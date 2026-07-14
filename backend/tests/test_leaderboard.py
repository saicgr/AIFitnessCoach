"""
Tests for leaderboard API endpoints.

Run with: pytest backend/tests/test_leaderboard.py -v
"""

import pytest
from fastapi.testclient import TestClient
from datetime import datetime, timezone
from uuid import uuid4

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from core.auth import get_current_user
from models.leaderboard import LeaderboardType, LeaderboardFilter
from services.leaderboard_service import LeaderboardService

# Mock test data
MOCK_USER_ID = str(uuid4())
MOCK_FRIEND_ID = str(uuid4())
MOCK_STRANGER_ID = str(uuid4())
# A user who has only completed 3 workouts — below the 10-workout gate that
# unlocks the global/country boards.
MOCK_NEW_USER_ID = str(uuid4())


class TestLeaderboardEndpoints:
    """Test leaderboard API endpoints."""

    def test_get_global_leaderboard_unlocked(self, client, auth_headers):
        """Test getting global leaderboard when unlocked."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&leaderboard_type=challenge_masters&filter_type=global",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert "entries" in data
        assert "total_entries" in data
        assert "user_rank" in data
        assert data["leaderboard_type"] == "challenge_masters"
        assert data["filter_type"] == "global"

    def test_get_global_leaderboard_locked(self, client, new_user_auth_headers):
        """Test getting global leaderboard when locked (< 10 workouts).

        NOTE: the endpoint resolves *whose* unlock state to check from the
        `user_id` QUERY PARAMETER, not from the bearer token, so the new user's
        id is what has to be sent here (the original test sent MOCK_USER_ID —
        the unlocked user — with a new-user token, which the handler never
        looks at, so it could never have produced a 403).
        """
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_NEW_USER_ID}&leaderboard_type=challenge_masters&filter_type=global",
            headers=new_user_auth_headers,
        )

        # Should return 403 Forbidden
        assert response.status_code == 403
        assert "workouts" in response.json()["detail"].lower()

    def test_get_friends_leaderboard(self, client, auth_headers):
        """Test getting friends-only leaderboard (always accessible)."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&leaderboard_type=challenge_masters&filter_type=friends",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert data["filter_type"] == "friends"
        # All entries should be friends
        for entry in data["entries"]:
            assert entry["is_friend"] is True

    def test_get_country_leaderboard(self, client, auth_headers):
        """Test getting country-specific leaderboard."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&leaderboard_type=challenge_masters&filter_type=country&country_code=US",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert data["filter_type"] == "country"
        assert data["country_code"] == "US"

        # All entries should be from US
        for entry in data["entries"]:
            assert entry["country_code"] == "US"

    def test_get_country_leaderboard_missing_code(self, client, auth_headers):
        """Test getting country leaderboard without country_code."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&leaderboard_type=challenge_masters&filter_type=country",
            headers=auth_headers,
        )

        # Should return 400 Bad Request
        assert response.status_code == 400
        assert "country_code required" in response.json()["detail"]

    def test_get_volume_kings_leaderboard(self, client, auth_headers):
        """Test getting Volume Kings leaderboard."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&leaderboard_type=volume_kings&filter_type=global",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert data["leaderboard_type"] == "volume_kings"

        # Entries should have volume stats
        if data["entries"]:
            entry = data["entries"][0]
            assert "total_volume_lbs" in entry
            assert "total_workouts" in entry
            assert "avg_volume_per_workout" in entry

    def test_get_streaks_leaderboard(self, client, auth_headers):
        """Test getting Streaks leaderboard."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&leaderboard_type=streaks&filter_type=global",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert data["leaderboard_type"] == "streaks"

        # Entries should have streak stats
        if data["entries"]:
            entry = data["entries"][0]
            assert "current_streak" in entry
            assert "best_streak" in entry

    def test_get_weekly_leaderboard(self, client, auth_headers):
        """Test getting weekly challenges leaderboard."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&leaderboard_type=weekly_challenges&filter_type=global",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert data["leaderboard_type"] == "weekly_challenges"

        # Entries should have weekly stats
        if data["entries"]:
            entry = data["entries"][0]
            assert "weekly_wins" in entry
            assert "weekly_completed" in entry
            assert "weekly_win_rate" in entry

    def test_leaderboard_pagination(self, client, auth_headers):
        """Test leaderboard pagination."""
        # Get first page
        response1 = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&limit=10&offset=0",
            headers=auth_headers,
        )

        assert response1.status_code == 200
        data1 = response1.json()

        # Get second page
        response2 = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&limit=10&offset=10",
            headers=auth_headers,
        )

        assert response2.status_code == 200
        data2 = response2.json()

        # Entries should be different
        if data1["entries"] and data2["entries"]:
            assert data1["entries"][0]["user_id"] != data2["entries"][0]["user_id"]

        # Check has_more flag
        assert isinstance(data1["has_more"], bool)

    def test_get_user_rank(self, client, auth_headers):
        """Test getting user's rank in leaderboard."""
        response = client.get(
            f"/api/v1/leaderboard/rank?user_id={MOCK_USER_ID}&leaderboard_type=challenge_masters",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert "rank" in data
        assert "total_users" in data
        assert "percentile" in data
        assert "user_stats" in data

        assert data["user_id"] == MOCK_USER_ID
        assert data["rank"] > 0
        assert data["total_users"] > 0
        assert 0 <= data["percentile"] <= 100

    def test_get_user_rank_with_country_filter(self, client, auth_headers):
        """Test getting user's rank with country filter."""
        response = client.get(
            f"/api/v1/leaderboard/rank?user_id={MOCK_USER_ID}&leaderboard_type=challenge_masters&country_filter=US",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert "rank" in data
        # Rank should be different than global (usually lower number)

    def test_get_unlock_status_unlocked(self, client, auth_headers):
        """Test getting unlock status for unlocked user."""
        response = client.get(
            f"/api/v1/leaderboard/unlock-status?user_id={MOCK_USER_ID}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert "is_unlocked" in data
        assert "workouts_completed" in data
        assert "workouts_needed" in data
        assert "unlock_message" in data
        assert "progress_percentage" in data

        if data["is_unlocked"]:
            assert data["workouts_needed"] == 0
            assert data["progress_percentage"] == 100

    def test_get_unlock_status_locked(self, client, new_user_auth_headers):
        """Test getting unlock status for locked user (< 10 workouts).

        As in test_get_global_leaderboard_locked, the endpoint reads the
        `user_id` query parameter (not the token) to decide whose unlock state to
        report, so the locked user's id has to be the one sent.
        """
        response = client.get(
            f"/api/v1/leaderboard/unlock-status?user_id={MOCK_NEW_USER_ID}",
            headers=new_user_auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        if not data["is_unlocked"]:
            assert data["workouts_needed"] > 0
            assert data["progress_percentage"] < 100
            assert "Complete" in data["unlock_message"]

    def test_get_leaderboard_stats(self, client, auth_headers):
        """Test getting overall leaderboard statistics."""
        response = client.get(
            "/api/v1/leaderboard/stats",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        assert "total_users" in data
        assert "total_countries" in data
        assert "average_wins" in data
        assert "highest_streak" in data
        assert "total_volume_lifted" in data

        assert data["total_users"] >= 0
        assert data["total_countries"] >= 0
        assert data["average_wins"] >= 0
        assert data["highest_streak"] >= 0
        assert data["total_volume_lifted"] >= 0

    def test_create_async_challenge_with_workout_id(self, client, auth_headers):
        """Test creating async 'Beat Their Best' challenge with specific workout."""
        mock_workout_id = str(uuid4())

        response = client.post(
            f"/api/v1/leaderboard/async-challenge?user_id={MOCK_USER_ID}",
            headers=auth_headers,
            json={
                "target_user_id": MOCK_STRANGER_ID,
                "workout_log_id": mock_workout_id,
                "challenge_message": "I'm coming for your record! 💪",
            },
        )

        assert response.status_code in [200, 404]  # 404 if mock workout doesn't exist

        if response.status_code == 200:
            data = response.json()

            assert data["challenge_created"] is True
            assert data["notification_sent"] is False  # Async, no notification yet
            assert "target_user_name" in data
            assert "workout_name" in data
            assert "target_stats" in data

    def test_create_async_challenge_auto_best(self, client, auth_headers):
        """Test creating async challenge without workout_id (auto-find best)."""
        response = client.post(
            f"/api/v1/leaderboard/async-challenge?user_id={MOCK_USER_ID}",
            headers=auth_headers,
            json={
                "target_user_id": MOCK_STRANGER_ID,
                "challenge_message": "Beat your best!",
            },
        )

        assert response.status_code in [200, 404]  # 404 if no workouts found

        if response.status_code == 200:
            data = response.json()
            assert data["challenge_created"] is True

    def test_create_async_challenge_user_not_found(self, client, auth_headers):
        """Test creating async challenge for non-existent user."""
        fake_user_id = str(uuid4())

        response = client.post(
            f"/api/v1/leaderboard/async-challenge?user_id={MOCK_USER_ID}",
            headers=auth_headers,
            json={
                "target_user_id": fake_user_id,
            },
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_leaderboard_entry_flags(self, client, auth_headers):
        """Test is_friend and is_current_user flags in leaderboard entries."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&filter_type=global",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        for entry in data["entries"]:
            assert "is_friend" in entry
            assert "is_current_user" in entry

            # Current user should be marked
            if entry["user_id"] == MOCK_USER_ID:
                assert entry["is_current_user"] is True

    def test_leaderboard_rank_ordering(self, client, auth_headers):
        """Test that leaderboard is properly ordered by rank."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&limit=100",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()

        # Check ranks are sequential
        for i, entry in enumerate(data["entries"]):
            expected_rank = i + 1
            assert entry["rank"] == expected_rank

        # Check ordering (first_wins should be descending)
        if len(data["entries"]) > 1:
            for i in range(len(data["entries"]) - 1):
                current_wins = data["entries"][i].get("first_wins", 0)
                next_wins = data["entries"][i + 1].get("first_wins", 0)
                assert current_wins >= next_wins  # Should be descending


class TestLeaderboardDataIntegrity:
    """Test leaderboard data integrity and calculations."""

    def test_first_wins_excludes_retries(self, client, db_connection):
        """Test that leaderboard only counts first-attempt wins."""
        # This test would check database directly to ensure
        # is_retry = false challenges are counted
        # This is a placeholder - requires actual DB connection

        # Query leaderboard view
        # SELECT first_wins FROM leaderboard_challenge_masters WHERE user_id = ?

        # Verify first_wins matches:
        # SELECT COUNT(*) FROM workout_challenges
        # WHERE did_beat = true AND is_retry = false AND to_user_id = ?

        pass  # Implement with actual DB connection

    def test_country_filter_accuracy(self, client, db_connection):
        """Test that country filter only returns users from that country."""
        # Query country leaderboard
        # Verify all entries have matching country_code

        pass  # Implement with actual DB connection

    def test_weekly_leaderboard_resets(self, client, db_connection):
        """Test that weekly leaderboard only counts current week."""
        # Query weekly leaderboard
        # Verify only challenges from DATE_TRUNC('week', NOW()) are counted

        pass  # Implement with actual DB connection


# ============================================================
# FIXTURES
# ============================================================

def _make_rows():
    """Build a deterministic set of leaderboard view rows.

    Column set is the union of the four leaderboard views
    (`leaderboard_challenge_masters`, `_volume_kings`, `_streaks`,
    `_weekly_challenges`) — the API's `_build_leaderboard_entry()` reads a
    different subset per leaderboard_type, so every row carries all of them.
    `first_wins` (the challenge_masters order column) is strictly descending by
    construction, and MOCK_USER_ID / MOCK_FRIEND_ID / MOCK_STRANGER_ID all sit
    on the board.
    """
    now = datetime.now(timezone.utc).isoformat()
    fixed_ids = [MOCK_USER_ID, MOCK_FRIEND_ID, MOCK_STRANGER_ID]
    rows = []
    for i in range(12):
        user_id = fixed_ids[i] if i < len(fixed_ids) else str(uuid4())
        rows.append({
            "user_id": user_id,
            "user_name": f"Athlete {i}",
            "avatar_url": None,
            "country_code": "US" if i % 2 == 0 else "CA",
            # challenge_masters
            "first_wins": 100 - (i * 5),
            "win_rate": 0.9 - (i * 0.01),
            "total_completed": 200 - i,
            # volume_kings
            "total_volume_lbs": 500000.0 - (i * 1000),
            "total_workouts": 300 - i,
            "avg_volume_per_workout": 1600.0 - i,
            # streaks
            "current_streak": 30 - i,
            "best_streak": 60 - i,
            # LeaderboardEntry types this as a datetime, so the double supplies
            # a full timestamp rather than a bare date.
            "last_workout_date": now,
            # weekly_challenges
            "weekly_wins": 12 - i,
            "weekly_completed": 14 - i,
            "weekly_win_rate": 0.85 - (i * 0.01),
            "last_updated": now,
        })
    return rows


class FakeLeaderboardService:
    """In-memory stand-in for `LeaderboardService`.

    Mirrors the real service's contract exactly — same method names, same
    argument names, same return shapes (see services/leaderboard_service.py) —
    but reads from a fixed row set instead of Supabase views/RPCs. Ordering and
    paging reuse the production `ORDER_COLUMNS` map so the double cannot drift
    from the real ordering rules.

    Unlock state is keyed on `user_id`, exactly as the real
    `check_unlock_status` is: MOCK_USER_ID has 25 completed workouts (unlocked),
    MOCK_NEW_USER_ID has 3 (still locked out of global/country).
    """

    WORKOUTS_COMPLETED = {}  # filled in __init__

    def __init__(self):
        self.rows = _make_rows()
        self.friend_ids = [MOCK_FRIEND_ID]
        self.workouts_completed = {
            MOCK_USER_ID: 25,
            MOCK_FRIEND_ID: 40,
            MOCK_STRANGER_ID: 15,
            MOCK_NEW_USER_ID: 3,
        }
        self.known_user_ids = {r["user_id"] for r in self.rows}

    # --- unlock -------------------------------------------------------
    def check_unlock_status(self, user_id: str, scope: str = "global"):
        completed = self.workouts_completed.get(user_id, 0)
        threshold = 1 if scope == "friends" else 10
        return {
            "is_unlocked": completed >= threshold,
            "workouts_completed": completed,
            "workouts_needed": max(threshold - completed, 0),
            "threshold": threshold,
            "days_active": 0,
        }

    # --- board --------------------------------------------------------
    def _ordered_rows(self, leaderboard_type, filter_type=None, user_id=None,
                      country_code=None):
        if filter_type == LeaderboardFilter.friends:
            rows = [r for r in self.rows if r["user_id"] in self.friend_ids]
        elif filter_type == LeaderboardFilter.country:
            rows = [r for r in self.rows if r["country_code"] == country_code]
        else:
            rows = list(self.rows)
        order_column = LeaderboardService.ORDER_COLUMNS[leaderboard_type]
        return sorted(rows, key=lambda r: r[order_column], reverse=True)

    def get_leaderboard_entries(self, leaderboard_type, filter_type, user_id,
                                country_code=None, limit=100, offset=0):
        rows = self._ordered_rows(leaderboard_type, filter_type, user_id, country_code)
        return {"entries": rows[offset:offset + limit], "total": len(rows)}

    def _get_friend_ids(self, user_id: str):
        return list(self.friend_ids)

    def get_strength_scores_for_users(self, user_ids):
        return {user_id: 750 for user_id in user_ids}

    def get_user_rank(self, user_id, leaderboard_type, country_filter=None):
        rows = self._ordered_rows(
            leaderboard_type,
            LeaderboardFilter.country if country_filter else LeaderboardFilter.global_lb,
            user_id,
            country_filter,
        )
        for idx, row in enumerate(rows):
            if row["user_id"] == user_id:
                rank = idx + 1
                total = len(rows)
                percentile = round((1 - (rank - 1) / total) * 100, 1)
                return {
                    "rank_info": {
                        "rank": rank,
                        "total_users": total,
                        "percentile": percentile,
                    },
                    "stats": row,
                }
        return None

    # --- stats --------------------------------------------------------
    def get_leaderboard_stats(self):
        total_users = len(self.rows)
        countries = {r["country_code"] for r in self.rows if r.get("country_code")}
        total_wins = sum(r["first_wins"] for r in self.rows)
        return {
            "total_users": total_users,
            "total_countries": len(countries),
            "top_country": "US",
            "average_wins": round(total_wins / total_users, 1),
            "highest_streak": max(r["best_streak"] for r in self.rows),
            "total_volume_lifted": round(sum(r["total_volume_lbs"] for r in self.rows), 0),
        }

    # --- async challenge ----------------------------------------------
    def create_async_challenge(self, user_id, target_user_id, workout_log_id=None,
                               challenge_message="I'm coming for your record! 💪"):
        # Real service raises ValueError when the target user (or their
        # workouts) can't be found; the endpoint turns that into a 404.
        if target_user_id not in self.known_user_ids:
            raise ValueError("Target user not found")
        return {
            "challenge_id": str(uuid4()),
            "target_user_name": "Athlete 2",
            "workout_name": "Their Best Workout",
            "target_stats": {
                "duration_minutes": 45,
                "total_volume": 12000,
                "exercises_count": 6,
            },
        }


@pytest.fixture
def leaderboard_service(monkeypatch):
    """Swap the module-level service singleton for the in-memory double.

    `api.v1.leaderboard` builds `leaderboard_service = LeaderboardService()` at
    import time and every handler calls that object, so patching the attribute on
    the API module is what routes the endpoints at the fake.
    """
    fake = FakeLeaderboardService()
    monkeypatch.setattr("api.v1.leaderboard.leaderboard_service", fake)
    return fake


@pytest.fixture
def client(leaderboard_service):
    """FastAPI test client with the auth dependency satisfied.

    Every leaderboard endpoint is behind `Depends(get_current_user)`, which
    validates a real Supabase JWT — these are endpoint-behaviour tests, not auth
    tests, so the dependency is overridden with a fixed identity. Note the
    handlers read the *user_id query parameter*, not the token, to decide whose
    board/unlock-state to serve (see NOTE in test_get_global_leaderboard_locked).
    """
    app.dependency_overrides[get_current_user] = lambda: {
        "id": MOCK_USER_ID,
        "email": "test@example.com",
    }
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def auth_headers():
    """Authentication headers for the unlocked user (25 completed workouts)."""
    return {
        "Authorization": "Bearer mock_token",
    }


@pytest.fixture
def new_user_auth_headers():
    """Authentication headers for a new user (3 completed workouts, < 10)."""
    return {
        "Authorization": "Bearer mock_new_user_token",
    }


@pytest.fixture
def db_connection():
    """Database connection for integration tests."""
    # return get_db_connection()
    pass  # Implement with actual DB connection


# ============================================================
# RUN TESTS
# ============================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
