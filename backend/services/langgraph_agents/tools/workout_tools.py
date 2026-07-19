"""
Workout modification tools for LangGraph agents.

Contains tools for adding, removing, replacing exercises,
modifying intensity, rescheduling, and generating quick workouts.
"""

from typing import List, Dict, Any
from datetime import datetime, timezone
import json
import re

from langchain_core.tools import tool

_UUID_PATTERN = re.compile(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    re.IGNORECASE
)


def _validate_workout_id(workout_id: str) -> bool:
    """Validate that workout_id is a valid UUID string."""
    return bool(_UUID_PATTERN.match(str(workout_id)))

from services.workout_modifier import WorkoutModifier
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from .base import run_async_in_sync

logger = get_logger(__name__)


def _get_user_equipment_info(user: Dict) -> tuple:
    """Extract equipment info from user profile."""
    user_equipment = user.get("equipment", []) if user else ["Bodyweight"]
    user_fitness_level = user.get("fitness_level", "intermediate") if user else "intermediate"
    user_prefs = user.get("preferences", {}) if user else {}

    if isinstance(user_prefs, str):
        try:
            user_prefs = json.loads(user_prefs) if user_prefs else {}
        except json.JSONDecodeError:
            user_prefs = {}

    dumbbell_count = user_prefs.get("dumbbell_count", 2)
    kettlebell_count = user_prefs.get("kettlebell_count", 1)

    return user_equipment, user_fitness_level, dumbbell_count, kettlebell_count


def _parse_injuries(user_injuries: Any) -> List[str]:
    """Parse user injuries from various formats."""
    if isinstance(user_injuries, str):
        try:
            user_injuries = json.loads(user_injuries)
        except json.JSONDecodeError:
            user_injuries = []

    injury_body_parts = []
    if user_injuries:
        for inj in user_injuries:
            if isinstance(inj, dict):
                injury_body_parts.append(inj.get("body_part", ""))
            elif isinstance(inj, str):
                injury_body_parts.append(inj)

    return injury_body_parts


@tool
def add_exercise_to_workout(
    workout_id: str,
    exercise_names: List[str],
    muscle_groups: List[str] = None
) -> Dict[str, Any]:
    """
    Add exercises to the user's current workout using the Exercise Library from ChromaDB.

    Args:
        workout_id: The UUID of the workout to modify
        exercise_names: List of exercise names to add (e.g., ["Push-ups", "Lunges"])
        muscle_groups: Optional list of target muscle groups

    Returns:
        Result dict with success status and message
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "add_exercise",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Adding exercises {exercise_names} to workout {workout_id} using RAG")

    try:
        db = get_supabase_db()

        # Get current workout
        workout = db.get_workout(workout_id)
        if not workout:
            return {
                "success": False,
                "action": "add_exercise",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        # Get current exercises
        exercises_data = workout.get("exercises")
        if isinstance(exercises_data, str):
            exercises = json.loads(exercises_data) if exercises_data else []
        else:
            exercises = exercises_data or []

        # Get user profile for personalized exercise selection
        user_id = workout.get("user_id")
        user = db.get_user(user_id) if user_id else None
        user_equipment, user_fitness_level, dumbbell_count, kettlebell_count = _get_user_equipment_info(user)

        # Use Exercise RAG to find exercises from the library
        from services.exercise_rag_service import get_exercise_rag_service
        exercise_rag = get_exercise_rag_service()

        added_exercises = []
        for exercise_name in exercise_names:
            # Check if exercise already exists in workout
            if any(ex.get("name", "").lower() == exercise_name.lower() for ex in exercises):
                logger.info(f"Exercise already exists: {exercise_name}")
                continue

            # Search for exercise in ChromaDB
            try:
                rag_results = run_async_in_sync(
                    exercise_rag.select_exercises_for_workout(
                        focus_area=exercise_name,
                        equipment=user_equipment if user_equipment else ["Bodyweight"],
                        fitness_level=user_fitness_level,
                        goals=["General Fitness"],
                        count=1,
                        avoid_exercises=[ex.get("name", "") for ex in exercises],
                        injuries=None,
                        dumbbell_count=dumbbell_count,
                        kettlebell_count=kettlebell_count,
                    ),
                    timeout=15
                )

                if rag_results:
                    ex = rag_results[0]
                    new_exercise = {
                        "name": ex.get("name", exercise_name),
                        "sets": ex.get("sets", 3),
                        "reps": ex.get("reps", 12),
                        "rest_seconds": ex.get("rest_seconds", 60),
                        "equipment": ex.get("equipment", "Bodyweight"),
                        "muscle_group": ex.get("muscle_group", ex.get("body_part", "")),
                        "notes": ex.get("notes", ""),
                        "gif_url": ex.get("gif_url", ""),
                        "video_url": ex.get("video_url", ""),
                        "image_url": ex.get("image_url", ""),
                        "library_id": ex.get("library_id", ""),
                    }
                    exercises.append(new_exercise)
                    added_exercises.append(new_exercise["name"])
                    logger.info(f"Added exercise from library: {new_exercise['name']}")
                else:
                    logger.warning(f"Exercise not found in library: {exercise_name}")

            except Exception as search_error:
                logger.warning(f"Failed to search for exercise {exercise_name}: {search_error}", exc_info=True)

        if not added_exercises:
            return {
                "success": False,
                "action": "add_exercise",
                "workout_id": workout_id,
                "message": "Could not find exercises in the Exercise Library. Try different exercise names."
            }

        # Update workout in database
        update_data = {
            "exercises": exercises,
            "last_modified_method": "ai_coach",
        }
        db.update_workout(workout_id, update_data)

        logger.info(f"Successfully added {len(added_exercises)} exercises to workout {workout_id}")

        return {
            "success": True,
            "action": "add_exercise",
            "workout_id": workout_id,
            "exercises_added": added_exercises,
            "message": f"Added {len(added_exercises)} exercises: {', '.join(added_exercises)}"
        }

    except Exception as e:
        logger.error(f"Failed to add exercises: {e}", exc_info=True)
        return {
            "success": False,
            "action": "add_exercise",
            "workout_id": workout_id,
            "message": f"Failed to add exercises: {str(e)}"
        }


@tool
def remove_exercise_from_workout(
    workout_id: str,
    exercise_names: List[str]
) -> Dict[str, Any]:
    """
    Remove exercises from the user's current workout.

    Args:
        workout_id: The UUID of the workout to modify
        exercise_names: List of exercise names to remove

    Returns:
        Result dict with success status and message
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "remove_exercise",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Removing exercises {exercise_names} from workout {workout_id}")
    modifier = WorkoutModifier()
    success = modifier.remove_exercises_from_workout(
        workout_id=workout_id,
        exercise_names=exercise_names
    )
    return {
        "success": success,
        "action": "remove_exercise",
        "workout_id": workout_id,
        "exercises_removed": exercise_names,
        "message": f"Removed exercises: {', '.join(exercise_names)}" if success else "Failed to remove exercises"
    }


@tool
def replace_all_exercises(
    workout_id: str,
    muscle_group: str,
    num_exercises: int = 5
) -> Dict[str, Any]:
    """
    Replace ALL exercises in a workout with new exercises targeting a specific muscle group.
    Uses the Exercise Library from ChromaDB for personalized exercise selection.

    Args:
        workout_id: The UUID of the workout to modify
        muscle_group: Target muscle group (e.g., "back", "chest", "legs")
        num_exercises: Number of new exercises to add (default 5)

    Returns:
        Result dict with success status, removed exercises, and new exercises
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "replace_all_exercises",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Replacing all exercises in workout {workout_id} with {muscle_group} exercises")

    try:
        db = get_supabase_db()

        workout = db.get_workout(workout_id)
        if not workout:
            return {
                "success": False,
                "action": "replace_all_exercises",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        current_exercises = workout.get("exercises", [])
        old_exercise_names = [e.get("name", "Unknown") for e in current_exercises]

        # Get user profile
        user_id = workout.get("user_id")
        user = db.get_user(user_id) if user_id else None
        user_equipment, user_fitness_level, dumbbell_count, kettlebell_count = _get_user_equipment_info(user)
        user_goals = user.get("goals", []) if user else []
        # PHASE-AWARE: only fully protect acute/subacute injuries; recovering /
        # reintroducing ones ease back in (and healed ones drop out) instead of
        # blocking the body part forever.
        try:
            from services.coach.injury_directives import resolve_injury_directives
            injury_body_parts = resolve_injury_directives(
                user.get("active_injuries") if user else None
            ).get("hard_avoid_parts", [])
        except Exception:
            injury_body_parts = _parse_injuries(user.get("active_injuries", []) if user else [])

        # Map muscle group to focus area
        focus_area_map = {
            "back": "back", "chest": "chest", "legs": "legs",
            "shoulders": "shoulders", "arms": "arms", "core": "core",
            "glutes": "legs", "biceps": "arms", "triceps": "arms",
            "quads": "legs", "hamstrings": "legs", "calves": "legs", "abs": "core",
        }
        focus_area = focus_area_map.get(muscle_group.lower(), muscle_group.lower())

        # Use Exercise RAG
        from services.exercise_rag_service import get_exercise_rag_service
        exercise_rag = get_exercise_rag_service()

        rag_exercises = run_async_in_sync(
            exercise_rag.select_exercises_for_workout(
                focus_area=focus_area,
                equipment=user_equipment if user_equipment else ["Bodyweight"],
                fitness_level=user_fitness_level,
                goals=user_goals if user_goals else ["General Fitness"],
                count=num_exercises,
                avoid_exercises=old_exercise_names,
                injuries=injury_body_parts if injury_body_parts else None,
                dumbbell_count=dumbbell_count,
                kettlebell_count=kettlebell_count,
            ),
            timeout=30
        )

        if not rag_exercises:
            return {
                "success": False,
                "action": "replace_all_exercises",
                "workout_id": workout_id,
                "message": f"Could not find exercises for {muscle_group}."
            }

        new_exercises = []
        for ex in rag_exercises:
            new_exercises.append({
                "name": ex.get("name", "Exercise"),
                "sets": ex.get("sets", 3),
                "reps": ex.get("reps", 12),
                "duration_seconds": ex.get("duration_seconds"),
                "muscle_group": muscle_group.lower(),
                "equipment": ex.get("equipment", "Bodyweight"),
                "notes": ex.get("notes", ""),
                "gif_url": ex.get("gif_url", ""),
                "video_url": ex.get("video_url", ""),
                "image_url": ex.get("image_url", ""),
                "library_id": ex.get("library_id", ""),
            })

        update_data = {
            "exercises": new_exercises,
            "name": f"{muscle_group.title()} Workout",
            "last_modified_method": "ai_replace_all"
        }
        db.update_workout(workout_id, update_data)

        new_exercise_names = [e["name"] for e in new_exercises]
        logger.info(f"Replaced {len(old_exercise_names)} exercises with {len(new_exercises)} {muscle_group} exercises")

        return {
            "success": True,
            "action": "replace_all_exercises",
            "workout_id": workout_id,
            "exercises_removed": old_exercise_names,
            "exercises_added": new_exercise_names,
            "muscle_group": muscle_group,
            "message": f"Replaced all exercises with {len(new_exercises)} {muscle_group} exercises"
        }

    except Exception as e:
        logger.error(f"Error replacing exercises: {e}", exc_info=True)
        return {
            "success": False,
            "action": "replace_all_exercises",
            "workout_id": workout_id,
            "message": f"Failed to replace exercises: {str(e)}"
        }


@tool
def modify_workout_intensity(
    workout_id: str,
    modification: str
) -> Dict[str, Any]:
    """
    Modify the intensity of the user's workout.

    Args:
        workout_id: The UUID of the workout to modify
        modification: Type of modification - "easier", "harder", "shorter", "longer"

    Returns:
        Result dict with success status and message
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "modify_intensity",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Modifying intensity for workout {workout_id}: {modification}")
    modifier = WorkoutModifier()
    success = modifier.modify_workout_intensity(
        workout_id=workout_id,
        modification=modification
    )
    return {
        "success": success,
        "action": "modify_intensity",
        "workout_id": workout_id,
        "modification": modification,
        "message": f"Workout intensity modified: {modification}" if success else "Failed to modify intensity"
    }


@tool
def reschedule_workout(
    workout_id: str,
    new_date: str,
    reason: str = None
) -> Dict[str, Any]:
    """
    Move a workout to a different date. If another workout exists on the target date, they will be swapped.

    Args:
        workout_id: The UUID of the workout to move
        new_date: New date in YYYY-MM-DD format
        reason: Reason for rescheduling

    Returns:
        Result dict with success status and message
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "reschedule",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Rescheduling workout {workout_id} to {new_date}")

    try:
        db = get_supabase_db()

        moved_workout = db.get_workout(workout_id)
        if not moved_workout:
            return {
                "success": False,
                "action": "reschedule",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        old_date = moved_workout.get("scheduled_date")
        user_id = moved_workout.get("user_id")
        workout_name = moved_workout.get("name")

        # Check for existing workout on new date
        workouts_on_date = db.get_workouts_by_date_range(user_id, new_date, new_date)

        swapped_with = None
        if workouts_on_date:
            existing = workouts_on_date[0]
            logger.info(f"Swapping: workout {existing['id']} will move to {old_date}")
            db.update_workout(existing['id'], {
                "scheduled_date": str(old_date),
                "last_modified_method": "ai_reschedule"
            })
            swapped_with = {"id": existing['id'], "name": existing['name']}

        db.update_workout(workout_id, {
            "scheduled_date": new_date,
            "last_modified_method": "ai_reschedule"
        })

        try:
            db.create_workout_change({
                "workout_id": workout_id,
                "user_id": user_id,
                "change_type": "rescheduled",
                "field_changed": "scheduled_date",
                "old_value": str(old_date),
                "new_value": new_date,
                "change_source": "ai_coach",
                "change_reason": reason or "Rescheduled via AI coach"
            })
        except Exception as log_error:
            logger.warning(f"Failed to log workout change: {log_error}", exc_info=True)

        if swapped_with:
            message = f"Moved '{workout_name}' to {new_date} and swapped with '{swapped_with['name']}'"
        else:
            message = f"Moved '{workout_name}' from {old_date} to {new_date}"

        return {
            "success": True,
            "action": "reschedule",
            "workout_id": workout_id,
            "workout_name": workout_name,
            "old_date": str(old_date),
            "new_date": new_date,
            "swapped_with": swapped_with,
            "message": message
        }

    except Exception as e:
        logger.error(f"Reschedule failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "reschedule",
            "workout_id": workout_id,
            "message": f"Failed to reschedule: {str(e)}"
        }


@tool
def delete_workout(
    workout_id: str,
    reason: str = None
) -> Dict[str, Any]:
    """
    Delete/cancel a workout from the user's schedule.

    Args:
        workout_id: The UUID of the workout to delete
        reason: Optional reason for deletion

    Returns:
        Result dict with success status and workout details
    """
    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "delete_workout",
            "workout_id": workout_id,
            "message": f"Invalid workout ID format: {workout_id}. Expected a UUID."
        }

    logger.info(f"Tool: Deleting workout {workout_id}")

    try:
        db = get_supabase_db()

        workout = db.get_workout(workout_id)
        if not workout:
            return {
                "success": False,
                "action": "delete_workout",
                "workout_id": workout_id,
                "message": f"Workout with ID {workout_id} not found"
            }

        workout_name = workout.get("name")
        scheduled_date = workout.get("scheduled_date")
        workout_type = workout.get("type")
        user_id = workout.get("user_id")

        # Delete related records
        db.delete_performance_logs_by_workout_log(workout_id)
        db.delete_workout_logs_by_workout(workout_id)
        db.delete_workout_changes_by_workout(workout_id)
        db.delete_workout(workout_id)

        try:
            db.create_workout_change({
                "workout_id": workout_id,
                "user_id": user_id,
                "change_type": "deleted",
                "field_changed": "workout",
                "old_value": workout_name,
                "new_value": None,
                "change_source": "ai_coach",
                "change_reason": reason or "Deleted via AI coach"
            })
        except Exception as log_error:
            logger.warning(f"Failed to log workout deletion: {log_error}", exc_info=True)

        return {
            "success": True,
            "action": "delete_workout",
            "workout_id": workout_id,
            "workout_name": workout_name,
            "scheduled_date": str(scheduled_date),
            "workout_type": workout_type,
            "reason": reason,
            "message": f"Successfully deleted '{workout_name}' scheduled for {scheduled_date}"
        }

    except Exception as e:
        logger.error(f"Delete workout failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "delete_workout",
            "workout_id": workout_id,
            "message": f"Failed to delete workout: {str(e)}"
        }


@tool
def generate_quick_workout(
    user_id: str,
    workout_id: str = None,
    duration_minutes: int = 15,
    workout_type: str = "full_body",
    intensity: str = "moderate",
    constraints_text: str = None,
    focus: str = None,
) -> Dict[str, Any]:
    """
    Generate a quick workout for the user using the Exercise Library.

    Args:
        user_id: The user's ID (required)
        workout_id: Optional ID of workout to replace
        duration_minutes: Target duration in minutes (default 15, max 30)
        workout_type: Type of workout (full_body, upper, lower, cardio, core, boxing, etc.)
        intensity: Workout intensity - "light", "moderate", "intense"
        constraints_text: Optional free-text limitation stated by the user. If the
            user mentions an injury, pain, soreness, a time limit, an equipment
            limit (e.g. "no dumbbells", "bodyweight only"), low-impact needs, or
            a body-part focus, pass their exact words here (e.g. "I have back
            pain, keep it short and low impact"). The workout is then built to
            honor those constraints (pain/injury is a HARD avoidance).
        focus: Optional muscle/area focus (e.g. "legs", "upper", "core") to bias
            the workout toward when the user names one.

    Returns:
        Result dict with the new quick workout details
    """
    # Input hardening (Fix 4) — never crash on a null / out-of-range arg from
    # the LLM tool call. Clamp duration to a sane 5–90 min; default type/intensity.
    try:
        duration_minutes = int(duration_minutes) if duration_minutes else 15
    except (TypeError, ValueError):
        duration_minutes = 15
    duration_minutes = max(5, min(duration_minutes, 90))
    workout_type = (workout_type or "full_body").strip() or "full_body"
    intensity = (intensity or "moderate").strip() or "moderate"

    # workout_id hardening (2026-07-18) — the LLM frequently fills the OPTIONAL
    # workout_id with a placeholder ("0", 0, "", "none", "null") when it means
    # "no existing workout, create a new one". Those values reach get_workout()
    # and 500 the uuid column (Postgres 22P02: invalid input syntax for type
    # uuid: "0"), so the whole tool returned success=False and no workout was
    # created. Coerce anything that isn't a real UUID to None → create-new path.
    if workout_id is not None and not _UUID_PATTERN.match(str(workout_id).strip()):
        workout_id = None

    logger.info(f"Tool: Generating quick {duration_minutes}min {workout_type} workout for user {user_id}")

    # ── DURABLE AUTO-CAPTURE (D) ──────────────────────────────────────────────
    # If the request mentions a NEW injury ("my back hurts, give me a workout"),
    # persist it (deduped, mild) BEFORE generating so this same workout — and all
    # future ones — honor it. Mere soreness (DOMS) is left transient. Non-fatal.
    try:
        from services.langgraph_agents.tools.injury_tools import (
            capture_pain_from_text, detect_red_flag, red_flag_safety_response,
            report_injury as _report_injury,
        )
        # RED-FLAG SAFETY (F3): numbness / radiating pain / can't-bear-weight etc.
        # → do NOT auto-generate a gentle workout; recommend a professional and
        # protect the area going forward. Deterministic, never an LLM call.
        _is_red, _rf_part = detect_red_flag(constraints_text or "")
        if _is_red:
            if _rf_part:
                try:
                    _report_injury.invoke({
                        "user_id": str(user_id), "body_part": _rf_part,
                        "severity": "severe", "notes": "red-flag symptoms reported",
                    })
                except Exception:
                    pass
            return {
                "success": True,
                "action": "injury_red_flag",
                "workout_id": None,
                "message": red_flag_safety_response(_rf_part),
            }
        capture_pain_from_text(str(user_id), constraints_text or "")
    except Exception as _cap_err:
        logger.debug(f"[Quick Workout] injury auto-capture/red-flag skipped: {_cap_err}")

    # ── NO-RESTRICTIONS path (ADDITIVE) ───────────────────────────────────────
    # If the user named an implement/movement the Exercise Library can't cover
    # ("hay bale", "tire", "sandbag", a made-up object), AUTHOR the session with
    # the LLM instead of silently substituting generic library moves. Gated by a
    # data-driven coverage check; any failure returns None and falls straight
    # through to the standard library path below (never blocks generation).
    try:
        from services.workout_novel_authoring import maybe_author_novel_workout
        # Use ONLY the user's own words for novel-implement detection. Do NOT
        # append workout_type — it is a default enum ("full_body") whose
        # underscore breaks implement extraction and would mask a real implement.
        _request_text = (constraints_text or focus or "").strip()
        novel = maybe_author_novel_workout(
            db_getter=get_supabase_db,
            user_id=str(user_id),
            request_text=_request_text,
            duration_minutes=duration_minutes,
            focus=focus,
            intensity=intensity,
            workout_id=workout_id,
        )
        if novel is not None:
            return novel
    except Exception as e:
        logger.warning(f"[Quick Workout] novel-authoring gate failed, using standard path: {e}")

    # ── Constraint-aware path (ADDITIVE) ──────────────────────────────────────
    # When the user states a free-text limitation/focus, build via the shared
    # workout engine so pain/injury/time/equipment/impact constraints are
    # honored deterministically. Returns the SAME response dict shape as the
    # legacy path below. Any failure falls through to the legacy path so a
    # constraint parse never breaks workout generation.
    if constraints_text or focus:
        try:
            from services.workout_builder import (
                build_adapted_workout,
                parse_constraints_text,
                persist_built_workout,
            )

            db = get_supabase_db()
            user = db.get_user(user_id) if user_id else None

            base_text_parts = []
            if constraints_text:
                base_text_parts.append(constraints_text)
            if focus:
                base_text_parts.append(focus)
            # Seed the parser with the requested type/intensity/duration too, so
            # the LLM's structured args aren't lost when constraints are present.
            seed_text = " ".join(base_text_parts + [
                str(workout_type or ""), str(intensity or ""),
                f"{duration_minutes} min",
            ])
            params = parse_constraints_text(seed_text)
            if focus:
                fa = str(focus).lower().strip().replace(" ", "_")
                if fa and fa not in [f.lower() for f in params.focus_areas]:
                    if "full_body" in params.focus_areas:
                        params.focus_areas = [fa]
                    else:
                        params.focus_areas.append(fa)

            built = run_async_in_sync(build_adapted_workout(params, user))

            final_workout_id = persist_built_workout(
                db,
                user_id=str(user_id),
                built=built,
                params=params,
                existing_workout_id=workout_id,
                generation_source="chat",
            )
            if not final_workout_id:
                raise RuntimeError("persist_built_workout returned no workout_id")

            exercises_added = [
                e.get("name", "Unknown") for e in (built.exercises or [])
            ]
            logger.info(
                f"[Quick Workout] Built constraint-aware workout {final_workout_id}: "
                f"'{built.name}' ({len(exercises_added)} exercises, "
                f"relaxed={built.relaxed_constraints})"
            )
            return {
                "success": True,
                "action": "generate_quick_workout",
                "workout_id": final_workout_id,
                "workout_name": built.name,
                "duration_minutes": built.duration_minutes,
                "workout_type": built.type,
                "intensity": params.intensity,
                "exercises_removed": [],
                "exercises_added": exercises_added,
                "exercise_count": len(built.exercises or []),
                "is_new_workout": workout_id is None,
                "relaxed_constraints": built.relaxed_constraints,
                "message": (
                    f"Created '{built.name}' - {len(exercises_added)} exercises"
                ),
            }
        except Exception as e:
            logger.warning(
                f"[Quick Workout] Constraint-aware build failed ({e}); "
                f"falling back to standard generation",
                exc_info=True,
            )
            # fall through to the legacy no-constraint path

    try:
        db = get_supabase_db()

        old_exercise_names = []
        workout = None
        is_new_workout = False

        # Try to get existing workout
        if workout_id:
            workout = db.get_workout(workout_id)
            if workout:
                old_exercises = workout.get("exercises", [])
                old_exercise_names = [e.get("name", "Unknown") for e in old_exercises]

        # If no workout found, check for existing incomplete workout for today
        if not workout:
            today_utc = datetime.now(timezone.utc).date().isoformat()
            existing_today = db.client.table("workouts").select("*").eq(
                "user_id", user_id
            ).eq("is_completed", False).eq("is_current", True).gte(
                "scheduled_date", today_utc
            ).lte("scheduled_date", today_utc + "T23:59:59Z").order(
                "created_at", desc=True
            ).limit(1).execute()

            if existing_today.data:
                workout = existing_today.data[0]
                workout_id = workout.get("id")
                old_exercises = workout.get("exercises_json", []) or workout.get("exercises", [])
                old_exercise_names = [e.get("name", "Unknown") for e in old_exercises] if old_exercises else []
            else:
                is_new_workout = True

        # Get user profile
        user = db.get_user(user_id) if user_id else None
        user_equipment, user_fitness_level, dumbbell_count, kettlebell_count = _get_user_equipment_info(user)
        user_goals = user.get("goals", []) if user else []
        # PHASE-AWARE: only fully protect acute/subacute injuries; recovering /
        # reintroducing ones ease back in (and healed ones drop out) instead of
        # blocking the body part forever.
        try:
            from services.coach.injury_directives import resolve_injury_directives
            injury_body_parts = resolve_injury_directives(
                user.get("active_injuries") if user else None
            ).get("hard_avoid_parts", [])
        except Exception:
            injury_body_parts = _parse_injuries(user.get("active_injuries", []) if user else [])

        # Map workout type to focus area
        focus_area_map = {
            "full_body": "full_body", "upper": "chest", "lower": "legs",
            "cardio": "full_body_power", "core": "core",
            "boxing": "boxing", "hyrox": "hyrox", "crossfit": "crossfit",
            "martial_arts": "martial_arts", "hiit": "hiit",
            "strength": "strength", "endurance": "endurance",
            "flexibility": "flexibility", "mobility": "mobility",
            "cricket": "cricket", "football": "football",
            "basketball": "basketball", "tennis": "tennis",
            "chest": "chest", "back": "back", "shoulders": "shoulders",
            "arms": "arms", "legs": "legs", "glutes": "legs",
        }

        workout_type_key = workout_type.lower().replace(" ", "_").replace("-", "_")
        if workout_type_key not in focus_area_map:
            workout_type_key = "full_body"
        focus_area = focus_area_map[workout_type_key]

        # Determine exercise count based on duration. Extended past 20 min so a
        # requested 30/45/60-min session is honored with a proportional number
        # of exercises (the old flat "6 for anything over 20" undercut long
        # requests).
        if duration_minutes <= 10:
            exercise_count = 3
        elif duration_minutes <= 15:
            exercise_count = 4
        elif duration_minutes <= 20:
            exercise_count = 5
        elif duration_minutes <= 30:
            exercise_count = 7
        elif duration_minutes <= 45:
            exercise_count = 9
        else:
            exercise_count = 10

        intensity_key = intensity.lower()
        if intensity_key not in ["light", "moderate", "intense"]:
            intensity_key = "moderate"

        # Map intensity to suggested fitness level
        intensity_to_fitness = {
            "light": "beginner",
            "moderate": "intermediate",
            "intense": "advanced",
        }
        suggested_fitness_level = intensity_to_fitness.get(intensity_key, "intermediate")

        # CRITICAL: Enforce fitness level ceiling - user cannot request exercises
        # above their actual fitness level. This prevents beginners from getting
        # advanced exercises just because they selected "intense" workout.
        FITNESS_LEVEL_ORDER = {"beginner": 1, "intermediate": 2, "advanced": 3}
        user_level_rank = FITNESS_LEVEL_ORDER.get(user_fitness_level.lower(), 2)
        suggested_level_rank = FITNESS_LEVEL_ORDER.get(suggested_fitness_level, 2)

        if suggested_level_rank > user_level_rank:
            logger.warning(
                f"[Quick Workout] User {user_fitness_level} requested {intensity_key} intensity. "
                f"Capping exercise selection at user's level to prevent inappropriate exercises."
            )
            rag_fitness_level = user_fitness_level
        else:
            rag_fitness_level = suggested_fitness_level

        logger.info(f"[Quick Workout] Intensity={intensity_key}, user_level={user_fitness_level}, rag_level={rag_fitness_level}")

        # ── FAST, equipment-aware exercise selection ─────────────────────────
        # The chat "quick workout" must be INSTANT. We deliberately DO NOT touch
        # ChromaDB here (it was the 30s hang) — instead we run one indexed SQL
        # query over the exercise library (equipment-aware, so "I want to work
        # out with a hay bale" works), then a hardcoded injury-safe static set as
        # the zero-dependency guarantee. Selection can never return success=False
        # and never blocks on a network round-trip. (RAG personalization stays on
        # the full plan-generation path where latency is acceptable.)
        from services import workout_fallback

        floor = min(exercise_count, 3)
        avoid_set = {n for n in (old_exercise_names or []) if n}
        rag_exercises: list = []

        # Layer 1 — fast SQL from exercise_library_cleaned (equipment-aware).
        try:
            rag_exercises = workout_fallback.sql_exercises(
                db,
                focus_area=focus_area,
                fitness_level=rag_fitness_level,
                count=exercise_count,
                equipment=user_equipment,
                injury_parts=injury_body_parts,
                avoid_names=avoid_set,
            )
            logger.info(f"[Quick Workout] SQL selected {len(rag_exercises)} exercises (fast path)")
        except Exception as e:
            logger.warning(f"[Quick Workout] SQL selection failed ({e}); using static")
            rag_exercises = []

        # Layer 1b — injury⇄focus collision: if the requested focus is starved by
        # injury avoidance / niche equipment, broaden to full_body (keep filters).
        if len(rag_exercises) < floor and focus_area != "full_body":
            try:
                broad = workout_fallback.sql_exercises(
                    db, focus_area="full_body", fitness_level=rag_fitness_level,
                    count=exercise_count, equipment=user_equipment,
                    injury_parts=injury_body_parts, avoid_names=avoid_set,
                )
                rag_exercises = workout_fallback.merge_unique(rag_exercises, broad)
                if broad:
                    logger.info("[Quick Workout] broadened focus→full_body (injury/equipment starvation)")
            except Exception:
                pass

        # Layer 2 — static curated bodyweight set (zero external dependency).
        if len(rag_exercises) < floor:
            static_ex = workout_fallback.static_bodyweight_exercises(
                focus_area=focus_area,
                count=exercise_count,
                injury_parts=injury_body_parts,
                avoid_names=avoid_set,
            )
            rag_exercises = workout_fallback.merge_unique(rag_exercises, static_ex)
            logger.info(f"[Quick Workout] static fallback ensured {len(rag_exercises)} exercises")

        # Cap to requested count. The static layer guarantees a non-empty result
        # for a reasonable request, so there is no success=False path here.
        rag_exercises = rag_exercises[:exercise_count]

        # Get adaptive parameters
        from services.adaptive_workout_service import get_adaptive_workout_service
        adaptive_service = get_adaptive_workout_service(db.client)

        intensity_to_focus = {
            "light": "endurance",
            "moderate": "hypertrophy",
            "intense": "strength",
        }
        workout_focus = intensity_to_focus.get(intensity_key, "hypertrophy")

        try:
            adaptive_params = run_async_in_sync(
                adaptive_service.get_adaptive_parameters(
                    user_id=user_id,
                    workout_type=workout_focus,
                    user_goals=user_goals,
                ),
                timeout=5
            )
        except Exception:
            adaptive_params = {"sets": 3, "reps": 12, "rest_seconds": 60}

        new_exercises = []
        for ex in rag_exercises:
            exercise_type = "compound" if any(
                compound in ex.get("name", "").lower()
                for compound in ["squat", "deadlift", "bench", "press", "row", "pull-up", "push-up"]
            ) else "isolation"
            rest_time = adaptive_service.get_varied_rest_time(exercise_type, workout_focus)

            new_exercises.append({
                "name": ex.get("name", "Exercise"),
                "sets": adaptive_params["sets"],
                "reps": ex.get("reps", adaptive_params["reps"]),
                "rest_seconds": rest_time,
                "duration_seconds": ex.get("duration_seconds"),
                "muscle_group": ex.get("muscle_group", ex.get("body_part", workout_type_key)),
                "equipment": ex.get("equipment", "Bodyweight"),
                "notes": ex.get("notes", ""),
                "gif_url": ex.get("gif_url", ""),
                "video_url": ex.get("video_url", ""),
                "image_url": ex.get("image_url", ""),
                "library_id": ex.get("library_id", ""),
            })

        # Apply supersets if appropriate
        if adaptive_service.should_use_supersets(workout_focus, duration_minutes, len(new_exercises)):
            new_exercises = adaptive_service.create_superset_pairs(new_exercises)

        # Add AMRAP finisher if appropriate
        if adaptive_service.should_include_amrap(workout_focus, rag_fitness_level):
            amrap_exercise = adaptive_service.create_amrap_finisher(new_exercises, workout_focus)
            new_exercises.append(amrap_exercise)

        # Generate workout name
        intensity_names = {"light": "Easy", "moderate": "Power", "intense": "Intense"}
        type_names = {
            "full_body": "Full Body", "upper": "Upper Body", "lower": "Lower Body",
            "cardio": "Cardio", "core": "Core", "boxing": "Boxing",
            "hyrox": "HYROX", "crossfit": "CrossFit", "hiit": "HIIT",
            "chest": "Chest", "back": "Back", "shoulders": "Shoulders",
            "arms": "Arms", "legs": "Legs",
        }
        workout_name = f"Quick {intensity_names.get(intensity_key, 'Power')} {type_names.get(workout_type_key, workout_type_key.replace('_', ' ').title())}"

        new_exercise_names = [e["name"] for e in new_exercises]
        final_workout_id = workout_id

        if is_new_workout:
            today_utc = datetime.now(timezone.utc).date().isoformat()
            new_workout_data = {
                "user_id": user_id,
                "name": workout_name,
                "type": workout_type_key.replace("_", " "),
                "difficulty": intensity_key,
                "scheduled_date": today_utc,
                "exercises_json": new_exercises,
                "duration_minutes": min(duration_minutes, 90),
                "is_completed": False,
                "generation_method": "ai_quick_workout",
                "generation_source": "chat",
            }
            # Persist with one retry. Supabase is the same reliable DB the whole
            # app uses; a failure here means an app-wide outage, so this is the
            # ONLY remaining non-card path — surface a clear retry, not a silent
            # apology. Selection NEVER causes success=False (resilient ladder).
            created_workout = None
            for _attempt in range(2):
                try:
                    created_workout = db.create_workout(new_workout_data)
                except Exception as ce:
                    logger.warning(f"[Quick Workout] create_workout attempt {_attempt+1} failed: {ce}")
                    created_workout = None
                if created_workout:
                    break
            if created_workout:
                final_workout_id = created_workout.get("id")
            else:
                return {
                    "success": False,
                    "action": "generate_quick_workout",
                    "workout_id": None,
                    "message": "I built your workout but couldn't save it just now — tap to try again.",
                }
        else:
            update_data = {
                "exercises_json": new_exercises,
                "name": workout_name,
                "duration_minutes": min(duration_minutes, 90),
                "difficulty": intensity_key,
                "type": workout_type_key.replace("_", " "),
                "generation_method": "ai_quick_workout"
            }
            db.update_workout(workout_id, update_data)
            final_workout_id = workout_id

        return {
            "success": True,
            "action": "generate_quick_workout",
            "workout_id": final_workout_id,
            "workout_name": workout_name,
            "duration_minutes": min(duration_minutes, 90),
            "workout_type": workout_type_key,
            "intensity": intensity_key,
            "exercises_removed": old_exercise_names,
            "exercises_added": new_exercise_names,
            "exercise_count": len(new_exercises),
            "is_new_workout": is_new_workout,
            "message": f"{'Created' if is_new_workout else 'Updated'} '{workout_name}' - {len(new_exercises)} exercises"
        }

    except Exception as e:
        logger.error(f"Generate quick workout failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "generate_quick_workout",
            "workout_id": workout_id,
            "message": f"Failed to generate quick workout: {str(e)}"
        }


# ─── Proposal layer ──────────────────────────────────────────────────────────
# When the user asks for advice ("any change you recommend?") the Workout
# agent calls propose_workout_change instead of mutating directly. This
# stages the change in chat_pending_proposals and the frontend renders an
# Apply / Not now card. Direct commands ("swap squats for lunges") keep
# using the mutation tools above — they still execute immediately.

_PROPOSAL_ACTIONS = {
    "add_exercise",
    "remove_exercise",
    "replace_exercise",
    "replace_all_exercises",
    "modify_intensity",
    "reschedule",
}


@tool
def propose_workout_change(
    workout_id: str,
    change_summary: str,
    reason: str,
    action: str,
    tool_args: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Propose a workout modification WITHOUT applying it. Use this whenever the
    user asks for advice, suggestions, or recommendations about their workout
    — NEVER describe a change in prose and do nothing, and NEVER mutate
    directly for soft/advisory requests.

    Use the real mutation tools (add_exercise_to_workout /
    remove_exercise_from_workout / replace_all_exercises / etc.) only when
    the user gives an explicit command like "swap squats for lunges".

    Args:
        workout_id: UUID of the workout the proposed change applies to.
        change_summary: Short user-facing line for the Apply card, e.g.
            "Swap Standard Rows → Pendlay Rows".
        reason: One-line rationale shown under the summary.
        action: One of add_exercise, remove_exercise, replace_exercise,
            replace_all_exercises, modify_intensity, reschedule.
        tool_args: Exact JSON args that will be passed to the matching
            mutation tool on apply. Example for a single-exercise swap:
              {"old_exercise": "Barbell Row", "new_exercise": "Pendlay Row",
               "muscle_group": "back"}

    Returns:
        {"success": True, "action": "propose_workout_change",
         "proposal_id": "<uuid>", "proposal_token": "<secret>",
         "summary": ..., "reason": ..., "proposed_action": action,
         "expires_at": "<iso8601>"}
        The proposal_token is required on apply — never log or echo it.
    """
    import secrets

    if not _validate_workout_id(workout_id):
        return {
            "success": False,
            "action": "propose_workout_change",
            "message": f"Invalid workout_id: {workout_id}. Expected a UUID.",
        }

    if action not in _PROPOSAL_ACTIONS:
        return {
            "success": False,
            "action": "propose_workout_change",
            "message": (
                f"Unsupported action: {action}. Must be one of "
                f"{sorted(_PROPOSAL_ACTIONS)}."
            ),
        }

    if not isinstance(tool_args, dict):
        return {
            "success": False,
            "action": "propose_workout_change",
            "message": "tool_args must be a JSON object.",
        }

    if not change_summary or not change_summary.strip():
        return {
            "success": False,
            "action": "propose_workout_change",
            "message": "change_summary is required.",
        }

    logger.info(
        f"Tool: Proposing workout change action={action} workout={workout_id} "
        f"summary={change_summary!r}"
    )

    try:
        db = get_supabase_db()

        workout = db.get_workout(workout_id)
        if not workout:
            return {
                "success": False,
                "action": "propose_workout_change",
                "workout_id": workout_id,
                "message": f"Workout {workout_id} not found.",
            }

        user_id = workout.get("user_id")
        if not user_id:
            return {
                "success": False,
                "action": "propose_workout_change",
                "workout_id": workout_id,
                "message": "Workout has no associated user_id.",
            }

        # 16-byte URL-safe token. Never echoed to logs; only returned to the
        # client so it can be sent back on /apply or /dismiss.
        proposal_token = secrets.token_urlsafe(16)

        row = {
            "user_id": user_id,
            "workout_id": workout_id,
            "action": action,
            "tool_args": tool_args,
            "summary": change_summary.strip(),
            "reason": (reason or "").strip() or None,
            "proposal_token": proposal_token,
            "status": "pending",
        }

        insert_result = (
            db.client.table("chat_pending_proposals").insert(row).execute()
        )
        if not insert_result.data:
            raise RuntimeError("Insert into chat_pending_proposals returned no data")

        inserted = insert_result.data[0]
        proposal_id = inserted["id"]
        expires_at = inserted["expires_at"]

        logger.info(
            f"Tool: Staged proposal {proposal_id} for workout {workout_id} "
            f"(action={action})"
        )

        return {
            "success": True,
            "action": "propose_workout_change",
            "workout_id": workout_id,
            "proposal_id": proposal_id,
            "proposal_token": proposal_token,
            "summary": change_summary.strip(),
            "reason": row["reason"],
            "proposed_action": action,
            "expires_at": expires_at,
        }

    except Exception as e:
        logger.error(f"propose_workout_change failed: {e}", exc_info=True)
        return {
            "success": False,
            "action": "propose_workout_change",
            "workout_id": workout_id,
            "message": f"Failed to stage proposal: {e}",
        }
