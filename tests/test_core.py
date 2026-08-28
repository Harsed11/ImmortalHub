"""Unit tests for ImmortalHub core logic. No GUI / network required."""
import os
import zipfile

import pytest

from core.version import APP_VERSION, parse_version
from core.workers import safe_extractall


STOCK_GI = (
    '"gameinfo.gi"\n'
    "{\n"
    "\tFileSystem\n"
    "\t{\n"
    "\t\tSearchPaths\n"
    "\t\t{\n"
    '\t\t\tGame\t\t\t\tdota\n'
    '\t\t\tGame\t\t\t\tcore\n'
    "\t\t}\n"
    "\t}\n"
    "}\n"
)

HOOKS = "\t\t\tGame\t\t\t\tdota/pak\n\t\t\tGame\t\t\t\tdota_russian/pak\n"


def make_dota(tmp_path, relative="dota", content=STOCK_GI):
    gi = tmp_path / relative / "gameinfo.gi"
    gi.parent.mkdir(parents=True, exist_ok=True)
    gi.write_text(content, encoding="utf-8")
    return gi


# --- versioning ---

def test_parse_version_ordering():
    assert parse_version("1.2.3") < parse_version("1.10.0")
    assert parse_version("v1.0.0") == parse_version("1.0.0")
    assert parse_version("1.0.0-alpha") < parse_version("1.0.1")
    assert parse_version("2.0") < parse_version("2.0.1")
    assert parse_version("") == (0, 0, 0)


def test_updater_uses_single_version_source():
    from core import updater
    assert updater.CURRENT_VERSION == APP_VERSION


# --- zip slip protection ---

def test_safe_extractall_blocks_path_traversal(tmp_path):
    archive = tmp_path / "mal.zip"
    with zipfile.ZipFile(archive, "w") as zf:
        zf.writestr("ok.txt", "fine")
        zf.writestr("../evil.txt", "escaped")
        zf.writestr("sub/../../outside.txt", "escaped2")
    dest = tmp_path / "dest"
    dest.mkdir()
    with pytest.raises(ValueError, match="path traversal"):
        with zipfile.ZipFile(archive) as zf:
            safe_extractall(zf, str(dest))
    assert not (tmp_path / "evil.txt").exists()
    assert not (tmp_path / "outside.txt").exists()


def test_safe_extractall_extracts_normal_archive(tmp_path):
    archive = tmp_path / "good.zip"
    with zipfile.ZipFile(archive, "w") as zf:
        zf.writestr("hero/vpk/file.vpk", "data")
        zf.writestr("readme.txt", "hi")
    dest = tmp_path / "dest"
    dest.mkdir()
    with zipfile.ZipFile(archive) as zf:
        safe_extractall(zf, str(dest))
    assert (dest / "hero" / "vpk" / "file.vpk").exists()
    assert (dest / "readme.txt").exists()


# --- gameinfo.gi path resolution ---

def test_gameinfo_paths_supports_root_and_game_folder(tmp_path):
    from core.dota_launcher import get_gameinfo_paths
    make_dota(tmp_path)  # <root>/dota/gameinfo.gi
    paths = get_gameinfo_paths(str(tmp_path))
    assert len(paths) == 1 and paths[0].endswith(os.path.join("dota", "gameinfo.gi"))


def test_gameinfo_paths_supports_game_variant(tmp_path):
    from core.dota_launcher import get_gameinfo_paths
    make_dota(tmp_path, relative=os.path.join("game", "dota"))
    paths = get_gameinfo_paths(str(tmp_path))
    assert len(paths) == 1 and "game" in paths[0]


# --- gameinfo health & repair ---

def test_health_stock_file_needs_repair(tmp_path):
    from core.dota_launcher import check_gameinfo_health
    make_dota(tmp_path)
    health = check_gameinfo_health(str(tmp_path))
    assert health["status"] == "needs_repair"
    assert health["isHealthy"] is False


def test_health_patched_file_is_healthy(tmp_path):
    from core.dota_launcher import check_gameinfo_health
    make_dota(tmp_path, content=STOCK_GI.replace("SearchPaths\n\t\t{", "SearchPaths\n\t\t{\n" + HOOKS))
    health = check_gameinfo_health(str(tmp_path))
    assert health["status"] == "healthy"
    assert health["isHealthy"] is True


def test_health_empty_path_not_found(tmp_path):
    from core.dota_launcher import check_gameinfo_health
    health = check_gameinfo_health(str(tmp_path))
    assert health["status"] == "not_found"


def test_repair_gameinfo_restores_hooks(tmp_path):
    from core.dota_launcher import check_gameinfo_health, repair_gameinfo
    make_dota(tmp_path)
    ok, msg = repair_gameinfo(str(tmp_path))
    assert ok, msg
    gi = tmp_path / "dota" / "gameinfo.gi"
    assert "dota/pak" in gi.read_text(encoding="utf-8")
    # repair_gameinfo creates a timestamped backup (gameinfo.gi.bak_YYYYMMDDHHMMSS)
    backups = list((tmp_path / "dota").glob("gameinfo.gi.bak*"))
    assert backups, "repair must leave a backup of the original file"
    assert check_gameinfo_health(str(tmp_path))["isHealthy"] is True


# --- log watcher ---

def test_log_watcher_tail_scan(tmp_path):
    from core.log_watcher import DotaLogWatcher
    (tmp_path / "console.log").write_text(
        "junk line\n" * 20000
        + "Connecting to public(1.2.3.4:27015) [U:1:123456]\n"
        + "player 76561198765432109 joined\n",
        encoding="utf-8",
    )
    watcher = DotaLogWatcher(dota_path=str(tmp_path))
    ids = watcher.scan_now()
    assert 123456 in ids
    assert 76561198765432109 - 76561197960265728 in ids


# --- lazy singletons / single source of truth ---

def test_image_cache_is_lazy():
    import core.image_cache as ic
    assert isinstance(ic.image_cache, ic._LazyImageCacheProxy)
    assert ic._LazyImageCacheProxy._instance is None
    path = ic.image_cache.get_cache_path("https://example.com/x.jpg")
    assert os.path.basename(path)
    assert ic._LazyImageCacheProxy._instance is not None


def test_discord_rpc_has_single_client_id_source():
    from core.discord_rpc import DEFAULT_CLIENT_ID
    assert DEFAULT_CLIENT_ID and DEFAULT_CLIENT_ID.isdigit()


# --- api mirrors ---

def test_api_mirror_urls_cover_primary_base():
    import api
    for base in api.DATA_BASE_MIRRORS:
        assert base.startswith("https://")
    assert api.BASE_URL == api.DATA_BASE_MIRRORS[0]


def test_api_fetch_json_falls_back_to_mirror(monkeypatch):
    import asyncio
    import api

    attempted = []

    class FakeResp:
        def __init__(self, status):
            self.status = status

        async def json(self, content_type=None):
            return {"ok": True}

    class _Ctx:
        def __init__(self, resp):
            self._resp = resp

        async def __aenter__(self):
            return self._resp

        async def __aexit__(self, *a):
            return False

    class FakeSession:
        def __init__(self, *a, **kw):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *a):
            return False

        def get(self, url):
            attempted.append(url)
            # First mirror (raw.githubusercontent) fails, second one works.
            return _Ctx(FakeResp(200 if len(attempted) >= 2 else 500))

    monkeypatch.setattr("aiohttp.ClientSession", FakeSession)
    result = asyncio.run(api.fetch_json(api.CONSTANTS_JSON))
    assert result == {"ok": True}
    assert len(attempted) == len(api.DATA_BASE_MIRRORS)



# --- i18n (EN/RU) ---

from core.i18n import STRINGS, normalize_lang, translate_ui


def test_normalize_lang_defaults_to_english():
    assert normalize_lang("RU") == "ru"
    assert normalize_lang("en") == "en"
    assert normalize_lang("de") == "en"
    assert normalize_lang(None) == "en"


def test_translate_ui_fallback_chain():
    assert translate_ui("nav.heroes", "ru") == "Скины героев"
    assert translate_ui("nav.heroes", "en") == "Hero Skins"
    # unknown key falls back to the key itself
    assert translate_ui("no.such.key", "ru") == "no.such.key"


def test_every_string_has_en_and_ru():
    for key, entry in STRINGS.items():
        assert "en" in entry and entry["en"], f"{key} missing 'en'"
        assert "ru" in entry and entry["ru"], f"{key} missing 'ru'"


# --- Global mod search ---

from core.mod_search import filter_mods


SEARCH_FIXTURE = [
    {"name": "Invoker robes", "hero": "Invoker", "tags": ["arcana"],
     "categoryId": "heroes", "previewUrl": "", "isInstalled": True, "isFavorite": False},
    {"name": "Aegis icons", "hero": "", "tags": ["hud"],
     "categoryId": "huds", "previewUrl": "", "isInstalled": False, "isFavorite": False},
]


def test_filter_mods_matches_name_hero_and_tags():
    r = filter_mods(SEARCH_FIXTURE, "invo")
    assert len(r) == 1 and r[0]["name"] == "Invoker robes"
    assert len(filter_mods(SEARCH_FIXTURE, "aegis")) == 1
    assert len(filter_mods(SEARCH_FIXTURE, "HUD")) == 1


def test_filter_mods_no_match_returns_empty():
    assert filter_mods(SEARCH_FIXTURE, "zzz") == []
    assert filter_mods(SEARCH_FIXTURE, "") in (SEARCH_FIXTURE, [])

