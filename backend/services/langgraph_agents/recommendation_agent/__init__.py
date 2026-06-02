"""Recommendation Agent — cross-domain synthesis (Gap 7 Part B).

Turns the user's whole picture (eaten + workouts + training load + injuries +
recovery + dietary prefs) into ONE grounded recommendation. Powers holistic
chat asks ("what should I eat/do given my training and how I'm recovering?").
"""
from .state import RecommendationAgentState
from .graph import build_recommendation_agent_graph

__all__ = [
    "RecommendationAgentState",
    "build_recommendation_agent_graph",
]
