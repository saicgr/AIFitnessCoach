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
)
from .search import build_search_query, build_search_query_with_custom_goals

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

        Returns:
            List of selected exercises with full details
        """
        logger.info(f"Selecting {count} exercises for {focus_area} workout")
        logger.info(f"Equipment: {equipment}, Dumbbells: {dumbbell_count}, Kettlebells: {kettlebell_count}")
        logger.info(f"Consistency mode: {consistency_mode}")
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

        # Build search query (with custom goals if user_id provided)
        if user_id:
            search_query = await build_search_query_with_custom_goals(
                focus_area, equipment, fitness_level, goals, user_id
            )
        else:
            search_query = build_search_query(focus_area, equipment, fitness_level, goals)

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

        # Format candidates
        candidates = []
        seen_exercises: List[str] = []

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

            # Filter out exercises without media
            has_video = meta.get("has_video", "false") == "true"
            gif_url = meta.get("gif_url", "")
            video_url = meta.get("video_url", "")
            image_url = meta.get("image_url", "")
            has_media = has_video or bool(gif_url) or bool(video_url) or bool(image_url)
            if not has_media:
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

            # Clean name for display
            raw_name = meta.get("name", "Unknown")
            exercise_name = clean_exercise_name_for_display(raw_name)

            # Skip similar exercises
            is_duplicate = False
            for seen_name in seen_exercises:
                if is_similar_exercise(exercise_name, seen_name):
                    is_duplicate = True
                    break

            if is_duplicate:
                continue

            seen_exercises.append(exercise_name)

            # Get equipment
            raw_eq = meta.get("equipment", "")
            if not raw_eq or raw_eq.lower() in ["bodyweight", "body weight", "none", ""]:
                eq = infer_equipment_from_name(exercise_name)
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
                "video_url": meta.get("video_url", ""),
                "image_url": meta.get("image_url", ""),
                "instructions": meta.get("instructions", ""),
                "similarity": similarity,
                "single_dumbbell_friendly": meta.get("single_dumbbell_friendly", "false") == "true",
                "single_kettlebell_friendly": meta.get("single_kettlebell_friendly", "false") == "true",
                "alternating_hands": meta.get("single_dumbbell_friendly", "false") == "true",
            })

        if not candidates:
            logger.error("No compatible exercises found after filtering")
            raise ValueError(f"No compatible exercises found for focus_area={focus_area}, equipment={equipment}")

        # Pre-filter for injuries
        if injuries and len(injuries) > 0:
            safe_candidates = pre_filter_by_injuries(candidates, injuries)
            if safe_candidates:
                logger.info(f"Pre-filtered {len(candidates)} candidates to {len(safe_candidates)} safe exercises")
                candidates = safe_candidates
            else:
                logger.warning("Pre-filter removed all candidates, keeping original list")

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
        remaining_count = count - len(queued_included)

        if remaining_count > 0:
            # Use AI to select remaining exercises
            selected = await self._ai_select_exercises(
                candidates=candidates[:20],
                focus_area=focus_area,
                fitness_level=fitness_level,
                goals=goals,
                count=remaining_count,
                injuries=injuries,
                workout_params=workout_params,
                strength_history=strength_history,
            )
        else:
            selected = []

        # Combine queued exercises first, then AI-selected exercises
        final_selection = queued_included + selected

        # Store queued exercise names for marking as used (returned via metadata)
        if queued_names_used:
            for ex in final_selection:
                if ex["name"] in queued_names_used:
                    ex["from_queue"] = True

        # Add metadata about selection process for transparency
        selection_metadata = {
            "queued_included_count": len(queued_included),
            "queued_exclusion_reasons": queued_exclusion_reasons,
            "favorites_in_selection": sum(1 for ex in final_selection if ex.get("is_favorite")),
            "consistency_boosted_count": sum(1 for ex in final_selection if ex.get("consistency_boosted")),
            "historical_weights_available": len(strength_history) if strength_history else 0,
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
                        ex, fitness_level, workout_params, strength_history
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
                                candidate, fitness_level, workout_params, strength_history
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
    ) -> Dict:
        """
        Format an exercise for inclusion in a workout.

        Includes equipment-aware starting weight recommendations based on:
        - User's historical strength data (if available) - HIGHEST PRIORITY
        - Exercise type (compound vs isolation)
        - Equipment type (dumbbell, barbell, machine, etc.)
        - User's fitness level

        Args:
            exercise: Raw exercise data from the database
            fitness_level: User's fitness level (beginner, intermediate, advanced)
            workout_params: Optional adaptive parameters (sets, reps, rest_seconds)
            strength_history: Dict mapping exercise names to historical weight data
                              e.g. {"Bench Press": {"last_weight_kg": 70, "max_weight_kg": 85, "last_reps": 8}}

        Returns:
            Formatted exercise dict with realistic weight recommendations
        """
        if workout_params:
            sets = workout_params.get("sets", 3)
            reps = workout_params.get("reps", 12)
            rest = workout_params.get("rest_seconds", 60)
        elif fitness_level == "beginner":
            sets, reps, rest = 2, 10, 90
        elif fitness_level == "advanced":
            sets, reps, rest = 4, 12, 45
        else:
            sets, reps, rest = 3, 12, 60

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
                    fitness_level=fitness_level,
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
