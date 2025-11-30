"""
Exercise RAG Service - Intelligent exercise selection using embeddings.

This service:
1. Indexes all exercises from exercise_library with embeddings
2. Uses AI to select the best exercises based on user profile, goals, equipment
3. Considers exercise variety, muscle balance, and progression
"""
from typing import List, Dict, Any, Optional
import json

from core.config import get_settings
from core.chroma_cloud import get_chroma_cloud_client
from core.supabase_client import get_supabase
from core.logger import get_logger
from services.openai_service import OpenAIService

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
        Index all exercises from the exercise_library table.

        Call this once to populate the vector store, or periodically to update.
        Uses batch embedding API to minimize API calls.

        Returns:
            Number of exercises indexed
        """
        logger.info("🔄 Starting exercise library indexing...")

        # Fetch all exercises from Supabase
        result = self.client.table("exercise_library").select("*").execute()
        exercises = result.data or []

        if not exercises:
            logger.warning("No exercises found in exercise_library table")
            return 0

        logger.info(f"📊 Found {len(exercises)} exercises to index")
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

                ids.append(doc_id)
                documents.append(exercise_text)
                # ChromaDB only accepts str, int, float, bool - convert None to empty string
                metadatas.append({
                    "exercise_id": str(ex.get("id") or ""),
                    "name": str(ex.get("exercise_name") or "Unknown"),
                    "body_part": str(ex.get("body_part") or ""),
                    "equipment": str(ex.get("equipment") or "bodyweight"),
                    "target_muscle": str(ex.get("target_muscle") or ""),
                    "secondary_muscles": json.dumps(ex.get("secondary_muscles") or []),
                    "difficulty": str(ex.get("difficulty_level") or "intermediate"),
                    "category": str(ex.get("category") or ""),
                    "gif_url": str(ex.get("gif_url") or ""),
                    "instructions": str(ex.get("instructions") or "")[:500],
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
        name = exercise.get("exercise_name", "Unknown")
        body_part = exercise.get("body_part", "")
        equipment = exercise.get("equipment", "bodyweight")
        target = exercise.get("target_muscle", "")
        secondary = exercise.get("secondary_muscles", [])
        category = exercise.get("category", "")
        difficulty = exercise.get("difficulty_level", "")
        instructions = exercise.get("instructions", "")

        text_parts = [
            f"Exercise: {name}",
            f"Body Part: {body_part}",
            f"Target Muscle: {target}",
            f"Equipment: {equipment}",
        ]

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

        Returns:
            List of selected exercises with full details
        """
        logger.info(f"🎯 Selecting {count} exercises for {focus_area} workout")

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
        for i, doc_id in enumerate(results["ids"][0]):
            meta = results["metadatas"][0][i]
            distance = results["distances"][0][i]
            similarity = 1 / (1 + distance)

            # Skip exercises to avoid
            if avoid_exercises and meta.get("name", "").lower() in [e.lower() for e in avoid_exercises]:
                continue

            # Filter by equipment compatibility
            ex_equipment = (meta.get("equipment", "") or "").lower()
            equipment_lower = [eq.lower() for eq in equipment] + ["body weight", "bodyweight", "none"]

            if not any(eq in ex_equipment for eq in equipment_lower):
                continue

            candidates.append({
                "id": meta.get("exercise_id", ""),
                "name": meta.get("name", "Unknown"),
                "body_part": meta.get("body_part", ""),
                "equipment": meta.get("equipment", "bodyweight"),
                "target_muscle": meta.get("target_muscle", ""),
                "difficulty": meta.get("difficulty", "intermediate"),
                "gif_url": meta.get("gif_url", ""),
                "instructions": meta.get("instructions", ""),
                "similarity": similarity,
            })

        if not candidates:
            logger.warning("No compatible exercises found after filtering")
            return await self._fallback_selection(focus_area, equipment, count)

        # Use AI to make final selection
        selected = await self._ai_select_exercises(
            candidates=candidates[:20],  # Limit candidates for AI
            focus_area=focus_area,
            fitness_level=fitness_level,
            goals=goals,
            count=count,
        )

        return selected

    def _build_search_query(
        self,
        focus_area: str,
        equipment: List[str],
        fitness_level: str,
        goals: List[str],
    ) -> str:
        """Build a semantic search query for exercises."""
        query_parts = [
            f"Exercises for {focus_area} workout",
            f"Equipment: {', '.join(equipment) if equipment else 'bodyweight'}",
            f"Fitness level: {fitness_level}",
        ]

        # Add goal-specific terms
        goal_keywords = {
            "Build Muscle": "hypertrophy muscle building compound exercises",
            "Lose Weight": "fat burning high intensity metabolic exercises",
            "Increase Strength": "strength power heavy compound exercises",
            "Improve Endurance": "cardio endurance stamina exercises",
            "Flexibility": "stretching mobility flexibility exercises",
            "General Fitness": "functional fitness full body exercises",
        }

        for goal in goals:
            if goal in goal_keywords:
                query_parts.append(goal_keywords[goal])

        return " ".join(query_parts)

    async def _ai_select_exercises(
        self,
        candidates: List[Dict],
        focus_area: str,
        fitness_level: str,
        goals: List[str],
        count: int,
    ) -> List[Dict[str, Any]]:
        """Use AI to select the best exercises from candidates."""

        # Format candidates for the prompt
        candidate_list = "\n".join([
            f"{i+1}. {c['name']} - targets {c['target_muscle']}, equipment: {c['equipment']}, body part: {c['body_part']}"
            for i, c in enumerate(candidates)
        ])

        prompt = f"""You are an expert fitness coach selecting exercises for a workout.

TARGET WORKOUT:
- Focus: {focus_area}
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Number of exercises needed: {count}

AVAILABLE EXERCISES:
{candidate_list}

SELECTION CRITERIA:
1. Choose exercises that best target the focus area ({focus_area})
2. Ensure variety - different exercises for balanced muscle development
3. Progress from compound to isolation exercises
4. Consider the fitness level - {fitness_level}
5. Align with goals: {', '.join(goals) if goals else 'General fitness'}

Return ONLY a JSON array of the exercise numbers you select (1-indexed), in the order they should be performed.
Example: [1, 5, 3, 8, 2, 6]

Select exactly {count} exercises."""

        try:
            response = await self.openai_service.client.chat.completions.create(
                model="gpt-4o-mini",  # Fast model for selection
                messages=[
                    {
                        "role": "system",
                        "content": "You are a fitness expert. Select exercises wisely. Return ONLY a JSON array of numbers."
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

        return {
            "name": exercise.get("name", "Unknown"),
            "sets": sets,
            "reps": reps,
            "rest_seconds": rest,
            "equipment": exercise.get("equipment", "bodyweight"),
            "muscle_group": exercise.get("target_muscle", exercise.get("body_part", "")),
            "body_part": exercise.get("body_part", ""),
            "notes": exercise.get("instructions", "Focus on proper form")[:200],
            "gif_url": exercise.get("gif_url", ""),
            "library_id": exercise.get("id", ""),
        }

    async def _fallback_selection(
        self,
        focus_area: str,
        equipment: List[str],
        count: int,
    ) -> List[Dict[str, Any]]:
        """Fallback to direct database query if RAG fails."""
        logger.warning("Using fallback selection from database")

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

        result = self.client.table("exercise_library").select("*").ilike(
            "body_part", f"%{body_part}%"
        ).limit(count * 2).execute()

        exercises = result.data or []

        # Filter by equipment
        equipment_lower = [eq.lower() for eq in equipment] + ["body weight", "bodyweight"]
        filtered = []
        for ex in exercises:
            ex_eq = (ex.get("equipment", "") or "").lower()
            if any(eq in ex_eq for eq in equipment_lower):
                filtered.append({
                    "name": ex.get("exercise_name", "Unknown"),
                    "target_muscle": ex.get("target_muscle", ""),
                    "body_part": ex.get("body_part", ""),
                    "equipment": ex.get("equipment", "bodyweight"),
                    "gif_url": ex.get("gif_url", ""),
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
