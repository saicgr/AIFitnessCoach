"""
API endpoints for Weekly Personal Goals.

Enables users to set and track personal weekly fitness challenges:
- single_max: Max reps in one set (e.g., "How many push-ups can I do?")
- weekly_volume: Total reps over the week (e.g., "500 push-ups this week")

Endpoints:
- POST /goals - Create a new weekly goal
- GET /goals/current - Get current week's goals
- GET /goals/history - Get historical goals for an exercise
- POST /goals/{id}/attempt - Record a single_max attempt
- POST /goals/{id}/volume - Add volume to weekly_volume goal
- POST /goals/{id}/complete - Mark goal as completed
- POST /goals/{id}/abandon - Abandon a goal
- GET /records - Get all personal records
- GET /summary - Get quick summary of current goals
- GET /goals/suggestions - Get AI-generated goal suggestions
- POST /goals/suggestions/{id}/dismiss - Dismiss a suggestion
- POST /goals/suggestions/{id}/accept - Create goal from suggestion
"""
from core.db import get_supabase_db
from .personal_goals_endpoints import router as _endpoints_router


from fastapi import APIRouter, Depends, HTTPException, Query, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.timezone_utils import user_today_date
from datetime import datetime, date, timedelta, timezone
from typing import Optional

from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.weekly_personal_goals import (
    CreateGoalRequest, RecordAttemptRequest, AddVolumeRequest,
    WeeklyPersonalGoal, GoalAttempt, PersonalGoalRecord,
    GoalsResponse, GoalHistoryResponse, PersonalRecordsResponse, GoalSummary,
    GoalType, GoalStatus, GoalUnit, GoalProgressPreview,
    WorkoutSyncRequest, WorkoutSyncResponse, SyncedGoalUpdate,
)
from models.goal_suggestions import (
    GoalSuggestionsResponse, GoalSuggestionItem, SuggestionCategoryGroup,
    SuggestionType, SuggestionCategory, GoalVisibility,
    AcceptSuggestionRequest, DismissSuggestionRequest,
    GoalSuggestionsSummary, FriendPreview,
)

router = APIRouter()
logger = get_logger(__name__)


def get_iso_week_boundaries(for_date: date) -> tuple[date, date]:
    """Get Monday and Sunday of the ISO week containing for_date."""
    # ISO weekday: Monday = 0, Sunday = 6 in Python
    week_start = for_date - timedelta(days=for_date.weekday())
    week_end = week_start + timedelta(days=6)
    return week_start, week_end


# ============================================================
# CREATE GOAL
# ============================================================

@router.post("/goals", response_model=WeeklyPersonalGoal)
async def create_goal(user_id: str, request: CreateGoalRequest,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a new weekly personal goal.

    If week_start not provided, uses current week (Monday).
    Automatically fetches personal_best from existing records.
    """
    logger.info(f"Creating goal: user={user_id}, exercise={request.exercise_name}, type={request.goal_type.value}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    try:
        db = get_supabase_db()

        # Get week boundaries
        if request.week_start:
            week_start = request.week_start
        else:
            week_start, _ = get_iso_week_boundaries(user_today_date(http_request))

        week_end = week_start + timedelta(days=6)

        # Check for existing goal this week
        existing = db.client.table("weekly_personal_goals").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).eq(
            "goal_type", request.goal_type.value
        ).eq("week_start", week_start.isoformat()).execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail=f"Goal for {request.exercise_name} ({request.goal_type.value}) already exists this week"
            )

        # Get personal best from records
        pb_result = db.client.table("personal_goal_records").select("record_value").eq(
            "user_id", user_id
        ).eq("exercise_name", request.exercise_name).eq(
            "goal_type", request.goal_type.value
        ).execute()

        personal_best = pb_result.data[0]["record_value"] if pb_result.data else None

        # Create goal
        goal_data = {
            "user_id": user_id,
            "exercise_name": request.exercise_name,
            "goal_type": request.goal_type.value,
            "target_value": request.target_value,
            "unit": request.unit.value,
            "week_start": week_start.isoformat(),
            "week_end": week_end.isoformat(),
            "personal_best": personal_best,
            "status": "active",
            "current_value": 0,
            "is_pr_beaten": False,
        }

        result = db.client.table("weekly_personal_goals").insert(goal_data).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to create goal"), "personal_goals")

        goal = result.data[0]
        logger.info(f"✅ Created goal: {goal['id']} - {request.exercise_name} ({request.goal_type.value})")

        # Log goal creation
        try:
            await log_user_activity(
                user_id=user_id,
                action="goal_created",
                endpoint="/api/v1/personal-goals/goals",
                message=f"Created goal: {request.exercise_name} ({request.goal_type.value})",
                metadata={
                    "goal_id": goal['id'],
                    "exercise_name": request.exercise_name,
                    "goal_type": request.goal_type.value,
                    "target_value": request.target_value,
                },
                status_code=200
            )
        except Exception as e:
            logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": user_id, "failed_action": "goal_created"})

        from .personal_goals_endpoints import _build_goal_response
        return _build_goal_response(goal, user_today_date(http_request))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create goal: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="goal_created",
            error=e,
            endpoint="/api/v1/personal-goals/goals",
            status_code=500
        )
        raise safe_internal_error(e, "personal_goals")


# ============================================================
# GET CURRENT WEEK GOALS
# ============================================================

@router.get("/goals/current", response_model=GoalsResponse)
async def get_current_goals(user_id: str,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get all goals for the current week."""
    logger.info(f"Getting current goals for user: {user_id}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    try:
        db = get_supabase_db()

        # Get current week boundaries
        today = user_today_date(http_request)
        week_start, week_end = get_iso_week_boundaries(today)

        result = db.client.table("weekly_personal_goals").select("*").eq(
            "user_id", user_id
        ).eq("week_start", week_start.isoformat()).order("created_at", desc=True).execute()

        # Get user's friends for friend count calculation
        friends_result = db.client.table("user_connections").select(
            "following_id, follower_id"
        ).or_(
            f"follower_id.eq.{user_id},following_id.eq.{user_id}"
        ).eq("status", "active").execute()

        friend_ids = set()
        for conn in friends_result.data:
            if conn["follower_id"] == user_id:
                friend_ids.add(conn["following_id"])
            else:
                friend_ids.add(conn["follower_id"])

        from .personal_goals_endpoints import _build_goal_response
        goals = []
        prs_count = 0

        for row in result.data:
            goal = _build_goal_response(row, today)

            if goal.is_pr_beaten:
                prs_count += 1

            # Fetch attempts for single_max goals
            if goal.goal_type == GoalType.single_max:
                attempts_result = db.client.table("goal_attempts").select("*").eq(
                    "goal_id", str(goal.id)
                ).order("attempted_at", desc=True).execute()
                goal.attempts = [GoalAttempt(**a) for a in attempts_result.data]

            # Count friends with same exercise/goal_type this week
            if friend_ids:
                friends_goals_result = db.client.table("weekly_personal_goals").select(
                    "id"
                ).in_("user_id", list(friend_ids)).eq(
                    "exercise_name", goal.exercise_name
                ).eq("goal_type", goal.goal_type.value).eq(
                    "week_start", week_start.isoformat()
                ).in_("visibility", ["friends", "public"]).execute()
                goal.friends_count = len(friends_goals_result.data)

            goals.append(goal)

        return GoalsResponse(
            goals=goals,
            current_week_goals=len(goals),
            total_prs_this_week=prs_count,
        )

    except Exception as e:
        logger.error(f"Failed to get current goals: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


# ============================================================
# RECORD ATTEMPT (for single_max)
# ============================================================

@router.post("/goals/{goal_id}/attempt", response_model=WeeklyPersonalGoal)
async def record_attempt(user_id: str, goal_id: str, request: RecordAttemptRequest,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Record an attempt for a single_max goal.

    Updates current_value if this attempt is the new max.
    Checks if personal record is beaten.
    """
    logger.info(f"Recording attempt: goal={goal_id}, value={request.attempt_value}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    try:
        db = get_supabase_db()

        # Verify goal exists and belongs to user
        goal_result = db.client.table("weekly_personal_goals").select("*").eq(
            "id", goal_id
        ).eq("user_id", user_id).execute()

        if not goal_result.data:
            raise HTTPException(status_code=404, detail="Goal not found")

        goal = goal_result.data[0]

        if goal["goal_type"] != "single_max":
            raise HTTPException(status_code=400, detail="This endpoint is for single_max goals only. Use /volume for weekly_volume goals.")

        if goal["status"] != "active":
            raise HTTPException(status_code=400, detail=f"Goal is not active (status: {goal['status']})")

        # Record the attempt
        attempt_data = {
            "goal_id": goal_id,
            "user_id": user_id,
            "attempt_value": request.attempt_value,
            "attempt_notes": request.attempt_notes,
            "workout_log_id": request.workout_log_id,
        }

        db.client.table("goal_attempts").insert(attempt_data).execute()

        # Update goal if this is a new max
        updates = {}
        if request.attempt_value > goal["current_value"]:
            updates["current_value"] = request.attempt_value

            # Check if PR beaten
            if goal["personal_best"] is None or request.attempt_value > goal["personal_best"]:
                updates["is_pr_beaten"] = True

            # Check if goal target achieved
            if request.attempt_value >= goal["target_value"]:
                updates["status"] = "completed"
                updates["completed_at"] = datetime.now(timezone.utc).isoformat()

        if updates:
            db.client.table("weekly_personal_goals").update(updates).eq("id", goal_id).execute()

        # Fetch updated goal with attempts
        updated = db.client.table("weekly_personal_goals").select("*").eq("id", goal_id).execute()
        if not updated.data:
            raise HTTPException(status_code=404, detail="Goal not found after update")
        attempts = db.client.table("goal_attempts").select("*").eq("goal_id", goal_id).order("attempted_at", desc=True).execute()

        from .personal_goals_endpoints import _build_goal_response
        goal_response = _build_goal_response(updated.data[0], user_today_date(http_request))
        goal_response.attempts = [GoalAttempt(**a) for a in attempts.data]

        logger.info(f"✅ Recorded attempt: {request.attempt_value} reps (new max: {updates.get('current_value', 'no')})")

        return goal_response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to record attempt: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


# ============================================================
# ADD VOLUME (for weekly_volume)
# ============================================================

@router.post("/goals/{goal_id}/volume", response_model=WeeklyPersonalGoal)
async def add_volume(user_id: str, goal_id: str, request: AddVolumeRequest,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Add volume to a weekly_volume goal.

    Increments current_value by the specified amount.
    Checks if personal record is beaten (total volume this week).
    """
    logger.info(f"Adding volume: goal={goal_id}, volume={request.volume_to_add}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    try:
        db = get_supabase_db()

        # Verify goal exists and belongs to user
        goal_result = db.client.table("weekly_personal_goals").select("*").eq(
            "id", goal_id
        ).eq("user_id", user_id).execute()

        if not goal_result.data:
            raise HTTPException(status_code=404, detail="Goal not found")

        goal = goal_result.data[0]

        if goal["goal_type"] != "weekly_volume":
            raise HTTPException(status_code=400, detail="This endpoint is for weekly_volume goals only. Use /attempt for single_max goals.")

        if goal["status"] != "active":
            raise HTTPException(status_code=400, detail=f"Goal is not active (status: {goal['status']})")

        # Calculate new value
        new_value = goal["current_value"] + request.volume_to_add

        updates = {
            "current_value": new_value,
        }

        # Check if PR beaten
        if goal["personal_best"] is None or new_value > goal["personal_best"]:
            updates["is_pr_beaten"] = True

        # Check if goal target achieved
        if new_value >= goal["target_value"]:
            updates["status"] = "completed"
            updates["completed_at"] = datetime.now(timezone.utc).isoformat()

        # Update goal
        db.client.table("weekly_personal_goals").update(updates).eq("id", goal_id).execute()

        # Fetch updated goal
        updated = db.client.table("weekly_personal_goals").select("*").eq("id", goal_id).execute()
        if not updated.data:
            raise HTTPException(status_code=404, detail="Goal not found after update")

        logger.info(f"✅ Added {request.volume_to_add} volume. New total: {new_value}")

        from .personal_goals_endpoints import _build_goal_response
        return _build_goal_response(updated.data[0], user_today_date(http_request))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add volume: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


# ============================================================
# COMPLETE GOAL (manual)
# ============================================================

@router.post("/goals/{goal_id}/complete", response_model=WeeklyPersonalGoal)
async def complete_goal(user_id: str, goal_id: str,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Manually mark a goal as completed."""
    logger.info(f"Completing goal: {goal_id}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    try:
        db = get_supabase_db()

        goal_result = db.client.table("weekly_personal_goals").select("*").eq(
            "id", goal_id
        ).eq("user_id", user_id).execute()

        if not goal_result.data:
            raise HTTPException(status_code=404, detail="Goal not found")

        goal = goal_result.data[0]

        if goal["status"] != "active":
            raise HTTPException(status_code=400, detail=f"Goal is not active (status: {goal['status']})")

        updates = {
            "status": "completed",
            "completed_at": datetime.now(timezone.utc).isoformat(),
        }

        # Check if current value beats PR
        if goal["personal_best"] is None or goal["current_value"] > goal["personal_best"]:
            updates["is_pr_beaten"] = True

        db.client.table("weekly_personal_goals").update(updates).eq("id", goal_id).execute()

        updated = db.client.table("weekly_personal_goals").select("*").eq("id", goal_id).execute()
        if not updated.data:
            raise HTTPException(status_code=404, detail="Goal not found after update")

        logger.info(f"✅ Goal completed: {goal_id}")

        from .personal_goals_endpoints import _build_goal_response
        return _build_goal_response(updated.data[0], user_today_date(http_request))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete goal: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


# ============================================================
# ABANDON GOAL
# ============================================================

@router.post("/goals/{goal_id}/abandon", response_model=WeeklyPersonalGoal)
async def abandon_goal(user_id: str, goal_id: str,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Abandon a goal (mark as abandoned)."""
    logger.info(f"Abandoning goal: {goal_id}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    try:
        db = get_supabase_db()

        goal_result = db.client.table("weekly_personal_goals").select("*").eq(
            "id", goal_id
        ).eq("user_id", user_id).execute()

        if not goal_result.data:
            raise HTTPException(status_code=404, detail="Goal not found")

        goal = goal_result.data[0]

        if goal["status"] != "active":
            raise HTTPException(status_code=400, detail=f"Goal is not active (status: {goal['status']})")

        db.client.table("weekly_personal_goals").update({
            "status": "abandoned",
        }).eq("id", goal_id).execute()

        updated = db.client.table("weekly_personal_goals").select("*").eq("id", goal_id).execute()
        if not updated.data:
            raise HTTPException(status_code=404, detail="Goal not found after update")

        logger.info(f"✅ Goal abandoned: {goal_id}")

        from .personal_goals_endpoints import _build_goal_response
        return _build_goal_response(updated.data[0], user_today_date(http_request))

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to abandon goal: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


@router.delete("/goals/{goal_id}")
async def delete_goal(user_id: str, goal_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Permanently delete a goal."""
    logger.info(f"Deleting goal: {goal_id}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    try:
        db = get_supabase_db()

        goal_result = db.client.table("weekly_personal_goals").select("id").eq(
            "id", goal_id
        ).eq("user_id", user_id).execute()

        if not goal_result.data:
            raise HTTPException(status_code=404, detail="Goal not found")

        # Delete attempts first (foreign key)
        db.client.table("goal_attempts").delete().eq("goal_id", goal_id).execute()

        # Delete the goal
        db.client.table("weekly_personal_goals").delete().eq("id", goal_id).execute()

        logger.info(f"✅ Goal deleted: {goal_id}")

        return {"status": "deleted", "goal_id": goal_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete goal: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


# ============================================================
# GET GOAL HISTORY
# ============================================================

@router.get("/goals/history", response_model=GoalHistoryResponse)
async def get_goal_history(
    user_id: str,
    exercise_name: str,
    goal_type: GoalType,
    http_request: Request,
    limit: int = Query(12, ge=1, le=52),
    current_user: dict = Depends(get_current_user),
):
    """Get historical goals for a specific exercise/goal_type combination."""
    logger.info(f"Getting goal history: user={user_id}, exercise={exercise_name}, type={goal_type.value}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

    try:
        db = get_supabase_db()

        result = db.client.table("weekly_personal_goals").select("*").eq(
            "user_id", user_id
        ).eq("exercise_name", exercise_name).eq(
            "goal_type", goal_type.value
        ).order("week_start", desc=True).limit(limit).execute()

        # Get all-time best
        record_result = db.client.table("personal_goal_records").select("record_value").eq(
            "user_id", user_id
        ).eq("exercise_name", exercise_name).eq(
            "goal_type", goal_type.value
        ).execute()

        all_time_best = record_result.data[0]["record_value"] if record_result.data else None

        from .personal_goals_endpoints import _build_goal_response
        today = user_today_date(http_request)
        weeks = [_build_goal_response(w, today) for w in result.data]

        return GoalHistoryResponse(
            exercise_name=exercise_name,
            goal_type=goal_type,
            weeks=weeks,
            all_time_best=all_time_best,
            total_weeks=len(weeks),
        )

    except Exception as e:
        logger.error(f"Failed to get goal history: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


# ============================================================
# GET PERSONAL RECORDS
# ============================================================


# Include secondary endpoints
router.include_router(_endpoints_router)
