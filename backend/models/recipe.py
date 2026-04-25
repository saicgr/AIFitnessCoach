"""Recipe and micronutrient Pydantic models."""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime
from enum import Enum


class RecipeCategory(str, Enum):
    """Recipe category options."""
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACK = "snack"
    DESSERT = "dessert"
    DRINK = "drink"
    OTHER = "other"


class RecipeSourceType(str, Enum):
    """How the recipe was created."""
    MANUAL = "manual"
    IMPORTED = "imported"
    AI_GENERATED = "ai_generated"
    IMPORTED_TEXT = "imported_text"
    IMPORTED_URL = "imported_url"
    IMPORTED_HANDWRITTEN = "imported_handwritten"
    PANTRY_SUGGESTED = "pantry_suggested"
    CLONED_FROM_SHARE = "cloned_from_share"
    IMPROVIZED = "improvized"  # Forked from a curated / public recipe via the Improvize action
    CURATED = "curated"        # Editorially-seeded Discover recipes (is_curated=TRUE)


class CookingMethod(str, Enum):
    """How a recipe or ingredient is cooked. Affects macro estimation."""
    RAW = "raw"
    BAKED = "baked"
    GRILLED = "grilled"
    FRIED = "fried"
    BOILED = "boiled"
    STEAMED = "steamed"
    ROASTED = "roasted"
    SAUTEED = "sauteed"
    SLOW_COOKED = "slow_cooked"
    PRESSURE_COOKED = "pressure_cooked"
    AIR_FRIED = "air_fried"
    SMOKED = "smoked"
    OTHER = "other"


class NutritionSource(str, Enum):
    """Where ingredient nutrition data came from."""
    BRANDED = "branded"     # exact match from a barcode/saved-food
    USDA = "usda"           # match in USDA / open food facts
    AI_ESTIMATE = "ai_estimate"  # Gemini estimate


# ============================================================
# MICRONUTRIENT MODELS
# ============================================================


class MicronutrientData(BaseModel):
    """Comprehensive micronutrient data for a food/meal."""
    # Vitamins
    vitamin_a_ug: Optional[float] = Field(default=None, ge=0)
    vitamin_c_mg: Optional[float] = Field(default=None, ge=0)
    vitamin_d_iu: Optional[float] = Field(default=None, ge=0)
    vitamin_e_mg: Optional[float] = Field(default=None, ge=0)
    vitamin_k_ug: Optional[float] = Field(default=None, ge=0)
    vitamin_b1_mg: Optional[float] = Field(default=None, ge=0)  # Thiamine
    vitamin_b2_mg: Optional[float] = Field(default=None, ge=0)  # Riboflavin
    vitamin_b3_mg: Optional[float] = Field(default=None, ge=0)  # Niacin
    vitamin_b5_mg: Optional[float] = Field(default=None, ge=0)  # Pantothenic Acid
    vitamin_b6_mg: Optional[float] = Field(default=None, ge=0)
    vitamin_b7_ug: Optional[float] = Field(default=None, ge=0)  # Biotin
    vitamin_b9_ug: Optional[float] = Field(default=None, ge=0)  # Folate
    vitamin_b12_ug: Optional[float] = Field(default=None, ge=0)
    choline_mg: Optional[float] = Field(default=None, ge=0)

    # Minerals
    calcium_mg: Optional[float] = Field(default=None, ge=0)
    iron_mg: Optional[float] = Field(default=None, ge=0)
    magnesium_mg: Optional[float] = Field(default=None, ge=0)
    zinc_mg: Optional[float] = Field(default=None, ge=0)
    selenium_ug: Optional[float] = Field(default=None, ge=0)
    potassium_mg: Optional[float] = Field(default=None, ge=0)
    sodium_mg: Optional[float] = Field(default=None, ge=0)
    phosphorus_mg: Optional[float] = Field(default=None, ge=0)
    copper_mg: Optional[float] = Field(default=None, ge=0)
    manganese_mg: Optional[float] = Field(default=None, ge=0)
    iodine_ug: Optional[float] = Field(default=None, ge=0)
    chromium_ug: Optional[float] = Field(default=None, ge=0)
    molybdenum_ug: Optional[float] = Field(default=None, ge=0)

    # Fatty Acids
    omega3_g: Optional[float] = Field(default=None, ge=0)
    omega6_g: Optional[float] = Field(default=None, ge=0)
    saturated_fat_g: Optional[float] = Field(default=None, ge=0)
    trans_fat_g: Optional[float] = Field(default=None, ge=0)
    monounsaturated_fat_g: Optional[float] = Field(default=None, ge=0)
    polyunsaturated_fat_g: Optional[float] = Field(default=None, ge=0)

    # Other
    cholesterol_mg: Optional[float] = Field(default=None, ge=0)
    sugar_g: Optional[float] = Field(default=None, ge=0)
    added_sugar_g: Optional[float] = Field(default=None, ge=0)
    water_ml: Optional[float] = Field(default=None, ge=0)
    caffeine_mg: Optional[float] = Field(default=None, ge=0)
    alcohol_g: Optional[float] = Field(default=None, ge=0)


class NutrientRDA(BaseModel):
    """Reference Daily Allowance for a nutrient."""
    nutrient_name: str
    nutrient_key: str
    unit: str
    category: str  # 'vitamin', 'mineral', 'fatty_acid', 'other'
    rda_floor: Optional[float] = None
    rda_target: Optional[float] = None
    rda_ceiling: Optional[float] = None
    rda_target_male: Optional[float] = None
    rda_target_female: Optional[float] = None
    display_name: str
    display_order: int = 0
    color_hex: Optional[str] = None


class NutrientProgress(BaseModel):
    """Progress towards a nutrient target."""
    nutrient_key: str
    display_name: str
    unit: str
    category: str
    current_value: float
    target_value: float
    floor_value: Optional[float] = None
    ceiling_value: Optional[float] = None
    percentage: float  # current/target * 100
    status: str  # 'low', 'adequate', 'optimal', 'over_ceiling'
    color_hex: Optional[str] = None
    top_contributors: Optional[List[Dict]] = None  # [{food_name, amount, contribution}]
    # Why this nutrient appears in `pinned`. One of:
    #   'static' — user's saved pinned_nutrients list (legacy / opted-out users).
    #   'top_contributor' — dynamic mode picked it for being a high % of RDA today.
    #   'over_ceiling' — penalty nutrient (sodium, saturated fat, added sugar) that
    #                    today's logs pushed past the safe ceiling. Frontend paints
    #                    this orange so users can spot the warning at a glance.
    # Set only on entries inside DailyMicronutrientSummary.pinned; the per-category
    # lists (vitamins/minerals/fatty_acids/other) leave it null.
    pin_reason: Optional[str] = None


class DailyMicronutrientSummary(BaseModel):
    """Daily summary of all micronutrients."""
    date: str
    user_id: str
    vitamins: List[NutrientProgress]
    minerals: List[NutrientProgress]
    fatty_acids: List[NutrientProgress]
    other: List[NutrientProgress]
    # Pinned nutrients shown on the Daily tab. May be a static user-saved list
    # (legacy mode) or a dynamic top-N selection from today's logged foods
    # (new default for new users). Each entry's `pin_reason` records why.
    pinned: List[NutrientProgress]
    # Source of the pinned selection: 'static' (user's saved list) or 'dynamic'
    # (computed from today's logs). Frontend uses this to render a settings
    # toggle without an extra API call.
    pinning_mode: Optional[str] = None


class NutrientContributor(BaseModel):
    """A food that contributed to nutrient intake."""
    food_log_id: str
    food_name: str
    meal_type: str
    amount: float
    unit: str
    logged_at: datetime


class NutrientContributorsResponse(BaseModel):
    """Top contributors to a specific nutrient."""
    nutrient_key: str
    display_name: str
    unit: str
    total_intake: float
    target: float
    contributors: List[NutrientContributor]


# ============================================================
# RECIPE INGREDIENT MODELS
# ============================================================


class RecipeIngredientBase(BaseModel):
    """Base model for recipe ingredient."""
    food_name: str = Field(..., max_length=255)
    brand: Optional[str] = Field(default=None, max_length=100)
    amount: float = Field(..., gt=0)
    unit: str = Field(..., max_length=30)  # 'g', 'ml', 'cup', 'tbsp', etc.
    amount_grams: Optional[float] = Field(default=None, ge=0)
    barcode: Optional[str] = Field(default=None, max_length=50)

    # Nutrition for this ingredient amount
    calories: Optional[float] = Field(default=None, ge=0)
    protein_g: Optional[float] = Field(default=None, ge=0)
    carbs_g: Optional[float] = Field(default=None, ge=0)
    fat_g: Optional[float] = Field(default=None, ge=0)
    fiber_g: Optional[float] = Field(default=None, ge=0)
    sugar_g: Optional[float] = Field(default=None, ge=0)

    # Key micronutrients
    vitamin_d_iu: Optional[float] = Field(default=None, ge=0)
    calcium_mg: Optional[float] = Field(default=None, ge=0)
    iron_mg: Optional[float] = Field(default=None, ge=0)
    sodium_mg: Optional[float] = Field(default=None, ge=0)
    omega3_g: Optional[float] = Field(default=None, ge=0)

    # Full micronutrients (optional)
    micronutrients: Optional[MicronutrientData] = None

    # Notes
    notes: Optional[str] = Field(default=None, max_length=500)
    is_optional: bool = False

    # Cooking + nutrition source tracking (migration 510)
    cooking_method: Optional[CookingMethod] = None
    nutrition_source: Optional[NutritionSource] = None
    nutrition_confidence: Optional[int] = Field(default=None, ge=0, le=100)
    is_negligible: bool = False  # "salt to taste" type rows excluded from totals
    raw_text: Optional[str] = Field(default=None, max_length=500)  # original user input


class RecipeIngredientCreate(RecipeIngredientBase):
    """Create a recipe ingredient."""
    ingredient_order: int = 0


class RecipeIngredient(RecipeIngredientBase):
    """Recipe ingredient response."""
    id: str
    recipe_id: str
    ingredient_order: int
    created_at: datetime
    updated_at: datetime


# ============================================================
# RECIPE MODELS
# ============================================================


class RecipeBase(BaseModel):
    """Base model for recipe."""
    name: str = Field(..., max_length=255)
    description: Optional[str] = Field(default=None, max_length=2000)
    servings: int = Field(default=1, ge=1, le=100)
    prep_time_minutes: Optional[int] = Field(default=None, ge=0, le=1440)
    cook_time_minutes: Optional[int] = Field(default=None, ge=0, le=1440)
    instructions: Optional[str] = Field(default=None, max_length=10000)
    image_url: Optional[str] = Field(default=None, max_length=500)
    category: Optional[RecipeCategory] = None
    cuisine: Optional[str] = Field(default=None, max_length=50)
    tags: Optional[List[str]] = Field(default_factory=list)
    source_url: Optional[str] = Field(default=None, max_length=500)
    source_type: RecipeSourceType = RecipeSourceType.MANUAL
    is_public: bool = False

    # Yield + cooking method (migration 510)
    cooked_yield_grams: Optional[float] = Field(default=None, ge=0)
    cooking_method: Optional[CookingMethod] = None
    auto_snapshot_versions: bool = True


class RecipeCreate(RecipeBase):
    """Create a recipe."""
    ingredients: List[RecipeIngredientCreate] = Field(default_factory=list)


class RecipeUpdate(BaseModel):
    """Update a recipe."""
    name: Optional[str] = Field(default=None, max_length=255)
    description: Optional[str] = Field(default=None, max_length=2000)
    servings: Optional[int] = Field(default=None, ge=1, le=100)
    prep_time_minutes: Optional[int] = Field(default=None, ge=0, le=1440)
    cook_time_minutes: Optional[int] = Field(default=None, ge=0, le=1440)
    instructions: Optional[str] = Field(default=None, max_length=10000)
    image_url: Optional[str] = Field(default=None, max_length=500)
    category: Optional[RecipeCategory] = None
    cuisine: Optional[str] = Field(default=None, max_length=50)
    tags: Optional[List[str]] = None
    is_public: Optional[bool] = None
    cooked_yield_grams: Optional[float] = Field(default=None, ge=0)
    cooking_method: Optional[CookingMethod] = None
    auto_snapshot_versions: Optional[bool] = None


class Recipe(RecipeBase):
    """Recipe response with calculated nutrition."""
    id: str
    # user_id is NULL for curated recipes (is_curated=TRUE) per migration 1925
    user_id: Optional[str] = None

    # Calculated nutrition per serving
    calories_per_serving: Optional[int] = None
    protein_per_serving_g: Optional[float] = None
    carbs_per_serving_g: Optional[float] = None
    fat_per_serving_g: Optional[float] = None
    fiber_per_serving_g: Optional[float] = None
    sugar_per_serving_g: Optional[float] = None

    # Key micronutrients per serving
    vitamin_d_per_serving_iu: Optional[float] = None
    calcium_per_serving_mg: Optional[float] = None
    iron_per_serving_mg: Optional[float] = None
    omega3_per_serving_g: Optional[float] = None
    sodium_per_serving_mg: Optional[float] = None

    # Full micronutrients per serving (optional)
    micronutrients_per_serving: Optional[Dict] = None

    # Usage stats
    times_logged: int = 0
    last_logged_at: Optional[datetime] = None

    # Discover / Favorites / Improvize (migration 1925)
    is_curated: bool = False
    slug: Optional[str] = None
    source_recipe_id: Optional[str] = None
    source_recipe_name: Optional[str] = None  # denormalized — survives source delete
    source_recipe_user_id: Optional[str] = None
    is_favorited: bool = False  # computed per-request for calling user

    # Ingredients
    ingredients: List[RecipeIngredient] = Field(default_factory=list)
    ingredient_count: Optional[int] = None

    # Timestamps
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None


class RecipeSummary(BaseModel):
    """Brief recipe info for lists."""
    id: str
    name: str
    category: Optional[str] = None
    calories_per_serving: Optional[int] = None
    protein_per_serving_g: Optional[float] = None
    servings: int
    ingredient_count: int
    times_logged: int
    image_url: Optional[str] = None
    created_at: datetime

    # Discover / Favorites / Improvize (migration 1925)
    is_curated: bool = False
    slug: Optional[str] = None
    source_recipe_id: Optional[str] = None
    source_recipe_name: Optional[str] = None
    is_favorited: bool = False
    source_type: Optional[str] = None


class RecipesResponse(BaseModel):
    """List of recipes response."""
    items: List[RecipeSummary]
    total_count: int


class LogRecipeRequest(BaseModel):
    """Request to log a recipe as a meal."""
    meal_type: str  # breakfast, lunch, dinner, snack
    servings: float = Field(default=1.0, gt=0, le=20)
    cook_event_id: Optional[str] = None  # leftover-tracking link
    nutrition_confidence: Optional[str] = Field(default=None, pattern="^(high|medium|low)$")


class LogRecipeResponse(BaseModel):
    """Response after logging a recipe."""
    success: bool
    food_log_id: str
    recipe_name: str
    servings: float
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None


# ============================================================
# AI INGREDIENT ANALYZER
# ============================================================


class IngredientAnalyzeRequest(BaseModel):
    """Request to analyze a free-text ingredient row into structured nutrition."""
    text: str = Field(..., min_length=1, max_length=300)
    cooking_method_hint: Optional[CookingMethod] = None
    brand_hint: Optional[str] = Field(default=None, max_length=100)
    user_id: Optional[str] = None  # for branded/saved-food matching


class IngredientAnalyzeResponse(BaseModel):
    """Structured ingredient with macros + source badge."""
    food_name: str
    brand: Optional[str] = None
    amount: float
    unit: str
    amount_grams: Optional[float] = None
    cooking_method: Optional[CookingMethod] = None
    nutrition_source: NutritionSource
    nutrition_confidence: int = Field(..., ge=0, le=100)
    is_negligible: bool = False
    raw_text: str
    # Macros for the parsed amount
    calories: float = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0
    fiber_g: float = 0
    sugar_g: float = 0
    # Key micros
    vitamin_d_iu: Optional[float] = None
    calcium_mg: Optional[float] = None
    iron_mg: Optional[float] = None
    sodium_mg: Optional[float] = None
    omega3_g: Optional[float] = None


class BulkIngredientAnalyzeRequest(BaseModel):
    """Analyze many rows in one round trip (used by recipe builder save)."""
    items: List[IngredientAnalyzeRequest] = Field(..., max_length=50)
    user_id: Optional[str] = None


class BulkIngredientAnalyzeResponse(BaseModel):
    items: List[IngredientAnalyzeResponse]


# ============================================================
# IMPORT RECIPE MODELS
# ============================================================


class ImportRecipeRequest(BaseModel):
    """Request to import a recipe from URL."""
    url: str = Field(..., max_length=500)
    servings_override: Optional[int] = Field(default=None, ge=1, le=100)


class ImportRecipeResponse(BaseModel):
    """Response after importing a recipe."""
    success: bool
    recipe: Optional[Recipe] = None
    error: Optional[str] = None
    ingredients_found: int = 0
    ingredients_with_nutrition: int = 0


class ImportTextRecipeRequest(BaseModel):
    """Paste a full recipe as text; AI extracts title, ingredients, steps."""
    text: str = Field(..., min_length=10, max_length=10000)
    servings_override: Optional[int] = Field(default=None, ge=1, le=100)


class ImportHandwrittenRecipeRequest(BaseModel):
    """Submit an image of a handwritten/printed recipe; Gemini OCR + structures it."""
    image_b64: str = Field(..., max_length=20_000_000)  # ~15 MB base64
    servings_override: Optional[int] = Field(default=None, ge=1, le=100)


class PantryAnalyzeRequest(BaseModel):
    """Request recipes given pantry items (text list and/or image)."""
    items_text: Optional[List[str]] = Field(default=None, max_length=200)
    image_b64: Optional[str] = Field(default=None, max_length=20_000_000)
    meal_type: Optional[str] = None
    count: int = Field(default=3, ge=1, le=8)
    additional_requirements: Optional[str] = None


class PantryDetectedItem(BaseModel):
    name: str
    confidence: int = Field(..., ge=0, le=100)
    source: str  # 'text' | 'image'


class PantrySuggestion(BaseModel):
    name: str
    description: Optional[str] = None
    cuisine: Optional[str] = None
    category: Optional[str] = None
    servings: int = 1
    prep_time_minutes: Optional[int] = None
    cook_time_minutes: Optional[int] = None
    calories_per_serving: Optional[int] = None
    protein_per_serving_g: Optional[float] = None
    carbs_per_serving_g: Optional[float] = None
    fat_per_serving_g: Optional[float] = None
    fiber_per_serving_g: Optional[float] = None
    matched_pantry_items: List[str] = Field(default_factory=list)
    missing_ingredients: List[str] = Field(default_factory=list)
    overall_match_score: int = Field(default=0, ge=0, le=100)
    suggestion_reason: Optional[str] = None
    ingredients: List[RecipeIngredientCreate] = Field(default_factory=list)


class PantryAnalyzeResponse(BaseModel):
    detected_items: List[PantryDetectedItem]
    suggestions: List[PantrySuggestion]


class PantryDetectRequest(BaseModel):
    """Lightweight detect-only request — just run vision on a pantry photo."""
    image_b64: str = Field(..., max_length=20_000_000)


class PantryDetectResponse(BaseModel):
    """Returns just the detected items, no recipe suggestions."""
    items: List[PantryDetectedItem]
