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
DEFAULT_CLIENT_ID = "1545929332399280232"
DEFAULT_LARGE_IMAGE = "logo"
DEFAULT_LARGE_TEXT = "ImmortalHub • Dota 2 Skinchanger"


class DiscordRPCClient:
    def __init__(self, client_id: str = DEFAULT_CLIENT_ID, large_image: str = DEFAULT_LARGE_IMAGE):
        self.client_id = client_id
        self._large_image = large_image
        self._large_text = DEFAULT_LARGE_TEXT
        self._small_image = "dota2"
        self._small_text = "Dota 2"
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

    def set_large_image(self, key_or_url: str, text: str = ""):
        with self._lock:
            self._large_image = key_or_url or DEFAULT_LARGE_IMAGE
            if text:
                self._large_text = text

    def update_presence(
        self,
        details: str = "Managing Dota 2 Custom Skins",
        state: str = "ImmortalHub Active",
        hero: str = "",
        active_mods_count: int = 0,
        large_image: Optional[str] = None,
        large_text: Optional[str] = None,
        small_image: Optional[str] = None,
        small_text: Optional[str] = None,
    ):
        self._ensure_started()
        with self._lock:
            self._current_details = details
            if hero:
                self._current_state = f"Hero: {hero} • {active_mods_count} skins active"
            elif active_mods_count > 0:
                self._current_state = f"{active_mods_count} Active Mods"
            else:
                self._current_state = state

            if large_image is not None:
                self._large_image = large_image
            if large_text is not None:
                self._large_text = large_text
            if small_image is not None:
                self._small_image = small_image
            if small_text is not None:
                self._small_text = small_text

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
                large_image = self._large_image
                large_text = self._large_text
                small_image = self._small_image
                small_text = self._small_text

            kwargs = {
                "details": details[:128],
                "state": state[:128],
                "start": self._start_time,
            }
            if large_image:
                kwargs["large_image"] = large_image
                if large_text:
                    kwargs["large_text"] = large_text[:128]
            if small_image:
                kwargs["small_image"] = small_image
                if small_text:
                    kwargs["small_text"] = small_text[:128]

            try:
                self._rpc.update(**kwargs)
            except Exception:
                # If small_image failed, try with just large_image
                if "small_image" in kwargs:
                    kwargs.pop("small_image", None)
                    kwargs.pop("small_text", None)
                    try:
                        self._rpc.update(**kwargs)
                        return
                    except Exception:
                        pass
                # Final fallback: text only
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
