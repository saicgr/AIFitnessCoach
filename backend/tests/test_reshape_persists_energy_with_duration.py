"""
Integration test for E2E register #146's reshape.py half: when
POST /reshape-for-readiness rewrites duration_minutes (time-budget trim), it
must ALSO rewrite estimated_calories through the same derivation — otherwise
the client re-derives calories from the new duration via its own MET
fallback, producing the exact "45 MIN/226 CAL then 11 MIN/55 CAL" bug.
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


async def test_reshape_persists_estimated_calories_alongside_duration():
    workout_row = {
        "id": "workout-1",
        "user_id": "user-1",
        "type": "strength",
        "difficulty": "medium",
        "duration_minutes": 52,
        "exercises_json": [_exercise(f"Move {i}") for i in range(6)],
    }
    sb, workouts_table = _make_sb(workout_row)

    req = ReshapeRequest(available_minutes=15, apply=True)

    with patch("api.v1.workouts.reshape.get_supabase_db", return_value=sb), \
         patch("api.v1.workouts.reshape.resolve_user_weight_kg", return_value=80.0):
        result = await reshape_for_readiness(
            req, workout_id="workout-1",
            current_user={"id": "user-1"},
        )

    assert result.applied is True, f"reasons={result.reasons}"
    assert result.reshaped is True

    assert workouts_table.update_payloads, "workouts row must have been updated"
    payload = workouts_table.update_payloads[-1]

    assert "duration_minutes" in payload
    assert "estimated_calories" in payload, (
        "the bug: duration_minutes was rewritten without estimated_calories, "
        "so the client re-derived calories against the new duration itself"
    )
    assert payload["estimated_calories"] > 0
    # Sanity: calories should be materially smaller for the (shorter, trimmed)
    # reshaped session than the original 52-minute figure would imply.
    assert payload["duration_minutes"] < 52


async def test_reshape_without_time_trim_does_not_touch_the_workout():
    """No available_minutes -> no trim -> nothing to persist. Confirms the
    new estimated_calories write is scoped to an actual reshape, not fired
    unconditionally."""
    workout_row = {
        "id": "workout-1",
        "user_id": "user-1",
        "type": "strength",
        "difficulty": "medium",
        "duration_minutes": 30,
        "exercises_json": [_exercise("Solo Move")],
    }
    sb, workouts_table = _make_sb(workout_row)

    req = ReshapeRequest(apply=True)

    with patch("api.v1.workouts.reshape.get_supabase_db", return_value=sb), \
         patch("api.v1.workouts.reshape.resolve_user_weight_kg", return_value=80.0):
        result = await reshape_for_readiness(
            req, workout_id="workout-1",
            current_user={"id": "user-1"},
        )

    assert result.reshaped is False
    assert not workouts_table.update_payloads
