"""
Backfill exercise difficulty levels based on exercise characteristics.

The source Excel file (1500+ exercise data.xlsx) doesn't have difficulty levels.
This script infers difficulty based on:
1. Equipment complexity (bodyweight = beginner, machines = intermediate, advanced equipment = advanced)
2. Exercise name patterns (plyo, explosive, weighted = harder)
3. Categories (conditioning, plyometric = intermediate+)

Usage:
    python scripts/backfill_exercise_difficulty.py

Environment variables:
    SUPABASE_URL - Supabase project URL
    SUPABASE_SERVICE_KEY - Supabase service role key
"""

import os
import sys
import re

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase


# Equipment-based difficulty mapping
EQUIPMENT_DIFFICULTY = {
    # Beginner equipment
    'bodyweight': 'Beginner',
    'none': 'Beginner',
    'yoga mat': 'Beginner',
    'foam roller': 'Beginner',
    'stability ball': 'Beginner',
    'resistance band': 'Beginner',
    'mini band': 'Beginner',

    # Intermediate equipment
    'dumbbells': 'Intermediate',
    'dumbbell': 'Intermediate',
    'kettlebells': 'Intermediate',
    'kettlebell': 'Intermediate',
    'barbell': 'Intermediate',
    'cable': 'Intermediate',
    'cable pulley machine': 'Intermediate',
    'cable machine': 'Intermediate',
    'machine': 'Intermediate',
    'smith machine': 'Intermediate',
    'pull-up bar': 'Intermediate',
    'dip bars': 'Intermediate',
    'bench': 'Intermediate',
    'ez bar': 'Intermediate',
    'medicine ball': 'Intermediate',
    'trx': 'Intermediate',
    'suspension trainer': 'Intermediate',

    # Advanced equipment
    'olympic barbell': 'Advanced',
    'trap bar': 'Advanced',
    'battle ropes': 'Advanced',
    'tire': 'Advanced',
    'sledgehammer': 'Advanced',
    'sandbag': 'Advanced',
    'chains': 'Advanced',
    'weight vest': 'Advanced',
    'gymnastic rings': 'Advanced',
}

# Exercise name patterns that indicate difficulty
ADVANCED_PATTERNS = [
    r'\bplyo\b', r'\bplyometric\b', r'\bexplosive\b', r'\bjump\b',
    r'\bpower\b', r'\bsnatch\b', r'\bclean\b', r'\bjerk\b',
    r'\bmuscle.?up\b', r'\bpistol\b', r'\bone.?leg\b', r'\bone.?arm\b',
    r'\bhandstand\b', r'\bl.?sit\b', r'\bfront lever\b', r'\bback lever\b',
    r'\bdragon flag\b', r'\bhuman flag\b', r'\bweighted\b',
    # Advanced calisthenics - require years of training
    r'\bplanche\b', r'\biron cross\b', r'\bmaltese\b', r'\bvictorian\b',
    r'\bv.?sit\b', r'\bmanna\b', r'\bshrimp squat\b', r'\bdragon squat\b',
    r'\barcher\b', r'\b90.?degree\b', r'\bfreestanding\b',
]

INTERMEDIATE_PATTERNS = [
    r'\bpull.?up\b', r'\bchin.?up\b', r'\bdip\b', r'\bpush.?up\b',
    r'\blunge\b', r'\bsquat\b', r'\bdeadlift\b', r'\brow\b',
    r'\bpress\b', r'\bcurl\b', r'\bextension\b', r'\braise\b',
    r'\bfly\b', r'\bflye\b', r'\brollout\b',
]

BEGINNER_PATTERNS = [
    r'\bstretch\b', r'\bstatic\b', r'\bhold\b', r'\bwall\b',
    r'\bseated\b', r'\blying\b', r'\bsupported\b', r'\bassisted\b',
    r'\bband.?assisted\b', r'\bmachine\b', r'\bcable\b',
]


def infer_difficulty(exercise_name: str, equipment: str, category: str) -> str:
    """
    Infer difficulty level based on exercise characteristics.

    Returns: 'Beginner', 'Intermediate', or 'Advanced'
    """
    name_lower = (exercise_name or '').lower()
    equip_lower = (equipment or '').lower()
    cat_lower = (category or '').lower()

    # Check for advanced patterns in name
    for pattern in ADVANCED_PATTERNS:
        if re.search(pattern, name_lower):
            return 'Advanced'

    # Check equipment-based difficulty
    for equip_key, difficulty in EQUIPMENT_DIFFICULTY.items():
        if equip_key in equip_lower:
            # Found equipment match, but check for name modifiers
            if difficulty == 'Beginner':
                # Check if name suggests intermediate
                for pattern in INTERMEDIATE_PATTERNS:
                    if re.search(pattern, name_lower):
                        return 'Intermediate'
                return 'Beginner'
            elif difficulty == 'Intermediate':
                # Check if name suggests advanced
                for pattern in ADVANCED_PATTERNS:
                    if re.search(pattern, name_lower):
                        return 'Advanced'
                return 'Intermediate'
            else:
                return difficulty

    # Check category-based difficulty
    if cat_lower in ['conditioning', 'plyometric', 'power']:
        return 'Intermediate'
    elif cat_lower in ['strength', 'hypertrophy']:
        return 'Intermediate'
    elif cat_lower in ['flexibility', 'mobility', 'stretching']:
        return 'Beginner'

    # Check beginner patterns
    for pattern in BEGINNER_PATTERNS:
        if re.search(pattern, name_lower):
            return 'Beginner'

    # Check intermediate patterns
    for pattern in INTERMEDIATE_PATTERNS:
        if re.search(pattern, name_lower):
            return 'Intermediate'

    # Default to Beginner (conservative - available to all users)
    return 'Beginner'


def backfill_difficulty():
    """Backfill difficulty_level for exercises that don't have it."""
    db = get_supabase().client

    # Get exercises without difficulty
    response = db.table("exercise_library").select(
        "id, exercise_name, equipment, category, difficulty_level"
    ).is_("difficulty_level", "null").execute()

    if not response.data:
        print("All exercises already have difficulty levels!")
        return

    print(f"Found {len(response.data)} exercises without difficulty level")

    # Track statistics
    stats = {'Beginner': 0, 'Intermediate': 0, 'Advanced': 0}
    updated_count = 0

    for exercise in response.data:
        exercise_id = exercise["id"]
        name = exercise.get("exercise_name", "")
        equipment = exercise.get("equipment", "")
        category = exercise.get("category", "")

        # Infer difficulty
        difficulty = infer_difficulty(name, equipment, category)
        stats[difficulty] += 1

        # Update database
        db.table("exercise_library").update({
            "difficulty_level": difficulty
        }).eq("id", exercise_id).execute()

        updated_count += 1

        if updated_count % 100 == 0:
            print(f"Updated {updated_count}/{len(response.data)} exercises...")

    print(f"\nDone! Updated {updated_count} exercises")
    print(f"\nDifficulty distribution:")
    for diff, count in sorted(stats.items()):
        print(f"  {diff}: {count}")

    print("\n\nIMPORTANT: Now reindex ChromaDB to apply changes:")
    print("  python scripts/reindex_chromadb.py")


def preview_inferences(limit: int = 20):
    """Preview what difficulties would be inferred without updating."""
    db = get_supabase().client

    response = db.table("exercise_library").select(
        "exercise_name, equipment, category"
    ).is_("difficulty_level", "null").limit(limit).execute()

    print(f"Preview of difficulty inferences (first {limit} exercises):\n")
    print(f"{'Exercise':<50} {'Equipment':<25} {'Inferred':<12}")
    print("-" * 90)

    for ex in response.data:
        name = ex.get("exercise_name", "")[:48]
        equip = (ex.get("equipment") or "N/A")[:23]
        cat = ex.get("category", "")
        difficulty = infer_difficulty(ex.get("exercise_name", ""), ex.get("equipment", ""), cat)
        print(f"{name:<50} {equip:<25} {difficulty:<12}")


def fix_advanced_exercises():
    """
    Fix exercises that should be Advanced but aren't.

    This scans ALL exercises (even those with difficulty set) and fixes any
    that match advanced patterns but aren't marked as Advanced.
    """
    db = get_supabase().client

    # Get ALL exercises
    response = db.table("exercise_library").select(
        "id, exercise_name, equipment, category, difficulty_level"
    ).execute()

    if not response.data:
        print("No exercises found!")
        return

    print(f"Scanning {len(response.data)} exercises for advanced patterns...")

    fixed_count = 0
    fixed_exercises = []

    for exercise in response.data:
        exercise_id = exercise["id"]
        name = exercise.get("exercise_name", "")
        equipment = exercise.get("equipment", "")
        category = exercise.get("category", "")
        current_difficulty = exercise.get("difficulty_level", "")

        # Check if name matches advanced patterns
        name_lower = name.lower()
        is_advanced = False
        matched_pattern = None

        for pattern in ADVANCED_PATTERNS:
            if re.search(pattern, name_lower):
                is_advanced = True
                matched_pattern = pattern
                break

        # If it's advanced but not marked as such, fix it
        if is_advanced and current_difficulty != "Advanced":
            db.table("exercise_library").update({
                "difficulty_level": "Advanced"
            }).eq("id", exercise_id).execute()

            fixed_count += 1
            fixed_exercises.append({
                "name": name,
                "old_difficulty": current_difficulty or "NULL",
                "pattern": matched_pattern
            })

            if fixed_count % 10 == 0:
                print(f"Fixed {fixed_count} exercises...")

    print(f"\n✅ Fixed {fixed_count} exercises to Advanced difficulty")

    if fixed_exercises:
        print("\nExercises that were fixed:")
        print(f"{'Exercise Name':<50} {'Old Difficulty':<15} {'Matched Pattern'}")
        print("-" * 90)
        for ex in fixed_exercises[:50]:  # Show first 50
            print(f"{ex['name'][:48]:<50} {ex['old_difficulty']:<15} {ex['pattern']}")

        if len(fixed_exercises) > 50:
            print(f"... and {len(fixed_exercises) - 50} more")

    print("\n\nIMPORTANT: Now reindex ChromaDB to apply changes:")
    print("  python scripts/reindex_chromadb.py")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Backfill exercise difficulty levels")
    parser.add_argument("--preview", action="store_true", help="Preview inferences without updating")
    parser.add_argument("--fix-advanced", action="store_true", help="Fix exercises that should be Advanced")
    parser.add_argument("--limit", type=int, default=20, help="Limit for preview mode")
    args = parser.parse_args()

    if args.preview:
        preview_inferences(args.limit)
    elif args.fix_advanced:
        print("=" * 60)
        print("Fix Advanced Exercises")
        print("=" * 60)
        fix_advanced_exercises()
    else:
        print("=" * 60)
        print("Exercise Difficulty Backfill")
        print("=" * 60)
        backfill_difficulty()
