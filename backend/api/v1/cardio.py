"""
Cardio API Endpoints
====================
Handles heart rate zones, cardio metrics, cardio sessions, and endurance training features.

Endpoints:
- GET /cardio/hr-zones/{user_id} - Get personalized heart rate training zones
- GET /cardio/metrics/{user_id} - Get full cardio metrics including VO2 max estimate
- POST /cardio/metrics - Save measured cardio metrics (custom max HR, resting HR)
- GET /cardio/metrics/history/{user_id} - Get cardio metrics history

Cardio Sessions:
- POST /cardio/sessions - Create a new cardio session
- GET /cardio/sessions/{user_id} - List cardio sessions with filters
- GET /cardio/sessions/{user_id}/{session_id} - Get a specific session
- PUT /cardio/sessions/{session_id} - Update a session
- DELETE /cardio/sessions/{session_id} - Delete a session
- GET /cardio/sessions/{user_id}/stats - Get aggregate cardio statistics
"""

from .cardio_models import *  # noqa: F401, F403
from .cardio_endpoints import router as _endpoints_router


from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from decimal import Decimal

from core.db import get_supabase_db
from services.cardio import (
    calculate_max_hr,
    calculate_hr_zones,
    calculate_age_from_dob,
    estimate_vo2_max,
    get_fitness_age,
    get_cardio_metrics,
    CardioMetrics,
)
from models.cardio_session import (
    CardioType,
    CardioLocation,
    CardioSessionCreate,
    CardioSessionUpdate,
    CardioSession,
    CardioSessionSummary,
    CardioSessionsListResponse,
    CardioTypeStats,
    CardioSessionStatsResponse,
)

from core.auth import get_current_user
from core.exceptions import safe_internal_error

import logging
logger = logging.getLogger(__name__)

router = APIRouter()


# ============================================================================
# Pydantic Models
# ============================================================================

class HRZoneResponse(BaseModel):
    """Heart rate zone with BPM ranges and metadata."""
    min: int = Field(..., description="Minimum heart rate for this zone in BPM")
    max: int = Field(..., description="Maximum heart rate for this zone in BPM")
    name: str = Field(..., description="Zone name (e.g., 'Recovery', 'Aerobic Base')")
    benefit: str = Field(..., description="Training benefit of this zone")
    color: str = Field(..., description="Hex color code for UI display")


class HRZonesResponse(BaseModel):
    """Complete heart rate zones response."""
    user_id: str
    max_hr: int = Field(..., description="Maximum heart rate used for calculation")
    resting_hr: Optional[int] = Field(None, description="Resting heart rate if provided")
    method: str = Field(..., description="Calculation method used: 'tanaka', 'traditional', or 'karvonen'")
    zone1_recovery: HRZoneResponse
    zone2_aerobic: HRZoneResponse
    zone3_tempo: HRZoneResponse
    zone4_threshold: HRZoneResponse
    zone5_max: HRZoneResponse
    calculated_at: datetime


class CardioMetricsResponse(BaseModel):
    """Full cardio metrics response including VO2 max and fitness age."""
    user_id: str
    max_hr: int = Field(..., description="Maximum heart rate in BPM")
    resting_hr: Optional[int] = Field(None, description="Resting heart rate in BPM")
    vo2_max_estimate: Optional[float] = Field(None, description="Estimated VO2 max in ml/kg/min")
    fitness_age: Optional[int] = Field(None, description="Calculated fitness age based on VO2 max")
    actual_age: int = Field(..., description="User's chronological age")
    source: str = Field(..., description="Data source: 'calculated', 'measured', or 'health_kit'")
    hr_zones: Dict[str, HRZoneResponse]
    calculated_at: datetime


class SaveCardioMetricsRequest(BaseModel):
    """Request to save measured cardio metrics."""
    user_id: str
    max_hr: Optional[int] = Field(None, ge=100, le=220, description="Measured max heart rate")
    resting_hr: Optional[int] = Field(None, ge=30, le=100, description="Resting heart rate")
    vo2_max_measured: Optional[float] = Field(None, ge=10, le=100, description="Measured VO2 max")
    source: str = Field("manual", description="Source of data: 'manual', 'health_kit', 'fitness_test'")


class CardioMetricsHistoryEntry(BaseModel):
    """Single cardio metrics history entry."""
    id: str
    max_hr: Optional[int]
    resting_hr: Optional[int]
    vo2_max_estimate: Optional[float]
    fitness_age: Optional[int]
    source: str
    measured_at: datetime


class CardioMetricsHistoryResponse(BaseModel):
    """Cardio metrics history response."""
    user_id: str
    entries: List[CardioMetricsHistoryEntry]
    trend: str = Field(..., description="Trend direction: 'improving', 'maintaining', 'declining'")
    avg_resting_hr_30d: Optional[float] = Field(None, description="Average resting HR over 30 days")


# ============================================================================
# HR Zones Endpoints
# ============================================================================

@router.get("/hr-zones/{user_id}", response_model=HRZonesResponse, tags=["Cardio"])
async def get_hr_zones(
    user_id: str,
    use_resting_hr: bool = Query(True, description="Use Karvonen formula if resting HR available"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get personalized heart rate training zones for a user.

    Uses the Tanaka formula for max HR estimation (208 - 0.7 * age),
    which is more accurate than the traditional 220 - age formula.

    If resting heart rate is available and use_resting_hr is True,
    uses the Karvonen formula for more personalized zones based on
    heart rate reserve.

    Returns 5 training zones:
    - Zone 1 (Recovery): 50-60% - Warm-up, cool-down
    - Zone 2 (Aerobic Base): 60-70% - Fat burning, endurance
    - Zone 3 (Tempo): 70-80% - Aerobic capacity
    - Zone 4 (Threshold): 80-90% - Lactate threshold
    - Zone 5 (VO2 Max): 90-100% - Peak performance
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    # Get user data including DOB and resting HR
    user_response = db.client.table("users").select(
        "id, date_of_birth, gender"
    ).eq("id", user_id).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = user_response.data
    dob_str = user.get("date_of_birth")

    if not dob_str:
        raise HTTPException(
            status_code=400,
            detail="Date of birth not set. Please update your profile to calculate HR zones."
        )

    # Calculate age from DOB
    dob = date.fromisoformat(dob_str) if isinstance(dob_str, str) else dob_str
    age = calculate_age_from_dob(dob)

    # Calculate max HR
    max_hr = calculate_max_hr(age, method="tanaka")

    # Try to get resting HR from latest cardio metrics or health data
    resting_hr = None
    method = "tanaka"

    if use_resting_hr:
        # Check cardio_metrics table first
        cardio_response = db.client.table("cardio_metrics").select(
            "resting_hr, max_hr, source"
        ).eq("user_id", user_id).order(
            "measured_at", desc=True
        ).limit(1).maybe_single().execute()

        if cardio_response.data:
            # Use stored max HR if available (measured is more accurate)
            if cardio_response.data.get("max_hr"):
                max_hr = cardio_response.data["max_hr"]
            resting_hr = cardio_response.data.get("resting_hr")

        # Fall back to health metrics if no cardio metrics
        if resting_hr is None:
            health_response = db.client.table("health_metrics").select(
                "resting_heart_rate"
            ).eq("user_id", user_id).order(
                "recorded_at", desc=True
            ).limit(1).maybe_single().execute()

            if health_response.data:
                resting_hr = health_response.data.get("resting_heart_rate")

        if resting_hr:
            method = "karvonen"

    # Calculate HR zones
    zones = calculate_hr_zones(max_hr, resting_hr)

    return HRZonesResponse(
        user_id=user_id,
        max_hr=max_hr,
        resting_hr=resting_hr,
        method=method,
        zone1_recovery=HRZoneResponse(**zones["zone1_recovery"]),
        zone2_aerobic=HRZoneResponse(**zones["zone2_aerobic"]),
        zone3_tempo=HRZoneResponse(**zones["zone3_tempo"]),
        zone4_threshold=HRZoneResponse(**zones["zone4_threshold"]),
        zone5_max=HRZoneResponse(**zones["zone5_max"]),
        calculated_at=datetime.now(),
    )


# ============================================================================
# Cardio Metrics Endpoints
# ============================================================================

@router.get("/metrics/{user_id}", response_model=CardioMetricsResponse, tags=["Cardio"])
async def get_cardio_metrics_endpoint(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get comprehensive cardio metrics for a user.

    Includes:
    - Max heart rate (calculated or measured)
    - Resting heart rate (if available)
    - VO2 max estimate (if resting HR available)
    - Fitness age (if VO2 max calculated)
    - All 5 heart rate training zones

    VO2 max is estimated using the Uth-Sorensen formula:
    VO2 max = 15.3 x (Max HR / Resting HR)

    Fitness age represents the age of an average person with
    the same cardiovascular fitness level.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    # Get user data
    user_response = db.client.table("users").select(
        "id, date_of_birth, gender, weight_kg"
    ).eq("id", user_id).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = user_response.data
    dob_str = user.get("date_of_birth")

    if not dob_str:
        raise HTTPException(
            status_code=400,
            detail="Date of birth not set. Please update your profile."
        )

    dob = date.fromisoformat(dob_str) if isinstance(dob_str, str) else dob_str
    age = calculate_age_from_dob(dob)
    gender = user.get("gender", "male")

    # Get stored cardio metrics
    resting_hr = None
    custom_max_hr = None
    source = "calculated"

    cardio_response = db.client.table("cardio_metrics").select("*").eq(
        "user_id", user_id
    ).order(
        "measured_at", desc=True
    ).limit(1).maybe_single().execute()

    if cardio_response.data:
        resting_hr = cardio_response.data.get("resting_hr")
        custom_max_hr = cardio_response.data.get("max_hr")
        source = cardio_response.data.get("source", "calculated")

    # Fall back to health metrics for resting HR
    if resting_hr is None:
        health_response = db.client.table("health_metrics").select(
            "resting_heart_rate"
        ).eq("user_id", user_id).order(
            "recorded_at", desc=True
        ).limit(1).maybe_single().execute()

        if health_response.data:
            resting_hr = health_response.data.get("resting_heart_rate")

    # Calculate all cardio metrics
    metrics = get_cardio_metrics(
        age=age,
        resting_hr=resting_hr,
        gender=gender,
        max_hr_method="tanaka",
        custom_max_hr=custom_max_hr,
    )

    # Build zones response
    zones_response = {
        key: HRZoneResponse(**zone_data)
        for key, zone_data in metrics.hr_zones.items()
    }

    return CardioMetricsResponse(
        user_id=user_id,
        max_hr=metrics.max_hr,
        resting_hr=metrics.resting_hr,
        vo2_max_estimate=metrics.vo2_max_estimate,
        fitness_age=metrics.fitness_age,
        actual_age=age,
        source=metrics.source,
        hr_zones=zones_response,
        calculated_at=datetime.now(),
    )


@router.post("/metrics", response_model=CardioMetricsResponse, tags=["Cardio"])
async def save_cardio_metrics(
    request: SaveCardioMetricsRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Save measured cardio metrics for a user.

    Users can record:
    - Measured max heart rate (from fitness test)
    - Resting heart rate (measured in the morning)
    - Measured VO2 max (from lab test)

    Measured values are more accurate than calculated estimates.
    """
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    # Verify user exists and get their data
    user_response = db.client.table("users").select(
        "id, date_of_birth, gender"
    ).eq("id", request.user_id).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    user = user_response.data
    dob_str = user.get("date_of_birth")

    if not dob_str:
        raise HTTPException(
            status_code=400,
            detail="Date of birth not set. Please update your profile."
        )

    dob = date.fromisoformat(dob_str) if isinstance(dob_str, str) else dob_str
    age = calculate_age_from_dob(dob)
    gender = user.get("gender", "male")

    # Calculate VO2 max and fitness age if possible
    vo2_max = request.vo2_max_measured
    fitness_age = None

    if vo2_max is None and request.resting_hr and request.max_hr:
        vo2_max = estimate_vo2_max(request.resting_hr, age, gender)

    if vo2_max:
        fitness_age = get_fitness_age(age, vo2_max, gender)

    # Prepare record data
    record_data = {
        "user_id": request.user_id,
        "max_hr": request.max_hr,
        "resting_hr": request.resting_hr,
        "vo2_max_estimate": vo2_max,
        "fitness_age": fitness_age,
        "source": request.source,
        "measured_at": datetime.now().isoformat(),
    }

    # Insert new record
    response = db.client.table("cardio_metrics").insert(record_data).execute()

    if not response.data:
        raise safe_internal_error(Exception("Failed to save cardio metrics"), "save_cardio_metrics")

    # Calculate full metrics for response
    metrics = get_cardio_metrics(
        age=age,
        resting_hr=request.resting_hr,
        gender=gender,
        max_hr_method="tanaka",
        custom_max_hr=request.max_hr,
    )

    zones_response = {
        key: HRZoneResponse(**zone_data)
        for key, zone_data in metrics.hr_zones.items()
    }

    return CardioMetricsResponse(
        user_id=request.user_id,
        max_hr=metrics.max_hr,
        resting_hr=metrics.resting_hr,
        vo2_max_estimate=vo2_max,
        fitness_age=fitness_age,
        actual_age=age,
        source=request.source,
        hr_zones=zones_response,
        calculated_at=datetime.now(),
    )


@router.get("/metrics/history/{user_id}", response_model=CardioMetricsHistoryResponse, tags=["Cardio"])
async def get_cardio_metrics_history(
    user_id: str,
    days: int = Query(90, ge=7, le=365, description="Number of days of history to retrieve"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get cardio metrics history for a user.

    Returns historical entries and trend analysis.
    Useful for tracking improvements in resting HR over time.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    # Verify user exists
    user_response = db.client.table("users").select("id").eq(
        "id", user_id
    ).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    # Get history
    start_date = (datetime.now() - timedelta(days=days)).isoformat()

    history_response = db.client.table("cardio_metrics").select("*").eq(
        "user_id", user_id
    ).gte(
        "measured_at", start_date
    ).order(
        "measured_at", desc=True
    ).execute()

    entries = [
        CardioMetricsHistoryEntry(
            id=entry["id"],
            max_hr=entry.get("max_hr"),
            resting_hr=entry.get("resting_hr"),
            vo2_max_estimate=entry.get("vo2_max_estimate"),
            fitness_age=entry.get("fitness_age"),
            source=entry.get("source", "calculated"),
            measured_at=datetime.fromisoformat(entry["measured_at"]),
        )
        for entry in (history_response.data or [])
    ]

    # Calculate trend based on resting HR (lower is better)
    trend = "maintaining"
    resting_hrs = [e.resting_hr for e in entries if e.resting_hr is not None]

    if len(resting_hrs) >= 2:
        recent_avg = sum(resting_hrs[:3]) / min(3, len(resting_hrs))
        older_avg = sum(resting_hrs[-3:]) / min(3, len(resting_hrs))

        if recent_avg < older_avg - 2:
            trend = "improving"
        elif recent_avg > older_avg + 2:
            trend = "declining"

    # Calculate 30-day average
    thirty_days_ago = datetime.now() - timedelta(days=30)
    recent_resting_hrs = [
        e.resting_hr for e in entries
        if e.resting_hr is not None and e.measured_at >= thirty_days_ago
    ]
    avg_resting_hr_30d = (
        round(sum(recent_resting_hrs) / len(recent_resting_hrs), 1)
        if recent_resting_hrs else None
    )

    return CardioMetricsHistoryResponse(
        user_id=user_id,
        entries=entries,
        trend=trend,
        avg_resting_hr_30d=avg_resting_hr_30d,
    )


# ============================================================================
# Cardio Session Endpoints
# ============================================================================

def _parse_cardio_session(data: dict) -> CardioSession:
    """Parse a database row into a CardioSession model."""
    return CardioSession(
        id=data["id"],
        user_id=data["user_id"],
        workout_id=data.get("workout_id"),
        cardio_type=CardioType(data["cardio_type"]),
        location=CardioLocation(data["location"]),
        distance_km=float(data["distance_km"]) if data.get("distance_km") is not None else None,
        duration_minutes=data["duration_minutes"],
        avg_pace_per_km=data.get("avg_pace_per_km"),
        avg_speed_kmh=float(data["avg_speed_kmh"]) if data.get("avg_speed_kmh") is not None else None,
        elevation_gain_m=data.get("elevation_gain_m"),
        avg_heart_rate=data.get("avg_heart_rate"),
        max_heart_rate=data.get("max_heart_rate"),
        calories_burned=data.get("calories_burned"),
        notes=data.get("notes"),
        weather_conditions=data.get("weather_conditions"),
        created_at=datetime.fromisoformat(data["created_at"].replace("Z", "+00:00")) if isinstance(data["created_at"], str) else data["created_at"],
        updated_at=datetime.fromisoformat(data["updated_at"].replace("Z", "+00:00")) if isinstance(data["updated_at"], str) else data["updated_at"],
    )


def _parse_cardio_session_summary(data: dict) -> CardioSessionSummary:
    """Parse a database row into a CardioSessionSummary model."""
    return CardioSessionSummary(
        id=data["id"],
        cardio_type=CardioType(data["cardio_type"]),
        location=CardioLocation(data["location"]),
        distance_km=float(data["distance_km"]) if data.get("distance_km") is not None else None,
        duration_minutes=data["duration_minutes"],
        avg_pace_per_km=data.get("avg_pace_per_km"),
        calories_burned=data.get("calories_burned"),
        created_at=datetime.fromisoformat(data["created_at"].replace("Z", "+00:00")) if isinstance(data["created_at"], str) else data["created_at"],
    )


@router.post("/sessions", response_model=CardioSession, tags=["Cardio Sessions"])
async def create_cardio_session(
    request: CardioSessionCreate,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a new cardio session.

    Records a completed cardio workout with details like distance, duration,
    pace, heart rate, and other metrics. Sessions can optionally be linked
    to a workout.
    """
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    db = get_supabase_db()

    # Verify user exists
    user_response = db.client.table("users").select("id").eq(
        "id", request.user_id
    ).maybe_single().execute()

    if not user_response.data:
        raise HTTPException(status_code=404, detail="User not found")

    # Verify workout exists if provided
    if request.workout_id:
        workout_response = db.client.table("workouts").select("id").eq(
            "id", request.workout_id
        ).maybe_single().execute()

        if not workout_response.data:
            raise HTTPException(status_code=404, detail="Workout not found")

    # Calculate average speed if distance and duration provided
    avg_speed = request.avg_speed_kmh
    if avg_speed is None and request.distance_km and request.duration_minutes:
        avg_speed = round((request.distance_km / request.duration_minutes) * 60, 2)

    # Calculate average pace if distance and duration provided
    avg_pace = request.avg_pace_per_km
    if avg_pace is None and request.distance_km and request.distance_km > 0:
        pace_minutes = request.duration_minutes / request.distance_km
        pace_mins = int(pace_minutes)
        pace_secs = int((pace_minutes - pace_mins) * 60)
        avg_pace = f"{pace_mins}:{pace_secs:02d}"

    # Prepare data for insertion
    session_data = {
        "user_id": request.user_id,
        "workout_id": request.workout_id,
        "cardio_type": request.cardio_type.value,
        "location": request.location.value,
        "distance_km": request.distance_km,
        "duration_minutes": request.duration_minutes,
        "avg_pace_per_km": avg_pace,
        "avg_speed_kmh": avg_speed,
        "elevation_gain_m": request.elevation_gain_m,
        "avg_heart_rate": request.avg_heart_rate,
        "max_heart_rate": request.max_heart_rate,
        "calories_burned": request.calories_burned,
        "notes": request.notes,
        "weather_conditions": request.weather_conditions,
    }

    # Insert session
    response = db.client.table("cardio_sessions").insert(session_data).execute()

    if not response.data:
        raise safe_internal_error(Exception("Failed to create cardio session"), "create_cardio_session")

    logger.info(f"Created cardio session for user {request.user_id}: {response.data[0]['id']}")

    return _parse_cardio_session(response.data[0])



# Include secondary endpoints
router.include_router(_endpoints_router)
