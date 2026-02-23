"""
Chat-related data models.
Pydantic models for request/response validation.
"""
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class AgentType(str, Enum):
    """Types of specialized agents that can respond to messages."""
    COACH = "coach"          # Default general fitness coach
    NUTRITION = "nutrition"  # Nutrition and meal planning specialist
    WORKOUT = "workout"      # Workout planning and modification specialist
    INJURY = "injury"        # Injury management and recovery specialist
    HYDRATION = "hydration"  # Hydration tracking specialist
    PLAN = "plan"            # Holistic weekly planning specialist


class CoachIntent(str, Enum):
    """Possible intents extracted from user messages."""
    ADD_EXERCISE = "add_exercise"
    REMOVE_EXERCISE = "remove_exercise"
    SWAP_WORKOUT = "swap_workout"
    MODIFY_INTENSITY = "modify_intensity"
    RESCHEDULE = "reschedule"
    REPORT_INJURY = "report_injury"
    DELETE_WORKOUT = "delete_workout"
    QUESTION = "question"
    # Nutrition-related intents
    ANALYZE_FOOD = "analyze_food"
    NUTRITION_SUMMARY = "nutrition_summary"
    RECENT_MEALS = "recent_meals"
    # App control intents
    CHANGE_SETTING = "change_setting"
    NAVIGATE = "navigate"
    # Workout action intents
    START_WORKOUT = "start_workout"
    COMPLETE_WORKOUT = "complete_workout"
    # Quick logging intents
    LOG_HYDRATION = "log_hydration"
    # Quick workout generation intent
    GENERATE_QUICK_WORKOUT = "generate_quick_workout"
    # Holistic planning intents
    GENERATE_WEEKLY_PLAN = "generate_weekly_plan"
    ADJUST_PLAN = "adjust_plan"
    EXPLAIN_PLAN = "explain_plan"


class AISettings(BaseModel):
    """AI personality and behavior settings."""
    # Coach Persona
    coach_persona_id: Optional[str] = Field(default=None, max_length=50)  # e.g., "coach_mike", "coach_sarah", "custom"
    coach_name: Optional[str] = Field(default=None, max_length=100)  # Display name for the coach (e.g., "Coach Mike")

    # Personality & Tone
    coaching_style: str = Field(default="motivational", max_length=50)  # "motivational", "professional", "friendly", "tough-love"
    communication_tone: str = Field(default="encouraging", max_length=50)  # "casual", "encouraging", "formal"
    encouragement_level: float = Field(default=0.7, ge=0.0, le=1.0)  # 0.0 - 1.0

    # Response Preferences
    response_length: str = Field(default="balanced", max_length=50)  # "concise", "balanced", "detailed"
    use_emojis: bool = True
    include_tips: bool = True

    # Fitness Coaching Specifics
    form_reminders: bool = True
    rest_day_suggestions: bool = True
    nutrition_mentions: bool = True
    injury_sensitivity: bool = True

    # Frontend-only fields (accepted but not used by backend agents directly)
    is_custom_coach: bool = False
    show_ai_coach_during_workouts: bool = True
    save_chat_history: bool = True
    use_rag: bool = True
    default_agent: Optional[str] = Field(default=None, max_length=50)
    enabled_agents: Optional[Dict[str, bool]] = None


class UserProfile(BaseModel):
    """User profile for context in chat."""
    id: str = Field(..., max_length=100)  # UUID from Supabase
    fitness_level: str = Field(default="beginner", max_length=50)
    goals: List[str] = Field(default=[], max_length=20)
    equipment: List[str] = Field(default=[], max_length=50)
    active_injuries: List[str] = Field(default=[], max_length=20)
    name: Optional[str] = Field(default=None, max_length=200)


class WorkoutContext(BaseModel):
    """Current workout context."""
    id: int
    name: str = Field(..., max_length=200)
    type: str = Field(..., max_length=50)
    difficulty: str = Field(..., max_length=50)
    exercises: List[Dict[str, Any]] = Field(default=[], max_length=50)
    scheduled_date: Optional[str] = Field(default=None, max_length=20)
    is_completed: bool = False


class WorkoutScheduleContext(BaseModel):
    """Workout schedule context for AI to understand temporal context."""
    yesterday: Optional[WorkoutContext] = None
    today: Optional[WorkoutContext] = None
    tomorrow: Optional[WorkoutContext] = None
    thisWeek: List[WorkoutContext] = []
    recentCompleted: List[WorkoutContext] = []


class ChatRequest(BaseModel):
    """
    Request body for chat endpoint.

    Example:
        {
            "message": "add barbell rows to my workout",
            "user_id": 1,
            "user_profile": {...},
            "current_workout": {...},
            "workout_schedule": {...},
            "conversation_history": [...],
            "image_base64": null,
            "ai_settings": {...}
        }
    """
    message: str = Field(..., min_length=1, max_length=5000, description="User's message (max 5000 characters)")
    user_id: str = Field(..., max_length=100, description="User ID (UUID from Supabase)")
    user_profile: Optional[UserProfile] = None
    current_workout: Optional[WorkoutContext] = None
    workout_schedule: Optional[WorkoutScheduleContext] = Field(
        default=None,
        description="Workout schedule context (yesterday, today, tomorrow, thisWeek, recentCompleted)"
    )
    conversation_history: List[Dict[str, Any]] = Field(
        default=[],
        max_length=100,
        description="Previous messages in format [{'role': 'user'/'assistant', 'content': '...'}] (max 100 messages)"
    )

    @field_validator("conversation_history")
    @classmethod
    def validate_conversation_history(cls, v):
        """Validate each message has a valid role and bounded content length."""
        valid_roles = {"user", "assistant"}
        for msg in v:
            role = msg.get("role")
            if role not in valid_roles:
                raise ValueError(f"Invalid conversation_history role: {role!r} (must be 'user' or 'assistant')")
            content = msg.get("content", "")
            if isinstance(content, str) and len(content) > 5000:
                raise ValueError("conversation_history message content too long (max 5000 chars)")
        return v
    image_base64: Optional[str] = Field(
        default=None,
        max_length=17_800_000,
        description="Base64 encoded image for food analysis (max ~10MB decoded, ~13.3MB base64)"
    )
    ai_settings: Optional[AISettings] = Field(
        default=None,
        description="AI personality and behavior settings"
    )
    unified_context: Optional[str] = Field(
        default=None,
        max_length=50000,
        description="Unified fasting/nutrition/workout context string"
    )


class IntentExtraction(BaseModel):
    """Extracted intent and entities from user message."""
    intent: CoachIntent
    exercises: List[str] = Field(default=[], max_length=20)
    muscle_groups: List[str] = Field(default=[], max_length=20)
    modification: Optional[str] = Field(default=None, max_length=200)
    body_part: Optional[str] = Field(default=None, max_length=100)
    # App settings fields
    setting_name: Optional[str] = Field(default=None, max_length=100)
    setting_value: Optional[bool] = None
    # Navigation fields
    destination: Optional[str] = Field(default=None, max_length=100)
    # Hydration logging fields
    hydration_amount: Optional[int] = Field(default=None, ge=0, le=100)  # Number of glasses/cups


class ChatResponse(BaseModel):
    """
    Response from chat endpoint.

    Example:
        {
            "message": "I've added Barbell Row to your workout!",
            "intent": "add_exercise",
            "agent_type": "workout",
            "action_data": {"exercise_id": "barbell_row", ...},
            "rag_context_used": true
        }
    """
    message: str = Field(..., description="AI coach response")
    intent: CoachIntent = Field(..., description="Detected intent")
    agent_type: AgentType = Field(
        default=AgentType.COACH,
        description="Which specialized agent responded"
    )
    action_data: Optional[Dict[str, Any]] = Field(
        None,
        description="Data for workout modifications"
    )
    rag_context_used: bool = Field(
        False,
        description="Whether RAG context was used"
    )
    similar_questions: List[str] = Field(
        default=[],
        description="Similar past questions found via RAG"
    )


class ChatMessage(BaseModel):
    """Stored chat message."""
    id: Optional[int] = None
    user_id: str = Field(..., max_length=100)  # UUID from Supabase
    user_message: str = Field(..., max_length=5000)
    ai_response: str = Field(..., max_length=20000)
    intent: str = Field(..., max_length=50)
    context_json: Optional[str] = Field(default=None, max_length=50000)
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class RAGDocument(BaseModel):
    """Document stored in RAG system."""
    id: str = Field(..., max_length=100)
    question: str = Field(..., max_length=5000)
    answer: str = Field(..., max_length=20000)
    intent: str = Field(..., max_length=50)
    user_id: str = Field(..., max_length=100)  # UUID from Supabase
    metadata: Dict[str, Any] = {}
    embedding: Optional[List[float]] = None
