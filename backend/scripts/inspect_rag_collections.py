#!/usr/bin/env python3
"""
Inspect the new per-user RAG collections populated by the workout-import pipeline.

Usage:
  python -m scripts.inspect_rag_collections --collection user_exercise_history --user-id <uuid> [--top 10] [--query "..."]
  python -m scripts.inspect_rag_collections --collection user_cardio_history --user-id <uuid> --top 5

Without --query it dumps the first N docs for the user. With --query it runs
a semantic lookup and prints the top-N matches with similarity scores.
"""
from __future__ import annotations

import argparse
import json
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--collection", required=True,
        choices=["user_exercise_history", "user_cardio_history"],
        help="Which RAG collection to inspect",
    )
    parser.add_argument("--user-id", required=True, help="UUID of the user to filter by")
    parser.add_argument("--top", type=int, default=10, help="How many docs to print (default 10)")
    parser.add_argument("--query", help="Optional natural-language query for semantic search")
    args = parser.parse_args()

    from core.chroma_cloud import get_chroma_cloud_client

    chroma = get_chroma_cloud_client()
    if args.collection == "user_exercise_history":
        collection = chroma.get_user_exercise_history_collection()
    else:
        collection = chroma.get_user_cardio_history_collection()

    where = {"user_id": args.user_id}

    if args.query:
        print(f"\n── Semantic query: {args.query!r} (user={args.user_id}) ──")
        try:
            results = collection.query(
                query_texts=[args.query],
                n_results=args.top,
                where=where,
            )
        except Exception as e:
            print(f"error: query failed: {e}", file=sys.stderr)
            sys.exit(2)

        ids = (results.get("ids") or [[]])[0]
        docs = (results.get("documents") or [[]])[0]
        metas = (results.get("metadatas") or [[]])[0]
        distances = (results.get("distances") or [[]])[0]

        if not ids:
            print("  (no matches)")
            return

        for i, (did, doc, meta, dist) in enumerate(zip(ids, docs, metas, distances), 1):
            similarity = 1.0 - float(dist) if dist is not None else None
            sim_str = f"{similarity:.3f}" if similarity is not None else "--"
            print(f"\n  [{i}] sim={sim_str}  id={did[:16]}…")
            print(f"      doc:  {doc}")
            print(f"      meta: {json.dumps(meta, default=str)}")
        return

    # No query → dump first N.
    print(f"\n── First {args.top} docs for user={args.user_id} in {args.collection} ──")
    try:
        data = collection.get(where=where, limit=args.top)
    except Exception as e:
        print(f"error: get failed: {e}", file=sys.stderr)
        sys.exit(2)

    ids = data.get("ids") or []
    docs = data.get("documents") or []
    metas = data.get("metadatas") or []
    if not ids:
        print("  (no docs — user has no imported history yet)")
        return

    for i, (did, doc, meta) in enumerate(zip(ids, docs, metas), 1):
        print(f"\n  [{i}] id={did[:16]}…")
        print(f"      doc:  {doc}")
        print(f"      meta: {json.dumps(meta, default=str)}")

    print(f"\n  Total docs in collection: {collection.count()}")


if __name__ == "__main__":
    main()
