"""Gemini-powered enrichment: a logged meal → a full structured recipe.

Used by `POST /api/v1/nutrition/food-logs/{log_id}/save-as-recipe`. Takes the
food_log's `food_items` JSONB + meal `user_query` and asks Gemini to produce a
restaurant-quality recipe — name, cuisine, category, servings, prep/cook
times, step-by-step instructions, and ingredient quantities + units. The
output drops straight into `RecipeCreate` for the persistence helper.

Why a dedicated service: the existing `recipe_suggestion_service.py` produces
NEW recipes from user goals/preferences. We need the inverse — given the
food_items the user already ate, fill in the cooking details. Different prompt
shape, different schema, but same `gemini_generate_with_retry` infrastructure.
"""
from __future__ import annotations

from typing import List, Optional

from google.genai import types
from pydantic import BaseModel, Field

from core.config import get_settings
from core.logger import get_logger
from models.recipe import (
    CookingMethod,
    RecipeCategory,
    RecipeCreate,
    RecipeIngredientCreate,
    RecipeSourceType,
)
from services.gemini.constants import gemini_generate_with_retry

logger = get_logger(__name__)


# ─── Gemini-side schema (what the model returns) ────────────────
# Stays structurally separate from the API-facing RecipeCreate so we can
# keep tight constraints on Gemini output without weakening the public model.

class _EnrichedIngredient(BaseModel):
    # Note: Gemini's Schema class (google-genai) doesn't support
    # `exclusiveMinimum`, so we use `ge=0` here and clamp to a tiny positive
    # value when building the API-facing RecipeIngredientCreate (which DOES
    # require amount > 0).
    food_name: str = Field(..., description="The ingredient name as you'd write on a shopping list")
    amount: float = Field(..., ge=0, description="Numeric quantity (>= 0); 0 means 'to taste' / negligible")
    unit: str = Field(..., description="g | ml | cup | tbsp | tsp | piece | clove | slice | pinch")
    amount_grams: Optional[float] = Field(default=None, description="Approximate grams if known")
    notes: Optional[str] = Field(default=None, description="Optional prep note like 'finely chopped'")
    cooking_method: Optional[str] = Field(
        default=None,
        description="raw | baked | grilled | fried | boiled | steamed | roasted | sauteed | slow_cooked | pressure_cooked | air_fried | smoked | other",
    )


class _EnrichedRecipe(BaseModel):
    """Strict Gemini output schema — everything we need to build a RecipeCreate."""
    name: str = Field(..., max_length=120, description="Concise dish name as you'd see on a menu")
    description: Optional[str] = Field(default=None, max_length=400)
    cuisine: Optional[str] = Field(default=None, max_length=40, description="Indian | Italian | Mexican | …")
    category: str = Field(..., description="breakfast | lunch | dinner | snack | dessert | drink | other")
    servings: int = Field(default=1, ge=1, le=20)
    prep_time_minutes: Optional[int] = Field(default=None, ge=0, le=480)
    cook_time_minutes: Optional[int] = Field(default=None, ge=0, le=480)
    instructions: List[str] = Field(default_factory=list, description="Ordered cooking steps, ~one sentence each")
    ingredients: List[_EnrichedIngredient] = Field(default_factory=list)
    tags: Optional[List[str]] = Field(default_factory=list, description="Optional tags like 'vegetarian','spicy','high-protein'")


_SYSTEM_INSTRUCTION = (
    "You are a culturally-literate professional chef converting a logged meal "
    "into a complete reusable recipe. The user already ate the food — your job "
    "is to reconstruct realistic ingredient quantities and step-by-step cooking "
    "instructions a home cook could follow tomorrow to recreate the dish.\n"
    "\n"
    "Hard rules:\n"
    "  • Be specific about quantities (use grams, ml, cups, tbsp, etc. — never "
    "    'some' or 'a bit').\n"
    "  • Steps must be ordered, action-first, and realistic for a home kitchen.\n"
    "  • Pick the correct cuisine (don't guess Italian for an Idli).\n"
    "  • Servings should reflect how many people the listed quantities feed; if "
    "    you can't tell, default to 1 serving matching the logged amounts.\n"
    "  • If the meal is multiple distinct dishes (e.g. 'Idli + Sambar + Chutney'), "
    "    fold them into one recipe whose instructions cover all components in "
    "    sensible order (longest cook first).\n"
    "  • Never invent allergens or ingredients the user didn't eat — stay close "
    "    to the logged food_items.\n"
)


def _build_prompt(
    *,
    user_query: Optional[str],
    food_items: list,
    total_calories: int,
    single_item_index: Optional[int],
) -> str:
    if single_item_index is not None and 0 <= single_item_index < len(food_items):
        item = food_items[single_item_index]
        return (
            f"Reconstruct the recipe for this single dish that the user logged:\n"
            f"  name: {item.get('name')}\n"
            f"  amount logged: {item.get('amount') or item.get('count') or '1 serving'}\n"
            f"  weight (g): {item.get('weight_g')}\n"
            f"  calories: {item.get('calories')}\n"
            f"  protein/carbs/fat (g): {item.get('protein_g')}/{item.get('carbs_g')}/{item.get('fat_g')}\n"
            "\nReturn structured JSON matching the schema."
        )
    items_lines = []
    for it in food_items or []:
        items_lines.append(
            f"  - {it.get('name')}: {it.get('amount') or it.get('count') or ''} "
            f"({it.get('weight_g') or '?'}g, {it.get('calories') or '?'} cal)"
        )
    return (
        f"Reconstruct the recipe for this logged meal.\n"
        f"User's description / search: {user_query or '(none)'}\n"
        f"Total calories logged: {total_calories}\n"
        f"Food items the user ate:\n"
        + "\n".join(items_lines)
        + "\n\nReturn structured JSON matching the schema."
    )


_VALID_CATEGORIES = {c.value for c in RecipeCategory}
_VALID_COOKING_METHODS = {m.value for m in CookingMethod}


def _coerce_category(raw: str) -> Optional[RecipeCategory]:
    val = (raw or "").strip().lower()
    if val in _VALID_CATEGORIES:
        return RecipeCategory(val)
    return None


def _coerce_cooking_method(raw: Optional[str]) -> Optional[CookingMethod]:
    if not raw:
        return None
    val = raw.strip().lower()
    if val in _VALID_COOKING_METHODS:
        return CookingMethod(val)
    return None


class RecipeEnrichmentService:
    """Singleton-shaped helper for the food_log → RecipeCreate path."""

    def __init__(self):
        self._settings = get_settings()

    async def enrich_food_log_to_recipe(
        self,
        food_log: dict,
        *,
        single_item_index: Optional[int] = None,
        image_url: Optional[str] = None,
    ) -> RecipeCreate:
        """Run Gemini with a constrained schema and convert the result into RecipeCreate.

        Raises if Gemini returns an unparseable response — caller should surface
        the failure to the user rather than silently fall back (per project rule
        feedback_no_silent_fallbacks.md).
        """
        food_items = food_log.get("food_items") or []
        prompt = _build_prompt(
            user_query=food_log.get("user_query"),
            food_items=food_items,
            total_calories=int(food_log.get("total_calories") or 0),
            single_item_index=single_item_index,
        )

        response = await gemini_generate_with_retry(
            model=self._settings.gemini_model,
            contents=prompt,
            config=types.GenerateContentConfig(
                system_instruction=_SYSTEM_INSTRUCTION,
                response_mime_type="application/json",
                response_schema=_EnrichedRecipe,
                max_output_tokens=2400,
                temperature=0.4,
            ),
            user_id=str(food_log.get("user_id", "system")),
            method_name="enrich_meal_to_recipe",
            timeout=25,
        )
        parsed: Optional[_EnrichedRecipe] = response.parsed
        if parsed is None:
            raise RuntimeError("Gemini returned an unparseable recipe enrichment")

        ingredients_create = [
            RecipeIngredientCreate(
                ingredient_order=i,
                food_name=ing.food_name[:255],
                # RecipeIngredientCreate requires amount > 0; clamp 0/None to a
                # tiny positive value for "to taste" rows (marked is_negligible
                # below if zero so triggers don't fold them into totals).
                amount=ing.amount if ing.amount > 0 else 0.001,
                unit=ing.unit[:30] or "g",
                amount_grams=ing.amount_grams,
                notes=(ing.notes or None) and ing.notes[:500],
                cooking_method=_coerce_cooking_method(ing.cooking_method),
                is_negligible=(ing.amount == 0),
            )
            for i, ing in enumerate(parsed.ingredients)
        ]

        return RecipeCreate(
            name=parsed.name[:255],
            description=(parsed.description or None) and parsed.description[:2000],
            servings=parsed.servings,
            prep_time_minutes=parsed.prep_time_minutes,
            cook_time_minutes=parsed.cook_time_minutes,
            instructions="\n".join(f"{i + 1}. {step}" for i, step in enumerate(parsed.instructions)) or None,
            image_url=image_url,
            category=_coerce_category(parsed.category),
            cuisine=(parsed.cuisine or None) and parsed.cuisine[:50],
            tags=parsed.tags or [],
            source_type=RecipeSourceType.FROM_LOGGED_MEAL,
            ingredients=ingredients_create,
        )


_singleton: Optional[RecipeEnrichmentService] = None


def get_recipe_enrichment_service() -> RecipeEnrichmentService:
    global _singleton
    if _singleton is None:
        _singleton = RecipeEnrichmentService()
    return _singleton
