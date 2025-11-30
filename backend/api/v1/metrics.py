"""
Health Metrics API Router.

Provides endpoints for calculating and storing health metrics.
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

from services.metrics_calculator import MetricsCalculator, HealthMetrics
from core.supabase_db import get_supabase_db
from core.logger import get_logger

router = APIRouter(prefix="/metrics", tags=["metrics"])
logger = get_logger(__name__)


class MetricsInput(BaseModel):
    """Input for metrics calculation."""
    user_id: str  # UUID from Supabase
    weight_kg: float = Field(..., gt=0, description="Weight in kilograms")
    height_cm: float = Field(..., gt=0, description="Height in centimeters")
    age: int = Field(..., ge=1, le=120, description="Age in years")
    gender: str = Field(..., description="Gender: male or female")
    activity_level: str = Field(
        default="lightly_active",
        description="Activity level: sedentary, lightly_active, moderately_active, very_active, extremely_active"
    )
    target_weight_kg: Optional[float] = Field(None, gt=0, description="Target weight in kg")
    waist_cm: Optional[float] = Field(None, gt=0, description="Waist circumference in cm")
    hip_cm: Optional[float] = Field(None, gt=0, description="Hip circumference in cm")
    neck_cm: Optional[float] = Field(None, gt=0, description="Neck circumference in cm")
    body_fat_percent: Optional[float] = Field(None, ge=0, le=70, description="Body fat percentage")
    resting_heart_rate: Optional[int] = Field(None, ge=30, le=200, description="Resting heart rate in bpm")
    blood_pressure_systolic: Optional[int] = Field(None, ge=70, le=250, description="Systolic blood pressure")
    blood_pressure_diastolic: Optional[int] = Field(None, ge=40, le=150, description="Diastolic blood pressure")


class MetricsResponse(BaseModel):
    """Response containing calculated metrics."""
    # Core metrics
    bmi: float
    bmi_category: str
    bmi_interpretation: str
    target_bmi: Optional[float] = None

    # Ideal body weight
    ideal_body_weight_devine: float
    ideal_body_weight_robinson: float
    ideal_body_weight_miller: float
    ideal_body_weight_average: float

    # Metabolic rates
    bmr_mifflin: float
    bmr_harris: float
    tdee: float
    tdee_interpretation: str

    # Body composition (optional)
    waist_to_height_ratio: Optional[float] = None
    waist_to_hip_ratio: Optional[float] = None
    body_fat_navy: Optional[float] = None
    lean_body_mass: Optional[float] = None
    ffmi: Optional[float] = None

    # Input measurements echoed back
    weight_kg: float
    height_cm: float
    age: int
    gender: str
    activity_level: str


class MetricsHistoryItem(BaseModel):
    """Single metrics history entry."""
    id: int
    recorded_at: datetime
    weight_kg: Optional[float]
    bmi: Optional[float]
    bmi_category: Optional[str]
    bmr: Optional[float]
    tdee: Optional[float]
    body_fat: Optional[float]


def row_to_metrics_history_item(row: dict) -> MetricsHistoryItem:
    """Convert a Supabase row dict to MetricsHistoryItem model."""
    body_fat = row.get("body_fat_measured") or row.get("body_fat_calculated")
    return MetricsHistoryItem(
        id=row.get("id"),
        recorded_at=row.get("recorded_at"),
        weight_kg=row.get("weight_kg"),
        bmi=row.get("bmi"),
        bmi_category=row.get("bmi_category"),
        bmr=row.get("bmr"),
        tdee=row.get("tdee"),
        body_fat=body_fat,
    )


@router.post("/calculate", response_model=MetricsResponse)
async def calculate_metrics(input: MetricsInput):
    """
    Calculate health metrics from user measurements.

    This endpoint calculates BMI, BMR, TDEE, and ideal body weight
    based on the provided measurements without storing them.
    """
    logger.info(f"Calculating metrics for user {input.user_id}")

    calculator = MetricsCalculator()
    metrics = calculator.calculate_all(
        weight_kg=input.weight_kg,
        height_cm=input.height_cm,
        age=input.age,
        gender=input.gender,
        activity_level=input.activity_level,
        target_weight_kg=input.target_weight_kg,
        waist_cm=input.waist_cm,
        hip_cm=input.hip_cm,
        neck_cm=input.neck_cm,
        body_fat_percent=input.body_fat_percent,
    )

    # Calculate average IBW
    ibw_avg = round(
        (metrics.ideal_body_weight_devine +
         metrics.ideal_body_weight_robinson +
         metrics.ideal_body_weight_miller) / 3, 1
    )

    return MetricsResponse(
        bmi=metrics.bmi,
        bmi_category=metrics.bmi_category,
        bmi_interpretation=calculator.get_bmi_interpretation(metrics.bmi, metrics.bmi_category),
        target_bmi=metrics.target_bmi,
        ideal_body_weight_devine=metrics.ideal_body_weight_devine,
        ideal_body_weight_robinson=metrics.ideal_body_weight_robinson,
        ideal_body_weight_miller=metrics.ideal_body_weight_miller,
        ideal_body_weight_average=ibw_avg,
        bmr_mifflin=metrics.bmr_mifflin,
        bmr_harris=metrics.bmr_harris,
        tdee=metrics.tdee,
        tdee_interpretation=calculator.get_tdee_interpretation(metrics.tdee, input.activity_level),
        waist_to_height_ratio=metrics.waist_to_height_ratio,
        waist_to_hip_ratio=metrics.waist_to_hip_ratio,
        body_fat_navy=metrics.body_fat_navy,
        lean_body_mass=metrics.lean_body_mass,
        ffmi=metrics.ffmi,
        weight_kg=input.weight_kg,
        height_cm=input.height_cm,
        age=input.age,
        gender=input.gender,
        activity_level=input.activity_level,
    )


@router.post("/record", response_model=MetricsResponse)
async def record_metrics(input: MetricsInput):
    """
    Calculate and record metrics to the user's history.

    This endpoint calculates metrics AND stores them in the database
    for tracking progress over time.
    """
    logger.info(f"Recording metrics for user {input.user_id}")

    calculator = MetricsCalculator()
    metrics = calculator.calculate_all(
        weight_kg=input.weight_kg,
        height_cm=input.height_cm,
        age=input.age,
        gender=input.gender,
        activity_level=input.activity_level,
        target_weight_kg=input.target_weight_kg,
        waist_cm=input.waist_cm,
        hip_cm=input.hip_cm,
        neck_cm=input.neck_cm,
        body_fat_percent=input.body_fat_percent,
    )

    # Store in database
    db = get_supabase_db()

    metrics_data = {
        "user_id": input.user_id,
        "weight_kg": input.weight_kg,
        "waist_cm": input.waist_cm,
        "hip_cm": input.hip_cm,
        "neck_cm": input.neck_cm,
        "body_fat_measured": input.body_fat_percent,
        "resting_heart_rate": input.resting_heart_rate,
        "blood_pressure_systolic": input.blood_pressure_systolic,
        "blood_pressure_diastolic": input.blood_pressure_diastolic,
        "bmi": metrics.bmi,
        "bmi_category": metrics.bmi_category,
        "bmr": metrics.bmr_mifflin,
        "tdee": metrics.tdee,
        "body_fat_calculated": metrics.body_fat_navy,
        "lean_body_mass": metrics.lean_body_mass,
        "ffmi": metrics.ffmi,
        "waist_to_height_ratio": metrics.waist_to_height_ratio,
        "waist_to_hip_ratio": metrics.waist_to_hip_ratio,
        "ideal_body_weight": metrics.ideal_body_weight_devine,
    }

    created = db.create_user_metrics(metrics_data)
    logger.info(f"Recorded metrics with ID {created['id']} for user {input.user_id}")

    # Calculate average IBW
    ibw_avg = round(
        (metrics.ideal_body_weight_devine +
         metrics.ideal_body_weight_robinson +
         metrics.ideal_body_weight_miller) / 3, 1
    )

    return MetricsResponse(
        bmi=metrics.bmi,
        bmi_category=metrics.bmi_category,
        bmi_interpretation=calculator.get_bmi_interpretation(metrics.bmi, metrics.bmi_category),
        target_bmi=metrics.target_bmi,
        ideal_body_weight_devine=metrics.ideal_body_weight_devine,
        ideal_body_weight_robinson=metrics.ideal_body_weight_robinson,
        ideal_body_weight_miller=metrics.ideal_body_weight_miller,
        ideal_body_weight_average=ibw_avg,
        bmr_mifflin=metrics.bmr_mifflin,
        bmr_harris=metrics.bmr_harris,
        tdee=metrics.tdee,
        tdee_interpretation=calculator.get_tdee_interpretation(metrics.tdee, input.activity_level),
        waist_to_height_ratio=metrics.waist_to_height_ratio,
        waist_to_hip_ratio=metrics.waist_to_hip_ratio,
        body_fat_navy=metrics.body_fat_navy,
        lean_body_mass=metrics.lean_body_mass,
        ffmi=metrics.ffmi,
        weight_kg=input.weight_kg,
        height_cm=input.height_cm,
        age=input.age,
        gender=input.gender,
        activity_level=input.activity_level,
    )


@router.get("/history/{user_id}", response_model=List[MetricsHistoryItem])
async def get_metrics_history(user_id: str, limit: int = 30):
    """
    Get user's metrics history for progress tracking.

    Returns the most recent metrics entries, ordered by date descending.
    """
    logger.info(f"Fetching metrics history for user {user_id}")

    db = get_supabase_db()
    rows = db.list_user_metrics(user_id=user_id, limit=limit)

    return [row_to_metrics_history_item(row) for row in rows]


@router.get("/latest/{user_id}")
async def get_latest_metrics(user_id: str):
    """
    Get the most recent metrics for a user.

    Returns the latest calculated metrics or None if no history exists.
    """
    logger.info(f"Fetching latest metrics for user {user_id}")

    db = get_supabase_db()
    row = db.get_latest_user_metrics(user_id=user_id)

    if not row:
        return {"message": "No metrics history found", "has_metrics": False}

    body_fat = row.get("body_fat_measured") or row.get("body_fat_calculated")

    return {
        "has_metrics": True,
        "id": row.get("id"),
        "recorded_at": row.get("recorded_at"),
        "weight_kg": row.get("weight_kg"),
        "bmi": row.get("bmi"),
        "bmi_category": row.get("bmi_category"),
        "bmr": row.get("bmr"),
        "tdee": row.get("tdee"),
        "body_fat": body_fat,
        "lean_body_mass": row.get("lean_body_mass"),
        "ffmi": row.get("ffmi"),
        "waist_to_height_ratio": row.get("waist_to_height_ratio"),
        "waist_to_hip_ratio": row.get("waist_to_hip_ratio"),
        "ideal_body_weight": row.get("ideal_body_weight"),
    }


@router.delete("/history/{user_id}/{metric_id}")
async def delete_metric_entry(user_id: str, metric_id: int):
    """Delete a specific metrics entry."""
    logger.info(f"Deleting metric {metric_id} for user {user_id}")

    db = get_supabase_db()
    deleted = db.delete_user_metrics(metric_id=metric_id, user_id=user_id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Metric entry not found")

    return {"message": "Metric entry deleted successfully"}


# ============ INJURY ENDPOINTS ============

from services.injury_service import get_injury_service, Injury


@router.get("/injuries/active/{user_id}")
async def get_active_injuries(user_id: str):
    """
    Get all active injuries for a user with recovery status.

    Returns injury details including recovery phase, progress, and rehab exercises.
    """
    logger.info(f"Fetching active injuries for user {user_id}")

    db = get_supabase_db()
    injury_service = get_injury_service()

    # Get active injuries from database
    rows = db.get_active_injuries(user_id=user_id)

    injuries = []
    for row in rows:
        reported_at = row.get("reported_at")
        if isinstance(reported_at, str):
            reported_at = datetime.fromisoformat(reported_at.replace("Z", "+00:00"))

        expected_recovery = row.get("expected_recovery_date")
        if isinstance(expected_recovery, str):
            expected_recovery = datetime.fromisoformat(expected_recovery.replace("Z", "+00:00"))

        injury = Injury(
            id=row.get("id"),
            user_id=row.get("user_id"),
            body_part=row.get("body_part"),
            severity=row.get("severity"),
            reported_at=reported_at,
            expected_recovery_date=expected_recovery,
            pain_level=row.get("pain_level_current"),
            notes=row.get("improvement_notes"),
        )

        # Get recovery summary from service
        summary = injury_service.get_recovery_summary(injury)

        # Get rehab exercises for current phase
        rehab_exercises = injury_service.get_rehab_exercises(injury)
        rehab_names = [ex["name"] for ex in rehab_exercises]

        injuries.append({
            "id": injury.id,
            "body_part": injury.body_part,
            "severity": injury.severity,
            "reported_at": injury.reported_at.isoformat(),
            "expected_recovery_date": summary["expected_recovery_date"],
            "current_phase": summary["current_phase"],
            "phase_description": summary["phase_description"],
            "allowed_intensity": summary["allowed_intensity"],
            "days_since_injury": summary["days_since_injury"],
            "days_remaining": summary["days_remaining"],
            "progress_percent": summary["progress_percent"],
            "pain_level": injury.pain_level,
            "rehab_exercises": rehab_names,
        })

    return {"injuries": injuries, "count": len(injuries)}
