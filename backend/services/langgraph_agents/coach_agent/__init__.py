"""
Coach Agent - LangGraph agent for general fitness coaching and app navigation.

This agent:
1. Handles general fitness questions and motivation
2. Handles app settings and navigation
3. Provides general wellness advice
4. Acts as the fallback for unclassified queries
"""
from .state import CoachAgentState
from .graph import build_coach_agent_graph
from .nodes import should_handle_action, coach_response_stream

__all__ = [
    "CoachAgentState",
    "build_coach_agent_graph",
    "should_handle_action",
    "coach_response_stream",
]
