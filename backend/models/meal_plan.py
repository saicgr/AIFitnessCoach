"""Meal plan models — daily planning + simulation + apply-to-today."""

from datetime import date, datetime
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field, model_validator


class MealType(str, Enum):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACK = "snack"


class MealPlanItemCreate(BaseModel):
    """Either a recipe reference OR an ad-hoc food_items array."""
    meal_type: MealType
    slot_order: int = 0
    recipe_id: Optional[str] = None
    food_items: Optional[List[Dict[str, Any]]] = None
    servings: float = Field(default=1.0, gt=0, le=20)

    @model_validator(mode="after")
    def _xor(self):
        if (self.recipe_id is None) == (self.food_items is None):
            raise ValueError("item must reference either recipe_id OR food_items, not both/neither")
        return self


class MealPlanItem(MealPlanItemCreate):
    id: str
    plan_id: str
    created_at: datetime


class MealPlanCreate(BaseModel):
    name: Optional[str] = Field(default=None, max_length=120)
    plan_date: Optional[date] = None
    is_template: bool = False
    notes: Optional[str] = Field(default=None, max_length=2000)
    items: List[MealPlanItemCreate] = Field(default_factory=list)
    # target_snapshot is captured server-side from user prefs; clients don't pass it


class MealPlanUpdate(BaseModel):
    name: Optional[str] = None
    plan_date: Optional[date] = None
    notes: Optional[str] = None


class MealPlan(BaseModel):
    id: str
    user_id: str
    name: Optional[str] = None
    plan_date: Optional[date] = None
    is_template: bool = False
    target_snapshot: Optional[Dict[str, Any]] = None
    notes: Optional[str] = None
    items: List[MealPlanItem] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime


class MealPlansResponse(BaseModel):
    items: List[MealPlan]
    total_count: int


# ============================================================
# SIMULATE — what-if without writing
# ============================================================


class MacroTotals(BaseModel):
    calories: float = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0
    fiber_g: float = 0
    sugar_g: float = 0
    sodium_mg: float = 0


class MacroRemainder(BaseModel):
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float


class AiSwapSuggestion(BaseModel):
    """Coach-suggested replacement to better hit goals."""
    item_id: Optional[str] = None  # plan item to replace; None = additional suggestion
    from_label: str
    to_label: str
    rationale: str
    deltas: Dict[str, float] = Field(default_factory=dict)
    new_recipe_id: Optional[str] = None
    new_food_items: Optional[List[Dict[str, Any]]] = None
    new_servings: Optional[float] = None


class SimulateResponse(BaseModel):
    plan_id: str
    totals: MacroTotals
    target_snapshot: Dict[str, Any]
    remainder: MacroRemainder
    over_budget: bool
    adherence_pct: Dict[str, float]  # per-macro adherence %
    swap_suggestions: List[AiSwapSuggestion] = Field(default_factory=list)
    coach_summary: Optional[str] = None


class ApplyResponse(BaseModel):
    plan_id: str
    target_date: date
    food_log_ids: List[str]
    duplicates_skipped: int = 0
    duplicates_warning: Optional[str] = None
