"""Second part of personal_goals_endpoints.py (auto-split for size)."""
from typing import List
from datetime import datetime, timedelta, date, timezone
from fastapi import APIRouter, Depends, HTTPException
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from models.goal_suggestions import (
    GoalSuggestionsResponse, GoalSuggestionItem, SuggestionCategoryGroup,
    SuggestionType, SuggestionCategory, GoalVisibility,
    AcceptSuggestionRequest, DismissSuggestionRequest,
    GoalSuggestionsSummary, FriendPreview,
)
from models.weekly_personal_goals import (
    WorkoutSyncRequest, WorkoutSyncResponse, SyncedGoalUpdate,
    GoalType,
)
from core.activity_logger import log_user_activity, log_user_error
from api.v1.goal_social import get_iso_week_boundaries

router = APIRouter()

async def get_suggestions_summary(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get a quick summary of available suggestions."""
    logger.info(f"Getting suggestions summary for user: {user_id}")

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

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
        logger.error(f"Failed to get suggestions summary: {e}", exc_info=True)
        raise safe_internal_error(e, "personal_goals")


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
            timed_exercises = {"Plank", "Wall Sit"}
            for exercise, goal_type, target, reasoning in common_exercises:
                suggestions.append({
                    "exercise_name": exercise,
                    "goal_type": goal_type,
                    "target": target,
                    "reasoning": reasoning,
                    "confidence": 0.6,
                    "source_data": {"type": "default_suggestion"},
                    "unit": "seconds" if exercise in timed_exercises else "reps",
                })

    except Exception as e:
        logger.error(f"Error generating performance suggestions: {e}", exc_info=True)

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
        logger.error(f"Error generating friends suggestions: {e}", exc_info=True)

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

        EXERCISE_DEFAULT_UNITS = {
            "Plank": "seconds",
            "Wall Sit": "seconds",
            "Running": "km",
            "Treadmill Walk": "km",
            "Cycling": "km",
            "Jump Rope": "minutes",
        }

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
                    "unit": EXERCISE_DEFAULT_UNITS.get(exercise, "reps"),
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
                    "unit": EXERCISE_DEFAULT_UNITS.get(exercise, "reps"),
                })

    except Exception as e:
        logger.error(f"Error generating new challenge suggestions: {e}", exc_info=True)

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
async def sync_workout_with_goals(user_id: str, request: WorkoutSyncRequest,
    current_user: dict = Depends(get_current_user),
):
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

    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Unauthorized")

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

        # Auto-sync kg single_max goals
        for exercise_perf in request.exercises:
            if exercise_perf.max_weight_kg and exercise_perf.max_weight_kg > 0:
                kg_goals_result = db.client.table("weekly_personal_goals").select("*").eq(
                    "user_id", user_id
                ).eq("exercise_name", exercise_perf.exercise_name).eq(
                    "goal_type", "single_max"
                ).eq("unit", "kg").eq("status", "active").eq(
                    "week_start", week_start.isoformat()
                ).execute()

                for kg_goal in (kg_goals_result.data or []):
                    current = float(kg_goal.get("current_value", 0) or 0)
                    if exercise_perf.max_weight_kg > current:
                        kg_updates = {"current_value": exercise_perf.max_weight_kg}
                        personal_best = kg_goal.get("personal_best")
                        if personal_best is None or exercise_perf.max_weight_kg > float(personal_best):
                            kg_updates["is_pr_beaten"] = True
                        if exercise_perf.max_weight_kg >= float(kg_goal["target_value"]):
                            kg_updates["status"] = "completed"
                            kg_updates["completed_at"] = datetime.now(timezone.utc).isoformat()
                        db.client.table("weekly_personal_goals").update(kg_updates).eq(
                            "id", kg_goal["id"]
                        ).execute()
                        logger.info(f"✅ Updated kg goal for {exercise_perf.exercise_name}: {exercise_perf.max_weight_kg}kg")

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
        logger.error(f"Failed to sync workout with goals: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="goals_workout_sync",
            error=e,
            endpoint="/api/v1/personal-goals/workout-sync",
            status_code=500
        )
        raise safe_internal_error(e, "personal_goals")
