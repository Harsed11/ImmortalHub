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
from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl, QTimer, QFileSystemWatcher
from PySide6.QtGui import QDesktopServices
from PySide6.QtMultimedia import QMediaPlayer, QAudioOutput

from api import (
    load_constants, load_mods, parse_categories, parse_all_mods,
    safe_url, BASE_URL, get_file_url, get_preview_url
)
from core.logger import logger
from core.version import APP_VERSION
from core.i18n import translate_ui, translate_category, normalize_lang
from core.mod_search import filter_mods
from core.dota_path import detect_steam_dota_path
from core.workers import InstallWorker, safe_extractall
from core.stats_service import StatsService
from core.gsi_server import GSIServer
from core.log_watcher import DotaLogWatcher
from core.image_cache import image_cache
from core.presets_service import PresetsService
from core.creators_service import CreatorsService
from core.hero_roles import hero_roles_service
from core.health_service import ModHealthService
from core.cloud_backup import CloudBackupService
from core.dota_launcher import launch_dota_game, check_gameinfo_health, repair_gameinfo, detect_valve_update
from core.discord_rpc import DEFAULT_CLIENT_ID, discord_rpc

class SkinChangerApp(QObject):
    categoriesLoaded = Signal()
    modsLoaded = Signal()
    creatorsChanged = Signal()
    errorOccurred = Signal(str)
    successOccurred = Signal(str)
    installedModsChanged = Signal()
    favoritesChanged = Signal()
    dotaPathChanged = Signal()
    installLanguageChanged = Signal()
    gameinfoStatusChanged = Signal()
    valveUpdateDetected = Signal(str)
    themeChanged = Signal()
    audioStateChanged = Signal()
    audioProgressChanged = Signal()
    loadingChanged = Signal()
    progressChanged = Signal(int, str, str)  # percent, status, item_name
    batchFinished = Signal(bool, str)
    liveMatchChanged = Signal()
    gsiStatusChanged = Signal()
    updateAvailable = Signal(str, str, str)  # version, notes, download_url
    remoteDataReady = Signal(object, object)  # (constants, mods) fetched off-GUI; (None, None) on failure
    uiLanguageChanged = Signal()
    heroRolesUpdated = Signal()
    integrityStatusChanged = Signal(str)
    cloudBackupFinished = Signal(bool, str, str)
    presetsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._categories = []
        self._mods_data = {}
        self._translations = {}
        self._heroes_list = []
        self._dota_path = ""
        self._install_language = "both"
        self._discord_client_id = DEFAULT_CLIENT_ID  # Default to ImmortalHub ID
        self._ui_language = "en"
        self._theme_mode = "cyberpunk"
        self._accent_hue = "immortal"
        self._bg_image_path = ""
        self._is_loading = True
        self._install_worker: Optional[InstallWorker] = None
        # Delivered in the GUI thread even though emitted from the fetch worker
        self.remoteDataReady.connect(self._on_remote_data_ready)

        # Stats & Live Match Service
        self._stats_service = StatsService()
        self._gsi_server = GSIServer()
        self._log_watcher = None
        self._live_match_data = None
        self._launch_options = ""

        # Media Player for Audio Previews & Scrubber
        self._media_player = QMediaPlayer()
        self._audio_output = QAudioOutput()
        self._media_player.setAudioOutput(self._audio_output)
        self._audio_output.setVolume(0.85)
        self._current_audio_url = ""
        self._audio_position = 0
        self._audio_duration = 0
        self._media_player.playbackStateChanged.connect(lambda _: self.audioStateChanged.emit())
        self._media_player.positionChanged.connect(self._on_audio_position_changed)
        self._media_player.durationChanged.connect(self._on_audio_duration_changed)

        # Valve Patch Update Detector
        self._valve_update_detected = False
        self._valve_update_message = ""
        self._auto_reapply_valve_update = True

        self._app_dir = os.path.join(os.path.expanduser("~"), ".dota2skinchanger")
        self._settings_path = os.path.join(self._app_dir, "settings.json")
        self._manifest_path = os.path.join(self._app_dir, "installed_mods.json")
        self._favorites_path = os.path.join(self._app_dir, "favorites.json")
        self._cache_dir = os.path.join(self._app_dir, "cache")
        os.makedirs(self._cache_dir, exist_ok=True)
        self._constants_cache_path = os.path.join(self._cache_dir, "constants.json")
        self._mods_cache_path = os.path.join(self._cache_dir, "mods.json")

        self._load_settings()

        # Mod Health & Cloud Backup Services
        self._health_service = ModHealthService(self._dota_path, self._manifest_path, self._app_dir)
        self._cloud_backup = CloudBackupService(self._app_dir)

        # Instant local cache loading (0ms startup)
        self._load_from_local_cache()

        # Hero Roles & Positions Meta Service
        self._hero_roles_service = hero_roles_service
        self._hero_roles_service.start_background_refresh(
            delay_seconds=4,
            on_complete=lambda ok: self.heroRolesUpdated.emit() if ok else None
        )

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

        # Deferred single check: restore mod hooks if a Dota update wiped them
        QTimer.singleShot(3000, self._auto_restore_hooks)

        # Real-time File System Watcher for Dota game folders
        self._fs_watcher = QFileSystemWatcher(self)
        self._fs_debounce_timer = QTimer(self)
        self._fs_debounce_timer.setSingleShot(True)
        self._fs_debounce_timer.setInterval(350)
        self._fs_debounce_timer.timeout.connect(self.validateInstalledMods)
        self._fs_watcher.directoryChanged.connect(self._on_game_dir_changed)
        self._setup_fs_watcher()

        # Initial auto-validation of installed mods against game folder
        self.validateInstalledMods()

        # Initialize Presets & Creators Service & Discord RPC
        self._presets_service = PresetsService(self._app_dir)
        self._creators_service = CreatorsService(self._app_dir)
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

    @Property(str, notify=uiLanguageChanged)
    def uiLanguage(self) -> str:
        return self._ui_language

    @Slot(str)
    def setUiLanguage(self, lang: str):
        lang = normalize_lang(lang)
        if lang != self._ui_language:
            self._ui_language = lang
            self._save_settings()
            self.uiLanguageChanged.emit()

    @Slot(str, result=str)
    def t(self, key: str) -> str:
        """Translate an application-chrome string in the active UI language."""
        return translate_ui(key, self._ui_language)

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
            if hasattr(self, "_health_service"):
                self._health_service.dota_path = value
            self._save_settings()
            self._setup_fs_watcher()
            self.dotaPathChanged.emit()
            self.gameinfoStatusChanged.emit()
            self.validateInstalledMods()

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
    accentHueChanged = Signal()
    bgImagePathChanged = Signal()
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

    @Property(str, notify=accentHueChanged)
    def accentHue(self):
        return self._accent_hue

    @accentHue.setter
    def accentHue(self, value: str):
        allowed = {"immortal", "cyan", "violet", "emerald", "amber", "crimson", "sakura", "ice"}
        value = value if value in allowed else "immortal"
        if self._accent_hue != value:
            self._accent_hue = value
            self._save_settings()
            self.accentHueChanged.emit()

    @Property(str, notify=bgImagePathChanged)
    def bgImagePath(self):
        return self._bg_image_path

    @bgImagePath.setter
    def bgImagePath(self, value: str):
        if self._bg_image_path != value:
            self._bg_image_path = value
            self._save_settings()
            self.bgImagePathChanged.emit()

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

    # --- Valve Update Detection Properties & Slots ---
    @Property(bool, notify=gameinfoStatusChanged)
    def isValveUpdateDetected(self):
        return self._valve_update_detected

    @Property(str, notify=gameinfoStatusChanged)
    def valveUpdateMessage(self):
        return self._valve_update_message

    @Property(bool, notify=gameinfoStatusChanged)
    def autoReapplyValveUpdate(self):
        return self._auto_reapply_valve_update

    @Slot(bool)
    def setAutoReapplyValveUpdate(self, enabled: bool):
        self._auto_reapply_valve_update = bool(enabled)
        self._save_settings()
        self.gameinfoStatusChanged.emit()

    @Slot(result=str)
    def checkValvePatchStatus(self) -> str:
        """Explicit check for Valve update status."""
        manifest = self._get_installed_dict(validate=False)
        res = detect_valve_update(self._dota_path, len(manifest))
        if res.get("detected"):
            self._valve_update_detected = True
            self._valve_update_message = res.get("message", "Valve update reset gameinfo.gi")
        else:
            self._valve_update_detected = False
            self._valve_update_message = ""
        self.gameinfoStatusChanged.emit()
        return json.dumps(res, ensure_ascii=False)

    @Slot(result=bool)
    def repairGameinfo(self) -> bool:
        """Restores gameinfo.gi mod search paths immediately."""
        ok, msg = repair_gameinfo(self._dota_path)
        if ok:
            self._valve_update_detected = False
            self._valve_update_message = ""
            self.successOccurred.emit(msg)
            self.gameinfoStatusChanged.emit()
            return True
        else:
            self.errorOccurred.emit(msg)
            return False

    @Slot()
    def dismissValveUpdateAlert(self):
        self._valve_update_detected = False
        self.gameinfoStatusChanged.emit()

    # --- Audio Player Properties & Slots ---
    def _on_audio_position_changed(self, pos: int):
        self._audio_position = pos
        self.audioProgressChanged.emit()

    def _on_audio_duration_changed(self, dur: int):
        self._audio_duration = dur
        self.audioProgressChanged.emit()

    @Property(bool, notify=audioStateChanged)
    def isPlayingAudio(self):
        return self._media_player.playbackState() == QMediaPlayer.PlayingState

    @Property(str, notify=audioStateChanged)
    def currentAudioUrl(self):
        return self._current_audio_url

    @Property(int, notify=audioProgressChanged)
    def audioPosition(self):
        return self._audio_position

    @Property(int, notify=audioProgressChanged)
    def audioDuration(self):
        return self._audio_duration

    @Property(str)
    def baseUrl(self):
        return BASE_URL

    @Slot(int)
    def seekAudio(self, pos_ms: int):
        self._media_player.setPosition(pos_ms)

    @Slot(float)
    def setAudioVolume(self, volume: float):
        vol = max(0.0, min(1.0, float(volume)))
        self._audio_output.setVolume(vol)

    # --- Theme Customizer Properties & Slots ---
    @Property(str, notify=themeChanged)
    def currentTheme(self):
        return self._theme_mode

    @Property(str, notify=themeChanged)
    def currentAccentHue(self):
        return self._accent_hue

    @Slot(result=str)
    def getThemeConfig(self) -> str:
        return json.dumps({
            "themeMode": self._theme_mode,
            "accentHue": self._accent_hue
        }, ensure_ascii=False)

    @Slot(str, str)
    def saveThemeConfig(self, theme_id: str, hue_id: str):
        self._theme_mode = theme_id or "cyberpunk"
        self._accent_hue = hue_id or "immortal"
        self._save_settings()
        self.themeChanged.emit()

    # --- Custom Spell Icons & Hero Aliases Slots ---
    @Slot(str, str, result=str)
    def getModSpellIcons(self, mod_name: str, hero_name: str) -> str:
        from core.spell_icons import get_custom_spells_for_mod
        spells = get_custom_spells_for_mod(mod_name, hero_name)
        return json.dumps(spells, ensure_ascii=False)

    @Slot(result=str)
    def getHeroAliasesJson(self) -> str:
        from core.hero_aliases import HERO_ALIASES
        return json.dumps(HERO_ALIASES, ensure_ascii=False)

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

    def _auto_restore_hooks(self):
        """(DISABLED FOR VAC BYPASS)
        We no longer auto-patch on startup. We only patch right before launching
        Dota 2 via the app, and then revert 25 seconds later. This guarantees that
        if the user launches Dota 2 directly from Steam without the app, they
        won't accidentally play with modified files and get a VAC warning.
        """
        pass

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

    # --- Creators & Telegram Channels Slots ---

    @Slot(result=str)
    def getCreators(self) -> str:
        creators = self._creators_service.get_all_creators()
        installed = self._get_installed_dict()
        result = []
        for c in creators:
            c_dict = dict(c)
            c_mods = c_dict.get("mods", [])
            installed_in_creator = 0
            for m in c_mods:
                m_name = m.get("name", "")
                m_cat = m.get("categoryId", "custom_creator")
                if f"{m_cat}::{m_name}" in installed or f"custom::{m_name}" in installed:
                    installed_in_creator += 1
            c_dict["installedCount"] = installed_in_creator
            c_dict["modsCount"] = len(c_mods)
            result.append(c_dict)
        return json.dumps(result, ensure_ascii=False)

    @Slot(str, result=str)
    def getCreator(self, creator_id: str) -> str:
        c = self._creators_service.get_creator(creator_id)
        if c:
            return json.dumps(c, ensure_ascii=False)
        return "{}"

    @Slot(str, str, str, str, result=bool)
    def createCreator(self, name: str, telegram: str, description: str, avatar_path: str) -> bool:
        try:
            created = self._creators_service.add_creator(
                name=name,
                telegram=telegram,
                description=description,
                avatar_path=avatar_path
            )
            self.creatorsChanged.emit()
            self.successOccurred.emit(f"Added channel: {created.get('name')}")
            return True
        except Exception as e:
            logger.error(f"Failed to create creator: {e}")
            self.errorOccurred.emit(f"Failed to create creator: {e}")
            return False

    @Slot(str, str, str, str, str, result=bool)
    def updateCreator(self, creator_id: str, name: str, telegram: str, description: str, avatar_path: str) -> bool:
        try:
            ok = self._creators_service.update_creator(creator_id, name, telegram, description, avatar_path)
            if ok:
                self.creatorsChanged.emit()
                self.successOccurred.emit("Creator updated successfully.")
            return ok
        except Exception as e:
            logger.error(f"Failed to update creator: {e}")
            self.errorOccurred.emit(f"Failed to update creator: {e}")
            return False

    @Slot(str, result=bool)
    def deleteCreator(self, creator_id: str) -> bool:
        try:
            ok = self._creators_service.delete_creator(creator_id)
            if ok:
                self.creatorsChanged.emit()
                self.successOccurred.emit("Creator removed.")
            return ok
        except Exception as e:
            logger.error(f"Failed to delete creator: {e}")
            self.errorOccurred.emit(f"Failed to delete creator: {e}")
            return False

    @Slot(str, result=str)
    def getCreatorMods(self, creator_id: str) -> str:
        creator = self._creators_service.get_creator(creator_id)
        if not creator:
            return "[]"
        mods = creator.get("mods", [])
        result = []
        for m in mods:
            m_dict = dict(m)
            m_name = m_dict.get("name", "")
            m_cat = m_dict.get("categoryId", "custom_creator")
            m_dict["isInstalled"] = self.isModInstalled(m_name, m_cat) or self.isModInstalled(m_name, "custom")
            m_dict["isFavorite"] = self.isFavorite(m_name, m_cat)
            result.append(m_dict)
        return json.dumps(result, ensure_ascii=False)

    @Slot(str, str, str, str, str, str, result=bool)
    def addCreatorMod(self, creator_id: str, name: str, hero: str, file_path: str, preview_path: str, description: str) -> bool:
        try:
            # Clean file URL if passed from QML
            clean_file = file_path.replace("file:///", "").replace("file://", "")
            clean_file = urllib.parse.unquote(clean_file)
            clean_preview = preview_path.replace("file:///", "").replace("file://", "")
            clean_preview = urllib.parse.unquote(clean_preview)

            mod = self._creators_service.add_mod_to_creator(
                creator_id=creator_id,
                name=name,
                hero=hero,
                file_path=clean_file,
                preview_path=clean_preview,
                description=description
            )
            if mod:
                self.creatorsChanged.emit()
                self.successOccurred.emit(f"Added skin '{mod.get('name')}' successfully!")
                return True
            else:
                self.errorOccurred.emit("Failed to add skin.")
                return False
        except Exception as e:
            logger.error(f"Error adding skin to creator: {e}")
            self.errorOccurred.emit(f"Error: {e}")
            return False

    @Slot(str, str, result=bool)
    def deleteCreatorMod(self, creator_id: str, mod_id: str) -> bool:
        try:
            ok = self._creators_service.delete_mod(creator_id, mod_id)
            if ok:
                self.creatorsChanged.emit()
                self.successOccurred.emit("Custom skin deleted.")
            return ok
        except Exception as e:
            logger.error(f"Failed to delete custom skin: {e}")
            self.errorOccurred.emit(f"Failed to delete: {e}")
            return False

    @Slot(str, str, result=int)
    def importCreatorFolder(self, creator_id: str, folder_path: str) -> int:
        try:
            clean_folder = folder_path.replace("file:///", "").replace("file://", "")
            clean_folder = urllib.parse.unquote(clean_folder)
            imported = self._creators_service.import_folder(creator_id, clean_folder)
            count = len(imported)
            if count > 0:
                self.creatorsChanged.emit()
                self.successOccurred.emit(f"Scanned folder and imported {count} skins!")
            else:
                self.errorOccurred.emit("No .vpk or .zip skins found in this folder.")
            return count
        except Exception as e:
            logger.error(f"Failed to import folder: {e}")
            self.errorOccurred.emit(f"Failed to scan folder: {e}")
            return 0

    @Slot(str, str, result=bool)
    def exportCreatorPack(self, creator_id: str, save_path: str) -> bool:
        try:
            clean_path = save_path.replace("file:///", "").replace("file://", "")
            clean_path = urllib.parse.unquote(clean_path)
            ok = self._creators_service.export_creator_pack(creator_id, clean_path)
            if ok:
                self.successOccurred.emit("Exported Creator Pack successfully!")
            else:
                self.errorOccurred.emit("Failed to export pack.")
            return ok
        except Exception as e:
            logger.error(f"Export pack error: {e}")
            self.errorOccurred.emit(f"Export error: {e}")
            return False

    @Slot(str, result=bool)
    def importCreatorPack(self, pack_path: str) -> bool:
        try:
            clean_path = pack_path.replace("file:///", "").replace("file://", "")
            clean_path = urllib.parse.unquote(clean_path)
            creator = self._creators_service.import_creator_pack(clean_path)
            if creator:
                self.creatorsChanged.emit()
                self.successOccurred.emit(f"Imported pack: {creator.get('name')} with {len(creator.get('mods', []))} skins!")
                return True
            else:
                self.errorOccurred.emit("Failed to import pack file.")
                return False
        except Exception as e:
            logger.error(f"Import pack error: {e}")
            self.errorOccurred.emit(f"Import error: {e}")
            return False

    # --- Native File Dialog Helpers for QML ---

    @Slot(str, str, result=str)
    def chooseFile(self, title: str, filter_str: str) -> str:
        file_path, _ = QFileDialog.getOpenFileName(None, title, "", filter_str)
        return file_path or ""

    @Slot(str, result=str)
    def chooseFolder(self, title: str) -> str:
        folder_path = QFileDialog.getExistingDirectory(None, title, "")
        return folder_path or ""

    @Slot(str, str, str, result=str)
    def chooseSaveFile(self, title: str, default_name: str, filter_str: str) -> str:
        save_path, _ = QFileDialog.getSaveFileName(None, title, default_name, filter_str)
        return save_path or ""

    @Slot(str)
    def openExternalUrl(self, url: str):
        if not url:
            return
        target = url.strip()
        if target.startswith("@"):
            target = f"https://t.me/{target[1:]}"
        elif not target.startswith("http://") and not target.startswith("https://") and not target.startswith("file://"):
            target = f"https://t.me/{target}"
        QDesktopServices.openUrl(QUrl(target))

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
        name_l = (m.name or "").lower()
        cat = str(m.category_id or "").lower()
        tags_str = str(m.tags or "").lower()

        if "arcana" in name_l or "arcana" in tags_str:
            rarity = "arcana"
        elif "persona" in name_l or "persona" in tags_str or any(p in name_l for p in [
            "toy butcher", "lost arts", "disciple's path", "dragon hold",
            "nightsilver", "blueheart", "exile unveiled", "wei"
        ]):
            rarity = "persona"
        elif "immortal" in name_l or "immortal" in tags_str:
            rarity = "immortal"
        elif "collector" in name_l or "cache" in name_l or "mythical" in name_l:
            rarity = "mythical"
        elif "rare" in name_l:
            rarity = "rare"
        else:
            rarity = "standard"

        if "sound" in cat or "voice" in cat or "music" in cat or "audio" in cat:
            slot = "audio"
        elif "fx" in cat or "effect" in cat or "shader" in cat:
            slot = "fx"
        elif any(w in name_l for w in ["weapon", "sword", "blade", "bow", "staff", "gun", "dagger", "axe", "glaive", "scythe", "hammer", "mace", "hook"]):
            slot = "weapon"
        elif "arcana" in name_l or "persona" in name_l or "set" in name_l or "bundle" in name_l or cat == "heroes":
            slot = "set"
        else:
            slot = "item"

        p_url = safe_url(m.preview_url())
        f_url = safe_url(m.file_url())
        f_name = m.file
        p_name = m.preview

        if styles_data:
            if not f_name:
                f_name = styles_data[0].get("file", "")
            if not f_url:
                f_url = styles_data[0].get("fileUrl", "") or safe_url(get_file_url(m.category_id, f_name))
            if not p_name:
                p_name = styles_data[0].get("preview", "")
            if not p_url:
                p_url = styles_data[0].get("previewUrl", "") or safe_url(get_preview_url(m.category_id, p_name))

        return {
            "name": m.name,
            "preview": p_name,
            "previewUrl": image_cache.get_url_or_cached(p_url),
            "file": f_name,
            "fileUrl": f_url,
            "audioUrl": safe_url(m.audio_url()),
            "videoUrl": safe_url(m.video_url()),
            "categoryId": m.category_id,
            "hero": m.hero,
            "tags": m.tags,
            "links": m.links,
            "styles": styles_data,
            "meta": m.meta,
            "rarity": rarity,
            "slot": slot,
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

    @Slot(result=str)
    def getHeroCards(self) -> str:
        """Returns JSON list of all available heroes with rich attributes, skin counts, and artwork."""
        sorted_heroes = sorted(list(set(self._heroes_list)))
        
        exceptions = {
            'anti-mage': 'antimage', 'centaur warrunner': 'centaur', 'clockwerk': 'rattletrap',
            'doom': 'doom_bringer', 'io': 'wisp', 'keeper of the light': 'keeper_of_the_light',
            'lifestealer': 'life_stealer', 'magnus': 'magnataur', 'natures prophet': 'furion',
            'necrophos': 'necrolyte', 'outworld destroyer': 'obsidian_destroyer',
            'queen of pain': 'queenofpain', 'shadow fiend': 'nevermore', 'timbersaw': 'shredder',
            'treant protector': 'treant', 'underlord': 'abyssal_underlord',
            'vengeful spirit': 'vengefulspirit', 'windranger': 'windrunner',
            'wraith king': 'skeleton_king', 'zeus': 'zuus'
        }

        # Dota 2 Primary Attributes Map
        attr_map = {
            # Strength
            'axe': 'str', 'earthshaker': 'str', 'pudge': 'str', 'sand_king': 'str', 'sven': 'str',
            'tiny': 'str', 'kunkka': 'str', 'slardar': 'str', 'tidehunter': 'str', 'skeleton_king': 'str',
            'dragon_knight': 'str', 'rattletrap': 'str', 'life_stealer': 'str', 'omniknight': 'str',
            'huskar': 'str', 'night_stalker': 'str', 'doom_bringer': 'str', 'spirit_breaker': 'str',
            'alchemist': 'str', 'lycan': 'str', 'chaos_knight': 'str', 'treant': 'str', 'ogre_magi': 'str',
            'undying': 'str', 'centaur': 'str', 'magnataur': 'str', 'shredder': 'str', 'bristleback': 'str',
            'tusk': 'str', 'abaddon': 'str', 'elder_titan': 'str', 'legion_commander': 'str',
            'earth_spirit': 'str', 'abyssal_underlord': 'str', 'phoenix': 'str', 'mars': 'str',
            'dawnbreaker': 'str', 'primal_beast': 'str',
            # Agility
            'antimage': 'agi', 'bloodseeker': 'agi', 'drow_ranger': 'agi', 'juggernaut': 'agi',
            'mirana': 'agi', 'morphling': 'agi', 'nevermore': 'agi', 'phantom_lancer': 'agi',
            'razor': 'agi', 'riki': 'agi', 'sniper': 'agi', 'templar_assassin': 'agi',
            'viper': 'agi', 'luna': 'agi', 'clinkz': 'agi', 'broodmother': 'agi', 'bounty_hunter': 'agi',
            'weaver': 'agi', 'spectre': 'agi', 'ursa': 'agi', 'gyrocopter': 'agi', 'lone_druid': 'agi',
            'meepo': 'agi', 'nyx_assassin': 'agi', 'naga_siren': 'agi', 'slark': 'agi',
            'troll_warlord': 'agi', 'ember_spirit': 'agi', 'terrorblade': 'agi', 'arc_warden': 'agi',
            'monkey_king': 'agi', 'pangolier': 'agi', 'hoodwink': 'agi', 'kez': 'agi',
            # Intelligence
            'bane': 'int', 'crystal_maiden': 'int', 'puck': 'int', 'storm_spirit': 'int', 'zuus': 'int',
            'lina': 'int', 'lion': 'int', 'shadow_shaman': 'int', 'witch_doctor': 'int', 'lich': 'int',
            'enigma': 'int', 'tinker': 'int', 'necrolyte': 'int', 'warlock': 'int', 'queenofpain': 'int',
            'death_prophet': 'int', 'pugna': 'int', 'dazzle': 'int', 'leshrac': 'int', 'dark_seer': 'int',
            'enchantress': 'int', 'jakiro': 'int', 'batrider': 'int', 'chen': 'int',
            'ancient_apparition': 'int', 'silencer': 'int', 'obsidian_destroyer': 'int',
            'shadow_demon': 'int', 'rubick': 'int', 'disruptor': 'int', 'keeper_of_the_light': 'int',
            'skywrath_mage': 'int', 'oracle': 'int', 'winter_wyvern': 'int', 'grimstroke': 'int',
            'ringmaster': 'int',
            # Universal
            'dark_willow': 'uni', 'snapfire': 'uni', 'void_spirit': 'uni', 'marci': 'uni',
            'muerta': 'uni', 'techies': 'uni', 'wisp': 'uni', 'visage': 'uni', 'medusa': 'uni',
            'invoker': 'uni', 'venomancer': 'uni', 'faceless_void': 'uni', 'windrunner': 'uni',
            'beastmaster': 'uni', 'brewmaster': 'uni'
        }

        cards = []
        for h in sorted_heroes:
            ln = h.lower().replace("'", "")
            valve_name = exceptions.get(ln, ln.replace(' ', '_').replace('-', '_'))
            img_url = f"https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/{valve_name}.png"
            attr = attr_map.get(valve_name, 'uni')
            roles_svc = getattr(self, "_hero_roles_service", None) or hero_roles_service
            meta = roles_svc.get_hero_meta(valve_name)
            role = meta.get("primary_role", "carry")
            roles = meta.get("roles", [role])
            role_display = meta.get("role_display", role.upper())
            lane_stats = meta.get("lanes", {})
            role_source = meta.get("source", "Dotabuff Meta")
            
            # Count available, installed and special skins for this hero
            h_lower = h.lower()
            skin_count = 0
            inst_count = 0
            fav_count = 0
            has_arcana = False
            has_persona = False
            has_immortal = False

            # Select high-definition featured skin preview (Installed > Arcana > Persona > Immortal > Best Set)
            installed_candidate = None
            arcana_candidate = None
            persona_candidate = None
            immortal_candidate = None
            set_candidate = None

            for cat_id in ["heroes", "hero-items", "herofx", "hero-sounds"]:
                for m in self._mods_data.get(cat_id, []):
                    if (m.hero and h_lower in m.hero.lower()) or h_lower in m.name.lower():
                        skin_count += 1
                        m_name_l = (m.name or "").lower()
                        tags_str = str(m.tags or "").lower()
                        p_url = m.preview_url() if hasattr(m, 'preview_url') else ""

                        is_arc = "arcana" in m_name_l or "arcana" in tags_str
                        is_per = "persona" in m_name_l or "persona" in tags_str or any(p in m_name_l for p in [
                            "toy butcher", "lost arts", "disciple's path", "dragon hold",
                            "nightsilver", "blueheart", "exile unveiled", "wei"
                        ])
                        is_immo = "immortal" in m_name_l or "immortal" in tags_str

                        if is_arc:
                            has_arcana = True
                        if is_per:
                            has_persona = True
                        if is_immo:
                            has_immortal = True

                        is_inst = self.isModInstalled(m.name, m.category_id)
                        if is_inst:
                            inst_count += 1
                            if p_url and not installed_candidate:
                                installed_candidate = m
                        if self.isFavorite(m.name, m.category_id):
                            fav_count += 1

                        if p_url:
                            if is_arc and not arcana_candidate:
                                arcana_candidate = m
                            elif is_per and not persona_candidate:
                                persona_candidate = m
                            elif is_immo and not immortal_candidate:
                                immortal_candidate = m
                            elif not set_candidate and cat_id in ["heroes", "hero-items"]:
                                set_candidate = m

            best_mod = installed_candidate or arcana_candidate or persona_candidate or immortal_candidate or set_candidate
            featured_skin_url = ""
            featured_skin_name = ""
            featured_rarity = "standard"
            if best_mod:
                raw_p_url = safe_url(best_mod.preview_url())
                featured_skin_url = image_cache.get_url_or_cached(raw_p_url)
                featured_skin_name = best_mod.name
                b_name_l = best_mod.name.lower()
                if "arcana" in b_name_l:
                    featured_rarity = "arcana"
                elif "persona" in b_name_l:
                    featured_rarity = "persona"
                elif "immortal" in b_name_l:
                    featured_rarity = "immortal"
                else:
                    featured_rarity = "mythical"

            cards.append({
                "name": h,
                "imageUrl": featured_skin_url or img_url,
                "defaultImageUrl": img_url,
                "skinPreviewUrl": featured_skin_url,
                "skinPreviewName": featured_skin_name,
                "featuredRarity": featured_rarity,
                "valveName": valve_name,
                "attr": attr,
                "role": role,
                "roles": roles,
                "roleDisplay": role_display,
                "laneStats": lane_stats,
                "roleSource": role_source,
                "skinCount": skin_count,
                "installedCount": inst_count,
                "hasArcana": has_arcana,
                "hasPersona": has_persona,
                "hasImmortal": has_immortal,
                "favCount": fav_count
            })
            
        return json.dumps(cards, ensure_ascii=False)

    @Slot(result=bool)
    def refreshHeroRoles(self) -> bool:
        """Fetches latest hero lane positions from online Dotabuff / OpenDota meta."""
        success = self._hero_roles_service.refresh_online(force=True)
        if success:
            self.heroRolesUpdated.emit()
        return success

    @Slot()
    def refreshHeroRolesAsync(self):
        """Triggers background fetch for latest hero roles without blocking UI."""
        self._hero_roles_service.start_background_refresh(
            delay_seconds=0,
            on_complete=lambda ok: self.heroRolesUpdated.emit() if ok else None
        )

    @Slot(str, result=str)
    def getCategoryPreviewImage(self, category_id: str) -> str:
        """Returns the preview image URL of a mod in a given category."""
        mods = self._mods_data.get(category_id, [])
        if mods:
            # Pick a stable mod based on category_id length to avoid flickering in QML
            index = len(category_id) % len(mods)
            mod = mods[index]
            serialized = self._serialize_mod(mod)
            return serialized.get("previewUrl", "")
        return ""

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
        """Translate a data-category label from the remote manifest."""
        label = self._translations.get(key, key)
        return translate_category(label, self._ui_language, key)

    # --- Dashboard Data Slots ---

    @Slot(result=int)
    def getTotalSkinsCount(self) -> int:
        """Returns the total number of skins/mods available across all categories."""
        total = 0
        for mods in self._mods_data.values():
            total += len(mods)
        return total

    @Slot(result=str)
    def getRecentlyInstalled(self) -> str:
        """Returns the 8 most recently installed mods for the dashboard."""
        manifest = self._get_installed_dict()
        items = list(manifest.values())
        # Sort by installedAt descending if available
        items.sort(key=lambda x: x.get("installedAt", ""), reverse=True)
        recent = items[:8]
        for item in recent:
            item["isInstalled"] = True
            item["isFavorite"] = self.isFavorite(item.get("name", ""), item.get("categoryId", ""))
        return json.dumps(recent, ensure_ascii=False)

    # --- Global Search ---

    @Slot(str, result=str)
    def searchMods(self, query: str) -> str:
        """Search every category and creator skins by name/hero/tags. Returns a JSON array."""
        flat = []
        for mods in self._mods_data.values():
            for m in mods:
                flat.append(self._serialize_mod(m))

        # Include custom creator mods
        for creator in self._creators_service.get_all_creators():
            c_name = creator.get("name", "Custom")
            for cm in creator.get("mods", []):
                cm_dict = dict(cm)
                cm_dict["isInstalled"] = self.isModInstalled(cm_dict.get("name", ""), cm_dict.get("categoryId", "custom_creator"))
                cm_dict["isFavorite"] = self.isFavorite(cm_dict.get("name", ""), cm_dict.get("categoryId", "custom_creator"))
                flat.append(cm_dict)

        results = filter_mods(flat, query, category_label=self.translate, limit=60)
        return json.dumps(results, ensure_ascii=False)

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

    @Slot(result=str)
    def validateInstalledMods(self) -> str:
        """Checks game folder for all installed mods and automatically prunes any that were removed from disk."""
        manifest = self._get_installed_dict(validate=True)

        # Check Valve update status if mods are equipped
        if len(manifest) > 0 and self.dotaDetected:
            try:
                from core.dota_launcher import detect_valve_update, repair_gameinfo
                update_status = detect_valve_update(self._dota_path, len(manifest))
                if update_status.get("detected"):
                    if self._auto_reapply_valve_update:
                        ok, msg = repair_gameinfo(self._dota_path)
                        if ok:
                            logger.info("Auto-reapplied gameinfo.gi mod hooks after detected Valve update.")
                            self.successOccurred.emit("Dota 2 была обновлена Valve. Gameinfo.gi автоматически восстановлен!")
                            self._valve_update_detected = False
                            self.gameinfoStatusChanged.emit()
                        else:
                            self._valve_update_detected = True
                            self._valve_update_message = update_status.get("message", "Valve update reset gameinfo.gi")
                            self.gameinfoStatusChanged.emit()
                            self.valveUpdateDetected.emit(json.dumps(update_status))
                    else:
                        self._valve_update_detected = True
                        self._valve_update_message = update_status.get("message", "Valve update reset gameinfo.gi")
                        self.gameinfoStatusChanged.emit()
                        self.valveUpdateDetected.emit(json.dumps(update_status))
            except Exception as e:
                logger.debug(f"Valve update check exception: {e}")

        return json.dumps(list(manifest.values()), ensure_ascii=False)

    @Slot()
    def refreshInstalledMods(self):
        """Triggers a re-scan of the game folder and updates installed status."""
        self.validateInstalledMods()

    @Slot()
    def syncAllInstalled(self):
        """Alias for syncAllMods."""
        self.syncAllMods()

    @Slot()
    def syncAllMods(self):
        """Validates current loadout and re-installs all currently installed mods to sync with the latest versions."""
        manifest = self._get_installed_dict(validate=True)
        if not manifest:
            self.successOccurred.emit("No installed mods to sync. Loadout is clean.")
            return

        to_install = []
        for key, item in manifest.items():
            if not isinstance(item, dict):
                continue
            try:
                cat, name = key.split("::", 1)
            except ValueError:
                cat = item.get("categoryId", "heroes")
                name = item.get("name", "")

            found = False
            category_mods = self._mods_data.get(cat, [])
            for m in category_mods:
                if m.name == name:
                    to_install.append(self._serialize_mod(m))
                    found = True
                    break

            if not found:
                # Creator or custom mod fallback
                file_name = item.get("file", "")
                to_install.append({
                    "name": item.get("name", name),
                    "categoryId": item.get("categoryId", cat),
                    "hero": item.get("hero", ""),
                    "previewUrl": item.get("previewUrl", ""),
                    "file": file_name,
                    "fileUrl": item.get("fileUrl", ""),
                    "filePath": item.get("filePath", ""),
                })

        if to_install:
            self.installBatch(json.dumps(to_install))
        else:
            self.successOccurred.emit("All mods are in sync with your game folder.")

    # --- Mod Health & Integrity Check ---

    @Slot(result=str)
    def checkModsIntegrity(self) -> str:
        """Performs a deep integrity scan of all tracked mods and gameinfo.gi."""
        if not self.dotaDetected:
            res = {
                "healthy": False,
                "totalMods": 0,
                "intactCount": 0,
                "corruptedCount": 0,
                "gameinfoIntact": False,
                "corruptedMods": [],
                "statusMessage": "Dota 2 path is not detected."
            }
            return json.dumps(res, ensure_ascii=False)

        res = self._health_service.check_integrity()
        json_str = json.dumps(res, ensure_ascii=False)
        self.integrityStatusChanged.emit(json_str)
        return json_str

    @Slot()
    def repairModsIntegrity(self):
        """Repairs gameinfo.gi and automatically re-downloads/installs any corrupted or wiped mods."""
        if not self.dotaDetected:
            self.errorOccurred.emit("Please configure a valid Dota 2 game path in Settings first!")
            return

        report = self._health_service.check_integrity()
        # 1. Repair gameinfo.gi
        gi_ok, gi_msg = self._health_service.repair_gameinfo_if_needed()
        if gi_ok:
            self._valve_update_detected = False
            self.gameinfoStatusChanged.emit()

        # 2. Re-install corrupted / missing mods
        corrupted = report.get("corruptedMods", [])
        if corrupted:
            reinstall_items = []
            for item in corrupted:
                cat_id = item.get("categoryId", "heroes")
                name = item.get("name", "")
                mod_def = None
                for m in self._mods_data.get(cat_id, []):
                    if m.name.lower() == name.lower():
                        mod_def = self._serialize_mod(m)
                        break
                if not mod_def:
                    mod_def = dict(item)
                reinstall_items.append(mod_def)

            logger.info(f"Integrity auto-repair: launching batch reinstallation of {len(reinstall_items)} items.")
            self.installBatch(json.dumps(reinstall_items))
        else:
            if gi_ok:
                self.successOccurred.emit("Целостность проверена: все файлы на месте, gameinfo.gi активен!")
            else:
                self.successOccurred.emit("Целостность проверена: все установленные моды в порядке.")
            self.checkModsIntegrity()

    # --- Cloud Backup & Synchronization ---

    @Slot(result=str)
    def createCloudBackup(self) -> str:
        """Uploads a complete snapshot of presets, favorites, loadout and settings to the cloud."""
        presets = self._presets_service.get_user_presets()
        manifest = self._health_service.get_tracked_manifest()
        favorites = self._get_favorites_dict()
        settings = {
            "accentHue": self._accent_hue,
            "uiLanguage": self._ui_language,
            "installLanguage": self._install_language
        }
        payload = self._cloud_backup.create_payload(presets, manifest, favorites, settings)
        ok, code, msg = self._cloud_backup.upload_to_cloud(payload)
        self.cloudBackupFinished.emit(ok, code, msg)
        if ok:
            self.successOccurred.emit(f"Cloud Backup создан! Код: {code}")
        else:
            self.errorOccurred.emit(f"Ошибка создания Cloud Backup: {msg}")
        return json.dumps({"success": ok, "code": code, "message": msg}, ensure_ascii=False)

    @Slot(str, result=str)
    def restoreCloudBackup(self, code_or_key: str) -> str:
        """Restores presets, favorites, loadout and settings from a cloud backup code."""
        ok, msg, data = self._cloud_backup.download_from_cloud(code_or_key)
        if not ok or not data:
            self.errorOccurred.emit(f"Не удалось восстановить Cloud Backup: {msg}")
            return json.dumps({"success": False, "message": msg}, ensure_ascii=False)

        # 1. Restore Presets
        restored_presets = 0
        for p in data.get("presets", []):
            if isinstance(p, dict) and p.get("name"):
                self._presets_service.import_preset(p)
                restored_presets += 1

        # 2. Restore Favorites
        favs = data.get("favorites", {})
        if favs and isinstance(favs, dict):
            self._save_favorites(favs)
            self.favoritesChanged.emit()

        # 3. Restore Settings
        st = data.get("settings", {})
        if st and isinstance(st, dict):
            hue = st.get("accentHue")
            if hue:
                self.accentHue = hue

        # 4. Restore Installed Manifest
        inst = data.get("installedMods", {})
        if inst and isinstance(inst, dict):
            self._save_manifest(inst)
            self.installedModsChanged.emit()

        summary_msg = f"Cloud Backup успешно восстановлен! Загружено пресетов: {restored_presets}, скинов в инвентаре: {len(inst)}"
        self.successOccurred.emit(summary_msg)
        return json.dumps({
            "success": True,
            "message": summary_msg,
            "presetsCount": restored_presets,
            "installedCount": len(inst)
        }, ensure_ascii=False)

    @Slot(str, result=str)
    def exportBackupToFile(self, file_path: str) -> str:
        """Exports profile backup to an offline .ihub_backup file."""
        clean_path = file_path.replace("file:///", "").replace("file://", "")
        presets = self._presets_service.get_user_presets()
        manifest = self._health_service.get_tracked_manifest()
        favorites = self._get_favorites_dict()
        settings = {"accentHue": self._accent_hue, "uiLanguage": self._ui_language, "installLanguage": self._install_language}
        payload = self._cloud_backup.create_payload(presets, manifest, favorites, settings)
        ok, msg = self._cloud_backup.export_to_file(clean_path, payload)
        if ok:
            self.successOccurred.emit(f"Бэкап экспортирован: {os.path.basename(clean_path)}")
        else:
            self.errorOccurred.emit(f"Ошибка экспорта: {msg}")
        return json.dumps({"success": ok, "message": msg}, ensure_ascii=False)

    @Slot(str, result=str)
    def importBackupFromFile(self, file_path: str) -> str:
        """Imports profile backup from an offline .ihub_backup file."""
        clean_path = file_path.replace("file:///", "").replace("file://", "")
        ok, msg, data = self._cloud_backup.import_from_file(clean_path)
        if not ok or not data:
            self.errorOccurred.emit(f"Ошибка загрузки файла бэкапа: {msg}")
            return json.dumps({"success": False, "message": msg}, ensure_ascii=False)

        for p in data.get("presets", []):
            if isinstance(p, dict) and p.get("name"):
                self._presets_service.import_preset(p)
        favs = data.get("favorites", {})
        if favs and isinstance(favs, dict):
            self._save_favorites(favs)
            self.favoritesChanged.emit()
        inst = data.get("installedMods", {})
        if inst and isinstance(inst, dict):
            self._save_manifest(inst)
            self.installedModsChanged.emit()

        self.successOccurred.emit(f"Бэкап успешно загружен из {os.path.basename(clean_path)}")
        return json.dumps({"success": True, "message": msg}, ensure_ascii=False)

    @Slot()
    def randomizeLoadout(self):
        """Picks a random skin for each hero and queues them for installation."""
        to_install = []
        import random
        hero_mods = self._mods_data.get("heroes", [])
        
        mods_by_hero = {}
        for m in hero_mods:
            if m.hero:
                h = m.hero.lower()
                if h not in mods_by_hero:
                    mods_by_hero[h] = []
                mods_by_hero[h].append(m)
        
        for h, mods in mods_by_hero.items():
            if mods:
                chosen = random.choice(mods)
                to_install.append(self._serialize_mod(chosen))
            
        if to_install:
            self.installBatch(json.dumps(to_install))

    @Slot(str, str, result=bool)
    def isModInstalled(self, name: str, category_id: str) -> bool:
        manifest = self._get_installed_dict(validate=True)
        key = f"{category_id}::{name}"
        if key in manifest:
            return True
        for k, v in manifest.items():
            if isinstance(v, dict) and v.get("name") == name:
                return True
        return False

    @Slot(result=str)
    def getInstalledMods(self) -> str:
        manifest = self._get_installed_dict(validate=True)
        items = list(manifest.values())
        return json.dumps(items, ensure_ascii=False)

    @Slot(str, str)
    def uninstallMod(self, name: str, category_id: str):
        manifest = self._get_installed_dict(validate=False)
        key = f"{category_id}::{name}"

        if key not in manifest:
            for k, v in list(manifest.items()):
                if isinstance(v, dict) and v.get("name") == name:
                    key = k
                    break

        item = manifest.get(key, {})
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

        # Additional disk cleanup for custom folders
        self._cleanup_mod_from_disk(name, category_id)

        if key in manifest:
            del manifest[key]
            self._save_manifest(manifest)

        self.installedModsChanged.emit()
        self.totalSavingsChanged.emit()
        self.successOccurred.emit(f"Uninstalled '{name}'. Removed {deleted_count} files/folders.")
        logger.info(f"Uninstalled '{name}'")

    @Slot(str, result=int)
    def uninstallHeroMods(self, hero_name: str) -> int:
        """Uninstalls all active mods belonging to the specified hero."""
        if not hero_name:
            return 0

        manifest = self._get_installed_dict(validate=False)
        hero_lower = hero_name.lower().strip()
        keys_to_delete = []

        for key, item in manifest.items():
            if not isinstance(item, dict):
                continue
            item_hero = (item.get("hero") or "").lower()
            item_name = (item.get("name") or "").lower()
            if (item_hero and hero_lower in item_hero) or (hero_lower in item_name):
                keys_to_delete.append((key, item))

        if not keys_to_delete:
            return 0

        uninstalled_count = 0
        for key, item in keys_to_delete:
            name = item.get("name", "")
            cat_id = item.get("categoryId", "")
            for file_path in item.get("files", []):
                try:
                    if os.path.isdir(file_path):
                        shutil.rmtree(file_path, ignore_errors=True)
                    elif os.path.isfile(file_path):
                        os.remove(file_path)
                except Exception as e:
                    logger.error(f"Error removing {file_path}: {e}")

            self._cleanup_mod_from_disk(name, cat_id)
            if key in manifest:
                del manifest[key]
            uninstalled_count += 1

        self._save_manifest(manifest)
        self.installedModsChanged.emit()
        self.totalSavingsChanged.emit()
        self.successOccurred.emit(f"Uninstalled {uninstalled_count} mods for {hero_name}")
        logger.info(f"Uninstalled {uninstalled_count} mods for hero '{hero_name}'")
        return uninstalled_count

    @Slot()
    def uninstallAll(self):
        """Alias for uninstallAllMods."""
        self.uninstallAllMods()

    @Slot()
    def uninstallAllMods(self):
        """Uninstalls all mods, removes mod files/folders from Dota directories, and clears the manifest."""
        manifest = self._get_installed_dict(validate=False)
        count = len(manifest)

        for item in manifest.values():
            if isinstance(item, dict):
                for file_path in item.get("files", []):
                    try:
                        if os.path.isdir(file_path):
                            shutil.rmtree(file_path, ignore_errors=True)
                        elif os.path.isfile(file_path):
                            os.remove(file_path)
                    except Exception as e:
                        logger.debug(f"Failed to remove file/dir {file_path} during full uninstall: {e}")

        # Clean up any custom mod folders starting with ! in all Dota directories
        if self.dotaDetected and self._dota_path:
            candidate_dirs = [
                os.path.join(self._dota_path, "dota"),
                os.path.join(self._dota_path, "dota_russian"),
                os.path.join(self._dota_path, "dota_schinese"),
                os.path.join(self._dota_path, "dota_koreana"),
            ]
            for d in candidate_dirs:
                if os.path.exists(d) and os.path.isdir(d):
                    try:
                        for entry in os.listdir(d):
                            if entry.startswith("!"):
                                full_p = os.path.join(d, entry)
                                try:
                                    if os.path.isdir(full_p):
                                        shutil.rmtree(full_p, ignore_errors=True)
                                    elif os.path.isfile(full_p):
                                        os.remove(full_p)
                                except Exception as e:
                                    logger.debug(f"Failed removing mod directory {full_p}: {e}")
                    except Exception as e:
                        logger.debug(f"Failed scanning directory {d} during uninstall: {e}")

        self._save_manifest({})
        self.installedModsChanged.emit()
        self.totalSavingsChanged.emit()
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

    @Slot(result=str)
    def browseBackgroundImage(self) -> str:
        start_dir = os.path.expanduser("~")
        path, _ = QFileDialog.getOpenFileName(
            None,
            "Select Background Image",
            start_dir,
            "Images (*.png *.jpg *.jpeg)"
        )
        if path:
            self.bgImagePath = path
            self.successOccurred.emit("Background image updated!")
            return path
        return ""

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

    def _is_mod_present_on_disk(self, item: Dict[str, Any]) -> bool:
        """Checks if at least one file or folder for the installed mod actually exists on disk."""
        if not self.dotaDetected or not self._dota_path:
            return True

        files = item.get("files", [])
        if files and isinstance(files, list):
            for file_path in files:
                if file_path and os.path.exists(file_path):
                    return True
            return False

        # Fallback check for legacy manifest entries without a "files" list
        cat_id = item.get("categoryId", "heroes")
        name = item.get("name", "")
        file_name = item.get("file", "")
        clean_name = os.path.basename(file_name) if file_name else ""
        safe_name = re.sub(r'[^a-zA-Z0-9_]', '_', name)
        safe_folder_name = f"!{cat_id}_{safe_name}"

        candidate_dirs = [
            os.path.join(self._dota_path, "dota"),
            os.path.join(self._dota_path, "dota_russian"),
            os.path.join(self._dota_path, "dota_schinese"),
            os.path.join(self._dota_path, "dota_koreana"),
        ]

        for d in candidate_dirs:
            if not os.path.exists(d):
                continue
            if clean_name and os.path.exists(os.path.join(d, clean_name)):
                return True
            if safe_folder_name and os.path.exists(os.path.join(d, safe_folder_name)):
                return True
            if safe_name and os.path.exists(os.path.join(d, safe_name)):
                return True

        return False

    def _cleanup_mod_from_disk(self, name: str, category_id: str = ""):
        """Removes any extracted or generated folders matching the mod name in Dota directories."""
        if not self.dotaDetected or not self._dota_path or not name:
            return
        safe_name = re.sub(r'[^a-zA-Z0-9_]', '_', name)
        candidate_dirs = [
            os.path.join(self._dota_path, "dota"),
            os.path.join(self._dota_path, "dota_russian"),
            os.path.join(self._dota_path, "dota_schinese"),
            os.path.join(self._dota_path, "dota_koreana"),
        ]
        for d in candidate_dirs:
            if not os.path.exists(d) or not os.path.isdir(d):
                continue
            try:
                for entry in os.listdir(d):
                    full_p = os.path.join(d, entry)
                    if entry.startswith("!") and safe_name.lower() in entry.lower():
                        if os.path.isdir(full_p):
                            shutil.rmtree(full_p, ignore_errors=True)
                            logger.info(f"Cleaned custom mod folder: {full_p}")
                        elif os.path.isfile(full_p):
                            os.remove(full_p)
                            logger.info(f"Cleaned custom mod file: {full_p}")
            except Exception as e:
                logger.debug(f"Error during disk cleanup for mod '{name}': {e}")

    def _setup_fs_watcher(self):
        """Configures QFileSystemWatcher on Dota game folders to detect external skin deletions."""
        if not hasattr(self, "_fs_watcher") or self._fs_watcher is None:
            return
        try:
            existing = self._fs_watcher.directories()
            if existing:
                self._fs_watcher.removePaths(existing)

            if self.dotaDetected and self._dota_path:
                dirs_to_watch = []
                for sub in ["dota", "dota_russian", "dota_schinese", "dota_koreana"]:
                    p = os.path.join(self._dota_path, sub)
                    if os.path.exists(p) and os.path.isdir(p):
                        dirs_to_watch.append(p)
                if dirs_to_watch:
                    self._fs_watcher.addPaths(dirs_to_watch)
                    logger.info(f"File watcher active on Dota dirs: {dirs_to_watch}")
        except Exception as e:
            logger.debug(f"Failed to setup fs watcher: {e}")

    def _on_game_dir_changed(self, path: str):
        logger.debug(f"Dota game folder changed: {path}. Triggering auto-validation...")
        if hasattr(self, "_fs_debounce_timer") and self._fs_debounce_timer:
            self._fs_debounce_timer.start()

    def _emit_installed_changed(self):
        try:
            self.installedModsChanged.emit()
            self.totalSavingsChanged.emit()
        except Exception:
            pass

    def _get_installed_dict(self, validate: bool = True) -> Dict[str, Any]:
        if not os.path.exists(self._manifest_path):
            return {}

        try:
            with open(self._manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)
        except Exception as e:
            logger.error(f"Failed to read installed manifest: {e}")
            return {}

        if not isinstance(manifest, dict):
            return {}

        if validate and self.dotaDetected:
            valid_manifest = {}
            changed = False
            for key, item in manifest.items():
                if not isinstance(item, dict):
                    changed = True
                    continue
                if self._is_mod_present_on_disk(item):
                    item["isCorrupted"] = False
                    if "files" in item and isinstance(item["files"], list):
                        existing_files = [f for f in item["files"] if os.path.exists(f)]
                        if len(existing_files) != len(item["files"]):
                            item["files"] = existing_files
                            changed = True
                    valid_manifest[key] = item
                else:
                    changed = True

            if changed:
                logger.info(f"Auto-pruned {len(manifest) - len(valid_manifest)} missing mods from manifest")
                self._save_manifest(valid_manifest)
                self._emit_installed_changed()
            manifest = valid_manifest

        return manifest

    def _save_manifest(self, manifest: Dict[str, Any]):
        try:
            os.makedirs(os.path.dirname(self._manifest_path), exist_ok=True)
            with open(self._manifest_path, "w", encoding="utf-8") as f:
                json.dump(manifest, f, indent=2, ensure_ascii=False)
            if hasattr(self, "_health_service"):
                self._health_service.sync_backup(manifest)
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
        if os.path.exists(self._settings_path):
            try:
                with open(self._settings_path, "r", encoding="utf-8") as f:
                    s = json.load(f)
                    self._dota_path = s.get("dotaPath", "")
                    self._install_language = s.get("installLanguage", "both")
                    self._ui_language = normalize_lang(s.get("uiLanguage", "en"))
                    self._theme_mode = s.get("themeMode", "cyberpunk")
                    self._accent_hue = s.get("accentHue", "cyan")
                    self._bg_image_path = s.get("bgImagePath", "")
                    loaded_discord_id = s.get("discordClientId", DEFAULT_CLIENT_ID)
                    if loaded_discord_id in ["1541931721216368653", ""]:
                        loaded_discord_id = DEFAULT_CLIENT_ID
                    self._discord_client_id = loaded_discord_id
                    self._auto_reapply_valve_update = s.get("autoReapplyValveUpdate", True)
                    
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
                    "accentHue": self._accent_hue,
                    "bgImagePath": self._bg_image_path,
                    "launchOptions": self._launch_options,
                    "uiLanguage": self._ui_language,
                    "autoReapplyValveUpdate": self._auto_reapply_valve_update
                }, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to save settings: {e}")

    # --- Live Match Slots ---

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
        logger.info("Triggering Demo Match preview...")
        self._live_match_data = self._stats_service.get_mock_match()
        self.liveMatchChanged.emit()
        self.successOccurred.emit("Loaded Live Match Drafting Analytics demo!")

    @Slot()
    def clearLiveMatch(self):
        self._live_match_data = None
        self.liveMatchChanged.emit()

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

    @Slot(str, result=str)
    def exportPresetCode(self, preset_json: str) -> str:
        try:
            p_data = json.loads(preset_json)
            code = self._presets_service.export_preset_code(p_data)
            if code:
                self.copyToClipboard(code)
                self.successOccurred.emit("Preset code copied to clipboard!")
            return code
        except Exception as e:
            logger.error(f"Failed to export preset code: {e}")
            return ""

    @Slot(str, result=bool)
    def importPresetCode(self, code_str: str) -> bool:
        try:
            res = self._presets_service.import_preset_code(code_str)
            if res:
                self.successOccurred.emit(f"Imported preset '{res.get('name', '')}' successfully!")
                return True
            else:
                self.errorOccurred.emit("Invalid preset code format.")
                return False
        except Exception as e:
            logger.error(f"Failed to import preset code: {e}")
            self.errorOccurred.emit("Failed to import preset.")
            return False

    @Slot(result=str)
    def exportCurrentLoadoutCode(self) -> str:
        """Encodes all currently equipped mods into a shareable IHUB-... code and copies it."""
        manifest = self._get_installed_dict(validate=False)
        items = list(manifest.values())
        if not items:
            self.errorOccurred.emit("No active mods equipped to export.")
            return ""
        code = self._presets_service.export_loadout_code(items, "My Active Loadout")
        if code:
            self.copyToClipboard(code)
            self.successOccurred.emit(f"Loadout code for {len(items)} mods copied to clipboard!")
        return code

    @Slot(str, result=str)
    def previewShareCode(self, code_str: str) -> str:
        """Parses a share code and returns JSON data for UI inspection without installing."""
        data = self._presets_service.parse_share_code(code_str)
        if data:
            return json.dumps(data, ensure_ascii=False)
        return ""

    @Slot(str, result=bool)
    def applyShareCode(self, code_str: str) -> bool:
        """Directly queues and installs all mods specified inside a share code."""
        data = self._presets_service.parse_share_code(code_str)
        if not data or "items" not in data or not data["items"]:
            self.errorOccurred.emit("Invalid or empty share code.")
            return False
        
        items = data["items"]
        self.installBatch(json.dumps(items))
        self.successOccurred.emit(f"Applying {len(items)} mods from shared code...")
        return True

    @Slot(str)
    def copyToClipboard(self, text: str):
        try:
            from PySide6.QtWidgets import QApplication
            clipboard = QApplication.clipboard()
            if clipboard:
                clipboard.setText(text)
        except Exception as e:
            logger.error(f"Failed to copy to clipboard: {e}")

    @Slot(result=str)
    def getOptimizedLaunchOptions(self) -> str:
        opts = "-novid -high -map dota -nohltv -nojoy +fps_max 0 +dota_embers 0"
        self.copyToClipboard(opts)
        self.successOccurred.emit("Pro launch options copied to clipboard!")
        return opts

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
        # 1. Ensure gameinfo is patched right before launch to apply mods
        logger.info("Ensuring mod hooks are active before launching for VAC bypass...")
        self.patchGameinfo()

        # 2. Launch the game
        ok, msg = launch_dota_game(self._dota_path, custom_args=self._launch_options)
        if ok:
            self.successOccurred.emit("Launching Dota 2 via Steam...")
            
            # 3. VAC Bypass
            # Revert the gameinfo file on disk after Dota 2 has loaded it into memory.
            # This allows periodic VAC checks to see a clean file while mods remain active.
            def delayed_restore():
                try:
                    logger.info("Executing VAC bypass: restoring gameinfo.gi...")
                    self.restoreGameinfo()
                except Exception as e:
                    logger.error(f"VAC bypass restore failed: {e}")
                    
            QTimer.singleShot(25000, delayed_restore)
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
