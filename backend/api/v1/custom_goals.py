"""
Custom Goals API - Manage user's custom training goals.

Endpoints:
- POST /api/v1/custom-goals/ - Create a new custom goal
- GET /api/v1/custom-goals/{user_id} - Get all active goals for a user
- GET /api/v1/custom-goals/{user_id}/keywords - Get combined keywords for RAG
- PATCH /api/v1/custom-goals/{goal_id} - Update goal priority or active status
- DELETE /api/v1/custom-goals/{goal_id} - Delete a goal
- POST /api/v1/custom-goals/{user_id}/refresh - Refresh stale keywords
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import json

from core.logger import get_logger
from services.custom_goal_service import get_custom_goal_service

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# REQUEST/RESPONSE MODELS
# =============================================================================

class CreateGoalRequest(BaseModel):
    """Request body for creating a new custom goal."""
    user_id: str = Field(..., description="User's ID")
    goal_text: str = Field(
        ...,
        min_length=5,
        max_length=500,
        description="Natural language goal description"
    )
    priority: int = Field(
        default=3,
        ge=1,
        le=5,
        description="Priority 1-5, higher = more focus"
    )


class GoalResponse(BaseModel):
    """Response model for a custom goal."""
    id: str
    user_id: str
    goal_text: str
    search_keywords: List[str]
    goal_type: str
    progression_strategy: str
    exercise_categories: List[str]
    muscle_groups: List[str]
    target_metrics: Dict[str, Any]
    training_notes: Optional[str]
    is_active: bool
    priority: int
    created_at: Optional[str]


class UpdateGoalRequest(BaseModel):
    """Request body for updating a goal."""
    is_active: Optional[bool] = None
    priority: Optional[int] = Field(default=None, ge=1, le=5)


class KeywordsResponse(BaseModel):
    """Response model for combined keywords."""
    keywords: List[str]
    goal_count: int


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def _parse_json_field(value, default=None):
    """Parse a field that could be JSON string or already parsed."""
    if value is None:
        return default if default is not None else []
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return default if default is not None else []
    return value


def _goal_to_response(goal: dict) -> GoalResponse:
    """Convert database goal record to response model."""
    return GoalResponse(
        id=goal["id"],
        user_id=goal["user_id"],
        goal_text=goal["goal_text"],
        search_keywords=_parse_json_field(goal.get("search_keywords"), []),
        goal_type=goal.get("goal_type", "general"),
        progression_strategy=goal.get("progression_strategy", "linear"),
        exercise_categories=_parse_json_field(goal.get("exercise_categories"), []),
        muscle_groups=_parse_json_field(goal.get("muscle_groups"), []),
        target_metrics=_parse_json_field(goal.get("target_metrics"), {}),
        training_notes=goal.get("training_notes"),
        is_active=goal.get("is_active", True),
        priority=goal.get("priority", 3),
        created_at=goal.get("created_at"),
    )


# =============================================================================
# ENDPOINTS
# =============================================================================

@router.post("/", response_model=GoalResponse)
async def create_custom_goal(request: CreateGoalRequest):
    """
    Create a new custom goal with AI-generated keywords.

    This endpoint:
    1. Accepts a natural language goal (e.g., "Improve box jump height")
    2. Uses Gemini AI to generate search keywords and training info
    3. Stores the goal with cached keywords for future workout generation

    Keywords are generated ONCE here, not during every workout generation.
    """
    logger.info(f"Creating custom goal for user {request.user_id}: {request.goal_text[:50]}...")

    try:
        service = get_custom_goal_service()
        goal = await service.create_custom_goal(
            user_id=request.user_id,
            goal_text=request.goal_text,
            priority=request.priority,
        )

        logger.info(f"Created goal {goal['id']} with {len(goal.get('search_keywords', []))} keywords")
        return _goal_to_response(goal)

    except Exception as e:
        logger.error(f"Failed to create custom goal: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}", response_model=List[GoalResponse])
async def get_user_goals(user_id: str):
    """
    Get all active custom goals for a user.

    Goals are ordered by priority (highest first).
    """
    try:
        service = get_custom_goal_service()
        goals = await service.get_active_goals(user_id)

        logger.debug(f"Retrieved {len(goals)} goals for user {user_id}")
        return [_goal_to_response(g) for g in goals]

    except Exception as e:
        logger.error(f"Failed to get goals for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}/keywords", response_model=KeywordsResponse)
async def get_combined_keywords(user_id: str):
    """
    Get combined search keywords from all active goals.

    This endpoint is used by the exercise RAG service to augment
    search queries with user's custom goal keywords.

    Keywords are deduplicated and weighted by priority.
    """
    try:
        service = get_custom_goal_service()
        keywords = await service.get_combined_keywords(user_id)
        goals = await service.get_active_goals(user_id)

        return KeywordsResponse(
            keywords=keywords,
            goal_count=len(goals)
        )

    except Exception as e:
        logger.error(f"Failed to get keywords for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/{goal_id}", response_model=GoalResponse)
async def update_goal(goal_id: str, request: UpdateGoalRequest):
    """
    Update a custom goal's priority or active status.

    Use this to:
    - Deactivate a goal without deleting it (is_active=false)
    - Change priority (1-5, higher = more focus)
    """
    if request.is_active is None and request.priority is None:
        raise HTTPException(status_code=400, detail="No updates provided")

    try:
        service = get_custom_goal_service()
        goal = await service.update_goal(
            goal_id=goal_id,
            is_active=request.is_active,
            priority=request.priority,
        )

        logger.info(f"Updated goal {goal_id}: active={request.is_active}, priority={request.priority}")
        return _goal_to_response(goal)

    except Exception as e:
        logger.error(f"Failed to update goal {goal_id}: {e}")
        if "not found" in str(e).lower():
            raise HTTPException(status_code=404, detail="Goal not found")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{goal_id}")
async def delete_goal(goal_id: str):
    """
    Delete a custom goal permanently.

    Consider using PATCH with is_active=false to deactivate instead.
    """
    try:
        service = get_custom_goal_service()
        success = await service.delete_goal(goal_id)

        if not success:
            raise HTTPException(status_code=404, detail="Goal not found")

        logger.info(f"Deleted goal {goal_id}")
        return {"success": True, "message": "Goal deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete goal {goal_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/refresh")
async def refresh_keywords(user_id: str):
    """
    Refresh stale keywords for a user's goals.

    Keywords are refreshed if they haven't been updated in 30+ days.
    This should be called periodically, not during workout generation.
    """
    try:
        service = get_custom_goal_service()
        refreshed_count = await service.refresh_stale_keywords(user_id)

        return {
            "success": True,
            "refreshed_count": refreshed_count,
            "message": f"Refreshed {refreshed_count} goal(s)"
        }

    except Exception as e:
        logger.error(f"Failed to refresh keywords for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
