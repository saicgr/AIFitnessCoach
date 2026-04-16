#!/usr/bin/env python
"""
Verify that a user's custom exercises are indexed into the
`custom_exercise_library` ChromaDB collection and queryable.

Usage:
    python scripts/check_custom_rag.py <user_id> <query>

Example:
    python scripts/check_custom_rag.py 123e4567-e89b-12d3-a456-426614174000 "cable row"

Prints:
    - Total count of custom-exercise entries for that user_id (raw count)
    - Top 5 results from `query_custom_collection` with metadata + distance
"""
from __future__ import annotations

import asyncio
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

try:
    from dotenv import load_dotenv
    load_dotenv(REPO_ROOT / ".env")
except Exception:
    pass


async def main(user_id: str, query: str) -> int:
    from services.exercise_rag.service import get_exercise_rag_service

    rag = get_exercise_rag_service()

    # 1) Raw count for this user_id in the custom collection.
    try:
        total_in_coll = rag.custom_collection.count()
    except Exception as e:
        print(f"❌ Failed to read custom_exercise_library count: {e}")
        return 1

    # Metadata-filtered count (user's own + public visible to them).
    try:
        user_rows = rag.custom_collection.get(
            where={"user_id": user_id},
            include=["metadatas"],
        )
        user_count = len(user_rows.get("ids") or [])
    except Exception as e:
        print(f"⚠️  Failed to fetch per-user rows: {e}")
        user_count = 0

    print(f"🔍 custom_exercise_library total rows: {total_in_coll}")
    print(f"🔍 rows owned by user_id={user_id}: {user_count}")

    if user_count == 0:
        print(
            "⚠️  No custom exercises indexed for this user. Import one via "
            "POST /custom-exercises/{user_id}/import first, then rerun."
        )

    # 2) Run a real query.
    print(f"\n🔍 Querying collection for: {query!r}")

    try:
        query_embedding = await rag.gemini_service.get_embedding_async(query)
    except Exception as e:
        print(f"❌ Failed to embed query: {e}")
        return 2

    if not query_embedding:
        print("❌ Empty embedding returned — check GEMINI_API_KEY.")
        return 2

    result = rag.query_custom_collection(
        query_embedding=query_embedding,
        user_id=user_id,
        n_results=5,
    )

    ids = (result.get("ids") or [[]])[0]
    metadatas = (result.get("metadatas") or [[]])[0]
    distances = (result.get("distances") or [[]])[0]
    documents = (result.get("documents") or [[]])[0]

    if not ids:
        print("    (no results)")
        return 0

    print(f"    Top {len(ids)} results:")
    for i, (_id, meta, dist, doc) in enumerate(zip(ids, metadatas, distances, documents), 1):
        name = (meta or {}).get("name", "?")
        owner = (meta or {}).get("user_id", "?")
        is_pub = (meta or {}).get("is_public")
        preview = (doc or "").replace("\n", " ")[:80]
        print(f"      {i}. {name!r:<35} dist={dist:.4f}  owner={owner}  public={is_pub}")
        print(f"         \"{preview}...\"")

    return 0


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    code = asyncio.run(main(sys.argv[1], sys.argv[2]))
    sys.exit(code)
