"""Pydantic models for diabetes."""
from datetime import datetime, date
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any


class CreateDiabetesProfileRequest(BaseModel):
    """Request to create a diabetes profile."""
    user_id: str
    diabetes_type: str = Field(..., description="type1, type2, prediabetes, gestational, other")
    diagnosis_date: Optional[str] = None
    target_glucose_min_mg_dl: float = 70
    target_glucose_max_mg_dl: float = 180
    fasting_target_min_mg_dl: float = 80
    fasting_target_max_mg_dl: float = 130
    pre_meal_target_min_mg_dl: float = 80
    pre_meal_target_max_mg_dl: float = 130
    post_meal_target_min_mg_dl: float = 80
    post_meal_target_max_mg_dl: float = 180
    bedtime_target_min_mg_dl: float = 90
    bedtime_target_max_mg_dl: float = 150
    a1c_target: Optional[float] = 7.0
    uses_insulin_pump: bool = False
    uses_cgm: bool = False
    cgm_device: Optional[str] = None
    insulin_pump_device: Optional[str] = None
    carb_ratio: Optional[float] = None
    correction_factor: Optional[float] = None
    notifications_enabled: bool = True
    low_glucose_alert_threshold: float = 70
    high_glucose_alert_threshold: float = 180


class DiabetesProfileResponse(BaseModel):
    """Diabetes profile response."""
    id: str
    user_id: str
    diabetes_type: str
    diagnosis_date: Optional[str] = None
    target_glucose_min_mg_dl: float
    target_glucose_max_mg_dl: float
    a1c_target: Optional[float] = None
    uses_insulin_pump: bool
    uses_cgm: bool
    cgm_device: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class UpdateGlucoseTargetsRequest(BaseModel):
    """Request to update glucose targets."""
    target_glucose_min_mg_dl: Optional[float] = None
    target_glucose_max_mg_dl: Optional[float] = None
    fasting_target_min_mg_dl: Optional[float] = None
    fasting_target_max_mg_dl: Optional[float] = None
    a1c_target: Optional[float] = None

    @validator('target_glucose_max_mg_dl')
    def validate_target_max(cls, v, values):
        if v is not None and 'target_glucose_min_mg_dl' in values and values['target_glucose_min_mg_dl'] is not None:
            if v < values['target_glucose_min_mg_dl']:
                raise ValueError('Max target must be greater than min target')
        return v


class LogGlucoseReadingRequest(BaseModel):
    """Request to log a glucose reading."""
    user_id: str
    glucose_mg_dl: float = Field(..., ge=20, le=600, description="Blood glucose in mg/dL")
    reading_type: str = "manual"  # manual, cgm, health_connect
    meal_context: Optional[str] = None  # fasting, before_meal, after_meal, bedtime, other
    notes: Optional[str] = None
    timestamp: Optional[str] = None
    source: str = "manual"
    device_id: Optional[str] = None


class GlucoseReadingResponse(BaseModel):
    """Glucose reading response."""
    id: str
    user_id: str
    glucose_mg_dl: float
    reading_type: str
    meal_context: Optional[str] = None
    notes: Optional[str] = None
    timestamp: str
    source: str
    created_at: str


class GlucoseHistoryResponse(BaseModel):
    """Paginated glucose history response."""
    readings: List[GlucoseReadingResponse]
    total_count: int
    limit: int
    offset: int


class GlucoseSummaryResponse(BaseModel):
    """Glucose summary statistics."""
    period: str
    reading_count: int
    average_glucose: Optional[float] = None
    min_glucose: Optional[float] = None
    max_glucose: Optional[float] = None
    standard_deviation: Optional[float] = None
    time_in_range: Optional[float] = None


class GlucoseStatusResponse(BaseModel):
    """Glucose status classification."""
    status: str  # very_low, low, normal, elevated, high, very_high
    severity: str  # none, info, warning, urgent
    message: str


class LogInsulinDoseRequest(BaseModel):
    """Request to log an insulin dose."""
    user_id: str
    insulin_type: str = Field(..., description="rapid, short, intermediate, long, mixed")
    insulin_name: Optional[str] = None
    units: float = Field(..., gt=0, le=300, description="Insulin units")
    dose_type: str = "meal"  # meal, correction, basal, exercise
    associated_meal: Optional[str] = None
    carbs_covered: Optional[float] = None
    glucose_before: Optional[float] = None
    correction_included: bool = False
    timestamp: Optional[str] = None
    notes: Optional[str] = None


class InsulinDoseResponse(BaseModel):
    """Insulin dose response."""
    id: str
    user_id: str
    insulin_type: str
    insulin_name: Optional[str] = None
    units: float
    dose_type: str
    correction_included: bool
    timestamp: str
    created_at: str


class DailyInsulinTotalResponse(BaseModel):
    """Daily insulin totals."""
    date: str
    total_units: float
    rapid_units: float
    long_units: float
    dose_count: int


class InsulinHistoryResponse(BaseModel):
    """Insulin history response."""
    doses: List[InsulinDoseResponse]
    period_days: int
    total_doses: int


class LogA1cRequest(BaseModel):
    """Request to log an A1C result."""
    user_id: str
    a1c_value: float = Field(..., ge=3.0, le=20.0, description="A1C percentage")
    test_date: str
    lab_name: Optional[str] = None
    notes: Optional[str] = None
    source: str = "lab"  # lab, home_test, estimated


class A1cResultResponse(BaseModel):
    """A1C result response."""
    id: str
    user_id: str
    a1c_value: float
    test_date: str
    estimated_avg_glucose: Optional[float] = None
    source: str
    created_at: str


class A1cHistoryResponse(BaseModel):
    """A1C history response."""
    results: List[A1cResultResponse]
    latest_a1c: Optional[float] = None


class A1cTrendResponse(BaseModel):
    """A1C trend analysis."""
    trend: str  # improving, stable, worsening
    change: float
    period_months: int


class EstimatedA1cResponse(BaseModel):
    """Estimated A1C from glucose readings."""
    estimated_a1c: Optional[float] = None
    based_on_readings: int
    average_glucose: Optional[float] = None
    period_days: int
    error: Optional[str] = None


class AddMedicationRequest(BaseModel):
    """Request to add a medication."""
    user_id: str
    medication_name: str
    dosage_mg: Optional[float] = None
    frequency: str  # once_daily, twice_daily, three_times_daily, as_needed
    times_of_day: Optional[List[str]] = None
    with_food: bool = False
    start_date: Optional[str] = None
    medication_type: str = "oral"  # oral, injectable, insulin
    notes: Optional[str] = None


class MedicationResponse(BaseModel):
    """Medication response."""
    id: str
    medication_name: str
    dosage_mg: Optional[float] = None
    frequency: str
    is_active: bool
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    created_at: str


class MedicationsListResponse(BaseModel):
    """List of medications."""
    medications: List[MedicationResponse]


class UpdateMedicationRequest(BaseModel):
    """Request to update a medication."""
    dosage_mg: Optional[float] = None
    frequency: Optional[str] = None
    times_of_day: Optional[List[str]] = None


class LogCarbEntryRequest(BaseModel):
    """Request to log carbohydrates."""
    user_id: str
    carbs_grams: float = Field(..., ge=0, le=500)
    meal_type: Optional[str] = None  # breakfast, lunch, dinner, snack
    food_items: Optional[List[str]] = None
    glucose_before: Optional[float] = None
    glucose_after: Optional[float] = None
    insulin_dose: Optional[float] = None
    timestamp: Optional[str] = None
    notes: Optional[str] = None


class CarbEntryResponse(BaseModel):
    """Carb entry response."""
    id: str
    carbs_grams: float
    meal_type: Optional[str] = None
    glucose_before: Optional[float] = None
    glucose_after: Optional[float] = None
    timestamp: str
    created_at: str


class DailyCarbTotalResponse(BaseModel):
    """Daily carb totals."""
    date: str
    total_carbs: float
    meal_count: int
    breakdown: dict


class CarbCorrelationResponse(BaseModel):
    """Carb-to-glucose correlation."""
    average_rise_per_10g_carbs: Optional[float] = None
    data_points: int
    period_days: int


class CreateGlucoseAlertRequest(BaseModel):
    """Request to create a glucose alert."""
    user_id: str
    alert_type: str  # low_glucose, high_glucose, rapid_drop, rapid_rise
    threshold_mg_dl: float
    notification_method: str = "push"  # push, sms, email
    enabled: bool = True
    repeat_interval_minutes: int = 15


class GlucoseAlertResponse(BaseModel):
    """Glucose alert response."""
    id: str
    alert_type: str
    threshold_mg_dl: float
    enabled: bool
    created_at: str


class UpdateGlucoseAlertRequest(BaseModel):
    """Request to update an alert."""
    threshold_mg_dl: Optional[float] = None
    enabled: Optional[bool] = None


class AlertTriggeredResponse(BaseModel):
    """Alert trigger check response."""
    triggered: bool
    alert_type: Optional[str] = None
    action_required: bool = False
    recommendations: List[str] = []


class TimeInRangeResponse(BaseModel):
    """Time in range calculation."""
    time_in_range: Optional[float] = None
    time_below_range: Optional[float] = None
    time_above_range: Optional[float] = None
    period_days: int
    reading_count: int
    error: Optional[str] = None


class VariabilityResponse(BaseModel):
    """Glucose variability metrics."""
    coefficient_of_variation: Optional[float] = None
    standard_deviation: Optional[float] = None
    gmi: Optional[float] = None  # Glucose Management Indicator
    average_glucose: Optional[float] = None
    reading_count: int


class GlucosePattern(BaseModel):
    """Detected glucose pattern."""
    pattern_type: str
    description: str
    severity: str
    recommendation: str


class PatternsResponse(BaseModel):
    """Detected patterns response."""
    patterns: List[GlucosePattern]
    analysis_period_days: int


class DashboardDataResponse(BaseModel):
    """Dashboard aggregated data."""
    current_glucose: Optional[float] = None
    current_glucose_status: Optional[str] = None
    a1c_latest: Optional[float] = None
    time_in_range: Optional[float] = None
    time_in_range_error: Optional[str] = None
    today_insulin_total: Optional[float] = None
    readings_today: int = 0


class PreWorkoutRiskResponse(BaseModel):
    """Pre-workout glucose risk assessment."""
    risk_level: str  # low, moderate, high
    can_exercise: bool
    current_glucose: Optional[float] = None
    recommendations: List[str] = []


class WorkoutGlucoseImpactResponse(BaseModel):
    """Workout impact on glucose."""
    average_drop: Optional[float] = None
    workout_count: int
    period_days: int


class HealthConnectSyncRequest(BaseModel):
    """Health Connect sync request."""
    user_id: str
    readings: List[dict]


class HealthConnectSyncResponse(BaseModel):
    """Health Connect sync response."""
    synced_count: int
    source: str


# ============================================================
# Helper Functions
# ============================================================

