"""
Activity / unit / time catalogs for conversational event logging.

These are deterministic lookup tables used by the LangGraph extraction
node (services/langgraph_agents/wellness_agent/log_node.py) and the
`/api/v1/events/log` endpoint to:

1. Resolve user phrasing ("yoga", "yin", "vinyasa") to a canonical
   activity_type ("yoga"), avoiding LLM cost for taxonomy lookup.
2. Compute MET-based calorie estimates per activity.
3. Convert input units (5k, 10000 steps, 32oz, 175lbs, "1 hour") to
   canonical numeric values the DB schema expects.
4. Resolve time-of-day phrasings ("this morning", "tonight",
   "yesterday at 3pm") to occurred_at timestamps.

Owned by feature C0 of the 2026-05-10 Timeline + Conversational Logging
plan. Adding new activities is text-only — never run build_runner.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Dict, List, Optional, Tuple


# ---------------------------------------------------------------------------
# Activity catalog
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class Activity:
    """One canonical activity definition.

    Attributes:
        canonical_id: stable ID stored in DB (`workouts.activity_type`).
        aliases: every phrasing the user might say. Lowercase + matched
            substring-first against the user's message.
        display_name: title-cased name for UI ("Yoga", "Basketball").
        icon: Material icon name for the timeline tile.
        met: MET coefficient for calorie estimation (kcal/kg/hr).
        category: rough grouping for analytics ("strength", "cardio",
            "flexibility", "recovery", "sport").
        default_intensity: pre-fills intensity if user didn't specify.
        needs_followup: list of payload fields the agent should ask for
            when the activity is detected (e.g. strength → body_part).
        logs_as: override the log domain (e.g. "rest" logs as a
            rest_day marker, not a workout).
    """
    canonical_id: str
    aliases: Tuple[str, ...]
    display_name: str
    icon: str
    met: float
    category: str
    default_intensity: str = "medium"
    needs_followup: Tuple[str, ...] = ()
    logs_as: str = "workout"


# Compact, ordered registry. Order matters for substring matching:
# multi-word aliases come BEFORE shorter ones so "lap swim" wins over "swim".
ACTIVITY_REGISTRY: List[Activity] = [
    # --- Strength / weights ---
    # NB: avoid generic "at the gym" alias — collides with "Did 30 min
    # cycling at the gym" which should resolve to cycling. The LLM
    # extractor in log_node handles ambiguous gym-only phrasings.
    Activity("strength",   ("strength training", "lifted weights", "weight training",
                            "weightlifting", "lift", "lifted", "weights", "gym session",
                            "hit the gym", "leg day", "push day", "pull day",
                            "upper day", "lower day", "back day", "chest day", "arm day",
                            "shoulder day", "crushed legs", "crushed chest", "crushed back",
                            "crushed arms", "crushed shoulders", "crossfit", "wod"),
             "Strength", "fitness_center", 5.0, "strength",
             default_intensity="medium",
             needs_followup=("body_part",)),
    Activity("powerlifting", ("powerlifting", "powerlift"),
             "Powerlifting", "fitness_center", 6.0, "strength"),
    Activity("calisthenics",("calisthenics", "bodyweight workout", "bodyweight session"),
             "Calisthenics", "accessibility_new", 4.5, "strength"),
    # --- Cardio (steady-state) ---
    Activity("walk",       ("walking the dog", "walked the dog", "dog walk", "lunch walk",
                            "evening walk", "morning walk", "walking", "walked", "walk",
                            "stroll", "strolled"),
             "Walk", "directions_walk", 3.5, "cardio",
             default_intensity="easy"),
    Activity("run",        ("running", "ran", "run", "jogged", "jogging", "jog", "trail run"),
             "Run", "directions_run", 8.0, "cardio"),
    Activity("hike",       ("hiking", "hiked", "hike", "trail walk", "trekking"),
             "Hike", "terrain", 6.0, "cardio"),
    Activity("cycling",    ("road biking", "mountain biking", "stationary bike",
                            "spin class", "spinning", "cycling", "cycled", "cycle",
                            "biking", "bike ride", "bike", "biked"),
             "Cycling", "directions_bike", 7.5, "cardio"),
    Activity("swim",       ("lap swim", "swim practice", "open water swim", "pool swim",
                            "swimming", "swam", "swim"),
             "Swim", "pool", 6.0, "cardio"),
    Activity("rowing",     ("rowing erg", "indoor rowing", "ergometer", "rowed", "rowing", "row"),
             "Rowing", "rowing", 7.0, "cardio"),
    Activity("elliptical", ("cross trainer", "elliptical"),
             "Elliptical", "fitness_center", 5.0, "cardio"),
    Activity("stairmaster",("stair climber", "stair climbing", "stairmaster", "stairs"),
             "StairMaster", "stairs", 8.8, "cardio"),
    # --- HIIT / interval ---
    Activity("hiit",       ("hiit session", "hiit class", "hiit", "tabata", "interval training",
                            "circuits", "circuit training", "conditioning",
                            "7-minute workout", "7 minute workout", "minute workout"),
             "HIIT", "bolt", 9.0, "cardio",
             default_intensity="hard"),
    Activity("plyometrics",("plyo", "plyometrics", "plyometric"),
             "Plyometrics", "bolt", 8.0, "cardio"),
    # --- Flexibility / mind-body ---
    Activity("yoga",       ("vinyasa", "hatha yoga", "power yoga", "yin yoga", "restorative yoga",
                            "hot yoga", "yoga class", "yoga", "yin"),
             "Yoga", "self_improvement", 2.5, "flexibility",
             default_intensity="easy"),
    Activity("pilates",    ("reformer pilates", "mat pilates", "pilates"),
             "Pilates", "self_improvement", 3.0, "flexibility"),
    Activity("barre",      ("barre class", "barre"),
             "Barre", "self_improvement", 4.0, "flexibility"),
    Activity("stretching", ("foam roll", "foam rolling", "stretched", "stretching", "stretch",
                            "mobility work", "mobility"),
             "Stretching", "accessibility", 2.3, "recovery",
             default_intensity="easy"),
    Activity("meditation", ("meditation", "meditated", "meditate"),
             "Meditation", "spa", 1.3, "recovery",
             default_intensity="easy"),
    # --- Sports ---
    Activity("basketball", ("pickup basketball", "basketball game", "bball",
                            "hoops", "basketball"),
             "Basketball", "sports_basketball", 6.5, "sport"),
    Activity("soccer",     ("soccer game", "soccer scrimmage", "futbol", "soccer"),
             "Soccer", "sports_soccer", 7.0, "sport"),
    Activity("football",   ("flag football", "football"),
             "Football", "sports_football", 8.0, "sport"),
    Activity("tennis",     ("tennis match", "tennis"),
             "Tennis", "sports_tennis", 7.3, "sport"),
    Activity("pickleball", ("pickleball",),
             "Pickleball", "sports_tennis", 5.0, "sport"),
    Activity("volleyball", ("beach volleyball", "volleyball"),
             "Volleyball", "sports_volleyball", 4.0, "sport"),
    Activity("squash",     ("racquetball", "squash"),
             "Squash", "sports_tennis", 7.3, "sport"),
    Activity("badminton",  ("badminton",),
             "Badminton", "sports_tennis", 5.5, "sport"),
    Activity("golf",       ("golf",),
             "Golf", "sports_golf", 4.8, "sport"),
    Activity("frisbee",    ("ultimate frisbee", "disc golf", "frisbee"),
             "Frisbee", "sports_handball", 8.0, "sport"),
    # --- Combat ---
    Activity("martial_arts",("brazilian jiu jitsu", "jiu jitsu", "bjj", "muay thai",
                             "kickboxing", "boxing", "mma", "judo", "karate", "taekwondo",
                             "martial arts"),
             "Martial Arts", "sports_mma", 7.5, "sport",
             default_intensity="hard"),
    # --- Outdoor / endurance ---
    Activity("climbing",   ("rock climbing", "bouldering", "climbing", "climbed", "climb"),
             "Climbing", "terrain", 8.0, "sport"),
    Activity("surfing",    ("surfing", "surfed", "surf"),
             "Surfing", "surfing", 6.0, "sport"),
    Activity("kayak",      ("kayaking", "kayaked", "kayak"),
             "Kayak", "rowing", 5.0, "cardio"),
    Activity("paddle",     ("stand up paddle", "paddleboarding", "sup", "paddling", "paddle"),
             "Paddleboard", "rowing", 6.0, "cardio"),
    Activity("skiing",     ("downhill skiing", "cross country skiing", "skiing", "ski"),
             "Skiing", "downhill_skiing", 7.0, "sport"),
    Activity("snowboard",  ("snowboarding", "snowboard"),
             "Snowboard", "snowboarding", 5.3, "sport"),
    Activity("dance",      ("dance class", "zumba", "salsa class", "dancing", "dance"),
             "Dance", "music_note", 5.5, "cardio"),
    # --- Special states ---
    Activity("rest",       ("rest day", "off day", "recovery day", "took a rest", "rest"),
             "Rest day", "bedtime", 0.0, "recovery",
             logs_as="rest_day"),
    Activity("other",      (),
             "Other", "fitness_center", 4.0, "other"),
]


def _build_alias_index() -> List[Tuple[str, Activity]]:
    """Flatten the registry into (alias, activity) pairs sorted by alias
    length DESC so multi-word aliases match before shorter substrings.
    Built once at import time."""
    pairs: List[Tuple[str, Activity]] = []
    for activity in ACTIVITY_REGISTRY:
        for alias in activity.aliases:
            pairs.append((alias.lower(), activity))
    pairs.sort(key=lambda pair: len(pair[0]), reverse=True)
    return pairs


_ALIAS_INDEX = _build_alias_index()


import re as _re


def resolve_activity(text: str) -> Optional[Activity]:
    """Match a user-supplied phrase to a canonical activity.

    Strategy: case-insensitive WORD-BOUNDARY search ordered by alias
    length (multi-word first). Substring matching would mis-route
    "drank" → "ran" and "stretching" → wrong category, so we use
    `\\b<alias>\\b` for short single-word aliases. Multi-word aliases
    keep substring behavior since they're already specific enough.
    Returns None when nothing matches — caller should fall back to the
    LLM extractor or to ``other``.
    """
    if not text:
        return None
    needle = text.lower().strip()
    for alias, activity in _ALIAS_INDEX:
        if " " in alias:
            # Multi-word alias: substring match is safe and faster.
            if alias in needle:
                return activity
        else:
            # Single-word alias: require word boundaries so "ran" doesn't
            # match "drank" / "frantic", "swim" doesn't match "swimsuit", etc.
            pattern = rf"\b{_re.escape(alias)}\b"
            if _re.search(pattern, needle):
                return activity
    return None


def get_activity(canonical_id: str) -> Optional[Activity]:
    """Lookup by canonical_id (stored in DB)."""
    for activity in ACTIVITY_REGISTRY:
        if activity.canonical_id == canonical_id:
            return activity
    return None


# ---------------------------------------------------------------------------
# Unit conversions
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class Unit:
    """One unit definition with category + conversion to canonical."""
    name: str
    category: str
    aliases: Tuple[str, ...]
    to_canonical: Callable[[float], float]
    canonical_unit: str


UNITS: List[Unit] = [
    # Time → minutes
    Unit("minutes", "time", ("minutes", "minute", "min", "mins"),
         lambda v: v, "min"),
    Unit("hours",   "time", ("hours", "hour", "hr", "hrs", "h"),
         lambda v: v * 60, "min"),
    Unit("seconds", "time", ("seconds", "second", "sec", "secs"),
         lambda v: v / 60.0, "min"),
    # Distance → km
    Unit("km",      "distance", ("kilometers", "kilometer", "kms", "km", "k"),
         lambda v: v, "km"),
    Unit("miles",   "distance", ("miles", "mile", "mi"),
         lambda v: v * 1.60934, "km"),
    Unit("meters",  "distance", ("meters", "meter", "m"),
         lambda v: v / 1000.0, "km"),
    # Volume → ml (water log)
    Unit("ml",      "volume", ("ml", "milliliters", "milliliter"),
         lambda v: v, "ml"),
    Unit("oz",      "volume", ("oz", "ounces", "ounce", "fl oz"),
         lambda v: v * 29.5735, "ml"),
    Unit("cups",    "volume", ("cups", "cup"),
         lambda v: v * 240.0, "ml"),
    Unit("liters",  "volume", ("liters", "liter", "litre", "litres", "l"),
         lambda v: v * 1000.0, "ml"),
    Unit("gallon",  "volume", ("gallons", "gallon", "gal"),
         lambda v: v * 3785.41, "ml"),
    Unit("glasses", "volume", ("glasses", "glass"),
         lambda v: v * 240.0, "ml"),
    # Weight → kg (body weight log)
    Unit("kg",      "weight", ("kilograms", "kilo", "kilos", "kg"),
         lambda v: v, "kg"),
    Unit("lbs",     "weight", ("pounds", "pound", "lbs", "lb"),
         lambda v: v * 0.453592, "kg"),
    # Steps → minutes (rough estimate, ~110 steps/min walking)
    Unit("steps",   "steps", ("steps", "step"),
         lambda v: v, "steps"),
]


_UNIT_INDEX: Dict[str, Unit] = {}
for u in UNITS:
    for alias in u.aliases:
        _UNIT_INDEX[alias.lower()] = u


def resolve_unit(unit_str: str) -> Optional[Unit]:
    """Parse a unit string ("min", "hours", "lbs", "oz") into a Unit."""
    if not unit_str:
        return None
    return _UNIT_INDEX.get(unit_str.lower().strip())


def steps_to_walking_minutes(steps: int) -> int:
    """Estimate walking duration from step count.

    Using the well-known cadence of ~110 steps/min for a casual walk.
    Round to nearest minute.
    """
    if steps <= 0:
        return 0
    return max(1, round(steps / 110.0))


def estimate_calories(met: float, weight_kg: float, duration_minutes: float) -> int:
    """Return rounded kcal burned via the standard MET formula:
    kcal = MET × weight(kg) × duration(hr).
    """
    if met <= 0 or weight_kg <= 0 or duration_minutes <= 0:
        return 0
    return round(met * weight_kg * (duration_minutes / 60.0))


# ---------------------------------------------------------------------------
# Intensity adjustment (X4 — "hot yoga" vs "yoga", "intense hike")
# ---------------------------------------------------------------------------

# Multiplier applied to the catalog MET when the user signals an intensity.
# "medium" is the catalog baseline. Conservative band — never more than ±40%.
INTENSITY_MET_MULTIPLIER: Dict[str, float] = {
    "easy": 0.80,
    "light": 0.80,
    "medium": 1.00,
    "moderate": 1.00,
    "hard": 1.30,
    "intense": 1.35,
    "vigorous": 1.35,
}


def intensity_adjusted_met(base_met: float, intensity: Optional[str]) -> float:
    """Scale a catalog MET by a user-supplied intensity word.

    "hot yoga" / "intense hike" burn meaningfully more than the catalog
    baseline; "easy walk" burns less. Unknown words → baseline (1.0).
    """
    if not intensity:
        return base_met
    return base_met * INTENSITY_MET_MULTIPLIER.get(intensity.lower().strip(), 1.0)



# ---------------------------------------------------------------------------
# Time-of-day / day hints
# ---------------------------------------------------------------------------

# Map free-text occurred_at hints to (hour_start, hour_end) windows in
# user-local time. The agent picks the midpoint when a precise hour
# isn't supplied.
TIME_OF_DAY_HINTS: Dict[str, Tuple[int, int]] = {
    "early morning":  (5, 8),
    "this morning":   (5, 11),
    "morning":        (5, 11),
    "noon":           (11, 13),
    "lunch":          (11, 14),
    "lunchtime":      (11, 14),
    "midday":         (11, 14),
    "afternoon":      (12, 17),
    "this afternoon": (12, 17),
    "this evening":   (17, 21),
    "evening":        (17, 21),
    "tonight":        (19, 23),
    "tonite":         (19, 23),
    "last night":     (19, 23),
    "earlier today":  (0, 23),
    "earlier":        (0, 23),
}

# Day-relative hints — value is days_offset from user_today.
# "monday" / "tuesday" etc resolve to the most-recent past occurrence.
DAY_HINTS: Dict[str, int] = {
    "today":           0,
    "this morning":    0,
    "this afternoon":  0,
    "this evening":    0,
    "tonight":         0,
    "earlier today":   0,
    "yesterday":      -1,
    "yesterday morning": -1,
    "yesterday afternoon": -1,
    "yesterday evening": -1,
    "last night":     -1,
    "the day before yesterday": -2,
}


def resolve_time_of_day(text: str) -> Optional[Tuple[int, int]]:
    """Match a hint like 'this morning' to an (h_start, h_end) window."""
    if not text:
        return None
    needle = text.lower().strip()
    # Match longest hint first to avoid "this morning" being shadowed by "morning"
    for hint in sorted(TIME_OF_DAY_HINTS.keys(), key=len, reverse=True):
        if hint in needle:
            return TIME_OF_DAY_HINTS[hint]
    return None


def resolve_day_offset(text: str) -> int:
    """Return days_offset from today for hints like 'yesterday' / 'today'.

    Defaults to 0 (today) when nothing matches.
    """
    if not text:
        return 0
    needle = text.lower().strip()
    for hint in sorted(DAY_HINTS.keys(), key=len, reverse=True):
        if hint in needle:
            return DAY_HINTS[hint]
    return 0
