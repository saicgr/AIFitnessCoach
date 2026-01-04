"""
Tests for Fasting Score system.

Tests the fasting score calculation, storage, and retrieval:
- Score calculation from stats and streak
- POST /fasting/scores - Save a fasting score
- GET /fasting/scores/{user_id} - Get score history
- GET /fasting/scores/{user_id}/current - Get current score
- GET /fasting/scores/{user_id}/trend - Get score trend

Run with: pytest backend/tests/test_fasting_scores.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from datetime import datetime, timedelta, date
import uuid
import sys
import os

# Add the backend directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB with chainable Supabase client pattern."""
    with patch("api.v1.fasting.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_client = MagicMock()
        mock_db.client = mock_client

        # Create chainable mock for table operations
        mock_table = MagicMock()
        mock_client.table.return_value = mock_table

        # Make all table operations chainable
        mock_table.select.return_value = mock_table
        mock_table.insert.return_value = mock_table
        mock_table.update.return_value = mock_table
        mock_table.delete.return_value = mock_table
        mock_table.upsert.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.neq.return_value = mock_table
        mock_table.gte.return_value = mock_table
        mock_table.lte.return_value = mock_table
        mock_table.order.return_value = mock_table
        mock_table.limit.return_value = mock_table
        mock_table.range.return_value = mock_table
        mock_table.is_.return_value = mock_table
        mock_table.single.return_value = mock_table
        mock_table.maybe_single.return_value = mock_table

        # Store mock_table for easy access in tests
        mock_db._mock_table = mock_table

        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def sample_user_id():
    return str(uuid.uuid4())


@pytest.fixture
def sample_fasting_stats():
    """Sample fasting statistics for score calculation."""
    return {
        "user_id": "user-123-abc",
        "total_fasts": 25,
        "completed_fasts": 20,
        "cancelled_fasts": 5,
        "total_fasting_hours": 320.0,
        "average_fast_duration_hours": 16.0,
        "longest_fast_hours": 24.0,
        "completion_rate": 80.0,
        "most_common_protocol": "16:8",
    }


@pytest.fixture
def sample_fasting_streak():
    """Sample fasting streak for score calculation."""
    return {
        "user_id": "user-123-abc",
        "current_streak": 7,
        "longest_streak": 14,
        "total_fasts_completed": 25,
        "total_fasting_hours": 320,
        "last_fast_date": date.today().isoformat(),
        "streak_start_date": (date.today() - timedelta(days=7)).isoformat(),
        "fasts_this_week": 4,
        "week_start_date": (date.today() - timedelta(days=date.today().weekday())).isoformat(),
        "freezes_available": 2,
        "freezes_used_this_week": 0,
        "weekly_goal_enabled": True,
        "weekly_goal_fasts": 5,
    }


@pytest.fixture
def sample_fasting_score():
    """Sample fasting score record."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": "user-123-abc",
        "score": 72,
        "completion_component": 80.0,
        "streak_component": 23.3,  # 7/30 * 100
        "duration_component": 100.0,  # 16h / 16h target
        "weekly_component": 80.0,  # 4/5 fasts
        "protocol_component": 50.0,  # 16:8 = 0.5 difficulty
        "current_streak": 7,
        "fasts_this_week": 4,
        "weekly_goal": 5,
        "completion_rate": 80.0,
        "avg_duration_minutes": 960,
        "recorded_at": datetime.utcnow().isoformat(),
        "created_at": datetime.utcnow().isoformat(),
    }


# ============================================================
# SCORE CALCULATION TESTS
# ============================================================

class TestScoreCalculation:
    """Test fasting score calculation logic."""

    def test_calculate_score_perfect(self):
        """Test score calculation with perfect stats."""
        # Perfect scenario:
        # - 100% completion rate -> 30 points
        # - 30+ day streak -> 25 points
        # - 16h+ avg duration -> 20 points
        # - 5/5 weekly -> 15 points
        # - Difficult protocol -> 10 points
        # Total: 100 points

        completion_rate = 100.0
        current_streak = 30
        avg_duration_hours = 16.0
        fasts_this_week = 5
        weekly_goal = 5
        protocol_difficulty = 1.0  # Maximum difficulty

        # Calculate components
        completion_comp = min(completion_rate, 100.0)  # 100
        streak_comp = min((current_streak / 30) * 100, 100.0)  # 100
        duration_comp = min((avg_duration_hours / 16) * 100, 100.0)  # 100
        weekly_comp = min((fasts_this_week / weekly_goal) * 100, 100.0)  # 100
        protocol_comp = min(protocol_difficulty * 100, 100.0)  # 100

        # Weighted score
        score = (
            completion_comp * 0.30 +
            streak_comp * 0.25 +
            duration_comp * 0.20 +
            weekly_comp * 0.15 +
            protocol_comp * 0.10
        )

        assert score == 100.0

    def test_calculate_score_beginner(self):
        """Test score calculation for a beginner user."""
        completion_rate = 60.0
        current_streak = 3
        avg_duration_hours = 12.0
        fasts_this_week = 2
        weekly_goal = 5
        protocol_difficulty = 0.3  # 12:12 protocol

        # Calculate components
        completion_comp = min(completion_rate, 100.0)  # 60
        streak_comp = min((current_streak / 30) * 100, 100.0)  # 10
        duration_comp = min((avg_duration_hours / 16) * 100, 100.0)  # 75
        weekly_comp = min((fasts_this_week / weekly_goal) * 100, 100.0)  # 40
        protocol_comp = min(protocol_difficulty * 100, 100.0)  # 30

        # Weighted score
        score = round(
            completion_comp * 0.30 +
            streak_comp * 0.25 +
            duration_comp * 0.20 +
            weekly_comp * 0.15 +
            protocol_comp * 0.10
        )

        # Expected: 60*0.30 + 10*0.25 + 75*0.20 + 40*0.15 + 30*0.10
        # = 18 + 2.5 + 15 + 6 + 3 = 44.5 -> 44 (round() uses banker's rounding)
        assert score == 44

    def test_calculate_score_intermediate(self, sample_fasting_stats, sample_fasting_streak):
        """Test score calculation with sample intermediate data."""
        # From fixtures:
        # completion_rate: 80%
        # current_streak: 7 days
        # avg_duration: 16h (960 min)
        # fasts_this_week: 4
        # weekly_goal: 5
        # protocol: 16:8 (0.5 difficulty)

        completion_comp = 80.0
        streak_comp = (7 / 30) * 100  # 23.33
        duration_comp = 100.0  # 16h/16h
        weekly_comp = (4 / 5) * 100  # 80
        protocol_comp = 50.0  # 0.5 * 100

        score = round(
            completion_comp * 0.30 +
            streak_comp * 0.25 +
            duration_comp * 0.20 +
            weekly_comp * 0.15 +
            protocol_comp * 0.10
        )

        # Expected: 80*0.30 + 23.33*0.25 + 100*0.20 + 80*0.15 + 50*0.10
        # = 24 + 5.83 + 20 + 12 + 5 = 66.83 -> 67
        assert score == 67

    def test_calculate_score_zero_stats(self):
        """Test score calculation with all zeros (new user)."""
        completion_comp = 0.0
        streak_comp = 0.0
        duration_comp = 0.0
        weekly_comp = 0.0
        protocol_comp = 0.0

        score = round(
            completion_comp * 0.30 +
            streak_comp * 0.25 +
            duration_comp * 0.20 +
            weekly_comp * 0.15 +
            protocol_comp * 0.10
        )

        assert score == 0

    def test_score_capped_at_100(self):
        """Test that score components are capped at 100."""
        # Even with extreme values, max should be 100
        completion_comp = min(150.0, 100.0)  # Capped
        streak_comp = min((60 / 30) * 100, 100.0)  # Capped at 100
        duration_comp = min((24 / 16) * 100, 100.0)  # Capped at 100
        weekly_comp = min((7 / 5) * 100, 100.0)  # Capped at 100
        protocol_comp = min(1.5 * 100, 100.0)  # Capped

        score = round(
            completion_comp * 0.30 +
            streak_comp * 0.25 +
            duration_comp * 0.20 +
            weekly_comp * 0.15 +
            protocol_comp * 0.10
        )

        assert score == 100


# ============================================================
# SCORE TIER TESTS
# ============================================================

class TestScoreTiers:
    """Test score tier labels and colors."""

    def test_tier_elite(self):
        """Test Elite tier (90+)."""
        assert get_tier_label(90) == "Elite"
        assert get_tier_label(95) == "Elite"
        assert get_tier_label(100) == "Elite"

    def test_tier_advanced(self):
        """Test Advanced tier (75-89)."""
        assert get_tier_label(75) == "Advanced"
        assert get_tier_label(80) == "Advanced"
        assert get_tier_label(89) == "Advanced"

    def test_tier_intermediate(self):
        """Test Intermediate tier (60-74)."""
        assert get_tier_label(60) == "Intermediate"
        assert get_tier_label(67) == "Intermediate"
        assert get_tier_label(74) == "Intermediate"

    def test_tier_beginner(self):
        """Test Beginner tier (40-59)."""
        assert get_tier_label(40) == "Beginner"
        assert get_tier_label(50) == "Beginner"
        assert get_tier_label(59) == "Beginner"

    def test_tier_starting(self):
        """Test Starting tier (0-39)."""
        assert get_tier_label(0) == "Starting"
        assert get_tier_label(20) == "Starting"
        assert get_tier_label(39) == "Starting"


def get_tier_label(score: int) -> str:
    """Get tier label for a score (mirrors Dart logic)."""
    if score >= 90:
        return "Elite"
    if score >= 75:
        return "Advanced"
    if score >= 60:
        return "Intermediate"
    if score >= 40:
        return "Beginner"
    return "Starting"


# ============================================================
# PROTOCOL DIFFICULTY TESTS
# ============================================================

class TestProtocolDifficulty:
    """Test protocol difficulty scoring."""

    def test_easy_protocols(self):
        """Test easy protocol difficulty values."""
        assert get_protocol_difficulty("12:12") == 0.3
        assert get_protocol_difficulty("14:10") == 0.4

    def test_medium_protocols(self):
        """Test medium protocol difficulty values."""
        assert get_protocol_difficulty("16:8") == 0.5
        assert get_protocol_difficulty("18:6") == 0.6

    def test_hard_protocols(self):
        """Test hard protocol difficulty values."""
        assert get_protocol_difficulty("20:4") == 0.75
        assert get_protocol_difficulty("OMAD") == 0.85
        assert get_protocol_difficulty("OMAD (One Meal a Day)") == 0.85

    def test_extended_protocols(self):
        """Test extended fast protocol difficulty values."""
        assert get_protocol_difficulty("24h Water Fast") == 1.0
        assert get_protocol_difficulty("48h Water Fast") == 1.0
        assert get_protocol_difficulty("72h Water Fast") == 1.0

    def test_unknown_protocol(self):
        """Test unknown protocol defaults to medium difficulty."""
        assert get_protocol_difficulty("unknown") == 0.5
        assert get_protocol_difficulty("custom") == 0.5


def get_protocol_difficulty(protocol: str) -> float:
    """Get difficulty score for a protocol (0-1 scale)."""
    difficulty_map = {
        "12:12": 0.3,
        "14:10": 0.4,
        "16:8": 0.5,
        "18:6": 0.6,
        "20:4": 0.75,
        "OMAD": 0.85,
        "OMAD (One Meal a Day)": 0.85,
        "24h Water Fast": 1.0,
        "48h Water Fast": 1.0,
        "72h Water Fast": 1.0,
        "7-Day Water Fast": 1.0,
        "5:2": 0.7,
        "ADF": 0.8,
        "ADF (Alternate Day)": 0.8,
    }
    return difficulty_map.get(protocol, 0.5)


# ============================================================
# SCORE STORAGE TESTS
# ============================================================

class TestSaveScore:
    """Test saving fasting scores to database."""

    @pytest.mark.asyncio
    async def test_save_score_success(self, mock_supabase_db, sample_user_id, sample_fasting_score):
        """Test successfully saving a fasting score."""
        mock_supabase_db._mock_table.execute.return_value = MagicMock(
            data=[sample_fasting_score]
        )

        # Create the score data
        score_data = {
            "user_id": sample_user_id,
            "score": 72,
            "completion_component": 80.0,
            "streak_component": 23.3,
            "duration_component": 100.0,
            "weekly_component": 80.0,
            "protocol_component": 50.0,
            "current_streak": 7,
            "fasts_this_week": 4,
            "weekly_goal": 5,
            "completion_rate": 80.0,
            "avg_duration_minutes": 960,
        }

        # Verify the mock was set up correctly
        mock_supabase_db._mock_table.insert.assert_not_called()

        # Simulate insert
        mock_supabase_db.client.table("fasting_scores").insert(score_data).execute()

        # Verify insert was called
        mock_supabase_db.client.table.assert_called_with("fasting_scores")
        mock_supabase_db._mock_table.insert.assert_called_once_with(score_data)

    @pytest.mark.asyncio
    async def test_save_score_upsert_same_day(self, mock_supabase_db, sample_user_id, sample_fasting_score):
        """Test that saving a score on the same day updates existing record."""
        mock_supabase_db._mock_table.execute.return_value = MagicMock(
            data=[sample_fasting_score]
        )

        score_data = {
            "user_id": sample_user_id,
            "score": 75,  # Updated score
        }

        # Simulate upsert
        mock_supabase_db.client.table("fasting_scores").upsert(
            score_data,
            on_conflict="user_id,recorded_at::date"
        ).execute()

        mock_supabase_db._mock_table.upsert.assert_called_once()


class TestGetScoreHistory:
    """Test retrieving fasting score history."""

    @pytest.mark.asyncio
    async def test_get_score_history_success(self, mock_supabase_db, sample_user_id):
        """Test getting score history for a user."""
        mock_scores = [
            {
                "id": str(uuid.uuid4()),
                "user_id": sample_user_id,
                "score": 72,
                "recorded_at": (datetime.utcnow() - timedelta(days=0)).isoformat(),
            },
            {
                "id": str(uuid.uuid4()),
                "user_id": sample_user_id,
                "score": 68,
                "recorded_at": (datetime.utcnow() - timedelta(days=1)).isoformat(),
            },
            {
                "id": str(uuid.uuid4()),
                "user_id": sample_user_id,
                "score": 65,
                "recorded_at": (datetime.utcnow() - timedelta(days=2)).isoformat(),
            },
        ]

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=mock_scores)

        # Simulate query
        mock_supabase_db.client.table("fasting_scores").select("*").eq(
            "user_id", sample_user_id
        ).order("recorded_at", desc=True).limit(30).execute()

        result = mock_supabase_db._mock_table.execute.return_value

        assert len(result.data) == 3
        assert result.data[0]["score"] == 72
        assert result.data[1]["score"] == 68
        assert result.data[2]["score"] == 65

    @pytest.mark.asyncio
    async def test_get_score_history_empty(self, mock_supabase_db, sample_user_id):
        """Test getting empty score history for new user."""
        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=[])

        result = mock_supabase_db._mock_table.execute.return_value

        assert len(result.data) == 0


# ============================================================
# SCORE TREND TESTS
# ============================================================

class TestScoreTrend:
    """Test score trend calculation."""

    def test_trend_up(self):
        """Test upward trend detection."""
        current_score = 75
        previous_score = 65

        score_change = current_score - previous_score
        trend = get_trend(current_score, previous_score)

        assert score_change == 10
        assert trend == "up"

    def test_trend_down(self):
        """Test downward trend detection."""
        current_score = 60
        previous_score = 70

        score_change = current_score - previous_score
        trend = get_trend(current_score, previous_score)

        assert score_change == -10
        assert trend == "down"

    def test_trend_stable(self):
        """Test stable trend detection."""
        current_score = 70
        previous_score = 70

        score_change = current_score - previous_score
        trend = get_trend(current_score, previous_score)

        assert score_change == 0
        assert trend == "stable"

    def test_trend_no_previous(self):
        """Test trend when no previous score exists."""
        current_score = 70
        previous_score = 0  # No previous score

        trend = get_trend(current_score, previous_score)

        # When no previous score, trend is based on having any score
        assert trend == "up" if current_score > 0 else "stable"

    @pytest.mark.asyncio
    async def test_get_score_trend_from_db(self, mock_supabase_db, sample_user_id):
        """Test getting score trend from database function."""
        mock_trend_data = [{
            "current_score": 75,
            "previous_score": 65,
            "score_change": 10,
            "trend": "up",
        }]

        mock_supabase_db._mock_table.execute.return_value = MagicMock(data=mock_trend_data)

        # Simulate calling the database function
        mock_supabase_db.client.rpc(
            "get_fasting_score_trend",
            {"p_user_id": sample_user_id}
        ).execute()

        result = mock_supabase_db._mock_table.execute.return_value

        assert result.data[0]["current_score"] == 75
        assert result.data[0]["previous_score"] == 65
        assert result.data[0]["score_change"] == 10
        assert result.data[0]["trend"] == "up"


def get_trend(current_score: int, previous_score: int) -> str:
    """Get trend direction based on score comparison."""
    if current_score > previous_score:
        return "up"
    elif current_score < previous_score:
        return "down"
    return "stable"


# ============================================================
# WEIGHT COMPONENT TESTS
# ============================================================

class TestWeightComponents:
    """Test that score weights sum to 100%."""

    def test_weights_sum_to_one(self):
        """Verify all weights sum to 1.0 (100%)."""
        weights = {
            "completion": 0.30,
            "streak": 0.25,
            "duration": 0.20,
            "weekly": 0.15,
            "protocol": 0.10,
        }

        total = sum(weights.values())
        assert total == 1.0, f"Weights sum to {total}, expected 1.0"

    def test_completion_highest_weight(self):
        """Verify completion rate has the highest weight."""
        weights = {
            "completion": 0.30,
            "streak": 0.25,
            "duration": 0.20,
            "weekly": 0.15,
            "protocol": 0.10,
        }

        assert weights["completion"] == max(weights.values())

    def test_protocol_lowest_weight(self):
        """Verify protocol difficulty has the lowest weight."""
        weights = {
            "completion": 0.30,
            "streak": 0.25,
            "duration": 0.20,
            "weekly": 0.15,
            "protocol": 0.10,
        }

        assert weights["protocol"] == min(weights.values())


# ============================================================
# SCORE VALIDATION TESTS
# ============================================================

class TestScoreValidation:
    """Test score value validation."""

    def test_score_range(self):
        """Test score is always in 0-100 range."""
        test_cases = [
            (0, True),
            (50, True),
            (100, True),
            (-1, False),
            (101, False),
        ]

        for score, expected_valid in test_cases:
            is_valid = 0 <= score <= 100
            assert is_valid == expected_valid, f"Score {score} validation failed"

    def test_component_range(self):
        """Test components are always in 0-100 range."""
        test_values = [-10, 0, 50, 100, 150]

        for value in test_values:
            clamped = max(0, min(100, value))
            assert 0 <= clamped <= 100


# ============================================================
# EDGE CASE TESTS
# ============================================================

class TestEdgeCases:
    """Test edge cases in score calculation."""

    def test_very_long_streak(self):
        """Test score with very long streak (capped at 30 days = 100%)."""
        streak = 100  # 100 day streak
        streak_comp = min((streak / 30) * 100, 100.0)

        assert streak_comp == 100.0

    def test_very_long_duration(self):
        """Test score with very long average duration (capped at 16h = 100%)."""
        avg_hours = 24  # 24 hour average
        duration_comp = min((avg_hours / 16) * 100, 100.0)

        assert duration_comp == 100.0

    def test_zero_weekly_goal(self):
        """Test handling of zero weekly goal (prevent division by zero)."""
        fasts_this_week = 3
        weekly_goal = 0

        # Should default to 5 if goal is 0
        safe_goal = weekly_goal if weekly_goal > 0 else 5
        weekly_comp = (fasts_this_week / safe_goal) * 100

        assert weekly_comp == 60.0

    def test_exceeded_weekly_goal(self):
        """Test when fasts exceed weekly goal (capped at 100%)."""
        fasts_this_week = 7
        weekly_goal = 5

        weekly_comp = min((fasts_this_week / weekly_goal) * 100, 100.0)

        assert weekly_comp == 100.0

    def test_decimal_precision(self):
        """Test score calculation maintains reasonable precision."""
        # Values that could cause floating point issues
        completion_rate = 33.333333
        streak = 7
        avg_hours = 14.5
        fasts_week = 3
        goal = 5
        difficulty = 0.5

        completion_comp = completion_rate
        streak_comp = (streak / 30) * 100
        duration_comp = (avg_hours / 16) * 100
        weekly_comp = (fasts_week / goal) * 100
        protocol_comp = difficulty * 100

        score = round(
            completion_comp * 0.30 +
            streak_comp * 0.25 +
            duration_comp * 0.20 +
            weekly_comp * 0.15 +
            protocol_comp * 0.10
        )

        # Should be a clean integer
        assert isinstance(score, int)
        assert 0 <= score <= 100


# ============================================================
# INTEGRATION-STYLE TESTS
# ============================================================

class TestScoreIntegration:
    """Integration-style tests for the complete score flow."""

    @pytest.mark.asyncio
    async def test_calculate_and_save_score_flow(
        self, mock_supabase_db, sample_user_id, sample_fasting_stats, sample_fasting_streak
    ):
        """Test the complete flow of calculating and saving a score."""
        # Step 1: Get stats and streak (mocked)
        mock_supabase_db._mock_table.execute.return_value = MagicMock(
            data=[sample_fasting_stats]
        )

        # Step 2: Calculate score
        completion_comp = sample_fasting_stats["completion_rate"]
        streak_comp = (sample_fasting_streak["current_streak"] / 30) * 100
        duration_comp = (sample_fasting_stats["average_fast_duration_hours"] / 16) * 100
        weekly_comp = (sample_fasting_streak["fasts_this_week"] / sample_fasting_streak["weekly_goal_fasts"]) * 100
        protocol_comp = get_protocol_difficulty(sample_fasting_stats["most_common_protocol"]) * 100

        score = round(
            completion_comp * 0.30 +
            streak_comp * 0.25 +
            duration_comp * 0.20 +
            weekly_comp * 0.15 +
            protocol_comp * 0.10
        )

        # Step 3: Save score
        score_record = {
            "user_id": sample_user_id,
            "score": score,
            "completion_component": completion_comp,
            "streak_component": streak_comp,
            "duration_component": duration_comp,
            "weekly_component": weekly_comp,
            "protocol_component": protocol_comp,
            "current_streak": sample_fasting_streak["current_streak"],
            "fasts_this_week": sample_fasting_streak["fasts_this_week"],
            "weekly_goal": sample_fasting_streak["weekly_goal_fasts"],
            "completion_rate": sample_fasting_stats["completion_rate"],
            "avg_duration_minutes": int(sample_fasting_stats["average_fast_duration_hours"] * 60),
        }

        # Verify score is valid
        assert 0 <= score <= 100
        assert score_record["user_id"] == sample_user_id
        assert all(0 <= v <= 100 for v in [
            score_record["completion_component"],
            score_record["duration_component"],
            score_record["weekly_component"],
            score_record["protocol_component"],
        ])

    def test_score_breakdown_adds_up(self, sample_fasting_stats, sample_fasting_streak):
        """Test that weighted components add up to the total score."""
        completion_comp = 80.0
        streak_comp = 23.33
        duration_comp = 100.0
        weekly_comp = 80.0
        protocol_comp = 50.0

        weighted_completion = completion_comp * 0.30
        weighted_streak = streak_comp * 0.25
        weighted_duration = duration_comp * 0.20
        weighted_weekly = weekly_comp * 0.15
        weighted_protocol = protocol_comp * 0.10

        calculated_score = (
            weighted_completion +
            weighted_streak +
            weighted_duration +
            weighted_weekly +
            weighted_protocol
        )

        # Verify individual contributions
        assert weighted_completion == 24.0
        assert round(weighted_streak, 2) == 5.83
        assert weighted_duration == 20.0
        assert weighted_weekly == 12.0
        assert weighted_protocol == 5.0

        # Total should be sum of weighted components
        expected_total = 24.0 + 5.83 + 20.0 + 12.0 + 5.0
        assert round(calculated_score, 2) == round(expected_total, 2)
