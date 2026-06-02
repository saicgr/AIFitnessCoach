"""Shared meal-recommendation engine (F3).

Single source of truth for "pick ONE meal that fits the user's remaining
macros". Used by BOTH:
  - the home-screen widget endpoint (`api/v1/nutrition/quick_suggestion.py`)
  - the Coach `recommend_meal` tool (`services/langgraph_agents/tools/
    nutrition_tools.py`)

so a "what should I eat / fill my macros" chat ask and the widget share the
exact same (user, slot, hour-bucket) cache and the exact same Gemini call — we
never pay for two parallel generations of the same suggestion.

Hard constraints (allergens / dietary restrictions / disliked foods / fasting)
are injected into the prompt AND re-checked on the parsed result; a violating
suggestion is regenerated once with the violation called out, and if it still
violates we surface a safe text fallback rather than push a restricted food.
"""
from __future__ import annotations

import time
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from google.genai import types

from core.config import get_settings
from core.logger import get_logger
from models.gemini_schemas import QuickSuggestionGeminiResponse
from services.gemini.constants import gemini_generate_with_retry

logger = get_logger(__name__)
settings = get_settings()

# Safe daily-calorie floor (never push the day's eatable budget below this).
SAFE_FLOOR_KCAL = {"female": 1200, "male": 1500}
# A remainder under this is treated as "snack territory", not a full meal.
SNACK_REMAINDER_THRESHOLD = 150

# FDA "Big 9" major allergens — normalised tokens we look for in food text.
FDA_BIG9 = {
    "milk", "dairy", "egg", "eggs", "fish", "shellfish", "crustacean",
    "tree nut", "tree nuts", "nut", "nuts", "peanut", "peanuts",
    "wheat", "gluten", "soy", "soya", "sesame",
}


# ─── In-process cache (mirrors the widget's 30-min (user,slot,hour) cache) ───

_CACHE: Dict[str, Tuple[float, QuickSuggestionGeminiResponse]] = {}
_CACHE_TTL_SECONDS = 30 * 60
_CACHE_MAX = 2000


def cache_key(user_id: str, slot: str) -> str:
    """Stable per (user, slot, hour-bucket) key — same granularity as the
    widget endpoint so a chat ask and a widget refresh in the same hour reuse
    one Gemini call."""
    hour_bucket = datetime.utcnow().strftime("%Y%m%d%H")
    return f"qs:{user_id}:{slot}:{hour_bucket}"


def cache_get(key: str) -> Optional[QuickSuggestionGeminiResponse]:
    hit = _CACHE.get(key)
    if not hit:
        return None
    ts, payload = hit
    if time.time() - ts > _CACHE_TTL_SECONDS:
        _CACHE.pop(key, None)
        return None
    return payload


def cache_put(key: str, value: QuickSuggestionGeminiResponse) -> None:
    _CACHE[key] = (time.time(), value)
    if len(_CACHE) > _CACHE_MAX:
        drop_n = _CACHE_MAX // 10
        oldest = sorted(_CACHE.items(), key=lambda kv: kv[1][0])[:drop_n]
        for k, _ in oldest:
            _CACHE.pop(k, None)


# ─── Meal-slot inference (shared with the widget) ───────────────────────────

_SLOT_TABLE: List[Tuple[int, int, str]] = [
    (4, 10, "breakfast"),
    (10, 15, "lunch"),
    (15, 21, "dinner"),
    (21, 24, "snack"),
    (0, 4, "snack"),
]


def infer_slot(tz_str: str, logged_today: List[str]) -> str:
    """Pick the next un-logged meal slot from local time + logged meals."""
    try:
        now_local = datetime.now(ZoneInfo(tz_str))
    except ZoneInfoNotFoundError:
        now_local = datetime.utcnow()
    hour = now_local.hour
    natural = "snack"
    for lo, hi, slot in _SLOT_TABLE:
        if lo <= hour < hi:
            natural = slot
            break
    order = ["breakfast", "lunch", "dinner", "snack"]
    logged_lower = {(s or "").lower() for s in logged_today}
    if natural not in logged_lower:
        return natural
    try:
        start_idx = order.index(natural)
    except ValueError:
        start_idx = 0
    for offset in range(1, len(order) + 1):
        candidate = order[(start_idx + offset) % len(order)]
        if candidate not in logged_lower:
            return candidate
    return "snack"


# ─── Fasting window ─────────────────────────────────────────────────────────

def is_in_fasting_window(prefs: Dict[str, Any], tz_str: str) -> bool:
    """True when the user has a configured eating window and the current local
    hour falls OUTSIDE it (i.e. they are fasting). Tolerant of absent config —
    no window set means never fasting. Supports both an explicit
    ``fasting_*`` shape and a generic ``eating_window_start/end_hour`` shape so
    we don't break if the prefs schema later gains either."""
    try:
        if not prefs.get("intermittent_fasting_enabled") and not prefs.get(
            "fasting_enabled"
        ):
            # No explicit fasting toggle → look for a bare eating window.
            start = prefs.get("eating_window_start_hour")
            end = prefs.get("eating_window_end_hour")
            if start is None or end is None:
                return False
        else:
            start = prefs.get("eating_window_start_hour", prefs.get("fasting_end_hour"))
            end = prefs.get("eating_window_end_hour", prefs.get("fasting_start_hour"))
            if start is None or end is None:
                return False
        try:
            now_local = datetime.now(ZoneInfo(tz_str))
        except ZoneInfoNotFoundError:
            now_local = datetime.utcnow()
        h = now_local.hour
        start, end = int(start), int(end)
        if start <= end:
            in_window = start <= h < end
        else:  # window wraps midnight (e.g. 20:00 → 04:00)
            in_window = h >= start or h < end
        return not in_window
    except Exception as e:
        logger.debug(f"[recommend_meal] fasting-window check skipped: {e}")
        return False


# ─── Constraint enforcement ─────────────────────────────────────────────────

def _normalize_tokens(values: Any) -> List[str]:
    out: List[str] = []
    if isinstance(values, list):
        for v in values:
            if v:
                out.append(str(v).strip().lower())
    elif isinstance(values, str) and values.strip():
        out.append(values.strip().lower())
    return out


def violates_constraints(
    suggestion: QuickSuggestionGeminiResponse,
    forbidden_tokens: List[str],
) -> Optional[str]:
    """Return the first forbidden token that appears in the suggestion text, or
    None when the suggestion is clean. Substring match on the lowercased
    title + every food-item name — deliberately conservative (a false positive
    just triggers one regeneration, never serves a violating food)."""
    if not forbidden_tokens:
        return None
    haystack = (suggestion.title or "").lower()
    haystack += " " + " ".join(
        (fi.name or "").lower() for fi in (suggestion.food_items or [])
    )
    for tok in forbidden_tokens:
        if tok and tok in haystack:
            return tok
    return None


# ─── Prompt ──────────────────────────────────────────────────────────────────

_SYSTEM_INSTRUCTION = (
    "You are a pragmatic nutrition coach generating ONE meal suggestion. "
    "Be specific and realistic (real foods, normal portions, supermarket ingredients). "
    "Pick ONE meal that fits the user's remaining macros; do not return options or alternatives. "
    "Prefer the user's recent favorites when the macros fit. "
    "HARD RULES (never violate): never suggest a food the user is allergic to, "
    "that breaks a stated dietary restriction, or that they dislike. "
    "Keep the title under 40 characters and the subtitle under 80 characters. "
    "Subtitle must explain in one sentence why this fits. "
    "Ingredient components must sum approximately to the totals (±5 cal / ±1 g)."
)


def build_prompt(
    meal_slot: str,
    eatable_calories: Optional[int],
    macros_remaining: Dict[str, Any],
    favs: List[Dict[str, Any]],
    workout: Optional[Dict[str, Any]],
    *,
    allergens: List[str],
    dietary_restrictions: List[str],
    dislikes: List[str],
    cuisines: List[str],
    over_budget: bool,
    snack_only: bool,
    locale: str = "en",
) -> str:
    lines = [
        f"Meal slot: {meal_slot}",
        f"Calories available for this meal/day: "
        f"{eatable_calories if eatable_calories is not None else 'unknown (no target)'}",
        f"Macros remaining — "
        f"P: {macros_remaining.get('protein_g', '?')}g  "
        f"C: {macros_remaining.get('carbs_g', '?')}g  "
        f"F: {macros_remaining.get('fat_g', '?')}g",
    ]
    if allergens:
        lines.append(f"ALLERGENS — never include (FDA Big 9 + user): {', '.join(allergens)}")
    if dietary_restrictions:
        lines.append(f"DIETARY RESTRICTIONS — must respect: {', '.join(dietary_restrictions)}")
    if dislikes:
        lines.append(f"DISLIKES — never suggest: {', '.join(dislikes)}")
    if cuisines:
        lines.append(f"Preferred cuisines (lean toward): {', '.join(cuisines)}")
    if over_budget:
        lines.append(
            "User is OVER their calorie budget today — suggest a LIGHT, low-calorie "
            "option (e.g. a small protein-forward snack or broth-based soup), NEVER a full meal."
        )
    if snack_only:
        lines.append(
            "Very little budget remains — suggest a SNACK (<150 kcal), not a meal."
        )
    if workout:
        wo_name = workout.get("name") or "Workout"
        done = "done" if workout.get("is_completed") else "planned"
        muscles = workout.get("primary_muscles") or []
        lines.append(
            f"Today's workout: {wo_name} ({done})"
            + (f" · primary: {', '.join(muscles)}" if muscles else "")
        )
    if favs:
        fav_lines = ", ".join(
            f"{f.get('name')} ({int(f.get('total_calories') or 0)} cal)"
            for f in favs[:5]
        )
        lines.append(f"User favorites (prefer when they fit): {fav_lines}")
    if locale and locale != "en":
        lines.append(
            f"Write the title and subtitle in the user's language (locale '{locale}'); "
            f"keep food-item names natural for that locale."
        )
    lines.append(
        "\nReturn ONE meal suggestion as structured JSON. "
        "Include 1-4 food_items whose calories/macros sum to the totals."
    )
    return "\n".join(lines)


async def generate_suggestion(
    *,
    user_id: str,
    meal_slot: str,
    eatable_calories: Optional[int],
    macros_remaining: Dict[str, Any],
    favs: List[Dict[str, Any]],
    workout: Optional[Dict[str, Any]],
    allergens: List[str],
    dietary_restrictions: List[str],
    dislikes: List[str],
    cuisines: List[str],
    over_budget: bool,
    snack_only: bool,
    locale: str = "en",
) -> QuickSuggestionGeminiResponse:
    """One Gemini call → one validated meal suggestion. Regenerates ONCE if the
    first result trips a hard constraint; raises if it still violates (caller
    decides how to surface — never serve a restricted food)."""
    forbidden = [t for t in (allergens + dislikes) if t]
    prompt = build_prompt(
        meal_slot, eatable_calories, macros_remaining, favs, workout,
        allergens=allergens, dietary_restrictions=dietary_restrictions,
        dislikes=dislikes, cuisines=cuisines, over_budget=over_budget,
        snack_only=snack_only, locale=locale,
    )

    async def _call(extra: str = "") -> QuickSuggestionGeminiResponse:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=prompt + extra,
            config=types.GenerateContentConfig(
                system_instruction=_SYSTEM_INSTRUCTION,
                response_mime_type="application/json",
                response_schema=QuickSuggestionGeminiResponse,
                max_output_tokens=600,
                temperature=0.6,
            ),
            user_id=user_id,
            method_name="recommend_meal",
            timeout=20,
        )
        parsed = response.parsed
        if parsed is None:
            raise RuntimeError("Gemini returned an unparseable meal suggestion")
        return parsed

    parsed = await _call()
    bad = violates_constraints(parsed, forbidden)
    if bad:
        logger.info(f"[recommend_meal] regen — first pick contained '{bad}'")
        parsed = await _call(
            f"\n\nThe previous attempt included '{bad}', which is FORBIDDEN. "
            f"Pick a completely different meal that excludes it."
        )
        bad2 = violates_constraints(parsed, forbidden)
        if bad2:
            raise ValueError(
                f"Could not produce a constraint-safe meal (still contained '{bad2}')"
            )
    return parsed


def collect_forbidden_tokens(
    *,
    allergies: Any,
    dietary_restrictions: Any,
    dislikes: List[str],
) -> Tuple[List[str], List[str], List[str]]:
    """Normalise the three constraint sources into token lists. FDA Big 9 is
    always merged into the allergen set so even a user who only listed 'peanut'
    still has the full major-allergen guard when their listed allergens map to
    a Big-9 family. We DON'T blanket-forbid all Big 9 for everyone (that would
    forbid eggs for someone with no egg allergy) — we only add Big-9 tokens the
    user actually declared, expanded to their synonyms."""
    user_allergens = _normalize_tokens(allergies)
    restrictions = _normalize_tokens(dietary_restrictions)
    dislike_tokens = _normalize_tokens(dislikes)

    # Expand declared allergens to their Big-9 synonym family so "dairy"
    # also forbids "milk", "peanut" also forbids "peanuts", etc.
    expanded = set(user_allergens)
    families = [
        {"milk", "dairy"}, {"egg", "eggs"}, {"fish"},
        {"shellfish", "crustacean", "shrimp", "crab", "lobster"},
        {"tree nut", "tree nuts", "nut", "nuts", "almond", "cashew", "walnut", "pecan"},
        {"peanut", "peanuts"}, {"wheat", "gluten"}, {"soy", "soya"}, {"sesame"},
    ]
    for tok in list(user_allergens):
        for fam in families:
            if tok in fam:
                expanded |= fam
    return sorted(expanded), restrictions, dislike_tokens
