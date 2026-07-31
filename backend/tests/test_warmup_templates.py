"""
Tests for saved warm-up templates (E2E register #125, backend piece).

- `_lookup_template`: type-specific row → default (workout_type IS NULL)
  fallback → None on a genuine miss.
- `GET /warmup-template`: 404 (not a fabricated default) when nothing saved.
- `PUT /warmup-template`: insert-when-absent / update-when-present.
- `POST /{workout_id}/warmup/apply-template`: 403 not-owner, 404 no template,
  and the SCD2 supersede-then-insert on a successful apply.

Every `.maybe_single().execute()` call in `warmup_templates.py` is guarded
per the CLAUDE.md rule ("maybe_single() returns None on 0 rows, not a
response with data=None") — `test_get_warmup_template_404_when_none_saved`
and `test_lookup_template_returns_none_when_maybe_single_returns_none` are
the negative tests for that: they feed the REAL `maybe_single()` return
value (`None`, not `SimpleNamespace(data=None)`) through the code, so an
unguarded `res.data` deref would raise `AttributeError: 'NoneType' object
has no attribute 'data'` instead of the expected 404 / None.

Run with: pytest backend/tests/test_warmup_templates.py -v
"""
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException
from starlette.requests import Request


def _http_request(path: str = "/api/v1/workouts/warmup-template") -> Request:
    """A minimal real starlette Request — the endpoints are decorated with
    `@limiter.limit(...)` (slowapi), which reads `.headers`/`.client` off a
    real Request and rejects a stub/MagicMock outright. Mirrors the helper
    in tests/test_recipe_suggestions.py."""
    return Request(
        {
            "type": "http",
            "http_version": "1.1",
            "method": "GET",
            "scheme": "http",
            "path": path,
            "raw_path": path.encode(),
            "query_string": b"",
            "root_path": "",
            "headers": [],
            "client": ("127.0.0.1", 50000),
            "server": ("testserver", 80),
        }
    )


def _mock_db(execute_results):
    """Build a `get_supabase_db()`-shaped mock whose `.execute()` calls
    return `execute_results` in order (a list of return values — pass a bare
    `None` anywhere to simulate what `maybe_single().execute()` really
    returns on 0 rows: the response object itself, not `data=None`)."""
    db = MagicMock()
    db.client.table.return_value.select.return_value.eq.return_value = (
        db.client.table.return_value.select.return_value
    )
    execute_mock = db.client.table.return_value.select.return_value.eq.return_value.maybe_single.return_value.execute
    # Also wire `.is_(...)` (the NULL-workout_type fallback path) and the
    # bare `.select(...).maybe_single()` (no filter) through the SAME
    # execute mock so every call in the file shares one ordered queue.
    db.client.table.return_value.select.return_value.is_.return_value.maybe_single.return_value.execute = execute_mock
    db.client.table.return_value.select.return_value.maybe_single.return_value.execute = execute_mock
    execute_mock.side_effect = list(execute_results)
    return db, execute_mock


# ============================================================================
# _lookup_template — the shared guard helper
# ============================================================================


class TestLookupTemplate:
    def test_returns_type_specific_row_without_fallback_query(self):
        from api.v1.workouts.warmup_templates import _lookup_template

        row = {"workout_type": "strength", "exercises_json": [{"name": "Arm Circles"}]}
        db, execute_mock = _mock_db([SimpleNamespace(data=row)])

        result = _lookup_template(db, "user-1", "strength")

        assert result == row
        assert execute_mock.call_count == 1  # no fallback query needed

    def test_falls_back_to_default_row_when_type_specific_missing(self):
        from api.v1.workouts.warmup_templates import _lookup_template

        default_row = {"workout_type": None, "exercises_json": [{"name": "Jumping Jacks"}]}
        # First call (type-specific): real maybe_single() 0-row return is
        # `None`, not a response object — this is the shape that breaks an
        # unguarded `res.data`.
        db, execute_mock = _mock_db([None, SimpleNamespace(data=default_row)])

        result = _lookup_template(db, "user-1", "strength")

        assert result == default_row
        assert execute_mock.call_count == 2

    def test_returns_none_when_maybe_single_returns_none(self):
        """THE negative-test shape for the maybe_single guard: both queries
        return the real 0-row value (`None`), and the guarded helper must
        return `None` cleanly rather than raising AttributeError."""
        from api.v1.workouts.warmup_templates import _lookup_template

        db, _ = _mock_db([None, None])

        result = _lookup_template(db, "user-1", "strength")

        assert result is None

    def test_no_workout_type_queries_default_only(self):
        from api.v1.workouts.warmup_templates import _lookup_template

        default_row = {"workout_type": None, "exercises_json": []}
        db, execute_mock = _mock_db([SimpleNamespace(data=default_row)])

        result = _lookup_template(db, "user-1", None)

        assert result == default_row
        assert execute_mock.call_count == 1


# ============================================================================
# GET /warmup-template
# ============================================================================


class TestGetWarmupTemplate:
    @pytest.mark.asyncio
    async def test_404_when_none_saved(self):
        """Both lookups miss (real maybe_single() `None` return) → clean 404,
        not an unhandled 500 from an unguarded `.data` access."""
        from api.v1.workouts.warmup_templates import get_warmup_template

        db, _ = _mock_db([None, None])
        with patch("api.v1.workouts.warmup_templates.get_supabase_db", return_value=db):
            with pytest.raises(HTTPException) as exc_info:
                await get_warmup_template(
                    _http_request(),
                    workout_type="strength",
                    current_user={"id": "user-1"},
                )
        assert exc_info.value.status_code == 404

    @pytest.mark.asyncio
    async def test_returns_saved_exercises(self):
        from api.v1.workouts.warmup_templates import get_warmup_template

        row = {
            "workout_type": "strength",
            "exercises_json": [{"name": "Arm Circles", "duration_seconds": 30}],
            "updated_at": "2026-07-30T00:00:00",
        }
        db, _ = _mock_db([SimpleNamespace(data=row)])
        with patch("api.v1.workouts.warmup_templates.get_supabase_db", return_value=db):
            response = await get_warmup_template(
                _http_request(),
                workout_type="strength",
                current_user={"id": "user-1"},
            )
        assert response["workout_type"] == "strength"
        assert response["exercises"] == row["exercises_json"]


# ============================================================================
# PUT /warmup-template
# ============================================================================


class TestSaveWarmupTemplate:
    @pytest.mark.asyncio
    async def test_inserts_when_no_existing_row(self):
        from api.v1.workouts.warmup_templates import (
            SaveWarmupTemplateRequest,
            WarmupTemplateExercise,
            save_warmup_template,
        )

        db, _ = _mock_db([None])  # lookup finds nothing → insert branch
        payload = SaveWarmupTemplateRequest(
            workout_type="strength",
            exercises=[WarmupTemplateExercise(name="Arm Circles", duration_seconds=30)],
        )
        with patch("api.v1.workouts.warmup_templates.get_supabase_db", return_value=db):
            response = await save_warmup_template(
                _http_request(), payload, current_user={"id": "user-1"}
            )

        assert response == {
            "success": True,
            "workout_type": "strength",
            "exercises_count": 1,
        }
        db.client.table.return_value.insert.assert_called_once()
        db.client.table.return_value.update.assert_not_called()

    @pytest.mark.asyncio
    async def test_updates_when_existing_row(self):
        from api.v1.workouts.warmup_templates import (
            SaveWarmupTemplateRequest,
            WarmupTemplateExercise,
            save_warmup_template,
        )

        db, _ = _mock_db([SimpleNamespace(data={"id": "row-1"})])
        payload = SaveWarmupTemplateRequest(
            workout_type="strength",
            exercises=[WarmupTemplateExercise(name="Arm Circles")],
        )
        with patch("api.v1.workouts.warmup_templates.get_supabase_db", return_value=db):
            response = await save_warmup_template(
                _http_request(), payload, current_user={"id": "user-1"}
            )

        assert response["success"] is True
        db.client.table.return_value.update.assert_called_once()
        db.client.table.return_value.insert.assert_not_called()


# ============================================================================
# POST /{workout_id}/warmup/apply-template
# ============================================================================


class TestApplyWarmupTemplate:
    @pytest.mark.asyncio
    async def test_403_when_not_owner(self):
        from api.v1.workouts.warmup_templates import apply_warmup_template

        db = MagicMock()
        db.get_workout.return_value = {"id": "w1", "user_id": "someone-else", "type": "strength"}
        with patch("api.v1.workouts.warmup_templates.get_supabase_db", return_value=db):
            with pytest.raises(HTTPException) as exc_info:
                await apply_warmup_template(
                    _http_request(), "w1", current_user={"id": "user-1"}
                )
        assert exc_info.value.status_code == 403

    @pytest.mark.asyncio
    async def test_404_when_no_template(self):
        from api.v1.workouts.warmup_templates import apply_warmup_template

        db, _ = _mock_db([None, None])
        db.get_workout.return_value = {"id": "w1", "user_id": "user-1", "type": "strength"}
        with patch("api.v1.workouts.warmup_templates.get_supabase_db", return_value=db):
            with pytest.raises(HTTPException) as exc_info:
                await apply_warmup_template(
                    _http_request(), "w1", current_user={"id": "user-1"}
                )
        assert exc_info.value.status_code == 404

    @pytest.mark.asyncio
    async def test_supersedes_existing_current_row_then_inserts(self):
        from api.v1.workouts.warmup_templates import apply_warmup_template

        template_row = {
            "workout_type": "strength",
            "exercises_json": [{"name": "Arm Circles", "duration_seconds": 30}],
        }
        db, _ = _mock_db([SimpleNamespace(data=template_row)])
        db.get_workout.return_value = {"id": "w1", "user_id": "user-1", "type": "strength"}
        # Existing is_current warmup row for this workout.
        db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = (
            SimpleNamespace(data=[{"id": "old-warmup-id", "version_number": 2}])
        )

        with patch("api.v1.workouts.warmup_templates.get_supabase_db", return_value=db):
            response = await apply_warmup_template(
                _http_request(), "w1", current_user={"id": "user-1"}
            )

        assert response["success"] is True
        assert response["exercises"] == template_row["exercises_json"]

        # The old row was superseded (is_current=False)...
        update_call = db.client.table.return_value.update.call_args
        assert update_call.args[0]["is_current"] is False
        # ...and a new row was inserted with the version bumped.
        insert_call = db.client.table.return_value.insert.call_args
        assert insert_call.args[0]["is_current"] is True
        assert insert_call.args[0]["version_number"] == 3
        assert insert_call.args[0]["workout_id"] == "w1"
