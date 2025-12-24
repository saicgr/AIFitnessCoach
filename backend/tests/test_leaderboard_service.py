"""
Tests for LeaderboardService.

Tests:
- Unlock status checking
- Getting leaderboard entries
- User rank calculation
- Leaderboard statistics
- Async challenge creation
- Helper methods

Run with: pytest backend/tests/test_leaderboard_service.py -v
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone
import uuid

from services.leaderboard_service import LeaderboardService
from models.leaderboard import LeaderboardType, LeaderboardFilter


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase():
    """Mock Supabase client."""
    with patch('services.leaderboard_service.get_supabase') as mock:
        supabase_mock = MagicMock()
        mock.return_value.client = supabase_mock
        yield supabase_mock


@pytest.fixture
def mock_social_rag():
    """Mock Social RAG service."""
    with patch('services.leaderboard_service.get_social_rag_service') as mock:
        rag_mock = MagicMock()
        collection_mock = MagicMock()
        rag_mock.get_social_collection.return_value = collection_mock
        mock.return_value = rag_mock
        yield rag_mock, collection_mock


@pytest.fixture
def leaderboard_service(mock_supabase, mock_social_rag):
    """Create LeaderboardService instance with mocked dependencies."""
    rag_mock, _ = mock_social_rag
    service = LeaderboardService()
    service.supabase = mock_supabase
    service.social_rag = rag_mock
    return service


@pytest.fixture
def sample_user_id():
    """Sample user ID."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_leaderboard_data():
    """Sample leaderboard view data."""
    return [
        {
            "user_id": str(uuid.uuid4()),
            "user_name": "Top User",
            "avatar_url": "https://example.com/avatar1.jpg",
            "country_code": "US",
            "first_wins": 100,
            "win_rate": 90.0,
            "total_completed": 110,
        },
        {
            "user_id": str(uuid.uuid4()),
            "user_name": "Second User",
            "avatar_url": None,
            "country_code": "GB",
            "first_wins": 80,
            "win_rate": 85.0,
            "total_completed": 95,
        },
        {
            "user_id": str(uuid.uuid4()),
            "user_name": "Third User",
            "avatar_url": "https://example.com/avatar3.jpg",
            "country_code": "US",
            "first_wins": 60,
            "win_rate": 75.0,
            "total_completed": 80,
        },
    ]


# ============================================================
# VIEW MAPPINGS TESTS
# ============================================================

class TestViewMappings:
    """Test view name and order column mappings."""

    def test_view_names(self, leaderboard_service):
        """Test view name mappings."""
        assert leaderboard_service.VIEW_NAMES[LeaderboardType.challenge_masters] == "leaderboard_challenge_masters"
        assert leaderboard_service.VIEW_NAMES[LeaderboardType.volume_kings] == "leaderboard_volume_kings"
        assert leaderboard_service.VIEW_NAMES[LeaderboardType.streaks] == "leaderboard_streaks"
        assert leaderboard_service.VIEW_NAMES[LeaderboardType.weekly_challenges] == "leaderboard_weekly_challenges"

    def test_order_columns(self, leaderboard_service):
        """Test order column mappings."""
        assert leaderboard_service.ORDER_COLUMNS[LeaderboardType.challenge_masters] == "first_wins"
        assert leaderboard_service.ORDER_COLUMNS[LeaderboardType.volume_kings] == "total_volume_lbs"
        assert leaderboard_service.ORDER_COLUMNS[LeaderboardType.streaks] == "best_streak"
        assert leaderboard_service.ORDER_COLUMNS[LeaderboardType.weekly_challenges] == "weekly_wins"


# ============================================================
# CHECK UNLOCK STATUS TESTS
# ============================================================

class TestCheckUnlockStatus:
    """Test unlock status checking."""

    def test_check_unlock_status_unlocked(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test checking unlock status for unlocked user."""
        mock_supabase.rpc.return_value.execute.return_value.data = [{
            "is_unlocked": True,
            "workouts_completed": 15,
            "workouts_needed": 0,
            "days_active": 30,
        }]

        result = leaderboard_service.check_unlock_status(sample_user_id)

        assert result["is_unlocked"] is True
        assert result["workouts_completed"] == 15
        assert result["workouts_needed"] == 0
        mock_supabase.rpc.assert_called_with("check_leaderboard_unlock", {"p_user_id": sample_user_id})

    def test_check_unlock_status_locked(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test checking unlock status for locked user."""
        mock_supabase.rpc.return_value.execute.return_value.data = [{
            "is_unlocked": False,
            "workouts_completed": 5,
            "workouts_needed": 5,
            "days_active": 10,
        }]

        result = leaderboard_service.check_unlock_status(sample_user_id)

        assert result["is_unlocked"] is False
        assert result["workouts_completed"] == 5
        assert result["workouts_needed"] == 5

    def test_check_unlock_status_no_data(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test checking unlock status when no data returned."""
        mock_supabase.rpc.return_value.execute.return_value.data = None

        result = leaderboard_service.check_unlock_status(sample_user_id)

        assert result["is_unlocked"] is False
        assert result["workouts_completed"] == 0
        assert result["workouts_needed"] == 10


# ============================================================
# GET LEADERBOARD ENTRIES TESTS
# ============================================================

class TestGetLeaderboardEntries:
    """Test getting leaderboard entries."""

    def test_get_global_entries(self, leaderboard_service, mock_supabase, sample_user_id, sample_leaderboard_data):
        """Test getting global leaderboard entries."""
        # Mock the query chain
        mock_query = MagicMock()
        mock_query.execute.return_value.data = sample_leaderboard_data
        mock_supabase.table.return_value.select.return_value = mock_query
        mock_query.order.return_value.range.return_value.execute.return_value.data = sample_leaderboard_data

        result = leaderboard_service.get_leaderboard_entries(
            leaderboard_type=LeaderboardType.challenge_masters,
            filter_type=LeaderboardFilter.global_lb,
            user_id=sample_user_id,
            limit=100,
            offset=0,
        )

        assert "entries" in result
        assert "total" in result
        assert result["total"] == len(sample_leaderboard_data)

    def test_get_country_entries(self, leaderboard_service, mock_supabase, sample_user_id, sample_leaderboard_data):
        """Test getting country-filtered leaderboard entries."""
        us_entries = [e for e in sample_leaderboard_data if e["country_code"] == "US"]

        mock_query = MagicMock()
        mock_supabase.table.return_value.select.return_value.eq.return_value = mock_query
        mock_query.execute.return_value.data = us_entries
        mock_query.order.return_value.range.return_value.execute.return_value.data = us_entries

        result = leaderboard_service.get_leaderboard_entries(
            leaderboard_type=LeaderboardType.challenge_masters,
            filter_type=LeaderboardFilter.country,
            user_id=sample_user_id,
            country_code="US",
        )

        assert result["total"] == len(us_entries)

    def test_get_friends_entries(self, leaderboard_service, mock_supabase, sample_user_id, sample_leaderboard_data):
        """Test getting friends-only leaderboard entries."""
        friend_id = sample_leaderboard_data[0]["user_id"]

        # Mock friend lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {"friend_id": friend_id}
        ]

        # Mock leaderboard query
        mock_query = MagicMock()
        mock_supabase.table.return_value.select.return_value.in_.return_value = mock_query
        mock_query.execute.return_value.data = [sample_leaderboard_data[0]]
        mock_query.order.return_value.range.return_value.execute.return_value.data = [sample_leaderboard_data[0]]

        result = leaderboard_service.get_leaderboard_entries(
            leaderboard_type=LeaderboardType.challenge_masters,
            filter_type=LeaderboardFilter.friends,
            user_id=sample_user_id,
        )

        assert "entries" in result

    def test_get_friends_entries_no_friends(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test getting friends entries when user has no friends."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        result = leaderboard_service.get_leaderboard_entries(
            leaderboard_type=LeaderboardType.challenge_masters,
            filter_type=LeaderboardFilter.friends,
            user_id=sample_user_id,
        )

        assert result["entries"] == []
        assert result["total"] == 0

    def test_get_entries_with_pagination(self, leaderboard_service, mock_supabase, sample_user_id, sample_leaderboard_data):
        """Test getting entries with pagination."""
        mock_query = MagicMock()
        mock_query.execute.return_value.data = sample_leaderboard_data
        mock_supabase.table.return_value.select.return_value = mock_query
        mock_query.order.return_value.range.return_value.execute.return_value.data = sample_leaderboard_data[:2]

        result = leaderboard_service.get_leaderboard_entries(
            leaderboard_type=LeaderboardType.challenge_masters,
            filter_type=LeaderboardFilter.global_lb,
            user_id=sample_user_id,
            limit=2,
            offset=0,
        )

        assert len(result["entries"]) == 2


# ============================================================
# GET USER RANK TESTS
# ============================================================

class TestGetUserRank:
    """Test user rank retrieval."""

    def test_get_user_rank_success(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test getting user rank successfully."""
        mock_supabase.rpc.return_value.execute.return_value.data = [{
            "rank": 25,
            "total_users": 500,
            "percentile": 5.0,
        }]

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "user_id": sample_user_id,
            "user_name": "Test User",
            "first_wins": 35,
        }]

        result = leaderboard_service.get_user_rank(
            user_id=sample_user_id,
            leaderboard_type=LeaderboardType.challenge_masters,
        )

        assert result is not None
        assert result["rank_info"]["rank"] == 25
        assert result["rank_info"]["total_users"] == 500
        assert result["stats"]["user_id"] == sample_user_id

    def test_get_user_rank_with_country_filter(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test getting user rank with country filter."""
        mock_supabase.rpc.return_value.execute.return_value.data = [{
            "rank": 5,
            "total_users": 50,
            "percentile": 10.0,
        }]

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "user_id": sample_user_id,
            "user_name": "Test User",
        }]

        result = leaderboard_service.get_user_rank(
            user_id=sample_user_id,
            leaderboard_type=LeaderboardType.challenge_masters,
            country_filter="US",
        )

        assert result["rank_info"]["rank"] == 5
        mock_supabase.rpc.assert_called_with("get_user_leaderboard_rank", {
            "p_user_id": sample_user_id,
            "p_leaderboard_type": "challenge_masters",
            "p_country_filter": "US",
        })

    def test_get_user_rank_not_found(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test getting rank for user not in leaderboard."""
        mock_supabase.rpc.return_value.execute.return_value.data = None

        result = leaderboard_service.get_user_rank(
            user_id=sample_user_id,
            leaderboard_type=LeaderboardType.challenge_masters,
        )

        assert result is None

    def test_get_user_rank_no_stats(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test getting rank when user stats not found."""
        mock_supabase.rpc.return_value.execute.return_value.data = [{
            "rank": 10,
            "total_users": 100,
            "percentile": 10.0,
        }]

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        result = leaderboard_service.get_user_rank(
            user_id=sample_user_id,
            leaderboard_type=LeaderboardType.challenge_masters,
        )

        assert result is None


# ============================================================
# GET LEADERBOARD STATS TESTS
# ============================================================

class TestGetLeaderboardStats:
    """Test overall leaderboard statistics."""

    def test_get_leaderboard_stats(self, leaderboard_service, mock_supabase):
        """Test getting overall leaderboard statistics."""
        # Mock challenge masters query
        masters_data = [
            {"country_code": "US", "first_wins": 50},
            {"country_code": "US", "first_wins": 40},
            {"country_code": "GB", "first_wins": 30},
        ]

        # Mock volume kings query
        volume_data = [
            {"total_volume_lbs": 1000000},
            {"total_volume_lbs": 500000},
        ]

        # Mock streaks query
        streaks_data = [
            {"best_streak": 100},
            {"best_streak": 50},
        ]

        # Setup mock returns for each table call
        call_count = [0]

        def mock_table(name):
            result = MagicMock()
            call_count[0] += 1
            if "masters" in name:
                result.select.return_value.execute.return_value.data = masters_data
            elif "volume" in name:
                result.select.return_value.execute.return_value.data = volume_data
            elif "streaks" in name:
                result.select.return_value.execute.return_value.data = streaks_data
            return result

        mock_supabase.table = mock_table

        result = leaderboard_service.get_leaderboard_stats()

        assert result["total_users"] == 3
        assert result["total_countries"] == 2  # US and GB
        assert result["top_country"] == "US"  # Most users
        assert result["average_wins"] == 40.0  # (50+40+30)/3
        assert result["highest_streak"] == 100
        assert result["total_volume_lifted"] == 1500000


# ============================================================
# CREATE ASYNC CHALLENGE TESTS
# ============================================================

class TestCreateAsyncChallenge:
    """Test async challenge creation."""

    def test_create_async_challenge_success(self, leaderboard_service, mock_supabase, mock_social_rag, sample_user_id):
        """Test successfully creating an async challenge."""
        rag_mock, collection_mock = mock_social_rag
        target_user_id = str(uuid.uuid4())
        workout_log_id = str(uuid.uuid4())
        challenge_id = str(uuid.uuid4())

        # Mock target user lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "Target User"}
        ]

        # Mock workout lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [{
            "id": workout_log_id,
            "workout_name": "Leg Day",
            "performance_data": {
                "duration_minutes": 60,
                "total_volume": 10000,
                "exercises_count": 8,
            },
        }]

        # Mock challenge insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": challenge_id,
        }]

        result = leaderboard_service.create_async_challenge(
            user_id=sample_user_id,
            target_user_id=target_user_id,
            workout_log_id=workout_log_id,
            challenge_message="Beat this!",
        )

        assert result["challenge_id"] == challenge_id
        assert result["target_user_name"] == "Target User"
        assert result["workout_name"] == "Leg Day"
        assert "target_stats" in result

    def test_create_async_challenge_auto_best_workout(self, leaderboard_service, mock_supabase, mock_social_rag, sample_user_id):
        """Test creating async challenge with auto-find best workout."""
        rag_mock, collection_mock = mock_social_rag
        target_user_id = str(uuid.uuid4())
        workout_log_id = str(uuid.uuid4())
        challenge_id = str(uuid.uuid4())

        # Mock target user lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "Target User"}
        ]

        # Mock best workout lookup (no specific workout_log_id)
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = [{
            "id": workout_log_id,
            "workout_name": "Best Workout",
            "performance_data": {"total_volume": 15000},
        }]

        # Mock challenge insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": challenge_id,
        }]

        result = leaderboard_service.create_async_challenge(
            user_id=sample_user_id,
            target_user_id=target_user_id,
            workout_log_id=None,  # Auto-find
        )

        assert result["challenge_id"] == challenge_id

    def test_create_async_challenge_target_not_found(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test creating challenge when target user not found."""
        target_user_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        with pytest.raises(ValueError, match="Target user not found"):
            leaderboard_service.create_async_challenge(
                user_id=sample_user_id,
                target_user_id=target_user_id,
            )

    def test_create_async_challenge_no_workouts(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test creating challenge when target has no workouts."""
        target_user_id = str(uuid.uuid4())

        # Mock target user found
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "Target User"}
        ]

        # Mock no workouts found
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []

        with pytest.raises(ValueError, match="No workouts found"):
            leaderboard_service.create_async_challenge(
                user_id=sample_user_id,
                target_user_id=target_user_id,
            )


# ============================================================
# HELPER METHOD TESTS
# ============================================================

class TestHelperMethods:
    """Test helper methods."""

    def test_get_friend_ids(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test getting friend IDs."""
        friend_ids = [str(uuid.uuid4()), str(uuid.uuid4())]

        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {"friend_id": friend_ids[0]},
            {"friend_id": friend_ids[1]},
        ]

        result = leaderboard_service._get_friend_ids(sample_user_id)

        assert len(result) == 2
        assert friend_ids[0] in result
        assert friend_ids[1] in result

    def test_get_friend_ids_no_friends(self, leaderboard_service, mock_supabase, sample_user_id):
        """Test getting friend IDs when user has no friends."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

        result = leaderboard_service._get_friend_ids(sample_user_id)

        assert result == []

    def test_log_async_challenge_success(self, leaderboard_service, mock_supabase, mock_social_rag, sample_user_id):
        """Test logging async challenge to ChromaDB."""
        rag_mock, collection_mock = mock_social_rag
        target_user_id = str(uuid.uuid4())
        challenge_id = str(uuid.uuid4())

        # Mock user lookups
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "Challenger"}
        ]

        leaderboard_service._log_async_challenge(
            user_id=sample_user_id,
            target_user_id=target_user_id,
            challenge_id=challenge_id,
            workout_name="Leg Day",
        )

        collection_mock.add.assert_called_once()
        call_args = collection_mock.add.call_args
        assert "BEAT" in call_args.kwargs["documents"][0]
        assert call_args.kwargs["ids"][0] == f"async_challenge_{challenge_id}"

    def test_log_async_challenge_chromadb_failure(self, leaderboard_service, mock_supabase, mock_social_rag, sample_user_id):
        """Test that ChromaDB failure doesn't raise exception."""
        rag_mock, collection_mock = mock_social_rag
        target_user_id = str(uuid.uuid4())
        challenge_id = str(uuid.uuid4())

        # Mock ChromaDB failure
        collection_mock.add.side_effect = Exception("ChromaDB error")

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
            {"name": "User"}
        ]

        # Should not raise
        leaderboard_service._log_async_challenge(
            user_id=sample_user_id,
            target_user_id=target_user_id,
            challenge_id=challenge_id,
            workout_name="Test",
        )


# ============================================================
# INTEGRATION TESTS
# ============================================================

class TestIntegration:
    """Integration tests for leaderboard service."""

    def test_full_leaderboard_flow(self, leaderboard_service, mock_supabase, sample_user_id, sample_leaderboard_data):
        """Test complete leaderboard retrieval flow."""
        # 1. Check unlock
        mock_supabase.rpc.return_value.execute.return_value.data = [{
            "is_unlocked": True,
            "workouts_completed": 15,
            "workouts_needed": 0,
        }]

        unlock_status = leaderboard_service.check_unlock_status(sample_user_id)
        assert unlock_status["is_unlocked"] is True

        # 2. Get entries
        mock_query = MagicMock()
        mock_query.execute.return_value.data = sample_leaderboard_data
        mock_supabase.table.return_value.select.return_value = mock_query
        mock_query.order.return_value.range.return_value.execute.return_value.data = sample_leaderboard_data

        entries = leaderboard_service.get_leaderboard_entries(
            leaderboard_type=LeaderboardType.challenge_masters,
            filter_type=LeaderboardFilter.global_lb,
            user_id=sample_user_id,
        )
        assert len(entries["entries"]) == 3

        # 3. Get user rank
        mock_supabase.rpc.return_value.execute.return_value.data = [{
            "rank": 10,
            "total_users": 100,
            "percentile": 10.0,
        }]
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
            "user_id": sample_user_id,
            "user_name": "Test User",
        }]

        rank = leaderboard_service.get_user_rank(
            user_id=sample_user_id,
            leaderboard_type=LeaderboardType.challenge_masters,
        )
        assert rank["rank_info"]["rank"] == 10


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
