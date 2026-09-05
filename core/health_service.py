"""
Mod Health & Integrity Service for ImmortalHub.
Scans installed VPK mods for missing, corrupted, or wiped files after Dota 2 updates,
checks gameinfo.gi search paths, and provides automated 1-click batch repair.
"""
import os
import json
from typing import Dict, Any, List, Tuple, Optional
from core.logger import logger
from core.dota_launcher import check_gameinfo_health, repair_gameinfo


class ModHealthService:
    def __init__(self, dota_path: str, manifest_path: str, app_dir: str):
        self.dota_path = dota_path
        self.manifest_path = manifest_path
        self.app_dir = app_dir
        self.backup_manifest_path = os.path.join(app_dir, "installed_mods_backup.json")

    def sync_backup(self, manifest: Dict[str, Any]):
        """Maintain a persistent backup of the user's intended mod loadout."""
        if not manifest:
            return
        try:
            os.makedirs(os.path.dirname(self.backup_manifest_path), exist_ok=True)
            with open(self.backup_manifest_path, "w", encoding="utf-8") as f:
                json.dump(manifest, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.debug(f"Failed to sync manifest backup: {e}")

    def get_tracked_manifest(self) -> Dict[str, Any]:
        """Loads manifest, falling back to backup if main manifest was wiped."""
        manifest = {}
        if os.path.exists(self.manifest_path):
            try:
                with open(self.manifest_path, "r", encoding="utf-8") as f:
                    manifest = json.load(f)
            except Exception:
                manifest = {}

        if not manifest and os.path.exists(self.backup_manifest_path):
            try:
                with open(self.backup_manifest_path, "r", encoding="utf-8") as f:
                    manifest = json.load(f)
            except Exception:
                manifest = {}

        return manifest if isinstance(manifest, dict) else {}

    def check_integrity(self) -> Dict[str, Any]:
        """
        Deep check of every installed mod:
        1. Verifies that all expected VPK / mod files exist on disk and have size > 0.
        2. Verifies that gameinfo.gi is properly patched with mod search paths.
        """
        manifest = self.get_tracked_manifest()
        
        # Keep backup up to date
        if manifest:
            self.sync_backup(manifest)

        gameinfo_intact = bool(check_gameinfo_health(self.dota_path).get("isHealthy", False)) if self.dota_path else False

        total_mods = len(manifest)
        intact_count = 0
        corrupted_mods = []

        for key, mod in manifest.items():
            if not isinstance(mod, dict):
                continue

            files = mod.get("files", [])
            missing_files = []

            if not files:
                # If no explicit files list, check default target directories
                name = mod.get("name", "")
                cat_id = mod.get("categoryId", "")
                file_name = mod.get("file", "")
                if file_name and self.dota_path:
                    for folder in ["dota", "dota_russian"]:
                        target = os.path.join(self.dota_path, folder, file_name)
                        if not os.path.exists(target) or os.path.getsize(target) == 0:
                            missing_files.append(target)
            else:
                for file_path in files:
                    if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
                        missing_files.append(file_path)

            if missing_files:
                corrupted_mods.append({
                    "key": key,
                    "name": mod.get("name", "Unknown Mod"),
                    "categoryId": mod.get("categoryId", ""),
                    "hero": mod.get("hero", ""),
                    "previewUrl": mod.get("previewUrl", ""),
                    "file": mod.get("file", ""),
                    "missingFiles": missing_files,
                    "targetLanguage": mod.get("targetLanguage", "both")
                })
            else:
                intact_count += 1

        is_healthy = (total_mods == intact_count) and gameinfo_intact if total_mods > 0 else gameinfo_intact

        result = {
            "healthy": is_healthy,
            "totalMods": total_mods,
            "intactCount": intact_count,
            "corruptedCount": len(corrupted_mods),
            "gameinfoIntact": gameinfo_intact,
            "corruptedMods": corrupted_mods,
            "statusMessage": self._build_status_message(is_healthy, total_mods, intact_count, len(corrupted_mods), gameinfo_intact)
        }
        return result

    def _build_status_message(self, healthy: bool, total: int, intact: int, corrupted: int, gi_ok: bool) -> str:
        if total == 0:
            return "No mods installed. Ready to equip skins." if gi_ok else "gameinfo.gi requires search paths patch."
        if healthy:
            return f"All {total} mods verified and intact on disk. Source 2 paths active."
        
        parts = []
        if corrupted > 0:
            parts.append(f"{corrupted} of {total} mods missing files on disk (Steam update or cache wipe)")
        if not gi_ok:
            parts.append("gameinfo.gi search paths missing")
        return "Issues detected: " + ", ".join(parts) + "."

    def repair_gameinfo_if_needed(self) -> Tuple[bool, str]:
        """Repairs gameinfo.gi search paths."""
        if not self.dota_path or not os.path.exists(self.dota_path):
            return False, "Dota 2 path not found."
        return repair_gameinfo(self.dota_path)
