"""Grocery list models — derived from a meal plan or single recipe."""

from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class Aisle(str, Enum):
    PRODUCE = "produce"
    DAIRY = "dairy"
    MEAT_SEAFOOD = "meat_seafood"
    PANTRY = "pantry"
    FROZEN = "frozen"
    BAKERY = "bakery"
    BEVERAGES = "beverages"
    CONDIMENTS = "condiments"
    SPICES = "spices"
    SNACKS = "snacks"
    HOUSEHOLD = "household"
    OTHER = "other"


class GroceryListItemBase(BaseModel):
    ingredient_name: str = Field(..., max_length=255)
    quantity: Optional[float] = Field(default=None, ge=0)
    unit: Optional[str] = Field(default=None, max_length=30)
    aisle: Optional[Aisle] = None
    is_checked: bool = False
    is_staple_suppressed: bool = False
    source_recipe_ids: List[str] = Field(default_factory=list)
    notes: Optional[str] = Field(default=None, max_length=500)


class GroceryListItemCreate(GroceryListItemBase):
    pass


class GroceryListItemUpdate(BaseModel):
    quantity: Optional[float] = None
    unit: Optional[str] = None
    aisle: Optional[Aisle] = None
    is_checked: Optional[bool] = None
    notes: Optional[str] = None


class GroceryListItem(GroceryListItemBase):
    id: str
    list_id: str
    created_at: datetime
    updated_at: datetime


class GroceryListCreate(BaseModel):
    """Either a meal_plan_id OR source_recipe_id source — service builds items automatically."""
    meal_plan_id: Optional[str] = None
    source_recipe_id: Optional[str] = None
    name: Optional[str] = None
    notes: Optional[str] = None
    suppress_staples: bool = True


class GroceryList(BaseModel):
    id: str
    user_id: str
    meal_plan_id: Optional[str] = None
    source_recipe_id: Optional[str] = None
    name: Optional[str] = None
    notes: Optional[str] = None
    items: List[GroceryListItem] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime


class GroceryListSummary(BaseModel):
    """Lightweight row for the lists-index screen."""
    id: str
    name: Optional[str] = None
    item_count: int
    checked_count: int
    meal_plan_id: Optional[str] = None
    source_recipe_id: Optional[str] = None
    created_at: datetime


class GroceryListsResponse(BaseModel):
    items: List[GroceryListSummary]
    total_count: int


class GroceryStaple(BaseModel):
    ingredient_name: str = Field(..., max_length=255)


class GroceryStaplesResponse(BaseModel):
    items: List[GroceryStaple]
