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
from dataclasses import dataclass, field
from typing import Optional, Dict, Any, List, Tuple

from sqlalchemy import text

from core.db.facade import get_supabase_db
from core.db.nutrition_db import NutritionDB
from core.supabase_client import get_supabase
from services.food_database_lookup_service import get_food_db_lookup_service
from services.gemini_service import GeminiService

logger = logging.getLogger(__name__)


@dataclass
class ParsedFoodItem:
    """A single parsed food item extracted from a natural-language description."""
    food_name: str          # Cleaned name for DB lookup
    quantity: float = 1.0   # Count (pieces/servings)
    weight_g: float = None  # Explicit weight in grams (e.g., "300g haleem")
    volume_ml: float = None # Explicit volume (converted to weight_g using 1ml~1g)
    unit: str = None        # "plate", "bowl", "glass", "slice", "cup", etc.
    raw_text: str = ""      # Original text before parsing


# ── Parsing constants ─────────────────────────────────────────────

_WORD_NUMBERS = {
    "a": 1, "an": 1, "one": 1, "two": 2, "three": 3, "four": 4,
    "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "half": 0.5, "quarter": 0.25, "dozen": 12, "couple": 2,
}

# Units that indicate "how many" (not weight/volume)
_COUNT_UNITS = frozenset([
    "plate", "plates", "bowl", "bowls", "glass", "glasses",
    "slice", "slices", "piece", "pieces", "cup", "cups",
    "scoop", "scoops", "spoon", "spoons", "tablespoon", "tablespoons",
    "teaspoon", "teaspoons", "tbsp", "tsp", "serving", "servings",
    "handful", "handfuls", "stick", "sticks", "can", "cans",
    "bottle", "bottles", "packet", "packets", "box", "boxes",
    "bar", "bars", "strip", "strips", "roll", "rolls",
    "portion", "portions",
])

# Weight pattern: number + weight unit (possibly with space)
_WEIGHT_REGEX = re.compile(
    r'^(\d+(?:\.\d+)?)\s*'
    r'(g|gm|gms|gram|grams|kg|kilo|kilogram|kilograms|oz|ounce|ounces)\b'
    r'\s*(?:of\s+)?(.+)$',
    re.IGNORECASE,
)

# Weight AFTER food: "rice 100g"
_WEIGHT_AFTER_REGEX = re.compile(
    r'^(.+?)\s+(\d+(?:\.\d+)?)\s*'
    r'(g|gm|gms|gram|grams|kg|kilo|kilogram|kilograms|oz|ounce|ounces)$',
    re.IGNORECASE,
)

# Volume pattern: number + volume unit
_VOLUME_REGEX = re.compile(
    r'^(\d+(?:\.\d+)?)\s*'
    r'(ml|milliliter|milliliters|millilitres|l|liter|litre|liters|litres'
    r'|fl\s*oz|fluid\s*oz)\b'
    r'\s*(?:of\s+)?(.+)$',
    re.IGNORECASE,
)

# Volume AFTER food: "milk 500ml"
_VOLUME_AFTER_REGEX = re.compile(
    r'^(.+?)\s+(\d+(?:\.\d+)?)\s*'
    r'(ml|milliliter|milliliters|millilitres|l|liter|litre|liters|litres'
    r'|fl\s*oz|fluid\s*oz)$',
    re.IGNORECASE,
)

# Filler phrases to strip from the start
_FILLER_REGEX = re.compile(
    r'^(?:i\s+(?:had|ate|just\s+had|just\s+ate|drank|just\s+drank)\s+)'
    r'|^(?:about|maybe|around|approximately|roughly|nearly|like)\s+',
    re.IGNORECASE,
)

# Bullet / prefix patterns
_BULLET_REGEX = re.compile(
    r'^(?:[-•*]\s+|\d+[.)]\s+|(?:breakfast|lunch|dinner|snack|brunch|supper)\s*:\s*)',
    re.IGNORECASE,
)

# Numeric + count-unit: "6 slices pizza"
_NUM_UNIT_REGEX = re.compile(
    r'^(\d+(?:\.\d+)?)\s+(' + '|'.join(_COUNT_UNITS) + r')\s+(?:of\s+)?(.+)$',
    re.IGNORECASE,
)

# Word number + optional unit: "one plate biryani", "half a pizza", "a bowl of soup"
_WORD_NUM_PATTERN = '|'.join(re.escape(w) for w in _WORD_NUMBERS)
_WORD_NUM_UNIT_REGEX = re.compile(
    r'^(' + _WORD_NUM_PATTERN + r')\s+'
    r'(?:a\s+)?'
    r'(?:(' + '|'.join(_COUNT_UNITS) + r')\s+(?:of\s+)?)?'
    r'(.+)$',
    re.IGNORECASE,
)

# Bare number prefix: "2 dosa", "100 rice"
_BARE_NUM_REGEX = re.compile(r'^(\d+(?:\.\d+)?)\s+(.+)$')

# Fraction prefix: "1/2 pizza"
_FRACTION_REGEX = re.compile(r'^(\d+)/(\d+)\s+(.+)$')


def _weight_unit_to_grams(value: float, unit: str) -> float:
    """Convert a weight value+unit to grams."""
    u = unit.lower().rstrip('s')
    if u in ('g', 'gm', 'gram'):
        return value
    if u in ('kg', 'kilo', 'kilogram'):
        return value * 1000
    if u in ('oz', 'ounce'):
        return value * 28.35
    return value


def _volume_unit_to_ml(value: float, unit: str) -> float:
    """Convert a volume value+unit to milliliters."""
    u = unit.lower().replace(' ', '')
    if u in ('ml', 'milliliter', 'milliliters', 'millilitres'):
        return value
    if u in ('l', 'liter', 'litre', 'liters', 'litres'):
        return value * 1000
    if u in ('floz', 'fluidoz'):
        return value * 29.57
    return value


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

        Parses quantity/weight from the description, looks up the cleaned food name,
        then scales the result accordingly.

        Examples:
            "2 dosa"     → food="dosa", qty=2 → scale by 2
            "300g rice"  → food="rice", weight_g=300 → scale per-100g
            "biryani"    → food="biryani", qty=1 → default serving

        Args:
            description: Food description

        Returns:
            Formatted analysis result if found, None otherwise
        """
        try:
            lookup_service = get_food_db_lookup_service()
            await lookup_service._load_overrides()

            # First try exact match on full description (handles "chicken 65", etc.)
            override = lookup_service._check_override(description)
            if override:
                return self._override_to_analysis(override)

            # Parse to extract quantity/weight, then look up cleaned food name
            parsed = self._parse_single_item(description)
            if not parsed:
                return None

            override = lookup_service._check_override(parsed.food_name)
            if not override:
                return None

            # Scale based on what was parsed
            if parsed.weight_g:
                return self._override_to_analysis_by_weight(override, parsed.weight_g)
            elif parsed.quantity != 1.0:
                return self._override_to_analysis_scaled(override, parsed.quantity)
            else:
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

    def _override_to_analysis_by_weight(
        self, override: Dict[str, Any], weight_g: float
    ) -> Dict[str, Any]:
        """
        Convert override to analysis using explicit weight in grams.
        Scales per-100g data by weight_g/100.

        Args:
            override: Override dict from FoodDatabaseLookupService
            weight_g: Explicit weight in grams

        Returns:
            Dict in same format as Gemini analysis
        """
        scale = weight_g / 100.0

        total_calories = round(override["calories_per_100g"] * scale)
        total_protein = round(override["protein_per_100g"] * scale, 1)
        total_carbs = round(override["carbs_per_100g"] * scale, 1)
        total_fat = round(override["fat_per_100g"] * scale, 1)
        total_fiber = round(override.get("fiber_per_100g", 0) * scale, 1)

        amount = f"{weight_g:.0f}g"

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
                scaled_micros[key] = round(val * scale, 2)
                per_gram_micros[key] = round(val / 100, 4)

        food_item = {
            "name": override["display_name"],
            "amount": amount,
            "calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "weight_g": round(weight_g, 1),
            "weight_source": "exact",
            "unit": "g",
            "ai_per_gram": {
                "calories": round(override["calories_per_100g"] / 100, 3),
                "protein": round(override["protein_per_100g"] / 100, 4),
                "carbs": round(override["carbs_per_100g"] / 100, 4),
                "fat": round(override["fat_per_100g"] / 100, 4),
                "fiber": round(override.get("fiber_per_100g", 0) / 100, 4),
                **per_gram_micros,
            },
        }

        if override.get("override_weight_per_piece_g"):
            food_item["weight_per_unit_g"] = override["override_weight_per_piece_g"]

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
        result.update(scaled_micros)
        return result

    def _override_to_analysis_scaled(
        self, override: Dict[str, Any], count: float
    ) -> Dict[str, Any]:
        """
        Convert override to analysis scaled by a given count.
        Uses serving size (override_serving_g or override_weight_per_piece_g or 100g)
        as the base, then multiplies by count.

        Args:
            override: Override dict from FoodDatabaseLookupService
            count: Number of servings/pieces

        Returns:
            Dict in same format as Gemini analysis
        """
        serving_g = (
            override.get("override_serving_g")
            or override.get("override_weight_per_piece_g")
            or 100.0
        )
        scale = serving_g / 100.0

        calories_per_serving = round(override["calories_per_100g"] * scale)
        protein_per_serving = round(override["protein_per_100g"] * scale, 1)
        carbs_per_serving = round(override["carbs_per_100g"] * scale, 1)
        fat_per_serving = round(override["fat_per_100g"] * scale, 1)
        fiber_per_serving = round(override.get("fiber_per_100g", 0) * scale, 1)

        total_calories = round(calories_per_serving * count)
        total_protein = round(protein_per_serving * count, 1)
        total_carbs = round(carbs_per_serving * count, 1)
        total_fat = round(fat_per_serving * count, 1)
        total_fiber = round(fiber_per_serving * count, 1)

        # Build serving description
        count_display = int(count) if count == int(count) else count
        if override.get("override_weight_per_piece_g"):
            amount = f"{count_display} piece{'s' if count != 1 else ''} ({round(serving_g * count):.0f}g)"
        else:
            amount = f"{count_display} x {serving_g:.0f}g"

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
                scaled_micros[key] = round(val * scale * count, 2)
                per_gram_micros[key] = round(val / 100, 4)

        food_item = {
            "name": override["display_name"],
            "amount": amount,
            "calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "weight_g": round(serving_g * count, 1),
            "weight_source": "exact",
            "unit": "g",
            "ai_per_gram": {
                "calories": round(override["calories_per_100g"] / 100, 3),
                "protein": round(override["protein_per_100g"] / 100, 4),
                "carbs": round(override["carbs_per_100g"] / 100, 4),
                "fat": round(override["fat_per_100g"] / 100, 4),
                "fiber": round(override.get("fiber_per_100g", 0) / 100, 4),
                **per_gram_micros,
            },
        }

        if override.get("override_weight_per_piece_g"):
            food_item["weight_per_unit_g"] = override["override_weight_per_piece_g"]
            food_item["count"] = count_display

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
    ) -> List[ParsedFoodItem]:
        """
        Split a multi-item food description into individual ParsedFoodItems.

        Splitting order:
        1. Newlines
        2. Commas
        3. " and " / " & " / " + " (with compound food protection)
        4. Does NOT split on " with " (part of food names like "dosa with chutney")

        Per-item parsing extracts quantity, weight_g, volume_ml, unit, and food_name.

        Args:
            description: Food description potentially containing multiple items

        Returns:
            List of ParsedFoodItem
        """
        raw_parts = self._split_text_into_parts(description.strip())
        items: List[ParsedFoodItem] = []
        for part in raw_parts:
            parsed = self._parse_single_item(part)
            if parsed:
                items.append(parsed)
        return items

    def _split_text_into_parts(self, text: str) -> List[str]:
        """Split text into individual food strings using newlines, commas, and conjunctions."""
        # Step 1: Split on newlines
        lines = [l.strip() for l in text.split('\n') if l.strip()]
        parts: List[str] = []
        for line in lines:
            # Step 2: Split on commas
            comma_parts = [p.strip() for p in line.split(',') if p.strip()]
            for cp in comma_parts:
                # Step 3: Split on " and " / " & " / " + " with compound food protection
                parts.extend(self._split_on_conjunctions(cp))
        return parts

    def _split_on_conjunctions(self, text: str) -> List[str]:
        """Split on ' and ', ' & ', ' + ' but protect compound foods like 'mac and cheese'."""
        # Check if the full text is a known override → don't split
        lookup_service = get_food_db_lookup_service()
        if lookup_service._overrides.get(text.lower().strip()):
            return [text]

        # Try splitting
        parts = re.split(r'\s+and\s+|\s*&\s*|\s*\+\s*', text, flags=re.IGNORECASE)
        parts = [p.strip() for p in parts if p.strip()]
        if len(parts) <= 1:
            return [text]

        # Check if any adjacent pair forms a compound food
        # e.g., "mac and cheese" → rejoin if "mac and cheese" is in overrides
        merged: List[str] = []
        i = 0
        while i < len(parts):
            if i + 1 < len(parts):
                compound = f"{parts[i]} and {parts[i+1]}"
                if lookup_service._overrides.get(compound.lower().strip()):
                    merged.append(compound)
                    i += 2
                    continue
            merged.append(parts[i])
            i += 1
        return merged

    def _parse_single_item(self, raw: str) -> Optional[ParsedFoodItem]:
        """Parse a single food string into a ParsedFoodItem."""
        text = raw.strip()
        if not text:
            return None

        # Strip fillers: "I had", "I ate", "about", etc.
        text = _FILLER_REGEX.sub('', text).strip()
        # Strip bullets: "- ", "• ", "1. ", "breakfast: "
        text = _BULLET_REGEX.sub('', text).strip()
        # Strip leading "and " / "or "
        text = re.sub(r'^(?:and|or)\s+', '', text, flags=re.IGNORECASE).strip()

        if not text:
            return None

        # Full-text override check: if entire text (including number) is a known override
        # This handles "chicken 65", "5 star chocolate", "7up"
        lookup_service = get_food_db_lookup_service()
        if lookup_service._overrides.get(text.lower().strip()):
            return ParsedFoodItem(food_name=text, quantity=1.0, raw_text=raw)

        # Try weight BEFORE food: "300g haleem", "0.5kg chicken"
        m = _WEIGHT_REGEX.match(text)
        if m:
            val = float(m.group(1))
            wg = _weight_unit_to_grams(val, m.group(2))
            food = m.group(3).strip()
            return ParsedFoodItem(food_name=food, weight_g=wg, raw_text=raw)

        # Try volume BEFORE food: "500ml milk", "2 liters water"
        m = _VOLUME_REGEX.match(text)
        if m:
            val = float(m.group(1))
            ml = _volume_unit_to_ml(val, m.group(2))
            food = m.group(3).strip()
            return ParsedFoodItem(food_name=food, weight_g=ml, volume_ml=ml, raw_text=raw)

        # Try weight AFTER food: "rice 100g"
        m = _WEIGHT_AFTER_REGEX.match(text)
        if m:
            food = m.group(1).strip()
            val = float(m.group(2))
            wg = _weight_unit_to_grams(val, m.group(3))
            return ParsedFoodItem(food_name=food, weight_g=wg, raw_text=raw)

        # Try volume AFTER food: "milk 500ml"
        m = _VOLUME_AFTER_REGEX.match(text)
        if m:
            food = m.group(1).strip()
            val = float(m.group(2))
            ml = _volume_unit_to_ml(val, m.group(2))
            return ParsedFoodItem(food_name=food, weight_g=ml, volume_ml=ml, raw_text=raw)

        # Try numeric + count-unit: "6 slices pizza", "2 cups rice"
        m = _NUM_UNIT_REGEX.match(text)
        if m:
            qty = float(m.group(1))
            unit = m.group(2).lower()
            food = m.group(3).strip()
            return ParsedFoodItem(food_name=food, quantity=qty, unit=unit, raw_text=raw)

        # Try word number + optional unit: "one plate biryani", "half a pizza", "a bowl of soup"
        m = _WORD_NUM_UNIT_REGEX.match(text)
        if m:
            word = m.group(1).lower()
            qty = _WORD_NUMBERS.get(word, 1.0)
            unit = m.group(2).lower() if m.group(2) else None
            food = m.group(3).strip()
            # Strip leading "of " from food if present
            food = re.sub(r'^of\s+', '', food, flags=re.IGNORECASE)
            return ParsedFoodItem(food_name=food, quantity=qty, unit=unit, raw_text=raw)

        # Try fraction: "1/2 pizza"
        m = _FRACTION_REGEX.match(text)
        if m:
            qty = float(m.group(1)) / float(m.group(2))
            food = m.group(3).strip()
            return ParsedFoodItem(food_name=food, quantity=qty, raw_text=raw)

        # Try bare number: "2 dosa", "100 rice"
        m = _BARE_NUM_REGEX.match(text)
        if m:
            qty = float(m.group(1))
            food = m.group(2).strip()
            # Check if full text with number is a known override (e.g., "chicken 65")
            if lookup_service._overrides.get(text.lower().strip()):
                return ParsedFoodItem(food_name=text, quantity=1.0, raw_text=raw)
            return ParsedFoodItem(food_name=food, quantity=qty, raw_text=raw)

        # No quantity detected
        return ParsedFoodItem(food_name=text, quantity=1.0, raw_text=raw)

    async def _try_multi_item_lookup(
        self, description: str, user_id: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Try to resolve food description from overrides + common foods.

        Now handles single items with quantities (e.g., "2 dosa") in addition
        to multi-item descriptions. For each parsed item, checks:
        1. Exact override match
        2. Fuzzy override search (word-index)
        3. Common foods DB

        If ALL items resolve locally, combines and returns the result.
        If any item misses, returns None to let Gemini handle the full description.

        When weight_g is provided on a ParsedFoodItem, scales using per-100g data.
        Applies countability heuristic for bare numbers.

        Args:
            description: Food description
            user_id: Optional user ID

        Returns:
            Combined analysis dict if all items found, None otherwise
        """
        try:
            items = self._split_food_description(description)
            if not items:
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

            for item in items:
                analysis = self._resolve_single_parsed_item(item, lookup_service)

                if not analysis:
                    # Any miss means Gemini handles the full description
                    return None

                for fi in analysis["food_items"]:
                    all_food_items.append(fi)

                total_cals += analysis["total_calories"]
                total_protein += analysis["protein_g"]
                total_carbs += analysis["carbs_g"]
                total_fat += analysis["fat_g"]
                total_fiber += analysis["fiber_g"]

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

    def _resolve_single_parsed_item(
        self, item: ParsedFoodItem, lookup_service
    ) -> Optional[Dict[str, Any]]:
        """
        Resolve a single ParsedFoodItem to a nutrition analysis using overrides + common foods.

        Applies countability heuristic for bare numbers and weight-based scaling.

        Args:
            item: ParsedFoodItem from _split_food_description
            lookup_service: FoodDatabaseLookupService instance

        Returns:
            Analysis dict or None if not found
        """
        food_name = item.food_name
        override = lookup_service._check_override(food_name)

        # Fuzzy fallback: try word-index search if exact miss
        if not override:
            fuzzy_matches = lookup_service._find_matching_overrides_for_search(food_name)
            if fuzzy_matches and len(fuzzy_matches) == 1:
                # Only use fuzzy if there's exactly one match (unambiguous)
                match_name = fuzzy_matches[0].get("name", "")
                override = lookup_service._check_override(match_name)

        if override:
            # Weight-based scaling
            if item.weight_g:
                return self._override_to_analysis_by_weight(override, item.weight_g)

            # Apply countability heuristic for bare numbers (no unit specified)
            qty = item.quantity
            if qty != 1.0 and not item.unit:
                qty = self._apply_countability_heuristic(override, qty)

            if qty != 1.0:
                return self._override_to_analysis_scaled(override, qty)
            else:
                return self._override_to_analysis(override)

        # Try common foods DB
        common = self.nutrition_db.get_common_food(food_name)
        if common:
            analysis = self._common_food_to_analysis(common)
            # Scale by quantity if not 1.0
            qty = item.quantity
            if item.weight_g and analysis.get("food_items"):
                # Weight-based scaling for common foods
                fi = analysis["food_items"][0]
                base_weight = float(fi.get("weight_g") or 100)
                if base_weight > 0:
                    scale = item.weight_g / base_weight
                    self._scale_analysis(analysis, scale, f"{item.weight_g:.0f}g")
                return analysis
            elif qty != 1.0:
                self._scale_analysis(analysis, qty)
            return analysis

        return None

    @staticmethod
    def _apply_countability_heuristic(override: Dict, qty: float) -> float:
        """
        Apply countability heuristic for bare numbers (user typed "100 rice" or "2 dosa").

        Rules:
        - Countable food (has weight_per_piece_g) + qty <= 30 → count (pieces)
        - Countable food + qty > 30 → treat qty as grams, convert to piece-count
        - Non-countable (serving_g only) + qty > 10 → treat qty as grams
        - Non-countable + qty <= 10 → treat as servings
        - Unknown + qty > 20 → assume grams (return qty as weight_g later handled upstream)
        - Unknown + qty <= 20 → assume count

        Returns the effective count to pass to _override_to_analysis_scaled,
        or a negative value to signal weight-based scaling (caller checks).
        """
        has_piece_weight = override.get("override_weight_per_piece_g") is not None
        has_serving = override.get("override_serving_g") is not None

        if has_piece_weight:
            # Countable food
            if qty <= 30:
                return qty  # pieces
            else:
                # Treat as grams → convert to piece count
                piece_g = override["override_weight_per_piece_g"]
                return qty / piece_g if piece_g > 0 else qty
        elif has_serving:
            # Non-countable food
            if qty > 10:
                # Treat as grams → convert to serving count
                serv_g = override["override_serving_g"]
                return qty / serv_g if serv_g > 0 else qty
            else:
                return qty  # servings
        else:
            # Unknown structure
            if qty > 20:
                # Treat as grams → scale from 100g base
                return qty / 100.0
            else:
                return qty  # count

    def _scale_analysis(
        self, analysis: Dict[str, Any], scale: float, amount_label: str = None
    ) -> None:
        """Scale an analysis dict's food_items and totals by a multiplier (in-place)."""
        for fi in analysis.get("food_items", []):
            fi["calories"] = round(fi["calories"] * scale)
            fi["protein_g"] = round(fi["protein_g"] * scale, 1)
            fi["carbs_g"] = round(fi["carbs_g"] * scale, 1)
            fi["fat_g"] = round(fi["fat_g"] * scale, 1)
            fi["fiber_g"] = round(fi["fiber_g"] * scale, 1)
            if fi.get("weight_g"):
                fi["weight_g"] = round(fi["weight_g"] * scale, 1)
            if amount_label:
                fi["amount"] = amount_label
            elif scale != 1.0:
                scale_display = int(scale) if scale == int(scale) else round(scale, 1)
                fi["amount"] = f"{scale_display} x {fi['amount']}"

        analysis["total_calories"] = round(analysis["total_calories"] * scale)
        analysis["protein_g"] = round(analysis["protein_g"] * scale, 1)
        analysis["carbs_g"] = round(analysis["carbs_g"] * scale, 1)
        analysis["fat_g"] = round(analysis["fat_g"] * scale, 1)
        analysis["fiber_g"] = round(analysis["fiber_g"] * scale, 1)

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
