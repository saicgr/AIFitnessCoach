"""
Food Database Lookup Service.

Two-tier search architecture:
  1. food_nutrition_overrides — hand-curated premium (8K+ items, in-memory)
  2. food_database — quality-filtered by confidence_score (528K raw, DB trigram search)
  3. OpenFoodFacts API — live fallback

Provides single and batch food lookups with in-memory TTL caching.
"""

import asyncio
import re
import time
from typing import Optional, Dict, List

import httpx
from sqlalchemy import text

from core.logger import get_logger
from core.supabase_client import get_supabase
from services.food_database_service import OFF_USER_AGENT

logger = get_logger(__name__)

# Restaurant/fast food brands - our DB doesn't have their exact menu items
RESTAURANT_BRANDS = [
    'taco bell', 'mcdonalds', "mcdonald's", 'burger king', 'wendys', "wendy's",
    'chick-fil-a', 'chickfila', 'subway', 'chipotle', 'five guys', 'in-n-out',
    'popeyes', 'kfc', 'pizza hut', 'dominos', "domino's", 'papa johns',
    'starbucks', 'dunkin', 'panda express', 'chilis', "chili's", 'applebees',
    "applebee's", 'olive garden', 'red lobster', 'outback', 'ihop', "denny's",
    'sonic', 'arby', "arby's", 'jack in the box', 'carl', "carl's jr",
    'hardee', "hardee's", 'del taco', 'qdoba', 'panera', 'noodles',
    'wingstop', 'buffalo wild wings', 'hooters', 'zaxbys', "zaxby's",
    "freddy's", 'freddys',
    'kirkland', 'kirkland signature',
    # Smoothie chains
    'smoothie king', 'tropical smoothie', 'tropical smoothie cafe',
    'jamba', 'jamba juice',
    # Weight loss brands
    'walden farms', 'g hughes', 'smart ones', 'slimfast', 'slim fast',
    'atkins', 'miracle noodle', 'yasso', 'skinny pop', 'skinnypop',
    # Hormonal/metabolism/superfood brands
    'force of nature', 'epic', 'epic provisions',
    'kettle & fire', 'kettle and fire',
    'navitas', 'navitas organics',
    "bob's red mill", 'bobs red mill',
    'bulletproof', 'four sigmatic',
    "that's it", 'thats it',
    'bare', 'bare snacks', 'bragg',
    # Coffee chains
    "dunkin'", 'dunkin donuts',
    "peet's", 'peets', "peet's coffee",
    # Alcohol brands
    'white claw', 'truly', 'michelob',
    # Grocery brands
    'barilla', 'tyson', 'perdue', 'progresso', 'hillshire farm',
    # Salad chains
    'chopt', 'just salad', 'salad and go', 'tender greens',
    # Trending chains
    "dave's hot chicken", 'daves hot chicken',
    "buc-ee's", 'bucees', 'slim chickens',
    # Bowl / coffee chains
    'playa bowls', "scooter's coffee", 'scooters coffee',
    "carl's jr", 'carls jr',
    # Grocery store brands
    '365 by whole foods', '365 whole foods',
    'h-e-b', 'heb', 'publix', 'wegmans',
    # Meal kits
    'hellofresh', 'hello fresh', 'blue apron',
    "member's mark", 'members mark',
    # Fitness snack brands
    'one bar', 'fitcrunch', 'fit crunch',
]


class FoodDatabaseLookupService:
    """
    Service for looking up foods in Supabase with two-tier search.

    Features:
    - Food nutrition overrides (curated corrections, highest priority)
    - food_database filtered by confidence_score >= 0.6
    - Full-text search with trigram similarity
    - Single and batch food lookups returning per-100g nutrition data
    - Match quality filtering (restaurant brand skip + word overlap)
    - In-memory TTL cache (1 hour, max 1000 entries)
    - Singleton pattern
    """

    def __init__(self):
        self._cache: Dict[str, tuple] = {}  # {key: (timestamp, data)}
        self._cache_ttl = 3600  # 1 hour
        # Overrides: keyed by normalized name and variant names
        self._overrides: Dict[str, Dict] = {}
        # Deduplicated list of all override entries (one per DB row)
        self._overrides_list: List[Dict] = []
        # Word-level inverted index: word -> set of indices into _overrides_list
        self._overrides_word_index: Dict[str, set] = {}
        self._overrides_loaded_at: float = 0
        self._overrides_ttl = 1800  # 30 minutes

    # ── Cache helpers ──────────────────────────────────────────────

    def _get_cached(self, key: str):
        """Get cached data if not expired."""
        if key in self._cache:
            timestamp, data = self._cache[key]
            if time.time() - timestamp < self._cache_ttl:
                return data
            else:
                del self._cache[key]
        return None

    def _set_cached(self, key: str, data):
        """Cache data with timestamp. Evicts oldest entries if over 1000."""
        self._cache[key] = (time.time(), data)

        if len(self._cache) > 1000:
            sorted_keys = sorted(
                self._cache.keys(),
                key=lambda k: self._cache[k][0],
            )
            for old_key in sorted_keys[:100]:
                del self._cache[old_key]

    # ── Overrides ──────────────────────────────────────────────────

    async def _load_overrides(self):
        """Load active overrides from food_nutrition_overrides table into memory.
        Keyed by food_name_normalized + all variant_names for fast lookup.
        Refreshes every 30 minutes.

        NOTE: With 200K+ overrides, loading all into memory uses ~180MB.
        On 512MB Render instances this causes OOM. We now search overrides
        via DB queries instead (_search_overrides_db) and only keep a small
        exact-lookup dict for single-food lookups (get_food_nutrition).
        """
        if self._overrides_loaded_at and (time.time() - self._overrides_loaded_at < self._overrides_ttl):
            return

        # Mark as loaded to prevent repeated attempts on failure
        self._overrides_loaded_at = time.time()
        # Clear in-memory structures — we no longer load all overrides
        self._overrides = {}
        self._overrides_list = []
        self._overrides_word_index = {}
        logger.info("[FoodDB] Override search now uses DB queries (memory-safe mode)")

    async def _search_overrides_db(
        self,
        query: str,
        limit: int = 15,
        restaurant: Optional[str] = None,
        food_category: Optional[str] = None,
        region: Optional[str] = None,
    ) -> List[Dict]:
        """Search overrides via database query instead of in-memory scan.
        Uses two passes: exact/prefix matches first, then substring matches."""
        try:
            from core.supabase_client import get_supabase as _get_sb
            sb = _get_sb()

            def _build_query(pattern: str):
                q = sb.client.table("food_nutrition_overrides").select("*").eq("is_active", True)
                q = q.ilike("display_name", pattern)
                if restaurant:
                    q = q.ilike("restaurant_name", f"%{restaurant}%")
                if food_category:
                    q = q.eq("food_category", food_category)
                if region:
                    q = q.eq("region", region.upper())
                return q

            matches = []
            seen_names = set()

            if query:
                query_lower = query.lower().strip()

                # Pass 1: Exact name match (highest priority)
                exact = sb.client.table("food_nutrition_overrides").select("*").eq(
                    "is_active", True
                ).eq("food_name_normalized", query_lower).limit(1).execute()
                if exact.data:
                    row = exact.data[0]
                    name = row["display_name"]
                    matches.append(self._override_row_to_search_result(row))
                    seen_names.add(name)

                # Pass 2: Prefix matches (e.g., "Apple ..." but not "Pineapple")
                if len(matches) < limit:
                    result = _build_query(f"{query}%").limit(limit).execute()
                    if result.data:
                        for row in result.data:
                            name = row["display_name"]
                            if name not in seen_names:
                                matches.append(self._override_row_to_search_result(row))
                                seen_names.add(name)

                # Pass 3: Substring matches for remaining slots
                if len(matches) < limit:
                    remaining = limit - len(matches)
                    result2 = _build_query(f"% {query}%").limit(remaining).execute()
                    if result2.data:
                        for row in result2.data:
                            name = row["display_name"]
                            if name not in seen_names:
                                matches.append(self._override_row_to_search_result(row))
                                seen_names.add(name)
                                if len(matches) >= limit:
                                    break

                # Pass 4: Broad substring if still not enough
                if len(matches) < limit:
                    remaining = limit - len(matches)
                    result3 = _build_query(f"%{query}%").limit(remaining + len(matches)).execute()
                    if result3.data:
                        for row in result3.data:
                            name = row["display_name"]
                            if name not in seen_names:
                                matches.append(self._override_row_to_search_result(row))
                                seen_names.add(name)
                                if len(matches) >= limit:
                                    break
            else:
                # No query — browse by restaurant/category/region
                q = sb.client.table("food_nutrition_overrides").select("*").eq("is_active", True)
                if restaurant:
                    q = q.ilike("restaurant_name", f"%{restaurant}%")
                if food_category:
                    q = q.eq("food_category", food_category)
                if region:
                    q = q.eq("region", region.upper())
                result = q.limit(limit).execute()
                if result.data:
                    for row in result.data:
                        matches.append(self._override_row_to_search_result(row))

            return matches
        except Exception as e:
            logger.warning(f"[FoodDB] Override DB search failed: {e}")
            return []

    def _override_row_to_search_result(self, row: Dict) -> Dict:
        """Convert a raw DB row from food_nutrition_overrides to search result format."""
        result = {
            "name": row["display_name"],
            "calories_per_100g": float(row.get("calories_per_100g") or 0),
            "protein_per_100g": float(row.get("protein_per_100g") or 0),
            "carbs_per_100g": float(row.get("carbs_per_100g") or 0),
            "fat_per_100g": float(row.get("fat_per_100g") or 0),
            "fiber_per_100g": float(row.get("fiber_per_100g") or 0),
            "source": "verified",
            "brand": row.get("restaurant_name"),
            "category": row.get("food_category"),
            "weight_per_unit_g": float(row["default_weight_per_piece_g"]) if row.get("default_weight_per_piece_g") else None,
            "serving_weight_g": float(row["default_serving_g"]) if row.get("default_serving_g") else None,
            "default_count": int(row["default_count"]) if row.get("default_count") else 1,
            "verification_level": "verified",
        }
        for key in (
            "sodium_mg", "cholesterol_mg", "saturated_fat_g", "trans_fat_g",
            "potassium_mg", "calcium_mg", "iron_mg", "vitamin_a_ug",
            "vitamin_c_mg", "vitamin_d_iu", "magnesium_mg", "zinc_mg",
            "phosphorus_mg", "selenium_ug", "omega3_g",
        ):
            val = row.get(key)
            if val is not None:
                result[key] = float(val)
        return result

    async def _load_overrides_legacy(self):
        """Legacy: Load ALL overrides into memory. Only used as fallback.
        WARNING: Uses ~180MB with 200K+ overrides — avoid on memory-constrained instances."""
        if self._overrides and (time.time() - self._overrides_loaded_at < self._overrides_ttl):
            return

        try:
            supabase = get_supabase()
            async with supabase.get_session() as session:
                result = await asyncio.wait_for(
                    session.execute(
                        text("SELECT * FROM food_nutrition_overrides WHERE is_active = TRUE")
                    ),
                    timeout=10.0,
                )
                rows = [dict(r._mapping) for r in result.fetchall()]

            new_overrides: Dict[str, Dict] = {}
            new_overrides_list: List[Dict] = []
            for row in rows:
                override_data = {
                    "display_name": row["display_name"],
                    "calories_per_100g": float(row["calories_per_100g"]),
                    "protein_per_100g": float(row["protein_per_100g"]),
                    "carbs_per_100g": float(row["carbs_per_100g"]),
                    "fat_per_100g": float(row["fat_per_100g"]),
                    "fiber_per_100g": float(row.get("fiber_per_100g") or 0),
                    "override_weight_per_piece_g": float(row["default_weight_per_piece_g"]) if row.get("default_weight_per_piece_g") else None,
                    "override_serving_g": float(row["default_serving_g"]) if row.get("default_serving_g") else None,
                    "source": row.get("source", "manual"),
                    "restaurant_name": row.get("restaurant_name"),
                    "food_category": row.get("food_category"),
                    "default_count": int(row["default_count"]) if row.get("default_count") else 1,
                    # Micronutrients (per 100g)
                    "sodium_mg": float(row["sodium_mg"]) if row.get("sodium_mg") is not None else None,
                    "cholesterol_mg": float(row["cholesterol_mg"]) if row.get("cholesterol_mg") is not None else None,
                    "saturated_fat_g": float(row["saturated_fat_g"]) if row.get("saturated_fat_g") is not None else None,
                    "trans_fat_g": float(row["trans_fat_g"]) if row.get("trans_fat_g") is not None else None,
                    "potassium_mg": float(row["potassium_mg"]) if row.get("potassium_mg") is not None else None,
                    "calcium_mg": float(row["calcium_mg"]) if row.get("calcium_mg") is not None else None,
                    "iron_mg": float(row["iron_mg"]) if row.get("iron_mg") is not None else None,
                    "vitamin_a_ug": float(row["vitamin_a_ug"]) if row.get("vitamin_a_ug") is not None else None,
                    "vitamin_c_mg": float(row["vitamin_c_mg"]) if row.get("vitamin_c_mg") is not None else None,
                    "vitamin_d_iu": float(row["vitamin_d_iu"]) if row.get("vitamin_d_iu") is not None else None,
                    "magnesium_mg": float(row["magnesium_mg"]) if row.get("magnesium_mg") is not None else None,
                    "zinc_mg": float(row["zinc_mg"]) if row.get("zinc_mg") is not None else None,
                    "phosphorus_mg": float(row["phosphorus_mg"]) if row.get("phosphorus_mg") is not None else None,
                    "selenium_ug": float(row["selenium_ug"]) if row.get("selenium_ug") is not None else None,
                    "omega3_g": float(row["omega3_g"]) if row.get("omega3_g") is not None else None,
                    "variant_names": row.get("variant_names") or [],
                    "region": row.get("region"),
                }
                new_overrides_list.append(override_data)
                # Key by primary normalized name
                primary_key = row["food_name_normalized"].lower().strip()
                new_overrides[primary_key] = override_data
                # Also key by each variant name
                variant_names = row.get("variant_names") or []
                for variant in variant_names:
                    if variant:
                        new_overrides[variant.lower().strip()] = override_data

            # Build word-level inverted index for fast search
            word_index: Dict[str, set] = {}
            for idx, override in enumerate(new_overrides_list):
                # Index words from display_name
                display_words = override["display_name"].lower().split()
                for w in display_words:
                    w = w.strip("(),.'\"!?-")
                    if len(w) >= 2:
                        word_index.setdefault(w, set()).add(idx)
                # Index words from variant_names
                for vn in (override.get("variant_names") or []):
                    if not isinstance(vn, str):
                        continue
                    vn_lower = vn.lower()
                    # Index the full variant as a key too
                    word_index.setdefault(vn_lower, set()).add(idx)
                    for w in vn_lower.split():
                        w = w.strip("(),.'\"!?-")
                        if len(w) >= 2:
                            word_index.setdefault(w, set()).add(idx)

            self._overrides = new_overrides
            self._overrides_list = new_overrides_list
            self._overrides_word_index = word_index
            self._overrides_loaded_at = time.time()
            logger.info(f"[FoodDB] Loaded {len(rows)} overrides ({len(new_overrides)} keys, {len(word_index)} index terms)")

        except Exception as e:
            logger.warning(f"[FoodDB] Failed to load overrides: {e}")
            # Keep stale data if available; if first load failed, retry once with sync client
            if not self._overrides:
                try:
                    from core.supabase_client import get_supabase as _get_sb
                    sb = _get_sb()
                    result = sb.client.table("food_nutrition_overrides").select("*").eq("is_active", True).execute()
                    if result.data:
                        logger.info(f"[FoodDB] Retry loaded {len(result.data)} overrides via sync client")
                        # Re-run the same indexing logic with the sync data
                        new_overrides: Dict[str, Dict] = {}
                        new_overrides_list: List[Dict] = []
                        for row in result.data:
                            override_data = {
                                "display_name": row["display_name"],
                                "calories_per_100g": float(row["calories_per_100g"]),
                                "protein_per_100g": float(row["protein_per_100g"]),
                                "carbs_per_100g": float(row["carbs_per_100g"]),
                                "fat_per_100g": float(row["fat_per_100g"]),
                                "fiber_per_100g": float(row.get("fiber_per_100g") or 0),
                                "override_weight_per_piece_g": float(row["default_weight_per_piece_g"]) if row.get("default_weight_per_piece_g") else None,
                                "override_serving_g": float(row["default_serving_g"]) if row.get("default_serving_g") else None,
                                "source": row.get("source", "manual"),
                                "restaurant_name": row.get("restaurant_name"),
                                "food_category": row.get("food_category"),
                                "default_count": int(row["default_count"]) if row.get("default_count") else 1,
                                "variant_names": row.get("variant_names") or [],
                                "region": row.get("region"),
                            }
                            new_overrides_list.append(override_data)
                            primary_key = row["food_name_normalized"].lower().strip()
                            new_overrides[primary_key] = override_data
                            for variant in (row.get("variant_names") or []):
                                if variant:
                                    new_overrides[variant.lower().strip()] = override_data
                        word_index: Dict[str, set] = {}
                        for idx, ov in enumerate(new_overrides_list):
                            for w in ov["display_name"].lower().split():
                                w = w.strip("(),.'\"!?-")
                                if len(w) >= 2:
                                    word_index.setdefault(w, set()).add(idx)
                            for vn in (ov.get("variant_names") or []):
                                if not isinstance(vn, str):
                                    continue
                                vn_lower = vn.lower()
                                word_index.setdefault(vn_lower, set()).add(idx)
                                for w in vn_lower.split():
                                    w = w.strip("(),.'\"!?-")
                                    if len(w) >= 2:
                                        word_index.setdefault(w, set()).add(idx)
                        self._overrides = new_overrides
                        self._overrides_list = new_overrides_list
                        self._overrides_word_index = word_index
                        self._overrides_loaded_at = time.time()
                except Exception as retry_err:
                    logger.warning(f"[FoodDB] Retry also failed: {retry_err}")
                    self._overrides = {}

    def _check_override(self, food_name: str) -> Optional[Dict]:
        """Check if a food name has a curated override.
        Uses exact match only (no substring) to avoid false positives
        like 'chicken dosa' matching 'dosa'."""
        if not food_name:
            return None

        normalized = food_name.lower().strip()

        # Try in-memory cache first
        override = self._overrides.get(normalized)
        if override:
            logger.info(
                f"[FoodDB] OVERRIDE HIT (cache): '{food_name}' → "
                f"{override['display_name']} ({override['calories_per_100g']} cal/100g)"
            )
            return override

        # Fall back to DB query for exact match
        try:
            from core.supabase_client import get_supabase as _get_sb
            sb = _get_sb()
            result = sb.client.table("food_nutrition_overrides").select("*").eq(
                "is_active", True
            ).eq("food_name_normalized", normalized).limit(1).execute()
            if result.data:
                row = result.data[0]
                override_data = {
                    "display_name": row["display_name"],
                    "calories_per_100g": float(row.get("calories_per_100g") or 0),
                    "protein_per_100g": float(row.get("protein_per_100g") or 0),
                    "carbs_per_100g": float(row.get("carbs_per_100g") or 0),
                    "fat_per_100g": float(row.get("fat_per_100g") or 0),
                    "fiber_per_100g": float(row.get("fiber_per_100g") or 0),
                    "override_weight_per_piece_g": float(row["default_weight_per_piece_g"]) if row.get("default_weight_per_piece_g") else None,
                    "override_serving_g": float(row["default_serving_g"]) if row.get("default_serving_g") else None,
                    "source": row.get("source", "manual"),
                    "restaurant_name": row.get("restaurant_name"),
                    "food_category": row.get("food_category"),
                    "default_count": int(row["default_count"]) if row.get("default_count") else 1,
                    "variant_names": row.get("variant_names") or [],
                    "region": row.get("region"),
                }
                # Cache for future lookups
                self._overrides[normalized] = override_data
                logger.info(
                    f"[FoodDB] OVERRIDE HIT (db): '{food_name}' → "
                    f"{override_data['display_name']} ({override_data['calories_per_100g']} cal/100g)"
                )
                return override_data
        except Exception as e:
            logger.debug(f"[FoodDB] Override DB lookup failed for '{food_name}': {e}")

        return None

    def _override_to_nutrition(self, override: Dict) -> Dict:
        """Convert an override dict to the standard nutrition dict format."""
        return {
            "calories_per_100g": override["calories_per_100g"],
            "protein_per_100g": override["protein_per_100g"],
            "carbs_per_100g": override["carbs_per_100g"],
            "fat_per_100g": override["fat_per_100g"],
            "fiber_per_100g": override["fiber_per_100g"],
            "override_weight_per_piece_g": override.get("override_weight_per_piece_g"),
            "override_serving_g": override.get("override_serving_g"),
        }

    # Match-score → similarity mapping for override search results
    _MATCH_SCORE_TO_SIMILARITY = {
        0: 1.0,   # Exact display_name match
        1: 0.95,  # Prefix match on display_name
        2: 0.85,  # Query is a whole word in display_name
        3: 0.75,  # Substring match on display_name
        4: 0.65,  # Exact variant name match
        5: 0.55,  # Variant substring/word match
    }

    def _override_to_search_result(self, override: Dict, match_score: int = 0) -> Dict:
        """Convert an override dict to a search result dict for the food picker UI.
        match_score controls the similarity_score (0=best, 5=worst)."""
        similarity = self._MATCH_SCORE_TO_SIMILARITY.get(match_score, 0.55)
        result = {
            "name": override["display_name"],
            "calories_per_100g": override["calories_per_100g"],
            "protein_per_100g": override["protein_per_100g"],
            "carbs_per_100g": override["carbs_per_100g"],
            "fat_per_100g": override["fat_per_100g"],
            "fiber_per_100g": override["fiber_per_100g"],
            "source": "verified",
            "similarity_score": similarity,
        }
        if override.get("restaurant_name"):
            result["brand"] = override["restaurant_name"]
        if override.get("food_category"):
            result["category"] = override["food_category"]
        if override.get("override_weight_per_piece_g"):
            result["weight_per_unit_g"] = override["override_weight_per_piece_g"]
        if override.get("override_serving_g"):
            result["serving_weight_g"] = override["override_serving_g"]
        result["default_count"] = override.get("default_count", 1)
        # Include micronutrients if available
        for key in (
            "sodium_mg", "cholesterol_mg", "saturated_fat_g", "trans_fat_g",
            "potassium_mg", "calcium_mg", "iron_mg", "vitamin_a_ug",
            "vitamin_c_mg", "vitamin_d_iu", "magnesium_mg", "zinc_mg",
            "phosphorus_mg", "selenium_ug", "omega3_g",
        ):
            val = override.get(key)
            if val is not None:
                result[key] = val
        return result

    def _find_matching_overrides_for_search(
        self,
        query: str,
        restaurant: Optional[str] = None,
        food_category: Optional[str] = None,
        region: Optional[str] = None,
    ) -> List[Dict]:
        """Find overrides matching a search query for injection into search results.
        Uses word-level inverted index for fast lookup instead of iterating all overrides.
        Optionally filters by restaurant_name, food_category, and/or region (ISO alpha-2)."""
        if not self._overrides_list:
            return []

        query_lower = query.lower().strip() if query else ""
        restaurant_lower = restaurant.lower().strip() if restaurant else None
        category_lower = food_category.lower().strip() if food_category else None
        region_upper = region.upper().strip() if region else None

        seen_display_names: set = set()
        matches: List[Dict] = []

        # If no query, browse by restaurant/category/region (iterate filtered subset)
        if not query_lower:
            if not restaurant_lower and not category_lower and not region_upper:
                return []
            for override in self._overrides_list:
                if restaurant_lower:
                    if restaurant_lower not in (override.get("restaurant_name") or "").lower():
                        continue
                if category_lower:
                    if category_lower != (override.get("food_category") or "").lower():
                        continue
                if region_upper:
                    if (override.get("region") or "").upper() != region_upper:
                        continue
                display = override["display_name"]
                if display not in seen_display_names:
                    matches.append(self._override_to_search_result(override))
                    seen_display_names.add(display)
            return matches

        # Use inverted index to find candidate overrides
        candidate_indices: set = set()

        def _stem_simple(word: str) -> str:
            """Basic plural stripping: bananas→banana, berries→berry, tomatoes→tomato."""
            if len(word) <= 3:
                return word
            if word.endswith("ies") and len(word) > 4:
                return word[:-3] + "y"  # berries→berry, cherries→cherry
            if word.endswith("oes") and len(word) > 4:
                return word[:-2]  # tomatoes→tomato, potatoes→potato
            if word.endswith("ches") or word.endswith("shes") or word.endswith("xes"):
                return word[:-2]  # peaches→peach, dishes→dish
            if word.endswith("s") and not word.endswith("ss"):
                return word[:-1]  # bananas→banana, apples→apple, eggs→egg
            return word

        def _lookup_word(word: str) -> None:
            """Look up a word in the index, trying original + stemmed form."""
            if word in self._overrides_word_index:
                candidate_indices.update(self._overrides_word_index[word])
            stemmed = _stem_simple(word)
            if stemmed != word and stemmed in self._overrides_word_index:
                candidate_indices.update(self._overrides_word_index[stemmed])

        # Check full query as a key (e.g., "coke" matches variant "coke")
        _lookup_word(query_lower)

        # Check each query word
        query_words = [w.strip("(),.'\"!?-") for w in query_lower.split() if len(w) >= 2]
        for w in query_words:
            _lookup_word(w)

        # Score and filter candidates — collect (match_score, override) tuples
        scored_matches: List[tuple] = []  # (match_score, override)

        for idx in candidate_indices:
            override = self._overrides_list[idx]

            # Filter by restaurant if specified
            if restaurant_lower:
                if restaurant_lower not in (override.get("restaurant_name") or "").lower():
                    continue
            # Filter by food_category if specified
            if category_lower:
                if category_lower != (override.get("food_category") or "").lower():
                    continue
            # Filter by region (ISO alpha-2) if specified
            if region_upper:
                if (override.get("region") or "").upper() != region_upper:
                    continue

            display = override["display_name"]
            if display in seen_display_names:
                continue

            display_lower = display.lower()

            # Determine match quality score (lower = better)
            match_score: Optional[int] = None

            # Display name matches (scores 0-3)
            if display_lower == query_lower:
                match_score = 0  # Exact display_name match
            elif display_lower.startswith(query_lower):
                match_score = 1  # Prefix match
            elif re.search(r'\b' + re.escape(query_lower) + r'\b', display_lower):
                match_score = 2  # Whole-word match in display_name
            elif query_lower in display_lower or display_lower in query_lower:
                match_score = 3  # Substring match

            # Variant name matches (scores 4-5)
            if match_score is None:
                variant_names = override.get("variant_names") or []
                for vn in variant_names:
                    vn_lower = vn.lower() if isinstance(vn, str) else ""
                    if not vn_lower:
                        continue
                    if vn_lower == query_lower or query_lower == vn_lower:
                        match_score = 4  # Exact variant match
                        break
                    if query_lower in vn_lower or vn_lower in query_lower:
                        match_score = 5  # Variant substring match
                        break

            # Word overlap fallback (scores as 3 — substring-level)
            if match_score is None:
                significant_words = [w for w in query_words if len(w) >= 3]
                if significant_words:
                    overlap = sum(1 for w in significant_words if w in display_lower)
                    if overlap / len(significant_words) >= 0.5:
                        match_score = 3

            if match_score is not None:
                scored_matches.append((match_score, override))
                seen_display_names.add(display)

        # Sort by match quality (lower score = better match)
        scored_matches.sort(key=lambda x: x[0])

        matches = [
            self._override_to_search_result(override, match_score=score)
            for score, override in scored_matches
        ]
        return matches

    # ── Multi-food query splitting ─────────────────────────────────

    # Pre-compiled regex for word-based multi-food delimiters.
    # Order matters: longer phrases first to avoid partial matches.
    _WORD_DELIMITERS_RE = re.compile(
        r'\s+along\s+with\s+'       # "biryani along with raita"
        r'|\s+paired\s+with\s+'     # "steak paired with mashed potatoes"
        r'|\s+served\s+with\s+'     # "dosa served with chutney"
        r'|\s+on\s+the\s+side\s+'   # "burger on the side fries" (rare)
        r'|\s+alongside\s+'         # "steak alongside veggies"
        r'|\s+and\s+a\s+'           # "burger and a coke"
        r'|\s+and\s+some\s+'        # "rice and some dal"
        r'|\s+and\s+'               # "rice and dal"
        r'|\s+with\s+a\s+'          # "pasta with a salad"
        r'|\s+with\s+some\s+'       # "roti with some sabzi"
        r'|\s+with\s+'              # "biryani with raita"
        r'|\s+plus\s+'              # "burger plus fries"
        r'|\s+also\s+'              # "dosa also sambhar"
        r'|\s+w/\s*'                # "naan w/ curry" or "naan w/curry"
        r'|\s*&\s*'                 # "rice & dal"
        r'|\s*\+\s*',              # "rice + chicken"
        flags=re.IGNORECASE,
    )

    # Hard delimiters that always mean separate foods.
    # Commas, semicolons, pipes, newlines, and " / " (slash with spaces).
    # Slash without spaces (e.g. "pizza/pasta") also splits, but NOT fractions
    # like "1/2" or shorthand like "w/".
    _HARD_DELIMITERS_RE = re.compile(r'[,;|\n]+')
    _SLASH_DELIMITERS_RE = re.compile(r'\s+/\s+')  # " / " with spaces
    _BARE_SLASH_RE = re.compile(r'(?<![0-9])/(?![0-9])')  # "/" not in fractions like "1/2"

    def _split_multi_query(self, query: str) -> List[str]:
        """Split multi-food queries into individual search terms.

        Phase 1 — Hard delimiters (always split, no override check):
            Commas, semicolons, pipes, newlines, " / " (spaced slash)
        Phase 2 — Bare slash "pizza/pasta" (not fractions "1/2", not "w/"):
            Splits unless full query is a known override
        Phase 3 — Word delimiters (override-protected):
            "and", "with", "along with", "paired with", "served with",
            "alongside", "plus", "also", "w/", "&", "+"

        Preserves compound foods that exist as overrides
        (e.g., "mac and cheese", "fish and chips", "rice with lentils").

        Examples:
            "chicken biryani with raita"       → ["chicken biryani", "raita"]
            "coke and biryani and ice cream"   → ["coke", "biryani", "ice cream"]
            "burger and a coke"                → ["burger", "coke"]
            "mac and cheese"                   → ["mac and cheese"]  (override)
            "fish and chips"                   → ["fish and chips"]  (override)
            "coke, biryani, ice cream"         → ["coke", "biryani", "ice cream"]
            "rice; dal; roti"                  → ["rice", "dal", "roti"]
            "tea | coffee"                     → ["tea", "coffee"]
            "pizza / pasta"                    → ["pizza", "pasta"]
            "tea/coffee"                       → ["tea", "coffee"]
            "rice + chicken"                   → ["rice", "chicken"]
            "dosa served with chutney"         → ["dosa", "chutney"]
            "steak alongside veggies"          → ["steak", "veggies"]
            "burger plus fries"                → ["burger", "fries"]
            "dosa also sambhar"                → ["dosa", "sambhar"]
            "naan w/ butter chicken"           → ["naan", "butter chicken"]
            "steak paired with mashed potatoes"→ ["steak", "mashed potatoes"]
            "biryani along with raita"         → ["biryani", "raita"]
            "pasta with a salad"               → ["pasta", "salad"]
        """
        q = query.strip()
        if not q:
            return []

        q_lower = q.lower()

        # ── Phase 1: Hard delimiters — always split, recurse each part ──
        if self._HARD_DELIMITERS_RE.search(q):
            parts = [p.strip() for p in self._HARD_DELIMITERS_RE.split(q) if p.strip()]
            final: List[str] = []
            for part in parts:
                final.extend(self._split_multi_query(part))
            return final if len(final) > 1 else [q]

        # " / " with spaces — clear separator like "pizza / pasta"
        if self._SLASH_DELIMITERS_RE.search(q):
            parts = [p.strip() for p in self._SLASH_DELIMITERS_RE.split(q) if p.strip()]
            if len(parts) > 1:
                final = []
                for part in parts:
                    final.extend(self._split_multi_query(part))
                return final if len(final) > 1 else [q]

        # ── Phase 2: Bare slash — "tea/coffee" but NOT "1/2" ──
        # Skip if contains "w/" (shorthand for "with", handled in Phase 3)
        if '/' in q and self._BARE_SLASH_RE.search(q) and not re.search(r'\bw/', q, re.IGNORECASE):
            parts = [p.strip() for p in q.split('/') if p.strip()]
            if len(parts) > 1:
                if self._overrides.get(q_lower):
                    return [q]
                return parts

        # ── Phase 3: Word delimiters — override-protected ──
        if not self._WORD_DELIMITERS_RE.search(q):
            return [q]

        # Full query is a known compound food → don't split
        if self._overrides.get(q_lower):
            return [q]

        parts = [p.strip() for p in self._WORD_DELIMITERS_RE.split(q) if p.strip()]
        # Filter out parts that are too short to be valid food names (e.g. "1", "1 c")
        # Keep only parts with at least one alphabetic word of 3+ characters
        parts = [p for p in parts if any(len(w) >= 3 and w.isalpha() for w in p.split())]
        return parts if len(parts) > 1 else [q]

    def _filter_search_results(self, query: str, db_foods: List[Dict]) -> List[Dict]:
        """Post-query word-overlap filter to remove false-positive trigram matches.

        - similarity >= 0.5: always keep (strong match)
        - similarity < 0.5 + single-word query: keep if any result word startswith query word
        - similarity < 0.5 + multi-word query: keep if at least one query word appears in result name
        """
        if not query or not db_foods:
            return db_foods
        query_words = set(query.lower().split())
        filtered = []
        for food in db_foods:
            sim = food.get("similarity_score", 0) or 0
            if sim >= 0.5:
                filtered.append(food)
                continue
            name_lower = food.get("name", "").lower()
            name_words = set(name_lower.split())
            if len(query_words) == 1:
                qw = next(iter(query_words))
                if any(nw.startswith(qw) for nw in name_words):
                    filtered.append(food)
            else:
                if query_words & name_words:
                    filtered.append(food)
        return filtered

    # ── OpenFoodFacts text-search fallback ─────────────────────────

    async def _search_off_text(self, query: str, limit: int = 20) -> List[Dict]:
        """OpenFoodFacts text-search fallback for typos / zero-result RPC queries."""
        try:
            async with httpx.AsyncClient(
                timeout=httpx.Timeout(4.0, connect=2.0),
                headers={"User-Agent": OFF_USER_AGENT},
            ) as client:
                resp = await client.get(
                    "https://world.openfoodfacts.org/cgi/search.pl",
                    params={
                        "search_terms": query,
                        "search_simple": 1,
                        "action": "process",
                        "json": 1,
                        "page_size": limit,
                        "fields": "product_name,nutriments,serving_quantity,brands",
                    },
                )
                resp.raise_for_status()
                data = resp.json()

            results: List[Dict] = []
            for p in data.get("products", []):
                name = p.get("product_name")
                if not name:
                    continue
                n = p.get("nutriments", {})
                brand = p.get("brands", "")
                display_name = f"{name} ({brand})" if brand else name
                results.append({
                    "id": None,
                    "name": display_name,
                    "source": "openfoodfacts",
                    "brand": brand,
                    "category": None,
                    "calories_per_100g": n.get("energy-kcal_100g", 0) or 0,
                    "protein_per_100g": n.get("proteins_100g", 0) or 0,
                    "fat_per_100g": n.get("fat_100g", 0) or 0,
                    "carbs_per_100g": n.get("carbohydrates_100g", 0) or 0,
                    "fiber_per_100g": n.get("fiber_100g", 0) or 0,
                    "sugar_per_100g": n.get("sugars_100g", 0) or 0,
                    "serving_description": f"{p.get('serving_quantity', '')}g" if p.get("serving_quantity") else None,
                    "serving_weight_g": p.get("serving_quantity"),
                    "similarity_score": 0.5,
                })
            logger.info(f"[FoodDB] OFF fallback returned {len(results)} results for '{query}'")
            return results
        except Exception as e:
            logger.warning(f"[FoodDB] OFF fallback failed for '{query}': {e}")
            return []

    # ── Match quality ──────────────────────────────────────────────

    @staticmethod
    def _is_good_match(query: str, result_name: str) -> bool:
        """
        Check if a database result is a good match for the query.
        Avoids using wrong products (e.g., "Cinnabon Pudding" for "Cinnabon Delights").

        Ported from gemini_service.py _is_good_usda_match.
        """
        query_lower = query.lower().strip()
        desc_lower = result_name.lower().strip()

        # If query mentions a restaurant brand, DB probably doesn't have the right item
        for brand in RESTAURANT_BRANDS:
            if brand in query_lower:
                logger.info(
                    f"[FoodDB] Skipping match - '{query}' is a restaurant item"
                )
                return False

        # Check word overlap: split query into significant words (3+ chars)
        query_words = [w for w in query_lower.split() if len(w) >= 3]
        if not query_words:
            return False

        matches = sum(1 for word in query_words if word in desc_lower)
        match_ratio = matches / len(query_words)

        # Require at least 50% of words to match
        if match_ratio < 0.5:
            logger.info(
                f"[FoodDB] Poor match - query='{query}' vs result='{result_name}' "
                f"(match_ratio={match_ratio:.0%})"
            )
            return False

        return True

    # ── Quality-filtered food_database search (tier 2) ─────────────

    async def _search_quality_foods(
        self, query: str, limit: int = 20, offset: int = 0
    ) -> List[Dict]:
        """Search food_database filtered by confidence_score >= 0.6.
        Returns high-quality results ordered by confidence_score * similarity."""
        try:
            supabase = get_supabase()
            async with supabase.get_session() as session:
                result = await asyncio.wait_for(
                    session.execute(
                        text("""
                            SELECT *,
                                   similarity(name_normalized, :q) AS similarity_score
                            FROM food_database
                            WHERE is_primary = TRUE
                              AND confidence_score >= 0.6
                              AND name_normalized % :q
                            ORDER BY confidence_score DESC,
                                     similarity(name_normalized, :q) DESC
                            LIMIT :lim OFFSET :off
                        """),
                        {"q": query.lower().strip(), "lim": limit, "off": offset},
                    ),
                    timeout=3.0,
                )
                rows = [dict(row._mapping) for row in result.fetchall()]

            foods: List[Dict] = []
            for row in rows:
                foods.append({
                    "id": row.get("id"),
                    "name": row.get("name", ""),
                    "source": row.get("source", ""),
                    "brand": row.get("brand"),
                    "category": row.get("category"),
                    "calories_per_100g": row.get("calories_per_100g", 0),
                    "protein_per_100g": row.get("protein_per_100g", 0),
                    "fat_per_100g": row.get("fat_per_100g", 0),
                    "carbs_per_100g": row.get("carbs_per_100g", 0),
                    "fiber_per_100g": row.get("fiber_per_100g"),
                    "sugar_per_100g": row.get("sugar_per_100g"),
                    "serving_weight_g": row.get("serving_weight_g"),
                    "similarity_score": row.get("similarity_score", 0),
                    "confidence_score": row.get("confidence_score"),
                    "verification_level": row.get("verification_level"),
                })
            logger.info(f"[FoodDB] Quality foods returned {len(foods)} results for '{query}'")
            return foods
        except asyncio.TimeoutError:
            logger.warning(f"[FoodDB] Quality foods search timed out for '{query}'")
            return []
        except Exception as e:
            logger.warning(f"[FoodDB] Quality foods search failed for '{query}': {e}")
            return []

    # ── Public API ─────────────────────────────────────────────────

    async def search_foods(
        self,
        query: str,
        page_size: int = 20,
        page: int = 1,
        category: Optional[str] = None,
        source: Optional[str] = None,
        restaurant: Optional[str] = None,
        food_category: Optional[str] = None,
        region: Optional[str] = None,
    ) -> List[Dict]:
        """
        Search the food database with pagination.
        Override entries matching the query appear first with source='verified'.
        Optionally filter overrides by restaurant, food_category, and/or region (ISO alpha-2).
        """
        # Normalize smart quotes from mobile keyboards (curly → straight)
        query = query.replace('\u2019', "'").replace('\u2018', "'").replace('\u201c', '"').replace('\u201d', '"').strip()
        if not query and not restaurant and not food_category and not region:
            return []

        cache_key = f"search:{(query or '').lower()}:{page_size}:{page}:{category}:{source}:{restaurant}:{food_category}:{region}"
        cached = self._get_cached(cache_key)
        if cached is not None:
            return cached

        logger.info(f"[FoodDB] Searching for '{query}' (page={page}, size={page_size}, restaurant={restaurant}, food_category={food_category})")

        # Load overrides (TTL-gated, no-op if fresh)
        await self._load_overrides()

        # Handle multi-food queries (e.g., "coke and biryani and ice cream")
        query_parts = self._split_multi_query(query)
        if len(query_parts) > 1:
            logger.info(f"[FoodDB] Multi-food query split: '{query}' → {query_parts}")
            all_results: List[Dict] = []
            seen_names: set = set()
            per_part_limit = max(5, page_size // len(query_parts))

            for part in query_parts:
                part_results = await self.search_foods(
                    query=part, page_size=per_part_limit, page=1,
                    category=category, source=source,
                    restaurant=restaurant, food_category=food_category,
                    region=region,
                )
                for r in part_results:
                    name_lower = r.get("name", "").lower()
                    if name_lower not in seen_names:
                        r["matched_query"] = part
                        all_results.append(r)
                        seen_names.add(name_lower)

            self._set_cached(cache_key, all_results[:page_size])
            return all_results[:page_size]

        try:
            supabase = get_supabase()
            offset = (page - 1) * page_size

            # Step 1: Search overrides via DB query — ALWAYS returned
            override_results = []
            if page == 1:
                override_results = await self._search_overrides_db(
                    query, limit=page_size, restaurant=restaurant,
                    food_category=food_category, region=region,
                )

            # When a region/country filter is active, only return country-tagged overrides
            # (food_database table doesn't have region data)
            quality_foods = []
            db_foods = []

            if not region:
                # Step 2 & 3: Search quality foods AND RPC concurrently
                if query and len(override_results) < page_size:
                    remaining = page_size - len(override_results)

                    async def _fetch_quality():
                        try:
                            return await self._search_quality_foods(query, remaining, offset)
                        except Exception:
                            return []

                    async def _fetch_rpc():
                        try:
                            async with supabase.get_session() as session:
                                result = await asyncio.wait_for(
                                    session.execute(
                                        text("SELECT * FROM search_food_database(:q, :lim, :off)"),
                                        {"q": query, "lim": remaining, "off": offset},
                                    ),
                                    timeout=3.0,
                                )
                                return [dict(row._mapping) for row in result.fetchall()]
                        except asyncio.TimeoutError:
                            logger.warning(f"[FoodDB] RPC timed out for '{query}'")
                            return []
                        except Exception as rpc_err:
                            logger.warning(f"[FoodDB] RPC failed for '{query}': {rpc_err}")
                            return []

                    # Run both searches concurrently — total wait = max(quality, rpc) not sum
                    quality_foods, db_foods = await asyncio.gather(
                        _fetch_quality(), _fetch_rpc()
                    )
                    quality_foods = self._filter_search_results(query, quality_foods)

                # Word-overlap filter: remove false-positive trigram matches
                db_foods = self._filter_search_results(query, db_foods)

                # If nothing found anywhere, try OFF as last resort
                if not db_foods and not quality_foods and not override_results and query:
                    db_foods = await self._search_off_text(query, page_size)
                    db_foods = self._filter_search_results(query, db_foods)

                # Post-filter by source/category if specified
                if source:
                    source_lower = source.lower()
                    quality_foods = [f for f in quality_foods if (f.get("source") or "").lower().startswith(source_lower)]
                    db_foods = [f for f in db_foods if (f.get("source") or "").lower() == source_lower]
                if category:
                    category_lower = category.lower()
                    quality_foods = [f for f in quality_foods if category_lower in (f.get("category") or "").lower()]
                    db_foods = [f for f in db_foods if category_lower in (f.get("category") or "").lower()]

            # Assemble: Overrides > Quality DB > Unfiltered DB (deduped)
            override_names = {r["name"].lower() for r in override_results}
            quality_foods = [f for f in quality_foods if f.get("name", "").lower() not in override_names]
            higher_names = override_names | {f.get("name", "").lower() for f in quality_foods}
            db_foods = [f for f in db_foods if f.get("name", "").lower() not in higher_names]
            foods = override_results + quality_foods + db_foods

            logger.info(f"[FoodDB] Found {len(foods)} results for '{query}'")
            self._set_cached(cache_key, foods)
            return foods

        except Exception as e:
            logger.error(f"[FoodDB] Search failed for '{query}': {e}")
            raise

    async def search_foods_unified(
        self,
        query: str,
        user_id: str,
        page_size: int = 20,
        page: int = 1,
        restaurant: Optional[str] = None,
        food_category: Optional[str] = None,
        region: Optional[str] = None,
    ) -> List[Dict]:
        """
        Search food database unified with user's saved foods.
        Priority: Saved Foods > Overrides > Curated DB.
        Falls back to regular search_foods if user_id is empty.
        """
        query = query.strip()
        if not query and not restaurant and not food_category and not region:
            return []

        if not user_id:
            return await self.search_foods(
                query=query, page_size=page_size, page=page,
                restaurant=restaurant, food_category=food_category, region=region,
            )

        cache_key = f"unified_search:{(query or '').lower()}:{user_id}:{page_size}:{page}:{restaurant}:{food_category}:{region}"
        cached = self._get_cached(cache_key)
        if cached is not None:
            return cached

        logger.info(f"[FoodDB] Unified search for '{query}' (user={user_id[:8]}..., page={page}, size={page_size})")

        # Load overrides (TTL-gated, no-op if fresh)
        await self._load_overrides()

        # Handle multi-food queries (e.g., "coke and biryani and ice cream")
        query_parts = self._split_multi_query(query)
        if len(query_parts) > 1:
            logger.info(f"[FoodDB] Multi-food query split: '{query}' → {query_parts}")
            all_results: List[Dict] = []
            seen_names: set = set()
            per_part_limit = max(5, page_size // len(query_parts))

            for part in query_parts:
                part_results = await self.search_foods_unified(
                    query=part, user_id=user_id,
                    page_size=per_part_limit, page=1,
                    restaurant=restaurant, food_category=food_category, region=region,
                )
                for r in part_results:
                    name_lower = r.get("name", "").lower()
                    if name_lower not in seen_names:
                        r["matched_query"] = part
                        all_results.append(r)
                        seen_names.add(name_lower)

            self._set_cached(cache_key, all_results[:page_size])
            return all_results[:page_size]

        try:
            supabase = get_supabase()
            offset = (page - 1) * page_size

            # Step 1: Search overrides via DB query — ALWAYS returned
            override_results = []
            if page == 1:
                override_results = await self._search_overrides_db(
                    query, limit=page_size, restaurant=restaurant,
                    food_category=food_category, region=region,
                )

            # Step 2: Fetch saved foods (fast LIKE on user's small table, <100ms)
            saved_foods = []
            if query and user_id:
                try:
                    async with supabase.get_session() as session:
                        result = await asyncio.wait_for(
                            session.execute(
                                text("""
                                    SELECT
                                        sfe.saved_food_id::TEXT AS id, sfe.name,
                                        CASE WHEN sfe.is_composite THEN 'saved' ELSE 'saved_item' END AS source,
                                        NULL::TEXT AS brand, NULL::TEXT AS category,
                                        ABS(sfe.calories)::REAL AS calories_per_100g,
                                        ABS(sfe.protein_g)::REAL AS protein_per_100g,
                                        ABS(sfe.fat_g)::REAL AS fat_per_100g,
                                        ABS(sfe.carbs_g)::REAL AS carbs_per_100g,
                                        ABS(sfe.fiber_g)::REAL AS fiber_per_100g,
                                        0.0::REAL AS sugar_per_100g,
                                        'per serving'::TEXT AS serving_description,
                                        NULL::REAL AS serving_weight_g,
                                        0.85::REAL AS similarity_score
                                    FROM saved_foods_exploded sfe
                                    WHERE sfe.user_id = CAST(:uid AS uuid)
                                      AND LOWER(sfe.name) LIKE LOWER('%' || :q || '%')
                                """),
                                {"q": query, "uid": user_id},
                            ),
                            timeout=3.0,
                        )
                        saved_foods = [dict(row._mapping) for row in result.fetchall()]
                except Exception:
                    pass  # Saved foods are optional, don't block

            # When region filter is active, skip food_database queries (no region data there)
            quality_foods = []
            db_foods = []

            if not region:
                # Step 3: Search food_database (quality-filtered by confidence_score >= 0.6)
                have_enough = len(override_results) + len(saved_foods) >= page_size
                if query and not have_enough:
                    remaining = page_size - len(override_results) - len(saved_foods)
                    quality_foods = await self._search_quality_foods(query, remaining, offset)
                    quality_foods = self._filter_search_results(query, quality_foods)

                # Step 4: Only hit unfiltered food_database if still not enough
                have_enough = len(override_results) + len(saved_foods) + len(quality_foods) >= page_size
                if query and not have_enough:
                    remaining = page_size - len(override_results) - len(saved_foods) - len(quality_foods)
                    try:
                        async with supabase.get_session() as session:
                            result = await asyncio.wait_for(
                                session.execute(
                                    text("SELECT * FROM search_food_database(:q, :lim, :off)"),
                                    {"q": query, "lim": remaining, "off": offset},
                                ),
                                timeout=5.0,
                            )
                            db_foods = [dict(row._mapping) for row in result.fetchall()]
                    except asyncio.TimeoutError:
                        logger.warning(f"[FoodDB] RPC timed out for '{query}' — trying OFF fallback")
                        db_foods = await self._search_off_text(query, page_size)
                    except Exception as rpc_err:
                        logger.warning(f"[FoodDB] RPC failed for '{query}': {rpc_err}")

                # Word-overlap filter: remove false-positive trigram matches
                db_foods = self._filter_search_results(query, db_foods)

                # If nothing found anywhere, try OFF as last resort
                if not db_foods and not quality_foods and not override_results and not saved_foods and query:
                    db_foods = await self._search_off_text(query, page_size)
                    db_foods = self._filter_search_results(query, db_foods)

            # Assemble: Saved > Overrides > Quality DB > Unfiltered DB (deduped)
            override_names = {r["name"].lower() for r in override_results}
            saved_names = {f.get("name", "").lower() for f in saved_foods}
            # Remove overrides that duplicate saved food names
            override_results = [r for r in override_results if r["name"].lower() not in saved_names]
            # Dedup quality foods against higher-priority tiers
            higher_names = override_names | saved_names
            quality_foods = [f for f in quality_foods if f.get("name", "").lower() not in higher_names]
            # Dedup unfiltered DB against all higher tiers
            all_preferred_names = higher_names | {f.get("name", "").lower() for f in quality_foods}
            db_foods = [f for f in db_foods if f.get("name", "").lower() not in all_preferred_names]

            foods = saved_foods + override_results + quality_foods + db_foods

            logger.info(f"[FoodDB] Unified search found {len(foods)} results for '{query}'")
            self._set_cached(cache_key, foods)
            return foods

        except Exception as e:
            logger.error(f"[FoodDB] Unified search failed for '{query}': {e}")
            # Fallback to regular search (will raise if that also fails)
            return await self.search_foods(
                query=query, page_size=page_size, page=page,
                restaurant=restaurant, food_category=food_category,
            )

    async def lookup_single_food(self, food_name: str) -> Optional[Dict]:
        """
        Look up a single food and return per-100g nutrition data.
        Checks overrides → quality food_database → unfiltered food_database.

        Returns dict with keys: calories_per_100g, protein_per_100g,
        carbs_per_100g, fat_per_100g, fiber_per_100g
        (+ override_weight_per_piece_g, override_serving_g if from override)
        or None if no good match found.
        """
        if not food_name or not food_name.strip():
            return None

        food_name = food_name.strip()
        cache_key = f"lookup:{food_name.lower()}"
        cached = self._get_cached(cache_key)
        if cached is not None:
            # cached could be the dict OR the sentinel False (meaning "no match")
            return cached if cached is not False else None

        # Check overrides first
        await self._load_overrides()
        override = self._check_override(food_name)
        if override:
            nutrition = self._override_to_nutrition(override)
            self._set_cached(cache_key, nutrition)
            return nutrition

        try:
            supabase = get_supabase()

            # Check quality-filtered food_database first (confidence_score >= 0.6)
            quality = await self._search_quality_foods(food_name, limit=1)
            if quality:
                v = quality[0]
                v_name = v.get("name", "")
                v_sim = float(v.get("similarity_score") or 0)
                if v_sim >= 0.3 or self._is_good_match(food_name, v_name):
                    nutrition = {
                        "calories_per_100g": float(v.get("calories_per_100g") or 0),
                        "protein_per_100g": float(v.get("protein_per_100g") or 0),
                        "carbs_per_100g": float(v.get("carbs_per_100g") or 0),
                        "fat_per_100g": float(v.get("fat_per_100g") or 0),
                        "fiber_per_100g": float(v.get("fiber_per_100g") or 0),
                    }
                    if v.get("serving_weight_g"):
                        nutrition["override_serving_g"] = float(v["serving_weight_g"])
                    self._set_cached(cache_key, nutrition)
                    return nutrition

            # Fall back to unfiltered food_database
            async with supabase.get_session() as session:
                result = await session.execute(
                    text("SELECT * FROM search_food_database(:q, 1, 0)"),
                    {"q": food_name},
                )
                foods = [dict(row._mapping) for row in result.fetchall()]

            if not foods:
                logger.info(f"[FoodDB] No results for '{food_name}'")
                self._set_cached(cache_key, False)
                return None

            top = foods[0]
            result_name = top.get("name", "")
            sim_score = float(top.get("similarity_score") or 0)

            # Trust high similarity scores (variant match via DB trigram)
            if sim_score < 0.3 and not self._is_good_match(food_name, result_name):
                self._set_cached(cache_key, False)
                return None

            nutrition = {
                "calories_per_100g": float(top.get("calories_per_100g") or 0),
                "protein_per_100g": float(top.get("protein_per_100g") or 0),
                "carbs_per_100g": float(top.get("carbs_per_100g") or 0),
                "fat_per_100g": float(top.get("fat_per_100g") or 0),
                "fiber_per_100g": float(top.get("fiber_per_100g") or 0),
            }

            logger.info(
                f"[FoodDB] Found '{result_name}' for '{food_name}' "
                f"({nutrition['calories_per_100g']} cal/100g)"
            )
            self._set_cached(cache_key, nutrition)
            return nutrition

        except Exception as e:
            logger.warning(f"[FoodDB] Lookup failed for '{food_name}': {e}")
            return None

    async def batch_lookup_foods(
        self, food_names: List[str]
    ) -> Dict[str, Optional[Dict]]:
        """
        Look up multiple foods in one RPC call.
        Checks overrides first for each name, then batch-queries the DB for the rest.

        Returns:
            Dict mapping each food name to its per-100g nutrition data
            (same format as lookup_single_food) or None if no good match.
        """
        if not food_names:
            return {}

        # Load overrides (TTL-gated)
        await self._load_overrides()

        results: Dict[str, Optional[Dict]] = {}
        uncached_names: List[str] = []

        # Check cache and overrides first for each name
        for name in food_names:
            name = name.strip()
            if not name:
                continue
            cache_key = f"lookup:{name.lower()}"
            cached = self._get_cached(cache_key)
            if cached is not None:
                results[name] = cached if cached is not False else None
            else:
                # Check override before sending to DB
                override = self._check_override(name)
                if override:
                    nutrition = self._override_to_nutrition(override)
                    results[name] = nutrition
                    self._set_cached(cache_key, nutrition)
                else:
                    uncached_names.append(name)

        if not uncached_names:
            return results

        logger.info(f"[FoodDB] Batch lookup for {len(uncached_names)} foods (after {len(results)} override/cache hits)")

        try:
            supabase = get_supabase()
            async with supabase.get_session() as session:
                rpc_result = await session.execute(
                    text("SELECT * FROM batch_lookup_foods(CAST(:names AS text[]))"),
                    {"names": uncached_names},
                )
                rows = [dict(r._mapping) for r in rpc_result.fetchall()]

            # Build a lookup from input_name -> row
            row_map: Dict[str, Dict] = {}
            for row in rows:
                input_name = row.get("input_name", "")
                if input_name:
                    row_map[input_name.strip()] = row

            # Process each uncached name
            for name in uncached_names:
                cache_key = f"lookup:{name.lower()}"
                row = row_map.get(name)

                if not row or not row.get("matched_name"):
                    # No result from DB
                    results[name] = None
                    self._set_cached(cache_key, False)
                    continue

                result_name = row.get("matched_name", "")
                sim_score = float(row.get("similarity_score") or 0)

                # Trust high similarity scores (variant match via DB trigram)
                if sim_score < 0.3 and not self._is_good_match(name, result_name):
                    results[name] = None
                    self._set_cached(cache_key, False)
                    continue

                nutrition = {
                    "calories_per_100g": float(row.get("calories_per_100g") or 0),
                    "protein_per_100g": float(row.get("protein_per_100g") or 0),
                    "carbs_per_100g": float(row.get("carbs_per_100g") or 0),
                    "fat_per_100g": float(row.get("fat_per_100g") or 0),
                    "fiber_per_100g": float(row.get("fiber_per_100g") or 0),
                }
                results[name] = nutrition
                self._set_cached(cache_key, nutrition)

                logger.info(
                    f"[FoodDB] Batch hit: '{result_name}' for '{name}' "
                    f"({nutrition['calories_per_100g']} cal/100g)"
                )

        except Exception as e:
            logger.error(f"[FoodDB] Batch lookup failed: {e}")
            # Mark all uncached as None so we don't retry immediately
            for name in uncached_names:
                if name not in results:
                    results[name] = None

        return results


# ── Singleton ──────────────────────────────────────────────────────

_food_db_lookup_service: Optional[FoodDatabaseLookupService] = None


def get_food_db_lookup_service() -> FoodDatabaseLookupService:
    """Get singleton FoodDatabaseLookupService instance."""
    global _food_db_lookup_service
    if _food_db_lookup_service is None:
        _food_db_lookup_service = FoodDatabaseLookupService()
    return _food_db_lookup_service
