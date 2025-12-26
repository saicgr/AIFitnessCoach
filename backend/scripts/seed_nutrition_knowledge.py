#!/usr/bin/env python3
"""
Seed the nutrition knowledge ChromaDB collection.

Run this script to populate the nutrition_knowledge collection with
goal-specific nutrition facts for RAG-enhanced food scoring.

Usage:
    python scripts/seed_nutrition_knowledge.py
"""
import asyncio
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.nutrition_rag_service import seed_nutrition_knowledge, get_nutrition_rag_service


async def main():
    print("🌱 Starting nutrition knowledge seeding...")

    # Check current state
    service = get_nutrition_rag_service()
    current_count = service.get_collection_count()
    print(f"📊 Current document count: {current_count}")

    if current_count > 0:
        print("⚠️ Collection already has documents.")
        response = input("Do you want to add more documents anyway? (y/N): ")
        if response.lower() != 'y':
            print("❌ Seeding cancelled.")
            return

    # Seed the collection
    await seed_nutrition_knowledge()

    # Verify
    final_count = service.get_collection_count()
    print(f"✅ Final document count: {final_count}")


if __name__ == "__main__":
    asyncio.run(main())
