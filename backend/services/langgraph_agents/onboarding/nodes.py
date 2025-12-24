"""
Node implementations for the Onboarding LangGraph agent.

AI-driven onboarding - no hardcoded questions!

This module re-exports all nodes from the modular nodes package
for backwards compatibility.
"""

# Re-export everything from the nodes package
from .nodes import (
    # Utilities
    ensure_string,
    get_field_value,
    detect_field_from_response,
    detect_non_gym_activity,
    NON_GYM_ACTIVITIES,
    # Extraction
    extract_data_node,
    # Agent
    onboarding_agent_node,
    # Completion
    check_completion_node,
    determine_next_step,
)

__all__ = [
    # Utilities
    "ensure_string",
    "get_field_value",
    "detect_field_from_response",
    "detect_non_gym_activity",
    "NON_GYM_ACTIVITIES",
    # Extraction
    "extract_data_node",
    # Agent
    "onboarding_agent_node",
    # Completion
    "check_completion_node",
    "determine_next_step",
]
