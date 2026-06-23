"""
Home Screen Bootstrap API endpoint.

Returns ALL data the home screen needs in a single request, replacing 5
separate API calls (today workout, nutrition summary, hydration, XP, gym profile).

Uses asyncio.gather() to run all queries in parallel for minimal latency.
Cached in Redis for 30 minutes with explicit invalidation on data changes.
"""
from core.db import get_supabase_db
from datetime import datetime, date, timedelta
from typing import Optional, List, Dict
import asyncio
import random
from concurrent.futures import ThreadPoolExecutor
import json

from fastapi import APIRouter, Depends, Request, Query, BackgroundTasks
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.rate_limiter import user_limiter
from pydantic import BaseModel

from core.logger import get_logger
from core.timezone_utils import resolve_timezone, get_user_today, local_date_to_utc_range
from core.redis_cache import RedisCache

# Reuse helpers from the workouts module
from api.v1.workouts.today import (
    _get_active_gym_profile_id,
    _extract_primary_muscles,
)

# -----------------------------------------------------------------------------
# Thread pool for running the blocking Supabase PostgREST .execute() calls.
#
# Sizing rationale (to be confirmed by the Phase C load test):
#   * Each bootstrap request issues 5 fetches concurrently, plus 2 pre-cache-key
#     blocking calls (timezone DB lookup + active gym profile). Worst case a
#     single request that fully cache-misses occupies ~7 threads briefly, but
#     the 5 heavy fetches are the steady-state concurrency unit.
#   * Single-flight (below) collapses duplicate misses for the SAME key onto one
#     computation, and the 30-min Redis cache absorbs the vast majority of the
#     ~10k concurrent users — only genuine cache misses ever touch this pool.
#   * The Supabase connection pool / PostgREST is the real downstream limit, so
#     this pool is deliberately bounded: an unbounded pool would just convert a
#     request spike into a DB-connection storm.
#   * 32 threads => up to ~6 fully-overlapping cache-missing requests per worker
#     in flight at once (32 / 5), which comfortably covers a post-TTL-expiry
#     burst after single-flight de-duplication, without overwhelming Postgres.
# NOTE: this is a PER-WORKER pool; total DB concurrency = 32 * gunicorn workers.
_DB_EXECUTOR_MAX_WORKERS = 32
_db_executor = ThreadPoolExecutor(
    max_workers=_DB_EXECUTOR_MAX_WORKERS,
    thread_name_prefix="home_bootstrap_db",
)

# The bootstrap cache, its TTL, and `invalidate_bootstrap_cache` live in the
# leaf module `bootstrap_cache.py` so write endpoints can import the
# invalidator without a circular import (this module imports route siblings).
from api.v1.home.bootstrap_cache import (  # noqa: E402
    _BOOTSTRAP_TTL_SECONDS,
    _bootstrap_cache,
    invalidate_bootstrap_cache,  # re-exported for backward compatibility
)

# Jittered per-write (see _jittered_ttl) so that many users' entries do NOT
# expire in lockstep — synchronized expiry causes a coordinated DB burst
# ("cache stampede") every 30 min.
_BOOTSTRAP_TTL_JITTER = 0.15           # +/- 15%

# Per-key single-flight registry. When several concurrent requests miss the
# cache for the SAME key, only the first one actually runs the 5 DB fetches;
# the rest await its shared asyncio.Future. This collapses N duplicate
# computations into 1 (e.g. a user reopening Home rapidly, or a thundering
# herd right after the TTL expires). Per-worker — combined with the jittered
# TTL above this keeps DB load flat under ~10k concurrent users.
_inflight: Dict[str, "asyncio.Future"] = {}
_inflight_lock = asyncio.Lock()


def _jittered_ttl() -> int:
    """Return the bootstrap TTL with +/- _BOOTSTRAP_TTL_JITTER random spread.

    Spreading expiries prevents a synchronized cache-stampede every 30 minutes.
    """
    spread = _BOOTSTRAP_TTL_SECONDS * _BOOTSTRAP_TTL_JITTER
    return int(_BOOTSTRAP_TTL_SECONDS + random.uniform(-spread, spread))

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


# `invalidate_bootstrap_cache` now lives in `bootstrap_cache.py` (imported and
# re-exported above) so write endpoints avoid a circular import.


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
# Cache-miss computation (wrapped by the single-flight guard)
# =============================================================================

async def _compute_bootstrap(
    db, user_id: str, today_str: str, user_tz: str, active_profile_id: Optional[str]
) -> BootstrapResponse:
    """Run the 5 parallel DB fetches and assemble the BootstrapResponse.

    This is the expensive path executed only on a genuine cache miss. It is
    invoked through the single-flight guard so concurrent misses for the same
    key share ONE invocation.
    """
    loop = asyncio.get_event_loop()
    workout_row, nutrition_data, hydration_data, xp_data, gym_profile_data = await asyncio.gather(
        loop.run_in_executor(_db_executor, lambda: _fetch_today_workout(db, user_id, today_str, user_tz, active_profile_id)),
        loop.run_in_executor(_db_executor, lambda: _fetch_nutrition_summary(db, user_id, today_str, user_tz)),
        loop.run_in_executor(_db_executor, lambda: _fetch_hydration(db, user_id, today_str, user_tz)),
        loop.run_in_executor(_db_executor, lambda: _fetch_xp(db, user_id)),
        loop.run_in_executor(_db_executor, lambda: _fetch_gym_profile(db, user_id)),
    )

    today_workout = None
    if workout_row:
        today_workout = _workout_row_to_summary(workout_row, today_str)

    return BootstrapResponse(
        today_workout=today_workout,
        nutrition_summary=NutritionSummary(**nutrition_data) if nutrition_data else NutritionSummary(),
        hydration=HydrationSummary(**hydration_data) if hydration_data else HydrationSummary(),
        xp=XPSummary(**xp_data) if xp_data else XPSummary(),
        gym_profile=GymProfileSummary(**gym_profile_data) if gym_profile_data else GymProfileSummary(),
    )


# =============================================================================
# Main endpoint
# =============================================================================

@router.get("/bootstrap", response_model=BootstrapResponse)
@user_limiter.limit("60/minute")
async def home_bootstrap(
    request: Request,
    background_tasks: BackgroundTasks,
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
    Response is cached in Redis for ~30 minutes (jittered).

    Rate limited to 60/minute per user: Home is opened and refreshed often,
    but never dozens of times per second — 60/min absorbs rapid re-opens and
    background refreshes while still capping a misbehaving client. Expensive
    misses are further de-duplicated by the per-key single-flight guard below.
    """
    logger.info(f"[BOOTSTRAP] Fetching home bootstrap for user {user_id}")

    try:
        db = get_supabase_db()
        loop = asyncio.get_event_loop()

        # Stamp last_active_at (foreground app-open signal for dormancy tapering).
        # Fire-and-forget so it never adds latency, and runs even on a cache HIT
        # below — every bootstrap request means the user opened the app.
        # NOT called from any background path, so dormant users stay dormant.
        try:
            from core.locale import persist_user_last_active
            background_tasks.add_task(persist_user_last_active, user_id, db)
        except Exception:
            pass

        # resolve_timezone and _get_active_gym_profile_id are blocking and may
        # each issue a Supabase .execute(). Offload them to the DB executor so
        # they never run on the event loop (critical under ~10k concurrency).
        user_tz, active_profile_id = await asyncio.gather(
            loop.run_in_executor(_db_executor, lambda: resolve_timezone(request, db, user_id)),
            loop.run_in_executor(_db_executor, lambda: _get_active_gym_profile_id(db, user_id)),
        )
        today_str = get_user_today(user_tz)
        profile_part = active_profile_id or "none"

        # Check cache
        cache_key = f"{user_id}:{profile_part}:{today_str}"
        cached = await _bootstrap_cache.get(cache_key)
        if cached:
            logger.info(f"[BOOTSTRAP] CACHE HIT for user {user_id}")
            return BootstrapResponse(**cached)

        # ---- Single-flight on cache miss --------------------------------
        # Concurrent misses for the same cache_key collapse onto ONE shared
        # computation instead of each running all 5 DB fetches.
        async with _inflight_lock:
            existing = _inflight.get(cache_key)
            if existing is not None:
                # Another request is already computing this key — await it.
                leader_future = existing
                is_leader = False
            else:
                leader_future = loop.create_future()
                _inflight[cache_key] = leader_future
                is_leader = True

        if not is_leader:
            logger.info(f"[BOOTSTRAP] Single-flight WAIT for user {user_id} ({cache_key})")
            response = await leader_future
            return response

        # This request is the leader: it actually computes the response.
        try:
            response = await _compute_bootstrap(
                db, user_id, today_str, user_tz, active_profile_id
            )

            # Cache the response with a jittered TTL to avoid lockstep expiry.
            await _bootstrap_cache.set(
                cache_key, response.dict(), ttl_override=_jittered_ttl()
            )
            logger.info(f"[BOOTSTRAP] CACHE SET for user {user_id} ({cache_key})")

            if not leader_future.done():
                leader_future.set_result(response)
            return response
        except Exception as e:
            # Propagate the failure to every waiter so they don't hang.
            if not leader_future.done():
                leader_future.set_exception(e)
            raise
        finally:
            # Always clear the in-flight slot so future misses recompute.
            async with _inflight_lock:
                if _inflight.get(cache_key) is leader_future:
                    del _inflight[cache_key]

    except Exception as e:
        logger.error(f"[BOOTSTRAP] Failed for user {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "home_bootstrap")
