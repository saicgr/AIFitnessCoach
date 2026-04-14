"""Helper functions extracted from cache_service.
Food Analysis Caching Service.

Wraps Gemini food analysis with intelligent caching to dramatically
reduce response times for repeated queries.

Cache Strategy:
0a. Saved Foods - User's personal saved meals (instant, user-scoped)
0b. Food Nutrition Overrides - 6,949 curated items (instant)
1. Common Foods DB - Instant lookup (bypasses AI entirely)
1b. Multi-item lookup (overrides + common foods)
1c. Modified override (base item + modifiers like "extra patty", "no cheese")
2. Food Analysis Cache - Cached AI responses (~100ms)
3. Gemini AI - Fresh analysis (30-90s)

Expected Performance:
- Saved food / override hit: < 10ms
- Common food: < 1 second
- Cache hit: < 2 seconds
- Cache miss (first time): 30-60 seconds


"""
from typing import Any, Dict, List, Optional
import asyncio
import json
import logging
from datetime import datetime, timedelta
from sqlalchemy import text
from core.db.facade import get_supabase_db
from core.db.nutrition_db import NutritionDB
from core.supabase_client import get_supabase
from services.gemini_service import GeminiService
from services.food_database_lookup_service import get_food_db_lookup_service
from services.food_analysis.cache_service_helpers_part2 import FoodAnalysisCacheServicePart2
from services.food_analysis.modifiers_helpers import _build_default_modifiers

logger = logging.getLogger(__name__)


class FoodAnalysisCacheService(FoodAnalysisCacheServicePart2):
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

    async def enrich_with_tips(
        self,
        food_items: list,
        meal_type: Optional[str] = None,
        mood_before: Optional[str] = None,
        user_id: Optional[str] = None,
        coach_name: Optional[str] = None,
        coaching_style: Optional[str] = None,
        communication_tone: Optional[str] = None,
        timezone_str: str = "",  # REQUIRED: caller must pass user's IANA timezone
    ) -> Dict[str, Any]:
        """
        Generate contextual coach tips for food items using full user context.

        Fetches calorie budget (consumed today vs target), computes health score,
        then calls Gemini generate_food_review() with all context for score-stratified,
        mood-aware, calorie-budget-aware tips.

        Args:
            food_items: List of food item dicts with nutritional data
            meal_type: Meal type (breakfast, lunch, dinner, snack)
            mood_before: User's current mood/state
            user_id: User ID for fetching goals, targets, and daily summary

        Returns:
            Dict with encouragements, warnings, ai_suggestion, recommended_swap, health_score
        """
        # Compute aggregate food name and macros from items
        food_names = [item.get("name", "food") for item in food_items]
        food_name = ", ".join(food_names)

        total_cal = sum(item.get("calories", 0) for item in food_items)
        total_protein = sum(float(item.get("protein_g", 0)) for item in food_items)
        total_carbs = sum(float(item.get("carbs_g", 0)) for item in food_items)
        total_fat = sum(float(item.get("fat_g", 0)) for item in food_items)
        total_fiber = sum(float(item.get("fiber_g", 0)) for item in food_items)

        macros = {
            "calories": total_cal,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
        }

        # Compute health score from items (average goal_score if available, else rule-based)
        item_scores = [item.get("goal_score") or item.get("health_score") for item in food_items]
        item_scores = [s for s in item_scores if s is not None]
        if item_scores:
            health_score = round(sum(item_scores) / len(item_scores))
        else:
            health_score = self._compute_health_score(total_cal, total_protein, total_fiber)

        # Fetch user context (goals, targets, daily summary)
        user_goals = []
        nutrition_targets = {}
        calories_consumed_today = None
        calories_remaining = None

        daily_target = None
        if user_id:
            try:
                supabase = get_supabase()
                async with supabase.get_session() as session:
                    # Get user goals
                    user_result = await session.execute(
                        text("SELECT goals, daily_calorie_target FROM users WHERE id = :uid LIMIT 1"),
                        {"uid": user_id},
                    )
                    user_row = user_result.fetchone()
                    if user_row:
                        goals_val = user_row._mapping.get("goals")
                        if isinstance(goals_val, list):
                            user_goals = goals_val
                        elif isinstance(goals_val, str):
                            try:
                                user_goals = json.loads(goals_val)
                            except (json.JSONDecodeError, TypeError):
                                user_goals = [goals_val] if goals_val else []

                        daily_target = user_row._mapping.get("daily_calorie_target")

                    # Get nutrition targets from preferences
                    targets_result = await session.execute(
                        text(
                            "SELECT target_calories AS calories, target_protein_g AS protein_g, "
                            "target_carbs_g AS carbs_g, target_fat_g AS fat_g "
                            "FROM nutrition_preferences WHERE user_id = :uid LIMIT 1"
                        ),
                        {"uid": user_id},
                    )
                    targets_row = targets_result.fetchone()
                    if targets_row:
                        nutrition_targets = dict(targets_row._mapping)

                    # Get coach persona from AI settings (if not already passed)
                    if not coach_name:
                        try:
                            coach_result = await session.execute(
                                text(
                                    "SELECT coach_name, coaching_style, communication_tone "
                                    "FROM user_ai_settings WHERE user_id = :uid LIMIT 1"
                                ),
                                {"uid": user_id},
                            )
                            coach_row = coach_result.fetchone()
                            if coach_row:
                                coach_name = coach_row._mapping.get("coach_name")
                                coaching_style = coach_row._mapping.get("coaching_style")
                                communication_tone = coach_row._mapping.get("communication_tone")
                        except Exception as e:
                            logger.warning(f"[EnrichTips] Failed to fetch coach persona: {e}", exc_info=True)

                # Get daily nutrition summary for calorie budget
                try:
                    from core.timezone_utils import get_user_today
                    today_str = get_user_today(timezone_str or "UTC")
                    nutrition_db = NutritionDB()
                    daily_summary = nutrition_db.get_daily_nutrition_summary(user_id, today_str)
                    calories_consumed_today = daily_summary.get("total_calories", 0)

                    # Use target from preferences first, then user table
                    target_cal = nutrition_targets.get("calories") or (daily_target if user_row else None)
                    if target_cal:
                        calories_remaining = max(0, int(target_cal) - calories_consumed_today)
                except Exception as e:
                    logger.warning(f"[EnrichTips] Failed to get daily summary: {e}", exc_info=True)

            except Exception as e:
                logger.warning(f"[EnrichTips] Failed to fetch user data: {e}", exc_info=True)

        # Call Gemini for contextual tips
        try:
            review = await self.gemini_service.generate_food_review(
                food_name=food_name,
                macros=macros,
                user_goals=user_goals,
                nutrition_targets=nutrition_targets,
                meal_type=meal_type,
                mood_before=mood_before,
                calories_consumed_today=calories_consumed_today,
                calories_remaining=calories_remaining,
                health_score=health_score,
                coach_name=coach_name,
                coaching_style=coaching_style,
                communication_tone=communication_tone,
            )
            if review:
                # Use the Gemini-returned health_score if we didn't have one from items
                if not item_scores and review.get("health_score"):
                    health_score = review["health_score"]
                return {
                    "encouragements": review.get("encouragements", []),
                    "warnings": review.get("warnings", []),
                    "ai_suggestion": review.get("ai_suggestion", ""),
                    "recommended_swap": review.get("recommended_swap", ""),
                    "health_score": health_score,
                }
        except Exception as e:
            logger.error(f"[EnrichTips] Gemini call failed: {e}", exc_info=True)

        # Fallback: return just the computed health_score with no tips
        return {
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": "",
            "recommended_swap": "",
            "health_score": health_score,
        }

    async def analyze_food(
        self,
        description: str,
        user_goals: Optional[List[str]] = None,
        nutrition_targets: Optional[Dict] = None,
        rag_context: Optional[str] = None,
        use_cache: bool = True,
        user_id: Optional[str] = None,
        mood_before: Optional[str] = None,
        meal_type: Optional[str] = None,
        personal_history: Optional[List[Dict]] = None,
    ) -> Dict[str, Any]:
        """
        Analyze food with intelligent caching.

        Order of operations:
        0a. Check user's saved foods (instant, user-scoped)
        0b. Check food nutrition overrides - 6,949 curated items (instant)
        1. Check common foods database (instant, bypasses AI)
        1b. Try multi-item lookup (overrides + common foods)
        1c. Try modified override (base item + modifiers like "extra patty")
        2. Check food analysis cache (cached AI response)
        3. Fall back to fresh Gemini analysis (cache result)

        For cache hits, enriches with contextual coach tips via enrich_with_tips().

        Args:
            description: Food description text
            user_goals: List of user fitness goals
            nutrition_targets: Dict with calorie/macro targets
            rag_context: RAG context from nutrition knowledge base
            use_cache: Whether to use caching (default True)
            user_id: Optional user ID for saved foods lookup
            mood_before: User's current mood/state
            meal_type: Meal type (breakfast, lunch, dinner, snack)

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
                # Enrich cache hit with contextual tips
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 0b: Try food nutrition overrides (3,785 curated items)
        if use_cache:
            override = await self._try_override(description)
            if override:
                logger.info(f"🎯 Override HIT: {description}")
                result.update(override)
                result["cache_hit"] = True
                result["cache_source"] = "override"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 1: Try common foods database (instant lookup)
        if use_cache:
            common_food = await self._try_common_food(description)
            if common_food:
                logger.info(f"🎯 Common food HIT: {description}")
                result.update(common_food)
                result["cache_hit"] = True
                result["cache_source"] = "common_foods"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 1b: Try multi-item lookup (overrides + common foods)
        if use_cache:
            multi_result = await self._try_multi_item_lookup(description, user_id)
            if multi_result:
                logger.info(f"🎯 Multi-item lookup HIT: {description}")
                result.update(multi_result)
                result["cache_hit"] = True
                result["cache_source"] = "multi_lookup"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 1c: Try modified override (base item + modifiers like "extra patty", "no cheese")
        if use_cache:
            modified = await self._try_modified_override(description)
            if modified:
                logger.info(f"🎯 Modified override HIT: {description}")
                result.update(modified)
                result["cache_hit"] = True
                result["cache_source"] = "modified_override"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 2: Try food analysis cache (cached AI response)
        if use_cache:
            cached = await self._try_cache(description)
            if cached:
                logger.info(f"🎯 Cache HIT for: {description[:50]}...")
                result.update(cached)
                result["cache_hit"] = True
                result["cache_source"] = "analysis_cache"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 3: Fresh Gemini analysis
        logger.info(f"🔄 Cache MISS - calling Gemini for: {description[:50]}...")

        analysis = await self.gemini_service.parse_food_description(
            description=description,
            user_goals=user_goals,
            nutrition_targets=nutrition_targets,
            rag_context=rag_context,
            mood_before=mood_before,
            meal_type=meal_type,
            user_id=user_id,
            personal_history=personal_history,
        )

        if analysis and analysis.get('food_items'):
            # Cache the successful result — only when there's NO personal history.
            # With history, the analysis includes a user-specific warning and
            # MUST NOT be cached globally (user A's history would leak to user B).
            if use_cache and not personal_history:
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

    def apply_personal_history_to_cache_hit(
        self,
        result: Dict[str, Any],
        personal_history: Optional[List[Dict]],
    ) -> None:
        """When analyze_food returned a cache hit (saved food / override / common /
        cached Gemini), Gemini's prompt never ran so its personal_history_note is
        absent. Synthesize one here from the history rows so the client still
        surfaces the pattern. Modifies `result` in place."""
        if not personal_history or not result:
            return
        warnable = [
            h for h in personal_history
            if (h.get("severity") or "").lower() in ("strong", "moderate")
        ]
        if not warnable:
            return
        # Pick the highest-severity row for the headline note.
        strong = [h for h in warnable if (h.get("severity") or "") == "strong"]
        pick = strong[0] if strong else warnable[0]
        food = pick.get("food_name") or "this meal"
        symptom = pick.get("dominant_symptom") or "off"
        neg = int(pick.get("negative_mood_count") or 0)
        total = int(pick.get("logs") or 0)
        severity = pick.get("severity") or "moderate"
        if severity == "strong":
            note = (
                f"Heads up — {food} has consistently left you feeling {symptom} "
                f"({neg} of {total} past logs)."
            )
        else:
            note = (
                f"Note: {food} has sometimes left you feeling {symptom} "
                f"({neg} of {total} past logs)."
            )
        result["personal_history_note"] = note
        warnings = list(result.get("warnings") or [])
        warnings.insert(0, note)
        result["warnings"] = warnings

    async def _enrich_cache_hit_with_tips(
        self,
        result: Dict[str, Any],
        meal_type: Optional[str],
        mood_before: Optional[str],
        user_id: Optional[str],
        timezone_str: str = "",
    ) -> None:
        """
        Enrich a cache-hit result with contextual coach tips if missing.

        Modifies result dict in-place by adding tip fields from enrich_with_tips().
        Only calls Gemini if tips are empty/missing in the cached data.
        """
        # Check if tips are already present and non-empty
        has_tips = (
            result.get("ai_suggestion")
            or result.get("encouragements")
            or result.get("warnings")
        )
        if has_tips:
            return

        food_items = result.get("food_items", [])
        if not food_items:
            return

        try:
            tips = await self.enrich_with_tips(
                food_items=food_items,
                meal_type=meal_type,
                mood_before=mood_before,
                user_id=user_id,
                timezone_str=timezone_str,
            )
            if tips:
                result["encouragements"] = tips.get("encouragements", [])
                result["warnings"] = tips.get("warnings", [])
                result["ai_suggestion"] = tips.get("ai_suggestion", "")
                result["recommended_swap"] = tips.get("recommended_swap", "")
                if tips.get("health_score") and not result.get("health_score"):
                    result["health_score"] = tips["health_score"]
                logger.info(f"[EnrichTips] Enriched cache hit with tips for {len(food_items)} items")
        except Exception as e:
            logger.warning(f"[EnrichTips] Failed to enrich cache hit: {e}", exc_info=True)

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
            logger.warning(f"Common food lookup failed: {e}", exc_info=True)
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
            logger.warning(f"Saved food lookup failed: {e}", exc_info=True)
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
            # Use exact-only here — fuzzy on multi-food descriptions can match
            # a minor ingredient (e.g., "everything bagel seasoning" from a full meal)
            override = lookup_service._check_override(description)
            food_key = description  # Track which key matched for default modifiers
            if override:
                result = self._override_to_analysis(override)
                self._inject_default_modifiers(result, food_key, override)
                return result

            # Parse to extract quantity/weight, then look up cleaned food name
            parsed = self._parse_single_item(description)
            if not parsed:
                return None

            # Fuzzy match on the parsed food name (safe — single food, not full description)
            override = await lookup_service._check_override_fuzzy_db(parsed.food_name)
            food_key = parsed.food_name
            if not override:
                return None

            # Scale based on what was parsed
            if parsed.weight_g:
                result = self._override_to_analysis_by_weight(override, parsed.weight_g)
            elif parsed.quantity != 1.0:
                result = self._override_to_analysis_scaled(override, parsed.quantity)
            else:
                result = self._override_to_analysis(override)

            self._inject_default_modifiers(result, food_key, override)
            return result

        except Exception as e:
            logger.warning(f"Override lookup failed: {e}", exc_info=True)
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

    @staticmethod
    def _inject_default_modifiers(
        result: Dict[str, Any], food_key: str, override: Dict[str, Any]
    ) -> None:
        """Inject default modifier groups (e.g. steak doneness) into analysis result."""
        # Check both the lookup key and the override's food_name_normalized
        override_name = override.get("food_name_normalized", "")
        default_mods = _build_default_modifiers(food_key)
        if not default_mods:
            default_mods = _build_default_modifiers(override_name)
        if not default_mods:
            return

        food_items = result.get("food_items", [])
        if not food_items:
            return
        fi = food_items[0]
        existing_mods = fi.get("modifiers", [])
        # Don't inject if a modifier of the same group already exists
        existing_groups = {m.get("group") for m in existing_mods if m.get("group")}
        for mod in default_mods:
            if mod.get("group") not in existing_groups:
                existing_mods.append(mod)
        fi["modifiers"] = existing_mods

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
                logger.error(f"❌ Failed to auto-learn food '{item.get('name')}': {e}", exc_info=True)

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



# Singleton instance
_cache_service_instance: Optional[FoodAnalysisCacheService] = None


def get_food_analysis_cache_service() -> FoodAnalysisCacheService:
    """Get or create the singleton cache service instance."""
    global _cache_service_instance
    if _cache_service_instance is None:
        _cache_service_instance = FoodAnalysisCacheService()
    return _cache_service_instance
