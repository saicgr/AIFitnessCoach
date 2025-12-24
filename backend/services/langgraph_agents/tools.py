"""
LangChain tool definitions for workout modifications, injury management,
and food image analysis.

This module re-exports all tools from the modular tools package
for backwards compatibility.

These tools are bound to the LLM and can be called automatically
based on user intent.
"""

# Re-export everything from the tools package
from .tools import (
    # Workout tools
    add_exercise_to_workout,
    remove_exercise_from_workout,
    replace_all_exercises,
    modify_workout_intensity,
    reschedule_workout,
    delete_workout,
    generate_quick_workout,
    # Injury tools
    report_injury,
    clear_injury,
    get_active_injuries,
    update_injury_status,
    # Nutrition tools
    analyze_food_image,
    get_nutrition_summary,
    get_recent_meals,
    # Utilities
    get_vision_service,
    # Registry
    ALL_TOOLS,
    TOOLS_MAP,
)

__all__ = [
    # Workout tools
    "add_exercise_to_workout",
    "remove_exercise_from_workout",
    "replace_all_exercises",
    "modify_workout_intensity",
    "reschedule_workout",
    "delete_workout",
    "generate_quick_workout",
    # Injury tools
    "report_injury",
    "clear_injury",
    "get_active_injuries",
    "update_injury_status",
    # Nutrition tools
    "analyze_food_image",
    "get_nutrition_summary",
    "get_recent_meals",
    # Utilities
    "get_vision_service",
    # Registry
    "ALL_TOOLS",
    "TOOLS_MAP",
]
