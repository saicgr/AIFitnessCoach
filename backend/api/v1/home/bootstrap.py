"""
Home Screen Bootstrap API endpoint.

Returns ALL data the home screen needs in a single request, replacing 5
separate API calls (today workout, nutrition summary, hydration, XP, gym profile).

Uses asyncio.gather() to run all queries in parallel for minimal latency.
Cached in Redis for 30 minutes with explicit invalidation on data changes.
"""
from core.db import get_supabase_db
from datetime import datetime, date, timedelta
from typing import Optional, List
import asyncio
from concurrent.futures import ThreadPoolExecutor
import json

from fastapi import APIRouter, Depends, Request, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel

from core.logger import get_logger
from core.timezone_utils import resolve_timezone, get_user_today, local_date_to_utc_range
from core.redis_cache import RedisCache

# Reuse helpers from the workouts module
from api.v1.workouts.today import (
    _get_active_gym_profile_id,
    _extract_primary_muscles,
)
# Thread pool for running synchronous DB calls concurrently
_db_executor = ThreadPoolExecutor(max_workers=10)

# Redis cache — 30 minute TTL, invalidated explicitly on data changes
_bootstrap_cache = RedisCache(prefix="home_bootstrap", ttl_seconds=1800, max_size=200)

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Response models
# =============================================================================

class WorkoutSummary(BaseModel):
    """Lightweight workout summary for the home screen hero card."""
    id: str
    name: str
    type: str
    difficulty: str
    duration_minutes: int
    exercise_count: int
    exercise_names: List[str] = []
    primary_muscles: List[str] = []
    scheduled_date: str
    is_today: bool
    is_completed: bool
    generation_method: Optional[str] = None


class NutritionSummary(BaseModel):
    """Daily nutrition totals and targets."""
    calories: int = 0
    target_calories: Optional[int] = None
    protein: float = 0.0
    carbs: float = 0.0
    fat: float = 0.0
    target_protein: Optional[float] = None
    target_carbs: Optional[float] = None
    target_fat: Optional[float] = None


class HydrationSummary(BaseModel):
    """Daily hydration progress."""
    current_ml: int = 0
    target_ml: int = 2500


class XPSummary(BaseModel):
    """User XP, level, and streak info."""
    level: int = 1
    current_xp: int = 0
    xp_to_next_level: int = 150
    streak: int = 0


class GymProfileSummary(BaseModel):
    """Active gym profile info."""
    id: Optional[str] = None
    name: Optional[str] = None


class BootstrapResponse(BaseModel):
    """Aggregated home screen bootstrap payload."""
    today_workout: Optional[WorkoutSummary] = None
    nutrition_summary: NutritionSummary = NutritionSummary()
    hydration: HydrationSummary = HydrationSummary()
    xp: XPSummary = XPSummary()
    gym_profile: GymProfileSummary = GymProfileSummary()


# =============================================================================
# Cache invalidation (call from other endpoints when data changes)
# =============================================================================

async def invalidate_bootstrap_cache(user_id: str, gym_profile_id: str = None):
    """Invalidate cached bootstrap response after data changes.

    Because the cache key includes today's date, we need to know which
    date string was used. Since invalidation typically happens for "today",
    we delete with a wildcard approach: try the most likely key.
    If gym_profile_id is not provided, we attempt invalidation with 'none'.
    """
    today_str = datetime.utcnow().strftime("%Y-%m-%d")
    profile_part = gym_profile_id or "none"
    cache_key = f"{user_id}:{profile_part}:{today_str}"
    await _bootstrap_cache.delete(cache_key)
    logger.debug(f"[CACHE] Invalidated home_bootstrap for key={cache_key}")


# =============================================================================
# Data-fetching helpers (each runs in the thread-pool executor)
# =============================================================================

def _fetch_today_workout(db, user_id: str, today_str: str, user_tz: str, active_profile_id: Optional[str]) -> Optional[dict]:
    """Fetch today's workout row from DB (lightweight — no full exercises payload)."""
    try:
        today_utc_start, today_utc_end = local_date_to_utc_range(today_str, user_tz)

        # First try uncompleted workout for today
        rows = db.list_workouts(
            user_id=user_id,
            from_date=today_utc_start,
            to_date=today_utc_end,
            is_completed=False,
            limit=1,
            gym_profile_id=active_profile_id,
        )

        # If no uncompleted workout, check for completed one
        if not rows:
            rows = db.list_workouts(
                user_id=user_id,
                from_date=today_utc_start,
                to_date=today_utc_end,
                is_completed=True,
                limit=1,
                gym_profile_id=active_profile_id,
            )

        # If still nothing, get next upcoming workout
        if not rows:
            user_today_date = datetime.strptime(today_str, "%Y-%m-%d").date()
            tomorrow_str = (user_today_date + timedelta(days=1)).isoformat()
            future_end = (user_today_date + timedelta(days=30)).isoformat()
            tomorrow_utc_start, _ = local_date_to_utc_range(tomorrow_str, user_tz)
            _, future_utc_end = local_date_to_utc_range(future_end, user_tz)
            rows = db.list_workouts(
                user_id=user_id,
                from_date=tomorrow_utc_start,
                to_date=future_utc_end,
                is_completed=False,
                limit=1,
                order_asc=True,
                gym_profile_id=active_profile_id,
            )

        if rows:
            return rows[0]
        return None
    except Exception as e:
        logger.error(f"[BOOTSTRAP] Failed to fetch today workout: {e}", exc_info=True)
        return None


def _fetch_nutrition_summary(db, user_id: str, today_str: str, user_tz: str) -> dict:
    """Fetch daily nutrition summary (calories + macros) and targets."""
    try:
        summary = db.get_daily_nutrition_summary(user_id, today_str, timezone_str=user_tz)
        targets = db.get_user_nutrition_targets(user_id)
        return {
            "calories": summary.get("total_calories", 0),
            "target_calories": targets.get("daily_calorie_target"),
            "protein": summary.get("total_protein_g", 0.0),
            "carbs": summary.get("total_carbs_g", 0.0),
            "fat": summary.get("total_fat_g", 0.0),
            "target_protein": targets.get("daily_protein_target_g"),
            "target_carbs": targets.get("daily_carbs_target_g"),
            "target_fat": targets.get("daily_fat_target_g"),
        }
    except Exception as e:
        logger.error(f"[BOOTSTRAP] Failed to fetch nutrition summary: {e}", exc_info=True)
        return {}


def _fetch_hydration(db, user_id: str, today_str: str, user_tz: str) -> dict:
    """Fetch today's hydration total and goal."""
    try:
        target_date = date.fromisoformat(today_str)
        target_date_str = target_date.isoformat()

        # Try local_date column first (timezone-correct), fall back to logged_at range
        result = None
        try:
            result = db.client.table("hydration_logs").select("amount_ml").eq(
                "user_id", user_id
            ).eq(
                "local_date", target_date_str
            ).execute()
        except Exception as local_date_err:
            if "local_date" in str(local_date_err):
                result = None
            else:
                raise

        if result is None or not result.data:
            start_of_day = datetime.combine(target_date, datetime.min.time())
            end_of_day = datetime.combine(target_date, datetime.max.time())
            result = db.client.table("hydration_logs").select("amount_ml").eq(
                "user_id", user_id
            ).gte(
                "logged_at", start_of_day.isoformat()
            ).lte(
                "logged_at", end_of_day.isoformat()
            ).execute()

        current_ml = sum(row.get("amount_ml", 0) for row in (result.data or []))

        # Get user's hydration goal
        goal_ml = 2500  # default
        try:
            goal_result = db.client.table("user_settings").select("hydration_goal_ml").eq(
                "user_id", user_id
            ).single().execute()
            if goal_result.data and goal_result.data.get("hydration_goal_ml"):
                goal_ml = goal_result.data["hydration_goal_ml"]
        except Exception:
            pass  # use default

        return {"current_ml": current_ml, "target_ml": goal_ml}
    except Exception as e:
        logger.error(f"[BOOTSTRAP] Failed to fetch hydration: {e}", exc_info=True)
        return {"current_ml": 0, "target_ml": 2500}


def _fetch_xp(db, user_id: str) -> dict:
    """Fetch user XP, level, and login streak."""
    try:
        # XP data from user_xp table
        xp_data = {"level": 1, "current_xp": 0, "xp_to_next_level": 150, "streak": 0}

        try:
            xp_result = db.client.table("user_xp").select(
                "total_xp, current_level, xp_to_next_level"
            ).eq("user_id", user_id).single().execute()

            if xp_result.data:
                xp_data["level"] = xp_result.data.get("current_level", 1)
                xp_data["current_xp"] = xp_result.data.get("total_xp", 0)
                xp_data["xp_to_next_level"] = xp_result.data.get("xp_to_next_level", 150)
        except Exception:
            pass  # new user — use defaults

        # Streak from user_login_streaks table
        try:
            streak_result = db.client.table("user_login_streaks").select(
                "current_streak"
            ).eq("user_id", user_id).single().execute()

            if streak_result.data:
                xp_data["streak"] = streak_result.data.get("current_streak", 0)
        except Exception:
            pass  # no streak record — use default 0

        return xp_data
    except Exception as e:
        logger.error(f"[BOOTSTRAP] Failed to fetch XP: {e}", exc_info=True)
        return {"level": 1, "current_xp": 0, "xp_to_next_level": 150, "streak": 0}


def _fetch_gym_profile(db, user_id: str) -> dict:
    """Fetch the active gym profile id and name."""
    try:
        result = db.client.table("gym_profiles").select(
            "id, name"
        ).eq("user_id", user_id).eq("is_active", True).single().execute()

        if result.data:
            return {"id": result.data.get("id"), "name": result.data.get("name")}
    except Exception:
        pass  # no active profile
    return {"id": None, "name": None}


def _workout_row_to_summary(row: dict, today_str: str) -> WorkoutSummary:
    """Convert a DB workout row to a lightweight WorkoutSummary."""
    raw_exercises = row.get("exercises") or row.get("exercises_json") or []
    if isinstance(raw_exercises, str):
        try:
            raw_exercises = json.loads(raw_exercises)
        except (json.JSONDecodeError, TypeError):
            raw_exercises = []

    exercises = raw_exercises if isinstance(raw_exercises, list) else []

    # Extract just the names (lightweight)
    exercise_names = []
    for ex in exercises:
        if isinstance(ex, dict):
            name = ex.get("name") or ex.get("exercise_name") or ""
            if name:
                exercise_names.append(name)

    scheduled_date = str(row.get("scheduled_date", ""))[:10]

    return WorkoutSummary(
        id=row.get("id", ""),
        name=row.get("name", "Workout"),
        type=row.get("type", "strength"),
        difficulty=row.get("difficulty", "medium"),
        duration_minutes=row.get("duration_minutes", 45),
        exercise_count=len(exercises),
        exercise_names=exercise_names,
        primary_muscles=_extract_primary_muscles(exercises),
        scheduled_date=scheduled_date,
        is_today=(scheduled_date == today_str),
        is_completed=row.get("is_completed", False),
        generation_method=row.get("generation_method"),
    )


# =============================================================================
# Main endpoint
# =============================================================================

@router.get("/bootstrap", response_model=BootstrapResponse)
async def home_bootstrap(
    request: Request,
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
) -> BootstrapResponse:
    """
    Return all home screen data in one request.

    Replaces 5 separate API calls:
    - GET /workouts/today
    - GET /nutrition/summaries/daily
    - GET /hydration/daily
    - GET /progress/xp
    - GET /gym-profiles (active)

    All queries run in parallel via asyncio.gather() for minimal latency.
    Response is cached in Redis for 30 minutes.
    """
    logger.info(f"[BOOTSTRAP] Fetching home bootstrap for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)

        # Get active gym profile (needed for cache key and workout filtering)
        active_profile_id = _get_active_gym_profile_id(db, user_id)
        profile_part = active_profile_id or "none"

        # Check cache
        cache_key = f"{user_id}:{profile_part}:{today_str}"
        cached = await _bootstrap_cache.get(cache_key)
        if cached:
            logger.info(f"[BOOTSTRAP] CACHE HIT for user {user_id}")
            return BootstrapResponse(**cached)

        # Run all 5 data fetches in parallel
        loop = asyncio.get_event_loop()
        workout_row, nutrition_data, hydration_data, xp_data, gym_profile_data = await asyncio.gather(
            loop.run_in_executor(_db_executor, lambda: _fetch_today_workout(db, user_id, today_str, user_tz, active_profile_id)),
            loop.run_in_executor(_db_executor, lambda: _fetch_nutrition_summary(db, user_id, today_str, user_tz)),
            loop.run_in_executor(_db_executor, lambda: _fetch_hydration(db, user_id, today_str, user_tz)),
            loop.run_in_executor(_db_executor, lambda: _fetch_xp(db, user_id)),
            loop.run_in_executor(_db_executor, lambda: _fetch_gym_profile(db, user_id)),
        )

        # Build response
        today_workout = None
        if workout_row:
            today_workout = _workout_row_to_summary(workout_row, today_str)

        response = BootstrapResponse(
            today_workout=today_workout,
            nutrition_summary=NutritionSummary(**nutrition_data) if nutrition_data else NutritionSummary(),
            hydration=HydrationSummary(**hydration_data) if hydration_data else HydrationSummary(),
            xp=XPSummary(**xp_data) if xp_data else XPSummary(),
            gym_profile=GymProfileSummary(**gym_profile_data) if gym_profile_data else GymProfileSummary(),
        )

        # Cache the response
        await _bootstrap_cache.set(cache_key, response.dict())
        logger.info(f"[BOOTSTRAP] CACHE SET for user {user_id} ({cache_key})")

        return response

    except Exception as e:
        logger.error(f"[BOOTSTRAP] Failed for user {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "home_bootstrap")
