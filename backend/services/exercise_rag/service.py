"""
Exercise RAG Service - Intelligent exercise selection using embeddings.

This service:
1. Indexes all exercises from exercise_library with embeddings
2. Uses AI to select the best exercises based on user profile, goals, equipment
3. Considers exercise variety, muscle balance, and progression
4. Provides equipment-aware weight recommendations
"""

from typing import List, Dict, Any, Optional
import json

from core.config import get_settings
from core.chroma_cloud import get_chroma_cloud_client
from core.supabase_client import get_supabase
from core.logger import get_logger
from core.weight_utils import get_starting_weight, detect_equipment_type
from services.gemini_service import GeminiService

from .utils import clean_exercise_name_for_display, infer_equipment_from_name
from .filters import (
    filter_by_equipment,
    is_similar_exercise,
    pre_filter_by_injuries,
    filter_by_avoided_muscles,
    parse_secondary_muscles,
)
from .search import build_search_query, build_search_query_with_custom_goals

settings = get_settings()
logger = get_logger(__name__)

# Difficulty ceiling by fitness level (prevents advanced exercises for beginners)
# Scale: beginner exercises=1-3, intermediate=4-6, advanced=7-10
# NOTE: These ceilings are now used for RANKING, not hard filtering.
# All exercises are available to all users, but exercises matching
# the user's level are scored higher in selection.
DIFFICULTY_CEILING = {
    "beginner": 3,       # Prefers easy exercises (1-3)
    "intermediate": 6,   # Prefers medium exercises (1-6)
    "advanced": 10,      # Prefers all difficulties
}

# Difficulty preference ratios for workout generation
# Format: {fitness_level: {difficulty_category: percentage}}
# beginner/intermediate/advanced refer to EXERCISE difficulty, not user level
DIFFICULTY_RATIOS = {
    "beginner": {"beginner": 0.60, "intermediate": 0.30, "advanced": 0.10},
    "intermediate": {"beginner": 0.25, "intermediate": 0.50, "advanced": 0.25},
    "advanced": {"beginner": 0.15, "intermediate": 0.35, "advanced": 0.50},
}

# Map difficulty string values to numeric scale (1-10)
DIFFICULTY_STRING_TO_NUM = {
    "beginner": 2,
    "easy": 2,
    "novice": 2,
    "intermediate": 5,
    "medium": 5,
    "moderate": 5,
    "advanced": 8,
    "hard": 8,
    "expert": 9,
    "elite": 10,
}

# Valid fitness levels (for validation)
VALID_FITNESS_LEVELS = {"beginner", "intermediate", "advanced"}

# Default fitness level when None/empty/invalid
DEFAULT_FITNESS_LEVEL = "intermediate"


def validate_fitness_level(fitness_level: Optional[str]) -> str:
    """
    Validate and normalize fitness level, returning a safe default if invalid.

    Args:
        fitness_level: User's fitness level (may be None, empty, or invalid)

    Returns:
        A valid lowercase fitness level string
    """
    if not fitness_level:
        logger.debug(f"[Fitness Level] No fitness level provided, defaulting to {DEFAULT_FITNESS_LEVEL}")
        return DEFAULT_FITNESS_LEVEL

    normalized = str(fitness_level).lower().strip()

    if normalized not in VALID_FITNESS_LEVELS:
        logger.warning(
            f"[Fitness Level] Invalid fitness level '{fitness_level}', "
            f"defaulting to {DEFAULT_FITNESS_LEVEL}. Valid values: {VALID_FITNESS_LEVELS}"
        )
        return DEFAULT_FITNESS_LEVEL

    return normalized


def get_difficulty_numeric(difficulty_value) -> int:
    """
    Convert difficulty value to numeric scale (1-10).

    Handles:
    - String values like "beginner", "intermediate", "advanced"
    - Numeric values (int or float)
    - None or empty values (defaults to 2 = beginner)

    Note: Default is beginner (2) so exercises without explicit difficulty
    are available to all fitness levels. This prevents the bug where
    defaulting to intermediate (5) filtered out ALL exercises for beginners.
    """
    if difficulty_value is None:
        return 2  # Default to beginner so all users can access

    # If already numeric
    if isinstance(difficulty_value, (int, float)):
        return int(difficulty_value)

    # Convert string to lowercase and look up
    difficulty_str = str(difficulty_value).lower().strip()
    return DIFFICULTY_STRING_TO_NUM.get(difficulty_str, 2)  # Default to beginner


def get_adjusted_difficulty_ceiling(
    user_fitness_level: str,
    difficulty_adjustment: int = 0,
) -> int:
    """
    Get the difficulty ceiling adjusted by user feedback.

    The difficulty adjustment shifts the ceiling up or down based on
    user feedback from recent workouts:
    - +2: User finds workouts too easy, allow much harder exercises
    - +1: User finds workouts somewhat easy, allow slightly harder
    - 0: No adjustment needed (default)
    - -1: User finds workouts somewhat hard, use easier exercises
    - -2: User finds workouts too hard, use much easier exercises

    Args:
        user_fitness_level: User's fitness level
        difficulty_adjustment: Adjustment from feedback (-2 to +2)

    Returns:
        Adjusted difficulty ceiling (clamped to 1-10)
    """
    validated_level = validate_fitness_level(user_fitness_level)
    base_ceiling = DIFFICULTY_CEILING.get(validated_level, 6)

    # Each adjustment point shifts the ceiling by 1
    adjusted_ceiling = base_ceiling + difficulty_adjustment

    # Clamp to valid range (1-10)
    adjusted_ceiling = max(1, min(10, adjusted_ceiling))

    if difficulty_adjustment != 0:
        logger.info(
            f"[Difficulty Adjustment] fitness_level={validated_level}, "
            f"base_ceiling={base_ceiling}, adjustment={difficulty_adjustment:+d}, "
            f"adjusted_ceiling={adjusted_ceiling}"
        )

    return adjusted_ceiling


def get_exercise_difficulty_category(exercise_difficulty) -> str:
    """
    Get the difficulty category for an exercise.

    Args:
        exercise_difficulty: The exercise's difficulty (string or numeric)

    Returns:
        "beginner", "intermediate", or "advanced"
    """
    difficulty_num = get_difficulty_numeric(exercise_difficulty)

    if difficulty_num <= 3:
        return "beginner"
    elif difficulty_num <= 6:
        return "intermediate"
    else:
        return "advanced"


def get_difficulty_score(
    exercise_difficulty,
    user_fitness_level: str,
    difficulty_adjustment: int = 0,
) -> float:
    """
    Calculate a difficulty compatibility score (0.0 to 1.0).

    Higher scores mean the exercise is more appropriate for the user's level.
    This is used for RANKING exercises, not filtering them out.

    Args:
        exercise_difficulty: The exercise's difficulty (string or numeric)
        user_fitness_level: User's fitness level ("beginner", "intermediate", "advanced")
        difficulty_adjustment: Adjustment from user feedback (-2 to +2)

    Returns:
        Score from 0.0 (poor match) to 1.0 (ideal match)
    """
    validated_level = validate_fitness_level(user_fitness_level)
    exercise_category = get_exercise_difficulty_category(exercise_difficulty)

    # Get the ratio for this exercise category given user's fitness level
    ratios = DIFFICULTY_RATIOS.get(validated_level, DIFFICULTY_RATIOS["intermediate"])
    base_score = ratios.get(exercise_category, 0.25)

    # Apply difficulty adjustment: positive = prefer harder, negative = prefer easier
    if difficulty_adjustment > 0 and exercise_category in ["intermediate", "advanced"]:
        base_score = min(1.0, base_score + 0.1 * difficulty_adjustment)
    elif difficulty_adjustment < 0 and exercise_category in ["beginner", "intermediate"]:
        base_score = min(1.0, base_score + 0.1 * abs(difficulty_adjustment))

    return base_score


def is_exercise_too_difficult(
    exercise_difficulty,
    user_fitness_level: str,
    difficulty_adjustment: int = 0,
) -> bool:
    """
    Check if an exercise is too difficult for a user's fitness level.

    NOTE: This now returns False for most cases to allow all exercises.
    The only hard filter is preventing Elite (10) exercises for beginners
    without positive difficulty adjustment.

    Args:
        exercise_difficulty: The exercise's difficulty (string or numeric)
        user_fitness_level: User's fitness level ("beginner", "intermediate", "advanced")
        difficulty_adjustment: Adjustment from user feedback (-2 to +2)

    Returns:
        True if the exercise should be filtered out, False if OK
    """
    exercise_difficulty_num = get_difficulty_numeric(exercise_difficulty)
    validated_level = validate_fitness_level(user_fitness_level)

    # Only hard-filter Elite (10) exercises for beginners without adjustment
    # This prevents injury risk from extremely advanced movements
    if validated_level == "beginner" and difficulty_adjustment <= 0:
        if exercise_difficulty_num >= 10:
            return True

    # All other exercises are allowed - difficulty is used for ranking, not filtering
    return False


def is_exercise_too_difficult_strict(
    exercise_difficulty,
    user_fitness_level: str,
    difficulty_adjustment: int = 0,
) -> bool:
    """
    STRICT version: Check if exercise exceeds user's difficulty ceiling.

    This is the original hard-filter logic, kept for backwards compatibility
    and cases where strict filtering is needed.

    Args:
        exercise_difficulty: The exercise's difficulty (string or numeric)
        user_fitness_level: User's fitness level ("beginner", "intermediate", "advanced")
        difficulty_adjustment: Adjustment from user feedback (-2 to +2)

    Returns:
        True if the exercise should be filtered out, False if OK
    """
    max_difficulty = get_adjusted_difficulty_ceiling(user_fitness_level, difficulty_adjustment)
    exercise_difficulty_num = get_difficulty_numeric(exercise_difficulty)

    return exercise_difficulty_num > max_difficulty


class ExerciseRAGService:
    """
    RAG-based exercise selection service.

    Uses embeddings to find exercises that best match:
    - User's fitness goals
    - Available equipment
    - Target muscle groups
    - Fitness level
    - Past workout history (avoiding repetition)
    """

    def __init__(self, gemini_service: GeminiService):
        self.gemini_service = gemini_service
        self.supabase = get_supabase()
        self.client = self.supabase.client

        # Get Chroma Cloud client
        self.chroma_client = get_chroma_cloud_client()
        self.collection = self.chroma_client.get_or_create_collection("exercise_library")

        logger.info(f"Exercise RAG initialized with {self.collection.count()} exercises")

    async def index_all_exercises(self, batch_size: int = 100) -> int:
        """
        Index all exercises from the exercise_library_cleaned view.

        Uses the cleaned/deduplicated view and only indexes exercises with videos.
        Uses batch embedding API to minimize API calls.

        Args:
            batch_size: Number of exercises to process per batch

        Returns:
            Number of exercises indexed
        """
        logger.info("Starting exercise library indexing (using cleaned view)...")

        # Fetch all exercises with pagination
        all_exercises = []
        page_size = 1000
        offset = 0

        while True:
            result = self.client.table("exercise_library_cleaned").select("*").range(
                offset, offset + page_size - 1
            ).execute()

            if not result.data:
                break

            all_exercises.extend(result.data)

            if len(result.data) < page_size:
                break

            offset += page_size

        if not all_exercises:
            logger.warning("No exercises found in exercise_library_cleaned view")
            return 0

        # Filter and deduplicate
        seen_names: set = set()
        exercises = []
        for ex in all_exercises:
            if not ex.get("video_url") and not ex.get("video_s3_path"):
                continue

            exercise_name = ex.get("name", ex.get("exercise_name_cleaned", ex.get("exercise_name", "")))
            lower_name = exercise_name.lower()
            if lower_name in seen_names:
                continue
            seen_names.add(lower_name)
            exercises.append(ex)

        logger.info(f"Found {len(exercises)} exercises to index (filtered from {len(all_exercises)})")
        indexed_count = 0

        # Process in batches
        for i in range(0, len(exercises), batch_size):
            batch = exercises[i:i + batch_size]
            batch_num = i // batch_size + 1
            total_batches = (len(exercises) + batch_size - 1) // batch_size

            logger.info(f"Processing batch {batch_num}/{total_batches} ({len(batch)} exercises)...")

            ids = []
            documents = []
            metadatas = []

            for ex in batch:
                doc_id = f"ex_{ex.get('id', '')}"
                exercise_text = self._build_exercise_text(ex)
                raw_name = ex.get("name", ex.get("exercise_name_cleaned", ex.get("exercise_name", "Unknown")))
                exercise_name = clean_exercise_name_for_display(raw_name)

                ids.append(doc_id)
                documents.append(exercise_text)
                metadatas.append({
                    "exercise_id": str(ex.get("id") or ""),
                    "name": exercise_name,
                    "body_part": str(ex.get("body_part") or ""),
                    "equipment": str(ex.get("equipment") or "bodyweight"),
                    "target_muscle": str(ex.get("target_muscle") or ""),
                    "secondary_muscles": json.dumps(ex.get("secondary_muscles") or []),
                    "difficulty": str(ex.get("difficulty_level") or "intermediate"),
                    "category": str(ex.get("category") or ""),
                    "gif_url": str(ex.get("gif_url") or ""),
                    "video_url": str(ex.get("video_url") or ""),
                    "image_url": str(ex.get("image_url") or ""),
                    "instructions": str(ex.get("instructions") or "")[:500],
                    "has_video": "true",
                    "single_dumbbell_friendly": "true" if ex.get("single_dumbbell_friendly") else "false",
                    "single_kettlebell_friendly": "true" if ex.get("single_kettlebell_friendly") else "false",
                })

            try:
                embeddings = await self.gemini_service.get_embeddings_batch_async(documents)
                logger.info(f"   Got {len(embeddings)} embeddings in 1 API call")
            except Exception as e:
                logger.error(f"Failed to get batch embeddings: {e}")
                continue

            if ids and embeddings:
                try:
                    try:
                        self.collection.delete(ids=ids)
                    except Exception:
                        pass

                    self.collection.add(
                        ids=ids,
                        embeddings=embeddings,
                        documents=documents,
                        metadatas=metadatas,
                    )
                    indexed_count += len(ids)
                    logger.info(f"   Indexed {len(ids)} exercises to Chroma Cloud")
                except Exception as e:
                    logger.error(f"Failed to index batch to Chroma: {e}")

        logger.info(f"Finished indexing {indexed_count} exercises")
        return indexed_count

    def _build_exercise_text(self, exercise: Dict) -> str:
        """Build rich text representation of an exercise for embedding."""
        name = exercise.get("name", exercise.get("exercise_name_cleaned", exercise.get("exercise_name", "Unknown")))
        body_part = exercise.get("body_part", "")
        equipment = exercise.get("equipment", "bodyweight")
        target = exercise.get("target_muscle", "")
        secondary = exercise.get("secondary_muscles", [])
        category = exercise.get("category", "")
        difficulty = exercise.get("difficulty_level", "")
        instructions = exercise.get("instructions", "")
        single_dumbbell = exercise.get("single_dumbbell_friendly", False)
        single_kettlebell = exercise.get("single_kettlebell_friendly", False)

        text_parts = [
            f"Exercise: {name}",
            f"Body Part: {body_part}",
            f"Target Muscle: {target}",
            f"Equipment: {equipment}",
        ]

        if single_dumbbell:
            text_parts.append("Can be done with single dumbbell")
        if single_kettlebell:
            text_parts.append("Can be done with single kettlebell")

        if secondary:
            if isinstance(secondary, list):
                text_parts.append(f"Secondary Muscles: {', '.join(secondary)}")
            else:
                text_parts.append(f"Secondary Muscles: {secondary}")

        if category:
            text_parts.append(f"Category: {category}")

        if difficulty:
            text_parts.append(f"Difficulty: {difficulty}")

        if instructions:
            text_parts.append(f"Instructions: {instructions[:300]}")

        return "\n".join(text_parts)

    async def select_exercises_for_workout(
        self,
        focus_area: str,
        equipment: List[str],
        fitness_level: str,
        goals: List[str],
        count: int = 6,
        avoid_exercises: Optional[List[str]] = None,
        injuries: Optional[List[str]] = None,
        dumbbell_count: int = 2,
        kettlebell_count: int = 1,
        workout_params: Optional[Dict] = None,
        user_id: Optional[str] = None,
        strength_history: Optional[Dict[str, Dict]] = None,
        favorite_exercises: Optional[List[str]] = None,
        queued_exercises: Optional[List[Dict]] = None,
        consistency_mode: str = "vary",
        recently_used_exercises: Optional[List[str]] = None,
        staple_exercises: Optional[List[str]] = None,
        variation_percentage: int = 30,
        avoided_muscles: Optional[Dict[str, List[str]]] = None,
        progression_pace: str = "medium",
        workout_type_preference: str = "strength",
        readiness_score: Optional[int] = None,
        user_mood: Optional[str] = None,
        difficulty_adjustment: int = 0,
    ) -> List[Dict[str, Any]]:
        """
        Intelligently select exercises for a workout using RAG + AI.

        Args:
            focus_area: Target body area (chest, back, legs, full_body, etc.)
            equipment: Available equipment
            fitness_level: User's fitness level
            goals: User's fitness goals
            count: Number of exercises to select
            avoid_exercises: Exercises to avoid (for variety)
            injuries: User's active injuries to avoid aggravating
            dumbbell_count: Number of dumbbells user has (1 or 2)
            kettlebell_count: Number of kettlebells user has (1 or 2)
            workout_params: Optional adaptive parameters (sets, reps, rest_seconds)
            user_id: User ID for fetching custom goal keywords (optional)
            strength_history: Dict mapping exercise names to historical weight data
                              e.g. {"Bench Press": {"last_weight_kg": 70, "max_weight_kg": 85, "last_reps": 8}}
            favorite_exercises: List of user's favorite exercise names to prioritize
            queued_exercises: List of exercises user has queued for inclusion
            consistency_mode: "vary" to avoid recent exercises, "consistent" to prefer them
            recently_used_exercises: List of exercises used in recent workouts (for consistency boost)
            staple_exercises: List of user's staple exercises that should ALWAYS be included
            variation_percentage: How much variety user wants (0-100, default 30)
            avoided_muscles: Dict with 'avoid' (completely skip) and 'reduce' (lower priority) muscle lists
            progression_pace: User's progression pace - "slow", "medium", or "fast"
            workout_type_preference: User's workout type - "strength", "cardio", "mixed", "mobility", "recovery"
            readiness_score: User's readiness score (0-100) - affects workout intensity
            user_mood: User's current mood - affects workout type recommendation
            difficulty_adjustment: Feedback-based difficulty adjustment (-2 to +2).
                                   Positive values allow harder exercises, negative use easier ones.

        Returns:
            List of selected exercises with full details
        """
        logger.info(f"Selecting {count} exercises for {focus_area} workout")
        logger.info(f"Equipment: {equipment}, Dumbbells: {dumbbell_count}, Kettlebells: {kettlebell_count}")
        logger.info(f"Consistency mode: {consistency_mode}, Variation: {variation_percentage}%")
        logger.info(f"Progression pace: {progression_pace}, Workout type preference: {workout_type_preference}")

        # Log readiness and mood for AI consistency tracking
        if readiness_score is not None:
            logger.info(f"🎯 [AI Consistency] Readiness score: {readiness_score}")
            if readiness_score < 50:
                logger.info(f"   -> Low readiness: Will adjust workout intensity DOWN")
            elif readiness_score > 70:
                logger.info(f"   -> High readiness: Can handle higher intensity")
        if user_mood:
            logger.info(f"🎯 [AI Consistency] User mood: {user_mood}")
            if user_mood.lower() in ["tired", "stressed", "anxious"]:
                logger.info(f"   -> {user_mood}: Will suggest recovery-focused exercises")
        if staple_exercises:
            logger.info(f"User has {len(staple_exercises)} staple exercises (never rotated)")
            # CRITICAL: Never put staples in avoid list - they should always be included
            if avoid_exercises:
                staple_lower = [s.lower() for s in staple_exercises]
                avoid_exercises = [e for e in avoid_exercises if e.lower() not in staple_lower]
                logger.info(f"Removed staples from avoid list, now avoiding {len(avoid_exercises)} exercises")
        if strength_history:
            logger.info(f"Using strength history for {len(strength_history)} exercises")
        if favorite_exercises:
            logger.info(f"User has {len(favorite_exercises)} favorite exercises")
        if queued_exercises:
            logger.info(f"User has {len(queued_exercises)} queued exercises")
        if recently_used_exercises:
            logger.info(f"User has {len(recently_used_exercises)} recently used exercises")
        if injuries:
            logger.info(f"User has injuries/conditions: {injuries}")
        if avoided_muscles:
            avoid_muscles_list = avoided_muscles.get("avoid", [])
            reduce_muscles_list = avoided_muscles.get("reduce", [])
            if avoid_muscles_list:
                logger.info(f"User has {len(avoid_muscles_list)} muscles to AVOID: {avoid_muscles_list}")
            if reduce_muscles_list:
                logger.info(f"User has {len(reduce_muscles_list)} muscles to REDUCE: {reduce_muscles_list}")

        # Validate fitness level to prevent None.lower() errors and ensure consistency
        validated_fitness_level = validate_fitness_level(fitness_level)
        if validated_fitness_level != fitness_level:
            logger.info(f"[Exercise Selection] Normalized fitness_level: '{fitness_level}' -> '{validated_fitness_level}'")

        # Log difficulty filtering context (with feedback adjustment)
        base_max_difficulty = DIFFICULTY_CEILING.get(validated_fitness_level, 6)
        adjusted_max_difficulty = get_adjusted_difficulty_ceiling(validated_fitness_level, difficulty_adjustment)
        if difficulty_adjustment != 0:
            logger.info(
                f"🎯 [Feedback Adjustment] Applying difficulty_adjustment={difficulty_adjustment:+d}, "
                f"base_ceiling={base_max_difficulty} -> adjusted_ceiling={adjusted_max_difficulty}"
            )
        logger.info(f"[Exercise Selection] fitness_level={validated_fitness_level}, max_difficulty={adjusted_max_difficulty} (1-10 scale)")

        # Build search query (with custom goals if user_id provided)
        if user_id:
            search_query = await build_search_query_with_custom_goals(
                focus_area, equipment, validated_fitness_level, goals, user_id
            )
        else:
            search_query = build_search_query(focus_area, equipment, validated_fitness_level, goals)

        # Get embedding for the search query
        query_embedding = await self.gemini_service.get_embedding_async(search_query)

        # Search for candidate exercises
        candidate_count = min(count * 4, 30)

        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=candidate_count,
            include=["documents", "metadatas", "distances"],
        )

        if not results["ids"][0]:
            logger.error("No exercises found in RAG")
            raise ValueError(f"No exercises found in RAG for focus_area={focus_area}")

        # Helper function to filter and format exercise candidates
        def _filter_exercises(require_media: bool = True) -> tuple[list, list]:
            """Filter exercises based on criteria. Returns (candidates, seen_exercises)."""
            filtered_candidates = []
            seen = []
            no_media_count = 0

            for i, doc_id in enumerate(results["ids"][0]):
                meta = results["metadatas"][0][i]
                distance = results["distances"][0][i]
                similarity = 1 - (distance / 2)

                # Skip exercises to avoid
                if avoid_exercises and meta.get("name", "").lower() in [e.lower() for e in avoid_exercises]:
                    continue

                # Get equipment info
                raw_ex_equipment = (meta.get("equipment", "") or "").lower().strip()
                exercise_name_for_inference = meta.get("name", "")
                if not raw_ex_equipment or raw_ex_equipment in ["bodyweight", "body weight", "none"]:
                    ex_equipment = infer_equipment_from_name(exercise_name_for_inference).lower()
                else:
                    ex_equipment = raw_ex_equipment

                # Filter by equipment
                if not filter_by_equipment(ex_equipment, equipment, meta.get("name", "")):
                    logger.debug(f"Filtered out '{meta.get('name')}' - equipment mismatch")
                    continue

                # Filter out exercises without media (optional based on require_media flag)
                has_video = meta.get("has_video", "false") == "true"
                gif_url = meta.get("gif_url", "")
                video_url = meta.get("video_url", "")
                image_url = meta.get("image_url", "")
                has_media = has_video or bool(gif_url) or bool(video_url) or bool(image_url)
                if require_media and not has_media:
                    no_media_count += 1
                    logger.debug(f"Filtered out '{meta.get('name')}' - no media (video/gif/image)")
                    continue

                # Filter by single equipment compatibility
                if dumbbell_count == 1 and "dumbbell" in ex_equipment:
                    single_db_friendly = meta.get("single_dumbbell_friendly", "false") == "true"
                    if not single_db_friendly:
                        continue

                if kettlebell_count == 1 and "kettlebell" in ex_equipment:
                    single_kb_friendly = meta.get("single_kettlebell_friendly", "false") == "true"
                    if not single_kb_friendly:
                        continue

                # Filter by difficulty - prevent advanced exercises for beginners
                # Uses STRICT filtering for beginners to prevent injury from advanced movements
                # Uses feedback-based difficulty_adjustment to shift ceiling
                # Default to "beginner" so exercises without explicit difficulty are available to all
                exercise_difficulty = meta.get("difficulty", "beginner")

                # For beginners, use strict filtering (ceiling of 3) to prevent advanced exercises
                # For intermediate/advanced, use permissive filtering (only blocks elite for intermediate)
                if validated_fitness_level == "beginner":
                    if is_exercise_too_difficult_strict(exercise_difficulty, validated_fitness_level, difficulty_adjustment):
                        logger.debug(f"Filtered out '{meta.get('name')}' - too difficult ({exercise_difficulty}) for beginner (strict)")
                        continue
                else:
                    if is_exercise_too_difficult(exercise_difficulty, validated_fitness_level, difficulty_adjustment):
                        logger.debug(f"Filtered out '{meta.get('name')}' - too difficult ({exercise_difficulty}) for {validated_fitness_level}")
                        continue

                # Clean name for display
                raw_name = meta.get("name", "Unknown")
                exercise_name = clean_exercise_name_for_display(raw_name)

                # Skip similar exercises
                is_duplicate = False
                for seen_name in seen:
                    if is_similar_exercise(exercise_name, seen_name):
                        is_duplicate = True
                        break

                if is_duplicate:
                    continue

                seen.append(exercise_name)

                # Get equipment
                raw_eq = meta.get("equipment", "")
                if not raw_eq or raw_eq.lower() in ["bodyweight", "body weight", "none", ""]:
                    eq = infer_equipment_from_name(exercise_name)
                else:
                    eq = raw_eq

                # Calculate difficulty compatibility score for ranking
                exercise_diff = meta.get("difficulty", "beginner")
                diff_score = get_difficulty_score(exercise_diff, validated_fitness_level, difficulty_adjustment)

                filtered_candidates.append({
                    "id": meta.get("exercise_id", ""),
                    "name": exercise_name,
                    "body_part": meta.get("body_part", ""),
                    "equipment": eq,
                    "target_muscle": meta.get("target_muscle", ""),
                    "secondary_muscles": meta.get("secondary_muscles", []),
                    "difficulty": exercise_diff,
                    "difficulty_category": get_exercise_difficulty_category(exercise_diff),
                    "difficulty_score": diff_score,
                    "gif_url": meta.get("gif_url", ""),
                    "video_url": meta.get("video_url", ""),
                    "image_url": meta.get("image_url", ""),
                    "instructions": meta.get("instructions", ""),
                    "similarity": similarity,
                    "single_dumbbell_friendly": meta.get("single_dumbbell_friendly", "false") == "true",
                    "single_kettlebell_friendly": meta.get("single_kettlebell_friendly", "false") == "true",
                    "alternating_hands": meta.get("single_dumbbell_friendly", "false") == "true",
                })

            if require_media and no_media_count > 0:
                logger.info(f"Filtered out {no_media_count} exercises due to missing media")

            return filtered_candidates, seen

        # First pass: require media
        candidates, seen_exercises = _filter_exercises(require_media=True)

        # If no candidates with media, try again without media requirement
        if not candidates:
            logger.warning(f"No exercises with media found for focus_area={focus_area}, trying without media requirement")
            candidates, seen_exercises = _filter_exercises(require_media=False)

        if not candidates:
            logger.error("No compatible exercises found after filtering (even without media requirement)")
            raise ValueError(f"No compatible exercises found for focus_area={focus_area}, equipment={equipment}")

        # Apply difficulty score to similarity for ranking
        # This ensures exercises matching user's fitness level are prioritized
        # Weight: 70% similarity, 30% difficulty match
        for candidate in candidates:
            original_similarity = candidate.get("similarity", 0.5)
            difficulty_score = candidate.get("difficulty_score", 0.5)
            # Weighted combination: similarity matters more, but difficulty influences selection
            candidate["similarity"] = (original_similarity * 0.7) + (difficulty_score * 0.3)
            candidate["original_similarity"] = original_similarity

        # Re-sort after applying difficulty scores
        candidates.sort(key=lambda x: x.get("similarity", 0), reverse=True)

        logger.info(
            f"Applied difficulty scoring for {validated_fitness_level} user: "
            f"{len([c for c in candidates if c.get('difficulty_category') == 'beginner'])} beginner, "
            f"{len([c for c in candidates if c.get('difficulty_category') == 'intermediate'])} intermediate, "
            f"{len([c for c in candidates if c.get('difficulty_category') == 'advanced'])} advanced exercises available"
        )

        # Pre-filter for injuries
        if injuries and len(injuries) > 0:
            safe_candidates = pre_filter_by_injuries(candidates, injuries)
            if safe_candidates:
                logger.info(f"Pre-filtered {len(candidates)} candidates to {len(safe_candidates)} safe exercises")
                candidates = safe_candidates
            else:
                logger.warning("Pre-filter removed all candidates, keeping original list")

        # Filter by avoided muscles (now includes secondary muscles with >20% involvement)
        if avoided_muscles:
            original_count = len(candidates)
            candidates, primary_filtered, secondary_filtered = filter_by_avoided_muscles(
                candidates, avoided_muscles
            )

            if primary_filtered > 0 or secondary_filtered > 0:
                logger.info(
                    f"Avoided muscles filter: {original_count} -> {len(candidates)} exercises "
                    f"(primary: {primary_filtered}, secondary: {secondary_filtered} filtered)"
                )

            if not candidates:
                logger.warning("Avoided muscles filter removed all candidates, this should not happen")
                # This is a safety net - the filter_by_avoided_muscles should handle this gracefully

            # Re-sort after penalty application (reduce muscles apply penalties)
            candidates.sort(key=lambda x: x.get("similarity", 0), reverse=True)

        # Apply workout type preference filtering
        # Different workout types prioritize different exercise categories
        if workout_type_preference and workout_type_preference != "strength":
            workout_type_keywords = {
                "cardio": ["cardio", "hiit", "jumping", "running", "cycling", "burpee", "jump", "sprint", "rowing", "skipping"],
                "mixed": [],  # No specific filtering for mixed
                "mobility": ["stretch", "mobility", "flexibility", "yoga", "foam", "rotation", "dynamic"],
                "recovery": ["stretch", "foam", "light", "recovery", "mobility", "yoga", "breathing"],
            }

            keywords = workout_type_keywords.get(workout_type_preference, [])
            if keywords:
                for candidate in candidates:
                    name_lower = candidate["name"].lower()
                    instructions = (candidate.get("instructions") or "").lower()

                    # Check if exercise matches workout type
                    matches_type = any(kw in name_lower or kw in instructions for kw in keywords)

                    if workout_type_preference in ["cardio", "mobility", "recovery"]:
                        if matches_type:
                            # Boost matching exercises by 1.5x
                            candidate["similarity"] = min(1.0, candidate["similarity"] * 1.5)
                            candidate["workout_type_boost"] = True
                            logger.debug(f"Boosted '{candidate['name']}' for {workout_type_preference} workout type")
                        else:
                            # Penalize non-matching exercises by 0.7x for specialized workouts
                            candidate["similarity"] = candidate["similarity"] * 0.7
                            candidate["workout_type_penalty"] = True

                # Re-sort after workout type filtering
                candidates.sort(key=lambda x: x["similarity"], reverse=True)
                logger.info(f"Applied {workout_type_preference} workout type filtering to candidates")

        # Boost favorites: STRONG boost to ensure favorites are prioritized
        # Using 2.5x multiplier (was 1.5x) - favorites should almost always be included
        if favorite_exercises:
            favorite_names_lower = [f.lower() for f in favorite_exercises]
            for candidate in candidates:
                if candidate["name"].lower() in favorite_names_lower:
                    # 150% boost (2.5x multiplier) - favorites get strong priority
                    candidate["similarity"] = min(1.0, candidate["similarity"] * 2.5)
                    candidate["is_favorite"] = True
                    candidate["boost_reason"] = "favorite"
                    logger.info(f"Boosted favorite exercise (2.5x): {candidate['name']} -> {candidate['similarity']:.2f}")
                else:
                    candidate["is_favorite"] = False

            # Re-sort by similarity after boosting
            candidates.sort(key=lambda x: x["similarity"], reverse=True)

        # Consistency mode boost: In "consistent" mode, boost recently used exercises
        # This ensures users who prefer consistent routines get exercises they know
        if consistency_mode == "consistent" and recently_used_exercises:
            recently_used_lower = [e.lower() for e in recently_used_exercises]
            boosted_count = 0
            for candidate in candidates:
                if candidate["name"].lower() in recently_used_lower:
                    # 80% boost (1.8x multiplier) for recently used in consistent mode
                    original_sim = candidate["similarity"]
                    candidate["similarity"] = min(1.0, candidate["similarity"] * 1.8)
                    candidate["consistency_boosted"] = True
                    if not candidate.get("boost_reason"):
                        candidate["boost_reason"] = "consistent_routine"
                    else:
                        candidate["boost_reason"] += "+consistent_routine"
                    boosted_count += 1
                    logger.info(f"Boosted consistent exercise (1.8x): {candidate['name']} {original_sim:.2f} -> {candidate['similarity']:.2f}")
                else:
                    candidate["consistency_boosted"] = False

            if boosted_count > 0:
                logger.info(f"Consistency mode: boosted {boosted_count} recently used exercises")
                # Re-sort after consistency boost
                candidates.sort(key=lambda x: x["similarity"], reverse=True)

        # Process STAPLE exercises - these are ALWAYS included (never rotated)
        # Staples take highest priority, even above queued exercises
        staple_included = []
        staple_names_used = []

        if staple_exercises:
            staple_names_lower = [s.lower() for s in staple_exercises]

            # Find staple exercises in candidates
            for staple_name in staple_exercises:
                staple_lower = staple_name.lower()
                for candidate in candidates:
                    if candidate["name"].lower() == staple_lower:
                        staple_included.append(candidate)
                        staple_names_used.append(candidate["name"])
                        candidate["is_staple"] = True
                        logger.info(f"Including STAPLE exercise: {candidate['name']}")
                        break

            # Remove staples from candidates to avoid duplicates
            candidates = [c for c in candidates if c["name"].lower() not in staple_names_lower]
            logger.info(f"Staples included: {len(staple_included)} of {len(staple_exercises)}")

        # Process queued exercises - include them first before AI selection
        # Track exclusion reasons for user feedback
        queued_included = []
        queued_names_used = []
        queued_exclusion_reasons = []  # Track why queued exercises weren't included

        if queued_exercises:
            queued_names = [q["name"].lower() for q in queued_exercises]
            candidate_names_lower = [c["name"].lower() for c in candidates]

            # Find queued exercises in candidates
            for queued in queued_exercises:
                queued_name_lower = queued["name"].lower()
                queued_focus = queued.get("target_muscle_group", "").lower()

                # Check if this exercise is in our candidates
                found_in_candidates = False
                for candidate in candidates:
                    if candidate["name"].lower() == queued_name_lower:
                        queued_included.append(candidate)
                        queued_names_used.append(candidate["name"])
                        candidate["from_queue"] = True
                        found_in_candidates = True
                        logger.info(f"Including queued exercise: {candidate['name']}")
                        break

                # Track why exercise wasn't included
                if not found_in_candidates:
                    reason = {
                        "exercise_name": queued["name"],
                        "queued_focus": queued_focus,
                        "current_focus": focus_area,
                    }

                    if queued_focus and queued_focus != focus_area.lower():
                        reason["exclusion_reason"] = f"Focus area mismatch: queued for '{queued_focus}', today is '{focus_area}'"
                    elif queued_name_lower not in candidate_names_lower:
                        reason["exclusion_reason"] = "Exercise not found in available library for current equipment"
                    else:
                        reason["exclusion_reason"] = "Exercise filtered out (equipment/injury filter)"

                    queued_exclusion_reasons.append(reason)
                    logger.info(f"Queued exercise excluded: {queued['name']} - {reason['exclusion_reason']}")

            # Remove queued exercises from candidates to avoid duplicates
            candidates = [c for c in candidates if c["name"].lower() not in queued_names]

        # Calculate how many more exercises we need from AI selection
        # Staples and queued take priority
        remaining_count = count - len(staple_included) - len(queued_included)

        # =============================================================================
        # AI CONSISTENCY: Adjust workout params based on readiness and mood
        # =============================================================================
        adjusted_workout_params = workout_params or {}
        if readiness_score is not None or user_mood:
            # Apply readiness and mood adjustments to workout parameters
            if readiness_score is not None:
                if readiness_score < 50:
                    # Low readiness - reduce intensity
                    base_sets = adjusted_workout_params.get("sets", 3)
                    base_reps = adjusted_workout_params.get("reps", 10)
                    base_rest = adjusted_workout_params.get("rest_seconds", 60)

                    adjusted_workout_params = dict(adjusted_workout_params)
                    adjusted_workout_params["sets"] = max(2, int(base_sets * 0.8))
                    adjusted_workout_params["reps"] = max(6, int(base_reps * 0.8) if isinstance(base_reps, int) else 8)
                    adjusted_workout_params["rest_seconds"] = int(base_rest * 1.3)
                    adjusted_workout_params["readiness_adjustment"] = "low_readiness"
                    logger.info(f"🎯 [AI Consistency] Low readiness ({readiness_score}): Reduced sets/reps by 20%, increased rest by 30%")

                elif readiness_score > 70:
                    # High readiness - can push harder
                    base_sets = adjusted_workout_params.get("sets", 3)
                    base_reps = adjusted_workout_params.get("reps", 10)
                    base_rest = adjusted_workout_params.get("rest_seconds", 60)

                    adjusted_workout_params = dict(adjusted_workout_params)
                    adjusted_workout_params["sets"] = min(5, int(base_sets * 1.1))
                    adjusted_workout_params["reps"] = min(15, int(base_reps * 1.1) if isinstance(base_reps, int) else 12)
                    adjusted_workout_params["rest_seconds"] = max(45, int(base_rest * 0.9))
                    adjusted_workout_params["readiness_adjustment"] = "high_readiness"
                    logger.info(f"🎯 [AI Consistency] High readiness ({readiness_score}): Increased intensity by 10%")

            if user_mood and user_mood.lower() in ["tired", "stressed", "anxious"]:
                # Further reduce for tired/stressed mood
                current_sets = adjusted_workout_params.get("sets", 3)
                current_reps = adjusted_workout_params.get("reps", 10)
                current_rest = adjusted_workout_params.get("rest_seconds", 60)

                adjusted_workout_params = dict(adjusted_workout_params)
                adjusted_workout_params["sets"] = max(2, int(current_sets * 0.9))
                adjusted_workout_params["reps"] = max(5, int(current_reps * 0.9) if isinstance(current_reps, int) else 8)
                adjusted_workout_params["rest_seconds"] = int(current_rest * 1.2)
                adjusted_workout_params["mood_adjustment"] = user_mood.lower()
                logger.info(f"🎯 [AI Consistency] Mood ({user_mood}): Further reduced intensity")

        if remaining_count > 0:
            # Use AI to select remaining exercises
            selected = await self._ai_select_exercises(
                candidates=candidates[:20],
                focus_area=focus_area,
                fitness_level=fitness_level,
                goals=goals,
                count=remaining_count,
                injuries=injuries,
                workout_params=adjusted_workout_params,
                strength_history=strength_history,
                progression_pace=progression_pace,
            )
        else:
            selected = []

        # Format staple and queued exercises (AI-selected are already formatted)
        formatted_staples = [
            self._format_exercise_for_workout(ex, fitness_level, adjusted_workout_params, strength_history, progression_pace)
            for ex in staple_included
        ]
        formatted_queued = [
            self._format_exercise_for_workout(ex, fitness_level, adjusted_workout_params, strength_history, progression_pace)
            for ex in queued_included
        ]

        # Combine in priority order: staples first, then queued, then AI-selected
        final_selection = formatted_staples + formatted_queued + selected

        # Store queued exercise names for marking as used (returned via metadata)
        if queued_names_used:
            for ex in final_selection:
                if ex["name"] in queued_names_used:
                    ex["from_queue"] = True

        # Add metadata about selection process for transparency
        selection_metadata = {
            "staple_included_count": len(staple_included),
            "staple_exercises_used": staple_names_used,
            "queued_included_count": len(queued_included),
            "queued_exclusion_reasons": queued_exclusion_reasons,
            "favorites_in_selection": sum(1 for ex in final_selection if ex.get("is_favorite")),
            "consistency_boosted_count": sum(1 for ex in final_selection if ex.get("consistency_boosted")),
            "historical_weights_available": len(strength_history) if strength_history else 0,
            "variation_percentage": variation_percentage,
            # AI consistency tracking
            "readiness_score": readiness_score,
            "readiness_adjustment": adjusted_workout_params.get("readiness_adjustment"),
            "user_mood": user_mood,
            "mood_adjustment": adjusted_workout_params.get("mood_adjustment"),
            # Feedback-based difficulty adjustment
            "difficulty_adjustment": difficulty_adjustment,
            "difficulty_ceiling_used": adjusted_max_difficulty,
        }

        # Attach metadata to first exercise (will be extracted by generation.py)
        if final_selection:
            final_selection[0]["_selection_metadata"] = selection_metadata

        return final_selection

    async def _ai_select_exercises(
        self,
        candidates: List[Dict],
        focus_area: str,
        fitness_level: str,
        goals: List[str],
        count: int,
        injuries: Optional[List[str]] = None,
        workout_params: Optional[Dict] = None,
        strength_history: Optional[Dict[str, Dict]] = None,
        progression_pace: str = "medium",
    ) -> List[Dict[str, Any]]:
        """Use AI to select the best exercises from candidates."""

        candidate_list = "\n".join([
            f"{i+1}. {c['name']} - targets {c['target_muscle']}, equipment: {c['equipment']}, body part: {c['body_part']}"
            for i, c in enumerate(candidates)
        ])

        # Build injury awareness section
        injury_section = ""
        if injuries and len(injuries) > 0:
            injury_list = ", ".join(injuries)
            injury_section = f"""
CRITICAL SAFETY REQUIREMENT - USER HAS INJURIES
The user has the following injuries/conditions: {injury_list}

YOU MUST STRICTLY AVOID exercises that could aggravate these injuries.
The user's safety is the TOP PRIORITY. Only select exercises that are 100% SAFE.
"""

        prompt = f"""You are an expert fitness coach selecting exercises for a workout.

TARGET WORKOUT:
- Focus: {focus_area}
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Number of exercises needed: {count}
{injury_section}
AVAILABLE EXERCISES:
{candidate_list}

SELECTION CRITERIA:
1. {"SAFETY FIRST: Exclude any exercises that could aggravate the user's injuries" if injuries else "Choose exercises that best target the focus area"}
2. Choose exercises that best target the focus area ({focus_area})
3. CRITICAL: Each exercise number must be UNIQUE - do NOT repeat any numbers
4. Ensure variety - select DIFFERENT exercises for balanced muscle development
5. Progress from compound to isolation exercises
6. Consider the fitness level - {fitness_level}
7. Align with goals: {', '.join(goals) if goals else 'General fitness'}

IMPORTANT: You MUST select {count} DIFFERENT exercises. Each number in your response must be unique.

Return ONLY a JSON array of {count} UNIQUE exercise numbers (1-indexed), in the order they should be performed.
Example: [1, 5, 3, 8, 2, 6] - notice all numbers are different

Select exactly {count} UNIQUE exercises that are SAFE for this user."""

        try:
            system_content = "You are a fitness expert"
            if injuries:
                system_content += " and certified physical therapist. SAFETY IS YOUR TOP PRIORITY."
            system_content += ". Select exercises wisely. Return ONLY a JSON array of numbers."

            from google import genai
            from google.genai import types

            client = genai.Client(api_key=settings.gemini_api_key)
            response = await client.aio.models.generate_content(
                model=settings.gemini_model,
                contents=f"{system_content}\n\n{prompt}",
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    temperature=0.3,
                    max_output_tokens=2000,
                ),
            )

            content = response.text.strip()

            if content.startswith("```"):
                content = content.split("\n", 1)[1] if "\n" in content else content[3:]
            if content.endswith("```"):
                content = content[:-3]

            selected_indices = json.loads(content.strip())

            # Get selected exercises - ensure no duplicates
            selected = []
            seen_indices = set()
            seen_names = set()
            for idx in selected_indices:
                if 1 <= idx <= len(candidates):
                    # Skip if we've already selected this index
                    if idx in seen_indices:
                        logger.warning(f"AI returned duplicate index {idx}, skipping")
                        continue

                    ex = candidates[idx - 1]
                    exercise_name = ex.get('name', '').lower().strip()

                    # Skip if we've already selected an exercise with the same name
                    if exercise_name in seen_names:
                        logger.warning(f"AI returned duplicate exercise '{ex.get('name')}', skipping")
                        continue

                    seen_indices.add(idx)
                    seen_names.add(exercise_name)
                    selected.append(self._format_exercise_for_workout(
                        ex, fitness_level, workout_params, strength_history, progression_pace
                    ))

            # If we don't have enough exercises due to duplicates, try to fill from remaining candidates
            if len(selected) < count:
                logger.warning(f"Only got {len(selected)}/{count} unique exercises, filling from remaining candidates")
                for i, candidate in enumerate(candidates):
                    if len(selected) >= count:
                        break
                    if (i + 1) not in seen_indices:
                        exercise_name = candidate.get('name', '').lower().strip()
                        if exercise_name not in seen_names:
                            seen_indices.add(i + 1)
                            seen_names.add(exercise_name)
                            selected.append(self._format_exercise_for_workout(
                                candidate, fitness_level, workout_params, strength_history, progression_pace
                            ))

            logger.info(f"AI selected {len(selected)} unique exercises: {[e['name'] for e in selected]}")
            return selected

        except Exception as e:
            logger.error(f"AI selection failed: {e}")
            raise

    def _format_exercise_for_workout(
        self,
        exercise: Dict,
        fitness_level: str,
        workout_params: Optional[Dict] = None,
        strength_history: Optional[Dict[str, Dict]] = None,
        progression_pace: str = "medium",
    ) -> Dict:
        """
        Format an exercise for inclusion in a workout.

        Includes equipment-aware starting weight recommendations based on:
        - User's historical strength data (if available) - HIGHEST PRIORITY
        - Exercise type (compound vs isolation)
        - Equipment type (dumbbell, barbell, machine, etc.)
        - User's fitness level
        - Progression pace (affects rep ranges and volume)

        Args:
            exercise: Raw exercise data from the database
            fitness_level: User's fitness level (beginner, intermediate, advanced)
            workout_params: Optional adaptive parameters (sets, reps, rest_seconds)
            strength_history: Dict mapping exercise names to historical weight data
                              e.g. {"Bench Press": {"last_weight_kg": 70, "max_weight_kg": 85, "last_reps": 8}}

        Returns:
            Formatted exercise dict with realistic weight recommendations
        """
        # Validate fitness level to ensure consistent defaults
        validated_level = validate_fitness_level(fitness_level)

        if workout_params:
            sets = workout_params.get("sets", 3)
            reps = workout_params.get("reps", 12)
            rest = workout_params.get("rest_seconds", 60)
        elif validated_level == "beginner":
            # Beginner-appropriate defaults: lower volume, more rest
            sets, reps, rest = 2, 10, 90
        elif validated_level == "advanced":
            sets, reps, rest = 4, 12, 45
        else:  # intermediate
            sets, reps, rest = 3, 12, 60

        # Apply progression pace adjustments
        # slow: Higher reps, lower intensity - focus on technique and endurance
        # medium: Standard rep ranges (default)
        # fast: Lower reps, higher intensity - focus on strength gains
        if progression_pace == "slow":
            # Slow progression: +2 reps, slightly longer rest
            reps = min(reps + 2, 15)  # Cap at 15 reps
            rest = min(rest + 15, 120)  # Add 15 sec rest, cap at 2 min
            logger.debug(f"Slow progression: adjusted to {reps} reps, {rest}s rest")
        elif progression_pace == "fast":
            # Fast progression: -2 reps, shorter rest for intensity
            reps = max(reps - 2, 6)  # Minimum 6 reps
            rest = max(rest - 10, 30)  # Reduce rest, minimum 30s
            sets = min(sets + 1, 5)  # Add a set for more volume, cap at 5
            logger.debug(f"Fast progression: adjusted to {sets}x{reps}, {rest}s rest")

        exercise_name = exercise.get("name", "Unknown")
        raw_equipment = exercise.get("equipment", "")
        if not raw_equipment or raw_equipment.lower() in ["bodyweight", "body weight", "none", ""]:
            equipment = infer_equipment_from_name(exercise_name)
        else:
            equipment = raw_equipment

        # Get equipment type for weight calculations
        equipment_type = detect_equipment_type(exercise_name, [equipment] if equipment else None)

        # Calculate starting weight - prioritize historical data over generic estimates
        starting_weight = 0.0
        weight_source = "generic"  # Track where weight came from

        if equipment_type != "bodyweight" and equipment.lower() not in ["bodyweight", "body weight", "none", ""]:
            # PRIORITY 1: Use historical weight data if available
            if strength_history:
                # Try exact match first
                history = strength_history.get(exercise_name)
                if not history:
                    # Try case-insensitive match
                    for hist_name, hist_data in strength_history.items():
                        if hist_name.lower() == exercise_name.lower():
                            history = hist_data
                            break

                if history and history.get("last_weight_kg", 0) > 0:
                    # Use the user's last weight for this exercise
                    starting_weight = history["last_weight_kg"]
                    weight_source = "historical"
                    logger.info(f"Using historical weight for {exercise_name}: {starting_weight}kg (last used)")

            # PRIORITY 2: Fall back to generic weight estimate
            if starting_weight == 0.0:
                starting_weight = get_starting_weight(
                    exercise_name=exercise_name,
                    equipment_type=equipment_type,
                    fitness_level=validated_level,  # Use validated level
                )
                weight_source = "generic"

        return {
            "name": exercise_name,
            "sets": sets,
            "reps": reps,
            "rest_seconds": rest,
            "equipment": equipment,
            "equipment_type": equipment_type,  # Normalized equipment type for weight utilities
            "weight_kg": starting_weight,      # Recommended starting weight
            "weight_source": weight_source,    # "historical" or "generic" - indicates data source
            "muscle_group": exercise.get("target_muscle", exercise.get("body_part", "")),
            "body_part": exercise.get("body_part", ""),
            "notes": exercise.get("instructions", "Focus on proper form"),
            "gif_url": exercise.get("gif_url", ""),
            "video_url": exercise.get("video_url", ""),
            "image_url": exercise.get("image_url", ""),
            "library_id": exercise.get("id", ""),
            "is_favorite": exercise.get("is_favorite", False),  # From favorite boost
            "is_staple": exercise.get("is_staple", False),  # User's core lifts that never rotate
            "from_queue": exercise.get("from_queue", False),  # From exercise queue
        }

    def get_stats(self) -> Dict[str, Any]:
        """Get exercise RAG statistics."""
        return {
            "total_exercises": self.collection.count(),
            "storage": "chroma_cloud",
        }


# Singleton instance
_exercise_rag_service: Optional[ExerciseRAGService] = None


def get_exercise_rag_service() -> ExerciseRAGService:
    """Get the global ExerciseRAGService instance."""
    global _exercise_rag_service
    if _exercise_rag_service is None:
        gemini_service = GeminiService()
        _exercise_rag_service = ExerciseRAGService(gemini_service)
    return _exercise_rag_service
