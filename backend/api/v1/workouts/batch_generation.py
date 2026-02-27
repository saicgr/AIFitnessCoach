"""
Batch workout retrieval for offline pre-caching.

GET /api/v1/workouts/upcoming?user_id=xxx&days=14

Returns the next N days of already-generated workouts with full exercise data.
This is a read-only endpoint - it returns whatever exists in the DB.
If fewer days than requested exist, the client knows to trigger generation when online.
"""
from datetime import date, datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger

from .utils import parse_json_field


router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Response Models
# =============================================================================


class UpcomingWorkoutResponse(BaseModel):
    """Upcoming workouts with coverage metadata."""
    workouts: List[dict]  # Full workout objects with exercises_json parsed
    total_days_requested: int
    total_days_available: int
    coverage_start: str  # ISO date
    coverage_end: str  # ISO date


class BatchUpcomingResponse(BaseModel):
    """Top-level batch response with cache timestamp."""
    data: UpcomingWorkoutResponse
    cached_at: str  # ISO timestamp


# =============================================================================
# Endpoint
# =============================================================================


@router.get("/upcoming", response_model=BatchUpcomingResponse)
async def get_upcoming_workouts(
    user_id: str = Query(..., description="User ID"),
    days: int = Query(default=14, ge=1, le=30, description="Number of days to look ahead (max 30)"),
    gym_profile_id: Optional[str] = Query(default=None, description="Filter by gym profile ID"),
    current_user: dict = Depends(get_current_user),
) -> BatchUpcomingResponse:
    """
    Get upcoming pre-generated workouts for offline pre-caching.

    Returns all workouts scheduled between today and today + days,
    with full exercise data parsed from exercises_json.

    This is a read-only endpoint - it does NOT trigger generation.
    The client can compare total_days_available vs total_days_requested
    to determine if more workouts need to be generated while online.
    """
    logger.info(f"[BATCH] Fetching upcoming workouts for user={user_id}, days={days}, gym_profile_id={gym_profile_id}")

    try:
        db = get_supabase_db()

        # Calculate date range
        today_date = date.today()
        end_date = today_date + timedelta(days=days)
        today_str = today_date.isoformat()
        end_str = end_date.isoformat()

        # If no gym_profile_id provided, try to get the active one
        profile_filter = gym_profile_id
        if not profile_filter:
            try:
                active_result = db.client.table("gym_profiles") \
                    .select("id") \
                    .eq("user_id", user_id) \
                    .eq("is_active", True) \
                    .single() \
                    .execute()
                if active_result.data:
                    profile_filter = active_result.data.get("id")
                    logger.info(f"[BATCH] Using active gym profile: {profile_filter}")
            except Exception as e:
                logger.debug(f"No active gym profile found: {e}")

        # Query workouts in date range, ordered by scheduled_date ASC
        rows = db.list_workouts(
            user_id=user_id,
            from_date=today_str,
            to_date=end_str,
            limit=days,  # At most one workout per day
            order_asc=True,
            gym_profile_id=profile_filter,
        )

        logger.info(f"[BATCH] Found {len(rows)} workouts in range {today_str} to {end_str}")

        # Parse exercises_json for each workout
        workouts = []
        for row in rows:
            workout = dict(row)

            # Parse exercises_json into a proper list
            raw_exercises = workout.get("exercises_json") or workout.get("exercises")
            workout["exercises"] = parse_json_field(raw_exercises, [])

            # Parse any other JSON fields that might be stored as strings
            for json_key in ("warmup_json", "stretch_json", "notes_json"):
                if json_key in workout:
                    workout[json_key] = parse_json_field(workout.get(json_key), [])

            workouts.append(workout)

        # Count unique dates with workouts
        workout_dates = set()
        for w in workouts:
            sched = w.get("scheduled_date", "")
            if sched:
                workout_dates.add(str(sched)[:10])

        return BatchUpcomingResponse(
            data=UpcomingWorkoutResponse(
                workouts=workouts,
                total_days_requested=days,
                total_days_available=len(workout_dates),
                coverage_start=today_str,
                coverage_end=end_str,
            ),
            cached_at=datetime.utcnow().isoformat() + "Z",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[BATCH] Failed to fetch upcoming workouts: {e}")
        raise safe_internal_error(e, "batch_generation")
