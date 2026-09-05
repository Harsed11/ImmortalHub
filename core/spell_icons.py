"""Dota 2 Custom Spell Icons and Video Preview Registry.

Maps Arcanas, Personas, and high-tier Immortals to their custom ability icons,
sound cues, and official Valve effect showcase clips.
"""

from typing import Dict, List, Any

VALVE_CDN_ABILITY_IMG = "https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/abilities"
VALVE_CDN_ABILITY_VID = "https://cdn.cloudflare.steamstatic.com/apps/dota2/videos/dota_react/abilities"

# Hero -> Item Keywords -> Custom Spells
HERO_CUSTOM_SPELLS: Dict[str, Dict[str, Any]] = {
    "Pudge": {
        "arcana": [
            {
                "id": "pudge_meat_hook",
                "name": "Meat Hook (Arcana Hook)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/pudge_meat_hook.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/pudge/pudge_meat_hook.mp4",
                "description": "Custom fiery chain animations, bloody hook trajectory, and flesh rip effects."
            },
            {
                "id": "pudge_rot",
                "name": "Rot (Toxic Miasma)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/pudge_rot.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/pudge/pudge_rot.mp4",
                "description": "Custom toxic green smoke ring, necrotic flies, and flesh bubbling effects."
            },
            {
                "id": "pudge_dismember",
                "name": "Dismember (Ghoulish Feast)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/pudge_dismember.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/pudge/pudge_dismember.mp4",
                "description": "Custom dismembering animations with ripping meat, flying ribs, and unique voice lines."
            }
        ]
    },
    "Shadow Fiend": {
        "arcana": [
            {
                "id": "nevermore_shadowraze1",
                "name": "Shadowraze (Demon Flame)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/nevermore_shadowraze1.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/nevermore/nevermore_shadowraze1.mp4",
                "description": "Custom erupting hellfire column with screaming souls and demonic scorched earth."
            },
            {
                "id": "nevermore_requiem",
                "name": "Requiem of Souls (Soul Explosion)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/nevermore_requiem.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/nevermore/nevermore_requiem.mp4",
                "description": "Fiery shockwave releasing dozens of wailing demon spirits with explosive screen shake."
            }
        ]
    },
    "Juggernaut": {
        "arcana": [
            {
                "id": "juggernaut_blade_fury",
                "name": "Blade Fury (Dragon Whirlwind)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/juggernaut_blade_fury.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/juggernaut/juggernaut_blade_fury.mp4",
                "description": "Ancient dragon energy circling the spin, slicing winds, and flying sparks."
            },
            {
                "id": "juggernaut_omni_slash",
                "name": "Omnislash (Astral Dragon Slash)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/juggernaut_omni_slash.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/juggernaut/juggernaut_omni_slash.mp4",
                "description": "Cyan glowing dragon dashes striking across targets with spatial distortion."
            }
        ]
    },
    "Phantom Assassin": {
        "arcana": [
            {
                "id": "phantom_assassin_stifling_dagger",
                "name": "Stifling Dagger (Paradox Blade)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/phantom_assassin_stifling_dagger.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/phantom_assassin/phantom_assassin_stifling_dagger.mp4",
                "description": "Throws twin ethereal rainbow-bladed spectral blades slicing through space."
            },
            {
                "id": "phantom_assassin_coup_de_grace",
                "name": "Coup de Grace (Manifold Memorial)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/phantom_assassin_coup_de_grace.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/phantom_assassin/phantom_assassin_coup_de_grace.mp4",
                "description": "Massive spatial blood splat leaving behind a permanently carved paradox gravestone."
            }
        ]
    },
    "Faceless Void": {
        "arcana": [
            {
                "id": "faceless_void_time_walk",
                "name": "Time Walk (Tentacle Rift)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/faceless_void_time_walk.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/faceless_void/faceless_void_time_walk.mp4",
                "description": "Opens cosmic void rift surrounded by Eldritch tentacles warping backward in time."
            },
            {
                "id": "faceless_void_chronosphere",
                "name": "Chronosphere (Claszian Domain)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/faceless_void_chronosphere.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/faceless_void/faceless_void_chronosphere.mp4",
                "description": "Colossal cosmic sphere featuring pulsing astral runes, cosmic nebulae, and Eldritch eyes."
            }
        ]
    },
    "Rubick": {
        "arcana": [
            {
                "id": "rubick_fade_bolt",
                "name": "Fade Bolt (Magus Resonator)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/rubick_fade_bolt.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/rubick/rubick_fade_bolt.mp4",
                "description": "Geometric prism laser leaping between enemies with glowing crystalline fragments."
            },
            {
                "id": "rubick_spell_steal",
                "name": "Spell Steal (The Magus Cypher)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/rubick_spell_steal.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/rubick/rubick_spell_steal.mp4",
                "description": "Custom emerald effects for 115+ stolen abilities with floating cubes and golden runes."
            }
        ]
    },
    "Invoker": {
        "arcana": [
            {
                "id": "invoker_sun_strike",
                "name": "Sun Strike (Dark Artistry Beacon)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/invoker_sun_strike.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/invoker/invoker_sun_strike.mp4",
                "description": "Celestial purple solar pillar crashing down with catastrophic planetary impact."
            },
            {
                "id": "invoker_chaos_meteor",
                "name": "Chaos Meteor (Dark Singularity)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/invoker_chaos_meteor.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/invoker/invoker_chaos_meteor.mp4",
                "description": "Rolling purple flaming asteroid leaving a trail of abyssal dark energy."
            }
        ]
    },
    "Wraith King": {
        "arcana": [
            {
                "id": "skeleton_king_hellfire_blast",
                "name": "Wraithfire Blast (Ostarion Flame)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/skeleton_king_hellfire_blast.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/skeleton_king/skeleton_king_hellfire_blast.mp4",
                "description": "Launches burning flaming skull enveloped in cursed bone fire."
            },
            {
                "id": "skeleton_king_reincarnation",
                "name": "Reincarnation (The One True King)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/skeleton_king_reincarnation.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/skeleton_king/skeleton_king_reincarnation.mp4",
                "description": "Shatters into flying bone armor before roaring back to life from the underworld."
            }
        ]
    },
    "Drow Ranger": {
        "arcana": [
            {
                "id": "drow_ranger_multishot",
                "name": "Multishot (Dread Retribution)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/drow_ranger_multishot.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/drow_ranger/drow_ranger_multishot.mp4",
                "description": "Fires volley of crimson dark crossbow bolts piercing enemies in a cone."
            }
        ]
    },
    "Razor": {
        "arcana": [
            {
                "id": "razor_static_link",
                "name": "Static Link (Voidstorm Tether)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/razor_static_link.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/razor/razor_static_link.mp4",
                "description": "Pulsing lightning coils draining kinetic energy with crackling high-voltage bolts."
            }
        ]
    },
    "Earthshaker": {
        "arcana": [
            {
                "id": "earthshaker_echo_slam",
                "name": "Echo Slam (Planetfall)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/earthshaker_echo_slam.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/earthshaker/earthshaker_echo_slam.mp4",
                "description": "Summons orbital planetary rings crashing down with cosmic reverberations."
            }
        ]
    },
    "Queen of Pain": {
        "arcana": [
            {
                "id": "queenofpain_sonic_wave",
                "name": "Sonic Wave (Eminence of Ristul)",
                "icon": f"{VALVE_CDN_ABILITY_IMG}/queenofpain_sonic_wave.png",
                "video": f"{VALVE_CDN_ABILITY_VID}/queenofpain/queenofpain_sonic_wave.mp4",
                "description": "Demonic shockwave of crimson sound obliterating armor and flesh."
            }
        ]
    }
}


def get_custom_spells_for_mod(mod_name: str, hero_name: str) -> List[Dict[str, Any]]:
    """Resolves custom spell icons and video effect previews for a given mod and hero."""
    if not hero_name:
        # Try to infer hero from mod_name
        for h in HERO_CUSTOM_SPELLS:
            if h.lower() in (mod_name or "").lower():
                hero_name = h
                break

    if not hero_name or hero_name not in HERO_CUSTOM_SPELLS:
        return []

    hero_spells = HERO_CUSTOM_SPELLS[hero_name]
    m_name_l = (mod_name or "").lower()

    # If it's an Arcana or high tier set, return the arcana custom spell set
    spells_raw = []
    arcana_keywords = ["arcana", "persona", "abscession", "demon eater", "legacy", "paradox", "clasz", "cypher", "great sage", "compass", "flockheart"]
    is_arcana = any(k in m_name_l for k in arcana_keywords)
    default_type = "arcana" if is_arcana else "immortal"
    if is_arcana or "immortal" in m_name_l:
        spells_raw = hero_spells.get("arcana", [])
    else:
        spells_raw = hero_spells.get("arcana", [])

    result = []
    for sp in spells_raw:
        item = dict(sp)
        item["type"] = default_type
        result.append(item)
    return result
