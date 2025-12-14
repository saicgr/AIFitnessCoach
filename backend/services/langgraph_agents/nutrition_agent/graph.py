"""
LangGraph graph assembly for the Nutrition Agent.
"""
from langgraph.graph import StateGraph, START, END

from .state import NutritionAgentState
from .nodes import (
    should_use_tools,
    nutrition_agent_node,
    nutrition_tool_executor_node,
    nutrition_response_node,
    nutrition_autonomous_node,
    nutrition_action_data_node,
    check_for_tool_calls,
)
from core.logger import get_logger

logger = get_logger(__name__)


def build_nutrition_agent_graph():
    """
    Build and compile the nutrition agent graph.

    FLOW:
        START
          |
        should_use_tools (router)
          |--- agent (image/data query)
          |      |
          |    check_for_tool_calls
          |      |--- tool_executor -> response
          |      |--- (no tools) -> action_data
          |
          |--- autonomous (general questions)
                 |
             action_data
                 |
               END
    """
    logger.info("Building nutrition agent graph...")

    graph = StateGraph(NutritionAgentState)

    # Add nodes
    graph.add_node("agent", nutrition_agent_node)
    graph.add_node("tool_executor", nutrition_tool_executor_node)
    graph.add_node("response", nutrition_response_node)
    graph.add_node("autonomous", nutrition_autonomous_node)
    graph.add_node("action_data", nutrition_action_data_node)

    # Router: should we use tools or respond autonomously?
    graph.add_conditional_edges(
        START,
        should_use_tools,
        {
            "agent": "agent",
            "respond": "autonomous",
        }
    )

    # After agent, check if tools were called
    graph.add_conditional_edges(
        "agent",
        check_for_tool_calls,
        {
            "execute_tools": "tool_executor",
            "finalize": "action_data",
        }
    )

    # Tool executor -> response -> action_data
    graph.add_edge("tool_executor", "response")
    graph.add_edge("response", "action_data")

    # Autonomous -> action_data
    graph.add_edge("autonomous", "action_data")

    # Action data -> END
    graph.add_edge("action_data", END)

    compiled = graph.compile()
    logger.info("Nutrition agent graph built successfully")

    return compiled
