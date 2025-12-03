"""
LangGraph graph assembly for the Exercise Suggestion agent.
"""
from langgraph.graph import StateGraph, START, END

from .state import ExerciseSuggestionState
from .nodes import (
    analyze_request_node,
    search_exercises_node,
    generate_suggestions_node,
)
from core.logger import get_logger

logger = get_logger(__name__)


def build_exercise_suggestion_graph():
    """
    Build and compile the exercise suggestion agent graph.

    FLOW:
        START
          |
        analyze_request (understand why user wants to swap)
          |
        search_exercises (find candidates from library)
          |
        generate_suggestions (AI ranks and explains)
          |
         END

    This is a simple linear flow - no branching needed for suggestions.
    """
    logger.info("Building exercise suggestion agent graph...")

    graph = StateGraph(ExerciseSuggestionState)

    # Add nodes
    graph.add_node("analyze_request", analyze_request_node)
    graph.add_node("search_exercises", search_exercises_node)
    graph.add_node("generate_suggestions", generate_suggestions_node)

    # Linear flow
    graph.add_edge(START, "analyze_request")
    graph.add_edge("analyze_request", "search_exercises")
    graph.add_edge("search_exercises", "generate_suggestions")
    graph.add_edge("generate_suggestions", END)

    # Compile
    compiled_graph = graph.compile()

    logger.info("Exercise suggestion agent graph built successfully")

    return compiled_graph
