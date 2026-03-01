"""
Food Analysis Caching Service.

Wraps Gemini food analysis with intelligent caching to dramatically
reduce response times for repeated queries.

Cache Strategy:
0a. Saved Foods - User's personal saved meals (instant, user-scoped)
0b. Food Nutrition Overrides - 3,785 curated items (instant)
1. Common Foods DB - Instant lookup (bypasses AI entirely)
2. Food Analysis Cache - Cached AI responses (~100ms)
3. Gemini AI - Fresh analysis (30-90s)

Expected Performance:
- Saved food / override hit: < 10ms
- Common food: < 1 second
- Cache hit: < 2 seconds
- Cache miss (first time): 30-60 seconds
"""
import asyncio
import logging
import re
from typing import Optional, Dict, Any, List, Tuple

from sqlalchemy import text

from core.db.facade import get_supabase_db
from core.db.nutrition_db import NutritionDB
from core.supabase_client import get_supabase
from services.food_database_lookup_service import get_food_db_lookup_service
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
        user_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Analyze food with intelligent caching.

        Order of operations:
        0a. Check user's saved foods (instant, user-scoped)
        0b. Check food nutrition overrides - 3,785 curated items (instant)
        1. Check common foods database (instant, bypasses AI)
        1b. Try multi-item lookup (overrides + common foods)
        2. Check food analysis cache (cached AI response)
        3. Fall back to fresh Gemini analysis (cache result)

        Args:
            description: Food description text
            user_goals: List of user fitness goals
            nutrition_targets: Dict with calorie/macro targets
            rag_context: RAG context from nutrition knowledge base
            use_cache: Whether to use caching (default True)
            user_id: Optional user ID for saved foods lookup

        Returns:
            Dict with food_items, totals, AI suggestions, and cache_hit indicator
        """
        result = {
            "cache_hit": False,
            "cache_source": None,
        }

        # Step 0a: Try user's saved foods (instant, user-scoped)
        if use_cache and user_id:
            saved = await self._try_saved_food(description, user_id)
            if saved:
                logger.info(f"🎯 Saved food HIT: {description}")
                result.update(saved)
                result["cache_hit"] = True
                result["cache_source"] = "saved_food"
                return result

        # Step 0b: Try food nutrition overrides (3,785 curated items)
        if use_cache:
            override = await self._try_override(description)
            if override:
                logger.info(f"🎯 Override HIT: {description}")
                result.update(override)
                result["cache_hit"] = True
                result["cache_source"] = "override"
                return result

        # Step 1: Try common foods database (instant lookup)
        if use_cache:
            common_food = await self._try_common_food(description)
            if common_food:
                logger.info(f"🎯 Common food HIT: {description}")
                result.update(common_food)
                result["cache_hit"] = True
                result["cache_source"] = "common_foods"
                return result

        # Step 1b: Try multi-item lookup (overrides + common foods)
        if use_cache:
            multi_result = await self._try_multi_item_lookup(description, user_id)
            if multi_result:
                logger.info(f"🎯 Multi-item lookup HIT: {description}")
                result.update(multi_result)
                result["cache_hit"] = True
                result["cache_source"] = "multi_lookup"
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

    async def _try_saved_food(
        self, description: str, user_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Try to find food in user's saved foods.

        Args:
            description: Food description
            user_id: User ID for scoping

        Returns:
            Formatted analysis result if found, None otherwise
        """
        try:
            supabase = get_supabase()
            normalized = description.strip().lower()
            async with supabase.get_session() as session:
                result = await session.execute(
                    text(
                        "SELECT * FROM saved_foods "
                        "WHERE user_id = :uid AND LOWER(name) = :name "
                        "AND deleted_at IS NULL LIMIT 1"
                    ),
                    {"uid": user_id, "name": normalized},
                )
                row = result.fetchone()

            if not row:
                return None

            saved = dict(row._mapping)
            return self._saved_food_to_analysis(saved)

        except Exception as e:
            logger.warning(f"Saved food lookup failed: {e}")
            return None

    def _saved_food_to_analysis(self, saved: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert saved food record to standard analysis format.

        Saved foods store per-meal totals + food_items JSONB array.

        Args:
            saved: Record from saved_foods table

        Returns:
            Dict in same format as Gemini analysis
        """
        total_calories = int(saved.get("total_calories") or 0)
        protein_g = float(saved.get("total_protein_g") or 0)
        carbs_g = float(saved.get("total_carbs_g") or 0)
        fat_g = float(saved.get("total_fat_g") or 0)
        fiber_g = float(saved.get("total_fiber_g") or 0)

        # Map food_items JSONB array directly
        raw_items = saved.get("food_items") or []
        food_items = []
        for item in raw_items:
            fi = {
                "name": item.get("name", saved.get("name")),
                "amount": item.get("amount", "1 serving"),
                "calories": int(item.get("calories") or 0),
                "protein_g": float(item.get("protein_g") or 0),
                "carbs_g": float(item.get("carbs_g") or 0),
                "fat_g": float(item.get("fat_g") or 0),
                "fiber_g": float(item.get("fiber_g") or 0),
                "weight_g": float(item.get("weight_g")) if item.get("weight_g") else None,
                "weight_source": "exact",
                "unit": "g",
            }
            # Add per-gram scaling if weight available
            w = fi["weight_g"]
            if w and w > 0:
                fi["ai_per_gram"] = {
                    "calories": round(fi["calories"] / w, 3),
                    "protein": round(fi["protein_g"] / w, 4),
                    "carbs": round(fi["carbs_g"] / w, 4),
                    "fat": round(fi["fat_g"] / w, 4),
                    "fiber": round(fi["fiber_g"] / w, 4),
                }
            food_items.append(fi)

        # Fallback: if no food_items array, create one from totals
        if not food_items:
            food_items = [{
                "name": saved.get("name"),
                "amount": "1 serving",
                "calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "weight_source": "exact",
                "unit": "g",
            }]

        score = self._compute_health_score(total_calories, protein_g, fiber_g)

        return {
            "food_items": food_items,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": None,
            "recommended_swap": None,
            "overall_meal_score": saved.get("overall_meal_score") or score,
            "health_score": score,
            "data_source": "saved_food",
        }

    async def _try_override(self, description: str) -> Optional[Dict[str, Any]]:
        """
        Try to find food in the curated food_nutrition_overrides (3,785 items).

        Uses the FoodDatabaseLookupService singleton which keeps overrides
        in memory with a 30-min TTL.

        Args:
            description: Food description

        Returns:
            Formatted analysis result if found, None otherwise
        """
        try:
            lookup_service = get_food_db_lookup_service()
            await lookup_service._load_overrides()
            override = lookup_service._check_override(description)

            if not override:
                return None

            return self._override_to_analysis(override)

        except Exception as e:
            logger.warning(f"Override lookup failed: {e}")
            return None

    def _override_to_analysis(self, override: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert per-100g override to per-serving analysis format.

        Serving size priority: override_serving_g > override_weight_per_piece_g > 100g

        Args:
            override: Override dict from FoodDatabaseLookupService

        Returns:
            Dict in same format as Gemini analysis
        """
        # Determine serving size
        serving_g = (
            override.get("override_serving_g")
            or override.get("override_weight_per_piece_g")
            or 100.0
        )
        scale = serving_g / 100.0
        default_count = override.get("default_count", 1) or 1

        calories_per_serving = round(override["calories_per_100g"] * scale)
        protein_per_serving = round(override["protein_per_100g"] * scale, 1)
        carbs_per_serving = round(override["carbs_per_100g"] * scale, 1)
        fat_per_serving = round(override["fat_per_100g"] * scale, 1)
        fiber_per_serving = round(override.get("fiber_per_100g", 0) * scale, 1)

        total_calories = calories_per_serving * default_count
        total_protein = round(protein_per_serving * default_count, 1)
        total_carbs = round(carbs_per_serving * default_count, 1)
        total_fat = round(fat_per_serving * default_count, 1)
        total_fiber = round(fiber_per_serving * default_count, 1)

        # Build serving description
        if default_count > 1:
            amount = f"{default_count} x {serving_g:.0f}g"
        elif override.get("override_serving_g"):
            amount = f"{serving_g:.0f}g serving"
        elif override.get("override_weight_per_piece_g"):
            amount = f"1 piece ({serving_g:.0f}g)"
        else:
            amount = "100g"

        # Scale micronutrients by serving size and count (same as macros)
        micro_keys = (
            "sodium_mg", "cholesterol_mg", "saturated_fat_g", "trans_fat_g",
            "potassium_mg", "calcium_mg", "iron_mg", "vitamin_a_ug",
            "vitamin_c_mg", "vitamin_d_iu", "magnesium_mg", "zinc_mg",
            "phosphorus_mg", "selenium_ug", "omega3_g",
        )
        scaled_micros = {}
        per_gram_micros = {}
        for key in micro_keys:
            val = override.get(key)
            if val is not None:
                scaled_micros[key] = round(val * scale * default_count, 2)
                per_gram_micros[key] = round(val / 100, 4)

        food_item = {
            "name": override["display_name"],
            "amount": amount,
            "calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "weight_g": round(serving_g * default_count, 1),
            "weight_source": "exact",
            "unit": "g",
            # Per-gram scaling for frontend weight adjustment slider
            "ai_per_gram": {
                "calories": round(override["calories_per_100g"] / 100, 3),
                "protein": round(override["protein_per_100g"] / 100, 4),
                "carbs": round(override["carbs_per_100g"] / 100, 4),
                "fat": round(override["fat_per_100g"] / 100, 4),
                "fiber": round(override.get("fiber_per_100g", 0) / 100, 4),
                **per_gram_micros,
            },
        }

        # Add weight_per_unit_g for count-based adjustment
        if override.get("override_weight_per_piece_g"):
            food_item["weight_per_unit_g"] = override["override_weight_per_piece_g"]
            food_item["count"] = default_count

        score = self._compute_health_score(total_calories, total_protein, total_fiber)

        result = {
            "food_items": [food_item],
            "total_calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": None,
            "recommended_swap": None,
            "overall_meal_score": score,
            "health_score": score,
            "data_source": "override",
            "restaurant_name": override.get("restaurant_name"),
            "food_category": override.get("food_category"),
        }
        # Add scaled micronutrients to top-level response
        result.update(scaled_micros)
        return result

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

    async def _try_multi_item_lookup(
        self, description: str, user_id: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Try to resolve a multi-item food description from overrides + common foods.

        Only activates when multiple items are detected. For each item, checks:
        1. Override (3,785 curated items)
        2. Common foods DB
        If ALL items resolve, combines and returns the result.
        Any miss → returns None to let Gemini handle the entire description.

        Args:
            description: Food description
            user_id: Optional user ID (unused for now, reserved for saved food per-item)

        Returns:
            Combined analysis dict if all items found, None otherwise
        """
        try:
            items = self._split_food_description(description)
            if len(items) <= 1:
                return None

            # Ensure overrides are loaded
            lookup_service = get_food_db_lookup_service()
            await lookup_service._load_overrides()

            all_food_items = []
            total_cals = 0
            total_protein = 0.0
            total_carbs = 0.0
            total_fat = 0.0
            total_fiber = 0.0

            for qty, food_name in items:
                analysis = None

                # Try override first
                override = lookup_service._check_override(food_name)
                if override:
                    analysis = self._override_to_analysis(override)
                else:
                    # Try common foods
                    common = self.nutrition_db.get_common_food(food_name)
                    if common:
                        analysis = self._common_food_to_analysis(common)

                if not analysis:
                    # Any miss means we fall through to Gemini
                    return None

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

            # Compute a simple health score from combined macros
            score = self._compute_health_score(total_cals, total_protein, total_fiber)

            return {
                "food_items": all_food_items,
                "total_calories": total_cals,
                "protein_g": round(total_protein, 1),
                "carbs_g": round(total_carbs, 1),
                "fat_g": round(total_fat, 1),
                "fiber_g": round(total_fiber, 1),
                "encouragements": [],
                "warnings": [],
                "ai_suggestion": None,
                "recommended_swap": None,
                "overall_meal_score": score,
                "health_score": score,
                "data_source": "multi_lookup",
            }

        except Exception as e:
            logger.warning(f"Multi-item lookup failed: {e}")
            return None

    def _common_food_to_analysis(self, common_food: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert common food record to standard analysis format.

        Args:
            common_food: Record from common_foods table

        Returns:
            Dict in same format as Gemini analysis
        """
        weight_g = float(common_food.get("serving_weight_g", 0)) if common_food.get("serving_weight_g") else None
        calories = common_food.get("calories", 0)
        protein_g = float(common_food.get("protein_g", 0))
        carbs_g = float(common_food.get("carbs_g", 0))
        fat_g = float(common_food.get("fat_g", 0))
        fiber_g = float(common_food.get("fiber_g", 0))

        food_item = {
            "name": common_food.get("name"),
            "amount": common_food.get("serving_size", "1 serving"),
            "calories": calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "weight_g": weight_g,
            "weight_source": "exact",
            "unit": "g",
        }

        # Add per-gram scaling data so frontend can adjust portions
        if weight_g and weight_g > 0:
            food_item["ai_per_gram"] = {
                "calories": round(calories / weight_g, 3),
                "protein": round(protein_g / weight_g, 4),
                "carbs": round(carbs_g / weight_g, 4),
                "fat": round(fat_g / weight_g, 4),
                "fiber": round(fiber_g / weight_g, 4),
            }

        # Get micronutrients if available
        micronutrients = common_food.get("micronutrients", {})

        # Compute a simple health score from macros
        score = self._compute_health_score(calories, protein_g, fiber_g)

        return {
            "food_items": [food_item],
            "total_calories": calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
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
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": None,
            "recommended_swap": None,
            "overall_meal_score": score,
            "health_score": score,
            # Source tracking
            "data_source": common_food.get("source", "common_foods"),
            "category": common_food.get("category"),
        }

    @staticmethod
    def _compute_health_score(calories: int, protein_g: float, fiber_g: float) -> int:
        """Compute a simple health score (1-10) from macros."""
        protein_ratio = (protein_g * 4) / max(calories, 1)
        score = 5  # neutral baseline
        if protein_ratio >= 0.25:
            score += 2
        elif protein_ratio >= 0.15:
            score += 1
        if fiber_g >= 5:
            score += 1
        return min(score, 10)

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
