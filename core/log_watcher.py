# Dota 2 Log Watcher for ImmortalHub
import os
import re
import time
import threading
from typing import Optional, Callable, List, Set

from core.logger import logger

STEAM_ID32_REGEX = re.compile(r'\[U:1:(\d+)\]')
STEAM_ID64_REGEX = re.compile(r'76561198\d{9}')
LOBBY_CONNECT_REGEX = re.compile(r'Connecting to public\(([\d\.:]+)\)')

class DotaLogWatcher:
    def __init__(self, dota_path: str = ''):
        self.dota_path = dota_path
        self._thread: Optional[threading.Thread] = None
        self._is_running = False
        self.on_players_detected: Optional[Callable[[List[int]], None]] = None
        self._last_parsed_ids: Set[int] = set()
        self._last_file_size = 0

    def find_log_files(self) -> List[str]:
        if not self.dota_path or not os.path.exists(self.dota_path):
            return []
        
        # console.log is the only log Dota 2 writes here (requires -condebug).
        # server_log.txt / connection.log are legacy names that never exist.
        candidates = []
        for folder in ['dota', 'dota_russian', '']:
            base = os.path.join(self.dota_path, folder) if folder else self.dota_path
            p = os.path.join(base, 'console.log')
            if os.path.exists(p):
                candidates.append(p)
        return candidates

    def start(self, callback: Callable[[List[int]], None]):
        if self._is_running:
            return
        self.on_players_detected = callback
        self._is_running = True
        self._thread = threading.Thread(target=self._watch_loop, daemon=True)
        self._thread.start()
        logger.info('Dota 2 Log Watcher started.')

    def stop(self):
        self._is_running = False

    @staticmethod
    def _read_tail(path: str, max_bytes: int = 262144) -> str:
        """Read only the last max_bytes of the file to avoid re-reading huge logs."""
        try:
            size = os.path.getsize(path)
            with open(path, 'rb') as f:
                if size > max_bytes:
                    f.seek(-max_bytes, os.SEEK_END)
                data = f.read()
            return data.decode('utf-8', errors='ignore')
        except OSError as e:
            logger.debug(f'Error reading log file {path}: {e}')
            return ''

    def scan_now(self) -> List[int]:
        found_ids = set()
        for fpath in self.find_log_files():
            # _read_tail returns only the last 256 KB instead of loading the
            # whole log into memory every 2 seconds.
            tail = self._read_tail(fpath)
            for line in tail.splitlines():
                # Match [U:1:XXXXX]
                for m in STEAM_ID32_REGEX.findall(line):
                    found_ids.add(int(m))
                # Match 76561198XXXXX
                for m in STEAM_ID64_REGEX.findall(line):
                    acc_id = int(m) - 76561197960265728
                    if acc_id > 0:
                        found_ids.add(acc_id)
        return list(found_ids)

    def _watch_loop(self):
        while self._is_running:
            try:
                ids = self.scan_now()
                if ids and set(ids) != self._last_parsed_ids:
                    self._last_parsed_ids = set(ids)
                    logger.info(f'Detected {len(ids)} player Steam IDs from Dota 2 logs: {ids}')
                    if self.on_players_detected:
                        self.on_players_detected(ids)
            except Exception as e:
                logger.debug(f'Error in log watcher loop: {e}')
            
            time.sleep(2.0)
