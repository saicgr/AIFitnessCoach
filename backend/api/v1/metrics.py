"""
Health Metrics API Router.

Provides endpoints for calculating and storing health metrics.
"""
import io

import pandas as pd
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse, JSONResponse
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


# ============ SIMPLE BODY MEASUREMENT ENDPOINTS ============
# These endpoints support the Flutter app's simple measurement recording

class SimpleMetricInput(BaseModel):
    """Simple input for recording a single body measurement."""
    user_id: str
    metric_type: str = Field(..., description="Type: weight, body_fat, chest, waist, hips, etc.")
    value: float = Field(..., gt=0, description="Measurement value")
    unit: str = Field(..., description="Unit: kg, lbs, cm, in, %")
    notes: Optional[str] = None


class SimpleMetricResponse(BaseModel):
    """Response for a single measurement entry."""
    id: str
    user_id: str
    metric_type: str
    value: float
    unit: str
    recorded_at: datetime
    notes: Optional[str] = None
    # Fasting context (auto-populated by database trigger when weight is logged)
    is_fasting_day: Optional[bool] = None
    fasting_record_id: Optional[str] = None
    fasting_protocol: Optional[str] = None
    fasting_duration_minutes: Optional[int] = None
    days_since_last_fast: Optional[int] = None


# Mapping from metric_type to body_measurements column names
METRIC_TYPE_TO_COLUMN = {
    "weight": "weight_kg",
    "body_fat": "body_fat_percent",
    "chest": "chest_cm",
    "waist": "waist_cm",
    "hips": "hip_cm",
    "neck": "neck_cm",
    "shoulders": "shoulder_cm",
    "biceps_left": "bicep_left_cm",
    "biceps_right": "bicep_right_cm",
    "forearm_left": "forearm_left_cm",
    "forearm_right": "forearm_right_cm",
    "thigh_left": "thigh_left_cm",
    "thigh_right": "thigh_right_cm",
    "calf_left": "calf_left_cm",
    "calf_right": "calf_right_cm",
}


def _convert_to_metric(value: float, unit: str, metric_type: str) -> float:
    """Convert value to metric units for storage."""
    if metric_type == "body_fat":
        return value  # percentage doesn't need conversion
    if unit == "lbs":
        return value / 2.20462  # to kg
    if unit == "in":
        return value * 2.54  # to cm
    return value  # already metric


@router.post("/body/record", response_model=SimpleMetricResponse, tags=["body-measurements"])
async def record_simple_metric(input: SimpleMetricInput):
    """
    Record a simple body measurement (weight, body fat, circumferences, etc.)

    This is a simplified endpoint for recording individual measurements
    without requiring full health metrics calculation.
    """
    logger.info(f"Recording simple metric {input.metric_type} for user {input.user_id}")

    db = get_supabase_db()

    # Get the column name for this metric type
    column_name = METRIC_TYPE_TO_COLUMN.get(input.metric_type)
    if not column_name:
        raise HTTPException(status_code=400, detail=f"Unknown metric type: {input.metric_type}")

    # Convert to metric units for storage
    metric_value = _convert_to_metric(input.value, input.unit, input.metric_type)

    # Insert into body_measurements table
    data = {
        "user_id": input.user_id,
        column_name: metric_value,
        "notes": input.notes,
        "measurement_source": "manual",
    }

    try:
        result = db.client.table("body_measurements").insert(data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to record measurement")

        row = result.data[0]

        # For weight measurements, fasting context is auto-populated by database trigger
        # We need to re-fetch the row to get the trigger-populated fasting fields
        if input.metric_type == "weight":
            refetch = db.client.table("body_measurements").select("*").eq("id", row["id"]).single().execute()
            if refetch.data:
                row = refetch.data

        return SimpleMetricResponse(
            id=str(row["id"]),
            user_id=row["user_id"],
            metric_type=input.metric_type,
            value=metric_value,
            unit="kg" if input.metric_type == "weight" else ("%" if input.metric_type == "body_fat" else "cm"),
            recorded_at=row.get("measured_at") or row.get("created_at"),
            notes=row.get("notes"),
            # Fasting context (populated by trigger for weight measurements)
            is_fasting_day=row.get("is_fasting_day"),
            fasting_record_id=str(row["fasting_record_id"]) if row.get("fasting_record_id") else None,
            fasting_protocol=row.get("fasting_protocol"),
            fasting_duration_minutes=row.get("fasting_duration_minutes"),
            days_since_last_fast=row.get("days_since_last_fast"),
        )
    except Exception as e:
        logger.error(f"Failed to record measurement: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/body/history/{user_id}", response_model=List[SimpleMetricResponse], tags=["body-measurements"])
async def get_body_measurement_history(
    user_id: str,
    metric_type: Optional[str] = None,
    limit: int = 50
):
    """
    Get measurement history for a user.

    If metric_type is provided, returns only measurements of that type.
    Otherwise returns all measurements.
    """
    logger.info(f"Getting measurement history for user {user_id}, type={metric_type}")

    db = get_supabase_db()

    try:
        # Build the query based on metric_type
        if metric_type:
            column_name = METRIC_TYPE_TO_COLUMN.get(metric_type)
            if not column_name:
                return []  # Unknown type, return empty

            # Query for non-null values of the specific column
            result = db.client.table("body_measurements") \
                .select("*") \
                .eq("user_id", user_id) \
                .not_.is_(column_name, "null") \
                .order("measured_at", desc=True) \
                .limit(limit) \
                .execute()

            # Map results to response format
            entries = []
            for row in result.data:
                value = row.get(column_name)
                if value is not None:
                    entries.append(SimpleMetricResponse(
                        id=str(row["id"]),
                        user_id=row["user_id"],
                        metric_type=metric_type,
                        value=value,
                        unit="kg" if metric_type == "weight" else ("%" if metric_type == "body_fat" else "cm"),
                        recorded_at=row.get("measured_at") or row.get("created_at"),
                        notes=row.get("notes"),
                        # Fasting context for weight measurements
                        is_fasting_day=row.get("is_fasting_day") if metric_type == "weight" else None,
                        fasting_record_id=str(row["fasting_record_id"]) if row.get("fasting_record_id") else None,
                        fasting_protocol=row.get("fasting_protocol") if metric_type == "weight" else None,
                        fasting_duration_minutes=row.get("fasting_duration_minutes") if metric_type == "weight" else None,
                        days_since_last_fast=row.get("days_since_last_fast") if metric_type == "weight" else None,
                    ))
            return entries
        else:
            # Return all measurements, flattened
            result = db.client.table("body_measurements") \
                .select("*") \
                .eq("user_id", user_id) \
                .order("measured_at", desc=True) \
                .limit(limit) \
                .execute()

            entries = []
            for row in result.data:
                for metric_type_key, column in METRIC_TYPE_TO_COLUMN.items():
                    value = row.get(column)
                    if value is not None:
                        entries.append(SimpleMetricResponse(
                            id=str(row["id"]),
                            user_id=row["user_id"],
                            metric_type=metric_type_key,
                            value=value,
                            unit="kg" if metric_type_key == "weight" else ("%" if metric_type_key == "body_fat" else "cm"),
                            recorded_at=row.get("measured_at") or row.get("created_at"),
                            notes=row.get("notes"),
                        ))
            return entries

    except Exception as e:
        logger.error(f"Failed to get measurement history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/body/history/{user_id}/{measurement_id}", tags=["body-measurements"])
async def delete_body_measurement(user_id: str, measurement_id: str):
    """Delete a specific body measurement entry."""
    logger.info(f"Deleting measurement {measurement_id} for user {user_id}")

    db = get_supabase_db()

    try:
        result = db.client.table("body_measurements") \
            .delete() \
            .eq("id", measurement_id) \
            .eq("user_id", user_id) \
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Measurement not found")

        return {"message": "Measurement deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete measurement: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/body/grouped/{user_id}", tags=["body-measurements"])
async def get_grouped_body_measurements(user_id: str, limit: int = 300):
    """
    Fetch ALL measurement types in a single query, grouped by type.
    Replaces 15 per-type API calls with one.
    """
    logger.info(f"Fetching grouped body measurements for user {user_id}")

    db = get_supabase_db()

    select_cols = ",".join([
        "id", "user_id", "measured_at", "created_at", "notes",
        *METRIC_TYPE_TO_COLUMN.values(),
        "is_fasting_day", "fasting_record_id", "fasting_protocol",
        "fasting_duration_minutes", "days_since_last_fast",
    ])

    try:
        result = db.client.table("body_measurements") \
            .select(select_cols) \
            .eq("user_id", user_id) \
            .order("measured_at", desc=True) \
            .limit(limit) \
            .execute()

        # Group: iterate rows once, unpack non-null columns into per-type lists
        grouped = {mt: [] for mt in METRIC_TYPE_TO_COLUMN}
        for row in result.data:
            for metric_type, column in METRIC_TYPE_TO_COLUMN.items():
                value = row.get(column)
                if value is not None:
                    entry = {
                        "id": str(row["id"]),
                        "user_id": row["user_id"],
                        "metric_type": metric_type,
                        "value": value,
                        "unit": "kg" if metric_type == "weight" else (
                            "%" if metric_type == "body_fat" else "cm"),
                        "recorded_at": row.get("measured_at") or row.get("created_at"),
                        "notes": row.get("notes"),
                    }
                    if metric_type == "weight":
                        entry["is_fasting_day"] = row.get("is_fasting_day")
                        entry["fasting_record_id"] = (
                            str(row["fasting_record_id"])
                            if row.get("fasting_record_id") else None)
                        entry["fasting_protocol"] = row.get("fasting_protocol")
                        entry["fasting_duration_minutes"] = row.get(
                            "fasting_duration_minutes")
                        entry["days_since_last_fast"] = row.get("days_since_last_fast")
                    grouped[metric_type].append(entry)

        return grouped
    except Exception as e:
        logger.error(f"Failed to get grouped measurements: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ BODY MEASUREMENTS EXPORT ============


@router.get("/body/export/{user_id}", tags=["body-measurements"])
async def export_body_measurements(
    user_id: str,
    format: str = "csv",
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    types: Optional[str] = None,
):
    """
    Export body measurements in the specified format.

    Query parameters:
    - format: "csv", "json", "xlsx", or "parquet". Default: "csv"
    - start_date: Optional ISO date (YYYY-MM-DD) filter
    - end_date: Optional ISO date (YYYY-MM-DD) filter
    - types: Optional comma-separated measurement types to include (e.g. "weight,waist,body_fat"). Default: all types.
    """
    if format not in ("csv", "json", "xlsx", "parquet"):
        raise HTTPException(status_code=400, detail=f"Unsupported format: {format}. Use csv, json, xlsx, or parquet.")

    # Parse types filter
    allowed_types = None
    if types:
        allowed_types = set(t.strip() for t in types.split(",") if t.strip())
        invalid = allowed_types - set(METRIC_TYPE_TO_COLUMN.keys())
        if invalid:
            raise HTTPException(status_code=400, detail=f"Unknown measurement types: {', '.join(invalid)}. Valid types: {', '.join(METRIC_TYPE_TO_COLUMN.keys())}")

    logger.info(f"Exporting body measurements for user {user_id}, format={format}, types={allowed_types}")

    db = get_supabase_db()

    try:
        query = db.client.table("body_measurements") \
            .select("*") \
            .eq("user_id", user_id) \
            .order("measured_at", desc=True)

        if start_date:
            query = query.gte("measured_at", start_date)
        if end_date:
            query = query.lte("measured_at", end_date + "T23:59:59Z")

        result = query.limit(5000).execute()
        rows = result.data or []

        # Flatten: for each row, for each metric column with a non-null value, create a record
        UNIT_MAP = {
            "weight": "kg",
            "body_fat": "%",
        }
        flat_rows = []
        for row in rows:
            date = row.get("measured_at") or row.get("created_at", "")
            notes = row.get("notes", "")
            for metric_type, column in METRIC_TYPE_TO_COLUMN.items():
                if allowed_types and metric_type not in allowed_types:
                    continue
                value = row.get(column)
                if value is not None:
                    flat_rows.append({
                        "date": date,
                        "type": metric_type,
                        "value": value,
                        "unit": UNIT_MAP.get(metric_type, "cm"),
                        "notes": notes,
                    })

        df = pd.DataFrame(flat_rows) if flat_rows else pd.DataFrame(columns=["date", "type", "value", "unit", "notes"])

        date_str = datetime.utcnow().strftime("%Y-%m-%d")

        if format == "json":
            records = df.to_dict(orient="records")
            return JSONResponse(
                content=records,
                headers={
                    "Content-Disposition": f'attachment; filename="body_measurements_{date_str}.json"',
                }
            )

        elif format == "xlsx":
            buf = io.BytesIO()
            df.to_excel(buf, index=False, engine="openpyxl")
            buf.seek(0)
            xlsx_bytes = buf.getvalue()
            return StreamingResponse(
                io.BytesIO(xlsx_bytes),
                media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                headers={
                    "Content-Disposition": f'attachment; filename="body_measurements_{date_str}.xlsx"',
                    "Content-Length": str(len(xlsx_bytes)),
                }
            )

        elif format == "parquet":
            buf = io.BytesIO()
            df.to_parquet(buf, engine="pyarrow", index=False)
            buf.seek(0)
            parquet_bytes = buf.getvalue()
            return StreamingResponse(
                io.BytesIO(parquet_bytes),
                media_type="application/octet-stream",
                headers={
                    "Content-Disposition": f'attachment; filename="body_measurements_{date_str}.parquet"',
                    "Content-Length": str(len(parquet_bytes)),
                }
            )

        else:
            # CSV
            csv_str = df.to_csv(index=False)
            csv_bytes = csv_str.encode("utf-8")
            return StreamingResponse(
                io.BytesIO(csv_bytes),
                media_type="text/csv",
                headers={
                    "Content-Disposition": f'attachment; filename="body_measurements_{date_str}.csv"',
                    "Content-Length": str(len(csv_bytes)),
                }
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to export body measurements: {e}")
        raise HTTPException(status_code=500, detail=str(e))
