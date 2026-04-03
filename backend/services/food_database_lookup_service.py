"""
Food Database Lookup Service.

Search architecture:
  1. food_nutrition_overrides — hand-curated premium (200K+ items, DB-queried)
  2. If no match → caller uses AI text analysis (Gemini)

Provides single and batch food lookups with in-memory TTL caching.
"""

import asyncio
import re
import time
from typing import Optional, Dict, List

from sqlalchemy import text

from core.logger import get_logger
from core.supabase_client import get_supabase
logger = get_logger(__name__)


class FoodDatabaseLookupService:
    """
    Service for looking up foods in Supabase with two-tier search.

    Features:
    - Food nutrition overrides (curated corrections, highest priority)
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
        """Search overrides using trigram similarity (uses GIN index) with exact-match boost."""
        try:
            sb = get_supabase()

            if not query:
                # No query — browse by restaurant/category/region
                q = sb.client.table("food_nutrition_overrides").select("*").eq("is_active", True)
                if restaurant:
                    q = q.ilike("restaurant_name", f"%{restaurant}%")
                if food_category:
                    q = q.eq("food_category", food_category)
                if region:
                    q = q.eq("region", region.upper())
                result = q.limit(limit).execute()
                return [self._override_row_to_search_result(row) for row in (result.data or [])]

            q = query.lower().strip()

            # Build optional filter clauses for raw SQL
            filters = []
            params = {
                "q": q,
                "lim": limit,
            }

            if restaurant:
                filters.append("AND restaurant_name ILIKE :restaurant")
                params["restaurant"] = f"%{restaurant}%"
            if food_category:
                filters.append("AND food_category = :food_category")
                params["food_category"] = food_category.lower()
            if region:
                filters.append("AND region = :region")
                params["region"] = region.upper()

            filter_clause = " ".join(filters)

            async with sb.get_session() as session:
                # Lower threshold for broader matching; GIN trigram index handles speed
                await session.execute(text("SET pg_trgm.similarity_threshold = 0.3"))
                result = await asyncio.wait_for(
                    session.execute(text(f"""
                        SELECT *,
                            similarity(food_name_normalized, :q) AS sim_score,
                            CASE
                                WHEN food_name_normalized = :q THEN 0
                                WHEN :q = ANY(variant_names) THEN 1
                                ELSE 2
                            END AS match_rank
                        FROM food_nutrition_overrides
                        WHERE is_active = TRUE
                        AND (
                            food_name_normalized = :q
                            OR :q = ANY(variant_names)
                            OR food_name_normalized % :q
                            OR display_name % :q
                            OR food_name_normalized ILIKE '%' || :q || '%'
                            OR :q ILIKE '%' || food_name_normalized || '%'
                        )
                        {filter_clause}
                        ORDER BY match_rank, sim_score DESC
                        LIMIT :lim
                    """), params),
                    timeout=3.0,
                )
                rows = [dict(row._mapping) for row in result.fetchall()]

            return [self._override_row_to_search_result(row) for row in rows]

        except asyncio.TimeoutError:
            logger.warning(f"[FoodDB] Override search timed out for '{query}'")
            return []
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

    # ── Cooking-method stem map (bidirectional) ────────────────────────
    _COOKING_STEMS: Dict[str, str] = {
        'mash': 'mashed', 'mashed': 'mash',
        'fry': 'fried', 'fried': 'fry',
        'grill': 'grilled', 'grilled': 'grill',
        'bake': 'baked', 'baked': 'bake',
        'roast': 'roasted', 'roasted': 'roast',
        'steam': 'steamed', 'steamed': 'steam',
        'boil': 'boiled', 'boiled': 'boil',
        'poach': 'poached', 'poached': 'poach',
        'smoke': 'smoked', 'smoked': 'smoke',
        'scramble': 'scrambled', 'scrambled': 'scramble',
        'saute': 'sauteed', 'sauteed': 'saute',
        'blanch': 'blanched', 'blanched': 'blanch',
        'braise': 'braised', 'braised': 'braise',
        'toast': 'toasted', 'toasted': 'toast',
        'chop': 'chopped', 'chopped': 'chop',
        'dice': 'diced', 'diced': 'dice',
        'slice': 'sliced', 'sliced': 'slice',
        'blend': 'blended', 'blended': 'blend',
        'puree': 'pureed', 'pureed': 'puree',
        'crush': 'crushed', 'crushed': 'crush',
        'shred': 'shredded', 'shredded': 'shred',
        'whip': 'whipped', 'whipped': 'whip',
        'pickle': 'pickled', 'pickled': 'pickle',
        'ferment': 'fermented', 'fermented': 'ferment',
        'dry': 'dried', 'dried': 'dry',
        'marinate': 'marinated', 'marinated': 'marinate',
        'stir-fry': 'stir-fried', 'stir-fried': 'stir-fry',
        'freeze': 'frozen', 'frozen': 'freeze',
    }

    @staticmethod
    def _stem_simple_static(word: str) -> str:
        """Basic plural stripping: bananas→banana, berries→berry, etc."""
        if len(word) <= 3:
            return word
        if word.endswith("ies") and len(word) > 4:
            return word[:-3] + "y"
        if word.endswith("oes") and len(word) > 4:
            return word[:-2]
        if word.endswith("ches") or word.endswith("shes") or word.endswith("xes"):
            return word[:-2]
        if word.endswith("s") and not word.endswith("ss"):
            return word[:-1]
        return word

    def _generate_fuzzy_candidates(self, query: str) -> List[str]:
        """
        Generate candidate strings by applying cooking-method stemming,
        plural stemming, and word reordering.

        Rules:
        - Reorder only for 2-word queries (avoids chocolate milk ↔ milk chocolate)
        - For 3-word: stem + original order + move-first-to-end
        - Max ~16 candidates per query
        """
        words = query.lower().strip().split()
        if not words or len(words) > 4:
            return []

        # Build variants for each word
        from itertools import product as iter_product
        word_variants = []
        for w in words:
            variants = {w}
            # Cooking stem
            if w in self._COOKING_STEMS:
                variants.add(self._COOKING_STEMS[w])
            # Plural stem
            stemmed = self._stem_simple_static(w)
            if stemmed != w:
                variants.add(stemmed)
                # Also cooking-stem the plural-stemmed form
                if stemmed in self._COOKING_STEMS:
                    variants.add(self._COOKING_STEMS[stemmed])
            word_variants.append(list(variants))

        candidates = set()
        for combo in iter_product(*word_variants):
            # Original word order
            candidates.add(' '.join(combo))
            # Reversed order — only for 2-word queries
            if len(combo) == 2:
                candidates.add(' '.join(reversed(combo)))
            # For 3-word: move first word to end
            elif len(combo) == 3:
                candidates.add(f"{combo[1]} {combo[2]} {combo[0]}")
                candidates.add(f"{combo[2]} {combo[0]} {combo[1]}")

        # Remove the original query (already tried in exact match)
        candidates.discard(query.lower().strip())
        return list(candidates)[:20]  # Safety cap

    # Cache for AI validation results to avoid repeated Gemini calls
    _ai_validation_cache: Dict[str, bool] = {}

    async def _ai_validate_match(self, query: str, matched_name: str) -> bool:
        """Quick Gemini validation: is the matched food a reasonable result for the query?

        Uses a fast, low-token Gemini call to validate fuzzy matches that have
        low similarity scores. Returns False on timeout/error (safe default).
        """
        cache_key = f"{query.lower()}|{matched_name.lower()}"
        if cache_key in self._ai_validation_cache:
            return self._ai_validation_cache[cache_key]

        try:
            from google import genai
            from google.genai import types
            client = genai.Client()

            prompt = (
                f"Is '{matched_name}' a reasonable food database match for someone "
                f"searching '{query}'? Answer ONLY 'YES' or 'NO'."
            )
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model="gemini-2.0-flash",
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        temperature=0,
                        max_output_tokens=3,
                    ),
                ),
                timeout=2.0,
            )
            answer = (response.text or "").strip().upper()
            is_valid = answer.startswith("YES")
            self._ai_validation_cache[cache_key] = is_valid
            return is_valid
        except Exception as e:
            logger.debug(f"[FoodDB] AI validation failed for '{query}' vs '{matched_name}': {e}")
            # On error, reject the match (safe default)
            self._ai_validation_cache[cache_key] = False
            return False

    async def _check_override_fuzzy_db(self, food_name: str) -> Optional[Dict]:
        """
        Extended override lookup with DB-backed fuzzy matching.

        Tries progressively fuzzier steps:
        1. Exact match on food_name_normalized (existing _check_override)
        2. Exact match in variant_names array (DB query, GIN index)
        3. Stemmed + reordered candidates vs variant_names (DB overlaps)
        4. Trigram similarity on food_name_normalized (threshold 0.4, 4+ chars)
        """
        # Step 1: Exact match (existing, fast)
        result = self._check_override(food_name)
        if result:
            return result

        normalized = food_name.lower().strip()
        if not normalized:
            return None

        try:
            sb = get_supabase()

            # Step 2: Check variant_names array for exact match
            resp = sb.client.table("food_nutrition_overrides").select("*").eq(
                "is_active", True
            ).contains("variant_names", [normalized]).limit(1).execute()

            if resp.data:
                row = resp.data[0]
                override_data = self._row_to_override_dict(row)
                # Cache for future exact lookups
                self._overrides[normalized] = override_data
                logger.info(
                    f"[FoodDB] OVERRIDE HIT (variant): '{food_name}' → "
                    f"{override_data['display_name']} ({override_data['calories_per_100g']} cal/100g)"
                )
                return override_data

            # Step 3: Stemmed + reordered candidates vs variant_names
            candidates = self._generate_fuzzy_candidates(normalized)
            if candidates:
                resp = sb.client.table("food_nutrition_overrides").select("*").eq(
                    "is_active", True
                ).overlaps("variant_names", candidates).limit(3).execute()

                if resp.data:
                    # Pick the best match: prefer the one with highest word overlap
                    best = self._pick_best_fuzzy_match(resp.data, normalized)
                    override_data = self._row_to_override_dict(best)
                    matched_candidate = next(
                        (c for c in candidates if c in [v.lower() for v in (best.get("variant_names") or [])]),
                        "fuzzy"
                    )
                    self._overrides[normalized] = override_data
                    logger.info(
                        f"[FoodDB] OVERRIDE HIT (fuzzy): '{food_name}' → "
                        f"{override_data['display_name']} via '{matched_candidate}' "
                        f"({override_data['calories_per_100g']} cal/100g)"
                    )
                    return override_data

            # Step 4: Trigram similarity on food_name_normalized (4+ chars only)
            if len(normalized) >= 4:
                try:
                    async with sb.get_session() as session:
                        result_row = await asyncio.wait_for(
                            session.execute(text("""
                                SELECT *, similarity(food_name_normalized, :q) AS sim
                                FROM food_nutrition_overrides
                                WHERE is_active = TRUE
                                AND similarity(food_name_normalized, :q) > 0.4
                                ORDER BY sim DESC
                                LIMIT 1
                            """), {"q": normalized}),
                            timeout=2.0,
                        )
                        row = result_row.fetchone()
                        if row:
                            row_dict = dict(row._mapping)
                            sim_score = float(row_dict.get('sim', 0))
                            matched_name = row_dict.get('display_name', '')

                            # Word-overlap pre-filter: reject if zero shared words (3+ chars)
                            query_words = {w for w in normalized.split() if len(w) >= 3}
                            match_words = {w for w in matched_name.lower().split() if len(w) >= 3}
                            has_word_overlap = bool(query_words & match_words)

                            if not has_word_overlap and sim_score < 0.6:
                                logger.info(
                                    f"[FoodDB] Rejected fuzzy match (no word overlap): "
                                    f"'{food_name}' ≠ '{matched_name}' (sim={sim_score:.2f})"
                                )
                            elif sim_score < 0.6:
                                # Low confidence match — AI validation
                                is_valid = await self._ai_validate_match(normalized, matched_name)
                                if not is_valid:
                                    logger.info(
                                        f"[FoodDB] AI rejected fuzzy match: "
                                        f"'{food_name}' ≠ '{matched_name}' (sim={sim_score:.2f})"
                                    )
                                else:
                                    override_data = self._row_to_override_dict(row_dict)
                                    self._overrides[normalized] = override_data
                                    logger.info(
                                        f"[FoodDB] OVERRIDE HIT (trigram {sim_score:.2f}, AI validated): "
                                        f"'{food_name}' → {matched_name}"
                                    )
                                    return override_data
                            else:
                                override_data = self._row_to_override_dict(row_dict)
                                self._overrides[normalized] = override_data
                                logger.info(
                                    f"[FoodDB] OVERRIDE HIT (trigram {sim_score:.2f}): "
                                    f"'{food_name}' → {matched_name}"
                                )
                                return override_data
                except Exception as e:
                    logger.debug(f"[FoodDB] Trigram search failed for '{food_name}': {e}")

        except Exception as e:
            logger.debug(f"[FoodDB] Fuzzy override lookup failed for '{food_name}': {e}")

        return None

    def _row_to_override_dict(self, row: Dict) -> Dict:
        """Convert a food_nutrition_overrides DB row to override data dict."""
        return {
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

    def _pick_best_fuzzy_match(self, rows: List[Dict], query: str) -> Dict:
        """Pick the best match from multiple fuzzy results based on word overlap."""
        if len(rows) == 1:
            return rows[0]

        query_words = set(query.lower().split())
        best_row = rows[0]
        best_score = 0

        for row in rows:
            name_words = set((row.get("display_name") or "").lower().split())
            variant_words = set()
            for v in (row.get("variant_names") or []):
                variant_words.update(v.lower().split())
            all_words = name_words | variant_words
            overlap = len(query_words & all_words)
            if overlap > best_score:
                best_score = overlap
                best_row = row

        return best_row

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
        still_unmatched: List[str] = []
        try:
            from core.supabase_client import get_supabase as _get_sb
            sb = _get_sb()
            for name in uncached_names:
                normalized = name.lower().strip()
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

        # No override match for remaining names — mark as None (caller uses AI)
        for name in still_unmatched:
            cache_key = f"lookup:{name.lower()}"
            results[name] = None
            self._set_cached(cache_key, False)

        override_hits = len(food_names) - len(still_unmatched)
        logger.info(f"[FoodDB] Batch: {override_hits} override hits (exact+variant), {len(still_unmatched)} misses")
        return results


# ── Singleton ──────────────────────────────────────────────────────

_food_db_lookup_service: Optional[FoodDatabaseLookupService] = None


def get_food_db_lookup_service() -> FoodDatabaseLookupService:
    """Get singleton FoodDatabaseLookupService instance."""
    global _food_db_lookup_service
    if _food_db_lookup_service is None:
        _food_db_lookup_service = FoodDatabaseLookupService()
    return _food_db_lookup_service
