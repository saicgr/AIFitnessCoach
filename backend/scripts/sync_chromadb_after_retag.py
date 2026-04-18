#!/usr/bin/env python3
"""One-shot ChromaDB sync for the April 2026 library cleanup.

The SQL mutations (DELETE 12 "(N)" rows, UPDATE 10 "bodyweight → Pull-Up Bar"
rows) were applied directly via Supabase MCP, so the usual dedupe /retag
scripts won't find candidates in Postgres. This helper carries the hard-coded
ID lists and syncs ChromaDB accordingly.

Dry-run by default. ``--apply`` writes to Chroma.

Usage:
    python scripts/sync_chromadb_after_retag.py           # dry run
    python scripts/sync_chromadb_after_retag.py --apply
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))


# Deleted from exercise_library (2026-04-17). Vectors should be removed.
DELETED_IDS = [
    "6b426350-9bea-472e-96e4-b83640fcb951",  # Arm Circle(1)
    "853224b3-8b0a-4f93-9b58-e5708a897a35",  # Barbell Bench Press (2)
    "eed1a047-1db0-4db6-b492-493763f54f1b",  # Barbell Sumo Deadlift (2)
    "43d577aa-c4c8-459d-9db2-88dafb9792c7",  # Bird Dog (3)
    "0070c2aa-5f6b-4664-81bb-ed57e152879e",  # Burpee(1)
    "9cd493f9-c9a4-468b-907b-be991dc53bb3",  # Butt Kicks (2)
    "dbac7b3e-7da9-417b-996b-7660ed36aa5b",  # Calf Raise On Hack Squat Machine(1)
    "ae5813dd-684a-4c00-897c-659beaf51d21",  # Close Grip Barbell Bench Press (2)
    "ae0e8dcb-835d-4fff-b580-bebeeed3f7f5",  # In And Out Squats Jump Bodyweight (2)
    "cb7ee511-1323-4fcd-9a32-c68a1a38ddf4",  # Leg Press Machine Normal Stance (2)
    "2e5ec96c-5eed-4028-91b4-41f1c0f7095d",  # Leg Press Machine Normal Stance (3)
    "7ce3e4c5-dbf3-418d-85d6-10ca20535beb",  # Lunge Pulses Bodyweight(1)
]

# Retagged to "Pull-Up Bar" in exercise_library (2026-04-17).
# Vector metadata should reflect the new equipment.
RETAGGED_IDS = [
    "0bc45bbd-837e-410a-ae12-495a2428f130",  # Back Lever
    "75d455bf-41c4-4404-b8e4-3c275e37a5db",  # Back Lever_female
    "274cd9b5-7315-4710-b8b5-a7eb64877616",  # Front Lever Raise
    "cee50c51-294b-4b4f-9404-fe493c4bffe9",  # Front Lever Raise To Hold
    "e1d2952e-6aba-460d-b88d-21400c33a9cc",  # Front Lever Raise To Hold_Female
    "1212b0ad-e687-4f95-8d88-2aa7e3b6e4e3",  # Front Lever Raise_Female
    "5507d499-d514-45f2-b163-f0f0b6b8ad51",  # Hanging Knee Raises
    "d374e230-a315-4420-b5fa-8fce37246806",  # Hanging Oblique Crunches
    "4805f6b6-ec14-481d-9912-89b500374baa",  # Kipping Pull Up
    "89d00164-566c-4f89-b489-5b1be737535a",  # Kipping Pull Up_Female
]

NEW_EQUIPMENT = "Pull-Up Bar"
COLLECTIONS = ("exercise_library", "fitness_exercises")


def _sync(apply: bool) -> int:
    try:
        from core.chroma_cloud import get_chroma_cloud_client
    except Exception as e:
        print(f"❌ Failed to import Chroma client: {e}")
        return 1

    try:
        client = get_chroma_cloud_client()
    except Exception as e:
        print(f"❌ Failed to init Chroma client: {e}")
        return 1

    for collection_name in COLLECTIONS:
        print(f"\n[collection] {collection_name}")
        try:
            collection = client.get_or_create_collection(collection_name)
        except Exception as e:
            print(f"   ⚠ Failed to open: {e}")
            continue

        # ---- Deletes ----
        try:
            existing_deletes = collection.get(ids=DELETED_IDS, include=["metadatas"])
            found_delete_ids = existing_deletes.get("ids") or []
        except Exception as e:
            print(f"   ⚠ Failed to read delete candidates: {e}")
            found_delete_ids = []

        if found_delete_ids:
            print(f"   will delete {len(found_delete_ids)} vector(s)")
            if apply:
                try:
                    collection.delete(ids=found_delete_ids)
                    print(f"   ✓ Deleted {len(found_delete_ids)} vector(s)")
                except Exception as e:
                    print(f"   ⚠ Delete failed: {e}")
        else:
            print(f"   no matching delete vectors")

        # ---- Retag metadata ----
        try:
            existing_retags = collection.get(ids=RETAGGED_IDS, include=["metadatas"])
            found_retag_ids = existing_retags.get("ids") or []
            found_retag_metas = existing_retags.get("metadatas") or []
        except Exception as e:
            print(f"   ⚠ Failed to read retag candidates: {e}")
            found_retag_ids = []
            found_retag_metas = []

        if found_retag_ids:
            print(f"   will retag {len(found_retag_ids)} vector(s) → equipment='{NEW_EQUIPMENT}'")
            new_metas = []
            for meta in found_retag_metas:
                m = dict(meta or {})
                m["equipment"] = NEW_EQUIPMENT
                new_metas.append(m)
            if apply:
                try:
                    collection.update(ids=found_retag_ids, metadatas=new_metas)
                    print(f"   ✓ Updated metadata for {len(found_retag_ids)} vector(s)")
                except Exception as e:
                    print(f"   ⚠ Update failed: {e}")
        else:
            print(f"   no matching retag vectors")

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    if not args.apply:
        print("Dry-run mode. Re-run with --apply to write to Chroma.\n")
    return _sync(apply=args.apply)


if __name__ == "__main__":
    raise SystemExit(main())
