"""
Process OpenFood Facts parquet into a clean parquet.

Sources:
  https://world.openfoodfacts.org/data
  https://openfoodfacts.github.io/openfoodfacts-server/api/aws-images-dataset/

The OFF parquet stores nutrition data in a `nutriments` column as arrays of
dicts: [{"name": "energy-kcal", "100g": 617.0, "unit": "kcal"}, ...]
This script parses that column to extract per-100g values.

Usage:
    python food_curation/process_openfoodfacts.py
"""

import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pyarrow.parquet as pq
from tqdm import tqdm

sys.path.insert(0, str(Path(__file__).parent))
from config import (
    OFF_MACRO_MAP,
    OFF_MAX_FOODS,
    OFF_MICRO_MAP,
    OFF_PARQUET,
    OFF_READ_COLUMNS,
    OUTPUT_DIR,
)
from inflammatory_score import calculate_inflammatory_score
from normalize import normalize_food_name_display


# How many rows to process per batch (memory management)
BATCH_SIZE = 200_000


def parse_nutriments(nutriments_list):
    """Parse the nutriments array into a flat dict of per-100g values.

    Returns None if the list is empty/null or missing core macros.
    """
    if nutriments_list is None:
        return None
    # Handle numpy arrays (parquet stores lists as ndarray)
    if isinstance(nutriments_list, np.ndarray):
        nutriments_list = nutriments_list.tolist()
    if not isinstance(nutriments_list, list):
        return None

    result = {}
    for item in nutriments_list:
        if not isinstance(item, dict):
            continue
        name = item.get("name")
        if name is None:
            continue

        # Check macros
        if name in OFF_MACRO_MAP:
            val = item.get("100g")
            if val is not None:
                try:
                    result[OFF_MACRO_MAP[name]] = float(val)
                except (ValueError, TypeError):
                    pass

        # Check micros
        if name in OFF_MICRO_MAP:
            canonical, multiplier = OFF_MICRO_MAP[name]
            val = item.get("100g")
            if val is not None:
                try:
                    result[canonical] = float(val) * multiplier
                except (ValueError, TypeError):
                    pass

    # Must have at least calories + protein + fat + carbs
    if not all(k in result for k in ("calories", "protein", "fat", "carbs")):
        return None
    if result.get("calories", 0) <= 0:
        return None

    return result


def quality_score(row, parsed: dict) -> float:
    """Score a food item for quality ranking. Higher = better."""
    score = 0.0

    # Completeness (0-1) contributes up to 40 points
    completeness = row.get("completeness")
    if completeness is not None and pd.notna(completeness):
        try:
            score += float(completeness) * 40
        except (ValueError, TypeError):
            pass

    # Nutriscore: a=30, b=20, c=10, d=5, e=0
    grade = row.get("nutriscore_grade")
    if isinstance(grade, str):
        grade = grade.lower().strip()
        score += {"a": 30, "b": 20, "c": 10, "d": 5}.get(grade, 0)

    # Micronutrient count (bonus up to 14 points)
    from config import MICRO_KEYS
    micro_count = sum(1 for k in MICRO_KEYS if k in parsed and parsed[k] > 0)
    score += micro_count

    # Having fiber/sugar is a plus
    if parsed.get("fiber", 0) > 0:
        score += 3
    if parsed.get("sugar") is not None:
        score += 2

    return score


def extract_product_name(val):
    """Extract product name from OFF's multilingual array format.

    OFF stores product_name as: [{"lang": "main", "text": "..."}, {"lang": "en", ...}]
    Returns the 'main' text, or first available text, or None.
    """
    if isinstance(val, str):
        return val.strip() or None
    if isinstance(val, np.ndarray):
        val = val.tolist()
    if isinstance(val, list):
        # Prefer 'main' lang, then 'en', then first available
        for target_lang in ("main", "en"):
            for item in val:
                if isinstance(item, dict) and item.get("lang") == target_lang:
                    text = item.get("text", "")
                    if isinstance(text, str) and text.strip():
                        return text.strip()
        # Fallback: first item with text
        for item in val:
            if isinstance(item, dict):
                text = item.get("text", "")
                if isinstance(text, str) and text.strip():
                    return text.strip()
    return None


def extract_tags(val):
    """Extract tags from OFF tag arrays, stripping 'en:' prefix.

    Handles ndarray, list of strings, or comma-separated string.
    Returns JSON string of cleaned tags, or None.
    """
    if val is None or (isinstance(val, float) and pd.isna(val)):
        return None
    if isinstance(val, np.ndarray):
        val = val.tolist()
    if isinstance(val, str):
        val = [t.strip() for t in val.split(",") if t.strip()]
    if not isinstance(val, list) or len(val) == 0:
        return None

    cleaned = []
    for tag in val:
        if not isinstance(tag, str):
            continue
        tag = tag.strip()
        # Strip lang prefix like "en:", "fr:", etc.
        if len(tag) > 3 and tag[2] == ":":
            tag = tag[3:]
        tag = tag.strip()
        if tag:
            cleaned.append(tag)

    return json.dumps(cleaned) if cleaned else None


def extract_ingredients_text(val):
    """Extract English ingredients text from OFF's multilingual array format.

    Handles [{"lang": "en", "text": "..."}] or plain string.
    Returns string or None.
    """
    if val is None or (isinstance(val, float) and pd.isna(val)):
        return None
    if isinstance(val, str):
        return val.strip() or None
    if isinstance(val, np.ndarray):
        val = val.tolist()
    if isinstance(val, list):
        # Prefer English, then main, then first available
        for target_lang in ("en", "main"):
            for item in val:
                if isinstance(item, dict) and item.get("lang") == target_lang:
                    text = item.get("text", "")
                    if isinstance(text, str) and text.strip():
                        return text.strip()
        # Fallback: first item with text
        for item in val:
            if isinstance(item, dict):
                text = item.get("text", "")
                if isinstance(text, str) and text.strip():
                    return text.strip()
    return None


def extract_image_url(images_val, barcode):
    """Construct front image URL from OFF images data.

    If images has 'front' or 'front_en', build URL. Otherwise return a
    default URL for the first image. Barcode is split into 3/3/3/rest
    segments for the path.
    Returns URL string or None.
    """
    if not barcode or barcode == "nan":
        return None

    # Build the barcode path: split into 3/3/3/rest segments
    barcode = str(barcode).strip()
    if len(barcode) <= 8:
        barcode_path = barcode
    else:
        barcode_path = "/".join([
            barcode[:3],
            barcode[3:6],
            barcode[6:9],
            barcode[9:],
        ])

    base = f"https://images.openfoodfacts.org/images/products/{barcode_path}"

    if images_val is None or (isinstance(images_val, float) and pd.isna(images_val)):
        return None

    if isinstance(images_val, np.ndarray):
        images_val = images_val.tolist()
    if isinstance(images_val, dict):
        # Look for front image keys
        for key in ("front_en", "front"):
            img = images_val.get(key)
            if isinstance(img, dict):
                rev = img.get("rev")
                if rev is not None:
                    return f"{base}/{key}.{rev}.400.jpg"

    # Fallback: first image
    return f"{base}/1.400.jpg"


def process_batch(df_batch):
    """Process a batch of OFF rows into canonical format."""
    results = []
    for idx, row in df_batch.iterrows():
        name = extract_product_name(row.get("product_name"))
        if not name:
            continue

        parsed = parse_nutriments(row.get("nutriments"))
        if parsed is None:
            continue

        # Separate macros and micros
        from config import MACRO_COLUMNS, MICRO_KEYS
        macros = {col: parsed.get(col, 0.0) for col in MACRO_COLUMNS}
        micros = {}
        for key in MICRO_KEYS:
            val = parsed.get(key)
            if val is not None and val > 0:
                micros[key] = round(val, 4)

        # Serving info
        serving_desc = row.get("serving_size")
        if isinstance(serving_desc, str):
            serving_desc = serving_desc.strip() or None
        else:
            serving_desc = None
        serving_wt = row.get("serving_quantity")
        if pd.notna(serving_wt):
            try:
                serving_wt = float(serving_wt)
            except (ValueError, TypeError):
                serving_wt = None
        else:
            serving_wt = None

        # Per-serving macros
        per_serving = {}
        if serving_wt and serving_wt > 0:
            factor = serving_wt / 100.0
            per_serving = {
                "calories_per_serving": round(macros["calories"] * factor, 1),
                "protein_per_serving": round(macros["protein"] * factor, 2),
                "fat_per_serving": round(macros["fat"] * factor, 2),
                "carbs_per_serving": round(macros["carbs"] * factor, 2),
            }

        name_clean = name.strip()
        barcode = str(row.get("code", "")).strip()
        brand = row.get("brands")
        brand = str(brand).strip() if isinstance(brand, str) and brand.strip() else None
        category = row.get("categories")
        category = str(category).strip()[:200] if isinstance(category, str) and category.strip() else None

        q_score = quality_score(row, parsed)

        # --- New enrichment fields ---
        allergens = extract_tags(row.get("allergens_tags"))
        diet_labels = extract_tags(row.get("labels_tags"))

        # Food group: extract first tag
        food_groups_json = extract_tags(row.get("food_groups_tags"))
        food_group = None
        if food_groups_json:
            try:
                groups = json.loads(food_groups_json)
                if groups:
                    food_group = groups[0]
            except (json.JSONDecodeError, IndexError):
                pass

        # NOVA group (1-4)
        nova_group = None
        nova_raw = row.get("nova_group")
        if nova_raw is not None and pd.notna(nova_raw):
            try:
                nova_val = int(float(nova_raw))
                if 1 <= nova_val <= 4:
                    nova_group = nova_val
            except (ValueError, TypeError):
                pass

        # Nutriscore numeric score
        nutriscore_score_val = None
        ns_raw = row.get("nutriscore_score")
        if ns_raw is not None and pd.notna(ns_raw):
            try:
                nutriscore_score_val = float(ns_raw)
            except (ValueError, TypeError):
                pass

        traces = extract_tags(row.get("traces_tags"))
        ingredients = extract_ingredients_text(row.get("ingredients_text"))
        image_url = extract_image_url(row.get("images"), barcode)

        # --- Inflammatory score ---
        macros_dict = {
            "calories": macros["calories"],
            "protein": macros["protein"],
            "fat": macros["fat"],
            "carbs": macros["carbs"],
            "fiber": macros.get("fiber", 0.0),
            "sugar": macros.get("sugar", 0.0),
        }
        inf_score, inf_cat = calculate_inflammatory_score(macros_dict, micros)

        # --- Audit columns ---
        nutrient_count = sum(1 for v in macros.values() if v and v > 0) + len(micros)
        micro_count = len(micros)
        has_serving = serving_wt is not None

        # Data completeness: count of non-null core fields / total core fields
        core_fields = [
            name_clean, barcode, brand, category, food_group,
            macros["calories"], macros["protein"], macros["fat"], macros["carbs"],
            serving_desc, serving_wt,
            allergens, ingredients, image_url,
        ]
        data_completeness = round(
            sum(1 for f in core_fields if f is not None and f != "" and f != 0) / len(core_fields),
            3,
        )

        processing_notes = None
        notes = []
        if macros["calories"] > 900:
            notes.append("very_high_calories")
        if macros["protein"] > 100:
            notes.append("very_high_protein")
        if not micros:
            notes.append("no_micros")
        if notes:
            processing_notes = "; ".join(notes)

        source_url = f"https://world.openfoodfacts.org/product/{barcode}" if barcode and barcode != "nan" else None

        results.append({
            "name": name_clean,
            "name_normalized": normalize_food_name_display(name_clean),
            "source": "openfoodfacts",
            "source_id": barcode,
            "data_type": "open_food_facts",
            "brand": brand,
            "category": category,
            "food_group": food_group,
            "calories_per_100g": round(macros["calories"], 1),
            "protein_per_100g": round(macros["protein"], 2),
            "fat_per_100g": round(macros["fat"], 2),
            "carbs_per_100g": round(macros["carbs"], 2),
            "fiber_per_100g": round(macros.get("fiber", 0.0), 2),
            "sugar_per_100g": round(macros.get("sugar", 0.0), 2),
            "micronutrients_per_100g": json.dumps(micros) if micros else None,
            "serving_description": serving_desc,
            "serving_weight_g": serving_wt,
            **per_serving,
            # Enrichment
            "allergens": allergens,
            "diet_labels": diet_labels,
            "nova_group": nova_group,
            "nutriscore_score": nutriscore_score_val,
            "traces": traces,
            "ingredients_text": ingredients,
            "image_url": image_url,
            # Inflammatory
            "inflammatory_score": inf_score,
            "inflammatory_category": inf_cat,
            # Audit
            "nutrient_count": nutrient_count,
            "micro_count": micro_count,
            "has_serving": has_serving,
            "data_completeness": data_completeness,
            "processing_notes": processing_notes,
            "source_url": source_url,
            # Internal (dropped before output)
            "_quality_score": q_score,
        })

    return results


def main():
    print("=" * 60)
    print("OpenFood Facts Processing")
    print("=" * 60)

    if not OFF_PARQUET.exists():
        print(f"ERROR: OFF parquet not found: {OFF_PARQUET}")
        sys.exit(1)

    # Read only the columns we need
    print(f"Reading {OFF_PARQUET} ...")
    pf = pq.ParquetFile(OFF_PARQUET)
    total_rows = pf.metadata.num_rows
    print(f"  Total rows in file: {total_rows:,}")

    # Determine which columns are available (use arrow schema for correct names)
    available_cols = set(pf.schema_arrow.names)
    read_cols = [c for c in OFF_READ_COLUMNS if c in available_cols]
    missing = set(OFF_READ_COLUMNS) - available_cols
    if missing:
        print(f"  Warning: columns not found in parquet: {missing}")

    all_results = []
    n_batches = (total_rows + BATCH_SIZE - 1) // BATCH_SIZE

    for batch in tqdm(pf.iter_batches(batch_size=BATCH_SIZE, columns=read_cols), total=n_batches, desc="Batches"):
        df_batch = batch.to_pandas()
        results = process_batch(df_batch)
        all_results.extend(results)

    print(f"\n  {len(all_results):,} foods with valid nutrition extracted")

    if not all_results:
        print("ERROR: No foods extracted. Check column names in parquet.")
        sys.exit(1)

    # Build DataFrame and sort by quality
    df = pd.DataFrame(all_results)

    # Dedup by barcode (keep highest quality)
    if "source_id" in df.columns:
        before = len(df)
        df = df.sort_values("_quality_score", ascending=False)
        df = df.drop_duplicates(subset="source_id", keep="first")
        print(f"  Deduped by barcode: {before:,} -> {len(df):,}")

    # Take top OFF_MAX_FOODS by quality score
    if len(df) > OFF_MAX_FOODS:
        df = df.nlargest(OFF_MAX_FOODS, "_quality_score")
        print(f"  Top {OFF_MAX_FOODS:,} by quality score retained")

    # Drop internal score column
    df = df.drop(columns=["_quality_score"])

    # Ensure per-serving columns exist
    for col in ["calories_per_serving", "protein_per_serving", "fat_per_serving", "carbs_per_serving"]:
        if col not in df.columns:
            df[col] = None

    out_path = OUTPUT_DIR / "off_processed.parquet"
    df.to_parquet(out_path, index=False)
    print(f"\nSaved {len(df):,} OFF foods -> {out_path}")

    # Quick stats
    print(f"  With micros: {df['micronutrients_per_100g'].notna().sum():,}")
    print(f"  With serving: {df['serving_weight_g'].notna().sum():,}")
    print(f"  With brand: {df['brand'].notna().sum():,}")
    grades = df["category"].notna().sum()
    print(f"  With category: {grades:,}")
    print(f"  With allergens: {df['allergens'].notna().sum():,}")
    print(f"  With ingredients: {df['ingredients_text'].notna().sum():,}")
    print(f"  With image URL: {df['image_url'].notna().sum():,}")
    print(f"  With inflammatory score: {df['inflammatory_score'].notna().sum():,}")


if __name__ == "__main__":
    main()
