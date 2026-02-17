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
            "is_completed", True
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
                "is_completed", True
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
    weeks: int = Query(None, ge=1, le=52, description="Number of weeks to include (legacy, use start_date/end_date instead)"),
    start_date_param: Optional[str] = Query(None, alias="start_date", description="Start date in YYYY-MM-DD format"),
    end_date_param: Optional[str] = Query(None, alias="end_date", description="End date in YYYY-MM-DD format"),
):
    """
    Get calendar heatmap data for visualizing workout consistency.

    Supports two modes:
    1. Date range: Provide start_date and end_date for custom range
    2. Weeks (legacy): Provide weeks parameter to get data from today - (weeks * 7) to today

    Returns workout status for each day:
    - completed: Workout was done
    - missed: Scheduled workout was missed
    - rest: No workout scheduled (rest day)
    - future: Future date
    """
    db = get_supabase_db()

    try:
        # Calculate date range based on parameters
        today = date.today()

        if start_date_param and end_date_param:
            # Use custom date range
            try:
                start_date = date.fromisoformat(start_date_param)
                end_date = date.fromisoformat(end_date_param)

                # Validate date range
                if end_date < start_date:
                    raise HTTPException(
                        status_code=400,
                        detail="end_date must be greater than or equal to start_date"
                    )

                # Cap end_date to today if it's in the future
                if end_date > today:
                    end_date = today

            except ValueError as e:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid date format. Use YYYY-MM-DD. Error: {str(e)}"
                )
        else:
            # Use weeks parameter (default to 4 weeks for backward compatibility)
            weeks_value = weeks if weeks is not None else 4
            start_date = today - timedelta(days=weeks_value * 7)
            end_date = today

        # Log the filter usage for user context
        try:
            await user_context_service.log_event(
                user_id=user_id,
                event_type=EventType.FEATURE_USAGE,
                event_data={
                    "endpoint": "/api/v1/consistency/calendar",
                    "message": f"Fetched calendar heatmap from {start_date} to {end_date}",
                    "start_date": start_date.isoformat(),
                    "end_date": end_date.isoformat(),
                    "days": (end_date - start_date).days + 1,
                    "used_custom_range": bool(start_date_param and end_date_param),
                }
            )
        except Exception as log_error:
            logger.warning(f"Failed to log calendar access: {log_error}")

        # Get all scheduled workouts in range
        workouts_response = db.client.table("workouts").select(
            "id, name, scheduled_date, is_completed"
        ).eq("user_id", user_id).gte(
            "scheduled_date", start_date.isoformat()
        ).lte(
            "scheduled_date", end_date.isoformat()
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
                "completed": workout["is_completed"],
            }

        # Build calendar data
        calendar_data = []
        total_completed = 0
        total_missed = 0
        total_rest = 0

        current_date = start_date
        while current_date <= end_date:
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
            end_date=end_date,
            data=calendar_data,
            total_completed=total_completed,
            total_missed=total_missed,
            total_rest_days=total_rest,
        )

    except HTTPException:
        # Re-raise HTTPExceptions (validation errors, etc.)
        raise
    except Exception as e:
        logger.error(f"Error fetching calendar heatmap: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch calendar data: {str(e)}")


@router.get("/day-detail", tags=["Consistency"])
async def get_day_detail(
    user_id: str = Query(..., description="User ID"),
    date_str: str = Query(..., alias="date", description="Date in YYYY-MM-DD format"),
):
    """
    Get detailed workout information for a specific day.

    Returns comprehensive workout data including:
    - Workout metadata (name, type, duration)
    - All exercises with set-by-set data (weight, reps, RPE, RIR)
    - Personal records achieved
    - Total volume and stats
    - Muscles worked
    """
    db = get_supabase_db()

    try:
        target_date = date.fromisoformat(date_str)
        today = date.today()

        # Determine base status
        if target_date > today:
            return {
                "date": date_str,
                "status": "future",
                "workout_id": None,
                "workout_name": None,
                "exercises": [],
                "muscles_worked": [],
            }

        # Get scheduled workout for this date
        # Use date range to properly match timestamp column
        # Prioritize completed workouts, then most recent
        workout_response = db.client.table("workouts").select(
            "id, name, type, difficulty, duration_minutes, exercises_json, is_completed"
        ).eq("user_id", user_id).gte(
            "scheduled_date", f"{date_str}T00:00:00"
        ).lt(
            "scheduled_date", f"{date_str}T23:59:59"
        ).order("is_completed", desc=True).order("created_at", desc=True).limit(1).execute()

        if not workout_response.data or len(workout_response.data) == 0:
            return {
                "date": date_str,
                "status": "rest",
                "workout_id": None,
                "workout_name": None,
                "exercises": [],
                "muscles_worked": [],
            }

        workout = workout_response.data[0]
        workout_id = workout["id"]
        is_completed = workout.get("is_completed", False)

        if not is_completed:
            # Workout was scheduled but not completed
            return {
                "date": date_str,
                "status": "missed",
                "workout_id": workout_id,
                "workout_name": workout.get("name"),
                "workout_type": workout.get("type"),
                "difficulty": workout.get("difficulty"),
                "duration_minutes": workout.get("duration_minutes"),
                "exercises": [],
                "muscles_worked": [ex.get("muscle_group") or ex.get("target_muscles", "") for ex in (workout.get("exercises_json") or []) if ex.get("muscle_group") or ex.get("target_muscles")],
            }

        # Get workout log for completed workout
        log_response = db.client.table("workout_logs").select(
            "id, completed_at, total_time_seconds, sets_json, calories_burned"
        ).eq("workout_id", workout_id).maybe_single().execute()
        log_data = log_response.data or {}

        workout_log_id = log_data.get("id")

        # Get performance logs for detailed set data
        exercises_data = []
        total_volume = 0.0
        all_rpes = []
        muscles_set = set()

        if workout_log_id:
            perf_response = db.client.table("performance_logs").select(
                "exercise_name, exercise_id, set_number, reps_completed, weight_kg, rpe, rir, set_type, is_pr"
            ).eq("workout_log_id", workout_log_id).order("exercise_name").order("set_number").execute()

            # Group by exercise
            exercise_sets = defaultdict(list)
            for row in (perf_response.data or []):
                exercise_sets[row["exercise_name"]].append(row)

            # Get exercise details for muscle groups
            exercise_names = list(exercise_sets.keys())
            if exercise_names:
                ex_details_response = db.client.table("exercises").select(
                    "name, primary_muscles, secondary_muscles"
                ).in_("name", exercise_names).execute()

                exercise_muscles = {}
                for ex in (ex_details_response.data or []):
                    primary = ex.get("primary_muscles", []) or []
                    exercise_muscles[ex["name"]] = primary[0] if primary else "Other"
                    muscles_set.update(primary)

            # Get PRs for this workout
            pr_response = db.client.table("strength_records").select(
                "exercise_name, is_pr, pr_type"
            ).eq("workout_log_id", workout_log_id).eq("is_pr", True).execute()

            exercise_prs = {}
            for pr in (pr_response.data or []):
                exercise_prs[pr["exercise_name"]] = pr.get("pr_type", "weight")

            # Build exercise data
            for ex_name, sets in exercise_sets.items():
                muscle_group = exercise_muscles.get(ex_name, "Other")
                has_pr = ex_name in exercise_prs
                pr_type = exercise_prs.get(ex_name)

                set_data = []
                ex_volume = 0.0
                best_weight = 0.0
                best_reps = 0

                for s in sets:
                    weight = s.get("weight_kg") or 0
                    reps = s.get("reps_completed") or 0
                    rpe = s.get("rpe")
                    rir = s.get("rir")

                    set_data.append({
                        "set_number": s.get("set_number", 1),
                        "reps": reps,
                        "weight_kg": weight,
                        "rpe": rpe,
                        "rir": rir,
                        "is_pr": s.get("is_pr", False),
                        "set_type": s.get("set_type", "working"),
                    })

                    set_volume = weight * reps
                    ex_volume += set_volume
                    total_volume += set_volume

                    if weight > best_weight:
                        best_weight = weight
                        best_reps = reps

                    if rpe:
                        all_rpes.append(rpe)

                exercises_data.append({
                    "exercise_name": ex_name,
                    "exercise_id": sets[0].get("exercise_id") if sets else None,
                    "muscle_group": muscle_group,
                    "sets": set_data,
                    "has_pr": has_pr,
                    "pr_type": pr_type,
                    "total_volume": round(ex_volume, 1),
                    "best_set_weight": best_weight,
                    "best_set_reps": best_reps,
                })

        # Calculate duration in minutes
        duration_mins = None
        if log_data.get("total_time_seconds"):
            duration_mins = log_data["total_time_seconds"] // 60
        elif workout.get("duration_minutes"):
            duration_mins = workout["duration_minutes"]

        # Average RPE
        avg_rpe = round(sum(all_rpes) / len(all_rpes), 1) if all_rpes else None

        # Get shared images if any
        shared_images = []
        if workout_log_id:
            share_response = db.client.table("workout_shares").select(
                "image_url"
            ).eq("workout_log_id", workout_log_id).execute()
            shared_images = [s["image_url"] for s in (share_response.data or []) if s.get("image_url")]

        return {
            "date": date_str,
            "status": "completed",
            "workout_id": workout_id,
            "workout_name": workout.get("name"),
            "workout_type": workout.get("type"),
            "difficulty": workout.get("difficulty"),
            "duration_minutes": duration_mins,
            "total_volume": round(total_volume, 1),
            "calories_burned": log_data.get("calories_burned"),
            "muscles_worked": list(muscles_set),
            "exercises": exercises_data,
            "shared_images": shared_images if shared_images else None,
            "coach_feedback": None,  # TODO: Add coach feedback lookup
            "completed_at": log_data.get("completed_at"),
            "average_rpe": avg_rpe,
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid date format: {str(e)}")
    except Exception as e:
        logger.error(f"Error fetching day detail: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch day detail: {str(e)}")


@router.get("/search-exercise", tags=["Consistency"])
async def search_exercise_history(
    user_id: str = Query(..., description="User ID"),
    exercise_name: str = Query(..., description="Exercise name to search for"),
    weeks: int = Query(52, ge=1, le=104, description="Number of weeks to search back"),
):
    """
    Search for all occurrences of an exercise in workout history.

    Returns:
    - List of dates where this exercise was performed
    - Summary for each occurrence (sets, best weight × reps, PR status)
    - Matching dates for heatmap highlighting
    """
    db = get_supabase_db()

    try:
        today = date.today()
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
        raise HTTPException(status_code=500, detail=f"Failed to search exercise history: {str(e)}")


@router.get("/exercise-suggestions", tags=["Consistency"])
async def get_exercise_suggestions(
    user_id: str = Query(..., description="User ID"),
    query: str = Query("", description="Search query for autocomplete"),
    limit: int = Query(10, ge=1, le=50, description="Max suggestions to return"),
):
    """
    Get exercise name suggestions for autocomplete.

    Returns exercises the user has performed, filtered by query,
    sorted by frequency of use.
    """
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
        raise HTTPException(status_code=500, detail=f"Failed to fetch suggestions: {str(e)}")


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
