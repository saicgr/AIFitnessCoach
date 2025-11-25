"""
Chat-related data models.
Pydantic models for request/response validation.
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class CoachIntent(str, Enum):
    """Possible intents extracted from user messages."""
    ADD_EXERCISE = "add_exercise"
    REMOVE_EXERCISE = "remove_exercise"
    SWAP_WORKOUT = "swap_workout"
    MODIFY_INTENSITY = "modify_intensity"
    RESCHEDULE = "reschedule"
    REPORT_INJURY = "report_injury"
    QUESTION = "question"


class UserProfile(BaseModel):
    """User profile for context in chat."""
    id: int
    fitness_level: str = "beginner"
    goals: List[str] = []
    equipment: List[str] = []
    active_injuries: List[str] = []


class WorkoutContext(BaseModel):
    """Current workout context."""
    id: int
    name: str
    type: str
    difficulty: str
    exercises: List[Dict[str, Any]] = []
    scheduled_date: Optional[str] = None
    is_completed: bool = False


class WorkoutScheduleContext(BaseModel):
    """Workout schedule context for AI to understand temporal context."""
    yesterday: Optional[WorkoutContext] = None
    today: Optional[WorkoutContext] = None
    tomorrow: Optional[WorkoutContext] = None
    thisWeek: List[WorkoutContext] = []
    recentCompleted: List[WorkoutContext] = []


class ChatRequest(BaseModel):
    """
    Request body for chat endpoint.

    Example:
        {
            "message": "add barbell rows to my workout",
            "user_id": 1,
            "user_profile": {...},
            "current_workout": {...},
            "workout_schedule": {...},
            "conversation_history": [...]
        }
    """
    message: str = Field(..., min_length=1, description="User's message")
    user_id: int = Field(..., description="User ID")
    user_profile: Optional[UserProfile] = None
    current_workout: Optional[WorkoutContext] = None
    workout_schedule: Optional[WorkoutScheduleContext] = Field(
        default=None,
        description="Workout schedule context (yesterday, today, tomorrow, thisWeek, recentCompleted)"
    )
    conversation_history: List[Dict[str, Any]] = Field(
        default=[],
        description="Previous messages in format [{'role': 'user'/'assistant', 'content': '...'}]"
    )


class IntentExtraction(BaseModel):
    """Extracted intent and entities from user message."""
    intent: CoachIntent
    exercises: List[str] = []
    muscle_groups: List[str] = []
    modification: Optional[str] = None
    body_part: Optional[str] = None


class ChatResponse(BaseModel):
    """
    Response from chat endpoint.

    Example:
        {
            "message": "I've added Barbell Row to your workout!",
            "intent": "add_exercise",
            "action_data": {"exercise_id": "barbell_row", ...},
            "rag_context_used": true
        }
    """
    message: str = Field(..., description="AI coach response")
    intent: CoachIntent = Field(..., description="Detected intent")
    action_data: Optional[Dict[str, Any]] = Field(
        None,
        description="Data for workout modifications"
    )
    rag_context_used: bool = Field(
        False,
        description="Whether RAG context was used"
    )
    similar_questions: List[str] = Field(
        default=[],
        description="Similar past questions found via RAG"
    )


class ChatMessage(BaseModel):
    """Stored chat message."""
    id: Optional[int] = None
    user_id: int
    user_message: str
    ai_response: str
    intent: str
    context_json: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class RAGDocument(BaseModel):
    """Document stored in RAG system."""
    id: str
    question: str
    answer: str
    intent: str
    user_id: int
    metadata: Dict[str, Any] = {}
    embedding: Optional[List[float]] = None
