"""
Daily Schedule Planner Models.

Pydantic models for the daily schedule system that combines workouts,
activities, meals, fasting windows, and habits into a unified timeline.

Supports:
- Schedule item CRUD (create, read, update, delete)
- Daily schedule with summary stats
- Up-next upcoming items view
- Auto-population from existing workouts, habits, and fasting records
- Google Calendar integration (OAuth, busy times, event push)
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import date, datetime
from enum import Enum
from uuid import UUID


# ============================================================================
# Enums
# ============================================================================

class ScheduleItemType(str, Enum):
    """Type of schedule item."""
    WORKOUT = "workout"
    ACTIVITY = "activity"
    MEAL = "meal"
    FASTING = "fasting"
    HABIT = "habit"


class ScheduleItemStatus(str, Enum):
    """Status of a schedule item."""
    SCHEDULED = "scheduled"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    SKIPPED = "skipped"
    MISSED = "missed"


class MealType(str, Enum):
    """Type of meal for meal schedule items."""
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACK = "snack"


# ============================================================================
# Request Models
# ============================================================================

class ScheduleItemCreate(BaseModel):
    """Request to create a new schedule item."""
    title: str = Field(..., min_length=1, max_length=255, description="Title of the schedule item")
    item_type: ScheduleItemType = Field(..., description="Type of schedule item")
    scheduled_date: date = Field(..., description="Date the item is scheduled for")
    start_time: str = Field(..., max_length=5, description="Start time in HH:MM format")
    end_time: Optional[str] = Field(None, max_length=5, description="End time in HH:MM format")
    duration_minutes: Optional[int] = Field(None, ge=1, le=1440, description="Duration in minutes")
    description: Optional[str] = Field(None, max_length=1000, description="Optional description")
    workout_id: Optional[UUID] = Field(None, description="Linked workout ID")
    habit_id: Optional[UUID] = Field(None, description="Linked habit ID")
    fasting_record_id: Optional[UUID] = Field(None, description="Linked fasting record ID")
    activity_type: Optional[str] = Field(None, max_length=100, description="Activity type (e.g., 'walking', 'yoga')")
    activity_target: Optional[str] = Field(None, max_length=255, description="Activity target (e.g., '10000 steps')")
    activity_icon: Optional[str] = Field(None, max_length=100, description="Icon name for activity display")
    activity_color: Optional[str] = Field(None, max_length=20, description="Hex color code for activity")
    meal_type: Optional[MealType] = Field(None, description="Type of meal if item_type is meal")
    is_recurring: bool = Field(default=False, description="Whether this item recurs")
    recurrence_rule: Optional[str] = Field(None, max_length=500, description="RRULE string for recurrence")
    notify_before_minutes: int = Field(default=15, ge=0, le=1440, description="Minutes before to send notification")
    sync_to_google_calendar: bool = Field(default=False, description="Whether to sync to Google Calendar")

    class Config:
        use_enum_values = True


class ScheduleItemUpdate(BaseModel):
    """Request to update an existing schedule item. All fields optional."""
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    item_type: Optional[ScheduleItemType] = None
    scheduled_date: Optional[date] = None
    start_time: Optional[str] = Field(None, max_length=5)
    end_time: Optional[str] = Field(None, max_length=5)
    duration_minutes: Optional[int] = Field(None, ge=1, le=1440)
    description: Optional[str] = Field(None, max_length=1000)
    workout_id: Optional[UUID] = None
    habit_id: Optional[UUID] = None
    fasting_record_id: Optional[UUID] = None
    activity_type: Optional[str] = Field(None, max_length=100)
    activity_target: Optional[str] = Field(None, max_length=255)
    activity_icon: Optional[str] = Field(None, max_length=100)
    activity_color: Optional[str] = Field(None, max_length=20)
    meal_type: Optional[MealType] = None
    is_recurring: Optional[bool] = None
    recurrence_rule: Optional[str] = Field(None, max_length=500)
    notify_before_minutes: Optional[int] = Field(None, ge=0, le=1440)
    sync_to_google_calendar: Optional[bool] = None
    status: Optional[ScheduleItemStatus] = None

    class Config:
        use_enum_values = True


class AutoPopulateRequest(BaseModel):
    """Request to auto-populate schedule items from existing data."""
    date: date = Field(..., description="Date to populate items for")
    include_workouts: bool = Field(default=True, description="Include scheduled workouts")
    include_habits: bool = Field(default=True, description="Include active habits")
    include_fasting: bool = Field(default=True, description="Include active fasting schedules")


class GoogleCalendarConnectRequest(BaseModel):
    """Request to connect Google Calendar via OAuth."""
    user_id: str = Field(..., description="User ID")
    auth_code: str = Field(..., description="OAuth authorization code from Google")
    calendar_id: Optional[str] = Field(None, description="Specific calendar ID to use (default: primary)")


class GoogleCalendarPushRequest(BaseModel):
    """Request to push a schedule item to Google Calendar."""
    item_id: UUID = Field(..., description="Schedule item ID to push")


# ============================================================================
# Response Models
# ============================================================================

class ScheduleItemResponse(BaseModel):
    """Complete schedule item record from database."""
    id: UUID
    user_id: str
    title: str
    item_type: ScheduleItemType
    scheduled_date: date
    start_time: str
    end_time: Optional[str] = None
    duration_minutes: Optional[int] = None
    description: Optional[str] = None
    status: ScheduleItemStatus = ScheduleItemStatus.SCHEDULED
    workout_id: Optional[UUID] = None
    habit_id: Optional[UUID] = None
    fasting_record_id: Optional[UUID] = None
    activity_type: Optional[str] = None
    activity_target: Optional[str] = None
    activity_icon: Optional[str] = None
    activity_color: Optional[str] = None
    meal_type: Optional[MealType] = None
    is_recurring: bool = False
    recurrence_rule: Optional[str] = None
    notify_before_minutes: int = 15
    sync_to_google_calendar: bool = False
    google_calendar_event_id: Optional[str] = None
    google_calendar_synced_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
        use_enum_values = True


class DailyScheduleResponse(BaseModel):
    """Full daily schedule with items and summary."""
    date: date
    items: List[ScheduleItemResponse] = Field(default_factory=list)
    summary: Dict[str, int] = Field(
        default_factory=lambda: {"total_items": 0, "completed": 0, "upcoming": 0},
        description="Summary counts: total_items, completed, upcoming"
    )


class UpNextResponse(BaseModel):
    """Response containing upcoming schedule items."""
    items: List[ScheduleItemResponse] = Field(default_factory=list)
    as_of: datetime = Field(..., description="Timestamp of the query")


class GoogleCalendarBusyTime(BaseModel):
    """A busy time block from Google Calendar."""
    start: datetime = Field(..., description="Start of busy period")
    end: datetime = Field(..., description="End of busy period")
    summary: Optional[str] = Field(None, description="Event summary if available")
