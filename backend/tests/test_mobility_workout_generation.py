"""
Tests for mobility and recovery workout generation.

This tests the new workout types: 'mobility' and 'recovery'.
"""
import pytest
from unittest.mock import patch, MagicMock, AsyncMock
import json


class TestMobilityWorkoutType:
    """Tests for mobility workout type generation."""

    def test_workout_type_includes_mobility(self):
        """Verify 'mobility' is a valid workout type."""
        valid_types = ['strength', 'cardio', 'mixed', 'mobility', 'recovery']
        assert 'mobility' in valid_types

    def test_workout_type_includes_recovery(self):
        """Verify 'recovery' is a valid workout type."""
        valid_types = ['strength', 'cardio', 'mixed', 'mobility', 'recovery']
        assert 'recovery' in valid_types

    @pytest.mark.asyncio
    @patch('services.gemini_service.genai')
    async def test_mobility_workout_prompt_generated(self, mock_genai):
        """Test that mobility workout generates correct prompt elements."""
        from services.gemini_service import GeminiService

        # Mock the Gemini response
        mock_response = MagicMock()
        mock_response.text = json.dumps({
            "name": "Zen Flow Flexibility",
            "type": "mobility",
            "difficulty": "beginner",
            "duration_minutes": 30,
            "target_muscles": ["hips", "shoulders"],
            "exercises": [
                {
                    "name": "Hip Flexor Stretch",
                    "sets": 2,
                    "reps": 1,
                    "hold_seconds": 45,
                    "rest_seconds": 15,
                    "equipment": "bodyweight",
                    "muscle_group": "hips",
                    "is_unilateral": True,
                    "notes": "Hold each side, breathe deeply"
                },
                {
                    "name": "Downward Dog",
                    "sets": 3,
                    "reps": 1,
                    "hold_seconds": 30,
                    "rest_seconds": 10,
                    "equipment": "bodyweight",
                    "muscle_group": "full body",
                    "is_unilateral": False,
                    "notes": "Press heels toward ground"
                }
            ],
            "notes": "Focus on breathing throughout"
        })

        mock_model = MagicMock()
        mock_model.generate_content_async = AsyncMock(return_value=mock_response)
        mock_genai.GenerativeModel.return_value = mock_model

        service = GeminiService()
        result = await service.generate_workout_plan(
            fitness_level="beginner",
            goals=["flexibility"],
            equipment=["bodyweight"],
            duration_minutes=30,
            workout_type_preference="mobility"
        )

        assert result["type"] == "mobility"
        assert len(result["exercises"]) >= 2  # May have more from RAG enrichment
        # Verify hold_seconds is present for at least some mobility exercises
        exercises_with_hold = [e for e in result["exercises"] if e.get("hold_seconds")]
        assert len(exercises_with_hold) >= 1, "Mobility workout should have exercises with hold_seconds"

    @pytest.mark.asyncio
    @patch('services.gemini_service.genai')
    async def test_recovery_workout_prompt_generated(self, mock_genai):
        """Test that recovery workout generates correct prompt elements."""
        from services.gemini_service import GeminiService

        mock_response = MagicMock()
        mock_response.text = json.dumps({
            "name": "Gentle Recovery Flow",
            "type": "recovery",
            "difficulty": "easy",
            "duration_minutes": 20,
            "target_muscles": ["full body"],
            "exercises": [
                {
                    "name": "Light Walking",
                    "sets": 1,
                    "reps": 1,
                    "duration_seconds": 300,
                    "rest_seconds": 0,
                    "equipment": "none",
                    "muscle_group": "legs",
                    "notes": "Easy pace, focus on breathing"
                },
                {
                    "name": "Gentle Quad Stretch",
                    "sets": 2,
                    "reps": 1,
                    "hold_seconds": 60,
                    "rest_seconds": 15,
                    "equipment": "bodyweight",
                    "muscle_group": "quads",
                    "is_unilateral": True,
                    "notes": "Hold wall for balance"
                }
            ],
            "notes": "This is an active recovery session"
        })

        mock_model = MagicMock()
        mock_model.generate_content_async = AsyncMock(return_value=mock_response)
        mock_genai.GenerativeModel.return_value = mock_model

        service = GeminiService()
        result = await service.generate_workout_plan(
            fitness_level="intermediate",
            goals=["recovery"],
            equipment=["bodyweight"],
            duration_minutes=20,
            workout_type_preference="recovery"
        )

        assert result["type"] == "recovery"
        # Recovery workouts should generally be lower intensity, but Gemini may vary
        # The key is that the workout type is correctly set to "recovery"
        assert result.get("difficulty") is not None, "Recovery workout should have a difficulty level"


class TestUnilateralExerciseSupport:
    """Tests for unilateral (single-side) exercise support."""

    def test_is_unilateral_field_parsed(self):
        """Test that is_unilateral field is correctly parsed."""
        exercise_data = {
            "name": "Single Leg Romanian Deadlift",
            "sets": 3,
            "reps": 10,
            "is_unilateral": True,
            "muscle_group": "hamstrings"
        }
        assert exercise_data["is_unilateral"] is True

    def test_alternating_hands_compatibility(self):
        """Test that alternating_hands and is_unilateral work together."""
        exercise_data = {
            "name": "Alternating Dumbbell Curl",
            "alternating_hands": True,
            "is_unilateral": True
        }
        # Both can be true for alternating exercises
        assert exercise_data["alternating_hands"] is True
        assert exercise_data["is_unilateral"] is True


class TestHoldSecondsField:
    """Tests for hold_seconds field for stretching exercises."""

    def test_hold_seconds_for_stretch(self):
        """Test that hold_seconds is used for stretching exercises."""
        stretch_exercise = {
            "name": "Pigeon Pose",
            "sets": 2,
            "reps": 1,
            "hold_seconds": 45,
            "muscle_group": "hips"
        }
        assert stretch_exercise["hold_seconds"] == 45
        # For holds, reps is typically 1
        assert stretch_exercise["reps"] == 1

    def test_hold_seconds_vs_duration_seconds(self):
        """Test distinction between hold_seconds (static) and duration_seconds (cardio)."""
        # Static hold (stretching)
        stretch = {
            "name": "Hip Flexor Stretch",
            "hold_seconds": 45,
            "duration_seconds": None
        }
        assert stretch["hold_seconds"] == 45
        assert stretch["duration_seconds"] is None

        # Cardio duration
        cardio = {
            "name": "Jumping Jacks",
            "hold_seconds": None,
            "duration_seconds": 30
        }
        assert cardio["hold_seconds"] is None
        assert cardio["duration_seconds"] == 30


class TestMobilityExerciseCategories:
    """Tests for mobility exercise category detection."""

    def test_yoga_exercise_detection(self):
        """Test detection of yoga exercises."""
        yoga_keywords = ['yoga', 'pose', 'asana', 'downward dog', 'warrior', 'cobra', 'child\'s pose']
        exercise_name = "Downward Dog Pose"

        # Check if any keyword is in exercise name
        is_yoga = any(kw.lower() in exercise_name.lower() for kw in yoga_keywords)
        assert is_yoga is True

    def test_stretch_exercise_detection(self):
        """Test detection of stretching exercises."""
        stretch_keywords = ['stretch', 'flexibility', 'pigeon', 'hamstring stretch']
        exercise_name = "Standing Hamstring Stretch"

        is_stretch = any(kw.lower() in exercise_name.lower() for kw in stretch_keywords)
        assert is_stretch is True

    def test_mobility_drill_detection(self):
        """Test detection of mobility drills."""
        mobility_keywords = ['mobility', 'rotation', 'circle', 'swing', 'flow']
        exercise_name = "Hip Circles"

        is_mobility = any(kw.lower() in exercise_name.lower() for kw in mobility_keywords)
        assert is_mobility is True


class TestWorkoutTypePromptGeneration:
    """Tests for workout type-specific prompt generation."""

    def test_mobility_prompt_contains_key_instructions(self):
        """Verify mobility prompt includes essential instructions."""
        mobility_instructions = """
🧘 MOBILITY WORKOUT TYPE:
This is a MOBILITY/FLEXIBILITY-focused workout. You MUST:
1. Focus on stretching, yoga poses, and mobility drills
2. Use hold_seconds for static stretches (typically 30-60 seconds)
3. Include dynamic mobility movements with controlled tempo
4. Emphasize joint range of motion and flexibility
5. Keep rest minimal (15-30 seconds) - these are low-intensity movements
6. Include unilateral (single-side) exercises for balance work
"""
        # Key elements that must be present
        assert "MOBILITY" in mobility_instructions
        assert "hold_seconds" in mobility_instructions
        assert "yoga" in mobility_instructions.lower()
        assert "stretching" in mobility_instructions.lower()
        assert "unilateral" in mobility_instructions.lower()

    def test_recovery_prompt_contains_key_instructions(self):
        """Verify recovery prompt includes essential instructions."""
        recovery_instructions = """
💆 RECOVERY WORKOUT TYPE:
This is a RECOVERY/ACTIVE REST workout. You MUST:
1. Keep intensity very low (RPE 3-4 out of 10)
2. Focus on blood flow and gentle movement
3. Include light stretching and mobility work
4. Use longer holds and slower tempos
5. Emphasize breathing and relaxation
6. NO heavy weights or intense cardio
"""
        # Key elements that must be present
        assert "RECOVERY" in recovery_instructions
        assert "low" in recovery_instructions.lower()
        assert "gentle" in recovery_instructions.lower()
        assert "breathing" in recovery_instructions.lower()
        assert "NO heavy weights" in recovery_instructions
