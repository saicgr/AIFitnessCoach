"""
Tests for the Subjective Feedback API endpoints.

Tests the /api/v1/subjective-feedback/* endpoints that allow users
to track how they feel before and after workouts.

Run with: pytest tests/test_subjective_feedback.py -v
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime, timedelta

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.v1.subjective_feedback import (
    MoodLevel,
    EnergyLevel,
    PreWorkoutCheckinCreate,
    PostWorkoutCheckinCreate,
    SubjectiveFeedback,
    SubjectiveTrendsResponse,
    FeelResultsSummary,
    _compute_mood_change,
)


# ============================================================================
# Unit Tests for Helper Functions
# ============================================================================

class TestComputeMoodChange:
    """Tests for the _compute_mood_change helper function."""

    def test_positive_mood_change(self):
        """Should calculate positive mood change correctly."""
        record = {"mood_before": 2, "mood_after": 4}
        result = _compute_mood_change(record)
        assert result == 2

    def test_negative_mood_change(self):
        """Should calculate negative mood change correctly."""
        record = {"mood_before": 4, "mood_after": 3}
        result = _compute_mood_change(record)
        assert result == -1

    def test_no_change(self):
        """Should return 0 when mood is the same."""
        record = {"mood_before": 3, "mood_after": 3}
        result = _compute_mood_change(record)
        assert result == 0

    def test_missing_mood_before(self):
        """Should return None when mood_before is missing."""
        record = {"mood_after": 4}
        result = _compute_mood_change(record)
        assert result is None

    def test_missing_mood_after(self):
        """Should return None when mood_after is missing."""
        record = {"mood_before": 3}
        result = _compute_mood_change(record)
        assert result is None

    def test_both_missing(self):
        """Should return None when both are missing."""
        record = {}
        result = _compute_mood_change(record)
        assert result is None


# ============================================================================
# Enum Tests
# ============================================================================

class TestMoodLevelEnum:
    """Tests for the MoodLevel enum."""

    def test_all_levels_defined(self):
        """Should have all expected mood levels."""
        assert MoodLevel.AWFUL.value == 1
        assert MoodLevel.LOW.value == 2
        assert MoodLevel.NEUTRAL.value == 3
        assert MoodLevel.GOOD.value == 4
        assert MoodLevel.GREAT.value == 5


class TestEnergyLevelEnum:
    """Tests for the EnergyLevel enum."""

    def test_all_levels_defined(self):
        """Should have all expected energy levels."""
        assert EnergyLevel.EXHAUSTED.value == 1
        assert EnergyLevel.TIRED.value == 2
        assert EnergyLevel.OKAY.value == 3
        assert EnergyLevel.ENERGIZED.value == 4
        assert EnergyLevel.PUMPED.value == 5


# ============================================================================
# Pydantic Model Tests
# ============================================================================

class TestPreWorkoutCheckinCreateModel:
    """Tests for the PreWorkoutCheckinCreate model."""

    def test_required_fields(self):
        """Should require user_id and mood_before."""
        checkin = PreWorkoutCheckinCreate(
            user_id="test-user",
            mood_before=3,
        )
        assert checkin.user_id == "test-user"
        assert checkin.mood_before == 3

    def test_optional_fields(self):
        """Should accept all optional fields."""
        checkin = PreWorkoutCheckinCreate(
            user_id="test-user",
            workout_id="workout-123",
            mood_before=3,
            energy_before=4,
            sleep_quality=4,
            stress_level=2,
        )
        assert checkin.workout_id == "workout-123"
        assert checkin.energy_before == 4
        assert checkin.sleep_quality == 4
        assert checkin.stress_level == 2

    def test_mood_before_validation(self):
        """Should validate mood_before is between 1 and 5."""
        with pytest.raises(Exception):
            PreWorkoutCheckinCreate(
                user_id="test-user",
                mood_before=0,  # Invalid - too low
            )

        with pytest.raises(Exception):
            PreWorkoutCheckinCreate(
                user_id="test-user",
                mood_before=6,  # Invalid - too high
            )


class TestPostWorkoutCheckinCreateModel:
    """Tests for the PostWorkoutCheckinCreate model."""

    def test_required_fields(self):
        """Should require user_id, workout_id, and mood_after."""
        checkin = PostWorkoutCheckinCreate(
            user_id="test-user",
            workout_id="workout-123",
            mood_after=4,
        )
        assert checkin.user_id == "test-user"
        assert checkin.workout_id == "workout-123"
        assert checkin.mood_after == 4

    def test_optional_fields(self):
        """Should accept all optional fields."""
        checkin = PostWorkoutCheckinCreate(
            user_id="test-user",
            workout_id="workout-123",
            mood_after=4,
            energy_after=4,
            confidence_level=5,
            soreness_level=2,
            feeling_stronger=True,
            notes="Great workout!",
        )
        assert checkin.energy_after == 4
        assert checkin.feeling_stronger is True
        assert checkin.notes == "Great workout!"

    def test_notes_max_length(self):
        """Should enforce max length on notes."""
        long_notes = "x" * 600  # Exceeds 500 char limit
        with pytest.raises(Exception):
            PostWorkoutCheckinCreate(
                user_id="test-user",
                workout_id="workout-123",
                mood_after=4,
                notes=long_notes,
            )


class TestSubjectiveFeedbackModel:
    """Tests for the SubjectiveFeedback model."""

    def test_complete_model(self):
        """Should create model with all fields."""
        feedback = SubjectiveFeedback(
            id="feedback-123",
            user_id="test-user",
            workout_id="workout-123",
            mood_before=2,
            energy_before=2,
            sleep_quality=3,
            stress_level=4,
            mood_after=4,
            energy_after=4,
            confidence_level=4,
            soreness_level=2,
            feeling_stronger=True,
            notes="Felt great!",
            pre_checkin_at=datetime.now(),
            post_checkin_at=datetime.now(),
            created_at=datetime.now(),
            mood_change=2,
        )
        assert feedback.mood_change == 2

    def test_partial_model(self):
        """Should allow partial data (only pre or only post checkin)."""
        feedback = SubjectiveFeedback(
            id="feedback-456",
            user_id="test-user",
            mood_before=3,
            created_at=datetime.now(),
        )
        assert feedback.mood_after is None
        assert feedback.feeling_stronger is False


# ============================================================================
# API Endpoint Tests - Pre-Workout Check-in
# ============================================================================

class TestPreWorkoutCheckinEndpoint:
    """Tests for POST /subjective-feedback/pre-checkin endpoint."""

    def test_endpoint_exists(self, client):
        """Test that pre-checkin endpoint exists."""
        response = client.post(
            "/api/v1/subjective-feedback/pre-checkin",
            json={
                "user_id": "test-user",
                "mood_before": 3,
            }
        )
        assert response.status_code != 404

    def test_requires_user_id(self, client):
        """Test that user_id is required."""
        response = client.post(
            "/api/v1/subjective-feedback/pre-checkin",
            json={
                "mood_before": 3,
            }
        )
        assert response.status_code == 422

    def test_requires_mood_before(self, client):
        """Test that mood_before is required."""
        response = client.post(
            "/api/v1/subjective-feedback/pre-checkin",
            json={
                "user_id": "test-user",
            }
        )
        assert response.status_code == 422

    @patch('api.v1.subjective_feedback.get_supabase_db')
    @patch('api.v1.subjective_feedback.log_user_activity')
    @patch('api.v1.subjective_feedback.user_context_service')
    def test_creates_pre_checkin_successfully(self, mock_context, mock_log, mock_db, client):
        """Should create pre-workout check-in successfully."""
        mock_result = MagicMock()
        mock_result.data = [{
            "id": "feedback-new-123",
            "user_id": "test-user",
            "workout_id": None,
            "mood_before": 3,
            "energy_before": 3,
            "sleep_quality": 4,
            "stress_level": None,
            "pre_checkin_at": datetime.now().isoformat(),
            "created_at": datetime.now().isoformat(),
        }]

        mock_db_instance = MagicMock()
        mock_db_instance.client.table.return_value.insert.return_value.execute.return_value = mock_result
        mock_db.return_value = mock_db_instance

        mock_log.return_value = None
        mock_context.log_event = AsyncMock()

        response = client.post(
            "/api/v1/subjective-feedback/pre-checkin",
            json={
                "user_id": "test-user",
                "mood_before": 3,
                "energy_before": 3,
                "sleep_quality": 4,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "feedback-new-123"
        assert data["mood_before"] == 3


# ============================================================================
# API Endpoint Tests - Post-Workout Check-in
# ============================================================================

class TestPostWorkoutCheckinEndpoint:
    """Tests for POST /subjective-feedback/workouts/{workout_id}/post-checkin endpoint."""

    def test_endpoint_exists(self, client):
        """Test that post-checkin endpoint exists."""
        response = client.post(
            "/api/v1/subjective-feedback/workouts/workout-123/post-checkin",
            json={
                "user_id": "test-user",
                "workout_id": "workout-123",
                "mood_after": 4,
            }
        )
        assert response.status_code != 404

    @patch('api.v1.subjective_feedback.get_supabase_db')
    @patch('api.v1.subjective_feedback.log_user_activity')
    @patch('api.v1.subjective_feedback.user_context_service')
    def test_creates_new_post_checkin(self, mock_context, mock_log, mock_db, client):
        """Should create new record when no pre-checkin exists."""
        mock_existing = MagicMock()
        mock_existing.data = []  # No existing pre-checkin

        mock_insert_result = MagicMock()
        mock_insert_result.data = [{
            "id": "feedback-post-123",
            "user_id": "test-user",
            "workout_id": "workout-123",
            "mood_after": 4,
            "energy_after": 4,
            "confidence_level": 4,
            "soreness_level": 2,
            "feeling_stronger": True,
            "notes": None,
            "post_checkin_at": datetime.now().isoformat(),
            "created_at": datetime.now().isoformat(),
        }]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing
        mock_query.insert.return_value.execute.return_value = mock_insert_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        mock_log.return_value = None
        mock_context.log_event = AsyncMock()

        response = client.post(
            "/api/v1/subjective-feedback/workouts/workout-123/post-checkin",
            json={
                "user_id": "test-user",
                "workout_id": "workout-123",
                "mood_after": 4,
                "energy_after": 4,
                "confidence_level": 4,
                "soreness_level": 2,
                "feeling_stronger": True,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["mood_after"] == 4
        assert data["feeling_stronger"] is True

    @patch('api.v1.subjective_feedback.get_supabase_db')
    @patch('api.v1.subjective_feedback.log_user_activity')
    @patch('api.v1.subjective_feedback.user_context_service')
    def test_updates_existing_pre_checkin(self, mock_context, mock_log, mock_db, client):
        """Should update existing pre-checkin with post-workout data."""
        mock_existing = MagicMock()
        mock_existing.data = [{
            "id": "feedback-existing-123",
            "user_id": "test-user",
            "workout_id": "workout-123",
            "mood_before": 2,
            "energy_before": 2,
            "pre_checkin_at": datetime.now().isoformat(),
            "created_at": datetime.now().isoformat(),
        }]

        mock_update_result = MagicMock()
        mock_update_result.data = [{
            "id": "feedback-existing-123",
            "user_id": "test-user",
            "workout_id": "workout-123",
            "mood_before": 2,
            "energy_before": 2,
            "mood_after": 5,
            "energy_after": 5,
            "confidence_level": 5,
            "soreness_level": 1,
            "feeling_stronger": True,
            "pre_checkin_at": datetime.now().isoformat(),
            "post_checkin_at": datetime.now().isoformat(),
            "created_at": datetime.now().isoformat(),
        }]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing
        mock_query.update.return_value.eq.return_value.execute.return_value = mock_update_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        mock_log.return_value = None
        mock_context.log_event = AsyncMock()

        response = client.post(
            "/api/v1/subjective-feedback/workouts/workout-123/post-checkin",
            json={
                "user_id": "test-user",
                "workout_id": "workout-123",
                "mood_after": 5,
                "energy_after": 5,
                "confidence_level": 5,
                "soreness_level": 1,
                "feeling_stronger": True,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["mood_before"] == 2  # Preserved from pre-checkin
        assert data["mood_after"] == 5


# ============================================================================
# API Endpoint Tests - Trends
# ============================================================================

class TestSubjectiveTrendsEndpoint:
    """Tests for GET /subjective-feedback/progress/subjective-trends endpoint."""

    def test_endpoint_exists(self, client):
        """Test that trends endpoint exists."""
        response = client.get(
            "/api/v1/subjective-feedback/progress/subjective-trends?user_id=test-user"
        )
        assert response.status_code != 404

    def test_requires_user_id(self, client):
        """Test that user_id is required."""
        response = client.get(
            "/api/v1/subjective-feedback/progress/subjective-trends"
        )
        assert response.status_code == 422

    @patch('api.v1.subjective_feedback.get_supabase_db')
    def test_returns_empty_trends_for_new_user(self, mock_db, client):
        """Should return empty trends for user with no data."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/subjective-feedback/progress/subjective-trends?user_id=new-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total_workouts"] == 0
        assert data["avg_mood_before"] == 0
        assert data["avg_mood_after"] == 0

    @patch('api.v1.subjective_feedback.get_supabase_db')
    def test_calculates_trends_correctly(self, mock_db, client):
        """Should calculate trends from workout data."""
        now = datetime.utcnow()
        mock_result = MagicMock()
        mock_result.data = [
            {
                "id": "1",
                "mood_before": 2,
                "mood_after": 4,
                "energy_before": 2,
                "energy_after": 4,
                "sleep_quality": 3,
                "confidence_level": 4,
                "feeling_stronger": True,
                "created_at": (now - timedelta(days=20)).isoformat(),
            },
            {
                "id": "2",
                "mood_before": 3,
                "mood_after": 5,
                "energy_before": 3,
                "energy_after": 5,
                "sleep_quality": 4,
                "confidence_level": 5,
                "feeling_stronger": True,
                "created_at": (now - timedelta(days=10)).isoformat(),
            },
            {
                "id": "3",
                "mood_before": 3,
                "mood_after": 4,
                "energy_before": 3,
                "energy_after": 4,
                "sleep_quality": 4,
                "confidence_level": 4,
                "feeling_stronger": False,
                "created_at": now.isoformat(),
            },
        ]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.gte.return_value.order.return_value.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/subjective-feedback/progress/subjective-trends?user_id=test-user&days=30"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total_workouts"] == 3
        assert data["feeling_stronger_count"] == 2


# ============================================================================
# API Endpoint Tests - Feel Results Summary
# ============================================================================

class TestFeelResultsSummaryEndpoint:
    """Tests for GET /subjective-feedback/progress/feel-results endpoint."""

    def test_endpoint_exists(self, client):
        """Test that feel-results endpoint exists."""
        response = client.get(
            "/api/v1/subjective-feedback/progress/feel-results?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.subjective_feedback.get_supabase_db')
    @patch('api.v1.subjective_feedback.user_context_service')
    def test_returns_summary_for_new_user(self, mock_context, mock_db, client):
        """Should return starter message for new user."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance
        mock_context.log_event = AsyncMock()

        response = client.get(
            "/api/v1/subjective-feedback/progress/feel-results?user_id=new-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total_workouts_tracked"] == 0
        assert "Start tracking" in data["insight_headline"]

    @patch('api.v1.subjective_feedback.get_supabase_db')
    @patch('api.v1.subjective_feedback.user_context_service')
    def test_returns_motivational_insights(self, mock_context, mock_db, client):
        """Should return motivational insights for active user."""
        mock_result = MagicMock()
        mock_result.data = [
            {"mood_before": 2, "mood_after": 4, "feeling_stronger": True},
            {"mood_before": 3, "mood_after": 5, "feeling_stronger": True},
            {"mood_before": 2, "mood_after": 4, "feeling_stronger": False},
        ]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance
        mock_context.log_event = AsyncMock()

        response = client.get(
            "/api/v1/subjective-feedback/progress/feel-results?user_id=test-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total_workouts_tracked"] == 3
        assert data["insight_headline"] is not None
        assert data["insight_detail"] is not None


# ============================================================================
# API Endpoint Tests - History
# ============================================================================

class TestSubjectiveHistoryEndpoint:
    """Tests for GET /subjective-feedback/history endpoint."""

    def test_endpoint_exists(self, client):
        """Test that history endpoint exists."""
        response = client.get(
            "/api/v1/subjective-feedback/history?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.subjective_feedback.get_supabase_db')
    def test_returns_paginated_history(self, mock_db, client):
        """Should return paginated history."""
        mock_result = MagicMock()
        mock_result.data = [
            {
                "id": "feedback-1",
                "user_id": "test-user",
                "workout_id": "workout-1",
                "mood_before": 3,
                "mood_after": 4,
                "feeling_stronger": True,
                "created_at": datetime.now().isoformat(),
            },
        ]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/subjective-feedback/history?user_id=test-user&limit=10&offset=0"
        )

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)


# ============================================================================
# API Endpoint Tests - Workout-Specific Feedback
# ============================================================================

class TestWorkoutSpecificFeedbackEndpoint:
    """Tests for GET /subjective-feedback/workouts/{workout_id} endpoint."""

    def test_endpoint_exists(self, client):
        """Test that workout-specific endpoint exists."""
        response = client.get(
            "/api/v1/subjective-feedback/workouts/workout-123?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.subjective_feedback.get_supabase_db')
    def test_returns_null_for_missing_feedback(self, mock_db, client):
        """Should return null for workout without feedback."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/subjective-feedback/workouts/workout-missing?user_id=test-user"
        )

        assert response.status_code == 200
        # Should return null/None for missing feedback
        assert response.json() is None


# ============================================================================
# API Endpoint Tests - Quick Stats
# ============================================================================

class TestQuickSubjectiveStatsEndpoint:
    """Tests for GET /subjective-feedback/quick-stats endpoint."""

    def test_endpoint_exists(self, client):
        """Test that quick-stats endpoint exists."""
        response = client.get(
            "/api/v1/subjective-feedback/quick-stats?user_id=test-user"
        )
        assert response.status_code != 404

    @patch('api.v1.subjective_feedback.get_supabase_db')
    def test_returns_no_data_for_new_user(self, mock_db, client):
        """Should return has_data=False for new user."""
        mock_result = MagicMock()
        mock_result.data = []

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/subjective-feedback/quick-stats?user_id=new-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["has_data"] is False
        assert data["total_checkins"] == 0

    @patch('api.v1.subjective_feedback.get_supabase_db')
    def test_returns_stats_for_active_user(self, mock_db, client):
        """Should return stats for active user."""
        mock_result = MagicMock()
        mock_result.data = [
            {"mood_after": 4, "feeling_stronger": True},
            {"mood_after": 5, "feeling_stronger": True},
            {"mood_after": 4, "feeling_stronger": False},
        ]

        mock_db_instance = MagicMock()
        mock_query = MagicMock()
        mock_query.select.return_value.eq.return_value.gte.return_value.execute.return_value = mock_result
        mock_db_instance.client.table.return_value = mock_query
        mock_db.return_value = mock_db_instance

        response = client.get(
            "/api/v1/subjective-feedback/quick-stats?user_id=active-user"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["has_data"] is True
        assert data["total_checkins"] == 3
        assert data["avg_mood_after"] is not None


# ============================================================================
# Response Model Tests
# ============================================================================

class TestSubjectiveTrendsResponseModel:
    """Tests for the SubjectiveTrendsResponse model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        response = SubjectiveTrendsResponse(
            user_id="test-user",
            period_days=30,
            total_workouts=10,
            avg_mood_before=3.2,
            avg_mood_after=4.1,
            avg_mood_change=0.9,
            avg_energy_before=3.0,
            avg_energy_after=4.0,
            avg_sleep_quality=3.5,
            avg_confidence=4.0,
            mood_trend_percent=15.0,
            energy_trend_percent=10.0,
            confidence_trend_percent=8.0,
            weekly_data=[],
            feeling_stronger_count=7,
            feeling_stronger_percent=70.0,
        )

        assert response.total_workouts == 10
        assert response.avg_mood_change == 0.9


class TestFeelResultsSummaryModel:
    """Tests for the FeelResultsSummary model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        summary = FeelResultsSummary(
            user_id="test-user",
            total_workouts_tracked=50,
            mood_improvement_percent=25.0,
            avg_post_workout_mood=4.2,
            avg_post_workout_energy=4.0,
            feeling_stronger_percent=65.0,
            insight_headline="You feel 25% better after working out!",
            insight_detail="Your average post-workout mood is 4.2/5.",
            mood_boost_from_exercise=80.0,
        )

        assert summary.mood_improvement_percent == 25.0
        assert "25%" in summary.insight_headline
