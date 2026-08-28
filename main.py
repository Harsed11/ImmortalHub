import sys
import os

from PySide6.QtWidgets import QApplication, QSystemTrayIcon, QMenu
from PySide6.QtCore import QUrl
from PySide6.QtGui import QFontDatabase, QFont, QIcon, QAction
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from core.logger import logger
from core.app import SkinChangerApp
from core.crash_handler import install_crash_handler
from core.single_instance import SingleInstanceGuard


def resource_path(relative_path: str) -> str:
    """Absolute path to a bundled resource. Works from source and frozen (PyInstaller)."""
    base = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base, relative_path)


def main():
    logger.info("Starting ImmortalHub application...")
    install_crash_handler()

    QQuickStyle.setStyle("Basic")
    app = QApplication(sys.argv)
    app.setApplicationName("ImmortalHub")
    app.setOrganizationName("ImmortalHub")
    app.setQuitOnLastWindowClosed(False)

    # Single-instance guard: a second launch focuses the running window instead
    # of starting a duplicate that would corrupt gameinfo.gi / manifest writes.
    guard = SingleInstanceGuard()
    if not guard.try_lock():
        guard.notify_running_instance()
        logger.info("ImmortalHub is already running — focusing the existing window. Exiting.")
        sys.exit(0)

    # Load and register custom gaming & cyberpunk fonts
    fonts_dir = resource_path(os.path.join("assets", "fonts"))
    if os.path.exists(fonts_dir):
        for f in os.listdir(fonts_dir):
            if f.endswith((".ttf", ".otf")):
                font_path = os.path.join(fonts_dir, f)
                font_id = QFontDatabase.addApplicationFont(font_path)
                if font_id != -1:
                    logger.debug(f"Loaded custom font: {f}")

    app.setFont(QFont("Exo 2", 10))

    skin_app = SkinChangerApp()

    engine = QQmlApplicationEngine()

    qml_dir = resource_path("qml")
    engine.addImportPath(qml_dir)

    engine.rootContext().setContextProperty("app", skin_app)

    qml_file = os.path.join(qml_dir, "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        logger.error("Failed to load main QML file. Exiting.")
        sys.exit(1)

    main_window = engine.rootObjects()[0]

    # Raise the existing window when a second instance is started
    def raise_window():
        main_window.show()
        main_window.raise_()
        main_window.activateWindow()

    guard.start_server(raise_window)

    # Setup System Tray
    tray_icon = QSystemTrayIcon(QIcon(resource_path(os.path.join("assets", "app_icon.jpg"))), app)
    tray_icon.setToolTip("ImmortalHub - Dota 2 Skin Changer")

    tray_menu = QMenu()
    
    show_action = QAction("Show ImmortalHub", app)
    show_action.triggered.connect(main_window.show)
    
    quit_action = QAction("Quit", app)
    quit_action.triggered.connect(app.quit)
    
    tray_menu.addAction(show_action)
    tray_menu.addSeparator()
    tray_menu.addAction(quit_action)
    
    tray_icon.setContextMenu(tray_menu)
    tray_icon.show()

    # Double click to show
    def tray_activated(reason):
        if reason == QSystemTrayIcon.DoubleClick:
            main_window.show()
    tray_icon.activated.connect(tray_activated)

    logger.info("UI loaded successfully. Entering event loop.")
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
