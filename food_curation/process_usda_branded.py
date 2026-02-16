"""
Process USDA FoodData Central *branded* foods into a clean parquet.

Source: https://fdc.nal.usda.gov/download-datasets

Extracts branded_food entries (~2M), ranks by nutrient completeness,
keeps top 200K.  Chunks the 1.7 GB food_nutrient.csv to stay memory-friendly.

Usage:
    python food_curation/process_usda_branded.py
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
    USDA_AMINO_ACID_IDS,
    USDA_DIR,
    USDA_MACRO_IDS,
    USDA_MICRO_IDS,
)
from inflammatory_score import calculate_inflammatory_score
from normalize import normalize_food_name_display

NUTRIENT_CHUNK_SIZE = 500_000
MAX_BRANDED_FOODS = 200_000


def load_branded_fdc_ids() -> tuple[set[int], dict[int, str]]:
    """Load food.csv, filter to data_type='branded_food'.

    Returns (set of branded fdc_ids, {fdc_id: food_description}).
    """
    print("Loading food.csv (branded filter) ...")
    df = pd.read_csv(
        USDA_DIR / "food.csv",
        dtype={"fdc_id": int, "data_type": str},
        usecols=["fdc_id", "data_type", "description"],
    )
    total = len(df)
    df = df[df["data_type"] == "branded_food"].copy()
    print(f"  {total:,} total -> {len(df):,} branded foods")

    fdc_ids = set(df["fdc_id"].astype(int))
    desc_map = dict(zip(df["fdc_id"].astype(int), df["description"].fillna("")))
    return fdc_ids, desc_map


def load_branded_metadata() -> pd.DataFrame:
    """Load branded_food.csv -> metadata per fdc_id.

    Columns: fdc_id, brand_owner, brand_name, gtin_upc, ingredients,
             branded_food_category, serving_size, serving_size_unit,
             household_serving_fulltext
    """
    print("Loading branded_food.csv ...")
    cols = [
        "fdc_id", "brand_owner", "brand_name", "gtin_upc", "ingredients",
        "branded_food_category", "serving_size", "serving_size_unit",
        "household_serving_fulltext",
    ]
    df = pd.read_csv(USDA_DIR / "branded_food.csv", usecols=cols, dtype={"fdc_id": int})
    print(f"  {len(df):,} branded metadata rows loaded")
    return df


def build_nutrient_index(target_fdc_ids: set[int]) -> dict[int, dict[str, float]]:
    """Chunk-read food_nutrient.csv, keep only target nutrients for branded foods.

    Returns {fdc_id: {canonical_col: amount}}.
    """
    target_nutrient_ids = set(USDA_ALL_NUTRIENT_IDS.keys())
    result: dict[int, dict[str, float]] = {}

    path = USDA_DIR / "food_nutrient.csv"
    n_chunks = 0
    n_kept = 0

    print("Chunking food_nutrient.csv (branded) ...")
    for chunk in tqdm(
        pd.read_csv(
            path,
            chunksize=NUTRIENT_CHUNK_SIZE,
            usecols=["fdc_id", "nutrient_id", "amount"],
        ),
        desc="food_nutrient chunks",
    ):
        n_chunks += 1
        chunk = chunk.dropna(subset=["fdc_id", "nutrient_id"])
        chunk["fdc_id"] = chunk["fdc_id"].astype(int)
        chunk["nutrient_id"] = chunk["nutrient_id"].astype(int)

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


def filter_and_rank(
    nutrient_index: dict[int, dict[str, float]],
) -> list[int]:
    """Filter foods that have calories + protein + fat + carbs > 0,
    then rank by nutrient completeness and return top MAX_BRANDED_FOODS fdc_ids.
    """
    print("Filtering and ranking by nutrient completeness ...")
    scored: list[tuple[int, int]] = []

    for fdc_id, nutrients in nutrient_index.items():
        cal = nutrients.get("calories", 0.0)
        pro = nutrients.get("protein", 0.0)
        fat = nutrients.get("fat", 0.0)
        carb = nutrients.get("carbs", 0.0)

        if cal <= 0 or (pro + fat + carb) <= 0:
            continue

        # Count non-zero nutrients
        n_count = sum(1 for v in nutrients.values() if v and v > 0)
        scored.append((fdc_id, n_count))

    print(f"  {len(scored):,} foods pass macro filter")

    # Sort descending by nutrient count, take top N
    scored.sort(key=lambda x: x[1], reverse=True)
    top_ids = [fdc_id for fdc_id, _ in scored[:MAX_BRANDED_FOODS]]
    print(f"  Keeping top {len(top_ids):,} by nutrient completeness")
    return top_ids


def build_dataframe(
    top_fdc_ids: list[int],
    desc_map: dict[int, str],
    branded_meta: pd.DataFrame,
    nutrient_index: dict[int, dict[str, float]],
) -> pd.DataFrame:
    """Combine foods + nutrients + branded metadata into the canonical schema."""
    # Index branded metadata by fdc_id for fast lookup
    meta_indexed = branded_meta.set_index("fdc_id")

    rows = []
    for fdc_id in tqdm(top_fdc_ids, desc="Building rows"):
        nutrients = nutrient_index.get(fdc_id, {})

        # Macros per 100g
        macros_100g = {col: round(nutrients.get(col, 0.0), 2) for col in MACRO_COLUMNS}
        macros_100g["calories"] = round(macros_100g["calories"], 1)

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
                micros_100g[key] = round(val * 1000.0, 4)

        # Branded metadata
        meta = meta_indexed.loc[fdc_id] if fdc_id in meta_indexed.index else pd.Series(dtype=object)
        # Handle case where multiple rows exist for same fdc_id (take first)
        if isinstance(meta, pd.DataFrame):
            meta = meta.iloc[0]

        brand_owner = meta.get("brand_owner", "") if len(meta) > 0 else ""
        brand_name = meta.get("brand_name", "") if len(meta) > 0 else ""
        brand = str(brand_owner).strip() if pd.notna(brand_owner) and str(brand_owner).strip() else (
            str(brand_name).strip() if pd.notna(brand_name) and str(brand_name).strip() else None
        )

        category = meta.get("branded_food_category", None) if len(meta) > 0 else None
        category = str(category).strip() if pd.notna(category) and str(category).strip() else None

        ingredients = meta.get("ingredients", None) if len(meta) > 0 else None
        ingredients = str(ingredients).strip() if pd.notna(ingredients) and str(ingredients).strip() else None

        # Serving info
        serving_size = meta.get("serving_size", None) if len(meta) > 0 else None
        serving_unit = meta.get("serving_size_unit", None) if len(meta) > 0 else None
        household = meta.get("household_serving_fulltext", None) if len(meta) > 0 else None

        # Build serving description
        serving_desc = None
        if pd.notna(household) and str(household).strip():
            serving_desc = str(household).strip()
        elif pd.notna(serving_size) and pd.notna(serving_unit):
            serving_desc = f"{serving_size} {str(serving_unit).strip()}"

        # serving_weight_g: parse from serving_size (numeric, in g or ml)
        serving_wt = None
        if pd.notna(serving_size):
            try:
                serving_wt = float(serving_size)
            except (ValueError, TypeError):
                pass

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
        inflammatory_score, inflammatory_category = calculate_inflammatory_score(
            macros_100g, micros_100g
        )

        # Audit columns
        nutrient_count = sum(1 for v in nutrients.values() if v and v > 0)
        micro_count = sum(1 for k in MICRO_KEYS if micros_100g.get(k, 0) > 0)
        has_serving = serving_wt is not None and serving_wt > 0

        total_fields = 10  # name, brand, category, calories, protein, fat, carbs, fiber, sugar, serving
        filled = sum([
            1,  # name always present
            1 if brand else 0,
            1 if category else 0,
            1 if macros_100g["calories"] > 0 else 0,
            1 if macros_100g["protein"] > 0 else 0,
            1 if macros_100g["fat"] > 0 else 0,
            1 if macros_100g["carbs"] > 0 else 0,
            1 if macros_100g["fiber"] > 0 else 0,
            1 if macros_100g["sugar"] > 0 else 0,
            1 if has_serving else 0,
        ])
        data_completeness = round(filled / total_fields, 2)

        # Processing notes
        notes = []
        if not brand:
            notes.append("no_brand")
        if not has_serving:
            notes.append("no_serving")
        if micro_count == 0:
            notes.append("no_micros")
        processing_notes = "; ".join(notes) if notes else None

        name = desc_map.get(fdc_id, "").strip()
        row = {
            "name": name,
            "name_normalized": normalize_food_name_display(name),
            "source": "usda_branded",
            "source_id": str(fdc_id),
            "data_type": "branded_food",
            "brand": brand,
            "category": category,
            "food_group": category,
            # Macros per 100g
            "calories_per_100g": macros_100g["calories"],
            "protein_per_100g": macros_100g["protein"],
            "fat_per_100g": macros_100g["fat"],
            "carbs_per_100g": macros_100g["carbs"],
            "fiber_per_100g": macros_100g["fiber"],
            "sugar_per_100g": macros_100g["sugar"],
            # Micros
            "micronutrients_per_100g": json.dumps(micros_100g) if micros_100g else None,
            # Serving
            "serving_description": serving_desc,
            "serving_weight_g": serving_wt,
            **per_serving,
            # OFF-specific fields (null for USDA branded)
            "allergens": None,
            "diet_labels": None,
            "nova_group": None,
            "nutriscore_score": None,
            "traces": None,
            "image_url": None,
            # Ingredients from branded_food.csv
            "ingredients_text": ingredients,
            # Inflammatory score
            "inflammatory_score": inflammatory_score,
            "inflammatory_category": inflammatory_category,
            # Audit columns
            "nutrient_count": nutrient_count,
            "micro_count": micro_count,
            "has_serving": has_serving,
            "data_completeness": data_completeness,
            "processing_notes": processing_notes,
            "source_url": f"https://fdc.nal.usda.gov/food-details/{fdc_id}/nutrients",
        }
        rows.append(row)

    df = pd.DataFrame(rows)

    # Ensure per-serving columns exist even if no serving data
    for col in ["calories_per_serving", "protein_per_serving", "fat_per_serving", "carbs_per_serving"]:
        if col not in df.columns:
            df[col] = None

    return df


def main():
    print("=" * 60)
    print("USDA FoodData Central - Branded Foods Processing")
    print("=" * 60)

    if not USDA_DIR.exists():
        print(f"ERROR: USDA directory not found: {USDA_DIR}")
        sys.exit(1)

    # Step 1: Load branded fdc_ids from food.csv
    branded_fdc_ids, desc_map = load_branded_fdc_ids()

    # Step 2: Load branded metadata
    branded_meta = load_branded_metadata()

    # Step 3: Chunk-read food_nutrient.csv for branded foods
    nutrient_index = build_nutrient_index(branded_fdc_ids)

    # Step 4-5: Filter (must have macros) and rank by completeness
    top_fdc_ids = filter_and_rank(nutrient_index)

    # Step 6-10: Build canonical dataframe
    df = build_dataframe(top_fdc_ids, desc_map, branded_meta, nutrient_index)

    # Save
    out_path = OUTPUT_DIR / "usda_branded_processed.parquet"
    df.to_parquet(out_path, index=False)
    print(f"\nSaved {len(df):,} USDA branded foods -> {out_path}")

    # Stats
    print(f"\n{'─' * 40}")
    print(f"  Total output rows:    {len(df):,}")
    print(f"  With brand:           {df['brand'].notna().sum():,}")
    print(f"  With category:        {df['category'].notna().sum():,}")
    print(f"  With micros:          {df['micronutrients_per_100g'].notna().sum():,}")
    print(f"  With serving:         {df['serving_weight_g'].notna().sum():,}")
    print(f"  With ingredients:     {df['ingredients_text'].notna().sum():,}")
    print(f"  Avg nutrient count:   {df['nutrient_count'].mean():.1f}")
    print(f"  Avg data completeness:{df['data_completeness'].mean():.2f}")

    # Top categories
    print(f"\n  Top 10 categories:")
    top_cats = df["category"].value_counts().head(10)
    for cat, count in top_cats.items():
        print(f"    {cat}: {count:,}")

    # Inflammatory score distribution
    print(f"\n  Inflammatory categories:")
    inflam = df["inflammatory_category"].value_counts()
    for cat, count in inflam.items():
        print(f"    {cat}: {count:,}")


if __name__ == "__main__":
    main()
