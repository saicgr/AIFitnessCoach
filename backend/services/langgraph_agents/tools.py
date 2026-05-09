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

# === Issue 3: workout mutation tools ===
# Re-export the in-workout mutation tools (swap one exercise, log a set,
# build/break supersets, reorder). Defined in tools/workout_mutation_tools.py
# to keep Issue 3 isolated from the parallel Issue 2 edits to
# tools/workout_tools.py. ALL_TOOLS already contains these via the
# package-level __init__.py — this block exists purely so callers can
# `from .tools import log_set` etc. without going through the subpackage.
from .tools import (
    swap_single_exercise,
    log_set,
    create_superset,
    break_superset,
    reorder_exercises,
)

# === Issue 2: equipment identify ===
# Re-export the identify_equipment tool ("What's this?" chat pill +
# in-chat gym_equipment photo handling). Defined in
# tools/equipment_tools.py to keep Issue 2 isolated from the parallel
# Issue 3 mutation edits. ALL_TOOLS already contains this via the
# package-level __init__.py — this block exists purely so callers can
# `from .tools import identify_equipment` without going through the
# subpackage.
from .tools import identify_equipment

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
    # === Issue 3: workout mutation tools ===
    "swap_single_exercise",
    "log_set",
    "create_superset",
    "break_superset",
    "reorder_exercises",
    # === Issue 2: equipment identify ===
    "identify_equipment",
]
