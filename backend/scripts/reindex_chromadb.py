"""
Reindex ChromaDB with Gemini embeddings.

IMPORTANT: This script deletes existing collections and recreates them
with Gemini embeddings (768 dimensions) instead of OpenAI (1536 dimensions).

Usage:
    cd backend
    python scripts/reindex_chromadb.py
"""
import asyncio
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

from services.gemini_service import GeminiService
from services.exercise_rag_service import ExerciseRAGService
from core.chroma_cloud import get_chroma_cloud_client

async def main():
    print("=" * 60)
    print("🔄 CHROMADB REINDEX WITH GEMINI EMBEDDINGS")
    print("   (768 dimensions instead of OpenAI's 1536)")
    print("=" * 60)

    # Show current state
    chroma_client = get_chroma_cloud_client()
    print(f"\n📊 Current Collections: {chroma_client.list_collections()}")

    for name in ["fitness_exercises", "fitness_rag_knowledge", "workout_plans", "custom_workout_inputs", "exercise_library", "workout_performance_feedback", "workout_changes"]:
        count = chroma_client.get_collection_count(name)
        if count > 0:
            print(f"   • {name}: {count} documents")

    # Delete old collections with wrong dimensions (1536 dim -> 768 dim)
    print("\n🗑️  Deleting old collections with wrong dimensions (1536 dim -> 768 dim)...")
    for collection_name in ["exercise_library", "custom_workout_inputs", "workout_plans", "workout_performance_feedback", "workout_changes"]:
        try:
            chroma_client.delete_collection(collection_name)
            print(f"   ✅ Deleted {collection_name} collection")
        except Exception as e:
            print(f"   ⚠️  Could not delete {collection_name}: {e}")

    # Initialize services
    print("\n🤖 Initializing Gemini service...")
    gemini_service = GeminiService()

    # Reindex exercises - this will create new collection with 768 dims
    print("\n🏋️ Reindexing exercise library with Gemini embeddings...")
    exercise_rag = ExerciseRAGService(gemini_service)
    indexed_count = await exercise_rag.index_all_exercises()

    print(f"\n✅ Indexed {indexed_count} exercises with Gemini embeddings!")

    # Show new state
    print("\n📊 Final state:")
    for name in ["fitness_exercises", "fitness_rag_knowledge", "workout_plans", "custom_workout_inputs", "exercise_library", "workout_performance_feedback", "workout_changes"]:
        count = chroma_client.get_collection_count(name)
        if count > 0:
            print(f"   • {name}: {count} documents")

    print("\n" + "=" * 60)
    print("✅ REINDEX COMPLETE!")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
