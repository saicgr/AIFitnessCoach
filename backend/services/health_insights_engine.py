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
"""

from __future__ import annotations

import logging
from datetime import date, datetime
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
