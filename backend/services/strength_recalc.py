"""Shared strength-score recompute (FEATURE 4).

Single source of truth for "recalculate this user's strength scores from the last 90 days
of workout_logs.sets_json". BOTH the manual ``POST /strength/calculate`` endpoint and the
``crud_background_tasks.recalculate_user_strength_scores`` background task call
``_recompute_strength_for_user`` so they can never diverge again (the background task used
to read ``workouts.exercises_json`` with an ``on_conflict`` that migration 2237 DROPPED,
which produced different numbers than the endpoint).

What it does, exactly as ``scores.py`` did before extraction, plus the composite/bests
additions:
  * reads ``workout_logs.sets_json`` (status=completed, last 90d), flattened by
    ``_flatten_logs_for_strength``;
  * runs the composite muscle scorer with per-muscle context (effective 1RM via
    ``strength_exercise_bests`` decay, weekly sets, sessions_28d, distinct exercises,
    first-set age, 60d bodyweight trend);
  * writes BOTH the combined NULL-gym rows AND the per-gym rows exactly as before
    (additive — never removes the per-gym block);
  * upserts ``strength_exercise_bests`` (all_time_best = max, last_trained_at = now) and
    reads back the decayed effective 1RM.

This module imports the flatten/body-info helpers from ``api.v1.scores`` to avoid copying
their (load-bearing, format-robust) parsing logic.
"""

from __future__ import annotations

import logging
from datetime import datetime, date, timedelta, timezone
from typing import Any, Dict, List, Optional

from services.strength_calculator_service import StrengthCalculatorService

logger = logging.getLogger(__name__)


# ── Effective-1RM decay parameters (FEATURE 4) ──────────────────────────────────────────
# A muscle's carry-forward strength shouldn't read as "lost" the instant a user takes a
# week off. We decay the all-time best toward a floor:
#   * grace period: 21 days of zero decay after the best was last trained;
#   * half-life: 120 days (strength detrains slowly relative to, say, VO2max);
#   * floor: never below 65% of the all-time best (retained strength base).
_DECAY_GRACE_DAYS = 21
_DECAY_HALF_LIFE_DAYS = 120
_DECAY_FLOOR_FRACTION = 0.65


def _decayed_effective_1rm(all_time_best: float, days_since_trained: Optional[float]) -> float:
    """Return the decayed effective 1RM given days since the lift was last trained."""
    if all_time_best <= 0:
        return 0.0
    if days_since_trained is None:
        return round(all_time_best, 2)
    d = max(0.0, float(days_since_trained))
    if d <= _DECAY_GRACE_DAYS:
        return round(all_time_best, 2)
    elapsed = d - _DECAY_GRACE_DAYS
    factor = 0.5 ** (elapsed / _DECAY_HALF_LIFE_DAYS)
    floored = max(_DECAY_FLOOR_FRACTION, factor)
    return round(all_time_best * floored, 2)


def _norm_key(name: str) -> str:
    return (name or "").strip().lower()


def _days_between(later: datetime, earlier: Optional[Any]) -> Optional[float]:
    """Days between an aware `later` and a stored timestamp (str/datetime), or None."""
    if not earlier:
        return None
    try:
        if isinstance(earlier, str):
            dt = datetime.fromisoformat(earlier.replace("Z", "+00:00"))
        elif isinstance(earlier, datetime):
            dt = earlier
        else:
            return None
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return (later - dt).total_seconds() / 86400.0
    except Exception:  # noqa: BLE001
        return None


def _bodyweight_trend_pct(supabase, user_id: str, now: datetime) -> Optional[float]:
    """60-day bodyweight trend as a signed percent (latest vs ~60d-ago), or None.

    Positive = gained mass, negative = lost mass. Reads body_measurements (falls back to
    user_metrics). Returns None when there isn't enough history — the composite treats a
    missing trend as "no bodyweight context" (bwDelta = 0), never a fake 0% trend.
    """
    cutoff = (now - timedelta(days=60)).isoformat()
    rows: List[Dict[str, Any]] = []
    for table in ("body_measurements", "user_metrics"):
        try:
            resp = (
                supabase.table(table)
                .select("weight_kg, recorded_at")
                .eq("user_id", user_id)
                .gte("recorded_at", cutoff)
                .order("recorded_at", desc=False)
                .execute()
            )
            rows = [r for r in (resp.data or []) if r.get("weight_kg")]
            if rows:
                break
        except Exception:  # noqa: BLE001 - table may not exist in some envs
            continue
    if len(rows) < 2:
        return None
    try:
        first = float(rows[0]["weight_kg"])
        last = float(rows[-1]["weight_kg"])
        if first <= 0:
            return None
        return round((last - first) / first * 100.0, 2)
    except Exception:  # noqa: BLE001
        return None


def _gather_muscle_context(
    *,
    supabase,
    user_id: str,
    all_logs: List[Dict[str, Any]],
    strength_service: StrengthCalculatorService,
    bodyweight_trend_pct: Optional[float],
    previous_scores: Dict[str, Any],
    bests_by_muscle: Dict[str, Dict[str, Any]],
    now: datetime,
) -> Dict[str, Dict[str, Any]]:
    """Build per-muscle composite context from the 90d logs + bests + trend.

    Computes, per muscle group:
      weekly_sets (already on the flattened score), sessions_28d (distinct completed-at
      days in last 28d that trained the muscle), distinct_exercises_alltime, days since
      first/last set, plus the decayed effective 1RM carried from strength_exercise_bests.
    """
    from api.v1.scores import _coerce_sets_json  # local import to avoid cycle at import

    cutoff_28 = now - timedelta(days=28)

    # Per-muscle aggregation across all logs.
    sessions_days: Dict[str, set] = {}
    distinct_ex: Dict[str, set] = {}
    first_set_at: Dict[str, datetime] = {}
    last_set_at: Dict[str, datetime] = {}

    for row in all_logs:
        completed = row.get("completed_at")
        cdt = None
        if completed:
            try:
                cdt = datetime.fromisoformat(str(completed).replace("Z", "+00:00"))
                if cdt.tzinfo is None:
                    cdt = cdt.replace(tzinfo=timezone.utc)
            except Exception:  # noqa: BLE001
                cdt = None
        payload = _coerce_sets_json(row.get("sets_json"))
        if isinstance(payload, dict):
            payload = payload.get("exercises") or []
        if not isinstance(payload, list):
            continue
        for el in payload:
            if not isinstance(el, dict):
                continue
            ex_name = el.get("name") or el.get("exercise_name") or ""
            if not ex_name:
                continue
            muscles = strength_service.get_exercise_muscle_groups(ex_name, exercise_data=el)
            for mg in muscles:
                distinct_ex.setdefault(mg, set()).add(_norm_key(ex_name))
                if cdt is not None:
                    if cdt >= cutoff_28:
                        sessions_days.setdefault(mg, set()).add(cdt.date())
                    if mg not in first_set_at or cdt < first_set_at[mg]:
                        first_set_at[mg] = cdt
                    if mg not in last_set_at or cdt > last_set_at[mg]:
                        last_set_at[mg] = cdt

    ctx: Dict[str, Dict[str, Any]] = {}
    all_muscles = (
        set(sessions_days) | set(distinct_ex) | set(first_set_at) | set(bests_by_muscle)
    )
    for mg in all_muscles:
        best = bests_by_muscle.get(mg) or {}
        ctx[mg] = {
            "sessions_28d": len(sessions_days.get(mg, set())),
            "distinct_exercises_alltime": len(distinct_ex.get(mg, set())),
            "days_since_first_set": _days_between(now, first_set_at.get(mg)),
            "days_since_last_set": _days_between(now, last_set_at.get(mg)),
            "bodyweight_trend_pct": bodyweight_trend_pct,
            "previous_score": previous_scores.get(mg),
            "effective_1rm_kg": best.get("effective_1rm_kg", 0),
            "effective_1rm_exercise": best.get("exercise_key"),
            "effective_1rm_equipment": best.get("equipment"),
        }
    return ctx


def _upsert_exercise_bests(
    *,
    supabase,
    user_id: str,
    all_logs: List[Dict[str, Any]],
    strength_service: StrengthCalculatorService,
    now: datetime,
) -> Dict[str, Dict[str, Any]]:
    """Upsert strength_exercise_bests from the 90d logs and return per-muscle effective 1RMs.

    For each (exercise, gym) we track the all-time best 1RM (max over the window AND any
    previously stored best) and last_trained_at = now; we then read back the decayed
    effective 1RM and roll it up to the BEST effective per muscle group (machine-credit
    combined rule lives in scores.py for the combined/per-gym split; here we just surface
    the per-muscle carry-forward used by the combined recompute).
    """
    from api.v1.scores import _flatten_logs_for_strength

    # Best fresh 1RM per exercise from this window (combined, NULL gym for the headline).
    flattened = _flatten_logs_for_strength(all_logs)
    fresh_best: Dict[str, Dict[str, Any]] = {}
    for entry in flattened:
        name = entry.get("exercise_name", "")
        if not name:
            continue
        weight = float(entry.get("weight_kg", 0) or 0)
        reps = int(entry.get("reps", 0) or 0)
        one_rm = strength_service.calculate_1rm_average(weight, reps)
        key = _norm_key(name)
        prev = fresh_best.get(key)
        if prev is None or one_rm > prev["one_rm"]:
            fresh_best[key] = {"one_rm": one_rm, "name": name}

    # Load any existing stored bests (combined / NULL gym).
    stored: Dict[str, Dict[str, Any]] = {}
    try:
        resp = (
            supabase.table("strength_exercise_bests")
            .select("exercise_key, all_time_best_1rm_kg, best_achieved_at, last_trained_at")
            .eq("user_id", user_id)
            .is_("gym_profile_id", "null")
            .execute()
        )
        for r in (resp.data or []):
            stored[_norm_key(r.get("exercise_key", ""))] = r
    except Exception as e:  # noqa: BLE001
        logger.warning(f"strength_exercise_bests read failed (non-fatal): {e}")

    bests_by_muscle: Dict[str, Dict[str, Any]] = {}
    for key, fb in fresh_best.items():
        existing = stored.get(key)
        prior_best = float(existing.get("all_time_best_1rm_kg") or 0) if existing else 0.0
        new_best = max(prior_best, float(fb["one_rm"]))
        # If this window produced a new all-time best, best_achieved_at = now.
        if fb["one_rm"] >= prior_best:
            best_achieved = now.isoformat()
        else:
            best_achieved = (existing or {}).get("best_achieved_at") or now.isoformat()

        record = {
            "user_id": user_id,
            "exercise_key": key,
            "gym_profile_id": None,
            "all_time_best_1rm_kg": round(new_best, 2),
            "best_achieved_at": best_achieved,
            "last_trained_at": now.isoformat(),
            "effective_1rm_kg": round(new_best, 2),  # freshly trained → no decay
            "updated_at": now.isoformat(),
        }
        try:
            supabase.table("strength_exercise_bests").upsert(
                record,
                on_conflict="user_id,exercise_key,gym_profile_id",
            ).execute()
        except Exception as e:  # noqa: BLE001
            # Some Supabase setups can't on_conflict a COALESCE-backed unique index;
            # fall back to delete+insert for this row (still additive).
            logger.debug(f"bests upsert fallback for {key}: {e}")
            try:
                supabase.table("strength_exercise_bests").delete().eq(
                    "user_id", user_id
                ).eq("exercise_key", key).is_("gym_profile_id", "null").execute()
                supabase.table("strength_exercise_bests").insert(record).execute()
            except Exception as e2:  # noqa: BLE001
                logger.warning(f"bests write failed for {key}: {e2}")

        # Roll up to per-muscle effective 1RM (carry-forward = freshly trained best here).
        muscles = strength_service.get_exercise_muscle_groups(fb["name"])
        for mg in muscles:
            cur = bests_by_muscle.get(mg)
            eff = record["effective_1rm_kg"]
            if cur is None or eff > cur["effective_1rm_kg"]:
                bests_by_muscle[mg] = {
                    "effective_1rm_kg": eff,
                    "exercise_key": fb["name"],
                    "equipment": None,
                }

    # Also fold in stored exercises NOT trained this window — apply decay so a long-rested
    # lift still contributes a (decayed) carry-forward to its muscle.
    for key, r in stored.items():
        if key in fresh_best:
            continue
        atb = float(r.get("all_time_best_1rm_kg") or 0)
        days = _days_between(now, r.get("last_trained_at"))
        eff = _decayed_effective_1rm(atb, days)
        if eff <= 0:
            continue
        muscles = strength_service.get_exercise_muscle_groups(key)
        for mg in muscles:
            cur = bests_by_muscle.get(mg)
            if cur is None or eff > cur["effective_1rm_kg"]:
                bests_by_muscle[mg] = {
                    "effective_1rm_kg": eff,
                    "exercise_key": key,
                    "equipment": None,
                }

    return bests_by_muscle


def _recompute_strength_for_user(
    user_id: str,
    supabase,
    tz: str,
    *,
    today: Optional[date] = None,
) -> int:
    """Recompute + persist a user's strength scores (combined + per-gym). Returns gym count.

    This is the EXACT recompute body that used to live inline in
    ``scores.calculate_strength_scores``, extracted verbatim and extended with the
    composite context + strength_exercise_bests carry-forward. Both the endpoint and the
    background task call it so they share one implementation.
    """
    # Imported here (not at module top) to avoid a circular import: scores.py imports
    # nothing from this module at import time, but this module borrows scores helpers.
    from api.v1.scores import _flatten_logs_for_strength, get_user_body_info
    from core.timezone_utils import get_user_today

    strength_service = StrengthCalculatorService()

    if today is None:
        try:
            today = date.fromisoformat(get_user_today(tz))
        except Exception:  # noqa: BLE001
            today = datetime.now(timezone.utc).date()

    # User body info (combined column → preferences fallback).
    user_response = (
        supabase.table("users")
        .select("weight_kg, gender, preferences")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )
    if not user_response or not user_response.data:
        logger.warning(f"User not found for strength recalc: {user_id}")
        return 0
    bodyweight, gender = get_user_body_info(user_response.data)

    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(days=90)

    # gym_profile_id selected so we can compute per-gym rows; ignored by the flatten.
    logs_response = (
        supabase.table("workout_logs")
        .select("sets_json, completed_at, gym_profile_id")
        .eq("user_id", user_id)
        .eq("status", "completed")
        .gte("completed_at", cutoff.isoformat())
        .execute()
    )
    all_logs = logs_response.data or []
    workout_data = _flatten_logs_for_strength(all_logs)

    # FEATURE 4 context: bests carry-forward + bodyweight trend + per-muscle context.
    bw_trend = _bodyweight_trend_pct(supabase, user_id, now)
    bests_by_muscle = _upsert_exercise_bests(
        supabase=supabase,
        user_id=user_id,
        all_logs=all_logs,
        strength_service=strength_service,
        now=now,
    )

    # Previous combined scores (for trend + previous_score).
    previous_response = (
        supabase.table("latest_strength_scores")
        .select("muscle_group, strength_score")
        .eq("user_id", user_id)
        .execute()
    )
    previous_scores = {
        r["muscle_group"]: r["strength_score"] for r in (previous_response.data or [])
    }

    muscle_ctx = _gather_muscle_context(
        supabase=supabase,
        user_id=user_id,
        all_logs=all_logs,
        strength_service=strength_service,
        bodyweight_trend_pct=bw_trend,
        previous_scores=previous_scores,
        bests_by_muscle=bests_by_muscle,
        now=now,
    )

    # Compute combined scores with per-muscle context.
    muscle_scores = _calculate_all_with_context(
        strength_service, workout_data, bodyweight, gender, muscle_ctx
    )

    period_end = today
    period_start = period_end - timedelta(days=7)

    # Idempotency: the unique index uniq_strength_scores_user_muscle_period_gym
    # (migration 2237) allows exactly ONE row per (user, muscle, period_end, gym).
    # A user can complete two workouts in a day (or hit the manual refresh twice),
    # which re-runs this recompute for the same period_end. Without clearing the
    # day's rows first, the second run hits a 23505 duplicate-key and the recalc
    # silently fails. So delete today's rows for this user (combined here, per-gym
    # below) before re-inserting fresh ones. previous_scores was already read above
    # from the view, so day-over-day trend is preserved.
    try:
        (
            supabase.table("strength_scores")
            .delete()
            .eq("user_id", user_id)
            .eq("period_end", period_end.isoformat())
            .is_("gym_profile_id", "null")
            .execute()
        )
    except Exception as e:  # noqa: BLE001
        logger.warning(f"Combined strength_scores same-day clear failed: {e}")

    for mg, score in muscle_scores.items():
        prev_score = previous_scores.get(mg)
        if prev_score is not None:
            if score.strength_score > prev_score + 2:
                trend = "improving"
            elif score.strength_score < prev_score - 2:
                trend = "declining"
            else:
                trend = "maintaining"
            score_change = score.strength_score - prev_score
        else:
            trend = "maintaining"
            score_change = None

        record_data = {
            "user_id": user_id,
            "muscle_group": mg,
            "strength_score": score.strength_score,
            "strength_level": score.strength_level.value,
            "best_exercise_name": score.best_exercise_name,
            "best_estimated_1rm_kg": score.best_estimated_1rm_kg,
            "bodyweight_ratio": score.bodyweight_ratio,
            "weekly_sets": score.weekly_sets,
            "weekly_volume_kg": score.weekly_volume_kg,
            "previous_score": prev_score,
            "score_change": score_change,
            "trend": trend,
            "calculated_at": now.isoformat(),
            "period_start": period_start.isoformat(),
            "period_end": period_end.isoformat(),
            # FEATURE 4 additive columns.
            "is_establishing": score.is_establishing,
            "score_range_low": score.score_range_low,
            "score_range_high": score.score_range_high,
        }
        supabase.table("strength_scores").insert(record_data).execute()

    # ── ADDITIVE: per-gym strength rows (preserved byte-for-byte from scores.py) ──
    gym_count = 0
    try:
        logs_by_gym: Dict[str, List[Dict[str, Any]]] = {}
        for log in all_logs:
            gid = log.get("gym_profile_id")
            if not gid:
                continue
            logs_by_gym.setdefault(gid, []).append(log)

        # Idempotency (same rationale as the combined clear above): drop today's
        # per-gym rows for this user before re-inserting so a same-day re-run
        # replaces rather than colliding on the unique index. prev_gym_resp below
        # has no period filter, so it still reads the prior period's row.
        if logs_by_gym:
            try:
                (
                    supabase.table("strength_scores")
                    .delete()
                    .eq("user_id", user_id)
                    .eq("period_end", period_end.isoformat())
                    .not_.is_("gym_profile_id", "null")
                    .execute()
                )
            except Exception as e:  # noqa: BLE001
                logger.warning(f"Per-gym strength_scores same-day clear failed: {e}")

        for gid, gym_logs in logs_by_gym.items():
            gym_workout_data = _flatten_logs_for_strength(gym_logs)
            if not gym_workout_data:
                continue
            gym_muscle_scores = _calculate_all_with_context(
                strength_service, gym_workout_data, bodyweight, gender, muscle_ctx
            )

            prev_gym_resp = (
                supabase.table("strength_scores")
                .select("muscle_group, strength_score")
                .eq("user_id", user_id)
                .eq("gym_profile_id", gid)
                .order("calculated_at", desc=True)
                .execute()
            )
            prev_gym_scores: Dict[str, Any] = {}
            for r in (prev_gym_resp.data or []):
                mgk = r.get("muscle_group")
                if mgk and mgk not in prev_gym_scores:
                    prev_gym_scores[mgk] = r.get("strength_score")

            for mg, score in gym_muscle_scores.items():
                prev_score = prev_gym_scores.get(mg)
                if prev_score is not None:
                    if score.strength_score > prev_score + 2:
                        g_trend = "improving"
                    elif score.strength_score < prev_score - 2:
                        g_trend = "declining"
                    else:
                        g_trend = "maintaining"
                    g_change = score.strength_score - prev_score
                else:
                    g_trend = "maintaining"
                    g_change = None

                supabase.table("strength_scores").insert({
                    "user_id": user_id,
                    "gym_profile_id": gid,
                    "muscle_group": mg,
                    "strength_score": score.strength_score,
                    "strength_level": score.strength_level.value,
                    "best_exercise_name": score.best_exercise_name,
                    "best_estimated_1rm_kg": score.best_estimated_1rm_kg,
                    "bodyweight_ratio": score.bodyweight_ratio,
                    "weekly_sets": score.weekly_sets,
                    "weekly_volume_kg": score.weekly_volume_kg,
                    "previous_score": prev_score,
                    "score_change": g_change,
                    "trend": g_trend,
                    "calculated_at": now.isoformat(),
                    "period_start": period_start.isoformat(),
                    "period_end": period_end.isoformat(),
                    "is_establishing": score.is_establishing,
                    "score_range_low": score.score_range_low,
                    "score_range_high": score.score_range_high,
                }).execute()
            gym_count += 1
    except Exception as e:  # noqa: BLE001
        logger.warning(f"Per-gym strength recalc failed (combined unaffected): {e}")
        gym_count = 0

    logger.info(
        f"Recomputed strength for {user_id}: {len(muscle_scores)} muscles, "
        f"{gym_count} gym profiles"
    )
    return gym_count


def _calculate_all_with_context(
    strength_service: StrengthCalculatorService,
    workout_data: List[Dict[str, Any]],
    bodyweight: float,
    gender: str,
    muscle_ctx: Dict[str, Dict[str, Any]],
):
    """Like calculate_all_muscle_scores but threads the per-muscle composite context.

    Mirrors StrengthCalculatorService.calculate_all_muscle_scores' grouping, then calls
    the composite scorer with the matching context dict per muscle group.
    """
    from services.strength_calculator_service import MuscleGroup

    muscle_exercises: Dict[str, List[Dict]] = {mg.value: [] for mg in MuscleGroup}
    for exercise in workout_data:
        exercise_name = exercise.get("exercise_name", "")
        muscle_groups = strength_service.get_exercise_muscle_groups(
            exercise_name, exercise_data=exercise
        )
        for i, mg in enumerate(muscle_groups):
            if mg in muscle_exercises:
                weight_factor = 1.0 if i == 0 else 0.5
                exercise_copy = dict(exercise)
                exercise_copy["weight_kg"] = float(exercise.get("weight_kg", 0) or 0) * weight_factor
                muscle_exercises[mg].append(exercise_copy)

    scores = {}
    for mg in MuscleGroup:
        scores[mg.value] = strength_service.compute_composite_muscle_score(
            mg.value,
            muscle_exercises[mg.value],
            bodyweight,
            gender,
            context=muscle_ctx.get(mg.value, {}),
        )
    return scores
