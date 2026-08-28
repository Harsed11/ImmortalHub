"""
Build Script for ImmortalHub — Dota 2 Skin Changer
Packages the application into a standalone Windows executable.
"""

import os
import sys
import subprocess
import shutil

def build():
    print("=" * 60)
    print("🛡️ Building ImmortalHub Standalone EXE")
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

    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--noconsole",
        "--name=ImmortalHub",
        f"--add-data={qml_dir};qml",
        "--hidden-import=PySide6.QtMultimedia",
        "--hidden-import=PySide6.QtQuickControls2",
        "--hidden-import=PySide6.QtQml",
        "--hidden-import=aiohttp",
        "--clean",
        "--noconfirm",
        main_py
    ]

    print(f"[*] Running PyInstaller command: {' '.join(cmd)}")
    subprocess.check_call(cmd, cwd=project_dir)

    dist_dir = os.path.join(project_dir, "dist", "ImmortalHub")
    print("\n" + "=" * 60)
    print(f"✅ Build Successful! Portable folder created at:")
    print(f"   {dist_dir}")
    print(f"   Executable: {os.path.join(dist_dir, 'ImmortalHub.exe')}")
    print("=" * 60)

if __name__ == "__main__":
    build()
