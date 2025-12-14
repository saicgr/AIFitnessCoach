"""
LangGraph graph assembly for the Hydration Agent.
"""
from langgraph.graph import StateGraph, START, END

from .state import HydrationAgentState
from .nodes import (
    should_log_hydration,
    hydration_log_node,
    hydration_advice_node,
)
from core.logger import get_logger

logger = get_logger(__name__)


def build_hydration_agent_graph():
    """
    Build and compile the hydration agent graph.

    FLOW:
        START
          |
        should_log_hydration (router)
          |--- log (user drank water)
          |      |
          |    END
          |
          |--- respond (hydration questions)
                 |
               END

    Note: The hydration agent is simpler than others because
    it doesn't have database tools - logging is done via action_data.
    """
    logger.info("Building hydration agent graph...")

    graph = StateGraph(HydrationAgentState)

    # Add nodes
    graph.add_node("log", hydration_log_node)
    graph.add_node("advice", hydration_advice_node)

    # Router: log or provide advice?
    graph.add_conditional_edges(
        START,
        should_log_hydration,
        {
            "log": "log",
            "respond": "advice",
        }
    )

    # Both nodes go to END
    graph.add_edge("log", END)
    graph.add_edge("advice", END)

    compiled = graph.compile()
    logger.info("Hydration agent graph built successfully")

    return compiled
