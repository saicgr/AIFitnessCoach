"""Secondary endpoints for fasting.  Sub-router included by main module.
Fasting Tracking API endpoints.

ENDPOINTS:
Fasting Records:
- POST /api/v1/fasting/start - Start a new fast
- POST /api/v1/fasting/{fast_id}/end - End an active fast
- POST /api/v1/fasting/{fast_id}/cancel - Cancel a fast (no credit)
- GET  /api/v1/fasting/active/{user_id} - Get current active fast
- GET  /api/v1/fasting/history/{user_id} - Get fasting history
- PUT  /api/v1/fasting/{fast_id} - Update a fast record

Fasting Preferences:
- GET  /api/v1/fasting/preferences/{user_id} - Get fasting preferences
- PUT  /api/v1/fasting/preferences/{user_id} - Update fasting preferences
- POST /api/v1/fasting/onboarding/complete - Complete fasting onboarding

Streaks & Stats:
- GET  /api/v1/fasting/streak/{user_id} - Get fasting streak
- GET  /api/v1/fasting/stats/{user_id} - Get fasting statistics

Safety:
- GET  /api/v1/fasting/safety-check/{user_id} - Check safety eligibility
- POST /api/v1/fasting/safety-screening - Save safety screening

Fasting Scores:
- POST /api/v1/fasting/score - Save/upsert a fasting score
- GET  /api/v1/fasting/score/history/{user_id} - Get historical scores
- GET  /api/v1/fasting/score/{user_id}/current - Get current/latest score
- GET  /api/v1/fasting/score/trend/{user_id} - Get score trend vs last week
"""
from typing import Optional
from datetime import datetime, timedelta, date
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel, Field
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.timezone_utils import resolve_timezone, get_user_today
from core.exceptions import safe_internal_error

from .fasting_models import (
    StartFastRequest,
    EndFastRequest,
    CancelFastRequest,
    UpdateFastRequest,
    FastingPreferencesRequest,
    CompleteOnboardingRequest,
    SafetyScreeningRequest,
    FastingRecordResponse,
    FastEndResultResponse,
    FastingPreferencesResponse,
    FastingStreakResponse,
    FastingStatsResponse,
    SafetyCheckResponse,
    FastingScoreCreateRequest,
    FastingScoreResponse,
    FastingScoreTrendResponse,
    LogFastingContextRequest,
)

router = APIRouter()

@router.get("/streak/{user_id}", response_model=FastingStreakResponse)
async def get_streak(user_id: str, current_user: dict = Depends(get_current_user)):
    """Get user's fasting streak."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting streak for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("fasting_streaks").select("*").eq(
            "user_id", user_id
        ).execute()

        if not result.data:
            # Return default streak
            return FastingStreakResponse(
                user_id=user_id,
                current_streak=0,
                longest_streak=0,
                total_fasts_completed=0,
                total_fasting_hours=0,
                fasts_this_week=0,
            )

        streak = result.data[0]
        return FastingStreakResponse(
            user_id=user_id,
            current_streak=streak.get("current_streak", 0),
            longest_streak=streak.get("longest_streak", 0),
            total_fasts_completed=streak.get("total_fasts_completed", 0),
            total_fasting_hours=streak.get("total_fasting_hours", 0),
            last_fast_date=streak.get("last_fast_date"),
            streak_start_date=streak.get("streak_start_date"),
            fasts_this_week=streak.get("fasts_this_week", 0),
            freezes_available=streak.get("freezes_available", 2),
            freezes_used_this_week=streak.get("freezes_used_this_week", 0),
        )

    except Exception as e:
        raise safe_internal_error(e, "get_streak")


@router.get("/stats/{user_id}", response_model=FastingStatsResponse)
async def get_stats(
    user_id: str,
    current_user: dict = Depends(get_current_user),
    period: str = Query(default="month", description="'week', 'month', 'year', 'all'"),
):
    """Get fasting statistics for a user."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting stats for user {user_id} (period: {period})")

    try:
        db = get_supabase_db()

        # Calculate date range
        now = datetime.utcnow()
        if period == "week":
            start_date = now - timedelta(days=7)
        elif period == "month":
            start_date = now - timedelta(days=30)
        elif period == "year":
            start_date = now - timedelta(days=365)
        else:
            start_date = datetime(2020, 1, 1)  # All time

        # Get fasting records
        result = db.client.table("fasting_records").select("*").eq(
            "user_id", user_id
        ).gte("start_time", start_date.isoformat()).execute()

        records = result.data or []

        # Calculate stats
        total_fasts = len(records)
        completed_fasts = len([r for r in records if r.get("status") == "completed"])
        cancelled_fasts = len([r for r in records if r.get("status") == "cancelled"])

        total_minutes = sum(
            r.get("actual_duration_minutes", 0) or 0
            for r in records if r.get("status") == "completed"
        )
        total_hours = total_minutes / 60

        avg_duration = total_hours / completed_fasts if completed_fasts > 0 else 0

        longest_minutes = max(
            (r.get("actual_duration_minutes", 0) or 0 for r in records),
            default=0
        )
        longest_hours = longest_minutes / 60

        completion_rate = (completed_fasts / total_fasts * 100) if total_fasts > 0 else 0

        # Count protocols
        protocol_counts = {}
        for r in records:
            protocol = r.get("protocol", "unknown")
            protocol_counts[protocol] = protocol_counts.get(protocol, 0) + 1

        most_common = max(protocol_counts, key=protocol_counts.get) if protocol_counts else None

        # Zones reached (simplified - would need actual zone tracking)
        zones_reached = {
            "fed": total_fasts,
            "postAbsorptive": completed_fasts,
            "earlyFasting": len([r for r in records if (r.get("actual_duration_minutes") or 0) >= 480]),
            "fatBurning": len([r for r in records if (r.get("actual_duration_minutes") or 0) >= 720]),
            "ketosis": len([r for r in records if (r.get("actual_duration_minutes") or 0) >= 960]),
            "deepKetosis": len([r for r in records if (r.get("actual_duration_minutes") or 0) >= 1440]),
        }

        return FastingStatsResponse(
            user_id=user_id,
            period=period,
            total_fasts=total_fasts,
            completed_fasts=completed_fasts,
            cancelled_fasts=cancelled_fasts,
            total_fasting_hours=round(total_hours, 1),
            average_fast_duration_hours=round(avg_duration, 1),
            longest_fast_hours=round(longest_hours, 1),
            completion_rate=round(completion_rate, 1),
            most_common_protocol=most_common,
            zones_reached=zones_reached,
        )

    except Exception as e:
        raise safe_internal_error(e, "get_stats")


# ==================== Safety Endpoints ====================

@router.get("/safety-check/{user_id}", response_model=SafetyCheckResponse)
async def check_safety_eligibility(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Check if user can safely use fasting features.

    Checks user profile for contraindications:
    - Pregnant/breastfeeding
    - Under 18
    - Eating disorder history (if disclosed)
    - Type 1 diabetes
    - Underweight (BMI < 18.5)
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Checking safety eligibility for user {user_id}")

    try:
        db = get_supabase_db()

        # Get user profile
        result = db.client.table("users").select(
            "age, gender, weight_kg, height_cm, health_conditions, goals"
        ).eq("id", user_id).execute()

        if not result.data:
            # No profile, allow with warning
            return SafetyCheckResponse(
                can_use_fasting=True,
                requires_warning=True,
                warnings=["Please complete your profile for personalized safety recommendations."],
                blocked_reasons=[],
            )

        user = result.data[0]

        warnings = []
        blocked_reasons = []

        # Check age
        age = user.get("age")
        if age and age < 18:
            blocked_reasons.append("Fasting is not recommended for those under 18.")
        elif age and age > 65:
            warnings.append("Please consult your doctor before starting a fasting regimen.")

        # Check BMI if we have height/weight
        weight = user.get("weight_kg")
        height = user.get("height_cm")
        if weight and height:
            bmi = weight / ((height / 100) ** 2)
            if bmi < 18.5:
                blocked_reasons.append("Fasting is not recommended for those who are underweight (BMI < 18.5).")

        # Check health conditions (if stored)
        conditions = user.get("health_conditions") or []
        if isinstance(conditions, str):
            conditions = [conditions]

        for condition in conditions:
            condition_lower = condition.lower() if condition else ""
            if "type 1 diabetes" in condition_lower:
                blocked_reasons.append("Type 1 diabetics should not fast without medical supervision.")
            elif "eating disorder" in condition_lower:
                blocked_reasons.append("For your safety, fasting is not recommended with a history of eating disorders.")
            elif "pregnant" in condition_lower or "breastfeeding" in condition_lower:
                blocked_reasons.append("Fasting is not recommended during pregnancy or breastfeeding.")
            elif "diabetes" in condition_lower:
                warnings.append("Please consult your doctor about fasting with diabetes.")
            elif "thyroid" in condition_lower:
                warnings.append("Please consult your doctor about fasting with thyroid conditions.")

        can_use = len(blocked_reasons) == 0
        requires_warning = len(warnings) > 0

        return SafetyCheckResponse(
            can_use_fasting=can_use,
            requires_warning=requires_warning,
            warnings=warnings,
            blocked_reasons=blocked_reasons,
        )

    except Exception as e:
        raise safe_internal_error(e, "check_safety_eligibility")


@router.post("/safety-screening")
async def save_safety_screening(data: SafetyScreeningRequest, current_user: dict = Depends(get_current_user)):
    """Save safety screening responses."""
    if str(current_user["id"]) != str(data.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Saving safety screening for user {data.user_id}")

    try:
        db = get_supabase_db()

        # Update preferences with safety info
        result = db.client.table("fasting_preferences").upsert({
            "user_id": data.user_id,
            "safety_screening_completed": True,
            "safety_warnings_acknowledged": list(data.responses.keys()),
            "safety_responses": data.responses,
            "updated_at": datetime.utcnow().isoformat(),
        }, on_conflict="user_id").execute()

        return {"status": "saved", "user_id": data.user_id}

    except Exception as e:
        raise safe_internal_error(e, "save_safety_screening")


# ==================== User Context Logging Endpoints ====================

class LogFastingContextRequest(BaseModel):
    """Request to log fasting context for AI coaching."""
    user_id: str
    fasting_record_id: Optional[str] = None
    context_type: str  # 'fast_started', 'zone_entered', 'fast_ended', 'fast_cancelled', 'note_added', 'mood_logged'
    zone_name: Optional[str] = None
    mood: Optional[str] = None
    energy_level: Optional[int] = Field(None, ge=1, le=5)
    note: Optional[str] = None
    protocol: Optional[str] = None
    protocol_type: Optional[str] = None
    is_dangerous_protocol: Optional[bool] = False
    elapsed_minutes: Optional[int] = None
    goal_minutes: Optional[int] = None


@router.post("/context/log")
async def log_fasting_context(data: LogFastingContextRequest, current_user: dict = Depends(get_current_user)):
    """
    Log user context during fasting for AI coaching and analytics.

    This logs events like:
    - fast_started: When user starts a fast
    - zone_entered: When user enters a new metabolic zone
    - fast_ended: When user completes a fast
    - fast_cancelled: When user cancels a fast
    - note_added: When user adds a note
    - mood_logged: When user logs their mood/energy
    """
    if str(current_user["id"]) != str(data.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Logging fasting context for user {data.user_id}: {data.context_type}")

    try:
        db = get_supabase_db()

        # Calculate completion percentage if applicable
        completion_percentage = None
        if data.elapsed_minutes and data.goal_minutes and data.goal_minutes > 0:
            completion_percentage = min(100.0, round((data.elapsed_minutes / data.goal_minutes) * 100, 2))

        context_data = {
            "id": str(uuid.uuid4()),
            "user_id": data.user_id,
            "fasting_record_id": data.fasting_record_id,
            "context_type": data.context_type,
            "zone_name": data.zone_name,
            "mood": data.mood,
            "energy_level": data.energy_level,
            "note": data.note,
            "protocol": data.protocol,
            "protocol_type": data.protocol_type,
            "is_dangerous_protocol": data.is_dangerous_protocol,
            "elapsed_minutes": data.elapsed_minutes,
            "goal_minutes": data.goal_minutes,
            "completion_percentage": completion_percentage,
            "timestamp": datetime.utcnow().isoformat(),
            "created_at": datetime.utcnow().isoformat(),
        }

        result = db.client.table("fasting_user_context").insert(context_data).execute()

        if not result.data:
            logger.warning(f"Could not log fasting context (table may not exist yet)")
            # Don't fail if table doesn't exist - migration may not be run
            return {"status": "skipped", "reason": "context table not available"}

        return {"status": "logged", "context_id": context_data["id"]}

    except Exception as e:
        logger.error(f"Error logging fasting context: {e}")
        # Don't fail the request - context logging is optional
        return {"status": "error", "reason": str(e)}


@router.get("/context/{user_id}")
async def get_fasting_context(
    user_id: str,
    current_user: dict = Depends(get_current_user),
    limit: int = Query(default=50, ge=1, le=200),
    context_type: Optional[str] = Query(None, description="Filter by context type"),
):
    """
    Get user's fasting context history for AI coaching.

    This provides context for the AI coach about the user's fasting patterns,
    moods, energy levels, and notes.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting context for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("fasting_user_context").select("*").eq(
            "user_id", user_id
        )

        if context_type:
            query = query.eq("context_type", context_type)

        result = query.order("timestamp", desc=True).limit(limit).execute()

        return {"contexts": result.data or [], "count": len(result.data or [])}

    except Exception as e:
        logger.error(f"Error getting fasting context: {e}")
        # Return empty if table doesn't exist
        return {"contexts": [], "count": 0}


# ==================== Fasting Score Endpoints ====================

@router.post("/score")
async def save_fasting_score(request: FastingScoreCreateRequest, http_request: Request, current_user: dict = Depends(get_current_user)):
    """
    Save or update today's fasting score for a user.

    Uses upsert to update today's score if already exists (one score per user per day).
    """
    if str(current_user["id"]) != str(request.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Saving fasting score for user {request.user_id}: {request.score}")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, request.user_id)

        data = {
            "user_id": request.user_id,
            "score": request.score,
            "completion_component": request.completion_component,
            "streak_component": request.streak_component,
            "duration_component": request.duration_component,
            "weekly_component": request.weekly_component,
            "protocol_component": request.protocol_component,
            "current_streak": request.current_streak,
            "fasts_this_week": request.fasts_this_week,
            "weekly_goal": request.weekly_goal,
            "completion_rate": request.completion_rate,
            "avg_duration_minutes": request.avg_duration_minutes,
            "score_date": get_user_today(user_tz),
            "recorded_at": datetime.utcnow().isoformat(),
        }

        result = db.client.table("fasting_scores").upsert(
            data, on_conflict="user_id,score_date"
        ).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save fasting score")

        logger.info(f"✅ Fasting score saved for user {request.user_id}")
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "save_fasting_score")


@router.get("/score/history/{user_id}")
async def get_fasting_score_history(
    user_id: str,
    http_request: Request,
    current_user: dict = Depends(get_current_user),
    days: int = Query(30, ge=1, le=365, description="Number of days of history to retrieve"),
):
    """
    Get historical fasting scores for a user.

    Returns scores for the specified number of days, ordered by most recent first.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting score history for user {user_id} (last {days} days)")

    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(http_request, db, user_id)

        today = date.fromisoformat(get_user_today(user_tz))
        cutoff_date = (today - timedelta(days=days)).isoformat()

        result = db.client.table("fasting_scores")\
            .select("*")\
            .eq("user_id", user_id)\
            .gte("score_date", cutoff_date)\
            .order("recorded_at", desc=True)\
            .execute()

        logger.info(f"✅ Retrieved {len(result.data or [])} score records for user {user_id}")
        return result.data or []

    except Exception as e:
        raise safe_internal_error(e, "get_fasting_score_history")


@router.get("/score/{user_id}/current")
async def get_current_fasting_score(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get the most recent fasting score for a user.

    Returns 404 if no score exists for the user.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting current fasting score for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("fasting_scores")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("recorded_at", desc=True)\
            .limit(1)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="No fasting score found for user")

        logger.info(f"✅ Current fasting score retrieved for user {user_id}")
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "get_current_fasting_score")


@router.get("/score/trend/{user_id}")
async def get_fasting_score_trend(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get fasting score trend comparing current score vs last week.

    Uses the database function get_fasting_score_trend() to calculate:
    - current_score: Most recent score
    - previous_score: Score from ~7 days ago
    - score_change: Difference between current and previous
    - trend: 'up', 'down', or 'stable'

    Returns default values (0, 0, 0, 'stable') if no scores exist.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting score trend for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.rpc("get_fasting_score_trend", {"p_user_id": user_id}).execute()

        if result.data:
            row = result.data[0]
            trend_data = {
                "current_score": row.get("current_score", 0),
                "previous_score": row.get("previous_score", 0),
                "score_change": row.get("score_change", 0),
                "trend": row.get("trend", "stable"),
            }
            logger.info(f"✅ Fasting score trend retrieved for user {user_id}: {trend_data}")
            return trend_data

        # Return default if no data
        logger.info(f"No score trend data found for user {user_id}, returning defaults")
        return {
            "current_score": 0,
            "previous_score": 0,
            "score_change": 0,
            "trend": "stable",
        }

    except Exception as e:
        logger.error(f"Error getting fasting score trend: {e}")
        # Return default on error to not break the frontend
        return {
            "current_score": 0,
            "previous_score": 0,
            "score_change": 0,
            "trend": "stable",
        }


# ==================== Extended Protocol Helpers ====================

DANGEROUS_PROTOCOLS = [
    "24h Water Fast",
    "48h Water Fast",
    "72h Water Fast",
    "7-Day Water Fast",
]

def is_dangerous_protocol(protocol: str) -> bool:
    """Check if a protocol is considered dangerous/extended."""
    return protocol in DANGEROUS_PROTOCOLS


def get_protocol_fasting_hours(protocol: str) -> int:
    """Get the fasting hours for a protocol."""
    protocol_hours = {
        "12:12": 12,
        "14:10": 14,
        "16:8": 16,
        "18:6": 18,
        "20:4": 20,
        "OMAD": 23,
        "OMAD (One Meal a Day)": 23,
        "24h Water Fast": 24,
        "48h Water Fast": 48,
        "72h Water Fast": 72,
        "7-Day Water Fast": 168,
        "5:2": 24,
        "ADF": 24,
        "ADF (Alternate Day)": 24,
    }
    return protocol_hours.get(protocol, 16)
