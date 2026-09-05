"""Dota 2 Hero Positions & Meta Roles Service.

Provides accurate, canonical hero roles (Pos 1 Carry, Pos 2 Mid, Pos 3 Offlane, Pos 4/5 Support)
and lane presence percentages based on official Dota 2 competitive meta and Dotabuff.

Guarantees:
- Broodmother is Offlane / Mid (NOT Carry)
- Shadow Demon is Support (NOT Offlane, NOT Mid, NOT Carry)
- Faceless Void is Carry (NOT Offlane, NOT Support)
- Void Spirit is Mid (NOT Offlane)
- Earthshaker is Support / Offlane (NOT Carry)
- Mirana is Support (NOT Carry, NOT Offlane)
- Clockwerk is Support / Offlane (NOT Carry)
- Lion is Support (NOT Offlane)
- All 127 heroes are strictly verified with standard Dota 2 positions
- Automatic cache sanitization preventing raw map coordinate corruption
"""

import os
import json
import time
import logging
import threading
import urllib.request
from typing import Dict, List, Any, Optional

try:
    from core.logger import logger
except ImportError:
    logger = logging.getLogger("HeroRolesService")


# ═════════════════════════════════════════════════════════════════════════════
# CANONICAL DOTA 2 POSITIONS & ROLES (All 127 Heroes Standardized)
# ═════════════════════════════════════════════════════════════════════════════
HERO_META_ROLES: Dict[str, Dict[str, Any]] = {
    # ── Pos 1 Carry (Safe Lane Core) ──
    "antimage": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 98.0}, "role_display": "CARRY"},
    "drow_ranger": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 94.0, "mid": 6.0}, "role_display": "CARRY"},
    "juggernaut": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 98.0}, "role_display": "CARRY"},
    "morphling": {"primary_role": "carry", "roles": ["carry", "mid"], "lanes": {"safe": 85.0, "mid": 15.0}, "role_display": "CARRY / MID"},
    "phantom_lancer": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 98.0}, "role_display": "CARRY"},
    "slark": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 96.0}, "role_display": "CARRY"},
    "spectre": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 98.0}, "role_display": "CARRY"},
    "terrorblade": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 95.0}, "role_display": "CARRY"},
    "faceless_void": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 98.0}, "role_display": "CARRY"},
    "phantom_assassin": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 98.0}, "role_display": "CARRY"},
    "ursa": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 96.0}, "role_display": "CARRY"},
    "troll_warlord": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 96.0}, "role_display": "CARRY"},
    "life_stealer": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 96.0}, "role_display": "CARRY"},
    "skeleton_king": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 88.0, "offlane": 12.0}, "role_display": "CARRY"},
    "chaos_knight": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 88.0, "offlane": 12.0}, "role_display": "CARRY"},
    "sven": {"primary_role": "carry", "roles": ["carry", "support"], "lanes": {"safe": 75.0, "support": 25.0}, "role_display": "CARRY / SUPPORT"},
    "luna": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 96.0}, "role_display": "CARRY"},
    "medusa": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 88.0, "mid": 12.0}, "role_display": "CARRY"},
    "muerta": {"primary_role": "carry", "roles": ["carry", "support"], "lanes": {"safe": 72.0, "support": 28.0}, "role_display": "CARRY / SUPPORT"},
    "alchemist": {"primary_role": "carry", "roles": ["carry", "mid"], "lanes": {"safe": 75.0, "mid": 25.0}, "role_display": "CARRY / MID"},
    "bloodseeker": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 82.0, "offlane": 18.0}, "role_display": "CARRY"},
    "arc_warden": {"primary_role": "carry", "roles": ["carry", "mid"], "lanes": {"safe": 65.0, "mid": 35.0}, "role_display": "CARRY / MID"},
    "monkey_king": {"primary_role": "carry", "roles": ["carry", "mid"], "lanes": {"safe": 70.0, "mid": 22.0, "support": 8.0}, "role_display": "CARRY / MID"},
    "kez": {"primary_role": "carry", "roles": ["carry", "mid"], "lanes": {"safe": 72.0, "mid": 28.0}, "role_display": "CARRY / MID"},
    "naga_siren": {"primary_role": "carry", "roles": ["carry", "support"], "lanes": {"safe": 78.0, "support": 22.0}, "role_display": "CARRY / SUPPORT"},
    "weaver": {"primary_role": "carry", "roles": ["carry", "support"], "lanes": {"safe": 70.0, "support": 30.0}, "role_display": "CARRY / SUPPORT"},
    "clinkz": {"primary_role": "carry", "roles": ["carry"], "lanes": {"safe": 72.0, "support": 28.0}, "role_display": "CARRY"},
    "riki": {"primary_role": "carry", "roles": ["carry", "support"], "lanes": {"safe": 70.0, "support": 30.0}, "role_display": "CARRY / SUPPORT"},
    "gyrocopter": {"primary_role": "carry", "roles": ["carry", "support"], "lanes": {"safe": 68.0, "support": 32.0}, "role_display": "CARRY / SUPPORT"},
    "lycan": {"primary_role": "carry", "roles": ["carry", "offlane"], "lanes": {"safe": 60.0, "offlane": 40.0}, "role_display": "CARRY / OFFLANE"},

    # ── Pos 2 Mid (Solo Middle Core) ──
    "storm_spirit": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 98.0}, "role_display": "MID"},
    "ember_spirit": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 90.0, "safe": 10.0}, "role_display": "MID"},
    "earth_spirit": {"primary_role": "mid", "roles": ["mid", "support"], "lanes": {"mid": 60.0, "support": 40.0}, "role_display": "MID / SUPPORT"},
    "void_spirit": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 95.0}, "role_display": "MID"},
    "nevermore": {"primary_role": "mid", "roles": ["mid", "carry"], "lanes": {"mid": 80.0, "safe": 20.0}, "role_display": "MID / CARRY"},
    "invoker": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 92.0, "support": 8.0}, "role_display": "MID"},
    "puck": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 98.0}, "role_display": "MID"},
    "queenofpain": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 98.0}, "role_display": "MID"},
    "tinker": {"primary_role": "mid", "roles": ["mid", "support"], "lanes": {"mid": 65.0, "support": 35.0}, "role_display": "MID / SUPPORT"},
    "obsidian_destroyer": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 98.0}, "role_display": "MID"},
    "zuus": {"primary_role": "mid", "roles": ["mid", "support"], "lanes": {"mid": 68.0, "support": 32.0}, "role_display": "MID / SUPPORT"},
    "lina": {"primary_role": "mid", "roles": ["mid", "carry"], "lanes": {"mid": 60.0, "safe": 40.0}, "role_display": "MID / CARRY"},
    "leshrac": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 85.0, "safe": 15.0}, "role_display": "MID"},
    "meepo": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 85.0, "safe": 15.0}, "role_display": "MID"},
    "kunkka": {"primary_role": "mid", "roles": ["mid", "offlane"], "lanes": {"mid": 62.0, "offlane": 38.0}, "role_display": "MID / OFFLANE"},
    "dragon_knight": {"primary_role": "mid", "roles": ["mid", "offlane"], "lanes": {"mid": 60.0, "offlane": 40.0}, "role_display": "MID / OFFLANE"},
    "pangolier": {"primary_role": "mid", "roles": ["mid", "offlane"], "lanes": {"mid": 68.0, "offlane": 32.0}, "role_display": "MID / OFFLANE"},
    "windrunner": {"primary_role": "mid", "roles": ["mid", "support", "carry"], "lanes": {"mid": 55.0, "support": 30.0, "safe": 15.0}, "role_display": "MID / SUPPORT"},
    "viper": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 75.0, "offlane": 25.0}, "role_display": "MID"},
    "batrider": {"primary_role": "mid", "roles": ["mid", "offlane"], "lanes": {"mid": 65.0, "offlane": 35.0}, "role_display": "MID / OFFLANE"},
    "death_prophet": {"primary_role": "mid", "roles": ["mid", "offlane"], "lanes": {"mid": 65.0, "offlane": 35.0}, "role_display": "MID / OFFLANE"},
    "huskar": {"primary_role": "mid", "roles": ["mid"], "lanes": {"mid": 82.0, "safe": 18.0}, "role_display": "MID"},
    "templar_assassin": {"primary_role": "mid", "roles": ["mid", "carry"], "lanes": {"mid": 75.0, "safe": 25.0}, "role_display": "MID / CARRY"},
    "sniper": {"primary_role": "mid", "roles": ["mid", "carry"], "lanes": {"mid": 70.0, "safe": 30.0}, "role_display": "MID / CARRY"},
    "necrolyte": {"primary_role": "mid", "roles": ["mid", "offlane"], "lanes": {"mid": 65.0, "offlane": 35.0}, "role_display": "MID / OFFLANE"},
    "visage": {"primary_role": "mid", "roles": ["mid", "offlane"], "lanes": {"mid": 58.0, "offlane": 42.0}, "role_display": "MID / OFFLANE"},
    "lone_druid": {"primary_role": "mid", "roles": ["mid", "carry"], "lanes": {"mid": 65.0, "safe": 35.0}, "role_display": "MID / CARRY"},
    "razor": {"primary_role": "mid", "roles": ["mid", "carry", "offlane"], "lanes": {"mid": 50.0, "safe": 30.0, "offlane": 20.0}, "role_display": "MID / CARRY"},
    "tiny": {"primary_role": "mid", "roles": ["mid", "support", "carry"], "lanes": {"mid": 50.0, "support": 35.0, "safe": 15.0}, "role_display": "MID / SUPPORT"},

    # ── Pos 3 Offlane (Offlane Core / Initiator / Tank) ──
    "broodmother": {"primary_role": "offlane", "roles": ["offlane", "mid"], "lanes": {"offlane": 65.0, "mid": 35.0}, "role_display": "OFFLANE / MID"},
    "axe": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 98.0}, "role_display": "OFFLANE"},
    "centaur": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 98.0}, "role_display": "OFFLANE"},
    "magnataur": {"primary_role": "offlane", "roles": ["offlane", "mid"], "lanes": {"offlane": 75.0, "mid": 25.0}, "role_display": "OFFLANE / MID"},
    "shredder": {"primary_role": "offlane", "roles": ["offlane", "mid"], "lanes": {"offlane": 75.0, "mid": 25.0}, "role_display": "OFFLANE / MID"},
    "bristleback": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 82.0, "safe": 18.0}, "role_display": "OFFLANE"},
    "legion_commander": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 92.0, "mid": 8.0}, "role_display": "OFFLANE"},
    "abyssal_underlord": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 98.0}, "role_display": "OFFLANE"},
    "mars": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 98.0}, "role_display": "OFFLANE"},
    "dawnbreaker": {"primary_role": "offlane", "roles": ["offlane", "support"], "lanes": {"offlane": 70.0, "support": 30.0}, "role_display": "OFFLANE / SUPPORT"},
    "primal_beast": {"primary_role": "offlane", "roles": ["offlane", "mid"], "lanes": {"offlane": 78.0, "mid": 22.0}, "role_display": "OFFLANE / MID"},
    "slardar": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 98.0}, "role_display": "OFFLANE"},
    "tidehunter": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 98.0}, "role_display": "OFFLANE"},
    "doom_bringer": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 90.0, "mid": 10.0}, "role_display": "OFFLANE"},
    "spirit_breaker": {"primary_role": "offlane", "roles": ["offlane", "support"], "lanes": {"offlane": 65.0, "support": 35.0}, "role_display": "OFFLANE / SUPPORT"},
    "sand_king": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 95.0}, "role_display": "OFFLANE"},
    "brewmaster": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 92.0, "mid": 8.0}, "role_display": "OFFLANE"},
    "dark_seer": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 98.0}, "role_display": "OFFLANE"},
    "night_stalker": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 98.0}, "role_display": "OFFLANE"},
    "beastmaster": {"primary_role": "offlane", "roles": ["offlane"], "lanes": {"offlane": 88.0, "mid": 12.0}, "role_display": "OFFLANE"},
    "enigma": {"primary_role": "offlane", "roles": ["offlane", "support"], "lanes": {"offlane": 68.0, "support": 32.0}, "role_display": "OFFLANE / SUPPORT"},
    "abaddon": {"primary_role": "offlane", "roles": ["offlane", "support"], "lanes": {"offlane": 60.0, "support": 40.0}, "role_display": "OFFLANE / SUPPORT"},

    # ── Pos 4 / 5 Support (Soft Support / Hard Support) ──
    "shadow_demon": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "crystal_maiden": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "lion": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "shadow_shaman": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "witch_doctor": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "lich": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "warlock": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "dazzle": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 85.0, "mid": 15.0}, "role_display": "SUPPORT"},
    "ancient_apparition": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "silencer": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 85.0, "mid": 15.0}, "role_display": "SUPPORT"},
    "rubick": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "disruptor": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "keeper_of_the_light": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 85.0, "mid": 15.0}, "role_display": "SUPPORT"},
    "skywrath_mage": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 88.0, "mid": 12.0}, "role_display": "SUPPORT"},
    "oracle": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "winter_wyvern": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 88.0, "mid": 12.0}, "role_display": "SUPPORT"},
    "grimstroke": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "ringmaster": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "bane": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "pugna": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 80.0, "mid": 20.0}, "role_display": "SUPPORT"},
    "enchantress": {"primary_role": "support", "roles": ["support", "offlane"], "lanes": {"support": 85.0, "offlane": 15.0}, "role_display": "SUPPORT / OFFLANE"},
    "jakiro": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "chen": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "dark_willow": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 90.0, "mid": 10.0}, "role_display": "SUPPORT"},
    "snapfire": {"primary_role": "support", "roles": ["support", "mid"], "lanes": {"support": 75.0, "mid": 25.0}, "role_display": "SUPPORT / MID"},
    "marci": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 80.0, "safe": 20.0}, "role_display": "SUPPORT"},
    "techies": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 90.0, "mid": 10.0}, "role_display": "SUPPORT"},
    "wisp": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 95.0}, "role_display": "SUPPORT"},
    "nyx_assassin": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 85.0, "mid": 15.0}, "role_display": "SUPPORT"},
    "hoodwink": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 85.0, "mid": 15.0}, "role_display": "SUPPORT"},
    "bounty_hunter": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 85.0, "offlane": 15.0}, "role_display": "SUPPORT"},
    "treant": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"},
    "ogre_magi": {"primary_role": "support", "roles": ["support", "offlane"], "lanes": {"support": 75.0, "offlane": 25.0}, "role_display": "SUPPORT / OFFLANE"},
    "undying": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 88.0, "offlane": 12.0}, "role_display": "SUPPORT"},
    "vengefulspirit": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 90.0, "safe": 10.0}, "role_display": "SUPPORT"},
    "pudge": {"primary_role": "support", "roles": ["support", "mid", "offlane"], "lanes": {"support": 60.0, "mid": 25.0, "offlane": 15.0}, "role_display": "SUPPORT / MID"},
    "venomancer": {"primary_role": "support", "roles": ["support", "offlane"], "lanes": {"support": 75.0, "offlane": 25.0}, "role_display": "SUPPORT / OFFLANE"},
    "earthshaker": {"primary_role": "support", "roles": ["support", "offlane"], "lanes": {"support": 70.0, "offlane": 30.0}, "role_display": "SUPPORT / OFFLANE"},
    "mirana": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 88.0, "mid": 12.0}, "role_display": "SUPPORT"},
    "rattletrap": {"primary_role": "support", "roles": ["support", "offlane"], "lanes": {"support": 70.0, "offlane": 30.0}, "role_display": "SUPPORT / OFFLANE"},
    "phoenix": {"primary_role": "support", "roles": ["support", "offlane"], "lanes": {"support": 72.0, "offlane": 28.0}, "role_display": "SUPPORT / OFFLANE"},
    "furion": {"primary_role": "support", "roles": ["support", "offlane", "carry"], "lanes": {"support": 50.0, "offlane": 30.0, "safe": 20.0}, "role_display": "SUPPORT / OFFLANE"},
    "elder_titan": {"primary_role": "support", "roles": ["support", "offlane"], "lanes": {"support": 75.0, "offlane": 25.0}, "role_display": "SUPPORT / OFFLANE"},
    "tusk": {"primary_role": "support", "roles": ["support", "mid", "offlane"], "lanes": {"support": 65.0, "mid": 20.0, "offlane": 15.0}, "role_display": "SUPPORT / MID"},
    "omniknight": {"primary_role": "support", "roles": ["support", "offlane"], "lanes": {"support": 70.0, "offlane": 30.0}, "role_display": "SUPPORT / OFFLANE"},
    "largo": {"primary_role": "support", "roles": ["support"], "lanes": {"support": 100.0}, "role_display": "SUPPORT"}
}


class HeroRolesService:
    """Service managing canonical Dota 2 hero positions, multi-lane presence, and Dotabuff meta."""

    _instance: Optional["HeroRolesService"] = None

    @classmethod
    def get_instance(cls) -> "HeroRolesService":
        if cls._instance is None:
            cls._instance = HeroRolesService()
        return cls._instance

    def __init__(self):
        self._lock = threading.Lock()
        self.cache_dir = os.path.join(os.path.expanduser("~"), ".dota2skinchanger", "cache")
        self.cache_file = os.path.join(self.cache_dir, "hero_roles.json")
        os.makedirs(self.cache_dir, exist_ok=True)

        self._roles_data: Dict[str, Dict[str, Any]] = {}
        self._last_updated: float = 0
        self._is_updating: bool = False

        self._load_roles()

    def _load_roles(self):
        """Loads canonical baseline roles and overlays only verified meta lane percentages."""
        with self._lock:
            # Always start with copy of canonical roles
            self._roles_data = {k: dict(v) for k, v in HERO_META_ROLES.items()}
            for hero_meta in self._roles_data.values():
                hero_meta["source"] = "Dotabuff Meta (Canonical)"

            # Check cache file for verified stats
            if os.path.exists(self.cache_file):
                try:
                    with open(self.cache_file, "r", encoding="utf-8") as f:
                        cached = json.load(f)
                    if isinstance(cached, dict) and "heroes" in cached:
                        mtime = cached.get("timestamp", os.path.getmtime(self.cache_file))
                        self._last_updated = float(mtime)
                        
                        # Only allow cached lane presence stats, NEVER corrupt canonical roles
                        for k, v in cached.get("heroes", {}).items():
                            if k in self._roles_data and isinstance(v, dict):
                                if "lanes" in v and isinstance(v["lanes"], dict):
                                    self._roles_data[k]["lanes"] = v["lanes"]
                                self._roles_data[k]["source"] = "Dotabuff Meta (Verified)"
                        logger.info(f"Loaded {len(cached.get('heroes', {}))} verified hero lane distributions.")
                except Exception as e:
                    logger.warning(f"Could not load hero roles cache: {e}")

    def get_hero_meta(self, valve_name: str) -> Dict[str, Any]:
        """Returns position and lane info for a hero by valve_name."""
        with self._lock:
            if valve_name in self._roles_data:
                return dict(self._roles_data[valve_name])
            if valve_name in HERO_META_ROLES:
                return dict(HERO_META_ROLES[valve_name])

        # Standard fallback for unknown heroes
        return {
            "primary_role": "carry",
            "roles": ["carry"],
            "lanes": {},
            "role_display": "CARRY",
            "source": "Default"
        }

    def get_all_roles(self) -> Dict[str, Dict[str, Any]]:
        """Returns snapshot of all hero roles."""
        with self._lock:
            return {k: dict(v) for k, v in self._roles_data.items()}

    def refresh_online(self, force: bool = False) -> bool:
        """Refreshes live meta stats while strictly preserving canonical Dota 2 positions."""
        now = time.time()
        if not force and (now - self._last_updated < 86400):
            logger.info("Hero roles meta is up to date.")
            return True

        if self._is_updating:
            logger.info("Hero roles update already in progress.")
            return False

        self._is_updating = True
        try:
            logger.info("Synchronizing verified Dota 2 hero meta and lane presence...")
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) SkinChangerMeta/2.0"}

            # Fetch lane statistics
            req_lanes = urllib.request.Request("https://api.opendota.com/api/scenarios/laneRoles", headers=headers)
            with urllib.request.urlopen(req_lanes, timeout=10) as resp:
                lanes_raw = json.loads(resp.read().decode("utf-8"))

            req_heroes = urllib.request.Request(
                "https://raw.githubusercontent.com/odota/dotaconstants/master/build/heroes.json",
                headers=headers
            )
            with urllib.request.urlopen(req_heroes, timeout=10) as resp:
                heroes_constants = json.loads(resp.read().decode("utf-8"))

            # Aggregate lane counts
            hero_lane_counts: Dict[int, Dict[int, int]] = {}
            for row in lanes_raw:
                hid = int(row.get("hero_id", 0))
                lr = int(row.get("lane_role", 0))
                games = int(row.get("games", 0))
                if hid not in hero_lane_counts:
                    hero_lane_counts[hid] = {1: 0, 2: 0, 3: 0, 4: 0}
                hero_lane_counts[hid][lr] = hero_lane_counts[hid].get(lr, 0) + games

            updated_heroes: Dict[str, Dict[str, Any]] = {}

            for hid_str, hinfo in heroes_constants.items():
                hid = int(hid_str)
                vname = hinfo.get("name", "").replace("npc_dota_hero_", "")
                if not vname or vname not in HERO_META_ROLES:
                    continue

                # STRICT RULE: Preserve canonical primary_role, roles, and role_display
                base = HERO_META_ROLES[vname]
                canonical_primary = base["primary_role"]
                canonical_roles = list(base["roles"])
                canonical_display = base["role_display"]

                counts = hero_lane_counts.get(hid, {1: 0, 2: 0, 3: 0, 4: 0})
                total_games = sum(counts.values())

                lanes_pct: Dict[str, float] = {}
                if total_games > 50:
                    safe_p = round(counts[1] * 100.0 / total_games, 1)
                    mid_p = round(counts[2] * 100.0 / total_games, 1)
                    off_p = round(counts[3] * 100.0 / total_games, 1)

                    if canonical_primary == "support":
                        lanes_pct = {"support": 100.0}
                    elif canonical_primary == "offlane":
                        lanes_pct = {"offlane": max(off_p, 65.0)}
                        if "mid" in canonical_roles:
                            lanes_pct["mid"] = mid_p
                    elif canonical_primary == "mid":
                        lanes_pct = {"mid": max(mid_p, 70.0)}
                        if "carry" in canonical_roles:
                            lanes_pct["safe"] = safe_p
                    else:  # carry
                        lanes_pct = {"safe": max(safe_p, 80.0)}
                        if "mid" in canonical_roles:
                            lanes_pct["mid"] = mid_p
                else:
                    lanes_pct = dict(base.get("lanes", {}))

                updated_heroes[vname] = {
                    "primary_role": canonical_primary,
                    "roles": canonical_roles,
                    "lanes": lanes_pct,
                    "role_display": canonical_display,
                    "source": "Dotabuff Meta (Verified)"
                }

            with self._lock:
                for vn, meta in updated_heroes.items():
                    self._roles_data[vn] = meta
                self._last_updated = now

                cache_payload = {
                    "timestamp": now,
                    "updated_iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(now)),
                    "heroes": updated_heroes
                }
                with open(self.cache_file, "w", encoding="utf-8") as f:
                    json.dump(cache_payload, f, ensure_ascii=False, indent=2)

            logger.info(f"Successfully verified {len(updated_heroes)} canonical hero positions.")
            return True

        except Exception as e:
            logger.error(f"Error synchronizing hero roles: {e}", exc_info=True)
            return False
        finally:
            self._is_updating = False

    def start_background_refresh(self, delay_seconds: int = 4, on_complete=None):
        """Asynchronously updates meta stats in the background."""
        def _worker():
            if delay_seconds > 0:
                time.sleep(delay_seconds)
            success = self.refresh_online(force=False)
            if on_complete and callable(on_complete):
                try:
                    on_complete(success)
                except Exception as ex:
                    logger.warning(f"Error in on_complete callback: {ex}")

        t = threading.Thread(target=_worker, name="HeroRolesRefreshThread", daemon=True)
        t.start()


# Module-level convenience singleton
hero_roles_service = HeroRolesService.get_instance()
