"""
Sleep-aware nutrition (Phase E1 — the closed-loop differentiator)
=================================================================
Turns the user's recovery state (Phase B1's recovery score + tier) into a
DETERMINISTIC adjustment of the day's macro targets, plus a deterministic
sleep-risk classifier for logged / scanned food.

Two independent surfaces, both pure and side-effect free:

1. ``adjust_targets_for_recovery`` — on a low-recovery day, shift the day's
   macro emphasis: protein up 10-15%, carbs/fat trimmed to keep total calories
   on target (poor sleep raises cortisol + protein turnover), and surface a
   timing nudge ("front-load calories — poor sleep raises evening cravings").
   It NEVER raises the calorie total, so it cannot erode a cutting deficit.

2. ``classify_sleep_risk`` / ``flag_food_items_for_sleep`` — tag caffeine /
   alcohol / heavy-late-meal content on a logged or scanned food item, and
   flag it only when it falls inside the user's wind-down window vs the
   ``health_goals`` bedtime goal.

Hard rules (CLAUDE.md + the approved plan, edge cases G35 / G36):
  * The recovery -> nutrition mapping is DETERMINISTIC — a tier maps to a fixed
    multiplier. No LLM is ever consulted for it.
  * No recovery data => targets are returned UNCHANGED. No mock data.
  * The protein-up adjustment respects the calorie-deficit goal: it FLOORS the
    FINAL calorie target and never clamps the deficit. Because protein is
    raised by re-allocating calories away from carbs/fat (not by adding
    calories), the deficit (= kg/wk x 7700 / 7) is preserved untouched.
  * Dietary restrictions are respected — a low-carb / keto user is not pushed
    toward extra carbs, and the protein bump is suppressed when the user's
    restrictions make a higher-protein day inappropriate (e.g. a documented
    renal restriction). Unknown / empty restrictions => no suppression.
  * The caffeine / alcohol / heavy-meal flag fires ONLY when the item content
    is recognised. Unknown content => no flag, no false alarm.
"""

from __future__ import annotations

import logging
from datetime import datetime, time, timedelta
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


# =============================================================================
# Part 1 — recovery -> macro-target adjustment (deterministic)
# =============================================================================

# Macro energy densities (kcal per gram) — textbook Atwater factors.
_KCAL_PER_G_PROTEIN = 4.0
_KCAL_PER_G_CARB = 4.0
_KCAL_PER_G_FAT = 9.0

# Per-tier protein bump. The plan specifies "+10-15%": the worse the recovery
# tier, the larger the bump within that band. Tiers that need no adaptation
# ("optimal" / "good") map to 0.0 — targets are returned unchanged for them.
# Keyed by the tier name produced by ``readiness_service.map_recovery_to_tier``.
_RECOVERY_PROTEIN_BUMP: Dict[str, float] = {
    "optimal": 0.0,
    "good": 0.0,
    "moderate": 0.10,      # mild under-recovery: +10% protein
    "compromised": 0.125,  # notable under-recovery: +12.5% protein
    "low": 0.15,           # poor night: +15% protein
}

# A tier is "low recovery" (triggers the full adjustment + craving heads-up)
# when its protein bump is non-zero. Centralised so callers stay in sync.
_LOW_RECOVERY_TIERS = frozenset(
    t for t, bump in _RECOVERY_PROTEIN_BUMP.items() if bump > 0.0
)

# Gap 2 — load-aware escalation. When the user is ALSO carrying high training
# load (loading / overreaching) on a low-recovery day, the protein-repair need
# is greater, so we step the bump up ONE notch — but never past the documented
# +15% band ceiling. The day stays calorie-neutral (the carb/fat re-allocation
# below is unchanged), so the cutting deficit is still preserved. Deterministic;
# no LLM judges "is this load dangerous" (feedback_no_llm_for_safety_classification).
_LOAD_ESCALATED_BUMP: Dict[str, float] = {
    "moderate": 0.125,     # +10% → +12.5%
    "compromised": 0.15,   # +12.5% → +15% (band ceiling)
    "low": 0.15,           # already at the ceiling — no further escalation
}
# Training-load states that justify the escalation.
_HIGH_LOAD_STATES = frozenset({"loading", "overreaching"})

# Absolute floor for the FINAL daily calorie target. ACSM / NATA minimum-intake
# guidance: never program a day below ~1200 kcal regardless of the deficit.
# This floors the FINAL target only — it never widens or clamps the deficit.
_CALORIE_FLOOR_KCAL = 1200

# Dietary-restriction tokens (lowercased substrings) under which a higher-
# protein day is medically inappropriate — the protein bump is suppressed and
# targets returned unchanged. Renal / kidney restrictions are the documented
# case (protein load is contraindicated in chronic kidney disease).
_PROTEIN_RESTRICTED_TOKENS = (
    "renal",
    "kidney",
    "low protein",
    "low-protein",
    "ckd",
)

# Dietary-restriction tokens under which carbohydrate must NOT be increased.
# When trimming protein's calorie cost out of carbs+fat we still only ever
# REDUCE carbs, so these matter only for the (unused) reverse direction; kept
# documented so a future edit that adds carbs respects them.
_LOW_CARB_TOKENS = ("keto", "ketogenic", "low carb", "low-carb", "atkins")


def _coerce_float(value: Any) -> Optional[float]:
    """Coerce a value to float, returning None for null / unparseable input."""
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _restrictions_block_protein_bump(
    dietary_restrictions: Optional[List[str]],
) -> bool:
    """True when the user's dietary restrictions make a higher-protein day
    inappropriate (renal / low-protein medical restriction).

    Unknown / empty restrictions => False (no suppression) — we never invent a
    restriction the user did not record.
    """
    if not dietary_restrictions:
        return False
    for raw in dietary_restrictions:
        if not raw:
            continue
        token = str(raw).strip().lower()
        if any(needle in token for needle in _PROTEIN_RESTRICTED_TOKENS):
            return True
    return False


def adjust_targets_for_recovery(
    base_targets: Dict[str, Optional[float]],
    recovery: Optional[Dict[str, Any]],
    dietary_restrictions: Optional[List[str]] = None,
    load_state: Optional[str] = None,
) -> Dict[str, Any]:
    """Deterministically adjust a day's macro targets for the user's recovery.

    On a LOW-recovery day this re-allocates the calorie budget toward protein:
    protein grams are raised by a fixed per-tier percentage, and carbohydrate
    and fat grams are trimmed by the exact calorie cost of that extra protein
    so the TOTAL calorie target is unchanged. Poor sleep raises cortisol,
    appetite and protein turnover, so a higher-protein, calorie-neutral day is
    the evidence-aligned response — and because no calories are added, the
    user's cutting deficit (= kg/wk x 7700 / 7) is preserved untouched.

    Args:
        base_targets: The user's current targets. Recognised keys (all
            optional, all may be None):
              ``daily_calorie_target``     (kcal)
              ``daily_protein_target_g``   (g)
              ``daily_carbs_target_g``     (g)
              ``daily_fat_target_g``       (g)
        recovery: The ``recovery`` sub-dict from
            ``health_activity.get_health_activity_snapshot`` —
            ``{"score", "tier", "volume_multiplier", "adjustment"}``. ``None``
            or a dict with ``tier`` None => NO adjustment (returned unchanged).
        dietary_restrictions: The user's recorded dietary restrictions. A
            renal / low-protein restriction suppresses the protein bump.

    Returns:
        A dict:
          ``adjusted``        — True if any target value changed.
          ``reason``          — short machine token: "no_recovery_data",
                                "recovery_ok", "restricted", or "low_recovery".
          ``tier``            — the recovery tier, or None.
          ``targets``         — the (possibly adjusted) target dict, same keys
                                as ``base_targets``; values are ints, or None
                                when the corresponding base value was None.
          ``calorie_floored`` — True if the final calorie target hit the
                                ``_CALORIE_FLOOR_KCAL`` floor.
          ``craving_heads_up``— a human craving / timing nudge string, or None.
          ``protein_delta_g`` — grams of protein added (0 when unchanged).

    Edge case G35: no recovery data => ``adjusted=False`` and the input
    targets echoed back verbatim. The calorie total is never raised.
    """
    # Echo the base targets through unchanged when we cannot / should not act.
    def _unchanged(reason: str) -> Dict[str, Any]:
        return {
            "adjusted": False,
            "reason": reason,
            "tier": (recovery or {}).get("tier") if recovery else None,
            "targets": dict(base_targets),
            "calorie_floored": False,
            "craving_heads_up": None,
            "protein_delta_g": 0,
        }

    # --- gate 1: no recovery data (edge case G35) ----------------------------
    if not recovery:
        return _unchanged("no_recovery_data")
    tier = recovery.get("tier")
    if not tier:
        return _unchanged("no_recovery_data")

    # --- gate 2: recovery is fine — no adaptation needed ---------------------
    if tier not in _LOW_RECOVERY_TIERS:
        return _unchanged("recovery_ok")

    # --- gate 3: dietary restriction forbids a higher-protein day ------------
    if _restrictions_block_protein_bump(dietary_restrictions):
        logger.info(
            "sleep_aware_nutrition: protein bump suppressed by dietary "
            "restriction (tier=%s)",
            tier,
        )
        return _unchanged("restricted")

    # --- the adjustment ------------------------------------------------------
    calories = _coerce_float(base_targets.get("daily_calorie_target"))
    protein = _coerce_float(base_targets.get("daily_protein_target_g"))
    carbs = _coerce_float(base_targets.get("daily_carbs_target_g"))
    fat = _coerce_float(base_targets.get("daily_fat_target_g"))

    bump_frac = _RECOVERY_PROTEIN_BUMP[tier]

    # Gap 2 — escalate the protein bump one notch on a high-load day (still
    # capped at the +15% band ceiling, still calorie-neutral).
    load_escalated = False
    _load = (load_state or "").strip().lower()
    if _load in _HIGH_LOAD_STATES:
        escalated = _LOAD_ESCALATED_BUMP.get(tier, bump_frac)
        if escalated > bump_frac:
            bump_frac = escalated
            load_escalated = True
    load_note = _load_note(tier, _load, load_escalated) if _load in _HIGH_LOAD_STATES else None

    # Without a known protein target there is nothing to scale — surface only
    # the craving heads-up so the user still gets the timing guidance.
    if protein is None or protein <= 0:
        return {
            "adjusted": False,
            "reason": "low_recovery",
            "tier": tier,
            "targets": dict(base_targets),
            "calorie_floored": False,
            "craving_heads_up": _craving_heads_up(tier),
            "protein_delta_g": 0,
            "load_state": _load or None,
            "load_escalated": load_escalated,
            "load_note": load_note,
        }

    new_protein = protein * (1.0 + bump_frac)
    extra_protein_g = new_protein - protein
    extra_protein_kcal = extra_protein_g * _KCAL_PER_G_PROTEIN

    # Re-allocate the extra protein's calorie cost OUT of carbs + fat so the
    # total stays constant. Split the trim proportionally to each macro's
    # current calorie share, so neither is zeroed disproportionately. When one
    # macro is unknown, the whole trim falls on the other.
    carb_kcal = (carbs or 0.0) * _KCAL_PER_G_CARB if carbs else 0.0
    fat_kcal = (fat or 0.0) * _KCAL_PER_G_FAT if fat else 0.0
    trimmable_kcal = carb_kcal + fat_kcal

    new_carbs = carbs
    new_fat = fat
    if trimmable_kcal > 0:
        # Don't trim more than is available — clamp the protein bump's cost.
        trim_kcal = min(extra_protein_kcal, trimmable_kcal)
        carb_share = carb_kcal / trimmable_kcal
        fat_share = fat_kcal / trimmable_kcal
        if carbs is not None:
            new_carbs = max(
                0.0, carbs - (trim_kcal * carb_share) / _KCAL_PER_G_CARB
            )
        if fat is not None:
            new_fat = max(
                0.0, fat - (trim_kcal * fat_share) / _KCAL_PER_G_FAT
            )

    # --- floor the FINAL calorie target (never clamp the deficit) ------------
    # The total is held constant by construction, but if the base target was
    # already at/under the safety floor we floor the FINAL value. This floors
    # the TARGET only — the deficit itself is whatever the user's goal set.
    calorie_floored = False
    final_calories = calories
    if calories is not None and calories < _CALORIE_FLOOR_KCAL:
        final_calories = float(_CALORIE_FLOOR_KCAL)
        calorie_floored = True

    adjusted_targets: Dict[str, Optional[int]] = {
        "daily_calorie_target": (
            int(round(final_calories)) if final_calories is not None else None
        ),
        "daily_protein_target_g": int(round(new_protein)),
        "daily_carbs_target_g": (
            int(round(new_carbs)) if new_carbs is not None else None
        ),
        "daily_fat_target_g": (
            int(round(new_fat)) if new_fat is not None else None
        ),
    }

    logger.info(
        "sleep_aware_nutrition: low-recovery target shift (tier=%s) "
        "protein %s->%sg, calories held at %s%s",
        tier,
        int(round(protein)),
        adjusted_targets["daily_protein_target_g"],
        adjusted_targets["daily_calorie_target"],
        " (floored)" if calorie_floored else "",
    )

    return {
        "adjusted": True,
        "reason": "low_recovery",
        "tier": tier,
        "targets": adjusted_targets,
        "calorie_floored": calorie_floored,
        "craving_heads_up": _craving_heads_up(tier),
        "protein_delta_g": int(round(extra_protein_g)),
        "load_state": _load or None,
        "load_escalated": load_escalated,
        "load_note": load_note,
    }


def _load_note(tier: str, load_state: str, escalated: bool) -> Optional[str]:
    """Deterministic note when a high-load + low-recovery day shifts nutrition.

    Calorie-neutral by construction (the carb/fat re-allocation keeps the total
    constant), so the copy never implies eating more — only eating SMARTER.
    """
    if load_state == "overreaching":
        if escalated:
            return (
                "Your training load is running hot and recovery is short today — "
                "nudged protein up a notch to support repair, with calories held "
                "steady. Consider an easier session."
            )
        return (
            "Training load is high and recovery is short — keep protein up and "
            "consider an easier session today."
        )
    # loading
    if escalated:
        return (
            "You're building load while under-recovered — shifted a bit more of "
            "the day toward protein for repair, calories unchanged."
        )
    return (
        "You're building training load — keep protein steady to support repair."
    )


def _craving_heads_up(tier: str) -> str:
    """A deterministic craving / meal-timing nudge for a low-recovery tier.

    Poor sleep raises ghrelin and evening cortisol, which drives late cravings.
    The copy is fixed per tier (no LLM) and front-loading calories is the
    evidence-aligned counter.
    """
    if tier == "low":
        return (
            "Rough night — appetite hormones run high after poor sleep. "
            "Front-load calories at breakfast and lunch, lean on protein, "
            "and expect stronger evening cravings than usual."
        )
    if tier == "compromised":
        return (
            "Under-recovered today — poor sleep nudges up evening cravings. "
            "Aim most of your calories before mid-afternoon and keep protein high."
        )
    # moderate
    return (
        "Slightly short on recovery — shift a little more of the day's food "
        "to earlier meals and keep protein steady to blunt evening hunger."
    )


# =============================================================================
# Part 2 — sleep-risk classifier for logged / scanned food
# =============================================================================

# Default wind-down window (minutes before the bedtime goal) inside which a
# caffeine / alcohol / heavy meal is flagged. Sleep Foundation guidance: avoid
# caffeine ~6h and a heavy meal ~3h before bed; we use a single 3h window for
# the "logged near bedtime" flag and let caffeine carry its own wider window.
_WIND_DOWN_MINUTES = 180          # 3h — heavy meal / alcohol window
_CAFFEINE_WIND_DOWN_MINUTES = 360  # 6h — caffeine has a long half-life

# Heavy-meal calorie threshold for a single logged item/meal. A single food
# log totalling more than this, eaten inside the wind-down window, is flagged
# as a heavy late meal (digestion disrupts sleep onset).
_HEAVY_MEAL_KCAL = 800

# Recognised caffeine-bearing food/drink name tokens (lowercased substrings).
# Only RECOGNISED content is flagged — an unknown item is never flagged
# (edge case G36: no false alarms).
_CAFFEINE_TOKENS = (
    "coffee", "espresso", "latte", "cappuccino", "americano", "macchiato",
    "mocha", "cold brew", "cold-brew", "flat white", "cortado",
    "energy drink", "red bull", "monster energy", "celsius",
    "pre-workout", "pre workout", "preworkout",
    "matcha", "yerba mate", "yerba-mate", "guarana",
    "black tea", "green tea", "chai", "caffeinated",
    "espresso shot", "double shot",
)
# Decaf must NOT trip the caffeine flag — checked before the token scan.
_DECAF_TOKENS = ("decaf", "decaffeinated", "caffeine-free", "caffeine free")

# Recognised alcohol-bearing food/drink name tokens (lowercased substrings).
_ALCOHOL_TOKENS = (
    "beer", "lager", "ale", "ipa", "stout", "pilsner",
    "wine", "merlot", "cabernet", "chardonnay", "rosé", "rose wine",
    "prosecco", "champagne", "sparkling wine",
    "vodka", "whiskey", "whisky", "bourbon", "rum", "gin", "tequila",
    "brandy", "cognac", "scotch",
    "cocktail", "margarita", "mojito", "martini", "negroni",
    "old fashioned", "manhattan", "daiquiri", "sangria",
    "hard seltzer", "hard cider", "spiked",
    "liqueur", "aperol", "campari",
)
# Non-alcoholic variants must NOT trip the alcohol flag.
_NON_ALCOHOLIC_TOKENS = (
    "non-alcoholic", "non alcoholic", "alcohol-free", "alcohol free",
    "0% abv", "zero proof", "mocktail", "virgin ",  # "virgin mojito"
)


def _name_has_token(name: str, tokens: tuple) -> bool:
    """True when ``name`` (already lowercased) contains any token substring."""
    return any(tok in name for tok in tokens)


def classify_sleep_risk(food_item: Dict[str, Any]) -> Dict[str, Any]:
    """Classify ONE food/drink item for sleep-disrupting content.

    Deterministic name-based detection. ONLY recognised content is classified;
    an unrecognised item returns ``risk_type=None`` so no flag is ever raised
    on unknown content (edge case G36 — no false alarms).

    Args:
        food_item: A food-item dict from the food classifier / log. Uses the
            ``name`` field; ``calories`` (or ``total_calories``) is used for
            the heavy-meal signal.

    Returns:
        ``{"risk_type": str|None, "detail": str|None}`` where ``risk_type`` is
        one of "caffeine", "alcohol", "heavy_meal", or None when nothing
        recognisable was found.
    """
    if not isinstance(food_item, dict):
        return {"risk_type": None, "detail": None}

    raw_name = food_item.get("name") or ""
    name = str(raw_name).strip().lower()

    if name:
        # Caffeine — but decaf / caffeine-free explicitly clears it.
        if not _name_has_token(name, _DECAF_TOKENS) and _name_has_token(
            name, _CAFFEINE_TOKENS
        ):
            return {
                "risk_type": "caffeine",
                "detail": f"{raw_name} contains caffeine",
            }
        # Alcohol — but non-alcoholic / mocktail variants explicitly clear it.
        if not _name_has_token(name, _NON_ALCOHOLIC_TOKENS) and _name_has_token(
            name, _ALCOHOL_TOKENS
        ):
            return {
                "risk_type": "alcohol",
                "detail": f"{raw_name} contains alcohol",
            }

    # Heavy meal — a single high-calorie item. Calorie data IS known content,
    # so a recognised-large item is a valid (non-name) signal.
    kcal = _coerce_float(food_item.get("calories"))
    if kcal is None:
        kcal = _coerce_float(food_item.get("total_calories"))
    if kcal is not None and kcal >= _HEAVY_MEAL_KCAL:
        return {
            "risk_type": "heavy_meal",
            "detail": f"heavy meal (~{int(round(kcal))} kcal)",
        }

    return {"risk_type": None, "detail": None}


def _parse_bedtime_goal(bedtime_goal: Any) -> Optional[time]:
    """Parse a ``health_goals.bedtime_goal`` value into a ``datetime.time``.

    Accepts ``"HH:MM"`` / ``"HH:MM:SS"`` strings (Postgres ``TIME`` columns
    serialise this way) or a ``datetime.time``. Returns None on anything
    unparseable — the caller then simply does not flag (no false alarm).
    """
    if bedtime_goal is None:
        return None
    if isinstance(bedtime_goal, time):
        return bedtime_goal
    text = str(bedtime_goal).strip()
    if not text:
        return None
    for fmt in ("%H:%M:%S", "%H:%M"):
        try:
            return datetime.strptime(text, fmt).time()
        except ValueError:
            continue
    return None


def _minutes_before_bedtime(
    logged_at_local: datetime,
    bedtime: time,
) -> float:
    """Minutes from ``logged_at_local`` until the next occurrence of ``bedtime``.

    Sleep is attributed to its wake date, so a 9pm coffee and an 11pm coffee
    are both "before tonight's bedtime". When the log time is already past
    bedtime (early-morning hours) we measure to the NEXT bedtime, which yields
    a large value => correctly NOT inside the wind-down window.
    """
    bedtime_today = logged_at_local.replace(
        hour=bedtime.hour,
        minute=bedtime.minute,
        second=bedtime.second,
        microsecond=0,
    )
    if bedtime_today <= logged_at_local:
        # Bedtime already passed today — the relevant bedtime is tomorrow's.
        bedtime_today = bedtime_today + timedelta(days=1)
    delta = bedtime_today - logged_at_local
    return delta.total_seconds() / 60.0


def flag_food_items_for_sleep(
    food_items: List[Dict[str, Any]],
    logged_at_local: Optional[datetime],
    bedtime_goal: Any,
) -> Dict[str, Any]:
    """Flag logged / scanned food for sleep risk inside the wind-down window.

    For each item, ``classify_sleep_risk`` determines recognised content; an
    item is FLAGGED only when (a) it has a recognised risk type AND (b) it was
    logged inside the relevant wind-down window before the user's bedtime goal
    (6h for caffeine, 3h for alcohol / heavy meals).

    No bedtime goal, no log timestamp, or no recognised content => an empty
    result. Unknown content is never flagged (edge case G36).

    Args:
        food_items: The food-item dicts being logged or scanned.
        logged_at_local: When the item was logged, in the USER'S local time
            (tz-aware or naive-local both work — only wall-clock is used).
        bedtime_goal: The user's ``health_goals.bedtime_goal`` (``"HH:MM"`` /
            ``time`` / None).

    Returns:
        ``{"has_flag": bool, "flags": [{name, risk_type, detail,
        minutes_before_bedtime}], "message": str|None}``. ``message`` is a
        single human heads-up summarising the flags, or None when none fired.
    """
    empty = {"has_flag": False, "flags": [], "message": None}

    if not food_items:
        return empty
    if logged_at_local is None:
        return empty

    bedtime = _parse_bedtime_goal(bedtime_goal)
    if bedtime is None:
        # No bedtime goal set — we cannot place the log in a wind-down window,
        # so we do not flag (no false alarm).
        return empty

    minutes_to_bed = _minutes_before_bedtime(logged_at_local, bedtime)

    flags: List[Dict[str, Any]] = []
    for item in food_items:
        risk = classify_sleep_risk(item)
        risk_type = risk.get("risk_type")
        if not risk_type:
            continue  # unknown / non-risky content — never flagged

        window = (
            _CAFFEINE_WIND_DOWN_MINUTES
            if risk_type == "caffeine"
            else _WIND_DOWN_MINUTES
        )
        if minutes_to_bed > window:
            continue  # logged well before the wind-down window — not a risk

        flags.append(
            {
                "name": (item.get("name") if isinstance(item, dict) else None),
                "risk_type": risk_type,
                "detail": risk.get("detail"),
                "minutes_before_bedtime": int(round(minutes_to_bed)),
            }
        )

    if not flags:
        return empty

    return {
        "has_flag": True,
        "flags": flags,
        "message": _sleep_risk_message(flags),
    }


def _sleep_risk_message(flags: List[Dict[str, Any]]) -> str:
    """Build a single human heads-up string from one or more sleep-risk flags.

    Deterministic copy (no LLM) — informational, never alarmist, and grounded
    in the specific item + the minutes-to-bedtime that triggered the flag.
    """
    parts: List[str] = []
    for f in flags:
        risk = f.get("risk_type")
        mins = f.get("minutes_before_bedtime")
        name = f.get("name") or "this item"
        hrs = (mins / 60.0) if isinstance(mins, (int, float)) else None
        when = f"~{hrs:.1f}h before your bedtime" if hrs is not None else "before bed"
        if risk == "caffeine":
            parts.append(
                f"{name} has caffeine and you logged it {when} — "
                f"caffeine can delay sleep onset for hours."
            )
        elif risk == "alcohol":
            parts.append(
                f"{name} contains alcohol logged {when} — "
                f"alcohol fragments sleep and cuts REM later in the night."
            )
        elif risk == "heavy_meal":
            parts.append(
                f"{name} is a heavy meal logged {when} — "
                f"late large meals can disrupt sleep onset."
            )
    return " ".join(parts)
