"""Scheduled recipe log models — recurring + batch (cook-once-eat-many)."""

from datetime import date, datetime, time
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field, model_validator


class ScheduleMode(str, Enum):
    RECURRING = "recurring"
    BATCH = "batch"


class ScheduleKind(str, Enum):
    DAILY = "daily"
    WEEKDAYS = "weekdays"
    WEEKENDS = "weekends"
    CUSTOM = "custom"


class MealType(str, Enum):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACK = "snack"


class BatchSlot(BaseModel):
    """One scheduled fire in a batch schedule."""
    local_date: date  # day to fire on, in user-local terms
    meal_type: MealType
    local_time: time
    servings: float = Field(default=1.0, gt=0, le=20)


class ScheduledRecipeLogCreate(BaseModel):
    """Create a recurring or batch schedule. Validates mode-specific fields."""
    recipe_id: str
    schedule_mode: ScheduleMode = ScheduleMode.RECURRING
    meal_type: MealType
    servings: float = Field(default=1.0, gt=0, le=20)
    timezone: str = Field(..., min_length=1, max_length=64)
    silent_log: bool = False

    # Recurring
    schedule_kind: Optional[ScheduleKind] = None
    days_of_week: Optional[List[int]] = Field(default=None, max_length=7)
    local_time: Optional[time] = None

    # Batch
    cook_event_id: Optional[str] = None
    batch_slots: Optional[List[BatchSlot]] = None

    @model_validator(mode="after")
    def _validate_mode(self):
        if self.schedule_mode == ScheduleMode.RECURRING:
            if self.schedule_kind is None or self.local_time is None:
                raise ValueError("recurring schedules need schedule_kind + local_time")
            if self.schedule_kind == ScheduleKind.CUSTOM and not self.days_of_week:
                raise ValueError("custom schedule_kind requires days_of_week")
            if self.days_of_week is not None and any(d < 0 or d > 6 for d in self.days_of_week):
                raise ValueError("days_of_week must be 0..6 (Sun..Sat)")
        else:  # BATCH
            if not self.batch_slots:
                raise ValueError("batch schedules need at least one slot")
            if self.cook_event_id is None:
                raise ValueError("batch schedules need a cook_event_id")
        return self


class ScheduledRecipeLogUpdate(BaseModel):
    enabled: Optional[bool] = None
    paused_until: Optional[date] = None
    servings: Optional[float] = Field(default=None, gt=0, le=20)
    silent_log: Optional[bool] = None
    local_time: Optional[time] = None
    days_of_week: Optional[List[int]] = None
    schedule_kind: Optional[ScheduleKind] = None
    batch_slots: Optional[List[BatchSlot]] = None


class ScheduledRecipeLog(BaseModel):
    id: str
    user_id: str
    recipe_id: Optional[str] = None
    schedule_mode: ScheduleMode
    meal_type: MealType
    servings: float
    schedule_kind: Optional[ScheduleKind] = None
    days_of_week: Optional[List[int]] = None
    local_time: Optional[time] = None
    timezone: str
    next_fire_at: datetime
    last_fired_at: Optional[datetime] = None
    cook_event_id: Optional[str] = None
    batch_slots: Optional[List[BatchSlot]] = None
    next_slot_index: int = 0
    paused_until: Optional[date] = None
    enabled: bool = True
    silent_log: bool = False
    created_at: datetime
    updated_at: datetime


class ScheduledRecipeLogsResponse(BaseModel):
    items: List[ScheduledRecipeLog]
    total_count: int


class UpcomingScheduledFire(BaseModel):
    """Compact view used by 'Coming up today' carousel."""
    schedule_id: str
    recipe_id: Optional[str] = None
    recipe_name: Optional[str] = None
    recipe_image_url: Optional[str] = None
    meal_type: MealType
    servings: float
    fire_at: datetime
    schedule_mode: ScheduleMode
    is_batch_last_slot: bool = False
