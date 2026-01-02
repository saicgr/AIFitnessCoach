"""
Tests for weight personalization in workout generation.

This module tests that user's historical weights and 1RM data are properly
applied to generated workouts, addressing the user review complaint:
"The coach also doesn't adjust the plan based on the actual weights I'm using"
"""

import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from api.v1.workouts.utils import (
    apply_1rm_weights_to_exercises,
    calculate_working_weight_from_1rm,
    get_user_1rm_data,
    get_user_training_intensity,
    get_user_intensity_overrides,
    fuzzy_exercise_match,
)


class TestCalculateWorkingWeight:
    """Tests for calculate_working_weight_from_1rm function."""

    def test_calculate_weight_at_75_percent(self):
        """Test weight calculation at 75% intensity."""
        result = calculate_working_weight_from_1rm(100.0, 75, 'barbell')
        assert result == 75.0

    def test_calculate_weight_at_70_percent(self):
        """Test weight calculation at 70% intensity."""
        result = calculate_working_weight_from_1rm(100.0, 70, 'barbell')
        assert result == 70.0

    def test_barbell_rounding_to_2_5kg(self):
        """Test that barbell weights are rounded to 2.5kg increments."""
        # 100kg * 73% = 73kg -> should round to 72.5kg
        result = calculate_working_weight_from_1rm(100.0, 73, 'barbell')
        assert result == 72.5

    def test_dumbbell_rounding_to_2kg(self):
        """Test that dumbbell weights are rounded to 2kg increments."""
        # 50kg * 75% = 37.5kg -> should round to 38kg
        result = calculate_working_weight_from_1rm(50.0, 75, 'dumbbell')
        assert result == 38.0

    def test_machine_rounding_to_5kg(self):
        """Test that machine weights are rounded to 5kg increments."""
        # 80kg * 80% = 64kg -> should round to 65kg
        result = calculate_working_weight_from_1rm(80.0, 80, 'machine')
        assert result == 65.0

    def test_cable_rounding_to_2_5kg(self):
        """Test that cable weights are rounded to 2.5kg increments."""
        # 60kg * 70% = 42kg -> should round to 42.5kg
        result = calculate_working_weight_from_1rm(60.0, 70, 'cable')
        assert result == 42.5

    def test_kettlebell_rounding_to_4kg(self):
        """Test that kettlebell weights are rounded to 4kg increments."""
        # 40kg * 75% = 30kg -> should round to 32kg
        result = calculate_working_weight_from_1rm(40.0, 75, 'kettlebell')
        assert result == 32.0

    def test_bodyweight_no_rounding(self):
        """Test that bodyweight exercises don't apply weight."""
        result = calculate_working_weight_from_1rm(80.0, 100, 'bodyweight')
        assert result == 80.0

    def test_intensity_below_50_clamped(self):
        """Test that intensity below 50% is clamped to 50%."""
        result = calculate_working_weight_from_1rm(100.0, 30, 'barbell')
        assert result == 50.0  # 100 * 50% = 50

    def test_intensity_above_100_clamped(self):
        """Test that intensity above 100% is clamped to 100%."""
        result = calculate_working_weight_from_1rm(100.0, 120, 'barbell')
        assert result == 100.0  # 100 * 100% = 100


class TestFuzzyExerciseMatch:
    """Tests for fuzzy_exercise_match function."""

    def test_exact_match(self):
        """Test exact name matching."""
        assert fuzzy_exercise_match("Bench Press", "Bench Press") is True

    def test_case_insensitive_match(self):
        """Test case insensitive matching."""
        assert fuzzy_exercise_match("bench press", "BENCH PRESS") is True

    def test_barbell_prefix_match(self):
        """Test matching with barbell prefix."""
        assert fuzzy_exercise_match("Bench Press", "Barbell Bench Press") is True

    def test_dumbbell_prefix_match(self):
        """Test matching with dumbbell prefix."""
        assert fuzzy_exercise_match("Curl", "Dumbbell Curl") is True

    def test_compound_word_pullup(self):
        """Test matching pullup variations."""
        assert fuzzy_exercise_match("Pull-up", "Pullup") is True
        assert fuzzy_exercise_match("Pull Up", "Pull-up") is True

    def test_no_match_different_exercises(self):
        """Test that different exercises don't match."""
        assert fuzzy_exercise_match("Bench Press", "Squat") is False
        assert fuzzy_exercise_match("Deadlift", "Curl") is False


class TestApply1RMWeightsToExercises:
    """Tests for apply_1rm_weights_to_exercises function."""

    def test_applies_weights_when_1rm_exists(self):
        """Test that weights are applied when 1RM data exists."""
        exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10, "weight": 50},
            {"name": "Squat", "sets": 4, "reps": 8, "weight": 60},
        ]
        one_rm_data = {
            "bench press": {"one_rep_max_kg": 100.0, "source": "manual", "confidence": 1.0},
            "squat": {"one_rep_max_kg": 140.0, "source": "calculated", "confidence": 0.9},
        }
        global_intensity = 75
        intensity_overrides = {}

        result = apply_1rm_weights_to_exercises(
            exercises, one_rm_data, global_intensity, intensity_overrides
        )

        assert len(result) == 2
        # Bench Press: 100kg * 75% = 75kg
        assert result[0]["weight"] == 75.0
        assert result[0]["weight_source"] == "1rm_calculated"
        assert result[0]["one_rep_max_kg"] == 100.0
        assert result[0]["intensity_percent"] == 75

        # Squat: 140kg * 75% = 105kg
        assert result[1]["weight"] == 105.0
        assert result[1]["weight_source"] == "1rm_calculated"

    def test_uses_intensity_override_for_specific_exercise(self):
        """Test that per-exercise intensity overrides are respected."""
        exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10},
            {"name": "Squat", "sets": 4, "reps": 8},
        ]
        one_rm_data = {
            "bench press": {"one_rep_max_kg": 100.0, "source": "manual", "confidence": 1.0},
            "squat": {"one_rep_max_kg": 140.0, "source": "manual", "confidence": 1.0},
        }
        global_intensity = 75
        intensity_overrides = {"bench press": 85}  # Override bench press to 85%

        result = apply_1rm_weights_to_exercises(
            exercises, one_rm_data, global_intensity, intensity_overrides
        )

        # Bench Press: 100kg * 85% = 85kg (uses override)
        assert result[0]["weight"] == 85.0
        assert result[0]["intensity_percent"] == 85

        # Squat: 140kg * 75% = 105kg (uses global)
        assert result[1]["weight"] == 105.0
        assert result[1]["intensity_percent"] == 75

    def test_fuzzy_matches_exercise_names(self):
        """Test that fuzzy matching works for exercise names."""
        exercises = [
            {"name": "Barbell Bench Press", "sets": 3, "reps": 10},
        ]
        one_rm_data = {
            "bench press": {"one_rep_max_kg": 100.0, "source": "manual", "confidence": 1.0},
        }
        global_intensity = 70
        intensity_overrides = {}

        result = apply_1rm_weights_to_exercises(
            exercises, one_rm_data, global_intensity, intensity_overrides
        )

        # Should match "Barbell Bench Press" to "bench press" 1RM
        assert result[0]["weight"] == 70.0
        assert result[0]["weight_source"] == "1rm_calculated"

    def test_preserves_exercises_without_1rm(self):
        """Test that exercises without 1RM data are preserved unchanged."""
        exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10, "weight": 50},
            {"name": "Lateral Raise", "sets": 3, "reps": 12, "weight": 10},
        ]
        one_rm_data = {
            "bench press": {"one_rep_max_kg": 100.0, "source": "manual", "confidence": 1.0},
        }
        global_intensity = 75
        intensity_overrides = {}

        result = apply_1rm_weights_to_exercises(
            exercises, one_rm_data, global_intensity, intensity_overrides
        )

        # Bench Press gets updated
        assert result[0]["weight"] == 75.0
        assert result[0]["weight_source"] == "1rm_calculated"

        # Lateral Raise keeps original weight (no 1RM data)
        assert result[1]["weight"] == 10
        assert result[1].get("weight_source") is None

    def test_handles_empty_1rm_data(self):
        """Test handling of empty 1RM data."""
        exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10, "weight": 50},
        ]
        one_rm_data = {}
        global_intensity = 75
        intensity_overrides = {}

        result = apply_1rm_weights_to_exercises(
            exercises, one_rm_data, global_intensity, intensity_overrides
        )

        # Original exercises should be returned unchanged
        assert result[0]["weight"] == 50
        assert result[0].get("weight_source") is None

    def test_detects_equipment_type_from_exercise(self):
        """Test that equipment type is correctly detected for rounding."""
        exercises = [
            {"name": "Dumbbell Curl", "sets": 3, "reps": 12, "equipment": "dumbbell"},
            {"name": "Cable Fly", "sets": 3, "reps": 15, "equipment": "cable"},
            {"name": "Leg Press", "sets": 4, "reps": 10, "equipment": "machine"},
        ]
        one_rm_data = {
            "dumbbell curl": {"one_rep_max_kg": 20.0, "source": "manual", "confidence": 1.0},
            "cable fly": {"one_rep_max_kg": 30.0, "source": "manual", "confidence": 1.0},
            "leg press": {"one_rep_max_kg": 200.0, "source": "manual", "confidence": 1.0},
        }
        global_intensity = 75
        intensity_overrides = {}

        result = apply_1rm_weights_to_exercises(
            exercises, one_rm_data, global_intensity, intensity_overrides
        )

        # Dumbbell Curl: 20kg * 75% = 15kg (2kg increment)
        assert result[0]["weight"] == 16.0  # Rounded to nearest 2kg

        # Cable Fly: 30kg * 75% = 22.5kg (2.5kg increment)
        assert result[1]["weight"] == 22.5

        # Leg Press: 200kg * 75% = 150kg (5kg increment)
        assert result[2]["weight"] == 150.0


class TestGetUser1RMData:
    """Tests for get_user_1rm_data function."""

    @pytest.mark.asyncio
    async def test_returns_empty_dict_when_no_data(self):
        """Test that empty dict is returned when no 1RM data exists."""
        with patch('api.v1.workouts.utils.get_supabase_db') as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = None
            mock_db.return_value.client = mock_client

            result = await get_user_1rm_data("test-user-id")
            assert result == {}

    @pytest.mark.asyncio
    async def test_returns_1rm_data_normalized(self):
        """Test that 1RM data is returned with lowercase exercise names."""
        with patch('api.v1.workouts.utils.get_supabase_db') as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
                {"exercise_name": "Bench Press", "one_rep_max_kg": 100.0, "source": "manual", "confidence": 1.0},
                {"exercise_name": "Squat", "one_rep_max_kg": 140.0, "source": "calculated", "confidence": 0.9},
            ]
            mock_db.return_value.client = mock_client

            result = await get_user_1rm_data("test-user-id")

            assert "bench press" in result
            assert result["bench press"]["one_rep_max_kg"] == 100.0
            assert "squat" in result
            assert result["squat"]["one_rep_max_kg"] == 140.0


class TestGetUserTrainingIntensity:
    """Tests for get_user_training_intensity function."""

    @pytest.mark.asyncio
    async def test_returns_default_75_when_not_set(self):
        """Test that default 75% is returned when not set."""
        with patch('api.v1.workouts.utils.get_supabase_db') as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
                {"training_intensity_percent": None}
            ]
            mock_db.return_value.client = mock_client

            result = await get_user_training_intensity("test-user-id")
            assert result == 75

    @pytest.mark.asyncio
    async def test_returns_user_set_intensity(self):
        """Test that user's set intensity is returned."""
        with patch('api.v1.workouts.utils.get_supabase_db') as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
                {"training_intensity_percent": 80}
            ]
            mock_db.return_value.client = mock_client

            result = await get_user_training_intensity("test-user-id")
            assert result == 80

    @pytest.mark.asyncio
    async def test_clamps_intensity_to_valid_range(self):
        """Test that intensity outside 50-100 is clamped."""
        with patch('api.v1.workouts.utils.get_supabase_db') as mock_db:
            mock_client = MagicMock()
            # Test below 50
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
                {"training_intensity_percent": 30}
            ]
            mock_db.return_value.client = mock_client

            result = await get_user_training_intensity("test-user-id")
            assert result == 75  # Falls back to default when invalid

            # Test above 100
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
                {"training_intensity_percent": 120}
            ]

            result = await get_user_training_intensity("test-user-id")
            assert result == 100  # Clamped to 100


class TestIntegrationWeightPersonalization:
    """Integration tests for weight personalization in workout generation."""

    def test_exercises_have_weight_source_marker(self):
        """Test that exercises have weight_source marker after personalization."""
        exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10},
        ]
        one_rm_data = {
            "bench press": {"one_rep_max_kg": 100.0, "source": "manual", "confidence": 1.0},
        }

        result = apply_1rm_weights_to_exercises(exercises, one_rm_data, 75, {})

        # Should have weight_source = "1rm_calculated"
        assert result[0]["weight_source"] == "1rm_calculated"
        # Should also have the original 1RM for display purposes
        assert result[0]["one_rep_max_kg"] == 100.0
        # Should have the intensity used
        assert result[0]["intensity_percent"] == 75

    def test_personalized_weights_persist_through_generation(self):
        """Test that personalized weights flow through to saved workout."""
        # This is tested via the endpoint, but we verify the data structure
        exercises = [
            {"name": "Squat", "sets": 4, "reps": 6, "equipment": "barbell"},
            {"name": "Deadlift", "sets": 3, "reps": 5, "equipment": "barbell"},
            {"name": "Bench Press", "sets": 3, "reps": 8, "equipment": "barbell"},
        ]
        one_rm_data = {
            "squat": {"one_rep_max_kg": 140.0, "source": "tested", "confidence": 1.0},
            "deadlift": {"one_rep_max_kg": 180.0, "source": "tested", "confidence": 1.0},
            "bench press": {"one_rep_max_kg": 100.0, "source": "calculated", "confidence": 0.9},
        }

        result = apply_1rm_weights_to_exercises(exercises, one_rm_data, 80, {})

        # All exercises should have personalized weights at 80%
        assert result[0]["weight"] == 112.5  # 140 * 0.8, rounded to 2.5kg
        assert result[1]["weight"] == 145.0  # 180 * 0.8, rounded to 2.5kg
        assert result[2]["weight"] == 80.0   # 100 * 0.8

        # All should have the marker
        for ex in result:
            assert ex["weight_source"] == "1rm_calculated"
