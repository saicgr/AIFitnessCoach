"""
One-time migration script to fix generic AI weights in existing workouts.

The AI was setting weight=10 kg for ALL exercises regardless of type.
This script updates exercises with generic/low weights to use sensible
equipment-based defaults.

Usage:
    python -m scripts.fix_generic_weights [--dry-run]
"""
import json
import sys
import os

# Add parent to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)


def snap_barbell_kg(raw: float) -> float:
    """Snap to valid barbell load: 20 kg bar + multiples of 2 kg (1 kg plate per side)."""
    bar = 20.0
    if raw <= bar:
        return bar
    plates = round((raw - bar) / 2.0) * 2.0
    return bar + plates

def snap_dumbbell_kg(raw: float) -> float:
    """Snap to 2 kg increments (metric dumbbell standard)."""
    snapped = round(raw / 2.0) * 2.0
    return max(snapped, 2.0)

def snap_cable_kg(raw: float) -> float:
    """Snap to 5 kg increments (cable/machine pin-select)."""
    snapped = round(raw / 5.0) * 5.0
    return max(snapped, 5.0)

def snap_kettlebell_kg(raw: float) -> float:
    """Snap to standard competition kettlebell weights."""
    weights = [4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32]
    return min(weights, key=lambda w: abs(w - raw))

def get_default_weight_kg(equipment: str, name: str) -> float:
    """Return a sensible default weight (kg) snapped to real gym increments."""
    eq = (equipment or '').lower()
    name = (name or '').lower()

    # Barbell exercises — min is bar (20 kg)
    if 'barbell' in eq or 'barbell' in name or 'bench press' in name or 'deadlift' in name:
        if 'deadlift' in name:
            return snap_barbell_kg(40.0)
        elif 'squat' in name:
            return snap_barbell_kg(30.0)
        elif 'bench' in name or 'press' in name:
            return snap_barbell_kg(30.0)
        elif 'curl' in name or 'extension' in name or 'pullover' in name:
            return snap_barbell_kg(20.0)
        elif 'row' in name:
            return snap_barbell_kg(30.0)
        return snap_barbell_kg(24.0)

    # Dumbbell exercises — 2 kg steps
    if 'dumbbell' in eq or 'dumbbell' in name or 'dumbbells' in name:
        if 'lateral' in name or 'fly' in name or 'raise' in name:
            return snap_dumbbell_kg(4.0)
        elif 'curl' in name or 'extension' in name or 'kick' in name:
            return snap_dumbbell_kg(6.0)
        elif 'press' in name or 'row' in name or 'snatch' in name:
            return snap_dumbbell_kg(10.0)
        return snap_dumbbell_kg(8.0)

    # Cable — 5 kg steps
    if 'cable' in eq or 'cable' in name:
        if 'fly' in name or 'lateral' in name or 'face pull' in name:
            return snap_cable_kg(5.0)
        return snap_cable_kg(15.0)

    # Machine — 5 kg steps
    if 'machine' in eq or 'machine' in name:
        return snap_cable_kg(20.0)

    # Kettlebell — competition weights
    if 'kettlebell' in eq or 'kettlebell' in name:
        return snap_kettlebell_kg(12.0)

    # Smith machine
    if 'smith' in eq or 'smith' in name:
        return snap_barbell_kg(20.0)

    # EZ bar
    if 'ez' in eq or 'ez bar' in name or 'ez curl' in name:
        return snap_barbell_kg(16.0)

    return 0.0  # Bodyweight — don't set a weight


def fix_workout_weights(workout_id: str, exercises_json: str, dry_run: bool = True) -> tuple:
    """Fix generic weights in a single workout's exercises.

    Returns (modified: bool, changes: list of dicts describing changes)
    """
    try:
        exercises = json.loads(exercises_json) if isinstance(exercises_json, str) else exercises_json
    except (json.JSONDecodeError, TypeError):
        return False, []

    if not isinstance(exercises, list):
        return False, []

    modified = False
    changes = []

    for ex in exercises:
        name = ex.get('name', '')
        equipment = ex.get('equipment', '')
        weight = ex.get('weight')
        weight_source = ex.get('weight_source')

        # Only skip exercises with weights from actual user history
        if weight_source == 'historical':
            continue

        default_weight = get_default_weight_kg(equipment, name)
        if default_weight <= 0:
            continue  # Bodyweight — skip

        current_weight = weight or 0

        # Fix exercise weight if it's below the equipment default
        needs_fix = current_weight < default_weight

        # Check set_targets — fix if ANY working set has a different weight than default
        # This catches cases where the AI set 10 or 20 kg but the real default is 30 kg
        set_targets = ex.get('set_targets', [])
        has_bad_targets = any(
            abs((st.get('target_weight_kg') or 0) - default_weight) > 0.1
            for st in set_targets
            if st.get('set_type') != 'warmup' and (st.get('target_weight_kg') or 0) <= 20
        )

        if not needs_fix and not has_bad_targets:
            continue

        changes.append({
            'exercise': name,
            'equipment': equipment,
            'old_weight': current_weight,
            'new_weight': default_weight,
        })
        modified = True

        if not dry_run:
            if needs_fix:
                ex['weight'] = default_weight
                ex['weight_source'] = 'generic'

            # Fix ALL set_targets that are below equipment default
            for st in set_targets:
                target_wt = st.get('target_weight_kg') or 0
                set_type = st.get('set_type', 'working')
                if set_type == 'warmup':
                    # Warmup at 50% of default
                    if target_wt < default_weight * 0.5:
                        st['target_weight_kg'] = snap_barbell_kg(default_weight * 0.5) if 'barbell' in (equipment or '').lower() or 'barbell' in name.lower() else round(default_weight * 0.5)
                elif target_wt < default_weight:
                    st['target_weight_kg'] = default_weight

    return modified, changes


def run_migration(dry_run: bool = True):
    """Run the weight fix migration on all workouts."""
    db = get_supabase_db()

    # Fetch all workouts (paginated)
    page_size = 100
    offset = 0
    total_modified = 0
    total_exercises_fixed = 0

    logger.info(f"{'DRY RUN — ' if dry_run else ''}Starting generic weight fix migration")

    while True:
        result = db.client.table('workouts').select(
            'id, exercises_json'
        ).range(offset, offset + page_size - 1).execute()

        if not result.data:
            break

        for workout in result.data:
            workout_id = workout['id']
            exercises_json = workout.get('exercises_json', '[]')

            modified, changes = fix_workout_weights(workout_id, exercises_json, dry_run)

            if modified and changes:
                total_modified += 1
                total_exercises_fixed += len(changes)

                for change in changes:
                    logger.info(
                        f"  [{workout_id[:8]}] {change['exercise']}: "
                        f"{change['old_weight']}kg → {change['new_weight']}kg "
                        f"({change['equipment']})"
                    )

                if not dry_run:
                    # Parse, modify in-place, then save
                    exercises = json.loads(exercises_json) if isinstance(exercises_json, str) else list(exercises_json)
                    fix_workout_weights(workout_id, json.dumps(exercises), dry_run=False)
                    # Re-parse to get modified version (fix_workout_weights modifies the parsed list)
                    exercises2 = json.loads(exercises_json) if isinstance(exercises_json, str) else exercises_json
                    # Actually we need to re-run on the same data
                    parsed = json.loads(exercises_json) if isinstance(exercises_json, str) else exercises_json
                    for ex in parsed:
                        name_val = ex.get('name', '')
                        equipment_val = ex.get('equipment', '')
                        ws = ex.get('weight_source')
                        if ws == 'historical':
                            continue
                        dw = get_default_weight_kg(equipment_val, name_val)
                        if dw <= 0:
                            continue
                        cur_w = ex.get('weight') or 0
                        if cur_w < dw:
                            ex['weight'] = dw
                            ex['weight_source'] = 'generic'
                        for st in ex.get('set_targets', []):
                            tw = st.get('target_weight_kg') or 0
                            stype = st.get('set_type', 'working')
                            if stype == 'warmup':
                                if tw < dw * 0.5:
                                    st['target_weight_kg'] = round(dw * 0.5)
                            elif tw < dw:
                                st['target_weight_kg'] = dw
                    db.client.table('workouts').update({
                        'exercises_json': json.dumps(parsed),
                    }).eq('id', workout_id).execute()

        offset += page_size
        if len(result.data) < page_size:
            break

    logger.info(
        f"{'DRY RUN — ' if dry_run else ''}"
        f"Migration complete: {total_modified} workouts modified, "
        f"{total_exercises_fixed} exercises fixed"
    )


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    if not dry_run:
        logger.warning("Running in LIVE mode — this will modify the database!")
        confirm = input("Are you sure? (yes/no): ")
        if confirm.lower() != 'yes':
            print("Aborted.")
            sys.exit(0)

    run_migration(dry_run=dry_run)
