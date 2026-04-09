"""
3-tier ingredient lookup engine.

Lookup order:
  1. Static dict (primary, synchronous) - exact, substring, fuzzy
  2. food_database (fallback, async) - Supabase RPC
  3. Heuristic rules (last resort) - keyword matching

Never returns None - always produces a score.
"""

import asyncio
import re
import difflib
import logging
import time
from typing import Tuple, Optional, Dict

from .database import IngredientRecord, get_by_name, get_alias_index
from .scoring import ingredient_score_to_category

logger = logging.getLogger(__name__)

# Lookup source labels
SOURCE_STATIC = "static_db"
SOURCE_FOOD_DB = "food_database"
SOURCE_HEURISTIC = "heuristic"

# In-memory cache of food_database inflammation scores (loaded once lazily)
_food_db_cache: Optional[Dict[str, Tuple[int, str]]] = None  # name_lower -> (score, category)
_food_db_cache_loaded_at: float = 0
_food_db_cache_lock = asyncio.Lock()
_FOOD_DB_CACHE_TTL = 3600  # refresh every hour


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


async def _ensure_food_db_cache() -> Dict[str, Tuple[int, str]]:
    """Load all food_database inflammation scores into memory (once, then hourly refresh)."""
    global _food_db_cache, _food_db_cache_loaded_at

    now = time.monotonic()
    if _food_db_cache is not None and (now - _food_db_cache_loaded_at) < _FOOD_DB_CACHE_TTL:
        return _food_db_cache

    async with _food_db_cache_lock:
        # Double-check after acquiring lock
        if _food_db_cache is not None and (now - _food_db_cache_loaded_at) < _FOOD_DB_CACHE_TTL:
            return _food_db_cache

        try:
            from core.supabase_client import get_supabase
            supabase = get_supabase()

            cache: Dict[str, Tuple[int, str]] = {}
            offset = 0
            batch_size = 1000

            while True:
                result = supabase.client.table("food_database") \
                    .select("name, inflammatory_score, inflammatory_category") \
                    .not_.is_("inflammatory_score", "null") \
                    .eq("is_primary", True) \
                    .range(offset, offset + batch_size - 1) \
                    .execute()

                if not result.data:
                    break

                for row in result.data:
                    name = row.get("name")
                    score = row.get("inflammatory_score")
                    if name and score is not None:
                        score_int = int(score)
                        if 1 <= score_int <= 10:
                            category = row.get("inflammatory_category") or ingredient_score_to_category(score_int)
                            cache[name.lower().strip()] = (score_int, category)

                if len(result.data) < batch_size:
                    break
                offset += batch_size

            _food_db_cache = cache
            _food_db_cache_loaded_at = time.monotonic()
            logger.info(f"Loaded {len(cache)} inflammation scores from food_database into memory")
            return cache

        except Exception as e:
            logger.warning(f"Failed to load food_database cache: {e}", exc_info=True)
            if _food_db_cache is not None:
                return _food_db_cache
            _food_db_cache = {}
            _food_db_cache_loaded_at = time.monotonic()
            return _food_db_cache


async def lookup_food_database(name: str) -> Optional[Tuple[str, IngredientRecord]]:
    """
    Look up ingredient in the in-memory food_database cache.

    Uses a pre-loaded dict of all food_database rows with inflammation scores.
    Tries exact match, then substring match — all in-memory, no DB queries.

    Returns:
        (source_label, IngredientRecord) or None
    """
    try:
        cache = await _ensure_food_db_cache()
        if not cache:
            return None

        name_lower = name.lower().strip()

        # 1. Exact match
        if name_lower in cache:
            score, category = cache[name_lower]
            return (SOURCE_FOOD_DB, IngredientRecord(
                score=score, category=category,
                reason=f"Score from food database entry: {name}",
                is_additive=False, aliases=(),
            ))

        # 2. Substring match (input name found in a cached key)
        if len(name_lower) >= 5:
            for key, (score, category) in cache.items():
                if name_lower in key:
                    return (SOURCE_FOOD_DB, IngredientRecord(
                        score=score, category=category,
                        reason=f"Score from food database entry: {key}",
                        is_additive=False, aliases=(),
                    ))

        return None

    except Exception as e:
        logger.warning(f"food_database lookup failed for '{name}': {e}", exc_info=True)
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
