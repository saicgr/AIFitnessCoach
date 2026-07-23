"""
Pydantic models for saved foods (favorite recipes).

Features:
- Save meals as favorite recipes
- Quick re-logging of saved meals
- Semantic search via ChromaDB
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


# ============================================================
# ENUMS
# ============================================================

class FoodSourceType(str, Enum):
    """Source type for saved foods."""
    TEXT = "text"
    BARCODE = "barcode"
    IMAGE = "image"


# ============================================================
# FOOD ITEM WITH RANKING
# ============================================================

class USDANutrientData(BaseModel):
    """USDA per-100g nutrient data for accurate portion scaling."""
    fdc_id: Optional[int] = None
    calories_per_100g: float = 0.0
    protein_per_100g: float = 0.0
    carbs_per_100g: float = 0.0
    fat_per_100g: float = 0.0
    fiber_per_100g: float = 0.0


class AiPerGramData(BaseModel):
    """AI-estimated per-gram nutrition data (fallback when USDA has no match).

    EVERY field is Optional and defaults to None, never 0.0. `services.gemini
    .parsers.build_ai_per_gram` emits a macro key ONLY when the AI actually
    returned that macro, and `flag_unknown_macros` POPS the protein/carbs/fat
    keys off an item whose macros it just nulled — precisely so nothing can
    re-multiply a fabricated factor back into the daily totals.

    With the old `float = 0.0` declaration that protection was undone right
    here at the model boundary: an absent key was rehydrated as a confident
    "0 g per gram", which scales to a confident 0 g at ANY portion size. None
    means "no per-gram factor for this macro" — a consumer must skip the
    macro (leaving it unknown), not scale it to zero.
    """
    calories: Optional[float] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None
    fiber: Optional[float] = None


class SavedFoodItem(BaseModel):
    """Individual food item in a saved meal."""
    name: str = Field(..., max_length=200)
    amount: Optional[str] = Field(default=None, max_length=50)  # e.g., "150g", "1 cup"
    calories: Optional[int] = Field(default=None, ge=0, le=10000)
    protein_g: Optional[float] = Field(default=None, ge=0, le=1000)
    carbs_g: Optional[float] = Field(default=None, ge=0, le=1000)
    fat_g: Optional[float] = Field(default=None, ge=0, le=1000)
    fiber_g: Optional[float] = Field(default=None, ge=0, le=1000)
    # Goal-based scoring (cached from when saved)
    goal_score: Optional[int] = Field(default=None, ge=1, le=10)
    goal_alignment: Optional[str] = Field(default=None, max_length=20)  # excellent, good, neutral, poor
    # Portion scaling fields (for weight adjustment when re-logging)
    weight_g: Optional[float] = Field(default=None, ge=0, le=10000)
    usda_data: Optional[USDANutrientData] = None
    ai_per_gram: Optional[AiPerGramData] = None
    # Count-based scaling fields (for countable items like tater tots, cookies)
    count: Optional[int] = Field(default=None, ge=0, le=1000)
    weight_per_unit_g: Optional[float] = Field(default=None, ge=0, le=1000)
    # A4 custom-food fields — stored in the food_items JSON so no schema
    # migration is needed. `brand` is captured only when known (never invented);
    # `emoji` is the chosen display icon.
    brand: Optional[str] = Field(default=None, max_length=120)
    emoji: Optional[str] = Field(default=None, max_length=16)


# ============================================================
# SAVED FOODS
# ============================================================

class SavedFoodBase(BaseModel):
    """Base model for saved foods."""
    name: str = Field(..., max_length=255)
    description: Optional[str] = Field(default=None, max_length=2000)
    source_type: FoodSourceType = FoodSourceType.TEXT
    barcode: Optional[str] = Field(default=None, max_length=50)
    image_url: Optional[str] = Field(default=None, max_length=500)

    # Nutrition totals
    total_calories: Optional[int] = Field(default=None, ge=0, le=20000)
    total_protein_g: Optional[float] = Field(default=None, ge=0, le=2000)
    total_carbs_g: Optional[float] = Field(default=None, ge=0, le=2000)
    total_fat_g: Optional[float] = Field(default=None, ge=0, le=2000)
    total_fiber_g: Optional[float] = Field(default=None, ge=0, le=500)

    # Food items
    food_items: List[SavedFoodItem] = Field(default_factory=list, max_length=50)

    # Goal scoring
    overall_meal_score: Optional[int] = Field(default=None, ge=1, le=10)
    goal_alignment_percentage: Optional[int] = Field(default=None, ge=0, le=100)

    # Organization
    tags: List[str] = Field(default_factory=list, max_length=20)
    notes: Optional[str] = Field(default=None, max_length=2000)


class SavedFoodCreate(SavedFoodBase):
    """Create a saved food."""
    pass


class SavedFood(SavedFoodBase):
    """Saved food from database."""
    id: str
    user_id: str
    times_logged: int = 0
    last_logged_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    deleted_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class SavedFoodUpdate(BaseModel):
    """Update a saved food."""
    name: Optional[str] = Field(default=None, max_length=255)
    description: Optional[str] = Field(default=None, max_length=2000)
    tags: Optional[List[str]] = Field(default=None, max_length=20)
    notes: Optional[str] = Field(default=None, max_length=2000)


class SavedFoodsResponse(BaseModel):
    """Paginated response for saved foods."""
    items: List[SavedFood]
    total_count: int


# ============================================================
# ACTIONS
# ============================================================

class SaveFoodFromLogRequest(BaseModel):
    """Request to save a food from log preview."""
    name: str = Field(..., max_length=255)
    description: Optional[str] = Field(default=None, max_length=2000)
    source_type: FoodSourceType = FoodSourceType.TEXT
    barcode: Optional[str] = Field(default=None, max_length=50)
    image_url: Optional[str] = Field(default=None, max_length=500)

    # Nutrition totals
    total_calories: Optional[int] = Field(default=None, ge=0, le=20000)
    total_protein_g: Optional[float] = Field(default=None, ge=0, le=2000)
    total_carbs_g: Optional[float] = Field(default=None, ge=0, le=2000)
    total_fat_g: Optional[float] = Field(default=None, ge=0, le=2000)
    total_fiber_g: Optional[float] = Field(default=None, ge=0, le=500)

    # Food items
    food_items: List[SavedFoodItem] = Field(default_factory=list, max_length=50)

    # Goal scoring (cached)
    overall_meal_score: Optional[int] = Field(default=None, ge=1, le=10)
    goal_alignment_percentage: Optional[int] = Field(default=None, ge=0, le=100)

    # Tags
    tags: Optional[List[str]] = Field(default=None, max_length=20)


class RelogSavedFoodRequest(BaseModel):
    """Request to re-log a saved food."""
    meal_type: str = Field(..., max_length=50)  # breakfast, lunch, dinner, snack


class SavedFoodSummary(BaseModel):
    """Simplified saved food for list view."""
    id: str
    name: str
    total_calories: Optional[int] = None
    total_protein_g: Optional[float] = None
    source_type: FoodSourceType
    times_logged: int = 0
    last_logged_at: Optional[datetime] = None
    created_at: datetime
    tags: List[str] = Field(default_factory=list)


# ============================================================
# SEARCH
# ============================================================

class SearchSavedFoodsRequest(BaseModel):
    """Request to search saved foods."""
    query: Optional[str] = Field(default=None, max_length=200)
    tags: Optional[List[str]] = Field(default=None, max_length=20)
    source_type: Optional[FoodSourceType] = None
    min_calories: Optional[int] = Field(default=None, ge=0)
    max_calories: Optional[int] = Field(default=None, le=20000)
    min_protein_g: Optional[float] = Field(default=None, ge=0)
    limit: int = Field(default=20, ge=1, le=100)
    offset: int = Field(default=0, ge=0)


class SimilarFoodsResponse(BaseModel):
    """Response for similar foods search via ChromaDB."""
    similar_foods: List[SavedFoodSummary]
    query: str


# ============================================================
# A4 — AI-ASSISTED CUSTOM FOOD CREATION
# ============================================================

class AiSuggestFoodRequest(BaseModel):
    """
    Request to AI-suggest fields for a new custom food.

    Provide EITHER `name` (text path → text food analysis) OR
    `image_base64` (label photo path → reuse nutrition-label OCR).
    """
    name: Optional[str] = Field(default=None, max_length=255,
                                description="Typed food name for text-based suggestion")
    image_base64: Optional[str] = Field(default=None,
                                        description="Base64 nutrition-label photo for OCR-based suggestion")
    mime_type: Optional[str] = Field(default="image/jpeg", max_length=50)


class AiSuggestedDuplicate(BaseModel):
    """An existing custom food that closely matches the suggestion."""
    id: str
    name: str
    total_calories: Optional[int] = None
    total_protein_g: Optional[float] = None
    source_type: FoodSourceType = FoodSourceType.TEXT


class AiSuggestFoodResponse(BaseModel):
    """
    AI suggestions for a custom food. EVERY field is advisory — the client
    renders all of these into editable inputs (C5: all editable before save).
    """
    # Suggested display name + branding
    name: Optional[str] = None
    brand: Optional[str] = None          # captured only if the AI actually read a brand — never invented
    emoji: Optional[str] = None          # deterministic keyword→emoji; null if no confident match

    # Suggested macros (per the amount/serving below). Any field may be null
    # when the AI could not determine it — the client leaves it blank/flagged,
    # it is NEVER silently guessed.
    amount: Optional[str] = None         # e.g. "1 serving", "100g"
    calories: Optional[int] = None
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None
    fiber_g: Optional[float] = None

    # Trust signals (C5: AI can't determine confidently → flag, don't guess)
    source: str = "text"                 # "text" | "nutrition_label"
    low_confidence: bool = False         # true → client shows a "double-check" hint
    missing_fields: List[str] = Field(default_factory=list)  # macro fields the AI could not read
    note: Optional[str] = None           # human-readable explanation of any caveat

    # Duplicate detection (C5)
    duplicate: Optional[AiSuggestedDuplicate] = None
