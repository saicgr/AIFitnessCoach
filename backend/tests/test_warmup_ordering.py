"""Tests for warmup exercise ordering.

This tests the feature that addresses user feedback:
"warm-ups should have static holds early, not intermixed with kinetic moves,
I'm trying to gradually increase my heart rate through movement, not stay stock still."
"""

import pytest
from services.warmup_stretch_service import (
    classify_movement_type,
    order_warmup_exercises,
    STATIC_EXERCISE_KEYWORDS,
    DYNAMIC_EXERCISE_KEYWORDS,
)


class TestMovementTypeClassification:
    """Tests for exercise movement type classification."""

    def test_static_exercises_identified(self):
        """Static hold exercises should be classified as 'static'."""
        static_exercises = [
            "Plank Hold",
            "Wall Sit",
            "Dead Hang",
            "Isometric Squat",
            "Static Lunge Hold",
            "L-Sit",
            "Hollow Body Hold",
            "Glute Bridge Hold",
        ]

        for exercise in static_exercises:
            result = classify_movement_type(exercise)
            assert result == "static", f"'{exercise}' should be classified as static, got {result}"

    def test_dynamic_exercises_identified(self):
        """Dynamic movement exercises should be classified as 'dynamic'."""
        dynamic_exercises = [
            "Jumping Jacks",
            "Arm Circles",
            "Leg Swings",
            "High Knees",
            "Butt Kicks",
            "Torso Rotation",
            "Walking Lunges",
            "Inchworm",
            "Mountain Climbers",
        ]

        for exercise in dynamic_exercises:
            result = classify_movement_type(exercise)
            assert result == "dynamic", f"'{exercise}' should be classified as dynamic, got {result}"

    def test_unknown_exercises_default_to_dynamic(self):
        """Unknown exercises should default to dynamic for warmups."""
        unknown_exercises = [
            "Some Random Exercise",
            "Mystery Move",
            "Warmup Thing",
        ]

        for exercise in unknown_exercises:
            result = classify_movement_type(exercise)
            assert result == "dynamic", f"Unknown exercise '{exercise}' should default to dynamic"

    def test_case_insensitive_matching(self):
        """Classification should be case-insensitive."""
        assert classify_movement_type("PLANK HOLD") == "static"
        assert classify_movement_type("plank hold") == "static"
        assert classify_movement_type("Plank Hold") == "static"
        assert classify_movement_type("JUMPING JACKS") == "dynamic"
        assert classify_movement_type("jumping jacks") == "dynamic"


class TestWarmupOrdering:
    """Tests for warmup exercise ordering."""

    def test_static_exercises_come_first(self):
        """Static exercises should be ordered before dynamic exercises."""
        exercises = [
            {"name": "Jumping Jacks"},  # dynamic
            {"name": "Plank Hold"},     # static
            {"name": "Arm Circles"},    # dynamic
            {"name": "Wall Sit"},       # static
            {"name": "High Knees"},     # dynamic
        ]

        ordered = order_warmup_exercises(exercises)

        # First exercises should be static
        assert ordered[0]["name"] == "Plank Hold" or ordered[0]["name"] == "Wall Sit"
        assert ordered[1]["name"] == "Plank Hold" or ordered[1]["name"] == "Wall Sit"

        # Last exercises should be dynamic
        dynamic_names = ["Jumping Jacks", "Arm Circles", "High Knees"]
        assert ordered[2]["name"] in dynamic_names
        assert ordered[3]["name"] in dynamic_names
        assert ordered[4]["name"] in dynamic_names

    def test_all_static_exercises(self):
        """All static exercises should maintain order."""
        exercises = [
            {"name": "Plank Hold"},
            {"name": "Wall Sit"},
            {"name": "Dead Hang"},
        ]

        ordered = order_warmup_exercises(exercises)
        assert len(ordered) == 3
        # All should be classified as static and appear
        names = [e["name"] for e in ordered]
        assert "Plank Hold" in names
        assert "Wall Sit" in names
        assert "Dead Hang" in names

    def test_all_dynamic_exercises(self):
        """All dynamic exercises should maintain order."""
        exercises = [
            {"name": "Jumping Jacks"},
            {"name": "Arm Circles"},
            {"name": "High Knees"},
        ]

        ordered = order_warmup_exercises(exercises)
        assert len(ordered) == 3
        names = [e["name"] for e in ordered]
        assert "Jumping Jacks" in names
        assert "Arm Circles" in names
        assert "High Knees" in names

    def test_empty_list(self):
        """Empty exercise list should return empty list."""
        ordered = order_warmup_exercises([])
        assert ordered == []

    def test_single_exercise(self):
        """Single exercise should be returned unchanged."""
        exercises = [{"name": "Plank Hold"}]
        ordered = order_warmup_exercises(exercises)
        assert len(ordered) == 1
        assert ordered[0]["name"] == "Plank Hold"

    def test_preserves_exercise_data(self):
        """Ordering should preserve all exercise data."""
        exercises = [
            {
                "name": "Jumping Jacks",
                "sets": 1,
                "reps": 20,
                "duration_seconds": 60,
                "notes": "Keep a steady pace"
            },
            {
                "name": "Plank Hold",
                "sets": 1,
                "reps": 1,
                "duration_seconds": 30,
                "notes": "Maintain flat back"
            },
        ]

        ordered = order_warmup_exercises(exercises)

        # Plank should be first (static)
        assert ordered[0]["name"] == "Plank Hold"
        assert ordered[0]["duration_seconds"] == 30
        assert ordered[0]["notes"] == "Maintain flat back"

        # Jumping Jacks should be second (dynamic)
        assert ordered[1]["name"] == "Jumping Jacks"
        assert ordered[1]["reps"] == 20


class TestStaticExerciseKeywords:
    """Tests for static exercise keyword coverage."""

    def test_common_static_holds_covered(self):
        """Common static hold exercises should have matching keywords."""
        common_static = [
            "plank",
            "wall sit",
            "dead hang",
            "isometric",
            "static",
            "l-sit",
            "hollow",
        ]

        for exercise_type in common_static:
            found = any(keyword in exercise_type for keyword in STATIC_EXERCISE_KEYWORDS)
            assert found, f"Static exercise type '{exercise_type}' should have a matching keyword"


class TestDynamicExerciseKeywords:
    """Tests for dynamic exercise keyword coverage."""

    def test_common_dynamic_movements_covered(self):
        """Common dynamic warmup movements should have matching keywords."""
        common_dynamic = [
            "jumping jacks",
            "arm circles",
            "leg swings",
            "high knees",
            "butt kicks",
            "torso rotation",
        ]

        for exercise_type in common_dynamic:
            found = any(keyword in exercise_type for keyword in DYNAMIC_EXERCISE_KEYWORDS)
            assert found, f"Dynamic exercise type '{exercise_type}' should have a matching keyword"


# Integration test (requires service instantiation)
class TestWarmupServiceIntegration:
    """Integration tests for warmup ordering in the service."""

    @pytest.mark.asyncio
    async def test_generated_warmups_are_ordered(self):
        """Generated warmups should have static exercises before dynamic ones."""
        # This test would require mocking the Gemini API
        # For now, we test the ordering function directly
        sample_ai_response = [
            {"name": "Arm Circles", "sets": 1, "reps": 15},
            {"name": "Plank Hold", "sets": 1, "reps": 1},
            {"name": "High Knees", "sets": 1, "reps": 20},
            {"name": "Wall Sit", "sets": 1, "reps": 1},
        ]

        ordered = order_warmup_exercises(sample_ai_response)

        # First two should be static (Plank Hold, Wall Sit)
        first_two_names = {ordered[0]["name"], ordered[1]["name"]}
        assert first_two_names == {"Plank Hold", "Wall Sit"}

        # Last two should be dynamic
        last_two_names = {ordered[2]["name"], ordered[3]["name"]}
        assert last_two_names == {"Arm Circles", "High Knees"}
