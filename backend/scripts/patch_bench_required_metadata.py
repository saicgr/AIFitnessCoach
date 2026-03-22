#!/usr/bin/env python3
"""
One-time script: adds bench_required="true"/"false" to all ChromaDB exercise metadata.
Fetches existing embeddings and re-upserts with enriched metadata.
Idempotent — safe to re-run.
"""
import sys
import os

# Add backend root to path so core/services imports work
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env'))

from core.config import get_settings
from core.chroma_cloud import get_chroma_cloud_client
from core.chroma_http_client import ChromaHTTPCollection

BENCH_PATTERNS = frozenset([
    "pullover",
    "bench press",
    "incline press",
    "decline press",
    "chest supported",
    "preacher",
])


def needs_bench(name: str) -> bool:
    """Determine if an exercise requires a flat/adjustable bench."""
    n = name.lower()
    # Cable, machine, floor, and ball exercises don't need a flat bench
    if "cable" in n or "machine" in n or "pulldown" in n:
        return False
    if "on floor" in n or "on exercise ball" in n or "floor press" in n:
        return False
    return any(p in n for p in BENCH_PATTERNS)


def main():
    client = get_chroma_cloud_client()

    # The exercises live in "exercise_library", not "fitness_exercises"
    http_client = client.client  # The underlying ChromaHTTPClient
    collection = http_client.get_or_create_collection(
        name="exercise_library",
        metadata={"hnsw:space": "cosine"},
    )

    bench_count = 0
    bench_exercises = []

    print("Starting bench_required metadata patch...")
    print(f"Collection: {collection.name} (id: {collection.id})")

    # Step 1: Fetch all IDs and metadatas in pages
    print("Fetching all exercises...")
    all_ids = []
    all_metadatas = []
    PAGE_SIZE = 200  # Chroma Cloud has a limit cap
    offset = 0

    while True:
        body = {"limit": PAGE_SIZE, "offset": offset, "include": ["metadatas"]}
        result = collection._post("get", body)

        page_ids = result.get("ids", [])
        page_metas = result.get("metadatas", [])

        if not page_ids:
            break

        all_ids.extend(page_ids)
        all_metadatas.extend(page_metas)
        print(f"  Fetched {len(all_ids)} exercises so far...")

        if len(page_ids) < PAGE_SIZE:
            break
        offset += PAGE_SIZE

    total = len(all_ids)
    print(f"Found {total} exercises total.")

    if total == 0:
        print("No exercises found. Exiting.")
        return

    # Step 2: Compute bench_required for each exercise
    enriched_metadatas = []
    for meta in all_metadatas:
        name = meta.get("name", "") or ""
        bench_req = "true" if needs_bench(name) else "false"
        new_meta = dict(meta)
        new_meta["bench_required"] = bench_req
        if bench_req == "true":
            bench_count += 1
            bench_exercises.append(name)
        enriched_metadatas.append(new_meta)

    # Step 3: Upsert in batches (delete + add with updated metadata)
    BATCH_SIZE = 50
    print(f"\nUpserting metadata in batches of {BATCH_SIZE}...")
    for i in range(0, total, BATCH_SIZE):
        batch_ids = all_ids[i:i + BATCH_SIZE]
        batch_metas = enriched_metadatas[i:i + BATCH_SIZE]

        # Fetch embeddings and documents for this batch
        batch_result = collection._post("get", {
            "ids": batch_ids,
            "include": ["embeddings", "documents"],
        })
        batch_embeddings = batch_result.get("embeddings", [])
        batch_documents = batch_result.get("documents", [])

        # Delete then re-add (simulates upsert)
        try:
            collection.delete(ids=batch_ids)
        except Exception:
            pass

        add_kwargs = {
            "ids": batch_ids,
            "metadatas": batch_metas,
        }
        if batch_documents:
            add_kwargs["documents"] = batch_documents
        if batch_embeddings:
            add_kwargs["embeddings"] = batch_embeddings

        collection.add(**add_kwargs)
        print(f"  Processed {min(i + BATCH_SIZE, total)}/{total} exercises...")

    print(f"\nDone! Processed {total} exercises total.")
    print(f"  bench_required=true: {bench_count}")
    print(f"  bench_required=false: {total - bench_count}")

    if bench_exercises:
        print(f"\nExercises marked bench_required=true:")
        for name in sorted(bench_exercises):
            print(f"  - {name}")


if __name__ == "__main__":
    main()
