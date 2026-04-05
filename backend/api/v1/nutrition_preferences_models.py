"""Pydantic models for nutrition_preferences."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


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


class MealTemplateUpdate(BaseModel):
    """Request to update a meal template."""
    name: Optional[str] = Field(default=None, min_length=1, max_length=100)
    description: Optional[str] = Field(default=None, max_length=500)
    meal_type: Optional[str] = Field(default=None, max_length=50)
    food_items: Optional[List[MealTemplateFoodItem]] = Field(default=None, max_length=20)
    tags: Optional[List[str]] = Field(default=None, max_length=10)


class MealTemplateCreate(MealTemplateBase):
    """Request to create a meal template."""
    pass


class MealTemplate(MealTemplateBase):
    """Meal template from database."""
    id: str
    user_id: Optional[str] = None
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

