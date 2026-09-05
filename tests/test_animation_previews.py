"""Tests for animation previews and video demonstration system."""
import pytest
from core.animation_previews import get_animation_preview_url, HERO_ANIMATION_SHOWCASES
from api import ModItem, parse_mod


def test_hero_animation_resolver():
    # SF requiem
    url = get_animation_preview_url(mod_name="Demon Eater", hero_name="Shadow Fiend", category_id="arcana")
    assert "nevermore_requiem.mp4" in url

    # PA coup de grace
    pa_url = get_animation_preview_url(mod_name="Manifold Paradox", hero_name="Phantom Assassin", category_id="arcana")
    assert "coup_de_grace.mp4" in pa_url

    # Void chrono
    void_url = get_animation_preview_url(mod_name="Claszian Apostasy", hero_name="Faceless Void", category_id="arcana")
    assert "chronosphere.mp4" in void_url

    # Juggernaut omnislash
    jugg_url = get_animation_preview_url(mod_name="Bladeform Legacy", hero_name="Juggernaut", category_id="arcana")
    assert "omni_slash.mp4" in jugg_url


def test_mod_item_video_url_explicit():
    item = ModItem(
        name="Demon Eater",
        hero="Shadow Fiend",
        category_id="arcana",
        preview="https://img.example/preview.png",
        file="sf_arcana.vpk",
        video_preview="https://cdn.cloudflare.steamstatic.com/apps/dota2/videos/dota_react/abilities/nevermore/nevermore_requiem.mp4",
    )
    assert "nevermore_requiem.mp4" in item.video_url()


def test_mod_item_video_url_fallback():
    # Even without explicit video_preview, video_url() dynamically resolves the hero animation showcase
    item = ModItem(
        name="Demon Eater",
        hero="Shadow Fiend",
        category_id="arcana",
        preview="https://img.example/preview.png",
        file="sf_arcana.vpk",
    )
    assert "nevermore_requiem.mp4" in item.video_url()


def test_parse_mod_attaches_video_link():
    raw_dict = {
        "name": "Custom SF",
        "hero": "Shadow Fiend",
        "category_id": "arcana",
        "preview": "https://img.example/preview.png",
        "file": "sf.vpk",
        "links": [
            {"name": "Animation Preview", "type": "video", "url": "https://example.com/showcase.mp4"}
        ]
    }
    mod = parse_mod(raw_dict, category_id="arcana", hero_name="Shadow Fiend")
    assert mod.video_preview == "https://example.com/showcase.mp4"
    assert mod.video_url() == "https://example.com/showcase.mp4"
