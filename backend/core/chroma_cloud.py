"""
Chroma Cloud client for AI Fitness Coach.
Uses Chroma Cloud v2 API with CloudClient.
"""
import chromadb
from typing import List, Dict, Optional

from core.config import get_settings


class ChromaCloudClient:
    """Wrapper for Chroma Cloud v2 API client."""

    def __init__(self):
        settings = get_settings()

        # Initialize CloudClient for Chroma Cloud v2 API
        self.client = chromadb.CloudClient(
            tenant=settings.chroma_tenant,
            database=settings.chroma_database,
            api_key=settings.chroma_cloud_api_key,
        )
        print(f"✅ Connected to Chroma Cloud (tenant: {settings.chroma_tenant}, database: {settings.chroma_database})")

        # Collection names
        self.exercise_collection_name = "fitness_exercises"
        self.rag_collection_name = "fitness_rag_knowledge"
        self.workout_collection_name = "workout_plans"
        self.custom_inputs_collection_name = "custom_workout_inputs"

    def get_or_create_collection(self, collection_name: str):
        """Get or create a collection in Chroma Cloud."""
        try:
            collection = self.client.get_collection(name=collection_name)
            print(f"✅ Retrieved existing collection: {collection_name}")
            return collection
        except Exception:
            # Collection doesn't exist, create it
            collection = self.client.create_collection(
                name=collection_name,
                metadata={"hnsw:space": "cosine"}
            )
            print(f"✅ Created new collection: {collection_name}")
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


# Singleton instance
_chroma_cloud_client: Optional[ChromaCloudClient] = None


def get_chroma_cloud_client() -> ChromaCloudClient:
    """Get the global Chroma Cloud client instance."""
    global _chroma_cloud_client
    if _chroma_cloud_client is None:
        _chroma_cloud_client = ChromaCloudClient()
    return _chroma_cloud_client
