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

import asyncio
import logging
from typing import List, Optional

from core.db import get_supabase_db
from models.recipe import (
    PantryAnalyzeRequest,
    PantryAnalyzeResponse,
    PantryDetectedItem,
    PantrySuggestion,
)
from services.pexels_service import get_dish_photo_url
from services.recipe_suggestion_service import MealType, RecipeSuggestionService
from services.vision_service import VisionService

logger = logging.getLogger(__name__)


# Mood → tone guidance for the generation prompt. Mapped in CODE (never the raw
# client string) so the mood field can't inject arbitrary prompt text.
_MOOD_DIRECTIVES = {
    "comfort": "The user is in a comfort-food mood — lean warm, hearty, one-pot / one-pan leanings.",
    "fresh": "The user wants fresh & light — crisp, bright, minimal cooking, plenty of vegetables.",
    "spicy": "The user wants bold heat — build in chili / spice-forward flavor.",
    "lazy": "The user wants lazy & quick — minimal steps, few dishes, easy cleanup.",
    "fancy": "The user wants to impress — presentation-worthy, restaurant-style plating.",
    "sweet": "The user has a sweet tooth — lean toward a healthy, dessert-leaning option.",
}


def build_filter_mood_directives(
    filters: Optional[List[str]] = None,
    mood: Optional[str] = None,
    dietary_restrictions: Optional[List[str]] = None,
) -> str:
    """Assemble the extra generation directives from the user's chosen filters,
    mood, and their ALWAYS-APPLIED dietary restrictions.

    - `dietary_restrictions` (from the user's nutrition_preferences row) and
      `filters` (human labels like "High protein", "≤ 30 min", "Mexican")
      become HARD constraints every recipe must satisfy. Restrictions are
      applied even when the client sends no filters — allergies/diet must never
      depend on the client remembering to send them.
    - `mood` is mapped in code to tone guidance.

    Returns a directive block to append to the generation constraint, or "".
    """
    hard: List[str] = []
    for r in (dietary_restrictions or []):
        r = (r or "").strip()
        if r:
            hard.append(r)
    for f in (filters or []):
        f = (f or "").strip()
        if f:
            hard.append(f)

    # De-dupe case-insensitively, preserving order.
    seen = set()
    deduped: List[str] = []
    for h in hard:
        k = h.lower()
        if k not in seen:
            seen.add(k)
            deduped.append(h)

    lines: List[str] = []
    if deduped:
        lines.append(
            "Every recipe MUST satisfy ALL of these constraints: "
            + "; ".join(deduped)
            + "."
        )
    if mood:
        directive = _MOOD_DIRECTIVES.get(mood.strip().lower())
        if directive:
            lines.append(directive)

    return "\n".join(lines)


def _always_applied_restrictions(prefs: Optional[dict]) -> List[str]:
    """Pull the user's allergies + dietary restrictions + non-trivial diet type
    out of their nutrition_preferences row, as human labels for the prompt."""
    prefs = prefs or {}
    out: List[str] = []
    for a in (prefs.get("allergies") or []):
        a = str(a).strip()
        if a:
            out.append(f"no {a} (allergy)")
    for r in (prefs.get("dietary_restrictions") or []):
        r = str(r).strip()
        if r:
            out.append(r)
    diet = str(prefs.get("diet_type") or "").strip()
    if diet and diet.lower() not in ("balanced", "none", ""):
        out.append(diet)
    return out


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

        # v3 — thread filters + mood + the user's ALWAYS-APPLIED dietary
        # restrictions into the generation constraint. Restrictions are merged
        # even when the client sends no filters (allergies/diet must never
        # depend on the client remembering to send them). Note: the underlying
        # RecipeSuggestionService ALSO injects allergies/restrictions via its
        # own user-context prompt block — this is deliberate reinforcement of
        # the safety-critical constraints.
        try:
            prefs = get_supabase_db().get_nutrition_preferences(user_id)
        except Exception:
            logger.warning("[Pantry] could not load nutrition_preferences", exc_info=True)
            prefs = None
        directives = build_filter_mood_directives(
            filters=req.filters,
            mood=req.mood,
            dietary_restrictions=_always_applied_restrictions(prefs),
        )
        if directives:
            constraint = f"{constraint}\n{directives}"

        try:
            meal_type = MealType(req.meal_type) if req.meal_type else MealType.ANY
        except ValueError:
            meal_type = MealType.ANY

        raw_suggestions = await self.suggester.suggest_recipes(
            user_id=user_id,
            meal_type=meal_type,
            count=req.count,
            additional_requirements=constraint,
            skip_save=True,
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
                    instructions=[str(x) for x in (data.get("instructions") or [])],
                )
            )

        # Fetch finished-dish photos for all suggestions CONCURRENTLY so N
        # lookups cost ~1 round-trip, not N. get_dish_photo_url never raises
        # (returns None on any failure), so gather stays clean.
        if suggestions:
            photo_urls = await asyncio.gather(
                *[get_dish_photo_url(s.name) for s in suggestions]
            )
            for s, url in zip(suggestions, photo_urls):
                s.image_url = url

        return PantryAnalyzeResponse(detected_items=detected, suggestions=suggestions)


_singleton: Optional[PantryAnalysisService] = None


def get_pantry_service() -> PantryAnalysisService:
    global _singleton
    if _singleton is None:
        _singleton = PantryAnalysisService()
    return _singleton
