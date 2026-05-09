"""
LangGraph tools package.

This package contains modular tool definitions organized by domain:
- workout_tools: Exercise and workout modification tools
- injury_tools: Injury reporting and management tools
- nutrition_tools: Food analysis and nutrition tracking tools
- form_tools: Exercise form analysis and comparison tools
"""

from .workout_tools import (
    add_exercise_to_workout,
    remove_exercise_from_workout,
    replace_all_exercises,
    modify_workout_intensity,
    reschedule_workout,
    delete_workout,
    generate_quick_workout,
    propose_workout_change,
)

from .injury_tools import (
    report_injury,
    clear_injury,
    get_active_injuries,
    update_injury_status,
)

from .nutrition_tools import (
    analyze_food_image,
    analyze_multi_food_images,
    parse_app_screenshot,
    parse_nutrition_label,
    get_nutrition_summary,
    get_recent_meals,
    log_food_from_text,
)

from .form_tools import (
    check_exercise_form,
    compare_exercise_form,
)

from .coach_tools import (
    import_gym_equipment,
    import_exercise,
)

# === Issue 3: workout mutation tools ===
# Direct in-workout mutations (swap one exercise, log a set, build/break
# supersets, reorder). Frontend renders a confirm-card via action_data
# before applying. Kept in a separate module to avoid merge conflicts
# with the parallel Issue 2 edits to workout_tools.py.
from .workout_mutation_tools import (
    swap_single_exercise,
    log_set,
    create_superset,
    break_superset,
    reorder_exercises,
    ISSUE_3_MUTATION_TOOLS,
)

# === Issue 2: equipment identify ===
# "What's this?" — when a user attaches a gym-equipment photo to chat,
# the Coach agent calls identify_equipment(s3_key) which delegates to
# the same `equipment_snap_core` powering POST /api/v1/equipment/snap.
# Returns action_data with action='open_swap_or_add' so the frontend
# can render the EquipmentMatchCard.
from .equipment_tools import (
    identify_equipment,
    ISSUE_2_EQUIPMENT_TOOLS,
)

from .base import get_vision_service, get_form_analysis_service

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
    propose_workout_change,
    # Injury tools
    report_injury,
    clear_injury,
    get_active_injuries,
    update_injury_status,
    # Nutrition tools
    analyze_food_image,
    analyze_multi_food_images,
    parse_app_screenshot,
    parse_nutrition_label,
    get_nutrition_summary,
    get_recent_meals,
    log_food_from_text,
    # Form analysis tools
    check_exercise_form,
    compare_exercise_form,
    # Coach import tools (gym equipment + custom exercise)
    import_gym_equipment,
    import_exercise,
    # === Issue 3: workout mutation tools ===
    *ISSUE_3_MUTATION_TOOLS,
    # === Issue 2: equipment identify ===
    *ISSUE_2_EQUIPMENT_TOOLS,
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
    "propose_workout_change",
    # Injury tools
    "report_injury",
    "clear_injury",
    "get_active_injuries",
    "update_injury_status",
    # Nutrition tools
    "analyze_food_image",
    "analyze_multi_food_images",
    "parse_app_screenshot",
    "parse_nutrition_label",
    "get_nutrition_summary",
    "get_recent_meals",
    "log_food_from_text",
    # Form analysis tools
    "check_exercise_form",
    "compare_exercise_form",
    # Coach import tools
    "import_gym_equipment",
    "import_exercise",
    # Issue 3: workout mutation tools
    "swap_single_exercise",
    "log_set",
    "create_superset",
    "break_superset",
    "reorder_exercises",
    "ISSUE_3_MUTATION_TOOLS",
    # Issue 2: equipment identify tool
    "identify_equipment",
    "ISSUE_2_EQUIPMENT_TOOLS",
    # Utilities
    "get_vision_service",
    "get_form_analysis_service",
    # Registry
    "ALL_TOOLS",
    "TOOLS_MAP",
]
