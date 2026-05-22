"""
LangGraph graph assembly for the Cycle Agent.
"""
from langgraph.graph import StateGraph, START, END

from .state import CycleAgentState
from .nodes import (
    should_use_tools,
    cycle_agent_node,
    cycle_tool_executor_node,
    cycle_response_node,
    cycle_autonomous_node,
    cycle_action_data_node,
    check_for_tool_calls,
)
from core.logger import get_logger

logger = get_logger(__name__)


def build_cycle_agent_graph():
    """
    Build and compile the cycle agent graph.

    FLOW:
        START
          |
        should_use_tools (router)
          |--- agent (logging / status / actions)
          |      |
          |    check_for_tool_calls
          |      |--- tool_executor -> response -> action_data
          |      |--- (no tools) -> action_data
          |
          |--- autonomous (general cycle education)
                 |
             action_data
                 |
               END
    """
    logger.info("Building cycle agent graph...")

    graph = StateGraph(CycleAgentState)

    graph.add_node("agent", cycle_agent_node)
    graph.add_node("tool_executor", cycle_tool_executor_node)
    graph.add_node("response", cycle_response_node)
    graph.add_node("autonomous", cycle_autonomous_node)
    graph.add_node("action_data", cycle_action_data_node)

    graph.add_conditional_edges(
        START,
        should_use_tools,
        {
            "agent": "agent",
            "respond": "autonomous",
        },
    )

    graph.add_conditional_edges(
        "agent",
        check_for_tool_calls,
        {
            "execute_tools": "tool_executor",
            "finalize": "action_data",
        },
    )

    graph.add_edge("tool_executor", "response")
    graph.add_edge("response", "action_data")
    graph.add_edge("autonomous", "action_data")
    graph.add_edge("action_data", END)

    compiled = graph.compile()
    logger.info("Cycle agent graph built successfully")

    return compiled
