"""Pure matching logic for the global mod search (no Qt dependencies)."""

from typing import Callable, Iterable, List


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
    else:
        parts.append(str(tags))
    return " ".join(parts).lower()


def filter_mods(mods: Iterable[dict], query: str,
                category_label: Callable[[str], str] = lambda cid: cid,
                limit: int = 60) -> List[dict]:
    """AND-match every whitespace-separated token against mod fields.

    Returns the original dicts (serialize before calling for QML usage).
    """
    query = (query or "").strip().lower()
    if len(query) < 2:
        return []
    tokens = query.split()
    results = []
    for mod in mods:
        haystack = _mod_haystack(mod, category_label)
        if all(token in haystack for token in tokens):
            results.append(mod)
            if len(results) >= limit:
                break
    return results
