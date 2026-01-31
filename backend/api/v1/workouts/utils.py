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
from typing import List, Optional, Dict, Any

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


def normalize_goals_list(goals) -> List[str]:
    """
    Normalize goals to a list of strings.

    Goals can come in various formats from the database:
    - List of strings: ["weight_loss", "muscle_gain"]
    - List of dicts: [{"name": "weight_loss"}, {"goal": "muscle_gain"}]
    - JSON string: '["weight_loss"]'
    - Single string: "weight_loss"
    - None

    This function handles all cases and returns a clean list of strings.

    Args:
        goals: Raw goals data from database or API

    Returns:
        List of goal strings
    """
    if goals is None:
        return []

    # Parse JSON string if needed
    if isinstance(goals, str):
        try:
            goals = json.loads(goals)
        except json.JSONDecodeError:
            # Single goal string
            return [goals] if goals.strip() else []

    # Not a list - return empty
    if not isinstance(goals, list):
        return []

    # Normalize each item in the list
    result = []
    for item in goals:
        if isinstance(item, str):
            if item.strip():
                result.append(item.strip())
        elif isinstance(item, dict):
            # Try common dict keys for goal name
            goal_name = (
                item.get("name") or
                item.get("goal") or
                item.get("title") or
                item.get("value") or
                item.get("id") or
                str(item)  # Fallback to string representation
            )
            if goal_name and isinstance(goal_name, str):
                result.append(goal_name.strip())
        # Skip other types (int, float, etc.)

    return result


def get_intensity_from_fitness_level(fitness_level: Optional[str]) -> str:
    """
    Derive workout intensity/difficulty from user's fitness level.

    This ensures beginners get 'easy' workouts, not 'medium'.
    Should be used when intensity_preference is not explicitly set.

    Args:
        fitness_level: User's fitness level (beginner, intermediate, advanced)

    Returns:
        Appropriate intensity: 'easy', 'medium', or 'hard'
    """
    if not fitness_level:
        return "medium"  # Default for unknown fitness level

    level_lower = fitness_level.lower().strip()
    if level_lower == "beginner":
        return "easy"
    elif level_lower == "advanced":
        return "hard"
    else:
        return "medium"  # intermediate or unknown


def resolve_training_split(split: Optional[str], num_days: int) -> str:
    """
    Resolve 'dont_know' to an actual training split based on workout days.

    When user selects "Don't know" / "Let AI decide", we auto-pick the best
    split based on how many days per week they train.

    Args:
        split: The stored training split (may be 'dont_know')
        num_days: Number of workout days per week

    Returns:
        Resolved split name (never returns 'dont_know')
    """
    if split and split.lower() != "dont_know":
        return split  # Already a specific split

    # Auto-pick based on days per week
    if num_days <= 3:
        return "full_body"  # Most efficient for low frequency
    elif num_days == 4:
        return "upper_lower"  # Classic 4-day split
    elif num_days <= 6:
        return "push_pull_legs"  # PPL for 5-6 days
    else:
        return "full_body"  # 7 days - full body rotation


def infer_workout_type_from_focus(focus_area: str, exercises: List[Dict] = None) -> str:
    """
    Infer workout type from focus area for PPL tracking.

    This maps focus areas to workout types so the PPL rotation system
    can track which workout types have been completed.

    Maps:
        - push/chest/shoulders/triceps -> "push"
        - pull/back/biceps -> "pull"
        - legs/lower/glutes/quads/hamstrings -> "legs"
        - full_body* -> "full_body"
        - upper* -> "upper"
        - core/abs -> "core"

    Args:
        focus_area: The focus area string (e.g., "push", "chest", "legs")
        exercises: Optional list of exercises (for future muscle-based inference)

    Returns:
        Workout type string for PPL tracking
    """
    if not focus_area:
        return "strength"

    focus_lower = focus_area.lower().replace(" ", "_").replace("-", "_")

    # Check for full_body variants first (most specific match)
    if "full" in focus_lower and "body" in focus_lower:
        return "full_body"

    # Mapping from focus area keywords to workout types
    type_mapping = {
        # Push muscles
        "push": "push",
        "chest": "push",
        "shoulders": "push",
        "shoulder": "push",
        "triceps": "push",
        "tricep": "push",
        # Pull muscles
        "pull": "pull",
        "back": "pull",
        "biceps": "pull",
        "bicep": "pull",
        "lats": "pull",
        # Leg muscles
        "legs": "legs",
        "leg": "legs",
        "lower": "legs",
        "glutes": "legs",
        "glute": "legs",
        "quads": "legs",
        "quad": "legs",
        "hamstrings": "legs",
        "hamstring": "legs",
        "calves": "legs",
        "calf": "legs",
        # Other types
        "core": "core",
        "abs": "core",
        "abdominals": "core",
        "upper": "upper",
        "arms": "arms",
        "cardio": "cardio",
        "hiit": "cardio",
    }

    for key, workout_type in type_mapping.items():
        if key in focus_lower:
            return workout_type

    # Default to strength if no match found
    return "strength"


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


def enrich_exercises_with_video_urls(exercises: List[Dict], db=None) -> List[Dict]:
    """
    Enrich exercises with video/image URLs from the exercise library.

    This function looks up each exercise by name in the exercise_library_cleaned view
    and populates gif_url, video_url, and image_s3_path if missing.

    Args:
        exercises: List of exercise dictionaries
        db: Optional Supabase database connection (will create if not provided)

    Returns:
        List of exercises with media URLs populated
    """
    if not exercises:
        return exercises

    # Get database connection
    if db is None:
        db = get_supabase_db()

    # Get unique exercise names (normalized for lookup)
    exercise_names = []
    name_mapping = {}  # lowercase -> original case
    for ex in exercises:
        name = ex.get("name", "")
        if name:
            normalized = name.lower().strip()
            exercise_names.append(normalized)
            name_mapping[normalized] = name

    if not exercise_names:
        return exercises

    try:
        # Fetch media URLs from exercise_library_cleaned view
        # image_url in the view is from image_s3_path column
        result = db.client.table("exercise_library_cleaned").select(
            "name, gif_url, video_url, image_url"
        ).execute()

        if not result.data:
            logger.debug("No exercises found in library for media enrichment")
            return exercises

        # Build a lookup map (lowercase name -> urls)
        url_map = {}
        for row in result.data:
            lib_name = (row.get("name") or "").lower().strip()
            if lib_name:
                url_map[lib_name] = {
                    "gif_url": row.get("gif_url"),
                    "video_url": row.get("video_url"),
                    "image_s3_path": row.get("image_url"),  # Map image_url to image_s3_path
                }

        # Enrich exercises
        enriched_count = 0
        for ex in exercises:
            ex_name = (ex.get("name") or "").lower().strip()
            if ex_name in url_map:
                urls = url_map[ex_name]
                # Only set if not already present
                if not ex.get("gif_url") and urls.get("gif_url"):
                    ex["gif_url"] = urls["gif_url"]
                    enriched_count += 1
                if not ex.get("video_url") and urls.get("video_url"):
                    ex["video_url"] = urls["video_url"]
                    enriched_count += 1
                if not ex.get("image_s3_path") and urls.get("image_s3_path"):
                    ex["image_s3_path"] = urls["image_s3_path"]
                    enriched_count += 1

        if enriched_count > 0:
            logger.info(f"✅ Enriched {enriched_count} exercise media URLs from library")

    except Exception as e:
        logger.warning(f"⚠️ Failed to enrich exercises with media URLs: {e}")
        # Don't fail - just return exercises without enrichment

    return exercises


def row_to_workout(row: dict, enrich_videos: bool = True) -> Workout:
    """Convert a Supabase row dict to Workout model.

    Args:
        row: Database row dictionary
        enrich_videos: If True, enrich exercises with video URLs from library (default: True)
    """
    exercises_json = row.get("exercises_json") or row.get("exercises")

    # Parse exercises and enrich with video URLs
    if isinstance(exercises_json, str):
        try:
            exercises_list = json.loads(exercises_json)
        except json.JSONDecodeError:
            exercises_list = []
    elif isinstance(exercises_json, list):
        exercises_list = exercises_json
    else:
        exercises_list = []

    # Enrich exercises with video URLs from library
    if enrich_videos and exercises_list:
        exercises_list = enrich_exercises_with_video_urls(exercises_list)

    # Convert back to JSON string
    exercises_json = json.dumps(exercises_list) if exercises_list else "[]"

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


async def get_user_personal_bests(user_id: str) -> Dict[str, Dict]:
    """
    Get user's personal records (PRs) per exercise from the personal_records table.

    This provides the user's all-time best performance for each exercise,
    which can be used to personalize workout notes and motivate users.

    Returns:
        Dict mapping exercise names to their PRs:
        {
            "Bench Press": {"weight": 85.0, "reps": 8, "1rm": 104.5, "achieved_at": "2025-01-03"},
            "Squat": {"weight": 120.0, "reps": 5, "1rm": 135.0, "achieved_at": "2025-01-01"},
        }
    """
    prs: Dict[str, Dict] = {}

    try:
        db = get_supabase_db()

        result = db.client.table("personal_records").select(
            "exercise_name, record_type, record_value, achieved_at"
        ).eq("user_id", user_id).order("achieved_at", desc=True).execute()

        for row in result.data or []:
            name = row.get("exercise_name")
            record_type = row.get("record_type")  # 'weight', 'reps', '1rm', 'time', 'distance'
            value = row.get("record_value")

            if not name or value is None:
                continue

            if name not in prs:
                prs[name] = {}

            # Store by record type (weight, reps, 1rm, etc.)
            prs[name][record_type] = value

            # Store achieved_at from the most recent record
            achieved_at = row.get("achieved_at", "")
            if achieved_at and "achieved_at" not in prs[name]:
                prs[name]["achieved_at"] = str(achieved_at)[:10]

        logger.info(f"Found PRs for {len(prs)} exercises for user {user_id}")

    except Exception as e:
        # Table might not exist or user has no PRs - this is fine
        logger.debug(f"Could not get personal bests (may not exist yet): {e}")

    return prs


def format_performance_context(
    exercises: List[Dict],
    strength_history: Dict[str, Dict],
    personal_bests: Dict[str, Dict],
) -> str:
    """
    Format last session + PR data for selected exercises into Gemini context.

    This creates a human-readable summary of the user's performance history
    that can be included in the Gemini prompt for personalized workout notes.

    Args:
        exercises: List of exercise dicts with 'name' field
        strength_history: Dict from get_user_strength_history()
        personal_bests: Dict from get_user_personal_bests()

    Returns:
        String like:
        "Performance history for selected exercises:
        - Bench Press: Last session 75kg x 8 reps | PR: 85kg
        - Squat: Last session 100kg x 6 reps | PR: 120kg"
    """
    if not exercises:
        return ""

    lines = []

    for ex in exercises:
        name = ex.get("name", "") if isinstance(ex, dict) else str(ex)
        if not name:
            continue

        parts = []

        # Last session data from strength_history
        hist = strength_history.get(name) or {}
        last_weight = hist.get("last_weight_kg", 0)
        last_reps = hist.get("last_reps", 0)
        max_weight = hist.get("max_weight_kg", 0)

        if last_weight > 0:
            if last_reps > 0:
                parts.append(f"Last: {last_weight}kg x {last_reps} reps")
            else:
                parts.append(f"Last: {last_weight}kg")

        # Personal best from personal_bests
        pr = personal_bests.get(name) or {}
        pr_weight = pr.get("weight", 0)
        pr_1rm = pr.get("1rm", 0)

        if pr_weight and pr_weight > 0:
            parts.append(f"PR: {pr_weight}kg")
        elif pr_1rm and pr_1rm > 0:
            parts.append(f"1RM: {pr_1rm}kg")
        elif max_weight > 0 and max_weight > last_weight:
            # Fallback to max from strength_history if no PR table entry
            parts.append(f"Max: {max_weight}kg")

        if parts:
            lines.append(f"- {name}: {' | '.join(parts)}")

    if not lines:
        return ""

    return "Performance history for selected exercises:\n" + "\n".join(lines)


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


async def get_user_staple_exercises(user_id: str) -> List[dict]:
    """
    Get user's staple exercises with reasons from the database.

    Staple exercises are core lifts that should NEVER be rotated out during
    weekly workout variation. Examples: Squat, Bench Press, Deadlift.

    Returns:
        List of dicts with exercise_name, reason, and muscle_group.
        Reason can be: 'core_compound', 'favorite', 'rehab', 'strength_focus', 'other'
    """
    try:
        db = get_supabase_db()

        result = db.client.table("staple_exercises").select(
            "exercise_name, reason, muscle_group"
        ).eq("user_id", user_id).execute()

        if not result.data:
            return []

        staples = [
            {
                "name": row["exercise_name"],
                "reason": row.get("reason", "favorite"),
                "muscle_group": row.get("muscle_group"),
            }
            for row in result.data
        ]
        logger.info(f"Found {len(staples)} staple exercises for user {user_id}: {[s['name'] for s in staples]}")
        return staples

    except Exception as e:
        # Table might not exist yet - this is fine
        logger.debug(f"Could not get staple exercises (table may not exist): {e}")
        return []


def get_staple_names(staples: List[dict]) -> List[str]:
    """Extract just the exercise names from staple exercises list."""
    return [s["name"] for s in staples] if staples else []


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

                # Also update setTargets weights if present (for per-set AI targets)
                if "set_targets" in exercise_copy and exercise_copy["set_targets"]:
                    for set_target in exercise_copy["set_targets"]:
                        set_type = set_target.get("set_type", "working")
                        if set_type == "warmup":
                            # Warmup sets at 50% of working weight
                            set_target["target_weight_kg"] = round(working_weight * 0.5, 1)
                        elif set_type == "drop":
                            # Drop sets at 80% of working weight
                            set_target["target_weight_kg"] = round(working_weight * 0.8, 1)
                        else:
                            # Working/failure/amrap sets at full working weight
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
    """
    Get list of exercise names the user wants to avoid.

    Only returns active avoidances (not expired temporary ones).

    Returns:
        List of exercise names to avoid (lowercase for matching).
    """
    try:
        db = get_supabase_db()

        # Use the database function that filters for active avoidances
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
    """
    Get muscle groups the user wants to avoid or reduce.

    Only returns active avoidances (not expired temporary ones).

    Returns:
        Dict with two keys:
        - 'avoid': List of muscle groups to completely avoid
        - 'reduce': List of muscle groups to use less often
    """
    try:
        db = get_supabase_db()

        # Use the database function that filters for active avoidances
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
    """
    Get user's progression pace preference.

    Progression pace controls:
    - slow: Conservative weight increases, more reps before adding weight
    - medium: Standard progression (default)
    - fast: Aggressive weight increases for experienced lifters

    Returns:
        Progression pace: "slow", "medium", or "fast". Defaults to "medium".
    """
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "preferences"
        ).eq("id", user_id).execute()

        if not result.data:
            return "medium"  # Default

        preferences = result.data[0].get("preferences") or {}
        if isinstance(preferences, str):
            import json
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        pace = preferences.get("progression_pace", "medium")

        # Validate pace value
        valid_paces = ["slow", "medium", "fast"]
        if pace not in valid_paces:
            pace = "medium"

        logger.debug(f"User {user_id} progression_pace: {pace}")
        return pace

    except Exception as e:
        logger.debug(f"Could not get progression pace: {e}")
        return "medium"  # Default


async def get_user_workout_type_preference(user_id: str) -> str:
    """
    Get user's workout type preference.

    Workout type controls:
    - strength: Focus on heavy compound lifts, lower reps
    - cardio: Focus on cardiovascular exercises, HIIT
    - mixed: Balanced approach with both strength and cardio
    - mobility: Focus on flexibility and mobility work
    - recovery: Light exercises for active recovery

    Returns:
        Workout type: "strength", "cardio", "mixed", "mobility", or "recovery".
        Defaults to "strength".
    """
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "preferences"
        ).eq("id", user_id).execute()

        if not result.data:
            return "strength"  # Default

        preferences = result.data[0].get("preferences") or {}
        if isinstance(preferences, str):
            import json
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        workout_type = preferences.get("workout_type_preference", "strength")

        # Validate workout type
        valid_types = ["strength", "cardio", "mixed", "mobility", "recovery"]
        if workout_type not in valid_types:
            workout_type = "strength"

        logger.debug(f"User {user_id} workout_type_preference: {workout_type}")
        return workout_type

    except Exception as e:
        logger.debug(f"Could not get workout type preference: {e}")
        return "strength"  # Default


async def get_substitute_exercise(
    exercise_name: str,
    muscle_group: str,
    user_id: str,
    avoided_exercises: List[str],
    equipment: List[str] = None,
) -> Optional[dict]:
    """
    Find a substitute for an exercise that was filtered out due to user preferences.

    This function searches the exercise library for a suitable replacement that:
    1. Targets the same muscle group
    2. Is not in the user's avoided exercises list
    3. Preferably uses equipment the user has access to

    Args:
        exercise_name: The name of the exercise being replaced
        muscle_group: The muscle group the exercise targets
        user_id: The user ID for filtering
        avoided_exercises: List of exercise names to avoid
        equipment: Optional list of equipment the user has

    Returns:
        A dict with substitute exercise info, or None if no substitute found
    """
    try:
        db = get_supabase_db()

        # Normalize for matching
        avoided_lower = [ae.lower() for ae in avoided_exercises]

        # Query the exercise library for exercises targeting the same muscle
        query = db.client.table("exercise_library_cleaned").select(
            "name, target_muscle, body_part, equipment, secondary_muscles"
        ).or_(
            f"target_muscle.ilike.%{muscle_group}%,body_part.ilike.%{muscle_group}%"
        ).limit(50)

        result = query.execute()

        if not result.data:
            logger.debug(f"No exercises found for muscle group: {muscle_group}")
            return None

        # Filter out avoided exercises and the original exercise
        candidates = []
        original_lower = exercise_name.lower()

        for ex in result.data:
            ex_name = ex.get("name", "")
            if ex_name.lower() == original_lower:
                continue
            if ex_name.lower() in avoided_lower:
                continue

            # Score the candidate based on equipment match
            score = 0
            ex_equipment = (ex.get("equipment") or "").lower()

            if equipment:
                equipment_lower = [e.lower() for e in equipment]
                has_gym_equipment = any(eq in equipment_lower for eq in ["full_gym", "dumbbells", "barbell", "cable_machine", "machines"])

                if ex_equipment in equipment_lower:
                    # Direct equipment match gets highest score
                    score += 20
                elif has_gym_equipment and ex_equipment in ["dumbbell", "dumbbells", "barbell", "cable", "machine"]:
                    # Gym equipment gets high score when user has gym access
                    score += 15
                elif ex_equipment == "body weight":
                    # Bodyweight gets lower score when gym equipment is available
                    score += 5 if has_gym_equipment else 10
            else:
                # If no equipment specified, prefer bodyweight
                if ex_equipment == "body weight":
                    score += 5

            candidates.append((score, ex))

        if not candidates:
            logger.debug(f"No valid substitutes found for {exercise_name} (muscle: {muscle_group})")
            return None

        # Sort by score and take the best match
        candidates.sort(key=lambda x: x[0], reverse=True)
        best_match = candidates[0][1]

        logger.info(f"🔄 [Auto-Substitute] Replaced '{exercise_name}' with '{best_match.get('name')}'")

        return {
            "name": best_match.get("name"),
            "muscle_group": best_match.get("target_muscle") or best_match.get("body_part"),
            "equipment": best_match.get("equipment"),
            "sets": 3,  # Default
            "reps": "10",  # Default
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
    """
    Automatically find substitutes for exercises that were filtered out.

    This maintains the workout structure by replacing filtered exercises
    with safe alternatives targeting the same muscle groups.

    Args:
        exercises: The current list of exercises (after filtering)
        filtered_exercises: Exercises that were removed due to user preferences
        user_id: The user ID
        avoided_exercises: List of exercise names to avoid
        equipment: Optional list of user's equipment

    Returns:
        Updated exercises list with substitutes added
    """
    substitutes_added = 0
    existing_names = {ex.get("name", "").lower() for ex in exercises}

    for filtered_ex in filtered_exercises:
        ex_name = filtered_ex.get("name", "")
        muscle_group = filtered_ex.get("muscle_group", "")

        if not muscle_group:
            # Try to infer muscle group from body_part or primary_muscle
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
                # Copy relevant fields from original exercise
                substitute["sets"] = filtered_ex.get("sets", 3)
                substitute["reps"] = filtered_ex.get("reps", "10")
                substitute["rest_seconds"] = filtered_ex.get("rest_seconds", 60)

                exercises.append(substitute)
                existing_names.add(substitute.get("name", "").lower())
                substitutes_added += 1

    if substitutes_added > 0:
        logger.info(f"✅ [Auto-Substitute] Added {substitutes_added} substitute exercises")

    return exercises


# =============================================================================
# AI CONSISTENCY HELPERS - Readiness, Mood, Injury-to-Muscle Mapping
# =============================================================================

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
    """
    Get the user's latest readiness score from the database.

    Readiness scores indicate how ready the user is for training:
    - Low (< 50): User should do lighter workouts, recovery-focused
    - Medium (50-70): Normal training intensity
    - High (> 70): User is well-recovered, can handle intense workouts

    Args:
        user_id: The user's ID

    Returns:
        Readiness score (0-100) or None if not available
    """
    try:
        db = get_supabase_db()

        # Get most recent readiness score
        result = db.client.table("readiness") \
            .select("score, created_at") \
            .eq("user_id", user_id) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()

        if result.data and len(result.data) > 0:
            score = result.data[0].get("score")
            created_at = result.data[0].get("created_at", "")

            # Check if score is recent (within last 24 hours)
            if created_at:
                from datetime import datetime
                try:
                    score_time = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                    age_hours = (datetime.now(score_time.tzinfo) - score_time).total_seconds() / 3600

                    if age_hours > 24:
                        logger.info(f"🔍 [Readiness] Score for user {user_id} is {age_hours:.1f} hours old, may be stale")
                except Exception:
                    pass

            logger.info(f"✅ [Readiness] User {user_id} readiness score: {score}")
            return score

        logger.debug(f"[Readiness] No readiness score found for user {user_id}")
        return None

    except Exception as e:
        logger.error(f"❌ [Readiness] Error getting readiness score for user {user_id}: {e}")
        return None


async def get_user_latest_mood(user_id: str) -> Optional[dict]:
    """
    Get the user's latest mood check-in from today.

    Mood affects workout recommendations:
    - "great": Can handle challenging workouts
    - "good": Normal intensity
    - "tired": Suggest lighter workout or recovery session
    - "stressed": Suggest stress-relief exercises, breathing work

    Args:
        user_id: The user's ID

    Returns:
        Dict with mood info or None if no recent check-in:
        {"mood": "tired", "check_in_time": "2024-01-15T08:00:00Z"}
    """
    try:
        db = get_supabase_db()

        # Get today's mood check-in (use today_mood_checkin view if available, otherwise query directly)
        try:
            result = db.client.table("today_mood_checkin") \
                .select("mood, check_in_time") \
                .eq("user_id", user_id) \
                .limit(1) \
                .execute()
        except Exception:
            # Fallback: Query mood_checkins table directly for today
            from datetime import datetime
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
    """
    Convert injury body parts to muscles that should be avoided.

    Uses INJURY_TO_AVOIDED_MUSCLES mapping to determine which muscle groups
    should be excluded from exercise selection when a user has an injury.

    Args:
        injuries: List of injury body parts (e.g., ["shoulder", "knee"])

    Returns:
        List of muscle groups to avoid (deduplicated)
    """
    if not injuries:
        return []

    muscles_to_avoid = set()

    for injury in injuries:
        injury_lower = injury.lower().strip()

        # Direct match
        if injury_lower in INJURY_TO_AVOIDED_MUSCLES:
            muscles_to_avoid.update(INJURY_TO_AVOIDED_MUSCLES[injury_lower])
            logger.info(f"🔍 [Injury Mapping] {injury} -> avoiding: {INJURY_TO_AVOIDED_MUSCLES[injury_lower]}")
        else:
            # Partial match (e.g., "shoulder pain" -> "shoulder")
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
    """
    Adjust workout parameters based on user's readiness score and mood.

    Readiness-based adjustments:
    - Low readiness (< 50): Reduce sets/reps by 20%, increase rest by 30%
    - Medium readiness (50-70): Normal parameters
    - High readiness (> 70): Can increase intensity slightly

    Mood-based adjustments (applied after readiness):
    - "tired" or "stressed": Further reduce intensity, suggest recovery exercises
    - "great": No reduction, full intensity allowed

    Args:
        workout_params: Base workout parameters (sets, reps, rest_seconds)
        readiness_score: User's readiness score (0-100) or None
        mood: User's current mood or None

    Returns:
        Adjusted workout parameters dict
    """
    if not workout_params:
        workout_params = {}

    # Make a copy to avoid mutating original
    adjusted = dict(workout_params)

    # Track adjustments for logging
    adjustments_made = []

    # Get base values with defaults
    base_sets = adjusted.get("sets", 3)
    base_reps = adjusted.get("reps", 10)
    base_rest = adjusted.get("rest_seconds", 60)

    # Handle reps if it's a string like "8-12"
    if isinstance(base_reps, str):
        try:
            # Take the average of the range
            if "-" in base_reps:
                low, high = base_reps.split("-")
                base_reps = (int(low) + int(high)) // 2
            else:
                base_reps = int(base_reps)
        except ValueError:
            base_reps = 10

    # Apply readiness-based adjustments
    if readiness_score is not None:
        if readiness_score < 50:
            # Low readiness - reduce intensity significantly
            adjusted["sets"] = max(2, int(base_sets * 0.8))  # 20% reduction
            adjusted["reps"] = max(6, int(base_reps * 0.8))  # 20% reduction
            adjusted["rest_seconds"] = int(base_rest * 1.3)  # 30% more rest
            adjusted["readiness_adjustment"] = "low_readiness"
            adjustments_made.append(f"Low readiness ({readiness_score}): reduced sets/reps 20%, increased rest 30%")

        elif readiness_score > 70:
            # High readiness - can push a bit harder
            adjusted["sets"] = min(5, int(base_sets * 1.1))  # 10% increase
            adjusted["reps"] = min(15, int(base_reps * 1.1))  # 10% increase
            adjusted["rest_seconds"] = max(45, int(base_rest * 0.9))  # 10% less rest
            adjusted["readiness_adjustment"] = "high_readiness"
            adjustments_made.append(f"High readiness ({readiness_score}): increased sets/reps 10%, reduced rest 10%")
        else:
            # Medium readiness - normal parameters
            adjusted["sets"] = base_sets
            adjusted["reps"] = base_reps
            adjusted["rest_seconds"] = base_rest
            adjusted["readiness_adjustment"] = "normal"

    # Apply mood-based adjustments (additive with readiness)
    if mood:
        mood_lower = mood.lower()

        if mood_lower in ["tired", "stressed", "anxious"]:
            # Further reduce intensity for tired/stressed users
            current_sets = adjusted.get("sets", base_sets)
            current_reps = adjusted.get("reps", base_reps)
            current_rest = adjusted.get("rest_seconds", base_rest)

            adjusted["sets"] = max(2, int(current_sets * 0.9))  # Additional 10% reduction
            adjusted["reps"] = max(5, int(current_reps * 0.9))  # Additional 10% reduction
            adjusted["rest_seconds"] = int(current_rest * 1.2)  # Additional 20% more rest
            adjusted["mood_adjustment"] = mood_lower
            adjustments_made.append(f"Mood ({mood_lower}): further reduced intensity")

            # Suggest recovery-focused workout
            adjusted["suggest_workout_type"] = "recovery"

        elif mood_lower == "great":
            adjusted["mood_adjustment"] = "great"
            # No additional reduction needed

    # Log adjustments
    if adjustments_made:
        logger.info(f"🎯 [Workout Params] Adjustments: {', '.join(adjustments_made)}")
        logger.info(f"🎯 [Workout Params] Final: sets={adjusted.get('sets')}, reps={adjusted.get('reps')}, rest={adjusted.get('rest_seconds')}s")

    return adjusted


async def get_active_injuries_with_muscles(user_id: str) -> dict:
    """
    Get user's active injuries AND automatically map them to avoided muscles.

    This combines:
    1. Fetching active injuries from database
    2. Mapping injury body parts to muscles to avoid

    Args:
        user_id: The user's ID

    Returns:
        Dict with:
        - "injuries": List of injury body parts
        - "avoided_muscles": List of muscle groups to avoid
    """
    try:
        db = get_supabase_db()

        # Get active injuries from injuries table
        injuries_result = db.client.table("injuries") \
            .select("affected_area, severity, status") \
            .eq("user_id", user_id) \
            .eq("status", "active") \
            .execute()

        active_injuries = []
        if injuries_result.data:
            for injury in injuries_result.data:
                affected_area = injury.get("affected_area", "")
                if affected_area:
                    active_injuries.append(affected_area)

        # Also check user's active_injuries field (could be stored there too)
        user = db.get_user(user_id)
        if user:
            user_injuries = user.get("active_injuries", [])
            if isinstance(user_injuries, str):
                try:
                    user_injuries = json.loads(user_injuries)
                except json.JSONDecodeError:
                    user_injuries = []

            # Add any injuries from user profile
            for inj in user_injuries:
                if isinstance(inj, dict):
                    body_part = inj.get("body_part", "") or inj.get("affected_area", "")
                elif isinstance(inj, str):
                    body_part = inj
                else:
                    body_part = ""

                if body_part and body_part not in active_injuries:
                    active_injuries.append(body_part)

        # Map injuries to muscles to avoid
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


# =============================================================================
# EXERCISE PARAMETER VALIDATION - Safety net for Gemini outputs
# =============================================================================

# Absolute maximums (safety net - never exceed regardless of fitness level)
ABSOLUTE_MAX_REPS = 30  # Never more than 30 reps of anything
ABSOLUTE_MAX_SETS = 6   # Never more than 6 sets
ABSOLUTE_MIN_REST = 30  # Always at least 30 sec rest

# Advanced calisthenics exercises that require YEARS of training
# These should NEVER be given to beginners - they risk injury
ADVANCED_EXERCISES_BLOCKLIST = {
    # Planche movements (require years of strength)
    "planche", "planche push up", "planche push-up", "full planche", "straddle planche",
    "planche lean", "pseudo planche",
    # Front lever movements
    "front lever", "front lever pull up", "front lever row", "front lever raise",
    # Muscle ups
    "muscle up", "muscle-up", "bar muscle up", "ring muscle up",
    # Handstand movements
    "handstand push up", "handstand push-up", "90 degree push up", "pike push up on wall",
    "freestanding handstand push up",
    # One arm movements
    "one arm pull up", "one arm pull-up", "one arm chin up", "one arm push up",
    "one arm push-up", "archer pull up", "archer push up",
    # Pistol squat variations
    "pistol squat", "one leg squat", "shrimp squat", "dragon squat",
    # Human flag and other advanced
    "human flag", "back lever", "iron cross", "maltese", "victorian",
    # L-sit and V-sit
    "l-sit", "l sit", "v-sit", "v sit", "manna",
    # Advanced ring movements
    "iron cross", "maltese cross", "ring handstand",
}

# Fitness level caps - applied to all exercises from Gemini
FITNESS_LEVEL_CAPS = {
    "beginner": {"max_sets": 3, "max_reps": 12, "min_rest": 60},
    "intermediate": {"max_sets": 4, "max_reps": 15, "min_rest": 45},
    "advanced": {"max_sets": 5, "max_reps": 20, "min_rest": 30},
}

# Hell mode caps - higher limits for maximum intensity workouts
# Users must accept risk warning before Hell mode is enabled
HELL_MODE_CAPS = {
    "max_sets": 6,      # Allow up to 6 sets per exercise
    "max_reps": 20,     # Allow up to 20 reps (AMRAP sets can go higher)
    "min_rest": 30,     # Minimum rest stays low for intensity
}

# Age-based additional caps - comprehensive age brackets
# These align with the AGE_ADJUSTMENTS in adaptive_workout_service.py
AGE_CAPS = {
    "young_adult": {  # Under 30
        "max_age": 29, "min_age": 18,
        "max_reps": 25, "max_sets": 6, "min_rest": 30,
        "intensity_ceiling": 1.0, "rest_multiplier": 1.0,
    },
    "adult": {  # 30-44
        "max_age": 44, "min_age": 30,
        "max_reps": 20, "max_sets": 5, "min_rest": 45,
        "intensity_ceiling": 0.95, "rest_multiplier": 1.1,
    },
    "middle_aged": {  # 45-59
        "max_age": 59, "min_age": 45,
        "max_reps": 16, "max_sets": 4, "min_rest": 60,
        "intensity_ceiling": 0.85, "rest_multiplier": 1.25,
    },
    "senior": {  # 60-74
        "max_age": 74, "min_age": 60,
        "max_reps": 12, "max_sets": 3, "min_rest": 75,
        "intensity_ceiling": 0.75, "rest_multiplier": 1.5,
    },
    "elderly": {  # 75+
        "max_age": None, "min_age": 75,
        "max_reps": 10, "max_sets": 3, "min_rest": 90,
        "intensity_ceiling": 0.65, "rest_multiplier": 2.0,
    },
}


def get_age_bracket_from_age(age: int) -> str:
    """Get the age bracket for a given age."""
    if age < 30:
        return "young_adult"
    elif age < 45:
        return "adult"
    elif age < 60:
        return "middle_aged"
    elif age < 75:
        return "senior"
    else:
        return "elderly"


def is_advanced_exercise(exercise_name: str) -> bool:
    """
    Check if an exercise is an advanced calisthenics movement.

    These exercises require years of progressive training and should
    NOT be given to beginners as they risk injury.

    Args:
        exercise_name: Name of the exercise to check

    Returns:
        True if the exercise is advanced and should be blocked for beginners
    """
    if not exercise_name:
        return False

    name_lower = exercise_name.lower().strip()

    # Direct match
    if name_lower in ADVANCED_EXERCISES_BLOCKLIST:
        return True

    # Partial match - check if any blocklist term is in the name
    for blocked_term in ADVANCED_EXERCISES_BLOCKLIST:
        if blocked_term in name_lower:
            return True

    return False


def validate_and_cap_exercise_parameters(
    exercises: List[dict],
    fitness_level: str = "intermediate",
    age: int = None,
    is_comeback: bool = False,
    rep_preferences: dict = None,
    difficulty: str = None
) -> List[dict]:
    """
    Validate and cap exercise parameters to prevent extreme workouts.

    This is a CRITICAL safety net that runs AFTER Gemini generates exercises.
    It ensures that regardless of what Gemini returns, users never get
    dangerous workout parameters like 90 squats.

    Args:
        exercises: List of exercise dicts from Gemini
        fitness_level: User's fitness level (beginner, intermediate, advanced)
        age: User's age (for age-based caps)
        is_comeback: Whether user is returning from a break
        rep_preferences: User's rep preferences from get_user_rep_preferences()
            - max_sets_per_exercise: User's max sets preference
            - min_sets_per_exercise: User's min sets preference
            - enforce_rep_ceiling: Whether to strictly enforce max_reps
            - max_reps: User's max reps ceiling (only used if enforce_rep_ceiling is True)
        difficulty: Workout difficulty level ('easy', 'medium', 'hard', 'hell').
            Hell mode skips age-based weight reduction since users accept the risk.

    Returns:
        Exercises with capped reps, sets, and adjusted rest times

    Example:
        >>> exercises = [{"name": "Squat", "sets": 5, "reps": 90, "rest_seconds": 20}]
        >>> result = validate_and_cap_exercise_parameters(exercises, "beginner", 70, True)
        >>> # Result: sets=2, reps=7, rest_seconds=90 (capped for beginner + elderly + comeback)
    """
    if not exercises:
        return exercises

    # Check if this is Hell mode - use higher caps for maximum intensity
    is_hell_mode = difficulty and difficulty.lower() == "hell"

    # Get fitness level caps (default to intermediate if unknown)
    # For Hell mode, use HELL_MODE_CAPS instead of fitness level caps
    if is_hell_mode:
        caps = HELL_MODE_CAPS
        logger.debug("[Hell Mode] Using elevated caps for maximum intensity workout")
    else:
        caps = FITNESS_LEVEL_CAPS.get(fitness_level.lower() if fitness_level else "intermediate",
                                       FITNESS_LEVEL_CAPS["intermediate"])

    # Get user's sets preferences (with defaults)
    user_max_sets = ABSOLUTE_MAX_SETS  # Default to absolute max
    user_min_sets = 2  # Default minimum
    enforce_rep_ceiling = False
    user_max_reps_ceiling = None

    if rep_preferences:
        user_max_sets = rep_preferences.get("max_sets_per_exercise", ABSOLUTE_MAX_SETS)
        user_min_sets = rep_preferences.get("min_sets_per_exercise", 2)
        enforce_rep_ceiling = rep_preferences.get("enforce_rep_ceiling", False)
        if enforce_rep_ceiling:
            user_max_reps_ceiling = rep_preferences.get("max_reps")

    validated_exercises = []
    filtered_count = 0

    for ex in exercises:
        # SAFETY: Filter out advanced exercises for beginners
        # These exercises require years of training and risk injury
        exercise_name = ex.get("name", "")
        if fitness_level and fitness_level.lower() == "beginner":
            if is_advanced_exercise(exercise_name):
                logger.warning(
                    f"Filtered out advanced exercise '{exercise_name}' for beginner user"
                )
                filtered_count += 1
                continue  # Skip this exercise entirely

        # Make a copy to avoid mutating the original
        validated_ex = dict(ex)

        # Get original values (with defaults)
        original_sets = ex.get("sets", 3)
        original_reps = ex.get("reps", 10)
        original_rest = ex.get("rest_seconds", 60)

        # Handle reps if it's a string like "8-12" or "10"
        if isinstance(original_reps, str):
            try:
                if "-" in original_reps:
                    # Take the higher value of a range for capping purposes
                    parts = original_reps.split("-")
                    original_reps = int(parts[1].strip())
                else:
                    original_reps = int(original_reps.strip())
            except (ValueError, IndexError):
                original_reps = 10  # Safe default

        # Ensure we're working with integers (handle None from JSON null)
        try:
            original_reps = int(original_reps)
        except (ValueError, TypeError):
            original_reps = 10  # Safe default

        try:
            original_sets = int(original_sets)
        except (ValueError, TypeError):
            original_sets = 3

        try:
            original_rest = int(original_rest)
        except (ValueError, TypeError):
            original_rest = 60

        # Step 1: Apply fitness level caps AND user's sets preference
        # User's max_sets_per_exercise takes priority over fitness level caps
        effective_max_sets = min(caps["max_sets"], user_max_sets, ABSOLUTE_MAX_SETS)
        capped_sets = min(original_sets, effective_max_sets)
        capped_sets = max(capped_sets, user_min_sets)  # Ensure at least min_sets

        capped_reps = min(original_reps, caps["max_reps"], ABSOLUTE_MAX_REPS)

        # Apply user's rep ceiling if enforce_rep_ceiling is enabled
        if enforce_rep_ceiling and user_max_reps_ceiling:
            capped_reps = min(capped_reps, user_max_reps_ceiling)

        capped_rest = max(original_rest, caps["min_rest"], ABSOLUTE_MIN_REST)

        # Step 2: Apply age-based caps for all age brackets
        # SKIP for Hell mode - users explicitly chose maximum intensity and accepted the risk
        if age and age >= 18 and not is_hell_mode:
            age_bracket = get_age_bracket_from_age(age)
            age_limits = AGE_CAPS[age_bracket]

            # Apply age-based caps
            capped_reps = min(capped_reps, age_limits["max_reps"])
            capped_sets = min(capped_sets, age_limits["max_sets"])
            capped_rest = max(capped_rest, age_limits["min_rest"])

            # Apply rest multiplier for older users
            if age_limits["rest_multiplier"] > 1.0:
                capped_rest = int(capped_rest * age_limits["rest_multiplier"])

            # Apply intensity ceiling to weights (if weight_kg is specified)
            if validated_ex.get("weight_kg") and age_limits["intensity_ceiling"] < 1.0:
                original_weight = validated_ex["weight_kg"]
                validated_ex["weight_kg"] = round(original_weight * age_limits["intensity_ceiling"], 1)
                if original_weight != validated_ex["weight_kg"]:
                    logger.debug(
                        f"[Age Caps] Reduced weight for {ex.get('name', 'Unknown')}: "
                        f"{original_weight}kg -> {validated_ex['weight_kg']}kg "
                        f"(age={age}, intensity_ceiling={age_limits['intensity_ceiling']})"
                    )
        elif age and age >= 18 and is_hell_mode:
            logger.debug(
                f"[Hell Mode] Skipping ALL age-based caps for {ex.get('name', 'Unknown')}: "
                f"sets={original_sets}, reps={original_reps}, weight={validated_ex.get('weight_kg')}kg "
                f"(difficulty=hell, age={age})"
            )

        # Step 3: Apply comeback reduction (returning from break)
        if is_comeback:
            # 30% reduction in reps (rounded down)
            capped_reps = max(3, int(capped_reps * 0.7))  # At least 3 reps
            # Reduce sets by 1, minimum 2
            capped_sets = max(2, capped_sets - 1)
            # 20% more rest for comeback
            capped_rest = int(capped_rest * 1.2)

        # Apply the validated values
        validated_ex["sets"] = capped_sets
        validated_ex["reps"] = capped_reps
        validated_ex["rest_seconds"] = capped_rest

        # Log when significant capping occurs
        if original_reps > capped_reps + 5 or original_sets > capped_sets + 1:
            logger.warning(
                f"⚠️ [Validation] Capped '{ex.get('name', 'Unknown')}': "
                f"sets {original_sets}->{capped_sets}, reps {original_reps}->{capped_reps}, "
                f"rest {original_rest}->{capped_rest}s "
                f"(fitness={fitness_level}, age={age}, comeback={is_comeback})"
            )

        validated_exercises.append(validated_ex)

    # Log summary if any exercise was capped
    total_original_volume = sum(
        (ex.get("sets", 3) * (int(ex.get("reps", 10)) if isinstance(ex.get("reps", 10), int)
                              else 10))
        for ex in exercises
    )
    total_capped_volume = sum(ex["sets"] * ex["reps"] for ex in validated_exercises)

    if total_capped_volume < total_original_volume * 0.9:  # More than 10% reduction
        reduction_pct = (1 - total_capped_volume / total_original_volume) * 100
        logger.info(
            f"🛡️ [Validation] Total workout volume reduced by {reduction_pct:.1f}% "
            f"(fitness={fitness_level}, age={age}, comeback={is_comeback})"
        )

    return validated_exercises


async def get_user_comeback_status(user_id: str) -> dict:
    """
    Check if user is in comeback mode (returning from a break).

    A user is considered "in comeback mode" if:
    1. They have a flag set in their profile
    2. OR they haven't completed a workout in 14+ days

    Returns:
        Dict with:
        - "in_comeback_mode": bool
        - "days_since_last_workout": int or None
        - "reason": str explaining why
    """
    try:
        db = get_supabase_db()

        # Check user profile for explicit comeback flag
        user = db.get_user(user_id)
        if not user:
            return {"in_comeback_mode": False, "days_since_last_workout": None, "reason": "User not found"}

        preferences = user.get("preferences", {})
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        # Check for explicit comeback mode flag
        if preferences.get("comeback_mode", False):
            return {
                "in_comeback_mode": True,
                "days_since_last_workout": None,
                "reason": "User marked as in comeback mode"
            }

        # Check for inactivity (no completed workouts in 14+ days)
        from datetime import datetime, timedelta
        cutoff_date = (datetime.now() - timedelta(days=14)).isoformat()

        result = db.client.table("workouts") \
            .select("scheduled_date, is_completed") \
            .eq("user_id", user_id) \
            .eq("is_completed", True) \
            .order("scheduled_date", desc=True) \
            .limit(1) \
            .execute()

        if not result.data:
            # No completed workouts ever - treat as new user, not comeback
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
            except Exception:
                pass

        return {
            "in_comeback_mode": False,
            "days_since_last_workout": None,
            "reason": "Could not determine workout history"
        }

    except Exception as e:
        logger.error(f"❌ [Comeback] Error checking comeback status for user {user_id}: {e}")
        return {"in_comeback_mode": False, "days_since_last_workout": None, "reason": str(e)}


# =============================================================================
# COMEBACK/BREAK DETECTION HELPERS - Enhanced with ComebackService
# =============================================================================

async def get_comeback_context(user_id: str) -> dict:
    """
    Get complete comeback context for workout generation.

    This integrates with the ComebackService to provide full break detection
    and comeback adjustment information for both workout generation and
    Gemini prompt context.

    Args:
        user_id: The user's ID

    Returns:
        Dict with:
        - "needs_comeback": bool - Whether user needs comeback adjustments
        - "break_status": Full break status info
        - "adjustments": ComebackAdjustments for workout modification
        - "prompt_context": String for Gemini prompt
        - "extra_warmup_minutes": Additional warmup time needed
    """
    try:
        from services.comeback_service import get_comeback_service

        comeback_service = get_comeback_service()
        break_status = await comeback_service.detect_break_status(user_id)

        # Check if user needs comeback adjustments
        needs_comeback = break_status.break_type.value != "active"

        if not needs_comeback:
            return {
                "needs_comeback": False,
                "break_status": None,
                "adjustments": None,
                "prompt_context": "",
                "extra_warmup_minutes": 0,
            }

        # User needs comeback adjustments
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
    """
    Apply comeback adjustments to a list of exercises.

    This modifies exercises based on the comeback context:
    - Reduces sets/reps based on volume multiplier
    - Reduces weights based on intensity multiplier
    - Adds extra rest time
    - Limits total exercise count

    Args:
        exercises: List of exercise dicts from workout generation
        comeback_context: Context from get_comeback_context()

    Returns:
        Modified exercise list with comeback adjustments
    """
    if not comeback_context.get("needs_comeback") or not exercises:
        return exercises

    adjustments = comeback_context.get("adjustments", {})
    if not adjustments:
        return exercises

    volume_mult = adjustments.get("volume_multiplier", 1.0)
    intensity_mult = adjustments.get("intensity_multiplier", 1.0)
    extra_rest = adjustments.get("extra_rest_seconds", 0)
    max_exercises = adjustments.get("max_exercise_count", 8)

    # Limit exercise count
    exercises = exercises[:max_exercises]

    modified = []
    for ex in exercises:
        mod_ex = dict(ex)

        # Reduce sets
        if "sets" in mod_ex:
            original_sets = mod_ex["sets"]
            mod_ex["sets"] = max(2, int(original_sets * volume_mult))

        # Reduce reps
        if "reps" in mod_ex:
            original_reps = mod_ex["reps"]
            if isinstance(original_reps, int):
                mod_ex["reps"] = max(6, int(original_reps * (volume_mult + 0.1)))

        # Reduce weight
        if "weight_kg" in mod_ex and mod_ex["weight_kg"]:
            original_weight = float(mod_ex["weight_kg"])
            new_weight = original_weight * intensity_mult
            # Round to nearest 2.5 kg
            mod_ex["weight_kg"] = round(new_weight / 2.5) * 2.5

        # Add extra rest
        rest = mod_ex.get("rest_seconds", 60)
        mod_ex["rest_seconds"] = rest + extra_rest

        # Add comeback note
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
    """
    Start comeback mode for user if they need it.

    This should be called when generating workouts for a user
    who is returning from a break.

    Args:
        user_id: The user's ID

    Returns:
        True if comeback mode was started, False otherwise
    """
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
    """
    Generate a context string for Gemini prompt about comeback workout.

    This provides clear instructions to Gemini about how to adjust
    the workout for a user returning from a break.

    Args:
        days_off: Number of days since last workout
        user_age: User's age (for senior-specific instructions)
        volume_reduction_pct: Volume reduction percentage (0-100)
        intensity_reduction_pct: Intensity reduction percentage (0-100)

    Returns:
        Context string for the Gemini prompt
    """
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

    # General comeback guidelines
    context_parts.extend([
        "- Focus on: reactivation, joint mobility, proper form",
        "- Avoid: heavy loads, high rep counts, explosive movements",
        "- Include: extra warm-up time, mobility work, longer rest periods"
    ])

    # Age-specific guidelines
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


# =============================================================================
# LEVERAGE-BASED PROGRESSION & REP PREFERENCES
# =============================================================================

# Default rep ranges by training focus
TRAINING_FOCUS_REP_RANGES = {
    "strength": {"min_reps": 4, "max_reps": 6, "description": "heavy loads, lower reps"},
    "hypertrophy": {"min_reps": 8, "max_reps": 12, "description": "moderate loads, muscle building"},
    "endurance": {"min_reps": 12, "max_reps": 15, "description": "lighter loads, higher reps"},
    "power": {"min_reps": 1, "max_reps": 5, "description": "explosive movements, max effort"},
    "balanced": {"min_reps": 8, "max_reps": 12, "description": "balanced approach"},
}

# Exercise progression chains - from easier to harder variants
EXERCISE_PROGRESSION_CHAINS = {
    # Push progressions
    "push-up": ["Wall Push-ups", "Incline Push-ups", "Knee Push-ups", "Push-ups", "Diamond Push-ups", "Decline Push-ups", "Archer Push-ups", "One-Arm Push-ups"],
    "dip": ["Bench Dips", "Assisted Dips", "Dips", "Weighted Dips", "Ring Dips"],
    "handstand push-up": ["Pike Push-ups", "Elevated Pike Push-ups", "Wall Handstand Hold", "Wall Handstand Push-ups", "Deficit Handstand Push-ups", "Freestanding Handstand Push-ups"],

    # Pull progressions
    "pull-up": ["Dead Hang", "Scapular Pull-ups", "Negative Pull-ups", "Assisted Pull-ups", "Pull-ups", "Chest-to-Bar Pull-ups", "Archer Pull-ups", "One-Arm Pull-ups"],
    "chin-up": ["Dead Hang", "Negative Chin-ups", "Assisted Chin-ups", "Chin-ups", "Weighted Chin-ups", "One-Arm Chin-ups"],
    "row": ["Inverted Rows (High Bar)", "Inverted Rows (Low Bar)", "One-Arm Inverted Rows", "Archer Rows"],
    "muscle-up": ["Pull-ups", "High Pull-ups", "Chest-to-Bar Pull-ups", "Kipping Muscle-up", "Strict Muscle-up", "Ring Muscle-up"],

    # Leg progressions
    "squat": ["Assisted Squats", "Box Squats", "Bodyweight Squats", "Goblet Squats", "Bulgarian Split Squats", "Pistol Squats", "Shrimp Squats"],
    "lunge": ["Stationary Lunges", "Walking Lunges", "Reverse Lunges", "Deficit Lunges", "Jumping Lunges", "Single-Leg Deadlifts"],
    "hip thrust": ["Glute Bridges", "Single-Leg Glute Bridges", "Hip Thrusts", "Single-Leg Hip Thrusts", "Barbell Hip Thrusts"],
    "calf raise": ["Seated Calf Raises", "Standing Calf Raises", "Single-Leg Calf Raises", "Deficit Calf Raises"],

    # Core progressions
    "plank": ["Forearm Plank", "High Plank", "Side Plank", "Plank with Leg Lift", "Plank with Arm Reach", "Ring Plank"],
    "leg raise": ["Lying Leg Raises", "Hanging Knee Raises", "Hanging Leg Raises", "Toes-to-Bar", "L-Sit"],
    "crunch": ["Crunches", "Bicycle Crunches", "Reverse Crunches", "V-ups", "Dragon Flags"],
}


async def get_user_rep_preferences(user_id: str) -> dict:
    """
    Get user's rep range and sets preferences for workout generation.

    This fetches the user's training focus and preferred rep/sets ranges.
    Users can specify:
    - training_focus: strength, hypertrophy, endurance, power, or balanced
    - min_reps: minimum reps they want (overrides training_focus)
    - max_reps: maximum reps they want (overrides training_focus)
    - avoid_high_reps: if True, cap all exercises at 12 reps max
    - max_sets_per_exercise: maximum sets per exercise (default 4)
    - min_sets_per_exercise: minimum sets per exercise (default 2)
    - enforce_rep_ceiling: if True, strictly enforce max_reps as ceiling (default False)

    Returns:
        Dict with:
        - "training_focus": User's training focus
        - "min_reps": Minimum rep target
        - "max_reps": Maximum rep target
        - "avoid_high_reps": Whether to cap reps at 12
        - "max_sets_per_exercise": Maximum sets per exercise
        - "min_sets_per_exercise": Minimum sets per exercise
        - "enforce_rep_ceiling": Whether to strictly enforce rep ceiling
        - "description": Human-readable description
    """
    try:
        db = get_supabase_db()

        result = db.client.table("users").select(
            "preferences"
        ).eq("id", user_id).execute()

        if not result.data:
            return {
                "training_focus": "balanced",
                "min_reps": 8,
                "max_reps": 12,
                "avoid_high_reps": False,
                "max_sets_per_exercise": 4,
                "min_sets_per_exercise": 2,
                "enforce_rep_ceiling": False,
                "description": "balanced approach (8-12 reps, 2-4 sets)"
            }

        preferences = result.data[0].get("preferences") or {}
        if isinstance(preferences, str):
            try:
                preferences = json.loads(preferences)
            except json.JSONDecodeError:
                preferences = {}

        # Get training focus (defaults to balanced)
        training_focus = preferences.get("training_focus", "balanced")
        if training_focus not in TRAINING_FOCUS_REP_RANGES:
            training_focus = "balanced"

        # Get default ranges from training focus
        focus_defaults = TRAINING_FOCUS_REP_RANGES[training_focus]

        # Allow user to override min/max reps
        min_reps = preferences.get("min_reps", focus_defaults["min_reps"])
        max_reps = preferences.get("max_reps", focus_defaults["max_reps"])
        avoid_high_reps = preferences.get("avoid_high_reps", False)

        # Get sets preferences with defaults
        max_sets_per_exercise = preferences.get("max_sets_per_exercise", 4)
        min_sets_per_exercise = preferences.get("min_sets_per_exercise", 2)
        enforce_rep_ceiling = preferences.get("enforce_rep_ceiling", False)

        # If avoid_high_reps is set, cap max_reps at 12
        if avoid_high_reps:
            max_reps = min(max_reps, 12)

        # Validate rep ranges
        if min_reps < 1:
            min_reps = 1
        if max_reps > 30:
            max_reps = 30
        if min_reps > max_reps:
            min_reps = max_reps - 2 if max_reps > 2 else 1

        # Validate sets ranges
        if max_sets_per_exercise < 1:
            max_sets_per_exercise = 1
        if max_sets_per_exercise > 10:
            max_sets_per_exercise = 10
        if min_sets_per_exercise < 1:
            min_sets_per_exercise = 1
        if min_sets_per_exercise > max_sets_per_exercise:
            min_sets_per_exercise = max_sets_per_exercise

        description = f"{training_focus} ({min_reps}-{max_reps} reps, {min_sets_per_exercise}-{max_sets_per_exercise} sets)"
        logger.debug(f"User {user_id} rep preferences: {description}")

        return {
            "training_focus": training_focus,
            "min_reps": min_reps,
            "max_reps": max_reps,
            "avoid_high_reps": avoid_high_reps,
            "max_sets_per_exercise": max_sets_per_exercise,
            "min_sets_per_exercise": min_sets_per_exercise,
            "enforce_rep_ceiling": enforce_rep_ceiling,
            "description": description,
        }

    except Exception as e:
        logger.debug(f"Could not get rep preferences: {e}")
        return {
            "training_focus": "balanced",
            "min_reps": 8,
            "max_reps": 12,
            "avoid_high_reps": False,
            "max_sets_per_exercise": 4,
            "min_sets_per_exercise": 2,
            "enforce_rep_ceiling": False,
            "description": "balanced approach (8-12 reps, 2-4 sets)"
        }


async def get_user_progression_context(user_id: str, days: int = 30) -> dict:
    """
    Get user's exercise mastery data for leverage-based progressions.

    This analyzes the user's workout history to identify exercises they've
    mastered (can do 12+ reps with good form) and suggests harder variants.

    Args:
        user_id: The user's ID
        days: Number of days of history to analyze

    Returns:
        Dict with:
        - "mastered_exercises": List of exercises user has mastered
        - "progression_suggestions": Dict mapping mastered exercises to harder variants
        - "exercises_marked_easy": List of exercises user marked as "too easy" in feedback
        - "mastery_context": Formatted string for Gemini prompt
    """
    try:
        db = get_supabase_db()
        from datetime import datetime, timedelta
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        mastered_exercises = []
        progression_suggestions = {}
        exercises_marked_easy = []

        # 1. Get exercises from feedback where user said "too_easy"
        try:
            feedback_result = db.client.table("exercise_feedback").select(
                "exercise_name, difficulty_felt, reps_completed"
            ).eq("user_id", user_id).gte("created_at", cutoff_date).eq(
                "difficulty_felt", "too_easy"
            ).execute()

            if feedback_result.data:
                for fb in feedback_result.data:
                    ex_name = fb.get("exercise_name", "")
                    if ex_name and ex_name not in exercises_marked_easy:
                        exercises_marked_easy.append(ex_name)
                        reps = fb.get("reps_completed", 0)
                        if reps >= 12:
                            mastered_exercises.append({
                                "name": ex_name,
                                "reason": f"User marked as too easy ({reps} reps)",
                                "source": "feedback"
                            })
        except Exception as e:
            logger.debug(f"Could not fetch exercise feedback: {e}")

        # 2. Get exercises where user consistently completes 12+ reps
        try:
            workout_result = db.client.table("completed_exercise_sets").select(
                "exercise_name, reps_completed, sets_completed"
            ).eq("user_id", user_id).gte("completed_at", cutoff_date).execute()

            # Aggregate by exercise name
            exercise_performance = {}
            if workout_result.data:
                for row in workout_result.data:
                    ex_name = row.get("exercise_name", "")
                    reps = row.get("reps_completed", 0)
                    if not ex_name or reps <= 0:
                        continue

                    if ex_name not in exercise_performance:
                        exercise_performance[ex_name] = {"total_sets": 0, "high_rep_sets": 0}

                    exercise_performance[ex_name]["total_sets"] += 1
                    if reps >= 12:
                        exercise_performance[ex_name]["high_rep_sets"] += 1

            # Identify mastered exercises (>70% of sets at 12+ reps)
            for ex_name, perf in exercise_performance.items():
                if perf["total_sets"] >= 3:  # Minimum 3 sets for confidence
                    high_rep_ratio = perf["high_rep_sets"] / perf["total_sets"]
                    if high_rep_ratio >= 0.7:
                        if ex_name not in [m["name"] for m in mastered_exercises]:
                            mastered_exercises.append({
                                "name": ex_name,
                                "reason": f"Consistently completing 12+ reps ({int(high_rep_ratio*100)}% of sets)",
                                "source": "performance"
                            })
        except Exception as e:
            logger.debug(f"Could not analyze workout performance: {e}")

        # 3. Find progression suggestions for mastered exercises
        for mastered in mastered_exercises:
            ex_name = mastered["name"].lower()

            # Check each progression chain
            for base_exercise, chain in EXERCISE_PROGRESSION_CHAINS.items():
                # Find if mastered exercise is in this chain
                chain_lower = [c.lower() for c in chain]

                for i, chain_ex in enumerate(chain_lower):
                    # Check for match (exact or partial)
                    if ex_name == chain_ex or ex_name in chain_ex or chain_ex in ex_name:
                        # Found the exercise in the chain - suggest next level
                        if i < len(chain) - 1:
                            progression_suggestions[mastered["name"]] = {
                                "current": chain[i],
                                "suggested": chain[i + 1],
                                "chain_position": f"{i + 1}/{len(chain)}"
                            }
                        else:
                            # Already at the top of the chain
                            progression_suggestions[mastered["name"]] = {
                                "current": chain[i],
                                "suggested": None,
                                "chain_position": f"{i + 1}/{len(chain)} (max level)"
                            }
                        break

        # 4. Build context string for Gemini prompt
        mastery_context_parts = []
        if mastered_exercises:
            for mastered in mastered_exercises[:10]:  # Limit to 10 exercises
                ex_name = mastered["name"]
                reason = mastered["reason"]
                suggestion = progression_suggestions.get(ex_name, {})

                if suggestion.get("suggested"):
                    mastery_context_parts.append(
                        f"- {ex_name}: MASTERED ({reason}) -> Suggest: {suggestion['suggested']}"
                    )
                elif suggestion.get("current"):
                    mastery_context_parts.append(
                        f"- {ex_name}: MASTERED ({reason}) at max progression level"
                    )
                else:
                    mastery_context_parts.append(
                        f"- {ex_name}: MASTERED ({reason})"
                    )

        mastery_context = "\n".join(mastery_context_parts) if mastery_context_parts else "No exercises identified as mastered yet."

        logger.info(
            f"[Progression] User {user_id}: {len(mastered_exercises)} mastered exercises, "
            f"{len(progression_suggestions)} with progression suggestions"
        )

        return {
            "mastered_exercises": mastered_exercises,
            "progression_suggestions": progression_suggestions,
            "exercises_marked_easy": exercises_marked_easy,
            "mastery_context": mastery_context,
        }

    except Exception as e:
        logger.error(f"Error getting progression context: {e}")
        return {
            "mastered_exercises": [],
            "progression_suggestions": {},
            "exercises_marked_easy": [],
            "mastery_context": "Unable to analyze exercise history.",
        }


def build_progression_philosophy_prompt(
    rep_preferences: dict,
    progression_context: dict,
) -> str:
    """
    Build the progression philosophy section for the Gemini prompt.

    This creates a clear, structured section that instructs Gemini
    on how to handle exercise progressions and rep ranges.

    Args:
        rep_preferences: User's rep preferences from get_user_rep_preferences()
        progression_context: Context from get_user_progression_context()

    Returns:
        Formatted string for inclusion in the Gemini workout generation prompt
    """
    training_focus = rep_preferences.get("training_focus", "balanced")
    min_reps = rep_preferences.get("min_reps", 8)
    max_reps = rep_preferences.get("max_reps", 12)
    avoid_high_reps = rep_preferences.get("avoid_high_reps", False)
    mastery_context = progression_context.get("mastery_context", "")

    # Training focus descriptions
    focus_descriptions = {
        "strength": "Strength: 4-6 reps, heavier loads, focus on max effort",
        "hypertrophy": "Hypertrophy: 8-12 reps, moderate loads, muscle building",
        "endurance": "Endurance: 12-15 reps, lighter loads, muscular endurance",
        "power": "Power: 1-5 reps, explosive movements, max speed",
        "balanced": "Balanced: 8-12 reps, moderate loads for general fitness",
    }

    prompt_parts = [
        "",
        "## Progression Philosophy",
        "- When an exercise becomes easy (user can do 12+ reps with good form), progress to a HARDER VARIANT instead of adding more reps",
        "- Prefer leverage-based progressions (e.g., push-up -> diamond push-up -> archer push-up) over simply adding repetitions",
        f"- Keep rep ranges within user's preferred range: {min_reps}-{max_reps} reps for most exercises",
        f"- User's training focus is {focus_descriptions.get(training_focus, training_focus)}",
        "",
    ]

    # Add mastery context if available
    if mastery_context and mastery_context != "Unable to analyze exercise history.":
        prompt_parts.extend([
            "## Exercise Mastery Context",
            "The user has mastered these exercises and is ready for progressions:",
            mastery_context,
            "",
            "For mastered exercises:",
            "- DO NOT prescribe the mastered version - use the suggested progression instead",
            "- If no harder variant exists, consider weighted versions or tempo variations",
            "",
        ])

    # Add anti-boring workout rules
    prompt_parts.extend([
        "## Avoid Boring Workouts",
        f"- NEVER prescribe more than {max_reps} reps for strength exercises",
    ])

    if avoid_high_reps:
        prompt_parts.append("- User has indicated 'avoid_high_reps' - cap ALL exercises at 12 reps maximum")

    prompt_parts.extend([
        "- Prioritize exercise progression over rep progression",
        "- Include variety - don't repeat the same exercise pattern every workout",
        "- Suggest harder exercise variants for users who have mastered basics",
        "",
    ])

    return "\n".join(prompt_parts)


# =============================================================================
# EXERCISE MUSCLE MAPPING HELPERS
# =============================================================================

async def get_all_muscles_for_exercise(exercise_name: str) -> List[Dict[str, Any]]:
    """
    Get all muscles worked by an exercise with involvement percentages.

    First checks the exercise_muscle_mappings table for detailed mappings,
    then falls back to parsing primary_muscle + secondary_muscles from the exercises table.

    Args:
        exercise_name: The name of the exercise

    Returns:
        List of dicts with 'muscle' and 'involvement' keys, e.g.:
        [
            {"muscle": "chest", "involvement": 0.7, "is_primary": True},
            {"muscle": "triceps", "involvement": 0.2, "is_primary": False},
            {"muscle": "shoulders", "involvement": 0.1, "is_primary": False},
        ]
    """
    try:
        db = get_supabase_db()
        muscles = []
        exercise_name_lower = exercise_name.lower().strip()

        # First try exercise_muscle_mappings table (if it exists)
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
        except Exception:
            # Table might not exist, fall back to exercise library
            pass

        # Fall back to exercise_library_cleaned
        result = db.client.table("exercise_library_cleaned").select(
            "target_muscle, secondary_muscles, body_part"
        ).ilike("name", f"%{exercise_name_lower}%").limit(1).execute()

        if not result.data:
            # Try exact match
            result = db.client.table("exercise_library_cleaned").select(
                "target_muscle, secondary_muscles, body_part"
            ).eq("name", exercise_name).limit(1).execute()

        if result.data:
            exercise = result.data[0]
            target_muscle = (exercise.get("target_muscle") or exercise.get("body_part") or "").lower().strip()

            # Add primary muscle with 70% default involvement
            if target_muscle:
                muscles.append({
                    "muscle": target_muscle,
                    "involvement": 0.7,
                    "is_primary": True,
                })

            # Parse secondary muscles
            secondary_raw = exercise.get("secondary_muscles", [])
            from services.exercise_rag.filters import parse_secondary_muscles
            secondary_parsed = parse_secondary_muscles(secondary_raw)

            for sec in secondary_parsed:
                # Mark as not primary
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
    """
    Compare the muscle profiles of two exercises to detect significant differences.

    Args:
        old_exercise_muscles: List of muscles from the original exercise
        new_exercise_muscles: List of muscles from the replacement exercise

    Returns:
        Dict with comparison results:
        {
            "is_similar": True/False,
            "primary_match": True/False,
            "similarity_score": 0.0-1.0,
            "missing_muscles": ["list", "of", "muscles"],
            "new_muscles": ["list", "of", "muscles"],
            "warning": "Optional warning message if significantly different"
        }
    """
    # Extract muscle names
    old_muscles = {m["muscle"].lower() for m in old_exercise_muscles if m.get("muscle")}
    new_muscles = {m["muscle"].lower() for m in new_exercise_muscles if m.get("muscle")}

    # Find primary muscles
    old_primary = next((m["muscle"].lower() for m in old_exercise_muscles if m.get("is_primary")), None)
    new_primary = next((m["muscle"].lower() for m in new_exercise_muscles if m.get("is_primary")), None)

    # Check primary muscle match
    primary_match = False
    if old_primary and new_primary:
        primary_match = old_primary == new_primary or old_primary in new_primary or new_primary in old_primary

    # Calculate overlap
    common_muscles = old_muscles & new_muscles
    all_muscles = old_muscles | new_muscles

    similarity_score = len(common_muscles) / len(all_muscles) if all_muscles else 1.0

    # Find differences
    missing_muscles = list(old_muscles - new_muscles)
    added_muscles = list(new_muscles - old_muscles)

    # Determine if the swap is acceptable
    is_similar = primary_match and similarity_score >= 0.5

    # Build warning message if significantly different
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


# =============================================================================
# USER WORKOUT PATTERNS - Historical data for workout generation
# =============================================================================

async def get_user_workout_patterns(user_id: str, days: int = 30) -> dict:
    """
    Fetch user's historical workout patterns to inform AI workout generation.

    This function analyzes the user's completed workouts to provide:
    1. Average sets/reps/weights per exercise they've done before
    2. Typical adjustments the user makes during workouts
    3. Exercises they frequently perform
    4. User's preferred set/rep limits

    Args:
        user_id: The user's ID
        days: Number of days of history to analyze (default 30)

    Returns:
        Dict with:
        - "exercise_patterns": Dict mapping exercise names to their historical averages
        - "set_rep_limits": User's max/min sets and reps preferences
        - "typical_adjustments": Common adjustments user makes
        - "frequently_used": List of frequently used exercises
        - "historical_context": Formatted string for Gemini prompt
    """
    try:
        db = get_supabase_db()
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        exercise_patterns = {}
        typical_adjustments = {
            "sets_increased": 0,
            "sets_decreased": 0,
            "reps_increased": 0,
            "reps_decreased": 0,
            "weight_increased": 0,
            "weight_decreased": 0,
        }
        frequently_used = []

        # Get user's set/rep preferences from their profile
        user = db.get_user(user_id)
        set_rep_limits = {
            "max_sets_per_exercise": 5,  # Default
            "min_sets_per_exercise": 2,
            "max_reps_per_set": 15,
            "min_reps_per_set": 6,
        }

        if user:
            preferences = user.get("preferences", {})
            if isinstance(preferences, str):
                try:
                    preferences = json.loads(preferences)
                except json.JSONDecodeError:
                    preferences = {}

            # Extract set/rep limits from preferences
            set_rep_limits["max_sets_per_exercise"] = preferences.get("max_sets_per_exercise", 5)
            set_rep_limits["min_sets_per_exercise"] = preferences.get("min_sets_per_exercise", 2)
            set_rep_limits["max_reps_per_set"] = preferences.get("max_reps_per_set", 15)
            set_rep_limits["min_reps_per_set"] = preferences.get("min_reps_per_set", 6)

        # 1. Analyze completed workout logs for exercise patterns
        try:
            # Get workout logs with their exercises
            workout_logs_result = db.client.table("workout_logs").select(
                "id, workout_id, sets_json, completed_at"
            ).eq("user_id", user_id).gte("completed_at", cutoff_date).execute()

            if workout_logs_result.data:
                exercise_data = {}  # Aggregate data per exercise

                for log in workout_logs_result.data:
                    sets_json = log.get("sets_json", [])
                    if isinstance(sets_json, str):
                        try:
                            sets_json = json.loads(sets_json)
                        except json.JSONDecodeError:
                            continue

                    for exercise_entry in sets_json:
                        if isinstance(exercise_entry, dict):
                            ex_name = exercise_entry.get("name") or exercise_entry.get("exercise_name", "")
                            if not ex_name:
                                continue

                            ex_name_lower = ex_name.lower()

                            # Initialize exercise data
                            if ex_name_lower not in exercise_data:
                                exercise_data[ex_name_lower] = {
                                    "name": ex_name,
                                    "total_sets": 0,
                                    "total_reps": 0,
                                    "total_weight": 0,
                                    "sessions": 0,
                                    "set_counts": [],
                                    "rep_counts": [],
                                    "weights": [],
                                }

                            # Extract sets data
                            sets = exercise_entry.get("sets", [])
                            if isinstance(sets, list):
                                set_count = len(sets)
                                for s in sets:
                                    if isinstance(s, dict):
                                        reps = s.get("reps", 0) or s.get("reps_completed", 0)
                                        weight = s.get("weight", 0) or s.get("weight_kg", 0)

                                        if isinstance(reps, (int, float)) and reps > 0:
                                            exercise_data[ex_name_lower]["total_reps"] += reps
                                            exercise_data[ex_name_lower]["rep_counts"].append(reps)
                                        if isinstance(weight, (int, float)) and weight > 0:
                                            exercise_data[ex_name_lower]["total_weight"] += weight
                                            exercise_data[ex_name_lower]["weights"].append(weight)

                                if set_count > 0:
                                    exercise_data[ex_name_lower]["total_sets"] += set_count
                                    exercise_data[ex_name_lower]["set_counts"].append(set_count)

                            exercise_data[ex_name_lower]["sessions"] += 1

                # Calculate averages for each exercise
                for ex_name_lower, data in exercise_data.items():
                    sessions = data["sessions"]
                    if sessions > 0:
                        avg_sets = round(sum(data["set_counts"]) / len(data["set_counts"]), 1) if data["set_counts"] else 3
                        avg_reps = round(sum(data["rep_counts"]) / len(data["rep_counts"]), 1) if data["rep_counts"] else 10
                        avg_weight = round(sum(data["weights"]) / len(data["weights"]), 1) if data["weights"] else 0

                        exercise_patterns[ex_name_lower] = {
                            "name": data["name"],
                            "avg_sets": avg_sets,
                            "avg_reps": avg_reps,
                            "avg_weight_kg": avg_weight,
                            "max_weight_kg": max(data["weights"]) if data["weights"] else 0,
                            "sessions": sessions,
                        }

                # Find frequently used exercises (3+ sessions)
                frequently_used = [
                    data["name"] for name, data in exercise_data.items()
                    if data["sessions"] >= 3
                ]

                logger.info(f"[Workout Patterns] Found {len(exercise_patterns)} exercises with patterns for user {user_id}")

        except Exception as e:
            logger.debug(f"Could not analyze workout logs: {e}")

        # 2. Analyze set adjustments from set_adjustments table (if it exists)
        try:
            adjustments_result = db.client.table("set_adjustments").select(
                "adjustment_type, adjustment_value"
            ).eq("user_id", user_id).gte("created_at", cutoff_date).execute()

            if adjustments_result.data:
                for adj in adjustments_result.data:
                    adj_type = adj.get("adjustment_type", "")
                    adj_value = adj.get("adjustment_value", 0)

                    if adj_type == "sets" and adj_value > 0:
                        typical_adjustments["sets_increased"] += 1
                    elif adj_type == "sets" and adj_value < 0:
                        typical_adjustments["sets_decreased"] += 1
                    elif adj_type == "reps" and adj_value > 0:
                        typical_adjustments["reps_increased"] += 1
                    elif adj_type == "reps" and adj_value < 0:
                        typical_adjustments["reps_decreased"] += 1
                    elif adj_type == "weight" and adj_value > 0:
                        typical_adjustments["weight_increased"] += 1
                    elif adj_type == "weight" and adj_value < 0:
                        typical_adjustments["weight_decreased"] += 1

        except Exception as e:
            logger.debug(f"Could not analyze set adjustments (table may not exist): {e}")

        # 3. Build historical context string for Gemini prompt
        historical_context_parts = []

        # Add set/rep limits as CRITICAL instructions
        if set_rep_limits["max_sets_per_exercise"] < 5 or set_rep_limits["max_reps_per_set"] < 15:
            historical_context_parts.extend([
                "",
                "## USER SET/REP LIMITS (CRITICAL - NEVER EXCEED)",
                f"- Maximum {set_rep_limits['max_sets_per_exercise']} sets per exercise. NEVER prescribe more than this.",
                f"- Maximum {set_rep_limits['max_reps_per_set']} reps per set. NEVER prescribe more than this.",
                f"- Minimum {set_rep_limits['min_sets_per_exercise']} sets per exercise.",
                f"- Minimum {set_rep_limits['min_reps_per_set']} reps per set.",
                "- These are HARD limits set by the user. Violating them will cause the workout to be rejected.",
                "",
            ])

        # Add exercise-specific historical data
        if exercise_patterns:
            historical_context_parts.extend([
                "",
                "## HISTORICAL EXERCISE DATA",
                "Use these baselines when prescribing exercises the user has done before:",
            ])

            # Sort by sessions (most frequent first) and limit to top 15
            sorted_exercises = sorted(
                exercise_patterns.items(),
                key=lambda x: x[1]["sessions"],
                reverse=True
            )[:15]

            for ex_name_lower, pattern in sorted_exercises:
                weight_str = f", avg weight: {pattern['avg_weight_kg']}kg" if pattern['avg_weight_kg'] > 0 else ""
                historical_context_parts.append(
                    f"- {pattern['name']}: {pattern['avg_sets']} sets x {pattern['avg_reps']} reps{weight_str} (based on {pattern['sessions']} sessions)"
                )

            historical_context_parts.append("")

        # Add adjustment patterns if significant
        total_adjustments = sum(typical_adjustments.values())
        if total_adjustments >= 5:
            historical_context_parts.append("## USER ADJUSTMENT PATTERNS")
            if typical_adjustments["sets_decreased"] > typical_adjustments["sets_increased"]:
                historical_context_parts.append("- User often reduces sets - start with FEWER sets")
            if typical_adjustments["reps_decreased"] > typical_adjustments["reps_increased"]:
                historical_context_parts.append("- User often reduces reps - start with FEWER reps")
            if typical_adjustments["weight_decreased"] > typical_adjustments["weight_increased"]:
                historical_context_parts.append("- User often reduces weight - start LIGHTER")
            historical_context_parts.append("")

        historical_context = "\n".join(historical_context_parts)

        logger.info(
            f"[Workout Patterns] User {user_id}: {len(exercise_patterns)} exercises, "
            f"{len(frequently_used)} frequently used, limits: {set_rep_limits}"
        )

        return {
            "exercise_patterns": exercise_patterns,
            "set_rep_limits": set_rep_limits,
            "typical_adjustments": typical_adjustments,
            "frequently_used": frequently_used,
            "historical_context": historical_context,
        }

    except Exception as e:
        logger.error(f"Error getting workout patterns for user {user_id}: {e}")
        return {
            "exercise_patterns": {},
            "set_rep_limits": {
                "max_sets_per_exercise": 5,
                "min_sets_per_exercise": 2,
                "max_reps_per_set": 15,
                "min_reps_per_set": 6,
            },
            "typical_adjustments": {},
            "frequently_used": [],
            "historical_context": "",
        }


def enforce_set_rep_limits(
    exercises: List[dict],
    set_rep_limits: dict,
    exercise_patterns: dict = None,
) -> List[dict]:
    """
    Post-generation validation to enforce user's set/rep limits.

    This is a CRITICAL safety net that runs AFTER Gemini generates exercises
    and AFTER validate_and_cap_exercise_parameters. It ensures that the user's
    explicit set/rep preferences are ALWAYS respected.

    Args:
        exercises: List of exercise dicts from Gemini (after initial validation)
        set_rep_limits: User's max/min sets and reps preferences
        exercise_patterns: Optional historical exercise patterns for personalization

    Returns:
        Exercises with enforced set/rep limits
    """
    if not exercises:
        return exercises

    max_sets = set_rep_limits.get("max_sets_per_exercise", 5)
    min_sets = set_rep_limits.get("min_sets_per_exercise", 2)
    max_reps = set_rep_limits.get("max_reps_per_set", 15)
    min_reps = set_rep_limits.get("min_reps_per_set", 6)

    enforced_exercises = []
    violations_fixed = 0

    for ex in exercises:
        enforced_ex = dict(ex)
        original_sets = ex.get("sets", 3)
        original_reps = ex.get("reps", 10)

        # Handle reps if it's a string
        if isinstance(original_reps, str):
            try:
                if "-" in original_reps:
                    parts = original_reps.split("-")
                    original_reps = int(parts[1].strip())
                else:
                    original_reps = int(original_reps.strip())
            except (ValueError, IndexError):
                original_reps = 10

        # Ensure integers
        try:
            original_sets = int(original_sets)
        except (ValueError, TypeError):
            original_sets = 3

        # Check if we have historical data for this exercise
        ex_name_lower = (ex.get("name") or "").lower()
        if exercise_patterns and ex_name_lower in exercise_patterns:
            pattern = exercise_patterns[ex_name_lower]
            # Use historical averages as a starting point, but still respect limits
            suggested_sets = min(max(int(pattern["avg_sets"]), min_sets), max_sets)
            suggested_reps = min(max(int(pattern["avg_reps"]), min_reps), max_reps)

            # Only use historical data if it's within limits
            if min_sets <= suggested_sets <= max_sets:
                enforced_ex["sets"] = suggested_sets
            if min_reps <= suggested_reps <= max_reps:
                enforced_ex["reps"] = suggested_reps

            # Mark that we used historical data
            enforced_ex["weight_source"] = enforced_ex.get("weight_source", "historical")
        else:
            # Enforce limits for new exercises
            new_sets = min(max(original_sets, min_sets), max_sets)
            new_reps = min(max(original_reps, min_reps), max_reps)

            if new_sets != original_sets or new_reps != original_reps:
                violations_fixed += 1
                logger.warning(
                    f"[Set/Rep Limits] Fixed '{ex.get('name', 'Unknown')}': "
                    f"sets {original_sets}->{new_sets}, reps {original_reps}->{new_reps} "
                    f"(limits: sets {min_sets}-{max_sets}, reps {min_reps}-{max_reps})"
                )

            enforced_ex["sets"] = new_sets
            enforced_ex["reps"] = new_reps

        enforced_exercises.append(enforced_ex)

    if violations_fixed > 0:
        logger.info(f"[Set/Rep Limits] Fixed {violations_fixed} exercises exceeding user limits")

    return enforced_exercises


# =============================================================================
# HORMONAL HEALTH CONTEXT - Gender-specific workout adjustments
# =============================================================================

async def get_user_hormonal_context(user_id: str) -> dict:
    """
    Get user's hormonal health context for workout generation.

    This provides:
    - Gender for gender-specific exercises
    - Cycle phase for menstrual phase-aware intensity
    - Hormonal goals for exercise selection
    - Kegel preferences for warmup/cooldown inclusion

    Args:
        user_id: User ID

    Returns:
        Dictionary with hormonal context for workout generation
    """
    try:
        db = get_supabase_db()
        context = {
            "gender": None,
            "hormone_goals": [],
            "primary_goal": None,
            "cycle_phase": None,
            "cycle_day": None,
            "recommended_intensity": None,
            "recent_symptoms": [],
            "symptom_severity": None,
            "kegels_enabled": False,
            "include_kegels_in_warmup": False,
            "include_kegels_in_cooldown": False,
            "kegel_level": "beginner",
            "kegel_focus_area": "general",
            "ai_context": "",
        }

        # Get user's gender
        user_response = db.client.table("users").select("gender").eq("id", user_id).single().execute()
        if user_response.data:
            context["gender"] = user_response.data.get("gender")

        # Get hormonal profile
        profile_response = db.client.table("hormonal_profiles").select("*").eq("user_id", user_id).single().execute()

        if profile_response.data:
            profile = profile_response.data
            context["hormone_goals"] = profile.get("hormone_goals", [])
            context["primary_goal"] = profile.get("primary_goal")

            # Calculate cycle phase if menstrual tracking is enabled
            if profile.get("menstrual_tracking_enabled") and profile.get("last_period_date"):
                from datetime import date, timedelta

                try:
                    last_period = date.fromisoformat(profile["last_period_date"])
                    avg_cycle_length = profile.get("avg_cycle_length", 28)
                    today = date.today()
                    days_since_period = (today - last_period).days
                    cycle_day = (days_since_period % avg_cycle_length) + 1
                    context["cycle_day"] = cycle_day

                    # Determine phase and recommended intensity
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
                    logger.warning(f"[Hormonal Context] Failed to calculate cycle phase: {e}")

        # Get recent hormone logs for symptoms (last 3 days)
        from datetime import datetime, timedelta

        cutoff = (datetime.now() - timedelta(days=3)).date().isoformat()
        logs_response = db.client.table("hormone_logs").select(
            "symptoms, symptom_severity, energy_level"
        ).eq("user_id", user_id).gte("log_date", cutoff).order("log_date", desc=True).limit(3).execute()

        if logs_response.data:
            all_symptoms = []
            for log in logs_response.data:
                symptoms = log.get("symptoms", [])
                if symptoms:
                    all_symptoms.extend(symptoms)

            # Deduplicate
            context["recent_symptoms"] = list(set(all_symptoms))[:5]

            # Get latest severity
            context["symptom_severity"] = logs_response.data[0].get("symptom_severity")

        # Get kegel preferences (use maybe_single to handle 0 rows gracefully)
        kegel_response = db.client.table("kegel_preferences").select("*").eq("user_id", user_id).maybe_single().execute()

        if kegel_response.data:
            prefs = kegel_response.data
            context["kegels_enabled"] = prefs.get("kegels_enabled", False)
            context["include_kegels_in_warmup"] = prefs.get("include_in_warmup", False)
            context["include_kegels_in_cooldown"] = prefs.get("include_in_cooldown", False)
            context["kegel_level"] = prefs.get("current_level", "beginner")
            context["kegel_focus_area"] = prefs.get("focus_area", "general")

        # Build AI context string
        context["ai_context"] = build_hormonal_ai_context(context)

        return context

    except Exception as e:
        logger.error(f"[Hormonal Context] Failed to get hormonal context: {e}")
        return {
            "gender": None,
            "hormone_goals": [],
            "primary_goal": None,
            "cycle_phase": None,
            "cycle_day": None,
            "recommended_intensity": None,
            "recent_symptoms": [],
            "symptom_severity": None,
            "kegels_enabled": False,
            "include_kegels_in_warmup": False,
            "include_kegels_in_cooldown": False,
            "kegel_level": "beginner",
            "kegel_focus_area": "general",
            "ai_context": "",
        }


def build_hormonal_ai_context(hormonal_context: dict) -> str:
    """
    Build AI prompt context string from hormonal context.

    This helps the AI:
    - Select appropriate exercises for the user's gender
    - Adjust intensity based on cycle phase
    - Include kegel exercises in warmup/cooldown when enabled
    - Consider hormonal goals in exercise selection

    Args:
        hormonal_context: Dictionary from get_user_hormonal_context()

    Returns:
        Formatted context string for Gemini prompt
    """
    context_parts = []

    # Gender context
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

    # Hormonal goal context
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

    # Cycle phase context
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

    # Symptoms context
    symptoms = hormonal_context.get("recent_symptoms", [])
    severity = hormonal_context.get("symptom_severity")
    if symptoms and severity in ["moderate", "severe"]:
        context_parts.append(
            f"User has reported {severity} symptoms: {', '.join(symptoms[:3])}. "
            "Adjust workout intensity accordingly, provide modifications, "
            "focus on feel-good exercises rather than challenging ones."
        )

    # Kegel context
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
    """
    Adjust workout exercises based on menstrual cycle phase.

    This applies post-generation adjustments to ensure workouts are
    appropriate for the user's current cycle phase.

    Args:
        exercises: List of exercise dictionaries
        cycle_phase: Current cycle phase (menstrual, follicular, ovulation, luteal)
        symptom_severity: Symptom severity (mild, moderate, severe)

    Returns:
        Adjusted exercises list
    """
    if not exercises or not cycle_phase:
        return exercises

    adjusted = []

    for ex in exercises:
        adjusted_ex = dict(ex)

        # Get current values
        sets = ex.get("sets", 3)
        reps = ex.get("reps", 10)

        # Handle string reps
        if isinstance(reps, str):
            try:
                if "-" in reps:
                    parts = reps.split("-")
                    reps = int(parts[1].strip())
                else:
                    reps = int(reps.strip())
            except (ValueError, IndexError):
                reps = 10

        # Adjustments based on cycle phase
        if cycle_phase == "menstrual":
            # Reduce intensity during menstrual phase
            intensity_reduction = 0.7 if symptom_severity in ["moderate", "severe"] else 0.8
            adjusted_ex["sets"] = max(2, int(sets * intensity_reduction))
            adjusted_ex["reps"] = max(6, int(reps * intensity_reduction))

            # Add note about modification
            adjusted_ex["notes"] = adjusted_ex.get("notes", "") + " (Modified for menstrual phase)"

        elif cycle_phase == "luteal":
            # Slight reduction in late luteal
            if symptom_severity in ["moderate", "severe"]:
                adjusted_ex["sets"] = max(2, int(sets * 0.85))
                adjusted_ex["reps"] = max(6, int(reps * 0.9))

        # Ovulation and follicular phases can maintain or increase intensity
        # (handled by AI in generation, no post-processing needed)

        adjusted.append(adjusted_ex)

    return adjusted


async def get_kegel_exercises_for_workout(
    user_id: str,
    placement: str,  # "warmup" or "cooldown"
) -> List[dict]:
    """
    Get kegel exercises to include in workout warmup or cooldown.

    Args:
        user_id: User ID
        placement: "warmup" or "cooldown"

    Returns:
        List of kegel exercise dictionaries formatted for workout
    """
    try:
        db = get_supabase_db()

        # Get user's kegel preferences
        prefs_response = db.client.table("kegel_preferences").select("*").eq("user_id", user_id).single().execute()

        if not prefs_response.data:
            return []

        prefs = prefs_response.data

        # Check if kegels are enabled for this placement
        if not prefs.get("kegels_enabled", False):
            return []

        if placement == "warmup" and not prefs.get("include_in_warmup", False):
            return []
        if placement == "cooldown" and not prefs.get("include_in_cooldown", False):
            return []

        # Get appropriate kegel exercises based on level and focus
        level = prefs.get("current_level", "beginner")
        focus = prefs.get("focus_area", "general")

        # Map focus area to target audience
        target_audience = "all"
        if focus in ["male_specific", "prostate_health"]:
            target_audience = "male"
        elif focus in ["female_specific", "postpartum"]:
            target_audience = "female"

        # Query kegel exercises
        query = db.client.table("kegel_exercises").select("*").eq("difficulty", level)

        if target_audience != "all":
            query = query.or_(f"target_audience.eq.{target_audience},target_audience.eq.all")
        else:
            query = query.eq("target_audience", "all")

        exercises_response = query.limit(2).execute()

        if not exercises_response.data:
            # Fallback to any beginner exercises
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
        logger.error(f"[Kegel Exercises] Failed to get kegel exercises for {placement}: {e}")
        return []


# =============================================================================
# FOCUS AREA VALIDATION
# =============================================================================

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

# Exercises that clearly don't match specific focus areas (quick validation)
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
    """
    Validate that an exercise matches the workout focus area.

    Args:
        exercise_name: Name of the exercise
        muscle_group: Primary muscle group targeted by the exercise
        focus_area: The intended focus area (e.g., 'legs', 'push', 'upper')

    Returns:
        Dict with validation results:
        {
            "matches": True/False,
            "reason": "Explanation of match/mismatch",
            "confidence": 0.0-1.0 (how confident we are in the assessment)
        }
    """
    exercise_lower = exercise_name.lower().strip()
    muscle_lower = (muscle_group or "").lower().strip()
    focus_lower = focus_area.lower().strip() if focus_area else ""

    # If no focus area, everything matches
    if not focus_lower or focus_lower in ['full_body', 'fullbody', 'full body']:
        return {"matches": True, "reason": "Full body focus allows all exercises", "confidence": 1.0}

    # Quick check: is exercise in the excluded list for this focus?
    excluded_exercises = FOCUS_AREA_EXCLUDED_EXERCISES.get(focus_lower, [])
    for excluded in excluded_exercises:
        if excluded in exercise_lower:
            return {
                "matches": False,
                "reason": f"'{exercise_name}' is a {excluded} exercise, not suitable for {focus_area} focus",
                "confidence": 0.95
            }

    # Check if muscle group matches the focus area
    target_muscles = FOCUS_AREA_MUSCLES.get(focus_lower, [])
    if target_muscles:
        # Check if the muscle group is in the target muscles
        for target in target_muscles:
            if target in muscle_lower or muscle_lower in target:
                return {
                    "matches": True,
                    "reason": f"'{muscle_group}' matches {focus_area} focus",
                    "confidence": 0.9
                }

        # Muscle doesn't match - this is a mismatch
        return {
            "matches": False,
            "reason": f"'{muscle_group}' does not match {focus_area} focus (expected: {', '.join(target_muscles[:3])})",
            "confidence": 0.8
        }

    # Unknown focus area, allow by default
    return {"matches": True, "reason": "Unknown focus area, allowing exercise", "confidence": 0.5}


async def validate_and_filter_focus_mismatches(
    exercises: List[Dict[str, Any]],
    focus_area: str,
    workout_name: str,
) -> Dict[str, Any]:
    """
    Validate all exercises match the workout focus area and filter mismatches.

    Args:
        exercises: List of exercise dictionaries
        focus_area: The intended focus area (e.g., 'legs', 'push', 'upper')
        workout_name: The generated workout name for logging

    Returns:
        Dict with:
        {
            "valid_exercises": List of exercises that match focus,
            "mismatched_exercises": List of exercises that don't match,
            "mismatch_count": Number of mismatched exercises,
            "warnings": List of warning messages
        }
    """
    valid_exercises = []
    mismatched_exercises = []
    warnings = []

    focus_lower = (focus_area or "").lower().strip()

    # If full body or no focus, all exercises are valid
    if not focus_lower or focus_lower in ['full_body', 'fullbody', 'full body']:
        return {
            "valid_exercises": exercises,
            "mismatched_exercises": [],
            "mismatch_count": 0,
            "warnings": []
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

        # Critical warning if majority of exercises don't match
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


def truncate_exercises_to_duration(
    exercises: List[Dict[str, Any]],
    max_duration_minutes: int,
    transition_time_seconds: int = 30
) -> List[Dict[str, Any]]:
    """
    Truncate exercises to fit within the specified duration constraint.

    This is a fallback when Gemini generates a workout that exceeds the time limit.
    Removes exercises from the end until the workout fits within max_duration_minutes.

    Args:
        exercises: List of exercise dictionaries
        max_duration_minutes: Maximum allowed workout duration in minutes
        transition_time_seconds: Time between exercises (default 30s)

    Returns:
        Truncated list of exercises that fits within the time constraint
    """
    if not exercises:
        return exercises

    max_duration_seconds = max_duration_minutes * 60

    def calculate_exercise_duration(exercise: Dict[str, Any]) -> int:
        """Calculate total duration for one exercise in seconds."""
        sets = exercise.get("sets", 3)
        reps = exercise.get("reps", 10)
        rest_seconds = exercise.get("rest_seconds", 60)
        duration_seconds = exercise.get("duration_seconds")

        if duration_seconds:
            # Cardio exercise with duration
            return sets * (duration_seconds + rest_seconds)
        else:
            # Strength exercise with reps (assume 3 seconds per rep)
            return sets * (reps * 3 + rest_seconds)

    # Calculate cumulative duration
    truncated_exercises = []
    cumulative_duration = 0

    for i, exercise in enumerate(exercises):
        exercise_duration = calculate_exercise_duration(exercise)
        transition_time = transition_time_seconds if i > 0 else 0

        # Check if adding this exercise would exceed the limit
        if cumulative_duration + exercise_duration + transition_time <= max_duration_seconds:
            truncated_exercises.append(exercise)
            cumulative_duration += exercise_duration + transition_time
        else:
            # Would exceed limit - stop here
            removed_count = len(exercises) - len(truncated_exercises)
            logger.warning(
                f"⚠️ [Duration Truncate] Removed {removed_count} exercises to fit within "
                f"{max_duration_minutes} min (estimated: {cumulative_duration / 60:.1f} min)"
            )
            break

    return truncated_exercises
