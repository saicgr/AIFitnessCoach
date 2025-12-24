"""
LangGraph tools package.

This package contains modular tool definitions organized by domain:
- workout_tools: Exercise and workout modification tools
- injury_tools: Injury reporting and management tools
- nutrition_tools: Food analysis and nutrition tracking tools
"""

from .workout_tools import (
    add_exercise_to_workout,
    remove_exercise_from_workout,
    replace_all_exercises,
    modify_workout_intensity,
    reschedule_workout,
    delete_workout,
    generate_quick_workout,
)

from .injury_tools import (
    report_injury,
    clear_injury,
    get_active_injuries,
    update_injury_status,
)

from .nutrition_tools import (
    analyze_food_image,
    get_nutrition_summary,
    get_recent_meals,
)

from .base import get_vision_service

# Registry of all available tools
ALL_TOOLS = [
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
]

# Tool name to function mapping
TOOLS_MAP = {tool.name: tool for tool in ALL_TOOLS}

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
