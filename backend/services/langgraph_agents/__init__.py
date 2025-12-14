"""LangGraph agents for AI Fitness Coach.

This package contains dedicated domain agents:
- Nutrition Agent: Food analysis, dietary advice
- Workout Agent: Exercise modifications, workout guidance
- Injury Agent: Injury tracking, recovery advice
- Hydration Agent: Water intake tracking, hydration tips
- Coach Agent: General fitness coaching, app navigation

Also includes legacy main graph for backwards compatibility.
"""
# Legacy main graph (for backwards compatibility)
from .graph import build_fitness_coach_graph
from .state import FitnessCoachState

# Domain-specific agents
from .nutrition_agent import NutritionAgentState, build_nutrition_agent_graph
from .workout_agent import WorkoutAgentState, build_workout_agent_graph
from .injury_agent import InjuryAgentState, build_injury_agent_graph
from .hydration_agent import HydrationAgentState, build_hydration_agent_graph
from .coach_agent import CoachAgentState, build_coach_agent_graph

# Base state
from .base_state import BaseAgentState

__all__ = [
    # Legacy
    "build_fitness_coach_graph",
    "FitnessCoachState",
    # Base
    "BaseAgentState",
    # Nutrition
    "NutritionAgentState",
    "build_nutrition_agent_graph",
    # Workout
    "WorkoutAgentState",
    "build_workout_agent_graph",
    # Injury
    "InjuryAgentState",
    "build_injury_agent_graph",
    # Hydration
    "HydrationAgentState",
    "build_hydration_agent_graph",
    # Coach
    "CoachAgentState",
    "build_coach_agent_graph",
]
