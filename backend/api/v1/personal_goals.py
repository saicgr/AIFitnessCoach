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

from fastapi import APIRouter, HTTPException, Query
from datetime import datetime, date, timedelta, timezone
from typing import Optional

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.weekly_personal_goals import (
    CreateGoalRequest, RecordAttemptRequest, AddVolumeRequest,
    WeeklyPersonalGoal, GoalAttempt, PersonalGoalRecord,
    GoalsResponse, GoalHistoryResponse, PersonalRecordsResponse, GoalSummary,
    GoalType, GoalStatus,
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
async def create_goal(user_id: str, request: CreateGoalRequest):
    """
    Create a new weekly personal goal.

    If week_start not provided, uses current week (Monday).
    Automatically fetches personal_best from existing records.
    """
    logger.info(f"Creating goal: user={user_id}, exercise={request.exercise_name}, type={request.goal_type.value}")

    try:
        db = get_supabase_db()

        # Get week boundaries
        if request.week_start:
            week_start = request.week_start
        else:
            week_start, _ = get_iso_week_boundaries(date.today())

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
            "week_start": week_start.isoformat(),
            "week_end": week_end.isoformat(),
            "personal_best": personal_best,
            "status": "active",
            "current_value": 0,
            "is_pr_beaten": False,
        }

        result = db.client.table("weekly_personal_goals").insert(goal_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create goal")

        goal = result.data[0]
        logger.info(f"✅ Created goal: {goal['id']} - {request.exercise_name} ({request.goal_type.value})")

        # Log goal creation
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

        return _build_goal_response(goal, date.today())

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create goal: {e}")
        await log_user_error(
            user_id=user_id,
            action="goal_created",
            error=e,
            endpoint="/api/v1/personal-goals/goals",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# GET CURRENT WEEK GOALS
# ============================================================

@router.get("/goals/current", response_model=GoalsResponse)
async def get_current_goals(user_id: str):
    """Get all goals for the current week."""
    logger.info(f"Getting current goals for user: {user_id}")

    try:
        db = get_supabase_db()

        # Get current week boundaries
        today = date.today()
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
        logger.error(f"Failed to get current goals: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# RECORD ATTEMPT (for single_max)
# ============================================================

@router.post("/goals/{goal_id}/attempt", response_model=WeeklyPersonalGoal)
async def record_attempt(user_id: str, goal_id: str, request: RecordAttemptRequest):
    """
    Record an attempt for a single_max goal.

    Updates current_value if this attempt is the new max.
    Checks if personal record is beaten.
    """
    logger.info(f"Recording attempt: goal={goal_id}, value={request.attempt_value}")

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
        attempts = db.client.table("goal_attempts").select("*").eq("goal_id", goal_id).order("attempted_at", desc=True).execute()

        goal_response = _build_goal_response(updated.data[0], date.today())
        goal_response.attempts = [GoalAttempt(**a) for a in attempts.data]

        logger.info(f"✅ Recorded attempt: {request.attempt_value} reps (new max: {updates.get('current_value', 'no')})")

        return goal_response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to record attempt: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# ADD VOLUME (for weekly_volume)
# ============================================================

@router.post("/goals/{goal_id}/volume", response_model=WeeklyPersonalGoal)
async def add_volume(user_id: str, goal_id: str, request: AddVolumeRequest):
    """
    Add volume to a weekly_volume goal.

    Increments current_value by the specified amount.
    Checks if personal record is beaten (total volume this week).
    """
    logger.info(f"Adding volume: goal={goal_id}, volume={request.volume_to_add}")

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

        logger.info(f"✅ Added {request.volume_to_add} volume. New total: {new_value}")

        return _build_goal_response(updated.data[0], date.today())

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add volume: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# COMPLETE GOAL (manual)
# ============================================================

@router.post("/goals/{goal_id}/complete", response_model=WeeklyPersonalGoal)
async def complete_goal(user_id: str, goal_id: str):
    """Manually mark a goal as completed."""
    logger.info(f"Completing goal: {goal_id}")

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

        logger.info(f"✅ Goal completed: {goal_id}")

        return _build_goal_response(updated.data[0], date.today())

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete goal: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# ABANDON GOAL
# ============================================================

@router.post("/goals/{goal_id}/abandon", response_model=WeeklyPersonalGoal)
async def abandon_goal(user_id: str, goal_id: str):
    """Abandon a goal (mark as abandoned)."""
    logger.info(f"Abandoning goal: {goal_id}")

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

        logger.info(f"✅ Goal abandoned: {goal_id}")

        return _build_goal_response(updated.data[0], date.today())

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to abandon goal: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# GET GOAL HISTORY
# ============================================================

@router.get("/goals/history", response_model=GoalHistoryResponse)
async def get_goal_history(
    user_id: str,
    exercise_name: str,
    goal_type: GoalType,
    limit: int = Query(12, ge=1, le=52),
):
    """Get historical goals for a specific exercise/goal_type combination."""
    logger.info(f"Getting goal history: user={user_id}, exercise={exercise_name}, type={goal_type.value}")

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

        today = date.today()
        weeks = [_build_goal_response(w, today) for w in result.data]

        return GoalHistoryResponse(
            exercise_name=exercise_name,
            goal_type=goal_type,
            weeks=weeks,
            all_time_best=all_time_best,
            total_weeks=len(weeks),
        )

    except Exception as e:
        logger.error(f"Failed to get goal history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# GET PERSONAL RECORDS
# ============================================================

@router.get("/records", response_model=PersonalRecordsResponse)
async def get_personal_records(user_id: str):
    """Get all personal records for a user."""
    logger.info(f"Getting personal records for user: {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("personal_goal_records").select("*").eq(
            "user_id", user_id
        ).order("achieved_at", desc=True).execute()

        return PersonalRecordsResponse(
            records=[PersonalGoalRecord(**r) for r in result.data],
            total_records=len(result.data),
        )

    except Exception as e:
        logger.error(f"Failed to get personal records: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# GET SUMMARY
# ============================================================

@router.get("/summary", response_model=GoalSummary)
async def get_goals_summary(user_id: str):
    """Get a quick summary of current week's goals."""
    logger.info(f"Getting goals summary for user: {user_id}")

    try:
        db = get_supabase_db()

        # Get current week boundaries
        today = date.today()
        week_start, _ = get_iso_week_boundaries(today)

        result = db.client.table("weekly_personal_goals").select("*").eq(
            "user_id", user_id
        ).eq("week_start", week_start.isoformat()).execute()

        active = 0
        completed = 0
        prs = 0
        volume = 0

        for goal in result.data:
            if goal["status"] == "active":
                active += 1
            elif goal["status"] == "completed":
                completed += 1

            if goal["is_pr_beaten"]:
                prs += 1

            if goal["goal_type"] == "weekly_volume":
                volume += goal["current_value"]

        return GoalSummary(
            active_goals=active,
            completed_this_week=completed,
            prs_this_week=prs,
            total_volume_this_week=volume,
        )

    except Exception as e:
        logger.error(f"Failed to get goals summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# WORKOUT SYNC - Auto-update goals after workout completion
# ============================================================

@router.post("/workout-sync", response_model=WorkoutSyncResponse)
async def sync_workout_with_goals(user_id: str, request: WorkoutSyncRequest):
    """
    Sync a completed workout with weekly personal goals.

    After a workout is completed, this endpoint automatically:
    1. Finds active weekly_volume goals matching exercises in the workout
    2. Adds the reps from the workout to those goals (case-insensitive matching)
    3. Updates goal progress and checks for PR/completion

    Note: Only updates weekly_volume goals. single_max goals require explicit attempts.

    Returns list of goals that were updated with their new progress.
    """
    logger.info(f"Syncing workout with goals: user={user_id}, workout_log_id={request.workout_log_id}")
    logger.info(f"Exercises in workout: {[e.exercise_name for e in request.exercises]}")

    try:
        db = get_supabase_db()
        today = date.today()
        week_start, _ = get_iso_week_boundaries(today)

        # Get all active weekly_volume goals for this user in current week
        goals_result = db.client.table("weekly_personal_goals").select("*").eq(
            "user_id", user_id
        ).eq("week_start", week_start.isoformat()).eq(
            "status", "active"
        ).eq("goal_type", "weekly_volume").execute()

        active_goals = goals_result.data if goals_result.data else []
        logger.info(f"Found {len(active_goals)} active weekly_volume goals")

        if not active_goals:
            return WorkoutSyncResponse(
                synced_goals=[],
                total_goals_updated=0,
                total_volume_added=0,
                new_prs=0,
                message="No active weekly_volume goals to sync"
            )

        # Build a map of exercise name (lowercase) -> goal for quick lookup
        goal_map = {}
        for goal in active_goals:
            exercise_lower = goal["exercise_name"].lower().strip()
            goal_map[exercise_lower] = goal

        synced_goals = []
        total_volume_added = 0
        new_prs = 0

        # Process each exercise from the workout
        for exercise in request.exercises:
            exercise_lower = exercise.exercise_name.lower().strip()

            # Check for matching goal (case-insensitive)
            matching_goal = goal_map.get(exercise_lower)
            if not matching_goal:
                logger.debug(f"No matching goal for exercise: {exercise.exercise_name}")
                continue

            goal_id = matching_goal["id"]
            volume_to_add = exercise.total_reps
            if volume_to_add <= 0:
                continue

            # Calculate new values
            old_value = matching_goal["current_value"]
            new_value = old_value + volume_to_add
            target = matching_goal["target_value"]
            personal_best = matching_goal["personal_best"]

            updates = {
                "current_value": new_value,
            }

            # Check if PR beaten
            is_new_pr = False
            if personal_best is None or new_value > personal_best:
                updates["is_pr_beaten"] = True
                is_new_pr = True
                new_prs += 1

            # Check if goal completed
            is_now_completed = False
            if new_value >= target:
                updates["status"] = "completed"
                updates["completed_at"] = datetime.now(timezone.utc).isoformat()
                is_now_completed = True

            # Update the goal
            db.client.table("weekly_personal_goals").update(updates).eq("id", goal_id).execute()

            # Calculate progress percentage
            progress_pct = min(100.0, (new_value / target) * 100) if target > 0 else 0.0

            synced_goals.append(SyncedGoalUpdate(
                goal_id=goal_id,
                exercise_name=matching_goal["exercise_name"],
                goal_type=GoalType.weekly_volume,
                volume_added=volume_to_add,
                new_current_value=new_value,
                target_value=target,
                is_now_completed=is_now_completed,
                is_new_pr=is_new_pr,
                progress_percentage=progress_pct,
            ))

            total_volume_added += volume_to_add
            logger.info(f"Updated goal for {matching_goal['exercise_name']}: +{volume_to_add} reps (now {new_value}/{target})")

        # Log the sync activity
        if synced_goals:
            await log_user_activity(
                user_id=user_id,
                action="workout_goal_sync",
                endpoint="/api/v1/personal-goals/workout-sync",
                message=f"Synced workout with {len(synced_goals)} goals, added {total_volume_added} total reps",
                metadata={
                    "workout_log_id": request.workout_log_id,
                    "goals_updated": len(synced_goals),
                    "total_volume_added": total_volume_added,
                    "new_prs": new_prs,
                    "goal_ids": [g.goal_id for g in synced_goals],
                },
                status_code=200
            )

        # Build response message
        if synced_goals:
            completed_count = sum(1 for g in synced_goals if g.is_now_completed)
            message_parts = [f"Updated {len(synced_goals)} goal{'s' if len(synced_goals) > 1 else ''}"]
            if completed_count > 0:
                message_parts.append(f"{completed_count} completed!")
            if new_prs > 0:
                message_parts.append(f"{new_prs} new PR{'s' if new_prs > 1 else ''}!")
            message = " - ".join(message_parts)
        else:
            message = "No matching goals found for workout exercises"

        return WorkoutSyncResponse(
            synced_goals=synced_goals,
            total_goals_updated=len(synced_goals),
            total_volume_added=total_volume_added,
            new_prs=new_prs,
            message=message,
        )

    except Exception as e:
        logger.error(f"Failed to sync workout with goals: {e}")
        await log_user_error(
            user_id=user_id,
            action="workout_goal_sync",
            error=e,
            endpoint="/api/v1/personal-goals/workout-sync",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def _build_goal_response(row: dict, today: date) -> WeeklyPersonalGoal:
    """Build a WeeklyPersonalGoal response with computed fields."""
    goal = WeeklyPersonalGoal(**row)

    # Calculate progress percentage
    if goal.target_value > 0:
        goal.progress_percentage = min(100.0, (goal.current_value / goal.target_value) * 100)

    # Calculate days remaining
    if isinstance(goal.week_end, str):
        week_end = date.fromisoformat(goal.week_end)
    else:
        week_end = goal.week_end

    goal.days_remaining = max(0, (week_end - today).days + 1)

    return goal


# ============================================================
# GOAL SUGGESTIONS
# ============================================================

@router.get("/goals/suggestions", response_model=GoalSuggestionsResponse)
async def get_goal_suggestions(
    user_id: str,
    force_refresh: bool = Query(False, description="Force regenerate suggestions"),
):
    """
    Get AI-generated goal suggestions organized by category.

    Categories:
    - beat_your_records: Performance-based suggestions from workout history
    - popular_with_friends: Goals friends are currently doing
    - new_challenges: Variety/discovery suggestions

    Returns cached suggestions if fresh (<24h), otherwise generates new ones.
    """
    logger.info(f"Getting goal suggestions for user: {user_id}, force_refresh={force_refresh}")

    try:
        db = get_supabase_db()
        now = datetime.now(timezone.utc)
        today = date.today()
        week_start, _ = get_iso_week_boundaries(today)

        # Check for fresh cached suggestions
        if not force_refresh:
            cached = db.client.table("goal_suggestions").select("*").eq(
                "user_id", user_id
            ).eq("is_dismissed", False).gt(
                "expires_at", now.isoformat()
            ).order("category").order("priority_rank").execute()

            if cached.data and len(cached.data) >= 3:  # Have at least a few suggestions
                return _build_suggestions_response(cached.data, now)

        # Generate new suggestions
        logger.info(f"Generating new suggestions for user: {user_id}")

        # Clear old suggestions
        db.client.table("goal_suggestions").delete().eq("user_id", user_id).execute()

        suggestions_to_insert = []
        expires_at = now + timedelta(hours=24)

        # 1. Performance-based suggestions (Beat Your Records)
        performance_suggestions = await _generate_performance_suggestions(db, user_id, week_start)
        for idx, s in enumerate(performance_suggestions[:4]):
            suggestions_to_insert.append({
                "user_id": user_id,
                "suggestion_type": SuggestionType.PERFORMANCE_BASED.value,
                "exercise_name": s["exercise_name"],
                "goal_type": s["goal_type"],
                "suggested_target": s["target"],
                "reasoning": s["reasoning"],
                "confidence_score": s.get("confidence", 0.8),
                "source_data": s.get("source_data", {}),
                "category": SuggestionCategory.BEAT_YOUR_RECORDS.value,
                "priority_rank": idx,
                "expires_at": expires_at.isoformat(),
            })

        # 2. Popular with friends suggestions
        friends_suggestions = await _generate_friends_suggestions(db, user_id, week_start)
        for idx, s in enumerate(friends_suggestions[:4]):
            suggestions_to_insert.append({
                "user_id": user_id,
                "suggestion_type": SuggestionType.POPULAR_WITH_FRIENDS.value,
                "exercise_name": s["exercise_name"],
                "goal_type": s["goal_type"],
                "suggested_target": s["target"],
                "reasoning": s["reasoning"],
                "confidence_score": s.get("confidence", 0.7),
                "source_data": s.get("source_data", {}),
                "category": SuggestionCategory.POPULAR_WITH_FRIENDS.value,
                "priority_rank": idx,
                "expires_at": expires_at.isoformat(),
            })

        # 3. New challenges suggestions
        new_challenges = await _generate_new_challenge_suggestions(db, user_id, week_start)
        for idx, s in enumerate(new_challenges[:4]):
            suggestions_to_insert.append({
                "user_id": user_id,
                "suggestion_type": SuggestionType.NEW_CHALLENGE.value,
                "exercise_name": s["exercise_name"],
                "goal_type": s["goal_type"],
                "suggested_target": s["target"],
                "reasoning": s["reasoning"],
                "confidence_score": s.get("confidence", 0.6),
                "source_data": s.get("source_data", {}),
                "category": SuggestionCategory.NEW_CHALLENGES.value,
                "priority_rank": idx,
                "expires_at": expires_at.isoformat(),
            })

        # Insert all suggestions
        if suggestions_to_insert:
            db.client.table("goal_suggestions").insert(suggestions_to_insert).execute()

        # Fetch and return
        result = db.client.table("goal_suggestions").select("*").eq(
            "user_id", user_id
        ).eq("is_dismissed", False).order("category").order("priority_rank").execute()

        return _build_suggestions_response(result.data, now)

    except Exception as e:
        logger.error(f"Failed to get goal suggestions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/goals/suggestions/{suggestion_id}/dismiss")
async def dismiss_suggestion(
    user_id: str,
    suggestion_id: str,
    request: Optional[DismissSuggestionRequest] = None,
):
    """Mark a suggestion as dismissed so it won't appear again."""
    logger.info(f"Dismissing suggestion: {suggestion_id} for user: {user_id}")

    try:
        db = get_supabase_db()

        # Verify suggestion belongs to user
        result = db.client.table("goal_suggestions").select("id").eq(
            "id", suggestion_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Suggestion not found")

        # Mark as dismissed
        db.client.table("goal_suggestions").update({
            "is_dismissed": True
        }).eq("id", suggestion_id).execute()

        logger.info(f"✅ Dismissed suggestion: {suggestion_id}")

        return {"status": "dismissed", "suggestion_id": suggestion_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to dismiss suggestion: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/goals/suggestions/{suggestion_id}/accept", response_model=WeeklyPersonalGoal)
async def accept_suggestion(
    user_id: str,
    suggestion_id: str,
    request: Optional[AcceptSuggestionRequest] = None,
):
    """Create a new goal from a suggestion."""
    logger.info(f"Accepting suggestion: {suggestion_id} for user: {user_id}")

    try:
        db = get_supabase_db()

        # Fetch suggestion
        suggestion_result = db.client.table("goal_suggestions").select("*").eq(
            "id", suggestion_id
        ).eq("user_id", user_id).execute()

        if not suggestion_result.data:
            raise HTTPException(status_code=404, detail="Suggestion not found")

        suggestion = suggestion_result.data[0]

        # Get week boundaries
        today = date.today()
        week_start, week_end = get_iso_week_boundaries(today)

        # Check for existing goal
        existing = db.client.table("weekly_personal_goals").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", suggestion["exercise_name"]).eq(
            "goal_type", suggestion["goal_type"]
        ).eq("week_start", week_start.isoformat()).execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail=f"Goal for {suggestion['exercise_name']} already exists this week"
            )

        # Get personal best
        pb_result = db.client.table("personal_goal_records").select("record_value").eq(
            "user_id", user_id
        ).eq("exercise_name", suggestion["exercise_name"]).eq(
            "goal_type", suggestion["goal_type"]
        ).execute()

        personal_best = pb_result.data[0]["record_value"] if pb_result.data else None

        # Determine target value
        target_value = suggestion["suggested_target"]
        if request and request.target_override:
            target_value = request.target_override

        # Determine visibility
        visibility = GoalVisibility.FRIENDS.value
        if request and request.visibility:
            visibility = request.visibility.value

        # Create goal
        goal_data = {
            "user_id": user_id,
            "exercise_name": suggestion["exercise_name"],
            "goal_type": suggestion["goal_type"],
            "target_value": target_value,
            "week_start": week_start.isoformat(),
            "week_end": week_end.isoformat(),
            "personal_best": personal_best,
            "status": "active",
            "current_value": 0,
            "is_pr_beaten": False,
            "source_suggestion_id": suggestion_id,
            "visibility": visibility,
        }

        result = db.client.table("weekly_personal_goals").insert(goal_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create goal")

        # Mark suggestion as used (dismissed)
        db.client.table("goal_suggestions").update({
            "is_dismissed": True
        }).eq("id", suggestion_id).execute()

        goal = result.data[0]
        logger.info(f"✅ Created goal from suggestion: {goal['id']}")

        return _build_goal_response(goal, today)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to accept suggestion: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/goals/suggestions/summary", response_model=GoalSuggestionsSummary)
async def get_suggestions_summary(user_id: str):
    """Get a quick summary of available suggestions."""
    logger.info(f"Getting suggestions summary for user: {user_id}")

    try:
        db = get_supabase_db()
        now = datetime.now(timezone.utc)

        result = db.client.table("goal_suggestions").select("category, expires_at").eq(
            "user_id", user_id
        ).eq("is_dismissed", False).gt(
            "expires_at", now.isoformat()
        ).execute()

        if not result.data:
            return GoalSuggestionsSummary(
                total_suggestions=0,
                categories_with_suggestions=0,
                has_friend_suggestions=False,
                suggestions_expire_at=None,
            )

        categories = set(s["category"] for s in result.data)
        has_friends = SuggestionCategory.POPULAR_WITH_FRIENDS.value in categories
        min_expires = min(s["expires_at"] for s in result.data)

        return GoalSuggestionsSummary(
            total_suggestions=len(result.data),
            categories_with_suggestions=len(categories),
            has_friend_suggestions=has_friends,
            suggestions_expire_at=datetime.fromisoformat(min_expires.replace("Z", "+00:00")) if min_expires else None,
        )

    except Exception as e:
        logger.error(f"Failed to get suggestions summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# SUGGESTION GENERATION HELPERS
# ============================================================

async def _generate_performance_suggestions(db, user_id: str, week_start: date) -> list:
    """
    Generate performance-based suggestions from workout history.
    Analyzes past goals and workout logs to suggest beatable targets.
    """
    suggestions = []

    try:
        # Get personal records
        records = db.client.table("personal_goal_records").select("*").eq(
            "user_id", user_id
        ).execute()

        # Get past completed goals
        past_goals = db.client.table("weekly_personal_goals").select("*").eq(
            "user_id", user_id
        ).eq("status", "completed").order("week_end", desc=True).limit(20).execute()

        # Create suggestions for exercises with history
        exercises_with_history = {}

        for record in records.data:
            exercise = record["exercise_name"]
            goal_type = record["goal_type"]
            current_best = record["record_value"]

            key = f"{exercise}_{goal_type}"
            if key not in exercises_with_history:
                exercises_with_history[key] = {
                    "exercise_name": exercise,
                    "goal_type": goal_type,
                    "best": current_best,
                    "recent_values": [],
                }

        # Add recent goal values
        for goal in past_goals.data:
            key = f"{goal['exercise_name']}_{goal['goal_type']}"
            if key in exercises_with_history and goal["current_value"] > 0:
                exercises_with_history[key]["recent_values"].append(goal["current_value"])

        # Generate suggestions
        for key, data in exercises_with_history.items():
            best = data["best"]
            recent = data["recent_values"][:3]

            # Calculate suggested target (5-15% above best)
            if best:
                increase_pct = 0.10  # 10% increase
                target = int(best * (1 + increase_pct))

                suggestions.append({
                    "exercise_name": data["exercise_name"],
                    "goal_type": data["goal_type"],
                    "target": target,
                    "reasoning": f"Your best is {best} reps. Try to beat it with {target}!",
                    "confidence": 0.85,
                    "source_data": {
                        "personal_best": best,
                        "recent_values": recent,
                        "increase_percentage": increase_pct * 100,
                    },
                })

        # If no history, suggest common exercises
        if not suggestions:
            common_exercises = [
                ("Push-ups", "single_max", 30, "Start with 30 push-ups and track your progress!"),
                ("Squats", "weekly_volume", 100, "Do 100 squats this week for stronger legs!"),
                ("Pull-ups", "single_max", 10, "Challenge yourself with 10 pull-ups!"),
                ("Plank", "single_max", 60, "Hold a plank for 60 seconds!"),
            ]
            for exercise, goal_type, target, reasoning in common_exercises:
                suggestions.append({
                    "exercise_name": exercise,
                    "goal_type": goal_type,
                    "target": target,
                    "reasoning": reasoning,
                    "confidence": 0.6,
                    "source_data": {"type": "default_suggestion"},
                })

    except Exception as e:
        logger.error(f"Error generating performance suggestions: {e}")

    return suggestions[:4]


async def _generate_friends_suggestions(db, user_id: str, week_start: date) -> list:
    """
    Generate suggestions based on what friends are doing.
    """
    suggestions = []

    try:
        # Get user's friends
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

        if not friend_ids:
            return []

        # Get friends' current goals
        friends_goals = db.client.table("weekly_personal_goals").select(
            "exercise_name, goal_type, target_value, user_id"
        ).in_("user_id", list(friend_ids)).eq(
            "week_start", week_start.isoformat()
        ).eq("status", "active").eq("visibility", "friends").execute()

        # Aggregate by exercise/type
        goal_counts = {}
        for goal in friends_goals.data:
            key = f"{goal['exercise_name']}_{goal['goal_type']}"
            if key not in goal_counts:
                goal_counts[key] = {
                    "exercise_name": goal["exercise_name"],
                    "goal_type": goal["goal_type"],
                    "count": 0,
                    "targets": [],
                    "friend_ids": [],
                }
            goal_counts[key]["count"] += 1
            goal_counts[key]["targets"].append(goal["target_value"])
            goal_counts[key]["friend_ids"].append(goal["user_id"])

        # Sort by popularity
        sorted_goals = sorted(goal_counts.values(), key=lambda x: x["count"], reverse=True)

        for data in sorted_goals[:4]:
            avg_target = int(sum(data["targets"]) / len(data["targets"]))
            friend_count = data["count"]

            suggestions.append({
                "exercise_name": data["exercise_name"],
                "goal_type": data["goal_type"],
                "target": avg_target,
                "reasoning": f"{friend_count} friend{'s' if friend_count > 1 else ''} doing this goal!",
                "confidence": min(0.9, 0.5 + (friend_count * 0.1)),
                "source_data": {
                    "friend_count": friend_count,
                    "average_target": avg_target,
                    "friend_ids": data["friend_ids"][:5],
                },
            })

    except Exception as e:
        logger.error(f"Error generating friends suggestions: {e}")

    return suggestions


async def _generate_new_challenge_suggestions(db, user_id: str, week_start: date) -> list:
    """
    Generate new challenge suggestions for variety.
    """
    suggestions = []

    try:
        # Get exercises user has done before
        past_exercises = db.client.table("weekly_personal_goals").select(
            "exercise_name"
        ).eq("user_id", user_id).execute()

        done_exercises = set(g["exercise_name"] for g in past_exercises.data)

        # Suggest exercises they haven't tried
        new_challenges = [
            ("Burpees", "weekly_volume", 50, "Try 50 burpees this week for full-body conditioning!"),
            ("Lunges", "weekly_volume", 100, "100 lunges for stronger legs and balance!"),
            ("Dips", "single_max", 20, "How many dips can you do? Start with 20!"),
            ("Mountain Climbers", "weekly_volume", 200, "200 mountain climbers for cardio power!"),
            ("Jumping Jacks", "weekly_volume", 300, "300 jumping jacks to boost your heart rate!"),
            ("Sit-ups", "weekly_volume", 100, "100 sit-ups for core strength!"),
            ("Calf Raises", "weekly_volume", 150, "150 calf raises for stronger calves!"),
            ("Box Jumps", "weekly_volume", 50, "50 box jumps for explosive power!"),
        ]

        for exercise, goal_type, target, reasoning in new_challenges:
            if exercise not in done_exercises:
                suggestions.append({
                    "exercise_name": exercise,
                    "goal_type": goal_type,
                    "target": target,
                    "reasoning": reasoning,
                    "confidence": 0.65,
                    "source_data": {"type": "new_challenge"},
                })

        # If all exercises tried, suggest volume challenges
        if len(suggestions) < 4:
            for exercise, goal_type, target, reasoning in new_challenges[:4]:
                if len(suggestions) >= 4:
                    break
                suggestions.append({
                    "exercise_name": exercise,
                    "goal_type": goal_type,
                    "target": target,
                    "reasoning": reasoning,
                    "confidence": 0.5,
                    "source_data": {"type": "variety_challenge"},
                })

    except Exception as e:
        logger.error(f"Error generating new challenge suggestions: {e}")

    return suggestions[:4]


def _build_suggestions_response(data: list, now: datetime) -> GoalSuggestionsResponse:
    """Build the categorized suggestions response."""
    categories_map = {
        SuggestionCategory.BEAT_YOUR_RECORDS.value: {
            "category_id": "beat_your_records",
            "category_title": "Beat Your Records",
            "category_icon": "emoji_events",
            "accent_color": "#FF9800",
            "suggestions": [],
        },
        SuggestionCategory.POPULAR_WITH_FRIENDS.value: {
            "category_id": "popular_with_friends",
            "category_title": "Popular with Friends",
            "category_icon": "people",
            "accent_color": "#9C27B0",
            "suggestions": [],
        },
        SuggestionCategory.NEW_CHALLENGES.value: {
            "category_id": "new_challenges",
            "category_title": "New Challenges",
            "category_icon": "explore",
            "accent_color": "#00BCD4",
            "suggestions": [],
        },
    }

    expires_at = now + timedelta(hours=24)
    total = 0

    for item in data:
        category = item["category"]
        if category in categories_map:
            suggestion = GoalSuggestionItem(
                id=item["id"],
                exercise_name=item["exercise_name"],
                goal_type=item["goal_type"],
                suggested_target=item["suggested_target"],
                reasoning=item["reasoning"],
                suggestion_type=item["suggestion_type"],
                category=item["category"],
                confidence_score=item["confidence_score"],
                source_data=item.get("source_data"),
                friends_on_goal=_extract_friends_preview(item.get("source_data")),
                friends_count=item.get("source_data", {}).get("friend_count", 0) if item.get("source_data") else 0,
                created_at=datetime.fromisoformat(item["created_at"].replace("Z", "+00:00")),
                expires_at=datetime.fromisoformat(item["expires_at"].replace("Z", "+00:00")),
            )
            categories_map[category]["suggestions"].append(suggestion)
            expires_at = suggestion.expires_at
            total += 1

    # Build category list (only non-empty)
    categories = [
        SuggestionCategoryGroup(**cat_data)
        for cat_data in categories_map.values()
        if cat_data["suggestions"]
    ]

    return GoalSuggestionsResponse(
        categories=categories,
        generated_at=now,
        expires_at=expires_at,
        total_suggestions=total,
    )


def _extract_friends_preview(source_data: dict) -> list:
    """Extract friend previews from source data if available."""
    if not source_data or "friend_ids" not in source_data:
        return []

    # In a real implementation, we'd fetch friend details
    # For now, return empty - the full data will come from goal_social endpoints
    return []


# ============================================================
# WORKOUT SYNC - Auto-update goals from completed workouts
# ============================================================

@router.post("/workout-sync", response_model=WorkoutSyncResponse)
async def sync_workout_with_goals(user_id: str, request: WorkoutSyncRequest):
    """
    Sync workout data with personal weekly goals.

    After completing a workout, this endpoint:
    1. Finds active weekly_volume goals matching exercises done
    2. Adds the reps from the workout to those goals
    3. Checks if any PRs were beaten or goals completed

    This enables the "Challenges of the Week" feature where users
    set goals like "500 push-ups this week" and have workout reps
    automatically count towards their goal.

    Args:
        user_id: User ID
        request: Workout performance data with exercise names and reps

    Returns:
        List of goals that were updated with progress info
    """
    logger.info(f"Syncing workout with goals for user: {user_id}")

    try:
        db = get_supabase_db()

        # Get current week boundaries
        today = date.today()
        week_start, _ = get_iso_week_boundaries(today)

        # Get user's active weekly_volume goals for this week
        active_goals_result = db.client.table("weekly_personal_goals").select("*").eq(
            "user_id", user_id
        ).eq("week_start", week_start.isoformat()).eq(
            "status", "active"
        ).eq("goal_type", "weekly_volume").execute()

        active_goals = {g["exercise_name"].lower(): g for g in active_goals_result.data}

        if not active_goals:
            logger.info(f"No active weekly_volume goals found for user {user_id}")
            return WorkoutSyncResponse(
                message="No active weekly volume goals to sync",
                total_goals_updated=0,
            )

        synced_updates = []
        total_volume_added = 0
        new_prs = 0

        # Match exercises from workout to goals (case-insensitive)
        for exercise_perf in request.exercises:
            exercise_key = exercise_perf.exercise_name.lower()

            # Try to find matching goal
            goal = active_goals.get(exercise_key)

            if not goal:
                # Try partial matching (e.g., "Push-ups" matches "Push-ups (Standard)")
                for goal_name, g in active_goals.items():
                    if exercise_key in goal_name or goal_name in exercise_key:
                        goal = g
                        break

            if goal and exercise_perf.total_reps > 0:
                goal_id = goal["id"]
                old_value = goal["current_value"]
                new_value = old_value + exercise_perf.total_reps

                updates = {
                    "current_value": new_value,
                }

                # Check if PR beaten
                is_pr = False
                if goal["personal_best"] is None or new_value > goal["personal_best"]:
                    updates["is_pr_beaten"] = True
                    is_pr = True
                    new_prs += 1

                # Check if goal completed
                is_completed = new_value >= goal["target_value"]
                if is_completed and goal["status"] != "completed":
                    updates["status"] = "completed"
                    updates["completed_at"] = datetime.now(timezone.utc).isoformat()

                # Update the goal
                db.client.table("weekly_personal_goals").update(updates).eq("id", goal_id).execute()

                # Calculate progress
                progress_pct = min(100.0, (new_value / goal["target_value"]) * 100)

                synced_updates.append(SyncedGoalUpdate(
                    goal_id=goal_id,
                    exercise_name=goal["exercise_name"],
                    goal_type=GoalType.weekly_volume,
                    volume_added=exercise_perf.total_reps,
                    new_current_value=new_value,
                    target_value=goal["target_value"],
                    is_now_completed=is_completed,
                    is_new_pr=is_pr,
                    progress_percentage=progress_pct,
                ))

                total_volume_added += exercise_perf.total_reps

                logger.info(
                    f"✅ Updated goal {goal_id}: {goal['exercise_name']} "
                    f"+{exercise_perf.total_reps} reps ({new_value}/{goal['target_value']})"
                )

        # Log the sync activity
        if synced_updates:
            await log_user_activity(
                user_id=user_id,
                action="goals_workout_sync",
                endpoint="/api/v1/personal-goals/workout-sync",
                message=f"Synced {len(synced_updates)} goals from workout",
                metadata={
                    "workout_log_id": request.workout_log_id,
                    "goals_updated": len(synced_updates),
                    "total_volume_added": total_volume_added,
                    "new_prs": new_prs,
                    "synced_goals": [u.goal_id for u in synced_updates],
                },
                status_code=200
            )

        message = f"Updated {len(synced_updates)} goal{'s' if len(synced_updates) != 1 else ''}"
        if new_prs > 0:
            message += f" with {new_prs} new PR{'s' if new_prs != 1 else ''}!"

        return WorkoutSyncResponse(
            synced_goals=synced_updates,
            total_goals_updated=len(synced_updates),
            total_volume_added=total_volume_added,
            new_prs=new_prs,
            message=message,
        )

    except Exception as e:
        logger.error(f"Failed to sync workout with goals: {e}")
        await log_user_error(
            user_id=user_id,
            action="goals_workout_sync",
            error=e,
            endpoint="/api/v1/personal-goals/workout-sync",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))
