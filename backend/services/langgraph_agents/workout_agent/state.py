"""
State schema for the Workout Agent.
"""
from typing import TypedDict, List, Dict, Any, Optional, Union
from models.chat import CoachIntent


class WorkoutAgentState(TypedDict):
    """
    State for the workout agent.
    Handles workout modifications, scheduling, and exercise guidance.
    """
    # Input (from ChatRequest)
    user_message: str
    user_id: Union[str, int]
    user_profile: Optional[Dict[str, Any]]
    current_workout: Optional[Dict[str, Any]]
    workout_schedule: Optional[Dict[str, Any]]
    conversation_history: List[Dict[str, str]]

    # AI personality settings
    ai_settings: Optional[Dict[str, Any]]

    # Intent extraction results
    intent: Optional[CoachIntent]
    extracted_exercises: List[str]
    extracted_muscle_groups: List[str]
    modification: Optional[str]

    # RAG context
    rag_documents: List[Dict[str, Any]]
    rag_context_formatted: str

    # Tool execution
    tool_calls: List[Dict[str, Any]]
    tool_results: List[Dict[str, Any]]
    tool_messages: List[Any]
    messages: List[Any]

    # Response generation
    ai_response: str
    final_response: str

    # Output
    action_data: Optional[Dict[str, Any]]
    rag_context_used: bool
    similar_questions: List[str]

    # Error handling
    error: Optional[str]
