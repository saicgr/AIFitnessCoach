"""
Tests for Leaderboard API endpoints.

Tests:
- Get leaderboard data (global, country, friends)
- Get user rank
- Get unlock status
- Get leaderboard stats
- Create async challenges
- Helper functions

Run with: pytest backend/tests/test_leaderboard_api.py -v
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone, timedelta
import uuid

from main import app
from models.leaderboard import LeaderboardType, LeaderboardFilter


client = TestClient(app)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_leaderboard_service():
    """Mock LeaderboardService for testing."""
    with patch('api.v1.leaderboard.leaderboard_service') as mock:
        yield mock


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_leaderboard_entries():
    """Sample leaderboard entries."""
    return [
        {
            "user_id": str(uuid.uuid4()),
            "user_name": "Champion User",
            "avatar_url": "https://example.com/avatar1.jpg",
            "country_code": "US",
            "first_wins": 50,
            "win_rate": 85.5,
            "total_completed": 60,
            "last_updated": datetime.now(timezone.utc).isoformat(),
        },
        {
            "user_id": str(uuid.uuid4()),
            "user_name": "Runner Up",
            "avatar_url": None,
            "country_code": "GB",
            "first_wins": 45,
            "win_rate": 80.0,
            "total_completed": 55,
            "last_updated": datetime.now(timezone.utc).isoformat(),
        },
        {
            "user_id": str(uuid.uuid4()),
            "user_name": "Third Place",
            "avatar_url": "https://example.com/avatar3.jpg",
            "country_code": "US",
            "first_wins": 40,
            "win_rate": 75.0,
            "total_completed": 50,
            "last_updated": datetime.now(timezone.utc).isoformat(),
        },
    ]


@pytest.fixture
def sample_unlock_status_unlocked():
    """Sample unlock status for unlocked user."""
    return {
        "is_unlocked": True,
        "workouts_completed": 15,
        "workouts_needed": 0,
        "days_active": 30,
    }


@pytest.fixture
def sample_unlock_status_locked():
    """Sample unlock status for locked user."""
    return {
        "is_unlocked": False,
        "workouts_completed": 5,
        "workouts_needed": 5,
        "days_active": 10,
    }


# ============================================================
# GET LEADERBOARD TESTS
# ============================================================

class TestGetLeaderboard:
    """Test getting leaderboard data."""

    def test_get_global_leaderboard_unlocked(self, mock_leaderboard_service, sample_user_id, sample_leaderboard_entries):
        """Test getting global leaderboard when unlocked."""
        mock_leaderboard_service.check_unlock_status.return_value = {
            "is_unlocked": True,
            "workouts_completed": 15,
            "workouts_needed": 0,
        }

        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": sample_leaderboard_entries,
            "total": 3,
        }

        mock_leaderboard_service._get_friend_ids.return_value = []

        mock_leaderboard_service.get_user_rank.return_value = {
            "rank_info": {"rank": 10, "total_users": 100, "percentile": 10.0},
            "stats": {
                "user_id": sample_user_id,
                "user_name": "Current User",
                "first_wins": 30,
                "win_rate": 70.0,
                "total_completed": 40,
            },
        }

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}&leaderboard_type=challenge_masters&filter_type=global"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["leaderboard_type"] == "challenge_masters"
        assert data["filter_type"] == "global"
        assert len(data["entries"]) == 3
        assert data["total_entries"] == 3
        assert data["user_rank"] is not None

    def test_get_global_leaderboard_locked(self, mock_leaderboard_service, sample_user_id):
        """Test getting global leaderboard when locked (< 10 workouts)."""
        mock_leaderboard_service.check_unlock_status.return_value = {
            "is_unlocked": False,
            "workouts_completed": 5,
            "workouts_needed": 5,
        }

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}&leaderboard_type=challenge_masters&filter_type=global"
        )

        assert response.status_code == 403
        assert "workouts" in response.json()["detail"].lower()

    def test_get_friends_leaderboard(self, mock_leaderboard_service, sample_user_id, sample_leaderboard_entries):
        """Test getting friends-only leaderboard (always accessible)."""
        mock_leaderboard_service.check_unlock_status.return_value = {
            "is_unlocked": False,  # Even locked users can see friends
            "workouts_completed": 5,
            "workouts_needed": 5,
        }

        # Only friends entries
        friend_entries = [sample_leaderboard_entries[0]]

        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": friend_entries,
            "total": 1,
        }

        mock_leaderboard_service._get_friend_ids.return_value = [friend_entries[0]["user_id"]]
        mock_leaderboard_service.get_user_rank.return_value = None

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}&filter_type=friends"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["filter_type"] == "friends"
        assert len(data["entries"]) == 1

    def test_get_country_leaderboard(self, mock_leaderboard_service, sample_user_id, sample_leaderboard_entries):
        """Test getting country-specific leaderboard."""
        mock_leaderboard_service.check_unlock_status.return_value = {
            "is_unlocked": True,
            "workouts_completed": 15,
            "workouts_needed": 0,
        }

        # Filter to US entries
        us_entries = [e for e in sample_leaderboard_entries if e["country_code"] == "US"]

        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": us_entries,
            "total": len(us_entries),
        }

        mock_leaderboard_service._get_friend_ids.return_value = []
        mock_leaderboard_service.get_user_rank.return_value = None

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}&filter_type=country&country_code=US"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["filter_type"] == "country"
        assert data["country_code"] == "US"
        assert all(e["country_code"] == "US" for e in data["entries"])

    def test_get_country_leaderboard_missing_code(self, mock_leaderboard_service, sample_user_id):
        """Test getting country leaderboard without country_code."""
        mock_leaderboard_service.check_unlock_status.return_value = {
            "is_unlocked": True,
        }

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}&filter_type=country"
        )

        assert response.status_code == 400
        assert "country_code required" in response.json()["detail"]

    def test_get_volume_kings_leaderboard(self, mock_leaderboard_service, sample_user_id):
        """Test getting Volume Kings leaderboard."""
        mock_leaderboard_service.check_unlock_status.return_value = {"is_unlocked": True}

        volume_entries = [
            {
                "user_id": str(uuid.uuid4()),
                "user_name": "Heavy Lifter",
                "total_volume_lbs": 1000000,
                "total_workouts": 100,
                "avg_volume_per_workout": 10000,
                "last_updated": datetime.now(timezone.utc).isoformat(),
            }
        ]

        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": volume_entries,
            "total": 1,
        }
        mock_leaderboard_service._get_friend_ids.return_value = []
        mock_leaderboard_service.get_user_rank.return_value = None

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}&leaderboard_type=volume_kings"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["leaderboard_type"] == "volume_kings"
        if data["entries"]:
            assert "total_volume_lbs" in data["entries"][0]

    def test_get_streaks_leaderboard(self, mock_leaderboard_service, sample_user_id):
        """Test getting Streaks leaderboard."""
        mock_leaderboard_service.check_unlock_status.return_value = {"is_unlocked": True}

        streak_entries = [
            {
                "user_id": str(uuid.uuid4()),
                "user_name": "Consistent Athlete",
                "current_streak": 30,
                "best_streak": 45,
                "last_workout_date": datetime.now(timezone.utc).isoformat(),
                "last_updated": datetime.now(timezone.utc).isoformat(),
            }
        ]

        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": streak_entries,
            "total": 1,
        }
        mock_leaderboard_service._get_friend_ids.return_value = []
        mock_leaderboard_service.get_user_rank.return_value = None

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}&leaderboard_type=streaks"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["leaderboard_type"] == "streaks"

    def test_get_weekly_challenges_leaderboard(self, mock_leaderboard_service, sample_user_id):
        """Test getting Weekly Challenges leaderboard."""
        mock_leaderboard_service.check_unlock_status.return_value = {"is_unlocked": True}

        weekly_entries = [
            {
                "user_id": str(uuid.uuid4()),
                "user_name": "Weekly Champion",
                "weekly_wins": 5,
                "weekly_completed": 7,
                "weekly_win_rate": 71.43,
                "last_updated": datetime.now(timezone.utc).isoformat(),
            }
        ]

        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": weekly_entries,
            "total": 1,
        }
        mock_leaderboard_service._get_friend_ids.return_value = []
        mock_leaderboard_service.get_user_rank.return_value = None

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}&leaderboard_type=weekly_challenges"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["leaderboard_type"] == "weekly_challenges"

    def test_leaderboard_pagination(self, mock_leaderboard_service, sample_user_id, sample_leaderboard_entries):
        """Test leaderboard pagination."""
        mock_leaderboard_service.check_unlock_status.return_value = {"is_unlocked": True}

        # Return subset for pagination
        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": sample_leaderboard_entries[:2],
            "total": 100,  # More total than returned
        }
        mock_leaderboard_service._get_friend_ids.return_value = []
        mock_leaderboard_service.get_user_rank.return_value = None

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}&limit=2&offset=0"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["limit"] == 2
        assert data["offset"] == 0
        assert data["has_more"] is True
        assert len(data["entries"]) == 2

    def test_leaderboard_empty_results(self, mock_leaderboard_service, sample_user_id):
        """Test leaderboard with no results."""
        mock_leaderboard_service.check_unlock_status.return_value = {"is_unlocked": True}
        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": [],
            "total": 0,
        }

        response = client.get(
            f"/api/v1/leaderboard/?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["entries"] == []
        assert data["total_entries"] == 0
        assert data["has_more"] is False


# ============================================================
# GET USER RANK TESTS
# ============================================================

class TestGetUserRank:
    """Test getting user's rank."""

    def test_get_user_rank_success(self, mock_leaderboard_service, sample_user_id):
        """Test getting user's rank successfully."""
        mock_leaderboard_service.get_user_rank.return_value = {
            "rank_info": {
                "rank": 25,
                "total_users": 500,
                "percentile": 5.0,
            },
            "stats": {
                "user_id": sample_user_id,
                "user_name": "Test User",
                "first_wins": 35,
                "win_rate": 78.0,
                "total_completed": 45,
            },
        }

        response = client.get(
            f"/api/v1/leaderboard/rank?user_id={sample_user_id}&leaderboard_type=challenge_masters"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == sample_user_id
        assert data["rank"] == 25
        assert data["total_users"] == 500
        assert data["percentile"] == 5.0
        assert data["user_stats"] is not None

    def test_get_user_rank_with_country_filter(self, mock_leaderboard_service, sample_user_id):
        """Test getting user's rank with country filter."""
        mock_leaderboard_service.get_user_rank.return_value = {
            "rank_info": {
                "rank": 5,  # Lower rank in country
                "total_users": 50,
                "percentile": 10.0,
            },
            "stats": {
                "user_id": sample_user_id,
                "user_name": "Test User",
                "first_wins": 35,
            },
        }

        response = client.get(
            f"/api/v1/leaderboard/rank?user_id={sample_user_id}&country_filter=US"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["rank"] == 5
        assert data["total_users"] == 50

    def test_get_user_rank_not_found(self, mock_leaderboard_service, sample_user_id):
        """Test getting rank for user not in leaderboard."""
        mock_leaderboard_service.get_user_rank.return_value = None

        response = client.get(
            f"/api/v1/leaderboard/rank?user_id={sample_user_id}"
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()


# ============================================================
# GET UNLOCK STATUS TESTS
# ============================================================

class TestGetUnlockStatus:
    """Test getting unlock status."""

    def test_get_unlock_status_unlocked(self, mock_leaderboard_service, sample_user_id, sample_unlock_status_unlocked):
        """Test getting unlock status for unlocked user."""
        mock_leaderboard_service.check_unlock_status.return_value = sample_unlock_status_unlocked

        response = client.get(f"/api/v1/leaderboard/unlock-status?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["is_unlocked"] is True
        assert data["workouts_completed"] == 15
        assert data["workouts_needed"] == 0
        assert data["progress_percentage"] == 100.0
        assert "unlocked" in data["unlock_message"].lower()

    def test_get_unlock_status_locked(self, mock_leaderboard_service, sample_user_id, sample_unlock_status_locked):
        """Test getting unlock status for locked user."""
        mock_leaderboard_service.check_unlock_status.return_value = sample_unlock_status_locked

        response = client.get(f"/api/v1/leaderboard/unlock-status?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["is_unlocked"] is False
        assert data["workouts_completed"] == 5
        assert data["workouts_needed"] == 5
        assert data["progress_percentage"] == 50.0
        assert "complete" in data["unlock_message"].lower()

    def test_get_unlock_status_almost_unlocked(self, mock_leaderboard_service, sample_user_id):
        """Test getting unlock status when almost unlocked."""
        mock_leaderboard_service.check_unlock_status.return_value = {
            "is_unlocked": False,
            "workouts_completed": 9,
            "workouts_needed": 1,
            "days_active": 15,
        }

        response = client.get(f"/api/v1/leaderboard/unlock-status?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["workouts_needed"] == 1
        assert data["progress_percentage"] == 90.0


# ============================================================
# GET LEADERBOARD STATS TESTS
# ============================================================

class TestGetLeaderboardStats:
    """Test getting overall leaderboard statistics."""

    def test_get_leaderboard_stats(self, mock_leaderboard_service):
        """Test getting overall leaderboard statistics."""
        mock_leaderboard_service.get_leaderboard_stats.return_value = {
            "total_users": 5000,
            "total_countries": 45,
            "top_country": "US",
            "average_wins": 12.5,
            "highest_streak": 365,
            "total_volume_lifted": 500000000.0,
        }

        response = client.get("/api/v1/leaderboard/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["total_users"] == 5000
        assert data["total_countries"] == 45
        assert data["top_country"] == "US"
        assert data["average_wins"] == 12.5
        assert data["highest_streak"] == 365
        assert data["total_volume_lifted"] == 500000000.0


# ============================================================
# ASYNC CHALLENGE TESTS
# ============================================================

class TestAsyncChallenge:
    """Test async challenge creation from leaderboard."""

    def test_create_async_challenge_success(self, mock_leaderboard_service, sample_user_id):
        """Test successfully creating async challenge."""
        target_user_id = str(uuid.uuid4())
        workout_log_id = str(uuid.uuid4())

        mock_leaderboard_service.create_async_challenge.return_value = {
            "challenge_id": str(uuid.uuid4()),
            "target_user_name": "Target User",
            "workout_name": "Their Best Leg Day",
            "target_stats": {
                "duration_minutes": 60,
                "total_volume": 10000,
                "exercises_count": 8,
            },
        }

        response = client.post(
            f"/api/v1/leaderboard/async-challenge?user_id={sample_user_id}",
            json={
                "target_user_id": target_user_id,
                "workout_log_id": workout_log_id,
                "challenge_message": "I'm coming for your record!",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["challenge_created"] is True
        assert data["notification_sent"] is False  # Async = no immediate notification
        assert data["target_user_name"] == "Target User"
        assert data["workout_name"] == "Their Best Leg Day"
        assert "target_stats" in data

    def test_create_async_challenge_auto_best(self, mock_leaderboard_service, sample_user_id):
        """Test creating async challenge without workout_id (auto-find best)."""
        target_user_id = str(uuid.uuid4())

        mock_leaderboard_service.create_async_challenge.return_value = {
            "challenge_id": str(uuid.uuid4()),
            "target_user_name": "Target User",
            "workout_name": "Their Best Workout",
            "target_stats": {"total_volume": 15000},
        }

        response = client.post(
            f"/api/v1/leaderboard/async-challenge?user_id={sample_user_id}",
            json={
                "target_user_id": target_user_id,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["challenge_created"] is True

    def test_create_async_challenge_user_not_found(self, mock_leaderboard_service, sample_user_id):
        """Test creating async challenge for non-existent user."""
        target_user_id = str(uuid.uuid4())

        mock_leaderboard_service.create_async_challenge.side_effect = ValueError("Target user not found")

        response = client.post(
            f"/api/v1/leaderboard/async-challenge?user_id={sample_user_id}",
            json={
                "target_user_id": target_user_id,
            }
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_create_async_challenge_no_workouts(self, mock_leaderboard_service, sample_user_id):
        """Test creating async challenge when target has no workouts."""
        target_user_id = str(uuid.uuid4())

        mock_leaderboard_service.create_async_challenge.side_effect = ValueError("No workouts found")

        response = client.post(
            f"/api/v1/leaderboard/async-challenge?user_id={sample_user_id}",
            json={
                "target_user_id": target_user_id,
            }
        )

        assert response.status_code == 404

    def test_create_async_challenge_failure(self, mock_leaderboard_service, sample_user_id):
        """Test handling of unexpected error during challenge creation."""
        target_user_id = str(uuid.uuid4())

        mock_leaderboard_service.create_async_challenge.side_effect = Exception("Database error")

        response = client.post(
            f"/api/v1/leaderboard/async-challenge?user_id={sample_user_id}",
            json={
                "target_user_id": target_user_id,
            }
        )

        assert response.status_code == 500
        assert "Failed to create challenge" in response.json()["detail"]


# ============================================================
# HELPER FUNCTION TESTS
# ============================================================

class TestHelperFunctions:
    """Test helper functions in leaderboard module."""

    def test_build_leaderboard_entry_challenge_masters(self):
        """Test building leaderboard entry for challenge masters."""
        from api.v1.leaderboard import _build_leaderboard_entry

        data = {
            "user_id": "user123",
            "user_name": "Test User",
            "avatar_url": "https://example.com/avatar.jpg",
            "country_code": "US",
            "first_wins": 50,
            "win_rate": 85.5,
            "total_completed": 60,
        }

        entry = _build_leaderboard_entry(
            data, rank=1, leaderboard_type=LeaderboardType.challenge_masters,
            is_friend=True, is_current_user=False
        )

        assert entry.rank == 1
        assert entry.user_id == "user123"
        assert entry.user_name == "Test User"
        assert entry.is_friend is True
        assert entry.is_current_user is False
        assert entry.first_wins == 50
        assert entry.win_rate == 85.5

    def test_build_leaderboard_entry_volume_kings(self):
        """Test building leaderboard entry for volume kings."""
        from api.v1.leaderboard import _build_leaderboard_entry

        data = {
            "user_id": "user123",
            "user_name": "Heavy Lifter",
            "total_volume_lbs": 1000000.0,
            "total_workouts": 100,
            "avg_volume_per_workout": 10000.0,
        }

        entry = _build_leaderboard_entry(
            data, rank=1, leaderboard_type=LeaderboardType.volume_kings,
            is_friend=False, is_current_user=True
        )

        assert entry.total_volume_lbs == 1000000.0
        assert entry.total_workouts == 100
        assert entry.avg_volume_per_workout == 10000.0
        assert entry.is_current_user is True

    def test_build_leaderboard_entry_streaks(self):
        """Test building leaderboard entry for streaks."""
        from api.v1.leaderboard import _build_leaderboard_entry

        data = {
            "user_id": "user123",
            "user_name": "Consistent",
            "current_streak": 30,
            "best_streak": 45,
            "last_workout_date": datetime.now(timezone.utc).isoformat(),
        }

        entry = _build_leaderboard_entry(
            data, rank=1, leaderboard_type=LeaderboardType.streaks,
            is_friend=False, is_current_user=False
        )

        assert entry.current_streak == 30
        assert entry.best_streak == 45

    def test_calculate_refresh_time_minutes(self):
        """Test refresh time calculation in minutes."""
        from api.v1.leaderboard import _calculate_refresh_time

        # 30 minutes ago
        last_updated = datetime.now(timezone.utc) - timedelta(minutes=30)
        refresh_time = _calculate_refresh_time(last_updated)

        assert "minutes" in refresh_time

    def test_calculate_refresh_time_seconds(self):
        """Test refresh time calculation in seconds."""
        from api.v1.leaderboard import _calculate_refresh_time

        # 59 minutes ago (about to refresh)
        last_updated = datetime.now(timezone.utc) - timedelta(minutes=59, seconds=30)
        refresh_time = _calculate_refresh_time(last_updated)

        assert "seconds" in refresh_time

    def test_get_order_column(self):
        """Test getting order column for leaderboard type."""
        from api.v1.leaderboard import _get_order_column

        assert _get_order_column(LeaderboardType.challenge_masters) == "first_wins"
        assert _get_order_column(LeaderboardType.volume_kings) == "total_volume_lbs"
        assert _get_order_column(LeaderboardType.streaks) == "best_streak"
        assert _get_order_column(LeaderboardType.weekly_challenges) == "weekly_wins"


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_leaderboard_entry_flags(self, mock_leaderboard_service, sample_user_id, sample_leaderboard_entries):
        """Test is_friend and is_current_user flags in entries."""
        mock_leaderboard_service.check_unlock_status.return_value = {"is_unlocked": True}

        # Make one entry the current user
        entries = sample_leaderboard_entries.copy()
        entries[1]["user_id"] = sample_user_id

        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": entries,
            "total": 3,
        }

        # First entry is a friend
        mock_leaderboard_service._get_friend_ids.return_value = [entries[0]["user_id"]]
        mock_leaderboard_service.get_user_rank.return_value = None

        response = client.get(f"/api/v1/leaderboard/?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()

        # Check flags
        assert data["entries"][0]["is_friend"] is True
        assert data["entries"][1]["is_current_user"] is True

    def test_leaderboard_rank_ordering(self, mock_leaderboard_service, sample_user_id, sample_leaderboard_entries):
        """Test that ranks are assigned correctly."""
        mock_leaderboard_service.check_unlock_status.return_value = {"is_unlocked": True}
        mock_leaderboard_service.get_leaderboard_entries.return_value = {
            "entries": sample_leaderboard_entries,
            "total": 3,
        }
        mock_leaderboard_service._get_friend_ids.return_value = []
        mock_leaderboard_service.get_user_rank.return_value = None

        response = client.get(f"/api/v1/leaderboard/?user_id={sample_user_id}")

        assert response.status_code == 200
        data = response.json()

        # Verify sequential ranks
        for i, entry in enumerate(data["entries"]):
            assert entry["rank"] == i + 1


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
