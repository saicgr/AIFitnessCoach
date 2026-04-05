"""
Readiness, mood, injury, and comeback utilities.

Handles:
- User readiness score fetching and interpretation
- Mood check-in data
- Injury-to-muscle mapping
- Workout parameter adjustments for readiness/mood
- Active injuries with muscle avoidance
- Comeback/break detection and adjustments
"""
import json
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)


# Mapping from injury body parts to muscles that should be avoided
INJURY_TO_AVOIDED_MUSCLES = {
    "shoulder": ["shoulders", "chest", "triceps", "delts", "anterior_delts", "lateral_delts", "rear_delts"],
    "back": ["back", "lats", "lower_back", "traps", "rhomboids", "erector_spinae"],
    "lower_back": ["lower_back", "back", "erector_spinae", "glutes", "hamstrings"],
    "knee": ["quads", "hamstrings", "calves", "legs", "quadriceps", "glutes"],
    "wrist": ["forearms", "biceps", "triceps", "grip"],
    "ankle": ["calves", "legs", "tibialis", "soleus", "gastrocnemius"],
    "hip": ["glutes", "hip_flexors", "legs", "quads", "hamstrings", "adductors", "abductors"],
    "elbow": ["biceps", "triceps", "forearms", "brachialis"],
    "neck": ["traps", "shoulders", "neck", "upper_back"],
    "chest": ["chest", "pectorals", "shoulders", "triceps"],
    "groin": ["adductors", "hip_flexors", "legs", "quads"],
    "hamstring": ["hamstrings", "glutes", "legs"],
    "quad": ["quads", "quadriceps", "legs", "knee"],
    "calf": ["calves", "legs", "ankle"],
    "rotator_cuff": ["shoulders", "chest", "delts", "rotator_cuff"],
}


async def get_user_readiness_score(user_id: str) -> Optional[int]:
    """Get the user's latest readiness score (0-100) or None if not available."""
    try:
        db = get_supabase_db()

        result = db.client.table("readiness") \
            .select("score, created_at") \
            .eq("user_id", user_id) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()

        if result.data and len(result.data) > 0:
            score = result.data[0].get("score")
            created_at = result.data[0].get("created_at", "")

            if created_at:
                try:
                    score_time = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                    age_hours = (datetime.now(score_time.tzinfo) - score_time).total_seconds() / 3600

                    if age_hours > 24:
                        logger.info(f"🔍 [Readiness] Score for user {user_id} is {age_hours:.1f} hours old, may be stale")
                except Exception as e:
                    logger.debug(f"Failed to parse readiness timestamp: {e}")

            logger.info(f"✅ [Readiness] User {user_id} readiness score: {score}")
            return score

        logger.debug(f"[Readiness] No readiness score found for user {user_id}")
        return None

    except Exception as e:
        logger.error(f"❌ [Readiness] Error getting readiness score for user {user_id}: {e}")
        return None


async def get_user_latest_mood(user_id: str) -> Optional[dict]:
    """Get the user's latest mood check-in from today."""
    try:
        db = get_supabase_db()

        try:
            result = db.client.table("today_mood_checkin") \
                .select("mood, check_in_time") \
                .eq("user_id", user_id) \
                .limit(1) \
                .execute()
        except Exception:
            today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0).isoformat()

            result = db.client.table("mood_checkins") \
                .select("mood, check_in_time") \
                .eq("user_id", user_id) \
                .gte("check_in_time", today_start) \
                .order("check_in_time", desc=True) \
                .limit(1) \
                .execute()

        if result.data and len(result.data) > 0:
            mood_data = {
                "mood": result.data[0].get("mood", "good"),
                "check_in_time": result.data[0].get("check_in_time"),
            }
            logger.info(f"✅ [Mood] User {user_id} mood: {mood_data['mood']}")
            return mood_data

        logger.debug(f"[Mood] No mood check-in found for user {user_id} today")
        return None

    except Exception as e:
        logger.error(f"❌ [Mood] Error getting mood for user {user_id}: {e}")
        return None


def get_muscles_to_avoid_from_injuries(injuries: List[str]) -> List[str]:
    """Convert injury body parts to muscles that should be avoided."""
    if not injuries:
        return []

    muscles_to_avoid = set()

    for injury in injuries:
        injury_lower = injury.lower().strip()

        if injury_lower in INJURY_TO_AVOIDED_MUSCLES:
            muscles_to_avoid.update(INJURY_TO_AVOIDED_MUSCLES[injury_lower])
            logger.info(f"🔍 [Injury Mapping] {injury} -> avoiding: {INJURY_TO_AVOIDED_MUSCLES[injury_lower]}")
        else:
            for injury_key, muscles in INJURY_TO_AVOIDED_MUSCLES.items():
                if injury_key in injury_lower or injury_lower in injury_key:
                    muscles_to_avoid.update(muscles)
                    logger.info(f"🔍 [Injury Mapping] {injury} (partial match: {injury_key}) -> avoiding: {muscles}")
                    break
            else:
                logger.warning(f"⚠️ [Injury Mapping] Unknown injury type: {injury}, no muscle mapping found")

    result = list(muscles_to_avoid)
    logger.info(f"✅ [Injury Mapping] Total muscles to avoid: {result}")
    return result


def adjust_workout_params_for_readiness(
    workout_params: dict,
    readiness_score: Optional[int],
    mood: Optional[str] = None,
) -> dict:
    """Adjust workout parameters based on user's readiness score and mood."""
    if not workout_params:
        workout_params = {}

    adjusted = dict(workout_params)
    adjustments_made = []

    base_sets = adjusted.get("sets", 3)
    base_reps = adjusted.get("reps", 10)
    base_rest = adjusted.get("rest_seconds", 60)

    if isinstance(base_reps, str):
        try:
            if "-" in base_reps:
                low, high = base_reps.split("-")
                base_reps = (int(low) + int(high)) // 2
            else:
                base_reps = int(base_reps)
        except ValueError:
            base_reps = 10

    if readiness_score is not None:
        if readiness_score < 50:
            adjusted["sets"] = max(2, int(base_sets * 0.8))
            adjusted["reps"] = max(6, int(base_reps * 0.8))
            adjusted["rest_seconds"] = int(base_rest * 1.3)
            adjusted["readiness_adjustment"] = "low_readiness"
            adjustments_made.append(f"Low readiness ({readiness_score}): reduced sets/reps 20%, increased rest 30%")
        elif readiness_score > 70:
            adjusted["sets"] = min(5, int(base_sets * 1.1))
            adjusted["reps"] = min(15, int(base_reps * 1.1))
            adjusted["rest_seconds"] = max(45, int(base_rest * 0.9))
            adjusted["readiness_adjustment"] = "high_readiness"
            adjustments_made.append(f"High readiness ({readiness_score}): increased sets/reps 10%, reduced rest 10%")
        else:
            adjusted["sets"] = base_sets
            adjusted["reps"] = base_reps
            adjusted["rest_seconds"] = base_rest
            adjusted["readiness_adjustment"] = "normal"

    if mood:
        mood_lower = mood.lower()

        if mood_lower in ["tired", "stressed", "anxious"]:
            current_sets = adjusted.get("sets", base_sets)
            current_reps = adjusted.get("reps", base_reps)
            current_rest = adjusted.get("rest_seconds", base_rest)

            adjusted["sets"] = max(2, int(current_sets * 0.9))
            adjusted["reps"] = max(5, int(current_reps * 0.9))
            adjusted["rest_seconds"] = int(current_rest * 1.2)
            adjusted["mood_adjustment"] = mood_lower
            adjustments_made.append(f"Mood ({mood_lower}): further reduced intensity")

            adjusted["suggest_workout_type"] = "recovery"

        elif mood_lower == "great":
            adjusted["mood_adjustment"] = "great"

    if adjustments_made:
        logger.info(f"🎯 [Workout Params] Adjustments: {', '.join(adjustments_made)}")
        logger.info(f"🎯 [Workout Params] Final: sets={adjusted.get('sets')}, reps={adjusted.get('reps')}, rest={adjusted.get('rest_seconds')}s")

    return adjusted


async def get_active_injuries_with_muscles(user_id: str) -> dict:
    """Get user's active injuries AND automatically map them to avoided muscles."""
    try:
        db = get_supabase_db()

        injuries_result = db.client.table("user_injuries") \
            .select("body_part, severity, status") \
            .eq("user_id", user_id) \
            .eq("status", "active") \
            .execute()

        active_injuries = []
        if injuries_result.data:
            for injury in injuries_result.data:
                body_part = injury.get("body_part", "")
                if body_part:
                    active_injuries.append(body_part)

        user = db.get_user(user_id)
        if user:
            user_injuries = user.get("active_injuries", [])
            if isinstance(user_injuries, str):
                try:
                    user_injuries = json.loads(user_injuries)
                except json.JSONDecodeError:
                    user_injuries = []

            for inj in user_injuries:
                if isinstance(inj, dict):
                    body_part = inj.get("body_part", "")
                elif isinstance(inj, str):
                    body_part = inj
                else:
                    body_part = ""

                if body_part and body_part not in active_injuries:
                    active_injuries.append(body_part)

        avoided_muscles = get_muscles_to_avoid_from_injuries(active_injuries)

        result = {
            "injuries": active_injuries,
            "avoided_muscles": avoided_muscles,
        }

        if active_injuries:
            logger.info(f"✅ [Injuries] User {user_id}: {len(active_injuries)} active injuries -> {len(avoided_muscles)} muscles to avoid")
            logger.info(f"   Injuries: {active_injuries}")
            logger.info(f"   Avoided muscles: {avoided_muscles}")

        return result

    except Exception as e:
        logger.error(f"❌ [Injuries] Error getting active injuries for user {user_id}: {e}")
        return {"injuries": [], "avoided_muscles": []}


async def get_user_comeback_status(user_id: str) -> dict:
    """Check if user is in comeback mode (returning from a break)."""
    try:
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            return {"in_comeback_mode": False, "days_since_last_workout": None, "reason": "User not found"}

        created_at = user.get("created_at")
        if created_at:
            try:
                if isinstance(created_at, str):
                    created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                else:
                    created = created_at
                account_age_days = (datetime.now(created.tzinfo) - created).days
                if account_age_days < 14:
                    return {
                        "in_comeback_mode": False,
                        "days_since_last_workout": None,
                        "reason": f"Account only {account_age_days} days old (< 14 day threshold)"
                    }
            except Exception as e:
                logger.debug(f"Failed to parse account age: {e}")

        preferences = user.get("preferences", {})
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        if preferences.get("comeback_mode", False):
            return {
                "in_comeback_mode": True,
                "days_since_last_workout": None,
                "reason": "User marked as in comeback mode"
            }

        cutoff_date = (datetime.now() - timedelta(days=14)).isoformat()

        result = db.client.table("workouts") \
            .select("scheduled_date, is_completed") \
            .eq("user_id", user_id) \
            .eq("is_completed", True) \
            .order("scheduled_date", desc=True) \
            .limit(1) \
            .execute()

        if not result.data:
            return {
                "in_comeback_mode": False,
                "days_since_last_workout": None,
                "reason": "No workout history found"
            }

        last_workout_date = result.data[0].get("scheduled_date")
        if last_workout_date:
            try:
                last_date = datetime.fromisoformat(last_workout_date.replace("Z", "+00:00"))
                days_since = (datetime.now(last_date.tzinfo) - last_date).days

                if days_since >= 14:
                    logger.info(f"🔄 [Comeback] User {user_id} is in comeback mode: {days_since} days since last workout")
                    return {
                        "in_comeback_mode": True,
                        "days_since_last_workout": days_since,
                        "reason": f"No workouts in {days_since} days (14+ day break)"
                    }
                else:
                    return {
                        "in_comeback_mode": False,
                        "days_since_last_workout": days_since,
                        "reason": f"Last workout {days_since} days ago (< 14 day threshold)"
                    }
            except Exception as e:
                logger.warning(f"Failed to check workout history: {e}")

        return {
            "in_comeback_mode": False,
            "days_since_last_workout": None,
            "reason": "Could not determine workout history"
        }

    except Exception as e:
        logger.error(f"❌ [Comeback] Error checking comeback status for user {user_id}: {e}")
        return {"in_comeback_mode": False, "days_since_last_workout": None, "reason": str(e)}


async def get_comeback_context(user_id: str) -> dict:
    """Get complete comeback context for workout generation."""
    try:
        from services.comeback_service import get_comeback_service

        comeback_service = get_comeback_service()
        break_status = await comeback_service.detect_break_status(user_id)

        needs_comeback = break_status.break_type.value != "active"

        if not needs_comeback:
            return {
                "needs_comeback": False,
                "break_status": None,
                "adjustments": None,
                "prompt_context": "",
                "extra_warmup_minutes": 0,
            }

        logger.info(
            f"🔄 [Comeback] User {user_id} returning after {break_status.days_since_last_workout} days "
            f"({break_status.break_type.value})"
        )

        if break_status.user_age and break_status.user_age >= 60:
            logger.info(f"👴 [Comeback] Senior user (age {break_status.user_age}) - applying additional adjustments")

        return {
            "needs_comeback": True,
            "break_status": {
                "days_off": break_status.days_since_last_workout,
                "break_type": break_status.break_type.value,
                "comeback_week": break_status.comeback_week,
                "in_comeback_mode": break_status.in_comeback_mode,
                "recommended_weeks": break_status.recommended_comeback_weeks,
                "user_age": break_status.user_age,
            },
            "adjustments": {
                "volume_multiplier": break_status.adjustments.volume_multiplier,
                "intensity_multiplier": break_status.adjustments.intensity_multiplier,
                "extra_rest_seconds": break_status.adjustments.extra_rest_seconds,
                "extra_warmup_minutes": break_status.adjustments.extra_warmup_minutes,
                "max_exercise_count": break_status.adjustments.max_exercise_count,
                "avoid_movements": break_status.adjustments.avoid_movements,
                "focus_areas": break_status.adjustments.focus_areas,
            },
            "prompt_context": break_status.prompt_context,
            "extra_warmup_minutes": break_status.adjustments.extra_warmup_minutes,
        }

    except Exception as e:
        logger.error(f"❌ [Comeback] Error getting comeback context: {e}")
        return {
            "needs_comeback": False,
            "break_status": None,
            "adjustments": None,
            "prompt_context": "",
            "extra_warmup_minutes": 0,
        }


async def apply_comeback_adjustments_to_exercises(
    exercises: List[dict],
    comeback_context: dict,
) -> List[dict]:
    """Apply comeback adjustments to a list of exercises."""
    if not comeback_context.get("needs_comeback") or not exercises:
        return exercises

    adjustments = comeback_context.get("adjustments", {})
    if not adjustments:
        return exercises

    volume_mult = adjustments.get("volume_multiplier", 1.0)
    intensity_mult = adjustments.get("intensity_multiplier", 1.0)
    extra_rest = adjustments.get("extra_rest_seconds", 0)
    max_exercises = adjustments.get("max_exercise_count", 8)

    exercises = exercises[:max_exercises]

    modified = []
    for ex in exercises:
        mod_ex = dict(ex)

        if "sets" in mod_ex:
            original_sets = mod_ex["sets"]
            mod_ex["sets"] = max(2, int(original_sets * volume_mult))

        if "reps" in mod_ex:
            original_reps = mod_ex["reps"]
            if isinstance(original_reps, int):
                mod_ex["reps"] = max(6, int(original_reps * (volume_mult + 0.1)))

        if "weight_kg" in mod_ex and mod_ex["weight_kg"]:
            original_weight = float(mod_ex["weight_kg"])
            new_weight = original_weight * intensity_mult
            mod_ex["weight_kg"] = round(new_weight / 2.5) * 2.5

        rest = mod_ex.get("rest_seconds", 60)
        mod_ex["rest_seconds"] = rest + extra_rest

        break_info = comeback_context.get("break_status", {})
        if break_info:
            days_off = break_info.get("days_off", 0)
            comeback_note = f"[COMEBACK: {days_off} days off] Reduced intensity for safe return."
            existing_notes = mod_ex.get("notes", "")
            mod_ex["notes"] = f"{comeback_note} {existing_notes}".strip()

        modified.append(mod_ex)

    logger.info(
        f"✅ [Comeback] Applied adjustments: volume x{volume_mult:.2f}, "
        f"intensity x{intensity_mult:.2f}, +{extra_rest}s rest, "
        f"{len(modified)}/{max_exercises} exercises"
    )

    return modified


async def start_comeback_mode_if_needed(user_id: str) -> bool:
    """Start comeback mode for user if they need it."""
    try:
        from services.comeback_service import get_comeback_service

        comeback_service = get_comeback_service()

        if await comeback_service.should_trigger_comeback(user_id):
            history_id = await comeback_service.start_comeback_mode(user_id)
            if history_id:
                logger.info(f"🔄 [Comeback] Started comeback mode for user {user_id}")
                return True

        return False

    except Exception as e:
        logger.error(f"❌ [Comeback] Error starting comeback mode: {e}")
        return False


def get_comeback_prompt_context(
    days_off: int,
    user_age: Optional[int] = None,
    volume_reduction_pct: float = 0,
    intensity_reduction_pct: float = 0,
) -> str:
    """Generate a context string for Gemini prompt about comeback workout."""
    if days_off < 7:
        return ""

    context_parts = [
        "",
        "## Comeback/Return-to-Training Context",
        f"- User is returning after {days_off} days off"
    ]

    if volume_reduction_pct > 0:
        context_parts.append(f"- Apply {int(volume_reduction_pct)}% volume reduction (fewer sets/reps)")

    if intensity_reduction_pct > 0:
        context_parts.append(f"- Apply {int(intensity_reduction_pct)}% intensity reduction (lighter weights)")

    context_parts.extend([
        "- Focus on: reactivation, joint mobility, proper form",
        "- Avoid: heavy loads, high rep counts, explosive movements",
        "- Include: extra warm-up time, mobility work, longer rest periods"
    ])

    if user_age:
        if user_age >= 70:
            context_parts.extend([
                "",
                "## SENIOR RETURN-TO-TRAINING (Age 70+):",
                "- CRITICAL: Extra caution required for safe return",
                "- Prioritize: controlled movements, balance work, joint health",
                "- Avoid: jumping, explosive movements, rapid changes of direction",
                "- Include: extended warmup (10+ minutes), balance exercises",
                "- Maximum 4 exercises per session",
                "- Minimum 90 seconds rest between sets",
                "- Focus on quality of movement over intensity"
            ])
        elif user_age >= 60:
            context_parts.extend([
                "",
                "## OLDER ADULT PROTOCOL (Age 60+):",
                "- Include balance and stability exercises",
                "- Avoid high-impact movements",
                "- Extended warmup recommended (7-10 minutes)",
                "- Focus on joint-friendly exercises"
            ])
        elif user_age >= 50:
            context_parts.extend([
                "",
                "## MIDDLE-AGED PROTOCOL (Age 50+):",
                "- Emphasize proper warmup and cooldown",
                "- Prioritize joint-friendly exercise variations",
                "- Allow for longer recovery between intense movements"
            ])

    return "\n".join(context_parts)
