"""Secondary endpoints for fasting_impact.  Sub-router included by main module.
Fasting Impact Analysis API endpoints.

ENDPOINTS:
Weight Tracking with Fasting Correlation:
- POST /api/v1/fasting-impact/weight - Log weight with automatic fasting day detection
- GET  /api/v1/fasting-impact/weight-correlation/{user_id} - Get weight logs with fasting correlation data

Impact Analysis:
- GET  /api/v1/fasting-impact/analysis/{user_id} - Analyze fasting impact on goals
- POST /api/v1/fasting-impact/analyze/{user_id} - Trigger fresh analysis and store results

Insights:
- GET  /api/v1/fasting-impact/insights/{user_id} - Get AI-generated insights about fasting impact
- GET  /api/v1/fasting-impact/ai-insight/{user_id} - Get Gemini AI-generated personalized insight
- POST /api/v1/fasting-impact/ai-insight/refresh/{user_id} - Force refresh AI insight (bypass cache)

Calendar:
- GET  /api/v1/fasting-impact/calendar/{user_id} - Get calendar view data with fasting/workout/goal info
"""
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta, date
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel, Field
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

from .fasting_impact_models import (
    LogWeightWithFastingRequest,
    WeightLogResponse,
    FastingWeightCorrelationResponse,
    FastingGoalImpactResponse,
    FastingImpactInsightResponse,
    CalendarDayData,
    CalendarViewResponse,
    AIFastingInsightResponse,
    AICorrelationResponse,
    AIFastingSummaryResponse,
    MarkFastingDayRequest,
    MarkFastingDayResponse,
)

router = APIRouter()

@router.get("/calendar/{user_id}", response_model=CalendarViewResponse)
async def get_fasting_calendar(
    user_id: str,
    month: int = Query(..., ge=1, le=12, description="Month (1-12)"),
    year: int = Query(..., ge=2020, le=2100, description="Year"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get calendar view data with fasting, weight, workout, and goal information.

    Each day shows:
    - Fasting status (was it a fasting day?)
    - Weight if logged
    - Workout completed
    - Goals hit vs total
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting calendar for user {user_id} ({month}/{year})")

    try:
        db = get_supabase_db()

        # Calculate date range for the month
        first_day = date(year, month, 1)
        if month == 12:
            last_day = date(year + 1, 1, 1) - timedelta(days=1)
        else:
            last_day = date(year, month + 1, 1) - timedelta(days=1)

        # Get fasting records for the month
        fasting_result = db.client.table("fasting_records").select(
            "id, start_time, protocol, status, completion_percentage"
        ).eq("user_id", user_id).gte(
            "start_time", first_day.isoformat()
        ).lte(
            "start_time", last_day.isoformat() + "T23:59:59"
        ).neq("status", "cancelled").execute()

        # Map fasting records by date
        fasting_by_date = {}
        for record in (fasting_result.data or []):
            try:
                record_date = datetime.fromisoformat(
                    record["start_time"].replace("Z", "+00:00")
                ).date().isoformat()
                fasting_by_date[record_date] = {
                    "id": record.get("id"),
                    "protocol": record.get("protocol"),
                    "completion_percent": record.get("completion_percentage"),
                }
            except Exception as e:
                logger.debug(f"Failed to parse fasting record: {e}")

        # Get weight logs
        weight_result = db.client.table("weight_logs").select(
            "logged_at, weight_kg"
        ).eq("user_id", user_id).gte(
            "logged_at", first_day.isoformat()
        ).lte("logged_at", last_day.isoformat()).execute()

        weight_by_date = {
            (row.get("logged_at") or "")[:10]: row.get("weight_kg")
            for row in (weight_result.data or [])
        }

        # Get workout completions
        workout_result = db.client.table("workout_logs").select(
            "id, completed_at"
        ).eq("user_id", user_id).gte(
            "completed_at", first_day.isoformat()
        ).lte("completed_at", last_day.isoformat()).execute()

        workouts_by_date = {}
        for row in (workout_result.data or []):
            completed_date = (row.get("completed_at") or "")[:10]
            if completed_date:
                workouts_by_date[completed_date] = row.get("id")

        # Get goal progress (using weekly_personal_goals table instead of non-existent personal_goal_progress)
        goals_result = db.client.table("weekly_personal_goals").select(
            "created_at, status"
        ).eq("user_id", user_id).gte(
            "created_at", first_day.isoformat()
        ).lte("created_at", last_day.isoformat()).execute()

        goals_by_date = {}
        for row in (goals_result.data or []):
            goal_date = (row.get("created_at") or "")[:10]
            if goal_date not in goals_by_date:
                goals_by_date[goal_date] = {"hit": 0, "total": 0}
            goals_by_date[goal_date]["total"] += 1
            if row.get("status") == "completed":
                goals_by_date[goal_date]["hit"] += 1

        # Build calendar days
        calendar_days = []
        current_date = first_day

        fasting_days_count = 0
        workout_days_count = 0
        goals_hit_count = 0

        while current_date <= last_day:
            date_str = current_date.isoformat()

            fasting_info = fasting_by_date.get(date_str, {})
            is_fasting = bool(fasting_info)

            goal_info = goals_by_date.get(date_str, {"hit": 0, "total": 0})
            has_workout = date_str in workouts_by_date

            if is_fasting:
                fasting_days_count += 1
            if has_workout:
                workout_days_count += 1
            goals_hit_count += goal_info["hit"]

            calendar_days.append(CalendarDayData(
                date=date_str,
                is_fasting_day=is_fasting,
                fasting_protocol=fasting_info.get("protocol"),
                fasting_completion_percent=fasting_info.get("completion_percent"),
                fasting_record_id=fasting_info.get("id"),
                weight_logged=weight_by_date.get(date_str),
                workout_completed=has_workout,
                workout_id=workouts_by_date.get(date_str),
                goals_hit=goal_info["hit"],
                goals_total=goal_info["total"],
            ))

            current_date += timedelta(days=1)

        # Build summary
        summary = {
            "total_days": len(calendar_days),
            "fasting_days": fasting_days_count,
            "workout_days": workout_days_count,
            "total_goals_hit": goals_hit_count,
            "days_with_weight_logged": len(weight_by_date),
            "fasting_rate": round(fasting_days_count / len(calendar_days) * 100, 1) if calendar_days else 0,
        }

        # Log activity for context tracking
        await log_user_activity(
            user_id=user_id,
            action="fasting_calendar_viewed",
            endpoint=f"/api/v1/fasting-impact/calendar/{user_id}",
            message=f"Viewed fasting calendar for {month}/{year}",
            metadata={
                "month": month,
                "year": year,
                "total_days": summary["total_days"],
                "fasting_days": summary["fasting_days"],
                "workout_days": summary["workout_days"],
                "total_goals_hit": summary["total_goals_hit"],
                "days_with_weight_logged": summary["days_with_weight_logged"],
                "fasting_rate": summary["fasting_rate"],
            },
            status_code=200
        )

        return CalendarViewResponse(
            user_id=user_id,
            month=month,
            year=year,
            days=calendar_days,
            summary=summary,
        )

    except Exception as e:
        logger.error(f"Error getting fasting calendar: {e}")
        await log_user_error(
            user_id=user_id,
            action="fasting_calendar_viewed",
            error=e,
            endpoint=f"/api/v1/fasting-impact/calendar/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

# ==================== AI-Powered Insights Endpoints ====================

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

def interpret_ai_correlation(score: float) -> str:
    """Interpret correlation score for user display."""
    if score > 0.5:
        return "Strong positive correlation - fasting significantly helps your goals"
    elif score > 0.3:
        return "Moderate positive correlation - fasting appears helpful"
    elif score > 0.1:
        return "Slight positive correlation - fasting may be slightly beneficial"
    elif score > -0.1:
        return "No clear correlation - fasting doesn't seem to affect your goals"
    elif score > -0.3:
        return "Slight negative correlation - fasting may slightly hinder goals"
    elif score > -0.5:
        return "Moderate negative correlation - consider adjusting fasting approach"
    else:
        return "Strong negative correlation - fasting may be impacting goals negatively"

async def get_weight_data_for_ai(user_id: str, days: int = 30) -> List[Dict[str, Any]]:
    """
    Get weight logs with fasting day correlation for AI analysis.
    """
    logger.info(f"Getting weight data for AI analysis for user {user_id}")

    db = get_supabase_db()
    end_date = date.today()
    start_date = end_date - timedelta(days=days)

    try:
        # Get weight logs (using logged_at, not date column)
        weight_result = db.client.table("weight_logs").select(
            "logged_at, weight_kg"
        ).eq("user_id", user_id).gte(
            "logged_at", start_date.isoformat()
        ).order("logged_at").execute()

        weight_logs = weight_result.data or []

        if not weight_logs:
            return []

        # Get fasting days
        fasting_result = db.client.table("fasting_records").select(
            "start_time"
        ).eq("user_id", user_id).eq("status", "completed").gte(
            "start_time", start_date.isoformat()
        ).execute()

        fasting_days = set()
        for record in (fasting_result.data or []):
            start_time = record.get("start_time", "")
            if start_time:
                fasting_days.add(start_time[:10])

        # Combine data
        result = []
        for log in weight_logs:
            log_date = (log.get("logged_at") or "")[:10]
            result.append({
                "date": log_date,
                "weight_kg": float(log.get("weight_kg", 0)),
                "is_fasting_day": log_date in fasting_days,
            })

        return result

    except Exception as e:
        logger.error(f"Error getting weight data for AI: {e}")
        return []

async def get_goal_data_for_ai(user_id: str, days: int = 30) -> Dict[str, Any]:
    """
    Get goal achievement data for AI analysis.
    """
    logger.info(f"Getting goal data for AI analysis for user {user_id}")

    db = get_supabase_db()
    end_date = date.today()
    start_date = end_date - timedelta(days=days)

    try:
        # Get fasting days first
        fasting_result = db.client.table("fasting_records").select(
            "start_time"
        ).eq("user_id", user_id).eq("status", "completed").gte(
            "start_time", start_date.isoformat()
        ).execute()

        fasting_days = set()
        for record in (fasting_result.data or []):
            start_time = record.get("start_time", "")
            if start_time:
                fasting_days.add(start_time[:10])

        # Get workout completions
        workout_result = db.client.table("workout_logs").select(
            "completed_at"
        ).eq("user_id", user_id).gte("completed_at", start_date.isoformat()).execute()

        fasting_workout_completed = 0
        fasting_workout_total = 0
        non_fasting_workout_completed = 0
        non_fasting_workout_total = 0

        for row in (workout_result.data or []):
            workout_date = (row.get("completed_at") or "")[:10]
            # All workout_logs entries are completed workouts
            if workout_date in fasting_days:
                fasting_workout_total += 1
                fasting_workout_completed += 1
            else:
                non_fasting_workout_total += 1
                non_fasting_workout_completed += 1

        # Get goal achievements
        goals_result = db.client.table("weekly_personal_goals").select(
            "created_at, status"
        ).eq("user_id", user_id).gte("created_at", start_date.isoformat()).execute()

        goals_fasting = 0
        goals_non_fasting = 0

        for row in (goals_result.data or []):
            goal_date = (row.get("created_at") or "")[:10]
            if row.get("status") == "completed":
                if goal_date in fasting_days:
                    goals_fasting += 1
                else:
                    goals_non_fasting += 1

        return {
            "goals_fasting": goals_fasting,
            "goals_non_fasting": goals_non_fasting,
            "workout_completion_fasting": (fasting_workout_completed / fasting_workout_total * 100) if fasting_workout_total > 0 else 0,
            "workout_completion_non_fasting": (non_fasting_workout_completed / non_fasting_workout_total * 100) if non_fasting_workout_total > 0 else 0,
        }

    except Exception as e:
        logger.error(f"Error getting goal data for AI: {e}")
        return {
            "goals_fasting": 0,
            "goals_non_fasting": 0,
            "workout_completion_fasting": 0,
            "workout_completion_non_fasting": 0,
        }

@router.get("/ai-insight/{user_id}", response_model=AIFastingInsightResponse)
@limiter.limit("5/minute")
async def get_ai_fasting_insight(
    request: Request,
    user_id: str,
    days: int = Query(default=30, ge=7, le=90, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get Gemini AI-generated insight about how fasting impacts the user's goals.

    The insight includes:
    - Analysis of fasting patterns using AI
    - Correlation with weight and workout goals
    - Personalized AI-generated recommendations

    Results are cached for 24 hours to avoid repeated AI calls.
    Uses Gemini Pro with 120-second timeout for reliable generation.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting AI fasting insight for user {user_id} (days={days})")

    try:
        # Import the service here to avoid circular imports
        from services.fasting_insight_service import get_fasting_insight_service

        service = get_fasting_insight_service()

        # Gather data for insight generation
        fasting_data = await service.get_fasting_summary_for_insight(user_id, days)
        weight_data = await get_weight_data_for_ai(user_id, days)
        goal_data = await get_goal_data_for_ai(user_id, days)

        # Generate AI insight
        insight = await service.generate_fasting_impact_insight(
            user_id=user_id,
            fasting_data=fasting_data,
            weight_data=weight_data,
            goal_data=goal_data,
        )

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="ai_fasting_insight_generated",
            endpoint=f"/api/v1/fasting-impact/ai-insight/{user_id}",
            message=f"Generated AI fasting insight: {insight.get('insight_type', 'unknown')}",
            metadata={
                "insight_type": insight.get("insight_type"),
                "days_analyzed": days,
            },
            status_code=200
        )

        return AIFastingInsightResponse(**insight)

    except ValueError as e:
        # Validation errors from AI parsing
        logger.error(f"Validation error getting AI insight: {e}")
        raise HTTPException(status_code=422, detail="Invalid data format")

    except Exception as e:
        logger.error(f"Error getting AI fasting insight: {e}")
        await log_user_error(
            user_id=user_id,
            action="ai_fasting_insight_generated",
            error=e,
            endpoint=f"/api/v1/fasting-impact/ai-insight/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

@router.post("/ai-insight/refresh/{user_id}", response_model=AIFastingInsightResponse)
@limiter.limit("5/minute")
async def refresh_ai_fasting_insight(
    request: Request,
    user_id: str,
    days: int = Query(default=30, ge=7, le=90, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """
    Force refresh the AI fasting insight, bypassing cache.

    Use this when user wants latest analysis after logging new data.
    Generates a fresh Gemini AI insight.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Force refreshing AI fasting insight for user {user_id}")

    try:
        from services.fasting_insight_service import get_fasting_insight_service

        service = get_fasting_insight_service()

        # Gather fresh data
        fasting_data = await service.get_fasting_summary_for_insight(user_id, days)
        weight_data = await get_weight_data_for_ai(user_id, days)
        goal_data = await get_goal_data_for_ai(user_id, days)

        # Generate fresh AI insight (will overwrite cache)
        insight = await service.generate_fasting_impact_insight(
            user_id=user_id,
            fasting_data=fasting_data,
            weight_data=weight_data,
            goal_data=goal_data,
        )

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="ai_fasting_insight_refreshed",
            endpoint=f"/api/v1/fasting-impact/ai-insight/refresh/{user_id}",
            message=f"Refreshed AI fasting insight: {insight.get('insight_type', 'unknown')}",
            metadata={
                "insight_type": insight.get("insight_type"),
                "days_analyzed": days,
            },
            status_code=200
        )

        return AIFastingInsightResponse(**insight)

    except Exception as e:
        logger.error(f"Error refreshing AI fasting insight: {e}")
        await log_user_error(
            user_id=user_id,
            action="ai_fasting_insight_refreshed",
            error=e,
            endpoint=f"/api/v1/fasting-impact/ai-insight/refresh/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

@router.get("/ai-correlation/{user_id}", response_model=AICorrelationResponse)
@limiter.limit("5/minute")
async def get_ai_correlation_score(
    request: Request,
    user_id: str,
    days: int = Query(default=30, ge=7, le=90, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get the correlation score between fasting and goal achievement.

    Returns a score from -1 to 1:
    - Positive: Fasting correlates with better goal achievement
    - Negative: Fasting correlates with worse goal achievement
    - Near zero: No clear correlation
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting AI correlation score for user {user_id} (days={days})")

    try:
        from services.fasting_insight_service import get_fasting_insight_service

        service = get_fasting_insight_service()
        score = await service.calculate_correlation_score(user_id, days)

        return AICorrelationResponse(
            user_id=user_id,
            correlation_score=round(score, 3),
            interpretation=interpret_ai_correlation(score),
            days_analyzed=days,
            sufficient_data=abs(score) > 0,  # 0 means not enough data
        )

    except Exception as e:
        logger.error(f"Error getting AI correlation score: {e}")
        raise safe_internal_error(e, "endpoint")

@router.get("/ai-summary/{user_id}", response_model=AIFastingSummaryResponse)
async def get_ai_fasting_summary(
    user_id: str,
    days: int = Query(default=30, ge=7, le=90, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get a summary of fasting data for the specified period.

    This is the raw data used for AI insight generation.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting AI fasting summary for user {user_id} (days={days})")

    try:
        from services.fasting_insight_service import get_fasting_insight_service

        service = get_fasting_insight_service()
        summary = await service.get_fasting_summary_for_insight(user_id, days)

        return AIFastingSummaryResponse(
            user_id=user_id,
            total_fasting_days=summary.get("total_fasting_days", 0),
            total_non_fasting_days=summary.get("total_non_fasting_days", 0),
            most_common_protocol=summary.get("most_common_protocol"),
            avg_fast_duration_hours=round(summary.get("avg_fast_duration_hours", 0), 1),
            correlation_score=summary.get("correlation_score"),
            period_days=days,
        )

    except Exception as e:
        logger.error(f"Error getting AI fasting summary: {e}")
        raise safe_internal_error(e, "endpoint")

# ==================== Mark Historical Fasting Day ====================

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

@router.post("/mark-fasting-day", response_model=MarkFastingDayResponse)
async def mark_historical_fasting_day(
    data: MarkFastingDayRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Mark a historical date as a fasting day.

    Use this endpoint when a user forgot to use the fasting timer but still completed
    a fast on a past date. This creates a completed fasting record for that day.

    Validation:
    - Date must be in the past (not today or future)
    - Date cannot be more than 30 days in the past
    - Cannot mark a date that already has a fasting record
    """
    if str(current_user["id"]) != str(data.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Marking historical fasting day for user {data.user_id} on {data.date}")

    try:
        db = get_supabase_db()

        # Parse and validate the date
        try:
            target_date = datetime.strptime(data.date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")

        today = date.today()

        # Validate date is in the past
        if target_date >= today:
            raise HTTPException(
                status_code=400,
                detail="Cannot mark today or future dates. Date must be in the past."
            )

        # Validate date is not too far in the past (max 30 days)
        days_ago = (today - target_date).days
        if days_ago > 30:
            raise HTTPException(
                status_code=400,
                detail="Cannot mark dates more than 30 days in the past."
            )

        # Check if there's already a fasting record for this date
        existing_check = await get_fasting_status_for_date(data.user_id, target_date)
        if existing_check["is_fasting_day"]:
            raise HTTPException(
                status_code=400,
                detail=f"A fasting record already exists for {data.date}."
            )

        # Determine protocol and hours
        protocol = data.protocol or "16:8"
        estimated_hours = data.estimated_hours

        # If no hours provided, derive from protocol
        if estimated_hours is None:
            protocol_hours = {
                "12:12": 12,
                "14:10": 14,
                "16:8": 16,
                "18:6": 18,
                "20:4": 20,
                "OMAD": 23,
                "24h": 24,
                "36h": 36,
                "48h": 48,
            }
            estimated_hours = protocol_hours.get(protocol, 16)

        # Calculate times (use noon as reference point)
        estimated_minutes = int(estimated_hours * 60)
        start_time = datetime.combine(target_date, datetime.min.time()) + timedelta(hours=8)  # 8 AM start
        end_time = start_time + timedelta(minutes=estimated_minutes)

        # Determine protocol type
        if estimated_hours <= 18:
            protocol_type = "tre"  # Time-restricted eating
        elif estimated_hours <= 24:
            protocol_type = "daily"
        else:
            protocol_type = "extended"

        # Create the fasting record
        record_id = str(uuid.uuid4())
        fasting_record = {
            "id": record_id,
            "user_id": data.user_id,
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "goal_duration_minutes": estimated_minutes,
            "actual_duration_minutes": estimated_minutes,
            "protocol": protocol,
            "protocol_type": protocol_type,
            "status": "completed",
            "completed_goal": True,
            "completion_percentage": 100.0,
            "notes": data.notes or f"Retroactively marked as fasting day ({estimated_hours}h)",
            "ended_by": "historical_mark",
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }

        result = db.client.table("fasting_records").insert(fasting_record).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create fasting record")

        # Log the activity
        await log_user_activity(
            user_id=data.user_id,
            action="historical_fasting_day_marked",
            endpoint="/api/v1/fasting-impact/mark-fasting-day",
            message=f"Marked {data.date} as fasting day ({protocol}, {estimated_hours}h)",
            metadata={
                "date": data.date,
                "protocol": protocol,
                "estimated_hours": estimated_hours,
                "record_id": record_id,
            },
            status_code=200
        )

        return MarkFastingDayResponse(
            id=record_id,
            user_id=data.user_id,
            date=data.date,
            protocol=protocol,
            estimated_hours=estimated_hours,
            status="completed",
            completion_percentage=100.0,
            notes=fasting_record["notes"],
            created_at=fasting_record["created_at"],
            message=f"Successfully marked {data.date} as a fasting day with {protocol} protocol ({estimated_hours}h)."
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error marking historical fasting day: {e}")
        await log_user_error(
            user_id=data.user_id,
            action="historical_fasting_day_marked",
            error=e,
            endpoint="/api/v1/fasting-impact/mark-fasting-day",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")
