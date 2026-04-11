"""Helper functions extracted from preference_engine.
Rule-Based Exercise Preference Engine.

Handles instant exercise swaps/injections/removals when users change exercise preferences
(staple, avoid exercise, avoid muscle). No AI regeneration needed — all changes are
applied directly to existing workout exercises_json.

Core principle: Parse JSON → find target → replace with library match → update row.
"""
from __future__ import annotations

from datetime import datetime, timedelta, date
import json
import logging
from core.timezone_utils import get_user_today
logger = logging.getLogger(__name__)


def _engine_parent():
    """Lazy import to avoid circular dependency with preference_engine.py."""
    from .preference_engine import (
        get_exercise_params, _build_exercise_object, _strip_parens,
        _normalize_muscle, _find_replacement_exercise,
        _find_compatible_replacement, _log_workout_change,
        inject_staple_into_workout, _fetch_preference_context,
        _get_upcoming_workouts, DAY_NAMES,
    )
    return (
        get_exercise_params, _build_exercise_object, _strip_parens,
        _normalize_muscle, _find_replacement_exercise,
        _find_compatible_replacement, _log_workout_change,
        inject_staple_into_workout, _fetch_preference_context,
        _get_upcoming_workouts, DAY_NAMES,
    )
def _inject_into_section(
    db,
    workout_id: str,
    staple: dict,
    section: str,
    context: dict,
    user_id: str,
) -> dict:
    """Inject a staple into the warmups or stretches table."""
    (get_exercise_params, _build_exercise_object, _strip_parens,
     _normalize_muscle, _find_replacement_exercise,
     _find_compatible_replacement, _log_workout_change,
     inject_staple_into_workout, _fetch_preference_context,
     _get_upcoming_workouts, DAY_NAMES) = _engine_parent()
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
        logger.error(f"Error injecting into {table}: {e}", exc_info=True)
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
    (get_exercise_params, _build_exercise_object, _strip_parens,
     _normalize_muscle, _find_replacement_exercise,
     _find_compatible_replacement, _log_workout_change,
     inject_staple_into_workout, _fetch_preference_context,
     _get_upcoming_workouts, DAY_NAMES) = _engine_parent()
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
        logger.error(f"Error updating workout {workout_id}: {e}", exc_info=True)
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
    (get_exercise_params, _build_exercise_object, _strip_parens,
     _normalize_muscle, _find_replacement_exercise,
     _find_compatible_replacement, _log_workout_change,
     inject_staple_into_workout, _fetch_preference_context,
     _get_upcoming_workouts, DAY_NAMES) = _engine_parent()
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
        logger.error(f"Error updating workout {workout_id}: {e}", exc_info=True)
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
        logger.warning(f"Error resolving staple/avoid conflict: {e}", exc_info=True)

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
    (get_exercise_params, _build_exercise_object, _strip_parens,
     _normalize_muscle, _find_replacement_exercise,
     _find_compatible_replacement, _log_workout_change,
     inject_staple_into_workout, _fetch_preference_context,
     _get_upcoming_workouts, DAY_NAMES) = _engine_parent()
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
        logger.error(f"Error creating staple workout for {date_str}: {e}", exc_info=True)

    return None


async def apply_staple_to_workouts(db, user_id: str, staple: dict, timezone_str: str = None) -> dict:
    """
    Apply a new staple exercise to all matching upcoming workouts.

    Respects target_days: only injects into workouts on the staple's target days.

    Returns: {"changes": [...], "message": "..."}
    """
    (get_exercise_params, _build_exercise_object, _strip_parens,
     _normalize_muscle, _find_replacement_exercise,
     _find_compatible_replacement, _log_workout_change,
     inject_staple_into_workout, _fetch_preference_context,
     _get_upcoming_workouts, DAY_NAMES) = _engine_parent()
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
            today = date.fromisoformat(get_user_today(timezone_str)) if timezone_str else date.fromisoformat(get_user_today("UTC"))
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
    (get_exercise_params, _build_exercise_object, _strip_parens,
     _normalize_muscle, _find_replacement_exercise,
     _find_compatible_replacement, _log_workout_change,
     inject_staple_into_workout, _fetch_preference_context,
     _get_upcoming_workouts, DAY_NAMES) = _engine_parent()
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
    (get_exercise_params, _build_exercise_object, _strip_parens,
     _normalize_muscle, _find_replacement_exercise,
     _find_compatible_replacement, _log_workout_change,
     inject_staple_into_workout, _fetch_preference_context,
     _get_upcoming_workouts, DAY_NAMES) = _engine_parent()
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
    (get_exercise_params, _build_exercise_object, _strip_parens,
     _normalize_muscle, _find_replacement_exercise,
     _find_compatible_replacement, _log_workout_change,
     inject_staple_into_workout, _fetch_preference_context,
     _get_upcoming_workouts, DAY_NAMES) = _engine_parent()
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
            logger.warning(f"Could not mark queue item as used: {e}", exc_info=True)

    changes = [result] if result.get("action") not in ("error",) else []
    if changes:
        message = f"Injected {exercise_name} into {next_workout.get('workout_name', 'next workout')}"
    else:
        message = f"Could not inject {exercise_name} into next workout"

    return {"changes": changes, "message": message}
