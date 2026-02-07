"""
LangGraph Coach Service - FastAPI integration wrapper with dedicated domain agents.

This service routes messages to specialized domain agents:
- Nutrition Agent: Food analysis, dietary advice
- Workout Agent: Exercise modifications, workout guidance
- Injury Agent: Injury tracking, recovery advice
- Hydration Agent: Water intake tracking, hydration tips
- Coach Agent: General fitness coaching, app navigation

Performance: Simple messages (greetings, thanks, goodbye) are handled via
a fast-path that skips intent extraction, RAG lookup, and agent execution.
"""
import re
import time
from typing import Optional, Dict, Any, Tuple

from models.chat import ChatRequest, ChatResponse, CoachIntent, AgentType
from services.gemini_service import GeminiService
from services.rag_service import RAGService, WorkoutRAGService

# Import all domain agents
from services.langgraph_agents.nutrition_agent import build_nutrition_agent_graph
from services.langgraph_agents.workout_agent import build_workout_agent_graph
from services.langgraph_agents.injury_agent import build_injury_agent_graph
from services.langgraph_agents.hydration_agent import build_hydration_agent_graph
from services.langgraph_agents.coach_agent import build_coach_agent_graph

from core.logger import get_logger

logger = get_logger(__name__)

# ──────────────────────────────────────────────
# Fast-path: Simple message detection & responses
# ──────────────────────────────────────────────
# Patterns that indicate a simple message that doesn't need the full LangGraph pipeline.
# These are checked BEFORE the expensive Gemini intent extraction call (~2s).

_GREETING_PATTERNS = re.compile(
    r"^(hi|hey|hello|howdy|yo|sup|what'?s up|hiya|good\s*(morning|afternoon|evening|night)|heya|greetings)[!?.]*$",
    re.IGNORECASE,
)

_THANKS_PATTERNS = re.compile(
    r"^(thanks?|thank\s*you|thx|ty|appreciate\s*it|cheers|much\s*appreciated)[!?.]*$",
    re.IGNORECASE,
)

_GOODBYE_PATTERNS = re.compile(
    r"^(bye|goodbye|see\s*ya|later|cya|peace|gotta\s*go|talk\s*later|ttyl|take\s*care)[!?.]*$",
    re.IGNORECASE,
)

_OK_PATTERNS = re.compile(
    r"^(ok|okay|k|got\s*it|sure|alright|sounds\s*good|cool|nice|great|awesome|perfect|yep|yup|yes|no|nah|nope)[!?.]*$",
    re.IGNORECASE,
)

# Map of simple intent -> (response, CoachIntent)
# Responses are kept short and energetic to match the fitness coaching persona.
SIMPLE_INTENT_MAP = {
    "greeting": (
        "Hey! Ready to crush your workout? What can I help with today?",
        CoachIntent.QUESTION,
    ),
    "thanks": (
        "You're welcome! Let me know if you need anything else. Keep pushing!",
        CoachIntent.QUESTION,
    ),
    "goodbye": (
        "See you next time! Keep up the great work and stay consistent!",
        CoachIntent.QUESTION,
    ),
    "acknowledgment": (
        "Got it! Let me know if there's anything else I can help with.",
        CoachIntent.QUESTION,
    ),
}

# @mention patterns for direct agent routing
AGENT_MENTION_PATTERNS = {
    r"@nutrition\b": AgentType.NUTRITION,
    r"@workout\b": AgentType.WORKOUT,
    r"@injury\b": AgentType.INJURY,
    r"@hydration\b": AgentType.HYDRATION,
    r"@coach\b": AgentType.COACH,
}

# Intent to agent mapping
INTENT_TO_AGENT = {
    # Nutrition agent
    CoachIntent.ANALYZE_FOOD: AgentType.NUTRITION,
    CoachIntent.NUTRITION_SUMMARY: AgentType.NUTRITION,
    CoachIntent.RECENT_MEALS: AgentType.NUTRITION,

    # Workout agent
    CoachIntent.ADD_EXERCISE: AgentType.WORKOUT,
    CoachIntent.REMOVE_EXERCISE: AgentType.WORKOUT,
    CoachIntent.SWAP_WORKOUT: AgentType.WORKOUT,
    CoachIntent.MODIFY_INTENSITY: AgentType.WORKOUT,
    CoachIntent.RESCHEDULE: AgentType.WORKOUT,
    CoachIntent.DELETE_WORKOUT: AgentType.WORKOUT,
    CoachIntent.START_WORKOUT: AgentType.WORKOUT,
    CoachIntent.COMPLETE_WORKOUT: AgentType.WORKOUT,
    CoachIntent.GENERATE_QUICK_WORKOUT: AgentType.WORKOUT,

    # Injury agent
    CoachIntent.REPORT_INJURY: AgentType.INJURY,

    # Hydration agent
    CoachIntent.LOG_HYDRATION: AgentType.HYDRATION,

    # Coach agent (default for these)
    CoachIntent.QUESTION: AgentType.COACH,
    CoachIntent.CHANGE_SETTING: AgentType.COACH,
    CoachIntent.NAVIGATE: AgentType.COACH,
}

# Keyword-based routing for message analysis
DOMAIN_KEYWORDS = {
    AgentType.NUTRITION: [
        "food", "eat", "ate", "meal", "calories", "protein", "carbs", "fat",
        "nutrition", "diet", "macros", "breakfast", "lunch", "dinner", "snack",
        "hungry", "recipe", "cooking", "what should i eat"
    ],
    AgentType.WORKOUT: [
        "exercise", "workout", "training", "gym", "lift", "squat", "bench",
        "deadlift", "muscle", "strength", "cardio", "hiit", "sets", "reps",
        "form", "technique", "how do i do", "quick", "create workout",
        "generate workout", "make workout", "give me a workout", "new workout",
        "short workout"
    ],
    AgentType.INJURY: [
        "hurt", "pain", "injury", "injured", "sore", "strain", "sprain",
        "recovery", "rehab", "heal", "prevent", "ice", "rest"
    ],
    AgentType.HYDRATION: [
        "water", "hydration", "hydrate", "drink", "thirsty", "dehydrated",
        "glasses", "cups", "fluid"
    ],
}


class LangGraphCoachService:
    """
    LangGraph-based coach service with dedicated domain agents.

    Routes messages to specialized agents based on:
    1. @mentions (explicit routing)
    2. Intent detection (from message analysis)
    3. Keyword matching (fallback)
    """

    def __init__(self):
        """Initialize all domain agents."""
        logger.info("Initializing LangGraph coach service with dedicated agents...")

        # Build all agent graphs
        self.agents = {
            AgentType.NUTRITION: build_nutrition_agent_graph(),
            AgentType.WORKOUT: build_workout_agent_graph(),
            AgentType.INJURY: build_injury_agent_graph(),
            AgentType.HYDRATION: build_hydration_agent_graph(),
            AgentType.COACH: build_coach_agent_graph(),
        }

        # Initialize services for intent extraction
        self.gemini_service = GeminiService()

        logger.info("All domain agents initialized successfully")

    def _detect_agent_mention(self, message: str) -> Tuple[Optional[AgentType], str]:
        """
        Detect @mention in message and extract agent type.

        Args:
            message: The user's message

        Returns:
            Tuple of (agent_type, cleaned_message)
        """
        for pattern, agent_type in AGENT_MENTION_PATTERNS.items():
            match = re.search(pattern, message, re.IGNORECASE)
            if match:
                cleaned = re.sub(pattern, "", message, flags=re.IGNORECASE).strip()
                logger.info(f"Detected @mention: {agent_type.value}, cleaned message: {cleaned[:50]}...")
                return agent_type, cleaned
        return None, message

    def _infer_agent_from_intent(self, intent: CoachIntent) -> AgentType:
        """Infer which agent should handle based on intent."""
        return INTENT_TO_AGENT.get(intent, AgentType.COACH)

    def _infer_agent_from_keywords(self, message: str) -> Optional[AgentType]:
        """
        Fallback: Infer agent from keywords in message.

        Returns None if no clear match (will default to coach).
        Uses word boundary matching to avoid false positives like "ate" in "generate".
        """
        import re
        message_lower = message.lower()

        keyword_counts = {}
        for agent_type, keywords in DOMAIN_KEYWORDS.items():
            # Use word boundary matching to avoid partial matches
            count = sum(1 for kw in keywords if re.search(r'\b' + re.escape(kw) + r'\b', message_lower))
            if count > 0:
                keyword_counts[agent_type] = count

        if keyword_counts:
            best_match = max(keyword_counts, key=keyword_counts.get)
            logger.info(f"Keyword match: {best_match.value} (score: {keyword_counts[best_match]})")
            return best_match

        return None

    async def _extract_intent(self, message: str) -> Tuple[CoachIntent, Dict[str, Any]]:
        """
        Extract intent and entities from user message.

        Returns:
            Tuple of (intent, extraction_data)
        """
        extraction = await self.gemini_service.extract_intent(message)
        return extraction.intent, {
            "exercises": extraction.exercises,
            "muscle_groups": extraction.muscle_groups,
            "modification": extraction.modification,
            "body_part": extraction.body_part,
            "setting_name": extraction.setting_name,
            "setting_value": extraction.setting_value,
            "destination": extraction.destination,
            "hydration_amount": extraction.hydration_amount,
        }

    async def _get_rag_context(self, message: str, user_id: str) -> Tuple[str, bool, list]:
        """Get RAG context for the message, including training settings."""
        context_parts = []
        rag_used = False
        similar_questions = []

        # 1. Get Q&A context (existing behavior)
        try:
            rag_service = RAGService(gemini_service=self.gemini_service)
            similar_docs = await rag_service.find_similar(
                query=message,
                user_id=user_id,
                n_results=3
            )
            formatted = rag_service.format_context(similar_docs)
            if formatted:
                context_parts.append(formatted)
                rag_used = True
            similar_questions = [
                doc.get("metadata", {}).get("question", "")
                for doc in similar_docs[:3]
            ]
        except Exception as e:
            logger.warning(f"Q&A RAG context retrieval failed: {e}")

        # 2. Get training settings context (1RMs, intensity, etc.)
        try:
            workout_rag = WorkoutRAGService(self.gemini_service)
            training_settings = workout_rag.get_recent_training_settings(
                user_id=user_id,
                days_lookback=30,
                max_results=10
            )
            if training_settings.get("has_settings") and training_settings.get("context_text"):
                # Add training settings as a separate context section
                settings_context = f"\n--- User's Training Settings ---\n{training_settings['context_text']}"
                context_parts.append(settings_context)
                rag_used = True
                logger.info(f"📊 Added training settings to RAG context for user {user_id}")
        except Exception as e:
            logger.warning(f"Training settings RAG retrieval failed: {e}")

        # Combine all context parts
        combined_context = "\n\n".join(context_parts)
        return combined_context, rag_used, similar_questions

    def _select_agent(
        self,
        mentioned_agent: Optional[AgentType],
        intent: CoachIntent,
        message: str,
        has_image: bool
    ) -> AgentType:
        """
        Select the appropriate agent based on all available signals.

        Priority:
        1. Explicit @mention
        2. Image present -> Nutrition (for food analysis)
        3. Intent-based routing
        4. Keyword-based routing
        5. Default to Coach
        """
        # 1. Explicit @mention takes priority
        if mentioned_agent:
            logger.info(f"Agent selection: @mention -> {mentioned_agent.value}")
            return mentioned_agent

        # 2. Image present -> Nutrition agent
        if has_image:
            logger.info("Agent selection: image present -> nutrition")
            return AgentType.NUTRITION

        # 3. Intent-based routing
        agent_from_intent = self._infer_agent_from_intent(intent)
        if agent_from_intent != AgentType.COACH:
            logger.info(f"Agent selection: intent {intent.value} -> {agent_from_intent.value}")
            return agent_from_intent

        # 4. Keyword-based routing
        agent_from_keywords = self._infer_agent_from_keywords(message)
        if agent_from_keywords:
            logger.info(f"Agent selection: keywords -> {agent_from_keywords.value}")
            return agent_from_keywords

        # 5. Default to Coach
        logger.info("Agent selection: default -> coach")
        return AgentType.COACH

    def _build_agent_state(
        self,
        agent_type: AgentType,
        request: ChatRequest,
        cleaned_message: str,
        intent: CoachIntent,
        extraction_data: Dict[str, Any],
        rag_context: str,
        rag_used: bool,
        similar_questions: list
    ) -> Dict[str, Any]:
        """Build the state dictionary for the selected agent."""
        base_state = {
            "user_message": cleaned_message,
            "user_id": request.user_id,
            "user_profile": request.user_profile.model_dump() if request.user_profile else None,
            "conversation_history": request.conversation_history,
            "intent": intent,
            "rag_documents": [],
            "rag_context_formatted": rag_context,
            "ai_response": "",
            "final_response": "",
            "action_data": None,
            "rag_context_used": rag_used,
            "similar_questions": similar_questions,
            "error": None,
            # AI personality settings
            "ai_settings": request.ai_settings.model_dump() if request.ai_settings else None,
        }

        # Add agent-specific fields
        if agent_type == AgentType.NUTRITION:
            base_state["image_base64"] = request.image_base64
            base_state["tool_calls"] = []
            base_state["tool_results"] = []
            base_state["tool_messages"] = []
            base_state["messages"] = []

        elif agent_type == AgentType.WORKOUT:
            base_state["current_workout"] = request.current_workout.model_dump() if request.current_workout else None
            base_state["workout_schedule"] = request.workout_schedule.model_dump() if request.workout_schedule else None
            base_state["extracted_exercises"] = extraction_data.get("exercises", [])
            base_state["extracted_muscle_groups"] = extraction_data.get("muscle_groups", [])
            base_state["modification"] = extraction_data.get("modification")
            base_state["tool_calls"] = []
            base_state["tool_results"] = []
            base_state["tool_messages"] = []
            base_state["messages"] = []

        elif agent_type == AgentType.INJURY:
            base_state["body_part"] = extraction_data.get("body_part")
            base_state["tool_calls"] = []
            base_state["tool_results"] = []
            base_state["tool_messages"] = []
            base_state["messages"] = []

        elif agent_type == AgentType.HYDRATION:
            base_state["hydration_amount"] = extraction_data.get("hydration_amount")

        elif agent_type == AgentType.COACH:
            base_state["current_workout"] = request.current_workout.model_dump() if request.current_workout else None
            base_state["workout_schedule"] = request.workout_schedule.model_dump() if request.workout_schedule else None
            base_state["setting_name"] = extraction_data.get("setting_name")
            base_state["setting_value"] = extraction_data.get("setting_value")
            base_state["destination"] = extraction_data.get("destination")

        return base_state

    @staticmethod
    def _quick_intent_check(message: str) -> Optional[str]:
        """
        Fast local check for simple messages that don't need the full pipeline.

        Returns a simple intent key (e.g., "greeting", "thanks") if the message
        is trivial, or None if it requires full processing.

        This avoids a ~2s Gemini API call for intent extraction on simple messages.
        """
        stripped = message.strip()

        # Only consider short messages (< 30 chars) to avoid false positives
        if len(stripped) > 30:
            return None

        if _GREETING_PATTERNS.match(stripped):
            return "greeting"
        if _THANKS_PATTERNS.match(stripped):
            return "thanks"
        if _GOODBYE_PATTERNS.match(stripped):
            return "goodbye"
        if _OK_PATTERNS.match(stripped):
            return "acknowledgment"

        return None

    async def process_message(self, request: ChatRequest) -> ChatResponse:
        """
        Process a user message using dedicated domain agents.

        Flow:
        0. Fast-path for simple messages (greetings, thanks, goodbye)
        1. Detect @mention
        2. Extract intent
        3. Get RAG context
        4. Select appropriate agent
        5. Build agent state
        6. Execute agent
        7. Return response
        """
        logger.info(f"Processing message: {request.message[:50]}...")

        try:
            # 0. Fast-path: check if this is a simple message that doesn't need full pipeline
            # Skip fast-path if there's an image (needs nutrition agent) or @mention
            if not request.image_base64:
                simple_intent = self._quick_intent_check(request.message)
                if simple_intent and simple_intent in SIMPLE_INTENT_MAP:
                    response_text, intent = SIMPLE_INTENT_MAP[simple_intent]
                    logger.info(f"Fast-path handled simple message: '{request.message[:30]}' -> {simple_intent}")
                    return ChatResponse(
                        message=response_text,
                        intent=intent,
                        agent_type=AgentType.COACH,
                        action_data=None,
                        rag_context_used=False,
                        similar_questions=[],
                    )

            # 1. Detect @mention
            mentioned_agent, cleaned_message = self._detect_agent_mention(request.message)

            # 2. Extract intent
            intent, extraction_data = await self._extract_intent(cleaned_message)
            logger.info(f"Extracted intent: {intent.value}")

            # 3. Get RAG context
            rag_context, rag_used, similar_questions = await self._get_rag_context(
                cleaned_message, request.user_id
            )

            # 4. Select agent
            has_image = request.image_base64 is not None
            selected_agent = self._select_agent(
                mentioned_agent, intent, cleaned_message, has_image
            )
            logger.info(f"Selected agent: {selected_agent.value}")

            # 5. Build agent state
            agent_state = self._build_agent_state(
                selected_agent,
                request,
                cleaned_message,
                intent,
                extraction_data,
                rag_context,
                rag_used,
                similar_questions
            )

            # 6. Execute agent with retry for thought_signature errors
            agent_graph = self.agents[selected_agent]
            start_time = time.time()
            try:
                final_state = await agent_graph.ainvoke(agent_state)
            except Exception as agent_error:
                error_msg = str(agent_error).lower()
                if "thought_signature" in error_msg or "function call is missing" in error_msg:
                    logger.warning(f"Thought signature error with {selected_agent.value} agent, retrying with fresh state...")
                    # Clear any cached message state and retry once
                    if "messages" in agent_state:
                        agent_state["messages"] = []
                    try:
                        final_state = await agent_graph.ainvoke(agent_state)
                    except Exception as retry_error:
                        logger.error(f"Retry also failed: {retry_error}")
                        # Fall back to a text-only response
                        elapsed = time.time() - start_time
                        logger.info(f"Agent {selected_agent.value} failed after retry in {elapsed:.1f}s")
                        return ChatResponse(
                            message="I had trouble processing that request. Could you try rephrasing your message?",
                            intent=intent,
                            agent_type=selected_agent,
                            action_data=None,
                            rag_context_used=rag_used,
                            similar_questions=similar_questions,
                        )
                else:
                    raise
            elapsed = time.time() - start_time
            logger.info(f"Agent {selected_agent.value} completed in {elapsed:.1f}s")

            # 7. Build response
            action_data = final_state.get("action_data")
            logger.info(f"[LangGraph Service] Agent returned action_data: {action_data}")

            response = ChatResponse(
                message=final_state.get("final_response", "I'm sorry, I couldn't process your request."),
                intent=intent,
                agent_type=selected_agent,
                action_data=action_data,
                rag_context_used=final_state.get("rag_context_used", rag_used),
                similar_questions=final_state.get("similar_questions", similar_questions),
            )

            logger.info(f"Response: intent={intent.value}, agent={selected_agent.value}, action_data={action_data is not None}")
            return response

        except Exception as e:
            logger.error(f"Agent execution failed: {e}", exc_info=True)
            # Provide specific error messages based on error type
            error_message = "I'm sorry, I encountered an error processing your request. Please try again."
            error_str = str(e).lower()
            if "thought_signature" in error_str or "function call is missing" in error_str:
                error_message = "I had a temporary issue with my tools. Please try your request again."
            elif "timeout" in error_str or "deadline" in error_str:
                error_message = "The request took too long. Please try a simpler request or try again in a moment."
            elif "quota" in error_str or "rate" in error_str:
                error_message = "I'm receiving too many requests right now. Please wait a moment and try again."

            return ChatResponse(
                message=error_message,
                intent=CoachIntent.QUESTION,
                agent_type=mentioned_agent or AgentType.COACH,
                action_data=None,
                rag_context_used=False,
                similar_questions=[],
            )
