import os
import re

from core.logger import logger

def detect_steam_dota_path() -> str:
    """Auto-detect Dota 2 game folder on Windows via Steam registry and library folders."""
    candidates = []

    logger.info("Attempting to auto-detect Dota 2 path...")

    # 1. Check Windows Registry
    try:
        import winreg
        for key_root, subkey in [
            (winreg.HKEY_CURRENT_USER, r"Software\Valve\Steam"),
            (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Valve\Steam"),
            (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Valve\Steam")
        ]:
            try:
                with winreg.OpenKey(key_root, subkey) as key:
                    for val_name in ["SteamPath", "InstallPath"]:
                        try:
                            val, _ = winreg.QueryValueEx(key, val_name)
                            if val and os.path.exists(val):
                                candidates.append(val.replace("/", "\\"))
                        except Exception:
                            pass
            except Exception:
                pass
    except Exception as e:
        logger.debug(f"Registry read error: {e}")

    # 2. Common drive paths
    for drive in ["C", "D", "E", "F", "G", "H"]:
        candidates.extend([
            f"{drive}:\\Program Files (x86)\\Steam",
            f"{drive}:\\Program Files\\Steam",
            f"{drive}:\\SteamLibrary",
            f"{drive}:\\Games\\Steam",
            f"{drive}:\\Steam",
        ])

    checked_libraries = set()
    for steam_dir in candidates:
        if not os.path.exists(steam_dir):
            continue
        checked_libraries.add(steam_dir)

        # Parse libraryfolders.vdf
        vdf = os.path.join(steam_dir, "steamapps", "libraryfolders.vdf")
        if os.path.exists(vdf):
            try:
                with open(vdf, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                    matches = re.findall(r'"path"\s+"([^"]+)"', content)
                    for m in matches:
                        clean_p = m.replace("\\\\", "\\")
                        if os.path.exists(clean_p):
                            checked_libraries.add(clean_p)
            except Exception as e:
                logger.debug(f"Error reading libraryfolders.vdf at {vdf}: {e}")

    # Check for dota 2 in all libraries
    for lib in checked_libraries:
        possible_paths = [
            os.path.join(lib, "steamapps", "common", "dota 2 beta", "game"),
            os.path.join(lib, "steamapps", "common", "dota 2 beta"),
            os.path.join(lib, "dota 2 beta", "game"),
        ]
        for p in possible_paths:
            if os.path.exists(os.path.join(p, "dota", "gameinfo.gi")):
                logger.info(f"Dota 2 found at: {os.path.normpath(p)}")
                return os.path.normpath(p)
            if os.path.exists(os.path.join(p, "game", "dota", "gameinfo.gi")):
                logger.info(f"Dota 2 found at: {os.path.normpath(os.path.join(p, 'game'))}")
                return os.path.normpath(os.path.join(p, "game"))
            if os.path.exists(os.path.join(p, "dota")) and os.path.exists(os.path.join(p, "bin")):
                logger.info(f"Dota 2 found at: {os.path.normpath(p)}")
                return os.path.normpath(p)

    logger.warning("Could not auto-detect Dota 2 path.")
    return ""
