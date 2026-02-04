"""
Tests for XP System API endpoints (migrations 217-220).

Tests:
- First-time bonuses (award, retrieve, available)
- Checkpoint progress (weekly/monthly tracking)
- Consumables system (inventory, use, 2x XP tokens)
- Daily crate system (claim, unlock activity crate)

Run with: pytest backend/tests/test_xp_system.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import date, datetime, timedelta
import asyncio


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for XP operations."""
    with patch("api.v1.xp.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_current_user():
    """Mock authenticated user."""
    return {
        "id": "user-test-123",
        "email": "test@example.com",
        "auth_id": "auth-test-456",
        "user_metadata": {},
    }


@pytest.fixture
def sample_first_time_bonus():
    return {
        "id": "bonus-1",
        "user_id": "user-test-123",
        "bonus_type": "first_workout",
        "xp_awarded": 150,
        "awarded_at": "2025-02-03T12:00:00Z",
    }


@pytest.fixture
def sample_checkpoint_progress():
    return {
        "weekly": {
            "period_start": "2025-02-03",
            "period_end": "2025-02-09",
            "workouts_target": 5,
            "workouts_completed": 2,
            "xp_awarded": False,
            "progress_percent": 40,
        },
        "monthly": {
            "period_start": "2025-02-01",
            "period_end": "2025-02-28",
            "workouts_target": 20,
            "workouts_completed": 5,
            "xp_awarded": False,
            "progress_percent": 25,
        },
    }


@pytest.fixture
def sample_consumables():
    return {
        "streak_shield": 3,
        "xp_token_2x": 1,
        "fitness_crate": 0,
        "premium_crate": 0,
    }


@pytest.fixture
def sample_daily_crates():
    return {
        "daily_crate_available": True,
        "streak_crate_available": True,
        "activity_crate_available": False,
        "selected_crate": None,
        "reward": None,
        "claimed": False,
        "claimed_at": None,
        "crate_date": "2025-02-03",
    }


# ============================================================
# FIRST-TIME BONUSES TESTS
# ============================================================

class TestFirstTimeBonuses:
    """Test first-time bonus endpoints."""

    def test_award_first_time_bonus_success(self, mock_supabase_db, mock_current_user):
        """Test successfully awarding a first-time bonus."""
        from api.v1.xp import award_first_time_bonus, FirstTimeBonusRequest, FIRST_TIME_BONUSES

        # Mock: bonus not already awarded
        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
        mock_table.upsert.return_value.execute.return_value = MagicMock()
        mock_table.insert.return_value.execute.return_value = MagicMock()

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {"total_xp": 150}

        request = FirstTimeBonusRequest(bonus_type="first_workout")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                award_first_time_bonus(request, mock_current_user)
            )

        assert result.awarded is True
        assert result.xp == FIRST_TIME_BONUSES["first_workout"]
        assert result.bonus_type == "first_workout"

    def test_award_first_time_bonus_already_claimed(self, mock_supabase_db, mock_current_user):
        """Test that duplicate bonus is prevented."""
        from api.v1.xp import award_first_time_bonus, FirstTimeBonusRequest

        # Mock: bonus already awarded
        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
            {"id": "existing-bonus"}
        ]

        request = FirstTimeBonusRequest(bonus_type="first_workout")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                award_first_time_bonus(request, mock_current_user)
            )

        assert result.awarded is False
        assert result.xp == 0

    def test_award_first_time_bonus_invalid_type(self, mock_supabase_db, mock_current_user):
        """Test invalid bonus type returns error."""
        from api.v1.xp import award_first_time_bonus, FirstTimeBonusRequest
        from fastapi import HTTPException

        request = FirstTimeBonusRequest(bonus_type="invalid_bonus_type")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            with pytest.raises(HTTPException) as exc_info:
                asyncio.get_event_loop().run_until_complete(
                    award_first_time_bonus(request, mock_current_user)
                )

        assert exc_info.value.status_code == 400

    def test_get_first_time_bonuses(self, mock_supabase_db, mock_current_user, sample_first_time_bonus):
        """Test retrieving awarded bonuses."""
        from api.v1.xp import get_first_time_bonuses

        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.order.return_value.execute.return_value.data = [
            sample_first_time_bonus
        ]

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_first_time_bonuses(mock_current_user)
            )

        assert len(result) == 1
        assert result[0].bonus_type == "first_workout"
        assert result[0].xp_awarded == 150

    def test_get_available_first_time_bonuses(self, mock_supabase_db, mock_current_user):
        """Test getting available (unclaimed) bonuses."""
        from api.v1.xp import get_available_first_time_bonuses, FIRST_TIME_BONUSES

        # Mock: only first_workout has been claimed
        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.execute.return_value.data = [
            {"bonus_type": "first_workout"}
        ]

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_available_first_time_bonuses(mock_current_user)
            )

        # Should have all bonus types with awarded status
        assert "bonuses" in result
        bonus_dict = {b["bonus_type"]: b["awarded"] for b in result["bonuses"]}
        assert bonus_dict["first_workout"] is True
        assert bonus_dict["first_breakfast"] is False


# ============================================================
# CHECKPOINT PROGRESS TESTS
# ============================================================

class TestCheckpointProgress:
    """Test checkpoint progress endpoints."""

    def test_get_checkpoint_progress_weekly(self, mock_supabase_db, mock_current_user, sample_checkpoint_progress):
        """Test getting weekly checkpoint progress."""
        from api.v1.xp import get_checkpoint_progress

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = sample_checkpoint_progress

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_checkpoint_progress("weekly", mock_current_user)
            )

        assert result["checkpoint_type"] == "weekly"
        assert result["workouts_target"] == 5
        assert result["workouts_completed"] == 2
        assert result["progress_percent"] == 40
        assert result["xp_reward"] == 200

    def test_get_checkpoint_progress_monthly(self, mock_supabase_db, mock_current_user, sample_checkpoint_progress):
        """Test getting monthly checkpoint progress."""
        from api.v1.xp import get_checkpoint_progress

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = sample_checkpoint_progress

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_checkpoint_progress("monthly", mock_current_user)
            )

        assert result["checkpoint_type"] == "monthly"
        assert result["workouts_target"] == 20
        assert result["workouts_completed"] == 5
        assert result["xp_reward"] == 1000

    def test_get_all_checkpoint_progress(self, mock_supabase_db, mock_current_user, sample_checkpoint_progress):
        """Test getting both weekly and monthly progress."""
        from api.v1.xp import get_all_checkpoint_progress

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = sample_checkpoint_progress

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_all_checkpoint_progress(mock_current_user)
            )

        assert "weekly" in result
        assert "monthly" in result

    def test_increment_checkpoint_workout(self, mock_supabase_db, mock_current_user):
        """Test incrementing workout count for checkpoints."""
        from api.v1.xp import increment_checkpoint_workout

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {
            "weekly_xp_awarded": 0,
            "monthly_xp_awarded": 0,
            "weekly_workouts": 3,
            "monthly_workouts": 6,
            "weekly_complete": False,
            "monthly_complete": False,
        }

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                increment_checkpoint_workout(mock_current_user)
            )

        assert result["success"] is True
        assert result["weekly_workouts"] == 3
        assert result["monthly_workouts"] == 6

    def test_increment_checkpoint_awards_weekly_xp(self, mock_supabase_db, mock_current_user):
        """Test XP is awarded when weekly checkpoint is reached."""
        from api.v1.xp import increment_checkpoint_workout

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {
            "weekly_xp_awarded": 200,
            "monthly_xp_awarded": 0,
            "weekly_workouts": 5,
            "monthly_workouts": 10,
            "weekly_complete": True,
            "monthly_complete": False,
        }

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                increment_checkpoint_workout(mock_current_user)
            )

        assert result["weekly_xp_awarded"] == 200
        assert result["total_xp_awarded"] == 200
        assert result["weekly_complete"] is True


# ============================================================
# CONSUMABLES TESTS
# ============================================================

class TestConsumables:
    """Test consumables system endpoints."""

    def test_get_consumables(self, mock_supabase_db, mock_current_user, sample_consumables):
        """Test getting user consumables inventory."""
        from api.v1.xp import get_consumables

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = sample_consumables

        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "active_2x_token_until": None
        }

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_consumables(mock_current_user)
            )

        assert result.streak_shield == 3
        assert result.xp_token_2x == 1
        assert result.fitness_crate == 0
        assert result.premium_crate == 0
        assert result.active_2x_until is None

    def test_use_consumable_streak_shield(self, mock_supabase_db, mock_current_user):
        """Test using a streak shield."""
        from api.v1.xp import use_consumable, UseConsumableRequest

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = True

        request = UseConsumableRequest(item_type="streak_shield")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                use_consumable(request, mock_current_user)
            )

        assert result["success"] is True
        assert result["item_type"] == "streak_shield"

    def test_use_consumable_2x_token(self, mock_supabase_db, mock_current_user):
        """Test using a 2x XP token."""
        from api.v1.xp import use_consumable, UseConsumableRequest

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = True

        request = UseConsumableRequest(item_type="xp_token_2x")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                use_consumable(request, mock_current_user)
            )

        assert result["success"] is True
        assert "24 hours" in result["message"]

    def test_use_consumable_no_items(self, mock_supabase_db, mock_current_user):
        """Test using a consumable when none available."""
        from api.v1.xp import use_consumable, UseConsumableRequest

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = False

        request = UseConsumableRequest(item_type="streak_shield")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                use_consumable(request, mock_current_user)
            )

        assert result["success"] is False

    def test_use_consumable_invalid_type(self, mock_supabase_db, mock_current_user):
        """Test using an invalid consumable type."""
        from api.v1.xp import use_consumable, UseConsumableRequest
        from fastapi import HTTPException

        request = UseConsumableRequest(item_type="invalid_item")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            with pytest.raises(HTTPException) as exc_info:
                asyncio.get_event_loop().run_until_complete(
                    use_consumable(request, mock_current_user)
                )

        assert exc_info.value.status_code == 400

    def test_open_crate_fitness(self, mock_supabase_db, mock_current_user):
        """Test opening a fitness crate."""
        from api.v1.xp import open_crate, OpenCrateRequest

        # Mock: user has the crate
        mock_supabase_db.client.rpc.return_value.execute.return_value.data = True

        request = OpenCrateRequest(crate_type="fitness_crate")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                open_crate(request, mock_current_user)
            )

        assert result["success"] is True
        assert result["crate_type"] == "fitness_crate"
        assert "reward" in result

    def test_open_crate_no_crate(self, mock_supabase_db, mock_current_user):
        """Test opening a crate when none available."""
        from api.v1.xp import open_crate, OpenCrateRequest

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = False

        request = OpenCrateRequest(crate_type="premium_crate")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                open_crate(request, mock_current_user)
            )

        assert result["success"] is False


# ============================================================
# DAILY CRATE TESTS
# ============================================================

class TestDailyCrates:
    """Test daily crate system endpoints."""

    def test_get_daily_crates(self, mock_supabase_db, mock_current_user, sample_daily_crates):
        """Test getting daily crate availability."""
        from api.v1.xp import get_daily_crates

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = sample_daily_crates

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_daily_crates(mock_current_user)
            )

        assert result.daily_crate_available is True
        assert result.streak_crate_available is True
        assert result.activity_crate_available is False
        assert result.claimed is False

    def test_claim_daily_crate_success(self, mock_supabase_db, mock_current_user):
        """Test claiming a daily crate."""
        from api.v1.xp import claim_daily_crate, ClaimDailyCrateRequest

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {
            "success": True,
            "crate_type": "daily",
            "reward": {"type": "xp", "amount": 50},
            "message": "Crate opened!",
        }

        request = ClaimDailyCrateRequest(crate_type="daily")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                claim_daily_crate(request, mock_current_user)
            )

        assert result["success"] is True
        assert result["crate_type"] == "daily"
        assert "reward" in result

    def test_claim_daily_crate_already_claimed(self, mock_supabase_db, mock_current_user):
        """Test claiming when already claimed today."""
        from api.v1.xp import claim_daily_crate, ClaimDailyCrateRequest

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {
            "success": False,
            "message": "Crate already claimed today",
        }

        request = ClaimDailyCrateRequest(crate_type="daily")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                claim_daily_crate(request, mock_current_user)
            )

        assert result["success"] is False

    def test_claim_streak_crate_unavailable(self, mock_supabase_db, mock_current_user):
        """Test claiming streak crate when not available."""
        from api.v1.xp import claim_daily_crate, ClaimDailyCrateRequest

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {
            "success": False,
            "message": "Streak crate not available (need 7+ day streak)",
        }

        request = ClaimDailyCrateRequest(crate_type="streak")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                claim_daily_crate(request, mock_current_user)
            )

        assert result["success"] is False
        assert "7+ day streak" in result.get("message", "")

    def test_claim_invalid_crate_type(self, mock_supabase_db, mock_current_user):
        """Test claiming invalid crate type."""
        from api.v1.xp import claim_daily_crate, ClaimDailyCrateRequest
        from fastapi import HTTPException

        request = ClaimDailyCrateRequest(crate_type="invalid")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            with pytest.raises(HTTPException) as exc_info:
                asyncio.get_event_loop().run_until_complete(
                    claim_daily_crate(request, mock_current_user)
                )

        assert exc_info.value.status_code == 400

    def test_unlock_activity_crate(self, mock_supabase_db, mock_current_user):
        """Test unlocking activity crate when all goals complete."""
        from api.v1.xp import unlock_activity_crate

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = True

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                unlock_activity_crate(mock_current_user)
            )

        assert result["success"] is True


# ============================================================
# DAILY GOALS XP TESTS
# ============================================================

class TestDailyGoalsXP:
    """Test daily goals XP awarding."""

    def test_award_goal_xp_workout(self, mock_supabase_db, mock_current_user):
        """Test awarding XP for workout completion."""
        from api.v1.xp import award_goal_xp, AwardGoalXPRequest

        # Mock: not already claimed
        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.eq.return_value.gte.return_value.lt.return_value.execute.return_value.data = []
        mock_table.upsert.return_value.execute.return_value = MagicMock()

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {"total_xp": 100}

        request = AwardGoalXPRequest(goal_type="workout_complete")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                award_goal_xp(request, mock_current_user)
            )

        assert result.success is True
        assert result.xp_awarded > 0
        assert result.already_claimed is False

    def test_award_goal_xp_already_claimed(self, mock_supabase_db, mock_current_user):
        """Test that duplicate goal XP is prevented."""
        from api.v1.xp import award_goal_xp, AwardGoalXPRequest

        # Mock: already claimed today
        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.eq.return_value.gte.return_value.lt.return_value.execute.return_value.data = [
            {"id": "existing-tx"}
        ]
        mock_table.upsert.return_value.execute.return_value = MagicMock()

        request = AwardGoalXPRequest(goal_type="weight_log")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                award_goal_xp(request, mock_current_user)
            )

        assert result.success is True
        assert result.xp_awarded == 0
        assert result.already_claimed is True

    def test_award_goal_xp_body_measurements(self, mock_supabase_db, mock_current_user):
        """Test awarding XP for body measurements."""
        from api.v1.xp import award_goal_xp, AwardGoalXPRequest

        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.eq.return_value.gte.return_value.lt.return_value.execute.return_value.data = []
        mock_table.upsert.return_value.execute.return_value = MagicMock()

        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {"total_xp": 20}

        request = AwardGoalXPRequest(goal_type="body_measurements")

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                award_goal_xp(request, mock_current_user)
            )

        assert result.success is True
        assert "body" in result.message.lower()

    def test_get_daily_goals_status(self, mock_supabase_db, mock_current_user):
        """Test getting daily goals completion status."""
        from api.v1.xp import get_daily_goals_status

        mock_table = MagicMock()
        mock_supabase_db.client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.gte.return_value.execute.return_value.data = [
            {"source": "daily_goal_workout_complete"},
            {"source": "daily_goal_weight_log"},
        ]

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_daily_goals_status(mock_current_user)
            )

        assert result.workout_complete is True
        assert result.weight_log is True
        assert result.meal_log is False
        assert result.protein_goal is False
        assert result.body_measurements is False


# ============================================================
# BONUS TYPES VALIDATION
# ============================================================

class TestBonusTypesValidation:
    """Test that all expected bonus types are defined."""

    def test_first_time_bonus_types_exist(self):
        """Verify all first-time bonus types are defined."""
        from api.v1.xp import FIRST_TIME_BONUSES

        expected_types = [
            "first_workout",
            "first_breakfast",
            "first_lunch",
            "first_dinner",
            "first_snack",
            "first_protein_goal",
            "first_calorie_goal",
            "first_weight_log",
            "first_fasting",
            "first_chat",
            "first_recipe",
            "first_template",
            "first_progress_photo",
            "first_habit",
            "first_pr",
            "first_body_measurements",
            "first_friend",
            "first_post",
            "first_reaction",
            "first_comment",
        ]

        for bonus_type in expected_types:
            assert bonus_type in FIRST_TIME_BONUSES, f"Missing bonus type: {bonus_type}"
            assert FIRST_TIME_BONUSES[bonus_type] > 0, f"Bonus {bonus_type} has no XP value"

    def test_crate_rewards_defined(self):
        """Verify crate reward tables are defined."""
        from api.v1.xp import CRATE_REWARDS

        assert "fitness_crate" in CRATE_REWARDS
        assert "premium_crate" in CRATE_REWARDS
        assert len(CRATE_REWARDS["fitness_crate"]) > 0
        assert len(CRATE_REWARDS["premium_crate"]) > 0


# ============================================================
# DYNAMIC CHECKPOINT TARGETS TESTS
# ============================================================

class TestDynamicCheckpointTargets:
    """Test dynamic checkpoint targets based on user's days_per_week."""

    def test_checkpoint_progress_includes_days_per_week(self, mock_supabase_db, mock_current_user):
        """Test that checkpoint progress response includes days_per_week."""
        from api.v1.xp import get_checkpoint_progress

        # Mock RPC with dynamic targets (user has 4 days/week)
        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {
            "weekly": {
                "period_start": "2025-02-03",
                "period_end": "2025-02-09",
                "workouts_target": 4,  # Dynamic: equals days_per_week
                "workouts_completed": 2,
                "xp_awarded": False,
                "progress_percent": 50,
                "days_per_week": 4,
            },
            "monthly": {
                "period_start": "2025-02-01",
                "period_end": "2025-02-28",
                "workouts_target": 18,  # Dynamic: ceil(4 * 4.3) = 18
                "workouts_completed": 5,
                "xp_awarded": False,
                "progress_percent": 28,
                "days_per_week": 4,
            },
        }

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_checkpoint_progress("weekly", mock_current_user)
            )

        assert result["checkpoint_type"] == "weekly"
        assert result["workouts_target"] == 4
        assert result["days_per_week"] == 4

    def test_checkpoint_progress_dynamic_targets_3_days(self, mock_supabase_db, mock_current_user):
        """Test checkpoint targets for 3 days/week user."""
        from api.v1.xp import get_checkpoint_progress

        # User with 3 days/week: weekly=3, monthly=ceil(3*4.3)=13
        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {
            "weekly": {
                "period_start": "2025-02-03",
                "period_end": "2025-02-09",
                "workouts_target": 3,
                "workouts_completed": 1,
                "xp_awarded": False,
                "progress_percent": 33,
                "days_per_week": 3,
            },
            "monthly": {
                "period_start": "2025-02-01",
                "period_end": "2025-02-28",
                "workouts_target": 13,
                "workouts_completed": 3,
                "xp_awarded": False,
                "progress_percent": 23,
                "days_per_week": 3,
            },
        }

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            weekly = asyncio.get_event_loop().run_until_complete(
                get_checkpoint_progress("weekly", mock_current_user)
            )
            monthly = asyncio.get_event_loop().run_until_complete(
                get_checkpoint_progress("monthly", mock_current_user)
            )

        assert weekly["workouts_target"] == 3
        assert monthly["workouts_target"] == 13

    def test_checkpoint_progress_dynamic_targets_6_days(self, mock_supabase_db, mock_current_user):
        """Test checkpoint targets for 6 days/week user."""
        from api.v1.xp import get_checkpoint_progress

        # User with 6 days/week: weekly=6, monthly=ceil(6*4.3)=26
        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {
            "weekly": {
                "period_start": "2025-02-03",
                "period_end": "2025-02-09",
                "workouts_target": 6,
                "workouts_completed": 4,
                "xp_awarded": False,
                "progress_percent": 67,
                "days_per_week": 6,
            },
            "monthly": {
                "period_start": "2025-02-01",
                "period_end": "2025-02-28",
                "workouts_target": 26,
                "workouts_completed": 10,
                "xp_awarded": False,
                "progress_percent": 38,
                "days_per_week": 6,
            },
        }

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            weekly = asyncio.get_event_loop().run_until_complete(
                get_checkpoint_progress("weekly", mock_current_user)
            )
            monthly = asyncio.get_event_loop().run_until_complete(
                get_checkpoint_progress("monthly", mock_current_user)
            )

        assert weekly["workouts_target"] == 6
        assert monthly["workouts_target"] == 26

    def test_increment_checkpoint_returns_targets(self, mock_supabase_db, mock_current_user):
        """Test increment checkpoint returns dynamic targets."""
        from api.v1.xp import increment_checkpoint_workout

        # Mock increment with dynamic targets
        mock_supabase_db.client.rpc.return_value.execute.return_value.data = {
            "weekly_xp_awarded": 0,
            "monthly_xp_awarded": 0,
            "weekly_workouts": 3,
            "monthly_workouts": 8,
            "weekly_target": 4,  # User's days_per_week
            "monthly_target": 18,  # ceil(4 * 4.3)
            "weekly_complete": False,
            "monthly_complete": False,
            "days_per_week": 4,
        }

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                increment_checkpoint_workout(mock_current_user)
            )

        assert result["success"] is True
        assert result["weekly_workouts"] == 3
        assert result["monthly_workouts"] == 8

    def test_checkpoint_fallback_uses_default(self, mock_supabase_db, mock_current_user):
        """Test that fallback uses default 5 days/week."""
        from api.v1.xp import get_checkpoint_progress

        # Mock RPC returning None (fallback case)
        mock_supabase_db.client.rpc.return_value.execute.return_value.data = None

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_checkpoint_progress("weekly", mock_current_user)
            )

        # Fallback uses default 5 days/week
        assert result["workouts_target"] == 5
        assert result["days_per_week"] == 5

    def test_checkpoint_fallback_monthly_uses_formula(self, mock_supabase_db, mock_current_user):
        """Test that monthly fallback uses ceil(5 * 4.3) = 22."""
        from api.v1.xp import get_checkpoint_progress

        # Mock RPC returning None (fallback case)
        mock_supabase_db.client.rpc.return_value.execute.return_value.data = None

        with patch("api.v1.xp.get_current_user", return_value=mock_current_user):
            result = asyncio.get_event_loop().run_until_complete(
                get_checkpoint_progress("monthly", mock_current_user)
            )

        # Fallback: ceil(5 * 4.3) = 22
        assert result["workouts_target"] == 22
        assert result["days_per_week"] == 5

    def test_dynamic_target_formula_calculation(self):
        """Test the dynamic target formula calculation."""
        import math

        # Formula: monthly_target = ceil(days_per_week * 4.3)
        test_cases = [
            (1, 1, 5),    # 1 day/week: weekly=1, monthly=ceil(1*4.3)=5
            (2, 2, 9),    # 2 days/week: weekly=2, monthly=ceil(2*4.3)=9
            (3, 3, 13),   # 3 days/week: weekly=3, monthly=ceil(3*4.3)=13
            (4, 4, 18),   # 4 days/week: weekly=4, monthly=ceil(4*4.3)=18
            (5, 5, 22),   # 5 days/week: weekly=5, monthly=ceil(5*4.3)=22
            (6, 6, 26),   # 6 days/week: weekly=6, monthly=ceil(6*4.3)=26
            (7, 7, 31),   # 7 days/week: weekly=7, monthly=ceil(7*4.3)=31
        ]

        for days_per_week, expected_weekly, expected_monthly in test_cases:
            calculated_weekly = days_per_week
            calculated_monthly = math.ceil(days_per_week * 4.3)
            assert calculated_weekly == expected_weekly, f"Weekly target mismatch for {days_per_week} days"
            assert calculated_monthly == expected_monthly, f"Monthly target mismatch for {days_per_week} days"
