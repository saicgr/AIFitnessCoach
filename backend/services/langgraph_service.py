"""
LangGraph Coach Service - FastAPI integration wrapper.

This service wraps the LangGraph agent and provides the same interface
as the original CoachService for easy integration.
"""
import re
from typing import Optional, Dict, Any, Tuple
from models.chat import ChatRequest, ChatResponse, CoachIntent, AgentType
from services.langgraph_agents.graph import build_fitness_coach_graph
from services.langgraph_agents.state import FitnessCoachState
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


class LangGraphCoachService:
    """
    LangGraph-based coach service.

    Replaces the original CoachService with graph-based orchestration.
    """

    def __init__(self):
        """Initialize the LangGraph coach service."""
        logger.info("Initializing LangGraph coach service...")
        self.graph = build_fitness_coach_graph()
        logger.info("LangGraph coach service initialized")

    def _detect_agent_mention(self, message: str) -> Tuple[Optional[AgentType], str]:
        """
        Detect @mention in message and extract agent type.

        Args:
            message: The user's message

        Returns:
            Tuple of (agent_type, cleaned_message)
            - agent_type: The detected agent type, or None for default routing
            - cleaned_message: Message with @mention removed
        """
        for pattern, agent_type in AGENT_MENTION_PATTERNS.items():
            match = re.search(pattern, message, re.IGNORECASE)
            if match:
                # Remove the @mention from the message
                cleaned = re.sub(pattern, "", message, flags=re.IGNORECASE).strip()
                logger.info(f"Detected @mention: {agent_type.value}, cleaned message: {cleaned[:50]}...")
                return agent_type, cleaned
        return None, message

    def _infer_agent_from_intent(self, intent: CoachIntent) -> AgentType:
        """
        Infer which agent should respond based on the detected intent.

        Args:
            intent: The detected intent

        Returns:
            The appropriate agent type
        """
        # Map intents to agents
        intent_to_agent = {
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

            # Injury agent
            CoachIntent.REPORT_INJURY: AgentType.INJURY,

            # Hydration agent
            CoachIntent.LOG_HYDRATION: AgentType.HYDRATION,
        }

        return intent_to_agent.get(intent, AgentType.COACH)

    async def process_message(self, request: ChatRequest) -> ChatResponse:
        """
        Process a user message using the LangGraph agent.

        Args:
            request: ChatRequest from the API

        Returns:
            ChatResponse with AI response and action data
        """
        logger.info(f"Processing message with LangGraph: {request.message[:50]}...")

        # Detect @mention for direct agent routing
        mentioned_agent, cleaned_message = self._detect_agent_mention(request.message)

        # Build initial state from request
        initial_state: FitnessCoachState = {
            # Input - use cleaned message (without @mention)
            "user_message": cleaned_message,
            "user_id": request.user_id,
            "user_profile": request.user_profile.model_dump() if request.user_profile else None,
            "current_workout": request.current_workout.model_dump() if request.current_workout else None,
            "workout_schedule": request.workout_schedule.model_dump() if request.workout_schedule else None,
            "conversation_history": request.conversation_history,
            "image_base64": request.image_base64,  # Pass image for food analysis

            # Intent extraction (will be filled by nodes)
            "intent": None,
            "extracted_exercises": [],
            "extracted_muscle_groups": [],
            "modification": None,
            "body_part": None,
            "setting_name": None,
            "setting_value": None,
            "destination": None,
            "hydration_amount": None,

            # RAG context (will be filled by nodes)
            "rag_documents": [],
            "rag_context_formatted": "",

            # Tool execution (will be filled by nodes)
            "tools_to_call": [],
            "tool_results": [],

            # Response generation (will be filled by nodes)
            "ai_response": "",
            "final_response": "",

            # Output (will be filled by nodes)
            "action_data": None,
            "rag_context_used": False,
            "similar_questions": [],

            # Error handling
            "error": None,

            # Routing
            "next_node": None,

            # Agent routing - pass the mentioned agent for context
            "mentioned_agent": mentioned_agent.value if mentioned_agent else None,
        }

        try:
            # Execute the graph
            final_state = await self.graph.ainvoke(initial_state)

            # Extract results
            intent = final_state.get("intent", CoachIntent.QUESTION)
            if isinstance(intent, str):
                intent = CoachIntent(intent)

            # Determine agent type:
            # 1. If user explicitly @mentioned an agent, use that
            # 2. Otherwise, infer from the detected intent
            if mentioned_agent:
                agent_type = mentioned_agent
            else:
                agent_type = self._infer_agent_from_intent(intent)

            response = ChatResponse(
                message=final_state.get("final_response", "I'm sorry, I couldn't process your request."),
                intent=intent,
                agent_type=agent_type,
                action_data=final_state.get("action_data"),
                rag_context_used=final_state.get("rag_context_used", False),
                similar_questions=final_state.get("similar_questions", []),
            )

            logger.info(f"LangGraph response: intent={response.intent.value}, agent={response.agent_type.value}, rag_used={response.rag_context_used}")
            return response

        except Exception as e:
            logger.error(f"LangGraph execution failed: {e}")
            # Return a graceful error response
            return ChatResponse(
                message=f"I'm sorry, I encountered an error processing your request. Please try again.",
                intent=CoachIntent.QUESTION,
                agent_type=mentioned_agent or AgentType.COACH,
                action_data=None,
                rag_context_used=False,
                similar_questions=[],
            )
