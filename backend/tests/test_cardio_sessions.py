"""
Tests for Cardio Sessions API endpoints.

Tests:
- Creating a cardio session
- Getting sessions list
- Getting single session
- Updating a session
- Deleting a session
- Getting aggregate stats
- Testing filters (by cardio_type, location, date range)
- Testing RLS (user can only see own data)

THE REAL ROUTE TABLE (api/v1/cardio.py + api/v1/cardio_endpoints.py, mounted
under /api/v1/cardio):

    POST   /cardio/sessions                        body carries user_id
    GET    /cardio/sessions/{user_id}              list (page/page_size)
    GET    /cardio/sessions/{user_id}/stats        aggregate stats (days=N)
    GET    /cardio/sessions/{user_id}/{session_id} single session
    PUT    /cardio/sessions/{session_id}           update
    DELETE /cardio/sessions/{session_id}           delete

Every route depends on `core.auth.get_current_user` and 403s on an identity
mismatch. This file previously called a *different*, imagined API — `user_id`
as a query param, `/sessions` as a GET collection, `/sessions/stats/weekly` —
and swallowed the mismatch with `assert status in [200, 404]` escape hatches
("404 if endpoint not implemented yet"). Every one of its 66 tests failed with
401 (no auth override) or 405 (no such route), i.e. the whole file was
asserting nothing about the real product. The calls are now correct, the auth
dependency is overridden, and the escape hatches are gone: each test asserts
the one status code and the response body the endpoint is contracted to
produce.

Run with: pytest backend/tests/test_cardio_sessions.py -v
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch
from datetime import datetime, timedelta, timezone
from contextlib import contextmanager
import uuid

from main import app
from core.auth import get_current_user


client = TestClient(app)

# A second client that does NOT re-raise server exceptions, so we can observe
# the HTTP response the global handler actually produces for an unhandled
# error (main.py:1116 → 500 {"detail": "Internal server error"}).
client_no_reraise = TestClient(app, raise_server_exceptions=False)


# ============================================================
# SUPABASE TEST DOUBLE
# ============================================================
#
# The old MagicMock chains (`table.return_value.select.return_value.eq...`)
# could not express "users returns X but cardio_sessions returns Y", could not
# distinguish the two queries the stats endpoint issues, and silently answered
# *any* chain — so a wrong call still got a mock back. This double routes by
# table name, answers per-operation, and RECORDS what was executed, which lets
# the filter/pagination/ordering tests assert the query that was actually built
# rather than just the status code.


class _Response:
    """Stand-in for a supabase-py APIResponse."""

    def __init__(self, data, count=None):
        self.data = data
        self.count = count


class _TableStub:
    """Chainable stand-in for a supabase-py table query builder."""

    def __init__(
        self,
        *,
        rows=None,
        row_queue=None,
        single=None,
        insert_result=None,
        update_result=None,
        delete_result=None,
        count=None,
        error=None,
    ):
        self._rows = rows if rows is not None else []
        self._row_queue = list(row_queue) if row_queue is not None else None
        self._single = single
        self._insert_result = insert_result
        self._update_result = update_result
        self._delete_result = delete_result if delete_result is not None else [{}]
        self._count = count
        self._error = error

        # Per-query builder state (reset on execute()).
        self._op = None
        self._payload = None
        self._is_single = False
        self._filters = []
        self._order = None
        self._range = None

        # Everything that reached execute(), in order.
        self.executed = []

    # -- terminal-op selectors -------------------------------------------
    def select(self, *args, **kwargs):
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

    def delete(self):
        self._op = "delete"
        return self

    # -- filters ----------------------------------------------------------
    def _filter(self, op, column, value):
        self._filters.append((op, column, value))
        return self

    def eq(self, column, value):
        return self._filter("eq", column, value)

    def neq(self, column, value):
        return self._filter("neq", column, value)

    def gte(self, column, value):
        return self._filter("gte", column, value)

    def lte(self, column, value):
        return self._filter("lte", column, value)

    def gt(self, column, value):
        return self._filter("gt", column, value)

    def lt(self, column, value):
        return self._filter("lt", column, value)

    def in_(self, column, value):
        return self._filter("in", column, value)

    # -- shaping ----------------------------------------------------------
    def order(self, column, desc=False):
        self._order = (column, desc)
        return self

    def range(self, start, end):
        self._range = (start, end)
        return self

    def limit(self, n):
        self._range = (0, n - 1)
        return self

    def maybe_single(self):
        self._is_single = True
        return self

    # -- execution --------------------------------------------------------
    def execute(self):
        record = {
            "op": self._op,
            "payload": self._payload,
            "filters": list(self._filters),
            "order": self._order,
            "range": self._range,
            "single": self._is_single,
        }
        op, is_single = self._op, self._is_single
        self._op = self._payload = None
        self._is_single = False
        self._filters = []
        self._order = self._range = None

        if self._error is not None:
            raise self._error

        self.executed.append(record)

        if op == "insert":
            return _Response(self._insert_result)
        if op == "update":
            return _Response(self._update_result)
        if op == "delete":
            return _Response(self._delete_result)
        if is_single:
            return _Response(self._single)
        if self._row_queue is not None:
            rows = self._row_queue.pop(0) if self._row_queue else []
        else:
            rows = self._rows
        return _Response(rows, count=self._count if self._count is not None else len(rows))

    # -- assertion helpers -------------------------------------------------
    def ops(self):
        return [e["op"] for e in self.executed]

    def last(self, op=None, single=None):
        """The most recent execute() matching op / single-ness."""
        for entry in reversed(self.executed):
            if op is not None and entry["op"] != op:
                continue
            if single is not None and entry["single"] != single:
                continue
            return entry
        raise AssertionError(f"no executed query with op={op} single={single}: {self.executed}")


class _FakeClient:
    def __init__(self, tables):
        self._tables = tables

    def table(self, name):
        if name not in self._tables:
            raise AssertionError(
                f"endpoint queried an unexpected table {name!r}; "
                f"this test only stubs {sorted(self._tables)}"
            )
        return self._tables[name]


class _FakeDb:
    def __init__(self, tables):
        self.client = _FakeClient(tables)


@contextmanager
def patched_db(**tables):
    """Patch get_supabase_db in BOTH cardio modules and yield the table stubs.

    The session routes are split across api.v1.cardio (POST /sessions) and
    api.v1.cardio_endpoints (list/stats/get/put/delete); each imported
    get_supabase_db into its own namespace, so patching only one — as this
    file used to — leaves the other talking to a real Supabase client.
    """
    db = _FakeDb(tables)
    with patch("api.v1.cardio.get_supabase_db", return_value=db), \
            patch("api.v1.cardio_endpoints.get_supabase_db", return_value=db):
        yield tables


@contextmanager
def authenticated_as(user_id):
    """Override the get_current_user dependency for the duration of the block."""

    async def _override():
        return {"id": user_id, "email": "test@example.com"}

    previous = app.dependency_overrides.get(get_current_user)
    app.dependency_overrides[get_current_user] = _override
    try:
        yield
    finally:
        if previous is None:
            app.dependency_overrides.pop(get_current_user, None)
        else:
            app.dependency_overrides[get_current_user] = previous


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def other_user_id():
    """Another user ID for RLS testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_session_id():
    """Sample cardio session ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def users_table(sample_user_id):
    """`users` table stub where the sample user exists."""
    return _TableStub(single={"id": sample_user_id})


def _row(user_id, **overrides):
    """A cardio_sessions row with the columns the API actually reads.

    The old fixtures invented columns the table does not have (`weather`,
    `temperature_celsius`, `started_at`, `completed_at`, `laps`,
    `avg_pace_min_per_km`) and omitted ones `_parse_cardio_session` requires
    (`avg_speed_kmh`, `weather_conditions`, `updated_at`), so any test that had
    actually reached the parser would have blown up.
    """
    now = datetime.now(timezone.utc)
    row = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "workout_id": None,
        "cardio_type": "running",
        "location": "outdoor",
        "distance_km": 7.5,
        "duration_minutes": 45,
        "avg_pace_per_km": "6:00",
        "avg_speed_kmh": 10.0,
        "elevation_gain_m": 85,
        "avg_heart_rate": 145,
        "max_heart_rate": 172,
        "calories_burned": 520,
        "notes": "Morning run in the park",
        "weather_conditions": "sunny",
        "created_at": now.isoformat(),
        "updated_at": now.isoformat(),
    }
    row.update(overrides)
    return row


@pytest.fixture
def sample_cardio_session(sample_user_id, sample_session_id):
    """Sample running session row."""
    return _row(sample_user_id, id=sample_session_id)


@pytest.fixture
def sample_cycling_session(sample_user_id):
    """Sample cycling session row."""
    return _row(
        sample_user_id,
        cardio_type="cycling",
        location="indoor",
        duration_minutes=60,
        distance_km=25.0,
        avg_pace_per_km="2:24",
        avg_speed_kmh=25.0,
        elevation_gain_m=0,
        avg_heart_rate=135,
        max_heart_rate=160,
        calories_burned=480,
        notes="Spin class workout",
        weather_conditions=None,
    )


@pytest.fixture
def sample_swimming_session(sample_user_id):
    """Sample swimming session row."""
    return _row(
        sample_user_id,
        cardio_type="swimming",
        location="pool",
        duration_minutes=40,
        distance_km=1.5,
        avg_pace_per_km="26:40",
        avg_speed_kmh=2.25,
        elevation_gain_m=0,
        avg_heart_rate=130,
        max_heart_rate=155,
        calories_burned=350,
        notes="Pool session",
        weather_conditions=None,
    )


# ============================================================
# CREATE SESSION TESTS
# ============================================================

class TestCreateCardioSession:
    """Test creating cardio sessions."""

    def test_create_running_session_success(self, users_table, sample_user_id, sample_cardio_session):
        """Test creating a running session successfully."""
        sessions = _TableStub(insert_result=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "running",
                    "location": "outdoor",
                    "duration_minutes": 45,
                    "distance_km": 7.5,
                    "avg_heart_rate": 145,
                    "max_heart_rate": 172,
                    "calories_burned": 520,
                    "notes": "Morning run in the park",
                },
            )

        assert response.status_code == 200
        body = response.json()
        assert body["id"] == sample_cardio_session["id"]
        assert body["user_id"] == sample_user_id
        assert body["cardio_type"] == "running"
        assert body["location"] == "outdoor"
        assert body["duration_minutes"] == 45

        # The row handed to Supabase carries the derived pace/speed the API
        # promises to compute when the client omits them: 7.5km in 45min.
        inserted = sessions.last(op="insert")["payload"]
        assert inserted["user_id"] == sample_user_id
        assert inserted["cardio_type"] == "running"
        assert inserted["avg_speed_kmh"] == 10.0        # 7.5 / 45 * 60
        assert inserted["avg_pace_per_km"] == "6:00"    # 45 / 7.5

    def test_create_cycling_session_success(self, users_table, sample_user_id, sample_cycling_session):
        """Test creating a cycling session successfully."""
        sessions = _TableStub(insert_result=[sample_cycling_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "cycling",
                    "location": "indoor",
                    "duration_minutes": 60,
                    "distance_km": 25.0,
                    "avg_heart_rate": 135,
                    "calories_burned": 480,
                    "notes": "Spin class workout",
                },
            )

        assert response.status_code == 200
        body = response.json()
        assert body["cardio_type"] == "cycling"
        assert body["location"] == "indoor"
        assert body["duration_minutes"] == 60
        assert body["distance_km"] == 25.0

        inserted = sessions.last(op="insert")["payload"]
        assert inserted["avg_speed_kmh"] == 25.0        # 25 / 60 * 60
        assert inserted["avg_pace_per_km"] == "2:24"    # 60 / 25

    def test_create_swimming_session_success(self, users_table, sample_user_id, sample_swimming_session):
        """Test creating a swimming session successfully.

        `laps` / `stroke_type` are not columns on cardio_sessions and are not
        fields of CardioSessionCreate; they are dropped by pydantic. The
        session still persists, which is the guarantee this test protects.
        """
        sessions = _TableStub(insert_result=[sample_swimming_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "swimming",
                    "location": "pool",
                    "duration_minutes": 40,
                    "distance_km": 1.5,
                    "avg_heart_rate": 130,
                },
            )

        assert response.status_code == 200
        body = response.json()
        assert body["cardio_type"] == "swimming"
        assert body["location"] == "pool"
        assert body["duration_minutes"] == 40

        inserted = sessions.last(op="insert")["payload"]
        assert "laps" not in inserted
        assert "stroke_type" not in inserted

    def test_create_session_invalid_cardio_type(self, users_table, sample_user_id):
        """Test creating a session with invalid cardio type."""
        sessions = _TableStub()

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "invalid_type",
                    "location": "outdoor",
                    "duration_minutes": 30,
                },
            )

        assert response.status_code == 422
        # Rejected at the schema boundary — nothing was written.
        assert sessions.executed == []

    def test_create_session_missing_required_fields(self, users_table, sample_user_id):
        """Test creating a session without required fields."""
        sessions = _TableStub()

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post("/api/v1/cardio/sessions", json={})

        assert response.status_code == 422
        missing = {
            tuple(err["loc"][1:])
            for err in response.json()["detail"]
            if err["type"] == "missing"
        }
        assert ("user_id",) in missing
        assert ("cardio_type",) in missing
        assert ("location",) in missing
        assert ("duration_minutes",) in missing
        assert sessions.executed == []

    def test_create_session_user_not_found(self, sample_user_id):
        """Test creating a session for non-existent user."""
        users = _TableStub(single=None)
        sessions = _TableStub()

        with authenticated_as(sample_user_id), patched_db(users=users, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "running",
                    "location": "outdoor",
                    "duration_minutes": 30,
                },
            )

        assert response.status_code == 404
        assert response.json()["detail"] == "User not found"
        assert sessions.executed == []


# ============================================================
# GET SESSIONS LIST TESTS
# ============================================================

class TestGetCardioSessionsList:
    """Test getting list of cardio sessions."""

    def test_get_sessions_list_success(self, users_table, sample_user_id, sample_cardio_session, sample_cycling_session):
        """Test getting list of sessions successfully."""
        sessions = _TableStub(rows=[sample_cardio_session, sample_cycling_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == sample_user_id
        assert data["total_count"] == 2
        assert len(data["sessions"]) == 2
        assert [s["cardio_type"] for s in data["sessions"]] == ["running", "cycling"]

    def test_get_sessions_list_empty(self, users_table, sample_user_id):
        """Test getting empty list of sessions."""
        sessions = _TableStub(rows=[])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["sessions"] == []
        assert data["total_count"] == 0

    def test_get_sessions_with_pagination(self, users_table, sample_user_id, sample_cardio_session):
        """Test getting sessions with pagination.

        The API paginates with page/page_size (1-indexed), not limit/offset.
        Page 2 of 10 must ask Supabase for rows 10..19 — an off-by-one here
        silently duplicates or drops a session at every page boundary.
        """
        sessions = _TableStub(rows=[sample_cardio_session], count=25)

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?page=2&page_size=10"
            )

        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 2
        assert data["page_size"] == 10
        assert data["total_count"] == 25
        assert sessions.last(op="select")["range"] == (10, 19)

    def test_get_sessions_user_not_found(self, sample_user_id):
        """Test listing sessions for a user that does not exist."""
        users = _TableStub(single=None)
        sessions = _TableStub(rows=[])

        with authenticated_as(sample_user_id), patched_db(users=users, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{sample_user_id}")

        assert response.status_code == 404
        assert response.json()["detail"] == "User not found"


# ============================================================
# GET SINGLE SESSION TESTS
# ============================================================

class TestGetSingleCardioSession:
    """Test getting a single cardio session."""

    def test_get_session_success(self, sample_user_id, sample_session_id, sample_cardio_session):
        """Test getting a single session successfully."""
        sessions = _TableStub(single=sample_cardio_session)

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}/{sample_session_id}"
            )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_session_id
        assert data["user_id"] == sample_user_id
        assert data["cardio_type"] == "running"

        # The lookup is scoped by BOTH id and user_id — that scoping is the
        # server-side half of RLS for this route.
        filters = sessions.last(op="select")["filters"]
        assert ("eq", "id", sample_session_id) in filters
        assert ("eq", "user_id", sample_user_id) in filters

    def test_get_session_not_found(self, sample_user_id, sample_session_id):
        """Test getting non-existent session."""
        sessions = _TableStub(single=None)

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}/{sample_session_id}"
            )

        assert response.status_code == 404
        assert response.json()["detail"] == "Cardio session not found"

    def test_get_session_invalid_uuid(self, sample_user_id):
        """Test getting session with invalid UUID.

        The route takes session_id as a plain string, so a malformed id is not
        a validation error — it simply matches no row. The guarantee is that it
        404s rather than 500ing or leaking another user's session.
        """
        sessions = _TableStub(single=None)

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}/invalid-uuid"
            )

        assert response.status_code == 404
        assert response.json()["detail"] == "Cardio session not found"


# ============================================================
# UPDATE SESSION TESTS
# ============================================================

class TestUpdateCardioSession:
    """Test updating cardio sessions."""

    def test_update_session_success(self, sample_user_id, sample_session_id, sample_cardio_session):
        """Test updating a session successfully."""
        updated = {**sample_cardio_session, "notes": "Updated notes", "distance_km": 8.0}
        sessions = _TableStub(single=sample_cardio_session, update_result=[updated])

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.put(
                f"/api/v1/cardio/sessions/{sample_session_id}",
                json={"notes": "Updated notes", "distance_km": 8.0},
            )

        assert response.status_code == 200
        data = response.json()
        assert data["notes"] == "Updated notes"
        assert data["distance_km"] == 8.0

        # Changing distance must re-derive pace/speed against the stored
        # duration (45 min), otherwise the session keeps stale metrics.
        payload = sessions.last(op="update")["payload"]
        assert payload["notes"] == "Updated notes"
        assert payload["distance_km"] == 8.0
        assert payload["avg_speed_kmh"] == 10.67       # 8.0 / 45 * 60
        assert payload["avg_pace_per_km"] == "5:38"    # 45 / 8.0 → 337.5s/km
        assert sessions.last(op="update")["filters"] == [("eq", "id", sample_session_id)]

    def test_update_session_not_found(self, sample_user_id, sample_session_id):
        """Test updating non-existent session."""
        sessions = _TableStub(single=None)

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.put(
                f"/api/v1/cardio/sessions/{sample_session_id}",
                json={"notes": "Updated notes"},
            )

        assert response.status_code == 404
        assert response.json()["detail"] == "Cardio session not found"
        assert "update" not in sessions.ops()

    def test_update_session_not_owner(self, sample_user_id, other_user_id, sample_session_id, sample_cardio_session):
        """Test updating session not owned by user."""
        owned_by_other = {**sample_cardio_session, "user_id": other_user_id}
        sessions = _TableStub(single=owned_by_other, update_result=[owned_by_other])

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.put(
                f"/api/v1/cardio/sessions/{sample_session_id}",
                json={"notes": "Hacked notes"},
            )

        assert response.status_code == 403
        assert response.json()["detail"] == "Access denied"
        assert "update" not in sessions.ops()

    def test_update_session_partial_update(self, sample_user_id, sample_session_id, sample_cardio_session):
        """Test partial update of a session."""
        updated = {**sample_cardio_session, "calories_burned": 600}
        sessions = _TableStub(single=sample_cardio_session, update_result=[updated])

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.put(
                f"/api/v1/cardio/sessions/{sample_session_id}",
                json={"calories_burned": 600},
            )

        assert response.status_code == 200
        assert response.json()["calories_burned"] == 600

        # Only the supplied field is written — an omitted field must not be
        # nulled out, and pace/speed must not be recomputed.
        assert sessions.last(op="update")["payload"] == {"calories_burned": 600}


# ============================================================
# DELETE SESSION TESTS
# ============================================================

class TestDeleteCardioSession:
    """Test deleting cardio sessions."""

    def test_delete_session_success(self, sample_user_id, sample_session_id):
        """Test deleting a session successfully."""
        sessions = _TableStub(
            single={"id": sample_session_id, "user_id": sample_user_id},
            delete_result=[{"id": sample_session_id}],
        )

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.delete(f"/api/v1/cardio/sessions/{sample_session_id}")

        assert response.status_code == 200
        assert response.json()["success"] is True
        assert sessions.last(op="delete")["filters"] == [("eq", "id", sample_session_id)]

    def test_delete_session_not_found(self, sample_user_id, sample_session_id):
        """Test deleting non-existent session."""
        sessions = _TableStub(single=None)

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.delete(f"/api/v1/cardio/sessions/{sample_session_id}")

        assert response.status_code == 404
        assert response.json()["detail"] == "Cardio session not found"
        assert "delete" not in sessions.ops()

    def test_delete_session_not_owner(self, sample_user_id, other_user_id, sample_session_id):
        """Test deleting session not owned by user."""
        sessions = _TableStub(single={"id": sample_session_id, "user_id": other_user_id})

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.delete(f"/api/v1/cardio/sessions/{sample_session_id}")

        assert response.status_code == 403
        assert response.json()["detail"] == "Access denied"
        assert "delete" not in sessions.ops()


# ============================================================
# AGGREGATE STATS TESTS
# ============================================================

class TestCardioSessionStats:
    """Test getting aggregate cardio session stats."""

    def test_get_aggregate_stats_success(self, users_table, sample_user_id):
        """Test getting aggregate stats successfully."""
        current = [
            _row(sample_user_id, cardio_type="running", duration_minutes=45,
                 distance_km=7.5, calories_burned=520, elevation_gain_m=85),
            _row(sample_user_id, cardio_type="running", duration_minutes=40,
                 distance_km=6.5, calories_burned=450, elevation_gain_m=60),
            _row(sample_user_id, cardio_type="cycling", location="indoor",
                 duration_minutes=60, distance_km=25.0, calories_burned=480,
                 elevation_gain_m=0),
        ]
        sessions = _TableStub(row_queue=[current, []])  # current period, then previous

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{sample_user_id}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["total_sessions"] == 3
        assert data["total_distance_km"] == 39.0        # 7.5 + 6.5 + 25.0
        assert data["total_duration_minutes"] == 145    # 45 + 40 + 60
        assert data["total_calories_burned"] == 1450    # 520 + 450 + 480
        assert data["total_elevation_gain_m"] == 145    # 85 + 60 + 0
        assert data["period_days"] == 30

    def test_get_stats_by_cardio_type(self, users_table, sample_user_id):
        """Test getting stats grouped by cardio type.

        The API has no `group_by` query param — the per-type breakdown is
        always present in `stats_by_type`, so that is what this asserts.
        """
        current = [
            _row(sample_user_id, cardio_type="running", duration_minutes=45,
                 distance_km=7.5, calories_burned=520),
            _row(sample_user_id, cardio_type="running", duration_minutes=40,
                 distance_km=6.5, calories_burned=450),
            _row(sample_user_id, cardio_type="cycling", location="indoor",
                 duration_minutes=60, distance_km=25.0, calories_burned=480),
        ]
        sessions = _TableStub(row_queue=[current, []])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{sample_user_id}/stats")

        assert response.status_code == 200
        by_type = {s["cardio_type"]: s for s in response.json()["stats_by_type"]}
        assert set(by_type) == {"running", "cycling"}

        assert by_type["running"]["session_count"] == 2
        assert by_type["running"]["total_distance_km"] == 14.0
        assert by_type["running"]["total_duration_minutes"] == 85
        assert by_type["running"]["total_calories_burned"] == 970

        assert by_type["cycling"]["session_count"] == 1
        assert by_type["cycling"]["total_distance_km"] == 25.0
        assert by_type["cycling"]["total_duration_minutes"] == 60
        assert by_type["cycling"]["avg_speed_kmh"] == 25.0
        # 60 min / 25 km is exactly 2:24 per km. This used to come back as
        # "2:23" — see the pace-truncation bug fixed in
        # services/cardio/pace.py (int((2.4 - 2) * 60) == 23).
        assert by_type["cycling"]["avg_pace_per_km"] == "2:24"
        assert by_type["running"]["avg_pace_per_km"] == "6:04"  # 85 min / 14 km

    def test_get_stats_with_date_range(self, users_table, sample_user_id):
        """Test getting stats within a date range.

        The window is expressed as `days=N` (not start_date/end_date), and the
        endpoint must translate it into a created_at lower bound N days back —
        the previous-period comparison is only meaningful if it does.
        """
        sessions = _TableStub(row_queue=[[], []])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}/stats?days=30"
            )

        assert response.status_code == 200
        assert response.json()["period_days"] == 30

        current_query, previous_query = sessions.executed
        gte_bounds = [f for f in current_query["filters"] if f[0] == "gte"]
        assert len(gte_bounds) == 1
        current_start = datetime.fromisoformat(gte_bounds[0][2])
        assert abs((datetime.now() - current_start) - timedelta(days=30)) < timedelta(minutes=1)

        # The previous period is the 30 days immediately before that.
        prev_gte = [f for f in previous_query["filters"] if f[0] == "gte"][0]
        prev_lt = [f for f in previous_query["filters"] if f[0] == "lt"][0]
        assert datetime.fromisoformat(prev_lt[2]) == current_start
        assert abs(
            (current_start - datetime.fromisoformat(prev_gte[2])) - timedelta(days=30)
        ) < timedelta(seconds=1)

    def test_get_weekly_stats(self, users_table, sample_user_id):
        """Test getting weekly stats summary.

        There is no /stats/weekly route (the old URL resolved to
        /sessions/{user_id}/{session_id} and 403'd). A weekly summary is
        `?days=7` on the stats route; that is the guarantee protected here.
        """
        current = [
            _row(sample_user_id, duration_minutes=45, distance_km=7.5, calories_burned=520),
            _row(sample_user_id, cardio_type="cycling", location="indoor",
                 duration_minutes=60, distance_km=25.0, calories_burned=480),
        ]
        sessions = _TableStub(row_queue=[current, []])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}/stats?days=7"
            )

        assert response.status_code == 200
        data = response.json()
        assert data["period_days"] == 7
        assert data["total_sessions"] == 2
        assert data["total_distance_km"] == 32.5
        assert data["total_duration_minutes"] == 105
        assert data["total_calories_burned"] == 1000
        assert data["avg_sessions_per_week"] == 2.0     # 2 sessions / 7 days * 7

    def test_get_monthly_stats(self, users_table, sample_user_id):
        """Test getting monthly stats summary.

        Same as above: a monthly summary is `?days=30`, not /stats/monthly.
        """
        sessions = _TableStub(row_queue=[[], []])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}/stats?days=30"
            )

        assert response.status_code == 200
        data = response.json()
        assert data["period_days"] == 30
        assert data["total_sessions"] == 0

    def test_get_stats_empty_sessions(self, users_table, sample_user_id):
        """Test getting stats when no sessions exist."""
        sessions = _TableStub(row_queue=[[], []])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{sample_user_id}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["total_sessions"] == 0
        assert data["total_distance_km"] == 0
        assert data["total_duration_minutes"] == 0
        assert data["total_calories_burned"] == 0
        assert data["avg_distance_per_session_km"] == 0
        assert data["avg_heart_rate"] is None
        assert data["stats_by_type"] == []
        # No previous period either → no trend can be computed (not 0%).
        assert data["distance_trend_percent"] is None
        assert data["longest_distance_session"] is None


# ============================================================
# FILTER TESTS
# ============================================================

class TestCardioSessionFilters:
    """Test cardio session filtering."""

    def test_filter_by_cardio_type_running(self, users_table, sample_user_id, sample_cardio_session):
        """Test filtering sessions by cardio type (running)."""
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?cardio_type=running"
            )

        assert response.status_code == 200
        for session in response.json()["sessions"]:
            assert session["cardio_type"] == "running"
        assert ("eq", "cardio_type", "running") in sessions.last(op="select")["filters"]

    def test_filter_by_cardio_type_cycling(self, users_table, sample_user_id, sample_cycling_session):
        """Test filtering sessions by cardio type (cycling)."""
        sessions = _TableStub(rows=[sample_cycling_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?cardio_type=cycling"
            )

        assert response.status_code == 200
        for session in response.json()["sessions"]:
            assert session["cardio_type"] == "cycling"
        assert ("eq", "cardio_type", "cycling") in sessions.last(op="select")["filters"]

    def test_filter_by_cardio_type_swimming(self, users_table, sample_user_id, sample_swimming_session):
        """Test filtering sessions by cardio type (swimming)."""
        sessions = _TableStub(rows=[sample_swimming_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?cardio_type=swimming"
            )

        assert response.status_code == 200
        for session in response.json()["sessions"]:
            assert session["cardio_type"] == "swimming"
        assert ("eq", "cardio_type", "swimming") in sessions.last(op="select")["filters"]

    def test_filter_by_unknown_cardio_type_rejected(self, users_table, sample_user_id):
        """An unsupported cardio_type is a 422, never an unfiltered result set."""
        sessions = _TableStub(rows=[])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?cardio_type=not_a_sport"
            )

        assert response.status_code == 422
        assert sessions.executed == []

    def test_filter_by_location_outdoor(self, users_table, sample_user_id, sample_cardio_session):
        """Test filtering sessions by location (outdoor)."""
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?location=outdoor"
            )

        assert response.status_code == 200
        for session in response.json()["sessions"]:
            assert session["location"] == "outdoor"
        assert ("eq", "location", "outdoor") in sessions.last(op="select")["filters"]

    def test_filter_by_location_indoor(self, users_table, sample_user_id, sample_cycling_session):
        """Test filtering sessions by location (indoor)."""
        sessions = _TableStub(rows=[sample_cycling_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?location=indoor"
            )

        assert response.status_code == 200
        for session in response.json()["sessions"]:
            assert session["location"] == "indoor"
        assert ("eq", "location", "indoor") in sessions.last(op="select")["filters"]

    def test_filter_by_date_range(self, users_table, sample_user_id, sample_cardio_session):
        """Test filtering sessions by date range.

        Both bounds must reach PostgREST as *valid* timestamps. Regression gate
        for the bug this file uncovered: the endpoint used to blindly
        string-concat `f"{start_date}T00:00:00"`, so the ISO-8601 datetime the
        mobile CardioRepository actually sends
        (`startDate.toIso8601String()` → "2026-07-06T00:00:00.000") became
        "2026-07-06T00:00:00.000T00:00:00" — a malformed timestamp that
        PostgREST rejects, 500ing the whole list request.
        """
        start_date = (datetime.now() - timedelta(days=7)).date().isoformat()
        end_date = datetime.now().date().isoformat()
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}"
                f"?start_date={start_date}&end_date={end_date}"
            )

        assert response.status_code == 200
        filters = sessions.last(op="select")["filters"]
        assert ("gte", "created_at", f"{start_date}T00:00:00") in filters
        assert ("lte", "created_at", f"{end_date}T23:59:59") in filters

        # Same request, but with the full ISO-8601 timestamps the app sends.
        iso_sessions = _TableStub(rows=[sample_cardio_session])
        iso_start = f"{start_date}T00:00:00.000"
        iso_end = f"{end_date}T23:59:59.000Z"

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=iso_sessions):
            iso_response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}"
                f"?start_date={iso_start}&end_date={iso_end}"
            )

        assert iso_response.status_code == 200
        for op, column, value in iso_sessions.last(op="select")["filters"]:
            if op in ("gte", "lte") and column == "created_at":
                # Must parse — i.e. must not be a concatenated mess.
                datetime.fromisoformat(value)

    def test_filter_by_start_date_only(self, users_table, sample_user_id, sample_cardio_session):
        """Test filtering sessions by start date only."""
        start_date = (datetime.now() - timedelta(days=30)).date().isoformat()
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?start_date={start_date}"
            )

        assert response.status_code == 200
        filters = sessions.last(op="select")["filters"]
        assert ("gte", "created_at", f"{start_date}T00:00:00") in filters
        assert not [f for f in filters if f[0] == "lte"]

    def test_filter_by_end_date_only(self, users_table, sample_user_id, sample_cardio_session):
        """Test filtering sessions by end date only."""
        end_date = datetime.now().date().isoformat()
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?end_date={end_date}"
            )

        assert response.status_code == 200
        filters = sessions.last(op="select")["filters"]
        assert ("lte", "created_at", f"{end_date}T23:59:59") in filters
        assert not [f for f in filters if f[0] == "gte"]

    def test_filter_combined_type_and_location(self, users_table, sample_user_id, sample_cardio_session):
        """Test filtering sessions by both cardio type and location."""
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}"
                f"?cardio_type=running&location=outdoor"
            )

        assert response.status_code == 200
        filters = sessions.last(op="select")["filters"]
        assert ("eq", "user_id", sample_user_id) in filters
        assert ("eq", "cardio_type", "running") in filters
        assert ("eq", "location", "outdoor") in filters

    def test_filter_combined_all_filters(self, users_table, sample_user_id, sample_cardio_session):
        """Test filtering sessions with all filters combined."""
        start_date = (datetime.now() - timedelta(days=7)).date().isoformat()
        end_date = datetime.now().date().isoformat()
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}"
                f"?cardio_type=running&location=outdoor"
                f"&start_date={start_date}&end_date={end_date}"
            )

        assert response.status_code == 200
        filters = sessions.last(op="select")["filters"]
        assert ("eq", "user_id", sample_user_id) in filters
        assert ("eq", "cardio_type", "running") in filters
        assert ("eq", "location", "outdoor") in filters
        assert ("gte", "created_at", f"{start_date}T00:00:00") in filters
        assert ("lte", "created_at", f"{end_date}T23:59:59") in filters

    def test_filter_no_results(self, users_table, sample_user_id):
        """Test filtering that returns no results."""
        sessions = _TableStub(rows=[])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?cardio_type=rowing"
            )

        assert response.status_code == 200
        data = response.json()
        assert data["sessions"] == []
        assert data["total_count"] == 0


# ============================================================
# RLS (ROW LEVEL SECURITY) TESTS
# ============================================================

class TestCardioSessionRLS:
    """Test Row Level Security - user can only access own data."""

    def test_rls_user_sees_only_own_sessions(self, users_table, sample_user_id, sample_cardio_session):
        """Test that user only sees their own sessions."""
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{sample_user_id}")

        assert response.status_code == 200
        for session in response.json()["sessions"]:
            assert session["user_id"] == sample_user_id
        # The query itself is scoped to the caller — not merely the response.
        assert ("eq", "user_id", sample_user_id) in sessions.last(op="select")["filters"]

    def test_rls_cannot_list_other_user_sessions(self, users_table, sample_user_id, other_user_id):
        """Test that user cannot list another user's sessions."""
        sessions = _TableStub(rows=[])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{other_user_id}")

        assert response.status_code == 403
        assert response.json()["detail"] == "Access denied"
        assert sessions.executed == []

    def test_rls_cannot_access_other_user_session(self, sample_user_id, other_user_id, sample_session_id):
        """Test that user cannot access another user's session.

        Two doors, both must be shut:
        1. asking for the session under the OTHER user's path → 403.
        2. asking for it under your OWN path → the query is scoped by user_id,
           so the row does not match and you get 404 (never the other user's
           session body).
        """
        sessions = _TableStub(single=None)

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            forbidden = client.get(
                f"/api/v1/cardio/sessions/{other_user_id}/{sample_session_id}"
            )
        assert forbidden.status_code == 403
        assert forbidden.json()["detail"] == "Access denied"
        assert sessions.executed == []

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            not_found = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}/{sample_session_id}"
            )
        assert not_found.status_code == 404
        assert ("eq", "user_id", sample_user_id) in sessions.last(op="select")["filters"]

    def test_rls_cannot_create_session_for_other_user(self, users_table, sample_user_id, other_user_id):
        """Test that user cannot create a session attributed to another user."""
        sessions = _TableStub(insert_result=[])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": other_user_id,
                    "cardio_type": "running",
                    "location": "outdoor",
                    "duration_minutes": 30,
                },
            )

        assert response.status_code == 403
        assert response.json()["detail"] == "Access denied"
        assert sessions.executed == []

    def test_rls_cannot_update_other_user_session(self, sample_user_id, other_user_id, sample_session_id, sample_cardio_session):
        """Test that user cannot update another user's session."""
        owned_by_other = {**sample_cardio_session, "user_id": other_user_id}
        sessions = _TableStub(single=owned_by_other, update_result=[owned_by_other])

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.put(
                f"/api/v1/cardio/sessions/{sample_session_id}",
                json={"notes": "Trying to update other user's session"},
            )

        assert response.status_code == 403
        assert response.json()["detail"] == "Access denied"
        assert "update" not in sessions.ops()

    def test_rls_cannot_delete_other_user_session(self, sample_user_id, other_user_id, sample_session_id):
        """Test that user cannot delete another user's session."""
        sessions = _TableStub(single={"id": sample_session_id, "user_id": other_user_id})

        with authenticated_as(sample_user_id), patched_db(cardio_sessions=sessions):
            response = client.delete(f"/api/v1/cardio/sessions/{sample_session_id}")

        assert response.status_code == 403
        assert response.json()["detail"] == "Access denied"
        assert "delete" not in sessions.ops()

    def test_rls_user_stats_only_own_data(self, users_table, sample_user_id, other_user_id):
        """Test that stats only include user's own sessions."""
        current = [
            _row(sample_user_id, duration_minutes=45, distance_km=7.5),
            _row(sample_user_id, cardio_type="cycling", location="indoor",
                 duration_minutes=60, distance_km=25.0),
        ]
        sessions = _TableStub(row_queue=[current, []])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{sample_user_id}/stats")

        assert response.status_code == 200
        assert response.json()["total_sessions"] == 2
        for entry in sessions.executed:
            assert ("eq", "user_id", sample_user_id) in entry["filters"]

        # And another user's stats are simply not reachable.
        other_sessions = _TableStub(row_queue=[[], []])
        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=other_sessions):
            forbidden = client.get(f"/api/v1/cardio/sessions/{other_user_id}/stats")

        assert forbidden.status_code == 403
        assert other_sessions.executed == []

    def test_unauthenticated_requests_are_rejected(self, sample_user_id, sample_session_id):
        """No token → 401 on every cardio-session route (no dependency override)."""
        app.dependency_overrides.pop(get_current_user, None)

        assert client.get(f"/api/v1/cardio/sessions/{sample_user_id}").status_code == 401
        assert client.get(
            f"/api/v1/cardio/sessions/{sample_user_id}/stats"
        ).status_code == 401
        assert client.get(
            f"/api/v1/cardio/sessions/{sample_user_id}/{sample_session_id}"
        ).status_code == 401
        assert client.post(
            "/api/v1/cardio/sessions",
            json={
                "user_id": sample_user_id,
                "cardio_type": "running",
                "location": "outdoor",
                "duration_minutes": 30,
            },
        ).status_code == 401
        assert client.put(
            f"/api/v1/cardio/sessions/{sample_session_id}", json={"notes": "x"}
        ).status_code == 401
        assert client.delete(
            f"/api/v1/cardio/sessions/{sample_session_id}"
        ).status_code == 401


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_create_session_with_zero_duration(self, users_table, sample_user_id):
        """Test creating session with zero duration.

        duration_minutes is `ge=1` — a zero-minute cardio session is not a
        session, and letting it through would divide by zero in the pace
        calculation and poison every average in the stats endpoint.
        """
        sessions = _TableStub()

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "running",
                    "location": "outdoor",
                    "duration_minutes": 0,
                },
            )

        assert response.status_code == 422
        assert sessions.executed == []

    def test_create_session_with_negative_values(self, users_table, sample_user_id):
        """Test creating session with negative values."""
        sessions = _TableStub()

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "running",
                    "location": "outdoor",
                    "duration_minutes": -30,
                    "distance_km": -5.0,
                },
            )

        assert response.status_code == 422
        rejected = {tuple(err["loc"][1:]) for err in response.json()["detail"]}
        assert ("duration_minutes",) in rejected
        assert ("distance_km",) in rejected
        assert sessions.executed == []

    def test_create_session_with_extreme_values(self, users_table, sample_user_id):
        """Test creating session with extreme heart rate values.

        avg/max heart rate are bounded to 40..250 BPM (CardioSessionCreate);
        300/350 BPM are physiologically impossible sensor garbage and are
        rejected rather than silently skewing the user's HR averages.
        """
        sessions = _TableStub()

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "running",
                    "location": "outdoor",
                    "duration_minutes": 30,
                    "avg_heart_rate": 300,
                    "max_heart_rate": 350,
                },
            )

        assert response.status_code == 422
        rejected = {tuple(err["loc"][1:]) for err in response.json()["detail"]}
        assert ("avg_heart_rate",) in rejected
        assert ("max_heart_rate",) in rejected
        assert sessions.executed == []

    def test_create_session_very_long_notes(self, users_table, sample_user_id):
        """Test creating session with very long notes.

        notes is `max_length=2000`; a 10k-char note is rejected at the schema
        boundary instead of being handed to Postgres. A note at the limit is
        still accepted — the bound is a bound, not a ban.
        """
        sessions = _TableStub()

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "running",
                    "location": "outdoor",
                    "duration_minutes": 30,
                    "notes": "A" * 10000,
                },
            )

        assert response.status_code == 422
        assert ("notes",) in {tuple(e["loc"][1:]) for e in response.json()["detail"]}
        assert sessions.executed == []

        # Exactly at the limit → accepted, and stored verbatim.
        at_limit = "A" * 2000
        accepted_row = _row(sample_user_id, notes=at_limit)
        ok_sessions = _TableStub(insert_result=[accepted_row])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=ok_sessions):
            ok = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "running",
                    "location": "outdoor",
                    "duration_minutes": 30,
                    "notes": at_limit,
                },
            )

        assert ok.status_code == 200
        assert ok_sessions.last(op="insert")["payload"]["notes"] == at_limit

    def test_database_error_handling(self, users_table, sample_user_id):
        """Test handling database errors.

        A Supabase failure must surface as a 500 with a generic body — the
        underlying exception text (which can carry connection strings or row
        data) must never reach the client.
        """
        sessions = _TableStub(error=RuntimeError("Database connection failed"))

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client_no_reraise.get(
                f"/api/v1/cardio/sessions/{sample_user_id}"
            )

        assert response.status_code == 500
        assert response.json() == {"detail": "Internal server error"}
        assert "Database connection failed" not in response.text

    def test_invalid_date_format_filter(self, users_table, sample_user_id):
        """Test filtering with invalid date format.

        REGRESSION GATE (real bug, fixed in api/v1/cardio_endpoints.py): the
        endpoint used to interpolate the raw query string straight into the
        PostgREST filter (`f"{start_date}T00:00:00"`), so "invalid-date"
        became the timestamp "invalid-dateT00:00:00" — PostgREST 400s that,
        the exception was unhandled, and the user got a 500 for a bad input.
        It is now a 422, and nothing is queried.
        """
        sessions = _TableStub(rows=[])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?start_date=invalid-date"
            )

        assert response.status_code == 422
        assert "start_date" in response.json()["detail"]
        assert sessions.executed == []

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            end_response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}?end_date=2026-13-45"
            )

        assert end_response.status_code == 422
        assert "end_date" in end_response.json()["detail"]
        assert sessions.executed == []


# ============================================================
# CARDIO TYPES AND LOCATIONS
# ============================================================

class TestCardioTypesAndLocations:
    """Test various cardio types and locations."""

    # `hiit` is deliberately NOT a CardioType (models/cardio_session.py) — the
    # Flutter client's CardioType enum doesn't offer it either, and `other`
    # covers it. It stays in this matrix as the negative case: an unsupported
    # type must be rejected, not coerced.
    @pytest.mark.parametrize("cardio_type,expected_status", [
        ("running", 200),
        ("cycling", 200),
        ("swimming", 200),
        ("walking", 200),
        ("rowing", 200),
        ("elliptical", 200),
        ("stair_climbing", 200),
        ("jump_rope", 200),
        ("hiking", 200),
        ("other", 200),
        ("hiit", 422),
    ])
    def test_create_session_various_cardio_types(self, users_table, sample_user_id, cardio_type, expected_status):
        """Test creating sessions with various cardio types."""
        row = _row(sample_user_id, cardio_type=cardio_type, duration_minutes=30)
        sessions = _TableStub(insert_result=[row])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": cardio_type,
                    "location": "outdoor",
                    "duration_minutes": 30,
                },
            )

        assert response.status_code == expected_status
        if expected_status == 200:
            assert response.json()["cardio_type"] == cardio_type
            assert sessions.last(op="insert")["payload"]["cardio_type"] == cardio_type
        else:
            assert sessions.executed == []

    @pytest.mark.parametrize("location,expected_status", [
        ("indoor", 200),
        ("outdoor", 200),
        ("gym", 200),
        ("pool", 200),
        ("track", 200),
        ("trail", 200),
        ("treadmill", 200),
        ("mars", 422),
    ])
    def test_create_session_various_locations(self, users_table, sample_user_id, location, expected_status):
        """Test creating sessions with various locations."""
        row = _row(sample_user_id, location=location, duration_minutes=30)
        sessions = _TableStub(insert_result=[row])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.post(
                "/api/v1/cardio/sessions",
                json={
                    "user_id": sample_user_id,
                    "cardio_type": "running",
                    "location": location,
                    "duration_minutes": 30,
                },
            )

        assert response.status_code == expected_status
        if expected_status == 200:
            assert response.json()["location"] == location
            assert sessions.last(op="insert")["payload"]["location"] == location
        else:
            assert sessions.executed == []


# ============================================================
# SORTING AND ORDERING TESTS
# ============================================================

class TestSortingAndOrdering:
    """Test sorting and ordering of cardio sessions."""

    def test_get_sessions_default_order(self, users_table, sample_user_id, sample_cardio_session):
        """Test default ordering (most recent first)."""
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(f"/api/v1/cardio/sessions/{sample_user_id}")

        assert response.status_code == 200
        assert sessions.last(op="select")["order"] == ("created_at", True)

    def test_get_sessions_order_by_duration(self, users_table, sample_user_id, sample_cardio_session):
        """Test ordering by duration.

        The list route exposes NO order_by/order parameters — ordering is fixed
        to `created_at DESC` (most recent first), which is what the Cardio tab
        renders. This test used to pretend `?order_by=duration_minutes` worked
        and passed vacuously on a 404. It now pins the real contract: an
        unrecognised ordering parameter is ignored (no 500, no 422) and the
        deterministic recency ordering still holds — so a client that sends one
        never silently gets an arbitrarily-ordered page.
        """
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}"
                f"?order_by=duration_minutes&order=desc"
            )

        assert response.status_code == 200
        assert sessions.last(op="select")["order"] == ("created_at", True)

    def test_get_sessions_order_by_distance(self, users_table, sample_user_id, sample_cardio_session):
        """Test ordering by distance.

        Same contract as test_get_sessions_order_by_duration: `order_by` is not
        part of the API, so the request is served with the fixed
        `created_at DESC` ordering rather than failing.
        """
        sessions = _TableStub(rows=[sample_cardio_session])

        with authenticated_as(sample_user_id), patched_db(users=users_table, cardio_sessions=sessions):
            response = client.get(
                f"/api/v1/cardio/sessions/{sample_user_id}"
                f"?order_by=distance_km&order=asc"
            )

        assert response.status_code == 200
        assert sessions.last(op="select")["order"] == ("created_at", True)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
