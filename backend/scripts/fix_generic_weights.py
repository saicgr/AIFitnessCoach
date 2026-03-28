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

        # Skip if weight is from history or already reasonable
        if weight_source == 'historical':
            continue

        # Check if weight looks generic (≤10 kg for all equipment types)
        if weight is not None and weight > 10:
            continue

        default_weight = get_default_weight_kg(equipment, name)
        if default_weight <= 0:
            continue  # Bodyweight — skip

        current_weight = weight or 0

        if default_weight > current_weight:
            changes.append({
                'exercise': name,
                'equipment': equipment,
                'old_weight': current_weight,
                'new_weight': default_weight,
            })

            if not dry_run:
                ex['weight'] = default_weight
                ex['weight_source'] = 'generic'  # Mark as still generic but corrected

                # Also fix set_targets
                for st in ex.get('set_targets', []):
                    target_wt = st.get('target_weight_kg', 0)
                    if target_wt is not None and target_wt <= 10:
                        st['target_weight_kg'] = default_weight

            modified = True

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
                    exercises = json.loads(exercises_json) if isinstance(exercises_json, str) else exercises_json
                    # Re-run to get the modified exercises
                    _, _ = fix_workout_weights(workout_id, exercises_json, dry_run=False)
                    db.client.table('workouts').update({
                        'exercises_json': json.dumps(exercises),
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
