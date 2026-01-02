"""
Plan Agent - LangGraph agent for holistic weekly planning.

This agent:
1. Generates comprehensive weekly plans integrating workouts, nutrition, and fasting
2. Adjusts nutrition targets based on training vs rest days
3. Coordinates fasting windows with workout schedules
4. Provides meal suggestions that fit within eating windows
5. Identifies and warns about potential conflicts (e.g., workout during fast)
"""
from .state import PlanAgentState
from .graph import build_plan_agent_graph

__all__ = [
    "PlanAgentState",
    "build_plan_agent_graph",
]
