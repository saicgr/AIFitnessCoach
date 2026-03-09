#!/usr/bin/env python3
"""
Validate all rows in food_database and populate the new quality columns.

Runs 6 validation rules on every row and sets:
  - atwater_valid (BOOLEAN)
  - confidence_score (REAL 0-1)
  - verification_level (TEXT)
  - validation_flags (JSONB)
  - food_group_detected (TEXT)
  - validated_at (TIMESTAMPTZ)

Usage:
  python validate_food_database.py              # full run
  python validate_food_database.py --dry-run    # preview stats, no DB writes
  python validate_food_database.py --limit 1000 # process first 1000 rows only
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import re
import sys
import time
from collections import defaultdict
from datetime import datetime, timezone
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
# Food group classification
# ─────────────────────────────────────────────────────────────

# keyword -> (food_group, min_cal_per_100g, max_cal_per_100g)
FOOD_GROUP_RULES = [
    # Order matters: more specific keywords first
    (["olive oil", "coconut oil", "canola oil", "vegetable oil", "sesame oil",
      "avocado oil", "sunflower oil", "peanut oil", "cooking oil", "oil,"],
     "oils", 600, 902),
    (["butter", "ghee", "lard", "shortening", "margarine"],
     "fats", 500, 902),
    (["walnut", "almond", "cashew", "pistachio", "pecan", "macadamia",
      "peanut", "hazelnut", "brazil nut", "pine nut", "mixed nuts", "nut butter",
      "peanut butter", "almond butter"],
     "nuts_seeds", 400, 720),
    (["sunflower seed", "pumpkin seed", "chia seed", "flax seed", "hemp seed",
      "sesame seed"],
     "nuts_seeds", 400, 720),
    (["chicken breast", "turkey breast", "chicken thigh", "ground beef",
      "beef steak", "pork chop", "pork loin", "lamb", "veal", "bison",
      "venison", "duck", "goose", "ground turkey", "sirloin", "ribeye",
      "tenderloin", "filet"],
     "meat", 80, 400),
    (["salmon", "tuna", "cod", "tilapia", "shrimp", "crab", "lobster",
      "sardine", "mackerel", "trout", "halibut", "catfish", "bass",
      "swordfish", "mahi", "scallop", "clam", "mussel", "oyster",
      "anchovy", "herring", "squid", "octopus"],
     "fish_seafood", 50, 350),
    (["milk", "yogurt", "cheese", "cream cheese", "cottage cheese",
      "sour cream", "whey", "casein", "kefir", "ricotta", "mozzarella",
      "cheddar", "parmesan", "brie", "gouda", "feta", "cream,"],
     "dairy", 20, 500),
    (["egg", "eggs,", "egg white", "egg yolk"],
     "eggs", 50, 250),
    (["rice", "pasta", "bread", "flour", "oat", "oatmeal", "cereal",
      "wheat", "barley", "quinoa", "couscous", "noodle", "tortilla",
      "cracker", "bagel", "muffin", "pancake", "waffle", "corn,",
      "cornmeal", "grits"],
     "grains", 100, 400),
    (["apple", "banana", "orange", "grape", "strawberr", "blueberr",
      "raspberr", "blackberr", "mango", "pineapple", "peach", "pear",
      "cherry", "plum", "kiwi", "watermelon", "cantaloupe", "melon",
      "papaya", "pomegranate", "fig", "date", "coconut", "avocado",
      "lemon", "lime", "grapefruit", "tangerine", "clementine",
      "apricot", "nectarine", "cranberr", "guava", "passion fruit",
      "lychee", "dragonfruit"],
     "fruits", 10, 400),
    (["lettuce", "spinach", "kale", "broccoli", "cauliflower", "carrot",
      "tomato", "cucumber", "pepper", "onion", "garlic", "celery",
      "zucchini", "squash", "eggplant", "asparagus", "green bean",
      "pea,", "peas,", "corn,", "potato", "sweet potato", "cabbage",
      "brussels sprout", "artichoke", "beet", "radish", "turnip",
      "mushroom", "arugula", "bok choy", "collard", "chard",
      "okra", "leek", "scallion"],
     "vegetables", 5, 200),
    (["bean", "lentil", "chickpea", "black bean", "kidney bean",
      "navy bean", "pinto bean", "soybean", "edamame", "tofu", "tempeh",
      "hummus"],
     "legumes", 50, 400),
    (["water", "tea", "coffee", "soda", "juice", "lemonade", "smoothie",
      "energy drink", "sports drink", "cola", "sprite", "fanta",
      "gatorade", "powerade", "kombucha"],
     "beverages", 0, 250),
    (["beer", "wine", "vodka", "whiskey", "rum", "gin", "tequila",
      "brandy", "cognac", "sake", "champagne", "prosecco", "mead",
      "cider", "hard seltzer", "cocktail", "margarita", "mojito",
      "martini", "bourbon", "scotch", "ale", "lager", "stout",
      "ipa", "porter", "pilsner"],
     "alcohol", 20, 350),
    (["candy", "chocolate", "cookie", "cake", "pie", "ice cream",
      "donut", "brownie", "pastry", "pudding", "custard", "gelato",
      "frosting", "syrup", "honey", "jam", "jelly", "sugar,",
      "caramel", "fudge"],
     "sweets", 100, 600),
    (["chip", "pretzel", "popcorn", "cracker", "granola bar",
      "protein bar", "energy bar", "trail mix", "jerky"],
     "snacks", 100, 600),
]

# Alcohol detection keywords for relaxed Atwater tolerance
ALCOHOL_KEYWORDS = frozenset([
    "beer", "wine", "vodka", "whiskey", "rum", "gin", "tequila",
    "brandy", "cognac", "sake", "champagne", "prosecco", "mead",
    "cider", "hard seltzer", "cocktail", "margarita", "mojito",
    "martini", "bourbon", "scotch", "ale", "lager", "stout",
    "ipa", "porter", "pilsner", "liqueur", "schnapps",
])

# Verification level classification
LAB_DATA_TYPES = frozenset({
    "foundation_food", "sr_legacy_food", "survey_fndds_food",
    "Foundation", "SR Legacy", "Survey (FNDDS)",
})


def _is_alcohol(name: str, category: str) -> bool:
    """Check if a food item is likely an alcohol product."""
    text = f"{name} {category}".lower()
    return any(kw in text for kw in ALCOHOL_KEYWORDS)


def detect_food_group(name: str, category: str) -> str | None:
    """Classify a food into a group using keyword matching.
    Returns the food group name or None if unclassifiable."""
    text = f"{name} {category}".lower()
    for keywords, group, _, _ in FOOD_GROUP_RULES:
        if any(kw in text for kw in keywords):
            return group
    return None


def get_category_calorie_range(food_group: str) -> tuple[float, float] | None:
    """Get the plausible calorie range for a food group."""
    for _, group, min_cal, max_cal in FOOD_GROUP_RULES:
        if group == food_group:
            return (min_cal, max_cal)
    return None


# ─────────────────────────────────────────────────────────────
# Verification level
# ─────────────────────────────────────────────────────────────

def classify_verification_level(source: str | None, data_type: str | None) -> str | None:
    """Assign a verification tier based on source and data_type."""
    if not source:
        return None
    source_lower = source.lower()
    data_type_lower = (data_type or "").lower()

    if source_lower == "usda":
        if data_type_lower in {dt.lower() for dt in LAB_DATA_TYPES}:
            return "lab_verified"
        # USDA branded is sometimes stored as source=usda, data_type=branded_food
        if data_type_lower == "branded_food":
            return "manufacturer_verified"
        return "lab_verified"  # default USDA to lab_verified
    if source_lower == "usda_branded":
        return "manufacturer_verified"
    if source_lower == "openfoodfacts":
        return "community_verified"
    if source_lower == "cnf":
        return "lab_verified"
    if source_lower == "indb":
        return "lab_verified"
    return None


# ─────────────────────────────────────────────────────────────
# 6 Validation Rules
# ─────────────────────────────────────────────────────────────

def rule_atwater(row: dict) -> tuple[bool, dict]:
    """Rule 1: Atwater calorie equation check (weight: 30%).
    Expected = P*4 + (C-fiber)*4 + F*9 + fiber*2.
    Pass if |actual - expected| <= max(30, 15% of expected)."""
    cal = row.get("calories_per_100g")
    protein = row.get("protein_per_100g")
    carbs = row.get("carbs_per_100g")
    fat = row.get("fat_per_100g")

    if cal is None or protein is None or carbs is None or fat is None:
        return False, {"skipped": True, "reason": "missing_macros"}

    fiber = row.get("fiber_per_100g") or 0
    # Atwater with fiber correction
    net_carbs = max(0, carbs - fiber)
    expected = (protein * 4) + (net_carbs * 4) + (fat * 9) + (fiber * 2)

    if expected == 0 and cal == 0:
        return True, {"expected": 0, "actual": 0, "diff": 0, "passed": True}

    diff = abs(cal - expected)
    # Tolerance: max of 30 kcal absolute or 15% of expected
    tolerance_pct = 0.15
    # Alcohol items get 50% tolerance (alcohol contributes 7 cal/g, not tracked)
    name = row.get("name") or ""
    category = row.get("category") or ""
    if _is_alcohol(name, category):
        tolerance_pct = 0.50

    tolerance = max(30, expected * tolerance_pct)
    passed = diff <= tolerance

    return passed, {
        "expected": round(expected, 1),
        "actual": round(cal, 1),
        "diff": round(diff, 1),
        "tolerance": round(tolerance, 1),
        "passed": passed,
    }


def rule_macro_bounds(row: dict) -> tuple[bool, dict]:
    """Rule 2: Individual macro bounds (weight: 15%).
    P, C, F each 0-100g; P <= cal/4; F <= cal/9;
    sugar <= carbs+1; fiber <= carbs+1."""
    cal = row.get("calories_per_100g") or 0
    protein = row.get("protein_per_100g")
    carbs = row.get("carbs_per_100g")
    fat = row.get("fat_per_100g")
    sugar = row.get("sugar_per_100g")
    fiber = row.get("fiber_per_100g")

    issues = []

    if protein is not None:
        if protein < 0 or protein > 100:
            issues.append(f"protein={protein} out of [0,100]")
        if cal > 0 and protein > (cal / 4) * 1.1:  # 10% slack
            issues.append(f"protein={protein} > cal/4={cal/4:.1f}")

    if carbs is not None and (carbs < 0 or carbs > 100):
        issues.append(f"carbs={carbs} out of [0,100]")

    if fat is not None:
        if fat < 0 or fat > 100:
            issues.append(f"fat={fat} out of [0,100]")
        if cal > 0 and fat > (cal / 9) * 1.1:
            issues.append(f"fat={fat} > cal/9={cal/9:.1f}")

    if sugar is not None and carbs is not None:
        if sugar > carbs + 1:
            issues.append(f"sugar={sugar} > carbs+1={carbs+1}")

    if fiber is not None and carbs is not None:
        if fiber > carbs + 1:
            issues.append(f"fiber={fiber} > carbs+1={carbs+1}")

    passed = len(issues) == 0
    return passed, {"passed": passed, "issues": issues}


def rule_macro_sum(row: dict) -> tuple[bool, dict]:
    """Rule 3: Macro sum (weight: 10%).
    P + C + F <= 101g per 100g (1g tolerance)."""
    protein = row.get("protein_per_100g") or 0
    carbs = row.get("carbs_per_100g") or 0
    fat = row.get("fat_per_100g") or 0

    total = protein + carbs + fat
    passed = total <= 101
    return passed, {"total": round(total, 1), "passed": passed}


def rule_category_range(row: dict) -> tuple[bool, dict]:
    """Rule 4: Category-specific calorie range (weight: 15%).
    Classify by keywords, check cal is in plausible range.
    Unknown category is not penalized (returns True)."""
    name = row.get("name") or ""
    category = row.get("category") or ""
    cal = row.get("calories_per_100g")

    food_group = detect_food_group(name, category)
    if food_group is None or cal is None:
        return True, {"food_group": None, "skipped": True, "passed": True}

    cal_range = get_category_calorie_range(food_group)
    if cal_range is None:
        return True, {"food_group": food_group, "skipped": True, "passed": True}

    min_cal, max_cal = cal_range
    passed = min_cal <= cal <= max_cal
    return passed, {
        "food_group": food_group,
        "min_cal": min_cal,
        "max_cal": max_cal,
        "actual_cal": round(cal, 1),
        "passed": passed,
    }


def rule_serving_size(row: dict) -> tuple[bool, dict]:
    """Rule 5: Serving size bounds (weight: 5%).
    If present: 1g <= serving <= 5000g."""
    serving = row.get("serving_weight_g")
    if serving is None:
        return True, {"skipped": True, "passed": True}

    passed = 1 <= serving <= 5000
    return passed, {"serving_g": serving, "passed": passed}


def rule_name_quality(row: dict) -> tuple[bool, dict]:
    """Rule 6: Name quality (weight: 5%).
    >= 3 chars, has letters, <= 200 chars."""
    name = row.get("name") or ""
    issues = []
    if len(name) < 3:
        issues.append("too_short")
    if len(name) > 200:
        issues.append("too_long")
    if not re.search(r"[a-zA-Z]", name):
        issues.append("no_letters")

    passed = len(issues) == 0
    return passed, {"name_len": len(name), "issues": issues, "passed": passed}


def compute_completeness(row: dict) -> float:
    """Completeness score: fraction of 8 key fields that are non-null (weight: 20%)."""
    fields = [
        row.get("calories_per_100g"),
        row.get("protein_per_100g"),
        row.get("carbs_per_100g"),
        row.get("fat_per_100g"),
        row.get("fiber_per_100g"),
        row.get("sugar_per_100g"),
        row.get("serving_weight_g"),
        row.get("brand"),
    ]
    present = sum(1 for f in fields if f is not None)
    return present / 8


# ─────────────────────────────────────────────────────────────
# Composite confidence score
# ─────────────────────────────────────────────────────────────

RULE_WEIGHTS = {
    "atwater": 0.30,
    "macro_bounds": 0.15,
    "macro_sum": 0.10,
    "category_range": 0.15,
    "serving_size": 0.05,
    "name_quality": 0.05,
    "completeness": 0.20,
}


def validate_row(row: dict) -> dict:
    """Run all 6 rules + completeness on a single row.
    Returns dict with all computed fields for the UPDATE."""
    flags = {}

    # Rule 1: Atwater
    atwater_passed, atwater_detail = rule_atwater(row)
    flags["atwater"] = atwater_detail

    # Rule 2: Macro bounds
    macro_bounds_passed, macro_bounds_detail = rule_macro_bounds(row)
    flags["macro_bounds"] = macro_bounds_detail

    # Rule 3: Macro sum
    macro_sum_passed, macro_sum_detail = rule_macro_sum(row)
    flags["macro_sum"] = macro_sum_detail

    # Rule 4: Category range
    category_passed, category_detail = rule_category_range(row)
    flags["category_range"] = category_detail

    # Rule 5: Serving size
    serving_passed, serving_detail = rule_serving_size(row)
    flags["serving_size"] = serving_detail

    # Rule 6: Name quality
    name_passed, name_detail = rule_name_quality(row)
    flags["name_quality"] = name_detail

    # Completeness
    completeness = compute_completeness(row)

    # Weighted confidence score
    confidence = (
        RULE_WEIGHTS["atwater"] * (1.0 if atwater_passed else 0.0)
        + RULE_WEIGHTS["macro_bounds"] * (1.0 if macro_bounds_passed else 0.0)
        + RULE_WEIGHTS["macro_sum"] * (1.0 if macro_sum_passed else 0.0)
        + RULE_WEIGHTS["category_range"] * (1.0 if category_passed else 0.0)
        + RULE_WEIGHTS["serving_size"] * (1.0 if serving_passed else 0.0)
        + RULE_WEIGHTS["name_quality"] * (1.0 if name_passed else 0.0)
        + RULE_WEIGHTS["completeness"] * completeness
    )

    # Food group detected
    food_group = detect_food_group(row.get("name") or "", row.get("category") or "")

    # Verification level
    verification_level = classify_verification_level(
        row.get("source"), row.get("data_type")
    )

    return {
        "atwater_valid": atwater_passed,
        "confidence_score": round(confidence, 4),
        "verification_level": verification_level,
        "validation_flags": flags,
        "food_group_detected": food_group,
        "validated_at": datetime.now(timezone.utc).isoformat(),
    }


# ─────────────────────────────────────────────────────────────
# Column mapping from DB rows
# ─────────────────────────────────────────────────────────────

SELECT_QUERY = """
SELECT
    id,
    name,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    sugar_per_100g,
    serving_weight_g,
    brand,
    source,
    data_type,
    category
FROM food_database
"""

COLUMN_NAMES = [
    "id", "name", "calories_per_100g", "protein_per_100g",
    "carbs_per_100g", "fat_per_100g", "fiber_per_100g", "sugar_per_100g",
    "serving_weight_g", "brand", "source", "data_type", "category",
]

UPDATE_SQL = """
UPDATE food_database SET
    atwater_valid = %(atwater_valid)s,
    confidence_score = %(confidence_score)s,
    verification_level = %(verification_level)s,
    validation_flags = %(validation_flags)s,
    food_group_detected = %(food_group_detected)s,
    validated_at = %(validated_at)s
WHERE id = %(id)s
"""


def row_to_dict(raw: tuple) -> dict:
    return dict(zip(COLUMN_NAMES, raw))


# ─────────────────────────────────────────────────────────────
# Main logic
# ─────────────────────────────────────────────────────────────

def run(dry_run: bool = False, limit: int | None = None) -> bool:
    logger.info("Connecting to %s@%s:%d/%s ...", DATABASE_USER, DATABASE_HOST, DATABASE_PORT, DATABASE_NAME)
    conn = psycopg2.connect(
        host=DATABASE_HOST, port=DATABASE_PORT, dbname=DATABASE_NAME,
        user=DATABASE_USER, password=DATABASE_PASSWORD, sslmode="require",
    )

    stats = {
        "total": 0,
        "atwater_pass": 0,
        "atwater_fail": 0,
        "rule_failures": defaultdict(int),
        "confidence_buckets": defaultdict(int),
        "verification_levels": defaultdict(int),
        "food_groups": defaultdict(int),
    }

    try:
        query = SELECT_QUERY
        if limit:
            query += f" LIMIT {limit}"

        logger.info("Fetching rows with server-side cursor (batch=%d) ...", BATCH_SIZE)
        t0 = time.time()

        server_cursor = conn.cursor(name="validate_food_db")
        server_cursor.itersize = BATCH_SIZE
        server_cursor.execute(query)

        update_cursor = conn.cursor()
        batch = []
        batch_num = 0

        while True:
            rows = server_cursor.fetchmany(BATCH_SIZE)
            if not rows:
                break

            for raw_row in rows:
                stats["total"] += 1
                row = row_to_dict(raw_row)
                result = validate_row(row)

                # Track stats
                if result["atwater_valid"]:
                    stats["atwater_pass"] += 1
                else:
                    stats["atwater_fail"] += 1

                for rule_name in ["atwater", "macro_bounds", "macro_sum",
                                  "category_range", "serving_size", "name_quality"]:
                    detail = result["validation_flags"].get(rule_name, {})
                    if not detail.get("passed", True):
                        stats["rule_failures"][rule_name] += 1

                # Confidence bucket
                cs = result["confidence_score"]
                if cs >= 0.9:
                    bucket = "0.9-1.0 (excellent)"
                elif cs >= 0.7:
                    bucket = "0.7-0.9 (good)"
                elif cs >= 0.6:
                    bucket = "0.6-0.7 (acceptable)"
                elif cs >= 0.4:
                    bucket = "0.4-0.6 (poor)"
                else:
                    bucket = "0.0-0.4 (bad)"
                stats["confidence_buckets"][bucket] += 1

                if result["verification_level"]:
                    stats["verification_levels"][result["verification_level"]] += 1

                if result["food_group_detected"]:
                    stats["food_groups"][result["food_group_detected"]] += 1

                # Prepare update row
                batch.append({
                    "id": row["id"],
                    "atwater_valid": result["atwater_valid"],
                    "confidence_score": result["confidence_score"],
                    "verification_level": result["verification_level"],
                    "validation_flags": json.dumps(result["validation_flags"]),
                    "food_group_detected": result["food_group_detected"],
                    "validated_at": result["validated_at"],
                })

                if len(batch) >= BATCH_SIZE:
                    batch_num += 1
                    if dry_run:
                        logger.info("  [DRY RUN] Batch %d: %d rows (would update)", batch_num, len(batch))
                    else:
                        _update_batch(update_cursor, batch, batch_num)
                    batch = []

            logger.info("  Processed %d rows so far (%.1fs) ...", stats["total"], time.time() - t0)

        # Flush remaining
        if batch:
            batch_num += 1
            if dry_run:
                logger.info("  [DRY RUN] Batch %d: %d rows (would update)", batch_num, len(batch))
            else:
                _update_batch(update_cursor, batch, batch_num)

        server_cursor.close()

        if not dry_run:
            conn.commit()
            logger.info("All batches committed.")
        else:
            conn.rollback()
            logger.info("[DRY RUN] No data was updated.")

        update_cursor.close()

    except Exception:
        conn.rollback()
        logger.exception("Fatal error during validation")
        return False
    finally:
        conn.close()

    _print_stats(stats, dry_run, time.time() - t0)
    return True


def _update_batch(cursor, batch: list[dict], batch_num: int) -> None:
    t0 = time.time()
    psycopg2.extras.execute_batch(cursor, UPDATE_SQL, batch, page_size=1000)
    elapsed = time.time() - t0
    logger.info("  Batch %d: updated %d rows (%.2fs)", batch_num, len(batch), elapsed)


def _print_stats(stats: dict, dry_run: bool, elapsed: float) -> None:
    prefix = "[DRY RUN] " if dry_run else ""

    print(f"\n{'='*60}")
    print(f"{prefix}FOOD DATABASE VALIDATION STATS")
    print(f"{'='*60}")

    print(f"\n  Total rows processed:   {stats['total']:,}")
    print(f"  Elapsed:                {elapsed:.1f}s")
    print(f"  Throughput:             {stats['total']/max(elapsed,1):.0f} rows/s")

    print(f"\n--- Atwater Check ---")
    print(f"  Pass: {stats['atwater_pass']:,}")
    print(f"  Fail: {stats['atwater_fail']:,}")

    print(f"\n--- Rule Failure Counts ---")
    for rule in ["atwater", "macro_bounds", "macro_sum", "category_range",
                 "serving_size", "name_quality"]:
        count = stats["rule_failures"].get(rule, 0)
        print(f"  {rule:20s} {count:>8,}")

    print(f"\n--- Confidence Distribution ---")
    for bucket in ["0.9-1.0 (excellent)", "0.7-0.9 (good)", "0.6-0.7 (acceptable)",
                   "0.4-0.6 (poor)", "0.0-0.4 (bad)"]:
        count = stats["confidence_buckets"].get(bucket, 0)
        print(f"  {bucket:25s} {count:>8,}")

    print(f"\n--- Verification Levels ---")
    for level in sorted(stats["verification_levels"].keys()):
        count = stats["verification_levels"][level]
        print(f"  {level:30s} {count:>8,}")

    print(f"\n--- Detected Food Groups ---")
    for group in sorted(stats["food_groups"].keys(), key=lambda g: -stats["food_groups"][g]):
        count = stats["food_groups"][group]
        print(f"  {group:20s} {count:>8,}")

    print(f"\n{'='*60}")


# ─────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Validate all food_database rows and populate quality columns."
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Validate and print stats without updating the database.",
    )
    parser.add_argument(
        "--limit", type=int, default=None,
        help="Process only the first N rows (for testing).",
    )
    args = parser.parse_args()

    logger.info(
        "Starting food_database validation%s%s ...",
        " (DRY RUN)" if args.dry_run else "",
        f" (limit={args.limit})" if args.limit else "",
    )

    success = run(dry_run=args.dry_run, limit=args.limit)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
