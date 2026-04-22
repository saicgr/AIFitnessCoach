"""
Response models for workout CRUD operations.

Extracted from crud.py to keep files under 1000 lines.
"""
from datetime import datetime
from typing import List, Optional, Dict, Any

from pydantic import BaseModel

from models.schemas import Workout


class PersonalRecordInfo(BaseModel):
    """PR info returned after workout completion."""
    exercise_name: str
    weight_kg: float
    reps: int
    estimated_1rm_kg: float
    previous_1rm_kg: Optional[float] = None
    improvement_kg: Optional[float] = None
    improvement_percent: Optional[float] = None
    is_all_time_pr: bool = True
    celebration_message: Optional[str] = None


class ExerciseComparisonInfo(BaseModel):
    """Comparison data for a single exercise vs previous session."""
    exercise_name: str
    exercise_id: Optional[str] = None

    # Current session
    current_sets: int = 0
    current_reps: int = 0
    current_volume_kg: float = 0.0
    current_max_weight_kg: Optional[float] = None
    current_1rm_kg: Optional[float] = None
    current_time_seconds: Optional[int] = None

    # Previous session
    previous_sets: Optional[int] = None
    previous_reps: Optional[int] = None
    previous_volume_kg: Optional[float] = None
    previous_max_weight_kg: Optional[float] = None
    previous_1rm_kg: Optional[float] = None
    previous_time_seconds: Optional[int] = None
    previous_date: Optional[datetime] = None

    # Differences
    volume_diff_kg: Optional[float] = None
    volume_diff_percent: Optional[float] = None
    weight_diff_kg: Optional[float] = None
    weight_diff_percent: Optional[float] = None
    rm_diff_kg: Optional[float] = None
    rm_diff_percent: Optional[float] = None
    time_diff_seconds: Optional[int] = None
    time_diff_percent: Optional[float] = None
    reps_diff: Optional[int] = None
    sets_diff: Optional[int] = None

    # Status: 'improved', 'maintained', 'declined', 'first_time'
    status: str = 'first_time'


class WorkoutComparisonInfo(BaseModel):
    """Comparison data for overall workout vs previous similar workout."""
    # Current workout
    current_duration_seconds: int = 0
    current_total_volume_kg: float = 0.0
    current_total_sets: int = 0
    current_total_reps: int = 0
    current_exercises: int = 0
    current_calories: int = 0

    # Previous workout
    has_previous: bool = False
    previous_duration_seconds: Optional[int] = None
    previous_total_volume_kg: Optional[float] = None
    previous_total_sets: Optional[int] = None
    previous_total_reps: Optional[int] = None
    previous_performed_at: Optional[datetime] = None

    # Differences
    duration_diff_seconds: Optional[int] = None
    duration_diff_percent: Optional[float] = None
    volume_diff_kg: Optional[float] = None
    volume_diff_percent: Optional[float] = None

    # Overall status
    overall_status: str = 'first_time'


class PerformanceComparisonInfo(BaseModel):
    """Complete performance comparison for workout completion."""
    workout_comparison: WorkoutComparisonInfo
    exercise_comparisons: List[ExerciseComparisonInfo] = []
    improved_count: int = 0
    maintained_count: int = 0
    declined_count: int = 0
    first_time_count: int = 0


class WorkoutCompletionResponse(BaseModel):
    """Extended response for workout completion including PRs and performance comparison."""
    workout: Workout
    personal_records: List[PersonalRecordInfo] = []
    performance_comparison: Optional[PerformanceComparisonInfo] = None
    strength_scores_updated: bool = False
    fitness_score_updated: bool = False
    completion_method: str = "tracked"
    message: str = "Workout completed successfully"
    # Workstream 1 (Day 0-7 retention): triggers the First Workout Forecast
    # sheet on the frontend when true. Set to True when the user's
    # users.first_workout_completed_at was NULL before this completion.
    is_first_workout: bool = False
    # Server-side XP award guarantee (fixes the "completed workout but 0
    # weekly XP" leaderboard bug). The server now awards the daily
    # workout_complete XP inline on completion instead of depending on
    # the client to call /xp/award-goal-xp. xp_awarded=True means the
    # transaction was inserted on this request; =False means dedup
    # (already claimed today) or a non-fatal error. Client treats this
    # as authoritative — no need to duplicate the award call when True.
    xp_awarded: bool = False
    xp_amount: int = 0


class SetLogInfo(BaseModel):
    """Per-set log data for workout summary display."""
    exercise_name: str
    exercise_index: int = 0
    set_number: int
    reps_completed: int
    weight_kg: float
    rpe: Optional[float] = None
    rir: Optional[int] = None
    set_type: str = "working"


class WorkoutSummaryResponse(BaseModel):
    """Response for the workout summary screen."""
    workout: dict
    performance_comparison: Optional[PerformanceComparisonInfo] = None
    personal_records: List[PersonalRecordInfo] = []
    # Long-form encouragement (2-3 sentences) shown in the Summary tab.
    coach_summary: Optional[str] = None
    # Punchy one-liner (≤20 words) anchored to real session deltas.
    # Rendered as the hero card on the Advanced tab — separate from
    # coach_summary so we can keep that long-form copy unchanged while
    # this field carries the short, sharp headline voice.
    hero_narrative: Optional[str] = None
    completion_method: Optional[str] = None
    completed_at: Optional[str] = None
    set_logs: List[SetLogInfo] = []


class UpdateExerciseSetsRequest(BaseModel):
    """Request to update exercise sets after workout completion."""
    exercise_index: int
    sets: List[Dict[str, Any]]  # [{ set_number, reps, weight_kg, rpe? }]
