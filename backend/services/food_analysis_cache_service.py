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
import asyncio
import logging
import re
from typing import Optional, Dict, Any, List, Tuple

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

        # Step 1b: Try multi-item common food lookup
        if use_cache:
            multi_result = await self._try_multi_item_common_food(description)
            if multi_result:
                logger.info(f"🎯 Multi-item common food HIT: {description}")
                result.update(multi_result)
                result["cache_hit"] = True
                result["cache_source"] = "multi_common_foods"
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

            # Auto-learn food items for future common food lookups
            asyncio.create_task(self._auto_learn_food_items(analysis))

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

    async def _auto_learn_food_items(self, analysis_result: Dict[str, Any]) -> None:
        """
        Auto-learn individual food items from a Gemini analysis result
        into the common_foods table for faster future lookups.

        Args:
            analysis_result: Successful Gemini food analysis result
        """
        food_items = analysis_result.get("food_items", [])
        if not food_items:
            return

        for item in food_items:
            try:
                name = item.get("name")
                if not name:
                    continue

                # Build micronutrients dict from item or top-level result
                micro_keys = [
                    "sugar_g", "sodium_mg", "cholesterol_mg",
                    "vitamin_a_ug", "vitamin_c_mg", "vitamin_d_iu",
                    "calcium_mg", "iron_mg", "potassium_mg",
                ]
                micronutrients = {}
                for key in micro_keys:
                    val = item.get(key) or analysis_result.get(key)
                    if val is not None:
                        micronutrients[key] = val

                # Infer category from food name
                category = self._infer_food_category(name)

                self.nutrition_db.upsert_learned_food(
                    name=name,
                    serving_size=item.get("amount", "1 serving"),
                    serving_weight_g=float(item.get("weight_g") or 0),
                    calories=int(item.get("calories") or 0),
                    protein_g=float(item.get("protein_g") or 0),
                    carbs_g=float(item.get("carbs_g") or 0),
                    fat_g=float(item.get("fat_g") or 0),
                    fiber_g=float(item.get("fiber_g") or 0),
                    micronutrients=micronutrients,
                    category=category,
                    source="ai_learned",
                )
                logger.info(f"✅ Auto-learned food: {name}")
            except Exception as e:
                logger.error(f"❌ Failed to auto-learn food '{item.get('name')}': {e}")

    @staticmethod
    def _infer_food_category(name: str) -> str:
        """Infer a food category from the food name using keyword heuristics."""
        lower = name.lower()
        protein_keywords = ["chicken", "beef", "fish", "salmon", "tuna", "egg",
                            "shrimp", "pork", "lamb", "turkey", "tofu", "paneer"]
        grain_keywords = ["rice", "bread", "pasta", "noodle", "roti", "naan",
                          "oat", "cereal", "wheat", "chapati"]
        fruit_keywords = ["apple", "banana", "mango", "orange", "grape",
                          "berry", "melon", "pear", "peach", "plum"]
        veg_keywords = ["broccoli", "spinach", "carrot", "tomato", "onion",
                        "potato", "lettuce", "cucumber", "pepper", "cabbage"]
        dairy_keywords = ["milk", "cheese", "yogurt", "curd", "butter", "cream"]

        for kw in protein_keywords:
            if kw in lower:
                return "protein"
        for kw in grain_keywords:
            if kw in lower:
                return "grains"
        for kw in fruit_keywords:
            if kw in lower:
                return "fruit"
        for kw in veg_keywords:
            if kw in lower:
                return "vegetable"
        for kw in dairy_keywords:
            if kw in lower:
                return "dairy"
        return "general"

    def _split_food_description(
        self, description: str
    ) -> List[Tuple[float, str]]:
        """
        Split a multi-item food description into individual items with quantities.

        Splits on: comma, ' and ', ' & ', ' + ', ' with '
        Extracts quantity prefix: "2 eggs" -> (2.0, "eggs")

        Args:
            description: Food description potentially containing multiple items

        Returns:
            List of (quantity, food_name) tuples
        """
        # Split on delimiters
        parts = re.split(r'\s*,\s*|\s+and\s+|\s+&\s+|\s+\+\s+|\s+with\s+', description.strip())
        items: List[Tuple[float, str]] = []

        for part in parts:
            part = part.strip()
            if not part:
                continue
            # Try to extract leading quantity (e.g., "2 eggs", "1.5 cups rice")
            qty_match = re.match(r'^(\d+(?:\.\d+)?)\s+(.+)$', part)
            if qty_match:
                qty = float(qty_match.group(1))
                food_name = qty_match.group(2).strip()
            else:
                qty = 1.0
                food_name = part
            items.append((qty, food_name))

        return items

    async def _try_multi_item_common_food(
        self, description: str
    ) -> Optional[Dict[str, Any]]:
        """
        Try to resolve a multi-item food description from the common foods DB.

        Only activates when multiple items are detected. If ALL items are found
        in common_foods, combines and returns the result. Otherwise returns None
        to let Gemini handle it.

        Args:
            description: Food description

        Returns:
            Combined analysis dict if all items found, None otherwise
        """
        try:
            items = self._split_food_description(description)
            if len(items) <= 1:
                return None

            all_food_items = []
            total_cals = 0
            total_protein = 0.0
            total_carbs = 0.0
            total_fat = 0.0
            total_fiber = 0.0

            for qty, food_name in items:
                common = self.nutrition_db.get_common_food(food_name)
                if not common:
                    # Any miss means we fall through to Gemini
                    return None

                analysis = self._common_food_to_analysis(common)
                # Scale by quantity
                for fi in analysis["food_items"]:
                    fi["calories"] = int(fi["calories"] * qty)
                    fi["protein_g"] = round(fi["protein_g"] * qty, 1)
                    fi["carbs_g"] = round(fi["carbs_g"] * qty, 1)
                    fi["fat_g"] = round(fi["fat_g"] * qty, 1)
                    fi["fiber_g"] = round(fi["fiber_g"] * qty, 1)
                    if fi.get("weight_g"):
                        fi["weight_g"] = round(fi["weight_g"] * qty, 1)
                    if qty != 1.0:
                        fi["amount"] = f"{qty} x {fi['amount']}"
                    all_food_items.append(fi)

                total_cals += int(analysis["total_calories"] * qty)
                total_protein += analysis["protein_g"] * qty
                total_carbs += analysis["carbs_g"] * qty
                total_fat += analysis["fat_g"] * qty
                total_fiber += analysis["fiber_g"] * qty

            return {
                "food_items": all_food_items,
                "total_calories": total_cals,
                "protein_g": round(total_protein, 1),
                "carbs_g": round(total_carbs, 1),
                "fat_g": round(total_fat, 1),
                "fiber_g": round(total_fiber, 1),
                "encouragements": ["All items found in our database for instant results!"],
                "warnings": [],
                "ai_suggestion": None,
                "recommended_swap": None,
                "data_source": "multi_common_foods",
            }

        except Exception as e:
            logger.warning(f"Multi-item common food lookup failed: {e}")
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
