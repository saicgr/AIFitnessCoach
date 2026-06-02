"""
Cross-Metric Smart Insights Engine (Phase D1)
=============================================
A deterministic correlation engine over the user's own ``daily_activity``
history. It pairs up six health metrics — sleep, steps, active calories,
resting heart rate, workout volume, and body weight — computes a Pearson
correlation for every pair over a 30-90 day window, keeps the pairs that are
both well-sampled and meaningfully correlated, ranks them by how *actionable*
they are, and emits plain-English insight strings.

Why deterministic (no LLM):
  * Correlation is math — an LLM would only add hallucination risk.
  * The output feeds the coach prompt, a home card, and the detail screens; it
    must be reproducible and explainable.

Hard rules (per CLAUDE.md + the approved plan + feedback memory):
  * **Correlation, never causation.** Every insight string is phrased as an
    observed association ("on nights you slept more, your resting HR ran
    lower") — never "X causes Y". The dict carries ``association_only: True``.
  * **Minimum evidence.** A pair is dropped unless it has >= ``_MIN_PAIRED_DAYS``
    days where *both* metrics are present, and ``|r|`` >= ``_MIN_ABS_R``.
  * **No fabrication.** Fewer than the minimum paired days => empty result, not
    a spurious insight. A no-wearable user yields ``[]`` cleanly.
  * **Weekly recompute, cached.** ``compute_smart_insights`` is pure; the
    endpoint layer (``api/v1/insights.py``) caches the result for a week.

Public surface:
  * ``compute_smart_insights(activities, window_days=...)`` — the pure engine.
  * ``top_insight_sentence(insights)`` — the single best line for the coach
    prompt (consumed by ``health_activity.get_health_context_for_ai``).
  * ``compute_food_sleep_insights(food_logs, activities, ...)`` — Phase E2:
    food-log-derived signals (evening caffeine, alcohol, large late meals,
    how late the user ate) correlated against the *next night's* sleep.
  * ``compute_training_sleep_insights(activities, performance_logs,
    form_jobs=..., ...)`` — Phase E3: a night's sleep correlated against the
    next day's logged lift performance (top-set load, reps, RPE) and AI
    form-analysis scores.

All three correlation engines share the same hard rules (>= 14 paired days —
8 for the sparse form-score pair — |r| >= 0.30, association-only copy, clean
empty output when data is sparse).
"""

from __future__ import annotations

import logging
from datetime import date, datetime, timedelta
from math import sqrt
from typing import Any, Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)


# =============================================================================
# Tuning constants — all deterministic, all documented inline.
# =============================================================================

# A correlation pair needs at least this many days where BOTH metrics are
# present. 14 is the plan's floor — below it a Pearson r is too noisy to trust
# and could surface a spurious pattern (edge case F33).
_MIN_PAIRED_DAYS = 14

# A pair is only surfaced when |r| reaches this. ~0.30 is a conventional
# "moderate" correlation threshold — weaker than that is not worth a user-
# facing insight.
_MIN_ABS_R = 0.30

# The correlation window. The engine accepts 30-90 days of history; callers
# pass the rows and a window size, and rows outside the window are dropped.
_MIN_WINDOW_DAYS = 30
_MAX_WINDOW_DAYS = 90
_DEFAULT_WINDOW_DAYS = 60

# How many ranked insights to emit at most — the home card / coach only need a
# few; more would be noise.
_MAX_INSIGHTS = 5


# -----------------------------------------------------------------------------
# Metric registry. Each metric maps a ``daily_activity`` row to a single daily
# scalar. ``higher_is_better`` documents the metric's polarity (used purely for
# phrasing, never for the math). ``label`` is the human noun used in copy.
# -----------------------------------------------------------------------------

def _row_sleep(row: Dict[str, Any]) -> Optional[float]:
    return _num(row.get("sleep_minutes"))


def _row_steps(row: Dict[str, Any]) -> Optional[float]:
    return _num(row.get("steps"))


def _row_active_cal(row: Dict[str, Any]) -> Optional[float]:
    return _num(row.get("active_calories"))


def _row_resting_hr(row: Dict[str, Any]) -> Optional[float]:
    return _num(row.get("resting_heart_rate"))


def _row_workout_volume(row: Dict[str, Any]) -> Optional[float]:
    """Workout volume proxy for the day.

    ``daily_activity`` does not store a strength-volume figure, so we use the
    closest day-level signal it DOES carry: active-calorie burn is the best
    available proxy for training load. Documented openly so the math is honest
    — when a richer per-day volume column lands this is the one place to swap.
    """
    return _num(row.get("active_calories"))


def _row_weight(row: Dict[str, Any]) -> Optional[float]:
    return _num(row.get("weight_kg"))


# Each entry: key -> (label, getter, higher_is_better)
_METRICS: Dict[str, Tuple[str, Any, bool]] = {
    "sleep": ("sleep", _row_sleep, True),
    "steps": ("daily steps", _row_steps, True),
    "active_calories": ("active calories", _row_active_cal, True),
    "resting_hr": ("resting heart rate", _row_resting_hr, False),
    "workout_volume": ("training load", _row_workout_volume, True),
    "weight": ("body weight", _row_weight, False),
}

# ``workout_volume`` and ``active_calories`` share the exact same source column
# today, so correlating them would yield a meaningless r=1.0. Suppress that one
# pair explicitly until they diverge.
_SUPPRESSED_PAIRS: set = {frozenset({"active_calories", "workout_volume"})}


# -----------------------------------------------------------------------------
# Actionability ranking. A correlation involving a metric the user can directly
# act on (sleep, steps, training load) is more useful to surface than one
# between two passive readouts. Higher = more actionable.
# -----------------------------------------------------------------------------
_ACTIONABILITY: Dict[str, int] = {
    "sleep": 3,
    "steps": 3,
    "workout_volume": 2,
    "active_calories": 2,
    "resting_hr": 1,
    "weight": 1,
}


def _num(value: Any) -> Optional[float]:
    """Coerce a DB value to float; None for null / unparseable / non-positive
    sentinels are kept as-is (0 is a legitimate step/calorie value)."""
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


# =============================================================================
# Pearson correlation
# =============================================================================

def pearson_r(xs: List[float], ys: List[float]) -> Optional[float]:
    """Pearson correlation coefficient for paired samples ``xs`` / ``ys``.

    Returns ``None`` when there are fewer than 2 pairs or when either series has
    zero variance (a flat series has an undefined correlation — never a fake 0).
    """
    n = len(xs)
    if n < 2 or len(ys) != n:
        return None

    mean_x = sum(xs) / n
    mean_y = sum(ys) / n

    cov = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys))
    var_x = sum((x - mean_x) ** 2 for x in xs)
    var_y = sum((y - mean_y) ** 2 for y in ys)

    if var_x <= 0 or var_y <= 0:
        return None

    r = cov / sqrt(var_x * var_y)
    # Clamp tiny floating-point overshoot past +-1.
    return max(-1.0, min(1.0, r))


# =============================================================================
# Insight phrasing — deterministic, association-only copy.
# =============================================================================

def _strength_word(abs_r: float) -> str:
    """A plain-language strength label for ``|r|``."""
    if abs_r >= 0.7:
        return "a strong"
    if abs_r >= 0.5:
        return "a clear"
    return "a moderate"


def _insight_sentence(
    key_a: str,
    key_b: str,
    r: float,
) -> str:
    """Build an association-only insight sentence for a correlated pair.

    The wording always frames the relationship as an *observed pattern in your
    data* — never a causal claim — to satisfy the no-causation rule.
    """
    label_a = _METRICS[key_a][0]
    label_b = _METRICS[key_b][0]
    strength = _strength_word(abs(r))
    direction = (
        "tend to rise together"
        if r > 0
        else "tend to move in opposite directions"
    )
    return (
        f"There's {strength} pattern in your data: {label_a} and {label_b} "
        f"{direction} (r = {r:+.2f}). This is an association, not proof of "
        f"cause — but it's worth noticing."
    )


# =============================================================================
# The engine
# =============================================================================

def _within_window(
    activities: List[Dict[str, Any]],
    window_days: int,
) -> List[Dict[str, Any]]:
    """Keep only rows whose ``activity_date`` is within ``window_days`` of the
    newest row. Rows with an unparseable date are dropped."""
    dated: List[Tuple[date, Dict[str, Any]]] = []
    for row in activities:
        raw = row.get("activity_date")
        if not raw:
            continue
        try:
            d = datetime.fromisoformat(str(raw)[:10]).date()
        except (ValueError, TypeError):
            continue
        dated.append((d, row))

    if not dated:
        return []

    newest = max(d for d, _ in dated)
    cutoff_ordinal = newest.toordinal() - window_days
    return [row for d, row in dated if d.toordinal() >= cutoff_ordinal]


def compute_smart_insights(
    activities: List[Dict[str, Any]],
    window_days: int = _DEFAULT_WINDOW_DAYS,
) -> List[Dict[str, Any]]:
    """Compute ranked cross-metric correlation insights.

    Args:
        activities: ``daily_activity`` rows (any order). Each row may also
            carry a ``weight_kg`` field merged in by the caller.
        window_days: the correlation window; clamped to 30-90 days.

    Returns:
        A list (ranked best-first, at most ``_MAX_INSIGHTS``) of dicts:
          ``{"metric_a", "metric_b", "r", "n", "strength", "actionability",
          "association_only": True, "insight": <sentence>}``.
        An empty list when there is not enough paired data — a clean,
        non-fabricated empty state (edge case F33).
    """
    if not activities:
        return []

    window_days = max(_MIN_WINDOW_DAYS, min(_MAX_WINDOW_DAYS, int(window_days)))
    rows = _within_window(activities, window_days)
    if len(rows) < _MIN_PAIRED_DAYS:
        # Not enough history at all — nothing trustworthy to say.
        return []

    keys = list(_METRICS.keys())
    candidates: List[Dict[str, Any]] = []

    for i in range(len(keys)):
        for j in range(i + 1, len(keys)):
            key_a, key_b = keys[i], keys[j]
            if frozenset({key_a, key_b}) in _SUPPRESSED_PAIRS:
                continue

            getter_a = _METRICS[key_a][1]
            getter_b = _METRICS[key_b][1]

            # Build paired samples — only days where BOTH metrics are present.
            xs: List[float] = []
            ys: List[float] = []
            for row in rows:
                va = getter_a(row)
                vb = getter_b(row)
                if va is None or vb is None:
                    continue
                xs.append(va)
                ys.append(vb)

            n = len(xs)
            if n < _MIN_PAIRED_DAYS:
                continue

            r = pearson_r(xs, ys)
            if r is None or abs(r) < _MIN_ABS_R:
                continue

            actionability = _ACTIONABILITY.get(key_a, 0) + _ACTIONABILITY.get(
                key_b, 0
            )
            candidates.append(
                {
                    "metric_a": key_a,
                    "metric_b": key_b,
                    "r": round(r, 3),
                    "n": n,
                    "strength": _strength_word(abs(r)).replace("a ", ""),
                    "actionability": actionability,
                    "association_only": True,
                    "insight": _insight_sentence(key_a, key_b, r),
                }
            )

    # Rank: most actionable first, then strongest correlation, then most data.
    candidates.sort(
        key=lambda c: (c["actionability"], abs(c["r"]), c["n"]),
        reverse=True,
    )
    return candidates[:_MAX_INSIGHTS]


def top_insight_sentence(insights: List[Dict[str, Any]]) -> str:
    """Return the single best insight sentence (or "" when there are none).

    Used by ``health_activity.get_health_context_for_ai`` to append one line of
    correlation context to the coach prompt without bloating the token budget.
    """
    if not insights:
        return ""
    return insights[0].get("insight", "")


# =============================================================================
# Phase E2 — Food-to-sleep correlation
# =============================================================================
# Extends the engine with food-log derived signals correlated against the
# *next night's* sleep. ``daily_activity`` carries no caffeine/alcohol/meal-
# timing columns, so every food signal here is DERIVED deterministically from
# the ``food_logs`` rows the user already has: the ``food_items`` name array,
# the ``logged_at`` timestamp, and ``total_calories``.
#
# Hard rules (same as the Part-D engine):
#   * Only DETECTABLE signals are correlated. Caffeine/alcohol are flagged only
#     when an item name clearly matches a known keyword — an unknown food never
#     produces a false caffeine/alcohol day (edge case G36/G37).
#   * Minimum evidence: a signal needs >= ``_MIN_PAIRED_DAYS`` paired
#     (food-day, next-night-sleep) days and |r| >= ``_MIN_ABS_R``.
#   * Association only, never causation — every emitted string says so.
#   * Sparse data => empty list, never a fabricated insight.

# Caffeine content estimate per matched item, in milligrams. Deliberately
# conservative single-serving figures (USDA / FDA "Spilling the Beans" 2018):
# a brewed coffee ~95 mg, espresso shot ~64 mg, tea ~47 mg, cola ~34 mg,
# energy drink ~80 mg. The exact dose is an estimate, so the engine only ever
# correlates it as an ordinal "how much / how late" signal, never a claim.
_CAFFEINE_MG: Dict[str, float] = {
    "espresso": 64.0,
    "cold brew": 200.0,
    "coffee": 95.0,
    "latte": 128.0,
    "cappuccino": 128.0,
    "americano": 128.0,
    "macchiato": 128.0,
    "mocha": 152.0,
    "energy drink": 80.0,
    "red bull": 80.0,
    "monster": 160.0,
    "celsius": 200.0,
    "pre-workout": 200.0,
    "pre workout": 200.0,
    "matcha": 70.0,
    "green tea": 28.0,
    "black tea": 47.0,
    "tea": 47.0,
    "cola": 34.0,
    "coke": 34.0,
    "pepsi": 38.0,
    "diet coke": 46.0,
    "mountain dew": 54.0,
    "yerba mate": 85.0,
    "caffeine": 100.0,
}

# Alcohol keywords. Presence-only (a binary "drank alcohol that evening"
# signal) — the engine never estimates a blood-alcohol figure.
_ALCOHOL_KEYWORDS: Tuple[str, ...] = (
    "beer", "wine", "whiskey", "whisky", "vodka", "rum", "tequila", "gin",
    "cocktail", "margarita", "martini", "champagne", "prosecco", "cider",
    "bourbon", "brandy", "liqueur", "sangria", "mojito", "spritz", "ipa",
    "lager", "ale", "hard seltzer", "white claw", "alcohol",
)

# A "large late meal" is a meal whose calorie total clears this bar. ~800 kcal
# is a reasonable "heavy meal" threshold for a single eating occasion.
_LARGE_MEAL_KCAL = 800.0

# The food-log day is bucketed by the user's local calendar date. Late-evening
# food (caffeine/large meal eaten after this hour, user-local) is the part the
# correlation cares about — it is what could disrupt *that night's* sleep.
_EVENING_HOUR = 17  # 5pm — start of the "evening / wind-down adjacent" window

# Sentinel for "no caffeine logged after the evening cutoff that day".
_NO_LATE_CAFFEINE = 0.0

# How many ranked food->sleep insights to emit at most.
_MAX_FOOD_INSIGHTS = 4


def _parse_ts(raw: Any) -> Optional[datetime]:
    """Parse an ISO-8601 timestamp string to an aware datetime, or None.

    ``food_logs.logged_at`` is stored as a UTC ISO string with offset. We keep
    it as-is (instant-based) — the local-hour bucketing applies a fixed UTC
    offset supplied by the caller, never wall-clock subtraction (edge case A5).
    """
    if raw is None:
        return None
    try:
        s = str(raw).replace("Z", "+00:00")
        return datetime.fromisoformat(s)
    except (ValueError, TypeError):
        return None


def _item_names(food_items: Any) -> List[str]:
    """Lower-cased name strings from a ``food_logs.food_items`` JSON array.

    Each element is a dict like ``{"name": "Latte", "calories": 128, ...}``.
    Non-dict / nameless elements are skipped — never guessed."""
    names: List[str] = []
    if not isinstance(food_items, (list, tuple)):
        return names
    for it in food_items:
        if isinstance(it, dict):
            name = it.get("name")
            if isinstance(name, str) and name.strip():
                names.append(name.strip().lower())
    return names


def _caffeine_mg_for_names(names: List[str]) -> float:
    """Estimated caffeine in mg for a list of lower-cased food-item names.

    Deterministic keyword scan. A name contributes the FIRST keyword it
    matches (longest keywords checked first so "cold brew" beats "coffee").
    Unknown names contribute 0 — never a false positive (edge case G36)."""
    if not names:
        return 0.0
    keywords = sorted(_CAFFEINE_MG.keys(), key=len, reverse=True)
    total = 0.0
    for name in names:
        for kw in keywords:
            if kw in name:
                total += _CAFFEINE_MG[kw]
                break
    return total


def _has_alcohol(names: List[str]) -> bool:
    """True when any item name clearly contains an alcohol keyword."""
    for name in names:
        for kw in _ALCOHOL_KEYWORDS:
            if kw in name:
                return True
    return False


def _local_hour(ts: datetime, utc_offset_hours: float) -> int:
    """User-local hour-of-day (0-23) for an aware UTC timestamp."""
    shifted = ts + timedelta(hours=utc_offset_hours)
    return shifted.hour


def _local_date(ts: datetime, utc_offset_hours: float) -> date:
    """User-local calendar date for an aware UTC timestamp."""
    return (ts + timedelta(hours=utc_offset_hours)).date()


def _build_food_day_signals(
    food_logs: List[Dict[str, Any]],
    utc_offset_hours: float,
) -> Dict[date, Dict[str, Any]]:
    """Collapse raw ``food_logs`` rows into one signal bundle per local date.

    Each bundle:
      ``late_caffeine_mg``  — caffeine (mg) from items logged at/after
                              ``_EVENING_HOUR`` local; 0 when none.
      ``had_alcohol_evening`` — True if any alcohol item was logged in the
                              evening window.
      ``had_large_late_meal`` — True if a meal logged in the evening window
                              cleared ``_LARGE_MEAL_KCAL``.
      ``last_meal_hour``    — the latest local hour any food was logged that
                              day (a "how late did you eat" proxy), or None.

    Only days with at least one parseable food row appear. Days with no
    detectable evening food still appear with zero/False signals — that is a
    legitimate "ate nothing late" data point for the correlation.
    """
    by_day: Dict[date, Dict[str, Any]] = {}
    for row in food_logs or []:
        ts = _parse_ts(row.get("logged_at"))
        if ts is None:
            continue
        day = _local_date(ts, utc_offset_hours)
        hour = _local_hour(ts, utc_offset_hours)
        names = _item_names(row.get("food_items"))

        bundle = by_day.setdefault(
            day,
            {
                "late_caffeine_mg": 0.0,
                "had_alcohol_evening": False,
                "had_large_late_meal": False,
                "last_meal_hour": None,
            },
        )

        # "Last meal hour" tracks the latest eating occasion of the day.
        prev = bundle["last_meal_hour"]
        if prev is None or hour > prev:
            bundle["last_meal_hour"] = hour

        is_evening = hour >= _EVENING_HOUR
        if is_evening:
            bundle["late_caffeine_mg"] += _caffeine_mg_for_names(names)
            if _has_alcohol(names):
                bundle["had_alcohol_evening"] = True
            kcal = _num(row.get("total_calories"))
            if kcal is not None and kcal >= _LARGE_MEAL_KCAL:
                bundle["had_large_late_meal"] = True

    return by_day


# Sleep-quality getters for a ``daily_activity`` row — the *outcome* side of
# the food->sleep correlation. Each returns None when the metric is absent.
def _sleep_minutes(row: Dict[str, Any]) -> Optional[float]:
    return _num(row.get("sleep_minutes"))


def _sleep_latency(row: Dict[str, Any]) -> Optional[float]:
    return _num(row.get("sleep_latency_minutes"))


def _sleep_efficiency(row: Dict[str, Any]) -> Optional[float]:
    return _num(row.get("sleep_efficiency"))


# Each food signal: key -> (human label, getter, "higher value" phrasing).
# ``getter`` maps a food-day bundle to a daily scalar (None => drop the day).
def _fs_late_caffeine(b: Dict[str, Any]) -> Optional[float]:
    return _num(b.get("late_caffeine_mg"))


def _fs_alcohol(b: Dict[str, Any]) -> Optional[float]:
    v = b.get("had_alcohol_evening")
    return 1.0 if v else 0.0


def _fs_large_meal(b: Dict[str, Any]) -> Optional[float]:
    v = b.get("had_large_late_meal")
    return 1.0 if v else 0.0


def _fs_last_meal_hour(b: Dict[str, Any]) -> Optional[float]:
    return _num(b.get("last_meal_hour"))


# (label, getter, units-noun) — units-noun is used purely for copy.
_FOOD_SIGNALS: Dict[str, Tuple[str, Any, str]] = {
    "late_caffeine": ("evening caffeine", _fs_late_caffeine, "mg"),
    "evening_alcohol": ("evening alcohol", _fs_alcohol, ""),
    "large_late_meal": ("a large late meal", _fs_large_meal, ""),
    "late_eating": ("eating later in the day", _fs_last_meal_hour, "h"),
}

# (label, getter, higher_is_better) for the sleep-outcome side.
_SLEEP_OUTCOMES: Dict[str, Tuple[str, Any, bool]] = {
    "sleep_duration": ("sleep duration", _sleep_minutes, True),
    "sleep_latency": ("how long it took to fall asleep", _sleep_latency, False),
    "sleep_efficiency": ("sleep efficiency", _sleep_efficiency, True),
}


def _food_sleep_sentence(
    food_key: str,
    outcome_key: str,
    r: float,
    n: int,
    mean_diff: Optional[float],
) -> str:
    """Association-only insight for a food-signal <-> next-night-sleep pair.

    When a concrete contrast figure is available (``mean_diff`` — the average
    gap in the sleep metric between the higher-signal and lower-signal nights)
    the sentence quotes it; otherwise it falls back to a strength/direction
    phrasing. Either way it is framed as an observed pattern, never a cause."""
    food_label = _FOOD_SIGNALS[food_key][0]
    outcome_label = _SLEEP_OUTCOMES[outcome_key][0]
    strength = _strength_word(abs(r))

    if mean_diff is not None and abs(mean_diff) >= 1.0:
        if outcome_key == "sleep_duration":
            return (
                f"On days with more {food_label}, you slept about "
                f"{abs(mean_diff):.0f} min {'less' if mean_diff < 0 else 'more'} "
                f"the following night, on average ({n} nights compared). "
                f"This is an association in your own data, not proof of cause."
            )
        if outcome_key == "sleep_latency":
            return (
                f"On days with more {food_label}, you took about "
                f"{abs(mean_diff):.0f} min "
                f"{'longer' if mean_diff > 0 else 'less time'} to fall asleep "
                f"that night, on average ({n} nights compared). "
                f"This is an association, not proof of cause."
            )
        # efficiency — mean_diff is a 0-1 fraction; show points.
        pts = abs(mean_diff) * 100.0
        return (
            f"On days with more {food_label}, your sleep efficiency ran about "
            f"{pts:.0f} points {'lower' if mean_diff < 0 else 'higher'} that "
            f"night, on average ({n} nights compared). This is an "
            f"association, not proof of cause."
        )

    direction = (
        "tends to line up with worse sleep"
        if (r > 0) != _SLEEP_OUTCOMES[outcome_key][2]
        else "tends to line up with better sleep"
    )
    return (
        f"There's {strength} pattern in your data: {food_label} {direction} "
        f"the following night (r = {r:+.2f}, {n} nights). This is an "
        f"association, not proof of cause — but it's worth noticing."
    )


def _mean(values: List[float]) -> Optional[float]:
    return sum(values) / len(values) if values else None


def compute_food_sleep_insights(
    food_logs: List[Dict[str, Any]],
    activities: List[Dict[str, Any]],
    window_days: int = _DEFAULT_WINDOW_DAYS,
    utc_offset_hours: float = 0.0,
) -> List[Dict[str, Any]]:
    """Correlate food-log signals against the *next night's* sleep (Phase E2).

    A food-day's signals (evening caffeine dose, evening alcohol, a large late
    meal, how late the last meal was) are paired with the sleep recorded for
    the FOLLOWING calendar date — the night that food could have affected.

    Args:
        food_logs: ``food_logs`` rows (any order) — ``logged_at``,
            ``food_items``, ``total_calories``.
        activities: ``daily_activity`` rows (any order) — the sleep side.
            Sleep is attributed to its wake date (edge case A2), which is the
            ``activity_date``, so "the night after food-day D" is the row with
            ``activity_date == D + 1``.
        window_days: correlation window, clamped to 30-90 days.
        utc_offset_hours: the user's UTC offset (e.g. -5 for CDT) used to
            bucket ``logged_at`` into local calendar days / evening hours.

    Returns:
        Ranked list (best-first, at most ``_MAX_FOOD_INSIGHTS``) of dicts:
          ``{"category": "food_sleep", "food_signal", "sleep_metric", "r",
          "n", "strength", "association_only": True, "insight"}``.
        Empty when there is not enough paired data — a clean, non-fabricated
        empty state (edge case G37).
    """
    if not food_logs or not activities:
        return []

    window_days = max(_MIN_WINDOW_DAYS, min(_MAX_WINDOW_DAYS, int(window_days)))

    # Sleep rows keyed by wake (activity) date, kept within the window.
    sleep_by_date: Dict[date, Dict[str, Any]] = {}
    for row in _within_window(activities, window_days):
        raw = row.get("activity_date")
        try:
            d = datetime.fromisoformat(str(raw)[:10]).date()
        except (ValueError, TypeError):
            continue
        sleep_by_date[d] = row
    if len(sleep_by_date) < _MIN_PAIRED_DAYS:
        return []

    food_by_day = _build_food_day_signals(food_logs, utc_offset_hours)
    if not food_by_day:
        return []

    candidates: List[Dict[str, Any]] = []

    for food_key, (_, food_getter, _) in _FOOD_SIGNALS.items():
        for outcome_key, (_, sleep_getter, _) in _SLEEP_OUTCOMES.items():
            xs: List[float] = []  # food signal on day D
            ys: List[float] = []  # sleep metric on night D+1
            for food_day, bundle in food_by_day.items():
                x = food_getter(bundle)
                if x is None:
                    continue
                next_night = sleep_by_date.get(food_day + timedelta(days=1))
                if next_night is None:
                    continue
                y = sleep_getter(next_night)
                if y is None:
                    continue
                xs.append(x)
                ys.append(y)

            n = len(xs)
            if n < _MIN_PAIRED_DAYS:
                continue

            r = pearson_r(xs, ys)
            if r is None or abs(r) < _MIN_ABS_R:
                continue

            # Concrete contrast: split nights into the days whose food signal
            # was above vs at-or-below the median, and report the gap in the
            # sleep metric. Reproducible and easy to phrase honestly.
            mean_diff = _high_low_mean_diff(xs, ys)

            candidates.append(
                {
                    "category": "food_sleep",
                    "food_signal": food_key,
                    "sleep_metric": outcome_key,
                    "r": round(r, 3),
                    "n": n,
                    "strength": _strength_word(abs(r)).replace("a ", ""),
                    "association_only": True,
                    "insight": _food_sleep_sentence(
                        food_key, outcome_key, r, n, mean_diff
                    ),
                }
            )

    # Rank by strength then sample size — every pair is equally actionable
    # (all food signals are things the user can change), so |r| leads.
    candidates.sort(key=lambda c: (abs(c["r"]), c["n"]), reverse=True)
    return candidates[:_MAX_FOOD_INSIGHTS]


def _high_low_mean_diff(
    xs: List[float], ys: List[float]
) -> Optional[float]:
    """Mean of ``ys`` on the high-``xs`` days minus the mean on the low days.

    "High" = strictly above the median of ``xs``; "low" = at or below it. When
    the signal is binary (0/1) this cleanly splits the 1-days from the 0-days.
    Returns None when one side is empty (a flat signal — no contrast to draw).
    """
    if len(xs) != len(ys) or not xs:
        return None
    ordered = sorted(xs)
    mid = len(ordered) // 2
    median = (
        ordered[mid]
        if len(ordered) % 2 == 1
        else (ordered[mid - 1] + ordered[mid]) / 2.0
    )
    high = [y for x, y in zip(xs, ys) if x > median]
    low = [y for x, y in zip(xs, ys) if x <= median]
    high_mean = _mean(high)
    low_mean = _mean(low)
    if high_mean is None or low_mean is None:
        return None
    return high_mean - low_mean


# =============================================================================
# Phase E3 — Sleep x training-data insights
# =============================================================================
# Correlates a night's sleep against the user's ACTUAL logged lift performance
# the next day (top-set load, average reps, average RPE from ``performance_logs``)
# and against AI form-analysis scores (from ``media_analysis_jobs`` rows whose
# ``job_type == 'form_analysis'``).
#
# Hard rules (same gates):
#   * Performance is paired with the PRECEDING night's sleep — that night is
#     what could affect today's training. Sleep is attributed to its wake date.
#   * Minimum evidence: >= ``_MIN_PAIRED_DAYS`` paired days, |r| >= ``_MIN_ABS_R``.
#   * Form-analysis data is sparse (only submitted videos). The form-score
#     correlation is simply ABSENT when there are too few scored days — never
#     extrapolated (edge case G37).
#   * Association only, never causation.

# How many ranked sleep x training insights to emit at most.
_MAX_TRAINING_INSIGHTS = 4

# Form-score correlations get their own (smaller) minimum: form videos are
# rare, so requiring a full 14 paired days would silently drop every real
# user. 8 is still enough paired (night, scored-lift-day) points for a
# defensible direction; below it the form pair is omitted, not faked.
_MIN_FORM_PAIRED_DAYS = 8


def _performance_day_signals(
    performance_logs: List[Dict[str, Any]],
    utc_offset_hours: float,
) -> Dict[date, Dict[str, Any]]:
    """Collapse ``performance_logs`` rows into one bundle per local date.

    Each bundle:
      ``top_set_kg``  — the heaviest single working set logged that day.
      ``avg_reps``    — mean reps across the day's sets.
      ``avg_rpe``     — mean RPE across the day's sets that recorded one.

    A day with no parseable set rows does not appear. ``avg_rpe`` is None when
    no set that day recorded an RPE — RPE logging is optional, so its absence
    is normal and that day is simply dropped from the RPE pair.
    """
    raw_by_day: Dict[date, Dict[str, List[float]]] = {}
    for row in performance_logs or []:
        ts = _parse_ts(row.get("recorded_at"))
        if ts is None:
            continue
        day = _local_date(ts, utc_offset_hours)
        bucket = raw_by_day.setdefault(day, {"loads": [], "reps": [], "rpes": []})
        load = _num(row.get("weight_kg"))
        if load is not None and load > 0:
            bucket["loads"].append(load)
        reps = _num(row.get("reps_completed"))
        if reps is not None and reps > 0:
            bucket["reps"].append(reps)
        rpe = _num(row.get("rpe"))
        if rpe is not None and rpe > 0:
            bucket["rpes"].append(rpe)

    out: Dict[date, Dict[str, Any]] = {}
    for day, bucket in raw_by_day.items():
        out[day] = {
            "top_set_kg": max(bucket["loads"]) if bucket["loads"] else None,
            "avg_reps": _mean(bucket["reps"]),
            "avg_rpe": _mean(bucket["rpes"]),
        }
    return out


def _form_score_day_signals(
    form_jobs: List[Dict[str, Any]],
    utc_offset_hours: float,
) -> Dict[date, float]:
    """Mean AI form-analysis score (1-10) per local date.

    ``form_jobs`` are ``media_analysis_jobs`` rows with ``job_type ==
    'form_analysis'``. The 1-10 ``form_score`` lives in the ``result`` JSONB;
    a job is used only when it ``completed`` and its result is a real exercise
    analysis (``content_type == 'exercise'``) with a positive score — a
    "not_exercise" upload or a failed job is skipped, never scored as 0.
    """
    by_day: Dict[date, List[float]] = {}
    for job in form_jobs or []:
        if str(job.get("status")) != "completed":
            continue
        result = job.get("result")
        if not isinstance(result, dict):
            continue
        if result.get("content_type") not in (None, "exercise"):
            # An explicit "not_exercise" classification — skip it.
            continue
        score = _num(result.get("form_score"))
        if score is None or score <= 0:
            continue
        ts = _parse_ts(job.get("completed_at") or job.get("created_at"))
        if ts is None:
            continue
        day = _local_date(ts, utc_offset_hours)
        by_day.setdefault(day, []).append(score)

    return {d: _mean(v) for d, v in by_day.items() if v}  # type: ignore[misc]


# Training-performance getters over a performance-day bundle.
def _tr_top_set(b: Dict[str, Any]) -> Optional[float]:
    return _num(b.get("top_set_kg"))


def _tr_avg_reps(b: Dict[str, Any]) -> Optional[float]:
    return _num(b.get("avg_reps"))


def _tr_avg_rpe(b: Dict[str, Any]) -> Optional[float]:
    return _num(b.get("avg_rpe"))


# (label, getter, higher_is_better) for the training-outcome side.
_TRAINING_METRICS: Dict[str, Tuple[str, Any, bool]] = {
    "top_set_load": ("your heaviest set", _tr_top_set, True),
    "avg_reps": ("your average reps per set", _tr_avg_reps, True),
    # Higher RPE for the same work means it felt harder — lower is "better"
    # only loosely; polarity is used purely for phrasing.
    "avg_rpe": ("how hard your sets felt (RPE)", _tr_avg_rpe, False),
}


def _training_sleep_sentence(
    metric_key: str,
    r: float,
    n: int,
    pct_diff: Optional[float],
    is_form: bool = False,
) -> str:
    """Association-only insight for a sleep <-> next-day-training pair.

    ``pct_diff`` (when present) is ``(long_sleep_mean - short_sleep_mean) /
    short_sleep_mean * 100`` — the gap in the training metric between the
    longer-sleep and shorter-sleep days, as a percent of the short-sleep
    baseline. So a POSITIVE ``pct_diff`` means the metric ran higher after
    long sleep, i.e. it was LOWER by that same magnitude after short sleep.
    All copy below is phrased from the "after shorter sleep" point of view,
    so the short-sleep change is the *negation* of ``pct_diff``."""
    strength = _strength_word(abs(r))

    if is_form:
        if pct_diff is not None and abs(pct_diff) >= 3.0:
            # Change in form score AFTER SHORT SLEEP = -pct_diff.
            lower_after_short = pct_diff > 0
            return (
                f"After shorter nights of sleep, your AI form score tended to "
                f"run about {abs(pct_diff):.0f}% "
                f"{'lower' if lower_after_short else 'higher'} the next day, "
                f"on average ({n} sessions compared). This is an association "
                f"in your data, not proof of cause — favoring technique work "
                f"on low-sleep days may still be worth a try."
            )
        return (
            f"There's {strength} pattern in your data: sleep and your next-day "
            f"AI form score move together (r = {r:+.2f}, {n} sessions). "
            f"This is an association, not proof of cause."
        )

    metric_label = _TRAINING_METRICS[metric_key][0]
    if pct_diff is not None and abs(pct_diff) >= 2.0:
        # pct_diff > 0  => metric ran HIGHER after long sleep
        #              => metric ran LOWER after short sleep.
        lower_after_short = pct_diff > 0
        if metric_key == "avg_rpe":
            # RPE: "lower after short sleep" means the work felt EASIER; the
            # notable, plan-named pattern is RPE running HIGHER after short
            # sleep (the same training felt harder).
            if lower_after_short:
                return (
                    f"After shorter nights of sleep, {metric_label} tended to "
                    f"be about {abs(pct_diff):.0f}% lower the next day "
                    f"({n} days compared). This is an association, not proof "
                    f"of cause."
                )
            return (
                f"After shorter nights of sleep, {metric_label} tended to be "
                f"about {abs(pct_diff):.0f}% higher the next day — the same "
                f"training felt harder ({n} days compared). This is an "
                f"association, not proof of cause."
            )
        # top_set_load / avg_reps — both are "more is better" lifts.
        if lower_after_short:
            change_word = "lighter" if metric_key == "top_set_load" else "lower"
        else:
            change_word = "heavier" if metric_key == "top_set_load" else "higher"
        return (
            f"After shorter nights of sleep, {metric_label} tended to be about "
            f"{abs(pct_diff):.0f}% {change_word} the next day, on average "
            f"({n} days compared). This is an association in your own data, "
            f"not proof of cause."
        )

    direction = (
        "tend to rise together" if r > 0 else "tend to move in opposite directions"
    )
    return (
        f"There's {strength} pattern in your data: sleep and {metric_label} "
        f"{direction} the next day (r = {r:+.2f}, {n} days). This is an "
        f"association, not proof of cause — but it's worth noticing."
    )


def _high_low_pct_diff(
    sleep_xs: List[float], metric_ys: List[float]
) -> Optional[float]:
    """Percentage gap in ``metric_ys`` between long-sleep and short-sleep days.

    Splits the paired days at the median sleep duration: the metric mean on
    the longer-sleep days vs the shorter-sleep days, expressed as a percentage
    of the shorter-sleep mean. A NEGATIVE result means the metric was lower
    after short sleep (e.g. lighter top sets). Returns None when a side is
    empty or the baseline mean is zero."""
    if len(sleep_xs) != len(metric_ys) or not sleep_xs:
        return None
    ordered = sorted(sleep_xs)
    mid = len(ordered) // 2
    median = (
        ordered[mid]
        if len(ordered) % 2 == 1
        else (ordered[mid - 1] + ordered[mid]) / 2.0
    )
    long_sleep = [y for x, y in zip(sleep_xs, metric_ys) if x > median]
    short_sleep = [y for x, y in zip(sleep_xs, metric_ys) if x <= median]
    long_mean = _mean(long_sleep)
    short_mean = _mean(short_sleep)
    if long_mean is None or short_mean is None or short_mean == 0:
        return None
    # Gap as a % of the short-sleep baseline: (long - short) / short * 100.
    # Positive => metric higher after long sleep (i.e. lower after short).
    return (long_mean - short_mean) / abs(short_mean) * 100.0


def compute_training_sleep_insights(
    activities: List[Dict[str, Any]],
    performance_logs: List[Dict[str, Any]],
    form_jobs: Optional[List[Dict[str, Any]]] = None,
    window_days: int = _DEFAULT_WINDOW_DAYS,
    utc_offset_hours: float = 0.0,
) -> List[Dict[str, Any]]:
    """Correlate a night's sleep with next-day training output (Phase E3).

    A night's sleep (attributed to its wake date) is paired with the lift
    performance logged on THAT SAME calendar date — the training the night
    fueled. Three performance metrics (top-set load, average reps, average
    RPE) come from ``performance_logs``; an optional fourth correlation pairs
    sleep with the AI form-analysis score from ``media_analysis_jobs``.

    Args:
        activities: ``daily_activity`` rows — the sleep side.
        performance_logs: ``performance_logs`` rows — ``weight_kg``,
            ``reps_completed``, ``rpe``, ``recorded_at``.
        form_jobs: optional ``media_analysis_jobs`` rows with
            ``job_type == 'form_analysis'``. Sparse by nature — when too few
            scored days exist the form pair is omitted, not faked.
        window_days: correlation window, clamped to 30-90 days.
        utc_offset_hours: the user's UTC offset for local-day bucketing.

    Returns:
        Ranked list (best-first, at most ``_MAX_TRAINING_INSIGHTS``) of dicts:
          ``{"category": "sleep_training", "sleep_metric": "sleep_duration",
          "training_metric", "r", "n", "strength", "association_only": True,
          "insight"}``.
        Empty when there is not enough paired data — a clean empty state.
    """
    if not activities or not performance_logs:
        return []

    window_days = max(_MIN_WINDOW_DAYS, min(_MAX_WINDOW_DAYS, int(window_days)))

    # Sleep duration keyed by wake date, within the window. Only the duration
    # is used as the sleep side here — it is the metric with the broadest
    # coverage (latency/efficiency are often null).
    sleep_by_date: Dict[date, float] = {}
    for row in _within_window(activities, window_days):
        raw = row.get("activity_date")
        try:
            d = datetime.fromisoformat(str(raw)[:10]).date()
        except (ValueError, TypeError):
            continue
        mins = _num(row.get("sleep_minutes"))
        if mins is not None and mins > 0:
            sleep_by_date[d] = mins
    if len(sleep_by_date) < _MIN_PAIRED_DAYS:
        return []

    perf_by_day = _performance_day_signals(performance_logs, utc_offset_hours)
    if not perf_by_day:
        return []

    candidates: List[Dict[str, Any]] = []

    # --- sleep <-> logged lift performance ----------------------------------
    for metric_key, (_, getter, _) in _TRAINING_METRICS.items():
        sleep_xs: List[float] = []
        metric_ys: List[float] = []
        for perf_day, bundle in perf_by_day.items():
            sleep_mins = sleep_by_date.get(perf_day)
            if sleep_mins is None:
                continue
            y = getter(bundle)
            if y is None:
                continue
            sleep_xs.append(sleep_mins)
            metric_ys.append(y)

        n = len(sleep_xs)
        if n < _MIN_PAIRED_DAYS:
            continue
        r = pearson_r(sleep_xs, metric_ys)
        if r is None or abs(r) < _MIN_ABS_R:
            continue
        pct_diff = _high_low_pct_diff(sleep_xs, metric_ys)
        candidates.append(
            {
                "category": "sleep_training",
                "sleep_metric": "sleep_duration",
                "training_metric": metric_key,
                "r": round(r, 3),
                "n": n,
                "strength": _strength_word(abs(r)).replace("a ", ""),
                "association_only": True,
                "insight": _training_sleep_sentence(
                    metric_key, r, n, pct_diff, is_form=False
                ),
            }
        )

    # --- sleep <-> AI form-analysis score (sparse — separate lower gate) ----
    form_by_day = _form_score_day_signals(form_jobs or [], utc_offset_hours)
    if form_by_day:
        sleep_xs = []
        score_ys: List[float] = []
        for form_day, score in form_by_day.items():
            sleep_mins = sleep_by_date.get(form_day)
            if sleep_mins is None:
                continue
            sleep_xs.append(sleep_mins)
            score_ys.append(score)
        n = len(sleep_xs)
        # Sparse-data gate: a smaller minimum, and absent (not faked) below it.
        if n >= _MIN_FORM_PAIRED_DAYS:
            r = pearson_r(sleep_xs, score_ys)
            if r is not None and abs(r) >= _MIN_ABS_R:
                pct_diff = _high_low_pct_diff(sleep_xs, score_ys)
                candidates.append(
                    {
                        "category": "sleep_training",
                        "sleep_metric": "sleep_duration",
                        "training_metric": "form_score",
                        "r": round(r, 3),
                        "n": n,
                        "strength": _strength_word(abs(r)).replace("a ", ""),
                        "association_only": True,
                        "insight": _training_sleep_sentence(
                            "form_score", r, n, pct_diff, is_form=True
                        ),
                    }
                )

    candidates.sort(key=lambda c: (abs(c["r"]), c["n"]), reverse=True)
    return candidates[:_MAX_TRAINING_INSIGHTS]


# =============================================================================
# Nutrition micronutrient insight (F5) — Coach card
# =============================================================================
# A single deterministic "you're tracking low on X" line for the Coach insights
# card, gated on data coverage so missing data NEVER reads as a deficiency.
# Frames everything as "below the RDA estimate", never a diagnosis. No LLM.

# RDA fallbacks (gender-neutral adult, sourced from nutrient_rdas defaults) used
# only when a live RDA map isn't supplied. mg unless noted (µg / IU).
_MICRO_RDA_FALLBACK: Dict[str, float] = {
    "fiber_g": 28.0, "vitamin_c_mg": 85.0, "vitamin_d_iu": 800.0,
    "calcium_mg": 1000.0, "iron_mg": 14.0, "magnesium_mg": 380.0,
    "potassium_mg": 4700.0, "zinc_mg": 10.0, "vitamin_a_ug": 800.0,
    "vitamin_b12_ug": 2.4, "vitamin_b9_ug": 400.0, "omega3_g": 1.4,
}
_MICRO_LABEL: Dict[str, str] = {
    "fiber_g": "fiber", "vitamin_c_mg": "vitamin C", "vitamin_d_iu": "vitamin D",
    "calcium_mg": "calcium", "iron_mg": "iron", "magnesium_mg": "magnesium",
    "potassium_mg": "potassium", "zinc_mg": "zinc", "vitamin_a_ug": "vitamin A",
    "vitamin_b12_ug": "vitamin B12", "vitamin_b9_ug": "folate", "omega3_g": "omega-3",
}
_MIN_MICRO_COVERAGE_DAYS = 3


def compute_nutrition_micro_insight(
    food_logs: List[Dict[str, Any]],
    rda_map: Optional[Dict[str, float]] = None,
    utc_offset_hours: float = 0.0,
    window_days: int = 7,
) -> Optional[Dict[str, Any]]:
    """Return ONE deterministic micronutrient-gap insight, or None.

    Gated on coverage: needs at least ``_MIN_MICRO_COVERAGE_DAYS`` distinct
    local days that carried ANY non-null micro value. A NULL micro means
    "unknown", NOT zero, so it is excluded from both the sum and the day count.
    Returns the nutrient with the lowest avg-daily/RDA ratio that is meaningfully
    below the estimate (<70%). Framed as "below the RDA estimate" — never a
    deficiency/diagnosis. ``rda_map`` (live ``nutrient_rdas``) overrides the
    fallback when supplied. No LLM, no fabrication.
    """
    if not food_logs:
        return None

    tracked = rda_map or _MICRO_RDA_FALLBACK
    sums: Dict[str, float] = {}
    days_with_data: set = set()

    for log in food_logs:
        raw = log.get("logged_at")
        d = None
        try:
            ts = datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
            if ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
            d = (ts + timedelta(hours=utc_offset_hours)).date()
        except Exception:
            continue
        had_any = False
        for key in tracked:
            v = log.get(key)
            if v is None:
                continue
            try:
                fv = float(v)
            except (TypeError, ValueError):
                continue
            sums[key] = sums.get(key, 0.0) + fv
            if fv > 0:
                had_any = True
        if had_any and d is not None:
            days_with_data.add(d)

    if len(days_with_data) < _MIN_MICRO_COVERAGE_DAYS:
        return None  # not enough coverage — silent (NOT a zero/deficiency)

    n_days = len(days_with_data)
    worst_key = None
    worst_ratio = 1.0
    for key, rda in tracked.items():
        if not rda or rda <= 0:
            continue
        avg = sums.get(key, 0.0) / n_days
        ratio = avg / rda
        if ratio < worst_ratio:
            worst_ratio = ratio
            worst_key = key

    if worst_key is None or worst_ratio >= 0.70:
        return None  # everything at/above the RDA estimate — no gap to flag

    label = _MICRO_LABEL.get(worst_key, worst_key)
    pct = int(round(worst_ratio * 100))
    return {
        "category": "nutrition_micro",
        "nutrient_key": worst_key,
        "pct_of_rda": pct,
        "n_days": n_days,
        "association_only": False,
        "framing": "below_rda_estimate_not_deficiency",
        "insight": (
            f"Over the last {n_days} logged days you've averaged about {pct}% of "
            f"the {label} RDA estimate — an easy one to nudge up with the right foods."
        ),
    }
