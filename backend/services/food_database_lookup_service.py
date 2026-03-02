"""
Food Database Lookup Service.

Queries the Supabase food_database_deduped view for nutrition data
via RPC functions. Provides single and batch food lookups with
in-memory TTL caching.

Includes a food_nutrition_overrides layer: curated, verified nutrition
data that takes priority over the base food_database for known-incorrect
entries (e.g. dosa, eggs).
"""

import asyncio
import re
import time
from typing import Optional, Dict, List

from sqlalchemy import text

from core.logger import get_logger
from core.supabase_client import get_supabase

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
]


class FoodDatabaseLookupService:
    """
    Service for looking up foods in the Supabase food_database_deduped view.

    Features:
    - Food nutrition overrides (curated corrections, highest priority)
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
        Refreshes every 30 minutes."""
        if self._overrides and (time.time() - self._overrides_loaded_at < self._overrides_ttl):
            return

        try:
            supabase = get_supabase()
            async with supabase.get_session() as session:
                result = await session.execute(
                    text("SELECT * FROM food_nutrition_overrides WHERE is_active = TRUE")
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
            # Keep stale data if available, otherwise empty dict
            if not self._overrides:
                self._overrides = {}

    def _check_override(self, food_name: str) -> Optional[Dict]:
        """Check if a food name has a curated override.
        Uses exact match only (no substring) to avoid false positives
        like 'chicken dosa' matching 'dosa'."""
        if not food_name or not self._overrides:
            return None

        normalized = food_name.lower().strip()
        override = self._overrides.get(normalized)
        if override:
            logger.info(
                f"[FoodDB] OVERRIDE HIT: '{food_name}' → "
                f"{override['display_name']} ({override['calories_per_100g']} cal/100g)"
            )
        return override

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

    def _override_to_search_result(self, override: Dict) -> Dict:
        """Convert an override dict to a search result dict for the food picker UI."""
        result = {
            "name": override["display_name"],
            "calories_per_100g": override["calories_per_100g"],
            "protein_per_100g": override["protein_per_100g"],
            "carbs_per_100g": override["carbs_per_100g"],
            "fat_per_100g": override["fat_per_100g"],
            "fiber_per_100g": override["fiber_per_100g"],
            "source": "verified",
            "similarity_score": 1.0,
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
    ) -> List[Dict]:
        """Find overrides matching a search query for injection into search results.
        Uses word-level inverted index for fast lookup instead of iterating all overrides.
        Optionally filters by restaurant_name and/or food_category."""
        if not self._overrides_list:
            return []

        query_lower = query.lower().strip() if query else ""
        restaurant_lower = restaurant.lower().strip() if restaurant else None
        category_lower = food_category.lower().strip() if food_category else None

        seen_display_names: set = set()
        matches: List[Dict] = []

        # If no query, browse by restaurant/category (iterate filtered subset)
        if not query_lower:
            if not restaurant_lower and not category_lower:
                return []
            for override in self._overrides_list:
                if restaurant_lower:
                    if restaurant_lower not in (override.get("restaurant_name") or "").lower():
                        continue
                if category_lower:
                    if category_lower != (override.get("food_category") or "").lower():
                        continue
                display = override["display_name"]
                if display not in seen_display_names:
                    matches.append(self._override_to_search_result(override))
                    seen_display_names.add(display)
            return matches

        # Use inverted index to find candidate overrides
        candidate_indices: set = set()

        # Check full query as a key (e.g., "coke" matches variant "coke")
        if query_lower in self._overrides_word_index:
            candidate_indices.update(self._overrides_word_index[query_lower])

        # Check each query word
        query_words = [w.strip("(),.'\"!?-") for w in query_lower.split() if len(w) >= 2]
        for w in query_words:
            if w in self._overrides_word_index:
                candidate_indices.update(self._overrides_word_index[w])

        # Score and filter candidates
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

            display = override["display_name"]
            if display in seen_display_names:
                continue

            display_lower = display.lower()

            # Check: substring match on display_name
            if query_lower in display_lower or display_lower in query_lower:
                matches.append(self._override_to_search_result(override))
                seen_display_names.add(display)
                continue

            # Check: variant_names match
            variant_names = override.get("variant_names") or []
            variant_matched = False
            for vn in variant_names:
                vn_lower = vn.lower() if isinstance(vn, str) else ""
                if query_lower in vn_lower or vn_lower in query_lower:
                    variant_matched = True
                    break
            if variant_matched:
                matches.append(self._override_to_search_result(override))
                seen_display_names.add(display)
                continue

            # Check: word overlap on display_name (50% threshold)
            significant_words = [w for w in query_words if len(w) >= 3]
            if significant_words:
                overlap = sum(1 for w in significant_words if w in display_lower)
                if overlap / len(significant_words) >= 0.5:
                    matches.append(self._override_to_search_result(override))
                    seen_display_names.add(display)

        return matches

    # ── Multi-food query splitting ─────────────────────────────────

    def _split_multi_query(self, query: str) -> List[str]:
        """Split multi-food queries into individual search terms.

        Splits on: commas, " and ", " & ", " + "
        Preserves compound foods that exist as overrides (e.g., "mac and cheese").

        Examples:
            "coke and biryani and ice cream" → ["coke", "biryani", "ice cream"]
            "mac and cheese"                → ["mac and cheese"]  (exists in overrides)
            "coke, biryani, ice cream"      → ["coke", "biryani", "ice cream"]
            "rice + chicken"                → ["rice", "chicken"]
        """
        q = query.strip()
        if not q:
            return []

        q_lower = q.lower()

        # No delimiters → single query
        if ',' not in q and ' and ' not in q_lower and ' & ' not in q and ' + ' not in q:
            return [q]

        # Split on commas first (always a clear multi-food delimiter)
        if ',' in q:
            comma_parts = [p.strip() for p in q.split(',') if p.strip()]
            # Recursively process each comma-separated part for " and " splitting
            final: List[str] = []
            for part in comma_parts:
                final.extend(self._split_multi_query(part))
            return final if len(final) > 1 else [q]

        # Handle " and " / " & " / " + "
        # Check if the full query is a known food in overrides → don't split
        if self._overrides.get(q_lower):
            return [q]

        parts = re.split(r'\s+and\s+|\s*&\s*|\s*\+\s*', q, flags=re.IGNORECASE)
        parts = [p.strip() for p in parts if p.strip()]

        return parts if len(parts) > 1 else [q]

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
    ) -> List[Dict]:
        """
        Search the food database with pagination.
        Override entries matching the query appear first with source='verified'.
        Optionally filter overrides by restaurant and/or food_category.
        """
        query = query.strip()
        if not query and not restaurant and not food_category:
            return []

        cache_key = f"search:{(query or '').lower()}:{page_size}:{page}:{category}:{source}:{restaurant}:{food_category}"
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
                )
                for r in part_results:
                    name_lower = r.get("name", "").lower()
                    if name_lower not in seen_names:
                        all_results.append(r)
                        seen_names.add(name_lower)

            self._set_cached(cache_key, all_results[:page_size])
            return all_results[:page_size]

        try:
            supabase = get_supabase()
            offset = (page - 1) * page_size

            # Step 1: Search overrides (in-memory, <1ms) — ALWAYS returned
            override_results = []
            if page == 1:
                override_results = self._find_matching_overrides_for_search(
                    query, restaurant=restaurant, food_category=food_category,
                )

            # Step 2: Only hit slow 528K trigram search if overrides aren't enough
            db_foods = []
            if query and len(override_results) < page_size:
                try:
                    async with supabase.get_session() as session:
                        result = await asyncio.wait_for(
                            session.execute(
                                text("SELECT * FROM search_food_database(:q, :lim, :off)"),
                                {"q": query, "lim": page_size, "off": offset},
                            ),
                            timeout=6.0,
                        )
                        db_foods = [dict(row._mapping) for row in result.fetchall()]
                except asyncio.TimeoutError:
                    logger.warning(f"[FoodDB] RPC timed out for '{query}' — returning overrides only")
                except Exception as rpc_err:
                    logger.warning(f"[FoodDB] RPC failed for '{query}': {rpc_err}")

            # Post-filter by source/category if specified
            if source:
                source_lower = source.lower()
                db_foods = [f for f in db_foods if (f.get("source") or "").lower() == source_lower]
            if category:
                category_lower = category.lower()
                db_foods = [f for f in db_foods if category_lower in (f.get("category") or "").lower()]

            # Assemble: Overrides first, then DB (deduped)
            override_names = {r["name"].lower() for r in override_results}
            db_foods = [f for f in db_foods if f.get("name", "").lower() not in override_names]
            foods = override_results + db_foods

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
    ) -> List[Dict]:
        """
        Search food database unified with user's saved foods.
        Priority: Saved Foods > Overrides > Curated DB.
        Falls back to regular search_foods if user_id is empty.
        """
        query = query.strip()
        if not query and not restaurant and not food_category:
            return []

        if not user_id:
            return await self.search_foods(
                query=query, page_size=page_size, page=page,
                restaurant=restaurant, food_category=food_category,
            )

        cache_key = f"unified_search:{(query or '').lower()}:{user_id}:{page_size}:{page}:{restaurant}:{food_category}"
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
                    restaurant=restaurant, food_category=food_category,
                )
                for r in part_results:
                    name_lower = r.get("name", "").lower()
                    if name_lower not in seen_names:
                        all_results.append(r)
                        seen_names.add(name_lower)

            self._set_cached(cache_key, all_results[:page_size])
            return all_results[:page_size]

        try:
            supabase = get_supabase()
            offset = (page - 1) * page_size

            # Step 1: Search overrides (in-memory, <1ms) — ALWAYS returned
            override_results = []
            if page == 1:
                override_results = self._find_matching_overrides_for_search(
                    query, restaurant=restaurant, food_category=food_category,
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

            # Step 3: Only hit the slow 528K-row trigram RPC if we don't have
            # enough results from overrides + saved foods combined
            db_foods = []
            have_enough = len(override_results) + len(saved_foods) >= page_size
            if query and not have_enough:
                try:
                    async with supabase.get_session() as session:
                        result = await asyncio.wait_for(
                            session.execute(
                                text("SELECT * FROM search_food_database(:q, :lim, :off)"),
                                {"q": query, "lim": page_size, "off": offset},
                            ),
                            timeout=6.0,
                        )
                        db_foods = [dict(row._mapping) for row in result.fetchall()]
                except asyncio.TimeoutError:
                    logger.warning(f"[FoodDB] RPC timed out for '{query}' — returning overrides only")
                except Exception as rpc_err:
                    logger.warning(f"[FoodDB] RPC failed for '{query}': {rpc_err}")

            # Assemble: Saved > Overrides > Curated DB (deduped)
            override_names = {r["name"].lower() for r in override_results}
            saved_names = {f.get("name", "").lower() for f in saved_foods}
            # Remove overrides that duplicate saved food names
            override_results = [r for r in override_results if r["name"].lower() not in saved_names]
            # Remove DB entries that duplicate override or saved names
            all_preferred_names = override_names | saved_names
            db_foods = [f for f in db_foods if f.get("name", "").lower() not in all_preferred_names]

            foods = saved_foods + override_results + db_foods

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
        Checks overrides first, then falls back to food_database.

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
