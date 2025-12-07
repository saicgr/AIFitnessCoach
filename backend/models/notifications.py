"""Notification and summary Pydantic models."""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class WeeklySummaryCreate(BaseModel):
    """Request to generate a weekly summary."""
    user_id: str
    week_start: str  # ISO date string


class WeeklySummary(BaseModel):
    """Weekly workout summary with AI-generated content."""
    id: str
    user_id: str
    week_start: str
    week_end: str

    # Stats
    workouts_completed: int = 0
    workouts_scheduled: int = 0
    total_exercises: int = 0
    total_sets: int = 0
    total_time_minutes: int = 0
    calories_burned_estimate: int = 0

    # Streak info
    current_streak: int = 0
    streak_status: Optional[str] = None  # 'growing', 'maintained', 'broken'

    # PRs
    prs_achieved: int = 0
    pr_details: Optional[List[dict]] = None

    # AI-generated content
    ai_summary: Optional[str] = None
    ai_highlights: Optional[List[str]] = None
    ai_encouragement: Optional[str] = None
    ai_next_week_tips: Optional[List[str]] = None
    ai_generated_at: Optional[datetime] = None

    # Notification status
    email_sent: bool = False
    push_sent: bool = False

    created_at: datetime


class NotificationPreferences(BaseModel):
    """User notification preferences."""
    id: Optional[str] = None
    user_id: str

    # Weekly summary
    weekly_summary_enabled: bool = True
    weekly_summary_day: str = "sunday"
    weekly_summary_time: str = "09:00"

    # Email notifications
    email_notifications_enabled: bool = True
    email_workout_reminders: bool = True
    email_achievement_alerts: bool = True
    email_weekly_summary: bool = True
    email_motivation_messages: bool = False

    # Push notifications
    push_notifications_enabled: bool = False
    push_workout_reminders: bool = True
    push_achievement_alerts: bool = True
    push_weekly_summary: bool = False
    push_hydration_reminders: bool = False

    # Timing
    quiet_hours_start: str = "22:00"
    quiet_hours_end: str = "07:00"
    timezone: str = "America/New_York"


class NotificationPreferencesUpdate(BaseModel):
    """Update notification preferences."""
    weekly_summary_enabled: Optional[bool] = None
    weekly_summary_day: Optional[str] = None
    weekly_summary_time: Optional[str] = None
    email_notifications_enabled: Optional[bool] = None
    email_workout_reminders: Optional[bool] = None
    email_achievement_alerts: Optional[bool] = None
    email_weekly_summary: Optional[bool] = None
    email_motivation_messages: Optional[bool] = None
    push_notifications_enabled: Optional[bool] = None
    push_workout_reminders: Optional[bool] = None
    push_achievement_alerts: Optional[bool] = None
    push_weekly_summary: Optional[bool] = None
    push_hydration_reminders: Optional[bool] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    timezone: Optional[str] = None
