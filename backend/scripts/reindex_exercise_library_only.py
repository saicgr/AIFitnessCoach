"""Narrow reindex: drop and rebuild only the `exercise_library` Chroma collection.

The full reindex_chromadb.py deletes ALL collections including
custom_exercise_library + nutrition_knowledge + fitness_rag_knowledge,
which is not what we want. This script touches only `exercise_library`,
which is safe to rebuild from `exercise_library_cleaned` matview.
"""
import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

from services.gemini_service import GeminiService
from services.exercise_rag_service import ExerciseRAGService
from core.chroma_cloud import get_chroma_cloud_client


COLLECTION = "exercise_library"


async def main() -> None:
    chroma_client = get_chroma_cloud_client()
    print(f"Existing collections: {chroma_client.list_collections()}")
    try:
        before = chroma_client.get_collection_count(COLLECTION)
        print(f"Current {COLLECTION} count: {before}")
    except Exception as e:
        print(f"Could not read current count: {e}")

    print(f"\nDeleting only `{COLLECTION}`...")
    try:
        chroma_client.delete_collection(COLLECTION)
        print("  deleted")
    except Exception as e:
        print(f"  delete skipped: {e}")

    gemini_service = GeminiService()

    # Workaround: module-level google-genai async client caches a dead event
    # loop, causing "Future attached to a different loop" when called from a
    # fresh asyncio.run(). Route the batch call through the sync API instead.
    async def _sync_backed_batch(texts):
        return gemini_service.get_embeddings_batch(texts)
    gemini_service.get_embeddings_batch_async = _sync_backed_batch

    exercise_rag = ExerciseRAGService(gemini_service)

    print("\nReindexing from exercise_library_cleaned...")
    indexed = await exercise_rag.index_all_exercises()
    print(f"\nIndexed {indexed} exercises.")

    after = chroma_client.get_collection_count(COLLECTION)
    print(f"Final {COLLECTION} count: {after}")


if __name__ == "__main__":
    asyncio.run(main())
