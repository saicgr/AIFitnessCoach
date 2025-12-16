"""
Exercise RAG Service - Intelligent exercise selection using embeddings.

This service:
1. Indexes all exercises from exercise_library with embeddings
2. Uses AI to select the best exercises based on user profile, goals, equipment
3. Considers exercise variety, muscle balance, and progression
"""
from typing import List, Dict, Any, Optional
import json
import re

from core.config import get_settings
from core.chroma_cloud import get_chroma_cloud_client
from core.supabase_client import get_supabase
from core.logger import get_logger
from services.openai_service import OpenAIService
from services.training_program_service import get_training_program_keywords_sync

settings = get_settings()
logger = get_logger(__name__)


def _infer_equipment_from_name(exercise_name: str) -> str:
    """
    Infer equipment type from exercise name when equipment data is missing.

    Examples:
    - "cable machine low to high" -> "Cable Machine"
    - "barbell bench press" -> "Barbell"
    - "dumbbell curl" -> "Dumbbells"
    """
    if not exercise_name:
        return "Bodyweight"

    name_lower = exercise_name.lower()

    # Equipment inference rules (order matters - more specific first)
    equipment_patterns = [
        (["cable machine", "cable"], "Cable Machine"),
        (["barbell", "bar bell"], "Barbell"),
        (["dumbbell", "dumb bell", "db "], "Dumbbells"),
        (["kettlebell", "kettle bell", "kb "], "Kettlebell"),
        (["ez bar", "ez-bar"], "EZ Bar"),
        (["smith machine", "smith"], "Smith Machine"),
        (["resistance band", "band "], "Resistance Bands"),
        (["pull-up bar", "pullup bar", "chin-up bar", "chinup bar"], "Pull-up Bar"),
        (["machine", "lat pulldown", "leg press", "leg curl", "leg extension", "chest press machine", "shoulder press machine"], "Machine"),
        (["trx", "suspension"], "TRX"),
        (["medicine ball", "med ball"], "Medicine Ball"),
        (["stability ball", "swiss ball", "exercise ball"], "Stability Ball"),
        (["rope ", " rope", "battle rope"], "Rope"),
        (["bench ", " bench"], "Bench"),
    ]

    for patterns, equipment in equipment_patterns:
        for pattern in patterns:
            if pattern in name_lower:
                return equipment

    # If no equipment matched, default to Bodyweight
    return "Bodyweight"


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

    def __init__(self, openai_service: OpenAIService):
        self.openai_service = openai_service
        self.supabase = get_supabase()
        self.client = self.supabase.client

        # Get Chroma Cloud client
        self.chroma_client = get_chroma_cloud_client()
        self.collection = self.chroma_client.get_or_create_collection("exercise_library")

        logger.info(f"✅ Exercise RAG initialized with {self.collection.count()} exercises")

    async def index_all_exercises(self, batch_size: int = 100) -> int:
        """
        Index all exercises from the exercise_library_cleaned view.

        Uses the cleaned/deduplicated view and only indexes exercises with videos.
        Call this once to populate the vector store, or periodically to update.
        Uses batch embedding API to minimize API calls.

        Returns:
            Number of exercises indexed
        """
        logger.info("🔄 Starting exercise library indexing (using cleaned view)...")

        # Fetch all exercises from cleaned view using pagination (Supabase 1000 row limit)
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

        # Filter: only exercises with videos, and deduplicate by lowercase name
        # Note: The cleaned view uses 'video_url' (not 'video_s3_path') and 'name' (not 'exercise_name_cleaned')
        seen_names: set = set()
        exercises = []
        for ex in all_exercises:
            # Skip exercises without videos
            # View column is 'video_url', fallback to 'video_s3_path' for compatibility
            if not ex.get("video_url") and not ex.get("video_s3_path"):
                continue

            # Get cleaned name - view uses 'name' column
            exercise_name = ex.get("name", ex.get("exercise_name_cleaned", ex.get("exercise_name", "")))

            # Case-insensitive deduplication (prefer Title Case)
            lower_name = exercise_name.lower()
            if lower_name in seen_names:
                continue
            seen_names.add(lower_name)

            exercises.append(ex)

        logger.info(f"📊 Found {len(exercises)} exercises to index (filtered from {len(all_exercises)}, only with videos, deduplicated)")
        indexed_count = 0

        # Process in batches (OpenAI supports up to 2048 texts per call)
        for i in range(0, len(exercises), batch_size):
            batch = exercises[i:i + batch_size]
            batch_num = i // batch_size + 1
            total_batches = (len(exercises) + batch_size - 1) // batch_size

            logger.info(f"📚 Processing batch {batch_num}/{total_batches} ({len(batch)} exercises)...")

            # Prepare all texts for batch embedding
            ids = []
            documents = []
            metadatas = []

            for ex in batch:
                doc_id = f"ex_{ex.get('id', '')}"
                exercise_text = self._build_exercise_text(ex)

                # Get cleaned name - view uses 'name' column (fallback for compatibility)
                exercise_name = ex.get("name", ex.get("exercise_name_cleaned", ex.get("exercise_name", "Unknown")))

                ids.append(doc_id)
                documents.append(exercise_text)
                # ChromaDB only accepts str, int, float, bool - convert None to empty string
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
                    "video_url": str(ex.get("video_url") or ""),  # Include video URL
                    "image_url": str(ex.get("image_url") or ""),  # Include image URL
                    "instructions": str(ex.get("instructions") or "")[:500],
                    "has_video": "true",  # All indexed exercises have videos
                    "single_dumbbell_friendly": "true" if ex.get("single_dumbbell_friendly") else "false",
                    "single_kettlebell_friendly": "true" if ex.get("single_kettlebell_friendly") else "false",
                })

            # Get ALL embeddings in ONE API call
            try:
                embeddings = await self.openai_service.get_embeddings_batch(documents)
                logger.info(f"   ✅ Got {len(embeddings)} embeddings in 1 API call")
            except Exception as e:
                logger.error(f"❌ Failed to get batch embeddings: {e}")
                continue

            # Upsert batch to collection
            if ids and embeddings:
                try:
                    # Delete existing to avoid duplicates
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
                    logger.info(f"   ✅ Indexed {len(ids)} exercises to Chroma Cloud")
                except Exception as e:
                    logger.error(f"❌ Failed to index batch to Chroma: {e}")

        logger.info(f"✅ Finished indexing {indexed_count} exercises (used ~{(len(exercises) + batch_size - 1) // batch_size} API calls)")
        return indexed_count

    def _build_exercise_text(self, exercise: Dict) -> str:
        """Build rich text representation of an exercise for embedding."""
        # Use cleaned name - view uses 'name' column (fallback for compatibility)
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

        # Add single equipment compatibility info
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

        Returns:
            List of selected exercises with full details
        """
        logger.info(f"🎯 Selecting {count} exercises for {focus_area} workout")
        logger.info(f"🏋️ Equipment: {equipment}, Dumbbells: {dumbbell_count}, Kettlebells: {kettlebell_count}")
        if injuries:
            logger.info(f"⚠️ User has injuries/conditions: {injuries} - AI will filter unsafe exercises")

        # Build search query based on user profile
        search_query = self._build_search_query(focus_area, equipment, fitness_level, goals)

        # Get embedding for the search query
        query_embedding = await self.openai_service.get_embedding(search_query)

        # Search for candidate exercises (get more than needed for AI to choose from)
        candidate_count = min(count * 4, 30)

        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=candidate_count,
            include=["documents", "metadatas", "distances"],
        )

        if not results["ids"][0]:
            logger.warning("No exercises found in RAG, falling back to random selection")
            return await self._fallback_selection(focus_area, equipment, count)

        # Format candidates for AI selection
        candidates = []
        seen_exercises = []  # Track exercise names to avoid similar duplicates

        for i, doc_id in enumerate(results["ids"][0]):
            meta = results["metadatas"][0][i]
            distance = results["distances"][0][i]
            # Cosine distance: 0-2 range, convert to similarity 0-1
            similarity = 1 - (distance / 2)

            # Skip exercises to avoid
            if avoid_exercises and meta.get("name", "").lower() in [e.lower() for e in avoid_exercises]:
                continue

            # Filter by equipment compatibility
            # First, get the raw equipment from metadata
            raw_ex_equipment = (meta.get("equipment", "") or "").lower().strip()

            # If equipment is empty/null, infer from exercise name
            exercise_name_for_inference = meta.get("name", "")
            if not raw_ex_equipment or raw_ex_equipment in ["bodyweight", "body weight", "none"]:
                inferred_equipment = _infer_equipment_from_name(exercise_name_for_inference)
                ex_equipment = inferred_equipment.lower()
            else:
                ex_equipment = raw_ex_equipment

            # Expand "Full Gym" and similar general options to include all gym equipment
            FULL_GYM_EQUIPMENT = [
                "barbell", "dumbbell", "dumbbells", "cable", "cable machine",
                "machine", "kettlebell", "bench", "ez bar", "smith machine",
                "lat pulldown", "leg press", "pull-up bar", "pullup bar",
                "resistance band", "medicine ball", "stability ball", "trx",
                "body weight", "bodyweight", "none"
            ]

            HOME_GYM_EQUIPMENT = [
                "dumbbell", "dumbbells", "kettlebell", "resistance band",
                "pull-up bar", "pullup bar", "bench", "stability ball",
                "body weight", "bodyweight", "none"
            ]

            # Build equipment list based on user selection
            equipment_lower = [eq.lower() for eq in equipment]

            # Expand general equipment options
            if "full gym" in equipment_lower:
                equipment_lower = FULL_GYM_EQUIPMENT
            elif "home gym" in equipment_lower:
                equipment_lower = HOME_GYM_EQUIPMENT
            elif "bodyweight only" in equipment_lower:
                # User wants ONLY bodyweight exercises
                equipment_lower = ["body weight", "bodyweight", "none"]
            else:
                # Always include bodyweight as an option in addition to selected equipment
                equipment_lower = equipment_lower + ["body weight", "bodyweight", "none"]

            # Check if exercise equipment matches user's equipment
            # Use partial matching for flexibility (e.g., "Dumbbells" matches "dumbbell")
            equipment_match = False
            for eq in equipment_lower:
                # Both strings must be non-empty for a valid match
                if eq and ex_equipment and (eq in ex_equipment or ex_equipment in eq):
                    equipment_match = True
                    break

            if not equipment_match:
                # Also check exercise name for equipment clues (e.g., "Kettlebell Swing")
                exercise_name_lower = meta.get("name", "").lower()
                for eq in equipment_lower:
                    if eq and eq in exercise_name_lower:
                        equipment_match = True
                        break

            if not equipment_match:
                logger.debug(f"Filtered out '{meta.get('name')}' - equipment '{ex_equipment}' not in {equipment_lower}")
                continue

            # Filter by single equipment compatibility if user has only 1 dumbbell or kettlebell
            if dumbbell_count == 1 and "dumbbell" in ex_equipment:
                # User has only 1 dumbbell - check if exercise is single-dumbbell friendly
                single_db_friendly = meta.get("single_dumbbell_friendly", "false") == "true"
                if not single_db_friendly:
                    logger.debug(f"Filtered out '{meta.get('name')}' - requires 2 dumbbells but user has 1")
                    continue

            if kettlebell_count == 1 and "kettlebell" in ex_equipment:
                # User has only 1 kettlebell - check if exercise is single-kettlebell friendly
                single_kb_friendly = meta.get("single_kettlebell_friendly", "false") == "true"
                if not single_kb_friendly:
                    logger.debug(f"Filtered out '{meta.get('name')}' - requires 2 kettlebells but user has 1")
                    continue

            # Get exercise name
            exercise_name = meta.get("name", "Unknown")

            # Skip if we already have a similar exercise (avoid duplicates and variations)
            is_duplicate = False
            for seen_name in seen_exercises:
                if self._is_similar_exercise(exercise_name, seen_name):
                    logger.debug(f"Skipping similar exercise: '{exercise_name}' (similar to '{seen_name}')")
                    is_duplicate = True
                    break

            if is_duplicate:
                continue

            seen_exercises.append(exercise_name)

            # Get equipment - use inference if missing
            raw_eq = meta.get("equipment", "")
            if not raw_eq or raw_eq.lower() in ["bodyweight", "body weight", "none", ""]:
                eq = _infer_equipment_from_name(exercise_name)
            else:
                eq = raw_eq

            candidates.append({
                "id": meta.get("exercise_id", ""),
                "name": exercise_name,
                "body_part": meta.get("body_part", ""),
                "equipment": eq,
                "target_muscle": meta.get("target_muscle", ""),
                "difficulty": meta.get("difficulty", "intermediate"),
                "gif_url": meta.get("gif_url", ""),
                "video_url": meta.get("video_url", ""),  # Include video URL
                "image_url": meta.get("image_url", ""),  # Include image URL
                "instructions": meta.get("instructions", ""),
                "similarity": similarity,
                "single_dumbbell_friendly": meta.get("single_dumbbell_friendly", "false") == "true",
                "single_kettlebell_friendly": meta.get("single_kettlebell_friendly", "false") == "true",
            })

        if not candidates:
            logger.warning("No compatible exercises found after filtering")
            return await self._fallback_selection(focus_area, equipment, count)

        # Pre-filter candidates based on injuries (safety net before AI)
        if injuries and len(injuries) > 0:
            safe_candidates = self._pre_filter_by_injuries(candidates, injuries)
            if safe_candidates:
                logger.info(f"🛡️ Pre-filtered {len(candidates)} candidates to {len(safe_candidates)} safe exercises")
                candidates = safe_candidates
            else:
                logger.warning("Pre-filter removed all candidates, keeping original list for AI to filter")

        # Use AI to make final selection
        selected = await self._ai_select_exercises(
            candidates=candidates[:20],  # Limit candidates for AI
            focus_area=focus_area,
            fitness_level=fitness_level,
            goals=goals,
            count=count,
            injuries=injuries,
        )

        return selected

    def _get_base_exercise_name(self, name: str) -> str:
        """
        Extract the normalized base exercise name for deduplication.

        Removes version suffixes, gender variants, and normalizes the name.

        Examples:
            "Push-up (version 2)" -> "push up"
            "Squat variation 3" -> "squat"
            "Bodyweight full squat with overhead press (version 2)" -> "bodyweight full squat overhead press"
            "Dumbbell Bicep Curl" -> "dumbbell bicep curl"
            "Air Bike_female" -> "air bike"
        """
        # Lowercase for comparison
        name = name.lower()

        # Remove "_female" or "_Female" suffix (gender variants)
        name = re.sub(r'[_\s]female$', '', name, flags=re.IGNORECASE)

        # Remove "(version X)" or "(Version X)" suffix
        name = re.sub(r'\s*\(version\s*\d+\)\s*', '', name, flags=re.IGNORECASE)

        # Remove "version X" suffix without parentheses
        name = re.sub(r'\s+version\s*\d+\s*', '', name, flags=re.IGNORECASE)

        # Remove "variation X" suffix
        name = re.sub(r'\s*\(variation\s*\d+\)\s*', '', name, flags=re.IGNORECASE)
        name = re.sub(r'\s+variation\s*\d+\s*', '', name, flags=re.IGNORECASE)

        # Remove "v2", "v3" etc suffix
        name = re.sub(r'\s+v\d+\s*', '', name, flags=re.IGNORECASE)

        # Remove common filler words that don't change the exercise
        filler_words = ['with', 'and', 'the', 'a', 'an', 'on', 'in', 'to', 'for']
        words = name.split()
        words = [w for w in words if w not in filler_words]
        name = ' '.join(words)

        # Normalize hyphens, underscores and multiple spaces
        name = name.replace('-', ' ')
        name = name.replace('_', ' ')
        name = re.sub(r'\s+', ' ', name)

        return name.strip()

    def _is_similar_exercise(self, name1: str, name2: str) -> bool:
        """
        Check if two exercise names are similar enough to be considered duplicates.

        Uses word overlap to detect similar exercises like:
        - "Squat" and "Bodyweight Squat"
        - "Bicep Curl" and "Dumbbell Bicep Curl"
        """
        base1 = self._get_base_exercise_name(name1)
        base2 = self._get_base_exercise_name(name2)

        # Exact match after normalization
        if base1 == base2:
            return True

        # Check word overlap - if one is subset of the other
        words1 = set(base1.split())
        words2 = set(base2.split())

        # If smaller set is fully contained in larger set, they're similar
        if words1.issubset(words2) or words2.issubset(words1):
            return True

        # High overlap (80%+ of smaller set matches)
        smaller = words1 if len(words1) < len(words2) else words2
        larger = words2 if len(words1) < len(words2) else words1
        overlap = len(smaller & larger)
        if len(smaller) > 0 and overlap / len(smaller) >= 0.8:
            return True

        return False

    def _pre_filter_by_injuries(
        self,
        candidates: List[Dict],
        injuries: List[str],
    ) -> List[Dict]:
        """
        Pre-filter exercises that are contraindicated for user's injuries.
        This is a safety net to catch dangerous exercises before AI selection.
        """
        # Define exercise patterns to avoid for each injury type
        injury_contraindications = {
            # Leg/Knee injuries
            "leg": ["squat", "lunge", "leg press", "leg extension", "leg curl", "step-up",
                    "box jump", "jump squat", "burpee", "mountain climber", "deadlift",
                    "romanian deadlift", "calf raise", "hack squat", "pistol squat",
                    "leg drive", "split squat", "jump", "hop", "sprint"],
            "knee": ["squat", "lunge", "leg press", "leg extension", "leg curl", "step-up",
                     "box jump", "jump squat", "burpee", "mountain climber", "deadlift",
                     "pistol squat", "split squat", "jump", "hop"],

            # Back injuries
            "back": ["deadlift", "romanian deadlift", "good morning", "bent-over row",
                     "squat", "leg press", "overhead press", "military press",
                     "sit-up", "crunch", "superman", "hyperextension", "back extension"],
            "spine": ["deadlift", "romanian deadlift", "good morning", "squat",
                      "overhead press", "sit-up", "crunch", "hyperextension"],
            "lower back": ["deadlift", "romanian deadlift", "good morning", "bent-over row",
                           "squat", "leg press", "sit-up", "crunch", "hyperextension",
                           "back extension", "superman"],

            # Shoulder injuries
            "shoulder": ["overhead press", "military press", "arnold press", "shoulder press",
                         "lateral raise", "upright row", "behind neck", "dip", "bench press",
                         "incline press", "fly", "pullover"],
            "rotator": ["overhead press", "lateral raise", "upright row", "behind neck",
                        "dip", "fly", "pullover"],

            # Wrist/Hand injuries
            "wrist": ["push-up", "pushup", "plank", "handstand", "clean", "snatch",
                      "front squat", "overhead squat", "bench press"],
            "hand": ["push-up", "pushup", "plank", "handstand", "clean", "deadlift"],

            # Hip injuries
            "hip": ["squat", "lunge", "hip thrust", "leg press", "deadlift", "step-up",
                    "glute bridge", "romanian deadlift", "sumo deadlift"],

            # Neck injuries
            "neck": ["shrug", "upright row", "sit-up", "crunch", "neck curl",
                     "neck extension", "behind neck press"],

            # Elbow/Arm injuries
            "elbow": ["curl", "tricep extension", "skull crusher", "close grip",
                      "diamond push-up", "dip"],
            "arm": ["curl", "tricep extension", "skull crusher", "overhead extension"],

            # Ankle injuries
            "ankle": ["calf raise", "jump", "hop", "skip", "run", "sprint",
                      "box jump", "jump squat", "burpee", "lunge"],
        }

        # Determine which injury categories apply
        active_patterns = set()
        injuries_lower = [inj.lower() for inj in injuries]

        for injury in injuries_lower:
            for key, patterns in injury_contraindications.items():
                if key in injury:
                    active_patterns.update(patterns)

        if not active_patterns:
            logger.info("No specific contraindication patterns found for injuries")
            return candidates

        logger.info(f"🚫 Filtering out exercises matching: {active_patterns}")

        # Filter candidates
        safe_candidates = []
        for candidate in candidates:
            exercise_name = candidate.get("name", "").lower()
            target_muscle = candidate.get("target_muscle", "").lower()
            body_part = candidate.get("body_part", "").lower()

            # Check if exercise matches any contraindicated pattern
            is_unsafe = False
            for pattern in active_patterns:
                if pattern in exercise_name or pattern in target_muscle or pattern in body_part:
                    logger.debug(f"🚫 Filtering out '{candidate.get('name')}' (matches '{pattern}')")
                    is_unsafe = True
                    break

            if not is_unsafe:
                safe_candidates.append(candidate)

        return safe_candidates

    def _build_search_query(
        self,
        focus_area: str,
        equipment: List[str],
        fitness_level: str,
        goals: List[str],
    ) -> str:
        """Build a semantic search query for exercises."""
        # Handle full_body emphasis variations for better variety
        focus_keywords = {
            "full_body_push": "full body workout emphasis on push movements chest shoulders triceps pressing",
            "full_body_pull": "full body workout emphasis on pull movements back biceps rowing pulling",
            "full_body_legs": "full body workout emphasis on legs lower body squats lunges glutes hamstrings",
            "full_body_core": "full body workout emphasis on core abs stability planks",
            "full_body_upper": "full body workout upper body focus chest back shoulders arms",
            "full_body_lower": "full body workout lower body focus legs glutes quads hamstrings calves",
            "full_body_power": "full body workout power explosive movements plyometrics jumps",
            "full_body": "full body balanced workout compound exercises",
            # Sport-specific workout types
            "boxing": "boxing workout punching power jab cross hook uppercut footwork conditioning cardio core rotation speed agility combat",
            "hyrox": "hyrox workout functional fitness running lunges burpees rowing sled push farmer carry wall balls ski erg endurance strength hybrid competition",
            "crossfit": "crossfit wod functional movements olympic lifts thrusters pull-ups box jumps kettlebell swings burpees muscle-ups high intensity amrap emom",
            "martial_arts": "martial arts mma grappling striking takedowns conditioning explosive power kicks punches combat training",
            "hiit": "hiit high intensity interval training cardio burpees jumping jacks mountain climbers explosive movements metabolic conditioning",
            "strength": "strength training heavy compound exercises squat deadlift bench press overhead press powerlifting maximal strength",
            "endurance": "endurance stamina cardio running cycling sustained effort aerobic conditioning long duration",
            "flexibility": "flexibility stretching yoga mobility range of motion static stretches dynamic stretches",
            "mobility": "mobility joint health functional movement dynamic stretching foam rolling warm-up activation",
            # Ball sports
            "cricket": "cricket training rotational power batting bowling throwing shoulder stability agility sprints lateral movement core strength explosive power conditioning",
            "football": "football soccer training sprinting agility change direction lower body power endurance conditioning kicks",
            "basketball": "basketball training vertical jump explosive power lateral movement agility conditioning court sprints",
            "tennis": "tennis training lateral movement agility rotational power shoulder stability core conditioning footwork",
        }

        focus_query = focus_keywords.get(focus_area, f"Exercises for {focus_area} workout")

        query_parts = [
            focus_query,
            f"Equipment: {', '.join(equipment) if equipment else 'bodyweight'}",
            f"Fitness level: {fitness_level}",
        ]

        # Add goal-specific terms (base goals)
        goal_keywords = {
            "Build Muscle": "hypertrophy muscle building compound exercises",
            "Lose Weight": "fat burning high intensity metabolic exercises",
            "Increase Strength": "strength power heavy compound exercises",
            "Improve Endurance": "cardio endurance stamina exercises",
            "Flexibility": "stretching mobility flexibility exercises",
            "General Fitness": "functional fitness full body exercises",
        }

        # Get training program keywords dynamically from database/cache
        training_program_keywords = get_training_program_keywords_sync()

        for goal in goals:
            if goal in goal_keywords:
                query_parts.append(goal_keywords[goal])
            # Check if goal matches a training program
            if goal in training_program_keywords:
                query_parts.append(training_program_keywords[goal])

        return " ".join(query_parts)

    async def _ai_select_exercises(
        self,
        candidates: List[Dict],
        focus_area: str,
        fitness_level: str,
        goals: List[str],
        count: int,
        injuries: Optional[List[str]] = None,
    ) -> List[Dict[str, Any]]:
        """Use AI to select the best exercises from candidates, considering injuries."""

        # Format candidates for the prompt
        candidate_list = "\n".join([
            f"{i+1}. {c['name']} - targets {c['target_muscle']}, equipment: {c['equipment']}, body part: {c['body_part']}"
            for i, c in enumerate(candidates)
        ])

        # Build injury awareness section
        injury_section = ""
        if injuries and len(injuries) > 0:
            injury_list = ", ".join(injuries)
            injury_section = f"""
⚠️⚠️⚠️ CRITICAL SAFETY REQUIREMENT - USER HAS INJURIES ⚠️⚠️⚠️
The user has the following injuries/conditions: {injury_list}

YOU MUST STRICTLY AVOID these exercises based on their injuries:

🚫 For "Leg pain", "Knee pain", "Knee injury", or any leg/knee issue:
   - NEVER SELECT: Squats (any variation), Lunges, Leg Press, Leg Extensions, Leg Curls, Step-ups
   - NEVER SELECT: Box Jumps, Jump Squats, Burpees, Mountain Climbers
   - NEVER SELECT: Deadlifts, Romanian Deadlifts, Calf Raises with heavy load
   - AVOID any exercise that puts significant load on the legs/knees

🚫 For "Lower back pain", "Back pain", "Spine issues":
   - NEVER SELECT: Deadlifts, Romanian Deadlifts, Good Mornings, Bent-over Rows
   - NEVER SELECT: Squats, Leg Press, Heavy Overhead Press
   - NEVER SELECT: Sit-ups, Crunches (prefer planks instead)
   - AVOID any exercise with spinal loading or flexion

🚫 For "Shoulder pain", "Shoulder injury", "Rotator cuff":
   - NEVER SELECT: Overhead Press, Military Press, Arnold Press
   - NEVER SELECT: Lateral Raises, Upright Rows, Behind-neck exercises
   - AVOID any overhead movements or internal rotation

🚫 For "Wrist pain", "Wrist injury":
   - NEVER SELECT: Push-ups, Planks, Handstands, Cleans
   - AVOID exercises requiring wrist extension under load

🚫 For "Hip pain", "Hip injury":
   - NEVER SELECT: Squats, Lunges, Hip Thrusts, Leg Press
   - NEVER SELECT: Deadlifts, Step-ups
   - AVOID exercises with deep hip flexion

🚫 For "Neck pain", "Neck injury":
   - NEVER SELECT: Shrugs with heavy weight, Upright Rows
   - NEVER SELECT: Sit-ups, Crunches (neck strain)
   - AVOID exercises that load the neck

IMPORTANT: The user's safety is the TOP PRIORITY. If in doubt, DO NOT select the exercise.
Only select exercises that are 100% SAFE for someone with {injury_list}.
"""

        prompt = f"""You are an expert fitness coach and physical therapist selecting exercises for a workout.

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
3. Ensure variety - different exercises for balanced muscle development
4. Progress from compound to isolation exercises
5. Consider the fitness level - {fitness_level}
6. Align with goals: {', '.join(goals) if goals else 'General fitness'}

Return ONLY a JSON array of the exercise numbers you select (1-indexed), in the order they should be performed.
Example: [1, 5, 3, 8, 2, 6]

Select exactly {count} exercises that are SAFE for this user."""

        try:
            system_content = "You are a fitness expert"
            if injuries:
                system_content += " and certified physical therapist with expertise in injury rehabilitation. SAFETY IS YOUR TOP PRIORITY - never recommend exercises that could aggravate the user's injuries."
            system_content += ". Select exercises wisely. Return ONLY a JSON array of numbers."

            response = await self.openai_service.client.chat.completions.create(
                model="gpt-4-turbo",  # Better model for safety-critical exercise selection
                messages=[
                    {
                        "role": "system",
                        "content": system_content
                    },
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                max_tokens=100
            )

            content = response.choices[0].message.content.strip()

            # Clean markdown
            if content.startswith("```"):
                content = content.split("\n", 1)[1] if "\n" in content else content[3:]
            if content.endswith("```"):
                content = content[:-3]

            selected_indices = json.loads(content.strip())

            # Get selected exercises
            selected = []
            for idx in selected_indices:
                if 1 <= idx <= len(candidates):
                    ex = candidates[idx - 1]
                    # Format for workout
                    selected.append(self._format_exercise_for_workout(ex, fitness_level))

            logger.info(f"✅ AI selected {len(selected)} exercises: {[e['name'] for e in selected]}")
            return selected

        except Exception as e:
            logger.error(f"AI selection failed: {e}, using top candidates")
            # Fallback to top candidates by similarity
            return [
                self._format_exercise_for_workout(c, fitness_level)
                for c in candidates[:count]
            ]

    def _format_exercise_for_workout(self, exercise: Dict, fitness_level: str) -> Dict:
        """Format an exercise for inclusion in a workout."""
        # Determine sets/reps based on fitness level
        if fitness_level == "beginner":
            sets, reps, rest = 2, 10, 90
        elif fitness_level == "advanced":
            sets, reps, rest = 4, 12, 45
        else:
            sets, reps, rest = 3, 12, 60

        # Get equipment - if missing or "bodyweight", try to infer from exercise name
        exercise_name = exercise.get("name", "Unknown")
        raw_equipment = exercise.get("equipment", "")
        if not raw_equipment or raw_equipment.lower() in ["bodyweight", "body weight", "none", ""]:
            # Infer equipment from name
            equipment = _infer_equipment_from_name(exercise_name)
        else:
            equipment = raw_equipment

        return {
            "name": exercise_name,
            "sets": sets,
            "reps": reps,
            "rest_seconds": rest,
            "equipment": equipment,
            "muscle_group": exercise.get("target_muscle", exercise.get("body_part", "")),
            "body_part": exercise.get("body_part", ""),
            "notes": exercise.get("instructions", "Focus on proper form"),
            "gif_url": exercise.get("gif_url", ""),
            "video_url": exercise.get("video_url", ""),  # Include video URL for playback
            "image_url": exercise.get("image_url", ""),  # Include image URL for thumbnails
            "library_id": exercise.get("id", ""),
        }

    async def _fallback_selection(
        self,
        focus_area: str,
        equipment: List[str],
        count: int,
    ) -> List[Dict[str, Any]]:
        """Fallback to direct database query if RAG fails. Uses cleaned view."""
        logger.warning("Using fallback selection from database (cleaned view)")

        # Map focus to body parts
        focus_map = {
            "chest": "chest",
            "back": "back",
            "shoulders": "shoulders",
            "arms": "upper arms",
            "legs": "upper legs",
            "core": "waist",
            "full_body": "chest",  # Start with chest for full body
        }

        body_part = focus_map.get(focus_area.lower(), "chest")

        # Use cleaned view instead of raw table
        result = self.client.table("exercise_library_cleaned").select("*").ilike(
            "body_part", f"%{body_part}%"
        ).limit(count * 4).execute()

        exercises = result.data or []

        # Filter by equipment and only include exercises with videos
        equipment_lower = [eq.lower() for eq in equipment] + ["body weight", "bodyweight"]
        seen_names: set = set()
        filtered = []

        for ex in exercises:
            # Skip exercises without videos - view uses 'video_url' column
            if not ex.get("video_url") and not ex.get("video_s3_path"):
                continue

            # Get cleaned name - view uses 'name' column (fallback for compatibility)
            exercise_name = ex.get("name", ex.get("exercise_name_cleaned", ex.get("exercise_name", "Unknown")))

            # Case-insensitive deduplication
            lower_name = exercise_name.lower()
            if lower_name in seen_names:
                continue
            seen_names.add(lower_name)

            # Filter by equipment
            ex_eq = (ex.get("equipment", "") or "").lower()
            if any(eq in ex_eq for eq in equipment_lower):
                filtered.append({
                    "name": exercise_name,
                    "target_muscle": ex.get("target_muscle", ""),
                    "body_part": ex.get("body_part", ""),
                    "equipment": ex.get("equipment", "bodyweight"),
                    "gif_url": ex.get("gif_url", ""),
                    "video_url": ex.get("video_url", ""),  # Include video URL
                    "image_url": ex.get("image_url", ""),  # Include image URL
                    "instructions": ex.get("instructions", ""),
                    "id": ex.get("id", ""),
                })

        return [
            self._format_exercise_for_workout(ex, "intermediate")
            for ex in filtered[:count]
        ]

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
        openai_service = OpenAIService()
        _exercise_rag_service = ExerciseRAGService(openai_service)
    return _exercise_rag_service
