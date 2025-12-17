"""
LangGraph graph assembly for the Workout Insights agent.
"""
from langgraph.graph import StateGraph, START, END

from .state import WorkoutInsightsState
from .nodes import (
    analyze_workout_node,
    generate_structured_insights_node,
)
from core.logger import get_logger

logger = get_logger(__name__)

# Cached compiled graph
_compiled_graph = None


def build_workout_insights_graph():
    """
    Build and compile the workout insights agent graph.

    FLOW:
        START
          |
        analyze_workout (extract metrics, determine focus)
          |
        generate_structured_insights (AI generates structured JSON insights)
          |
         END

    Simple linear flow for generating workout insights.
    """
    global _compiled_graph

    if _compiled_graph is not None:
        return _compiled_graph

    logger.info("Building workout insights agent graph...")

    graph = StateGraph(WorkoutInsightsState)

    # Add nodes
    graph.add_node("analyze_workout", analyze_workout_node)
    graph.add_node("generate_insights", generate_structured_insights_node)

    # Linear flow
    graph.add_edge(START, "analyze_workout")
    graph.add_edge("analyze_workout", "generate_insights")
    graph.add_edge("generate_insights", END)

    # Compile
    _compiled_graph = graph.compile()

    logger.info("Workout insights agent graph built successfully")

    return _compiled_graph


async def generate_workout_insights(
    workout_id: str,
    workout_name: str,
    exercises: list,
    duration_minutes: int = 45,
    workout_type: str = None,
    difficulty: str = None,
    user_goals: list = None,
    fitness_level: str = "intermediate",
) -> str:
    """
    Generate structured workout insights using the insights agent.

    Args:
        workout_id: The workout's unique ID
        workout_name: Name of the workout
        exercises: List of exercise dictionaries
        duration_minutes: Workout duration
        workout_type: Type of workout (strength, cardio, etc.)
        difficulty: Difficulty level
        user_goals: User's fitness goals
        fitness_level: User's fitness level

    Returns:
        JSON string with structured insights:
        {
            "headline": "Motivational headline",
            "sections": [
                {"icon": "🎯", "title": "Focus", "content": "...", "color": "cyan"},
                ...
            ]
        }
    """
    graph = build_workout_insights_graph()

    initial_state = {
        "workout_id": workout_id,
        "workout_name": workout_name,
        "exercises": exercises,
        "duration_minutes": duration_minutes,
        "workout_type": workout_type,
        "difficulty": difficulty,
        "user_goals": user_goals or [],
        "fitness_level": fitness_level,
        "target_muscles": [],
        "exercise_count": 0,
        "total_sets": 0,
        "workout_focus": None,
        "headline": "",
        "sections": [],
        "summary": "",
        "error": None,
    }

    result = await graph.ainvoke(initial_state)
    return result.get("summary", "")
