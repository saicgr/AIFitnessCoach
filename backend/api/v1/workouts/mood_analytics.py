"""
Mood history, analytics, and calendar endpoints.

Extracted from generation.py to keep files under 1000 lines.
Provides mood tracking and visualization data:
- GET /{user_id}/mood-history - Paginated mood check-in history
- GET /{user_id}/mood-analytics - Mood distribution, patterns, streaks
- PUT /{user_id}/mood-checkins/{checkin_id}/complete - Mark mood workout done
- GET /{user_id}/mood-today - Today's mood check-in
- GET /{user_id}/mood-weekly - Weekly mood data for chart
- GET /{user_id}/mood-calendar - Monthly mood data for calendar heatmap
"""
from core.db import get_supabase_db
import calendar
from datetime import datetime, date as date_type, timedelta
from typing import List, Dict, Any, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.mood_workout_service import mood_workout_service

router = APIRouter()
logger = get_logger(__name__)


# ============================================================================
# Response Models
# ============================================================================

class MoodHistoryResponse(BaseModel):
    """Response model for mood history."""
    checkins: List[Dict[str, Any]]
    total_count: int
    has_more: bool


class MoodAnalyticsResponse(BaseModel):
    """Response model for mood analytics."""
    summary: Dict[str, Any]
    patterns: List[Dict[str, Any]]
    streaks: Dict[str, Any]
    recommendations: List[str]


class MoodDayEntry(BaseModel):
    """Single mood entry within a day."""
    mood: str
    emoji: str
    color: str
    time: str


class MoodDayData(BaseModel):
    """Mood data for a single day."""
    date: str
    day_name: str
    moods: List[MoodDayEntry]
    primary_mood: Optional[str] = None
    checkin_count: int
    workout_completed: bool


class MoodWeeklySummary(BaseModel):
    """Summary stats for weekly mood data."""
    total_checkins: int
    avg_mood_score: float
    trend: str  # "improving", "declining", "stable"


class MoodWeeklyResponse(BaseModel):
    """Response model for weekly mood data."""
    days: List[MoodDayData]
    summary: MoodWeeklySummary


class MoodCalendarDay(BaseModel):
    """Mood data for a single calendar day."""
    moods: List[str]
    primary_mood: str
    color: str
    checkin_count: int


class MoodCalendarSummary(BaseModel):
    """Summary stats for calendar mood data."""
    days_with_checkins: int
    total_checkins: int
    most_common_mood: Optional[str] = None


class MoodCalendarResponse(BaseModel):
    """Response model for monthly mood calendar data."""
    month: int
    year: int
    days: Dict[str, Optional[MoodCalendarDay]]
    summary: MoodCalendarSummary


# ============================================================================
# Endpoints
# ============================================================================

@router.get("/{user_id}/mood-history", response_model=MoodHistoryResponse)
async def get_mood_history(
    user_id: str,
    limit: int = 30,
    offset: int = 0,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's mood check-in history.

    Returns a list of mood check-ins with workout information.
    Supports pagination and date filtering.
    """
    logger.info(f"Fetching mood history for user {user_id}")

    try:
        db = get_supabase_db()

        # Build query
        query = db.client.table("mood_checkins") \
            .select("*, workouts(id, name, type, difficulty, is_completed)") \
            .eq("user_id", user_id) \
            .order("check_in_time", desc=True)

        # Apply date filters if provided
        if start_date:
            query = query.gte("check_in_time", start_date)
        if end_date:
            query = query.lte("check_in_time", end_date)

        # Get total count first
        count_result = db.client.table("mood_checkins") \
            .select("*", count="exact") \
            .eq("user_id", user_id)

        if start_date:
            count_result = count_result.gte("check_in_time", start_date)
        if end_date:
            count_result = count_result.lte("check_in_time", end_date)

        count_response = count_result.execute()
        total_count = count_response.count if count_response.count else 0

        # Apply pagination
        query = query.range(offset, offset + limit - 1)

        result = query.execute()

        checkins = []
        for row in result.data or []:
            # Get mood config for display info
            mood_type = row.get("mood", "good")
            config = mood_workout_service.get_mood_config(
                mood_workout_service.validate_mood(mood_type)
            )

            workout_data = row.get("workouts")

            checkins.append({
                "id": row.get("id"),
                "mood": mood_type,
                "mood_emoji": config.emoji,
                "mood_color": config.color_hex,
                "check_in_time": row.get("check_in_time"),
                "workout_generated": row.get("workout_generated", False),
                "workout_completed": row.get("workout_completed", False),
                "workout": {
                    "id": workout_data.get("id"),
                    "name": workout_data.get("name"),
                    "type": workout_data.get("type"),
                    "difficulty": workout_data.get("difficulty"),
                    "completed": workout_data.get("is_completed"),
                } if workout_data else None,
                "context": row.get("context", {}),
            })

        return MoodHistoryResponse(
            checkins=checkins,
            total_count=total_count,
            has_more=(offset + limit) < total_count,
        )

    except Exception as e:
        logger.error(f"Failed to get mood history for user {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "generation")


@router.get("/{user_id}/mood-analytics", response_model=MoodAnalyticsResponse)
async def get_mood_analytics(
    user_id: str,
    days: int = 30,
    current_user: dict = Depends(get_current_user),
):
    """
    Get mood analytics and patterns for a user.

    Returns:
    - Summary: Total check-ins, most frequent mood, completion rate
    - Patterns: Mood distribution by time of day, day of week
    - Streaks: Current streak, longest streak
    - Recommendations: AI-generated suggestions based on patterns
    """
    logger.info(f"Fetching mood analytics for user {user_id}, last {days} days")

    try:
        db = get_supabase_db()

        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)

        # Fetch all check-ins in date range
        result = db.client.table("mood_checkins") \
            .select("*") \
            .eq("user_id", user_id) \
            .gte("check_in_time", start_date.isoformat()) \
            .lte("check_in_time", end_date.isoformat()) \
            .order("check_in_time", desc=True) \
            .execute()

        checkins = result.data or []
        total_count = len(checkins)

        if total_count == 0:
            return MoodAnalyticsResponse(
                summary={
                    "total_checkins": 0,
                    "workouts_generated": 0,
                    "workouts_completed": 0,
                    "completion_rate": 0,
                    "most_frequent_mood": None,
                    "days_tracked": days,
                },
                patterns=[],
                streaks={
                    "current_streak": 0,
                    "longest_streak": 0,
                    "last_checkin": None,
                },
                recommendations=[
                    "Start tracking your mood to get personalized insights!",
                    "Check in daily to see how your mood affects your workouts.",
                ],
            )

        # Calculate mood distribution
        mood_counts = {"great": 0, "good": 0, "tired": 0, "stressed": 0}
        workouts_generated = 0
        workouts_completed = 0
        time_of_day_moods = {"morning": {}, "afternoon": {}, "evening": {}, "night": {}}
        day_of_week_moods = {
            "monday": {}, "tuesday": {}, "wednesday": {},
            "thursday": {}, "friday": {}, "saturday": {}, "sunday": {}
        }

        for checkin in checkins:
            mood = checkin.get("mood", "good")
            mood_counts[mood] = mood_counts.get(mood, 0) + 1

            if checkin.get("workout_generated"):
                workouts_generated += 1
            if checkin.get("workout_completed"):
                workouts_completed += 1

            # Parse context for patterns
            context = checkin.get("context", {})
            time_of_day = context.get("time_of_day", "afternoon")
            day_of_week = context.get("day_of_week", "monday")

            if time_of_day in time_of_day_moods:
                time_of_day_moods[time_of_day][mood] = time_of_day_moods[time_of_day].get(mood, 0) + 1

            if day_of_week in day_of_week_moods:
                day_of_week_moods[day_of_week][mood] = day_of_week_moods[day_of_week].get(mood, 0) + 1

        # Find most frequent mood
        most_frequent_mood = max(mood_counts, key=mood_counts.get)
        most_frequent_config = mood_workout_service.get_mood_config(
            mood_workout_service.validate_mood(most_frequent_mood)
        )

        # Calculate streaks
        checkin_dates = set()
        for checkin in checkins:
            check_in_time = checkin.get("check_in_time", "")
            if check_in_time:
                try:
                    dt = datetime.fromisoformat(check_in_time.replace("Z", "+00:00"))
                    checkin_dates.add(dt.date())
                except (ValueError, AttributeError) as e:
                    logger.debug(f"Failed to parse check-in date: {e}")

        sorted_dates = sorted(checkin_dates, reverse=True)

        current_streak = 0
        longest_streak = 0
        temp_streak = 0
        today = date_type.today()

        if sorted_dates:
            # Calculate current streak
            expected_date = today
            for d in sorted_dates:
                if d == expected_date or d == expected_date - timedelta(days=1):
                    current_streak += 1
                    expected_date = d - timedelta(days=1)
                else:
                    break

            # Calculate longest streak
            prev_date = None
            for d in sorted(checkin_dates):
                if prev_date is None or (d - prev_date).days == 1:
                    temp_streak += 1
                else:
                    longest_streak = max(longest_streak, temp_streak)
                    temp_streak = 1
                prev_date = d
            longest_streak = max(longest_streak, temp_streak)

        # Build patterns list
        patterns = []

        # Mood distribution pattern
        patterns.append({
            "type": "mood_distribution",
            "title": "Your Mood Distribution",
            "data": [
                {
                    "mood": mood,
                    "count": count,
                    "percentage": round((count / total_count) * 100, 1) if total_count > 0 else 0,
                    "emoji": mood_workout_service.get_mood_config(
                        mood_workout_service.validate_mood(mood)
                    ).emoji,
                }
                for mood, count in mood_counts.items()
            ],
        })

        # Time of day pattern
        patterns.append({
            "type": "time_of_day",
            "title": "Mood by Time of Day",
            "data": [
                {
                    "time_of_day": tod,
                    "moods": moods,
                    "dominant_mood": max(moods, key=moods.get) if moods else None,
                }
                for tod, moods in time_of_day_moods.items()
            ],
        })

        # Day of week pattern
        patterns.append({
            "type": "day_of_week",
            "title": "Mood by Day of Week",
            "data": [
                {
                    "day": dow,
                    "moods": moods,
                    "dominant_mood": max(moods, key=moods.get) if moods else None,
                }
                for dow, moods in day_of_week_moods.items()
            ],
        })

        # Generate recommendations
        recommendations = []

        completion_rate = (workouts_completed / workouts_generated * 100) if workouts_generated > 0 else 0

        if completion_rate < 50 and workouts_generated > 3:
            recommendations.append(
                "Try shorter workouts when you're feeling tired or stressed - you're more likely to complete them!"
            )

        if mood_counts.get("tired", 0) > total_count * 0.4:
            recommendations.append(
                "You've been feeling tired frequently. Consider adjusting your sleep schedule or trying recovery workouts."
            )

        if mood_counts.get("stressed", 0) > total_count * 0.3:
            recommendations.append(
                "Stress has been high lately. Our stress-relief workouts include breathing exercises and flow movements."
            )

        if mood_counts.get("great", 0) > total_count * 0.5:
            recommendations.append(
                "You're often feeling great! Consider trying more challenging workouts to push your limits."
            )

        if current_streak >= 7:
            recommendations.append(
                f"Amazing! You're on a {current_streak}-day streak. Keep it up!"
            )
        elif current_streak == 0:
            recommendations.append(
                "Check in with your mood today and get a personalized workout suggestion!"
            )

        return MoodAnalyticsResponse(
            summary={
                "total_checkins": total_count,
                "workouts_generated": workouts_generated,
                "workouts_completed": workouts_completed,
                "completion_rate": round(completion_rate, 1),
                "most_frequent_mood": {
                    "mood": most_frequent_mood,
                    "emoji": most_frequent_config.emoji,
                    "color": most_frequent_config.color_hex,
                    "count": mood_counts[most_frequent_mood],
                },
                "days_tracked": days,
            },
            patterns=patterns,
            streaks={
                "current_streak": current_streak,
                "longest_streak": longest_streak,
                "last_checkin": checkins[0].get("check_in_time") if checkins else None,
            },
            recommendations=recommendations,
        )

    except Exception as e:
        logger.error(f"Failed to get mood analytics: {e}", exc_info=True)
        raise safe_internal_error(e, "generation")


@router.put("/{user_id}/mood-checkins/{checkin_id}/complete")
async def mark_mood_workout_completed(user_id: str, checkin_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Mark a mood check-in's workout as completed."""
    logger.info(f"Marking mood workout completed: user={user_id}, checkin={checkin_id}")

    try:
        db = get_supabase_db()

        # Verify check-in belongs to user
        result = db.client.table("mood_checkins") \
            .select("*") \
            .eq("id", checkin_id) \
            .eq("user_id", user_id) \
            .single() \
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Mood check-in not found")

        # Update completion status
        db.client.table("mood_checkins") \
            .update({"workout_completed": True}) \
            .eq("id", checkin_id) \
            .execute()

        return {"success": True, "message": "Workout marked as completed"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to mark mood workout completed: {e}", exc_info=True)
        raise safe_internal_error(e, "generation")


@router.get("/{user_id}/mood-today")
async def get_today_mood(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get user's mood check-in for today (if any)."""
    logger.info(f"Fetching today's mood for user {user_id}")

    try:
        db = get_supabase_db()

        # Query today's check-in using the view
        result = db.client.table("today_mood_checkin") \
            .select("*") \
            .eq("user_id", user_id) \
            .execute()

        if result.data and len(result.data) > 0:
            checkin = result.data[0]
            mood_type = checkin.get("mood", "good")
            config = mood_workout_service.get_mood_config(
                mood_workout_service.validate_mood(mood_type)
            )

            return {
                "has_checkin": True,
                "checkin": {
                    "id": checkin.get("id"),
                    "mood": mood_type,
                    "mood_emoji": config.emoji,
                    "mood_color": config.color_hex,
                    "check_in_time": checkin.get("check_in_time"),
                    "workout_generated": checkin.get("workout_generated", False),
                    "workout_completed": checkin.get("workout_completed", False),
                    "workout_id": checkin.get("workout_id"),
                },
            }

        return {
            "has_checkin": False,
            "checkin": None,
        }

    except Exception as e:
        logger.error(f"Failed to get today's mood: {e}", exc_info=True)
        raise safe_internal_error(e, "generation")


@router.get("/{user_id}/mood-weekly", response_model=MoodWeeklyResponse)
async def get_mood_weekly(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's mood data for the last 7 days.

    Returns daily mood check-ins with trend analysis for weekly chart visualization.
    """
    logger.info(f"Fetching weekly mood data for user {user_id}")

    try:
        db = get_supabase_db()

        # Calculate date range (last 7 days)
        today = datetime.now().date()
        week_ago = today - timedelta(days=6)  # Include today, so 7 days total

        # Fetch check-ins for the week
        result = db.client.table("mood_checkins") \
            .select("*") \
            .eq("user_id", user_id) \
            .gte("check_in_time", week_ago.isoformat()) \
            .lte("check_in_time", (today + timedelta(days=1)).isoformat()) \
            .order("check_in_time", desc=False) \
            .execute()

        checkins = result.data or []

        # Mood score mapping for trend calculation
        mood_scores = {"great": 4, "good": 3, "tired": 2, "stressed": 1}

        # Group check-ins by date
        days_data = {}
        for i in range(7):
            day = week_ago + timedelta(days=i)
            day_str = day.isoformat()
            days_data[day_str] = {
                "date": day_str,
                "day_name": day.strftime("%A"),
                "moods": [],
                "primary_mood": None,
                "checkin_count": 0,
                "workout_completed": False,
            }

        # Process check-ins
        total_score = 0
        total_checkins = 0
        first_half_scores = []
        second_half_scores = []

        for checkin in checkins:
            check_time = checkin.get("check_in_time", "")
            if not check_time:
                continue

            # Parse date
            if "T" in check_time:
                day_str = check_time.split("T")[0]
            else:
                day_str = check_time[:10]

            if day_str not in days_data:
                continue

            mood = checkin.get("mood", "good")
            config = mood_workout_service.get_mood_config(
                mood_workout_service.validate_mood(mood)
            )

            # Parse time for display
            try:
                time_part = check_time.split("T")[1][:5] if "T" in check_time else "00:00"
            except (IndexError, AttributeError):
                time_part = "00:00"

            days_data[day_str]["moods"].append({
                "mood": mood,
                "emoji": config.emoji,
                "color": config.color_hex,
                "time": time_part,
            })
            days_data[day_str]["checkin_count"] += 1

            if checkin.get("workout_completed"):
                days_data[day_str]["workout_completed"] = True

            # Track scores for trend
            score = mood_scores.get(mood, 2)
            total_score += score
            total_checkins += 1

            # Determine if first or second half of week
            day_index = (datetime.fromisoformat(day_str).date() - week_ago).days
            if day_index < 4:
                first_half_scores.append(score)
            else:
                second_half_scores.append(score)

        # Calculate primary mood for each day (most frequent)
        for day_str, day_data in days_data.items():
            if day_data["moods"]:
                mood_counts = {}
                for m in day_data["moods"]:
                    mood_counts[m["mood"]] = mood_counts.get(m["mood"], 0) + 1
                day_data["primary_mood"] = max(mood_counts, key=mood_counts.get)

        # Calculate trend
        avg_score = total_score / total_checkins if total_checkins > 0 else 0
        first_half_avg = sum(first_half_scores) / len(first_half_scores) if first_half_scores else 0
        second_half_avg = sum(second_half_scores) / len(second_half_scores) if second_half_scores else 0

        if second_half_avg > first_half_avg + 0.3:
            trend = "improving"
        elif second_half_avg < first_half_avg - 0.3:
            trend = "declining"
        else:
            trend = "stable"

        # Convert to list sorted by date
        days_list = [
            MoodDayData(
                date=d["date"],
                day_name=d["day_name"],
                moods=[MoodDayEntry(**m) for m in d["moods"]],
                primary_mood=d["primary_mood"],
                checkin_count=d["checkin_count"],
                workout_completed=d["workout_completed"],
            )
            for d in sorted(days_data.values(), key=lambda x: x["date"])
        ]

        return MoodWeeklyResponse(
            days=days_list,
            summary=MoodWeeklySummary(
                total_checkins=total_checkins,
                avg_mood_score=round(avg_score, 2),
                trend=trend,
            ),
        )

    except Exception as e:
        logger.error(f"Failed to get weekly mood data: {e}", exc_info=True)
        raise safe_internal_error(e, "generation")


@router.get("/{user_id}/mood-calendar", response_model=MoodCalendarResponse)
async def get_mood_calendar(user_id: str, month: int, year: int,
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's mood data for a specific month.

    Returns mood check-ins organized by day for calendar heatmap visualization.
    """
    logger.info(f"Fetching mood calendar for user {user_id}, {year}-{month:02d}")

    try:
        db = get_supabase_db()

        # Validate month and year
        if month < 1 or month > 12:
            raise HTTPException(status_code=400, detail="Month must be between 1 and 12")
        if year < 2020 or year > 2100:
            raise HTTPException(status_code=400, detail="Invalid year")

        # Calculate date range for the month
        _, last_day = calendar.monthrange(year, month)
        start_date = f"{year}-{month:02d}-01"
        end_date = f"{year}-{month:02d}-{last_day}"

        # Fetch check-ins for the month
        result = db.client.table("mood_checkins") \
            .select("*") \
            .eq("user_id", user_id) \
            .gte("check_in_time", start_date) \
            .lte("check_in_time", f"{end_date}T23:59:59") \
            .order("check_in_time", desc=False) \
            .execute()

        checkins = result.data or []

        # Initialize days dict with all days of the month
        days_data: Dict[str, Optional[Dict]] = {}
        for day in range(1, last_day + 1):
            day_str = f"{year}-{month:02d}-{day:02d}"
            days_data[day_str] = None

        # Process check-ins
        day_checkins: Dict[str, List[str]] = {}  # date -> list of moods

        for checkin in checkins:
            check_time = checkin.get("check_in_time", "")
            if not check_time:
                continue

            # Parse date
            if "T" in check_time:
                day_str = check_time.split("T")[0]
            else:
                day_str = check_time[:10]

            if day_str not in days_data:
                continue

            mood = checkin.get("mood", "good")

            if day_str not in day_checkins:
                day_checkins[day_str] = []
            day_checkins[day_str].append(mood)

        # Calculate stats for each day with check-ins
        mood_counts_total: Dict[str, int] = {}
        days_with_checkins = 0
        total_checkins = 0

        for day_str, moods in day_checkins.items():
            if moods:
                days_with_checkins += 1
                total_checkins += len(moods)

                # Count moods for this day
                mood_counts = {}
                for m in moods:
                    mood_counts[m] = mood_counts.get(m, 0) + 1
                    mood_counts_total[m] = mood_counts_total.get(m, 0) + 1

                # Get primary mood (most frequent)
                primary_mood = max(mood_counts, key=mood_counts.get)
                config = mood_workout_service.get_mood_config(
                    mood_workout_service.validate_mood(primary_mood)
                )

                days_data[day_str] = {
                    "moods": moods,
                    "primary_mood": primary_mood,
                    "color": config.color_hex,
                    "checkin_count": len(moods),
                }

        # Convert to response format
        days_response: Dict[str, Optional[MoodCalendarDay]] = {}
        for day_str, data in days_data.items():
            if data:
                days_response[day_str] = MoodCalendarDay(**data)
            else:
                days_response[day_str] = None

        # Get most common mood
        most_common_mood = max(mood_counts_total, key=mood_counts_total.get) if mood_counts_total else None

        return MoodCalendarResponse(
            month=month,
            year=year,
            days=days_response,
            summary=MoodCalendarSummary(
                days_with_checkins=days_with_checkins,
                total_checkins=total_checkins,
                most_common_mood=most_common_mood,
            ),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get mood calendar data: {e}", exc_info=True)
        raise safe_internal_error(e, "generation")
