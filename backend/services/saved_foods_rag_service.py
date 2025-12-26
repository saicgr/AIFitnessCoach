"""
Saved Foods RAG Service - Vector search for favorite recipes.

This service stores saved food embeddings in ChromaDB for:
- Semantic search ("find similar meals")
- Quick retrieval of frequently used meals
- Personalized meal suggestions
"""

from typing import List, Dict, Any, Optional
from core.chroma_cloud import get_chroma_cloud_client
from services.gemini_service import GeminiService


SAVED_FOODS_COLLECTION_NAME = "saved_foods"


class SavedFoodsRAGService:
    """
    RAG service for saved foods / favorite recipes.

    Stores meal embeddings and enables semantic search.
    """

    def __init__(self, gemini_service: Optional[GeminiService] = None):
        self.gemini_service = gemini_service or GeminiService()
        self.chroma_client = get_chroma_cloud_client()
        self.collection = self.chroma_client.get_saved_foods_collection()
        print(f"SavedFoodsRAG initialized with {self.collection.count()} documents")

    async def save_food(
        self,
        saved_food_id: str,
        user_id: str,
        name: str,
        description: Optional[str],
        food_items: List[Dict[str, Any]],
        total_calories: Optional[int] = None,
        total_protein_g: Optional[float] = None,
        source_type: str = "text",
        tags: Optional[List[str]] = None,
    ) -> str:
        """
        Save a food to ChromaDB for semantic search.

        Args:
            saved_food_id: UUID of the saved food in database
            user_id: User's UUID
            name: Meal name
            description: Meal description
            food_items: List of food items with nutrition
            total_calories: Total calories
            total_protein_g: Total protein
            source_type: text, barcode, or image
            tags: Optional tags

        Returns:
            Document ID (same as saved_food_id)
        """
        # Build searchable document text
        food_items_text = ", ".join([
            f"{item.get('name', 'Unknown')} ({item.get('calories', 0)} cal)"
            for item in food_items
        ])

        document = f"{name}: {description or ''} - {food_items_text}"

        # Get embedding from Gemini
        embedding = await self.gemini_service.get_embedding_async(document)

        # Store in ChromaDB
        self.collection.add(
            ids=[saved_food_id],
            embeddings=[embedding],
            documents=[document],
            metadatas=[{
                "user_id": user_id,
                "name": name,
                "total_calories": total_calories or 0,
                "total_protein_g": total_protein_g or 0,
                "source_type": source_type,
                "tags": ",".join(tags) if tags else "",
            }],
        )

        print(f"Saved food to ChromaDB: {saved_food_id[:8]}... (total: {self.collection.count()})")
        return saved_food_id

    async def search_similar(
        self,
        query: str,
        user_id: str,
        n_results: int = 5,
        min_calories: Optional[int] = None,
        max_calories: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Search for similar saved foods.

        Args:
            query: Search query (e.g., "healthy breakfast", "high protein")
            user_id: User's UUID (filter to only their saved foods)
            n_results: Number of results to return
            min_calories: Minimum calories filter
            max_calories: Maximum calories filter

        Returns:
            List of similar foods with metadata
        """
        # Get embedding for query
        query_embedding = await self.gemini_service.get_embedding_async(query)

        # Build where filter for user
        where_filter = {"user_id": user_id}

        # Query ChromaDB
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=n_results * 2,  # Get more to filter by calories
            where=where_filter,
            include=["documents", "metadatas", "distances"]
        )

        if not results or not results.get("ids") or not results["ids"][0]:
            return []

        # Process and filter results
        similar_foods = []
        for i, doc_id in enumerate(results["ids"][0]):
            metadata = results["metadatas"][0][i] if results.get("metadatas") else {}
            calories = metadata.get("total_calories", 0)

            # Apply calorie filters
            if min_calories and calories < min_calories:
                continue
            if max_calories and calories > max_calories:
                continue

            similar_foods.append({
                "id": doc_id,
                "name": metadata.get("name", ""),
                "total_calories": calories,
                "total_protein_g": metadata.get("total_protein_g", 0),
                "source_type": metadata.get("source_type", "text"),
                "tags": metadata.get("tags", "").split(",") if metadata.get("tags") else [],
                "distance": results["distances"][0][i] if results.get("distances") else 0,
                "document": results["documents"][0][i] if results.get("documents") else "",
            })

        # Sort by distance (lower = more similar)
        similar_foods.sort(key=lambda x: x["distance"])

        return similar_foods[:n_results]

    async def delete_food(self, saved_food_id: str) -> bool:
        """
        Delete a saved food from ChromaDB.

        Args:
            saved_food_id: UUID of the saved food

        Returns:
            True if deleted, False if not found
        """
        try:
            self.collection.delete(ids=[saved_food_id])
            print(f"Deleted saved food from ChromaDB: {saved_food_id[:8]}...")
            return True
        except Exception as e:
            print(f"Failed to delete saved food from ChromaDB: {e}")
            return False

    async def update_food(
        self,
        saved_food_id: str,
        user_id: str,
        name: str,
        description: Optional[str],
        food_items: List[Dict[str, Any]],
        total_calories: Optional[int] = None,
        total_protein_g: Optional[float] = None,
        source_type: str = "text",
        tags: Optional[List[str]] = None,
    ) -> str:
        """
        Update a saved food in ChromaDB.

        Args:
            Same as save_food()

        Returns:
            Document ID
        """
        # Delete old entry
        await self.delete_food(saved_food_id)

        # Add new entry
        return await self.save_food(
            saved_food_id=saved_food_id,
            user_id=user_id,
            name=name,
            description=description,
            food_items=food_items,
            total_calories=total_calories,
            total_protein_g=total_protein_g,
            source_type=source_type,
            tags=tags,
        )

    def get_collection_count(self) -> int:
        """Get the number of documents in the saved foods collection."""
        return self.collection.count()

    def get_user_food_count(self, user_id: str) -> int:
        """Get the number of saved foods for a specific user."""
        try:
            results = self.collection.get(
                where={"user_id": user_id},
                include=[]
            )
            return len(results.get("ids", []))
        except Exception:
            return 0


# Singleton instance
_saved_foods_rag_service: Optional[SavedFoodsRAGService] = None


def get_saved_foods_rag_service() -> SavedFoodsRAGService:
    """Get the global SavedFoodsRAGService instance."""
    global _saved_foods_rag_service
    if _saved_foods_rag_service is None:
        _saved_foods_rag_service = SavedFoodsRAGService()
    return _saved_foods_rag_service
