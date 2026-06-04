"""
Sleep-score Python port (server-side fallback)
==============================================
A faithful Python port of the mobile app's pure ``computeSleepScore`` function
(``mobile/flutter/lib/screens/health/widgets/sleep_score.dart``). It exists for
ONE purpose: the morning sleep-score push (FEATURE 1) must name the SAME 0-100
number the in-app Sleep screen shows. The app now syncs that exact number into
``daily_activity.sleep_score`` (migration 2239), so the push reads the synced
value first. This port is used ONLY as a fallback when ``sleep_score`` is NULL
(older app build, or a sleep night that synced before the column existed).

Parity rules with the Dart original:
  * Duration   (max 50) — asleep minutes vs the user's sleep-duration goal.
                          Full marks at goal; linear scale-down for a shortfall;
                          a large over-shoot (>+90 min) is mildly penalised.
  * Restfulness (max 25) — efficiency (16) + deep+REM stage bonus (9). When
                          efficiency is unknown, the component falls back to the
                          stage bonus scaled to the full 25 — never faked.
  * Consistency (max 25) — OMITTED on the backend. The snapshot has no recent
                          mid-sleep history to compare against, so we follow the
                          app's own new-user path EXACTLY: drop the component and
                          RENORMALISE the total over the components that DO have
                          data. The result is identical to what the app shows a
                          user whose history can't supply consistency.

Returns ``None`` when there are no asleep minutes — the caller must NOT
fabricate a number (no-mock-data rule).
"""

from __future__ import annotations

from typing import Optional

# Raw component weights before any renormalisation — identical to the Dart
# constants ``_kDurationWeight`` / ``_kRestfulnessWeight`` / ``_kConsistencyWeight``.
_DURATION_WEIGHT = 50.0
_RESTFULNESS_WEIGHT = 25.0
# Consistency weight (25) is intentionally never added on the backend — see the
# module docstring. Kept as a comment so the parity with the Dart file is clear.

# Restfulness sub-shares (the Dart ``effShare`` / ``stageShare``).
_EFF_SHARE = 16.0
_STAGE_SHARE = 9.0

# Healthy deep+REM is ~45% of total asleep — the 100% anchor for the stage bonus.
_STAGE_TARGET_FRAC = 0.45

# Efficiency normalisation window: full marks at 0.95, linear down to 0 at 0.50.
_EFF_FLOOR = 0.50
_EFF_CEIL = 0.95


def _clamp(value: float, lo: float, hi: float) -> float:
    """Clamp ``value`` into ``[lo, hi]`` (mirrors Dart's ``.clamp``)."""
    if value < lo:
        return lo
    if value > hi:
        return hi
    return value


def compute_sleep_score(
    asleep_minutes: int,
    goal_minutes: int = 480,
    efficiency: Optional[float] = None,
    deep_minutes: int = 0,
    rem_minutes: int = 0,
) -> Optional[int]:
    """Compute the 0-100 sleep score, a Python port of Dart ``computeSleepScore``.

    Args:
        asleep_minutes: total minutes asleep that night (main sleep + naps).
        goal_minutes: the user's nightly sleep-duration goal (default 480 = 8h).
        efficiency: asleep / time-in-bed, 0.0-1.0; ``None`` when unknown.
        deep_minutes / rem_minutes: staged sleep minutes; 0 when un-staged.

    Returns:
        The renormalised 0-100 integer score, or ``None`` when ``asleep_minutes``
        is <= 0 (nothing to score). Consistency is always omitted on the backend
        and the total is renormalised over Duration + Restfulness — EXACTLY the
        app's new-user (no-history) path.
    """
    if asleep_minutes is None or asleep_minutes <= 0:
        return None
    goal = goal_minutes if (goal_minutes and goal_minutes > 0) else 480

    # ── Duration (max 50) ────────────────────────────────────────────────
    # Full marks at goal; linear scale-down for a shortfall; mild penalty for a
    # large over-shoot (oversleeping is a quality signal too). Identical math to
    # the Dart original.
    if asleep_minutes >= goal:
        overshoot = asleep_minutes - goal
        if overshoot <= 90:
            duration_points = _DURATION_WEIGHT
        else:
            excess = _clamp(float(overshoot - 90), 0.0, 180.0)
            duration_points = _DURATION_WEIGHT * (1.0 - 0.2 * (excess / 180.0))
    else:
        duration_points = _DURATION_WEIGHT * (asleep_minutes / goal)
    duration_points = _clamp(duration_points, 0.0, _DURATION_WEIGHT)

    # ── Restfulness (max 25) ─────────────────────────────────────────────
    # Efficiency contributes 16 of 25; the deep+REM stage proportion the other 9.
    stage_prop = (
        (deep_minutes + rem_minutes) / asleep_minutes if asleep_minutes > 0 else 0.0
    )
    stage_points = _clamp(_STAGE_SHARE * (stage_prop / _STAGE_TARGET_FRAC), 0.0, _STAGE_SHARE)

    if efficiency is not None:
        eff_norm = _clamp((efficiency - _EFF_FLOOR) / (_EFF_CEIL - _EFF_FLOOR), 0.0, 1.0)
        restfulness_points = _EFF_SHARE * eff_norm + stage_points
    else:
        # No efficiency data — fall back to the stage bonus alone, scaled to the
        # full restfulness weight so the component is honestly bounded by what we
        # actually know (Dart case 7 path).
        restfulness_points = _clamp(
            _RESTFULNESS_WEIGHT * (stage_prop / _STAGE_TARGET_FRAC),
            0.0,
            _RESTFULNESS_WEIGHT,
        )
    restfulness_points = _clamp(restfulness_points, 0.0, _RESTFULNESS_WEIGHT)

    # ── Renormalise the TOTAL over the components that have data ──────────
    # Consistency is OMITTED on the backend (no mid-sleep history in the
    # snapshot) — exactly the app's new-user path. So raw_max is Duration +
    # Restfulness only.
    raw_max = _DURATION_WEIGHT + _RESTFULNESS_WEIGHT
    raw_points = duration_points + restfulness_points
    total = round((raw_points / raw_max) * 100)
    return int(_clamp(float(total), 0.0, 100.0))
