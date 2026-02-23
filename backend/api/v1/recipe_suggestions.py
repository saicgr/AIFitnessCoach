"""
Recipe Suggestions API
======================
Endpoints for AI-powered recipe suggestions based on:
- Body type (ectomorph/mesomorph/endomorph)
- Cultural/cuisine preferences
- Dietary restrictions and allergies
- Nutrition goals
"""

import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel, Field

from services.recipe_suggestion_service import (
    recipe_suggestion_service,
    MealType,
    RecipeSuggestion,
)
from services.user_context_service import UserContextService, EventType

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/nutrition/recipes", tags=["Recipe Suggestions"])


# ============================================================================
# REQUEST/RESPONSE MODELS
# ============================================================================


class RecipeIngredientResponse(BaseModel):
    """Ingredient in a recipe."""
    name: str
    amount: float
    unit: str
    calories: float = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0
    notes: Optional[str] = None


class RecipeSuggestionResponse(BaseModel):
    """A single recipe suggestion."""
    id: Optional[str] = None
    recipe_name: str
    recipe_description: str
    cuisine: str
    category: str
    ingredients: List[RecipeIngredientResponse]
    instructions: List[str]
    servings: int
    calories_per_serving: int
    protein_per_serving_g: float
    carbs_per_serving_g: float
    fat_per_serving_g: float
    fiber_per_serving_g: float
    prep_time_minutes: int
    cook_time_minutes: int
    suggestion_reason: str
    goal_alignment_score: int
    cuisine_match_score: int
    diet_compliance_score: int
    overall_match_score: int
    user_rating: Optional[int] = None
    user_saved: bool = False
    user_cooked: bool = False


class SuggestRecipesRequest(BaseModel):
    """Request to generate recipe suggestions."""
    meal_type: str = Field(default="any", description="Type of meal: breakfast, lunch, dinner, snack, any")
    count: int = Field(default=3, ge=1, le=5, description="Number of recipes to generate (1-5)")
    additional_requirements: Optional[str] = Field(default=None, description="Extra requirements like 'high fiber' or 'under 400 calories'")


class SuggestRecipesResponse(BaseModel):
    """Response with generated recipe suggestions."""
    success: bool
    recipes: List[RecipeSuggestionResponse]
    session_id: Optional[str] = None
    message: Optional[str] = None


class RateSuggestionRequest(BaseModel):
    """Request to rate a recipe suggestion."""
    rating: int = Field(ge=1, le=5, description="Rating 1-5 stars")
    feedback: Optional[str] = Field(default=None, description="Optional feedback text")


class CuisineResponse(BaseModel):
    """Cuisine type info."""
    code: str
    name: str
    region: Optional[str] = None
    typical_spice_level: Optional[str] = None


class BodyTypeResponse(BaseModel):
    """Body type info."""
    code: str
    name: str
    description: Optional[str] = None
    metabolism_type: Optional[str] = None
    dietary_tips: Optional[List[str]] = None


class UpdatePreferencesRequest(BaseModel):
    """Request to update cuisine/body type preferences."""
    body_type: Optional[str] = None
    favorite_cuisines: Optional[List[str]] = None
    spice_tolerance: Optional[str] = None
    cultural_background: Optional[str] = None


# ============================================================================
# API ENDPOINTS
# ============================================================================


@router.post("/{user_id}/suggest", response_model=SuggestRecipesResponse)
async def suggest_recipes(user_id: str, request: SuggestRecipesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Generate personalized recipe suggestions based on user's:
    - Body type
    - Cultural/cuisine preferences
    - Diet type and nutrition goals
    - Allergies and dietary restrictions
    - Cooking skill and time available

    Returns 1-5 AI-generated recipes tailored to the user.
    """
    logger.info(f"🍳 [API] Recipe suggestion request for user {user_id}: {request.meal_type}, count={request.count}")

    try:
        # Parse meal type
        try:
            meal_type = MealType(request.meal_type.lower())
        except ValueError:
            meal_type = MealType.ANY

        # Generate suggestions
        suggestions = await recipe_suggestion_service.suggest_recipes(
            user_id=user_id,
            meal_type=meal_type,
            count=request.count,
            additional_requirements=request.additional_requirements,
        )

        # Convert to response format
        recipes = [
            RecipeSuggestionResponse(
                recipe_name=s.recipe_name,
                recipe_description=s.recipe_description,
                cuisine=s.cuisine,
                category=s.category,
                ingredients=[
                    RecipeIngredientResponse(
                        name=i.name,
                        amount=i.amount,
                        unit=i.unit,
                        calories=i.calories,
                        protein_g=i.protein_g,
                        carbs_g=i.carbs_g,
                        fat_g=i.fat_g,
                        notes=i.notes,
                    )
                    for i in s.ingredients
                ],
                instructions=s.instructions,
                servings=s.servings,
                calories_per_serving=s.calories_per_serving,
                protein_per_serving_g=s.protein_per_serving_g,
                carbs_per_serving_g=s.carbs_per_serving_g,
                fat_per_serving_g=s.fat_per_serving_g,
                fiber_per_serving_g=s.fiber_per_serving_g,
                prep_time_minutes=s.prep_time_minutes,
                cook_time_minutes=s.cook_time_minutes,
                suggestion_reason=s.suggestion_reason,
                goal_alignment_score=s.goal_alignment_score,
                cuisine_match_score=s.cuisine_match_score,
                diet_compliance_score=s.diet_compliance_score,
                overall_match_score=s.overall_match_score,
            )
            for s in suggestions
        ]

        # Log user context event
        try:
            user_context_service = UserContextService()
            await user_context_service.log_event(
                user_id=user_id,
                event_type=EventType.FEATURE_INTERACTION,
                event_data={
                    "feature": "recipe_suggestion",
                    "action": "requested",
                    "meal_type": request.meal_type,
                    "count_requested": request.count,
                    "count_generated": len(recipes),
                    "additional_requirements": request.additional_requirements,
                },
            )
        except Exception as ctx_err:
            logger.warning(f"⚠️ Failed to log context: {ctx_err}")

        return SuggestRecipesResponse(
            success=True,
            recipes=recipes,
            message=f"Generated {len(recipes)} personalized recipes",
        )

    except ValueError as e:
        logger.error(f"❌ [API] Recipe suggestion error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"❌ [API] Recipe suggestion error: {e}")
        raise safe_internal_error(e, "recipe_suggestions")


@router.get("/{user_id}/suggestions", response_model=List[RecipeSuggestionResponse])
async def get_saved_suggestions(
    user_id: str,
    limit: int = Query(default=20, ge=1, le=100),
    saved_only: bool = Query(default=False),
    current_user: dict = Depends(get_current_user),
):
    """Get user's previous recipe suggestions."""
    logger.info(f"🍳 [API] Getting suggestions for user {user_id}, saved_only={saved_only}")

    try:
        suggestions = await recipe_suggestion_service.get_saved_suggestions(
            user_id=user_id,
            limit=limit,
            saved_only=saved_only,
        )

        return [
            RecipeSuggestionResponse(
                id=s.get("id"),
                recipe_name=s.get("recipe_name", ""),
                recipe_description=s.get("recipe_description", ""),
                cuisine=s.get("cuisine", ""),
                category=s.get("category", ""),
                ingredients=[
                    RecipeIngredientResponse(**ing)
                    for ing in s.get("ingredients", [])
                ],
                instructions=s.get("instructions", []),
                servings=s.get("servings", 1),
                calories_per_serving=s.get("calories_per_serving", 0),
                protein_per_serving_g=s.get("protein_per_serving_g", 0),
                carbs_per_serving_g=s.get("carbs_per_serving_g", 0),
                fat_per_serving_g=s.get("fat_per_serving_g", 0),
                fiber_per_serving_g=s.get("fiber_per_serving_g", 0),
                prep_time_minutes=s.get("prep_time_minutes", 0),
                cook_time_minutes=s.get("cook_time_minutes", 0),
                suggestion_reason=s.get("suggestion_reason", ""),
                goal_alignment_score=s.get("goal_alignment_score", 0),
                cuisine_match_score=s.get("cuisine_match_score", 0),
                diet_compliance_score=s.get("diet_compliance_score", 0),
                overall_match_score=s.get("overall_match_score", 0),
                user_rating=s.get("user_rating"),
                user_saved=s.get("user_saved", False),
                user_cooked=s.get("user_cooked", False),
            )
            for s in suggestions
        ]

    except Exception as e:
        logger.error(f"❌ [API] Error getting suggestions: {e}")
        raise safe_internal_error(e, "recipe_suggestions")


@router.post("/{user_id}/suggestions/{suggestion_id}/rate")
async def rate_suggestion(user_id: str, suggestion_id: str, request: RateSuggestionRequest,
    current_user: dict = Depends(get_current_user),
):
    """Rate a recipe suggestion (1-5 stars)."""
    logger.info(f"🍳 [API] Rating suggestion {suggestion_id} with {request.rating} stars")

    success = await recipe_suggestion_service.rate_suggestion(
        user_id=user_id,
        suggestion_id=suggestion_id,
        rating=request.rating,
        feedback=request.feedback,
    )

    if not success:
        raise HTTPException(status_code=400, detail="Failed to rate suggestion")

    # Log context
    try:
        user_context_service = UserContextService()
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "recipe_suggestion",
                "action": "rated",
                "suggestion_id": suggestion_id,
                "rating": request.rating,
            },
        )
    except Exception:
        pass

    return {"success": True, "message": "Rating saved"}


@router.post("/{user_id}/suggestions/{suggestion_id}/save")
async def save_suggestion(user_id: str, suggestion_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Save/favorite a recipe suggestion."""
    logger.info(f"🍳 [API] Saving suggestion {suggestion_id}")

    success = await recipe_suggestion_service.save_suggestion(
        user_id=user_id,
        suggestion_id=suggestion_id,
    )

    if not success:
        raise HTTPException(status_code=400, detail="Failed to save suggestion")

    # Log context
    try:
        user_context_service = UserContextService()
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "recipe_suggestion",
                "action": "saved",
                "suggestion_id": suggestion_id,
            },
        )
    except Exception:
        pass

    return {"success": True, "message": "Recipe saved to favorites"}


@router.post("/{user_id}/suggestions/{suggestion_id}/cooked")
async def mark_cooked(user_id: str, suggestion_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Mark a recipe suggestion as cooked."""
    logger.info(f"🍳 [API] Marking suggestion {suggestion_id} as cooked")

    success = await recipe_suggestion_service.mark_cooked(
        user_id=user_id,
        suggestion_id=suggestion_id,
    )

    if not success:
        raise HTTPException(status_code=400, detail="Failed to mark as cooked")

    # Log context
    try:
        user_context_service = UserContextService()
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "recipe_suggestion",
                "action": "cooked",
                "suggestion_id": suggestion_id,
            },
        )
    except Exception:
        pass

    return {"success": True, "message": "Marked as cooked"}


@router.post("/{user_id}/suggestions/{suggestion_id}/convert")
async def convert_to_recipe(user_id: str, suggestion_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Convert a suggestion to a user recipe in the recipe library."""
    logger.info(f"🍳 [API] Converting suggestion {suggestion_id} to user recipe")

    recipe_id = await recipe_suggestion_service.convert_to_user_recipe(
        user_id=user_id,
        suggestion_id=suggestion_id,
    )

    if not recipe_id:
        raise HTTPException(status_code=400, detail="Failed to convert to recipe")

    return {"success": True, "recipe_id": recipe_id, "message": "Recipe added to your library"}


@router.get("/cuisines", response_model=List[CuisineResponse])
async def get_cuisines(
    current_user: dict = Depends(get_current_user),
):
    """Get list of available cuisines for preference selection."""
    cuisines = await recipe_suggestion_service.get_cuisines_list()
    return [CuisineResponse(**c) for c in cuisines]


@router.get("/body-types", response_model=List[BodyTypeResponse])
async def get_body_types(
    current_user: dict = Depends(get_current_user),
):
    """Get list of body types with descriptions."""
    body_types = await recipe_suggestion_service.get_body_types_list()
    return [BodyTypeResponse(**b) for b in body_types]


@router.put("/{user_id}/preferences")
async def update_recipe_preferences(user_id: str, request: UpdatePreferencesRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update user's recipe-related preferences (body type, cuisines, spice tolerance).
    """
    logger.info(f"🍳 [API] Updating recipe preferences for user {user_id}")

    try:
        from core.db import get_supabase_db
        db = get_supabase_db()

        update_data = {}
        if request.body_type is not None:
            update_data["body_type"] = request.body_type
        if request.favorite_cuisines is not None:
            update_data["favorite_cuisines"] = request.favorite_cuisines
        if request.spice_tolerance is not None:
            update_data["spice_tolerance"] = request.spice_tolerance
        if request.cultural_background is not None:
            update_data["cultural_background"] = request.cultural_background

        if not update_data:
            return {"success": True, "message": "No updates provided"}

        # Upsert nutrition preferences
        existing = db.client.table("nutrition_preferences").select("id").eq(
            "user_id", user_id
        ).execute()

        if existing.data:
            db.client.table("nutrition_preferences").update(update_data).eq(
                "user_id", user_id
            ).execute()
        else:
            update_data["user_id"] = user_id
            db.client.table("nutrition_preferences").insert(update_data).execute()

        logger.info(f"✅ [API] Updated recipe preferences for {user_id}")
        return {"success": True, "message": "Preferences updated"}

    except Exception as e:
        logger.error(f"❌ [API] Error updating preferences: {e}")
        raise safe_internal_error(e, "recipe_suggestions")
