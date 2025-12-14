"""
LangGraph graph assembly for the Coach Agent.
"""
from langgraph.graph import StateGraph, START, END

from .state import CoachAgentState
from .nodes import (
    should_handle_action,
    coach_action_node,
    coach_response_node,
)
from core.logger import get_logger

logger = get_logger(__name__)


def build_coach_agent_graph():
    """
    Build and compile the coach agent graph.

    FLOW:
        START
          |
        should_handle_action (router)
          |--- action (settings/navigation)
          |      |
          |    END
          |
          |--- respond (general coaching)
                 |
               END

    The coach agent is the general-purpose agent that handles:
    - Greetings and small talk
    - General fitness questions
    - App settings and navigation
    - Motivation and encouragement
    """
    logger.info("Building coach agent graph...")

    graph = StateGraph(CoachAgentState)

    # Add nodes
    graph.add_node("action", coach_action_node)
    graph.add_node("respond", coach_response_node)

    # Router: action or general response?
    graph.add_conditional_edges(
        START,
        should_handle_action,
        {
            "action": "action",
            "respond": "respond",
        }
    )

    # Both nodes go to END
    graph.add_edge("action", END)
    graph.add_edge("respond", END)

    compiled = graph.compile()
    logger.info("Coach agent graph built successfully")

    return compiled
