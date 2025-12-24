"""
Tests for leaderboard service.
"""

import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone


class TestLeaderboardServiceInit:
    """Tests for LeaderboardService initialization."""

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_initializes_with_dependencies(self, mock_rag, mock_supabase):
        """Test service initializes with dependencies."""
        mock_supabase.return_value = MagicMock()
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService

        service = LeaderboardService()

        assert service.supabase is not None
        assert service.social_rag is not None


class TestViewMappings:
    """Tests for view mappings constants."""

    def test_view_names_mapping(self):
        """Test VIEW_NAMES contains all leaderboard types."""
        from services.leaderboard_service import LeaderboardService
        from models.leaderboard import LeaderboardType

        for lb_type in LeaderboardType:
            assert lb_type in LeaderboardService.VIEW_NAMES

    def test_order_columns_mapping(self):
        """Test ORDER_COLUMNS contains all leaderboard types."""
        from services.leaderboard_service import LeaderboardService
        from models.leaderboard import LeaderboardType

        for lb_type in LeaderboardType:
            assert lb_type in LeaderboardService.ORDER_COLUMNS


class TestCheckUnlockStatus:
    """Tests for check_unlock_status method."""

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_returns_unlock_data(self, mock_rag, mock_supabase):
        """Test returning unlock status data."""
        mock_client = MagicMock()
        mock_rpc_result = MagicMock()
        mock_rpc_result.execute.return_value.data = [{
            "is_unlocked": True,
            "workouts_completed": 15,
            "workouts_needed": 10,
            "days_active": 20
        }]
        mock_client.rpc.return_value = mock_rpc_result
        mock_supabase.return_value = mock_client
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService

        service = LeaderboardService()
        result = service.check_unlock_status("user-123")

        assert result["is_unlocked"] is True
        assert result["workouts_completed"] == 15

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_returns_defaults_when_no_data(self, mock_rag, mock_supabase):
        """Test returning defaults when no data."""
        mock_client = MagicMock()
        mock_rpc_result = MagicMock()
        mock_rpc_result.execute.return_value.data = None
        mock_client.rpc.return_value = mock_rpc_result
        mock_supabase.return_value = mock_client
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService

        service = LeaderboardService()
        result = service.check_unlock_status("user-123")

        assert result["is_unlocked"] is False
        assert result["workouts_completed"] == 0
        assert result["workouts_needed"] == 10
        assert result["days_active"] == 0


class TestGetLeaderboardEntries:
    """Tests for get_leaderboard_entries method."""

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_returns_global_entries(self, mock_rag, mock_supabase):
        """Test returning global leaderboard entries."""
        mock_client = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_order = MagicMock()
        mock_range = MagicMock()

        mock_client.table.return_value = mock_table
        mock_table.select.return_value = mock_select
        mock_select.execute.return_value.data = [
            {"user_id": "1", "first_wins": 10},
            {"user_id": "2", "first_wins": 8}
        ]
        mock_select.order.return_value = mock_order
        mock_order.range.return_value = mock_range
        mock_range.execute.return_value.data = [
            {"user_id": "1", "first_wins": 10}
        ]

        mock_supabase.return_value = mock_client
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService
        from models.leaderboard import LeaderboardType, LeaderboardFilter

        service = LeaderboardService()
        result = service.get_leaderboard_entries(
            leaderboard_type=LeaderboardType.challenge_masters,
            filter_type=LeaderboardFilter.global_,
            user_id="user-123",
            limit=10,
            offset=0
        )

        assert "entries" in result
        assert "total" in result

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_returns_empty_for_no_friends(self, mock_rag, mock_supabase):
        """Test returning empty list when no friends."""
        mock_client = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq1 = MagicMock()
        mock_eq2 = MagicMock()

        mock_client.table.return_value = mock_table
        mock_table.select.return_value = mock_select
        mock_select.eq.return_value = mock_eq1
        mock_eq1.eq.return_value = mock_eq2
        mock_eq2.execute.return_value.data = []  # No friends

        mock_supabase.return_value = mock_client
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService
        from models.leaderboard import LeaderboardType, LeaderboardFilter

        service = LeaderboardService()
        result = service.get_leaderboard_entries(
            leaderboard_type=LeaderboardType.challenge_masters,
            filter_type=LeaderboardFilter.friends,
            user_id="user-123",
            limit=10,
            offset=0
        )

        assert result["entries"] == []
        assert result["total"] == 0


class TestGetUserRank:
    """Tests for get_user_rank method."""

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_returns_user_rank_and_stats(self, mock_rag, mock_supabase):
        """Test returning user rank and stats."""
        mock_client = MagicMock()

        # Mock RPC call
        mock_rpc = MagicMock()
        mock_rpc.execute.return_value.data = [{"rank": 5, "total_users": 100}]
        mock_client.rpc.return_value = mock_rpc

        # Mock table call for stats
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq = MagicMock()
        mock_eq.execute.return_value.data = [{"user_id": "user-123", "first_wins": 10}]
        mock_select.eq.return_value = mock_eq
        mock_table.select.return_value = mock_select
        mock_client.table.return_value = mock_table

        mock_supabase.return_value = mock_client
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService
        from models.leaderboard import LeaderboardType

        service = LeaderboardService()
        result = service.get_user_rank(
            user_id="user-123",
            leaderboard_type=LeaderboardType.challenge_masters,
            country_filter=None
        )

        assert result is not None
        assert "rank_info" in result
        assert "stats" in result

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_returns_none_when_no_rank(self, mock_rag, mock_supabase):
        """Test returning None when user has no rank."""
        mock_client = MagicMock()
        mock_rpc = MagicMock()
        mock_rpc.execute.return_value.data = None
        mock_client.rpc.return_value = mock_rpc

        mock_supabase.return_value = mock_client
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService
        from models.leaderboard import LeaderboardType

        service = LeaderboardService()
        result = service.get_user_rank(
            user_id="user-123",
            leaderboard_type=LeaderboardType.challenge_masters
        )

        assert result is None


class TestGetLeaderboardStats:
    """Tests for get_leaderboard_stats method."""

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_returns_aggregated_stats(self, mock_rag, mock_supabase):
        """Test returning aggregated statistics."""
        mock_client = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()

        # Mock different table responses
        def mock_table_side_effect(table_name):
            mock_t = MagicMock()
            mock_s = MagicMock()
            mock_t.select.return_value = mock_s

            if "challenge_masters" in table_name:
                mock_s.execute.return_value.data = [
                    {"country_code": "US", "first_wins": 10},
                    {"country_code": "UK", "first_wins": 8}
                ]
            elif "volume" in table_name:
                mock_s.execute.return_value.data = [
                    {"total_volume_lbs": 50000}
                ]
            elif "streaks" in table_name:
                mock_s.execute.return_value.data = [
                    {"best_streak": 30}
                ]
            else:
                mock_s.execute.return_value.data = []

            return mock_t

        mock_client.table.side_effect = mock_table_side_effect
        mock_supabase.return_value = mock_client
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService

        service = LeaderboardService()
        result = service.get_leaderboard_stats()

        assert "total_users" in result
        assert "total_countries" in result
        assert "highest_streak" in result
        assert "total_volume_lifted" in result


class TestCreateAsyncChallenge:
    """Tests for create_async_challenge method."""

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_creates_challenge_successfully(self, mock_rag, mock_supabase):
        """Test creating async challenge successfully."""
        mock_client = MagicMock()

        # Mock user lookup
        def table_side_effect(table_name):
            mock_t = MagicMock()
            mock_s = MagicMock()
            mock_eq = MagicMock()

            if table_name == "users":
                mock_eq.execute.return_value.data = [{"name": "Test User"}]
            elif table_name == "workout_logs":
                mock_order = MagicMock()
                mock_limit = MagicMock()
                mock_order.limit.return_value = mock_limit
                mock_eq.order.return_value = mock_order
                mock_limit.execute.return_value.data = [{
                    "id": "workout-123",
                    "workout_name": "Test Workout",
                    "performance_data": {
                        "duration_minutes": 45,
                        "total_volume": 5000,
                        "exercises_count": 6
                    }
                }]
            elif table_name == "workout_challenges":
                mock_insert = MagicMock()
                mock_t.insert.return_value = mock_insert
                mock_insert.execute.return_value.data = [{"id": "challenge-123"}]
                return mock_t

            mock_s.eq.return_value = mock_eq
            mock_t.select.return_value = mock_s
            return mock_t

        mock_client.table.side_effect = table_side_effect
        mock_supabase.return_value = mock_client

        mock_rag_instance = MagicMock()
        mock_collection = MagicMock()
        mock_rag_instance.get_social_collection.return_value = mock_collection
        mock_rag.return_value = mock_rag_instance

        from services.leaderboard_service import LeaderboardService

        service = LeaderboardService()
        result = service.create_async_challenge(
            user_id="user-1",
            target_user_id="user-2"
        )

        assert "challenge_id" in result
        assert "target_user_name" in result

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_raises_error_for_missing_user(self, mock_rag, mock_supabase):
        """Test raising error when target user not found."""
        mock_client = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq = MagicMock()

        mock_eq.execute.return_value.data = []  # No user found
        mock_select.eq.return_value = mock_eq
        mock_table.select.return_value = mock_select
        mock_client.table.return_value = mock_table

        mock_supabase.return_value = mock_client
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService

        service = LeaderboardService()

        with pytest.raises(ValueError, match="Target user not found"):
            service.create_async_challenge(
                user_id="user-1",
                target_user_id="nonexistent"
            )


class TestHelperMethods:
    """Tests for helper methods."""

    @patch('services.leaderboard_service.get_supabase_client')
    @patch('services.leaderboard_service.get_social_rag_service')
    def test_get_friend_ids(self, mock_rag, mock_supabase):
        """Test _get_friend_ids helper method."""
        mock_client = MagicMock()
        mock_table = MagicMock()
        mock_select = MagicMock()
        mock_eq1 = MagicMock()
        mock_eq2 = MagicMock()

        mock_eq2.execute.return_value.data = [
            {"friend_id": "friend-1"},
            {"friend_id": "friend-2"}
        ]
        mock_eq1.eq.return_value = mock_eq2
        mock_select.eq.return_value = mock_eq1
        mock_table.select.return_value = mock_select
        mock_client.table.return_value = mock_table

        mock_supabase.return_value = mock_client
        mock_rag.return_value = MagicMock()

        from services.leaderboard_service import LeaderboardService

        service = LeaderboardService()
        result = service._get_friend_ids("user-123")

        assert len(result) == 2
        assert "friend-1" in result
        assert "friend-2" in result
