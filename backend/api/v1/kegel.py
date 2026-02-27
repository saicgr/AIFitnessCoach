"""
Kegel/Pelvic Floor API Endpoints
API routes for kegel preferences, session tracking, and pelvic floor exercises.
"""

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import Optional, List
from datetime import date, datetime, timedelta
from uuid import UUID

from models.hormonal_health import (
    KegelPreferences, KegelPreferencesCreate, KegelPreferencesUpdate,
    KegelSession, KegelSessionCreate,
    KegelStats, KegelExercise, KegelDailyGoal,
    KegelFocusArea, KegelLevel
)
from core.supabase_client import get_supabase
from core.timezone_utils import resolve_timezone, get_user_today
from core.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/kegel", tags=["Kegel/Pelvic Floor"])


# ============================================================================
# KEGEL PREFERENCES ENDPOINTS
# ============================================================================

@router.get("/preferences/{user_id}", response_model=Optional[KegelPreferences])
async def get_kegel_preferences(user_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Get user's kegel preferences."""
    logger.info(f"[Kegel] Fetching preferences for user {user_id}")

    try:
        supabase = get_supabase().client
        result = supabase.table("kegel_preferences").select("*").eq("user_id", str(user_id)).execute()

        if not result.data:
            logger.info(f"[Kegel] No preferences found for user {user_id}")
            return None

        logger.info(f"[Kegel] Preferences retrieved for user {user_id}")
        return result.data[0]

    except Exception as e:
        logger.error(f"[Kegel] Error fetching preferences: {e}")
        raise safe_internal_error(e, "kegel")


@router.put("/preferences/{user_id}", response_model=KegelPreferences)
async def upsert_kegel_preferences(user_id: UUID, preferences: KegelPreferencesUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Create or update user's kegel preferences."""
    logger.info(f"[Kegel] Upserting preferences for user {user_id}")

    try:
        supabase = get_supabase().client

        # Prepare data, excluding None values
        pref_data = {k: v for k, v in preferences.dict().items() if v is not None}
        pref_data["user_id"] = str(user_id)
        pref_data["updated_at"] = datetime.utcnow().isoformat()

        # Convert enums to strings
        for field in ["current_level", "focus_area", "reminder_frequency"]:
            if field in pref_data and pref_data[field] is not None:
                pref_data[field] = pref_data[field].value if hasattr(pref_data[field], 'value') else pref_data[field]

        # Convert time to string
        if "daily_reminder_time" in pref_data and pref_data["daily_reminder_time"]:
            pref_data["daily_reminder_time"] = pref_data["daily_reminder_time"].isoformat()

        # Check if preferences exist
        existing = supabase.table("kegel_preferences").select("id").eq("user_id", str(user_id)).execute()

        if existing.data:
            # Update existing
            result = supabase.table("kegel_preferences").update(pref_data).eq("user_id", str(user_id)).execute()
        else:
            # Insert new
            pref_data["created_at"] = datetime.utcnow().isoformat()
            result = supabase.table("kegel_preferences").insert(pref_data).execute()

        logger.info(f"[Kegel] Preferences upserted for user {user_id}")
        return result.data[0]

    except Exception as e:
        logger.error(f"[Kegel] Error upserting preferences: {e}")
        raise safe_internal_error(e, "kegel")


@router.delete("/preferences/{user_id}")
async def delete_kegel_preferences(user_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Delete user's kegel preferences."""
    logger.info(f"[Kegel] Deleting preferences for user {user_id}")

    try:
        supabase = get_supabase().client
        supabase.table("kegel_preferences").delete().eq("user_id", str(user_id)).execute()
        logger.info(f"[Kegel] Preferences deleted for user {user_id}")
        return {"message": "Preferences deleted successfully"}

    except Exception as e:
        logger.error(f"[Kegel] Error deleting preferences: {e}")
        raise safe_internal_error(e, "kegel")


# ============================================================================
# KEGEL SESSION ENDPOINTS
# ============================================================================

@router.post("/sessions/{user_id}", response_model=KegelSession)
async def create_kegel_session(user_id: UUID, session: KegelSessionCreate,
    current_user: dict = Depends(get_current_user),
):
    """Log a completed kegel session."""
    logger.info(f"[Kegel] Creating session for user {user_id}")

    try:
        supabase = get_supabase().client

        session_data = session.dict()
        session_data["user_id"] = str(user_id)
        session_data["created_at"] = datetime.utcnow().isoformat()
        session_data["session_time"] = datetime.utcnow().time().isoformat()

        # Convert enums and date
        session_data["session_date"] = session_data["session_date"].isoformat()
        for field in ["session_type", "performed_during"]:
            if session_data.get(field):
                session_data[field] = session_data[field].value if hasattr(session_data[field], 'value') else session_data[field]

        result = supabase.table("kegel_sessions").insert(session_data).execute()

        logger.info(f"[Kegel] Session created for user {user_id}")
        return result.data[0]

    except Exception as e:
        logger.error(f"[Kegel] Error creating session: {e}")
        raise safe_internal_error(e, "kegel")


@router.get("/sessions/{user_id}", response_model=List[KegelSession])
async def get_kegel_sessions(
    user_id: UUID,
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    limit: int = Query(50, ge=1, le=365),
    current_user: dict = Depends(get_current_user),
):
    """Get kegel sessions for a user with optional date range."""
    logger.info(f"[Kegel] Fetching sessions for user {user_id}")

    try:
        supabase = get_supabase().client

        query = supabase.table("kegel_sessions").select("*").eq("user_id", str(user_id))

        if start_date:
            query = query.gte("session_date", start_date.isoformat())
        if end_date:
            query = query.lte("session_date", end_date.isoformat())

        result = query.order("session_date", desc=True).order("session_time", desc=True).limit(limit).execute()

        logger.info(f"[Kegel] Retrieved {len(result.data)} sessions for user {user_id}")
        return result.data

    except Exception as e:
        logger.error(f"[Kegel] Error fetching sessions: {e}")
        raise safe_internal_error(e, "kegel")


@router.get("/sessions/{user_id}/today", response_model=List[KegelSession])
async def get_today_kegel_sessions(user_id: UUID, request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get today's kegel sessions."""
    logger.info(f"[Kegel] Fetching today's sessions for user {user_id}")

    try:
        supabase = get_supabase().client
        user_tz = resolve_timezone(request, None, str(user_id))
        today_str = get_user_today(user_tz)
        result = supabase.table("kegel_sessions").select("*").eq(
            "user_id", str(user_id)
        ).eq("session_date", today_str).order("session_time", desc=True).execute()

        return result.data

    except Exception as e:
        logger.error(f"[Kegel] Error fetching today's sessions: {e}")
        raise safe_internal_error(e, "kegel")


# ============================================================================
# KEGEL STATISTICS ENDPOINTS
# ============================================================================

@router.get("/stats/{user_id}", response_model=KegelStats)
async def get_kegel_stats(user_id: UUID, request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get kegel exercise statistics for a user."""
    logger.info(f"[Kegel] Calculating stats for user {user_id}")

    try:
        supabase = get_supabase().client

        # Get preferences
        prefs_result = supabase.table("kegel_preferences").select("*").eq("user_id", str(user_id)).execute()
        prefs = prefs_result.data[0] if prefs_result.data else {"kegels_enabled": False, "target_sessions_per_day": 3}

        # Get all sessions
        sessions_result = supabase.table("kegel_sessions").select("*").eq("user_id", str(user_id)).execute()
        sessions = sessions_result.data

        # Calculate stats
        total_sessions = len(sessions)
        total_duration = sum(s.get("duration_seconds", 0) for s in sessions)
        avg_duration = total_duration // total_sessions if total_sessions > 0 else 0

        # Count unique days
        session_dates = set(s.get("session_date") for s in sessions)
        total_days = len(session_dates)

        # Today's sessions
        user_tz = resolve_timezone(request, None, str(user_id))
        today_str = get_user_today(user_tz)
        today_date = date.fromisoformat(today_str)
        sessions_today = len([s for s in sessions if s.get("session_date") == today_str])

        # Last 7 days
        week_ago = (today_date - timedelta(days=7)).isoformat()
        sessions_last_7 = len([s for s in sessions if s.get("session_date", "") >= week_ago])

        # Calculate streak
        current_streak = 0
        longest_streak = 0
        if session_dates:
            sorted_dates = sorted([date.fromisoformat(d) for d in session_dates], reverse=True)

            # Current streak (consecutive days including today or yesterday)
            check_date = today_date
            if check_date not in [date.fromisoformat(d) for d in session_dates]:
                check_date = today_date - timedelta(days=1)

            temp_streak = 0
            for d in sorted_dates:
                if d == check_date:
                    temp_streak += 1
                    check_date -= timedelta(days=1)
                elif d < check_date:
                    break
            current_streak = temp_streak

            # Longest streak
            temp_streak = 1
            sorted_dates_asc = sorted([date.fromisoformat(d) for d in session_dates])
            for i in range(1, len(sorted_dates_asc)):
                if sorted_dates_asc[i] - sorted_dates_asc[i-1] == timedelta(days=1):
                    temp_streak += 1
                else:
                    longest_streak = max(longest_streak, temp_streak)
                    temp_streak = 1
            longest_streak = max(longest_streak, temp_streak)

        # Check if daily goal met
        target = prefs.get("target_sessions_per_day", 3)
        daily_goal_met = sessions_today >= target

        return KegelStats(
            user_id=str(user_id),
            kegels_enabled=prefs.get("kegels_enabled", False),
            target_sessions_per_day=target,
            total_days_practiced=total_days,
            total_sessions=total_sessions,
            total_duration_seconds=total_duration,
            avg_session_duration=avg_duration,
            sessions_today=sessions_today,
            sessions_last_7_days=sessions_last_7,
            current_streak=current_streak,
            longest_streak=longest_streak,
            daily_goal_met_today=daily_goal_met
        )

    except Exception as e:
        logger.error(f"[Kegel] Error calculating stats: {e}")
        raise safe_internal_error(e, "kegel")


@router.get("/daily-goal/{user_id}", response_model=KegelDailyGoal)
async def check_daily_goal(user_id: UUID, request: Request, check_date: date = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    """Check if user has met their daily kegel goal."""
    logger.info(f"[Kegel] Checking daily goal for user {user_id}")

    try:
        supabase = get_supabase().client

        if check_date is None:
            user_tz = resolve_timezone(request, None, str(user_id))
            target_date = date.fromisoformat(get_user_today(user_tz))
        else:
            target_date = check_date

        # Get preferences
        prefs_result = supabase.table("kegel_preferences").select("target_sessions_per_day").eq("user_id", str(user_id)).execute()
        target = prefs_result.data[0].get("target_sessions_per_day", 3) if prefs_result.data else 3

        # Count sessions for the date
        sessions_result = supabase.table("kegel_sessions").select("id").eq(
            "user_id", str(user_id)
        ).eq("session_date", target_date.isoformat()).execute()

        completed = len(sessions_result.data)
        remaining = max(0, target - completed)

        return KegelDailyGoal(
            user_id=str(user_id),
            date=target_date,
            goal_met=completed >= target,
            sessions_completed=completed,
            target_sessions=target,
            remaining=remaining
        )

    except Exception as e:
        logger.error(f"[Kegel] Error checking daily goal: {e}")
        raise safe_internal_error(e, "kegel")


# ============================================================================
# KEGEL EXERCISES REFERENCE ENDPOINTS
# ============================================================================

@router.get("/exercises", response_model=List[KegelExercise])
async def get_kegel_exercises(
    target_audience: Optional[str] = Query(None, description="Filter by 'all', 'male', or 'female'"),
    difficulty: Optional[KegelLevel] = Query(None),
    focus_area: Optional[KegelFocusArea] = Query(None),
    current_user: dict = Depends(get_current_user),
):
    """Get list of pelvic floor exercises."""
    logger.info(f"[Kegel] Fetching exercises")

    try:
        supabase = get_supabase().client

        query = supabase.table("kegel_exercises").select("*").eq("is_active", True)

        if target_audience:
            # Include exercises for 'all' plus the specific audience
            query = query.in_("target_audience", ["all", target_audience])

        if difficulty:
            query = query.eq("difficulty", difficulty.value)

        result = query.order("sort_order").execute()

        # Filter by focus area if needed (done in Python since it's not a direct column)
        exercises = result.data
        if focus_area:
            focus_area_map = {
                KegelFocusArea.POSTPARTUM: "female",
                KegelFocusArea.PROSTATE_HEALTH: "male",
                KegelFocusArea.MALE_SPECIFIC: "male",
                KegelFocusArea.FEMALE_SPECIFIC: "female",
            }
            if focus_area in focus_area_map:
                target = focus_area_map[focus_area]
                exercises = [e for e in exercises if e.get("target_audience") in ["all", target]]

        logger.info(f"[Kegel] Retrieved {len(exercises)} exercises")
        return exercises

    except Exception as e:
        logger.error(f"[Kegel] Error fetching exercises: {e}")
        raise safe_internal_error(e, "kegel")


@router.get("/exercises/{exercise_id}", response_model=KegelExercise)
async def get_kegel_exercise(exercise_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Get a specific kegel exercise by ID."""
    logger.info(f"[Kegel] Fetching exercise {exercise_id}")

    try:
        supabase = get_supabase().client
        result = supabase.table("kegel_exercises").select("*").eq("id", str(exercise_id)).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Kegel] Error fetching exercise: {e}")
        raise safe_internal_error(e, "kegel")


@router.get("/exercises/by-name/{name}", response_model=KegelExercise)
async def get_kegel_exercise_by_name(name: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a kegel exercise by name."""
    logger.info(f"[Kegel] Fetching exercise by name: {name}")

    try:
        supabase = get_supabase().client
        result = supabase.table("kegel_exercises").select("*").eq("name", name).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Exercise not found")

        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Kegel] Error fetching exercise: {e}")
        raise safe_internal_error(e, "kegel")


# ============================================================================
# WORKOUT INTEGRATION ENDPOINTS
# ============================================================================

@router.get("/for-workout/{user_id}")
async def get_kegels_for_workout(
    user_id: UUID,
    placement: str = Query(..., description="'warmup', 'cooldown', or 'standalone'"),
    current_user: dict = Depends(get_current_user),
):
    """Get kegel exercises to include in a workout based on user preferences."""
    logger.info(f"[Kegel] Getting kegels for {placement} for user {user_id}")

    try:
        supabase = get_supabase().client

        # Check preferences
        prefs_result = supabase.table("kegel_preferences").select("*").eq("user_id", str(user_id)).execute()

        if not prefs_result.data:
            return {"include_kegels": False, "exercises": [], "reason": "No kegel preferences set"}

        prefs = prefs_result.data[0]

        if not prefs.get("kegels_enabled"):
            return {"include_kegels": False, "exercises": [], "reason": "Kegels disabled"}

        # Check if this placement is enabled
        placement_field = f"include_in_{placement}"
        if placement == "standalone":
            placement_field = "include_as_standalone"

        if not prefs.get(placement_field):
            return {"include_kegels": False, "exercises": [], "reason": f"Kegels not enabled for {placement}"}

        # Get appropriate exercises
        level = prefs.get("current_level", "beginner")
        focus = prefs.get("focus_area", "general")

        # Map focus area to target audience
        target_audience = "all"
        if focus in ["male_specific", "prostate_health"]:
            target_audience = "male"
        elif focus in ["female_specific", "postpartum"]:
            target_audience = "female"

        # Fetch exercises
        query = supabase.table("kegel_exercises").select("*").eq("is_active", True).eq("difficulty", level)
        if target_audience != "all":
            query = query.in_("target_audience", ["all", target_audience])
        else:
            query = query.eq("target_audience", "all")

        result = query.order("sort_order").limit(3).execute()

        return {
            "include_kegels": True,
            "placement": placement,
            "exercises": result.data,
            "total_duration_seconds": sum(e.get("default_duration_seconds", 30) for e in result.data)
        }

    except Exception as e:
        logger.error(f"[Kegel] Error getting kegels for workout: {e}")
        raise safe_internal_error(e, "kegel")


@router.post("/log-from-workout/{user_id}")
async def log_kegels_from_workout(
    user_id: UUID,
    request: Request,
    workout_id: UUID,
    placement: str = Query(..., description="'warmup' or 'cooldown'"),
    duration_seconds: int = Query(..., ge=1),
    exercises_completed: List[str] = Query(default=[]),
    current_user: dict = Depends(get_current_user),
):
    """Log kegel exercises completed as part of a workout."""
    logger.info(f"[Kegel] Logging kegels from workout {workout_id} for user {user_id}")

    try:
        supabase = get_supabase().client
        user_tz = resolve_timezone(request, None, str(user_id))

        session_data = {
            "user_id": str(user_id),
            "session_date": get_user_today(user_tz),
            "session_time": datetime.utcnow().time().isoformat(),
            "duration_seconds": duration_seconds,
            "session_type": "standard",
            "performed_during": placement,
            "workout_id": str(workout_id),
            "exercise_name": ", ".join(exercises_completed) if exercises_completed else None,
            "created_at": datetime.utcnow().isoformat()
        }

        result = supabase.table("kegel_sessions").insert(session_data).execute()

        logger.info(f"[Kegel] Logged kegels from workout for user {user_id}")
        return result.data[0]

    except Exception as e:
        logger.error(f"[Kegel] Error logging from workout: {e}")
        raise safe_internal_error(e, "kegel")
