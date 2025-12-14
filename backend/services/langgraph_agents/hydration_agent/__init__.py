"""
Hydration Agent - LangGraph agent for hydration tracking and advice.

This agent:
1. Handles hydration logging (via action_data)
2. Provides hydration advice and recommendations
3. Answers questions about water intake and hydration
4. Primarily autonomous - gives advice without tools
"""
from .state import HydrationAgentState
from .graph import build_hydration_agent_graph

__all__ = [
    "HydrationAgentState",
    "build_hydration_agent_graph",
]
