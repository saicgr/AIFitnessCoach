"""
Process USDA FoodData Central CSVs into a clean parquet.

Source: https://fdc.nal.usda.gov/download-datasets

Extracts foundation_food + sr_legacy_food + survey_fndds_food (~13-16K foods),
skipping branded foods (~2M).  Chunks the 1.7 GB food_nutrient.csv to stay
memory-friendly.

Usage:
    python food_curation/process_usda.py
"""

import json
import sys
from pathlib import Path

import pandas as pd
from tqdm import tqdm

# Allow running from project root
sys.path.insert(0, str(Path(__file__).parent))
from config import (
    AMINO_ACID_KEYS,
    MACRO_COLUMNS,
    MICRO_KEYS,
    OUTPUT_DIR,
    USDA_ALL_NUTRIENT_IDS,
    USDA_DIR,
    USDA_MACRO_IDS,
    USDA_MICRO_IDS,
    USDA_TARGET_DATA_TYPES,
)
from inflammatory_score import calculate_inflammatory_score
from normalize import normalize_food_name, normalize_food_name_display


NUTRIENT_CHUNK_SIZE = 500_000


def load_category_map() -> dict[int, str]:
    """Load food_category.csv -> {id: description}."""
    df = pd.read_csv(USDA_DIR / "food_category.csv")
    return dict(zip(df["id"], df["description"]))


def load_target_foods(category_map: dict[int, str]) -> pd.DataFrame:
    """Load food.csv, filter to target data_types."""
    print("Loading food.csv ...")
    df = pd.read_csv(
        USDA_DIR / "food.csv",
        dtype={"fdc_id": int, "data_type": str, "food_category_id": str},
    )
    total = len(df)
    df = df[df["data_type"].isin(USDA_TARGET_DATA_TYPES)].copy()
    print(f"  {total:,} total -> {len(df):,} target foods")

    # Map category id -> name (target foods have numeric IDs)
    df["food_category_id_int"] = pd.to_numeric(df["food_category_id"], errors="coerce")
    df["category"] = df["food_category_id_int"].map(category_map)
    df = df.drop(columns=["food_category_id_int"])
    return df


def build_nutrient_index(target_fdc_ids: set[int]) -> dict[int, dict[str, float]]:
    """Chunk-read food_nutrient.csv, keep only target nutrients for target foods.

    Returns {fdc_id: {canonical_col: amount}}.
    """
    target_nutrient_ids = set(USDA_ALL_NUTRIENT_IDS.keys())
    result: dict[int, dict[str, float]] = {}

    path = USDA_DIR / "food_nutrient.csv"
    n_chunks = 0
    n_kept = 0

    print("Chunking food_nutrient.csv ...")
    for chunk in tqdm(
        pd.read_csv(
            path,
            chunksize=NUTRIENT_CHUNK_SIZE,
            usecols=["fdc_id", "nutrient_id", "amount"],
        ),
        desc="food_nutrient chunks",
    ):
        n_chunks += 1
        # Drop rows with missing fdc_id or nutrient_id
        chunk = chunk.dropna(subset=["fdc_id", "nutrient_id"])
        chunk["fdc_id"] = chunk["fdc_id"].astype(int)
        chunk["nutrient_id"] = chunk["nutrient_id"].astype(int)

        # Filter to our foods AND our nutrients
        mask = chunk["fdc_id"].isin(target_fdc_ids) & chunk["nutrient_id"].isin(target_nutrient_ids)
        filtered = chunk.loc[mask]
        n_kept += len(filtered)

        for _, row in filtered.iterrows():
            fdc_id = int(row["fdc_id"])
            nid = int(row["nutrient_id"])
            amount = float(row["amount"]) if pd.notna(row["amount"]) else 0.0
            col_name = USDA_ALL_NUTRIENT_IDS[nid]
            result.setdefault(fdc_id, {})[col_name] = amount

    print(f"  {n_chunks} chunks processed, {n_kept:,} nutrient rows kept for {len(result):,} foods")
    return result


def load_portions(target_fdc_ids: set[int]) -> dict[int, dict]:
    """Load food_portion.csv -> first portion per fdc_id.

    Returns {fdc_id: {"description": str, "gram_weight": float}}.
    """
    print("Loading food_portion.csv ...")
    df = pd.read_csv(USDA_DIR / "food_portion.csv")
    df = df.dropna(subset=["fdc_id"])
    df["fdc_id"] = df["fdc_id"].astype(int)
    df = df[df["fdc_id"].isin(target_fdc_ids)].copy()

    # Keep first portion per food (lowest seq_num)
    df = df.sort_values(["fdc_id", "seq_num"])
    df = df.drop_duplicates(subset="fdc_id", keep="first")

    result = {}
    for _, row in df.iterrows():
        fdc_id = int(row["fdc_id"])
        gram_weight = float(row["gram_weight"]) if pd.notna(row.get("gram_weight")) else None
        # Build description from modifier / portion_description / amount + measure_unit
        parts = []
        if pd.notna(row.get("amount")):
            parts.append(str(row["amount"]))
        if pd.notna(row.get("modifier")):
            parts.append(str(row["modifier"]))
        elif pd.notna(row.get("portion_description")):
            parts.append(str(row["portion_description"]))
        desc = " ".join(parts).strip() if parts else None
        result[fdc_id] = {"description": desc, "gram_weight": gram_weight}

    print(f"  {len(result):,} portions loaded")
    return result


def build_dataframe(
    foods_df: pd.DataFrame,
    nutrient_index: dict[int, dict[str, float]],
    portions: dict[int, dict],
) -> pd.DataFrame:
    """Combine foods + nutrients + portions into the canonical schema."""
    rows = []
    for _, food in tqdm(foods_df.iterrows(), total=len(foods_df), desc="Building rows"):
        fdc_id = int(food["fdc_id"])
        nutrients = nutrient_index.get(fdc_id, {})
        portion = portions.get(fdc_id, {})

        # Skip foods with no calorie data
        calories = nutrients.get("calories", 0.0)
        if calories <= 0:
            continue

        # Macros per 100g
        macros_100g = {col: nutrients.get(col, 0.0) for col in MACRO_COLUMNS}

        # Micros per 100g
        micros_100g = {}
        for key in MICRO_KEYS:
            val = nutrients.get(key)
            if val is not None and val > 0:
                micros_100g[key] = round(val, 4)

        # Amino acids per 100g (USDA stores in g, convert to mg)
        for key in AMINO_ACID_KEYS:
            val = nutrients.get(key)
            if val is not None and val > 0:
                micros_100g[key] = round(val * 1000, 4)

        # Serving info
        serving_desc = portion.get("description")
        serving_wt = portion.get("gram_weight")

        # Per-serving macros
        per_serving = {}
        if serving_wt and serving_wt > 0:
            factor = serving_wt / 100.0
            per_serving = {
                "calories_per_serving": round(macros_100g["calories"] * factor, 1),
                "protein_per_serving": round(macros_100g["protein"] * factor, 2),
                "fat_per_serving": round(macros_100g["fat"] * factor, 2),
                "carbs_per_serving": round(macros_100g["carbs"] * factor, 2),
            }

        # Inflammatory score
        macros_dict = {col: macros_100g[col] for col in MACRO_COLUMNS}
        inf_score, inf_cat = calculate_inflammatory_score(macros_dict, micros_100g)

        # Audit columns
        processing_notes = []
        if not serving_wt or serving_wt <= 0:
            processing_notes.append("no serving info")
        if not micros_100g:
            processing_notes.append("no micros")

        non_zero_macros = sum(1 for col in MACRO_COLUMNS if macros_100g.get(col, 0) > 0)
        completeness_fields = [
            food.get("description"), macros_100g.get("calories"),
            macros_100g.get("protein"), macros_100g.get("fat"),
            macros_100g.get("carbs"), macros_100g.get("fiber"),
            macros_100g.get("sugar"), serving_wt, food.get("category"),
        ]
        data_completeness = round(
            sum(1 for v in completeness_fields if v is not None and v != 0 and v != "") / 9, 2
        )

        name = str(food["description"]).strip()
        row = {
            "name": name,
            "name_normalized": normalize_food_name_display(name),
            "source": "usda",
            "source_id": str(fdc_id),
            "data_type": food["data_type"],
            "brand": None,
            "category": food.get("category"),
            "food_group": food.get("category"),
            "calories_per_100g": round(macros_100g["calories"], 1),
            "protein_per_100g": round(macros_100g["protein"], 2),
            "fat_per_100g": round(macros_100g["fat"], 2),
            "carbs_per_100g": round(macros_100g["carbs"], 2),
            "fiber_per_100g": round(macros_100g["fiber"], 2),
            "sugar_per_100g": round(macros_100g["sugar"], 2),
            "micronutrients_per_100g": json.dumps(micros_100g) if micros_100g else None,
            "serving_description": serving_desc,
            "serving_weight_g": serving_wt,
            **per_serving,
            # OFF-specific fields (placeholders for USDA)
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
            "nutrient_count": non_zero_macros + len(micros_100g),
            "micro_count": len(micros_100g),
            "has_serving": serving_wt is not None and serving_wt > 0,
            "data_completeness": data_completeness,
            "processing_notes": "; ".join(processing_notes) if processing_notes else None,
            "source_url": f"https://fdc.nal.usda.gov/food-details/{fdc_id}/nutrients",
        }
        rows.append(row)

    df = pd.DataFrame(rows)
    # Ensure all output columns exist
    for col in ["calories_per_serving", "protein_per_serving", "fat_per_serving", "carbs_per_serving"]:
        if col not in df.columns:
            df[col] = None
    return df


def main():
    print("=" * 60)
    print("USDA FoodData Central Processing")
    print("=" * 60)

    if not USDA_DIR.exists():
        print(f"ERROR: USDA directory not found: {USDA_DIR}")
        sys.exit(1)

    category_map = load_category_map()
    print(f"  {len(category_map)} food categories loaded")

    foods_df = load_target_foods(category_map)
    target_fdc_ids = set(foods_df["fdc_id"].astype(int))

    nutrient_index = build_nutrient_index(target_fdc_ids)
    portions = load_portions(target_fdc_ids)
    df = build_dataframe(foods_df, nutrient_index, portions)

    out_path = OUTPUT_DIR / "usda_processed.parquet"
    df.to_parquet(out_path, index=False)
    print(f"\nSaved {len(df):,} USDA foods -> {out_path}")

    # Quick stats
    for dt in USDA_TARGET_DATA_TYPES:
        n = (df["data_type"] == dt).sum()
        print(f"  {dt}: {n:,}")
    print(f"  With micros: {df['micronutrients_per_100g'].notna().sum():,}")
    print(f"  With serving: {df['serving_weight_g'].notna().sum():,}")


if __name__ == "__main__":
    main()
