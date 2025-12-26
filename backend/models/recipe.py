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
    status: str  # 'low', 'optimal', 'high', 'over_ceiling'
    color_hex: Optional[str] = None
    top_contributors: Optional[List[Dict]] = None  # [{food_name, amount, contribution}]


class DailyMicronutrientSummary(BaseModel):
    """Daily summary of all micronutrients."""
    date: str
    user_id: str
    vitamins: List[NutrientProgress]
    minerals: List[NutrientProgress]
    fatty_acids: List[NutrientProgress]
    other: List[NutrientProgress]
    # Pinned nutrients (user's favorites)
    pinned: List[NutrientProgress]


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


class Recipe(RecipeBase):
    """Recipe response with calculated nutrition."""
    id: str
    user_id: str

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


class RecipesResponse(BaseModel):
    """List of recipes response."""
    items: List[RecipeSummary]
    total_count: int


class LogRecipeRequest(BaseModel):
    """Request to log a recipe as a meal."""
    meal_type: str  # breakfast, lunch, dinner, snack
    servings: float = Field(default=1.0, gt=0, le=20)


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
