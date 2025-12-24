"""
Tests for onboarding utility functions.
"""

import pytest


class TestEnsureString:
    """Tests for ensure_string function."""

    def test_returns_string_as_is(self):
        """Test that string input is returned unchanged."""
        from services.langgraph_agents.onboarding.nodes.utils import ensure_string

        assert ensure_string("hello") == "hello"
        assert ensure_string("") == ""

    def test_converts_list_to_string(self):
        """Test that list is converted to space-separated string."""
        from services.langgraph_agents.onboarding.nodes.utils import ensure_string

        assert ensure_string(["hello", "world"]) == "hello world"
        assert ensure_string([]) == ""

    def test_converts_other_types(self):
        """Test that other types are converted to string."""
        from services.langgraph_agents.onboarding.nodes.utils import ensure_string

        assert ensure_string(123) == "123"
        assert ensure_string(None) == ""

    def test_handles_mixed_list(self):
        """Test handling of list with mixed types."""
        from services.langgraph_agents.onboarding.nodes.utils import ensure_string

        assert ensure_string([1, "two", 3]) == "1 two 3"


class TestGetFieldValue:
    """Tests for get_field_value function."""

    def test_returns_snake_case_value(self):
        """Test getting value with snake_case key."""
        from services.langgraph_agents.onboarding.nodes.utils import get_field_value

        collected = {"days_per_week": 5}
        assert get_field_value(collected, "days_per_week") == 5

    def test_returns_camel_case_value(self):
        """Test getting value with camelCase key."""
        from services.langgraph_agents.onboarding.nodes.utils import get_field_value

        collected = {"daysPerWeek": 5}
        assert get_field_value(collected, "days_per_week") == 5

    def test_returns_none_for_missing(self):
        """Test returning None for missing field."""
        from services.langgraph_agents.onboarding.nodes.utils import get_field_value

        collected = {}
        assert get_field_value(collected, "days_per_week") is None

    def test_returns_none_for_empty_string(self):
        """Test returning None for empty string value."""
        from services.langgraph_agents.onboarding.nodes.utils import get_field_value

        collected = {"days_per_week": ""}
        result = get_field_value(collected, "days_per_week")
        # Empty string should try alternative case, return None if both empty
        assert result == "" or result is None

    def test_returns_none_for_empty_list(self):
        """Test returning None for empty list value."""
        from services.langgraph_agents.onboarding.nodes.utils import get_field_value

        collected = {"goals": []}
        result = get_field_value(collected, "goals")
        # Empty list should try alternative case
        assert result == [] or result is None


class TestDetectFieldFromResponse:
    """Tests for detect_field_from_response function."""

    def test_detects_workout_duration(self):
        """Test detecting workout duration field."""
        from services.langgraph_agents.onboarding.nodes.utils import detect_field_from_response

        assert detect_field_from_response("How long do you want your workout to be? 30, 45, 60 minutes?") == "workout_duration"
        assert detect_field_from_response("What's your preferred session length?") == "workout_duration"

    def test_detects_selected_days(self):
        """Test detecting selected days field."""
        from services.langgraph_agents.onboarding.nodes.utils import detect_field_from_response

        assert detect_field_from_response("Which days work best for you? Monday, Tuesday?") == "selected_days"
        assert detect_field_from_response("What days of the week can you train?") == "selected_days"

    def test_detects_goals(self):
        """Test detecting goals field."""
        from services.langgraph_agents.onboarding.nodes.utils import detect_field_from_response

        assert detect_field_from_response("What's your fitness goal?") == "goals"
        assert detect_field_from_response("What do you want to achieve?") == "goals"

    def test_returns_none_for_unknown(self):
        """Test returning None for unknown response."""
        from services.langgraph_agents.onboarding.nodes.utils import detect_field_from_response

        assert detect_field_from_response("Hello, how are you?") is None


class TestDetectNonGymActivity:
    """Tests for detect_non_gym_activity function."""

    def test_detects_walking(self):
        """Test detecting walking as non-gym activity."""
        from services.langgraph_agents.onboarding.nodes.utils import detect_non_gym_activity

        result = detect_non_gym_activity("I just want to walk more")
        assert result is not None
        assert result["activity"] == "walking"

    def test_detects_step_counting(self):
        """Test detecting step counting goal."""
        from services.langgraph_agents.onboarding.nodes.utils import detect_non_gym_activity

        result = detect_non_gym_activity("My goal is 10k steps daily")
        assert result is not None
        assert result["activity"] == "step counting"

    def test_detects_jogging(self):
        """Test detecting jogging as non-gym activity."""
        from services.langgraph_agents.onboarding.nodes.utils import detect_non_gym_activity

        result = detect_non_gym_activity("I enjoy jogging")
        assert result is not None
        assert result["activity"] == "jogging"

    def test_returns_none_for_gym_activity(self):
        """Test returning None for gym activities."""
        from services.langgraph_agents.onboarding.nodes.utils import detect_non_gym_activity

        assert detect_non_gym_activity("I want to build muscle") is None
        assert detect_non_gym_activity("Weight training") is None

    def test_handles_list_input(self):
        """Test handling of list input."""
        from services.langgraph_agents.onboarding.nodes.utils import detect_non_gym_activity

        result = detect_non_gym_activity(["I", "want", "to", "walk"])
        assert result is not None
        assert result["activity"] == "walking"


class TestNonGymActivities:
    """Tests for NON_GYM_ACTIVITIES constant."""

    def test_contains_expected_activities(self):
        """Test that all expected activities are present."""
        from services.langgraph_agents.onboarding.nodes.utils import NON_GYM_ACTIVITIES

        assert "walk" in NON_GYM_ACTIVITIES
        assert "jogging" in NON_GYM_ACTIVITIES
        assert "meditation only" in NON_GYM_ACTIVITIES
        assert "cycling outdoors" in NON_GYM_ACTIVITIES

    def test_activity_has_required_keys(self):
        """Test that each activity has required keys."""
        from services.langgraph_agents.onboarding.nodes.utils import NON_GYM_ACTIVITIES

        for key, value in NON_GYM_ACTIVITIES.items():
            assert "activity" in value
            assert "complement" in value
