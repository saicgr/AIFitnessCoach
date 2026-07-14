"""
Tests for Hormonal Health API Endpoints

Two things changed under these tests since they were written; both are fixed in
HOW the tests call the code, never in WHAT they assert:

1. `api.v1.hormonal_health` never had a `get_supabase_client` symbol — it imports
   `get_supabase` (from core.supabase_client) and uses `get_supabase().client`.
   The stale `patch("api.v1.hormonal_health.get_supabase_client")` raised
   AttributeError inside the fixture, so all 16 tests ERRORED before running.

2. Every endpoint now `Depends(get_current_user)`, so an unauthenticated
   TestClient gets 401 before the handler runs. The auth dependency is overridden
   with a fixed test user (the gate itself is asserted in
   `TestAuthGate::test_unauthenticated_request_is_rejected`).

The Supabase mock is a small in-memory PostgREST fake rather than a chain of
MagicMock `.return_value`s, because the handlers no longer hit ONE table with ONE
chain shape: `/cycle-phase` now reads period history through
`services.cycle.cycle_predictor.predict_for_user`, which queries
`hormonal_profiles` + `cycle_periods` + `hormone_logs` with different chains.
Seeding real rows keeps the tests honest — the handler's own filtering, ordering
and upsert logic runs for real.
"""

import pytest
from datetime import date, datetime, timedelta, timezone
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from uuid import uuid4

# Test data
TEST_USER_ID = str(uuid4())


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
    """Supports the exact builder chains the hormonal endpoints use."""

    def __init__(self, store: dict, table: str):
        self._store = store
        self._table = table
        self._op = "select"
        self._payload = None
        self._on_conflict = None
        self._filters = []
        self._order_col = None
        self._order_desc = False
        self._limit = None
        self._count = None

    # -- builders ------------------------------------------------------------
    def select(self, *_cols, count=None):
        self._op = "select"
        self._count = count
        return self

    def insert(self, payload):
        self._op = "insert"
        self._payload = payload
        return self

    def upsert(self, payload, on_conflict=None):
        self._op = "upsert"
        self._payload = payload
        self._on_conflict = on_conflict
        return self

    def update(self, payload):
        self._op = "update"
        self._payload = payload
        return self

    def delete(self):
        self._op = "delete"
        return self

    def eq(self, col, val):
        self._filters.append(("eq", col, val))
        return self

    def gte(self, col, val):
        self._filters.append(("gte", col, val))
        return self

    def lte(self, col, val):
        self._filters.append(("lte", col, val))
        return self

    def order(self, col, desc=False):
        self._order_col = col
        self._order_desc = desc
        return self

    def limit(self, n):
        self._limit = n
        return self

    # -- execution -----------------------------------------------------------
    def _rows(self):
        return self._store.setdefault(self._table, [])

    def _matches(self, row) -> bool:
        for op, col, val in self._filters:
            actual = row.get(col)
            if op == "eq" and not _values_equal(actual, val):
                return False
            if op == "gte" and not (actual is not None and str(actual) >= str(val)):
                return False
            if op == "lte" and not (actual is not None and str(actual) <= str(val)):
                return False
        return True

    def _with_defaults(self, payload: dict) -> dict:
        row = dict(payload)
        row.setdefault("id", str(uuid4()))
        row.setdefault("created_at", datetime.now(timezone.utc).isoformat())
        row.setdefault("updated_at", datetime.now(timezone.utc).isoformat())
        return row

    def execute(self):
        rows = self._rows()

        if self._op == "select":
            hits = [dict(r) for r in rows if self._matches(r)]
            if self._order_col:
                hits.sort(
                    key=lambda r: str(r.get(self._order_col) or ""),
                    reverse=self._order_desc,
                )
            if self._limit is not None:
                hits = hits[: self._limit]
            return _FakeResult(hits, count=len(hits) if self._count else None)

        if self._op == "insert":
            row = self._with_defaults(self._payload)
            rows.append(row)
            return _FakeResult([dict(row)])

        if self._op == "upsert":
            keys = [k.strip() for k in (self._on_conflict or "id").split(",")]
            row = self._with_defaults(self._payload)
            for existing in rows:
                if all(_values_equal(existing.get(k), row.get(k)) for k in keys):
                    existing.update(self._payload)
                    return _FakeResult([dict(existing)])
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
    """Stand-in for `get_supabase().client` with seedable tables."""

    def __init__(self):
        self.tables: dict = {}

    def seed(self, table: str, rows: list):
        self.tables.setdefault(table, []).extend(dict(r) for r in rows)

    def table(self, name: str) -> _FakeQuery:
        return _FakeQuery(self.tables, name)

    def from_(self, name: str) -> _FakeQuery:
        return _FakeQuery(self.tables, name)


def _full_profile(**overrides) -> dict:
    """A hormonal_profiles row with the NOT NULL columns the API returns."""
    row = {
        "id": str(uuid4()),
        "user_id": TEST_USER_ID,
        "gender": "female",
        "hormone_goals": [],
        "menstrual_tracking_enabled": False,
        "testosterone_optimization_enabled": False,
        "created_at": "2025-01-01T00:00:00Z",
        "updated_at": "2025-01-01T00:00:00Z",
    }
    row.update(overrides)
    return row


def _full_food(name: str, **overrides) -> dict:
    """A hormone_supportive_foods row with every NOT NULL flag the response
    model (HormoneSupportiveFood) requires."""
    row = {
        "id": str(uuid4()),
        "name": name,
        "category": "seafood",
        "is_active": True,
        "supports_testosterone": False,
        "supports_estrogen_balance": False,
        "supports_pcos": False,
        "supports_menopause": False,
        "supports_fertility": False,
        "supports_thyroid": False,
        "good_for_menstrual": False,
        "good_for_follicular": False,
        "good_for_ovulation": False,
        "good_for_luteal": False,
        "key_nutrients": [],
    }
    row.update(overrides)
    return row


def _server_today() -> date:
    """The date the endpoints resolve as "today" (tests pin the tz to UTC)."""
    return datetime.now(timezone.utc).date()


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def mock_supabase():
    """Patch the module's REAL supabase accessor (`get_supabase`, not
    `get_supabase_client`) with the in-memory fake."""
    with patch("api.v1.hormonal_health.get_supabase") as mock_get:
        fake = FakeSupabaseClient()
        wrapper = MagicMock()
        wrapper.client = fake
        mock_get.return_value = wrapper
        yield fake


@pytest.fixture
def client():
    """Authenticated test client (endpoints Depends(get_current_user))."""
    from main import app
    from core.auth import get_current_user

    app.dependency_overrides[get_current_user] = lambda: {"id": TEST_USER_ID}
    # Pin the server's "today" to UTC so date maths in the tests and in the
    # handlers agree regardless of the machine's local zone.
    yield TestClient(app, headers={"X-User-Timezone": "UTC"})
    app.dependency_overrides.pop(get_current_user, None)


class TestAuthGate:
    """The hormonal endpoints are user-scoped and must require a token."""

    def test_unauthenticated_request_is_rejected(self):
        from main import app

        anon = TestClient(app)
        response = anon.get(f"/api/v1/hormonal-health/profile/{TEST_USER_ID}")
        assert response.status_code == 401


class TestHormonalProfileEndpoints:
    """Tests for hormonal profile CRUD operations."""

    def test_get_profile_not_found(self, client, mock_supabase):
        """Test getting profile when none exists."""
        response = client.get(f"/api/v1/hormonal-health/profile/{TEST_USER_ID}")
        assert response.status_code == 200
        assert response.json() is None

    def test_get_profile_success(self, client, mock_supabase):
        """Test getting existing profile."""
        mock_supabase.seed("hormonal_profiles", [
            _full_profile(
                gender="female",
                hormone_goals=["balance_estrogen", "pcos_management"],
                menstrual_tracking_enabled=True,
                cycle_length_days=28,
            )
        ])

        response = client.get(f"/api/v1/hormonal-health/profile/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == TEST_USER_ID
        assert "balance_estrogen" in data["hormone_goals"]

    def test_upsert_profile_create(self, client, mock_supabase):
        """Test creating a new profile."""
        # No existing profile seeded -> the handler must INSERT.
        profile_data = {
            "gender": "male",
            "hormone_goals": ["optimize_testosterone"],
            "testosterone_optimization_enabled": True,
        }

        response = client.put(f"/api/v1/hormonal-health/profile/{TEST_USER_ID}", json=profile_data)
        assert response.status_code == 200

        stored = mock_supabase.tables["hormonal_profiles"]
        assert len(stored) == 1
        assert stored[0]["gender"] == "male"
        assert stored[0]["hormone_goals"] == ["optimize_testosterone"]

    def test_upsert_profile_update(self, client, mock_supabase):
        """Test updating an existing profile."""
        mock_supabase.seed("hormonal_profiles", [
            _full_profile(hormone_goals=["balance_estrogen"])
        ])

        profile_data = {
            "hormone_goals": ["balance_estrogen", "menopause_support"],
        }

        response = client.put(f"/api/v1/hormonal-health/profile/{TEST_USER_ID}", json=profile_data)
        assert response.status_code == 200

        stored = mock_supabase.tables["hormonal_profiles"]
        assert len(stored) == 1  # updated in place, not duplicated
        assert stored[0]["hormone_goals"] == ["balance_estrogen", "menopause_support"]


class TestHormoneLogEndpoints:
    """Tests for hormone log CRUD operations."""

    def test_create_log(self, client, mock_supabase):
        """Test creating a hormone log."""
        log_data = {
            "log_date": "2025-01-01",
            "energy_level": 7,
            "mood": "good",
            "symptoms": ["fatigue"],
        }

        response = client.post(f"/api/v1/hormonal-health/logs/{TEST_USER_ID}", json=log_data)
        assert response.status_code == 200
        data = response.json()
        assert data["energy_level"] == 7

    def test_get_logs(self, client, mock_supabase):
        """Test getting hormone logs."""
        mock_supabase.seed("hormone_logs", [
            {
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "log_date": "2025-01-01",
                "energy_level": 7,
                "created_at": "2025-01-01T00:00:00Z",
            },
            {
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "log_date": "2024-12-31",
                "energy_level": 6,
                "created_at": "2024-12-31T00:00:00Z",
            },
        ])

        response = client.get(f"/api/v1/hormonal-health/logs/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_get_logs_with_date_filter(self, client, mock_supabase):
        """Test getting hormone logs with date filter."""
        mock_supabase.seed("hormone_logs", [
            {
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "log_date": "2025-01-01",
                "energy_level": 7,
                "created_at": "2025-01-01T00:00:00Z",
            },
            {   # outside the requested window — must be filtered out
                "id": str(uuid4()),
                "user_id": TEST_USER_ID,
                "log_date": "2024-12-20",
                "energy_level": 5,
                "created_at": "2024-12-20T00:00:00Z",
            },
        ])

        response = client.get(
            f"/api/v1/hormonal-health/logs/{TEST_USER_ID}",
            params={"start_date": "2025-01-01", "end_date": "2025-01-07"},
        )
        assert response.status_code == 200
        data = response.json()
        assert [log["log_date"] for log in data] == ["2025-01-01"]


class TestCyclePhaseEndpoints:
    """Tests for cycle phase calculations.

    The period history these tests seed now lives in the canonical
    `cycle_periods` table: GET /cycle-phase is served by
    `services.cycle.cycle_predictor.predict_for_user`, which reads
    `cycle_periods` (falling back to nothing when it is empty) instead of
    `hormonal_profiles.last_period_start_date`. The profile row is still seeded
    (it carries menstrual_tracking_enabled + cycle_length_days). The asserted
    phase/day values are unchanged from the original tests.
    """

    @staticmethod
    def _seed_cycle(mock_supabase, days_since_period_start: int, tracking: bool = True):
        last_period = (_server_today() - timedelta(days=days_since_period_start)).isoformat()
        mock_supabase.seed("hormonal_profiles", [
            _full_profile(
                menstrual_tracking_enabled=tracking,
                last_period_start_date=last_period,
                cycle_length_days=28,
            )
        ])
        mock_supabase.seed("cycle_periods", [
            {"user_id": TEST_USER_ID, "start_date": last_period, "end_date": None}
        ])

    def test_get_cycle_phase_not_tracking(self, client, mock_supabase):
        """Test cycle phase when tracking is disabled."""
        mock_supabase.seed("hormonal_profiles", [
            _full_profile(menstrual_tracking_enabled=False)
        ])

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["menstrual_tracking_enabled"] is False

    def test_get_cycle_phase_menstrual(self, client, mock_supabase):
        """Test cycle phase calculation - menstrual phase."""
        # Day 3 should be menstrual phase
        self._seed_cycle(mock_supabase, days_since_period_start=2)

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["current_phase"] == "menstrual"
        assert data["current_cycle_day"] == 3

    def test_get_cycle_phase_follicular(self, client, mock_supabase):
        """Test cycle phase calculation - follicular phase."""
        # Day 10 should be follicular phase
        self._seed_cycle(mock_supabase, days_since_period_start=9)

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["current_phase"] == "follicular"

    def test_get_cycle_phase_ovulation(self, client, mock_supabase):
        """Test cycle phase calculation - ovulation phase."""
        # Day 15 should be ovulation phase
        self._seed_cycle(mock_supabase, days_since_period_start=14)

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["current_phase"] == "ovulation"

    def test_get_cycle_phase_luteal(self, client, mock_supabase):
        """Test cycle phase calculation - luteal phase."""
        # Day 20 should be luteal phase
        self._seed_cycle(mock_supabase, days_since_period_start=19)

        response = client.get(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}")
        assert response.status_code == 200
        data = response.json()
        assert data["current_phase"] == "luteal"

    def test_log_period_start(self, client, mock_supabase):
        """Test logging period start."""
        mock_supabase.seed("hormonal_profiles", [
            _full_profile(menstrual_tracking_enabled=True)
        ])

        response = client.post(f"/api/v1/hormonal-health/cycle-phase/{TEST_USER_ID}/log-period")
        assert response.status_code == 200

        today_iso = _server_today().isoformat()
        assert mock_supabase.tables["cycle_periods"][0]["start_date"] == today_iso
        assert (
            mock_supabase.tables["hormonal_profiles"][0]["last_period_start_date"]
            == today_iso
        )


class TestHormoneSupportiveFoodsEndpoints:
    """Tests for hormone-supportive foods endpoints."""

    def test_get_foods_all(self, client, mock_supabase):
        """Test getting all hormone-supportive foods."""
        mock_supabase.seed("hormone_supportive_foods", [
            _full_food(
                "Oysters",
                category="seafood",
                supports_testosterone=True,
                key_nutrients=["zinc", "vitamin_d"],
            ),
            _full_food(
                "Flaxseeds",
                category="seed",
                supports_estrogen_balance=True,
                key_nutrients=["lignans", "omega3"],
            ),
        ])

        response = client.get("/api/v1/hormonal-health/foods")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_get_foods_filtered_by_goal(self, client, mock_supabase):
        """Test getting foods filtered by hormone goal."""
        mock_supabase.seed("hormone_supportive_foods", [
            _full_food(
                "Oysters",
                category="seafood",
                supports_testosterone=True,
                key_nutrients=["zinc"],
            ),
            _full_food(  # must NOT come back for a testosterone goal
                "Flaxseeds",
                category="seed",
                supports_estrogen_balance=True,
                key_nutrients=["lignans"],
            ),
        ])

        response = client.get(
            "/api/v1/hormonal-health/foods",
            params={"goal": "optimize_testosterone"},
        )
        assert response.status_code == 200
        assert [food["name"] for food in response.json()] == ["Oysters"]


class TestHormonalInsightsEndpoint:
    """Tests for comprehensive insights endpoint."""

    def test_get_insights(self, client, mock_supabase):
        """Test getting comprehensive hormonal insights."""
        mock_supabase.seed("hormonal_profiles", [
            _full_profile(
                gender="male",
                hormone_goals=["optimize_testosterone"],
                menstrual_tracking_enabled=False,
            )
        ])
        # No logs, no foods — the empty-data path.

        response = client.get(f"/api/v1/hormonal-health/insights/{TEST_USER_ID}")
        assert response.status_code == 200
