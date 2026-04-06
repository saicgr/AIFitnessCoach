"""Secondary endpoints for consistency.  Sub-router included by main module.
Consistency Insights API Endpoints
===================================
Provides insights into workout consistency, streaks, and patterns
to help users stay consistent with their fitness journey.

Endpoints:
- GET /consistency/insights - Get comprehensive consistency insights
- GET /consistency/patterns - Get detailed time/day patterns
- GET /consistency/calendar - Get calendar heatmap data
- POST /consistency/streak-recovery - Initiate streak recovery
"""
from typing import Optional
from collections import defaultdict
from datetime import datetime, timedelta, date
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, Request
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.timezone_utils import resolve_timezone, get_user_today
from core.exceptions import safe_internal_error
from models.consistency import StreakRecoveryRequest, StreakRecoveryResponse

router = APIRouter()
@router.get("/search-exercise", tags=["Consistency"])
async def search_exercise_history(
    request: Request,
    user_id: str = Query(..., description="User ID"),
    exercise_name: str = Query(..., description="Exercise name to search for"),
    weeks: int = Query(52, ge=1, le=104, description="Number of weeks to search back"),
    current_user: dict = Depends(get_current_user),
):
    """
    Search for all occurrences of an exercise in workout history.

    Returns:
    - List of dates where this exercise was performed
    - Summary for each occurrence (sets, best weight × reps, PR status)
    - Matching dates for heatmap highlighting
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        user_tz = resolve_timezone(request, db, user_id)
        today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
        start_date = today - timedelta(days=weeks * 7)

        # Search performance logs for this exercise
        # Use ILIKE for case-insensitive partial matching
        perf_response = db.client.table("performance_logs").select(
            "workout_log_id, exercise_name, exercise_id, set_number, reps_completed, weight_kg, rpe, rir, is_pr, recorded_at"
        ).eq("user_id", user_id).ilike(
            "exercise_name", f"%{exercise_name}%"
        ).gte(
            "recorded_at", start_date.isoformat()
        ).order("recorded_at", desc=True).execute()

        if not perf_response.data:
            return {
                "exercise_name": exercise_name,
                "total_results": 0,
                "results": [],
                "matching_dates": [],
            }

        # Get workout log IDs to fetch workout details
        workout_log_ids = list(set(row["workout_log_id"] for row in perf_response.data if row.get("workout_log_id")))

        # Get workout logs with workout info
        log_response = db.client.table("workout_logs").select(
            "id, workout_id, completed_at"
        ).in_("id", workout_log_ids).execute()

        log_map = {log["id"]: log for log in (log_response.data or [])}

        # Get workout names
        workout_ids = list(set(log["workout_id"] for log in (log_response.data or []) if log.get("workout_id")))
        workout_response = db.client.table("workouts").select(
            "id, name, scheduled_date"
        ).in_("id", workout_ids).execute()

        workout_map = {w["id"]: w for w in (workout_response.data or [])}

        # Group performance data by workout log
        by_workout_log = defaultdict(list)
        for row in perf_response.data:
            if row.get("workout_log_id"):
                by_workout_log[row["workout_log_id"]].append(row)

        # Build results
        results = []
        matching_dates = set()

        for log_id, sets in by_workout_log.items():
            log_info = log_map.get(log_id, {})
            workout_id = log_info.get("workout_id")
            workout_info = workout_map.get(workout_id, {})

            # Determine date
            completed_at = log_info.get("completed_at")
            if completed_at:
                result_date = completed_at[:10] if "T" in completed_at else completed_at
            else:
                scheduled = workout_info.get("scheduled_date", "")
                result_date = scheduled[:10] if "T" in scheduled else scheduled

            if not result_date:
                continue

            matching_dates.add(result_date)

            # Calculate stats
            total_sets = len(sets)
            best_weight = 0.0
            best_reps = 0
            total_volume = 0.0
            has_pr = False
            pr_type = None
            all_rpes = []

            for s in sets:
                weight = s.get("weight_kg") or 0
                reps = s.get("reps_completed") or 0
                total_volume += weight * reps

                if weight > best_weight:
                    best_weight = weight
                    best_reps = reps

                if s.get("is_pr"):
                    has_pr = True
                    pr_type = "weight"  # Default

                if s.get("rpe"):
                    all_rpes.append(s["rpe"])

            avg_rpe = round(sum(all_rpes) / len(all_rpes), 1) if all_rpes else None

            # Use the actual exercise name from the first set (might be slightly different due to search)
            actual_name = sets[0].get("exercise_name", exercise_name)

            results.append({
                "date": result_date,
                "workout_id": workout_id or "",
                "workout_name": workout_info.get("name", "Workout"),
                "exercise_name": actual_name,
                "sets_completed": total_sets,
                "best_weight": best_weight,
                "best_reps": best_reps,
                "total_volume": round(total_volume, 1),
                "has_pr": has_pr,
                "pr_type": pr_type,
                "average_rpe": avg_rpe,
            })

        # Sort by date descending
        results.sort(key=lambda x: x["date"], reverse=True)

        return {
            "exercise_name": exercise_name,
            "total_results": len(results),
            "results": results,
            "matching_dates": sorted(list(matching_dates), reverse=True),
        }

    except Exception as e:
        logger.error(f"Error searching exercise history: {e}")
        raise safe_internal_error(e, "search_exercise_history")


@router.get("/exercise-suggestions", tags=["Consistency"])
async def get_exercise_suggestions(
    user_id: str = Query(..., description="User ID"),
    query: str = Query("", description="Search query for autocomplete"),
    limit: int = Query(10, ge=1, le=50, description="Max suggestions to return"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get exercise name suggestions for autocomplete.

    Returns exercises the user has performed, filtered by query,
    sorted by frequency of use.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Get distinct exercise names from user's performance logs
        # with count of how many times performed
        if query:
            perf_response = db.client.table("performance_logs").select(
                "exercise_name, recorded_at"
            ).eq("user_id", user_id).ilike(
                "exercise_name", f"%{query}%"
            ).execute()
        else:
            perf_response = db.client.table("performance_logs").select(
                "exercise_name, recorded_at"
            ).eq("user_id", user_id).execute()

        if not perf_response.data:
            return []

        # Count occurrences and track last performed
        exercise_stats = defaultdict(lambda: {"count": 0, "last": None})

        for row in perf_response.data:
            name = row["exercise_name"]
            recorded = row.get("recorded_at")

            exercise_stats[name]["count"] += 1

            if recorded:
                current_last = exercise_stats[name]["last"]
                if current_last is None or recorded > current_last:
                    exercise_stats[name]["last"] = recorded

        # Sort by count (most frequent first)
        sorted_exercises = sorted(
            exercise_stats.items(),
            key=lambda x: x[1]["count"],
            reverse=True
        )[:limit]

        return [
            {
                "name": name,
                "times_performed": stats["count"],
                "last_performed": stats["last"][:10] if stats["last"] and "T" in stats["last"] else stats["last"],
            }
            for name, stats in sorted_exercises
        ]

    except Exception as e:
        logger.error(f"Error fetching exercise suggestions: {e}")
        raise safe_internal_error(e, "get_exercise_suggestions")


@router.post("/streak-recovery", response_model=StreakRecoveryResponse, tags=["Consistency"])
async def initiate_streak_recovery(
    http_request: Request,
    request: StreakRecoveryRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Initiate a streak recovery attempt.

    Called when a user returns after breaking their streak.
    Records the attempt and provides encouraging guidance.
    """
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        user_id = request.user_id
        recovery_type = request.recovery_type

        logger.info(f"Initiating streak recovery for user {user_id}")

        # Get user's last workout info
        user_response = safe_maybe_single(
            db.client.table("users").select(
                "current_streak, last_workout_date"
            ).eq("id", user_id).maybe_single()
        )

        last_workout_date = None
        previous_streak = 0

        if user_response.data:
            last_workout_str = user_response.data.get("last_workout_date")
            if last_workout_str:
                last_workout_date = date.fromisoformat(last_workout_str) if isinstance(last_workout_str, str) else last_workout_str

        # Calculate days since last workout
        user_tz = resolve_timezone(http_request, db, user_id)
        user_today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()
        days_since = 0
        if last_workout_date:
            days_since = (user_today - last_workout_date).days

        # Get previous streak length from most recent streak history
        history_response = db.client.table("streak_history").select(
            "streak_length"
        ).eq("user_id", user_id).order("ended_at", desc=True).limit(1).execute()

        if history_response.data:
            previous_streak = history_response.data[0]["streak_length"]

        # Generate motivation message
        motivation_message = get_recovery_message(days_since, previous_streak)
        motivation_quote = get_motivation_quote()

        # Determine suggested workout
        suggested_type = "quick_recovery" if recovery_type == RecoveryType.QUICK_RECOVERY.value else "strength"
        suggested_duration = 20 if recovery_type == RecoveryType.QUICK_RECOVERY.value else 30

        # Create recovery attempt record
        attempt_data = {
            "user_id": user_id,
            "previous_streak_length": previous_streak,
            "days_since_last_workout": days_since,
            "recovery_type": recovery_type,
            "motivation_message": motivation_message,
            "created_at": datetime.now().isoformat(),
        }

        attempt_response = db.client.table("streak_recovery_attempts").insert(
            attempt_data
        ).execute()

        if not attempt_response.data:
            raise HTTPException(status_code=500, detail="Failed to create recovery attempt")

        attempt_id = attempt_response.data[0]["id"]

        # Log the recovery attempt
        background_tasks.add_task(
            log_recovery_attempt,
            user_id=user_id,
            attempt_id=attempt_id,
            days_since=days_since,
        )

        return StreakRecoveryResponse(
            success=True,
            attempt_id=attempt_id,
            message=motivation_message,
            motivation_quote=motivation_quote,
            suggested_workout_type=suggested_type,
            suggested_duration_minutes=suggested_duration,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error initiating streak recovery: {e}")
        raise safe_internal_error(e, "initiate_streak_recovery")


@router.post("/streak-recovery/{attempt_id}/complete", tags=["Consistency"])
async def complete_streak_recovery(
    attempt_id: str,
    user_id: str = Query(...),
    workout_id: Optional[str] = Query(None),
    was_successful: bool = Query(True),
    current_user: dict = Depends(get_current_user),
):
    """
    Mark a streak recovery attempt as completed.

    Called after the user completes (or abandons) their recovery workout.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Update the recovery attempt
        update_data = {
            "was_successful": was_successful,
            "completed_at": datetime.now().isoformat(),
        }
        if workout_id:
            update_data["recovery_workout_id"] = workout_id

        response = db.client.table("streak_recovery_attempts").update(
            update_data
        ).eq("id", attempt_id).eq("user_id", user_id).execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="Recovery attempt not found")

        return {
            "success": True,
            "message": "Great job getting back on track!" if was_successful else "No worries, try again tomorrow!",
            "completed_at": update_data["completed_at"],
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error completing streak recovery: {e}")
        raise safe_internal_error(e, "complete_streak_recovery")


# ============================================================================
# Background Tasks
# ============================================================================

async def log_insights_view(user_id: str, current_streak: int):
    """Log when user views consistency insights."""
    try:
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.SCREEN_VIEW,
            event_data={
                "screen": "consistency_insights",
                "current_streak": current_streak,
            },
            context={"feature": "consistency_dashboard"},
        )
    except Exception as e:
        logger.error(f"Failed to log insights view: {e}")


async def log_recovery_attempt(user_id: str, attempt_id: str, days_since: int):
    """Log streak recovery attempt."""
    try:
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.WORKOUT_STARTED,  # Using closest existing type
            event_data={
                "action": "streak_recovery_initiated",
                "attempt_id": attempt_id,
                "days_since_last_workout": days_since,
            },
            context={"feature": "streak_recovery"},
        )
    except Exception as e:
        logger.error(f"Failed to log recovery attempt: {e}")
