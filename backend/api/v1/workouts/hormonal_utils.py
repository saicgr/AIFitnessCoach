"""
Hormonal health context utilities.

Handles:
- Gender-specific workout adjustments
- Menstrual cycle phase detection and intensity scaling
- Hormonal goal recommendations (testosterone, PCOS, menopause, etc.)
- Symptom-based adjustments
- Kegel exercise integration for warmup/cooldown
"""
import json
from datetime import date, datetime, timedelta
from typing import List, Dict, Any, Optional

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.timezone_utils import get_user_today

logger = get_logger(__name__)


async def get_user_hormonal_context(user_id: str, timezone_str: str) -> dict:
    """Get user's hormonal health context for workout generation."""
    try:
        db = get_supabase_db()
        context = {
            "gender": None, "hormone_goals": [], "primary_goal": None,
            "cycle_phase": None, "cycle_day": None, "recommended_intensity": None,
            "recent_symptoms": [], "symptom_severity": None,
            "kegels_enabled": False, "include_kegels_in_warmup": False,
            "include_kegels_in_cooldown": False, "kegel_level": "beginner",
            "kegel_focus_area": "general", "ai_context": "",
        }

        user_response = db.client.table("users").select("gender").eq("id", user_id).maybe_single().execute()
        if user_response and user_response.data:
            context["gender"] = user_response.data.get("gender")

        profile_response = db.client.table("hormonal_profiles").select("*").eq("user_id", user_id).maybe_single().execute()

        if profile_response and profile_response.data:
            profile = profile_response.data
            context["hormone_goals"] = profile.get("hormone_goals", [])
            context["primary_goal"] = profile.get("primary_goal")

            if profile.get("menstrual_tracking_enabled") and profile.get("last_period_date"):
                try:
                    last_period = date.fromisoformat(profile["last_period_date"])
                    avg_cycle_length = profile.get("avg_cycle_length", 28)
                    today = date.fromisoformat(get_user_today(timezone_str))
                    days_since_period = (today - last_period).days
                    cycle_day = (days_since_period % avg_cycle_length) + 1
                    context["cycle_day"] = cycle_day

                    if cycle_day <= 5:
                        context["cycle_phase"] = "menstrual"
                        context["recommended_intensity"] = "light"
                    elif cycle_day <= 13:
                        context["cycle_phase"] = "follicular"
                        context["recommended_intensity"] = "moderate_to_high"
                    elif cycle_day <= 16:
                        context["cycle_phase"] = "ovulation"
                        context["recommended_intensity"] = "high"
                    else:
                        context["cycle_phase"] = "luteal"
                        context["recommended_intensity"] = "moderate"

                except (ValueError, TypeError) as e:
                    logger.warning(f"[Hormonal Context] Failed to calculate cycle phase: {e}", exc_info=True)

        cutoff = (datetime.now() - timedelta(days=3)).date().isoformat()
        logs_response = db.client.table("hormone_logs").select(
            "symptoms, energy_level"
        ).eq("user_id", user_id).gte("log_date", cutoff).order("log_date", desc=True).limit(3).execute()

        if logs_response and logs_response.data:
            all_symptoms = []
            for log in logs_response.data:
                symptoms = log.get("symptoms", [])
                if symptoms:
                    all_symptoms.extend(symptoms)

            context["recent_symptoms"] = list(set(all_symptoms))[:5]

            latest_symptoms = logs_response.data[0].get("symptoms", [])
            if latest_symptoms:
                symptom_count = len(latest_symptoms)
                if symptom_count >= 4:
                    context["symptom_severity"] = "severe"
                elif symptom_count >= 2:
                    context["symptom_severity"] = "moderate"
                else:
                    context["symptom_severity"] = "mild"

        kegel_response = db.client.table("kegel_preferences").select("*").eq("user_id", user_id).maybe_single().execute()

        if kegel_response and kegel_response.data:
            prefs = kegel_response.data
            context["kegels_enabled"] = prefs.get("kegels_enabled", False)
            context["include_kegels_in_warmup"] = prefs.get("include_in_warmup", False)
            context["include_kegels_in_cooldown"] = prefs.get("include_in_cooldown", False)
            context["kegel_level"] = prefs.get("current_level", "beginner")
            context["kegel_focus_area"] = prefs.get("focus_area", "general")

        context["ai_context"] = build_hormonal_ai_context(context)

        return context

    except Exception as e:
        logger.error(f"[Hormonal Context] Failed to get hormonal context: {e}", exc_info=True)
        return {
            "gender": None, "hormone_goals": [], "primary_goal": None,
            "cycle_phase": None, "cycle_day": None, "recommended_intensity": None,
            "recent_symptoms": [], "symptom_severity": None,
            "kegels_enabled": False, "include_kegels_in_warmup": False,
            "include_kegels_in_cooldown": False, "kegel_level": "beginner",
            "kegel_focus_area": "general", "ai_context": "",
        }


def build_hormonal_ai_context(hormonal_context: dict) -> str:
    """Build AI prompt context string from hormonal context."""
    context_parts = []

    gender = hormonal_context.get("gender")
    if gender:
        if gender == "male":
            context_parts.append(
                "User is male. For testosterone optimization, prioritize compound movements "
                "(squats, deadlifts, bench press, rows) with heavier weights and adequate rest (2-3 min). "
                "Include exercises that engage large muscle groups."
            )
        elif gender == "female":
            context_parts.append(
                "User is female. Include a balanced mix of strength training with focus on "
                "proper form and progressive overload. Include glute, core, and full-body exercises."
            )

    primary_goal = hormonal_context.get("primary_goal")
    if primary_goal:
        goal_recommendations = {
            "testosterone_optimization": (
                "For testosterone optimization: prioritize heavy compound lifts (squat, deadlift, bench), "
                "use 6-10 rep range for strength, adequate rest between sets (2-3 min), "
                "avoid excessive cardio which can lower testosterone."
            ),
            "estrogen_balance": (
                "For estrogen balance: include a mix of strength and cardio, "
                "focus on stress-reducing exercises, include hip-opening stretches, "
                "moderate intensity with good recovery."
            ),
            "pcos_management": (
                "For PCOS management: prioritize strength training over cardio, "
                "moderate-intensity resistance training, include metabolic circuits, "
                "avoid excessive high-intensity which can increase cortisol."
            ),
            "menopause_support": (
                "For menopause support: prioritize bone-loading exercises (weight-bearing), "
                "include balance work, focus on joint-friendly movements, "
                "include strength training to maintain muscle mass."
            ),
            "fertility_support": (
                "For fertility support: moderate intensity only, avoid overtraining, "
                "include stress-reducing exercises, focus on pelvic health and core stability."
            ),
            "postpartum_recovery": (
                "For postpartum recovery: focus on core rehabilitation, pelvic floor exercises, "
                "gradual progression, avoid high-impact until cleared, include diaphragmatic breathing."
            ),
        }
        if primary_goal in goal_recommendations:
            context_parts.append(goal_recommendations[primary_goal])

    cycle_phase = hormonal_context.get("cycle_phase")
    cycle_day = hormonal_context.get("cycle_day")
    if cycle_phase:
        phase_recommendations = {
            "menstrual": (
                f"User is in menstrual phase (day {cycle_day}). REDUCE workout intensity by 20-30%. "
                "Focus on lighter weights, gentle movement, yoga, walking. "
                "Avoid high-intensity or explosive exercises. Prioritize recovery."
            ),
            "follicular": (
                f"User is in follicular phase (day {cycle_day}). Energy is rising. "
                "Good time for trying new exercises, building strength, increasing intensity gradually. "
                "Can include more challenging workouts."
            ),
            "ovulation": (
                f"User is in ovulation phase (day {cycle_day}). Peak energy and strength. "
                "Great time for high-intensity workouts, heavy lifts, PRs. "
                "Note: slightly higher injury risk - emphasize proper form."
            ),
            "luteal": (
                f"User is in luteal phase (day {cycle_day}). Energy may be decreasing. "
                "Focus on moderate intensity, steady-state exercises, strength maintenance. "
                "Avoid pushing for PRs, focus on consistency."
            ),
        }
        if cycle_phase in phase_recommendations:
            context_parts.append(phase_recommendations[cycle_phase])

    symptoms = hormonal_context.get("recent_symptoms", [])
    severity = hormonal_context.get("symptom_severity")
    if symptoms and severity in ["moderate", "severe"]:
        context_parts.append(
            f"User has reported {severity} symptoms: {', '.join(symptoms[:3])}. "
            "Adjust workout intensity accordingly, provide modifications, "
            "focus on feel-good exercises rather than challenging ones."
        )

    if hormonal_context.get("kegels_enabled"):
        kegel_parts = []
        if hormonal_context.get("include_kegels_in_warmup"):
            level = hormonal_context.get("kegel_level", "beginner")
            focus = hormonal_context.get("kegel_focus_area", "general")
            kegel_parts.append(
                f"Include {level}-level kegel exercises in the WARMUP section. "
                f"Focus area: {focus.replace('_', ' ')}."
            )
        if hormonal_context.get("include_kegels_in_cooldown"):
            level = hormonal_context.get("kegel_level", "beginner")
            focus = hormonal_context.get("kegel_focus_area", "general")
            kegel_parts.append(
                f"Include {level}-level kegel exercises in the COOLDOWN/STRETCHING section. "
                f"Focus area: {focus.replace('_', ' ')}."
            )
        if kegel_parts:
            context_parts.append(" ".join(kegel_parts))

    return " ".join(context_parts) if context_parts else ""


def adjust_workout_for_cycle_phase(
    exercises: List[dict],
    cycle_phase: str,
    symptom_severity: str = None,
) -> List[dict]:
    """Adjust workout exercises based on menstrual cycle phase."""
    if not exercises or not cycle_phase:
        return exercises

    adjusted = []

    for ex in exercises:
        adjusted_ex = dict(ex)

        sets = ex.get("sets", 3)
        reps = ex.get("reps", 10)

        if isinstance(reps, str):
            try:
                if "-" in reps:
                    parts = reps.split("-")
                    reps = int(parts[1].strip())
                else:
                    reps = int(reps.strip())
            except (ValueError, IndexError):
                reps = 10

        if cycle_phase == "menstrual":
            intensity_reduction = 0.7 if symptom_severity in ["moderate", "severe"] else 0.8
            adjusted_ex["sets"] = max(2, int(sets * intensity_reduction))
            adjusted_ex["reps"] = max(6, int(reps * intensity_reduction))
            adjusted_ex["notes"] = adjusted_ex.get("notes", "") + " (Modified for menstrual phase)"

        elif cycle_phase == "luteal":
            if symptom_severity in ["moderate", "severe"]:
                adjusted_ex["sets"] = max(2, int(sets * 0.85))
                adjusted_ex["reps"] = max(6, int(reps * 0.9))

        adjusted.append(adjusted_ex)

    return adjusted


async def get_kegel_exercises_for_workout(
    user_id: str,
    placement: str,
) -> List[dict]:
    """Get kegel exercises to include in workout warmup or cooldown."""
    try:
        db = get_supabase_db()

        prefs_response = db.client.table("kegel_preferences").select("*").eq("user_id", user_id).single().execute()

        if not prefs_response.data:
            return []

        prefs = prefs_response.data

        if not prefs.get("kegels_enabled", False):
            return []

        if placement == "warmup" and not prefs.get("include_in_warmup", False):
            return []
        if placement == "cooldown" and not prefs.get("include_in_cooldown", False):
            return []

        level = prefs.get("current_level", "beginner")
        focus = prefs.get("focus_area", "general")

        target_audience = "all"
        if focus in ["male_specific", "prostate_health"]:
            target_audience = "male"
        elif focus in ["female_specific", "postpartum"]:
            target_audience = "female"

        query = db.client.table("kegel_exercises").select("*").eq("difficulty", level)

        if target_audience != "all":
            query = query.or_(f"target_audience.eq.{target_audience},target_audience.eq.all")
        else:
            query = query.eq("target_audience", "all")

        exercises_response = query.limit(2).execute()

        if not exercises_response.data:
            exercises_response = db.client.table("kegel_exercises").select(
                "*"
            ).eq("difficulty", "beginner").eq("target_audience", "all").limit(2).execute()

        kegel_exercises = []
        for ex in (exercises_response.data or []):
            kegel_exercises.append({
                "name": ex.get("display_name", ex.get("name")),
                "type": "kegel",
                "duration_seconds": ex.get("default_duration_seconds", 30),
                "reps": ex.get("default_reps", 10),
                "hold_seconds": ex.get("default_hold_seconds", 5),
                "rest_seconds": ex.get("rest_between_reps_seconds", 5),
                "instructions": ex.get("instructions", []),
                "notes": f"Pelvic floor exercise - {placement}",
                "kegel_exercise_id": ex.get("id"),
            })

        logger.info(f"[Kegel Exercises] Added {len(kegel_exercises)} kegel exercises to {placement}")
        return kegel_exercises

    except Exception as e:
        logger.error(f"[Kegel Exercises] Failed to get kegel exercises for {placement}: {e}", exc_info=True)
        return []
