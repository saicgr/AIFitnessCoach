"""
Food Analysis Caching Service.

Wraps Gemini food analysis with intelligent caching to dramatically
reduce response times for repeated queries.

Cache Strategy:
1. Common Foods DB - Instant lookup (bypasses AI entirely)
2. Food Analysis Cache - Cached AI responses (~100ms)
3. Gemini AI - Fresh analysis (30-90s)

Expected Performance:
- Cache hit: < 2 seconds
- Cache miss (first time): 30-60 seconds
- Common food: < 1 second
"""
import logging
from typing import Optional, Dict, Any, List

from core.db.facade import get_supabase_db
from core.db.nutrition_db import NutritionDB
from services.gemini_service import GeminiService

logger = logging.getLogger(__name__)


class FoodAnalysisCacheService:
    """
    Caching layer for food analysis to speed up repeated queries.

    Usage:
        cache_service = FoodAnalysisCacheService()
        result = await cache_service.analyze_food(
            description="lamb biryani",
            user_goals=["build_muscle"],
            nutrition_targets={"daily_calorie_target": 2500},
            rag_context="...",
        )
    """

    def __init__(
        self,
        nutrition_db: Optional[NutritionDB] = None,
        gemini_service: Optional[GeminiService] = None,
    ):
        """
        Initialize the cache service.

        Args:
            nutrition_db: Optional NutritionDB instance (uses global if not provided)
            gemini_service: Optional GeminiService instance (creates new if not provided)
        """
        self._nutrition_db = nutrition_db
        self._gemini_service = gemini_service

    @property
    def nutrition_db(self) -> NutritionDB:
        """Get NutritionDB instance, creating if needed."""
        if self._nutrition_db is None:
            db = get_supabase_db()
            self._nutrition_db = db.nutrition
        return self._nutrition_db

    @property
    def gemini_service(self) -> GeminiService:
        """Get GeminiService instance, creating if needed."""
        if self._gemini_service is None:
            self._gemini_service = GeminiService()
        return self._gemini_service

    async def analyze_food(
        self,
        description: str,
        user_goals: Optional[List[str]] = None,
        nutrition_targets: Optional[Dict] = None,
        rag_context: Optional[str] = None,
        use_cache: bool = True,
    ) -> Dict[str, Any]:
        """
        Analyze food with intelligent caching.

        Order of operations:
        1. Check common foods database (instant, bypasses AI)
        2. Check food analysis cache (cached AI response)
        3. Fall back to fresh Gemini analysis (cache result)

        Args:
            description: Food description text
            user_goals: List of user fitness goals
            nutrition_targets: Dict with calorie/macro targets
            rag_context: RAG context from nutrition knowledge base
            use_cache: Whether to use caching (default True)

        Returns:
            Dict with food_items, totals, AI suggestions, and cache_hit indicator
        """
        result = {
            "cache_hit": False,
            "cache_source": None,
        }

        # Step 1: Try common foods database (instant lookup)
        if use_cache:
            common_food = await self._try_common_food(description)
            if common_food:
                logger.info(f"🎯 Common food HIT: {description}")
                result.update(common_food)
                result["cache_hit"] = True
                result["cache_source"] = "common_foods"
                return result

        # Step 2: Try food analysis cache (cached AI response)
        if use_cache:
            cached = await self._try_cache(description)
            if cached:
                logger.info(f"🎯 Cache HIT for: {description[:50]}...")
                result.update(cached)
                result["cache_hit"] = True
                result["cache_source"] = "analysis_cache"
                return result

        # Step 3: Fresh Gemini analysis
        logger.info(f"🔄 Cache MISS - calling Gemini for: {description[:50]}...")

        analysis = await self.gemini_service.parse_food_description(
            description=description,
            user_goals=user_goals,
            nutrition_targets=nutrition_targets,
            rag_context=rag_context,
        )

        if analysis and analysis.get('food_items'):
            # Cache the successful result
            if use_cache:
                await self._cache_result(description, analysis)

            result.update(analysis)
            result["cache_hit"] = False
            result["cache_source"] = "gemini_fresh"
            return result

        # Analysis failed
        logger.warning(f"❌ Gemini analysis failed for: {description[:50]}...")
        return None

    async def _try_common_food(self, description: str) -> Optional[Dict[str, Any]]:
        """
        Try to find food in common foods database.

        Args:
            description: Food description

        Returns:
            Formatted analysis result if found, None otherwise
        """
        try:
            # Simple single-item lookup first
            common = self.nutrition_db.get_common_food(description)

            if common:
                # Convert common food to analysis format
                return self._common_food_to_analysis(common)

            return None

        except Exception as e:
            logger.warning(f"Common food lookup failed: {e}")
            return None

    def _common_food_to_analysis(self, common_food: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert common food record to standard analysis format.

        Args:
            common_food: Record from common_foods table

        Returns:
            Dict in same format as Gemini analysis
        """
        food_item = {
            "name": common_food.get("name"),
            "amount": common_food.get("serving_size", "1 serving"),
            "calories": common_food.get("calories", 0),
            "protein_g": float(common_food.get("protein_g", 0)),
            "carbs_g": float(common_food.get("carbs_g", 0)),
            "fat_g": float(common_food.get("fat_g", 0)),
            "fiber_g": float(common_food.get("fiber_g", 0)),
            "weight_g": float(common_food.get("serving_weight_g", 0)) if common_food.get("serving_weight_g") else None,
            "unit": "g",
        }

        # Get micronutrients if available
        micronutrients = common_food.get("micronutrients", {})

        return {
            "food_items": [food_item],
            "total_calories": common_food.get("calories", 0),
            "protein_g": float(common_food.get("protein_g", 0)),
            "carbs_g": float(common_food.get("carbs_g", 0)),
            "fat_g": float(common_food.get("fat_g", 0)),
            "fiber_g": float(common_food.get("fiber_g", 0)),
            # Micronutrients from JSONB field
            "sugar_g": micronutrients.get("sugar_g"),
            "sodium_mg": micronutrients.get("sodium_mg"),
            "cholesterol_mg": micronutrients.get("cholesterol_mg"),
            "vitamin_a_ug": micronutrients.get("vitamin_a_ug"),
            "vitamin_c_mg": micronutrients.get("vitamin_c_mg"),
            "vitamin_d_iu": micronutrients.get("vitamin_d_iu"),
            "calcium_mg": micronutrients.get("calcium_mg"),
            "iron_mg": micronutrients.get("iron_mg"),
            "potassium_mg": micronutrients.get("potassium_mg"),
            # Default encouragements for common foods
            "encouragements": [f"Good choice! {common_food.get('name')} is a common staple."],
            "warnings": [],
            "ai_suggestion": None,
            "recommended_swap": None,
            # Source tracking
            "data_source": common_food.get("source", "common_foods"),
            "category": common_food.get("category"),
        }

    async def _try_cache(self, description: str) -> Optional[Dict[str, Any]]:
        """
        Try to find cached analysis for food description.

        Args:
            description: Food description

        Returns:
            Cached analysis result if found, None otherwise
        """
        try:
            # Normalize and hash
            normalized = NutritionDB.normalize_food_query(description)
            query_hash = NutritionDB.hash_query(normalized)

            # Check cache
            cached = self.nutrition_db.get_cached_food_analysis(query_hash)

            return cached

        except Exception as e:
            logger.warning(f"Cache lookup failed: {e}")
            return None

    async def _cache_result(
        self,
        description: str,
        analysis: Dict[str, Any],
    ) -> bool:
        """
        Cache a successful analysis result.

        Args:
            description: Original food description
            analysis: Analysis result to cache

        Returns:
            True if cached successfully
        """
        try:
            return self.nutrition_db.cache_food_analysis(
                food_description=description,
                analysis_result=analysis,
            )
        except Exception as e:
            logger.warning(f"Failed to cache analysis: {e}")
            return False

    def get_cache_key(self, description: str) -> str:
        """
        Get the cache key (hash) for a food description.

        Useful for debugging and testing.

        Args:
            description: Food description

        Returns:
            SHA256 hash of normalized description
        """
        normalized = NutritionDB.normalize_food_query(description)
        return NutritionDB.hash_query(normalized)

    async def invalidate_cache(self, description: str) -> bool:
        """
        Invalidate (delete) a cached analysis.

        Args:
            description: Food description to invalidate

        Returns:
            True if invalidated successfully
        """
        try:
            normalized = NutritionDB.normalize_food_query(description)
            query_hash = NutritionDB.hash_query(normalized)

            self.nutrition_db.client.table("food_analysis_cache").delete().eq(
                "query_hash", query_hash
            ).execute()

            logger.info(f"🗑️ Invalidated cache for: {description[:50]}...")
            return True

        except Exception as e:
            logger.error(f"Failed to invalidate cache: {e}")
            return False


# Singleton instance
_cache_service_instance: Optional[FoodAnalysisCacheService] = None


def get_food_analysis_cache_service() -> FoodAnalysisCacheService:
    """Get or create the singleton cache service instance."""
    global _cache_service_instance
    if _cache_service_instance is None:
        _cache_service_instance = FoodAnalysisCacheService()
    return _cache_service_instance
