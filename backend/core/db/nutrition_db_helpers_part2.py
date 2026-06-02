"""Second part of nutrition_db_helpers.py (auto-split for size)."""
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import hashlib
import logging
import re
logger = logging.getLogger(__name__)

# Max age for a cached food-analysis row. The read helper bumps
# last_accessed_at on every hit, so without this a hot stale row would serve
# forever. After this window the row is treated as a miss and re-computed
# (picking up any model/prompt improvements). See migration 2091.
_FOOD_ANALYSIS_CACHE_TTL = timedelta(days=30)


class NutritionDBPart2:
    """Second half of NutritionDB methods. Use as mixin."""

    def get_nutrition_streak(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get nutrition streak for a user.

        Args:
            user_id: User's UUID

        Returns:
            Streak record or None
        """
        result = (
            self.client.table("nutrition_streaks")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def upsert_nutrition_streak(
        self, user_id: str, streak_data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Create or update nutrition streak.

        Args:
            user_id: User's UUID
            streak_data: Streak data to update

        Returns:
            Created/updated streak record
        """
        data = {"user_id": user_id, **streak_data}
        result = (
            self.client.table("nutrition_streaks")
            .upsert(data, on_conflict="user_id")
            .execute()
        )
        return result.data[0] if result.data else None

    # ==================== ADAPTIVE NUTRITION ====================

    def get_latest_adaptive_calculation(
        self, user_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get the most recent adaptive TDEE calculation for a user.

        Args:
            user_id: User's UUID

        Returns:
            Latest calculation record or None
        """
        result = (
            self.client.table("adaptive_nutrition_calculations")
            .select("*")
            .eq("user_id", user_id)
            .order("calculated_at", desc=True)
            .limit(1)
            .execute()
        )
        return result.data[0] if result.data else None

    def create_adaptive_calculation(
        self, user_id: str, calculation_data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Create a new adaptive TDEE calculation record.

        Args:
            user_id: User's UUID
            calculation_data: Calculation results

        Returns:
            Created calculation record
        """
        data = {"user_id": user_id, **calculation_data}
        result = (
            self.client.table("adaptive_nutrition_calculations")
            .insert(data)
            .execute()
        )
        return result.data[0] if result.data else None

    # ==================== WEEKLY RECOMMENDATIONS ====================

    def get_weekly_recommendation(
        self, recommendation_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get a weekly nutrition recommendation by ID.

        Args:
            recommendation_id: Recommendation UUID

        Returns:
            Recommendation record or None
        """
        result = (
            self.client.table("weekly_nutrition_recommendations")
            .select("*")
            .eq("id", recommendation_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def get_pending_recommendations(
        self, user_id: str
    ) -> List[Dict[str, Any]]:
        """
        Get pending (not yet responded to) recommendations for a user.

        Args:
            user_id: User's UUID

        Returns:
            List of pending recommendations
        """
        result = (
            self.client.table("weekly_nutrition_recommendations")
            .select("*")
            .eq("user_id", user_id)
            .is_("user_accepted", "null")
            .order("created_at", desc=True)
            .execute()
        )
        return result.data or []

    def create_weekly_recommendation(
        self, user_id: str, recommendation_data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Create a new weekly nutrition recommendation.

        Args:
            user_id: User's UUID
            recommendation_data: Recommendation details

        Returns:
            Created recommendation record
        """
        data = {"user_id": user_id, **recommendation_data}
        result = (
            self.client.table("weekly_nutrition_recommendations")
            .insert(data)
            .execute()
        )
        return result.data[0] if result.data else None

    def update_recommendation_response(
        self, recommendation_id: str, accepted: bool
    ) -> Optional[Dict[str, Any]]:
        """
        Update user response to a recommendation.

        Args:
            recommendation_id: Recommendation UUID
            accepted: Whether the user accepted the recommendation

        Returns:
            Updated recommendation record
        """
        result = (
            self.client.table("weekly_nutrition_recommendations")
            .update({"user_accepted": accepted})
            .eq("id", recommendation_id)
            .execute()
        )
        return result.data[0] if result.data else None

    # ==================== FOOD ANALYSIS CACHING ====================

    @staticmethod
    def normalize_food_query(text: str) -> str:
        """
        Normalize a food description for consistent cache keys.

        Performs:
        - Lowercase conversion
        - Trim whitespace
        - Collapse multiple spaces to single space
        - Remove special characters (keep alphanumeric and spaces)

        Args:
            text: Raw food description

        Returns:
            Normalized text for hashing
        """
        # Lowercase and trim
        normalized = text.lower().strip()
        # Collapse multiple spaces
        normalized = re.sub(r'\s+', ' ', normalized)
        # Remove special characters but keep alphanumeric and spaces
        normalized = re.sub(r'[^a-z0-9\s]', '', normalized)
        return normalized

    @staticmethod
    def normalize_for_cache_key(text: str) -> str:
        """F2 — deterministic GLOBAL-cache key normalization.

        Goal: "2 eggs" == "two eggs" == "2x eggs" (same key), BUT
        "2 eggs" != "2 eggs fried" != "2 eggs from McDonald's" (different keys).

        So we KEEP everything that changes the food (quantity, brand, restaurant,
        cooking method, qualifier tokens) and only strip noise:
          - leading filler phrases ("i had", "for breakfast", logging verbs)
          - word-numbers → digits ("two"→"2") — ENGLISH ONLY
          - "2x"/"2 x" multiplier → "2"
          - locale decimal comma ("7,5"→"7.5")
          - emoji + most punctuation, trailing notes after '#'
          - case + whitespace

        For input that is clearly NOT English (no ASCII letters / has non-Latin
        script), we normalize CONSERVATIVELY (case + whitespace only) so we don't
        mangle e.g. "dos huevos" / "deux oeufs" by word-number mapping.

        Used ONLY for the AI-analysis cache hash. It is NOT used for override
        matching (that still uses `normalize_food_query`), so the global cache
        stores the pre-override AI baseline.
        """
        from services.food_analysis.constants import _WORD_NUMBERS, _FILLER_REGEX

        if not text:
            return ""
        s = text.strip()

        # Drop a trailing free-text note after '#'.
        if "#" in s:
            s = s.split("#", 1)[0].strip()

        # Strip emoji / pictographs (keep ASCII + common latin letters/digits).
        s = re.sub(
            r"[\U0001F000-\U0001FAFF\U00002600-\U000027BF\U0001F1E6-\U0001F1FF←-⇿⌀-⏿]",
            " ",
            s,
        )

        # Locale decimal comma between digits → dot (7,5 → 7.5).
        s = re.sub(r"(?<=\d),(?=\d)", ".", s)

        lower = s.lower()

        # Detect "clearly non-English": contains a non-Latin script char, OR
        # has no ASCII a-z letters at all. In that case, conservative only.
        has_non_latin = bool(re.search(r"[^\x00-\x7f]", lower))
        has_ascii_alpha = bool(re.search(r"[a-z]", lower))
        conservative = has_non_latin or not has_ascii_alpha

        if conservative:
            out = re.sub(r"\s+", " ", lower).strip()
            return out

        # Strip leading filler phrases (iteratively — "today i had some ...").
        prev = None
        cur = lower.strip()
        guard = 0
        while prev != cur and guard < 6:
            prev = cur
            cur = _FILLER_REGEX.sub("", cur, count=1).strip()
            guard += 1
        lower = cur or lower

        # "2x" / "2 x eggs" multiplier → "2 eggs".
        lower = re.sub(r"\b(\d+(?:\.\d+)?)\s*x\b", r"\1", lower)

        # Tokenize, mapping word-numbers → digits.
        tokens = re.split(r"\s+", lower)
        mapped = []
        for tok in tokens:
            t = tok.strip(".,:;!?()[]\"'")
            if not t:
                continue
            if t in _WORD_NUMBERS:
                num = _WORD_NUMBERS[t]
                mapped.append(str(int(num)) if float(num).is_integer() else str(num))
            else:
                mapped.append(t)
        joined = " ".join(mapped)

        # Strip remaining punctuation except '.' (decimals) and keep alnum/space.
        joined = re.sub(r"[^a-z0-9.\s]", " ", joined)
        joined = re.sub(r"\s+", " ", joined).strip()
        return joined

    @staticmethod
    def hash_query(text: str) -> str:
        """
        Create SHA256 hash of normalized text for cache key.

        Args:
            text: Normalized food description

        Returns:
            SHA256 hex digest
        """
        return hashlib.sha256(text.encode('utf-8')).hexdigest()

    def get_cached_food_analysis(
        self, query_hash: str
    ) -> Optional[Dict[str, Any]]:
        """
        Check cache for existing food analysis.

        Also updates hit_count and last_accessed_at on cache hit.

        Args:
            query_hash: SHA256 hash of normalized food description

        Returns:
            Cached analysis result (JSONB) or None if not found
        """
        try:
            result = (
                self.client.table("food_analysis_cache")
                .select("id, analysis_result, hit_count, created_at")
                .eq("query_hash", query_hash)
                .maybe_single()
                .execute()
            )

            if result and result.data:
                cache_entry = result.data

                # TTL check: reject (and let the caller re-compute) any row
                # older than _FOOD_ANALYSIS_CACHE_TTL. Without this, a row
                # whose last_accessed_at keeps getting bumped on every hit
                # would never expire and stale nutrition numbers would serve
                # forever. created_at is guaranteed by migration 2091.
                created_at_raw = cache_entry.get("created_at")
                if created_at_raw:
                    try:
                        created_at = datetime.fromisoformat(
                            str(created_at_raw).replace("Z", "+00:00")
                        )
                        # Compare in the same awareness as the stored value.
                        now = (
                            datetime.now(created_at.tzinfo)
                            if created_at.tzinfo is not None
                            else datetime.utcnow()
                        )
                        if now - created_at > _FOOD_ANALYSIS_CACHE_TTL:
                            logger.info(
                                f"Food analysis cache STALE (>{_FOOD_ANALYSIS_CACHE_TTL.days}d) "
                                f"for hash {query_hash[:8]}... — re-computing"
                            )
                            return None
                    except (ValueError, TypeError) as e:
                        # Malformed created_at — treat as a miss so we
                        # re-compute and overwrite with a fresh, valid row.
                        logger.warning(
                            f"Malformed created_at in food_analysis_cache "
                            f"(hash {query_hash[:8]}...): {e} — re-computing"
                        )
                        return None

                # Update hit stats (fire and forget)
                try:
                    self.client.table("food_analysis_cache").update({
                        "hit_count": cache_entry.get("hit_count", 0) + 1,
                        "last_accessed_at": datetime.utcnow().isoformat()
                    }).eq("id", cache_entry["id"]).execute()
                except Exception as e:
                    logger.warning(f"Failed to update cache hit stats: {e}", exc_info=True)

                logger.info(f"🎯 Cache HIT for food query (hash: {query_hash[:8]}...)")
                return cache_entry.get("analysis_result")

            return None

        except Exception as e:
            logger.error(f"Error checking food analysis cache: {e}", exc_info=True)
            return None

    def cache_food_analysis(
        self,
        food_description: str,
        analysis_result: Dict[str, Any],
        model_version: Optional[str] = None,
        prompt_version: str = "v1"
    ) -> bool:
        """
        Cache a food analysis result.

        Args:
            food_description: Original food description
            analysis_result: Full Gemini response as dict
            model_version: AI model version used
            prompt_version: Prompt template version

        Returns:
            True if cached successfully
        """
        try:
            if model_version is None:
                # Food-analysis path runs on the vision/Flash-Lite model.
                from core.config import get_settings
                model_version = get_settings().gemini_vision_model

            normalized = self.normalize_food_query(food_description)
            query_hash = self.hash_query(normalized)

            self.client.table("food_analysis_cache").upsert({
                "query_hash": query_hash,
                "food_description": food_description,
                "analysis_result": analysis_result,
                "model_version": model_version,
                "prompt_version": prompt_version,
                "last_accessed_at": datetime.utcnow().isoformat(),
            }, on_conflict="query_hash").execute()

            logger.info(f"✅ Cached food analysis for: {food_description[:50]}...")
            return True

        except Exception as e:
            logger.error(f"Error caching food analysis: {e}", exc_info=True)
            return False

    # ==================== COMMON FOODS DATABASE ====================

    def get_common_food(
        self, name: str, confidence_threshold: float = 0.8
    ) -> Optional[Dict[str, Any]]:
        """
        Search common foods database for a match.

        Searches by:
        1. Exact name match (case-insensitive)
        2. Alias array contains match

        Args:
            name: Food name to search
            confidence_threshold: Not used currently, for future fuzzy matching

        Returns:
            Common food record or None
        """
        try:
            normalized_name = name.lower().strip()

            # First try exact name match
            result = (
                self.client.table("common_foods")
                .select("*")
                .eq("is_active", True)
                .ilike("name", normalized_name)
                .maybe_single()
                .execute()
            )

            if result and result.data:
                logger.info(f"🎯 Common food EXACT match: {name}")
                return result.data

            # Try alias match using contains
            result = (
                self.client.table("common_foods")
                .select("*")
                .eq("is_active", True)
                .contains("aliases", [normalized_name])
                .maybe_single()
                .execute()
            )

            if result and result.data:
                logger.info(f"🎯 Common food ALIAS match: {name} -> {result.data.get('name')}")
                return result.data

            return None

        except Exception as e:
            logger.error(f"Error searching common foods: {e}", exc_info=True)
            return None

    def list_common_foods(
        self, category: Optional[str] = None, limit: int = 100
    ) -> List[Dict[str, Any]]:
        """
        List common foods, optionally filtered by category.

        Args:
            category: Filter by category (e.g., 'indian', 'protein', 'fruit')
            limit: Maximum results

        Returns:
            List of common food records
        """
        try:
            query = (
                self.client.table("common_foods")
                .select("*")
                .eq("is_active", True)
            )

            if category:
                query = query.eq("category", category)

            result = query.order("name").limit(limit).execute()
            return result.data or []

        except Exception as e:
            logger.error(f"Error listing common foods: {e}", exc_info=True)
            return []

    def upsert_learned_food(
        self,
        name: str,
        serving_size: str,
        serving_weight_g: float,
        calories: int,
        protein_g: float,
        carbs_g: float,
        fat_g: float,
        fiber_g: float = 0,
        micronutrients: Optional[Dict[str, Any]] = None,
        category: str = "general",
        source: str = "ai_learned",
        aliases: Optional[List[str]] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Insert or update a learned food in the common_foods table.

        If a food with the same name exists, it will only update if the new
        data has more non-null micronutrient fields. New aliases are appended
        without duplicating existing ones.

        Args:
            name: Food name
            serving_size: Human-readable serving size (e.g., "1 cup")
            serving_weight_g: Weight of one serving in grams
            calories: Calories per serving
            protein_g: Protein grams per serving
            carbs_g: Carbohydrate grams per serving
            fat_g: Fat grams per serving
            fiber_g: Fiber grams per serving
            micronutrients: JSONB dict of micronutrient values
            category: Food category
            source: Data source (default 'ai_learned')
            aliases: List of alternative names

        Returns:
            Upserted common food record or None on error
        """
        try:
            normalized_name = name.lower().strip()
            new_aliases = [a.lower().strip() for a in (aliases or [])]
            new_micros = micronutrients or {}

            # Check for existing entry by name
            existing = (
                self.client.table("common_foods")
                .select("*")
                .ilike("name", normalized_name)
                .maybe_single()
                .execute()
            )

            if existing and existing.data:
                # Update only if new data has more micronutrient fields
                existing_micros = existing.data.get("micronutrients") or {}
                existing_non_null = sum(
                    1 for v in existing_micros.values() if v is not None
                )
                new_non_null = sum(
                    1 for v in new_micros.values() if v is not None
                )

                if new_non_null <= existing_non_null:
                    logger.info(
                        f"Skipping update for '{name}': existing has "
                        f"{existing_non_null} micros vs new {new_non_null}"
                    )
                    return existing.data

                # Merge aliases without duplicates
                existing_aliases = existing.data.get("aliases") or []
                merged_aliases = list(
                    dict.fromkeys(existing_aliases + new_aliases)
                )

                update_data = {
                    "serving_size": serving_size,
                    "serving_weight_g": serving_weight_g,
                    "calories": calories,
                    "protein_g": protein_g,
                    "carbs_g": carbs_g,
                    "fat_g": fat_g,
                    "fiber_g": fiber_g,
                    "micronutrients": new_micros,
                    "category": category,
                    "source": source,
                    "aliases": merged_aliases,
                    "updated_at": datetime.utcnow().isoformat(),
                }

                result = (
                    self.client.table("common_foods")
                    .update(update_data)
                    .eq("id", existing.data["id"])
                    .execute()
                )
                logger.info(f"✅ Updated learned food: {name}")
                return result.data[0] if result.data else None

            # Insert new entry
            insert_data = {
                "name": normalized_name,
                "serving_size": serving_size,
                "serving_weight_g": serving_weight_g,
                "calories": calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "micronutrients": new_micros,
                "category": category,
                "source": source,
                "aliases": new_aliases,
                "is_active": True,
            }

            result = (
                self.client.table("common_foods")
                .insert(insert_data)
                .execute()
            )
            logger.info(f"✅ Inserted new learned food: {name}")
            return result.data[0] if result.data else None

        except Exception as e:
            logger.error(f"Error upserting learned food '{name}': {e}", exc_info=True)
            return None

    # ==================== RAG CONTEXT CACHING ====================

    def get_cached_rag_context(
        self, goal_hash: str
    ) -> Optional[Dict[str, Any]]:
        """
        Check cache for RAG context by goal hash.

        Args:
            goal_hash: SHA256 hash of user goals/preferences

        Returns:
            Cached RAG context or None if not found/expired
        """
        try:
            result = (
                self.client.table("rag_context_cache")
                .select("id, context_result, hit_count, expires_at")
                .eq("goal_hash", goal_hash)
                .maybe_single()
                .execute()
            )

            if result and result.data:
                cache_entry = result.data

                # Check if expired
                expires_at = cache_entry.get("expires_at")
                if expires_at:
                    expiry_time = datetime.fromisoformat(
                        expires_at.replace('Z', '+00:00')
                    )
                    if datetime.now(expiry_time.tzinfo) > expiry_time:
                        logger.info(f"RAG cache expired for hash: {goal_hash[:8]}...")
                        return None

                # Update hit stats
                try:
                    self.client.table("rag_context_cache").update({
                        "hit_count": cache_entry.get("hit_count", 0) + 1,
                        "last_accessed_at": datetime.utcnow().isoformat()
                    }).eq("id", cache_entry["id"]).execute()
                except Exception as e:
                    logger.warning(f"Failed to update RAG cache hit stats: {e}", exc_info=True)

                logger.info(f"🎯 RAG cache HIT for goal hash: {goal_hash[:8]}...")
                return cache_entry.get("context_result")

            return None

        except Exception as e:
            logger.error(f"Error checking RAG context cache: {e}", exc_info=True)
            return None

    def cache_rag_context(
        self,
        goal_hash: str,
        context_result: Dict[str, Any],
        ttl_hours: int = 1
    ) -> bool:
        """
        Cache RAG context for a user goal hash.

        Args:
            goal_hash: SHA256 hash of user goals/preferences
            context_result: RAG context documents/embeddings info
            ttl_hours: Time-to-live in hours (default 1 hour)

        Returns:
            True if cached successfully
        """
        try:
            expires_at = datetime.utcnow() + timedelta(hours=ttl_hours)

            self.client.table("rag_context_cache").upsert({
                "goal_hash": goal_hash,
                "context_result": context_result,
                "expires_at": expires_at.isoformat(),
                "last_accessed_at": datetime.utcnow().isoformat(),
            }, on_conflict="goal_hash").execute()

            logger.info(f"✅ Cached RAG context for goal hash: {goal_hash[:8]}...")
            return True

        except Exception as e:
            logger.error(f"Error caching RAG context: {e}", exc_info=True)
            return False

    @staticmethod
    def create_goal_hash(user_goals: Dict[str, Any]) -> str:
        """
        Create a hash from user nutrition goals for RAG caching.

        Args:
            user_goals: Dict with keys like 'goal', 'target_calories', etc.

        Returns:
            SHA256 hash of sorted goal string
        """
        # Sort keys for consistent hashing
        sorted_goals = sorted(user_goals.items())
        goal_str = str(sorted_goals)
        return hashlib.sha256(goal_str.encode('utf-8')).hexdigest()
