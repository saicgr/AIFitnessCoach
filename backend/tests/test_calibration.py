"""
Tests for Calibration Workout API endpoints.

Tests all calibration functionality including:
- Get calibration status for a user
- Generate a new calibration workout
- Start a calibration workout
- Complete calibration with exercise results
- Accept/decline suggested adjustments
- Skip calibration
- Get calibration results
- Get strength baselines
"""
import pytest
from unittest.mock import Mock, MagicMock, patch, AsyncMock
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
import uuid
import json

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app


# ============ Mock Data Generators ============

def generate_mock_user(
    user_id: str = None,
    fitness_level: str = "intermediate",
    calibration_completed: bool = False,
    calibration_skipped: bool = False,
    equipment: list = None,
):
    """Generate a mock user profile."""
    return {
        "id": user_id or str(uuid.uuid4()),
        "fitness_level": fitness_level,
        "goals": ["build_muscle", "lose_fat"],
        "equipment": equipment or ["dumbbells", "barbell", "pull_up_bar"],
        "date_of_birth": "1990-01-01",
        "gender": "male",
        "weight_unit": "lbs",
        "calibration_completed": calibration_completed,
        "calibration_skipped": calibration_skipped,
        "last_calibrated_at": None,
    }


def generate_mock_calibration_workout(
    calibration_id: str = None,
    user_id: str = None,
    status: str = "generated",
    exercise_count: int = 5,
):
    """Generate a mock calibration workout."""
    exercises = []
    exercise_templates = [
        {"name": "Bench Press", "target_muscle": "chest", "equipment": "barbell"},
        {"name": "Pull-ups", "target_muscle": "back", "equipment": "pull-up bar"},
        {"name": "Barbell Squat", "target_muscle": "legs", "equipment": "barbell"},
        {"name": "Shoulder Press", "target_muscle": "shoulders", "equipment": "dumbbells"},
        {"name": "Plank", "target_muscle": "core", "equipment": "bodyweight"},
    ]

    for i, template in enumerate(exercise_templates[:exercise_count]):
        exercises.append({
            "id": str(uuid.uuid4()),
            "name": template["name"],
            "target_muscle": template["target_muscle"],
            "equipment": template["equipment"],
            "is_compound": True,
            "test_type": "max_reps" if template["name"] != "Plank" else "time",
            "instructions": f"Test instructions for {template['name']}",
        })

    return {
        "id": calibration_id or str(uuid.uuid4()),
        "user_id": user_id or str(uuid.uuid4()),
        "status": status,
        "exercises_json": json.dumps(exercises),
        "estimated_duration_minutes": 20,
        "instructions": "Complete each exercise to your maximum ability.",
        "created_at": datetime.utcnow().isoformat(),
        "started_at": None if status == "generated" else datetime.utcnow().isoformat(),
        "completed_at": None if status != "completed" else datetime.utcnow().isoformat(),
        "results_json": None,
        "ai_analysis": None,
        "suggested_adjustments": None,
        "user_accepted_adjustments": None,
    }


def generate_mock_exercise_performance(
    exercise_id: str = None,
    exercise_name: str = "Bench Press",
    weight_used: float = 135.0,
    reps_completed: int = 10,
    rpe: int = 7,
):
    """Generate a mock exercise performance result."""
    return {
        "exercise_id": exercise_id or str(uuid.uuid4()),
        "exercise_name": exercise_name,
        "weight_used": weight_used,
        "weight_unit": "lbs",
        "reps_completed": reps_completed,
        "time_seconds": None,
        "rpe": rpe,
        "notes": None,
        "felt_easy": rpe <= 5,
        "felt_hard": rpe >= 8,
    }


def generate_mock_calibration_result(
    exercise_count: int = 5,
    overall_difficulty: str = "just_right",
):
    """Generate a mock calibration result with exercise performances."""
    exercises = [
        ("Bench Press", 135.0, 10, 7),
        ("Pull-ups", 0.0, 8, 8),
        ("Barbell Squat", 185.0, 12, 6),
        ("Shoulder Press", 50.0, 10, 7),
        ("Plank", None, None, 6),  # Time-based
    ]

    performances = []
    for i, (name, weight, reps, rpe) in enumerate(exercises[:exercise_count]):
        perf = generate_mock_exercise_performance(
            exercise_name=name,
            weight_used=weight or 0,
            reps_completed=reps or 0,
            rpe=rpe,
        )
        if name == "Plank":
            perf["time_seconds"] = 60
        performances.append(perf)

    return {
        "exercise_performances": performances,
        "overall_difficulty": overall_difficulty,
        "user_notes": "Felt good overall",
        "total_duration_minutes": 25,
    }


def generate_mock_strength_baseline(
    user_id: str = None,
    exercise_name: str = "Bench Press",
    baseline_weight: float = 135.0,
    baseline_reps: int = 10,
    estimated_1rm: float = 180.0,
):
    """Generate a mock strength baseline."""
    return {
        "id": str(uuid.uuid4()),
        "user_id": user_id or str(uuid.uuid4()),
        "exercise_name": exercise_name,
        "muscle_group": "chest",
        "baseline_weight": baseline_weight,
        "baseline_reps": baseline_reps,
        "estimated_1rm": estimated_1rm,
        "weight_unit": "lbs",
        "confidence_level": 0.9,
        "source": "calibration",
        "calibration_id": str(uuid.uuid4()),
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": None,
    }


def generate_mock_calibration_analysis(
    suggested_fitness_level: str = "intermediate",
    strength_level: str = "intermediate",
):
    """Generate a mock AI calibration analysis."""
    return {
        "summary": "Your calibration workout shows solid intermediate-level performance across all muscle groups.",
        "strength_level": strength_level,
        "suggested_fitness_level": suggested_fitness_level,
        "adjustments": [
            {
                "adjustment_type": "fitness_level",
                "current_value": "beginner",
                "suggested_value": suggested_fitness_level,
                "reason": "Your performance indicates you can handle more challenging workouts.",
                "confidence": 0.85,
            }
        ],
        "muscle_group_analysis": {
            "chest": {"level": "intermediate", "estimated_1rm": 180},
            "back": {"level": "intermediate", "notes": "Good pull-up performance"},
            "legs": {"level": "intermediate", "estimated_1rm": 225},
        },
        "recommendations": [
            "Focus on progressive overload for continued strength gains",
            "Your squat form looks strong - consider adding weight",
            "Core endurance is good - incorporate anti-rotation exercises",
        ],
    }


# ============ Mock Supabase Setup ============

@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    with patch("api.v1.calibration.get_supabase") as mock_get_supabase:
        mock_client = MagicMock()
        mock_supabase_instance = MagicMock()
        mock_supabase_instance.client = mock_client
        mock_get_supabase.return_value = mock_supabase_instance
        yield mock_client


@pytest.fixture
def mock_gemini():
    """Create a mock Gemini service."""
    with patch("api.v1.calibration.GeminiService") as mock_gemini_class:
        mock_service = MagicMock()
        mock_service.chat = AsyncMock(return_value=json.dumps(
            generate_mock_calibration_analysis()
        ))
        mock_gemini_class.return_value = mock_service
        yield mock_service


@pytest.fixture
def mock_activity_logger():
    """Mock the activity logger functions."""
    with patch("api.v1.calibration.log_user_activity") as mock_log_activity, \
         patch("api.v1.calibration.log_user_error") as mock_log_error:
        mock_log_activity.return_value = AsyncMock()()
        mock_log_error.return_value = AsyncMock()()
        yield mock_log_activity, mock_log_error


@pytest.fixture
def client():
    """Create a test client."""
    return TestClient(app)


# ============ Calibration Status Tests ============

class TestCalibrationStatus:
    """Tests for GET /calibration/status/{user_id}"""

    def test_get_status_pending(self, client, mock_supabase, mock_activity_logger):
        """Test getting calibration status when pending."""
        user_id = str(uuid.uuid4())
        mock_user = generate_mock_user(user_id=user_id)

        # Mock user lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_user]

        # Mock calibration lookup (no calibration exists)
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []

        response = client.get(f"/api/v1/calibration/status/{user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "pending"
        assert data["calibration_completed"] is False
        assert data["calibration_skipped"] is False
        assert data["can_recalibrate"] is True

    def test_get_status_completed(self, client, mock_supabase, mock_activity_logger):
        """Test getting calibration status when completed."""
        user_id = str(uuid.uuid4())
        calibration_id = str(uuid.uuid4())

        mock_user = generate_mock_user(
            user_id=user_id,
            calibration_completed=True,
        )
        mock_user["last_calibrated_at"] = datetime.utcnow().isoformat()

        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            user_id=user_id,
            status="completed",
        )

        # Mock user lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_user]

        # Mock calibration lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = [mock_calibration]

        response = client.get(f"/api/v1/calibration/status/{user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert data["calibration_completed"] is True
        assert data["calibration_workout_id"] == calibration_id

    def test_get_status_skipped(self, client, mock_supabase, mock_activity_logger):
        """Test getting calibration status when skipped."""
        user_id = str(uuid.uuid4())

        mock_user = generate_mock_user(
            user_id=user_id,
            calibration_skipped=True,
        )

        # Mock user lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_user]

        response = client.get(f"/api/v1/calibration/status/{user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "skipped"
        assert data["calibration_skipped"] is True

    def test_get_status_user_not_found(self, client, mock_supabase, mock_activity_logger):
        """Test getting status for non-existent user."""
        user_id = str(uuid.uuid4())

        # Mock user lookup - no user found
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.get(f"/api/v1/calibration/status/{user_id}")

        assert response.status_code == 404


# ============ Generate Calibration Tests ============

class TestGenerateCalibration:
    """Tests for POST /calibration/generate/{user_id}"""

    def test_generate_calibration_success(self, client, mock_supabase, mock_activity_logger):
        """Test generating a new calibration workout."""
        user_id = str(uuid.uuid4())
        mock_user = generate_mock_user(user_id=user_id)

        # Mock user lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_user]

        # Mock insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{"id": str(uuid.uuid4())}]

        response = client.post(f"/api/v1/calibration/generate/{user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == user_id
        assert data["status"] == "generated"
        assert len(data["exercises"]) > 0
        assert data["estimated_duration_minutes"] == 20

    def test_generate_calibration_with_custom_duration(self, client, mock_supabase, mock_activity_logger):
        """Test generating calibration with custom duration preference."""
        user_id = str(uuid.uuid4())
        mock_user = generate_mock_user(user_id=user_id)

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_user]
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{"id": str(uuid.uuid4())}]

        response = client.post(
            f"/api/v1/calibration/generate/{user_id}",
            json={"duration_preference": 30}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["estimated_duration_minutes"] == 30

    def test_generate_calibration_bodyweight_only(self, client, mock_supabase, mock_activity_logger):
        """Test generating calibration for user with bodyweight only."""
        user_id = str(uuid.uuid4())
        mock_user = generate_mock_user(user_id=user_id, equipment=[])

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_user]
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{"id": str(uuid.uuid4())}]

        response = client.post(f"/api/v1/calibration/generate/{user_id}")

        assert response.status_code == 200
        data = response.json()

        # Should have bodyweight exercises
        exercises = data["exercises"]
        assert any(ex["name"] == "Push-ups" for ex in exercises)
        assert any(ex["name"] == "Bodyweight Squats" for ex in exercises)

    def test_generate_calibration_user_not_found(self, client, mock_supabase, mock_activity_logger):
        """Test generating for non-existent user."""
        user_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.post(f"/api/v1/calibration/generate/{user_id}")

        assert response.status_code == 404


# ============ Start Calibration Tests ============

class TestStartCalibration:
    """Tests for POST /calibration/start/{calibration_id}"""

    def test_start_calibration_success(self, client, mock_supabase, mock_activity_logger):
        """Test starting a calibration workout."""
        calibration_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())

        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            user_id=user_id,
            status="generated",
        )

        # Mock calibration lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_calibration]

        # Mock update
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{"id": calibration_id}]

        response = client.post(f"/api/v1/calibration/start/{calibration_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["calibration_id"] == calibration_id
        assert "started_at" in data

    def test_start_calibration_already_completed(self, client, mock_supabase, mock_activity_logger):
        """Test starting an already completed calibration."""
        calibration_id = str(uuid.uuid4())

        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            status="completed",
        )

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_calibration]

        response = client.post(f"/api/v1/calibration/start/{calibration_id}")

        assert response.status_code == 400

    def test_start_calibration_not_found(self, client, mock_supabase, mock_activity_logger):
        """Test starting non-existent calibration."""
        calibration_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.post(f"/api/v1/calibration/start/{calibration_id}")

        assert response.status_code == 404


# ============ Complete Calibration Tests ============

class TestCompleteCalibration:
    """Tests for POST /calibration/complete/{calibration_id}"""

    def test_complete_calibration_success(self, client, mock_supabase, mock_gemini, mock_activity_logger):
        """Test completing a calibration workout with results."""
        calibration_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())

        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            user_id=user_id,
            status="in_progress",
        )

        mock_user = generate_mock_user(user_id=user_id, fitness_level="beginner")

        # Mock calibration lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            MagicMock(data=[mock_calibration]),  # First call for calibration
            MagicMock(data=[mock_user]),  # Second call for user
        ]

        # Mock inserts/updates
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{}]
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        results = generate_mock_calibration_result()

        response = client.post(
            f"/api/v1/calibration/complete/{calibration_id}",
            json=results,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["calibration_id"] == calibration_id
        assert "analysis" in data
        assert "suggested_adjustments" in data

    def test_complete_calibration_not_started(self, client, mock_supabase, mock_activity_logger):
        """Test completing a calibration that wasn't started."""
        calibration_id = str(uuid.uuid4())

        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            status="completed",
        )

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_calibration]

        results = generate_mock_calibration_result()

        response = client.post(
            f"/api/v1/calibration/complete/{calibration_id}",
            json=results,
        )

        assert response.status_code == 400


# ============ Accept/Decline Adjustments Tests ============

class TestAdjustments:
    """Tests for accept/decline adjustment endpoints."""

    def test_accept_adjustments_success(self, client, mock_supabase, mock_activity_logger):
        """Test accepting suggested adjustments."""
        calibration_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())

        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            user_id=user_id,
            status="completed",
        )
        mock_calibration["suggested_adjustments"] = json.dumps({
            "fitness_level": {
                "current": "beginner",
                "suggested": "intermediate",
                "should_change": True,
            },
            "adjustments": [],
        })

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_calibration]
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.post(f"/api/v1/calibration/accept-adjustments/{calibration_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "fitness_level" in data["updates_applied"]

    def test_decline_adjustments_success(self, client, mock_supabase, mock_activity_logger):
        """Test declining suggested adjustments."""
        calibration_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())

        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            user_id=user_id,
            status="completed",
        )

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_calibration]
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.post(f"/api/v1/calibration/decline-adjustments/{calibration_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_accept_adjustments_not_completed(self, client, mock_supabase, mock_activity_logger):
        """Test accepting adjustments for non-completed calibration."""
        calibration_id = str(uuid.uuid4())

        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            status="in_progress",
        )

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [mock_calibration]

        response = client.post(f"/api/v1/calibration/accept-adjustments/{calibration_id}")

        assert response.status_code == 400


# ============ Skip Calibration Tests ============

class TestSkipCalibration:
    """Tests for POST /calibration/skip/{user_id}"""

    def test_skip_calibration_success(self, client, mock_supabase, mock_activity_logger):
        """Test skipping calibration."""
        user_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{"id": user_id}]
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.post(f"/api/v1/calibration/skip/{user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "skipped" in data["message"].lower()

    def test_skip_calibration_user_not_found(self, client, mock_supabase, mock_activity_logger):
        """Test skipping for non-existent user."""
        user_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.post(f"/api/v1/calibration/skip/{user_id}")

        assert response.status_code == 404


# ============ Get Results Tests ============

class TestGetResults:
    """Tests for GET /calibration/results/{calibration_id}"""

    def test_get_results_success(self, client, mock_supabase, mock_activity_logger):
        """Test getting calibration results."""
        calibration_id = str(uuid.uuid4())

        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            status="completed",
        )
        mock_calibration["results_json"] = json.dumps(
            generate_mock_calibration_result()["exercise_performances"]
        )
        mock_calibration["ai_analysis"] = json.dumps(generate_mock_calibration_analysis())
        mock_calibration["suggested_adjustments"] = json.dumps({
            "fitness_level": {"current": "beginner", "suggested": "intermediate", "should_change": True}
        })

        # Mock calibration lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            MagicMock(data=[mock_calibration]),
            MagicMock(data=[]),  # baselines count
        ]

        response = client.get(f"/api/v1/calibration/results/{calibration_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["calibration_id"] == calibration_id
        assert data["status"] == "completed"
        assert data["ai_analysis"] is not None

    def test_get_results_not_found(self, client, mock_supabase, mock_activity_logger):
        """Test getting results for non-existent calibration."""
        calibration_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

        response = client.get(f"/api/v1/calibration/results/{calibration_id}")

        assert response.status_code == 404


# ============ Get Baselines Tests ============

class TestGetBaselines:
    """Tests for GET /calibration/baselines/{user_id}"""

    def test_get_baselines_success(self, client, mock_supabase, mock_activity_logger):
        """Test getting user's strength baselines."""
        user_id = str(uuid.uuid4())

        baselines = [
            generate_mock_strength_baseline(user_id=user_id, exercise_name="Bench Press"),
            generate_mock_strength_baseline(user_id=user_id, exercise_name="Squat"),
        ]

        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = baselines

        response = client.get(f"/api/v1/calibration/baselines/{user_id}")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["exercise_name"] == "Bench Press"

    def test_get_baselines_empty(self, client, mock_supabase, mock_activity_logger):
        """Test getting baselines when none exist."""
        user_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value.data = []

        response = client.get(f"/api/v1/calibration/baselines/{user_id}")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 0

    def test_get_baselines_filtered_by_exercise(self, client, mock_supabase, mock_activity_logger):
        """Test getting baselines filtered by exercise name."""
        user_id = str(uuid.uuid4())

        baselines = [
            generate_mock_strength_baseline(user_id=user_id, exercise_name="Bench Press"),
        ]

        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.execute.return_value.data = baselines

        response = client.get(
            f"/api/v1/calibration/baselines/{user_id}",
            params={"exercise_name": "Bench Press"}
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["exercise_name"] == "Bench Press"


# ============ 1RM Calculation Tests ============

class Test1RMCalculation:
    """Tests for the 1RM calculation helper function."""

    def test_brzycki_formula_10_reps(self):
        """Test Brzycki formula with 10 reps."""
        from api.v1.calibration import _calculate_estimated_1rm

        # 135 lbs x 10 reps should give approximately 180 lbs 1RM
        result = _calculate_estimated_1rm(135, 10)
        assert 175 <= result <= 185

    def test_brzycki_formula_1_rep(self):
        """Test Brzycki formula with 1 rep (should equal weight)."""
        from api.v1.calibration import _calculate_estimated_1rm

        result = _calculate_estimated_1rm(200, 1)
        assert result == 200.0

    def test_brzycki_formula_high_reps(self):
        """Test Brzycki formula with very high reps (capped at 36)."""
        from api.v1.calibration import _calculate_estimated_1rm

        # Should not return infinity or unrealistic values
        result = _calculate_estimated_1rm(50, 40)
        assert result > 0
        assert result < 10000  # Reasonable upper bound

    def test_brzycki_formula_zero_values(self):
        """Test Brzycki formula with zero values."""
        from api.v1.calibration import _calculate_estimated_1rm

        assert _calculate_estimated_1rm(0, 10) == 0.0
        assert _calculate_estimated_1rm(100, 0) == 0.0


# ============ Integration Tests ============

class TestCalibrationFlow:
    """End-to-end tests for the calibration workflow."""

    def test_full_calibration_flow(self, client, mock_supabase, mock_gemini, mock_activity_logger):
        """Test the complete calibration workflow."""
        user_id = str(uuid.uuid4())
        calibration_id = str(uuid.uuid4())

        mock_user = generate_mock_user(user_id=user_id, fitness_level="beginner")
        mock_calibration = generate_mock_calibration_workout(
            calibration_id=calibration_id,
            user_id=user_id,
        )

        # Setup mocks for the entire flow
        def mock_table(table_name):
            mock = MagicMock()
            if table_name == "users":
                mock.select.return_value.eq.return_value.execute.return_value.data = [mock_user]
            elif table_name == "calibration_workouts":
                mock.select.return_value.eq.return_value.execute.return_value.data = [mock_calibration]
                mock.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []
                mock.insert.return_value.execute.return_value.data = [{"id": calibration_id}]
                mock.update.return_value.eq.return_value.execute.return_value.data = [{}]
            elif table_name == "strength_baselines":
                mock.insert.return_value.execute.return_value.data = [{}]
                mock.select.return_value.eq.return_value.execute.return_value.data = []
            return mock

        mock_supabase.table.side_effect = mock_table

        # Step 1: Check initial status
        response = client.get(f"/api/v1/calibration/status/{user_id}")
        assert response.status_code == 200
        assert response.json()["status"] == "pending"

        # Step 2: Generate calibration workout
        mock_supabase.table.side_effect = mock_table
        response = client.post(f"/api/v1/calibration/generate/{user_id}")
        assert response.status_code == 200

        # Step 3: Start calibration
        mock_calibration["status"] = "generated"
        mock_supabase.table.side_effect = mock_table
        response = client.post(f"/api/v1/calibration/start/{calibration_id}")
        assert response.status_code == 200

        # Step 4: Complete calibration would require more complex mocking
        # This is tested in individual tests above

        print("✅ Full calibration flow test passed")
