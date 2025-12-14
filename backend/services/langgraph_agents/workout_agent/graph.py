"""
LangGraph graph assembly for the Workout Agent.
"""
from langgraph.graph import StateGraph, START, END

from .state import WorkoutAgentState
from .nodes import (
    should_use_tools,
    workout_agent_node,
    workout_tool_executor_node,
    workout_response_node,
    workout_autonomous_node,
    workout_action_data_node,
    check_for_tool_calls,
)
from core.logger import get_logger

logger = get_logger(__name__)


def build_workout_agent_graph():
    """
    Build and compile the workout agent graph.

    FLOW:
        START
          |
        should_use_tools (router)
          |--- agent (modifications)
          |      |
          |    check_for_tool_calls
          |      |--- tool_executor -> response
          |      |--- (no tools) -> action_data
          |
          |--- autonomous (exercise questions)
                 |
             action_data
                 |
               END
    """
    logger.info("Building workout agent graph...")

    graph = StateGraph(WorkoutAgentState)

    # Add nodes
    graph.add_node("agent", workout_agent_node)
    graph.add_node("tool_executor", workout_tool_executor_node)
    graph.add_node("response", workout_response_node)
    graph.add_node("autonomous", workout_autonomous_node)
    graph.add_node("action_data", workout_action_data_node)

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
    logger.info("Workout agent graph built successfully")

    return compiled
