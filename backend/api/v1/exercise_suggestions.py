"""
Exercise Suggestions API - LangGraph agent-powered exercise alternatives.

ENDPOINTS:
- POST /api/v1/exercise-suggestions/suggest - Get AI-powered exercise suggestions

RATE LIMITS:
- /suggest: 5 requests/minute (AI-intensive)

Updated: 2025-12-21 - Trigger Render redeploy for swap exercise feature
"""
from fastapi import APIRouter, HTTPException, Request
from typing import List, Optional, Dict, Any
from pydantic import BaseModel

from services.langgraph_agents.exercise_suggestion import (
    ExerciseSuggestionState,
    build_exercise_suggestion_graph,
)
from core.logger import get_logger
from core.rate_limiter import limiter

router = APIRouter()
logger = get_logger(__name__)

# Build the graph once at module load
exercise_suggestion_graph = None


def get_suggestion_graph():
    """Lazy initialization of the suggestion graph."""
    global exercise_suggestion_graph
    if exercise_suggestion_graph is None:
        exercise_suggestion_graph = build_exercise_suggestion_graph()
    return exercise_suggestion_graph


# ==================== Request/Response Models ====================

class CurrentExercise(BaseModel):
    """Current exercise being swapped."""
    name: str
    sets: int = 3
    reps: int = 10
    muscle_group: Optional[str] = None
    equipment: Optional[str] = None


class SuggestionRequest(BaseModel):
    """Request for exercise suggestions."""
    user_id: str  # UUID string
    message: str  # User's request (e.g., "I don't have dumbbells")
    current_exercise: CurrentExercise
    user_equipment: Optional[List[str]] = None
    user_injuries: Optional[List[str]] = None
    user_fitness_level: Optional[str] = "intermediate"
    avoided_exercises: Optional[List[str]] = None  # Exercises user wants to avoid


class ExerciseSuggestion(BaseModel):
    """A single exercise suggestion."""
    id: Optional[str] = None
    name: str
    body_part: Optional[str] = None
    equipment: Optional[str] = None
    target_muscle: Optional[str] = None
    reason: str
    tip: Optional[str] = None
    rank: int = 1  # 1 = best match, 2 = second best, etc.


class SuggestionResponse(BaseModel):
    """Response with exercise suggestions."""
    suggestions: List[ExerciseSuggestion]
    message: str
    swap_reason: Optional[str] = None


# ==================== Endpoints ====================

@router.post("/suggest", response_model=SuggestionResponse)
@limiter.limit("5/minute")
async def get_exercise_suggestions(http_request: Request, request: SuggestionRequest):
    """
    Get AI-powered exercise suggestions.

    This endpoint uses a LangGraph agent that:
    1. Analyzes WHY the user wants to swap (equipment, injury, difficulty, etc.)
    2. Searches the exercise library for matching alternatives
    3. Uses AI to rank and explain the best options

    Example requests:
    - "I don't have dumbbells" -> finds bodyweight or barbell alternatives
    - "I have a shoulder injury" -> finds exercises that avoid shoulders
    - "I want something easier" -> finds lower difficulty alternatives
    - "Give me variety" -> finds different exercises targeting same muscle
    """
    logger.info(f"Exercise suggestion request: {request.message[:50]}...")

    try:
        graph = get_suggestion_graph()

        # Build initial state
        initial_state: ExerciseSuggestionState = {
            "user_id": request.user_id,
            "user_message": request.message,
            "current_exercise": request.current_exercise.model_dump(),
            "user_equipment": request.user_equipment,
            "user_injuries": request.user_injuries,
            "user_fitness_level": request.user_fitness_level,
            "avoided_exercises": request.avoided_exercises,  # Pass avoided exercises to filter
            # Will be filled by nodes
            "swap_reason": None,
            "target_muscle_group": None,
            "equipment_constraint": None,
            "difficulty_preference": None,
            "candidate_exercises": [],
            "suggestions": [],
            "response_message": "",
            "error": None,
        }

        # Execute the graph
        final_state = await graph.ainvoke(initial_state)

        # Check for errors
        if final_state.get("error"):
            logger.error(f"Suggestion agent error: {final_state['error']}")

        # Build response with ranking (order matters - first is best match)
        suggestions = [
            ExerciseSuggestion(
                id=s.get("id"),
                name=s.get("name", "Unknown"),
                body_part=s.get("body_part"),
                equipment=s.get("equipment"),
                target_muscle=s.get("target_muscle"),
                reason=s.get("reason", ""),
                tip=s.get("tip"),
                rank=idx + 1,  # 1-indexed rank
            )
            for idx, s in enumerate(final_state.get("suggestions", []))
        ]

        response = SuggestionResponse(
            suggestions=suggestions,
            message=final_state.get("response_message", "Here are some alternatives:"),
            swap_reason=final_state.get("swap_reason"),
        )

        logger.info(f"Returning {len(suggestions)} suggestions")
        return response

    except Exception as e:
        logger.error(f"Exercise suggestion failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
