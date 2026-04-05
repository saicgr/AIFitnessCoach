"""
Gemini Service Workout Naming - Holiday themes and workout name generation.
"""
import logging
from typing import Optional
from datetime import datetime

logger = logging.getLogger("gemini")


class WorkoutNamingMixin:
    """Mixin providing workout naming methods for GeminiService."""

    def _get_holiday_theme(self, workout_date: Optional[str] = None, user_dob: Optional[str] = None) -> Optional[str]:
        """
        Subtle holiday hint on the actual day (±1 day).
        Returns a gentle suggestion — the workout name should still primarily
        reflect the training focus, with an optional nod to the occasion.

        Priority (first match wins):
          0. User's birthday — the most personal occasion
          1. Moveable holidays — year-based lookup tables (lunar/Islamic/computed)
          2. Fixed-date holidays — same calendar date every year
          3. Fitness legends birthdays — exact day only (no ±1)
        """
        from datetime import datetime, date, timedelta

        if not workout_date:
            check_date = datetime.now()
        else:
            try:
                check_date = datetime.fromisoformat(workout_date.replace('Z', '+00:00'))
            except Exception as e:
                logger.debug(f"Failed to parse workout_date: {e}")
                check_date = datetime.now()

        month, day = check_date.month, check_date.day
        year = check_date.year
        check_d = date(year, month, day)

        _suffix = ". Keep the training focus primary — the occasion nod is optional flavor, not the main theme."

        def _near(target_m: int, target_d: int, tolerance: int = 1) -> bool:
            """Check if today is within ±tolerance days of target date."""
            try:
                target = date(year, target_m, target_d)
                return abs((check_d - target).days) <= tolerance
            except ValueError:
                return False

        # ══════════════════════════════════════════════════════════
        # 0. USER'S BIRTHDAY — highest priority, most personal
        # ══════════════════════════════════════════════════════════
        if user_dob:
            try:
                dob = datetime.fromisoformat(str(user_dob).replace('Z', '+00:00'))
                if month == dob.month and day == dob.day:
                    return (
                        "It's the user's BIRTHDAY today! Make the workout name a birthday celebration "
                        "(e.g., 'Birthday Beast Chest', 'Birthday Blitz Legs', 'Level Up Arms'). "
                        "Keep it fun and empowering — this is THEIR day"
                        + _suffix
                    )
            except Exception as e:
                logger.debug(f"Failed to parse user DOB: {e}")

        # ══════════════════════════════════════════════════════════
        # 1. MOVEABLE HOLIDAYS — year-based lookup tables
        #    These shift every year (lunar / Islamic / computed).
        #    Tables cover 2024-2030; outside that range, skipped.
        # ══════════════════════════════════════════════════════════

        # ── Chinese / Lunar calendar ──
        _chinese_new_year = {
            2024: (2, 10), 2025: (1, 29), 2026: (2, 17), 2027: (2, 6),
            2028: (1, 26), 2029: (2, 13), 2030: (2, 3),
        }
        _dragon_boat = {
            2024: (6, 10), 2025: (5, 31), 2026: (6, 19), 2027: (6, 9),
            2028: (5, 28), 2029: (6, 16), 2030: (6, 5),
        }
        _mid_autumn = {  # Also Chuseok (Korea)
            2024: (9, 17), 2025: (10, 6), 2026: (9, 25), 2027: (9, 15),
            2028: (10, 3), 2029: (9, 22), 2030: (9, 12),
        }

        # ── Indian lunar calendar ──
        _holi = {
            2024: (3, 25), 2025: (3, 14), 2026: (3, 3), 2027: (3, 22),
            2028: (3, 11), 2029: (3, 1), 2030: (3, 20),
        }
        _diwali = {
            2024: (11, 1), 2025: (10, 20), 2026: (11, 8), 2027: (10, 29),
            2028: (10, 17), 2029: (11, 5), 2030: (10, 26),
        }
        _dussehra = {
            2024: (10, 12), 2025: (10, 2), 2026: (10, 20), 2027: (10, 10),
            2028: (9, 29), 2029: (10, 18), 2030: (10, 7),
        }
        _guru_nanak = {
            2024: (11, 15), 2025: (11, 5), 2026: (11, 24), 2027: (11, 14),
            2028: (11, 2), 2029: (11, 21), 2030: (11, 10),
        }
        _ganesh_chaturthi = {
            2024: (9, 7), 2025: (8, 27), 2026: (9, 15), 2027: (9, 4),
            2028: (8, 24), 2029: (9, 12), 2030: (9, 1),
        }
        _raksha_bandhan = {
            2024: (8, 19), 2025: (8, 9), 2026: (8, 28), 2027: (8, 17),
            2028: (8, 6), 2029: (8, 25), 2030: (8, 14),
        }

        # ── Islamic calendar (shifts ~11 days/year) ──
        _eid_al_fitr = {
            2024: (4, 10), 2025: (3, 30), 2026: (3, 20), 2027: (3, 9),
            2028: (2, 27), 2029: (2, 14), 2030: (2, 4),
        }
        _eid_al_adha = {
            2024: (6, 17), 2025: (6, 6), 2026: (5, 27), 2027: (5, 16),
            2028: (5, 4), 2029: (4, 24), 2030: (4, 13),
        }

        # Build moveable list for this year: (month, day, suggestion)
        moveable = []

        if year in _chinese_new_year:
            cm, cd = _chinese_new_year[year]
            moveable.append((cm, cd, "Chinese New Year — dragon/renewal nod (e.g., 'Dragon Year Power Legs')"))
            # Lantern Festival = 15 days after CNY
            lantern = date(year, cm, cd) + timedelta(days=15)
            moveable.append((lantern.month, lantern.day, "Lantern Festival — lantern/light nod (e.g., 'Lantern Blaze Arms')"))

        if year in _dragon_boat:
            dm, dd = _dragon_boat[year]
            moveable.append((dm, dd, "Dragon Boat Festival — dragon paddle nod (e.g., 'Dragon Paddle Back')"))

        if year in _mid_autumn:
            mm, md = _mid_autumn[year]
            moveable.append((mm, md, "Mid-Autumn Festival / Chuseok — harvest/moon nod (e.g., 'Moonrise Harvest Power Chest')"))

        if year in _holi:
            hm, hd = _holi[year]
            moveable.append((hm, hd, "Holi — color/energy nod (e.g., 'Rang Barse Power Shoulders')"))

        if year in _diwali:
            dm, dd = _diwali[year]
            moveable.append((dm, dd, "Diwali — light/festival nod (e.g., 'Deepavali Blaze Chest')"))

        if year in _dussehra:
            dm, dd = _dussehra[year]
            moveable.append((dm, dd, "Dussehra / Vijayadashami — victory/triumph nod (e.g., 'Vijay Warrior Legs')"))
            # Navratri starts 9 days before Dussehra
            nav = date(year, dm, dd) - timedelta(days=9)
            moveable.append((nav.month, nav.day, "Navratri begins — divine energy nod (e.g., 'Shakti Power Legs')"))

        if year in _guru_nanak:
            gm, gd = _guru_nanak[year]
            moveable.append((gm, gd, "Guru Nanak Jayanti — wisdom/strength nod (e.g., 'Guru Power Shoulders')"))

        if year in _ganesh_chaturthi:
            gm, gd = _ganesh_chaturthi[year]
            moveable.append((gm, gd, "Ganesh Chaturthi — remover of obstacles nod (e.g., 'Ganapati Strength Chest')"))

        if year in _raksha_bandhan:
            rm, rd = _raksha_bandhan[year]
            moveable.append((rm, rd, "Raksha Bandhan — bond/protection nod (e.g., 'Raksha Iron Arms')"))

        if year in _eid_al_fitr:
            em, ed = _eid_al_fitr[year]
            moveable.append((em, ed, "Eid al-Fitr — celebration/feast nod (e.g., 'Eid Mubarak Strength Chest')"))

        if year in _eid_al_adha:
            em, ed = _eid_al_adha[year]
            moveable.append((em, ed, "Eid al-Adha — sacrifice/strength nod (e.g., 'Qurbani Power Legs')"))

        # Easter (Western) — anonymous Gregorian algorithm
        def _easter(y: int):
            a = y % 19
            b, c = divmod(y, 100)
            d, e = divmod(b, 4)
            f = (b + 8) // 25
            g = (b - f + 1) // 3
            h = (19 * a + b - d - g + 15) % 30
            i, k = divmod(c, 4)
            l = (32 + 2 * e + 2 * i - h - k) % 7
            m = (a + 11 * h + 22 * l) // 451
            em, ed = divmod(h + l - 7 * m + 114, 31)
            return em, ed + 1

        easter_m, easter_d = _easter(year)
        moveable.append((easter_m, easter_d, "Easter — rebirth/rise nod (e.g., 'Phoenix Rise Chest')"))
        gf = date(year, easter_m, easter_d) - timedelta(days=2)
        moveable.append((gf.month, gf.day, "Good Friday — endurance/sacrifice nod (e.g., 'Crucible Endurance Legs')"))

        # ── US Monday-anchored federal holidays ──
        import calendar

        def _nth_weekday(yr: int, mo: int, weekday: int, n: int) -> int:
            """Return the day-of-month for the nth occurrence of weekday in month."""
            cal_m = calendar.monthcalendar(yr, mo)
            days = [w[weekday] for w in cal_m if w[weekday] != 0]
            return days[n - 1] if len(days) >= n else 0

        def _last_weekday(yr: int, mo: int, weekday: int) -> int:
            """Return the day-of-month for the last occurrence of weekday in month."""
            cal_m = calendar.monthcalendar(yr, mo)
            days = [w[weekday] for w in cal_m if w[weekday] != 0]
            return days[-1] if days else 0

        # MLK Day — 3rd Monday of January
        mlk = _nth_weekday(year, 1, calendar.MONDAY, 3)
        if mlk:
            moveable.append((1, mlk, "Martin Luther King Jr. Day — dream/justice nod (e.g., 'Dream Power Chest')"))

        # Presidents' Day — 3rd Monday of February
        pres = _nth_weekday(year, 2, calendar.MONDAY, 3)
        if pres:
            moveable.append((2, pres, "Presidents' Day — presidential/commander nod (e.g., 'Commander Chest Press')"))

        # Memorial Day — last Monday of May
        memorial = _last_weekday(year, 5, calendar.MONDAY)
        if memorial:
            moveable.append((5, memorial, "Memorial Day — honor/tribute nod (e.g., 'Tribute Iron Back')"))

        # Labor Day — 1st Monday of September
        labor = _nth_weekday(year, 9, calendar.MONDAY, 1)
        if labor:
            moveable.append((9, labor, "Labor Day — grind/work nod (e.g., 'Labor of Iron Legs')"))

        # Columbus Day / Indigenous Peoples' Day — 2nd Monday of October
        columbus = _nth_weekday(year, 10, calendar.MONDAY, 2)
        if columbus:
            moveable.append((10, columbus, "Indigenous Peoples' Day — explorer/warrior nod (e.g., 'Frontier Warrior Shoulders')"))

        # Thanksgiving (US) — 4th Thursday of November
        cal_nov = calendar.monthcalendar(year, 11)
        thursdays = [w[calendar.THURSDAY] for w in cal_nov if w[calendar.THURSDAY] != 0]
        if len(thursdays) >= 4:
            moveable.append((11, thursdays[3], "Thanksgiving — feast/gratitude nod (e.g., 'Grateful Grind Legs')"))

        # ── UK Bank Holidays (Monday-anchored) ──
        # Early May — 1st Monday of May
        early_may = _nth_weekday(year, 5, calendar.MONDAY, 1)
        if early_may:
            moveable.append((5, early_may, "Early May Bank Holiday (UK) — spring energy nod (e.g., 'Spring Bank Power Legs')"))

        # Spring Bank — last Monday of May
        spring_bank = _last_weekday(year, 5, calendar.MONDAY)
        if spring_bank and spring_bank != early_may:
            moveable.append((5, spring_bank, "Spring Bank Holiday (UK) — holiday grind nod (e.g., 'Bank Holiday Beast Arms')"))

        # Summer Bank — last Monday of August
        summer_bank = _last_weekday(year, 8, calendar.MONDAY)
        if summer_bank:
            moveable.append((8, summer_bank, "Summer Bank Holiday (UK) — summer grind nod (e.g., 'Summer Bank Blitz Chest')"))

        # Check moveable holidays (±1 day)
        for hm, hd, suggestion in moveable:
            if _near(hm, hd):
                return f"{suggestion}{_suffix}"

        # ══════════════════════════════════════════════════════════
        # 2. FIXED-DATE HOLIDAYS — same calendar date every year
        # ══════════════════════════════════════════════════════════
        fixed_holidays = {
            # ─── Global / International ───
            (1, 1):   "New Year — fresh-start vibe (e.g., 'Resolution Iron Legs')",
            (3, 8):   "International Women's Day — empowerment nod (e.g., 'Warrior Queen Legs')",
            (5, 1):   "International Workers' Day — grind/labor nod (e.g., 'Iron Worker Shoulders')",
            (6, 21):  "International Yoga Day — flow/balance nod (e.g., 'Zen Warrior Core')",
            (10, 10): "World Mental Health Day — mindfulness nod (e.g., 'Mindful Power Back')",

            # ─── US ───
            (2, 14):  "Valentine's Day — heart/love nod (e.g., 'Heartbreak Chest Press')",
            (3, 17):  "St Patrick's Day — lucky/green nod (e.g., 'Lucky Strike Shoulders')",
            (5, 5):   "Cinco de Mayo — fiesta nod (e.g., 'Fuego Push Day')",
            (6, 19):  "Juneteenth — freedom/strength nod (e.g., 'Liberation Power Back')",
            (7, 4):   "Independence Day — freedom/firework nod (e.g., 'Firework Shoulders')",
            (10, 31): "Halloween — spooky nod (e.g., 'Phantom Deadlift Back')",
            (11, 11): "Veterans Day / Remembrance Day — warrior nod (e.g., 'Battalion Arms')",
            (12, 25): "Christmas — festive nod (e.g., 'Blitzen Power Legs')",
            (12, 31): "New Year's Eve — countdown nod (e.g., 'Midnight Grind Chest')",

            # ─── UK / Europe ───
            (1, 25):  "Burns Night (Scotland) — Scottish warrior nod (e.g., 'Highland Warrior Legs')",
            (2, 1):   "Imbolc / St Brigid's Day (Ireland) — renewal nod (e.g., 'Celtic Spring Chest')",
            (4, 23):  "St George's Day (England) — dragon-slayer nod (e.g., 'Dragon Slayer Chest')",
            (6, 6):   "Sweden's National Day — Nordic strength nod (e.g., 'Viking Forge Arms')",
            (7, 14):  "Bastille Day (France) — revolution nod (e.g., 'Revolution Power Legs')",
            (10, 3):  "German Unity Day — unity/strength nod (e.g., 'Iron Unity Back')",
            (11, 5):  "Guy Fawkes Night (UK) — bonfire/fire nod (e.g., 'Bonfire Blaze Shoulders')",
            (12, 26): "Boxing Day (UK) — boxing nod (e.g., 'Boxing Day Knockout Arms')",

            # ─── Indian (fixed-date only) ───
            (1, 14):  "Makar Sankranti / Pongal — harvest/sun nod (e.g., 'Surya Power Legs')",
            (1, 26):  "Republic Day (India) — patriot/strength nod (e.g., 'Republic Iron Chest')",
            (4, 14):  "Baisakhi / Tamil New Year — harvest/new beginning nod (e.g., 'Baisakhi Strength Legs')",
            (8, 15):  "Independence Day (India) — freedom/pride nod (e.g., 'Azadi Power Back')",
            (10, 2):  "Gandhi Jayanti — discipline/peace nod (e.g., 'Ahimsa Iron Core')",

            # ─── Chinese (fixed-date only) ───
            (10, 1):  "Chinese National Day / Golden Week — golden nod (e.g., 'Golden Dragon Legs')",

            # ─── Korean (fixed-date) ───
            (3, 1):   "Samiljeol / Independence Movement Day (Korea) — patriot nod (e.g., 'Samil Warrior Back')",
            (5, 5):   "Children's Day (Korea) — playful energy nod (e.g., 'Youthful Power Legs')",
            (6, 6):   "Memorial Day (Korea) — honor nod (e.g., 'Hwarang Warrior Chest')",
            (8, 15):  "Gwangbokjeol / Liberation Day (Korea) — freedom nod (e.g., 'Gwangbok Power Arms')",
            (10, 9):  "Hangul Day (Korea) — cultural pride nod (e.g., 'Hangul Strength Shoulders')",

            # ─── Japan ───
            (2, 11):  "National Foundation Day (Japan) — founding nod (e.g., 'Yamato Power Legs')",
            (5, 3):   "Constitution Day / Golden Week (Japan) — golden nod (e.g., 'Samurai Golden Arms')",
            (11, 3):  "Culture Day (Japan) — cultural strength nod (e.g., 'Ronin Spirit Back')",
            (11, 23): "Labor Thanksgiving Day (Japan) — gratitude/work nod (e.g., 'Harvest Grind Chest')",

            # ─── Middle East ───
            (3, 21):  "Nowruz (Persian New Year) — spring renewal nod (e.g., 'Nowruz Rise Legs')",

            # ─── Latin America ───
            (9, 16):  "Mexican Independence Day — grito nod (e.g., 'Grito Power Chest')",
            (11, 2):  "Dia de los Muertos — ancestral strength nod (e.g., 'Ancestral Fire Shoulders')",

            # ─── Africa ───
            (5, 25):  "Africa Day — unity/strength nod (e.g., 'Ubuntu Power Legs')",
            (12, 26): "Kwanzaa begins — unity/heritage nod (e.g., 'Umoja Strength Back')",

            # ─── Health & Fitness Awareness Days ───
            (3, 4):   "World Obesity Day — transformation nod (e.g., 'Transform Power Legs')",
            (4, 6):   "International Day of Sport — athletic nod (e.g., 'Olympian Spirit Chest')",
            (4, 7):   "World Health Day — wellness nod (e.g., 'Vitality Surge Shoulders')",
            (5, 10):  "Global Wellness Day — mind-body nod (e.g., 'Total Wellness Power Core')",
            (6, 1):   "Global Running Day — cardio/endurance nod (e.g., 'Runner's High Legs')",
            (9, 29):  "World Heart Day — cardiovascular nod (e.g., 'Iron Heart Chest')",
            (11, 14): "World Diabetes Day — health/discipline nod (e.g., 'Discipline Iron Back')",

            # ─── Seasonal Milestones ───
            (3, 20):  "Spring Equinox — rebirth/renewal nod (e.g., 'Equinox Rise Legs')",
            (6, 20):  "Summer Solstice — peak energy nod (e.g., 'Solstice Peak Shoulders')",
            (9, 22):  "Autumn Equinox — harvest/balance nod (e.g., 'Equinox Balance Core')",
            (12, 21): "Winter Solstice — dark-to-light nod (e.g., 'Winter Forge Chest')",
        }

        for (hm, hd), suggestion in fixed_holidays.items():
            if _near(hm, hd):
                return f"{suggestion}{_suffix}"

        # ══════════════════════════════════════════════════════════
        # 3. FITNESS LEGENDS BIRTHDAYS — exact day only (no ±1)
        #    Pioneers, champions, and icons of strength & sport.
        # ══════════════════════════════════════════════════════════
        legends = {
            # ─── Bodybuilding / Strength Pioneers ───
            (7, 30):  "Arnold Schwarzenegger's Birthday — The Austrian Oak (e.g., 'Austrian Oak Chest')",
            (4, 2):   "Eugen Sandow's Birthday — Father of Modern Bodybuilding (e.g., 'Sandow Classic Physique')",
            (11, 29): "Joe Weider's Birthday — Father of Bodybuilding (e.g., 'Weider Principle Arms')",
            (6, 7):   "Reg Park's Birthday — Arnold's Idol, 3x Mr Universe (e.g., 'Park Legacy Legs')",
            (10, 12): "Larry Scott's Birthday — First Mr Olympia (e.g., 'Scott Curl Arms')",
            (5, 13):  "Ronnie Coleman's Birthday — 8x Mr Olympia (e.g., 'Yeah Buddy Legs')",
            (11, 11): "Lee Haney's Birthday — 8x Mr Olympia (e.g., 'Haney Era Back')",
            (4, 19):  "Dorian Yates's Birthday — Shadow, 6x Mr Olympia (e.g., 'Blood & Guts Back')",
            (6, 28):  "Frank Zane's Birthday — The Chemist, aesthetics king (e.g., 'Zane Aesthetics Core')",
            (2, 12):  "Franco Columbu's Birthday — Arnold's training partner (e.g., 'Sardinian Strength Chest')",
            (9, 12):  "Chris Bumstead's Birthday — Classic Physique king (e.g., 'CBum Classic Chest')",

            # ─── Fitness Science & Godparents ───
            (9, 26):  "Jack LaLanne's Birthday — Godfather of Fitness (e.g., 'LaLanne Legacy Legs')",
            (8, 5):   "Dr. Thomas DeLorme's Birthday — Father of Progressive Resistance (e.g., 'DeLorme Protocol Legs')",

            # ─── Combat / Martial Arts Icons ───
            (11, 27): "Bruce Lee's Birthday — martial arts legend (e.g., 'Dragon Fist Power Core')",
            (1, 17):  "Muhammad Ali's Birthday — The Greatest (e.g., 'Float Like A Butterfly Shoulders')",
            (3, 8):   "Ip Man's Birthday — Wing Chun grandmaster (e.g., 'Wing Chun Iron Fist Arms')",

            # ─── Global Sports Legends ───
            (8, 21):  "Usain Bolt's Birthday — fastest man ever (e.g., 'Lightning Bolt Legs')",
            (2, 17):  "Michael Jordan's Birthday — His Airness (e.g., 'Air Jordan Legs')",
            (5, 2):   "Dwayne 'The Rock' Johnson's Birthday — People's Champ (e.g., 'Rock Bottom Legs')",
            (9, 26):  "Serena Williams's Birthday — tennis GOAT (e.g., 'Grand Slam Power Arms')",
            (2, 5):   "Cristiano Ronaldo's Birthday — CR7, peak athlete (e.g., 'CR7 Power Legs')",
            (6, 24):  "Lionel Messi's Birthday — GOAT (e.g., 'Messi Magic Legs')",
            (12, 30): "LeBron James's Birthday — King James (e.g., 'King James Power Chest')",
            (8, 23):  "Kobe Bryant's Birthday — Mamba Mentality (e.g., 'Mamba Mentality Legs')",
            (10, 13): "Simone Biles's Birthday — greatest gymnast (e.g., 'Biles Power Core')",
            (8, 8):   "Roger Federer's Birthday — elegance & precision (e.g., 'Federer Precision Arms')",
            (2, 8):   "Mary Kom's Birthday — Magnificent Mary, boxing champion (e.g., 'Magnificent Mary Arms')",

            # ─── Indian Sports Icons ───
            (4, 24):  "Sachin Tendulkar's Birthday — God of Cricket (e.g., 'Master Blaster Arms')",
            (6, 27):  "P.T. Usha's Birthday — Queen of Indian Track (e.g., 'Payyoli Express Legs')",
            (12, 24): "Neeraj Chopra's Birthday — Olympic Gold Javelin (e.g., 'Javelin Gold Shoulders')",
            (11, 20): "Milkha Singh's Birthday — The Flying Sikh (e.g., 'Flying Sikh Sprint Legs')",
            (11, 5):  "Virat Kohli's Birthday — King Kohli (e.g., 'King Kohli Power Chest')",
            (7, 7):   "MS Dhoni's Birthday — Captain Cool (e.g., 'Captain Cool Finish Arms')",

            # ─── Powerlifting & Strongman ───
            (1, 28):  "Ed Coan's Birthday — greatest powerlifter ever (e.g., 'Coan Protocol Legs')",
            (10, 17): "Hafthor Bjornsson's Birthday — The Mountain (e.g., 'Mountain Deadlift Back')",
            (7, 15):  "Eddie Hall's Birthday — 500kg deadlift legend (e.g., 'Beast Mode Deadlift Back')",

            # ─── Modern Fitness Icons ───
            (7, 22):  "CT Fletcher's Birthday — iron addict (e.g., 'It's Still Your Set Arms')",
            (9, 30):  "Ronnie Coleman (Mr Olympia debut anniversary nod) — legendary (e.g., 'Lightweight Baby Legs')",
            (3, 24):  "Rich Froning's Birthday — CrossFit GOAT (e.g., 'Froning Chipper Legs')",
        }

        for (lm, ld), suggestion in legends.items():
            if month == lm and day == ld:
                return f"{suggestion}{_suffix}"

        # ══════════════════════════════════════════════════════════
        # 4. ZODIAC SEASON — lowest priority fallback flavor
        #    Only triggers if no holiday, awareness day, or legend matched.
        #    Adds subtle astrological personality to the workout name.
        # ══════════════════════════════════════════════════════════
        zodiac_themes = [
            ((1, 20), (2, 18),  "Aquarius season — visionary/rebel energy (e.g., 'Aquarius Rebel Chest')"),
            ((2, 19), (3, 20),  "Pisces season — flow/intuition energy (e.g., 'Pisces Flow Legs')"),
            ((3, 21), (4, 19),  "Aries season — fire/warrior energy (e.g., 'Aries Fire Shoulders')"),
            ((4, 20), (5, 20),  "Taurus season — bull/endurance energy (e.g., 'Taurus Bull Legs')"),
            ((5, 21), (6, 20),  "Gemini season — twin/dynamic energy (e.g., 'Gemini Twin Arms')"),
            ((6, 21), (7, 22),  "Cancer season — iron shell/protection energy (e.g., 'Iron Crab Core')"),
            ((7, 23), (8, 22),  "Leo season — lion/king energy (e.g., 'Leo King Chest')"),
            ((8, 23), (9, 22),  "Virgo season — precision/perfection energy (e.g., 'Virgo Precision Back')"),
            ((9, 23), (10, 22), "Libra season — balance/harmony energy (e.g., 'Libra Balance Core')"),
            ((10, 23), (11, 21), "Scorpio season — intensity/dark power energy (e.g., 'Scorpio Sting Legs')"),
            ((11, 22), (12, 21), "Sagittarius season — archer/adventure energy (e.g., 'Archer Fire Shoulders')"),
            ((12, 22), (1, 19),  "Capricorn season — mountain goat/discipline energy (e.g., 'Capricorn Grind Legs')"),
        ]

        for (start_m, start_d), (end_m, end_d), suggestion in zodiac_themes:
            if start_m <= end_m:
                # Normal range (e.g., Mar 21 - Apr 19)
                if (month == start_m and day >= start_d) or \
                   (month == end_m and day <= end_d) or \
                   (start_m < month < end_m):
                    return f"{suggestion}. This is a very subtle suggestion — only use if it fits naturally."
            else:
                # Wraps around year end (Capricorn: Dec 22 - Jan 19)
                if (month == start_m and day >= start_d) or \
                   (month == end_m and day <= end_d) or \
                   (month > start_m or month < end_m):
                    return f"{suggestion}. This is a very subtle suggestion — only use if it fits naturally."

        return None

    def _build_coach_naming_context(
        self,
        coach_style: Optional[str] = None,
        coach_tone: Optional[str] = None,
        workout_date: Optional[str] = None,
        user_dob: Optional[str] = None,
    ) -> str:
        """
        Build dynamic workout naming instructions based on coach personality and date context.

        Each coach style gets unique naming themes that match their personality.
        Holiday/occasion context is also incorporated when relevant.
        """
        from datetime import datetime

        # Coach style influences naming theme - each style has unique flavor
        style_naming = {
            "drill-sergeant": "INTENSE military-style name (e.g., 'Operation Quad Strike', 'Code Red Chest', 'Tactical Arms Assault', 'Delta Force Legs', 'Bravo Company Back')",
            "zen-master": "Peaceful, nature-inspired name (e.g., 'Flowing River Legs', 'Mountain Peak Chest', 'Lotus Core Flow', 'Bamboo Strength Arms', 'Ocean Wave Back')",
            "hype-beast": "HYPED explosive name with energy (e.g., 'INSANE Leg Destroyer', 'CRAZY Arms Pump', 'LEGENDARY Chest Blast', 'UNREAL Core Crusher', 'EPIC Back Attack')",
            "scientist": "Scientific/technical name (e.g., 'Quadriceps Protocol', 'Pectoral Synthesis', 'Deltoid Optimization', 'Gluteal Activation Study', 'Bicep Hypertrophy Lab')",
            "comedian": "Fun punny name (e.g., 'Leg Day or Leg Night', 'Armed and Dangerous', 'Chest Quest Comedy', 'Core Blimey', 'Back to the Future')",
            "old-school": "Classic bodybuilding name (e.g., 'Golden Era Legs', 'Pumping Iron Chest', 'Old School Arms', 'Classic Physique Back', 'Bronze Age Core')",
            "pirate": "Nautical adventure name (e.g., 'Treasure Hunt Legs', 'Cannonball Chest', 'Anchor Arms Ahoy', 'Seven Seas Core', 'Kraken Back Attack')",
            "anime": "Epic anime-style name (e.g., 'PLUS ULTRA Legs', 'Final Form Chest', 'Power Level Arms', 'Spirit Bomb Core', 'Dragon Fist Back')",
            "motivational": "Inspiring power name (e.g., 'Champion Legs Rise', 'Victory Chest Surge', 'Warrior Arms Awakening', 'Unstoppable Core', 'Conqueror Back')",
            "professional": "Clean professional name (e.g., 'Precision Leg Training', 'Elite Chest Session', 'Performance Arms', 'Core Excellence', 'Back Mastery')",
            "friendly": "Warm encouraging name (e.g., 'Happy Legs Day', 'Chest Fest Fun', 'Arms Adventure', 'Core Journey', 'Back Bonanza')",
            "tough-love": "Direct intense name (e.g., 'No Excuses Legs', 'Earn Your Chest', 'Prove It Arms', 'Grind Core', 'Pain Equals Gain Back')",
            "college-coach": "Athletic sports name (e.g., 'Championship Legs', 'Varsity Chest Press', 'All-Star Arms', 'MVP Core', 'Starting Lineup Back')",
        }

        # Tone can add extra flavor
        tone_modifiers = {
            "gen-z": " (no cap, this hits different)",
            "sarcastic": " (with a side of sass)",
            "roast-mode": " (time to get roasted into shape)",
            "pirate": " (arrr matey!)",
            "british": " (quite proper, old sport)",
            "surfer": " (totally gnarly vibes)",
            "anime": " (PLUS ULTRA energy!)",
        }

        # Default naming for styles not in the map
        default_naming = "EXCITING unique name (e.g., 'Thunder Legs', 'Phoenix Push', 'Iron Core', 'Beast Mode Arms', 'Storm Shoulders', 'Venom Back', 'Primal Chest')"

        base_instruction = style_naming.get(coach_style, default_naming)

        # Add tone modifier if applicable
        tone_suffix = tone_modifiers.get(coach_tone, "")

        # Get holiday/occasion context
        holiday_context = self._get_holiday_theme(workout_date, user_dob=user_dob)

        # Also check day of week for non-holiday days
        day_theme = None
        if not holiday_context and workout_date:
            try:
                date = datetime.fromisoformat(workout_date.replace('Z', '+00:00'))
                weekday = date.strftime("%A")
                day_themes = {
                    "Monday": "Monday Motivation",
                    "Wednesday": "Midweek Momentum",
                    "Friday": "Friday Finisher",
                    "Saturday": "Weekend Warrior",
                    "Sunday": "Sunday Strength",
                }
                day_theme = day_themes.get(weekday)
            except Exception as e:
                logger.debug(f"Failed to get day theme: {e}")

        # Build the final instruction
        if holiday_context:
            # Holiday takes priority - extract the theme words
            final_instruction = f"Generate a {base_instruction}{tone_suffix}. {holiday_context}"
        elif day_theme:
            final_instruction = f"Generate a {day_theme}-themed {base_instruction}{tone_suffix}"
        else:
            final_instruction = f"Generate a {base_instruction}{tone_suffix}"

        return f"{final_instruction}. NEVER use bland generic words like Foundation, Basic, Total, Simple, Standard, Beginner, General, Routine, Session, Program."
