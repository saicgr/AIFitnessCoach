"""
Data quality validation report for the curated food database.

Prints stats, samples, null rates, category distribution, and spot-checks
for specific foods. Exports a validation_report.txt for user review.

Usage:
    python food_curation/validate.py
"""

import io
import json
import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).parent))
from config import AMINO_ACID_KEYS, MACRO_COLUMNS, OUTPUT_DIR


# Foods to spot-check (common items users will search for)
SPOT_CHECK_FOODS = [
    "chicken breast",
    "biryani",
    "rice",
    "banana",
    "idli",
    "egg",
    "paneer",
    "oats",
    "apple",
    "salmon",
    "dal",
    "roti",
    "milk",
    "yogurt",
    "pizza",
]

# Foods to spot-check inflammatory scores
INFLAMMATORY_SPOT_CHECKS = {
    "salmon": "anti",       # should be anti-inflammatory
    "blueberr": "anti",     # should be anti-inflammatory
    "spinach": "anti",      # should be anti-inflammatory
    "candy": "inflammatory",  # should be pro-inflammatory
    "bacon": "inflammatory",  # should be pro-inflammatory
    "soda": "inflammatory",   # should be pro-inflammatory
}


class TeeWriter:
    """Write to both stdout and a StringIO buffer."""

    def __init__(self):
        self.buffer = io.StringIO()
        self.stdout = sys.stdout

    def write(self, text):
        self.stdout.write(text)
        self.buffer.write(text)

    def flush(self):
        self.stdout.flush()

    def get_value(self):
        return self.buffer.value() if hasattr(self.buffer, "value") else self.buffer.getvalue()


def print_section(title: str):
    print(f"\n{'=' * 60}")
    print(f"  {title}")
    print(f"{'=' * 60}")


def validate_final(df: pd.DataFrame):
    """Run all validation checks."""

    # ── 1. Row counts ──
    print_section("1. Row Counts")
    print(f"Total foods: {len(df):,}")
    print(f"\nBy source:")
    for src, count in df["source"].value_counts().items():
        pct = count / len(df) * 100
        print(f"  {src:20s} {count:>8,}  ({pct:.1f}%)")

    if "data_type" in df.columns:
        print(f"\nBy data_type:")
        for dt, count in df["data_type"].value_counts().head(10).items():
            print(f"  {str(dt):30s} {count:>8,}")

    # ── 2. Random samples ──
    print_section("2. Random Samples (10 per source)")
    for src in sorted(df["source"].unique()):
        subset = df[df["source"] == src]
        sample = subset.sample(min(10, len(subset)), random_state=42)
        print(f"\n--- {src.upper()} ---")
        for _, row in sample.iterrows():
            cat = row.get("category", "")
            cat_str = f" [{cat}]" if pd.notna(cat) and cat else ""
            brand_str = f" ({row['brand']})" if pd.notna(row.get("brand")) and row.get("brand") else ""
            print(
                f"  {row['name'][:50]:50s}{brand_str[:20]:20s} "
                f"cal={row['calories_per_100g']:>7.1f}  "
                f"P={row['protein_per_100g']:>6.1f}  "
                f"F={row['fat_per_100g']:>6.1f}  "
                f"C={row['carbs_per_100g']:>6.1f}"
                f"{cat_str}"
            )

    # ── 3. Null / zero rates ──
    print_section("3. Null & Zero Rates")
    check_cols = [
        "calories_per_100g", "protein_per_100g", "fat_per_100g",
        "carbs_per_100g", "fiber_per_100g", "sugar_per_100g",
        "micronutrients_per_100g", "serving_description", "serving_weight_g",
        "calories_per_serving", "brand", "category", "food_group",
        "allergens", "diet_labels", "nova_group", "nutriscore_score",
        "traces", "ingredients_text", "image_url",
        "inflammatory_score", "inflammatory_category",
        "source_url",
    ]
    for col in check_cols:
        if col not in df.columns:
            continue
        null_count = df[col].isna().sum()
        null_pct = null_count / len(df) * 100

        if df[col].dtype in ("float64", "int64", "Float64"):
            zero_count = (df[col] == 0).sum()
            zero_pct = zero_count / len(df) * 100
            print(f"  {col:30s}  null={null_count:>7,} ({null_pct:5.1f}%)  zero={zero_count:>7,} ({zero_pct:5.1f}%)")
        else:
            print(f"  {col:30s}  null={null_count:>7,} ({null_pct:5.1f}%)")

    # ── 4. Top 20 categories ──
    print_section("4. Top 20 Categories")
    if "category" in df.columns:
        cats = df["category"].dropna().value_counts().head(20)
        for cat, count in cats.items():
            print(f"  {str(cat)[:50]:50s} {count:>6,}")
    else:
        print("  No category column found")

    # ── 5. Micronutrient coverage ──
    print_section("5. Micronutrient Coverage")
    micro_data = df["micronutrients_per_100g"].dropna()
    if len(micro_data) > 0:
        micro_counts: dict[str, int] = {}
        for val in micro_data:
            try:
                d = json.loads(val)
                for key in d:
                    micro_counts[key] = micro_counts.get(key, 0) + 1
            except (json.JSONDecodeError, TypeError):
                pass
        for key, count in sorted(micro_counts.items(), key=lambda x: -x[1]):
            pct = count / len(df) * 100
            print(f"  {key:30s} {count:>8,}  ({pct:.1f}%)")

    # ── 6. Amino acid coverage ──
    print_section("6. Amino Acid Coverage")
    if len(micro_data) > 0:
        aa_counts: dict[str, int] = {}
        for val in micro_data:
            try:
                d = json.loads(val)
                for key in AMINO_ACID_KEYS:
                    if key in d and d[key] > 0:
                        aa_counts[key] = aa_counts.get(key, 0) + 1
            except (json.JSONDecodeError, TypeError):
                pass
        if aa_counts:
            for key, count in sorted(aa_counts.items(), key=lambda x: -x[1]):
                pct = count / len(df) * 100
                print(f"  {key:30s} {count:>8,}  ({pct:.1f}%)")

            # Spot-check: chicken breast should have high leucine
            chicken = df[df["name_normalized"].str.contains("chicken breast", case=False, na=False)]
            if len(chicken) > 0:
                row = chicken.iloc[0]
                if pd.notna(row["micronutrients_per_100g"]):
                    micros = json.loads(row["micronutrients_per_100g"])
                    leucine = micros.get("leucine_mg", 0)
                    print(f"\n  Spot-check: '{row['name'][:40]}' leucine_mg = {leucine}")
                    if leucine > 1000:
                        print(f"    PASS (expected >1000 mg for chicken breast)")
                    else:
                        print(f"    WARNING: leucine seems low for chicken breast")
        else:
            print("  No amino acid data found")

    # ── 7. Calorie distribution ──
    print_section("7. Calorie Distribution (per 100g)")
    cal = df["calories_per_100g"]
    print(f"  Min:    {cal.min():.1f}")
    print(f"  Q25:    {cal.quantile(0.25):.1f}")
    print(f"  Median: {cal.median():.1f}")
    print(f"  Q75:    {cal.quantile(0.75):.1f}")
    print(f"  Max:    {cal.max():.1f}")
    print(f"  Mean:   {cal.mean():.1f}")

    suspicious_high = df[cal > 900]
    if len(suspicious_high) > 0:
        print(f"\n  WARNING: {len(suspicious_high)} foods with >900 cal/100g:")
        for _, row in suspicious_high.head(5).iterrows():
            print(f"    {row['name'][:50]} = {row['calories_per_100g']:.0f} cal")

    # ── 8. Spot-checks ──
    print_section("8. Spot-Check: Common Foods")
    name_lower = df["name_normalized"]
    for query in SPOT_CHECK_FOODS:
        matches = df[name_lower.str.contains(query, case=False, na=False)]
        n = len(matches)
        print(f"\n  '{query}' -> {n} matches")
        if n > 0:
            for _, row in matches.head(3).iterrows():
                src = row["source"]
                brand = f" ({row['brand'][:15]})" if pd.notna(row.get("brand")) and row.get("brand") else ""
                print(
                    f"    [{src:14s}] {row['name'][:45]:45s}{brand} "
                    f"cal={row['calories_per_100g']:>7.1f}  "
                    f"P={row['protein_per_100g']:>5.1f}  "
                    f"F={row['fat_per_100g']:>5.1f}  "
                    f"C={row['carbs_per_100g']:>5.1f}"
                )

    # ── 9. Allergens coverage ──
    print_section("9. Allergens & Diet Labels")
    if "allergens" in df.columns:
        has_allergens = df["allergens"].notna().sum()
        pct = has_allergens / len(df) * 100
        print(f"  Foods with allergens: {has_allergens:,} ({pct:.1f}%)")

        # Top allergens
        allergen_counts: dict[str, int] = {}
        for val in df["allergens"].dropna():
            try:
                tags = json.loads(val)
                for tag in tags:
                    allergen_counts[tag] = allergen_counts.get(tag, 0) + 1
            except (json.JSONDecodeError, TypeError):
                pass
        if allergen_counts:
            print(f"\n  Top 10 allergens:")
            for tag, count in sorted(allergen_counts.items(), key=lambda x: -x[1])[:10]:
                print(f"    {tag:30s} {count:>8,}")

    if "diet_labels" in df.columns:
        has_labels = df["diet_labels"].notna().sum()
        pct = has_labels / len(df) * 100
        print(f"\n  Foods with diet labels: {has_labels:,} ({pct:.1f}%)")

        label_counts: dict[str, int] = {}
        for val in df["diet_labels"].dropna():
            try:
                tags = json.loads(val)
                for tag in tags:
                    label_counts[tag] = label_counts.get(tag, 0) + 1
            except (json.JSONDecodeError, TypeError):
                pass
        if label_counts:
            print(f"\n  Top 10 diet labels:")
            for tag, count in sorted(label_counts.items(), key=lambda x: -x[1])[:10]:
                print(f"    {tag:30s} {count:>8,}")

    # ── 10. NOVA group distribution ──
    print_section("10. NOVA Group Distribution")
    if "nova_group" in df.columns:
        nova = df["nova_group"].dropna()
        print(f"  Foods with NOVA group: {len(nova):,} ({len(nova)/len(df)*100:.1f}%)")
        if len(nova) > 0:
            for grp, count in nova.value_counts().sort_index().items():
                labels = {1: "Unprocessed", 2: "Processed ingredients", 3: "Processed", 4: "Ultra-processed"}
                label = labels.get(int(grp), "Unknown")
                print(f"    NOVA {int(grp)} ({label:25s}): {count:>8,}")

    # ── 11. Inflammatory score distribution ──
    print_section("11. Inflammatory Score Distribution")
    if "inflammatory_score" in df.columns:
        inf = df["inflammatory_score"].dropna()
        print(f"  Foods with score: {len(inf):,} ({len(inf)/len(df)*100:.1f}%)")
        if len(inf) > 0:
            print(f"  Min:    {inf.min():.3f}")
            print(f"  Q25:    {inf.quantile(0.25):.3f}")
            print(f"  Median: {inf.median():.3f}")
            print(f"  Q75:    {inf.quantile(0.75):.3f}")
            print(f"  Max:    {inf.max():.3f}")

    if "inflammatory_category" in df.columns:
        cats = df["inflammatory_category"].dropna().value_counts()
        print(f"\n  Category distribution:")
        for cat, count in cats.items():
            pct = count / len(df) * 100
            print(f"    {str(cat):35s} {count:>8,}  ({pct:.1f}%)")

    # Spot-check inflammatory scores
    print(f"\n  Spot-checks:")
    for query, expected_dir in INFLAMMATORY_SPOT_CHECKS.items():
        matches = df[df["name_normalized"].str.contains(query, case=False, na=False)]
        if len(matches) > 0:
            row = matches.iloc[0]
            score = row.get("inflammatory_score")
            cat = row.get("inflammatory_category", "N/A")
            if pd.notna(score):
                status = "PASS" if (expected_dir == "anti" and score < 0) or (expected_dir == "inflammatory" and score > 0) else "CHECK"
                print(f"    '{row['name'][:40]}': score={score:.3f} cat={cat} [{status}]")

    # ── 12. Image URL coverage ──
    print_section("12. Image URL Coverage")
    if "image_url" in df.columns:
        has_img = df["image_url"].notna().sum()
        pct = has_img / len(df) * 100
        print(f"  Foods with image_url: {has_img:,} ({pct:.1f}%)")
        # Show a few sample URLs
        samples = df[df["image_url"].notna()].head(3)
        for _, row in samples.iterrows():
            print(f"    {row['name'][:40]}: {row['image_url'][:80]}")

    # ── 13. Data completeness summary ──
    print_section("13. Completeness Summary")
    has_serving = df["serving_weight_g"].notna().sum()
    has_micros = df["micronutrients_per_100g"].notna().sum()
    has_brand = df["brand"].notna().sum()
    has_category = df["category"].notna().sum()
    has_per_serving = df["calories_per_serving"].notna().sum() if "calories_per_serving" in df.columns else 0
    has_food_group = df["food_group"].notna().sum() if "food_group" in df.columns else 0
    has_ingredients = df["ingredients_text"].notna().sum() if "ingredients_text" in df.columns else 0

    print(f"  Foods with serving info:    {has_serving:>8,} / {len(df):,}  ({has_serving/len(df)*100:.1f}%)")
    print(f"  Foods with micronutrients:  {has_micros:>8,} / {len(df):,}  ({has_micros/len(df)*100:.1f}%)")
    print(f"  Foods with brand:           {has_brand:>8,} / {len(df):,}  ({has_brand/len(df)*100:.1f}%)")
    print(f"  Foods with category:        {has_category:>8,} / {len(df):,}  ({has_category/len(df)*100:.1f}%)")
    print(f"  Foods with food_group:      {has_food_group:>8,} / {len(df):,}  ({has_food_group/len(df)*100:.1f}%)")
    print(f"  Foods with per-serving cal: {has_per_serving:>8,} / {len(df):,}  ({has_per_serving/len(df)*100:.1f}%)")
    print(f"  Foods with ingredients:     {has_ingredients:>8,} / {len(df):,}  ({has_ingredients/len(df)*100:.1f}%)")

    # Data completeness score distribution
    if "data_completeness" in df.columns:
        dc = df["data_completeness"].dropna()
        print(f"\n  Data completeness score:")
        print(f"    Mean:   {dc.mean():.3f}")
        print(f"    Median: {dc.median():.3f}")
        print(f"    Min:    {dc.min():.3f}")
        print(f"    Max:    {dc.max():.3f}")

    # ── 14. Dedup stats ──
    print_section("14. Dedup Statistics")
    if "dedup_rank" in df.columns and "is_primary" in df.columns:
        n_primary = df["is_primary"].sum()
        n_dups = (~df["is_primary"]).sum()
        print(f"  Primary entries: {n_primary:,}")
        print(f"  Duplicate entries: {n_dups:,}")
        print(f"  Dedup ratio: {n_dups / len(df) * 100:.1f}%")

        # Show some examples of dedup groups
        if n_dups > 0:
            multi = df.groupby("dedup_key").filter(lambda x: len(x) > 1)
            sample_keys = multi["dedup_key"].unique()[:3]
            print(f"\n  Sample dedup groups:")
            for key in sample_keys:
                group = df[df["dedup_key"] == key]
                print(f"\n    Key: '{key}'")
                for _, row in group.iterrows():
                    primary = "*" if row["is_primary"] else " "
                    print(f"      {primary} [{row['source']:14s}] {row['name'][:50]} rank={row['dedup_rank']}")
    else:
        print("  No dedup columns found (using deduped file)")


def main():
    print("=" * 60)
    print("Food Database Validation Report")
    print("=" * 60)

    # Try raw file first (has dedup columns), fall back to deduped/final
    raw_path = OUTPUT_DIR / "food_database_raw.parquet"
    deduped_path = OUTPUT_DIR / "food_database_deduped.parquet"
    final_path = OUTPUT_DIR / "food_database_final.parquet"

    if raw_path.exists():
        print(f"Using RAW file: {raw_path}")
        df = pd.read_parquet(raw_path)
    elif deduped_path.exists():
        print(f"Using DEDUPED file: {deduped_path}")
        df = pd.read_parquet(deduped_path)
    elif final_path.exists():
        print(f"Using FINAL file: {final_path}")
        df = pd.read_parquet(final_path)
    else:
        print(f"ERROR: No database file found. Run merge_and_dedup.py first.")
        sys.exit(1)

    # Tee output to both console and file
    tee = TeeWriter()
    old_stdout = sys.stdout
    sys.stdout = tee

    try:
        validate_final(df)
    finally:
        sys.stdout = old_stdout

    # Save report
    report_path = OUTPUT_DIR / "validation_report.txt"
    report_path.write_text(tee.get_value())
    print(f"\nReport saved: {report_path}")


if __name__ == "__main__":
    main()
