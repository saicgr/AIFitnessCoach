"""
Flexibility Assessment Pydantic models.

Models for tracking flexibility test results and progress over time.
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class FlexibilityRating(str, Enum):
    """Rating levels for flexibility assessments."""
    POOR = "poor"
    FAIR = "fair"
    GOOD = "good"
    EXCELLENT = "excellent"


class FlexibilityTestType(str, Enum):
    """Available flexibility test types."""
    SIT_AND_REACH = "sit_and_reach"
    SHOULDER_FLEXIBILITY = "shoulder_flexibility"
    HIP_FLEXOR = "hip_flexor"
    HAMSTRING = "hamstring"
    ANKLE_DORSIFLEXION = "ankle_dorsiflexion"
    THORACIC_ROTATION = "thoracic_rotation"
    GROIN_FLEXIBILITY = "groin_flexibility"
    QUADRICEPS = "quadriceps"
    CALF_FLEXIBILITY = "calf_flexibility"
    NECK_ROTATION = "neck_rotation"


# ============================================
# Flexibility Test Models
# ============================================

class FlexibilityTestBase(BaseModel):
    """Base model for flexibility tests."""
    id: str = Field(..., max_length=50, description="Unique identifier for the test")
    name: str = Field(..., max_length=100, description="Display name of the test")
    description: str = Field(..., max_length=500, description="Description of what this test measures")
    instructions: List[str] = Field(default_factory=list, description="Step-by-step instructions")
    unit: str = Field(default="inches", max_length=20, description="Unit of measurement")
    target_muscles: List[str] = Field(default_factory=list, description="Muscles targeted by this test")
    equipment_needed: List[str] = Field(default_factory=list, description="Equipment required")
    higher_is_better: bool = Field(default=True, description="Whether higher values indicate better flexibility")
    tips: List[str] = Field(default_factory=list, description="Tips for accurate testing")
    common_mistakes: List[str] = Field(default_factory=list, description="Common mistakes to avoid")
    video_url: Optional[str] = Field(default=None, max_length=500, description="URL to demonstration video")
    image_url: Optional[str] = Field(default=None, max_length=500, description="URL to demonstration image")


class FlexibilityTest(FlexibilityTestBase):
    """Full flexibility test model."""
    is_active: bool = Field(default=True, description="Whether this test is currently available")
    created_at: Optional[datetime] = None


# ============================================
# Flexibility Assessment Models
# ============================================

class FlexibilityAssessmentBase(BaseModel):
    """Base model for flexibility assessments."""
    test_type: str = Field(..., max_length=50, description="Type of flexibility test")
    measurement: float = Field(..., description="The measured value")
    unit: str = Field(default="inches", max_length=20, description="Unit of measurement")
    notes: Optional[str] = Field(default=None, max_length=500, description="Notes about this assessment")


class FlexibilityAssessmentCreate(FlexibilityAssessmentBase):
    """Model for creating a new flexibility assessment."""
    user_id: str = Field(..., max_length=100, description="User ID")


class FlexibilityAssessmentRecord(BaseModel):
    """Model for recording a new flexibility assessment with evaluation."""
    test_type: str = Field(..., max_length=50, description="Type of flexibility test")
    measurement: float = Field(..., description="The measured value")
    gender: str = Field(..., max_length=20, description="User's gender for norm comparison")
    age: int = Field(..., ge=1, le=120, description="User's age for norm comparison")
    notes: Optional[str] = Field(default=None, max_length=500, description="Notes about this assessment")


class FlexibilityAssessment(FlexibilityAssessmentBase):
    """Full flexibility assessment model with ID and metadata."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    rating: Optional[str] = Field(default=None, max_length=20, description="Rating based on norms")
    percentile: Optional[int] = Field(default=None, ge=0, le=100, description="Percentile ranking")
    assessed_at: datetime = Field(default_factory=datetime.utcnow)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class FlexibilityAssessmentWithEvaluation(FlexibilityAssessment):
    """Assessment with full evaluation details."""
    test_name: Optional[str] = None
    target_muscles: List[str] = Field(default_factory=list)
    recommendations: List[Dict[str, Any]] = Field(default_factory=list)
    improvement_message: Optional[str] = None
    tips: List[str] = Field(default_factory=list)
    common_mistakes: List[str] = Field(default_factory=list)


# ============================================
# Stretch Plan Models
# ============================================

class StretchExercise(BaseModel):
    """A single stretch exercise recommendation."""
    name: str = Field(..., max_length=100, description="Name of the stretch")
    duration: Optional[str] = Field(default=None, max_length=20, description="Duration (e.g., '30 sec')")
    reps: Optional[int] = Field(default=None, ge=1, le=50, description="Number of repetitions")
    sets: int = Field(default=2, ge=1, le=10, description="Number of sets")
    notes: Optional[str] = Field(default=None, max_length=200, description="Additional notes")


class FlexibilityStretchPlan(BaseModel):
    """Personalized stretch plan based on assessment results."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    test_type: str = Field(..., max_length=50)
    rating: str = Field(..., max_length=20)
    stretches: List[StretchExercise] = Field(default_factory=list)
    is_active: bool = Field(default=True)
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


# ============================================
# Progress Tracking Models
# ============================================

class FlexibilityProgress(BaseModel):
    """Progress tracking for a specific test type."""
    user_id: str
    test_type: str
    assessment_date: datetime
    measurement: float
    unit: str
    rating: Optional[str] = None
    percentile: Optional[int] = None
    previous_measurement: Optional[float] = None
    improvement: Optional[float] = None
    previous_rating: Optional[str] = None
    assessment_number: int = 1


class FlexibilityTrend(BaseModel):
    """Trend data for a specific test type."""
    test_type: str
    test_name: str
    unit: str
    first_assessment: Dict[str, Any]
    latest_assessment: Dict[str, Any]
    total_assessments: int
    improvement: Dict[str, Any]
    trend_data: List[Dict[str, Any]]


# ============================================
# Summary Models
# ============================================

class FlexibilityTestSummary(BaseModel):
    """Summary of a user's performance on a specific test."""
    test_type: str
    test_name: str
    latest_measurement: float
    unit: str
    rating: str
    percentile: int
    total_assessments: int
    improvement_from_first: Optional[float] = None
    last_assessed: datetime


class FlexibilitySummary(BaseModel):
    """Overall flexibility summary for a user."""
    overall_score: float = Field(..., ge=0, le=100, description="Overall flexibility score (0-100)")
    overall_rating: str
    tests_completed: int
    total_assessments: int
    first_assessment: Optional[datetime] = None
    latest_assessment: Optional[datetime] = None
    category_ratings: Dict[str, str] = Field(default_factory=dict)
    areas_needing_improvement: List[str] = Field(default_factory=list)
    improvement_priority: List[Dict[str, Any]] = Field(default_factory=list)


class FlexibilityScoreResponse(BaseModel):
    """Response from get_flexibility_score function."""
    overall_score: float
    overall_rating: str
    tests_completed: int
    areas_needing_improvement: List[str]


# ============================================
# Request/Response Models
# ============================================

class RecordAssessmentRequest(BaseModel):
    """Request to record a new flexibility assessment."""
    test_type: str = Field(..., max_length=50, description="Type of flexibility test")
    measurement: float = Field(..., description="The measured value")
    notes: Optional[str] = Field(default=None, max_length=500, description="Notes about this assessment")


class RecordAssessmentResponse(BaseModel):
    """Response from recording an assessment."""
    success: bool
    message: str = Field(..., max_length=500)
    assessment: FlexibilityAssessmentWithEvaluation
    is_improvement: bool = Field(default=False, description="Whether this is an improvement from last time")
    rating_improved: bool = Field(default=False, description="Whether the rating level improved")


class GetHistoryRequest(BaseModel):
    """Request parameters for getting assessment history."""
    test_type: Optional[str] = Field(default=None, max_length=50, description="Filter by test type")
    limit: int = Field(default=50, ge=1, le=200, description="Maximum number of records to return")
    days: Optional[int] = Field(default=None, ge=1, le=365, description="Filter by days ago")


class GetProgressRequest(BaseModel):
    """Request parameters for getting progress data."""
    test_type: str = Field(..., max_length=50, description="Type of flexibility test")
    days: int = Field(default=90, ge=7, le=365, description="Number of days to include")


class CompareAssessmentsRequest(BaseModel):
    """Request to compare multiple assessments."""
    test_type: str = Field(..., max_length=50)
    assessment_ids: List[str] = Field(..., min_length=2, max_length=10)


class BatchEvaluationRequest(BaseModel):
    """Request for batch evaluation of multiple test results."""
    assessments: List[RecordAssessmentRequest]
    gender: str = Field(..., max_length=20)
    age: int = Field(..., ge=1, le=120)
