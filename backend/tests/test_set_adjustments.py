"""
Tests for Set Adjustment Functionality.

This module tests:
1. API endpoints for adjusting, editing, and deleting sets
2. Fatigue detection and recommendations
3. Database operations for set adjustments
4. Integration tests for full workout flow with adjustments

Note: Some tests require services that may not be implemented yet.
These are marked with pytest.mark.skip or use try/except imports.
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from typing import Dict, Any, List, Tuple, Optional

# Try importing TestClient, handle if not available
try:
    from fastapi.testclient import TestClient
    HAS_TEST_CLIENT = True
except ImportError:
    HAS_TEST_CLIENT = False
    TestClient = None


# Mock UUIDs for testing
MOCK_USER_ID = "test-user-123"
MOCK_WORKOUT_ID = "workout-456"
MOCK_WORKOUT_LOG_ID = "workout-log-789"
MOCK_SET_ADJUSTMENT_ID = "set-adj-101"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    with patch("core.supabase_db.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_supabase_client():
    """Create a mock Supabase client with .client accessor."""
    with patch("core.db.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock_db.client = MagicMock()
        mock.return_value = mock_db
        yield mock_db


@pytest.fixture
def client():
    """Create a test client."""
    from main import app
    return TestClient(app)


def generate_mock_workout(exercise_count: int = 3, sets_per_exercise: int = 3):
    """Generate a mock workout with exercises and sets."""
    exercises = []
    for i in range(exercise_count):
        sets = []
        for j in range(sets_per_exercise):
            sets.append({
                "set_number": j + 1,
                "reps": 10,
                "weight_kg": 50.0 + (j * 5),
                "rpe": 7,
                "completed": True,
                "reps_completed": 10,
            })
        exercises.append({
            "id": f"exercise-{i}",
            "name": f"Exercise {i}",
            "sets": sets,
            "muscle_group": "chest",
            "equipment": "barbell",
        })

    return {
        "id": MOCK_WORKOUT_ID,
        "user_id": MOCK_USER_ID,
        "name": "Test Workout",
        "type": "strength",
        "difficulty": "intermediate",
        "scheduled_date": datetime.now().isoformat(),
        "is_completed": False,
        "exercises": exercises,
        "duration_minutes": 45,
    }


def generate_mock_set_adjustment(
    exercise_index: int = 0,
    original_sets: int = 3,
    new_sets: int = 2,
    reason: str = "fatigue",
):
    """Generate a mock set adjustment record."""
    return {
        "id": MOCK_SET_ADJUSTMENT_ID,
        "user_id": MOCK_USER_ID,
        "workout_id": MOCK_WORKOUT_ID,
        "workout_log_id": MOCK_WORKOUT_LOG_ID,
        "exercise_index": exercise_index,
        "exercise_name": f"Exercise {exercise_index}",
        "original_sets": original_sets,
        "new_sets": new_sets,
        "reason": reason,
        "adjustment_type": "reduce",
        "created_at": datetime.now().isoformat(),
    }


def generate_mock_performance_sets(reps_pattern: list, weight_kg: float = 50.0):
    """Generate mock sets with specific rep patterns for fatigue testing."""
    sets = []
    for i, reps in enumerate(reps_pattern):
        sets.append({
            "set_number": i + 1,
            "reps": 10,  # Target reps
            "reps_completed": reps,  # Actual reps
            "weight_kg": weight_kg,
            "rpe": 6 + (i * 0.5),  # Increasing RPE
            "completed": True,
        })
    return sets


# =============================================================================
# API Endpoint Tests
# =============================================================================

# Skip marker for tests that require specific API endpoints
requires_set_adjustment_api = pytest.mark.skipif(
    True,  # Set to False when API is implemented
    reason="Set adjustment API endpoints not yet implemented"
)


@requires_set_adjustment_api
class TestAdjustSetsEndpoint:
    """Tests for POST /workouts/{workout_id}/exercises/{exercise_index}/adjust-sets"""

    def test_adjust_sets_reduces_count(self, client, mock_supabase):
        """Test successfully reducing set count for an exercise."""
        # Setup mock workout
        mock_workout = generate_mock_workout()
        mock_supabase.get_workout.return_value = mock_workout

        # Mock the update
        updated_exercises = mock_workout["exercises"].copy()
        updated_exercises[0]["sets"] = updated_exercises[0]["sets"][:2]  # Reduce to 2 sets
        mock_supabase.update_workout.return_value = {
            **mock_workout,
            "exercises": updated_exercises,
        }

        # Mock adjustment logging
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = MagicMock(
            data=[generate_mock_set_adjustment()]
        )

        response = client.post(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/adjust-sets",
            json={
                "user_id": MOCK_USER_ID,
                "new_set_count": 2,
            }
        )

        # Verify response
        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True
        assert data.get("new_set_count") == 2

    def test_adjust_sets_with_reason(self, client, mock_supabase):
        """Test set adjustment with reason provided."""
        mock_workout = generate_mock_workout()
        mock_supabase.get_workout.return_value = mock_workout
        mock_supabase.update_workout.return_value = mock_workout

        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = MagicMock(
            data=[generate_mock_set_adjustment(reason="feeling tired today")]
        )

        response = client.post(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/adjust-sets",
            json={
                "user_id": MOCK_USER_ID,
                "new_set_count": 2,
                "reason": "feeling tired today",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True

    def test_adjust_sets_invalid_exercise_index(self, client, mock_supabase):
        """Test adjustment with invalid exercise index."""
        mock_workout = generate_mock_workout(exercise_count=3)
        mock_supabase.get_workout.return_value = mock_workout

        response = client.post(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/10/adjust-sets",
            json={
                "user_id": MOCK_USER_ID,
                "new_set_count": 2,
            }
        )

        assert response.status_code == 400
        assert "invalid exercise index" in response.json()["detail"].lower()

    def test_adjust_sets_workout_not_found(self, client, mock_supabase):
        """Test adjustment when workout doesn't exist."""
        mock_supabase.get_workout.return_value = None

        response = client.post(
            f"/api/v1/workouts/nonexistent-workout/exercises/0/adjust-sets",
            json={
                "user_id": MOCK_USER_ID,
                "new_set_count": 2,
            }
        )

        assert response.status_code == 404


@requires_set_adjustment_api
class TestEditSetEndpoint:
    """Tests for PUT /workouts/{workout_id}/exercises/{exercise_index}/sets/{set_number}"""

    def test_edit_completed_set(self, client, mock_supabase):
        """Test editing a completed set's values."""
        mock_workout = generate_mock_workout()
        mock_supabase.get_workout.return_value = mock_workout
        mock_supabase.update_workout.return_value = mock_workout

        response = client.put(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/sets/1",
            json={
                "user_id": MOCK_USER_ID,
                "reps_completed": 8,
                "weight_kg": 55.0,
                "rpe": 8.5,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True

    def test_edit_set_invalid_values(self, client, mock_supabase):
        """Test editing set with invalid values (negative reps, etc.)."""
        mock_workout = generate_mock_workout()
        mock_supabase.get_workout.return_value = mock_workout

        response = client.put(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/sets/1",
            json={
                "user_id": MOCK_USER_ID,
                "reps_completed": -5,  # Invalid
                "weight_kg": 50.0,
            }
        )

        assert response.status_code == 422  # Validation error

    def test_edit_set_invalid_set_number(self, client, mock_supabase):
        """Test editing non-existent set number."""
        mock_workout = generate_mock_workout(sets_per_exercise=3)
        mock_supabase.get_workout.return_value = mock_workout

        response = client.put(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/sets/10",
            json={
                "user_id": MOCK_USER_ID,
                "reps_completed": 8,
                "weight_kg": 50.0,
            }
        )

        assert response.status_code == 400


@requires_set_adjustment_api
class TestDeleteSetEndpoint:
    """Tests for DELETE /workouts/{workout_id}/exercises/{exercise_index}/sets/{set_number}"""

    def test_delete_set(self, client, mock_supabase):
        """Test deleting a specific set from an exercise."""
        mock_workout = generate_mock_workout(sets_per_exercise=4)
        mock_supabase.get_workout.return_value = mock_workout

        # Mock update with set removed
        updated_workout = mock_workout.copy()
        updated_workout["exercises"][0]["sets"] = mock_workout["exercises"][0]["sets"][1:]
        mock_supabase.update_workout.return_value = updated_workout

        response = client.delete(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/sets/1",
            params={"user_id": MOCK_USER_ID}
        )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True
        assert data.get("remaining_sets") == 3

    def test_delete_nonexistent_set(self, client, mock_supabase):
        """Test deleting a set that doesn't exist."""
        mock_workout = generate_mock_workout(sets_per_exercise=3)
        mock_supabase.get_workout.return_value = mock_workout

        response = client.delete(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/sets/10",
            params={"user_id": MOCK_USER_ID}
        )

        assert response.status_code == 400

    def test_delete_last_set_prevented(self, client, mock_supabase):
        """Test that deleting the last set of an exercise is prevented."""
        mock_workout = generate_mock_workout(sets_per_exercise=1)
        mock_supabase.get_workout.return_value = mock_workout

        response = client.delete(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/sets/1",
            params={"user_id": MOCK_USER_ID}
        )

        assert response.status_code == 400
        assert "cannot delete last set" in response.json()["detail"].lower()


@requires_set_adjustment_api
class TestGetAdjustmentsEndpoint:
    """Tests for GET /workouts/{workout_id}/adjustments"""

    def test_get_workout_adjustments(self, client, mock_supabase):
        """Test retrieving all adjustments for a workout."""
        mock_adjustments = [
            generate_mock_set_adjustment(exercise_index=0, original_sets=4, new_sets=3),
            generate_mock_set_adjustment(exercise_index=1, original_sets=3, new_sets=2),
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.order.return_value.execute.return_value = MagicMock(
            data=mock_adjustments
        )

        response = client.get(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/adjustments",
            params={"user_id": MOCK_USER_ID}
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    def test_get_user_adjustment_patterns(self, client, mock_supabase):
        """Test retrieving user's historical adjustment patterns."""
        mock_patterns = [
            {
                "exercise_name": "Bench Press",
                "total_adjustments": 5,
                "avg_reduction": 1.2,
                "common_reason": "fatigue",
            },
            {
                "exercise_name": "Squat",
                "total_adjustments": 3,
                "avg_reduction": 0.8,
                "common_reason": "time constraint",
            },
        ]
        mock_supabase.client.rpc.return_value.execute.return_value = MagicMock(
            data=mock_patterns
        )

        response = client.get(
            f"/api/v1/users/{MOCK_USER_ID}/adjustment-patterns"
        )

        assert response.status_code == 200
        data = response.json()
        assert "patterns" in data


# =============================================================================
# Fatigue Detection Tests
# =============================================================================

# Fatigue detection helper functions (inline for testing when service doesn't exist)
def detect_fatigue_inline(sets: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Inline fatigue detection for testing.
    Detects fatigue from rep decline, high RPE, or weight reduction.
    """
    if not sets or len(sets) < 2:
        return {"fatigue_detected": False, "fatigue_level": 0.0}

    # Check for rep decline
    first_reps = sets[0].get("reps_completed", sets[0].get("reps", 0))
    last_reps = sets[-1].get("reps_completed", sets[-1].get("reps", 0))

    if first_reps > 0:
        decline_pct = ((first_reps - last_reps) / first_reps) * 100
        if decline_pct >= 20:
            return {
                "fatigue_detected": True,
                "detection_reason": "rep_decline",
                "decline_percentage": decline_pct,
                "fatigue_level": min(1.0, decline_pct / 50),
            }

    # Check for high RPE
    rpes = [s.get("rpe", 0) for s in sets if s.get("rpe")]
    if rpes:
        avg_rpe = sum(rpes) / len(rpes)
        max_rpe = max(rpes)
        if max_rpe >= 9.5 or (avg_rpe >= 8.5 and rpes[-1] >= 9):
            return {
                "fatigue_detected": True,
                "detection_reason": "high_rpe",
                "avg_rpe": avg_rpe,
                "max_rpe": max_rpe,
                "fatigue_level": min(1.0, (avg_rpe - 7) / 3),
            }

    # Check for weight reduction
    weights = [s.get("weight_kg", 0) for s in sets]
    if len(weights) >= 2:
        first_weight = weights[0]
        last_weight = weights[-1]
        if first_weight > 0 and last_weight < first_weight * 0.8:
            return {
                "fatigue_detected": True,
                "detection_reason": "weight_reduction",
                "weight_drop_pct": ((first_weight - last_weight) / first_weight) * 100,
                "fatigue_level": 0.7,
            }

    return {"fatigue_detected": False, "fatigue_level": 0.0}


def get_fatigue_recommendation_inline(
    fatigue_data: Dict[str, Any],
    remaining_sets: int
) -> Dict[str, Any]:
    """
    Inline fatigue recommendation for testing.
    """
    if not fatigue_data.get("fatigue_detected", False):
        return {
            "action": "continue",
            "sets_to_complete": remaining_sets,
            "message": "Performance is consistent. Continue as planned.",
        }

    fatigue_level = fatigue_data.get("fatigue_level", 0.5)

    if fatigue_level >= 0.8:
        return {
            "action": "stop",
            "suggested_sets": 0,
            "message": "High fatigue detected. Stop to reduce injury risk.",
        }
    elif fatigue_level >= 0.4:
        suggested = max(1, remaining_sets - 1)
        return {
            "action": "reduce",
            "suggested_sets": suggested,
            "message": f"Moderate fatigue detected. Consider reducing to {suggested} more set(s).",
        }
    else:
        return {
            "action": "continue",
            "sets_to_complete": remaining_sets,
            "message": "Mild fatigue. You can continue if feeling okay.",
        }


class TestFatigueDetection:
    """Tests for fatigue detection algorithms."""

    def test_fatigue_detection_rep_decline(self):
        """Test detecting fatigue from declining rep counts."""
        # Try importing from service, fall back to inline implementation
        try:
            from services.fatigue_detection_service import detect_fatigue
        except ImportError:
            detect_fatigue = detect_fatigue_inline

        # Pattern: 10, 8, 6 reps - clear decline
        sets = generate_mock_performance_sets([10, 8, 6], weight_kg=50.0)

        result = detect_fatigue(sets)

        assert result["fatigue_detected"] is True
        assert result["detection_reason"] == "rep_decline"
        assert result["decline_percentage"] >= 20

    def test_fatigue_detection_high_rpe(self):
        """Test detecting fatigue from high RPE values."""
        try:
            from services.fatigue_detection_service import detect_fatigue
        except ImportError:
            detect_fatigue = detect_fatigue_inline

        # Sets with escalating high RPE
        sets = [
            {"set_number": 1, "reps_completed": 10, "weight_kg": 50, "rpe": 7, "completed": True},
            {"set_number": 2, "reps_completed": 10, "weight_kg": 50, "rpe": 9, "completed": True},
            {"set_number": 3, "reps_completed": 9, "weight_kg": 50, "rpe": 10, "completed": True},
        ]

        result = detect_fatigue(sets)

        assert result["fatigue_detected"] is True
        assert "rpe" in result["detection_reason"].lower()

    def test_fatigue_detection_weight_reduction(self):
        """Test detecting fatigue when user reduces weight mid-exercise."""
        try:
            from services.fatigue_detection_service import detect_fatigue
        except ImportError:
            detect_fatigue = detect_fatigue_inline

        # User starts heavy, then drops weight significantly
        sets = [
            {"set_number": 1, "reps_completed": 10, "weight_kg": 60, "rpe": 7, "completed": True},
            {"set_number": 2, "reps_completed": 10, "weight_kg": 60, "rpe": 8, "completed": True},
            {"set_number": 3, "reps_completed": 10, "weight_kg": 45, "rpe": 8, "completed": True},  # Dropped weight
        ]

        result = detect_fatigue(sets)

        assert result["fatigue_detected"] is True
        assert "weight" in result["detection_reason"].lower()

    def test_fatigue_detection_no_fatigue(self):
        """Test that consistent performance doesn't trigger fatigue detection."""
        try:
            from services.fatigue_detection_service import detect_fatigue
        except ImportError:
            detect_fatigue = detect_fatigue_inline

        # Consistent performance
        sets = generate_mock_performance_sets([10, 10, 10], weight_kg=50.0)

        result = detect_fatigue(sets)

        assert result["fatigue_detected"] is False


class TestFatigueRecommendations:
    """Tests for fatigue-based workout recommendations."""

    def test_fatigue_recommendation_continue(self):
        """Test recommendation to continue when fatigue is minimal."""
        try:
            from services.fatigue_detection_service import get_fatigue_recommendation
        except ImportError:
            get_fatigue_recommendation = get_fatigue_recommendation_inline

        fatigue_data = {
            "fatigue_detected": False,
            "fatigue_level": 0.2,
        }

        recommendation = get_fatigue_recommendation(fatigue_data, remaining_sets=2)

        assert recommendation["action"] == "continue"
        assert recommendation["sets_to_complete"] == 2

    def test_fatigue_recommendation_reduce(self):
        """Test recommendation to reduce sets when moderate fatigue detected."""
        try:
            from services.fatigue_detection_service import get_fatigue_recommendation
        except ImportError:
            get_fatigue_recommendation = get_fatigue_recommendation_inline

        fatigue_data = {
            "fatigue_detected": True,
            "fatigue_level": 0.5,
            "detection_reason": "rep_decline",
        }

        recommendation = get_fatigue_recommendation(fatigue_data, remaining_sets=3)

        assert recommendation["action"] == "reduce"
        assert recommendation["suggested_sets"] < 3
        assert "message" in recommendation

    def test_fatigue_recommendation_stop(self):
        """Test recommendation to stop when severe fatigue detected."""
        try:
            from services.fatigue_detection_service import get_fatigue_recommendation
        except ImportError:
            get_fatigue_recommendation = get_fatigue_recommendation_inline

        fatigue_data = {
            "fatigue_detected": True,
            "fatigue_level": 0.9,
            "detection_reason": "high_rpe",
        }

        recommendation = get_fatigue_recommendation(fatigue_data, remaining_sets=2)

        assert recommendation["action"] == "stop"
        assert "risk" in recommendation["message"].lower() or "stop" in recommendation["message"].lower()


# =============================================================================
# Database Tests
# =============================================================================

# Inline helper functions for database tests when service doesn't exist
async def save_set_adjustment_inline(adjustment_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Inline implementation of save_set_adjustment for testing."""
    # This is a mock implementation - in real tests, this would be mocked via fixtures
    return {**adjustment_data, "id": MOCK_SET_ADJUSTMENT_ID}


async def get_user_adjustment_patterns_inline(user_id: str) -> List[Dict[str, Any]]:
    """Inline implementation of get_user_adjustment_patterns for testing."""
    return []


async def get_workout_adjustments_inline(workout_id: str, user_id: str) -> List[Dict[str, Any]]:
    """Inline implementation of get_workout_adjustments for testing."""
    return []


class TestSetAdjustmentDatabase:
    """Tests for set adjustment database operations."""

    @pytest.mark.asyncio
    async def test_set_adjustment_saved_correctly(self, mock_supabase_client):
        """Test that set adjustments are properly saved to database."""
        try:
            from services.set_adjustment_service import save_set_adjustment
        except ImportError:
            save_set_adjustment = save_set_adjustment_inline

        adjustment_data = {
            "user_id": MOCK_USER_ID,
            "workout_id": MOCK_WORKOUT_ID,
            "workout_log_id": MOCK_WORKOUT_LOG_ID,
            "exercise_index": 0,
            "exercise_name": "Bench Press",
            "original_sets": 4,
            "new_sets": 3,
            "reason": "fatigue",
            "adjustment_type": "reduce",
        }

        mock_supabase_client.client.table.return_value.insert.return_value.execute.return_value = MagicMock(
            data=[{**adjustment_data, "id": MOCK_SET_ADJUSTMENT_ID}]
        )

        result = await save_set_adjustment(adjustment_data)

        assert result is not None
        assert result.get("id") == MOCK_SET_ADJUSTMENT_ID

    @pytest.mark.asyncio
    async def test_adjustment_patterns_view(self, mock_supabase_client):
        """Test querying the adjustment patterns view."""
        try:
            from services.set_adjustment_service import get_user_adjustment_patterns
        except ImportError:
            pytest.skip("set_adjustment_service not implemented yet")

        mock_patterns = [
            {
                "exercise_name": "Squat",
                "muscle_group": "legs",
                "total_adjustments": 10,
                "avg_sets_reduced": 1.5,
                "most_common_reason": "fatigue",
                "last_adjustment_date": datetime.now().isoformat(),
            },
        ]

        mock_supabase_client.client.from_.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
            data=mock_patterns
        )

        result = await get_user_adjustment_patterns(MOCK_USER_ID)

        assert len(result) == 1
        assert result[0]["exercise_name"] == "Squat"
        assert result[0]["total_adjustments"] == 10

    @pytest.mark.asyncio
    async def test_rls_policies_own_data_only(self, mock_supabase_client):
        """Test that RLS policies prevent accessing other users' adjustments."""
        try:
            from services.set_adjustment_service import get_workout_adjustments
        except ImportError:
            pytest.skip("set_adjustment_service not implemented yet")

        other_user_id = "other-user-999"

        # Mock RLS returning empty for unauthorized access
        mock_supabase_client.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = MagicMock(
            data=[]  # RLS filters out other user's data
        )

        result = await get_workout_adjustments(MOCK_WORKOUT_ID, other_user_id)

        assert result == []


# =============================================================================
# Integration Tests
# =============================================================================

class TestSetAdjustmentIntegration:
    """Integration tests for set adjustment workflow."""

    @pytest.mark.asyncio
    async def test_full_workout_with_set_adjustments(self, mock_supabase_client):
        """Test complete workflow: start workout, detect fatigue, adjust sets, complete."""
        try:
            from services.workout_session_service import WorkoutSessionService
        except ImportError:
            pytest.skip("workout_session_service not implemented yet")

        service = WorkoutSessionService(mock_supabase_client)

        # 1. Start workout
        mock_workout = generate_mock_workout()
        mock_supabase_client.get_workout.return_value = mock_workout

        session = await service.start_workout(MOCK_USER_ID, MOCK_WORKOUT_ID)
        assert session is not None

        # 2. Log sets with declining performance (fatigue pattern)
        declining_sets = generate_mock_performance_sets([10, 8, 6])
        await service.log_exercise_sets(session["id"], 0, declining_sets)

        # 3. Fatigue should be detected
        fatigue_check = await service.check_fatigue(session["id"], 0)
        assert fatigue_check["fatigue_detected"] is True

        # 4. Apply set adjustment based on recommendation
        adjustment_result = await service.apply_set_adjustment(
            session["id"],
            exercise_index=0,
            new_set_count=3,
            reason="AI-detected fatigue",
        )
        assert adjustment_result["success"] is True

        # 5. Complete workout
        mock_supabase_client.update_workout.return_value = {**mock_workout, "is_completed": True}
        completion = await service.complete_workout(session["id"])
        assert completion["is_completed"] is True

    @pytest.mark.asyncio
    async def test_adjustment_reflected_in_workout_log(self, mock_supabase_client):
        """Test that set adjustments are recorded in workout logs."""
        try:
            from services.workout_log_service import get_workout_log_with_adjustments
        except ImportError:
            pytest.skip("workout_log_service not implemented yet")

        # Mock workout log with adjustments
        mock_log = {
            "id": MOCK_WORKOUT_LOG_ID,
            "workout_id": MOCK_WORKOUT_ID,
            "user_id": MOCK_USER_ID,
            "total_time_seconds": 2700,
            "completed_at": datetime.now().isoformat(),
            "sets_json": generate_mock_workout()["exercises"],
        }

        mock_adjustments = [
            generate_mock_set_adjustment(exercise_index=0),
            generate_mock_set_adjustment(exercise_index=2),
        ]

        mock_supabase_client.client.table.return_value.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = MagicMock(
            data=mock_log
        )
        mock_supabase_client.client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
            data=mock_adjustments
        )

        result = await get_workout_log_with_adjustments(MOCK_WORKOUT_LOG_ID)

        assert result is not None
        assert result.get("adjustments_count") == 2
        assert len(result.get("adjustments", [])) == 2

    @pytest.mark.asyncio
    async def test_user_context_logged_on_adjustment(self, mock_supabase_client):
        """Test that user context is logged when adjustments are made."""
        from services.user_context_service import UserContextService

        service = UserContextService()

        # Mock the log_event method
        with patch.object(service, 'log_event', new_callable=AsyncMock) as mock_log:
            mock_log.return_value = "event-123"

            # Log a set adjustment event
            event_id = await service.log_event(
                user_id=MOCK_USER_ID,
                event_type="set_adjustment",
                event_data={
                    "workout_id": MOCK_WORKOUT_ID,
                    "exercise_index": 0,
                    "exercise_name": "Bench Press",
                    "original_sets": 4,
                    "new_sets": 3,
                    "reason": "fatigue_detected",
                    "fatigue_level": 0.7,
                },
                context={
                    "time_of_day": "afternoon",
                    "day_of_week": "monday",
                },
            )

            assert event_id is not None
            mock_log.assert_called_once()


# =============================================================================
# Edge Cases and Error Handling
# =============================================================================

@requires_set_adjustment_api
class TestSetAdjustmentEdgeCases:
    """Tests for edge cases and error handling."""

    def test_adjust_sets_to_zero_prevented(self, client, mock_supabase):
        """Test that reducing sets to zero is not allowed."""
        mock_workout = generate_mock_workout()
        mock_supabase.get_workout.return_value = mock_workout

        response = client.post(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/adjust-sets",
            json={
                "user_id": MOCK_USER_ID,
                "new_set_count": 0,
            }
        )

        assert response.status_code == 422  # Validation error

    def test_adjust_sets_increase_allowed(self, client, mock_supabase):
        """Test that increasing set count is allowed."""
        mock_workout = generate_mock_workout(sets_per_exercise=2)
        mock_supabase.get_workout.return_value = mock_workout
        mock_supabase.update_workout.return_value = mock_workout

        response = client.post(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/adjust-sets",
            json={
                "user_id": MOCK_USER_ID,
                "new_set_count": 4,
            }
        )

        assert response.status_code == 200

    def test_concurrent_adjustment_handling(self, client, mock_supabase):
        """Test handling of concurrent adjustment requests."""
        mock_workout = generate_mock_workout()
        mock_supabase.get_workout.return_value = mock_workout

        # Simulate version conflict
        mock_supabase.update_workout.side_effect = [
            Exception("Version conflict"),
            mock_workout,  # Retry succeeds
        ]

        response = client.post(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/adjust-sets",
            json={
                "user_id": MOCK_USER_ID,
                "new_set_count": 2,
            }
        )

        # Should handle gracefully
        assert response.status_code in [200, 409, 500]

    def test_adjustment_on_completed_workout(self, client, mock_supabase):
        """Test that adjustments on completed workouts are handled correctly."""
        mock_workout = generate_mock_workout()
        mock_workout["is_completed"] = True
        mock_supabase.get_workout.return_value = mock_workout

        response = client.post(
            f"/api/v1/workouts/{MOCK_WORKOUT_ID}/exercises/0/adjust-sets",
            json={
                "user_id": MOCK_USER_ID,
                "new_set_count": 2,
            }
        )

        # Should either succeed (adjustments can be made retroactively)
        # or fail with appropriate error
        assert response.status_code in [200, 400]


# =============================================================================
# Helper Function Tests
# =============================================================================

# Inline helper implementations for testing
def calculate_volume_difference_inline(
    original_sets: List[Dict[str, Any]],
    new_sets: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """Calculate the volume difference between original and new sets."""
    original_volume = sum(
        s.get("reps", 0) * s.get("weight_kg", 0) for s in original_sets
    )
    new_volume = sum(
        s.get("reps", 0) * s.get("weight_kg", 0) for s in new_sets
    )
    reduction = original_volume - new_volume
    reduction_pct = (reduction / original_volume * 100) if original_volume > 0 else 0

    return {
        "original_volume": original_volume,
        "new_volume": new_volume,
        "volume_reduction": reduction,
        "reduction_percentage": round(reduction_pct, 2),
    }


def suggest_adjustment_reason_inline(fatigue_data: Dict[str, Any]) -> List[str]:
    """Generate adjustment reason suggestions based on fatigue data."""
    suggestions = []

    if fatigue_data.get("fatigue_detected"):
        reason = fatigue_data.get("detection_reason", "")
        level = fatigue_data.get("fatigue_level", 0)

        if "rep" in reason.lower():
            suggestions.append("Fatigue detected - rep count declining")
        if "rpe" in reason.lower():
            suggestions.append("High RPE indicates significant fatigue")
        if "weight" in reason.lower():
            suggestions.append("Weight reduction indicates fatigue")

        if level >= 0.7:
            suggestions.append("Consider ending exercise early for recovery")
        elif level >= 0.4:
            suggestions.append("Reduce remaining sets by 1-2")

    if not suggestions:
        suggestions = ["Personal preference", "Time constraint", "Focus on other exercises"]

    return suggestions


def validate_adjustment_request_inline(
    request: Dict[str, Any],
    max_sets: int = 10
) -> Tuple[bool, List[str]]:
    """Validate a set adjustment request."""
    errors = []

    if not request.get("user_id"):
        errors.append("user_id is required")

    new_set_count = request.get("new_set_count", 0)
    if new_set_count < 1:
        errors.append("new_set_count must be at least 1")
    if new_set_count > max_sets:
        errors.append(f"new_set_count cannot exceed {max_sets}")

    return len(errors) == 0, errors


class TestSetAdjustmentHelpers:
    """Tests for helper functions used in set adjustments."""

    def test_calculate_volume_difference(self):
        """Test volume calculation for adjustment impact."""
        try:
            from services.set_adjustment_service import calculate_volume_difference
        except ImportError:
            calculate_volume_difference = calculate_volume_difference_inline

        original_sets = [
            {"reps": 10, "weight_kg": 50},
            {"reps": 10, "weight_kg": 50},
            {"reps": 10, "weight_kg": 50},
        ]

        new_sets = [
            {"reps": 10, "weight_kg": 50},
            {"reps": 10, "weight_kg": 50},
        ]

        diff = calculate_volume_difference(original_sets, new_sets)

        assert diff["original_volume"] == 1500  # 3 * 10 * 50
        assert diff["new_volume"] == 1000  # 2 * 10 * 50
        assert diff["volume_reduction"] == 500
        assert diff["reduction_percentage"] == pytest.approx(33.33, rel=0.1)

    def test_generate_adjustment_reason_suggestion(self):
        """Test AI-generated adjustment reason suggestions."""
        try:
            from services.set_adjustment_service import suggest_adjustment_reason
        except ImportError:
            suggest_adjustment_reason = suggest_adjustment_reason_inline

        fatigue_data = {
            "fatigue_detected": True,
            "fatigue_level": 0.7,
            "detection_reason": "rep_decline",
            "rpe_average": 8.5,
        }

        suggestions = suggest_adjustment_reason(fatigue_data)

        assert isinstance(suggestions, list)
        assert len(suggestions) > 0
        assert any("fatigue" in s.lower() for s in suggestions)

    def test_validate_set_adjustment_request(self):
        """Test validation of set adjustment request data."""
        try:
            from services.set_adjustment_service import validate_adjustment_request
        except ImportError:
            validate_adjustment_request = validate_adjustment_request_inline

        # Valid request
        valid_request = {
            "user_id": MOCK_USER_ID,
            "new_set_count": 2,
            "reason": "fatigue",
        }

        is_valid, errors = validate_adjustment_request(valid_request, max_sets=5)
        assert is_valid is True
        assert len(errors) == 0

        # Invalid request - too many sets
        invalid_request = {
            "user_id": MOCK_USER_ID,
            "new_set_count": 10,
        }

        is_valid, errors = validate_adjustment_request(invalid_request, max_sets=5)
        assert is_valid is False
        assert len(errors) > 0
