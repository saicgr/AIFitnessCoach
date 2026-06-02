"""LangGraph graph assembly for the Recommendation (synthesis) Agent — Gap 7 Part B."""
from langgraph.graph import StateGraph, START, END

from .state import RecommendationAgentState
from .nodes import recommendation_node
from core.logger import get_logger

logger = get_logger(__name__)


def build_recommendation_agent_graph():
    """Build and compile the recommendation agent graph.

    FLOW (single-node — the node assembles its own holistic context):
        START -> recommend -> END
    """
    logger.info("Building recommendation agent graph...")

    graph = StateGraph(RecommendationAgentState)
    graph.add_node("recommend", recommendation_node)
    graph.add_edge(START, "recommend")
    graph.add_edge("recommend", END)

    compiled = graph.compile()
    logger.info("Recommendation agent graph built successfully")
    return compiled
