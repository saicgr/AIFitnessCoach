"""
State schema for the Cycle Agent.
"""
from typing import TypedDict, List, Dict, Any, Optional, Union
from models.chat import CoachIntent


class CycleAgentState(TypedDict):
    """
    State for the menstrual-cycle agent.
    Handles cycle questions, symptom/period logging, and phase guidance.
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

    # Cycle context (assembled by services.cycle.cycle_context.build_cycle_context)
    cycle_phase: Optional[str]
    cycle_context: Optional[Dict[str, Any]]

    # Live user timezone (IANA) carried from the HTTP handler
    user_tz: Optional[str]

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
