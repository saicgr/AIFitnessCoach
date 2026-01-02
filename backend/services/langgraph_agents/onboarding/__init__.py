"""
Onboarding agent for FitWiz.

Uses LangGraph to conduct natural, AI-driven conversations instead of hardcoded questions.
"""
from .state import OnboardingState
from .nodes import (
    check_completion_node,
    onboarding_agent_node,
    extract_data_node,
    determine_next_step,
)
from .prompts import (
    ONBOARDING_AGENT_SYSTEM_PROMPT,
    DATA_EXTRACTION_SYSTEM_PROMPT,
    REQUIRED_FIELDS,
    OPTIONAL_FIELDS,
    QUICK_REPLIES,
)

__all__ = [
    "OnboardingState",
    "check_completion_node",
    "onboarding_agent_node",
    "extract_data_node",
    "determine_next_step",
    "ONBOARDING_AGENT_SYSTEM_PROMPT",
    "DATA_EXTRACTION_SYSTEM_PROMPT",
    "REQUIRED_FIELDS",
    "OPTIONAL_FIELDS",
    "QUICK_REPLIES",
]
