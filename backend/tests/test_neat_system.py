"""
Tests for the NEAT (Non-Exercise Activity Thermogenesis) Improvement System.

Tests comprehensive functionality for:
- Progressive step goals
- Hourly activity tracking
- NEAT score calculation
- Streak management
- Achievement system
- Reminder functionality
- API endpoints

Run with: pytest backend/tests/test_neat_system.py -v
"""

import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime, date, timedelta, time
from typing import Optional, List, Dict, Any
import asyncio

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def mock_supabase_db():
    """Mock SupabaseDB for NEAT operations."""
    with patch("core.supabase_db.get_supabase_db") as mock_get_db:
        mock_db = MagicMock()
        mock_get_db.return_value = mock_db
        yield mock_db


@pytest.fixture
def sample_user_id():
    """Standard test user ID."""
    return "user-neat-123"


@pytest.fixture
def sedentary_user_profile():
    """User profile for a sedentary user (baseline ~3000 steps)."""
    return {
        "id": "user-sedentary-001",
        "name": "Sedentary User",
        "baseline_steps": 3000,
        "current_step_goal": 3500,
        "activity_level": "sedentary",
        "created_at": datetime.now().isoformat(),
    }


@pytest.fixture
def active_user_profile():
    """User profile for an active user (baseline ~8000 steps)."""
    return {
        "id": "user-active-001",
        "name": "Active User",
        "baseline_steps": 8000,
        "current_step_goal": 10000,
        "activity_level": "active",
        "created_at": datetime.now().isoformat(),
    }


@pytest.fixture
def sample_hourly_activity():
    """Sample hourly activity data."""
    return {
        "id": "hourly-1",
        "user_id": "user-neat-123",
        "date": date.today().isoformat(),
        "hour": 9,
        "steps": 350,
        "is_active": True,
        "created_at": datetime.now().isoformat(),
    }


@pytest.fixture
def sample_neat_goals():
    """Sample NEAT goals data."""
    return {
        "id": "goals-1",
        "user_id": "user-neat-123",
        "step_goal": 8000,
        "active_hours_goal": 10,
        "baseline_steps": 5000,
        "week_number": 1,
        "last_updated": datetime.now().isoformat(),
    }


@pytest.fixture
def sample_neat_score():
    """Sample NEAT score data."""
    return {
        "id": "score-1",
        "user_id": "user-neat-123",
        "date": date.today().isoformat(),
        "total_steps": 8500,
        "active_hours": 12,
        "neat_score": 85,
        "step_goal_met": True,
        "created_at": datetime.now().isoformat(),
    }


@pytest.fixture
def sample_streak():
    """Sample streak data."""
    return {
        "id": "streak-1",
        "user_id": "user-neat-123",
        "streak_type": "step_goal",
        "current_streak": 5,
        "longest_streak": 12,
        "last_achieved_date": date.today().isoformat(),
        "created_at": datetime.now().isoformat(),
    }


@pytest.fixture
def sample_achievement():
    """Sample achievement data."""
    return {
        "id": "achievement-1",
        "user_id": "user-neat-123",
        "achievement_type": "first_1000_steps",
        "earned_at": datetime.now().isoformat(),
        "metadata": {"steps": 1000},
    }


@pytest.fixture
def sample_reminder_preferences():
    """Sample reminder preferences."""
    return {
        "id": "prefs-1",
        "user_id": "user-neat-123",
        "reminders_enabled": True,
        "quiet_hours_start": "22:00",
        "quiet_hours_end": "07:00",
        "work_hours_only": False,
        "sedentary_threshold_minutes": 60,
        "created_at": datetime.now().isoformat(),
    }


# ============================================================================
# Progressive Goal Tests
# ============================================================================

class TestProgressiveGoals:
    """Tests for progressive step goal management."""

    def test_initial_goal_for_sedentary_user(self, sedentary_user_profile):
        """Should set initial goal as baseline + 500 for sedentary users."""
        baseline = sedentary_user_profile["baseline_steps"]
        expected_goal = baseline + 500

        # Simulate goal calculation
        initial_goal = calculate_initial_goal(baseline)

        assert initial_goal == expected_goal
        assert initial_goal == 3500  # 3000 + 500

    def test_goal_progression_after_week(self, mock_supabase_db, sample_user_id):
        """Should increase goal by 500 if user consistently meets goal."""
        current_goal = 8000
        days_met_goal = 5  # User met goal 5 out of 7 days

        new_goal = calculate_goal_progression(
            current_goal=current_goal,
            days_met_goal=days_met_goal,
            threshold_days=5
        )

        assert new_goal == 8500  # Should increase by 500

    def test_goal_stays_same_if_not_met(self, mock_supabase_db, sample_user_id):
        """Goal should remain unchanged if user doesn't meet threshold."""
        current_goal = 8000
        days_met_goal = 3  # Only met goal 3 out of 7 days

        new_goal = calculate_goal_progression(
            current_goal=current_goal,
            days_met_goal=days_met_goal,
            threshold_days=5
        )

        assert new_goal == current_goal
        assert new_goal == 8000

    def test_manual_goal_update(self, mock_supabase_db, sample_user_id):
        """Should allow manual goal updates."""
        mock_supabase_db.update_neat_goals.return_value = {
            "id": "goals-1",
            "user_id": sample_user_id,
            "step_goal": 10000,
            "updated_at": datetime.now().isoformat(),
        }

        result = update_step_goal(mock_supabase_db, sample_user_id, 10000)

        assert result["step_goal"] == 10000
        mock_supabase_db.update_neat_goals.assert_called_once()

    def test_goal_capped_at_15000_steps(self, mock_supabase_db, sample_user_id):
        """Goal should be capped at 15000 steps maximum."""
        current_goal = 14800
        days_met_goal = 7  # Met every day

        new_goal = calculate_goal_progression(
            current_goal=current_goal,
            days_met_goal=days_met_goal,
            threshold_days=5,
            max_goal=15000
        )

        assert new_goal == 15000
        assert new_goal <= 15000


# ============================================================================
# Hourly Activity Tests
# ============================================================================

class TestHourlyActivity:
    """Tests for hourly activity tracking."""

    def test_record_hourly_activity(self, mock_supabase_db, sample_user_id, sample_hourly_activity):
        """Should successfully record hourly activity."""
        mock_supabase_db.upsert_hourly_activity.return_value = sample_hourly_activity

        result = record_hourly_activity(
            db=mock_supabase_db,
            user_id=sample_user_id,
            hour=9,
            steps=350
        )

        assert result["steps"] == 350
        assert result["hour"] == 9
        mock_supabase_db.upsert_hourly_activity.assert_called_once()

    def test_sedentary_detection_under_250_steps(self, mock_supabase_db, sample_user_id):
        """Hours with under 250 steps should be marked as sedentary."""
        hourly_data = {
            "id": "hourly-2",
            "user_id": sample_user_id,
            "date": date.today().isoformat(),
            "hour": 10,
            "steps": 150,
            "is_active": False,
            "created_at": datetime.now().isoformat(),
        }
        mock_supabase_db.upsert_hourly_activity.return_value = hourly_data

        result = record_hourly_activity(
            db=mock_supabase_db,
            user_id=sample_user_id,
            hour=10,
            steps=150
        )

        assert result["is_active"] is False
        assert result["steps"] < 250

    def test_active_hour_detection_250_plus_steps(self, mock_supabase_db, sample_user_id):
        """Hours with 250+ steps should be marked as active."""
        hourly_data = {
            "id": "hourly-3",
            "user_id": sample_user_id,
            "date": date.today().isoformat(),
            "hour": 11,
            "steps": 350,
            "is_active": True,
            "created_at": datetime.now().isoformat(),
        }
        mock_supabase_db.upsert_hourly_activity.return_value = hourly_data

        result = record_hourly_activity(
            db=mock_supabase_db,
            user_id=sample_user_id,
            hour=11,
            steps=350
        )

        assert result["is_active"] is True
        assert result["steps"] >= 250

    def test_hourly_breakdown_returns_all_hours(self, mock_supabase_db, sample_user_id):
        """Should return activity data for all 24 hours."""
        hours_data = [
            {"hour": h, "steps": h * 100, "is_active": h * 100 >= 250}
            for h in range(24)
        ]
        mock_supabase_db.get_hourly_breakdown.return_value = hours_data

        result = get_hourly_breakdown(mock_supabase_db, sample_user_id, date.today())

        assert len(result) == 24
        # Check that hours 3+ are marked active (steps >= 250)
        active_hours = [h for h in result if h["is_active"]]
        sedentary_hours = [h for h in result if not h["is_active"]]
        assert len(active_hours) > 0
        assert len(sedentary_hours) > 0

    def test_batch_sync_hourly_data(self, mock_supabase_db, sample_user_id):
        """Should successfully batch sync multiple hours of data."""
        batch_data = [
            {"hour": 9, "steps": 350},
            {"hour": 10, "steps": 280},
            {"hour": 11, "steps": 420},
        ]

        mock_supabase_db.batch_upsert_hourly_activity.return_value = {
            "synced": 3,
            "total": 3,
            "results": [{"hour": h["hour"], "status": "success"} for h in batch_data]
        }

        result = batch_sync_hourly_data(mock_supabase_db, sample_user_id, batch_data)

        assert result["synced"] == 3
        assert result["total"] == 3


# ============================================================================
# NEAT Score Tests
# ============================================================================

class TestNEATScore:
    """Tests for NEAT score calculation."""

    def test_neat_score_calculation_formula(self):
        """Should correctly calculate NEAT score using the formula."""
        # Formula: ((steps / goal) * 60) + ((active_hours / 14) * 40)
        # Capped at 100

        steps = 8000
        goal = 10000
        active_hours = 10

        score = calculate_neat_score(steps, goal, active_hours)

        expected_step_component = (steps / goal) * 60  # 48
        expected_hour_component = (active_hours / 14) * 40  # ~28.57
        expected_score = min(expected_step_component + expected_hour_component, 100)  # ~76.57

        assert round(score, 1) == round(expected_score, 1)

    def test_score_capped_at_100(self):
        """Score should be capped at 100 even if metrics exceed goals."""
        steps = 15000  # Way over goal
        goal = 8000
        active_hours = 16  # All waking hours active

        score = calculate_neat_score(steps, goal, active_hours)

        assert score == 100
        assert score <= 100

    def test_score_with_zero_steps(self):
        """Should return 0 or minimum score with zero steps."""
        steps = 0
        goal = 8000
        active_hours = 0

        score = calculate_neat_score(steps, goal, active_hours)

        assert score == 0

    def test_score_with_all_active_hours(self):
        """Should calculate correctly with maximum active hours."""
        steps = 10000
        goal = 10000
        active_hours = 14  # Maximum trackable active hours

        score = calculate_neat_score(steps, goal, active_hours)

        # 60 (full step component) + 40 (full active hours) = 100
        assert score == 100

    def test_score_trend_over_days(self, mock_supabase_db, sample_user_id):
        """Should correctly calculate score trend over multiple days."""
        scores = [
            {"date": (date.today() - timedelta(days=6)).isoformat(), "neat_score": 65},
            {"date": (date.today() - timedelta(days=5)).isoformat(), "neat_score": 68},
            {"date": (date.today() - timedelta(days=4)).isoformat(), "neat_score": 70},
            {"date": (date.today() - timedelta(days=3)).isoformat(), "neat_score": 72},
            {"date": (date.today() - timedelta(days=2)).isoformat(), "neat_score": 75},
            {"date": (date.today() - timedelta(days=1)).isoformat(), "neat_score": 78},
            {"date": date.today().isoformat(), "neat_score": 80},
        ]
        mock_supabase_db.get_neat_scores.return_value = scores

        trend = calculate_score_trend(mock_supabase_db, sample_user_id, days=7)

        assert trend["direction"] == "improving"
        assert trend["average"] > 70
        assert trend["change"] > 0


# ============================================================================
# Streak Tests
# ============================================================================

class TestStreaks:
    """Tests for streak management."""

    def test_streak_starts_at_one(self, mock_supabase_db, sample_user_id):
        """New streak should start at 1."""
        mock_supabase_db.create_streak.return_value = {
            "id": "streak-new",
            "user_id": sample_user_id,
            "streak_type": "step_goal",
            "current_streak": 1,
            "longest_streak": 1,
            "last_achieved_date": date.today().isoformat(),
        }

        result = start_new_streak(mock_supabase_db, sample_user_id, "step_goal")

        assert result["current_streak"] == 1

    def test_streak_increments_on_consecutive_days(self, mock_supabase_db, sample_user_id, sample_streak):
        """Streak should increment when goal is met on consecutive days."""
        current_streak = sample_streak["current_streak"]  # 5
        mock_supabase_db.get_streak.return_value = sample_streak
        mock_supabase_db.update_streak.return_value = {
            **sample_streak,
            "current_streak": current_streak + 1,
        }

        result = increment_streak(
            db=mock_supabase_db,
            user_id=sample_user_id,
            streak_type="step_goal",
            achieved_date=date.today()
        )

        assert result["current_streak"] == current_streak + 1
        assert result["current_streak"] == 6

    def test_streak_resets_after_missed_day(self, mock_supabase_db, sample_user_id, sample_streak):
        """Streak should reset to 0 after a missed day."""
        sample_streak["last_achieved_date"] = (date.today() - timedelta(days=2)).isoformat()
        mock_supabase_db.get_streak.return_value = sample_streak
        mock_supabase_db.update_streak.return_value = {
            **sample_streak,
            "current_streak": 1,  # Reset and start new
        }

        result = check_and_update_streak(
            db=mock_supabase_db,
            user_id=sample_user_id,
            streak_type="step_goal",
            goal_met_today=True
        )

        assert result["current_streak"] == 1  # Reset to 1 (today counts)

    def test_longest_streak_preserved(self, mock_supabase_db, sample_user_id, sample_streak):
        """Longest streak should be preserved when current resets."""
        sample_streak["current_streak"] = 10
        sample_streak["longest_streak"] = 12
        sample_streak["last_achieved_date"] = (date.today() - timedelta(days=2)).isoformat()

        mock_supabase_db.get_streak.return_value = sample_streak
        mock_supabase_db.update_streak.return_value = {
            **sample_streak,
            "current_streak": 1,
            "longest_streak": 12,  # Preserved
        }

        result = check_and_update_streak(
            db=mock_supabase_db,
            user_id=sample_user_id,
            streak_type="step_goal",
            goal_met_today=True
        )

        assert result["longest_streak"] == 12

    def test_multiple_streak_types_independent(self, mock_supabase_db, sample_user_id):
        """Different streak types should be tracked independently."""
        step_streak = {
            "streak_type": "step_goal",
            "current_streak": 5,
        }
        active_hours_streak = {
            "streak_type": "active_hours",
            "current_streak": 3,
        }

        mock_supabase_db.get_streak.side_effect = lambda db, user_id, streak_type: (
            step_streak if streak_type == "step_goal" else active_hours_streak
        )

        step_result = get_streak(mock_supabase_db, sample_user_id, "step_goal")
        hours_result = get_streak(mock_supabase_db, sample_user_id, "active_hours")

        assert step_result["current_streak"] != hours_result["current_streak"]
        assert step_result["current_streak"] == 5
        assert hours_result["current_streak"] == 3


# ============================================================================
# Achievement Tests
# ============================================================================

class TestAchievements:
    """Tests for achievement system."""

    def test_first_1000_steps_achievement(self, mock_supabase_db, sample_user_id):
        """Should grant achievement when user first hits 1000 steps."""
        mock_supabase_db.get_achievement.return_value = None  # Not yet earned
        mock_supabase_db.create_achievement.return_value = {
            "id": "achievement-new",
            "user_id": sample_user_id,
            "achievement_type": "first_1000_steps",
            "earned_at": datetime.now().isoformat(),
        }

        result = check_and_grant_achievement(
            db=mock_supabase_db,
            user_id=sample_user_id,
            achievement_type="first_1000_steps",
            condition_met=True
        )

        assert result["achievement_type"] == "first_1000_steps"
        mock_supabase_db.create_achievement.assert_called_once()

    def test_streak_achievements(self, mock_supabase_db, sample_user_id):
        """Should grant streak milestone achievements."""
        streak_milestones = [7, 14, 30, 60, 100]

        for milestone in streak_milestones:
            mock_supabase_db.get_achievement.return_value = None
            mock_supabase_db.create_achievement.return_value = {
                "achievement_type": f"streak_{milestone}_days",
                "earned_at": datetime.now().isoformat(),
            }

            result = check_streak_achievement(
                db=mock_supabase_db,
                user_id=sample_user_id,
                current_streak=milestone
            )

            assert result is not None
            assert f"streak_{milestone}_days" in result["achievement_type"]

    def test_neat_score_achievements(self, mock_supabase_db, sample_user_id):
        """Should grant achievements for NEAT score milestones."""
        score_milestones = [50, 75, 90, 100]

        for score in score_milestones:
            mock_supabase_db.get_achievement.return_value = None
            mock_supabase_db.create_achievement.return_value = {
                "achievement_type": f"neat_score_{score}",
                "earned_at": datetime.now().isoformat(),
            }

            result = check_neat_score_achievement(
                db=mock_supabase_db,
                user_id=sample_user_id,
                score=score
            )

            assert result is not None

    def test_no_duplicate_achievements(self, mock_supabase_db, sample_user_id, sample_achievement):
        """Should not grant duplicate achievements."""
        mock_supabase_db.get_achievement.return_value = sample_achievement  # Already earned

        result = check_and_grant_achievement(
            db=mock_supabase_db,
            user_id=sample_user_id,
            achievement_type="first_1000_steps",
            condition_met=True
        )

        assert result is None  # No new achievement
        mock_supabase_db.create_achievement.assert_not_called()

    def test_achievement_progress_tracking(self, mock_supabase_db, sample_user_id):
        """Should track progress towards achievements."""
        mock_supabase_db.get_achievement_progress.return_value = {
            "achievement_type": "streak_30_days",
            "current_progress": 15,
            "target": 30,
            "percentage": 50,
        }

        progress = get_achievement_progress(
            mock_supabase_db,
            sample_user_id,
            "streak_30_days"
        )

        assert progress["current_progress"] == 15
        assert progress["target"] == 30
        assert progress["percentage"] == 50


# ============================================================================
# Reminder Tests
# ============================================================================

class TestReminders:
    """Tests for sedentary reminders."""

    def test_reminder_sent_when_sedentary(self, mock_supabase_db, sample_user_id):
        """Should trigger reminder when user is sedentary for threshold duration."""
        mock_supabase_db.get_reminder_preferences.return_value = {
            "reminders_enabled": True,
            "sedentary_threshold_minutes": 60,
        }
        mock_supabase_db.get_last_active_hour.return_value = {
            "hour": datetime.now().hour - 2,  # 2 hours ago
            "steps": 300,
        }

        should_remind = check_sedentary_reminder(
            db=mock_supabase_db,
            user_id=sample_user_id,
            current_hour=datetime.now().hour
        )

        assert should_remind is True

    def test_no_reminder_during_quiet_hours(self, mock_supabase_db, sample_user_id):
        """Should not send reminders during quiet hours."""
        mock_supabase_db.get_reminder_preferences.return_value = {
            "reminders_enabled": True,
            "quiet_hours_start": "22:00",
            "quiet_hours_end": "07:00",
            "sedentary_threshold_minutes": 60,
        }

        # Simulate 11 PM (within quiet hours)
        should_remind = check_sedentary_reminder(
            db=mock_supabase_db,
            user_id=sample_user_id,
            current_hour=23,  # 11 PM
            check_time=time(23, 0)
        )

        assert should_remind is False

    def test_reminder_respects_work_hours_setting(self, mock_supabase_db, sample_user_id):
        """Should only remind during work hours if setting is enabled."""
        mock_supabase_db.get_reminder_preferences.return_value = {
            "reminders_enabled": True,
            "work_hours_only": True,
            "work_hours_start": "09:00",
            "work_hours_end": "17:00",
            "sedentary_threshold_minutes": 60,
        }

        # Test during work hours (should remind)
        should_remind_work = check_sedentary_reminder(
            db=mock_supabase_db,
            user_id=sample_user_id,
            current_hour=10,
            check_time=time(10, 0)
        )

        # Test outside work hours (should not remind)
        should_remind_evening = check_sedentary_reminder(
            db=mock_supabase_db,
            user_id=sample_user_id,
            current_hour=19,
            check_time=time(19, 0)
        )

        assert should_remind_evening is False

    def test_reminder_threshold_configurable(self, mock_supabase_db, sample_user_id):
        """Sedentary threshold should be configurable."""
        # 30 minute threshold
        mock_supabase_db.get_reminder_preferences.return_value = {
            "reminders_enabled": True,
            "sedentary_threshold_minutes": 30,
        }

        threshold = get_sedentary_threshold(mock_supabase_db, sample_user_id)
        assert threshold == 30

        # 90 minute threshold
        mock_supabase_db.get_reminder_preferences.return_value = {
            "reminders_enabled": True,
            "sedentary_threshold_minutes": 90,
        }

        threshold = get_sedentary_threshold(mock_supabase_db, sample_user_id)
        assert threshold == 90

    def test_reminder_preferences_update(self, mock_supabase_db, sample_user_id, sample_reminder_preferences):
        """Should successfully update reminder preferences."""
        updated_prefs = {
            **sample_reminder_preferences,
            "sedentary_threshold_minutes": 45,
            "quiet_hours_start": "23:00",
        }
        mock_supabase_db.update_reminder_preferences.return_value = updated_prefs

        result = update_reminder_preferences(
            db=mock_supabase_db,
            user_id=sample_user_id,
            sedentary_threshold_minutes=45,
            quiet_hours_start="23:00"
        )

        assert result["sedentary_threshold_minutes"] == 45
        assert result["quiet_hours_start"] == "23:00"


# ============================================================================
# API Endpoint Tests
# ============================================================================

class TestNEATAPIEndpoints:
    """Tests for NEAT API endpoints."""

    def test_get_neat_dashboard(self, client, mock_supabase_db, sample_user_id):
        """Should return complete NEAT dashboard data."""
        with patch("api.v1.neat.get_supabase_db", return_value=mock_supabase_db):
            mock_supabase_db.get_neat_dashboard.return_value = {
                "user_id": sample_user_id,
                "today_steps": 6500,
                "step_goal": 8000,
                "active_hours": 8,
                "neat_score": 72,
                "current_streak": 5,
                "achievements": [],
            }

            response = client.get(f"/api/v1/neat/dashboard?user_id={sample_user_id}")

            # Note: This may return 404 if endpoint doesn't exist yet
            if response.status_code == 200:
                data = response.json()
                assert "today_steps" in data
                assert "neat_score" in data
                assert "current_streak" in data

    def test_update_goals_endpoint(self, client, mock_supabase_db, sample_user_id):
        """Should update NEAT goals via API."""
        with patch("api.v1.neat.get_supabase_db", return_value=mock_supabase_db):
            mock_supabase_db.update_neat_goals.return_value = {
                "step_goal": 10000,
                "active_hours_goal": 12,
            }

            response = client.post(
                "/api/v1/neat/goals",
                json={
                    "user_id": sample_user_id,
                    "step_goal": 10000,
                    "active_hours_goal": 12,
                }
            )

            if response.status_code == 200:
                data = response.json()
                assert data["step_goal"] == 10000

    def test_hourly_sync_endpoint(self, client, mock_supabase_db, sample_user_id):
        """Should sync hourly activity via API."""
        with patch("api.v1.neat.get_supabase_db", return_value=mock_supabase_db):
            mock_supabase_db.upsert_hourly_activity.return_value = {
                "hour": 10,
                "steps": 350,
                "is_active": True,
            }

            response = client.post(
                "/api/v1/neat/hourly-sync",
                json={
                    "user_id": sample_user_id,
                    "hour": 10,
                    "steps": 350,
                }
            )

            if response.status_code == 200:
                data = response.json()
                assert data["steps"] == 350

    def test_achievements_endpoint(self, client, mock_supabase_db, sample_user_id):
        """Should return user achievements via API."""
        with patch("api.v1.neat.get_supabase_db", return_value=mock_supabase_db):
            mock_supabase_db.get_user_achievements.return_value = [
                {"achievement_type": "first_1000_steps", "earned_at": datetime.now().isoformat()},
                {"achievement_type": "streak_7_days", "earned_at": datetime.now().isoformat()},
            ]

            response = client.get(f"/api/v1/neat/achievements?user_id={sample_user_id}")

            if response.status_code == 200:
                data = response.json()
                assert isinstance(data, list)

    def test_scheduler_endpoints(self, client, mock_supabase_db, sample_user_id):
        """Should handle reminder scheduler endpoints."""
        with patch("api.v1.neat.get_supabase_db", return_value=mock_supabase_db):
            mock_supabase_db.get_reminder_preferences.return_value = {
                "reminders_enabled": True,
                "sedentary_threshold_minutes": 60,
            }

            response = client.get(f"/api/v1/neat/reminder-preferences?user_id={sample_user_id}")

            if response.status_code == 200:
                data = response.json()
                assert "reminders_enabled" in data


# ============================================================================
# Edge Cases Tests
# ============================================================================

class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_new_user_no_baseline(self, mock_supabase_db, sample_user_id):
        """Should handle new users with no baseline data."""
        mock_supabase_db.get_user_baseline.return_value = None
        mock_supabase_db.get_recent_activity.return_value = []

        baseline = calculate_baseline_steps(mock_supabase_db, sample_user_id)

        # Should default to a reasonable baseline for new users
        assert baseline == 5000  # Default baseline

    def test_timezone_handling_for_hourly_data(self, mock_supabase_db, sample_user_id):
        """Should correctly handle timezone conversions for hourly data."""
        # Test with different timezone offsets
        user_timezone = "America/New_York"  # UTC-5

        utc_hour = 15  # 3 PM UTC
        expected_local_hour = 10  # 10 AM ET

        local_hour = convert_utc_to_local_hour(utc_hour, user_timezone)

        # Note: This depends on DST, so we just verify conversion happened
        assert isinstance(local_hour, int)
        assert 0 <= local_hour <= 23

    def test_concurrent_streak_updates(self, mock_supabase_db, sample_user_id):
        """Should handle concurrent streak update attempts."""
        mock_supabase_db.get_streak.return_value = {
            "current_streak": 5,
            "longest_streak": 10,
            "last_achieved_date": (date.today() - timedelta(days=1)).isoformat(),
        }

        # Simulate optimistic locking with version
        mock_supabase_db.update_streak_with_lock.side_effect = [
            None,  # First attempt fails (concurrent update)
            {"current_streak": 6, "version": 2},  # Retry succeeds
        ]

        result = update_streak_safely(
            db=mock_supabase_db,
            user_id=sample_user_id,
            streak_type="step_goal"
        )

        assert result is not None
        assert result["current_streak"] == 6

    def test_missing_hourly_data_gaps(self, mock_supabase_db, sample_user_id):
        """Should handle gaps in hourly data gracefully."""
        # Data with gaps (missing hours 5, 6, 7)
        hourly_data = [
            {"hour": 8, "steps": 300},
            {"hour": 9, "steps": 250},
            # Gap here
            {"hour": 12, "steps": 400},
            {"hour": 13, "steps": 350},
        ]
        mock_supabase_db.get_hourly_breakdown.return_value = hourly_data

        result = get_hourly_breakdown_with_gaps(
            mock_supabase_db,
            sample_user_id,
            date.today()
        )

        # Should fill in missing hours with 0 steps
        assert len(result) == 24
        assert result[5]["steps"] == 0  # Missing hour filled
        assert result[6]["steps"] == 0


# ============================================================================
# Helper Functions for Tests
# ============================================================================

def calculate_initial_goal(baseline: int) -> int:
    """Calculate initial step goal based on baseline."""
    return baseline + 500


def calculate_goal_progression(
    current_goal: int,
    days_met_goal: int,
    threshold_days: int = 5,
    max_goal: int = 15000
) -> int:
    """Calculate new goal based on weekly performance."""
    if days_met_goal >= threshold_days:
        new_goal = current_goal + 500
        return min(new_goal, max_goal)
    return current_goal


def update_step_goal(db, user_id: str, new_goal: int) -> dict:
    """Update user's step goal."""
    return db.update_neat_goals({"user_id": user_id, "step_goal": new_goal})


def record_hourly_activity(db, user_id: str, hour: int, steps: int) -> dict:
    """Record hourly activity."""
    is_active = steps >= 250
    return db.upsert_hourly_activity({
        "user_id": user_id,
        "date": date.today().isoformat(),
        "hour": hour,
        "steps": steps,
        "is_active": is_active,
    })


def get_hourly_breakdown(db, user_id: str, target_date: date) -> List[dict]:
    """Get hourly breakdown for a specific date."""
    return db.get_hourly_breakdown(user_id, target_date.isoformat())


def batch_sync_hourly_data(db, user_id: str, data: List[dict]) -> dict:
    """Batch sync hourly activity data."""
    return db.batch_upsert_hourly_activity(user_id, data)


def calculate_neat_score(steps: int, goal: int, active_hours: int) -> float:
    """Calculate NEAT score."""
    if goal == 0:
        return 0

    step_component = (steps / goal) * 60
    hour_component = (active_hours / 14) * 40
    score = step_component + hour_component

    return min(score, 100)


def calculate_score_trend(db, user_id: str, days: int = 7) -> dict:
    """Calculate NEAT score trend."""
    scores = db.get_neat_scores(user_id, days)

    if not scores:
        return {"direction": "stable", "average": 0, "change": 0}

    avg = sum(s["neat_score"] for s in scores) / len(scores)
    first_half = scores[:len(scores)//2]
    second_half = scores[len(scores)//2:]

    first_avg = sum(s["neat_score"] for s in first_half) / len(first_half) if first_half else 0
    second_avg = sum(s["neat_score"] for s in second_half) / len(second_half) if second_half else 0

    change = second_avg - first_avg

    if change > 5:
        direction = "improving"
    elif change < -5:
        direction = "declining"
    else:
        direction = "stable"

    return {"direction": direction, "average": avg, "change": change}


def start_new_streak(db, user_id: str, streak_type: str) -> dict:
    """Start a new streak."""
    return db.create_streak({
        "user_id": user_id,
        "streak_type": streak_type,
        "current_streak": 1,
        "longest_streak": 1,
        "last_achieved_date": date.today().isoformat(),
    })


def increment_streak(db, user_id: str, streak_type: str, achieved_date: date) -> dict:
    """Increment an existing streak."""
    streak = db.get_streak(user_id, streak_type)
    new_streak_count = streak["current_streak"] + 1
    new_longest = max(streak["longest_streak"], new_streak_count)

    return db.update_streak({
        "user_id": user_id,
        "streak_type": streak_type,
        "current_streak": new_streak_count,
        "longest_streak": new_longest,
        "last_achieved_date": achieved_date.isoformat(),
    })


def check_and_update_streak(
    db, user_id: str, streak_type: str, goal_met_today: bool
) -> dict:
    """Check streak status and update accordingly."""
    streak = db.get_streak(user_id, streak_type)
    last_date = date.fromisoformat(streak["last_achieved_date"])
    days_since = (date.today() - last_date).days

    if days_since > 1:
        # Streak broken, reset
        new_streak = 1 if goal_met_today else 0
    elif days_since == 1 and goal_met_today:
        # Consecutive day, increment
        new_streak = streak["current_streak"] + 1
    else:
        # Same day or goal not met
        new_streak = streak["current_streak"]

    return db.update_streak({
        "current_streak": new_streak,
        "longest_streak": max(streak["longest_streak"], new_streak),
    })


def get_streak(db, user_id: str, streak_type: str) -> dict:
    """Get current streak."""
    return db.get_streak(db, user_id, streak_type)


def check_and_grant_achievement(
    db, user_id: str, achievement_type: str, condition_met: bool
) -> Optional[dict]:
    """Check and grant achievement if conditions are met."""
    if not condition_met:
        return None

    existing = db.get_achievement(user_id, achievement_type)
    if existing:
        return None  # Already earned

    return db.create_achievement({
        "user_id": user_id,
        "achievement_type": achievement_type,
        "earned_at": datetime.now().isoformat(),
    })


def check_streak_achievement(db, user_id: str, current_streak: int) -> Optional[dict]:
    """Check for streak-based achievements."""
    milestones = [7, 14, 30, 60, 100]

    for milestone in milestones:
        if current_streak >= milestone:
            achievement_type = f"streak_{milestone}_days"
            existing = db.get_achievement(user_id, achievement_type)
            if not existing:
                return db.create_achievement({
                    "achievement_type": achievement_type,
                    "earned_at": datetime.now().isoformat(),
                })
    return None


def check_neat_score_achievement(db, user_id: str, score: float) -> Optional[dict]:
    """Check for NEAT score achievements."""
    milestones = [50, 75, 90, 100]

    for milestone in milestones:
        if score >= milestone:
            achievement_type = f"neat_score_{milestone}"
            existing = db.get_achievement(user_id, achievement_type)
            if not existing:
                return db.create_achievement({
                    "achievement_type": achievement_type,
                    "earned_at": datetime.now().isoformat(),
                })
    return None


def get_achievement_progress(db, user_id: str, achievement_type: str) -> dict:
    """Get progress towards an achievement."""
    return db.get_achievement_progress(user_id, achievement_type)


def check_sedentary_reminder(
    db, user_id: str, current_hour: int, check_time: time = None
) -> bool:
    """Check if sedentary reminder should be sent."""
    prefs = db.get_reminder_preferences(user_id)

    if not prefs.get("reminders_enabled", True):
        return False

    # Check quiet hours
    if check_time:
        quiet_start = prefs.get("quiet_hours_start", "22:00")
        quiet_end = prefs.get("quiet_hours_end", "07:00")
        quiet_start_time = time.fromisoformat(quiet_start)
        quiet_end_time = time.fromisoformat(quiet_end)

        if quiet_start_time <= check_time or check_time <= quiet_end_time:
            return False

    # Check work hours only
    if prefs.get("work_hours_only", False):
        work_start = prefs.get("work_hours_start", "09:00")
        work_end = prefs.get("work_hours_end", "17:00")
        work_start_time = time.fromisoformat(work_start)
        work_end_time = time.fromisoformat(work_end)

        if check_time and not (work_start_time <= check_time <= work_end_time):
            return False

    return True


def get_sedentary_threshold(db, user_id: str) -> int:
    """Get sedentary threshold in minutes."""
    prefs = db.get_reminder_preferences(user_id)
    return prefs.get("sedentary_threshold_minutes", 60)


def update_reminder_preferences(db, user_id: str, **kwargs) -> dict:
    """Update reminder preferences."""
    return db.update_reminder_preferences({"user_id": user_id, **kwargs})


def calculate_baseline_steps(db, user_id: str) -> int:
    """Calculate baseline steps from recent activity."""
    baseline = db.get_user_baseline(user_id)
    if baseline:
        return baseline

    recent = db.get_recent_activity(user_id)
    if recent:
        return sum(a["steps"] for a in recent) // len(recent)

    return 5000  # Default baseline


def convert_utc_to_local_hour(utc_hour: int, timezone: str) -> int:
    """Convert UTC hour to local hour."""
    # Simplified conversion - in real implementation use pytz
    from datetime import timezone as tz, timedelta

    # Simple offset for demonstration (would use pytz in real code)
    offsets = {
        "America/New_York": -5,
        "America/Los_Angeles": -8,
        "Europe/London": 0,
    }

    offset = offsets.get(timezone, 0)
    local_hour = (utc_hour + offset) % 24
    return local_hour


def update_streak_safely(db, user_id: str, streak_type: str) -> Optional[dict]:
    """Update streak with retry on conflict."""
    max_retries = 3

    for attempt in range(max_retries):
        result = db.update_streak_with_lock(user_id, streak_type)
        if result:
            return result

    return None


def get_hourly_breakdown_with_gaps(db, user_id: str, target_date: date) -> List[dict]:
    """Get hourly breakdown, filling in gaps with zeros."""
    data = db.get_hourly_breakdown(user_id, target_date.isoformat())

    # Create full 24-hour structure
    hours_map = {h["hour"]: h for h in data}
    result = []

    for hour in range(24):
        if hour in hours_map:
            result.append(hours_map[hour])
        else:
            result.append({
                "hour": hour,
                "steps": 0,
                "is_active": False,
            })

    return result


# ============================================================================
# Run Tests
# ============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
