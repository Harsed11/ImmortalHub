import asyncio
import aiohttp
from typing import Optional, Dict, Any
from core.logger import logger

CURRENT_VERSION = "1.0.0"
GITHUB_REPO = "Harsed11/ImmortalHub"
API_RELEASES_URL = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"

class UpdateChecker:
    """
    Checks GitHub Releases for new ImmortalHub executable updates.
    """

    @staticmethod
    async def check_for_updates() -> Optional[Dict[str, Any]]:
        try:
            headers = {"User-Agent": "ImmortalHub-Updater"}
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=10)) as session:
                async with session.get(API_RELEASES_URL, headers=headers) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        tag_name = data.get("tag_name", "").lstrip("v")
                        if tag_name and tag_name != CURRENT_VERSION:
                            download_url = data.get("html_url", f"https://github.com/{GITHUB_REPO}/releases")
                            # Find exe asset if available
                            for asset in data.get("assets", []):
                                if asset.get("name", "").endswith(".exe"):
                                    download_url = asset.get("browser_download_url", download_url)
                                    break

                            return {
                                "has_update": True,
                                "latest_version": tag_name,
                                "current_version": CURRENT_VERSION,
                                "release_notes": data.get("body", "New performance enhancements and VPK updates."),
                                "download_url": download_url,
                                "published_at": data.get("published_at", ""),
                            }
        except Exception as e:
            logger.debug(f"Update check failed (offline or rate limited): {e}")

        return None

updater = UpdateChecker()
