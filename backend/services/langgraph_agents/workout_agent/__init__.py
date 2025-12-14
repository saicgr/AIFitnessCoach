"""
Workout Agent - LangGraph agent for workout management and exercise guidance.

This agent:
1. Modifies workouts (add/remove exercises, change intensity)
2. Reschedules and manages workout calendar
3. Provides exercise guidance and form tips
4. Can respond autonomously for exercise questions
"""
from .state import WorkoutAgentState
from .graph import build_workout_agent_graph

__all__ = [
    "WorkoutAgentState",
    "build_workout_agent_graph",
]
