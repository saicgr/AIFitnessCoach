"""
Regression test for E2E register row #159: `reshape-for-readiness` rewrote
`exercises_json` / `duration_minutes` / `estimated_calories` in place with NO
audit trail — neither `modification_history` (the column) nor `workout_changes`
(via `log_workout_change`) ever recorded it, unlike every other mutation path
(`services/workout_modifier.py`). A reshaped workout was indistinguishable
after the fact from one that was always that size.

This asserts both surfaces are stamped on apply, matching the shape
`workout_modifier.py` writes (a `modification_history` entry with
type/timestamp/method), and are NOT touched on a preview-only call.
"""
from unittest.mock import MagicMock, patch

import pytest

from api.v1.workouts.reshape import reshape_for_readiness, ReshapeRequest

pytestmark = pytest.mark.asyncio


def _exercise(name):
    return {
        "name": name,
        "sets": 4,
        "reps": 10,
        "rest_seconds": 90,
        "muscle_group": "chest",
    }


class _FakeTable:
    """One persistent mock per table name, so SELECT-time and UPDATE-time
    calls share the same object and the update payload is inspectable."""

    def __init__(self, select_data):
        self.update_payloads = []
        self._select_result = MagicMock()
        self._select_result.data = select_data

    def select(self, *a, **k):
        m = MagicMock()
        m.eq.return_value.maybe_single.return_value.execute.return_value = self._select_result
        return m

    def update(self, payload):
        self.update_payloads.append(payload)
        m = MagicMock()
        m.eq.return_value.eq.return_value.execute.return_value = MagicMock()
        return m

    def upsert(self, *a, **k):
        m = MagicMock()
        m.execute.return_value = MagicMock()
        return m


def _make_sb(workout_row):
    workouts_table = _FakeTable(workout_row)
    readiness_table = _FakeTable(None)

    sb = MagicMock()

    def _table(name):
        if name == "workouts":
            return workouts_table
        return readiness_table

    sb.client.table.side_effect = _table
    return sb, workouts_table


async def test_reshape_apply_stamps_modification_history_and_workout_changes():
    workout_row = {
        "id": "workout-1",
        "user_id": "user-1",
        "type": "strength",
        "difficulty": "medium",
        "duration_minutes": 52,
        "exercises_json": [_exercise(f"Move {i}") for i in range(6)],
        # Pre-existing history from an earlier (unrelated) edit — the new
        # entry must be APPENDED, not overwrite it.
        "modification_history": [{"type": "user_edit", "timestamp": "earlier"}],
    }
    sb, workouts_table = _make_sb(workout_row)

    req = ReshapeRequest(available_minutes=15, apply=True)

    with patch("api.v1.workouts.reshape.get_supabase_db", return_value=sb), \
         patch("api.v1.workouts.reshape.resolve_user_weight_kg", return_value=80.0), \
         patch("api.v1.workouts.reshape.log_workout_change") as mock_log_change:
        result = await reshape_for_readiness(
            req, workout_id="workout-1",
            current_user={"id": "user-1"},
        )

    assert result.applied is True, f"reasons={result.reasons}"

    assert workouts_table.update_payloads, "workouts row must have been updated"
    payload = workouts_table.update_payloads[-1]

    # 1) `modification_history` column: appended, not clobbered.
    assert "modification_history" in payload, (
        "the bug: exercises_json/duration/calories were rewritten with no "
        "modification_history entry, so a reshaped workout was indistinguishable "
        "after the fact from one that was always that size"
    )
    history = payload["modification_history"]
    assert len(history) == 2
    assert history[0] == {"type": "user_edit", "timestamp": "earlier"}
    new_entry = history[1]
    assert new_entry["type"] == "reshape_for_readiness"
    assert new_entry["method"] == "pre_workout_checkin"
    assert "timestamp" in new_entry
    assert new_entry["reasons"] == result.reasons

    # 2) `workout_changes` audit log via log_workout_change (the same helper
    # every other mutation endpoint in workout_operations.py uses).
    mock_log_change.assert_called_once()
    args, kwargs = mock_log_change.call_args
    assert args[0] == "workout-1"
    assert args[1] == "user-1"
    assert args[2] == "reshape_for_readiness"


async def test_reshape_preview_does_not_touch_audit_surfaces():
    """apply=False (preview only) must not write modification_history or log
    a workout_changes row — nothing was actually persisted."""
    workout_row = {
        "id": "workout-1",
        "user_id": "user-1",
        "type": "strength",
        "difficulty": "medium",
        "duration_minutes": 52,
        "exercises_json": [_exercise(f"Move {i}") for i in range(6)],
        "modification_history": [],
    }
    sb, workouts_table = _make_sb(workout_row)

    req = ReshapeRequest(available_minutes=15, apply=False)

    with patch("api.v1.workouts.reshape.get_supabase_db", return_value=sb), \
         patch("api.v1.workouts.reshape.resolve_user_weight_kg", return_value=80.0), \
         patch("api.v1.workouts.reshape.log_workout_change") as mock_log_change:
        result = await reshape_for_readiness(
            req, workout_id="workout-1",
            current_user={"id": "user-1"},
        )

    assert result.applied is False
    assert result.reshaped is True  # would have reshaped, just not applied
    assert not workouts_table.update_payloads
    mock_log_change.assert_not_called()
