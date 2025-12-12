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
from services.openai_service import OpenAIService

settings = get_settings()


class RAGService:
    """
    RAG service for storing and retrieving Q&A pairs.

    How it works:
    1. Every chat Q&A is stored with an embedding
    2. When a new question comes in, we find similar past questions
    3. The similar Q&As are used as context for the AI

    This makes responses more accurate over time!
    """

    def __init__(self, openai_service: OpenAIService):
        self.openai_service = openai_service

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

        # Get embedding from OpenAI
        embedding = await self.openai_service.get_embedding(combined_text)

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
        query_embedding = await self.openai_service.get_embedding(query)

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

    def __init__(self, openai_service: OpenAIService):
        self.openai_service = openai_service

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
        embedding = await self.openai_service.get_embedding(workout_text)

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
        embedding = await self.openai_service.get_embedding(change_text)

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
        query_embedding = await self.openai_service.get_embedding(query)

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

    def __init__(self, openai_service: OpenAIService):
        self.openai_service = openai_service

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
        embedding = await self.openai_service.get_embedding(food_text)

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
        query_embedding = await self.openai_service.get_embedding(query)

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
