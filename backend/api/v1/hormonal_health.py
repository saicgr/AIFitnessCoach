"""
Hormonal Health API Endpoints
API routes for hormonal health tracking, cycle management, and personalized recommendations.
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from datetime import date, datetime, timedelta
from uuid import UUID

from models.hormonal_health import (
    HormonalProfile, HormonalProfileCreate, HormonalProfileUpdate,
    HormoneLog, HormoneLogCreate,
    CyclePhaseInfo, CyclePhaseRecommendation, CyclePhase,
    HormonalRecommendation, HormonalInsights,
    HormoneSupportiveFood, HormonalFoodRecommendation,
    HormoneGoal
)
from core.supabase_client import get_supabase

router = APIRouter(prefix="/hormonal-health", tags=["Hormonal Health"])


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def calculate_cycle_phase(last_period_date: date, cycle_length: int = 28) -> tuple:
    """Calculate current cycle day and phase."""
    if not last_period_date:
        return None, None

    days_since_period = (date.today() - last_period_date).days
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
async def get_hormonal_profile(user_id: UUID):
    """Get user's hormonal health profile."""
    print(f"🔍 [Hormonal] Fetching profile for user {user_id}")

    try:
        supabase = get_supabase().client
        result = supabase.table("hormonal_profiles").select("*").eq("user_id", str(user_id)).execute()

        if not result.data:
            print(f"ℹ️ [Hormonal] No profile found for user {user_id}")
            return None

        print(f"✅ [Hormonal] Profile retrieved for user {user_id}")
        return result.data[0]

    except Exception as e:
        print(f"❌ [Hormonal] Error fetching profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/profile/{user_id}", response_model=HormonalProfile)
async def upsert_hormonal_profile(user_id: UUID, profile: HormonalProfileUpdate):
    """Create or update user's hormonal health profile."""
    print(f"🔍 [Hormonal] Upserting profile for user {user_id}")

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

        print(f"✅ [Hormonal] Profile upserted for user {user_id}")
        return result.data[0]

    except Exception as e:
        print(f"❌ [Hormonal] Error upserting profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/profile/{user_id}")
async def delete_hormonal_profile(user_id: UUID):
    """Delete user's hormonal health profile."""
    print(f"🔍 [Hormonal] Deleting profile for user {user_id}")

    try:
        supabase = get_supabase().client
        supabase.table("hormonal_profiles").delete().eq("user_id", str(user_id)).execute()
        print(f"✅ [Hormonal] Profile deleted for user {user_id}")
        return {"message": "Profile deleted successfully"}

    except Exception as e:
        print(f"❌ [Hormonal] Error deleting profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# HORMONE LOG ENDPOINTS
# ============================================================================

@router.post("/logs/{user_id}", response_model=HormoneLog)
async def create_hormone_log(user_id: UUID, log: HormoneLogCreate):
    """Create a hormone log entry."""
    print(f"🔍 [Hormonal] Creating log for user {user_id} on {log.log_date}")

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
                        p.get("cycle_length_days", 28)
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

        print(f"✅ [Hormonal] Log created for user {user_id}")
        return result.data[0]

    except Exception as e:
        print(f"❌ [Hormonal] Error creating log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/logs/{user_id}", response_model=List[HormoneLog])
async def get_hormone_logs(
    user_id: UUID,
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    limit: int = Query(30, ge=1, le=365)
):
    """Get hormone logs for a user with optional date range."""
    print(f"🔍 [Hormonal] Fetching logs for user {user_id}")

    try:
        supabase = get_supabase().client

        query = supabase.table("hormone_logs").select("*").eq("user_id", str(user_id))

        if start_date:
            query = query.gte("log_date", start_date.isoformat())
        if end_date:
            query = query.lte("log_date", end_date.isoformat())

        result = query.order("log_date", desc=True).limit(limit).execute()

        print(f"✅ [Hormonal] Retrieved {len(result.data)} logs for user {user_id}")
        return result.data

    except Exception as e:
        print(f"❌ [Hormonal] Error fetching logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/logs/{user_id}/today", response_model=Optional[HormoneLog])
async def get_today_hormone_log(user_id: UUID):
    """Get today's hormone log if it exists."""
    print(f"🔍 [Hormonal] Fetching today's log for user {user_id}")

    try:
        supabase = get_supabase().client
        result = supabase.table("hormone_logs").select("*").eq(
            "user_id", str(user_id)
        ).eq("log_date", date.today().isoformat()).execute()

        if result.data:
            return result.data[0]
        return None

    except Exception as e:
        print(f"❌ [Hormonal] Error fetching today's log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# CYCLE PHASE ENDPOINTS
# ============================================================================

@router.get("/cycle-phase/{user_id}", response_model=CyclePhaseInfo)
async def get_cycle_phase(user_id: UUID):
    """Get current cycle phase information for a user."""
    print(f"🔍 [Hormonal] Getting cycle phase for user {user_id}")

    try:
        supabase = get_supabase().client
        result = supabase.table("hormonal_profiles").select("*").eq("user_id", str(user_id)).execute()

        if not result.data:
            return CyclePhaseInfo(
                user_id=str(user_id),
                menstrual_tracking_enabled=False
            )

        profile = result.data[0]

        if not profile.get("menstrual_tracking_enabled") or not profile.get("last_period_start_date"):
            return CyclePhaseInfo(
                user_id=str(user_id),
                menstrual_tracking_enabled=profile.get("menstrual_tracking_enabled", False)
            )

        last_period = date.fromisoformat(profile["last_period_start_date"])
        cycle_length = profile.get("cycle_length_days", 28)
        current_day, current_phase = calculate_cycle_phase(last_period, cycle_length)

        # Calculate days until next phase
        phase_boundaries = {
            CyclePhase.MENSTRUAL: 5,
            CyclePhase.FOLLICULAR: 13,
            CyclePhase.OVULATION: 16,
            CyclePhase.LUTEAL: cycle_length
        }

        next_phases = {
            CyclePhase.MENSTRUAL: CyclePhase.FOLLICULAR,
            CyclePhase.FOLLICULAR: CyclePhase.OVULATION,
            CyclePhase.OVULATION: CyclePhase.LUTEAL,
            CyclePhase.LUTEAL: CyclePhase.MENSTRUAL
        }

        days_until_next = phase_boundaries[current_phase] - current_day + 1

        # Get recommendations
        recommendations = get_phase_recommendations(current_phase)

        return CyclePhaseInfo(
            user_id=str(user_id),
            menstrual_tracking_enabled=True,
            current_cycle_day=current_day,
            current_phase=current_phase,
            days_until_next_phase=days_until_next,
            next_phase=next_phases[current_phase],
            cycle_length_days=cycle_length,
            last_period_start_date=last_period,
            recommended_intensity=recommendations.workout_intensity if recommendations else None,
            avoid_exercises=recommendations.exercises_to_avoid if recommendations else [],
            recommended_exercises=recommendations.recommended_exercise_types if recommendations else [],
            nutrition_focus=recommendations.nutrition_tips if recommendations else []
        )

    except Exception as e:
        print(f"❌ [Hormonal] Error getting cycle phase: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/cycle-phase/recommendations/{phase}", response_model=CyclePhaseRecommendation)
async def get_phase_recommendation(phase: CyclePhase):
    """Get recommendations for a specific cycle phase."""
    recommendations = get_phase_recommendations(phase)
    if not recommendations:
        raise HTTPException(status_code=404, detail="Phase not found")
    return recommendations


@router.post("/cycle-phase/{user_id}/log-period")
async def log_period_start(user_id: UUID, period_date: date = Query(default=None)):
    """Log the start of a new menstrual period."""
    print(f"🔍 [Hormonal] Logging period start for user {user_id}")

    try:
        supabase = get_supabase().client

        period_start = period_date or date.today()

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

        print(f"✅ [Hormonal] Period logged for user {user_id} on {period_start}")
        return {"message": "Period start logged", "date": period_start.isoformat()}

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ [Hormonal] Error logging period: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# HORMONE-SUPPORTIVE FOODS ENDPOINTS
# ============================================================================

@router.get("/foods", response_model=List[HormoneSupportiveFood])
async def get_hormone_supportive_foods(
    goal: Optional[HormoneGoal] = Query(None),
    cycle_phase: Optional[CyclePhase] = Query(None)
):
    """Get hormone-supportive foods, optionally filtered by goal or cycle phase."""
    print(f"🔍 [Hormonal] Fetching hormone-supportive foods")

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
        print(f"✅ [Hormonal] Retrieved {len(result.data)} foods")
        return result.data

    except Exception as e:
        print(f"❌ [Hormonal] Error fetching foods: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/foods/recommendations/{user_id}", response_model=HormonalFoodRecommendation)
async def get_food_recommendations(user_id: UUID):
    """Get personalized hormone-supportive food recommendations."""
    print(f"🔍 [Hormonal] Getting food recommendations for user {user_id}")

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
                    profile.get("cycle_length_days", 28)
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
        print(f"❌ [Hormonal] Error getting food recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# COMPREHENSIVE INSIGHTS ENDPOINT
# ============================================================================

@router.get("/insights/{user_id}", response_model=HormonalInsights)
async def get_hormonal_insights(user_id: UUID):
    """Get comprehensive hormonal health insights for a user."""
    print(f"🔍 [Hormonal] Getting comprehensive insights for user {user_id}")

    try:
        supabase = get_supabase().client

        # Get profile
        profile_result = supabase.table("hormonal_profiles").select("*").eq("user_id", str(user_id)).execute()
        profile = profile_result.data[0] if profile_result.data else None

        # Get cycle phase info
        cycle_info = await get_cycle_phase(user_id)

        # Get recent logs (last 7 days)
        logs_result = supabase.table("hormone_logs").select("*").eq(
            "user_id", str(user_id)
        ).gte(
            "log_date", (date.today() - timedelta(days=7)).isoformat()
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
        food_recommendations = await get_food_recommendations(user_id)

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
        print(f"❌ [Hormonal] Error getting insights: {e}")
        raise HTTPException(status_code=500, detail=str(e))
