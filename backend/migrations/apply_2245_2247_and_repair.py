"""
One-shot: ensure food/weight/workout idempotency migrations (2245-2247) are
applied, then perform the user-approved data repair:
  (a) restore the user's soft-deleted dal-rice food_log,
  (b) cross-account dedup of historical duplicate food_logs.

Idempotent + preview-before-mutate. Run from backend/ with the venv:
    .venv/bin/python migrations/apply_2245_2247_and_repair.py
Add `--apply` to actually perform the restore + dedup (without it, dry-run).
The DDL migrations always run (they are IF NOT EXISTS, safe to repeat).
"""
import os
import sys
import re

import psycopg2
import psycopg2.extras

HERE = os.path.dirname(os.path.abspath(__file__))
APPLY = "--apply" in sys.argv


def load_database_url() -> str:
    # Prefer a real env var; otherwise parse backend/.env.
    url = os.environ.get("DATABASE_URL")
    if url:
        return _normalize(url)
    env_path = os.path.join(HERE, "..", ".env")
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line.startswith("DATABASE_URL"):
                # DATABASE_URL=... or DATABASE_URL="..."
                val = line.split("=", 1)[1].strip().strip('"').strip("'")
                if val:
                    return _normalize(val)
    raise SystemExit("DATABASE_URL not found in env or backend/.env")


def _normalize(url: str) -> str:
    # psycopg2 wants a plain libpq DSN — strip the SQLAlchemy async driver tag.
    return url.replace("postgresql+asyncpg://", "postgresql://").replace(
        "postgres+asyncpg://", "postgresql://"
    )


def col_exists(cur, table, col):
    cur.execute(
        "SELECT 1 FROM information_schema.columns WHERE table_name=%s AND column_name=%s",
        (table, col),
    )
    return cur.fetchone() is not None


def index_exists(cur, name):
    cur.execute("SELECT 1 FROM pg_indexes WHERE indexname=%s", (name,))
    return cur.fetchone() is not None


def run_sql_file(cur, path):
    with open(path) as f:
        cur.execute(f.read())


def main():
    url = load_database_url()
    conn = psycopg2.connect(url)
    conn.autocommit = False
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # ---- 1. Migrations (idempotent DDL) -----------------------------------
    print("== Migrations 2245-2247 ==")
    for fname in (
        "2245_food_logs_idempotency_key.sql",
        "2246_weight_logs_idempotency_key.sql",
        "2247_workout_logs_idempotency_key.sql",
    ):
        path = os.path.join(HERE, fname)
        if os.path.exists(path):
            run_sql_file(cur, path)
            print(f"  applied {fname}")
        else:
            print(f"  MISSING {fname} (skipped)")
    conn.commit()

    for table, idx in (
        ("food_logs", "uq_food_logs_user_idempotency_key"),
        ("weight_logs", "uq_weight_logs_user_idempotency_key"),
        ("workout_logs", "uq_workout_logs_user_idempotency_key"),
    ):
        print(
            f"  {table}: column={col_exists(cur, table, 'idempotency_key')} "
            f"index={index_exists(cur, idx)}"
        )

    # ---- 2. Restore the user's soft-deleted dal-rice food_log -------------
    print("\n== Restore soft-deleted dal-rice log ==")
    cur.execute(
        """
        SELECT id, user_id, meal_type, total_calories, logged_at, deleted_at,
               food_items::text AS items
        FROM food_logs
        WHERE deleted_at IS NOT NULL
          AND (food_items::text ILIKE '%dal rice%'
               OR food_items::text ILIKE '%pappu annam%')
        ORDER BY deleted_at DESC
        LIMIT 10
        """
    )
    candidates = cur.fetchall()
    for r in candidates:
        print(
            f"  candidate id={r['id']} user={r['user_id']} {r['total_calories']}kcal "
            f"logged={r['logged_at']} deleted={r['deleted_at']}"
        )
    if candidates:
        target = candidates[0]
        if APPLY:
            cur.execute(
                "UPDATE food_logs SET deleted_at = NULL WHERE id = %s", (target["id"],)
            )
            conn.commit()
            print(f"  RESTORED id={target['id']} (deleted_at cleared)")
        else:
            print(f"  [dry-run] would restore id={target['id']}")
    else:
        print("  no soft-deleted dal-rice row found")

    # ---- 3. Cross-account dedup of historical duplicate food_logs ---------
    # A duplicate pair = same user_id + meal_type + total_calories + same first
    # food item name, both live (deleted_at IS NULL), logged within 2 minutes.
    # Keep the EARLIEST row of each cluster; soft-delete the later extras.
    print("\n== Cross-account food_logs dedup ==")
    dedup_select = """
        WITH ranked AS (
            SELECT
                id, user_id, logged_at,
                ROW_NUMBER() OVER (
                    PARTITION BY user_id, meal_type, total_calories,
                        lower(coalesce(food_items->0->>'name', '')),
                        floor(extract(epoch FROM logged_at) / 120)
                    ORDER BY logged_at ASC, created_at ASC, id ASC
                ) AS rn
            FROM food_logs
            WHERE deleted_at IS NULL
        )
        SELECT id FROM ranked WHERE rn > 1
    """
    cur.execute(f"SELECT count(*) AS n FROM ({dedup_select}) d")
    dup_count = cur.fetchone()["n"]
    print(f"  duplicate extras to soft-delete: {dup_count}")
    if dup_count and APPLY:
        cur.execute(
            f"""
            UPDATE food_logs SET deleted_at = now()
            WHERE id IN ({dedup_select})
            """
        )
        conn.commit()
        print(f"  SOFT-DELETED {cur.rowcount} duplicate food_logs")
        # Re-check
        cur.execute(f"SELECT count(*) AS n FROM ({dedup_select}) d")
        print(f"  remaining duplicate extras after dedup: {cur.fetchone()['n']}")
    elif dup_count:
        print(f"  [dry-run] would soft-delete {dup_count} duplicate food_logs")

    cur.close()
    conn.close()
    print("\nDone." + ("" if APPLY else "  (dry-run — re-run with --apply to mutate)"))


if __name__ == "__main__":
    main()
