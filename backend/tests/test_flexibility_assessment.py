"""
Tests for Flexibility Assessment API endpoints and service.

Tests all flexibility assessment functionality including:
- Get all flexibility tests
- Get specific test details
- Record assessments with evaluation
- Get assessment history
- Get progress/trend for a specific test
- Get overall flexibility summary and score
- Stretch plan recommendations
- Service evaluation logic with age/gender norms
"""
import pytest
from unittest.mock import Mock, MagicMock, patch, AsyncMock
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
import uuid

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from services.flexibility.assessment import (
    evaluate_flexibility,
    calculate_percentile,
    get_recommendations,
    FlexibilityAssessmentService,
    get_flexibility_assessment_service,
    FlexibilityRating,
    FLEXIBILITY_TESTS,
    STRETCH_RECOMMENDATIONS,
)


# ============ Mock Data Generators ============

def generate_mock_flexibility_test(
    test_id: str = "sit_and_reach",
    name: str = "Sit and Reach Test",
    unit: str = "inches",
):
    """Generate a mock flexibility test definition."""
    return {
        "id": test_id,
        "name": name,
        "description": f"Test for {name.lower()}",
        "instructions": ["Step 1", "Step 2", "Step 3"],
        "unit": unit,
        "target_muscles": ["hamstrings", "lower_back"],
        "equipment_needed": ["ruler"],
        "tips": ["Tip 1", "Tip 2"],
        "common_mistakes": ["Mistake 1"],
        "video_url": None,
        "image_url": None,
        "higher_is_better": True,
    }


def generate_mock_assessment(
    user_id: str = None,
    test_type: str = "sit_and_reach",
    measurement: float = 6.0,
    rating: str = "good",
    percentile: int = 65,
    assessed_at: datetime = None,
):
    """Generate a mock flexibility assessment."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id or str(uuid.uuid4()),
        "test_type": test_type,
        "measurement": measurement,
        "unit": "inches",
        "rating": rating,
        "percentile": percentile,
        "notes": None,
        "assessed_at": (assessed_at or datetime.now()).isoformat(),
        "created_at": datetime.now().isoformat(),
    }


def generate_mock_progress(
    test_type: str = "sit_and_reach",
    assessments_count: int = 5,
    start_measurement: float = 2.0,
    end_measurement: float = 7.0,
):
    """Generate mock progress data with multiple assessments."""
    assessments = []
    measurement_step = (end_measurement - start_measurement) / (assessments_count - 1) if assessments_count > 1 else 0

    for i in range(assessments_count):
        measurement = start_measurement + (measurement_step * i)
        date = datetime.now() - timedelta(days=(assessments_count - i - 1) * 7)

        # Determine rating based on measurement
        if measurement >= 10:
            rating = "excellent"
        elif measurement >= 5:
            rating = "good"
        elif measurement >= 1:
            rating = "fair"
        else:
            rating = "poor"

        assessments.append({
            "measurement": round(measurement, 1),
            "rating": rating,
            "assessed_at": date.isoformat(),
        })

    return {
        "test_type": test_type,
        "unit": "inches",
        "total_assessments": assessments_count,
        "first_assessment": assessments[0],
        "latest_assessment": assessments[-1],
        "improvement_absolute": round(end_measurement - start_measurement, 1),
        "improvement_percentage": round(((end_measurement - start_measurement) / start_measurement) * 100, 1) if start_measurement > 0 else 0,
        "is_positive_improvement": end_measurement > start_measurement,
        "rating_improved": True,
        "rating_levels_gained": 1,
        "trend_data": assessments,
    }


def generate_mock_summary(
    tests_completed: int = 5,
    overall_score: float = 67.5,
    overall_rating: str = "good",
):
    """Generate a mock flexibility summary."""
    return {
        "user_id": str(uuid.uuid4()),
        "overall_score": overall_score,
        "overall_rating": overall_rating,
        "tests_completed": tests_completed,
        "total_assessments": tests_completed * 3,
        "category_ratings": {
            "hamstrings": "good",
            "shoulders": "fair",
            "hips": "good",
        },
        "areas_needing_improvement": ["shoulder_flexibility", "hip_flexor"],
        "last_assessed_at": datetime.now().isoformat(),
    }


# ============ Fixtures ============

@pytest.fixture
def client():
    """Create a test client."""
    return TestClient(app)


@pytest.fixture
def mock_user_id():
    """Generate a mock user ID."""
    return str(uuid.uuid4())


@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    mock = MagicMock()
    mock_table = MagicMock()
    mock.table.return_value = mock_table

    mock_select = MagicMock()
    mock_table.select.return_value = mock_select
    mock_select.eq.return_value = mock_select
    mock_select.order.return_value = mock_select
    mock_select.limit.return_value = mock_select
    mock_select.single.return_value = mock_select

    mock_insert = MagicMock()
    mock_table.insert.return_value = mock_insert

    mock_update = MagicMock()
    mock_table.update.return_value = mock_update
    mock_update.eq.return_value = mock_update

    mock_delete = MagicMock()
    mock_table.delete.return_value = mock_delete
    mock_delete.eq.return_value = mock_delete

    return mock


@pytest.fixture
def flexibility_service():
    """Get the flexibility assessment service."""
    return get_flexibility_assessment_service()


# ============ Tests: Service Evaluation Logic ============

class TestFlexibilityEvaluation:
    """Tests for the flexibility evaluation service functions."""

    def test_sit_and_reach_evaluation_good_male_30(self):
        """Test sit and reach evaluation for male, 30 years old, good rating."""
        result = evaluate_flexibility("sit_and_reach", 6.0, "male", 30)
        assert result["rating"] == "good"
        assert result["test_type"] == "sit_and_reach"
        assert result["measurement"] == 6.0
        assert result["unit"] == "inches"
        assert "hamstrings" in result["target_muscles"]

    def test_sit_and_reach_evaluation_excellent_female_25(self):
        """Test sit and reach evaluation for female, 25 years old, excellent rating."""
        result = evaluate_flexibility("sit_and_reach", 12.0, "female", 25)
        assert result["rating"] == "excellent"
        assert result["percentile"] >= 75

    def test_sit_and_reach_evaluation_poor_male_50(self):
        """Test sit and reach evaluation for male, 50 years old, poor rating."""
        result = evaluate_flexibility("sit_and_reach", -5.0, "male", 50)
        assert result["rating"] == "poor"
        assert result["percentile"] <= 25
        assert "improvement_message" in result
        assert len(result["recommendations"]) > 0

    def test_sit_and_reach_evaluation_fair_male_45(self):
        """Test sit and reach evaluation for fair rating."""
        result = evaluate_flexibility("sit_and_reach", 1.0, "male", 45)
        assert result["rating"] == "fair"

    def test_shoulder_flexibility_evaluation_lower_is_better(self):
        """Test shoulder flexibility where lower gap is better."""
        # 0 gap should be excellent (fingers touching)
        result = evaluate_flexibility("shoulder_flexibility", 0.0, "male", 30)
        assert result["rating"] == "excellent"

        # Large gap should be poor
        result_poor = evaluate_flexibility("shoulder_flexibility", 6.0, "male", 30)
        assert result_poor["rating"] == "poor"

    def test_hip_flexor_evaluation_lower_is_better(self):
        """Test hip flexor (Thomas test) where lower angle is better."""
        # 0 degrees (flat thigh) should be excellent
        result = evaluate_flexibility("hip_flexor", 2.0, "male", 30)
        assert result["rating"] == "excellent"

        # High angle should be poor
        result_poor = evaluate_flexibility("hip_flexor", 30.0, "male", 30)
        assert result_poor["rating"] == "poor"

    def test_hamstring_evaluation_higher_is_better(self):
        """Test hamstring (ASLR) where higher angle is better."""
        result = evaluate_flexibility("hamstring", 80.0, "male", 25)
        assert result["rating"] == "excellent"

        result_poor = evaluate_flexibility("hamstring", 40.0, "male", 25)
        assert result_poor["rating"] == "poor"

    def test_evaluation_with_invalid_test_type(self):
        """Test evaluation with unknown test type returns error."""
        result = evaluate_flexibility("invalid_test", 10.0, "male", 30)
        assert "error" in result
        assert "available_tests" in result

    def test_evaluation_age_group_selection(self):
        """Test that age groups are selected correctly."""
        # Test different age groups give different results for same measurement
        result_young = evaluate_flexibility("sit_and_reach", 4.0, "male", 25)
        result_older = evaluate_flexibility("sit_and_reach", 4.0, "male", 55)

        # Same measurement might have different ratings due to age-adjusted norms
        assert result_young["age_group"] == "18-29"
        assert result_older["age_group"] == "50-59"

    def test_evaluation_includes_recommendations(self):
        """Test that evaluation includes stretch recommendations."""
        result = evaluate_flexibility("sit_and_reach", 0.0, "male", 30)
        assert result["rating"] == "fair"
        assert "recommendations" in result
        assert len(result["recommendations"]) > 0
        # Recommendations should have name, duration/reps, sets
        rec = result["recommendations"][0]
        assert "name" in rec
        assert "sets" in rec

    def test_evaluation_gender_fallback(self):
        """Test evaluation with invalid gender falls back to male."""
        result = evaluate_flexibility("sit_and_reach", 6.0, "unknown", 30)
        assert result["gender"] == "male"
        assert "rating" in result


class TestPercentileCalculation:
    """Tests for percentile calculation function."""

    def test_percentile_excellent_range(self):
        """Test percentile in excellent range."""
        percentile = calculate_percentile("sit_and_reach", 15.0, "male", 25)
        assert percentile >= 75
        assert percentile <= 99

    def test_percentile_poor_range(self):
        """Test percentile in poor range."""
        percentile = calculate_percentile("sit_and_reach", -5.0, "male", 30)
        assert percentile >= 1
        assert percentile <= 24

    def test_percentile_fair_range(self):
        """Test percentile in fair range."""
        percentile = calculate_percentile("sit_and_reach", 2.0, "male", 30)
        assert percentile >= 25
        assert percentile <= 50

    def test_percentile_good_range(self):
        """Test percentile in good range."""
        percentile = calculate_percentile("sit_and_reach", 6.0, "male", 30)
        assert percentile >= 50
        assert percentile <= 75

    def test_percentile_invalid_test(self):
        """Test percentile for invalid test returns 50."""
        percentile = calculate_percentile("invalid_test", 10.0, "male", 30)
        assert percentile == 50

    def test_percentile_lower_is_better_test(self):
        """Test percentile calculation for lower-is-better tests."""
        # Excellent shoulder flexibility (overlap, negative value)
        percentile = calculate_percentile("shoulder_flexibility", -2.0, "male", 25)
        assert percentile >= 75


class TestGetRecommendations:
    """Tests for stretch recommendation retrieval."""

    def test_get_recommendations_poor_rating(self):
        """Test getting recommendations for poor rating."""
        recs = get_recommendations("sit_and_reach", "poor")
        assert len(recs) > 0
        assert any("Hamstring" in r["name"] or "Forward" in r["name"] for r in recs)

    def test_get_recommendations_fair_rating(self):
        """Test getting recommendations for fair rating."""
        recs = get_recommendations("sit_and_reach", "fair")
        assert len(recs) > 0

    def test_get_recommendations_excellent_rating(self):
        """Test getting recommendations for excellent rating."""
        recs = get_recommendations("sit_and_reach", "excellent")
        assert len(recs) > 0
        # Should be maintenance stretches
        assert any("Maintenance" in r["name"] for r in recs)

    def test_get_recommendations_invalid_test(self):
        """Test getting recommendations for invalid test."""
        recs = get_recommendations("invalid_test", "poor")
        assert len(recs) == 0

    def test_get_recommendations_invalid_rating(self):
        """Test getting recommendations for invalid rating."""
        recs = get_recommendations("sit_and_reach", "invalid_rating")
        assert len(recs) == 0


class TestFlexibilityAssessmentService:
    """Tests for the FlexibilityAssessmentService class."""

    def test_get_all_tests(self, flexibility_service):
        """Test getting all flexibility tests."""
        tests = flexibility_service.get_all_tests()
        assert len(tests) == 10  # We have 10 flexibility tests defined

        # Verify structure
        for test in tests:
            assert "id" in test
            assert "name" in test
            assert "description" in test
            assert "instructions" in test
            assert "unit" in test
            assert "target_muscles" in test

    def test_get_test_by_id_valid(self, flexibility_service):
        """Test getting a specific test by ID."""
        test = flexibility_service.get_test_by_id("sit_and_reach")
        assert test is not None
        assert test["id"] == "sit_and_reach"
        assert test["name"] == "Sit and Reach Test"
        assert "hamstrings" in test["target_muscles"]

    def test_get_test_by_id_invalid(self, flexibility_service):
        """Test getting a non-existent test by ID."""
        test = flexibility_service.get_test_by_id("invalid_test_id")
        assert test is None

    def test_get_tests_by_muscle_hamstrings(self, flexibility_service):
        """Test getting tests that target hamstrings."""
        tests = flexibility_service.get_tests_by_muscle("hamstrings")
        assert len(tests) > 0
        # Should include sit_and_reach and hamstring tests
        test_ids = [t["id"] for t in tests]
        assert "sit_and_reach" in test_ids
        assert "hamstring" in test_ids

    def test_get_tests_by_muscle_shoulders(self, flexibility_service):
        """Test getting tests that target shoulders."""
        tests = flexibility_service.get_tests_by_muscle("shoulders")
        assert len(tests) > 0
        test_ids = [t["id"] for t in tests]
        assert "shoulder_flexibility" in test_ids

    def test_evaluate_method(self, flexibility_service):
        """Test the evaluate method."""
        result = flexibility_service.evaluate(
            test_type="sit_and_reach",
            measurement=6.0,
            gender="male",
            age=30,
            notes="Test note"
        )
        assert result["rating"] == "good"
        assert result["notes"] == "Test note"

    def test_compare_assessments_shows_improvement(self, flexibility_service):
        """Test comparing assessments shows improvement."""
        assessments = [
            {"test_type": "sit_and_reach", "measurement": 2.0, "rating": "fair", "assessed_at": "2024-01-01"},
            {"test_type": "sit_and_reach", "measurement": 4.0, "rating": "fair", "assessed_at": "2024-02-01"},
            {"test_type": "sit_and_reach", "measurement": 7.0, "rating": "good", "assessed_at": "2024-03-01"},
        ]

        result = flexibility_service.compare_assessments(assessments)

        assert result["total_assessments"] == 3
        assert result["improvement"]["absolute"] == 5.0
        assert result["improvement"]["is_positive"] is True
        assert result["improvement"]["rating_improved"] is True
        assert result["improvement"]["rating_levels_gained"] == 1

    def test_compare_assessments_insufficient_data(self, flexibility_service):
        """Test comparing with only one assessment."""
        assessments = [
            {"test_type": "sit_and_reach", "measurement": 2.0, "rating": "fair"}
        ]

        result = flexibility_service.compare_assessments(assessments)
        assert "error" in result

    def test_compare_assessments_lower_is_better(self, flexibility_service):
        """Test comparing assessments for lower-is-better tests."""
        assessments = [
            {"test_type": "shoulder_flexibility", "measurement": 5.0, "rating": "fair", "assessed_at": "2024-01-01"},
            {"test_type": "shoulder_flexibility", "measurement": 2.0, "rating": "good", "assessed_at": "2024-03-01"},
        ]

        result = flexibility_service.compare_assessments(assessments)

        # Improvement should be positive even though measurement decreased
        # because for this test, lower is better
        assert result["improvement"]["absolute"] == 3.0  # Improvement is magnitude
        assert result["improvement"]["is_positive"] is True

    def test_get_overall_flexibility_score(self, flexibility_service):
        """Test calculating overall flexibility score."""
        assessments = {
            "sit_and_reach": {"rating": "good", "measurement": 6.0},
            "shoulder_flexibility": {"rating": "fair", "measurement": 3.0},
            "hamstring": {"rating": "excellent", "measurement": 85.0},
            "ankle_dorsiflexion": {"rating": "good", "measurement": 4.5},
        }

        result = flexibility_service.get_overall_flexibility_score(assessments)

        assert "overall_score" in result
        assert "overall_rating" in result
        assert result["tests_completed"] == 4
        assert "category_ratings" in result
        assert "improvement_priority" in result

        # Score should be between 0 and 100
        assert 0 <= result["overall_score"] <= 100

    def test_get_overall_flexibility_score_empty(self, flexibility_service):
        """Test overall score with no assessments."""
        result = flexibility_service.get_overall_flexibility_score({})
        assert "error" in result

    def test_improvement_priorities_poor_first(self, flexibility_service):
        """Test that improvement priorities list poor ratings first."""
        assessments = {
            "sit_and_reach": {"rating": "excellent", "measurement": 12.0},
            "shoulder_flexibility": {"rating": "poor", "measurement": 8.0},
            "hamstring": {"rating": "fair", "measurement": 55.0},
        }

        result = flexibility_service.get_overall_flexibility_score(assessments)
        priorities = result["improvement_priority"]

        assert len(priorities) == 2  # Only poor and fair
        assert priorities[0]["current_rating"] == "poor"
        assert priorities[1]["current_rating"] == "fair"


# ============ Tests: API Endpoints ============

class TestGetFlexibilityTests:
    """Tests for GET /api/v1/flexibility/tests endpoint."""

    def test_get_all_tests_success(self, client):
        """Test successfully fetching all flexibility tests."""
        response = client.get("/api/v1/flexibility/tests")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 10

        # Verify test structure
        test = data[0]
        assert "id" in test
        assert "name" in test
        assert "instructions" in test
        assert "unit" in test

    def test_get_specific_test(self, client):
        """Test fetching a specific flexibility test."""
        response = client.get("/api/v1/flexibility/tests/sit_and_reach")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "sit_and_reach"
        assert data["name"] == "Sit and Reach Test"
        assert "hamstrings" in data["target_muscles"]

    def test_get_nonexistent_test(self, client):
        """Test fetching a non-existent test returns 404."""
        response = client.get("/api/v1/flexibility/tests/invalid_test")

        assert response.status_code == 404


class TestRecordAssessment:
    """Tests for POST /api/v1/flexibility/user/{user_id}/assessment endpoint."""

    def test_record_assessment_success(self, client, mock_supabase, mock_user_id):
        """Test successfully recording a flexibility assessment."""
        mock_user_result = MagicMock()
        mock_user_result.data = [{"id": mock_user_id, "age": 30, "gender": "male"}]

        created_assessment = generate_mock_assessment(
            user_id=mock_user_id,
            measurement=6.0,
            rating="good"
        )
        mock_insert_result = MagicMock()
        mock_insert_result.data = [created_assessment]

        def mock_table_side_effect(table_name):
            mock_table = MagicMock()
            if table_name == "users":
                mock_table.select.return_value.eq.return_value.execute.return_value = mock_user_result
            elif table_name == "flexibility_assessments":
                mock_table.insert.return_value.execute.return_value = mock_insert_result
            return mock_table

        mock_supabase.table.side_effect = mock_table_side_effect

        with patch("api.v1.flexibility.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.flexibility.log_user_activity", new_callable=AsyncMock):
                response = client.post(
                    f"/api/v1/flexibility/user/{mock_user_id}/assessment",
                    json={
                        "test_type": "sit_and_reach",
                        "measurement": 6.0,
                        "notes": "Felt good stretch"
                    }
                )

                assert response.status_code == 200
                data = response.json()
                assert "assessment" in data
                assert "message" in data
                assert data["assessment"]["rating"] == "good"

    def test_record_assessment_invalid_test_type(self, client, mock_user_id):
        """Test recording assessment with invalid test type."""
        response = client.post(
            f"/api/v1/flexibility/user/{mock_user_id}/assessment",
            json={
                "test_type": "invalid_test",
                "measurement": 10.0
            }
        )

        assert response.status_code == 400


class TestGetAssessmentHistory:
    """Tests for GET /api/v1/flexibility/user/{user_id}/assessments endpoint."""

    def test_get_history_success(self, client, mock_supabase, mock_user_id):
        """Test successfully fetching assessment history."""
        assessments = [
            generate_mock_assessment(user_id=mock_user_id, measurement=4.0),
            generate_mock_assessment(user_id=mock_user_id, measurement=6.0),
            generate_mock_assessment(user_id=mock_user_id, measurement=8.0),
        ]

        mock_result = MagicMock()
        mock_result.data = assessments
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_result

        with patch("api.v1.flexibility.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/flexibility/user/{mock_user_id}/assessments")

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 3

    def test_get_history_filtered_by_test_type(self, client, mock_supabase, mock_user_id):
        """Test fetching history filtered by test type."""
        assessments = [
            generate_mock_assessment(user_id=mock_user_id, test_type="sit_and_reach"),
        ]

        mock_result = MagicMock()
        mock_result.data = assessments
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_result

        with patch("api.v1.flexibility.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(
                f"/api/v1/flexibility/user/{mock_user_id}/assessments?test_type=sit_and_reach"
            )

            assert response.status_code == 200

    def test_get_history_empty(self, client, mock_supabase, mock_user_id):
        """Test fetching empty history."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_result

        with patch("api.v1.flexibility.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/flexibility/user/{mock_user_id}/assessments")

            assert response.status_code == 200
            assert response.json() == []


class TestGetProgressTrend:
    """Tests for GET /api/v1/flexibility/user/{user_id}/progress/{test_type} endpoint."""

    def test_get_progress_success(self, client, mock_supabase, mock_user_id):
        """Test successfully fetching progress trend."""
        assessments = [
            {
                "measurement": 2.0,
                "rating": "fair",
                "assessed_at": "2024-01-01T00:00:00",
            },
            {
                "measurement": 4.0,
                "rating": "fair",
                "assessed_at": "2024-02-01T00:00:00",
            },
            {
                "measurement": 7.0,
                "rating": "good",
                "assessed_at": "2024-03-01T00:00:00",
            },
        ]

        test_info = generate_mock_flexibility_test()

        mock_result = MagicMock()
        mock_result.data = assessments
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.flexibility.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(
                f"/api/v1/flexibility/user/{mock_user_id}/progress/sit_and_reach"
            )

            assert response.status_code == 200
            data = response.json()
            assert "trend_data" in data
            assert "improvement_absolute" in data

    def test_get_progress_insufficient_data(self, client, mock_supabase, mock_user_id):
        """Test progress with only one assessment."""
        mock_result = MagicMock()
        mock_result.data = [{"measurement": 5.0, "rating": "good", "assessed_at": "2024-01-01"}]
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.flexibility.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(
                f"/api/v1/flexibility/user/{mock_user_id}/progress/sit_and_reach"
            )

            # Should still return 200 but with limited data
            assert response.status_code == 200


class TestGetFlexibilitySummary:
    """Tests for GET /api/v1/flexibility/user/{user_id}/summary endpoint."""

    def test_get_summary_success(self, client, mock_supabase, mock_user_id):
        """Test successfully fetching flexibility summary."""
        # Mock latest assessments for different test types
        latest_assessments = [
            {"test_type": "sit_and_reach", "measurement": 6.0, "rating": "good"},
            {"test_type": "shoulder_flexibility", "measurement": 3.0, "rating": "fair"},
            {"test_type": "hamstring", "measurement": 75.0, "rating": "good"},
        ]

        mock_result = MagicMock()
        mock_result.data = latest_assessments
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.flexibility.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/flexibility/user/{mock_user_id}/summary")

            assert response.status_code == 200
            data = response.json()
            assert "overall_score" in data
            assert "overall_rating" in data
            assert "tests_completed" in data


class TestGetFlexibilityScore:
    """Tests for GET /api/v1/flexibility/user/{user_id}/score endpoint."""

    def test_get_score_success(self, client, mock_supabase, mock_user_id):
        """Test successfully fetching flexibility score."""
        latest_assessments = [
            {"test_type": "sit_and_reach", "rating": "good"},
            {"test_type": "hamstring", "rating": "excellent"},
        ]

        mock_result = MagicMock()
        mock_result.data = latest_assessments
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = mock_result

        with patch("api.v1.flexibility.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            response = client.get(f"/api/v1/flexibility/user/{mock_user_id}/score")

            assert response.status_code == 200
            data = response.json()
            assert "score" in data


class TestDeleteAssessment:
    """Tests for DELETE /api/v1/flexibility/user/{user_id}/assessment/{assessment_id} endpoint."""

    def test_delete_assessment_success(self, client, mock_supabase, mock_user_id):
        """Test successfully deleting an assessment."""
        assessment_id = str(uuid.uuid4())

        mock_result = MagicMock()
        mock_result.data = [{"id": assessment_id}]
        mock_supabase.table.return_value.delete.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        with patch("api.v1.flexibility.get_supabase_db") as mock_get_db:
            mock_db = MagicMock()
            mock_db.client = mock_supabase
            mock_get_db.return_value = mock_db

            with patch("api.v1.flexibility.log_user_activity", new_callable=AsyncMock):
                response = client.delete(
                    f"/api/v1/flexibility/user/{mock_user_id}/assessment/{assessment_id}"
                )

                assert response.status_code == 200
                assert response.json()["success"] is True


# ============ Tests: Test Data Validation ============

class TestFlexibilityTestData:
    """Tests to validate flexibility test data integrity."""

    def test_all_tests_have_required_fields(self):
        """Test that all flexibility tests have required fields."""
        required_fields = [
            "id", "name", "description", "instructions", "unit",
            "target_muscles", "equipment_needed", "norms", "tips", "common_mistakes"
        ]

        for test_id, test in FLEXIBILITY_TESTS.items():
            for field in required_fields:
                assert hasattr(test, field), f"Test {test_id} missing field {field}"

    def test_all_tests_have_norms_for_both_genders(self):
        """Test that all tests have norms for male and female."""
        for test_id, test in FLEXIBILITY_TESTS.items():
            assert "male" in test.norms, f"Test {test_id} missing male norms"
            assert "female" in test.norms, f"Test {test_id} missing female norms"

    def test_all_tests_have_norms_for_all_age_groups(self):
        """Test that all tests have norms for all age groups."""
        age_groups = ["18-29", "30-39", "40-49", "50-59", "60+"]

        for test_id, test in FLEXIBILITY_TESTS.items():
            for gender in ["male", "female"]:
                for age_group in age_groups:
                    assert age_group in test.norms[gender], \
                        f"Test {test_id} missing {gender}/{age_group} norms"

    def test_all_tests_have_stretch_recommendations(self):
        """Test that all tests have stretch recommendations for all ratings."""
        ratings = ["poor", "fair", "good", "excellent"]

        for test_id in FLEXIBILITY_TESTS.keys():
            assert test_id in STRETCH_RECOMMENDATIONS, \
                f"Test {test_id} missing from recommendations"

            for rating in ratings:
                assert rating in STRETCH_RECOMMENDATIONS[test_id], \
                    f"Test {test_id} missing {rating} recommendations"

    def test_test_count_is_ten(self):
        """Test that we have exactly 10 flexibility tests."""
        assert len(FLEXIBILITY_TESTS) == 10

        expected_tests = [
            "sit_and_reach", "shoulder_flexibility", "hip_flexor",
            "hamstring", "ankle_dorsiflexion", "thoracic_rotation",
            "groin_flexibility", "quadriceps", "calf_flexibility", "neck_rotation"
        ]

        for test_id in expected_tests:
            assert test_id in FLEXIBILITY_TESTS, f"Missing expected test: {test_id}"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
