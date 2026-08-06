"""
Regression test for docs/qa/UI_E2E_2026-08-05.md row 4.

The Flutter client (exercise_alternatives_provider.dart) calls the bare
`GET /api/v1/exercises/{exercise_id}/alternatives` path, but the only handler
for "/{exercise_id}/alternatives" was registered on
`exercise_preferences_endpoints.router`, which is mounted under the
`/exercise-preferences` prefix — so the bare `/exercises` path 404'd for
every user on every swap-sheet open. Fixed by registering the SAME handler
object onto the `/exercises` router too (api/v1/exercises.py), so there is
exactly one implementation reachable at both paths.
"""
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from main import app
    from core.auth import get_current_user

    app.dependency_overrides[get_current_user] = lambda: {
        "id": "1aa02a24-0224-4a5a-b1e5-3f24dcd60bdc"
    }
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


def _mock_db_for_id_lookup(exercise_row):
    """Fake `get_supabase_db()` whose `exercise_library_cleaned` id lookup
    returns `exercise_row`, matching the chain
    `db.client.table(...).select(...).eq(...).limit(...).execute()`.
    """
    mock_db = MagicMock()
    execute_result = MagicMock()
    execute_result.data = [exercise_row] if exercise_row else []
    mock_db.client.table.return_value.select.return_value.eq.return_value.limit.return_value.execute.return_value = (
        execute_result
    )
    return mock_db


class TestExerciseAlternativesRouteAlias:
    def test_bare_exercises_path_is_routed_not_404(self, client):
        """GET /api/v1/exercises/{id}/alternatives must resolve to a handler
        (never 404) — this is the exact defect: the path had no route at all.
        """
        fake_row = {
            "id": "0312d89a-2824-4444-b0e6-3c5acdc8e571",
            "name": "180 Jump Turns",
            "equipment": "Bodyweight",
        }
        with patch(
            "api.v1.exercise_preferences_endpoints.get_supabase_db",
            return_value=_mock_db_for_id_lookup(fake_row),
        ), patch(
            "api.v1.exercise_preferences_endpoints._run_substitute_cascade",
            return_value=[],
        ):
            response = client.get(
                f"/api/v1/exercises/{fake_row['id']}/alternatives"
            )

        assert response.status_code == 200, response.text
        assert response.json() == {"alternatives": []}

    def test_bare_and_prefixed_paths_both_resolve(self, client):
        """Both paths must be live and both must resolve to the same handler
        function — a duplicated/forked implementation would be the wrong
        fix here.
        """
        from main import app

        alt_routes = [
            r for r in app.routes if getattr(r, "path", "").endswith("/alternatives")
        ]
        paths = {r.path for r in alt_routes}
        assert "/api/v1/exercises/{exercise_id}/alternatives" in paths
        assert (
            "/api/v1/exercise-preferences/exercises/{exercise_id}/alternatives"
            in paths
        )
        endpoints = {r.endpoint for r in alt_routes}
        assert len(endpoints) == 1, (
            "the two alternatives routes must share one implementation, "
            f"found {len(endpoints)} distinct endpoint functions"
        )

    def test_bare_path_unknown_id_fails_open_empty_not_500(self, client):
        """Unknown/unresolvable id must fail open to an empty list, per the
        handler's own contract — never fabricate alternatives, never 500.
        """
        with patch(
            "api.v1.exercise_preferences_endpoints.get_supabase_db",
            return_value=_mock_db_for_id_lookup(None),
        ):
            response = client.get(
                "/api/v1/exercises/00000000-0000-0000-0000-000000000000/alternatives"
            )

        assert response.status_code == 200
        assert response.json() == {"alternatives": []}
