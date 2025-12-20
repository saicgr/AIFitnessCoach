"""
LangGraph-based onboarding service.

Replaces the hardcoded question system with AI-driven conversations.
"""
from typing import Dict, Any, List, Optional
from .langgraph_agents.graph import build_onboarding_agent_graph
from .langgraph_agents.onboarding import OnboardingState
from core.logger import get_logger

logger = get_logger(__name__)


class LangGraphOnboardingService:
    """
    Service for conducting AI-driven onboarding using LangGraph.

    No hardcoded questions - the AI decides what to ask based on context!
    """

    def __init__(self):
        """Initialize the onboarding service with the LangGraph agent."""
        logger.info("Initializing LangGraph onboarding service...")
        self.graph = build_onboarding_agent_graph()
        logger.info("LangGraph onboarding service initialized")

    async def process_message(
        self,
        user_id: str,
        message: str,
        collected_data: Dict[str, Any],
        conversation_history: List[Dict[str, str]],
    ) -> Dict[str, Any]:
        """
        Process a user message in the onboarding conversation.

        Args:
            user_id: User ID
            message: User's message
            collected_data: Data collected so far
            conversation_history: Previous messages

        Returns:
            Dict with:
                - next_question: AI-generated question
                - extracted_data: New data extracted from message
                - is_complete: Whether onboarding is finished
                - quick_replies: Optional quick reply buttons
                - component: Optional UI component (day_picker, etc.)
        """
        logger.info("=" * 80)
        logger.info(f"[LangGraph Onboarding] 🚀 PROCESSING MESSAGE")
        logger.info(f"[LangGraph Onboarding] User ID: {user_id}")
        logger.info(f"[LangGraph Onboarding] User message: {message}")
        logger.info(f"[LangGraph Onboarding] Collected data keys: {list(collected_data.keys())}")
        logger.info(f"[LangGraph Onboarding] Conversation history length: {len(conversation_history)}")
        logger.info("=" * 80)

        # Build initial state
        initial_state: OnboardingState = {
            "user_message": message,
            "user_id": user_id,
            "conversation_history": conversation_history,
            "collected_data": collected_data,
            "messages": [],
            "next_question": None,
            "missing_fields": [],
            "validation_errors": {},
            "is_complete": False,
            "final_response": "",
            "error": None,
            "component": None,
            "quick_replies": None,
            "multi_select": False,
        }

        try:
            # Run the graph
            import time
            start_time = time.time()
            logger.info("[LangGraph Onboarding] ⏳ Invoking graph...")
            result = await self.graph.ainvoke(initial_state)
            elapsed = time.time() - start_time

            logger.info("=" * 80)
            logger.info(f"[LangGraph Onboarding] ✅ GRAPH COMPLETED in {elapsed:.2f}s")
            logger.info(f"[LangGraph Onboarding] Is complete: {result.get('is_complete')}")
            logger.info(f"[LangGraph Onboarding] Missing fields: {result.get('missing_fields')}")
            logger.info(f"[LangGraph Onboarding] Quick replies: {result.get('quick_replies') is not None}")
            logger.info(f"[LangGraph Onboarding] Component: {result.get('component')}")
            logger.info(f"[LangGraph Onboarding] AI Response: {result.get('final_response', '')[:200]}...")
            logger.info("=" * 80)

            # Extract response data
            response = {
                "next_question": {
                    "question": result.get("final_response", ""),
                    "quick_replies": result.get("quick_replies"),
                    "multi_select": result.get("multi_select", False),
                    "component": result.get("component"),
                },
                "extracted_data": result.get("collected_data", {}),
                "is_complete": result.get("is_complete", False),
                "missing_fields": result.get("missing_fields", []),
            }

            logger.info(f"[LangGraph Onboarding] Response: {response}")

            return response

        except Exception as e:
            logger.error(f"[LangGraph Onboarding] Error: {e}", exc_info=True)
            raise

    async def validate_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate collected onboarding data.

        Args:
            data: Collected onboarding data

        Returns:
            Dict with validation results
        """
        errors = {}
        warnings = []

        # Validate required fields
        required_fields = [
            "name",
            "goals",
            "equipment",
            "days_per_week",
            "selected_days",
            "workout_duration",
            "fitness_level",
            "age",
            "gender",
            "heightCm",
            "weightKg",
        ]

        missing = []
        for field in required_fields:
            if field not in data or not data[field]:
                missing.append(field)

        if missing:
            errors["missing_fields"] = missing

        # Validate data types and ranges
        if "age" in data:
            age = data["age"]
            if not isinstance(age, (int, float)) or age < 13 or age > 100:
                errors["age"] = "Age must be between 13 and 100"

        if "days_per_week" in data:
            days = data["days_per_week"]
            if not isinstance(days, (int, float)) or days < 1 or days > 7:
                errors["days_per_week"] = "Days per week must be between 1 and 7"

        if "workout_duration" in data:
            duration = data["workout_duration"]
            if not isinstance(duration, (int, float)) or duration < 15 or duration > 180:
                errors["workout_duration"] = "Workout duration must be between 15 and 180 minutes"

        if "heightCm" in data:
            height = data["heightCm"]
            if not isinstance(height, (int, float)) or height < 100 or height > 250:
                errors["heightCm"] = "Height must be between 100 and 250 cm"

        if "weightKg" in data:
            weight = data["weightKg"]
            if not isinstance(weight, (int, float)) or weight < 30 or weight > 300:
                errors["weightKg"] = "Weight must be between 30 and 300 kg"

        return {
            "is_valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
        }
