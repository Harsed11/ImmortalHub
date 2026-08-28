import json
import asyncio
import urllib.parse
from typing import Optional
from dataclasses import dataclass, field

BASE_URL = "https://raw.githubusercontent.com/h6rd/Dota2PornFxWeb/main"
MODS_JSON = f"{BASE_URL}/assets/data/mods.json"
CONSTANTS_JSON = f"{BASE_URL}/assets/data/constants.json"


def safe_url(url: str) -> str:
    """Ensure URL is properly encoded without control characters or raw spaces."""
    if not url:
        return ""
    unquoted = urllib.parse.unquote(url)
    parts = urllib.parse.urlsplit(unquoted)
    encoded_path = urllib.parse.quote(parts.path, safe="/")
    encoded_query = urllib.parse.quote(parts.query, safe="=&")
    return urllib.parse.urlunsplit((parts.scheme, parts.netloc, encoded_path, encoded_query, parts.fragment))


def get_file_url(category_id: str, filename: str) -> str:
    if not filename:
        return ""
    if filename.startswith("http"):
        return safe_url(filename)
    encoded_file = urllib.parse.quote(filename)
    return f"{BASE_URL}/assets/files/{category_id}/{encoded_file}"


def get_preview_url(category_id: str, preview: str) -> str:
    if not preview:
        return ""
    if preview.startswith("http"):
        return safe_url(preview)
    encoded_prev = urllib.parse.quote(preview)
    return f"{BASE_URL}/assets/previews/{category_id}/{encoded_prev}"


@dataclass
class ModStyle:
    label: str = ""
    preview: str = ""
    file: str = ""
    color: str = ""

    def preview_url(self, category_id: str) -> str:
        return get_preview_url(category_id, self.preview)

    def file_url(self, category_id: str) -> str:
        return get_file_url(category_id, self.file)


@dataclass
class ModLink:
    type: str = ""
    url: str = ""
    name: str = ""


@dataclass
class ModItem:
    name: str = ""
    preview: str = ""
    file: str = ""
    category_id: str = ""
    hero: str = ""
    audio_preview: str = ""
    tags: dict = field(default_factory=dict)
    links: list = field(default_factory=list)
    styles: list = field(default_factory=list)
    meta: dict = field(default_factory=dict)

    def preview_url(self) -> str:
        return get_preview_url(self.category_id, self.preview)

    def file_url(self) -> str:
        return get_file_url(self.category_id, self.file)

    def audio_url(self) -> str:
        if self.audio_preview:
            if self.audio_preview.startswith("http"):
                return safe_url(self.audio_preview)
            if self.audio_preview.startswith("assets/"):
                return safe_url(f"{BASE_URL}/{self.audio_preview}")
            return get_preview_url(self.category_id, self.audio_preview)
        return ""


@dataclass
class Category:
    id: str = ""
    key: str = ""
    emoji: str = ""
    preview: str = ""
    hidden: bool = False
    guide_id: str = ""

    def preview_url(self) -> str:
        if self.preview:
            encoded_cat_prev = urllib.parse.quote(self.preview)
            return f"{BASE_URL}/assets/previews/categories/{encoded_cat_prev}"
        return ""


async def fetch_json(url: str) -> dict:
    import aiohttp
    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=30)) as session:
        async with session.get(safe_url(url)) as resp:
            if resp.status == 200:
                return await resp.json(content_type=None)
            raise Exception(f"HTTP {resp.status} for {url}")


async def load_constants() -> dict:
    return await fetch_json(CONSTANTS_JSON)


async def load_mods() -> dict:
    return await fetch_json(MODS_JSON)


def parse_mod(data: dict, category_id: str, hero_name: str = "") -> ModItem:
    import os
    links = []
    audio_preview = ""

    for link_data in data.get("links", []):
        link_type = link_data.get("type", "")
        link_url = link_data.get("url", "")
        links.append(ModLink(
            type=link_type,
            url=link_url,
            name=link_data.get("name", ""),
        ))
        if any(link_url.lower().endswith(ext) for ext in [".mp4", ".mp3", ".wav", ".webm", ".ogg"]):
            audio_preview = link_url

    # Check linkType / linkUrl directly
    if not audio_preview and data.get("linkUrl"):
        l_url = data.get("linkUrl", "")
        if any(l_url.lower().endswith(ext) for ext in [".mp4", ".mp3", ".wav", ".webm", ".ogg"]):
            audio_preview = l_url

    preview_name = data.get("preview", "")
    if any(preview_name.lower().endswith(ext) for ext in [".mp4", ".mp3", ".wav", ".webm", ".ogg"]):
        if not audio_preview:
            audio_preview = preview_name
        # Use .webp thumbnail for Image components
        base_prev = os.path.splitext(preview_name)[0]
        preview_name = f"{base_prev}.webp"

    styles = []
    for style_data in data.get("styles", []):
        style_preview = style_data.get("preview", "")
        style_file = style_data.get("file", "")
        styles.append({
            "label": style_data.get("label", ""),
            "preview": style_preview,
            "previewUrl": get_preview_url(category_id, style_preview),
            "file": style_file,
            "fileUrl": get_file_url(category_id, style_file),
            "color": style_data.get("color", ""),
        })

    return ModItem(
        name=data.get("name", ""),
        preview=preview_name,
        file=data.get("file", ""),
        category_id=category_id,
        hero=hero_name,
        audio_preview=audio_preview,
        tags=data.get("tags", {}),
        links=[l.__dict__ for l in links],
        styles=styles,
        meta=data.get("meta", {}),
    )


def parse_categories(data: dict) -> list[Category]:
    cats = []
    for cat_data in data.get("categories", []):
        cats.append(Category(
            id=cat_data.get("id", ""),
            key=cat_data.get("key", ""),
            emoji=cat_data.get("emoji", ""),
            preview=cat_data.get("preview", ""),
            hidden=cat_data.get("hidden", False),
            guide_id=cat_data.get("guideId", ""),
        ))
    return cats


def parse_all_mods(data: dict) -> dict:
    result = {}
    raw = data.get("modsData", {})
    for cat_id, cat_content in raw.items():
        mods_list = []
        if isinstance(cat_content, dict) and "groups" in cat_content:
            for group in cat_content.get("groups", []):
                hero_or_group_name = group.get("name", "")
                for mod_data in group.get("mods", []):
                    mods_list.append(parse_mod(mod_data, cat_id, hero_name=hero_or_group_name))
        elif isinstance(cat_content, list):
            for mod_data in cat_content:
                mods_list.append(parse_mod(mod_data, cat_id))
        result[cat_id] = mods_list
    return result
