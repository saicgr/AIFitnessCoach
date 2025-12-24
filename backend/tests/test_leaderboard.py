"""
Tests for leaderboard API endpoints.

Run with: pytest backend/tests/test_leaderboard.py -v
"""

import pytest
from fastapi.testclient import TestClient
from datetime import datetime, timezone
from uuid import uuid4

# Import your FastAPI app
# from main import app
# client = TestClient(app)

# Mock test data
MOCK_USER_ID = str(uuid4())
MOCK_FRIEND_ID = str(uuid4())
MOCK_STRANGER_ID = str(uuid4())


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
        """Test getting global leaderboard when locked (< 10 workouts)."""
        response = client.get(
            f"/api/v1/leaderboard/?user_id={MOCK_USER_ID}&leaderboard_type=challenge_masters&filter_type=global",
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
        """Test getting unlock status for locked user (< 10 workouts)."""
        response = client.get(
            f"/api/v1/leaderboard/unlock-status?user_id={MOCK_USER_ID}",
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

@pytest.fixture
def client():
    """FastAPI test client."""
    # from main import app
    # return TestClient(app)
    pass  # Implement with actual app import


@pytest.fixture
def auth_headers():
    """Mock authentication headers for unlocked user."""
    return {
        "Authorization": "Bearer mock_token",
    }


@pytest.fixture
def new_user_auth_headers():
    """Mock authentication headers for new user (< 10 workouts)."""
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
