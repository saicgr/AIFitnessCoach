"""
Rule-Based Exercise Preference Engine.

Handles instant exercise swaps/injections/removals when users change exercise preferences
(staple, avoid exercise, avoid muscle). No AI regeneration needed — all changes are
applied directly to existing workout exercises_json.

Core principle: Parse JSON → find target → replace with library match → update row.
"""
import re
import json
import random
import logging
from datetime import date, datetime, timedelta
from typing import Optional

# Day-of-week constants (Python weekday(): 0=Monday, 6=Sunday)
DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

from core.supabase_db import get_supabase_db

logger = logging.getLogger(__name__)


# =============================================================================
# Exercise Type Detection
# =============================================================================

TIMED_KEYWORDS = [
    "hold", "plank", "hang", "isometric", "static",
    "dead hang", "wall sit", "l-sit", "hollow",
]
CARDIO_EQUIPMENT = {
    "treadmill", "elliptical", "stationary bike",
    "rowing machine", "bike", "rower",
}

# Push/Pull/Legs compatibility for smart muscle replacement
MUSCLE_COMPATIBILITY = {
    "chest": ["shoulders", "triceps"],
    "shoulders": ["chest", "triceps"],
    "triceps": ["chest", "shoulders"],
    "back": ["biceps", "rear delts"],
    "lats": ["biceps", "rear delts"],
    "biceps": ["back", "forearms"],
    "quads": ["hamstrings", "glutes", "calves"],
    "quadriceps": ["hamstrings", "glutes", "calves"],
    "hamstrings": ["glutes", "quads", "quadriceps", "calves"],
    "glutes": ["hamstrings", "quads", "quadriceps"],
    "calves": ["quads", "quadriceps", "hamstrings"],
    "abs": ["obliques", "lower back", "core"],
    "obliques": ["abs", "lower back", "core"],
    "core": ["abs", "obliques"],
    "lower back": ["abs", "obliques", "core"],
    "traps": ["shoulders", "back"],
    "forearms": ["biceps", "back"],
    "adductors": ["abductors", "glutes"],
    "abductors": ["adductors", "glutes"],
}

# Normalize muscle name variations
MUSCLE_ALIASES = {
    "pectoralis major": "chest",
    "pectoralis minor": "chest",
    "pecs": "chest",
    "deltoids": "shoulders",
    "delts": "shoulders",
    "rear delts": "shoulders",
    "anterior deltoid": "shoulders",
    "lateral deltoid": "shoulders",
    "posterior deltoid": "shoulders",
    "latissimus dorsi": "back",
    "lats": "back",
    "trapezius": "traps",
    "rhomboids": "back",
    "erector spinae": "lower back",
    "rectus abdominis": "abs",
    "transverse abdominis": "core",
    "hip flexors": "quads",
    "quadriceps femoris": "quadriceps",
    "biceps femoris": "hamstrings",
    "gastrocnemius": "calves",
    "soleus": "calves",
    "gluteus maximus": "glutes",
    "gluteus medius": "glutes",
}


def _strip_parens(value: str | None) -> str | None:
    """Strip parenthetical details from muscle names (e.g., 'Chest (Pectoralis Major)' → 'Chest')."""
    if not value:
        return value
    return re.sub(r"\s*\(.*?\)", "", value).strip() or value


def _normalize_muscle(muscle: str | None) -> str | None:
    """Normalize muscle name to canonical form."""
    if not muscle:
        return None
    clean = _strip_parens(muscle).lower().strip()
    return MUSCLE_ALIASES.get(clean, clean)


def _is_timed_exercise(name: str, category: str | None = None) -> bool:
    """Check if exercise is timed (hold/isometric)."""
    name_lower = name.lower()
    cat_lower = (category or "").lower()
    return (
        any(kw in name_lower for kw in TIMED_KEYWORDS)
        or cat_lower in ("isometric", "static", "stretching")
    )


def _is_cardio_exercise(name: str, equipment: str | None = None, category: str | None = None) -> bool:
    """Check if exercise is cardio."""
    cat_lower = (category or "").lower()
    eq_lower = (equipment or "").lower()
    return cat_lower == "cardio" or eq_lower in CARDIO_EQUIPMENT


def get_exercise_params(
    exercise_name: str,
    library_data: dict,
    user_overrides: dict | None = None,
    exercise_history: dict | None = None,
    user_profile: dict | None = None,
) -> dict:
    """
    Return smart exercise parameters using a priority chain.

    Priority (highest → lowest):
    1. User-stored staple overrides (user_sets, user_reps, etc.)
    2. Exercise history (last weight/reps the user actually performed)
    3. Profile-aware calculation (fitness_level + primary_goal → intensity)
    4. Library defaults (default_duration_seconds, etc.)
    5. Smart type-based fallback
    """
    name_lower = exercise_name.lower()
    category = (library_data.get("category") or "").lower()
    equipment = (library_data.get("equipment") or "").lower()

    is_timed = _is_timed_exercise(name_lower, category)
    is_cardio = _is_cardio_exercise(name_lower, equipment, category)

    # === Layer 5: Type-based fallback defaults ===
    if is_cardio:
        params = {
            "is_timed": True, "duration_seconds": 300,
            "sets": 1, "reps": None, "rest_seconds": 0,
        }
    elif is_timed:
        params = {
            "is_timed": True, "sets": 3,
            "duration_seconds": 30, "reps": None, "rest_seconds": 30,
        }
    else:
        params = {
            "is_timed": False, "sets": 3,
            "reps": 10, "rest_seconds": 60, "duration_seconds": None,
        }

    # === Layer 4: Library defaults ===
    if library_data.get("default_duration_seconds"):
        params["duration_seconds"] = library_data["default_duration_seconds"]

    # === Layer 3: Profile-aware calculation ===
    if user_profile and not is_timed and not is_cardio:
        goal = user_profile.get("primary_goal", "muscle_hypertrophy")
        intensity = user_profile.get("intensity_preference", "moderate")
        if goal == "muscle_strength":
            params.update({"sets": 4, "reps": 5, "rest_seconds": 120})
        elif goal == "muscle_hypertrophy":
            params.update({"sets": 3, "reps": 10, "rest_seconds": 60})
        elif goal == "strength_hypertrophy":
            params.update({"sets": 4, "reps": 8, "rest_seconds": 90})
        if intensity == "intense":
            params["sets"] = min(params["sets"] + 1, 5)
        elif intensity == "light":
            params["sets"] = max(params["sets"] - 1, 2)

    if user_profile and is_cardio:
        intensity = user_profile.get("intensity_preference", "moderate")
        if intensity == "light":
            params["duration_seconds"] = 300
        elif intensity == "moderate":
            params["duration_seconds"] = 600
        elif intensity == "intense":
            params["duration_seconds"] = 900

    # === Layer 2: Exercise history ===
    if exercise_history:
        hist = exercise_history.get(exercise_name.lower()) or exercise_history.get(exercise_name)
        if hist:
            if hist.get("last_weight_kg") and not is_timed:
                params["weight_kg"] = hist["last_weight_kg"]
            if hist.get("last_reps") and not is_timed:
                params["reps"] = hist["last_reps"]

    # === Layer 1: User staple overrides (highest priority) ===
    if user_overrides:
        if user_overrides.get("user_sets"):
            params["sets"] = user_overrides["user_sets"]
        if user_overrides.get("user_reps"):
            # Handle "8-12" range format — use first number
            reps_str = str(user_overrides["user_reps"])
            try:
                params["reps"] = int(reps_str.split("-")[0])
            except ValueError:
                pass
        if user_overrides.get("user_rest_seconds"):
            params["rest_seconds"] = user_overrides["user_rest_seconds"]
        if user_overrides.get("user_duration_seconds"):
            params["duration_seconds"] = user_overrides["user_duration_seconds"]
            params["is_timed"] = True
            params["reps"] = None
        for key in (
            "user_speed_mph", "user_incline_percent", "user_rpm",
            "user_resistance_level", "user_stroke_rate_spm",
        ):
            if user_overrides.get(key):
                params[key.replace("user_", "")] = user_overrides[key]

    return params


# =============================================================================
# Exercise Library Lookup
# =============================================================================

def _find_replacement_exercise(
    db,
    target_muscle: str,
    equipment_pref: str | None,
    excluded_names: set[str],
    avoided_exercises: set[str],
    avoided_muscles: set[str],
) -> dict | None:
    """
    Find a replacement exercise from the library.

    Scoring: same target_muscle +2, same equipment +1, random jitter 0-0.5.
    Filters out excluded names, avoided exercises, and exercises targeting avoided muscles.
    """
    clean_muscle = _strip_parens(target_muscle)
    if not clean_muscle:
        return None

    try:
        query = db.client.table("exercise_library_cleaned") \
            .select("name, target_muscle, body_part, equipment, gif_url, secondary_muscles, category") \
            .ilike("target_muscle", f"%{clean_muscle}%") \
            .limit(50)
        result = query.execute()

        if not result.data:
            # Fallback: try body_part match
            query = db.client.table("exercise_library_cleaned") \
                .select("name, target_muscle, body_part, equipment, gif_url, secondary_muscles, category") \
                .ilike("body_part", f"%{clean_muscle}%") \
                .limit(50)
            result = query.execute()

        if not result.data:
            return None

        excluded_lower = {n.lower() for n in excluded_names}
        avoided_lower = {n.lower() for n in avoided_exercises}
        avoided_muscles_lower = {_normalize_muscle(m) for m in avoided_muscles}

        candidates = []
        for ex in result.data:
            name_lower = ex["name"].lower()
            if name_lower in excluded_lower or name_lower in avoided_lower:
                continue

            # Check that this exercise doesn't target an avoided muscle
            ex_target = _normalize_muscle(ex.get("target_muscle"))
            if ex_target and ex_target in avoided_muscles_lower:
                continue

            # Check secondary muscles too
            secondary = ex.get("secondary_muscles") or ""
            if isinstance(secondary, str):
                sec_list = [s.strip().lower() for s in secondary.split(",") if s.strip()]
            else:
                sec_list = [str(s).lower() for s in secondary]
            if any(_normalize_muscle(s) in avoided_muscles_lower for s in sec_list):
                continue

            # Score
            score = 0.0
            ex_muscle = _strip_parens(ex.get("target_muscle") or "")
            if clean_muscle.lower() in (ex_muscle or "").lower():
                score += 2.0
            ex_eq = (ex.get("equipment") or "").lower()
            if equipment_pref and equipment_pref.lower() == ex_eq:
                score += 1.0
            score += random.uniform(0, 0.5)

            candidates.append({**ex, "_score": score})

        if not candidates:
            return None

        candidates.sort(key=lambda x: x["_score"], reverse=True)
        best = candidates[0]
        best.pop("_score", None)
        return best

    except Exception as e:
        logger.error(f"Error finding replacement exercise: {e}")
        return None


def _find_compatible_replacement(
    db,
    avoided_muscle: str,
    equipment_pref: str | None,
    excluded_names: set[str],
    avoided_exercises: set[str],
    avoided_muscles: set[str],
) -> dict | None:
    """Find a replacement exercise from a compatible muscle group."""
    normalized = _normalize_muscle(avoided_muscle)
    compatible = MUSCLE_COMPATIBILITY.get(normalized, [])

    for compat_muscle in compatible:
        replacement = _find_replacement_exercise(
            db, compat_muscle, equipment_pref,
            excluded_names, avoided_exercises, avoided_muscles,
        )
        if replacement:
            return replacement

    return None


def _build_exercise_object(
    exercise_name: str,
    library_data: dict,
    params: dict,
    order: int = 1,
) -> dict:
    """Build an exercise JSON object for insertion into exercises_json."""
    obj = {
        "name": exercise_name,
        "muscle_group": _strip_parens(library_data.get("target_muscle")) or library_data.get("body_part"),
        "equipment": library_data.get("equipment"),
        "gif_url": library_data.get("gif_url"),
        "order": order,
        "sets": params.get("sets", 3),
        "rest_seconds": params.get("rest_seconds", 60),
    }

    if params.get("is_timed"):
        obj["is_timed"] = True
        obj["duration_seconds"] = params.get("duration_seconds", 30)
        # Don't set reps for timed exercises
    else:
        obj["reps"] = params.get("reps", 10)
        if params.get("weight_kg"):
            obj["weight_kg"] = params["weight_kg"]

    # Cardio params
    for key in ("speed_mph", "incline_percent", "rpm", "resistance_level", "stroke_rate_spm"):
        if params.get(key):
            obj[key] = params[key]

    return obj


# =============================================================================
# Shared Data Fetching (done ONCE per preference change, reused across all modifications)
# =============================================================================

async def _fetch_preference_context(db, user_id: str) -> dict:
    """Fetch all context needed for preference changes in one batch."""
    context = {
        "user_profile": None,
        "exercise_history": {},
        "staples": [],
        "avoided_exercises": set(),
        "avoided_muscles": set(),
        "workout_days": [],  # User's scheduled workout days (0=Mon, 6=Sun)
    }

    try:
        # User profile + preferences (for workout_days)
        profile_result = db.client.table("users").select(
            "fitness_level, primary_goal, intensity_preference, "
            "progression_pace, equipment_details, preferences"
        ).eq("id", user_id).single().execute()
        context["user_profile"] = profile_result.data

        # Extract workout_days from preferences JSON
        prefs = profile_result.data.get("preferences") if profile_result.data else None
        if prefs:
            import json as _json
            if isinstance(prefs, str):
                try:
                    prefs = _json.loads(prefs)
                except (ValueError, TypeError):
                    prefs = {}
            if isinstance(prefs, dict):
                wd = prefs.get("workout_days") or prefs.get("selected_days") or []
                if isinstance(wd, list):
                    context["workout_days"] = [int(d) for d in wd if isinstance(d, (int, float))]
    except Exception as e:
        logger.warning(f"Could not fetch user profile: {e}")

    try:
        # Exercise history
        from api.v1.workouts.utils import get_user_strength_history
        context["exercise_history"] = await get_user_strength_history(user_id)
    except Exception as e:
        logger.warning(f"Could not fetch exercise history: {e}")

    try:
        # Staples (for knowing which exercises are staples — don't replace them)
        staples_result = db.client.table("user_staples_with_details").select("*").eq("user_id", user_id).execute()
        context["staples"] = staples_result.data or []
    except Exception as e:
        logger.warning(f"Could not fetch staples: {e}")

    try:
        # Avoided exercises
        avoided_result = db.client.table("avoided_exercises").select("exercise_name").eq("user_id", user_id).execute()
        context["avoided_exercises"] = {r["exercise_name"].lower() for r in (avoided_result.data or [])}
    except Exception as e:
        logger.warning(f"Could not fetch avoided exercises: {e}")

    try:
        # Avoided muscles
        muscles_result = db.client.table("avoided_muscles").select("muscle_group, severity").eq("user_id", user_id).execute()
        context["avoided_muscles"] = {r["muscle_group"].lower() for r in (muscles_result.data or [])}
    except Exception as e:
        logger.warning(f"Could not fetch avoided muscles: {e}")

    return context


def _get_upcoming_workouts(db, user_id: str) -> list[dict]:
    """Get all upcoming incomplete workouts (tomorrow+)."""
    tomorrow_str = (date.today()).isoformat()
    try:
        result = db.client.table("workouts").select(
            "id, scheduled_date, exercises_json, workout_name, status, is_completed, gym_profile_id"
        ).eq(
            "user_id", user_id
        ).gt(
            "scheduled_date", tomorrow_str
        ).eq(
            "is_completed", False
        ).neq(
            "status", "generating"
        ).order("scheduled_date").execute()
        return result.data or []
    except Exception as e:
        logger.error(f"Error fetching upcoming workouts: {e}")
        return []


def _log_workout_change(db, user_id: str, workout_id: str, change_type: str, details: dict):
    """Log a change to the workout_changes audit table."""
    try:
        db.client.table("workout_changes").insert({
            "user_id": user_id,
            "workout_id": workout_id,
            "change_type": change_type,
            "details": json.dumps(details),
            "created_at": datetime.utcnow().isoformat(),
        }).execute()
    except Exception as e:
        logger.warning(f"Could not log workout change: {e}")


def _validate_equipment(exercise_equipment: str | None, user_equipment: list | None) -> bool:
    """Check if user has the required equipment for an exercise."""
    if not exercise_equipment or not user_equipment:
        return True  # No requirement or no profile = allow

    eq_lower = exercise_equipment.lower()
    if eq_lower in ("bodyweight", "body weight", "body only"):
        return True

    # Check if any user equipment matches
    user_eq_lower = [e.lower() for e in user_equipment]

    # Special expansions
    if "full_gym" in user_eq_lower or "commercial_gym" in user_eq_lower:
        return True

    return eq_lower in user_eq_lower


# =============================================================================
# Core Engine Functions
# =============================================================================

async def inject_staple_into_workout(
    db,
    workout: dict,
    staple: dict,
    context: dict,
    user_id: str,
) -> dict:
    """
    Inject a staple exercise into a workout.

    For section="main": modifies exercises_json
    For section="warmup": modifies warmups table
    For section="stretches": modifies stretches table

    Returns: {"action": "replaced"|"added"|"already_present"|"skipped", ...}
    """
    workout_id = workout["id"]
    staple_name = staple["exercise_name"]
    staple_section = staple.get("section", "main")
    staple_muscle = _normalize_muscle(staple.get("target_muscle") or staple.get("muscle_group"))

    # Equipment validation
    user_equipment = (context.get("user_profile") or {}).get("equipment_details")
    if isinstance(user_equipment, str):
        try:
            user_equipment = json.loads(user_equipment)
        except (json.JSONDecodeError, TypeError):
            user_equipment = None
    staple_equipment = staple.get("equipment")
    if not _validate_equipment(staple_equipment, user_equipment):
        return {
            "action": "skipped",
            "reason": f"{staple_name} requires {staple_equipment} — not in your gym profile",
            "workout_id": workout_id,
            "workout_date": workout.get("scheduled_date"),
        }

    if staple_section in ("warmup", "stretches"):
        return _inject_into_section(db, workout_id, staple, staple_section, context, user_id)

    # === Main section ===
    exercises = workout.get("exercises_json") or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (json.JSONDecodeError, TypeError):
            exercises = []

    # Check if already present
    existing_names_lower = {(ex.get("name") or "").lower() for ex in exercises}
    if staple_name.lower() in existing_names_lower:
        return {
            "action": "already_present",
            "workout_id": workout_id,
            "workout_date": workout.get("scheduled_date"),
        }

    # Check staple count — don't let >50% be injected staples
    staple_names_lower = {s["exercise_name"].lower() for s in context.get("staples", [])}
    staple_count = sum(1 for ex in exercises if (ex.get("name") or "").lower() in staple_names_lower)
    if len(exercises) > 0 and staple_count >= len(exercises) * 0.5:
        return {
            "action": "skipped",
            "reason": "Too many staple exercises already in this workout",
            "workout_id": workout_id,
            "workout_date": workout.get("scheduled_date"),
        }

    # Build exercise params
    params = get_exercise_params(
        staple_name,
        staple,  # library data comes from view
        user_overrides=staple,
        exercise_history=context.get("exercise_history"),
        user_profile=context.get("user_profile"),
    )

    # Look for same-muscle exercise to replace (but NOT another staple)
    replaced_name = None
    if staple_muscle:
        for i, ex in enumerate(exercises):
            ex_muscle = _normalize_muscle(ex.get("muscle_group") or ex.get("target_muscle"))
            ex_name_lower = (ex.get("name") or "").lower()
            if ex_muscle == staple_muscle and ex_name_lower not in staple_names_lower:
                replaced_name = ex.get("name")
                exercises[i] = _build_exercise_object(staple_name, staple, params, order=ex.get("order", i + 1))
                break

    if replaced_name is None:
        # Add as extra exercise
        new_order = max((ex.get("order", 0) for ex in exercises), default=0) + 1
        exercises.append(_build_exercise_object(staple_name, staple, params, order=new_order))

    # Update workout
    try:
        db.client.table("workouts").update({
            "exercises_json": exercises,
        }).eq("id", workout_id).execute()

        _log_workout_change(db, user_id, workout_id, "staple_inject", {
            "staple": staple_name,
            "replaced": replaced_name,
            "action": "replaced" if replaced_name else "added",
        })

        return {
            "action": "replaced" if replaced_name else "added",
            "old": replaced_name,
            "new": staple_name,
            "workout_id": workout_id,
            "workout_date": workout.get("scheduled_date"),
            "workout_name": workout.get("workout_name"),
        }
    except Exception as e:
        logger.error(f"Error updating workout {workout_id}: {e}")
        return {"action": "error", "reason": str(e), "workout_id": workout_id}


def _inject_into_section(
    db,
    workout_id: str,
    staple: dict,
    section: str,
    context: dict,
    user_id: str,
) -> dict:
    """Inject a staple into the warmups or stretches table."""
    table = "warmups" if section == "warmup" else "stretches"
    staple_name = staple["exercise_name"]

    try:
        result = db.client.table(table).select("id, exercises_json").eq("workout_id", workout_id).execute()
        row = result.data[0] if result.data else None

        exercises = []
        if row:
            exercises = row.get("exercises_json") or []
            if isinstance(exercises, str):
                try:
                    exercises = json.loads(exercises)
                except (json.JSONDecodeError, TypeError):
                    exercises = []

        # Check if already present
        existing_names_lower = {(ex.get("name") or "").lower() for ex in exercises}
        if staple_name.lower() in existing_names_lower:
            return {
                "action": "already_present",
                "workout_id": workout_id,
                "section": section,
            }

        # Build exercise params (warmup/stretch uses duration primarily)
        params = get_exercise_params(
            staple_name, staple,
            user_overrides=staple,
            exercise_history=context.get("exercise_history"),
            user_profile=context.get("user_profile"),
        )
        if section == "stretches":
            params["rest_seconds"] = 0

        new_order = max((ex.get("order", 0) for ex in exercises), default=0) + 1
        exercises.append(_build_exercise_object(staple_name, staple, params, order=new_order))

        if row:
            db.client.table(table).update({"exercises_json": exercises}).eq("id", row["id"]).execute()
        else:
            db.client.table(table).insert({
                "workout_id": workout_id,
                "exercises_json": exercises,
            }).execute()

        return {
            "action": f"added_{section}",
            "new": staple_name,
            "workout_id": workout_id,
            "section": section,
        }
    except Exception as e:
        logger.error(f"Error injecting into {table}: {e}")
        return {"action": "error", "reason": str(e)}


async def remove_exercise_from_workout(
    db,
    workout: dict,
    exercise_name: str,
    context: dict,
    user_id: str,
) -> dict:
    """
    Replace an avoided exercise in a workout with a suitable alternative.

    Returns: {"action": "replaced"|"removed", "old": name, "new": name}
    """
    workout_id = workout["id"]
    exercises = workout.get("exercises_json") or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (json.JSONDecodeError, TypeError):
            exercises = []

    # Find the exercise (case-insensitive)
    target_idx = None
    for i, ex in enumerate(exercises):
        if (ex.get("name") or "").lower() == exercise_name.lower():
            target_idx = i
            break

    if target_idx is None:
        return {"action": "not_found", "workout_id": workout_id}

    old_exercise = exercises[target_idx]
    old_muscle = _strip_parens(old_exercise.get("muscle_group") or old_exercise.get("target_muscle"))
    old_equipment = old_exercise.get("equipment")
    old_order = old_exercise.get("order", target_idx + 1)

    # Get names already in workout (to avoid duplicates)
    excluded = {(ex.get("name") or "").lower() for ex in exercises}
    excluded.add(exercise_name.lower())

    # Find replacement with same muscle
    replacement = _find_replacement_exercise(
        db, old_muscle or "compound", old_equipment,
        excluded, context["avoided_exercises"], context["avoided_muscles"],
    )

    if replacement:
        params = get_exercise_params(
            replacement["name"], replacement,
            exercise_history=context.get("exercise_history"),
            user_profile=context.get("user_profile"),
        )
        exercises[target_idx] = _build_exercise_object(
            replacement["name"], replacement, params, order=old_order,
        )
        new_name = replacement["name"]
    else:
        # No replacement found — remove exercise (workout gets shorter)
        exercises.pop(target_idx)
        new_name = None
        logger.warning(f"No replacement found for {exercise_name} in workout {workout_id}")

    try:
        db.client.table("workouts").update({
            "exercises_json": exercises,
        }).eq("id", workout_id).execute()

        _log_workout_change(db, user_id, workout_id, "avoid_exercise_swap", {
            "removed": exercise_name,
            "replacement": new_name,
        })

        return {
            "action": "replaced" if new_name else "removed",
            "old": exercise_name,
            "new": new_name,
            "workout_id": workout_id,
            "workout_date": workout.get("scheduled_date"),
            "workout_name": workout.get("workout_name"),
        }
    except Exception as e:
        logger.error(f"Error updating workout {workout_id}: {e}")
        return {"action": "error", "reason": str(e), "workout_id": workout_id}


async def remove_muscle_from_workout(
    db,
    workout: dict,
    muscle_group: str,
    severity: str,
    context: dict,
    user_id: str,
) -> dict:
    """
    Replace all exercises targeting a muscle group in a workout.

    For severity="avoid": replace all primary+secondary matches.
    For severity="reduce": replace only primary matches.

    Returns: {"action": "replaced", "replaced": [{"old": name, "new": name}, ...]}
    """
    workout_id = workout["id"]
    exercises = workout.get("exercises_json") or []
    if isinstance(exercises, str):
        try:
            exercises = json.loads(exercises)
        except (json.JSONDecodeError, TypeError):
            exercises = []

    normalized_muscle = _normalize_muscle(muscle_group)
    replacements = []
    excluded = {(ex.get("name") or "").lower() for ex in exercises}

    # Staple names — don't replace staples
    staple_names_lower = {s["exercise_name"].lower() for s in context.get("staples", [])}

    for i, ex in enumerate(exercises):
        ex_name = ex.get("name") or ""
        if ex_name.lower() in staple_names_lower:
            continue  # Never replace a staple

        ex_muscle = _normalize_muscle(ex.get("muscle_group") or ex.get("target_muscle"))
        is_primary_match = ex_muscle == normalized_muscle

        # For "reduce" severity, only replace if it's the primary target
        if severity == "reduce" and not is_primary_match:
            continue

        # For "avoid" severity, also check secondary muscles
        is_secondary_match = False
        if severity == "avoid" and not is_primary_match:
            secondary = ex.get("secondary_muscles") or ""
            if isinstance(secondary, str):
                sec_list = [s.strip().lower() for s in secondary.split(",") if s.strip()]
            else:
                sec_list = [str(s).lower() for s in secondary]
            is_secondary_match = any(_normalize_muscle(s) == normalized_muscle for s in sec_list)

        if not is_primary_match and not is_secondary_match:
            continue

        # Find compatible replacement (different muscle group)
        old_equipment = ex.get("equipment")
        replacement = _find_compatible_replacement(
            db, normalized_muscle, old_equipment,
            excluded, context["avoided_exercises"],
            context["avoided_muscles"] | {normalized_muscle},
        )

        if replacement:
            params = get_exercise_params(
                replacement["name"], replacement,
                exercise_history=context.get("exercise_history"),
                user_profile=context.get("user_profile"),
            )
            exercises[i] = _build_exercise_object(
                replacement["name"], replacement, params,
                order=ex.get("order", i + 1),
            )
            excluded.add(replacement["name"].lower())
            replacements.append({"old": ex_name, "new": replacement["name"]})
        else:
            # Keep exercise if no replacement found and we need at least 3
            remaining_count = len(exercises) - len([r for r in replacements])
            if remaining_count <= 3:
                continue  # Keep it to maintain minimum
            exercises[i] = None  # Mark for removal
            replacements.append({"old": ex_name, "new": None})

    # Remove None-marked exercises
    exercises = [ex for ex in exercises if ex is not None]

    if not replacements:
        return {"action": "no_match", "workout_id": workout_id, "muscle": muscle_group}

    try:
        db.client.table("workouts").update({
            "exercises_json": exercises,
        }).eq("id", workout_id).execute()

        _log_workout_change(db, user_id, workout_id, "avoid_muscle_swap", {
            "muscle": muscle_group,
            "severity": severity,
            "replacements": replacements,
        })

        return {
            "action": "replaced",
            "replaced": replacements,
            "muscle": muscle_group,
            "workout_id": workout_id,
            "workout_date": workout.get("scheduled_date"),
            "workout_name": workout.get("workout_name"),
        }
    except Exception as e:
        logger.error(f"Error updating workout {workout_id}: {e}")
        return {"action": "error", "reason": str(e), "workout_id": workout_id}


# =============================================================================
# Conflict Detection
# =============================================================================

def resolve_staple_avoid_conflict(db, user_id: str, exercise_name: str, action: str) -> str | None:
    """
    Auto-resolve staple vs. avoided conflict.

    action="staple": Check if exercise is avoided → auto-remove from avoided
    action="avoid": Check if exercise is in staples → auto-remove from staples

    Returns: message about what was resolved, or None if no conflict.
    """
    try:
        if action == "staple":
            existing = db.client.table("avoided_exercises").select("id").eq(
                "user_id", user_id
            ).ilike("exercise_name", exercise_name).execute()
            if existing.data:
                db.client.table("avoided_exercises").delete().eq("id", existing.data[0]["id"]).execute()
                return f"Removed {exercise_name} from avoided list since it's now a staple"

        elif action == "avoid":
            existing = db.client.table("staple_exercises").select("id").eq(
                "user_id", user_id
            ).ilike("exercise_name", exercise_name).execute()
            if existing.data:
                db.client.table("staple_exercises").delete().eq("id", existing.data[0]["id"]).execute()
                return f"Removed {exercise_name} from staples since it's now avoided"

    except Exception as e:
        logger.warning(f"Error resolving staple/avoid conflict: {e}")

    return None


# =============================================================================
# High-Level Apply Functions (called from endpoints)
# =============================================================================

def _staple_matches_day(staple: dict, scheduled_date_str: str | None) -> bool:
    """Check if a staple's target_days matches the workout's scheduled date."""
    target_days = staple.get("target_days")
    if target_days is None:
        return True  # No restriction — applies to all days

    if not scheduled_date_str:
        return True  # No date info — include by default

    try:
        parsed = datetime.strptime(scheduled_date_str[:10], "%Y-%m-%d")
        day_of_week = parsed.weekday()  # 0=Monday, 6=Sunday
        return day_of_week in target_days
    except (ValueError, TypeError):
        return True  # Can't parse — include by default


async def _create_staple_workout_for_date(
    db,
    user_id: str,
    target_date: date,
    staples_for_day: list[dict],
    context: dict,
) -> dict | None:
    """
    Create a lightweight staple-only workout on a non-workout day.

    This is for cases like: user staples treadmill for M/W/F but workout days are Tue/Thu/Sat/Sun.
    Creates a minimal workout containing just the stapled exercises.

    Returns the created workout dict or None on failure.
    """
    date_str = target_date.isoformat()

    # Check if a workout already exists for this date
    try:
        existing = db.client.table("workouts").select("id").eq(
            "user_id", user_id
        ).eq("scheduled_date", date_str).neq("status", "cancelled").limit(1).execute()
        if existing.data:
            return None  # Workout already exists — don't create duplicate
    except Exception:
        pass

    # Build exercises_json from staples
    exercises = []
    for i, staple in enumerate(staples_for_day):
        params = get_exercise_params(
            staple["exercise_name"],
            staple,
            user_overrides=staple,
            exercise_history=context.get("exercise_history"),
            user_profile=context.get("user_profile"),
        )
        exercises.append(_build_exercise_object(
            staple["exercise_name"], staple, params, order=i + 1,
        ))

    if not exercises:
        return None

    # Generate a simple workout name from the exercises
    muscle_groups = list({
        _strip_parens(ex.get("muscle_group")) or "General"
        for ex in exercises
        if ex.get("muscle_group")
    })
    if not muscle_groups:
        workout_name = "Staple Workout"
    elif len(muscle_groups) == 1:
        workout_name = f"{muscle_groups[0]} Session"
    else:
        workout_name = f"{' & '.join(muscle_groups[:2])} Session"

    day_name = DAY_NAMES[target_date.weekday()]

    try:
        import uuid
        workout_data = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "scheduled_date": date_str,
            "exercises_json": exercises,
            "status": "ready",
            "is_completed": False,
            "workout_name": workout_name,
            "name": workout_name,
            "generation_method": "staple_auto",
            "difficulty": "medium",
        }
        result = db.client.table("workouts").insert(workout_data).execute()
        if result.data:
            logger.info(f"Created staple-only workout for {day_name} {date_str}: {workout_name}")
            return result.data[0]
    except Exception as e:
        logger.error(f"Error creating staple workout for {date_str}: {e}")

    return None


async def apply_staple_to_workouts(db, user_id: str, staple: dict) -> dict:
    """
    Apply a new staple exercise to all matching upcoming workouts.

    Respects target_days: only injects into workouts on the staple's target days.

    Returns: {"changes": [...], "message": "..."}
    """
    context = await _fetch_preference_context(db, user_id)
    workouts = _get_upcoming_workouts(db, user_id)

    staple_muscle = _normalize_muscle(staple.get("target_muscle") or staple.get("muscle_group"))
    staple_section = staple.get("section", "main")

    changes = []
    for workout in workouts:
        # Day-of-week filter: skip workouts that don't match target_days
        if not _staple_matches_day(staple, workout.get("scheduled_date")):
            continue

        # For main section, only inject into workouts targeting the same muscle group
        if staple_section == "main" and staple_muscle:
            exercises = workout.get("exercises_json") or []
            if isinstance(exercises, str):
                try:
                    exercises = json.loads(exercises)
                except (json.JSONDecodeError, TypeError):
                    exercises = []

            # Check if workout has any exercise with matching muscle
            workout_muscles = {
                _normalize_muscle(ex.get("muscle_group") or ex.get("target_muscle"))
                for ex in exercises
            }
            if staple_muscle not in workout_muscles:
                continue  # Skip — this workout doesn't target the staple's muscle

        result = await inject_staple_into_workout(db, workout, staple, context, user_id)
        if result.get("action") not in ("already_present", "skipped", "error", "not_found"):
            changes.append(result)

    # Create staple-only workouts on non-workout target days
    target_days = staple.get("target_days")
    user_workout_days = set(context.get("workout_days", []))
    created_workouts = 0

    if target_days and user_workout_days:
        non_workout_target_days = [d for d in target_days if d not in user_workout_days]
        if non_workout_target_days:
            logger.info(
                f"Staple '{staple['exercise_name']}' targets non-workout days: "
                f"{[DAY_NAMES[d] for d in non_workout_target_days]}"
            )
            # Get all staples that target these days (batch them per day)
            all_staples = context.get("staples", [])

            # Create workouts for the next 2 weeks of non-workout target days
            today = date.today()
            for day_offset in range(1, 15):  # Tomorrow through 14 days out
                target_date = today + timedelta(days=day_offset)
                if target_date.weekday() not in non_workout_target_days:
                    continue

                # Collect ALL staples that target this day
                staples_for_day = []
                for s in all_staples:
                    s_target_days = s.get("target_days")
                    if s_target_days is None or target_date.weekday() in s_target_days:
                        staples_for_day.append(s)

                # Also include the new staple being added (may not be in all_staples yet)
                new_name_lower = staple["exercise_name"].lower()
                if not any(s["exercise_name"].lower() == new_name_lower for s in staples_for_day):
                    staples_for_day.append(staple)

                if staples_for_day:
                    result = await _create_staple_workout_for_date(
                        db, user_id, target_date, staples_for_day, context,
                    )
                    if result:
                        created_workouts += 1
                        changes.append({
                            "action": "created",
                            "new": staple["exercise_name"],
                            "workout_date": target_date.isoformat(),
                            "workout_name": result.get("workout_name", "Staple Workout"),
                        })

    day_info = ""
    if target_days:
        day_names = [DAY_NAMES[d] for d in sorted(target_days) if 0 <= d <= 6]
        day_info = f" (on {', '.join(day_names)})"

    if changes:
        parts = []
        injected = [c for c in changes if c.get("action") != "created"]
        created = [c for c in changes if c.get("action") == "created"]
        if injected:
            parts.append(f"added to {len(injected)} workout(s)")
        if created:
            parts.append(f"created {len(created)} new workout(s)")
        message = f"{staple['exercise_name']}: {', '.join(parts)}{day_info}"
    else:
        message = f"{staple['exercise_name']} saved{day_info}. It will appear in your next matching workout"

    return {"changes": changes, "message": message}


async def apply_avoid_exercise_to_workouts(db, user_id: str, exercise_name: str) -> dict:
    """
    Remove an avoided exercise from all upcoming workouts.

    Returns: {"changes": [...], "message": "..."}
    """
    context = await _fetch_preference_context(db, user_id)
    workouts = _get_upcoming_workouts(db, user_id)

    changes = []
    for workout in workouts:
        exercises = workout.get("exercises_json") or []
        if isinstance(exercises, str):
            try:
                exercises = json.loads(exercises)
            except (json.JSONDecodeError, TypeError):
                exercises = []

        # Check if this workout contains the avoided exercise
        has_exercise = any(
            (ex.get("name") or "").lower() == exercise_name.lower()
            for ex in exercises
        )
        if not has_exercise:
            continue

        result = await remove_exercise_from_workout(db, workout, exercise_name, context, user_id)
        if result.get("action") not in ("not_found", "error"):
            changes.append(result)

    if changes:
        message = f"Replaced {exercise_name} in {len(changes)} upcoming workout(s)"
    else:
        message = f"{exercise_name} added to avoid list. No upcoming workouts contained it"

    return {"changes": changes, "message": message}


async def apply_avoid_muscle_to_workouts(db, user_id: str, muscle_group: str, severity: str) -> dict:
    """
    Remove/replace exercises targeting a muscle group in all upcoming workouts.

    Returns: {"changes": [...], "message": "..."}
    """
    context = await _fetch_preference_context(db, user_id)
    workouts = _get_upcoming_workouts(db, user_id)

    changes = []
    total_replaced = 0
    for workout in workouts:
        result = await remove_muscle_from_workout(db, workout, muscle_group, severity, context, user_id)
        if result.get("action") == "replaced":
            changes.append(result)
            total_replaced += len(result.get("replaced", []))

    if changes:
        message = f"Replaced {total_replaced} exercise(s) targeting {muscle_group} in {len(changes)} workout(s)"
    else:
        message = f"No upcoming workouts contained exercises targeting {muscle_group}"

    return {"changes": changes, "message": message}


async def inject_queued_exercise_into_next_workout(db, user_id: str, exercise_name: str, queue_id: str) -> dict:
    """
    Inject a queued exercise into the next upcoming workout.

    Returns: {"changes": [...], "message": "..."}
    """
    context = await _fetch_preference_context(db, user_id)
    workouts = _get_upcoming_workouts(db, user_id)

    if not workouts:
        return {"changes": [], "message": f"No upcoming workouts to inject {exercise_name} into"}

    # Get exercise details from library
    try:
        lib_result = db.client.table("exercise_library_cleaned") \
            .select("name, target_muscle, body_part, equipment, gif_url, secondary_muscles, category") \
            .ilike("name", exercise_name) \
            .limit(1) \
            .execute()

        if not lib_result.data:
            lib_result = db.client.table("exercise_library_cleaned") \
                .select("name, target_muscle, body_part, equipment, gif_url, secondary_muscles, category") \
                .ilike("name", f"%{exercise_name}%") \
                .limit(1) \
                .execute()

        library_data = lib_result.data[0] if lib_result.data else {"name": exercise_name}
    except Exception:
        library_data = {"name": exercise_name}

    # Use next workout
    next_workout = workouts[0]
    staple_like = {
        "exercise_name": exercise_name,
        "section": "main",
        **library_data,
    }

    result = await inject_staple_into_workout(db, next_workout, staple_like, context, user_id)

    # Mark queue item as used
    if result.get("action") not in ("error", "skipped"):
        try:
            db.client.table("exercise_queue").update({
                "used_at": datetime.utcnow().isoformat(),
            }).eq("id", queue_id).execute()
        except Exception as e:
            logger.warning(f"Could not mark queue item as used: {e}")

    changes = [result] if result.get("action") not in ("error",) else []
    if changes:
        message = f"Injected {exercise_name} into {next_workout.get('workout_name', 'next workout')}"
    else:
        message = f"Could not inject {exercise_name} into next workout"

    return {"changes": changes, "message": message}
