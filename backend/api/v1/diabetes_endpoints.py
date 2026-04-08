"""Secondary endpoints for diabetes.  Sub-router included by main module.
Diabetes Tracking API endpoints.

Comprehensive diabetes management for Type 1, Type 2, and other diabetes types.
Includes blood glucose logging, insulin tracking, A1C management, carbohydrate
counting, and Health Connect integration.
"""
from typing import Optional
from datetime import datetime, timedelta, date
import uuid
from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error


def _diabetes_parent():
    """Lazy import to avoid circular dependency."""
    from .diabetes import glucose_to_a1c, classify_glucose_status
    return glucose_to_a1c, classify_glucose_status


from .diabetes_models import (
    CreateDiabetesProfileRequest,
    DiabetesProfileResponse,
    UpdateGlucoseTargetsRequest,
    LogGlucoseReadingRequest,
    GlucoseReadingResponse,
    GlucoseHistoryResponse,
    GlucoseSummaryResponse,
    GlucoseStatusResponse,
    LogInsulinDoseRequest,
    InsulinDoseResponse,
    DailyInsulinTotalResponse,
    InsulinHistoryResponse,
    LogA1cRequest,
    A1cResultResponse,
    A1cHistoryResponse,
    A1cTrendResponse,
    EstimatedA1cResponse,
    AddMedicationRequest,
    MedicationResponse,
    MedicationsListResponse,
    UpdateMedicationRequest,
    LogCarbEntryRequest,
    CarbEntryResponse,
    DailyCarbTotalResponse,
    CarbCorrelationResponse,
    CreateGlucoseAlertRequest,
    GlucoseAlertResponse,
    UpdateGlucoseAlertRequest,
    AlertTriggeredResponse,
    TimeInRangeResponse,
    VariabilityResponse,
    GlucosePattern,
    PatternsResponse,
    DashboardDataResponse,
    PreWorkoutRiskResponse,
    WorkoutGlucoseImpactResponse,
    HealthConnectSyncRequest,
    HealthConnectSyncResponse,
)

router = APIRouter()

@router.get("/a1c/{user_id}/estimated", response_model=EstimatedA1cResponse)
async def calculate_estimated_a1c(user_id: str, days: int = 90, current_user: dict = Depends(get_current_user)):
    """Calculate estimated A1C from glucose readings."""
    glucose_to_a1c, classify_glucose_status = _diabetes_parent()
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def add_medication(request: AddMedicationRequest, current_user: dict = Depends(get_current_user)):
    """Add a diabetes medication."""
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        raise safe_internal_error(Exception("Failed to add medication"), "diabetes")

    return MedicationResponse(**result.data[0])


@router.get("/medications/{user_id}", response_model=MedicationsListResponse)
async def get_active_medications(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get list of active medications."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    result = db.client.table("diabetes_medications").select("*").eq(
        "user_id", user_id
    ).eq("is_active", True).execute()

    medications = [MedicationResponse(**m) for m in (result.data or [])]

    return MedicationsListResponse(medications=medications)


@router.patch("/medications/{user_id}/{medication_id}/deactivate", response_model=MedicationResponse)
async def deactivate_medication(user_id: str, medication_id: str, current_user: dict = Depends(get_current_user)):
    """Deactivate a medication."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def update_medication(user_id: str, medication_id: str, request: UpdateMedicationRequest, current_user: dict = Depends(get_current_user)):
    """Update a medication."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def log_carb_entry(request: LogCarbEntryRequest, current_user: dict = Depends(get_current_user)):
    """Log a carbohydrate entry."""
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        raise safe_internal_error(Exception("Failed to log carb entry"), "diabetes")

    return CarbEntryResponse(**result.data[0])


@router.get("/carbs/{user_id}/daily", response_model=DailyCarbTotalResponse)
async def get_daily_carb_total(user_id: str, date: Optional[str] = None, current_user: dict = Depends(get_current_user)):
    """Get total carbs for a day."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def get_carb_glucose_correlation(user_id: str, days: int = 30, current_user: dict = Depends(get_current_user)):
    """Get carb-to-glucose correlation analysis."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def create_glucose_alert(request: CreateGlucoseAlertRequest, current_user: dict = Depends(get_current_user)):
    """Create a glucose alert configuration."""
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
        raise safe_internal_error(Exception("Failed to create alert"), "diabetes")

    return GlucoseAlertResponse(**result.data[0])


@router.get("/alerts/{user_id}/check", response_model=AlertTriggeredResponse)
async def check_alert_triggered(user_id: str, glucose_value: float, current_user: dict = Depends(get_current_user)):
    """Check if any alerts should be triggered."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def update_glucose_alert(user_id: str, alert_id: str, request: UpdateGlucoseAlertRequest, current_user: dict = Depends(get_current_user)):
    """Update a glucose alert."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
    target_max: float = 180,
    current_user: dict = Depends(get_current_user),
):
    """Calculate time in range percentage."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def calculate_glucose_variability(user_id: str, days: int = 7, current_user: dict = Depends(get_current_user)):
    """Calculate glucose variability metrics."""
    glucose_to_a1c, classify_glucose_status = _diabetes_parent()
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def detect_glucose_patterns(user_id: str, days: int = 14, current_user: dict = Depends(get_current_user)):
    """Detect glucose patterns."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def get_dashboard_data(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get comprehensive dashboard data."""
    glucose_to_a1c, classify_glucose_status = _diabetes_parent()
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def assess_pre_workout_risk(user_id: str, current_user: dict = Depends(get_current_user)):
    """Assess glucose risk before workout."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
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
async def analyze_workout_glucose_impact(user_id: str, days: int = 30, current_user: dict = Depends(get_current_user)):
    """Analyze how workouts affect glucose levels."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    # This would require workout data correlation
    # For now, return placeholder
    return WorkoutGlucoseImpactResponse(
        average_drop=None,
        workout_count=0,
        period_days=days
    )
