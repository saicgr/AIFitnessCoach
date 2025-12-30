"""
Tests for Mood-Based Workout Feature
=====================================
Tests for mood check-ins, mood history, mood analytics, and mood workout generation.
"""

import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock, AsyncMock, patch
import json

from backend.services.mood_workout_service import (
    MoodWorkoutService,
    MoodType,
    MoodWorkoutConfig,
    MOOD_CONFIGS,
)


class TestMoodWorkoutService:
    """Tests for MoodWorkoutService"""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = MoodWorkoutService()

    def test_all_mood_types_have_configs(self):
        """Test that all mood types have corresponding configurations."""
        for mood_type in MoodType:
            assert mood_type in MOOD_CONFIGS
            config = MOOD_CONFIGS[mood_type]
            assert isinstance(config, MoodWorkoutConfig)

    def test_get_mood_config_returns_correct_config(self):
        """Test that get_mood_config returns the correct configuration."""
        great_config = self.service.get_mood_config(MoodType.GREAT)
        assert great_config.intensity_preference == "hard"
        assert great_config.workout_type_preference == "strength"
        assert great_config.emoji == "🔥"

        tired_config = self.service.get_mood_config(MoodType.TIRED)
        assert tired_config.intensity_preference == "easy"
        assert tired_config.workout_type_preference == "mobility"
        assert tired_config.emoji == "😴"

    def test_validate_mood_with_valid_values(self):
        """Test validate_mood with valid mood strings."""
        assert MoodWorkoutService.validate_mood("great") == MoodType.GREAT
        assert MoodWorkoutService.validate_mood("good") == MoodType.GOOD
        assert MoodWorkoutService.validate_mood("tired") == MoodType.TIRED
        assert MoodWorkoutService.validate_mood("stressed") == MoodType.STRESSED

    def test_validate_mood_case_insensitive(self):
        """Test that validate_mood is case insensitive."""
        assert MoodWorkoutService.validate_mood("GREAT") == MoodType.GREAT
        assert MoodWorkoutService.validate_mood("Good") == MoodType.GOOD
        assert MoodWorkoutService.validate_mood("TIRED") == MoodType.TIRED

    def test_validate_mood_with_invalid_value(self):
        """Test validate_mood raises ValueError for invalid mood."""
        with pytest.raises(ValueError) as exc_info:
            MoodWorkoutService.validate_mood("invalid_mood")
        assert "Invalid mood" in str(exc_info.value)

    def test_get_workout_params_basic(self):
        """Test get_workout_params returns correct parameters."""
        params = self.service.get_workout_params(
            mood=MoodType.GREAT,
            user_fitness_level="intermediate",
        )

        assert params["mood"] == "great"
        assert params["mood_emoji"] == "🔥"
        assert params["intensity_preference"] == "hard"
        assert params["workout_type_preference"] == "strength"
        assert params["duration_minutes"] == 25  # Default for GREAT

    def test_get_workout_params_with_duration_override(self):
        """Test that duration override is clamped to mood's valid range."""
        # GREAT mood has range (20, 30)
        params = self.service.get_workout_params(
            mood=MoodType.GREAT,
            duration_override=45,  # Above max
        )
        assert params["duration_minutes"] == 30  # Clamped to max

        params = self.service.get_workout_params(
            mood=MoodType.GREAT,
            duration_override=10,  # Below min
        )
        assert params["duration_minutes"] == 20  # Clamped to min

    def test_get_workout_params_adjusts_intensity_for_beginner(self):
        """Test that intensity is adjusted down for beginners on hard workouts."""
        params = self.service.get_workout_params(
            mood=MoodType.GREAT,  # Would normally be "hard"
            user_fitness_level="beginner",
        )
        assert params["intensity_preference"] == "medium"  # Adjusted down

    def test_get_workout_params_adjusts_intensity_for_advanced(self):
        """Test that intensity is adjusted up for advanced users on easy workouts."""
        params = self.service.get_workout_params(
            mood=MoodType.TIRED,  # Would normally be "easy"
            user_fitness_level="advanced",
        )
        assert params["intensity_preference"] == "medium"  # Adjusted up

    def test_build_generation_prompt_contains_mood(self):
        """Test that the generation prompt contains mood information."""
        prompt = self.service.build_generation_prompt(
            mood=MoodType.GREAT,
            user_fitness_level="intermediate",
            user_goals=["build_muscle"],
            user_equipment=["dumbbells"],
            duration_minutes=25,
        )

        assert "GREAT" in prompt
        assert "🔥" in prompt
        assert "challenging" in prompt.lower()
        assert "intermediate" in prompt.lower()
        assert "dumbbells" in prompt.lower()
        assert "25" in prompt

    def test_build_generation_prompt_returns_json_format_instructions(self):
        """Test that the prompt requests JSON output."""
        prompt = self.service.build_generation_prompt(
            mood=MoodType.GOOD,
            user_fitness_level="intermediate",
            user_goals=[],
            user_equipment=[],
            duration_minutes=20,
        )

        assert "JSON" in prompt
        assert '"name"' in prompt
        assert '"exercises"' in prompt
        assert '"warmup"' in prompt
        assert '"cooldown"' in prompt

    def test_get_context_data_time_of_day_morning(self):
        """Test that context data correctly identifies morning."""
        with patch("backend.services.mood_workout_service.datetime") as mock_datetime:
            mock_datetime.now.return_value = datetime(2024, 1, 1, 8, 0, 0)
            context = self.service.get_context_data()
            assert context["time_of_day"] == "morning"

    def test_get_context_data_time_of_day_afternoon(self):
        """Test that context data correctly identifies afternoon."""
        with patch("backend.services.mood_workout_service.datetime") as mock_datetime:
            mock_datetime.now.return_value = datetime(2024, 1, 1, 14, 0, 0)
            context = self.service.get_context_data()
            assert context["time_of_day"] == "afternoon"

    def test_get_context_data_time_of_day_evening(self):
        """Test that context data correctly identifies evening."""
        with patch("backend.services.mood_workout_service.datetime") as mock_datetime:
            mock_datetime.now.return_value = datetime(2024, 1, 1, 19, 0, 0)
            context = self.service.get_context_data()
            assert context["time_of_day"] == "evening"

    def test_get_context_data_time_of_day_night(self):
        """Test that context data correctly identifies night."""
        with patch("backend.services.mood_workout_service.datetime") as mock_datetime:
            mock_datetime.now.return_value = datetime(2024, 1, 1, 23, 0, 0)
            context = self.service.get_context_data()
            assert context["time_of_day"] == "night"

    def test_get_context_data_includes_device_info(self):
        """Test that context data includes device information."""
        context = self.service.get_context_data(
            device="ios",
            app_version="1.0.0",
            previous_mood="good",
        )
        assert context["device"] == "ios"
        assert context["app_version"] == "1.0.0"
        assert context["previous_mood"] == "good"

    def test_get_all_moods_returns_all_four(self):
        """Test that get_all_moods returns all four mood options."""
        moods = self.service.get_all_moods()
        assert len(moods) == 4

        mood_values = [m["value"] for m in moods]
        assert "great" in mood_values
        assert "good" in mood_values
        assert "tired" in mood_values
        assert "stressed" in mood_values

    def test_get_all_moods_has_required_fields(self):
        """Test that each mood has required display fields."""
        moods = self.service.get_all_moods()
        for mood in moods:
            assert "value" in mood
            assert "emoji" in mood
            assert "color" in mood
            assert "label" in mood
            assert "description" in mood


class TestMoodConfigs:
    """Tests for mood configuration correctness."""

    def test_great_mood_is_high_intensity(self):
        """Test that GREAT mood has high intensity settings."""
        config = MOOD_CONFIGS[MoodType.GREAT]
        assert config.intensity_preference == "hard"
        assert config.rest_multiplier < 1.0  # Shorter rest
        assert config.max_exercises >= 5

    def test_tired_mood_is_recovery_focused(self):
        """Test that TIRED mood has recovery-focused settings."""
        config = MOOD_CONFIGS[MoodType.TIRED]
        assert config.intensity_preference == "easy"
        assert config.workout_type_preference == "mobility"
        assert config.rest_multiplier > 1.0  # Longer rest
        assert config.cooldown_duration >= 3  # Longer cooldown

    def test_stressed_mood_focuses_on_stress_relief(self):
        """Test that STRESSED mood focuses on stress relief."""
        config = MOOD_CONFIGS[MoodType.STRESSED]
        assert "stress" in " ".join(config.focus_keywords).lower()
        assert config.workout_type_preference in ["cardio", "flow"]
        assert config.cooldown_duration >= 3  # Longer cooldown for stress relief

    def test_all_configs_have_valid_durations(self):
        """Test that all mood configs have valid duration ranges."""
        for mood_type, config in MOOD_CONFIGS.items():
            assert config.duration_range[0] >= 10  # Min 10 minutes
            assert config.duration_range[1] <= 45  # Max 45 minutes
            assert config.duration_range[0] <= config.duration_range[1]
            assert config.duration_default >= config.duration_range[0]
            assert config.duration_default <= config.duration_range[1]

    def test_all_configs_have_valid_colors(self):
        """Test that all mood configs have valid hex colors."""
        for mood_type, config in MOOD_CONFIGS.items():
            assert config.color_hex.startswith("#")
            assert len(config.color_hex) == 7  # #RRGGBB format


class TestMoodAnalyticsCalculations:
    """Tests for mood analytics calculations (simulated)."""

    def test_completion_rate_calculation(self):
        """Test completion rate is calculated correctly."""
        # Simulate: 10 workouts generated, 7 completed
        workouts_generated = 10
        workouts_completed = 7
        completion_rate = (workouts_completed / workouts_generated * 100) if workouts_generated > 0 else 0
        assert completion_rate == 70.0

    def test_completion_rate_with_zero_generated(self):
        """Test completion rate handles zero generated workouts."""
        workouts_generated = 0
        workouts_completed = 0
        completion_rate = (workouts_completed / workouts_generated * 100) if workouts_generated > 0 else 0
        assert completion_rate == 0

    def test_mood_distribution_percentage(self):
        """Test mood distribution percentage calculation."""
        mood_counts = {"great": 5, "good": 10, "tired": 3, "stressed": 2}
        total = sum(mood_counts.values())  # 20

        great_pct = round((mood_counts["great"] / total) * 100, 1)
        assert great_pct == 25.0

        good_pct = round((mood_counts["good"] / total) * 100, 1)
        assert good_pct == 50.0

    def test_streak_calculation_consecutive_days(self):
        """Test streak calculation with consecutive days."""
        from datetime import date

        today = date.today()
        checkin_dates = {
            today,
            today - timedelta(days=1),
            today - timedelta(days=2),
            today - timedelta(days=3),
        }

        sorted_dates = sorted(checkin_dates, reverse=True)
        current_streak = 0
        expected_date = today

        for d in sorted_dates:
            if d == expected_date or d == expected_date - timedelta(days=1):
                current_streak += 1
                expected_date = d - timedelta(days=1)
            else:
                break

        assert current_streak == 4

    def test_streak_calculation_with_gap(self):
        """Test streak calculation with a gap in dates."""
        from datetime import date

        today = date.today()
        checkin_dates = {
            today,
            today - timedelta(days=1),
            # Gap here
            today - timedelta(days=5),
            today - timedelta(days=6),
        }

        sorted_dates = sorted(checkin_dates, reverse=True)
        current_streak = 0
        expected_date = today

        for d in sorted_dates:
            if d == expected_date or d == expected_date - timedelta(days=1):
                current_streak += 1
                expected_date = d - timedelta(days=1)
            else:
                break

        assert current_streak == 2  # Only today and yesterday


class TestMoodRecommendations:
    """Tests for mood-based recommendation generation."""

    def test_recommendation_for_low_completion(self):
        """Test recommendation is generated for low completion rate."""
        completion_rate = 30  # Below 50%
        workouts_generated = 10

        recommendations = []
        if completion_rate < 50 and workouts_generated > 3:
            recommendations.append(
                "Try shorter workouts when you're feeling tired or stressed"
            )

        assert len(recommendations) == 1
        assert "shorter workouts" in recommendations[0]

    def test_recommendation_for_high_tiredness(self):
        """Test recommendation is generated for frequent tired moods."""
        mood_counts = {"great": 2, "good": 3, "tired": 10, "stressed": 1}
        total_count = sum(mood_counts.values())

        recommendations = []
        if mood_counts.get("tired", 0) > total_count * 0.4:
            recommendations.append("sleep schedule")

        assert len(recommendations) == 1

    def test_recommendation_for_high_stress(self):
        """Test recommendation is generated for frequent stressed moods."""
        mood_counts = {"great": 2, "good": 3, "tired": 1, "stressed": 8}
        total_count = sum(mood_counts.values())

        recommendations = []
        if mood_counts.get("stressed", 0) > total_count * 0.3:
            recommendations.append("stress-relief workouts")

        assert len(recommendations) == 1

    def test_recommendation_for_great_streak(self):
        """Test recommendation is generated for good streak."""
        current_streak = 10

        recommendations = []
        if current_streak >= 7:
            recommendations.append(f"{current_streak}-day streak")

        assert len(recommendations) == 1
        assert "10-day streak" in recommendations[0]


class TestMoodPromptGeneration:
    """Tests for mood-based workout prompt generation."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = MoodWorkoutService()

    def test_prompt_includes_warmup_instructions(self):
        """Test that prompt includes warmup section instructions."""
        prompt = self.service.build_generation_prompt(
            mood=MoodType.GREAT,
            user_fitness_level="intermediate",
            user_goals=[],
            user_equipment=[],
            duration_minutes=25,
        )
        assert "warmup" in prompt.lower()
        assert "dynamic" in prompt.lower() or "warm" in prompt.lower()

    def test_prompt_includes_cooldown_instructions(self):
        """Test that prompt includes cooldown section instructions."""
        prompt = self.service.build_generation_prompt(
            mood=MoodType.GREAT,
            user_fitness_level="intermediate",
            user_goals=[],
            user_equipment=[],
            duration_minutes=25,
        )
        assert "cooldown" in prompt.lower()
        assert "stretch" in prompt.lower()

    def test_prompt_includes_user_equipment(self):
        """Test that prompt includes user's available equipment."""
        prompt = self.service.build_generation_prompt(
            mood=MoodType.GOOD,
            user_fitness_level="intermediate",
            user_goals=[],
            user_equipment=["dumbbells", "resistance bands", "pull-up bar"],
            duration_minutes=20,
        )
        assert "dumbbells" in prompt
        assert "resistance bands" in prompt
        assert "pull-up bar" in prompt

    def test_prompt_includes_user_goals(self):
        """Test that prompt includes user's fitness goals."""
        prompt = self.service.build_generation_prompt(
            mood=MoodType.GOOD,
            user_fitness_level="intermediate",
            user_goals=["build_muscle", "improve_endurance"],
            user_equipment=[],
            duration_minutes=20,
        )
        assert "build_muscle" in prompt
        assert "improve_endurance" in prompt

    def test_prompt_requests_motivational_message(self):
        """Test that prompt requests a motivational message."""
        prompt = self.service.build_generation_prompt(
            mood=MoodType.TIRED,
            user_fitness_level="intermediate",
            user_goals=[],
            user_equipment=[],
            duration_minutes=15,
        )
        assert "motivational_message" in prompt


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
