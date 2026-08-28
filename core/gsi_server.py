# Dota 2 Game State Integration (GSI) & Log Parser for ImmortalHub
import os
import json
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Optional, Callable, Dict, Any

from core.logger import logger

GSI_CONFIG_CONTENT = """\"ImmortalHub GSI Integration\"
{
    \"uri\"           \"http://127.0.0.1:39888/\"
    \"timeout\"       \"5.0\"
    \"buffer\"        \"0.1\"
    \"throttle\"      \"0.2\"
    \"heartbeat\"     \"30.0\"
    \"data\"
    {
        \"provider\"      \"1\"
        \"map\"           \"1\"
        \"player\"        \"1\"
        \"hero\"          \"1\"
        \"draft\"         \"1\"
        \"wearables\"     \"1\"
    }
}
"""

CLASS_NAME = 'GSIRequestHandler'

class GSIRequestHandler(BaseHTTPRequestHandler):
    on_gsi_payload: Optional[Callable[[Dict[str, Any]], None]] = None

    def do_POST(self):
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            if body:
                payload = json.loads(body.decode('utf-8'))
                if GSIRequestHandler.on_gsi_payload:
                    GSIRequestHandler.on_gsi_payload(payload)
            self.send_response(200)
            self.end_headers()
        except Exception as e:
            logger.debug(f'Error processing GSI payload: {e}')
            self.send_response(500)
            self.end_headers()

    def log_message(self, format, *args):
        pass

class GSIServer:
    def __init__(self, host: str = '127.0.0.1', port: int = 39888):
        self.host = host
        self.port = port
        self.httpd: Optional[HTTPServer] = None
        self._thread: Optional[threading.Thread] = None
        self._is_running = False
        self.on_state_change: Optional[Callable[[Dict[str, Any]], None]] = None
        self.current_state = 'DOTA_GAMERULES_STATE_DISCONNECTED'
        self.current_match_id = ''

    def start(self, callback: Callable[[Dict[str, Any]], None]):
        if self._is_running:
            return
        
        self.on_state_change = callback
        GSIRequestHandler.on_gsi_payload = self._handle_payload

        try:
            self.httpd = HTTPServer((self.host, self.port), GSIRequestHandler)
            self._is_running = True
            self._thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)
            self._thread.start()
            logger.info(f'GSI Server started on {self.host}:{self.port}')
        except Exception as e:
            logger.error(f'Failed to start GSI server: {e}')

    def stop(self):
        if not self._is_running or not self.httpd:
            return
        self._is_running = False
        try:
            self.httpd.shutdown()
            self.httpd.server_close()
            logger.info('GSI Server stopped.')
        except Exception as e:
            logger.debug(f'Error stopping GSI server: {e}')

    def _handle_payload(self, payload: Dict[str, Any]):
        map_info = payload.get('map', {})
        game_state = map_info.get('game_state', 'DOTA_GAMERULES_STATE_DISCONNECTED')
        match_id = map_info.get('matchid', '')
        
        self.current_state = game_state
        self.current_match_id = match_id

        if self.on_state_change:
            self.on_state_change(payload)

    @staticmethod
    def install_gsi_config(dota_path: str) -> bool:
        if not dota_path or not os.path.exists(dota_path):
            return False

        target_dirs = []
        for folder in ['dota', 'dota_russian']:
            cand = os.path.join(dota_path, folder, 'cfg', 'gamestate_integration')
            target_dirs.append(cand)
            cand2 = os.path.join(dota_path, 'cfg', 'gamestate_integration')
            target_dirs.append(cand2)

        installed_any = False
        for cfg_dir in set(target_dirs):
            parent = os.path.dirname(os.path.dirname(cfg_dir))
            if os.path.exists(parent):
                try:
                    os.makedirs(cfg_dir, exist_ok=True)
                    file_path = os.path.join(cfg_dir, 'gamestate_integration_immortalhub.cfg')
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(GSI_CONFIG_CONTENT)
                    logger.info(f'Installed GSI config at {file_path}')
                    installed_any = True
                except Exception as e:
                    logger.error(f'Failed to write GSI config: {e}')

        return installed_any

    @staticmethod
    def is_gsi_installed(dota_path: str) -> bool:
        if not dota_path or not os.path.exists(dota_path):
            return False
        for folder in ['dota', 'dota_russian']:
            cfg = os.path.join(dota_path, folder, 'cfg', 'gamestate_integration', 'gamestate_integration_immortalhub.cfg')
            if os.path.exists(cfg):
                return True
        return False
