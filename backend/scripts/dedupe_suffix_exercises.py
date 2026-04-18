#!/usr/bin/env python3
"""Remove `(N)` import-duplicate rows from exercise_library_cleaned.

Finds rows whose ``name`` matches the pattern ``Foo(1)`` / ``Foo (2)`` /
``Foo (3)`` (12 such rows as of 2026-04-17) and, for each, verifies the
un-suffixed base row exists. When a base row is present the suffixed row is
safe to delete — it's a true duplicate from an older import pass.

Dry-run by default. Pass ``--apply`` to actually delete from Postgres and
the two ChromaDB collections that store exercise embeddings
(``exercise_library`` used by RAG-driven generation, ``fitness_exercises``
used by the library smart-search endpoint).

Usage:
    SUPABASE_DB_PASSWORD=... python scripts/dedupe_suffix_exercises.py           # dry run
    SUPABASE_DB_PASSWORD=... python scripts/dedupe_suffix_exercises.py --apply

The script also syncs ChromaDB using credentials from the app's usual env
(``CHROMA_*``). If ChromaDB is unreachable, the Postgres rows are still
deleted and missing-vector cleanups are logged.
"""

import argparse
import os
import re
import sys
from typing import List, Tuple

import psycopg2

# Allow importing app modules when run from backend/ root.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

SUFFIX_RE = re.compile(r"\s*\(\s*\d+\s*\)\s*$")

DB_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DB_NAME = "postgres"
DB_USER = "postgres"


def _connect_db() -> psycopg2.extensions.connection:
    password = os.environ.get("SUPABASE_DB_PASSWORD") or os.environ.get("DATABASE_PASSWORD")
    if not password:
        raise SystemExit("Set SUPABASE_DB_PASSWORD (or DATABASE_PASSWORD) in the environment.")
    return psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=password, port=5432)


def _find_candidates(conn) -> List[Tuple[str, str]]:
    """Return (id, name) tuples for suffixed rows whose base row exists."""
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT id, name
            FROM exercise_library_cleaned
            WHERE name ~ '\\(\\s*\\d+\\s*\\)\\s*$'
            ORDER BY name
            """
        )
        suffixed_rows = cur.fetchall()

        kept: List[Tuple[str, str]] = []
        orphaned: List[Tuple[str, str]] = []
        for ex_id, name in suffixed_rows:
            base = SUFFIX_RE.sub("", name).strip()
            if not base:
                orphaned.append((ex_id, name))
                continue
            cur.execute(
                "SELECT 1 FROM exercise_library_cleaned WHERE name = %s AND id <> %s LIMIT 1",
                (base, ex_id),
            )
            if cur.fetchone():
                kept.append((ex_id, name))
            else:
                orphaned.append((ex_id, name))

    if orphaned:
        print(f"⚠  Skipping {len(orphaned)} suffixed row(s) with no matching base:")
        for ex_id, name in orphaned:
            print(f"   - {name} (id={ex_id})")

    return kept


def _delete_from_chroma(ids: List[str]) -> None:
    try:
        from core.chroma_cloud import get_chroma_cloud_client
    except Exception as e:  # pragma: no cover
        print(f"⚠  Chroma client unavailable ({e}); skipping vector cleanup.")
        return

    try:
        client = get_chroma_cloud_client()
    except Exception as e:
        print(f"⚠  Failed to init Chroma client ({e}); skipping vector cleanup.")
        return

    for collection_name in ("exercise_library", "fitness_exercises"):
        try:
            collection = client.get_or_create_collection(collection_name)
            collection.delete(ids=ids)
            print(f"   ✓ Removed {len(ids)} id(s) from Chroma collection '{collection_name}'")
        except Exception as e:
            print(f"   ⚠ Failed to delete from '{collection_name}': {e}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Actually delete (default: dry-run)")
    args = parser.parse_args()

    conn = _connect_db()
    try:
        candidates = _find_candidates(conn)
    except Exception as e:
        print(f"❌ Query failed: {e}")
        conn.close()
        return 1

    if not candidates:
        print("✓ No suffixed duplicates to delete.")
        conn.close()
        return 0

    print(f"\nFound {len(candidates)} suffixed duplicate row(s) with a base-name match:")
    for ex_id, name in candidates:
        print(f"   - {name}  (id={ex_id})")

    if not args.apply:
        print("\nDry-run only. Re-run with --apply to delete these rows.")
        conn.close()
        return 0

    ids = [c[0] for c in candidates]
    with conn.cursor() as cur:
        cur.execute("DELETE FROM exercise_library_cleaned WHERE id = ANY(%s)", (ids,))
        deleted = cur.rowcount
    conn.commit()
    conn.close()
    print(f"\n✓ Deleted {deleted} row(s) from Postgres.")

    _delete_from_chroma(ids)
    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
