"""
Tests for workouts utility functions.

Tests cover:
- parse_json_field
- row_to_workout
- get_workout_focus
- calculate_workout_date
- calculate_monthly_dates
- extract_name_words
"""
import pytest
from datetime import datetime, timedelta

from api.v1.workouts.utils import (
    parse_json_field,
    row_to_workout,
    get_workout_focus,
    calculate_workout_date,
    calculate_monthly_dates,
    extract_name_words,
)
from models.schemas import Workout


class TestParseJsonField:
    """Tests for parse_json_field utility."""

    def test_parse_json_field_with_string(self):
        """Test parsing a valid JSON string."""
        result = parse_json_field('["a", "b"]', [])
        assert result == ["a", "b"]

    def test_parse_json_field_with_dict_string(self):
        """Test parsing a JSON dict string."""
        result = parse_json_field('{"key": "value"}', {})
        assert result == {"key": "value"}

    def test_parse_json_field_with_already_parsed_list(self):
        """Test with already parsed list."""
        result = parse_json_field(["a", "b"], [])
        assert result == ["a", "b"]

    def test_parse_json_field_with_already_parsed_dict(self):
        """Test with already parsed dict."""
        result = parse_json_field({"key": "value"}, {})
        assert result == {"key": "value"}

    def test_parse_json_field_with_none(self):
        """Test with None value."""
        result = parse_json_field(None, [])
        assert result == []

    def test_parse_json_field_with_invalid_json(self):
        """Test with invalid JSON returns default."""
        result = parse_json_field("not json", [])
        assert result == []

    def test_parse_json_field_with_non_collection_value(self):
        """Test with non-list/dict value returns default."""
        result = parse_json_field(123, [])
        assert result == []


class TestRowToWorkout:
    """Tests for row_to_workout conversion."""

    def test_row_to_workout_minimal(self):
        """Test conversion with minimal data."""
        row = {
            "id": "123",
            "user_id": "user-1",
            "name": "Test Workout",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
            "is_completed": False,
        }
        workout = row_to_workout(row)
        assert workout.id == "123"
        assert workout.user_id == "user-1"
        assert workout.name == "Test Workout"
        assert workout.type == "strength"

    def test_row_to_workout_with_exercises_list(self):
        """Test conversion with exercises as list."""
        row = {
            "id": "123",
            "user_id": "user-1",
            "name": "Test",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
            "exercises_json": [{"name": "Squat", "sets": 3}],
        }
        workout = row_to_workout(row)
        assert workout.exercises_json == '[{"name": "Squat", "sets": 3}]'

    def test_row_to_workout_with_exercises_string(self):
        """Test conversion with exercises as string."""
        row = {
            "id": "123",
            "user_id": "user-1",
            "name": "Test",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
            "exercises_json": '[{"name": "Squat"}]',
        }
        workout = row_to_workout(row)
        assert workout.exercises_json == '[{"name": "Squat"}]'

    def test_row_to_workout_with_versioning_fields(self):
        """Test conversion includes SCD2 versioning fields."""
        row = {
            "id": "123",
            "user_id": "user-1",
            "name": "Test",
            "type": "strength",
            "difficulty": "medium",
            "scheduled_date": "2024-01-15",
            "version_number": 2,
            "is_current": True,
            "valid_from": "2024-01-01",
            "valid_to": None,
            "parent_workout_id": "parent-123",
        }
        workout = row_to_workout(row)
        assert workout.version_number == 2
        assert workout.is_current is True
        assert workout.parent_workout_id == "parent-123"


class TestGetWorkoutFocus:
    """Tests for get_workout_focus function."""

    def test_full_body_split(self):
        """Test full_body split returns rotating emphasis."""
        result = get_workout_focus("full_body", [0, 2, 4])
        assert result[0] == "full_body_push"
        assert result[2] == "full_body_pull"
        assert result[4] == "full_body_legs"

    def test_upper_lower_split(self):
        """Test upper_lower split alternates correctly."""
        result = get_workout_focus("upper_lower", [0, 1, 2, 3])
        assert result[0] == "upper"
        assert result[1] == "lower"
        assert result[2] == "upper"
        assert result[3] == "lower"

    def test_push_pull_legs_split(self):
        """Test push_pull_legs split rotates correctly."""
        result = get_workout_focus("push_pull_legs", [0, 1, 2])
        assert result[0] == "push"
        assert result[1] == "pull"
        assert result[2] == "legs"

    def test_body_part_split(self):
        """Test body_part split assigns different muscles."""
        result = get_workout_focus("body_part", [0, 1, 2, 3, 4, 5])
        assert result[0] == "chest"
        assert result[1] == "back"
        assert result[5] == "core"

    def test_unknown_split_defaults_to_full_body(self):
        """Test unknown split defaults to full_body."""
        result = get_workout_focus("unknown", [0, 1])
        assert result[0] == "full_body"
        assert result[1] == "full_body"


class TestCalculateWorkoutDate:
    """Tests for calculate_workout_date function."""

    def test_calculate_workout_date_day_0(self):
        """Test calculating date for first day."""
        result = calculate_workout_date("2024-01-15", 0)
        assert result == datetime(2024, 1, 15)

    def test_calculate_workout_date_day_3(self):
        """Test calculating date for day 3."""
        result = calculate_workout_date("2024-01-15", 3)
        assert result == datetime(2024, 1, 18)

    def test_calculate_workout_date_day_6(self):
        """Test calculating date for end of week."""
        result = calculate_workout_date("2024-01-15", 6)
        assert result == datetime(2024, 1, 21)


class TestCalculateMonthlyDates:
    """Tests for calculate_monthly_dates function."""

    def test_calculate_monthly_dates_one_week(self):
        """Test calculating dates for one week."""
        result = calculate_monthly_dates("2024-01-15", [0, 2, 4], weeks=1)
        # Should only include dates within the first week
        assert len(result) <= 3

    def test_calculate_monthly_dates_four_weeks(self):
        """Test calculating dates for four weeks."""
        result = calculate_monthly_dates("2024-01-15", [0, 2, 4], weeks=4)
        # Should have approximately 12 workout dates (3 per week x 4 weeks)
        assert 10 <= len(result) <= 14

    def test_calculate_monthly_dates_respects_selected_days(self):
        """Test that only selected days are included."""
        result = calculate_monthly_dates("2024-01-15", [0], weeks=2)
        # Only Mondays should be included
        for date in result:
            assert date.weekday() == 0


class TestExtractNameWords:
    """Tests for extract_name_words function."""

    def test_extract_name_words_basic(self):
        """Test basic word extraction."""
        result = extract_name_words("Upper Body Power")
        assert "upper" in result
        assert "body" in result
        assert "power" in result

    def test_extract_name_words_filters_common_words(self):
        """Test that common words are filtered out."""
        result = extract_name_words("The Workout for Strength")
        assert "the" not in result
        assert "for" not in result
        assert "workout" not in result
        assert "strength" in result

    def test_extract_name_words_filters_short_words(self):
        """Test that short words are filtered out."""
        result = extract_name_words("A to Z Workout")
        assert "a" not in result
        assert "to" not in result

    def test_extract_name_words_empty_string(self):
        """Test with empty string."""
        result = extract_name_words("")
        assert result == []
