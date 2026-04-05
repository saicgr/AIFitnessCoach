"""Pydantic models for fasting_impact."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class LogWeightWithFastingRequest(BaseModel):
    """Request to log weight with optional fasting correlation."""
    user_id: str
    weight_kg: float = Field(gt=0, description="Weight in kilograms")
    date: str = Field(description="Date in YYYY-MM-DD format")
    notes: Optional[str] = None
    fasting_record_id: Optional[str] = Field(None, description="Optional explicit link to a fasting record")

class WeightLogResponse(BaseModel):
    """Weight log entry with fasting correlation."""
    id: str
    user_id: str
    weight_kg: float
    date: str
    notes: Optional[str] = None
    fasting_record_id: Optional[str] = None
    is_fasting_day: bool
    fasting_protocol: Optional[str] = None
    fasting_completion_percent: Optional[float] = None
    created_at: str

class FastingWeightCorrelationResponse(BaseModel):
    """Response containing weight logs with fasting correlation data."""
    user_id: str
    period_days: int
    weight_logs: List[WeightLogResponse]
    summary: Dict[str, Any]

class FastingGoalImpactResponse(BaseModel):
    """Response containing fasting impact on goals analysis."""
    user_id: str
    period: str
    analysis_date: str

    # Weight metrics
    avg_weight_fasting_days: Optional[float] = None
    avg_weight_non_fasting_days: Optional[float] = None
    weight_trend_fasting: Optional[str] = None  # 'decreasing', 'stable', 'increasing'

    # Workout performance
    workouts_on_fasting_days: int = 0
    workouts_on_non_fasting_days: int = 0
    avg_workout_completion_fasting: Optional[float] = None
    avg_workout_completion_non_fasting: Optional[float] = None

    # Goals performance
    goals_hit_on_fasting_days: int = 0
    goals_hit_on_non_fasting_days: int = 0
    goal_completion_rate_fasting: Optional[float] = None
    goal_completion_rate_non_fasting: Optional[float] = None

    # Correlation metrics
    correlation_score: Optional[float] = Field(None, ge=-1.0, le=1.0, description="Pearson correlation between fasting and goal achievement")
    correlation_interpretation: Optional[str] = None

    # Overall assessment
    fasting_impact_summary: str
    recommendations: List[str]

class FastingImpactInsightResponse(BaseModel):
    """AI-generated insights about fasting impact."""
    user_id: str
    generated_at: str

    # Structured insights
    weight_insight: Optional[Dict[str, Any]] = None
    performance_insight: Optional[Dict[str, Any]] = None
    goal_insight: Optional[Dict[str, Any]] = None

    # Natural language insights
    key_findings: List[str]
    personalized_tips: List[str]

    # Trend indicators
    overall_trend: str  # 'positive', 'neutral', 'needs_attention'
    confidence_level: str  # 'high', 'medium', 'low' based on data quantity

class CalendarDayData(BaseModel):
    """Data for a single calendar day."""
    date: str
    is_fasting_day: bool
    fasting_protocol: Optional[str] = None
    fasting_completion_percent: Optional[float] = None
    fasting_record_id: Optional[str] = None
    weight_logged: Optional[float] = None
    workout_completed: bool = False
    workout_id: Optional[str] = None
    goals_hit: int = 0
    goals_total: int = 0

class CalendarViewResponse(BaseModel):
    """Calendar view with fasting, weight, workout, and goal data."""
    user_id: str
    month: int
    year: int
    days: List[CalendarDayData]
    summary: Dict[str, Any]

# ==================== Helper Functions ====================

class AIFastingInsightResponse(BaseModel):
    """AI-generated fasting insight response using Gemini."""
    id: str
    user_id: str
    insight_type: str  # 'positive', 'neutral', 'negative', 'needs_more_data'
    title: str
    message: str
    recommendation: str
    key_finding: Optional[str] = None
    data_summary: Dict[str, Any]
    created_at: str

class AICorrelationResponse(BaseModel):
    """Correlation score response."""
    user_id: str
    correlation_score: float
    interpretation: str
    days_analyzed: int
    sufficient_data: bool

class AIFastingSummaryResponse(BaseModel):
    """Fasting summary data response."""
    user_id: str
    total_fasting_days: int
    total_non_fasting_days: int
    most_common_protocol: Optional[str]
    avg_fast_duration_hours: float
    correlation_score: Optional[float]
    period_days: int

class MarkFastingDayRequest(BaseModel):
    """Request to mark a historical date as a fasting day."""
    user_id: str
    date: str = Field(description="Date in YYYY-MM-DD format")
    protocol: Optional[str] = Field(None, description="Fasting protocol (e.g., '16:8', '18:6')")
    estimated_hours: Optional[float] = Field(None, ge=1, le=72, description="Estimated fasting hours (1-72)")
    notes: Optional[str] = Field(None, description="Optional notes about the fast")

class MarkFastingDayResponse(BaseModel):
    """Response after marking a historical fasting day."""
    id: str
    user_id: str
    date: str
    protocol: Optional[str]
    estimated_hours: Optional[float]
    status: str
    completion_percentage: float
    notes: Optional[str]
    created_at: str
    message: str

