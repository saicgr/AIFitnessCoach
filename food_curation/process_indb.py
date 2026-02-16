"""
Process Indian Nutrient Database (INDB) Excel into a clean parquet.

Source: Anuvaad INDB 2024.11 (1,014 Indian foods with comprehensive
micronutrient profiles including vitamins D2/D3, K1/K2, fatty acid breakdown).

Usage:
    python food_curation/process_indb.py
"""

import json
import sys
from pathlib import Path

import pandas as pd
from tqdm import tqdm

sys.path.insert(0, str(Path(__file__).parent))
from config import (
    INDB_EXTRA_MICROS,
    INDB_MACRO_MAP,
    INDB_MICRO_MAP,
    INDB_SERVING_PREFIX,
    INDB_XLSX,
    MACRO_COLUMNS,
    OUTPUT_DIR,
)
from inflammatory_score import calculate_inflammatory_score
from normalize import normalize_food_name_display


def safe_float(val) -> float:
    """Convert a value to float, returning 0.0 on failure."""
    if pd.isna(val):
        return 0.0
    try:
        return float(val)
    except (ValueError, TypeError):
        return 0.0


def build_micros(row):
    """Build micronutrients dict from INDB row.

    Handles:
    - Standard micro columns (INDB_MICRO_MAP)
    - Vitamin D: vitd2_ug + vitd3_ug combined, * 40 for IU
    - Extra micros (INDB_EXTRA_MICROS) as bonus keys
    """
    micros: dict[str, float] = {}

    # Standard micros
    for indb_col, (canonical, multiplier) in INDB_MICRO_MAP.items():
        val = safe_float(row.get(indb_col))
        if val > 0:
            micros[canonical] = round(val * multiplier, 4)

    # Vitamin D: combine D2 + D3 (in ug), convert to IU (* 40)
    vitd2 = safe_float(row.get("vitd2_ug"))
    vitd3 = safe_float(row.get("vitd3_ug"))
    vitd_total_ug = vitd2 + vitd3
    if vitd_total_ug > 0:
        micros["vitamin_d_iu"] = round(vitd_total_ug * 40, 4)

    # Extra micros unique to INDB
    for indb_col, canonical in INDB_EXTRA_MICROS.items():
        val = safe_float(row.get(indb_col))
        if val > 0:
            micros[canonical] = round(val, 4)

    return micros


def main():
    print("=" * 60)
    print("Indian INDB Processing")
    print("=" * 60)

    if not INDB_XLSX.exists():
        print(f"ERROR: INDB file not found: {INDB_XLSX}")
        sys.exit(1)

    print(f"Reading {INDB_XLSX} ...")
    df_raw = pd.read_excel(INDB_XLSX, engine="openpyxl")
    print(f"  {len(df_raw):,} rows, {len(df_raw.columns)} columns")

    rows = []
    for _, row in tqdm(df_raw.iterrows(), total=len(df_raw), desc="Processing INDB"):
        name = str(row.get("food_name", "")).strip()
        if not name:
            continue

        # Macros per 100g
        macros = {}
        for indb_col, canonical in INDB_MACRO_MAP.items():
            macros[canonical] = safe_float(row.get(indb_col))

        # Skip if no calorie data
        if macros.get("calories", 0) <= 0:
            continue

        # Micros per 100g
        micros = build_micros(row)

        # Serving info
        serving_desc = row.get("servings_unit")
        if isinstance(serving_desc, str) and serving_desc.strip():
            serving_desc = serving_desc.strip()
        else:
            serving_desc = None

        # Per-serving values from unit_serving_ columns
        serving_cal = safe_float(row.get(f"{INDB_SERVING_PREFIX}energy_kcal"))
        serving_protein = safe_float(row.get(f"{INDB_SERVING_PREFIX}protein_g"))
        serving_fat = safe_float(row.get(f"{INDB_SERVING_PREFIX}fat_g"))
        serving_carbs = safe_float(row.get(f"{INDB_SERVING_PREFIX}carb_g"))

        # Estimate serving weight from calorie ratio (per_serving / per_100g * 100)
        serving_wt = None
        if macros["calories"] > 0 and serving_cal > 0:
            serving_wt = round((serving_cal / macros["calories"]) * 100, 1)

        food_code = str(row.get("food_code", "")).strip()
        source_type = str(row.get("primarysource", "")).strip() or "indb"

        # Inflammatory score
        macros_dict = {col: macros[col] for col in ["calories", "protein", "fat", "carbs", "fiber", "sugar"]}
        inf_score, inf_cat = calculate_inflammatory_score(macros_dict, micros)

        # Audit: count non-zero macro values + micro keys
        non_zero_macros = sum(1 for v in macros.values() if v > 0)
        nutrient_count = non_zero_macros + len(micros)

        # Data completeness: count non-null of key fields / 8
        completeness_fields = [name, macros.get("calories"), macros.get("protein"),
                               macros.get("fat"), macros.get("carbs"),
                               macros.get("fiber"), macros.get("sugar"), serving_wt]
        data_completeness = round(sum(1 for f in completeness_fields if f is not None and f != 0) / 8, 3)

        # Processing notes
        notes = []
        if macros.get("calories", 0) > 0 and macros.get("protein", 0) == 0 and macros.get("fat", 0) == 0 and macros.get("carbs", 0) == 0:
            notes.append("has_calories_but_no_macros")
        if serving_wt is not None and serving_wt > 500:
            notes.append("large_serving_estimate")
        if not micros:
            notes.append("no_micronutrients")
        processing_notes = "; ".join(notes) if notes else None

        rows.append({
            "name": name,
            "name_normalized": normalize_food_name_display(name),
            "source": "indb",
            "source_id": food_code,
            "data_type": source_type,
            "brand": None,
            "category": None,  # INDB doesn't have food categories
            "food_group": None,  # INDB doesn't have food groups
            "calories_per_100g": round(macros["calories"], 1),
            "protein_per_100g": round(macros["protein"], 2),
            "fat_per_100g": round(macros["fat"], 2),
            "carbs_per_100g": round(macros["carbs"], 2),
            "fiber_per_100g": round(macros.get("fiber", 0.0), 2),
            "sugar_per_100g": round(macros.get("sugar", 0.0), 2),
            "micronutrients_per_100g": json.dumps(micros) if micros else None,
            "serving_description": serving_desc,
            "serving_weight_g": serving_wt,
            "calories_per_serving": round(serving_cal, 1) if serving_cal > 0 else None,
            "protein_per_serving": round(serving_protein, 2) if serving_protein > 0 else None,
            "fat_per_serving": round(serving_fat, 2) if serving_fat > 0 else None,
            "carbs_per_serving": round(serving_carbs, 2) if serving_carbs > 0 else None,
            # OFF-specific fields (not available in INDB)
            "allergens": None,
            "diet_labels": None,
            "nova_group": None,
            "nutriscore_score": None,
            "traces": None,
            "ingredients_text": None,
            "image_url": None,
            # Inflammatory score
            "inflammatory_score": inf_score,
            "inflammatory_category": inf_cat,
            # Audit columns
            "nutrient_count": nutrient_count,
            "micro_count": len(micros),
            "has_serving": serving_wt is not None,
            "data_completeness": data_completeness,
            "processing_notes": processing_notes,
            "source_url": None,  # INDB has no web source
        })

    df = pd.DataFrame(rows)

    out_path = OUTPUT_DIR / "indb_processed.parquet"
    df.to_parquet(out_path, index=False)
    print(f"\nSaved {len(df):,} INDB foods -> {out_path}")

    # Quick stats
    print(f"  With micros: {df['micronutrients_per_100g'].notna().sum():,}")
    print(f"  With serving: {df['serving_weight_g'].notna().sum():,}")
    micro_counts = df["micronutrients_per_100g"].dropna().apply(lambda x: len(json.loads(x)))
    if len(micro_counts) > 0:
        print(f"  Avg micros per food: {micro_counts.mean():.1f}")
        print(f"  Max micros per food: {micro_counts.max()}")


if __name__ == "__main__":
    main()
