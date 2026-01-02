"""
LangGraph Coach Service - FastAPI integration wrapper with dedicated domain agents.

This service routes messages to specialized domain agents:
- Nutrition Agent: Food analysis, dietary advice
- Workout Agent: Exercise modifications, workout guidance
- Injury Agent: Injury tracking, recovery advice
- Hydration Agent: Water intake tracking, hydration tips
- Coach Agent: General fitness coaching, app navigation
"""
import re
from typing import Optional, Dict, Any, Tuple

from models.chat import ChatRequest, ChatResponse, CoachIntent, AgentType
from services.gemini_service import GeminiService
from services.rag_service import RAGService

# Import all domain agents
from services.langgraph_agents.nutrition_agent import build_nutrition_agent_graph
from services.langgraph_agents.workout_agent import build_workout_agent_graph
from services.langgraph_agents.injury_agent import build_injury_agent_graph
from services.langgraph_agents.hydration_agent import build_hydration_agent_graph
from services.langgraph_agents.coach_agent import build_coach_agent_graph

from core.logger import get_logger

logger = get_logger(__name__)

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
        """Get RAG context for the message."""
        try:
            rag_service = RAGService(gemini_service=self.gemini_service)
            similar_docs = await rag_service.find_similar(
                query=message,
                user_id=user_id,
                n_results=3
            )
            formatted = rag_service.format_context(similar_docs)
            similar_questions = [
                doc.get("metadata", {}).get("question", "")
                for doc in similar_docs[:3]
            ]
            return formatted, len(similar_docs) > 0, similar_questions
        except Exception as e:
            logger.warning(f"RAG context retrieval failed: {e}")
            return "", False, []

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

    async def process_message(self, request: ChatRequest) -> ChatResponse:
        """
        Process a user message using dedicated domain agents.

        Flow:
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

            # 6. Execute agent
            agent_graph = self.agents[selected_agent]
            final_state = await agent_graph.ainvoke(agent_state)

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
            return ChatResponse(
                message="I'm sorry, I encountered an error processing your request. Please try again.",
                intent=CoachIntent.QUESTION,
                agent_type=mentioned_agent or AgentType.COACH,
                action_data=None,
                rag_context_used=False,
                similar_questions=[],
            )
