"""
Nutrition Preferences API - Quick logging, meal templates, and food search.

This module provides endpoints for:
1. Nutrition UI preferences (disable_ai_tips, quick_log_mode, etc.)
2. Quick logging of saved foods without AI analysis
3. Personalized quick food suggestions based on logging history
4. Meal templates for one-tap logging
5. Fast food search with caching

ENDPOINTS:

Preferences:
- GET  /api/v1/nutrition/preferences - Get nutrition UI preferences
- PUT  /api/v1/nutrition/preferences - Update nutrition preferences
- POST /api/v1/nutrition/preferences/reset - Reset to default preferences

Quick Log:
- POST /api/v1/nutrition/quick-log - Instant log a saved food
- GET  /api/v1/nutrition/quick-suggestions - Get personalized quick suggestions

Meal Templates:
- GET  /api/v1/nutrition/templates - List all meal templates
- POST /api/v1/nutrition/templates - Create a meal template
- PUT  /api/v1/nutrition/templates/{template_id} - Update a template
- DELETE /api/v1/nutrition/templates/{template_id} - Delete a template
- POST /api/v1/nutrition/templates/{template_id}/log - Log a template as food

Food Search:
- GET  /api/v1/nutrition/search - Fast food search with caching
"""
from core.db import get_supabase_db

from .nutrition_preferences_models import *  # noqa: F401, F403
from .nutrition_preferences_endpoints import router as _endpoints_router

from datetime import datetime, timedelta
from typing import List, Optional
import uuid
import logging
from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.activity_logger import log_user_activity, log_user_error
from services.user_context_service import user_context_service

logger = logging.getLogger(__name__)
router = APIRouter()


# =============================================================================
# Pydantic Models - Preferences
# =============================================================================

class NutritionPreferences(BaseModel):
    """User's nutrition UI preferences."""
    disable_ai_tips: bool = Field(default=False, description="Disable AI tips after logging")
    quick_log_mode: bool = Field(default=False, description="Enable quick log mode by default")
    default_meal_type: Optional[str] = Field(default=None, max_length=50, description="Default meal type for logging")
    show_macros_on_home: bool = Field(default=True, description="Show macro breakdown on home screen")
    show_calories_remaining: bool = Field(default=True, description="Show calories remaining vs consumed")
    enable_meal_reminders: bool = Field(default=True, description="Enable meal logging reminders")
    preferred_units: str = Field(default="metric", description="Preferred units (metric/imperial)")
    show_micronutrients: bool = Field(default=False, description="Show detailed micronutrients")
    quick_access_foods_count: int = Field(default=5, ge=1, le=10, description="Number of quick access foods to show")
    meals_per_day: int = Field(default=4, ge=3, le=8, description="Number of meals per day (4, 5, or 6)")
    # Hormonal diet preferences
    hormonal_diet_enabled: bool = Field(default=False, description="Enable hormonal diet recommendations")
    hormonal_goal: Optional[str] = Field(default=None, description="Primary hormonal goal for diet recommendations")
    show_hormone_supportive_foods: bool = Field(default=True, description="Show hormone-supportive food suggestions")
    cycle_aware_nutrition: bool = Field(default=False, description="Adjust nutrition suggestions based on menstrual cycle phase")
    calorie_estimate_bias: int = Field(default=0, ge=-2, le=2, description="Bias for AI calorie estimates: -2 to 2")


class NutritionPreferencesResponse(BaseModel):
    """Response with user's nutrition preferences."""
    user_id: str
    preferences: NutritionPreferences
    updated_at: Optional[datetime] = None


class NutritionPreferencesUpdate(BaseModel):
    """Request to update nutrition preferences."""
    disable_ai_tips: Optional[bool] = None
    quick_log_mode: Optional[bool] = None
    default_meal_type: Optional[str] = Field(default=None, max_length=50)
    show_macros_on_home: Optional[bool] = None
    show_calories_remaining: Optional[bool] = None
    enable_meal_reminders: Optional[bool] = None
    preferred_units: Optional[str] = Field(default=None, pattern="^(metric|imperial)$")
    show_micronutrients: Optional[bool] = None
    quick_access_foods_count: Optional[int] = Field(default=None, ge=1, le=10)
    meals_per_day: Optional[int] = Field(default=None, ge=3, le=8)
    # Hormonal diet preferences
    hormonal_diet_enabled: Optional[bool] = None
    hormonal_goal: Optional[str] = None
    show_hormone_supportive_foods: Optional[bool] = None
    cycle_aware_nutrition: Optional[bool] = None
    calorie_estimate_bias: Optional[int] = Field(default=None, ge=-2, le=2)


# =============================================================================
# Pydantic Models - Quick Log
# =============================================================================

class QuickLogRequest(BaseModel):
    """Request to quick log a saved food."""
    saved_food_id: str = Field(..., description="ID of the saved food to log")
    meal_type: str = Field(..., max_length=50, description="Meal type (breakfast, lunch, dinner, snack)")
    servings: float = Field(default=1.0, ge=0.1, le=10.0, description="Number of servings")


class QuickLogResponse(BaseModel):
    """Response after quick logging a food."""
    success: bool
    food_log_id: str
    saved_food_id: str
    saved_food_name: str
    meal_type: str
    servings: float
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    logged_at: datetime


class QuickSuggestion(BaseModel):
    """A quick food suggestion for the user."""
    saved_food_id: str
    name: str
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    times_logged: int
    last_logged_at: Optional[datetime] = None
    suggested_meal_type: str
    suggestion_reason: str  # "frequently_logged", "time_appropriate", "recent_favorite"
    tags: List[str] = Field(default_factory=list)


class QuickSuggestionsResponse(BaseModel):
    """Response with personalized quick food suggestions."""
    suggestions: List[QuickSuggestion]
    time_of_day: str  # "morning", "afternoon", "evening", "night"
    suggested_meal_type: str


# =============================================================================
# Pydantic Models - Meal Templates
# =============================================================================

class MealTemplateFoodItem(BaseModel):
    """Individual food item in a meal template."""
    name: str = Field(..., max_length=200)
    amount: Optional[str] = Field(default=None, max_length=50)
    calories: int = Field(default=0, ge=0, le=5000)
    protein_g: float = Field(default=0.0, ge=0, le=500)
    carbs_g: float = Field(default=0.0, ge=0, le=500)
    fat_g: float = Field(default=0.0, ge=0, le=500)
    fiber_g: Optional[float] = Field(default=None, ge=0, le=100)


class MealTemplateBase(BaseModel):
    """Base model for meal templates."""
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(default=None, max_length=500)
    meal_type: str = Field(..., max_length=50)  # breakfast, lunch, dinner, snack
    food_items: List[MealTemplateFoodItem] = Field(default_factory=list, max_length=20)
    tags: List[str] = Field(default_factory=list, max_length=10)
    is_system_template: bool = Field(default=False, description="Whether this is a system-provided template")


class MealTemplateCreate(MealTemplateBase):
    """Request to create a meal template."""
    pass


class MealTemplateUpdate(BaseModel):
    """Request to update a meal template."""
    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    description: Optional[str] = Field(default=None, max_length=500)
    meal_type: Optional[str] = Field(default=None, max_length=50)
    food_items: Optional[List[MealTemplateFoodItem]] = Field(default=None, max_length=20)
    tags: Optional[List[str]] = Field(default=None, max_length=10)


class MealTemplate(MealTemplateBase):
    """Meal template from database."""
    id: str
    user_id: Optional[str] = None  # None for system templates
    total_calories: int
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    total_fiber_g: Optional[float] = None
    times_used: int = 0
    last_used_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class MealTemplatesResponse(BaseModel):
    """Response with list of meal templates."""
    templates: List[MealTemplate]
    total_count: int


class LogTemplateRequest(BaseModel):
    """Request to log a meal template as a food entry."""
    meal_type: Optional[str] = Field(default=None, max_length=50, description="Override the template's meal type")
    servings: float = Field(default=1.0, ge=0.1, le=10.0, description="Number of servings")


class LogTemplateResponse(BaseModel):
    """Response after logging a meal template."""
    success: bool
    food_log_id: str
    template_id: str
    template_name: str
    meal_type: str
    servings: float
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    logged_at: datetime


# =============================================================================
# Pydantic Models - Food Search
# =============================================================================

class FoodSearchResult(BaseModel):
    """A food search result."""
    id: str
    name: str
    source: str  # "saved", "template", "database", "usda"
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    serving_size: Optional[str] = None
    brand: Optional[str] = None
    is_user_food: bool = False


class FoodSearchResponse(BaseModel):
    """Response with food search results."""
    results: List[FoodSearchResult]
    query: str
    total_count: int
    cached: bool = False


# =============================================================================
# Helper Functions
# =============================================================================

def get_time_of_day() -> tuple[str, str]:
    """Get current time of day and suggested meal type."""
    hour = datetime.now().hour
    if 5 <= hour < 11:
        return "morning", "breakfast"
    elif 11 <= hour < 15:
        return "afternoon", "lunch"
    elif 15 <= hour < 20:
        return "evening", "dinner"
    else:
        return "night", "snack"


def calculate_template_totals(food_items: List[MealTemplateFoodItem]) -> dict:
    """Calculate total nutrition from food items."""
    totals = {
        "total_calories": 0,
        "total_protein_g": 0.0,
        "total_carbs_g": 0.0,
        "total_fat_g": 0.0,
        "total_fiber_g": 0.0,
    }
    for item in food_items:
        totals["total_calories"] += item.calories
        totals["total_protein_g"] += item.protein_g
        totals["total_carbs_g"] += item.carbs_g
        totals["total_fat_g"] += item.fat_g
        if item.fiber_g:
            totals["total_fiber_g"] += item.fiber_g
    return totals


# =============================================================================
# Preferences Endpoints
# =============================================================================

@router.get("/preferences", response_model=NutritionPreferencesResponse)
async def get_nutrition_preferences(current_user: dict = Depends(get_current_user)):
    """
    Get user's nutrition UI preferences.

    Returns preferences like:
    - disable_ai_tips: Whether to skip AI tips after logging
    - quick_log_mode: Whether quick log mode is enabled by default
    - default_meal_type: Default meal type for new logs
    - And more display preferences
    """
    user_id = current_user["id"]
    logger.info(f"Getting nutrition preferences for user {user_id}")

    try:
        db = get_supabase_db()

        # Try to get existing preferences
        result = db.client.table("nutrition_preferences").select("*").eq("user_id", user_id).maybeSingle().execute()

        if result.data:
            prefs_data = result.data
            preferences = NutritionPreferences(
                disable_ai_tips=prefs_data.get("disable_ai_tips", False),
                quick_log_mode=prefs_data.get("quick_log_mode", False),
                default_meal_type=prefs_data.get("default_meal_type"),
                show_macros_on_home=prefs_data.get("show_macros_on_home", True),
                show_calories_remaining=prefs_data.get("show_calories_remaining", True),
                enable_meal_reminders=prefs_data.get("enable_meal_reminders", True),
                preferred_units=prefs_data.get("preferred_units", "metric"),
                show_micronutrients=prefs_data.get("show_micronutrients", False),
                quick_access_foods_count=prefs_data.get("quick_access_foods_count", 5),
                meals_per_day=prefs_data.get("meals_per_day", 4),
                # Hormonal diet preferences
                hormonal_diet_enabled=prefs_data.get("hormonal_diet_enabled", False),
                hormonal_goal=prefs_data.get("hormonal_goal"),
                show_hormone_supportive_foods=prefs_data.get("show_hormone_supportive_foods", True),
                cycle_aware_nutrition=prefs_data.get("cycle_aware_nutrition", False),
                calorie_estimate_bias=prefs_data.get("calorie_estimate_bias", 0),
            )
            updated_at = prefs_data.get("updated_at")
        else:
            # Return defaults
            preferences = NutritionPreferences()
            updated_at = None

        return NutritionPreferencesResponse(
            user_id=user_id,
            preferences=preferences,
            updated_at=updated_at,
        )

    except Exception as e:
        logger.error(f"Error getting nutrition preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_preferences")


@router.put("/preferences", response_model=NutritionPreferencesResponse)
async def update_nutrition_preferences(
    request: NutritionPreferencesUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Update user's nutrition UI preferences.

    Only provided fields will be updated. Omitted fields remain unchanged.
    """
    user_id = current_user["id"]
    logger.info(f"Updating nutrition preferences for user {user_id}")

    try:
        db = get_supabase_db()

        # Build update data from non-None fields
        update_data = {}
        for field, value in request.model_dump(exclude_unset=True).items():
            if value is not None:
                update_data[field] = value

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields provided to update")

        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Upsert preferences
        result = db.client.table("nutrition_preferences").upsert({
            "user_id": user_id,
            **update_data,
        }, on_conflict="user_id").execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to update preferences"), "nutrition_preferences")

        prefs_data = result.data[0]

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="nutrition_preferences_update",
            endpoint="/api/v1/nutrition/preferences",
            message=f"Updated {len(update_data)} nutrition preferences",
            metadata={"updated_fields": list(update_data.keys())},
            status_code=200
        )

        # Log user context for analytics
        await user_context_service.log_nutrition_preferences_updated(
            user_id=user_id,
            disable_ai_tips=prefs_data.get("disable_ai_tips"),
            quick_log_mode=prefs_data.get("quick_log_mode"),
            compact_tracker_view=prefs_data.get("compact_tracker_view"),
        )

        # Log specific toggles for analytics
        if "disable_ai_tips" in update_data:
            await user_context_service.log_ai_tips_toggled(
                user_id=user_id,
                disabled=update_data["disable_ai_tips"],
            )
        if "compact_tracker_view" in update_data:
            await user_context_service.log_compact_view_toggled(
                user_id=user_id,
                enabled=update_data["compact_tracker_view"],
            )

        preferences = NutritionPreferences(
            disable_ai_tips=prefs_data.get("disable_ai_tips", False),
            quick_log_mode=prefs_data.get("quick_log_mode", False),
            default_meal_type=prefs_data.get("default_meal_type"),
            show_macros_on_home=prefs_data.get("show_macros_on_home", True),
            show_calories_remaining=prefs_data.get("show_calories_remaining", True),
            enable_meal_reminders=prefs_data.get("enable_meal_reminders", True),
            preferred_units=prefs_data.get("preferred_units", "metric"),
            show_micronutrients=prefs_data.get("show_micronutrients", False),
            quick_access_foods_count=prefs_data.get("quick_access_foods_count", 5),
            meals_per_day=prefs_data.get("meals_per_day", 4),
            # Hormonal diet preferences
            hormonal_diet_enabled=prefs_data.get("hormonal_diet_enabled", False),
            hormonal_goal=prefs_data.get("hormonal_goal"),
            show_hormone_supportive_foods=prefs_data.get("show_hormone_supportive_foods", True),
            cycle_aware_nutrition=prefs_data.get("cycle_aware_nutrition", False),
            calorie_estimate_bias=prefs_data.get("calorie_estimate_bias", 0),
        )

        return NutritionPreferencesResponse(
            user_id=user_id,
            preferences=preferences,
            updated_at=prefs_data.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating nutrition preferences: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="nutrition_preferences_update",
            error=e,
            endpoint="/api/v1/nutrition/preferences",
            status_code=500
        )
        raise safe_internal_error(e, "nutrition_preferences")


@router.post("/preferences/reset", response_model=NutritionPreferencesResponse)
async def reset_nutrition_preferences(current_user: dict = Depends(get_current_user)):
    """
    Reset nutrition preferences to default values.

    All preferences will be set to their default values.
    """
    user_id = current_user["id"]
    logger.info(f"Resetting nutrition preferences for user {user_id}")

    try:
        db = get_supabase_db()

        # Default preferences
        default_prefs = NutritionPreferences()
        prefs_dict = default_prefs.model_dump()
        prefs_dict["user_id"] = user_id
        prefs_dict["updated_at"] = datetime.utcnow().isoformat()

        # Upsert with defaults
        result = db.client.table("nutrition_preferences").upsert(
            prefs_dict,
            on_conflict="user_id"
        ).execute()

        if not result.data:
            raise safe_internal_error(ValueError("Failed to reset preferences"), "nutrition_preferences")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="nutrition_preferences_reset",
            endpoint="/api/v1/nutrition/preferences/reset",
            message="Reset nutrition preferences to defaults",
            status_code=200
        )

        # Log user context for analytics
        await user_context_service.log_nutrition_preferences_reset(
            user_id=user_id,
        )

        return NutritionPreferencesResponse(
            user_id=user_id,
            preferences=default_prefs,
            updated_at=result.data[0].get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error resetting nutrition preferences: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_preferences")


# =============================================================================
# Quick Log Endpoints
# =============================================================================

@router.post("/quick-log", response_model=QuickLogResponse)
async def quick_log_saved_food(
    request: QuickLogRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Instantly log a saved food without AI analysis.

    This is the fastest way to log food - no AI tips, no analysis,
    just quick logging with calculated nutrition based on servings.
    """
    user_id = current_user["id"]
    logger.info(f"Quick logging saved food {request.saved_food_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get the saved food
        result = db.client.table("saved_foods").select("*").eq("id", request.saved_food_id).eq("user_id", user_id).maybeSingle().execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Saved food not found")

        saved_food = result.data

        # Calculate nutrition based on servings
        servings = request.servings
        total_calories = int((saved_food.get("total_calories") or 0) * servings)
        protein_g = float((saved_food.get("total_protein_g") or 0) * servings)
        carbs_g = float((saved_food.get("total_carbs_g") or 0) * servings)
        fat_g = float((saved_food.get("total_fat_g") or 0) * servings)
        fiber_g = float((saved_food.get("total_fiber_g") or 0) * servings) if saved_food.get("total_fiber_g") else None

        # Get food items and scale them
        food_items = saved_food.get("food_items") or []
        scaled_items = []
        for item in food_items:
            scaled_item = {
                "name": item.get("name"),
                "amount": item.get("amount"),
                "calories": int((item.get("calories") or 0) * servings),
                "protein_g": float((item.get("protein_g") or 0) * servings),
                "carbs_g": float((item.get("carbs_g") or 0) * servings),
                "fat_g": float((item.get("fat_g") or 0) * servings),
            }
            if item.get("fiber_g"):
                scaled_item["fiber_g"] = float(item["fiber_g"] * servings)
            scaled_items.append(scaled_item)

        # Create food log
        logged_at = datetime.utcnow()
        food_log = db.create_food_log(
            user_id=user_id,
            meal_type=request.meal_type,
            food_items=scaled_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=None,  # No AI feedback for quick log
            health_score=None,
            source_type="manual",
            input_type="manual",
        )

        food_log_id = food_log.get("id") if food_log else str(uuid.uuid4())

        # Update saved food usage stats
        db.client.table("saved_foods").update({
            "times_logged": (saved_food.get("times_logged") or 0) + 1,
            "last_logged_at": logged_at.isoformat(),
        }).eq("id", request.saved_food_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="quick_log",
            endpoint="/api/v1/nutrition/quick-log",
            message=f"Quick logged '{saved_food.get('name')}' ({total_calories} cal)",
            metadata={
                "food_log_id": food_log_id,
                "saved_food_id": request.saved_food_id,
                "meal_type": request.meal_type,
                "servings": servings,
                "total_calories": total_calories,
            },
            status_code=200
        )

        # Log user context for analytics
        await user_context_service.log_quick_log_used(
            user_id=user_id,
            food_name=saved_food.get("name", "Unknown"),
            meal_type=request.meal_type,
            calories=total_calories,
            servings=servings,
        )

        return QuickLogResponse(
            success=True,
            food_log_id=food_log_id,
            saved_food_id=request.saved_food_id,
            saved_food_name=saved_food.get("name"),
            meal_type=request.meal_type,
            servings=servings,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            logged_at=logged_at,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error quick logging food: {e}", exc_info=True)
        await log_user_error(
            user_id=user_id,
            action="quick_log",
            error=e,
            endpoint="/api/v1/nutrition/quick-log",
            metadata={"saved_food_id": request.saved_food_id},
            status_code=500
        )
        raise safe_internal_error(e, "nutrition_preferences")


@router.get("/quick-suggestions", response_model=QuickSuggestionsResponse)
async def get_quick_suggestions(
    current_user: dict = Depends(get_current_user),
    limit: int = Query(default=10, ge=1, le=20)
):
    """
    Get personalized quick food suggestions based on:
    - Time of day
    - Meal type
    - User's logging history
    - Most frequently logged foods

    Returns top suggestions with full nutrition data.
    """
    user_id = current_user["id"]
    time_of_day, suggested_meal_type = get_time_of_day()
    logger.info(f"Getting quick suggestions for user {user_id}, time: {time_of_day}")

    try:
        db = get_supabase_db()

        suggestions = []

        # 1. Get frequently logged foods (top by times_logged)
        frequent_result = db.client.table("saved_foods").select("*").eq("user_id", user_id).order("times_logged", desc=True).limit(5).execute()

        for food in frequent_result.data or []:
            if len(suggestions) >= limit:
                break
            suggestions.append(QuickSuggestion(
                saved_food_id=food["id"],
                name=food.get("name", "Unknown"),
                total_calories=food.get("total_calories") or 0,
                protein_g=food.get("total_protein_g") or 0.0,
                carbs_g=food.get("total_carbs_g") or 0.0,
                fat_g=food.get("total_fat_g") or 0.0,
                fiber_g=food.get("total_fiber_g"),
                times_logged=food.get("times_logged") or 0,
                last_logged_at=food.get("last_logged_at"),
                suggested_meal_type=suggested_meal_type,
                suggestion_reason="frequently_logged",
                tags=food.get("tags") or [],
            ))

        # 2. Get recently logged foods (last 7 days)
        week_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()
        recent_result = db.client.table("saved_foods").select("*").eq("user_id", user_id).gte("last_logged_at", week_ago).order("last_logged_at", desc=True).limit(5).execute()

        seen_ids = {s.saved_food_id for s in suggestions}
        for food in recent_result.data or []:
            if len(suggestions) >= limit:
                break
            if food["id"] in seen_ids:
                continue
            seen_ids.add(food["id"])
            suggestions.append(QuickSuggestion(
                saved_food_id=food["id"],
                name=food.get("name", "Unknown"),
                total_calories=food.get("total_calories") or 0,
                protein_g=food.get("total_protein_g") or 0.0,
                carbs_g=food.get("total_carbs_g") or 0.0,
                fat_g=food.get("total_fat_g") or 0.0,
                fiber_g=food.get("total_fiber_g"),
                times_logged=food.get("times_logged") or 0,
                last_logged_at=food.get("last_logged_at"),
                suggested_meal_type=suggested_meal_type,
                suggestion_reason="recent_favorite",
                tags=food.get("tags") or [],
            ))

        # 3. Get time-appropriate foods from templates
        template_result = db.client.table("meal_templates").select("*").or_(f"user_id.eq.{user_id},is_system_template.eq.true").eq("meal_type", suggested_meal_type).limit(5).execute()

        for template in template_result.data or []:
            if len(suggestions) >= limit:
                break
            # Create a pseudo saved_food_id for templates
            template_id = f"template:{template['id']}"
            if template_id in seen_ids:
                continue
            seen_ids.add(template_id)
            suggestions.append(QuickSuggestion(
                saved_food_id=template_id,
                name=template.get("name", "Unknown"),
                total_calories=template.get("total_calories") or 0,
                protein_g=template.get("total_protein_g") or 0.0,
                carbs_g=template.get("total_carbs_g") or 0.0,
                fat_g=template.get("total_fat_g") or 0.0,
                fiber_g=template.get("total_fiber_g"),
                times_logged=template.get("times_used") or 0,
                last_logged_at=template.get("last_used_at"),
                suggested_meal_type=suggested_meal_type,
                suggestion_reason="time_appropriate",
                tags=template.get("tags") or [],
            ))

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="quick_suggestions",
            endpoint="/api/v1/nutrition/quick-suggestions",
            message=f"Retrieved {len(suggestions)} quick suggestions",
            metadata={
                "time_of_day": time_of_day,
                "suggested_meal_type": suggested_meal_type,
                "suggestion_count": len(suggestions),
            },
            status_code=200
        )

        return QuickSuggestionsResponse(
            suggestions=suggestions[:limit],
            time_of_day=time_of_day,
            suggested_meal_type=suggested_meal_type,
        )

    except Exception as e:
        logger.error(f"Error getting quick suggestions: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition_preferences")


# =============================================================================
# Meal Templates Endpoints
# =============================================================================


# Include secondary endpoints
router.include_router(_endpoints_router)
