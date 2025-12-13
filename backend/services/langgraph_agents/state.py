"""
State schema for the Fitness Coach LangGraph agent.

This TypedDict flows through all nodes, accumulating information
as the conversation is processed.
"""
from typing import TypedDict, List, Dict, Any, Optional, Union
from models.chat import CoachIntent


class FitnessCoachState(TypedDict):
    """
    Central state for the fitness coach agent.
    Flows through all nodes, accumulating information.
    """
    # Input (from ChatRequest)
    user_message: str
    user_id: Union[str, int]  # UUID from Supabase (string) or legacy int
    user_profile: Optional[Dict[str, Any]]
    current_workout: Optional[Dict[str, Any]]
    workout_schedule: Optional[Dict[str, Any]]  # yesterday, today, tomorrow, thisWeek, recentCompleted
    conversation_history: List[Dict[str, str]]
    image_base64: Optional[str]  # Base64 encoded image for food analysis

    # Intent extraction results
    intent: Optional[CoachIntent]
    extracted_exercises: List[str]
    extracted_muscle_groups: List[str]
    modification: Optional[str]
    body_part: Optional[str]
    # App settings
    setting_name: Optional[str]
    setting_value: Optional[bool]
    # Navigation
    destination: Optional[str]
    # Hydration logging
    hydration_amount: Optional[int]

    # RAG context
    rag_documents: List[Dict[str, Any]]
    rag_context_formatted: str

    # Tool execution
    tool_calls: List[Dict[str, Any]]  # Tools the LLM wants to call
    tool_results: List[Dict[str, Any]]
    tool_messages: List[Any]  # ToolMessage objects for LLM context
    messages: List[Any]  # Full message history for LLM

    # Response generation
    ai_response: str
    final_response: str

    # Output (for ChatResponse)
    action_data: Optional[Dict[str, Any]]
    rag_context_used: bool
    similar_questions: List[str]

    # Error handling
    error: Optional[str]

    # Routing
    next_node: Optional[str]
