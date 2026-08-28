import os
import json
import uuid
from typing import List, Dict, Any, Optional

try:
    from core.logger import logger
except ImportError:
    import logging
    logger = logging.getLogger("PresetsService")


BUILTIN_PRESETS = [
    {
        "id": "preset_all_arcana",
        "name": "🔥 ALL ARCANA & IMMORTAL",
        "badge": "CURATED",
        "description": "Full collection of iconic Arcana and Immortal sets across all top heroes (Juggernaut, SF, PA, Invoker, Pudge, Rubick, WK, TB).",
        "icon": "🔥",
        "tags": ["Arcana", "Immortals", "Hero Sets"],
        "targetMods": [
            {"hero": "Juggernaut", "query": "Bladeform Legacy"},
            {"hero": "Phantom Assassin", "query": "Manifold Paradox"},
            {"hero": "Shadow Fiend", "query": "Demon Eater"},
            {"hero": "Invoker", "query": "Dark Artistry"},
            {"hero": "Pudge", "query": "Feast of Abscession"},
            {"hero": "Rubick", "query": "The Magus Cypher"},
            {"hero": "Wraith King", "query": "The One True King"},
            {"hero": "Terrorblade", "query": "Fractured Metaphor"}
        ]
    },
    {
        "id": "preset_ultra_fps",
        "name": "⚡ ULTRA FPS & VISION BOOST",
        "badge": "PERFORMANCE",
        "description": "Maximum competitive visibility and FPS boost: simplified trees, flat clean terrain, and particle optimization.",
        "icon": "⚡",
        "tags": ["FPS Boost", "Trees", "Clear Vision"],
        "targetMods": [
            {"category": "trees", "query": "LowPoly"},
            {"category": "terrains", "query": "Flat"},
            {"category": "shaders", "query": "Outline"}
        ]
    },
    {
        "id": "preset_ti_collector",
        "name": "🌟 THE INTERNATIONAL COLLECTOR",
        "badge": "EXCLUSIVE",
        "description": "Exclusive TI atmosphere: Custom TI battle pass terrain, glowing emblems, custom towers, and versus screens.",
        "icon": "🌟",
        "tags": ["The International", "Terrains", "Emblems"],
        "targetMods": [
            {"category": "emblems", "query": "Aegis"},
            {"category": "versus-screens", "query": "TI"},
            {"category": "terrains", "query": "Reef's Edge"}
        ]
    },
    {
        "id": "preset_anime_cyber",
        "name": "🎌 ANIME & CYBER EDITION",
        "badge": "COMMUNITY",
        "description": "Unique community-made anime models, cyber HUDs, and custom neon particle effects.",
        "icon": "🎌",
        "tags": ["Anime", "Persona", "Cyber"],
        "targetMods": [
            {"category": "heroes", "query": "Anime"},
            {"category": "huds", "query": "Cyber"}
        ]
    }
]


class PresetsService:
    def __init__(self, app_dir: str):
        self.presets_path = os.path.join(app_dir, "presets.json")
        self._user_presets = []
        self._load_user_presets()

    def _load_user_presets(self):
        if os.path.exists(self.presets_path):
            try:
                with open(self.presets_path, "r", encoding="utf-8") as f:
                    self._user_presets = json.load(f)
            except Exception as e:
                logger.error(f"Failed to load user presets: {e}")
                self._user_presets = []
        else:
            self._user_presets = []

    def _save_user_presets(self):
        try:
            with open(self.presets_path, "w", encoding="utf-8") as f:
                json.dump(self._user_presets, f, ensure_ascii=False, indent=2)
        except Exception as e:
            logger.error(f"Failed to save user presets: {e}")

    def get_all_presets(self, all_mods_by_cat: Dict[str, list]) -> List[Dict[str, Any]]:
        result = []
        
        # 1. Built-in Presets
        for p in BUILTIN_PRESETS:
            matched_items = []
            for target in p.get("targetMods", []):
                t_hero = target.get("hero", "").lower()
                t_cat = target.get("category", "")
                t_query = target.get("query", "").lower()

                # Search through categories
                categories_to_search = [t_cat] if t_cat else list(all_mods_by_cat.keys())
                for cat_id in categories_to_search:
                    for m in all_mods_by_cat.get(cat_id, []):
                        m_name = getattr(m, "name", "")
                        m_hero = getattr(m, "hero", "") or ""
                        if t_hero and t_hero not in m_name.lower() and t_hero not in m_hero.lower():
                            continue
                        if t_query and t_query not in m_name.lower():
                            continue
                        
                        matched_items.append({
                            "name": m_name,
                            "categoryId": getattr(m, "category_id", cat_id),
                            "previewUrl": getattr(m, "preview_url", lambda: "")() if callable(getattr(m, "preview_url", None)) else "",
                            "file": getattr(m, "file", "")
                        })
                        break  # Match one per target rule

            result.append({
                "id": p["id"],
                "name": p["name"],
                "badge": p["badge"],
                "description": p["description"],
                "icon": p["icon"],
                "tags": p["tags"],
                "isBuiltin": True,
                "itemCount": len(matched_items),
                "items": matched_items
            })

        # 2. User Presets
        for up in self._user_presets:
            result.append({
                "id": up.get("id", str(uuid.uuid4())),
                "name": up.get("name", "Custom Preset"),
                "badge": "USER",
                "description": up.get("description", "Custom user-saved preset"),
                "icon": up.get("icon", "🎭"),
                "tags": up.get("tags", ["Custom"]),
                "isBuiltin": False,
                "createdAt": up.get("createdAt", ""),
                "itemCount": len(up.get("items", [])),
                "items": up.get("items", [])
            })

        return result

    def save_user_preset(self, name: str, description: str, items: list, tags: list = None) -> dict:
        preset_id = f"user_{uuid.uuid4().hex[:8]}"
        new_preset = {
            "id": preset_id,
            "name": name.strip() or "My Custom Setup",
            "description": description.strip() or f"Preset with {len(items)} skins",
            "icon": "🎭",
            "tags": tags or ["Custom"],
            "items": items,
            "createdAt": os.path.getmtime(self.presets_path) if os.path.exists(self.presets_path) else 0
        }
        self._user_presets.append(new_preset)
        self._save_user_presets()
        return new_preset

    def delete_user_preset(self, preset_id: str) -> bool:
        initial_len = len(self._user_presets)
        self._user_presets = [p for p in self._user_presets if p.get("id") != preset_id]
        if len(self._user_presets) != initial_len:
            self._save_user_presets()
            return True
        return False
