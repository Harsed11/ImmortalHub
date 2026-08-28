# Player & Match Statistics Engine for ImmortalHub
import os
import json
import time
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor
from typing import Dict, List, Any, Optional

from core.logger import logger

STEAM_HERO_IMG_BASE = 'https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/heroes/'

HERO_ID_MAP = {
    1: 'antimage', 2: 'axe', 3: 'bane', 4: 'bloodseeker', 5: 'crystal_maiden',
    6: 'drow_ranger', 7: 'earthshaker', 8: 'juggernaut', 9: 'mirana', 10: 'morphling',
    11: 'nevermore', 12: 'phantom_lancer', 13: 'puck', 14: 'pudge', 15: 'razor',
    16: 'sand_king', 17: 'storm_spirit', 18: 'sven', 19: 'tiny', 20: 'vengefulspirit',
    21: 'windrunner', 22: 'zuus', 23: 'kunkka', 25: 'lina', 26: 'lion',
    27: 'shadow_shaman', 28: 'slardar', 29: 'tidehunter', 30: 'witch_doctor', 31: 'lich',
    32: 'riki', 33: 'enigma', 34: 'tinker', 35: 'sniper', 36: 'necrolyte',
    37: 'warlock', 38: 'beastmaster', 39: 'queenofpain', 40: 'venomancer', 41: 'faceless_void',
    42: 'skeleton_king', 43: 'death_prophet', 44: 'phantom_assassin', 45: 'pugna', 46: 'templar_assassin',
    47: 'viper', 48: 'luna', 49: 'dragon_knight', 50: 'dazzle', 51: 'rattletrap',
    52: 'leshrac', 53: 'furion', 54: 'life_stealer', 55: 'dark_seer', 56: 'clinkz',
    57: 'omniknight', 58: 'enchantress', 59: 'huskar', 60: 'night_stalker', 61: 'broodmother',
    62: 'bounty_hunter', 63: 'weaver', 64: 'jakiro', 65: 'batrider', 66: 'chen',
    67: 'spectre', 68: 'ancient_apparition', 69: 'doom_bringer', 70: 'ursa', 71: 'spirit_breaker',
    72: 'gyrocopter', 73: 'alchemist', 74: 'invoker', 75: 'silencer', 76: 'obsidian_destroyer',
    77: 'lycan', 78: 'lone_druid', 79: 'brewmaster', 80: 'shadow_demon', 81: 'chaos_knight',
    82: 'meepo', 83: 'treant', 84: 'ogre_magi', 85: 'undying', 86: 'rubick',
    87: 'disruptor', 88: 'nyx_assassin', 89: 'naga_siren', 90: 'keeper_of_the_light', 91: 'wisp',
    92: 'visage', 93: 'slark', 94: 'medusa', 95: 'troll_warlord', 96: 'centaur',
    97: 'magnataur', 98: 'shredder', 99: 'bristleback', 100: 'tusk', 101: 'skywrath_mage',
    102: 'abaddon', 103: 'elder_titan', 104: 'legion_commander', 105: 'techies', 106: 'ember_spirit',
    107: 'earth_spirit', 108: 'abyssal_underlord', 109: 'terrorblade', 110: 'phoenix', 111: 'oracle',
    112: 'winter_wyvern', 113: 'arc_warden', 114: 'monkey_king', 119: 'dark_willow', 120: 'pangolier',
    121: 'grimstroke', 123: 'hoodwink', 126: 'void_spirit', 128: 'snapfire', 129: 'mars',
    135: 'dawnbreaker', 136: 'marci', 137: 'primal_beast', 138: 'muerta', 145: 'ringmaster', 146: 'kez'
}

HERO_PRETTY_NAMES = {
    'antimage': 'Anti-Mage', 'nevermore': 'Shadow Fiend', 'zuus': 'Zeus', 'windrunner': 'Windranger',
    'skeleton_king': 'Wraith King', 'rattletrap': 'Clockwerk', 'furion': 'Nature\'s Prophet',
    'life_stealer': 'Lifestealer', 'doom_bringer': 'Doom', 'obsidian_destroyer': 'Outworld Destroyer',
    'shredder': 'Timbersaw', 'abyssal_underlord': 'Underlord', 'necrolyte': 'Necrophos',
    'queenofpain': 'Queen of Pain', 'faceless_void': 'Faceless Void', 'phantom_assassin': 'Phantom Assassin',
    'templar_assassin': 'Templar Assassin', 'dragon_knight': 'Dragon Knight', 'dark_seer': 'Dark Seer',
    'bounty_hunter': 'Bounty Hunter', 'ancient_apparition': 'Ancient Apparition', 'spirit_breaker': 'Spirit Breaker',
    'chaos_knight': 'Chaos Knight', 'treant': 'Treant Protector', 'ogre_magi': 'Ogre Magi',
    'nyx_assassin': 'Nyx Assassin', 'naga_siren': 'Naga Siren', 'keeper_of_the_light': 'Keeper of the Light',
    'troll_warlord': 'Troll Warlord', 'centaur': 'Centaur Warrunner', 'skywrath_mage': 'Skywrath Mage',
    'legion_commander': 'Legion Commander', 'ember_spirit': 'Ember Spirit', 'earth_spirit': 'Earth Spirit',
    'winter_wyvern': 'Winter Wyvern', 'arc_warden': 'Arc Warden', 'monkey_king': 'Monkey King',
    'dark_willow': 'Dark Willow', 'void_spirit': 'Void Spirit', 'primal_beast': 'Primal Beast'
}

RANK_TIER_NAMES = {
    0: 'Unranked', 1: 'Herald', 2: 'Guardian', 3: 'Crusader', 4: 'Archon',
    5: 'Legend', 6: 'Ancient', 7: 'Divine', 8: 'Immortal'
}

class StatsService:
    def __init__(self):
        self._cache = {}
        self._cache_ttl = 900  # 15 min
        self._pool = ThreadPoolExecutor(max_workers=8)

    def steam64_to_account_id(self, steam64: int) -> int:
        return int(steam64) - 76561197960265728

    def account_id_to_steam64(self, account_id: int) -> int:
        return int(account_id) + 76561197960265728

    def get_hero_name(self, hero_id: int) -> str:
        short = HERO_ID_MAP.get(int(hero_id), 'unknown')
        if short in HERO_PRETTY_NAMES:
            return HERO_PRETTY_NAMES[short]
        return short.replace('_', ' ').title()

    def get_hero_avatar(self, hero_id: int) -> str:
        short = HERO_ID_MAP.get(int(hero_id), '')
        if not short:
            return ''
        return f'{STEAM_HERO_IMG_BASE}{short}.png'

    def get_rank_display(self, rank_tier: Optional[int], leaderboard_rank: Optional[int] = None) -> Dict[str, Any]:
        if not rank_tier or rank_tier == 0:
            return {'name': 'Unranked', 'division': '', 'badge': '❓', 'tier': 0, 'full': 'Unranked'}
        
        tier = rank_tier // 10
        stars = rank_tier % 10
        base_name = RANK_TIER_NAMES.get(tier, 'Unranked')
        
        if tier == 8:
            if leaderboard_rank:
                return {'name': 'Immortal', 'division': f'#{leaderboard_rank}', 'badge': '🏆', 'tier': 8, 'full': f'Immortal #{leaderboard_rank}'}
            return {'name': 'Immortal', 'division': '', 'badge': '🏆', 'tier': 8, 'full': 'Immortal'}
        
        stars_roman = ['I', 'II', 'III', 'IV', 'V'][min(max(0, stars - 1), 4)] if stars > 0 else ''
        return {
            'name': base_name,
            'division': stars_roman,
            'badge': f'{base_name[:3]} {stars_roman}'.strip(),
            'tier': tier,
            'full': f'{base_name} {stars_roman}'.strip()
        }

    def _http_get(self, url: str) -> Optional[Any]:
        req = urllib.request.Request(
            url,
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)',
                'Accept': 'application/json'
            }
        )
        try:
            with urllib.request.urlopen(req, timeout=4) as resp:
                return json.loads(resp.read().decode('utf-8'))
        except Exception as e:
            logger.debug(f'HTTP get error for {url}: {e}')
            return None

    def fetch_player_stats(self, account_id: int) -> Dict[str, Any]:
        account_id = int(account_id)
        now = time.time()
        
        if account_id in self._cache:
            entry = self._cache[account_id]
            if now - entry['timestamp'] < self._cache_ttl:
                return entry['data']

        logger.info(f'Fetching stats for account {account_id}...')
        player_info = self._http_get(f'https://api.opendota.com/api/players/{account_id}')
        wl_info = self._http_get(f'https://api.opendota.com/api/players/{account_id}/wl')
        recent_matches = self._http_get(f'https://api.opendota.com/api/players/{account_id}/recentMatches')
        heroes_info = self._http_get(f'https://api.opendota.com/api/players/{account_id}/heroes')

        is_private = not bool(player_info and player_info.get('profile'))
        
        profile = player_info.get('profile', {}) if player_info else {}
        name = profile.get('personaname') or f'Player {account_id}'
        avatar = profile.get('avatarfull') or profile.get('avatar') or ''
        rank_tier = player_info.get('rank_tier') if player_info else None
        leaderboard_rank = player_info.get('leaderboard_rank') if player_info else None
        rank_meta = self.get_rank_display(rank_tier, leaderboard_rank)

        wins = wl_info.get('win', 0) if wl_info else 0
        losses = wl_info.get('lose', 0) if wl_info else 0
        total_games = wins + losses
        winrate = round((wins / total_games * 100), 1) if total_games > 0 else 0.0

        # Recent 20 matches stats & history dots
        recent_wins = 0
        recent_count = 0
        current_streak = 0
        streak_type = None
        recent_history = []  # Last 5 matches: ['W', 'L', 'W', ...]

        if recent_matches and isinstance(recent_matches, list):
            recent_count = len(recent_matches)
            for i, m in enumerate(recent_matches):
                is_radiant = m.get('player_slot', 0) < 128
                radiant_win = m.get('radiant_win', False)
                won = (is_radiant and radiant_win) or (not is_radiant and not radiant_win)
                
                if won:
                    recent_wins += 1
                
                if i < 5:
                    recent_history.append('W' if won else 'L')

                if i == 0:
                    streak_type = 'W' if won else 'L'
                    current_streak = 1
                elif streak_type:
                    if (won and streak_type == 'W') or (not won and streak_type == 'L'):
                        current_streak += 1
                    else:
                        streak_type = None

        recent_winrate = round((recent_wins / recent_count * 100), 1) if recent_count > 0 else 0.0
        streak_str = f"{current_streak}{streak_type}" if (streak_type and current_streak >= 2) else "-"
        is_on_fire = (streak_type == "W" and current_streak >= 3)
        is_tilting = (streak_type == "L" and current_streak >= 3)

        # Top Signature Heroes
        signatures = []
        ban_recommendation = None

        if heroes_info and isinstance(heroes_info, list):
            valid_heroes = [h for h in heroes_info if h.get('games', 0) >= 3]
            valid_heroes.sort(key=lambda x: (x.get('games', 0) * (x.get('win', 0) / max(1, x.get('games', 1)))), reverse=True)
            
            for h in valid_heroes[:5]:
                hid = int(h.get('hero_id', 0))
                h_games = int(h.get('games', 0))
                h_wins = int(h.get('win', 0))
                h_wr = round((h_wins / h_games * 100), 1) if h_games > 0 else 0.0
                is_spammer = h_games >= 20 and h_wr >= 56.0
                
                sig_item = {
                    'heroId': hid,
                    'heroName': self.get_hero_name(hid),
                    'avatar': self.get_hero_avatar(hid),
                    'games': h_games,
                    'winrate': h_wr,
                    'isSpammer': is_spammer
                }
                signatures.append(sig_item)
                
                if is_spammer and not ban_recommendation:
                    ban_recommendation = sig_item

        result = {
            'accountId': account_id,
            'name': name,
            'avatar': avatar,
            'isPrivate': is_private,
            'rank': rank_meta,
            'totalGames': total_games,
            'winrate': winrate,
            'recentWinrate': recent_winrate,
            'recentHistory': recent_history,
            'streak': streak_str,
            'isOnFire': is_on_fire,
            'isTilting': is_tilting,
            'signatureHeroes': signatures,
            'banRecommendation': ban_recommendation,
            'pickedHero': None
        }

        self._cache[account_id] = {'data': result, 'timestamp': now}
        return result

    def fetch_match_players(self, player_ids: List[int]) -> List[Dict[str, Any]]:
        results = list(self._pool.map(self.fetch_player_stats, player_ids))
        return results

    def build_match_from_ids(self, player_ids: List[int], match_id: str = "Live") -> Dict[str, Any]:
        players = self.fetch_match_players(player_ids)
        # Split into Radiant (up to 5) and Dire (up to 5)
        radiant = players[:5]
        dire = players[5:10]
        return {
            'matchId': str(match_id),
            'gameMode': 'Live Dota 2 Match',
            'gameState': 'DOTA_GAMERULES_STATE_HERO_SELECTION',
            'radiant': radiant,
            'dire': dire
        }

    def search_player_by_query(self, query: str) -> Optional[Dict[str, Any]]:
        query = query.strip()
        if not query:
            return None
        
        # Check if URL
        if 'dotabuff.com/players/' in query or 'opendota.com/players/' in query:
            import re
            m = re.search(r'/players/(\d+)', query)
            if m:
                return self.fetch_player_stats(int(m.group(1)))

        # Check if digits
        if query.isdigit():
            val = int(query)
            if val > 76561197960265728:
                val = self.steam64_to_account_id(val)
            return self.fetch_player_stats(val)

        return None

    def get_mock_match(self) -> Dict[str, Any]:
        return {
            'matchId': '7892144321',
            'gameMode': 'All Pick (Ranked)',
            'gameState': 'DOTA_GAMERULES_STATE_HERO_SELECTION',
            'radiant': [
                {
                    'accountId': 11111111, 'name': 'Miracle-', 'avatar': 'https://avatars.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg',
                    'isPrivate': False, 'rank': {'name': 'Immortal', 'division': '#42', 'badge': '🏆', 'tier': 8, 'full': 'Immortal #42'},
                    'totalGames': 4820, 'winrate': 59.4, 'recentWinrate': 75.0, 'streak': '6W', 'isOnFire': True, 'isTilting': False,
                    'signatureHeroes': [
                        {'heroId': 74, 'heroName': 'Invoker', 'avatar': self.get_hero_avatar(74), 'games': 820, 'winrate': 64.2, 'isSpammer': True},
                        {'heroId': 11, 'heroName': 'Shadow Fiend', 'avatar': self.get_hero_avatar(11), 'games': 510, 'winrate': 61.0, 'isSpammer': True},
                        {'heroId': 1, 'heroName': 'Anti-Mage', 'avatar': self.get_hero_avatar(1), 'games': 390, 'winrate': 58.5, 'isSpammer': False}
                    ],
                    'banRecommendation': {'heroId': 74, 'heroName': 'Invoker', 'winrate': 64.2},
                    'pickedHero': {'heroId': 74, 'heroName': 'Invoker', 'avatar': self.get_hero_avatar(74)}
                },
                {
                    'accountId': 22222222, 'name': 'Topson', 'avatar': '',
                    'isPrivate': False, 'rank': {'name': 'Immortal', 'division': '#88', 'badge': '🏆', 'tier': 8, 'full': 'Immortal #88'},
                    'totalGames': 3940, 'winrate': 57.8, 'recentWinrate': 65.0, 'streak': '3W', 'isOnFire': True, 'isTilting': False,
                    'signatureHeroes': [
                        {'heroId': 13, 'heroName': 'Puck', 'avatar': self.get_hero_avatar(13), 'games': 420, 'winrate': 62.1, 'isSpammer': True},
                        {'heroId': 106, 'heroName': 'Ember Spirit', 'avatar': self.get_hero_avatar(106), 'games': 340, 'winrate': 59.8, 'isSpammer': True},
                        {'heroId': 19, 'heroName': 'Tiny', 'avatar': self.get_hero_avatar(19), 'games': 290, 'winrate': 57.0, 'isSpammer': False}
                    ],
                    'banRecommendation': {'heroId': 13, 'heroName': 'Puck', 'winrate': 62.1},
                    'pickedHero': None
                },
                {
                    'accountId': 33333333, 'name': 'Collapse', 'avatar': '',
                    'isPrivate': False, 'rank': {'name': 'Immortal', 'division': '#120', 'badge': '🏆', 'tier': 8, 'full': 'Immortal #120'},
                    'totalGames': 3100, 'winrate': 56.5, 'recentWinrate': 55.0, 'streak': '-', 'isOnFire': False, 'isTilting': False,
                    'signatureHeroes': [
                        {'heroId': 97, 'heroName': 'Magnus', 'avatar': self.get_hero_avatar(97), 'games': 620, 'winrate': 66.8, 'isSpammer': True},
                        {'heroId': 129, 'heroName': 'Mars', 'avatar': self.get_hero_avatar(129), 'games': 450, 'winrate': 61.2, 'isSpammer': True},
                        {'heroId': 49, 'heroName': 'Dragon Knight', 'avatar': self.get_hero_avatar(49), 'games': 310, 'winrate': 58.0, 'isSpammer': False}
                    ],
                    'banRecommendation': {'heroId': 97, 'heroName': 'Magnus', 'winrate': 66.8},
                    'pickedHero': None
                },
                {
                    'accountId': 44444444, 'name': 'Miposhka', 'avatar': '',
                    'isPrivate': False, 'rank': {'name': 'Immortal', 'division': '#310', 'badge': '🏆', 'tier': 8, 'full': 'Immortal #310'},
                    'totalGames': 5400, 'winrate': 54.2, 'recentWinrate': 50.0, 'streak': '-', 'isOnFire': False, 'isTilting': False,
                    'signatureHeroes': [
                        {'heroId': 31, 'heroName': 'Lich', 'avatar': self.get_hero_avatar(31), 'games': 580, 'winrate': 57.5, 'isSpammer': True},
                        {'heroId': 83, 'heroName': 'Treant Protector', 'avatar': self.get_hero_avatar(83), 'games': 410, 'winrate': 56.0, 'isSpammer': False},
                        {'heroId': 86, 'heroName': 'Rubick', 'avatar': self.get_hero_avatar(86), 'games': 390, 'winrate': 53.0, 'isSpammer': False}
                    ],
                    'banRecommendation': None,
                    'pickedHero': None
                },
                {
                    'accountId': 55555555, 'name': 'Anonymous Pudge', 'avatar': '',
                    'isPrivate': True, 'rank': {'name': 'Divine', 'division': 'IV', 'badge': 'DIV IV', 'tier': 7, 'full': 'Divine IV'},
                    'totalGames': 0, 'winrate': 0.0, 'recentWinrate': 0.0, 'streak': '-', 'isOnFire': False, 'isTilting': False,
                    'signatureHeroes': [],
                    'banRecommendation': None,
                    'pickedHero': None
                }
            ],
            'dire': [
                {
                    'accountId': 66666666, 'name': 'Yatoro (Raddan)', 'avatar': '',
                    'isPrivate': False, 'rank': {'name': 'Immortal', 'division': '#5', 'badge': '🏆', 'tier': 8, 'full': 'Immortal #5'},
                    'totalGames': 6120, 'winrate': 62.1, 'recentWinrate': 80.0, 'streak': '7W', 'isOnFire': True, 'isTilting': False,
                    'signatureHeroes': [
                        {'heroId': 10, 'heroName': 'Morphling', 'avatar': self.get_hero_avatar(10), 'games': 890, 'winrate': 65.4, 'isSpammer': True},
                        {'heroId': 109, 'heroName': 'Terrorblade', 'avatar': self.get_hero_avatar(109), 'games': 620, 'winrate': 63.8, 'isSpammer': True},
                        {'heroId': 44, 'heroName': 'Phantom Assassin', 'avatar': self.get_hero_avatar(44), 'games': 480, 'winrate': 60.5, 'isSpammer': True}
                    ],
                    'banRecommendation': {'heroId': 10, 'heroName': 'Morphling', 'winrate': 65.4},
                    'pickedHero': {'heroId': 10, 'heroName': 'Morphling', 'avatar': self.get_hero_avatar(10)}
                },
                {
                    'accountId': 77777777, 'name': 'gpk~', 'avatar': '',
                    'isPrivate': False, 'rank': {'name': 'Immortal', 'division': '#18', 'badge': '🏆', 'tier': 8, 'full': 'Immortal #18'},
                    'totalGames': 4780, 'winrate': 58.7, 'recentWinrate': 60.0, 'streak': '2W', 'isOnFire': False, 'isTilting': False,
                    'signatureHeroes': [
                        {'heroId': 17, 'heroName': 'Storm Spirit', 'avatar': self.get_hero_avatar(17), 'games': 550, 'winrate': 61.2, 'isSpammer': True},
                        {'heroId': 46, 'heroName': 'Templar Assassin', 'avatar': self.get_hero_avatar(46), 'games': 430, 'winrate': 60.0, 'isSpammer': True},
                        {'heroId': 39, 'heroName': 'Queen of Pain', 'avatar': self.get_hero_avatar(39), 'games': 390, 'winrate': 57.5, 'isSpammer': False}
                    ],
                    'banRecommendation': {'heroId': 17, 'heroName': 'Storm Spirit', 'winrate': 61.2},
                    'pickedHero': None
                },
                {
                    'accountId': 88888888, 'name': '33 (Net 33)', 'avatar': '',
                    'isPrivate': False, 'rank': {'name': 'Immortal', 'division': '#25', 'badge': '🏆', 'tier': 8, 'full': 'Immortal #25'},
                    'totalGames': 5100, 'winrate': 57.3, 'recentWinrate': 45.0, 'streak': '3L', 'isOnFire': False, 'isTilting': True,
                    'signatureHeroes': [
                        {'heroId': 77, 'heroName': 'Lycan', 'avatar': self.get_hero_avatar(77), 'games': 710, 'winrate': 64.5, 'isSpammer': True},
                        {'heroId': 38, 'heroName': 'Beastmaster', 'avatar': self.get_hero_avatar(38), 'games': 580, 'winrate': 62.0, 'isSpammer': True},
                        {'heroId': 92, 'heroName': 'Visage', 'avatar': self.get_hero_avatar(92), 'games': 490, 'winrate': 63.2, 'isSpammer': True}
                    ],
                    'banRecommendation': {'heroId': 77, 'heroName': 'Lycan', 'winrate': 64.5},
                    'pickedHero': None
                },
                {
                    'accountId': 99999999, 'name': 'Sneyking', 'avatar': '',
                    'isPrivate': False, 'rank': {'name': 'Immortal', 'division': '#110', 'badge': '🏆', 'tier': 8, 'full': 'Immortal #110'},
                    'totalGames': 4300, 'winrate': 53.8, 'recentWinrate': 50.0, 'streak': '-', 'isOnFire': False, 'isTilting': False,
                    'signatureHeroes': [
                        {'heroId': 64, 'heroName': 'Jakiro', 'avatar': self.get_hero_avatar(64), 'games': 420, 'winrate': 56.4, 'isSpammer': False},
                        {'heroId': 68, 'heroName': 'Ancient Apparition', 'avatar': self.get_hero_avatar(68), 'games': 380, 'winrate': 55.0, 'isSpammer': False},
                        {'heroId': 27, 'heroName': 'Shadow Shaman', 'avatar': self.get_hero_avatar(27), 'games': 310, 'winrate': 54.0, 'isSpammer': False}
                    ],
                    'banRecommendation': None,
                    'pickedHero': None
                },
                {
                    'accountId': 10101010, 'name': 'ShadowRaze_God', 'avatar': '',
                    'isPrivate': False, 'rank': {'name': 'Divine', 'division': 'V', 'badge': 'DIV V', 'tier': 7, 'full': 'Divine V'},
                    'totalGames': 2400, 'winrate': 52.1, 'recentWinrate': 35.0, 'streak': '5L', 'isOnFire': False, 'isTilting': True,
                    'signatureHeroes': [
                        {'heroId': 14, 'heroName': 'Pudge', 'avatar': self.get_hero_avatar(14), 'games': 620, 'winrate': 49.5, 'isSpammer': False},
                        {'heroId': 35, 'heroName': 'Sniper', 'avatar': self.get_hero_avatar(35), 'games': 310, 'winrate': 51.0, 'isSpammer': False},
                        {'heroId': 8, 'heroName': 'Juggernaut', 'avatar': self.get_hero_avatar(8), 'games': 290, 'winrate': 53.0, 'isSpammer': False}
                    ],
                    'banRecommendation': None,
                    'pickedHero': None
                }
            ]
        }
