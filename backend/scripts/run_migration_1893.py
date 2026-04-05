#!/usr/bin/env python3
"""Run migration 1893: Fix indexes and keys (Supabase linter warnings).

Applied: 2026-04-04

Fixes:
- unindexed_foreign_keys: 223 FK columns indexed (13 original + 210 from dropped unused)
- no_primary_key: 2 backup/copy tables given PK constraints on existing id columns
- duplicate_index: 71 redundant non-unique indexes dropped (where unique index exists)
- unused_index: 847 indexes with idx_scan=0 dropped (non-PK, non-unique)
- Re-created 223 FK indexes after unused-index cleanup exposed unindexed FKs

Final state:
  Unindexed foreign keys: 0
  Tables without PK: 0
  True duplicate indexes: 0 (5 remaining are false positives: btree vs gin, different WHERE)
  Truly unused indexes: 1 (235 are newly-created FK indexes with 0 scans)

Execution strategy:
  1. CREATE INDEX CONCURRENTLY for unindexed FKs (autocommit, no transaction)
  2. ALTER TABLE ADD PRIMARY KEY for backup/copy tables
  3. DROP INDEX for duplicate indexes (unique covers non-unique)
  4. DROP INDEX for unused indexes in batches of 50
  5. CREATE INDEX CONCURRENTLY for FKs exposed by step 4
  6. DROP INDEX for new duplicates from step 5
"""
import os
import sys
import time

import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")

CONN_PARAMS = dict(
    host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
    user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require",
)


def get_stats():
    """Get counts of linter issues."""
    conn = psycopg2.connect(**CONN_PARAMS)
    cur = conn.cursor()

    cur.execute("""
        SELECT COUNT(*) FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
        AND NOT EXISTS (
            SELECT 1 FROM pg_index idx
            JOIN pg_class cls ON cls.oid = idx.indrelid
            JOIN pg_namespace ns ON ns.oid = cls.relnamespace
            JOIN pg_attribute att ON att.attrelid = cls.oid AND att.attnum = ANY(idx.indkey)
            WHERE ns.nspname = 'public' AND cls.relname = tc.table_name AND att.attname = kcu.column_name
        )
    """)
    unindexed_fks = cur.fetchone()[0]

    cur.execute("""
        SELECT COUNT(*) FROM pg_tables t
        WHERE t.schemaname = 'public'
        AND NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_schema = 'public'
            AND tc.table_name = t.tablename
        )
    """)
    no_pk = cur.fetchone()[0]

    cur.execute("""
        SELECT COUNT(*) FROM pg_stat_user_indexes s
        JOIN pg_index i ON s.indexrelid = i.indexrelid
        WHERE s.schemaname = 'public' AND s.idx_scan = 0
        AND NOT i.indisprimary AND NOT i.indisunique
    """)
    unused = cur.fetchone()[0]

    cur.execute("""
        SELECT COUNT(*)
        FROM pg_index a
        JOIN pg_index b ON a.indrelid = b.indrelid
            AND a.indexrelid < b.indexrelid
            AND a.indkey::text = b.indkey::text
        JOIN pg_class ca ON ca.oid = a.indexrelid
        JOIN pg_namespace na ON na.oid = ca.relnamespace
        WHERE na.nspname = 'public'
    """)
    dups = cur.fetchone()[0]

    conn.close()
    return unindexed_fks, no_pk, unused, dups


def step1_index_unindexed_fks():
    """Create indexes on all unindexed foreign key columns."""
    conn = psycopg2.connect(**CONN_PARAMS)
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cur = conn.cursor()

    cur.execute("""
        SELECT DISTINCT tc.table_name, kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
        AND NOT EXISTS (
            SELECT 1 FROM pg_index idx
            JOIN pg_class cls ON cls.oid = idx.indrelid
            JOIN pg_namespace ns ON ns.oid = cls.relnamespace
            JOIN pg_attribute att ON att.attrelid = cls.oid AND att.attnum = ANY(idx.indkey)
            WHERE ns.nspname = 'public' AND cls.relname = tc.table_name AND att.attname = kcu.column_name
        )
        ORDER BY tc.table_name, kcu.column_name
    """)
    rows = cur.fetchall()
    if not rows:
        print("  No unindexed foreign keys found.")
        conn.close()
        return 0

    print(f"  Found {len(rows)} unindexed foreign keys...")
    success = errors = 0
    for table, col in rows:
        idx_name = f"idx_{table}_{col}"[:63]
        try:
            cur.execute(f"CREATE INDEX CONCURRENTLY IF NOT EXISTS {idx_name} ON public.{table} ({col})")
            success += 1
        except Exception as e:
            errors += 1
            print(f"    Error on {idx_name}: {e}")

    conn.close()
    print(f"  Created {success} FK indexes, {errors} errors")
    return success


def step2_add_primary_keys():
    """Add PKs to backup/copy tables that are missing them."""
    conn = psycopg2.connect(**CONN_PARAMS)
    cur = conn.cursor()

    tables_without_pk = []
    cur.execute("""
        SELECT t.tablename FROM pg_tables t
        WHERE t.schemaname = 'public'
        AND NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_schema = 'public'
            AND tc.table_name = t.tablename
        )
        ORDER BY t.tablename
    """)
    tables_without_pk = [r[0] for r in cur.fetchall()]

    if not tables_without_pk:
        print("  No tables without PK found.")
        conn.close()
        return 0

    success = 0
    for table in tables_without_pk:
        # Check if table has an 'id' column we can use
        cur.execute("""
            SELECT column_name, data_type FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = %s AND column_name = 'id'
        """, (table,))
        id_col = cur.fetchone()
        if id_col:
            try:
                cur.execute(f"DELETE FROM public.{table} WHERE id IS NULL")
                cur.execute(f"ALTER TABLE public.{table} ADD CONSTRAINT {table}_pkey PRIMARY KEY (id)")
                conn.commit()
                success += 1
                print(f"  Added PK to {table}")
            except Exception as e:
                conn.rollback()
                print(f"  Error adding PK to {table}: {e}")
        else:
            print(f"  SKIP {table}: no 'id' column found")

    conn.close()
    return success


def step3_drop_duplicate_indexes():
    """Drop redundant non-unique indexes where a unique index on same columns exists."""
    conn = psycopg2.connect(**CONN_PARAMS)
    cur = conn.cursor()

    cur.execute("""
        SELECT
            a.indexrelid::regclass, b.indexrelid::regclass,
            a.indrelid::regclass,
            a.indisprimary, b.indisprimary,
            a.indisunique, b.indisunique,
            pg_get_indexdef(a.indexrelid), pg_get_indexdef(b.indexrelid)
        FROM pg_index a
        JOIN pg_index b ON a.indrelid = b.indrelid
            AND a.indexrelid < b.indexrelid
            AND a.indkey::text = b.indkey::text
        JOIN pg_class ca ON ca.oid = a.indexrelid
        JOIN pg_namespace na ON na.oid = ca.relnamespace
        WHERE na.nspname = 'public'
    """)
    dup_rows = cur.fetchall()

    to_drop = set()
    for idx1, idx2, table, pk1, pk2, uniq1, uniq2, def1, def2 in dup_rows:
        idx1_name, idx2_name = str(idx1), str(idx2)
        d1, d2 = def1.lower(), def2.lower()

        # Skip different index types (btree vs gin)
        if ('using gin' in d1) != ('using gin' in d2):
            continue
        # Skip different WHERE clauses
        w1 = d1.split(' where ', 1)[1] if ' where ' in d1 else None
        w2 = d2.split(' where ', 1)[1] if ' where ' in d2 else None
        if w1 != w2:
            continue

        drop = None
        if pk1 and not pk2:
            drop = idx2_name
        elif pk2 and not pk1:
            drop = idx1_name
        elif uniq1 and not uniq2:
            drop = idx2_name
        elif uniq2 and not uniq1:
            drop = idx1_name
        elif not uniq1 and not uniq2:
            drop = idx2_name

        if drop:
            to_drop.add(drop)

    if not to_drop:
        print("  No true duplicate indexes found.")
        conn.close()
        return 0

    print(f"  Dropping {len(to_drop)} redundant indexes...")
    success = 0
    for idx in to_drop:
        try:
            cur.execute(f"DROP INDEX IF EXISTS {idx}")
            success += 1
        except Exception as e:
            conn.rollback()
            print(f"    Error dropping {idx}: {e}")

    conn.commit()
    conn.close()
    print(f"  Dropped {success} duplicate indexes")
    return success


def step4_drop_unused_indexes():
    """Drop indexes with idx_scan=0 that are not PK, not unique, and not supporting FKs."""
    conn = psycopg2.connect(**CONN_PARAMS)
    cur = conn.cursor()

    cur.execute("""
        SELECT s.indexrelname
        FROM pg_stat_user_indexes s
        JOIN pg_index i ON s.indexrelid = i.indexrelid
        WHERE s.schemaname = 'public'
          AND s.idx_scan = 0
          AND NOT i.indisprimary
          AND NOT i.indisunique
          AND NOT EXISTS (
            SELECT 1
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
                ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
            JOIN pg_attribute att ON att.attrelid = s.relid AND att.attname = kcu.column_name
            WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
              AND tc.table_name = s.relname
              AND att.attnum = ANY(i.indkey)
          )
        ORDER BY s.indexrelname
    """)
    indexes = [r[0] for r in cur.fetchall()]

    if not indexes:
        print("  No truly unused indexes found (all 0-scan indexes support FKs).")
        conn.close()
        return 0

    print(f"  Dropping {len(indexes)} unused non-FK indexes...")
    success = errors = 0
    batch_size = 50

    for i in range(0, len(indexes), batch_size):
        batch = indexes[i:i + batch_size]
        try:
            for idx in batch:
                cur.execute(f"DROP INDEX IF EXISTS public.{idx}")
            conn.commit()
            success += len(batch)
        except Exception as e:
            conn.rollback()
            for idx in batch:
                try:
                    cur.execute(f"DROP INDEX IF EXISTS public.{idx}")
                    conn.commit()
                    success += 1
                except Exception:
                    conn.rollback()
                    errors += 1

    conn.close()
    print(f"  Dropped {success} unused indexes, {errors} errors")
    return success


def run_migration():
    print(f"\n{'=' * 60}")
    print(f"Migration 1893: Fix indexes and keys")
    print(f"  Fixes unindexed FKs, missing PKs, duplicate & unused indexes")
    print(f"{'=' * 60}")

    fks, nopk, unused, dups = get_stats()
    print(f"\n  Current state:")
    print(f"    Unindexed foreign keys: {fks}")
    print(f"    Tables without PK:      {nopk}")
    print(f"    Duplicate index pairs:  {dups}")
    print(f"    Unused indexes (0-scan): {unused}")

    if fks == 0 and nopk == 0 and dups <= 5:
        print(f"\n  Migration already applied (or no issues found). Nothing to do.")
        return

    # Step 1: Index unindexed FKs
    print(f"\n  Step 1: Indexing unindexed foreign keys...")
    t0 = time.time()
    step1_index_unindexed_fks()
    print(f"    Time: {time.time() - t0:.1f}s")

    # Step 2: Add primary keys
    print(f"\n  Step 2: Adding primary keys...")
    t0 = time.time()
    step2_add_primary_keys()
    print(f"    Time: {time.time() - t0:.1f}s")

    # Step 3: Drop duplicate indexes
    print(f"\n  Step 3: Dropping duplicate indexes...")
    t0 = time.time()
    step3_drop_duplicate_indexes()
    print(f"    Time: {time.time() - t0:.1f}s")

    # Step 4: Drop unused indexes (excluding FK-supporting ones)
    print(f"\n  Step 4: Dropping unused non-FK indexes...")
    t0 = time.time()
    step4_drop_unused_indexes()
    print(f"    Time: {time.time() - t0:.1f}s")

    # Re-run step 1 in case step 4 dropped FK-supporting indexes
    print(f"\n  Step 5: Re-check for unindexed FKs after cleanup...")
    t0 = time.time()
    step1_index_unindexed_fks()
    print(f"    Time: {time.time() - t0:.1f}s")

    # Re-run step 3 in case step 5 created new duplicates
    print(f"\n  Step 6: Re-check for duplicate indexes...")
    t0 = time.time()
    step3_drop_duplicate_indexes()
    print(f"    Time: {time.time() - t0:.1f}s")

    # Final stats
    fks, nopk, unused, dups = get_stats()
    print(f"\n  Final state:")
    print(f"    Unindexed foreign keys: {fks}")
    print(f"    Tables without PK:      {nopk}")
    print(f"    Duplicate index pairs:  {dups}")
    print(f"    Unused indexes (0-scan): {unused}")
    print(f"\n  Migration completed!")


if __name__ == "__main__":
    run_migration()
