"""
Chroma Cloud client for FitWiz.
Uses a thin HTTP client against Chroma Cloud REST API v2.
"""
from typing import List, Dict, Optional

from core.chroma_http_client import ChromaHTTPClient
from core.config import get_settings


class ChromaCloudClient:
    """Wrapper for Chroma Cloud v2 API client."""

    def __init__(self):
        settings = get_settings()

        # Initialize lightweight HTTP client for Chroma Cloud v2 API
        self.client = ChromaHTTPClient(
            tenant=settings.chroma_tenant,
            database=settings.chroma_database,
            api_key=settings.chroma_cloud_api_key,
            host=settings.chroma_cloud_host,
        )
        print(f"✅ Connected to Chroma Cloud (tenant: {settings.chroma_tenant}, database: {settings.chroma_database})")

        # Collection names
        self.exercise_collection_name = "fitness_exercises"
        self.rag_collection_name = "fitness_rag_knowledge"
        self.workout_collection_name = "workout_plans"
        self.custom_inputs_collection_name = "custom_workout_inputs"
        self.saved_foods_collection_name = "saved_foods"

    def get_or_create_collection(self, collection_name: str):
        """Get or create a collection in Chroma Cloud."""
        collection = self.client.get_or_create_collection(
            name=collection_name,
            metadata={"hnsw:space": "cosine"}
        )
        print(f"✅ Got or created collection: {collection_name}")
        return collection

    def get_exercise_collection(self):
        """Get the exercise collection."""
        return self.get_or_create_collection(self.exercise_collection_name)

    def get_rag_collection(self):
        """Get the RAG knowledge collection."""
        return self.get_or_create_collection(self.rag_collection_name)

    def get_workout_collection(self):
        """Get the workout plans collection."""
        return self.get_or_create_collection(self.workout_collection_name)

    def get_custom_inputs_collection(self):
        """Get the custom workout inputs collection (focus areas, injuries)."""
        return self.get_or_create_collection(self.custom_inputs_collection_name)

    def get_saved_foods_collection(self):
        """Get the saved foods collection (favorite recipes)."""
        return self.get_or_create_collection(self.saved_foods_collection_name)

    def add_documents(
        self,
        collection_name: str,
        documents: List[str],
        metadatas: List[Dict],
        ids: List[str],
        embeddings: Optional[List[List[float]]] = None
    ):
        """Add documents to a collection."""
        collection = self.get_or_create_collection(collection_name)

        if embeddings:
            collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids,
                embeddings=embeddings
            )
        else:
            # Let Chroma generate embeddings
            collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids
            )

        print(f"✅ Added {len(documents)} documents to {collection_name}")

    def query_collection(
        self,
        collection_name: str,
        query_texts: Optional[List[str]] = None,
        query_embeddings: Optional[List[List[float]]] = None,
        n_results: int = 5,
        where: Optional[Dict] = None
    ):
        """Query a collection for similar documents."""
        collection = self.get_or_create_collection(collection_name)

        if query_embeddings:
            results = collection.query(
                query_embeddings=query_embeddings,
                n_results=n_results,
                where=where
            )
        elif query_texts:
            results = collection.query(
                query_texts=query_texts,
                n_results=n_results,
                where=where
            )
        else:
            raise ValueError("Must provide either query_texts or query_embeddings")

        return results

    def delete_collection(self, collection_name: str):
        """Delete a collection."""
        try:
            self.client.delete_collection(name=collection_name)
            print(f"✅ Deleted collection: {collection_name}")
        except Exception as e:
            print(f"❌ Failed to delete collection {collection_name}: {e}")

    def list_collections(self):
        """List all collections."""
        collections = self.client.list_collections()
        return [col.name for col in collections]

    def get_collection_count(self, collection_name: str) -> int:
        """Get the number of documents in a collection."""
        try:
            collection = self.get_or_create_collection(collection_name)
            return collection.count()
        except Exception:
            return 0

    def get_collection_embedding_dimension(self, collection_name: str) -> Optional[int]:
        """
        Get the embedding dimension of a collection by sampling one document.
        Returns None if collection is empty or doesn't exist.
        """
        try:
            collection = self.client.get_collection(name=collection_name)
            if collection.count() == 0:
                return None

            # Sample one document to get embedding dimension
            result = collection.get(
                limit=1,
                include=["embeddings"]
            )

            if result and result.get("embeddings") and len(result["embeddings"]) > 0:
                return len(result["embeddings"][0])
            return None
        except Exception:
            return None

    def check_embedding_dimensions(self, expected_dim: int = 768) -> Dict[str, any]:
        """
        Check all collections for embedding dimension mismatches.

        Args:
            expected_dim: Expected embedding dimension (768 for Gemini text-embedding-004)

        Returns:
            Dict with 'healthy' bool and 'mismatches' list of problematic collections
        """
        mismatches = []
        collections_checked = []

        for collection_name in self.list_collections():
            dim = self.get_collection_embedding_dimension(collection_name)
            if dim is not None:
                collections_checked.append({
                    "name": collection_name,
                    "dimension": dim,
                    "matches": dim == expected_dim
                })
                if dim != expected_dim:
                    mismatches.append({
                        "name": collection_name,
                        "actual_dim": dim,
                        "expected_dim": expected_dim
                    })

        return {
            "healthy": len(mismatches) == 0,
            "expected_dimension": expected_dim,
            "collections_checked": collections_checked,
            "mismatches": mismatches
        }


# Singleton instance
_chroma_cloud_client: Optional[ChromaCloudClient] = None


def get_chroma_cloud_client() -> ChromaCloudClient:
    """Get the global Chroma Cloud client instance."""
    global _chroma_cloud_client
    if _chroma_cloud_client is None:
        _chroma_cloud_client = ChromaCloudClient()
    return _chroma_cloud_client
