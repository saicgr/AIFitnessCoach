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


def fuzzy_exercise_match(name1: str, name2: str) -> bool:
    """
    Check if two exercise names are similar enough to be considered the same.

    Handles variations like:
    - "Bench Press" vs "Barbell Bench Press"
    - "Squat" vs "Barbell Back Squat"
    - "Pull-up" vs "Pull Up" vs "Pullup"

    Returns True if names are similar enough.
    """
    import re

    # First, normalize compound words (pullup -> pull up, pushup -> push up)
    def expand_compound(name: str) -> str:
        name = name.lower()
        # Common compound variations
        name = re.sub(r'pullup', 'pull up', name)
        name = re.sub(r'pushup', 'push up', name)
        name = re.sub(r'situp', 'sit up', name)
        name = re.sub(r'chinup', 'chin up', name)
        name = re.sub(r'stepup', 'step up', name)
        name = re.sub(r'lunge', 'lunge', name)
        # Remove hyphens
        name = name.replace('-', ' ')
        return name

    # Normalize both names
    def normalize(name: str) -> set:
        # Expand compound words first
        name = expand_compound(name)
        # Remove common prefixes/suffixes
        remove_words = {
            'barbell', 'dumbbell', 'cable', 'machine', 'smith',
            'seated', 'standing', 'incline', 'decline', 'flat',
            'wide', 'narrow', 'close', 'grip', 'overhand', 'underhand',
            'single', 'double', 'one', 'two', 'arm', 'leg',
            'front', 'back', 'rear', 'side', 'lateral',
        }
        # Split into words, remove punctuation
        words = set(re.findall(r'[a-z]+', name))
        # Keep only significant words
        significant = words - remove_words
        return significant if significant else words

    words1 = normalize(name1)
    words2 = normalize(name2)

    # Check if there's significant overlap
    if not words1 or not words2:
        return name1.lower() == name2.lower()

    # Calculate Jaccard similarity
    intersection = len(words1 & words2)
    union = len(words1 | words2)
    similarity = intersection / union if union > 0 else 0

    # Also check if one is a subset of the other
    is_subset = words1.issubset(words2) or words2.issubset(words1)

    # Match if similarity > 0.5 OR one is subset of other
    return similarity > 0.5 or is_subset


async def get_user_strength_history(user_id: str) -> dict:
    """
    Get user's strength history from ALL sources for workout generation.

    Combines data from:
    1. Completed workouts (ChromaDB) - actual workout performance
    2. Imported workout history (Supabase) - manual entries

    Returns:
        Dict mapping exercise names to their historical data:
        {
            "Bench Press": {"last_weight_kg": 70, "max_weight_kg": 85, "last_reps": 8, "source": "completed"},
            "Squat": {"last_weight_kg": 100, "max_weight_kg": 120, "last_reps": 6, "source": "imported"},
        }
    """
    strength_history = {}

    # SOURCE 1: Get from ChromaDB (completed workouts)
    try:
        from services.workout_feedback_rag_service import get_workout_feedback_rag_service
        feedback_rag = get_workout_feedback_rag_service()

        sessions = await feedback_rag.find_similar_exercise_sessions(
            exercise_name="",  # Empty to get all
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

            # Check if this exercise already exists (exact or fuzzy match)
            matched_name = None
            for existing_name in strength_history.keys():
                if existing_name.lower() == name.lower() or fuzzy_exercise_match(existing_name, name):
                    matched_name = existing_name
                    break

            if matched_name:
                # Merge with existing data - prefer completed workout data for last_weight
                # but update max if imported is higher
                if weight > strength_history[matched_name]["max_weight_kg"]:
                    strength_history[matched_name]["max_weight_kg"] = weight
                strength_history[matched_name]["session_count"] += 1
                strength_history[matched_name]["source"] = "both"
            else:
                # New exercise from imports
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


async def get_user_favorite_exercises(user_id: str) -> List[str]:
    """
    Get user's favorite exercise names from the database.

    Returns:
        List of exercise names the user has favorited.
    """
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
        # Table might not exist yet - this is fine
        logger.debug(f"Could not get favorite exercises (table may not exist): {e}")
        return []


async def get_user_consistency_mode(user_id: str) -> str:
    """
    Get user's exercise consistency preference.

    Returns:
        "vary" (default) - Avoid recently used exercises for variety
        "consistent" - Prefer recently used exercises for consistency

    This addresses competitor feedback: "The 'consistent' setting didn't help"
    """
    try:
        db = get_supabase_db()

        user = db.get_user(user_id)
        if not user:
            return "vary"  # Default

        preferences = user.get("preferences", {})
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        # Get the consistency mode from preferences, default to "vary"
        consistency_mode = preferences.get("exercise_consistency", "vary")

        # Validate the value
        if consistency_mode not in ["vary", "consistent"]:
            consistency_mode = "vary"

        logger.debug(f"User {user_id} exercise_consistency mode: {consistency_mode}")
        return consistency_mode

    except Exception as e:
        logger.error(f"Error getting consistency mode: {e}")
        return "vary"  # Default to variety on error


async def get_user_exercise_queue(user_id: str, focus_area: str = None) -> List[dict]:
    """
    Get user's queued exercises for workout generation.

    Args:
        user_id: The user's ID
        focus_area: Optional focus area to filter matching exercises

    Returns:
        List of queued exercises with their details.
        Each exercise has: name, exercise_id, priority, target_muscle_group

    This addresses competitor feedback: "queuing exercises didn't help"
    """
    try:
        db = get_supabase_db()
        now = datetime.now().isoformat()

        # Get active queue items (not expired, not used)
        query = db.client.table("exercise_queue").select(
            "id", "exercise_name", "exercise_id", "priority", "target_muscle_group"
        ).eq("user_id", user_id).is_("used_at", "null").gte("expires_at", now)

        # Filter by focus area if specified
        if focus_area:
            # Include exercises matching this focus area, OR exercises with no target specified
            # We do an OR filter for matching target or null target
            pass  # Supabase doesn't easily support OR, so we'll filter in Python

        result = query.order("priority", desc=False).execute()

        if not result.data:
            return []

        queued = []
        for row in result.data:
            # If focus area specified, filter to matching or unspecified target
            target = row.get("target_muscle_group", "").lower() if row.get("target_muscle_group") else ""

            if focus_area:
                focus_lower = focus_area.lower()
                # Include if target matches focus, or if no target specified
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
        # Table might not exist yet - this is fine
        logger.debug(f"Could not get exercise queue (table may not exist): {e}")
        return []


async def mark_queued_exercises_used(user_id: str, exercise_names: List[str]):
    """
    Mark queued exercises as used after they've been included in a workout.

    Args:
        user_id: The user's ID
        exercise_names: List of exercise names that were used
    """
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


async def get_user_staple_exercises(user_id: str) -> List[str]:
    """
    Get user's staple exercise names from the database.

    Staple exercises are core lifts that should NEVER be rotated out during
    weekly workout variation. Examples: Squat, Bench Press, Deadlift.

    Returns:
        List of exercise names the user has marked as staples.
    """
    try:
        db = get_supabase_db()

        result = db.client.table("staple_exercises").select(
            "exercise_name"
        ).eq("user_id", user_id).execute()

        if not result.data:
            return []

        staples = [row["exercise_name"] for row in result.data]
        logger.info(f"Found {len(staples)} staple exercises for user {user_id}")
        return staples

    except Exception as e:
        # Table might not exist yet - this is fine
        logger.debug(f"Could not get staple exercises (table may not exist): {e}")
        return []


async def get_user_variation_percentage(user_id: str) -> int:
    """
    Get user's exercise variation percentage setting.

    Controls how much exercises change week-to-week:
    - 0% = Same exercises every week (maximum consistency)
    - 30% = Default - rotate about 1/3 of exercises (balanced)
    - 100% = Maximum variety - new exercises every week

    Note: Staple exercises are never affected by this setting.

    Returns:
        Variation percentage (0-100), defaults to 30.
    """
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "variation_percentage"
        ).eq("id", user_id).execute()

        if not result.data:
            return 30  # Default

        percentage = result.data[0].get("variation_percentage", 30)

        # Validate range
        if percentage is None or percentage < 0:
            percentage = 30
        elif percentage > 100:
            percentage = 100

        logger.debug(f"User {user_id} variation_percentage: {percentage}%")
        return percentage

    except Exception as e:
        logger.error(f"Error getting variation percentage: {e}")
        return 30  # Default on error


async def get_user_1rm_data(user_id: str) -> dict:
    """
    Get user's stored 1RMs for percentage-based training.

    This data is used to calculate working weights at the user's
    preferred training intensity (e.g., 70% of 1RM).

    Returns:
        Dict mapping exercise names (lowercase) to 1RM data:
        {
            "bench press": {"one_rep_max_kg": 100.0, "source": "manual", "confidence": 1.0},
            "squat": {"one_rep_max_kg": 140.0, "source": "calculated", "confidence": 0.85},
        }
    """
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
        # Table might not exist yet
        logger.debug(f"Could not get user 1RMs (table may not exist): {e}")
        return {}


async def get_user_training_intensity(user_id: str) -> int:
    """
    Get user's global training intensity preference.

    This is the percentage of 1RM the user wants to train at.
    Values range from 50 (light/recovery) to 100 (max effort).

    Returns:
        Training intensity percentage (50-100), defaults to 75.
    """
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "training_intensity_percent"
        ).eq("id", user_id).execute()

        if not result.data:
            return 75  # Default

        intensity = result.data[0].get("training_intensity_percent", 75)

        # Validate range
        if intensity is None or intensity < 50:
            intensity = 75
        elif intensity > 100:
            intensity = 100

        logger.debug(f"User {user_id} training_intensity: {intensity}%")
        return intensity

    except Exception as e:
        logger.debug(f"Error getting training intensity: {e}")
        return 75  # Default


async def get_user_intensity_overrides(user_id: str) -> dict:
    """
    Get user's per-exercise intensity overrides.

    Returns:
        Dict mapping exercise names (lowercase) to intensity percentages:
        {"bench press": 85, "squat": 70}
    """
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
    """
    Calculate working weight from 1RM and intensity percentage.

    Args:
        one_rep_max_kg: User's 1RM for the exercise
        intensity_percent: Desired training intensity (50-100)
        equipment_type: Type of equipment for rounding

    Returns:
        Working weight rounded to equipment increment
    """
    # Equipment-based weight increments for rounding
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

    # Round to equipment increment
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
    """
    Apply 1RM-based weights to exercises that have known maxes.

    This is the key function for the percentage-based training feature.
    For each exercise with a known 1RM, it calculates the working weight
    based on the user's intensity preference.

    Args:
        exercises: List of exercise dicts from workout generation
        one_rm_data: Dict mapping exercise names (lowercase) to 1RM data
        global_intensity: User's global training intensity (50-100)
        intensity_overrides: Optional dict of per-exercise intensity overrides

    Returns:
        Updated exercises list with calculated weights and weight_source markers
    """
    if not one_rm_data:
        return exercises

    intensity_overrides = intensity_overrides or {}
    updated_exercises = []

    for exercise in exercises:
        exercise_copy = dict(exercise)
        exercise_name = (exercise.get("name") or "").lower()

        # Check if we have a 1RM for this exercise (exact or fuzzy match)
        matched_1rm = None
        matched_name = None

        # First try exact match
        if exercise_name in one_rm_data:
            matched_1rm = one_rm_data[exercise_name]
            matched_name = exercise_name
        else:
            # Try fuzzy matching
            for rm_name, rm_data in one_rm_data.items():
                if fuzzy_exercise_match(exercise_name, rm_name):
                    matched_1rm = rm_data
                    matched_name = rm_name
                    break

        if matched_1rm:
            one_rep_max_kg = matched_1rm.get("one_rep_max_kg", 0)
            if one_rep_max_kg > 0:
                # Get intensity (check for override first)
                intensity = intensity_overrides.get(
                    exercise_name,
                    intensity_overrides.get(matched_name, global_intensity)
                )

                # Determine equipment type for rounding
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

                # Calculate working weight
                working_weight = calculate_working_weight_from_1rm(
                    one_rep_max_kg, intensity, equipment_type
                )

                # Update exercise with calculated weight
                exercise_copy["weight"] = working_weight
                exercise_copy["weight_source"] = "1rm_calculated"
                exercise_copy["one_rep_max_kg"] = one_rep_max_kg
                exercise_copy["intensity_percent"] = intensity

                logger.debug(
                    f"Applied 1RM weight: {exercise_name} - "
                    f"1RM: {one_rep_max_kg}kg @ {intensity}% = {working_weight}kg"
                )

        updated_exercises.append(exercise_copy)

    applied_count = sum(1 for e in updated_exercises if e.get("weight_source") == "1rm_calculated")
    if applied_count > 0:
        logger.info(f"Applied 1RM-based weights to {applied_count}/{len(exercises)} exercises")

    return updated_exercises
