"""
Completion checking nodes for onboarding.

Contains nodes for checking if onboarding is complete and routing.
"""

from typing import Dict, Any

from ..state import OnboardingState
from ..prompts import REQUIRED_FIELDS
from .utils import get_field_value
from core.logger import get_logger

logger = get_logger(__name__)


async def check_completion_node(state: OnboardingState) -> Dict[str, Any]:
    """
    Check if onboarding is complete by examining collected data.

    IMPORTANT: Handles both snake_case (backend) and camelCase (frontend) keys!
    Frontend stores data in camelCase but backend expects snake_case.

    Args:
        state: The current onboarding state

    Returns:
        - is_complete: True if all required fields are collected
        - missing_fields: List of fields still needed
    """
    logger.info("[Check Completion] Checking if onboarding is complete...")

    collected = state.get("collected_data", {})
    missing = []

    logger.info(f"[Check Completion] Collected data keys: {list(collected.keys())}")

    for field in REQUIRED_FIELDS:
        # Use helper to check both snake_case and camelCase
        value = get_field_value(collected, field)

        # Check if field is missing or empty
        if value is None or value == "" or (isinstance(value, list) and len(value) == 0):
            missing.append(field)

    is_complete = len(missing) == 0

    logger.info(f"[Check Completion] Complete: {is_complete}, Missing: {missing}")

    return {
        "is_complete": is_complete,
        "missing_fields": missing,
    }


def determine_next_step(state: OnboardingState) -> str:
    """
    Determine what to do next after checking completion.

    Args:
        state: The current onboarding state

    Returns:
        - "ask_question" if still missing data
        - "complete" if onboarding is done
    """
    is_complete = state.get("is_complete", False)

    if is_complete:
        logger.info("[Router] Onboarding complete!")
        return "complete"
    else:
        logger.info("[Router] Still need more data, continuing conversation")
        return "ask_question"
