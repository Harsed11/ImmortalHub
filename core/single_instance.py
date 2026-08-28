"""Single-instance guard: only one ImmortalHub may run at a time.

A second launch focuses the already-running window instead of silently
corrupting state (two instances could both patch gameinfo.gi and write
the mod manifest concurrently).
"""

import os
import tempfile

from PySide6.QtCore import QLockFile
from PySide6.QtNetwork import QLocalServer, QLocalSocket

from core.logger import logger

LOCK_FILE = os.path.join(tempfile.gettempdir(), "ImmortalHub.singleinstance.lock")
SERVER_NAME = "ImmortalHub.SingleInstance"


class SingleInstanceGuard:
    def __init__(self):
        self._lock = QLockFile(LOCK_FILE)
        self._server: QLocalServer | None = None

    def try_lock(self) -> bool:
        """Try to become the primary instance. QLockFile handles stale locks."""
        if not self._lock.tryLock(0):
            return False
        # Remove leftovers of a crashed previous instance before listening.
        QLocalServer.removeServer(SERVER_NAME)
        self._server = QLocalServer()
        if not self._server.listen(SERVER_NAME):
            logger.warning(f"Single-instance IPC server failed to listen: {self._server.errorString()}")
        return True

    def notify_running_instance(self) -> bool:
        """Ask the primary instance to raise its window. Returns True on success."""
        socket = QLocalSocket()
        socket.connectToServer(SERVER_NAME)
        if socket.waitForConnected(500):
            socket.write(b"show\n")
            socket.flush()
            socket.waitForBytesWritten(500)
            socket.disconnectFromServer()
            return True
        return False

    def start_server(self, on_activate) -> None:
        """Listen for 'show' requests from secondary instances."""
        if self._server is None:
            return

        def _on_connection():
            sock = self._server.nextPendingConnection()
            if sock is None:
                return

            def _handle_ready():
                sock.readAll()
                try:
                    on_activate()
                except Exception as e:
                    logger.warning(f"Failed to activate window: {e}")

            sock.readyRead.connect(_handle_ready)

        self._server.newConnection.connect(_on_connection)
        logger.info("Single-instance server is listening.")
