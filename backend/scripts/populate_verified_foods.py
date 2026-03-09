#!/usr/bin/env python3
"""
Populate the verified_foods table from food_database.

Extracts quality-verified items from food_database (528K rows), applies sanity
checks (all 4 core macros present, calorie/macro bounds, no override duplicates),
assigns verification tiers, and batch-inserts into verified_foods.

Three-tier search hierarchy:
  1. food_nutrition_overrides  (hand-curated, highest trust)
  2. verified_foods            (quality-checked, this table)
  3. food_database             (raw, lowest trust)

Usage:
  python populate_verified_foods.py              # run full population
  python populate_verified_foods.py --dry-run    # count only, no inserts
"""

import argparse
import logging
import os
import sys
import time
from collections import defaultdict

from typing import Optional

import psycopg2
import psycopg2.extras

# ─────────────────────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────────────────────
# Database connection
# ─────────────────────────────────────────────────────────────

DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", 5432))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")

if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD or SUPABASE_DB_PASSWORD environment variable is required")

BATCH_SIZE = 5000

# ─────────────────────────────────────────────────────────────
# Extraction query
# ─────────────────────────────────────────────────────────────

EXTRACTION_QUERY = """
SELECT DISTINCT ON (LOWER(fd.name))
    LOWER(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(fd.name), '[^a-zA-Z0-9 ]', '', 'g'), '\\s+', '_', 'g')) AS food_name_normalized,
    INITCAP(TRIM(fd.name)) AS display_name,
    fd.calories_per_100g,
    fd.protein_per_100g,
    fd.carbs_per_100g,
    fd.fat_per_100g,
    fd.fiber_per_100g,
    fd.sugar_per_100g,
    fd.serving_weight_g AS default_serving_g,
    NULL::REAL AS default_weight_per_piece_g,
    fd.source,
    fd.source_id::TEXT AS source_id,
    fd.brand,
    fd.category AS food_category,
    fd.data_type
FROM food_database fd
WHERE fd.is_primary = TRUE
  -- Must have all 4 core macros
  AND fd.calories_per_100g IS NOT NULL
  AND fd.protein_per_100g IS NOT NULL
  AND fd.carbs_per_100g IS NOT NULL
  AND fd.fat_per_100g IS NOT NULL
  -- Calorie sanity: 0 <= cal <= 902 (pure fat max)
  AND fd.calories_per_100g >= 0
  AND fd.calories_per_100g <= 902
  -- Macro sanity: P + C + F <= 101g per 100g (1g tolerance)
  AND (fd.protein_per_100g + fd.carbs_per_100g + fd.fat_per_100g) <= 101
  -- Not a duplicate of an existing override
  AND NOT EXISTS (
    SELECT 1 FROM food_nutrition_overrides fno
    WHERE fno.food_name_normalized = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(fd.name), '[^a-zA-Z0-9 ]', '', 'g'), '\\s+', '_', 'g'))
  )
ORDER BY LOWER(fd.name),
  CASE fd.source
    WHEN 'USDA' THEN 0
    WHEN 'OPEN_FOOD_FACTS' THEN 1
    ELSE 2
  END,
  CASE
    WHEN fd.data_type IN ('Foundation', 'SR Legacy', 'Survey (FNDDS)') THEN 0
    WHEN fd.data_type = 'Branded' THEN 1
    ELSE 2
  END
"""

# ─────────────────────────────────────────────────────────────
# Classification helpers
# ─────────────────────────────────────────────────────────────

LAB_DATA_TYPES = frozenset({"foundation_food", "sr_legacy_food", "survey_fndds_food"})


def classify_verification_level(source: str, data_type: str) -> Optional[str]:
    """Return verification tier or None to skip the row."""
    if source == "usda":
        if data_type in LAB_DATA_TYPES:
            return "lab_verified"
        return None  # unknown usda data_type — skip
    if source == "usda_branded":
        if data_type == "branded_food":
            return "manufacturer_verified"
        return None
    if source == "openfoodfacts":
        return "community_verified"
    return None  # unknown source (cnf, indb, etc.) — skip


def map_source(source: str, data_type: str) -> str:
    """Map raw source + data_type to the verified_foods.source enum."""
    if source == "usda":
        if data_type in LAB_DATA_TYPES:
            return "usda_lab"
        return "usda_lab"  # fallback for usda
    if source == "usda_branded":
        return "usda_branded"
    return "off_verified"


def compute_completeness(row: dict) -> float:
    """Score 0-1 based on how many of 8 key fields are non-null."""
    fields = [
        row["calories_per_100g"],
        row["protein_per_100g"],
        row["carbs_per_100g"],
        row["fat_per_100g"],
        row["fiber_per_100g"],
        row["sugar_per_100g"],
        row.get("sodium_mg"),  # not in extraction query — always None for now
        row["default_serving_g"],
    ]
    present = sum(1 for f in fields if f is not None)
    return round(present / 8, 4)


# ─────────────────────────────────────────────────────────────
# Insert SQL
# ─────────────────────────────────────────────────────────────

INSERT_SQL = """
INSERT INTO verified_foods (
    food_name_normalized,
    display_name,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    sugar_per_100g,
    default_serving_g,
    default_weight_per_piece_g,
    source,
    source_id,
    brand,
    food_category,
    verification_level,
    data_completeness_score
) VALUES (
    %(food_name_normalized)s,
    %(display_name)s,
    %(calories_per_100g)s,
    %(protein_per_100g)s,
    %(carbs_per_100g)s,
    %(fat_per_100g)s,
    %(fiber_per_100g)s,
    %(sugar_per_100g)s,
    %(default_serving_g)s,
    %(default_weight_per_piece_g)s,
    %(source)s,
    %(source_id)s,
    %(brand)s,
    %(food_category)s,
    %(verification_level)s,
    %(data_completeness_score)s
) ON CONFLICT (food_name_normalized) DO NOTHING
"""

# ─────────────────────────────────────────────────────────────
# Column names returned by EXTRACTION_QUERY (positional)
# ─────────────────────────────────────────────────────────────

COLUMN_NAMES = [
    "food_name_normalized",
    "display_name",
    "calories_per_100g",
    "protein_per_100g",
    "carbs_per_100g",
    "fat_per_100g",
    "fiber_per_100g",
    "sugar_per_100g",
    "default_serving_g",
    "default_weight_per_piece_g",
    "source",
    "source_id",
    "brand",
    "food_category",
    "data_type",
]


def row_to_dict(row: tuple) -> dict:
    """Convert a cursor row tuple into a named dict."""
    return dict(zip(COLUMN_NAMES, row))


# ─────────────────────────────────────────────────────────────
# Main logic
# ─────────────────────────────────────────────────────────────

def run(dry_run: bool = False) -> bool:
    logger.info("Connecting to database %s@%s:%d/%s ...", DATABASE_USER, DATABASE_HOST, DATABASE_PORT, DATABASE_NAME)
    conn = psycopg2.connect(
        host=DATABASE_HOST,
        port=DATABASE_PORT,
        dbname=DATABASE_NAME,
        user=DATABASE_USER,
        password=DATABASE_PASSWORD,
        sslmode="require",
    )

    # Stats accumulators
    stats = {
        "total_extracted": 0,
        "skipped_unknown_source": 0,
        "skipped_low_completeness": 0,
        "inserted": 0,
        "by_verification": defaultdict(int),
        "by_source": defaultdict(int),
        "high_completeness": 0,  # >= 0.8
        "samples": defaultdict(list),  # verification_level -> list of sample display_names
    }

    try:
        # Use a server-side (named) cursor for the large extraction query
        logger.info("Executing extraction query with server-side cursor ...")
        t0 = time.time()

        cur_name = "verified_foods_extract"
        server_cursor = conn.cursor(name=cur_name)
        server_cursor.itersize = BATCH_SIZE
        server_cursor.execute(EXTRACTION_QUERY)

        elapsed_query = time.time() - t0
        logger.info("Extraction query started (%.1fs). Fetching rows ...", elapsed_query)

        # We'll use a separate cursor for inserts
        insert_cursor = conn.cursor()

        batch = []
        batch_num = 0

        while True:
            rows = server_cursor.fetchmany(BATCH_SIZE)
            if not rows:
                break

            for raw_row in rows:
                stats["total_extracted"] += 1
                row = row_to_dict(raw_row)

                raw_source = row["source"]
                raw_data_type = row["data_type"]

                # Classify verification level
                verification_level = classify_verification_level(raw_source, raw_data_type)
                if verification_level is None:
                    stats["skipped_unknown_source"] += 1
                    continue

                # Compute completeness and filter
                completeness = compute_completeness(row)
                if completeness < 0.5:
                    stats["skipped_low_completeness"] += 1
                    continue

                # Map source to verified_foods enum
                mapped_source = map_source(raw_source, raw_data_type)

                # Build insert dict
                insert_row = {
                    "food_name_normalized": row["food_name_normalized"],
                    "display_name": row["display_name"],
                    "calories_per_100g": row["calories_per_100g"],
                    "protein_per_100g": row["protein_per_100g"],
                    "carbs_per_100g": row["carbs_per_100g"],
                    "fat_per_100g": row["fat_per_100g"],
                    "fiber_per_100g": row["fiber_per_100g"],
                    "sugar_per_100g": row["sugar_per_100g"],
                    "default_serving_g": row["default_serving_g"],
                    "default_weight_per_piece_g": row["default_weight_per_piece_g"],
                    "source": mapped_source,
                    "source_id": row["source_id"],
                    "brand": row["brand"],
                    "food_category": row["food_category"],
                    "verification_level": verification_level,
                    "data_completeness_score": completeness,
                }

                batch.append(insert_row)

                # Track stats
                stats["by_verification"][verification_level] += 1
                stats["by_source"][mapped_source] += 1
                if completeness >= 0.8:
                    stats["high_completeness"] += 1

                # Collect samples (up to 5 per tier)
                if len(stats["samples"][verification_level]) < 5:
                    stats["samples"][verification_level].append(
                        f"{row['display_name']} ({row['calories_per_100g']:.0f} cal, completeness={completeness:.2f})"
                    )

                # Flush batch
                if len(batch) >= BATCH_SIZE:
                    batch_num += 1
                    if dry_run:
                        logger.info("  [DRY RUN] Batch %d: %d rows (would insert)", batch_num, len(batch))
                    else:
                        _insert_batch(insert_cursor, batch, batch_num)
                    stats["inserted"] += len(batch)
                    batch = []

            # Progress log after each server-side fetch
            logger.info("  Processed %d rows so far ...", stats["total_extracted"])

        # Flush remaining
        if batch:
            batch_num += 1
            if dry_run:
                logger.info("  [DRY RUN] Batch %d: %d rows (would insert)", batch_num, len(batch))
            else:
                _insert_batch(insert_cursor, batch, batch_num)
            stats["inserted"] += len(batch)

        server_cursor.close()

        if not dry_run:
            conn.commit()
            logger.info("All batches committed.")
        else:
            conn.rollback()
            logger.info("[DRY RUN] No data was inserted.")

        insert_cursor.close()

        # Verification: count rows in verified_foods
        if not dry_run:
            with conn.cursor() as vcur:
                vcur.execute("SELECT count(*) FROM verified_foods WHERE is_active = TRUE")
                total_in_table = vcur.fetchone()[0]
                logger.info("Total active rows in verified_foods: %d", total_in_table)

    except Exception:
        conn.rollback()
        logger.exception("Fatal error during population")
        return False
    finally:
        conn.close()

    # ── Print stats ───────────────────────────────────────────
    _print_stats(stats, dry_run)
    return True


def _insert_batch(cursor, batch: list[dict], batch_num: int) -> None:
    """Execute a batch insert with ON CONFLICT DO NOTHING."""
    t0 = time.time()
    psycopg2.extras.execute_batch(cursor, INSERT_SQL, batch, page_size=1000)
    elapsed = time.time() - t0
    logger.info("  Batch %d: inserted %d rows (%.2fs)", batch_num, len(batch), elapsed)


def _print_stats(stats: dict, dry_run: bool) -> None:
    """Print a human-readable summary."""
    prefix = "[DRY RUN] " if dry_run else ""

    print(f"\n{'=' * 60}")
    print(f"{prefix}VERIFIED FOODS POPULATION STATS")
    print(f"{'=' * 60}")

    print(f"\n  Total rows extracted from food_database:  {stats['total_extracted']:,}")
    print(f"  Skipped (unknown source/data_type):       {stats['skipped_unknown_source']:,}")
    print(f"  Skipped (completeness < 0.5):             {stats['skipped_low_completeness']:,}")
    print(f"  Rows {'that would be ' if dry_run else ''}inserted:                      {stats['inserted']:,}")

    print(f"\n--- By verification_level ---")
    for level in ["lab_verified", "manufacturer_verified", "community_verified"]:
        count = stats["by_verification"].get(level, 0)
        print(f"  {level:30s} {count:>8,}")

    print(f"\n--- By source ---")
    for src in ["usda_lab", "usda_branded", "off_verified"]:
        count = stats["by_source"].get(src, 0)
        print(f"  {src:30s} {count:>8,}")

    print(f"\n--- Data completeness ---")
    print(f"  Rows with completeness >= 0.8:            {stats['high_completeness']:,}")

    print(f"\n--- Sample items per tier ---")
    for level in ["lab_verified", "manufacturer_verified", "community_verified"]:
        samples = stats["samples"].get(level, [])
        if samples:
            print(f"\n  [{level}]")
            for s in samples:
                print(f"    - {s}")

    print(f"\n{'=' * 60}")


# ─────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Populate verified_foods from food_database with quality checks."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Count and classify rows without inserting into the database.",
    )
    args = parser.parse_args()

    logger.info("Starting verified_foods population%s ...", " (DRY RUN)" if args.dry_run else "")
    t_start = time.time()

    success = run(dry_run=args.dry_run)

    elapsed = time.time() - t_start
    logger.info("Finished in %.1f seconds.", elapsed)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
