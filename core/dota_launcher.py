import os
import re
import shutil
import subprocess
import webbrowser
from datetime import datetime
from typing import Tuple, Dict, Any

try:
    from core.logger import logger
except ImportError:
    import logging
    logger = logging.getLogger("DotaLauncher")


DEFAULT_LAUNCH_ARGS = "-novid -high -map dota -dx11 -condebug"  # -condebug enables console.log for the live match watcher


def get_gameinfo_paths(dota_path: str) -> list[str]:
    if not dota_path or not os.path.exists(dota_path):
        return []
    
    paths = []
    # dota_path normally points at the 'game' folder, but may also be the game root
    candidates = [os.path.join(dota_path, "dota", "gameinfo.gi"),
                  os.path.join(dota_path, "game", "dota", "gameinfo.gi")]
    for candidate in candidates:
        if os.path.exists(candidate) and candidate not in paths:
            paths.append(candidate)
    
    candidates = [os.path.join(dota_path, "dota_russian", "gameinfo.gi"),
                  os.path.join(dota_path, "game", "dota_russian", "gameinfo.gi")]
    for candidate in candidates:
        if os.path.exists(candidate) and candidate not in paths:
            paths.append(candidate)
        
    return paths


def check_gameinfo_health(dota_path: str) -> Dict[str, Any]:
    """Check whether gameinfo.gi files are healthy and have mod hooks active."""
    paths = get_gameinfo_paths(dota_path)
    if not paths:
        return {
            "status": "not_found",
            "message": "Dota 2 installation path not found or invalid.",
            "isHealthy": False
        }
    
    all_hooked = True
    details = []

    for gi_path in paths:
        try:
            with open(gi_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            
            # ImmortalHub's canonical hook is 'Game dota/pak' (injected by
            # app.patchGameinfo and repair_gameinfo). Stock gameinfo.gi already
            # contains 'Mod dota' / 'dota_russian' entries, so those must NOT
            # be treated as active hooks.
            has_mod_hook = "dota/pak" in content
            details.append({
                "path": gi_path,
                "hasHook": has_mod_hook
            })
            if not has_mod_hook:
                all_hooked = False
        except Exception as e:
            details.append({"path": gi_path, "error": str(e), "hasHook": False})
            all_hooked = False

    return {
        "status": "healthy" if all_hooked else "needs_repair",
        "message": "All gameinfo.gi mod hooks are active." if all_hooked else "GameInfo.gi was reset by a Dota update. Repair recommended.",
        "isHealthy": all_hooked,
        "details": details
    }


def repair_gameinfo(dota_path: str) -> Tuple[bool, str]:
    """Safely restore and inject mod search paths into gameinfo.gi with backup.

    Injects the same hooks as SkinChangerApp.patchGameinfo ('Game dota/pak'), so
    repair, patching and the gameinfoPatched status stay consistent.
    """
    paths = get_gameinfo_paths(dota_path)
    if not paths:
        return False, "Dota 2 directory not found."

    success_count = 0
    errors = []

    for gi_path in paths:
        try:
            # 1. Create timestamped backup
            bak_path = gi_path + f".bak_{datetime.now().strftime('%Y%m%d%H%M%S')}"
            shutil.copy2(gi_path, bak_path)

            with open(gi_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()

            # Ensure SearchPaths section exists
            search_paths_match = re.search(r'(SearchPaths\s*\{)(.*?)(\})', content, re.DOTALL)
            if search_paths_match:
                inner_paths = search_paths_match.group(2)
                
                # Check if Mod line already present
                if "dota/pak" not in inner_paths:
                    injected_entry = "\n\t\t\tGame\t\t\t\tdota/pak\n\t\t\tGame\t\t\t\tdota_russian/pak"
                    new_inner = injected_entry + inner_paths
                    new_content = content[:search_paths_match.start(2)] + new_inner + content[search_paths_match.end(2):]
                    
                    with open(gi_path, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    success_count += 1
                else:
                    success_count += 1
        except Exception as e:
            errors.append(f"{os.path.basename(gi_path)}: {str(e)}")

    if success_count > 0:
        return True, f"Successfully repaired {success_count} gameinfo files. Mod hooks restored."
    return False, f"Repair failed: {', '.join(errors)}"


def launch_dota_game(dota_path: str, custom_args: str = "") -> Tuple[bool, str]:
    """Launch Dota 2 via Steam protocol or direct executable with launch arguments."""
    args = custom_args.strip() if custom_args else DEFAULT_LAUNCH_ARGS
    
    # 1. Preferred method: Steam URI Protocol
    try:
        steam_uri = f"steam://rungameid/570//{args}"
        webbrowser.open(steam_uri)
        logger.info(f"Launched Dota 2 via Steam URI: {steam_uri}")
        return True, f"Dota 2 launched with args: {args}"
    except Exception as e:
        logger.warning(f"Steam protocol launch failed: {e}. Trying direct dota2.exe...")

    # 2. Fallback: Direct dota2.exe (dota_path may be the game root or the 'game' folder)
    if dota_path and os.path.exists(dota_path):
        exe_candidates = [
            os.path.join(dota_path, "game", "bin", "win64", "dota2.exe"),
            os.path.join(dota_path, "bin", "win64", "dota2.exe"),
        ]
        exe_path = next((p for p in exe_candidates if os.path.exists(p)), "")
        if exe_path:
            try:
                cmd = [exe_path] + args.split()
                subprocess.Popen(cmd, cwd=os.path.dirname(exe_path))
                logger.info(f"Directly executed dota2.exe: {exe_path}")
                return True, "Dota 2 launched via direct executable."
            except Exception as e:
                return False, f"Failed to launch dota2.exe: {e}"

    return False, "Could not launch Dota 2. Ensure Steam or Dota 2 path is configured."
