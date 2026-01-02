"""
State schema for the Plan Agent.
"""
from typing import TypedDict, List, Dict, Any, Optional, Union
from models.chat import CoachIntent


class PlanAgentState(TypedDict):
    """
    State for the plan agent.
    Handles holistic weekly planning integrating workouts, nutrition, and fasting.
    """
    # Input (from ChatRequest)
    user_message: str
    user_id: Union[str, int]
    user_profile: Optional[Dict[str, Any]]
    conversation_history: List[Dict[str, str]]

    # AI personality settings
    ai_settings: Optional[Dict[str, Any]]

    # Intent extraction results
    intent: Optional[CoachIntent]

    # Plan-specific context
    current_plan: Optional[Dict[str, Any]]  # Current weekly plan if exists
    workout_days: List[int]  # Days of week for training (0=Mon, 6=Sun)
    fasting_protocol: Optional[str]  # 16:8, 18:6, OMAD, None
    nutrition_strategy: Optional[str]  # workout_aware, static, cutting, bulking
    nutrition_targets: Optional[Dict[str, Any]]  # Base calorie/macro targets
    preferred_workout_time: Optional[str]  # HH:MM format

    # Generated plan data
    generated_plan: Optional[Dict[str, Any]]  # AI-generated plan structure
    daily_entries: List[Dict[str, Any]]  # Daily plan entries
    meal_suggestions: List[Dict[str, Any]]  # Generated meal suggestions
    coordination_notes: List[Dict[str, Any]]  # Warnings and notes

    # RAG context (if needed for exercise/nutrition knowledge)
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

    # Error handling
    error: Optional[str]
