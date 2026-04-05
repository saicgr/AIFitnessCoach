"""
User preference fetching utilities.

All async functions that fetch user-specific preferences from the database
for use in workout generation. These are typically called in parallel via
asyncio.gather() for performance.

Handles:
- Strength history (ChromaDB + imported)
- Personal bests / PRs
- Performance context formatting
- Favorite exercises
- Exercise consistency mode
- Exercise queue management
- Staple exercises
- Variation percentage
- 1RM data and weight calculations
- Training intensity and overrides
- Avoided exercises and muscles
- Progression pace
- Workout type preference
- Exercise substitution
"""
import json
import re
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.exercise_rag.filters import filter_by_equipment
from services.exercise_rag.utils import infer_equipment_from_name

logger = get_logger(__name__)


def fuzzy_exercise_match(name1: str, name2: str) -> bool:
    """
    Check if two exercise names are similar enough to be considered the same.

    Handles variations like:
    - "Bench Press" vs "Barbell Bench Press"
    - "Squat" vs "Barbell Back Squat"
    - "Pull-up" vs "Pull Up" vs "Pullup"
    """
    # First, normalize compound words (pullup -> pull up, pushup -> push up)
    def expand_compound(name: str) -> str:
        name = name.lower()
        name = re.sub(r'pullup', 'pull up', name)
        name = re.sub(r'pushup', 'push up', name)
        name = re.sub(r'situp', 'sit up', name)
        name = re.sub(r'chinup', 'chin up', name)
        name = re.sub(r'stepup', 'step up', name)
        name = re.sub(r'lunge', 'lunge', name)
        name = name.replace('-', ' ')
        return name

    def normalize(name: str) -> set:
        name = expand_compound(name)
        remove_words = {
            'barbell', 'dumbbell', 'cable', 'machine', 'smith',
            'seated', 'standing', 'incline', 'decline', 'flat',
            'wide', 'narrow', 'close', 'grip', 'overhand', 'underhand',
            'single', 'double', 'one', 'two', 'arm', 'leg',
            'front', 'back', 'rear', 'side', 'lateral',
        }
        words = set(re.findall(r'[a-z]+', name))
        significant = words - remove_words
        return significant if significant else words

    words1 = normalize(name1)
    words2 = normalize(name2)

    if not words1 or not words2:
        return name1.lower() == name2.lower()

    intersection = len(words1 & words2)
    union = len(words1 | words2)
    similarity = intersection / union if union > 0 else 0

    is_subset = words1.issubset(words2) or words2.issubset(words1)

    return similarity > 0.5 or is_subset


async def get_user_strength_history(user_id: str) -> dict:
    """
    Get user's strength history from ALL sources for workout generation.

    Combines data from:
    1. Completed workouts (ChromaDB) - actual workout performance
    2. Imported workout history (Supabase) - manual entries
    """
    strength_history = {}

    # SOURCE 1: Get from ChromaDB (completed workouts)
    try:
        from services.workout_feedback_rag_service import get_workout_feedback_rag_service
        feedback_rag = get_workout_feedback_rag_service()

        sessions = await feedback_rag.find_similar_exercise_sessions(
            exercise_name="",
            user_id=user_id,
            n_results=50,
        )

        for session in sessions:
            exercises = session.get("metadata", {}).get("exercises", [])
            for ex in exercises:
                name = ex.get("name", "")
                weight = ex.get("weight_kg", 0)
                reps = ex.get("reps", 0)

                if not name or weight <= 0:
                    continue

                if name not in strength_history:
                    strength_history[name] = {
                        "last_weight_kg": weight,
                        "max_weight_kg": weight,
                        "last_reps": reps,
                        "session_count": 1,
                        "source": "completed",
                    }
                else:
                    if weight > strength_history[name]["max_weight_kg"]:
                        strength_history[name]["max_weight_kg"] = weight
                    strength_history[name]["session_count"] += 1

        logger.info(f"Found {len(strength_history)} exercises from completed workouts")

    except Exception as e:
        logger.warning(f"Error getting ChromaDB strength history: {e}")

    # SOURCE 2: Get from imported workout history (Supabase)
    try:
        db = get_supabase_db()

        result = db.client.table("workout_history_imports") \
            .select("exercise_name, weight_kg, reps, performed_at") \
            .eq("user_id", user_id) \
            .order("performed_at", desc=True) \
            .limit(200) \
            .execute()

        imported_count = 0
        for row in result.data or []:
            name = row.get("exercise_name", "")
            weight = float(row.get("weight_kg", 0))
            reps = row.get("reps", 0)

            if not name or weight <= 0:
                continue

            matched_name = None
            for existing_name in strength_history.keys():
                if existing_name.lower() == name.lower() or fuzzy_exercise_match(existing_name, name):
                    matched_name = existing_name
                    break

            if matched_name:
                if weight > strength_history[matched_name]["max_weight_kg"]:
                    strength_history[matched_name]["max_weight_kg"] = weight
                strength_history[matched_name]["session_count"] += 1
                strength_history[matched_name]["source"] = "both"
            else:
                strength_history[name] = {
                    "last_weight_kg": weight,
                    "max_weight_kg": weight,
                    "last_reps": reps,
                    "session_count": 1,
                    "source": "imported",
                }
                imported_count += 1

        logger.info(f"Added {imported_count} exercises from imported history")

    except Exception as e:
        logger.warning(f"Error getting imported strength history: {e}")

    logger.info(f"Total strength history: {len(strength_history)} exercises for user {user_id}")
    return strength_history


async def get_user_personal_bests(user_id: str) -> Dict[str, Dict]:
    """Get user's personal records (PRs) per exercise from the personal_records table."""
    prs: Dict[str, Dict] = {}

    try:
        db = get_supabase_db()

        result = db.client.table("personal_records").select(
            "exercise_name, record_type, record_value, achieved_at"
        ).eq("user_id", user_id).order("achieved_at", desc=True).execute()

        for row in result.data or []:
            name = row.get("exercise_name")
            record_type = row.get("record_type")
            value = row.get("record_value")

            if not name or value is None:
                continue

            if name not in prs:
                prs[name] = {}

            prs[name][record_type] = value

            achieved_at = row.get("achieved_at", "")
            if achieved_at and "achieved_at" not in prs[name]:
                prs[name]["achieved_at"] = str(achieved_at)[:10]

        logger.info(f"Found PRs for {len(prs)} exercises for user {user_id}")

    except Exception as e:
        logger.debug(f"Could not get personal bests (may not exist yet): {e}")

    return prs


def format_performance_context(
    exercises: List[Dict],
    strength_history: Dict[str, Dict],
    personal_bests: Dict[str, Dict],
) -> str:
    """
    Format last session + PR data for selected exercises into Gemini context.
    """
    if not exercises:
        return ""

    lines = []

    for ex in exercises:
        name = ex.get("name", "") if isinstance(ex, dict) else str(ex)
        if not name:
            continue

        parts = []

        hist = strength_history.get(name) or {}
        last_weight = hist.get("last_weight_kg", 0)
        last_reps = hist.get("last_reps", 0)
        max_weight = hist.get("max_weight_kg", 0)
        session_count = hist.get("session_count", 0)

        if last_weight > 0:
            if last_reps > 0:
                parts.append(f"Last: {last_weight}kg x {last_reps} reps")
            else:
                parts.append(f"Last: {last_weight}kg")

        pr = personal_bests.get(name) or {}
        pr_weight = pr.get("weight", 0)
        pr_1rm = pr.get("1rm", 0)

        if pr_weight and pr_weight > 0:
            parts.append(f"PR: {pr_weight}kg")
        elif pr_1rm and pr_1rm > 0:
            parts.append(f"1RM: {pr_1rm}kg")
        elif max_weight > 0 and max_weight > last_weight:
            parts.append(f"Max: {max_weight}kg")

        if last_weight > 0:
            name_lower = name.lower()
            if any(kw in name_lower for kw in ["barbell", "squat", "bench press", "deadlift", "overhead press"]):
                increment = 2.5
            else:
                increment = 2.0

            suggested_weight = round(last_weight + increment, 1)
            if last_reps and last_reps < 6:
                parts.append(f"Suggest: {last_weight}kg x {last_reps + 1} reps (add reps)")
            elif session_count and session_count >= 3 and max_weight and last_weight >= max_weight:
                parts.append(f"Suggest: {last_weight}kg x {(last_reps or 8) + 2} reps (plateau - add reps)")
            else:
                parts.append(f"Suggest: {suggested_weight}kg x {last_reps or 8} reps")

        if parts:
            lines.append(f"- {name}: {' | '.join(parts)}")

    if not lines:
        return ""

    return "Performance history for selected exercises:\n" + "\n".join(lines)


async def get_user_favorite_exercises(user_id: str) -> List[str]:
    """Get user's favorite exercise names from the database."""
    try:
        db = get_supabase_db()

        response = db.client.table("favorite_exercises").select(
            "exercise_name"
        ).eq("user_id", user_id).execute()

        if not response.data:
            return []

        favorites = [row["exercise_name"] for row in response.data]
        logger.info(f"Found {len(favorites)} favorite exercises for user {user_id}")
        return favorites

    except Exception as e:
        logger.debug(f"Could not get favorite exercises (table may not exist): {e}")
        return []


async def get_user_consistency_mode(user_id: str) -> str:
    """Get user's exercise consistency preference: 'vary' or 'consistent'."""
    try:
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            return "vary"

        preferences = user.get("preferences", {})
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        consistency_mode = preferences.get("exercise_consistency", "vary")

        if consistency_mode not in ["vary", "consistent"]:
            consistency_mode = "vary"

        logger.debug(f"User {user_id} exercise_consistency mode: {consistency_mode}")
        return consistency_mode

    except Exception as e:
        logger.error(f"Error getting consistency mode: {e}")
        return "vary"


async def get_user_exercise_queue(user_id: str, focus_area: str = None) -> List[dict]:
    """Get user's queued exercises for workout generation."""
    try:
        db = get_supabase_db()
        now = datetime.now().isoformat()

        query = db.client.table("exercise_queue").select(
            "id", "exercise_name", "exercise_id", "priority", "target_muscle_group"
        ).eq("user_id", user_id).is_("used_at", "null").gte("expires_at", now)

        result = query.order("priority", desc=False).execute()

        if not result.data:
            return []

        queued = []
        for row in result.data:
            target = row.get("target_muscle_group", "").lower() if row.get("target_muscle_group") else ""

            if focus_area:
                focus_lower = focus_area.lower()
                if target and target not in focus_lower and focus_lower not in target:
                    continue

            queued.append({
                "queue_id": row["id"],
                "name": row["exercise_name"],
                "exercise_id": row.get("exercise_id"),
                "priority": row.get("priority", 0),
                "target_muscle_group": row.get("target_muscle_group"),
            })

        logger.info(f"Found {len(queued)} queued exercises for user {user_id} (focus: {focus_area})")
        return queued

    except Exception as e:
        logger.debug(f"Could not get exercise queue (table may not exist): {e}")
        return []


async def mark_queued_exercises_used(user_id: str, exercise_names: List[str]):
    """Mark queued exercises as used after they've been included in a workout."""
    if not exercise_names:
        return

    try:
        db = get_supabase_db()
        now = datetime.now().isoformat()

        for name in exercise_names:
            db.client.table("exercise_queue").update({
                "used_at": now
            }).eq("user_id", user_id).eq("exercise_name", name).is_("used_at", "null").execute()

        logger.info(f"Marked {len(exercise_names)} queued exercises as used for user {user_id}")

    except Exception as e:
        logger.warning(f"Could not mark queued exercises as used: {e}")


async def get_user_staple_exercises(user_id: str, gym_profile_id: Optional[str] = None, scheduled_date: Optional[str] = None) -> List[dict]:
    """Get user's staple exercises with reasons from the database."""
    try:
        db = get_supabase_db()

        query = db.client.table("user_staples_with_details").select(
            "exercise_name, reason, muscle_group, gym_profile_id, equipment, target_days"
        ).eq("user_id", user_id)

        if gym_profile_id:
            query = query.or_(f"gym_profile_id.eq.{gym_profile_id},gym_profile_id.is.null")

        result = query.execute()

        if not result.data:
            return []

        staples = [
            {
                "name": row["exercise_name"],
                "reason": row.get("reason", "favorite"),
                "muscle_group": row.get("muscle_group"),
                "gym_profile_id": row.get("gym_profile_id"),
                "equipment": row.get("equipment"),
                "target_days": row.get("target_days"),
            }
            for row in result.data
        ]

        # Filter by day-of-week if scheduled_date is provided
        if scheduled_date:
            try:
                from datetime import datetime as dt
                parsed_date = dt.strptime(scheduled_date[:10], "%Y-%m-%d")
                day_of_week = parsed_date.weekday()

                filtered = []
                for s in staples:
                    td = s.get("target_days")
                    if td is None:
                        filtered.append(s)
                    elif day_of_week in td:
                        filtered.append(s)
                    else:
                        logger.info(f"Skipping staple '{s['name']}' — target_days {td} doesn't include day {day_of_week}")

                logger.info(f"Filtered staples by day {day_of_week}: {len(staples)} → {len(filtered)}")
                staples = filtered
            except (ValueError, TypeError) as e:
                logger.warning(f"Could not parse scheduled_date '{scheduled_date}' for day filtering: {e}")

        logger.info(f"Found {len(staples)} staple exercises for user {user_id} (profile: {gym_profile_id or 'all'}): {[s['name'] for s in staples]}")
        return staples

    except Exception as e:
        logger.debug(f"Could not get staple exercises (table may not exist): {e}")
        return []


def get_staple_names(staples: List[dict]) -> List[str]:
    """Extract just the exercise names from staple exercises list."""
    return [s["name"] for s in staples] if staples else []


async def get_user_variation_percentage(user_id: str) -> int:
    """Get user's exercise variation percentage setting (0-100, default 30)."""
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "variation_percentage"
        ).eq("id", user_id).execute()

        if not result.data:
            return 30

        percentage = result.data[0].get("variation_percentage", 30)

        if percentage is None or percentage < 0:
            percentage = 30
        elif percentage > 100:
            percentage = 100

        logger.debug(f"User {user_id} variation_percentage: {percentage}%")
        return percentage

    except Exception as e:
        logger.error(f"Error getting variation percentage: {e}")
        return 30


async def get_user_1rm_data(user_id: str) -> dict:
    """Get user's stored 1RMs for percentage-based training."""
    try:
        db = get_supabase_db()

        result = db.client.table("user_exercise_1rms").select(
            "exercise_name, one_rep_max_kg, source, confidence"
        ).eq("user_id", user_id).execute()

        if not result.data:
            return {}

        one_rm_data = {}
        for row in result.data:
            exercise_name = row.get("exercise_name", "").lower()
            if exercise_name:
                one_rm_data[exercise_name] = {
                    "one_rep_max_kg": float(row.get("one_rep_max_kg", 0)),
                    "source": row.get("source", "manual"),
                    "confidence": float(row.get("confidence", 1.0)),
                }

        logger.info(f"Loaded {len(one_rm_data)} 1RMs for user {user_id}")
        return one_rm_data

    except Exception as e:
        logger.debug(f"Could not get user 1RMs (table may not exist): {e}")
        return {}


async def get_user_training_intensity(user_id: str) -> int:
    """Get user's global training intensity preference (50-100, default 75)."""
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "training_intensity_percent"
        ).eq("id", user_id).execute()

        if not result.data:
            return 75

        intensity = result.data[0].get("training_intensity_percent", 75)

        if intensity is None or intensity < 50:
            intensity = 75
        elif intensity > 100:
            intensity = 100

        logger.debug(f"User {user_id} training_intensity: {intensity}%")
        return intensity

    except Exception as e:
        logger.debug(f"Error getting training intensity: {e}")
        return 75


async def get_user_intensity_overrides(user_id: str) -> dict:
    """Get user's per-exercise intensity overrides."""
    try:
        db = get_supabase_db()

        result = db.client.table("exercise_intensity_overrides").select(
            "exercise_name, intensity_percent"
        ).eq("user_id", user_id).execute()

        if not result.data:
            return {}

        overrides = {}
        for row in result.data:
            exercise_name = row.get("exercise_name", "").lower()
            if exercise_name:
                overrides[exercise_name] = row.get("intensity_percent", 75)

        logger.debug(f"User {user_id} has {len(overrides)} intensity overrides")
        return overrides

    except Exception as e:
        logger.debug(f"Could not get intensity overrides: {e}")
        return {}


def calculate_working_weight_from_1rm(
    one_rep_max_kg: float,
    intensity_percent: int,
    equipment_type: str = 'barbell',
) -> float:
    """Calculate working weight from 1RM and intensity percentage."""
    WEIGHT_INCREMENTS = {
        'barbell': 2.5,
        'dumbbell': 2.0,
        'machine': 5.0,
        'cable': 2.5,
        'kettlebell': 4.0,
        'bodyweight': 0,
    }

    if intensity_percent < 50:
        intensity_percent = 50
    elif intensity_percent > 100:
        intensity_percent = 100

    raw_weight = one_rep_max_kg * (intensity_percent / 100)

    increment = WEIGHT_INCREMENTS.get(equipment_type, 2.5)
    if increment > 0:
        rounded_weight = round(raw_weight / increment) * increment
    else:
        rounded_weight = raw_weight

    return round(rounded_weight, 1)


def apply_1rm_weights_to_exercises(
    exercises: List[dict],
    one_rm_data: dict,
    global_intensity: int,
    intensity_overrides: dict = None,
) -> List[dict]:
    """Apply 1RM-based weights to exercises that have known maxes."""
    if not one_rm_data:
        return exercises

    intensity_overrides = intensity_overrides or {}
    updated_exercises = []

    for exercise in exercises:
        exercise_copy = dict(exercise)
        exercise_name = (exercise.get("name") or "").lower()

        matched_1rm = None
        matched_name = None

        if exercise_name in one_rm_data:
            matched_1rm = one_rm_data[exercise_name]
            matched_name = exercise_name
        else:
            for rm_name, rm_data in one_rm_data.items():
                if fuzzy_exercise_match(exercise_name, rm_name):
                    matched_1rm = rm_data
                    matched_name = rm_name
                    break

        if matched_1rm:
            one_rep_max_kg = matched_1rm.get("one_rep_max_kg", 0)
            if one_rep_max_kg > 0:
                intensity = intensity_overrides.get(
                    exercise_name,
                    intensity_overrides.get(matched_name, global_intensity)
                )

                equipment = (exercise.get("equipment") or "barbell").lower()
                if "dumbbell" in equipment:
                    equipment_type = "dumbbell"
                elif "cable" in equipment:
                    equipment_type = "cable"
                elif "machine" in equipment:
                    equipment_type = "machine"
                elif "kettlebell" in equipment:
                    equipment_type = "kettlebell"
                elif "bodyweight" in equipment or "body" in equipment:
                    equipment_type = "bodyweight"
                else:
                    equipment_type = "barbell"

                working_weight = calculate_working_weight_from_1rm(
                    one_rep_max_kg, intensity, equipment_type
                )

                exercise_copy["weight"] = working_weight
                exercise_copy["weight_source"] = "1rm_calculated"
                exercise_copy["one_rep_max_kg"] = one_rep_max_kg
                exercise_copy["intensity_percent"] = intensity

                if "set_targets" in exercise_copy and exercise_copy["set_targets"]:
                    for set_target in exercise_copy["set_targets"]:
                        if not isinstance(set_target, dict):
                            continue
                        set_type = set_target.get("set_type", "working")
                        if set_type == "warmup":
                            set_target["target_weight_kg"] = round(working_weight * 0.5, 1)
                        elif set_type == "drop":
                            set_target["target_weight_kg"] = round(working_weight * 0.8, 1)
                        else:
                            set_target["target_weight_kg"] = working_weight
                    logger.debug(f"Updated {len(exercise_copy['set_targets'])} set_targets with 1RM-based weights")

                logger.debug(
                    f"Applied 1RM weight: {exercise_name} - "
                    f"1RM: {one_rep_max_kg}kg @ {intensity}% = {working_weight}kg"
                )

        updated_exercises.append(exercise_copy)

    applied_count = sum(1 for e in updated_exercises if e.get("weight_source") == "1rm_calculated")
    if applied_count > 0:
        logger.info(f"Applied 1RM-based weights to {applied_count}/{len(exercises)} exercises")

    return updated_exercises


async def get_user_avoided_exercises(user_id: str) -> List[str]:
    """Get list of exercise names the user wants to avoid."""
    try:
        db = get_supabase_db()

        result = db.client.rpc(
            "get_active_avoided_exercises",
            {"p_user_id": user_id}
        ).execute()

        if not result.data:
            return []

        avoided = [row.get("exercise_name", "").lower() for row in result.data if row.get("exercise_name")]
        if avoided:
            logger.info(f"User {user_id} has {len(avoided)} avoided exercises: {avoided[:5]}...")
        return avoided

    except Exception as e:
        logger.debug(f"Could not get avoided exercises: {e}")
        return []


async def get_user_avoided_muscles(user_id: str) -> dict:
    """Get muscle groups the user wants to avoid or reduce."""
    try:
        db = get_supabase_db()

        result = db.client.rpc(
            "get_active_avoided_muscles",
            {"p_user_id": user_id}
        ).execute()

        if not result.data:
            return {"avoid": [], "reduce": []}

        avoid_list = []
        reduce_list = []

        for row in result.data:
            muscle = row.get("muscle_group", "").lower()
            severity = row.get("severity", "avoid")

            if muscle:
                if severity == "avoid":
                    avoid_list.append(muscle)
                elif severity == "reduce":
                    reduce_list.append(muscle)

        if avoid_list or reduce_list:
            logger.info(f"User {user_id} avoided muscles - avoid: {avoid_list}, reduce: {reduce_list}")

        return {"avoid": avoid_list, "reduce": reduce_list}

    except Exception as e:
        logger.debug(f"Could not get avoided muscles: {e}")
        return {"avoid": [], "reduce": []}


async def get_user_progression_pace(user_id: str) -> str:
    """Get user's progression pace preference: 'slow', 'medium', or 'fast'."""
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "preferences"
        ).eq("id", user_id).execute()

        if not result.data:
            return "medium"

        preferences = result.data[0].get("preferences") or {}
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        pace = preferences.get("progression_pace", "medium")

        valid_paces = ["slow", "medium", "fast"]
        if pace not in valid_paces:
            pace = "medium"

        logger.debug(f"User {user_id} progression_pace: {pace}")
        return pace

    except Exception as e:
        logger.debug(f"Could not get progression pace: {e}")
        return "medium"


async def get_user_workout_type_preference(user_id: str) -> str:
    """Get user's workout type preference: 'strength', 'cardio', 'mixed', 'mobility', or 'recovery'."""
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "preferences"
        ).eq("id", user_id).execute()

        if not result.data:
            return "strength"

        preferences = result.data[0].get("preferences") or {}
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        workout_type = preferences.get("workout_type_preference", "strength")

        valid_types = ["strength", "cardio", "mixed", "mobility", "recovery"]
        if workout_type not in valid_types:
            workout_type = "strength"

        logger.debug(f"User {user_id} workout_type_preference: {workout_type}")
        return workout_type

    except Exception as e:
        logger.debug(f"Could not get workout type preference: {e}")
        return "strength"


async def get_substitute_exercise(
    exercise_name: str,
    muscle_group: str,
    user_id: str,
    avoided_exercises: List[str],
    equipment: List[str] = None,
) -> Optional[dict]:
    """Find a substitute for an exercise that was filtered out due to user preferences."""
    try:
        db = get_supabase_db()

        avoided_lower = [ae.lower() for ae in avoided_exercises]

        muscles = [" ".join(m.split()) for m in muscle_group.split(",") if m.strip()] if muscle_group else []
        if muscles:
            conditions = ",".join(
                f"target_muscle.ilike.%{m}%,body_part.ilike.%{m}%"
                for m in muscles
            )
            query = db.client.table("exercise_library_cleaned").select(
                "name, target_muscle, body_part, equipment, secondary_muscles"
            ).or_(conditions).limit(50)
        else:
            query = db.client.table("exercise_library_cleaned").select(
                "name, target_muscle, body_part, equipment, secondary_muscles"
            ).limit(50)

        result = query.execute()

        if not result.data:
            logger.debug(f"No exercises found for muscle group: {muscle_group}")
            return None

        candidates = []
        original_lower = exercise_name.lower()

        for ex in result.data:
            ex_name = ex.get("name", "")
            if ex_name.lower() == original_lower:
                continue
            if ex_name.lower() in avoided_lower:
                continue

            score = 0
            ex_equipment = (ex.get("equipment") or "").lower()

            if equipment:
                equipment_lower = [e.lower() for e in equipment]
                _bw_aliases = {"bodyweight", "none", "no_equipment", ""}
                has_real_equipment = any(eq not in _bw_aliases for eq in equipment_lower)

                if ex_equipment in equipment_lower:
                    score += 20
                elif has_real_equipment and ex_equipment not in ("body weight", "bodyweight", "none", ""):
                    score += 15
                elif ex_equipment in ("body weight", "bodyweight"):
                    score += 5 if has_real_equipment else 10
            else:
                if ex_equipment == "body weight":
                    score += 5

            candidates.append((score, ex))

        # Hard equipment filter
        if equipment:
            compatible_candidates = []
            for score, ex in candidates:
                ex_equip = (ex.get("equipment") or "").strip()
                ex_name = ex.get("name", "")
                if not ex_equip or ex_equip.lower() in ("bodyweight", "body weight", "none", ""):
                    ex_equip = infer_equipment_from_name(ex_name)
                if filter_by_equipment(ex_equip, equipment, ex_name):
                    compatible_candidates.append((score, ex))
            if compatible_candidates:
                candidates = compatible_candidates
            else:
                logger.debug(f"No equipment-compatible substitutes for {exercise_name}, using best scored")

        if not candidates:
            logger.debug(f"No valid substitutes found for {exercise_name} (muscle: {muscle_group})")
            return None

        candidates.sort(key=lambda x: x[0], reverse=True)
        best_match = candidates[0][1]

        logger.info(f"🔄 [Auto-Substitute] Replaced '{exercise_name}' with '{best_match.get('name')}'")

        return {
            "name": best_match.get("name"),
            "muscle_group": best_match.get("target_muscle") or best_match.get("body_part"),
            "equipment": best_match.get("equipment"),
            "sets": 3,
            "reps": "10",
            "substituted_for": exercise_name,
        }

    except Exception as e:
        logger.debug(f"Could not find substitute for {exercise_name}: {e}")
        return None


async def auto_substitute_filtered_exercises(
    exercises: List[dict],
    filtered_exercises: List[dict],
    user_id: str,
    avoided_exercises: List[str],
    equipment: List[str] = None,
) -> List[dict]:
    """Automatically find substitutes for exercises that were filtered out."""
    substitutes_added = 0
    existing_names = {ex.get("name", "").lower() for ex in exercises}

    for filtered_ex in filtered_exercises:
        ex_name = filtered_ex.get("name", "")
        muscle_group = filtered_ex.get("muscle_group", "")

        if not muscle_group:
            muscle_group = filtered_ex.get("body_part") or filtered_ex.get("primary_muscle", "")

        if muscle_group:
            substitute = await get_substitute_exercise(
                exercise_name=ex_name,
                muscle_group=muscle_group,
                user_id=user_id,
                avoided_exercises=avoided_exercises,
                equipment=equipment,
            )

            if substitute and substitute.get("name", "").lower() not in existing_names:
                substitute["sets"] = filtered_ex.get("sets", 3)
                substitute["reps"] = filtered_ex.get("reps", "10")
                substitute["rest_seconds"] = filtered_ex.get("rest_seconds", 60)

                exercises.append(substitute)
                existing_names.add(substitute.get("name", "").lower())
                substitutes_added += 1

    if substitutes_added > 0:
        logger.info(f"✅ [Auto-Substitute] Added {substitutes_added} substitute exercises")

    return exercises
