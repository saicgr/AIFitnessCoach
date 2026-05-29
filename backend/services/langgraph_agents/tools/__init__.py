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
from .wellness_tools import (
    log_event,
    set_agent_user_id,
    WELLNESS_TOOLS,
)

from .equipment_tools import (
    identify_equipment,
    ISSUE_2_EQUIPMENT_TOOLS,
)

# === Phase B2: wearable health & activity ===
# On-demand snapshot of the user's sleep / recovery / steps / heart-rate
# picture. Delegates to HealthActivityMixin.get_health_activity_snapshot;
# the coach also gets a pre-fetched compact version in its prompt context.
from .health_tools import (
    get_health_activity_summary,
    HEALTH_TOOLS,
)

# === Phase F: menstrual-cycle agent tools ===
# Read + action tools for the dedicated cycle agent (status / history /
# symptoms, period & symptom logging, cycle-sync preferences, phase-based
# workout & meal suggestions). Surfaced through chat action_data.
from .cycle_tools import (
    get_cycle_status,
    get_cycle_history,
    get_recent_symptoms,
    log_cycle_symptom,
    log_period_event,
    set_cycle_sync_preference,
    suggest_phase_workout,
    suggest_phase_meals,
    CYCLE_TOOLS,
)

# === Suggested-action launcher chips ===
# `suggest_actions` lets the nutrition + workout agents surface tappable
# shortcut chips (scan a menu, check form, browse workouts) in the chat.
# `inject_suggested_actions` is the central merger called once per response.
from .suggestion_tools import (
    suggest_actions,
    inject_suggested_actions,
    CHAT_LAUNCHABLE_ACTION_IDS,
)

from .base import get_vision_service, get_form_analysis_service

# === Phase 2-6 workouts overhaul tools ===
# Equipment calibration, user_state read, regenerate today, force deload,
# progression-style set, bonus-workout eligibility, recovery recommendation,
# why-this-workout explain, per-muscle score breakdown.
from .coach_phase2_tools import (
    calibrate_equipment,
    get_user_state,
    regenerate_today,
    start_deload_week,
    set_progression_style,
    bonus_workout_eligibility,
    apply_recovery_recommendation,
    explain_today_workout,
    score_breakdown,
)

PHASE2_TOOLS = [
    calibrate_equipment,
    get_user_state,
    regenerate_today,
    start_deload_week,
    set_progression_style,
    bonus_workout_eligibility,
    apply_recovery_recommendation,
    explain_today_workout,
    score_breakdown,
]

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
    # === Wellness logging (2026-05-10): generalized log_event tool ===
    *WELLNESS_TOOLS,
    # === Phase B2: wearable health & activity snapshot ===
    *HEALTH_TOOLS,
    # === Phase F: menstrual-cycle agent tools ===
    *CYCLE_TOOLS,
    # === Phase 2-6 workouts overhaul ===
    *PHASE2_TOOLS,
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
    # Phase B2: wearable health & activity
    "get_health_activity_summary",
    "HEALTH_TOOLS",
    # Phase F: menstrual-cycle agent tools
    "get_cycle_status",
    "get_cycle_history",
    "get_recent_symptoms",
    "log_cycle_symptom",
    "log_period_event",
    "set_cycle_sync_preference",
    "suggest_phase_workout",
    "suggest_phase_meals",
    "CYCLE_TOOLS",
    # Phase 2-6 workouts overhaul
    "calibrate_equipment",
    "get_user_state",
    "regenerate_today",
    "start_deload_week",
    "set_progression_style",
    "bonus_workout_eligibility",
    "apply_recovery_recommendation",
    "explain_today_workout",
    "score_breakdown",
    "PHASE2_TOOLS",
    # Utilities
    "get_vision_service",
    "get_form_analysis_service",
    # Registry
    "ALL_TOOLS",
    "TOOLS_MAP",
]
