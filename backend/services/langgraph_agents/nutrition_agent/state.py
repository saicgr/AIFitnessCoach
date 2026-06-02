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

    # ── Day-context fields (pre-fetched by _build_agent_state) ───────────
    # These let the nutrition agent reason about today's logged meals,
    # scheduled workout, and the user's favorites without tool round-trips.
    # Any field may be None if the user hasn't set targets / logged meals /
    # has no saved foods / is a rest day. `context_partial=True` when any
    # pre-fetch helper raised — the prompt will soften its confidence.
    current_workout: Optional[Dict[str, Any]]
    workout_schedule: Optional[Dict[str, Any]]
    daily_nutrition_context: Optional[Dict[str, Any]]
    recent_favorites: Optional[List[Dict[str, Any]]]
    context_partial: bool

    # Gap 7/17 — cross-domain context so a food rec respects the whole picture.
    # dietary_constraints unions diet_type + dietary_restrictions[] + coach_memory
    # 'dietary' (the HARD vegan/allergy rule). memory/cardio/health blocks let the
    # food rec reason across injuries, training load, and recovery.
    dietary_constraints: Optional[Dict[str, Any]]
    memory_context: Optional[str]
    cardio_context: Optional[str]
    health_context: Optional[str]
    # Gap 15 — glucose↔food correlation block (diabetes users; "" otherwise).
    glucose_context: Optional[str]

    # Cycle context (Phase F) — phase string + compact summary only, so
    # "what should I eat today" is cycle-aware. Never raw hormone_logs rows.
    cycle_phase: Optional[str]
    cycle_context: Optional[Dict[str, Any]]

    # Error handling
    error: Optional[str]

    # i18n — ISO 639-1 locale code. Injected into system prompt.
    locale: Optional[str]
