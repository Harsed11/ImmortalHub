import os
import sys
import json
import time
import threading
from typing import Optional

try:
    from core.logger import logger
except ImportError:
    import logging
    logger = logging.getLogger("DiscordRPC")

try:
    import pypresence
    HAS_PYPRESENCE = True
except ImportError:
    HAS_PYPRESENCE = False


# ImmortalHub Custom Application ID
DEFAULT_CLIENT_ID = "1541931721216368653"


class DiscordRPCClient:
    def __init__(self, client_id: str = DEFAULT_CLIENT_ID):
        self.client_id = client_id
        self._rpc = None
        self._connected = False
        self._running = True
        self._start_time = int(time.time())
        self._current_details = "ImmortalHub • Dota 2 Custom Skins"
        self._current_state = "Managing Custom Skins"
        self._lock = threading.Lock()
        self._thread_started = False
        self._worker_thread: Optional[threading.Thread] = None

    def _ensure_started(self):
        """Start the background worker only when presence is actually used."""
        if not HAS_PYPRESENCE or self._thread_started:
            return
        self._thread_started = True
        self._worker_thread = threading.Thread(target=self._run_loop, daemon=True)
        self._worker_thread.start()
        logger.info("Discord Rich Presence thread started.")

    def set_client_id(self, client_id: str):
        if client_id and client_id != self.client_id:
            with self._lock:
                self.client_id = client_id
                self._connected = False
                if self._rpc:
                    try:
                        self._rpc.close()
                    except Exception:
                        pass
                    self._rpc = None

    def update_presence(self, details: str = "Managing Dota 2 Custom Skins", state: str = "ImmortalHub Active", hero: str = "", active_mods_count: int = 0):
        self._ensure_started()
        with self._lock:
            self._current_details = details
            if hero:
                self._current_state = f"Hero: {hero} • {active_mods_count} skins active"
            elif active_mods_count > 0:
                self._current_state = f"{active_mods_count} Active Mods"
            else:
                self._current_state = state

    def _connect(self) -> bool:
        if not HAS_PYPRESENCE:
            return False
        
        try:
            self._rpc = pypresence.Presence(self.client_id)
            self._rpc.connect()
            self._connected = True
            logger.info("Connected to Discord Rich Presence via pypresence.")
            return True
        except Exception:
            self._connected = False
            self._rpc = None
            return False

    def _send_presence(self):
        if not self._connected or not self._rpc:
            return
        
        try:
            with self._lock:
                details = self._current_details
                state = self._current_state

            self._rpc.update(
                details=details[:128],
                state=state[:128],
                start=self._start_time
            )
        except Exception:
            self._connected = False
            if self._rpc:
                try:
                    self._rpc.close()
                except Exception:
                    pass
                self._rpc = None

    def _run_loop(self):
        while self._running:
            try:
                if not self._connected:
                    if self._connect():
                        self._send_presence()
                else:
                    self._send_presence()
            except Exception:
                pass
            time.sleep(15)

    def close(self):
        self._running = False
        if self._rpc:
            try:
                self._rpc.close()
            except Exception:
                pass


discord_rpc = DiscordRPCClient()
