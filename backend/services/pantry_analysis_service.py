"""
Pantry Analysis Service
=======================
Take a pantry photo and/or text list of items the user has on hand,
return AI-suggested recipes built around them.

Reuses:
  - VisionService.analyze_pantry_image() for fridge/pantry photos
  - RecipeSuggestionService.suggest_recipes() for the suggestion engine,
    extended with a `must_use_ingredients` constraint passed via
    additional_requirements.
"""

import logging
from typing import List, Optional

from models.recipe import (
    PantryAnalyzeRequest,
    PantryAnalyzeResponse,
    PantryDetectedItem,
    PantrySuggestion,
)
from services.recipe_suggestion_service import MealType, RecipeSuggestionService
from services.vision_service import VisionService

logger = logging.getLogger(__name__)


class PantryAnalysisService:
    """Pantry text + image → recipe suggestions."""

    def __init__(self):
        self.vision = VisionService()
        self.suggester = RecipeSuggestionService()

    async def analyze(self, user_id: str, req: PantryAnalyzeRequest) -> PantryAnalyzeResponse:
        detected: List[PantryDetectedItem] = []

        # 1) Detect items from text
        for item in (req.items_text or []):
            cleaned = item.strip()
            if cleaned:
                detected.append(
                    PantryDetectedItem(name=cleaned, confidence=100, source="text")
                )

        # 2) Detect items from photo (if provided)
        if req.image_b64:
            try:
                vision_items = await self.vision.analyze_pantry_image(req.image_b64)
            except Exception as exc:
                logger.exception("[Pantry] vision analyze failed")
                vision_items = []
                # Per feedback_no_silent_fallbacks: if photo was sent, surface explicit error
                # only when we have no text items either.
                if not detected:
                    raise RuntimeError(f"Couldn't read the pantry photo: {exc}") from exc

            for v in vision_items:
                detected.append(
                    PantryDetectedItem(
                        name=v.get("name") or "unknown",
                        confidence=int(v.get("confidence") or 70),
                        source="image",
                    )
                )

        if not detected:
            raise RuntimeError("Tell me what you have or upload a photo.")

        # 3) Build suggestion request
        item_names = [d.name for d in detected]
        constraint = (
            "Only suggest recipes that mostly use these ingredients on hand: "
            + ", ".join(item_names[:30])
            + ". You may include up to 2 commonly available extras (oil, salt, pepper, water)."
        )
        if req.additional_requirements:
            constraint = f"{constraint}\nAlso: {req.additional_requirements}"

        try:
            meal_type = MealType(req.meal_type) if req.meal_type else MealType.ANY
        except ValueError:
            meal_type = MealType.ANY

        raw_suggestions = await self.suggester.suggest_recipes(
            user_id=user_id,
            meal_type=meal_type,
            count=req.count,
            additional_requirements=constraint,
        )

        suggestions: List[PantrySuggestion] = []
        on_hand = {n.lower() for n in item_names}
        for s in raw_suggestions:
            data = s.to_dict() if hasattr(s, "to_dict") else dict(s)
            ingredient_names = {
                (ing.get("name") or "").lower() for ing in data.get("ingredients", [])
            }
            matched = sorted(on_hand & ingredient_names)
            missing = sorted(ingredient_names - on_hand)
            suggestions.append(
                PantrySuggestion(
                    name=data.get("recipe_name") or data.get("name") or "Untitled",
                    description=data.get("recipe_description") or data.get("description"),
                    cuisine=data.get("cuisine"),
                    category=data.get("category"),
                    servings=int(data.get("servings") or 1),
                    prep_time_minutes=data.get("prep_time_minutes"),
                    cook_time_minutes=data.get("cook_time_minutes"),
                    calories_per_serving=data.get("calories_per_serving"),
                    protein_per_serving_g=data.get("protein_per_serving_g"),
                    carbs_per_serving_g=data.get("carbs_per_serving_g"),
                    fat_per_serving_g=data.get("fat_per_serving_g"),
                    fiber_per_serving_g=data.get("fiber_per_serving_g"),
                    matched_pantry_items=matched,
                    missing_ingredients=missing,
                    overall_match_score=int(data.get("overall_match_score") or 0),
                    suggestion_reason=data.get("suggestion_reason"),
                    ingredients=[],  # full RecipeIngredientCreate built lazily on save
                )
            )

        return PantryAnalyzeResponse(detected_items=detected, suggestions=suggestions)


_singleton: Optional[PantryAnalysisService] = None


def get_pantry_service() -> PantryAnalysisService:
    global _singleton
    if _singleton is None:
        _singleton = PantryAnalysisService()
    return _singleton
