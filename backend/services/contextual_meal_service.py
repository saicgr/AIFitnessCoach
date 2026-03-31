"""
Contextual Meal Reference Service

Detects when users reference past meals ("leftovers", "same thing", "my usual",
"last night's dinner") and resolves them against actual food log history.

Detection uses fast keyword matching (<1ms, no AI calls).
Resolution queries the user's food_logs table.
"""

import re
import logging
from datetime import date, timedelta
from enum import Enum
from typing import Optional, List, Dict, Any, Tuple

logger = logging.getLogger(__name__)


# ═══════════════════════════════════════════════════════════════════
# Reference Type Classification
# ═══════════════════════════════════════════════════════════════════

class ReferenceType(str, Enum):
    TEMPORAL = "temporal"           # "yesterday's lunch", "last night"
    REPEAT = "repeat"               # "same thing", "again"
    USUAL = "usual"                 # "my usual", "the usual"
    KEYWORD_SEARCH = "keyword"      # "the chicken from last week"
    AMBIGUOUS = "ambiguous"         # "leftover chicken" — try history, fallback to analysis


class ContextualRef:
    """Parsed contextual reference."""
    ref_type: ReferenceType = ReferenceType.TEMPORAL
    target_date: Optional[date] = None
    meal_type: Optional[str] = None        # breakfast, lunch, dinner, snack
    keyword: Optional[str] = None          # food keyword for search
    modifier: Optional[float] = None       # portion multiplier (0.5 = half, 2.0 = double)
    modifier_exclude: Optional[str] = None # "skip the rice"
    original_text: str = ""

    def __init__(self):
        pass


class ResolvedMeal:
    """Result of resolving a contextual reference."""
    def __init__(
        self,
        found: bool,
        items: Optional[List[Dict]] = None,
        source_label: Optional[str] = None,
        source_date: Optional[str] = None,
        source_meal_type: Optional[str] = None,
        message: Optional[str] = None,
        suggestion_logs: Optional[List[Dict]] = None,
        total_calories: int = 0,
        protein_g: float = 0.0,
        carbs_g: float = 0.0,
        fat_g: float = 0.0,
        fiber_g: float = 0.0,
    ):
        self.found = found
        self.items = items or []
        self.source_label = source_label
        self.source_date = source_date
        self.source_meal_type = source_meal_type
        self.message = message
        self.suggestion_logs = suggestion_logs
        self.total_calories = total_calories
        self.protein_g = protein_g
        self.carbs_g = carbs_g
        self.fat_g = fat_g
        self.fiber_g = fiber_g


# ═══════════════════════════════════════════════════════════════════
# Word Sets
# ═══════════════════════════════════════════════════════════════════

# --- Reference words: signals user is referencing a past meal ---

_LEFTOVER_WORDS = {
    "leftover", "leftovers", "left over", "left-over", "left-overs",
    "remaining", "remains", "rest of", "the rest",
    "what was left", "what's left", "whats left",
    "unfinished", "didn't finish", "not finished",
}

_REPEAT_WORDS = {
    "same", "same thing", "same meal", "same food", "same stuff", "same again",
    "same as", "same as before", "same as last", "same as earlier",
    "repeat", "repeated", "redo",
    "again", "once more", "one more time",
    "copy", "duplicate", "ditto",
    "that again", "like before", "like last time", "like earlier",
    "what i had", "what i ate", "what i eaten",
    "what i've had", "what i've eaten",
    "what we had", "what we ate",
    "had before", "ate before", "eaten before",
}

_USUAL_WORDS = {
    "usual", "my usual", "the usual", "as usual",
    "regular", "my regular", "the regular",
    "go-to", "go to", "goto", "my go-to", "my goto",
    "everyday", "my everyday", "daily", "my daily",
    "always have", "always eat", "always get", "always order",
    "usually have", "usually eat", "usually get", "usually order",
    "normal", "my normal", "the normal",
    "standard", "my standard",
    "typical", "my typical",
    "routine", "my routine",
}

_REHEATED_WORDS = {
    "reheated", "reheat", "re-heated", "re-heat",
    "warmed up", "warm up", "warming up", "warmed",
    "heated up", "heat up", "heating up", "heated",
    "microwaved", "microwave", "nuked",
    "toasted up", "defrosted",
}

_FINISHED_WORDS = {
    "finished off", "finished up",
    "polished off", "cleaned up", "cleaned out",
    "ate the rest", "had the rest", "eating the rest",
    "doggy bag", "takeaway box", "take home",
    "from the fridge", "in the fridge", "fridge food",
}

_MEALPREP_WORDS = {
    "meal prep", "meal prepped", "prepped",
    "batch cook", "batch cooked",
    "made earlier", "cooked earlier", "prepared earlier",
    "made ahead", "cooked ahead", "precooked", "pre-cooked",
    "packed from", "brought from",
}

_COMPARISON_WORDS = {
    "just like", "like yesterday", "similar to",
    "the one from", "that thing from", "that dish from",
    "what i made", "what i cooked", "what i ordered", "what i got",
}

# Combine all reference word sets
_ALL_REFERENCE_WORDS = (
    _LEFTOVER_WORDS | _REPEAT_WORDS | _USUAL_WORDS |
    _REHEATED_WORDS | _FINISHED_WORDS | _MEALPREP_WORDS |
    _COMPARISON_WORDS
)

# Sorted by length descending so longer phrases match first
_REFERENCE_PHRASES = sorted(_ALL_REFERENCE_WORDS, key=len, reverse=True)

# --- Time words ---

_TIME_WORDS_EXACT = {
    "yesterday", "yesterdays", "yesterday's", "yest", "yesturday",
    "last night", "lastnight", "last nite", "prev night", "previous night",
    "night before", "the day before", "day before today",
    "day before yesterday",
    "today", "today's",
    "earlier", "earlier today",
    "this morning", "this afternoon", "this evening",
    "just now", "just had", "a while ago", "few hours ago",
    "before this", "prior to this",
    "last week", "past week", "previous week", "a week ago",
    "last weekend", "this past weekend", "over the weekend",
    "other day", "the other day", "other night", "the other night",
}

_DAY_NAMES = {
    "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
    "mon", "tue", "tues", "wed", "thu", "thur", "thurs", "fri", "sat", "sun",
}

# Sorted by length descending
_TIME_PHRASES = sorted(_TIME_WORDS_EXACT, key=len, reverse=True)

# --- Meal words ---
_MEAL_WORDS = {
    "breakfast", "brekkie", "bfast",
    "lunch", "luncheon", "midday",
    "dinner", "supper", "dins", "evening meal",
    "snack", "snacks", "munchies",
    "brunch",
    "meal", "food",
}

_MEAL_NORMALIZE = {
    "breakfast": "breakfast", "brekkie": "breakfast", "bfast": "breakfast",
    "lunch": "lunch", "luncheon": "lunch", "midday": "lunch",
    "dinner": "dinner", "supper": "dinner", "dins": "dinner", "evening meal": "dinner",
    "snack": "snack", "snacks": "snack", "munchies": "snack",
    "brunch": "breakfast",
    "meal": None, "food": None,
}

# --- Modifier words ---
_MODIFIER_MAP = {
    "half": 0.5, "quarter": 0.25, "third": 0.33,
    "double": 2.0, "triple": 3.0, "twice": 2.0, "thrice": 3.0,
    "2x": 2.0, "3x": 3.0,
}

_EXCLUDE_PHRASES = [
    "without the", "without", "minus the", "minus",
    "no ", "skip the", "skip", "drop the", "hold the",
    "except the", "except", "but no", "but not", "but without",
    "leave out", "take out", "remove the", "remove",
]

# --- Compound food exclusion list ---
_COMPOUND_FOOD_EXCLUSIONS = {
    "sunday roast", "breakfast burrito", "breakfast sausage", "breakfast wrap",
    "breakfast sandwich", "breakfast bowl", "breakfast muffin", "breakfast bar",
    "dinner roll", "dinner mints", "dinner sausage",
    "morning glory", "morning star",
    "overnight oats", "overnight chia",
    "regular fries", "regular coffee", "regular coke", "regular size",
    "regular menu",
    "double cheeseburger", "double whopper", "double down", "double stuff",
    "double shot", "double espresso",
    "triple whopper", "triple stack",
    "half and half", "half-and-half", "half pound",
    "day old bread",
    "daily bread", "daily special", "daily deal",
    "last bite", "last drop", "last piece",
    "night shift",
    "power lunch", "lunch box", "lunch meat",
    "dinner for one", "dinner for two",
    "again again",
}

# --- Intent negation phrases ---
_NEGATION_PHRASES = [
    "i want", "i'd like", "i would like", "give me", "order",
    "logging", "log this", "tracking", "adding", "i'll have",
    "can i have", "make me", "prepare",
]

# --- Regex for weight/quantity ---
_WEIGHT_QTY_RE = re.compile(
    r'\d+\s*(?:g|oz|ml|cups?|tbsp|tsp|kg|lbs?|pieces?|pcs?|slices?|servings?|ounces?|grams?)\b',
    re.IGNORECASE,
)

# --- Regex for N days ago ---
_N_DAYS_AGO_RE = re.compile(
    r'(\d+|two|three|four|five|few|couple)\s*(?:days?|nights?)\s*ago',
    re.IGNORECASE,
)

_WORD_TO_NUM = {
    "two": 2, "three": 3, "four": 4, "five": 5,
    "few": 3, "couple": 2,
}

# Day-of-week mapping
_DOW_MAP = {
    "monday": 0, "mon": 0,
    "tuesday": 1, "tue": 1, "tues": 1,
    "wednesday": 2, "wed": 2,
    "thursday": 3, "thu": 3, "thur": 3, "thurs": 3,
    "friday": 4, "fri": 4,
    "saturday": 5, "sat": 5,
    "sunday": 6, "sun": 6,
}


# ═══════════════════════════════════════════════════════════════════
# Detection
# ═══════════════════════════════════════════════════════════════════

def _find_matches(text: str, phrases: list) -> List[str]:
    """Find all matching phrases in text, longest match first."""
    found = []
    remaining = text
    for phrase in phrases:  # already sorted by length desc
        if phrase in remaining:
            found.append(phrase)
            # Remove matched phrase to avoid double-counting
            remaining = remaining.replace(phrase, " ", 1)
    return found


def _find_day_names(text: str) -> List[str]:
    """Find day-of-week names in text."""
    found = []
    words = text.split()
    for w in words:
        if w in _DAY_NAMES:
            found.append(w)
    return found


def detect_contextual_reference(
    text: str,
    current_meal_type: Optional[str] = None,
) -> Optional[ContextualRef]:
    """
    Detect if user input is a contextual meal reference.

    Returns ContextualRef if detected, None if it's a regular food description.
    """
    original = text.strip()
    lower = original.lower()

    # Step 0: Too short
    if len(lower) < 3:
        return None

    # Step 1: Compound food exclusion
    for compound in _COMPOUND_FOOD_EXCLUSIONS:
        if compound in lower:
            return None

    # Step 2: Intent negation — user is describing NEW food
    for neg in _NEGATION_PHRASES:
        if neg in lower:
            return None

    # Step 3: Weight/quantity indicators → food description
    if _WEIGHT_QTY_RE.search(lower):
        return None

    # Step 4: Comma-separated with 2+ food segments → food description
    if "," in lower:
        segments = [s.strip() for s in lower.split(",") if s.strip()]
        if len(segments) >= 2:
            # Check if any segment has a reference word — if so, might be contextual
            has_ref_in_segment = any(
                any(ref in seg for ref in ["leftover", "same", "repeat", "usual", "yesterday", "last night"])
                for seg in segments
            )
            if not has_ref_in_segment:
                return None

    # Step 5: Find reference and time words
    found_refs = _find_matches(lower, _REFERENCE_PHRASES)
    found_times = _find_matches(lower, _TIME_PHRASES)
    found_days = _find_day_names(lower)
    found_meals = _find_matches(lower, sorted(_MEAL_WORDS, key=len, reverse=True))

    # Combine time signals
    all_time = found_times + found_days

    # Must have at least one signal
    if not found_refs and not all_time:
        return None

    # Step 6: "again" at start followed by comma/period is filler, not reference
    if found_refs == ["again"] and re.match(r'^again\s*[,.]', lower):
        return None

    # Step 7: Bare "regular" without "my"/"the" is likely a size modifier
    if found_refs == ["regular"] and "my regular" not in lower and "the regular" not in lower:
        return None

    # Step 8: Bare meal word with time word but lots of other food words
    #   "yesterday I had chicken biryani with raita and naan" — too many food words
    #   vs "yesterday's lunch" — concise reference
    stripped = lower
    for ref in found_refs:
        stripped = stripped.replace(ref, " ")
    for t in all_time:
        stripped = stripped.replace(t, " ")
    for m in found_meals:
        stripped = stripped.replace(m, " ")
    # Remove common stop words and modifier words
    _stop_words = {"the", "a", "an", "of", "from", "my", "i", "and", "with", "but", "s", "'s", "night", "last"}
    _modifier_stop = set(_MODIFIER_MAP.keys()) | {"without", "minus", "skip", "except", "hold", "drop", "leave", "take", "remove"}
    for stop in _stop_words:
        stripped = re.sub(rf'\b{re.escape(stop)}\b', ' ', stripped)
    remaining_words = [w for w in stripped.split() if len(w) >= 3 and w not in _modifier_stop]

    # If 4+ remaining meaningful words and no explicit reference word, probably food description
    if len(remaining_words) >= 4 and not found_refs:
        return None

    # Step 9: Extract keyword from remaining words
    keyword = " ".join(remaining_words).strip() if remaining_words else None
    if keyword and len(keyword) < 3:
        keyword = None

    # Step 10: Extract modifier
    modifier = None
    for mod_word, mod_val in _MODIFIER_MAP.items():
        if mod_word in lower:
            modifier = mod_val
            break

    # Extract exclusion modifier
    modifier_exclude = None
    for exc in _EXCLUDE_PHRASES:
        if exc in lower:
            idx = lower.index(exc) + len(exc)
            rest = lower[idx:].strip()
            # Take the next few words as the exclusion target
            exc_words = rest.split()[:3]
            if exc_words:
                modifier_exclude = " ".join(exc_words)
            break

    # Step 11: Parse target date
    target_date = _parse_date(all_time)

    # Step 12: Parse meal type
    meal_type = None
    for m in found_meals:
        normalized = _MEAL_NORMALIZE.get(m)
        if normalized:
            meal_type = normalized
            break

    # Infer meal type from time words
    if not meal_type:
        time_text = " ".join(all_time)
        if "morning" in time_text or "breakfast" in lower:
            meal_type = "breakfast"
        elif "night" in time_text or "evening" in time_text or "dinner" in lower or "supper" in lower:
            meal_type = "dinner"

    # Step 13: Classify reference type
    ref_type = _classify_type(found_refs, all_time, keyword)

    # Step 14: If ambiguous (has keyword but reference type is just temporal from leftovers)
    # Mark as ambiguous so resolver can try history first, fallback to analysis
    if keyword and ref_type == ReferenceType.TEMPORAL and not all_time:
        ref_type = ReferenceType.AMBIGUOUS

    # Build result
    ref = ContextualRef()
    ref.ref_type = ref_type
    ref.target_date = target_date
    ref.meal_type = meal_type or current_meal_type
    ref.keyword = keyword
    ref.modifier = modifier
    ref.modifier_exclude = modifier_exclude
    ref.original_text = original
    return ref


def _classify_type(
    refs: List[str], times: List[str], keyword: Optional[str],
) -> ReferenceType:
    """Classify the reference type from detected words."""
    ref_set = set(refs)

    # Explicit "usual/regular/go-to" words
    if ref_set & _USUAL_WORDS:
        return ReferenceType.USUAL

    # Explicit "same/repeat/again" words WITHOUT time
    if ref_set & _REPEAT_WORDS and not times:
        return ReferenceType.REPEAT

    # Has time words
    if times:
        if keyword and not (ref_set & (_LEFTOVER_WORDS | _REHEATED_WORDS | _FINISHED_WORDS)):
            return ReferenceType.KEYWORD_SEARCH
        return ReferenceType.TEMPORAL

    # Leftover/reheated/finished words default to yesterday
    if ref_set & (_LEFTOVER_WORDS | _REHEATED_WORDS | _FINISHED_WORDS | _MEALPREP_WORDS):
        return ReferenceType.TEMPORAL

    # Comparison words with keyword
    if ref_set & _COMPARISON_WORDS and keyword:
        return ReferenceType.KEYWORD_SEARCH

    # Same/repeat with time = temporal
    if ref_set & _REPEAT_WORDS and times:
        return ReferenceType.TEMPORAL

    return ReferenceType.REPEAT  # Safest default


def _parse_date(time_words: List[str]) -> Optional[date]:
    """Parse target date from time words."""
    today = date.today()

    if not time_words:
        return today - timedelta(days=1)  # Default: yesterday

    text = " ".join(time_words).lower()

    # Direct matches
    if any(w in text for w in ("yesterday", "yest", "yesturday", "last night", "lastnight",
                                "last nite", "prev night", "previous night", "night before")):
        return today - timedelta(days=1)

    if any(w in text for w in ("today", "this morning", "this afternoon", "this evening",
                                "earlier", "just now", "just had", "few hours ago")):
        return today

    if "day before yesterday" in text:
        return today - timedelta(days=2)

    # N days ago
    m = _N_DAYS_AGO_RE.search(text)
    if m:
        val = m.group(1)
        n = _WORD_TO_NUM.get(val) or int(val)
        return today - timedelta(days=n)

    # "other day" / "the other day" → 2-3 days back
    if "other day" in text or "other night" in text:
        return today - timedelta(days=2)

    # "last week" / "past week"
    if any(w in text for w in ("last week", "past week", "previous week", "a week ago")):
        return today - timedelta(days=7)

    # "weekend"
    if "weekend" in text:
        days_since_sat = (today.weekday() - 5) % 7
        if days_since_sat == 0 and today.weekday() != 5:
            days_since_sat = 7
        return today - timedelta(days=days_since_sat)

    # Day of week
    for word in text.split():
        if word in _DOW_MAP:
            dow = _DOW_MAP[word]
            days_back = (today.weekday() - dow) % 7
            if days_back == 0:
                days_back = 7  # "monday" on a monday = LAST monday
            return today - timedelta(days=days_back)

    return today - timedelta(days=1)  # Fallback: yesterday


# ═══════════════════════════════════════════════════════════════════
# Resolution
# ═══════════════════════════════════════════════════════════════════

async def resolve_contextual_reference(
    ref: ContextualRef,
    user_id: str,
    nutrition_db,
) -> ResolvedMeal:
    """
    Resolve a contextual reference against the user's food log history.

    Args:
        ref: Parsed contextual reference
        user_id: User ID
        nutrition_db: NutritionDB instance (sync methods, run in executor)
    """
    import asyncio
    loop = asyncio.get_event_loop()

    try:
        if ref.ref_type == ReferenceType.TEMPORAL or ref.ref_type == ReferenceType.AMBIGUOUS:
            return await _resolve_temporal(ref, user_id, nutrition_db, loop)

        elif ref.ref_type == ReferenceType.REPEAT:
            return await _resolve_repeat(ref, user_id, nutrition_db, loop)

        elif ref.ref_type == ReferenceType.USUAL:
            return await _resolve_usual(ref, user_id, nutrition_db, loop)

        elif ref.ref_type == ReferenceType.KEYWORD_SEARCH:
            return await _resolve_keyword(ref, user_id, nutrition_db, loop)

        else:
            return ResolvedMeal(found=False, message="Could not understand the reference.")

    except Exception as e:
        logger.error(f"[ContextualMeal] Resolution error: {e}")
        return ResolvedMeal(found=False, message="Something went wrong looking up your meal history.")


async def _resolve_temporal(ref, user_id, db, loop) -> ResolvedMeal:
    """Resolve temporal references: "yesterday's lunch", "leftovers", etc."""
    target = ref.target_date or (date.today() - timedelta(days=1))
    target_str = target.isoformat()
    # Query for the full day, add 1 day for end range
    end_str = (target + timedelta(days=1)).isoformat()

    logs = await loop.run_in_executor(
        None, lambda: db.list_food_logs(
            user_id,
            from_date=target_str,
            to_date=end_str,
            meal_type=ref.meal_type if ref.meal_type else None,
            limit=10,
        )
    )

    # Filter by keyword if present
    if ref.keyword and logs:
        filtered = [l for l in logs if _keyword_in_log(ref.keyword, l)]
        if filtered:
            logs = filtered
        elif ref.ref_type == ReferenceType.AMBIGUOUS:
            # Ambiguous + keyword not found → return not found so caller falls through to analysis
            return ResolvedMeal(found=False, message=None)

    if not logs:
        return await _build_fallback(ref, user_id, db, loop, target)

    return _build_resolved(logs, ref, target)


async def _resolve_repeat(ref, user_id, db, loop) -> ResolvedMeal:
    """Resolve repeat references: "same thing", "again", etc."""
    logs = await loop.run_in_executor(
        None, lambda: db.list_food_logs(
            user_id,
            meal_type=ref.meal_type if ref.meal_type else None,
            limit=1,
        )
    )

    if not logs:
        return ResolvedMeal(
            found=False,
            message="No recent meals found to repeat. Describe what you ate instead.",
        )

    log = logs[0]
    source_date = _parse_logged_at(log.get("logged_at"))
    return _build_resolved(logs, ref, source_date)


async def _resolve_usual(ref, user_id, db, loop) -> ResolvedMeal:
    """Resolve "my usual" — find most frequently logged meal combo in last 30 days."""
    since = (date.today() - timedelta(days=30)).isoformat()

    logs = await loop.run_in_executor(
        None, lambda: db.list_food_logs(
            user_id,
            from_date=since,
            meal_type=ref.meal_type if ref.meal_type else None,
            limit=100,
        )
    )

    if len(logs) < 3:
        return ResolvedMeal(
            found=False,
            message="Not enough meal history to find your usual. Log a few more meals first!",
        )

    # Find most common meal by food item names (sorted tuple as key)
    from collections import Counter
    meal_signatures = Counter()
    sig_to_log = {}

    for log in logs:
        items = log.get("food_items", [])
        if not items:
            continue
        names = tuple(sorted(item.get("name", "").lower().strip() for item in items if item.get("name")))
        if names:
            meal_signatures[names] += 1
            if names not in sig_to_log:
                sig_to_log[names] = log

    if not meal_signatures:
        return ResolvedMeal(
            found=False,
            message="Not enough meal history to find your usual. Log a few more meals first!",
        )

    most_common = meal_signatures.most_common(1)[0]
    most_common_sig, count = most_common
    best_log = sig_to_log[most_common_sig]

    source_date = _parse_logged_at(best_log.get("logged_at"))
    result = _build_resolved([best_log], ref, source_date)
    result.source_label = f"Your usual ({count}x in last 30 days)"
    return result


async def _resolve_keyword(ref, user_id, db, loop) -> ResolvedMeal:
    """Resolve keyword searches: "the chicken from last week", etc."""
    days_back = 14
    if ref.target_date:
        # Search around the target date (±1 day)
        from_date = (ref.target_date - timedelta(days=1)).isoformat()
        to_date = (ref.target_date + timedelta(days=2)).isoformat()
    else:
        from_date = (date.today() - timedelta(days=days_back)).isoformat()
        to_date = (date.today() + timedelta(days=1)).isoformat()

    logs = await loop.run_in_executor(
        None, lambda: db.list_food_logs(
            user_id,
            from_date=from_date,
            to_date=to_date,
            limit=50,
        )
    )

    if not logs or not ref.keyword:
        return ResolvedMeal(
            found=False,
            message=f"No '{ref.keyword}' meals found recently. Try describing it instead.",
        )

    # Filter by keyword
    filtered = [l for l in logs if _keyword_in_log(ref.keyword, l)]

    if not filtered:
        return ResolvedMeal(
            found=False,
            message=f"No '{ref.keyword}' meals found recently. Try describing it instead.",
        )

    # Return the most recent match
    best = filtered[0]
    source_date = _parse_logged_at(best.get("logged_at"))
    return _build_resolved([best], ref, source_date)


# ═══════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════

def _keyword_in_log(keyword: str, log: Dict) -> bool:
    """Check if keyword matches any food item in the log."""
    kw_lower = keyword.lower()
    for item in log.get("food_items", []):
        name = (item.get("name") or "").lower()
        if kw_lower in name or name in kw_lower:
            return True
    return False


def _parse_logged_at(logged_at) -> Optional[date]:
    """Parse logged_at string to date."""
    if not logged_at:
        return None
    try:
        if isinstance(logged_at, str):
            return date.fromisoformat(logged_at[:10])
        return logged_at
    except (ValueError, TypeError):
        return None


def _build_resolved(logs: List[Dict], ref: ContextualRef, source_date: Optional[date]) -> ResolvedMeal:
    """Build a ResolvedMeal from matching food logs."""
    all_items = []
    total_cal = 0
    total_prot = 0.0
    total_carbs = 0.0
    total_fat = 0.0
    total_fiber = 0.0
    meal_types_seen = set()

    for log in logs:
        items = log.get("food_items", [])
        meal_types_seen.add(log.get("meal_type", "meal"))

        for item in items:
            # Apply portion modifier
            mod = ref.modifier or 1.0
            cal = int((item.get("calories", 0) or 0) * mod)
            prot = float((item.get("protein_g", 0) or 0)) * mod
            carbs = float((item.get("carbs_g", 0) or 0)) * mod
            fat = float((item.get("fat_g", 0) or 0)) * mod
            fiber = float((item.get("fiber_g", 0) or 0)) * mod

            # Apply exclusion modifier
            if ref.modifier_exclude:
                name_lower = (item.get("name") or "").lower()
                if ref.modifier_exclude.lower() in name_lower:
                    continue  # Skip this item

            # Build item in the format expected by the analyze response
            food_item = {
                "name": item.get("name", "Unknown"),
                "amount": item.get("amount", "1 serving"),
                "calories": cal,
                "protein_g": round(prot, 1),
                "carbs_g": round(carbs, 1),
                "fat_g": round(fat, 1),
                "fiber_g": round(fiber, 1),
            }
            # Carry over weight fields if present
            if item.get("weight_g"):
                food_item["weight_g"] = round(float(item["weight_g"]) * (ref.modifier or 1.0), 1)

            all_items.append(food_item)
            total_cal += cal
            total_prot += prot
            total_carbs += carbs
            total_fat += fat
            total_fiber += fiber

    # Build source label
    meal_type_str = ", ".join(sorted(meal_types_seen))
    date_str = source_date.strftime("%b %d") if source_date else "recent"
    modifier_str = ""
    if ref.modifier and ref.modifier != 1.0:
        modifier_str = f" ({ref.modifier}x portions)"
    source_label = f"From {meal_type_str} · {date_str}{modifier_str}"

    return ResolvedMeal(
        found=True,
        items=all_items,
        source_label=source_label,
        source_date=source_date.isoformat() if source_date else None,
        source_meal_type=meal_type_str,
        total_calories=total_cal,
        protein_g=round(total_prot, 1),
        carbs_g=round(total_carbs, 1),
        fat_g=round(total_fat, 1),
        fiber_g=round(total_fiber, 1),
    )


async def _build_fallback(ref, user_id, db, loop, target_date) -> ResolvedMeal:
    """Build helpful fallback when no logs found for the reference."""
    target_str = target_date.isoformat()
    end_str = (target_date + timedelta(days=1)).isoformat()

    # Check if they logged a DIFFERENT meal type that day
    if ref.meal_type:
        all_day_logs = await loop.run_in_executor(
            None, lambda: db.list_food_logs(
                user_id,
                from_date=target_str,
                to_date=end_str,
                limit=10,
            )
        )
        if all_day_logs:
            other_meals = [l for l in all_day_logs if l.get("meal_type") != ref.meal_type]
            if other_meals:
                other_type = other_meals[0].get("meal_type", "a meal")
                other_items = other_meals[0].get("food_items", [])
                other_names = ", ".join(
                    item.get("name", "?") for item in other_items[:3]
                )
                return ResolvedMeal(
                    found=False,
                    message=(
                        f"No {ref.meal_type} logged on {target_date.strftime('%b %d')}. "
                        f"You had {other_type}: {other_names}. Did you mean that?"
                    ),
                    suggestion_logs=other_meals,
                )

    return ResolvedMeal(
        found=False,
        message=f"No meals logged on {target_date.strftime('%b %d')}. Describe what you ate instead.",
    )


# ═══════════════════════════════════════════════════════════════════
# Main Entry Point
# ═══════════════════════════════════════════════════════════════════

async def detect_and_resolve(
    description: str,
    user_id: str,
    current_meal_type: Optional[str],
    nutrition_db,
) -> Optional[ResolvedMeal]:
    """
    Main entry point: detect contextual reference and resolve it.

    Returns:
        ResolvedMeal if reference detected and resolved (or fallback message).
        None if input is not a contextual reference (caller should proceed with normal analysis).
    """
    ref = detect_contextual_reference(description, current_meal_type)
    if ref is None:
        return None

    logger.info(
        f"[ContextualMeal] Detected {ref.ref_type.value} reference: "
        f"date={ref.target_date}, meal={ref.meal_type}, "
        f"keyword={ref.keyword}, modifier={ref.modifier}, "
        f"text='{ref.original_text}'"
    )

    result = await resolve_contextual_reference(ref, user_id, nutrition_db)

    # For ambiguous references that weren't found, return None to let normal analysis proceed
    if ref.ref_type == ReferenceType.AMBIGUOUS and not result.found and not result.message:
        logger.info(f"[ContextualMeal] Ambiguous reference not found in history, falling through to analysis")
        return None

    return result
