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
from services.gemini_service import GeminiService
from services.gemini.constants import gemini_generate_with_retry, settings as gemini_settings
from models.gemini_schemas import ExerciseIndicesResponse

from .utils import clean_exercise_name_for_display, infer_equipment_from_name
from .filters import (
    filter_by_equipment,
    is_similar_exercise,
    is_stretch_exercise,
    is_warmup_filler_exercise,
    pre_filter_by_injuries,
    filter_by_avoided_muscles,
    parse_secondary_muscles,
)
from .search import build_search_query, build_search_query_with_custom_goals
from .difficulty import (  # noqa: F401 - re-exported for backward compatibility
    DIFFICULTY_CEILING,
    CHALLENGE_DIFFICULTY_RANGE,
    DIFFICULTY_RATIOS,
    DIFFICULTY_STRING_TO_NUM,
    VALID_FITNESS_LEVELS,
    DEFAULT_FITNESS_LEVEL,
    _BENCH_REQUIRED_PATTERNS,
    _SQUAT_RACK_REQUIRED_PATTERNS,
    _needs_bench,
    validate_fitness_level,
    get_difficulty_numeric,
    get_adjusted_difficulty_ceiling,
    get_exercise_difficulty_category,
    get_difficulty_score,
    is_exercise_too_difficult,
    is_exercise_too_difficult_strict,
)
from .formatting import (
    format_exercise_for_workout,
    detect_unilateral,
    is_progression_of,
)
from .selection_pipeline import (
    apply_difficulty_scoring,
    boost_equipment_matches,
    cap_bodyweight_exercises,
    apply_injury_filter,
    apply_avoided_muscles_filter,
    apply_workout_type_filter,
    apply_favorites_boost,
    apply_consistency_mode,
    extract_staple_exercises,
    extract_queued_exercises,
    adjust_workout_params_for_readiness,
)

settings = get_settings()
logger = get_logger(__name__)


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

        # Second collection for user-created custom exercises.
        # Scoped by user_id in metadata; public exercises are queryable across users.
        try:
            self.custom_collection = self.chroma_client.get_or_create_collection(
                name="custom_exercise_library",
                metadata={"hnsw:space": "cosine"},
            )
        except TypeError:
            # Older chroma-cloud clients may not accept metadata kwarg.
            self.custom_collection = self.chroma_client.get_or_create_collection(
                "custom_exercise_library"
            )

        try:
            _count = self.collection.count()
        except Exception as e:
            logger.warning(f"Failed to get collection count: {e}", exc_info=True)
            _count = "unknown"
        try:
            _custom_count = self.custom_collection.count()
        except Exception as e:
            logger.warning(f"Failed to get custom collection count: {e}", exc_info=True)
            _custom_count = "unknown"
        logger.info(
            f"Exercise RAG initialized with {_count} library exercises, "
            f"{_custom_count} custom exercises"
        )

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

        # Filter and deduplicate (use dedup_key so Burpee / Burpee(1) collapse)
        from .utils import dedup_key
        seen_names: set = set()
        exercises = []
        for ex in all_exercises:
            if not ex.get("video_url") and not ex.get("video_s3_path"):
                continue

            # Skip exercises with missing critical metadata
            if not ex.get("body_part") or not ex.get("target_muscle"):
                continue

            exercise_name = ex.get("name", ex.get("exercise_name_cleaned", ex.get("exercise_name", "")))
            key = dedup_key(exercise_name)
            if not key or key in seen_names:
                continue
            seen_names.add(key)
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
                    "equipment": str(ex.get("equipment") or infer_equipment_from_name(exercise_name)),
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
                    "bench_required": "true" if _needs_bench(ex.get("name", "")) else "false",
                })

            try:
                embeddings = await self.gemini_service.get_embeddings_batch_async(documents)
                logger.info(f"   Got {len(embeddings)} embeddings in 1 API call")
            except Exception as e:
                logger.error(f"Failed to get batch embeddings: {e}", exc_info=True)
                continue

            if ids and embeddings:
                try:
                    try:
                        self.collection.delete(ids=ids)
                    except Exception as e:
                        logger.debug(f"ChromaDB batch delete: {e}")

                    self.collection.add(
                        ids=ids,
                        embeddings=embeddings,
                        documents=documents,
                        metadatas=metadatas,
                    )
                    indexed_count += len(ids)
                    logger.info(f"   Indexed {len(ids)} exercises to Chroma Cloud")
                except Exception as e:
                    logger.error(f"Failed to index batch to Chroma: {e}", exc_info=True)

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

    # =========================================================================
    # Custom Exercise Indexing (user-created exercises)
    # =========================================================================

    def _build_custom_exercise_text(self, exercise: Dict[str, Any]) -> str:
        """Build the embedding text for a custom exercise row. Mirrors library shape."""
        name = exercise.get("name") or "Custom Exercise"
        body_part = exercise.get("body_part") or ""
        target_muscles = exercise.get("target_muscles") or []
        secondary = exercise.get("secondary_muscles") or []
        equipment = exercise.get("equipment") or "bodyweight"
        difficulty = exercise.get("difficulty_level") or ""
        exercise_type = exercise.get("exercise_type") or "strength"
        movement_type = exercise.get("movement_type") or "dynamic"
        instructions = exercise.get("instructions") or ""

        if isinstance(target_muscles, str):
            target_muscles = [target_muscles]
        if isinstance(secondary, str):
            secondary = [secondary]

        text_parts = [
            f"Exercise: {name}",
            f"Body Part: {body_part}",
            f"Target Muscle: {', '.join(target_muscles) if target_muscles else ''}",
            f"Equipment: {equipment}",
        ]
        if secondary:
            text_parts.append(f"Secondary Muscles: {', '.join(secondary)}")
        if exercise_type:
            text_parts.append(f"Category: {exercise_type}")
        if movement_type:
            text_parts.append(f"Movement: {movement_type}")
        if difficulty:
            text_parts.append(f"Difficulty: {difficulty}")
        if instructions:
            text_parts.append(f"Instructions: {str(instructions)[:300]}")
        return "\n".join(text_parts)

    def _build_custom_metadata(self, exercise: Dict[str, Any]) -> Dict[str, Any]:
        """Build ChromaDB metadata dict for a custom exercise."""
        target_muscles = exercise.get("target_muscles") or []
        if isinstance(target_muscles, str):
            target_muscles = [target_muscles]

        secondary = exercise.get("secondary_muscles") or []
        if isinstance(secondary, str):
            secondary = [secondary]

        raw_name = exercise.get("name", "Custom Exercise")
        cleaned_name = clean_exercise_name_for_display(raw_name)

        # Primary target_muscle (first element) for parity with library schema.
        primary_target = target_muscles[0] if target_muscles else ""

        return {
            "exercise_id": str(exercise.get("id") or ""),
            "name": cleaned_name,
            "body_part": str(exercise.get("body_part") or ""),
            "equipment": str(exercise.get("equipment") or "bodyweight"),
            "target_muscle": str(primary_target),
            "target_muscles": json.dumps(list(target_muscles)),
            "secondary_muscles": json.dumps(list(secondary)),
            "difficulty": str(exercise.get("difficulty_level") or "intermediate"),
            "category": str(exercise.get("exercise_type") or "strength"),
            "movement_type": str(exercise.get("movement_type") or "dynamic"),
            "gif_url": str(exercise.get("image_url") or ""),
            "video_url": str(exercise.get("video_url") or ""),
            "image_url": str(exercise.get("image_url") or ""),
            "instructions": str(exercise.get("instructions") or "")[:500],
            "has_video": "true" if exercise.get("video_url") else "false",
            "is_custom": "true",
            "user_id": str(exercise.get("user_id") or ""),
            "is_public": bool(exercise.get("is_public", False)),
            "is_warmup_suitable": bool(exercise.get("is_warmup_suitable", False)),
            "is_stretch_suitable": bool(exercise.get("is_stretch_suitable", False)),
            "is_cooldown_suitable": bool(exercise.get("is_cooldown_suitable", False)),
        }

    async def index_custom_exercise(self, exercise: Dict[str, Any]) -> bool:
        """
        Index a single custom exercise into the `custom_exercise_library` collection.

        Returns True on success, False (non-fatal) on failure — callers should log
        a ⚠️ but NOT fail the parent request on indexing errors.
        """
        exercise_id = exercise.get("id")
        if not exercise_id:
            logger.warning("⚠️ [ExerciseRAG] index_custom_exercise: missing id — skipping")
            return False

        try:
            doc_id = f"custom_{exercise_id}"
            document = self._build_custom_exercise_text(exercise)
            metadata = self._build_custom_metadata(exercise)

            embedding = await self.gemini_service.get_embedding_async(document)
            if not embedding:
                logger.warning(f"⚠️ [ExerciseRAG] embedding returned empty for custom exercise {exercise_id}")
                return False

            # Upsert: try delete-then-add to keep semantics consistent with library ingest.
            try:
                self.custom_collection.delete(ids=[doc_id])
            except Exception as e:
                logger.debug(f"[ExerciseRAG] delete-before-add noop for {doc_id}: {e}")

            self.custom_collection.add(
                ids=[doc_id],
                embeddings=[embedding],
                documents=[document],
                metadatas=[metadata],
            )
            logger.info(
                f"✅ [ExerciseRAG] Indexed custom exercise '{exercise.get('name')}' (id={exercise_id}) "
                f"into custom_exercise_library"
            )
            return True
        except Exception as e:
            logger.error(
                f"❌ [ExerciseRAG] Failed to index custom exercise {exercise_id}: {e}",
                exc_info=True,
            )
            return False

    async def update_custom_exercise_index(self, exercise: Dict[str, Any]) -> bool:
        """Re-index a custom exercise after update. Upsert semantics."""
        return await self.index_custom_exercise(exercise)

    async def delete_custom_exercise_index(self, exercise_id: str) -> bool:
        """Remove a custom exercise from the ChromaDB custom collection."""
        if not exercise_id:
            return False
        try:
            doc_id = f"custom_{exercise_id}"
            self.custom_collection.delete(ids=[doc_id])
            logger.info(f"✅ [ExerciseRAG] Deleted custom exercise {exercise_id} from index")
            return True
        except Exception as e:
            logger.error(
                f"❌ [ExerciseRAG] Failed to delete custom exercise {exercise_id} from index: {e}",
                exc_info=True,
            )
            return False

    def query_custom_collection(
        self,
        query_embedding: List[float],
        user_id: Optional[str],
        n_results: int = 20,
    ) -> Dict[str, Any]:
        """
        Query the custom exercise collection filtered to exercises the user can see:
          - their own (user_id match) OR
          - public (is_public=true)

        Returns the raw ChromaDB query result dict.
        """
        if not user_id:
            where = {"is_public": True}
        else:
            where = {"$or": [{"user_id": user_id}, {"is_public": True}]}

        try:
            return self.custom_collection.query(
                query_embeddings=[query_embedding],
                n_results=n_results,
                where=where,
                include=["documents", "metadatas", "distances"],
            )
        except Exception as e:
            logger.warning(
                f"⚠️ [ExerciseRAG] custom collection query failed: {e}",
                exc_info=True,
            )
            return {"ids": [[]], "metadatas": [[]], "distances": [[]], "documents": [[]]}

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
        very_recently_used_exercises: Optional[List[str]] = None,
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
        # Home/outdoor environments need a larger pool since most exercises require gym equipment
        is_constrained_env = workout_environment and workout_environment.lower() in ("home", "outdoor", "park")
        # Increase pool when user has dumbbells but no bench — many dumbbell exercises get filtered
        eq_lower = [eq.lower() for eq in equipment]
        has_dumbbells_no_bench = (
            any("dumbbell" in eq for eq in eq_lower) and
            not any("bench" in eq or "home_gym" in eq or "full_gym" in eq for eq in eq_lower)
        )
        # Multipliers tuned so the post-filter pipeline (media, difficulty,
        # workout_type, injury, avoided_muscles, consistency_mode, hard-remove
        # of 7d-recent) leaves enough survivors to fill the requested count
        # without triggering "Only got N/M unique exercises" backfill warnings.
        # Previously 6x gave 30 candidates — for users with 20+ recent
        # exercises + narrow focus areas, survivors fell to 4.
        if is_constrained_env:
            candidate_count = min(count * 15, 100)
        elif has_dumbbells_no_bench:
            candidate_count = min(count * 12, 80)
        else:
            candidate_count = min(count * 10, 60)

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

            # Pre-compute bench/rack availability (constant across all exercises)
            user_equipment_lower = [eq.lower() for eq in equipment]
            user_has_bench = (
                any("bench" in eq for eq in user_equipment_lower) or
                any("home_gym" in eq or "full_gym" in eq for eq in user_equipment_lower)
            )
            user_has_rack = (
                any("squat_rack" in eq or "power_rack" in eq or "rack" in eq
                    for eq in user_equipment_lower) or
                any("full_gym" in eq for eq in user_equipment_lower)
            )
            user_has_barbell = any("barbell" in eq for eq in user_equipment_lower)

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

                # Secondary equipment safety filters (bench + rack)
                ex_name_lower = meta.get("name", "").lower()
                bench_required_field = str(meta.get("bench_required", "")).lower()

                if not user_has_bench:
                    if bench_required_field == "true" or _needs_bench(meta.get("name", "")):
                        logger.debug(f"Bench-filter: '{meta.get('name')}' removed - requires bench")
                        continue

                if not user_has_rack and user_has_barbell:
                    if any(pat in ex_name_lower for pat in _SQUAT_RACK_REQUIRED_PATTERNS):
                        logger.debug(f"Rack-filter: '{meta.get('name')}' removed - requires squat rack")
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

                # Filter out stretches for strength/cardio workouts
                if workout_type_preference not in ("mobility", "recovery", "flexibility"):
                    if is_stretch_exercise(
                        meta.get("name", ""),
                        meta.get("body_part", ""),
                        meta.get("category", ""),
                    ):
                        logger.debug(f"Filtered out '{meta.get('name')}' - stretch exercise in {workout_type_preference} workout")
                        continue

                # Filter out warmup/filler exercises from strength workouts
                if workout_type_preference in ("strength", "hypertrophy"):
                    if is_warmup_filler_exercise(meta.get("name", "")):
                        logger.debug(f"Filtered out '{meta.get('name')}' - warmup filler in {workout_type_preference} workout")
                        continue

                # Clean name for display (also strip "(N)" import-duplicate suffix
                # so base names match each other in the similarity check).
                raw_name = meta.get("name", "Unknown")
                from .utils import strip_dedup_suffix
                exercise_name = strip_dedup_suffix(clean_exercise_name_for_display(raw_name))

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

        # Apply post-filtering pipeline using extracted functions
        apply_difficulty_scoring(candidates, validated_fitness_level, difficulty_adjustment)
        boost_equipment_matches(candidates, equipment)
        candidates = cap_bodyweight_exercises(candidates, equipment)
        candidates = apply_injury_filter(candidates, injuries if injuries else [])
        candidates = apply_avoided_muscles_filter(candidates, avoided_muscles)
        apply_workout_type_filter(candidates, workout_type_preference)
        apply_favorites_boost(candidates, favorite_exercises)
        apply_consistency_mode(candidates, recently_used_exercises, consistency_mode, variation_percentage)

        # Save a snapshot before hard-removal so backfill (line 776) and
        # post-selection swap (line 829) can fall back to the full pool
        candidates_before_removal = list(candidates)

        # Hard-remove very recently used exercises from candidate pool
        # This ensures they cannot be selected by AI, backfill, or any other path
        if very_recently_used_exercises and consistency_mode != "consistent":
            very_recent_lower = {e.lower() for e in very_recently_used_exercises}
            staple_lower = {s.lower() for s in staple_names}
            min_pool = count * 2

            # Count how many would survive hard-removal
            surviving = [
                c for c in candidates
                if c["name"].lower() not in very_recent_lower
                or c["name"].lower() in staple_lower
            ]

            if len(surviving) >= min_pool:
                # Pool is large enough — hard-remove safely
                removed = len(candidates) - len(surviving)
                candidates = surviving
                if removed > 0:
                    logger.info(
                        f"🔄 [Variety] Hard-removed {removed} recently used exercises from pool "
                        f"(variation={variation_percentage}%, pool: {len(candidates) + removed} -> {len(candidates)})"
                    )
            else:
                # Pool too small for hard-removal — apply 0.05x penalty instead
                penalized = 0
                for c in candidates:
                    if c["name"].lower() in very_recent_lower and c["name"].lower() not in staple_lower:
                        c["similarity"] = c["similarity"] * 0.05
                        penalized += 1
                candidates.sort(key=lambda x: x.get("similarity", 0), reverse=True)
                if penalized > 0:
                    logger.info(
                        f"🔄 [Variety] Pool too small for hard-removal ({len(candidates)} < {min_pool}), "
                        f"applied 0.05x penalty to {penalized} recently used exercises instead"
                    )

        # Process STAPLE exercises
        staple_included, staple_names_used, candidates = extract_staple_exercises(
            candidates, staple_names, staple_exercises
        )

        # Process queued exercises
        queued_included, queued_names_used, candidates, queued_exclusion_reasons = extract_queued_exercises(
            candidates, queued_exercises, focus_area
        )

        # Calculate how many more exercises we need from AI selection
        remaining_count = count - len(staple_included) - len(queued_included)

        # Adjust workout params based on readiness and mood
        adjusted_workout_params = adjust_workout_params_for_readiness(
            workout_params, readiness_score, user_mood
        )

        if remaining_count > 0:
            # Apply batch offset to ensure variety across parallel workout generations
            # Each workout in a batch gets a different offset (0, 1, 2, ...) to select
            # different exercises from the candidate pool.
            # Window size must be ≥ 4x remaining_count so the AI has real choice
            # after its own dedup/variety rules. With a 4-exercise window for a
            # 5-exercise request, duplicates or rejected picks leave no room to
            # backfill unique alternatives.
            window = max(30, remaining_count * 6)
            offset_start = batch_offset * count
            offset_end = offset_start + window

            # Ensure we have enough candidates by using modulo wrap-around
            if len(candidates) > 0:
                if offset_start >= len(candidates):
                    # Wrap around if offset is beyond candidate list
                    offset_start = offset_start % len(candidates)
                    offset_end = offset_start + window

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
                offset_candidates = candidates[:window]

            # Use AI to select remaining exercises
            selected = await self._ai_select_exercises(
                candidates=offset_candidates[:window],
                focus_area=focus_area,
                fitness_level=fitness_level,
                goals=goals,
                count=remaining_count,
                injuries=injuries,
                workout_params=adjusted_workout_params,
                strength_history=strength_history,
                progression_pace=progression_pace,
                equipment=equipment,
                avoid_exercises=avoid_exercises if avoid_exercises else None,
                user_id=user_id,
                recently_used_exercises=recently_used_exercises,
            )

            # Backfill from full candidate pool if AI returned too few
            # Two-pass: first avoid recently used, then allow as last resort
            if len(selected) < remaining_count:
                all_used = {e['name'].lower().strip() for e in selected}
                all_used |= {s['name'].lower().strip() for s in staple_included}
                all_used |= {q['name'].lower().strip() for q in queued_included}
                very_recent_lower = {e.lower() for e in (very_recently_used_exercises or [])}

                # Pass 1: backfill only from non-recently-used candidates
                for candidate in candidates:
                    if len(selected) >= remaining_count:
                        break
                    name_lower = candidate['name'].lower().strip()
                    if name_lower not in all_used and name_lower not in very_recent_lower:
                        all_used.add(name_lower)
                        selected.append(self._format_exercise_for_workout(
                            candidate, fitness_level, adjusted_workout_params,
                            strength_history, progression_pace
                        ))

                # Pass 2: if still short, allow recently used as last resort
                if len(selected) < remaining_count:
                    for candidate in candidates_before_removal:
                        if len(selected) >= remaining_count:
                            break
                        name_lower = candidate['name'].lower().strip()
                        if name_lower not in all_used:
                            all_used.add(name_lower)
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

        # Post-selection overlap check: swap exercises that overlap with recent workouts
        if very_recently_used_exercises and consistency_mode != "consistent" and final_selection:
            protected_names = {s.lower() for s in staple_names_used + queued_names_used}

            overlapping_indices = []
            for i, ex in enumerate(final_selection):
                name_lower = ex["name"].lower()
                if name_lower in protected_names:
                    continue
                for recent in very_recently_used_exercises:
                    if is_similar_exercise(ex["name"], recent):
                        overlapping_indices.append(i)
                        break

            non_protected_count = max(len(final_selection) - len(protected_names), 1)
            overlap_ratio = len(overlapping_indices) / non_protected_count

            if overlap_ratio > 0.5:
                # Build swap pool from unused, non-recent candidates
                selected_names = {ex["name"].lower() for ex in final_selection}
                swap_pool = [
                    c for c in candidates_before_removal
                    if c["name"].lower() not in selected_names
                    and not any(is_similar_exercise(c["name"], r) for r in very_recently_used_exercises)
                    and c.get("similarity", 0) > 0.05
                ]
                swap_pool.sort(key=lambda x: x.get("similarity", 0), reverse=True)

                swap_idx = 0
                for i in overlapping_indices:
                    if swap_idx < len(swap_pool):
                        replacement = self._format_exercise_for_workout(
                            swap_pool[swap_idx], fitness_level, adjusted_workout_params,
                            strength_history, progression_pace
                        )
                        logger.info(
                            f"🔄 [Variety] Post-swap: '{final_selection[i]['name']}' -> '{replacement['name']}'"
                        )
                        final_selection[i] = replacement
                        swap_idx += 1

                if swap_idx > 0:
                    logger.info(f"🔄 [Variety] Post-selection: swapped {swap_idx}/{len(overlapping_indices)} overlapping exercises")

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
        equipment: Optional[List[str]] = None,
        avoid_exercises: Optional[List[str]] = None,
        user_id: Optional[str] = None,
        recently_used_exercises: Optional[List[str]] = None,
    ) -> List[Dict[str, Any]]:
        """Use AI to select the best exercises from candidates."""

        # Deduplicate candidates by name (keep first occurrence = highest similarity).
        # dedup_key also strips "(N)" suffixes so Burpee / Burpee(1) collapse.
        from .utils import dedup_key
        seen_cand_names = set()
        deduped = []
        for c in candidates:
            key = dedup_key(c['name'])
            if key and key not in seen_cand_names:
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

        # Detect if user has any non-bodyweight equipment for equipment priority rule
        _BW_ONLY_EQUIPMENT_AI = {"bodyweight", "bodyweight_only", "bodyweight only", "body weight", "none", ""}
        user_real_equipment = [eq for eq in (equipment or []) if eq.lower() not in _BW_ONLY_EQUIPMENT_AI]

        equipment_priority_section = ""
        if user_real_equipment:
            equipment_priority_section = f"""
EQUIPMENT PRIORITY RULE (user has: {', '.join(user_real_equipment)}):
- Select AT MOST 1 bodyweight exercise out of {count}
- STRONGLY prefer exercises using: {', '.join(user_real_equipment)}
- Bodyweight exercises are acceptable ONLY as a warm-up or finisher, not as primary movements
- Do NOT select easy cardio-style bodyweight moves (punches, jumping jacks, etc.)
"""

        adjacent_day_section = ""
        if avoid_exercises:
            adjacent_day_section = f"""
ADJACENT-DAY VARIETY RULE:
AVOID these exercises already used in adjacent workouts: {', '.join(avoid_exercises)}
Do NOT select any exercise from the above list. Pick different exercises for variety.
"""

        recently_used_section = ""
        if recently_used_exercises:
            recent_names = recently_used_exercises[:15]
            recently_used_section = f"""
VARIETY RULE - RECENTLY USED EXERCISES:
These exercises were used in the user's recent workouts: {', '.join(recent_names)}
STRONGLY prefer different exercises for variety. Only pick a recently used exercise
if there is absolutely no suitable alternative in the candidate list.
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
{equipment_priority_section}
{adjacent_day_section}
{recently_used_section}
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

            response = await gemini_generate_with_retry(
                model=gemini_settings.gemini_model,
                contents=f"{system_content}\n\n{prompt}",
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=ExerciseIndicesResponse,
                    temperature=0.7,
                    max_output_tokens=2000,
                ),
                user_id=user_id,
                method_name="ai_select_exercises",
            )

            content = response.text.strip()
            data = json.loads(content)
            selected_indices = data.get("selected_indices", [])

            # Get selected exercises - ensure no duplicates. dedup_key strips
            # "(N)" suffixes so Burpee / Burpee(1) collapse to one slot.
            from .utils import dedup_key
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
                    exercise_name = dedup_key(ex.get('name', ''))

                    # Skip if we've already selected an exercise with the same name
                    if not exercise_name or exercise_name in seen_names:
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
                        exercise_name = dedup_key(candidate.get('name', ''))
                        if exercise_name and exercise_name not in seen_names:
                            seen_indices.add(i + 1)
                            seen_names.add(exercise_name)
                            selected.append(self._format_exercise_for_workout(
                                candidate, fitness_level, workout_params, strength_history, progression_pace
                            ))

            logger.info(f"AI selected {len(selected)} unique exercises: {[e['name'] for e in selected]}")
            return selected

        except Exception as e:
            logger.error(f"AI selection failed: {e}", exc_info=True)
            raise

    def _detect_unilateral(self, exercise_name: str, metadata: dict = None) -> bool:
        """Detect if exercise is unilateral (single-arm/leg). Delegates to formatting module."""
        return detect_unilateral(exercise_name, metadata)

    def _format_exercise_for_workout(
        self,
        exercise: Dict,
        fitness_level: str,
        workout_params: Optional[Dict] = None,
        strength_history: Optional[Dict[str, Dict]] = None,
        progression_pace: str = "medium",
    ) -> Dict:
        """Format an exercise for inclusion in a workout. Delegates to formatting module."""
        return format_exercise_for_workout(
            exercise, fitness_level, workout_params, strength_history, progression_pace
        )

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
        """Select exactly 1 challenge exercise for beginners and intermediate users."""
        if fitness_level not in ("beginner", "intermediate"):
            return None

        main_exercise_names = {ex.get("name", "").lower() for ex in main_exercises}
        logger.info(f"Selecting challenge exercise for {fitness_level}, excluding: {main_exercise_names}")

        try:
            search_query = f"advanced {focus_area} exercise progression challenge"
            results = self.collection.query(
                query_texts=[search_query], n_results=50,
                include=["metadatas", "distances"],
            )

            if not results or not results["metadatas"] or not results["metadatas"][0]:
                return None

            metadatas = results["metadatas"][0]
            distances = results["distances"][0] if results["distances"] else []

            challenge_candidates = []
            filter_stats = {"duplicate": 0, "difficulty": 0, "equipment": 0, "injury": 0, "avoided": 0, "no_media": 0}

            for i, meta in enumerate(metadatas):
                exercise_name = meta.get("name", "Unknown")
                exercise_name_lower = exercise_name.lower()

                if exercise_name_lower in main_exercise_names:
                    filter_stats["duplicate"] += 1
                    continue

                exercise_difficulty = meta.get("difficulty", "beginner")
                difficulty_num = get_difficulty_numeric(exercise_difficulty)
                if difficulty_num < CHALLENGE_DIFFICULTY_RANGE["min"] or difficulty_num > CHALLENGE_DIFFICULTY_RANGE["max"]:
                    filter_stats["difficulty"] += 1
                    continue

                ex_equipment = (meta.get("equipment", "") or "").lower()
                equipment_lower = [e.lower() for e in equipment] if equipment else []
                if ex_equipment and ex_equipment not in ["bodyweight", "body weight", "none", ""]:
                    if not any(eq in ex_equipment for eq in equipment_lower):
                        filter_stats["equipment"] += 1
                        continue

                if injuries:
                    primary_muscle = (meta.get("target_muscle", "") or "").lower()
                    secondary_muscles = parse_secondary_muscles(meta.get("secondary_muscles", []))
                    is_safe = pre_filter_by_injuries(
                        exercise_name=exercise_name, primary_muscle=primary_muscle,
                        secondary_muscles=secondary_muscles, injuries=injuries
                    )
                    if not is_safe:
                        filter_stats["injury"] += 1
                        continue

                if avoided_muscles:
                    primary_muscle = (meta.get("target_muscle", "") or "").lower()
                    avoid_list = avoided_muscles.get("avoid", [])
                    if any(am.lower() in primary_muscle for am in avoid_list):
                        filter_stats["avoided"] += 1
                        continue

                has_media = bool(meta.get("gif_url") or meta.get("video_url") or meta.get("image_url"))
                if not has_media:
                    filter_stats["no_media"] += 1
                    continue

                similarity = 1 - distances[i] if i < len(distances) else 0.5
                progression_from = None
                for main_ex in main_exercises:
                    main_name = main_ex.get("name", "").lower()
                    if self._is_progression_of(exercise_name_lower, main_name):
                        progression_from = main_ex.get("name")
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
                logger.warning(f"[Challenge] No valid candidates after filtering. Stats: {filter_stats}")
                return None

            challenge_candidates.sort(key=lambda x: x["similarity"], reverse=True)
            best_challenge = challenge_candidates[0]

            formatted = self._format_exercise_for_workout(
                best_challenge, fitness_level, workout_params, strength_history,
                progression_pace="slow",
            )
            formatted["is_challenge"] = True
            formatted["progression_from"] = best_challenge.get("progression_from")
            formatted["difficulty"] = best_challenge.get("difficulty")
            formatted["difficulty_num"] = best_challenge.get("difficulty_num")

            logger.info(f"Selected challenge exercise: {formatted['name']} (difficulty: {best_challenge['difficulty_num']})")
            return formatted

        except Exception as e:
            logger.error(f"Error selecting challenge exercise: {e}", exc_info=True)
            return None

    def _is_progression_of(self, challenge_name: str, main_name: str) -> bool:
        """Check if the challenge exercise is a progression of a main exercise."""
        return is_progression_of(challenge_name, main_name)

    def get_stats(self) -> Dict[str, Any]:
        """Get exercise RAG statistics."""
        try:
            c = self.collection.count()
            total = c if c >= 0 else -1
        except Exception as e:
            logger.warning(f"Failed to get exercise count: {e}", exc_info=True)
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
