"""
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
from .neat_endpoints import router as _endpoints_router


from datetime import datetime, date, time, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.timezone_utils import user_today_date
from collections import defaultdict
import logging
import random

from core.db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.neat import (
    # Goals
    NEATGoal,
    NEATGoalProgress,
    ProgressiveGoalRequest,
    ProgressiveGoalResponse,
    UpdateGoalRequest,
    GoalAdjustmentStrategy,
    # Hourly Activity
    HourlyActivityInput,
    HourlyActivityRecord,
    HourlyBreakdown,
    BatchHourlyActivityInput,
    BatchHourlyActivityResponse,
    # NEAT Score
    NEATScore,
    NEATScoreComponents,
    NEATScoreHistory,
    CalculateScoreRequest,
    # Streaks
    NEATStreak,
    StreaksResponse,
    StreakSummary,
    StreakType,
    # Achievements
    NEATAchievementDefinition,
    UserNEATAchievement,
    AchievementProgress,
    AchievementsResponse,
    AvailableAchievementsResponse,
    AchievementCheckResult,
    NEATAchievementCategory,
    AchievementTier,
    # Reminders
    ReminderPreferences,
    UpdateReminderPreferencesRequest,
    ShouldRemindResponse,
    ReminderFrequency,
    DayOfWeek,
    # Dashboard
    NEATDashboard,
    # Scheduler
    SendRemindersRequest,
    SendRemindersResponse,
    CalculateDailyScoresRequest,
    CalculateDailyScoresResponse,
    AdjustWeeklyGoalsRequest,
    AdjustWeeklyGoalsResponse,
)
from services.user_context_service import user_context_service, EventType

logger = get_logger(__name__)

router = APIRouter()


# ============================================================================
# Helper Functions
# ============================================================================

def calculate_neat_score(
    total_steps: int,
    step_goal: int,
    active_hours: int,
    active_hours_goal: int,
    movement_breaks: int,
    movement_breaks_goal: int,
    hourly_consistency: float,  # 0-1, how evenly distributed steps are
) -> tuple[float, NEATScoreComponents]:
    """
    Calculate NEAT score based on multiple factors.

    Scoring breakdown (max 100):
    - Step score (40 points): Based on steps vs goal
    - Consistency score (30 points): How evenly distributed activity is
    - Active hours score (20 points): Hours with activity above threshold
    - Movement breaks score (10 points): Number of movement breaks taken
    """
    # Step score (0-40)
    step_ratio = min(total_steps / step_goal, 1.5) if step_goal > 0 else 0
    step_score = min(step_ratio * 40, 40)

    # Consistency score (0-30)
    consistency_score = hourly_consistency * 30

    # Active hours score (0-20)
    hours_ratio = min(active_hours / active_hours_goal, 1.0) if active_hours_goal > 0 else 0
    active_hours_score = hours_ratio * 20

    # Movement breaks score (0-10)
    breaks_ratio = min(movement_breaks / movement_breaks_goal, 1.0) if movement_breaks_goal > 0 else 0
    movement_breaks_score = breaks_ratio * 10

    total_score = step_score + consistency_score + active_hours_score + movement_breaks_score

    components = NEATScoreComponents(
        step_score=round(step_score, 1),
        consistency_score=round(consistency_score, 1),
        active_hours_score=round(active_hours_score, 1),
        movement_breaks_score=round(movement_breaks_score, 1),
    )

    return round(total_score, 1), components


def score_to_grade(score: float) -> str:
    """Convert numeric score to letter grade."""
    if score >= 90:
        return "A+"
    elif score >= 85:
        return "A"
    elif score >= 80:
        return "A-"
    elif score >= 75:
        return "B+"
    elif score >= 70:
        return "B"
    elif score >= 65:
        return "B-"
    elif score >= 60:
        return "C+"
    elif score >= 55:
        return "C"
    elif score >= 50:
        return "C-"
    elif score >= 45:
        return "D+"
    elif score >= 40:
        return "D"
    else:
        return "F"


def get_score_message(score: float, step_goal_met: bool) -> str:
    """Generate encouraging message based on score."""
    if score >= 90:
        messages = [
            "Outstanding day! You're crushing your NEAT goals!",
            "Incredible activity level today! Keep up the amazing work!",
            "You're a movement champion today!",
        ]
    elif score >= 75:
        messages = [
            "Great job today! Your body is thanking you!",
            "Solid activity day! You're building healthy habits!",
            "Well done! Consistency like this makes a difference!",
        ]
    elif score >= 60:
        messages = [
            "Good effort today! A little more movement and you'll hit your goals!",
            "You're on the right track! Keep moving!",
            "Decent day! Try to add a few more steps tomorrow!",
        ]
    elif score >= 45:
        if step_goal_met:
            messages = ["You met your step goal! Try to spread activity more evenly tomorrow."]
        else:
            messages = [
                "Room for improvement! Try setting hourly movement reminders.",
                "Every step counts! Aim for more breaks tomorrow.",
            ]
    else:
        messages = [
            "Today was quiet. Tomorrow is a fresh start!",
            "Movement is medicine. Let's aim higher tomorrow!",
            "Small steps lead to big changes. You've got this!",
        ]

    return random.choice(messages)


def get_streak_message(best_streak_type: Optional[str], best_value: int) -> str:
    """Generate message about current streaks."""
    if not best_streak_type or best_value == 0:
        return "Start building your streaks today!"

    type_display = {
        "step_goal": "step goal",
        "active_hours": "active hours",
        "movement_breaks": "movement",
        "neat_score": "NEAT score",
    }

    display = type_display.get(best_streak_type, best_streak_type)

    if best_value >= 30:
        return f"Incredible {best_value}-day {display} streak! You're unstoppable!"
    elif best_value >= 14:
        return f"Amazing {best_value}-day {display} streak! Keep going!"
    elif best_value >= 7:
        return f"Great {best_value}-day {display} streak!"
    elif best_value >= 3:
        return f"Nice {best_value}-day {display} streak building!"
    else:
        return f"You have a {best_value}-day {display} streak. Keep it up!"


def calculate_hourly_consistency(hourly_steps: List[int]) -> float:
    """
    Calculate how evenly distributed steps are across hours.
    Returns 0-1 where 1 is perfectly even distribution.
    """
    if not hourly_steps or sum(hourly_steps) == 0:
        return 0.0

    # Filter to only waking hours with activity potential (e.g., 6 AM - 10 PM)
    total = sum(hourly_steps)
    active_hours = [s for s in hourly_steps if s > 0]

    if len(active_hours) <= 1:
        return 0.3  # Some credit for any activity

    # Calculate coefficient of variation (lower is more consistent)
    mean = total / len(active_hours)
    variance = sum((s - mean) ** 2 for s in active_hours) / len(active_hours)
    std_dev = variance ** 0.5
    cv = std_dev / mean if mean > 0 else 1

    # Convert CV to consistency score (0-1)
    # CV of 0 = perfect consistency (1.0)
    # CV of 1 = average variance (0.5)
    # CV of 2+ = poor consistency (0.0)
    consistency = max(0, 1 - (cv / 2))

    # Bonus for having activity in more hours
    hours_bonus = min(len(active_hours) / 12, 0.2)  # Up to 0.2 bonus for 12+ active hours

    return min(consistency + hours_bonus, 1.0)


def get_motivation_message_for_dashboard(
    score: Optional[float],
    step_progress: float,
    streak_value: int,
) -> str:
    """Generate a motivational message for the dashboard."""
    if score and score >= 80:
        return "You're having an amazing activity day! Keep it up!"
    elif step_progress >= 100:
        return "Step goal crushed! Can you beat yesterday's total?"
    elif step_progress >= 75:
        return "Almost there! Just a bit more to hit your goal!"
    elif step_progress >= 50:
        return "Halfway to your step goal! Keep moving!"
    elif streak_value >= 7:
        return f"Protect your {streak_value}-day streak! Every step counts!"
    elif streak_value >= 3:
        return "Building momentum! Keep your streak alive!"
    else:
        return "Every step counts toward a healthier you!"


# ============================================================================
# Goals Endpoints
# ============================================================================

@router.get("/goals/{user_id}", response_model=NEATGoalProgress, tags=["NEAT Goals"])
async def get_neat_goals(
    user_id: str,
    request: Request,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Get current NEAT goals and today's progress.

    Returns the user's step goal, active hours goal, and movement breaks goal
    along with current progress toward each.
    """
    db = get_supabase_db()

    try:
        logger.info(f"Fetching NEAT goals for user {user_id}")

        # Get or create goals
        goals_response = db.client.table("neat_goals").select("*").eq(
            "user_id", user_id
        ).maybe_single().execute()

        if goals_response.data:
            goal = NEATGoal(**goals_response.data)
        else:
            # Create default goals
            default_goal = {
                "user_id": user_id,
                "daily_step_goal": 8000,
                "active_hours_goal": 8,
                "movement_breaks_goal": 6,
                "min_steps_per_hour": 250,
                "is_progressive": True,
                "adjustment_strategy": GoalAdjustmentStrategy.MODERATE.value,
                "created_at": datetime.now().isoformat(),
            }
            insert_response = db.client.table("neat_goals").insert(default_goal).execute()
            if not insert_response.data:
                raise safe_internal_error(ValueError("Failed to create default NEAT goals"), "neat")
            goal = NEATGoal(**insert_response.data[0])

        # Get today's activity
        today = user_today_date(request).isoformat()
        activity_response = db.client.table("daily_activity").select(
            "steps"
        ).eq("user_id", user_id).eq("activity_date", today).maybe_single().execute()

        current_steps = activity_response.data.get("steps", 0) if activity_response.data else 0

        # Get today's hourly breakdown for active hours and movement breaks
        hourly_response = db.client.table("neat_hourly_activity").select(
            "hour, steps, active_minutes"
        ).eq("user_id", user_id).eq("activity_date", today).execute()

        active_hours = 0
        movement_breaks = 0

        for record in (hourly_response.data or []):
            if record.get("steps", 0) >= goal.min_steps_per_hour:
                active_hours += 1
            if record.get("active_minutes", 0) >= 5:
                movement_breaks += 1

        # Calculate progress percentages
        step_progress = (current_steps / goal.daily_step_goal * 100) if goal.daily_step_goal > 0 else 0
        active_hours_progress = (active_hours / goal.active_hours_goal * 100) if goal.active_hours_goal > 0 else 0
        movement_breaks_progress = (movement_breaks / goal.movement_breaks_goal * 100) if goal.movement_breaks_goal > 0 else 0

        # Estimate end-of-day steps
        current_hour = datetime.now().hour
        remaining_hours = max(0, 22 - current_hour)  # Assume activity stops at 10 PM
        avg_steps_per_hour = current_steps / max(current_hour - 6, 1) if current_hour > 6 else 0
        estimated_end_of_day = current_steps + int(avg_steps_per_hour * remaining_hours * 0.8)  # 0.8 factor for declining activity

        # Generate on-track message
        if step_progress >= 100:
            on_track_message = "You've hit your step goal!"
        elif estimated_end_of_day >= goal.daily_step_goal:
            on_track_message = "You're on track to meet your goal!"
        else:
            steps_needed = goal.daily_step_goal - current_steps
            on_track_message = f"Need {steps_needed:,} more steps to reach your goal"

        progress = NEATGoalProgress(
            goal=goal,
            current_steps=current_steps,
            step_progress_percentage=round(step_progress, 1),
            steps_remaining=max(0, goal.daily_step_goal - current_steps),
            active_hours_today=active_hours,
            active_hours_progress_percentage=round(active_hours_progress, 1),
            movement_breaks_today=movement_breaks,
            movement_breaks_progress_percentage=round(movement_breaks_progress, 1),
            is_step_goal_met=current_steps >= goal.daily_step_goal,
            is_active_hours_met=active_hours >= goal.active_hours_goal,
            is_movement_breaks_met=movement_breaks >= goal.movement_breaks_goal,
            estimated_steps_by_end_of_day=estimated_end_of_day,
            on_track_message=on_track_message,
            last_sync_at=datetime.now(),
        )

        # Log goal view
        background_tasks.add_task(
            log_user_activity,
            user_id=user_id,
            action="neat_goals_viewed",
            endpoint=f"/api/v1/neat/goals/{user_id}",
            message=f"Viewed NEAT goals: {current_steps}/{goal.daily_step_goal} steps",
            metadata={
                "current_steps": current_steps,
                "step_goal": goal.daily_step_goal,
                "step_progress": round(step_progress, 1),
            },
            status_code=200,
        )

        return progress

    except Exception as e:
        logger.error(f"Error fetching NEAT goals: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_goals_fetch")


@router.put("/goals/{user_id}", response_model=NEATGoal, tags=["NEAT Goals"])
async def update_neat_goals(
    user_id: str,
    request: UpdateGoalRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update the user's NEAT goals.

    Allows updating step goal, active hours goal, movement breaks goal,
    and progressive goal settings.
    """
    db = get_supabase_db()

    try:
        logger.info(f"Updating NEAT goals for user {user_id}")

        update_data = {}
        if request.daily_step_goal is not None:
            update_data["daily_step_goal"] = request.daily_step_goal
        if request.active_hours_goal is not None:
            update_data["active_hours_goal"] = request.active_hours_goal
        if request.movement_breaks_goal is not None:
            update_data["movement_breaks_goal"] = request.movement_breaks_goal
        if request.min_steps_per_hour is not None:
            update_data["min_steps_per_hour"] = request.min_steps_per_hour
        if request.is_progressive is not None:
            update_data["is_progressive"] = request.is_progressive
        if request.adjustment_strategy is not None:
            update_data["adjustment_strategy"] = request.adjustment_strategy

        update_data["updated_at"] = datetime.now().isoformat()

        response = db.client.table("neat_goals").update(update_data).eq(
            "user_id", user_id
        ).execute()

        if not response.data:
            raise HTTPException(status_code=404, detail="NEAT goals not found for user")

        # Log goal update
        try:
            await log_user_activity(
                user_id=user_id,
                action="neat_goals_updated",
                endpoint=f"/api/v1/neat/goals/{user_id}",
                message="Updated NEAT goals",
                metadata=update_data,
                status_code=200,
            )
        except Exception as e:
            logger.error(f"Activity logging failed: {e}", exc_info=True, extra={"user_id_full": user_id, "failed_action": "neat_goals_updated"})

        return NEATGoal(**response.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating NEAT goals: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_goals_update")


@router.post("/goals/{user_id}/calculate-progressive", response_model=ProgressiveGoalResponse, tags=["NEAT Goals"])
async def calculate_progressive_goal(
    user_id: str,
    request: ProgressiveGoalRequest,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate and optionally apply a progressive step goal.

    Analyzes the user's recent step history and suggests an adjusted goal
    based on their performance and selected strategy.
    """
    db = get_supabase_db()

    try:
        logger.info(f"Calculating progressive goal for user {user_id}")

        # Get current goal
        goal_response = db.client.table("neat_goals").select(
            "daily_step_goal"
        ).eq("user_id", user_id).maybe_single().execute()

        current_goal = goal_response.data.get("daily_step_goal", 8000) if goal_response.data else 8000

        # Get historical step data
        start_date = (user_today_date(http_request) - timedelta(days=request.look_back_days)).isoformat()
        history_response = db.client.table("daily_activity").select(
            "steps, activity_date"
        ).eq("user_id", user_id).gte("activity_date", start_date).execute()

        if not history_response.data:
            return ProgressiveGoalResponse(
                user_id=user_id,
                current_goal=current_goal,
                suggested_goal=current_goal,
                change_percentage=0,
                average_steps_achieved=0,
                goal_achievement_rate=0,
                reasoning="Not enough data to calculate progressive goal. Keep tracking!",
                applied=False,
            )

        # Calculate statistics
        steps_list = [r.get("steps", 0) for r in history_response.data]
        average_steps = sum(steps_list) / len(steps_list)
        days_met_goal = sum(1 for s in steps_list if s >= current_goal)
        achievement_rate = (days_met_goal / len(steps_list)) * 100

        # Determine adjustment based on strategy
        strategy = request.strategy or GoalAdjustmentStrategy.MODERATE

        if achievement_rate >= 80:
            # User is crushing it, increase goal
            if strategy == GoalAdjustmentStrategy.CONSERVATIVE:
                adjustment = 0.05
            elif strategy == GoalAdjustmentStrategy.MODERATE:
                adjustment = 0.10
            elif strategy == GoalAdjustmentStrategy.AGGRESSIVE:
                adjustment = 0.15
            else:  # ADAPTIVE
                adjustment = min(0.15, (achievement_rate - 80) / 100)

            suggested_goal = int(current_goal * (1 + adjustment))
            reasoning = f"Great job! You've met your goal {achievement_rate:.0f}% of days. Time to level up!"

        elif achievement_rate >= 50:
            # User is doing okay, small adjustment or maintain
            suggested_goal = current_goal
            adjustment = 0
            reasoning = f"You're meeting your goal {achievement_rate:.0f}% of days. Keep building consistency!"

        else:
            # User is struggling, consider lowering
            if strategy == GoalAdjustmentStrategy.CONSERVATIVE:
                adjustment = -0.05
            elif strategy == GoalAdjustmentStrategy.MODERATE:
                adjustment = -0.10
            else:
                adjustment = -0.10  # Don't decrease too aggressively

            suggested_goal = max(int(current_goal * (1 + adjustment)), 5000)  # Minimum 5000
            reasoning = f"Let's adjust your goal to be more achievable. You can always increase it later!"

        # Round to nearest 500
        suggested_goal = round(suggested_goal / 500) * 500
        change_percentage = ((suggested_goal - current_goal) / current_goal) * 100

        return ProgressiveGoalResponse(
            user_id=user_id,
            current_goal=current_goal,
            suggested_goal=suggested_goal,
            change_percentage=round(change_percentage, 1),
            average_steps_achieved=round(average_steps, 0),
            goal_achievement_rate=round(achievement_rate, 1),
            reasoning=reasoning,
            applied=False,
        )

    except Exception as e:
        logger.error(f"Error calculating progressive goal: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_progressive_goal")


# ============================================================================
# Hourly Activity Endpoints
# ============================================================================

@router.post("/hourly/{user_id}", response_model=HourlyActivityRecord, tags=["NEAT Hourly Activity"])
async def record_hourly_activity(
    user_id: str,
    activity: HourlyActivityInput,
    current_user: dict = Depends(get_current_user),
):
    """
    Record hourly activity data from health sync.

    Called by the mobile app after syncing with Health Connect or Apple Health.
    Uses upsert to update existing record for the same hour or create new one.
    """
    db = get_supabase_db()

    try:
        logger.info(f"Recording hourly activity for user {user_id}, hour {activity.hour}")

        # Get user's min steps per hour setting
        goal_response = db.client.table("neat_goals").select(
            "min_steps_per_hour"
        ).eq("user_id", user_id).maybe_single().execute()

        min_steps = goal_response.data.get("min_steps_per_hour", 250) if goal_response.data else 250

        # Determine if sedentary and if hourly goal was met
        was_sedentary = activity.was_sedentary if activity.was_sedentary is not None else (activity.active_minutes < 5)
        met_hourly_goal = activity.steps >= min_steps

        data = {
            "user_id": user_id,
            "activity_date": activity.activity_date.isoformat(),
            "hour": activity.hour,
            "steps": activity.steps,
            "active_minutes": activity.active_minutes,
            "distance_meters": activity.distance_meters,
            "calories": activity.calories,
            "was_sedentary": was_sedentary,
            "met_hourly_goal": met_hourly_goal,
            "source": activity.source,
            "created_at": datetime.now().isoformat(),
        }

        # Upsert based on user_id, activity_date, and hour
        response = db.client.table("neat_hourly_activity").upsert(
            data,
            on_conflict="user_id,activity_date,hour"
        ).execute()

        if not response.data:
            raise safe_internal_error(ValueError("Failed to record hourly activity"), "neat")

        return HourlyActivityRecord(**response.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error recording hourly activity: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_hourly_record")


@router.get("/hourly/{user_id}/{activity_date}", response_model=HourlyBreakdown, tags=["NEAT Hourly Activity"])
async def get_hourly_breakdown(
    user_id: str,
    activity_date: date,
    current_user: dict = Depends(get_current_user),
):
    """
    Get hourly activity breakdown for a specific date.

    Returns all hourly records with summary statistics including
    total steps, active hours, and most/least active hours.
    """
    db = get_supabase_db()

    try:
        logger.info(f"Fetching hourly breakdown for user {user_id} on {activity_date}")

        response = db.client.table("neat_hourly_activity").select("*").eq(
            "user_id", user_id
        ).eq("activity_date", activity_date.isoformat()).order("hour").execute()

        hours = [HourlyActivityRecord(**r) for r in (response.data or [])]

        # Calculate summary statistics
        total_steps = sum(h.steps for h in hours)
        total_active_minutes = sum(h.active_minutes for h in hours)
        total_calories = sum(h.calories for h in hours)
        active_hours_count = sum(1 for h in hours if h.met_hourly_goal)
        sedentary_hours_count = sum(1 for h in hours if h.was_sedentary)

        most_active_hour = None
        least_active_hour = None
        max_steps = 0
        min_steps = float('inf')

        for h in hours:
            if h.steps > max_steps:
                max_steps = h.steps
                most_active_hour = h.hour
            if h.steps < min_steps and h.steps > 0:
                min_steps = h.steps
                least_active_hour = h.hour

        hourly_average = total_steps / len(hours) if hours else 0

        return HourlyBreakdown(
            user_id=user_id,
            activity_date=activity_date,
            hours=hours,
            total_steps=total_steps,
            total_active_minutes=total_active_minutes,
            total_calories=total_calories,
            active_hours_count=active_hours_count,
            sedentary_hours_count=sedentary_hours_count,
            most_active_hour=most_active_hour,
            least_active_hour=least_active_hour if min_steps != float('inf') else None,
            hourly_average_steps=round(hourly_average, 1),
        )

    except Exception as e:
        logger.error(f"Error fetching hourly breakdown: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_hourly_breakdown")


@router.post("/hourly/{user_id}/batch", response_model=BatchHourlyActivityResponse, tags=["NEAT Hourly Activity"])
async def batch_sync_hourly_activity(
    user_id: str,
    batch: BatchHourlyActivityInput,
    current_user: dict = Depends(get_current_user),
):
    """
    Batch sync multiple hours of activity data.

    Useful for syncing historical data or multiple hours at once
    from Health Connect or Apple Health.
    """
    db = get_supabase_db()

    try:
        logger.info(f"Batch syncing {len(batch.activities)} hourly records for user {user_id}")

        # Get user's min steps per hour setting
        goal_response = db.client.table("neat_goals").select(
            "min_steps_per_hour"
        ).eq("user_id", user_id).maybe_single().execute()

        min_steps = goal_response.data.get("min_steps_per_hour", 250) if goal_response.data else 250

        results = []
        synced = 0
        failed = 0

        for activity in batch.activities:
            try:
                was_sedentary = activity.was_sedentary if activity.was_sedentary is not None else (activity.active_minutes < 5)
                met_hourly_goal = activity.steps >= min_steps

                data = {
                    "user_id": user_id,
                    "activity_date": activity.activity_date.isoformat(),
                    "hour": activity.hour,
                    "steps": activity.steps,
                    "active_minutes": activity.active_minutes,
                    "distance_meters": activity.distance_meters,
                    "calories": activity.calories,
                    "was_sedentary": was_sedentary,
                    "met_hourly_goal": met_hourly_goal,
                    "source": activity.source,
                    "created_at": datetime.now().isoformat(),
                }

                db.client.table("neat_hourly_activity").upsert(
                    data,
                    on_conflict="user_id,activity_date,hour"
                ).execute()

                results.append({
                    "date": activity.activity_date.isoformat(),
                    "hour": activity.hour,
                    "status": "success",
                })
                synced += 1

            except Exception as e:
                results.append({
                    "date": activity.activity_date.isoformat(),
                    "hour": activity.hour,
                    "status": "error",
                    "error": str(e),
                })
                failed += 1

        return BatchHourlyActivityResponse(
            synced_count=synced,
            failed_count=failed,
            results=results,
        )

    except Exception as e:
        logger.error(f"Error batch syncing hourly activity: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_hourly_batch")


# ============================================================================
# NEAT Score Endpoints
# ============================================================================

@router.get("/score/{user_id}/today", response_model=Optional[NEATScore], tags=["NEAT Score"])
async def get_today_neat_score(user_id: str,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Get today's NEAT score.

    Returns the calculated NEAT score for today if available,
    or None if not yet calculated.
    """
    db = get_supabase_db()

    try:
        today = user_today_date(request).isoformat()

        response = db.client.table("neat_scores").select("*").eq(
            "user_id", user_id
        ).eq("score_date", today).maybe_single().execute()

        if not response.data:
            return None

        data = response.data
        components = NEATScoreComponents(
            step_score=data.get("step_score", 0),
            consistency_score=data.get("consistency_score", 0),
            active_hours_score=data.get("active_hours_score", 0),
            movement_breaks_score=data.get("movement_breaks_score", 0),
        )

        return NEATScore(
            id=data.get("id"),
            user_id=data.get("user_id"),
            score_date=date.fromisoformat(data.get("score_date")),
            total_score=data.get("total_score", 0),
            components=components,
            total_steps=data.get("total_steps", 0),
            active_hours=data.get("active_hours", 0),
            movement_breaks=data.get("movement_breaks", 0),
            step_goal_met=data.get("step_goal_met", False),
            grade=data.get("grade", "C"),
            percentile=data.get("percentile"),
            message=data.get("message", ""),
            calculated_at=datetime.fromisoformat(data.get("calculated_at")),
        )

    except Exception as e:
        logger.error(f"Error fetching today's NEAT score: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_score_today")


@router.get("/score/{user_id}/history", response_model=NEATScoreHistory, tags=["NEAT Score"])
async def get_neat_score_history(
    user_id: str,
    start_date: Optional[date] = Query(None, description="Start date for history"),
    end_date: Optional[date] = Query(None, description="End date for history"),
    limit: int = Query(30, ge=1, le=365, description="Max number of records"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get NEAT score history with date range filtering.

    Returns scores with trend analysis and grade distribution.
    """
    db = get_supabase_db()

    try:
        query = db.client.table("neat_scores").select("*").eq("user_id", user_id)

        if start_date:
            query = query.gte("score_date", start_date.isoformat())
        if end_date:
            query = query.lte("score_date", end_date.isoformat())

        response = query.order("score_date", desc=True).limit(limit).execute()

        scores = []
        grade_counts: Dict[str, int] = defaultdict(int)
        total_score = 0
        highest = 0
        lowest = 100

        for data in (response.data or []):
            components = NEATScoreComponents(
                step_score=data.get("step_score", 0),
                consistency_score=data.get("consistency_score", 0),
                active_hours_score=data.get("active_hours_score", 0),
                movement_breaks_score=data.get("movement_breaks_score", 0),
            )

            score = NEATScore(
                id=data.get("id"),
                user_id=data.get("user_id"),
                score_date=date.fromisoformat(data.get("score_date")),
                total_score=data.get("total_score", 0),
                components=components,
                total_steps=data.get("total_steps", 0),
                active_hours=data.get("active_hours", 0),
                movement_breaks=data.get("movement_breaks", 0),
                step_goal_met=data.get("step_goal_met", False),
                grade=data.get("grade", "C"),
                percentile=data.get("percentile"),
                message=data.get("message", ""),
                calculated_at=datetime.fromisoformat(data.get("calculated_at")),
            )
            scores.append(score)

            grade_counts[score.grade] += 1
            total_score += score.total_score
            highest = max(highest, score.total_score)
            lowest = min(lowest, score.total_score)

        # Calculate trend
        if len(scores) >= 7:
            recent_avg = sum(s.total_score for s in scores[:7]) / 7
            older_avg = sum(s.total_score for s in scores[7:14]) / min(7, len(scores) - 7) if len(scores) > 7 else recent_avg

            if recent_avg > older_avg + 5:
                trend = "improving"
            elif recent_avg < older_avg - 5:
                trend = "declining"
            else:
                trend = "stable"
        else:
            trend = "stable"

        avg_score = total_score / len(scores) if scores else 0
        days_above_80 = sum(1 for s in scores if s.total_score >= 80)

        return NEATScoreHistory(
            user_id=user_id,
            scores=scores,
            average_score=round(avg_score, 1),
            highest_score=highest if scores else 0,
            lowest_score=lowest if scores else 0,
            trend=trend,
            total_days_tracked=len(scores),
            days_above_80=days_above_80,
            grade_distribution=dict(grade_counts),
        )

    except Exception as e:
        logger.error(f"Error fetching NEAT score history: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_score_history")


@router.post("/score/{user_id}/calculate", response_model=NEATScore, tags=["NEAT Score"])
async def calculate_neat_score(
    user_id: str,
    request: CalculateScoreRequest,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate and save today's NEAT score.

    Aggregates hourly activity data and calculates a comprehensive score
    based on steps, consistency, active hours, and movement breaks.
    """
    db = get_supabase_db()

    try:
        today = user_today_date(http_request)
        today_str = today.isoformat()

        # Check if already calculated today (unless force recalculate)
        if not request.force_recalculate:
            existing = db.client.table("neat_scores").select("id").eq(
                "user_id", user_id
            ).eq("score_date", today_str).maybe_single().execute()

            if existing.data:
                # Return existing score
                return await get_today_neat_score(user_id, http_request)

        # Get goals
        goal_response = db.client.table("neat_goals").select("*").eq(
            "user_id", user_id
        ).maybe_single().execute()

        if goal_response.data:
            step_goal = goal_response.data.get("daily_step_goal", 8000)
            active_hours_goal = goal_response.data.get("active_hours_goal", 8)
            movement_breaks_goal = goal_response.data.get("movement_breaks_goal", 6)
            min_steps_per_hour = goal_response.data.get("min_steps_per_hour", 250)
        else:
            step_goal = 8000
            active_hours_goal = 8
            movement_breaks_goal = 6
            min_steps_per_hour = 250

        # Get hourly data
        hourly_response = db.client.table("neat_hourly_activity").select("*").eq(
            "user_id", user_id
        ).eq("activity_date", today_str).order("hour").execute()

        hourly_data = hourly_response.data or []

        # Calculate metrics
        total_steps = sum(h.get("steps", 0) for h in hourly_data)
        active_hours = sum(1 for h in hourly_data if h.get("steps", 0) >= min_steps_per_hour)
        movement_breaks = sum(1 for h in hourly_data if h.get("active_minutes", 0) >= 5)

        # Calculate consistency
        hourly_steps = [h.get("steps", 0) for h in hourly_data]
        consistency = calculate_hourly_consistency(hourly_steps)

        # Calculate score
        total_score, components = calculate_neat_score(
            total_steps=total_steps,
            step_goal=step_goal,
            active_hours=active_hours,
            active_hours_goal=active_hours_goal,
            movement_breaks=movement_breaks,
            movement_breaks_goal=movement_breaks_goal,
            hourly_consistency=consistency,
        )

        step_goal_met = total_steps >= step_goal
        grade = score_to_grade(total_score)
        message = get_score_message(total_score, step_goal_met)

        # Save score
        score_data = {
            "user_id": user_id,
            "score_date": today_str,
            "total_score": total_score,
            "step_score": components.step_score,
            "consistency_score": components.consistency_score,
            "active_hours_score": components.active_hours_score,
            "movement_breaks_score": components.movement_breaks_score,
            "total_steps": total_steps,
            "active_hours": active_hours,
            "movement_breaks": movement_breaks,
            "step_goal_met": step_goal_met,
            "grade": grade,
            "message": message,
            "calculated_at": datetime.now().isoformat(),
        }

        response = db.client.table("neat_scores").upsert(
            score_data,
            on_conflict="user_id,score_date"
        ).execute()

        if not response.data:
            raise safe_internal_error(ValueError("Failed to save NEAT score"), "neat")

        return NEATScore(
            id=response.data[0].get("id"),
            user_id=user_id,
            score_date=today,
            total_score=total_score,
            components=components,
            total_steps=total_steps,
            active_hours=active_hours,
            movement_breaks=movement_breaks,
            step_goal_met=step_goal_met,
            grade=grade,
            message=message,
            calculated_at=datetime.now(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error calculating NEAT score: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_score_calculate")


# ============================================================================
# Streaks Endpoints
# ============================================================================

@router.get("/streaks/{user_id}", response_model=StreaksResponse, tags=["NEAT Streaks"])
async def get_neat_streaks(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all NEAT streak types for a user.

    Returns current and longest streaks for step goals, active hours,
    movement breaks, and NEAT scores.
    """
    db = get_supabase_db()

    try:
        response = db.client.table("neat_streaks").select("*").eq(
            "user_id", user_id
        ).execute()

        streaks = [NEATStreak(**s) for s in (response.data or [])]

        # Find best overall streak
        best_streak = None
        max_length = 0
        for s in streaks:
            if s.current_length > max_length:
                max_length = s.current_length
                best_streak = s

        active_count = sum(1 for s in streaks if s.is_active and s.current_length > 0)

        return StreaksResponse(
            user_id=user_id,
            streaks=streaks,
            best_overall_streak=best_streak,
            total_active_streaks=active_count,
        )

    except Exception as e:
        logger.error(f"Error fetching NEAT streaks: {e}", exc_info=True)
        raise safe_internal_error(e, "neat_streaks")



# Include secondary endpoints
router.include_router(_endpoints_router)
