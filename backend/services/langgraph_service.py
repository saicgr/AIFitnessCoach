"""
LangGraph Coach Service - FastAPI integration wrapper.

This service wraps the LangGraph agent and provides the same interface
as the original CoachService for easy integration.
"""
from typing import Optional, Dict, Any
from models.chat import ChatRequest, ChatResponse, CoachIntent
from services.langgraph_agents.graph import build_fitness_coach_graph
from services.langgraph_agents.state import FitnessCoachState
from core.logger import get_logger

logger = get_logger(__name__)


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

    async def process_message(self, request: ChatRequest) -> ChatResponse:
        """
        Process a user message using the LangGraph agent.

        Args:
            request: ChatRequest from the API

        Returns:
            ChatResponse with AI response and action data
        """
        logger.info(f"Processing message with LangGraph: {request.message[:50]}...")

        # Build initial state from request
        initial_state: FitnessCoachState = {
            # Input
            "user_message": request.message,
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
        }

        try:
            # Execute the graph
            final_state = await self.graph.ainvoke(initial_state)

            # Extract results
            intent = final_state.get("intent", CoachIntent.QUESTION)
            if isinstance(intent, str):
                intent = CoachIntent(intent)

            response = ChatResponse(
                message=final_state.get("final_response", "I'm sorry, I couldn't process your request."),
                intent=intent,
                action_data=final_state.get("action_data"),
                rag_context_used=final_state.get("rag_context_used", False),
                similar_questions=final_state.get("similar_questions", []),
            )

            logger.info(f"LangGraph response: intent={response.intent.value}, rag_used={response.rag_context_used}")
            return response

        except Exception as e:
            logger.error(f"LangGraph execution failed: {e}")
            # Return a graceful error response
            return ChatResponse(
                message=f"I'm sorry, I encountered an error processing your request. Please try again.",
                intent=CoachIntent.QUESTION,
                action_data=None,
                rag_context_used=False,
                similar_questions=[],
            )
