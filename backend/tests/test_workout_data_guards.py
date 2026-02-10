"""
Tests for the string-to-dict guard on Gemini workout data responses.

Covers the fix for:
- workouts_db.py:668,813 — Missing guard when Gemini returns a stringified
  or double-stringified JSON instead of a dict.
"""
import json

from api.v1.workouts_db import ensure_workout_data_dict


class TestWorkoutDataStringGuard:
    """Tests for ensure_workout_data_dict() helper."""

    def test_dict_passes_through(self):
        data = {"name": "Workout", "exercises": [{"name": "Squat"}]}
        result = ensure_workout_data_dict(data)
        assert result == data

    def test_string_json_parsed(self):
        data = json.dumps({"name": "W", "exercises": []})
        result = ensure_workout_data_dict(data)
        assert isinstance(result, dict)
        assert result["name"] == "W"

    def test_double_stringified_json(self):
        inner = {"name": "W", "exercises": []}
        data = json.dumps(json.dumps(inner))  # double-stringified
        result = ensure_workout_data_dict(data)
        assert isinstance(result, dict)
        assert result["name"] == "W"

    def test_unparseable_string_becomes_empty_dict(self):
        result = ensure_workout_data_dict("not json")
        assert result == {}

    def test_non_dict_after_parse_becomes_empty(self):
        result = ensure_workout_data_dict("[1,2,3]")
        assert result == {}

    def test_int_becomes_empty_dict(self):
        result = ensure_workout_data_dict(42)
        assert result == {}

    def test_none_becomes_empty_dict(self):
        result = ensure_workout_data_dict(None)
        assert result == {}

    def test_nested_string_in_string(self):
        """Triple-stringified still resolves to dict."""
        inner = {"name": "W"}
        data = json.dumps(json.dumps(json.dumps(inner)))
        result = ensure_workout_data_dict(data)
        assert isinstance(result, dict)
        assert result["name"] == "W"

    def test_empty_string_becomes_empty_dict(self):
        result = ensure_workout_data_dict("")
        assert result == {}

    def test_float_becomes_empty_dict(self):
        result = ensure_workout_data_dict(3.14)
        assert result == {}
