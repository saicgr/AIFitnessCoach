"""
Shared utilities and helper functions for workout endpoints.

This module contains common utilities used across workout-related endpoints:
- Database row conversion
- JSON field parsing
- Workout change logging
- RAG indexing
- Date calculations
"""
import json
from datetime import datetime, timedelta
from typing import List, Optional

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


def get_all_equipment(user: dict) -> List[str]:
    """
    Get combined list of standard and custom equipment for a user.

    This merges the predefined equipment the user selected with any custom
    equipment they added (e.g., "homemade pull-up bar", "yoga wheel").

    Args:
        user: User data dict from database

    Returns:
        Combined list of all equipment names (deduplicated)
    """
    standard = parse_json_field(user.get("equipment"), [])
    custom = parse_json_field(user.get("custom_equipment"), [])

    if not isinstance(standard, list):
        standard = []
    if not isinstance(custom, list):
        custom = []

    # Combine and deduplicate (preserve order, standard first)
    all_equipment = list(standard)
    for item in custom:
        if item and item not in all_equipment:
            all_equipment.append(item)

    return all_equipment


def row_to_workout(row: dict) -> Workout:
    """Convert a Supabase row dict to Workout model."""
    exercises_json = row.get("exercises_json") or row.get("exercises")
    if isinstance(exercises_json, list):
        exercises_json = json.dumps(exercises_json)
    elif exercises_json is None:
        exercises_json = "[]"

    # Convert dict/list fields to JSON strings
    generation_metadata = row.get("generation_metadata")
    if isinstance(generation_metadata, (dict, list)):
        generation_metadata = json.dumps(generation_metadata)

    modification_history = row.get("modification_history")
    if isinstance(modification_history, (dict, list)):
        modification_history = json.dumps(modification_history)

    return Workout(
        id=str(row.get("id")),  # Ensure string for UUID
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
        # SCD2 versioning fields
        version_number=row.get("version_number", 1),
        is_current=row.get("is_current", True),
        valid_from=row.get("valid_from"),
        valid_to=row.get("valid_to"),
        parent_workout_id=row.get("parent_workout_id"),
        superseded_by=row.get("superseded_by"),
    )


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
        logger.error(f"Failed to log workout change: {e}")


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
        logger.error(f"Failed to index workout to RAG: {e}")


async def get_recently_used_exercises(user_id: str, days: int = 7) -> List[str]:
    """
    Get list of exercise names used by user in recent workouts.

    This ensures variety by avoiding exercises the user has done recently.

    Args:
        user_id: The user's ID
        days: Number of days to look back (default 7)

    Returns:
        List of exercise names to avoid
    """
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        # Get recent workouts for this user
        response = db.client.table("workouts").select(
            "exercises_json"
        ).eq("user_id", user_id).gte(
            "scheduled_date", cutoff_date
        ).execute()

        if not response.data:
            return []

        # Extract all exercise names from recent workouts
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
        logger.error(f"Error getting recently used exercises: {e}")
        return []


def get_workout_focus(split: str, selected_days: List[int], focus_areas: List[str] = None) -> dict:
    """Return workout focus for each day based on training split.

    For full_body split, we rotate through different emphasis areas to ensure variety
    while still targeting the whole body.

    Supported training programs:
    - full_body: 3-4 days, all muscle groups with rotating emphasis
    - upper_lower: 4 days, alternating upper/lower body
    - push_pull_legs: 3-6 days, classic PPL split
    - phul: 4 days, Power Hypertrophy Upper Lower
    - arnold_split: 6 days, chest/back, shoulders/arms, legs
    - hyrox: 4-5 days, hybrid running + functional fitness
    - bro_split: 5-6 days, one muscle group per day
    - body_part: Legacy support for bro split
    - custom: User-defined focus areas (rotates through selected focus_areas)

    Args:
        split: The training split/program type
        selected_days: List of day indices (0=Monday, 6=Sunday)
        focus_areas: Optional list of focus areas for 'custom' split
    """
    num_days = len(selected_days)

    if split == "full_body":
        # Rotate emphasis to ensure variety even in full-body workouts
        # Each still targets full body but with different primary focus
        full_body_emphases = [
            "full_body_push",   # Emphasis on pushing movements (chest, shoulders, triceps)
            "full_body_pull",   # Emphasis on pulling movements (back, biceps)
            "full_body_legs",   # Emphasis on lower body (legs, glutes)
            "full_body_core",   # Emphasis on core and stability
            "full_body_upper",  # Upper body focused full-body
            "full_body_lower",  # Lower body focused full-body
            "full_body_power",  # Power/explosive movements
        ]
        return {day: full_body_emphases[i % len(full_body_emphases)] for i, day in enumerate(selected_days)}

    elif split == "upper_lower":
        focuses = ["upper", "lower"] * (num_days // 2 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}

    elif split == "push_pull_legs":
        focuses = ["push", "pull", "legs"] * (num_days // 3 + 1)
        return {day: focuses[i] for i, day in enumerate(selected_days)}

    elif split == "phul":
        # PHUL: Power Hypertrophy Upper Lower (4 days)
        # Day 1: Upper Power, Day 2: Lower Power, Day 3: Upper Hypertrophy, Day 4: Lower Hypertrophy
        phul_focuses = [
            "upper_power",       # Heavy compound upper (bench, rows, OHP)
            "lower_power",       # Heavy compound lower (squats, deadlifts)
            "upper_hypertrophy", # Higher rep upper body isolation
            "lower_hypertrophy", # Higher rep leg work
        ]
        return {day: phul_focuses[i % len(phul_focuses)] for i, day in enumerate(selected_days)}

    elif split == "arnold_split":
        # Arnold Split: 6 days, training each muscle group twice
        # Chest/Back, Shoulders/Arms, Legs (repeat)
        arnold_focuses = [
            "chest_back",      # Chest and back together (antagonist pairing)
            "shoulders_arms",  # Shoulders, biceps, triceps
            "legs",            # Full leg day
            "chest_back",      # Second chest/back session
            "shoulders_arms",  # Second shoulders/arms session
            "legs",            # Second leg day
        ]
        return {day: arnold_focuses[i % len(arnold_focuses)] for i, day in enumerate(selected_days)}

    elif split == "hyrox":
        # HYROX: Hybrid fitness racing (running + 8 functional stations)
        # Stations: Ski Erg, Sled Push, Sled Pull, Burpee Broad Jumps, Rowing, Farmers Carry, Sandbag Lunges, Wall Balls
        hyrox_focuses = [
            "hyrox_strength",    # Sled work, farmers carry, sandbag exercises
            "hyrox_running",     # Running intervals + compromised running practice
            "hyrox_stations",    # Station practice (ski erg, rowing, wall balls)
            "hyrox_endurance",   # Long aerobic work + functional conditioning
            "hyrox_simulation",  # Race simulation (run + station + run)
        ]
        return {day: hyrox_focuses[i % len(hyrox_focuses)] for i, day in enumerate(selected_days)}

    elif split == "bro_split" or split == "body_part":
        # Bro Split: One muscle group per day (5-6 days)
        body_parts = [
            "chest",      # Chest day
            "back",       # Back day
            "shoulders",  # Shoulders day
            "legs",       # Leg day
            "arms",       # Biceps and triceps
            "core_cardio" # Core work and light cardio
        ]
        return {day: body_parts[i % len(body_parts)] for i, day in enumerate(selected_days)}

    elif split == "custom":
        # Custom: User defines their own focus areas
        # Rotates through the user's selected focus areas
        if focus_areas and len(focus_areas) > 0:
            # Normalize focus area names to match FOCUS_AREA_KEYWORDS format
            normalized = []
            for fa in focus_areas:
                # Convert "Full Body" -> "full_body", "Chest" -> "chest", etc.
                norm = fa.lower().replace(" ", "_")
                normalized.append(norm)

            # Rotate through user's selected focus areas
            return {day: normalized[i % len(normalized)] for i, day in enumerate(selected_days)}
        else:
            # No focus areas selected - fall back to balanced full body rotation
            logger.warning("Custom split selected but no focus_areas provided, using balanced rotation")
            balanced = ["upper", "lower", "full_body", "push", "pull", "legs"]
            return {day: balanced[i % len(balanced)] for i, day in enumerate(selected_days)}

    elif split == "dont_know" or split is None:
        # User selected "Don't know" - auto-pick best split based on days per week
        # This addresses the "I'll let AI decide" option
        if num_days <= 3:
            # 3 or fewer days: Full body is most efficient
            full_body_emphases = [
                "full_body_push",
                "full_body_pull",
                "full_body_legs",
            ]
            return {day: full_body_emphases[i % len(full_body_emphases)] for i, day in enumerate(selected_days)}
        elif num_days == 4:
            # 4 days: Upper/Lower is ideal balance
            focuses = ["upper", "lower", "upper", "lower"]
            return {day: focuses[i] for i, day in enumerate(selected_days)}
        elif num_days <= 6:
            # 5-6 days: Push/Pull/Legs works well
            focuses = ["push", "pull", "legs"] * 2
            return {day: focuses[i] for i, day in enumerate(selected_days)}
        else:
            # 7 days: Full body with variety
            return {day: "full_body" for day in selected_days}

    # Default to full body if unknown split
    return {day: "full_body" for day in selected_days}


def calculate_workout_date(week_start_date: str, day_index: int) -> datetime:
    """Calculate the actual date for a workout based on week start and day index."""
    base_date = datetime.fromisoformat(week_start_date)
    return base_date + timedelta(days=day_index)


def calculate_monthly_dates(month_start_date: str, selected_days: List[int], weeks: int = 12) -> List[datetime]:
    """Calculate workout dates for specified number of weeks from the start date."""
    base_date = datetime.fromisoformat(month_start_date)
    end_date = base_date + timedelta(days=weeks * 7)

    workout_dates = []
    current_date = base_date

    while current_date < end_date:
        weekday = current_date.weekday()
        if weekday in selected_days:
            workout_dates.append(current_date)
        current_date += timedelta(days=1)

    return workout_dates


def extract_name_words(workout_name: str) -> List[str]:
    """Extract significant words from a workout name."""
    import re
    ignore_words = {'the', 'a', 'an', 'of', 'for', 'and', 'or', 'to', 'workout', 'session'}
    words = re.findall(r'[A-Za-z]{3,}', workout_name.lower())
    return [w for w in words if w not in ignore_words]
