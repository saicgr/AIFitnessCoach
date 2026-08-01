"""Regression gate for E2E #158 — a finalize must never silently no-op.

The bug: `create_workout_log`'s migration-2247 double-log guard returned an
existing row UNTOUCHED whenever the idempotency key matched. The Easy-tier
finalize reaches that path carrying the session's real sets, while the stored
row is still the empty shell first-set persistence created (`sets_json='[]'`,
status `in_progress`). So the finalize wrote nothing, the endpoint logged
"Workout log created" and returned 200, and the client reported success.

Observed live: 20 identical POSTs in 18 seconds, every one resolving to the
same row id, every one 200 OK, zero net writes — a completed workout recorded
nowhere, and `workout_log_id=None` handed to the downstream goals sync.

The fix treats "empty stored row + payload with real sets" as an UPGRADE
rather than a duplicate. These tests pin both directions, because the guard
must keep working for true replays — that is what it is for.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from core.db.workout_db import (  # noqa: E402
    _FINALIZE_MERGE_FIELDS,
    _carries_new_session_data,
    _is_empty_sets,
)


class TestIsEmptySets:
    """sets_json has had four shapes in this codebase; all must be handled."""

    def test_none_is_empty(self):
        assert _is_empty_sets(None) is True

    def test_empty_list_is_empty(self):
        assert _is_empty_sets([]) is True

    def test_bracket_string_is_empty(self):
        # The literal shape first-set persistence writes.
        assert _is_empty_sets("[]") is True
        assert _is_empty_sets("  []  ") is True

    def test_blank_and_null_strings_are_empty(self):
        assert _is_empty_sets("") is True
        assert _is_empty_sets("null") is True

    def test_populated_list_is_not_empty(self):
        assert _is_empty_sets([{"reps": 10}]) is False

    def test_populated_json_string_is_not_empty(self):
        assert _is_empty_sets('[{"reps": 10, "weight_kg": 40}]') is False


class TestCarriesNewSessionData:
    def test_empty_row_plus_real_payload_merges(self):
        """The exact #158 case: the finalize must win."""
        assert _carries_new_session_data(
            {"sets_json": "[]", "status": "in_progress"},
            {"sets_json": '[{"reps": 9}]'},
        ) is True

    def test_true_replay_changes_nothing(self):
        """Two identical completions — the guard's actual purpose."""
        assert _carries_new_session_data(
            {"sets_json": '[{"reps": 9}]'},
            {"sets_json": '[{"reps": 9}]'},
        ) is False

    def test_empty_payload_never_overwrites_a_real_row(self):
        """A late/duplicate empty write must not blank a finalized session."""
        assert _carries_new_session_data(
            {"sets_json": '[{"reps": 9}]'},
            {"sets_json": "[]"},
        ) is False

    def test_empty_row_and_empty_payload_is_still_a_duplicate(self):
        assert _carries_new_session_data(
            {"sets_json": "[]"}, {"sets_json": "[]"}
        ) is False

    def test_missing_keys_do_not_raise(self):
        assert _carries_new_session_data({}, {}) is False


class TestMergeFieldAllowlist:
    """A replay must never be able to repoint a row at another user/workout."""

    def test_identity_columns_are_not_mergeable(self):
        for forbidden in (
            "user_id",
            "workout_id",
            "idempotency_key",
            "id",
            "gym_profile_id",
        ):
            assert forbidden not in _FINALIZE_MERGE_FIELDS, forbidden

    def test_the_fields_a_finalize_actually_backfills_are_present(self):
        for expected in ("sets_json", "total_time_seconds", "status", "metadata"):
            assert expected in _FINALIZE_MERGE_FIELDS, expected
