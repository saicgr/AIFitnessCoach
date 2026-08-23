"""Secondary endpoints for scores.  Sub-router included by main module.
Scores API Endpoints
====================
Handles strength scores, readiness scores, personal records, nutrition scores,
and combined fitness scores.

Endpoints:
- POST /readiness - Submit daily readiness check-in
- GET /readiness/{date} - Get readiness for specific date
- GET /readiness/history - Get readiness history
- GET /strength - Get all muscle group strength scores
- GET /strength/{muscle_group} - Get specific muscle strength detail
- POST /strength/calculate - Trigger strength score recalculation
- GET /personal-records - Get all personal records
- GET /personal-records/{exercise} - Get PRs for specific exercise
- GET /nutrition - Get weekly nutrition score
- POST /nutrition/calculate - Calculate nutrition score
- GET /fitness - Get overall fitness score
- POST /fitness/calculate - Calculate overall fitness score
- GET /overview - Combined dashboard data
"""
import asyncio
from typing import Any, Dict, List, Mapping, NamedTuple, Optional, Sequence
from datetime import datetime, timedelta, date
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, Request
from core.timezone_utils import user_today_date, resolve_timezone
from pydantic import BaseModel
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.db_executor import run_db, gather_db
from core.exceptions import safe_internal_error
from services.strength_calculator_service import StrengthCalculatorService, StrengthLevel
from services.personal_records_service import PersonalRecordsService
from services.nutrition_calculator_service import NutritionCalculatorService, NutritionTargets, DailyNutrition
from services.fitness_score_calculator_service import FitnessScoreCalculatorService, FitnessScore, FitnessLevel
# Used at lines 648, 650, 951 — were previously undefined names that would
# crash with NameError whenever the score-view telemetry or readiness-
# recommendation paths fired. Same pattern as scores.py:48,61.
from services.user_context_service import user_context_service, EventType
from services.ai_insights_service import ai_insights_service
from .scores_models import (
    ReadinessCheckInRequest,
    ReadinessResponse,
    ReadinessHistoryResponse,
    StrengthScoreResponse,
    AllStrengthScoresResponse,
    StrengthDetailResponse,
    PersonalRecordResponse,
    PRStatsResponse,
    NutritionScoreResponse,
    NutritionCalculateRequest,
    FitnessScoreResponse,
    FitnessScoreBreakdownResponse,
    FitnessCalculateRequest,
    ScoresOverviewResponse,
    DotsLiftDetail,
    DotsScoreResponse,
)

router = APIRouter()


# ============================================================================
# Readiness aggregation chokepoint
# ============================================================================
# `readiness_scores.readiness_score` is NULLABLE and partial rows are NORMAL:
# the mid-workout quick check-in (api/v1/workouts/reshape.py
# `_persist_checkin_gauges`) upserts on (user_id, score_date) writing only the
# gauges it collected and deliberately never computes a score. Any aggregation
# that sums the raw column therefore evaluates `int + None` -> TypeError, which
# either 500s the endpoint or — worse — gets swallowed by an enclosing
# `except Exception` and silently reports "no readiness data" to a user who has
# plenty. Every readiness average in this module goes through the helper below
# so a new call site cannot reintroduce the bug, and so "not enough data" is an
# explicit, inspectable state instead of a caught exception.


class ReadinessWindow(NamedTuple):
    """Outcome of averaging one window of readiness rows.

    `average` is None ONLY when the window holds no *scored* row. `scored_rows`
    and `unscored_rows` say which situation produced that None, so callers can
    report an honest "not enough data" rather than a swallowed failure.
    """

    average: Optional[float]
    scored_rows: int
    unscored_rows: int

    @property
    def has_signal(self) -> bool:
        """True when at least one row in the window carried a real score."""
        return self.average is not None


def average_readiness_rows(rows: Optional[Sequence[Mapping[str, Any]]]) -> ReadinessWindow:
    """Average `readiness_score` across readiness rows, skipping unscored rows.

    Unscored rows (quick check-ins that recorded gauges but no score) are
    counted, not coerced to a number — a missing score is not a zero.
    """
    scored: List[float] = []
    unscored = 0
    for row in (rows or []):
        value = row.get("readiness_score")
        if value is None:
            unscored += 1
            continue
        scored.append(float(value))
    if not scored:
        return ReadinessWindow(None, 0, unscored)
    return ReadinessWindow(sum(scored) / len(scored), len(scored), unscored)


def readiness_window_from_response(response: Any) -> ReadinessWindow:
    """`average_readiness_rows` for a PostgREST response that may itself be None."""
    return average_readiness_rows(response.data if response else None)


# The overall fitness score needs an integer readiness component even when the
# user has no readiness signal at all. `FitnessScoreCalculatorService` types
# `readiness_score: int` and its focus-recommendation picker re-applies its own
# hardcoded component weights, so passing 0 would both understate the total and
# pin every recommendation to "prioritize sleep and recovery" for someone who
# simply never checked in. The midpoint of the 0-100 scale is the only value
# that biases the weighted total in neither direction. Its use is logged at the
# call site so the substitution is never invisible.
NEUTRAL_READINESS_BASELINE = 50


@router.get("/personal-records/{exercise}", tags=["Personal Records"])
async def get_exercise_pr_history(
    exercise: str,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """Get PR history for a specific exercise."""
    db = get_supabase_db()
    pr_service = PersonalRecordsService()

    # Get all PRs for this exercise
    response = (await run_db(lambda: db.client.table("personal_records").select("*").eq(
        "user_id", user_id
    ).ilike(
        "exercise_name", f"%{exercise}%"
    ).order(
        "achieved_at", desc=True
    ).execute()))

    all_prs = response.data or []

    return pr_service.get_exercise_pr_history(exercise, all_prs)


# ============================================================================
# DOTS / Wilks Score Endpoints
# ============================================================================


class DotsLiftDetail(BaseModel):
    exercise_name: str
    estimated_1rm_kg: float


class DotsScoreResponse(BaseModel):
    dots_score: float
    wilks_score: float
    total_kg: float
    bodyweight_kg: float
    gender: str
    lifts: List[DotsLiftDetail]


@router.get("/dots", response_model=DotsScoreResponse, tags=["DOTS/Wilks"])
async def get_dots_score(
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate DOTS and Wilks scores from user's best squat, bench, and deadlift 1RMs.

    Fetches the user's stored 1RMs for the three powerlifting movements,
    sums them into a total, and applies the DOTS and Wilks formulas.
    """
    db = get_supabase_db()

    # Get user body info
    user_response = (await run_db(lambda: db.client.table("users").select(
        "weight_kg, gender, preferences"
    ).eq("id", user_id).single().execute()))

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    from .scores import get_user_body_info  # Lazy import to avoid circular import with scores.py
    bodyweight_kg, gender = get_user_body_info(user_response.data)

    # Get stored 1RMs for the big three lifts
    one_rm_response = (await run_db(lambda: db.client.table("user_exercise_1rm").select(
        "exercise_name, estimated_1rm_kg"
    ).eq("user_id", user_id).execute()))

    stored_1rms = {
        row["exercise_name"].lower().replace(" ", "_"): float(row["estimated_1rm_kg"])
        for row in (one_rm_response.data or [])
        if row.get("estimated_1rm_kg")
    }

    # Match big three lifts (with common name variants)
    squat_names = ["squat", "back_squat", "barbell_squat", "barbell_back_squat"]
    bench_names = ["bench_press", "barbell_bench_press", "flat_bench_press", "flat_barbell_bench_press"]
    deadlift_names = ["deadlift", "conventional_deadlift", "barbell_deadlift"]

    def find_best(names):
        best = 0.0
        best_name = names[0]
        for name in names:
            val = stored_1rms.get(name, 0.0)
            if val > best:
                best = val
                best_name = name
        return best_name, best

    squat_name, squat_1rm = find_best(squat_names)
    bench_name, bench_1rm = find_best(bench_names)
    deadlift_name, deadlift_1rm = find_best(deadlift_names)

    total_kg = squat_1rm + bench_1rm + deadlift_1rm

    lifts = []
    if squat_1rm > 0:
        lifts.append(DotsLiftDetail(exercise_name=squat_name, estimated_1rm_kg=squat_1rm))
    if bench_1rm > 0:
        lifts.append(DotsLiftDetail(exercise_name=bench_name, estimated_1rm_kg=bench_1rm))
    if deadlift_1rm > 0:
        lifts.append(DotsLiftDetail(exercise_name=deadlift_name, estimated_1rm_kg=deadlift_1rm))

    if total_kg <= 0:
        return DotsScoreResponse(
            dots_score=0.0,
            wilks_score=0.0,
            total_kg=0.0,
            bodyweight_kg=bodyweight_kg,
            gender=gender,
            lifts=[],
        )

    calc = StrengthCalculatorService()
    scores = calc.calculate_dots_score(bodyweight_kg, total_kg, gender)

    return DotsScoreResponse(
        dots_score=scores["dots_score"],
        wilks_score=scores["wilks_score"],
        total_kg=round(total_kg, 2),
        bodyweight_kg=bodyweight_kg,
        gender=gender,
        lifts=lifts,
    )


# ============================================================================
# Nutrition Score Endpoints
# ============================================================================

@router.get("/nutrition", response_model=NutritionScoreResponse, tags=["Nutrition"])
async def get_nutrition_score(
    http_request: Request,
    user_id: str = Query(...),
    week_start: Optional[date] = Query(None, description="Start of week (Monday)"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get weekly nutrition score for a user.

    If week_start is not provided, returns current week's score.
    """
    db = get_supabase_db()
    nutrition_service = NutritionCalculatorService()

    # Determine week range — user-local via device X-User-Timezone header.
    if week_start is None:
        tz_str = (await run_db(lambda: resolve_timezone(http_request, db, user_id)))
        week_start, week_end = nutrition_service.get_current_week_range(tz_str)
    else:
        week_end = week_start + timedelta(days=6)

    # Try to get cached score from database
    score_response = (await run_db(lambda: db.client.table("nutrition_scores").select("*").eq(
        "user_id", user_id
    ).eq(
        "week_start", week_start.isoformat()
    ).maybe_single().execute()))

    if score_response and score_response.data:
        record = score_response.data
        return NutritionScoreResponse(
            id=record["id"],
            user_id=record["user_id"],
            week_start=date.fromisoformat(record["week_start"]),
            week_end=date.fromisoformat(record["week_end"]),
            days_logged=record["days_logged"],
            total_days=record.get("total_days", 7),
            adherence_percent=record["adherence_percent"],
            calorie_adherence_percent=record.get("calorie_adherence_percent", 0),
            protein_adherence_percent=record.get("protein_adherence_percent", 0),
            carb_adherence_percent=record.get("carb_adherence_percent", 0),
            fat_adherence_percent=record.get("fat_adherence_percent", 0),
            avg_health_score=record.get("avg_health_score", 0),
            fiber_target_met_days=record.get("fiber_target_met_days", 0),
            nutrition_score=record["nutrition_score"],
            nutrition_level=record["nutrition_level"],
            ai_weekly_summary=record.get("ai_weekly_summary"),
            ai_improvement_tips=record.get("ai_improvement_tips", []),
            calculated_at=datetime.fromisoformat(record["calculated_at"]) if record.get("calculated_at") else None,
        )

    # No cached score - return empty score for this week
    return NutritionScoreResponse(
        user_id=user_id,
        week_start=week_start,
        week_end=week_end,
        days_logged=0,
        total_days=7,
        nutrition_score=0,
        nutrition_level="needs_work",
    )


@router.post("/nutrition/calculate", response_model=NutritionScoreResponse, tags=["Nutrition"])
async def calculate_nutrition_score(
    request: NutritionCalculateRequest,
    background_tasks: BackgroundTasks,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate and save weekly nutrition score.

    Analyzes food logs for the week and calculates adherence to targets.
    """
    db = get_supabase_db()
    nutrition_service = NutritionCalculatorService()
    tz_str = (await run_db(lambda: resolve_timezone(http_request, db, request.user_id)))

    # Determine week range — user-local via device X-User-Timezone header.
    if request.week_start is None:
        week_start, week_end = nutrition_service.get_current_week_range(tz_str)
    else:
        week_start = request.week_start
        week_end = week_start + timedelta(days=6)

    # Get user's nutrition targets
    user_response = (await run_db(lambda: db.client.table("users").select(
        "id, daily_calorie_target, daily_protein_target_g, daily_carbs_target_g, "
        "daily_fat_target_g, target_fiber_g"
    ).eq("id", request.user_id).maybe_single().execute()))

    if not user_response or not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = user_response.data
    targets = NutritionTargets(
        calories=int(user.get("daily_calorie_target") or 2000),
        protein_g=int(user.get("daily_protein_target_g") or 150),
        carbs_g=int(user.get("daily_carbs_target_g") or 200),
        fat_g=int(user.get("daily_fat_target_g") or 65),
        fiber_g=int(user.get("target_fiber_g") or 30),
    )

    # Get food logs for the week. food_logs timestamps rows via logged_at
    # (there is no log_date column); bound the range to the full week_start..
    # week_end days inclusive.
    food_logs_response = (await run_db(lambda: db.client.table("food_logs").select("*").eq(
        "user_id", request.user_id
    ).gte(
        "logged_at", f"{week_start.isoformat()}T00:00:00"
    ).lte(
        "logged_at", f"{week_end.isoformat()}T23:59:59"
    ).execute()))

    food_logs = food_logs_response.data or []

    # Aggregate daily nutrition from food logs
    daily_data = {}
    for log in food_logs:
        # logged_at is a timestamp; take its date component for daily bucketing.
        log_date = date.fromisoformat(log["logged_at"][:10])
        if log_date not in daily_data:
            daily_data[log_date] = DailyNutrition(
                date=log_date,
                calories=0,
                protein_g=0,
                carbs_g=0,
                fat_g=0,
                fiber_g=0,
                health_score=0,
                meals_logged=0,
            )

        daily = daily_data[log_date]
        # food_logs stores calories as total_calories (there is no `calories`
        # column — the old read silently summed 0 every week).
        daily.calories += float(log.get("total_calories") or 0)
        daily.protein_g += float(log.get("protein_g", 0))
        daily.carbs_g += float(log.get("carbs_g", 0))
        daily.fat_g += float(log.get("fat_g", 0))
        daily.fiber_g += float(log.get("fiber_g", 0))
        daily.meals_logged += 1

        # Average health score
        if log.get("health_score"):
            if daily.health_score == 0:
                daily.health_score = float(log["health_score"])
            else:
                daily.health_score = (daily.health_score + float(log["health_score"])) / 2

    # Calculate nutrition score
    score = nutrition_service.calculate_weekly_nutrition_score(
        user_id=request.user_id,
        week_start=week_start,
        week_end=week_end,
        daily_data=list(daily_data.values()),
        targets=targets,
    )

    # Get improvement tips
    tips = nutrition_service.get_improvement_tips(score)
    score.ai_improvement_tips = tips

    # Get previous week's score for comparison (user-local week).
    previous_week_start, previous_week_end = nutrition_service.get_previous_week_range(tz_str)
    try:
        previous_response = (await run_db(lambda: db.client.table("nutrition_scores").select(
            "nutrition_score"
        ).eq(
            "user_id", request.user_id
        ).eq(
            "week_start", previous_week_start.isoformat()
        ).maybe_single().execute()))
    except Exception:
        previous_response = None

    previous_score = previous_response.data.get("nutrition_score") if previous_response and previous_response.data else None

    # Save to database
    record_data = {
        "user_id": request.user_id,
        "week_start": week_start.isoformat(),
        "week_end": week_end.isoformat(),
        "days_logged": score.days_logged,
        "total_days": score.total_days,
        "adherence_percent": score.adherence_percent,
        "calorie_adherence_percent": score.calorie_adherence_percent,
        "protein_adherence_percent": score.protein_adherence_percent,
        "carb_adherence_percent": score.carb_adherence_percent,
        "fat_adherence_percent": score.fat_adherence_percent,
        "avg_health_score": score.avg_health_score,
        "fiber_target_met_days": score.fiber_target_met_days,
        "nutrition_score": score.nutrition_score,
        "nutrition_level": score.nutrition_level.value,
        "ai_improvement_tips": score.ai_improvement_tips,
        "previous_score": previous_score,
        "calculated_at": datetime.now().isoformat(),
    }

    # Upsert (update if exists for this week)
    response = (await run_db(lambda: db.client.table("nutrition_scores").upsert(
        record_data,
        on_conflict="user_id,week_start",
    ).execute()))

    if not response.data:
        raise safe_internal_error(ValueError("Failed to save nutrition score"), "scores_endpoints")

    record = response.data[0]

    return NutritionScoreResponse(
        id=record["id"],
        user_id=record["user_id"],
        week_start=date.fromisoformat(record["week_start"]),
        week_end=date.fromisoformat(record["week_end"]),
        days_logged=record["days_logged"],
        total_days=record.get("total_days", 7),
        adherence_percent=record["adherence_percent"],
        calorie_adherence_percent=record.get("calorie_adherence_percent", 0),
        protein_adherence_percent=record.get("protein_adherence_percent", 0),
        carb_adherence_percent=record.get("carb_adherence_percent", 0),
        fat_adherence_percent=record.get("fat_adherence_percent", 0),
        avg_health_score=record.get("avg_health_score", 0),
        fiber_target_met_days=record.get("fiber_target_met_days", 0),
        nutrition_score=record["nutrition_score"],
        nutrition_level=record["nutrition_level"],
        ai_weekly_summary=record.get("ai_weekly_summary"),
        ai_improvement_tips=record.get("ai_improvement_tips", []),
        calculated_at=datetime.fromisoformat(record["calculated_at"]) if record.get("calculated_at") else None,
    )


# ============================================================================
# Fitness Score Endpoints
# ============================================================================

@router.get("/fitness", response_model=FitnessScoreBreakdownResponse, tags=["Fitness"])
async def get_fitness_score(
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Get overall fitness score with breakdown.

    Returns the combined fitness score from strength, consistency, nutrition, and readiness.
    """
    db = get_supabase_db()
    fitness_service = FitnessScoreCalculatorService()

    # Get the latest fitness score from database
    score_response = (await run_db(lambda: db.client.table("fitness_scores").select("*").eq(
        "user_id", user_id
    ).order(
        "calculated_at", desc=True
    ).limit(1).maybe_single().execute()))

    if score_response and score_response.data:
        record = score_response.data
        fitness_score = FitnessScoreResponse(
            id=record["id"],
            user_id=record["user_id"],
            calculated_date=date.fromisoformat(record["calculated_date"]) if record.get("calculated_date") else None,
            strength_score=record["strength_score"],
            readiness_score=record["readiness_score"],
            consistency_score=record["consistency_score"],
            nutrition_score=record["nutrition_score"],
            overall_fitness_score=record["overall_fitness_score"],
            fitness_level=record["fitness_level"],
            ai_summary=record.get("ai_summary"),
            focus_recommendation=record.get("focus_recommendation"),
            previous_score=record.get("previous_score"),
            score_change=record.get("score_change"),
            trend=record.get("trend", "maintaining"),
            calculated_at=datetime.fromisoformat(record["calculated_at"]) if record.get("calculated_at") else None,
        )

        # Build breakdown
        score_obj = FitnessScore(
            user_id=user_id,
            strength_score=record["strength_score"],
            readiness_score=record["readiness_score"],
            consistency_score=record["consistency_score"],
            nutrition_score=record["nutrition_score"],
            overall_fitness_score=record["overall_fitness_score"],
            fitness_level=FitnessLevel(record["fitness_level"]),
        )
        breakdown = fitness_service.get_score_breakdown_display(score_obj)
        level_description = fitness_service.get_level_description(score_obj.fitness_level)
        level_color = fitness_service.get_level_color(score_obj.fitness_level)

        return FitnessScoreBreakdownResponse(
            fitness_score=fitness_score,
            breakdown=breakdown,
            level_description=level_description,
            level_color=level_color,
        )

    # No score exists - return default
    default_score = FitnessScoreResponse(
        user_id=user_id,
        overall_fitness_score=0,
        fitness_level="beginner",
    )
    return FitnessScoreBreakdownResponse(
        fitness_score=default_score,
        breakdown=[],
        level_description="Starting your fitness journey - focus on consistency.",
        level_color="#9E9E9E",
    )


@router.post("/fitness/calculate", response_model=FitnessScoreBreakdownResponse, tags=["Fitness"])
async def calculate_fitness_score(
    request: FitnessCalculateRequest,
    background_tasks: BackgroundTasks,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate and save overall fitness score.

    Combines strength, consistency, nutrition, and readiness into one score.
    """
    db = get_supabase_db()
    fitness_service = FitnessScoreCalculatorService()
    strength_service = StrengthCalculatorService()

    user_id = request.user_id
    today = user_today_date(http_request, db, user_id)

    # 1. Get strength score (overall)
    strength_response = (await run_db(lambda: db.client.table("latest_strength_scores").select(
        "muscle_group, strength_score"
    ).eq("user_id", user_id).execute()))

    if strength_response and strength_response.data:
        score_objects = {
            r["muscle_group"]: type('obj', (object,), {'strength_score': r["strength_score"] or 0})()
            for r in strength_response.data
        }
        strength_score, _ = strength_service.calculate_overall_strength_score(score_objects)
    else:
        strength_score = 0

    # 2. Get consistency score (workout completion rate for last 30 days)
    today = user_today_date(http_request, db, user_id)
    thirty_days_ago = (today - timedelta(days=30)).isoformat()

    # Count scheduled workouts
    scheduled_response = (await run_db(lambda: db.client.table("workouts").select(
        "id", count="exact"
    ).eq(
        "user_id", user_id
    ).gte(
        "scheduled_date", thirty_days_ago
    ).execute()))
    scheduled_count = scheduled_response.count or 0

    # Count completed workouts
    completed_response = (await run_db(lambda: db.client.table("workouts").select(
        "id", count="exact"
    ).eq(
        "user_id", user_id
    ).eq(
        "is_completed", True
    ).gte(
        "scheduled_date", thirty_days_ago
    ).execute()))
    completed_count = completed_response.count or 0

    consistency_score = fitness_service.calculate_consistency_score(
        scheduled=scheduled_count,
        completed=completed_count,
    )

    # 3. Get nutrition score (current week) — user-local via device X-User-Timezone header.
    tz_str = (await run_db(lambda: resolve_timezone(http_request, db, user_id)))
    from services.nutrition_calculator_service import nutrition_calculator_service
    week_start, week_end = nutrition_calculator_service.get_current_week_range(tz_str)

    try:
        nutrition_response = (await run_db(lambda: db.client.table("nutrition_scores").select(
            "nutrition_score"
        ).eq(
            "user_id", user_id
        ).eq(
            "week_start", week_start.isoformat()
        ).maybe_single().execute()))
    except Exception:
        nutrition_response = None

    if nutrition_response and nutrition_response.data:
        nutrition_score = nutrition_response.data.get("nutrition_score", 0)
    else:
        # No cached row for this week yet (e.g. never triggered, or the first
        # calculation ran before today's meals were logged). Defaulting to 0
        # here silently reported "no nutrition" for an account with real,
        # fully-logged food_logs — compute it live instead of trusting an
        # absent cache, mirroring POST /nutrition/calculate.
        try:
            live_nutrition = await calculate_nutrition_score(
                NutritionCalculateRequest(user_id=user_id, week_start=week_start),
                background_tasks,
                http_request,
                current_user,
            )
            nutrition_score = live_nutrition.nutrition_score
        except Exception:
            logger.warning(
                "Live nutrition-score fallback failed for %s; using 0", user_id,
                exc_info=True,
            )
            nutrition_score = 0

    # 4. Get readiness score (7-day average)
    seven_days_ago = (today - timedelta(days=7)).isoformat()
    readiness_response = (await run_db(lambda: db.client.table("readiness_scores").select(
        "readiness_score"
    ).eq(
        "user_id", user_id
    ).gte(
        "score_date", seven_days_ago
    ).execute()))

    readiness_window = readiness_window_from_response(readiness_response)
    if readiness_window.has_signal:
        readiness_score = round(readiness_window.average)
    else:
        # No scored row in the window — either the user never checked in, or
        # every row is an unscored mid-workout quick check-in. Say so out loud;
        # the component falls back to the scale midpoint (see the constant's
        # note) rather than to a number pretending to be the user's readiness.
        readiness_score = NEUTRAL_READINESS_BASELINE
        logger.info(
            "Fitness score for %s has no readiness signal in the 7-day window "
            "(scored=0, unscored=%d) — readiness component uses the neutral "
            "baseline %d",
            user_id, readiness_window.unscored_rows, NEUTRAL_READINESS_BASELINE,
        )

    # 5. Get previous fitness score — only a row genuinely from a prior week
    # (>=7 days back) counts as a week-over-week baseline. Without this gate,
    # a same-day/same-week recompute becomes its own "previous" score and a
    # brand-new account reports a fabricated week-over-week delta.
    one_week_ago = (today - timedelta(days=7)).isoformat()
    try:
        previous_response = (await run_db(lambda: db.client.table("fitness_scores").select(
            "overall_fitness_score"
        ).eq(
            "user_id", user_id
        ).lte(
            "calculated_date", one_week_ago
        ).order(
            "calculated_at", desc=True
        ).limit(1).maybe_single().execute()))
    except Exception:
        previous_response = None

    previous_score = previous_response.data.get("overall_fitness_score") if previous_response and previous_response.data else None

    # 6. Calculate overall fitness score
    score = fitness_service.calculate_fitness_score(
        user_id=user_id,
        strength_score=strength_score,
        readiness_score=readiness_score,
        consistency_score=consistency_score,
        nutrition_score=nutrition_score,
        timezone_str=tz_str,
        previous_score=previous_score,
    )

    # 7. Save to database
    record_data = {
        "user_id": user_id,
        "calculated_date": today.isoformat(),
        "strength_score": score.strength_score,
        "readiness_score": score.readiness_score,
        "consistency_score": score.consistency_score,
        "nutrition_score": score.nutrition_score,
        "overall_fitness_score": score.overall_fitness_score,
        "fitness_level": score.fitness_level.value,
        "strength_weight": score.strength_weight,
        "consistency_weight": score.consistency_weight,
        "nutrition_weight": score.nutrition_weight,
        "readiness_weight": score.readiness_weight,
        "focus_recommendation": score.focus_recommendation,
        "previous_score": score.previous_score,
        "score_change": score.score_change,
        "trend": score.trend,
        "calculated_at": datetime.now().isoformat(),
    }

    response = (await run_db(lambda: db.client.table("fitness_scores").insert(record_data).execute()))

    if not response.data:
        raise safe_internal_error(ValueError("Failed to save fitness score"), "scores_endpoints")

    record = response.data[0]

    # Log score calculation event
    await user_context_service.log_event(
        user_id=user_id,
        event_type=EventType.SCORE_VIEW,
        event_data={
            "action": "calculate",
            "overall_score": score.overall_fitness_score,
            "fitness_level": score.fitness_level.value,
        },
        context={"screen": "fitness_calculation"},
    )

    # Build response
    fitness_score_response = FitnessScoreResponse(
        id=record["id"],
        user_id=record["user_id"],
        calculated_date=date.fromisoformat(record["calculated_date"]),
        strength_score=record["strength_score"],
        readiness_score=record["readiness_score"],
        consistency_score=record["consistency_score"],
        nutrition_score=record["nutrition_score"],
        overall_fitness_score=record["overall_fitness_score"],
        fitness_level=record["fitness_level"],
        focus_recommendation=record.get("focus_recommendation"),
        previous_score=record.get("previous_score"),
        score_change=record.get("score_change"),
        trend=record.get("trend", "maintaining"),
        calculated_at=datetime.fromisoformat(record["calculated_at"]),
    )

    breakdown = fitness_service.get_score_breakdown_display(score)
    level_description = fitness_service.get_level_description(score.fitness_level)
    level_color = fitness_service.get_level_color(score.fitness_level)

    return FitnessScoreBreakdownResponse(
        fitness_score=fitness_score_response,
        breakdown=breakdown,
        level_description=level_description,
        level_color=level_color,
    )


# ============================================================================
# Overview Endpoint
# ============================================================================

@router.get("/overview", response_model=ScoresOverviewResponse, tags=["Overview"])
async def get_scores_overview(
    http_request: Request,
    user_id: str = Query(...),
    current_user: dict = Depends(get_current_user),
):
    """Get combined dashboard data including readiness, strength, and PRs."""
    db = get_supabase_db()
    strength_service = StrengthCalculatorService()

    # ── Run all 6 DB queries in PARALLEL using thread pool ──
    import asyncio
    from concurrent.futures import ThreadPoolExecutor
    _scores_pool = ThreadPoolExecutor(max_workers=6)
    loop = asyncio.get_event_loop()

    _today = user_today_date(http_request, db, user_id)
    today = _today.isoformat()
    thirty_days_ago = (_today - timedelta(days=30)).isoformat()
    seven_days_ago = (_today - timedelta(days=7)).isoformat()
    # User-local timezone for any week-boundary math below.
    tz_str = (await run_db(lambda: resolve_timezone(http_request, db, user_id)))

    def _q_readiness():
        try:
            return db.client.table("readiness_scores").select("*").eq("user_id", user_id).eq("score_date", today).maybe_single().execute()
        except: return None

    def _q_strength():
        try:
            return db.client.table("latest_strength_scores").select("muscle_group, strength_score").eq("user_id", user_id).execute()
        except: return None

    def _q_prs():
        try:
            return db.client.table("personal_records").select("*").eq("user_id", user_id).not_.is_("weight_kg", "null").order("achieved_at", desc=True).limit(5).execute()
        except: return None

    def _q_pr_count():
        try:
            return db.client.table("personal_records").select("id", count="exact").eq("user_id", user_id).not_.is_("weight_kg", "null").gte("achieved_at", thirty_days_ago).execute()
        except: return None

    def _q_readiness_avg():
        try:
            return db.client.table("readiness_scores").select("readiness_score").eq("user_id", user_id).gte("score_date", seven_days_ago).execute()
        except Exception as e:
            # A query failure is not "no readiness data" — log it so the two are
            # distinguishable in the logs instead of collapsing to a bare None.
            logger.warning(f"Readiness 7-day window query failed for {user_id}: {e}", exc_info=True)
            return None

    def _q_nutrition():
        try:
            ns = NutritionCalculatorService()
            ws, _ = ns.get_current_week_range(tz_str)
            return db.client.table("nutrition_scores").select("nutrition_score, nutrition_level").eq("user_id", user_id).eq("week_start", ws.isoformat()).maybe_single().execute()
        except: return None

    def _q_fitness():
        try:
            return db.client.table("fitness_scores").select("overall_fitness_score, fitness_level, consistency_score").eq("user_id", user_id).order("calculated_at", desc=True).limit(1).maybe_single().execute()
        except: return None

    (readiness_response, strength_response, pr_response,
     pr_count_response, readiness_avg_response,
     nutrition_response, fitness_response) = await asyncio.gather(
        loop.run_in_executor(_scores_pool, _q_readiness),
        loop.run_in_executor(_scores_pool, _q_strength),
        loop.run_in_executor(_scores_pool, _q_prs),
        loop.run_in_executor(_scores_pool, _q_pr_count),
        loop.run_in_executor(_scores_pool, _q_readiness_avg),
        loop.run_in_executor(_scores_pool, _q_nutrition),
        loop.run_in_executor(_scores_pool, _q_fitness),
    )

    # ── Process results ──

    today_readiness = None
    has_checked_in = False

    if readiness_response and readiness_response.data:
        has_checked_in = True
        r = readiness_response.data
        today_readiness = ReadinessResponse(
            id=r["id"],
            user_id=r["user_id"],
            score_date=date.fromisoformat(r["score_date"]),
            sleep_quality=r["sleep_quality"],
            fatigue_level=r["fatigue_level"],
            stress_level=r["stress_level"],
            muscle_soreness=r["muscle_soreness"],
            mood=r.get("mood"),
            energy_level=r.get("energy_level"),
            hooper_index=r["hooper_index"],
            readiness_score=r["readiness_score"],
            readiness_level=r["readiness_level"],
            ai_workout_recommendation=r.get("ai_workout_recommendation"),
            recommended_intensity=r.get("recommended_intensity"),
            ai_insight=r.get("ai_insight"),
            # Both columns are nullable in readiness_scores; a partial row must
            # not blow up the whole dashboard. Same guarded form as the three
            # sibling ReadinessResponse builders in scores.py.
            submitted_at=datetime.fromisoformat(r["submitted_at"]) if r.get("submitted_at") else None,
            created_at=datetime.fromisoformat(r["created_at"]) if r.get("created_at") else None,
        )

    # Process strength scores (already fetched in parallel)
    muscle_scores_summary = {}
    overall_score = 0
    overall_level = StrengthLevel.BEGINNER
    try:
        muscle_scores_summary = {
            r["muscle_group"]: r["strength_score"] or 0
            for r in (strength_response.data or []) if strength_response
        }
        if muscle_scores_summary:
            score_objects = {
                k: type('obj', (object,), {'strength_score': v})()
                for k, v in muscle_scores_summary.items()
            }
            overall_score, overall_level = strength_service.calculate_overall_strength_score(score_objects)
    except Exception as e:
        logger.warning(f"Failed to process strength scores: {e}", exc_info=True)

    # Process recent PRs (already fetched in parallel)
    recent_prs = []
    pr_count = 0
    try:
        for pr in (pr_response.data or []) if pr_response else []:
            try:
                recent_prs.append(PersonalRecordResponse(
                    id=pr["id"],
                    user_id=pr["user_id"],
                    exercise_name=pr["exercise_name"],
                    exercise_id=pr.get("exercise_id"),
                    muscle_group=pr.get("muscle_group"),
                    weight_kg=float(pr["weight_kg"]),
                    reps=int(pr["reps"]),
                    estimated_1rm_kg=float(pr["estimated_1rm_kg"]),
                    set_type=pr.get("set_type", "working"),
                    rpe=float(pr["rpe"]) if pr.get("rpe") else None,
                    achieved_at=datetime.fromisoformat(pr["achieved_at"]),
                    workout_id=pr.get("workout_id"),
                    previous_weight_kg=float(pr["previous_weight_kg"]) if pr.get("previous_weight_kg") else None,
                    previous_1rm_kg=float(pr["previous_1rm_kg"]) if pr.get("previous_1rm_kg") else None,
                    improvement_kg=float(pr["improvement_kg"]) if pr.get("improvement_kg") else None,
                    improvement_percent=float(pr["improvement_percent"]) if pr.get("improvement_percent") else None,
                    is_all_time_pr=pr.get("is_all_time_pr", True),
                    celebration_message=pr.get("celebration_message"),
                    created_at=datetime.fromisoformat(pr["created_at"]),
                ))
            except Exception as e:
                logger.warning(f"Failed to parse PR {pr.get('id')}: {e}", exc_info=True)

        # Count PRs in last 30 days (already fetched in parallel)
        pr_count = pr_count_response.count or 0 if pr_count_response else 0
    except Exception as e:
        logger.warning(f"Failed to fetch personal records: {e}", exc_info=True)

    # Process 7-day readiness average (already fetched in parallel).
    # No try/except here on purpose: the aggregation goes through the readiness
    # chokepoint, which cannot raise on unscored rows, and a genuine "no scored
    # row in the window" is reported as an explicit None — not as a swallowed
    # exception that makes a user with six scored days look like they have zero.
    readiness_window = readiness_window_from_response(readiness_avg_response)
    readiness_average = readiness_window.average
    if readiness_window.unscored_rows:
        logger.info(
            "Readiness 7-day average for %s skipped %d unscored check-in row(s); "
            "averaged %d scored row(s)",
            user_id, readiness_window.unscored_rows, readiness_window.scored_rows,
        )

    # Process nutrition score (already fetched in parallel)
    nutrition_score = None
    nutrition_level = None
    try:
        nutrition_score = nutrition_response.data.get("nutrition_score") if nutrition_response and nutrition_response.data else None
        nutrition_level = nutrition_response.data.get("nutrition_level") if nutrition_response and nutrition_response.data else None
    except Exception as e:
        logger.warning(f"Failed to fetch nutrition score: {e}", exc_info=True)

    # Process fitness score (already fetched in parallel)
    overall_fitness_score = None
    fitness_level = None
    consistency_score = None
    try:
        overall_fitness_score = fitness_response.data.get("overall_fitness_score") if fitness_response and fitness_response.data else None
        fitness_level = fitness_response.data.get("fitness_level") if fitness_response and fitness_response.data else None
        consistency_score = fitness_response.data.get("consistency_score") if fitness_response and fitness_response.data else None
    except Exception as e:
        logger.warning(f"Failed to fetch fitness score: {e}", exc_info=True)

    return ScoresOverviewResponse(
        user_id=user_id,
        today_readiness=today_readiness,
        has_checked_in_today=has_checked_in,
        overall_strength_score=overall_score,
        overall_strength_level=overall_level.value,
        muscle_scores_summary=muscle_scores_summary,
        recent_prs=recent_prs,
        pr_count_30_days=pr_count,
        readiness_average_7_days=round(readiness_average, 1) if readiness_average is not None else None,
        nutrition_score=nutrition_score,
        nutrition_level=nutrition_level,
        consistency_score=consistency_score,
        overall_fitness_score=overall_fitness_score,
        fitness_level=fitness_level,
    )


# ============================================================================
# Background Tasks
# ============================================================================

async def generate_ai_readiness_insight(
    user_id: str,
    record_id: str,
    readiness_data: Dict[str, Any],
    db,
    timezone_str: str,
):
    """
    Background task to generate AI-powered readiness recommendations.
    Updates the readiness record with the AI insight.
    """
    try:
        logger.info(f"Generating AI readiness insight for user {user_id}")

        # Get today's scheduled workout if any
        from core.timezone_utils import get_user_today
        today = get_user_today(timezone_str)
        workout_response = (await run_db(lambda: db.client.table("workouts").select(
            "name, type, duration_minutes"
        ).eq(
            "user_id", user_id
        ).eq(
            "scheduled_date", today
        ).eq(
            "is_completed", False
        ).maybe_single().execute()))

        scheduled_workout = None
        if workout_response and workout_response.data:
            w = workout_response.data
            scheduled_workout = {
                "name": w.get("name"),
                "type": w.get("type"),
                "duration_minutes": w.get("duration_minutes"),
            }

        # Get user profile
        user_response = (await run_db(lambda: db.client.table("users").select(
            "name, fitness_level, goals"
        ).eq("id", user_id).maybe_single().execute()))

        user_profile = {}
        if user_response and user_response.data:
            u = user_response.data
            user_profile = {
                "id": user_id,
                "name": u.get("name"),
                "fitness_level": u.get("fitness_level", "intermediate"),
                "goals": u.get("goals", ["general fitness"]),
            }

        # Generate AI recommendation
        ai_recommendation = await ai_insights_service.generate_readiness_recommendation(
            readiness_data=readiness_data,
            scheduled_workout=scheduled_workout,
            user_profile=user_profile,
        )

        # Update record with AI insight
        (await run_db(lambda: db.client.table("readiness_scores").update({
            "ai_insight": ai_recommendation,
        }).eq("id", record_id).execute()))

        logger.info(f"AI readiness insight saved for user {user_id}")

    except Exception as e:
        logger.error(f"Failed to generate AI readiness insight: {e}", exc_info=True)
