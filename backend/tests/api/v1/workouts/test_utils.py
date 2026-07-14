"""
Tests for workouts utility functions.

Tests cover:
- parse_json_field
- row_to_workout
- get_workout_focus
- _calculate_next_workout_date (the surviving workout-date scheduler)
- extract_name_words
- get_user_progression_pace
- get_user_workout_type_preference

Import note: `api.v1.workouts.utils` was split into sub-modules
(schedule_utils, user_preference_utils, ...) and re-exports them for backwards
compatibility, so `get_workout_focus` / `extract_name_words` /
`get_user_*_preference` still import from `utils`. The functions are *defined*
elsewhere, though, which matters for `patch()` targets — see
TestGetUserProgressionPace.
"""
import json

import pytest
from datetime import date, datetime, timedelta
from unittest.mock import patch, MagicMock, AsyncMock

from api.v1.workouts.utils import (
    parse_json_field,
    row_to_workout,
    get_workout_focus,
    extract_name_words,
    get_user_progression_pace,
    get_user_workout_type_preference,
)
from api.v1.workouts.today import _calculate_next_workout_date
from models.schemas import Workout

# get_supabase_db is looked up in the module where the function under test is
# DEFINED (user_preference_utils), not where it is re-exported (utils).
_PREF_DB = "api.v1.workouts.user_preference_utils.get_supabase_db"


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
        """Test conversion with exercises as list.

        Retired behavior updated: this used to assert `exercises_json` was a
        byte-for-byte re-dump of the input list. `row_to_workout` now also
        attaches serve-time tracking metadata (`attach_tracking_metadata`,
        api/v1/workouts/utils.py:1115) so the client renders cardio / carry /
        timed stations as something other than "weight x reps". The original
        guarantee — every input field survives the round-trip unchanged — is
        asserted exactly, plus the metadata that is now part of the contract.
        """
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
        exercises = json.loads(workout.exercises_json)
        assert len(exercises) == 1
        assert exercises[0]["name"] == "Squat"
        assert exercises[0]["sets"] == 3
        assert exercises[0]["tracking_type"] == "weight"
        assert exercises[0]["metric_keys"] == ["weight", "reps"]

    def test_row_to_workout_with_exercises_string(self):
        """Test conversion with exercises as string.

        Same update as test_row_to_workout_with_exercises_list: a JSON *string*
        input is parsed, enriched with tracking metadata, and re-serialized —
        so the assertion is on the parsed payload, not on string equality.
        """
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
        exercises = json.loads(workout.exercises_json)
        assert len(exercises) == 1
        assert exercises[0]["name"] == "Squat"
        assert exercises[0]["tracking_type"] == "weight"
        assert exercises[0]["metric_keys"] == ["weight", "reps"]

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
        """Test body_part split assigns different muscles.

        Retired label updated: the bro-split day 6 focus used to be plain
        "core". `schedule_utils.get_workout_focus` (the implementation
        `api.v1.workouts.utils` re-exports, and the one today.py generates
        from) renamed it to "core_cardio" when bro_split/body_part were merged
        onto one focus table. Same guarantee: six training days map to six
        DISTINCT body-part focuses in a fixed order, ending on the core day.
        """
        result = get_workout_focus("body_part", [0, 1, 2, 3, 4, 5])
        assert result[0] == "chest"
        assert result[1] == "back"
        assert result[5] == "core_cardio"
        assert len(set(result.values())) == 6

    def test_unknown_split_defaults_to_full_body(self):
        """Test unknown split defaults to the full-body family.

        Retired behavior updated: an unknown split used to map EVERY day to the
        bare focus "full_body". It now falls back to the same rotating
        full-body emphasis table the explicit `full_body` split uses
        (full_body_push / _pull / _legs / ...), so a user on an unrecognised
        split still trains the whole body but doesn't repeat one identical
        session every day. Intent preserved (unknown -> full body, never a
        partial split); assertion made exact against the current rotation.
        """
        result = get_workout_focus("unknown", [0, 1])
        assert result[0] == "full_body_push"
        assert result[1] == "full_body_pull"
        assert all(focus.startswith("full_body") for focus in result.values())


def _scheduled_dates(selected_days, start: date, weeks: int):
    """Every date a workout would be scheduled on in a `weeks`-long window.

    Replays the current scheduler day by day: for each calendar day in the
    window, ask `_calculate_next_workout_date` where the next workout lands and
    keep it if it is still inside the window. This is the horizon the rolling
    generator fills (today.py `_get_upcoming_dates_needing_generation`).
    """
    end = start + timedelta(days=weeks * 7)
    dates = set()
    day = start
    while day < end:
        nxt = date.fromisoformat(
            _calculate_next_workout_date(selected_days, user_today_str=day.isoformat())
        )
        if nxt < end:
            dates.add(nxt)
        day += timedelta(days=1)
    return sorted(dates)


class TestCalculateWorkoutDate:
    """Tests for resolving a workout's calendar date from the training schedule.

    RETIRED FUNCTION: `api.v1.workouts.utils.calculate_workout_date(week_start,
    day_index)` was deleted in 3063fbd1, when monthly batch generation
    (`GenerateMonthlyRequest` -> fan out `month_start_date` + `selected_days`
    into N weeks of rows) was replaced by rolling per-day generation. Nothing
    calls a `week_start + day_index` offset any more.

    The surviving primitive with the same job — "given the user's training days,
    what calendar date does a workout land on?" — is
    `today.py::_calculate_next_workout_date`, used by generation_endpoints,
    generation_streaming, versioning and today. These cases are the originals
    re-expressed against it: same anchor Monday 2024-01-15, same expected
    dates (Jan 15 / 18 / 21).
    """

    def test_next_workout_date_is_today_when_today_is_a_training_day(self):
        """Monday anchor, Monday is a training day -> schedule for today."""
        result = _calculate_next_workout_date([0, 2, 4], user_today_str="2024-01-15")
        assert result == "2024-01-15"

    def test_next_workout_date_advances_to_next_training_day(self):
        """Monday anchor, Thursday-only schedule -> 3 days out (Jan 18)."""
        result = _calculate_next_workout_date([3], user_today_str="2024-01-15")
        assert result == "2024-01-18"

    def test_next_workout_date_reaches_end_of_week(self):
        """Monday anchor, Sunday-only schedule -> 6 days out (Jan 21)."""
        result = _calculate_next_workout_date([6], user_today_str="2024-01-15")
        assert result == "2024-01-21"


class TestCalculateMonthlyDates:
    """Tests for the multi-week schedule the generator fills.

    RETIRED FUNCTION: `calculate_monthly_dates(month_start_date, selected_days,
    weeks)` was deleted alongside `calculate_workout_date` (see above) — its
    callers in generation.py / workouts_db.py went away with monthly batch
    generation. The guarantee it protected is still load-bearing, so it is
    re-expressed here over the current scheduler via `_scheduled_dates`:
    workouts land on the user's selected weekdays and only those, for as many
    weeks ahead as we look. Assertions tightened from the originals' loose
    bounds (`<= 3`, `10 <= len <= 14`) to the exact counts, which the current
    scheduler is deterministic enough to guarantee.
    """

    def test_one_week_horizon(self):
        """One week of a 3-day schedule = exactly 3 workout dates."""
        result = _scheduled_dates([0, 2, 4], date(2024, 1, 15), weeks=1)
        assert result == [date(2024, 1, 15), date(2024, 1, 17), date(2024, 1, 19)]

    def test_four_week_horizon(self):
        """Four weeks of a 3-day schedule = exactly 12 workout dates (3 x 4)."""
        result = _scheduled_dates([0, 2, 4], date(2024, 1, 15), weeks=4)
        assert len(result) == 12

    def test_respects_selected_days(self):
        """Only selected weekdays are ever scheduled."""
        result = _scheduled_dates([0], date(2024, 1, 15), weeks=2)
        assert len(result) == 2
        for scheduled in result:
            assert scheduled.weekday() == 0


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


class TestGetUserProgressionPace:
    """Tests for get_user_progression_pace function."""

    @pytest.mark.asyncio
    async def test_returns_medium_when_no_user_found(self):
        """Test that medium is returned when user doesn't exist."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(data=[])
            mock_db.return_value.client = mock_client

            result = await get_user_progression_pace("non-existent-user")
            assert result == "medium"

    @pytest.mark.asyncio
    async def test_returns_slow_pace(self):
        """Test that slow pace is returned when set."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": {"progression_pace": "slow"}}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_progression_pace("user-123")
            assert result == "slow"

    @pytest.mark.asyncio
    async def test_returns_fast_pace(self):
        """Test that fast pace is returned when set."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": {"progression_pace": "fast"}}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_progression_pace("user-123")
            assert result == "fast"

    @pytest.mark.asyncio
    async def test_returns_medium_for_invalid_pace(self):
        """Test that medium is returned for invalid pace values."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": {"progression_pace": "invalid_pace"}}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_progression_pace("user-123")
            assert result == "medium"

    @pytest.mark.asyncio
    async def test_handles_string_preferences(self):
        """Test that JSON string preferences are parsed correctly."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": '{"progression_pace": "slow"}'}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_progression_pace("user-123")
            assert result == "slow"

    @pytest.mark.asyncio
    async def test_handles_null_preferences(self):
        """Test that null preferences returns medium."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": None}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_progression_pace("user-123")
            assert result == "medium"

    @pytest.mark.asyncio
    async def test_handles_database_exception(self):
        """Test that database exceptions return medium."""
        with patch(_PREF_DB) as mock_db:
            mock_db.side_effect = Exception("Database error")

            result = await get_user_progression_pace("user-123")
            assert result == "medium"


class TestGetUserWorkoutTypePreference:
    """Tests for get_user_workout_type_preference function."""

    @pytest.mark.asyncio
    async def test_returns_strength_when_no_user_found(self):
        """Test that strength is returned when user doesn't exist."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(data=[])
            mock_db.return_value.client = mock_client

            result = await get_user_workout_type_preference("non-existent-user")
            assert result == "strength"

    @pytest.mark.asyncio
    async def test_returns_cardio_type(self):
        """Test that cardio type is returned when set."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": {"workout_type_preference": "cardio"}}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_workout_type_preference("user-123")
            assert result == "cardio"

    @pytest.mark.asyncio
    async def test_returns_mixed_type(self):
        """Test that mixed type is returned when set."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": {"workout_type_preference": "mixed"}}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_workout_type_preference("user-123")
            assert result == "mixed"

    @pytest.mark.asyncio
    async def test_returns_mobility_type(self):
        """Test that mobility type is returned when set."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": {"workout_type_preference": "mobility"}}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_workout_type_preference("user-123")
            assert result == "mobility"

    @pytest.mark.asyncio
    async def test_returns_recovery_type(self):
        """Test that recovery type is returned when set."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": {"workout_type_preference": "recovery"}}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_workout_type_preference("user-123")
            assert result == "recovery"

    @pytest.mark.asyncio
    async def test_returns_strength_for_invalid_type(self):
        """Test that strength is returned for invalid type values."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": {"workout_type_preference": "invalid_type"}}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_workout_type_preference("user-123")
            assert result == "strength"

    @pytest.mark.asyncio
    async def test_handles_string_preferences(self):
        """Test that JSON string preferences are parsed correctly."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": '{"workout_type_preference": "cardio"}'}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_workout_type_preference("user-123")
            assert result == "cardio"

    @pytest.mark.asyncio
    async def test_handles_null_preferences(self):
        """Test that null preferences returns strength."""
        with patch(_PREF_DB) as mock_db:
            mock_client = MagicMock()
            mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[{"preferences": None}]
            )
            mock_db.return_value.client = mock_client

            result = await get_user_workout_type_preference("user-123")
            assert result == "strength"

    @pytest.mark.asyncio
    async def test_handles_database_exception(self):
        """Test that database exceptions return strength."""
        with patch(_PREF_DB) as mock_db:
            mock_db.side_effect = Exception("Database error")

            result = await get_user_workout_type_preference("user-123")
            assert result == "strength"
