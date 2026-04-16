"""Public recipe sharing models — share links + clone."""

from datetime import datetime
from typing import Any, Dict, Optional

from pydantic import BaseModel, Field


class ShareLink(BaseModel):
    recipe_id: str
    slug: str
    url: str                    # full shareable URL constructed by service
    view_count: int = 0
    save_count: int = 0
    created_at: datetime
    is_public: bool = True


class CreateShareLinkResponse(BaseModel):
    link: ShareLink


class PublicRecipeView(BaseModel):
    """Sanitized public payload — no owner PII."""
    slug: str
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    servings: int
    prep_time_minutes: Optional[int] = None
    cook_time_minutes: Optional[int] = None
    instructions: Optional[str] = None
    category: Optional[str] = None
    cuisine: Optional[str] = None
    tags: list = Field(default_factory=list)
    cooking_method: Optional[str] = None
    cooked_yield_grams: Optional[float] = None
    calories_per_serving: Optional[int] = None
    protein_per_serving_g: Optional[float] = None
    carbs_per_serving_g: Optional[float] = None
    fat_per_serving_g: Optional[float] = None
    fiber_per_serving_g: Optional[float] = None
    micronutrients_per_serving: Optional[Dict[str, Any]] = None
    ingredients: list = Field(default_factory=list)
    times_logged: int = 0
    view_count: int = 0
    save_count: int = 0
    author_display_name: Optional[str] = None  # falls back to "Anonymous chef"


class CloneRecipeResponse(BaseModel):
    new_recipe_id: str
    already_saved: bool = False
    message: str
