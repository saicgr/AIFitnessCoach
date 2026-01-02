"""
Diabetes Tracking API endpoints.

Comprehensive diabetes management for Type 1, Type 2, and other diabetes types.
Includes blood glucose logging, insulin tracking, A1C management, carbohydrate
counting, and Health Connect integration.
"""

from datetime import datetime, date, timedelta
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel, Field, validator
import uuid

from core.supabase_db import get_supabase_db
from services.user_context_service import (
    log_user_activity,
    log_user_error,
)

router = APIRouter(prefix="/diabetes", tags=["Diabetes Tracking"])


# ============================================================
# Pydantic Models
# ============================================================

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

def glucose_to_a1c(avg_glucose: float) -> float:
    """Convert average glucose (mg/dL) to estimated A1C."""
    return (avg_glucose + 46.7) / 28.7


def a1c_to_glucose(a1c: float) -> float:
    """Convert A1C to estimated average glucose (mg/dL)."""
    return (a1c * 28.7) - 46.7


def classify_glucose_status(glucose_mg_dl: float) -> str:
    """Classify glucose status."""
    if glucose_mg_dl < 54:
        return "very_low"
    elif glucose_mg_dl < 70:
        return "low"
    elif glucose_mg_dl <= 100:
        return "normal"
    elif glucose_mg_dl <= 125:
        return "elevated"
    elif glucose_mg_dl <= 180:
        return "high"
    else:
        return "very_high"


def calculate_cv(readings: List[float]) -> Optional[float]:
    """Calculate coefficient of variation."""
    if not readings or len(readings) < 2:
        return None
    import statistics
    mean = statistics.mean(readings)
    if mean == 0:
        return None
    std = statistics.stdev(readings)
    return (std / mean) * 100


# ============================================================
# Profile Endpoints
# ============================================================

@router.post("/profile", response_model=DiabetesProfileResponse)
async def create_diabetes_profile(request: CreateDiabetesProfileRequest):
    """Create a diabetes profile for a user."""
    db = get_supabase_db()

    # Check if profile already exists
    existing = db.client.table("diabetes_profiles").select("id").eq(
        "user_id", request.user_id
    ).execute()

    if existing.data:
        raise HTTPException(status_code=400, detail="Diabetes profile already exists for this user")

    profile_data = {
        "id": str(uuid.uuid4()),
        "user_id": request.user_id,
        "diabetes_type": request.diabetes_type,
        "diagnosis_date": request.diagnosis_date,
        "target_glucose_min_mg_dl": request.target_glucose_min_mg_dl,
        "target_glucose_max_mg_dl": request.target_glucose_max_mg_dl,
        "fasting_target_min_mg_dl": request.fasting_target_min_mg_dl,
        "fasting_target_max_mg_dl": request.fasting_target_max_mg_dl,
        "a1c_target": request.a1c_target,
        "uses_insulin_pump": request.uses_insulin_pump,
        "uses_cgm": request.uses_cgm,
        "cgm_device": request.cgm_device,
        "notifications_enabled": request.notifications_enabled,
        "low_glucose_alert_threshold": request.low_glucose_alert_threshold,
        "high_glucose_alert_threshold": request.high_glucose_alert_threshold,
    }

    result = db.client.table("diabetes_profiles").insert(profile_data).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create diabetes profile")

    await log_user_activity(
        request.user_id,
        "diabetes_profile_created",
        {"diabetes_type": request.diabetes_type}
    )

    return DiabetesProfileResponse(**result.data[0])


@router.get("/profile/{user_id}", response_model=DiabetesProfileResponse)
async def get_diabetes_profile(user_id: str):
    """Get a user's diabetes profile."""
    db = get_supabase_db()

    result = db.client.table("diabetes_profiles").select("*").eq(
        "user_id", user_id
    ).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Diabetes profile not found")

    return DiabetesProfileResponse(**result.data[0])


@router.patch("/profile/{user_id}/targets", response_model=DiabetesProfileResponse)
async def update_glucose_targets(user_id: str, request: UpdateGlucoseTargetsRequest):
    """Update glucose targets for a user."""
    db = get_supabase_db()

    # Validate min/max relationship
    if request.target_glucose_min_mg_dl and request.target_glucose_max_mg_dl:
        if request.target_glucose_min_mg_dl > request.target_glucose_max_mg_dl:
            raise HTTPException(status_code=400, detail="Min target cannot exceed max target")

    update_data = {k: v for k, v in request.dict().items() if v is not None}
    update_data["updated_at"] = datetime.utcnow().isoformat()

    result = db.client.table("diabetes_profiles").update(update_data).eq(
        "user_id", user_id
    ).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Diabetes profile not found")

    return DiabetesProfileResponse(**result.data[0])


# ============================================================
# Glucose Reading Endpoints
# ============================================================

@router.post("/glucose", response_model=GlucoseReadingResponse)
async def log_glucose_reading(request: LogGlucoseReadingRequest):
    """Log a glucose reading."""
    db = get_supabase_db()

    reading_data = {
        "id": str(uuid.uuid4()),
        "user_id": request.user_id,
        "glucose_mg_dl": request.glucose_mg_dl,
        "reading_type": request.reading_type,
        "meal_context": request.meal_context,
        "notes": request.notes,
        "timestamp": request.timestamp or datetime.utcnow().isoformat(),
        "source": request.source,
        "device_id": request.device_id,
    }

    result = db.client.table("glucose_readings").insert(reading_data).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to log glucose reading")

    status = classify_glucose_status(request.glucose_mg_dl)
    await log_user_activity(
        request.user_id,
        "glucose_reading_logged",
        {
            "value": request.glucose_mg_dl,
            "status": status,
            "meal_context": request.meal_context,
        }
    )

    return GlucoseReadingResponse(**result.data[0])


@router.get("/glucose/{user_id}/history", response_model=GlucoseHistoryResponse)
async def get_glucose_history(
    user_id: str,
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
):
    """Get glucose reading history with pagination."""
    db = get_supabase_db()

    # Validate date range
    if from_date and to_date:
        if from_date > to_date:
            raise HTTPException(status_code=400, detail="from_date cannot be after to_date")

    query = db.client.table("glucose_readings").select("*", count="exact").eq(
        "user_id", user_id
    )

    if from_date:
        query = query.gte("timestamp", from_date)
    if to_date:
        query = query.lte("timestamp", to_date + "T23:59:59")

    query = query.order("timestamp", desc=True).range(offset, offset + limit - 1)
    result = query.execute()

    readings = [GlucoseReadingResponse(**r) for r in (result.data or [])]
    total_count = result.count or len(readings)

    return GlucoseHistoryResponse(
        readings=readings,
        total_count=total_count,
        limit=limit,
        offset=offset
    )


@router.get("/glucose/{user_id}/latest", response_model=Optional[GlucoseReadingResponse])
async def get_latest_reading(user_id: str):
    """Get the most recent glucose reading."""
    db = get_supabase_db()

    result = db.client.table("glucose_readings").select("*").eq(
        "user_id", user_id
    ).order("timestamp", desc=True).limit(1).execute()

    if not result.data:
        return None

    return GlucoseReadingResponse(**result.data[0])


@router.get("/glucose/{user_id}/summary", response_model=GlucoseSummaryResponse)
async def get_glucose_summary(
    user_id: str,
    period: str = "daily",  # daily, weekly, monthly
    date: Optional[str] = None,
):
    """Get glucose summary statistics for a period."""
    import statistics

    db = get_supabase_db()

    # Calculate date range
    if date:
        target_date = datetime.fromisoformat(date)
    else:
        target_date = datetime.now()

    if period == "daily":
        start_date = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=1)
    elif period == "weekly":
        start_date = target_date - timedelta(days=target_date.weekday())
        start_date = start_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=7)
    else:  # monthly
        start_date = target_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        if target_date.month == 12:
            end_date = target_date.replace(year=target_date.year + 1, month=1, day=1)
        else:
            end_date = target_date.replace(month=target_date.month + 1, day=1)

    result = db.client.table("glucose_readings").select("glucose_mg_dl").eq(
        "user_id", user_id
    ).gte("timestamp", start_date.isoformat()).lt("timestamp", end_date.isoformat()).execute()

    readings = [r["glucose_mg_dl"] for r in (result.data or [])]

    if not readings:
        return GlucoseSummaryResponse(
            period=period,
            reading_count=0,
            average_glucose=None,
            min_glucose=None,
            max_glucose=None,
        )

    return GlucoseSummaryResponse(
        period=period,
        reading_count=len(readings),
        average_glucose=round(statistics.mean(readings), 1),
        min_glucose=min(readings),
        max_glucose=max(readings),
        standard_deviation=round(statistics.stdev(readings), 1) if len(readings) > 1 else None,
    )


@router.get("/glucose/status/{glucose_value}", response_model=GlucoseStatusResponse)
async def get_glucose_status(glucose_value: float):
    """Get status classification for a glucose value."""
    status = classify_glucose_status(glucose_value)

    severity_map = {
        "very_low": "urgent",
        "low": "warning",
        "normal": "none",
        "elevated": "info",
        "high": "warning",
        "very_high": "urgent",
    }

    message_map = {
        "very_low": "Severe hypoglycemia - take fast-acting carbs immediately",
        "low": "Hypoglycemia - consider having a snack",
        "normal": "Blood glucose is in the normal range",
        "elevated": "Blood glucose is slightly elevated",
        "high": "Blood glucose is high - monitor closely",
        "very_high": "Hyperglycemia - consider correction dose and check ketones",
    }

    return GlucoseStatusResponse(
        status=status,
        severity=severity_map[status],
        message=message_map[status]
    )


@router.delete("/glucose/{user_id}/{reading_id}")
async def delete_glucose_reading(user_id: str, reading_id: str):
    """Delete a glucose reading."""
    db = get_supabase_db()

    # Verify ownership
    existing = db.client.table("glucose_readings").select("id").eq(
        "id", reading_id
    ).eq("user_id", user_id).execute()

    if not existing.data:
        raise HTTPException(status_code=404, detail="Glucose reading not found")

    db.client.table("glucose_readings").delete().eq("id", reading_id).execute()

    return {"status": "deleted", "id": reading_id}


@router.post("/glucose/sync", response_model=HealthConnectSyncResponse)
async def sync_from_health_connect(request: HealthConnectSyncRequest):
    """Sync glucose readings from Health Connect."""
    db = get_supabase_db()

    synced_count = 0
    for reading in request.readings:
        reading_data = {
            "id": str(uuid.uuid4()),
            "user_id": request.user_id,
            "glucose_mg_dl": reading.get("glucose_mg_dl"),
            "reading_type": "cgm",
            "timestamp": reading.get("timestamp"),
            "source": "health_connect",
        }

        try:
            db.client.table("glucose_readings").insert(reading_data).execute()
            synced_count += 1
        except Exception:
            continue

    await log_user_activity(
        request.user_id,
        "health_connect_diabetes_sync",
        {"glucose_count": synced_count}
    )

    return HealthConnectSyncResponse(synced_count=synced_count, source="health_connect")


# ============================================================
# Insulin Tracking Endpoints
# ============================================================

@router.post("/insulin", response_model=InsulinDoseResponse)
async def log_insulin_dose(request: LogInsulinDoseRequest):
    """Log an insulin dose."""
    db = get_supabase_db()

    dose_data = {
        "id": str(uuid.uuid4()),
        "user_id": request.user_id,
        "insulin_type": request.insulin_type,
        "insulin_name": request.insulin_name,
        "units": request.units,
        "dose_type": request.dose_type,
        "associated_meal": request.associated_meal,
        "carbs_covered": request.carbs_covered,
        "glucose_before": request.glucose_before,
        "correction_included": request.correction_included,
        "timestamp": request.timestamp or datetime.utcnow().isoformat(),
        "notes": request.notes,
    }

    result = db.client.table("insulin_doses").insert(dose_data).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to log insulin dose")

    await log_user_activity(
        request.user_id,
        "insulin_dose_logged",
        {"units": request.units, "insulin_type": request.insulin_type}
    )

    return InsulinDoseResponse(**result.data[0])


@router.get("/insulin/{user_id}/daily", response_model=DailyInsulinTotalResponse)
async def get_daily_insulin_total(user_id: str, date: Optional[str] = None):
    """Get total insulin for a day."""
    db = get_supabase_db()

    if date:
        target_date = datetime.fromisoformat(date)
    else:
        target_date = datetime.now()

    start = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
    end = start + timedelta(days=1)

    result = db.client.table("insulin_doses").select("units,insulin_type").eq(
        "user_id", user_id
    ).gte("timestamp", start.isoformat()).lt("timestamp", end.isoformat()).execute()

    doses = result.data or []
    total = sum(d["units"] for d in doses)
    rapid = sum(d["units"] for d in doses if d["insulin_type"] in ["rapid", "short"])
    long_acting = sum(d["units"] for d in doses if d["insulin_type"] in ["long", "intermediate"])

    return DailyInsulinTotalResponse(
        date=target_date.date().isoformat(),
        total_units=total,
        rapid_units=rapid,
        long_units=long_acting,
        dose_count=len(doses)
    )


@router.get("/insulin/{user_id}/history", response_model=InsulinHistoryResponse)
async def get_insulin_history(user_id: str, days: int = 7):
    """Get insulin dose history."""
    db = get_supabase_db()

    start_date = datetime.now() - timedelta(days=days)

    result = db.client.table("insulin_doses").select("*").eq(
        "user_id", user_id
    ).gte("timestamp", start_date.isoformat()).order("timestamp", desc=True).execute()

    doses = [InsulinDoseResponse(**d) for d in (result.data or [])]

    return InsulinHistoryResponse(
        doses=doses,
        period_days=days,
        total_doses=len(doses)
    )


# ============================================================
# A1C Endpoints
# ============================================================

@router.post("/a1c", response_model=A1cResultResponse)
async def log_a1c_result(request: LogA1cRequest):
    """Log an A1C result."""
    db = get_supabase_db()

    estimated_avg = round(a1c_to_glucose(request.a1c_value), 0)

    a1c_data = {
        "id": str(uuid.uuid4()),
        "user_id": request.user_id,
        "a1c_value": request.a1c_value,
        "test_date": request.test_date,
        "lab_name": request.lab_name,
        "notes": request.notes,
        "estimated_avg_glucose": estimated_avg,
        "source": request.source,
    }

    result = db.client.table("a1c_records").insert(a1c_data).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to log A1C result")

    await log_user_activity(
        request.user_id,
        "a1c_logged",
        {"value": request.a1c_value}
    )

    return A1cResultResponse(**result.data[0])


@router.get("/a1c/{user_id}/history", response_model=A1cHistoryResponse)
async def get_a1c_history(user_id: str):
    """Get A1C history."""
    db = get_supabase_db()

    result = db.client.table("a1c_records").select("*").eq(
        "user_id", user_id
    ).order("test_date", desc=True).execute()

    results = [A1cResultResponse(**r) for r in (result.data or [])]
    latest = results[0].a1c_value if results else None

    return A1cHistoryResponse(results=results, latest_a1c=latest)


@router.get("/a1c/{user_id}/trend", response_model=A1cTrendResponse)
async def get_a1c_trend(user_id: str):
    """Get A1C trend analysis."""
    db = get_supabase_db()

    result = db.client.table("a1c_records").select("a1c_value,test_date").eq(
        "user_id", user_id
    ).order("test_date", desc=True).limit(3).execute()

    if not result.data or len(result.data) < 2:
        return A1cTrendResponse(trend="stable", change=0, period_months=0)

    latest = result.data[0]["a1c_value"]
    oldest = result.data[-1]["a1c_value"]
    change = round(latest - oldest, 1)

    if change < -0.2:
        trend = "improving"
    elif change > 0.2:
        trend = "worsening"
    else:
        trend = "stable"

    return A1cTrendResponse(trend=trend, change=change, period_months=len(result.data) * 3)


@router.get("/a1c/{user_id}/estimated", response_model=EstimatedA1cResponse)
async def calculate_estimated_a1c(user_id: str, days: int = 90):
    """Calculate estimated A1C from glucose readings."""
    import statistics

    db = get_supabase_db()

    start_date = datetime.now() - timedelta(days=days)

    result = db.client.table("glucose_readings").select("glucose_mg_dl").eq(
        "user_id", user_id
    ).gte("timestamp", start_date.isoformat()).execute()

    readings = [r["glucose_mg_dl"] for r in (result.data or [])]

    if len(readings) < 10:
        return EstimatedA1cResponse(
            estimated_a1c=None,
            based_on_readings=len(readings),
            period_days=days,
            error="insufficient_data"
        )

    avg_glucose = statistics.mean(readings)
    estimated = round(glucose_to_a1c(avg_glucose), 1)

    return EstimatedA1cResponse(
        estimated_a1c=estimated,
        based_on_readings=len(readings),
        average_glucose=round(avg_glucose, 0),
        period_days=days
    )


# ============================================================
# Medication Endpoints
# ============================================================

@router.post("/medications", response_model=MedicationResponse)
async def add_medication(request: AddMedicationRequest):
    """Add a diabetes medication."""
    db = get_supabase_db()

    med_data = {
        "id": str(uuid.uuid4()),
        "user_id": request.user_id,
        "medication_name": request.medication_name,
        "dosage_mg": request.dosage_mg,
        "frequency": request.frequency,
        "times_of_day": request.times_of_day,
        "with_food": request.with_food,
        "start_date": request.start_date or date.today().isoformat(),
        "is_active": True,
        "medication_type": request.medication_type,
        "notes": request.notes,
    }

    result = db.client.table("diabetes_medications").insert(med_data).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to add medication")

    return MedicationResponse(**result.data[0])


@router.get("/medications/{user_id}", response_model=MedicationsListResponse)
async def get_active_medications(user_id: str):
    """Get list of active medications."""
    db = get_supabase_db()

    result = db.client.table("diabetes_medications").select("*").eq(
        "user_id", user_id
    ).eq("is_active", True).execute()

    medications = [MedicationResponse(**m) for m in (result.data or [])]

    return MedicationsListResponse(medications=medications)


@router.patch("/medications/{user_id}/{medication_id}/deactivate", response_model=MedicationResponse)
async def deactivate_medication(user_id: str, medication_id: str):
    """Deactivate a medication."""
    db = get_supabase_db()

    result = db.client.table("diabetes_medications").update({
        "is_active": False,
        "end_date": date.today().isoformat(),
        "updated_at": datetime.utcnow().isoformat()
    }).eq("id", medication_id).eq("user_id", user_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Medication not found")

    return MedicationResponse(**result.data[0])


@router.patch("/medications/{user_id}/{medication_id}", response_model=MedicationResponse)
async def update_medication(user_id: str, medication_id: str, request: UpdateMedicationRequest):
    """Update a medication."""
    db = get_supabase_db()

    update_data = {k: v for k, v in request.dict().items() if v is not None}
    update_data["updated_at"] = datetime.utcnow().isoformat()

    result = db.client.table("diabetes_medications").update(update_data).eq(
        "id", medication_id
    ).eq("user_id", user_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Medication not found")

    return MedicationResponse(**result.data[0])


# ============================================================
# Carbohydrate Endpoints
# ============================================================

@router.post("/carbs", response_model=CarbEntryResponse)
async def log_carb_entry(request: LogCarbEntryRequest):
    """Log a carbohydrate entry."""
    db = get_supabase_db()

    carb_data = {
        "id": str(uuid.uuid4()),
        "user_id": request.user_id,
        "carbs_grams": request.carbs_grams,
        "meal_type": request.meal_type,
        "food_items": request.food_items,
        "glucose_before": request.glucose_before,
        "glucose_after": request.glucose_after,
        "insulin_dose": request.insulin_dose,
        "timestamp": request.timestamp or datetime.utcnow().isoformat(),
        "notes": request.notes,
    }

    result = db.client.table("carb_entries").insert(carb_data).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to log carb entry")

    return CarbEntryResponse(**result.data[0])


@router.get("/carbs/{user_id}/daily", response_model=DailyCarbTotalResponse)
async def get_daily_carb_total(user_id: str, date: Optional[str] = None):
    """Get total carbs for a day."""
    db = get_supabase_db()

    if date:
        target_date = datetime.fromisoformat(date)
    else:
        target_date = datetime.now()

    start = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
    end = start + timedelta(days=1)

    result = db.client.table("carb_entries").select("carbs_grams,meal_type").eq(
        "user_id", user_id
    ).gte("timestamp", start.isoformat()).lt("timestamp", end.isoformat()).execute()

    entries = result.data or []
    total = sum(e["carbs_grams"] for e in entries)

    breakdown = {}
    for entry in entries:
        meal = entry.get("meal_type") or "other"
        breakdown[meal] = breakdown.get(meal, 0) + entry["carbs_grams"]

    return DailyCarbTotalResponse(
        date=target_date.date().isoformat(),
        total_carbs=total,
        meal_count=len(entries),
        breakdown=breakdown
    )


@router.get("/carbs/{user_id}/correlation", response_model=CarbCorrelationResponse)
async def get_carb_glucose_correlation(user_id: str, days: int = 30):
    """Get carb-to-glucose correlation analysis."""
    db = get_supabase_db()

    start_date = datetime.now() - timedelta(days=days)

    result = db.client.table("carb_entries").select(
        "carbs_grams,glucose_before,glucose_after"
    ).eq("user_id", user_id).gte(
        "timestamp", start_date.isoformat()
    ).not_.is_("glucose_before", "null").not_.is_("glucose_after", "null").execute()

    entries = result.data or []

    if not entries:
        return CarbCorrelationResponse(
            average_rise_per_10g_carbs=None,
            data_points=0,
            period_days=days
        )

    rises_per_10g = []
    for e in entries:
        if e["carbs_grams"] > 0:
            rise = e["glucose_after"] - e["glucose_before"]
            rise_per_10g = (rise / e["carbs_grams"]) * 10
            rises_per_10g.append(rise_per_10g)

    if not rises_per_10g:
        return CarbCorrelationResponse(
            average_rise_per_10g_carbs=None,
            data_points=0,
            period_days=days
        )

    import statistics
    avg_rise = round(statistics.mean(rises_per_10g), 1)

    return CarbCorrelationResponse(
        average_rise_per_10g_carbs=avg_rise,
        data_points=len(entries),
        period_days=days
    )


# ============================================================
# Alert Endpoints
# ============================================================

@router.post("/alerts", response_model=GlucoseAlertResponse)
async def create_glucose_alert(request: CreateGlucoseAlertRequest):
    """Create a glucose alert configuration."""
    db = get_supabase_db()

    alert_data = {
        "id": str(uuid.uuid4()),
        "user_id": request.user_id,
        "alert_type": request.alert_type,
        "threshold_mg_dl": request.threshold_mg_dl,
        "enabled": request.enabled,
        "notification_method": request.notification_method,
        "repeat_interval_minutes": request.repeat_interval_minutes,
    }

    result = db.client.table("glucose_alerts").insert(alert_data).execute()

    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create alert")

    return GlucoseAlertResponse(**result.data[0])


@router.get("/alerts/{user_id}/check", response_model=AlertTriggeredResponse)
async def check_alert_triggered(user_id: str, glucose_value: float):
    """Check if any alerts should be triggered."""
    db = get_supabase_db()

    result = db.client.table("glucose_alerts").select("*").eq(
        "user_id", user_id
    ).eq("enabled", True).execute()

    alerts = result.data or []

    for alert in alerts:
        if alert["alert_type"] == "low_glucose" and glucose_value < alert["threshold_mg_dl"]:
            return AlertTriggeredResponse(
                triggered=True,
                alert_type="low_glucose",
                action_required=True,
                recommendations=["Have fast-acting carbs (15g)", "Recheck in 15 minutes"]
            )
        elif alert["alert_type"] == "high_glucose" and glucose_value > alert["threshold_mg_dl"]:
            return AlertTriggeredResponse(
                triggered=True,
                alert_type="high_glucose",
                action_required=True,
                recommendations=["Consider correction dose", "Stay hydrated", "Check ketones if > 250"]
            )

    return AlertTriggeredResponse(triggered=False)


@router.patch("/alerts/{user_id}/{alert_id}", response_model=GlucoseAlertResponse)
async def update_glucose_alert(user_id: str, alert_id: str, request: UpdateGlucoseAlertRequest):
    """Update a glucose alert."""
    db = get_supabase_db()

    update_data = {k: v for k, v in request.dict().items() if v is not None}
    update_data["updated_at"] = datetime.utcnow().isoformat()

    result = db.client.table("glucose_alerts").update(update_data).eq(
        "id", alert_id
    ).eq("user_id", user_id).execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Alert not found")

    return GlucoseAlertResponse(**result.data[0])


# ============================================================
# Analytics Endpoints
# ============================================================

@router.get("/analytics/{user_id}/time-in-range", response_model=TimeInRangeResponse)
async def calculate_time_in_range(
    user_id: str,
    days: int = 7,
    target_min: float = 70,
    target_max: float = 180
):
    """Calculate time in range percentage."""
    db = get_supabase_db()

    start_date = datetime.now() - timedelta(days=days)

    result = db.client.table("glucose_readings").select("glucose_mg_dl").eq(
        "user_id", user_id
    ).gte("timestamp", start_date.isoformat()).execute()

    readings = [r["glucose_mg_dl"] for r in (result.data or [])]

    if not readings:
        return TimeInRangeResponse(
            time_in_range=None,
            period_days=days,
            reading_count=0,
            error="no_data"
        )

    in_range = sum(1 for r in readings if target_min <= r <= target_max)
    below = sum(1 for r in readings if r < target_min)
    above = sum(1 for r in readings if r > target_max)
    total = len(readings)

    return TimeInRangeResponse(
        time_in_range=round((in_range / total) * 100, 1),
        time_below_range=round((below / total) * 100, 1),
        time_above_range=round((above / total) * 100, 1),
        period_days=days,
        reading_count=total
    )


@router.get("/analytics/{user_id}/variability", response_model=VariabilityResponse)
async def calculate_glucose_variability(user_id: str, days: int = 7):
    """Calculate glucose variability metrics."""
    import statistics

    db = get_supabase_db()

    start_date = datetime.now() - timedelta(days=days)

    result = db.client.table("glucose_readings").select("glucose_mg_dl").eq(
        "user_id", user_id
    ).gte("timestamp", start_date.isoformat()).execute()

    readings = [r["glucose_mg_dl"] for r in (result.data or [])]

    if len(readings) < 2:
        return VariabilityResponse(
            coefficient_of_variation=None,
            standard_deviation=None,
            reading_count=len(readings)
        )

    avg = statistics.mean(readings)
    std = statistics.stdev(readings)
    cv = (std / avg) * 100
    gmi = glucose_to_a1c(avg)  # Glucose Management Indicator

    return VariabilityResponse(
        coefficient_of_variation=round(cv, 1),
        standard_deviation=round(std, 1),
        gmi=round(gmi, 1),
        average_glucose=round(avg, 0),
        reading_count=len(readings)
    )


@router.get("/analytics/{user_id}/patterns", response_model=PatternsResponse)
async def detect_glucose_patterns(user_id: str, days: int = 14):
    """Detect glucose patterns."""
    import statistics

    db = get_supabase_db()

    start_date = datetime.now() - timedelta(days=days)

    result = db.client.table("glucose_readings").select(
        "glucose_mg_dl,meal_context,timestamp"
    ).eq("user_id", user_id).gte("timestamp", start_date.isoformat()).execute()

    readings = result.data or []
    patterns = []

    # Check for dawn phenomenon (high morning readings)
    fasting_readings = [r["glucose_mg_dl"] for r in readings if r.get("meal_context") == "fasting"]
    non_fasting = [r["glucose_mg_dl"] for r in readings if r.get("meal_context") != "fasting"]

    if len(fasting_readings) >= 5 and len(non_fasting) >= 5:
        fasting_avg = statistics.mean(fasting_readings)
        non_fasting_avg = statistics.mean(non_fasting)

        if fasting_avg > 130 and fasting_avg > non_fasting_avg + 20:
            patterns.append(GlucosePattern(
                pattern_type="dawn_phenomenon",
                description="Elevated morning glucose levels detected",
                severity="moderate",
                recommendation="Discuss with your doctor about adjusting evening medication or timing"
            ))

    return PatternsResponse(patterns=patterns, analysis_period_days=days)


@router.get("/analytics/{user_id}/dashboard", response_model=DashboardDataResponse)
async def get_dashboard_data(user_id: str):
    """Get comprehensive dashboard data."""
    db = get_supabase_db()

    # Get profile
    profile = db.client.table("diabetes_profiles").select("*").eq(
        "user_id", user_id
    ).maybe_single().execute()

    # Get latest glucose
    latest_glucose = db.client.table("glucose_readings").select("glucose_mg_dl").eq(
        "user_id", user_id
    ).order("timestamp", desc=True).limit(1).maybe_single().execute()

    # Get latest A1C
    latest_a1c = db.client.table("a1c_records").select("a1c_value").eq(
        "user_id", user_id
    ).order("test_date", desc=True).limit(1).maybe_single().execute()

    # Get today's insulin
    today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_insulin = db.client.table("insulin_doses").select("units").eq(
        "user_id", user_id
    ).gte("timestamp", today_start.isoformat()).execute()

    insulin_total = sum(d["units"] for d in (today_insulin.data or []))

    # Get today's readings count
    today_readings = db.client.table("glucose_readings").select("id", count="exact").eq(
        "user_id", user_id
    ).gte("timestamp", today_start.isoformat()).execute()

    current_glucose = latest_glucose.data.get("glucose_mg_dl") if latest_glucose.data else None
    current_status = classify_glucose_status(current_glucose) if current_glucose else None

    return DashboardDataResponse(
        current_glucose=current_glucose,
        current_glucose_status=current_status,
        a1c_latest=latest_a1c.data.get("a1c_value") if latest_a1c.data else None,
        today_insulin_total=insulin_total,
        readings_today=today_readings.count or 0
    )


# ============================================================
# Exercise Integration Endpoints
# ============================================================

@router.get("/exercise/{user_id}/pre-workout", response_model=PreWorkoutRiskResponse)
async def assess_pre_workout_risk(user_id: str):
    """Assess glucose risk before workout."""
    db = get_supabase_db()

    # Get latest reading
    result = db.client.table("glucose_readings").select("glucose_mg_dl,timestamp").eq(
        "user_id", user_id
    ).order("timestamp", desc=True).limit(1).execute()

    if not result.data:
        return PreWorkoutRiskResponse(
            risk_level="moderate",
            can_exercise=True,
            recommendations=["Check blood glucose before starting workout"]
        )

    reading = result.data[0]
    glucose = reading["glucose_mg_dl"]
    timestamp = datetime.fromisoformat(reading["timestamp"].replace("Z", "+00:00"))
    age_minutes = (datetime.now(timestamp.tzinfo) - timestamp).total_seconds() / 60

    recommendations = []

    # Check if reading is too old
    if age_minutes > 60:
        recommendations.append("Reading is older than 1 hour - check again before exercising")

    if glucose < 70:
        return PreWorkoutRiskResponse(
            risk_level="high",
            can_exercise=False,
            current_glucose=glucose,
            recommendations=[
                "Blood glucose is too low for exercise",
                "Have 15-20g fast-acting carbs",
                "Wait 15-30 minutes and recheck"
            ]
        )
    elif glucose < 100:
        return PreWorkoutRiskResponse(
            risk_level="moderate",
            can_exercise=True,
            current_glucose=glucose,
            recommendations=[
                "Have a small carb snack (10-15g) before starting",
                "Monitor for signs of low blood sugar"
            ]
        )
    elif glucose > 250:
        return PreWorkoutRiskResponse(
            risk_level="high",
            can_exercise=False,
            current_glucose=glucose,
            recommendations=[
                "Blood glucose is too high for exercise",
                "Check ketones before exercising",
                "If ketones are present, do not exercise"
            ]
        )
    elif glucose > 180:
        return PreWorkoutRiskResponse(
            risk_level="moderate",
            can_exercise=True,
            current_glucose=glucose,
            recommendations=[
                "Blood glucose is elevated",
                "Stay well hydrated during exercise",
                "Monitor how you feel"
            ]
        )

    return PreWorkoutRiskResponse(
        risk_level="low",
        can_exercise=True,
        current_glucose=glucose,
        recommendations=recommendations
    )


@router.get("/exercise/{user_id}/impact", response_model=WorkoutGlucoseImpactResponse)
async def analyze_workout_glucose_impact(user_id: str, days: int = 30):
    """Analyze how workouts affect glucose levels."""
    # This would require workout data correlation
    # For now, return placeholder
    return WorkoutGlucoseImpactResponse(
        average_drop=None,
        workout_count=0,
        period_days=days
    )
