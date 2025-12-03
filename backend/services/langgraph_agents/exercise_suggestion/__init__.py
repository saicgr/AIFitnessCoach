"""
Exercise Suggestion Agent - LangGraph-based agent for suggesting exercise alternatives.

This agent:
1. Takes the current exercise and user preferences
2. Searches the exercise library for alternatives
3. Uses AI to rank and explain the suggestions
"""
from .state import ExerciseSuggestionState
from .graph import build_exercise_suggestion_graph
from .nodes import (
    analyze_request_node,
    search_exercises_node,
    generate_suggestions_node,
)

__all__ = [
    "ExerciseSuggestionState",
    "build_exercise_suggestion_graph",
    "analyze_request_node",
    "search_exercises_node",
    "generate_suggestions_node",
]
