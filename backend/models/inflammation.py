"""
Pydantic models for food inflammation analysis.

Features:
- AI-powered ingredient inflammation classification
- Caching by barcode for efficiency
- Per-user scan history tracking
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


# ============================================================
# ENUMS
# ============================================================

class InflammationCategory(str, Enum):
    """Overall inflammation category for a product."""
    HIGHLY_INFLAMMATORY = "highly_inflammatory"
    MODERATELY_INFLAMMATORY = "moderately_inflammatory"
    NEUTRAL = "neutral"
    ANTI_INFLAMMATORY = "anti_inflammatory"
    HIGHLY_ANTI_INFLAMMATORY = "highly_anti_inflammatory"


class IngredientCategory(str, Enum):
    """Category of an individual ingredient."""
    HIGHLY_INFLAMMATORY = "highly_inflammatory"
    INFLAMMATORY = "inflammatory"
    NEUTRAL = "neutral"
    ANTI_INFLAMMATORY = "anti_inflammatory"
    HIGHLY_ANTI_INFLAMMATORY = "highly_anti_inflammatory"
    ADDITIVE = "additive"  # Preservatives, colorings, etc.
    UNKNOWN = "unknown"


# ============================================================
# INGREDIENT ANALYSIS
# ============================================================

class IngredientAnalysis(BaseModel):
    """Analysis result for a single ingredient."""
    name: str = Field(..., max_length=200, description="Ingredient name")
    category: IngredientCategory = Field(..., description="Inflammation category")
    score: int = Field(..., ge=1, le=10, description="1=inflammatory, 10=anti-inflammatory")
    reason: str = Field(..., max_length=500, description="Explanation for the classification")
    is_inflammatory: bool = Field(..., description="True if score <= 4")
    is_additive: bool = Field(default=False, description="True if ingredient is an additive/preservative")
    scientific_notes: Optional[str] = Field(default=None, max_length=500, description="Optional scientific context")


# ============================================================
# ANALYSIS REQUEST/RESPONSE
# ============================================================

class AnalyzeInflammationRequest(BaseModel):
    """Request to analyze inflammation from barcode scan."""
    user_id: str = Field(..., description="User ID for history tracking")
    barcode: str = Field(..., max_length=50, description="Product barcode")
    product_name: Optional[str] = Field(default=None, max_length=500, description="Product name from barcode lookup")
    ingredients_text: str = Field(..., min_length=3, max_length=10000, description="Raw ingredients text from Open Food Facts")


class InflammationAnalysisResponse(BaseModel):
    """Complete inflammation analysis response."""
    # Identifiers
    analysis_id: str = Field(..., description="UUID of the analysis")
    barcode: str
    product_name: Optional[str] = None

    # Overall assessment
    overall_score: int = Field(..., ge=1, le=10, description="1=highly inflammatory, 10=highly anti-inflammatory")
    overall_category: InflammationCategory
    summary: str = Field(..., max_length=1000, description="Plain-language summary")
    recommendation: Optional[str] = Field(default=None, max_length=500, description="Actionable recommendation")

    # Detailed analysis
    ingredient_analyses: List[IngredientAnalysis] = Field(default_factory=list)

    # Flagged items for quick display
    inflammatory_ingredients: List[str] = Field(default_factory=list, description="Names of inflammatory ingredients")
    anti_inflammatory_ingredients: List[str] = Field(default_factory=list, description="Names of anti-inflammatory ingredients")
    additives_found: List[str] = Field(default_factory=list, description="Names of additives/preservatives")

    # Counts for UI
    inflammatory_count: int = Field(default=0, description="Count of inflammatory ingredients")
    anti_inflammatory_count: int = Field(default=0, description="Count of anti-inflammatory ingredients")
    neutral_count: int = Field(default=0, description="Count of neutral ingredients")

    # Metadata
    from_cache: bool = Field(default=False, description="True if result was cached")
    analysis_confidence: Optional[float] = Field(default=None, ge=0, le=1, description="AI confidence score")
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================================
# USER HISTORY
# ============================================================

class UserInflammationScan(BaseModel):
    """A user's scan history entry."""
    scan_id: str
    user_id: str
    barcode: str
    product_name: Optional[str] = None
    overall_score: int
    overall_category: InflammationCategory
    summary: str
    scanned_at: datetime
    notes: Optional[str] = None
    is_favorited: bool = False

    class Config:
        from_attributes = True


class UserInflammationHistoryResponse(BaseModel):
    """Paginated user scan history."""
    items: List[UserInflammationScan]
    total_count: int
    has_more: bool = False


class UserInflammationStatsResponse(BaseModel):
    """Aggregated inflammation statistics for a user."""
    user_id: str
    total_scans: int = 0
    avg_inflammation_score: Optional[float] = None
    inflammatory_products_scanned: int = 0
    anti_inflammatory_products_scanned: int = 0
    last_scan_at: Optional[datetime] = None


# ============================================================
# UPDATE REQUESTS
# ============================================================

class UpdateScanNotesRequest(BaseModel):
    """Request to update notes on a scan."""
    notes: Optional[str] = Field(default=None, max_length=2000)


class ToggleFavoriteRequest(BaseModel):
    """Request to toggle favorite status."""
    is_favorited: bool
