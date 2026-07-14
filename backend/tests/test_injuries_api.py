"""
Tests for Injuries API endpoints.

This module tests:
1. Report injury endpoint
2. List injuries endpoint (with filters)
3. Get injury details
4. Update injury
5. Mark as healed
6. Check-in endpoints
7. Rehab exercises endpoints
8. Workout modifications endpoint

--- 2026-07 repair notes (why these tests changed) -----------------------------
Every request in this file used to be routed at a URL shape the router has never
served (`POST /injuries/{user_id}`, `PUT /injuries/{user_id}/{injury_id}`,
`POST .../heal`, ...), and none of them sent auth. The suite "passed" only
because each assertion accepted 404 — i.e. "route not found" satisfied the
test. The 15 that failed did so with 405/401, which is what finally exposed it.

The real contract, from `backend/api/v1/injuries.py` (all of it behind
`Depends(get_current_user)`):

    GET    /api/v1/injuries/{user_id}                        list (status filter)
    GET    /api/v1/injuries/{user_id}/active                 active + recovering
    POST   /api/v1/injuries/{user_id}/report                 report an injury
    GET    /api/v1/injuries/detail/{injury_id}               injury + check-ins + rehab
    PUT    /api/v1/injuries/{injury_id}                      update injury
    DELETE /api/v1/injuries/{injury_id}                      mark healed
    POST   /api/v1/injuries/{injury_id}/check-in             add recovery check-in
    GET    /api/v1/injuries/{user_id}/workout-modifications  modifications

So the fixes here are all "the test was calling it wrong": correct URLs, a real
authenticated caller, and `api.v1.injuries.get_supabase` as the patch target
(the router imports `get_supabase` from `core.supabase_client`; the old target,
`core.supabase_db.get_supabase_db`, is a different module the router never
touches, so the mocks were never wired to anything). With the calls corrected
the endpoints actually execute, so the assertions now check real payloads
instead of a permissive status-code set.

Two intents in the original file have no endpoint to test against at all —
assigning a rehab exercise and marking one complete. Those tests are left
exactly as they were (see TestAddRehabExercise / TestCompleteRehabExercise) and
are reported as an open question rather than silently rewritten.
"""
import pytest
from datetime import date, timedelta, datetime, timezone
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


MOCK_USER_ID = "test-user-injury-123"
MOCK_INJURY_ID = "test-injury-456"
MOCK_UPDATE_ID = "test-update-789"
MOCK_REHAB_ID = "test-rehab-101"

# Every chained PostgREST builder method the injuries router uses.
_CHAIN_METHODS = (
    "select", "insert", "update", "delete", "upsert",
    "eq", "neq", "in_", "is_", "gte", "lte",
    "order", "range", "limit", "single", "maybe_single",
)


def db_result(data, count=None):
    """A stand-in for a PostgREST APIResponse (`.data` + `.count`)."""
    result = MagicMock()
    result.data = data
    if count is None:
        count = len(data) if isinstance(data, list) else 0
    result.count = count
    return result


def table_mock(results):
    """Chainable table mock.

    `results` is a single db_result (returned for every execute()) or a list of
    db_results returned in call order — the router queries some tables more than
    once per request (e.g. select-then-update).
    """
    table = MagicMock()
    for method in _CHAIN_METHODS:
        getattr(table, method).return_value = table
    if isinstance(results, list):
        table.execute.side_effect = results
    else:
        table.execute.return_value = results
    return table


class FakeSupabase:
    """Mimics the object `core.supabase_client.get_supabase()` returns.

    The router only ever touches `.client.table(<name>)`, so a per-table
    registry is enough — and it keeps multi-table endpoints (injury detail hits
    user_injuries + injury_updates + injury_rehab_exercises) honest, instead of
    handing the same canned rows back for every table.
    """

    def __init__(self):
        self._tables = {}
        self.client = MagicMock()
        self.client.table.side_effect = self.table

    def set_table(self, name, results):
        self._tables[name] = table_mock(results)
        return self._tables[name]

    def table(self, name):
        if name not in self._tables:
            self._tables[name] = table_mock(db_result([]))
        return self._tables[name]


@pytest.fixture
def supabase():
    """Patch the injuries router's Supabase accessor with a FakeSupabase."""
    fake = FakeSupabase()
    with patch("api.v1.injuries.get_supabase", return_value=fake):
        yield fake


@pytest.fixture(autouse=True)
def no_workout_invalidation():
    """Stub the workout-invalidation side effect.

    `report_injury` / `update_injury` / `mark_injury_healed` call
    `invalidate_workouts_after_injury_change`, which builds its OWN Supabase
    client (not the one the router holds) and would fire live HTTP at production
    Postgres from a unit test. It is a collaborator here, tested on its own; the
    contract these tests care about is only that the endpoints call it.
    """
    with patch(
        "api.v1.workouts.utils.invalidate_workouts_after_injury_change",
        return_value={"today_deleted": 0, "upcoming_deleted": 0},
    ) as mock_invalidate:
        yield mock_invalidate


@pytest.fixture
def client():
    """Authenticated test client.

    Every injuries endpoint is behind `Depends(get_current_user)`, so an
    unauthenticated TestClient gets a 401 before the handler ever runs — that
    was the single biggest cause of failures in this file. Overriding the
    dependency gives the tests a signed-in caller.
    """
    from main import app
    from core.auth import get_current_user

    app.dependency_overrides[get_current_user] = lambda: {
        "id": MOCK_USER_ID,
        "email": "injury-tests@example.com",
    }
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


def generate_mock_injury(
    body_part: str = "knee",
    injury_type: str = "strain",
    severity: str = "moderate",
    status: str = "active",
    recovery_phase: str = "acute",
):
    """Generate a mock injury record."""
    return {
        "id": MOCK_INJURY_ID,
        "user_id": MOCK_USER_ID,
        "body_part": body_part,
        "injury_type": injury_type,
        "severity": severity,
        "reported_at": datetime.now(timezone.utc).isoformat(),
        "occurred_at": date.today().isoformat(),
        "expected_recovery_date": (date.today() + timedelta(days=14)).isoformat(),
        "actual_recovery_date": None,
        "recovery_phase": recovery_phase,
        "pain_level": 5,
        "affects_exercises": ["Squats", "Lunges", "Leg Press"],
        "affects_muscles": ["quadriceps", "hamstrings"],
        "notes": "Tweaked during heavy squat session",
        "activity_when_occurred": "Barbell Squat",
        "reported_via": "app",
        "status": status,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


def generate_mock_injury_update(
    pain_level: int = 4,
    mobility_rating: int = 3,
    recovery_phase: str = "subacute",
):
    """Generate a mock injury update/check-in record."""
    return {
        "id": MOCK_UPDATE_ID,
        "injury_id": MOCK_INJURY_ID,
        "user_id": MOCK_USER_ID,
        "pain_level": pain_level,
        "mobility_rating": mobility_rating,
        "recovery_phase": recovery_phase,
        "can_workout": True,
        "workout_modifications": "Avoid heavy leg exercises, light cardio ok",
        "notes": "Feeling better, less pain when walking",
        "checked_at": datetime.now(timezone.utc).isoformat(),
    }


def generate_mock_rehab_exercise(
    exercise_name: str = "Quad Stretch",
    exercise_type: str = "stretching",
):
    """Generate a mock rehab exercise record."""
    return {
        "id": MOCK_REHAB_ID,
        "injury_id": MOCK_INJURY_ID,
        "exercise_name": exercise_name,
        "exercise_type": exercise_type,
        "sets": 3,
        "reps": 10,
        "hold_seconds": 30,
        "frequency_per_day": 2,
        "notes": "Hold stretch gently, no bouncing",
        "assigned_at": datetime.now(timezone.utc).isoformat(),
        "completed_count": 5,
        "last_completed_at": datetime.now(timezone.utc).isoformat(),
    }


# =============================================================================
# Report Injury Tests
# =============================================================================

class TestReportInjury:
    """Tests for POST /injuries/{user_id}/report"""

    def test_report_injury_success(self, client, supabase, no_workout_invalidation):
        """Test successfully reporting an injury."""
        supabase.set_table("user_injuries", db_result([generate_mock_injury()]))

        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/report",
            json={
                "body_part": "knee",
                "injury_type": "strain",
                "severity": "moderate",
                "pain_level": 5,
                "notes": "Tweaked during heavy squat session",
                "activity_when_occurred": "Barbell Squat",
            }
        )

        assert response.status_code == 200
        body = response.json()
        assert body["success"] is True
        assert body["injury"]["body_part"] == "knee"
        assert body["injury"]["severity"] == "moderate"
        # Knee gets knee-specific rehab suggestions, not the generic fallback.
        assert "Wall Sits" in body["recommended_rehab_exercises"]

        # The row the endpoint persisted.
        inserted = supabase.table("user_injuries").insert.call_args[0][0]
        assert inserted["user_id"] == MOCK_USER_ID
        assert inserted["injury_type"] == "strain"
        assert inserted["pain_level"] == 5
        assert inserted["status"] == "active"
        assert inserted["recovery_phase"] == "acute"
        # Moderate injuries default to a 14-day expected recovery.
        expected = (datetime.utcnow() + timedelta(days=14)).date().isoformat()
        assert inserted["expected_recovery_date"] == expected

        # E3: reporting an injury must clear not-started future workouts so they
        # regenerate without the injured area.
        no_workout_invalidation.assert_called_once()
        assert no_workout_invalidation.call_args[0][0] == MOCK_USER_ID

    def test_report_injury_minimal_fields(self, client, supabase):
        """Test reporting injury with only required fields."""
        supabase.set_table(
            "user_injuries",
            db_result([generate_mock_injury(body_part="shoulder", injury_type=None, severity="mild")]),
        )

        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/report",
            json={
                "body_part": "shoulder",
                "severity": "mild",
            }
        )

        assert response.status_code == 200
        body = response.json()
        assert body["injury"]["body_part"] == "shoulder"
        assert body["injury"]["severity"] == "mild"
        assert "Pendulum Exercises" in body["recommended_rehab_exercises"]

        inserted = supabase.table("user_injuries").insert.call_args[0][0]
        # Optional fields are persisted as NULL, not dropped or defaulted.
        assert inserted["injury_type"] is None
        assert inserted["pain_level"] is None
        assert inserted["affects_exercises"] == []

    def test_report_injury_invalid_severity(self, client, supabase):
        """Test reporting injury with invalid severity."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/report",
            json={
                "body_part": "knee",
                "severity": "extreme",  # Invalid
            }
        )

        assert response.status_code == 422
        assert supabase.table("user_injuries").insert.called is False

    def test_report_injury_invalid_injury_type(self, client, supabase):
        """Test reporting injury with invalid injury type."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/report",
            json={
                "body_part": "knee",
                "severity": "moderate",
                "injury_type": "unknown_type",  # Invalid
            }
        )

        assert response.status_code == 422
        assert supabase.table("user_injuries").insert.called is False

    def test_report_injury_with_affected_exercises(self, client, supabase):
        """Test reporting injury with specific exercises to avoid."""
        supabase.set_table(
            "user_injuries",
            db_result([generate_mock_injury(body_part="lower_back", injury_type="overuse", severity="severe")]),
        )

        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/report",
            json={
                "body_part": "lower_back",
                "severity": "severe",
                "injury_type": "overuse",
                "affects_exercises": ["Deadlift", "Bent Over Row", "Good Morning"],
                "affects_muscles": ["lower_back", "erector_spinae"],
            }
        )

        assert response.status_code == 200

        inserted = supabase.table("user_injuries").insert.call_args[0][0]
        assert inserted["affects_exercises"] == ["Deadlift", "Bent Over Row", "Good Morning"]
        assert inserted["affects_muscles"] == ["lower_back", "erector_spinae"]
        assert inserted["severity"] == "severe"
        # Severe injuries get a 35-day expected recovery window.
        expected = (datetime.utcnow() + timedelta(days=35)).date().isoformat()
        assert inserted["expected_recovery_date"] == expected


# =============================================================================
# List Injuries Tests
# =============================================================================

class TestListInjuries:
    """Tests for GET /injuries/{user_id}"""

    def test_list_injuries_success(self, client, supabase):
        """Test listing all injuries for a user."""
        mock_data = [
            generate_mock_injury("knee", "strain", "moderate", "active"),
            generate_mock_injury("shoulder", "sprain", "mild", "recovering"),
        ]
        # Two queries: the page of rows, then a count-only query for active_count.
        table = supabase.set_table(
            "user_injuries",
            [db_result(mock_data), db_result([], count=2)],
        )

        response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}")

        assert response.status_code == 200
        body = response.json()
        assert body["count"] == 2
        assert body["active_count"] == 2
        assert [i["body_part"] for i in body["injuries"]] == ["knee", "shoulder"]
        assert ("user_id", MOCK_USER_ID) in [c.args for c in table.eq.call_args_list]

    def test_list_injuries_filter_by_status(self, client, supabase):
        """Test listing injuries filtered by status."""
        table = supabase.set_table(
            "user_injuries",
            [db_result([generate_mock_injury(status="active")]), db_result([], count=1)],
        )

        response = client.get(
            f"/api/v1/injuries/{MOCK_USER_ID}",
            params={"status": "active"}
        )

        assert response.status_code == 200
        body = response.json()
        assert body["count"] == 1
        assert body["injuries"][0]["status"] == "active"
        # The status filter must reach the query, not just be accepted.
        assert ("status", "active") in [c.args for c in table.eq.call_args_list]

    def test_list_injuries_filter_by_body_part(self, client, supabase):
        """Test that the list endpoint tolerates an unknown filter param.

        Originally asserted a server-side `body_part` filter. No such filter has
        ever existed on this endpoint: `get_user_injuries` accepts `status`,
        `limit` and `offset` only (git history has never carried a `body_part`
        Query param), and body-part narrowing is done by the caller over the
        returned list. Retired rather than deleted so the guarantee it can still
        protect is kept: an unrecognized query param is ignored, not a 422, and
        the list still comes back parsed. Whether a server-side body_part filter
        SHOULD exist is a product question, not a regression this test caught.
        """
        table = supabase.set_table(
            "user_injuries",
            [db_result([generate_mock_injury(body_part="knee")]), db_result([], count=1)],
        )

        response = client.get(
            f"/api/v1/injuries/{MOCK_USER_ID}",
            params={"body_part": "knee"}
        )

        assert response.status_code == 200
        body = response.json()
        assert body["count"] == 1
        assert body["injuries"][0]["body_part"] == "knee"
        # Not pushed into the query — the endpoint filters by user_id/status only.
        assert ("body_part", "knee") not in [c.args for c in table.eq.call_args_list]

    def test_list_injuries_empty(self, client, supabase):
        """Test listing injuries when user has none."""
        supabase.set_table(
            "user_injuries",
            [db_result([]), db_result([], count=0)],
        )

        response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}")

        assert response.status_code == 200
        body = response.json()
        assert body["injuries"] == []
        assert body["count"] == 0
        assert body["active_count"] == 0

    def test_list_active_injuries_only(self, client, supabase):
        """Test listing only active and recovering injuries.

        The original request (`GET /{user_id}?active_only=true`) had no such
        query param; the dedicated route is `GET /{user_id}/active`. Same intent,
        real endpoint.
        """
        mock_data = [
            generate_mock_injury(status="active"),
            generate_mock_injury(status="recovering"),
        ]
        table = supabase.set_table("user_injuries", db_result(mock_data))

        response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}/active")

        assert response.status_code == 200
        body = response.json()
        assert body["count"] == 2
        assert body["active_count"] == 2
        # "Active" means active OR recovering — a recovering injury still limits
        # training, so it must not be dropped.
        assert ("status", ["active", "recovering"]) in [c.args for c in table.in_.call_args_list]


# =============================================================================
# Get Injury Details Tests
# =============================================================================

class TestGetInjuryDetails:
    """Tests for GET /injuries/detail/{injury_id}"""

    def test_get_injury_details_success(self, client, supabase):
        """Test getting details of a specific injury."""
        supabase.set_table("user_injuries", db_result([generate_mock_injury()]))
        supabase.set_table("injury_updates", db_result([]))
        supabase.set_table("injury_rehab_exercises", db_result([]))

        response = client.get(f"/api/v1/injuries/detail/{MOCK_INJURY_ID}")

        assert response.status_code == 200
        body = response.json()
        assert body["id"] == MOCK_INJURY_ID
        assert body["body_part"] == "knee"
        assert body["days_since_reported"] == 0
        assert body["check_ins"] == []
        assert body["rehab_exercises"] == []

    def test_get_injury_details_not_found(self, client, supabase):
        """Test getting details of non-existent injury."""
        supabase.set_table("user_injuries", db_result([]))

        response = client.get("/api/v1/injuries/detail/nonexistent-id")

        assert response.status_code == 404


# =============================================================================
# Update Injury Tests
# =============================================================================

class TestUpdateInjury:
    """Tests for PUT /injuries/{injury_id}"""

    def test_update_injury_success(self, client, supabase):
        """Test updating an injury."""
        updated = generate_mock_injury(severity="mild", recovery_phase="recovery")
        updated["pain_level"] = 2
        table = supabase.set_table(
            "user_injuries",
            [db_result([generate_mock_injury()]), db_result([updated])],
        )

        response = client.put(
            f"/api/v1/injuries/{MOCK_INJURY_ID}",
            json={
                "recovery_phase": "recovery",
                "pain_level": 2,
                "notes": "Much better now, nearly healed",
            }
        )

        assert response.status_code == 200
        body = response.json()
        assert body["success"] is True
        assert body["injury"]["pain_level"] == 2
        assert body["injury"]["recovery_phase"] == "recovery"

        written = table.update.call_args[0][0]
        assert written["recovery_phase"] == "recovery"
        assert written["pain_level"] == 2
        assert written["notes"] == "Much better now, nearly healed"

    def test_update_injury_not_found(self, client, supabase):
        """Test updating non-existent injury."""
        table = supabase.set_table("user_injuries", db_result([]))

        response = client.put(
            "/api/v1/injuries/nonexistent-id",
            json={"pain_level": 1}
        )

        assert response.status_code == 404
        assert table.update.called is False

    def test_update_injury_add_affected_exercises(self, client, supabase):
        """Test updating injury to add affected exercises."""
        table = supabase.set_table(
            "user_injuries",
            [db_result([generate_mock_injury()]), db_result([generate_mock_injury()])],
        )

        response = client.put(
            f"/api/v1/injuries/{MOCK_INJURY_ID}",
            json={
                "affects_exercises": ["Squats", "Lunges", "Leg Press", "Step Ups"],
            }
        )

        assert response.status_code == 200
        written = table.update.call_args[0][0]
        assert written["affects_exercises"] == ["Squats", "Lunges", "Leg Press", "Step Ups"]
        # A partial update must not clobber fields the caller didn't send.
        assert "pain_level" not in written
        assert "status" not in written


# =============================================================================
# Mark as Healed Tests
# =============================================================================

class TestMarkAsHealed:
    """Tests for DELETE /injuries/{injury_id} (mark healed)"""

    def test_mark_as_healed_success(self, client, supabase):
        """Test marking an injury as healed.

        The original `POST /{user_id}/{injury_id}/heal` route never existed —
        healing is `DELETE /injuries/{injury_id}` (a soft close: it flips
        status/recovery_phase and stamps actual_recovery_date, it does not
        delete the row).
        """
        table = supabase.set_table(
            "user_injuries",
            [db_result([generate_mock_injury()]), db_result([generate_mock_injury(status="healed")])],
        )

        response = client.delete(f"/api/v1/injuries/{MOCK_INJURY_ID}")

        assert response.status_code == 200
        body = response.json()
        assert body["success"] is True
        assert body["injury_id"] == MOCK_INJURY_ID
        assert body["healed_at"] is not None

        written = table.update.call_args[0][0]
        assert written["status"] == "healed"
        assert written["recovery_phase"] == "healed"
        assert written["actual_recovery_date"] == datetime.utcnow().date().isoformat()

    def test_mark_as_healed_not_found(self, client, supabase):
        """Test marking non-existent injury as healed."""
        table = supabase.set_table("user_injuries", db_result([]))

        response = client.delete("/api/v1/injuries/nonexistent-id")

        assert response.status_code == 404
        assert table.update.called is False

    def test_mark_as_chronic(self, client, supabase):
        """Test marking an injury as chronic.

        There is no `/chronic` route; chronic is a status, set through the
        update endpoint. Unlike "healed", it must NOT stamp a recovery date —
        a chronic injury has not resolved.
        """
        table = supabase.set_table(
            "user_injuries",
            [db_result([generate_mock_injury()]), db_result([generate_mock_injury(status="chronic")])],
        )

        response = client.put(
            f"/api/v1/injuries/{MOCK_INJURY_ID}",
            json={"status": "chronic"}
        )

        assert response.status_code == 200
        assert response.json()["injury"]["status"] == "chronic"

        written = table.update.call_args[0][0]
        assert written["status"] == "chronic"
        assert "actual_recovery_date" not in written


# =============================================================================
# Check-In Tests
# =============================================================================

class TestInjuryCheckIn:
    """Tests for POST /injuries/{injury_id}/check-in"""

    def test_check_in_success(self, client, supabase):
        """Test successfully adding a check-in."""
        injuries = supabase.set_table(
            "user_injuries",
            [db_result([generate_mock_injury()]), db_result([generate_mock_injury()])],
        )
        supabase.set_table("injury_updates", db_result([generate_mock_injury_update()]))

        response = client.post(
            f"/api/v1/injuries/{MOCK_INJURY_ID}/check-in",
            json={
                "pain_level": 4,
                "mobility_rating": 3,
                "recovery_phase": "subacute",
                "can_workout": True,
                "notes": "Feeling better, less pain when walking",
            }
        )

        assert response.status_code == 200
        body = response.json()
        assert body["injury_id"] == MOCK_INJURY_ID
        assert body["pain_level"] == 4
        assert body["mobility_rating"] == 3
        assert body["recovery_phase"] == "subacute"
        assert body["can_workout"] is True

        # The check-in also rolls the latest pain level / phase onto the injury.
        rolled_up = injuries.update.call_args[0][0]
        assert rolled_up["pain_level"] == 4
        assert rolled_up["recovery_phase"] == "subacute"

    def test_check_in_minimal_fields(self, client, supabase):
        """Test check-in with minimal fields."""
        supabase.set_table(
            "user_injuries",
            [db_result([generate_mock_injury()]), db_result([generate_mock_injury()])],
        )
        updates = supabase.set_table(
            "injury_updates",
            db_result([generate_mock_injury_update(pain_level=3, mobility_rating=None, recovery_phase=None)]),
        )

        response = client.post(
            f"/api/v1/injuries/{MOCK_INJURY_ID}/check-in",
            json={"pain_level": 3}
        )

        assert response.status_code == 200
        body = response.json()
        assert body["pain_level"] == 3
        # can_workout defaults to True when the caller omits it.
        assert body["can_workout"] is True

        written = updates.insert.call_args[0][0]
        assert written["injury_id"] == MOCK_INJURY_ID
        assert written["user_id"] == MOCK_USER_ID
        assert written["recovery_phase"] is None

    def test_check_in_invalid_pain_level(self, client, supabase):
        """Test check-in with invalid pain level."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_INJURY_ID}/check-in",
            json={"pain_level": 15}  # Should be 0-10
        )

        assert response.status_code == 422
        assert supabase.table("injury_updates").insert.called is False


class TestGetCheckIns:
    """Tests for an injury's check-in history.

    There is no dedicated `GET .../check-ins` collection route — check-ins are
    served embedded in `GET /injuries/detail/{injury_id}` (InjuryWithDetails).
    Same intent (the recovery history is retrievable and ordered), real route.
    """

    def test_get_check_ins_success(self, client, supabase):
        """Test getting all check-ins for an injury."""
        mock_data = [
            generate_mock_injury_update(pain_level=6, recovery_phase="acute"),
            generate_mock_injury_update(pain_level=4, recovery_phase="subacute"),
            generate_mock_injury_update(pain_level=2, recovery_phase="recovery"),
        ]
        supabase.set_table("user_injuries", db_result([generate_mock_injury()]))
        updates = supabase.set_table("injury_updates", db_result(mock_data))
        supabase.set_table("injury_rehab_exercises", db_result([]))

        response = client.get(f"/api/v1/injuries/detail/{MOCK_INJURY_ID}")

        assert response.status_code == 200
        check_ins = response.json()["check_ins"]
        assert len(check_ins) == 3
        assert [c["pain_level"] for c in check_ins] == [6, 4, 2]
        assert [c["recovery_phase"] for c in check_ins] == ["acute", "subacute", "recovery"]
        # Newest first.
        assert updates.order.call_args.args == ("checked_at",)
        assert updates.order.call_args.kwargs == {"desc": True}

    def test_get_check_ins_empty(self, client, supabase):
        """Test getting check-ins when none exist."""
        supabase.set_table("user_injuries", db_result([generate_mock_injury()]))
        supabase.set_table("injury_updates", db_result([]))
        supabase.set_table("injury_rehab_exercises", db_result([]))

        response = client.get(f"/api/v1/injuries/detail/{MOCK_INJURY_ID}")

        assert response.status_code == 200
        assert response.json()["check_ins"] == []


# =============================================================================
# Rehab Exercises Tests
# =============================================================================

class TestGetRehabExercises:
    """Tests for an injury's assigned rehab exercises.

    Like check-ins, these are served embedded in
    `GET /injuries/detail/{injury_id}`, not from a separate collection route.
    """

    def test_get_rehab_exercises_success(self, client, supabase):
        """Test getting rehab exercises for an injury."""
        mock_data = [
            generate_mock_rehab_exercise("Quad Stretch", "stretching"),
            generate_mock_rehab_exercise("Leg Raise", "strengthening"),
            generate_mock_rehab_exercise("Wall Sit", "isometric"),
        ]
        supabase.set_table("user_injuries", db_result([generate_mock_injury()]))
        supabase.set_table("injury_updates", db_result([]))
        supabase.set_table("injury_rehab_exercises", db_result(mock_data))

        response = client.get(f"/api/v1/injuries/detail/{MOCK_INJURY_ID}")

        assert response.status_code == 200
        rehab = response.json()["rehab_exercises"]
        assert len(rehab) == 3
        assert [r["exercise_name"] for r in rehab] == ["Quad Stretch", "Leg Raise", "Wall Sit"]
        assert rehab[0]["sets"] == 3
        assert rehab[0]["reps"] == 10
        assert rehab[0]["hold_seconds"] == 30
        assert rehab[0]["frequency_per_day"] == 2

    def test_get_rehab_exercises_empty(self, client, supabase):
        """Test getting rehab exercises when none assigned."""
        supabase.set_table("user_injuries", db_result([generate_mock_injury()]))
        supabase.set_table("injury_updates", db_result([]))
        supabase.set_table("injury_rehab_exercises", db_result([]))

        response = client.get(f"/api/v1/injuries/detail/{MOCK_INJURY_ID}")

        assert response.status_code == 200
        assert response.json()["rehab_exercises"] == []


class TestAddRehabExercise:
    """Tests for POST /injuries/{user_id}/{injury_id}/rehab-exercises

    ⚠️ NO SUCH ENDPOINT EXISTS. The router reads `injury_rehab_exercises` (for
    the detail view) but exposes no way to assign one; the whole write side of
    rehab assignment is unimplemented. These two tests only pass because their
    assertions accept 404, i.e. they are satisfied by the route being absent.
    Left byte-for-byte as they were: writing them against the real API is
    impossible until the product decides whether rehab assignment is an API
    feature (see the report accompanying this change). Deleting or skipping them
    would hide the gap.
    """

    def test_add_rehab_exercise_success(self, client, supabase):
        """Test adding a rehab exercise."""
        supabase.set_table("injury_rehab_exercises", db_result([generate_mock_rehab_exercise()]))

        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/rehab-exercises",
            json={
                "exercise_name": "Quad Stretch",
                "exercise_type": "stretching",
                "sets": 3,
                "reps": 10,
                "hold_seconds": 30,
                "frequency_per_day": 2,
                "notes": "Hold stretch gently, no bouncing",
            }
        )

        assert response.status_code in [200, 201, 404, 422]

    def test_add_rehab_exercise_invalid_type(self, client, supabase):
        """Test adding rehab exercise with invalid type."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/rehab-exercises",
            json={
                "exercise_name": "Invalid Exercise",
                "exercise_type": "unknown_type",  # Invalid
            }
        )

        assert response.status_code in [404, 422]


class TestCompleteRehabExercise:
    """Tests for POST /injuries/{user_id}/{injury_id}/rehab-exercises/{exercise_id}/complete

    ⚠️ NO SUCH ENDPOINT EXISTS — same gap as TestAddRehabExercise. Left as-is.
    """

    def test_complete_rehab_exercise_success(self, client, supabase):
        """Test marking rehab exercise as completed."""
        supabase.set_table(
            "injury_rehab_exercises",
            db_result([{**generate_mock_rehab_exercise(), "completed_count": 6}]),
        )

        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/{MOCK_INJURY_ID}/rehab-exercises/{MOCK_REHAB_ID}/complete"
        )

        assert response.status_code in [200, 404]


# =============================================================================
# Workout Modifications Tests
# =============================================================================

class TestGetWorkoutModifications:
    """Tests for GET /injuries/{user_id}/workout-modifications"""

    def test_get_workout_modifications_success(self, client, supabase):
        """Test getting workout modifications based on active injuries."""
        supabase.set_table(
            "user_injuries",
            db_result([generate_mock_injury("knee", "strain", "moderate", "active")]),
        )

        response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}/workout-modifications")

        assert response.status_code == 200
        body = response.json()
        assert body["has_active_injuries"] is True
        assert body["active_injury_count"] == 1
        assert set(body["exercises_to_avoid"]) == {"Squats", "Lunges", "Leg Press"}
        assert set(body["muscles_to_limit"]) == {"quadriceps", "hamstrings"}
        # A moderate knee injury is not severe, so lower body stays available,
        # but cardio (impact on the knee) is pulled.
        assert body["can_do_upper_body"] is True
        assert body["can_do_lower_body"] is True
        assert body["can_do_cardio"] is False
        assert any(
            "knee" in rec.lower() for rec in body["general_recommendations"]
        )

    def test_get_workout_modifications_no_injuries(self, client, supabase):
        """Test workout modifications when no active injuries."""
        supabase.set_table("user_injuries", db_result([]))

        response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}/workout-modifications")

        assert response.status_code == 200
        body = response.json()
        assert body["has_active_injuries"] is False
        assert body["active_injury_count"] == 0
        assert body["exercises_to_avoid"] == []
        assert body["can_do_upper_body"] is True
        assert body["can_do_lower_body"] is True
        assert body["can_do_core"] is True
        assert body["can_do_cardio"] is True

    def test_get_exercises_to_avoid(self, client, supabase):
        """Test getting list of exercises to avoid.

        There is no `/exercises-to-avoid` route; the avoid-list is a field of
        the workout-modifications payload, which is what the generator reads.
        Same intent, real route.
        """
        knee = generate_mock_injury("knee", "strain", "moderate", "active")
        shoulder = generate_mock_injury("shoulder", "sprain", "mild", "recovering")
        shoulder["affects_exercises"] = ["Overhead Press", "Bench Press"]
        supabase.set_table("user_injuries", db_result([knee, shoulder]))

        response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}/workout-modifications")

        assert response.status_code == 200
        body = response.json()
        # Every affected exercise across ALL active injuries, deduped.
        assert set(body["exercises_to_avoid"]) == {
            "Squats", "Lunges", "Leg Press", "Overhead Press", "Bench Press",
        }
        assert body["active_injury_count"] == 2


# =============================================================================
# Error Reporting Tests
# =============================================================================

class TestInjuryErrorReporting:
    """Regression gate for a real bug this repair found.

    Every `except Exception as e:` handler in api/v1/injuries.py used to do:

        raise safe_internal_error(RuntimeError("DB insert returned no data"), "endpoint")

    — i.e. it threw away the caught exception and handed `safe_internal_error` a
    FABRICATED one. `safe_internal_error(e, context)` is what reports to Sentry
    (`error_class = type(e).__name__`, `pgrst_code = _extract_pgrst_code(e)`,
    `module = context`), so EVERY 500 out of the injuries router — including
    read paths that never insert anything — arrived as
    `RuntimeError: DB insert returned no data` with no PostgREST code and a
    module tag of "endpoint". A column-drift 42703 on the list endpoint and a
    timeout on workout-modifications were indistinguishable in triage.

    The handlers now pass the real `e` (and tag the module "injuries"). This
    test fails if anyone reintroduces a synthesized cause.
    """

    def test_500_reports_the_real_exception_to_sentry(self, client, supabase):
        from fastapi import HTTPException

        table = supabase.set_table("user_injuries", db_result([]))
        table.execute.side_effect = ValueError("column user_injuries.foo does not exist")

        captured = []

        def record(exc, context="", **extras):
            captured.append((exc, context))
            return HTTPException(status_code=500, detail="Internal server error")

        with patch("api.v1.injuries.safe_internal_error", side_effect=record):
            response = client.get(f"/api/v1/injuries/{MOCK_USER_ID}")

        assert response.status_code == 500
        assert len(captured) == 1
        reported, context = captured[0]
        assert isinstance(reported, ValueError)
        assert str(reported) == "column user_injuries.foo does not exist"
        assert context == "injuries"


# =============================================================================
# Validation Tests
# =============================================================================

class TestInjuryValidation:
    """Tests for injury request validation."""

    def test_invalid_pain_level_high(self, client, supabase):
        """Test that pain level above 10 is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/report",
            json={
                "body_part": "knee",
                "severity": "moderate",
                "pain_level": 15,
            }
        )

        assert response.status_code == 422
        assert supabase.table("user_injuries").insert.called is False

    def test_invalid_pain_level_negative(self, client, supabase):
        """Test that negative pain level is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/report",
            json={
                "body_part": "knee",
                "severity": "moderate",
                "pain_level": -1,
            }
        )

        assert response.status_code == 422
        assert supabase.table("user_injuries").insert.called is False

    def test_invalid_mobility_rating(self, client, supabase):
        """Test that invalid mobility rating is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_INJURY_ID}/check-in",
            json={
                "pain_level": 5,
                "mobility_rating": 10,  # Should be 1-5
            }
        )

        assert response.status_code == 422
        assert supabase.table("injury_updates").insert.called is False

    def test_empty_body_part(self, client, supabase):
        """Test that empty body part is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_USER_ID}/report",
            json={
                "body_part": "",
                "severity": "moderate",
            }
        )

        assert response.status_code == 422
        assert supabase.table("user_injuries").insert.called is False

    def test_invalid_recovery_phase(self, client, supabase):
        """Test that invalid recovery phase is rejected."""
        response = client.post(
            f"/api/v1/injuries/{MOCK_INJURY_ID}/check-in",
            json={
                "pain_level": 5,
                "recovery_phase": "unknown_phase",  # Invalid
            }
        )

        assert response.status_code == 422
        assert supabase.table("injury_updates").insert.called is False
