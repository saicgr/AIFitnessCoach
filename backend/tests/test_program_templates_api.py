"""Unit tests for api/v1/program_templates.py.

The router's HTTP layer cannot be exercised here: this repo's installed
httpx (0.28.1) / starlette (0.35.1) pair is version-skewed, so
`fastapi.testclient.TestClient(app)` raises
`TypeError: __init__() got an unexpected keyword argument 'app'` for EVERY
TestClient-based test in the suite (e.g. test_chat_api.py errors identically).
That is a pre-existing environment issue, unrelated to the program-template
feature.

So this file does what the task asks when TestClient is unavailable: it
unit-tests the request/response Pydantic models (validation + rejection) and
the router's pure helper functions, with no HTTP and no live DB.
"""
import os
import sys

import pytest
from pydantic import ValidationError

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# .env is needed because importing the router pulls in core.supabase_client.
from dotenv import load_dotenv  # noqa: E402

load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"))
os.environ.setdefault("USE_MOCK_DATA", "true")

from api.v1.program_templates import (  # noqa: E402
    LibraryProgramCard,
    LibraryBrowseResponse,
    TemplateCreateRequest,
    TemplatePatchRequest,
    ParseRequest,
    ScheduleRequest,
    _has_workouts,
    _sessions_per_week,
)


# =============================================================================
# LibraryProgramCard — the library browse-grid card
# =============================================================================
class TestLibraryProgramCard:
    def test_minimal_valid_card(self):
        """Only id + program_name are required; the rest are optional."""
        card = LibraryProgramCard(id="p1", program_name="Push Pull Legs")
        assert card.id == "p1"
        assert card.program_name == "Push Pull Legs"
        assert card.goals == []
        assert card.celebrity_name is None
        assert card.duration_weeks is None

    def test_full_card(self):
        card = LibraryProgramCard(
            id="p2",
            program_name="Hero Program",
            program_category="strength",
            celebrity_name="Some Athlete",
            difficulty_level="Advanced",
            duration_weeks=12,
            sessions_per_week=5,
            session_duration_minutes=60,
            description="A serious program",
            goals=["build muscle", "get strong"],
        )
        assert card.duration_weeks == 12
        assert card.goals == ["build muscle", "get strong"]

    def test_missing_program_name_rejected(self):
        with pytest.raises(ValidationError):
            LibraryProgramCard(id="p3")

    def test_missing_id_rejected(self):
        with pytest.raises(ValidationError):
            LibraryProgramCard(program_name="Nameless")

    def test_goals_must_be_a_list(self):
        with pytest.raises(ValidationError):
            LibraryProgramCard(id="p4", program_name="Bad", goals="not-a-list")


class TestLibraryBrowseResponse:
    def test_valid_response(self):
        resp = LibraryBrowseResponse(
            total=1,
            programs=[LibraryProgramCard(id="p1", program_name="X")],
        )
        assert resp.total == 1
        assert len(resp.programs) == 1

    def test_empty_response(self):
        """An empty filtered result is valid: total=0, programs=[] (#L14)."""
        resp = LibraryBrowseResponse(total=0, programs=[])
        assert resp.total == 0
        assert resp.programs == []


# =============================================================================
# TemplateCreateRequest — authored / reviewed template payload
# =============================================================================
class TestTemplateCreateRequest:
    def _days(self):
        return [
            {"day_index": 0, "is_rest": False,
             "exercises": [{"name": "Squat"}]},
        ]

    def test_minimal_valid_request(self):
        req = TemplateCreateRequest(name="My Program", days=self._days())
        assert req.name == "My Program"
        # Defaults.
        assert req.week_length == 7
        assert req.deload_every_n_weeks == 5
        assert req.progression_strategy == "linear"
        assert req.apply_staples is True
        assert req.source == "authored"

    def test_empty_name_rejected(self):
        """name has min_length=1 -> an empty string fails validation."""
        with pytest.raises(ValidationError):
            TemplateCreateRequest(name="", days=self._days())

    def test_missing_name_rejected(self):
        with pytest.raises(ValidationError):
            TemplateCreateRequest(days=self._days())

    def test_missing_days_rejected(self):
        """days is a required field with no default."""
        with pytest.raises(ValidationError):
            TemplateCreateRequest(name="No Days")

    def test_week_length_must_be_positive(self):
        """week_length has ge=1 -> 0 is rejected."""
        with pytest.raises(ValidationError):
            TemplateCreateRequest(
                name="Bad", days=self._days(), week_length=0
            )

    def test_week_length_one_is_allowed(self):
        req = TemplateCreateRequest(
            name="Single Week", days=self._days(), week_length=1
        )
        assert req.week_length == 1

    def test_custom_fields_round_trip(self):
        req = TemplateCreateRequest(
            name="From Library",
            days=self._days(),
            week_length=10,
            deload_every_n_weeks=None,
            progression_strategy="none",
            apply_staples=False,
            source="library",
            source_program_id="prog-123",
            category="powerlifting",
        )
        assert req.source == "library"
        assert req.source_program_id == "prog-123"
        assert req.deload_every_n_weeks is None
        assert req.progression_strategy == "none"

    def test_empty_days_list_passes_model_but_is_caught_by_endpoint(self):
        """An empty days list satisfies the model (List is required, not
        non-empty); the endpoint itself enforces >=1 training day."""
        req = TemplateCreateRequest(name="Empty", days=[])
        assert req.days == []


class TestTemplatePatchRequest:
    def test_all_fields_optional(self):
        """A patch with no fields is valid (a no-op patch)."""
        req = TemplatePatchRequest()
        assert req.name is None
        assert req.days is None
        assert req.week_length is None

    def test_partial_patch(self):
        req = TemplatePatchRequest(name="Renamed")
        assert req.name == "Renamed"
        assert req.description is None

    def test_week_length_still_bounded(self):
        """When provided, week_length must still be >= 1."""
        with pytest.raises(ValidationError):
            TemplatePatchRequest(week_length=0)

    def test_week_length_valid_when_provided(self):
        req = TemplatePatchRequest(week_length=8)
        assert req.week_length == 8


# =============================================================================
# ParseRequest — free-text parse payload
# =============================================================================
class TestParseRequest:
    def test_valid_request(self):
        req = ParseRequest(description="Day 1: Bench Press 3x8")
        assert req.description.startswith("Day 1")

    def test_empty_description_rejected(self):
        """description has min_length=1."""
        with pytest.raises(ValidationError):
            ParseRequest(description="")

    def test_missing_description_rejected(self):
        with pytest.raises(ValidationError):
            ParseRequest()


# =============================================================================
# ScheduleRequest — template -> workouts scheduling payload
# =============================================================================
class TestScheduleRequest:
    def test_minimal_valid_request(self):
        req = ScheduleRequest(start_date="2026-06-01", weeks=4)
        # start_date is coerced to a date object.
        assert req.start_date.isoformat() == "2026-06-01"
        assert req.weeks == 4
        # Defaults.
        assert req.day_alignment == "start_today"
        assert req.day_times == {}

    def test_weeks_must_be_at_least_one(self):
        """weeks has ge=1 -> 0 is rejected."""
        with pytest.raises(ValidationError):
            ScheduleRequest(start_date="2026-06-01", weeks=0)

    def test_negative_weeks_rejected(self):
        with pytest.raises(ValidationError):
            ScheduleRequest(start_date="2026-06-01", weeks=-3)

    def test_missing_start_date_rejected(self):
        with pytest.raises(ValidationError):
            ScheduleRequest(weeks=4)

    def test_missing_weeks_rejected(self):
        with pytest.raises(ValidationError):
            ScheduleRequest(start_date="2026-06-01")

    def test_invalid_date_string_rejected(self):
        with pytest.raises(ValidationError):
            ScheduleRequest(start_date="not-a-date", weeks=4)

    def test_day_times_custom_map(self):
        req = ScheduleRequest(
            start_date="2026-06-01",
            weeks=2,
            day_alignment="calendar_weekday",
            day_times={"0": "07:00", "2": "18:30"},
        )
        assert req.day_alignment == "calendar_weekday"
        assert req.day_times["0"] == "07:00"
        assert req.day_times["2"] == "18:30"

    def test_day_alignment_is_free_string_at_model_level(self):
        """The model does not enum-restrict day_alignment; the endpoint
        rejects unknown values. The model itself accepts any string."""
        req = ScheduleRequest(
            start_date="2026-06-01", weeks=1, day_alignment="anything"
        )
        assert req.day_alignment == "anything"


# =============================================================================
# _has_workouts — the empty-program structural filter (X3)
# =============================================================================
class TestHasWorkouts:
    def test_list_blob_with_entries(self):
        assert _has_workouts({"workouts": [{"day": 1}]}) is True

    def test_empty_list_blob(self):
        assert _has_workouts({"workouts": []}) is False

    def test_dict_blob_with_nested_workouts(self):
        assert _has_workouts({"workouts": {"workouts": [{"day": 1}]}}) is True

    def test_dict_blob_with_empty_nested_workouts(self):
        assert _has_workouts({"workouts": {"workouts": []}}) is False

    def test_missing_workouts_key(self):
        assert _has_workouts({"program_name": "X"}) is False

    def test_null_workouts(self):
        assert _has_workouts({"workouts": None}) is False


# =============================================================================
# _sessions_per_week — sessions count derivation
# =============================================================================
class TestSessionsPerWeek:
    def test_explicit_sessions_per_week_used(self):
        assert _sessions_per_week({"sessions_per_week": 5}) == 5

    def test_derived_from_list_blob(self):
        """With no explicit count, count workout entries that have exercises."""
        program = {
            "workouts": [
                {"day": 1, "exercises": [{"name": "Squat"}]},
                {"day": 2, "exercises": []},          # rest day, not counted
                {"day": 3, "exercises": [{"name": "Bench"}]},
            ]
        }
        assert _sessions_per_week(program) == 2

    def test_derived_from_dict_blob(self):
        program = {
            "workouts": {
                "workouts": [
                    {"day": 1, "exercises": [{"name": "Squat"}]},
                    {"day": 2, "exercises": [{"name": "Bench"}]},
                ]
            }
        }
        assert _sessions_per_week(program) == 2

    def test_explicit_count_takes_precedence_over_blob(self):
        program = {
            "sessions_per_week": 3,
            "workouts": [{"day": 1, "exercises": [{"name": "Squat"}]}],
        }
        assert _sessions_per_week(program) == 3

    def test_no_data_returns_none(self):
        assert _sessions_per_week({"program_name": "X"}) is None
