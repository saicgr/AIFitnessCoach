"""
Upload food_database_raw.parquet to Supabase PostgreSQL.
Creates table, bulk inserts ~716K rows, adds indexes, and creates deduped view.
"""

import io
import time
import pandas as pd
import psycopg2

CONN_STRING = "postgresql://postgres:d2nHU5oLZ1GCz63B@db.hpbzfahijszqmgsybuor.supabase.co:5432/postgres"
PARQUET_PATH = "food_curation/output/food_database_raw.parquet"
TABLE_NAME = "food_database"
VIEW_NAME = "food_database_deduped"
CHUNK_SIZE = 50_000

# Column definitions: (parquet_col, sql_type)
COLUMNS = [
    ("name", "TEXT NOT NULL"),
    ("name_normalized", "TEXT NOT NULL"),
    ("source", "TEXT NOT NULL"),
    ("source_id", "TEXT NOT NULL"),
    ("data_type", "TEXT"),
    ("brand", "TEXT"),
    ("category", "TEXT"),
    ("food_group", "TEXT"),
    ("calories_per_100g", "REAL"),
    ("protein_per_100g", "REAL"),
    ("fat_per_100g", "REAL"),
    ("carbs_per_100g", "REAL"),
    ("fiber_per_100g", "REAL"),
    ("sugar_per_100g", "REAL"),
    ("micronutrients_per_100g", "TEXT"),
    ("serving_description", "TEXT"),
    ("serving_weight_g", "REAL"),
    ("calories_per_serving", "REAL"),
    ("protein_per_serving", "REAL"),
    ("fat_per_serving", "REAL"),
    ("carbs_per_serving", "REAL"),
    ("allergens", "TEXT"),
    ("diet_labels", "TEXT"),
    ("nova_group", "REAL"),
    ("nutriscore_score", "REAL"),
    ("traces", "TEXT"),
    ("ingredients_text", "TEXT"),
    ("image_url", "TEXT"),
    ("inflammatory_score", "REAL"),
    ("inflammatory_category", "TEXT"),
    ("nutrient_count", "INTEGER"),
    ("micro_count", "INTEGER"),
    ("has_serving", "BOOLEAN"),
    ("data_completeness", "REAL"),
    ("processing_notes", "TEXT"),
    ("source_url", "TEXT"),
    ("dedup_key", "TEXT NOT NULL"),
    ("dedup_rank", "INTEGER NOT NULL"),
    ("is_primary", "BOOLEAN NOT NULL"),
]

COL_NAMES = [c[0] for c in COLUMNS]


def create_table(cur):
    """Drop existing objects and create fresh table."""
    print("Dropping existing view and table...")
    cur.execute(f"DROP VIEW IF EXISTS {VIEW_NAME} CASCADE;")
    cur.execute(f"DROP TABLE IF EXISTS {TABLE_NAME} CASCADE;")

    col_defs = ",\n    ".join(f"{name} {sql_type}" for name, sql_type in COLUMNS)
    create_sql = f"""
    CREATE TABLE {TABLE_NAME} (
        id BIGSERIAL PRIMARY KEY,
        {col_defs}
    );
    """
    print("Creating table...")
    cur.execute(create_sql)
    print("Table created.")


def bulk_insert(cur, df):
    """Insert data using COPY FROM STDIN for speed."""
    total = len(df)
    inserted = 0
    col_list = ",".join(COL_NAMES)

    for start in range(0, total, CHUNK_SIZE):
        chunk = df.iloc[start : start + CHUNK_SIZE]
        buf = io.StringIO()
        chunk[COL_NAMES].to_csv(buf, index=False, header=True, na_rep="\\N")
        buf.seek(0)

        copy_sql = f"COPY {TABLE_NAME} ({col_list}) FROM STDIN WITH (FORMAT CSV, HEADER TRUE, NULL '\\N')"
        cur.copy_expert(copy_sql, buf)

        inserted += len(chunk)
        print(f"  Inserted {inserted:,}/{total:,} rows ({inserted * 100 // total}%)")

    return inserted


def create_indexes(cur):
    """Create indexes for common query patterns."""
    indexes = [
        (
            f"idx_{TABLE_NAME}_is_primary",
            f"CREATE INDEX idx_{TABLE_NAME}_is_primary ON {TABLE_NAME} (is_primary) WHERE is_primary = TRUE;",
        ),
        (
            f"idx_{TABLE_NAME}_source",
            f"CREATE INDEX idx_{TABLE_NAME}_source ON {TABLE_NAME} (source);",
        ),
        (
            f"idx_{TABLE_NAME}_name_normalized",
            f"CREATE INDEX idx_{TABLE_NAME}_name_normalized ON {TABLE_NAME} (name_normalized);",
        ),
        (
            f"idx_{TABLE_NAME}_dedup_key",
            f"CREATE INDEX idx_{TABLE_NAME}_dedup_key ON {TABLE_NAME} (dedup_key);",
        ),
        (
            f"idx_{TABLE_NAME}_category",
            f"CREATE INDEX idx_{TABLE_NAME}_category ON {TABLE_NAME} (category);",
        ),
    ]

    for name, sql in indexes:
        print(f"  Creating index {name}...")
        cur.execute(sql)

    # Enable pg_trgm extension and create GIN trigram index for fuzzy search
    print("  Enabling pg_trgm extension...")
    cur.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm;")
    print(f"  Creating GIN trigram index on name_normalized...")
    cur.execute(
        f"CREATE INDEX idx_{TABLE_NAME}_name_trgm ON {TABLE_NAME} USING GIN (name_normalized gin_trgm_ops);"
    )
    print("All indexes created.")


def create_view(cur):
    """Create deduped view filtering to primary entries only."""
    cur.execute(f"""
        CREATE VIEW {VIEW_NAME} AS
        SELECT * FROM {TABLE_NAME} WHERE is_primary = TRUE;
    """)
    print("View created.")


def verify(cur):
    """Print verification stats."""
    cur.execute(f"SELECT COUNT(*) FROM {TABLE_NAME};")
    raw_count = cur.fetchone()[0]

    cur.execute(f"SELECT COUNT(*) FROM {VIEW_NAME};")
    deduped_count = cur.fetchone()[0]

    cur.execute(f"SELECT source, COUNT(*) FROM {TABLE_NAME} GROUP BY source ORDER BY COUNT(*) DESC;")
    source_counts = cur.fetchall()

    cur.execute(f"""
        SELECT indexname, pg_size_pretty(pg_relation_size(indexname::regclass))
        FROM pg_indexes WHERE tablename = '{TABLE_NAME}';
    """)
    index_info = cur.fetchall()

    cur.execute(f"SELECT pg_size_pretty(pg_total_relation_size('{TABLE_NAME}'));")
    table_size = cur.fetchone()[0]

    print(f"\n{'='*50}")
    print(f"VERIFICATION")
    print(f"{'='*50}")
    print(f"Raw table rows:    {raw_count:,}")
    print(f"Deduped view rows: {deduped_count:,}")
    print(f"Table total size:  {table_size}")
    print(f"\nRows by source:")
    for source, count in source_counts:
        print(f"  {source}: {count:,}")
    print(f"\nIndexes:")
    for name, size in index_info:
        print(f"  {name}: {size}")

    # Spot check: chicken breast search
    cur.execute(f"""
        SELECT name, source, calories_per_100g, protein_per_100g
        FROM {VIEW_NAME}
        WHERE name_normalized ILIKE '%chicken breast%'
        LIMIT 5;
    """)
    results = cur.fetchall()
    print(f"\nSample query (chicken breast from deduped view):")
    for row in results:
        print(f"  {row[0]} [{row[1]}] - {row[2]} cal, {row[3]}g protein")


def main():
    start = time.time()

    print(f"Reading {PARQUET_PATH}...")
    df = pd.read_parquet(PARQUET_PATH)
    print(f"Loaded {len(df):,} rows, {len(df.columns)} columns")

    # Ensure column order matches
    missing = [c for c in COL_NAMES if c not in df.columns]
    if missing:
        raise ValueError(f"Missing columns in parquet: {missing}")

    print(f"\nConnecting to Supabase...")
    conn = psycopg2.connect(CONN_STRING)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        create_table(cur)
        conn.commit()

        print(f"\nBulk inserting {len(df):,} rows (chunk size: {CHUNK_SIZE:,})...")
        inserted = bulk_insert(cur, df)
        conn.commit()
        print(f"Inserted {inserted:,} rows total.")

        print("\nCreating indexes...")
        create_indexes(cur)
        conn.commit()

        print("\nCreating deduped view...")
        create_view(cur)
        conn.commit()

        print("\nVerifying...")
        verify(cur)

    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cur.close()
        conn.close()

    elapsed = time.time() - start
    print(f"\nDone in {elapsed:.1f}s")


if __name__ == "__main__":
    main()
