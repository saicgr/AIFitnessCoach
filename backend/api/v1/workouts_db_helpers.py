"""
Shared helpers, utility functions, and Pydantic models for workouts_db endpoints.
"""
import json
from typing import List, Optional
from datetime import datetime, timedelta
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import Workout
from services.gemini_service import GeminiService
from services.rag_service import WorkoutRAGService

logger = get_logger(__name__)

# Initialize workout RAG service (lazy loading)
_workout_rag_service: Optional[WorkoutRAGService] = None


def get_workout_rag_service() -> WorkoutRAGService:
    """Get or create the workout RAG service instance."""
    global _workout_rag_service
    if _workout_rag_service is None:
        gemini_service = GeminiService()
        _workout_rag_service = WorkoutRAGService(gemini_service)
    return _workout_rag_service


def ensure_workout_data_dict(data, context: str = "") -> dict:
    """
    Ensure workout_data is a dict. Handles string, double-stringified, or non-dict inputs.

    Gemini sometimes returns a JSON string instead of a parsed dict, or even a
    double-stringified JSON string. This normalizes all cases to a dict.
    """
    if isinstance(data, dict):
        return data
    if isinstance(data, str) and data:
        # Try up to 3 rounds of json.loads for multi-stringified JSON
        for _ in range(3):
            try:
                data = json.loads(data)
                if isinstance(data, dict):
                    return data
                if not isinstance(data, str):
                    break  # Parsed to non-dict, non-string (e.g., list) — give up
            except (json.JSONDecodeError, ValueError, TypeError):
                break
    prefix = f"[{context}] " if context else ""
    logger.error(f"{prefix}workout_data is not a dict: type={type(data).__name__}, preview={str(data)[:200]}")
    return {}


def parse_json_field(value, default):
    """Parse a field that could be a JSON string or already parsed."""
    if value is None:
        return default
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return default
    return value if isinstance(value, (list, dict)) else default


def normalize_goals_list(goals) -> List[str]:
    """
    Normalize goals to a list of strings.

    Goals can come in various formats from the database:
    - List of strings: ["weight_loss", "muscle_gain"]
    - List of dicts: [{"name": "weight_loss"}, {"goal": "muscle_gain"}]
    - JSON string: '["weight_loss"]'
    - Single string: "weight_loss"
    - None
    """
    if goals is None:
        return []

    # Parse JSON string if needed
    if isinstance(goals, str):
        try:
            goals = json.loads(goals)
        except json.JSONDecodeError:
            return [goals] if goals.strip() else []

    if not isinstance(goals, list):
        return []

    result = []
    for item in goals:
        if isinstance(item, str):
            if item.strip():
                result.append(item.strip())
        elif isinstance(item, dict):
            goal_name = (
                item.get("name") or
                item.get("goal") or
                item.get("title") or
                item.get("value") or
                item.get("id") or
                str(item)
            )
            if goal_name and isinstance(goal_name, str):
                result.append(goal_name.strip())

    return result


async def get_recently_used_exercises(user_id: str, days: int = 7) -> List[str]:
    """Get list of exercise names used by user in recent workouts."""
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        response = db.client.table("workouts").select(
            "exercises_json"
        ).eq("user_id", user_id).gte(
            "scheduled_date", cutoff_date
        ).execute()

        if not response.data:
            return []

        recent_exercises = set()
        for workout in response.data:
            exercises_json = workout.get("exercises_json", [])
            if isinstance(exercises_json, str):
                try:
                    exercises_json = json.loads(exercises_json)
                except json.JSONDecodeError:
                    continue

            for exercise in exercises_json:
                if isinstance(exercise, dict):
                    name = exercise.get("name") or exercise.get("exercise_name")
                    if name:
                        recent_exercises.add(name)

        logger.info(f"Found {len(recent_exercises)} recently used exercises for user {user_id} (last {days} days)")
        return list(recent_exercises)

    except Exception as e:
        logger.error(f"Error getting recently used exercises: {e}", exc_info=True)
        return []


async def index_workout_to_rag(workout: Workout):
    """Index a workout to RAG for retrieval (fire-and-forget)."""
    try:
        rag_service = get_workout_rag_service()
        exercises = json.loads(workout.exercises_json) if isinstance(workout.exercises_json, str) else workout.exercises_json
        scheduled_date = workout.scheduled_date
        if hasattr(scheduled_date, 'isoformat'):
            scheduled_date = scheduled_date.isoformat()
        await rag_service.index_workout(
            workout_id=workout.id,
            user_id=workout.user_id,
            name=workout.name,
            workout_type=workout.type,
            difficulty=workout.difficulty,
            exercises=exercises,
            scheduled_date=str(scheduled_date),
            is_completed=workout.is_completed,
            generation_method=workout.generation_method,
        )
    except Exception as e:
        logger.error(f"Failed to index workout to RAG: {e}", exc_info=True)


def log_workout_change(
    workout_id: str,
    user_id: str,
    change_type: str,
    field_changed: str = None,
    old_value=None,
    new_value=None,
    change_source: str = "api",
    change_reason: str = None
):
    """Log a change to a workout for audit trail."""
    try:
        db = get_supabase_db()
        change_data = {
            "workout_id": workout_id,
            "user_id": user_id,
            "change_type": change_type,
            "field_changed": field_changed,
            "old_value": json.dumps(old_value) if old_value is not None else None,
            "new_value": json.dumps(new_value) if new_value is not None else None,
            "change_source": change_source,
            "change_reason": change_reason,
        }
        db.create_workout_change(change_data)
        logger.debug(f"Logged workout change: workout_id={workout_id}, type={change_type}")
    except Exception as e:
        logger.error(f"Failed to log workout change: {e}", exc_info=True)


def row_to_workout(row: dict) -> Workout:
    """Convert a Supabase row dict to Workout model."""
    exercises_json = row.get("exercises_json") or row.get("exercises")
    if isinstance(exercises_json, list):
        exercises_json = json.dumps(exercises_json)
    elif exercises_json is None:
        exercises_json = "[]"

    # Tag list-path workouts (schedule / workout-tab) with tracking_type +
    # metric_keys so they render the right input columns even when opened from
    # the list rather than /today. Defensive: any failure keeps the original.
    try:
        from services.exercise_tracking_metric import attach_tracking_metadata
        from services.exercise_instructions_resolver import attach_instructions
        _ex_list = json.loads(exercises_json)
        if isinstance(_ex_list, list):
            attach_tracking_metadata(_ex_list)
            attach_instructions(_ex_list)
            exercises_json = json.dumps(_ex_list)
    except Exception:
        pass

    generation_metadata = row.get("generation_metadata")
    if isinstance(generation_metadata, (dict, list)):
        generation_metadata = json.dumps(generation_metadata)

    # Fold program-assignment provenance (migration 2285) into
    # generation_metadata so the workouts-LIST path (schedule + workout tab)
    # carries the same program tags the /today path emits. The list query
    # selects assignment_id / program_slot / template_week as COLUMNS (not
    # inside generation_metadata), so without this merge every program card
    # falls back to the generic type color + "Main" badge — the per-program
    # accent + slot badge + name label only ever lit up on /today.
    # program_id/program_name are resolved client-side from the loaded
    # assignments list (keyed by assignment_id); we only need the id + slot
    # + week here to make WorkoutProgramContext non-null and color-stable.
    _assignment_id = row.get("assignment_id")
    if _assignment_id:
        _meta_obj = {}
        if generation_metadata:
            try:
                _parsed = json.loads(generation_metadata)
                if isinstance(_parsed, dict):
                    _meta_obj = _parsed
            except (ValueError, TypeError):
                _meta_obj = {}
        _meta_obj.setdefault("assignment_id", str(_assignment_id))
        if row.get("program_slot"):
            _meta_obj.setdefault("program_slot", row.get("program_slot"))
        if row.get("template_week") is not None:
            _meta_obj.setdefault("program_week", row.get("template_week"))
        generation_metadata = json.dumps(_meta_obj)

    modification_history = row.get("modification_history")
    if isinstance(modification_history, (dict, list)):
        modification_history = json.dumps(modification_history)

    return Workout(
        id=str(row.get("id")),
        user_id=str(row.get("user_id")),
        name=row.get("name"),
        type=row.get("type"),
        difficulty=row.get("difficulty"),
        scheduled_date=row.get("scheduled_date"),
        is_completed=row.get("is_completed", False),
        exercises_json=exercises_json,
        duration_minutes=row.get("duration_minutes", 45),
        created_at=row.get("created_at"),
        generation_method=row.get("generation_method"),
        generation_source=row.get("generation_source"),
        generation_metadata=generation_metadata,
        generated_at=row.get("generated_at"),
        last_modified_method=row.get("last_modified_method"),
        last_modified_at=row.get("last_modified_at"),
        modification_history=modification_history,
        version_number=row.get("version_number", 1),
        is_current=row.get("is_current", True),
        valid_from=row.get("valid_from"),
        valid_to=row.get("valid_to"),
        parent_workout_id=row.get("parent_workout_id"),
        superseded_by=row.get("superseded_by"),
    )


_VALID_FOCUS_OVERRIDES = {
    "upper", "lower", "full_body", "push", "pull", "legs",
    "chest", "back", "shoulders", "arms", "core",
}


def get_workout_focus(
    split: str,
    selected_days: List[int],
    day_focus_override: Optional[dict] = None,
) -> dict:
    """Return workout focus for each day based on training split.

    `day_focus_override` is an optional dict from the active gym profile's
    `day_focus_override` JSONB column. When the user pinned a specific focus
    to a weekday (only meaningful for split=='dont_know' aka "Let AI Decide"),
    that pin wins over the heuristic. Pinned values are validated against
    `_VALID_FOCUS_OVERRIDES` so a malformed payload from an old/forked client
    can't poison the generation prompt.
    """
    overrides: dict = {}
    if day_focus_override:
        for k, v in day_focus_override.items():
            try:
                day_int = int(k)
            except (TypeError, ValueError):
                continue
            if isinstance(v, str) and v.lower() in _VALID_FOCUS_OVERRIDES:
                overrides[day_int] = v.lower()

    num_days = len(selected_days)

    # Apply overrides only for the AI-Decide split — other splits have
    # deterministic mappings the user explicitly opted into.
    apply_overrides = overrides and (split == "dont_know" or split is None)

    def _maybe_override(day: int, default: str) -> str:
        return overrides[day] if apply_overrides and day in overrides else default

    if split == "full_body":
        full_body_emphases = [
            "full_body_push", "full_body_pull", "full_body_legs",
            "full_body_core", "full_body_upper", "full_body_lower", "full_body_power",
        ]
        return {day: full_body_emphases[i % len(full_body_emphases)] for i, day in enumerate(selected_days)}
    elif split == "upper_lower":
        focuses = ["upper", "lower"] * (num_days // 2 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}
    elif split == "push_pull_legs":
        focuses = ["push", "pull", "legs"] * (num_days // 3 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}
    elif split == "body_part":
        body_parts = ["chest", "back", "shoulders", "legs", "arms", "core"]
        return {day: body_parts[i % len(body_parts)] for i, day in enumerate(selected_days)}
    elif split == "dont_know" or split is None:
        # AI-Decide split: respect per-day pins where present, fall back to
        # the heuristic for unpinned days. This is the only split that
        # honours `day_focus_override` (other splits have deterministic
        # mappings the user explicitly opted into).
        if num_days <= 3:
            full_body_emphases = ["full_body_push", "full_body_pull", "full_body_legs"]
            return {
                day: _maybe_override(day, full_body_emphases[i % len(full_body_emphases)])
                for i, day in enumerate(selected_days)
            }
        elif num_days == 4:
            focuses = ["upper", "lower", "upper", "lower"]
            return {
                day: _maybe_override(day, focuses[i])
                for i, day in enumerate(selected_days)
            }
        elif num_days <= 6:
            focuses = ["push", "pull", "legs"] * 2
            return {
                day: _maybe_override(day, focuses[i])
                for i, day in enumerate(selected_days)
            }
        else:
            return {day: _maybe_override(day, "full_body") for day in selected_days}

    return {day: "full_body" for day in selected_days}


# ==================== Pydantic Models ====================

class WorkoutSuggestionRequest(BaseModel):
    """Request for AI workout suggestions."""
    workout_id: str
    user_id: str
    current_workout_type: Optional[str] = None
    prompt: Optional[str] = None


class WorkoutSuggestion(BaseModel):
    """A single workout suggestion."""
    name: str
    type: str
    difficulty: str
    duration_minutes: int
    description: str
    focus_areas: List[str]
    sample_exercises: List[str] = []


class WorkoutSuggestionsResponse(BaseModel):
    """Response with workout suggestions."""
    suggestions: List[WorkoutSuggestion]


# ==================== Reasoning Builders ====================

def build_exercise_reasoning(
    exercise_name: str,
    muscle_group: str,
    equipment: str,
    sets: int,
    reps: str,
    workout_type: str,
    difficulty: str,
    user_goals: list,
    user_fitness_level: str,
    user_equipment: list,
) -> str:
    """Build reasoning explanation for why an exercise was selected."""
    reasons = []

    if muscle_group:
        reasons.append(f"Targets {muscle_group} effectively")

    if equipment:
        equipment_lower = equipment.lower()
        if equipment_lower in ["bodyweight", "none", "body weight"]:
            reasons.append("Requires no equipment - great for home workouts")
        elif user_equipment and any(eq.lower() in equipment_lower for eq in user_equipment):
            reasons.append(f"Matches your available equipment ({equipment})")
        else:
            reasons.append(f"Uses {equipment}")

    goal_map = {
        "muscle_gain": ["compound movement for muscle growth", "builds strength and size"],
        "weight_loss": ["burns calories efficiently", "elevates heart rate"],
        "strength": ["develops maximal strength", "progressive overload focused"],
        "endurance": ["builds muscular endurance", "higher rep scheme"],
        "flexibility": ["improves range of motion", "dynamic movement"],
        "general_fitness": ["well-rounded exercise", "functional movement pattern"],
    }
    for goal in user_goals:
        if goal.lower().replace(" ", "_") in goal_map:
            reasons.append(goal_map[goal.lower().replace(" ", "_")][0])
            break

    if isinstance(reps, str) and "-" in reps:
        reasons.append(f"{sets} sets of {reps} reps for optimal stimulus")
    elif isinstance(reps, int) or (isinstance(reps, str) and reps.isdigit()):
        reps_int = int(reps) if isinstance(reps, str) else reps
        if reps_int <= 5:
            reasons.append(f"Low rep range ({sets}x{reps}) for strength focus")
        elif reps_int <= 12:
            reasons.append(f"{sets}x{reps} in hypertrophy range for muscle growth")
        else:
            reasons.append(f"Higher reps ({sets}x{reps}) for endurance and conditioning")

    if difficulty:
        difficulty_lower = difficulty.lower()
        if difficulty_lower == "beginner":
            reasons.append("Beginner-friendly movement pattern")
        elif difficulty_lower == "advanced":
            reasons.append("Challenging variation for advanced trainees")

    return ". ".join(reasons) if reasons else "Selected to complement your workout program"


def build_workout_reasoning(
    workout_name: str,
    workout_type: str,
    difficulty: str,
    target_muscles: list,
    exercise_count: int,
    duration_minutes: int,
    user_goals: list,
    user_fitness_level: str,
    training_split: str = None,
) -> str:
    """Build overall reasoning for the workout design."""
    parts = []

    type_explanations = {
        "strength": "This strength-focused workout emphasizes compound movements and progressive overload",
        "hypertrophy": "This hypertrophy workout is designed to maximize muscle growth through optimal volume",
        "cardio": "This cardio session elevates heart rate for cardiovascular health and calorie burn",
        "hiit": "This high-intensity interval training alternates intense bursts with recovery periods",
        "endurance": "This endurance workout builds stamina and muscular endurance",
        "flexibility": "This flexibility session improves mobility and range of motion",
        "full_body": "This full-body workout hits all major muscle groups in one session",
        "upper_body": "This upper body session targets chest, back, shoulders, and arms",
        "lower_body": "This lower body workout focuses on quads, hamstrings, glutes, and calves",
        "push": "This push workout targets chest, shoulders, and triceps",
        "pull": "This pull workout targets back, biceps, and rear delts",
        "legs": "This leg day focuses on quadriceps, hamstrings, glutes, and calves",
    }
    workout_type_lower = workout_type.lower().replace(" ", "_")
    if workout_type_lower in type_explanations:
        parts.append(type_explanations[workout_type_lower])
    else:
        parts.append(f"This {workout_type} workout is designed for balanced training")

    if training_split:
        split_names = {
            "full_body": "full body split (training all muscles each session)",
            "upper_lower": "upper/lower split (alternating focus)",
            "push_pull_legs": "push/pull/legs split (organized by movement pattern)",
            "bro_split": "body part split (one muscle group per day)",
        }
        split_lower = training_split.lower().replace(" ", "_")
        if split_lower in split_names:
            parts.append(f"Following your {split_names[split_lower]}")

    if target_muscles:
        muscles_str = ", ".join(target_muscles[:3])
        if len(target_muscles) > 3:
            muscles_str += f" and {len(target_muscles) - 3} more"
        parts.append(f"Primary targets: {muscles_str}")

    if user_goals:
        goals_str = ", ".join(user_goals[:2])
        parts.append(f"Aligned with your goals: {goals_str}")

    parts.append(f"{exercise_count} exercises in approximately {duration_minutes} minutes")

    if user_fitness_level:
        level_lower = user_fitness_level.lower()
        if level_lower == "beginner":
            parts.append("Designed for beginners with fundamental movements")
        elif level_lower == "intermediate":
            parts.append("Intermediate difficulty with progressive challenges")
        elif level_lower == "advanced":
            parts.append("Advanced training with complex movements and higher intensity")

    return ". ".join(parts) + "."
