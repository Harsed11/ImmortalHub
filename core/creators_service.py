import os
import re
import json
import uuid
import shutil
import zipfile
from datetime import datetime
from typing import List, Dict, Any, Optional

try:
    from core.logger import logger
except ImportError:
    import logging
    logger = logging.getLogger("CreatorsService")

DOTA_HEROES_REFERENCE = [
    "Abaddon", "Alchemist", "Ancient Apparition", "Anti-Mage", "Arc Warden", "Axe",
    "Bane", "Batrider", "Beastmaster", "Bloodseeker", "Bounty Hunter", "Brewmaster",
    "Bristleback", "Broodmother", "Centaur Warrunner", "Chaos Knight", "Chen",
    "Clinkz", "Clockwerk", "Crystal Maiden", "Dark Seer", "Dark Willow", "Dawnbreaker",
    "Dazzle", "Death Prophet", "Disruptor", "Doom", "Dragon Knight", "Drow Ranger",
    "Earth Spirit", "Earthshaker", "Elder Titan", "Ember Spirit", "Enchantress", "Enigma",
    "Faceless Void", "Grimstroke", "Gyrocopter", "Hoodwink", "Huskar", "Invoker", "Io",
    "Jakiro", "Juggernaut", "Keeper of the Light", "Kunkka", "Legion Commander", "Leshrac",
    "Lich", "Lifestealer", "Lina", "Lion", "Lone Druid", "Luna", "Lycan", "Magnus",
    "Marci", "Mars", "Medusa", "Meepo", "Mirana", "Monkey King", "Morphling", "Muerta",
    "Naga Siren", "Nature's Prophet", "Necrophos", "Night Stalker", "Nyx Assassin",
    "Ogre Magi", "Omniknight", "Oracle", "Outworld Destroyer", "Pangolier",
    "Phantom Assassin", "Phantom Lancer", "Phoenix", "Primal Beast", "Puck", "Pudge",
    "Pugna", "Queen of Pain", "Razor", "Riki", "Ringmaster", "Kez", "Rubick",
    "Sand King", "Shadow Demon", "Shadow Fiend", "Shadow Shaman", "Silencer",
    "Skywrath Mage", "Slardar", "Slark", "Snapfire", "Sniper", "Spectre", "Spirit Breaker",
    "Storm Spirit", "Sven", "Techies", "Templar Assassin", "Terrorblade", "Tidehunter",
    "Timbersaw", "Tinker", "Tiny", "Treant Protector", "Troll Warlord", "Tusk",
    "Underlord", "Undying", "Ursa", "Vengeful Spirit", "Venomancer", "Viper", "Visage",
    "Void Spirit", "Warlock", "Weaver", "Windranger", "Winter Wyvern", "Witch Doctor",
    "Wraith King", "Zeus"
]


def detect_hero_from_string(text: str) -> str:
    """Attempt to detect a Dota 2 hero name from a filename or text."""
    if not text:
        return "Custom"
    text_clean = text.lower().replace("_", " ").replace("-", " ")
    for hero in DOTA_HEROES_REFERENCE:
        h_clean = hero.lower().replace("-", " ").replace("'", "")
        # Check whole word match or clean containment
        pattern = r'\b' + re.escape(h_clean) + r'\b'
        if re.search(pattern, text_clean):
            return hero
    # Also check single word parts (e.g. "pa", "sf", "qop", "wk", "tb", "am", "jugg", "invo")
    short_map = {
        "am": "Anti-Mage",
        "pa": "Phantom Assassin",
        "sf": "Shadow Fiend",
        "qop": "Queen of Pain",
        "wk": "Wraith King",
        "tb": "Terrorblade",
        "cm": "Crystal Maiden",
        "es": "Earthshaker",
        "ta": "Templar Assassin",
        "dk": "Dragon Knight",
        "mk": "Monkey King",
        "pl": "Phantom Lancer",
        "jugg": "Juggernaut",
        "invo": "Invoker",
        "wr": "Windranger",
        "lc": "Legion Commander",
        "ls": "Lifestealer",
        "np": "Nature's Prophet",
        "od": "Outworld Destroyer",
        "sk": "Sand King",
        "vs": "Vengeful Spirit",
        "wd": "Witch Doctor",
        "kotl": "Keeper of the Light",
        "ns": "Night Stalker",
        "aa": "Ancient Apparition",
        "bs": "Bloodseeker",
        "bh": "Bounty Hunter",
        "ck": "Chaos Knight",
        "dp": "Death Prophet",
        "ds": "Dark Seer",
        "fv": "Faceless Void",
        "sb": "Spirit Breaker",
    }
    for token in re.findall(r'\b[a-zA-Z0-9]+\b', text_clean):
        if token in short_map:
            return short_map[token]
    return "Custom"


class CreatorsService:
    def __init__(self, app_dir: str):
        self.app_dir = app_dir
        self.catalog_path = os.path.join(app_dir, "creators_catalog.json")
        self.data_dir = os.path.join(app_dir, "creators_data")
        os.makedirs(self.data_dir, exist_ok=True)
        self._creators: List[Dict[str, Any]] = []
        self._load_catalog()

    def _load_catalog(self):
        if os.path.exists(self.catalog_path):
            try:
                with open(self.catalog_path, "r", encoding="utf-8") as f:
                    self._creators = json.load(f)
                    return
            except Exception as e:
                logger.error(f"Failed to load creators catalog: {e}")
        
        # Initial default creators template
        self._creators = [
            {
                "id": "tg_dota2mods",
                "name": "Dota 2 Custom Modders",
                "telegram": "@dota2_custom_skins",
                "description": "Telegram community creating custom Dota 2 VPK skins, anime models, and visual overhauls.",
                "avatar": "",
                "badge": "TELEGRAM",
                "createdAt": datetime.now().strftime("%Y-%m-%d %H:%M"),
                "mods": []
            }
        ]
        self._save_catalog()

    def _save_catalog(self):
        try:
            with open(self.catalog_path, "w", encoding="utf-8") as f:
                json.dump(self._creators, f, ensure_ascii=False, indent=2)
        except Exception as e:
            logger.error(f"Failed to save creators catalog: {e}")

    def get_all_creators(self) -> List[Dict[str, Any]]:
        return self._creators

    def get_creator(self, creator_id: str) -> Optional[Dict[str, Any]]:
        for c in self._creators:
            if c.get("id") == creator_id:
                return c
        return None

    def add_creator(self, name: str, telegram: str = "", description: str = "", avatar_path: str = "", badge: str = "TELEGRAM") -> Dict[str, Any]:
        creator_id = f"creator_{uuid.uuid4().hex[:8]}"
        c_dir = os.path.join(self.data_dir, creator_id)
        os.makedirs(c_dir, exist_ok=True)

        saved_avatar_path = ""
        if avatar_path and os.path.exists(avatar_path):
            try:
                ext = os.path.splitext(avatar_path)[1]
                dest_avatar = os.path.join(c_dir, f"avatar{ext}")
                shutil.copy2(avatar_path, dest_avatar)
                saved_avatar_path = dest_avatar
            except Exception as e:
                logger.error(f"Failed to copy creator avatar: {e}")

        # Format telegram handle
        tg_clean = telegram.strip()
        if tg_clean.startswith("https://t.me/"):
            tg_clean = "@" + tg_clean.replace("https://t.me/", "").rstrip("/")
        elif tg_clean and not tg_clean.startswith("@") and not tg_clean.startswith("http"):
            tg_clean = "@" + tg_clean

        creator = {
            "id": creator_id,
            "name": name.strip() or "Custom Creator",
            "telegram": tg_clean,
            "description": description.strip(),
            "avatar": saved_avatar_path,
            "badge": badge,
            "createdAt": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "mods": []
        }
        self._creators.append(creator)
        self._save_catalog()
        logger.info(f"Created new creator: {creator['name']} ({creator_id})")
        return creator

    def update_creator(self, creator_id: str, name: str, telegram: str = "", description: str = "", avatar_path: str = "") -> bool:
        creator = self.get_creator(creator_id)
        if not creator:
            return False

        creator["name"] = name.strip() or creator["name"]
        
        tg_clean = telegram.strip()
        if tg_clean.startswith("https://t.me/"):
            tg_clean = "@" + tg_clean.replace("https://t.me/", "").rstrip("/")
        elif tg_clean and not tg_clean.startswith("@") and not tg_clean.startswith("http"):
            tg_clean = "@" + tg_clean
        creator["telegram"] = tg_clean

        creator["description"] = description.strip()

        if avatar_path and os.path.exists(avatar_path):
            c_dir = os.path.join(self.data_dir, creator_id)
            os.makedirs(c_dir, exist_ok=True)
            ext = os.path.splitext(avatar_path)[1]
            dest_avatar = os.path.join(c_dir, f"avatar{ext}")
            try:
                shutil.copy2(avatar_path, dest_avatar)
                creator["avatar"] = dest_avatar
            except Exception as e:
                logger.error(f"Failed to update creator avatar: {e}")

        self._save_catalog()
        return True

    def delete_creator(self, creator_id: str) -> bool:
        initial_count = len(self._creators)
        self._creators = [c for c in self._creators if c.get("id") != creator_id]
        if len(self._creators) != initial_count:
            # Clean up directory
            c_dir = os.path.join(self.data_dir, creator_id)
            if os.path.exists(c_dir):
                try:
                    shutil.rmtree(c_dir, ignore_errors=True)
                except Exception as e:
                    logger.debug(f"Failed to remove creator folder {c_dir}: {e}")
            self._save_catalog()
            logger.info(f"Deleted creator {creator_id}")
            return True
        return False

    def add_mod_to_creator(
        self,
        creator_id: str,
        name: str,
        hero: str,
        file_path: str,
        preview_path: str = "",
        description: str = "",
        tags: Optional[List[str]] = None
    ) -> Optional[Dict[str, Any]]:
        creator = self.get_creator(creator_id)
        if not creator:
            logger.error(f"Creator {creator_id} not found.")
            return None

        if not os.path.exists(file_path):
            logger.error(f"Mod file not found: {file_path}")
            return None

        c_dir = os.path.join(self.data_dir, creator_id)
        os.makedirs(c_dir, exist_ok=True)

        mod_id = f"mod_{uuid.uuid4().hex[:8]}"
        base_name = os.path.basename(file_path)
        dest_file = os.path.join(c_dir, f"{mod_id}_{base_name}")
        shutil.copy2(file_path, dest_file)

        saved_preview_path = ""
        if preview_path and os.path.exists(preview_path):
            p_ext = os.path.splitext(preview_path)[1]
            dest_preview = os.path.join(c_dir, f"{mod_id}_preview{p_ext}")
            try:
                shutil.copy2(preview_path, dest_preview)
                saved_preview_path = dest_preview
            except Exception as e:
                logger.error(f"Failed to copy preview: {e}")

        # Hero auto-detection fallback
        final_hero = hero.strip() if hero and hero.strip() else detect_hero_from_string(f"{name} {base_name}")
        final_name = name.strip() or os.path.splitext(base_name)[0]

        file_size = os.path.getsize(dest_file)

        mod_entry = {
            "id": mod_id,
            "name": final_name,
            "hero": final_hero,
            "categoryId": "custom_creator",
            "creatorId": creator_id,
            "creatorName": creator.get("name", "Custom Creator"),
            "file": base_name,
            "filePath": dest_file,
            "preview": os.path.basename(saved_preview_path) if saved_preview_path else "",
            "previewPath": saved_preview_path,
            "previewUrl": f"file:///{saved_preview_path.replace(os.sep, '/')}" if saved_preview_path else "",
            "fileUrl": f"file:///{dest_file.replace(os.sep, '/')}",
            "description": description.strip(),
            "tags": tags or ["VPK", final_hero],
            "sizeBytes": file_size,
            "addedAt": datetime.now().strftime("%Y-%m-%d %H:%M")
        }

        creator["mods"].append(mod_entry)
        self._save_catalog()
        logger.info(f"Added mod '{final_name}' to creator '{creator.get('name')}'")
        return mod_entry

    def delete_mod(self, creator_id: str, mod_id: str) -> bool:
        creator = self.get_creator(creator_id)
        if not creator:
            return False

        target_mod = None
        for m in creator.get("mods", []):
            if m.get("id") == mod_id:
                target_mod = m
                break

        if not target_mod:
            return False

        # Clean files
        if target_mod.get("filePath") and os.path.exists(target_mod["filePath"]):
            try:
                os.remove(target_mod["filePath"])
            except Exception:
                pass
        if target_mod.get("previewPath") and os.path.exists(target_mod["previewPath"]):
            try:
                os.remove(target_mod["previewPath"])
            except Exception:
                pass

        creator["mods"] = [m for m in creator["mods"] if m.get("id") != mod_id]
        self._save_catalog()
        logger.info(f"Deleted mod {mod_id} from creator {creator_id}")
        return True

    def import_folder(self, creator_id: str, folder_path: str) -> List[Dict[str, Any]]:
        """
        Scans a directory for .vpk and .zip files and automatically adds them
        under the given creator with intelligent hero and preview image detection.
        """
        creator = self.get_creator(creator_id)
        if not creator:
            return []

        if not os.path.exists(folder_path) or not os.path.isdir(folder_path):
            return []

        imported = []
        image_extensions = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
        
        # Build index of images in the directory
        all_images = {}
        for root, _, files in os.walk(folder_path):
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in image_extensions:
                    base = os.path.splitext(f)[0].lower()
                    all_images[base] = os.path.join(root, f)

        # Scan for VPK and ZIP
        for root, _, files in os.walk(folder_path):
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in [".vpk", ".zip"]:
                    file_full_path = os.path.join(root, f)
                    raw_stem = os.path.splitext(f)[0]
                    
                    # Clean skin name
                    clean_name = raw_stem.replace("_", " ").replace("-", " ")
                    clean_name = re.sub(r'^\d+[\s\.\-_]*', '', clean_name).strip().title()
                    if not clean_name:
                        clean_name = raw_stem

                    # Hero detection
                    detected_hero = detect_hero_from_string(f"{raw_stem} {root}")

                    # Matching preview image
                    preview_path = ""
                    stem_lower = raw_stem.lower()
                    if stem_lower in all_images:
                        preview_path = all_images[stem_lower]
                    else:
                        # Find closest image in same folder
                        for img_name, img_path in all_images.items():
                            if os.path.dirname(img_path) == root:
                                preview_path = img_path
                                break

                    mod_res = self.add_mod_to_creator(
                        creator_id=creator_id,
                        name=clean_name,
                        hero=detected_hero,
                        file_path=file_full_path,
                        preview_path=preview_path,
                        description=f"Imported from {os.path.basename(folder_path)}"
                    )
                    if mod_res:
                        imported.append(mod_res)

        return imported

    def export_creator_pack(self, creator_id: str, output_zip_path: str) -> bool:
        creator = self.get_creator(creator_id)
        if not creator:
            return False

        try:
            with zipfile.ZipFile(output_zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
                # Add manifest
                pack_manifest = {
                    "creator": {
                        "name": creator.get("name"),
                        "telegram": creator.get("telegram"),
                        "description": creator.get("description"),
                        "badge": creator.get("badge")
                    },
                    "mods": []
                }

                for mod in creator.get("mods", []):
                    rel_vpk = f"files/{os.path.basename(mod['filePath'])}"
                    if os.path.exists(mod.get("filePath", "")):
                        zf.write(mod["filePath"], rel_vpk)

                    rel_prev = ""
                    if mod.get("previewPath") and os.path.exists(mod["previewPath"]):
                        rel_prev = f"previews/{os.path.basename(mod['previewPath'])}"
                        zf.write(mod["previewPath"], rel_prev)

                    pack_manifest["mods"].append({
                        "name": mod.get("name"),
                        "hero": mod.get("hero"),
                        "description": mod.get("description"),
                        "file_rel": rel_vpk,
                        "preview_rel": rel_prev,
                        "tags": mod.get("tags")
                    })

                zf.writestr("pack_manifest.json", json.dumps(pack_manifest, ensure_ascii=False, indent=2))
            return True
        except Exception as e:
            logger.error(f"Failed to export pack: {e}")
            return False

    def import_creator_pack(self, pack_zip_path: str) -> Optional[Dict[str, Any]]:
        if not os.path.exists(pack_zip_path):
            return None

        try:
            with zipfile.ZipFile(pack_zip_path, "r") as zf:
                if "pack_manifest.json" not in zf.namelist():
                    logger.error("Invalid pack: missing pack_manifest.json")
                    return None

                manifest_data = json.loads(zf.read("pack_manifest.json").decode("utf-8"))
                c_info = manifest_data.get("creator", {})
                
                # Create Creator
                new_creator = self.add_creator(
                    name=c_info.get("name", "Imported Creator"),
                    telegram=c_info.get("telegram", ""),
                    description=c_info.get("description", ""),
                    badge=c_info.get("badge", "PACK")
                )
                creator_id = new_creator["id"]
                c_dir = os.path.join(self.data_dir, creator_id)

                for mod in manifest_data.get("mods", []):
                    file_rel = mod.get("file_rel")
                    if file_rel and file_rel in zf.namelist():
                        zf.extract(file_rel, c_dir)
                        extracted_vpk = os.path.join(c_dir, file_rel)

                        extracted_prev = ""
                        prev_rel = mod.get("preview_rel")
                        if prev_rel and prev_rel in zf.namelist():
                            zf.extract(prev_rel, c_dir)
                            extracted_prev = os.path.join(c_dir, prev_rel)

                        self.add_mod_to_creator(
                            creator_id=creator_id,
                            name=mod.get("name", "Custom Skin"),
                            hero=mod.get("hero", "Custom"),
                            file_path=extracted_vpk,
                            preview_path=extracted_prev,
                            description=mod.get("description", ""),
                            tags=mod.get("tags", [])
                        )

                return self.get_creator(creator_id)
        except Exception as e:
            logger.error(f"Failed to import pack: {e}")
            return None
