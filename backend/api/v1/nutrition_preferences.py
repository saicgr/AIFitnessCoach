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
from datetime import datetime, timedelta
from typing import List, Optional
import uuid
import logging
from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel, Field

from core.supabase_db import get_supabase_db
from core.auth import get_current_user
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
        logger.error(f"Error getting nutrition preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
            raise HTTPException(status_code=500, detail="Failed to update preferences")

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
        )

        return NutritionPreferencesResponse(
            user_id=user_id,
            preferences=preferences,
            updated_at=prefs_data.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating nutrition preferences: {e}")
        await log_user_error(
            user_id=user_id,
            action="nutrition_preferences_update",
            error=e,
            endpoint="/api/v1/nutrition/preferences",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


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
            raise HTTPException(status_code=500, detail="Failed to reset preferences")

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
        logger.error(f"Error resetting nutrition preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
        logger.error(f"Error quick logging food: {e}")
        await log_user_error(
            user_id=user_id,
            action="quick_log",
            error=e,
            endpoint="/api/v1/nutrition/quick-log",
            metadata={"saved_food_id": request.saved_food_id},
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


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
        logger.error(f"Error getting quick suggestions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Meal Templates Endpoints
# =============================================================================

@router.get("/templates", response_model=MealTemplatesResponse)
async def list_meal_templates(
    current_user: dict = Depends(get_current_user),
    meal_type: Optional[str] = Query(default=None, description="Filter by meal type"),
    include_system: bool = Query(default=True, description="Include system templates"),
):
    """
    List all meal templates (user's + system templates).

    Use meal_type query param to filter by specific meal type.
    """
    user_id = current_user["id"]
    logger.info(f"Listing meal templates for user {user_id}, meal_type={meal_type}")

    try:
        db = get_supabase_db()

        # Build query for user templates
        query = db.client.table("meal_templates").select("*")

        if include_system:
            query = query.or_(f"user_id.eq.{user_id},is_system_template.eq.true")
        else:
            query = query.eq("user_id", user_id)

        if meal_type:
            query = query.eq("meal_type", meal_type)

        query = query.order("created_at", desc=True)
        result = query.execute()

        templates = []
        for row in result.data or []:
            # Parse food items from JSONB
            food_items_raw = row.get("food_items") or []
            food_items = [MealTemplateFoodItem(**item) for item in food_items_raw]

            templates.append(MealTemplate(
                id=row["id"],
                user_id=row.get("user_id"),
                name=row.get("name", ""),
                description=row.get("description"),
                meal_type=row.get("meal_type", ""),
                food_items=food_items,
                tags=row.get("tags") or [],
                is_system_template=row.get("is_system_template", False),
                total_calories=row.get("total_calories") or 0,
                total_protein_g=row.get("total_protein_g") or 0.0,
                total_carbs_g=row.get("total_carbs_g") or 0.0,
                total_fat_g=row.get("total_fat_g") or 0.0,
                total_fiber_g=row.get("total_fiber_g"),
                times_used=row.get("times_used") or 0,
                last_used_at=row.get("last_used_at"),
                created_at=row.get("created_at"),
                updated_at=row.get("updated_at"),
            ))

        return MealTemplatesResponse(
            templates=templates,
            total_count=len(templates),
        )

    except Exception as e:
        logger.error(f"Error listing meal templates: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/templates", response_model=MealTemplate)
async def create_meal_template(
    request: MealTemplateCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new meal template.

    Templates allow one-tap logging of common meals.
    """
    user_id = current_user["id"]
    logger.info(f"Creating meal template '{request.name}' for user {user_id}")

    try:
        db = get_supabase_db()

        # Calculate totals
        totals = calculate_template_totals(request.food_items)

        # Prepare food items for storage
        food_items_data = [item.model_dump() for item in request.food_items]

        template_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()

        # Insert template
        result = db.client.table("meal_templates").insert({
            "id": template_id,
            "user_id": user_id,
            "name": request.name,
            "description": request.description,
            "meal_type": request.meal_type,
            "food_items": food_items_data,
            "tags": request.tags,
            "is_system_template": False,  # User templates are never system templates
            **totals,
            "times_used": 0,
            "created_at": now,
            "updated_at": now,
        }).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create template")

        row = result.data[0]

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="meal_template_create",
            endpoint="/api/v1/nutrition/templates",
            message=f"Created meal template '{request.name}'",
            metadata={
                "template_id": template_id,
                "meal_type": request.meal_type,
                "total_calories": totals["total_calories"],
                "food_items_count": len(request.food_items),
            },
            status_code=201
        )

        # Log user context for analytics
        await user_context_service.log_meal_template_created(
            user_id=user_id,
            template_name=request.name,
            total_calories=totals["total_calories"],
            food_count=len(request.food_items),
        )

        return MealTemplate(
            id=row["id"],
            user_id=row.get("user_id"),
            name=row.get("name", ""),
            description=row.get("description"),
            meal_type=row.get("meal_type", ""),
            food_items=request.food_items,
            tags=row.get("tags") or [],
            is_system_template=row.get("is_system_template", False),
            total_calories=row.get("total_calories") or 0,
            total_protein_g=row.get("total_protein_g") or 0.0,
            total_carbs_g=row.get("total_carbs_g") or 0.0,
            total_fat_g=row.get("total_fat_g") or 0.0,
            total_fiber_g=row.get("total_fiber_g"),
            times_used=row.get("times_used") or 0,
            last_used_at=row.get("last_used_at"),
            created_at=row.get("created_at"),
            updated_at=row.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating meal template: {e}")
        await log_user_error(
            user_id=user_id,
            action="meal_template_create",
            error=e,
            endpoint="/api/v1/nutrition/templates",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/templates/{template_id}", response_model=MealTemplate)
async def update_meal_template(
    template_id: str,
    request: MealTemplateUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Update an existing meal template.

    Only user-owned templates can be updated. System templates cannot be modified.
    """
    user_id = current_user["id"]
    logger.info(f"Updating meal template {template_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table("meal_templates").select("*").eq("id", template_id).maybeSingle().execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Template not found")

        if existing.data.get("is_system_template"):
            raise HTTPException(status_code=403, detail="Cannot modify system templates")

        if existing.data.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Build update data
        update_data = {"updated_at": datetime.utcnow().isoformat()}

        for field, value in request.model_dump(exclude_unset=True).items():
            if value is not None:
                if field == "food_items":
                    update_data["food_items"] = [item.model_dump() for item in value]
                    # Recalculate totals
                    totals = calculate_template_totals(value)
                    update_data.update(totals)
                else:
                    update_data[field] = value

        # Update template
        result = db.client.table("meal_templates").update(update_data).eq("id", template_id).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update template")

        row = result.data[0]

        # Parse food items
        food_items_raw = row.get("food_items") or []
        food_items = [MealTemplateFoodItem(**item) for item in food_items_raw]

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="meal_template_update",
            endpoint=f"/api/v1/nutrition/templates/{template_id}",
            message=f"Updated meal template '{row.get('name')}'",
            metadata={
                "template_id": template_id,
                "updated_fields": list(update_data.keys()),
            },
            status_code=200
        )

        return MealTemplate(
            id=row["id"],
            user_id=row.get("user_id"),
            name=row.get("name", ""),
            description=row.get("description"),
            meal_type=row.get("meal_type", ""),
            food_items=food_items,
            tags=row.get("tags") or [],
            is_system_template=row.get("is_system_template", False),
            total_calories=row.get("total_calories") or 0,
            total_protein_g=row.get("total_protein_g") or 0.0,
            total_carbs_g=row.get("total_carbs_g") or 0.0,
            total_fat_g=row.get("total_fat_g") or 0.0,
            total_fiber_g=row.get("total_fiber_g"),
            times_used=row.get("times_used") or 0,
            last_used_at=row.get("last_used_at"),
            created_at=row.get("created_at"),
            updated_at=row.get("updated_at"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating meal template: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/templates/{template_id}")
async def delete_meal_template(
    template_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a meal template.

    Only user-owned templates can be deleted. System templates cannot be removed.
    """
    user_id = current_user["id"]
    logger.info(f"Deleting meal template {template_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ownership
        existing = db.client.table("meal_templates").select("*").eq("id", template_id).maybeSingle().execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Template not found")

        if existing.data.get("is_system_template"):
            raise HTTPException(status_code=403, detail="Cannot delete system templates")

        if existing.data.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        template_name = existing.data.get("name")

        # Delete template
        db.client.table("meal_templates").delete().eq("id", template_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="meal_template_delete",
            endpoint=f"/api/v1/nutrition/templates/{template_id}",
            message=f"Deleted meal template '{template_name}'",
            metadata={"template_id": template_id},
            status_code=200
        )

        # Log user context for analytics
        await user_context_service.log_meal_template_deleted(
            user_id=user_id,
            template_id=template_id,
            template_name=template_name,
        )

        return {"status": "deleted", "id": template_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting meal template: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/templates/{template_id}/log", response_model=LogTemplateResponse)
async def log_meal_template(
    template_id: str,
    request: LogTemplateRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Log a meal template as a food log entry.

    Optionally override the meal type and adjust servings.
    """
    user_id = current_user["id"]
    logger.info(f"Logging meal template {template_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get template
        result = db.client.table("meal_templates").select("*").eq("id", template_id).maybeSingle().execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Template not found")

        template = result.data

        # Check access (user template or system template)
        if not template.get("is_system_template") and template.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Calculate nutrition based on servings
        servings = request.servings
        total_calories = int((template.get("total_calories") or 0) * servings)
        protein_g = float((template.get("total_protein_g") or 0) * servings)
        carbs_g = float((template.get("total_carbs_g") or 0) * servings)
        fat_g = float((template.get("total_fat_g") or 0) * servings)
        fiber_g = float((template.get("total_fiber_g") or 0) * servings) if template.get("total_fiber_g") else None

        # Scale food items
        food_items_raw = template.get("food_items") or []
        scaled_items = []
        for item in food_items_raw:
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

        # Use override meal type or template's meal type
        meal_type = request.meal_type or template.get("meal_type")

        # Create food log
        logged_at = datetime.utcnow()
        food_log = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=scaled_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=f"Logged from template: {template.get('name')}",
            health_score=None,
        )

        food_log_id = food_log.get("id") if food_log else str(uuid.uuid4())

        # Update template usage stats
        db.client.table("meal_templates").update({
            "times_used": (template.get("times_used") or 0) + 1,
            "last_used_at": logged_at.isoformat(),
        }).eq("id", template_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="meal_template_log",
            endpoint=f"/api/v1/nutrition/templates/{template_id}/log",
            message=f"Logged template '{template.get('name')}' ({total_calories} cal)",
            metadata={
                "food_log_id": food_log_id,
                "template_id": template_id,
                "meal_type": meal_type,
                "servings": servings,
                "total_calories": total_calories,
            },
            status_code=200
        )

        # Log user context for analytics
        await user_context_service.log_meal_template_logged(
            user_id=user_id,
            template_id=template_id,
            template_name=template.get("name", "Unknown"),
            meal_type=meal_type,
            total_calories=total_calories,
        )

        return LogTemplateResponse(
            success=True,
            food_log_id=food_log_id,
            template_id=template_id,
            template_name=template.get("name"),
            meal_type=meal_type,
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
        logger.error(f"Error logging meal template: {e}")
        await log_user_error(
            user_id=user_id,
            action="meal_template_log",
            error=e,
            endpoint=f"/api/v1/nutrition/templates/{template_id}/log",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Food Search Endpoints
# =============================================================================

@router.get("/search", response_model=FoodSearchResponse)
async def search_foods(
    current_user: dict = Depends(get_current_user),
    q: str = Query(..., min_length=1, max_length=100, description="Search query"),
    limit: int = Query(default=20, ge=1, le=50),
):
    """
    Fast food search with caching.

    Searches across:
    - User's saved foods
    - Meal templates
    - Food database (if available)

    Results are cached for repeated queries.
    """
    user_id = current_user["id"]
    search_query = q.strip().lower()
    logger.info(f"Searching foods for user {user_id}, query='{q}'")

    try:
        db = get_supabase_db()

        # Check cache first
        cache_key = f"{user_id}:{search_query}"
        cache_result = db.client.table("food_search_cache").select("*").eq("cache_key", cache_key).maybeSingle().execute()

        if cache_result.data:
            cache_entry = cache_result.data
            # Check if cache is still valid (1 hour)
            cached_at = datetime.fromisoformat(cache_entry.get("cached_at").replace("Z", "+00:00"))
            if datetime.now(cached_at.tzinfo) - cached_at < timedelta(hours=1):
                logger.info(f"Returning cached search results for query '{q}'")
                # Log user context for analytics (cache hit)
                await user_context_service.log_food_search_performed(
                    user_id=user_id,
                    query=q,
                    result_count=len(cache_entry.get("results") or []),
                    cache_hit=True,
                    source="cache",
                )
                return FoodSearchResponse(
                    results=cache_entry.get("results") or [],
                    query=q,
                    total_count=len(cache_entry.get("results") or []),
                    cached=True,
                )

        results = []

        # 1. Search user's saved foods
        saved_result = db.client.table("saved_foods").select("*").eq("user_id", user_id).ilike("name", f"%{search_query}%").limit(limit // 2).execute()

        for food in saved_result.data or []:
            results.append(FoodSearchResult(
                id=food["id"],
                name=food.get("name", "Unknown"),
                source="saved",
                total_calories=food.get("total_calories") or 0,
                protein_g=food.get("total_protein_g") or 0.0,
                carbs_g=food.get("total_carbs_g") or 0.0,
                fat_g=food.get("total_fat_g") or 0.0,
                fiber_g=food.get("total_fiber_g"),
                is_user_food=True,
            ))

        # 2. Search meal templates
        template_result = db.client.table("meal_templates").select("*").or_(f"user_id.eq.{user_id},is_system_template.eq.true").ilike("name", f"%{search_query}%").limit(limit // 4).execute()

        for template in template_result.data or []:
            results.append(FoodSearchResult(
                id=f"template:{template['id']}",
                name=template.get("name", "Unknown"),
                source="template",
                total_calories=template.get("total_calories") or 0,
                protein_g=template.get("total_protein_g") or 0.0,
                carbs_g=template.get("total_carbs_g") or 0.0,
                fat_g=template.get("total_fat_g") or 0.0,
                fiber_g=template.get("total_fiber_g"),
                is_user_food=template.get("user_id") == user_id,
            ))

        # 3. Search food database (if table exists)
        try:
            food_db_result = db.client.table("food_database").select("*").ilike("name", f"%{search_query}%").limit(limit // 4).execute()

            for food in food_db_result.data or []:
                results.append(FoodSearchResult(
                    id=food["id"],
                    name=food.get("name", "Unknown"),
                    source="database",
                    total_calories=food.get("calories") or 0,
                    protein_g=food.get("protein_g") or 0.0,
                    carbs_g=food.get("carbs_g") or 0.0,
                    fat_g=food.get("fat_g") or 0.0,
                    fiber_g=food.get("fiber_g"),
                    serving_size=food.get("serving_size"),
                    brand=food.get("brand"),
                    is_user_food=False,
                ))
        except Exception as e:
            # Food database table might not exist
            logger.debug(f"Food database search skipped: {e}")

        # Limit results
        results = results[:limit]

        # Cache results
        try:
            cache_data = {
                "cache_key": cache_key,
                "user_id": user_id,
                "query": search_query,
                "results": [r.model_dump() for r in results],
                "cached_at": datetime.utcnow().isoformat(),
            }
            db.client.table("food_search_cache").upsert(
                cache_data,
                on_conflict="cache_key"
            ).execute()
        except Exception as e:
            # Cache table might not exist
            logger.debug(f"Failed to cache search results: {e}")

        # Log user context for analytics (fresh search)
        await user_context_service.log_food_search_performed(
            user_id=user_id,
            query=q,
            result_count=len(results),
            cache_hit=False,
            source="api",
        )

        return FoodSearchResponse(
            results=results,
            query=q,
            total_count=len(results),
            cached=False,
        )

    except Exception as e:
        logger.error(f"Error searching foods: {e}")
        raise HTTPException(status_code=500, detail=str(e))
