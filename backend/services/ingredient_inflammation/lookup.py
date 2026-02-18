"""
3-tier ingredient lookup engine.

Lookup order:
  1. Static dict (primary, synchronous) - exact, substring, fuzzy
  2. food_database (fallback, async) - Supabase RPC
  3. Heuristic rules (last resort) - keyword matching

Never returns None - always produces a score.
"""

import re
import difflib
import logging
from typing import Tuple, Optional

from .database import IngredientRecord, get_by_name, get_alias_index
from .scoring import ingredient_score_to_category

logger = logging.getLogger(__name__)

# Lookup source labels
SOURCE_STATIC = "static_db"
SOURCE_FOOD_DB = "food_database"
SOURCE_HEURISTIC = "heuristic"


def lookup_static(name: str) -> Optional[Tuple[str, IngredientRecord]]:
    """
    Look up ingredient in static database.

    Tries in order:
    1. Exact match in alias index
    2. Substring match (key contains name or name contains key, len >= 4)
    3. Fuzzy match via difflib (cutoff=0.82)

    Returns:
        (source_label, IngredientRecord) or None
    """
    name_lower = name.lower().strip()
    if not name_lower:
        return None

    # 1. Exact match
    record = get_by_name(name_lower)
    if record is not None:
        return (SOURCE_STATIC, record)

    alias_index = get_alias_index()

    # 2. Substring match (both directions)
    if len(name_lower) >= 4:
        # Check if any known key is a substring of the input name
        for key, record in alias_index.items():
            if len(key) >= 4 and key in name_lower:
                return (SOURCE_STATIC, record)

        # Check if the input name is a substring of any known key
        for key, record in alias_index.items():
            if len(key) >= 4 and name_lower in key:
                return (SOURCE_STATIC, record)

    # 3. Fuzzy match
    all_keys = list(alias_index.keys())
    matches = difflib.get_close_matches(name_lower, all_keys, n=1, cutoff=0.82)
    if matches:
        return (SOURCE_STATIC, alias_index[matches[0]])

    return None


async def lookup_food_database(name: str) -> Optional[Tuple[str, IngredientRecord]]:
    """
    Look up ingredient in the Supabase food_database.

    Only called when static dict misses. Uses the search_food_database RPC
    and reads inflammatory_score/inflammatory_category if available.

    Returns:
        (source_label, IngredientRecord) or None
    """
    try:
        from core.supabase_client import get_supabase
        supabase = get_supabase()

        # Query food_database directly for inflammation columns
        result = supabase.client.table("food_database") \
            .select("name, inflammatory_score, inflammatory_category") \
            .ilike("name", f"%{name}%") \
            .eq("is_primary", True) \
            .limit(1) \
            .execute()

        if not result.data:
            return None

        row = result.data[0]
        score = row.get("inflammatory_score")
        category = row.get("inflammatory_category")

        if score is None:
            return None

        score = int(score)
        if score < 1 or score > 10:
            return None

        category = category or ingredient_score_to_category(score)

        record = IngredientRecord(
            score=score,
            category=category,
            reason=f"Score from food database entry: {row.get('name', name)}",
            is_additive=False,
            aliases=(),
        )
        return (SOURCE_FOOD_DB, record)

    except Exception as e:
        logger.warning(f"food_database lookup failed for '{name}': {e}")
        return None


def lookup_heuristic(name: str) -> Tuple[str, IngredientRecord]:
    """
    Last-resort heuristic scoring based on keyword patterns.

    Always returns a result (never None).
    """
    name_lower = name.lower().strip()

    # Highly inflammatory patterns
    if "hydrogenated" in name_lower:
        return (SOURCE_HEURISTIC, IngredientRecord(
            score=10, category="highly_inflammatory",
            reason="Hydrogenated fats contain trans fats which are highly inflammatory",
            is_additive=False, aliases=()))

    if any(kw in name_lower for kw in ("sugar", "syrup", "sweetener")):
        return (SOURCE_HEURISTIC, IngredientRecord(
            score=9, category="highly_inflammatory",
            reason="Sugar/syrup variants promote inflammatory insulin spikes",
            is_additive=False, aliases=()))

    if "artificial" in name_lower:
        return (SOURCE_HEURISTIC, IngredientRecord(
            score=8, category="inflammatory",
            reason="Artificial ingredients may trigger inflammatory responses",
            is_additive=True, aliases=()))

    # E-number pattern (E followed by 3-4 digits)
    if re.match(r"^e\d{3,4}[a-z]?$", name_lower):
        return (SOURCE_HEURISTIC, IngredientRecord(
            score=7, category="inflammatory",
            reason="Food additive (E-number) with potential inflammatory effects",
            is_additive=True, aliases=()))

    # Moderately inflammatory patterns
    if any(kw in name_lower for kw in ("bleached", "refined", "processed")):
        return (SOURCE_HEURISTIC, IngredientRecord(
            score=7, category="inflammatory",
            reason="Processed/refined ingredients tend to be more inflammatory",
            is_additive=False, aliases=()))

    if any(kw in name_lower for kw in ("color", "colour", "dye")):
        return (SOURCE_HEURISTIC, IngredientRecord(
            score=7, category="inflammatory",
            reason="Food colorings may trigger inflammatory responses",
            is_additive=True, aliases=()))

    # Anti-inflammatory patterns
    if any(kw in name_lower for kw in ("organic", "whole grain")):
        return (SOURCE_HEURISTIC, IngredientRecord(
            score=4, category="anti_inflammatory",
            reason="Organic/whole grain ingredients tend to be less inflammatory",
            is_additive=False, aliases=()))

    if any(kw in name_lower for kw in ("extract", "concentrate")) and \
       any(kw in name_lower for kw in ("fruit", "vegetable", "herb", "plant")):
        return (SOURCE_HEURISTIC, IngredientRecord(
            score=4, category="anti_inflammatory",
            reason="Plant-based extracts often have anti-inflammatory properties",
            is_additive=False, aliases=()))

    if any(kw in name_lower for kw in ("vitamin", "mineral")):
        return (SOURCE_HEURISTIC, IngredientRecord(
            score=4, category="anti_inflammatory",
            reason="Vitamins and minerals generally support anti-inflammatory processes",
            is_additive=True, aliases=()))

    # Default: neutral
    return (SOURCE_HEURISTIC, IngredientRecord(
        score=5, category="neutral",
        reason="Insufficient data to determine inflammatory properties",
        is_additive=False, aliases=()))


async def lookup_ingredient(name: str) -> Tuple[str, IngredientRecord]:
    """
    Main lookup function. Tries all 3 tiers in order.

    Args:
        name: Ingredient name to look up

    Returns:
        (source, IngredientRecord) - never returns None
    """
    # Tier 1: Static database
    result = lookup_static(name)
    if result is not None:
        return result

    # Tier 2: food_database (async)
    result = await lookup_food_database(name)
    if result is not None:
        return result

    # Tier 3: Heuristic (always returns)
    return lookup_heuristic(name)
