"""
Gemini Service Nutrition - Food image analysis, text parsing, inflammation analysis.
"""
import asyncio
import json
import logging
import time
import re
from typing import List, Dict, Optional

from google.genai import types
from core.config import get_settings
from core.ai_response_parser import parse_ai_json
from models.gemini_schemas import FoodAnalysisResponse
from services.gemini.constants import (
    client, _log_token_usage, _gemini_semaphore,
    _food_text_cache, settings, gemini_generate_with_retry,
)
from services.gemini.utils import _sanitize_for_prompt, safe_join_list

logger = logging.getLogger("gemini")

FOOD_ANALYSIS_TIMEOUT = 30


class NutritionMixin:
    """Mixin providing nutrition analysis methods for GeminiService."""

    # ============================================
    # Food Analysis Methods
    # ============================================

    async def analyze_food_image(
        self,
        image_base64: str,
        mime_type: str = "image/jpeg",
        request_id: str = None,
        user_id: Optional[str] = None,
    ) -> Dict:
        """
        Analyze a food image and extract nutrition information using Gemini Vision.

        Args:
            image_base64: Base64 encoded image data
            mime_type: Image MIME type (e.g., 'image/jpeg', 'image/png')
            request_id: Unique request ID for log traceability

        Returns:
            Dictionary with food_items, total_calories, protein_g, carbs_g, fat_g, fiber_g, feedback
            On error, returns dict with 'error', 'error_code', and 'error_details' keys
        """
        req_id = request_id or f"img_{int(time.time() * 1000)}"
        image_size_kb = len(image_base64) * 3 // 4 // 1024  # Approximate decoded size

        logger.info(f"[IMAGE-ANALYSIS:{req_id}] Starting food image analysis | mime={mime_type} | size_kb={image_size_kb}")

        # Prompt with weight/count fields for portion editing (like text describe feature)
        prompt = '''Analyze this food image and identify the foods with their nutrition.

Return ONLY valid JSON (no markdown):
{
  "food_items": [
    {"name": "Food name", "amount": "portion size", "calories": 150, "protein_g": 10.0, "carbs_g": 15.0, "fat_g": 5.0, "fiber_g": 2.0, "weight_g": 100, "unit": "g", "count": null, "weight_per_unit_g": null, "inflammation_score": 5, "is_ultra_processed": false}
  ],
  "total_calories": 450,
  "protein_g": 25.0,
  "carbs_g": 40.0,
  "fat_g": 15.0,
  "fiber_g": 5.0,
  "inflammation_score": 5,
  "is_ultra_processed": false,
  "feedback": "Brief nutritional feedback",
  "plate_description": "Brief visual description of the plate/scene, max 100 chars (e.g. 'A South Indian breakfast with steamed idlis, sambar, and chutneys')"
}

CRITICAL RULES:
- Identify ALL visible food items specifically (max 10 items)
- Be SPECIFIC with dish names: "Butter Chicken" not "Indian Curry", "Chicken Tikka Masala" not "Curry"
- For Indian food: identify specific dishes (dal makhani, paneer butter masala, chicken curry, biryani, etc.)
- RESTAURANT PORTIONS are large! Use realistic weights:
  - Naan bread: 80-100g EACH
  - Bowl of curry: 200-300g per bowl
  - Rice portion: 150-250g
  - Pakoras/samosas: 40-50g each
  - Roti/chapati: 40-50g each

WEIGHT/COUNT FIELDS (required for portion editing):
- weight_g: Total weight in grams for this item (be realistic for restaurant portions!)
- unit: "g" (solids), "ml" (liquids), "oz", "cups", "tsp", "tbsp"
- COUNTABLE items — discrete pieces you pick up and eat individually. ALWAYS set count + weight_per_unit_g:
  - Breads: naan(~90g), roti/chapati(~45g), paratha(~80g), puri(~25g), bhatura(~60g), dosa(~120g), appam(~50g), bread slice(~30g), tortilla(~35g), pita(~60g)
  - Indian snacks/starters: samosa(~80g), pakora/pakoda(~45g), vada/medu vada(~40g), bonda(~35g), bajji(~40g), cutlet(~60g), paneer tikka piece(~30g), chicken tikka piece(~35g), seekh kebab(~50g), shami kebab(~60g), chicken 65 piece(~25g), gobi/paneer manchurian piece(~25g), spring roll(~50g), egg roll(~80g), kachori(~50g), aloo tikki(~60g), dhokla piece(~30g), idli(~40g), momos/dumpling(~30g)
  - Western snacks: french fry(~8g), chip/crisp(~2g), tater tot(~10g), chicken nugget(~18g), meatball(~30g), falafel(~17g), chicken wing(~85g), sushi piece(~35g), pizza slice(~100g), taco(~80g), egg(~50g), cookie(~15g), donut(~60g), muffin(~120g), pancake(~40g), waffle(~75g), sausage/hot dog(~45g), crab rangoon(~25g), wonton(~15g), empanada(~80g), pierogi(~40g), gyoza(~25g), tempura piece(~30g)
  - Sweets: laddoo(~40g), gulab jamun(~40g), rasgulla(~40g), barfi piece(~30g), peda(~20g), jalebi piece(~25g), mysore pak piece(~30g), chocolate piece(~10g)
  - count: Number of pieces visible/described
  - weight_per_unit_g: Weight of ONE piece
  - weight_g = count × weight_per_unit_g
  - For "small fries"/"medium fries"/"large fries", estimate individual fry sticks (small≈40, medium≈55, large≈70) at ~8g each
- NON-COUNTABLE items — served as a portion/heap/bowl. Set count=null, weight_per_unit_g=null:
  - Indian mains/sides: curry (any), dal, sambhar, rasam, biryani, pulao, fried rice, curd rice, rice (any), upma, poha, khichdi, raita
  - Indian "fry" dishes: chicken fry, fish fry, prawn fry, bhindi fry, aloo fry, gobi fry, egg fry — these are DRY PREPARATIONS served as a portion, NOT individual countable pieces
  - Other: soup, salad, pasta, noodles, stir-fry, mashed potatoes, scrambled eggs, oatmeal/porridge, yogurt, ice cream, halwa, kheer/payasam, chutney, sauce, gravy

INFLAMMATION SCORE (1-10, 10 = most inflammatory):
1-2: Strongly anti-inflammatory (wild salmon, turmeric, berries, leafy greens, ginger tea, olive oil)
3-4: Mildly anti-inflammatory (most vegetables, whole grains, nuts, legumes, plain yogurt)
5: Neutral (plain eggs, plain rice, plain chicken breast, milk)
6-7: Mildly inflammatory (white bread, red meat, cheese, fried foods, butter)
8-9: Moderately inflammatory (processed meats, fast food, sugary drinks, packaged snacks, instant noodles)
10: Highly inflammatory (deep-fried ultra-processed combos, trans fat items, candy + soda meals)

ULTRA-PROCESSED (is_ultra_processed): true if food would be NOVA Group 4 — contains industrial additives like emulsifiers, hydrogenated oils, artificial sweeteners, protein isolates, modified starches, high-fructose corn syrup. Examples: Coca-Cola=true, instant noodles=true, grilled chicken=false, homemade samosa=false.

Per-item inflammation_score: Rate EACH food item individually. Meal-level inflammation_score: Calorie-weighted average of all items (round to nearest int).

MICRONUTRIENTS: Estimate all vitamins (A, C, D, E, K, B1, B2, B3, B6, B9, B12), minerals (calcium, iron, magnesium, zinc, selenium, potassium, sodium, phosphorus, copper, manganese), and fatty acids (omega-3, omega-6) for the total meal. Use standard USDA values for the identified foods.'''

        # Timeout for image analysis - needs to be generous for complex images
        IMAGE_ANALYSIS_TIMEOUT = 30  # 30 seconds — most images analyze in 2-8s, generous buffer for API spikes
        start_time = time.time()

        try:
            # Create image part from base64
            try:
                image_part = types.Part.from_bytes(
                    data=__import__('base64').b64decode(image_base64),
                    mime_type=mime_type
                )
                logger.info(f"[IMAGE-ANALYSIS:{req_id}] Image decoded successfully")
            except Exception as decode_err:
                logger.error(f"[IMAGE-ANALYSIS:{req_id}] FAILED to decode base64 image | error={decode_err}", exc_info=True)
                return {
                    "error": "Failed to decode image",
                    "error_code": "IMAGE_DECODE_FAILED",
                    "error_details": str(decode_err),
                    "request_id": req_id,
                }

            # Add timeout to prevent hanging on slow Gemini responses
            logger.info(f"[IMAGE-ANALYSIS:{req_id}] Sending to Gemini API | model={self.model} | timeout={IMAGE_ANALYSIS_TIMEOUT}s")
            try:
                response = await gemini_generate_with_retry(
                    model=self.model,
                    contents=[prompt, image_part],
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=FoodAnalysisResponse,
                        max_output_tokens=8192,  # High limit to prevent truncation with micronutrients
                        temperature=0.3,
                    ),
                    user_id=user_id,
                    timeout=IMAGE_ANALYSIS_TIMEOUT,
                    method_name="analyze_food_image",
                )
                elapsed = time.time() - start_time
                logger.info(f"[IMAGE-ANALYSIS:{req_id}] Gemini API responded | elapsed={elapsed:.2f}s")
            except asyncio.TimeoutError:
                elapsed = time.time() - start_time
                logger.error(f"[IMAGE-ANALYSIS:{req_id}] TIMEOUT after {elapsed:.2f}s (limit={IMAGE_ANALYSIS_TIMEOUT}s)", exc_info=True)
                return {
                    "error": f"Image analysis timed out after {IMAGE_ANALYSIS_TIMEOUT} seconds. Please try again.",
                    "error_code": "GEMINI_TIMEOUT",
                    "error_details": f"Gemini API did not respond within {IMAGE_ANALYSIS_TIMEOUT}s",
                    "request_id": req_id,
                    "elapsed_seconds": elapsed,
                }

            # Check for blocked/filtered response
            if hasattr(response, 'prompt_feedback') and response.prompt_feedback:
                feedback = response.prompt_feedback
                if hasattr(feedback, 'block_reason') and feedback.block_reason:
                    logger.error(f"[IMAGE-ANALYSIS:{req_id}] BLOCKED by safety filter | reason={feedback.block_reason}")
                    return {
                        "error": "Image was blocked by content safety filter. Please try a different image.",
                        "error_code": "SAFETY_FILTER_BLOCKED",
                        "error_details": f"Block reason: {feedback.block_reason}",
                        "request_id": req_id,
                    }

            # Check if response has candidates
            if not response.candidates:
                logger.error(f"[IMAGE-ANALYSIS:{req_id}] NO CANDIDATES in response | response={response}")
                return {
                    "error": "No analysis results returned from AI",
                    "error_code": "NO_CANDIDATES",
                    "error_details": "Gemini returned empty candidates array",
                    "request_id": req_id,
                }

            # Check candidate finish reason
            candidate = response.candidates[0]
            if hasattr(candidate, 'finish_reason'):
                finish_reason = str(candidate.finish_reason)
                if 'SAFETY' in finish_reason.upper():
                    logger.error(f"[IMAGE-ANALYSIS:{req_id}] SAFETY block on candidate | finish_reason={finish_reason}")
                    return {
                        "error": "Analysis blocked by content filter. Please try a different image.",
                        "error_code": "CANDIDATE_SAFETY_BLOCKED",
                        "error_details": f"Finish reason: {finish_reason}",
                        "request_id": req_id,
                    }

            # Use response.parsed for structured output - SDK handles JSON parsing
            parsed = response.parsed
            if not parsed:
                # Log raw response for debugging
                raw_text = response.text if hasattr(response, 'text') else 'N/A'
                logger.error(f"[IMAGE-ANALYSIS:{req_id}] PARSING FAILED | raw_response_preview={raw_text[:500] if raw_text else 'empty'}")
                return {
                    "error": "Could not parse AI response. Please try again.",
                    "error_code": "PARSE_FAILED",
                    "error_details": f"Raw response preview: {raw_text[:200] if raw_text else 'empty'}",
                    "request_id": req_id,
                }
            result = parsed.model_dump()
            logger.info(f"[IMAGE-ANALYSIS:{req_id}] Parsed successfully | food_items_count={len(result.get('food_items', []))}")

            # Debug: Log raw Gemini values BEFORE USDA enhancement
            logger.info(
                f"[IMAGE-ANALYSIS:{req_id}] RAW GEMINI VALUES | "
                f"total_calories={result.get('total_calories')} | "
                f"protein_g={result.get('protein_g')} | "
                f"carbs_g={result.get('carbs_g')} | "
                f"fat_g={result.get('fat_g')}"
            )
            for idx, item in enumerate(result.get('food_items', [])):
                logger.info(
                    f"[IMAGE-ANALYSIS:{req_id}] RAW ITEM[{idx}] | "
                    f"name={item.get('name')} | "
                    f"calories={item.get('calories')} | "
                    f"protein_g={item.get('protein_g')} | "
                    f"carbs_g={item.get('carbs_g')} | "
                    f"fat_g={item.get('fat_g')} | "
                    f"weight_g={item.get('weight_g')}"
                )

            # Validation: Check for items with 0 calories (suspicious)
            zero_cal_items = [item.get('name') for item in result.get('food_items', []) if item.get('calories', 0) == 0]
            if zero_cal_items:
                logger.warning(f"[IMAGE-ANALYSIS:{req_id}] SUSPICIOUS: Gemini returned 0 calories for: {zero_cal_items}")

            # Enhance food items with USDA per-100g data for accurate scaling
            if result and result.get('food_items'):
                try:
                    enhanced_items = await self._enhance_food_items_with_nutrition_db(result['food_items'])
                    result['food_items'] = enhanced_items

                    # Recalculate totals based on enhanced items
                    total_calories = sum(item.get('calories', 0) or 0 for item in enhanced_items)
                    total_protein = sum(item.get('protein_g', 0) or 0 for item in enhanced_items)
                    total_carbs = sum(item.get('carbs_g', 0) or 0 for item in enhanced_items)
                    total_fat = sum(item.get('fat_g', 0) or 0 for item in enhanced_items)
                    total_fiber = sum(item.get('fiber_g', 0) or 0 for item in enhanced_items)

                    result['total_calories'] = total_calories
                    result['protein_g'] = round(total_protein, 1)
                    result['carbs_g'] = round(total_carbs, 1)
                    result['fat_g'] = round(total_fat, 1)
                    result['fiber_g'] = round(total_fiber, 1)

                    logger.info(f"[IMAGE-ANALYSIS:{req_id}] Nutrition DB enhanced {len(enhanced_items)} items | total_calories={total_calories}")

                    # Debug: Log values AFTER USDA enhancement
                    for idx, item in enumerate(enhanced_items):
                        logger.info(
                            f"[IMAGE-ANALYSIS:{req_id}] ENHANCED ITEM[{idx}] | "
                            f"name={item.get('name')} | "
                            f"calories={item.get('calories')} | "
                            f"protein_g={item.get('protein_g')} | "
                            f"weight_g={item.get('weight_g')} | "
                            f"usda_data={'YES' if item.get('usda_data') else 'NO'}"
                        )
                except Exception as e:
                    logger.warning(f"[IMAGE-ANALYSIS:{req_id}] USDA enhancement failed, using AI estimates | error={e}", exc_info=True)

            # Check if we got empty food items
            if not result.get('food_items'):
                logger.warning(f"[IMAGE-ANALYSIS:{req_id}] NO FOOD ITEMS detected in image (user-recoverable)")
                return {
                    "error": "Could not identify any food items in the image. Please try a clearer photo.",
                    "error_code": "NO_FOOD_DETECTED",
                    "error_details": "Gemini returned empty food_items array",
                    "request_id": req_id,
                }

            # Success - log final summary
            total_elapsed = time.time() - start_time
            logger.info(
                f"[IMAGE-ANALYSIS:{req_id}] SUCCESS | "
                f"items={len(result.get('food_items', []))} | "
                f"calories={result.get('total_calories', 0)} | "
                f"elapsed={total_elapsed:.2f}s"
            )

            # Add request_id to result for traceability
            result['request_id'] = req_id
            return result

        except Exception as e:
            elapsed = time.time() - start_time
            logger.error(
                f"[IMAGE-ANALYSIS:{req_id}] UNEXPECTED ERROR | "
                f"error_type={type(e).__name__} | "
                f"error={str(e)} | "
                f"elapsed={elapsed:.2f}s"
            , exc_info=True)
            logger.exception(f"[IMAGE-ANALYSIS:{req_id}] Full traceback:")
            return {
                "error": "An unexpected error occurred during image analysis. Please try again.",
                "error_code": "UNEXPECTED_ERROR",
                "error_details": f"{type(e).__name__}: {str(e)}",
                "request_id": req_id,
            }

    async def parse_food_description(
        self,
        description: str,
        user_goals: Optional[List[str]] = None,
        nutrition_targets: Optional[Dict] = None,
        rag_context: Optional[str] = None,
        mood_before: Optional[str] = None,
        meal_type: Optional[str] = None,
        user_id: Optional[str] = None,
        personal_history: Optional[List[Dict]] = None,
    ) -> Optional[Dict]:
        """
        Parse a text description of food and extract nutrition information with goal-based rankings.

        Args:
            description: Natural language description of food
                        (e.g., "2 eggs, toast with butter, and orange juice")
            user_goals: List of user fitness goals (e.g., ["build_muscle", "lose_weight"])
            nutrition_targets: Dict with daily_calorie_target, daily_protein_target_g, etc.
            rag_context: Optional RAG context from ChromaDB for personalized feedback

        Returns:
            Dictionary with food_items (with rankings), total_calories, macros, ai_suggestion, etc.
        """
        # Check food text cache first (same food description returns same analysis).
        # CORRECTNESS: cache key includes user_id because personal_history injects
        # per-user warnings into the response. Without user_id, user A's history
        # could leak into user B's re-log tip for the same food text.
        personal_history_key = ""
        if personal_history:
            try:
                personal_history_key = "|".join(
                    f"{h.get('food_name')}:{h.get('severity')}:{h.get('negative_mood_count')}"
                    for h in personal_history
                )
            except Exception:
                personal_history_key = "has_history"
        try:
            cache_key = _food_text_cache.make_key(
                "food_text",
                description.strip().lower(),
                user_goals,
                nutrition_targets,
                user_id or "anon",
                personal_history_key,
            )
            # Skip cache entirely when there's personal history — the note is
            # user-specific AND mood_before-specific, and we'd rather re-run than
            # risk a stale miss-attribution.
            if not personal_history_key:
                cached_result = await _food_text_cache.get(cache_key)
                if cached_result is not None:
                    logger.info(f"[FoodTextCache] Cache HIT for: '{description[:60]}...'")
                    return cached_result
        except Exception as cache_err:
            logger.warning(f"[FoodTextCache] Cache lookup error (falling through): {cache_err}", exc_info=True)

        # Build user context section for goal-based scoring
        user_context = ""
        if user_goals or nutrition_targets:
            user_context = "\nUSER FITNESS CONTEXT:\n"
            if user_goals:
                user_context += f"- Fitness Goals: {safe_join_list(user_goals, 'General fitness')}\n"
            if nutrition_targets:
                if nutrition_targets.get('daily_calorie_target'):
                    user_context += f"- Daily Calorie Target: {nutrition_targets['daily_calorie_target']} kcal\n"
                if nutrition_targets.get('daily_protein_target_g'):
                    user_context += f"- Daily Protein Target: {nutrition_targets['daily_protein_target_g']}g\n"
                if nutrition_targets.get('daily_carbs_target_g'):
                    user_context += f"- Daily Carbs Target: {nutrition_targets['daily_carbs_target_g']}g\n"
                if nutrition_targets.get('daily_fat_target_g'):
                    user_context += f"- Daily Fat Target: {nutrition_targets['daily_fat_target_g']}g\n"

        # Add RAG context if available
        rag_section = ""
        if rag_context:
            rag_section = f"\nNUTRITION KNOWLEDGE CONTEXT:\n{rag_context}\n"

        # Personal history: prior logs of the same food with mood/energy data.
        # Gemini must acknowledge this pattern in warnings + recommended_swap,
        # and set `personal_history_note` so the UI can render a dedicated pill.
        personal_history_section = ""
        if personal_history:
            lines = []
            for h in personal_history:
                severity = (h.get("severity") or "").lower()
                if severity not in ("strong", "moderate"):
                    continue
                food = h.get("food_name") or "this food"
                total = h.get("logs") or 0
                confirmed = h.get("confirmed_count") or 0
                inferred = h.get("inferred_count") or 0
                negative = h.get("negative_mood_count") or 0
                symptom = h.get("dominant_symptom") or "off"
                avg_energy = h.get("avg_energy")
                conf_note = (
                    f"{confirmed} user-reported"
                    if not inferred
                    else f"{confirmed} reported + {inferred} AI-inferred"
                )
                energy_note = (
                    f", avg energy {avg_energy:.1f}/5"
                    if isinstance(avg_energy, (int, float))
                    else ""
                )
                lines.append(
                    f"- '{food}': logged {total}x in last 90d ({conf_note}); "
                    f"user felt {symptom} {negative} of {total} times{energy_note}. "
                    f"Severity: {severity}."
                )
            if lines:
                personal_history_section = (
                    "\nUSER'S PERSONAL HISTORY WITH THESE FOODS (last 90 days):\n"
                    + "\n".join(lines)
                    + "\n"
                    "RULES for using this history:\n"
                    "1. Add a specific item to `warnings` citing the pattern — include the "
                    "numbers (e.g. '4 of 5 times you ate pasta you felt bloated').\n"
                    "2. `recommended_swap` MUST address the pattern directly.\n"
                    "3. Set `personal_history_note` to a short 1-sentence friendly callout "
                    "(e.g. 'Heads up — this one has left you feeling bloated most times').\n"
                    "4. Tone for 'moderate' severity: softer ('this one has sometimes left you…'). "
                    "Tone for 'strong': direct ('consistently leaves you…'). Never sarcastic.\n"
                )

        # Build scoring criteria based on goals - simplified for speed
        scoring_criteria = """
SCORING (1-10): Be strict. Restaurant/fast food: 4-6. Whole foods: 7-8. Score 9-10 is rare.
- Muscle goals: Need >25g protein for score >7
- Weight loss: Penalize >500 cal, need fiber for score >7
- Fried foods: -2 points. High sodium/sugar: -1 point each.

INFLAMMATION SCORE (1-10, 10 = most inflammatory):
1-2: Strongly anti-inflammatory (wild salmon, turmeric, berries, leafy greens, ginger tea, olive oil)
3-4: Mildly anti-inflammatory (most vegetables, whole grains, nuts, legumes, plain yogurt)
5: Neutral (plain eggs, plain rice, plain chicken breast, milk)
6-7: Mildly inflammatory (white bread, red meat, cheese, fried foods, butter)
8-9: Moderately inflammatory (processed meats, fast food, sugary drinks, packaged snacks, instant noodles)
10: Highly inflammatory (deep-fried ultra-processed combos, trans fat items, candy + soda meals)

ULTRA-PROCESSED (is_ultra_processed): true if food would be NOVA Group 4 — contains industrial additives like emulsifiers, hydrogenated oils, artificial sweeteners, protein isolates, modified starches, high-fructose corn syrup. Examples: Coca-Cola=true, instant noodles=true, grilled chicken=false, homemade samosa=false.

Per-item inflammation_score: Rate EACH food item individually. Meal-level inflammation_score: Calorie-weighted average of all items (round to nearest int)."""

        # Response format with micronutrients for complete nutrient tracking
        # Added count, weight_per_unit_g for countable items, and unit for measurement type
        if user_goals or nutrition_targets:
            response_format = '''{{
  "food_items": [
    {{"name": "Food name", "amount": "portion", "calories": 150, "protein_g": 10, "carbs_g": 15, "fat_g": 5, "fiber_g": 2, "goal_score": 7, "weight_g": 100, "unit": "g", "count": null, "weight_per_unit_g": null, "inflammation_score": 5, "is_ultra_processed": false}}
  ],
  "total_calories": 450,
  "protein_g": 25,
  "carbs_g": 40,
  "fat_g": 15,
  "fiber_g": 5,
  "sugar_g": 8,
  "sodium_mg": 500,
  "cholesterol_mg": 50,
  "vitamin_a_ug": 150,
  "vitamin_c_mg": 10,
  "vitamin_d_iu": 40,
  "calcium_mg": 100,
  "iron_mg": 2,
  "potassium_mg": 300,
  "inflammation_score": 5,
  "is_ultra_processed": false,
  "corrected_query": "Corrected food description or null if no typos",
  "overall_meal_score": 7,
  "encouragements": ["What's good about this meal for their goals"],
  "warnings": ["Any concerns - skip if none"],
  "ai_suggestion": "Next time: specific actionable tip",
  "recommended_swap": "Healthier alternative if applicable",
  "personal_history_note": "Short friendly callout when user has prior history with this food — else null"
}}'''
        else:
            response_format = '''{{
  "food_items": [
    {{"name": "Food name", "amount": "portion", "calories": 150, "protein_g": 10, "carbs_g": 15, "fat_g": 5, "fiber_g": 2, "weight_g": 100, "unit": "g", "count": null, "weight_per_unit_g": null, "inflammation_score": 5, "is_ultra_processed": false}}
  ],
  "total_calories": 450,
  "protein_g": 25,
  "carbs_g": 40,
  "fat_g": 15,
  "fiber_g": 5,
  "sugar_g": 8,
  "sodium_mg": 500,
  "cholesterol_mg": 50,
  "vitamin_a_ug": 150,
  "vitamin_c_mg": 10,
  "vitamin_d_iu": 40,
  "calcium_mg": 100,
  "iron_mg": 2,
  "potassium_mg": 300,
  "inflammation_score": 5,
  "is_ultra_processed": false,
  "corrected_query": "Corrected food description or null if no typos",
  "encouragements": ["What's good about this meal"],
  "warnings": ["Any concerns - skip if none"],
  "ai_suggestion": "Next time: specific actionable tip",
  "recommended_swap": "Healthier alternative if applicable",
  "personal_history_note": "Short friendly callout when user has prior history with this food — else null"
}}'''

        # Build actionable tip guidance based on user goals
        tip_guidance = ""
        if user_goals or nutrition_targets:
            mood_context = ""
            if mood_before:
                mood_context = f"\n- User's current mood/state: {mood_before}. Factor this into your tips — if bloated, don't suggest intense exercise; if tired, note energy impact; if hungry, acknowledge satiety."
            meal_type_context = ""
            if meal_type:
                meal_type_context = f"\n- This is the user's {meal_type}. Tailor tip to meal timing (breakfast = energy for the day, dinner = avoid heavy foods before sleep, snack = portion awareness)."
            tip_guidance = f"""
COACH TIP STRUCTURE - ALWAYS use ALL relevant fields:
- encouragements: 1-2 short points on what's genuinely GOOD (e.g., "Good protein from chicken for muscle building")
- warnings: ALWAYS include for scores 1-7. Point out what needs improvement: high sodium, excess calories, low fiber, too much saturated fat, missing nutrients, large portions, etc. Be specific with numbers (e.g., "High sodium (~1400mg) - over half daily limit", "Low fiber at ~4g - aim for 8g+ per meal"). Do NOT skip warnings for 6-7 scores.
- ai_suggestion: Start with "Next time:" then give ONE specific actionable tip (e.g., "Next time: Ask for half rice to cut 100 cal and 20g carbs")
- recommended_swap: ALWAYS include for scores 1-7. Give a concrete swap with the benefit (e.g., "Swap white rice for brown rice: +3g fiber, lower glycemic index", "Skip cheese and add fajita veggies: save 110 cal, add vitamins"){mood_context}{meal_type_context}

SCORE-BASED TIP TONE:
- Score 1-3: Be direct about poor nutrition. Focus on healthier alternatives. Do NOT spin positively.
- Score 4-5: Acknowledge what it provides but emphasize better alternatives and portion control.
- Score 6-7: Balanced tone — briefly note what's good, then lead with a concrete improvement. Do NOT be overly enthusiastic. A 6/10 meal is average, not great. Example: "Good protein from chicken. Swap white rice for brown rice and skip the cheese to cut 150 cal and add fiber."
- Score 8-10: Reinforce positive behavior and explain specific health benefits."""

        prompt = f'''Parse food and return nutrition JSON. Be fast and accurate.

Food: "{description}"
{user_context}{rag_section}{personal_history_section}{scoring_criteria if user_goals else ""}{tip_guidance}

Return ONLY JSON (no markdown):
{response_format}

FOOD NAMING RULES (CRITICAL — lookup accuracy depends on this):
- Preserve EVERY qualifier word the user wrote (ingredient, protein, cuisine, brand, modifier).
- NEVER canonicalize to a shorter or more generic name. The DB has distinct rows
  for specific variants with very different macros — stripping a qualifier yields
  the wrong row.
- Examples of WRONG vs RIGHT extraction:
  - Input "paneer masala dosa" → WRONG "Masala Dosa" · RIGHT "Paneer Masala Dosa"
  - Input "chicken tikka masala" → WRONG "Tikka Masala" · RIGHT "Chicken Tikka Masala"
  - Input "thai green curry" → WRONG "Green Curry" · RIGHT "Thai Green Curry"
  - Input "chocolate milk" → WRONG "Milk" · RIGHT "Chocolate Milk" (and never "Milk Chocolate" — word order matters)
  - Input "egg fried rice" → WRONG "Fried Rice" · RIGHT "Egg Fried Rice"
  - Input "paneer butter masala" → WRONG "Butter Masala" or "Paneer" · RIGHT "Paneer Butter Masala"
- If the user likely made a typo (e.g. "paner"), correct it to the canonical spelling
  ("paneer") in corrected_query but KEEP the full multi-word name in food_items[].name.
- Only drop personal descriptors that never change nutrition (my favorite, best ever).
- KEEP sensory/taste words (spicy, mild, sweet, sour, plain, bitter) — they often identify
  distinct products (Spicy McChicken ≠ McChicken, Sweet Potato ≠ Potato, Plain Yogurt ≠ Yogurt).
- COMMA IS AN UNBREAKABLE ITEM BOUNDARY: "X, Y" is ALWAYS two separate items, even
  when "X Y" (or "Y X") happens to spell a popular dish. Never fuse adjacent
  comma-separated words into a compound dish name. Examples of what NOT to do:
  - "chicken fry, rice" is two items (Chicken Fry + Rice), NOT "Chicken Fried Rice"
  - "egg, fried rice" is two items (Egg + Fried Rice), NOT "Egg Fried Rice"
  - "sweet, sour pork" is two items, NOT "Sweet and Sour Pork"

CRITICAL PORTION SIZE RULES:
- HIGHEST PRIORITY: If user specifies an EXACT quantity (e.g., "500g rice", "300ml milk", "2 cups oats", "750g chicken"), ALWAYS use that exact quantity. User-specified amounts override ALL defaults below. Never reduce or round user-specified quantities.
- If no size/portion specified, ALWAYS assume MEDIUM/REGULAR serving (not large)
- For restaurant foods without size: use their "regular" or "medium" option
- For packaged foods: use single serving from nutrition label
- For homemade: use standard single serving
- Movie popcorn (AMC/Regal/etc) without size = medium (~600-730 cal with butter, NOT large 1000+)
- Coffee drinks without size = medium (16oz)
- "Diet", "Zero Sugar", "Sugar-Free" beverages (Diet Coke, Coke Zero, Diet Pepsi, etc.) = ALWAYS 0 calories, 0 protein, 0 carbs, 0 fat. Do NOT estimate non-zero values.
- Fast food without size = regular/medium combo
- Pizza without count = assume 2 slices

PORTION SIZE KEYWORDS — when these modify the food (no explicit weight given):
- "side of [food]" / "a side of [food]" (standalone, NOT within a composite meal): SIDE PORTION — 30-35% of regular serving
  - "side of chicken al pastor from chipotle" → ~110-120g (~210-250 cal), NOT a full 300g+ serving
  - "side of rice" → ~75-85g (~100 cal), "side of fries" → ~80g (~130 cal), "side of guacamole" → ~40g (~60 cal)
  - NOTE: "bowl with a side of chips" is different — that's a SEPARATE ITEM signal (see KEEP SEPARATE rules below)
- "kids [food]" / "kid's [food]" / "children's [food]": ~50% of regular adult serving
- "appetizer portion" / "starter portion": ~40% of entrée size
- "personal [food]" (e.g., personal pizza): ~50% of regular
- "junior [food]" / "jr [food]": ~60% of regular
- "petite [food]": ~50% of regular
- "mini [food]": ~50% of regular
- "fun size [food]": ~30% of regular (candy bars)
- "snack size [food]": ~40% of regular
- "king size [food]": ~200% of regular (candy bars)
- "family size [food]": ~350% of regular
- "shared [food]" / "split [food]": ~50% (split between two)
- "a bite of [food]" / "just a bite": ~10% of regular
- "a taste of [food]": ~10% of regular
- "a little [food]" / "just a little": ~30% of regular

FIXED-WEIGHT DESCRIPTORS — these specify a fixed amount regardless of food:
- "a sprinkle of [food]" / "sprinkled with [food]": ~4g
- "a drizzle of [food]" / "drizzled with [food]": ~8g
- "a dollop of [food]": ~15g
- "a splash of [food]": ~15ml
- "a pinch of [food]": ~1g
- "a dash of [food]": ~1g
- "a touch of [food]": ~4g
- "a hint of [food]": ~2g
- "a dusting of [food]": ~3g
- "a squirt of [food]": ~8g (condiment/sauce)
- "a squeeze of [food]": ~8g (lemon, sauce)
- "a smear of [food]": ~12g (cream cheese, butter)
- "a swirl of [food]": ~12g (sauce, cream)
- "a glob of [food]": ~25g

VAGUE QUANTITY LANGUAGE:
- "some [food]" (standalone, no verb prefix): Moderate/regular serving — do NOT increase or decrease
- "just some [food]" / "only some [food]": ~50% of regular serving
- "some of the [food]" / "some of [food]": ~50% of regular (partial)
- "a little [food]" / "a little bit of [food]": ~30% of regular
- "a bit of [food]": ~35% of regular
- "a lot of [food]" / "lots of [food]" / "plenty of [food]": ~150% of regular
- "a ton of [food]" / "tons of [food]": ~200% of regular
- "a bunch of [food]": ~150% of regular
- "hardly any [food]" / "barely any [food]": ~10% of regular
- "not much [food]": ~40% of regular
- "a few [food]": 3-4 pieces/items of that food
- "several [food]": 4-5 pieces/items

COUNTABLE ITEMS - Discrete pieces you pick up and eat individually (NOT by weight):
- ALWAYS include "count" (number of pieces) and "weight_per_unit_g" (weight of ONE piece)
- Breads: naan(~90g), roti/chapati(~45g), paratha(~80g), puri(~25g), bhatura(~60g), dosa(~120g), appam(~50g), idli(~40g), bread slice(~30g), tortilla(~35g), pita(~60g)
- Indian snacks: samosa(~80g), pakora(~45g), vada(~40g), bonda(~35g), bajji(~40g), cutlet(~60g), paneer tikka piece(~30g), chicken tikka piece(~35g), seekh kebab(~50g), shami kebab(~60g), chicken 65 piece(~25g), gobi manchurian piece(~25g), spring roll(~50g), kachori(~50g), aloo tikki(~60g), dhokla piece(~30g), momos(~30g)
- Western: french fry(~8g), chip(~2g), tater tot(~10g), nugget(~18g), meatball(~30g), falafel(~17g), wing(~85g), sushi(~35g), pizza slice(~100g), taco(~80g), egg(~50g), cookie(~15g), donut(~60g), sausage(~45g), wonton(~15g), gyoza(~25g), tempura(~30g), empanada(~80g)
- Sweets: laddoo(~40g), gulab jamun(~40g), rasgulla(~40g), barfi(~30g), peda(~20g), jalebi piece(~25g)
- weight_g = count × weight_per_unit_g
- If user mentions count (e.g., "18 tater tots"), use that count
- If user just says "tater tots" without count, estimate reasonable serving (e.g., 10-12 pieces)
- For "small fries"/"medium fries"/"large fries", estimate individual fry sticks (small≈40, medium≈55, large≈70) at ~8g each
- NOT COUNTABLE (use count=null, weight_per_unit_g=null): curry, dal, rice, biryani, pulao, soup, salad, pasta, noodles, oatmeal, yogurt, ice cream, halwa, kheer, chutney, sauce
- IMPORTANT "fry" dishes (chicken fry, fish fry, prawn fry, bhindi fry, aloo fry, gobi fry) are Indian DRY PREPARATIONS served as a portion — NOT countable individual pieces. Use count=null, weight_per_unit_g=null for these.

MEASUREMENT UNITS - Use "unit" field to specify the most natural unit:
- "g" = grams (default for solid foods: chicken, rice, bread)
- "ml" = milliliters (liquids: shakes, smoothies, milk, juice, soup)
- "oz" = fluid ounces (US drinks: coffee, soda)
- "cups" = cups (cooking: "2 cups of strawberry milkshake")
- "tsp" = teaspoons (small amounts: sugar, oil)
- "tbsp" = tablespoons (sauces, dressings, peanut butter)
- For liquids, weight_g should be the ml equivalent (1ml ≈ 1g for water-based drinks)
- Examples: protein shake → unit: "ml", 2 cups milkshake → unit: "cups", 1 tbsp peanut butter → unit: "tbsp"

Rules: Use USDA data. Sum totals from items. Account for prep methods (fried adds fat).

SPELLING CORRECTION - Detect and correct misspelled food names:
- If the user misspells a food/brand name, correct it and use the CORRECT name for nutrition lookup
- Set "corrected_query" to the corrected version of the FULL input (e.g., "mchiken wrap" → "McChicken Wrap")
- Use the CORRECT food's nutrition data, not a random similar food
- Common fast food misspellings: mchiken/mchicken → McChicken, mcflury → McFlurry, bic mac → Big Mac, whooper → Whopper, chik fil a → Chick-fil-A, subwey → Subway, etc.
- If no misspellings detected, set "corrected_query" to null
- The "name" field in food_items should always use the CORRECT spelling

COMPOSITE MEAL RULE - CRITICAL:
When user describes a NAMED composite meal (bowl, burrito, wrap, plate, combo, sandwich, sub, taco, pizza, ramen, poke bowl, shake, smoothie, thali, bento, bibimbap) with its toppings/ingredients, return ONLY the individual ingredients as separate food items — each with its own weight and nutrition. Do NOT add a redundant wrapper item for the whole meal.

RETURN INDIVIDUAL INGREDIENTS (not one combined item) — so users can edit each:
- "Chipotle bowl with chicken, rice, beans, salsa, cheese, guac" → 6 items: "Grilled Chicken" (200g), "White Rice" (150g), "Black Beans" (80g), "Corn Salsa" (100g), "Shredded Cheese" (30g), "Guacamole" (50g). Use restaurant-appropriate portion sizes.
- "Subway turkey sub with lettuce, tomato, mayo" → items: "Sub Roll" (90g), "Turkey Breast" (115g), "Lettuce" (30g), "Tomato" (30g), "Mayonnaise" (15g)
- "Poke bowl with tuna, rice, edamame, seaweed" → items: "Ahi Tuna" (120g), "Sushi Rice" (200g), "Edamame" (50g), "Seaweed Salad" (30g)
- "acai bowl topped with granola, banana, and honey" → items: "Acai Blend" (200g), "Granola" (40g), "Banana" (60g), "Honey" (15g)
- "thali with dal, rice, roti, sabzi" → items: "Dal" (150g), "Steamed Rice" (150g), "Roti" (60g), "Mixed Vegetable Sabzi" (100g)
- "bento box with salmon, rice, edamame" → items: "Grilled Salmon" (120g), "Japanese Rice" (150g), "Edamame" (50g)
- "Thanksgiving plate with turkey, mashed potatoes, stuffing, gravy" → items: "Roasted Turkey" (150g), "Mashed Potatoes" (150g), "Stuffing" (100g), "Turkey Gravy" (60g)

ALL input patterns mean the same thing — return individual ingredients:
- "with": "bowl with chicken, rice, beans"
- "and" (no "with"): "bowl chicken and rice and beans"
- Comma-only: "bowl, chicken, rice, beans"
- No separator: "chicken burrito bowl rice beans cheese"
- "on": "burger on brioche bun with lettuce"
- "over": "grilled chicken over rice with veggies"
- "in": "soup in bread bowl with crackers"
- "topped with": "acai bowl topped with granola, banana"
- "add": "bowl add chicken add guac"
- Parenthetical: "bowl (chicken, rice, beans)"
- "extra"/"no": "bowl with chicken, extra cheese, no beans" → include extra cheese (larger portion), exclude beans entirely
- Size: "large bowl with double chicken" → double the chicken portion

DO NOT add a wrapper item like "Chipotle Chicken Burrito Bowl" alongside the ingredients — that double-counts calories.

KEEP SEPARATE — these signal a separate dish alongside the composite:
- "and a [different dish]": "Chipotle bowl with chicken and a cookie" → bowl ingredients + "Cookie" as separate item
- "and [ice cream/dessert/drink]": "Chipotle bowl with chicken and ice cream" → bowl ingredients + "Ice Cream"
- "plus": "burrito bowl plus chips and salsa" → bowl ingredients + "Chips and Salsa"
- "side of" (WITH a base composite like bowl/burrito/plate): "Chipotle bowl with a side of chips" → bowl ingredients + "Tortilla Chips"
  IMPORTANT: "side of [food]" WITHOUT a base composite (e.g., "side of chicken al pastor") is NOT a separate item — it means a SMALL SIDE PORTION (~30-35% of regular). See PORTION SIZE KEYWORDS above.
- "also"/"also got": "Chipotle bowl also got a drink" → bowl ingredients + the drink
- Multi-person: "Chipotle bowl for me, chicken tacos for my wife" → bowl ingredients + taco ingredients

NO COMPOSITE KEYWORD — list each item separately:
- "chicken, rice, and beans" → 3 items (no bowl/burrito/plate keyword)
- "steak and lobster" → 2 items (separate dishes)
- "bruschetta appetizer, filet mignon, caesar salad, tiramisu" → 4 items (multi-course)
- "chicken fry, dal, rice and curd" → 4 items: "Chicken Fry" (South Indian fried chicken), "Dal", "Steamed Rice", "Curd". NEVER return a single "Chicken Fried Rice" — that fuses comma-separated items into a hallucinated dish.
- "paneer fry, naan, raita" → 3 items: "Paneer Fry", "Naan", "Raita"
- "egg bhurji, roti, pickle" → 3 items (Indian breakfast, no composite keyword)
- "idli, sambar, chutney, filter coffee" → 4 items (South Indian breakfast, no thali keyword)

ABSURD/IMPOSSIBLE COMBOS — use culinary common sense:
- "ice cream topped with garlic chicken" → 2 items: "Ice Cream" + "Garlic Chicken" (garlic chicken is NOT an ice cream topping — these are separate foods)
- "coffee with steak" → 2 items (clearly separate)
- "pizza with chocolate sauce" → items of a dessert pizza if plausible; otherwise 2 separate items
- "waffle topped with chicken and syrup" → items: "Waffle", "Fried Chicken", "Maple Syrup" (chicken & waffles is a real dish)
- If the topping/ingredient would NEVER appear on that base food in any cuisine, treat as separate items.

"CONTAINER OF X" — NOT a composite meal:
- "bowl of ice cream" → 1 item: "Ice Cream" (bowl is a container, not a meal type)
- "plate of cookies" → 1 item: "Cookies"
- "cup of soup" → 1 item: "Soup"
- "glass of milk" → 1 item: "Milk"

AMBIGUOUS — use best judgment:
- "rice with curry" → 2 items: "Steamed Rice" + "Curry" (so user can adjust each)
- "eggs with toast and bacon" → 3 items (separate breakfast items)

NEVER double-count: do NOT add a wrapper/composite item AND also its ingredients.

INGREDIENT NAMING - CRITICAL:
- Use GENERIC names unless user specifies a brand: "black beans" → "Black Beans" (NOT "Taco Bell Black Beans")
- "guac"/"guacamole" → "Guacamole" (NOT "Avocado" — different food, different nutrition)
- "corn salsa" → "Corn Salsa" (NOT "Corn Salad")
- "cheese" on a bowl → "Shredded Cheese" or "Mexican Blend Cheese"
- Only use brand names if user explicitly says the brand

IMPORTANT - ALWAYS identify foods:
- For ANY food description, ALWAYS return valid food items with estimated nutrition
- If you don't recognize the exact item (e.g., "Cinnamon Delights from Taco Bell"), estimate based on similar foods (e.g., fried dough with cinnamon sugar)
- Fast food items without exact data: estimate based on ingredients and similar menu items
- NEVER return empty food_items - always make your best estimate

RESTAURANT/LOCATION QUALIFIERS — DO NOT create food items from restaurant names:
- When input ends with (or contains "from"/"at") a restaurant name, that name is LOCATION CONTEXT
- Use the restaurant name ONLY to inform portion sizes and menu accuracy — do NOT generate a separate food item from it
- The restaurant name tells you WHERE the food is from, not WHAT food to add
- Examples:
  - "mexican coke chipotle" → 1 item: "Mexican Coke" (chipotle = restaurant, NOT a burrito bowl)
  - "coke zero taco bell" → 1 item: "Coke Zero" (taco bell = restaurant context)
  - "chicken nuggets mcdonalds" → 1 item: "Chicken McNuggets" (use McDonald's 10-piece portion)
  - "iced coffee dunkin" → 1 item: "Iced Coffee" (Dunkin' medium portion)
  - "fries and a coke burger king" → 2 items: "French Fries" + "Coca-Cola" (BK portions)
  - "side of chips chipotle" → 1 item: "Tortilla Chips" (Chipotle side portion)
  - "latte from starbucks" → 1 item: "Latte" (Starbucks grande)
  - "wings at wingstop" → 1 item: "Chicken Wings" (Wingstop portion)
  - "pizza pizza hut" → 1 item: "Pizza" (Pizza Hut medium, 2 slices)
  - "coke from chipotle and a burrito" → 2 items: "Mexican Coke" + "Burrito" (both Chipotle portions)
- DISTINGUISH from chipotle the INGREDIENT/FLAVOR:
  - "chipotle chicken sandwich" → 1 item (chipotle-FLAVORED chicken sandwich — chipotle is an adjective describing the food)
  - "chipotle mayo" → 1 item (the condiment made with chipotle peppers)
  - "chipotle sauce" → 1 item (the sauce)
  - "chicken with chipotle" → 1 item (chicken with chipotle sauce/peppers as ingredient)
  - "chicken chipotle" → ambiguous — if no other context, interpret as "chicken from Chipotle" (1 item: Chicken)
- HOW TO TELL: If removing the restaurant name leaves a complete food description, it is location context. If removing it changes the food itself, it is an ingredient/flavor.'''

        # Timeout for food analysis
        FOOD_ANALYSIS_TIMEOUT = 25
        last_error = None
        content = ""

        try:
            logger.info(f"[Gemini] Parsing food description: {description[:100]}...")

            response = await gemini_generate_with_retry(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=FoodAnalysisResponse,
                    max_output_tokens=8192,  # High limit to prevent truncation (MAX_TOKENS causes parsed=None)
                    temperature=0.2,  # Lower = faster, more deterministic
                ),
                user_id=user_id,
                max_retries=2,
                timeout=FOOD_ANALYSIS_TIMEOUT,
                method_name="parse_food_description",
            )

            # Use response.parsed for structured output - SDK handles JSON parsing
            parsed = response.parsed
            result = None

            if parsed:
                result = parsed.model_dump()
            else:
                # Log details about why structured parsing failed
                logger.warning(f"[Gemini] Structured parsing returned None")
                raw_text = response.text if response.text else ""
                logger.info(f"[Gemini] Raw response text: {raw_text[:500] if raw_text else 'None'}")

                # Check for safety/blocking issues
                if hasattr(response, 'candidates') and response.candidates:
                    for i, candidate in enumerate(response.candidates):
                        if hasattr(candidate, 'finish_reason'):
                            logger.info(f"[Gemini] Candidate {i} finish_reason: {candidate.finish_reason}")
                        if hasattr(candidate, 'safety_ratings'):
                            logger.info(f"[Gemini] Candidate {i} safety_ratings: {candidate.safety_ratings}")

                # Try to parse raw text as JSON fallback
                if raw_text:
                    logger.info(f"[Gemini] Attempting fallback JSON parsing from raw text...")
                    result = self._extract_json_robust(raw_text)
                    if result:
                        logger.info(f"[Gemini] Fallback JSON parsing succeeded")
                    else:
                        logger.warning(f"[Gemini] Fallback JSON parsing also failed")

            if result and result.get('food_items'):
                logger.info(f"[Gemini] Parsed {len(result.get('food_items', []))} food items")

                # Enhance food items with USDA per-100g data for accurate scaling
                try:
                    enhanced_items = await self._enhance_food_items_with_nutrition_db(result['food_items'])
                    result['food_items'] = enhanced_items

                    # Recalculate totals based on enhanced items
                    total_calories = sum(item.get('calories', 0) or 0 for item in enhanced_items)
                    total_protein = sum(item.get('protein_g', 0) or 0 for item in enhanced_items)
                    total_carbs = sum(item.get('carbs_g', 0) or 0 for item in enhanced_items)
                    total_fat = sum(item.get('fat_g', 0) or 0 for item in enhanced_items)
                    total_fiber = sum(item.get('fiber_g', 0) or 0 for item in enhanced_items)

                    result['total_calories'] = total_calories
                    result['protein_g'] = round(total_protein, 1)
                    result['carbs_g'] = round(total_carbs, 1)
                    result['fat_g'] = round(total_fat, 1)
                    result['fiber_g'] = round(total_fiber, 1)

                    logger.info(f"[NutritionDB] Enhanced {len(enhanced_items)} items, total: {total_calories} cal")
                except Exception as e:
                    logger.warning(f"Nutrition DB enhancement failed, using AI estimates: {e}", exc_info=True)
                    # Continue with original AI estimates if enhancement fails

                # Cache the successful result
                try:
                    await _food_text_cache.set(cache_key, result)
                    logger.info(f"[FoodTextCache] Cache MISS - stored result for: '{description[:60]}...'")
                except Exception as cache_err:
                    logger.warning(f"[FoodTextCache] Failed to store result: {cache_err}", exc_info=True)

                return result

            # Structured output succeeded but no food_items - try unstructured fallback
            logger.warning(f"[Gemini] Structured output returned no food_items. Trying unstructured fallback...")

        except Exception as e:
            logger.warning(f"[Gemini] Food description parsing failed: {e}", exc_info=True)
            last_error = str(e)

        # Fallback: try without response_schema - just ask for JSON
        try:
            fallback_response = await gemini_generate_with_retry(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    max_output_tokens=4096,
                    temperature=0.2,
                ),
                user_id=user_id,
                timeout=FOOD_ANALYSIS_TIMEOUT + 15,
                method_name="parse_food_description_fallback",
            )

            if fallback_response.text:
                logger.info(f"[Gemini] Unstructured fallback response: {fallback_response.text[:500]}")
                result = self._extract_json_robust(fallback_response.text)
                if result and result.get('food_items'):
                    logger.info(f"[Gemini] Unstructured fallback succeeded with {len(result['food_items'])} items")

                    # Enhance with USDA data
                    try:
                        enhanced_items = await self._enhance_food_items_with_nutrition_db(result['food_items'])
                        result['food_items'] = enhanced_items
                        result['total_calories'] = sum(item.get('calories', 0) or 0 for item in enhanced_items)
                        result['protein_g'] = round(sum(item.get('protein_g', 0) or 0 for item in enhanced_items), 1)
                        result['carbs_g'] = round(sum(item.get('carbs_g', 0) or 0 for item in enhanced_items), 1)
                        result['fat_g'] = round(sum(item.get('fat_g', 0) or 0 for item in enhanced_items), 1)
                        result['fiber_g'] = round(sum(item.get('fiber_g', 0) or 0 for item in enhanced_items), 1)
                    except Exception as e:
                        logger.warning(f"Nutrition DB enhancement failed in fallback: {e}", exc_info=True)

                    # Cache the fallback result too
                    try:
                        await _food_text_cache.set(cache_key, result)
                        logger.info(f"[FoodTextCache] Cache MISS (fallback) - stored result for: '{description[:60]}...'")
                    except Exception as cache_err:
                        logger.warning(f"[FoodTextCache] Failed to store fallback result: {cache_err}", exc_info=True)

                    return result
        except Exception as e:
            logger.error(f"[Gemini] Unstructured fallback also failed: {e}", exc_info=True)

        logger.error(f"[Gemini] All attempts + fallback failed. Last error: {last_error}")
        logger.error(f"[Gemini] Last content was: {content[:500] if content else 'empty'}")
        return None

    def _extract_json_robust(self, content: str) -> Optional[Dict]:
        """
        Robustly extract and parse JSON from Gemini response.

        Uses the centralized AI response parser for general JSON parsing,
        with food-specific regex extraction as a specialized fallback.
        """
        import re

        if not content:
            return None

        original_content = content

        # Step 1: Use the centralized AI response parser
        # This handles: markdown extraction, boundary detection, trailing commas,
        # control characters, truncation repair, and AST fallback
        parse_result = parse_ai_json(content, context="gemini_service")

        if parse_result.success:
            if parse_result.was_repaired:
                logger.info(f"[Gemini] JSON repaired using {parse_result.strategy_used.value}: {parse_result.repair_steps}")
            return parse_result.data

        # Step 2: Food-specific regex extraction as specialized fallback
        # This handles truncated food analysis responses that the general parser can't recover
        logger.warning(f"[Gemini] Central parser failed, attempting food-specific regex recovery...")

        try:
            # Try to extract food_items array - handle both complete and truncated responses
            # First try complete array with closing bracket
            food_items_match = re.search(r'"food_items"\s*:\s*\[(.*?)\]', content, re.DOTALL)
            if not food_items_match:
                # Try to find truncated food_items array (no closing bracket)
                food_items_start = re.search(r'"food_items"\s*:\s*\[', content)
                if food_items_start:
                    items_str = content[food_items_start.end():]
                    logger.info(f"[Gemini] Found truncated food_items array, attempting recovery...")
                else:
                    items_str = None
            else:
                items_str = food_items_match.group(1)

            if items_str:
                # Extract individual food objects - look for complete objects with required fields
                food_objects = []
                # Match complete objects that have at minimum: name, calories, amount
                obj_pattern = r'\{\s*"name"\s*:\s*"[^"]+"\s*,\s*"amount"\s*:\s*"[^"]+"\s*,\s*"calories"\s*:\s*\d+[^{}]*\}'
                for obj_match in re.finditer(obj_pattern, items_str):
                    try:
                        obj = json.loads(obj_match.group())
                        food_objects.append(obj)
                    except json.JSONDecodeError:
                        # Try to fix the individual object
                        obj_str = obj_match.group()
                        obj_str = re.sub(r',\s*([}\]])', r'\1', obj_str)
                        try:
                            obj = json.loads(obj_str)
                            food_objects.append(obj)
                        except Exception as e:
                            logger.debug(f"Failed to parse food object: {e}")

                # If structured pattern failed, try simpler pattern for complete objects
                if not food_objects:
                    logger.info(f"[Gemini] Trying simple pattern for complete objects...")
                    simple_pattern = r'\{[^{}]+\}'
                    for obj_match in re.finditer(simple_pattern, items_str):
                        try:
                            obj = json.loads(obj_match.group())
                            if 'name' in obj and 'calories' in obj:
                                food_objects.append(obj)
                                logger.info(f"[Gemini] Simple pattern matched: {obj.get('name')}")
                        except json.JSONDecodeError:
                            obj_str = obj_match.group()
                            obj_str = re.sub(r',\s*([}\]])', r'\1', obj_str)
                            try:
                                obj = json.loads(obj_str)
                                if 'name' in obj and 'calories' in obj:
                                    food_objects.append(obj)
                                    logger.info(f"[Gemini] Simple pattern (fixed) matched: {obj.get('name')}")
                            except Exception as e:
                                logger.debug(f"Failed to parse fixed food obj: {e}")

                # Try to recover truncated objects by extracting key-value pairs
                if not food_objects:
                    logger.info(f"[Gemini] Attempting field-by-field recovery for truncated objects...")
                    # Find all objects that start but may not end
                    obj_starts = list(re.finditer(r'\{', items_str))
                    for i, start_match in enumerate(obj_starts):
                        start_pos = start_match.start()
                        # Find the next object start or end of string
                        if i + 1 < len(obj_starts):
                            end_pos = obj_starts[i + 1].start()
                        else:
                            end_pos = len(items_str)

                        obj_str = items_str[start_pos:end_pos]

                        # Extract fields using regex - flexible order
                        name_match = re.search(r'"name"\s*:\s*"([^"]+)"', obj_str)
                        amount_match = re.search(r'"amount"\s*:\s*"([^"]+)"', obj_str)
                        calories_match = re.search(r'"calories"\s*:\s*(\d+(?:\.\d+)?)', obj_str)
                        protein_match = re.search(r'"protein_g"\s*:\s*(\d+(?:\.\d+)?)', obj_str)
                        carbs_match = re.search(r'"carbs_g"\s*:\s*(\d+(?:\.\d+)?)', obj_str)
                        fat_match = re.search(r'"fat_g"\s*:\s*(\d+(?:\.\d+)?)', obj_str)
                        fiber_match = re.search(r'"fiber_g"\s*:\s*(\d+(?:\.\d+)?)', obj_str)

                        # Must have at least name and calories
                        if name_match and calories_match:
                            recovered_obj = {
                                "name": name_match.group(1),
                                "amount": amount_match.group(1) if amount_match else "1 serving",
                                "calories": float(calories_match.group(1)),
                                "protein_g": float(protein_match.group(1)) if protein_match else 0,
                                "carbs_g": float(carbs_match.group(1)) if carbs_match else 0,
                                "fat_g": float(fat_match.group(1)) if fat_match else 0,
                                "fiber_g": float(fiber_match.group(1)) if fiber_match else 0,
                            }
                            food_objects.append(recovered_obj)
                            logger.info(f"[Gemini] Recovered truncated item: {recovered_obj['name']}")

                if food_objects:
                    # Calculate totals from individual items
                    total_calories = sum(item.get('calories', 0) for item in food_objects)
                    total_protein = sum(item.get('protein_g', 0) for item in food_objects)
                    total_carbs = sum(item.get('carbs_g', 0) for item in food_objects)
                    total_fat = sum(item.get('fat_g', 0) for item in food_objects)
                    total_fiber = sum(item.get('fiber_g', 0) for item in food_objects)

                    recovered_result = {
                        "food_items": food_objects,
                        "total_calories": total_calories,
                        "protein_g": total_protein,
                        "carbs_g": total_carbs,
                        "fat_g": total_fat,
                        "fiber_g": total_fiber,
                        "health_score": 5,  # Default neutral score
                        "ai_suggestion": f"Logged {len(food_objects)} item(s): ~{total_calories} cal, {total_protein}g protein. Values are estimates - adjust if needed."
                    }
                    logger.info(f"[Gemini] Recovered {len(food_objects)} food items via regex extraction")
                    return recovered_result
        except Exception as e:
            logger.warning(f"[Gemini] Food-specific regex recovery failed: {e}", exc_info=True)

        logger.error(f"[Gemini] All JSON parsing attempts failed. Content preview: {original_content[:200]}")
        return None
