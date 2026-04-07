"""Second part of food_database_lookup_service_helpers.py (auto-split for size)."""
from typing import Dict, List, Optional
import logging
import re
from core.supabase_client import get_supabase
logger = logging.getLogger(__name__)


class FoodDatabaseLookupServicePart2:
    """Second half of FoodDatabaseLookupService methods. Use as mixin."""

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

    # Weight/quantity patterns: "8oz", "200g", "1 cup", "2 slices", "1 lb"
    _WEIGHT_PATTERN = re.compile(
        r'(\d+(?:\.\d+)?)\s*'
        r'(oz|ounce|ounces|g|grams?|kg|kilograms?|lbs?|pounds?|cups?|tbsp|tsp|tablespoons?|teaspoons?|ml|liters?|litres?|pieces?|pcs?|slices?|servings?)',
        re.IGNORECASE
    )
    _WEIGHT_PREFIX_STRIP = re.compile(
        r'^\d+(?:\.\d+)?\s*'
        r'(?:oz|ounce|ounces|g|grams?|kg|kilograms?|lbs?|pounds?|cups?|tbsp|tsp|tablespoons?|teaspoons?|ml|liters?|litres?|pieces?|pcs?|slices?|servings?)\s*',
        re.IGNORECASE
    )

    # Conversion factors to grams
    _UNIT_TO_GRAMS = {
        'oz': 28.35, 'ounce': 28.35, 'ounces': 28.35,
        'g': 1.0, 'gram': 1.0, 'grams': 1.0,
        'kg': 1000.0, 'kilogram': 1000.0, 'kilograms': 1000.0,
        'lb': 453.6, 'lbs': 453.6, 'pound': 453.6, 'pounds': 453.6,
    }

    def _extract_weight_from_query(self, query: str) -> Optional[float]:
        """Extract weight in grams from query like '8oz filet mignon' → 226.8g."""
        match = self._WEIGHT_PATTERN.search(query)
        if not match:
            return None
        amount = float(match.group(1))
        unit = match.group(2).lower()
        factor = self._UNIT_TO_GRAMS.get(unit)
        if factor:
            return round(amount * factor, 1)
        return None  # Units like cups, slices not convertible to grams

    def _strip_weight_prefix(self, query: str) -> str:
        """Strip leading weight from query: '8oz filet mignon' → 'filet mignon'."""
        stripped = self._WEIGHT_PREFIX_STRIP.sub('', query).strip()
        return stripped if stripped else query

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
                extracted_weight_g = self._extract_weight_from_query(part)
                clean_part = self._strip_weight_prefix(part) if extracted_weight_g else part

                part_results = await self.search_foods(
                    query=clean_part, page_size=per_part_limit, page=1,
                    category=category, source=source,
                    restaurant=restaurant, food_category=food_category,
                    region=region,
                )
                for r in part_results:
                    name_lower = r.get("name", "").lower()
                    if name_lower not in seen_names:
                        r["matched_query"] = part
                        if extracted_weight_g:
                            r["serving_weight_g"] = extracted_weight_g
                            r["user_specified_weight"] = True
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

            foods = override_results

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
        Search with user's saved foods and overrides.
        Priority: Saved Foods > Overrides.
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
                # Extract weight/quantity from the query part (e.g., "8oz filet mignon" → 227g)
                extracted_weight_g = self._extract_weight_from_query(part)
                # Strip the weight prefix for better search matching
                clean_part = self._strip_weight_prefix(part) if extracted_weight_g else part

                part_results = await self.search_foods_unified(
                    query=clean_part, user_id=user_id,
                    page_size=per_part_limit, page=1,
                    restaurant=restaurant, food_category=food_category, region=region,
                )
                for r in part_results:
                    name_lower = r.get("name", "").lower()
                    if name_lower not in seen_names:
                        r["matched_query"] = part
                        # Override serving weight if user specified a weight (e.g., "8oz")
                        if extracted_weight_g:
                            r["serving_weight_g"] = extracted_weight_g
                            r["user_specified_weight"] = True
                        all_results.append(r)
                        seen_names.add(name_lower)

            self._set_cached(cache_key, all_results[:page_size])
            return all_results[:page_size]

        try:
            supabase = get_supabase()

            # Run overrides + saved foods in parallel
            async def _fetch_overrides():
                if page != 1:
                    return []
                return await self._search_overrides_db(
                    query, limit=page_size, restaurant=restaurant,
                    food_category=food_category, region=region,
                )

            async def _fetch_saved():
                if not query or not user_id:
                    return []
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
                                        0.85::REAL AS similarity_score,
                                        ABS(sfe.calories)::INTEGER AS total_calories
                                    FROM saved_foods_exploded sfe
                                    WHERE sfe.user_id = CAST(:uid AS uuid)
                                      AND LOWER(sfe.name) LIKE LOWER('%' || :q || '%')
                                """),
                                {"q": query, "uid": user_id},
                            ),
                            timeout=3.0,
                        )
                        return [dict(row._mapping) for row in result.fetchall()]
                except Exception:
                    return []

            override_results, saved_foods = await asyncio.gather(
                _fetch_overrides(), _fetch_saved()
            )

            # Dedup overrides against saved food names
            saved_names = {f.get("name", "").lower() for f in saved_foods}
            override_results = [r for r in override_results if r["name"].lower() not in saved_names]

            foods = saved_foods + override_results

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
        Checks overrides only. Returns None if no match found (caller uses AI).

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
            return cached if cached is not False else None

        await self._load_overrides()
        override = await self._check_override_fuzzy_db(food_name)
        if override:
            nutrition = self._override_to_nutrition(override)
            self._set_cached(cache_key, nutrition)
            return nutrition

        logger.info(f"[FoodDB] No override match for '{food_name}'")
        self._set_cached(cache_key, False)
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

        # Check cache and overrides first for each name (exact match)
        for name in food_names:
            name = name.strip()
            if not name:
                continue
            cache_key = f"lookup:{name.lower()}"
            cached = self._get_cached(cache_key)
            if cached is not None:
                results[name] = cached if cached is not False else None
            else:
                # Check override (exact match on food_name_normalized)
                override = self._check_override(name)
                if override:
                    nutrition = self._override_to_nutrition(override)
                    results[name] = nutrition
                    self._set_cached(cache_key, nutrition)
                else:
                    uncached_names.append(name)

        if not uncached_names:
            return results

        # Step 2: Check variant_names for foods that missed exact match
        # Prefer generic entries (region IS NULL) over regional variants for accuracy
        still_unmatched: List[str] = []
        try:
            from core.supabase_client import get_supabase as _get_sb
            sb = _get_sb()
            for name in uncached_names:
                normalized = name.lower().strip()
                # Try generic entries first (region IS NULL) — most accurate for common foods
                resp = sb.client.table("food_nutrition_overrides").select("*").eq(
                    "is_active", True
                ).is_("region", "null").contains("variant_names", [normalized]).limit(1).execute()

                if not resp.data:
                    # Fall back to any regional entry
                    resp = sb.client.table("food_nutrition_overrides").select("*").eq(
                        "is_active", True
                    ).contains("variant_names", [normalized]).limit(1).execute()

                if resp.data:
                    row = resp.data[0]
                    override_data = self._row_to_override_dict(row)
                    nutrition = self._override_to_nutrition(override_data)
                    results[name] = nutrition
                    self._set_cached(f"lookup:{normalized}", nutrition)
                    # Cache for future exact lookups too
                    self._overrides[normalized] = override_data
                    logger.info(
                        f"[FoodDB] OVERRIDE HIT (batch-variant): '{name}' → "
                        f"{override_data['display_name']} ({override_data['calories_per_100g']} cal/100g)"
                    )
                else:
                    still_unmatched.append(name)
        except Exception as e:
            logger.warning(f"[FoodDB] Batch variant lookup failed: {e}")
            still_unmatched = uncached_names

        # Step 3: Fuzzy matching for remaining misses
        if still_unmatched:
            final_unmatched = []
            for name in still_unmatched:
                try:
                    fuzzy_result = await self._check_override_fuzzy_db(name)
                    if fuzzy_result:
                        nutrition = self._override_to_nutrition(fuzzy_result)
                        results[name] = nutrition
                        self._set_cached(f"lookup:{name.lower()}", nutrition)
                        logger.info(
                            f"[FoodDB] OVERRIDE HIT (batch-fuzzy): '{name}' → "
                            f"{fuzzy_result['display_name']} ({fuzzy_result['calories_per_100g']} cal/100g)"
                        )
                    else:
                        final_unmatched.append(name)
                except Exception as e:
                    logger.debug(f"[FoodDB] Fuzzy lookup failed for '{name}': {e}")
                    final_unmatched.append(name)
            still_unmatched = final_unmatched

        # No override match for remaining names — mark as None (caller uses AI)
        for name in still_unmatched:
            cache_key = f"lookup:{name.lower()}"
            results[name] = None
            self._set_cached(cache_key, False)

        override_hits = len(food_names) - len(still_unmatched)
        logger.info(f"[FoodDB] Batch: {override_hits} override hits (exact+variant+fuzzy), {len(still_unmatched)} misses")
        return results
