"""
Nutrition Agent - LangGraph agent for nutrition tracking and dietary advice.

This agent:
1. Analyzes food images and logs meals
2. Provides nutrition summaries
3. Gives dietary advice and meal suggestions
4. Can respond autonomously without calling tools for general nutrition questions
"""
from .state import NutritionAgentState
from .graph import build_nutrition_agent_graph

__all__ = [
    "NutritionAgentState",
    "build_nutrition_agent_graph",
]
