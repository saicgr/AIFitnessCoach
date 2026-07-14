"""
Tests for App Tour API endpoints.

These tests verify the app tour tracking functionality including:
1. Starting tours for new and existing users
2. Tracking step completions
3. Completing and skipping tours
4. Tour status checks
5. Analytics endpoints

This supports the onboarding flow that guides users through the app features.

────────────────────────────────────────────────────────────────────────────
WHY THIS FILE CHANGED (calls only — no assertion was weakened or removed)
────────────────────────────────────────────────────────────────────────────
Every test here used to call an API that does not exist and never has:
`/api/v1/app-tour/{start,status,analytics,claim}` plus `/{id}/step`,
`/{id}/complete`, `/{id}/skip`. So every request 404'd. The endpoint-existence
assertions failed outright, and the rest of the suite passed VACUOUSLY — their
bodies are guarded by `if start_response.status_code in [200, 201]:`, which was
never true, so the tour flow was never exercised at all.

The tour API actually lives in `api/v1/demo_endpoints.py`, mounted under the
demo router (`api/v1/demo.py`, prefix `/demo`):

    POST /api/v1/demo/tour/start          {user_id?, device_id?, source,
                                           device_info?, app_version?, platform?}
                                       →  {session_id, should_show_tour, tour_config}
    POST /api/v1/demo/tour/step-completed {session_id, step_id, duration_seconds?,
                                           action_taken?, deep_link_target?}
                                       →  {status: "logged", step_id,
                                           total_steps_completed}
    POST /api/v1/demo/tour/completed      {session_id, status: completed|skipped,
                                           skip_step?, ...}
                                       →  {status, total_duration_seconds,
                                           steps_completed}
    GET  /api/v1/demo/tour/status/{identifier}?identifier_type=user_id|device_id
    GET  /api/v1/demo/tour/analytics      (admin only)

The tests below now call THAT API with THAT payload shape. What each test
asserts is unchanged, except where the real response is richer than the
speculative one the tests were written against — there the assertion was made
STRONGER (e.g. steps_completed is asserted to be an exact count instead of an
`if key in body` no-op). Three tests that assert input validation the API does
not perform are left FAILING on purpose — see TestTourEdgeCases.

The DB is stubbed with an in-memory fake that mirrors the two CHECK constraints
`app_tour_sessions` really carries in production (verified against
information_schema): `source IN (new_user, settings, deep_link, app_update,
feature_intro)` and `skip_reason IS NULL OR IN (already_familiar, too_long,
not_interested, accidental, will_do_later, other)`. That keeps the tests
hermetic (no writes to the production tour table) without pretending the API
rejects things production would accept.
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from httpx import AsyncClient
from datetime import datetime, timezone
import uuid
import json

from core.auth import get_admin_user
from core.rate_limiter import limiter
from main import app


# ============ Fake Supabase ============

# Live CHECK constraints on public.app_tour_sessions (information_schema, 2026-07):
#   app_tour_sessions_source_check
#   app_tour_sessions_skip_reason_check
_VALID_SOURCES = {"new_user", "settings", "deep_link", "app_update", "feature_intro"}
_VALID_SKIP_REASONS = {
    "already_familiar", "too_long", "not_interested",
    "accidental", "will_do_later", "other",
}


class _CheckViolation(Exception):
    """Stand-in for the PostgREST 23514 a CHECK constraint raises."""


class _InvalidTextRepresentation(Exception):
    """Stand-in for the Postgres 22P02 a bad value for a typed column raises."""


def _enforce_column_rules(table: str, row: dict) -> dict:
    """Apply the real column constraints/types of app_tour_sessions to `row`.

    Returns the (possibly coerced) row, exactly as Postgres would store it.
    """
    if table != "app_tour_sessions":
        return dict(row)

    row = dict(row)
    if "source" in row and row["source"] not in _VALID_SOURCES:
        raise _CheckViolation(
            f'new row for relation "app_tour_sessions" violates check constraint '
            f'"app_tour_sessions_source_check" (source={row["source"]!r})'
        )
    skip_reason = row.get("skip_reason")
    if skip_reason is not None and skip_reason not in _VALID_SKIP_REASONS:
        raise _CheckViolation(
            f'new row for relation "app_tour_sessions" violates check constraint '
            f'"app_tour_sessions_skip_reason_check" (skip_reason={skip_reason!r})'
        )
    # skip_step is an INTEGER column (migration 2306) even though the request
    # model types it as a str — Postgres coerces a numeric string and rejects
    # anything else with 22P02. See BUG note on test_skip_tour_success.
    if row.get("skip_step") is not None:
        try:
            row["skip_step"] = int(row["skip_step"])
        except (TypeError, ValueError):
            raise _InvalidTextRepresentation(
                f'invalid input syntax for type integer: "{row["skip_step"]}"'
            )
    return row


class _FakeResult:
    def __init__(self, data):
        self.data = data


class _FakeQuery:
    """Minimal supabase-py query builder over an in-memory row store."""

    def __init__(self, store: dict, table: str):
        self._store = store
        self._table = table
        self._op = None
        self._payload = None
        self._eq = []
        self._gte = []
        self._order = None

    # -- builders --
    def select(self, *_cols, **_kw):
        self._op = "select"
        return self

    def insert(self, payload):
        self._op = "insert"
        self._payload = payload
        return self

    def update(self, payload):
        self._op = "update"
        self._payload = payload
        return self

    def eq(self, col, val):
        self._eq.append((col, val))
        return self

    def gte(self, col, val):
        self._gte.append((col, val))
        return self

    def order(self, col, desc=False):
        self._order = (col, desc)
        return self

    # -- terminal --
    def _matches(self, row) -> bool:
        for col, val in self._eq:
            if row.get(col) != val:
                return False
        for col, val in self._gte:
            if str(row.get(col) or "") < str(val):
                return False
        return True

    def execute(self):
        rows = self._store.setdefault(self._table, [])

        if self._op == "insert":
            payload = self._payload if isinstance(self._payload, list) else [self._payload]
            inserted = []
            for row in payload:
                stored = _enforce_column_rules(self._table, row)
                stored.setdefault("id", str(uuid.uuid4()))
                rows.append(stored)
                inserted.append(stored)
            return _FakeResult(inserted)

        if self._op == "update":
            updated = []
            for row in rows:
                if self._matches(row):
                    merged = _enforce_column_rules(self._table, {**row, **self._payload})
                    row.clear()
                    row.update(merged)
                    updated.append(row)
            return _FakeResult(updated)

        matched = [dict(r) for r in rows if self._matches(r)]
        if self._order:
            col, desc = self._order
            matched.sort(key=lambda r: str(r.get(col) or ""), reverse=desc)
        return _FakeResult(matched)


class _FakeClient:
    def __init__(self):
        self.store: dict = {}

    def table(self, name):
        return _FakeQuery(self.store, name)

    def from_(self, name):
        # The tour analytics endpoint optimistically reads a `tour_analytics`
        # view; that view does not exist in production (the real one is named
        # app_tour_analytics), so the call raises and the endpoint falls back to
        # computing analytics from app_tour_sessions. Mirror that here so the
        # tests exercise the code path production actually takes.
        raise RuntimeError(f'relation "public.{name}" does not exist')


class _FakeDB:
    def __init__(self):
        self.client = _FakeClient()


# ============ Fixtures ============

@pytest.fixture(autouse=True)
def fake_db():
    """In-memory app_tour_sessions store — no writes to the production table."""
    db = _FakeDB()
    with patch("api.v1.demo_endpoints.get_supabase_db", return_value=db):
        yield db


@pytest.fixture(autouse=True)
def no_rate_limit():
    """Disable slowapi for this module.

    /tour/start and /tour/completed are capped at 5/hour per IP. A test suite
    runs dozens of tour starts from one client IP, so without this the 6th test
    would get a 429 that has nothing to do with tour behavior. Rate limiting is
    covered by its own tests; restored on teardown so no other module is
    affected.
    """
    was_enabled = limiter.enabled
    limiter.enabled = False
    try:
        yield
    finally:
        limiter.enabled = was_enabled


@pytest.fixture(autouse=True)
def admin_auth():
    """Satisfy the admin dependency on GET /tour/analytics (SECURITY: admin-only)."""
    app.dependency_overrides[get_admin_user] = lambda: {
        "id": "admin-user", "email": "admin@example.com", "role": "admin",
    }
    try:
        yield
    finally:
        app.dependency_overrides.pop(get_admin_user, None)


@pytest.fixture
def test_user_id():
    """Generate a test user UUID."""
    return str(uuid.uuid4())


@pytest.fixture
def test_device_id():
    """Generate a test device/session UUID."""
    return str(uuid.uuid4())


@pytest.fixture
def tour_session_data(test_user_id, test_device_id):
    """Sample tour session data."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": test_user_id,
        "session_id": test_device_id,
        "source": "new_user",
        "device_info": {
            "platform": "ios",
            "os_version": "17.0",
            "app_version": "1.5.0",
            "device_model": "iPhone 15 Pro",
            "screen_width": 390,
            "screen_height": 844,
            "locale": "en_US"
        },
        "steps_completed": [],
        "current_step": None,
        "tour_version": "1.0",
        "started_at": datetime.now(timezone.utc).isoformat(),
        "completed_at": None,
        "skipped_at": None,
        "skip_reason": None,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    }


@pytest.fixture
def tour_step_event_data(tour_session_data):
    """Sample tour step event data."""
    return {
        "id": str(uuid.uuid4()),
        "tour_session_id": tour_session_data["id"],
        "step_id": "welcome",
        "step_index": 0,
        "action": "viewed",
        "duration_seconds": 5,
        "interaction_data": {"button_clicks": ["next"]},
        "created_at": datetime.now(timezone.utc).isoformat()
    }


@pytest.fixture
def tour_config():
    """Sample tour configuration returned by start endpoint."""
    return {
        "version": "1.0",
        "steps": [
            {"id": "welcome", "title": "Welcome to Zealova", "index": 0},
            {"id": "ai_workouts", "title": "AI-Generated Workouts", "index": 1},
            {"id": "chat_coach", "title": "Your AI Coach", "index": 2},
            {"id": "library", "title": "Exercise Library", "index": 3},
            {"id": "progress", "title": "Track Your Progress", "index": 4},
            {"id": "nutrition", "title": "Nutrition Tracking", "index": 5},
            {"id": "complete", "title": "You're All Set!", "index": 6}
        ],
        "total_steps": 7
    }


@pytest.fixture
def mock_supabase():
    """Mock Supabase client for database operations."""
    mock = MagicMock()
    mock.table = MagicMock(return_value=mock)
    mock.select = MagicMock(return_value=mock)
    mock.insert = MagicMock(return_value=mock)
    mock.update = MagicMock(return_value=mock)
    mock.eq = MagicMock(return_value=mock)
    mock.is_ = MagicMock(return_value=mock)
    mock.single = MagicMock(return_value=mock)
    mock.execute = MagicMock(return_value=MagicMock(data=None))
    mock.rpc = MagicMock(return_value=mock)
    return mock


# ============ Tour Start Tests ============

class TestTourStart:
    """Tests for starting app tours."""

    @pytest.mark.asyncio
    async def test_start_tour_new_user(self, async_client: AsyncClient, test_device_id):
        """Test starting a tour for a new anonymous user (no user_id)."""
        response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user",
                "device_info": {
                    "platform": "ios",
                    "app_version": "1.5.0"
                }
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()

        assert "tour_session_id" in data or "session_id" in data
        assert "config" in data or "tour_config" in data or "steps" in data

    @pytest.mark.asyncio
    async def test_start_tour_existing_user(self, async_client: AsyncClient, test_user_id, test_device_id):
        """Test starting a tour for an authenticated user."""
        response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "user_id": test_user_id,
                "device_id": test_device_id,
                "source": "new_user",
                "device_info": {
                    "platform": "android",
                    "app_version": "1.5.0"
                }
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()

        # Should have session info
        assert "tour_session_id" in data or "session_id" in data or "id" in data

    @pytest.mark.asyncio
    async def test_start_tour_from_settings(self, async_client: AsyncClient, fake_db, test_user_id, test_device_id):
        """Test starting a tour with source='settings'."""
        response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "user_id": test_user_id,
                "device_id": test_device_id,
                "source": "settings",
                "device_info": {
                    "platform": "ios"
                }
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()

        # Verify source is recorded if returned
        if "source" in data:
            assert data["source"] == "settings"

        # The response body doesn't echo the source, so assert it on the row the
        # endpoint persisted — that is what the analytics views read.
        rows = fake_db.client.store["app_tour_sessions"]
        assert [r["source"] for r in rows] == ["settings"]

    @pytest.mark.asyncio
    async def test_start_tour_returns_config(self, async_client: AsyncClient, test_device_id):
        """Test that starting a tour returns the tour configuration."""
        response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()

        # Should return tour config with steps
        config = data.get("config") or data.get("tour_config") or data
        assert "steps" in config
        assert len(config["steps"]) > 0
        # Each step should have id and title/name
        for step in config["steps"]:
            assert "id" in step or "step_id" in step

    @pytest.mark.asyncio
    async def test_start_tour_skip_for_completed_user(self, async_client: AsyncClient, test_user_id, test_device_id):
        """Test that tour is skipped if user already completed it."""
        # First start and complete a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "user_id": test_user_id,
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete the tour
        complete = await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": tour_session_id, "status": "completed"},
        )
        assert complete.status_code == 200

        # Try to start another tour
        second_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "user_id": test_user_id,
                "device_id": str(uuid.uuid4()),
                "source": "new_user"
            }
        )

        # Should indicate tour already completed → should_show_tour False
        assert second_response.status_code == 200
        assert second_response.json()["should_show_tour"] is False

    @pytest.mark.asyncio
    async def test_start_tour_from_settings_shows_even_after_completion(
        self, async_client: AsyncClient, test_user_id, test_device_id
    ):
        """A user who already finished the tour can still replay it from settings.

        (The 'already completed' suppression is scoped to source='new_user'.)
        """
        start = await async_client.post(
            "/api/v1/demo/tour/start",
            json={"user_id": test_user_id, "device_id": test_device_id, "source": "new_user"},
        )
        await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": start.json()["session_id"], "status": "completed"},
        )

        replay = await async_client.post(
            "/api/v1/demo/tour/start",
            json={"user_id": test_user_id, "device_id": test_device_id, "source": "settings"},
        )

        assert replay.status_code == 200
        assert replay.json()["should_show_tour"] is True


# ============ Tour Step Tests ============

class TestTourSteps:
    """Tests for tour step tracking."""

    @pytest.mark.asyncio
    async def test_complete_step_success(self, async_client: AsyncClient, test_device_id):
        """Test logging a step completion."""
        # Start a tour first
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete a step
        response = await async_client.post(
            "/api/v1/demo/tour/step-completed",
            json={
                "session_id": tour_session_id,
                "step_id": "welcome",
                "action_taken": "next",
                "duration_seconds": 5
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data.get("status") in ["recorded", "success", "logged", None] or "id" in data

    @pytest.mark.asyncio
    async def test_complete_step_with_deep_link(self, async_client: AsyncClient, fake_db, test_device_id):
        """Test logging a step with deep link action."""
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        response = await async_client.post(
            "/api/v1/demo/tour/step-completed",
            json={
                "session_id": tour_session_id,
                "step_id": "exercise_library",
                "action_taken": "deep_link",
                "deep_link_target": "/library",
                "duration_seconds": 15,
            }
        )

        assert response.status_code in [200, 201]

        # The deep link must be recorded for the conversion funnel.
        session = fake_db.client.store["app_tour_sessions"][0]
        assert [dl["target"] for dl in session["deep_links_clicked"]] == ["/library"]

    @pytest.mark.asyncio
    async def test_complete_step_invalid_session(self, async_client: AsyncClient):
        """Test 404 for invalid session when completing step."""
        invalid_session_id = str(uuid.uuid4())

        response = await async_client.post(
            "/api/v1/demo/tour/step-completed",
            json={
                "session_id": invalid_session_id,
                "step_id": "welcome",
                "action_taken": "next"
            }
        )

        # Should return 404 or 400 for invalid session
        assert response.status_code in [404, 400, 500]

    @pytest.mark.asyncio
    async def test_complete_step_adds_to_array(self, async_client: AsyncClient, test_device_id):
        """Test that steps get added to steps_completed array."""
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete multiple steps
        steps = ["welcome", "ai_workouts", "chat_coach"]
        for idx, step_id in enumerate(steps):
            step_response = await async_client.post(
                "/api/v1/demo/tour/step-completed",
                json={
                    "session_id": tour_session_id,
                    "step_id": step_id,
                    "action_taken": "next",
                    "duration_seconds": 5
                }
            )
            assert step_response.status_code == 200
            assert step_response.json()["total_steps_completed"] == idx + 1

        # Get tour status to verify steps_completed
        status_response = await async_client.get(
            f"/api/v1/demo/tour/status/{test_device_id}",
            params={"identifier_type": "device_id"}
        )

        assert status_response.status_code == 200
        status_data = status_response.json()
        # The status endpoint reports the COUNT of completed steps.
        assert status_data["latest_session"]["steps_completed"] == len(steps)


# ============ Tour Completion Tests ============

class TestTourCompletion:
    """Tests for tour completion and skipping."""

    @pytest.mark.asyncio
    async def test_complete_tour_success(self, async_client: AsyncClient, test_device_id):
        """Test marking a tour as completed."""
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete the tour
        response = await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": tour_session_id, "status": "completed"},
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data.get("status") in ["completed", "success", None] or "completed_at" in data

    @pytest.mark.asyncio
    async def test_skip_tour_success(self, async_client: AsyncClient, fake_db, test_device_id):
        """Test marking a tour as skipped with skip_step.

        The API models the skip point as `skip_step`, not a free-text reason.

        BUG (reported, not worked around): TourCompletedRequest types skip_step
        as Optional[str] while app_tour_sessions.skip_step is an INTEGER column
        (migration 2306). So a real int is rejected by Pydantic with 422, and a
        step-id string ("ai_workouts") is rejected by Postgres with 22P02 → 500.
        The ONLY value the current stack can store end-to-end is a numeric
        STRING, which is what this test sends — it pins the contract as it
        actually is today, and the fake DB coerces it exactly like the INT column
        does. Whoever owns the schema should decide which side is wrong.
        """
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        response = await async_client.post(
            "/api/v1/demo/tour/completed",
            json={
                "session_id": tour_session_id,
                "status": "skipped",
                "skip_step": "2",
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        assert data.get("status") in ["skipped", "success", None] or "skipped_at" in data

        session = fake_db.client.store["app_tour_sessions"][0]
        assert session["status"] == "skipped"
        assert session["skip_step"] == 2

    @pytest.mark.asyncio
    async def test_complete_tour_logs_context(self, async_client: AsyncClient, fake_db, test_user_id, test_device_id):
        """Test that completing a tour logs to user_context_logs."""
        # Start tour with user_id
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "user_id": test_user_id,
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete the tour
        response = await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": tour_session_id, "status": "completed"},
        )

        # Tour completion should log to context
        assert response.status_code in [200, 201]

        events = [
            row["event_type"]
            for row in fake_db.client.store.get("user_context_logs", [])
            if row["user_id"] == test_user_id
        ]
        assert "app_tour_started" in events
        assert "app_tour_completed" in events

    @pytest.mark.asyncio
    async def test_complete_tour_updates_ui_state(self, async_client: AsyncClient, fake_db, test_user_id, test_device_id):
        """Test that completing a tour updates ui_onboarding_state."""
        # The endpoint only patches ui_onboarding_state for an EXISTING user row.
        fake_db.client.store["users"] = [{"id": test_user_id, "ui_onboarding_state": {}}]

        # Start tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "user_id": test_user_id,
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete the tour
        await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": tour_session_id, "status": "completed"},
        )

        ui_state = fake_db.client.store["users"][0]["ui_onboarding_state"]
        assert ui_state["app_tour_completed"] is True
        assert ui_state["app_tour_skipped"] is False

        # Check tour status
        status_response = await async_client.get(
            f"/api/v1/demo/tour/status/{test_user_id}",
            params={"identifier_type": "user_id"}
        )

        assert status_response.status_code == 200
        status_data = status_response.json()
        # should_show_tour should be False after completion
        assert status_data["should_show_tour"] is False


# ============ Tour Status Tests ============

class TestTourStatus:
    """Tests for tour status retrieval."""

    @pytest.mark.asyncio
    async def test_get_tour_status_by_user_id(self, async_client: AsyncClient, test_user_id, test_device_id):
        """Test getting tour status for a user."""
        # Start a tour first
        await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "user_id": test_user_id,
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        # Get status
        response = await async_client.get(
            f"/api/v1/demo/tour/status/{test_user_id}",
            params={"identifier_type": "user_id"}
        )

        assert response.status_code == 200
        data = response.json()

        # Should have status info
        assert "should_show_tour" in data or "has_completed_tour" in data or "status" in data
        assert data["total_tour_sessions"] == 1

    @pytest.mark.asyncio
    async def test_get_tour_status_by_device_id(self, async_client: AsyncClient, test_device_id):
        """Test getting tour status for a device."""
        # Start a tour
        await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        # Get status by device/session id
        response = await async_client.get(
            f"/api/v1/demo/tour/status/{test_device_id}",
            params={"identifier_type": "device_id"}
        )

        assert response.status_code == 200
        assert response.json()["total_tour_sessions"] == 1

    @pytest.mark.asyncio
    async def test_tour_status_rejects_unknown_identifier_type(self, async_client: AsyncClient, test_user_id):
        """identifier_type is restricted to the two indexed columns."""
        response = await async_client.get(
            f"/api/v1/demo/tour/status/{test_user_id}",
            params={"identifier_type": "email"}
        )

        assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_tour_status_shows_completion(self, async_client: AsyncClient, test_user_id, test_device_id):
        """Test that should_show_tour is False after completion."""
        # Start tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "user_id": test_user_id,
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete the tour
        await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": tour_session_id, "status": "completed"},
        )

        # Get status
        response = await async_client.get(
            f"/api/v1/demo/tour/status/{test_user_id}",
            params={"identifier_type": "user_id"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["should_show_tour"] is False
        assert data["has_completed_tour"] is True

    @pytest.mark.asyncio
    async def test_tour_status_new_user(self, async_client: AsyncClient):
        """Test that should_show_tour is True for new users."""
        new_user_id = str(uuid.uuid4())

        response = await async_client.get(
            f"/api/v1/demo/tour/status/{new_user_id}",
            params={"identifier_type": "user_id"}
        )

        assert response.status_code == 200
        data = response.json()
        # New user should see the tour
        assert data["should_show_tour"] is True
        assert data["latest_session"] is None


# ============ Tour Analytics Tests ============

class TestTourAnalytics:
    """Tests for tour analytics endpoints."""

    @pytest.mark.asyncio
    async def test_get_tour_analytics(self, async_client: AsyncClient, test_device_id):
        """Test getting aggregated tour analytics."""
        await async_client.post(
            "/api/v1/demo/tour/start",
            json={"device_id": test_device_id, "source": "new_user", "platform": "ios"},
        )

        response = await async_client.get("/api/v1/demo/tour/analytics")

        # Analytics endpoint should exist
        assert response.status_code in [200, 403, 401]  # May require auth

        if response.status_code == 200:
            data = response.json()
            # Should have analytics data
            assert "total_starts" in data or "analytics" in data or "data" in data or isinstance(data, list)
            assert data["analytics"]["total_sessions"] == 1

    @pytest.mark.asyncio
    async def test_tour_analytics_filter_by_source(self, async_client: AsyncClient, test_device_id):
        """Test filtering analytics by source parameter."""
        await async_client.post(
            "/api/v1/demo/tour/start",
            json={"device_id": test_device_id, "source": "new_user"},
        )
        await async_client.post(
            "/api/v1/demo/tour/start",
            json={"device_id": str(uuid.uuid4()), "source": "settings"},
        )

        response = await async_client.get(
            "/api/v1/demo/tour/analytics",
            params={"source": "new_user"}
        )

        assert response.status_code in [200, 403, 401]

        if response.status_code == 200:
            data = response.json()
            # Results should be filtered by source if supported
            assert data["source_filter"] == "new_user"
            assert data["analytics"]["total_sessions"] == 1

    @pytest.mark.asyncio
    async def test_tour_analytics_filter_by_platform(self, async_client: AsyncClient, test_device_id):
        """Test filtering analytics by platform parameter."""
        await async_client.post(
            "/api/v1/demo/tour/start",
            json={"device_id": test_device_id, "source": "new_user", "platform": "ios"},
        )
        await async_client.post(
            "/api/v1/demo/tour/start",
            json={"device_id": str(uuid.uuid4()), "source": "new_user", "platform": "android"},
        )

        response = await async_client.get(
            "/api/v1/demo/tour/analytics",
            params={"platform": "ios"}
        )

        assert response.status_code in [200, 403, 401]

        if response.status_code == 200:
            data = response.json()
            # Results should be filtered by platform if supported
            assert data["platform_filter"] == "ios"
            assert data["analytics"]["total_sessions"] == 1

    @pytest.mark.asyncio
    async def test_tour_analytics_requires_admin(self, async_client: AsyncClient):
        """The analytics endpoint is admin-only (it aggregates every user's tour)."""
        app.dependency_overrides.pop(get_admin_user, None)  # restore real dependency
        try:
            response = await async_client.get("/api/v1/demo/tour/analytics")
        finally:
            app.dependency_overrides[get_admin_user] = lambda: {"id": "admin-user"}

        assert response.status_code in [401, 403]


# ============ Edge Cases and Error Handling ============

class TestTourEdgeCases:
    """Tests for edge cases and error handling."""

    @pytest.mark.asyncio
    async def test_start_tour_invalid_source(self, async_client: AsyncClient, test_device_id):
        """Test starting a tour with invalid source value.

        Enforced by the app_tour_sessions_source_check CHECK constraint (the API
        model types `source` as a bare str), so the insert raises and the
        endpoint returns a 500 rather than persisting an unknown source.
        """
        response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "invalid_source"
            }
        )

        # Should reject invalid source
        assert response.status_code in [400, 422, 500]

    @pytest.mark.asyncio
    async def test_complete_step_invalid_step_id(self, async_client: AsyncClient, test_device_id):
        """Test completing a step with invalid step_id.

        *** KNOWN FAILURE — OPEN QUESTION, NOT A TEST BUG. ***
        POST /demo/tour/step-completed accepts ANY step_id string and appends it
        to app_tour_sessions.steps_completed, so this returns 200 and the junk
        step id lands in the analytics aggregation
        (get_tour_analytics buckets step_completion_rates BY step_id).

        There is no authoritative step vocabulary to validate against today:
          * DEFAULT_TOUR_CONFIG (api/v1/demo.py) uses welcome / workout_preview /
            exercise_library / progress_tracking / ai_coach ...
          * the app_tour_step_events CHECK (migration 102) uses welcome /
            ai_workouts / chat_coach / library / progress / nutrition / complete
          * no backend code writes app_tour_step_events at all, and no Flutter
            code calls these endpoints yet.
        Picking one of those lists and enforcing it is a product decision, not a
        mechanical fix, so the test is left failing rather than silently
        rewritten to bless the current behavior.
        """
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        response = await async_client.post(
            "/api/v1/demo/tour/step-completed",
            json={
                "session_id": tour_session_id,
                "step_id": "invalid_step",
                "action_taken": "next"
            }
        )

        # Should reject invalid step_id
        assert response.status_code in [400, 422, 500]

    @pytest.mark.asyncio
    async def test_complete_step_invalid_action(self, async_client: AsyncClient, test_device_id):
        """Test completing a step with invalid action value.

        *** KNOWN FAILURE — OPEN QUESTION, NOT A TEST BUG. ***
        Same shape as test_complete_step_invalid_step_id: `action_taken` is an
        unvalidated str on TourStepCompletedRequest. Its docstring enumerates
        skip / next / deep_link, while the app_tour_step_events.action CHECK
        enumerates viewed / interacted / skipped / deep_linked / back_navigated /
        replayed / help_clicked — two different vocabularies, neither enforced.
        Any string is accepted and stored.
        """
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        response = await async_client.post(
            "/api/v1/demo/tour/step-completed",
            json={
                "session_id": tour_session_id,
                "step_id": "welcome",
                "action_taken": "invalid_action"
            }
        )

        # Should reject invalid action
        assert response.status_code in [400, 422, 500]

    @pytest.mark.asyncio
    async def test_skip_tour_invalid_reason(self, async_client: AsyncClient, test_device_id):
        """Test skipping a tour with invalid skip_reason.

        *** KNOWN FAILURE — OPEN QUESTION, NOT A TEST BUG. ***
        app_tour_sessions.skip_reason exists, carries a CHECK constraint
        (already_familiar / too_long / not_interested / accidental /
        will_do_later / other) and is the sole input of the app_tour_skip_analysis
        view — but TourCompletedRequest has NO skip_reason field, so the API
        cannot accept one, silently drops it, and the column is never populated
        (the skip-analysis view can only ever be empty).

        Either the field should be added to TourCompletedRequest and forwarded
        (then the DB CHECK rejects a bad value exactly like `source`), or
        skip_reason + its view are dead schema and should be dropped. That is a
        product call, so the test is left failing rather than deleted.
        """
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        response = await async_client.post(
            "/api/v1/demo/tour/completed",
            json={
                "session_id": tour_session_id,
                "status": "skipped",
                "skip_reason": "invalid_reason"
            }
        )

        # Should reject invalid skip_reason
        assert response.status_code in [400, 422, 500]

    @pytest.mark.asyncio
    async def test_complete_already_completed_tour(self, async_client: AsyncClient, test_device_id):
        """Test that completing an already completed tour is handled gracefully."""
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete the tour
        await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": tour_session_id, "status": "completed"},
        )

        # Try to complete again
        response = await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": tour_session_id, "status": "completed"},
        )

        # Should handle gracefully (200 OK or appropriate error)
        assert response.status_code in [200, 400, 409]

    @pytest.mark.asyncio
    async def test_skip_already_completed_tour(self, async_client: AsyncClient, test_device_id):
        """Test that skipping an already completed tour is handled gracefully."""
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete the tour
        await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": tour_session_id, "status": "completed"},
        )

        # Try to skip
        response = await async_client.post(
            "/api/v1/demo/tour/completed",
            json={"session_id": tour_session_id, "status": "skipped"},
        )

        # Should handle gracefully
        assert response.status_code in [200, 400, 409]


# ============ Tour Session Claiming Tests ============

class TestTourSessionClaiming:
    """Tests for claiming anonymous tour sessions after signup.

    There is no tour-claim endpoint: an anonymous tour is keyed by device_id and
    a post-signup tour simply carries the user_id. These tests assert the API
    surface's shape (a claim call is a 404), which is what they always asserted —
    the difference is that they now say so against the real base path instead of
    404-ing on a base path that never existed.
    """

    @pytest.mark.asyncio
    async def test_claim_anonymous_session(self, async_client: AsyncClient, test_device_id, test_user_id):
        """Test claiming an anonymous tour session after user signs up."""
        # Start an anonymous tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]

        # Claim the session for the user
        claim_response = await async_client.post(
            "/api/v1/demo/tour/claim",
            json={
                "device_id": test_device_id,
                "user_id": test_user_id
            }
        )

        # Claiming should work or endpoint might not exist
        assert claim_response.status_code in [200, 201, 404]

    @pytest.mark.asyncio
    async def test_claim_already_claimed_session(self, async_client: AsyncClient, test_device_id):
        """Test that claiming an already claimed session is handled."""
        user_id_1 = str(uuid.uuid4())
        user_id_2 = str(uuid.uuid4())

        # Start a tour with user_id_1
        await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "user_id": user_id_1,
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        # Try to claim for user_id_2
        claim_response = await async_client.post(
            "/api/v1/demo/tour/claim",
            json={
                "device_id": test_device_id,
                "user_id": user_id_2
            }
        )

        # Should fail or be a no-op
        assert claim_response.status_code in [200, 400, 404, 409]


# ============ Tour Version Tests ============

class TestTourVersioning:
    """Tests for tour versioning and A/B testing support."""

    @pytest.mark.asyncio
    async def test_start_tour_with_version(self, async_client: AsyncClient, test_device_id):
        """Test starting a tour with a specific version."""
        response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user",
                "tour_version": "2.0"
            }
        )

        assert response.status_code in [200, 201]
        data = response.json()
        if "tour_version" in data:
            assert data["tour_version"] == "2.0"

    @pytest.mark.asyncio
    async def test_analytics_by_version(self, async_client: AsyncClient):
        """Test getting analytics filtered by tour version."""
        response = await async_client.get(
            "/api/v1/demo/tour/analytics",
            params={"tour_version": "1.0"}
        )

        assert response.status_code in [200, 403, 401]


# ============ Tour Step Metrics Tests ============

class TestTourStepMetrics:
    """Tests for step-level metrics and analytics."""

    @pytest.mark.asyncio
    async def test_step_duration_tracking(self, async_client: AsyncClient, fake_db, test_device_id):
        """Test that step duration is properly tracked."""
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete a step with duration
        response = await async_client.post(
            "/api/v1/demo/tour/step-completed",
            json={
                "session_id": tour_session_id,
                "step_id": "welcome",
                "action_taken": "next",
                "duration_seconds": 30
            }
        )

        assert response.status_code in [200, 201]

        step = fake_db.client.store["app_tour_sessions"][0]["steps_completed"][0]
        assert step["duration_seconds"] == 30

    @pytest.mark.asyncio
    async def test_step_interaction_data(self, async_client: AsyncClient, fake_db, test_device_id):
        """Test that interaction data is properly recorded.

        The API records the action taken on a step plus its duration; the
        speculative `interaction_data` blob (scroll depth, video percent, …) is
        not part of the request model, so what is asserted is the interaction
        data the endpoint DOES persist.
        """
        # Start a tour
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={
                "device_id": test_device_id,
                "source": "new_user"
            }
        )

        assert start_response.status_code in [200, 201]
        tour_session_id = start_response.json()["session_id"]

        # Complete a step with rich interaction data
        response = await async_client.post(
            "/api/v1/demo/tour/step-completed",
            json={
                "session_id": tour_session_id,
                "step_id": "workout_preview",
                "action_taken": "deep_link",
                "deep_link_target": "/workout/today",
                "duration_seconds": 45,
            }
        )

        assert response.status_code in [200, 201]

        session = fake_db.client.store["app_tour_sessions"][0]
        step = session["steps_completed"][0]
        assert step["step_id"] == "workout_preview"
        assert step["action_taken"] == "deep_link"
        assert step["duration_seconds"] == 45
        assert session["deep_links_clicked"][0]["target"] == "/workout/today"

    @pytest.mark.asyncio
    async def test_get_step_analytics(self, async_client: AsyncClient, test_device_id):
        """Test getting step-level analytics.

        There is no dedicated /analytics/steps route — step-level numbers are
        returned inside the main analytics payload as `step_completion_rates`,
        so that is where the assertion now looks.
        """
        start_response = await async_client.post(
            "/api/v1/demo/tour/start",
            json={"device_id": test_device_id, "source": "new_user"},
        )
        session_id = start_response.json()["session_id"]
        await async_client.post(
            "/api/v1/demo/tour/step-completed",
            json={"session_id": session_id, "step_id": "welcome", "action_taken": "next"},
        )

        response = await async_client.get("/api/v1/demo/tour/analytics")

        assert response.status_code in [200, 403, 401, 404]

        if response.status_code == 200:
            data = response.json()
            # Should return step-level data
            assert isinstance(data, (dict, list))
            assert data["analytics"]["step_completion_rates"] == {"welcome": 100.0}
