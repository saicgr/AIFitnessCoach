#!/usr/bin/env python3
"""Re-tag mis-labeled exercises that physically require a pull-up bar but
are stored as bodyweight in ``exercise_library_cleaned``.

These are catches for exercises like ``Hanging Toes-to-Bar`` or
``Tuck Front Lever Holds`` — the names make the equipment obvious, but the
data was imported with ``equipment = 'Bodyweight'``. Bodyweight-only users
therefore receive workouts they can't perform.

Dry-run by default; ``--apply`` updates Postgres **and** upserts the
metadata in the two ChromaDB collections that back workout generation and
smart-search so RAG candidate filtering picks up the new tag.

Heuristic: any row whose name matches pull-up-bar tokens AND is currently
tagged bodyweight or NULL. The script prints every candidate before doing
anything — review the list and re-run with ``--apply``.
"""

import argparse
import os
import sys
from typing import List, Tuple

import psycopg2

# Allow importing app modules when run from backend/ root.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

DB_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DB_NAME = "postgres"
DB_USER = "postgres"

# ``~*`` = case-insensitive regex. The pattern matches both hyphen and space
# variants, and explicitly excludes "assisted pull" which is a machine.
PULLUP_BAR_PATTERN = (
    r"(pull[-\s]?up|chin[-\s]?up|muscle[-\s]?up|hanging|toes[-\s]?to[-\s]?bar|"
    r"knees[-\s]?to[-\s]?elbow|front lever|back lever|tuck lever|skin the cat|"
    r"bar hang|dead hang)"
)
EXCLUDE_PATTERN = r"(^\s*assisted\b|\bassisted\b|dumbbell|barbell|machine|cable)"

NEW_EQUIPMENT = "Pull-Up Bar"


def _connect_db() -> psycopg2.extensions.connection:
    password = os.environ.get("SUPABASE_DB_PASSWORD") or os.environ.get("DATABASE_PASSWORD")
    if not password:
        raise SystemExit("Set SUPABASE_DB_PASSWORD (or DATABASE_PASSWORD) in the environment.")
    return psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=password, port=5432)


def _find_candidates(conn) -> List[Tuple[str, str, str]]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT id, name, COALESCE(equipment, '(null)')
            FROM exercise_library_cleaned
            WHERE name ~* %s
              AND (name !~* %s)
              AND (equipment ILIKE 'bodyweight' OR equipment ILIKE 'body weight' OR equipment IS NULL OR equipment = '')
            ORDER BY name
            """,
            (PULLUP_BAR_PATTERN, EXCLUDE_PATTERN),
        )
        return cur.fetchall()


def _sync_chroma(rows: List[Tuple[str, str, str]]) -> None:
    try:
        from core.chroma_cloud import get_chroma_cloud_client
    except Exception as e:  # pragma: no cover
        print(f"⚠  Chroma client unavailable ({e}); skipping vector sync.")
        return

    try:
        client = get_chroma_cloud_client()
    except Exception as e:
        print(f"⚠  Failed to init Chroma client ({e}); skipping vector sync.")
        return

    ids = [r[0] for r in rows]
    for collection_name in ("exercise_library", "fitness_exercises"):
        try:
            collection = client.get_or_create_collection(collection_name)
        except Exception as e:
            print(f"   ⚠ Failed to open '{collection_name}': {e}")
            continue

        # Fetch existing metadata, flip the equipment field, upsert.
        try:
            existing = collection.get(ids=ids, include=["metadatas", "documents", "embeddings"])
        except Exception as e:
            print(f"   ⚠ Failed to read '{collection_name}': {e}")
            continue

        if not existing or not existing.get("ids"):
            print(f"   - '{collection_name}': no matching vectors (collection may only index a subset)")
            continue

        new_metas = []
        for meta in existing.get("metadatas") or []:
            m = dict(meta or {})
            m["equipment"] = NEW_EQUIPMENT
            new_metas.append(m)

        try:
            collection.update(ids=existing["ids"], metadatas=new_metas)
            print(f"   ✓ Updated metadata for {len(existing['ids'])} vector(s) in '{collection_name}'")
        except Exception as e:
            print(f"   ⚠ Failed to update metadata in '{collection_name}': {e}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Actually update (default: dry-run)")
    args = parser.parse_args()

    conn = _connect_db()
    try:
        candidates = _find_candidates(conn)
    except Exception as e:
        print(f"❌ Query failed: {e}")
        conn.close()
        return 1

    if not candidates:
        print("✓ No mis-tagged pull-up-bar exercises found.")
        conn.close()
        return 0

    print(f"\nFound {len(candidates)} candidate(s) to re-tag -> '{NEW_EQUIPMENT}':")
    print(f"{'id':36}  {'current_equipment':20}  name")
    print("-" * 96)
    for ex_id, name, equip in candidates:
        print(f"{ex_id}  {equip:20}  {name}")

    if not args.apply:
        print("\nDry-run only. Review the list above and re-run with --apply.")
        conn.close()
        return 0

    ids = [c[0] for c in candidates]
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE exercise_library_cleaned SET equipment = %s WHERE id = ANY(%s)",
            (NEW_EQUIPMENT, ids),
        )
        updated = cur.rowcount
    conn.commit()
    conn.close()
    print(f"\n✓ Updated {updated} row(s) in Postgres.")

    _sync_chroma(candidates)
    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
