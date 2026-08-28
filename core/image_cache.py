import os
import sys
import hashlib
import urllib.parse
from concurrent.futures import ThreadPoolExecutor
from typing import List, Optional
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from PySide6.QtCore import QObject, Signal, QUrl

# Support running directly or imported
try:
    from core.logger import logger
except ImportError:
    import logging
    logger = logging.getLogger("ImageCache")


def to_cdn_url(url: str) -> str:
    """Convert raw.githubusercontent.com URL to ultra-fast edge CDN mirror."""
    if not url:
        return ""
    if "raw.githubusercontent.com/h6rd/Dota2PornFxWeb/main" in url:
        return url.replace(
            "raw.githubusercontent.com/h6rd/Dota2PornFxWeb/main",
            "cdn.jsdelivr.net/gh/h6rd/Dota2PornFxWeb@main"
        )
    return url


class ImageCacheManager(QObject):
    imageCached = Signal(str, str)  # (url, local_path)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.cache_dir = os.path.join(os.path.expanduser("~"), ".dota2skinchanger", "cache", "previews")
        os.makedirs(self.cache_dir, exist_ok=True)
        
        # High-concurrency requests session with connection pooling
        self.session = requests.Session()
        retry_strategy = Retry(
            total=3,
            backoff_factor=0.2,
            status_forcelist=[429, 500, 502, 503, 504],
        )
        adapter = HTTPAdapter(
            pool_connections=32,
            pool_maxsize=32,
            max_retries=retry_strategy
        )
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)
        self.session.headers.update({
            "User-Agent": "ImmortalHub/1.0",
            "Accept": "image/webp,image/apng,image/*,*/*;q=0.8"
        })
        
        self.executor = ThreadPoolExecutor(max_workers=32, thread_name_prefix="ImgCache")
        self._queued_urls = set()

    def get_cache_path(self, url: str) -> Optional[str]:
        if not url:
            return None
        url_hash = hashlib.md5(url.encode("utf-8")).hexdigest()
        ext = os.path.splitext(urllib.parse.urlparse(url).path)[1]
        if not ext or len(ext) > 5:
            ext = ".jpg"
        return os.path.join(self.cache_dir, f"{url_hash}{ext}")

    def is_cached(self, url: str) -> bool:
        local_path = self.get_cache_path(url)
        return bool(local_path and os.path.exists(local_path) and os.path.getsize(local_path) > 100)

    def get_url_or_cached(self, url: str) -> str:
        """Return local file URI if cached on disk, otherwise return fast CDN URL and queue for background download."""
        if not url:
            return ""
        
        local_path = self.get_cache_path(url)
        if local_path and os.path.exists(local_path) and os.path.getsize(local_path) > 100:
            return QUrl.fromLocalFile(local_path).toString()
        
        # Queue for background download
        if url.startswith("http") and url not in self._queued_urls:
            self._queued_urls.add(url)
            self.executor.submit(self._download_task, url, local_path)
            
        return to_cdn_url(url)

    def prefetch_all(self, urls: List[str]):
        """Bulk queue all URLs for high-speed concurrent prefetching."""
        for url in urls:
            if not url or not url.startswith("http"):
                continue
            local_path = self.get_cache_path(url)
            if local_path and (not os.path.exists(local_path) or os.path.getsize(local_path) < 100):
                if url not in self._queued_urls:
                    self._queued_urls.add(url)
                    self.executor.submit(self._download_task, url, local_path)

    def _download_task(self, url: str, target_path: str):
        try:
            temp_path = target_path + ".tmp"
            # Try CDN first for maximum speed
            download_url = to_cdn_url(url)
            resp = self.session.get(download_url, timeout=6, stream=True)
            if resp.status_code != 200 and download_url != url:
                # Fallback to direct raw URL
                resp = self.session.get(url, timeout=10, stream=True)

            if resp.status_code == 200:
                with open(temp_path, "wb") as f:
                    for chunk in resp.iter_content(chunk_size=16384):
                        f.write(chunk)
                if os.path.exists(temp_path) and os.path.getsize(temp_path) > 100:
                    if os.path.exists(target_path):
                        try:
                            os.remove(target_path)
                        except OSError:
                            pass
                    try:
                        os.rename(temp_path, target_path)
                        self.imageCached.emit(url, target_path)
                    except OSError:
                        pass
        except Exception:
            if os.path.exists(target_path + ".tmp"):
                try:
                    os.remove(target_path + ".tmp")
                except OSError:
                    pass


class _LazyImageCacheProxy:
    """Defers ImageCacheManager (QObject + thread pool) creation until first use.

    Keeps ``from core.image_cache import image_cache`` working everywhere while
    removing import-time side effects before the QApplication exists.
    """

    _instance: Optional["ImageCacheManager"] = None

    def _get(self) -> "ImageCacheManager":
        if _LazyImageCacheProxy._instance is None:
            _LazyImageCacheProxy._instance = ImageCacheManager()
        return _LazyImageCacheProxy._instance

    def __getattr__(self, name):
        return getattr(self._get(), name)


image_cache = _LazyImageCacheProxy()
