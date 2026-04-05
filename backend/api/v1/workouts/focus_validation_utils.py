"""
Focus area validation and exercise-muscle matching utilities.

Handles:
- Validating exercises match their intended focus area
- Filtering mismatched exercises
- Exercise muscle mapping (primary + secondary)
- Muscle profile comparison for exercise swaps
- Favorite workout context building
"""
import json
from typing import List, Dict, Any, Optional

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)


# Mapping of focus areas to target muscles
FOCUS_AREA_MUSCLES = {
    'legs': ['quads', 'quadriceps', 'hamstrings', 'glutes', 'calves', 'leg', 'thigh', 'hip'],
    'lower': ['quads', 'quadriceps', 'hamstrings', 'glutes', 'calves', 'leg', 'thigh', 'hip'],
    'push': ['chest', 'shoulders', 'triceps', 'pec', 'delt', 'shoulder'],
    'pull': ['back', 'biceps', 'lats', 'traps', 'rear delt', 'rhomboids'],
    'upper': ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'pec', 'delt', 'lats', 'arm'],
    'chest': ['chest', 'pec', 'pectorals'],
    'back': ['back', 'lats', 'traps', 'rhomboids', 'erector'],
    'shoulders': ['shoulders', 'delts', 'deltoids', 'delt'],
    'arms': ['biceps', 'triceps', 'forearms', 'arm', 'brachii'],
    'core': ['abs', 'core', 'obliques', 'abdominals', 'rectus', 'transverse'],
    'glutes': ['glutes', 'gluteus', 'hip', 'butt'],
}

# Exercises that clearly don't match specific focus areas
FOCUS_AREA_EXCLUDED_EXERCISES = {
    'legs': ['push-up', 'pushup', 'bench press', 'shoulder press', 'bicep curl', 'tricep', 'lat pulldown', 'pull-up', 'row', 'chest fly', 'dip'],
    'lower': ['push-up', 'pushup', 'bench press', 'shoulder press', 'bicep curl', 'tricep', 'lat pulldown', 'pull-up', 'row', 'chest fly', 'dip'],
    'push': ['squat', 'lunge', 'deadlift', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'hip thrust', 'pull-up', 'row', 'bicep curl', 'lat pulldown'],
    'pull': ['squat', 'lunge', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'push-up', 'pushup', 'bench press', 'shoulder press', 'tricep', 'chest fly', 'dip'],
    'chest': ['squat', 'lunge', 'deadlift', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'hip thrust', 'pull-up', 'row', 'bicep curl', 'lat pulldown', 'shoulder press', 'lateral raise'],
    'back': ['squat', 'lunge', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'push-up', 'pushup', 'bench press', 'shoulder press', 'tricep', 'chest fly', 'dip'],
    'shoulders': ['squat', 'lunge', 'deadlift', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'hip thrust', 'chest fly', 'bicep curl'],
}


def validate_exercise_matches_focus(
    exercise_name: str,
    muscle_group: str,
    focus_area: str,
) -> Dict[str, Any]:
    """Validate that an exercise matches the workout focus area."""
    exercise_lower = exercise_name.lower().strip()
    muscle_lower = (muscle_group or "").lower().strip()
    focus_lower = focus_area.lower().strip() if focus_area else ""

    if not focus_lower or focus_lower in ['full_body', 'fullbody', 'full body']:
        return {"matches": True, "reason": "Full body focus allows all exercises", "confidence": 1.0}

    excluded_exercises = FOCUS_AREA_EXCLUDED_EXERCISES.get(focus_lower, [])
    for excluded in excluded_exercises:
        if excluded in exercise_lower:
            return {
                "matches": False,
                "reason": f"'{exercise_name}' is a {excluded} exercise, not suitable for {focus_area} focus",
                "confidence": 0.95
            }

    target_muscles = FOCUS_AREA_MUSCLES.get(focus_lower, [])
    if target_muscles:
        for target in target_muscles:
            if target in muscle_lower or muscle_lower in target:
                return {
                    "matches": True,
                    "reason": f"'{muscle_group}' matches {focus_area} focus",
                    "confidence": 0.9
                }

        return {
            "matches": False,
            "reason": f"'{muscle_group}' does not match {focus_area} focus (expected: {', '.join(target_muscles[:3])})",
            "confidence": 0.8
        }

    return {"matches": True, "reason": "Unknown focus area, allowing exercise", "confidence": 0.5}


async def validate_and_filter_focus_mismatches(
    exercises: List[Dict[str, Any]],
    focus_area: str,
    workout_name: str,
) -> Dict[str, Any]:
    """Validate all exercises match the workout focus area and filter mismatches."""
    valid_exercises = []
    mismatched_exercises = []
    warnings = []

    focus_lower = (focus_area or "").lower().strip()

    if not focus_lower:
        return {
            "valid_exercises": exercises,
            "mismatched_exercises": [],
            "mismatch_count": 0,
            "warnings": []
        }

    # For full_body workouts: validate muscle group coverage instead of filtering
    if focus_lower in ['full_body', 'fullbody', 'full body']:
        coverage_groups = {
            "legs": {"legs", "quads", "quadriceps", "hamstrings", "glutes", "calves", "leg", "thigh", "hip", "lower body"},
            "back": {"back", "lats", "traps", "rhomboids", "rear delt", "middle back", "lower back", "upper back"},
            "chest_push": {"chest", "pectorals", "pecs", "shoulders", "deltoids", "triceps", "front delt"},
        }

        covered = {group: False for group in coverage_groups}
        for ex in exercises:
            muscle = (ex.get("muscle_group") or "").lower()
            ex_name = (ex.get("name") or "").lower()
            combined = f"{muscle} {ex_name}"
            for group, keywords in coverage_groups.items():
                if any(kw in combined for kw in keywords):
                    covered[group] = True

        missing_groups = [g for g, is_covered in covered.items() if not is_covered]

        if missing_groups:
            friendly = {"legs": "Legs/Glutes", "back": "Back/Pull", "chest_push": "Chest/Shoulders/Push"}
            missing_names = [friendly.get(g, g) for g in missing_groups]
            warning_msg = (
                f"⚠️ [{workout_name}] Full-body workout is MISSING exercises for: {', '.join(missing_names)}. "
                f"Exercises only cover: {', '.join(g for g, c in covered.items() if c) or 'unknown'}"
            )
            logger.warning(f"🚨 [Full Body Validation] {warning_msg}")
            warnings.append(warning_msg)

        return {
            "valid_exercises": exercises,
            "mismatched_exercises": [],
            "mismatch_count": 0,
            "warnings": warnings,
            "missing_muscle_groups": missing_groups,
        }

    for ex in exercises:
        exercise_name = ex.get("name", "")
        muscle_group = ex.get("muscle_group", "")

        validation = validate_exercise_matches_focus(exercise_name, muscle_group, focus_area)

        if validation["matches"]:
            valid_exercises.append(ex)
        else:
            mismatched_exercises.append(ex)
            warnings.append(f"⚠️ [{workout_name}] Mismatch: '{exercise_name}' ({muscle_group}) - {validation['reason']}")
            logger.warning(f"🚨 [Focus Validation] {validation['reason']}")

    mismatch_count = len(mismatched_exercises)

    if mismatch_count > 0:
        logger.warning(
            f"🚨 [Focus Validation] Workout '{workout_name}' has {mismatch_count}/{len(exercises)} "
            f"exercises that don't match the '{focus_area}' focus!"
        )

        if mismatch_count > len(exercises) / 2:
            logger.error(
                f"❌ [Focus Validation] CRITICAL: Majority of exercises in '{workout_name}' "
                f"don't match '{focus_area}' focus! This is likely an AI generation error."
            )

    return {
        "valid_exercises": valid_exercises,
        "mismatched_exercises": mismatched_exercises,
        "mismatch_count": mismatch_count,
        "warnings": warnings
    }


async def get_all_muscles_for_exercise(exercise_name: str) -> List[Dict[str, Any]]:
    """Get all muscles worked by an exercise with involvement percentages."""
    try:
        db = get_supabase_db()
        muscles = []
        exercise_name_lower = exercise_name.lower().strip()

        try:
            mapping_result = db.client.table("exercise_muscle_mappings").select(
                "muscle_name, involvement_percentage, is_primary"
            ).ilike("exercise_name", f"%{exercise_name_lower}%").execute()

            if mapping_result.data:
                for row in mapping_result.data:
                    muscles.append({
                        "muscle": row.get("muscle_name", "").lower(),
                        "involvement": row.get("involvement_percentage", 0.3),
                        "is_primary": row.get("is_primary", False),
                    })
                logger.debug(f"Found {len(muscles)} muscles from exercise_muscle_mappings for '{exercise_name}'")
                return muscles
        except Exception as e:
            logger.debug(f"Muscle mapping lookup failed: {e}")

        result = db.client.table("exercise_library_cleaned").select(
            "target_muscle, secondary_muscles, body_part"
        ).ilike("name", f"%{exercise_name_lower}%").limit(1).execute()

        if not result.data:
            result = db.client.table("exercise_library_cleaned").select(
                "target_muscle, secondary_muscles, body_part"
            ).eq("name", exercise_name).limit(1).execute()

        if result.data:
            exercise = result.data[0]
            target_muscle = (exercise.get("target_muscle") or exercise.get("body_part") or "").lower().strip()

            if target_muscle:
                muscles.append({
                    "muscle": target_muscle,
                    "involvement": 0.7,
                    "is_primary": True,
                })

            secondary_raw = exercise.get("secondary_muscles", [])
            from services.exercise_rag.filters import parse_secondary_muscles
            secondary_parsed = parse_secondary_muscles(secondary_raw)

            for sec in secondary_parsed:
                muscles.append({
                    "muscle": sec.get("muscle", "").lower(),
                    "involvement": sec.get("involvement", 0.3),
                    "is_primary": False,
                })

        if muscles:
            logger.debug(f"Found {len(muscles)} muscles for '{exercise_name}': {[m['muscle'] for m in muscles]}")
        else:
            logger.debug(f"No muscle data found for '{exercise_name}'")

        return muscles

    except Exception as e:
        logger.debug(f"Error getting muscles for exercise '{exercise_name}': {e}")
        return []


def compare_muscle_profiles(
    old_exercise_muscles: List[Dict[str, Any]],
    new_exercise_muscles: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """Compare the muscle profiles of two exercises to detect significant differences."""
    old_muscles = {m["muscle"].lower() for m in old_exercise_muscles if m.get("muscle")}
    new_muscles = {m["muscle"].lower() for m in new_exercise_muscles if m.get("muscle")}

    old_primary = next((m["muscle"].lower() for m in old_exercise_muscles if m.get("is_primary")), None)
    new_primary = next((m["muscle"].lower() for m in new_exercise_muscles if m.get("is_primary")), None)

    primary_match = False
    if old_primary and new_primary:
        primary_match = old_primary == new_primary or old_primary in new_primary or new_primary in old_primary

    common_muscles = old_muscles & new_muscles
    all_muscles = old_muscles | new_muscles

    similarity_score = len(common_muscles) / len(all_muscles) if all_muscles else 1.0

    missing_muscles = list(old_muscles - new_muscles)
    added_muscles = list(new_muscles - old_muscles)

    is_similar = primary_match and similarity_score >= 0.5

    warning = None
    if not primary_match:
        warning = f"Primary muscle changed from '{old_primary}' to '{new_primary}'"
    elif similarity_score < 0.5:
        warning = f"Muscle profile significantly different (similarity: {similarity_score:.0%})"
    elif missing_muscles:
        warning = f"Exercise no longer targets: {', '.join(missing_muscles)}"

    return {
        "is_similar": is_similar,
        "primary_match": primary_match,
        "similarity_score": similarity_score,
        "missing_muscles": missing_muscles,
        "new_muscles": added_muscles,
        "warning": warning,
    }


async def get_user_favorite_workouts(user_id: str) -> list:
    """Get user's favorite workouts for generation context."""
    try:
        db = get_supabase_db()
        result = db.client.table("workouts").select(
            "name, type, difficulty, exercises_json, duration_minutes"
        ).eq("user_id", user_id).eq("is_favorite", True).order(
            "created_at", desc=True
        ).limit(5).execute()

        return result.data if result.data else []
    except Exception as e:
        logger.error(f"Error getting favorite workouts: {e}")
        return []


def build_favorite_workouts_context(favorites: list) -> str:
    """Build prompt-ready context string from favorite workouts."""
    if not favorites:
        return ""

    from .utils import parse_json_field

    lines = ["FAVORITE WORKOUT TEMPLATES (workouts the user loved - use as inspiration):"]

    for i, fav in enumerate(favorites, 1):
        name = fav.get("name", "Unnamed")
        workout_type = fav.get("type", "unknown")
        difficulty = fav.get("difficulty", "medium")
        duration = fav.get("duration_minutes", "?")

        exercise_names = []
        exercises_json = fav.get("exercises_json")
        if exercises_json:
            parsed = parse_json_field(exercises_json, [])
            for ex in parsed:
                if isinstance(ex, dict):
                    ex_name = ex.get("name") or ex.get("exercise_name")
                    if ex_name:
                        exercise_names.append(ex_name)

        exercises_str = ", ".join(exercise_names[:6])
        if len(exercise_names) > 6:
            exercises_str += f" (+{len(exercise_names) - 6} more)"

        lines.append(
            f"{i}. \"{name}\" ({workout_type}, {difficulty}): "
            f"{exercises_str} [{len(exercise_names)} exercises, {duration}min]"
        )

    lines.append("When generating for the same muscle group/type, prefer similar exercise combinations and structures.")
    return "\n".join(lines)
