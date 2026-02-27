"""
Workout screen summary endpoint.

Returns lightweight data for the Workouts screen: weekly progress counts,
recent completed sessions, and upcoming workout summaries. Designed to be
fast (~5-10KB response vs 2-5MB from full workout list).
"""
from datetime import date, timedelta
from typing import List, Optional
import asyncio
import json
from concurrent.futures import ThreadPoolExecutor

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()

# Thread pool for parallel sync DB calls
_db_executor = ThreadPoolExecutor(max_workers=15)


class WorkoutMiniSummary(BaseModel):
    """Lightweight workout summary for list display."""
    id: str
    name: str
    type: str
    scheduled_date: str
    is_completed: bool
    duration_minutes: int
    exercise_count: int
    primary_muscles: List[str]


class WorkoutScreenSummary(BaseModel):
    """Response for the workouts screen summary endpoint."""
    completed_this_week: int
    planned_this_week: int
    previous_sessions: List[WorkoutMiniSummary]
    upcoming_workouts: List[WorkoutMiniSummary]


def _extract_exercise_count(exercises_json) -> int:
    """Extract exercise count from exercises_json without full parsing."""
    if not exercises_json:
        return 0
    if isinstance(exercises_json, list):
        return len(exercises_json)
    if isinstance(exercises_json, str):
        try:
            parsed = json.loads(exercises_json)
            return len(parsed) if isinstance(parsed, list) else 0
        except (json.JSONDecodeError, TypeError):
            return 0
    return 0


def _extract_primary_muscles(exercises_json) -> List[str]:
    """Extract primary muscle groups from exercises_json with minimal parsing."""
    muscles = set()
    exercises = exercises_json
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (json.JSONDecodeError, TypeError):
            return []
    if not isinstance(exercises, list):
        return []

    for ex in exercises:
        if isinstance(ex, dict):
            muscle = (
                ex.get("primary_muscle") or
                ex.get("primaryMuscle") or
                ex.get("muscle_group") or
                ex.get("muscleGroup") or
                ""
            )
            if muscle:
                muscles.add(muscle.title())
    return list(muscles)[:4]


def _row_to_mini_summary(row: dict) -> WorkoutMiniSummary:
    """Convert a database row to WorkoutMiniSummary (no video enrichment)."""
    exercises_json = row.get("exercises_json") or row.get("exercises")
    scheduled_date = str(row.get("scheduled_date", ""))[:10]

    return WorkoutMiniSummary(
        id=str(row.get("id", "")),
        name=row.get("name", "Workout"),
        type=row.get("type", "strength"),
        scheduled_date=scheduled_date,
        is_completed=row.get("is_completed", False),
        duration_minutes=row.get("duration_minutes", 45),
        exercise_count=_extract_exercise_count(exercises_json),
        primary_muscles=_extract_primary_muscles(exercises_json),
    )


def _get_active_gym_profile_id(db, user_id: str) -> Optional[str]:
    """Get the active gym profile ID for a user."""
    try:
        result = db.client.table("gym_profiles") \
            .select("id") \
            .eq("user_id", user_id) \
            .eq("is_active", True) \
            .single() \
            .execute()
        if result.data:
            return result.data.get("id")
    except Exception as e:
        logger.warning(f"Failed to get active gym profile: {e}")
    return None


@router.get("/screen-summary", response_model=WorkoutScreenSummary)
async def get_workout_screen_summary(
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
) -> WorkoutScreenSummary:
    """
    Get lightweight summary data for the Workouts screen.

    Returns weekly progress counts, last 3 completed workouts, and next 7 upcoming.
    Response is ~5-10KB vs 2-5MB from full workout list.
    """
    logger.info(f"Fetching workout screen summary for user {user_id}")

    try:
        db = get_supabase_db()

        # Get active gym profile
        active_profile_id = _get_active_gym_profile_id(db, user_id)

        # Calculate week boundaries (Monday to Sunday)
        today = date.today()
        start_of_week = today - timedelta(days=today.weekday())
        end_of_week = start_of_week + timedelta(days=6)

        # Future window for upcoming
        future_end = today + timedelta(days=30)

        # Run 3 queries in parallel
        loop = asyncio.get_event_loop()

        week_rows, completed_rows, upcoming_rows = await asyncio.gather(
            # All workouts this week (for planned + completed counts)
            loop.run_in_executor(_db_executor, lambda: db.list_workouts(
                user_id=user_id,
                from_date=start_of_week.isoformat(),
                to_date=end_of_week.isoformat(),
                limit=20,
                gym_profile_id=active_profile_id,
            )),
            # Last 3 completed (for previous sessions)
            loop.run_in_executor(_db_executor, lambda: db.list_workouts(
                user_id=user_id,
                is_completed=True,
                limit=3,
                gym_profile_id=active_profile_id,
            )),
            # Next 7 upcoming (not completed, future)
            loop.run_in_executor(_db_executor, lambda: db.list_workouts(
                user_id=user_id,
                from_date=today.isoformat(),
                to_date=future_end.isoformat(),
                is_completed=False,
                limit=7,
                order_asc=True,
                gym_profile_id=active_profile_id,
            )),
        )

        # Calculate weekly progress
        completed_this_week = sum(1 for w in week_rows if w.get("is_completed"))
        planned_this_week = len(week_rows)

        # Build mini summaries (no video enrichment needed)
        previous_sessions = [_row_to_mini_summary(r) for r in completed_rows]
        upcoming_workouts = [_row_to_mini_summary(r) for r in upcoming_rows]

        return WorkoutScreenSummary(
            completed_this_week=completed_this_week,
            planned_this_week=planned_this_week,
            previous_sessions=previous_sessions,
            upcoming_workouts=upcoming_workouts,
        )

    except Exception as e:
        logger.error(f"Failed to get workout screen summary: {e}")
        raise safe_internal_error(e, "screen_summary")
