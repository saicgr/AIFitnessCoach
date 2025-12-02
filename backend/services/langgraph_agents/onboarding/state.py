"""
OnboardingState schema for the onboarding agent.

This defines the state that flows through the onboarding graph nodes.
"""
from typing import TypedDict, List, Dict, Any, Optional
from langchain_core.messages import BaseMessage


class OnboardingState(TypedDict):
    """
    State for the onboarding agent graph.

    This state is passed through all nodes in the onboarding graph,
    tracking the conversation, collected data, and completion status.
    """
    # Input
    user_message: str
    user_id: str
    conversation_history: List[Dict[str, str]]

    # Collected Data
    collected_data: Dict[str, Any]  # {name, goals, equipment, etc.}

    # Processing
    messages: List[BaseMessage]  # LangChain messages for LLM
    next_question: Optional[str]  # AI-generated question

    # Validation
    missing_fields: List[str]  # Fields still needed
    validation_errors: Dict[str, str]  # Field validation errors

    # Completion
    is_complete: bool  # Whether onboarding is finished

    # Output
    final_response: str  # Response to send to user
    error: Optional[str]  # Error message if something went wrong

    # Component rendering (for frontend)
    component: Optional[str]  # 'day_picker', 'health_checklist', etc.
    quick_replies: Optional[List[Dict[str, Any]]]  # Quick reply buttons
    multi_select: bool  # Whether quick replies support multi-select

