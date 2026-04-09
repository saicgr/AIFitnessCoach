"""Secondary endpoints for personal_goals.  Sub-router included by main module."""
from typing import Optional
from datetime import datetime, timedelta, date
from fastapi import APIRouter, Depends, HTTPException, Query
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from models.weekly_personal_goals import (
    PersonalRecordsResponse, GoalSummary, WeeklyPersonalGoal,
    WorkoutSyncRequest, WorkoutSyncResponse, SyncedGoalUpdate,
    GoalProgressPreview, GoalType, PersonalGoalRecord,
)
from core.activity_logger import log_user_activity, log_user_error
from api.v1.goal_social import get_iso_week_boundaries
from models.goal_suggestions import (
    GoalSuggestionsResponse, GoalSuggestionItem, SuggestionCategoryGroup,
    SuggestionType, SuggestionCategory, GoalVisibility,
    AcceptSuggestionRequest, DismissSuggestionRequest,
    GoalSuggestionsSummary, FriendPreview,
)

from .personal_goals_endpoints_part2 import (  # noqa: F401
    get_suggestions_summary,
    _generate_performance_suggestions,
    _generate_friends_suggestions,
    _generate_new_challenge_suggestions,
    _build_suggestions_response,
    _extract_friends_preview,
    sync_workout_with_goals,
)

router = APIRouter()

@router.get("/records", response_model=PersonalRecordsResponse)
async def get_personal_records(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get all personal records for a user."""
    logger.info(f"Getting personal records for user: {user_id}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

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
        logger.error(f"Failed to get personal records: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


# ============================================================
# GET SUMMARY
# ============================================================

@router.get("/summary", response_model=GoalSummary)
async def get_goals_summary(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a quick summary of current week's goals."""
    logger.info(f"Getting goals summary for user: {user_id}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

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
        previews = []

        for goal in result.data:
            if goal["status"] == "active":
                active += 1
                if len(previews) < 3:
                    target = float(goal.get("target_value", 1) or 1)
                    current = float(goal.get("current_value", 0) or 0)
                    previews.append({
                        "exercise_name": goal["exercise_name"],
                        "current_value": current,
                        "target_value": target,
                        "unit": goal.get("unit", "reps"),
                        "progress_percentage": round(min(100.0, current / max(1.0, target) * 100), 1),
                    })
            elif goal["status"] == "completed":
                completed += 1

            if goal["is_pr_beaten"]:
                prs += 1

            if goal["goal_type"] == "weekly_volume":
                volume += float(goal.get("current_value", 0) or 0)

        return GoalSummary(
            active_goals=active,
            completed_this_week=completed,
            prs_this_week=prs,
            total_volume_this_week=volume,
            active_goal_previews=[GoalProgressPreview(**p) for p in previews],
        )

    except Exception as e:
        logger.error(f"Failed to get goals summary: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


# ============================================================
# WORKOUT SYNC - Auto-update goals after workout completion
# ============================================================

@router.post("/workout-sync", response_model=WorkoutSyncResponse)
async def sync_workout_with_goals(user_id: str, request: WorkoutSyncRequest,
    current_user: dict = Depends(get_current_user),
):
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

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

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

        # Auto-sync kg single_max goals
        for exercise in request.exercises:
            if exercise.max_weight_kg and exercise.max_weight_kg > 0:
                kg_goals_result = db.client.table("weekly_personal_goals").select("*").eq(
                    "user_id", user_id
                ).eq("exercise_name", exercise.exercise_name).eq(
                    "goal_type", "single_max"
                ).eq("unit", "kg").eq("status", "active").eq(
                    "week_start", week_start.isoformat()
                ).execute()

                for kg_goal in (kg_goals_result.data or []):
                    current = float(kg_goal.get("current_value", 0) or 0)
                    if exercise.max_weight_kg > current:
                        kg_updates = {"current_value": exercise.max_weight_kg}
                        personal_best = kg_goal.get("personal_best")
                        if personal_best is None or exercise.max_weight_kg > float(personal_best):
                            kg_updates["is_pr_beaten"] = True
                        if exercise.max_weight_kg >= float(kg_goal["target_value"]):
                            kg_updates["status"] = "completed"
                            kg_updates["completed_at"] = datetime.now(timezone.utc).isoformat()
                        db.client.table("weekly_personal_goals").update(kg_updates).eq(
                            "id", kg_goal["id"]
                        ).execute()
                        logger.info(f"Updated kg goal for {exercise.exercise_name}: {exercise.max_weight_kg}kg")

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
        logger.error(f"Failed to sync workout with goals: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="workout_goal_sync",
            error=e,
            endpoint="/api/v1/personal-goals/workout-sync",
            status_code=500
        )
        raise safe_internal_error(e, "personal_goals")


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
    current_user: dict = Depends(get_current_user),
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

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

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
                "unit": s.get("unit", "reps"),
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
                "unit": s.get("unit", "reps"),
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
                "unit": s.get("unit", "reps"),
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
        logger.error(f"Failed to get goal suggestions: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


@router.post("/goals/suggestions/{suggestion_id}/dismiss")
async def dismiss_suggestion(
    user_id: str,
    suggestion_id: str,
    request: Optional[DismissSuggestionRequest] = None,
    current_user: dict = Depends(get_current_user),
):
    """Mark a suggestion as dismissed so it won't appear again."""
    logger.info(f"Dismissing suggestion: {suggestion_id} for user: {user_id}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

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
        logger.error(f"Failed to dismiss suggestion: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


@router.post("/goals/suggestions/{suggestion_id}/accept", response_model=WeeklyPersonalGoal)
async def accept_suggestion(
    user_id: str,
    suggestion_id: str,
    request: Optional[AcceptSuggestionRequest] = None,
    current_user: dict = Depends(get_current_user),
):
    """Create a new goal from a suggestion."""
    logger.info(f"Accepting suggestion: {suggestion_id} for user: {user_id}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

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
            "unit": suggestion.get("unit", "reps"),
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
        logger.error(f"Failed to accept suggestion: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")
