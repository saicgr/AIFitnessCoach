"""
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
from fastapi import APIRouter, HTTPException, Query, Depends, Request
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from decimal import Decimal
import uuid
import statistics

from pydantic import BaseModel, Field

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.rate_limiter import limiter
from core.exceptions import safe_internal_error

router = APIRouter()
logger = get_logger(__name__)

# ==================== Pydantic Models ====================

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

def calculate_correlation_score(fasting_days_success: List[bool], non_fasting_days_success: List[bool]) -> Optional[float]:
    """
    Calculate Pearson correlation between fasting and goal achievement.

    Returns a value between -1 and 1:
    - Positive: fasting correlates with more success
    - Negative: fasting correlates with less success
    - Near 0: no correlation
    """
    if not fasting_days_success or not non_fasting_days_success:
        return None

    try:
        # Convert to binary values for correlation
        all_days = [(1, 1 if s else 0) for s in fasting_days_success] + \
                   [(0, 1 if s else 0) for s in non_fasting_days_success]

        if len(all_days) < 5:  # Need minimum data for meaningful correlation
            return None

        fasting_values = [d[0] for d in all_days]
        success_values = [d[1] for d in all_days]

        # Calculate means
        mean_fasting = statistics.mean(fasting_values)
        mean_success = statistics.mean(success_values)

        # Calculate correlation
        numerator = sum((f - mean_fasting) * (s - mean_success)
                       for f, s in zip(fasting_values, success_values))

        sum_sq_fasting = sum((f - mean_fasting) ** 2 for f in fasting_values)
        sum_sq_success = sum((s - mean_success) ** 2 for s in success_values)

        denominator = (sum_sq_fasting * sum_sq_success) ** 0.5

        if denominator == 0:
            return 0.0

        return round(numerator / denominator, 3)

    except Exception as e:
        logger.warning(f"Could not calculate correlation: {e}")
        return None

def generate_impact_insight(
    weight_trend: Optional[str],
    avg_weight_fasting: Optional[float],
    avg_weight_non_fasting: Optional[float],
    workout_completion_fasting: Optional[float],
    workout_completion_non_fasting: Optional[float],
    goal_rate_fasting: Optional[float],
    goal_rate_non_fasting: Optional[float],
    correlation_score: Optional[float]
) -> Dict[str, Any]:
    """
    Create human-readable insight based on fasting impact data.
    """
    insights = {
        "key_findings": [],
        "personalized_tips": [],
        "overall_trend": "neutral",
        "weight_insight": None,
        "performance_insight": None,
        "goal_insight": None,
    }

    # Weight insights
    if avg_weight_fasting is not None and avg_weight_non_fasting is not None:
        weight_diff = avg_weight_non_fasting - avg_weight_fasting
        if abs(weight_diff) > 0.5:
            if weight_diff > 0:
                insights["key_findings"].append(
                    f"Your weight is {abs(weight_diff):.1f}kg lower on fasting days on average."
                )
                insights["weight_insight"] = {
                    "direction": "positive",
                    "difference_kg": round(weight_diff, 2),
                    "message": "Fasting appears to be supporting your weight goals."
                }
            else:
                insights["weight_insight"] = {
                    "direction": "neutral",
                    "difference_kg": round(weight_diff, 2),
                    "message": "Weight fluctuations are normal. Focus on the long-term trend."
                }

        if weight_trend == "decreasing":
            insights["personalized_tips"].append(
                "Your weight trend is positive! Continue with your current fasting schedule."
            )
            insights["overall_trend"] = "positive"

    # Workout performance insights
    if workout_completion_fasting is not None and workout_completion_non_fasting is not None:
        perf_diff = workout_completion_fasting - workout_completion_non_fasting
        if abs(perf_diff) > 5:  # 5% threshold
            if perf_diff > 0:
                insights["key_findings"].append(
                    f"You complete {perf_diff:.0f}% more of your workouts on fasting days."
                )
                insights["performance_insight"] = {
                    "direction": "positive",
                    "difference_percent": round(perf_diff, 1),
                    "message": "Fasting seems to boost your workout focus and completion."
                }
            else:
                insights["key_findings"].append(
                    f"Your workout completion is {abs(perf_diff):.0f}% lower on fasting days."
                )
                insights["performance_insight"] = {
                    "direction": "needs_attention",
                    "difference_percent": round(perf_diff, 1),
                    "message": "Consider scheduling intense workouts during eating windows."
                }
                insights["personalized_tips"].append(
                    "Try lighter workouts or schedule them closer to your eating window on fasting days."
                )

    # Goal achievement insights
    if goal_rate_fasting is not None and goal_rate_non_fasting is not None:
        goal_diff = goal_rate_fasting - goal_rate_non_fasting
        if abs(goal_diff) > 10:  # 10% threshold
            if goal_diff > 0:
                insights["key_findings"].append(
                    f"You hit {goal_diff:.0f}% more goals on fasting days."
                )
                insights["goal_insight"] = {
                    "direction": "positive",
                    "difference_percent": round(goal_diff, 1),
                    "message": "Fasting is positively impacting your goal achievement!"
                }
            else:
                insights["goal_insight"] = {
                    "direction": "neutral",
                    "difference_percent": round(goal_diff, 1),
                    "message": "Your goal achievement is consistent regardless of fasting."
                }

    # Correlation-based insight
    if correlation_score is not None:
        if correlation_score > 0.3:
            insights["personalized_tips"].append(
                "There's a positive correlation between your fasting and success. Keep it up!"
            )
            if insights["overall_trend"] == "neutral":
                insights["overall_trend"] = "positive"
        elif correlation_score < -0.3:
            insights["personalized_tips"].append(
                "Consider adjusting your fasting schedule to better align with your goals."
            )
            insights["overall_trend"] = "needs_attention"

    # Default tips if none generated
    if not insights["personalized_tips"]:
        insights["personalized_tips"] = [
            "Keep logging your data consistently for better insights.",
            "Track how you feel during workouts on fasting vs non-fasting days."
        ]

    if not insights["key_findings"]:
        insights["key_findings"] = [
            "Keep tracking to build more data for meaningful insights."
        ]

    return insights

async def get_fasting_status_for_date(user_id: str, target_date: date) -> Dict[str, Any]:
    """
    Check if a specific date was a fasting day for the user.
    Returns fasting info if found.
    """
    db = get_supabase_db()

    # Get fasting records that overlap with this date
    date_start = datetime.combine(target_date, datetime.min.time()).isoformat()
    date_end = datetime.combine(target_date, datetime.max.time()).isoformat()

    result = db.client.table("fasting_records").select(
        "id, protocol, protocol_type, status, completion_percentage, start_time, end_time"
    ).eq("user_id", user_id).neq("status", "cancelled").or_(
        f"start_time.lte.{date_end},end_time.gte.{date_start}"
    ).execute()

    if not result.data:
        return {
            "is_fasting_day": False,
            "fasting_record_id": None,
            "protocol": None,
            "completion_percent": None,
        }

    # Get the most relevant fasting record for this date
    record = result.data[0]
    return {
        "is_fasting_day": True,
        "fasting_record_id": record.get("id"),
        "protocol": record.get("protocol"),
        "completion_percent": record.get("completion_percentage"),
    }

async def link_weight_to_fasting(user_id: str, weight_date: date, weight_log_id: str) -> Optional[str]:
    """
    Associate weight log with any fasting record from that date.
    Returns the fasting_record_id if linked.
    """
    fasting_status = await get_fasting_status_for_date(user_id, weight_date)

    if fasting_status["is_fasting_day"] and fasting_status["fasting_record_id"]:
        db = get_supabase_db()

        # Update the weight log with the fasting record link
        db.client.table("weight_logs").update({
            "fasting_record_id": fasting_status["fasting_record_id"],
            "updated_at": datetime.utcnow().isoformat(),
        }).eq("id", weight_log_id).execute()

        return fasting_status["fasting_record_id"]

    return None

def interpret_correlation(score: Optional[float]) -> str:
    """Interpret the correlation score for users."""
    if score is None:
        return "Not enough data to determine correlation."

    if score > 0.5:
        return "Strong positive correlation: Fasting strongly supports your goal achievement."
    elif score > 0.3:
        return "Moderate positive correlation: Fasting appears to help your goals."
    elif score > 0.1:
        return "Weak positive correlation: Slight benefit from fasting observed."
    elif score > -0.1:
        return "No significant correlation: Fasting doesn't appear to affect goal achievement."
    elif score > -0.3:
        return "Weak negative correlation: Goals may be slightly harder on fasting days."
    elif score > -0.5:
        return "Moderate negative correlation: Consider adjusting your fasting approach."
    else:
        return "Strong negative correlation: Your current fasting may be hindering goals."

# ==================== Weight Logging Endpoints ====================

@router.post("/weight", response_model=WeightLogResponse)
async def log_weight_with_fasting(
    data: LogWeightWithFastingRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Log weight with automatic fasting day detection.

    Automatically checks if the user has an active fast or completed fast on the given date
    and links the weight log to the fasting record if applicable.
    """
    if str(current_user["id"]) != str(data.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Logging weight for user {data.user_id} on {data.date}")

    try:
        db = get_supabase_db()

        # Parse the date
        try:
            log_date = datetime.strptime(data.date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")

        # Check fasting status for this date
        fasting_status = await get_fasting_status_for_date(data.user_id, log_date)

        # Use explicitly provided fasting_record_id if given, otherwise use detected one
        fasting_record_id = data.fasting_record_id or fasting_status.get("fasting_record_id")

        # Insert into body_measurements table (consolidated weight storage)
        # The database trigger will auto-populate fasting context and sync to fasting_weight_correlation
        measurement_data = {
            "user_id": data.user_id,
            "weight_kg": data.weight_kg,
            "measured_at": f"{data.date}T12:00:00Z",  # Use noon as default time for date-only input
            "measurement_source": "manual",
            "notes": data.notes,
        }

        result = db.client.table("body_measurements").insert(measurement_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to log weight")

        # Re-fetch to get trigger-populated fasting fields
        row = result.data[0]
        refetch = db.client.table("body_measurements").select("*").eq("id", row["id"]).single().execute()
        if refetch.data:
            row = refetch.data

        # Log activity
        await log_user_activity(
            user_id=data.user_id,
            action="weight_logged_with_fasting",
            endpoint="/api/v1/fasting-impact/weight",
            message=f"Logged weight {data.weight_kg}kg on {data.date}" +
                    (f" (fasting day: {fasting_status.get('protocol')})" if fasting_status["is_fasting_day"] else ""),
            metadata={
                "weight_kg": data.weight_kg,
                "is_fasting_day": fasting_status["is_fasting_day"],
                "fasting_protocol": fasting_status.get("protocol"),
            },
            status_code=200
        )

        # Construct response using data from body_measurements (with trigger-populated fasting context)
        response_data = {
            "id": str(row["id"]),
            "user_id": data.user_id,
            "weight_kg": data.weight_kg,
            "date": data.date,
            "notes": data.notes,
            # Use trigger-populated fasting data from body_measurements, fall back to pre-fetched status
            "fasting_record_id": str(row["fasting_record_id"]) if row.get("fasting_record_id") else fasting_record_id,
            "is_fasting_day": row.get("is_fasting_day", fasting_status["is_fasting_day"]),
            "fasting_protocol": row.get("fasting_protocol") or fasting_status.get("protocol"),
            "fasting_completion_percent": fasting_status.get("completion_percent"),
            "created_at": row.get("created_at") or datetime.utcnow().isoformat(),
        }

        return WeightLogResponse(**response_data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error logging weight: {e}")
        await log_user_error(
            user_id=data.user_id,
            action="weight_logged_with_fasting",
            error=e,
            endpoint="/api/v1/fasting-impact/weight",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

@router.get("/weight-correlation/{user_id}", response_model=FastingWeightCorrelationResponse)
async def get_weight_correlation(
    user_id: str,
    days: int = Query(default=30, ge=7, le=365, description="Number of days to analyze"),
    include_non_fasting: bool = Query(default=True, description="Include non-fasting days in response"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get weight logs with fasting correlation data.

    Returns weight logs tagged with whether they were on fasting days,
    along with summary statistics comparing fasting vs non-fasting days.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting weight correlation for user {user_id} (last {days} days)")

    try:
        db = get_supabase_db()

        # Calculate date range
        end_date = date.today()
        start_date = end_date - timedelta(days=days)

        # Get weight correlation data from fasting_weight_correlation table
        # This table is populated automatically by a trigger when weight is logged
        result = db.client.table("fasting_weight_correlation").select("*").eq(
            "user_id", user_id
        ).gte("date", start_date.isoformat()).lte("date", end_date.isoformat()).order(
            "date", desc=True
        ).execute()

        weight_logs = []
        fasting_day_weights = []
        non_fasting_day_weights = []

        for row in (result.data or []):
            is_fasting = row.get("is_fasting_day", False)
            weight = row.get("weight_kg", 0)

            if is_fasting:
                fasting_day_weights.append(weight)
            else:
                non_fasting_day_weights.append(weight)

            # Calculate completion percent from duration if available
            fasting_duration = row.get("fasting_duration_minutes", 0)
            # Assume 16h (960 min) as default goal for completion calculation
            completion_percent = min(100.0, (fasting_duration / 960) * 100) if fasting_duration else None

            if include_non_fasting or is_fasting:
                weight_logs.append(WeightLogResponse(
                    id=row.get("id"),
                    user_id=row.get("user_id"),
                    weight_kg=row.get("weight_kg"),
                    date=row.get("date"),
                    notes=row.get("notes"),
                    fasting_record_id=row.get("fasting_record_id"),
                    is_fasting_day=is_fasting,
                    fasting_protocol=row.get("fasting_protocol"),
                    fasting_completion_percent=completion_percent if row.get("fasting_completed_goal") else None,
                    created_at=row.get("created_at"),
                ))

        # Calculate summary statistics
        summary = {
            "total_logs": len(result.data or []),
            "fasting_day_logs": len(fasting_day_weights),
            "non_fasting_day_logs": len(non_fasting_day_weights),
            "avg_weight_fasting_days": round(statistics.mean(fasting_day_weights), 2) if fasting_day_weights else None,
            "avg_weight_non_fasting_days": round(statistics.mean(non_fasting_day_weights), 2) if non_fasting_day_weights else None,
            "weight_difference": None,
        }

        if summary["avg_weight_fasting_days"] and summary["avg_weight_non_fasting_days"]:
            summary["weight_difference"] = round(
                summary["avg_weight_non_fasting_days"] - summary["avg_weight_fasting_days"], 2
            )

        # Log activity for context tracking
        await log_user_activity(
            user_id=user_id,
            action="weight_correlation_viewed",
            endpoint=f"/api/v1/fasting-impact/weight-correlation/{user_id}",
            message=f"Viewed weight correlation data for {days} days",
            metadata={
                "days": days,
                "total_logs": summary["total_logs"],
                "fasting_day_logs": summary["fasting_day_logs"],
                "non_fasting_day_logs": summary["non_fasting_day_logs"],
                "weight_difference": summary["weight_difference"],
            },
            status_code=200
        )

        return FastingWeightCorrelationResponse(
            user_id=user_id,
            period_days=days,
            weight_logs=weight_logs,
            summary=summary,
        )

    except Exception as e:
        logger.error(f"Error getting weight correlation: {e}")
        await log_user_error(
            user_id=user_id,
            action="weight_correlation_viewed",
            error=e,
            endpoint=f"/api/v1/fasting-impact/weight-correlation/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

# ==================== Impact Analysis Endpoints ====================

@router.get("/analysis/{user_id}", response_model=FastingGoalImpactResponse)
async def get_fasting_impact_analysis(
    user_id: str,
    period: str = Query(default="month", description="Period: 'week', 'month', '3months', 'all'"),
    current_user: dict = Depends(get_current_user),
):
    """
    Analyze fasting impact on goals.

    Compares performance on fasting vs non-fasting days:
    - Weight trends
    - Workout completion rates
    - Goal achievement rates
    - Calculates correlation score
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting impact analysis for user {user_id} (period: {period})")

    try:
        db = get_supabase_db()

        # Calculate date range
        today = date.today()
        if period == "week":
            start_date = today - timedelta(days=7)
        elif period == "month":
            start_date = today - timedelta(days=30)
        elif period == "3months":
            start_date = today - timedelta(days=90)
        else:
            start_date = today - timedelta(days=365)  # 'all' defaults to 1 year

        # Get fasting records
        fasting_result = db.client.table("fasting_records").select(
            "id, start_time, end_time, status, completion_percentage"
        ).eq("user_id", user_id).gte(
            "start_time", start_date.isoformat()
        ).neq("status", "cancelled").execute()

        fasting_dates = set()
        for record in (fasting_result.data or []):
            try:
                start = datetime.fromisoformat(record["start_time"].replace("Z", "+00:00")).date()
                fasting_dates.add(start.isoformat())
            except Exception as e:
                logger.debug(f"Failed to parse fasting date: {e}")

        # Get weight logs
        weight_result = db.client.table("weight_logs").select("*").eq(
            "user_id", user_id
        ).gte("logged_at", start_date.isoformat()).execute()

        fasting_weights = []
        non_fasting_weights = []
        for row in (weight_result.data or []):
            weight = row.get("weight_kg", 0)
            log_date = (row.get("logged_at") or "")[:10]  # Extract date part
            # Check if this date was a fasting day (weight_logs doesn't have is_fasting_day column)
            if log_date in fasting_dates:
                fasting_weights.append(weight)
            else:
                non_fasting_weights.append(weight)

        # Get workout completions
        workout_result = db.client.table("workout_logs").select(
            "id, completed_at"
        ).eq("user_id", user_id).gte("completed_at", start_date.isoformat()).execute()

        fasting_workouts = []
        non_fasting_workouts = []
        for row in (workout_result.data or []):
            workout_date = (row.get("completed_at") or "")[:10]  # Extract date part
            completion = 100  # workout_logs doesn't have completion_percentage, assume complete
            is_fasting = workout_date in fasting_dates

            if is_fasting:
                fasting_workouts.append(completion)
            else:
                non_fasting_workouts.append(completion)

        # Get goal achievements (weekly personal goals)
        goals_result = db.client.table("weekly_personal_goals").select(
            "created_at, status"
        ).eq("user_id", user_id).gte("created_at", start_date.isoformat()).execute()

        fasting_goals_success = []
        non_fasting_goals_success = []
        goals_fasting_hit = 0
        goals_non_fasting_hit = 0

        for row in (goals_result.data or []):
            goal_date = (row.get("created_at") or "")[:10]
            completed = row.get("status") == "completed"
            is_fasting = goal_date in fasting_dates

            if is_fasting:
                fasting_goals_success.append(completed)
                if completed:
                    goals_fasting_hit += 1
            else:
                non_fasting_goals_success.append(completed)
                if completed:
                    goals_non_fasting_hit += 1

        # Calculate metrics
        avg_weight_fasting = round(statistics.mean(fasting_weights), 2) if fasting_weights else None
        avg_weight_non_fasting = round(statistics.mean(non_fasting_weights), 2) if non_fasting_weights else None

        avg_workout_fasting = round(statistics.mean(fasting_workouts), 1) if fasting_workouts else None
        avg_workout_non_fasting = round(statistics.mean(non_fasting_workouts), 1) if non_fasting_workouts else None

        goal_rate_fasting = round(goals_fasting_hit / len(fasting_goals_success) * 100, 1) if fasting_goals_success else None
        goal_rate_non_fasting = round(goals_non_fasting_hit / len(non_fasting_goals_success) * 100, 1) if non_fasting_goals_success else None

        # Determine weight trend on fasting days
        weight_trend = None
        if len(fasting_weights) >= 3:
            first_half = statistics.mean(fasting_weights[:len(fasting_weights)//2])
            second_half = statistics.mean(fasting_weights[len(fasting_weights)//2:])
            if second_half < first_half - 0.5:
                weight_trend = "decreasing"
            elif second_half > first_half + 0.5:
                weight_trend = "increasing"
            else:
                weight_trend = "stable"

        # Calculate correlation
        correlation = calculate_correlation_score(fasting_goals_success, non_fasting_goals_success)
        correlation_interpretation = interpret_correlation(correlation)

        # Generate summary and recommendations
        recommendations = []
        summary_parts = []

        if avg_weight_fasting and avg_weight_non_fasting:
            diff = avg_weight_non_fasting - avg_weight_fasting
            if diff > 0.5:
                summary_parts.append("Fasting days show lower average weight.")
                recommendations.append("Your fasting routine appears to support weight management.")
            elif diff < -0.5:
                summary_parts.append("Weight is slightly higher on fasting days.")
                recommendations.append("This is normal - hydration and timing affect measurements.")

        if avg_workout_fasting and avg_workout_non_fasting:
            if avg_workout_fasting > avg_workout_non_fasting + 5:
                summary_parts.append("Workout completion is higher on fasting days.")
                recommendations.append("You seem to perform well during fasted workouts.")
            elif avg_workout_fasting < avg_workout_non_fasting - 5:
                summary_parts.append("Workout completion is lower on fasting days.")
                recommendations.append("Consider scheduling intense workouts during eating windows.")

        if goal_rate_fasting and goal_rate_non_fasting:
            if goal_rate_fasting > goal_rate_non_fasting + 10:
                summary_parts.append("Goal achievement is higher on fasting days.")
            elif goal_rate_fasting < goal_rate_non_fasting - 10:
                summary_parts.append("Goal achievement is lower on fasting days.")

        if not summary_parts:
            summary_parts.append("Not enough data yet for meaningful comparison.")

        if not recommendations:
            recommendations = ["Keep tracking to build more insights about your fasting patterns."]

        response = FastingGoalImpactResponse(
            user_id=user_id,
            period=period,
            analysis_date=today.isoformat(),
            avg_weight_fasting_days=avg_weight_fasting,
            avg_weight_non_fasting_days=avg_weight_non_fasting,
            weight_trend_fasting=weight_trend,
            workouts_on_fasting_days=len(fasting_workouts),
            workouts_on_non_fasting_days=len(non_fasting_workouts),
            avg_workout_completion_fasting=avg_workout_fasting,
            avg_workout_completion_non_fasting=avg_workout_non_fasting,
            goals_hit_on_fasting_days=goals_fasting_hit,
            goals_hit_on_non_fasting_days=goals_non_fasting_hit,
            goal_completion_rate_fasting=goal_rate_fasting,
            goal_completion_rate_non_fasting=goal_rate_non_fasting,
            correlation_score=correlation,
            correlation_interpretation=correlation_interpretation,
            fasting_impact_summary=" ".join(summary_parts),
            recommendations=recommendations,
        )

        # Log activity for context tracking
        await log_user_activity(
            user_id=user_id,
            action="fasting_impact_viewed",
            endpoint=f"/api/v1/fasting-impact/analysis/{user_id}",
            message=f"Viewed fasting impact analysis for period: {period}",
            metadata={
                "period": period,
                "correlation_score": correlation,
                "weight_trend": weight_trend,
                "fasting_days_analyzed": len(fasting_dates),
                "workouts_on_fasting_days": len(fasting_workouts),
                "workouts_on_non_fasting_days": len(non_fasting_workouts),
                "goal_rate_fasting": goal_rate_fasting,
                "goal_rate_non_fasting": goal_rate_non_fasting,
            },
            status_code=200
        )

        return response

    except Exception as e:
        logger.error(f"Error analyzing fasting impact: {e}")
        await log_user_error(
            user_id=user_id,
            action="fasting_impact_viewed",
            error=e,
            endpoint=f"/api/v1/fasting-impact/analysis/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

@router.post("/analyze/{user_id}", response_model=FastingGoalImpactResponse)
async def trigger_fasting_analysis(
    user_id: str,
    period: str = Query(default="month", description="Period: 'week', 'month', '3months', 'all'"),
    current_user: dict = Depends(get_current_user),
):
    """
    Trigger fresh analysis and store results.

    Recalculates all metrics and stores the analysis results for future reference.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Triggering fasting analysis for user {user_id}")

    try:
        # Get the analysis
        analysis = await get_fasting_impact_analysis(user_id, period)

        db = get_supabase_db()

        # Store the analysis results
        analysis_record = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "period": period,
            "analysis_date": analysis.analysis_date,
            "avg_weight_fasting_days": analysis.avg_weight_fasting_days,
            "avg_weight_non_fasting_days": analysis.avg_weight_non_fasting_days,
            "weight_trend_fasting": analysis.weight_trend_fasting,
            "workouts_on_fasting_days": analysis.workouts_on_fasting_days,
            "workouts_on_non_fasting_days": analysis.workouts_on_non_fasting_days,
            "avg_workout_completion_fasting": analysis.avg_workout_completion_fasting,
            "avg_workout_completion_non_fasting": analysis.avg_workout_completion_non_fasting,
            "goals_hit_on_fasting_days": analysis.goals_hit_on_fasting_days,
            "goals_hit_on_non_fasting_days": analysis.goals_hit_on_non_fasting_days,
            "goal_completion_rate_fasting": analysis.goal_completion_rate_fasting,
            "goal_completion_rate_non_fasting": analysis.goal_completion_rate_non_fasting,
            "correlation_score": analysis.correlation_score,
            "fasting_impact_summary": analysis.fasting_impact_summary,
            "recommendations": analysis.recommendations,
            "created_at": datetime.utcnow().isoformat(),
        }

        # Try to store (may fail if table doesn't exist yet)
        try:
            db.client.table("fasting_impact_analysis").insert(analysis_record).execute()
        except Exception as store_error:
            logger.warning(f"Could not store analysis (table may not exist): {store_error}")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="fasting_analysis_triggered",
            endpoint=f"/api/v1/fasting-impact/analyze/{user_id}",
            message=f"Triggered fasting impact analysis for {period}",
            metadata={"period": period, "correlation_score": analysis.correlation_score},
            status_code=200
        )

        return analysis

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error triggering fasting analysis: {e}")
        await log_user_error(
            user_id=user_id,
            action="fasting_analysis_triggered",
            error=e,
            endpoint=f"/api/v1/fasting-impact/analyze/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

# ==================== Insights Endpoint ====================

@router.get("/insights/{user_id}", response_model=FastingImpactInsightResponse)
async def get_fasting_insights(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get AI-generated insights about fasting impact.

    Returns structured insights about weight, performance, and goals
    based on the user's fasting patterns.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting fasting insights for user {user_id}")

    try:
        # Get the analysis first
        analysis = await get_fasting_impact_analysis(user_id, "month")

        # Generate insights
        insights_data = generate_impact_insight(
            weight_trend=analysis.weight_trend_fasting,
            avg_weight_fasting=analysis.avg_weight_fasting_days,
            avg_weight_non_fasting=analysis.avg_weight_non_fasting_days,
            workout_completion_fasting=analysis.avg_workout_completion_fasting,
            workout_completion_non_fasting=analysis.avg_workout_completion_non_fasting,
            goal_rate_fasting=analysis.goal_completion_rate_fasting,
            goal_rate_non_fasting=analysis.goal_completion_rate_non_fasting,
            correlation_score=analysis.correlation_score,
        )

        # Determine confidence level based on data quantity
        total_data_points = (
            analysis.workouts_on_fasting_days +
            analysis.workouts_on_non_fasting_days +
            analysis.goals_hit_on_fasting_days +
            analysis.goals_hit_on_non_fasting_days
        )

        if total_data_points >= 30:
            confidence = "high"
        elif total_data_points >= 10:
            confidence = "medium"
        else:
            confidence = "low"

        # Log activity for context tracking
        await log_user_activity(
            user_id=user_id,
            action="fasting_insights_viewed",
            endpoint=f"/api/v1/fasting-impact/insights/{user_id}",
            message=f"Viewed fasting insights with {confidence} confidence",
            metadata={
                "overall_trend": insights_data.get("overall_trend", "neutral"),
                "confidence_level": confidence,
                "total_data_points": total_data_points,
                "key_findings_count": len(insights_data.get("key_findings", [])),
                "has_weight_insight": insights_data.get("weight_insight") is not None,
                "has_performance_insight": insights_data.get("performance_insight") is not None,
                "has_goal_insight": insights_data.get("goal_insight") is not None,
            },
            status_code=200
        )

        return FastingImpactInsightResponse(
            user_id=user_id,
            generated_at=datetime.utcnow().isoformat(),
            weight_insight=insights_data.get("weight_insight"),
            performance_insight=insights_data.get("performance_insight"),
            goal_insight=insights_data.get("goal_insight"),
            key_findings=insights_data.get("key_findings", []),
            personalized_tips=insights_data.get("personalized_tips", []),
            overall_trend=insights_data.get("overall_trend", "neutral"),
            confidence_level=confidence,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting fasting insights: {e}")
        await log_user_error(
            user_id=user_id,
            action="fasting_insights_viewed",
            error=e,
            endpoint=f"/api/v1/fasting-impact/insights/{user_id}",
            status_code=500
        )
        raise safe_internal_error(e, "endpoint")

# ==================== Calendar Endpoint ====================

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
        raise HTTPException(status_code=422, detail=str(e))

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
