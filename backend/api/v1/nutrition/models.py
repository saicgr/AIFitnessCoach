"""
Pydantic request/response models for nutrition endpoints.

All inline BaseModel classes from the original nutrition.py are
consolidated here for reuse across sub-modules.
"""
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, validator


# ── Food Log Models ──────────────────────────────────────────────

class FoodLogResponse(BaseModel):
    """Food log response model."""
    id: str
    user_id: str
    meal_type: str
    logged_at: str
    food_items: List[dict]
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    health_score: Optional[int] = None
    ai_feedback: Optional[str] = None
    notes: Optional[str] = None
    mood_before: Optional[str] = None
    mood_after: Optional[str] = None
    energy_level: Optional[int] = None
    # Inflammation / ultra-processed tracking
    inflammation_score: Optional[int] = None
    is_ultra_processed: Optional[bool] = None
    image_url: Optional[str] = None
    # Origin-of-log tracking
    source_type: Optional[str] = None  # 'image' | 'barcode' | 'text' | 'chat' | 'restaurant' | 'parse_app_screenshot' | 'parse_nutrition_label'
    user_query: Optional[str] = None   # Originating user input (search query, caption, chat message, product name, etc.)
    # Key micronutrients
    sodium_mg: Optional[float] = None
    sugar_g: Optional[float] = None
    saturated_fat_g: Optional[float] = None
    cholesterol_mg: Optional[float] = None
    potassium_mg: Optional[float] = None
    calcium_mg: Optional[float] = None
    iron_mg: Optional[float] = None
    vitamin_a_ug: Optional[float] = None
    vitamin_c_mg: Optional[float] = None
    vitamin_d_iu: Optional[float] = None
    created_at: str


class FoodItemEdit(BaseModel):
    """One per-field edit to a food item (cal/P/C/F) for the audit trail."""
    food_item_index: int
    food_item_name: str
    food_item_id: Optional[str] = None
    edited_field: str   # 'calories' | 'protein_g' | 'carbs_g' | 'fat_g'
    previous_value: float
    updated_value: float

    @validator('edited_field')
    def field_must_be_allowed(cls, v):
        if v not in ('calories', 'protein_g', 'carbs_g', 'fat_g'):
            raise ValueError(f"edited_field must be one of calories/protein_g/carbs_g/fat_g, got {v}")
        return v


class FoodItemEditResponse(BaseModel):
    """Audit row as returned by GET /food-logs/{id}/edits."""
    id: str
    food_log_id: str
    food_item_index: int
    food_item_name: str
    food_item_id: Optional[str] = None
    edited_field: str
    previous_value: float
    updated_value: float
    edit_source: str
    edited_at: str


class UpdateFoodLogRequest(BaseModel):
    total_calories: Optional[int] = None
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None
    fiber_g: Optional[float] = None
    weight_g: Optional[float] = None
    portion_multiplier: Optional[float] = None
    meal_type: Optional[str] = None
    logged_at: Optional[str] = None
    notes: Optional[str] = None
    food_items: Optional[List[dict]] = None
    # Per-field item edits recorded alongside the update for audit/analytics
    item_edits: Optional[List[FoodItemEdit]] = None


class UpdateMoodRequest(BaseModel):
    """Update mood/wellness data on a food log after logging."""
    mood_before: Optional[str] = None
    mood_after: Optional[str] = None
    energy_level: Optional[int] = None  # 1-5


# ── Summary Models ─────────────────────────────────────���─────────

class DailyNutritionResponse(BaseModel):
    """Daily nutrition summary response."""
    date: str
    total_calories: int
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    total_fiber_g: float
    meal_count: int
    avg_health_score: Optional[float] = None
    meals: List[FoodLogResponse] = []


class WeeklyNutritionResponse(BaseModel):
    """Weekly nutrition summary response."""
    start_date: str
    end_date: str
    daily_summaries: List[dict]
    total_calories: int
    average_daily_calories: float
    total_meals: int


class NutritionTargetsResponse(BaseModel):
    """Nutrition targets response."""
    user_id: str
    daily_calorie_target: Optional[int] = None
    daily_protein_target_g: Optional[float] = None
    daily_carbs_target_g: Optional[float] = None


# ── Barcode Models ───────────────────────────────────────────────

class BarcodeProductResponse(BaseModel):
    """Barcode product lookup response."""
    barcode: str
    product_name: str
    brand: Optional[str] = None
    categories: Optional[str] = None
    image_url: Optional[str] = None
    image_thumb_url: Optional[str] = None
    nutrients: dict
    nutriscore_grade: Optional[str] = None
    nova_group: Optional[int] = None
    ingredients_text: Optional[str] = None
    allergens: Optional[str] = None


class LogBarcodeRequest(BaseModel):
    """Request to log food from barcode."""
    user_id: str
    barcode: str = Field(..., max_length=100)
    meal_type: str = Field(..., max_length=20)
    servings: float = 1.0
    serving_size_g: Optional[float] = None

    @validator('user_id')
    def user_id_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('user_id cannot be empty')
        return v


class LogBarcodeResponse(BaseModel):
    """Response after logging food from barcode."""
    success: bool
    food_log_id: str
    product_name: str
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float


# ── Food Search Models ───────────────────────────────────────────

class USDAFoodResponse(BaseModel):
    """USDA food response."""
    fdc_id: int
    description: str
    brand_owner: Optional[str] = None
    branded_food_category: Optional[str] = None
    serving_size: Optional[float] = None
    serving_size_unit: Optional[str] = None
    household_serving_text: Optional[str] = None
    data_type: Optional[str] = None
    calories: Optional[float] = None
    protein_g: Optional[float] = None
    fat_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fiber_g: Optional[float] = None
    sugar_g: Optional[float] = None
    sodium_mg: Optional[float] = None
    saturated_fat_g: Optional[float] = None
    cholesterol_mg: Optional[float] = None
    potassium_mg: Optional[float] = None
    vitamin_d_iu: Optional[float] = None
    calcium_mg: Optional[float] = None
    iron_mg: Optional[float] = None


class USDASearchResponse(BaseModel):
    """USDA search response."""
    foods: List[USDAFoodResponse]
    total_hits: int
    current_page: int
    total_pages: int


class CombinedFoodSearchResponse(BaseModel):
    """Combined food search response."""
    usda_foods: List[USDAFoodResponse] = []
    database_foods: List[dict] = []
    total_results: int = 0


# ── Food Logging Models ─────────────────────────────────────────

class AnalyzeTextRequest(BaseModel):
    """Request to analyze food from text description (no logging)."""
    description: str = Field(..., max_length=2000)


class LogTextRequest(BaseModel):
    """Request to log food from text description."""
    user_id: str
    description: str = Field(..., max_length=2000)
    meal_type: str = Field(..., max_length=20)
    mood_before: Optional[str] = None
    # Distinguishes typed from dictated input. Populates food_logs.input_type.
    # Allowed values match the CHECK constraint added in migration 1960.
    input_type: Optional[str] = Field(default=None, max_length=30)

    @validator('user_id')
    def user_id_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('user_id cannot be empty')
        return v


class LogDirectRequest(BaseModel):
    """Request to log already-analyzed food directly (e.g., from restaurant mode with portion adjustments)."""
    user_id: str
    meal_type: str = Field(..., max_length=20)
    food_items: List[dict]
    total_calories: int
    total_protein: int
    total_carbs: int
    total_fat: int
    total_fiber: Optional[int] = None
    source_type: str = Field(default="restaurant", max_length=50)
    # Specific input method — populates food_logs.input_type. One of:
    # text, voice, camera, gallery, barcode, menu_scan, buffet_scan,
    # multi_image_scan, chat, ai_suggestion, manual, image, copy, watch.
    input_type: Optional[str] = Field(default=None, max_length=30)
    notes: Optional[str] = Field(default=None, max_length=500)
    # Originating user input (e.g. dish name the user selected, restaurant item they picked).
    user_query: Optional[str] = Field(default=None, max_length=500)
    # AI/vision description of the analyzed meal (e.g. Gemini's "feedback" string for
    # photo logs). When present, the server stores this instead of the generic
    # "Logged via {source_type}" placeholder so the meal list surfaces what the AI
    # actually saw.
    ai_feedback: Optional[str] = Field(default=None, max_length=2000)
    # Micronutrients
    sodium_mg: Optional[float] = None
    sugar_g: Optional[float] = None
    saturated_fat_g: Optional[float] = None
    cholesterol_mg: Optional[float] = None
    potassium_mg: Optional[float] = None
    vitamin_a_ug: Optional[float] = None
    vitamin_c_mg: Optional[float] = None
    vitamin_d_iu: Optional[float] = None
    vitamin_e_mg: Optional[float] = None
    vitamin_k_ug: Optional[float] = None
    vitamin_b1_mg: Optional[float] = None
    vitamin_b2_mg: Optional[float] = None
    vitamin_b3_mg: Optional[float] = None
    vitamin_b5_mg: Optional[float] = None
    vitamin_b6_mg: Optional[float] = None
    vitamin_b7_ug: Optional[float] = None
    vitamin_b9_ug: Optional[float] = None
    vitamin_b12_ug: Optional[float] = None
    calcium_mg: Optional[float] = None
    iron_mg: Optional[float] = None
    magnesium_mg: Optional[float] = None
    zinc_mg: Optional[float] = None
    phosphorus_mg: Optional[float] = None
    copper_mg: Optional[float] = None
    manganese_mg: Optional[float] = None
    selenium_ug: Optional[float] = None
    choline_mg: Optional[float] = None
    omega3_g: Optional[float] = None
    omega6_g: Optional[float] = None
    # Image storage (from analyze-image-stream S3 upload)
    image_url: Optional[str] = None
    image_storage_key: Optional[str] = None
    # Scores from analysis
    health_score: Optional[int] = None
    overall_meal_score: Optional[int] = None
    # Inflammation / ultra-processed tracking
    inflammation_score: Optional[int] = None
    is_ultra_processed: Optional[bool] = None
    # Pre-save per-field edits made in the Log Meal sheet before this save
    item_edits: Optional[List[FoodItemEdit]] = None
    # Explicit timestamp for the log. When the user is viewing a past date in
    # the Nutrition tab and taps "Log food," the entry must land on THAT date
    # — not "now". Expected ISO-8601 (e.g., "2026-04-20T15:30:00"). If
    # omitted, server defaults to user-tz "now" (preserves legacy behavior).
    logged_at: Optional[str] = Field(default=None, max_length=40)

    @validator('user_id')
    def user_id_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('user_id cannot be empty')
        return v


class FoodItemRanking(BaseModel):
    """Individual food item with goal-based ranking."""
    name: str
    amount: Optional[str] = None
    calories: int = 0
    protein_g: float = 0.0
    carbs_g: float = 0.0
    fat_g: float = 0.0
    fiber_g: Optional[float] = None
    goal_score: Optional[int] = None
    goal_alignment: Optional[str] = None
    reason: Optional[str] = None


class LogFoodResponse(BaseModel):
    """Response after logging food from image or text with goal-based analysis."""
    success: bool
    food_log_id: str
    food_items: List[dict]
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    overall_meal_score: Optional[int] = None
    health_score: Optional[int] = None
    goal_alignment_percentage: Optional[int] = None
    ai_suggestion: Optional[str] = None
    encouragements: Optional[List[str]] = None
    warnings: Optional[List[str]] = None
    recommended_swap: Optional[str] = None
    confidence_score: Optional[float] = None
    confidence_level: Optional[str] = None
    source_type: Optional[str] = None
    inflammation_score: Optional[int] = None
    is_ultra_processed: Optional[bool] = None


class FoodReviewRequest(BaseModel):
    """Request for AI food review."""
    food_name: str
    calories: int
    protein_g: float
    carbs_g: float
    fat_g: float


# ── Preferences Models ───────────────────────────────────────────

class NutritionPreferencesResponse(BaseModel):
    """Nutrition preferences response model."""
    id: Optional[str] = None
    user_id: str
    nutrition_goals: List[str] = []
    nutrition_goal: str = "maintain"
    rate_of_change: Optional[str] = None
    goal_weight_kg: Optional[float] = None
    goal_date: Optional[str] = None
    weeks_to_goal: Optional[int] = None
    calculated_bmr: Optional[int] = None
    calculated_tdee: Optional[int] = None
    target_calories: Optional[int] = None
    target_protein_g: Optional[int] = None
    target_carbs_g: Optional[int] = None
    target_fat_g: Optional[int] = None
    target_fiber_g: int = 25
    diet_type: str = "balanced"
    custom_carb_percent: Optional[int] = None
    custom_protein_percent: Optional[int] = None
    custom_fat_percent: Optional[int] = None
    allergies: List[str] = []
    dietary_restrictions: List[str] = []
    disliked_foods: List[str] = []
    meal_pattern: str = "3_meals"
    cooking_skill: str = "intermediate"
    cooking_time_minutes: int = 30
    budget_level: str = "moderate"
    show_ai_feedback_after_logging: bool = True
    calm_mode_enabled: bool = False
    show_weekly_instead_of_daily: bool = False
    adjust_calories_for_training: bool = True
    adjust_calories_for_rest: bool = False
    nutrition_onboarding_completed: bool = False
    onboarding_completed_at: Optional[datetime] = None
    last_recalculated_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    weekly_checkin_enabled: bool = True
    last_weekly_checkin_at: Optional[datetime] = None
    weekly_checkin_dismiss_count: int = 0


class NutritionPreferencesUpdate(BaseModel):
    """Nutrition preferences update request."""
    nutrition_goals: Optional[List[str]] = None
    nutrition_goal: Optional[str] = None
    rate_of_change: Optional[str] = None
    target_calories: Optional[int] = None
    target_protein_g: Optional[int] = None
    target_carbs_g: Optional[int] = None
    target_fat_g: Optional[int] = None
    target_fiber_g: Optional[int] = None
    diet_type: Optional[str] = None
    custom_carb_percent: Optional[int] = None
    custom_protein_percent: Optional[int] = None
    custom_fat_percent: Optional[int] = None
    allergies: Optional[List[str]] = None
    dietary_restrictions: Optional[List[str]] = None
    disliked_foods: Optional[List[str]] = None
    meal_pattern: Optional[str] = None
    cooking_skill: Optional[str] = None
    cooking_time_minutes: Optional[int] = None
    budget_level: Optional[str] = None
    show_ai_feedback_after_logging: Optional[bool] = None
    calm_mode_enabled: Optional[bool] = None
    show_weekly_instead_of_daily: Optional[bool] = None
    adjust_calories_for_training: Optional[bool] = None
    adjust_calories_for_rest: Optional[bool] = None
    weekly_checkin_enabled: Optional[bool] = None
    last_weekly_checkin_at: Optional[str] = None
    weekly_checkin_dismiss_count: Optional[int] = None


class DynamicTargetsResponse(BaseModel):
    """Dynamic nutrition targets response model."""
    target_calories: int = 2000
    target_protein_g: int = 150
    target_carbs_g: int = 200
    target_fat_g: int = 65
    target_fiber_g: int = 25
    is_training_day: bool = False
    is_fasting_day: bool = False
    is_rest_day: bool = True
    adjustment_reason: Optional[str] = None
    calorie_adjustment: int = 0


# ── Weight Tracking Models ───────────────────────────────────────

class WeightLogCreate(BaseModel):
    """Request model for creating a weight log"""
    user_id: str
    weight_kg: float
    logged_at: Optional[datetime] = None
    source: str = "manual"
    notes: Optional[str] = None


class WeightLogResponse(BaseModel):
    """Response model for weight log"""
    id: str
    user_id: str
    weight_kg: float
    logged_at: datetime
    source: str = "manual"
    notes: Optional[str] = None
    created_at: Optional[datetime] = None


class WeightTrendResponse(BaseModel):
    """Response model for weight trend"""
    start_weight: Optional[float] = None
    end_weight: Optional[float] = None
    change_kg: Optional[float] = None
    weekly_rate_kg: Optional[float] = None
    direction: str = "maintaining"
    days_analyzed: int = 0
    confidence: float = 0.0


# ── Onboarding Models ───────────────────────────────────────────

class NutritionOnboardingRequest(BaseModel):
    """Request model for completing nutrition onboarding"""
    user_id: str
    nutrition_goals: List[str] = []
    nutrition_goal: Optional[str] = None
    rate_of_change: Optional[str] = None
    diet_type: str = "balanced"
    allergies: List[str] = []
    dietary_restrictions: List[str] = []
    meal_pattern: str = "3_meals"
    fasting_start_hour: Optional[int] = None
    fasting_end_hour: Optional[int] = None
    cooking_skill: str = "intermediate"
    cooking_time_minutes: int = 30
    budget_level: str = "moderate"
    custom_carb_percent: Optional[int] = None
    custom_protein_percent: Optional[int] = None
    custom_fat_percent: Optional[int] = None

    @validator('user_id')
    def user_id_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('user_id cannot be empty')
        return v

    # Pre-calculated values from frontend (optional)
    calculated_bmr: Optional[int] = None
    calculated_tdee: Optional[int] = None
    target_calories: Optional[int] = None
    target_protein_g: Optional[int] = None
    target_carbs_g: Optional[int] = None
    target_fat_g: Optional[int] = None

    @property
    def primary_goal(self) -> str:
        """Get primary goal - first in goals list or legacy goal field"""
        if self.nutrition_goals:
            return self.nutrition_goals[0]
        return self.nutrition_goal or "maintain"

    @property
    def all_goals(self) -> List[str]:
        """Get all goals as list"""
        if self.nutrition_goals:
            return self.nutrition_goals
        if self.nutrition_goal:
            return [self.nutrition_goal]
        return ["maintain"]


class SkipOnboardingRequest(BaseModel):
    """Request to skip nutrition onboarding."""
    user_id: str


# ── Streak Models ────────────────────────────────────────────────

class NutritionStreakResponse(BaseModel):
    """Response model for nutrition streak"""
    id: Optional[str] = None
    user_id: str
    current_streak_days: int = 0
    streak_start_date: Optional[datetime] = None
    last_logged_date: Optional[datetime] = None
    freezes_available: int = 2
    freezes_used_this_week: int = 0
    week_start_date: Optional[datetime] = None
    longest_streak_ever: int = 0
    total_days_logged: int = 0
    weekly_goal_enabled: bool = False
    weekly_goal_days: int = 5
    days_logged_this_week: int = 0


# ── Micronutrient Models ────────────────────────────────────────

class PinnedNutrientsUpdate(BaseModel):
    """Update pinned micronutrients."""
    pinned_nutrients: List[str]


# ── Adaptive / TDEE Models ──────────────────────────────────────

class AdaptiveCalculationResponse(BaseModel):
    """Adaptive TDEE calculation response."""
    id: Optional[str] = None
    user_id: str
    calculated_tdee: int = 0
    calculated_at: Optional[datetime] = None
    period_start: Optional[datetime] = None
    period_end: Optional[datetime] = None
    avg_daily_intake: Optional[int] = None
    start_trend_weight_kg: Optional[float] = None
    end_trend_weight_kg: Optional[float] = None
    data_quality_score: Optional[float] = None
    confidence_level: Optional[str] = None
    days_logged: Optional[int] = None
    weight_entries: Optional[int] = None
    smoothed_tdee: Optional[int] = None
    confidence_score: float = 0.0
    data_points: int = 0
    weight_trend_kg_per_week: Optional[float] = None
    avg_daily_calories: Optional[int] = None
    period_days: int = 14
    last_calculated_at: Optional[datetime] = None
    recommendation: Optional[str] = None


# ── Cooking Conversion Models ───────────────────────────────────

class CookingConversionFactorResponse(BaseModel):
    """Cooking conversion factor response."""
    id: Optional[str] = None
    food_name: str
    food_category: str
    raw_to_cooked_ratio: float
    cooked_to_raw_ratio: float
    cooking_method: Optional[str] = None
    notes: Optional[str] = None
    moisture_loss_percent: Optional[float] = None
    fat_absorption_percent: Optional[float] = None


class ConvertWeightRequest(BaseModel):
    """Request to convert between raw and cooked weight."""
    food_name: str
    weight_g: float
    direction: str = "raw_to_cooked"
    cooking_method: Optional[str] = None


class ConvertWeightResponse(BaseModel):
    """Response for weight conversion."""
    original_weight_g: float
    converted_weight_g: float
    direction: str
    food_name: str
    cooking_method: Optional[str] = None
    conversion_ratio: float
    confidence: str = "medium"
    notes: Optional[str] = None


class CookingConversionsListResponse(BaseModel):
    """Response for listing cooking conversions."""
    conversions: List[CookingConversionFactorResponse]
    total_count: int
    categories: List[str]


# ── Weekly Recommendation Models ────────────────────────────────

class WeeklyRecommendationResponse(BaseModel):
    """Weekly recommendation response."""
    id: Optional[str] = None
    user_id: str
    week_start: Optional[str] = None
    status: str = "pending"
    recommendation_type: Optional[str] = None
    current_avg_calories: Optional[int] = None
    recommended_calories: Optional[int] = None
    calorie_change: Optional[int] = None
    reasoning: Optional[str] = None
    suggested_protein_g: Optional[int] = None
    suggested_carbs_g: Optional[int] = None
    suggested_fat_g: Optional[int] = None
    weight_trend_direction: Optional[str] = None
    weight_change_kg: Optional[float] = None
    adherence_score: Optional[float] = None
    created_at: Optional[datetime] = None
    responded_at: Optional[datetime] = None


class WeeklySummaryResponse(BaseModel):
    """Weekly check-in summary response."""
    avg_daily_calories: int = 0
    avg_daily_protein_g: int = 0
    avg_daily_carbs_g: int = 0
    avg_daily_fat_g: int = 0
    days_logged: int = 0
    total_days: int = 7
    adherence_percentage: int = 0
    calorie_target: int = 2000
    weight_change_kg: Optional[float] = None


# ── Detailed TDEE / Adherence Models ────────────────────────────

class DetailedTDEEResponse(BaseModel):
    """Detailed TDEE response with breakdown."""
    tdee: int = 0
    confidence_low: Optional[int] = None
    confidence_high: Optional[int] = None
    uncertainty_display: Optional[str] = None
    uncertainty_calories: Optional[int] = None
    data_quality_score: Optional[float] = None
    weight_change_kg: Optional[float] = None
    avg_daily_intake: Optional[int] = None
    start_weight_kg: Optional[float] = None
    end_weight_kg: Optional[float] = None
    days_analyzed: Optional[int] = None
    food_logs_count: Optional[int] = None
    weight_logs_count: Optional[int] = None
    weight_trend: Optional[dict] = None
    metabolic_adaptation: Optional[dict] = None
    confidence_level: Optional[str] = None


class AdherenceSummaryResponse(BaseModel):
    """Adherence summary response."""
    weekly_adherence: List[dict] = []
    average_adherence: Optional[float] = None
    sustainability_score: Optional[float] = None
    sustainability_rating: Optional[str] = None
    recommendation: Optional[str] = None
    weeks_analyzed: int = 0


class RecommendationOption(BaseModel):
    """A single recommendation option for the user."""
    option_type: str
    label: str = ""
    calories: int
    protein_g: int
    carbs_g: int
    fat_g: int
    expected_weekly_change_kg: Optional[float] = None
    sustainability_rating: str = "medium"
    description: str = ""
    is_recommended: bool = False


class RecommendationOptionsResponse(BaseModel):
    """Response containing multiple recommendation options."""
    current_tdee: Optional[int] = None
    current_goal: Optional[str] = None
    adherence_score: Optional[float] = None
    has_adaptation: Optional[bool] = None
    adaptation_details: Optional[dict] = None
    options: List[RecommendationOption] = []
    recommended_option: Optional[str] = None


class SelectRecommendationRequest(BaseModel):
    """Request to select a recommendation option."""
    option_type: str


# ── Food Report Models ──────────────────────────────────────────

class FoodReportRequest(BaseModel):
    """Request to report incorrect food data or submit corrections."""
    user_id: str
    food_database_id: Optional[int] = None
    food_name: str
    reported_issue: Optional[str] = None
    original_calories: Optional[float] = None
    original_protein: Optional[float] = None
    original_carbs: Optional[float] = None
    original_fat: Optional[float] = None
    corrected_calories: Optional[float] = None
    corrected_protein: Optional[float] = None
    corrected_carbs: Optional[float] = None
    corrected_fat: Optional[float] = None
    data_source: Optional[str] = None
    food_log_id: Optional[str] = None
    # Traceability fields for debugging bad analyses
    report_type: Optional[str] = None       # "wrong_nutrition" | "wrong_food" | "other"
    original_query: Optional[str] = None    # what the user originally typed
    analysis_response: Optional[dict] = None  # full Gemini/cache response JSON
    all_food_items: Optional[list] = None   # all food items returned by analysis


class FoodReportResponse(BaseModel):
    """Response after submitting a food report."""
    success: bool
    report_id: str
    message: str


# ── Food Patterns (Nutrition > Patterns tab) ─────────────────────

class FoodPatternEntry(BaseModel):
    """A single food's mood/energy aggregate over the last N days."""
    food_name: str
    logs: int                          # confirmed + inferred
    confirmed_count: int
    inferred_count: int
    negative_mood_count: int
    positive_mood_count: int
    avg_energy: Optional[float] = None
    low_energy_count: int = 0
    high_energy_count: int = 0
    dominant_symptom: Optional[str] = None  # e.g. "bloated"
    last_logged_at: Optional[str] = None
    negative_score: float
    positive_score: float


class FoodPatternsMoodResponse(BaseModel):
    """GET /nutrition/food-patterns/mood response."""
    energizing_foods: List[FoodPatternEntry]
    draining_foods: List[FoodPatternEntry]
    total_logs_analyzed: int
    days_window: int
    oldest_log_date: Optional[str] = None
    checkin_disabled: bool = False
    inference_enabled: bool = True


class TopFoodEntry(BaseModel):
    """A single food's total for a given nutrient over the selected range."""
    food_name: str
    total_value: float
    unit: str                          # "g", "mg", "kcal"
    occurrences: int
    last_image_url: Optional[str] = None
    last_food_score: Optional[int] = None
    last_logged_at: Optional[str] = None


class TopFoodsResponse(BaseModel):
    """GET /nutrition/food-patterns/top-foods response."""
    metric: str                        # calories | protein | carbs | ...
    range: str                         # day | week | month | 90d
    start_date: str
    end_date: str
    items: List[TopFoodEntry]


class DailyMacroSeriesPoint(BaseModel):
    date: str                          # YYYY-MM-DD (user-local)
    calories: int = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0
    fiber_g: float = 0


class MacrosSummaryResponse(BaseModel):
    """GET /nutrition/food-patterns/macros-summary response."""
    range: str
    start_date: str
    end_date: str
    days_counted: int
    avg_calories: int = 0
    avg_protein_g: float = 0
    avg_carbs_g: float = 0
    avg_fat_g: float = 0
    avg_fiber_g: float = 0
    calorie_goal: Optional[int] = None
    protein_goal: Optional[int] = None
    carbs_goal: Optional[int] = None
    fat_goal: Optional[int] = None
    fiber_goal: Optional[int] = None
    daily_series: List[DailyMacroSeriesPoint]


class PatternsHistoryResponse(BaseModel):
    """GET /nutrition/food-patterns/history response."""
    items: List[FoodLogResponse]
    total: int
    limit: int
    offset: int


class InferenceConfirmRequest(BaseModel):
    """PATCH /food-logs/{id}/inference — confirm/dismiss an AI-inferred mood."""
    action: str  # "confirm" | "dismiss"

    @validator('action')
    def action_must_be_allowed(cls, v):
        if v not in ("confirm", "dismiss"):
            raise ValueError("action must be 'confirm' or 'dismiss'")
        return v
