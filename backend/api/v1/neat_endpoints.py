"""Secondary endpoints for neat.  Sub-router included by main module.
NEAT (Non-Exercise Activity Thermogenesis) Improvement System API Endpoints.

NEAT refers to the energy expended for everything we do that is not sleeping,
eating, or sports-like exercise. This includes walking, typing, yard work,
and even fidgeting.

Endpoints:
- Goals: Manage step goals and progressive goal setting
- Hourly Activity: Record and retrieve hourly activity from health sync
- NEAT Score: Calculate and retrieve daily NEAT scores
- Streaks: Track multiple streak types (steps, active hours, movement)
- Achievements: Earn badges for NEAT activities
- Reminder Preferences: Configure movement reminder settings
- Dashboard: Combined endpoint for efficient UI loading
- Scheduler: Cron job endpoints for background processing
"""
import asyncio
from typing import Any, Dict
from datetime import datetime, timedelta, date, time
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
import logging
logger = logging.getLogger(__name__)
import random
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.activity_logger import log_user_activity
from services.user_context_service import UserContextService, EventType


def _neat_parent():
    """Lazy import to avoid circular dependency with parent module."""
    from .neat import (
        get_streak_message, get_motivation_message_for_dashboard,
        get_neat_goals, get_today_neat_score, get_hourly_breakdown,
        get_neat_score_history, calculate_neat_score,
        calculate_progressive_goal, update_neat_goals,
    )
    return (
        get_streak_message, get_motivation_message_for_dashboard,
        get_neat_goals, get_today_neat_score, get_hourly_breakdown,
        get_neat_score_history, calculate_neat_score,
        calculate_progressive_goal, update_neat_goals,
    )
from models.neat import (
    NEATGoal, NEATGoalProgress, ProgressiveGoalRequest, ProgressiveGoalResponse,
    UpdateGoalRequest, GoalAdjustmentStrategy,
    HourlyActivityInput, HourlyActivityRecord, HourlyBreakdown,
    BatchHourlyActivityInput, BatchHourlyActivityResponse,
    NEATScore, NEATScoreComponents, NEATScoreHistory, CalculateScoreRequest,
    NEATStreak, StreaksResponse, StreakSummary, StreakType,
    NEATAchievementDefinition, UserNEATAchievement, AchievementProgress,
    AchievementsResponse, AvailableAchievementsResponse, AchievementCheckResult,
    NEATAchievementCategory, AchievementTier,
    ReminderPreferences, UpdateReminderPreferencesRequest, ShouldRemindResponse,
    ReminderFrequency, DayOfWeek,
    NEATDashboard,
    SendRemindersRequest, SendRemindersResponse,
    CalculateDailyScoresRequest, CalculateDailyScoresResponse,
    AdjustWeeklyGoalsRequest, AdjustWeeklyGoalsResponse,
)

router = APIRouter()
@router.get("/streaks/{user_id}/summary", response_model=StreakSummary, tags=["NEAT Streaks"])
async def get_streak_summary(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get a compact streak summary for display.

    Returns current streak values for each type and identifies
    the best performing streak.
    """
    (get_streak_message, get_motivation_message_for_dashboard,
     get_neat_goals, get_today_neat_score, get_hourly_breakdown,
     get_neat_score_history, calculate_neat_score,
     calculate_progressive_goal, update_neat_goals) = _neat_parent()
    db = get_supabase_db()

    try:
        response = db.client.table("neat_streaks").select("*").eq(
            "user_id", user_id
        ).execute()

        streaks = {s.get("streak_type"): s for s in (response.data or [])}

        step_goal = streaks.get(StreakType.STEP_GOAL.value, {}).get("current_length", 0)
        active_hours = streaks.get(StreakType.ACTIVE_HOURS.value, {}).get("current_length", 0)
        movement_breaks = streaks.get(StreakType.MOVEMENT_BREAKS.value, {}).get("current_length", 0)
        neat_score = streaks.get(StreakType.NEAT_SCORE.value, {}).get("current_length", 0)

        # Find best current and all-time
        best_type = None
        best_value = 0
        all_time_best = 0
        all_time_type = None

        for s in (response.data or []):
            current = s.get("current_length", 0)
            longest = s.get("longest_length", 0)

            if current > best_value:
                best_value = current
                best_type = s.get("streak_type")

            if longest > all_time_best:
                all_time_best = longest
                all_time_type = s.get("streak_type")

        message = get_streak_message(best_type, best_value)

        return StreakSummary(
            user_id=user_id,
            step_goal_streak=step_goal,
            active_hours_streak=active_hours,
            movement_breaks_streak=movement_breaks,
            neat_score_streak=neat_score,
            best_streak_type=best_type,
            best_streak_value=best_value,
            all_time_best=all_time_best,
            all_time_best_type=all_time_type,
            streak_message=message,
        )

    except Exception as e:
        logger.error(f"Error fetching streak summary: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_streak_summary")


# ============================================================================
# Achievements Endpoints
# ============================================================================

@router.get("/achievements/{user_id}", response_model=AchievementsResponse, tags=["NEAT Achievements"])
async def get_neat_achievements(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all earned NEAT achievements for a user.

    Returns earned achievements with total points and recently earned items.
    """
    db = get_supabase_db()

    try:
        # Get user's achievements with definitions
        response = db.client.table("user_neat_achievements").select(
            "*, neat_achievement_definitions(*)"
        ).eq("user_id", user_id).order("achieved_at", desc=True).execute()

        earned = []
        total_points = 0
        recently_earned = []
        one_week_ago = datetime.now() - timedelta(days=7)

        for data in (response.data or []):
            definition_data = data.get("neat_achievement_definitions", {})
            definition = NEATAchievementDefinition(**definition_data) if definition_data else None

            achievement = UserNEATAchievement(
                id=data.get("id"),
                user_id=data.get("user_id"),
                achievement_id=data.get("achievement_id"),
                achieved_at=datetime.fromisoformat(data.get("achieved_at")),
                trigger_value=data.get("trigger_value"),
                is_notified=data.get("is_notified", False),
                is_celebrated=data.get("is_celebrated", False),
                achievement=definition,
            )
            earned.append(achievement)

            if definition:
                total_points += definition.points

            if achievement.achieved_at > one_week_ago:
                recently_earned.append(achievement)

        return AchievementsResponse(
            user_id=user_id,
            earned=earned,
            total_points=total_points,
            total_earned=len(earned),
            recently_earned=recently_earned,
        )

    except Exception as e:
        logger.error(f"Error fetching NEAT achievements: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_achievements")


@router.get("/achievements/{user_id}/available", response_model=AvailableAchievementsResponse, tags=["NEAT Achievements"])
async def get_available_achievements(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get available achievements with progress toward each.

    Returns achievements the user hasn't earned yet with their
    current progress percentage.
    """
    db = get_supabase_db()

    try:
        # Get all definitions
        definitions_response = db.client.table("neat_achievement_definitions").select(
            "*"
        ).eq("is_active", True).order("sort_order").execute()

        # Get user's earned achievement IDs
        earned_response = db.client.table("user_neat_achievements").select(
            "achievement_id"
        ).eq("user_id", user_id).execute()

        earned_ids = {r.get("achievement_id") for r in (earned_response.data or [])}

        # Get user's current metrics for progress calculation
        today = date.today().isoformat()

        # Get total steps this month
        month_start = date.today().replace(day=1).isoformat()
        steps_response = db.client.table("daily_activity").select(
            "steps"
        ).eq("user_id", user_id).gte("activity_date", month_start).execute()

        total_steps = sum(r.get("steps", 0) for r in (steps_response.data or []))

        # Get current streaks
        streaks_response = db.client.table("neat_streaks").select(
            "streak_type, current_length, longest_length"
        ).eq("user_id", user_id).execute()

        streaks = {s.get("streak_type"): s for s in (streaks_response.data or [])}

        # Build available achievements with progress
        available = []
        closest = None
        closest_progress = 0

        for data in (definitions_response.data or []):
            if data.get("id") in earned_ids:
                continue

            definition = NEATAchievementDefinition(**data)

            # Calculate progress based on category
            current_value = 0
            if definition.category == NEATAchievementCategory.STEPS.value:
                current_value = total_steps
            elif definition.category == NEATAchievementCategory.STREAKS.value:
                # Use max of all streaks
                current_value = max(
                    s.get("current_length", 0) for s in streaks.values()
                ) if streaks else 0

            progress_pct = min((current_value / definition.threshold * 100), 99) if definition.threshold > 0 else 0

            progress = AchievementProgress(
                achievement=definition,
                is_achieved=False,
                current_value=current_value,
                progress_percentage=round(progress_pct, 1),
            )
            available.append(progress)

            if progress_pct > closest_progress:
                closest_progress = progress_pct
                closest = progress

        return AvailableAchievementsResponse(
            user_id=user_id,
            available=available,
            closest_to_unlock=closest,
        )

    except Exception as e:
        logger.error(f"Error fetching available achievements: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_available_achievements")


@router.post("/achievements/{user_id}/check", response_model=AchievementCheckResult, tags=["NEAT Achievements"])
async def check_neat_achievements(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Check and award any new NEAT achievements.

    Evaluates user's current metrics against achievement thresholds
    and awards any newly unlocked achievements.
    """
    db = get_supabase_db()

    try:
        logger.info(f"Checking NEAT achievements for user {user_id}")

        # Get all active definitions
        definitions_response = db.client.table("neat_achievement_definitions").select(
            "*"
        ).eq("is_active", True).execute()

        # Get user's earned achievements
        earned_response = db.client.table("user_neat_achievements").select(
            "achievement_id"
        ).eq("user_id", user_id).execute()

        earned_ids = {r.get("achievement_id") for r in (earned_response.data or [])}

        # Get user's metrics
        # Total steps all time
        steps_response = db.client.table("daily_activity").select(
            "steps"
        ).eq("user_id", user_id).execute()

        total_steps = sum(r.get("steps", 0) for r in (steps_response.data or []))

        # Streaks
        streaks_response = db.client.table("neat_streaks").select(
            "streak_type, current_length, longest_length"
        ).eq("user_id", user_id).execute()

        max_streak = max(
            max(s.get("current_length", 0), s.get("longest_length", 0))
            for s in (streaks_response.data or [{}])
        ) if streaks_response.data else 0

        # Days with goal met
        goals_met_response = db.client.table("neat_scores").select(
            "id", count="exact"
        ).eq("user_id", user_id).eq("step_goal_met", True).execute()

        days_goal_met = goals_met_response.count or 0

        # Check each definition
        new_achievements = []
        total_new_points = 0

        for definition in (definitions_response.data or []):
            if definition.get("id") in earned_ids:
                continue

            threshold = definition.get("threshold", 0)
            category = definition.get("category")

            # Determine if threshold is met
            met = False
            trigger_value = 0

            if category == NEATAchievementCategory.STEPS.value:
                if total_steps >= threshold:
                    met = True
                    trigger_value = total_steps
            elif category == NEATAchievementCategory.STREAKS.value:
                if max_streak >= threshold:
                    met = True
                    trigger_value = max_streak
            elif category == NEATAchievementCategory.CONSISTENCY.value:
                if days_goal_met >= threshold:
                    met = True
                    trigger_value = days_goal_met

            if met:
                # Award achievement
                achievement_data = {
                    "user_id": user_id,
                    "achievement_id": definition.get("id"),
                    "achieved_at": datetime.now().isoformat(),
                    "trigger_value": trigger_value,
                    "is_notified": False,
                    "is_celebrated": False,
                }

                insert_response = db.client.table("user_neat_achievements").insert(
                    achievement_data
                ).execute()

                if insert_response.data:
                    awarded = UserNEATAchievement(
                        id=insert_response.data[0].get("id"),
                        user_id=user_id,
                        achievement_id=definition.get("id"),
                        achieved_at=datetime.now(),
                        trigger_value=trigger_value,
                        achievement=NEATAchievementDefinition(**definition),
                    )
                    new_achievements.append(awarded)
                    total_new_points += definition.get("points", 0)

                    logger.info(f"Awarded NEAT achievement {definition.get('name')} to user {user_id}")

        return AchievementCheckResult(
            new_achievements=new_achievements,
            total_new_points=total_new_points,
        )

    except Exception as e:
        logger.error(f"Error checking NEAT achievements: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_check_achievements")


# ============================================================================
# Reminder Preferences Endpoints
# ============================================================================

@router.get("/reminders/{user_id}/preferences", response_model=ReminderPreferences, tags=["NEAT Reminders"])
async def get_reminder_preferences(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get the user's movement reminder preferences.

    Returns settings for reminder frequency, active hours, and days.
    """
    db = get_supabase_db()

    try:
        response = db.client.table("neat_reminder_preferences").select("*").eq(
            "user_id", user_id
        ).maybe_single().execute()

        if response.data:
            data = response.data
            # Parse time fields
            start_time = time.fromisoformat(data.get("start_time", "08:00:00"))
            end_time = time.fromisoformat(data.get("end_time", "20:00:00"))

            return ReminderPreferences(
                id=data.get("id"),
                user_id=data.get("user_id"),
                enabled=data.get("enabled", True),
                frequency=data.get("frequency", ReminderFrequency.EVERY_60_MIN.value),
                start_time=start_time,
                end_time=end_time,
                active_days=data.get("active_days", [d.value for d in [
                    DayOfWeek.MONDAY, DayOfWeek.TUESDAY, DayOfWeek.WEDNESDAY,
                    DayOfWeek.THURSDAY, DayOfWeek.FRIDAY
                ]]),
                skip_if_active=data.get("skip_if_active", True),
                active_threshold_minutes=data.get("active_threshold_minutes", 5),
                quiet_during_workout=data.get("quiet_during_workout", True),
                reminder_message_style=data.get("reminder_message_style", "encouraging"),
                created_at=datetime.fromisoformat(data.get("created_at")) if data.get("created_at") else None,
                updated_at=datetime.fromisoformat(data.get("updated_at")) if data.get("updated_at") else None,
            )
        else:
            # Return defaults
            return ReminderPreferences(user_id=user_id)

    except Exception as e:
        logger.error(f"Error fetching reminder preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_reminder_preferences")


@router.put("/reminders/{user_id}/preferences", response_model=ReminderPreferences, tags=["NEAT Reminders"])
async def update_reminder_preferences(
    user_id: str,
    request: UpdateReminderPreferencesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the user's movement reminder preferences.

    Allows partial updates to any reminder setting.
    """
    db = get_supabase_db()

    try:
        update_data: Dict[str, Any] = {"user_id": user_id}

        if request.enabled is not None:
            update_data["enabled"] = request.enabled
        if request.frequency is not None:
            update_data["frequency"] = request.frequency
        if request.start_time is not None:
            update_data["start_time"] = request.start_time.isoformat()
        if request.end_time is not None:
            update_data["end_time"] = request.end_time.isoformat()
        if request.active_days is not None:
            update_data["active_days"] = request.active_days
        if request.skip_if_active is not None:
            update_data["skip_if_active"] = request.skip_if_active
        if request.active_threshold_minutes is not None:
            update_data["active_threshold_minutes"] = request.active_threshold_minutes
        if request.quiet_during_workout is not None:
            update_data["quiet_during_workout"] = request.quiet_during_workout
        if request.reminder_message_style is not None:
            update_data["reminder_message_style"] = request.reminder_message_style

        update_data["updated_at"] = datetime.now().isoformat()

        response = db.client.table("neat_reminder_preferences").upsert(
            update_data,
            on_conflict="user_id"
        ).execute()

        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to update reminder preferences")

        # Log preference update
        await log_user_activity(
            user_id=user_id,
            action="neat_reminder_preferences_updated",
            endpoint=f"/api/v1/neat/reminders/{user_id}/preferences",
            message="Updated NEAT reminder preferences",
            metadata={k: str(v) for k, v in update_data.items() if k != "user_id"},
            status_code=200,
        )

        return await get_reminder_preferences(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating reminder preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_reminder_update")


@router.get("/reminders/{user_id}/should-remind", response_model=ShouldRemindResponse, tags=["NEAT Reminders"])
async def should_send_reminder(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Check if a movement reminder should be sent now.

    Evaluates current time, day, user's recent activity, and preferences
    to determine if a reminder is appropriate.
    """
    db = get_supabase_db()

    try:
        now = datetime.now()
        current_time = now.time()
        current_day = DayOfWeek(now.strftime("%A").lower())

        # Get preferences
        prefs = await get_reminder_preferences(user_id)

        # Check if reminders are enabled
        if not prefs.enabled:
            return ShouldRemindResponse(
                should_remind=False,
                reason="Reminders are disabled",
            )

        # Check if current day is active
        if current_day.value not in [d.value if isinstance(d, DayOfWeek) else d for d in prefs.active_days]:
            return ShouldRemindResponse(
                should_remind=False,
                reason=f"{current_day.value.capitalize()} is not an active reminder day",
            )

        # Check if current time is within active hours
        if current_time < prefs.start_time or current_time > prefs.end_time:
            return ShouldRemindResponse(
                should_remind=False,
                reason="Outside of active reminder hours",
                next_reminder_at=datetime.combine(now.date(), prefs.start_time) if current_time < prefs.start_time else None,
            )

        # Check if user has an active workout (if quiet_during_workout is enabled)
        if prefs.quiet_during_workout:
            # Check for active workout in last hour
            one_hour_ago = (now - timedelta(hours=1)).isoformat()
            workout_response = db.client.table("workouts").select("id").eq(
                "user_id", user_id
            ).eq("completed", False).gte("started_at", one_hour_ago).maybe_single().execute()

            if workout_response.data:
                return ShouldRemindResponse(
                    should_remind=False,
                    reason="User has an active workout",
                )

        # Check recent activity if skip_if_active is enabled
        if prefs.skip_if_active:
            # Get activity for current hour
            today = now.date().isoformat()
            current_hour = now.hour

            hourly_response = db.client.table("neat_hourly_activity").select(
                "active_minutes, created_at"
            ).eq("user_id", user_id).eq("activity_date", today).eq(
                "hour", current_hour
            ).maybe_single().execute()

            if hourly_response.data:
                active_minutes = hourly_response.data.get("active_minutes", 0)
                if active_minutes >= prefs.active_threshold_minutes:
                    return ShouldRemindResponse(
                        should_remind=False,
                        reason="User was recently active",
                        last_active_at=datetime.fromisoformat(hourly_response.data.get("created_at")) if hourly_response.data.get("created_at") else None,
                        minutes_since_activity=0,
                    )

        # Generate reminder message
        messages = {
            "encouraging": [
                "Time for a quick stretch! Your body will thank you.",
                "How about a short walk? Every step counts!",
                "Stand up and move around for a minute!",
            ],
            "factual": [
                "You've been sedentary for a while. Consider moving.",
                "Regular movement breaks improve focus and health.",
                "Time to add some steps to your daily count.",
            ],
            "playful": [
                "Your legs are getting lonely! Give them a walk!",
                "Couch potato alert! Time to move those limbs!",
                "Your step counter is feeling neglected...",
            ],
        }

        style_messages = messages.get(prefs.reminder_message_style, messages["encouraging"])
        suggested_message = random.choice(style_messages)

        # Calculate next reminder time
        frequency_minutes = {
            ReminderFrequency.EVERY_30_MIN.value: 30,
            ReminderFrequency.EVERY_45_MIN.value: 45,
            ReminderFrequency.EVERY_60_MIN.value: 60,
            ReminderFrequency.EVERY_90_MIN.value: 90,
            ReminderFrequency.EVERY_120_MIN.value: 120,
        }

        freq_value = prefs.frequency.value if isinstance(prefs.frequency, ReminderFrequency) else prefs.frequency
        minutes = frequency_minutes.get(freq_value, 60)
        next_reminder = now + timedelta(minutes=minutes)

        return ShouldRemindResponse(
            should_remind=True,
            reason="Reminder criteria met",
            next_reminder_at=next_reminder,
            suggested_message=suggested_message,
        )

    except Exception as e:
        logger.error(f"Error checking should remind: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_should_remind")


# ============================================================================
# Dashboard Endpoint
# ============================================================================

@router.get("/dashboard/{user_id}", response_model=NEATDashboard, tags=["NEAT Dashboard"])
async def get_neat_dashboard(
    user_id: str,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Get combined NEAT dashboard data.

    Returns all data needed for the NEAT dashboard in a single call:
    - Current goal and progress
    - Today's NEAT score
    - Current streaks
    - Recent achievements
    - Hourly breakdown
    - Trend information
    """
    (get_streak_message, get_motivation_message_for_dashboard,
     get_neat_goals, get_today_neat_score, get_hourly_breakdown,
     get_neat_score_history, calculate_neat_score,
     calculate_progressive_goal, update_neat_goals) = _neat_parent()
    try:
        logger.info(f"Fetching NEAT dashboard for user {user_id}")

        # Fetch all data concurrently (in production, use asyncio.gather)
        goal_progress = await get_neat_goals(user_id, background_tasks)
        today_score = await get_today_neat_score(user_id)
        streak_summary = await get_streak_summary(user_id)

        # Get recent achievements
        achievements_response = await get_neat_achievements(user_id)
        recent_achievements = achievements_response.recently_earned
        uncelebrated = [a for a in achievements_response.earned if not a.is_celebrated]

        # Get today's hourly breakdown
        hourly_breakdown = await get_hourly_breakdown(user_id, date.today())

        # Get weekly average and trend
        history = await get_neat_score_history(user_id, limit=7)
        weekly_average = history.average_score if history.scores else None
        weekly_trend = history.trend

        # Generate motivation message
        motivation = get_motivation_message_for_dashboard(
            score=today_score.total_score if today_score else None,
            step_progress=goal_progress.step_progress_percentage,
            streak_value=streak_summary.best_streak_value,
        )

        # Determine next milestone
        available = await get_available_achievements(user_id)
        next_milestone = None
        if available.closest_to_unlock:
            next_milestone = f"{available.closest_to_unlock.progress_percentage:.0f}% to {available.closest_to_unlock.achievement.name}"

        dashboard = NEATDashboard(
            user_id=user_id,
            goal_progress=goal_progress,
            today_score=today_score,
            streak_summary=streak_summary,
            recent_achievements=recent_achievements,
            uncelebrated_achievements=uncelebrated,
            hourly_breakdown=hourly_breakdown,
            weekly_average_score=weekly_average,
            weekly_trend=weekly_trend,
            motivational_message=motivation,
            next_milestone=next_milestone,
            generated_at=datetime.now(),
        )

        # Log dashboard view
        background_tasks.add_task(
            user_context_service.log_event,
            user_id=user_id,
            event_type=EventType.SCREEN_VIEW,
            event_data={
                "screen": "neat_dashboard",
                "step_progress": goal_progress.step_progress_percentage,
                "today_score": today_score.total_score if today_score else None,
            },
        )

        return dashboard

    except Exception as e:
        logger.error(f"Error fetching NEAT dashboard: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_dashboard")


# ============================================================================
# Scheduler Endpoints (for Cron Jobs)
# ============================================================================

@router.post("/scheduler/send-movement-reminders", response_model=SendRemindersResponse, tags=["NEAT Scheduler"])
async def send_movement_reminders(request: SendRemindersRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Send movement reminders to sedentary users.

    Called by cron job to check users who should receive reminders
    and trigger push notifications.
    """
    db = get_supabase_db()

    try:
        logger.info(f"Running movement reminder scheduler (dry_run={request.dry_run})")

        now = datetime.now()
        current_hour = now.hour
        current_day = now.strftime("%A").lower()

        # Get users with reminders enabled for current time/day
        prefs_response = db.client.table("neat_reminder_preferences").select(
            "user_id"
        ).eq("enabled", True).contains("active_days", [current_day]).execute()

        users_checked = 0
        reminders_sent = 0
        skipped_active = 0
        skipped_preferences = 0
        errors = 0

        for pref in (prefs_response.data or [])[:request.max_users]:
            user_id = pref.get("user_id")
            users_checked += 1

            try:
                should_remind = await should_send_reminder(user_id)

                if not should_remind.should_remind:
                    if "active" in should_remind.reason.lower():
                        skipped_active += 1
                    else:
                        skipped_preferences += 1
                    continue

                if not request.dry_run:
                    logger.info("Push notification not implemented: NEAT movement reminder for user %s (message: %s)", user_id, should_remind.suggested_message)

                reminders_sent += 1

            except Exception as e:
                logger.error(f"Error processing reminder for user {user_id}: {e}", exc_info=True)
                errors += 1

        logger.info(f"Movement reminders: {reminders_sent} sent, {skipped_active} skipped (active), {errors} errors")

        return SendRemindersResponse(
            users_checked=users_checked,
            reminders_sent=reminders_sent,
            skipped_active=skipped_active,
            skipped_preferences=skipped_preferences,
            errors=errors,
            dry_run=request.dry_run,
        )

    except Exception as e:
        logger.error(f"Error in movement reminder scheduler: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_reminder_scheduler")


@router.post("/scheduler/calculate-daily-scores", response_model=CalculateDailyScoresResponse, tags=["NEAT Scheduler"])
async def calculate_daily_scores(request: CalculateDailyScoresRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate end-of-day NEAT scores for all users.

    Called by cron job at end of day to calculate final scores
    and update streaks.
    """
    (get_streak_message, get_motivation_message_for_dashboard,
     get_neat_goals, get_today_neat_score, get_hourly_breakdown,
     get_neat_score_history, calculate_neat_score,
     calculate_progressive_goal, update_neat_goals) = _neat_parent()
    db = get_supabase_db()

    try:
        target_date = request.target_date or (date.today() - timedelta(days=1))
        logger.info(f"Calculating daily NEAT scores for {target_date}")

        # Get all users with hourly activity for the target date
        users_response = db.client.table("neat_hourly_activity").select(
            "user_id"
        ).eq("activity_date", target_date.isoformat()).execute()

        unique_users = list({r.get("user_id") for r in (users_response.data or [])})

        users_processed = 0
        scores_calculated = 0
        streaks_updated = 0
        errors = 0

        for user_id in unique_users[:request.max_users]:
            users_processed += 1

            try:
                # Calculate score
                score_request = CalculateScoreRequest(user_id=user_id, force_recalculate=True)
                await calculate_neat_score(user_id, score_request)
                scores_calculated += 1

                # Streak updates based on score not yet implemented
                logger.info("Streak update not implemented: skipping streak check for user %s after score calculation", user_id)

            except Exception as e:
                logger.error(f"Error calculating score for user {user_id}: {e}", exc_info=True)
                errors += 1

        logger.info(f"Daily scores: {scores_calculated} calculated, {errors} errors")

        return CalculateDailyScoresResponse(
            target_date=target_date,
            users_processed=users_processed,
            scores_calculated=scores_calculated,
            streaks_updated=streaks_updated,
            errors=errors,
        )

    except Exception as e:
        logger.error(f"Error in daily score calculator: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_daily_scores")


@router.post("/scheduler/adjust-weekly-goals", response_model=AdjustWeeklyGoalsResponse, tags=["NEAT Scheduler"])
async def adjust_weekly_goals(request: AdjustWeeklyGoalsRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Adjust progressive goals weekly.

    Called by cron job weekly to evaluate user performance and
    adjust step goals according to their progressive goal settings.
    """
    (get_streak_message, get_motivation_message_for_dashboard,
     get_neat_goals, get_today_neat_score, get_hourly_breakdown,
     get_neat_score_history, calculate_neat_score,
     calculate_progressive_goal, update_neat_goals) = _neat_parent()
    db = get_supabase_db()

    try:
        logger.info(f"Running weekly goal adjustment (dry_run={request.dry_run})")

        # Get users with progressive goals enabled
        goals_response = db.client.table("neat_goals").select(
            "user_id, daily_step_goal, adjustment_strategy"
        ).eq("is_progressive", True).execute()

        users_checked = 0
        goals_adjusted = 0
        goals_increased = 0
        goals_decreased = 0
        goals_unchanged = 0

        for goal in (goals_response.data or [])[:request.max_users]:
            user_id = goal.get("user_id")
            current_goal = goal.get("daily_step_goal")
            strategy = goal.get("adjustment_strategy", GoalAdjustmentStrategy.MODERATE.value)
            users_checked += 1

            try:
                # Calculate progressive goal
                prog_request = ProgressiveGoalRequest(
                    user_id=user_id,
                    strategy=GoalAdjustmentStrategy(strategy),
                    look_back_days=14,
                )
                result = await calculate_progressive_goal(user_id, prog_request)

                if result.suggested_goal != current_goal:
                    if not request.dry_run:
                        # Apply the new goal
                        update_request = UpdateGoalRequest(daily_step_goal=result.suggested_goal)
                        await update_neat_goals(user_id, update_request)

                        # Update last adjustment date
                        db.client.table("neat_goals").update({
                            "last_adjustment_date": date.today().isoformat()
                        }).eq("user_id", user_id).execute()

                    goals_adjusted += 1
                    if result.suggested_goal > current_goal:
                        goals_increased += 1
                    else:
                        goals_decreased += 1
                else:
                    goals_unchanged += 1

            except Exception as e:
                logger.error(f"Error adjusting goal for user {user_id}: {e}", exc_info=True)

        logger.info(f"Weekly goals: {goals_adjusted} adjusted ({goals_increased} increased, {goals_decreased} decreased)")

        return AdjustWeeklyGoalsResponse(
            users_checked=users_checked,
            goals_adjusted=goals_adjusted,
            goals_increased=goals_increased,
            goals_decreased=goals_decreased,
            goals_unchanged=goals_unchanged,
            dry_run=request.dry_run,
        )

    except Exception as e:
        logger.error(f"Error in weekly goal adjustment: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_weekly_goals")
