"""
Workout milestones progress — next-numeric-threshold tracking.

GET /api/v1/workouts/milestones — returns the user's progress toward the
next workout-count milestone, plus any milestone crossed in the last 7 days.

Distinct from `api/v1/milestones.py` (definition-driven catalog with tiers/
points/celebration UI). This endpoint backs the home `WorkoutMilestoneCard`
which only needs a count + next-threshold + just-crossed flag.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)

# Numeric thresholds aligned with WorkoutMilestoneCard expectations
MILESTONE_THRESHOLDS = [10, 25, 50, 100, 250, 500, 1000]


class WorkoutMilestonesResponse(BaseModel):
    total_workouts: int
    next_milestone: int
    remaining: int
    just_crossed: Optional[int] = None


@router.get("/milestones", response_model=WorkoutMilestonesResponse)
async def get_workout_milestones(
    current_user: dict = Depends(get_current_user),
) -> WorkoutMilestonesResponse:
    """
    Return next milestone progress for completed workout count.

    Counts `workout_logs` rows for the user where `completed_at IS NOT NULL`.
    Returns the next threshold strictly above the total, the remaining count,
    and (if a threshold was crossed in the last 7 days) which threshold.
    """
    user_id = current_user.get("id") or current_user.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Missing user id")

    try:
        db = get_supabase_db()

        # Count completed workout_logs (completed_at NOT NULL).
        # Supabase python client: use head=True+count="exact" to avoid pulling rows.
        total_resp = (
            db.client.table("workout_logs")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .not_.is_("completed_at", "null")
            .execute()
        )
        total = int(total_resp.count or 0)

        # Detect a threshold crossed in the last 7 days: count completed
        # workouts older than 7 days; the delta vs total reveals recent ones.
        cutoff = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
        old_resp = (
            db.client.table("workout_logs")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .not_.is_("completed_at", "null")
            .lt("completed_at", cutoff)
            .execute()
        )
        prior_total = int(old_resp.count or 0)

        just_crossed: Optional[int] = None
        for t in MILESTONE_THRESHOLDS:
            # Crossed within the last 7 days iff prior_total < t <= total.
            if prior_total < t <= total:
                just_crossed = t
                # Don't break — pick the highest threshold crossed in window.

        # Next milestone strictly above total. If beyond the top, repeat top.
        next_milestone = next(
            (t for t in MILESTONE_THRESHOLDS if t > total),
            MILESTONE_THRESHOLDS[-1],
        )
        remaining = max(next_milestone - total, 0)

        return WorkoutMilestonesResponse(
            total_workouts=total,
            next_milestone=next_milestone,
            remaining=remaining,
            just_crossed=just_crossed,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"workout milestones lookup failed user={user_id}: {e}",
            exc_info=True,
        )
        raise HTTPException(
            status_code=500,
            detail=f"workout_milestones_failed: {e.__class__.__name__}",
        )
