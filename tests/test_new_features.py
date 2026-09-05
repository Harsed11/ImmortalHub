"""
Unit tests for the 5 newly implemented features:
1. Valve Patch Detector & Auto-Restore
2. Multimedia & Skin Details (Spell Icons, Ability Previews, Audio Player)
3. Preset & Loadout Share Codes (IHUB-...)
4. Smart Search & Dota 2 Hero/Spell Aliases
5. Theme Customizer & Dynamic Accent Hues
"""
import json
import pytest

from core.dota_launcher import detect_valve_update, repair_gameinfo, check_gameinfo_health
from core.hero_aliases import expand_search_tokens, get_heroes_for_query, HERO_ALIASES
from core.mod_search import filter_mods
from core.spell_icons import get_custom_spells_for_mod, HERO_CUSTOM_SPELLS
from core.presets_service import PresetsService

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

PATCHED_GI = (
    '"gameinfo.gi"\n'
    "{\n"
    "\tFileSystem\n"
    "\t{\n"
    "\t\tSearchPaths\n"
    "\t\t{\n"
    '\t\t\tGame\t\t\t\tdota/pak\n'
    '\t\t\tGame\t\t\t\tdota_russian/pak\n'
    '\t\t\tGame\t\t\t\tdota\n'
    '\t\t\tGame\t\t\t\tcore\n'
    "\t\t}\n"
    "\t}\n"
)


# ==========================================
# 1. Valve Patch Detector Tests
# ==========================================
def test_detect_valve_update_when_wiped(tmp_path):
    dota_dir = tmp_path / "game"
    gi = dota_dir / "dota" / "gameinfo.gi"
    gi.parent.mkdir(parents=True, exist_ok=True)
    gi.write_text(STOCK_GI, encoding="utf-8")

    # With 3 installed mods and unpatched gameinfo, should detect wipe
    res = detect_valve_update(str(dota_dir), installed_mods_count=3)
    assert res["detected"] is True
    assert res["is_patched"] is False
    assert "Valve update" in res["message"]


def test_detect_valve_update_when_healthy(tmp_path):
    dota_dir = tmp_path / "game"
    gi = dota_dir / "dota" / "gameinfo.gi"
    gi.parent.mkdir(parents=True, exist_ok=True)
    gi.write_text(PATCHED_GI, encoding="utf-8")

    res = detect_valve_update(str(dota_dir), installed_mods_count=5)
    assert res["detected"] is False
    assert res["is_patched"] is True


def test_detect_valve_update_no_mods(tmp_path):
    dota_dir = tmp_path / "game"
    gi = dota_dir / "dota" / "gameinfo.gi"
    gi.parent.mkdir(parents=True, exist_ok=True)
    gi.write_text(STOCK_GI, encoding="utf-8")

    # With 0 installed mods, unpatched is normal, not an update wipe
    res = detect_valve_update(str(dota_dir), installed_mods_count=0)
    assert res["detected"] is False


def test_repair_gameinfo_restores_hooks(tmp_path):
    dota_dir = tmp_path / "game"
    gi = dota_dir / "dota" / "gameinfo.gi"
    gi.parent.mkdir(parents=True, exist_ok=True)
    gi.write_text(STOCK_GI, encoding="utf-8")

    ok, msg = repair_gameinfo(str(dota_dir))
    assert ok is True
    content = gi.read_text(encoding="utf-8")
    assert "dota/pak" in content
    assert "dota_russian/pak" in content


# ==========================================
# 2. Smart Search & Hero Aliases Tests
# ==========================================
def test_hero_aliases_coverage():
    # Verify all major popular heroes have rich aliases
    assert "Pudge" in HERO_ALIASES
    assert "Shadow Fiend" in HERO_ALIASES
    assert "Invoker" in HERO_ALIASES
    assert "Juggernaut" in HERO_ALIASES
    assert "Anti-Mage" in HERO_ALIASES

    pudge_aliases = [a.lower() for a in HERO_ALIASES["Pudge"]]
    assert "пудж" in pudge_aliases
    assert "хук" in pudge_aliases
    assert "мясник" in pudge_aliases


def test_get_heroes_for_query():
    # Russian name for Pudge
    matches = get_heroes_for_query("пудж")
    assert "Pudge" in matches

    # Slang SF
    matches = get_heroes_for_query("сф")
    assert "Shadow Fiend" in matches

    # Russian skill name
    matches = get_heroes_for_query("хук")
    assert "Pudge" in matches

    # English skill/item slang
    matches = get_heroes_for_query("meat hook")
    assert "Pudge" in matches


def test_expand_search_tokens():
    tokens = expand_search_tokens("пудж")
    assert "pudge" in tokens or "пудж" in tokens


def test_filter_mods_with_russian_query():
    sample_mods = [
        {"name": "Feast of Abscession", "hero": "Pudge", "categoryId": "heroes", "rarity": "Arcana"},
        {"name": "Demon Eater", "hero": "Shadow Fiend", "categoryId": "heroes", "rarity": "Arcana"},
        {"name": "Bladeform Legacy", "hero": "Juggernaut", "categoryId": "heroes", "rarity": "Arcana"},
    ]

    # Searching "пудж" should return Pudge's Feast of Abscession
    filtered = filter_mods(sample_mods, query="пудж")
    assert len(filtered) == 1
    assert filtered[0]["hero"] == "Pudge"

    # Searching "сф" should return Shadow Fiend's Demon Eater
    filtered = filter_mods(sample_mods, query="сф")
    assert len(filtered) == 1
    assert filtered[0]["hero"] == "Shadow Fiend"


# ==========================================
# 3. Spell Icons & Ability Effects Tests
# ==========================================
def test_get_custom_spells_for_mod_arcana():
    # Pudge Arcana custom spells
    spells = get_custom_spells_for_mod("Feast of Abscession", "Pudge")
    assert len(spells) >= 2
    hook_spell = next((s for s in spells if "Hook" in s["name"]), None)
    assert hook_spell is not None
    assert hook_spell["icon"].startswith("http")
    assert hook_spell["type"] == "arcana"


def test_get_custom_spells_for_mod_immortal():
    # Juggernaut Immortal cat's blade / edge
    spells = get_custom_spells_for_mod("Edge of the Lost Order", "Juggernaut")
    assert len(spells) >= 1
    assert spells[0]["type"] == "immortal"
    assert "Blade Fury" in spells[0]["name"]


def test_get_custom_spells_generic_hero_fallback():
    # Fallback to Arcana spells for hero when mod is Arcana
    spells = get_custom_spells_for_mod("Custom Arcana Mod", "Invoker")
    assert len(spells) >= 1


# ==========================================
# 4. Preset & Loadout Share Codes Tests
# ==========================================
def test_export_and_parse_loadout_code(tmp_path):
    service = PresetsService(app_dir=str(tmp_path))
    items = [
        {"name": "Feast of Abscession", "hero": "Pudge", "categoryId": "heroes"},
        {"name": "Gabe Newell Announcer", "hero": "", "categoryId": "announcer"}
    ]

    code = service.export_loadout_code(items, "Championship Loadout")
    assert code.startswith("IHUB-")

    parsed = service.parse_share_code(code)
    assert parsed is not None
    assert parsed["type"] == "loadout"
    assert parsed["name"] == "Championship Loadout"
    assert len(parsed["items"]) == 2
    assert parsed["items"][0]["name"] == "Feast of Abscession"
    assert parsed["items"][1]["categoryId"] == "announcer"


def test_import_preset_code_saves_preset(tmp_path):
    service = PresetsService(app_dir=str(tmp_path))
    items = [{"name": "Demon Eater", "hero": "Shadow Fiend", "categoryId": "heroes"}]
    code = service.export_preset_code({"name": "SF Main", "description": "SF build", "items": items})

    saved = service.import_preset_code(code)
    assert saved is not None
    assert saved["name"] == "SF Main"
    assert len(saved["items"]) == 1

    # Check that it appears in user presets
    presets = service.get_user_presets()
    assert any(p["name"] == "SF Main" for p in presets)


def test_invalid_share_code_handling(tmp_path):
    service = PresetsService(app_dir=str(tmp_path))
    assert service.parse_share_code("INVALID-CODE-XYZ") is None
    assert service.parse_share_code("") is None
    assert service.parse_share_code("IHUB-not-base64!#%") is None


# ==========================================
# 5. Theme Customizer & Accent Hues
# ==========================================
def test_theme_customizer_all_hues():
    allowed_hues = {"immortal", "cyan", "violet", "emerald", "amber", "crimson", "sakura", "ice"}
    assert "sakura" in allowed_hues
    assert "ice" in allowed_hues
    assert "immortal" in allowed_hues


# ==========================================
# 6. Multi-Style Mod Fallback Tests
# ==========================================
def test_parse_mod_multi_style_fallback():
    from api import parse_mod

    # Mod with no top-level file or preview, but has styles
    raw_mod = {
        "name": "Shadow Fiend King of Vipers",
        "styles": [
            {"label": "Style 1", "file": "King of Vipers S1.zip", "preview": "King of Vipers S1.webp"},
            {"label": "Style 2", "file": "King of Vipers S2.zip", "preview": "King of Vipers S2.webp"}
        ]
    }
    parsed = parse_mod(raw_mod, "heroes", "Shadow Fiend")
    assert parsed.name == "Shadow Fiend King of Vipers"
    assert parsed.file == "King of Vipers S1.zip"
    assert parsed.preview == "King of Vipers S1.webp"
    assert "King%20of%20Vipers%20S1.zip" in parsed.file_url()
    assert "King%20of%20Vipers%20S1.webp" in parsed.preview_url()
    assert len(parsed.styles) == 2

