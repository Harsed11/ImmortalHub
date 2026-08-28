"""Global crash handling: log every unhandled exception and inform the user.

Covers the main thread (sys.excepthook), background threads
(threading.excepthook) and routes Qt/QML messages into the log file,
so crashes are never silent.
"""

import sys
import threading
import traceback

from core.logger import logger


def _show_crash_dialog(title: str, summary: str, details: str):
    """Show a Qt critical box if a QApplication exists (best effort)."""
    try:
        from PySide6.QtWidgets import QApplication, QMessageBox
        if QApplication.instance() is None:
            return
        box = QMessageBox(QMessageBox.Icon.Critical, title, summary)
        box.setDetailedText(details)
        box.exec()
    except Exception:
        # Never let the crash reporter itself crash the app.
        pass


def _format(exc_type, exc_value, exc_tb) -> str:
    return "".join(traceback.format_exception(exc_type, exc_value, exc_tb))


def _python_excepthook(exc_type, exc_value, exc_tb):
    if issubclass(exc_type, KeyboardInterrupt):
        sys.__excepthook__(exc_type, exc_value, exc_tb)
        return
    tb_text = _format(exc_type, exc_value, exc_tb)
    logger.critical(f"Unhandled exception in main thread:\n{tb_text}")
    _show_crash_dialog(
        "ImmortalHub — unexpected error",
        f"{exc_type.__name__}: {exc_value}\n\n"
        "The error was written to the log file. Please attach it when reporting the issue.",
        tb_text,
    )


def _threading_excepthook(args: threading.ExceptHookArgs):
    tb_text = _format(args.exc_type, args.exc_value, args.exc_traceback)
    thread_name = args.thread.name if args.thread is not None else "unknown"
    logger.critical(f"Unhandled exception in thread '{thread_name}':\n{tb_text}")


def _qt_message_handler(mode, context, message):
    """Route Qt/QML warnings and errors into our log file."""
    try:
        from PySide6.QtCore import QtMsgType
        location = f" ({context.file}:{context.line})" if context.file else ""
        if mode in (QtMsgType.QtCriticalMsg, QtMsgType.QtFatalMsg):
            logger.error(f"Qt: {message}{location}")
        elif mode == QtMsgType.QtWarningMsg:
            logger.warning(f"Qt: {message}{location}")
        else:
            logger.debug(f"Qt: {message}")
    except Exception:
        pass


def install_crash_handler():
    sys.excepthook = _python_excepthook
    if hasattr(threading, "excepthook"):
        threading.excepthook = _threading_excepthook
    try:
        from PySide6.QtCore import qInstallMessageHandler
        qInstallMessageHandler(_qt_message_handler)
    except Exception:
        pass
    logger.info("Global crash handler installed.")
