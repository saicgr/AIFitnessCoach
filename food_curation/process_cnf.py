"""
Process Canadian Nutrient File (CNF) CSVs into a clean parquet.

Source: https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/nutrient-data.html

Extracts ~5690 foods from the CNF dataset, maps nutrients to our canonical
schema, and outputs a parquet file ready for merging.

Usage:
    python food_curation/process_cnf.py
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
    CNF_AMINO_ACID_IDS,
    CNF_DIR,
    CNF_EXTRA_MICRO_IDS,
    CNF_MACRO_IDS,
    CNF_MICRO_IDS,
    MACRO_COLUMNS,
    MICRO_KEYS,
    OUTPUT_DIR,
)
from inflammatory_score import calculate_inflammatory_score
from normalize import normalize_food_name_display

NUTRIENT_CHUNK_SIZE = 100_000

# All CNF nutrient IDs we want to keep (flat set for fast filtering)
_ALL_WANTED_IDS = (
    set(CNF_MACRO_IDS.keys())
    | set(CNF_MICRO_IDS.keys())
    | set(CNF_EXTRA_MICRO_IDS.keys())
    | set(CNF_AMINO_ACID_IDS.keys())
)


def load_food_groups() -> dict[int, str]:
    """Load FOOD GROUP.csv -> {FoodGroupID: FoodGroupName}."""
    print("Loading FOOD GROUP.csv ...")
    df = pd.read_csv(CNF_DIR / "FOOD GROUP.csv", encoding="latin-1")
    mapping = dict(zip(df["FoodGroupID"], df["FoodGroupName"]))
    print(f"  {len(mapping)} food groups loaded")
    return mapping


def load_foods(group_map: dict[int, str]) -> pd.DataFrame:
    """Load FOOD NAME.csv, attach group names."""
    print("Loading FOOD NAME.csv ...")
    df = pd.read_csv(
        CNF_DIR / "FOOD NAME.csv",
        dtype={"FoodID": int, "FoodGroupID": int},
        encoding="latin-1",
    )
    total = len(df)
    df["food_group"] = df["FoodGroupID"].map(group_map)
    print(f"  {total:,} foods loaded")
    return df


def build_nutrient_index(target_food_ids: set[int]) -> dict[int, dict[int, float]]:
    """Chunk-read NUTRIENT AMOUNT.csv, keep only wanted nutrients for target foods.

    Returns {food_id: {nutrient_id: amount}}.
    """
    result: dict[int, dict[int, float]] = {}
    path = CNF_DIR / "NUTRIENT AMOUNT.csv"
    n_chunks = 0
    n_kept = 0

    print("Chunking NUTRIENT AMOUNT.csv ...")
    for chunk in tqdm(
        pd.read_csv(
            path,
            chunksize=NUTRIENT_CHUNK_SIZE,
            usecols=["FoodID", "NutrientID", "NutrientValue"],
            encoding="latin-1",
        ),
        desc="nutrient chunks",
    ):
        n_chunks += 1
        chunk = chunk.dropna(subset=["FoodID", "NutrientID"])
        chunk["FoodID"] = chunk["FoodID"].astype(int)
        chunk["NutrientID"] = chunk["NutrientID"].astype(int)

        mask = chunk["FoodID"].isin(target_food_ids) & chunk["NutrientID"].isin(_ALL_WANTED_IDS)
        filtered = chunk.loc[mask]
        n_kept += len(filtered)

        for _, row in filtered.iterrows():
            food_id = int(row["FoodID"])
            nid = int(row["NutrientID"])
            amount = float(row["NutrientValue"]) if pd.notna(row["NutrientValue"]) else 0.0
            result.setdefault(food_id, {})[nid] = amount

    print(f"  {n_chunks} chunks processed, {n_kept:,} nutrient rows kept for {len(result):,} foods")
    return result


def load_servings(target_food_ids: set[int]) -> dict[int, dict]:
    """Load CONVERSION FACTOR.csv + MEASURE NAME.csv -> first serving per food.

    Returns {food_id: {"description": str, "serving_weight_g": float}}.
    CNF serving weight = 100g * ConversionFactorValue.
    """
    print("Loading MEASURE NAME.csv ...")
    measures = pd.read_csv(CNF_DIR / "MEASURE NAME.csv", encoding="latin-1")
    measure_map = dict(zip(measures["MeasureID"], measures["MeasureDescription"]))
    print(f"  {len(measure_map)} measures loaded")

    print("Loading CONVERSION FACTOR.csv ...")
    cf = pd.read_csv(CNF_DIR / "CONVERSION FACTOR.csv", encoding="latin-1")
    cf = cf.dropna(subset=["FoodID", "MeasureID", "ConversionFactorValue"])
    cf["FoodID"] = cf["FoodID"].astype(int)
    cf["MeasureID"] = cf["MeasureID"].astype(int)
    cf = cf[cf["FoodID"].isin(target_food_ids)].copy()

    # Keep first conversion factor per food
    cf = cf.drop_duplicates(subset="FoodID", keep="first")

    result = {}
    for _, row in cf.iterrows():
        food_id = int(row["FoodID"])
        cfv = float(row["ConversionFactorValue"])
        measure_id = int(row["MeasureID"])
        desc = measure_map.get(measure_id)
        result[food_id] = {
            "description": desc,
            "serving_weight_g": round(100.0 * cfv, 2),
        }

    print(f"  {len(result):,} servings loaded")
    return result


def build_dataframe(
    foods_df: pd.DataFrame,
    nutrient_index: dict[int, dict[int, float]],
    servings: dict[int, dict],
) -> pd.DataFrame:
    """Combine foods + nutrients + servings into the canonical schema."""
    # Pre-build extra micro keys list
    extra_micro_keys = [v[0] for v in CNF_EXTRA_MICRO_IDS.values()]

    rows = []
    for _, food in tqdm(foods_df.iterrows(), total=len(foods_df), desc="Building rows"):
        food_id = int(food["FoodID"])
        raw_nutrients = nutrient_index.get(food_id, {})
        serving = servings.get(food_id, {})

        # Extract macros per 100g using CNF nutrient IDs
        macros_100g = {}
        for nid, col_name in CNF_MACRO_IDS.items():
            macros_100g[col_name] = raw_nutrients.get(nid, 0.0)

        # Skip foods with no calorie data
        calories = macros_100g.get("calories", 0.0)
        if calories <= 0:
            continue

        # Extract micros per 100g (canonical 14-key set)
        micros_100g = {}
        for nid, (key, multiplier) in CNF_MICRO_IDS.items():
            val = raw_nutrients.get(nid)
            if val is not None and val > 0:
                micros_100g[key] = round(val * multiplier, 4)

        # Extract extra micros
        for nid, (key, multiplier) in CNF_EXTRA_MICRO_IDS.items():
            val = raw_nutrients.get(nid)
            if val is not None and val > 0:
                micros_100g[key] = round(val * multiplier, 4)

        # Extract amino acids (CNF stores in grams, multiply by 1000 for mg)
        for nid, (key, multiplier) in CNF_AMINO_ACID_IDS.items():
            val = raw_nutrients.get(nid)
            if val is not None and val > 0:
                micros_100g[key] = round(val * multiplier, 4)

        # Serving info
        serving_desc = serving.get("description")
        serving_wt = serving.get("serving_weight_g")
        has_serving = serving_wt is not None and serving_wt > 0

        # Per-serving macros
        per_serving = {}
        if has_serving:
            factor = serving_wt / 100.0
            per_serving = {
                "calories_per_serving": round(macros_100g["calories"] * factor, 1),
                "protein_per_serving": round(macros_100g["protein"] * factor, 2),
                "fat_per_serving": round(macros_100g["fat"] * factor, 2),
                "carbs_per_serving": round(macros_100g["carbs"] * factor, 2),
            }

        # Inflammatory score
        score, category = calculate_inflammatory_score(macros_100g, micros_100g)

        # Audit columns
        non_zero_macros = sum(1 for v in macros_100g.values() if v and v > 0)
        non_zero_micros = sum(
            1 for k, v in micros_100g.items()
            if v and v > 0 and k in set(MICRO_KEYS) | set(extra_micro_keys)
        )
        nutrient_count = non_zero_macros + non_zero_micros
        micro_count = non_zero_micros

        # Data completeness: core fields = name, calories, protein, fat, carbs, fiber, sugar, serving_weight_g, category
        core_filled = 0
        core_total = 9
        name = str(food["FoodDescription"]).strip()
        if name:
            core_filled += 1
        if macros_100g.get("calories", 0) > 0:
            core_filled += 1
        if macros_100g.get("protein", 0) > 0:
            core_filled += 1
        if macros_100g.get("fat", 0) > 0:
            core_filled += 1
        if macros_100g.get("carbs", 0) > 0:
            core_filled += 1
        if macros_100g.get("fiber", 0) > 0:
            core_filled += 1
        if macros_100g.get("sugar", 0) > 0:
            core_filled += 1
        if has_serving:
            core_filled += 1
        if pd.notna(food.get("food_group")):
            core_filled += 1
        data_completeness = round(core_filled / core_total, 3)

        # Processing notes
        notes = []
        if macros_100g.get("protein", 0) == 0:
            notes.append("missing protein")
        if not has_serving:
            notes.append("no serving info")
        if micro_count == 0:
            notes.append("no micros")
        processing_notes = "; ".join(notes) if notes else None

        row = {
            "name": name,
            "name_normalized": normalize_food_name_display(name),
            "source": "cnf",
            "source_id": str(food_id),
            "data_type": "cnf",
            "brand": None,
            "category": food.get("food_group"),
            "food_group": food.get("food_group"),
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
            # OFF-specific fields (null for CNF)
            "allergens": None,
            "diet_labels": None,
            "nova_group": None,
            "nutriscore_score": None,
            "traces": None,
            "ingredients_text": None,
            "image_url": None,
            # Inflammatory score
            "inflammatory_score": score,
            "inflammatory_category": category,
            # Audit columns
            "nutrient_count": nutrient_count,
            "micro_count": micro_count,
            "has_serving": has_serving,
            "data_completeness": data_completeness,
            "processing_notes": processing_notes,
            "source_url": None,
        }
        rows.append(row)

    df = pd.DataFrame(rows)
    # Ensure per-serving columns exist even if no food had servings
    for col in ["calories_per_serving", "protein_per_serving", "fat_per_serving", "carbs_per_serving"]:
        if col not in df.columns:
            df[col] = None
    return df


def main():
    print("=" * 60)
    print("Canadian Nutrient File (CNF) Processing")
    print("=" * 60)

    if not CNF_DIR.exists():
        print(f"ERROR: CNF directory not found: {CNF_DIR}")
        sys.exit(1)

    group_map = load_food_groups()
    foods_df = load_foods(group_map)
    target_food_ids = set(foods_df["FoodID"].astype(int))

    nutrient_index = build_nutrient_index(target_food_ids)
    servings = load_servings(target_food_ids)
    df = build_dataframe(foods_df, nutrient_index, servings)

    out_path = OUTPUT_DIR / "cnf_processed.parquet"
    df.to_parquet(out_path, index=False)
    print(f"\nSaved {len(df):,} CNF foods -> {out_path}")

    # Stats
    print(f"\n--- Stats ---")
    print(f"  Total foods with calories: {len(df):,}")
    print(f"  With micros:   {df['micronutrients_per_100g'].notna().sum():,}")
    print(f"  With serving:  {df['serving_weight_g'].notna().sum():,}")
    print(f"  Avg completeness: {df['data_completeness'].mean():.2%}")

    # Group breakdown
    if "food_group" in df.columns:
        print(f"\n--- Food Groups ---")
        for grp, count in df["food_group"].value_counts().items():
            print(f"  {grp}: {count:,}")

    # Inflammatory category breakdown
    print(f"\n--- Inflammatory Categories ---")
    for cat, count in df["inflammatory_category"].value_counts().items():
        print(f"  {cat}: {count:,}")


if __name__ == "__main__":
    main()
