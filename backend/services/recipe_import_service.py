"""
Recipe Import Service
=====================
Parses external recipes from three sources, normalizes to RecipeCreate:
  1) URL    — fetched with httpx, main content extracted with trafilatura, parsed by Gemini
  2) Text   — pasted free-text recipe, parsed by Gemini
  3) Image  — handwritten or printed recipe photo, OCR + structured by Gemini Vision

Each path:
  - Streams progress events (steps: fetching → extracting → parsing → matching → done)
  - Returns a RecipeCreate ready for POST /nutrition/recipes
  - Sets source_type to imported_url / imported_text / imported_handwritten
  - Records ingredient nutrition_source as ai_estimate (recipe builder will refresh later)
  - Throws explicit errors on low confidence (no silent garbage)
"""

import asyncio
import json
import logging
import re
from typing import AsyncIterator, Dict, List, Optional

import httpx

from models.recipe import (
    CookingMethod,
    NutritionSource,
    RecipeCategory,
    RecipeCreate,
    RecipeIngredientCreate,
    RecipeSourceType,
)
from services.gemini.service import GeminiService
from services.gemini_text_helper import gemini_text
from services.ingredient_analyzer_service import get_ingredient_analyzer
from services.vision_service import VisionService

logger = logging.getLogger(__name__)

# Heuristic: minimum confidence the import reached a "this is actually a recipe" state
_MIN_RECIPE_CONFIDENCE = 60

_RECIPE_PARSE_PROMPT = """You are a strict recipe parser. Given the input, return ONLY valid JSON
with this exact schema (no markdown, no commentary):
{
  "is_recipe": true|false,
  "confidence": 0-100,
  "recipe": {
    "name": "...",
    "description": "...",
    "servings": 1,
    "prep_time_minutes": 0,
    "cook_time_minutes": 0,
    "cuisine": "...",
    "category": "breakfast|lunch|dinner|snack|dessert|drink|other",
    "cooking_method": "raw|baked|grilled|fried|boiled|steamed|roasted|sauteed|slow_cooked|pressure_cooked|air_fried|smoked|other|null",
    "instructions": "Step 1. ...\\nStep 2. ...",
    "tags": [],
    "ingredients": [
      {"food_name": "...", "amount": 1.0, "unit": "g|oz|cup|tbsp|tsp|ml|piece", "notes": "optional"}
    ]
  }
}
If the input is not a recipe (e.g., random article, shopping list, blog intro only), set is_recipe=false and recipe=null.
"""


def _strip_markdown_json(text: str) -> str:
    """Gemini sometimes wraps JSON in ```json fences; strip them."""
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
    return text


class RecipeImportService:
    """Three-mode recipe importer with streaming progress."""

    def __init__(self):
        self.gemini = GeminiService()
        self.vision = VisionService()
        self.analyzer = get_ingredient_analyzer()

    # ------------------------------------------------------------------
    # URL import
    # ------------------------------------------------------------------

    async def import_url(
        self, url: str, user_id: Optional[str] = None
    ) -> AsyncIterator[Dict]:
        yield {"step": "fetching", "message": f"Fetching {url}"}

        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.get(
                    url,
                    follow_redirects=True,
                    headers={"User-Agent": "FitWiz Recipe Importer"},
                )
                resp.raise_for_status()
                html = resp.text
        except Exception as exc:
            yield {"step": "error", "message": f"Could not fetch URL: {exc}"}
            return

        yield {"step": "extracting", "message": "Extracting main content"}

        # Use trafilatura for main-content extraction; fall back to raw HTML head
        try:
            import trafilatura

            extracted = trafilatura.extract(html, include_images=False) or ""
        except Exception:
            # Strip tags as a last resort; recipe parser only needs text
            extracted = re.sub(r"<[^>]+>", " ", html)
            extracted = re.sub(r"\s+", " ", extracted)[:8000]

        if not extracted or len(extracted) < 80:
            yield {"step": "error", "message": "Page content was too short to parse"}
            return

        async for event in self._parse_text_to_recipe(
            extracted, user_id, source_type=RecipeSourceType.IMPORTED_URL, source_url=url
        ):
            yield event

    # ------------------------------------------------------------------
    # Text import
    # ------------------------------------------------------------------

    async def import_text(
        self, text: str, user_id: Optional[str] = None
    ) -> AsyncIterator[Dict]:
        yield {"step": "parsing", "message": "Parsing recipe text"}
        async for event in self._parse_text_to_recipe(
            text, user_id, source_type=RecipeSourceType.IMPORTED_TEXT
        ):
            yield event

    # ------------------------------------------------------------------
    # Handwritten image import
    # ------------------------------------------------------------------

    async def import_handwritten(
        self, image_b64: str, user_id: Optional[str] = None
    ) -> AsyncIterator[Dict]:
        yield {"step": "ocr", "message": "Reading handwriting…"}

        ocr_text = await self.vision.extract_handwritten_recipe(image_b64)
        if not ocr_text or len(ocr_text) < 30:
            yield {"step": "error", "message": "Couldn't read enough text from the image"}
            return

        yield {"step": "parsing", "message": "Structuring recipe"}
        async for event in self._parse_text_to_recipe(
            ocr_text, user_id, source_type=RecipeSourceType.IMPORTED_HANDWRITTEN
        ):
            yield event

    # ------------------------------------------------------------------
    # Shared text → recipe with ingredient analysis
    # ------------------------------------------------------------------

    async def _parse_text_to_recipe(
        self,
        text: str,
        user_id: Optional[str],
        source_type: RecipeSourceType,
        source_url: Optional[str] = None,
    ) -> AsyncIterator[Dict]:
        # 1) Ask Gemini to extract structured recipe
        try:
            raw = await gemini_text(
                f"{_RECIPE_PARSE_PROMPT}\n\nINPUT:\n{text[:8000]}",
                temperature=0.2,
                method_name="recipe_import_parse",
            )
            parsed = json.loads(_strip_markdown_json(raw))
        except Exception as exc:
            logger.exception("[RecipeImport] Gemini parse failed")
            yield {"step": "error", "message": f"Couldn't parse recipe: {exc}"}
            return

        if not parsed.get("is_recipe") or (parsed.get("confidence", 0) < _MIN_RECIPE_CONFIDENCE):
            yield {
                "step": "error",
                "message": "This doesn't look like a recipe. Try pasting the recipe content directly.",
            }
            return

        recipe = parsed.get("recipe") or {}
        ingredients_raw = recipe.get("ingredients") or []

        yield {
            "step": "analyzing",
            "message": f"Estimating nutrition for {len(ingredients_raw)} ingredients",
        }

        ingredients: List[RecipeIngredientCreate] = []
        for idx, ing in enumerate(ingredients_raw[:50]):
            ing_text = f"{ing.get('amount', '')} {ing.get('unit', '')} {ing.get('food_name', '')}".strip()
            try:
                from models.recipe import IngredientAnalyzeRequest

                analyzed = await self.analyzer.analyze_one(
                    IngredientAnalyzeRequest(text=ing_text, user_id=user_id)
                )
                ingredients.append(
                    RecipeIngredientCreate(
                        ingredient_order=idx,
                        food_name=analyzed.food_name,
                        brand=analyzed.brand,
                        amount=analyzed.amount,
                        unit=analyzed.unit,
                        amount_grams=analyzed.amount_grams,
                        calories=analyzed.calories,
                        protein_g=analyzed.protein_g,
                        carbs_g=analyzed.carbs_g,
                        fat_g=analyzed.fat_g,
                        fiber_g=analyzed.fiber_g,
                        sugar_g=analyzed.sugar_g,
                        sodium_mg=analyzed.sodium_mg,
                        calcium_mg=analyzed.calcium_mg,
                        iron_mg=analyzed.iron_mg,
                        omega3_g=analyzed.omega3_g,
                        vitamin_d_iu=analyzed.vitamin_d_iu,
                        cooking_method=analyzed.cooking_method,
                        nutrition_source=analyzed.nutrition_source,
                        nutrition_confidence=analyzed.nutrition_confidence,
                        is_negligible=analyzed.is_negligible,
                        raw_text=analyzed.raw_text,
                        notes=ing.get("notes"),
                    )
                )
            except Exception as exc:
                logger.warning("[RecipeImport] ingredient analyze failed: %s", exc)
                # Keep the row as a low-confidence AI estimate so the user can edit
                ingredients.append(
                    RecipeIngredientCreate(
                        ingredient_order=idx,
                        food_name=ing.get("food_name") or ing_text,
                        amount=float(ing.get("amount") or 1),
                        unit=ing.get("unit") or "g",
                        nutrition_source=NutritionSource.AI_ESTIMATE,
                        nutrition_confidence=0,
                        raw_text=ing_text,
                    )
                )

        try:
            category = RecipeCategory(recipe.get("category") or "other")
        except ValueError:
            category = RecipeCategory.OTHER
        try:
            cooking_method_val = recipe.get("cooking_method")
            cooking_method = CookingMethod(cooking_method_val) if cooking_method_val else None
        except ValueError:
            cooking_method = None

        recipe_create = RecipeCreate(
            name=recipe.get("name") or "Imported recipe",
            description=recipe.get("description"),
            servings=int(recipe.get("servings") or 1),
            prep_time_minutes=recipe.get("prep_time_minutes"),
            cook_time_minutes=recipe.get("cook_time_minutes"),
            instructions=recipe.get("instructions"),
            cuisine=recipe.get("cuisine"),
            category=category,
            tags=recipe.get("tags") or [],
            cooking_method=cooking_method,
            source_type=source_type,
            source_url=source_url,
            ingredients=ingredients,
        )

        yield {
            "step": "done",
            "message": "Recipe ready",
            "recipe": recipe_create.model_dump(mode="json"),
            "confidence": parsed.get("confidence", 0),
        }


_singleton: Optional[RecipeImportService] = None


def get_recipe_import_service() -> RecipeImportService:
    global _singleton
    if _singleton is None:
        _singleton = RecipeImportService()
    return _singleton
