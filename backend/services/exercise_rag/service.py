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
from models.gemini_schemas import ExerciseIndicesResponse

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
# NOTE: For beginners, this ceiling is STRICTLY enforced to prevent advanced exercises.
# For intermediate/advanced users, exercises are ranked by difficulty match.
DIFFICULTY_CEILING = {
    "beginner": 6,       # Beginner + intermediate exercises (1-6), strict filtering
    "intermediate": 8,   # Up to most advanced (1-8)
    "advanced": 10,      # All difficulties including elite
}

# Challenge exercise difficulty range for beginners (separate "Want a Challenge?" section)
CHALLENGE_DIFFICULTY_RANGE = {
    "min": 7,  # Minimum difficulty for challenge exercises
    "max": 8,  # Maximum difficulty for challenge exercises (not elite 9-10)
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

        try:
            _count = self.collection.count()
        except Exception:
            _count = "unknown"
        logger.info(f"Exercise RAG initialized with {_count} exercises")

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
        staple_exercises: Optional[List[dict]] = None,
        variation_percentage: int = 30,
        avoided_muscles: Optional[Dict[str, List[str]]] = None,
        progression_pace: str = "medium",
        workout_type_preference: str = "strength",
        readiness_score: Optional[int] = None,
        user_mood: Optional[str] = None,
        difficulty_adjustment: int = 0,
        batch_offset: int = 0,
        workout_environment: Optional[str] = None,
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
            staple_exercises: List of dicts with name, reason, muscle_group for user's staple exercises
            variation_percentage: How much variety user wants (0-100, default 30)
            avoided_muscles: Dict with 'avoid' (completely skip) and 'reduce' (lower priority) muscle lists
            progression_pace: User's progression pace - "slow", "medium", or "fast"
            workout_type_preference: User's workout type - "strength", "cardio", "mixed", "mobility", "recovery"
            readiness_score: User's readiness score (0-100) - affects workout intensity
            user_mood: User's current mood - affects workout type recommendation
            difficulty_adjustment: Feedback-based difficulty adjustment (-2 to +2).
                                   Positive values allow harder exercises, negative use easier ones.
            batch_offset: Offset for batch generation to ensure variety across parallel workouts.
                          Each workout in a batch should get a different offset (0, 1, 2, 3, ...).
                          This skips the first (batch_offset * count) candidates to ensure variety.

        Returns:
            List of selected exercises with full details
        """
        logger.info(f"Selecting {count} exercises for {focus_area} workout (batch_offset={batch_offset})")
        logger.info(f"Equipment: {equipment}, Dumbbells: {dumbbell_count}, Kettlebells: {kettlebell_count}")
        logger.info(f"Consistency mode: {consistency_mode}, Variation: {variation_percentage}%")
        logger.info(f"Progression pace: {progression_pace}, Workout type preference: {workout_type_preference}")

        # Adjust equipment based on workout environment
        if workout_environment:
            logger.info(f"Workout environment: {workout_environment}")
            from .filters import FULL_GYM_EQUIPMENT, HOME_GYM_EQUIPMENT
            env_lower = workout_environment.lower()
            if "gym" in env_lower and "home" not in env_lower:
                # Commercial gym - ensure full gym equipment available
                if not any("full_gym" in eq.lower() or "full gym" in eq.lower() for eq in equipment):
                    equipment = list(set(equipment + FULL_GYM_EQUIPMENT))
                    logger.info(f"Expanded equipment for gym environment: {len(equipment)} items")
            elif "home" in env_lower:
                # Home gym - restrict to home equipment only
                if not any("home_gym" in eq.lower() or "home gym" in eq.lower() for eq in equipment):
                    equipment = [eq for eq in equipment if eq.lower() in HOME_GYM_EQUIPMENT or eq.lower() == "bodyweight"]
                    if not equipment:
                        equipment = HOME_GYM_EQUIPMENT
                    logger.info(f"Filtered equipment for home environment: {equipment}")
            elif "outdoor" in env_lower or "park" in env_lower:
                # Outdoor - bodyweight and minimal equipment
                equipment = ["bodyweight", "pull_up_bar", "resistance_bands"]
                logger.info(f"Set equipment for outdoor environment: {equipment}")

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
        # Extract staple names (supports both old List[str] and new List[dict] format)
        staple_names = []
        if staple_exercises:
            for s in staple_exercises:
                if isinstance(s, dict):
                    staple_names.append(s.get("name", ""))
                else:
                    staple_names.append(s)
            staple_names = [n for n in staple_names if n]  # Remove empty names
            logger.info(f"User has {len(staple_names)} staple exercises (never rotated): {staple_names}")
            # CRITICAL: Never put staples in avoid list - they should always be included
            if avoid_exercises:
                staple_lower = [s.lower() for s in staple_names]
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
        candidate_count = min(count * 6, 40)

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

                # Use STRICT filtering for beginners (ceiling of 6, only beginner+intermediate exercises)
                # Use permissive filtering for intermediate/advanced users (more variety)
                # difficulty_adjustment from user feedback can increase the ceiling
                if validated_fitness_level == "beginner":
                    if is_exercise_too_difficult_strict(exercise_difficulty, validated_fitness_level, difficulty_adjustment):
                        logger.debug(f"Filtered out '{meta.get('name')}' - too difficult ({exercise_difficulty}) for beginner (strict, adjustment={difficulty_adjustment})")
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
                # SAFETY FIX: Don't keep unsafe exercises - instead, select the least risky ones
                logger.warning(f"Injury filter too restrictive - all {len(candidates)} exercises flagged as unsafe")
                logger.warning(f"User injuries: {injuries}")
                # Sort by how many injury patterns they match (fewer = safer)
                # This ensures we pick the "safest" of the unsafe options rather than random
                from .filters import INJURY_CONTRAINDICATIONS
                active_patterns = set()
                for injury in [inj.lower() for inj in injuries]:
                    for key, patterns in INJURY_CONTRAINDICATIONS.items():
                        if key in injury:
                            active_patterns.update(patterns)

                def count_matches(candidate):
                    name_lower = candidate.get("name", "").lower()
                    target_lower = candidate.get("target_muscle", "").lower()
                    body_lower = candidate.get("body_part", "").lower()
                    count = 0
                    for pattern in active_patterns:
                        if pattern in name_lower or pattern in target_lower or pattern in body_lower:
                            count += 1
                    return count

                # Sort by match count (ascending) so least-risky exercises are first
                candidates.sort(key=lambda c: (count_matches(c), -c.get("similarity", 0)))
                # Take only exercises with minimum matches
                if candidates:
                    min_matches = count_matches(candidates[0])
                    candidates = [c for c in candidates if count_matches(c) == min_matches]
                    logger.info(f"Selected {len(candidates)} least-risky exercises (match count: {min_matches})")

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

        if staple_names:  # Use extracted staple_names from earlier
            staple_names_lower = [s.lower() for s in staple_names]

            # Build a map of staple name -> reason for tagging
            staple_reasons = {}
            if staple_exercises:
                for s in staple_exercises:
                    if isinstance(s, dict):
                        staple_reasons[s.get("name", "").lower()] = s.get("reason", "favorite")

            # Find staple exercises in candidates
            for staple_name in staple_names:
                staple_lower = staple_name.lower()
                for candidate in candidates:
                    if candidate["name"].lower() == staple_lower:
                        staple_included.append(candidate)
                        staple_names_used.append(candidate["name"])
                        candidate["is_staple"] = True
                        candidate["staple_reason"] = staple_reasons.get(staple_lower, "favorite")
                        reason_label = staple_reasons.get(staple_lower, "favorite")
                        logger.info(f"Including STAPLE exercise: {candidate['name']} (reason: {reason_label})")
                        break

            # Remove staples from candidates to avoid duplicates
            candidates = [c for c in candidates if c["name"].lower() not in staple_names_lower]
            logger.info(f"Staples included: {len(staple_included)} of {len(staple_names)}")

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
            # Apply batch offset to ensure variety across parallel workout generations
            # Each workout in a batch gets a different offset (0, 1, 2, ...) to select
            # different exercises from the candidate pool
            offset_start = batch_offset * count
            offset_end = offset_start + 20  # Get 20 candidates starting from offset

            # Ensure we have enough candidates by using modulo wrap-around
            if len(candidates) > 0:
                if offset_start >= len(candidates):
                    # Wrap around if offset is beyond candidate list
                    offset_start = offset_start % len(candidates)
                    offset_end = offset_start + 20

                # Get candidates with offset
                if offset_end <= len(candidates):
                    offset_candidates = candidates[offset_start:offset_end]
                else:
                    # Wrap around to beginning if needed
                    offset_candidates = candidates[offset_start:] + candidates[:offset_end - len(candidates)]
                    # Remove duplicates from wrap-around
                    seen_oc = set()
                    unique_oc = []
                    for c in offset_candidates:
                        key = c['name'].lower().strip()
                        if key not in seen_oc:
                            seen_oc.add(key)
                            unique_oc.append(c)
                    offset_candidates = unique_oc

                if batch_offset > 0:
                    logger.info(f"🎯 [Batch Variety] Applied batch_offset={batch_offset}, using candidates [{offset_start}:{offset_end}] (total: {len(candidates)})")
            else:
                offset_candidates = candidates[:20]

            # Use AI to select remaining exercises
            selected = await self._ai_select_exercises(
                candidates=offset_candidates[:20],  # Ensure max 20
                focus_area=focus_area,
                fitness_level=fitness_level,
                goals=goals,
                count=remaining_count,
                injuries=injuries,
                workout_params=adjusted_workout_params,
                strength_history=strength_history,
                progression_pace=progression_pace,
            )

            # Backfill from full candidate pool if AI returned too few
            if len(selected) < remaining_count:
                all_used = {e['name'].lower().strip() for e in selected}
                all_used |= {s['name'].lower().strip() for s in staple_included}
                all_used |= {q['name'].lower().strip() for q in queued_included}
                for candidate in candidates:  # Full pool, not offset slice
                    if len(selected) >= remaining_count:
                        break
                    if candidate['name'].lower().strip() not in all_used:
                        all_used.add(candidate['name'].lower().strip())
                        selected.append(self._format_exercise_for_workout(
                            candidate, fitness_level, adjusted_workout_params,
                            strength_history, progression_pace
                        ))
                if len(selected) < remaining_count:
                    logger.warning(
                        f"Could only select {len(selected)}/{remaining_count} exercises "
                        f"from {len(candidates)} total candidates"
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

        # Deduplicate candidates by name (keep first occurrence = highest similarity)
        seen_cand_names = set()
        deduped = []
        for c in candidates:
            key = c['name'].lower().strip()
            if key not in seen_cand_names:
                seen_cand_names.add(key)
                deduped.append(c)
        candidates = deduped

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
5. USE EQUIPMENT VARIETY - Include exercises with different equipment types (barbell, dumbbell, cable, machine) rather than only bodyweight exercises. The user has access to gym equipment.
6. Progress from compound to isolation exercises
7. Consider the fitness level - {fitness_level} (but still use weights - beginners benefit from learning barbell and dumbbell movements)
8. Align with goals: {', '.join(goals) if goals else 'General fitness'}

IMPORTANT: You MUST select {count} DIFFERENT exercises. Each number in your response must be unique.

Return a JSON object with "selected_indices" array containing {count} UNIQUE exercise numbers (1-indexed), in the order they should be performed.
Example: {{"selected_indices": [1, 5, 3, 8, 2, 6]}} - notice all numbers are different

Select exactly {count} UNIQUE exercises that are SAFE for this user."""

        try:
            system_content = "You are a fitness expert"
            if injuries:
                system_content += " and certified physical therapist. SAFETY IS YOUR TOP PRIORITY."
            system_content += ". Select exercises wisely. Return ONLY valid JSON."

            from google.genai import types
            from core.gemini_client import get_genai_client

            client = get_genai_client()
            response = await client.aio.models.generate_content(
                model=settings.gemini_model,
                contents=f"{system_content}\n\n{prompt}",
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=ExerciseIndicesResponse,
                    temperature=0.3,
                    max_output_tokens=2000,
                ),
            )

            content = response.text.strip()
            data = json.loads(content)
            selected_indices = data.get("selected_indices", [])

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

    def _detect_unilateral(self, exercise_name: str, metadata: dict = None) -> bool:
        """
        Detect if exercise is unilateral (single-arm/leg).

        Unilateral exercises work one side at a time and should display
        "(each side)" in the UI so users know the weight is per side.

        Args:
            exercise_name: Name of the exercise
            metadata: Optional exercise metadata from RAG

        Returns:
            True if exercise is unilateral (single-sided)
        """
        if not exercise_name:
            return False

        name_lower = exercise_name.lower()

        # Keywords that indicate unilateral exercises
        unilateral_keywords = [
            "single arm", "single-arm", "one arm", "one-arm",
            "single leg", "single-leg", "one leg", "one-leg",
            "alternate", "alternating", "unilateral",
            "split squat", "bulgarian split",
            "lunge", "step up", "step-up",
            "pistol squat", "pistol",
            "single dumbbell", "one dumbbell",
        ]

        if any(kw in name_lower for kw in unilateral_keywords):
            return True

        # Check metadata if available
        if metadata:
            if metadata.get("is_unilateral", False):
                return True
            if metadata.get("alternating_hands", False):
                return True

        return False

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
        exercise_name = exercise.get("name", "Unknown")

        # Import exercise classification utilities
        from core.exercise_data import get_exercise_type, REP_LIMITS

        # 1. CLASSIFY EXERCISE using existing utility
        exercise_type = get_exercise_type(exercise_name)  # compound_upper, compound_lower, isolation, bodyweight

        # 2. GET REP RANGE based on exercise type (not just fitness level)
        min_reps, max_reps = REP_LIMITS.get(exercise_type, (8, 12))

        if workout_params:
            # Use adaptive params if provided
            sets = workout_params.get("sets", 3)
            reps = workout_params.get("reps", 12)
            rest = workout_params.get("rest_seconds", 60)
        else:
            # 3. DETERMINE SETS based on exercise type + fitness level
            if exercise_type in ["compound_upper", "compound_lower"]:
                # Compounds: More sets for strength development
                base_sets = {"beginner": 3, "intermediate": 4, "advanced": 5}
            else:
                # Isolation/Bodyweight: Fewer sets
                base_sets = {"beginner": 2, "intermediate": 3, "advanced": 4}
            sets = base_sets.get(validated_level, 3)

            # 4. DETERMINE REPS based on exercise type + fitness level
            if validated_level == "beginner":
                reps = max_reps  # Higher reps for technique focus
            elif validated_level == "advanced":
                reps = min_reps  # Lower reps for strength focus
            else:
                reps = (min_reps + max_reps) // 2  # Middle ground

            # 5. REST based on exercise type (compounds need more rest)
            if exercise_type in ["compound_upper", "compound_lower"]:
                rest_map = {"beginner": 120, "intermediate": 90, "advanced": 60}
            else:
                rest_map = {"beginner": 90, "intermediate": 60, "advanced": 45}
            rest = rest_map.get(validated_level, 60)

        # Apply progression pace adjustments
        # slow: Higher reps, lower intensity - focus on technique and endurance
        # medium: Standard rep ranges (default)
        # fast: Lower reps, higher intensity - focus on strength gains
        if progression_pace == "slow":
            # Slow progression: +2 reps, slightly longer rest
            reps = min(reps + 2, max_reps)  # Cap at max_reps for exercise type
            rest = min(rest + 15, 150)  # Add 15 sec rest, cap at 2.5 min
            logger.debug(f"Slow progression: adjusted to {reps} reps, {rest}s rest")
        elif progression_pace == "fast":
            # Fast progression: -2 reps, shorter rest for intensity
            reps = max(reps - 2, min_reps)  # Minimum at min_reps for exercise type
            rest = max(rest - 15, 30)  # Reduce rest, minimum 30s
            sets = min(sets + 1, 6)  # Add a set for more volume, cap at 6
            logger.debug(f"Fast progression: adjusted to {sets}x{reps}, {rest}s rest")
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

        # Generate set_targets array based on available data
        # This is CRITICAL - without set_targets, validate_set_targets_strict() will fail
        # Valid set_types: "warmup" (W), "working", "drop" (D), "failure" (F), "amrap" (A)
        set_targets = []
        is_bodyweight = equipment_type == "bodyweight" or equipment.lower() in ["bodyweight", "body weight", "none", ""]

        # Helper function for research-backed RPE to RIR mapping
        def rpe_to_rir(rpe: float) -> int:
            """
            Convert RPE to RIR using research-backed mapping.
            Based on modern training science (Helms et al., Zourdos et al.)
            """
            if rpe >= 10.0:
                return 0  # Max effort, no reps left
            elif rpe >= 9.5:
                return 0  # Maybe 1 more rep (effectively 0)
            elif rpe >= 9.0:
                return 1  # Definitely 1 more rep
            elif rpe >= 8.5:
                return 1  # 1-2 reps left (round to 1)
            elif rpe >= 8.0:
                return 2  # 2 reps left
            elif rpe >= 7.5:
                return 2  # 2-3 reps left (round to 2)
            elif rpe >= 7.0:
                return 3  # 3 reps left
            elif rpe >= 6.0:
                return 4  # 4 reps left (light effort)
            else:
                return 5  # 5+ reps left (warmup/easy)

        # Universal RIR progression for ALL fitness levels (MacroFactor-style)
        # Research shows beginners underpredict RIR by ~1 rep, so conservative RIR 3
        # leads to actual RIR 5-6 = no training stimulus. Same RIR for all levels,
        # weight is what varies by fitness level.
        is_compound = exercise_type in ["compound_upper", "compound_lower"]

        def get_working_set_rir(set_number: int, total_sets: int, is_compound_ex: bool) -> int:
            """
            Universal RIR progression: 2 → 1 → 0-1
            Same for ALL fitness levels. Weight is the differentiator.
            """
            if set_number == 1:
                return 2  # First working set: RIR 2 (yellow)
            elif set_number == 2:
                return 1  # Second set: RIR 1 (orange)
            else:
                # Later sets: RIR 1 for compounds (safety), RIR 0 for isolation
                return 1 if is_compound_ex else 0

        def get_weight_for_rir(base_weight: float, target_rir: int, equipment_type: str) -> float:
            """
            Calculate weight based on RIR target.
            Lower RIR = higher weight (each RIR drop ≈ 5% weight increase).

            RIR 2 = base weight (100%)
            RIR 1 = base weight + 5%
            RIR 0 = base weight + 10%
            """
            if base_weight <= 0:
                return 0

            # Weight multiplier based on RIR (RIR 2 is baseline)
            rir_multipliers = {
                2: 1.00,   # Baseline
                1: 1.05,   # +5%
                0: 1.10,   # +10%
            }
            multiplier = rir_multipliers.get(target_rir, 1.0)
            raw_weight = base_weight * multiplier

            # Round to equipment-appropriate increment
            increment = {
                "dumbbell": 2.5,
                "dumbbells": 2.5,
                "barbell": 2.5,
                "machine": 5.0,
                "cable": 2.5,
                "kettlebell": 4.0,
                "smith_machine": 2.5,
                "ez_bar": 2.5,
            }.get(equipment_type.lower() if equipment_type else "barbell", 2.5)

            return round(raw_weight / increment) * increment

        for set_num in range(1, sets + 1):
            # WARMUP SET: First set for compound exercises with weights
            if set_num == 1 and is_compound and not is_bodyweight and starting_weight > 0:
                set_targets.append({
                    "set_number": set_num,
                    "set_type": "warmup",  # W
                    "target_reps": min(reps + 2, 15),  # Higher reps for warmup
                    "target_weight_kg": round(starting_weight * 0.5, 1),  # 50% weight
                    "target_rpe": 5,
                    "target_rir": 5,  # Warmup = lots in tank
                })
            else:
                # WORKING SETS: Universal RIR progression (same for all fitness levels)
                # Adjust set_num for warmup offset if compound exercise
                adjusted_set_num = set_num - 1 if (is_compound and not is_bodyweight and starting_weight > 0) else set_num

                # Get RIR based on set position (2 → 1 → 0-1)
                target_rir = get_working_set_rir(adjusted_set_num, sets, is_compound)

                # Calculate weight based on RIR (lower RIR = higher weight)
                set_weight = get_weight_for_rir(starting_weight, target_rir, equipment_type)

                # Calculate RPE from RIR
                # RIR 2 → RPE 8, RIR 1 → RPE 9, RIR 0 → RPE 10
                target_rpe = 10 - target_rir

                # Determine set type based on RIR
                if target_rir == 0:
                    set_type = "failure"  # F - max effort
                else:
                    set_type = "working"

                set_targets.append({
                    "set_number": set_num,
                    "set_type": set_type,
                    "target_reps": reps,
                    "target_weight_kg": set_weight if not is_bodyweight else 0,
                    "target_rpe": target_rpe,
                    "target_rir": target_rir,
                })

        logger.debug(f"Generated {len(set_targets)} set_targets for {exercise_name} (type={exercise_type}, bodyweight={is_bodyweight})")

        # Detect if this is a unilateral exercise (single-arm/leg)
        # Used to display "(each side)" in the UI for weight interpretation
        is_unilateral = self._detect_unilateral(exercise_name, exercise)

        # Check if this is a timed exercise (planks, wall sits, holds)
        is_timed = exercise.get("is_timed", False)
        hold_seconds = exercise.get("default_hold_seconds")

        # For timed exercises, set reps to 1 (time-based, not rep-based)
        if is_timed and hold_seconds:
            reps = 1

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
            "is_unilateral": is_unilateral,  # True if single-arm/leg - display "(each side)" in UI
            "is_timed": is_timed,  # True for planks, wall sits, holds - display timer instead of reps
            "hold_seconds": hold_seconds,  # Default hold time for timed exercises
            "set_targets": set_targets,  # CRITICAL: Required by validate_set_targets_strict()
        }

    async def select_challenge_exercise(
        self,
        main_exercises: List[Dict],
        focus_area: str,
        equipment: List[str],
        fitness_level: str = "beginner",
        injuries: Optional[List[str]] = None,
        avoided_muscles: Optional[Dict[str, List[str]]] = None,
        workout_params: Optional[Dict] = None,
        strength_history: Optional[Dict[str, Dict]] = None,
    ) -> Optional[Dict]:
        """
        Select exactly 1 challenge exercise for beginners and intermediate users.

        This provides a "Want a Challenge?" section with a harder exercise
        that users can optionally try. The challenge exercise:
        - Has difficulty higher than main workout ceiling
        - Is NOT in the main_exercises (no duplicates)
        - Should be a progression of an exercise in main workout if possible
        - Uses RAG to find the best match

        Args:
            main_exercises: Main workout exercises (to avoid duplicates)
            focus_area: Target muscle group/body part
            equipment: Available equipment list
            fitness_level: User's fitness level (beginner or intermediate)
            injuries: List of injuries to avoid
            avoided_muscles: Muscles to avoid/reduce
            workout_params: Workout parameters (sets/reps/rest)
            strength_history: User's strength history for weight recommendations

        Returns:
            A single challenge exercise dict, or None if not applicable/found
        """
        # Only provide challenge exercises for beginners and intermediate
        # Advanced/hard/hell users already have challenging exercises
        if fitness_level not in ("beginner", "intermediate"):
            logger.debug(f"Challenge exercise only for beginner/intermediate, skipping for {fitness_level}")
            return None

        # Get names of main exercises to exclude (no duplicates)
        main_exercise_names = {ex.get("name", "").lower() for ex in main_exercises}
        logger.info(f"🔥 Selecting challenge exercise for {fitness_level}, excluding: {main_exercise_names}")

        try:
            # Build search query for challenge exercises
            search_query = f"advanced {focus_area} exercise progression challenge"

            # Query ChromaDB for exercises matching the focus area
            results = self.collection.query(
                query_texts=[search_query],
                n_results=50,  # Get more candidates to filter
                include=["metadatas", "distances"],
            )

            if not results or not results["metadatas"] or not results["metadatas"][0]:
                logger.warning("🔥 [Challenge] No candidates found in ChromaDB for query: %s", search_query)
                return None

            metadatas = results["metadatas"][0]
            distances = results["distances"][0] if results["distances"] else []
            logger.info(f"🔥 [Challenge] Found {len(metadatas)} initial candidates from ChromaDB")

            # Log difficulty distribution for debugging
            difficulty_counts = {}
            for meta in metadatas:
                d = meta.get("difficulty", "unknown")
                difficulty_counts[d] = difficulty_counts.get(d, 0) + 1
            logger.info(f"🔥 [Challenge] Difficulty distribution: {difficulty_counts}")

            # Filter candidates for challenge exercises
            challenge_candidates = []
            filter_stats = {"duplicate": 0, "difficulty": 0, "equipment": 0, "injury": 0, "avoided": 0, "no_media": 0}

            for i, meta in enumerate(metadatas):
                exercise_name = meta.get("name", "Unknown")
                exercise_name_lower = exercise_name.lower()

                # Skip if in main exercises (no duplicates)
                if exercise_name_lower in main_exercise_names:
                    filter_stats["duplicate"] += 1
                    continue

                # Check difficulty is in challenge range (5-8 for intermediate/advanced)
                exercise_difficulty = meta.get("difficulty", "beginner")
                difficulty_num = get_difficulty_numeric(exercise_difficulty)

                if difficulty_num < CHALLENGE_DIFFICULTY_RANGE["min"] or difficulty_num > CHALLENGE_DIFFICULTY_RANGE["max"]:
                    filter_stats["difficulty"] += 1
                    continue

                # Check equipment compatibility
                ex_equipment = (meta.get("equipment", "") or "").lower()
                equipment_lower = [e.lower() for e in equipment] if equipment else []

                if ex_equipment and ex_equipment not in ["bodyweight", "body weight", "none", ""]:
                    if not any(eq in ex_equipment for eq in equipment_lower):
                        filter_stats["equipment"] += 1
                        continue

                # Filter by injuries
                if injuries:
                    primary_muscle = (meta.get("target_muscle", "") or "").lower()
                    secondary_muscles = parse_secondary_muscles(meta.get("secondary_muscles", []))

                    is_safe = pre_filter_by_injuries(
                        exercise_name=exercise_name,
                        primary_muscle=primary_muscle,
                        secondary_muscles=secondary_muscles,
                        injuries=injuries
                    )
                    if not is_safe:
                        filter_stats["injury"] += 1
                        continue

                # Filter by avoided muscles
                if avoided_muscles:
                    primary_muscle = (meta.get("target_muscle", "") or "").lower()
                    secondary_muscles = parse_secondary_muscles(meta.get("secondary_muscles", []))

                    avoid_list = avoided_muscles.get("avoid", [])
                    if any(am.lower() in primary_muscle for am in avoid_list):
                        filter_stats["avoided"] += 1
                        continue

                # Must have media
                has_media = bool(meta.get("gif_url") or meta.get("video_url") or meta.get("image_url"))
                if not has_media:
                    filter_stats["no_media"] += 1
                    continue

                # Calculate similarity score
                similarity = 1 - distances[i] if i < len(distances) else 0.5

                # Check if this is a progression of a main exercise
                progression_from = None
                for main_ex in main_exercises:
                    main_name = main_ex.get("name", "").lower()
                    # Check if exercise names are related (e.g., "Push-up" -> "Diamond Push-up")
                    if self._is_progression_of(exercise_name_lower, main_name):
                        progression_from = main_ex.get("name")
                        # Boost similarity for progression exercises
                        similarity = min(1.0, similarity * 1.5)
                        break

                challenge_candidates.append({
                    "id": meta.get("exercise_id", ""),
                    "name": clean_exercise_name_for_display(exercise_name),
                    "body_part": meta.get("body_part", ""),
                    "equipment": meta.get("equipment", "bodyweight"),
                    "target_muscle": meta.get("target_muscle", ""),
                    "secondary_muscles": meta.get("secondary_muscles", []),
                    "difficulty": exercise_difficulty,
                    "difficulty_num": difficulty_num,
                    "gif_url": meta.get("gif_url", ""),
                    "video_url": meta.get("video_url", ""),
                    "image_url": meta.get("image_url", ""),
                    "instructions": meta.get("instructions", ""),
                    "similarity": similarity,
                    "progression_from": progression_from,
                    "is_challenge": True,
                })

            if not challenge_candidates:
                logger.warning(f"🔥 [Challenge] No valid candidates after filtering. Stats: {filter_stats}")
                return None

            logger.info(f"🔥 [Challenge] Found {len(challenge_candidates)} valid candidates after filtering. Filter stats: {filter_stats}")

            # Sort by similarity (prefer progressions which got boosted)
            challenge_candidates.sort(key=lambda x: x["similarity"], reverse=True)

            # Select the best challenge exercise
            best_challenge = challenge_candidates[0]

            # Format for workout
            formatted = self._format_exercise_for_workout(
                best_challenge,
                fitness_level,
                workout_params,
                strength_history,
                progression_pace="slow",  # Conservative for challenge exercises
            )

            # Add challenge-specific fields
            formatted["is_challenge"] = True
            formatted["progression_from"] = best_challenge.get("progression_from")
            formatted["difficulty"] = best_challenge.get("difficulty")
            formatted["difficulty_num"] = best_challenge.get("difficulty_num")

            logger.info(f"🔥 Selected challenge exercise: {formatted['name']} (difficulty: {best_challenge['difficulty_num']}, progression_from: {best_challenge.get('progression_from', 'N/A')})")

            return formatted

        except Exception as e:
            logger.error(f"Error selecting challenge exercise: {e}")
            return None

    def _is_progression_of(self, challenge_name: str, main_name: str) -> bool:
        """
        Check if the challenge exercise is a progression of a main exercise.

        Examples:
        - "diamond push-up" is a progression of "push-up"
        - "archer pull-up" is a progression of "pull-up"
        - "jump squat" is a progression of "squat"
        """
        challenge_lower = challenge_name.lower()
        main_lower = main_name.lower()

        # Direct progression patterns
        progression_patterns = [
            # Push-up progressions
            ("push-up", ["diamond push-up", "decline push-up", "archer push-up", "chest tap push-up", "pike push-up", "clap push-up"]),
            ("push up", ["diamond push up", "decline push up", "archer push up", "chest tap push up", "pike push up", "clap push up"]),
            # Pull-up progressions
            ("pull-up", ["archer pull-up", "wide grip pull-up", "l-sit pull-up", "muscle-up"]),
            ("pull up", ["archer pull up", "wide grip pull up", "l-sit pull up", "muscle up"]),
            # Squat progressions
            ("squat", ["jump squat", "pistol squat", "shrimp squat", "bulgarian split squat"]),
            ("goblet squat", ["front squat", "barbell squat"]),
            # Row progressions
            ("row", ["one-arm row", "archer row", "explosive row"]),
            # Plank progressions
            ("plank", ["side plank", "plank to push-up", "commando plank"]),
            # Lunge progressions
            ("lunge", ["jump lunge", "walking lunge", "reverse lunge"]),
        ]

        for base_exercise, progressions in progression_patterns:
            if base_exercise in main_lower:
                if any(prog in challenge_lower for prog in progressions):
                    return True

        # Check if challenge contains main exercise name (generic progression)
        # e.g., "incline dumbbell press" -> "decline dumbbell press"
        main_words = set(main_lower.split())
        challenge_words = set(challenge_lower.split())
        common_words = main_words & challenge_words

        # If they share significant words but challenge has modifiers
        if len(common_words) >= 2 and challenge_words != main_words:
            return True

        return False

    def get_stats(self) -> Dict[str, Any]:
        """Get exercise RAG statistics."""
        try:
            c = self.collection.count()
            total = c if c >= 0 else -1
        except Exception:
            total = -1
        return {
            "total_exercises": total,
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
