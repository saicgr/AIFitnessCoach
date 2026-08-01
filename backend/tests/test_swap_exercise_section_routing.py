"""
Regression test for E2E register row #154: `POST /swap-exercise` advertised
`section` support in its schema (`SwapExerciseRequest.section`) but
`swap_exercise_in_workout` unconditionally searched the MAIN `exercises_json`
list regardless of `section`. A `section:"warmup"` swap for a move that only
existed in the `warmups` table would 404 "not found in workout" even though
the exercise WAS in the workout — just in the wrong list.

Full-path proof through the real ASGI app, mirroring the row-88 injury-guard
tests in test_injury_terminal_guard.py.
"""
from typing import Any, Dict
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from main import app
from core.auth import get_current_user
import api.v1.workouts.workout_operations as ops_mod

_GUARD = "services.exercise_rag.injury_guard"

pytestmark = pytest.mark.asyncio

USER_ID = "11111111-1111-1111-1111-111111111111"
WORKOUT_ID = "22222222-2222-2222-2222-222222222222"


def _fake_db_with_warmup(warmup_row):
    fake_db = MagicMock()
    fake_db.get_workout.return_value = {
        "id": WORKOUT_ID, "user_id": USER_ID,
        "name": "Full Body", "type": "strength", "difficulty": "intermediate",
        "scheduled_date": "2026-07-30T12:00:00+00:00",
        # The MAIN list does NOT contain the warm-up move — proving the fix
        # actually reads the warmups table, not exercises_json.
        "exercises_json": [{"name": "Goblet Squat", "sets": 3, "reps": 10}],
    }

    warmups_table = MagicMock()
    select_result = MagicMock()
    select_result.data = [warmup_row] if warmup_row else []
    warmups_table.select.return_value.eq.return_value.eq.return_value.execute.return_value = select_result

    update_calls: Dict[str, Any] = {}

    def _capture_update(payload):
        update_calls.update(payload)
        m = MagicMock()
        m.eq.return_value.execute.return_value = MagicMock()
        return m

    warmups_table.update.side_effect = _capture_update

    exercise_swaps_table = MagicMock()
    exercise_swaps_table.insert.return_value.execute.return_value = MagicMock()

    def _table(name):
        if name == "warmups":
            return warmups_table
        if name == "exercise_swaps":
            return exercise_swaps_table
        return MagicMock()

    fake_db.client.table.side_effect = _table
    return fake_db, update_calls


async def test_swap_exercise_section_warmup_finds_and_replaces_in_warmups_table():
    """Before the fix: this always 404'd 'Jumping Jacks not found in workout'
    because the endpoint searched exercises_json (the MAIN list) no matter
    what `section` said. It never looked at the `warmups` table."""
    fake_db, update_calls = _fake_db_with_warmup({
        "id": "warmup-row-1",
        "exercises_json": [
            {"name": "Jumping Jacks", "duration_seconds": 30, "equipment": "none"},
        ],
    })

    app.dependency_overrides[get_current_user] = lambda: {"id": USER_ID}
    try:
        with patch.object(ops_mod, "get_supabase_db", return_value=fake_db), \
             patch.object(ops_mod, "get_active_injuries_with_muscles",
                          AsyncMock(return_value={"injuries": [], "avoided_muscles": []})), \
             patch.object(ops_mod, "get_all_muscles_for_exercise", AsyncMock(return_value=None)), \
             patch(f"{_GUARD}._lookup_library_exercise",
                   lambda name, eid=None: {"name": "High Knees", "id": "lib-3"}), \
             patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as ac:
                resp = await ac.post(
                    "/api/v1/workouts/swap-exercise",
                    json={
                        "workout_id": WORKOUT_ID,
                        "old_exercise_name": "Jumping Jacks",
                        "new_exercise_name": "High Knees",
                        "section": "warmup",
                    },
                )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert resp.status_code == 200, resp.text
    assert update_calls, "the warmups row should have been updated in place"
    swapped = update_calls["exercises_json"]
    assert "High Knees" in swapped
    assert "Jumping Jacks" not in swapped
    # The MAIN workout row must NOT have been touched by a warmup swap.
    fake_db.update_workout.assert_not_called()


async def test_swap_exercise_section_warmup_404s_when_move_absent_from_warmups():
    """A genuinely absent name still 404s — the fix must not become
    accidentally lenient."""
    fake_db, update_calls = _fake_db_with_warmup({
        "id": "warmup-row-1",
        "exercises_json": [{"name": "Arm Circles", "duration_seconds": 30}],
    })

    app.dependency_overrides[get_current_user] = lambda: {"id": USER_ID}
    try:
        with patch.object(ops_mod, "get_supabase_db", return_value=fake_db), \
             patch.object(ops_mod, "get_active_injuries_with_muscles",
                          AsyncMock(return_value={"injuries": [], "avoided_muscles": []})), \
             patch.object(ops_mod, "get_all_muscles_for_exercise", AsyncMock(return_value=None)), \
             patch(f"{_GUARD}._lookup_library_exercise",
                   lambda name, eid=None: {"name": "High Knees", "id": "lib-3"}), \
             patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as ac:
                resp = await ac.post(
                    "/api/v1/workouts/swap-exercise",
                    json={
                        "workout_id": WORKOUT_ID,
                        "old_exercise_name": "Jumping Jacks",
                        "new_exercise_name": "High Knees",
                        "section": "warmup",
                    },
                )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert resp.status_code == 404, resp.text
    assert not update_calls
