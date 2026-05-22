"""
Hormonal Health API Endpoints
API routes for hormonal health tracking, cycle management, and personalized recommendations.
"""

from fastapi import APIRouter, HTTPException, Query, Depends, Request
from typing import Optional, List
from datetime import date, datetime, timedelta
from uuid import UUID

from models.hormonal_health import (
    HormonalProfile, HormonalProfileCreate, HormonalProfileUpdate,
    HormoneLog, HormoneLogCreate,
    CyclePhaseInfo, CyclePhaseRecommendation, CyclePhase,
    HormonalRecommendation, HormonalInsights,
    HormoneSupportiveFood, HormonalFoodRecommendation,
    HormoneGoal,
    CyclePeriod, CyclePeriodCreate, CyclePeriodUpdate, CyclePrediction,
)
from core.supabase_client import get_supabase
from core.auth import get_current_user
from core.logger import get_logger
from core.timezone_utils import user_today_date
from services.cycle.cycle_predictor import predict_for_user

logger = get_logger(__name__)
from core.exceptions import safe_internal_error

router = APIRouter(prefix="/hormonal-health", tags=["Hormonal Health"])


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def calculate_cycle_phase(last_period_date: date, cycle_length: int = 28, today: date = None) -> tuple:
    """Calculate current cycle day and phase."""
    if not last_period_date:
        return None, None

    if today is None:
        today = date.today()  # fallback for non-endpoint callers; endpoints should always pass today
    days_since_period = (today - last_period_date).days
    current_cycle_day = (days_since_period % cycle_length) + 1

    if current_cycle_day <= 5:
        phase = CyclePhase.MENSTRUAL
    elif current_cycle_day <= 13:
        phase = CyclePhase.FOLLICULAR
    elif current_cycle_day <= 16:
        phase = CyclePhase.OVULATION
    else:
        phase = CyclePhase.LUTEAL

    return current_cycle_day, phase


def get_phase_recommendations(phase: CyclePhase) -> CyclePhaseRecommendation:
    """Get recommendations for a specific cycle phase."""
    recommendations = {
        CyclePhase.MENSTRUAL: CyclePhaseRecommendation(
            phase=CyclePhase.MENSTRUAL,
            phase_description="Days 1-5: Your body is shedding the uterine lining. Energy may be lower.",
            workout_intensity="light_to_moderate",
            recommended_exercise_types=["yoga", "walking", "light stretching", "swimming", "pilates"],
            exercises_to_avoid=["high intensity interval training", "heavy lifting", "inversions"],
            nutrition_tips=[
                "Focus on iron-rich foods (spinach, lentils, red meat)",
                "Stay hydrated",
                "Include anti-inflammatory foods (turmeric, ginger)",
                "Dark chocolate can help with cramps (magnesium)"
            ],
            self_care_tips=[
                "Rest when needed",
                "Use heat therapy for cramps",
                "Prioritize sleep",
                "Gentle movement helps with cramps"
            ],
            expected_energy_level="Lower than usual"
        ),
        CyclePhase.FOLLICULAR: CyclePhaseRecommendation(
            phase=CyclePhase.FOLLICULAR,
            phase_description="Days 6-13: Estrogen rises, energy increases. Great time for new challenges.",
            workout_intensity="moderate_to_high",
            recommended_exercise_types=["strength training", "HIIT", "new exercises", "skill work", "group classes"],
            exercises_to_avoid=[],
            nutrition_tips=[
                "Light, fresh foods work well",
                "Fermented foods support gut health",
                "Lean proteins for muscle building",
                "Complex carbs for sustained energy"
            ],
            self_care_tips=[
                "Try new activities",
                "Schedule challenging workouts",
                "Great time for social fitness",
                "Your body can handle more stress"
            ],
            expected_energy_level="Rising and high"
        ),
        CyclePhase.OVULATION: CyclePhaseRecommendation(
            phase=CyclePhase.OVULATION,
            phase_description="Days 14-16: Peak fertility and energy. Estrogen and testosterone peak.",
            workout_intensity="high",
            recommended_exercise_types=["PR attempts", "competitions", "high intensity", "group classes", "challenging workouts"],
            exercises_to_avoid=[],
            nutrition_tips=[
                "Fiber-rich foods support estrogen metabolism",
                "Antioxidant-rich fruits and vegetables",
                "Raw vegetables are easier to digest now",
                "Light, colorful meals"
            ],
            self_care_tips=[
                "Best time for challenging goals",
                "Schedule competitions or tests",
                "Social energy is high",
                "Great for communication and planning"
            ],
            expected_energy_level="Peak energy"
        ),
        CyclePhase.LUTEAL: CyclePhaseRecommendation(
            phase=CyclePhase.LUTEAL,
            phase_description="Days 17-28: Progesterone rises, then both hormones drop. PMS may occur.",
            workout_intensity="moderate",
            recommended_exercise_types=["moderate cardio", "pilates", "strength maintenance", "recovery work", "yoga"],
            exercises_to_avoid=["extreme endurance", "new max attempts"],
            nutrition_tips=[
                "Complex carbs help with serotonin",
                "Magnesium-rich foods (nuts, seeds, dark chocolate)",
                "B vitamins support mood",
                "Avoid excessive salt to reduce bloating"
            ],
            self_care_tips=[
                "Be patient with yourself",
                "Maintain regular routines",
                "Prioritize sleep",
                "Gentle self-care practices"
            ],
            expected_energy_level="Gradually decreasing"
        )
    }
    return recommendations.get(phase)


# ============================================================================
# HORMONAL PROFILE ENDPOINTS
# ============================================================================

@router.get("/profile/{user_id}", response_model=Optional[HormonalProfile])
async def get_hormonal_profile(
    user_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Get user's hormonal health profile."""
    logger.info(f"[Hormonal] Fetching profile for user {user_id}")

    try:
        supabase = get_supabase().client
        result = supabase.table("hormonal_profiles").select("*").eq("user_id", str(user_id)).execute()

        if not result.data:
            logger.info(f"[Hormonal] No profile found for user {user_id}")
            return None

        logger.info(f"[Hormonal] Profile retrieved for user {user_id}")
        return result.data[0]

    except Exception as e:
        logger.error(f"[Hormonal] Error fetching profile: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.put("/profile/{user_id}", response_model=HormonalProfile)
async def upsert_hormonal_profile(
    user_id: UUID, profile: HormonalProfileUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Create or update user's hormonal health profile."""
    logger.info(f"[Hormonal] Upserting profile for user {user_id}")

    try:
        supabase = get_supabase().client

        # Prepare data, excluding None values
        profile_data = {k: v for k, v in profile.dict().items() if v is not None}
        profile_data["user_id"] = str(user_id)
        profile_data["updated_at"] = datetime.utcnow().isoformat()

        # Convert enums to strings
        if "hormone_goals" in profile_data:
            profile_data["hormone_goals"] = [g.value if hasattr(g, 'value') else g for g in profile_data["hormone_goals"]]
        for field in ["gender", "birth_sex", "menopause_status", "andropause_status", "cycle_regularity", "thyroid_condition_type"]:
            if field in profile_data and profile_data[field] is not None:
                profile_data[field] = profile_data[field].value if hasattr(profile_data[field], 'value') else profile_data[field]

        # Convert date to string
        if "last_period_start_date" in profile_data and profile_data["last_period_start_date"]:
            profile_data["last_period_start_date"] = profile_data["last_period_start_date"].isoformat()

        # Check if profile exists
        existing = supabase.table("hormonal_profiles").select("id").eq("user_id", str(user_id)).execute()

        if existing.data:
            # Update existing
            result = supabase.table("hormonal_profiles").update(profile_data).eq("user_id", str(user_id)).execute()
        else:
            # Insert new
            profile_data["created_at"] = datetime.utcnow().isoformat()
            result = supabase.table("hormonal_profiles").insert(profile_data).execute()

        logger.info(f"[Hormonal] Profile upserted for user {user_id}")
        return result.data[0]

    except Exception as e:
        logger.error(f"[Hormonal] Error upserting profile: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.delete("/profile/{user_id}")
async def delete_hormonal_profile(
    user_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Delete user's hormonal health profile."""
    logger.info(f"[Hormonal] Deleting profile for user {user_id}")

    try:
        supabase = get_supabase().client
        supabase.table("hormonal_profiles").delete().eq("user_id", str(user_id)).execute()
        logger.info(f"[Hormonal] Profile deleted for user {user_id}")
        return {"message": "Profile deleted successfully"}

    except Exception as e:
        logger.error(f"[Hormonal] Error deleting profile: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# HORMONE LOG ENDPOINTS
# ============================================================================

@router.post("/logs/{user_id}", response_model=HormoneLog)
async def create_hormone_log(
    user_id: UUID, log: HormoneLogCreate,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Create a hormone log entry."""
    logger.info(f"[Hormonal] Creating log for user {user_id} on {log.log_date}")

    try:
        supabase = get_supabase().client

        log_data = log.dict()
        log_data["user_id"] = str(user_id)
        log_data["created_at"] = datetime.utcnow().isoformat()

        # Convert enums and date
        log_data["log_date"] = log_data["log_date"].isoformat()
        for field in ["cycle_phase", "period_flow", "mood", "exercise_intensity", "cervical_mucus"]:
            if log_data.get(field):
                log_data[field] = log_data[field].value if hasattr(log_data[field], 'value') else log_data[field]
        if log_data.get("symptoms"):
            log_data["symptoms"] = [s.value if hasattr(s, 'value') else s for s in log_data["symptoms"]]

        # Auto-calculate cycle day and phase if not provided
        if not log_data.get("cycle_day") or not log_data.get("cycle_phase"):
            profile = supabase.table("hormonal_profiles").select("*").eq("user_id", str(user_id)).execute()
            if profile.data and profile.data[0].get("menstrual_tracking_enabled"):
                p = profile.data[0]
                if p.get("last_period_start_date"):
                    cycle_day, phase = calculate_cycle_phase(
                        date.fromisoformat(p["last_period_start_date"]),
                        p.get("cycle_length_days", 28),
                        today=user_today_date(request, None, str(user_id)),
                    )
                    if not log_data.get("cycle_day"):
                        log_data["cycle_day"] = cycle_day
                    if not log_data.get("cycle_phase"):
                        log_data["cycle_phase"] = phase.value if phase else None

        # Upsert (one log per day)
        result = supabase.table("hormone_logs").upsert(
            log_data,
            on_conflict="user_id,log_date"
        ).execute()

        logger.info(f"[Hormonal] Log created for user {user_id}")
        return result.data[0]

    except Exception as e:
        logger.error(f"[Hormonal] Error creating log: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.get("/logs/{user_id}", response_model=List[HormoneLog])
async def get_hormone_logs(
    user_id: UUID,
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    limit: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(get_current_user),
):
    """Get hormone logs for a user with optional date range."""
    logger.info(f"[Hormonal] Fetching logs for user {user_id}")

    try:
        supabase = get_supabase().client

        query = supabase.table("hormone_logs").select("*").eq("user_id", str(user_id))

        if start_date:
            query = query.gte("log_date", start_date.isoformat())
        if end_date:
            query = query.lte("log_date", end_date.isoformat())

        result = query.order("log_date", desc=True).limit(limit).execute()

        logger.info(f"[Hormonal] Retrieved {len(result.data)} logs for user {user_id}")
        return result.data

    except Exception as e:
        logger.error(f"[Hormonal] Error fetching logs: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.get("/logs/{user_id}/today", response_model=Optional[HormoneLog])
async def get_today_hormone_log(
    user_id: UUID,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get today's hormone log if it exists."""
    logger.info(f"[Hormonal] Fetching today's log for user {user_id}")

    try:
        today = user_today_date(request, None, str(user_id))
        supabase = get_supabase().client
        result = supabase.table("hormone_logs").select("*").eq(
            "user_id", str(user_id)
        ).eq("log_date", today.isoformat()).execute()

        if result.data:
            return result.data[0]
        return None

    except Exception as e:
        logger.error(f"[Hormonal] Error fetching today's log: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# CYCLE PHASE ENDPOINTS
# ============================================================================

@router.get("/cycle-phase/{user_id}", response_model=CyclePhaseInfo)
async def get_cycle_phase(
    user_id: UUID,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get current cycle phase information for a user.

    Backed by the deterministic prediction engine (services.cycle.cycle_predictor),
    so the phase reflects the user's actual period history and any logged
    BBT / cervical-mucus / LH signals — not a hardcoded day-number boundary.
    The CyclePhaseInfo response shape is unchanged for backward compatibility.
    """
    logger.info(f"[Hormonal] Getting cycle phase for user {user_id}")

    try:
        supabase = get_supabase().client
        profile_result = supabase.table("hormonal_profiles").select("*").eq("user_id", str(user_id)).execute()
        profile = profile_result.data[0] if profile_result.data else None
        tracking_enabled = bool(profile.get("menstrual_tracking_enabled")) if profile else False

        today = user_today_date(request, None, str(user_id))
        prediction = predict_for_user(supabase, str(user_id), today)

        if not prediction.get("predictions_available"):
            return CyclePhaseInfo(
                user_id=str(user_id),
                menstrual_tracking_enabled=tracking_enabled,
            )

        phase_value = prediction.get("current_phase")
        phase_enum = CyclePhase(phase_value) if phase_value else None
        next_phase_value = prediction.get("next_phase")
        recommendations = get_phase_recommendations(phase_enum) if phase_enum else None

        stats = prediction.get("stats") or {}
        avg_cycle = stats.get("avg_cycle_length")
        cycle_length = (
            int(round(avg_cycle)) if avg_cycle
            else (profile.get("cycle_length_days") if profile else None)
        )

        return CyclePhaseInfo(
            user_id=str(user_id),
            menstrual_tracking_enabled=tracking_enabled,
            current_cycle_day=prediction.get("current_cycle_day"),
            current_phase=phase_enum,
            days_until_next_phase=prediction.get("days_until_next_phase"),
            next_phase=CyclePhase(next_phase_value) if next_phase_value else None,
            cycle_length_days=cycle_length,
            last_period_start_date=prediction.get("last_period_start"),
            recommended_intensity=recommendations.workout_intensity if recommendations else None,
            avoid_exercises=recommendations.exercises_to_avoid if recommendations else [],
            recommended_exercises=recommendations.recommended_exercise_types if recommendations else [],
            nutrition_focus=recommendations.nutrition_tips if recommendations else [],
        )

    except Exception as e:
        logger.error(f"[Hormonal] Error getting cycle phase: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.get("/cycle-phase/recommendations/{phase}", response_model=CyclePhaseRecommendation)
async def get_phase_recommendation(
    phase: CyclePhase,
    current_user: dict = Depends(get_current_user),
):
    """Get recommendations for a specific cycle phase."""
    recommendations = get_phase_recommendations(phase)
    if not recommendations:
        raise HTTPException(status_code=404, detail="Phase not found")
    return recommendations


@router.post("/cycle-phase/{user_id}/log-period")
async def log_period_start(
    user_id: UUID, request: Request, period_date: date = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    """Log the start of a new menstrual period."""
    logger.info(f"[Hormonal] Logging period start for user {user_id}")

    try:
        supabase = get_supabase().client

        period_start = period_date or user_today_date(request, None, str(user_id))

        # Record the period in the canonical cycle_periods history table.
        supabase.table("cycle_periods").upsert({
            "user_id": str(user_id),
            "start_date": period_start.isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }, on_conflict="user_id,start_date").execute()

        # Update profile with new period start date
        result = supabase.table("hormonal_profiles").update({
            "last_period_start_date": period_start.isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        }).eq("user_id", str(user_id)).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Hormonal profile not found")

        # Also create/update a hormone log for this day
        supabase.table("hormone_logs").upsert({
            "user_id": str(user_id),
            "log_date": period_start.isoformat(),
            "cycle_day": 1,
            "cycle_phase": CyclePhase.MENSTRUAL.value,
            "period_flow": "medium",
            "created_at": datetime.utcnow().isoformat()
        }, on_conflict="user_id,log_date").execute()

        logger.info(f"[Hormonal] Period logged for user {user_id} on {period_start}")
        return {"message": "Period start logged", "date": period_start.isoformat()}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Hormonal] Error logging period: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# CYCLE PERIODS (canonical history) + PREDICTION ENDPOINTS
# ============================================================================

def _sync_last_period(supabase, user_id: str) -> None:
    """Keep hormonal_profiles.last_period_start_date pointed at the most recent
    cycle_periods row. Predictions read cycle_periods directly now; this only
    keeps legacy consumers (the photo-reminder filter, older clients) coherent.
    """
    try:
        latest = supabase.table("cycle_periods").select("start_date").eq(
            "user_id", user_id
        ).order("start_date", desc=True).limit(1).execute()
        if latest.data:
            supabase.table("hormonal_profiles").update({
                "last_period_start_date": latest.data[0]["start_date"],
                "updated_at": datetime.utcnow().isoformat(),
            }).eq("user_id", user_id).execute()
    except Exception as e:  # non-fatal — the canonical data is in cycle_periods
        logger.warning(f"[Hormonal] _sync_last_period failed for {user_id}: {e}")


@router.get("/prediction/{user_id}", response_model=CyclePrediction)
async def get_cycle_prediction(
    user_id: UUID,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Full cycle prediction: current phase, next-period forecast with a
    confidence window, ovulation (estimated or BBT-confirmed), fertile window,
    and cycle statistics. All dates are estimates — never a contraceptive method.
    """
    logger.info(f"[Hormonal] Computing cycle prediction for user {user_id}")

    try:
        supabase = get_supabase().client
        today = user_today_date(request, None, str(user_id))
        prediction = predict_for_user(supabase, str(user_id), today)
        prediction["user_id"] = str(user_id)
        return prediction

    except Exception as e:
        logger.error(f"[Hormonal] Error computing prediction: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.get("/periods/{user_id}", response_model=List[CyclePeriod])
async def list_cycle_periods(
    user_id: UUID,
    limit: int = Query(24, ge=1, le=120),
    current_user: dict = Depends(get_current_user),
):
    """List a user's logged periods, newest first."""
    try:
        supabase = get_supabase().client
        result = supabase.table("cycle_periods").select("*").eq(
            "user_id", str(user_id)
        ).order("start_date", desc=True).limit(limit).execute()
        return result.data or []

    except Exception as e:
        logger.error(f"[Hormonal] Error listing periods: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.post("/periods/{user_id}", response_model=CyclePeriod)
async def create_cycle_period(
    user_id: UUID, period: CyclePeriodCreate,
    current_user: dict = Depends(get_current_user),
):
    """Log a period (start date, optional end date). Upserts on start date so
    re-logging the same day edits rather than duplicates."""
    logger.info(f"[Hormonal] Logging period for user {user_id} starting {period.start_date}")

    try:
        if period.end_date and period.end_date < period.start_date:
            raise HTTPException(status_code=400, detail="end_date cannot precede start_date")

        supabase = get_supabase().client
        period_data = {
            "user_id": str(user_id),
            "start_date": period.start_date.isoformat(),
            "end_date": period.end_date.isoformat() if period.end_date else None,
            "updated_at": datetime.utcnow().isoformat(),
        }
        result = supabase.table("cycle_periods").upsert(
            period_data, on_conflict="user_id,start_date"
        ).execute()
        _sync_last_period(supabase, str(user_id))

        logger.info(f"[Hormonal] Period logged for user {user_id}")
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Hormonal] Error logging period: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.patch("/periods/{user_id}/{period_id}", response_model=CyclePeriod)
async def update_cycle_period(
    user_id: UUID, period_id: UUID, patch: CyclePeriodUpdate,
    current_user: dict = Depends(get_current_user),
):
    """Edit a logged period (e.g. set its end date)."""
    try:
        update_data = {}
        if patch.start_date is not None:
            update_data["start_date"] = patch.start_date.isoformat()
        if patch.end_date is not None:
            update_data["end_date"] = patch.end_date.isoformat()
        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        supabase = get_supabase().client
        result = supabase.table("cycle_periods").update(update_data).eq(
            "id", str(period_id)
        ).eq("user_id", str(user_id)).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Period not found")
        _sync_last_period(supabase, str(user_id))
        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Hormonal] Error updating period: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.delete("/periods/{user_id}/{period_id}")
async def delete_cycle_period(
    user_id: UUID, period_id: UUID,
    current_user: dict = Depends(get_current_user),
):
    """Delete a logged period; predictions recompute from what remains."""
    try:
        supabase = get_supabase().client
        supabase.table("cycle_periods").delete().eq(
            "id", str(period_id)
        ).eq("user_id", str(user_id)).execute()
        _sync_last_period(supabase, str(user_id))
        return {"message": "Period deleted"}

    except Exception as e:
        logger.error(f"[Hormonal] Error deleting period: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# HORMONE-SUPPORTIVE FOODS ENDPOINTS
# ============================================================================

@router.get("/foods", response_model=List[HormoneSupportiveFood])
async def get_hormone_supportive_foods(
    goal: Optional[HormoneGoal] = Query(None),
    cycle_phase: Optional[CyclePhase] = Query(None),
    current_user: dict = Depends(get_current_user),
):
    """Get hormone-supportive foods, optionally filtered by goal or cycle phase."""
    logger.info(f"[Hormonal] Fetching hormone-supportive foods")

    try:
        supabase = get_supabase().client
        query = supabase.table("hormone_supportive_foods").select("*").eq("is_active", True)

        # Filter by goal
        if goal:
            goal_column_map = {
                HormoneGoal.OPTIMIZE_TESTOSTERONE: "supports_testosterone",
                HormoneGoal.BALANCE_ESTROGEN: "supports_estrogen_balance",
                HormoneGoal.PCOS_MANAGEMENT: "supports_pcos",
                HormoneGoal.MENOPAUSE_SUPPORT: "supports_menopause",
                HormoneGoal.IMPROVE_FERTILITY: "supports_fertility",
            }
            if goal in goal_column_map:
                query = query.eq(goal_column_map[goal], True)

        # Filter by cycle phase
        if cycle_phase:
            phase_column_map = {
                CyclePhase.MENSTRUAL: "good_for_menstrual",
                CyclePhase.FOLLICULAR: "good_for_follicular",
                CyclePhase.OVULATION: "good_for_ovulation",
                CyclePhase.LUTEAL: "good_for_luteal",
            }
            query = query.eq(phase_column_map[cycle_phase], True)

        result = query.execute()
        logger.info(f"[Hormonal] Retrieved {len(result.data)} foods")
        return result.data

    except Exception as e:
        logger.error(f"[Hormonal] Error fetching foods: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


@router.get("/foods/recommendations/{user_id}", response_model=HormonalFoodRecommendation)
async def get_food_recommendations(
    user_id: UUID,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get personalized hormone-supportive food recommendations."""
    logger.info(f"[Hormonal] Getting food recommendations for user {user_id}")

    try:
        supabase = get_supabase().client

        # Get user's hormonal profile
        profile_result = supabase.table("hormonal_profiles").select("*").eq("user_id", str(user_id)).execute()

        hormone_goals = []
        current_phase = None

        if profile_result.data:
            profile = profile_result.data[0]
            hormone_goals = [HormoneGoal(g) for g in profile.get("hormone_goals", [])]

            if profile.get("menstrual_tracking_enabled") and profile.get("last_period_start_date"):
                _, current_phase = calculate_cycle_phase(
                    date.fromisoformat(profile["last_period_start_date"]),
                    profile.get("cycle_length_days", 28),
                    today=user_today_date(request, None, str(user_id)),
                )

        # Get recommended foods
        foods_query = supabase.table("hormone_supportive_foods").select("*").eq("is_active", True)
        foods_result = foods_query.execute()
        all_foods = foods_result.data

        # Filter and score foods
        recommended_foods = []
        for food in all_foods:
            score = 0
            # Score by goals
            for goal in hormone_goals:
                if goal == HormoneGoal.OPTIMIZE_TESTOSTERONE and food.get("supports_testosterone"):
                    score += 2
                elif goal == HormoneGoal.BALANCE_ESTROGEN and food.get("supports_estrogen_balance"):
                    score += 2
                elif goal == HormoneGoal.PCOS_MANAGEMENT and food.get("supports_pcos"):
                    score += 2
                elif goal == HormoneGoal.MENOPAUSE_SUPPORT and food.get("supports_menopause"):
                    score += 2
                elif goal == HormoneGoal.IMPROVE_FERTILITY and food.get("supports_fertility"):
                    score += 2

            # Score by cycle phase
            if current_phase:
                phase_col = f"good_for_{current_phase.value}"
                if food.get(phase_col):
                    score += 1

            if score > 0:
                food["_score"] = score
                recommended_foods.append(food)

        # Sort by score
        recommended_foods.sort(key=lambda x: x.get("_score", 0), reverse=True)

        # Build key nutrients to focus on
        key_nutrients = set()
        for food in recommended_foods[:10]:
            key_nutrients.update(food.get("key_nutrients", []))

        # Foods to limit based on goals
        foods_to_limit = []
        if HormoneGoal.OPTIMIZE_TESTOSTERONE in hormone_goals:
            foods_to_limit.extend(["Excessive alcohol", "Processed soy", "Refined sugar", "Trans fats"])
        if HormoneGoal.BALANCE_ESTROGEN in hormone_goals:
            foods_to_limit.extend(["Non-organic dairy", "Conventionally raised meat", "Excessive caffeine"])
        if HormoneGoal.PCOS_MANAGEMENT in hormone_goals:
            foods_to_limit.extend(["High glycemic foods", "Refined carbs", "Sugary drinks", "Processed foods"])

        # Meal timing tips
        meal_timing_tips = [
            "Eat protein with every meal to stabilize blood sugar",
            "Include healthy fats for hormone production",
            "Don't skip breakfast - it affects cortisol levels"
        ]
        if current_phase == CyclePhase.LUTEAL:
            meal_timing_tips.append("Eat smaller, more frequent meals to manage blood sugar")
        if HormoneGoal.OPTIMIZE_TESTOSTERONE in hormone_goals:
            meal_timing_tips.append("Consider eating your largest meal post-workout")

        return HormonalFoodRecommendation(
            user_id=str(user_id),
            hormone_goals=hormone_goals,
            current_cycle_phase=current_phase,
            recommended_foods=recommended_foods[:15],
            foods_to_limit=list(set(foods_to_limit)),
            key_nutrients_to_focus=list(key_nutrients)[:10],
            meal_timing_tips=meal_timing_tips
        )

    except Exception as e:
        logger.error(f"[Hormonal] Error getting food recommendations: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# COMPREHENSIVE INSIGHTS ENDPOINT
# ============================================================================

@router.get("/insights/{user_id}", response_model=HormonalInsights)
async def get_hormonal_insights(
    user_id: UUID,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Get comprehensive hormonal health insights for a user."""
    logger.info(f"[Hormonal] Getting comprehensive insights for user {user_id}")

    try:
        supabase = get_supabase().client

        # Get profile
        profile_result = supabase.table("hormonal_profiles").select("*").eq("user_id", str(user_id)).execute()
        profile = profile_result.data[0] if profile_result.data else None

        # Get cycle phase info
        cycle_info = await get_cycle_phase(user_id, request)

        # Get recent logs (last 7 days)
        logs_result = supabase.table("hormone_logs").select("*").eq(
            "user_id", str(user_id)
        ).gte(
            "log_date", (user_today_date(request, None, str(user_id)) - timedelta(days=7)).isoformat()
        ).order("log_date", desc=True).execute()

        # Summarize recent logs
        logs_summary = None
        if logs_result.data:
            logs = logs_result.data
            logs_summary = {
                "days_logged": len(logs),
                "avg_energy": sum(l.get("energy_level", 0) for l in logs if l.get("energy_level")) / max(1, len([l for l in logs if l.get("energy_level")])),
                "avg_sleep": sum(l.get("sleep_quality", 0) for l in logs if l.get("sleep_quality")) / max(1, len([l for l in logs if l.get("sleep_quality")])),
                "avg_stress": sum(l.get("stress_level", 0) for l in logs if l.get("stress_level")) / max(1, len([l for l in logs if l.get("stress_level")])),
                "common_symptoms": [],
                "mood_trend": []
            }
            # Find common symptoms
            all_symptoms = []
            for log in logs:
                all_symptoms.extend(log.get("symptoms", []))
            from collections import Counter
            logs_summary["common_symptoms"] = [s for s, _ in Counter(all_symptoms).most_common(3)]
            logs_summary["mood_trend"] = [l.get("mood") for l in logs if l.get("mood")]

        # Get food recommendations
        food_recommendations = await get_food_recommendations(user_id, request)

        # Build recommendations
        recommendations = []
        if profile:
            goals = profile.get("hormone_goals", [])

            if "optimize_testosterone" in goals:
                recommendations.append(HormonalRecommendation(
                    user_id=str(user_id),
                    recommendation_type="lifestyle",
                    title="Testosterone Optimization Tips",
                    description="Based on your goal to optimize testosterone levels",
                    action_items=[
                        "Get 7-9 hours of quality sleep",
                        "Include compound exercises (squats, deadlifts)",
                        "Manage stress through relaxation techniques",
                        "Ensure adequate zinc and vitamin D intake"
                    ],
                    based_on=["optimize_testosterone goal"],
                    priority="high",
                    created_at=datetime.utcnow()
                ))

            if cycle_info.current_phase:
                phase_rec = get_phase_recommendations(cycle_info.current_phase)
                if phase_rec:
                    recommendations.append(HormonalRecommendation(
                        user_id=str(user_id),
                        recommendation_type="workout",
                        title=f"{cycle_info.current_phase.value.title()} Phase Workout Tips",
                        description=phase_rec.phase_description,
                        action_items=phase_rec.self_care_tips,
                        based_on=[f"Current cycle phase: {cycle_info.current_phase.value}"],
                        priority="medium",
                        created_at=datetime.utcnow()
                    ))

        return HormonalInsights(
            user_id=str(user_id),
            profile=profile,
            current_cycle_phase=cycle_info,
            recent_logs_summary=logs_summary,
            recommendations=recommendations,
            food_recommendations=food_recommendations
        )

    except Exception as e:
        logger.error(f"[Hormonal] Error getting insights: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# ── Custom Trends: per-day hormone/cycle time series ────────────────────────

@router.get("/trends/{user_id}")
async def get_hormone_trends(
    user_id: UUID,
    request: Request,
    days: int = Query(
        default=90, ge=0, le=1825,
        description="Rolling-window size in days ending today. 0 = all history.",
    ),
    current_user: dict = Depends(get_current_user),
):
    """Per-day hormone/cycle time series for the Custom Trends chart.

    `hormone_logs` rows are already one-per-user-per-day (keyed on `log_date`,
    which is the user's local calendar date), so no UTC bucketing is needed.
    Days with no log are absent from `daily_series` — no fabricated data.

    Numeric fields plotted: energy_level, sleep_quality, libido_level,
    stress_level, motivation_level, recovery_feeling, basal_body_temperature
    (1-10 scales; BBT in Celsius). `cycle_day`, `cycle_phase` and `period_flow`
    are included so the chart can render a future-period / cycle-phase overlay.
    """
    if str(current_user.get("id") or current_user.get("sub")) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")

    try:
        today = user_today_date(request, None, str(user_id))
        # 0 ⇒ all history (cap ~5y so the query stays bounded).
        span = days if days > 0 else 1825
        start_date = (today - timedelta(days=span - 1)).isoformat()

        supabase = get_supabase().client
        result = (
            supabase.table("hormone_logs")
            .select(
                "log_date,cycle_day,cycle_phase,period_flow,"
                "energy_level,sleep_quality,libido_level,stress_level,"
                "motivation_level,recovery_feeling,basal_body_temperature"
            )
            .eq("user_id", str(user_id))
            .gte("log_date", start_date)
            .lte("log_date", today.isoformat())
            .order("log_date")
            .execute()
        )
        rows = result.data or []

        daily_series = []
        for row in rows:
            bbt = row.get("basal_body_temperature")
            daily_series.append({
                "date": row.get("log_date"),
                "cycle_day": row.get("cycle_day"),
                "cycle_phase": row.get("cycle_phase"),
                "period_flow": row.get("period_flow"),
                "energy_level": row.get("energy_level"),
                "sleep_quality": row.get("sleep_quality"),
                "libido_level": row.get("libido_level"),
                "stress_level": row.get("stress_level"),
                "motivation_level": row.get("motivation_level"),
                "recovery_feeling": row.get("recovery_feeling"),
                "basal_body_temperature": float(bbt) if bbt is not None else None,
            })

        return {"daily_series": daily_series}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Hormonal] Error getting trends: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


# ============================================================================
# AI PROACTIVE INSIGHT (Phase F)
# ============================================================================
#
# A server-generated, proactive insight for the user's current cycle phase and
# recent data. Deterministic + template-based (NO LLM) so it is cheap and fast;
# cached per-user-per-day in memory. The cycle agent (the chat surface) handles
# anything conversational — this endpoint just powers the inline insight card /
# app-bar badge so the coach feels present without a chat round-trip.
#
# Safety: copy is general wellness only — never contraceptive advice, never a
# diagnosis. Red-flag patterns surface a gentle "see a clinician" nudge.

import random as _random
from hashlib import md5 as _md5

# In-memory per-day cache: {(user_id, iso_date): insight_dict}. Bounded by the
# tiny key space (one entry per active user per day); cleared on process
# restart, which is acceptable for a non-critical advisory surface.
_AI_INSIGHT_CACHE: dict = {}

# Variant pools — phrasing is rotated (seeded by user+date so it is stable
# across a day's repeated fetches) so the copy reads human-written, per
# feedback_dynamic_copy_not_robotic.md. >=4 variants per pattern.
_PHASE_INSIGHT_POOL = {
    "menstrual": [
        "You're in your menstrual phase. Energy often dips here — gentle "
        "movement and iron-rich meals tend to help.",
        "Menstrual phase right now. Be kind to yourself: rest is productive, "
        "and warm, comforting food can ease cramps.",
        "It's your period week. Light walks, stretching and staying hydrated "
        "usually take the edge off.",
        "Menstrual phase. If you're tired, that's expected — lean into "
        "lighter sessions and magnesium-rich foods.",
    ],
    "follicular": [
        "You're in your follicular phase — energy is climbing. A great "
        "stretch for progressive strength work.",
        "Follicular phase: rising energy and quicker recovery. A good window "
        "to push training intensity a little.",
        "Your follicular phase is here. Fresh, lighter meals and harder "
        "workouts both tend to feel good now.",
        "Follicular phase. Motivation usually trends up — ride it with some "
        "skill or strength progression.",
    ],
    "ovulation": [
        "You're around ovulation — often a peak-energy window. A strong day "
        "for heavier lifts or intervals.",
        "Ovulation phase: many people feel their strongest here. Good timing "
        "for a PR attempt if you're up for it.",
        "Ovulation window. Energy and mood often peak — make the most of it "
        "with a session you enjoy.",
        "You're near ovulation. Antioxidant-rich foods and a high-intensity "
        "session both pair well with this phase.",
    ],
    "luteal": [
        "You're in your luteal phase. Cravings and a small energy taper are "
        "normal — complex carbs help steady things.",
        "Luteal phase right now. Moderate, steady workouts and magnesium-rich "
        "foods tend to feel best as the period nears.",
        "Your luteal phase is here. A slight calorie increase late in this "
        "phase is normal, not a setback.",
        "Luteal phase. If mood or energy dips, that's hormonal — gentler "
        "training and good sleep go a long way.",
    ],
}

_NO_DATA_INSIGHT = [
    "Log your first period to unlock cycle predictions and phase-based tips.",
    "Once you log a period, you'll get personalized phase insights here.",
    "Start by logging a period — your cycle phase and tips will appear after.",
    "Add a period log to see where you are in your cycle and what tends to help.",
]


def _seeded_choice(pool: list, seed_key: str):
    """Pick a stable variant for a given seed (user_id + date) so the insight
    text doesn't flicker across repeated fetches in the same day."""
    if not pool:
        return ""
    idx = int(_md5(seed_key.encode()).hexdigest(), 16) % len(pool)
    return pool[idx]


@router.get("/ai-insight/{user_id}")
async def get_cycle_ai_insight(
    user_id: UUID,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """Server-generated proactive cycle insight for the current phase/data.

    Deterministic + template-based (no LLM), cached per user per day. Powers
    the inline AI insight card and the app-bar "fresh insight" badge on the
    Cycle screen. Always frames predictions as estimates; surfaces a gentle
    clinician nudge when a red-flag pattern is present.
    """
    logger.info(f"[Hormonal] AI insight for user {user_id}")
    try:
        today = user_today_date(request, None, str(user_id))
        cache_key = (str(user_id), today.isoformat())
        cached = _AI_INSIGHT_CACHE.get(cache_key)
        if cached is not None:
            return cached

        from services.cycle.cycle_context import build_cycle_context

        supabase = get_supabase().client
        ctx = build_cycle_context(supabase, str(user_id), today)

        seed = f"{user_id}:{today.isoformat()}"
        red_flags = ctx.get("red_flags") or []
        phase = ctx.get("phase")
        pred = ctx.get("prediction") or {}

        # --- Headline insight text -----------------------------------------
        if not ctx.get("available") or not pred.get("predictions_available"):
            headline = _seeded_choice(_NO_DATA_INSIGHT, seed)
        elif phase in _PHASE_INSIGHT_POOL:
            headline = _seeded_choice(_PHASE_INSIGHT_POOL[phase], seed)
        else:
            headline = (
                "Here's your cycle snapshot for today — log symptoms to make "
                "it more personal."
            )

        # --- Data-grounded detail line -------------------------------------
        detail_bits = []
        if pred.get("predictions_available"):
            day = pred.get("current_cycle_day")
            conf = pred.get("confidence") or "low"
            if day:
                detail_bits.append(f"Cycle day {day}")
            late_by = pred.get("period_late_by")
            days_until = pred.get("days_until_next_period")
            if late_by is not None:
                detail_bits.append(
                    f"period an estimated {late_by} days late"
                )
            elif days_until is not None:
                detail_bits.append(
                    f"next period estimated in ~{days_until} days"
                )
            detail_bits.append(f"{conf}-confidence estimate")

        recent = ctx.get("recent_logs") or {}
        if recent.get("avg_energy") is not None:
            detail_bits.append(
                f"avg logged energy {recent['avg_energy']}/10"
            )

        detail = ". ".join(detail_bits) + "." if detail_bits else ""

        # --- Clinician nudge (gentle, never a diagnosis) -------------------
        clinician_nudge = None
        if red_flags:
            clinician_nudge = (
                "A pattern in your recent data ("
                + "; ".join(red_flags)
                + ") is worth mentioning to a doctor or gynecologist. This "
                "is not a diagnosis — just a heads-up."
            )

        insight = {
            "user_id": str(user_id),
            "date": today.isoformat(),
            "phase": phase,
            "cycle_day": ctx.get("cycle_day"),
            "headline": headline,
            "detail": detail,
            "clinician_nudge": clinician_nudge,
            "has_red_flag": bool(red_flags),
            "tracking_mode": ctx.get("tracking_mode"),
            # Suggested-question chips for the chat surface, phase-aware.
            "suggested_questions": _suggested_questions_for(phase, ctx.get("tracking_mode")),
            "disclaimer": (
                "Cycle predictions are estimates for general wellness — not a "
                "contraceptive method and not medical advice."
            ),
            "generated_at": datetime.utcnow().isoformat(),
        }

        _AI_INSIGHT_CACHE[cache_key] = insight
        return insight

    except Exception as e:
        logger.error(f"[Hormonal] Error generating AI insight: {e}", exc_info=True)
        raise safe_internal_error(e, "endpoint")


def _suggested_questions_for(phase: Optional[str], tracking_mode: Optional[str]) -> List[str]:
    """Phase- and mode-aware suggested-question chips for the chat surface."""
    base = {
        "menstrual": [
            "Why am I so tired this week?",
            "What should I eat during my period?",
            "Is it okay to work out on my period?",
        ],
        "follicular": [
            "What workout should I do today?",
            "Why do I feel more energetic?",
            "Is my cycle normal?",
        ],
        "ovulation": [
            "Am I in my fertile window?",
            "What should I eat today?",
            "Is this a good time to train hard?",
        ],
        "luteal": [
            "Why am I craving carbs?",
            "How do I handle PMS symptoms?",
            "What should I eat this week?",
        ],
    }
    questions = list(base.get(phase or "", [
        "Where am I in my cycle?",
        "Is my cycle normal?",
        "What should I eat today?",
    ]))
    if tracking_mode == "ttc":
        questions.insert(0, "When is my fertile window?")
    return questions[:4]
