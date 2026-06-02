"""State schema for the Recommendation (synthesis) Agent — Gap 7 Part B."""
from typing import TypedDict, List, Dict, Any, Optional, Union

from models.chat import CoachIntent


class RecommendationAgentState(TypedDict):
    """State for the cross-domain recommendation agent.

    Single purpose: turn the user's whole picture (eaten + workouts + training
    load + injuries + recovery + dietary prefs) into ONE grounded recommendation
    — the video's "vegan + peak-zone runs → plant-based recovery fats + a
    lighter session" moment. Unlike the nutrition agent (food only) and the
    coach (no meal history/targets), this agent reasons across all domains at
    once via `build_holistic_context`.
    """
    # Input (from ChatRequest)
    user_message: str
    user_id: Union[str, int]
    user_profile: Optional[Dict[str, Any]]
    conversation_history: List[Dict[str, str]]

    # Live phone IANA timezone (carried through every state so today's nutrition
    # + cycle resolve against the user's real calendar day, never UTC).
    user_tz: Optional[str]

    # AI personality settings
    ai_settings: Optional[Dict[str, Any]]

    # Intent extraction results
    intent: Optional[CoachIntent]

    # RAG context (optional — the agent is grounded by holistic_context, not RAG)
    rag_documents: List[Dict[str, Any]]
    rag_context_formatted: str

    # Assembled cross-domain context (build_holistic_context output) — attached
    # by the node itself (not pre-fetched in langgraph_service) so the agent is
    # self-contained and reusable from non-chat surfaces.
    holistic_context: Optional[Dict[str, Any]]

    # Response generation
    ai_response: str
    final_response: str

    # Output
    action_data: Optional[Dict[str, Any]]
    rag_context_used: bool
    similar_questions: List[str]

    # Error handling
    error: Optional[str]

    # i18n — ISO 639-1 locale code.
    locale: Optional[str]
