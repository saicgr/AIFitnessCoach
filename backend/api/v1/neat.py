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

from datetime import datetime, date, time, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from core.auth import get_current_user
from core.exceptions import safe_internal_error
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
            goal = NEATGoal(**insert_response.data[0])

        # Get today's activity
        today = date.today().isoformat()
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
        logger.error(f"Error fetching NEAT goals: {e}")
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
        await log_user_activity(
            user_id=user_id,
            action="neat_goals_updated",
            endpoint=f"/api/v1/neat/goals/{user_id}",
            message="Updated NEAT goals",
            metadata=update_data,
            status_code=200,
        )

        return NEATGoal(**response.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating NEAT goals: {e}")
        raise safe_internal_error(e, "neat_goals_update")


@router.post("/goals/{user_id}/calculate-progressive", response_model=ProgressiveGoalResponse, tags=["NEAT Goals"])
async def calculate_progressive_goal(
    user_id: str,
    request: ProgressiveGoalRequest,
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
        start_date = (date.today() - timedelta(days=request.look_back_days)).isoformat()
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
        logger.error(f"Error calculating progressive goal: {e}")
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
            raise HTTPException(status_code=500, detail="Failed to record hourly activity")

        return HourlyActivityRecord(**response.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error recording hourly activity: {e}")
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
        logger.error(f"Error fetching hourly breakdown: {e}")
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
        logger.error(f"Error batch syncing hourly activity: {e}")
        raise safe_internal_error(e, "neat_hourly_batch")


# ============================================================================
# NEAT Score Endpoints
# ============================================================================

@router.get("/score/{user_id}/today", response_model=Optional[NEATScore], tags=["NEAT Score"])
async def get_today_neat_score(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get today's NEAT score.

    Returns the calculated NEAT score for today if available,
    or None if not yet calculated.
    """
    db = get_supabase_db()

    try:
        today = date.today().isoformat()

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
        logger.error(f"Error fetching today's NEAT score: {e}")
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
        logger.error(f"Error fetching NEAT score history: {e}")
        raise safe_internal_error(e, "neat_score_history")


@router.post("/score/{user_id}/calculate", response_model=NEATScore, tags=["NEAT Score"])
async def calculate_neat_score(
    user_id: str,
    request: CalculateScoreRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate and save today's NEAT score.

    Aggregates hourly activity data and calculates a comprehensive score
    based on steps, consistency, active hours, and movement breaks.
    """
    db = get_supabase_db()

    try:
        today = date.today()
        today_str = today.isoformat()

        # Check if already calculated today (unless force recalculate)
        if not request.force_recalculate:
            existing = db.client.table("neat_scores").select("id").eq(
                "user_id", user_id
            ).eq("score_date", today_str).maybe_single().execute()

            if existing.data:
                # Return existing score
                return await get_today_neat_score(user_id)

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
            raise HTTPException(status_code=500, detail="Failed to save NEAT score")

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
        logger.error(f"Error calculating NEAT score: {e}")
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
        logger.error(f"Error fetching NEAT streaks: {e}")
        raise safe_internal_error(e, "neat_streaks")


@router.get("/streaks/{user_id}/summary", response_model=StreakSummary, tags=["NEAT Streaks"])
async def get_streak_summary(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get a compact streak summary for display.

    Returns current streak values for each type and identifies
    the best performing streak.
    """
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
        logger.error(f"Error fetching streak summary: {e}")
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
        logger.error(f"Error fetching NEAT achievements: {e}")
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
        logger.error(f"Error fetching available achievements: {e}")
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
        logger.error(f"Error checking NEAT achievements: {e}")
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
        logger.error(f"Error fetching reminder preferences: {e}")
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
        logger.error(f"Error updating reminder preferences: {e}")
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
        logger.error(f"Error checking should remind: {e}")
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
        logger.error(f"Error fetching NEAT dashboard: {e}")
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
                    # TODO: Send push notification
                    # await notification_service.send_push(user_id, {
                    #     "title": "Time to Move!",
                    #     "body": should_remind.suggested_message,
                    #     "data": {"type": "neat_reminder"}
                    # })
                    pass

                reminders_sent += 1

            except Exception as e:
                logger.error(f"Error processing reminder for user {user_id}: {e}")
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
        logger.error(f"Error in movement reminder scheduler: {e}")
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

                # TODO: Update streaks based on score
                # This would check if goals were met and update streak counts

            except Exception as e:
                logger.error(f"Error calculating score for user {user_id}: {e}")
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
        logger.error(f"Error in daily score calculator: {e}")
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
                logger.error(f"Error adjusting goal for user {user_id}: {e}")

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
        logger.error(f"Error in weekly goal adjustment: {e}")
        raise safe_internal_error(e, "neat_weekly_goals")
