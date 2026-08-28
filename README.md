<div align="center">

# ⚡ ImmortalHub — Next-Gen Dota 2 Skin Changer

[![Platform](https://img.shields.io/badge/Platform-Windows_x64-00F0FF.svg?style=for-the-badge&logo=windows)](https://github.com/Harsed11/ImmortalHub)
[![Dota 2](https://img.shields.io/badge/Dota_2-Patch_7.38c_Ready-A855F7.svg?style=for-the-badge&logo=dota2)](https://github.com/Harsed11/ImmortalHub)
[![License](https://img.shields.io/badge/License-MIT-10B981.svg?style=for-the-badge)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/Harsed11/ImmortalHub?style=for-the-badge&color=FBBC04)](https://github.com/Harsed11/ImmortalHub/stargazers)

**The ultimate zero-latency, VAC-safe skin changer and cosmetic manager for Dota 2.**  
Unlock all 142+ Arcanas, 850+ Immortals, Custom Announcers, Map Terrains, and Weather Effects with one click.

[🌐 Official Website](https://github.com/Harsed11/ImmortalHub) • [📥 Download Releases](https://github.com/Harsed11/ImmortalHub/releases) • [🐛 Report Issue](https://github.com/Harsed11/ImmortalHub/issues)

</div>

---

## 💎 Features

- ⚡ **Zero-Latency Memory VFS Hook**: Direct Source 2 memory redirection without DirectX injection or FPS loss.
- 🛡️ **100% VAC-Safe**: Client-side cosmetic rendering only. Does not alter server-validated packet streams.
- 🔮 **All Arcanas & Immortals**: Juggernaut Bladeform Legacy, Phantom Assassin Manifold Paradox, Invoker Dark Artistry, Shadow Fiend Demon Eater, Pudge Toy Butcher, and more.
- 🌦️ **Custom Terrains & Weather**: Switch between *Immortal Gardens, Reef's Edge, Emerald Abyss* and *Ash, Rain, Aurora, Moonbeam* weather effects.
- 🎙️ **Custom Sound & Announcer Packs**: Gabe Newell Mega-Kill, Deus Ex Ultra-Kill, Rick & Morty First Blood, and custom Blink Dagger chimes.
- 📡 **Game State Integration (GSI)**: Real-time match telemetry and automatic hero draft detection.
- ☁️ **Cloud Loadouts**: Export and share your dream sets via short 6-character codes (`IH-JUG9X`).
- 🔄 **GitHub Releases Auto-Updater**: 1-click update checks directly within the application settings.

---

## 🚀 Quickstart Guide

### Option 1: Standalone Portable EXE (Recommended)

1. Download the latest `ImmortalHub_Portable_x64.zip` from [Releases](https://github.com/Harsed11/ImmortalHub/releases/latest).
2. Extract the archive anywhere on your PC.
3. Launch `ImmortalHub.exe` (Run as Administrator).
4. The application will automatically detect your Steam Dota 2 directory.
5. Select any skin, map, or weather effect and click **Inject**!

### Option 2: Running from Source (Developers)

```bash
# 1. Clone the repository
git clone https://github.com/Harsed11/ImmortalHub.git
cd ImmortalHub

# 2. Set up virtual environment
python -m venv .venv
.venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Launch ImmortalHub
python main.py
```

---

## 🛠️ Building Standalone Executable

To build your own portable `.exe` bundle using PyInstaller:

```bash
python build_exe.py
```

The output will be placed in `dist/ImmortalHub/ImmortalHub.exe`.

---

## 📂 Project Architecture

```
ImmortalHub/
├── core/                  # Core Python modules
│   ├── app.py             # Main QML Controller & Signal Engine
│   ├── cloud_loadouts.py  # Shareable Loadout Code Generator
│   ├── updater.py         # GitHub Releases Auto-Updater
│   ├── gsi_server.py      # Real-time Game State Integration
│   ├── dota_launcher.py   # Steam launch & GameInfo patcher
│   ├── discord_rpc.py     # Discord Rich Presence integration
│   └── stats_service.py   # Live match stats parser
├── qml/                   # Modern Cyberpunk Qt Quick / QML UI
│   ├── Main.qml           # Master Window Layout & Sidebar
│   ├── views/             # Views (Heroes, Installed, Live Match, Settings)
│   └── theme/             # SkinTheme styling tokens & neon colors
├── website/               # Next-Gen React + Vite Landing Page
│   └── src/               # Canvas 2D Particle Engine & Showcase UI
├── .github/workflows/     # CI/CD Automated PyInstaller Builds
├── build_exe.py           # Standalone packaging script
└── main.py                # Application entrypoint
```

---

## ⚖️ Disclaimer

Dota 2 and Valve are registered trademarks of Valve Corporation. ImmortalHub is an open-source educational cosmetic tool and is not affiliated with, endorsed by, or associated with Valve Corporation.
