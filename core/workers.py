import os
import re
import json
import zipfile
import shutil
import tempfile
import urllib.request
from datetime import datetime
from typing import List, Dict, Any

from PySide6.QtCore import QThread, Signal
from api import get_file_url, safe_url
from core.logger import logger


def safe_extractall(zf: zipfile.ZipFile, dest: str) -> None:
    """Extract a zip archive safely, rejecting path traversal (Zip Slip) entries."""
    dest_real = os.path.realpath(dest)
    for member in zf.infolist():
        target = os.path.realpath(os.path.join(dest, member.filename))
        if target != dest_real and not target.startswith(dest_real + os.sep):
            raise ValueError(f"Blocked unsafe zip entry (path traversal): {member.filename!r}")
    zf.extractall(dest)


class InstallWorker(QThread):
    progress = Signal(int, str, str)   # percent, status, item_name
    modDone = Signal(str, bool, str)   # mod_name, success, message
    batchFinished = Signal(bool, str)  # success, summary

    def __init__(self, items: List[Dict[str, Any]], dota_path: str, manifest_path: str, install_lang: str):
        super().__init__()
        self.items = items
        self.dota_path = dota_path
        self.manifest_path = manifest_path
        self.install_lang = install_lang

    def _get_target_pak_dirs(self) -> List[str]:
        dirs = []
        if self.install_lang == "both":
            dirs.append(os.path.join(self.dota_path, "dota"))
            dirs.append(os.path.join(self.dota_path, "dota_russian"))
        else:
            dirs.append(os.path.join(self.dota_path, self.install_lang))
        return dirs

    def run(self):
        logger.info(f"Starting installation of {len(self.items)} mods.")
        target_pak_dirs = self._get_target_pak_dirs()
        for d in target_pak_dirs:
            os.makedirs(d, exist_ok=True)

        installed_manifest = {}
        if os.path.exists(self.manifest_path):
            try:
                with open(self.manifest_path, "r", encoding="utf-8") as f:
                    installed_manifest = json.load(f)
            except Exception as e:
                logger.error(f"Failed to load manifest: {e}")
                installed_manifest = {}

        total = len(self.items)
        success_count = 0
        errors = []

        for i, mod in enumerate(self.items):
            name = mod.get("name", "Unknown Mod")
            cat_id = mod.get("categoryId", "heroes")
            file_name = mod.get("file", "")
            raw_url = mod.get("fileUrl", get_file_url(cat_id, file_name))
            file_url = safe_url(raw_url)
            preview_url = safe_url(mod.get("previewUrl", ""))
            hero = mod.get("hero", "")

            percent = int((i / total) * 100)
            self.progress.emit(percent, f"Downloading: {name}", name)
            logger.info(f"Downloading mod '{name}' from {file_url}")

            try:
                req = urllib.request.Request(
                    file_url,
                    headers={"User-Agent": "Dota2SkinChangerPro/2.0"}
                )

                with urllib.request.urlopen(req, timeout=60) as resp:
                    data = resp.read()

                created_files = []
                clean_name = os.path.basename(file_name)

                if file_name.lower().endswith(".zip"):
                    safe_temp_name = re.sub(r'[^a-zA-Z0-9_\-\.]', '_', clean_name)
                    tmp_zip = os.path.join(tempfile.gettempdir(), f"d2sc_{safe_temp_name}")
                    with open(tmp_zip, "wb") as f_out:
                        f_out.write(data)

                    temp_extract = os.path.join(tempfile.gettempdir(), f"d2sc_ext_{safe_temp_name}")
                    os.makedirs(temp_extract, exist_ok=True)

                    with zipfile.ZipFile(tmp_zip, "r") as zf:
                        safe_extractall(zf, temp_extract)

                    try:
                        os.remove(tmp_zip)
                    except Exception as e:
                        logger.debug(f"Failed to remove temp zip {tmp_zip}: {e}")

                    # Look for VPK files to copy directly to each target pak/ dir
                    vpk_found = []
                    for root, _, files in os.walk(temp_extract):
                        for file in files:
                            if file.lower().endswith(".vpk"):
                                src_vpk = os.path.join(root, file)
                                vpk_found.append((src_vpk, file))

                    if vpk_found:
                        for target_pak in target_pak_dirs:
                            for src_vpk, vpk_file in vpk_found:
                                dest_vpk = os.path.join(target_pak, vpk_file)
                                shutil.copy2(src_vpk, dest_vpk)
                                created_files.append(dest_vpk)
                    else:
                        # No VPK, copy extracted contents as subfolder
                        safe_folder_name = f"!{cat_id}_{re.sub(r'[^a-zA-Z0-9_]', '_', name)}"
                        for target_pak in target_pak_dirs:
                            dest_folder = os.path.join(target_pak, safe_folder_name)
                            if os.path.exists(dest_folder):
                                shutil.rmtree(dest_folder, ignore_errors=True)
                            shutil.copytree(temp_extract, dest_folder)
                            created_files.append(dest_folder)

                    try:
                        shutil.rmtree(temp_extract, ignore_errors=True)
                    except Exception as e:
                        logger.debug(f"Failed to remove temp extract {temp_extract}: {e}")

                else:
                    # Single VPK or direct resource file
                    for target_pak in target_pak_dirs:
                        out_path = os.path.join(target_pak, clean_name)
                        with open(out_path, "wb") as f_out:
                            f_out.write(data)
                        created_files.append(out_path)

                # Record in manifest
                manifest_key = f"{cat_id}::{name}"
                installed_manifest[manifest_key] = {
                    "name": name,
                    "categoryId": cat_id,
                    "hero": hero,
                    "previewUrl": preview_url,
                    "file": file_name,
                    "files": created_files,
                    "targetLanguage": self.install_lang,
                    "installedAt": datetime.now().strftime("%Y-%m-%d %H:%M"),
                }

                success_count += 1
                logger.info(f"Successfully installed '{name}'.")
                self.modDone.emit(name, True, f"Installed {name}")

            except Exception as e:
                logger.error(f"Failed to install '{name}': {e}", exc_info=True)
                errors.append(f"{name}: {str(e)}")
                self.modDone.emit(name, False, str(e))

            self.progress.emit(int(((i + 1) / total) * 100), f"Finished: {name}", name)

        # Save manifest
        try:
            os.makedirs(os.path.dirname(self.manifest_path), exist_ok=True)
            with open(self.manifest_path, "w", encoding="utf-8") as f:
                json.dump(installed_manifest, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to save manifest to {self.manifest_path}: {e}")

        all_ok = len(errors) == 0
        summary_msg = f"Installed {success_count}/{total} mods successfully."
        if errors:
            summary_msg += f" Errors: {', '.join(errors[:3])}"

        logger.info(f"Batch installation finished. {summary_msg}")
        self.batchFinished.emit(all_ok, summary_msg)
