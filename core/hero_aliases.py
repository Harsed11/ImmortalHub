"""Comprehensive Dota 2 hero aliases, Russian transliterations, slang, and spell associations.

Used by mod_search.py, HeroesView.qml, and GlobalSearchModal to provide
smart fuzzy multi-lingual searching across all 127 heroes and thousands of mods.
"""

from typing import Dict, List, Set

# Mapping of canonical hero name (as used in HEROES_LIST / Valve schema)
# to alternate names, Russian names, community slang, and key spells.
HERO_ALIASES: Dict[str, List[str]] = {
    "Abaddon": [
        "абаддон", "абадон", "аба", "lord of avernus", "щит", "туман", "койл", "aphotic shield", "borrowed time"
    ],
    "Alchemist": [
        "алхимик", "алхим", "химик", "монеты", "золото", "кислота", "банка", "chemical rage", "greed"
    ],
    "Ancient Apparition": [
        "аппарат", "аа", "ancient apparition", "айсбласт", "айс бласт", "холод", "лед", "ice blast"
    ],
    "Anti-Mage": [
        "антимаг", "анти-маг", "магина", "ам", "am", "anti mage", "antimage", "маножог", "манаберн", "манавойд"
    ],
    "Arc Warden": [
        "арк варден", "арк", "варден", "зет", "zet", "arc warden", "копия", "клон", "темпест", "tempest double"
    ],
    "Axe": [
        "акс", "могул хан", "топор", "крутилка", "агр", "берсерк", "ульт", "culling blade", "berserker's call"
    ],
    "Bane": [
        "бейн", "беин", "атропос", "сон", "кошмар", "хватка", "грип", "fiend's grip", "nightmare"
    ],
    "Batrider": [
        "бэт райдер", "бетрайдер", "бет", "летучая мышь", "лассо", "огонь", "смола", "flaming lasso"
    ],
    "Beastmaster": [
        "бистмастер", "бист", "кабан", "птица", "рев", "топоры", "beast master", "primal roar"
    ],
    "Bloodseeker": [
        "бладсикер", "бс", "bs", "сикер", "кровь", "жажда", "rupture", "разрыв", "кровавая баня"
    ],
    "Bounty Hunter": [
        "баунти хантер", "бх", "bh", "гондор", "трек", "инвиз", "джинада", "track", "jinada"
    ],
    "Brewmaster": [
        "брюмастер", "брю", "панда", "хмелевар", "пиво", "пандарены", "три панды", "primal split"
    ],
    "Bristleback": [
        "бристлбек", "брист", "еж", "ежик", "спина", "колючки", "сопли", "quill spray", "warpath"
    ],
    "Broodmother": [
        "брудмазер", "бруда", "паучиха", "пауки", "сеть", "brood", "spiderlings", "spin web"
    ],
    "Centaur Warrunner": [
        "кентавр", "кент", "брэдвард", "топот", "стамп", "телега", "возвратка", "stampede", "hoof stomp"
    ],
    "Chaos Knight": [
        "хаос найт", "цк", "ck", "хаос", "конь", "иллюзии", "стан", "криты", "phantasm", "chaos bolt"
    ],
    "Chen": [
        "чен", "священник", "крипы", "зоопарк", "хил", "holy persuasion", "hand of god"
    ],
    "Clinkz": [
        "клинкз", "боник", "лучник", "скелет", "инвиз", "стрелы", "штрайф", "strafe", "burning army"
    ],
    "Clockwerk": [
        "клокверк", "клок", "железка", "коги", "шестеренки", "ракета", "хукшот", "hookshot", "power cogs"
    ],
    "Crystal Maiden": [
        "кристал мейден", "цм", "цмка", "cm", "рилай", "ледышка", "колба", "нова", "фризинг филд", "freezing field"
    ],
    "Dark Seer": [
        "дарк сир", "дс", "ds", "иштинка", "стена", "вакуум", "ускорение", "щиток", "wall of replica", "vacuum"
    ],
    "Dark Willow": [
        "дарк виллоу", "виллоу", "фея", "миреска", "бедрилам", "страх", "кусты", "bedlam", "terrorize"
    ],
    "Dawnbreaker": [
        "давнбрейкер", "давн", "валькирия", "молот", "звезда", "солар гардиан", "solar guardian", "starbreaker"
    ],
    "Dazzle": [
        "даззл", "дазл", "крест", "хил", "грейв", "яд", "мина", "shallow grave", "shadow wave"
    ],
    "Death Prophet": [
        "дезпрофет", "дп", "dp", "кробелус", "кроба", "духи", "экзорцизм", "молчанка", "exorcism", "silence"
    ],
    "Disruptor": [
        "дизраптор", "тралл", "круг", "статик шторм", "глаймпс", "возврат", "static storm", "glimpse"
    ],
    "Doom": [
        "дум", "люцифер", "ульт", "пожирание", "земля", "doom", "infernal blade", "devour"
    ],
    "Dragon Knight": [
        "драгон найт", "дк", "dk", "дэвион", "дракон", "огонь", "стан", "щит", "elder dragon form"
    ],
    "Drow Ranger": [
        "дров рейнджер", "тракса", "дровка", "дроу", "стрелы", "ледяные стрелы", "сало", "марксманшип", "multishot"
    ],
    "Earth Spirit": [
        "эрс спирит", "земеля", "земля", "камни", "каменщик", "стан", "магнитизм", "magnetize", "boulder smash"
    ],
    "Earthshaker": [
        "эрсшейкер", "шейкер", "фиссура", "эхослем", "эхо слэм", "тотем", "стан", "fissure", "echo slam"
    ],
    "Elder Titan": [
        "элдер титан", "титан", "ет", "et", "дух", "топот", "раскол", "землятресение", "earth splitter"
    ],
    "Ember Spirit": [
        "эмбер спирит", "эмбер", "синь", "огненный спирит", "реликвия", "реминанты", "слеш", "sleight of fist"
    ],
    "Enchantress": [
        "энчантрес", "энча", "коза", "олененок", "копья", "хил", "импетус", "impetus", "untouchable"
    ],
    "Enigma": [
        "энигма", "эдики", "эдолоны", "блэкхол", "блэк хол", "дыра", "black hole", "midnight pulse"
    ],
    "Faceless Void": [
        "фейслесс войд", "войд", "купол", "хроносфера", "хроно", "баши", "таймлок", "chronosphere", "time walk"
    ],
    "Grimstroke": [
        "гримстроук", "грим", "кисть", "чернила", "связка", "soulbind", "phantom's embrace", "stroke of faith"
    ],
    "Gyrocopter": [
        "гирокоптер", "гиро", "вертолет", "дед", "ракеты", "залп", "флак", "каллидаун", "call down", "flak cannon"
    ],
    "Hoodwink": [
        "худвинк", "белка", "арбалет", "желудь", "сеть", "снайп", "sharpshooter", "acorn shot"
    ],
    "Huskar": [
        "хускар", "хусик", "копья", "огонь", "берсерк", "лайфбрейк", "прыжок", "life break", "burning spear"
    ],
    "Invoker": [
        "инвокер", "инвок", "вокер", "карл", "kael", "karl", "санстрайк", "метеорит", "бласт", "торнадо", "форжи", "сферы", "sunstrike", "chaos meteor"
    ],
    "Io": [
        "ио", "виспа", "шарик", "светлячок", "связка", "релокейт", "духи", "tether", "relocate", "spirits"
    ],
    "Jakiro": [
        "джакиро", "двухголовый", "дракон", "лед и пламя", "макропира", "лед", "огонь", "macropyre", "ice path"
    ],
    "Juggernaut": [
        "джаггернаут", "джаггер", "юсернот", "югера", "крутилка", "омнислеш", "варди", "omnilash", "blade fury"
    ],
    "Keeper of the Light": [
        "кипер оф зе лайт", "котл", "kotl", "гендальф", "лошадь", "волна", "свет", "мана", "иллюминация", "illuminate"
    ],
    "Kunkka": [
        "кункка", "кунка", "адмирал", "корабль", "крест", "торрент", "сплеш", "ghostship", "torrent", "tidebringer"
    ],
    "Legion Commander": [
        "легион коммандер", "легионка", "лк", "lc", "дуэль", "стрелы", "прес", "хил", "duel", "press the attack"
    ],
    "Leshrac": [
        "лешрак", "леший", "конь", "радуга", "молнии", "стан", "пульс", "pulse nova", "split earth"
    ],
    "Lich": [
        "лич", "мертвец", "чайник", "цепной лед", "щит", "кукла", "chain frost", "frost shield"
    ],
    "Lifestealer": [
        "лайфстилер", "гуля", "наикс", "найкс", "naix", "рейдж", "отжор", "залезть", "rage", "infest"
    ],
    "Lina": [
        "лина", "огонь", "лагуна", "стан", "пламя", "драгонслейв", "laguna blade", "dragon slave"
    ],
    "Lion": [
        "лион", "лев", "демон", "палец", "ульта", "стан", "хекс", "манасос", "finger of death", "hex"
    ],
    "Lone Druid": [
        "лон друид", "силла", "медведь", "мишка", "друид", "трансформация", "spirit bear", "true form"
    ],
    "Luna": [
        "луна", "лунная", "кошка", "лучи", "лунное затмение", "бимы", "eclipse", "lucent beam"
    ],
    "Lycan": [
        "ликан", "волк", "волки", "оборотень", "криты", "вой", "shapeshift", "summon wolves"
    ],
    "Magnus": [
        "магнус", "магнат", "рп", "reverse polarity", "увоз", "скивер", "шоквейв", "эмповер", "skewer", "shockwave"
    ],
    "Marci": [
        "марси", "немая", "аниме", "кулаки", "ярость", "анлиш", "бросок", "unleash", "dispose"
    ],
    "Mars": [
        "марс", "бог войны", "арена", "копье", "щит", "удар щитом", "spear of mars", "arena of blood"
    ],
    "Medusa": [
        "медуза", "дуза", "змея", "щит маны", "стрелы", "взгляд", "камень", "stone gaze", "mana shield"
    ],
    "Meepo": [
        "мипо", "геомансер", "клоны", "лопата", "сетка", "пуф", "землекоп", "divided we stand", "poof"
    ],
    "Mirana": [
        "мирана", "потма", "стрела", "прыжок", "инвиз", "звездопад", "sacred arrow", "moonlight shadow"
    ],
    "Monkey King": [
        "манки кинг", "мк", "mk", "обезьяна", "сунь укун", "палка", "деревья", "арена", "wukong's command", "tree dance"
    ],
    "Morphling": [
        "морфлинг", "морф", "вода", "перекачка", "волна", "шот", "адаптив", "waveform", "adaptive strike"
    ],
    "Muerta": [
        "муэрта", "пистолеты", "смерть", "призраки", "выстрел", "рикошет", "pierce the veil", "dead shot"
    ],
    "Naga Siren": [
        "нага сирена", "нага", "песня", "сон", "иллюзии", "сетка", "риптайд", "song of the siren", "mirror image"
    ],
    "Nature's Prophet": [
        "нейчурс профит", "фурион", "фура", "пеньки", "деревья", "телепорт", "ульта по всей карте", "wrath of nature", "teleportation"
    ],
    "Necrophos": [
        "некрофос", "некр", "дедушка", "коса", "коса смерти", "хил", "аура", "смерть", "reaper's scythe", "death pulse"
    ],
    "Night Stalker": [
        "найт сталкер", "баланар", "ночь", "крылья", "молчание", "тьма", "darkness", "dark ascension"
    ],
    "Nyx Assassin": [
        "никс ассасин", "никс", "жук", "шипы", "вендетта", "инвиз", "стан", "burn", "vendetta", "spiked carpace"
    ],
    "Ogre Magi": [
        "огр маг", "огр", "два дурака", "мультикаст", "бладласт", "стан", "огонь", "multicast", "bloodlust"
    ],
    "Omniknight": [
        "омникнайт", "омник", "паладин", "молот", "хил", "репел", "гардиан", "guardian angel", "purification"
    ],
    "Oracle": [
        "оракул", "нерис", "ульт", "спасение", "очищение", "огонь", "false promise", "purifying flames"
    ],
    "Outworld Destroyer": [
        "аутворлд дестроер", "од", "od", "дестроер", "астрал", "орб", "ультимейт", "sanity's eclipse", "astral imprisonment"
    ],
    "Pangolier": [
        "пангольер", "панго", "броненосец", "шпага", "шар", "роллинг", "rolling thunder", "swashbuckle"
    ],
    "Phantom Assassin": [
        "фантом ассасин", "па", "pa", "мортра", "мортред", "криты", "фантомка", "кинжал", "блюр", "coup de grace", "stifling dagger"
    ],
    "Phantom Lancer": [
        "фантом лансер", "пл", "pl", "лансер", "иллюзии", "копье", "доппель", "копья", "juxtapose", "doppelganger"
    ],
    "Phoenix": [
        "феникс", "птица", "яйцо", "солнце", "луч", "огонь", "супернова", "supernova", "sun ray"
    ],
    "Primal Beast": [
        "праймал бист", "бист", "динозавр", "разгон", "хватка", "топот", "удар о землю", "pulverize", "onslaught"
    ],
    "Puck": [
        "пак", "дракончик", "сфера", "сало", "сон", "дрим коил", "шифт", "dream coil", "illusory orb"
    ],
    "Pudge": [
        "пудж", "падж", "мясник", "бучер", "хук", "крюк", "рот", "вонь", "дизмембер", "сожрать", "meat hook", "dismember", "rot"
    ],
    "Pugna": [
        "пугна", "зеленый", "варда", "сосалка", "лайфдрейн", "астрал", "башня", "life drain", "nether ward"
    ],
    "Queen of Pain": [
        "квин оф пейн", "квопа", "qop", "акаша", "блинк", "крик", "ульта", "соник вейв", "sonic wave", "scream of pain"
    ],
    "Razor": [
        "разор", "электрик", "статик линк", "ток", "шторм", "статическая связь", "static link", "eye of the storm"
    ],
    "Riki": [
        "рики", "сатир", "инвиз", "крыса", "тучка", "смок", "прыжки", "ульта", "tricks of the trade", "smoke screen"
    ],
    "Rubick": [
        "рубик", "великий маг", "воровство", "спеллстил", "телекинез", "болт", "spell steal", "telekinesis", "fade bolt"
    ],
    "Sand King": [
        "санд кинг", "ск", "sk", "крикс", "скорпион", "эпицентр", "стан", "песок", "epicenter", "burrowstrike"
    ],
    "Shadow Demon": [
        "шедоу демон", "сд", "sd", "демон", "иллюзии", "яд", "пурж", "очищение", "disruption", "demonic purge"
    ],
    "Shadow Fiend": [
        "шедоу финд", "сф", "sf", "невермор", "койлы", "raze", "души", "реквием", "демон", "requiem of souls", "shadowraze"
    ],
    "Shadow Shaman": [
        "шедоу шаман", "расту", "шаман", "бомж", "змейки", "хекс", "сетка", "варды", "mass serpent ward", "shackles"
    ],
    "Silencer": [
        "сайленсер", "сало", "нортон", "глобал", "глобал сайленс", "интеллект", "дизарм", "global silence", "glaives of wisdom"
    ],
    "Skywrath Mage": [
        "скайрас маг", "скай", "петух", "птица", "ульт", "молния", "сало", "мистик флейр", "mystic flare", "arcane bolt"
    ],
    "Slardar": [
        "слардар", "рыба", "селедка", "баши", "спринт", "лужа", "минус армор", "коридор", "corrosive haze", "slithereen crush"
    ],
    "Slark": [
        "сларк", "рыба", "ночная", "паунс", "прыжок", "дарк пакт", "тень", "ульт", "ловкость", "shadow dance", "pounce"
    ],
    "Snapfire": [
        "снапфайр", "бабка", "ящерица", "печенька", "дробовик", "ульта", "поцелуи", "mortimer kisses", "scatterblast"
    ],
    "Sniper": [
        "снайпер", "дед", "карлик", "шрапнель", "ульта", "прицел", "ассасинейт", "дальность", "assassinate", "shrapnel"
    ],
    "Spectre": [
        "спектра", "меркуриал", "иллюзии", "дагер", "дисперсия", "ульта", "хонт", "haunt", "spectral dagger"
    ],
    "Spirit Breaker": [
        "спирит брейкер", "бара", "корова", "разгон", "чардж", "баратрум", "баши", "charge of darkness", "nether strike"
    ],
    "Storm Spirit": [
        "шторм спирит", "шторм", "райджин", "панда", "электричество", "шар", "молния", "ball lightning", "static remnant"
    ],
    "Sven": [
        "свен", "рыцарь", "бог войны", "молот", "стан", "ульт", "годс стренгс", "сплеш", "god's strength", "storm hammer"
    ],
    "Techies": [
        "течис", "минеры", "мины", "бомбы", "смертники", "взрыв", "бочка", "proximity mines", "blast off"
    ],
    "Templar Assassin": [
        "темплар ассасин", "та", "ta", "ланая", "щитки", "рефракшн", "мелд", "ловушки", "refraction", "meld", "psionic trap"
    ],
    "Terrorblade": [
        "террорблейд", "тб", "tb", "иллюзии", "метаморфоза", "демон", "сандер", "обмен хп", "sunder", "metamorphosis"
    ],
    "Tidehunter": [
        "тайдхантер", "тайд", "арбуз", "левиафан", "равага", "щупальца", "якорь", "щит", "ravage", "anchor smash"
    ],
    "Timbersaw": [
        "тимберсоу", "тимбер", "дровосек", "пила", "деревья", "крюк", "чакрам", "chakram", "timber chain"
    ],
    "Tinker": [
        "тинкер", "бош", "робот", "лазер", "ракеты", "перезарядка", "реарм", "rearm", "laser"
    ],
    "Tiny": [
        "тини", "камень", "дерево", "аваланч", "бросок", "тосс", "рост", "avalanche", "toss", "grow"
    ],
    "Treant Protector": [
        "триант протектор", "трен", "дерево", "рут", "хил башен", "инвиз", "корни", "overgrowth", "living armor"
    ],
    "Troll Warlord": [
        "тролль варлорд", "тролль", "топоры", "ярость", "бессмертие", "топорики", "battle trance", "whirling axes"
    ],
    "Tusk": [
        "таск", "морж", "снежок", "панч", "удар", "сигил", "ледяная стена", "walrus punch", "snowball"
    ],
    "Underlord": [
        "андерлорд", "питлорд", "яма", "огонь", "портал", "телепорт", "dark rift", "pit of malice"
    ],
    "Undying": [
        "андаинг", "зомби", "томба", "могила", "сила", "декей", "голем", "decay", "tombstone", "flesh golem"
    ],
    "Ursa": [
        "урса", "медведь", "ульфсаар", "лапы", "ярость", "рошан", "энрейдж", "fury swipes", "enrage"
    ],
    "Vengeful Spirit": [
        "венга", "венджефул спирит", "свап", "обмен", "стан", "волна", "минус армор", "nether swap", "magic missile"
    ],
    "Venomancer": [
        "веномансер", "веник", "змея", "яд", "чума", "нова", "варды", "poison nova", "plague ward"
    ],
    "Viper": [
        "вайпер", "змея", "летающая", "плюка", "лужа", "яд", "страйк", "viper strike", "nethertoxin"
    ],
    "Visage": [
        "визаж", "птицы", "горгульи", "душа", "могильщик", "соул ассампшн", "familiars", "soul assumption"
    ],
    "Void Spirit": [
        "войд спирит", "инай", "четвертый спирит", "порталы", "диссимилейт", "астрал", "dissimilate", "astral step"
    ],
    "Warlock": [
        "варлок", "голем", "книга", "связка", "хил", "упал голем", "chaotic offering", "fatal bonds"
    ],
    "Weaver": [
        "вивер", "жук", "нить", "инвиз", "шукучи", "жуки", "таймлапс", "возврат времени", "time lapse", "shukuchi"
    ],
    "Windranger": [
        "виндрейнджер", "вр", "врка", "wr", "рыжая", "лучница", "связка", "стрела", "ветерок", "ульта", "focus fire", "shackleshot", "powershot"
    ],
    "Winter Wyvern": [
        "винтер виверна", "виверна", "аурора", "полет", "проклятие", "хил в кокон", "winter's curse", "arctic burn"
    ],
    "Witch Doctor": [
        "вич доктор", "вд", "wd", "знахарь", "маледикт", "бочонок", "каскады", "варда", "ульта вд", "death ward", "maledict", "paralyzing cask"
    ],
    "Wraith King": [
        "рейт кинг", "вк", "wk", "леорик", "папич", "скелет", "криты", "стан", "перерождение", "реинкарнация", "reincarnation", "wraithfire blast"
    ],
    "Zeus": [
        "зевс", "бог", "молния", "ульта по всем", "прыжок", "громовержец", "thundergod's wrath", "lightning bolt"
    ]
}

# Reverse index for lightning fast token -> List[HeroName] lookup
_REVERSE_INDEX: Dict[str, Set[str]] = {}

for hero, aliases in HERO_ALIASES.items():
    hero_l = hero.lower()
    for word in hero_l.split():
        _REVERSE_INDEX.setdefault(word, set()).add(hero)
    for alias in aliases:
        alias_l = alias.lower()
        _REVERSE_INDEX.setdefault(alias_l, set()).add(hero)
        for part in alias_l.split():
            if len(part) >= 2:
                _REVERSE_INDEX.setdefault(part, set()).add(hero)


def get_heroes_for_query(query: str) -> List[str]:
    """Given a search string (Russian slang, translit, spell, or English name),
    returns matching canonical hero names.
    """
    q = (query or "").strip().lower()
    if not q or len(q) < 2:
        return []

    matched_heroes: Set[str] = set()

    # Exact token match
    if q in _REVERSE_INDEX:
        matched_heroes.update(_REVERSE_INDEX[q])

    # Check substring matches across aliases
    for hero, aliases in HERO_ALIASES.items():
        if q in hero.lower():
            matched_heroes.add(hero)
            continue
        for a in aliases:
            if q in a:
                matched_heroes.add(hero)
                break

    return list(matched_heroes)


def expand_search_tokens(query: str) -> List[str]:
    """Expands search query tokens with associated hero names and transliterations
    so mod_search can match mods that only list English names.
    """
    tokens = (query or "").strip().lower().split()
    expanded = set(tokens)

    for token in tokens:
        if len(token) < 2:
            continue
        heroes = get_heroes_for_query(token)
        for h in heroes:
            expanded.add(h.lower())
            for part in h.lower().split():
                expanded.add(part)

    return list(expanded)
