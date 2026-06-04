"""
Phase 4 — Score transparency endpoint.

GET /api/v1/scores/breakdown/{muscle_group}

Returns the per-exercise contribution to a muscle's strength score so the
Flutter strength_tab can render a "tap → see how each lift contributes"
drill-down. Mirrors Gravl's marketed feature: "Ability to see the logic /
exercises that are contributing to a particular muscle's strength score."

Logic is deterministic (per `feedback_no_llm_for_safety_classification` —
strength score interpretation is not LLM territory). Contribution % is:

    contribution(exercise) = e1RM(exercise) × bodyweight_ratio_weight /
                             sum(e1RM × weight for all exercises in muscle)

Reads from `strength_scores` (already populated by strength_calculator_service)
+ recent workout_logs for per-exercise e1RM trail.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple

from fastapi import APIRouter, Depends, HTTPException

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from services.fitness_score_calculator_service import (
    MUSCLE_LEVEL_THRESHOLDS,
    OVERALL_LEVEL_THRESHOLDS,
    SCORE_STALE_DAYS,
    FitnessScoreCalculatorService,
    detect_level_up,
    fitness_score_calculator_service,
)


def _brzycki_1rm(weight_kg: float, reps: int) -> float:
    """Brzycki formula — matches the one used in adaptive_workout_service_helpers."""
    if reps <= 0 or weight_kg <= 0:
        return 0.0
    if reps >= 37:  # Brzycki denominator = 37-r; clamp to avoid div-by-zero.
        return weight_kg
    return weight_kg * (36 / (37 - reps))


estimate_one_rep_max = _brzycki_1rm

logger = get_logger(__name__)
router = APIRouter()


@router.get("/scores/breakdown/{muscle_group}")
async def scores_breakdown(
    muscle_group: str,
    current_user: dict = Depends(get_current_user),
):
    """Per-exercise contribution to a muscle's strength score."""
    user_id = current_user["id"]
    muscle = muscle_group.lower().strip()
    db = get_supabase_db()

    # Pull the muscle's overall score for header.
    muscle_score_row = (
        db.client.table("strength_scores")
        .select("strength_score,strength_level,best_exercise_name,"
                "best_estimated_1rm_kg,bodyweight_ratio,weekly_sets,weekly_volume_kg,trend,"
                "calculated_at")
        .eq("user_id", user_id)
        .eq("muscle_group", muscle)
        .order("calculated_at", desc=True)
        .limit(1)
        .execute()
    )
    if not muscle_score_row.data:
        raise HTTPException(
            status_code=404,
            detail={
                "error": "no_strength_score",
                "muscle_group": muscle,
                "hint": "Log at least one workout targeting this muscle to populate the score.",
            },
        )
    header = muscle_score_row.data[0]
    # B6 — staleness flag so the UI can render a "score going stale" chip.
    header["is_stale"] = FitnessScoreCalculatorService.is_score_stale(
        header.get("calculated_at")
    )
    header["stale_days_threshold"] = SCORE_STALE_DAYS

    # Pull last-90-day logs that include this muscle.
    since = (datetime.now(timezone.utc) - timedelta(days=90)).isoformat()
    logs = (
        db.client.table("workout_logs")
        .select("performance_data,completed_at")
        .eq("user_id", user_id)
        .gte("completed_at", since)
        .execute()
    )

    # Group set entries by exercise; estimate per-exercise e1RM from best logged set.
    per_exercise_best: dict[str, dict] = {}
    for row in (logs.data or []):
        perf = row.get("performance_data") or {}
        for ex in (perf.get("exercises") or []):
            if (ex.get("primary_muscle") or "").lower() != muscle:
                continue
            name = ex.get("name") or ex.get("exercise_name")
            if not name:
                continue
            for s in (ex.get("sets") or []):
                weight = float(s.get("weight_kg") or 0)
                reps = int(s.get("reps") or 0)
                if weight <= 0 or reps <= 0:
                    continue
                e1rm = estimate_one_rep_max(weight, reps)
                cur = per_exercise_best.get(name)
                if not cur or e1rm > cur["e1rm"]:
                    per_exercise_best[name] = {
                        "exercise_name": name,
                        "best_set_weight_kg": weight,
                        "best_set_reps": reps,
                        "e1rm": round(e1rm, 1),
                        "last_logged_at": row.get("completed_at"),
                    }

    items = list(per_exercise_best.values())
    if not items:
        return {
            "header": header,
            "exercises": [],
            "note": "Strength score exists but no recent (90d) sets targeting this muscle have been logged.",
        }

    total_e1rm = sum(i["e1rm"] for i in items) or 1.0
    for i in items:
        i["contribution_pct"] = round((i["e1rm"] / total_e1rm) * 100, 1)

    items.sort(key=lambda i: i["contribution_pct"], reverse=True)

    return {
        "muscle_group": muscle,
        "header": header,
        "exercises": items,
        "exercise_count": len(items),
    }


# ---------------------------------------------------------------------------
# B6 (3) — Stale-score data source for the HOME nudge card.
# ---------------------------------------------------------------------------
@router.get("/scores/stale-muscles")
async def stale_muscles(current_user: dict = Depends(get_current_user)):
    """Muscles whose strength-score data is STALE (>SCORE_STALE_DAYS old).

    Consumed by the HOME "refresh your <muscle> score" nudge card. Excluded
    muscles (preferences.excluded_muscles) are never reported — the user opted
    out of training them. Deterministic; no LLM.
    """
    user_id = current_user["id"]
    db = get_supabase_db()

    # preferences.excluded_muscles (JSONB list on users — select '*').
    excluded: list = []
    try:
        prefs_row = (
            db.client.table("users")
            .select("preferences")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        if prefs_row.data:
            raw = (prefs_row.data[0].get("preferences") or {}).get("excluded_muscles")
            if isinstance(raw, list):
                excluded = [str(m).strip().lower() for m in raw if m]
    except Exception as exc:  # noqa: BLE001
        logger.warning("stale_muscles: could not read excluded_muscles: %s", exc)

    rows = (
        db.client.table("strength_scores")
        .select("muscle_group, strength_score, calculated_at")
        .eq("user_id", user_id)
        .order("calculated_at", desc=True)
        .execute()
    )
    # Latest row per muscle (no DISTINCT-ON in supabase-py).
    latest_by_muscle: dict = {}
    for row in (rows.data or []):
        mg = row.get("muscle_group")
        if mg and mg not in latest_by_muscle:
            latest_by_muscle[mg] = row

    stale = FitnessScoreCalculatorService.detect_stale_muscles(
        list(latest_by_muscle.values()),
        excluded_muscles=excluded,
    )
    return {
        "stale_muscles": stale,
        "stale_count": len(stale),
        "stale_days_threshold": SCORE_STALE_DAYS,
        "excluded_muscles": excluded,
    }


# ---------------------------------------------------------------------------
# B6 (2) — Recent muscle/overall level-ups for the workout-complete celebration.
# ---------------------------------------------------------------------------
@router.get("/scores/recent-level-ups")
async def recent_level_ups(current_user: dict = Depends(get_current_user)):
    """Muscles whose strength score most recently crossed UP into a new level
    band, plus the overall fitness-level crossing if any.

    Consumed by the workout-complete screen to fire a level-up celebration
    (confetti) when a workout pushed a muscle/overall score across a threshold.
    Deterministic — compares each muscle's latest `strength_score` against its
    stored `previous_score` via fitness_score_calculator.detect_level_up.

    Only rows recalculated in the last `within_minutes` window count, so the
    celebration is scoped to the just-completed workout (the completion flow
    recalculates strength scores in a background task).
    """
    user_id = current_user["id"]
    db = get_supabase_db()

    # Latest strength_scores row per muscle, with previous_score + recency.
    rows = (
        db.client.table("strength_scores")
        .select("muscle_group, strength_score, previous_score, calculated_at")
        .eq("user_id", user_id)
        .order("calculated_at", desc=True)
        .execute()
    )
    latest_by_muscle: dict = {}
    for row in (rows.data or []):
        mg = row.get("muscle_group")
        if mg and mg not in latest_by_muscle:
            latest_by_muscle[mg] = row

    # Respect excluded muscles — no celebration for an opted-out muscle.
    excluded: set = set()
    try:
        prefs_row = (
            db.client.table("users")
            .select("preferences")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        if prefs_row.data:
            raw = (prefs_row.data[0].get("preferences") or {}).get("excluded_muscles")
            if isinstance(raw, list):
                excluded = {str(m).strip().lower() for m in raw if m}
    except Exception as exc:  # noqa: BLE001
        logger.warning("recent_level_ups: could not read excluded_muscles: %s", exc)

    muscle_level_ups: list = []
    for mg, row in latest_by_muscle.items():
        if (mg or "").strip().lower() in excluded:
            continue
        new_score = int(row.get("strength_score") or 0)
        prev_score = row.get("previous_score")
        prev_score = int(prev_score) if prev_score is not None else None
        crossing = detect_level_up(
            prev_score, new_score, thresholds=MUSCLE_LEVEL_THRESHOLDS
        )
        if crossing:
            crossing["muscle_group"] = mg
            muscle_level_ups.append(crossing)

    # Overall fitness-level crossing (from the latest fitness_score row).
    overall_level_up = None
    try:
        fs = (
            db.client.table("fitness_scores")
            .select("overall_fitness_score, previous_score, calculated_at")
            .eq("user_id", user_id)
            .order("calculated_at", desc=True)
            .limit(1)
            .execute()
        )
        if fs.data:
            r = fs.data[0]
            new_overall = int(r.get("overall_fitness_score") or 0)
            prev_overall = r.get("previous_score")
            prev_overall = int(prev_overall) if prev_overall is not None else None
            overall_level_up = detect_level_up(
                prev_overall, new_overall, thresholds=OVERALL_LEVEL_THRESHOLDS
            )
    except Exception as exc:  # noqa: BLE001
        logger.warning("recent_level_ups: overall fitness_scores read failed: %s", exc)

    # Highest single-muscle jump leads the celebration headline.
    muscle_level_ups.sort(key=lambda c: c.get("new_score", 0), reverse=True)

    return {
        "muscle_level_ups": muscle_level_ups,
        "muscle_level_up_count": len(muscle_level_ups),
        "overall_level_up": overall_level_up,
        "has_any": bool(muscle_level_ups) or bool(overall_level_up),
    }


# ---------------------------------------------------------------------------
# B6 (1) — Per-exercise score TARGET for the in-workout pill.
# ---------------------------------------------------------------------------
@router.get("/scores/targets/{muscle_group}")
async def score_target(
    muscle_group: str,
    target_reps: int = 8,
    current_user: dict = Depends(get_current_user),
):
    """Deterministic weight×reps target that would raise a muscle's strength
    score into its NEXT level band.

    Shown in-workout as a pill ("Hit 80 kg × 8 to level up Chest"). The Flutter
    side converts kg→lb per the user's workout-weight unit setting. No LLM.
    """
    user_id = current_user["id"]
    muscle = muscle_group.lower().strip()
    db = get_supabase_db()

    user_response = (
        db.client.table("users")
        .select("weight_kg, gender, preferences")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )
    if not user_response or not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    user_data = user_response.data
    # Reuse the same body-info extraction the /scores endpoints use.
    from api.v1.scores import get_user_body_info
    bodyweight, gender = get_user_body_info(user_data)

    # Respect excluded muscles — no target for an opted-out muscle.
    prefs = user_data.get("preferences") or {}
    if isinstance(prefs, dict):
        excluded = {
            str(m).strip().lower()
            for m in (prefs.get("excluded_muscles") or [])
            if m
        }
        if muscle in excluded:
            return {
                "muscle_group": muscle,
                "excluded": True,
                "target": None,
                "note": "This muscle is in your excluded-muscles list.",
            }

    row = (
        db.client.table("strength_scores")
        .select("strength_score, best_exercise_name, best_estimated_1rm_kg, "
                "strength_level, calculated_at")
        .eq("user_id", user_id)
        .eq("muscle_group", muscle)
        .order("calculated_at", desc=True)
        .limit(1)
        .execute()
    )
    if not row.data:
        # No score yet → still give a beginner→novice target so the pill renders.
        current_score = 0
        best_exercise_name = ""
        best_1rm = 0.0
        is_stale = True
    else:
        r = row.data[0]
        current_score = int(r.get("strength_score") or 0)
        best_exercise_name = r.get("best_exercise_name") or ""
        best_1rm = float(r.get("best_estimated_1rm_kg") or 0)
        is_stale = FitnessScoreCalculatorService.is_score_stale(r.get("calculated_at"))

    target = fitness_score_calculator_service.compute_exercise_score_target(
        muscle_group=muscle,
        current_score=current_score,
        bodyweight_kg=bodyweight,
        gender=gender,
        best_exercise_name=best_exercise_name,
        best_estimated_1rm_kg=best_1rm,
        target_reps=target_reps,
    )
    return {
        "muscle_group": muscle,
        "excluded": False,
        "current_score": current_score,
        "is_stale": is_stale,
        "stale_days_threshold": SCORE_STALE_DAYS,
        "target": target,  # None when already elite
    }


# ---------------------------------------------------------------------------
# Per-EXERCISE strength score for the in-workout hexagon badge + best-lift card.
# Gravl parity (Image #2): a numeric score in a glowing hexagon, "Best lift from
# the last 3 months", with weight / reps / one-rep-max / date of that best set.
#
# We already have per-MUSCLE scores; this surfaces the same scoring math scoped
# to a SINGLE exercise so the active-workout screen can render it inline.
# Deterministic (no LLM) — reuses StrengthCalculatorService, the same engine
# that powers the muscle scores, so the number is consistent app-wide.
# ---------------------------------------------------------------------------
@router.get("/scores/exercise/{exercise_name}")
async def exercise_strength_score(
    exercise_name: str,
    current_user: dict = Depends(get_current_user),
):
    """Best lift (last 90 days) + a 0-100 strength score & level for one exercise."""
    from services.strength_calculator_service import (
        StrengthCalculatorService,
        strength_calculator_service,
    )

    user_id = current_user["id"]
    name = exercise_name.strip()
    db = get_supabase_db()

    # Body info drives the bodyweight-ratio classification (same as muscle scores).
    user_response = (
        db.client.table("users")
        .select("weight_kg, gender, preferences")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )
    if not user_response or not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")
    from api.v1.scores import get_user_body_info
    bodyweight, gender = get_user_body_info(user_response.data)

    since = (datetime.now(timezone.utc) - timedelta(days=90)).isoformat()
    # performance_logs is the flat per-set source (also powers exercise history).
    perf = (
        db.client.table("performance_logs")
        .select("exercise_name, reps_completed, weight_kg, recorded_at, is_pr")
        .eq("user_id", user_id)
        .ilike("exercise_name", name)  # case-insensitive exact (no wildcards)
        .gte("recorded_at", since)
        .order("recorded_at", desc=True)
        .execute()
    )
    rows = perf.data or []

    best: Optional[dict] = None
    # Best e1RM per calendar day → a small sparkline trail for the card.
    day_best: dict[str, float] = {}
    for r in rows:
        weight = float(r.get("weight_kg") or 0)
        reps = int(r.get("reps_completed") or 0)
        if weight <= 0 or reps <= 0:
            continue
        e1rm = StrengthCalculatorService.calculate_1rm_average(weight, reps)
        recorded = r.get("recorded_at")
        if best is None or e1rm > best["estimated_1rm_kg"]:
            best = {
                "weight_kg": round(weight, 1),
                "reps": reps,
                "estimated_1rm_kg": round(e1rm, 1),
                "achieved_at": recorded,
            }
        day = str(recorded or "")[:10]
        if day and e1rm > day_best.get(day, 0):
            day_best[day] = round(e1rm, 1)

    if best is None:
        return {
            "exercise_name": name,
            "has_data": False,
            "score": 0,
            "level": "beginner",
            "best": None,
            "history": [],
        }

    level, ratio, score = strength_calculator_service.classify_strength_level(
        name, best["estimated_1rm_kg"], bodyweight, gender
    )
    history = [
        {"date": d, "e1rm": v} for d, v in sorted(day_best.items())
    ][-12:]  # last 12 sessions for the sparkline

    return {
        "exercise_name": name,
        "has_data": True,
        "score": score,
        "level": level.value,
        "bodyweight_ratio": ratio,
        "best": best,
        "history": history,
    }
