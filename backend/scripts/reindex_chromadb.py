"""
Reindex ChromaDB with Gemini embeddings and CLEANED exercise names.

IMPORTANT: This script deletes existing collections and recreates them
with Gemini embeddings (768 dimensions) instead of OpenAI (1536 dimensions).

Dynamically discovers all collections from ChromaDB — no hardcoded list to go stale.

Uses exercise_library_cleaned view which:
- Removes "_Male" and "_Female" suffixes from names
- Removes "360 degrees" metadata noise
- Deduplicates exercises (keeps female version when both exist)
- Ensures clean, searchable names like "Bench Press" instead of "Bench Press_Male"

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
    print("CHROMADB REINDEX WITH GEMINI EMBEDDINGS")
    print("   (768 dimensions)")
    print("=" * 60)

    chroma_client = get_chroma_cloud_client()

    # Dynamically discover all collections instead of hardcoding
    all_collections = chroma_client.list_collections()
    print(f"\nFound {len(all_collections)} collections: {all_collections}")

    # Check dimensions and show current state
    dim_check = chroma_client.check_embedding_dimensions(expected_dim=768)
    for col in dim_check["collections_checked"]:
        status = "OK" if col["matches"] else f"MISMATCH ({col['dimension']} dims)"
        print(f"   - {col['name']}: {status}")

    if dim_check["healthy"]:
        print("\nAll collections have correct dimensions (768).")
        confirm = input("Reindex anyway? Type 'yes' to continue: ")
    else:
        mismatched = [m["name"] for m in dim_check["mismatches"]]
        print(f"\nMismatched collections: {mismatched}")
        print("\nWARNING: This will delete ALL collections and their embeddings!")
        print("   User data in Supabase is safe - only vector embeddings are deleted.")
        print("   Collections will be recreated with 768-dim Gemini embeddings.")
        confirm = input("\n   Type 'yes' to continue: ")

    if confirm.lower() != 'yes':
        print("\nAborted.")
        return

    # Delete all collections
    print("\nDeleting collections...")
    for collection_name in all_collections:
        try:
            chroma_client.delete_collection(collection_name)
            print(f"   Deleted {collection_name}")
        except Exception as e:
            print(f"   Could not delete {collection_name}: {e}")

    # Initialize services
    print("\nInitializing Gemini service...")
    gemini_service = GeminiService()

    # Reindex exercises - this will create new collection with 768 dims
    print("\nReindexing exercise library with Gemini embeddings...")
    print("   Using exercise_library_cleaned view (cleaned names, no duplicates)")
    exercise_rag = ExerciseRAGService(gemini_service)
    indexed_count = await exercise_rag.index_all_exercises()

    print(f"\nIndexed {indexed_count} exercises with Gemini embeddings!")

    # Show new state
    print("\nFinal state:")
    for name in chroma_client.list_collections():
        count = chroma_client.get_collection_count(name)
        print(f"   - {name}: {count} documents")

    print("\n" + "=" * 60)
    print("REINDEX COMPLETE!")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(main())
