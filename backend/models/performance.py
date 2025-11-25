"""
Performance Models for Gravl-like Progressive Overload.

EASY TO MODIFY:
- Adjust 1RM formulas: Modify the estimation methods in StrengthRecord
- Change progression rules: Modify ProgressionRecommendation logic
- Add new metrics: Add new Pydantic models following the existing pattern
"""
from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Any
from datetime import datetime
from enum import Enum


class ProgressionStrategy(str, Enum):
    """Strategy for progressive overload."""
    LINEAR = "linear"  # Add weight each session
    DOUBLE_PROGRESSION = "double_progression"  # Increase reps, then weight
    WAVE = "wave"  # Undulating periodization
    DELOAD = "deload"  # Reduce intensity for recovery


class SetPerformance(BaseModel):
    """
    Single set performance data.
    Captures everything about one set of an exercise.
    """
    set_number: int
    reps_completed: int
    weight_kg: float
    rpe: Optional[float] = Field(None, ge=1, le=10, description="Rate of Perceived Exertion (1-10)")
    rir: Optional[int] = Field(None, ge=0, le=5, description="Reps in Reserve (0-5)")
    tempo: Optional[str] = None  # e.g., "3-1-2-0" (eccentric-pause-concentric-pause)
    notes: Optional[str] = None
    completed: bool = True
    failed_at_rep: Optional[int] = None  # If set failed, at which rep


class ExercisePerformance(BaseModel):
    """
    Performance data for one exercise in a workout.
    """
    exercise_id: str
    exercise_name: str
    sets: List[SetPerformance]
    target_sets: int
    target_reps: int
    target_weight_kg: Optional[float] = None
    rest_seconds: int = 90

    @property
    def total_reps(self) -> int:
        """Total reps completed across all sets."""
        return sum(s.reps_completed for s in self.sets if s.completed)

    @property
    def total_volume(self) -> float:
        """Total volume (reps × weight) in kg."""
        return sum(s.reps_completed * s.weight_kg for s in self.sets if s.completed)

    @property
    def average_rpe(self) -> Optional[float]:
        """Average RPE across sets."""
        rpes = [s.rpe for s in self.sets if s.rpe is not None]
        return sum(rpes) / len(rpes) if rpes else None

    @property
    def estimated_1rm(self) -> Optional[float]:
        """Estimate 1RM using Brzycki formula from best set."""
        best_set = max(
            (s for s in self.sets if s.completed and s.weight_kg > 0),
            key=lambda s: s.weight_kg * (36 / (37 - s.reps_completed)) if s.reps_completed < 37 else 0,
            default=None
        )
        if best_set and best_set.reps_completed < 37:
            # Brzycki formula: 1RM = weight × (36 / (37 - reps))
            return best_set.weight_kg * (36 / (37 - best_set.reps_completed))
        return None


class WorkoutPerformance(BaseModel):
    """
    Complete workout performance log.
    """
    workout_id: int
    user_id: int
    workout_name: str
    workout_type: str
    scheduled_date: datetime
    started_at: datetime
    completed_at: Optional[datetime] = None
    exercises: List[ExercisePerformance]
    session_rpe: Optional[float] = Field(None, ge=1, le=10)
    notes: Optional[str] = None

    @property
    def duration_minutes(self) -> Optional[int]:
        """Workout duration in minutes."""
        if self.completed_at:
            return int((self.completed_at - self.started_at).total_seconds() / 60)
        return None

    @property
    def total_volume(self) -> float:
        """Total workout volume in kg."""
        return sum(ex.total_volume for ex in self.exercises)

    @property
    def total_sets(self) -> int:
        """Total sets completed."""
        return sum(len(ex.sets) for ex in self.exercises)

    @property
    def completion_rate(self) -> float:
        """Percentage of target sets completed."""
        target = sum(ex.target_sets for ex in self.exercises)
        completed = sum(len([s for s in ex.sets if s.completed]) for ex in self.exercises)
        return (completed / target * 100) if target > 0 else 0


class StrengthRecord(BaseModel):
    """
    Historical strength record for an exercise.
    Used for tracking PRs and progression.
    """
    exercise_id: str
    exercise_name: str
    user_id: int
    date: datetime
    weight_kg: float
    reps: int
    estimated_1rm: float
    rpe: Optional[float] = None
    is_pr: bool = False  # Personal record flag

    @classmethod
    def calculate_1rm(cls, weight: float, reps: int, formula: str = "brzycki") -> float:
        """
        Calculate estimated 1RM using various formulas.

        Formulas:
        - brzycki: weight × (36 / (37 - reps))
        - epley: weight × (1 + reps / 30)
        - lander: (100 × weight) / (101.3 - 2.67123 × reps)
        """
        if reps == 1:
            return weight
        if reps >= 37:
            return weight  # Formula breaks down at high reps

        if formula == "brzycki":
            return weight * (36 / (37 - reps))
        elif formula == "epley":
            return weight * (1 + reps / 30)
        elif formula == "lander":
            return (100 * weight) / (101.3 - 2.67123 * reps)
        else:
            return weight * (36 / (37 - reps))  # Default to Brzycki


class ProgressionRecommendation(BaseModel):
    """
    Recommendation for next workout's weight/reps.
    """
    exercise_id: str
    exercise_name: str
    current_weight_kg: float
    current_reps: int
    recommended_weight_kg: float
    recommended_reps: int
    recommended_sets: int
    strategy: ProgressionStrategy
    reason: str
    confidence: float = Field(ge=0, le=1, description="Confidence in recommendation (0-1)")


class MuscleGroupVolume(BaseModel):
    """
    Weekly volume tracking per muscle group.
    """
    muscle_group: str
    total_sets: int
    total_reps: int
    total_volume_kg: float
    frequency: int  # Times trained this week
    target_sets: int  # Recommended weekly sets
    recovery_status: str  # "recovered", "fatigued", "overtrained"


class WeeklyPerformanceSummary(BaseModel):
    """
    Weekly performance summary for analytics.
    """
    user_id: int
    week_start: datetime
    week_end: datetime
    workouts_completed: int
    workouts_planned: int
    total_volume_kg: float
    total_sets: int
    total_reps: int
    average_session_rpe: Optional[float]
    muscle_group_volumes: List[MuscleGroupVolume]
    new_prs: int
    adherence_rate: float  # % of planned workouts completed


class AdaptationRequest(BaseModel):
    """
    Request to adapt a workout based on previous performance.
    """
    user_id: int
    workout_id: int
    reason: str  # "missed_muscles", "recovery", "time_constraint", "progression"
    missed_muscle_groups: Optional[List[str]] = None
    available_time_minutes: Optional[int] = None
    fatigue_level: Optional[int] = Field(None, ge=1, le=10)
    injuries: Optional[List[str]] = None


class AdaptedWorkout(BaseModel):
    """
    Result of workout adaptation.
    """
    original_workout_id: int
    adapted_exercises: List[Dict[str, Any]]
    changes_made: List[str]
    reasoning: str
    estimated_duration_minutes: int


# ============ Request/Response Models for API ============

class LogWorkoutRequest(BaseModel):
    """Request to log a completed workout."""
    workout_id: int
    user_id: int
    started_at: datetime
    completed_at: datetime
    exercises: List[ExercisePerformance]
    session_rpe: Optional[float] = None
    notes: Optional[str] = None


class LogWorkoutResponse(BaseModel):
    """Response after logging workout."""
    success: bool
    workout_log_id: int
    message: str
    new_prs: List[str]  # List of exercises with new PRs
    next_recommendations: List[ProgressionRecommendation]


class GetRecommendationsRequest(BaseModel):
    """Request for exercise recommendations."""
    user_id: int
    workout_id: Optional[int] = None
    exercise_ids: Optional[List[str]] = None


class GetRecommendationsResponse(BaseModel):
    """Response with exercise recommendations."""
    user_id: int
    recommendations: List[ProgressionRecommendation]
    deload_suggested: bool
    deload_reason: Optional[str] = None


class AnalyticsRequest(BaseModel):
    """Request for performance analytics."""
    user_id: int
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    exercise_ids: Optional[List[str]] = None


class AnalyticsResponse(BaseModel):
    """Response with performance analytics."""
    user_id: int
    period_start: datetime
    period_end: datetime
    weekly_summaries: List[WeeklyPerformanceSummary]
    strength_progression: Dict[str, List[StrengthRecord]]  # exercise_id -> records
    volume_trend: List[Dict[str, Any]]
    top_prs: List[StrengthRecord]
