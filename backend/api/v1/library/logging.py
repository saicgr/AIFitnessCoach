"""
Library Logging API endpoints.

Provides endpoints for logging user interactions with the library
for AI personalization and preference learning.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import logging

from core.auth import get_current_user
from services.user_context_service import user_context_service

logger = logging.getLogger(__name__)

router = APIRouter()


# =============================================================================
# REQUEST MODELS
# =============================================================================

class ExerciseViewRequest(BaseModel):
    """Request model for logging exercise view events."""
    exercise_id: str = Field(..., description="Exercise ID")
    exercise_name: str = Field(..., description="Name of the exercise")
    source: str = Field(
        default="library_browse",
        description="Source of the view (library_browse, search_result, carousel, workout_detail)"
    )
    muscle_group: Optional[str] = Field(None, description="Target muscle group")
    difficulty: Optional[str] = Field(None, description="Exercise difficulty level")
    equipment: Optional[List[str]] = Field(None, description="Equipment required")


class ProgramViewRequest(BaseModel):
    """Request model for logging program view events."""
    program_id: str = Field(..., description="Program ID")
    program_name: str = Field(..., description="Name of the program")
    category: Optional[str] = Field(None, description="Program category")
    difficulty: Optional[str] = Field(None, description="Program difficulty level")
    duration_weeks: Optional[int] = Field(None, description="Program duration in weeks")


class SearchRequest(BaseModel):
    """Request model for logging search events."""
    search_query: str = Field(..., description="The search query text")
    search_type: str = Field(
        default="exercises",
        description="Type of search (exercises or programs)"
    )
    filters_used: Optional[Dict[str, Any]] = Field(
        None,
        description="Dictionary of filters applied"
    )
    result_count: int = Field(default=0, description="Number of results returned")


class FilterRequest(BaseModel):
    """Request model for logging filter events."""
    filter_type: str = Field(
        ...,
        description="Type of filter (muscle_group, equipment, difficulty, body_part, etc.)"
    )
    filter_values: List[str] = Field(..., description="List of selected filter values")
    result_count: int = Field(default=0, description="Number of results after filtering")


# =============================================================================
# RESPONSE MODELS
# =============================================================================

class LogResponse(BaseModel):
    """Response model for log endpoints."""
    success: bool
    event_id: Optional[str] = None
    message: str


class LibraryPreferencesResponse(BaseModel):
    """Response model for library preferences."""
    user_id: str
    period_days: int
    has_library_activity: bool
    total_events: int
    exercise_views: Optional[Dict[str, Any]] = None
    searches: Optional[Dict[str, Any]] = None
    filters: Optional[Dict[str, Any]] = None
    program_views: Optional[Dict[str, Any]] = None
    ai_context: Optional[str] = None


# =============================================================================
# ENDPOINTS
# =============================================================================

@router.post(
    "/log/exercise-view",
    response_model=LogResponse,
    summary="Log exercise view",
    description="Log when a user views an exercise detail in the library."
)
async def log_exercise_view(
    request: ExerciseViewRequest,
    user_id: str = Depends(get_current_user),
):
    """
    Log when a user views an exercise detail in the library.

    This helps the AI learn:
    - Which exercises the user is interested in
    - Preferred muscle groups and difficulty levels
    - Equipment preferences based on viewing patterns
    """
    try:
        event_id = await user_context_service.log_exercise_viewed(
            user_id=user_id,
            exercise_id=request.exercise_id,
            exercise_name=request.exercise_name,
            source=request.source,
            muscle_group=request.muscle_group,
            difficulty=request.difficulty,
            equipment=request.equipment,
        )

        return LogResponse(
            success=True,
            event_id=event_id,
            message="Exercise view logged successfully"
        )
    except Exception as e:
        logger.error(f"Failed to log exercise view: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to log exercise view: {str(e)}"
        )


@router.post(
    "/log/program-view",
    response_model=LogResponse,
    summary="Log program view",
    description="Log when a user views a program detail in the library."
)
async def log_program_view(
    request: ProgramViewRequest,
    user_id: str = Depends(get_current_user),
):
    """
    Log when a user views a program detail in the library.

    This helps the AI learn:
    - Which programs the user is interested in
    - Preferred program categories
    - Preferred program duration and difficulty
    """
    try:
        event_id = await user_context_service.log_program_viewed(
            user_id=user_id,
            program_id=request.program_id,
            program_name=request.program_name,
            category=request.category,
            difficulty=request.difficulty,
            duration_weeks=request.duration_weeks,
        )

        return LogResponse(
            success=True,
            event_id=event_id,
            message="Program view logged successfully"
        )
    except Exception as e:
        logger.error(f"Failed to log program view: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to log program view: {str(e)}"
        )


@router.post(
    "/log/search",
    response_model=LogResponse,
    summary="Log library search",
    description="Log when a user searches in the library."
)
async def log_library_search(
    request: SearchRequest,
    user_id: str = Depends(get_current_user),
):
    """
    Log when a user searches in the library.

    This helps the AI learn:
    - What exercises/programs users are looking for
    - Common search patterns and terminology
    - Preferred filters and result expectations
    """
    try:
        event_id = await user_context_service.log_library_search(
            user_id=user_id,
            search_query=request.search_query,
            search_type=request.search_type,
            filters_used=request.filters_used,
            result_count=request.result_count,
        )

        return LogResponse(
            success=True,
            event_id=event_id,
            message="Library search logged successfully"
        )
    except Exception as e:
        logger.error(f"Failed to log library search: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to log library search: {str(e)}"
        )


@router.post(
    "/log/filter",
    response_model=LogResponse,
    summary="Log filter usage",
    description="Log when a user applies a filter in the library."
)
async def log_exercise_filter(
    request: FilterRequest,
    user_id: str = Depends(get_current_user),
):
    """
    Log when a user applies a filter in the library.

    This helps the AI learn:
    - Preferred muscle groups and body parts
    - Equipment preferences
    - Difficulty level preferences
    """
    try:
        event_id = await user_context_service.log_exercise_filter_used(
            user_id=user_id,
            filter_type=request.filter_type,
            filter_values=request.filter_values,
            result_count=request.result_count,
        )

        return LogResponse(
            success=True,
            event_id=event_id,
            message="Filter usage logged successfully"
        )
    except Exception as e:
        logger.error(f"Failed to log filter usage: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to log filter usage: {str(e)}"
        )


@router.get(
    "/preferences",
    response_model=LibraryPreferencesResponse,
    summary="Get library preferences",
    description="Get user's library interaction preferences for AI personalization."
)
async def get_library_preferences(
    days: int = 30,
    user_id: str = Depends(get_current_user),
):
    """
    Get user's library interaction preferences.

    Returns insights about:
    - Most viewed muscle groups
    - Preferred difficulty levels
    - Equipment preferences
    - Common search terms
    """
    try:
        preferences = await user_context_service.get_library_preferences(
            user_id=user_id,
            days=days,
        )

        # Generate AI context
        ai_context = user_context_service.get_library_ai_context(preferences)

        return LibraryPreferencesResponse(
            user_id=preferences.get("user_id", user_id),
            period_days=preferences.get("period_days", days),
            has_library_activity=preferences.get("has_library_activity", False),
            total_events=preferences.get("total_events", 0),
            exercise_views=preferences.get("exercise_views"),
            searches=preferences.get("searches"),
            filters=preferences.get("filters"),
            program_views=preferences.get("program_views"),
            ai_context=ai_context if ai_context else None,
        )
    except Exception as e:
        logger.error(f"Failed to get library preferences: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get library preferences: {str(e)}"
        )
