"""
Food Database Lookup Service.

Queries the Supabase food_database_deduped view for nutrition data
via RPC functions. Provides single and batch food lookups with
in-memory TTL caching.
"""

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
    - Full-text search with trigram similarity
    - Single and batch food lookups returning per-100g nutrition data
    - Match quality filtering (restaurant brand skip + word overlap)
    - In-memory TTL cache (1 hour, max 1000 entries)
    - Singleton pattern
    """

    def __init__(self):
        self._cache: Dict[str, tuple] = {}  # {key: (timestamp, data)}
        self._cache_ttl = 3600  # 1 hour

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
    ) -> List[Dict]:
        """
        Search the food database with pagination.

        Args:
            query: Search term (e.g. "chicken breast")
            page_size: Results per page (default 20)
            page: 1-based page number
            category: Optional category filter
            source: Optional source filter (usda, openfoodfacts, cnf, indb)

        Returns:
            List of food dicts from the database.
        """
        query = query.strip()
        if not query:
            return []

        cache_key = f"search:{query.lower()}:{page_size}:{page}:{category}:{source}"
        cached = self._get_cached(cache_key)
        if cached is not None:
            return cached

        logger.info(f"[FoodDB] Searching for '{query}' (page={page}, size={page_size})")

        try:
            supabase = get_supabase()
            offset = (page - 1) * page_size

            # Use direct SQLAlchemy to bypass PostgREST's 3s anon statement_timeout
            async with supabase.get_session() as session:
                result = await session.execute(
                    text("SELECT * FROM search_food_database(:q, :lim, :off)"),
                    {"q": query, "lim": page_size, "off": offset},
                )
                foods = [dict(row._mapping) for row in result.fetchall()]

            # Post-filter by source/category if specified
            if source:
                source_lower = source.lower()
                foods = [f for f in foods if (f.get("source") or "").lower() == source_lower]
            if category:
                category_lower = category.lower()
                foods = [f for f in foods if category_lower in (f.get("category") or "").lower()]

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
    ) -> List[Dict]:
        """
        Search food database unified with user's saved foods.
        Falls back to regular search_foods if user_id is empty.
        """
        query = query.strip()
        if not query:
            return []

        if not user_id:
            return await self.search_foods(query=query, page_size=page_size, page=page)

        cache_key = f"unified_search:{query.lower()}:{user_id}:{page_size}:{page}"
        cached = self._get_cached(cache_key)
        if cached is not None:
            return cached

        logger.info(f"[FoodDB] Unified search for '{query}' (user={user_id[:8]}..., page={page}, size={page_size})")

        try:
            supabase = get_supabase()
            offset = (page - 1) * page_size

            # Use direct SQLAlchemy to bypass PostgREST's 3s anon statement_timeout
            async with supabase.get_session() as session:
                result = await session.execute(
                    text("SELECT * FROM search_food_database_unified(:q, :uid::uuid, :lim, :off)"),
                    {"q": query, "uid": user_id, "lim": page_size, "off": offset},
                )
                foods = [dict(row._mapping) for row in result.fetchall()]

            logger.info(f"[FoodDB] Unified search found {len(foods)} results for '{query}'")
            self._set_cached(cache_key, foods)
            return foods

        except Exception as e:
            logger.error(f"[FoodDB] Unified search failed for '{query}': {e}")
            # Fallback to regular search (will raise if that also fails)
            return await self.search_foods(query=query, page_size=page_size, page=page)

    async def lookup_single_food(self, food_name: str) -> Optional[Dict]:
        """
        Look up a single food and return per-100g nutrition data.

        Returns dict with keys: calories_per_100g, protein_per_100g,
        carbs_per_100g, fat_per_100g, fiber_per_100g
        or None if no good match found.

        Same return format as gemini_service._lookup_single_usda.
        """
        if not food_name or not food_name.strip():
            return None

        food_name = food_name.strip()
        cache_key = f"lookup:{food_name.lower()}"
        cached = self._get_cached(cache_key)
        if cached is not None:
            # cached could be the dict OR the sentinel False (meaning "no match")
            return cached if cached is not False else None

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

        Args:
            food_names: List of food name strings.

        Returns:
            Dict mapping each food name to its per-100g nutrition data
            (same format as lookup_single_food) or None if no good match.
        """
        if not food_names:
            return {}

        results: Dict[str, Optional[Dict]] = {}
        uncached_names: List[str] = []

        # Check cache first for each name
        for name in food_names:
            name = name.strip()
            if not name:
                continue
            cache_key = f"lookup:{name.lower()}"
            cached = self._get_cached(cache_key)
            if cached is not None:
                results[name] = cached if cached is not False else None
            else:
                uncached_names.append(name)

        if not uncached_names:
            return results

        logger.info(f"[FoodDB] Batch lookup for {len(uncached_names)} foods")

        try:
            supabase = get_supabase()
            async with supabase.get_session() as session:
                rpc_result = await session.execute(
                    text("SELECT * FROM batch_lookup_foods(:names::text[])"),
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
