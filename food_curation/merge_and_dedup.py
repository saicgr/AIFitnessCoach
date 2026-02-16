"""
Merge all processed parquets and deduplicate.

Architecture: Outputs a single raw table with ALL rows, plus rank columns.
Deduped = rank 1 entries only.

Dedup strategy:
  1. Normalize food names (sort words alphabetically) as dedup key
  2. Priority: usda > usda_branded > cnf > indb > openfoodfacts
  3. Among same source, prefer the entry with more micronutrients

Output files:
  - food_database_raw.parquet     - ALL rows with dedup_key, dedup_rank, is_primary
  - food_database_raw.csv         - same, for human review
  - food_database_deduped.parquet - filtered to is_primary=True only
  - food_database_deduped.csv     - same, for human review

Usage:
    python food_curation/merge_and_dedup.py
"""

import json
import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).parent))
from config import OUTPUT_DIR
from normalize import SOURCE_PRIORITY, normalize_food_name


def count_micros(val) -> int:
    """Count micronutrients in the JSON string."""
    if pd.isna(val) or not val:
        return 0
    try:
        return len(json.loads(val))
    except (json.JSONDecodeError, TypeError):
        return 0


def main():
    print("=" * 60)
    print("Merge & Deduplicate (5 sources)")
    print("=" * 60)

    # Load all five processed parquets
    sources = {
        "usda": OUTPUT_DIR / "usda_processed.parquet",
        "usda_branded": OUTPUT_DIR / "usda_branded_processed.parquet",
        "cnf": OUTPUT_DIR / "cnf_processed.parquet",
        "off": OUTPUT_DIR / "off_processed.parquet",
        "indb": OUTPUT_DIR / "indb_processed.parquet",
    }

    dfs = []
    for label, path in sources.items():
        if path.exists():
            df = pd.read_parquet(path)
            print(f"  Loaded {label}: {len(df):,} rows")
            dfs.append(df)
        else:
            print(f"  WARNING: {label} not found at {path}, skipping")

    if not dfs:
        print("ERROR: No source files found. Run process_*.py first.")
        sys.exit(1)

    # Concatenate
    df = pd.concat(dfs, ignore_index=True)
    total_before = len(df)
    print(f"\nCombined: {total_before:,} rows")

    # Filter: must have name and calories > 0
    df = df.dropna(subset=["name"])
    df = df[df["name"].str.strip().str.len() > 0]
    df = df[df["calories_per_100g"] > 0]
    print(f"After name+calories filter: {len(df):,}")

    # Create dedup key (sorted words, brand-aware for branded items)
    print("Building dedup keys ...")
    df["dedup_key"] = df.apply(
        lambda row: normalize_food_name(row["name"], row.get("brand")), axis=1
    )
    df = df[df["dedup_key"].str.len() > 0]

    # Source priority and micro count for sorting
    df["_source_priority"] = df["source"].map(SOURCE_PRIORITY).fillna(99).astype(int)
    df["_micro_count"] = df["micronutrients_per_100g"].apply(count_micros)

    # Sort: dedup_key ASC, source_priority ASC (USDA first), micro_count DESC
    df = df.sort_values(
        ["dedup_key", "_source_priority", "_micro_count"],
        ascending=[True, True, False],
    )

    # Assign dedup_rank within each dedup_key group
    print("Assigning dedup ranks ...")
    df["dedup_rank"] = df.groupby("dedup_key").cumcount() + 1
    df["is_primary"] = df["dedup_rank"] == 1

    # Stats
    n_unique = df["dedup_key"].nunique()
    n_dups = len(df) - n_unique
    print(f"\n  Total rows: {len(df):,}")
    print(f"  Unique dedup keys: {n_unique:,}")
    print(f"  Duplicate rows: {n_dups:,}")

    # Show duplicate breakdown by source
    dup_df = df[df["dedup_rank"] > 1]
    if len(dup_df) > 0:
        print(f"\n  Duplicates by source:")
        for src, cnt in dup_df["source"].value_counts().items():
            print(f"    {src}: {cnt:,}")

    # Clean up internal columns
    df = df.drop(columns=["_source_priority", "_micro_count"])

    # Sort by source, then name for readability
    df = df.sort_values(["source", "name"]).reset_index(drop=True)

    # ── Save RAW (all rows) ──
    raw_parquet = OUTPUT_DIR / "food_database_raw.parquet"
    df.to_parquet(raw_parquet, index=False)
    print(f"\nSaved RAW: {raw_parquet} ({len(df):,} rows)")

    raw_csv = OUTPUT_DIR / "food_database_raw.csv"
    df.to_csv(raw_csv, index=False)
    print(f"Saved RAW CSV: {raw_csv}")

    # ── Save DEDUPED (primary entries only) ──
    df_deduped = df[df["is_primary"]].copy().reset_index(drop=True)

    deduped_parquet = OUTPUT_DIR / "food_database_deduped.parquet"
    df_deduped.to_parquet(deduped_parquet, index=False)
    print(f"\nSaved DEDUPED: {deduped_parquet} ({len(df_deduped):,} rows)")

    deduped_csv = OUTPUT_DIR / "food_database_deduped.csv"
    df_deduped.to_csv(deduped_csv, index=False)
    print(f"Saved DEDUPED CSV: {deduped_csv}")

    # Also save the old filename for backwards compatibility
    compat_parquet = OUTPUT_DIR / "food_database_final.parquet"
    df_deduped.to_parquet(compat_parquet, index=False)
    compat_csv = OUTPUT_DIR / "food_database_final.csv"
    df_deduped.to_csv(compat_csv, index=False)

    # Final breakdown
    print("\n  Final breakdown by source (deduped):")
    for src, count in df_deduped["source"].value_counts().items():
        print(f"    {src}: {count:,}")
    print(f"    TOTAL: {len(df_deduped):,}")

    print("\n  Final breakdown by source (raw):")
    for src, count in df["source"].value_counts().items():
        print(f"    {src}: {count:,}")
    print(f"    TOTAL: {len(df):,}")


if __name__ == "__main__":
    main()
