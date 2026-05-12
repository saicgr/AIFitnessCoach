"""
Workouts screen summary endpoint.

Restored as a thin server-side derivation so old shipped clients (1.2.66 and
earlier) that still call `GET /workouts/screen-summary` get a 200 instead of
falling through to the `/{workout_id}` UUID matcher and 422'ing.

Newer clients derive this from the already-loaded workouts list in
`workout_repository.dart` and never call this endpoint.
"""
import json
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

from ._gym_profile_helpers import get_active_gym_profile_id
from .utils import row_to_workout

router = APIRouter()
logger = get_logger(__name__)


class WorkoutMiniSummary(BaseModel):
    id: str
    name: str
    type: str
    scheduled_date: str
    is_completed: bool
    duration_minutes: int
    exercise_count: int
    primary_muscles: List[str]


class WorkoutScreenSummaryResponse(BaseModel):
    completed_this_week: int
    planned_this_week: int
    previous_sessions: List[WorkoutMiniSummary]
    upcoming_workouts: List[WorkoutMiniSummary]


def _to_mini(w) -> WorkoutMiniSummary:
    exercises: List[dict] = []
    try:
        if w.exercises_json:
            parsed = json.loads(w.exercises_json)
            if isinstance(parsed, list):
                exercises = [e for e in parsed if isinstance(e, dict)]
    except Exception:
        exercises = []

    primary: List[str] = []
    for ex in exercises:
        muscles = ex.get("primary_muscles") or ex.get("muscle_groups") or []
        if isinstance(muscles, list):
            for m in muscles:
                if m and m not in primary:
                    primary.append(m)
    return WorkoutMiniSummary(
        id=w.id or "",
        name=w.name or "Workout",
        type=w.type or "workout",
        scheduled_date=str(w.scheduled_date) if w.scheduled_date else "",
        is_completed=bool(w.is_completed),
        duration_minutes=int(w.duration_minutes or 0),
        exercise_count=len(exercises),
        primary_muscles=primary[:6],
    )


@router.get("/screen-summary", response_model=WorkoutScreenSummaryResponse)
async def get_workouts_screen_summary(
    user_id: str = Query(..., description="User ID"),
    current_user: dict = Depends(get_current_user),
):
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()
        profile_filter = get_active_gym_profile_id(db, user_id)

        rows = db.list_workouts(
            user_id=user_id,
            limit=200,
            offset=0,
            gym_profile_id=profile_filter,
        )
        workouts = [row_to_workout(r) for r in rows]

        now = datetime.utcnow()
        today = datetime(now.year, now.month, now.day)
        start_of_week = today - timedelta(days=today.weekday())
        end_of_week = start_of_week + timedelta(days=7)

        completed_this_week = 0
        planned_this_week = 0
        previous: List[tuple] = []
        upcoming: List[tuple] = []

        for w in workouts:
            if not w.scheduled_date:
                continue
            try:
                sched = datetime.fromisoformat(str(w.scheduled_date).replace("Z", "+00:00"))
            except Exception:
                continue
            local = datetime(sched.year, sched.month, sched.day)

            if start_of_week <= local < end_of_week:
                planned_this_week += 1
                if w.is_completed:
                    completed_this_week += 1

            if w.is_completed:
                previous.append((local, w))
            elif local >= today:
                upcoming.append((local, w))

        previous.sort(key=lambda t: t[0], reverse=True)
        upcoming.sort(key=lambda t: t[0])

        return WorkoutScreenSummaryResponse(
            completed_this_week=completed_this_week,
            planned_this_week=planned_this_week,
            previous_sessions=[_to_mini(w) for _, w in previous[:10]],
            upcoming_workouts=[_to_mini(w) for _, w in upcoming[:10]],
        )
    except Exception as e:
        logger.error(f"screen-summary failed for user {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "screen_summary")
