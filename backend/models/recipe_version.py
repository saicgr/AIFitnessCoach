"""Recipe version history + diff models."""

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class RecipeVersionSummary(BaseModel):
    """Lightweight row for the history timeline."""
    id: str
    recipe_id: str
    version_number: int
    change_summary: Optional[str] = None
    edited_by: Optional[str] = None
    edited_at: datetime


class RecipeVersion(BaseModel):
    id: str
    recipe_id: str
    version_number: int
    recipe_snapshot: Dict[str, Any]   # whole recipe + ingredients
    change_summary: Optional[str] = None
    edited_by: Optional[str] = None
    edited_at: datetime


class RecipeVersionsResponse(BaseModel):
    items: List[RecipeVersionSummary]
    total_count: int
    current_version: int


class FieldDiff(BaseModel):
    field: str
    before: Any = None
    after: Any = None


class IngredientDiff(BaseModel):
    change: str   # 'added' | 'removed' | 'modified'
    food_name: str
    before: Optional[Dict[str, Any]] = None
    after: Optional[Dict[str, Any]] = None


class RecipeDiff(BaseModel):
    from_version: int
    to_version: int
    field_diffs: List[FieldDiff] = Field(default_factory=list)
    ingredient_diffs: List[IngredientDiff] = Field(default_factory=list)


class RecipeRevertRequest(BaseModel):
    target_version: int


class RecipeRevertResponse(BaseModel):
    success: bool
    new_current_version: int
    message: str
    schedules_using_recipe_count: int = 0
