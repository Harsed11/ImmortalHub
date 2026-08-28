"""UI localization for ImmortalHub (EN/RU).

Data labels (mod names, hero names, category labels) come from the remote
constants.json and are English-only; this module translates the application
chrome (navigation, buttons, search, status strings).
"""

SUPPORTED_LANGUAGES = ("en", "ru")

STRINGS: dict = {
    # --- Sidebar navigation ---
    "nav.heroes":    {"en": "Hero Skins",        "ru": "Скины героев"},
    "nav.favorites": {"en": "Favorites",         "ru": "Избранное"},
    "nav.effects":   {"en": "Effects & Shaders", "ru": "Эффекты и шейдеры"},
    "nav.map":       {"en": "Terrain & World",   "ru": "Мир и ландшафт"},
    "nav.audio":     {"en": "Voice & Music",     "ru": "Звук и музыка"},
    "nav.misc":      {"en": "Items & Misc",      "ru": "Предметы и разное"},
    "nav.fpsboost":  {"en": "FPS Boost",         "ru": "FPS Boost"},
    "nav.installed": {"en": "Installed",         "ru": "Установленные"},
    "nav.settings":  {"en": "Settings",          "ru": "Настройки"},
    # --- Sidebar sections ---
    "section.browse": {"en": "BROWSE", "ru": "КАТАЛОГ"},
    "section.system": {"en": "SYSTEM", "ru": "СИСТЕМА"},
    # --- Sidebar status card ---
    "status.launch":      {"en": "▶ LAUNCH DOTA 2",    "ru": "▶ ЗАПУСТИТЬ DOTA 2"},
    "status.open_folder": {"en": "📁 OPEN MOD FOLDER", "ru": "📁 ОТКРЫТЬ ПАПКУ МОДОВ"},
    # --- Title bar ---
    "tb.play":    {"en": "▶ PLAY DOTA 2", "ru": "▶ ИГРАТЬ DOTA 2"},
    "tb.presets": {"en": "🎭 PRESETS",    "ru": "🎭 ПРЕСЕТЫ"},
    "tb.queue":   {"en": "⚡ QUEUE",       "ru": "⚡ ОЧЕРЕДЬ"},
    "tb.search":  {"en": "🔍 SEARCH",     "ru": "🔍 ПОИСК"},
    # --- Global search modal ---
    "search.title":        {"en": "GLOBAL SEARCH",                        "ru": "ГЛОБАЛЬНЫЙ ПОИСК"},
    "search.placeholder":  {"en": "Search skins, heroes, categories...",  "ru": "Поиск скинов, героев, категорий..."},
    "search.hint":         {"en": "↑↓ navigate   ↵ open   esc close",     "ru": "↑↓ навигация   ↵ открыть   esc закрыть"},
    "search.no_results":   {"en": "No mods found for",                    "ru": "Ничего не найдено по запросу"},
    "search.min_chars":    {"en": "Type at least 2 characters...",        "ru": "Введите минимум 2 символа..."},
    "search.installed":    {"en": "INSTALLED",                         "ru": "УСТАНОВЛЕН"},
    "search.favorites":    {"en": "FAVORITES",                            "ru": "ИЗБРАННОЕ"},
    "search.count":        {"en": "results",                              "ru": "результатов"},
    "search.installed_badge": {"en": "INSTALLED",                         "ru": "УСТАНОВЛЕН"},
    "search.install_action":  {"en": "OPEN",                              "ru": "ОТКРЫТЬ"},
    "search.navigate":     {"en": "navigate",                             "ru": "навигация"},
    "search.open":         {"en": "open",                                 "ru": "открыть"},
    "search.close":        {"en": "close",                                "ru": "закрыть"},
}

# Russian labels for category ids from the remote manifest. Categories not
# present here fall back to the English label from constants.json.
CATEGORY_RU_LABELS: dict = {
    "ti-bp-effects": "Эффекты боевого пропуска", "shaders": "Шейдеры",
    "item-effects": "Эффекты предметов", "creep-deny": "Денаи крипов",
    "emblems": "Эмблемы", "versus-screens": "Экраны противостояний",
    "terrains": "Ландшафты", "trees": "Деревья", "river": "Река",
    "roshan": "Рошан", "ancient": "Древние", "tormentor": "Мучители",
    "towers": "Башни", "pedestal": "Постаменты", "high-five": "Дай пять",
    "packs": "Наборы", "ranged-attack": "Дальняя атака",
    "weather": "Погода", "mega-kill": "Мега-убийства", "guides": "Гайды",
    "announcers": "Комментаторы", "music": "Музыка", "sounds": "Звуки",
    "hero-sounds": "Звуки героев", "herofx": "Эффекты героев",
    "creeps": "Крипы", "couriers": "Курьеры", "wards": "Варды",
    "huds": "Интерфейс (HUD)", "item-icons": "Иконки предметов",
    "ranks": "Ранги", "cursors": "Курсоры", "fonts": "Шрифты",
    "backgrounds": "Фоны", "other": "Другое", "heroes": "Скины героев",
    "hero-items": "Предметы героев", "custom": "Кастомные моды",
}


def normalize_lang(lang) -> str:
    """Return a supported language code, defaulting to English."""
    lang = str(lang or "en").lower()
    return lang if lang in SUPPORTED_LANGUAGES else "en"


def translate_ui(key: str, lang: str) -> str:
    """Translate a UI string with graceful fallbacks: lang -> en -> key."""
    entry = STRINGS.get(key)
    if entry is None:
        return key
    return entry.get(normalize_lang(lang)) or entry.get("en") or key


def translate_category(label_en: str, lang: str, key: str = "") -> str:
    """Translate a category label. Uses CATEGORY_RU_LABELS for Russian."""
    if normalize_lang(lang) != "ru":
        return label_en
    return CATEGORY_RU_LABELS.get(key, label_en)
