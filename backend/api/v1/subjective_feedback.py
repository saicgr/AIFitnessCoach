"""
Subjective Results Tracking API endpoints.

Allows users to track how they "feel" before and after workouts,
enabling insights like "Your mood improved 23% since starting".

This feature addresses the user's desire to "feel their results"
beyond just physical metrics.
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from datetime import datetime, timedelta, date
from pydantic import BaseModel, Field
from enum import Enum

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from services.user_context_service import UserContextService, EventType

router = APIRouter()
user_context_service = UserContextService()
logger = get_logger(__name__)


# ============================================
# Pydantic Models
# ============================================

class MoodLevel(int, Enum):
    """Mood levels 1-5."""
    AWFUL = 1
    LOW = 2
    NEUTRAL = 3
    GOOD = 4
    GREAT = 5


class EnergyLevel(int, Enum):
    """Energy levels 1-5."""
    EXHAUSTED = 1
    TIRED = 2
    OKAY = 3
    ENERGIZED = 4
    PUMPED = 5


class PreWorkoutCheckinCreate(BaseModel):
    """Pre-workout check-in request."""
    user_id: str = Field(..., description="User UUID")
    workout_id: Optional[str] = Field(None, description="Workout UUID (optional at pre-check-in)")
    mood_before: int = Field(..., ge=1, le=5, description="Current mood 1-5")
    energy_before: Optional[int] = Field(None, ge=1, le=5, description="Energy level 1-5")
    sleep_quality: Optional[int] = Field(None, ge=1, le=5, description="Last night's sleep quality 1-5")
    stress_level: Optional[int] = Field(None, ge=1, le=5, description="Current stress level 1-5 (1=stressed, 5=calm)")


class PostWorkoutCheckinCreate(BaseModel):
    """Post-workout check-in request."""
    user_id: str = Field(..., description="User UUID")
    workout_id: str = Field(..., description="Workout UUID")
    mood_after: int = Field(..., ge=1, le=5, description="Post-workout mood 1-5")
    energy_after: Optional[int] = Field(None, ge=1, le=5, description="Post-workout energy 1-5")
    confidence_level: Optional[int] = Field(None, ge=1, le=5, description="Feeling stronger/confident 1-5")
    soreness_level: Optional[int] = Field(None, ge=1, le=5, description="Muscle soreness 1-5")
    feeling_stronger: bool = Field(False, description="Do you feel stronger?")
    notes: Optional[str] = Field(None, max_length=500, description="Optional notes")


class SubjectiveFeedback(BaseModel):
    """Complete subjective feedback record."""
    id: str
    user_id: str
    workout_id: Optional[str] = None
    mood_before: Optional[int] = None
    energy_before: Optional[int] = None
    sleep_quality: Optional[int] = None
    stress_level: Optional[int] = None
    mood_after: Optional[int] = None
    energy_after: Optional[int] = None
    confidence_level: Optional[int] = None
    soreness_level: Optional[int] = None
    feeling_stronger: bool = False
    notes: Optional[str] = None
    pre_checkin_at: Optional[datetime] = None
    post_checkin_at: Optional[datetime] = None
    created_at: datetime
    mood_change: Optional[int] = None  # Computed: mood_after - mood_before


class SubjectiveTrendsResponse(BaseModel):
    """Trends response for mood/energy over time."""
    user_id: str
    period_days: int
    total_workouts: int

    # Averages
    avg_mood_before: float
    avg_mood_after: float
    avg_mood_change: float
    avg_energy_before: float
    avg_energy_after: float
    avg_sleep_quality: float
    avg_confidence: float

    # Trends over time (positive = improving)
    mood_trend_percent: float
    energy_trend_percent: float
    confidence_trend_percent: float

    # Breakdown by period
    weekly_data: List[dict]

    # Insights
    feeling_stronger_count: int
    feeling_stronger_percent: float


class FeelResultsSummary(BaseModel):
    """High-level summary for "Feel Results" screen."""
    user_id: str
    total_workouts_tracked: int

    # Headline metrics
    mood_improvement_percent: float
    avg_post_workout_mood: float
    avg_post_workout_energy: float
    feeling_stronger_percent: float

    # Motivational insights
    insight_headline: str
    insight_detail: str

    # Best and worst patterns
    best_workout_day: Optional[str] = None
    best_time_of_day: Optional[str] = None
    mood_boost_from_exercise: float


# ============================================
# Helper Functions
# ============================================

def _compute_mood_change(record: dict) -> Optional[int]:
    """Compute mood change from before to after."""
    before = record.get("mood_before")
    after = record.get("mood_after")
    if before is not None and after is not None:
        return after - before
    return None


def _get_mood_emoji(level: int) -> str:
    """Get emoji for mood level."""
    emojis = {1: "", 2: "", 3: "", 4: "", 5: ""}
    return emojis.get(level, "")


def _get_energy_emoji(level: int) -> str:
    """Get emoji for energy level."""
    emojis = {1: "", 2: "", 3: "", 4: "", 5: ""}
    return emojis.get(level, "")


# ============================================
# Pre-Workout Check-in Endpoints
# ============================================

@router.post("/pre-checkin", response_model=SubjectiveFeedback)
async def create_pre_workout_checkin(checkin: PreWorkoutCheckinCreate):
    """
    Log a pre-workout check-in.

    This is called before starting a workout to capture baseline mood/energy.
    Quick and skippable - designed to take less than 5 seconds.
    """
    logger.info(f"Creating pre-workout check-in for user {checkin.user_id}")

    try:
        db = get_supabase_db()

        record = {
            "user_id": checkin.user_id,
            "workout_id": checkin.workout_id,
            "mood_before": checkin.mood_before,
            "energy_before": checkin.energy_before,
            "sleep_quality": checkin.sleep_quality,
            "stress_level": checkin.stress_level,
            "pre_checkin_at": datetime.utcnow().isoformat(),
        }

        result = db.client.table("workout_subjective_feedback").insert(record).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create pre-workout check-in")

        data = result.data[0]

        # Log user activity
        await log_user_activity(
            user_id=checkin.user_id,
            action="pre_workout_checkin",
            endpoint="/api/v1/subjective-feedback/pre-checkin",
            message=f"Pre-workout check-in: mood={checkin.mood_before}/5",
            metadata={
                "mood_before": checkin.mood_before,
                "energy_before": checkin.energy_before,
                "sleep_quality": checkin.sleep_quality,
            },
            status_code=200
        )

        # Log to user context service for AI personalization
        await user_context_service.log_event(
            user_id=checkin.user_id,
            event_type=EventType.SUBJECTIVE_PRE_CHECKIN,
            metadata={
                "mood_before": checkin.mood_before,
                "energy_before": checkin.energy_before,
                "sleep_quality": checkin.sleep_quality,
                "stress_level": checkin.stress_level,
                "workout_id": checkin.workout_id,
            },
        )

        logger.info(f"Pre-workout check-in created: {data['id']}")

        return SubjectiveFeedback(
            id=str(data["id"]),
            user_id=data["user_id"],
            workout_id=data.get("workout_id"),
            mood_before=data.get("mood_before"),
            energy_before=data.get("energy_before"),
            sleep_quality=data.get("sleep_quality"),
            stress_level=data.get("stress_level"),
            pre_checkin_at=data.get("pre_checkin_at"),
            created_at=data.get("created_at") or datetime.utcnow(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create pre-workout check-in: {e}")
        await log_user_error(
            user_id=checkin.user_id,
            action="pre_workout_checkin",
            error=e,
            endpoint="/api/v1/subjective-feedback/pre-checkin",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Post-Workout Check-in Endpoints
# ============================================

@router.post("/workouts/{workout_id}/post-checkin", response_model=SubjectiveFeedback)
async def create_post_workout_checkin(workout_id: str, checkin: PostWorkoutCheckinCreate):
    """
    Log a post-workout check-in.

    This is called after completing a workout to capture how the user feels.
    Updates an existing pre-checkin record or creates a new one.
    """
    logger.info(f"Creating post-workout check-in for workout {workout_id}")

    try:
        db = get_supabase_db()

        # Check if there's an existing pre-checkin for this workout
        existing = db.client.table("workout_subjective_feedback").select("*").eq(
            "workout_id", workout_id
        ).eq("user_id", checkin.user_id).execute()

        if existing.data:
            # Update existing record with post-workout data
            record_id = existing.data[0]["id"]
            update_data = {
                "mood_after": checkin.mood_after,
                "energy_after": checkin.energy_after,
                "confidence_level": checkin.confidence_level,
                "soreness_level": checkin.soreness_level,
                "feeling_stronger": checkin.feeling_stronger,
                "notes": checkin.notes,
                "post_checkin_at": datetime.utcnow().isoformat(),
            }

            result = db.client.table("workout_subjective_feedback").update(
                update_data
            ).eq("id", record_id).execute()
        else:
            # Create new record with just post-workout data
            record = {
                "user_id": checkin.user_id,
                "workout_id": workout_id,
                "mood_after": checkin.mood_after,
                "energy_after": checkin.energy_after,
                "confidence_level": checkin.confidence_level,
                "soreness_level": checkin.soreness_level,
                "feeling_stronger": checkin.feeling_stronger,
                "notes": checkin.notes,
                "post_checkin_at": datetime.utcnow().isoformat(),
            }

            result = db.client.table("workout_subjective_feedback").insert(record).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create post-workout check-in")

        data = result.data[0]
        mood_change = _compute_mood_change(data)

        # Log user activity
        await log_user_activity(
            user_id=checkin.user_id,
            action="post_workout_checkin",
            endpoint=f"/api/v1/subjective-feedback/workouts/{workout_id}/post-checkin",
            message=f"Post-workout check-in: mood={checkin.mood_after}/5, stronger={checkin.feeling_stronger}",
            metadata={
                "workout_id": workout_id,
                "mood_after": checkin.mood_after,
                "mood_change": mood_change,
                "feeling_stronger": checkin.feeling_stronger,
            },
            status_code=200
        )

        # Log to user context service for AI personalization
        await user_context_service.log_event(
            user_id=checkin.user_id,
            event_type=EventType.SUBJECTIVE_POST_CHECKIN,
            metadata={
                "workout_id": workout_id,
                "mood_after": checkin.mood_after,
                "energy_after": checkin.energy_after,
                "confidence_level": checkin.confidence_level,
                "soreness_level": checkin.soreness_level,
                "mood_change": mood_change,
                "feeling_stronger": checkin.feeling_stronger,
            },
        )

        # If user reported feeling stronger, log additional event for analytics
        if checkin.feeling_stronger:
            await user_context_service.log_event(
                user_id=checkin.user_id,
                event_type=EventType.FEELING_STRONGER_REPORTED,
                metadata={
                    "workout_id": workout_id,
                    "mood_after": checkin.mood_after,
                },
            )

        logger.info(f"Post-workout check-in created/updated: {data['id']}")

        return SubjectiveFeedback(
            id=str(data["id"]),
            user_id=data["user_id"],
            workout_id=data.get("workout_id"),
            mood_before=data.get("mood_before"),
            energy_before=data.get("energy_before"),
            sleep_quality=data.get("sleep_quality"),
            stress_level=data.get("stress_level"),
            mood_after=data.get("mood_after"),
            energy_after=data.get("energy_after"),
            confidence_level=data.get("confidence_level"),
            soreness_level=data.get("soreness_level"),
            feeling_stronger=data.get("feeling_stronger", False),
            notes=data.get("notes"),
            pre_checkin_at=data.get("pre_checkin_at"),
            post_checkin_at=data.get("post_checkin_at"),
            created_at=data.get("created_at") or datetime.utcnow(),
            mood_change=mood_change,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create post-workout check-in: {e}")
        await log_user_error(
            user_id=checkin.user_id,
            action="post_workout_checkin",
            error=e,
            endpoint=f"/api/v1/subjective-feedback/workouts/{workout_id}/post-checkin",
            metadata={"workout_id": workout_id},
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Trends Endpoints
# ============================================

@router.get("/progress/subjective-trends", response_model=SubjectiveTrendsResponse)
async def get_subjective_trends(
    user_id: str,
    days: int = Query(30, ge=7, le=365, description="Number of days to analyze")
):
    """
    Get mood/energy trends over time.

    Returns averages, trends, and weekly breakdown of subjective metrics.
    """
    logger.info(f"Getting subjective trends for user {user_id} ({days} days)")

    try:
        db = get_supabase_db()

        # Get all subjective feedback for the period
        start_date = (datetime.utcnow() - timedelta(days=days)).isoformat()

        result = db.client.table("workout_subjective_feedback").select("*").eq(
            "user_id", user_id
        ).gte("created_at", start_date).order("created_at").execute()

        records = result.data or []
        total_workouts = len(records)

        if total_workouts == 0:
            return SubjectiveTrendsResponse(
                user_id=user_id,
                period_days=days,
                total_workouts=0,
                avg_mood_before=0,
                avg_mood_after=0,
                avg_mood_change=0,
                avg_energy_before=0,
                avg_energy_after=0,
                avg_sleep_quality=0,
                avg_confidence=0,
                mood_trend_percent=0,
                energy_trend_percent=0,
                confidence_trend_percent=0,
                weekly_data=[],
                feeling_stronger_count=0,
                feeling_stronger_percent=0,
            )

        # Calculate averages
        mood_before_vals = [r["mood_before"] for r in records if r.get("mood_before")]
        mood_after_vals = [r["mood_after"] for r in records if r.get("mood_after")]
        energy_before_vals = [r["energy_before"] for r in records if r.get("energy_before")]
        energy_after_vals = [r["energy_after"] for r in records if r.get("energy_after")]
        sleep_vals = [r["sleep_quality"] for r in records if r.get("sleep_quality")]
        confidence_vals = [r["confidence_level"] for r in records if r.get("confidence_level")]

        avg_mood_before = sum(mood_before_vals) / len(mood_before_vals) if mood_before_vals else 0
        avg_mood_after = sum(mood_after_vals) / len(mood_after_vals) if mood_after_vals else 0
        avg_energy_before = sum(energy_before_vals) / len(energy_before_vals) if energy_before_vals else 0
        avg_energy_after = sum(energy_after_vals) / len(energy_after_vals) if energy_after_vals else 0
        avg_sleep = sum(sleep_vals) / len(sleep_vals) if sleep_vals else 0
        avg_confidence = sum(confidence_vals) / len(confidence_vals) if confidence_vals else 0

        # Calculate mood changes
        mood_changes = [
            r["mood_after"] - r["mood_before"]
            for r in records
            if r.get("mood_before") and r.get("mood_after")
        ]
        avg_mood_change = sum(mood_changes) / len(mood_changes) if mood_changes else 0

        # Calculate trends (compare first half vs second half of period)
        mid_point = len(records) // 2
        if mid_point > 0:
            first_half = records[:mid_point]
            second_half = records[mid_point:]

            first_mood = [r["mood_after"] for r in first_half if r.get("mood_after")]
            second_mood = [r["mood_after"] for r in second_half if r.get("mood_after")]

            first_energy = [r["energy_after"] for r in first_half if r.get("energy_after")]
            second_energy = [r["energy_after"] for r in second_half if r.get("energy_after")]

            first_conf = [r["confidence_level"] for r in first_half if r.get("confidence_level")]
            second_conf = [r["confidence_level"] for r in second_half if r.get("confidence_level")]

            def calc_trend(first: list, second: list) -> float:
                if not first or not second:
                    return 0
                first_avg = sum(first) / len(first)
                second_avg = sum(second) / len(second)
                if first_avg == 0:
                    return 0
                return ((second_avg - first_avg) / first_avg) * 100

            mood_trend = calc_trend(first_mood, second_mood)
            energy_trend = calc_trend(first_energy, second_energy)
            confidence_trend = calc_trend(first_conf, second_conf)
        else:
            mood_trend = 0
            energy_trend = 0
            confidence_trend = 0

        # Weekly breakdown
        weekly_data = []
        current_date = datetime.utcnow()
        for week_offset in range(min(4, days // 7)):
            week_end = current_date - timedelta(weeks=week_offset)
            week_start = week_end - timedelta(days=7)

            week_records = [
                r for r in records
                if week_start.isoformat() <= r.get("created_at", "") <= week_end.isoformat()
            ]

            week_mood_after = [r["mood_after"] for r in week_records if r.get("mood_after")]
            week_energy_after = [r["energy_after"] for r in week_records if r.get("energy_after")]

            weekly_data.append({
                "week": week_offset + 1,
                "week_start": week_start.date().isoformat(),
                "workout_count": len(week_records),
                "avg_mood": sum(week_mood_after) / len(week_mood_after) if week_mood_after else 0,
                "avg_energy": sum(week_energy_after) / len(week_energy_after) if week_energy_after else 0,
            })

        # Feeling stronger stats
        feeling_stronger_count = sum(1 for r in records if r.get("feeling_stronger"))
        feeling_stronger_percent = (feeling_stronger_count / total_workouts) * 100 if total_workouts > 0 else 0

        return SubjectiveTrendsResponse(
            user_id=user_id,
            period_days=days,
            total_workouts=total_workouts,
            avg_mood_before=round(avg_mood_before, 2),
            avg_mood_after=round(avg_mood_after, 2),
            avg_mood_change=round(avg_mood_change, 2),
            avg_energy_before=round(avg_energy_before, 2),
            avg_energy_after=round(avg_energy_after, 2),
            avg_sleep_quality=round(avg_sleep, 2),
            avg_confidence=round(avg_confidence, 2),
            mood_trend_percent=round(mood_trend, 1),
            energy_trend_percent=round(energy_trend, 1),
            confidence_trend_percent=round(confidence_trend, 1),
            weekly_data=weekly_data,
            feeling_stronger_count=feeling_stronger_count,
            feeling_stronger_percent=round(feeling_stronger_percent, 1),
        )

    except Exception as e:
        logger.error(f"Failed to get subjective trends: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/progress/feel-results", response_model=FeelResultsSummary)
async def get_feel_results_summary(user_id: str):
    """
    Get high-level "Feel Results" summary.

    Returns motivational insights like "Your mood improved 23% since starting".
    Designed for the Feel Results screen.
    """
    logger.info(f"Getting feel results summary for user {user_id}")

    try:
        db = get_supabase_db()

        # Get all subjective feedback for the user
        result = db.client.table("workout_subjective_feedback").select("*").eq(
            "user_id", user_id
        ).order("created_at").execute()

        records = result.data or []
        total = len(records)

        if total == 0:
            return FeelResultsSummary(
                user_id=user_id,
                total_workouts_tracked=0,
                mood_improvement_percent=0,
                avg_post_workout_mood=0,
                avg_post_workout_energy=0,
                feeling_stronger_percent=0,
                insight_headline="Start tracking how you feel!",
                insight_detail="Complete your first workout with a mood check-in to see your results.",
                mood_boost_from_exercise=0,
            )

        # Calculate mood improvement (comparing before vs after across all workouts)
        mood_changes = []
        for r in records:
            before = r.get("mood_before")
            after = r.get("mood_after")
            if before and after:
                mood_changes.append(after - before)

        avg_mood_change = sum(mood_changes) / len(mood_changes) if mood_changes else 0

        # Calculate average improvement as percentage (1-5 scale, so max improvement is 4)
        mood_improvement_percent = (avg_mood_change / 4) * 100 if mood_changes else 0

        # Post-workout averages
        mood_after_vals = [r["mood_after"] for r in records if r.get("mood_after")]
        energy_after_vals = [r["energy_after"] for r in records if r.get("energy_after")]

        avg_mood_after = sum(mood_after_vals) / len(mood_after_vals) if mood_after_vals else 0
        avg_energy_after = sum(energy_after_vals) / len(energy_after_vals) if energy_after_vals else 0

        # Feeling stronger percentage
        stronger_count = sum(1 for r in records if r.get("feeling_stronger"))
        feeling_stronger_pct = (stronger_count / total) * 100 if total > 0 else 0

        # Calculate mood boost from exercise
        positive_changes = [c for c in mood_changes if c > 0]
        mood_boost = (len(positive_changes) / len(mood_changes)) * 100 if mood_changes else 0

        # Generate motivational insights
        if avg_mood_change > 0.5:
            headline = f"You feel {abs(mood_improvement_percent):.0f}% better after working out!"
            detail = f"Your average post-workout mood is {avg_mood_after:.1f}/5. Exercise is clearly working for you!"
        elif avg_mood_change > 0:
            headline = "Working out is boosting your mood!"
            detail = f"You've tracked {total} workouts. Your mood improves by {avg_mood_change:.1f} points on average."
        elif feeling_stronger_pct > 50:
            headline = f"You feel stronger {feeling_stronger_pct:.0f}% of the time!"
            detail = "Your confidence is building with every workout. Keep up the great work!"
        elif avg_mood_after >= 4:
            headline = f"Your average post-workout mood: {avg_mood_after:.1f}/5"
            detail = "You consistently feel good after exercising. That's the power of movement!"
        else:
            headline = "Keep tracking to see your progress!"
            detail = f"You've completed {total} check-ins. Patterns will emerge over time."

        # TODO: Add time-of-day and day-of-week analysis for best_workout_day/time

        # Log feel results view for analytics
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEEL_RESULTS_VIEWED,
            metadata={
                "total_workouts_tracked": total,
                "mood_improvement_percent": round(mood_improvement_percent, 1),
                "avg_post_workout_mood": round(avg_mood_after, 1),
                "feeling_stronger_percent": round(feeling_stronger_pct, 1),
            },
        )

        return FeelResultsSummary(
            user_id=user_id,
            total_workouts_tracked=total,
            mood_improvement_percent=round(mood_improvement_percent, 1),
            avg_post_workout_mood=round(avg_mood_after, 1),
            avg_post_workout_energy=round(avg_energy_after, 1),
            feeling_stronger_percent=round(feeling_stronger_pct, 1),
            insight_headline=headline,
            insight_detail=detail,
            mood_boost_from_exercise=round(mood_boost, 1),
        )

    except Exception as e:
        logger.error(f"Failed to get feel results summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# History Endpoints
# ============================================

@router.get("/history", response_model=List[SubjectiveFeedback])
async def get_subjective_history(
    user_id: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0)
):
    """Get user's subjective feedback history."""
    logger.info(f"Getting subjective history for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("workout_subjective_feedback").select("*").eq(
            "user_id", user_id
        ).order("created_at", desc=True).range(offset, offset + limit - 1).execute()

        records = result.data or []

        return [
            SubjectiveFeedback(
                id=str(r["id"]),
                user_id=r["user_id"],
                workout_id=r.get("workout_id"),
                mood_before=r.get("mood_before"),
                energy_before=r.get("energy_before"),
                sleep_quality=r.get("sleep_quality"),
                stress_level=r.get("stress_level"),
                mood_after=r.get("mood_after"),
                energy_after=r.get("energy_after"),
                confidence_level=r.get("confidence_level"),
                soreness_level=r.get("soreness_level"),
                feeling_stronger=r.get("feeling_stronger", False),
                notes=r.get("notes"),
                pre_checkin_at=r.get("pre_checkin_at"),
                post_checkin_at=r.get("post_checkin_at"),
                created_at=r.get("created_at") or datetime.utcnow(),
                mood_change=_compute_mood_change(r),
            )
            for r in records
        ]

    except Exception as e:
        logger.error(f"Failed to get subjective history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/workouts/{workout_id}", response_model=Optional[SubjectiveFeedback])
async def get_workout_subjective_feedback(workout_id: str, user_id: str):
    """Get subjective feedback for a specific workout."""
    logger.info(f"Getting subjective feedback for workout {workout_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("workout_subjective_feedback").select("*").eq(
            "workout_id", workout_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            return None

        r = result.data[0]

        return SubjectiveFeedback(
            id=str(r["id"]),
            user_id=r["user_id"],
            workout_id=r.get("workout_id"),
            mood_before=r.get("mood_before"),
            energy_before=r.get("energy_before"),
            sleep_quality=r.get("sleep_quality"),
            stress_level=r.get("stress_level"),
            mood_after=r.get("mood_after"),
            energy_after=r.get("energy_after"),
            confidence_level=r.get("confidence_level"),
            soreness_level=r.get("soreness_level"),
            feeling_stronger=r.get("feeling_stronger", False),
            notes=r.get("notes"),
            pre_checkin_at=r.get("pre_checkin_at"),
            post_checkin_at=r.get("post_checkin_at"),
            created_at=r.get("created_at") or datetime.utcnow(),
            mood_change=_compute_mood_change(r),
        )

    except Exception as e:
        logger.error(f"Failed to get workout subjective feedback: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Quick Stats Endpoint
# ============================================

@router.get("/quick-stats")
async def get_quick_subjective_stats(user_id: str):
    """
    Get quick stats for display on home screen or profile.

    Returns simplified metrics suitable for widgets/tiles.
    """
    logger.info(f"Getting quick subjective stats for user {user_id}")

    try:
        db = get_supabase_db()

        # Get last 30 days of data
        start_date = (datetime.utcnow() - timedelta(days=30)).isoformat()

        result = db.client.table("workout_subjective_feedback").select("*").eq(
            "user_id", user_id
        ).gte("created_at", start_date).execute()

        records = result.data or []

        if not records:
            return {
                "has_data": False,
                "total_checkins": 0,
                "avg_mood_after": None,
                "mood_trend": None,
                "feeling_stronger_rate": None,
            }

        mood_after_vals = [r["mood_after"] for r in records if r.get("mood_after")]
        stronger_count = sum(1 for r in records if r.get("feeling_stronger"))

        # Calculate simple trend (last 7 vs previous 7)
        recent = records[-7:] if len(records) >= 7 else records
        earlier = records[-14:-7] if len(records) >= 14 else []

        recent_mood = [r["mood_after"] for r in recent if r.get("mood_after")]
        earlier_mood = [r["mood_after"] for r in earlier if r.get("mood_after")]

        mood_trend = None
        if recent_mood and earlier_mood:
            recent_avg = sum(recent_mood) / len(recent_mood)
            earlier_avg = sum(earlier_mood) / len(earlier_mood)
            if earlier_avg > 0:
                mood_trend = round(((recent_avg - earlier_avg) / earlier_avg) * 100, 1)

        return {
            "has_data": True,
            "total_checkins": len(records),
            "avg_mood_after": round(sum(mood_after_vals) / len(mood_after_vals), 1) if mood_after_vals else None,
            "mood_trend": mood_trend,
            "feeling_stronger_rate": round((stronger_count / len(records)) * 100, 1) if records else None,
        }

    except Exception as e:
        logger.error(f"Failed to get quick subjective stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))
