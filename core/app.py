import os
import re
import json
import shutil
import zipfile
import asyncio
import threading
import urllib.parse
from datetime import datetime
from typing import Optional, Dict, Any

from PySide6.QtWidgets import QFileDialog
from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl, QTimer
from PySide6.QtGui import QDesktopServices
from PySide6.QtMultimedia import QMediaPlayer, QAudioOutput

from api import (
    load_constants, load_mods, parse_categories, parse_all_mods,
    safe_url, BASE_URL
)
from core.logger import logger
from core.version import APP_VERSION
from core.dota_path import detect_steam_dota_path
from core.workers import InstallWorker, safe_extractall
from core.stats_service import StatsService
from core.gsi_server import GSIServer
from core.log_watcher import DotaLogWatcher
from core.image_cache import image_cache
from core.presets_service import PresetsService
from core.dota_launcher import launch_dota_game, check_gameinfo_health, repair_gameinfo
from core.discord_rpc import DEFAULT_CLIENT_ID, discord_rpc

class SkinChangerApp(QObject):
    categoriesLoaded = Signal()
    modsLoaded = Signal()
    errorOccurred = Signal(str)
    successOccurred = Signal(str)
    installedModsChanged = Signal()
    favoritesChanged = Signal()
    dotaPathChanged = Signal()
    installLanguageChanged = Signal()
    gameinfoStatusChanged = Signal()
    audioStateChanged = Signal()
    loadingChanged = Signal()
    progressChanged = Signal(int, str, str)  # percent, status, item_name
    batchFinished = Signal(bool, str)
    liveMatchChanged = Signal()
    overlayToggled = Signal(bool)
    gsiStatusChanged = Signal()
    updateAvailable = Signal(str, str, str)  # version, notes, download_url
    remoteDataReady = Signal(object, object)  # (constants, mods) fetched off-GUI; (None, None) on failure

    def __init__(self, parent=None):
        super().__init__(parent)
        self._categories = []
        self._mods_data = {}
        self._translations = {}
        self._heroes_list = []
        self._dota_path = ""
        self._install_language = "both"
        self._discord_client_id = DEFAULT_CLIENT_ID  # Default to ImmortalHub ID
        self._theme_mode = "cyberpunk"
        self._is_loading = True
        self._install_worker: Optional[InstallWorker] = None
        # Delivered in the GUI thread even though emitted from the fetch worker
        self.remoteDataReady.connect(self._on_remote_data_ready)

        # Stats & Live Match Service
        self._stats_service = StatsService()
        self._gsi_server = GSIServer()
        self._log_watcher = None
        self._live_match_data = None
        self._overlay_visible = False
        self._overlay_enabled = True
        self._launch_options = ""

        # Media Player for Audio Previews
        self._media_player = QMediaPlayer()
        self._audio_output = QAudioOutput()
        self._media_player.setAudioOutput(self._audio_output)
        self._audio_output.setVolume(0.85)
        self._current_audio_url = ""
        self._media_player.playbackStateChanged.connect(lambda _: self.audioStateChanged.emit())

        self._app_dir = os.path.join(os.path.expanduser("~"), ".dota2skinchanger")
        self._settings_path = os.path.join(self._app_dir, "settings.json")
        self._manifest_path = os.path.join(self._app_dir, "installed_mods.json")
        self._favorites_path = os.path.join(self._app_dir, "favorites.json")
        self._cache_dir = os.path.join(self._app_dir, "cache")
        os.makedirs(self._cache_dir, exist_ok=True)
        self._constants_cache_path = os.path.join(self._cache_dir, "constants.json")
        self._mods_cache_path = os.path.join(self._cache_dir, "mods.json")

        self._load_settings()

        # Instant local cache loading (0ms startup)
        self._load_from_local_cache()

        # Start GSI server listener & Log Watcher
        self._gsi_server.start(self._on_gsi_event)
        self._log_watcher = DotaLogWatcher(self._dota_path)
        self._log_watcher.start(self._on_real_players_detected)

        # If dota path not set, try auto-detection
        if not self._dota_path or not os.path.exists(self._dota_path):
            detected = detect_steam_dota_path()
            if detected:
                self._dota_path = detected
                self._log_watcher.dota_path = detected
                self._save_settings()
                # Auto-install GSI config if detected
                GSIServer.install_gsi_config(self._dota_path)

        # Initialize Presets Service & Discord RPC
        self._presets_service = PresetsService(self._app_dir)
        self.installedModsChanged.connect(self._on_installed_changed_for_rpc)
        self._on_installed_changed_for_rpc()

    def _on_installed_changed_for_rpc(self):
        try:
            count = len(self._get_installed_dict())
            discord_rpc.update_presence(
                details=f"ImmortalHub • {count} active custom skins",
                state="Custom Skin Changer",
                active_mods_count=count
            )
        except Exception:
            pass

    # --- Properties ---

    @Property(str, constant=True)
    def appVersion(self) -> str:
        return f"v{APP_VERSION}"

    @Property(list, notify=categoriesLoaded)
    def categories(self):
        return [c.__dict__ for c in self._categories if not c.hidden]

    @Property(dict, notify=categoriesLoaded)
    def translations(self):
        return self._translations

    @Property(list, notify=categoriesLoaded)
    def heroesList(self):
        return self._heroes_list

    @Property(str, notify=dotaPathChanged)
    def dotaPath(self):
        return self._dota_path

    @dotaPath.setter
    def dotaPath(self, value: str):
        if self._dota_path != value:
            self._dota_path = value
            self._save_settings()
            self.dotaPathChanged.emit()
            self.gameinfoStatusChanged.emit()

    @Property(str, notify=installLanguageChanged)
    def installLanguage(self):
        return self._install_language

    @installLanguage.setter
    def installLanguage(self, value: str):
        if self._install_language != value:
            self._install_language = value
            self._save_settings()
            self.installLanguageChanged.emit()

    @Property(str, notify=dotaPathChanged)
    def discordClientId(self):
        return self._discord_client_id

    @discordClientId.setter
    def discordClientId(self, value: str):
        if self._discord_client_id != value:
            self._discord_client_id = value
            self._save_settings()
            from core.discord_rpc import discord_rpc
            discord_rpc.set_client_id(value)
            self.dotaPathChanged.emit() # Reusing signal for simplicity or we can emit a new one, but let's just trigger update

    themeModeChanged = Signal()
    totalSavingsChanged = Signal()
    launchOptionsChanged = Signal()
    
    @Property(str, notify=launchOptionsChanged)
    def launchOptions(self):
        return self._launch_options

    @launchOptions.setter
    def launchOptions(self, value: str):
        if self._launch_options != value:
            self._launch_options = value
            self._save_settings()
            self.launchOptionsChanged.emit()

    @Property(str, notify=themeModeChanged)
    def themeMode(self):
        return self._theme_mode

    @themeMode.setter
    def themeMode(self, value: str):
        if self._theme_mode != value:
            self._theme_mode = value
            self._save_settings()
            self.themeModeChanged.emit()

    @Property(int, notify=totalSavingsChanged)
    def totalSavings(self):
        return self._calculate_savings()
        
    def _calculate_savings(self) -> int:
        installed = self._get_installed_dict()
        savings = 0
        for mod_id, mod in installed.items():
            name = str(mod.get("name", "")).lower()
            if "arcana" in name:
                savings += 35
            elif "persona" in name:
                savings += 20
            elif "immortal" in name:
                savings += 5
            elif "cache" in name or "collector" in name:
                savings += 10
            else:
                savings += 3 # standard skin
        return savings

    @Property(list, constant=True)
    def availableLanguages(self):
        return [
            {"id": "both", "name": "All / Both (dota & dota_russian)", "folder": "both", "emoji": "🌐"},
            {"id": "dota", "name": "English / Default (game/dota)", "folder": "dota", "emoji": "🇬🇧"},
            {"id": "dota_russian", "name": "Russian (game/dota_russian)", "folder": "dota_russian", "emoji": "🇷🇺"},
            {"id": "dota_schinese", "name": "Chinese (game/dota_schinese)", "folder": "dota_schinese", "emoji": "🇨🇳"},
            {"id": "dota_koreana", "name": "Korean (game/dota_koreana)", "folder": "dota_koreana", "emoji": "🇰🇷"},
        ]

    @Property(bool, notify=dotaPathChanged)
    def dotaDetected(self):
        return bool(self._dota_path and os.path.exists(self._dota_path))

    @Property(bool, notify=liveMatchChanged)
    def isLiveMatchActive(self):
        return self._live_match_data is not None

    @Property(bool, notify=overlayToggled)
    def overlayVisible(self):
        return self._overlay_visible

    @Property(bool, notify=gsiStatusChanged)
    def gsiInstalled(self):
        return GSIServer.is_gsi_installed(self._dota_path)

    @Property(bool, notify=loadingChanged)
    def isLoading(self):
        return self._is_loading

    @Property(int, notify=installedModsChanged)
    def installedCount(self):
        return len(self._get_installed_dict())

    @Property(int, notify=favoritesChanged)
    def favoritesCount(self):
        return len(self._get_favorites_dict())

    @Property(bool, notify=gameinfoStatusChanged)
    def gameinfoPatched(self):
        if not self._dota_path:
            return False
        gi_path = os.path.join(self._dota_path, "dota", "gameinfo.gi")
        if not os.path.exists(gi_path):
            return False
        try:
            with open(gi_path, "r", encoding="utf-8", errors="ignore") as f:
                return "dota/pak" in f.read()
        except Exception as e:
            logger.debug(f"Failed to check gameinfo.gi status: {e}")
            return False

    @Property(bool, notify=audioStateChanged)
    def isPlayingAudio(self):
        return self._media_player.playbackState() == QMediaPlayer.PlayingState

    @Property(str, notify=audioStateChanged)
    def currentAudioUrl(self):
        return self._current_audio_url

    @Property(str)
    def baseUrl(self):
        return BASE_URL

    # --- Audio Player Slots ---

    @Slot(str)
    def playAudio(self, url: str):
        clean = safe_url(url)
        if not clean:
            return
        self._current_audio_url = clean
        self._media_player.setSource(QUrl(clean))
        self._media_player.play()
        self.audioStateChanged.emit()

    @Slot()
    def stopAudio(self):
        self._media_player.stop()
        self._current_audio_url = ""
        self.audioStateChanged.emit()

    @Slot(str)
    def toggleAudio(self, url: str):
        clean = safe_url(url)
        if self._current_audio_url == clean and self._media_player.playbackState() == QMediaPlayer.PlayingState:
            self.stopAudio()
        else:
            self.playAudio(url)

    @Slot(str, str, str)
    def playDemoVoiceLine(self, name: str, hero: str, category_id: str):
        cat_mods = self._mods_data.get(category_id, [])
        for m in cat_mods:
            if m.name.lower() == name.lower() and m.audio_preview:
                self.playAudio(m.audio_url())
                return
        
        # If no audio URL is available, notify the user instead of playing a 404 URL
        self.successOccurred.emit(f"Audio preview for {name} is not available in the database yet.")

    # --- Gameinfo.gi Patcher ---

    @Slot(result=bool)
    def patchGameinfo(self) -> bool:
        if not self._dota_path:
            self.errorOccurred.emit("Set Dota 2 path first!")
            return False
        gi_path = os.path.join(self._dota_path, "dota", "gameinfo.gi")
        if not os.path.exists(gi_path):
            self.errorOccurred.emit(f"gameinfo.gi not found at {gi_path}")
            return False

        try:
            with open(gi_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()

            if "dota/pak" in content:
                self.successOccurred.emit("gameinfo.gi is already patched for mod support.")
                return True

            bak_path = gi_path + ".bak"
            if not os.path.exists(bak_path):
                shutil.copy2(gi_path, bak_path)

            pattern = r'(SearchPaths\s*\{)'
            replacement = r'\1\n\t\t\tGame\t\t\t\tdota/pak\n\t\t\tGame\t\t\t\tdota_russian/pak'
            patched = re.sub(pattern, replacement, content, count=1)

            with open(gi_path, "w", encoding="utf-8") as f:
                f.write(patched)

            self.gameinfoStatusChanged.emit()
            self.successOccurred.emit("gameinfo.gi patched successfully! Mod priority is active.")
            logger.info("Successfully patched gameinfo.gi")
            return True
        except Exception as e:
            logger.error(f"Failed to patch gameinfo.gi: {e}")
            self.errorOccurred.emit(f"Failed to patch gameinfo.gi: {e}")
            return False

    @Slot(result=bool)
    def restoreGameinfo(self) -> bool:
        if not self._dota_path:
            return False
        gi_path = os.path.join(self._dota_path, "dota", "gameinfo.gi")
        if not os.path.exists(gi_path):
            return False

        try:
            with open(gi_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()

            content = re.sub(r'[ \t]*Game[ \t]+dota/pak\r?\n?', '', content)
            content = re.sub(r'[ \t]*Game[ \t]+dota_russian/pak\r?\n?', '', content)

            with open(gi_path, "w", encoding="utf-8") as f:
                f.write(content)

            self.gameinfoStatusChanged.emit()
            self.successOccurred.emit("gameinfo.gi restored to default.")
            logger.info("Successfully restored gameinfo.gi")
            return True
        except Exception as e:
            logger.error(f"Failed to restore gameinfo.gi: {e}")
            self.errorOccurred.emit(f"Failed to restore gameinfo.gi: {e}")
            return False

    # --- Favorites System ---

    @Slot(str)
    def toggleFavorite(self, mod_json: str):
        try:
            mod = json.loads(mod_json)
            name = mod.get("name", "")
            cat_id = mod.get("categoryId", "")
            key = f"{cat_id}::{name}"

            favs = self._get_favorites_dict()
            if key in favs:
                del favs[key]
                self.successOccurred.emit(f"Removed '{name}' from favorites.")
            else:
                favs[key] = mod
                self.successOccurred.emit(f"Added '{name}' to favorites ⭐")

            self._save_favorites(favs)
            self.favoritesChanged.emit()
        except Exception as e:
            logger.error(f"Error updating favorites: {e}")
            self.errorOccurred.emit(f"Error updating favorites: {e}")

    @Slot(str, str, result=bool)
    def isFavorite(self, name: str, category_id: str) -> bool:
        favs = self._get_favorites_dict()
        key = f"{category_id}::{name}"
        return key in favs

    @Slot(result=str)
    def getFavorites(self) -> str:
        favs = self._get_favorites_dict()
        items = list(favs.values())
        for item in items:
            item["isInstalled"] = self.isModInstalled(item.get("name", ""), item.get("categoryId", ""))
            item["isFavorite"] = True
        return json.dumps(items, ensure_ascii=False)

    # --- Custom Mod Drag & Drop Importer ---

    @Slot(str)
    def importCustomMod(self, file_path_or_url: str):
        clean_path = file_path_or_url.replace("file:///", "").replace("file://", "")
        clean_path = urllib.parse.unquote(clean_path)

        if not os.path.exists(clean_path):
            self.errorOccurred.emit(f"File not found: {clean_path}")
            return

        if not self.dotaDetected:
            self.errorOccurred.emit("Please set Dota 2 game path first!")
            return

        base_name = os.path.basename(clean_path)
        mod_name = os.path.splitext(base_name)[0]

        target_pak_dirs = []
        if self._install_language == "both":
            target_pak_dirs.append(os.path.join(self._dota_path, "dota"))
            target_pak_dirs.append(os.path.join(self._dota_path, "dota_russian"))
        else:
            target_pak_dirs.append(os.path.join(self._dota_path, self._install_language))

        for d in target_pak_dirs:
            os.makedirs(d, exist_ok=True)

        created_files = []

        try:
            if clean_path.lower().endswith(".zip"):
                with zipfile.ZipFile(clean_path, "r") as zf:
                    for target_pak in target_pak_dirs:
                        extract_dest = os.path.join(target_pak, f"!custom_{mod_name}")
                        os.makedirs(extract_dest, exist_ok=True)
                        safe_extractall(zf, extract_dest)
                        created_files.append(extract_dest)
            elif clean_path.lower().endswith(".vpk"):
                for target_pak in target_pak_dirs:
                    dest_file = os.path.join(target_pak, base_name)
                    shutil.copy2(clean_path, dest_file)
                    created_files.append(dest_file)
            else:
                self.errorOccurred.emit("Unsupported format. Please drop a .vpk or .zip file.")
                return

            manifest = self._get_installed_dict()
            manifest_key = f"custom::{mod_name}"
            manifest[manifest_key] = {
                "name": mod_name,
                "categoryId": "custom",
                "hero": "Custom",
                "previewUrl": "",
                "file": base_name,
                "files": created_files,
                "targetLanguage": self._install_language,
                "installedAt": datetime.now().strftime("%Y-%m-%d %H:%M"),
            }
            self._save_manifest(manifest)
            self.installedModsChanged.emit()
            self.successOccurred.emit(f"Successfully imported custom mod: {mod_name}!")
            logger.info(f"Custom mod {mod_name} imported successfully.")
        except Exception as e:
            logger.error(f"Failed to import custom mod: {e}", exc_info=True)
            self.errorOccurred.emit(f"Failed to import custom mod: {e}")

    def _load_from_local_cache(self):
        try:
            if os.path.exists(self._constants_cache_path) and os.path.exists(self._mods_cache_path):
                with open(self._constants_cache_path, "r", encoding="utf-8") as f:
                    constants = json.load(f)
                with open(self._mods_cache_path, "r", encoding="utf-8") as f:
                    mods = json.load(f)

                self._translations = constants.get("translations", {})
                self._heroes_list = constants.get("HEROES_LIST", [])
                self._categories = parse_categories(constants)
                self._mods_data = parse_all_mods(mods)
                self._is_loading = False
                logger.info("Instantly loaded constants and mods from local cache (0ms).")
        except Exception as e:
            logger.warning(f"Local cache fast-load failed: {e}")

    # --- Async Data Loader ---

    @Slot()
    def loadAll(self):
        if not self._mods_data:
            self._is_loading = True
            self.loadingChanged.emit()
        # Fetch in a background thread so slow networks never freeze the GUI.
        # Results are marshalled back via remoteDataReady (queued connection).
        threading.Thread(target=self._fetch_remote_data, daemon=True, name="RemoteDataFetch").start()

    def _fetch_remote_data(self):
        loop = asyncio.new_event_loop()
        try:
            logger.info("Fetching fresh constants and mods data in background...")
            constants = loop.run_until_complete(load_constants())
            mods = loop.run_until_complete(load_mods())

            # Save to disk cache for future instant offline startups
            try:
                with open(self._constants_cache_path, "w", encoding="utf-8") as f:
                    json.dump(constants, f, ensure_ascii=False)
                with open(self._mods_cache_path, "w", encoding="utf-8") as f:
                    json.dump(mods, f, ensure_ascii=False)
            except Exception as e:
                logger.warning(f"Cache write error: {e}")

            self.remoteDataReady.emit(constants, mods)
        except Exception as e:
            logger.warning(f"Network update skipped / failed: {str(e)}")
            self.remoteDataReady.emit(None, None)
        finally:
            loop.close()

    @Slot(object, object)
    def _on_remote_data_ready(self, constants, mods):
        """Runs in the GUI thread (queued connection from the fetch worker)."""
        if constants is not None and mods is not None:
            self._translations = constants.get("translations", {})
            self._heroes_list = constants.get("HEROES_LIST", [])
            self._categories = parse_categories(constants)
            self._mods_data = parse_all_mods(mods)

            # High-speed background prefetch of all preview images
            all_previews = []
            for cat_id, cat_mods in self._mods_data.items():
                for m in cat_mods:
                    if m.preview:
                        all_previews.append(safe_url(m.preview_url()))
                    for st in (m.styles or []):
                        if isinstance(st, dict) and st.get("previewUrl"):
                            all_previews.append(safe_url(st["previewUrl"]))
                        elif hasattr(st, "preview") and st.preview:
                            all_previews.append(safe_url(st.preview_url(m.category_id)))
            image_cache.prefetch_all(all_previews)

            self._is_loading = False
            self.loadingChanged.emit()
            self.categoriesLoaded.emit()
            self.modsLoaded.emit()
            self.installedModsChanged.emit()
            self.favoritesChanged.emit()
            self.gameinfoStatusChanged.emit()
            logger.info("Successfully updated API data.")
        elif self._is_loading:
            self._is_loading = False
            self.loadingChanged.emit()
            self.errorOccurred.emit("Network error: could not fetch the latest data.")

    def _serialize_mod(self, m) -> dict:
        p_url = safe_url(m.preview_url())
        styles_data = []
        for s in (m.styles or []):
            if isinstance(s, dict):
                st_url = safe_url(s.get("previewUrl", ""))
                styles_data.append({
                    "label": s.get("label", ""),
                    "preview": s.get("preview", ""),
                    "previewUrl": image_cache.get_url_or_cached(st_url),
                    "file": s.get("file", ""),
                    "fileUrl": s.get("fileUrl", ""),
                    "color": s.get("color", "")
                })
            else:
                st_url = safe_url(s.preview_url(m.category_id))
                styles_data.append({
                    "label": s.label,
                    "preview": s.preview,
                    "previewUrl": image_cache.get_url_or_cached(st_url),
                    "file": s.file,
                    "color": s.color
                })
        return {
            "name": m.name,
            "preview": m.preview,
            "previewUrl": image_cache.get_url_or_cached(p_url),
            "file": m.file,
            "fileUrl": safe_url(m.file_url()),
            "audioUrl": safe_url(m.audio_url()),
            "categoryId": m.category_id,
            "hero": m.hero,
            "tags": m.tags,
            "links": m.links,
            "styles": styles_data,
            "meta": m.meta,
            "isInstalled": self.isModInstalled(m.name, m.category_id),
            "isFavorite": self.isFavorite(m.name, m.category_id)
        }

    # --- Mods Query & Filtering ---

    @Slot(str, result=str)
    def getModsForCategory(self, category_id: str) -> str:
        mods = self._mods_data.get(category_id, [])
        result = [self._serialize_mod(m) for m in mods]
        return json.dumps(result, ensure_ascii=False)

    @Slot(result=str)
    def getAllModsFlat(self) -> str:
        all_mods = []
        for cat_id, mods in self._mods_data.items():
            for m in mods:
                all_mods.append(self._serialize_mod(m))
        return json.dumps(all_mods, ensure_ascii=False)

    @Slot(str, result=str)
    def getHeroMods(self, hero_name: str) -> str:
        result = []
        hero_lower = hero_name.lower()

        # Check 'heroes' category
        for m in self._mods_data.get("heroes", []):
            if hero_lower in m.name.lower() or (m.hero and hero_lower in m.hero.lower()):
                result.append(self._serialize_mod(m))

        # Check 'hero-items' category
        for m in self._mods_data.get("hero-items", []):
            if (m.hero and hero_lower in m.hero.lower()) or hero_lower in m.name.lower():
                result.append(self._serialize_mod(m))

        # Check 'herofx' and 'hero-sounds'
        for cat_id in ["herofx", "hero-sounds"]:
            for m in self._mods_data.get(cat_id, []):
                if hero_lower in m.name.lower() or (m.hero and hero_lower in m.hero.lower()):
                    result.append(self._serialize_mod(m))

        return json.dumps(result, ensure_ascii=False)

    @Slot(str, result=str)
    def translate(self, key: str) -> str:
        return self._translations.get(key, key)

    # --- Installation & Uninstallation ---

    @Slot(str, str)
    def installMod(self, mod_json: str, category_id: str):
        if not self.dotaDetected:
            self.errorOccurred.emit("Please set a valid Dota 2 game path in Settings first!")
            return

        try:
            mod = json.loads(mod_json)
            mod["categoryId"] = category_id
            self.installBatch(json.dumps([mod]))
        except Exception as e:
            logger.error(f"Failed to parse mod info: {str(e)}")
            self.errorOccurred.emit(f"Failed to parse mod info: {str(e)}")

    @Slot(str)
    def installBatch(self, mods_json_array: str):
        if not self.dotaDetected:
            self.errorOccurred.emit("Please set a valid Dota 2 game path in Settings first!")
            return

        try:
            items = json.loads(mods_json_array)
            if not items:
                return

            for item in items:
                conflict_json = self.checkModConflict(json.dumps(item))
                if conflict_json != "{}":
                    c_data = json.loads(conflict_json)
                    if c_data.get("hasConflict"):
                        c_mod = c_data.get("conflictingMod", {})
                        c_name = c_mod.get("name")
                        c_cat = c_mod.get("categoryId")
                        if c_name and c_cat:
                            logger.info(f"Auto-uninstalling conflicting mod: {c_name} (Category: {c_cat})")
                            self.uninstallMod(c_name, c_cat)

            if self._install_worker and self._install_worker.isRunning():
                self.errorOccurred.emit("An installation is already in progress. Please wait.")
                return

            logger.info(f"Starting batch install of {len(items)} items")
            self._install_worker = InstallWorker(
                items, self._dota_path, self._manifest_path, self._install_language
            )
            self._install_worker.progress.connect(self._on_worker_progress)
            self._install_worker.modDone.connect(self._on_mod_done)
            self._install_worker.batchFinished.connect(self._on_batch_finished)
            self._install_worker.start()

        except Exception as e:
            logger.error(f"Batch install error: {str(e)}")
            self.errorOccurred.emit(f"Batch install error: {str(e)}")

    def _on_worker_progress(self, percent: int, status: str, item_name: str):
        self.progressChanged.emit(percent, status, item_name)

    def _on_mod_done(self, mod_name: str, success: bool, msg: str):
        if success:
            self.successOccurred.emit(f"Installed: {mod_name}")
            self.installedModsChanged.emit()
            self.totalSavingsChanged.emit()
        else:
            self.errorOccurred.emit(f"Error ({mod_name}): {msg}")

    def _on_batch_finished(self, success: bool, summary: str):
        if success:
            self.successOccurred.emit(summary)
        else:
            self.errorOccurred.emit(summary)
        self.installedModsChanged.emit()
        self.totalSavingsChanged.emit()
        self.batchFinished.emit(success, summary)

    @Slot(str, str, result=bool)
    def isModInstalled(self, name: str, category_id: str) -> bool:
        manifest = self._get_installed_dict()
        key = f"{category_id}::{name}"
        return key in manifest

    @Slot(result=str)
    def getInstalledMods(self) -> str:
        manifest = self._get_installed_dict()
        items = list(manifest.values())
        return json.dumps(items, ensure_ascii=False)

    @Slot(str, str)
    def uninstallMod(self, name: str, category_id: str):
        manifest = self._get_installed_dict()
        key = f"{category_id}::{name}"

        if key not in manifest:
            self.errorOccurred.emit(f"Mod '{name}' is not recorded as installed.")
            return

        item = manifest[key]
        deleted_count = 0

        for file_path in item.get("files", []):
            try:
                if os.path.isdir(file_path):
                    shutil.rmtree(file_path, ignore_errors=True)
                    deleted_count += 1
                elif os.path.isfile(file_path):
                    os.remove(file_path)
                    deleted_count += 1
            except Exception as e:
                logger.error(f"Error removing {file_path}: {e}")

        del manifest[key]
        self._save_manifest(manifest)
        self.installedModsChanged.emit()
        self.totalSavingsChanged.emit()
        self.successOccurred.emit(f"Uninstalled '{name}'. Removed {deleted_count} files/folders.")
        logger.info(f"Uninstalled '{name}'")

    @Slot()
    def uninstallAllMods(self):
        manifest = self._get_installed_dict()
        if not manifest:
            self.errorOccurred.emit("No installed mods found.")
            return

        count = len(manifest)

        for item in manifest.values():
            for file_path in item.get("files", []):
                try:
                    if os.path.isdir(file_path):
                        shutil.rmtree(file_path, ignore_errors=True)
                    elif os.path.isfile(file_path):
                        os.remove(file_path)
                except Exception as e:
                    logger.debug(f"Failed to remove file/dir {file_path} during full uninstall: {e}")

        self._save_manifest({})
        self.installedModsChanged.emit()
        self.successOccurred.emit(f"All {count} mods have been cleanly uninstalled.")
        logger.info("All mods uninstalled cleanly.")

    # --- Language & Path Helpers ---

    @Slot(str)
    def setInstallLanguage(self, lang_id: str):
        self.installLanguage = lang_id
        self.successOccurred.emit(f"Target mod folder set to: {lang_id}")

    @Slot(result=str)
    def autoDetectDotaPath(self) -> str:
        detected = detect_steam_dota_path()
        if detected:
            self.dotaPath = detected
            self.successOccurred.emit(f"Dota 2 detected at: {detected}")
            return detected
        else:
            self.errorOccurred.emit("Could not automatically locate Dota 2. Please browse manually.")
            return ""

    @Slot(result=str)
    def browseDotaPath(self) -> str:
        start_dir = self._dota_path if os.path.exists(self._dota_path) else "C:\\Program Files (x86)\\Steam\\steamapps\\common"
        path = QFileDialog.getExistingDirectory(
            None,
            "Select Dota 2 'game' folder (e.g. .../dota 2 beta/game)",
            start_dir
        )
        if path:
            if os.path.exists(os.path.join(path, "game", "dota")):
                path = os.path.join(path, "game")

            self.dotaPath = os.path.normpath(path)
            self.successOccurred.emit(f"Dota 2 path saved: {self._dota_path}")
            return self._dota_path
        return ""

    @Slot(str)
    def setDotaPath(self, path: str):
        self.dotaPath = path

    @Slot()
    def openPakFolder(self):
        if self._dota_path:
            folder_target = "dota_russian" if (self._install_language in ["both", "dota_russian"] and os.path.exists(os.path.join(self._dota_path, "dota_russian"))) else ("dota" if self._install_language == "both" else self._install_language)
            dest_dir = os.path.join(self._dota_path, folder_target)
            os.makedirs(dest_dir, exist_ok=True)
            QDesktopServices.openUrl(QUrl.fromLocalFile(dest_dir))
        else:
            self.errorOccurred.emit("Dota 2 path is not set.")

    @Slot(str)
    def openFolder(self, path: str):
        if os.path.exists(path):
            QDesktopServices.openUrl(QUrl.fromLocalFile(path))

    @Slot(str)
    def openUrl(self, url: str):
        if url.startswith("http"):
            QDesktopServices.openUrl(QUrl(url))
        else:
            QDesktopServices.openUrl(QUrl.fromLocalFile(url))

    # --- Internal Settings & Manifest Helpers ---

    def _get_installed_dict(self) -> Dict[str, Any]:
        if os.path.exists(self._manifest_path):
            try:
                with open(self._manifest_path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Failed to read installed manifest: {e}")
                return {}
        return {}

    def _save_manifest(self, manifest: Dict[str, Any]):
        try:
            os.makedirs(os.path.dirname(self._manifest_path), exist_ok=True)
            with open(self._manifest_path, "w", encoding="utf-8") as f:
                json.dump(manifest, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to save manifest: {e}")

    def _get_favorites_dict(self) -> Dict[str, Any]:
        if os.path.exists(self._favorites_path):
            try:
                with open(self._favorites_path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Failed to read favorites: {e}")
                return {}
        return {}

    def _save_favorites(self, favs: Dict[str, Any]):
        try:
            os.makedirs(os.path.dirname(self._favorites_path), exist_ok=True)
            with open(self._favorites_path, "w", encoding="utf-8") as f:
                json.dump(favs, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to save favorites: {e}")

    def _load_settings(self):
        try:
            if os.path.exists(self._settings_path):
                with open(self._settings_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self._dota_path = data.get("dotaPath", "")
                    self._install_language = data.get("installLanguage", "both")
                    self._discord_client_id = data.get("discordClientId", "1541931721216368653")
                    self._theme_mode = data.get("themeMode", "cyberpunk")
                    self._launch_options = data.get("launchOptions", "")
                    
                    # Update discord client ID upon loading
                    from core.discord_rpc import discord_rpc
                    discord_rpc.set_client_id(self._discord_client_id)
        except Exception as e:
            logger.error(f"Failed to load settings: {e}")

    def _save_settings(self):
        try:
            os.makedirs(os.path.dirname(self._settings_path), exist_ok=True)
            with open(self._settings_path, "w", encoding="utf-8") as f:
                json.dump({
                    "dotaPath": self._dota_path,
                    "installLanguage": self._install_language,
                    "discordClientId": self._discord_client_id,
                    "themeMode": self._theme_mode,
                    "launchOptions": self._launch_options
                }, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save settings: {e}")

    # --- Live Match & Overplus Overlay Slots ---

    def _on_real_players_detected(self, player_ids: list):
        if not player_ids:
            return
        logger.info(f"Real players detected from Dota 2: {player_ids}")
        import threading
        def _fetch():
            try:
                data = self._stats_service.build_match_from_ids(player_ids)
                self._live_match_data = data
                self.liveMatchChanged.emit()
                if self._overlay_enabled:
                    self._overlay_visible = True
                    self.overlayToggled.emit(True)
                self.successOccurred.emit(f"Detected {len(player_ids)} real players in active Dota 2 match!")
            except Exception as e:
                logger.error(f"Error fetching real player stats: {e}")
        threading.Thread(target=_fetch, daemon=True).start()

    def _on_gsi_event(self, payload: Dict[str, Any]):
        map_info = payload.get('map', {})
        game_state = map_info.get('game_state', '')
        player_info = payload.get('player', {})
        steamid = player_info.get('steamid', '')
        
        # If in hero selection or draft
        if game_state in ['DOTA_GAMERULES_STATE_HERO_SELECTION', 'DOTA_GAMERULES_STATE_STRATEGY_TIME', 'DOTA_GAMERULES_STATE_PRE_GAME']:
            logger.info(f"Dota GSI Match State: {game_state}")
            # If we don't have active live match, check logs
            if not self._live_match_data:
                if self._log_watcher:
                    real_ids = self._log_watcher.scan_now()
                    if real_ids:
                        self._on_real_players_detected(real_ids)
                        return
                
                # If player steamid is available from GSI
                if steamid and steamid.isdigit():
                    acc_id = int(steamid) - 76561197960265728
                    if acc_id > 0:
                        self._on_real_players_detected([acc_id])
                        return

                if self._overlay_enabled:
                    self._overlay_visible = True
                    self.overlayToggled.emit(True)

    @Slot(result=str)
    def getLiveMatchJson(self) -> str:
        if self._live_match_data:
            return json.dumps(self._live_match_data, ensure_ascii=False)
        return "{}"

    @Slot()
    def scanDotaLogsNow(self):
        if not self._log_watcher:
            self._log_watcher = DotaLogWatcher(self._dota_path)
        ids = self._log_watcher.scan_now()
        if ids:
            self._on_real_players_detected(ids)
        else:
            self.errorOccurred.emit("No active players found in Dota 2 logs yet. Start a match or launch Dota 2 with -condebug!")

    @Slot(str, result=str)
    def searchPlayer(self, query: str) -> str:
        data = self._stats_service.search_player_by_query(query)
        if data:
            return json.dumps(data, ensure_ascii=False)
        return "{}"

    @Slot(str)
    def loadMatchByAccountIds(self, ids_csv: str):
        import re
        nums = [int(n) for n in re.findall(r'\d+', ids_csv)]
        clean_ids = []
        for n in nums:
            if n > 76561197960265728:
                clean_ids.append(n - 76561197960265728)
            elif n > 1000:
                clean_ids.append(n)
        if clean_ids:
            self._on_real_players_detected(clean_ids)
        else:
            self.errorOccurred.emit("No valid Steam IDs provided.")

    @Slot()
    def triggerDemoMatch(self):
        logger.info("Triggering Overplus-style Demo Match preview...")
        self._live_match_data = self._stats_service.get_mock_match()
        self.liveMatchChanged.emit()
        self._overlay_visible = True
        self.overlayToggled.emit(True)
        self.successOccurred.emit("Loaded Live Match Drafting Analytics demo!")

    @Slot()
    def clearLiveMatch(self):
        self._live_match_data = None
        self._overlay_visible = False
        self.liveMatchChanged.emit()
        self.overlayToggled.emit(False)

    @Slot()
    def toggleOverlay(self):
        self._overlay_visible = not self._overlay_visible
        self.overlayToggled.emit(self._overlay_visible)

    @Slot(bool)
    def setOverlayVisible(self, visible: bool):
        self._overlay_visible = visible
        self.overlayToggled.emit(self._overlay_visible)

    @Slot(result=bool)
    def installGsiConfig(self) -> bool:
        if not self._dota_path:
            self.errorOccurred.emit("Dota 2 path is not set!")
            return False
        success = GSIServer.install_gsi_config(self._dota_path)
        if success:
            self.successOccurred.emit("Game State Integration config installed successfully!")
            self.gsiStatusChanged.emit()
        else:
            self.errorOccurred.emit("Failed to install GSI config into Dota 2 cfg folder.")
        return success

    # --- Feature Slots: Presets, Conflict Detector, Dota Launcher & Drag-Drop ---

    @Slot(result=str)
    def getPresetsJson(self) -> str:
        all_presets = self._presets_service.get_all_presets(self._mods_data)
        return json.dumps(all_presets, ensure_ascii=False)

    @Slot(str, str, result=str)
    def saveUserPreset(self, name: str, desc: str) -> str:
        installed = self._get_installed_dict()
        items = []
        for key, item in installed.items():
            items.append({
                "name": item.get("name", ""),
                "categoryId": item.get("categoryId", ""),
                "previewUrl": item.get("previewUrl", ""),
                "file": item.get("file", "")
            })
        new_p = self._presets_service.save_user_preset(name, desc, items)
        self.successOccurred.emit(f"Preset '{name}' saved successfully!")
        return json.dumps(new_p, ensure_ascii=False)

    @Slot(str, result=bool)
    def deleteUserPreset(self, preset_id: str) -> bool:
        ok = self._presets_service.delete_user_preset(preset_id)
        if ok:
            self.successOccurred.emit("Preset deleted.")
        return ok

    @Slot(str)
    def loadPreset(self, preset_json: str):
        try:
            preset = json.loads(preset_json)
            items = preset.get("items", [])
            if not items:
                self.errorOccurred.emit("Preset contains no items.")
                return
            
            # Since conflict manager is now baked into installBatch, 
            # we can just uninstall all mods first for a clean slate, 
            # OR let installBatch handle overwrites.
            # Usually a preset implies a complete loadout swap, so we uninstall all first.
            self.uninstallAllMods()
            
            # Then queue all preset items for installation
            self.installBatch(json.dumps(items))
            self.successOccurred.emit(f"Loading preset: {preset.get('name', 'Custom Loadout')}")
        except Exception as e:
            logger.error(f"Failed to load preset: {e}")
            self.errorOccurred.emit("Failed to parse preset data.")

    @Slot(str, result=str)
    def checkModConflict(self, mod_json: str) -> str:
        try:
            m = json.loads(mod_json)
            mod_hero = (m.get("hero") or "").strip()
            mod_cat = m.get("categoryId", "")
            mod_name = m.get("name", "")

            installed = self._get_installed_dict()
            for key, item in installed.items():
                inst_name = item.get("name", "")
                inst_hero = (item.get("hero") or "").strip()
                inst_cat = item.get("categoryId", "")

                if inst_name == mod_name:
                    continue

                # Conflict 1: Same hero skins
                if mod_hero and inst_hero and mod_hero.lower() == inst_hero.lower():
                    if mod_cat == inst_cat or mod_cat == "heroes" or inst_cat == "heroes":
                        return json.dumps({
                            "hasConflict": True,
                            "conflictingMod": item,
                            "newMod": m,
                            "reason": f"Hero '{mod_hero}' already has '{inst_name}' installed."
                        }, ensure_ascii=False)

                # Conflict 2: Singleton categories (trees, terrains, river, roshan)
                if mod_cat in ["trees", "terrains", "river", "ancient", "roshan"] and mod_cat == inst_cat:
                    return json.dumps({
                        "hasConflict": True,
                        "conflictingMod": item,
                        "newMod": m,
                        "reason": f"Category '{mod_cat}' already has '{inst_name}' active."
                    }, ensure_ascii=False)

        except Exception as e:
            logger.warning(f"Error checking mod conflict: {e}")
        return "{}"

    @Slot(result=bool)
    def launchDota(self) -> bool:
        ok, msg = launch_dota_game(self._dota_path, custom_args=self._launch_options)
        if ok:
            self.successOccurred.emit("Launching Dota 2 via Steam...")
        else:
            self.errorOccurred.emit(msg)
        return ok

    @Slot(result=str)
    def getGameInfoHealth(self) -> str:
        health = check_gameinfo_health(self._dota_path)
        return json.dumps(health, ensure_ascii=False)

    @Slot(result=bool)
    def repairGameInfoHooks(self) -> bool:
        ok, msg = repair_gameinfo(self._dota_path)
        if ok:
            self.successOccurred.emit(msg)
            self.gameinfoStatusChanged.emit()
        else:
            self.errorOccurred.emit(msg)
        return ok

    @Slot(str)
    def importDroppedFile(self, file_url_or_path: str):
        if not file_url_or_path:
            return
        path = file_url_or_path
        if path.startswith("file:///"):
            path = QUrl(file_url_or_path).toLocalFile()
        
        if not os.path.exists(path):
            self.errorOccurred.emit(f"File not found: {path}")
            return
        
        self.importCustomMod(path)

    # --- Cloud Loadouts & Auto-Updater Slots ---

    @Slot(str, result=str)
    def exportHeroLoadoutCode(self, hero_name: str) -> str:
        """
        Exports the currently installed cosmetic items for a given hero into a shareable IH- code.
        """
        try:
            from core.cloud_loadouts import cloud_loadouts
            installed = self._get_installed_dict()
            hero_items = []
            for item in installed.values():
                if (item.get("hero") or "").lower() == hero_name.lower():
                    hero_items.append(item)

            if not hero_items:
                self.errorOccurred.emit(f"No active cosmetics equipped for {hero_name}.")
                return ""

            code = cloud_loadouts.encode_loadout(hero_name, hero_items)
            self.successOccurred.emit(f"Exported {hero_name} Loadout Code: {code}")
            return code
        except Exception as e:
            logger.error(f"Failed to export loadout code: {e}")
            self.errorOccurred.emit("Failed to generate loadout share code.")
            return ""

    @Slot(str, result=str)
    def importHeroLoadoutCode(self, code: str) -> str:
        """
        Parses an IH- loadout code and returns the hero & item data JSON.
        """
        try:
            from core.cloud_loadouts import cloud_loadouts
            decoded = cloud_loadouts.decode_loadout(code)
            if not decoded:
                self.errorOccurred.emit("Invalid or corrupted Loadout Code.")
                return "{}"

            self.successOccurred.emit(f"Imported Loadout for {decoded.get('hero')}: {len(decoded.get('items', []))} items found!")
            return json.dumps(decoded, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to import loadout code: {e}")
            self.errorOccurred.emit("Failed to parse loadout share code.")
            return "{}"

    @Slot()
    def checkForUpdates(self):
        """
        Checks GitHub Releases for new updates asynchronously.
        """
        import threading
        def _check():
            try:
                from core.updater import updater
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                result = loop.run_until_complete(updater.check_for_updates())
                loop.close()

                if result and result.get("has_update"):
                    self.updateAvailable.emit(
                        result.get("latest_version", ""),
                        result.get("release_notes", ""),
                        result.get("download_url", "")
                    )
                    self.successOccurred.emit(f"New update available: v{result.get('latest_version')}")
                else:
                    self.successOccurred.emit(f"ImmortalHub is up to date! (v{APP_VERSION})")
            except Exception as e:
                logger.debug(f"Update check error: {e}")

        threading.Thread(target=_check, daemon=True).start()
