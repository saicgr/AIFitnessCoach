"""
Vision Service for analyzing food images using Gemini Vision.

This service handles:
- Food image analysis for nutrition estimation
- Multi-image food analysis (plates, buffets, menus)
- Auto-detection of meal type based on time of day
- JSON-formatted nutrition responses
"""

from __future__ import annotations

import asyncio
import json
import base64
from datetime import datetime
from typing import Optional
from google.genai import types

import boto3

from core.config import get_settings
from core.logger import get_logger
from models.gemini_schemas import (
    BuffetAnalysisResponse,
    FoodAnalysisResponse,
    MenuAnalysisResponse,
    Stage1CompoundComponent,
    Stage1CompoundDecompose,
    Stage1Dish,
    Stage1DishIdentification,
    Stage1MenuIdentification,
    Stage1MenuItem,
)
from typing import List, Literal
from services.gemini.constants import gemini_generate_with_retry
from services.gemini.nutrition import compute_meal_inflammation
from services.gemini.parsers import finalize_food_items


def _safe_finalize(food_items, where: str):
    """Wrap finalize_food_items so a tripwire failure never breaks the response."""
    if not food_items:
        return food_items
    try:
        return finalize_food_items(food_items, db_rows=None)
    except Exception as e:
        logger.warning(f"[vision:{where}] finalize_food_items failed: {e}", exc_info=True)
        return food_items

logger = get_logger(__name__)
settings = get_settings()


def _get_nutrition_cache() -> Optional[str]:
    """Get the nutrition analysis cache name from GeminiService (if available)."""
    try:
        from services.gemini_service import GeminiService
        return GeminiService._nutrition_analysis_cache
    except Exception:
        return None


def _count_dishes(result: dict) -> int:
    """Count total dishes across sections (menu) or top-level (buffet)."""
    total = 0
    for section in result.get("sections", []) or []:
        total += len(section.get("dishes", []) or [])
    total += len(result.get("dishes", []) or [])
    return total


def _iter_menu_dishes(result: dict):
    """Yield every dish dict in a menu or buffet response — flattens sections.

    Used by post-schema fallbacks so we can walk every dish without caring
    whether it came from buffet (flat `dishes`) or menu (nested in sections).
    Yields the actual dict references so callers can mutate in place.
    """
    for section in result.get("sections", []) or []:
        for dish in section.get("dishes", []) or []:
            yield dish
    for dish in result.get("dishes", []) or []:
        yield dish


# Default inflammation trigger tags when Gemini returns an empty array.
# Bucketed by inflammation_score band so the UI never shows a blank "why"
# box; these are deliberately generic since we don't know the real drivers
# — the user sees "general" language until the prompt compliance tightens.
_FALLBACK_TRIGGERS_BY_BAND = {
    "anti": ["whole_foods"],
    "mild": ["mixed_ingredients"],
    "high": ["processed_ingredients"],
}


def _apply_dish_health_fallbacks(dish: dict) -> None:
    """Fill in deterministic defaults for any health field Gemini dropped.

    Runs AFTER response_schema enforcement — schema makes this a rare path,
    but real production data has shown Gemini can still truncate long menu
    JSONs mid-dish, and salvage logic may re-introduce incomplete items. We
    prefer showing a safe default ("added_sugar_g: 0.0", generic trigger)
    over a blank pill the user can't interpret.
    """
    # added_sugar_g defaults to 0.0 — most savoury dishes have no added sugar.
    if dish.get("added_sugar_g") is None:
        dish["added_sugar_g"] = 0.0

    # is_ultra_processed defaults to False (conservative — we only warn when
    # Gemini is confident it's NOVA-4).
    if dish.get("is_ultra_processed") is None:
        dish["is_ultra_processed"] = False

    # inflammation_triggers: if empty/missing, derive one generic tag from
    # the score band. The real fix is prompt compliance; this just prevents
    # an empty chip row in the Score Explain sheet.
    triggers = dish.get("inflammation_triggers")
    if not triggers or not isinstance(triggers, list):
        score = dish.get("inflammation_score")
        if score is None:
            band = "mild"
        elif score <= 3:
            band = "anti"
        elif score <= 6:
            band = "mild"
        else:
            band = "high"
        dish["inflammation_triggers"] = _FALLBACK_TRIGGERS_BY_BAND[band]


def _log_dish_if_missing_fields(dish: dict, mode: str) -> None:
    """Emit a WARNING when any required health field is still missing.

    Schema enforcement should prevent this. If we see it in logs, the schema
    is being bypassed (cache conflict, SDK change, schema mismatch) and
    needs investigation.
    """
    missing = []
    for field in (
        "inflammation_score",
        "inflammation_triggers",
        "fodmap_rating",
        "added_sugar_g",
        "is_ultra_processed",
    ):
        if dish.get(field) is None:
            missing.append(field)
    # glycemic_load is allowed null for sub-2g-carb items
    if dish.get("glycemic_load") is None and dish.get("carbs_g", 0) >= 2:
        missing.append("glycemic_load")
    if missing:
        logger.warning(
            f"[vision_analyze_food_s3] mode={mode} dish='{dish.get('name','?')}' "
            f"missing required fields after schema: {missing}"
        )


def _salvage_truncated_menu_json(content: str, analysis_mode: str) -> Optional[dict]:
    """
    Attempt to recover a partially-complete menu/buffet JSON response.

    Gemini occasionally hits the output token cap mid-object. We chop the
    trailing incomplete dish, re-close the arrays + outer object, and re-parse.
    Returns the parsed dict on success, None if recovery isn't possible.
    """
    # Find the last complete dish by locating the last "},\n" or "}\n" followed
    # by more text inside a dishes array. Strategy: find last complete "}" that
    # belongs to a dish entry, then close any open arrays/objects after it.
    last_close = content.rfind('}')
    if last_close < 0:
        return None

    # Trim to just after the last complete brace, then close any unbalanced
    # brackets/braces left open.
    trimmed = content[: last_close + 1]
    open_brackets = trimmed.count('[') - trimmed.count(']')
    open_braces = trimmed.count('{') - trimmed.count('}')
    if open_brackets < 0 or open_braces < 0:
        return None

    # Drop any trailing "," before close
    trimmed = trimmed.rstrip()
    if trimmed.endswith(','):
        trimmed = trimmed[:-1]

    candidate = trimmed + (']' * open_brackets) + ('}' * open_braces)
    try:
        return json.loads(candidate)
    except json.JSONDecodeError:
        return None


class VisionService:
    """Service for analyzing images using Gemini Vision."""

    def __init__(self):
        # Food-scan vision is all perception (dish ID, OCR, classification) —
        # Flash Lite is faster + cheaper + thinking-minimal. See config.py.
        self.model = settings.gemini_vision_model
        # Initialize S3 client for multi-image analysis
        if settings.aws_access_key_id and settings.s3_bucket_name:
            self._s3_client = boto3.client(
                "s3",
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
                region_name=settings.aws_default_region,
            )
            self._bucket = settings.s3_bucket_name
        else:
            self._s3_client = None
            self._bucket = None

    def _get_suggested_meal_type(self) -> str:
        """Determine likely meal type based on current time."""
        hour = datetime.now().hour
        if 5 <= hour < 11:
            return "breakfast"
        elif 11 <= hour < 15:
            return "lunch"
        elif 15 <= hour < 18:
            return "snack"
        else:
            return "dinner"

    # =====================================================================
    # PHASE-2 Stage-1 thin classifiers (replaces analyze_food_image flow)
    # =====================================================================
    #
    # These return ONLY identification + portion (no macros, no enrichment,
    # no micronutrients). The downstream cache_service.analyze_dishes_from_vision
    # then resolves all 6+9+29 fields from food_nutrition_overrides_canonical
    # → user_contributed → USDA → Gemini fallback.
    #
    # Total Vision wall time: ~1.5-2s per call (vs 30-60s for the old
    # analyze_food_image with its 16-field schema). Output token budget:
    # ~150 tok/dish × ≤10 dishes = ≤1500 output tokens vs 4000 in legacy.

    async def identify_dishes_from_image(
        self,
        image_bytes: bytes,
        mime_type: str = "image/jpeg",
        mode: Literal['plate', 'buffet'] = 'plate',
        user_context: Optional[str] = None,
        request_id: str = "",
    ) -> Stage1DishIdentification:
        """Stage-1: identify dishes + portion estimate from a single image.

        Returns Stage1DishIdentification with 1-N dishes, cuisine_tag,
        plate_layout, meal_type_guess. NO macros, NO enrichment — those come
        from the cache_service lookup downstream.

        `mode='buffet'` bumps max_output_tokens to handle ≤20 dishes per
        photo (hotel breakfast spreads, food court samples). Plate mode
        targets ≤6 dishes (typical meal photo).
        """
        max_dishes = 20 if mode == 'buffet' else 6
        # Plate budget bumped 500→800: 6 dishes × ~80 tokens each (name +
        # weight + serving + confidence + cuisine_tag + plate_layout +
        # meal_type_guess) leaves headroom for verbose serving descriptions.
        # Buffet stays at 1200 (20 dishes).
        max_tokens = 1200 if mode == 'buffet' else 800
        suggested_meal = self._get_suggested_meal_type()
        ctx_line = f'\nUser says: "{user_context}"' if user_context else ''

        prompt = f"""Identify the dishes visible in this food/beverage image.

Time-of-day suggests: {suggested_meal} (override if the food clearly indicates otherwise).{ctx_line}

For EACH distinct dish (up to {max_dishes}):
- name: SPECIFIC normalized dish name. Examples:
    * "hyderabadi chicken biryani" not "biryani" (when regional cues visible)
    * "grilled chicken breast" not "chicken"
    * "ihop original buttermilk pancakes" if a chain logo is visible
    * "scrambled eggs" not just "eggs"
  Use lowercase, plain words separated by spaces. Backend re-normalizes.
- weight_g_estimate: realistic single-serving weight in grams. Don't guess
  the WHOLE PLATE's weight when there are multiple dishes — estimate each.
- serving_description: human-readable like "1 cup heaping", "2 strips",
  "1 piece, ~12oz". Surfaces in UI under the dish name.
- confidence: 0.0-1.0 your confidence in the identification.

ALSO return:
- cuisine_tag: ONE of indian|chinese|italian|mexican|french|japanese|thai|
  american|mediterranean|greek|vietnamese|korean|spanish|middle_eastern|
  african — drives region-aware downstream lookup. Null if ambiguous.
- plate_layout: 'single' (one dish) | 'mixed' (several dishes side-by-side)
  | 'composed' (combo plate / thali / bento / bowl with intermingled items)
- meal_type_guess: breakfast|lunch|dinner|snack|drink

CRITICAL: do NOT include macros, calories, micronutrients, vitamins, or
health ratings — that data comes from a separate database lookup. Just
identify and portion-estimate.

Top-level response is a JSON OBJECT with keys: dishes (array), cuisine_tag,
plate_layout, meal_type_guess.
"""

        image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)

        # Use list[Stage1Dish] schema (top-level array) — Phase-1 lesson:
        # Gemini structured-output rejects $ref/$defs from wrapper models.
        # We get the dish list as an array and assemble Stage1DishIdentification
        # from the rest of the JSON object via a follow-on parse.
        config = types.GenerateContentConfig(
            response_mime_type="application/json",
            temperature=0.1,
            max_output_tokens=max_tokens,
            # thinking_budget=0 — gemini-3.x is a thinking model; with thinking
            # ON it consumed the whole output budget and the JSON truncated
            # at ~char 36 (the 50% NO_FOOD_DETECTED bug). Dish ID is pure
            # perception, no reasoning needed.
            thinking_config=types.ThinkingConfig(thinking_budget=0),
        )

        logger.info(
            f"[stage1_identify_dishes:{request_id}] mode={mode} max_dishes={max_dishes}"
        )

        response = await gemini_generate_with_retry(
            model=self.model,
            contents=[prompt, image_part],
            config=config,
            method_name="vision_identify_dishes_stage1",
        )
        # Surface truncation explicitly — a non-STOP finish_reason means the
        # model was cut off (token cap / safety) and the JSON is likely
        # partial. Logged so a future thinking/budget regression is visible.
        try:
            fr = response.candidates[0].finish_reason
            if fr and str(fr).upper() not in ("STOP", "FINISHREASON.STOP"):
                logger.warning(
                    f"[stage1_identify_dishes:{request_id}] finish_reason={fr} "
                    "— response may be truncated"
                )
        except (AttributeError, IndexError, TypeError):
            pass
        raw = (response.text or "").strip()
        if not raw:
            raise RuntimeError("Empty Stage-1 response from Gemini Vision")

        # The model returns a JSON object with `dishes` array + metadata.
        # Tolerate the model wrapping with markdown fences.
        if raw.startswith("```"):
            raw = raw.strip("`").lstrip("json").strip()
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError as e:
            # Try to salvage a truncated response — Gemini sometimes terminates
            # mid-token even well under the budget (safety filter or model
            # variance). The same helper we use for menu salvage works for
            # plate too (both wrap a `dishes` array inside a JSON object).
            salvaged = _salvage_truncated_menu_json(raw, analysis_mode=mode)
            if salvaged and salvaged.get("dishes"):
                logger.warning(
                    f"[stage1_identify_dishes:{request_id}] salvaged "
                    f"{len(salvaged.get('dishes', []))} dishes from truncated "
                    f"response (raw_len={len(raw)})"
                )
                parsed = salvaged
            else:
                logger.error(
                    f"[stage1_identify_dishes:{request_id}] JSON parse failure: {e} — raw[:300]={raw[:300]!r}"
                )
                raise RuntimeError(f"Stage-1 JSON parse failure: {e}")

        # Construct Stage1DishIdentification from the parsed object. If the
        # model returned a bare array (sometimes it does), wrap it.
        if isinstance(parsed, list):
            parsed = {"dishes": parsed}

        # Normalize: drop dishes with empty name, cap at max_dishes
        raw_dishes = parsed.get("dishes", [])[:max_dishes]
        dishes: List[Stage1Dish] = []
        for d in raw_dishes:
            try:
                dish = Stage1Dish.model_validate(d)
                if dish.name.strip():
                    dishes.append(dish)
            except Exception as e:  # noqa: BLE001
                logger.warning(
                    f"[stage1_identify_dishes:{request_id}] skipping bad dish entry: {e}"
                )

        if not dishes:
            raise RuntimeError("Stage-1 returned no valid dishes (NO_FOOD_DETECTED)")

        return Stage1DishIdentification(
            dishes=dishes,
            cuisine_tag=parsed.get("cuisine_tag"),
            plate_layout=parsed.get("plate_layout", 'composed' if mode == 'buffet' else 'single'),
            meal_type_guess=parsed.get("meal_type_guess"),
        )

    async def identify_dishes_from_multi_image(
        self,
        image_bytes_list: List[bytes],
        mime_types: List[str],
        mode: Literal['plate', 'buffet'] = 'plate',
        user_context: Optional[str] = None,
        request_id: str = "",
    ) -> Stage1DishIdentification:
        """Stage-1 across N images (the 2-5 angles UX). Returns the UNION of
        dishes seen across all photos, deduplicated by normalized name.

        Drops the legacy `_classify_food_images` auto-classify hop — caller
        passes mode explicitly. Default to 'plate'; menu/buffet routed via
        dedicated paths.
        """
        if not image_bytes_list:
            raise RuntimeError("identify_dishes_from_multi_image called with no images")

        max_dishes = 25 if mode == 'buffet' else 12  # bigger across N photos
        max_tokens = 1500 if mode == 'buffet' else 800
        suggested_meal = self._get_suggested_meal_type()
        ctx_line = f'\nUser says: "{user_context}"' if user_context else ''

        prompt = f"""Identify ALL distinct dishes visible across these {len(image_bytes_list)} food/beverage images.

The user took multiple photos of the same meal (different angles or different plates). Return the UNION of dishes seen across photos, deduplicated by name — if the same dish appears in 2+ photos, list it ONCE with the best portion estimate.

Time-of-day suggests: {suggested_meal} (override based on the food).{ctx_line}

For EACH distinct dish (up to {max_dishes}):
- name: SPECIFIC normalized dish name (e.g. "grilled salmon", "miso soup", "chipotle chicken bowl")
- weight_g_estimate: realistic single-serving weight in grams
- serving_description: "1 cup heaping" / "2 strips" / "1 bowl, ~12oz"
- confidence: 0.0-1.0 in the identification

Plus:
- cuisine_tag (ONE of indian|chinese|italian|mexican|french|japanese|thai|american|mediterranean|greek|vietnamese|korean|spanish|middle_eastern|african, or null)
- plate_layout: 'mixed' (separate dishes) | 'composed' (combo / bowl) | 'single' (rare for multi-photo)
- meal_type_guess: breakfast|lunch|dinner|snack|drink

CRITICAL: NO macros, NO calories, NO micronutrients. JSON object with keys: dishes (array), cuisine_tag, plate_layout, meal_type_guess.
"""

        image_parts = [
            types.Part.from_bytes(data=b, mime_type=m)
            for b, m in zip(image_bytes_list, mime_types)
        ]

        config = types.GenerateContentConfig(
            response_mime_type="application/json",
            temperature=0.1,
            max_output_tokens=max_tokens,
            thinking_config=types.ThinkingConfig(thinking_budget=0),  # see L306
        )

        logger.info(
            f"[stage1_identify_multi:{request_id}] mode={mode} n_images={len(image_bytes_list)} max_dishes={max_dishes}"
        )

        response = await gemini_generate_with_retry(
            model=self.model,
            contents=[prompt] + image_parts,
            config=config,
            method_name="vision_identify_multi_stage1",
        )
        raw = (response.text or "").strip()
        if not raw:
            raise RuntimeError("Empty multi-image Stage-1 response from Gemini Vision")
        if raw.startswith("```"):
            raw = raw.strip("`").lstrip("json").strip()

        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError as e:
            # Same salvage path as the single-image Stage-1 — see L324.
            salvaged = _salvage_truncated_menu_json(raw, analysis_mode=mode)
            if salvaged and salvaged.get("dishes"):
                logger.warning(
                    f"[stage1_identify_multi:{request_id}] salvaged "
                    f"{len(salvaged.get('dishes', []))} dishes from truncated "
                    f"response (raw_len={len(raw)})"
                )
                parsed = salvaged
            else:
                logger.error(
                    f"[stage1_identify_multi:{request_id}] JSON parse failure: {e}"
                )
                raise RuntimeError(f"Multi-image Stage-1 JSON parse failure: {e}")

        if isinstance(parsed, list):
            parsed = {"dishes": parsed}

        # Dedup by normalized name (Python-side defense in case the model
        # didn't fully dedupe per the prompt)
        seen_names: set = set()
        dishes: List[Stage1Dish] = []
        for d in parsed.get("dishes", [])[:max_dishes]:
            try:
                dish = Stage1Dish.model_validate(d)
                key = dish.name.strip().lower()
                if not key or key in seen_names:
                    continue
                seen_names.add(key)
                dishes.append(dish)
            except Exception as e:  # noqa: BLE001
                logger.warning(
                    f"[stage1_identify_multi:{request_id}] skipping bad dish: {e}"
                )

        if not dishes:
            raise RuntimeError(
                "Multi-image Stage-1 returned no valid dishes (NO_FOOD_DETECTED across all photos)"
            )

        return Stage1DishIdentification(
            dishes=dishes,
            cuisine_tag=parsed.get("cuisine_tag"),
            plate_layout=parsed.get("plate_layout", 'composed' if len(dishes) > 3 else 'mixed'),
            meal_type_guess=parsed.get("meal_type_guess"),
        )

    async def identify_menu_from_image(
        self,
        image_bytes_list: List[bytes],
        mime_types: List[str],
        request_id: str = "",
    ) -> Stage1MenuIdentification:
        """Stage-1 for restaurant menu OCR. Returns restaurant_name + items
        grouped by section (Appetizers/Mains/Desserts/etc.). NO macros — the
        downstream menu_scan_cache + canonical lookup fills nutrition.
        """
        prompt = """OCR this restaurant menu (or menus, if multiple photos).

Return:
- restaurant_name: the restaurant name extracted from header / logo / footer if visible. NULL if not visible.
- items: array of menu items. Up to 80 items total across all photos.

For each item:
- name: dish name as it appears on the menu (preserve as-is, the backend normalizes for lookup)
- section: 'Appetizers' | 'Mains' | 'Entrees' | 'Desserts' | 'Drinks' | 'Sides' | 'Soups' | 'Salads' | 'Breakfast' | 'Brunch' | 'Lunch' | 'Dinner' | null

CRITICAL:
- Do NOT include prices.
- Do NOT include menu descriptions, ingredients, or marketing copy — just the dish NAME.
- Do NOT include macros, calories, or nutrition info — that comes from database lookup.
- Skip non-food items (drinks specials banner, hours, contact info).

Top-level JSON object with keys: restaurant_name, items.
"""

        image_parts = [
            types.Part.from_bytes(data=b, mime_type=m)
            for b, m in zip(image_bytes_list, mime_types)
        ]

        config = types.GenerateContentConfig(
            response_mime_type="application/json",
            temperature=0.1,
            max_output_tokens=4000,  # menus can have lots of items
            thinking_config=types.ThinkingConfig(thinking_budget=0),  # see L306
        )

        logger.info(
            f"[stage1_identify_menu:{request_id}] n_images={len(image_bytes_list)}"
        )

        response = await gemini_generate_with_retry(
            model=self.model,
            contents=[prompt] + image_parts,
            config=config,
            method_name="vision_identify_menu_stage1",
        )
        raw = (response.text or "").strip()
        if not raw:
            raise RuntimeError("Empty menu Stage-1 response from Gemini Vision")
        if raw.startswith("```"):
            raw = raw.strip("`").lstrip("json").strip()

        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError as e:
            # Best-effort salvage of truncated menu JSON (existing helper)
            salvaged = _salvage_truncated_menu_json(raw, "menu")
            if salvaged is not None:
                parsed = salvaged
            else:
                raise RuntimeError(f"Menu Stage-1 JSON parse failure: {e}")

        items: List[Stage1MenuItem] = []
        for item in parsed.get("items", [])[:80]:
            try:
                m = Stage1MenuItem.model_validate(item)
                if m.name.strip():
                    items.append(m)
            except Exception as e:  # noqa: BLE001
                logger.warning(
                    f"[stage1_identify_menu:{request_id}] skipping bad item: {e}"
                )

        if not items:
            raise RuntimeError(
                "Menu Stage-1 returned no valid items (NO_MENU_DETECTED)"
            )

        return Stage1MenuIdentification(
            restaurant_name=parsed.get("restaurant_name"),
            items=items,
        )

    # =====================================================================
    # Legacy heavyweight path — kept for rollback safety until Phase 2 ships
    # =====================================================================

    async def analyze_food_image(
        self,
        image_base64: str,
        user_context: Optional[str] = None,
    ) -> dict:
        """
        Analyze a food image to extract nutrition information.

        Args:
            image_base64: Base64 encoded image data (without data:image prefix)
            user_context: Optional message from user about the meal

        Returns:
            Dictionary with nutrition analysis including:
            - meal_type: Detected meal type
            - food_items: List of identified foods with individual nutrition
            - total_calories, total_protein_g, total_carbs_g, total_fat_g, total_fiber_g
            - health_score: 1-10 rating
            - feedback: Coaching feedback on the meal
        """
        suggested_meal = self._get_suggested_meal_type()

        # Check for nutrition context cache
        cache_name = _get_nutrition_cache()

        if cache_name:
            # Dynamic-only prompt (static guidelines/schema/reference data are in the cache)
            prompt = f"""Analyze this food or beverage image and provide detailed nutrition estimates. Include drinks (cocktails, smoothies, juices, coffee, protein shakes), beverages, and any consumable items.

Current time suggests this is likely {suggested_meal}, but override based on the food if it clearly indicates otherwise.

{f'User says: "{user_context}"' if user_context else ''}

For COUNTABLE items (breadsticks, samosas, eggs, nuggets, cookies, sushi rolls, dumplings, pizza slices, tacos, wings, meatballs, falafel, etc.) ALWAYS set count = number of pieces visible AND weight_per_unit_g = grams per piece, with weight_g = count × weight_per_unit_g. For non-countable items (rice, soup, pasta heap, salad) leave count=null and weight_per_unit_g=null.

Estimate all micronutrients (vitamins A/C/D/E/K/B1-B12, minerals like calcium/iron/magnesium/zinc/potassium/sodium, omega-3/6) based on the identified foods. Use the plate analysis JSON schema from your cached reference. Return valid JSON."""
        else:
            # Full prompt (no cache available — include everything inline)
            prompt = f"""Analyze this food or beverage image and provide detailed nutrition estimates. Include drinks (cocktails, smoothies, juices, coffee, protein shakes), beverages, and any consumable items.

Current time suggests this is likely {suggested_meal}, but override based on the food if it clearly indicates otherwise (e.g., pancakes are breakfast even at dinner time).

{f'User says: "{user_context}"' if user_context else ''}

Return ONLY valid JSON with this exact structure:
{{
    "meal_type": "breakfast" | "lunch" | "dinner" | "snack",
    "food_items": [
        {{
            "name": "food name",
            "amount": "estimated amount (e.g., '1 cup', '150g', '1 medium')",
            "calories": <integer>,
            "protein_g": <float>,
            "carbs_g": <float>,
            "fat_g": <float>,
            "weight_g": <float - estimated weight in grams>,
            "count": <integer or null - number of countable items like eggs, cookies>,
            "weight_per_unit_g": <float or null - weight of one piece for countable items>,
            "confidence": "high" | "medium" | "low",
            "estimate_reasoning": "<short grounded phrase, <=80 chars, or null>"
        }}
    ],
    "total_calories": <integer>,
    "total_protein_g": <float>,
    "total_carbs_g": <float>,
    "total_fat_g": <float>,
    "total_fiber_g": <float>,
    "health_score": <integer 1-10>,
    "feedback": "Brief, encouraging coaching feedback about this meal (2-3 sentences max)"
}}

Guidelines:
- Be realistic with portion estimates based on what you see
- If you can't identify something clearly, make a reasonable guess
- Health score: 1-3 (poor), 4-6 (average), 7-8 (good), 9-10 (excellent)
- Feedback should be constructive and encouraging, mentioning positives first
- Include fiber estimate if vegetables/whole grains are present
- Estimate all micronutrients (vitamins, minerals, fatty acids) based on the identified foods
- confidence: be HONEST per item. 'high' = clearly identifiable + obvious
  portion; 'medium' = identity clear, portion estimated; 'low' = ambiguous
  identity, hidden contents (smoothie/soup/wrap), blurry, or an unfamiliar
  regional dish. A 'low' surfaces a 1-tap user confirm — do not over-claim.
- estimate_reasoning: ONE short phrase citing a REAL visible cue for the
  portion ('~220g; plate reads ~10in', 'standard 1-cup serving'). Must be
  grounded — never invent details. Set null when there is no real basis."""

        try:
            logger.info(f"🍽️ Analyzing food image with Gemini (cache={'yes' if cache_name else 'no'})")

            # Decode base64 image data
            image_bytes = base64.b64decode(image_base64)

            # Create image part for Gemini using the new SDK
            image_part = types.Part.from_bytes(
                data=image_bytes,
                mime_type="image/jpeg"
            )

            # Build config with optional cached_content
            gen_config = types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=FoodAnalysisResponse,
                max_output_tokens=4000,
                thinking_config=types.ThinkingConfig(thinking_budget=0),  # thinking off — see L306
                temperature=0.3,
            )
            if cache_name:
                gen_config.cached_content = cache_name

            # Generate content with image
            response = await gemini_generate_with_retry(
                model=self.model,
                contents=[prompt, image_part],
                config=gen_config,
                method_name="vision_analyze_food_image",
            )

            # Parse the response - try structured parsed result first, fall back to text
            logger.info(f"✅ Vision API response received")

            # Try to get parsed result from structured output first
            result = None
            try:
                # Gemini structured output may have a parsed attribute
                if hasattr(response, 'parsed') and response.parsed:
                    result = response.parsed if isinstance(response.parsed, dict) else json.loads(str(response.parsed))
            except Exception:
                pass

            if result is None:
                content = response.text.strip()
                try:
                    result = json.loads(content)
                except json.JSONDecodeError:
                    # Try to repair truncated/malformed JSON by extracting food_items
                    logger.warning(f"⚠️ JSON parse failed, attempting repair. Raw: {content[:300]}...", exc_info=True)
                    import re
                    # Extract what we can from the partial JSON
                    repaired = content
                    # Close any unclosed arrays/objects
                    open_brackets = repaired.count('[') - repaired.count(']')
                    open_braces = repaired.count('{') - repaired.count('}')
                    # Remove trailing comma before closing
                    repaired = re.sub(r',\s*$', '', repaired)
                    repaired += ']' * open_brackets + '}' * open_braces
                    try:
                        result = json.loads(repaired)
                        logger.info(f"✅ JSON repair successful")
                    except json.JSONDecodeError as e2:
                        logger.error(f"❌ JSON repair also failed: {e2}", exc_info=True)
                        logger.error(f"Raw content: {content[:500]}...", exc_info=True)
                        raise ValueError(f"Invalid JSON in vision response: {e2}")

            # Validate required fields
            required_fields = [
                "meal_type",
                "food_items",
                "total_calories",
                "total_protein_g",
                "total_carbs_g",
                "total_fat_g",
                "health_score",
                "feedback",
            ]
            for field in required_fields:
                if field not in result:
                    logger.warning(f"Missing field in response: {field}")
                    result[field] = self._get_default_value(field)

            # Ensure fiber is present
            if "total_fiber_g" not in result:
                result["total_fiber_g"] = 0.0

            # Normalize response - add non-prefixed versions for consistency with GeminiService
            # This ensures both total_protein_g and protein_g are available
            result["protein_g"] = result.get("total_protein_g", 0.0)
            result["carbs_g"] = result.get("total_carbs_g", 0.0)
            result["fat_g"] = result.get("total_fat_g", 0.0)
            result["fiber_g"] = result.get("total_fiber_g", 0.0)

            if not result.get("food_items"):
                logger.warning(f"⚠️ Gemini returned 0 food items. Raw response: {content[:500]}")

            # L2+L3 portion validation (vision flow has no DB rows; only L3 fires).
            result["food_items"] = _safe_finalize(result.get("food_items") or [], "single_image_plate")

            logger.info(
                f"✅ Food analysis complete: {result['total_calories']} cal, "
                f"{len(result['food_items'])} items identified"
            )

            return result

        except json.JSONDecodeError as e:
            logger.error(f"❌ Failed to parse JSON response: {e}", exc_info=True)
            logger.error(f"Raw content: {content[:500]}...", exc_info=True)
            raise ValueError(f"Invalid JSON in vision response: {e}")

        except Exception as e:
            logger.error(f"❌ Vision analysis failed: {e}", exc_info=True)
            raise

    # Valid media content types for classification
    VALID_CONTENT_TYPES = {
        "food_plate", "food_menu", "food_buffet", "exercise_form",
        "progress_photo", "app_screenshot", "nutrition_label",
        "document", "gym_equipment", "unknown",
        # Recipes feature additions
        "pantry_photo", "recipe_handwritten",
    }

    async def classify_media_content(
        self,
        image_data: Optional[bytes] = None,
        image_base64: Optional[str] = None,
        mime_type: str = "image/jpeg",
        s3_key: Optional[str] = None,
        user_message: Optional[str] = None,
    ) -> str:
        """
        Classify what media content shows. Lightweight Gemini Vision call (~10 tokens output).

        Used for intelligent agent routing before the message reaches a domain agent.

        Returns one of: food_plate, food_menu, food_buffet, exercise_form,
        progress_photo, app_screenshot, nutrition_label, document,
        gym_equipment, unknown

        `user_message` is the text the user typed alongside the image. Passing
        it lets Gemini disambiguate hybrid images — e.g. a phone screenshot
        of a DoorDash menu shouldn't be `app_screenshot` if the user is asking
        "what should I eat", that's clearly a `food_menu` recommendation.
        """
        import time as _time
        start = _time.time()

        user_text_hint = ""
        if user_message and user_message.strip():
            # Truncate aggressively — only the gist matters for routing, not
            # the full essay.
            snippet = user_message.strip().replace("\n", " ")[:240]
            user_text_hint = (
                f"\n\nThe user typed alongside this image: \"{snippet}\"\n"
                "Use this text as context to disambiguate. Examples:\n"
                "  - menu image + 'what should I eat / recommend / which is best' → food_menu\n"
                "  - plate image + 'log this' → food_plate\n"
                "  - screenshot + 'log my macros from yesterday' → app_screenshot\n"
                "  - bottle/box label + 'how many calories' → nutrition_label"
            )

        classify_prompt = (
            "Look at this image/frame. Classify what it shows as ONE of these categories. "
            "Respond with ONLY the category name, nothing else.\n\n"
            "Categories:\n"
            "- food_plate: A plate, bowl, or serving of food/drink\n"
            "- food_menu: A menu listing dishes/items with names and prices. INCLUDES food"
            " delivery app screenshots (DoorDash, Uber Eats, Grubhub, Postmates, Deliveroo),"
            " restaurant websites, printed menus, cafe boards, and in-restaurant digital menus."
            " ANY image whose primary content is a list of dishes you could order is food_menu —"
            " do NOT classify it as app_screenshot just because it's on a phone.\n"
            "- food_buffet: A buffet spread or multiple dishes laid out on a table\n"
            "- exercise_form: A person performing a physical exercise or workout movement\n"
            "- progress_photo: A body/physique photo, mirror selfie, or before/after comparison\n"
            "- app_screenshot: A screenshot from a FITNESS- or NUTRITION-TRACKING app showing"
            " ALREADY-LOGGED data with calorie/macro numbers (MyFitnessPal log, Apple Health,"
            " Cronometer, Lose It!, etc.). NOT for food delivery apps — those are food_menu.\n"
            "- nutrition_label: A nutrition facts label on food packaging\n"
            "- document: A text document, handwritten note, printed paper, or PDF\n"
            "- gym_equipment: Gym equipment or machines with no person exercising\n"
            "- pantry_photo: An open fridge, pantry, or refrigerator interior showing groceries on hand\n"
            "- recipe_handwritten: A handwritten or printed recipe card / cookbook page\n"
            "- unknown: Cannot determine or none of the above"
            + user_text_hint
        )

        try:
            # Resolve image bytes from the various input sources
            if image_data:
                raw_bytes = image_data
            elif image_base64:
                raw_bytes = base64.b64decode(image_base64)
            elif s3_key:
                raw_bytes = await self._download_image_from_s3(s3_key)
            else:
                logger.warning("[MediaClassifier] No image data provided")
                return "unknown"

            image_part = types.Part.from_bytes(data=raw_bytes, mime_type=mime_type)

            response = await gemini_generate_with_retry(
                model=self.model,
                contents=[classify_prompt, image_part],
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=15,
                    thinking_config=types.ThinkingConfig(thinking_budget=0),  # thinking off — see L306
                ),
                method_name="vision_classify_media",
            )

            raw_text = response.text.strip().lower()
            # Match against valid types with substring matching
            for content_type in self.VALID_CONTENT_TYPES:
                if content_type in raw_text:
                    elapsed = _time.time() - start
                    logger.info(f"[MediaClassifier] Classified as: {content_type} (took {elapsed:.2f}s)")
                    return content_type

            elapsed = _time.time() - start
            logger.warning(f"[MediaClassifier] Unrecognized response '{raw_text}', defaulting to unknown (took {elapsed:.2f}s)")
            return "unknown"

        except Exception as e:
            elapsed = _time.time() - start
            logger.warning(f"[MediaClassifier] Classification failed (took {elapsed:.2f}s): {e}", exc_info=True)
            return "unknown"

    # ============================================================
    # Recipes feature: pantry photo + handwritten recipe extraction
    # ============================================================

    async def analyze_pantry_image(self, image_b64: str) -> list[dict]:
        """Detect groceries visible in a pantry/fridge photo.

        Returns: [{name, confidence, qty_estimate?}, ...]. Throws on hard failure
        so callers can surface the error rather than silently returning [].
        """
        prompt = (
            "List every distinct food/drink item visible in this fridge or pantry image. "
            "Return JSON ONLY with this shape: "
            '{"items":[{"name":"chicken breast","confidence":85,"qty_estimate":"approx 2 packs"}]}\n'
            "Be specific: 'whole milk' not 'dairy'. Skip non-food items."
        )
        try:
            raw_bytes = base64.b64decode(image_b64)
            image_part = types.Part.from_bytes(data=raw_bytes, mime_type="image/jpeg")
            response = await gemini_generate_with_retry(
                model=self.model,
                contents=[prompt, image_part],
                config=types.GenerateContentConfig(
                    temperature=0.2, max_output_tokens=800,
                    thinking_config=types.ThinkingConfig(thinking_budget=0),  # see L306
                ),
                method_name="vision_pantry",
            )
            text = (response.text or "").strip()
            if text.startswith("```"):
                import re as _re
                text = _re.sub(r"^```(?:json)?\s*", "", text)
                text = _re.sub(r"\s*```$", "", text)
            import json as _json
            data = _json.loads(text)
            items = data.get("items") or []
            # Defensive: filter to dict items with a name
            return [
                {"name": i["name"], "confidence": int(i.get("confidence", 70)),
                 "qty_estimate": i.get("qty_estimate")}
                for i in items if isinstance(i, dict) and i.get("name")
            ]
        except Exception as exc:
            logger.exception("[Vision] pantry analyze failed")
            raise RuntimeError(f"Could not analyze pantry image: {exc}") from exc

    async def extract_handwritten_recipe(self, image_b64: str) -> str:
        """OCR + light cleanup for a handwritten or printed recipe image.

        Returns plain text: title on first line, ingredients next, then steps.
        Caller (recipe_import_service) parses this into structured form via Gemini.
        """
        prompt = (
            "This image contains a recipe (handwritten card, cookbook page, or printed). "
            "Read it carefully and return plain text in this layout:\n"
            "TITLE: <name>\n"
            "SERVINGS: <number or blank>\n"
            "INGREDIENTS:\n- one per line with amount and unit\n"
            "STEPS:\n1. ...\n2. ...\n"
            "If parts are illegible, mark them with [unclear]. Do not invent missing items."
        )
        try:
            raw_bytes = base64.b64decode(image_b64)
            image_part = types.Part.from_bytes(data=raw_bytes, mime_type="image/jpeg")
            response = await gemini_generate_with_retry(
                model=self.model,
                contents=[prompt, image_part],
                config=types.GenerateContentConfig(
                    temperature=0.1, max_output_tokens=2000,
                    thinking_config=types.ThinkingConfig(thinking_budget=0),  # see L306
                ),
                method_name="vision_handwritten_recipe",
            )
            return (response.text or "").strip()
        except Exception as exc:
            logger.exception("[Vision] handwritten OCR failed")
            raise RuntimeError(f"Could not read handwritten recipe: {exc}") from exc

    async def extract_text_from_frames(
        self,
        frames: "list[types.Part]",
        audio_part: "Optional[types.Part]" = None,
    ) -> str:
        """Transcribe a social-video clip into plain text for recipe parsing.

        One multimodal Gemini call that does BOTH jobs in a single round-trip:
          * OCR every readable on-screen overlay across the sampled `frames`
            (recipe title, ingredient list, step captions) — this is the
            common TikTok/Reels case where the recipe is shown as text with
            little or no narration, and
          * transcribe the spoken narration from `audio_part` when provided
            (Instagram/TikTok talk-through recipes that have no on-screen text).

        Returns a single plain-text block (on-screen text first, then the
        spoken transcript). Returns "" when there's nothing to send or the
        call fails — the caller still has caption/transcript text to fall back
        on, so this never raises.
        """
        if not frames and audio_part is None:
            return ""

        wants_audio = audio_part is not None
        prompt = (
            "These are sampled frames"
            + (" and the audio track" if wants_audio else "")
            + " from a short cooking video. Extract the recipe content as PLAIN TEXT "
            "(no markdown, no commentary). Do BOTH of these:\n"
            "1. ON-SCREEN TEXT: read every readable text overlay across the frames — "
            "recipe name, ingredient list with amounts, and any step text. Preserve "
            "line breaks and the order it appears.\n"
            + (
                "2. NARRATION: transcribe what the speaker says in the audio, "
                "including any ingredient amounts or steps they call out.\n"
                if wants_audio
                else ""
            )
            + "Combine everything you find into one text block. Do not invent "
            "ingredients or steps that aren't shown or spoken. If nothing readable "
            "is present, return an empty response."
        )
        try:
            contents: list = [prompt]
            contents.extend(frames)
            if audio_part is not None:
                contents.append(audio_part)
            response = await gemini_generate_with_retry(
                model=self.model,
                contents=contents,
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    max_output_tokens=2000,
                ),
                method_name="vision_social_video_text",
            )
            return (response.text or "").strip()
        except Exception as exc:
            logger.warning("[Vision] social video text extraction failed: %s", exc)
            return ""

    async def _download_image_from_s3(self, s3_key: str) -> bytes:
        """Download an image from S3 into memory (max ~1.5MB per image).
        Retries once after 2s on NoSuchKey — covers parallel upload race condition."""
        if not self._s3_client or not self._bucket:
            raise RuntimeError("S3 client not configured for multi-image analysis")

        for attempt in range(2):
            try:
                s3_obj = await asyncio.to_thread(
                    self._s3_client.get_object,
                    Bucket=self._bucket,
                    Key=s3_key,
                )
                body = s3_obj["Body"]
                data = await asyncio.to_thread(body.read)
                logger.debug(f"Downloaded {len(data)} bytes from S3 key: {s3_key}")
                return data
            except Exception as e:
                if "NoSuchKey" in str(type(e).__name__) or "NoSuchKey" in str(e):
                    if attempt == 0:
                        logger.warning(f"⚠️ S3 key not found (attempt 1), retrying in 2s: {s3_key}", exc_info=True)
                        await asyncio.sleep(2)
                        continue
                raise

    async def _classify_food_images(self, image_parts: list) -> str:
        """Quick classification: plate, buffet, or menu."""
        classify_prompt = (
            "Look at these food-related images. Classify what they show as ONE of: "
            "plate, buffet, menu. Respond with one word only."
        )
        response = await gemini_generate_with_retry(
            model=self.model,
            contents=[classify_prompt] + image_parts,
            config=types.GenerateContentConfig(
                temperature=0.1,
                max_output_tokens=10,
                thinking_config=types.ThinkingConfig(thinking_budget=0),  # thinking off — see L306
            ),
            method_name="vision_classify_food_images",
        )
        classification = response.text.strip().lower()
        if "buffet" in classification or "spread" in classification:
            return "buffet"
        elif "menu" in classification:
            return "menu"
        return "plate"

    async def analyze_food_from_s3_keys(
        self,
        s3_keys: list[str],
        mime_types: list[str],
        user_context: Optional[str] = None,
        analysis_mode: str = "auto",
        nutrition_context: Optional[dict] = None,
        standing_rules_block: str = "",
    ) -> dict:
        """
        Analyze multiple food images from S3 for nutrition estimation.

        Supports plates, buffets, and restaurant menus.

        Args:
            s3_keys: List of S3 object keys for the images
            mime_types: List of MIME types for each image
            user_context: Optional user context message
            analysis_mode: "auto", "plate", "buffet", or "menu"
            nutrition_context: User's daily targets + remaining budget

        Returns:
            Dict with nutrition analysis results
        """
        logger.info(f"Analyzing {len(s3_keys)} food images, mode={analysis_mode}")

        try:
            # Step 1: Download all images from S3 in parallel
            download_tasks = [self._download_image_from_s3(key) for key in s3_keys]
            image_data_list = await asyncio.gather(*download_tasks)

            # Step 2: Create Gemini Parts for each image
            image_parts = []
            for data, mime_type in zip(image_data_list, mime_types):
                image_parts.append(types.Part.from_bytes(data=data, mime_type=mime_type))

            # Step 3: Auto-classify if needed
            if analysis_mode == "auto":
                analysis_mode = await self._classify_food_images(image_parts)
                logger.info(f"Auto-classified food images as: {analysis_mode}")

            # Step 4: Build prompt based on mode.
            # Menu + buffet modes use a trimmed inline schema to maximize dish
            # capacity under the token cap, so we bypass the nutrition cache
            # (which bakes in a heavier schema with recommended_order/tips/etc.)
            cache_name = _get_nutrition_cache()
            if analysis_mode in ("menu", "buffet"):
                cache_name = None
            nutrition_ctx_str = ""
            if nutrition_context:
                nutrition_ctx_str = f"\nUser's nutrition context: {json.dumps(nutrition_context)}"

            user_ctx_str = f'\nUser says: "{user_context}"' if user_context else ""
            suggested_meal = self._get_suggested_meal_type()

            # A3 — instruction-following contract. Only injected when the user
            # actually typed an instruction, so a no-instruction scan keeps the
            # leaner prompt. Hardened so the model honors explicit overrides,
            # exclusions and stated logic, and reports back WHAT it changed.
            instruction_block = ""
            if user_context and user_context.strip():
                instruction_block = (
                    "\n\nUSER INSTRUCTION (HIGH PRIORITY — read carefully):\n"
                    f'The user wrote: "{user_context.strip()}"\n'
                    "Treat this instruction as authoritative over what the photo alone suggests:\n"
                    "1. PORTION OVERRIDE — if the user states an amount or fraction "
                    "(\"I ate half\", \"only a quarter\", \"~10in plate\", \"300g\"), scale the "
                    "affected items to match. \"I ate half\" -> halve calories, macros and weight_g of "
                    "every plated item unless the user scopes it to one food.\n"
                    "2. EXCLUDE NAMED FOODS — if the user says to exclude/remove/skip a food "
                    "(\"exclude the bread\", \"no rice\", \"didn't eat the fries\"), DROP that item "
                    "entirely from food_items and from every total. Do not just zero it out.\n"
                    "3. APPLY STATED LOGIC — honor preparation/ingredient claims (\"no oil\", "
                    "\"grilled not fried\", \"skim milk\", \"add 2 tbsp peanut butter\") and recompute "
                    "macros accordingly.\n"
                    "4. CONTRADICTION — if the instruction names a food the photo clearly does NOT "
                    "show, trust the instruction and re-analyze from the text; if it names a food "
                    "you cannot find to exclude/modify, apply what you can and say so in the note.\n"
                    "5. IMPLAUSIBLE CLAIMS — if the instruction is physically implausible "
                    "(\"5000 cal of lettuce\"), keep a realistic estimate and note that you did not "
                    "apply the implausible figure.\n"
                    "6. NONSENSE / QUESTIONS — if the instruction is off-topic, abusive, or actually "
                    "a question, ignore it for the numbers and analyze the photo normally; leave "
                    "applied_instruction_note null.\n"
                    "7. CONFLICTS — if two instructions conflict (\"no oil\" + \"deep fried\"), follow "
                    "the most specific / last one and note the conflict.\n"
                    "8. REPORT BACK — set `applied_instruction_note` to a short past-tense summary of "
                    "exactly what the instruction changed (e.g. 'Halved all portions; removed the "
                    "bread.'). If the instruction changed nothing, leave it null.\n"
                )

            # L3 — standing food-logging rules. Built by the caller via
            # food_logging_rules_service.build_rules_prompt_block(); empty when
            # the user has no rules. Appended to instruction_block so all three
            # prompt branches (plate/buffet/menu) carry it. The rules service
            # already encoded the per-log-instruction override wording, so a
            # per-log instruction wins over a conflicting standing rule (C9).
            if standing_rules_block:
                instruction_block = instruction_block + standing_rules_block

            if analysis_mode == "buffet":
                prompt = f"""Analyze this buffet/food spread. Identify EVERY distinct dish visible — do not skip any.

CRITICAL RULES:
1. NUTRITION MUST NOT BE ROUND — derive calories from realistic portion weight (weight_g × kcal/g). Acceptable: 387, 462, 518. NOT acceptable: 400, 450, 500 every time. Decimal precision for macros (42.6 not 40.0).
2. ALWAYS include weight_g — your best estimate of the single-serving weight in grams.
3. DETECT allergens per FDA Big 9 — fill detected_allergens as an array using any of: "milk", "egg", "fish", "crustacean_shellfish", "tree_nuts", "wheat", "peanuts", "soybeans", "sesame".

REQUIRED per dish (NEVER omit any field below):
- name, calories, protein_g, carbs_g, fat_g (per single serving)
- serving_description, weight_g
- rating ("green" | "yellow" | "red") + rating_reason (≤ 8 words)
- inflammation_score (0-10; 0-3 anti, 4-6 neutral/mild, 7-10 highly inflammatory) — NEVER null.
- inflammation_triggers: array of 1-3 short tags naming the drivers of inflammation_score. NEVER empty. Pick from: deep_fried, seed_oil, refined_flour, added_sugar, processed_meat, saturated_fat, omega6_high, artificial_additives, omega3_rich, leafy_greens, olive_oil, turmeric, whole_grains, fermented, berries, fatty_fish (free-form accepted).
- glycemic_load (integer per serving; GL = GI × carbs_g / 100; <10 low, 10-19 medium, 20+ high) — null ONLY for near-zero-carb items (< 2g carbs).
- fodmap_rating ("low" | "medium" | "high" per Monash) — NEVER null, every cooked dish classifies.
- fodmap_reason (≤ 6 words naming trigger ingredient(s)) — null ONLY when fodmap_rating == "low".
- added_sugar_g (grams of added sugar per serving; excludes naturally-occurring whole-fruit/whole-dairy sugar). Use 0.0 when none. NEVER null.
- is_ultra_processed (bool; NOVA Group 4 → true). NEVER null.
- coach_tip (≤ 18 words: pick or skip, tailored to the user's nutrition context).

RESTAURANT NAME: If the restaurant / venue name is visible anywhere in the image (signage, station labels, branding), extract it into a top-level "restaurant_name" string. Set "restaurant_name" to null if no name is visible.
{nutrition_ctx_str}{user_ctx_str}{instruction_block}

Return ONLY this JSON, no other keys:
{{
    "analysis_type": "buffet",
    "restaurant_name": "Spice Garden Buffet",
    "dishes": [
        {{
            "name": "Chicken Biryani",
            "calories": 538,
            "protein_g": 28.4,
            "carbs_g": 62.1,
            "fat_g": 19.3,
            "weight_g": 240,
            "serving_description": "1 cup, heaping",
            "detected_allergens": ["milk"],
            "rating": "yellow",
            "rating_reason": "balanced, watch the ghee",
            "inflammation_score": 4,
            "inflammation_triggers": ["saturated_fat", "refined_flour"],
            "glycemic_load": 18,
            "fodmap_rating": "medium",
            "fodmap_reason": "contains onion, garlic",
            "added_sugar_g": 0.0,
            "is_ultra_processed": false,
            "coach_tip": "Decent option; take half portion + extra protein."
        }}
    ]
}}"""

            elif analysis_mode == "menu":
                prompt = f"""Analyze this restaurant menu. OCR extract EVERY dish across ALL sections — do not skip any, do not truncate.

COMPLETENESS CONTRACT (read first):
0. Before producing JSON, COUNT the dishes visible across ALL sections (including descriptions in small print). The final response MUST contain that exact count of dish entries. If you can't fit them all, drop the LONGEST descriptive prose first — never drop a dish.
0a. Coverage > prose. coach_tip / rating_reason / fodmap_reason can be terse (≤ 6 words) so token budget goes to MORE DISHES rather than longer reasons.
0b. If a section header is visible (e.g. "Burgers", "Bowls", "Drinks"), that section MUST appear in the output, even if you only have room for the most common 1-2 dishes from it.

CRITICAL RULES:
1. NUTRITION MUST NOT BE ROUND — derive calories from realistic portion weight (weight_g × kcal/g). Acceptable values: 387, 462, 518. NOT acceptable: 400, 450, 500 every time. Same rule for protein_g / carbs_g / fat_g — decimal precision expected (e.g. 42.6, not 40.0).
2. ALWAYS include weight_g — your best estimate of the dish's serving weight in grams (typical restaurant portions: naan 80-100g, curry bowl 200-300g, rice 150-250g, entrée protein 150-250g, salad 150-250g, soup 240-300g).
3. NORMALIZE section_name to ONE of: "breakfast" | "appetizers" | "mains" | "sides" | "desserts" | "drinks" | "specials" | "uncategorized". Map restaurant labels like "Starters" → "appetizers", "Entrées" → "mains", "Beverages" → "drinks".
4. EXTRACT price as a number when visible on the menu (keep the currency in a "currency" string like "USD" / "INR" / "EUR"). Return null ONLY if truly not shown.
5. DETECT allergens per FDA Big 9 — fill detected_allergens as an array using any of: "milk", "egg", "fish", "crustacean_shellfish", "tree_nuts", "wheat", "peanuts", "soybeans", "sesame". Infer from dish description (e.g. "Shrimp Pad Thai" → ["crustacean_shellfish", "peanuts", "soybeans"]).

REQUIRED per dish (NEVER omit any field below):
- rating ("green" | "yellow" | "red") + rating_reason (≤ 8 words).
- inflammation_score (0-10; 0-3 anti, 4-6 neutral/mild, 7-10 highly inflammatory) — NEVER null.
- inflammation_triggers: array of 1-3 short tags naming the drivers of inflammation_score. NEVER empty. Pick from: deep_fried, seed_oil, refined_flour, added_sugar, processed_meat, saturated_fat, omega6_high, artificial_additives, omega3_rich, leafy_greens, olive_oil, turmeric, whole_grains, fermented, berries, fatty_fish (free-form accepted).
- glycemic_load (integer per serving; GL = GI × carbs_g / 100; <10 low, 10-19 medium, 20+ high) — null ONLY for near-zero-carb dishes (<2g carbs).
- fodmap_rating ("low" | "medium" | "high" per Monash — high if onion, garlic, wheat, high-lactose dairy, apples/pears, honey, or beans in user-visible quantity) — NEVER null.
- fodmap_reason (≤ 6 words naming the trigger ingredient(s)) — null ONLY when fodmap_rating == "low".
- added_sugar_g (grams of added sugar per serving; excludes naturally-occurring whole-fruit/whole-dairy sugar). Use 0.0 when none. NEVER null.
- is_ultra_processed (bool; NOVA Group 4 → true). NEVER null.
- coach_tip (≤ 18 words, tailored to user's goals — pick-or-skip with why).

RESTAURANT NAME: If the restaurant's name is visible anywhere on the menu image (header, logo, footer), extract it into a top-level "restaurant_name" string. Set "restaurant_name" to null if no name is visible.
{nutrition_ctx_str}{user_ctx_str}

Return ONLY this JSON, no other keys:
{{
    "analysis_type": "menu",
    "restaurant_name": "Tandoor House",
    "sections": [
        {{
            "section_name": "mains",
            "dishes": [
                {{
                    "name": "Tandoori Chicken Half",
                    "price": 14.95,
                    "currency": "USD",
                    "calories": 487,
                    "protein_g": 48.3,
                    "carbs_g": 6.2,
                    "fat_g": 28.7,
                    "weight_g": 220,
                    "detected_allergens": ["milk"],
                    "rating": "green",
                    "rating_reason": "high protein, moderate fat",
                    "inflammation_score": 2,
                    "inflammation_triggers": ["turmeric", "whole_grains"],
                    "glycemic_load": 4,
                    "fodmap_rating": "low",
                    "fodmap_reason": null,
                    "added_sugar_g": 0.0,
                    "is_ultra_processed": false,
                    "coach_tip": "Hits your protein target; skip the naan if possible."
                }}
            ]
        }}
    ]
}}"""

            else:
                # plate mode (default)
                if cache_name:
                    # Dynamic-only prompt (plate schema + guidelines are in cache).
                    # The cached system-instruction covers health score + portion
                    # rules; the inflammation rubric is in the cache too as of the
                    # nutrition_analysis_v1 build. Dynamic prompt just has to name
                    # the fields so the model doesn't silently drop them.
                    prompt = f"""Analyze these food images and provide detailed nutrition estimates.
Identify EVERY distinct food/drink item across all images. Each visually distinct dish, side, sauce, garnish, or beverage is its own food_item — do NOT collapse multiple foods into one entry. If two images show different dishes, return separate items for each.

Current time suggests this is likely {suggested_meal}.
{nutrition_ctx_str}{user_ctx_str}{instruction_block}

Use the plate analysis JSON schema from your cached reference.
When the user supplied an instruction above, also return a top-level
`applied_instruction_note` string summarizing what the instruction changed
(or null if it changed nothing).

REQUIRED per food_item (NEVER omit):
- name, amount, calories, protein_g, carbs_g, fat_g, fiber_g, weight_g
- For COUNTABLE items (discrete pieces: breadsticks, samosas, eggs, nuggets, cookies, sushi rolls, dumplings, slices of pizza, tacos, wings, meatballs, falafel, etc.) ALWAYS set count = number of pieces visible AND weight_per_unit_g = grams per piece. weight_g must equal count × weight_per_unit_g. Example: 3 breadsticks → count=3, weight_per_unit_g=40, weight_g=120. For NON-COUNTABLE items (rice, soup, pasta heap, salad, fries pile) leave count=null and weight_per_unit_g=null.
- inflammation_score (1-10, 10 = most inflammatory) — NEVER null.
- inflammation_triggers: array of 1-3 short tags naming the drivers. NEVER empty. Pick from: deep_fried, seed_oil, refined_flour, added_sugar, processed_meat, saturated_fat, omega6_high, artificial_additives, omega3_rich, leafy_greens, olive_oil, turmeric, whole_grains, fermented, berries, fatty_fish (free-form accepted).
- is_ultra_processed (bool; NOVA Group 4 → true). NEVER null.
- glycemic_load (integer per serving, GI × carbs_g / 100; <10 low, 10-19 medium, 20+ high) — null ONLY for near-zero-carb items (<2g carbs).
- fodmap_rating ("low" | "medium" | "high" per Monash) — NEVER null.
- fodmap_reason (≤ 6 words naming the trigger ingredient(s)) — null ONLY when fodmap_rating == "low".
- added_sugar_g (grams of added sugar per serving, excludes whole-fruit/whole-dairy sugars). Use 0.0 when none. NEVER null.

REQUIRED meal-level fields: total_calories, total_protein_g, total_carbs_g, total_fat_g, total_fiber_g, health_score (1-10), inflammation_score (1-10, calorie-weighted average of items), inflammation_triggers (up to 3 dominant drivers across items), is_ultra_processed (true if meal is predominantly NOVA Group 4), glycemic_load (sum of per-item glycemic_loads, treat null as 0), fodmap_rating (highest rating among items — "high" wins), added_sugar_g (sum across items), feedback.

Return valid JSON."""
                else:
                    prompt = f"""Analyze these food images and provide detailed nutrition estimates.
Identify EVERY distinct food/drink item across all images. Each visually distinct dish, side, sauce, garnish, or beverage gets its own food_item entry — do NOT merge multiple foods into one. If two images show different dishes, return separate items for each.

Current time suggests this is likely {suggested_meal}.
{nutrition_ctx_str}{user_ctx_str}{instruction_block}

Return ONLY valid JSON with this exact structure:
{{
    "analysis_type": "plate",
    "meal_type": "breakfast" | "lunch" | "dinner" | "snack",
    "food_items": [
        {{
            "name": "food name",
            "amount": "estimated amount (e.g., '1 cup', '150g')",
            "calories": 0,
            "protein_g": 0.0,
            "carbs_g": 0.0,
            "fat_g": 0.0,
            "fiber_g": 0.0,
            "weight_g": 0,
            "count": null,
            "weight_per_unit_g": null,
            "inflammation_score": 5,
            "inflammation_triggers": ["whole_grains"],
            "is_ultra_processed": false,
            "glycemic_load": 8,
            "fodmap_rating": "low",
            "fodmap_reason": null,
            "added_sugar_g": 0.0
        }}
    ],
    "total_calories": 0,
    "total_protein_g": 0.0,
    "total_carbs_g": 0.0,
    "total_fat_g": 0.0,
    "total_fiber_g": 0.0,
    "health_score": 5,
    "inflammation_score": 5,
    "inflammation_triggers": ["whole_grains"],
    "is_ultra_processed": false,
    "glycemic_load": 12,
    "fodmap_rating": "low",
    "fodmap_reason": null,
    "added_sugar_g": 0.0,
    "feedback": "Brief coaching feedback",
    "applied_instruction_note": null
}}

Guidelines:
- Be realistic with portion estimates
- Health score: 1-3 (poor), 4-6 (average), 7-8 (good), 9-10 (excellent)
- Inflammation score (1-10, 10 = most inflammatory):
  1-2 strongly anti-inflammatory (wild salmon, turmeric, berries, leafy greens, olive oil)
  3-4 mildly anti-inflammatory (most vegetables, whole grains, nuts, legumes, plain yogurt)
  5 neutral (plain eggs, plain rice, plain chicken breast, milk)
  6-7 mildly inflammatory (white bread, red meat, cheese, fried foods, butter)
  8-9 moderately inflammatory (processed meats, fast food, sugary drinks, packaged snacks, instant noodles)
  10 highly inflammatory (deep-fried ultra-processed combos, trans-fat items, candy+soda meals)
- is_ultra_processed: true if the food would be NOVA Group 4 (industrial emulsifiers, hydrogenated oils, artificial sweeteners, HFCS, protein isolates, modified starches). Homemade/whole foods are false.
- Glycemic load per item = GI × carbs_g / 100, rounded to nearest int. Examples: white rice 1 cup ≈ 23 (high), oatmeal 1 cup ≈ 13 (medium), broccoli 1 cup ≈ 1 (low). Null if the item is essentially carb-free (meat, oil, cheese).
- FODMAP rating per item (Monash University scale):
  low = meat, eggs, rice, oats, most nuts and seeds, hard cheeses, banana (unripe), berries, oranges, cucumber, carrot, zucchini, spinach
  medium = avocado (small), sweet potato, almond (serving-dependent), certain dairy portions
  high = onion, garlic, wheat/rye/barley pasta & bread, high-lactose dairy (milk, ice cream), apples, pears, mango, honey, beans/lentils in large quantity, cauliflower
  fodmap_reason names the primary trigger(s) in ≤ 6 words, or null when rating is low.
- Meal-level inflammation_score = calorie-weighted average of per-item scores, rounded to nearest int.
- Meal-level is_ultra_processed = true if any item is ultra-processed AND their combined calories dominate.
- Meal-level glycemic_load = sum of per-item glycemic_loads (treat null as 0).
- Meal-level fodmap_rating = highest rating among items (high > medium > low). fodmap_reason = concat of triggers across items.
- Feedback should be constructive and encouraging"""

            # Step 5: Call Gemini with all images.
            # Menu + buffet need larger output headroom because responses can
            # contain 30-60+ dishes (chain restaurants, multi-page menus).
            # Bumped from 16k → 48k after a real menu only returned 5 of ~25
            # dishes — the cap was clipping the response mid-section. Gemini
            # 3 Flash supports 64k output; 48k leaves slack for retries and
            # keeps cost bounded. Plate stays at 4k.
            max_tokens = 48000 if analysis_mode in ("menu", "buffet") else 4000

            # Bind a Pydantic response_schema per mode so Gemini MUST emit
            # every required health field (inflammation_score +
            # inflammation_triggers + glycemic_load + fodmap_rating +
            # fodmap_reason + added_sugar_g + is_ultra_processed). Without the
            # schema the model silently drops fields on ~10-20% of dishes
            # and the Health Strip ends up gap-riddled. Plate mode cannot
            # use response_schema when the cached nutrition_analysis_v1
            # cache is active — the two are mutually exclusive per google-genai
            # — so plate falls back to prompt-only and relies on the
            # post-response fallback below.
            schema_by_mode = {
                "menu": MenuAnalysisResponse,
                "buffet": BuffetAnalysisResponse,
                "plate": FoodAnalysisResponse,
            }
            response_schema = None
            if analysis_mode in ("menu", "buffet"):
                response_schema = schema_by_mode[analysis_mode]
            elif analysis_mode == "plate" and not cache_name:
                response_schema = schema_by_mode["plate"]

            gen_config = types.GenerateContentConfig(
                temperature=0.2,
                response_mime_type="application/json",
                max_output_tokens=max_tokens,
                thinking_config=types.ThinkingConfig(thinking_budget=0),  # thinking off — see L306
                **({"response_schema": response_schema} if response_schema else {}),
            )
            if cache_name:
                gen_config.cached_content = cache_name

            logger.info(
                f"Multi-image food analysis: mode={analysis_mode}, "
                f"cache={'yes' if cache_name else 'no'}, max_tokens={max_tokens}"
            )

            response = await gemini_generate_with_retry(
                model=self.model,
                contents=[prompt] + image_parts,
                config=gen_config,
                method_name="vision_analyze_food_s3",
            )

            content = response.text.strip()
            logger.info(f"Multi-image food analysis response received ({len(content)} chars)")
            try:
                result = json.loads(content)
            except json.JSONDecodeError as parse_err:
                # Likely truncated JSON. Try to salvage for menu/buffet where we
                # can drop the last incomplete dish and re-close the arrays.
                if analysis_mode in ("menu", "buffet"):
                    salvaged = _salvage_truncated_menu_json(content, analysis_mode)
                    if salvaged is not None:
                        logger.warning(
                            f"Salvaged truncated {analysis_mode} JSON: "
                            f"recovered {_count_dishes(salvaged)} dishes"
                        )
                        result = salvaged
                    else:
                        raise parse_err
                else:
                    raise parse_err

            # Normalize plate mode results for compatibility
            if analysis_mode == "plate":
                result.setdefault("meal_type", suggested_meal)
                result.setdefault("food_items", [])
                result.setdefault("total_calories", 0)
                result.setdefault("total_protein_g", 0.0)
                result.setdefault("total_carbs_g", 0.0)
                result.setdefault("total_fat_g", 0.0)
                result.setdefault("total_fiber_g", 0.0)
                result.setdefault("health_score", 5)
                if not result.get("health_score_reasons"):
                    result["health_score_reasons"] = ["ai_unavailable"]
                result.setdefault("feedback", "")
                # Add non-prefixed versions
                result["protein_g"] = result.get("total_protein_g", 0.0)
                result["carbs_g"] = result.get("total_carbs_g", 0.0)
                result["fat_g"] = result.get("total_fat_g", 0.0)
                result["fiber_g"] = result.get("total_fiber_g", 0.0)

                # Meal-level inflammation fallback. Gemini sometimes fills
                # per-item scores but drops the meal-level aggregate on
                # plate mode (especially with the cached schema). Compute
                # the calorie-weighted average from per-item scores when
                # meal-level is null so the client can always show the badge.
                items = result.get("food_items") or []
                if result.get("inflammation_score") is None:
                    meal_infl, meal_upf = compute_meal_inflammation(items)
                    if meal_infl is not None:
                        result["inflammation_score"] = meal_infl
                    if result.get("is_ultra_processed") is None and meal_upf is not None:
                        result["is_ultra_processed"] = meal_upf
                if result.get("inflammation_score") is None:
                    logger.warning(
                        f"[vision_analyze_food_s3] inflammation_score null after fallback; "
                        f"items={len(items)} mode={analysis_mode}"
                    )

            # Post-schema sanity: even with response_schema enforcement, log a
            # warning if any menu/buffet dish arrives without the required
            # health signals. These shouldn't fire once the schema lands but
            # the warning lets us catch schema-bypass regressions early.
            # Also apply deterministic fallbacks for added_sugar_g (default
            # 0.0) and inflammation_triggers (derived from the score band) so
            # the client-side Health Strip is never blank.
            if analysis_mode in ("menu", "buffet"):
                dishes = _iter_menu_dishes(result)
                for dish in dishes:
                    _apply_dish_health_fallbacks(dish)
                    _log_dish_if_missing_fields(dish, analysis_mode)
                # Guarantee restaurant_name is present on the result so the
                # streaming layer can carry it through. Treat a missing key
                # (Gemini omitted it) or an empty string as null — no fallback.
                rn = result.get("restaurant_name")
                result["restaurant_name"] = rn if (isinstance(rn, str) and rn.strip()) else None

            result["analysis_type"] = analysis_mode
            # L2+L3 portion validation across all entry shapes.
            if analysis_mode == "plate":
                result["food_items"] = _safe_finalize(result.get("food_items") or [], "multi_image_plate")
            elif analysis_mode == "buffet":
                result["dishes"] = _safe_finalize(result.get("dishes") or [], "multi_image_buffet")
            elif analysis_mode == "menu":
                for section in (result.get("sections") or []):
                    if isinstance(section, dict):
                        section["dishes"] = _safe_finalize(section.get("dishes") or [], "multi_image_menu")
            logger.info(f"Multi-image food analysis complete: mode={analysis_mode}")
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse multi-image JSON response: {e}", exc_info=True)
            raise ValueError(f"Invalid JSON in multi-image vision response: {e}")
        except Exception as e:
            logger.error(f"Multi-image food analysis failed: {e}", exc_info=True)
            raise

    async def analyze_app_screenshot(
        self,
        image_base64: str = None,
        s3_key: str = None,
        mime_type: str = "image/jpeg",
        user_context: Optional[str] = None,
    ) -> dict:
        """
        Analyze a screenshot from a nutrition/fitness app (MyFitnessPal, Cronometer, etc.).
        OCR extracts food entries with calories and macros.
        """
        suggested_meal = self._get_suggested_meal_type()

        prompt = f"""You are an expert OCR system for nutrition app screenshots.
Analyze this screenshot from a nutrition/fitness tracking app.

TASKS:
1. Identify the source app (MyFitnessPal, Cronometer, LoseIt, Samsung Health, etc.)
2. Extract ALL food entries visible with their calories and macros — log EVERY
   food row, never silently collapse a multi-food screenshot into one item.
3. Determine the meal type from context or time-based suggestion: {suggested_meal}
4. CONTENT CHECK: if this screenshot is actually a RECIPE (ingredient list +
   cooking steps) or a generic web page / chat — NOT a nutrition-tracking panel
   — set "content_kind" to "recipe" or "not_nutrition" and leave food_items empty.
5. If calorie/macro values are cut off, glared, or unreadable, list those field
   names in "unreadable_fields" and keep your best estimate (do not invent
   precise numbers for a field you cannot see).
6. Detect units: if the screenshot shows energy in kilojoules (kJ), convert to
   kcal (1 kcal = 4.184 kJ) and note "kj_converted" in "unit_notes".

{f'User says: "{user_context}"' if user_context else ''}

Return ONLY valid JSON with this exact structure:
{{
    "content_kind": "nutrition_panel" | "recipe" | "not_nutrition",
    "source_app": "app name or unknown",
    "meal_type": "breakfast" | "lunch" | "dinner" | "snack",
    "food_items": [
        {{
            "name": "food name",
            "amount": "amount as shown in app",
            "calories": <integer>,
            "protein_g": <float>,
            "carbs_g": <float>,
            "fat_g": <float>
        }}
    ],
    "total_calories": <integer>,
    "total_protein_g": <float>,
    "total_carbs_g": <float>,
    "total_fat_g": <float>,
    "total_fiber_g": <float>,
    "unreadable_fields": ["names of fields that were glared/cut-off, empty if clean"],
    "unit_notes": ["e.g. kj_converted, per_100g_normalized — empty if none"],
    "low_confidence": <true if the screenshot layout is unknown or values are shaky>,
    "health_score": <integer 1-10>,
    "health_score_reasons": ["1-5 tags from: high_protein, high_fiber, anti_inflammatory, low_added_sugar, balanced_macros (positives) | ultra_processed, deep_fried, refined_flour, added_sugar, high_sodium, high_glycemic, low_fiber, processed_meat, trans_fat (negatives)"]
}}

Guidelines:
- Extract exact values shown in the app when visible
- If macros are partially visible, estimate from calories and food type
- Health score based on overall meal quality
- health_score_reasons must contain 1-5 short tags explaining WHY the meal earned its score
- Keep output strictly to the JSON — no prose, no commentary"""

        try:
            logger.info("Analyzing app screenshot with Gemini OCR")

            # Resolve image bytes
            if image_base64:
                image_bytes = base64.b64decode(image_base64)
            elif s3_key:
                image_bytes = await self._download_image_from_s3(s3_key)
            else:
                raise ValueError("Either image_base64 or s3_key must be provided")

            image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)

            response = await gemini_generate_with_retry(
                model=self.model,
                contents=[prompt, image_part],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=1500,
                    thinking_config=types.ThinkingConfig(thinking_budget=0),  # thinking off — see L306
                    temperature=0.2,
                ),
                method_name="vision_analyze_app_screenshot",
            )

            content = response.text.strip()
            result = json.loads(content)

            # Validate required fields
            for field in ["meal_type", "food_items", "total_calories", "total_protein_g", "total_carbs_g", "total_fat_g"]:
                if field not in result:
                    result[field] = self._get_default_value(field)

            result.setdefault("source_app", "unknown")
            result.setdefault("content_kind", "nutrition_panel")
            result.setdefault("unreadable_fields", [])
            result.setdefault("unit_notes", [])
            result.setdefault("low_confidence", False)
            result.setdefault("total_fiber_g", 0.0)
            result.setdefault("health_score", 5)
            # Health-score reasons must always be present so the ScoreExplainSheet
            # has something to render. If Gemini omitted them we tag the row as
            # ai_unavailable rather than leaving an empty list — the frontend
            # uses that sentinel to show a graceful fallback message.
            if not result.get("health_score_reasons"):
                result["health_score_reasons"] = ["ai_unavailable"]
            result.setdefault("feedback", "")

            # Add non-prefixed versions for consistency
            result["protein_g"] = result.get("total_protein_g", 0.0)
            result["carbs_g"] = result.get("total_carbs_g", 0.0)
            result["fat_g"] = result.get("total_fat_g", 0.0)
            result["fiber_g"] = result.get("total_fiber_g", 0.0)

            # L2+L3 portion validation (no DB rows in OCR flow).
            result["food_items"] = _safe_finalize(result.get("food_items") or [], "app_screenshot_ocr")

            logger.info(
                f"App screenshot analysis complete: {result['total_calories']} cal, "
                f"{len(result.get('food_items', []))} items from {result.get('source_app', 'unknown')}"
            )
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse app screenshot JSON: {e}", exc_info=True)
            raise ValueError(f"Invalid JSON in app screenshot response: {e}")
        except Exception as e:
            logger.error(f"App screenshot analysis failed: {e}", exc_info=True)
            raise

    async def analyze_nutrition_label(
        self,
        image_base64: str = None,
        s3_key: str = None,
        mime_type: str = "image/jpeg",
        servings_consumed: float = 1.0,
        user_context: Optional[str] = None,
        images_base64: Optional[List[str]] = None,
    ) -> dict:
        """
        Analyze a nutrition facts label from food packaging.
        Reads per-serving macros and multiplies by servings_consumed.

        Gap 4 — multi-photo stitching: when ``images_base64`` carries more than
        one photo, they are treated as pieces of the SAME label (e.g. a panel
        wrapped around a bottle) and stitched into one set of facts. The result
        carries ``label_complete`` — false when key rows are still cut off, so
        the client can prompt for another photo.
        """
        suggested_meal = self._get_suggested_meal_type()

        # Normalize to a list of photos. images_base64 (multi) wins; else the
        # single image_base64; else an s3_key resolved below.
        photos_b64 = [b for b in (images_base64 or []) if b]
        if not photos_b64 and image_base64:
            photos_b64 = [image_base64]
        is_multi = len(photos_b64) > 1

        multi_note = (
            f"\nYou are given {len(photos_b64)} photos. They are pieces of the "
            "SAME nutrition label captured separately (e.g. the panel wraps "
            "around a bottle). Stitch them into ONE complete set of facts — do "
            "NOT add them together as if they were different products.\n"
            if is_multi else ""
        )

        prompt = f"""You are an expert OCR system for nutrition facts labels.
Analyze this nutrition facts label from food packaging.
{multi_note}
TASKS:
1. Read the product name and brand if visible. If a packaging SIZE descriptor is
   printed on the front (e.g. "King Size", "Share Size", "Fun Size", "Family
   Size", "Party Size"), INCLUDE it in "product_name" (e.g. "Almond Joy King
   Size") — it is a distinct product with its own net weight, not optional.
2. Extract serving size and servings per container
3. Extract ALL nutrition facts PER SERVING (the values printed on the label)
4. The user consumed {servings_consumed} serving(s) - multiply all values accordingly
5. UNIT DETECTION: if energy is given in kilojoules (kJ) instead of kcal,
   convert (1 kcal = 4.184 kJ). If the panel is "per 100g" rather than
   "per serving", normalize to the stated serving size. Record what you did
   in "unit_notes".
6. GLARE / CUT-OFF: if a value is obscured by glare or cropped off the image,
   add that field name to "unreadable_fields" and keep your best estimate —
   do NOT fabricate a precise number you cannot read.
7. MULTI-SERVING: always report "servings_per_container" so the app can
   confirm the user did not log the whole package by mistake.
8. COMPLETENESS: set "label_complete" to false if the core panel (calories +
   the macro rows: protein, carbs, fat) is still partly cut off or unreadable
   across ALL provided photos — i.e. another photo would meaningfully help.
   Set it true when the essential facts are fully captured.

{f'User says: "{user_context}"' if user_context else ''}

Return ONLY valid JSON with this exact structure:
{{
    "product_name": "product name or unknown",
    "brand": "brand name if printed, else null",
    "serving_size": "serving size as shown on label",
    "servings_per_container": <float or null>,
    "per_serving_calories": <integer per single serving>,
    "unreadable_fields": ["names of glared/cut-off fields, empty if clean"],
    "unit_notes": ["e.g. kj_converted, per_100g_normalized — empty if none"],
    "low_confidence": <true if the label is hard to read>,
    "label_complete": <true if the core panel is fully captured, false if another photo would help>,
    "meal_type": "{suggested_meal}",
    "food_items": [
        {{
            "name": "product name",
            "amount": "{servings_consumed} serving(s)",
            "calories": <integer - per serving * {servings_consumed}>,
            "protein_g": <float - per serving * {servings_consumed}>,
            "carbs_g": <float - per serving * {servings_consumed}>,
            "fat_g": <float - per serving * {servings_consumed}>
        }}
    ],
    "total_calories": <integer - total for {servings_consumed} servings>,
    "total_protein_g": <float>,
    "total_carbs_g": <float>,
    "total_fat_g": <float>,
    "total_fiber_g": <float>,
    "health_score": <integer 1-10>
}}

Guidelines:
- Read exact values from the label
- Multiply ALL values by {servings_consumed} servings consumed
- Health score based on nutritional quality
- Keep output strictly to the JSON — no prose, no commentary"""

        try:
            logger.info(
                f"Analyzing nutrition label ({servings_consumed} servings, "
                f"{len(photos_b64) or 1} photo(s)) with Gemini OCR"
            )

            # Resolve image bytes for every provided photo (multi-photo stitch).
            image_parts = []
            if photos_b64:
                for b64 in photos_b64:
                    image_parts.append(
                        types.Part.from_bytes(
                            data=base64.b64decode(b64), mime_type=mime_type
                        )
                    )
            elif s3_key:
                image_bytes = await self._download_image_from_s3(s3_key)
                image_parts.append(
                    types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
                )
            else:
                raise ValueError("Either image_base64/images_base64 or s3_key must be provided")

            response = await gemini_generate_with_retry(
                model=self.model,
                contents=[prompt, *image_parts],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=1200,
                    thinking_config=types.ThinkingConfig(thinking_budget=0),  # thinking off — see L306
                    temperature=0.2,
                ),
                method_name="vision_analyze_nutrition_label",
            )

            content = response.text.strip()
            result = json.loads(content)

            # Validate required fields
            for field in ["meal_type", "food_items", "total_calories", "total_protein_g", "total_carbs_g", "total_fat_g"]:
                if field not in result:
                    result[field] = self._get_default_value(field)

            result.setdefault("product_name", "unknown")
            result.setdefault("brand", None)
            result.setdefault("serving_size", "unknown")
            result.setdefault("servings_per_container", None)
            result.setdefault("per_serving_calories", None)
            result.setdefault("unreadable_fields", [])
            result.setdefault("unit_notes", [])
            result.setdefault("low_confidence", False)
            # Gap 4 — default to complete so a model that omits the field never
            # nags the user for more photos; only an explicit false prompts one.
            result.setdefault("label_complete", True)
            result.setdefault("total_fiber_g", 0.0)
            result.setdefault("health_score", 5)
            if not result.get("health_score_reasons"):
                result["health_score_reasons"] = ["ai_unavailable"]
            result.setdefault("feedback", "")

            # Add non-prefixed versions for consistency
            result["protein_g"] = result.get("total_protein_g", 0.0)
            result["carbs_g"] = result.get("total_carbs_g", 0.0)
            result["fat_g"] = result.get("total_fat_g", 0.0)
            result["fiber_g"] = result.get("total_fiber_g", 0.0)

            # L2+L3 portion validation (no DB rows in label OCR flow).
            result["food_items"] = _safe_finalize(result.get("food_items") or [], "nutrition_label_ocr")

            # Fix A — descriptive serving unit + count card for label scans.
            # The OCR result carries the label's own "Serving size 1/4 Pizza
            # (138g)" + "8 servings per container", but the per-item dicts above
            # ship only "1 serving(s)" with NO weight, so the app could only show
            # a generic unit. Parse the serving descriptor + per-serving grams and
            # attach serving_label / servings_per_container / weight_per_unit_g /
            # count / weight_g so the card renders "1/4 pizza = 138g" + a
            # "N per container" caption and supports count scaling.
            try:
                from services.gemini.parsers import parse_serving_label as _psl
                _sl = _psl(result.get("serving_size"))
                _serv_label = _sl.get("serving_label")
                _per_serv_g = _sl.get("grams")
                _spc = result.get("servings_per_container")
                _spc_int = int(_spc) if isinstance(_spc, (int, float)) and _spc >= 1 else None
                _count = int(servings_consumed) if float(servings_consumed).is_integer() and servings_consumed >= 1 else None
                for _fi in result["food_items"]:
                    if not isinstance(_fi, dict):
                        continue
                    if _serv_label and not _fi.get("serving_label"):
                        _fi["serving_label"] = _serv_label
                    if _spc_int is not None:
                        _fi["servings_per_container"] = _spc_int
                    if _per_serv_g and _per_serv_g > 0 and not _fi.get("weight_g"):
                        _fi["weight_per_unit_g"] = _per_serv_g
                        if _count:
                            _fi["count"] = _count
                            _fi["weight_g"] = round(_per_serv_g * _count, 1)
                            _fi["portion_basis"] = "by_count"
            except Exception as _sl_err:
                logger.debug(f"[label-ocr] serving-label enrichment skipped: {_sl_err}")

            logger.info(
                f"Nutrition label analysis complete: {result['total_calories']} cal "
                f"({servings_consumed} servings of {result.get('product_name', 'unknown')})"
            )
            return result

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse nutrition label JSON: {e}", exc_info=True)
            raise ValueError(f"Invalid JSON in nutrition label response: {e}")
        except Exception as e:
            logger.error(f"Nutrition label analysis failed: {e}", exc_info=True)
            raise

    def _get_default_value(self, field: str):
        """Get default value for missing fields."""
        defaults = {
            "meal_type": "snack",
            "food_items": [],
            "total_calories": 0,
            "total_protein_g": 0.0,
            "total_carbs_g": 0.0,
            "total_fat_g": 0.0,
            "total_fiber_g": 0.0,
            "health_score": 5,
            "feedback": "Unable to fully analyze this image.",
        }
        return defaults.get(field)

    # ============================================================
    # Gym Equipment Importer: document extraction (PDF / DOCX / images)
    # Used by GymEquipmentExtractor in services/gym_equipment_extractor.py.
    # Native Gemini PDF input (no external OCR library). 10-page hard cap.
    # ============================================================

    GYM_EQUIPMENT_EXTRACTION_PROMPT = (
        "You are extracting gym equipment from the provided content. "
        "Identify every distinct machine, free weight, accessory, or training tool mentioned. "
        "Return ONLY a JSON array. Schema:\n"
        "[{\"raw_name\": \"exact text or item name\", "
        "\"quantity\": number or null, "
        "\"weight_range\": \"e.g. '5-100lb'\" or null, "
        "\"confidence\": 0.0-1.0}]\n"
        "Do not invent items. If uncertain, set confidence lower. "
        "Preserve weight units verbatim (lb/kg/lbs) — do not convert. "
        "If nothing found, return []."
    )

    async def extract_equipment_from_document(
        self,
        file_bytes: bytes,
        mime_type: str,
    ) -> list[dict]:
        """Extract a list of raw gym-equipment mentions from a PDF or image document.

        Args:
            file_bytes: Raw bytes of the PDF or image file.
            mime_type: One of 'application/pdf', 'image/jpeg', 'image/png', 'image/webp'.

        Returns:
            List of dicts: [{"raw_name": str, "quantity": Optional[int], "weight_range": Optional[str], "confidence": float}]

        Raises:
            ValueError: If mime_type unsupported, PDF page count > 10, or response is not valid JSON.
            Exception: Any Gemini / network error propagates (no silent fallback).
        """
        allowed_mimes = {
            "application/pdf",
            "image/jpeg", "image/png", "image/webp",
        }
        if mime_type not in allowed_mimes:
            raise ValueError(
                f"❌ extract_equipment_from_document: unsupported mime_type '{mime_type}'. "
                f"Allowed: {sorted(allowed_mimes)}"
            )

        # 10-page hard cap for PDFs
        if mime_type == "application/pdf":
            try:
                import pypdf
                from io import BytesIO
                reader = pypdf.PdfReader(BytesIO(file_bytes))
                page_count = len(reader.pages)
                logger.info(f"🏋️ [EquipmentDoc] PDF page count: {page_count}")
                if page_count > 10:
                    raise ValueError(
                        f"PDF has {page_count} pages — exceeds the 10-page limit for equipment import. "
                        f"Please trim the document or split it across multiple uploads."
                    )
            except ValueError:
                raise
            except Exception as e:
                # pypdf failed to parse — surface the error rather than silently passing garbage to Gemini
                logger.error(f"❌ [EquipmentDoc] pypdf failed to parse PDF: {e}", exc_info=True)
                raise ValueError(f"Could not parse PDF: {e}") from e

        logger.info(
            f"🏋️ [EquipmentDoc] Extracting equipment (mime={mime_type}, size={len(file_bytes)} bytes)"
        )

        try:
            part = types.Part.from_bytes(data=file_bytes, mime_type=mime_type)
            response = await gemini_generate_with_retry(
                model=self.model,
                contents=[self.GYM_EQUIPMENT_EXTRACTION_PROMPT, part],
                config=types.GenerateContentConfig(
                    temperature=0.1,
                    # Large enough for ~100 items at ~40 tokens each plus JSON overhead.
                    max_output_tokens=8000,
                    thinking_config=types.ThinkingConfig(thinking_budget=0),  # thinking off — see L306
                    response_mime_type="application/json",
                ),
                method_name="vision_extract_equipment_document",
            )

            text = (response.text or "").strip()
            # Strip ```json fences defensively (response_mime_type usually prevents this,
            # but Gemini occasionally wraps output anyway).
            if text.startswith("```"):
                import re as _re
                text = _re.sub(r"^```(?:json)?\s*", "", text)
                text = _re.sub(r"\s*```$", "", text)

            try:
                parsed = json.loads(text)
            except json.JSONDecodeError as e:
                logger.error(
                    f"❌ [EquipmentDoc] Gemini returned non-JSON: {text[:300]}", exc_info=True
                )
                raise ValueError(f"Gemini returned invalid JSON for equipment extraction: {e}") from e

            if not isinstance(parsed, list):
                logger.warning(
                    f"⚠️ [EquipmentDoc] Expected list, got {type(parsed).__name__}; coercing to []"
                )
                return []

            # Defensive shape-normalization; drop malformed entries.
            cleaned: list[dict] = []
            for item in parsed:
                if not isinstance(item, dict):
                    continue
                raw_name = (item.get("raw_name") or "").strip()
                if not raw_name:
                    continue
                try:
                    confidence = float(item.get("confidence") or 0.5)
                except (TypeError, ValueError):
                    confidence = 0.5
                confidence = max(0.0, min(1.0, confidence))
                cleaned.append({
                    "raw_name": raw_name,
                    "quantity": item.get("quantity"),
                    "weight_range": item.get("weight_range"),
                    "confidence": confidence,
                })

            logger.info(f"✅ [EquipmentDoc] Extracted {len(cleaned)} raw equipment items")
            return cleaned

        except ValueError:
            raise
        except Exception as e:
            logger.error(f"❌ [EquipmentDoc] Extraction failed: {e}", exc_info=True)
            raise


# Singleton instance
_vision_service: Optional[VisionService] = None


def get_vision_service() -> VisionService:
    """Get the singleton VisionService instance."""
    global _vision_service
    if _vision_service is None:
        _vision_service = VisionService()
    return _vision_service
