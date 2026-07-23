"""
Pydantic models for saved and scheduled workouts.

Features:
- Save workouts from social feed
- Schedule workouts for future dates
- Track workout sharing metrics
"""

import re

from pydantic import BaseModel, Field, model_validator
from typing import Optional, List, Dict, Any
from datetime import datetime, date as date_type, time as time_type
from enum import Enum


# ============================================================
# REAL-WORLD SHAPE NORMALIZERS
# ============================================================
# The same exercise JSONB is written by several producers (the workout studio,
# the from-workout save path, and the share-funnel importer, which forwards the
# raw Flutter shape). Those producers do NOT agree on scalar types:
#   • reps arrives as an int (8), a range STRING ("8-12"), a single-number
#     string ("8"), a per-side string ("12 each side"), or null (timed holds).
#   • equipment arrives as a str ("dumbbell") OR a LIST (["dumbbell", "bench"]).
# ExerciseTemplate is the single read-back type (SavedWorkout(**row) coerces the
# JSONB into it), so ONE mismatched scalar 500s the whole GET. These helpers +
# the model_validator below coerce every shape into the canonical scalar the
# model declares, WITHOUT losing information (the original rep range is kept in
# reps_display; equipment items are joined, not dropped).


def _parse_reps(raw: str) -> tuple[Optional[int], Optional[str]]:
    """(canonical_int, lossless_display) for a rep string.

    Canonical int = the TOP of a range, so progression targets the harder end
    (a "8-12" set advances toward 12). Returns a display string ONLY when the
    original text carries information the int cannot (a range, a per-side note,
    or a non-numeric cue like "AMRAP"); a plain "8" needs no display because the
    int fully captures it. Never raises: unparseable text yields (None, text) so
    reps honestly reads "unknown" while the original is still shown.
    """
    s = raw.strip()
    if not s:
        return None, None
    if re.fullmatch(r"\d+", s):
        return int(s), None
    m = re.fullmatch(r"(\d+)\s*(?:-|–|—|to)\s*(\d+)", s, flags=re.IGNORECASE)
    if m:
        return max(int(m.group(1)), int(m.group(2))), s
    lead = re.match(r"(\d+)", s)
    if lead:
        return int(lead.group(1)), s
    return None, s


def _canonical_equipment(items) -> Optional[str]:
    """A list of equipment -> one canonical string, losslessly joined. Falls
    back to the first item (never a 500) if the join would exceed the column
    width; returns None for an empty/blank list."""
    parts = [str(x).strip() for x in items if x is not None and str(x).strip()]
    if not parts:
        return None
    joined = ", ".join(parts)
    if len(joined) <= 100:
        return joined
    return parts[0][:100]


# ============================================================
# ENUMS
# ============================================================

class DifficultyLevel(str, Enum):
    """Workout difficulty levels."""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class ScheduledWorkoutStatus(str, Enum):
    """Status of scheduled workouts."""
    SCHEDULED = "scheduled"
    COMPLETED = "completed"
    SKIPPED = "skipped"
    RESCHEDULED = "rescheduled"


# ============================================================
# EXERCISE MODELS
# ============================================================

class SetTargetTemplate(BaseModel):
    """Per-set AI target preserved in a saved workout."""
    set_number: int
    set_type: str = "working"  # warmup | working | drop | failure | amrap
    target_reps: Optional[int] = None
    target_weight_kg: Optional[float] = None
    target_hold_seconds: Optional[int] = None
    target_rpe: Optional[int] = None
    target_rir: Optional[int] = None


class ExerciseTemplate(BaseModel):
    """Template for an exercise in a saved workout.

    Lossless snapshot of a generated/live workout exercise. reps & weight are
    optional because timed holds (planks, wall sits) and bodyweight moves have
    neither; duration/hold/set_targets/superset/drop-set + media are preserved
    so the saved copy renders and runs exactly like the original. (Without this
    a plank/AMRAP/superset workout would be silently corrupted on save.)

    Shape tolerance: producers send reps as an int, a range string ("8-12"), a
    single-number string, or null, and equipment as a str or a list. The
    model_validator below coerces those into the canonical scalars WITHOUT loss
    — reps becomes the top of the range while reps_display keeps the original
    "8-12" so the range still renders. This is a model_validator(mode="before")
    rather than a pair of field_validators because deriving reps_display from
    reps is a cross-field move; it still runs on EVERY construction path (import,
    from-workout, read-back), which is the whole point — the chokepoint is the
    model, not any one call site.
    """
    name: str = Field(..., max_length=200)
    sets: int = Field(default=1, ge=1, le=20)
    reps: Optional[int] = Field(default=None, ge=0, le=1000)
    # Original rep text when reps alone can't express it (ranges, per-side,
    # "AMRAP"). None when reps is an exact integer that needs no gloss.
    reps_display: Optional[str] = Field(default=None, max_length=100)
    weight_kg: Optional[float] = Field(default=None, ge=0, le=1000)
    rest_seconds: Optional[int] = Field(default=60, ge=0, le=600)
    duration_seconds: Optional[int] = Field(default=None, ge=0, le=7200)
    hold_seconds: Optional[int] = Field(default=None, ge=0, le=3600)
    notes: Optional[str] = Field(default=None, max_length=500)
    muscle_group: Optional[str] = Field(default=None, max_length=100)
    equipment: Optional[str] = Field(default=None, max_length=100)
    # Structure
    superset_group: Optional[int] = None
    superset_order: Optional[int] = None
    is_unilateral: Optional[bool] = None
    is_timed: Optional[bool] = None
    is_amrap: Optional[bool] = None
    is_drop_set: Optional[bool] = None
    drop_set_count: Optional[int] = None
    drop_set_percentage: Optional[int] = None
    set_targets: Optional[List[SetTargetTemplate]] = None
    # Media so the saved copy shows thumbnails/video
    gif_url: Optional[str] = Field(default=None, max_length=1000)
    video_url: Optional[str] = Field(default=None, max_length=1000)
    image_url: Optional[str] = Field(default=None, max_length=1000)
    library_id: Optional[str] = Field(default=None, max_length=100)

    @model_validator(mode="before")
    @classmethod
    def _normalize_real_world_shapes(cls, data):
        """Coerce reps (int|range-str|null) and equipment (str|list) into the
        canonical scalars this model declares, before field validation runs, on
        every construction path. Lossless: a rep range is preserved in
        reps_display; equipment list items are joined, not dropped."""
        if not isinstance(data, dict):
            return data
        data = dict(data)  # never mutate the caller's dict

        raw_reps = data.get("reps")
        if isinstance(raw_reps, str):
            canonical, display = _parse_reps(raw_reps)
            data["reps"] = canonical
            # Don't clobber an explicit reps_display the producer already set.
            if display is not None and not data.get("reps_display"):
                data["reps_display"] = display

        raw_equip = data.get("equipment")
        if isinstance(raw_equip, (list, tuple)):
            data["equipment"] = _canonical_equipment(raw_equip)

        return data


# ============================================================
# SAVED WORKOUTS
# ============================================================

class SavedWorkoutBase(BaseModel):
    """Base model for saved workouts."""
    workout_name: str = Field(..., max_length=200)
    workout_description: Optional[str] = Field(default=None, max_length=2000)
    exercises: List[ExerciseTemplate] = Field(..., max_length=50)
    total_exercises: int = Field(..., ge=0, le=100)
    estimated_duration_minutes: Optional[int] = Field(default=None, ge=1, le=480)
    difficulty_level: Optional[DifficultyLevel] = None
    folder: Optional[str] = Field(default="Favorites", max_length=100)
    tags: List[str] = Field(default_factory=list, max_length=20)
    notes: Optional[str] = Field(default=None, max_length=2000)


class SavedWorkoutCreate(SavedWorkoutBase):
    """Create a saved workout."""
    source_activity_id: Optional[str] = Field(default=None, max_length=100)
    source_user_id: Optional[str] = Field(default=None, max_length=100)


class SavedWorkout(SavedWorkoutBase):
    """Saved workout from database."""
    id: str
    user_id: str
    source_activity_id: Optional[str] = None
    source_user_id: Optional[str] = None
    times_completed: int = 0
    last_completed_at: Optional[datetime] = None
    saved_at: datetime
    updated_at: datetime

    # Optional joined data
    source_user_name: Optional[str] = None
    source_user_avatar: Optional[str] = None

    class Config:
        from_attributes = True


class SavedWorkoutUpdate(BaseModel):
    """Update a saved workout."""
    workout_name: Optional[str] = Field(default=None, max_length=200)
    workout_description: Optional[str] = Field(default=None, max_length=2000)
    folder: Optional[str] = Field(default=None, max_length=100)
    tags: Optional[List[str]] = Field(default=None, max_length=20)
    notes: Optional[str] = Field(default=None, max_length=2000)


class SavedWorkoutsResponse(BaseModel):
    """Paginated response for saved workouts."""
    workouts: List[SavedWorkout]
    total_count: int
    folders: List[str]  # List of unique folders


# ============================================================
# SCHEDULED WORKOUTS
# ============================================================

class ScheduledWorkoutBase(BaseModel):
    """Base model for scheduled workouts."""
    scheduled_date: date_type
    scheduled_time: Optional[time_type] = None
    workout_name: str = Field(..., max_length=200)
    exercises: List[ExerciseTemplate] = Field(..., max_length=50)
    reminder_enabled: bool = True
    reminder_minutes_before: int = Field(default=60, ge=0, le=1440)
    notes: Optional[str] = Field(default=None, max_length=2000)


class ScheduledWorkoutCreate(ScheduledWorkoutBase):
    """Create a scheduled workout."""
    saved_workout_id: Optional[str] = Field(default=None, max_length=100)
    workout_id: Optional[str] = Field(default=None, max_length=100)


class ScheduledWorkout(ScheduledWorkoutBase):
    """Scheduled workout from database."""
    id: str
    user_id: str
    saved_workout_id: Optional[str] = None
    workout_id: Optional[str] = None
    status: ScheduledWorkoutStatus
    completed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ScheduledWorkoutUpdate(BaseModel):
    """Update a scheduled workout."""
    scheduled_date: Optional[date_type] = None
    scheduled_time: Optional[time_type] = None
    status: Optional[ScheduledWorkoutStatus] = None
    reminder_enabled: Optional[bool] = None
    reminder_minutes_before: Optional[int] = Field(default=None, ge=0, le=1440)
    notes: Optional[str] = Field(default=None, max_length=2000)


class ScheduledWorkoutsResponse(BaseModel):
    """Response for scheduled workouts."""
    scheduled: List[ScheduledWorkout]
    total_count: int


# ============================================================
# WORKOUT SHARES
# ============================================================

class WorkoutShare(BaseModel):
    """Workout sharing metrics."""
    id: str
    shared_by: str
    workout_log_id: Optional[str] = None
    activity_id: Optional[str] = None
    share_count: int = 0
    completion_count: int = 0
    average_rating: Optional[float] = None
    is_public: bool = False
    created_at: datetime

    # Optional joined data
    creator_name: Optional[str] = None
    creator_avatar: Optional[str] = None
    activity_data: Optional[Dict[str, Any]] = None

    class Config:
        from_attributes = True


class PopularWorkout(BaseModel):
    """Popular shared workout."""
    id: str
    workout_name: str
    creator_name: str
    creator_avatar: Optional[str] = None
    exercises: List[ExerciseTemplate]
    share_count: int
    completion_count: int
    average_rating: Optional[float] = None
    difficulty_level: Optional[DifficultyLevel] = None


# ============================================================
# ACTIONS
# ============================================================

class SaveWorkoutFromActivity(BaseModel):
    """Request to save a workout from an activity."""
    activity_id: str = Field(..., max_length=100)
    folder: Optional[str] = Field(default="From Friends", max_length=100)
    notes: Optional[str] = Field(default=None, max_length=2000)


class DoWorkoutNow(BaseModel):
    """Request to start a saved workout now."""
    saved_workout_id: str = Field(..., max_length=100)
    # Will create a workout session and navigate to ActiveWorkoutScreen


class ScheduleWorkoutRequest(BaseModel):
    """Request to schedule a workout."""
    saved_workout_id: Optional[str] = Field(default=None, max_length=100)
    activity_id: Optional[str] = Field(default=None, max_length=100)  # Can schedule directly from activity
    scheduled_date: date_type
    scheduled_time: Optional[time_type] = None
    reminder_enabled: bool = True
    reminder_minutes_before: int = Field(default=60, ge=0, le=1440)
    notes: Optional[str] = Field(default=None, max_length=2000)


# ============================================================
# CALENDAR VIEW
# ============================================================

class CalendarWorkout(BaseModel):
    """Simplified workout for calendar view."""
    id: str
    date: date_type
    time: Optional[time_type] = None
    name: str
    status: ScheduledWorkoutStatus
    exercise_count: int
    estimated_duration: Optional[int] = None


class MonthlyCalendar(BaseModel):
    """Calendar view for a month."""
    year: int
    month: int
    workouts: List[CalendarWorkout]
    total_scheduled: int
    total_completed: int
