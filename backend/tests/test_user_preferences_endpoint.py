"""
Tests for the cross-device user preferences endpoint added in SLICE_F:

    GET  /api/v1/users/me/preferences
    PATCH /api/v1/users/me/preferences

Backed by users.week_starts_sunday + users.distance_unit (migration 2094).

These tests use FastAPI dependency overrides + the AsyncClient/ASGITransport
fixture (TestClient has known httpx-version skew in this repo, per
project_testclient_httpx_skew note) to avoid hitting Supabase, and patch
get_supabase_db so we can assert the right SQL was issued without a live DB.
"""
from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from main import app
from core.auth import get_current_user

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

TEST_USER_ID = "00000000-0000-0000-0000-000000000aaa"


def _fake_user() -> dict:
    return {"id": TEST_USER_ID, "email": "tester@example.com"}


def _override_auth():
    """Yield a deterministic current_user for protected endpoints."""
    return _fake_user()


@pytest.fixture
def auth_override():
    """Install + tear down a get_current_user dependency override."""
    app.dependency_overrides[get_current_user] = _override_auth
    yield
    app.dependency_overrides.pop(get_current_user, None)


def _mock_db_select(week_starts_sunday, distance_unit) -> MagicMock:
    """Build a chained mock that behaves like the supabase-py builder for
    `client.table(...).select(...).eq(...).limit(...).execute()`."""
    db = MagicMock()
    chain = MagicMock()
    db.client.table.return_value = chain
    chain.select.return_value = chain
    chain.eq.return_value = chain
    chain.limit.return_value = chain
    chain.update.return_value = chain
    chain.execute.return_value = MagicMock(
        data=[
            {
                "week_starts_sunday": week_starts_sunday,
                "distance_unit": distance_unit,
            }
        ]
    )
    return db


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestGetMyPreferences:
    @pytest.mark.asyncio
    async def test_unauthenticated_returns_401(self, async_client):
        # No auth override installed → real get_current_user runs and
        # returns 401 (no Authorization header).
        res = await async_client.get("/api/v1/users/me/preferences")
        assert res.status_code in (401, 403)

    @pytest.mark.asyncio
    @patch("api.v1.users.profile.get_supabase_db")
    async def test_returns_persisted_values(
        self, mock_get_db, async_client, auth_override
    ):
        mock_get_db.return_value = _mock_db_select(
            week_starts_sunday=True, distance_unit="mi"
        )
        res = await async_client.get("/api/v1/users/me/preferences")
        assert res.status_code == 200, res.text
        body = res.json()
        assert body["week_starts_sunday"] is True
        assert body["distance_unit"] == "mi"

    @pytest.mark.asyncio
    @patch("api.v1.users.profile.get_supabase_db")
    async def test_returns_404_when_user_row_missing(
        self, mock_get_db, async_client, auth_override
    ):
        db = MagicMock()
        chain = MagicMock()
        db.client.table.return_value = chain
        chain.select.return_value = chain
        chain.eq.return_value = chain
        chain.limit.return_value = chain
        chain.execute.return_value = MagicMock(data=[])
        mock_get_db.return_value = db

        res = await async_client.get("/api/v1/users/me/preferences")
        assert res.status_code == 404


class TestPatchMyPreferences:
    @pytest.mark.asyncio
    async def test_unauthenticated_returns_401(self, async_client):
        res = await async_client.patch(
            "/api/v1/users/me/preferences",
            json={"week_starts_sunday": True},
        )
        assert res.status_code in (401, 403)

    @pytest.mark.asyncio
    @patch("api.v1.users.profile.get_supabase_db")
    async def test_null_only_payload_is_noop_and_returns_current(
        self, mock_get_db, async_client, auth_override
    ):
        db = _mock_db_select(week_starts_sunday=False, distance_unit="km")
        mock_get_db.return_value = db
        res = await async_client.patch(
            "/api/v1/users/me/preferences",
            json={"week_starts_sunday": None, "distance_unit": None},
        )
        assert res.status_code == 200, res.text
        body = res.json()
        # Update path NOT taken — only a read-back happened.
        db.client.table.return_value.update.assert_not_called()
        assert body["week_starts_sunday"] is False
        assert body["distance_unit"] == "km"

    @pytest.mark.asyncio
    @patch("api.v1.users.profile.get_supabase_db")
    async def test_valid_update_writes_then_reads(
        self, mock_get_db, async_client, auth_override
    ):
        # After the update we read back the new state.
        db = _mock_db_select(week_starts_sunday=True, distance_unit="mi")
        mock_get_db.return_value = db
        res = await async_client.patch(
            "/api/v1/users/me/preferences",
            json={"week_starts_sunday": True, "distance_unit": "mi"},
        )
        assert res.status_code == 200, res.text
        body = res.json()
        assert body["week_starts_sunday"] is True
        assert body["distance_unit"] == "mi"
        # Confirm update was issued with exactly the two fields.
        update_call = db.client.table.return_value.update.call_args
        assert update_call is not None
        payload = update_call.args[0]
        assert payload == {"week_starts_sunday": True, "distance_unit": "mi"}

    @pytest.mark.asyncio
    async def test_invalid_distance_unit_returns_422(
        self, async_client, auth_override
    ):
        # No DB mock needed — validation rejects before any DB call.
        res = await async_client.patch(
            "/api/v1/users/me/preferences",
            json={"distance_unit": "leagues"},
        )
        assert res.status_code == 422, res.text
