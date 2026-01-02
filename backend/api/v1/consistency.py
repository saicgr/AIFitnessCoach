"""
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

from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Query, BackgroundTasks
from collections import defaultdict
import logging

from core.db import get_supabase_db
from models.consistency import (
    ConsistencyInsights,
    ConsistencyPatterns,
    DayPattern,
    TimeOfDayPattern,
    WeeklyConsistencyMetric,
    StreakHistoryRecord,
    StreakRecoveryRequest,
    StreakRecoveryResponse,
    CalendarHeatmapData,
    CalendarHeatmapResponse,
    DayOfWeek,
    TimeOfDay,
    RecoveryType,
)
from services.user_context_service import user_context_service, EventType

logger = logging.getLogger(__name__)

router = APIRouter()


# ============================================================================
# Helper Functions
# ============================================================================

def get_day_name(day_of_week: int) -> str:
    """Get day name from day of week number (0=Sunday)."""
    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    return days[day_of_week] if 0 <= day_of_week <= 6 else "Unknown"


def get_time_of_day_name(hour: int) -> str:
    """Get time of day category from hour."""
    if 5 <= hour < 8:
        return "early_morning"
    elif 8 <= hour < 11:
        return "morning"
    elif 11 <= hour < 14:
        return "midday"
    elif 14 <= hour < 17:
        return "afternoon"
    elif 17 <= hour < 20:
        return "evening"
    else:
        return "night"


def get_time_of_day_display(time_key: str) -> str:
    """Get display name for time of day."""
    displays = {
        "early_morning": "Early Morning (5-8 AM)",
        "morning": "Morning (8-11 AM)",
        "midday": "Midday (11 AM - 2 PM)",
        "afternoon": "Afternoon (2-5 PM)",
        "evening": "Evening (5-8 PM)",
        "night": "Night (8-11 PM)",
    }
    return displays.get(time_key, time_key)


def calculate_weekly_trend(rates: List[float]) -> str:
    """Calculate trend from weekly completion rates."""
    if len(rates) < 2:
        return "stable"

    # Compare last 2 weeks
    if rates[-1] > rates[-2] + 10:
        return "improving"
    elif rates[-1] < rates[-2] - 10:
        return "declining"
    return "stable"


def get_recovery_message(days_since: int, previous_streak: int) -> str:
    """Generate an encouraging recovery message."""
    if days_since == 1:
        if previous_streak >= 7:
            return "Don't worry about missing one day! Your {}-day streak shows real dedication. Let's get back on track today.".format(previous_streak)
        return "Everyone takes breaks. Today is a fresh start!"
    elif days_since <= 3:
        return "A few days off can actually help recovery. Ready to jump back in?"
    elif days_since <= 7:
        return "Life happens! What matters is that you're here now. Let's start fresh."
    else:
        return "Welcome back! Every fitness journey has ups and downs. Today you choose to continue."


def get_motivation_quote() -> str:
    """Get a random motivation quote for recovery."""
    quotes = [
        "The best time to start was yesterday. The next best time is now.",
        "Progress, not perfection.",
        "You don't have to be great to start, but you have to start to be great.",
        "The only bad workout is the one that didn't happen.",
        "Consistency is more important than intensity.",
        "Small steps every day lead to big results.",
        "Your future self will thank you.",
        "Fall seven times, stand up eight.",
    ]
    import random
    return random.choice(quotes)


# ============================================================================
# Main Endpoints
# ============================================================================

@router.get("/insights", response_model=ConsistencyInsights, tags=["Consistency"])
async def get_consistency_insights(
    user_id: str = Query(..., description="User ID"),
    days_back: int = Query(90, ge=7, le=365, description="Days of history to analyze"),
    background_tasks: BackgroundTasks = None,
):
    """
    Get comprehensive consistency insights for a user.

    Returns:
    - Current and longest streak
    - Best/worst day of week for consistency
    - Monthly completion rate
    - Weekly completion rates (last 4 weeks)
    - Recovery suggestion if streak is broken
    """
    db = get_supabase_db()

    try:
        logger.info(f"Fetching consistency insights for user {user_id}")

        # Get user's current streak from users table
        user_response = db.client.table("users").select(
            "current_streak, last_workout_date"
        ).eq("id", user_id).maybe_single().execute()

        current_streak = 0
        last_workout_date = None
        if user_response.data:
            current_streak = user_response.data.get("current_streak", 0) or 0
            last_workout_str = user_response.data.get("last_workout_date")
            if last_workout_str:
                last_workout_date = date.fromisoformat(last_workout_str) if isinstance(last_workout_str, str) else last_workout_str

        # Get longest streak from history
        try:
            longest_response = db.client.rpc(
                "get_longest_streak",
                {"p_user_id": user_id}
            ).execute()
            longest_streak = longest_response.data or current_streak
        except Exception:
            # Function might not exist yet, fall back to query
            history_response = db.client.table("streak_history").select(
                "streak_length"
            ).eq("user_id", user_id).order("streak_length", desc=True).limit(1).execute()
            historical_max = history_response.data[0]["streak_length"] if history_response.data else 0
            longest_streak = max(historical_max, current_streak)

        # Calculate days since last workout
        days_since_last = 0
        if last_workout_date:
            days_since_last = (date.today() - last_workout_date).days

        # Get workout time patterns
        patterns_response = db.client.table("workout_time_patterns").select(
            "day_of_week, hour_of_day, completion_count, skip_count"
        ).eq("user_id", user_id).execute()

        # Aggregate by day of week
        day_totals = defaultdict(lambda: {"completions": 0, "skips": 0})
        time_totals = defaultdict(lambda: {"completions": 0, "skips": 0})

        for pattern in (patterns_response.data or []):
            dow = pattern["day_of_week"]
            hour = pattern["hour_of_day"]
            completions = pattern["completion_count"] or 0
            skips = pattern["skip_count"] or 0

            day_totals[dow]["completions"] += completions
            day_totals[dow]["skips"] += skips

            time_key = get_time_of_day_name(hour)
            time_totals[time_key]["completions"] += completions
            time_totals[time_key]["skips"] += skips

        # Build day patterns
        day_patterns = []
        best_day = None
        worst_day = None
        best_rate = -1
        worst_rate = 101

        for dow in range(7):
            totals = day_totals[dow]
            total_attempts = totals["completions"] + totals["skips"]
            rate = (totals["completions"] / total_attempts * 100) if total_attempts > 0 else 0

            pattern = DayPattern(
                day_of_week=dow,
                day_name=get_day_name(dow),
                total_completions=totals["completions"],
                total_skips=totals["skips"],
                completion_rate=round(rate, 1),
            )
            day_patterns.append(pattern)

            if total_attempts > 0:
                if rate > best_rate:
                    best_rate = rate
                    best_day = pattern
                if rate < worst_rate:
                    worst_rate = rate
                    worst_day = pattern

        # Mark best/worst
        if best_day:
            for p in day_patterns:
                if p.day_of_week == best_day.day_of_week:
                    p.is_best_day = True
                    break
        if worst_day:
            for p in day_patterns:
                if p.day_of_week == worst_day.day_of_week:
                    p.is_worst_day = True
                    break

        # Build time patterns
        time_patterns = []
        preferred_time = None
        max_completions = 0

        for time_key in ["early_morning", "morning", "midday", "afternoon", "evening", "night"]:
            totals = time_totals.get(time_key, {"completions": 0, "skips": 0})
            total_attempts = totals["completions"] + totals["skips"]
            rate = (totals["completions"] / total_attempts * 100) if total_attempts > 0 else 0

            pattern = TimeOfDayPattern(
                time_of_day=time_key,
                display_name=get_time_of_day_display(time_key),
                total_completions=totals["completions"],
                total_skips=totals["skips"],
                completion_rate=round(rate, 1),
            )
            time_patterns.append(pattern)

            if totals["completions"] > max_completions:
                max_completions = totals["completions"]
                preferred_time = time_key

        # Mark preferred time
        if preferred_time:
            for p in time_patterns:
                if p.time_of_day == preferred_time:
                    p.is_preferred = True
                    break

        # Get monthly stats (current month)
        month_start = date.today().replace(day=1)
        month_end = date.today()

        # Count scheduled workouts this month
        scheduled_response = db.client.table("workouts").select(
            "id", count="exact"
        ).eq("user_id", user_id).gte(
            "scheduled_date", month_start.isoformat()
        ).lte(
            "scheduled_date", month_end.isoformat()
        ).execute()
        month_scheduled = scheduled_response.count or 0

        # Count completed workouts this month
        completed_response = db.client.table("workouts").select(
            "id", count="exact"
        ).eq("user_id", user_id).eq(
            "completed", True
        ).gte(
            "scheduled_date", month_start.isoformat()
        ).lte(
            "scheduled_date", month_end.isoformat()
        ).execute()
        month_completed = completed_response.count or 0

        month_rate = (month_completed / month_scheduled * 100) if month_scheduled > 0 else 0
        month_display = f"{month_completed} of {month_scheduled} workouts"

        # Get weekly completion rates (last 4 weeks)
        weekly_rates = []
        rates_for_trend = []
        today = date.today()

        for week_offset in range(4):
            week_end = today - timedelta(days=week_offset * 7)
            week_start = week_end - timedelta(days=6)

            # Count for this week
            week_scheduled_resp = db.client.table("workouts").select(
                "id", count="exact"
            ).eq("user_id", user_id).gte(
                "scheduled_date", week_start.isoformat()
            ).lte(
                "scheduled_date", week_end.isoformat()
            ).execute()
            week_scheduled = week_scheduled_resp.count or 0

            week_completed_resp = db.client.table("workouts").select(
                "id", count="exact"
            ).eq("user_id", user_id).eq(
                "completed", True
            ).gte(
                "scheduled_date", week_start.isoformat()
            ).lte(
                "scheduled_date", week_end.isoformat()
            ).execute()
            week_completed = week_completed_resp.count or 0

            week_rate = (week_completed / week_scheduled * 100) if week_scheduled > 0 else 0

            weekly_rates.append(WeeklyConsistencyMetric(
                week_start=week_start,
                week_end=week_end,
                workouts_scheduled=week_scheduled,
                workouts_completed=week_completed,
                completion_rate=round(week_rate, 1),
            ))
            rates_for_trend.append(week_rate)

        # Reverse to have oldest first for trend calculation
        rates_for_trend.reverse()
        weekly_trend = calculate_weekly_trend(rates_for_trend)
        avg_weekly = sum(rates_for_trend) / len(rates_for_trend) if rates_for_trend else 0

        # Determine if recovery is needed
        needs_recovery = current_streak == 0 and days_since_last > 0 and last_workout_date is not None
        recovery_suggestion = None
        if needs_recovery:
            recovery_suggestion = get_recovery_message(days_since_last, 0)

        # Log the insights view
        if background_tasks:
            background_tasks.add_task(
                log_insights_view,
                user_id=user_id,
                current_streak=current_streak,
            )

        return ConsistencyInsights(
            user_id=user_id,
            current_streak=current_streak,
            longest_streak=longest_streak,
            is_streak_active=current_streak > 0,
            best_day=best_day,
            worst_day=worst_day,
            day_patterns=day_patterns,
            preferred_time=preferred_time,
            time_patterns=time_patterns,
            month_workouts_completed=month_completed,
            month_workouts_scheduled=month_scheduled,
            month_completion_rate=round(month_rate, 1),
            month_display=month_display,
            weekly_completion_rates=weekly_rates,
            average_weekly_rate=round(avg_weekly, 1),
            weekly_trend=weekly_trend,
            needs_recovery=needs_recovery,
            recovery_suggestion=recovery_suggestion,
            days_since_last_workout=days_since_last,
            last_workout_date=last_workout_date,
            calculated_at=datetime.now(),
        )

    except Exception as e:
        logger.error(f"Error fetching consistency insights: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch consistency insights: {str(e)}")


@router.get("/patterns", response_model=ConsistencyPatterns, tags=["Consistency"])
async def get_consistency_patterns(
    user_id: str = Query(..., description="User ID"),
    days_back: int = Query(180, ge=30, le=365, description="Days of history to analyze"),
):
    """
    Get detailed consistency patterns including time of day preferences,
    day of week patterns, and historical streak analysis.
    """
    db = get_supabase_db()

    try:
        logger.info(f"Fetching consistency patterns for user {user_id}")

        # Get workout time patterns
        patterns_response = db.client.table("workout_time_patterns").select(
            "day_of_week, hour_of_day, completion_count, skip_count, updated_at"
        ).eq("user_id", user_id).execute()

        # Aggregate patterns
        day_totals = defaultdict(lambda: {"completions": 0, "skips": 0})
        time_totals = defaultdict(lambda: {"completions": 0, "skips": 0})

        for pattern in (patterns_response.data or []):
            dow = pattern["day_of_week"]
            hour = pattern["hour_of_day"]
            completions = pattern["completion_count"] or 0
            skips = pattern["skip_count"] or 0

            day_totals[dow]["completions"] += completions
            day_totals[dow]["skips"] += skips

            time_key = get_time_of_day_name(hour)
            time_totals[time_key]["completions"] += completions
            time_totals[time_key]["skips"] += skips

        # Build day patterns
        day_patterns = []
        best_day_name = None
        worst_day_name = None
        best_rate = -1
        worst_rate = 101

        for dow in range(7):
            totals = day_totals[dow]
            total_attempts = totals["completions"] + totals["skips"]
            rate = (totals["completions"] / total_attempts * 100) if total_attempts > 0 else 0

            day_name = get_day_name(dow)
            pattern = DayPattern(
                day_of_week=dow,
                day_name=day_name,
                total_completions=totals["completions"],
                total_skips=totals["skips"],
                completion_rate=round(rate, 1),
            )
            day_patterns.append(pattern)

            if total_attempts > 0:
                if rate > best_rate:
                    best_rate = rate
                    best_day_name = day_name
                if rate < worst_rate:
                    worst_rate = rate
                    worst_day_name = day_name

        # Build time patterns
        time_patterns = []
        preferred_time = None
        max_completions = 0

        for time_key in ["early_morning", "morning", "midday", "afternoon", "evening", "night"]:
            totals = time_totals.get(time_key, {"completions": 0, "skips": 0})
            total_attempts = totals["completions"] + totals["skips"]
            rate = (totals["completions"] / total_attempts * 100) if total_attempts > 0 else 0

            pattern = TimeOfDayPattern(
                time_of_day=time_key,
                display_name=get_time_of_day_display(time_key),
                total_completions=totals["completions"],
                total_skips=totals["skips"],
                completion_rate=round(rate, 1),
                is_preferred=False,
            )
            time_patterns.append(pattern)

            if totals["completions"] > max_completions:
                max_completions = totals["completions"]
                preferred_time = time_key

        # Mark preferred time
        if preferred_time:
            for p in time_patterns:
                if p.time_of_day == preferred_time:
                    p.is_preferred = True
                    break

        # Get streak history
        history_response = db.client.table("streak_history").select("*").eq(
            "user_id", user_id
        ).order("ended_at", desc=True).limit(20).execute()

        streak_history = []
        total_streak_length = 0
        for record in (history_response.data or []):
            streak_history.append(StreakHistoryRecord(
                id=record["id"],
                user_id=record["user_id"],
                streak_length=record["streak_length"],
                started_at=datetime.fromisoformat(record["started_at"]) if record.get("started_at") else datetime.now(),
                ended_at=datetime.fromisoformat(record["ended_at"]) if record.get("ended_at") else datetime.now(),
                end_reason=record.get("end_reason", "missed_workout"),
                created_at=datetime.fromisoformat(record["created_at"]) if record.get("created_at") else datetime.now(),
            ))
            total_streak_length += record["streak_length"]

        avg_streak = total_streak_length / len(streak_history) if streak_history else 0

        return ConsistencyPatterns(
            user_id=user_id,
            time_patterns=time_patterns,
            preferred_time=preferred_time,
            day_patterns=day_patterns,
            most_consistent_day=best_day_name,
            least_consistent_day=worst_day_name,
            has_seasonal_data=False,  # TODO: Implement seasonal analysis
            seasonal_notes=None,
            skip_reasons={},  # TODO: Implement skip reason tracking
            most_common_skip_reason=None,
            streak_history=streak_history,
            average_streak_length=round(avg_streak, 1),
            streak_count=len(streak_history),
            calculated_at=datetime.now(),
        )

    except Exception as e:
        logger.error(f"Error fetching consistency patterns: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch consistency patterns: {str(e)}")


@router.get("/calendar", response_model=CalendarHeatmapResponse, tags=["Consistency"])
async def get_calendar_heatmap(
    user_id: str = Query(..., description="User ID"),
    weeks: int = Query(4, ge=1, le=12, description="Number of weeks to include"),
):
    """
    Get calendar heatmap data for visualizing workout consistency.

    Returns workout status for each day:
    - completed: Workout was done
    - missed: Scheduled workout was missed
    - rest: No workout scheduled (rest day)
    - future: Future date
    """
    db = get_supabase_db()

    try:
        # Calculate date range
        today = date.today()
        start_date = today - timedelta(days=weeks * 7)

        # Get all scheduled workouts in range
        workouts_response = db.client.table("workouts").select(
            "id, name, scheduled_date, completed"
        ).eq("user_id", user_id).gte(
            "scheduled_date", start_date.isoformat()
        ).lte(
            "scheduled_date", today.isoformat()
        ).execute()

        # Build a map of date -> workout info
        workout_map = {}
        for workout in (workouts_response.data or []):
            scheduled_str = workout["scheduled_date"]
            if "T" in scheduled_str:
                scheduled_str = scheduled_str.split("T")[0]
            workout_date = date.fromisoformat(scheduled_str)
            workout_map[workout_date] = {
                "name": workout["name"],
                "completed": workout["completed"],
            }

        # Build calendar data
        calendar_data = []
        total_completed = 0
        total_missed = 0
        total_rest = 0

        current_date = start_date
        while current_date <= today:
            dow = current_date.weekday()  # 0=Monday in Python
            # Convert to SQL format (0=Sunday)
            sql_dow = (dow + 1) % 7

            if current_date in workout_map:
                workout_info = workout_map[current_date]
                if workout_info["completed"]:
                    status = "completed"
                    total_completed += 1
                else:
                    status = "missed"
                    total_missed += 1
                workout_name = workout_info["name"]
            else:
                status = "rest"
                total_rest += 1
                workout_name = None

            calendar_data.append(CalendarHeatmapData(
                date=current_date,
                day_of_week=sql_dow,
                status=status,
                workout_name=workout_name,
            ))

            current_date += timedelta(days=1)

        return CalendarHeatmapResponse(
            user_id=user_id,
            start_date=start_date,
            end_date=today,
            data=calendar_data,
            total_completed=total_completed,
            total_missed=total_missed,
            total_rest_days=total_rest,
        )

    except Exception as e:
        logger.error(f"Error fetching calendar heatmap: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch calendar data: {str(e)}")


@router.post("/streak-recovery", response_model=StreakRecoveryResponse, tags=["Consistency"])
async def initiate_streak_recovery(
    request: StreakRecoveryRequest,
    background_tasks: BackgroundTasks,
):
    """
    Initiate a streak recovery attempt.

    Called when a user returns after breaking their streak.
    Records the attempt and provides encouraging guidance.
    """
    db = get_supabase_db()

    try:
        user_id = request.user_id
        recovery_type = request.recovery_type

        logger.info(f"Initiating streak recovery for user {user_id}")

        # Get user's last workout info
        user_response = db.client.table("users").select(
            "current_streak, last_workout_date"
        ).eq("id", user_id).maybe_single().execute()

        last_workout_date = None
        previous_streak = 0

        if user_response.data:
            last_workout_str = user_response.data.get("last_workout_date")
            if last_workout_str:
                last_workout_date = date.fromisoformat(last_workout_str) if isinstance(last_workout_str, str) else last_workout_str

        # Calculate days since last workout
        days_since = 0
        if last_workout_date:
            days_since = (date.today() - last_workout_date).days

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
        raise HTTPException(status_code=500, detail=f"Failed to initiate recovery: {str(e)}")


@router.post("/streak-recovery/{attempt_id}/complete", tags=["Consistency"])
async def complete_streak_recovery(
    attempt_id: str,
    user_id: str = Query(...),
    workout_id: Optional[str] = Query(None),
    was_successful: bool = Query(True),
):
    """
    Mark a streak recovery attempt as completed.

    Called after the user completes (or abandons) their recovery workout.
    """
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
        raise HTTPException(status_code=500, detail=f"Failed to complete recovery: {str(e)}")


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
