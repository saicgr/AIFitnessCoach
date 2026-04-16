"""AI nutrition-pro review models for recipes and meal plans."""

from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class CoachReviewSubject(str, Enum):
    RECIPE = "recipe"
    MEAL_PLAN = "meal_plan"


class CoachReviewKind(str, Enum):
    AI_AUTO = "ai_auto"
    AI_REQUESTED = "ai_requested"
    HUMAN_PRO_PENDING = "human_pro_pending"
    HUMAN_PRO_COMPLETE = "human_pro_complete"


class MicronutrientGap(BaseModel):
    nutrient: str
    deficit_pct: int = Field(..., ge=0, le=100)
    suggestion: Optional[str] = None


class SwapSuggestion(BaseModel):
    """Sub-piece of a coach review: one recommended swap."""
    target_label: str           # ingredient or item being swapped
    suggested_label: str
    rationale: str
    deltas: Dict[str, float] = Field(default_factory=dict)  # {protein_g: +18, calories: -120}
    target_item_id: Optional[str] = None
    suggested_recipe_id: Optional[str] = None


class CoachReviewRequest(BaseModel):
    """Trigger an AI review. subject_type/subject_id default from URL path in router."""
    review_kind: CoachReviewKind = CoachReviewKind.AI_REQUESTED
    notes: Optional[str] = Field(default=None, max_length=500)


class CoachReview(BaseModel):
    id: str
    user_id: str
    subject_type: CoachReviewSubject
    subject_id: str
    subject_version: Optional[int] = None
    review_kind: CoachReviewKind
    overall_score: Optional[int] = None
    macro_balance_notes: Optional[str] = None
    micronutrient_gaps: List[MicronutrientGap] = Field(default_factory=list)
    allergen_flags: List[str] = Field(default_factory=list)
    glycemic_load_score: Optional[int] = None
    swap_suggestions: List[SwapSuggestion] = Field(default_factory=list)
    full_feedback: Optional[str] = None
    model_id: Optional[str] = None
    reviewed_at: datetime
    is_stale: bool = False  # set by service when subject_version < current_version
    human_pro_id: Optional[str] = None


class CoachReviewsResponse(BaseModel):
    items: List[CoachReview]
    total_count: int


class HumanProRequestResponse(BaseModel):
    """Stub for the future human-coach feature."""
    queued: bool
    message: str = "We'll notify you when human reviewers launch."
