"""
Gemini API Response Schemas for Structured Outputs.

These Pydantic models are used with Gemini's `response_schema` parameter
to guarantee valid JSON responses that match the expected structure.

This makes the codebase model-agnostic - switching between Gemini versions
(2.5 Flash, 3.0 Flash, etc.) will work seamlessly.

Usage:
    from models.gemini_schemas import GeneratedWorkoutResponse

    response = await client.aio.models.generate_content(
        model=self.model,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=GeneratedWorkoutResponse,
        ),
    )
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from enum import Enum


# =============================================================================
# INTENT EXTRACTION SCHEMAS
# =============================================================================

class CoachIntentEnum(str, Enum):
    """Possible intents extracted from user messages."""
    ADD_EXERCISE = "add_exercise"
    REMOVE_EXERCISE = "remove_exercise"
    SWAP_WORKOUT = "swap_workout"
    MODIFY_INTENSITY = "modify_intensity"
    RESCHEDULE = "reschedule"
    REPORT_INJURY = "report_injury"
    DELETE_WORKOUT = "delete_workout"
    RECOMMEND_WORKOUT_CHANGE = "recommend_workout_change"
    QUESTION = "question"
    ANALYZE_FOOD = "analyze_food"
    NUTRITION_SUMMARY = "nutrition_summary"
    RECENT_MEALS = "recent_meals"
    CHANGE_SETTING = "change_setting"
    NAVIGATE = "navigate"
    START_WORKOUT = "start_workout"
    COMPLETE_WORKOUT = "complete_workout"
    LOG_HYDRATION = "log_hydration"
    GENERATE_QUICK_WORKOUT = "generate_quick_workout"
    SET_WATER_GOAL = "set_water_goal"
    LOG_WEIGHT = "log_weight"
    GENERATE_WEEKLY_PLAN = "generate_weekly_plan"
    ADJUST_PLAN = "adjust_plan"
    EXPLAIN_PLAN = "explain_plan"


class IntentExtractionResponse(BaseModel):
    """Schema for intent extraction from user messages."""
    intent: str = Field(..., description="The detected intent from CoachIntent enum")
    exercises: List[str] = Field(default=[], description="Exercise names mentioned")
    muscle_groups: List[str] = Field(default=[], description="Muscle groups mentioned")
    modification: Optional[str] = Field(default=None, description="Modification details")
    body_part: Optional[str] = Field(default=None, description="Body part mentioned")
    setting_name: Optional[str] = Field(default=None, description="Setting to change")
    setting_value: Optional[bool] = Field(default=None, description="New setting value")
    destination: Optional[str] = Field(default=None, description="Navigation destination")
    hydration_amount: Optional[int] = Field(default=None, description="Number of glasses/cups")
    water_goal_glasses: Optional[int] = Field(default=None, description="Daily water goal in glasses")
    weight_value: Optional[float] = Field(default=None, description="Weight value to log")


# =============================================================================
# EXERCISE EXTRACTION SCHEMAS
# =============================================================================

class ExerciseListResponse(BaseModel):
    """Schema for extracting exercise names from AI response."""
    exercises: List[str] = Field(default=[], description="List of exercise names")


class ExerciseIndicesResponse(BaseModel):
    """Schema for AI-selected exercise indices from RAG results."""
    selected_indices: List[int] = Field(..., description="1-indexed list of selected exercise positions")


# =============================================================================
# WORKOUT GENERATION SCHEMAS
# =============================================================================

class SetTargetSchema(BaseModel):
    """Schema for per-set AI targets (like Gravl/Hevy)."""
    set_number: int = Field(..., description="Set number (1-indexed)")
    set_type: str = Field(..., description="REQUIRED: Set type - must be one of: 'warmup', 'working', 'drop', 'failure', 'amrap'")
    target_reps: int = Field(..., description="Target reps for this set")
    target_weight_kg: Optional[float] = Field(default=None, description="Target weight in kg for this set")
    target_hold_seconds: Optional[int] = Field(default=None, description="Target hold time in seconds for timed exercises (planks, wall sits). Use for progressive holds.")
    target_rpe: Optional[int] = Field(default=None, description="Target RPE (1-10) for this set")
    target_rir: Optional[int] = Field(default=None, description="Target RIR (0-5) for this set")


class WorkoutExerciseSchema(BaseModel):
    """Schema for a single exercise in a generated workout."""
    name: str = Field(..., description="Exercise name")
    sets: int = Field(default=3, description="Number of sets")
    reps: int = Field(default=12, description="Reps per set (1 for duration-based)")
    weight_kg: Optional[float] = Field(default=None, description="Starting weight in kg")
    rest_seconds: int = Field(default=60, description="Rest between sets in seconds")
    duration_seconds: Optional[int] = Field(default=None, description="Duration for cardio/timed exercises")
    hold_seconds: Optional[int] = Field(default=None, description="Hold time for static exercises")
    equipment: Optional[str] = Field(default=None, description="Equipment required")
    muscle_group: Optional[str] = Field(default=None, description="Primary muscle targeted")
    is_unilateral: bool = Field(default=False, description="True if single-arm/leg exercise")
    notes: Optional[str] = Field(default=None, description="Form tips or modifications")
    is_drop_set: bool = Field(default=False, description="True if last set(s) should be drop sets")
    is_failure_set: bool = Field(default=False, description="True if final set should be taken to failure")
    drop_set_count: Optional[int] = Field(default=None, description="Number of drop sets (typically 2-3)")
    drop_set_percentage: Optional[int] = Field(default=None, description="Weight reduction percentage per drop (typically 20-25%)")
    set_targets: List[SetTargetSchema] = Field(..., description="REQUIRED: Per-set AI targets with specific weight/reps for each set. Must match 'sets' count.")


class GeneratedWorkoutResponse(BaseModel):
    """Schema for AI-generated workout plans."""
    name: str = Field(..., description="Creative workout name")
    type: str = Field(..., description="Workout type (strength, cardio, etc.)")
    difficulty: str = Field(..., description="Difficulty level")
    description: Optional[str] = Field(default=None, description="1-2 sentence explanation of the workout's training logic and structure")
    duration_minutes: int = Field(..., description="Total workout duration")
    target_muscles: List[str] = Field(default=[], description="Primary muscles targeted")
    exercises: List[WorkoutExerciseSchema] = Field(..., description="List of exercises")
    notes: Optional[str] = Field(default=None, description="Overall workout tips")


class WorkoutNameItem(BaseModel):
    """Schema for a single workout name suggestion."""
    name: str = Field(..., description="Creative workout name")
    type: str = Field(..., description="Workout type")
    difficulty: str = Field(..., description="Difficulty level")


class WorkoutNamesResponse(BaseModel):
    """Schema for workout name generation."""
    workout_names: List[WorkoutNameItem] = Field(..., description="List of workout name suggestions")


class WorkoutNamingResponse(BaseModel):
    """Schema for generating workout names (without exercises - those come from RAG).

    This is used by generate_workout_from_library() which only needs Gemini
    to provide a creative name and tip. Exercises are selected by RAG, not Gemini.
    """
    name: str = Field(..., description="Creative workout name (3-4 words)")
    type: str = Field(..., description="Workout type (strength, cardio, etc.)")
    difficulty: str = Field(..., description="Difficulty level")
    notes: Optional[str] = Field(default=None, description="Personalized tip for the user")


# =============================================================================
# EXERCISE REASONING SCHEMAS
# =============================================================================

class ExerciseReasoningItem(BaseModel):
    """Schema for individual exercise reasoning."""
    exercise_name: str = Field(..., description="Name of the exercise")
    reasoning: str = Field(..., description="Why this exercise was selected")


class ExerciseReasoningResponse(BaseModel):
    """Schema for workout/exercise reasoning."""
    workout_reasoning: str = Field(..., description="Overall workout design reasoning")
    exercise_reasoning: List[ExerciseReasoningItem] = Field(..., description="Per-exercise reasoning")


# =============================================================================
# FOOD ANALYSIS SCHEMAS
# =============================================================================

class FoodItemSchema(BaseModel):
    """Schema for a single analyzed food item."""
    name: str = Field(..., description="Food name")
    amount: str = Field(..., description="Portion size description")
    calories: int = Field(..., description="Calories")
    protein_g: float = Field(..., description="Protein in grams")
    carbs_g: float = Field(..., description="Carbohydrates in grams")
    fat_g: float = Field(..., description="Fat in grams")
    fiber_g: float = Field(default=0, description="Fiber in grams")
    weight_g: Optional[float] = Field(default=None, description="Weight in grams")
    unit: str = Field(default="g", description="Measurement unit")
    count: Optional[int] = Field(default=None, description="Count for countable items")
    weight_per_unit_g: Optional[float] = Field(default=None, description="Weight per unit for countable items")
    goal_score: Optional[int] = Field(default=None, description="Score 1-10 based on user goals")
    inflammation_score: Optional[int] = Field(default=None, description="Inflammation score 1-10, 10 = most inflammatory")
    # Structured drivers of inflammation_score. 1-3 short tags like
    # 'deep_fried', 'refined_flour', 'added_sugar', 'omega3_rich',
    # 'leafy_greens'. Surfaced as chip-badges in the Score Explain sheet.
    inflammation_triggers: Optional[List[str]] = Field(default=None, description="1-3 short tags naming drivers of inflammation_score (e.g. deep_fried, refined_flour, added_sugar). Pick from: deep_fried, seed_oil, refined_flour, added_sugar, processed_meat, saturated_fat, omega6_high, artificial_additives, omega3_rich, leafy_greens, olive_oil, turmeric, whole_grains, fermented, berries, fatty_fish.")
    is_ultra_processed: Optional[bool] = Field(default=None, description="True if NOVA Group 4 ultra-processed food")
    # Added sugar is the single most actionable nutrition signal; surface it
    # as a first-class field so the Health Strip can render it on its own pill.
    # WHO adult daily limit = 25 g; the UI colours pills accordingly.
    added_sugar_g: Optional[float] = Field(default=None, description="Grams of added sugar per serving (excludes naturally-occurring sugars in whole fruit/dairy). Use 0.0 for no added sugar, never null.")
    glycemic_load: Optional[int] = Field(default=None, description="Glycemic load per serving (GI × carbs_g / 100). <10 low, 10-19 medium, 20+ high. Null ONLY for near-zero-carb items (<2g carbs).")
    fodmap_rating: Optional[str] = Field(default=None, description="Monash FODMAP classification: 'low' | 'medium' | 'high'. Required for every cooked dish.")
    fodmap_reason: Optional[str] = Field(default=None, description="≤6 words naming the FODMAP trigger(s). Null only when fodmap_rating == 'low'.")


class FoodAnalysisResponse(BaseModel):
    """Schema for food image/text analysis."""
    food_items: List[FoodItemSchema] = Field(..., description="List of food items")
    total_calories: int = Field(..., description="Total calories")
    protein_g: float = Field(..., description="Total protein")
    carbs_g: float = Field(..., description="Total carbs")
    fat_g: float = Field(..., description="Total fat")
    fiber_g: float = Field(default=0, description="Total fiber")
    # Micronutrients — Vitamins
    vitamin_a_ug: Optional[float] = Field(default=None, description="Vitamin A in micrograms")
    vitamin_c_mg: Optional[float] = Field(default=None, description="Vitamin C in mg")
    vitamin_d_iu: Optional[float] = Field(default=None, description="Vitamin D in IU")
    vitamin_e_mg: Optional[float] = Field(default=None, description="Vitamin E in mg")
    vitamin_k_ug: Optional[float] = Field(default=None, description="Vitamin K in micrograms")
    vitamin_b1_mg: Optional[float] = Field(default=None, description="Thiamine B1 in mg")
    vitamin_b2_mg: Optional[float] = Field(default=None, description="Riboflavin B2 in mg")
    vitamin_b3_mg: Optional[float] = Field(default=None, description="Niacin B3 in mg")
    vitamin_b6_mg: Optional[float] = Field(default=None, description="Vitamin B6 in mg")
    vitamin_b9_ug: Optional[float] = Field(default=None, description="Folate B9 in micrograms")
    vitamin_b12_ug: Optional[float] = Field(default=None, description="Vitamin B12 in micrograms")
    choline_mg: Optional[float] = Field(default=None, description="Choline in mg")
    # Micronutrients — Minerals
    calcium_mg: Optional[float] = Field(default=None, description="Calcium in mg")
    iron_mg: Optional[float] = Field(default=None, description="Iron in mg")
    magnesium_mg: Optional[float] = Field(default=None, description="Magnesium in mg")
    zinc_mg: Optional[float] = Field(default=None, description="Zinc in mg")
    selenium_ug: Optional[float] = Field(default=None, description="Selenium in micrograms")
    potassium_mg: Optional[float] = Field(default=None, description="Potassium in mg")
    sodium_mg: Optional[float] = Field(default=None, description="Sodium in mg")
    phosphorus_mg: Optional[float] = Field(default=None, description="Phosphorus in mg")
    copper_mg: Optional[float] = Field(default=None, description="Copper in mg")
    manganese_mg: Optional[float] = Field(default=None, description="Manganese in mg")
    iodine_ug: Optional[float] = Field(default=None, description="Iodine in micrograms")
    # Micronutrients — Fatty Acids & Other
    omega3_g: Optional[float] = Field(default=None, description="Omega-3 fatty acids in grams")
    omega6_g: Optional[float] = Field(default=None, description="Omega-6 fatty acids in grams")
    sugar_g: Optional[float] = Field(default=None, description="Total sugar in grams")
    cholesterol_mg: Optional[float] = Field(default=None, description="Cholesterol in mg")
    caffeine_mg: Optional[float] = Field(default=None, description="Caffeine in mg")
    # Spelling correction
    corrected_query: Optional[str] = Field(default=None, description="Corrected food description if user had typos/misspellings, null if no correction needed")
    # Feedback fields
    feedback: Optional[str] = Field(default=None, description="Nutritional feedback")
    overall_meal_score: Optional[int] = Field(default=None, description="Overall score 1-10")
    encouragements: Optional[List[str]] = Field(default=None, description="Positive aspects of the meal")
    warnings: Optional[List[str]] = Field(default=None, description="Nutritional concerns - high sodium, low fiber, excess calories, etc. Always include for scores 1-7")
    ai_suggestion: Optional[str] = Field(default=None, description="Actionable tip starting with 'Next time:'")
    recommended_swap: Optional[str] = Field(default=None, description="Concrete healthier swap with benefit, e.g. 'Swap white rice for brown rice: +3g fiber'")
    plate_description: Optional[str] = Field(default=None, description="Brief visual description of the plate/scene for image analysis, max 100 chars. e.g. 'A South Indian breakfast with steamed idlis, sambar, and chutneys'")
    inflammation_score: Optional[int] = Field(default=None, description="Meal-level inflammation score 1-10, calorie-weighted average of items")
    is_ultra_processed: Optional[bool] = Field(default=None, description="True if meal contains predominantly NOVA Group 4 ultra-processed foods")
    # Meal-level roll-ups (mirror the per-item fields above).
    inflammation_triggers: Optional[List[str]] = Field(default=None, description="Up to 3 dominant inflammation drivers across the meal.")
    added_sugar_g: Optional[float] = Field(default=None, description="Total added sugar across the meal in grams.")
    glycemic_load: Optional[int] = Field(default=None, description="Sum of per-item glycemic_loads (treat null as 0).")
    fodmap_rating: Optional[str] = Field(default=None, description="Highest FODMAP rating across items (high > medium > low).")
    fodmap_reason: Optional[str] = Field(default=None, description="Concatenated trigger reasons across items.")


# =============================================================================
# MENU / BUFFET ANALYSIS SCHEMAS
# =============================================================================
#
# These are passed as `response_schema` to Gemini so every dish returned from
# a menu or buffet scan is guaranteed to carry the full health-signal set —
# inflammation_score + inflammation_triggers + glycemic_load + fodmap_rating
# + fodmap_reason + added_sugar_g + is_ultra_processed. Without a schema
# Gemini silently drops fields and the Health Strip ends up with gaps.


class MenuDishSchema(BaseModel):
    """Schema for a single dish parsed from a menu or buffet image.

    Kept separate from FoodItemSchema (plate mode) because menu dishes carry
    restaurant-specific context (price / currency / section / allergens)
    that plate items don't have.
    """
    name: str = Field(..., description="Dish name as shown on the menu.")
    calories: int = Field(..., description="Calories per single serving.")
    protein_g: float = Field(..., description="Protein grams per serving.")
    carbs_g: float = Field(..., description="Carb grams per serving.")
    fat_g: float = Field(..., description="Fat grams per serving.")
    weight_g: Optional[float] = Field(default=None, description="Estimated serving weight in grams.")
    serving_description: Optional[str] = Field(default=None, description="Human-readable portion description (e.g. '1 cup, heaping').")
    price: Optional[float] = Field(default=None, description="Listed menu price; null if not visible on the menu.")
    currency: Optional[str] = Field(default=None, description="ISO-ish currency code (USD/EUR/INR). Null if no price.")
    detected_allergens: Optional[List[str]] = Field(default=None, description="FDA Big 9 allergens detected: milk, egg, fish, crustacean_shellfish, tree_nuts, wheat, peanuts, soybeans, sesame.")
    rating: str = Field(..., description="Goal-fit: 'green' | 'yellow' | 'red'.")
    rating_reason: Optional[str] = Field(default=None, description="≤8 words justifying the goal-fit rating.")
    inflammation_score: int = Field(..., description="Per-serving inflammation score 0-10. 0-3 anti, 4-6 neutral, 7-10 highly inflammatory. NEVER null.")
    inflammation_triggers: List[str] = Field(..., description="1-3 short tags naming drivers of inflammation_score (pick from deep_fried, seed_oil, refined_flour, added_sugar, processed_meat, saturated_fat, omega6_high, artificial_additives, omega3_rich, leafy_greens, olive_oil, turmeric, whole_grains, fermented, berries, fatty_fish; free-form accepted). NEVER empty.")
    glycemic_load: Optional[int] = Field(default=None, description="Per-serving GL (GI × carbs_g / 100). Null ONLY if carbs_g < 2.")
    fodmap_rating: str = Field(..., description="Monash FODMAP classification: 'low' | 'medium' | 'high'. Required for every dish.")
    fodmap_reason: Optional[str] = Field(default=None, description="≤6 words naming the FODMAP trigger(s). Null ONLY when fodmap_rating == 'low'.")
    added_sugar_g: float = Field(..., description="Added sugar grams per serving (excludes whole-fruit / whole-dairy sugars). Use 0.0 when there is none; never null.")
    is_ultra_processed: bool = Field(..., description="True iff the dish is predominantly NOVA Group 4 (industrial emulsifiers, HFCS, isolates, etc.).")
    coach_tip: Optional[str] = Field(default=None, description="≤18 words: pick-or-skip guidance tailored to the user's goals.")


class BuffetAnalysisResponse(BaseModel):
    """Schema for buffet-mode multi-dish analysis — flat list of dishes."""
    analysis_type: str = Field(default="buffet", description="Always 'buffet'.")
    dishes: List[MenuDishSchema] = Field(..., description="Every distinct dish visible in the buffet. Do not skip any.")


class MenuSectionSchema(BaseModel):
    """One section of a menu (appetizers / mains / desserts / etc.)."""
    section_name: str = Field(..., description="Normalised section: breakfast | appetizers | mains | sides | desserts | drinks | specials | uncategorized.")
    dishes: List[MenuDishSchema] = Field(..., description="Dishes within this section.")


class MenuAnalysisResponse(BaseModel):
    """Schema for menu-mode analysis — sections containing dishes."""
    analysis_type: str = Field(default="menu", description="Always 'menu'.")
    sections: List[MenuSectionSchema] = Field(..., description="All sections of the menu; extract EVERY dish across ALL sections.")


# =============================================================================
# INFLAMMATION ANALYSIS SCHEMAS
# =============================================================================

class IngredientCategoryEnum(str, Enum):
    """Category of an individual ingredient."""
    HIGHLY_INFLAMMATORY = "highly_inflammatory"
    INFLAMMATORY = "inflammatory"
    NEUTRAL = "neutral"
    ANTI_INFLAMMATORY = "anti_inflammatory"
    HIGHLY_ANTI_INFLAMMATORY = "highly_anti_inflammatory"
    ADDITIVE = "additive"
    UNKNOWN = "unknown"


class IngredientAnalysisSchema(BaseModel):
    """Schema for a single ingredient analysis."""
    name: str = Field(..., description="Ingredient name")
    category: str = Field(..., description="Inflammation category")
    score: int = Field(..., ge=1, le=10, description="1=inflammatory, 10=anti-inflammatory")
    reason: str = Field(..., description="Explanation for classification")
    is_inflammatory: bool = Field(..., description="True if score <= 4")
    is_additive: bool = Field(default=False, description="True if additive/preservative")
    scientific_notes: Optional[str] = Field(default=None, description="Scientific context")


class InflammationAnalysisGeminiResponse(BaseModel):
    """Schema for Gemini inflammation analysis output."""
    overall_score: int = Field(..., ge=1, le=10, description="1=highly inflammatory, 10=anti-inflammatory")
    overall_category: str = Field(..., description="Overall category")
    summary: str = Field(..., description="Plain-language summary")
    recommendation: Optional[str] = Field(default=None, description="Actionable recommendation")
    ingredient_analyses: List[IngredientAnalysisSchema] = Field(default=[], description="Per-ingredient analysis")
    inflammatory_ingredients: List[str] = Field(default=[], description="Inflammatory ingredient names")
    anti_inflammatory_ingredients: List[str] = Field(default=[], description="Anti-inflammatory names")
    additives_found: List[str] = Field(default=[], description="Additive names")


# =============================================================================
# WARMUP/STRETCH SCHEMAS
# =============================================================================

class WarmupExerciseSchema(BaseModel):
    """Schema for a single warmup exercise."""
    name: str = Field(..., description="Exercise name")
    sets: int = Field(default=1, description="Number of sets")
    reps: int = Field(default=10, description="Reps per set")
    duration_seconds: Optional[int] = Field(default=None, description="Duration in seconds")
    rest_seconds: int = Field(default=15, description="Rest between sets")
    equipment: Optional[str] = Field(default=None, description="Equipment needed")
    muscle_group: Optional[str] = Field(default=None, description="Target muscle group")
    notes: Optional[str] = Field(default=None, description="Instructions/tips")


class WarmupResponse(BaseModel):
    """Schema for warmup routine generation."""
    exercises: List[WarmupExerciseSchema] = Field(..., description="List of warmup exercises")
    duration_minutes: Optional[int] = Field(default=None, description="Total warmup duration")
    notes: Optional[str] = Field(default=None, description="General warmup notes")


class StretchExerciseSchema(BaseModel):
    """Schema for a single stretch exercise."""
    name: str = Field(..., description="Stretch name")
    sets: int = Field(default=1, description="Number of sets")
    reps: int = Field(default=1, description="Reps per set")
    duration_seconds: Optional[int] = Field(default=30, description="Hold duration")
    rest_seconds: int = Field(default=10, description="Rest between stretches")
    equipment: Optional[str] = Field(default=None, description="Equipment needed")
    muscle_group: Optional[str] = Field(default=None, description="Target muscle group")
    notes: Optional[str] = Field(default=None, description="Instructions/tips")


class StretchResponse(BaseModel):
    """Schema for stretch routine generation."""
    exercises: List[StretchExerciseSchema] = Field(..., description="List of stretch exercises")
    duration_minutes: Optional[int] = Field(default=None, description="Total stretch duration")
    notes: Optional[str] = Field(default=None, description="General stretch notes")


# =============================================================================
# CALIBRATION WORKOUT SCHEMAS
# =============================================================================

class CalibrationExerciseSchema(BaseModel):
    """Schema for a calibration exercise."""
    name: str = Field(..., description="Exercise name")
    target_reps: int = Field(..., description="Target reps to attempt")
    target_sets: int = Field(default=1, description="Target sets")
    weight_kg: Optional[float] = Field(default=None, description="Suggested weight")
    rest_seconds: int = Field(default=60, description="Rest time")
    notes: Optional[str] = Field(default=None, description="Form notes")


class CalibrationWorkoutResponse(BaseModel):
    """Schema for calibration workout generation."""
    difficulty_assessment: str = Field(..., description="Initial assessment")
    suggested_level: str = Field(..., description="Suggested fitness level")
    exercises: List[CalibrationExerciseSchema] = Field(..., description="Calibration exercises")
    notes: Optional[str] = Field(default=None, description="General notes")


class PerformanceAnalysisResponse(BaseModel):
    """Schema for performance analysis after calibration."""
    performance_score: int = Field(..., ge=1, le=10, description="Overall score 1-10")
    recommendations: List[str] = Field(default=[], description="Improvement recommendations")
    next_difficulty_level: str = Field(..., description="Recommended next level")
    strengths: Optional[List[str]] = Field(default=None, description="User strengths identified")
    areas_to_improve: Optional[List[str]] = Field(default=None, description="Areas needing work")


# =============================================================================
# CUSTOM GOAL SCHEMAS
# =============================================================================

class CustomGoalItem(BaseModel):
    """Schema for a custom goal suggestion."""
    title: str = Field(..., description="Goal title")
    description: str = Field(..., description="Goal description")
    target_value: Optional[float] = Field(default=None, description="Target value")
    target_unit: Optional[str] = Field(default=None, description="Unit of measurement")
    timeframe_days: Optional[int] = Field(default=None, description="Timeframe in days")


class CustomGoalsResponse(BaseModel):
    """Schema for custom goal suggestions."""
    goals: List[CustomGoalItem] = Field(..., description="Suggested goals")
    reasoning: str = Field(..., description="Why these goals were suggested")
    implementation_steps: List[str] = Field(default=[], description="Steps to achieve goals")


# =============================================================================
# FASTING INSIGHT SCHEMAS
# =============================================================================

class FastingImpactResponse(BaseModel):
    """Schema for fasting impact analysis."""
    impact_score: int = Field(..., ge=1, le=10, description="Impact on workout 1-10")
    recommendations: List[str] = Field(default=[], description="Recommendations")
    energy_impact: str = Field(..., description="Expected energy impact")
    muscle_impact: str = Field(..., description="Expected muscle impact")
    optimal_workout_timing: Optional[str] = Field(default=None, description="Best time to workout")
    nutrition_tips: Optional[List[str]] = Field(default=None, description="Nutrition recommendations")


# =============================================================================
# MEAL PLANNING SCHEMAS
# =============================================================================

class MealItemSchema(BaseModel):
    """Schema for a single meal in a meal plan."""
    meal_type: str = Field(..., description="breakfast/lunch/dinner/snack")
    name: str = Field(..., description="Meal name")
    description: str = Field(..., description="Meal description")
    calories: int = Field(..., description="Calories")
    protein_g: float = Field(..., description="Protein in grams")
    carbs_g: float = Field(..., description="Carbs in grams")
    fat_g: float = Field(..., description="Fat in grams")
    ingredients: Optional[List[str]] = Field(default=None, description="Ingredient list")
    prep_time_minutes: Optional[int] = Field(default=None, description="Prep time")


class DailyMealPlanResponse(BaseModel):
    """Schema for daily meal plan generation."""
    daily_meals: List[MealItemSchema] = Field(..., description="Meals for the day")
    total_calories: int = Field(..., description="Total daily calories")
    total_protein_g: float = Field(..., description="Total protein")
    total_carbs_g: float = Field(..., description="Total carbs")
    total_fat_g: float = Field(..., description="Total fat")
    notes: Optional[str] = Field(default=None, description="Meal plan notes")


class MealSuggestionItem(BaseModel):
    """Schema for a meal suggestion."""
    name: str = Field(..., description="Meal name")
    description: str = Field(..., description="Description")
    calories: int = Field(..., description="Calories")
    protein_g: float = Field(..., description="Protein")
    carbs_g: float = Field(..., description="Carbs")
    fat_g: float = Field(..., description="Fat")
    meal_type: str = Field(..., description="Suggested meal type")


class MealSuggestionsResponse(BaseModel):
    """Schema for personalized meal suggestions."""
    meal_suggestions: List[MealSuggestionItem] = Field(..., description="Suggested meals")
    daily_nutrition: Optional[dict] = Field(default=None, description="Daily nutrition summary")


class SnackItemSchema(BaseModel):
    """Schema for a snack suggestion."""
    name: str = Field(..., description="Snack name")
    calories: int = Field(..., description="Calories")
    protein_g: float = Field(..., description="Protein")
    carbs_g: float = Field(..., description="Carbs")
    fat_g: float = Field(..., description="Fat")
    description: Optional[str] = Field(default=None, description="Description")


class SnackSuggestionsResponse(BaseModel):
    """Schema for snack suggestions."""
    snacks: List[SnackItemSchema] = Field(..., description="Suggested snacks")


# =============================================================================
# QUICK MEAL SUGGESTION (home-screen widget / Siri / Action Button)
# =============================================================================

class QuickSuggestionFoodItem(BaseModel):
    """Single food component inside a quick meal suggestion."""
    name: str = Field(..., description="Food item name, e.g. '3-egg scramble'")
    grams: Optional[int] = Field(default=None, description="Portion in grams")
    calories: int = Field(..., description="Calories for this component")
    protein_g: float = Field(..., description="Protein in grams")
    carbs_g: float = Field(..., description="Carbs in grams")
    fat_g: float = Field(..., description="Fat in grams")


class QuickSuggestionGeminiResponse(BaseModel):
    """Gemini structured output for the widget's single-meal suggestion.

    Kept deliberately tight: the widget can only render ~2 lines of text + a
    macros row, so the LLM should return exactly one meal, not a list.
    """
    emoji: str = Field(..., description="One emoji summarising the meal, e.g. 🍳")
    title: str = Field(..., description="Short meal title, max ~40 chars")
    subtitle: str = Field(..., description="One-line why-this-fits reasoning, max ~80 chars")
    calories: int = Field(..., description="Total calories for the meal")
    protein_g: float = Field(..., description="Total protein")
    carbs_g: float = Field(..., description="Total carbs")
    fat_g: float = Field(..., description="Total fat")
    food_items: List[QuickSuggestionFoodItem] = Field(
        default_factory=list,
        description="Component foods used for auto-logging when user taps 'Log it'",
    )


# =============================================================================
# WORKOUT SUGGESTION SCHEMAS (for API routes)
# =============================================================================

class WorkoutSuggestionSchema(BaseModel):
    """Schema for a workout suggestion."""
    name: str = Field(..., description="Workout name")
    type: str = Field(..., description="Workout type")
    difficulty: str = Field(..., description="Difficulty level")
    duration_minutes: int = Field(..., description="Duration")
    description: str = Field(..., description="Brief description")
    focus_areas: List[str] = Field(default=[], description="Target areas")
    sample_exercises: List[str] = Field(default=[], description="Example exercises")


class WorkoutSuggestionsResponse(BaseModel):
    """Schema for workout suggestions list."""
    suggestions: List[WorkoutSuggestionSchema] = Field(..., description="List of suggestions")


# =============================================================================
# CUSTOM GOAL KEYWORDS SCHEMA
# =============================================================================

class CustomGoalKeywordsResponse(BaseModel):
    """Schema for custom goal keyword generation."""
    keywords: List[str] = Field(..., description="Search keywords for exercise database")
    goal_type: str = Field(..., description="Type of goal (strength, endurance, power, etc.)")
    target_metrics: Optional[dict] = Field(default=None, description="Target metrics and timeline")
    progression_strategy: str = Field(default="linear", description="Progression approach")
    exercise_categories: List[str] = Field(default=[], description="Exercise categories")
    muscle_groups: List[str] = Field(default=[], description="Target muscle groups")
    training_frequency: Optional[str] = Field(default=None, description="Recommended frequency")
    training_notes: Optional[str] = Field(default=None, description="Additional training notes")


# =============================================================================
# FASTING INSIGHT SCHEMA
# =============================================================================

class FastingInsightResponse(BaseModel):
    """Schema for fasting insight generation."""
    insight_type: str = Field(..., description="Type: positive, neutral, negative, needs_more_data")
    title: str = Field(..., description="Short title under 50 characters")
    message: str = Field(..., description="Detailed insight message")
    recommendation: str = Field(..., description="Actionable recommendation")


# =============================================================================
# WORKOUT INPUT PARSING SCHEMAS (for AI text/image/voice input)
# =============================================================================

class ParsedExerciseItem(BaseModel):
    """Schema for a single parsed exercise from natural language input."""
    name: str = Field(..., description="Exercise name (use standard gym names)")
    sets: int = Field(default=3, ge=1, le=20, description="Number of sets")
    reps: int = Field(default=10, ge=1, le=100, description="Reps per set")
    weight_value: Optional[float] = Field(default=None, ge=0, description="Weight value")
    weight_unit: str = Field(default="lbs", description="Weight unit: 'kg' or 'lbs'")
    rest_seconds: int = Field(default=60, ge=0, le=600, description="Rest between sets")
    original_text: str = Field(..., description="Original text segment that was parsed")
    confidence: float = Field(default=1.0, ge=0, le=1, description="Parsing confidence 0-1")
    notes: Optional[str] = Field(default=None, description="Any additional notes from input")


class ParseWorkoutInputResponse(BaseModel):
    """Schema for parsed workout input response (legacy - exercises only)."""
    exercises: List[ParsedExerciseItem] = Field(default=[], description="List of parsed exercises")
    summary: str = Field(..., description="Human-readable summary of what was parsed")
    warnings: List[str] = Field(default=[], description="Any parsing warnings or issues")


# =============================================================================
# DUAL-MODE WORKOUT INPUT PARSING (Sets + Exercises)
# =============================================================================

class SetToLogItem(BaseModel):
    """Schema for a single set to log for the current exercise.

    Used when user types just weight*reps without exercise name.
    These sets apply to the CURRENT exercise being tracked.
    """
    weight: float = Field(..., ge=0, description="Weight value (0 for bodyweight)")
    reps: int = Field(..., ge=0, le=500, description="Number of reps (0 for failed attempt)")
    unit: str = Field(default="lbs", description="Weight unit: 'kg' or 'lbs'")
    is_bodyweight: bool = Field(default=False, description="True if bodyweight exercise (weight=0)")
    is_failure: bool = Field(default=False, description="True if set was to failure/AMRAP")
    is_warmup: bool = Field(default=False, description="True if this is a warmup set")
    original_input: str = Field(default="", description="Original text that produced this set")
    notes: Optional[str] = Field(default=None, description="Any notes for this set")


class ExerciseToAddItem(BaseModel):
    """Schema for a new exercise to add to the workout.

    Used when user input contains an exercise NAME.
    """
    name: str = Field(..., description="Exercise name (use standard gym names, expand abbreviations)")
    sets: int = Field(default=3, ge=1, le=20, description="Number of sets")
    reps: int = Field(default=10, ge=1, le=100, description="Reps per set")
    weight_kg: Optional[float] = Field(default=None, ge=0, description="Weight in kg")
    weight_lbs: Optional[float] = Field(default=None, ge=0, description="Weight in lbs")
    rest_seconds: int = Field(default=60, ge=0, le=600, description="Rest between sets in seconds")
    is_bodyweight: bool = Field(default=False, description="True for bodyweight exercises")
    original_text: str = Field(default="", description="Original text segment that was parsed")
    confidence: float = Field(default=1.0, ge=0, le=1, description="Parsing confidence 0-1")
    notes: Optional[str] = Field(default=None, description="Any additional notes")


class ParseWorkoutInputV2Response(BaseModel):
    """Schema for dual-mode workout input parsing.

    Supports TWO use cases:
    1. Set logging: User types "135*8, 145*6" -> logs sets for CURRENT exercise
    2. Add exercise: User types "3x10 deadlift at 135" -> adds NEW exercise

    Both can happen in the same input!
    """
    sets_to_log: List[SetToLogItem] = Field(
        default=[],
        description="Sets to log for the CURRENT exercise (just weight*reps, no exercise name)"
    )
    exercises_to_add: List[ExerciseToAddItem] = Field(
        default=[],
        description="New exercises to add to the workout (contains exercise names)"
    )
    summary: str = Field(
        ...,
        description="Human-readable summary, e.g., 'Log 3 sets for Bench Press, Add Deadlift'"
    )
    warnings: List[str] = Field(
        default=[],
        description="Any parsing warnings or issues"
    )


# =============================================================================
# WORKOUT INSIGHTS SCHEMAS
# =============================================================================

class WorkoutInsightSection(BaseModel):
    """Schema for a single insight section in workout insights."""
    icon: str = Field(..., description="Emoji icon for the section (e.g., '💪', '🎯', '🔥', '⚡')")
    title: str = Field(..., description="Short title (2-3 words max)")
    content: str = Field(..., description="Brief content (6-10 words max)")
    color: str = Field(..., description="Color hint: 'cyan', 'purple', 'orange', or 'green'")


class WorkoutInsightsResponse(BaseModel):
    """Schema for structured workout insights with headline and sections.

    Used by the workout insights LangGraph agent to generate motivational
    and informative summaries for workout cards.

    Example response:
    {
        "headline": "Crush Your Goals!",
        "sections": [
            {"icon": "💪", "title": "Focus", "content": "Target chest and triceps today", "color": "cyan"},
            {"icon": "🎯", "title": "Intensity", "content": "Progressive overload for strength", "color": "purple"}
        ]
    }
    """
    headline: str = Field(..., description="Motivational headline (3-5 words max)")
    sections: List[WorkoutInsightSection] = Field(..., description="Exactly 2 insight sections")


# =============================================================================
# BODY ANALYZER SCHEMAS
# =============================================================================

class PostureFindingSchema(BaseModel):
    """One observed postural issue. Severity drives which correctives we inject.

    `corrective_exercise_tag` MUST match one of the six values accepted by
    the exercise_library.corrective_for[] column — otherwise the
    `apply-posture-correctives` endpoint can't resolve exercises.
    """
    issue: str = Field(
        ...,
        description=(
            "Posture issue code. One of: forward_head_posture, rounded_shoulders, "
            "anterior_pelvic_tilt, uneven_shoulders, knee_valgus, scapular_winging."
        ),
    )
    severity: int = Field(..., ge=1, le=3, description="1=mild, 2=moderate, 3=severe")
    description: str = Field(..., description="Short human-readable description, ≤20 words")
    corrective_exercise_tag: str = Field(
        ...,
        description="Must equal one of the `corrective_for` array values on exercise_library.",
    )


class BodyAnalyzerGeminiResponse(BaseModel):
    """Structured output for the Body Analyzer screen.

    Gemini fills these from progress photos + stored body measurements.
    Downstream code persists this to `body_analyzer_snapshots` and may
    seed users.muscle_focus_points on first run.
    """
    overall_rating: int = Field(..., ge=0, le=100, description="Composite fitness score 0–100")
    body_type: str = Field(
        ...,
        description="One of: ectomorph, mesomorph, endomorph, balanced",
    )
    body_fat_pct: float = Field(..., ge=3, le=60, description="Estimated body-fat %")
    muscle_mass_pct: float = Field(..., ge=10, le=70, description="Estimated skeletal-muscle %")
    symmetry_score: int = Field(..., ge=0, le=100, description="Left-right symmetry")
    feedback_paragraph: str = Field(
        ...,
        description=(
            "Concise 3–5 sentence narrative: what's strong, what lags, and the "
            "user's physique archetype. No hype; describe observations."
        ),
    )
    improvement_tips: List[str] = Field(
        default_factory=list,
        description="3–5 actionable, specific tips (e.g. 'Add 4 sets/wk of rear-delt work').",
    )
    posture_findings: List[PostureFindingSchema] = Field(
        default_factory=list,
        description="Posture issues visible in the photos.",
    )
    priority_muscles: List[str] = Field(
        default_factory=list,
        description=(
            "Muscle groups that most need emphasis, subset of: chest, back, "
            "shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core."
        ),
    )


class PhotoMeasurementEstimate(BaseModel):
    """One photo-derived body measurement."""
    metric: str = Field(
        ...,
        description="One of: waist_cm, chest_cm, hip_cm, neck_cm, shoulder_cm, thigh_left_cm, thigh_right_cm, bicep_left_cm, bicep_right_cm",
    )
    value_cm: float = Field(..., gt=0, le=250, description="Estimated value in centimetres")
    confidence: float = Field(..., ge=0, le=1, description="Confidence 0–1")
    method: str = Field(
        default="photo_ratio",
        description="How the estimate was derived: photo_ratio | photo_scale_reference | photo_height_anchor",
    )


class PhotoMeasurementExtractionResponse(BaseModel):
    """Batch of photo-derived measurements returned by Gemini Vision."""
    estimates: List[PhotoMeasurementEstimate] = Field(default_factory=list)
    scale_reference_detected: bool = Field(
        default=False,
        description="True if Gemini located a hand/credit-card/doorframe to calibrate with.",
    )
    overall_confidence: float = Field(..., ge=0, le=1)


# =============================================================================
# PROGRESS PHOTO COMPARISON (before/after narrative) SCHEMA
# =============================================================================

class ProgressPhotoComparisonResponse(BaseModel):
    """Structured narrative comparing two progress photos.

    `summary_text` is the public-facing sentence; the region-specific fields
    let the UI later surface region chips (midsection / upper / lower) without
    a second Gemini call.
    """
    summary_text: str = Field(
        ...,
        description="1–3 sentence narrative describing visible change. Honest, encouraging, specific.",
    )
    midsection_change: str = Field(default="", description="Observation about midsection.")
    upper_body_change: str = Field(default="", description="Observation about upper body.")
    lower_body_change: str = Field(default="", description="Observation about lower body.")
    overall_verdict: str = Field(
        default="",
        description="One-word verdict: improved | maintained | regressed | inconclusive",
    )


# =============================================================================
# PROGRAM RETUNE PROPOSAL SCHEMA
# =============================================================================

class ProgramRetuneProposalResponse(BaseModel):
    """Concrete deltas Gemini proposes after a Body Analyzer run.

    These fields are applied directly to `public.users` columns so the next
    AI-generated workout / meal plan reflects the user's physique — no
    separate program-mutation table or code path.

    Bounds are enforced at schema level so the model can never propose an
    unsafe adjustment (e.g. +1000 kcal/day or −20% intensity in one step).
    """
    muscle_focus_points_proposed: Dict[str, int] = Field(
        default_factory=dict,
        description=(
            "New muscle_focus_points allocation. Values 0–5, total ≤5 across all keys. "
            "Keys match users.muscle_focus_points muscle names."
        ),
    )
    training_intensity_percent_delta: int = Field(
        default=0, ge=-15, le=15,
        description="Percent-point shift in users.training_intensity_percent.",
    )
    rest_days_per_week_suggested: int = Field(
        default=2, ge=1, le=4, description="Suggested rest days per week.",
    )
    daily_calorie_target_delta: int = Field(
        default=0, ge=-400, le=400, description="Calorie target delta (kcal).",
    )
    daily_protein_target_g_delta: int = Field(
        default=0, ge=-40, le=40, description="Protein target delta (g).",
    )
    daily_carbs_target_g_delta: int = Field(
        default=0, ge=-80, le=80, description="Carbs target delta (g).",
    )
    daily_fat_target_g_delta: int = Field(
        default=0, ge=-30, le=30, description="Fat target delta (g).",
    )
    priority_muscles: List[str] = Field(
        default_factory=list,
        description="Muscle groups to emphasize in the next program (subset of strength_scores muscle enum).",
    )
    posture_corrective_tags: List[str] = Field(
        default_factory=list,
        description=(
            "Subset of: forward_head_posture, rounded_shoulders, anterior_pelvic_tilt, "
            "uneven_shoulders, knee_valgus, scapular_winging."
        ),
    )
    reasoning: str = Field(..., description="Plain-language justification shown to the user.")
    confidence: float = Field(..., ge=0, le=1, description="Model confidence 0–1.")


# =============================================================================
# AUDIO COACH SCHEMA
# =============================================================================

class AudioCoachScriptResponse(BaseModel):
    """Short (≤60 words) personalised script the TTS service will voice.

    Kept tiny on purpose — users should hear 15–20 s, not a monologue.
    """
    script_text: str = Field(
        ...,
        description=(
            "Coach-persona-voiced script ≤60 words. Include the user's first name. "
            "Reference one concrete recent signal (streak day count, PR, weight change, "
            "upcoming workout target). End with a forward-looking sentence."
        ),
    )
    tone: str = Field(
        default="encouraging",
        description="One of: encouraging, celebratory, gentle_nudge, informational",
    )
