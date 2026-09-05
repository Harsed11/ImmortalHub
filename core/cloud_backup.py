"""
Cloud Backup & Profile Synchronization Service for ImmortalHub.
Allows backing up presets, favorites, installed loadout, and settings to the cloud
(via Bytebin with fallback to local .ihub_backup archives) using short IHUB-CLOUD-... keys.
"""
import os
import re
import json
import time
import urllib.request
import urllib.parse
from typing import Dict, Any, Tuple, Optional
from core.logger import logger

BYTEBIN_URL = "https://bytebin.lucko.me"
USER_AGENT = "ImmortalHub-Desktop/2.0"


class CloudBackupService:
    def __init__(self, app_dir: str):
        self.app_dir = app_dir
        self.backups_dir = os.path.join(app_dir, "backups")
        os.makedirs(self.backups_dir, exist_ok=True)

    @staticmethod
    def extract_key(code_or_url: str) -> str:
        """Extracts the 10-char bytebin key from raw key, IHUB-CLOUD-... or URL."""
        if not code_or_url:
            return ""
        s = code_or_url.strip()
        if s.startswith("IHUB-CLOUD-"):
            s = s[len("IHUB-CLOUD-"):]
        elif "bytebin.lucko.me/" in s:
            s = s.split("bytebin.lucko.me/")[-1].split("?")[0].split("/")[0]
        # Clean alphanumeric key
        match = re.search(r"[A-Za-z0-9_-]{6,30}", s)
        return match.group(0) if match else s

    def create_payload(
        self,
        presets: list,
        installed_mods: dict,
        favorites: dict,
        settings: dict
    ) -> Dict[str, Any]:
        """Creates a standardized backup bundle."""
        return {
            "appName": "ImmortalHub",
            "version": 2,
            "createdAt": int(time.time()),
            "presets": presets or [],
            "installedMods": installed_mods or {},
            "favorites": favorites or {},
            "settings": {
                "accentHue": settings.get("accentHue", "cyan"),
                "uiLanguage": settings.get("uiLanguage", "en"),
                "installLanguage": settings.get("installLanguage", "both"),
            }
        }

    def save_local_snapshot(self, payload: Dict[str, Any]) -> str:
        """Saves a local snapshot in the user's backups directory."""
        filename = f"backup_{int(time.time())}.ihub_backup"
        filepath = os.path.join(self.backups_dir, filename)
        latest_path = os.path.join(self.backups_dir, "backup_latest.ihub_backup")
        try:
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(payload, f, indent=2, ensure_ascii=False)
            with open(latest_path, "w", encoding="utf-8") as f:
                json.dump(payload, f, indent=2, ensure_ascii=False)
            return filepath
        except Exception as e:
            logger.error(f"Failed to save local snapshot: {e}")
            return ""

    def upload_to_cloud(self, payload: Dict[str, Any]) -> Tuple[bool, str, str]:
        """
        Uploads backup payload to Bytebin.
        Returns (success: bool, share_code: str, message: str)
        """
        # First guarantee local snapshot
        local_path = self.save_local_snapshot(payload)

        try:
            raw_data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            req = urllib.request.Request(
                f"{BYTEBIN_URL}/post",
                data=raw_data,
                headers={
                    "User-Agent": USER_AGENT,
                    "Content-Type": "application/json"
                }
            )
            with urllib.request.urlopen(req, timeout=12) as resp:
                res = json.loads(resp.read().decode("utf-8"))
                key = res.get("key", "")
                if key:
                    code = f"IHUB-CLOUD-{key}"
                    logger.info(f"Cloud backup uploaded successfully: {code}")
                    return True, code, "Backup successfully uploaded to cloud."
                else:
                    return False, "", "Cloud response did not return a valid backup key."
        except Exception as e:
            logger.error(f"Cloud backup upload failed: {e}")
            return False, "", f"Cloud upload error: {e}"

    def download_from_cloud(self, code_or_key: str) -> Tuple[bool, str, Optional[Dict[str, Any]]]:
        """
        Downloads and validates backup payload from cloud key or code.
        Returns (success: bool, message: str, payload: dict | None)
        """
        key = self.extract_key(code_or_key)
        if not key:
            return False, "Invalid cloud backup code format.", None

        try:
            req = urllib.request.Request(
                f"{BYTEBIN_URL}/{key}",
                headers={"User-Agent": USER_AGENT}
            )
            with urllib.request.urlopen(req, timeout=12) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                if not isinstance(data, dict):
                    return False, "Invalid backup data structure.", None
                
                # Validation
                if "presets" not in data and "installedMods" not in data and "favorites" not in data:
                    return False, "Backup does not contain valid ImmortalHub profile data.", None

                return True, "Cloud backup retrieved successfully.", data
        except Exception as e:
            logger.error(f"Cloud backup fetch failed for key '{key}': {e}")
            return False, f"Could not retrieve cloud backup: {e}", None

    def export_to_file(self, target_path: str, payload: Dict[str, Any]) -> Tuple[bool, str]:
        """Exports backup to a user-chosen file path."""
        try:
            with open(target_path, "w", encoding="utf-8") as f:
                json.dump(payload, f, indent=2, ensure_ascii=False)
            return True, f"Backup exported to {os.path.basename(target_path)}"
        except Exception as e:
            return False, f"Export failed: {e}"

    def import_from_file(self, source_path: str) -> Tuple[bool, str, Optional[Dict[str, Any]]]:
        """Imports backup from a user-chosen file path."""
        if not os.path.exists(source_path):
            return False, "File does not exist.", None
        try:
            with open(source_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if not isinstance(data, dict) or ("presets" not in data and "installedMods" not in data):
                return False, "Selected file is not a valid ImmortalHub backup archive.", None
            return True, "Backup file loaded successfully.", data
        except Exception as e:
            return False, f"Failed to read backup file: {e}", None
