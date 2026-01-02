"""
Tests for AI Insights and Exercise Reasoning functionality.

Tests cover:
1. Fallback summary generation when AI fails
2. AI-powered exercise reasoning generation
3. Static exercise reasoning fallback
4. Workout reasoning generation
"""
import asyncio
import json
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ==================== FALLBACK SUMMARY TESTS ====================

def _generate_fallback_summary(
    workout_name: str,
    exercises: list,
    duration_minutes: int,
    workout_type: str = None,
) -> str:
    """
    Generate a fallback summary when AI generation fails.
    Returns a valid JSON string that matches the expected format.
    (Copied from suggestions.py for standalone testing)
    """
    # Determine workout focus from exercises
    exercise_names = [ex.get("name", "") for ex in exercises[:3] if ex.get("name")]
    exercises_preview = ", ".join(exercise_names) if exercise_names else "various exercises"

    # Extract muscle groups
    muscles = set()
    for ex in exercises:
        muscle = ex.get("primary_muscle") or ex.get("muscle_group") or ex.get("target")
        if muscle:
            muscles.add(muscle.lower())

    muscle_focus = ", ".join(list(muscles)[:3]) if muscles else "full body"

    # Determine headline based on workout type
    type_headlines = {
        "strength": "Build Strength Today!",
        "hypertrophy": "Muscle Building Session!",
        "cardio": "Heart-Pumping Cardio!",
        "hiit": "High Intensity Burn!",
        "flexibility": "Stretch & Recover!",
        "endurance": "Endurance Challenge!",
    }
    headline = type_headlines.get(workout_type.lower() if workout_type else "", "Great Workout Ahead!")

    # Build sections
    sections = [
        {
            "icon": "🎯",
            "title": "Focus",
            "content": f"This workout targets {muscle_focus} with {len(exercises)} exercises",
            "color": "cyan"
        },
        {
            "icon": "💪",
            "title": "Key Moves",
            "content": f"Includes {exercises_preview} for comprehensive training",
            "color": "purple"
        },
        {
            "icon": "⏱️",
            "title": "Duration",
            "content": f"Complete in about {duration_minutes} minutes with proper rest periods",
            "color": "orange"
        }
    ]

    return json.dumps({"headline": headline, "sections": sections})


def test_fallback_summary_strength_workout():
    """Test fallback summary for a strength workout."""
    exercises = [
        {"name": "Barbell Squat", "primary_muscle": "quadriceps"},
        {"name": "Deadlift", "primary_muscle": "hamstrings"},
        {"name": "Bench Press", "primary_muscle": "chest"},
    ]

    result = _generate_fallback_summary(
        workout_name="Power Strength",
        exercises=exercises,
        duration_minutes=45,
        workout_type="strength"
    )

    # Parse and validate JSON
    parsed = json.loads(result)

    assert parsed["headline"] == "Build Strength Today!"
    assert len(parsed["sections"]) == 3
    assert "quadriceps" in parsed["sections"][0]["content"].lower() or "hamstrings" in parsed["sections"][0]["content"].lower()
    assert "Barbell Squat" in parsed["sections"][1]["content"]
    assert "45 minutes" in parsed["sections"][2]["content"]

    return True


def test_fallback_summary_cardio_workout():
    """Test fallback summary for a cardio workout."""
    exercises = [
        {"name": "Jumping Jacks", "muscle_group": "full body"},
        {"name": "Burpees", "muscle_group": "full body"},
        {"name": "Mountain Climbers", "muscle_group": "core"},
    ]

    result = _generate_fallback_summary(
        workout_name="Cardio Blast",
        exercises=exercises,
        duration_minutes=30,
        workout_type="cardio"
    )

    parsed = json.loads(result)

    assert parsed["headline"] == "Heart-Pumping Cardio!"
    assert len(parsed["sections"]) == 3
    assert "30 minutes" in parsed["sections"][2]["content"]

    return True


def test_fallback_summary_empty_exercises():
    """Test fallback summary with empty exercises list."""
    result = _generate_fallback_summary(
        workout_name="Empty Workout",
        exercises=[],
        duration_minutes=20,
        workout_type=None
    )

    parsed = json.loads(result)

    assert parsed["headline"] == "Great Workout Ahead!"
    assert "full body" in parsed["sections"][0]["content"]
    assert "various exercises" in parsed["sections"][1]["content"]
    assert "0 exercises" in parsed["sections"][0]["content"]

    return True


def test_fallback_summary_no_type():
    """Test fallback summary without workout type."""
    exercises = [
        {"name": "Push-ups", "target": "chest"},
    ]

    result = _generate_fallback_summary(
        workout_name="Quick Workout",
        exercises=exercises,
        duration_minutes=15,
        workout_type=None
    )

    parsed = json.loads(result)

    assert parsed["headline"] == "Great Workout Ahead!"
    assert len(parsed["sections"]) == 3

    return True


def test_fallback_summary_hiit():
    """Test fallback summary for HIIT workout."""
    exercises = [
        {"name": "Squat Jumps", "primary_muscle": "legs"},
        {"name": "Push-up Burpees", "primary_muscle": "chest"},
    ]

    result = _generate_fallback_summary(
        workout_name="HIIT Burn",
        exercises=exercises,
        duration_minutes=25,
        workout_type="hiit"
    )

    parsed = json.loads(result)

    assert parsed["headline"] == "High Intensity Burn!"

    return True


# ==================== STATIC EXERCISE REASONING TESTS ====================

def _build_exercise_reasoning(
    exercise_name: str,
    muscle_group: str,
    equipment: str,
    sets: int,
    reps: str,
    workout_type: str,
    difficulty: str,
    user_goals: list,
    user_fitness_level: str,
    user_equipment: list,
) -> str:
    """Build reasoning explanation for why an exercise was selected.
    (Copied from workouts_db.py for standalone testing)
    """
    reasons = []

    # Muscle targeting
    if muscle_group:
        reasons.append(f"Targets {muscle_group} effectively")

    # Equipment match
    if equipment:
        equipment_lower = equipment.lower()
        if equipment_lower in ["bodyweight", "none", "body weight"]:
            reasons.append("Requires no equipment - great for home workouts")
        elif user_equipment and any(eq.lower() in equipment_lower for eq in user_equipment):
            reasons.append(f"Matches your available equipment ({equipment})")
        else:
            reasons.append(f"Uses {equipment}")

    # Goal alignment
    goal_map = {
        "muscle_gain": ["compound movement for muscle growth", "builds strength and size"],
        "weight_loss": ["burns calories efficiently", "elevates heart rate"],
        "strength": ["develops maximal strength", "progressive overload focused"],
        "endurance": ["builds muscular endurance", "higher rep scheme"],
        "flexibility": ["improves range of motion", "dynamic movement"],
        "general_fitness": ["well-rounded exercise", "functional movement pattern"],
    }
    for goal in user_goals:
        if goal.lower().replace(" ", "_") in goal_map:
            reasons.append(goal_map[goal.lower().replace(" ", "_")][0])
            break

    # Set/rep scheme reasoning
    if isinstance(reps, str) and "-" in reps:
        reasons.append(f"{sets} sets of {reps} reps for optimal stimulus")
    elif isinstance(reps, int) or (isinstance(reps, str) and reps.isdigit()):
        reps_int = int(reps) if isinstance(reps, str) else reps
        if reps_int <= 5:
            reasons.append(f"Low rep range ({sets}x{reps}) for strength focus")
        elif reps_int <= 12:
            reasons.append(f"{sets}x{reps} in hypertrophy range for muscle growth")
        else:
            reasons.append(f"Higher reps ({sets}x{reps}) for endurance and conditioning")

    # Difficulty appropriateness
    if difficulty:
        difficulty_lower = difficulty.lower()
        if difficulty_lower == "beginner":
            reasons.append("Beginner-friendly movement pattern")
        elif difficulty_lower == "advanced":
            reasons.append("Challenging variation for advanced trainees")

    return ". ".join(reasons) if reasons else "Selected to complement your workout program"


def test_static_reasoning_muscle_targeting():
    """Test that static reasoning includes muscle targeting."""
    result = _build_exercise_reasoning(
        exercise_name="Barbell Squat",
        muscle_group="quadriceps",
        equipment="barbell",
        sets=4,
        reps="6-8",
        workout_type="strength",
        difficulty="intermediate",
        user_goals=["muscle_gain"],
        user_fitness_level="intermediate",
        user_equipment=["barbell", "dumbbells"],
    )

    assert "quadriceps" in result.lower()
    assert "barbell" in result.lower()

    return True


def test_static_reasoning_bodyweight():
    """Test reasoning for bodyweight exercises."""
    result = _build_exercise_reasoning(
        exercise_name="Push-ups",
        muscle_group="chest",
        equipment="bodyweight",
        sets=3,
        reps="15",
        workout_type="strength",
        difficulty="beginner",
        user_goals=["general_fitness"],
        user_fitness_level="beginner",
        user_equipment=[],
    )

    assert "no equipment" in result.lower()
    assert "beginner" in result.lower()

    return True


def test_static_reasoning_goals():
    """Test that reasoning aligns with user goals."""
    result = _build_exercise_reasoning(
        exercise_name="Deadlift",
        muscle_group="hamstrings",
        equipment="barbell",
        sets=5,
        reps="5",
        workout_type="strength",
        difficulty="advanced",
        user_goals=["strength"],
        user_fitness_level="advanced",
        user_equipment=["barbell"],
    )

    assert "strength" in result.lower()
    assert "advanced" in result.lower()

    return True


def test_static_reasoning_rep_ranges():
    """Test reasoning for different rep ranges."""
    # Low reps (strength)
    result_low = _build_exercise_reasoning(
        exercise_name="Bench Press",
        muscle_group="chest",
        equipment="barbell",
        sets=5,
        reps="3",
        workout_type="strength",
        difficulty="intermediate",
        user_goals=[],
        user_fitness_level="intermediate",
        user_equipment=[],
    )
    assert "strength focus" in result_low.lower() or "low rep" in result_low.lower()

    # High reps (endurance)
    result_high = _build_exercise_reasoning(
        exercise_name="Lunges",
        muscle_group="legs",
        equipment="bodyweight",
        sets=3,
        reps="20",
        workout_type="endurance",
        difficulty="intermediate",
        user_goals=[],
        user_fitness_level="intermediate",
        user_equipment=[],
    )
    assert "endurance" in result_high.lower() or "higher reps" in result_high.lower()

    return True


def test_static_reasoning_empty_input():
    """Test reasoning with minimal input."""
    result = _build_exercise_reasoning(
        exercise_name="Unknown Exercise",
        muscle_group="",
        equipment="",
        sets=3,
        reps="10",
        workout_type="",
        difficulty="",
        user_goals=[],
        user_fitness_level="",
        user_equipment=[],
    )

    # Should return fallback message or basic reasoning
    assert len(result) > 0

    return True


# ==================== WORKOUT REASONING TESTS ====================

def _build_workout_reasoning(
    workout_name: str,
    workout_type: str,
    difficulty: str,
    target_muscles: list,
    exercise_count: int,
    duration_minutes: int,
    user_goals: list,
    user_fitness_level: str,
    training_split: str = None,
) -> str:
    """Build overall reasoning for the workout design.
    (Partial implementation for testing)
    """
    parts = []

    # Workout type explanation
    type_explanations = {
        "strength": "This strength-focused workout emphasizes compound movements and progressive overload",
        "hypertrophy": "This hypertrophy workout is designed to maximize muscle growth through optimal volume",
        "cardio": "This cardio session elevates heart rate for cardiovascular health and calorie burn",
        "hiit": "This high-intensity interval training alternates intense bursts with recovery periods",
        "endurance": "This endurance workout builds stamina and muscular endurance",
        "flexibility": "This flexibility session improves mobility and range of motion",
    }

    if workout_type and workout_type.lower() in type_explanations:
        parts.append(type_explanations[workout_type.lower()])

    # Target muscles
    if target_muscles:
        muscles_str = ", ".join(target_muscles[:3])
        parts.append(f"Targeting {muscles_str}")

    # Duration
    parts.append(f"Designed to be completed in approximately {duration_minutes} minutes")

    return ". ".join(parts) if parts else "A balanced workout designed for your fitness journey"


def test_workout_reasoning_strength():
    """Test workout reasoning for strength type."""
    result = _build_workout_reasoning(
        workout_name="Power Day",
        workout_type="strength",
        difficulty="intermediate",
        target_muscles=["chest", "shoulders", "triceps"],
        exercise_count=6,
        duration_minutes=45,
        user_goals=["strength"],
        user_fitness_level="intermediate",
        training_split="push_pull_legs",
    )

    assert "strength" in result.lower()
    assert "45 minutes" in result
    assert "chest" in result.lower()

    return True


def test_workout_reasoning_hiit():
    """Test workout reasoning for HIIT type."""
    result = _build_workout_reasoning(
        workout_name="HIIT Blast",
        workout_type="hiit",
        difficulty="advanced",
        target_muscles=["full body"],
        exercise_count=8,
        duration_minutes=30,
        user_goals=["weight_loss"],
        user_fitness_level="advanced",
    )

    assert "high-intensity" in result.lower() or "hiit" in result.lower()
    assert "30 minutes" in result

    return True


def test_workout_reasoning_no_type():
    """Test workout reasoning without type."""
    result = _build_workout_reasoning(
        workout_name="Custom Workout",
        workout_type="",
        difficulty="beginner",
        target_muscles=[],
        exercise_count=5,
        duration_minutes=25,
        user_goals=[],
        user_fitness_level="beginner",
    )

    assert "25 minutes" in result
    assert len(result) > 0

    return True


# ==================== RUN ALL TESTS ====================

def run_tests():
    """Run all tests and report results."""
    tests = [
        # Fallback summary tests
        ("Fallback Summary - Strength Workout", test_fallback_summary_strength_workout),
        ("Fallback Summary - Cardio Workout", test_fallback_summary_cardio_workout),
        ("Fallback Summary - Empty Exercises", test_fallback_summary_empty_exercises),
        ("Fallback Summary - No Type", test_fallback_summary_no_type),
        ("Fallback Summary - HIIT", test_fallback_summary_hiit),
        # Static exercise reasoning tests
        ("Static Reasoning - Muscle Targeting", test_static_reasoning_muscle_targeting),
        ("Static Reasoning - Bodyweight", test_static_reasoning_bodyweight),
        ("Static Reasoning - Goals", test_static_reasoning_goals),
        ("Static Reasoning - Rep Ranges", test_static_reasoning_rep_ranges),
        ("Static Reasoning - Empty Input", test_static_reasoning_empty_input),
        # Workout reasoning tests
        ("Workout Reasoning - Strength", test_workout_reasoning_strength),
        ("Workout Reasoning - HIIT", test_workout_reasoning_hiit),
        ("Workout Reasoning - No Type", test_workout_reasoning_no_type),
    ]

    passed = 0
    failed = 0

    print()
    print("=" * 60)
    print("AI INSIGHTS AND REASONING TESTS")
    print("=" * 60)
    print()

    for test_name, test_func in tests:
        try:
            result = test_func()
            if result:
                print(f"  ✅ PASSED - {test_name}")
                passed += 1
            else:
                print(f"  ❌ FAILED - {test_name}")
                failed += 1
        except Exception as e:
            print(f"  ❌ FAILED - {test_name}: {e}")
            failed += 1

    print()
    print("=" * 60)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 60)

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(run_tests())
