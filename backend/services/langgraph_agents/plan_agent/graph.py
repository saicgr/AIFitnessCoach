"""
LangGraph graph assembly for the Plan Agent.
"""
from langgraph.graph import StateGraph, START, END

from .state import PlanAgentState
from .nodes import (
    should_generate_plan,
    plan_generate_node,
    plan_query_node,
    plan_modify_node,
    plan_respond_node,
    plan_action_data_node,
)
from core.logger import get_logger

logger = get_logger(__name__)


def build_plan_agent_graph():
    """
    Build and compile the plan agent graph.

    FLOW:
        START
          |
        should_generate_plan (router)
          |--- generate (create new plan)
          |      |
          |    action_data
          |
          |--- query (answer plan questions)
          |      |
          |    action_data
          |
          |--- modify (adjust existing plan)
          |      |
          |    action_data
          |
          |--- respond (general response)
                 |
              action_data
                 |
               END
    """
    logger.info("Building plan agent graph...")

    graph = StateGraph(PlanAgentState)

    # Add nodes
    graph.add_node("generate", plan_generate_node)
    graph.add_node("query", plan_query_node)
    graph.add_node("modify", plan_modify_node)
    graph.add_node("respond", plan_respond_node)
    graph.add_node("action_data", plan_action_data_node)

    # Router: what type of plan operation is needed?
    graph.add_conditional_edges(
        START,
        should_generate_plan,
        {
            "generate": "generate",
            "query": "query",
            "modify": "modify",
            "respond": "respond",
        }
    )

    # All paths lead to action_data
    graph.add_edge("generate", "action_data")
    graph.add_edge("query", "action_data")
    graph.add_edge("modify", "action_data")
    graph.add_edge("respond", "action_data")

    # Action data -> END
    graph.add_edge("action_data", END)

    compiled = graph.compile()
    logger.info("Plan agent graph built successfully")

    return compiled
