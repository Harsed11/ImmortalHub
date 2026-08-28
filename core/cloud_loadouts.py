import json
import zlib
import base64
from typing import Dict, Any, List, Optional

class CloudLoadoutService:
    """
    Encodes and decodes equipped hero cosmetics into short, shareable codes
    Format: IH-<Base64CompressedString>
    Example: IH-eJyrVkpMyk...
    """

    PREFIX = "IH-"

    @staticmethod
    def encode_loadout(hero_name: str, equipped_items: List[Dict[str, Any]]) -> str:
        """
        Compresses a list of equipped items for a hero into a shareable code.
        """
        payload = {
            "v": 1,
            "h": hero_name,
            "items": [
                {
                    "n": item.get("name", ""),
                    "f": item.get("file", ""),
                    "c": item.get("category_id", ""),
                    "s": item.get("style", 0),
                }
                for item in equipped_items
            ]
        }
        raw_json = json.dumps(payload, separators=(',', ':')).encode('utf-8')
        compressed = zlib.compress(raw_json, level=9)
        b64 = base64.urlsafe_b64encode(compressed).decode('utf-8').rstrip('=')
        return f"{CloudLoadoutService.PREFIX}{b64}"

    @staticmethod
    def decode_loadout(code: str) -> Optional[Dict[str, Any]]:
        """
        Decompresses and validates a shareable loadout code.
        """
        if not code:
            return None
        clean_code = code.strip()
        if clean_code.startswith(CloudLoadoutService.PREFIX):
            clean_code = clean_code[len(CloudLoadoutService.PREFIX):]

        # Add back URL-safe base64 padding
        padding_needed = len(clean_code) % 4
        if padding_needed:
            clean_code += "=" * (4 - padding_needed)

        try:
            compressed = base64.urlsafe_b64decode(clean_code.encode('utf-8'))
            raw_json = zlib.decompress(compressed)
            data = json.loads(raw_json.decode('utf-8'))
            return {
                "version": data.get("v", 1),
                "hero": data.get("h", ""),
                "items": [
                    {
                        "name": it.get("n", ""),
                        "file": it.get("f", ""),
                        "category_id": it.get("c", ""),
                        "style": it.get("s", 0),
                    }
                    for it in data.get("items", [])
                ]
            }
        except Exception:
            return None

cloud_loadouts = CloudLoadoutService()
