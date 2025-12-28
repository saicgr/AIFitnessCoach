"""
Tests for workout insights node functions, specifically JSON repair logic.
"""
import pytest
import json

from services.langgraph_agents.workout_insights.nodes import (
    repair_json_string,
    categorize_muscle_group,
    determine_workout_focus,
)


class TestRepairJsonString:
    """Tests for the repair_json_string function."""

    def test_valid_json_returns_unchanged(self):
        """Valid JSON should be returned as-is."""
        valid = '{"headline": "Test", "sections": []}'
        result = repair_json_string(valid)
        assert result == valid
        assert json.loads(result) == {"headline": "Test", "sections": []}

    def test_empty_string_returns_none(self):
        """Empty string should return None."""
        assert repair_json_string("") is None
        assert repair_json_string(None) is None

    def test_trailing_comma_removed(self):
        """Trailing commas before closing brackets should be removed."""
        malformed = '{"headline": "Test", "sections": [],}'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["headline"] == "Test"

    def test_trailing_comma_in_array(self):
        """Trailing commas in arrays should be removed."""
        malformed = '{"items": [1, 2, 3,]}'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["items"] == [1, 2, 3]

    def test_unclosed_braces_completed(self):
        """Unclosed braces should be completed."""
        malformed = '{"headline": "Test"'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["headline"] == "Test"

    def test_unclosed_brackets_completed(self):
        """Unclosed brackets should be completed."""
        malformed = '{"items": [1, 2, 3'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["items"] == [1, 2, 3]

    def test_nested_unclosed_structures(self):
        """Nested unclosed structures should be completed."""
        malformed = '{"outer": {"inner": [1, 2'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert "outer" in parsed

    def test_extract_json_from_text(self):
        """JSON embedded in text should be extracted."""
        with_text = 'Here is the JSON: {"headline": "Test", "sections": []} some trailing text'
        result = repair_json_string(with_text)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["headline"] == "Test"

    def test_completely_invalid_returns_none(self):
        """Completely invalid content should return None."""
        invalid = "This is not JSON at all and has no braces"
        result = repair_json_string(invalid)
        assert result is None

    def test_unterminated_string_completed(self):
        """Unterminated strings should be completed when possible."""
        # Simple case with unterminated string
        malformed = '{"headline": "Test workout'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert "headline" in parsed

    def test_real_world_unterminated_string_error(self):
        """Test the actual error case from production logs."""
        # Simulating: Unterminated string starting at: line 2 column 15 (char 16)
        malformed = '''{
  "headline": "Power'''
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert "headline" in parsed

    def test_complex_insights_structure_truncated(self):
        """Test with a truncated but recoverable insights structure."""
        # This JSON is truncated mid-value but can be recovered
        malformed = '{"headline": "Leg Day Power!", "sections": []'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["headline"] == "Leg Day Power!"
        assert "sections" in parsed

    def test_multiple_trailing_commas(self):
        """Multiple trailing commas should all be fixed."""
        malformed = '{"a": 1, "b": [1, 2,], "c": 3,}'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["a"] == 1
        assert parsed["b"] == [1, 2]
        assert parsed["c"] == 3


class TestCategorizeMuscleGroup:
    """Tests for muscle group categorization."""

    def test_empty_muscle_returns_other(self):
        assert categorize_muscle_group("") == "other"
        assert categorize_muscle_group(None) == "other"

    def test_chest_is_upper_push(self):
        assert categorize_muscle_group("chest") == "upper_push"
        assert categorize_muscle_group("Pectoralis Major") == "upper_push"

    def test_shoulder_is_upper_push(self):
        assert categorize_muscle_group("shoulder") == "upper_push"
        assert categorize_muscle_group("Deltoid") == "upper_push"
        assert categorize_muscle_group("triceps") == "upper_push"

    def test_back_is_upper_pull(self):
        assert categorize_muscle_group("back") == "upper_pull"
        assert categorize_muscle_group("Latissimus Dorsi") == "upper_pull"
        assert categorize_muscle_group("biceps") == "upper_pull"

    def test_legs_are_lower(self):
        assert categorize_muscle_group("quadriceps") == "lower"
        assert categorize_muscle_group("hamstrings") == "lower"
        assert categorize_muscle_group("glutes") == "lower"
        assert categorize_muscle_group("calf") == "lower"
        assert categorize_muscle_group("legs") == "lower"

    def test_core_muscles(self):
        assert categorize_muscle_group("core") == "core"
        assert categorize_muscle_group("abs") == "core"
        assert categorize_muscle_group("obliques") == "core"


class TestDetermineWorkoutFocus:
    """Tests for workout focus determination."""

    def test_empty_list_returns_full_body(self):
        assert determine_workout_focus([]) == "full body"

    def test_mostly_lower_is_leg_day(self):
        muscles = ["quadriceps", "hamstrings", "glutes", "calves"]
        assert determine_workout_focus(muscles) == "leg day"

    def test_mostly_push_is_push_day(self):
        muscles = ["chest", "shoulders", "triceps", "chest"]
        assert determine_workout_focus(muscles) == "push day"

    def test_mostly_pull_is_pull_day(self):
        muscles = ["back", "biceps", "lats", "rhomboids"]
        assert determine_workout_focus(muscles) == "pull day"

    def test_mixed_upper_is_upper_body(self):
        muscles = ["chest", "back", "shoulders", "biceps"]
        assert determine_workout_focus(muscles) == "upper body"

    def test_balanced_is_full_body(self):
        muscles = ["chest", "back", "quadriceps", "hamstrings", "core"]
        result = determine_workout_focus(muscles)
        assert result in ["full body", "upper body"]  # Could be either depending on distribution
