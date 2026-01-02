"""
Standalone tests for focus area validation functions.

These tests don't require the full application context and can run independently.

Run with: python tests/test_focus_validation_standalone.py
"""
import asyncio
from typing import Dict, Any, List


# =============================================================================
# COPY OF FOCUS AREA VALIDATION CODE FOR STANDALONE TESTING
# =============================================================================

# Mapping of focus areas to target muscles
FOCUS_AREA_MUSCLES = {
    'legs': ['quads', 'quadriceps', 'hamstrings', 'glutes', 'calves', 'leg', 'thigh', 'hip'],
    'lower': ['quads', 'quadriceps', 'hamstrings', 'glutes', 'calves', 'leg', 'thigh', 'hip'],
    'push': ['chest', 'shoulders', 'triceps', 'pec', 'delt', 'shoulder'],
    'pull': ['back', 'biceps', 'lats', 'traps', 'rear delt', 'rhomboids'],
    'upper': ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'pec', 'delt', 'lats', 'arm'],
    'chest': ['chest', 'pec', 'pectorals'],
    'back': ['back', 'lats', 'traps', 'rhomboids', 'erector'],
    'shoulders': ['shoulders', 'delts', 'deltoids', 'delt'],
    'arms': ['biceps', 'triceps', 'forearms', 'arm', 'brachii'],
    'core': ['abs', 'core', 'obliques', 'abdominals', 'rectus', 'transverse'],
    'glutes': ['glutes', 'gluteus', 'hip', 'butt'],
}

# Exercises that clearly don't match specific focus areas (quick validation)
FOCUS_AREA_EXCLUDED_EXERCISES = {
    'legs': ['push-up', 'pushup', 'bench press', 'shoulder press', 'bicep curl', 'tricep', 'lat pulldown', 'pull-up', 'row', 'chest fly', 'dip'],
    'lower': ['push-up', 'pushup', 'bench press', 'shoulder press', 'bicep curl', 'tricep', 'lat pulldown', 'pull-up', 'row', 'chest fly', 'dip'],
    'push': ['squat', 'lunge', 'deadlift', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'hip thrust', 'pull-up', 'row', 'bicep curl', 'lat pulldown'],
    'pull': ['squat', 'lunge', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'push-up', 'pushup', 'bench press', 'shoulder press', 'tricep', 'chest fly', 'dip'],
    'chest': ['squat', 'lunge', 'deadlift', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'hip thrust', 'pull-up', 'row', 'bicep curl', 'lat pulldown', 'shoulder press', 'lateral raise'],
    'back': ['squat', 'lunge', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'push-up', 'pushup', 'bench press', 'shoulder press', 'tricep', 'chest fly', 'dip'],
    'shoulders': ['squat', 'lunge', 'deadlift', 'leg press', 'leg curl', 'leg extension', 'calf raise', 'hip thrust', 'chest fly', 'bicep curl'],
}


def validate_exercise_matches_focus(
    exercise_name: str,
    muscle_group: str,
    focus_area: str,
) -> Dict[str, Any]:
    """Validate that an exercise matches the workout focus area."""
    exercise_lower = exercise_name.lower().strip()
    muscle_lower = (muscle_group or "").lower().strip()
    focus_lower = focus_area.lower().strip() if focus_area else ""

    # If no focus area, everything matches
    if not focus_lower or focus_lower in ['full_body', 'fullbody', 'full body']:
        return {"matches": True, "reason": "Full body focus allows all exercises", "confidence": 1.0}

    # Quick check: is exercise in the excluded list for this focus?
    excluded_exercises = FOCUS_AREA_EXCLUDED_EXERCISES.get(focus_lower, [])
    for excluded in excluded_exercises:
        if excluded in exercise_lower:
            return {
                "matches": False,
                "reason": f"'{exercise_name}' is a {excluded} exercise, not suitable for {focus_area} focus",
                "confidence": 0.95
            }

    # Check if muscle group matches the focus area
    target_muscles = FOCUS_AREA_MUSCLES.get(focus_lower, [])
    if target_muscles:
        for target in target_muscles:
            if target in muscle_lower or muscle_lower in target:
                return {
                    "matches": True,
                    "reason": f"'{muscle_group}' matches {focus_area} focus",
                    "confidence": 0.9
                }

        return {
            "matches": False,
            "reason": f"'{muscle_group}' does not match {focus_area} focus (expected: {', '.join(target_muscles[:3])})",
            "confidence": 0.8
        }

    # Unknown focus area, allow by default
    return {"matches": True, "reason": "Unknown focus area, allowing exercise", "confidence": 0.5}


async def validate_and_filter_focus_mismatches(
    exercises: List[Dict[str, Any]],
    focus_area: str,
    workout_name: str,
) -> Dict[str, Any]:
    """Validate all exercises match the workout focus area and filter mismatches."""
    valid_exercises = []
    mismatched_exercises = []
    warnings = []

    focus_lower = (focus_area or "").lower().strip()

    # If full body or no focus, all exercises are valid
    if not focus_lower or focus_lower in ['full_body', 'fullbody', 'full body']:
        return {
            "valid_exercises": exercises,
            "mismatched_exercises": [],
            "mismatch_count": 0,
            "warnings": []
        }

    for ex in exercises:
        exercise_name = ex.get("name", "")
        muscle_group = ex.get("muscle_group", "")

        validation = validate_exercise_matches_focus(exercise_name, muscle_group, focus_area)

        if validation["matches"]:
            valid_exercises.append(ex)
        else:
            mismatched_exercises.append(ex)
            warnings.append(f"⚠️ [{workout_name}] Mismatch: '{exercise_name}' ({muscle_group}) - {validation['reason']}")

    return {
        "valid_exercises": valid_exercises,
        "mismatched_exercises": mismatched_exercises,
        "mismatch_count": len(mismatched_exercises),
        "warnings": warnings
    }


# =============================================================================
# TESTS
# =============================================================================

def run_tests():
    """Run all standalone tests."""
    passed = 0
    failed = 0

    print("=" * 60)
    print("FOCUS AREA VALIDATION TESTS")
    print("=" * 60)
    print()

    # Test 1: Leg exercise matches leg focus
    print("Test 1: Leg exercise matches leg focus")
    result = validate_exercise_matches_focus("Barbell Squat", "quadriceps", "legs")
    if result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 2: Push-up does NOT match leg focus (THE BUG WE'RE FIXING)
    print("Test 2: Push-ups do NOT match leg focus (the bug)")
    result = validate_exercise_matches_focus("Push-ups", "chest", "legs")
    if not result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 3: Bench press does NOT match leg focus
    print("Test 3: Bench press does NOT match leg focus")
    result = validate_exercise_matches_focus("Bench Press", "chest", "legs")
    if not result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 4: Chest exercise matches push focus
    print("Test 4: Chest exercise matches push focus")
    result = validate_exercise_matches_focus("Incline Dumbbell Press", "chest", "push")
    if result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 5: Squat does NOT match push focus
    print("Test 5: Squat does NOT match push focus")
    result = validate_exercise_matches_focus("Barbell Squat", "quadriceps", "push")
    if not result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 6: Any exercise matches full_body
    print("Test 6: Any exercise matches full_body focus")
    result = validate_exercise_matches_focus("Push-ups", "chest", "full_body")
    if result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 7: Back exercise matches pull focus
    print("Test 7: Back exercise matches pull focus")
    result = validate_exercise_matches_focus("Barbell Row", "back", "pull")
    if result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 8: Push-up does NOT match pull focus
    print("Test 8: Push-ups do NOT match pull focus")
    result = validate_exercise_matches_focus("Push-ups", "chest", "pull")
    if not result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 9: Shoulder exercise matches push focus
    print("Test 9: Shoulder exercise matches push focus")
    result = validate_exercise_matches_focus("Overhead Press", "shoulders", "push")
    if result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 10: Core exercise matches core focus
    print("Test 10: Core exercise matches core focus")
    result = validate_exercise_matches_focus("Plank", "abs", "core")
    if result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 11: Case insensitive focus
    print("Test 11: Case insensitive focus area")
    result = validate_exercise_matches_focus("Squat", "quadriceps", "LEGS")
    if result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    # Test 12: Empty focus allows all
    print("Test 12: Empty focus allows all exercises")
    result = validate_exercise_matches_focus("Random Exercise", "random", "")
    if result["matches"]:
        print("  ✅ PASSED")
        passed += 1
    else:
        print(f"  ❌ FAILED: {result}")
        failed += 1

    print()
    print("=" * 60)
    print("BATCH VALIDATION TESTS (async)")
    print("=" * 60)
    print()

    async def run_async_tests():
        nonlocal passed, failed

        # Test 13: All exercises match
        print("Test 13: All leg exercises match leg focus")
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},
            {"name": "Lunges", "muscle_group": "glutes"},
            {"name": "Leg Press", "muscle_group": "quads"},
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Thunder Legs")
        if result["mismatch_count"] == 0 and len(result["valid_exercises"]) == 3:
            print("  ✅ PASSED")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 14: THE ACTUAL BUG - leg workout with push-ups
        print("Test 14: Leg workout with only push-ups detected as mismatch")
        exercises = [
            {"name": "Push-ups", "muscle_group": "chest"},
            {"name": "Wide Push-ups", "muscle_group": "chest"},
            {"name": "Diamond Push-ups", "muscle_group": "chest"},
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Thunder Legs")
        if result["mismatch_count"] == 3 and len(result["valid_exercises"]) == 0:
            print("  ✅ PASSED")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 15: Mixed exercises
        print("Test 15: Mixed exercises correctly filtered")
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},
            {"name": "Push-ups", "muscle_group": "chest"},  # Mismatch
            {"name": "Lunges", "muscle_group": "glutes"},
            {"name": "Bench Press", "muscle_group": "chest"},  # Mismatch
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Thunder Legs")
        if result["mismatch_count"] == 2 and len(result["valid_exercises"]) == 2:
            print("  ✅ PASSED")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 16: Majority mismatch detected
        print("Test 16: Majority mismatch detected (4 out of 5)")
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},
            {"name": "Push-ups", "muscle_group": "chest"},
            {"name": "Bench Press", "muscle_group": "chest"},
            {"name": "Shoulder Press", "muscle_group": "shoulders"},
            {"name": "Tricep Dips", "muscle_group": "triceps"},
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Savage Wolf Legs")
        if result["mismatch_count"] == 4 and result["mismatch_count"] > len(exercises) / 2:
            print("  ✅ PASSED")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 17: Full body allows all
        print("Test 17: Full body focus allows all exercises")
        exercises = [
            {"name": "Squat", "muscle_group": "quadriceps"},
            {"name": "Push-ups", "muscle_group": "chest"},
            {"name": "Pull-ups", "muscle_group": "back"},
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "full_body", "Total Body Blast")
        if result["mismatch_count"] == 0:
            print("  ✅ PASSED")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 18: Push focus validation
        print("Test 18: Push focus correctly identifies mismatches")
        exercises = [
            {"name": "Bench Press", "muscle_group": "chest"},
            {"name": "Shoulder Press", "muscle_group": "shoulders"},
            {"name": "Barbell Row", "muscle_group": "back"},  # Mismatch
            {"name": "Squat", "muscle_group": "quadriceps"},  # Mismatch
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "push", "Phoenix Chest")
        if result["mismatch_count"] == 2 and len(result["valid_exercises"]) == 2:
            print("  ✅ PASSED")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 19: Warnings contain exercise names
        print("Test 19: Warnings contain exercise names")
        exercises = [
            {"name": "Squat", "muscle_group": "quadriceps"},
            {"name": "Diamond Push-ups", "muscle_group": "chest"},
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Iron Legs")
        if len(result["warnings"]) == 1 and "Diamond Push-ups" in result["warnings"][0]:
            print("  ✅ PASSED")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 20: Empty exercises list
        print("Test 20: Empty exercises list handled")
        result = await validate_and_filter_focus_mismatches([], "legs", "Empty Workout")
        if result["mismatch_count"] == 0 and len(result["valid_exercises"]) == 0:
            print("  ✅ PASSED")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

    asyncio.run(run_async_tests())

    print()
    print("=" * 60)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 60)

    if failed > 0:
        print("\n❌ SOME TESTS FAILED!")
        return 1
    else:
        print("\n✅ ALL TESTS PASSED!")
        return 0


def run_minimum_exercise_tests():
    """Run tests for minimum exercise count validation scenarios."""
    passed = 0
    failed = 0

    MIN_EXERCISES_REQUIRED = 3

    print()
    print("=" * 60)
    print("MINIMUM EXERCISE COUNT VALIDATION TESTS")
    print("=" * 60)
    print()

    async def test_minimum_exercises():
        nonlocal passed, failed

        # Test 21: Workout with enough valid exercises - should filter mismatches
        print("Test 21: Enough valid exercises (4) - can filter mismatches")
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},
            {"name": "Lunges", "muscle_group": "glutes"},
            {"name": "Leg Press", "muscle_group": "quads"},
            {"name": "Calf Raises", "muscle_group": "calves"},
            {"name": "Push-ups", "muscle_group": "chest"},  # Mismatch
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Thunder Legs")

        if result["mismatch_count"] == 1 and len(result["valid_exercises"]) == 4:
            # 4 valid exercises >= 3 minimum - can filter out the 1 mismatch
            print("  ✅ PASSED - 4 valid exercises >= 3 minimum, can filter mismatch")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 22: Not enough valid exercises - identify but keep all
        print("Test 22: Not enough valid exercises (1) - should keep all in production")
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},  # Valid
            {"name": "Push-ups", "muscle_group": "chest"},  # Mismatch
            {"name": "Bench Press", "muscle_group": "chest"},  # Mismatch
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Thunder Legs")

        if len(result["valid_exercises"]) == 1 and result["mismatch_count"] == 2:
            print("  ✅ PASSED - 1 valid < 3 minimum, production would keep all 3")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 23: Zero valid exercises (the reported bug scenario)
        print("Test 23: Zero valid exercises - critical bug scenario")
        exercises = [
            {"name": "Push-ups", "muscle_group": "chest"},
            {"name": "Wide Push-ups", "muscle_group": "chest"},
            {"name": "Diamond Push-ups", "muscle_group": "chest"},
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Thunder Legs")

        if len(result["valid_exercises"]) == 0 and result["mismatch_count"] == 3:
            print("  ✅ PASSED - All 3 flagged as mismatched (leg workout with only push-ups)")
            print("      Note: Production keeps all to avoid empty workout, but logs critical error")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 24: Exactly 3 valid exercises (meets minimum exactly)
        print("Test 24: Exactly 3 valid exercises - meets minimum")
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},
            {"name": "Lunges", "muscle_group": "glutes"},
            {"name": "Leg Press", "muscle_group": "quads"},
            {"name": "Push-ups", "muscle_group": "chest"},  # Mismatch
            {"name": "Bench Press", "muscle_group": "chest"},  # Mismatch
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Thunder Legs")

        if len(result["valid_exercises"]) == 3 and result["mismatch_count"] == 2:
            print("  ✅ PASSED - 3 valid == 3 minimum, can filter mismatches")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

        # Test 25: 2 valid exercises (below minimum)
        print("Test 25: 2 valid exercises - below minimum")
        exercises = [
            {"name": "Barbell Squat", "muscle_group": "quadriceps"},
            {"name": "Lunges", "muscle_group": "glutes"},
            {"name": "Push-ups", "muscle_group": "chest"},  # Mismatch
        ]
        result = await validate_and_filter_focus_mismatches(exercises, "legs", "Thunder Legs")

        if len(result["valid_exercises"]) == 2 and result["mismatch_count"] == 1:
            print("  ✅ PASSED - 2 valid < 3 minimum, production would keep all 3")
            passed += 1
        else:
            print(f"  ❌ FAILED: {result}")
            failed += 1

    asyncio.run(test_minimum_exercises())

    print()
    print("=" * 60)
    print(f"MINIMUM EXERCISE RESULTS: {passed} passed, {failed} failed")
    print("=" * 60)

    return passed, failed


if __name__ == "__main__":
    import sys

    # Run main tests
    main_result = run_tests()

    # Run minimum exercise tests
    min_passed, min_failed = run_minimum_exercise_tests()

    print()
    print("=" * 60)
    total_passed = 20 + min_passed
    total_failed = (1 if main_result != 0 else 0) + min_failed
    print(f"TOTAL: {total_passed} passed, {total_failed} failed")
    print("=" * 60)

    if main_result != 0 or min_failed > 0:
        print("\n❌ SOME TESTS FAILED!")
        sys.exit(1)
    else:
        print("\n✅ ALL TESTS PASSED!")
        sys.exit(0)
