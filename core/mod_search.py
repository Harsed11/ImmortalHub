"""Pure matching logic for the global mod search (no Qt dependencies)."""

from typing import Callable, Iterable, List, Set
from core.hero_aliases import get_heroes_for_query, HERO_ALIASES


def _mod_haystack(mod: dict, category_label: Callable[[str], str]) -> str:
    parts = [
        str(mod.get("name", "")),
        str(mod.get("hero", "")),
        str(mod.get("categoryId", "")),
        category_label(str(mod.get("categoryId", ""))),
    ]
    tags = mod.get("tags") or []
    if isinstance(tags, (list, tuple)):
        parts.extend(str(t) for t in tags)
    elif isinstance(tags, dict):
        parts.extend(str(k) + " " + str(v) for k, v in tags.items())
    else:
        parts.append(str(tags))
    return " ".join(parts).lower()


def filter_mods(mods: Iterable[dict], query: str,
                category_label: Callable[[str], str] = lambda cid: cid,
                limit: int = 60) -> List[dict]:
    """Smart fuzzy multi-lingual matching against mod fields and Dota 2 hero aliases.

    Matches English names, Russian names, nicknames (e.g. 'пудж', 'сф', 'папич', 'гуля'),
    and spell associations ('хук', 'койлы', 'купол').
    """
    query = (query or "").strip().lower()
    if len(query) < 2:
        return []

    tokens = query.split()
    matched_heroes_from_query: Set[str] = set(get_heroes_for_query(query))
    for t in tokens:
        if len(t) >= 2:
            matched_heroes_from_query.update(get_heroes_for_query(t))

    matched_heroes_lower = {h.lower() for h in matched_heroes_from_query}

    results = []
    for mod in mods:
        haystack = _mod_haystack(mod, category_label)
        mod_hero = str(mod.get("hero", "")).strip().lower()

        # 1. Direct token match in haystack
        direct_match = all(token in haystack for token in tokens)

        # 2. Hero alias match (e.g. query='пудж', mod.hero='Pudge')
        alias_hero_match = False
        if matched_heroes_lower and mod_hero:
            if mod_hero in matched_heroes_lower or any(mh in mod_hero for mh in matched_heroes_lower):
                alias_hero_match = True

        # 3. Mod name mentions an aliased hero
        if not alias_hero_match and matched_heroes_lower:
            mod_name_l = str(mod.get("name", "")).lower()
            if any(mh in mod_name_l for mh in matched_heroes_lower):
                alias_hero_match = True

        if direct_match or alias_hero_match:
            results.append(mod)
            if len(results) >= limit:
                break

    return results
