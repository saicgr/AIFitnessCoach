"""
State schema for the Nutrition Agent.
"""
from typing import TypedDict, List, Dict, Any, Optional, Union
from models.chat import CoachIntent


class NutritionAgentState(TypedDict):
    """
    State for the nutrition agent.
    Handles food analysis, meal logging, and dietary advice.
    """
    # Input (from ChatRequest)
    user_message: str
    user_id: Union[str, int]
    user_profile: Optional[Dict[str, Any]]
    conversation_history: List[Dict[str, str]]
    image_base64: Optional[str]  # Base64 encoded image for food analysis
    media_refs: Optional[List[Dict[str, Any]]]  # Multi-media references for batch analysis

    # AI personality settings
    ai_settings: Optional[Dict[str, Any]]

    # Intent extraction results
    intent: Optional[CoachIntent]

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

    # Media classification (from media classifier)
    media_content_type: Optional[str]

    # Error handling
    error: Optional[str]
