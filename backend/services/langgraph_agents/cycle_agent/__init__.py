"""
Cycle Agent - LangGraph agent for menstrual-cycle health.

This agent:
1. Answers cycle questions from the user's own logged data
2. Logs period events, symptoms, mood, energy and sleep
3. Sets cycle-sync workout / nutrition preferences
4. Gives phase-aware workout and nutrition guidance

Safety: never gives contraceptive advice, never diagnoses, flags red-flag
patterns with a clinician nudge, frames predictions as estimates, PCOS-aware.
"""
from .state import CycleAgentState
from .graph import build_cycle_agent_graph

__all__ = [
    "CycleAgentState",
    "build_cycle_agent_graph",
]
