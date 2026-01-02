"""
Tests for the Progress Milestones and ROI API endpoints.

Tests the /api/v1/progress/milestones/* and /api/v1/progress/roi/* endpoints
that track user milestones and demonstrate value through ROI metrics.

Run with: pytest tests/test_milestones.py -v
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime, date

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.milestones import (
    MilestoneCategory,
    MilestoneTier,
    MilestoneDefinition,
    UserMilestone,
    MilestoneProgress,
    NewMilestoneAchieved,
    ROIMetrics,
    ROISummary,
    MilestonesResponse,
    MilestoneShareRequest,
    MarkMilestoneCelebratedRequest,
    MilestoneCheckResult,
)


# ============================================================================
# Enum Tests
# ============================================================================

class TestMilestoneCategoryEnum:
    """Tests for the MilestoneCategory enum."""

    def test_all_categories_defined(self):
        """Should have all expected milestone categories."""
        assert MilestoneCategory.WORKOUTS.value == "workouts"
        assert MilestoneCategory.STREAK.value == "streak"
        assert MilestoneCategory.STRENGTH.value == "strength"
        assert MilestoneCategory.VOLUME.value == "volume"
        assert MilestoneCategory.TIME.value == "time"
        assert MilestoneCategory.WEIGHT.value == "weight"
        assert MilestoneCategory.PRS.value == "prs"


class TestMilestoneTierEnum:
    """Tests for the MilestoneTier enum."""

    def test_all_tiers_defined(self):
        """Should have all expected milestone tiers."""
        assert MilestoneTier.BRONZE.value == "bronze"
        assert MilestoneTier.SILVER.value == "silver"
        assert MilestoneTier.GOLD.value == "gold"
        assert MilestoneTier.PLATINUM.value == "platinum"
        assert MilestoneTier.DIAMOND.value == "diamond"


# ============================================================================
# Pydantic Model Tests
# ============================================================================

class TestMilestoneDefinitionModel:
    """Tests for the MilestoneDefinition model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        definition = MilestoneDefinition(
            id="milestone-first-workout",
            name="First Workout",
            description="Complete your first workout!",
            category=MilestoneCategory.WORKOUTS,
            threshold=1,
            icon="trophy",
            badge_color="gold",
            tier=MilestoneTier.BRONZE,
            points=10,
            share_message="I just completed my first workout!",
            is_active=True,
            sort_order=1,
        )

        assert definition.id == "milestone-first-workout"
        assert definition.threshold == 1
        assert definition.points == 10

    def test_defaults(self):
        """Should have sensible defaults."""
        definition = MilestoneDefinition(
            id="test-milestone",
            name="Test",
            category=MilestoneCategory.WORKOUTS,
            threshold=5,
        )

        assert definition.badge_color == "cyan"
        assert definition.tier == MilestoneTier.BRONZE
        assert definition.points == 10
        assert definition.is_active is True


class TestUserMilestoneModel:
    """Tests for the UserMilestone model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        milestone = UserMilestone(
            id="user-milestone-123",
            user_id="test-user",
            milestone_id="milestone-first-workout",
            achieved_at=datetime.now(),
            trigger_value=1.0,
            trigger_context={"workout_id": "workout-123"},
            is_notified=True,
            is_celebrated=False,
        )

        assert milestone.user_id == "test-user"
        assert milestone.is_celebrated is False


class TestMilestoneProgressModel:
    """Tests for the MilestoneProgress model."""

    def test_achieved_milestone(self):
        """Should create achieved milestone progress."""
        milestone_def = MilestoneDefinition(
            id="test-milestone",
            name="Test",
            category=MilestoneCategory.WORKOUTS,
            threshold=5,
        )

        progress = MilestoneProgress(
            milestone=milestone_def,
            is_achieved=True,
            achieved_at=datetime.now(),
            trigger_value=5.0,
            is_celebrated=True,
        )

        assert progress.is_achieved is True
        assert progress.trigger_value == 5.0

    def test_upcoming_milestone(self):
        """Should create upcoming milestone with progress."""
        milestone_def = MilestoneDefinition(
            id="test-milestone",
            name="Test",
            category=MilestoneCategory.WORKOUTS,
            threshold=10,
        )

        progress = MilestoneProgress(
            milestone=milestone_def,
            is_achieved=False,
            current_value=7.0,
            progress_percentage=70.0,
        )

        assert progress.is_achieved is False
        assert progress.progress_percentage == 70.0


class TestROIMetricsModel:
    """Tests for the ROIMetrics model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        metrics = ROIMetrics(
            user_id="test-user",
            total_workouts_completed=50,
            total_exercises_completed=400,
            total_sets_completed=1200,
            total_reps_completed=12000,
            total_workout_time_seconds=108000,  # 30 hours
            total_workout_time_hours=30.0,
            total_weight_lifted_lbs=150000,
            total_weight_lifted_kg=68000,
            estimated_calories_burned=15000,
            strength_increase_percentage=25.0,
            prs_achieved_count=10,
            current_streak_days=7,
            longest_streak_days=14,
            journey_days=90,
            workouts_this_week=4,
            workouts_this_month=16,
            average_workouts_per_week=3.5,
        )

        assert metrics.total_workouts_completed == 50
        assert metrics.journey_days == 90

    def test_compute_derived_fields(self):
        """Should compute derived fields correctly."""
        metrics = ROIMetrics(
            user_id="test-user",
            total_workout_time_seconds=7200,  # 2 hours
            average_workout_duration_seconds=1800,  # 30 min
            strength_increase_percentage=15.0,
            prs_achieved_count=5,
            journey_days=30,
        )

        metrics.compute_derived_fields()

        assert metrics.total_workout_time_hours == 2.0
        assert metrics.average_workout_duration_minutes == 30
        assert "15%" in metrics.strength_summary
        assert "30 days" in metrics.journey_summary


class TestROISummaryModel:
    """Tests for the ROISummary model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        summary = ROISummary(
            total_workouts=50,
            total_hours_invested=30.5,
            estimated_calories_burned=15000,
            total_weight_lifted="150,000 lbs",
            strength_increase_text="25% stronger",
            prs_count=10,
            current_streak=7,
            journey_days=90,
            headline="Your Fitness Journey",
            motivational_message="You've invested 30+ hours in yourself!",
        )

        assert summary.total_workouts == 50
        assert "30+" in summary.motivational_message


class TestMilestonesResponseModel:
    """Tests for the MilestonesResponse model."""

    def test_model_creation(self):
        """Should create model with all fields."""
        milestone_def = MilestoneDefinition(
            id="test-milestone",
            name="Test",
            category=MilestoneCategory.WORKOUTS,
            threshold=5,
        )

        response = MilestonesResponse(
            achieved=[MilestoneProgress(milestone=milestone_def, is_achieved=True)],
            upcoming=[MilestoneProgress(milestone=milestone_def, is_achieved=False, progress_percentage=50.0)],
            total_points=100,
            total_achieved=5,
            next_milestone=MilestoneProgress(milestone=milestone_def, is_achieved=False, progress_percentage=80.0),
            recently_achieved=[],
            uncelebrated=[],
        )

        assert response.total_points == 100
        assert len(response.achieved) == 1


class TestMilestoneShareRequestModel:
    """Tests for the MilestoneShareRequest model."""

    def test_required_fields(self):
        """Should require milestone_id and platform."""
        request = MilestoneShareRequest(
            milestone_id="milestone-123",
            platform="twitter",
        )

        assert request.milestone_id == "milestone-123"
        assert request.platform == "twitter"


class TestMarkMilestoneCelebratedRequestModel:
    """Tests for the MarkMilestoneCelebratedRequest model."""

    def test_required_fields(self):
        """Should require milestone_ids list."""
        request = MarkMilestoneCelebratedRequest(
            milestone_ids=["milestone-1", "milestone-2"],
        )

        assert len(request.milestone_ids) == 2


class TestMilestoneCheckResultModel:
    """Tests for the MilestoneCheckResult model."""

    def test_with_new_milestones(self):
        """Should create result with new milestones."""
        new_milestone = NewMilestoneAchieved(
            milestone_id="milestone-10-workouts",
            milestone_name="10 Workouts Complete",
            milestone_icon="muscle",
            milestone_tier=MilestoneTier.SILVER,
            points=25,
            share_message="Just hit 10 workouts!",
        )

        result = MilestoneCheckResult(
            new_milestones=[new_milestone],
            total_new_points=25,
            roi_updated=True,
        )

        assert len(result.new_milestones) == 1
        assert result.total_new_points == 25

    def test_empty_result(self):
        """Should create empty result."""
        result = MilestoneCheckResult(
            new_milestones=[],
            total_new_points=0,
            roi_updated=False,
        )

        assert len(result.new_milestones) == 0


# ============================================================================
# API Endpoint Tests - Milestone Definitions
# ============================================================================

class TestMilestoneDefinitionsEndpoint:
    """Tests for GET /progress/milestones/definitions endpoint."""

    def test_endpoint_exists(self, client):
        """Test that definitions endpoint exists."""
        response = client.get("/api/v1/progress/milestones/definitions")
        assert response.status_code != 404

    @patch('api.v1.milestones.milestone_service')
    def test_returns_definitions(self, mock_service, client):
        """Should return milestone definitions."""
        mock_service.get_all_milestone_definitions = AsyncMock(return_value=[
            MilestoneDefinition(
                id="first-workout",
                name="First Workout",
                category=MilestoneCategory.WORKOUTS,
                threshold=1,
            ),
        ])

        response = client.get("/api/v1/progress/milestones/definitions")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    @patch('api.v1.milestones.milestone_service')
    def test_accepts_category_filter(self, mock_service, client):
        """Should accept category filter."""
        mock_service.get_all_milestone_definitions = AsyncMock(return_value=[])

        response = client.get(
            "/api/v1/progress/milestones/definitions?category=workouts"
        )

        assert response.status_code == 200


# ============================================================================
# API Endpoint Tests - User Milestones
# ============================================================================

class TestUserMilestonesEndpoint:
    """Tests for GET /progress/milestones/{user_id} endpoint."""

    def test_endpoint_exists(self, client):
        """Test that user milestones endpoint exists."""
        response = client.get("/api/v1/progress/milestones/test-user")
        assert response.status_code != 404

    @patch('api.v1.milestones.milestone_service')
    @patch('api.v1.milestones.log_user_activity')
    def test_returns_user_milestones(self, mock_log, mock_service, client):
        """Should return user's milestone progress."""
        milestone_def = MilestoneDefinition(
            id="test-milestone",
            name="Test",
            category=MilestoneCategory.WORKOUTS,
            threshold=5,
        )

        mock_service.get_milestone_progress = AsyncMock(return_value=MilestonesResponse(
            achieved=[MilestoneProgress(milestone=milestone_def, is_achieved=True)],
            upcoming=[],
            total_points=50,
            total_achieved=5,
        ))
        mock_log.return_value = None

        response = client.get("/api/v1/progress/milestones/test-user")

        assert response.status_code == 200
        data = response.json()
        assert "achieved" in data
        assert "upcoming" in data
        assert "total_points" in data


class TestUncelebratedMilestonesEndpoint:
    """Tests for GET /progress/milestones/{user_id}/uncelebrated endpoint."""

    def test_endpoint_exists(self, client):
        """Test that uncelebrated endpoint exists."""
        response = client.get("/api/v1/progress/milestones/test-user/uncelebrated")
        assert response.status_code != 404

    @patch('api.v1.milestones.milestone_service')
    def test_returns_uncelebrated_milestones(self, mock_service, client):
        """Should return uncelebrated milestones."""
        mock_service.get_uncelebrated_milestones = AsyncMock(return_value=[
            UserMilestone(
                id="user-milestone-1",
                user_id="test-user",
                milestone_id="milestone-10-workouts",
                achieved_at=datetime.now(),
                is_celebrated=False,
            ),
        ])

        response = client.get("/api/v1/progress/milestones/test-user/uncelebrated")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)


class TestCelebrateMilestonesEndpoint:
    """Tests for POST /progress/milestones/{user_id}/celebrate endpoint."""

    def test_endpoint_exists(self, client):
        """Test that celebrate endpoint exists."""
        response = client.post(
            "/api/v1/progress/milestones/test-user/celebrate",
            json={"milestone_ids": ["milestone-1"]}
        )
        assert response.status_code != 404

    @patch('api.v1.milestones.milestone_service')
    @patch('api.v1.milestones.user_context_service')
    def test_marks_milestones_celebrated(self, mock_context, mock_service, client):
        """Should mark milestones as celebrated."""
        mock_service.mark_milestones_celebrated = AsyncMock(return_value=True)
        mock_context.log_event = AsyncMock()

        response = client.post(
            "/api/v1/progress/milestones/test-user/celebrate",
            json={"milestone_ids": ["milestone-1", "milestone-2"]}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True


class TestShareMilestoneEndpoint:
    """Tests for POST /progress/milestones/{user_id}/share endpoint."""

    def test_endpoint_exists(self, client):
        """Test that share endpoint exists."""
        response = client.post(
            "/api/v1/progress/milestones/test-user/share",
            json={"milestone_id": "milestone-1", "platform": "twitter"}
        )
        assert response.status_code != 404

    @patch('api.v1.milestones.milestone_service')
    @patch('api.v1.milestones.user_context_service')
    @patch('api.v1.milestones.log_user_activity')
    def test_records_milestone_share(self, mock_log, mock_context, mock_service, client):
        """Should record milestone share."""
        mock_service.record_milestone_share = AsyncMock(return_value=True)
        mock_context.log_event = AsyncMock()
        mock_log.return_value = None

        response = client.post(
            "/api/v1/progress/milestones/test-user/share",
            json={"milestone_id": "milestone-1", "platform": "instagram"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True


class TestCheckMilestonesEndpoint:
    """Tests for POST /progress/milestones/{user_id}/check endpoint."""

    def test_endpoint_exists(self, client):
        """Test that check endpoint exists."""
        response = client.post("/api/v1/progress/milestones/test-user/check")
        assert response.status_code != 404

    @patch('api.v1.milestones.milestone_service')
    @patch('api.v1.milestones.log_user_activity')
    def test_checks_and_awards_milestones(self, mock_log, mock_service, client):
        """Should check and award new milestones."""
        mock_service.check_and_award_milestones = AsyncMock(return_value=MilestoneCheckResult(
            new_milestones=[
                NewMilestoneAchieved(
                    milestone_id="milestone-10-workouts",
                    milestone_name="10 Workouts",
                    points=25,
                ),
            ],
            total_new_points=25,
            roi_updated=True,
        ))
        mock_log.return_value = None

        response = client.post("/api/v1/progress/milestones/test-user/check")

        assert response.status_code == 200
        data = response.json()
        assert "new_milestones" in data
        assert "total_new_points" in data


# ============================================================================
# API Endpoint Tests - ROI Metrics
# ============================================================================

class TestROIMetricsEndpoint:
    """Tests for GET /progress/roi/{user_id} endpoint."""

    def test_endpoint_exists(self, client):
        """Test that ROI endpoint exists."""
        response = client.get("/api/v1/progress/roi/test-user")
        assert response.status_code != 404

    @patch('api.v1.milestones.milestone_service')
    @patch('api.v1.milestones.user_context_service')
    def test_returns_roi_metrics(self, mock_context, mock_service, client):
        """Should return ROI metrics."""
        mock_service.get_roi_metrics = AsyncMock(return_value=ROIMetrics(
            user_id="test-user",
            total_workouts_completed=50,
            total_workout_time_hours=30.0,
            estimated_calories_burned=15000,
            strength_increase_percentage=25.0,
            prs_achieved_count=10,
            journey_days=90,
        ))
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/progress/roi/test-user")

        assert response.status_code == 200
        data = response.json()
        assert "total_workouts_completed" in data
        assert "journey_days" in data

    @patch('api.v1.milestones.milestone_service')
    @patch('api.v1.milestones.user_context_service')
    def test_accepts_recalculate_parameter(self, mock_context, mock_service, client):
        """Should accept recalculate parameter."""
        mock_service.get_roi_metrics = AsyncMock(return_value=ROIMetrics(
            user_id="test-user",
        ))
        mock_context.log_event = AsyncMock()

        response = client.get("/api/v1/progress/roi/test-user?recalculate=true")

        assert response.status_code == 200


class TestROISummaryEndpoint:
    """Tests for GET /progress/roi/{user_id}/summary endpoint."""

    def test_endpoint_exists(self, client):
        """Test that ROI summary endpoint exists."""
        response = client.get("/api/v1/progress/roi/test-user/summary")
        assert response.status_code != 404

    @patch('api.v1.milestones.milestone_service')
    def test_returns_compact_summary(self, mock_service, client):
        """Should return compact ROI summary."""
        mock_service.get_roi_summary = AsyncMock(return_value=ROISummary(
            total_workouts=50,
            total_hours_invested=30.0,
            estimated_calories_burned=15000,
            total_weight_lifted="150,000 lbs",
            strength_increase_text="25% stronger",
            prs_count=10,
            current_streak=7,
            journey_days=90,
            headline="Your Fitness Journey",
            motivational_message="Amazing progress!",
        ))

        response = client.get("/api/v1/progress/roi/test-user/summary")

        assert response.status_code == 200
        data = response.json()
        assert "total_workouts" in data
        assert "motivational_message" in data


# ============================================================================
# API Endpoint Tests - Progress Overview
# ============================================================================

class TestProgressOverviewEndpoint:
    """Tests for GET /progress/{user_id} endpoint."""

    def test_endpoint_exists(self, client):
        """Test that progress overview endpoint exists."""
        response = client.get("/api/v1/progress/test-user")
        assert response.status_code != 404

    @patch('api.v1.milestones.milestone_service')
    def test_returns_combined_data(self, mock_service, client):
        """Should return combined milestones and ROI data."""
        milestone_def = MilestoneDefinition(
            id="test-milestone",
            name="Test",
            category=MilestoneCategory.WORKOUTS,
            threshold=5,
        )

        mock_service.get_milestone_progress = AsyncMock(return_value=MilestonesResponse(
            achieved=[],
            upcoming=[],
            total_points=50,
            total_achieved=5,
        ))

        mock_service.get_roi_summary = AsyncMock(return_value=ROISummary(
            total_workouts=50,
            total_hours_invested=30.0,
        ))

        response = client.get("/api/v1/progress/test-user")

        assert response.status_code == 200
        data = response.json()
        assert "milestones" in data
        assert "roi" in data


# ============================================================================
# Error Handling Tests
# ============================================================================

class TestMilestoneErrorHandling:
    """Tests for error handling in milestone endpoints."""

    @patch('api.v1.milestones.milestone_service')
    def test_handles_service_error_in_definitions(self, mock_service, client):
        """Should handle service errors gracefully."""
        mock_service.get_all_milestone_definitions = AsyncMock(
            side_effect=Exception("Service error")
        )

        response = client.get("/api/v1/progress/milestones/definitions")

        assert response.status_code == 500

    @patch('api.v1.milestones.milestone_service')
    @patch('api.v1.milestones.log_user_error')
    def test_handles_service_error_in_user_milestones(self, mock_log_error, mock_service, client):
        """Should handle and log service errors."""
        mock_service.get_milestone_progress = AsyncMock(
            side_effect=Exception("Database error")
        )
        mock_log_error.return_value = None

        response = client.get("/api/v1/progress/milestones/test-user")

        assert response.status_code == 500

    @patch('api.v1.milestones.milestone_service')
    def test_handles_service_error_in_roi(self, mock_service, client):
        """Should handle ROI service errors."""
        mock_service.get_roi_metrics = AsyncMock(
            side_effect=Exception("Calculation error")
        )

        response = client.get("/api/v1/progress/roi/test-user")

        assert response.status_code == 500


# ============================================================================
# Validation Tests
# ============================================================================

class TestMilestoneValidation:
    """Tests for request validation in milestone endpoints."""

    def test_celebrate_requires_milestone_ids(self, client):
        """Should require milestone_ids in celebrate request."""
        response = client.post(
            "/api/v1/progress/milestones/test-user/celebrate",
            json={}  # Missing milestone_ids
        )
        assert response.status_code == 422

    def test_share_requires_milestone_id(self, client):
        """Should require milestone_id in share request."""
        response = client.post(
            "/api/v1/progress/milestones/test-user/share",
            json={"platform": "twitter"}  # Missing milestone_id
        )
        assert response.status_code == 422

    def test_share_requires_platform(self, client):
        """Should require platform in share request."""
        response = client.post(
            "/api/v1/progress/milestones/test-user/share",
            json={"milestone_id": "milestone-1"}  # Missing platform
        )
        assert response.status_code == 422
