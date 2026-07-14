"""
Tests for Demo and Trial API endpoints.

These tests verify the demo preview and trial functionality
that allows users to experience the app before signing up.

This addresses the complaint:
"One of those apps where you answer a bunch of questions to get a 'tailored plan',
but then hit a paywall to even see how the app works"

Three things were wrong in HOW these tests called the app (never in what they
assert):

1. Every test is `async def` and `await client.post(...)`, but the `client`
   fixture they picked up from conftest is a *synchronous* `TestClient` — so
   every test died with "object Response can't be used in 'await' expression".
   The type annotation on each test (`client: AsyncClient`) says what was
   intended; this module now provides that async fixture.

2. The demo endpoints write to Supabase (`demo_sessions`, `demo_interactions`).
   Un-mocked, they would hit the real project (the app's Settings loads .env) and
   scribble test rows into production analytics. They now run against an
   in-memory PostgREST fake, so session resume / conversion-duration / interaction
   logging are all exercised for real, just not over the wire.

3. slowapi rate limits (3/hour on the preview plan) are process-global, so the
   4th preview-plan call in the module used to 429. The limiter is reset between
   tests instead of being disabled, so a within-test burst is still limited.
"""

import pytest
from httpx import AsyncClient, ASGITransport
from datetime import datetime, timezone
from unittest.mock import patch, MagicMock
import uuid


# ============================================================================
# In-memory Supabase (PostgREST) fake
# ============================================================================

def _values_equal(actual, expected) -> bool:
    if isinstance(expected, bool) or isinstance(actual, bool):
        return bool(actual) == bool(expected)
    if actual is None or expected is None:
        return actual is expected
    return str(actual) == str(expected)


class _FakeResult:
    def __init__(self, data, count=None):
        self.data = data
        self.count = count


class _FakeQuery:
    """Supports the builder chains the demo endpoints use."""

    def __init__(self, store: dict, table: str):
        self._store = store
        self._table = table
        self._op = "select"
        self._payload = None
        self._filters = []
        self._count = None

    def select(self, *_cols, count=None):
        self._op = "select"
        self._count = count
        return self

    def insert(self, payload):
        self._op = "insert"
        self._payload = payload
        return self

    def update(self, payload):
        self._op = "update"
        self._payload = payload
        return self

    def delete(self):
        self._op = "delete"
        return self

    def eq(self, col, val):
        self._filters.append((col, val))
        return self

    def _rows(self):
        return self._store.setdefault(self._table, [])

    def _matches(self, row) -> bool:
        return all(_values_equal(row.get(col), val) for col, val in self._filters)

    def execute(self):
        rows = self._rows()

        if self._op == "select":
            hits = [dict(r) for r in rows if self._matches(r)]
            return _FakeResult(hits, count=len(hits) if self._count else None)

        if self._op == "insert":
            row = dict(self._payload)
            row.setdefault("id", str(uuid.uuid4()))
            now = datetime.now(timezone.utc).isoformat()
            row.setdefault("created_at", now)
            if self._table == "demo_sessions":
                row.setdefault("started_at", now)
            rows.append(row)
            return _FakeResult([dict(row)])

        if self._op == "update":
            hit = [r for r in rows if self._matches(r)]
            for r in hit:
                r.update(self._payload)
            return _FakeResult([dict(r) for r in hit])

        if self._op == "delete":
            hit = [r for r in rows if self._matches(r)]
            for r in hit:
                rows.remove(r)
            return _FakeResult([dict(r) for r in hit])

        raise AssertionError(f"unsupported op {self._op}")


class FakeSupabaseClient:
    def __init__(self):
        self.tables: dict = {}

    def seed(self, table: str, rows: list):
        self.tables.setdefault(table, []).extend(dict(r) for r in rows)

    def table(self, name: str) -> _FakeQuery:
        return _FakeQuery(self.tables, name)

    def from_(self, name: str) -> _FakeQuery:
        return _FakeQuery(self.tables, name)


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def fake_db():
    """Patch `get_supabase_db` inside the demo module with the in-memory fake."""
    with patch("api.v1.demo.get_supabase_db") as mock_get_db:
        fake_client = FakeSupabaseClient()
        db = MagicMock()
        db.client = fake_client
        mock_get_db.return_value = db
        yield fake_client


@pytest.fixture
async def client(fake_db) -> AsyncClient:
    """ASGI client — these tests `await` their requests (see module docstring)."""
    from main import app

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.fixture
def admin_client(fake_db):
    """Client whose caller passes the admin gate on /demo/analytics/*."""
    from main import app
    from core.auth import get_admin_user

    app.dependency_overrides[get_admin_user] = lambda: {"id": "admin-user", "is_admin": True}
    transport = ASGITransport(app=app)
    yield AsyncClient(transport=transport, base_url="http://test")
    app.dependency_overrides.pop(get_admin_user, None)


@pytest.fixture(autouse=True)
def _reset_rate_limits():
    """Clear slowapi's counters between tests.

    The demo routes are limited to 3-5 calls/hour PER IP and every test in the
    process shares one IP, so without this the 4th /generate-preview-plan call in
    the module 429s. Resetting (rather than disabling) keeps the limiter live, so
    a burst inside a single test is still rate-limited for real.
    """
    from core.rate_limiter import limiter, user_limiter

    for lim in (limiter, user_limiter):
        try:
            lim.reset()
        except Exception:  # storage without reset support — nothing to clear
            pass
    yield


class TestDemoPreviewPlan:
    """Tests for the preview plan generation endpoint."""

    @pytest.mark.asyncio
    async def test_generate_preview_plan_basic(self, client: AsyncClient):
        """Test generating a basic preview plan."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["build_muscle"],
                "fitness_level": "intermediate",
                "equipment": ["dumbbells", "barbell"],
                "days_per_week": 3,
                "training_split": "push_pull_legs",
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert "session_id" in data
        assert "plan" in data
        assert data["plan"]["days_per_week"] == 3
        assert len(data["plan"]["workout_days"]) == 3

    @pytest.mark.asyncio
    async def test_generate_preview_plan_with_session_id(self, client: AsyncClient):
        """Test that provided session_id is used."""
        session_id = str(uuid.uuid4())

        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["lose_weight"],
                "fitness_level": "beginner",
                "equipment": ["bodyweight"],
                "days_per_week": 2,
                "session_id": session_id,
            }
        )

        assert response.status_code == 200
        assert response.json()["session_id"] == session_id

    @pytest.mark.asyncio
    async def test_generate_preview_plan_exercises_not_empty(self, client: AsyncClient):
        """Test that exercises are returned for each day."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["increase_strength"],
                "fitness_level": "advanced",
                "equipment": ["dumbbells", "barbell", "cable_machine"],
                "days_per_week": 4,
            }
        )

        assert response.status_code == 200
        data = response.json()

        for day in data["plan"]["workout_days"]:
            assert "exercises" in day
            assert len(day["exercises"]) > 0

            for exercise in day["exercises"]:
                assert "name" in exercise
                assert "sets" in exercise
                assert "reps" in exercise

    @pytest.mark.asyncio
    async def test_generate_preview_plan_different_splits(self, client: AsyncClient):
        """Test plan generation with different training splits."""
        splits = ["push_pull_legs", "upper_lower", "full_body"]

        for split in splits:
            response = await client.post(
                "/api/v1/demo/generate-preview-plan",
                json={
                    "goals": ["build_muscle"],
                    "fitness_level": "intermediate",
                    "equipment": ["dumbbells"],
                    "days_per_week": 3,
                    "training_split": split,
                }
            )

            assert response.status_code == 200
            data = response.json()
            assert data["plan"]["training_split"] == split

    @pytest.mark.asyncio
    async def test_generate_preview_plan_includes_personalization(self, client: AsyncClient):
        """Test that personalization info is included."""
        response = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["build_muscle"],
                "fitness_level": "beginner",
                "equipment": ["dumbbells", "barbell"],
                "days_per_week": 3,
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert "personalization" in data
        assert data["personalization"]["goal_match"] is True
        assert data["personalization"]["fitness_level"] == "beginner"
        assert "total_exercises" in data["personalization"]

class TestDemoSession:
    """Tests for demo session management."""

    @pytest.mark.asyncio
    async def test_start_new_session(self, client: AsyncClient):
        """Test starting a new demo session."""
        response = await client.post(
            "/api/v1/demo/session/start",
            json={
                "quiz_data": {"goal": "build_muscle"},
                "device_info": {"platform": "ios", "version": "1.0.0"},
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert "session_id" in data
        assert data["status"] in ["active", "resumed"]

    @pytest.mark.asyncio
    async def test_resume_existing_session(self, client: AsyncClient):
        """Test resuming an existing session."""
        # Start session
        start_response = await client.post(
            "/api/v1/demo/session/start",
            json={"quiz_data": {"goal": "lose_weight"}}
        )
        session_id = start_response.json()["session_id"]

        # Resume with more data
        resume_response = await client.post(
            "/api/v1/demo/session/start",
            json={
                "session_id": session_id,
                "quiz_data": {"goal": "lose_weight", "level": "beginner"},
            }
        )

        assert resume_response.status_code == 200
        assert resume_response.json()["session_id"] == session_id
        assert resume_response.json()["status"] == "resumed"

    @pytest.mark.asyncio
    async def test_get_session_details(self, client: AsyncClient):
        """Test getting session details."""
        # Start session
        start_response = await client.post(
            "/api/v1/demo/session/start",
            json={"quiz_data": {"goal": "build_muscle"}}
        )
        session_id = start_response.json()["session_id"]

        # Get session
        get_response = await client.get(f"/api/v1/demo/session/{session_id}")

        assert get_response.status_code == 200
        data = get_response.json()
        assert "session" in data
        assert data["session"]["session_id"] == session_id


class TestDemoInteractions:
    """Tests for demo interaction logging."""

    @pytest.mark.asyncio
    async def test_log_screen_view(self, client: AsyncClient):
        """Test logging a screen view."""
        response = await client.post(
            "/api/v1/demo/interaction",
            json={
                "session_id": str(uuid.uuid4()),
                "action_type": "screen_view",
                "screen": "exercise_library",
                "duration_seconds": 30,
            }
        )

        assert response.status_code == 200
        assert response.json()["status"] == "logged"

    @pytest.mark.asyncio
    async def test_log_feature_tap(self, client: AsyncClient):
        """Test logging a feature tap."""
        response = await client.post(
            "/api/v1/demo/interaction",
            json={
                "session_id": str(uuid.uuid4()),
                "action_type": "feature_tap",
                "feature": "ai_coach_chat",
                "metadata": {"was_locked": True},
            }
        )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_log_workout_preview(self, client: AsyncClient):
        """Test logging a workout preview."""
        response = await client.post(
            "/api/v1/demo/interaction",
            json={
                "session_id": str(uuid.uuid4()),
                "action_type": "workout_preview",
                "screen": "personalized_preview",
                "metadata": {"workout_day": 1, "exercises_viewed": 5},
            }
        )

        assert response.status_code == 200


class TestSampleWorkouts:
    """Tests for sample workout retrieval."""

    @pytest.mark.asyncio
    async def test_get_sample_workouts(self, client: AsyncClient):
        """Test getting sample workouts."""
        response = await client.get("/api/v1/demo/sample-workouts")

        assert response.status_code == 200
        data = response.json()

        assert "workouts" in data
        assert len(data["workouts"]) >= 3

        for workout in data["workouts"]:
            assert "id" in workout
            assert "name" in workout
            assert "exercises" in workout
            assert len(workout["exercises"]) > 0

    @pytest.mark.asyncio
    async def test_get_sample_workouts_with_level(self, client: AsyncClient):
        """Test getting sample workouts filtered by level."""
        response = await client.get(
            "/api/v1/demo/sample-workouts",
            params={"fitness_level": "beginner"}
        )

        assert response.status_code == 200
        data = response.json()
        assert "workouts" in data


class TestSessionConversion:
    """Tests for session conversion tracking."""

    @pytest.mark.asyncio
    async def test_convert_session(self, client: AsyncClient):
        """Test converting a demo session to a user."""
        # Start session
        start_response = await client.post(
            "/api/v1/demo/session/start",
            json={"quiz_data": {"goal": "build_muscle"}}
        )
        session_id = start_response.json()["session_id"]

        # Convert session
        user_id = str(uuid.uuid4())
        convert_response = await client.post(
            "/api/v1/demo/session/convert",
            json={
                "session_id": session_id,
                "user_id": user_id,
                "trigger": "paywall_skip",
            }
        )

        assert convert_response.status_code == 200
        assert convert_response.json()["status"] == "converted"

    @pytest.mark.asyncio
    async def test_convert_session_records_duration(self, client: AsyncClient):
        """Test that conversion records session duration."""
        # Start session
        start_response = await client.post(
            "/api/v1/demo/session/start",
            json={"quiz_data": {"goal": "build_muscle"}}
        )
        session_id = start_response.json()["session_id"]

        # Log some interactions to simulate time passing
        await client.post(
            "/api/v1/demo/interaction",
            json={
                "session_id": session_id,
                "action_type": "screen_view",
                "screen": "home",
                "duration_seconds": 60,
            }
        )

        # Convert session
        user_id = str(uuid.uuid4())
        convert_response = await client.post(
            "/api/v1/demo/session/convert",
            json={
                "session_id": session_id,
                "user_id": user_id,
                "trigger": "sign_up_button",
            }
        )

        assert convert_response.status_code == 200
        # Duration should be calculated
        assert "session_duration_seconds" in convert_response.json()
        assert convert_response.json()["session_duration_seconds"] is not None


class TestConversionAnalytics:
    """Tests for conversion analytics endpoints.

    USED TO ASSERT: these two endpoints answered 200 to ANY caller.
    RETIRED BECAUSE: demo analytics expose funnel + engagement data across all
    users, so both routes were locked behind `Depends(get_admin_user)`
    ("SECURITY: Admin-only" in demo.py).
    GUARANTEE PROTECTED NOW: an ADMIN still gets the documented payload
    (period_days + funnel_data / features) — the original intent — and a
    non-admin caller is rejected instead of being handed the data.
    """

    @pytest.mark.asyncio
    async def test_get_conversion_analytics(self, admin_client: AsyncClient, fake_db):
        """Test getting conversion analytics."""
        fake_db.seed("demo_conversion_funnel", [
            {"stage": "quiz_started", "sessions": 10, "conversions": 4},
        ])

        response = await admin_client.get("/api/v1/demo/analytics/conversion")

        assert response.status_code == 200
        data = response.json()
        assert "period_days" in data
        assert "funnel_data" in data
        assert data["funnel_data"][0]["stage"] == "quiz_started"

    @pytest.mark.asyncio
    async def test_get_feature_analytics(self, admin_client: AsyncClient, fake_db):
        """Test getting feature engagement analytics."""
        fake_db.seed("demo_feature_engagement", [
            {"feature": "ai_coach_chat", "taps": 12},
        ])

        response = await admin_client.get("/api/v1/demo/analytics/features")

        assert response.status_code == 200
        data = response.json()
        assert "features" in data
        assert data["features"][0]["feature"] == "ai_coach_chat"

    @pytest.mark.asyncio
    async def test_analytics_rejects_non_admin(self, client: AsyncClient):
        """A caller without an admin token must NOT get demo analytics."""
        for path in ("/api/v1/demo/analytics/conversion", "/api/v1/demo/analytics/features"):
            response = await client.get(path)
            assert response.status_code in (401, 403), path
