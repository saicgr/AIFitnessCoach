"""
Onboarding nodes package.

This package contains modular node implementations for the onboarding LangGraph agent:
- utils: Utility functions for string handling and field detection
- extraction: Data extraction from user messages
- agent: AI question generation node
- completion: Completion checking and routing
"""

from .utils import (
    ensure_string,
    get_field_value,
    detect_field_from_response,
    detect_non_gym_activity,
    NON_GYM_ACTIVITIES,
)

from .extraction import extract_data_node

from .agent import onboarding_agent_node

from .completion import (
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
