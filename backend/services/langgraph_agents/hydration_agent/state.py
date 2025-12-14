"""
State schema for the Hydration Agent.
"""
from typing import TypedDict, List, Dict, Any, Optional, Union
from models.chat import CoachIntent


class HydrationAgentState(TypedDict):
    """
    State for the hydration agent.
    Handles hydration logging and provides hydration advice.
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
    hydration_amount: Optional[int]

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
