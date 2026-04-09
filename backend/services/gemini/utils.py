"""
Gemini Service Utilities - Shared helper functions for prompt building,
set target validation, and equipment rules.
"""
import json
import re
import logging
from typing import List, Dict

logger = logging.getLogger("gemini")


def _sanitize_for_prompt(text: str, max_len: int = 1000) -> str:
    """Sanitize user input before inserting into AI prompts.

    Strips characters commonly used for prompt injection and truncates
    to prevent overly long inputs from dominating the context window.
    """
    if not text:
        return ""
    return re.sub(r'[\'"\\`\n\r{}]', '', text)[:max_len]


def safe_join_list(items, default: str = "") -> str:
    """
    Safely join a list of items that might contain strings or dicts.

    This handles the case where goals, equipment, etc. might be stored as
    dictionaries instead of strings (e.g., [{"name": "weight_loss"}]).

    Args:
        items: List of strings or dicts to join
        default: Default value if items is empty or None

    Returns:
        Comma-separated string of items
    """
    if not items:
        return default

    result = []
    for item in items:
        if isinstance(item, str):
            if item.strip():
                result.append(item.strip())
        elif isinstance(item, dict):
            name = (
                item.get("name") or
                item.get("goal") or
                item.get("title") or
                item.get("value") or
                item.get("id") or
                str(item)
            )
            if name and isinstance(name, str):
                result.append(name.strip())
        else:
            result.append(str(item))

    return ", ".join(result) if result else default


# Canonical set of equipment values that are NOT bodyweight
_BODYWEIGHT_ALIASES = {"bodyweight", "none", "no_equipment", ""}


def _build_equipment_usage_rule(equipment) -> str:
    """Build the equipment-usage rule section for the workout generation prompt.

    Dynamically detects ANY non-bodyweight equipment so kettlebell, resistance_bands,
    pull_up_bar, etc. all get the same strong enforcement rule that was previously
    only applied to full_gym/dumbbells/barbell/cable_machine/machines.
    """
    if not equipment:
        return ""

    # Normalise items (may be dicts from the DB)
    normalised = []
    for item in equipment:
        if isinstance(item, str):
            normalised.append(item.strip().lower())
        elif isinstance(item, dict):
            val = item.get("name") or item.get("value") or item.get("id") or ""
            if isinstance(val, str):
                normalised.append(val.strip().lower())

    real_equipment = [e for e in normalised if e and e not in _BODYWEIGHT_ALIASES]

    if not real_equipment:
        return (
            "The user has NO equipment — generate bodyweight-only exercises.\n"
            "Do NOT include any exercises that require dumbbells, barbells, machines, or other equipment."
        )

    equip_names = ", ".join(real_equipment)

    # Detect bench and rack availability
    has_bench = any("bench" in e for e in normalised) or any("home_gym" in e or "full_gym" in e for e in normalised)
    has_rack = any("squat_rack" in e or "rack" in e or "power_rack" in e for e in normalised) or any("full_gym" in e for e in normalised)

    equipment_restrictions = []
    if real_equipment and not has_bench:
        equipment_restrictions.append(
            "⚠️ NO BENCH AVAILABLE: The user does NOT have a weight bench.\n"
            "STRICTLY EXCLUDE all exercises that require lying on a bench:\n"
            "  - Bench Press (flat, incline, decline — any variation)\n"
            "  - Pullover / Pull Over (Dumbbell Chest Pullover, Dumbbell Chest Pull Over, etc.)\n"
            "  - Tate Press, JM Press, Lying Tricep Extension, Lying Extension\n"
            "  - Preacher Curl, Chest-Supported Row, Chest-Supported Fly\n"
            "  - Any exercise whose name contains 'bench', 'incline dumbbell', 'decline dumbbell', or 'lying extension'\n"
            "SAFE ALTERNATIVES: Floor Press, Push-Ups, Dumbbell Floor Flye, "
            "Standing/Seated Overhead Press, Dips."
        )
    if any("barbell" in e for e in normalised) and not has_rack:
        equipment_restrictions.append(
            "⚠️ NO SQUAT RACK: Exclude Barbell Squat, Barbell Bench Press, "
            "Overhead Press (racked). Use: Deadlift, RDL, Bent-Over Row instead."
        )
    restriction_text = "\n".join(equipment_restrictions)

    base_rule = (
        f"IF THE USER HAS EQUIPMENT, YOU **MUST** USE IT! This is NON-NEGOTIABLE.\n"
        f"The user owns: {equip_names}\n"
        f"  → AT LEAST 4-5 exercises (out of 6-8 total) MUST use the user's equipment\n"
        f"  → Maximum 1-2 bodyweight exercises allowed\n"
        f"  → NEVER generate a mostly bodyweight workout when the user has equipment!\n"
        f"  → Prioritise the user's specific equipment ({equip_names}) over generic bodyweight moves."
    )

    if restriction_text:
        return f"{base_rule}\n\n{restriction_text}"
    return base_rule


def infer_set_type(exercise: Dict, set_target: Dict, set_index: int, total_sets: int) -> str:
    """
    Infer set_type from context when Gemini omits it (safety net).

    Inference rules based on prompt guidelines:
    1. RPE 10 or RIR 0 -> failure
    2. Exercise marked is_failure_set and last set -> failure
    3. Exercise marked is_drop_set and one of last N sets -> drop
    4. First set of weighted exercise -> warmup
    5. Default -> working
    """
    target_rpe = set_target.get('target_rpe')
    target_rir = set_target.get('target_rir')
    target_weight = set_target.get('target_weight_kg')
    set_num = set_target.get('set_number', set_index + 1)

    if target_rpe == 10 or target_rir == 0:
        return "failure"

    if exercise.get('is_failure_set') and set_index == total_sets - 1:
        return "failure"

    if exercise.get('is_drop_set'):
        drop_count = exercise.get('drop_set_count', 2)
        if set_index >= total_sets - drop_count:
            return "drop"

    if set_num == 1 and target_weight and target_weight > 0:
        return "warmup"

    return "working"


def validate_set_targets_strict(exercises: List[Dict], user_context: Dict = None) -> List[Dict]:
    """
    STRICTLY validates that every exercise has set_targets array from Gemini.
    FAILS (raises exception) if any exercise is missing set_targets - NO FALLBACK DATA.

    Also validates set_type values (W=warmup, D=drop, F=failure, A=amrap, or working).

    Args:
        exercises: List of exercise dictionaries from Gemini
        user_context: Optional dict with user info for logging (user_id, fitness_level, etc.)

    Returns:
        List of exercises if all valid

    Raises:
        ValueError: If any exercise is missing set_targets or has invalid set types
    """
    if user_context:
        logger.info(f"🔍 [set_targets] Validating for user context:")
        logger.info(f"   - user_id: {user_context.get('user_id', 'unknown')}")
        logger.info(f"   - fitness_level: {user_context.get('fitness_level', 'unknown')}")
        logger.info(f"   - difficulty: {user_context.get('difficulty', 'unknown')}")
        logger.info(f"   - goals: {user_context.get('goals', [])}")
        logger.info(f"   - equipment: {user_context.get('equipment', [])}")

    missing_targets = []
    invalid_set_types = []
    valid_set_types = {'warmup', 'working', 'drop', 'failure', 'amrap'}

    set_type_counts = {'warmup': 0, 'working': 0, 'drop': 0, 'failure': 0, 'amrap': 0}
    total_sets = 0

    for exercise in exercises:
        if isinstance(exercise, str):
            try:
                exercise = json.loads(exercise)
            except (json.JSONDecodeError, ValueError):
                logger.error(f"❌ [set_targets] Exercise is an unparseable string: {exercise[:100]}", exc_info=True)
                continue
        if not isinstance(exercise, dict):
            logger.error(f"❌ [set_targets] Exercise is not a dict: type={type(exercise).__name__}")
            continue

        ex_name = exercise.get('name', 'Unknown')
        set_targets = exercise.get("set_targets")

        if isinstance(set_targets, str):
            try:
                set_targets = json.loads(set_targets)
                exercise["set_targets"] = set_targets
            except (json.JSONDecodeError, ValueError):
                logger.error(f"❌ [set_targets] set_targets is an unparseable string for '{ex_name}'", exc_info=True)
                set_targets = None

        if not set_targets:
            missing_targets.append(ex_name)
            logger.error(f"❌ [set_targets] MISSING for '{ex_name}' - Gemini FAILED to generate!")
            continue

        if not isinstance(set_targets, list):
            missing_targets.append(ex_name)
            logger.error(f"❌ [set_targets] set_targets is not a list for '{ex_name}': type={type(set_targets).__name__}")
            continue

        logger.info(f"✅ [set_targets] '{ex_name}' has {len(set_targets)} targets:")
        for idx, st in enumerate(set_targets):
            if isinstance(st, str):
                try:
                    st = json.loads(st)
                    set_targets[idx] = st
                except (json.JSONDecodeError, ValueError):
                    logger.warning(f"⚠️ [set_targets] Skipping unparseable set_target string for '{ex_name}' set {idx + 1}", exc_info=True)
                    continue
            if not isinstance(st, dict):
                logger.warning(f"⚠️ [set_targets] Skipping non-dict set_target for '{ex_name}' set {idx + 1}: type={type(st).__name__}")
                continue

            total_sets += 1
            set_num = st.get('set_number', idx + 1)
            set_type = st.get('set_type')
            target_reps = st.get('target_reps', 0)
            target_weight = st.get('target_weight_kg')
            target_rpe = st.get('target_rpe')

            if not set_type:
                set_type = infer_set_type(exercise, st, idx, len(set_targets))
                st['set_type'] = set_type
                logger.warning(f"⚠️ [set_type] Auto-inferred '{set_type}' for '{ex_name}' set {set_num}")

            set_type_lower = set_type.lower()

            if set_type_lower not in valid_set_types:
                invalid_set_types.append(f"{ex_name} set {set_num}: '{set_type}'")
                logger.error(f"❌ [set_type] Invalid '{set_type}' for '{ex_name}' set {set_num} - must be W/D/F/A or working")
            else:
                set_type_counts[set_type_lower] += 1

            type_indicator = {
                'warmup': 'W',
                'working': str(set_num),
                'drop': 'D',
                'failure': 'F',
                'amrap': 'A'
            }.get(set_type_lower, '?')

            weight_str = f"{target_weight}kg" if target_weight else "BW"
            rpe_str = f"RPE {target_rpe}" if target_rpe else ""
            logger.info(f"   [{type_indicator}] Set {set_num}: {set_type.upper()} - {weight_str} × {target_reps} {rpe_str}")

    if missing_targets:
        error_msg = f"Gemini FAILED to generate set_targets for {len(missing_targets)} exercises: {missing_targets}"
        logger.error(f"❌ [FATAL] {error_msg}")
        raise ValueError(error_msg)

    if invalid_set_types:
        error_msg = f"Gemini generated invalid set_type for {len(invalid_set_types)} sets: {invalid_set_types}"
        logger.error(f"❌ [FATAL] {error_msg}")
        raise ValueError(error_msg)

    # Enforce MINIMUM 3 working sets per exercise
    MIN_WORKING_SETS = 3
    _effective_types = {'working', 'drop', 'failure', 'amrap'}
    for exercise in exercises:
        if not isinstance(exercise, dict):
            continue
        ex_name = exercise.get('name', 'Unknown')
        targets = exercise.get('set_targets', [])
        if not isinstance(targets, list):
            continue
        working_count = sum(
            1 for st in targets
            if isinstance(st, dict) and st.get('set_type', 'working').lower() in _effective_types
        )
        if working_count < MIN_WORKING_SETS:
            logger.warning(
                f"⚠️ [set_targets] '{ex_name}' has only {working_count} effective sets "
                f"(min {MIN_WORKING_SETS}) — auto-repairing"
            )
            last_eff = next(
                (st for st in reversed(targets)
                 if isinstance(st, dict) and st.get('set_type', 'working').lower() in _effective_types),
                None
            )
            if last_eff is None:
                last_eff = {
                    'set_type': 'working',
                    'target_reps': exercise.get('reps', 10),
                    'target_weight_kg': None,
                    'target_rpe': 8,
                    'target_rir': 2,
                }
            while working_count < MIN_WORKING_SETS:
                new_set = dict(last_eff)
                new_set['set_number'] = len(targets) + 1
                if new_set.get('set_type', 'working').lower() in ('failure', 'amrap'):
                    new_set['set_type'] = 'working'
                    new_set['target_rpe'] = min(9, (new_set.get('target_rpe') or 8))
                    new_set['target_rir'] = max(1, (new_set.get('target_rir') or 1))
                targets.append(new_set)
                working_count += 1

            exercise['set_targets'] = targets
            exercise['sets'] = len(targets)
            logger.info(f"✅ [set_targets] '{ex_name}' repaired to {len(targets)} sets")

    logger.info(f"📊 [set_targets] Summary ({total_sets} total sets):")
    logger.info(f"   W (warmup): {set_type_counts['warmup']}")
    logger.info(f"   Working: {set_type_counts['working']}")
    logger.info(f"   D (drop): {set_type_counts['drop']}")
    logger.info(f"   F (failure): {set_type_counts['failure']}")
    logger.info(f"   A (amrap): {set_type_counts['amrap']}")

    logger.info(f"✅ [set_targets] All {len(exercises)} exercises have valid set_targets with proper set_type!")
    return exercises


# Keep old function name as alias for backwards compatibility with generation.py imports
ensure_set_targets = validate_set_targets_strict
