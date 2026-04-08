"""Helper functions extracted from rag_service.
RAG (Retrieval Augmented Generation) Service.

This service stores Q&A pairs and retrieves similar past conversations
to provide better context to the AI.

Uses Chroma Cloud (cloud-hosted vector database) for all deployments.

Performance: In-memory caching layer for embedding generation and
ChromaDB queries to avoid redundant network calls (500ms-2s each).


"""
import time
from typing import Any, Dict, List, Optional
from core.config import get_settings
from core.chroma_cloud import get_chroma_cloud_client
from core.logger import get_logger
from services.gemini_service import GeminiService

settings = get_settings()
_rag_logger = get_logger(__name__)


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

        try:
            _count = self.food_collection.count()
        except Exception as e:
            _rag_logger.warning(f"Failed to get food log count: {e}")
            _count = "unknown"
        _rag_logger.info(f"Nutrition RAG initialized: {_count} food logs")

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
        except Exception as e:
            _rag_logger.debug(f"ChromaDB delete before upsert: {e}")

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

        _rag_logger.info(f"Indexed food log: {meal_type} - {food_summary} (ID: {food_log_id})")
        return doc_id

    async def _get_embedding_cached(self, text: str) -> List[float]:
        """Get embedding - delegates to gemini_service which has its own cache."""
        return await self.gemini_service.get_embedding_async(text)

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
        # Check query result cache (lazy import to avoid circular dependency)
        from services.rag_service import _query_cache
        query_cache_key = _query_cache.make_key("find_similar_meals", query, user_id, n_results, meal_type)
        cached_results = await _query_cache.get(query_cache_key)
        if cached_results is not None:
            _rag_logger.debug(f"Nutrition RAG cache HIT ({len(cached_results)} results) for: '{query[:40]}...'")
            return cached_results

        start = time.time()

        # Get query embedding (with embedding cache)
        query_embedding = await self._get_embedding_cached(query)

        # Build where filter
        where_filter = {}
        if user_id is not None:
            where_filter["user_id"] = user_id
        if meal_type is not None:
            where_filter["meal_type"] = meal_type

        # Query
        results = self.food_collection.query(
            query_embeddings=[query_embedding],
            n_results=n_results,
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

        elapsed_ms = int((time.time() - start) * 1000)
        _rag_logger.debug(f"Nutrition RAG cache MISS, found {len(similar_meals)} results in {elapsed_ms}ms")

        # Cache the results
        await _query_cache.set(query_cache_key, similar_meals)

        _rag_logger.info(f"Found {len(similar_meals)} similar meals for: '{query[:50]}...'")
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
        try:
            c = self.food_collection.count()
            total = c if c >= 0 else -1
        except Exception as e:
            _rag_logger.warning(f"Failed to get food log count: {e}")
            total = -1
        return {
            "total_food_logs": total,
            "storage": "chroma_cloud",
        }
