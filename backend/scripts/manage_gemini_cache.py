#!/usr/bin/env python3
"""
Gemini Cache Management Utility

Usage:
    python scripts/manage_gemini_cache.py list          # List all caches
    python scripts/manage_gemini_cache.py delete <name> # Delete specific cache
    python scripts/manage_gemini_cache.py delete-all    # Delete all workout caches
    python scripts/manage_gemini_cache.py refresh       # Force refresh (delete workout cache)
"""
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from google import genai
from core.config import get_settings


def get_client():
    settings = get_settings()
    return genai.Client(api_key=settings.gemini_api_key)


def list_caches():
    """List all Gemini caches for this API key."""
    client = get_client()
    print("\n📦 Gemini Caches:\n")

    caches = list(client.caches.list())
    if not caches:
        print("  No caches found.")
        return

    for cache in caches:
        print(f"  Name: {cache.name}")
        print(f"  Display Name: {cache.display_name}")
        print(f"  Model: {cache.model}")
        print(f"  Expire Time: {cache.expire_time}")
        print(f"  Create Time: {cache.create_time}")
        if hasattr(cache, 'usage_metadata') and cache.usage_metadata:
            print(f"  Cached Tokens: {cache.usage_metadata.total_token_count}")
        print("  ---")

    print(f"\nTotal: {len(caches)} cache(s)")


def delete_cache(name: str):
    """Delete a specific cache by name."""
    client = get_client()
    try:
        client.caches.delete(name=name)
        print(f"✅ Deleted cache: {name}")
    except Exception as e:
        print(f"❌ Failed to delete cache: {e}")


def delete_all_workout_caches():
    """Delete all workout generation caches."""
    client = get_client()
    deleted = 0

    for cache in client.caches.list():
        if cache.display_name and "workout" in cache.display_name.lower():
            try:
                client.caches.delete(name=cache.name)
                print(f"✅ Deleted: {cache.display_name} ({cache.name})")
                deleted += 1
            except Exception as e:
                print(f"❌ Failed to delete {cache.name}: {e}")

    if deleted == 0:
        print("No workout caches found to delete.")
    else:
        print(f"\n🗑️  Deleted {deleted} cache(s)")


def refresh_cache():
    """Force refresh by deleting the current workout cache."""
    delete_all_workout_caches()
    print("\n🔄 Next workout generation request will create a new cache.")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1].lower()

    if command == "list":
        list_caches()
    elif command == "delete":
        if len(sys.argv) < 3:
            print("Usage: python manage_gemini_cache.py delete <cache_name>")
            sys.exit(1)
        delete_cache(sys.argv[2])
    elif command == "delete-all":
        delete_all_workout_caches()
    elif command == "refresh":
        refresh_cache()
    else:
        print(f"Unknown command: {command}")
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
