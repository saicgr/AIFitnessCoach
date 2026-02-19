"""
Injury Tracking API endpoints.

Allows users to:
- Report new injuries with body part, type, and severity
- Track recovery progress with check-ins
- View assigned rehab exercises and mark them complete
- Get workout modifications based on active injuries

This module integrates with the user_context_logs for AI personalization
and provides workout modification recommendations based on injury status.
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date, timedelta
from enum import Enum

from core.supabase_client import get_supabase
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Enums
# =============================================================================

class InjuryType(str, Enum):
    STRAIN = "strain"
    SPRAIN = "sprain"
    OVERUSE = "overuse"
    ACUTE = "acute"
    CHRONIC = "chronic"


class InjurySeverity(str, Enum):
    MILD = "mild"
    MODERATE = "moderate"
    SEVERE = "severe"


class RecoveryPhase(str, Enum):
    ACUTE = "acute"
    SUBACUTE = "subacute"
    RECOVERY = "recovery"
    HEALED = "healed"


class InjuryStatus(str, Enum):
    ACTIVE = "active"
    RECOVERING = "recovering"
    HEALED = "healed"
    CHRONIC = "chronic"


# =============================================================================
# Pydantic Models
# =============================================================================

class InjuryReportRequest(BaseModel):
    """Request to report a new injury."""
    body_part: str = Field(..., min_length=1, max_length=100)
    injury_type: Optional[InjuryType] = None
    severity: InjurySeverity = InjurySeverity.MILD
    pain_level: Optional[int] = Field(default=None, ge=0, le=10)
    occurred_at: Optional[date] = None
    expected_recovery_date: Optional[date] = None
    affects_exercises: Optional[List[str]] = None
    affects_muscles: Optional[List[str]] = None
    notes: Optional[str] = Field(default=None, max_length=1000)
    activity_when_occurred: Optional[str] = Field(default=None, max_length=200)


class InjuryUpdateRequest(BaseModel):
    """Request to update an existing injury."""
    status: Optional[InjuryStatus] = None
    recovery_phase: Optional[RecoveryPhase] = None
    pain_level: Optional[int] = Field(default=None, ge=0, le=10)
    expected_recovery_date: Optional[date] = None
    affects_exercises: Optional[List[str]] = None
    affects_muscles: Optional[List[str]] = None
    notes: Optional[str] = Field(default=None, max_length=1000)


class InjuryCheckInRequest(BaseModel):
    """Request to add a recovery check-in."""
    pain_level: Optional[int] = Field(default=None, ge=0, le=10)
    mobility_rating: Optional[int] = Field(default=None, ge=1, le=5)
    recovery_phase: Optional[RecoveryPhase] = None
    can_workout: bool = True
    workout_modifications: Optional[str] = Field(default=None, max_length=500)
    notes: Optional[str] = Field(default=None, max_length=1000)


class InjuryCheckIn(BaseModel):
    """A recovery check-in entry."""
    id: str
    injury_id: str
    user_id: str
    pain_level: Optional[int] = None
    mobility_rating: Optional[int] = None
    recovery_phase: Optional[RecoveryPhase] = None
    can_workout: bool = True
    workout_modifications: Optional[str] = None
    notes: Optional[str] = None
    checked_at: datetime


class RehabExercise(BaseModel):
    """A rehabilitation exercise assigned for an injury."""
    id: str
    injury_id: str
    exercise_name: str
    exercise_type: Optional[str] = None
    sets: Optional[int] = None
    reps: Optional[int] = None
    hold_seconds: Optional[int] = None
    frequency_per_day: int = 1
    notes: Optional[str] = None
    assigned_at: datetime
    completed_count: int = 0
    last_completed_at: Optional[datetime] = None


class Injury(BaseModel):
    """An injury record."""
    id: str
    user_id: str
    body_part: str
    injury_type: Optional[InjuryType] = None
    severity: InjurySeverity
    reported_at: datetime
    occurred_at: Optional[date] = None
    expected_recovery_date: Optional[date] = None
    actual_recovery_date: Optional[date] = None
    recovery_phase: RecoveryPhase = RecoveryPhase.ACUTE
    pain_level: Optional[int] = None
    affects_exercises: Optional[List[str]] = None
    affects_muscles: Optional[List[str]] = None
    notes: Optional[str] = None
    activity_when_occurred: Optional[str] = None
    status: InjuryStatus = InjuryStatus.ACTIVE
    created_at: datetime
    updated_at: datetime


class InjuryWithDetails(Injury):
    """Injury with additional details like check-ins and rehab exercises."""
    check_ins: List[InjuryCheckIn] = []
    rehab_exercises: List[RehabExercise] = []
    days_since_reported: int = 0
    progress_percentage: Optional[float] = None


class InjurySummary(BaseModel):
    """Summary view of an injury for list views."""
    id: str
    body_part: str
    injury_type: Optional[InjuryType] = None
    severity: InjurySeverity
    recovery_phase: RecoveryPhase
    pain_level: Optional[int] = None
    status: InjuryStatus
    reported_at: datetime
    expected_recovery_date: Optional[date] = None
    days_since_reported: int = 0


class ExerciseModification(BaseModel):
    """A modification for a specific exercise based on injuries."""
    exercise_name: str
    modification_type: str
    reason: str
    alternative_exercise: Optional[str] = None
    weight_reduction_percentage: Optional[int] = None


class MuscleModification(BaseModel):
    """A modification for a muscle group based on injuries."""
    muscle_group: str
    modification_type: str
    reason: str
    severity: InjurySeverity


class WorkoutModifications(BaseModel):
    """Workout modifications based on active injuries."""
    user_id: str
    has_active_injuries: bool = False
    active_injury_count: int = 0
    exercises_to_avoid: List[str] = []
    muscles_to_limit: List[str] = []
    exercise_modifications: List[ExerciseModification] = []
    muscle_modifications: List[MuscleModification] = []
    general_recommendations: List[str] = []
    can_do_upper_body: bool = True
    can_do_lower_body: bool = True
    can_do_core: bool = True
    can_do_cardio: bool = True


class InjuryReportResponse(BaseModel):
    """Response after reporting an injury."""
    success: bool
    message: str
    injury: Injury
    recommended_rehab_exercises: Optional[List[str]] = None


class InjuryListResponse(BaseModel):
    """Response with a list of injuries."""
    injuries: List[InjurySummary]
    count: int = 0
    active_count: int = 0


class CheckInListResponse(BaseModel):
    """Response with a list of check-ins."""
    check_ins: List[InjuryCheckIn]
    count: int = 0
    injury_id: str


# =============================================================================
# Helper Functions
# =============================================================================

def _parse_injury(data: dict) -> Injury:
    """Parse database row to Injury model."""
    return Injury(
        id=str(data["id"]),
        user_id=data["user_id"],
        body_part=data["body_part"],
        injury_type=InjuryType(data["injury_type"]) if data.get("injury_type") else None,
        severity=InjurySeverity(data["severity"]),
        reported_at=data.get("reported_at") or datetime.utcnow(),
        occurred_at=data.get("occurred_at"),
        expected_recovery_date=data.get("expected_recovery_date"),
        actual_recovery_date=data.get("actual_recovery_date"),
        recovery_phase=RecoveryPhase(data.get("recovery_phase", "acute")),
        pain_level=data.get("pain_level"),
        affects_exercises=data.get("affects_exercises") or [],
        affects_muscles=data.get("affects_muscles") or [],
        notes=data.get("notes"),
        activity_when_occurred=data.get("activity_when_occurred"),
        status=InjuryStatus(data.get("status", "active")),
        created_at=data.get("created_at") or datetime.utcnow(),
        updated_at=data.get("updated_at") or datetime.utcnow(),
    )


def _parse_injury_summary(data: dict) -> InjurySummary:
    """Parse database row to InjurySummary model."""
    reported_at = data.get("reported_at")
    if isinstance(reported_at, str):
        reported_at = datetime.fromisoformat(reported_at.replace("Z", "+00:00"))
    elif not reported_at:
        reported_at = datetime.utcnow()

    days_since = (datetime.utcnow() - reported_at.replace(tzinfo=None)).days if reported_at else 0

    return InjurySummary(
        id=str(data["id"]),
        body_part=data["body_part"],
        injury_type=InjuryType(data["injury_type"]) if data.get("injury_type") else None,
        severity=InjurySeverity(data["severity"]),
        recovery_phase=RecoveryPhase(data.get("recovery_phase", "acute")),
        pain_level=data.get("pain_level"),
        status=InjuryStatus(data.get("status", "active")),
        reported_at=reported_at,
        expected_recovery_date=data.get("expected_recovery_date"),
        days_since_reported=max(0, days_since),
    )


def _calculate_expected_recovery_date(severity: InjurySeverity) -> date:
    """Calculate expected recovery date based on severity."""
    recovery_days = {
        InjurySeverity.MILD: 7,
        InjurySeverity.MODERATE: 14,
        InjurySeverity.SEVERE: 35,
    }
    days = recovery_days.get(severity, 7)
    return (datetime.utcnow() + timedelta(days=days)).date()


def _get_recommended_rehab_exercises(body_part: str) -> List[str]:
    """Get recommended rehab exercises based on body part."""
    recommendations = {
        "knee": ["Wall Sits", "Straight Leg Raises", "Hamstring Curls", "Quad Stretches"],
        "shoulder": ["Pendulum Exercises", "Wall Slides", "External Rotation", "Scapular Squeezes"],
        "lower_back": ["Cat-Cow Stretches", "Bird Dogs", "Pelvic Tilts", "Knee-to-Chest Stretches"],
        "ankle": ["Ankle Circles", "Calf Raises", "Resistance Band Exercises", "Balance Training"],
        "wrist": ["Wrist Circles", "Wrist Flexor Stretches", "Grip Strengthening", "Prayer Stretches"],
        "elbow": ["Wrist Curls", "Reverse Wrist Curls", "Forearm Pronation/Supination"],
        "hip": ["Hip Circles", "Clamshells", "Hip Flexor Stretches", "Glute Bridges"],
        "neck": ["Neck Tilts", "Chin Tucks", "Neck Rotations", "Levator Scapulae Stretches"],
        "calf": ["Calf Stretches", "Heel Raises", "Eccentric Heel Drops", "Foam Rolling"],
    }

    body_part_lower = body_part.lower().replace(" ", "_")
    return recommendations.get(body_part_lower, ["Gentle Range of Motion", "Ice/Heat Therapy", "Light Stretching"])


# =============================================================================
# API Endpoints
# =============================================================================

@router.get("/{user_id}", response_model=InjuryListResponse)
async def get_user_injuries(
    user_id: str,
    status: Optional[InjuryStatus] = Query(default=None),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    """Get all injuries for a user."""
    logger.info(f"Getting injuries for user {user_id}")

    try:
        supabase = get_supabase()

        query = supabase.client.table("user_injuries").select("*").eq("user_id", user_id)

        if status:
            query = query.eq("status", status.value)

        query = query.order("reported_at", desc=True).range(offset, offset + limit - 1)

        result = query.execute()

        injuries = [_parse_injury_summary(i) for i in result.data or []]

        # Get active count
        active_result = supabase.client.table("user_injuries").select(
            "id", count="exact"
        ).eq("user_id", user_id).in_(
            "status", ["active", "recovering"]
        ).execute()

        active_count = active_result.count or 0

        return InjuryListResponse(
            injuries=injuries,
            count=len(injuries),
            active_count=active_count,
        )

    except Exception as e:
        logger.error(f"Failed to get user injuries: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/active", response_model=InjuryListResponse)
async def get_active_injuries(user_id: str):
    """Get only active injuries for a user."""
    logger.info(f"Getting active injuries for user {user_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("user_injuries").select("*").eq(
            "user_id", user_id
        ).in_(
            "status", ["active", "recovering"]
        ).order("reported_at", desc=True).execute()

        injuries = [_parse_injury_summary(i) for i in result.data or []]

        return InjuryListResponse(
            injuries=injuries,
            count=len(injuries),
            active_count=len(injuries),
        )

    except Exception as e:
        logger.error(f"Failed to get active injuries: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/report", response_model=InjuryReportResponse)
async def report_injury(user_id: str, request: InjuryReportRequest):
    """Report a new injury for a user."""
    logger.info(f"Reporting injury for user {user_id}: {request.body_part}")

    try:
        supabase = get_supabase()

        expected_recovery = request.expected_recovery_date
        if not expected_recovery:
            expected_recovery = _calculate_expected_recovery_date(request.severity)

        now = datetime.utcnow().isoformat()
        injury_data = {
            "user_id": user_id,
            "body_part": request.body_part,
            "injury_type": request.injury_type.value if request.injury_type else None,
            "severity": request.severity.value,
            "pain_level": request.pain_level,
            "occurred_at": request.occurred_at.isoformat() if request.occurred_at else None,
            "expected_recovery_date": expected_recovery.isoformat() if expected_recovery else None,
            "affects_exercises": request.affects_exercises or [],
            "affects_muscles": request.affects_muscles or [],
            "notes": request.notes,
            "activity_when_occurred": request.activity_when_occurred,
            "status": InjuryStatus.ACTIVE.value,
            "recovery_phase": RecoveryPhase.ACUTE.value,
            "reported_at": now,
            "created_at": now,
            "updated_at": now,
        }

        result = supabase.client.table("user_injuries").insert(injury_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create injury record")

        injury = _parse_injury(result.data[0])

        recommended_exercises = _get_recommended_rehab_exercises(request.body_part)

        # Invalidate upcoming workouts so they regenerate without the injured area
        from api.v1.workouts.utils import invalidate_upcoming_workouts
        invalidate_upcoming_workouts(user_id, reason=f"injury reported: {request.body_part}")

        logger.info(f"Injury reported: {result.data[0]['id']}")

        return InjuryReportResponse(
            success=True,
            message=f"Injury to {request.body_part} reported. Take care and follow recovery guidelines.",
            injury=injury,
            recommended_rehab_exercises=recommended_exercises,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to report injury: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/detail/{injury_id}", response_model=InjuryWithDetails)
async def get_injury(injury_id: str):
    """Get a specific injury with full details."""
    logger.info(f"Getting injury details: {injury_id}")

    try:
        supabase = get_supabase()

        injury_result = supabase.client.table("user_injuries").select("*").eq(
            "id", injury_id
        ).execute()

        if not injury_result.data:
            raise HTTPException(status_code=404, detail="Injury not found")

        injury_data = injury_result.data[0]
        injury = _parse_injury(injury_data)

        # Get check-ins
        check_ins_result = supabase.client.table("injury_updates").select("*").eq(
            "injury_id", injury_id
        ).order("checked_at", desc=True).execute()

        check_ins = []
        for c in check_ins_result.data or []:
            check_ins.append(InjuryCheckIn(
                id=str(c["id"]),
                injury_id=str(c["injury_id"]),
                user_id=c["user_id"],
                pain_level=c.get("pain_level"),
                mobility_rating=c.get("mobility_rating"),
                recovery_phase=RecoveryPhase(c["recovery_phase"]) if c.get("recovery_phase") else None,
                can_workout=c.get("can_workout", True),
                workout_modifications=c.get("workout_modifications"),
                notes=c.get("notes"),
                checked_at=c.get("checked_at") or datetime.utcnow(),
            ))

        # Get rehab exercises
        rehab_result = supabase.client.table("injury_rehab_exercises").select("*").eq(
            "injury_id", injury_id
        ).order("assigned_at").execute()

        rehab_exercises = []
        for r in rehab_result.data or []:
            rehab_exercises.append(RehabExercise(
                id=str(r["id"]),
                injury_id=str(r["injury_id"]),
                exercise_name=r["exercise_name"],
                exercise_type=r.get("exercise_type"),
                sets=r.get("sets"),
                reps=r.get("reps"),
                hold_seconds=r.get("hold_seconds"),
                frequency_per_day=r.get("frequency_per_day", 1),
                notes=r.get("notes"),
                assigned_at=r.get("assigned_at") or datetime.utcnow(),
                completed_count=r.get("completed_count", 0),
                last_completed_at=r.get("last_completed_at"),
            ))

        reported_at = injury.reported_at
        days_since = (datetime.utcnow() - reported_at.replace(tzinfo=None)).days

        progress = None
        if injury.expected_recovery_date:
            total_days = (injury.expected_recovery_date - reported_at.date()).days
            if total_days > 0:
                progress = min(100.0, (days_since / total_days) * 100)

        return InjuryWithDetails(
            **injury.model_dump(),
            check_ins=check_ins,
            rehab_exercises=rehab_exercises,
            days_since_reported=max(0, days_since),
            progress_percentage=progress,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get injury details: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{injury_id}")
async def update_injury(injury_id: str, request: InjuryUpdateRequest):
    """Update an existing injury."""
    logger.info(f"Updating injury: {injury_id}")

    try:
        supabase = get_supabase()

        injury_result = supabase.client.table("user_injuries").select("*").eq(
            "id", injury_id
        ).execute()

        if not injury_result.data:
            raise HTTPException(status_code=404, detail="Injury not found")

        update_data = {"updated_at": datetime.utcnow().isoformat()}

        if request.status is not None:
            update_data["status"] = request.status.value
            if request.status == InjuryStatus.HEALED:
                update_data["actual_recovery_date"] = datetime.utcnow().date().isoformat()
                update_data["recovery_phase"] = RecoveryPhase.HEALED.value

        if request.recovery_phase is not None:
            update_data["recovery_phase"] = request.recovery_phase.value

        if request.pain_level is not None:
            update_data["pain_level"] = request.pain_level

        if request.expected_recovery_date is not None:
            update_data["expected_recovery_date"] = request.expected_recovery_date.isoformat()

        if request.affects_exercises is not None:
            update_data["affects_exercises"] = request.affects_exercises

        if request.affects_muscles is not None:
            update_data["affects_muscles"] = request.affects_muscles

        if request.notes is not None:
            update_data["notes"] = request.notes

        result = supabase.client.table("user_injuries").update(update_data).eq(
            "id", injury_id
        ).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update injury")

        injury = _parse_injury(result.data[0])

        return {"success": True, "message": "Injury updated", "injury": injury}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update injury: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{injury_id}")
async def mark_injury_healed(injury_id: str):
    """Mark an injury as healed."""
    logger.info(f"Marking injury as healed: {injury_id}")

    try:
        supabase = get_supabase()

        injury_result = supabase.client.table("user_injuries").select("*").eq(
            "id", injury_id
        ).execute()

        if not injury_result.data:
            raise HTTPException(status_code=404, detail="Injury not found")

        current_injury = injury_result.data[0]

        if current_injury["status"] == "healed":
            raise HTTPException(status_code=400, detail="Injury is already marked as healed")

        healed_at = datetime.utcnow()

        update_data = {
            "status": InjuryStatus.HEALED.value,
            "recovery_phase": RecoveryPhase.HEALED.value,
            "actual_recovery_date": healed_at.date().isoformat(),
            "updated_at": healed_at.isoformat(),
        }

        supabase.client.table("user_injuries").update(update_data).eq("id", injury_id).execute()

        return {
            "success": True,
            "message": f"Great news! Your {current_injury['body_part']} injury has been marked as healed.",
            "injury_id": injury_id,
            "healed_at": healed_at.isoformat(),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to mark injury as healed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{injury_id}/check-in", response_model=InjuryCheckIn)
async def add_check_in(injury_id: str, request: InjuryCheckInRequest):
    """Add a recovery check-in for an injury."""
    logger.info(f"Adding check-in for injury: {injury_id}")

    try:
        supabase = get_supabase()

        injury_result = supabase.client.table("user_injuries").select("*").eq(
            "id", injury_id
        ).execute()

        if not injury_result.data:
            raise HTTPException(status_code=404, detail="Injury not found")

        injury_data = injury_result.data[0]
        user_id = injury_data["user_id"]

        now = datetime.utcnow().isoformat()
        check_in_data = {
            "injury_id": injury_id,
            "user_id": user_id,
            "pain_level": request.pain_level,
            "mobility_rating": request.mobility_rating,
            "recovery_phase": request.recovery_phase.value if request.recovery_phase else None,
            "can_workout": request.can_workout,
            "workout_modifications": request.workout_modifications,
            "notes": request.notes,
            "checked_at": now,
        }

        result = supabase.client.table("injury_updates").insert(check_in_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create check-in")

        # Update injury with latest pain level and recovery phase
        update_data = {"updated_at": now}
        if request.pain_level is not None:
            update_data["pain_level"] = request.pain_level
        if request.recovery_phase is not None:
            update_data["recovery_phase"] = request.recovery_phase.value
            if request.recovery_phase == RecoveryPhase.HEALED:
                update_data["status"] = InjuryStatus.HEALED.value
                update_data["actual_recovery_date"] = datetime.utcnow().date().isoformat()
            elif request.recovery_phase == RecoveryPhase.RECOVERY:
                update_data["status"] = InjuryStatus.RECOVERING.value

        supabase.client.table("user_injuries").update(update_data).eq("id", injury_id).execute()

        c = result.data[0]
        return InjuryCheckIn(
            id=str(c["id"]),
            injury_id=str(c["injury_id"]),
            user_id=c["user_id"],
            pain_level=c.get("pain_level"),
            mobility_rating=c.get("mobility_rating"),
            recovery_phase=RecoveryPhase(c["recovery_phase"]) if c.get("recovery_phase") else None,
            can_workout=c.get("can_workout", True),
            workout_modifications=c.get("workout_modifications"),
            notes=c.get("notes"),
            checked_at=c.get("checked_at") or datetime.utcnow(),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add check-in: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/workout-modifications", response_model=WorkoutModifications)
async def get_workout_modifications(user_id: str):
    """Get workout modifications based on active injuries."""
    logger.info(f"Getting workout modifications for user: {user_id}")

    try:
        supabase = get_supabase()

        result = supabase.client.table("user_injuries").select("*").eq(
            "user_id", user_id
        ).in_("status", ["active", "recovering"]).execute()

        injuries = result.data or []

        if not injuries:
            return WorkoutModifications(
                user_id=user_id,
                has_active_injuries=False,
                active_injury_count=0,
            )

        exercises_to_avoid = set()
        muscles_to_limit = set()
        exercise_modifications = []
        muscle_modifications = []
        general_recommendations = []

        upper_body_parts = ["shoulder", "arm", "wrist", "elbow", "chest", "upper_back", "neck"]
        lower_body_parts = ["knee", "ankle", "hip", "leg", "calf", "thigh", "foot"]
        core_parts = ["lower_back", "core", "abs", "spine"]

        upper_body_affected = False
        lower_body_affected = False
        core_affected = False

        for injury in injuries:
            body_part = injury["body_part"].lower().replace(" ", "_")
            severity = InjurySeverity(injury["severity"])

            if injury.get("affects_exercises"):
                for ex in injury["affects_exercises"]:
                    exercises_to_avoid.add(ex)
                    exercise_modifications.append(ExerciseModification(
                        exercise_name=ex,
                        modification_type="avoid",
                        reason=f"{injury['body_part']} injury ({severity.value})",
                    ))

            if injury.get("affects_muscles"):
                for muscle in injury["affects_muscles"]:
                    muscles_to_limit.add(muscle)
                    muscle_modifications.append(MuscleModification(
                        muscle_group=muscle,
                        modification_type="reduce" if severity == InjurySeverity.MILD else "avoid",
                        reason=f"{injury['body_part']} injury",
                        severity=severity,
                    ))

            if any(part in body_part for part in upper_body_parts):
                upper_body_affected = True
            if any(part in body_part for part in lower_body_parts):
                lower_body_affected = True
            if any(part in body_part for part in core_parts):
                core_affected = True

            recovery_phase = RecoveryPhase(injury.get("recovery_phase", "acute"))

            if recovery_phase == RecoveryPhase.ACUTE:
                general_recommendations.append(
                    f"Allow {injury['body_part']} to rest - avoid aggravating movements"
                )
            elif recovery_phase == RecoveryPhase.SUBACUTE:
                general_recommendations.append(
                    f"Light mobility work for {injury['body_part']} - avoid heavy resistance"
                )
            elif recovery_phase == RecoveryPhase.RECOVERY:
                general_recommendations.append(
                    f"Gradually increase {injury['body_part']} work - listen to your body"
                )

            if severity == InjurySeverity.SEVERE:
                general_recommendations.append(
                    f"Consider consulting a healthcare professional for your {injury['body_part']} injury"
                )

        can_do_upper = not (upper_body_affected and any(
            InjurySeverity(i["severity"]) == InjurySeverity.SEVERE
            for i in injuries
            if any(p in i["body_part"].lower() for p in upper_body_parts)
        ))

        can_do_lower = not (lower_body_affected and any(
            InjurySeverity(i["severity"]) == InjurySeverity.SEVERE
            for i in injuries
            if any(p in i["body_part"].lower() for p in lower_body_parts)
        ))

        can_do_core = not (core_affected and any(
            InjurySeverity(i["severity"]) == InjurySeverity.SEVERE
            for i in injuries
            if any(p in i["body_part"].lower() for p in core_parts)
        ))

        can_do_cardio = can_do_lower and not any(
            i["body_part"].lower() in ["ankle", "knee", "hip", "foot"] and
            InjurySeverity(i["severity"]) != InjurySeverity.MILD
            for i in injuries
        )

        return WorkoutModifications(
            user_id=user_id,
            has_active_injuries=True,
            active_injury_count=len(injuries),
            exercises_to_avoid=list(exercises_to_avoid),
            muscles_to_limit=list(muscles_to_limit),
            exercise_modifications=exercise_modifications,
            muscle_modifications=muscle_modifications,
            general_recommendations=list(set(general_recommendations)),
            can_do_upper_body=can_do_upper,
            can_do_lower_body=can_do_lower,
            can_do_core=can_do_core,
            can_do_cardio=can_do_cardio,
        )

    except Exception as e:
        logger.error(f"Failed to get workout modifications: {e}")
        raise HTTPException(status_code=500, detail=str(e))
