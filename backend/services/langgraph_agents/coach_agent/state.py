"""
State schema for the Coach Agent.
"""
from typing import TypedDict, List, Dict, Any, Optional, Union
from models.chat import CoachIntent


class CoachAgentState(TypedDict):
    """
    State for the general coach agent.
    Handles general fitness coaching, greetings, and app control.
    """
    # Input (from ChatRequest)
    user_message: str
    user_id: Union[str, int]
    user_profile: Optional[Dict[str, Any]]
    current_workout: Optional[Dict[str, Any]]
    workout_schedule: Optional[Dict[str, Any]]
    conversation_history: List[Dict[str, str]]

    # Intent extraction results
    intent: Optional[CoachIntent]
    setting_name: Optional[str]
    setting_value: Optional[bool]
    destination: Optional[str]

    # RAG context
    rag_documents: List[Dict[str, Any]]
    rag_context_formatted: str

    # Response generation
    ai_response: str
    final_response: str

    # Output
    action_data: Optional[Dict[str, Any]]
    rag_context_used: bool
    similar_questions: List[str]

    # Error handling
    error: Optional[str]
