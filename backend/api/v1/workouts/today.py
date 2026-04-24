"""
Today's Workout API endpoint.

Provides a quick-start experience by returning today's scheduled workout
or the next upcoming workout.

IMPORTANT: The hero card should ALWAYS show a workout. If no workouts exist,
this endpoint will auto-generate them. There is never a scenario where
the hero card is empty.

NOTE: Workouts are filtered by active gym profile. Users only see workouts
belonging to the currently active gym profile.
"""
from core.db import get_supabase_db
from datetime import datetime, date, timedelta, timezone
from typing import Optional, List, Set
import asyncio
from concurrent.futures import ThreadPoolExecutor
import json

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel

import hashlib

from fastapi.responses import JSONResponse, Response

from core.logger import get_logger
from core.timezone_utils import resolve_timezone, get_user_today, local_date_to_utc_range
from services.user_context_service import user_context_service
from core.redis_cache import RedisCache

from .utils import parse_json_field, get_workout_focus, resolve_training_split, infer_workout_type_from_focus


# Thread pool for running synchronous DB calls concurrently
_db_executor = ThreadPoolExecutor(max_workers=15)

# Redis cache for /today responses — prevents redundant DB hits on frequent polls
_today_workout_cache = RedisCache(prefix="workout_today", ttl_seconds=1800, max_size=200)

# Short TTL for transient states (is_generating, needs_generation) to prevent poll storms
_TRANSIENT_CACHE_TTL = 30  # seconds

# Redis cache for user records — avoids Supabase query on every cache miss
_user_record_cache = RedisCache(prefix="user_record", ttl_seconds=60, max_size=200)

# Redis cache for active gym profile IDs — queried on every /today call
_gym_profile_cache = RedisCache(prefix="gym_profile", ttl_seconds=30, max_size=200)


async def invalidate_today_workout_cache(user_id: str, gym_profile_id: str = None, date: str = None):
    """Invalidate cached /today response after workout changes."""
    cache_key = f"{user_id}:{gym_profile_id or 'none'}:{date or 'unknown'}"
    await _today_workout_cache.delete(cache_key)
    # Also clear user/gym caches so next request picks up fresh data
    await _user_record_cache.delete(user_id)
    await _gym_profile_cache.delete(user_id)
    logger.debug(f"[CACHE] Invalidated workout_today + user/gym caches for key={cache_key}")


# =============================================================================
# Background auto-generation tracking
# =============================================================================
# Tracks in-flight background generation tasks to prevent duplicate calls.
# Key: "user_id:date_str:gym_profile_id", Value: True while generating.
_active_background_generations: Set[str] = set()

# Cooldown for scheduling background generation per user.
# Prevents /today polls (every 3-15s) from re-queuing generation tasks.
# Key: user_id, Value: timestamp of last scheduled generation.
_last_bg_gen_schedule: dict = {}
_BG_GEN_SCHEDULE_COOLDOWN = 30  # seconds


def _get_active_gym_profile_id(db, user_id: str) -> Optional[str]:
    """Get the active gym profile ID for a user.

    Returns None if no gym profiles exist (user hasn't set up profiles yet).
    """
    try:
        result = db.client.table("gym_profiles") \
            .select("id, name") \
            .eq("user_id", user_id) \
            .eq("is_active", True) \
            .single() \
            .execute()
        if result.data:
            return result.data.get("id")
    except Exception as e:
        # No active profile found (single() raises if no match)
        logger.debug(f"No active gym profile found: {e}")
    return None


async def _get_cached_gym_profile_id(db, user_id: str) -> Optional[str]:
    """Get active gym profile ID with Redis caching."""
    cache_key = user_id
    cached = await _gym_profile_cache.get(cache_key)
    if cached is not None:
        # Cached "none" string means no profile was found last time
        return None if cached == "__none__" else cached
    profile_id = _get_active_gym_profile_id(db, user_id)
    await _gym_profile_cache.set(cache_key, profile_id if profile_id else "__none__")
    return profile_id


def _compute_etag(response: "TodayWorkoutResponse") -> str:
    """Lightweight ETag based on workout IDs + completion + generating status."""
    parts = []
    if response.today_workout:
        parts.append(f"{response.today_workout.id}:{response.today_workout.is_completed}")
    if response.next_workout:
        parts.append(f"{response.next_workout.id}:{response.next_workout.is_completed}")
    parts.append(f"gen:{response.is_generating}")
    parts.append(f"need:{response.needs_generation}")
    return hashlib.md5("|".join(parts).encode()).hexdigest()[:16]

router = APIRouter()
logger = get_logger(__name__)


class TodayWorkoutSummary(BaseModel):
    """Summary info for quick display on home screen."""
    id: str
    name: str
    type: str
    difficulty: str
    description: Optional[str] = None
    duration_minutes: int
    exercise_count: int
    primary_muscles: List[str]
    scheduled_date: str
    is_today: bool
    is_completed: bool
    exercises: List[dict] = []  # Full exercise data for hero card preview
    generation_method: Optional[str] = None  # e.g. 'quick_rule_based', 'gemini', etc.


class TodayWorkoutResponse(BaseModel):
    """Response for today's workout endpoint."""
    has_workout_today: bool
    today_workout: Optional[TodayWorkoutSummary] = None
    next_workout: Optional[TodayWorkoutSummary] = None
    days_until_next: Optional[int] = None
    # Extra today workouts (quick workouts coexisting with scheduled workout)
    extra_today_workouts: List[TodayWorkoutSummary] = []
    # Completed workout info (if user already completed today's workout)
    completed_today: bool = False
    completed_workout: Optional[TodayWorkoutSummary] = None
    # Generation status fields
    is_generating: bool = False
    generation_message: Optional[str] = None
    # Auto-generation trigger fields
    needs_generation: bool = False
    next_workout_date: Optional[str] = None  # YYYY-MM-DD format for frontend to generate
    # Gym profile context
    gym_profile_id: Optional[str] = None  # Active gym profile ID used for filtering


def _extract_primary_muscles(exercises: list) -> List[str]:
    """Extract unique primary muscle groups from exercises."""
    muscles = set()
    for exercise in exercises:
        if isinstance(exercise, dict):
            # Check various field names for muscle info
            muscle = (
                exercise.get("primary_muscle") or
                exercise.get("primaryMuscle") or
                exercise.get("muscle_group") or
                exercise.get("muscleGroup") or
                exercise.get("target_muscle") or
                ""
            )
            if muscle:
                muscles.add(muscle.title())
    return list(muscles)[:4]  # Limit to top 4


def _row_to_summary(row: dict, user_today_str: Optional[str] = None) -> TodayWorkoutSummary:
    """Convert a database row to TodayWorkoutSummary."""
    # Parse exercises
    raw_exercises = row.get("exercises") or row.get("exercises_json")
    logger.debug(f"[_row_to_summary] workout_id={row.get('id')}, exercises_type={type(raw_exercises)}, "
                 f"exercises_len={len(raw_exercises) if raw_exercises else 0}")

    exercises = raw_exercises or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (json.JSONDecodeError, TypeError):
            logger.warning(f"[_row_to_summary] Failed to parse exercises JSON for workout {row.get('id')}", exc_info=True)
            exercises = []

    # Get scheduled date
    scheduled_date = row.get("scheduled_date", "")
    if scheduled_date:
        scheduled_date = str(scheduled_date)[:10]  # Get YYYY-MM-DD part

    # Check if today using user's local date
    if not user_today_str:
        raise ValueError("user_today_str is required — never fall back to date.today() on a UTC server")
    ref_today = user_today_str
    is_today = scheduled_date == ref_today

    return TodayWorkoutSummary(
        id=row.get("id", ""),
        name=row.get("name", "Workout"),
        type=row.get("type", "strength"),
        difficulty=row.get("difficulty", "medium"),
        description=row.get("description"),
        duration_minutes=row.get("duration_minutes", 45),
        exercise_count=len(exercises) if isinstance(exercises, list) else 0,
        primary_muscles=_extract_primary_muscles(exercises) if isinstance(exercises, list) else [],
        scheduled_date=scheduled_date,
        is_today=is_today,
        is_completed=row.get("is_completed", False),
        exercises=exercises if isinstance(exercises, list) else [],
        generation_method=row.get("generation_method"),
    )


def _is_today_a_workout_day(selected_days: List[int], user_today_str: str) -> bool:
    """Check if today is a scheduled workout day for the user.

    ``user_today_str`` is required — never fall back to ``date.today()``
    which returns UTC on a Render server.
    """
    # Python's weekday(): Monday=0, Sunday=6 - matches our selected_days format
    today_weekday = datetime.strptime(user_today_str, "%Y-%m-%d").weekday()
    return today_weekday in selected_days


def _get_user_workout_days(user: dict) -> List[int]:
    """Extract user's workout days from preferences as 0-indexed (Mon=0..Sun=6).

    Current Flutter clients write 0-indexed values:
      - workout_days_sheet.dart documents "0=Monday, 6=Sunday"
      - settings_card workout days picker uses value: 0..6 for Mon..Sun
      - profile editor saves _selectedDays (0-indexed) directly

    Flutter's user.workoutDays getter only subtracts 1 when a value > 6 is seen,
    so ambiguous values in [1..6] are treated as 0-indexed. Backend must match
    that convention — otherwise profile shows one set of days while the
    generator schedules a different set (observed with reviewer@fitwiz.us
    whose stored [1,3,5,6] displayed as Tue/Thu/Sat/Sun in the app but was
    being normalized to Mon/Wed/Fri/Sat on the server, so workouts were
    generated on the wrong days).

    Legacy 1-indexed data is detected by the unmistakable 7 marker. Without a
    7, we trust the value as already 0-indexed.

    Returns an empty list if no workout days are configured, so that
    auto-generation does NOT trigger on arbitrary default days.
    """
    preferences = parse_json_field(user.get("preferences"), {})
    # Try workout_days first (new format), fall back to selected_days (old format)
    selected_days = preferences.get("workout_days") or preferences.get("selected_days")

    if not selected_days or not isinstance(selected_days, list):
        logger.warning(f"[WORKOUT DAYS] No workout_days found in user preferences, returning empty list")
        return []

    # Filter to int-only values up front so heuristics don't trip over strings.
    int_days = [d for d in selected_days if isinstance(d, int)]
    if not int_days:
        return []

    # Only treat as 1-indexed if we see the 7 marker. Otherwise keep as-is,
    # matching Flutter. Drop any out-of-range values so downstream weekday
    # checks never match accidentally.
    has_seven = any(d == 7 for d in int_days)
    if has_seven:
        normalized = [d - 1 for d in int_days if 1 <= d <= 7]
    else:
        normalized = [d for d in int_days if 0 <= d <= 6]

    return sorted(set(normalized))


def _calculate_next_workout_date(selected_days: List[int], user_today_str: str) -> str:
    """Calculate the next workout date based on user's selected days.

    Returns the date in YYYY-MM-DD format.
    If today is a workout day, returns today.
    Otherwise returns the next upcoming workout day.

    ``user_today_str`` is required — never fall back to ``date.today()``
    which returns UTC on a Render server.
    """
    today = datetime.strptime(user_today_str, "%Y-%m-%d").date()
    today_weekday = today.weekday()

    # If today is a workout day, return today
    if today_weekday in selected_days:
        return today.isoformat()

    # Find the next workout day
    for days_ahead in range(1, 8):  # Check next 7 days
        future_date = today + timedelta(days=days_ahead)
        if future_date.weekday() in selected_days:
            return future_date.isoformat()

    # Fallback to today (shouldn't happen if selected_days is valid)
    return today.isoformat()


def _get_upcoming_dates_needing_generation(
    db,
    user_id: str,
    selected_days: List[int],
    active_profile_id: Optional[str],
    max_dates: int = 3,
    user_today_str: Optional[str] = None,
    user_tz: str = "UTC",
) -> List[date]:
    """Find up to `max_dates` upcoming scheduled workout days that have no workout generated.

    Scans the next 14 calendar days and returns dates that:
    1. Fall on one of the user's selected workout days
    2. Are today or in the future
    3. Don't already have a workout (completed or not) in the database
    4. Are not already being generated in the background

    Uses timezone-aware UTC date ranges to correctly match workouts stored
    with the user's local timezone offset.
    """
    if not user_today_str:
        raise ValueError("user_today_str is required — never fall back to date.today() on a UTC server")
    today_date = datetime.strptime(user_today_str, "%Y-%m-%d").date()
    end_date = today_date + timedelta(days=14)

    # Use timezone-aware UTC range for the full 14-day window
    range_start, _ = local_date_to_utc_range(today_date.isoformat(), user_tz)
    _, range_end = local_date_to_utc_range(end_date.isoformat(), user_tz)

    # Single query for ALL workouts in the next 14 days (timezone-aware)
    existing_workouts = db.list_workouts(
        user_id=user_id,
        from_date=range_start,
        to_date=range_end,
        limit=30,
        gym_profile_id=active_profile_id,
    )

    # Build set of dates that already have workouts.
    # Convert each workout's scheduled_date back to the user's local date
    # so we compare apples-to-apples with the user's calendar days.
    existing_dates = set()
    for w in existing_workouts:
        sd = w.get("scheduled_date", "")
        if sd:
            # Extract the date portion — works for both "YYYY-MM-DD" and "YYYY-MM-DDTHH:MM:SS+00:00"
            existing_dates.add(sd[:10])
            # Also add the user-local date in case the UTC date differs
            try:
                from dateutil.parser import parse as parse_dt
                import pytz
                utc_dt = parse_dt(sd)
                local_dt = utc_dt.astimezone(pytz.timezone(user_tz))
                existing_dates.add(local_dt.strftime("%Y-%m-%d"))
            except Exception:
                pass

    # Find scheduled days without workouts (also skip in-flight generations)
    results: List[date] = []
    for days_ahead in range(0, 14):
        check_date = today_date + timedelta(days=days_ahead)
        if check_date.weekday() not in selected_days:
            continue
        if check_date.isoformat() in existing_dates:
            continue
        # Skip dates already being generated in background
        gen_key = f"{user_id}:{check_date.isoformat()}:{active_profile_id or 'default'}"
        if gen_key in _active_background_generations:
            continue
        results.append(check_date)
        if len(results) >= max_dates:
            break

    return results


def _backfill_gym_profile_id(db, user_id: str, gym_profile_id: str) -> None:
    """Background task: tag workouts with NULL gym_profile_id.

    Workouts created before gym profiles existed or through flows that
    didn't set gym_profile_id will be invisible to profile-filtered queries.
    This one-shot backfill assigns the active profile to those workouts.
    """
    try:
        result = db.client.table("workouts") \
            .update({"gym_profile_id": gym_profile_id}) \
            .eq("user_id", user_id) \
            .is_("gym_profile_id", "null") \
            .execute()
        count = len(result.data) if result.data else 0
        if count > 0:
            logger.info(f"[BACKFILL] Tagged {count} orphaned workouts with gym_profile_id={gym_profile_id}")
    except Exception as e:
        logger.warning(f"[BACKFILL] Failed to backfill gym_profile_id: {e}", exc_info=True)


def _is_transient_error_str(err: str) -> bool:
    """Check if an error string indicates a transient/retryable error."""
    err_lower = err.lower()
    return any(kw in err_lower for kw in ["429", "resource_exhausted", "503", "timeout", "rate limit", "unavailable"])


async def auto_generate_workout(user_id: str, target_date: date, gym_profile_id: Optional[str] = None, selected_days: Optional[List[int]] = None, adjacent_day_exercises: Optional[List[str]] = None, batch_offset: int = 0, _retry_count: int = 0, user_tz: str = "UTC"):
    """Background task: generate a workout for a specific date.

    Safety guarantees:
    - Checks if a workout already exists for the date (race-condition prevention)
    - Tracks in-flight generations to prevent duplicate calls
    - Catches all exceptions so background tasks never crash the server
    """
    generation_key = f"{user_id}:{target_date.isoformat()}:{gym_profile_id or 'default'}"

    # Prevent duplicate in-flight generation for same user+date+profile
    if generation_key in _active_background_generations:
        logger.info(f"[BG-GEN] Already generating for {generation_key}, skipping")
        return

    _active_background_generations.add(generation_key)
    logger.info(f"[BG-GEN] Starting background generation for user={user_id}, date={target_date.isoformat()}")

    try:
        db = get_supabase_db()

        # Double-check: workout may have been created between the /today check and now
        # Use timezone-aware UTC range to correctly find workouts stored with TZ offset
        tz_from, tz_to = local_date_to_utc_range(target_date.isoformat(), user_tz)
        existing = db.list_workouts(
            user_id=user_id,
            from_date=tz_from,
            to_date=tz_to,
            limit=1,
            gym_profile_id=gym_profile_id,
        )
        if existing:
            logger.info(f"[BG-GEN] Workout already exists for {generation_key}, skipping generation")
            return

        # Also check for a workout with status='generating' (another request may have started it)
        try:
            target_str = target_date.isoformat()
            # Use timezone-aware range for generating check too
            gen_range_start, gen_range_end = local_date_to_utc_range(target_str, user_tz)
            gen_query = db.client.table("workouts").select("id, created_at").eq(
                "user_id", user_id
            ).gte(
                "scheduled_date", gen_range_start
            ).lte(
                "scheduled_date", gen_range_end
            ).eq(
                "status", "generating"
            )
            if gym_profile_id:
                gen_query = gen_query.eq("gym_profile_id", gym_profile_id)
            generating_check = gen_query.execute()
            if generating_check.data:
                # Check if placeholder is stuck (older than 5 minutes)
                from datetime import timezone
                placeholder = generating_check.data[0]
                created_at_str = placeholder.get("created_at")
                is_stuck = False
                if created_at_str:
                    try:
                        from dateutil.parser import parse as parse_dt
                        created_at = parse_dt(created_at_str)
                        age_seconds = (datetime.now(timezone.utc) - created_at).total_seconds()
                        if age_seconds > 300:  # 5 minutes
                            is_stuck = True
                            logger.warning(f"[BG-GEN] Stuck placeholder {placeholder['id']} is {age_seconds:.0f}s old, deleting it")
                            db.client.table("workouts").delete().eq("id", placeholder["id"]).execute()
                    except Exception:
                        pass
                if not is_stuck:
                    logger.info(f"[BG-GEN] Workout already being generated for {generation_key} (profile={gym_profile_id}), skipping")
                    return
        except Exception as e:
            logger.debug(f"Dedup check failed, proceeding: {e}")

        # Determine per-day focus area for workout variety
        focus_for_day = None
        workout_type = None
        if selected_days:
            try:
                training_split = None
                profile_focus_areas = []
                if gym_profile_id:
                    profile = db.client.table("gym_profiles").select(
                        "training_split, focus_areas"
                    ).eq("id", gym_profile_id).single().execute()
                    if profile.data:
                        training_split = profile.data.get("training_split")
                        profile_focus_areas = profile.data.get("focus_areas") or []
                else:
                    # Fallback: get split from user record
                    user_record = db.get_user(user_id)
                    training_split = user_record.get("training_split") if user_record else None
                resolved_split = resolve_training_split(training_split, len(selected_days))
                focus_map = get_workout_focus(resolved_split, selected_days, profile_focus_areas)
                focus_for_day = focus_map.get(target_date.weekday())
                if focus_for_day:
                    workout_type = infer_workout_type_from_focus(focus_for_day)
                logger.info(f"[BG-GEN] Day {target_date.weekday()} focus={focus_for_day}, type={workout_type}, split={resolved_split}")
            except Exception as e:
                logger.warning(f"[BG-GEN] Could not determine focus for {target_date}: {e}", exc_info=True)

        # Import the generation function (local import to avoid circular dependency)
        from .generation_endpoints import generate_workout
        from models.schemas import GenerateWorkoutRequest

        request = GenerateWorkoutRequest(
            user_id=user_id,
            scheduled_date=target_date.isoformat(),
            gym_profile_id=gym_profile_id,
            focus_areas=[focus_for_day] if focus_for_day else None,
            workout_type=workout_type,
            adjacent_day_exercises=adjacent_day_exercises,
            batch_offset=batch_offset,
        )

        # Call the unwrapped function to bypass the @user_limiter.limit decorator.
        # Background generation has no HTTP request context and should not be rate-limited.
        # Note: request=None means resolve_timezone() will fall back to DB/UTC for timezone,
        # and skip_comeback reads from body (not request).
        unwrapped = getattr(generate_workout, "__wrapped__", generate_workout)
        result = await unwrapped(None, body=request, background_tasks=BackgroundTasks(), current_user={"id": user_id})
        logger.info(f"[BG-GEN] Successfully generated workout for {generation_key}: {result.name if result else 'unknown'}")
        return result

    except Exception as e:
        if _retry_count < 1 and _is_transient_error_str(str(e)):
            logger.warning(f"[BG-GEN] Transient error for {generation_key}, retrying in 10s: {e}")
            _active_background_generations.discard(generation_key)
            await asyncio.sleep(10)
            return await auto_generate_workout(
                user_id, target_date, gym_profile_id, selected_days,
                adjacent_day_exercises, batch_offset, _retry_count=_retry_count + 1,
                user_tz=user_tz,
            )
        logger.error(f"[BG-GEN] Failed to generate workout for {generation_key}: {e}", exc_info=True)
    finally:
        _active_background_generations.discard(generation_key)


async def _sequential_generate_workouts(
    user_id: str,
    dates: List[date],
    gym_profile_id: Optional[str] = None,
    selected_days: Optional[List[int]] = None,
    user_tz: str = "UTC",
) -> None:
    """Generate workouts one at a time so each sees the previous one's exercises.

    This ensures get_recently_used_exercises returns the exercises from
    the just-generated workout, preventing duplicate exercises across
    adjacent days. Adjacent-day exercise names are also passed explicitly
    to the next generation call for additional deduplication.
    """
    all_batch_exercises: List[str] = []
    for i, gen_date in enumerate(dates):
        logger.info(f"[SEQ-GEN] Generating workout {i+1}/{len(dates)} for {gen_date.isoformat()} (batch_offset={i}, avoiding {len(all_batch_exercises)} exercises)")
        try:
            result = await auto_generate_workout(
                user_id=user_id,
                target_date=gen_date,
                gym_profile_id=gym_profile_id,
                selected_days=selected_days,
                adjacent_day_exercises=all_batch_exercises if all_batch_exercises else None,
                batch_offset=i,
                user_tz=user_tz,
            )
        except Exception as e:
            logger.error(f"[SEQ-GEN] Failed workout {i+1}/{len(dates)} for {gen_date}: {e}", exc_info=True)
            result = None
        # Accumulate exercise names from ALL generated workouts for the avoid list
        if result and hasattr(result, 'exercises') and result.exercises:
            new_exercises = [ex.name for ex in result.exercises if hasattr(ex, 'name') and ex.name]
            all_batch_exercises.extend(new_exercises)
            logger.info(f"[SEQ-GEN] Accumulated {len(all_batch_exercises)} total exercises to avoid (added {len(new_exercises)} from day {i+1})")
            # Invalidate today cache so the next poll picks up the newly generated workout
            await invalidate_today_workout_cache(user_id, gym_profile_id, gen_date.isoformat())


@router.get("/today", response_model=TodayWorkoutResponse)
async def get_today_workout(
    request: Request,
    user_id: str = Query(..., description="User ID"),
    background_tasks: BackgroundTasks = BackgroundTasks(),
    current_user: dict = Depends(get_current_user),
) -> TodayWorkoutResponse:
    """
    Get today's scheduled workout or the next upcoming workout.

    Returns:
    - today_workout: Today's workout if scheduled and not completed
    - next_workout: Next upcoming workout (always populated if no today workout)
    - days_until_next: Number of days until next workout
    - is_generating: True if workout is being generated in background
    - generation_message: Message about generation status

    IMPORTANT: The hero card should ALWAYS show a workout. If no workouts exist,
    this endpoint will trigger auto-generation. There is never a scenario where
    the hero card is empty.

    This endpoint is optimized for the Quick Start widget on the home screen.
    """
    logger.info(f"Fetching today's workout for user {user_id}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)

        # Get user to check their workout days (with Redis cache)
        cached_user = await _user_record_cache.get(user_id)
        if cached_user:
            user = cached_user
        else:
            user = db.get_user(user_id)
            if user:
                await _user_record_cache.set(user_id, user)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Get active gym profile for filtering (with Redis cache)
        active_profile_id = await _get_cached_gym_profile_id(db, user_id)
        logger.debug(f"[GYM PROFILE] Active profile for user {user_id}: {active_profile_id}")

        # Check cache before running expensive DB queries
        cache_key = f"{user_id}:{active_profile_id or 'none'}:{today_str}"
        cached = await _today_workout_cache.get(cache_key)
        if cached:
            logger.info(f"[CACHE] HIT workout_today for user {user_id}")
            cached_response = TodayWorkoutResponse(**cached)
            etag = _compute_etag(cached_response)
            if_none_match = request.headers.get("if-none-match", "")
            if if_none_match == etag:
                return Response(status_code=304, headers={"ETag": etag})
            return JSONResponse(content=cached, headers={"ETag": etag})

        selected_days = _get_user_workout_days(user)

        day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        is_today_workout_day = _is_today_a_workout_day(selected_days, user_today_str=today_str)

        # Enhanced user context logging for debugging (downgraded to debug)
        user_preferences = parse_json_field(user.get("preferences"), {})
        user_timezone = user.get("timezone") or user_preferences.get("timezone") or "Not set"
        logger.debug(f"[USER CONTEXT] user_id={user_id}, timezone={user_timezone}, "
                     f"onboarding_completed={user.get('onboarding_completed', False)}")
        logger.debug(f"[TODAY DEBUG] server_date={today_str}, selected_days={selected_days}, "
                     f"is_workout_day={is_today_workout_day}")

        # Compute UTC date ranges for timezone-aware queries
        today_utc_start, today_utc_end = local_date_to_utc_range(today_str, user_tz)
        user_today_date = datetime.strptime(today_str, "%Y-%m-%d").date()
        tomorrow_str = (user_today_date + timedelta(days=1)).isoformat()
        future_end = (user_today_date + timedelta(days=30)).isoformat()
        tomorrow_utc_start, _ = local_date_to_utc_range(tomorrow_str, user_tz)
        _, future_utc_end = local_date_to_utc_range(future_end, user_tz)

        # Run 3 independent DB queries in parallel using thread pool
        # (db.list_workouts is synchronous, so we use run_in_executor)
        # Today query uses allow_multiple_per_date=True and limit=5 to capture
        # quick workouts that coexist with the scheduled workout.
        loop = asyncio.get_event_loop()
        today_rows, future_rows, completed_today_rows = await asyncio.gather(
            loop.run_in_executor(_db_executor, lambda: db.list_workouts(
                user_id=user_id, from_date=today_utc_start, to_date=today_utc_end,
                is_completed=False, limit=5, gym_profile_id=active_profile_id,
                allow_multiple_per_date=True,
            )),
            loop.run_in_executor(_db_executor, lambda: db.list_workouts(
                user_id=user_id, from_date=tomorrow_utc_start, to_date=future_utc_end,
                is_completed=False, limit=1, order_asc=True, gym_profile_id=active_profile_id,
            )),
            loop.run_in_executor(_db_executor, lambda: db.list_workouts(
                user_id=user_id, from_date=today_utc_start, to_date=today_utc_end,
                is_completed=True, limit=1, gym_profile_id=active_profile_id,
            )),
        )

        if not today_rows:
            logger.debug(f"[TODAY DEBUG] No workout found for today ({today_str}), profile={active_profile_id}")

        # Check if a generation placeholder exists for today (list_workouts now
        # excludes status='generating' rows, so we need a separate check to
        # signal the frontend to poll until the real workout is ready).
        generating_for_today = False
        try:
            _gen_start, _gen_end = local_date_to_utc_range(today_str, user_tz)
            gen_check = db.client.table("workouts").select("id").eq(
                "user_id", user_id
            ).gte(
                "scheduled_date", _gen_start
            ).lte(
                "scheduled_date", _gen_end
            ).eq("status", "generating")
            if active_profile_id:
                gen_check = gen_check.or_(
                    f"gym_profile_id.eq.{active_profile_id},gym_profile_id.is.null"
                )
            gen_result = gen_check.execute()
            generating_for_today = bool(gen_result.data)
            if generating_for_today:
                logger.debug(f"[TODAY DEBUG] Generation placeholder found for today ({today_str})")
        except Exception as e:
            logger.debug(f"[TODAY DEBUG] Generation placeholder check failed: {e}")

        today_workout: Optional[TodayWorkoutSummary] = None
        extra_today_workouts: List[TodayWorkoutSummary] = []
        next_workout: Optional[TodayWorkoutSummary] = None
        has_workout_today = False
        is_generating = generating_for_today
        generation_message: Optional[str] = "Generating your workout..." if generating_for_today else None
        days_until_next: Optional[int] = None

        if today_rows:
            today_workout = _row_to_summary(today_rows[0], user_today_str=today_str)
            has_workout_today = True
            logger.debug(f"[TODAY DEBUG] Found today's workout: {today_workout.name}")
            # Additional today workouts (quick workouts coexisting with scheduled)
            if len(today_rows) > 1:
                extra_today_workouts = [
                    _row_to_summary(row, user_today_str=today_str)
                    for row in today_rows[1:]
                ]
                logger.debug(f"[TODAY DEBUG] Found {len(extra_today_workouts)} extra today workouts")

        if future_rows:
            next_workout = _row_to_summary(future_rows[0], user_today_str=today_str)
            next_date = datetime.strptime(next_workout.scheduled_date, "%Y-%m-%d").date()
            user_today_date = datetime.strptime(today_str, "%Y-%m-%d").date()
            days_until_next = (next_date - user_today_date).days
            logger.debug(f"[TODAY DEBUG] Found next workout: {next_workout.name}, in {days_until_next} days")

        has_completed_workout_today = len(completed_today_rows) > 0

        if has_completed_workout_today:
            logger.debug(f"[JIT Safety Net] User {user_id} already completed today's workout. Skipping auto-generation.")
            # Pre-cache tomorrow's workout in the background
            tomorrow_str = (user_today_date + timedelta(days=1)).isoformat()
            from .generation import generate_next_day_background
            background_tasks.add_task(generate_next_day_background, user_id, tomorrow_str)

        # Check if today is a scheduled workout day
        is_today_workout_day = _is_today_a_workout_day(selected_days, user_today_str=today_str)

        # Determine if generation is needed
        # Case 1: No today_workout AND no next_workout => generate for next scheduled day
        # Case 2: Next scheduled workout day has no workout (even if a later day does)
        #         e.g., on Friday with workout days Tue/Thu/Sat/Sun: if Saturday has no
        #         workout but Sunday does, we should still signal generation for Saturday
        needs_generation = False
        next_workout_date: Optional[str] = None

        if not today_workout and not has_completed_workout_today:
            nearest_scheduled_date_str = _calculate_next_workout_date(selected_days, user_today_str=today_str)
            if not next_workout:
                # Case 1: No workouts at all - generate for the next scheduled day
                needs_generation = True
                next_workout_date = nearest_scheduled_date_str
                logger.info(f"[AUTO-GEN] No workouts found for user {user_id}. Signaling generation needed for {next_workout_date}")
            elif next_workout and nearest_scheduled_date_str != next_workout.scheduled_date:
                # Case 2: The nearest scheduled day doesn't match the next existing workout
                # This means there's a gap - the nearest day needs generation
                # e.g., nearest scheduled is Saturday but next existing workout is Sunday
                needs_generation = True
                next_workout_date = nearest_scheduled_date_str
                logger.info(f"[AUTO-GEN] Nearest scheduled day {nearest_scheduled_date_str} has no workout "
                           f"(next existing is {next_workout.scheduled_date}). "
                           f"Signaling generation for {next_workout_date}")

        # Log analytics event for quick start view (non-blocking)
        background_tasks.add_task(
            user_context_service.log_event,
            user_id=user_id,
            event_type="quick_start_viewed",
            event_data={
                "has_workout_today": has_workout_today,
                "workout_id": today_workout.id if today_workout else None,
                "next_workout_id": next_workout.id if next_workout else None,
                "days_until_next": days_until_next,
                "is_generating": is_generating,
            },
        )

        # Build completed workout summary if user completed today's workout
        completed_workout_summary: Optional[TodayWorkoutSummary] = None
        if has_completed_workout_today:
            completed_workout_summary = _row_to_summary(completed_today_rows[0], user_today_str=today_str)
            logger.info(f"User completed today's workout: {completed_workout_summary.name}")

        # ================================================================
        # Proactive Background Generation (with cooldown)
        # ================================================================
        # Check for missing upcoming workouts and pre-generate them.
        # Cooldown prevents /today polls (every 3-15s) from re-queuing tasks.
        now_ts = datetime.now().timestamp()
        last_scheduled = _last_bg_gen_schedule.get(user_id, 0)
        if now_ts - last_scheduled >= _BG_GEN_SCHEDULE_COOLDOWN:
            upcoming_missing = _get_upcoming_dates_needing_generation(
                db=db,
                user_id=user_id,
                selected_days=selected_days,
                active_profile_id=active_profile_id,
                max_dates=7,
                user_today_str=today_str,
                user_tz=user_tz,
            )
            if upcoming_missing:
                _last_bg_gen_schedule[user_id] = now_ts
                logger.info(f"[BG-GEN] Scheduling SEQUENTIAL background generation for {len(upcoming_missing)} dates: "
                           f"{[d.isoformat() for d in upcoming_missing]}")
                # Generate sequentially so each workout sees previous ones' exercises
                # via get_recently_used_exercises, ensuring variety across adjacent days
                background_tasks.add_task(
                    _sequential_generate_workouts,
                    user_id=user_id,
                    dates=upcoming_missing,
                    gym_profile_id=active_profile_id,
                    selected_days=selected_days,
                    user_tz=user_tz,
                )

        # Backfill: tag orphaned workouts (gym_profile_id IS NULL) with the active profile
        if active_profile_id:
            background_tasks.add_task(
                _backfill_gym_profile_id,
                db=db,
                user_id=user_id,
                gym_profile_id=active_profile_id,
            )

        response = TodayWorkoutResponse(
            has_workout_today=has_workout_today,
            today_workout=today_workout,
            next_workout=next_workout,
            days_until_next=days_until_next,
            extra_today_workouts=extra_today_workouts,
            completed_today=has_completed_workout_today,
            completed_workout=completed_workout_summary,
            is_generating=is_generating,
            generation_message=generation_message,
            needs_generation=needs_generation,
            next_workout_date=next_workout_date,
            gym_profile_id=active_profile_id,
        )

        # Cache all responses — stable ones with full TTL, transient with short TTL
        if response.is_generating or response.needs_generation:
            await _today_workout_cache.set(cache_key, response.dict(), ttl_override=_TRANSIENT_CACHE_TTL)
            logger.debug(f"[CACHE] SET workout_today (transient, {_TRANSIENT_CACHE_TTL}s) for user {user_id}")
        else:
            await _today_workout_cache.set(cache_key, response.dict())
            logger.debug(f"[CACHE] SET workout_today for user {user_id}")

        # ETag / 304 support — avoids sending unchanged payloads over the wire
        etag = _compute_etag(response)
        if_none_match = request.headers.get("if-none-match", "")
        if if_none_match == etag:
            return Response(status_code=304, headers={"ETag": etag})

        return JSONResponse(
            content=response.dict(),
            headers={"ETag": etag},
        )

    except Exception as e:
        logger.error(f"Failed to get today's workout: {e}", exc_info=True)
        raise safe_internal_error(e, "today")


@router.post("/today/start")
async def log_quick_start(
    user_id: str = Query(..., description="User ID"),
    workout_id: str = Query(..., description="Workout ID being started"),
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Log when user taps 'Start Today's Workout' for analytics.

    This helps track:
    - Quick start usage patterns
    - Conversion from home screen to active workout
    - Time of day preferences
    """
    logger.info(f"Logging quick start for user {user_id}, workout {workout_id}")

    try:
        await user_context_service.log_event(
            user_id=user_id,
            event_type="quick_start_tapped",
            event_data={
                "workout_id": workout_id,
                "source": "quick_start_widget",
                "timestamp": datetime.now().isoformat(),
            },
        )

        return {
            "success": True,
            "message": "Quick start logged",
        }

    except Exception as e:
        logger.warning(f"Failed to log quick start: {e}", exc_info=True)
        # Don't fail the request - logging is non-critical
        return {
            "success": False,
            "message": "Logging failed but operation continues",
        }
