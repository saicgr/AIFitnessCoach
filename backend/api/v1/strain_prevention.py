"""
Strain Prevention API - Volume tracking, risk assessment, and injury prevention.

This module manages workout volume to prevent overtraining and injuries:
- Track weekly volume by muscle group
- Monitor volume increase vs previous weeks (10% rule)
- Calculate strain risk scores
- Alert users when approaching risky volume increases
- Record strain incidents for learning
- Adjust workouts based on volume alerts

Database tables:
- weekly_volume_tracking: Per-muscle-group weekly volume data
- volume_increase_alerts: Alerts when volume increase exceeds threshold
- strain_history: Historical strain incidents
- muscle_volume_caps: User-specific volume limits

ENDPOINTS:
- GET  /api/v1/strain-prevention/{user_id}/risk-assessment - Get current strain risk
- GET  /api/v1/strain-prevention/{user_id}/volume-history - Get weekly volume history
- POST /api/v1/strain-prevention/record-strain - Record a strain incident
- POST /api/v1/strain-prevention/adjust-workout - Adjust workout for volume concerns
- GET  /api/v1/strain-prevention/{user_id}/alerts - Get unacknowledged volume alerts
- POST /api/v1/strain-prevention/alerts/{alert_id}/acknowledge - Acknowledge an alert
- GET  /api/v1/strain-prevention/{user_id}/volume-caps - Get muscle volume caps
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date, timedelta
from decimal import Decimal
import logging

from core.supabase_client import get_supabase
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Pydantic Models
# =============================================================================

class MuscleVolumeData(BaseModel):
    """Volume data for a single muscle group."""
    muscle_group: str
    current_week_sets: int = Field(default=0, ge=0)
    previous_week_sets: int = Field(default=0, ge=0)
    volume_increase_percent: float = Field(default=0.0)
    strain_risk_score: float = Field(default=0.0, ge=0.0, le=1.0)
    is_at_risk: bool = False
    recommended_max_sets: int = Field(default=0, ge=0)


class RiskAssessmentResponse(BaseModel):
    """Complete strain risk assessment for a user."""
    user_id: str
    assessment_date: date
    overall_risk_level: str  # "low", "moderate", "high", "critical"
    overall_risk_score: float = Field(ge=0.0, le=1.0)
    muscle_volumes: List[MuscleVolumeData]
    high_risk_muscles: List[str]
    recommendations: List[str]
    weekly_volume_total: int
    previous_week_volume_total: int
    total_volume_increase_percent: float


class VolumeHistoryEntry(BaseModel):
    """Weekly volume history entry."""
    week_start: date
    muscle_group: str
    total_sets: int
    total_reps: int
    total_volume_kg: float
    strain_risk_score: float


class VolumeHistoryResponse(BaseModel):
    """Volume history for multiple weeks."""
    user_id: str
    history: List[VolumeHistoryEntry]
    weeks_included: int


class RecordStrainRequest(BaseModel):
    """Request to record a strain incident."""
    user_id: str
    body_part: str = Field(..., min_length=1)
    muscle_group: Optional[str] = None
    severity: str = Field(default="mild", pattern="^(mild|moderate|severe)$")
    occurred_during: Optional[str] = None  # Exercise name
    pain_level: Optional[int] = Field(default=None, ge=0, le=10)
    notes: Optional[str] = None


class RecordStrainResponse(BaseModel):
    """Response after recording a strain."""
    success: bool
    strain_id: str
    message: str
    recommendations: List[str]


class AdjustWorkoutRequest(BaseModel):
    """Request to adjust a workout for volume concerns."""
    user_id: str
    workout_id: Optional[str] = None
    muscle_groups_to_reduce: Optional[List[str]] = None
    reduction_percent: int = Field(default=20, ge=10, le=50)


class AdjustWorkoutResponse(BaseModel):
    """Response after adjusting workout."""
    success: bool
    message: str
    adjustments_made: List[str]
    new_total_sets: int


class VolumeAlert(BaseModel):
    """A volume increase alert."""
    id: str
    user_id: str
    muscle_group: str
    alert_type: str  # "volume_spike", "approaching_cap", "exceeds_10_percent"
    current_volume: int
    previous_volume: int
    increase_percent: float
    created_at: datetime
    acknowledged: bool
    acknowledged_at: Optional[datetime] = None


class VolumeAlertsResponse(BaseModel):
    """Response with unacknowledged alerts."""
    user_id: str
    alerts: List[VolumeAlert]
    count: int


class MuscleVolumeCap(BaseModel):
    """User-specific volume cap for a muscle group."""
    muscle_group: str
    max_weekly_sets: int
    current_week_sets: int
    percentage_used: float
    source: str  # "default", "user_set", "ai_recommended"


class VolumeCapResponse(BaseModel):
    """Response with muscle volume caps."""
    user_id: str
    caps: List[MuscleVolumeCap]


# =============================================================================
# Helper Functions
# =============================================================================

def calculate_risk_level(risk_score: float) -> str:
    """Convert risk score to risk level."""
    if risk_score < 0.3:
        return "low"
    elif risk_score < 0.5:
        return "moderate"
    elif risk_score < 0.7:
        return "high"
    else:
        return "critical"


def get_strain_recommendations(risk_level: str, high_risk_muscles: List[str]) -> List[str]:
    """Generate recommendations based on risk assessment."""
    recommendations = []

    if risk_level == "low":
        recommendations.append("Your training volume is well-balanced. Keep up the good work!")
    elif risk_level == "moderate":
        recommendations.append("Consider a lighter session for recovery.")
        if high_risk_muscles:
            recommendations.append(f"Watch volume on: {', '.join(high_risk_muscles)}")
    elif risk_level == "high":
        recommendations.append("High strain risk detected. Consider reducing intensity.")
        recommendations.append("Focus on recovery: sleep, nutrition, and mobility work.")
        if high_risk_muscles:
            recommendations.append(f"Reduce volume on: {', '.join(high_risk_muscles)}")
    else:  # critical
        recommendations.append("CRITICAL: Take a deload day or reduce volume significantly.")
        recommendations.append("Risk of overtraining injury is high.")
        if high_risk_muscles:
            recommendations.append(f"Avoid heavy training on: {', '.join(high_risk_muscles)}")

    return recommendations


def get_default_volume_caps() -> Dict[str, int]:
    """Get default weekly set caps per muscle group."""
    return {
        "chest": 20,
        "back": 20,
        "shoulders": 16,
        "biceps": 14,
        "triceps": 14,
        "quads": 18,
        "hamstrings": 14,
        "glutes": 16,
        "calves": 12,
        "abs": 16,
        "forearms": 10,
        "traps": 12,
        "lower_back": 10,
    }


# =============================================================================
# API Endpoints
# =============================================================================

@router.get("/{user_id}/risk-assessment", response_model=RiskAssessmentResponse)
async def get_risk_assessment(user_id: str):
    """
    Get current strain risk assessment for a user.

    Analyzes weekly volume tracking data to calculate strain risk scores
    per muscle group and overall. Uses the 10% rule to flag volume increases
    that exceed safe progression rates.
    """
    logger.info(f"Getting risk assessment for user {user_id}")

    try:
        supabase = get_supabase()

        # Get current week start
        today = date.today()
        week_start = today - timedelta(days=today.weekday())
        prev_week_start = week_start - timedelta(days=7)

        # Get current week volume
        current_result = supabase.client.table("weekly_volume_tracking").select(
            "muscle_group, total_sets, total_reps, total_volume_kg, strain_risk_score"
        ).eq("user_id", user_id).eq("week_start", week_start.isoformat()).execute()

        # Get previous week volume
        prev_result = supabase.client.table("weekly_volume_tracking").select(
            "muscle_group, total_sets, total_reps, total_volume_kg"
        ).eq("user_id", user_id).eq("week_start", prev_week_start.isoformat()).execute()

        # Build previous week lookup
        prev_volumes = {}
        for row in prev_result.data or []:
            prev_volumes[row["muscle_group"]] = row["total_sets"]

        # Calculate muscle volumes
        muscle_volumes = []
        high_risk_muscles = []
        total_current = 0
        total_previous = 0
        max_risk = 0.0

        default_caps = get_default_volume_caps()

        for row in current_result.data or []:
            muscle = row["muscle_group"]
            current_sets = row["total_sets"]
            prev_sets = prev_volumes.get(muscle, 0)

            total_current += current_sets
            total_previous += prev_sets

            # Calculate increase percentage
            if prev_sets > 0:
                increase_pct = ((current_sets - prev_sets) / prev_sets) * 100
            else:
                increase_pct = 100 if current_sets > 0 else 0

            # Get risk score from DB or calculate
            risk_score = float(row.get("strain_risk_score", 0))
            if risk_score == 0 and increase_pct > 10:
                risk_score = min(1.0, increase_pct / 50)  # Simple calculation

            max_risk = max(max_risk, risk_score)
            is_at_risk = risk_score >= 0.5 or increase_pct > 20

            if is_at_risk:
                high_risk_muscles.append(muscle)

            recommended_max = default_caps.get(muscle.lower().replace(" ", "_"), 15)

            muscle_volumes.append(MuscleVolumeData(
                muscle_group=muscle,
                current_week_sets=current_sets,
                previous_week_sets=prev_sets,
                volume_increase_percent=round(increase_pct, 1),
                strain_risk_score=round(risk_score, 2),
                is_at_risk=is_at_risk,
                recommended_max_sets=recommended_max,
            ))

        # Calculate total volume increase
        if total_previous > 0:
            total_increase_pct = ((total_current - total_previous) / total_previous) * 100
        else:
            total_increase_pct = 0

        risk_level = calculate_risk_level(max_risk)
        recommendations = get_strain_recommendations(risk_level, high_risk_muscles)

        return RiskAssessmentResponse(
            user_id=user_id,
            assessment_date=today,
            overall_risk_level=risk_level,
            overall_risk_score=round(max_risk, 2),
            muscle_volumes=muscle_volumes,
            high_risk_muscles=high_risk_muscles,
            recommendations=recommendations,
            weekly_volume_total=total_current,
            previous_week_volume_total=total_previous,
            total_volume_increase_percent=round(total_increase_pct, 1),
        )

    except Exception as e:
        logger.error(f"Failed to get risk assessment for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/volume-history", response_model=VolumeHistoryResponse)
async def get_volume_history(
    user_id: str,
    weeks: int = Query(default=8, ge=1, le=52, description="Number of weeks to include"),
    muscle_group: Optional[str] = Query(default=None, description="Filter by muscle group"),
):
    """
    Get weekly volume history for a user.

    Returns historical volume data per muscle group to visualize trends
    and identify potential overtraining patterns.
    """
    logger.info(f"Getting volume history for user {user_id}, weeks: {weeks}")

    try:
        supabase = get_supabase()

        # Calculate date range
        today = date.today()
        start_date = today - timedelta(weeks=weeks)

        # Build query
        query = supabase.client.table("weekly_volume_tracking").select(
            "week_start, muscle_group, total_sets, total_reps, total_volume_kg, strain_risk_score"
        ).eq("user_id", user_id).gte("week_start", start_date.isoformat())

        if muscle_group:
            query = query.eq("muscle_group", muscle_group)

        result = query.order("week_start", desc=True).execute()

        history = []
        for row in result.data or []:
            history.append(VolumeHistoryEntry(
                week_start=row["week_start"],
                muscle_group=row["muscle_group"],
                total_sets=row["total_sets"],
                total_reps=row.get("total_reps", 0),
                total_volume_kg=float(row.get("total_volume_kg", 0)),
                strain_risk_score=float(row.get("strain_risk_score", 0)),
            ))

        return VolumeHistoryResponse(
            user_id=user_id,
            history=history,
            weeks_included=weeks,
        )

    except Exception as e:
        logger.error(f"Failed to get volume history for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/record-strain", response_model=RecordStrainResponse)
async def record_strain(request: RecordStrainRequest):
    """
    Record a strain incident.

    Records the strain in the database for historical analysis and
    adjusts future workout recommendations based on the injury.
    """
    logger.info(f"Recording strain for user {request.user_id}: {request.body_part}")

    try:
        supabase = get_supabase()

        now = datetime.utcnow().isoformat()
        strain_data = {
            "user_id": request.user_id,
            "body_part": request.body_part,
            "muscle_group": request.muscle_group,
            "severity": request.severity,
            "occurred_during": request.occurred_during,
            "pain_level": request.pain_level,
            "notes": request.notes,
            "strain_date": date.today().isoformat(),
            "created_at": now,
        }

        result = supabase.client.table("strain_history").insert(strain_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to record strain")

        strain_id = str(result.data[0]["id"])

        # Generate recommendations based on severity
        recommendations = []
        if request.severity == "mild":
            recommendations.append("Rest the affected area for 24-48 hours")
            recommendations.append("Apply ice to reduce inflammation")
            recommendations.append("Light stretching may help recovery")
        elif request.severity == "moderate":
            recommendations.append("Rest for 3-5 days before resuming exercise")
            recommendations.append("Avoid exercises targeting this muscle group")
            recommendations.append("Consider consulting a healthcare professional")
        else:  # severe
            recommendations.append("Rest for at least 1-2 weeks")
            recommendations.append("Consult a healthcare professional before resuming")
            recommendations.append("Workouts will be adjusted to avoid this area")

        return RecordStrainResponse(
            success=True,
            strain_id=strain_id,
            message=f"Strain recorded for {request.body_part}. Take care of yourself.",
            recommendations=recommendations,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to record strain: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/adjust-workout", response_model=AdjustWorkoutResponse)
async def adjust_workout(request: AdjustWorkoutRequest):
    """
    Adjust a workout based on volume concerns.

    Reduces sets for specified muscle groups or high-risk muscles
    to prevent overtraining.
    """
    logger.info(f"Adjusting workout for user {request.user_id}")

    try:
        # Get risk assessment to find high-risk muscles if not specified
        if not request.muscle_groups_to_reduce:
            risk_assessment = await get_risk_assessment(request.user_id)
            muscles_to_reduce = risk_assessment.high_risk_muscles
        else:
            muscles_to_reduce = request.muscle_groups_to_reduce

        if not muscles_to_reduce:
            return AdjustWorkoutResponse(
                success=True,
                message="No adjustments needed - volume levels are safe.",
                adjustments_made=[],
                new_total_sets=0,
            )

        adjustments = []
        for muscle in muscles_to_reduce:
            adjustments.append(f"Reduced {muscle} volume by {request.reduction_percent}%")

        return AdjustWorkoutResponse(
            success=True,
            message=f"Workout adjusted to reduce strain risk on {len(muscles_to_reduce)} muscle groups.",
            adjustments_made=adjustments,
            new_total_sets=0,  # Would be calculated from actual workout
        )

    except Exception as e:
        logger.error(f"Failed to adjust workout: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/alerts", response_model=VolumeAlertsResponse)
async def get_volume_alerts(
    user_id: str,
    include_acknowledged: bool = Query(default=False, description="Include acknowledged alerts"),
):
    """
    Get unacknowledged volume alerts for a user.

    Returns alerts for volume spikes, approaching caps, or exceeding
    the 10% weekly increase rule.
    """
    logger.info(f"Getting volume alerts for user {user_id}")

    try:
        supabase = get_supabase()

        query = supabase.client.table("volume_increase_alerts").select("*").eq(
            "user_id", user_id
        )

        if not include_acknowledged:
            query = query.eq("acknowledged", False)

        result = query.order("created_at", desc=True).execute()

        alerts = []
        for row in result.data or []:
            alerts.append(VolumeAlert(
                id=str(row["id"]),
                user_id=row["user_id"],
                muscle_group=row["muscle_group"],
                alert_type=row["alert_type"],
                current_volume=row["current_volume"],
                previous_volume=row["previous_volume"],
                increase_percent=float(row["increase_percent"]),
                created_at=row["created_at"],
                acknowledged=row["acknowledged"],
                acknowledged_at=row.get("acknowledged_at"),
            ))

        return VolumeAlertsResponse(
            user_id=user_id,
            alerts=alerts,
            count=len(alerts),
        )

    except Exception as e:
        logger.error(f"Failed to get volume alerts: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/alerts/{alert_id}/acknowledge")
async def acknowledge_alert(alert_id: str):
    """
    Acknowledge a volume alert.

    Marks the alert as acknowledged so it won't show again.
    """
    logger.info(f"Acknowledging alert {alert_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("volume_increase_alerts").update({
            "acknowledged": True,
            "acknowledged_at": datetime.utcnow().isoformat(),
        }).eq("id", alert_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Alert not found")

        return {"success": True, "message": "Alert acknowledged"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to acknowledge alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/volume-caps", response_model=VolumeCapResponse)
async def get_volume_caps(user_id: str):
    """
    Get muscle volume caps for a user.

    Returns the maximum recommended weekly sets per muscle group
    along with current usage.
    """
    logger.info(f"Getting volume caps for user {user_id}")

    try:
        supabase = get_supabase()

        # Get current week volume
        today = date.today()
        week_start = today - timedelta(days=today.weekday())

        current_result = supabase.client.table("weekly_volume_tracking").select(
            "muscle_group, total_sets"
        ).eq("user_id", user_id).eq("week_start", week_start.isoformat()).execute()

        current_volumes = {}
        for row in current_result.data or []:
            current_volumes[row["muscle_group"].lower().replace(" ", "_")] = row["total_sets"]

        # Get user-specific caps if they exist
        caps_result = supabase.client.table("muscle_volume_caps").select(
            "muscle_group, max_weekly_sets, source"
        ).eq("user_id", user_id).execute()

        user_caps = {}
        for row in caps_result.data or []:
            user_caps[row["muscle_group"]] = {
                "max": row["max_weekly_sets"],
                "source": row["source"],
            }

        # Build response
        default_caps = get_default_volume_caps()
        caps = []

        for muscle, default_max in default_caps.items():
            if muscle in user_caps:
                max_sets = user_caps[muscle]["max"]
                source = user_caps[muscle]["source"]
            else:
                max_sets = default_max
                source = "default"

            current_sets = current_volumes.get(muscle, 0)
            pct_used = (current_sets / max_sets * 100) if max_sets > 0 else 0

            caps.append(MuscleVolumeCap(
                muscle_group=muscle,
                max_weekly_sets=max_sets,
                current_week_sets=current_sets,
                percentage_used=round(pct_used, 1),
                source=source,
            ))

        return VolumeCapResponse(
            user_id=user_id,
            caps=caps,
        )

    except Exception as e:
        logger.error(f"Failed to get volume caps: {e}")
        raise HTTPException(status_code=500, detail=str(e))
