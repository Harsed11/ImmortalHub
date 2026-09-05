"""
Unit tests for Dota 2 Hero Positions & Dotabuff Meta Roles Service.
Tests:
1. Hero role coverage (all 127 heroes properly classified)
2. Specific hero classifications (Broodmother is Offlane/Mid, NOT Carry;
   Earthshaker is Support/Offlane/Mid, NOT Carry; Mirana is Support/Mid, NOT Carry;
   Clockwerk is Support/Offlane, NOT Carry)
3. HeroRolesService local caching and metadata lookup
4. Multi-role filtering simulation matching HeroesView.qml
5. Integration with SkinChangerApp.getHeroCards()
"""

import json
import pytest
from core.hero_roles import HeroRolesService, HERO_META_ROLES, hero_roles_service
from core.app import SkinChangerApp


def test_hero_meta_roles_baseline_coverage():
    """Verify all 127 heroes have valid primary_role and non-empty roles list."""
    assert len(HERO_META_ROLES) >= 120
    valid_roles = {"carry", "mid", "offlane", "support"}

    for vname, data in HERO_META_ROLES.items():
        assert "primary_role" in data, f"Hero {vname} missing primary_role"
        assert data["primary_role"] in valid_roles, f"Hero {vname} invalid primary_role {data['primary_role']}"
        assert "roles" in data, f"Hero {vname} missing roles list"
        assert len(data["roles"]) > 0, f"Hero {vname} empty roles list"
        for r in data["roles"]:
            assert r in valid_roles, f"Hero {vname} contains invalid role {r}"


def test_broodmother_is_not_carry():
    """Broodmother must be classified as Offlane/Mid and NOT Carry."""
    meta = hero_roles_service.get_hero_meta("broodmother")
    assert meta["primary_role"] == "offlane"
    assert "carry" not in meta["roles"]
    assert "offlane" in meta["roles"]
    assert "mid" in meta["roles"]


def test_shadow_demon_is_strictly_support():
    """Shadow Demon must be Support and NEVER Offlane or Carry."""
    meta = hero_roles_service.get_hero_meta("shadow_demon")
    assert meta["primary_role"] == "support"
    assert meta["roles"] == ["support"]
    assert "offlane" not in meta["roles"]
    assert "carry" not in meta["roles"]


def test_faceless_void_is_strictly_carry():
    """Faceless Void must be Carry and NEVER Offlane."""
    meta = hero_roles_service.get_hero_meta("faceless_void")
    assert meta["primary_role"] == "carry"
    assert meta["roles"] == ["carry"]
    assert "offlane" not in meta["roles"]


def test_void_spirit_is_strictly_mid():
    """Void Spirit must be Mid and NEVER Offlane."""
    meta = hero_roles_service.get_hero_meta("void_spirit")
    assert meta["primary_role"] == "mid"
    assert meta["roles"] == ["mid"]
    assert "offlane" not in meta["roles"]


def test_earthshaker_is_not_carry():
    """Earthshaker must be Support/Offlane/Mid and NOT Carry."""
    meta = hero_roles_service.get_hero_meta("earthshaker")
    assert meta["primary_role"] == "support"
    assert "carry" not in meta["roles"]
    assert "support" in meta["roles"]
    assert "offlane" in meta["roles"] or "mid" in meta["roles"]


def test_mirana_is_not_carry():
    """Mirana must be Support/Mid and NOT Carry."""
    meta = hero_roles_service.get_hero_meta("mirana")
    assert meta["primary_role"] == "support"
    assert "carry" not in meta["roles"]
    assert "support" in meta["roles"]


def test_clockwerk_is_not_carry():
    """Clockwerk (rattletrap) must be Support/Offlane and NOT Carry."""
    meta = hero_roles_service.get_hero_meta("rattletrap")
    assert meta["primary_role"] == "support"
    assert "carry" not in meta["roles"]
    assert "support" in meta["roles"]
    assert "offlane" in meta["roles"]


def test_multi_role_filtering_simulation():
    """Simulate QML multi-role filtering logic from HeroesView.qml."""
    cards = [
        {"name": "Broodmother", "role": "offlane", "roles": ["offlane", "mid"]},
        {"name": "Earthshaker", "role": "support", "roles": ["support", "mid", "offlane"]},
        {"name": "Anti-Mage", "role": "carry", "roles": ["carry"]},
        {"name": "Storm Spirit", "role": "mid", "roles": ["mid"]},
    ]

    def filter_by_role(role_filter):
        if role_filter == "all":
            return cards
        return [
            c for c in cards
            if c.get("role") == role_filter
            or (c.get("roles") and role_filter in c.get("roles"))
        ]

    # Filter Carry: Anti-Mage only; Broodmother, Earthshaker must NOT be included
    carry_heroes = [c["name"] for c in filter_by_role("carry")]
    assert "Anti-Mage" in carry_heroes
    assert "Broodmother" not in carry_heroes
    assert "Earthshaker" not in carry_heroes

    # Filter Offlane: Broodmother and Earthshaker must be included
    offlane_heroes = [c["name"] for c in filter_by_role("offlane")]
    assert "Broodmother" in offlane_heroes
    assert "Earthshaker" in offlane_heroes
    assert "Anti-Mage" not in offlane_heroes

    # Filter Mid: Broodmother, Earthshaker, Storm Spirit must be included
    mid_heroes = [c["name"] for c in filter_by_role("mid")]
    assert "Broodmother" in mid_heroes
    assert "Earthshaker" in mid_heroes
    assert "Storm Spirit" in mid_heroes
    assert "Anti-Mage" not in mid_heroes

    # Filter Support: Earthshaker must be included; Broodmother must NOT
    support_heroes = [c["name"] for c in filter_by_role("support")]
    assert "Earthshaker" in support_heroes
    assert "Broodmother" not in support_heroes
    assert "Anti-Mage" not in support_heroes


def test_app_get_hero_cards_integration():
    """Verify app.getHeroCards() returns cards with role, roles, roleDisplay, and laneStats."""
    app = SkinChangerApp()
    cards_json = app.getHeroCards()
    cards = json.loads(cards_json)

    assert len(cards) == 127

    cards_map = {c["name"]: c for c in cards}

    # Verify Broodmother
    bm = cards_map.get("Broodmother")
    assert bm is not None
    assert bm["role"] == "offlane"
    assert "carry" not in bm["roles"]
    assert "offlane" in bm["roles"]
    assert "roles" in bm and isinstance(bm["roles"], list)
    assert "roleDisplay" in bm
    assert "laneStats" in bm

    # Verify Earthshaker
    es = cards_map.get("Earthshaker")
    assert es is not None
    assert es["role"] == "support"
    assert "carry" not in es["roles"]
    assert "support" in es["roles"]

    # Verify Mirana
    mirana = cards_map.get("Mirana")
    assert mirana is not None
    assert mirana["role"] == "support"
    assert "carry" not in mirana["roles"]
    assert "support" in mirana["roles"]
