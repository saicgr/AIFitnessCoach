"""
RAG (Retrieval Augmented Generation) Service.

This service stores Q&A pairs and retrieves similar past conversations
to provide better context to the AI.

Uses Chroma Cloud (cloud-hosted vector database) for all deployments.
"""
from typing import List, Dict, Any, Optional, Union
from datetime import datetime
import uuid
from core.config import get_settings
from core.chroma_cloud import get_chroma_cloud_client
from services.gemini_service import GeminiService

settings = get_settings()

# Import split descriptions from dedicated module (avoids circular imports)
from services.split_descriptions import SPLIT_DESCRIPTIONS, get_split_context


class RAGService:
    """
    RAG service for storing and retrieving Q&A pairs.

    How it works:
    1. Every chat Q&A is stored with an embedding
    2. When a new question comes in, we find similar past questions
    3. The similar Q&As are used as context for the AI

    This makes responses more accurate over time!
    """

    def __init__(self, gemini_service: GeminiService):
        self.gemini_service = gemini_service

        # Get Chroma Cloud client
        self.chroma_client = get_chroma_cloud_client()
        self.collection = self.chroma_client.get_rag_collection()

        print(f"✅ RAG initialized with {self.collection.count()} documents")

    async def add_qa_pair(
        self,
        question: str,
        answer: str,
        intent: str,
        user_id: Union[str, int],
        metadata: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        Store a Q&A pair in the RAG system.

        Args:
            question: User's question
            answer: AI's answer
            intent: Detected intent
            user_id: User ID
            metadata: Additional metadata

        Returns:
            Document ID
        """
        doc_id = str(uuid.uuid4())

        # Create combined text for embedding
        combined_text = f"Q: {question}\nA: {answer}"

        # Get embedding from Gemini
        embedding = await self.gemini_service.get_embedding_async(combined_text)

        # Store in ChromaDB
        self.collection.add(
            ids=[doc_id],
            embeddings=[embedding],
            documents=[combined_text],
            metadatas=[{
                "question": question,
                "answer": answer,
                "intent": intent,
                "user_id": user_id,
                **(metadata or {}),
            }],
        )

        print(f"📚 Stored Q&A pair: {doc_id[:8]}... (total: {self.collection.count()})")
        return doc_id

    async def find_similar(
        self,
        query: str,
        n_results: int = None,
        user_id: Optional[Union[str, int]] = None,
        intent_filter: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Find similar past Q&A pairs.

        Args:
            query: The question to find similar matches for
            n_results: Number of results (default from config)
            user_id: Optional filter by user
            intent_filter: Optional filter by intent

        Returns:
            List of similar documents with scores
        """
        if self.collection.count() == 0:
            return []

        n_results = n_results or settings.rag_top_k

        # Get query embedding
        query_embedding = await self.gemini_service.get_embedding_async(query)

        # Build where filter
        where_filter = {}
        if user_id is not None:
            where_filter["user_id"] = user_id
        if intent_filter is not None:
            where_filter["intent"] = intent_filter

        # Query ChromaDB
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=min(n_results, self.collection.count()),
            where=where_filter if where_filter else None,
            include=["documents", "metadatas", "distances"],
        )

        # Format results
        similar_docs = []
        for i, doc_id in enumerate(results["ids"][0]):
            distance = results["distances"][0][i]
            # ChromaDB with cosine distance: distance ranges 0-2, convert to similarity 0-1
            # similarity = 1 - (distance / 2) maps: 0 -> 1.0, 1 -> 0.5, 2 -> 0.0
            similarity = 1 - (distance / 2)

            if similarity >= settings.rag_min_similarity:
                similar_docs.append({
                    "id": doc_id,
                    "document": results["documents"][0][i],
                    "metadata": results["metadatas"][0][i],
                    "similarity": similarity,
                })

        print(f"🔍 Found {len(similar_docs)} similar docs for: '{query[:50]}...'")
        return similar_docs

    def format_context(self, similar_docs: List[Dict[str, Any]]) -> str:
        """
        Format similar documents into context for the AI prompt.

        Args:
            similar_docs: List of similar documents

        Returns:
            Formatted context string
        """
        if not similar_docs:
            return ""

        context_parts = ["RELEVANT PAST CONVERSATIONS:"]

        for i, doc in enumerate(similar_docs[:3], 1):  # Limit to top 3
            meta = doc["metadata"]
            context_parts.append(
                f"\n{i}. User asked: \"{meta['question']}\"\n"
                f"   Coach answered: \"{meta['answer'][:200]}...\"\n"
                f"   (Intent: {meta['intent']}, Similarity: {doc['similarity']:.2f})"
            )

        return "\n".join(context_parts)

    def get_stats(self) -> Dict[str, Any]:
        """Get RAG system statistics."""
        return {
            "total_documents": self.collection.count(),
            "storage": "chroma_cloud",
        }

    async def clear_all(self):
        """Clear all stored documents (use carefully!)."""
        self.chroma_client.delete_collection(self.chroma_client.rag_collection_name)
        self.collection = self.chroma_client.get_rag_collection()
        print("🗑️ Cleared all RAG documents")


class WorkoutRAGService:
    """
    RAG service specifically for workout history and changes.

    This allows the AI coach to:
    1. Recall past workouts and exercises
    2. Track workout modifications over time
    3. Provide personalized advice based on workout history
    """

    def __init__(self, gemini_service: GeminiService):
        self.gemini_service = gemini_service

        # Get Chroma Cloud client
        self.chroma_client = get_chroma_cloud_client()

        # Collection for workout documents
        self.workout_collection = self.chroma_client.get_workout_collection()

        # Collection for workout changes (using a custom collection name)
        self.changes_collection = self.chroma_client.get_or_create_collection(
            "workout_changes"
        )

        print(f"✅ Workout RAG initialized: {self.workout_collection.count()} workouts, {self.changes_collection.count()} changes")

    async def index_workout(
        self,
        workout_id: int,
        user_id: Union[str, int],
        name: str,
        workout_type: str,
        difficulty: str,
        exercises: List[Dict[str, Any]],
        scheduled_date: str,
        is_completed: bool = False,
        generation_method: str = "algorithm",
    ) -> str:
        """
        Index a workout for RAG retrieval.

        Args:
            workout_id: Unique workout ID
            user_id: User ID
            name: Workout name
            workout_type: Type (strength, cardio, etc.)
            difficulty: Difficulty level
            exercises: List of exercises
            scheduled_date: Date of workout
            is_completed: Whether completed
            generation_method: How workout was generated

        Returns:
            Document ID
        """
        doc_id = f"workout_{workout_id}"

        # Build exercise summary
        exercise_names = [e.get("name", "Unknown") for e in exercises]
        exercise_summary = ", ".join(exercise_names[:5])
        if len(exercises) > 5:
            exercise_summary += f" and {len(exercises) - 5} more"

        # Create searchable text
        workout_text = (
            f"Workout: {name}\n"
            f"Type: {workout_type}\n"
            f"Difficulty: {difficulty}\n"
            f"Exercises: {exercise_summary}\n"
            f"Date: {scheduled_date}\n"
            f"Status: {'Completed' if is_completed else 'Scheduled'}"
        )

        # Get embedding
        embedding = await self.gemini_service.get_embedding_async(workout_text)

        # Upsert to collection (update if exists)
        try:
            self.workout_collection.delete(ids=[doc_id])
        except Exception:
            pass  # Document might not exist

        self.workout_collection.add(
            ids=[doc_id],
            embeddings=[embedding],
            documents=[workout_text],
            metadatas=[{
                "workout_id": workout_id,
                "user_id": user_id,
                "name": name,
                "type": workout_type,
                "difficulty": difficulty,
                "exercise_count": len(exercises),
                "scheduled_date": scheduled_date,
                "is_completed": is_completed,
                "generation_method": generation_method,
            }],
        )

        print(f"🏋️ Indexed workout: {name} (ID: {workout_id})")
        return doc_id

    async def index_workout_change(
        self,
        change_id: int,
        workout_id: int,
        user_id: Union[str, int],
        change_type: str,
        field_changed: Optional[str] = None,
        old_value: Optional[str] = None,
        new_value: Optional[str] = None,
        change_source: str = "api",
        change_reason: Optional[str] = None,
        created_at: str = None,
    ) -> str:
        """
        Index a workout change for RAG retrieval.

        This helps the AI understand how workouts evolved and why.
        """
        doc_id = f"change_{change_id}"

        # Build change description
        change_text = f"Workout change ({change_type})"
        if field_changed:
            change_text += f": {field_changed}"
        if old_value and new_value:
            change_text += f" from '{old_value}' to '{new_value}'"
        elif new_value:
            change_text += f": {new_value}"
        if change_reason:
            change_text += f" (Reason: {change_reason})"
        change_text += f" via {change_source}"

        # Get embedding
        embedding = await self.gemini_service.get_embedding_async(change_text)

        self.changes_collection.add(
            ids=[doc_id],
            embeddings=[embedding],
            documents=[change_text],
            metadatas=[{
                "change_id": change_id,
                "workout_id": workout_id,
                "user_id": user_id,
                "change_type": change_type,
                "field_changed": field_changed or "",
                "change_source": change_source,
                "created_at": created_at or "",
            }],
        )

        print(f"📝 Indexed change: {change_type} for workout {workout_id}")
        return doc_id

    async def find_similar_workouts(
        self,
        query: str,
        user_id: Optional[Union[str, int]] = None,
        n_results: int = 5,
        workout_type: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Find similar past workouts.

        Args:
            query: Search query (e.g., "leg day", "strength workout")
            user_id: Optional filter by user
            n_results: Number of results
            workout_type: Optional filter by type

        Returns:
            List of similar workouts
        """
        if self.workout_collection.count() == 0:
            return []

        # Get query embedding
        query_embedding = await self.gemini_service.get_embedding_async(query)

        # Build where filter
        where_filter = {}
        if user_id is not None:
            where_filter["user_id"] = user_id
        if workout_type is not None:
            where_filter["type"] = workout_type

        # Query
        results = self.workout_collection.query(
            query_embeddings=[query_embedding],
            n_results=min(n_results, self.workout_collection.count()),
            where=where_filter if where_filter else None,
            include=["documents", "metadatas", "distances"],
        )

        # Format results
        similar_workouts = []
        for i, doc_id in enumerate(results["ids"][0]):
            distance = results["distances"][0][i]
            # Cosine distance: 0-2 range, convert to similarity 0-1
            similarity = 1 - (distance / 2)

            if similarity >= settings.rag_min_similarity:
                similar_workouts.append({
                    "id": doc_id,
                    "document": results["documents"][0][i],
                    "metadata": results["metadatas"][0][i],
                    "similarity": similarity,
                })

        print(f"🔍 Found {len(similar_workouts)} similar workouts for: '{query[:50]}...'")
        return similar_workouts

    async def get_workout_changes(
        self,
        workout_id: Optional[int] = None,
        user_id: Optional[Union[str, int]] = None,
        n_results: int = 10,
    ) -> List[Dict[str, Any]]:
        """
        Get workout changes, optionally filtered.

        Args:
            workout_id: Filter by specific workout
            user_id: Filter by user
            n_results: Number of results

        Returns:
            List of workout changes
        """
        if self.changes_collection.count() == 0:
            return []

        # Build where filter
        where_filter = {}
        if workout_id is not None:
            where_filter["workout_id"] = workout_id
        if user_id is not None:
            where_filter["user_id"] = user_id

        # Get all matching changes
        results = self.changes_collection.get(
            where=where_filter if where_filter else None,
            include=["documents", "metadatas"],
            limit=n_results,
        )

        changes = []
        for i, doc_id in enumerate(results["ids"]):
            changes.append({
                "id": doc_id,
                "document": results["documents"][i],
                "metadata": results["metadatas"][i],
            })

        return changes

    def format_workout_context(self, similar_workouts: List[Dict[str, Any]]) -> str:
        """Format similar workouts into context for AI."""
        if not similar_workouts:
            return ""

        context_parts = ["RELEVANT PAST WORKOUTS:"]

        for i, workout in enumerate(similar_workouts[:3], 1):
            meta = workout["metadata"]
            context_parts.append(
                f"\n{i}. {meta['name']} ({meta['type']})\n"
                f"   Difficulty: {meta['difficulty']}, Exercises: {meta['exercise_count']}\n"
                f"   Date: {meta['scheduled_date']}, Status: {'Completed' if meta['is_completed'] else 'Scheduled'}\n"
                f"   (Similarity: {workout['similarity']:.2f})"
            )

        return "\n".join(context_parts)

    async def index_program_preferences(
        self,
        user_id: str,
        difficulty: Optional[str] = None,
        duration_minutes: Optional[int] = None,
        workout_type: Optional[str] = None,
        workout_days: Optional[List[str]] = None,
        equipment: Optional[List[str]] = None,
        focus_areas: Optional[List[str]] = None,
        injuries: Optional[List[str]] = None,
        goals: Optional[List[str]] = None,
        motivations: Optional[List[str]] = None,
        dumbbell_count: Optional[int] = None,
        kettlebell_count: Optional[int] = None,
        training_experience: Optional[str] = None,
        workout_environment: Optional[str] = None,
        change_reason: str = "user_customization",
    ) -> str:
        """
        Index program preference changes for AI context retrieval.

        This allows the AI coach to reference the user's preference history:
        - "I see you recently changed your focus to upper body..."
        - "Since you added that lower back injury, I'll avoid..."
        - "You've been doing 4-day splits lately..."
        - "You have a single dumbbell, so I'll suggest single dumbbell exercises..."

        Args:
            user_id: User ID
            difficulty: Selected difficulty (easy/medium/hard)
            duration_minutes: Workout duration preference
            workout_type: Workout style (Strength, HIIT, etc.)
            workout_days: Selected workout days
            equipment: Available equipment
            focus_areas: Target muscle groups
            injuries: Areas to avoid
            goals: Fitness goals (multi-select)
            motivations: What motivates the user (multi-select)
            dumbbell_count: Number of dumbbells (1=single, 2=pair)
            kettlebell_count: Number of kettlebells (1=single, 2+=multiple)
            change_reason: Why preferences were changed

        Returns:
            Document ID
        """
        from datetime import datetime

        timestamp = datetime.now().isoformat()
        doc_id = f"prefs_{user_id}_{timestamp}"

        # Build preference summary text
        pref_parts = [f"Program Preferences Update for user {user_id}"]
        pref_parts.append(f"Updated: {timestamp}")
        pref_parts.append(f"Reason: {change_reason}")

        if goals:
            pref_parts.append(f"Fitness Goals: {', '.join(goals)}")
        if motivations:
            pref_parts.append(f"Motivations: {', '.join(motivations)}")
        if training_experience:
            # Map to human-readable text for AI context
            exp_map = {
                'never': 'No prior lifting experience',
                'less_than_6_months': 'Less than 6 months lifting experience',
                '6_months_to_2_years': '6 months to 2 years lifting experience',
                '2_to_5_years': '2 to 5 years lifting experience',
                '5_plus_years': 'Over 5 years lifting experience',
            }
            pref_parts.append(f"Training Experience: {exp_map.get(training_experience, training_experience)}")
        if workout_environment:
            env_map = {
                'commercial_gym': 'Commercial gym',
                'home_gym': 'Home gym setup',
                'home': 'Home without dedicated gym',
                'outdoors': 'Outdoor workouts',
                'hotel': 'Hotel/travel workouts',
                'apartment_gym': 'Apartment building gym',
                'office_gym': 'Office/workplace gym',
                'custom': 'Custom equipment setup',
            }
            pref_parts.append(f"Workout Environment: {env_map.get(workout_environment, workout_environment)}")
        if difficulty:
            pref_parts.append(f"Difficulty: {difficulty}")
        if duration_minutes:
            pref_parts.append(f"Duration: {duration_minutes} minutes")
        if workout_type:
            pref_parts.append(f"Workout Type: {workout_type}")
        if workout_days:
            pref_parts.append(f"Workout Days: {', '.join(workout_days)}")
        if equipment:
            pref_parts.append(f"Equipment: {', '.join(equipment)}")
        if dumbbell_count is not None:
            dumbbell_desc = "single dumbbell" if dumbbell_count == 1 else f"pair of dumbbells ({dumbbell_count})"
            pref_parts.append(f"Dumbbells: {dumbbell_desc}")
        if kettlebell_count is not None:
            kettlebell_desc = "single kettlebell" if kettlebell_count == 1 else f"multiple kettlebells ({kettlebell_count})"
            pref_parts.append(f"Kettlebells: {kettlebell_desc}")
        if focus_areas:
            pref_parts.append(f"Focus Areas: {', '.join(focus_areas)}")
        if injuries:
            pref_parts.append(f"Injuries to Avoid: {', '.join(injuries)}")

        pref_text = "\n".join(pref_parts)

        # Get embedding
        try:
            embedding = await self.gemini_service.get_embedding_async(pref_text)

            # Add to changes collection (reusing existing collection for preference changes)
            self.changes_collection.add(
                ids=[doc_id],
                embeddings=[embedding],
                documents=[pref_text],
                metadatas=[{
                    "user_id": user_id,
                    "change_type": "program_preferences",
                    "goals": ",".join(goals) if goals else "",
                    "motivations": ",".join(motivations) if motivations else "",
                    "training_experience": training_experience or "",
                    "workout_environment": workout_environment or "",
                    "difficulty": difficulty or "",
                    "duration_minutes": duration_minutes or 0,
                    "workout_type": workout_type or "",
                    "workout_days": ",".join(workout_days) if workout_days else "",
                    "equipment": ",".join(equipment) if equipment else "",
                    "dumbbell_count": dumbbell_count or 2,
                    "kettlebell_count": kettlebell_count or 1,
                    "focus_areas": ",".join(focus_areas) if focus_areas else "",
                    "injuries": ",".join(injuries) if injuries else "",
                    "change_reason": change_reason,
                    "timestamp": timestamp,
                }],
            )

            print(f"📝 Indexed program preferences for user {user_id}: {change_reason}")
            return doc_id
        except Exception as e:
            print(f"❌ Failed to index program preferences: {e}")
            return ""

    async def index_training_settings(
        self,
        user_id: str,
        action: str,
        one_rms: Optional[List[Dict[str, Any]]] = None,
        global_intensity_percent: Optional[int] = None,
        exercise_overrides: Optional[Dict[str, int]] = None,
        progression_pace: Optional[str] = None,
        training_split: Optional[str] = None,
        workout_type: Optional[str] = None,
        exercise_consistency: Optional[str] = None,  # 'consistent' or 'varied'
        variation_percentage: Optional[int] = None,  # 0-100
    ) -> str:
        """
        Index training settings changes for AI context retrieval.

        This allows the AI coach to reference the user's training configuration:
        - "Based on your 100kg bench press 1RM at 75% intensity, try 75kg..."
        - "Since you prefer slow progression, I'll keep weights steady..."
        - "Your Push/Pull/Legs split means today is a push day..."

        Args:
            user_id: User ID
            action: What changed (set_1rm, delete_1rm, set_training_intensity, etc.)
            one_rms: List of 1RM records [{exercise_name, one_rep_max_kg, source}]
            global_intensity_percent: Global training intensity (50-100%)
            exercise_overrides: Per-exercise intensity overrides {exercise: percent}
            progression_pace: slow/medium/fast
            training_split: full_body/push_pull_legs/upper_lower/etc.
            workout_type: strength/cardio/mixed/mobility/recovery
            exercise_consistency: 'consistent' or 'varied' - whether to use same exercises weekly
            variation_percentage: 0-100 - percentage of exercises that rotate each week

        Returns:
            Document ID
        """
        from datetime import datetime

        timestamp = datetime.now().isoformat()
        doc_id = f"training_{user_id}_{action}_{timestamp}"

        # Build training settings summary text
        parts = [f"Training Settings Update for user {user_id}"]
        parts.append(f"Updated: {timestamp}")
        parts.append(f"Action: {action}")

        if one_rms:
            parts.append("One Rep Max (1RM) Records:")
            for rm in one_rms:
                exercise = rm.get("exercise_name", "Unknown")
                weight = rm.get("one_rep_max_kg", 0)
                source = rm.get("source", "manual")
                parts.append(f"  - {exercise}: {weight}kg ({source})")

        if global_intensity_percent is not None:
            intensity_desc = self._get_intensity_description(global_intensity_percent)
            parts.append(f"Global Training Intensity: {global_intensity_percent}% ({intensity_desc})")

        if exercise_overrides:
            parts.append("Per-Exercise Intensity Overrides:")
            for exercise, percent in exercise_overrides.items():
                desc = self._get_intensity_description(percent)
                parts.append(f"  - {exercise}: {percent}% ({desc})")

        if progression_pace:
            pace_desc = {
                'slow': 'Increase weight every 3-4 weeks',
                'medium': 'Increase weight every 1-2 weeks',
                'fast': 'Increase weight every session',
            }.get(progression_pace, progression_pace)
            parts.append(f"Progression Pace: {progression_pace} - {pace_desc}")

        if training_split:
            # Use comprehensive split descriptions with scientific context
            split_context = get_split_context(training_split)
            parts.append(split_context)

        if workout_type:
            type_desc = {
                'strength': 'Weight training focus',
                'cardio': 'Running, cycling, HIIT',
                'mixed': 'Strength + cardio days',
                'mobility': 'Stretching, yoga, flexibility',
                'recovery': 'Light movement, active rest',
            }.get(workout_type, workout_type)
            parts.append(f"Workout Type: {workout_type} - {type_desc}")

        # Exercise Consistency
        if exercise_consistency:
            if exercise_consistency == "consistent":
                parts.append("Exercise Consistency: CONSISTENT - Same core exercises each week for better progress tracking")
            else:
                parts.append("Exercise Consistency: VARIED - Different exercises each week to prevent boredom and hit muscles from different angles")

        # Weekly Variety
        if variation_percentage is not None:
            parts.append(f"Weekly Variety: {variation_percentage}% - {100 - variation_percentage}% of exercises stay the same, {variation_percentage}% rotate each week")

        settings_text = "\n".join(parts)

        # Get embedding and store
        try:
            embedding = await self.gemini_service.get_embedding_async(settings_text)

            # Build metadata
            metadata = {
                "user_id": user_id,
                "change_type": "training_settings",
                "action": action,
                "timestamp": timestamp,
            }
            if global_intensity_percent is not None:
                metadata["global_intensity_percent"] = global_intensity_percent
            if progression_pace:
                metadata["progression_pace"] = progression_pace
            if training_split:
                metadata["training_split"] = training_split
            if workout_type:
                metadata["workout_type"] = workout_type
            if one_rms:
                # Store 1RM summary as comma-separated for search
                rm_summary = ",".join([f"{rm['exercise_name']}:{rm['one_rep_max_kg']}kg" for rm in one_rms])
                metadata["one_rms"] = rm_summary[:500]  # Limit length
            if exercise_consistency:
                metadata["exercise_consistency"] = exercise_consistency
            if variation_percentage is not None:
                metadata["variation_percentage"] = variation_percentage

            self.changes_collection.add(
                ids=[doc_id],
                embeddings=[embedding],
                documents=[settings_text],
                metadatas=[metadata],
            )

            print(f"📝 Indexed training settings for user {user_id}: {action}")
            return doc_id
        except Exception as e:
            print(f"❌ Failed to index training settings: {e}")
            return ""

    def get_recent_training_settings(
        self,
        user_id: str,
        days_lookback: int = 30,
        max_results: int = 10,
    ) -> Dict[str, Any]:
        """
        Retrieve the most recent training settings for a user with recency filtering.

        This method queries the changes_collection and returns a consolidated view
        of the user's current training configuration, prioritizing the most recent
        settings for each category.

        Args:
            user_id: User ID to retrieve settings for
            days_lookback: Only consider settings from the last N days (default 30)
            max_results: Maximum number of documents to query (default 10)

        Returns:
            Dict containing consolidated training settings:
            {
                "one_rms": {"bench press": 100, ...},  # Most recent 1RMs
                "global_intensity_percent": 75,
                "progression_pace": "medium",
                "training_split": "push_pull_legs",
                "workout_type": "strength",
                "exercise_consistency": "varied",
                "variation_percentage": 30,
                "context_text": "Formatted text for AI context",
                "has_settings": bool,
            }
        """
        from datetime import datetime, timedelta

        try:
            # Query training settings for this user
            results = self.changes_collection.get(
                where={
                    "$and": [
                        {"user_id": {"$eq": user_id}},
                        {"change_type": {"$eq": "training_settings"}},
                    ]
                },
                include=["metadatas", "documents"],
            )

            if not results or not results.get("metadatas"):
                return {
                    "one_rms": {},
                    "global_intensity_percent": None,
                    "progression_pace": None,
                    "training_split": None,
                    "workout_type": None,
                    "exercise_consistency": None,
                    "variation_percentage": None,
                    "context_text": "",
                    "has_settings": False,
                }

            # Filter by recency and sort by timestamp (most recent first)
            cutoff_date = datetime.now() - timedelta(days=days_lookback)
            cutoff_str = cutoff_date.isoformat()

            # Pair metadata with documents and filter by date
            valid_entries = []
            for i, metadata in enumerate(results["metadatas"]):
                timestamp = metadata.get("timestamp", "")
                if timestamp >= cutoff_str:
                    valid_entries.append({
                        "metadata": metadata,
                        "document": results["documents"][i] if results.get("documents") else "",
                        "timestamp": timestamp,
                    })

            # Sort by timestamp descending (most recent first)
            valid_entries.sort(key=lambda x: x["timestamp"], reverse=True)

            # Consolidate settings - most recent value wins
            consolidated = {
                "one_rms": {},
                "global_intensity_percent": None,
                "progression_pace": None,
                "training_split": None,
                "workout_type": None,
                "exercise_consistency": None,
                "variation_percentage": None,
            }

            # Track which settings we've already set (most recent wins)
            set_fields = set()

            for entry in valid_entries[:max_results]:
                meta = entry["metadata"]

                # Global intensity
                if "global_intensity_percent" not in set_fields and meta.get("global_intensity_percent"):
                    consolidated["global_intensity_percent"] = meta["global_intensity_percent"]
                    set_fields.add("global_intensity_percent")

                # Progression pace
                if "progression_pace" not in set_fields and meta.get("progression_pace"):
                    consolidated["progression_pace"] = meta["progression_pace"]
                    set_fields.add("progression_pace")

                # Training split
                if "training_split" not in set_fields and meta.get("training_split"):
                    consolidated["training_split"] = meta["training_split"]
                    set_fields.add("training_split")

                # Workout type
                if "workout_type" not in set_fields and meta.get("workout_type"):
                    consolidated["workout_type"] = meta["workout_type"]
                    set_fields.add("workout_type")

                # Exercise consistency
                if "exercise_consistency" not in set_fields and meta.get("exercise_consistency"):
                    consolidated["exercise_consistency"] = meta["exercise_consistency"]
                    set_fields.add("exercise_consistency")

                # Variation percentage
                if "variation_percentage" not in set_fields and meta.get("variation_percentage") is not None:
                    consolidated["variation_percentage"] = meta["variation_percentage"]
                    set_fields.add("variation_percentage")

                # 1RMs - merge all, most recent overwrites older for same exercise
                if meta.get("one_rms"):
                    rm_pairs = meta["one_rms"].split(",")
                    for pair in rm_pairs:
                        if ":" in pair:
                            exercise, weight = pair.rsplit(":", 1)
                            exercise = exercise.strip().lower()
                            if exercise not in consolidated["one_rms"]:
                                # Parse weight (remove 'kg' suffix)
                                try:
                                    weight_val = float(weight.replace("kg", "").strip())
                                    consolidated["one_rms"][exercise] = weight_val
                                except ValueError:
                                    pass

            # Build context text for AI
            context_parts = []
            if consolidated["one_rms"]:
                rm_text = ", ".join([f"{ex}: {w}kg" for ex, w in consolidated["one_rms"].items()])
                context_parts.append(f"User's 1RM Records: {rm_text}")

            if consolidated["global_intensity_percent"]:
                intensity_desc = self._get_intensity_description(consolidated["global_intensity_percent"])
                context_parts.append(f"Training Intensity: {consolidated['global_intensity_percent']}% ({intensity_desc})")

            if consolidated["progression_pace"]:
                context_parts.append(f"Progression Pace: {consolidated['progression_pace']}")

            if consolidated["training_split"]:
                context_parts.append(f"Training Split: {consolidated['training_split']}")

            if consolidated["workout_type"]:
                context_parts.append(f"Workout Type: {consolidated['workout_type']}")

            if consolidated["exercise_consistency"]:
                consistency_desc = "same exercises each week" if consolidated["exercise_consistency"] == "consistent" else "varied exercises"
                context_parts.append(f"Exercise Consistency: {consolidated['exercise_consistency']} ({consistency_desc})")

            if consolidated["variation_percentage"] is not None:
                context_parts.append(f"Weekly Variety: {consolidated['variation_percentage']}% exercises rotate")

            consolidated["context_text"] = "\n".join(context_parts)
            consolidated["has_settings"] = bool(context_parts)

            print(f"📊 Retrieved training settings for user {user_id}: {len(valid_entries)} recent entries")
            return consolidated

        except Exception as e:
            print(f"❌ Failed to retrieve training settings: {e}")
            return {
                "one_rms": {},
                "global_intensity_percent": None,
                "progression_pace": None,
                "training_split": None,
                "workout_type": None,
                "exercise_consistency": None,
                "variation_percentage": None,
                "context_text": "",
                "has_settings": False,
            }

    def _get_intensity_description(self, percent: int) -> str:
        """Get human-readable description for intensity percentage."""
        if percent <= 60:
            return "Light/Recovery"
        elif percent <= 70:
            return "Moderate/Endurance"
        elif percent <= 80:
            return "Working Weight/Hypertrophy"
        elif percent <= 90:
            return "Heavy/Strength"
        else:
            return "Near Max/Peaking"

    def get_stats(self) -> Dict[str, Any]:
        """Get workout RAG statistics."""
        return {
            "total_workouts": self.workout_collection.count(),
            "total_changes": self.changes_collection.count(),
            "storage": "chroma_cloud",
        }


class NutritionRAGService:
    """
    RAG service for nutrition and food log history.

    This allows the AI coach to:
    1. Recall past meals and nutrition data
    2. Track eating patterns over time
    3. Provide personalized nutrition advice based on food history
    """

    def __init__(self, gemini_service: GeminiService):
        self.gemini_service = gemini_service

        # Get Chroma Cloud client
        self.chroma_client = get_chroma_cloud_client()

        # Collection for food logs
        self.food_collection = self.chroma_client.get_or_create_collection(
            "food_logs"
        )

        print(f"✅ Nutrition RAG initialized: {self.food_collection.count()} food logs")

    async def index_food_log(
        self,
        food_log_id: str,
        user_id: str,
        meal_type: str,
        food_items: List[Dict[str, Any]],
        total_calories: int,
        protein_g: float,
        carbs_g: float,
        fat_g: float,
        health_score: int,
        ai_feedback: str,
        logged_at: str,
    ) -> str:
        """
        Index a food log for RAG retrieval.

        Args:
            food_log_id: Unique food log ID
            user_id: User ID
            meal_type: Type of meal (breakfast, lunch, dinner, snack)
            food_items: List of food items with nutrition data
            total_calories: Total calories
            protein_g: Total protein in grams
            carbs_g: Total carbs in grams
            fat_g: Total fat in grams
            health_score: Health score 1-10
            ai_feedback: AI feedback on the meal
            logged_at: When the meal was logged

        Returns:
            Document ID
        """
        doc_id = f"food_{food_log_id}"

        # Build food item summary
        food_names = [item.get("name", "Unknown") for item in food_items]
        food_summary = ", ".join(food_names[:5])
        if len(food_items) > 5:
            food_summary += f" and {len(food_items) - 5} more items"

        # Create searchable text
        food_text = (
            f"Meal: {meal_type}\n"
            f"Foods: {food_summary}\n"
            f"Calories: {total_calories} kcal\n"
            f"Protein: {protein_g}g, Carbs: {carbs_g}g, Fat: {fat_g}g\n"
            f"Health Score: {health_score}/10\n"
            f"Date: {logged_at}\n"
            f"Feedback: {ai_feedback}"
        )

        # Get embedding
        embedding = await self.gemini_service.get_embedding_async(food_text)

        # Upsert to collection (update if exists)
        try:
            self.food_collection.delete(ids=[doc_id])
        except Exception:
            pass  # Document might not exist

        self.food_collection.add(
            ids=[doc_id],
            embeddings=[embedding],
            documents=[food_text],
            metadatas=[{
                "food_log_id": food_log_id,
                "user_id": user_id,
                "meal_type": meal_type,
                "total_calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "health_score": health_score,
                "logged_at": logged_at,
                "food_count": len(food_items),
            }],
        )

        print(f"🍽️ Indexed food log: {meal_type} - {food_summary} (ID: {food_log_id})")
        return doc_id

    async def find_similar_meals(
        self,
        query: str,
        user_id: Optional[str] = None,
        n_results: int = 5,
        meal_type: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Find similar past meals.

        Args:
            query: Search query (e.g., "high protein breakfast", "healthy lunch")
            user_id: Optional filter by user
            n_results: Number of results
            meal_type: Optional filter by meal type

        Returns:
            List of similar meals
        """
        if self.food_collection.count() == 0:
            return []

        # Get query embedding
        query_embedding = await self.gemini_service.get_embedding_async(query)

        # Build where filter
        where_filter = {}
        if user_id is not None:
            where_filter["user_id"] = user_id
        if meal_type is not None:
            where_filter["meal_type"] = meal_type

        # Query
        results = self.food_collection.query(
            query_embeddings=[query_embedding],
            n_results=min(n_results, self.food_collection.count()),
            where=where_filter if where_filter else None,
            include=["documents", "metadatas", "distances"],
        )

        # Format results
        similar_meals = []
        for i, doc_id in enumerate(results["ids"][0]):
            distance = results["distances"][0][i]
            # Cosine distance: 0-2 range, convert to similarity 0-1
            similarity = 1 - (distance / 2)

            if similarity >= settings.rag_min_similarity:
                similar_meals.append({
                    "id": doc_id,
                    "document": results["documents"][0][i],
                    "metadata": results["metadatas"][0][i],
                    "similarity": similarity,
                })

        print(f"🔍 Found {len(similar_meals)} similar meals for: '{query[:50]}...'")
        return similar_meals

    async def get_user_nutrition_history(
        self,
        user_id: str,
        n_results: int = 10,
    ) -> List[Dict[str, Any]]:
        """
        Get a user's nutrition history.

        Args:
            user_id: User ID
            n_results: Number of results

        Returns:
            List of food logs
        """
        if self.food_collection.count() == 0:
            return []

        # Get all matching logs for user
        results = self.food_collection.get(
            where={"user_id": user_id},
            include=["documents", "metadatas"],
            limit=n_results,
        )

        logs = []
        for i, doc_id in enumerate(results["ids"]):
            logs.append({
                "id": doc_id,
                "document": results["documents"][i],
                "metadata": results["metadatas"][i],
            })

        return logs

    def format_nutrition_context(self, similar_meals: List[Dict[str, Any]]) -> str:
        """Format similar meals into context for AI."""
        if not similar_meals:
            return ""

        context_parts = ["RELEVANT PAST MEALS:"]

        for i, meal in enumerate(similar_meals[:3], 1):
            meta = meal["metadata"]
            context_parts.append(
                f"\n{i}. {meta['meal_type'].title()} ({meta['logged_at']})\n"
                f"   Calories: {meta['total_calories']} kcal\n"
                f"   Macros: P:{meta['protein_g']}g, C:{meta['carbs_g']}g, F:{meta['fat_g']}g\n"
                f"   Health Score: {meta['health_score']}/10\n"
                f"   (Similarity: {meal['similarity']:.2f})"
            )

        return "\n".join(context_parts)

    def get_stats(self) -> Dict[str, Any]:
        """Get nutrition RAG statistics."""
        return {
            "total_food_logs": self.food_collection.count(),
            "storage": "chroma_cloud",
        }
