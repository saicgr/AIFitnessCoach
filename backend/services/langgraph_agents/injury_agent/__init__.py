"""
Injury Agent - LangGraph agent for injury management and recovery guidance.

This agent:
1. Records and tracks injuries
2. Modifies workouts based on injuries
3. Provides recovery guidance and rehab exercises
4. Can respond autonomously for injury prevention and pain management advice
"""
from .state import InjuryAgentState
from .graph import build_injury_agent_graph

__all__ = [
    "InjuryAgentState",
    "build_injury_agent_graph",
]
