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
from .consistency_endpoints import router as _endpoints_router


from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks, Request
from collections import defaultdict
import logging

from core.db import get_supabase_db
from core.timezone_utils import resolve_timezone, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.db_utils import safe_maybe_single
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
    request: Request,
    user_id: str = Query(..., description="User ID"),
    days_back: int = Query(90, ge=7, le=365, description="Days of history to analyze"),
    background_tasks: BackgroundTasks = None,
    current_user: dict = Depends(get_current_user),
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
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()
    user_tz = resolve_timezone(request, db, user_id)
    today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()

    try:
        logger.info(f"Fetching consistency insights for user {user_id}")

        # Get user's current streak from users table
        user_response = safe_maybe_single(
            db.client.table("users").select(
                "current_streak, last_workout_date"
            ).eq("id", user_id).maybe_single()
        )

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
            days_since_last = (today - last_workout_date).days

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

        # Get monthly + weekly stats in ONE query instead of 10 separate ones
        month_start = today.replace(day=1)
        oldest_week_start = today - timedelta(days=3 * 7 + 6)  # 4 weeks back
        range_start = min(month_start, oldest_week_start)

        all_workouts_resp = db.client.table("workouts").select(
            "scheduled_date, is_completed"
        ).eq("user_id", user_id).gte(
            "scheduled_date", range_start.isoformat()
        ).lte(
            "scheduled_date", today.isoformat()
        ).execute()

        all_workouts = all_workouts_resp.data or []

        # Parse dates once
        parsed_workouts = []
        for w in all_workouts:
            sd = w["scheduled_date"]
            if "T" in sd:
                sd = sd.split("T")[0]
            parsed_workouts.append((date.fromisoformat(sd), w["is_completed"]))

        # Monthly stats
        month_scheduled = sum(1 for d, _ in parsed_workouts if d >= month_start)
        month_completed = sum(1 for d, c in parsed_workouts if d >= month_start and c)
        month_rate = (month_completed / month_scheduled * 100) if month_scheduled > 0 else 0
        month_display = f"{month_completed} of {month_scheduled} workouts"

        # Weekly completion rates (last 4 weeks) - computed from same data
        weekly_rates = []
        rates_for_trend = []

        for week_offset in range(4):
            week_end = today - timedelta(days=week_offset * 7)
            week_start = week_end - timedelta(days=6)

            week_scheduled = sum(1 for d, _ in parsed_workouts if week_start <= d <= week_end)
            week_completed = sum(1 for d, c in parsed_workouts if week_start <= d <= week_end and c)
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
        logger.error(f"Error fetching consistency insights: {e}", exc_info=True)
        raise safe_internal_error(e, "get_consistency_insights")


@router.get("/patterns", response_model=ConsistencyPatterns, tags=["Consistency"])
async def get_consistency_patterns(
    user_id: str = Query(..., description="User ID"),
    days_back: int = Query(180, ge=30, le=365, description="Days of history to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get detailed consistency patterns including time of day preferences,
    day of week patterns, and historical streak analysis.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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

        logger.info("has_seasonal_data not yet implemented for user %s - returning False", user_id)
        logger.info("skip_reasons not yet implemented for user %s - returning empty dict", user_id)

        return ConsistencyPatterns(
            user_id=user_id,
            time_patterns=time_patterns,
            preferred_time=preferred_time,
            day_patterns=day_patterns,
            most_consistent_day=best_day_name,
            least_consistent_day=worst_day_name,
            has_seasonal_data=False,
            seasonal_notes=None,
            skip_reasons={},
            most_common_skip_reason=None,
            streak_history=streak_history,
            average_streak_length=round(avg_streak, 1),
            streak_count=len(streak_history),
            calculated_at=datetime.now(),
        )

    except Exception as e:
        logger.error(f"Error fetching consistency patterns: {e}", exc_info=True)
        raise safe_internal_error(e, "get_consistency_patterns")


@router.get("/calendar", response_model=CalendarHeatmapResponse, tags=["Consistency"])
async def get_calendar_heatmap(
    request: Request,
    user_id: str = Query(..., description="User ID"),
    weeks: int = Query(None, ge=1, le=52, description="Number of weeks to include (legacy, use start_date/end_date instead)"),
    start_date_param: Optional[str] = Query(None, alias="start_date", description="Start date in YYYY-MM-DD format"),
    end_date_param: Optional[str] = Query(None, alias="end_date", description="End date in YYYY-MM-DD format"),
    current_user: dict = Depends(get_current_user),
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
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        # Calculate date range based on parameters
        user_tz = resolve_timezone(request, db, user_id)
        today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()

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
                    detail="Invalid date format. Use YYYY-MM-DD."
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
                event_type=EventType.FEATURE_INTERACTION,
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
            logger.warning(f"Failed to log calendar access: {log_error}", exc_info=True)

        # Get all scheduled workouts in range (use end-of-day for inclusive upper bound)
        workouts_response = db.client.table("workouts").select(
            "id, name, scheduled_date, is_completed, generation_method"
        ).eq("user_id", user_id).gte(
            "scheduled_date", start_date.isoformat()
        ).lte(
            "scheduled_date", end_date.isoformat() + "T23:59:59+00:00"
        ).execute()

        # Build a map of date -> workout info
        workout_map = {}
        for workout in (workouts_response.data or []):
            scheduled_str = workout["scheduled_date"]
            if "T" in scheduled_str:
                scheduled_str = scheduled_str.split("T")[0]
            workout_date = date.fromisoformat(scheduled_str)
            # Imported workouts from Health are always considered completed
            # since they represent workouts already performed on the device
            is_completed = workout["is_completed"] or workout.get("generation_method") == "health_connect_import"
            workout_map[workout_date] = {
                "name": workout["name"],
                "completed": is_completed,
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
        logger.error(f"Error fetching calendar heatmap: {e}", exc_info=True)
        raise safe_internal_error(e, "get_calendar_heatmap")


@router.get("/day-detail", tags=["Consistency"])
async def get_day_detail(
    request: Request,
    user_id: str = Query(..., description="User ID"),
    date_str: str = Query(..., alias="date", description="Date in YYYY-MM-DD format"),
    current_user: dict = Depends(get_current_user),
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
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    try:
        target_date = date.fromisoformat(date_str)
        user_tz = resolve_timezone(request, db, user_id)
        today = datetime.strptime(get_user_today(user_tz), "%Y-%m-%d").date()

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
            "id, name, type, difficulty, duration_minutes, exercises_json, is_completed, generation_method"
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
        # Imported workouts from Health are always considered completed
        is_completed = workout.get("is_completed", False) or workout.get("generation_method") == "health_connect_import"

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

        # For health-imported workouts, include import metadata
        is_health_import = workout.get("generation_method") == "health_connect_import"
        import_metadata = None
        if is_health_import:
            # Fetch generation_metadata for import details (calories, source app, etc.)
            meta_response = safe_maybe_single(
                db.client.table("workouts").select(
                    "generation_metadata"
                ).eq("id", workout_id).maybe_single()
            )
            raw_meta = (meta_response.data or {}).get("generation_metadata")
            if raw_meta:
                import json as json_mod
                if isinstance(raw_meta, str):
                    try:
                        import_metadata = json_mod.loads(raw_meta)
                    except Exception:
                        import_metadata = None
                elif isinstance(raw_meta, dict):
                    import_metadata = raw_meta

        # Get workout log for completed workout
        log_response = safe_maybe_single(
            db.client.table("workout_logs").select(
                "id, completed_at, total_time_seconds, sets_json, calories_burned"
            ).eq("workout_id", workout_id).maybe_single()
        )
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

        logger.info("coach_feedback not yet implemented for day detail (user=%s, date=%s)", user_id, date_str)

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
            "coach_feedback": None,  # not yet implemented - coach feedback lookup pending
            "completed_at": log_data.get("completed_at"),
            "average_rpe": avg_rpe,
            "is_health_import": is_health_import,
            "import_metadata": import_metadata,
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")
    except Exception as e:
        logger.error(f"Error fetching day detail: {e}", exc_info=True)
        raise safe_internal_error(e, "get_day_detail")



# Include secondary endpoints
router.include_router(_endpoints_router)
