"""
LangGraph graph assembly for the Injury Agent.
"""
from langgraph.graph import StateGraph, START, END

from .state import InjuryAgentState
from .nodes import (
    should_use_tools,
    injury_agent_node,
    injury_tool_executor_node,
    injury_response_node,
    injury_autonomous_node,
    injury_action_data_node,
    check_for_tool_calls,
)
from core.logger import get_logger

logger = get_logger(__name__)


def build_injury_agent_graph():
    """
    Build and compile the injury agent graph.

    FLOW:
        START
          |
        should_use_tools (router)
          |--- agent (injury reporting/clearing)
          |      |
          |    check_for_tool_calls
          |      |--- tool_executor -> response
          |      |--- (no tools) -> action_data
          |
          |--- autonomous (injury advice)
                 |
             action_data
                 |
               END
    """
    logger.info("Building injury agent graph...")

    graph = StateGraph(InjuryAgentState)

    # Add nodes
    graph.add_node("agent", injury_agent_node)
    graph.add_node("tool_executor", injury_tool_executor_node)
    graph.add_node("response", injury_response_node)
    graph.add_node("autonomous", injury_autonomous_node)
    graph.add_node("action_data", injury_action_data_node)

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
    logger.info("Injury agent graph built successfully")

    return compiled
