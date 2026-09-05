"""
Animation and Video Previews database for ImmortalHub.
Provides verified high-definition animation loops and ability showcases (MP4/WebM)
for Arcanas, Personas, and special effects directly from Dota 2 CDN and mod repositories.
"""
from typing import Optional, Dict, Any, List
from api import BASE_URL, safe_url

STEAM_CDN_ABILITY = "https://cdn.cloudflare.steamstatic.com/apps/dota2/videos/dota_react/abilities"

# Mapping hero names / keywords to signature ability animation videos
HERO_ANIMATION_SHOWCASES: Dict[str, str] = {
    "shadow fiend": f"{STEAM_CDN_ABILITY}/nevermore/nevermore_requiem.mp4",
    "phantom assassin": f"{STEAM_CDN_ABILITY}/phantom_assassin/phantom_assassin_coup_de_grace.mp4",
    "faceless void": f"{STEAM_CDN_ABILITY}/faceless_void/faceless_void_chronosphere.mp4",
    "juggernaut": f"{STEAM_CDN_ABILITY}/juggernaut/juggernaut_omni_slash.mp4",
    "pudge": f"{STEAM_CDN_ABILITY}/pudge/pudge_meat_hook.mp4",
    "invoker": f"{STEAM_CDN_ABILITY}/invoker/invoker_sun_strike.mp4",
    "rubick": f"{STEAM_CDN_ABILITY}/rubick/rubick_spell_steal.mp4",
    "earthshaker": f"{STEAM_CDN_ABILITY}/earthshaker/earthshaker_echo_slam.mp4",
    "windranger": f"{STEAM_CDN_ABILITY}/windrunner/windrunner_focusfire.mp4",
    "queen of pain": f"{STEAM_CDN_ABILITY}/queenofpain/queenofpain_sonic_wave.mp4",
    "spectre": f"{STEAM_CDN_ABILITY}/spectre/spectre_haunt.mp4",
    "crystal maiden": f"{STEAM_CDN_ABILITY}/crystal_maiden/crystal_maiden_freezing_field.mp4",
    "drow ranger": f"{STEAM_CDN_ABILITY}/drow_ranger/drow_ranger_multishot.mp4",
    "anti-mage": f"{STEAM_CDN_ABILITY}/antimage/antimage_mana_void.mp4",
    "razor": f"{STEAM_CDN_ABILITY}/razor/razor_eye_of_the_storm.mp4",
    "monkey king": f"{STEAM_CDN_ABILITY}/monkey_king/monkey_king_wukongs_command.mp4",
    "lina": f"{STEAM_CDN_ABILITY}/lina/lina_laguna_blade.mp4",
    "terrorblade": f"{STEAM_CDN_ABILITY}/terrorblade/terrorblade_sunder.mp4",
    "legion commander": f"{STEAM_CDN_ABILITY}/legion_commander/legion_commander_duel.mp4",
    "zeus": f"{STEAM_CDN_ABILITY}/zuus/zuus_thundergods_wrath.mp4",
    "slark": f"{STEAM_CDN_ABILITY}/slark/slark_shadow_dance.mp4",
    "sniper": f"{STEAM_CDN_ABILITY}/sniper/sniper_assassinate.mp4",
    "axe": f"{STEAM_CDN_ABILITY}/axe/axe_culling_blade.mp4",
    "kunkka": f"{STEAM_CDN_ABILITY}/kunkka/kunkka_ghostship.mp4",
    "marci": f"{STEAM_CDN_ABILITY}/marci/marci_unleash.mp4",
    "primal beast": f"{STEAM_CDN_ABILITY}/primal_beast/primal_beast_pulverize.mp4",
    "muerta": f"{STEAM_CDN_ABILITY}/muerta/muerta_pierce_the_veil.mp4",
    "ringmaster": f"{STEAM_CDN_ABILITY}/ringmaster/ringmaster_wheel.mp4",
    "kez": f"{STEAM_CDN_ABILITY}/kez/kez_echo_slash.mp4",
}


def get_animation_preview_url(
    mod_name: str,
    hero_name: str = "",
    category_id: str = "",
    links: Optional[List[Dict[str, Any]]] = None,
    raw_preview: str = ""
) -> str:
    """
    Resolves a playable animation / video demonstration URL for a given mod:
    1. Checks if any link in links is a direct .mp4 or .webm.
    2. Checks if raw_preview is a video file.
    3. Checks if the mod is an Arcana / Persona / Immortal / High-tier skin and has a signature ability showcase.
    """
    # 1. Check links
    if links:
        for link in links:
            url = link.get("url", "")
            if any(url.lower().endswith(ext) for ext in [".mp4", ".webm"]):
                if url.startswith("http://") or url.startswith("https://"):
                    return safe_url(url)
                if url.startswith("assets/"):
                    return safe_url(f"{BASE_URL}/{url}")
                return safe_url(f"{BASE_URL}/assets/previews/{category_id}/{url}")

    # 2. Check raw_preview
    if raw_preview and any(raw_preview.lower().endswith(ext) for ext in [".mp4", ".webm"]):
        if raw_preview.startswith("http://") or raw_preview.startswith("https://"):
            return safe_url(raw_preview)
        if raw_preview.startswith("assets/"):
            return safe_url(f"{BASE_URL}/{raw_preview}")
        return safe_url(f"{BASE_URL}/assets/previews/{category_id}/{raw_preview}")

    # 3. Signature Arcana/Persona/Hero animation video
    name_l = (mod_name or "").lower()
    hero_l = (hero_name or "").lower().replace("_", " ").strip()

    # If hero is not passed, infer from name
    if not hero_l:
        for h in HERO_ANIMATION_SHOWCASES:
            if h in name_l:
                hero_l = h
                break

    if hero_l in HERO_ANIMATION_SHOWCASES:
        return HERO_ANIMATION_SHOWCASES[hero_l]

    # Fuzzy match on hero name key
    for h, url in HERO_ANIMATION_SHOWCASES.items():
        if h in hero_l or hero_l in h:
            return url

    return ""
