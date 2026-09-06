"""
Build Script for ImmortalHub — Dota 2 Skin Changer
Packages the application into a standalone Windows executable.
Usage:
    python build_exe.py           # Builds portable directory in dist/ImmortalHub/
    python build_exe.py --onefile # Builds single ImmortalHub.exe in dist/
"""

import os
import sys
import subprocess
import shutil


def build(onefile: bool = False):
    print("=" * 60)
    print(f"🛡️ Building ImmortalHub Standalone EXE ({'Single File' if onefile else 'Folder Bundle'})")
    print("=" * 60)

    # Check if pyinstaller is available
    try:
        import PyInstaller
    except ImportError:
        print("[*] PyInstaller not found. Installing PyInstaller...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pyinstaller"])

    project_dir = os.path.dirname(os.path.abspath(__file__))
    main_py = os.path.join(project_dir, "main.py")
    qml_dir = os.path.join(project_dir, "qml")
    assets_dir = os.path.join(project_dir, "assets")
    ico_path = os.path.join(assets_dir, "app_icon.ico")

    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--noconsole",
        "--name=ImmortalHub",
        f"--add-data={qml_dir};qml",
        f"--add-data={assets_dir};assets",
        "--hidden-import=PySide6.QtMultimedia",
        "--hidden-import=PySide6.QtQuickControls2",
        "--hidden-import=PySide6.QtQml",
        "--hidden-import=aiohttp",
        "--hidden-import=requests",
        "--hidden-import=pypresence",
        "--clean",
        "--noconfirm",
    ]

    if os.path.exists(ico_path):
        cmd.append(f"--icon={ico_path}")

    if onefile:
        cmd.append("--onefile")

    cmd.append(main_py)

    print(f"[*] Running PyInstaller command: {' '.join(cmd)}")
    subprocess.check_call(cmd, cwd=project_dir)

    dist_dir = os.path.join(project_dir, "dist")
    print("\n" + "=" * 60)
    if onefile:
        exe_file = os.path.join(dist_dir, "ImmortalHub.exe")
        print("✅ Build Successful! Single standalone executable created at:")
        print(f"   {exe_file}")
    else:
        folder_dir = os.path.join(dist_dir, "ImmortalHub")
        print("✅ Build Successful! Portable folder created at:")
        print(f"   {folder_dir}")
        print(f"   Executable: {os.path.join(folder_dir, 'ImmortalHub.exe')}")
    print("=" * 60)


if __name__ == "__main__":
    is_onefile = "--onefile" in sys.argv or "-F" in sys.argv
    build(onefile=is_onefile)
