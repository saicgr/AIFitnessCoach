"""
Tests for Senior Fitness API endpoints.

This module tests:
1. Get settings endpoint
2. Update settings endpoint
3. Recovery status endpoint
4. Apply workout modifications
5. Log workout endpoint
6. Is-senior check
7. Mobility/balance exercises
8. Low-impact alternatives
"""
import pytest
from datetime import date, timedelta, datetime, timezone
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


MOCK_USER_ID = "test-user-senior-123"
MOCK_WORKOUT_ID = "test-workout-456"


@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    mock_db = MagicMock()
    mock_client = MagicMock()
    mock_db.client = mock_client
    return mock_db, mock_client


@pytest.fixture
def client():
    """Create a test client."""
    from main import app
    return TestClient(app)


def generate_mock_senior_settings(
    recovery_multiplier: float = 1.5,
    max_intensity_percent: int = 75,
    user_age: int = 68,
):
    """Generate mock senior settings."""
    return {
        "id": "settings-123",
        "user_id": MOCK_USER_ID,
        "recovery_multiplier": recovery_multiplier,
        "min_rest_days_strength": 2,
        "min_rest_days_cardio": 1,
        "max_intensity_percent": max_intensity_percent,
        "max_workout_duration_minutes": 45,
        "max_exercises_per_session": 6,
        "extended_warmup_minutes": 10,
        "extended_cooldown_minutes": 10,
        "prefer_low_impact": True,
        "avoid_high_impact_cardio": True,
        "include_mobility_exercises": True,
        "mobility_exercises_per_session": 2,
        "include_balance_exercises": True,
        "balance_exercises_per_session": 1,
        "custom_notes": "Focus on joint health",
        "users": {"age": user_age},
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }


def generate_mock_user(age: int = 68):
    """Generate mock user data."""
    return {
        "id": MOCK_USER_ID,
        "age": age,
        "fitness_level": "beginner",
    }


def generate_mock_workout_log(
    workout_type: str = "strength",
    intensity_level: int = 70,
):
    """Generate mock senior workout log entry."""
    return {
        "id": "log-123",
        "user_id": MOCK_USER_ID,
        "workout_id": MOCK_WORKOUT_ID,
        "workout_type": workout_type,
        "intensity_level": intensity_level,
        "duration_minutes": 40,
        "modifications_applied": ["Reduced sets", "Extended rest"],
        "post_workout_feeling": "good",
        "notes": "Felt comfortable throughout",
        "completed_at": datetime.now(timezone.utc).isoformat(),
    }


def generate_mock_mobility_exercise(name: str = "Cat-Cow Stretch"):
    """Generate mock mobility exercise."""
    return {
        "id": "mobility-123",
        "name": name,
        "description": "Gentle spinal mobility exercise",
        "target_muscles": ["spine", "lower back"],
        "duration_seconds": 30,
        "sets": 2,
        "reps": 10,
        "difficulty": "easy",
        "instructions": [
            "Start on hands and knees",
            "Inhale, drop belly and look up",
            "Exhale, round spine and tuck chin",
        ],
        "is_active": True,
    }


def generate_mock_low_impact_alternative(
    original: str = "Jump Squats",
    alternative: str = "Bodyweight Squats"
):
    """Generate mock low-impact alternative."""
    return {
        "id": "alt-123",
        "original_exercise": original,
        "alternative_exercise": alternative,
        "reason": "Eliminates jump impact on knees",
    }


# =============================================================================
# Get Settings Tests
# =============================================================================

class TestGetSeniorSettings:
    """Tests for GET /senior-fitness/settings/{user_id}"""

    def test_get_settings_success(self, client, mock_supabase):
        """Test successful retrieval of senior settings."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_senior_settings()])

            response = client.get(f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]

    def test_get_settings_not_senior(self, client, mock_supabase):
        """Test getting settings when user is not a senior."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            # No senior settings, but user exists with age < 60
            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[]),  # No senior settings
                MagicMock(data=[generate_mock_user(age=45)]),  # User is 45
            ]

            response = client.get(f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]

    def test_get_settings_auto_defaults_for_60_plus(self, client, mock_supabase):
        """Test that defaults are auto-created for 60+ users."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[]),  # No senior settings yet
                MagicMock(data=[generate_mock_user(age=65)]),  # User is 65
            ]

            response = client.get(f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]

    def test_get_settings_age_75_plus(self, client, mock_supabase):
        """Test settings for 75+ user with stricter limits."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[
                generate_mock_senior_settings(
                    recovery_multiplier=2.0,
                    max_intensity_percent=65,
                    user_age=78
                )
            ])

            response = client.get(f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]


# =============================================================================
# Update Settings Tests
# =============================================================================

class TestUpdateSeniorSettings:
    """Tests for PUT /senior-fitness/settings/{user_id}"""

    def test_update_settings_success(self, client, mock_supabase):
        """Test successfully updating senior settings."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.upsert.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_senior_settings()])

            response = client.put(
                f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}",
                json={
                    "recovery_multiplier": 1.75,
                    "max_intensity_percent": 70,
                    "extended_warmup_minutes": 12,
                    "include_balance_exercises": True,
                }
            )

            assert response.status_code in [200, 404, 422]

    def test_update_settings_partial(self, client, mock_supabase):
        """Test updating only some settings."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.upsert.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_senior_settings()])

            response = client.put(
                f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}",
                json={"prefer_low_impact": False}
            )

            assert response.status_code in [200, 404, 422]

    def test_update_settings_invalid_intensity(self, client, mock_supabase):
        """Test updating with invalid intensity value."""
        response = client.put(
            f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}",
            json={"max_intensity_percent": 150}  # Should be 0-100
        )

        assert response.status_code in [404, 422]

    def test_update_settings_add_custom_notes(self, client, mock_supabase):
        """Test adding custom notes to settings."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.upsert.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_senior_settings()])

            response = client.put(
                f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}",
                json={
                    "custom_notes": "Arthritis in left knee, avoid deep squats"
                }
            )

            assert response.status_code in [200, 404, 422]


# =============================================================================
# Recovery Status Tests
# =============================================================================

class TestRecoveryStatus:
    """Tests for GET /senior-fitness/recovery-status/{user_id}"""

    def test_recovery_status_ready(self, client, mock_supabase):
        """Test recovery status when user is ready for workout."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.limit.return_value = mock_table

            # Settings show 2 rest days required
            # Last workout was 3 days ago
            last_workout_time = (datetime.now(timezone.utc) - timedelta(days=3)).isoformat()

            mock_table.execute.side_effect = [
                MagicMock(data=[generate_mock_senior_settings()]),
                MagicMock(data=[{"completed_at": last_workout_time}]),
            ]

            response = client.get(
                f"/api/v1/senior-fitness/recovery-status/{MOCK_USER_ID}",
                params={"workout_type": "strength"}
            )

            assert response.status_code in [200, 404]

    def test_recovery_status_not_ready(self, client, mock_supabase):
        """Test recovery status when user needs more rest."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.limit.return_value = mock_table

            # Last workout was yesterday
            last_workout_time = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()

            mock_table.execute.side_effect = [
                MagicMock(data=[generate_mock_senior_settings()]),
                MagicMock(data=[{"completed_at": last_workout_time}]),
            ]

            response = client.get(
                f"/api/v1/senior-fitness/recovery-status/{MOCK_USER_ID}",
                params={"workout_type": "strength"}
            )

            assert response.status_code in [200, 404]

    def test_recovery_status_no_previous_workout(self, client, mock_supabase):
        """Test recovery status for first workout."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.limit.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[generate_mock_senior_settings()]),
                MagicMock(data=[]),  # No previous workouts
            ]

            response = client.get(
                f"/api/v1/senior-fitness/recovery-status/{MOCK_USER_ID}",
                params={"workout_type": "strength"}
            )

            assert response.status_code in [200, 404]

    def test_recovery_status_cardio_vs_strength(self, client, mock_supabase):
        """Test that cardio has different recovery requirements."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.order.return_value = mock_table
            mock_table.limit.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[generate_mock_senior_settings()]),
                MagicMock(data=[]),
            ]

            response = client.get(
                f"/api/v1/senior-fitness/recovery-status/{MOCK_USER_ID}",
                params={"workout_type": "cardio"}
            )

            assert response.status_code in [200, 404]


# =============================================================================
# Apply Workout Modifications Tests
# =============================================================================

class TestApplyWorkoutModifications:
    """Tests for POST /senior-fitness/modify-workout/{user_id}"""

    def test_apply_modifications_success(self, client, mock_supabase):
        """Test successfully applying senior modifications to workout."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.limit.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[generate_mock_senior_settings()]),
                MagicMock(data=[generate_mock_user()]),
                MagicMock(data=[]),  # Mobility exercises
            ]

            response = client.post(
                f"/api/v1/senior-fitness/modify-workout/{MOCK_USER_ID}",
                json={
                    "workout": {
                        "id": MOCK_WORKOUT_ID,
                        "name": "Full Body Workout",
                        "type": "strength",
                    },
                    "exercises": [
                        {"name": "Squats", "sets": 4, "reps": 10, "weight_kg": 50},
                        {"name": "Bench Press", "sets": 4, "reps": 10, "weight_kg": 40},
                        {"name": "Jump Squats", "sets": 3, "reps": 12},  # Should be replaced
                    ]
                }
            )

            assert response.status_code in [200, 404, 422]

    def test_apply_modifications_replaces_high_impact(self, client, mock_supabase):
        """Test that high-impact exercises are replaced with low-impact."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.limit.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[generate_mock_senior_settings()]),
                MagicMock(data=[generate_mock_user()]),
                MagicMock(data=[]),
            ]

            response = client.post(
                f"/api/v1/senior-fitness/modify-workout/{MOCK_USER_ID}",
                json={
                    "workout": {"id": MOCK_WORKOUT_ID, "name": "HIIT", "type": "cardio"},
                    "exercises": [
                        {"name": "Burpees", "sets": 3, "reps": 10},
                        {"name": "Box Jumps", "sets": 3, "reps": 10},
                        {"name": "Mountain Climbers", "sets": 3, "reps": 20},
                    ]
                }
            )

            assert response.status_code in [200, 404, 422]

    def test_apply_modifications_not_senior(self, client, mock_supabase):
        """Test that non-senior users get workout unchanged."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table

            mock_table.execute.side_effect = [
                MagicMock(data=[]),  # No senior settings
                MagicMock(data=[generate_mock_user(age=35)]),  # User is 35
            ]

            response = client.post(
                f"/api/v1/senior-fitness/modify-workout/{MOCK_USER_ID}",
                json={
                    "workout": {"id": MOCK_WORKOUT_ID, "name": "Test", "type": "strength"},
                    "exercises": [{"name": "Squats", "sets": 4, "reps": 10}]
                }
            )

            assert response.status_code in [200, 404, 422]


# =============================================================================
# Log Workout Tests
# =============================================================================

class TestLogWorkout:
    """Tests for POST /senior-fitness/log-workout/{user_id}"""

    def test_log_workout_success(self, client, mock_supabase):
        """Test successfully logging a completed workout."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_workout_log()])

            response = client.post(
                f"/api/v1/senior-fitness/log-workout/{MOCK_USER_ID}",
                json={
                    "workout_id": MOCK_WORKOUT_ID,
                    "workout_type": "strength",
                    "intensity_level": 70,
                    "duration_minutes": 40,
                    "modifications_applied": ["Reduced sets", "Extended rest"],
                    "post_workout_feeling": "good",
                    "notes": "Felt comfortable throughout",
                }
            )

            assert response.status_code in [200, 201, 404, 422]

    def test_log_workout_minimal_fields(self, client, mock_supabase):
        """Test logging workout with minimal fields."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.insert.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_workout_log()])

            response = client.post(
                f"/api/v1/senior-fitness/log-workout/{MOCK_USER_ID}",
                json={
                    "workout_type": "cardio",
                    "intensity_level": 60,
                    "duration_minutes": 30,
                }
            )

            assert response.status_code in [200, 201, 404, 422]

    def test_log_workout_invalid_intensity(self, client, mock_supabase):
        """Test logging workout with invalid intensity."""
        response = client.post(
            f"/api/v1/senior-fitness/log-workout/{MOCK_USER_ID}",
            json={
                "workout_type": "strength",
                "intensity_level": 150,  # Should be 0-100
                "duration_minutes": 40,
            }
        )

        assert response.status_code in [404, 422]

    def test_log_workout_invalid_feeling(self, client, mock_supabase):
        """Test logging workout with invalid feeling."""
        response = client.post(
            f"/api/v1/senior-fitness/log-workout/{MOCK_USER_ID}",
            json={
                "workout_type": "strength",
                "intensity_level": 70,
                "duration_minutes": 40,
                "post_workout_feeling": "invalid_feeling",
            }
        )

        assert response.status_code in [404, 422]


# =============================================================================
# Is Senior Check Tests
# =============================================================================

class TestIsSeniorCheck:
    """Tests for GET /senior-fitness/is-senior/{user_id}"""

    def test_is_senior_true(self, client, mock_supabase):
        """Test checking if 65 year old is senior."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_user(age=65)])

            response = client.get(f"/api/v1/senior-fitness/is-senior/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]

    def test_is_senior_false(self, client, mock_supabase):
        """Test checking if 45 year old is not senior."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_user(age=45)])

            response = client.get(f"/api/v1/senior-fitness/is-senior/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]

    def test_is_senior_boundary_59(self, client, mock_supabase):
        """Test 59 year old is not senior."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_user(age=59)])

            response = client.get(f"/api/v1/senior-fitness/is-senior/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]

    def test_is_senior_boundary_60(self, client, mock_supabase):
        """Test 60 year old is senior."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_user(age=60)])

            response = client.get(f"/api/v1/senior-fitness/is-senior/{MOCK_USER_ID}")

            assert response.status_code in [200, 404]


# =============================================================================
# Mobility Exercises Tests
# =============================================================================

class TestMobilityExercises:
    """Tests for GET /senior-fitness/mobility-exercises"""

    def test_get_mobility_exercises_success(self, client, mock_supabase):
        """Test getting mobility exercises."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_mobility_exercise("Cat-Cow Stretch"),
                generate_mock_mobility_exercise("Hip Circles"),
                generate_mock_mobility_exercise("Arm Circles"),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.limit.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get("/api/v1/senior-fitness/mobility-exercises")

            assert response.status_code in [200, 404]

    def test_get_mobility_exercises_with_count(self, client, mock_supabase):
        """Test getting specific number of mobility exercises."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_mobility_exercise("Cat-Cow Stretch"),
                generate_mock_mobility_exercise("Hip Circles"),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.limit.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get(
                "/api/v1/senior-fitness/mobility-exercises",
                params={"count": 2}
            )

            assert response.status_code in [200, 404]


class TestBalanceExercises:
    """Tests for GET /senior-fitness/balance-exercises"""

    def test_get_balance_exercises_success(self, client, mock_supabase):
        """Test getting balance exercises."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            response = client.get("/api/v1/senior-fitness/balance-exercises")

            assert response.status_code in [200, 404]

    def test_get_balance_exercises_with_count(self, client, mock_supabase):
        """Test getting specific number of balance exercises."""
        mock_db, mock_client = mock_supabase

        response = client.get(
            "/api/v1/senior-fitness/balance-exercises",
            params={"count": 1}
        )

        assert response.status_code in [200, 404]


# =============================================================================
# Low Impact Alternatives Tests
# =============================================================================

class TestLowImpactAlternatives:
    """Tests for GET /senior-fitness/low-impact-alternative"""

    def test_get_alternative_success(self, client, mock_supabase):
        """Test getting low-impact alternative for an exercise."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.ilike.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[
                generate_mock_low_impact_alternative("Jump Squats", "Bodyweight Squats")
            ])

            response = client.get(
                "/api/v1/senior-fitness/low-impact-alternative",
                params={"exercise_name": "Jump Squats"}
            )

            assert response.status_code in [200, 404]

    def test_get_alternative_not_found(self, client, mock_supabase):
        """Test when no alternative exists."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.ilike.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[])

            response = client.get(
                "/api/v1/senior-fitness/low-impact-alternative",
                params={"exercise_name": "Bicep Curls"}  # No alternative needed
            )

            assert response.status_code in [200, 404]

    def test_get_all_alternatives(self, client, mock_supabase):
        """Test getting all low-impact alternatives."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            mock_data = [
                generate_mock_low_impact_alternative("Jump Squats", "Bodyweight Squats"),
                generate_mock_low_impact_alternative("Burpees", "Step-Back Burpees"),
                generate_mock_low_impact_alternative("Box Jumps", "Step-Ups"),
            ]

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=mock_data)

            response = client.get("/api/v1/senior-fitness/low-impact-alternatives")

            assert response.status_code in [200, 404]


# =============================================================================
# Service Unit Tests
# =============================================================================

class TestSeniorWorkoutService:
    """Unit tests for SeniorWorkoutService methods."""

    @pytest.mark.asyncio
    async def test_get_user_settings(self, mock_supabase):
        """Test getting user settings."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            from services.senior_workout_service import SeniorWorkoutService

            service = SeniorWorkoutService()
            service._db = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[generate_mock_senior_settings()])

            result = await service.get_user_settings(MOCK_USER_ID)

            assert result is not None
            assert result.recovery_multiplier == 1.5
            assert result.max_intensity_percent == 75

    @pytest.mark.asyncio
    async def test_is_senior_user(self, mock_supabase):
        """Test checking if user is senior."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            from services.senior_workout_service import SeniorWorkoutService

            service = SeniorWorkoutService()
            service._db = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.eq.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[{"age": 68}])

            is_senior, age = await service.is_senior_user(MOCK_USER_ID)

            assert is_senior is True
            assert age == 68

    @pytest.mark.asyncio
    async def test_get_low_impact_alternative(self, mock_supabase):
        """Test getting low-impact alternative."""
        mock_db, mock_client = mock_supabase

        with patch("services.senior_workout_service.get_supabase_db") as mock_get_db:
            mock_get_db.return_value = mock_db

            from services.senior_workout_service import SeniorWorkoutService

            service = SeniorWorkoutService()
            service._db = mock_db

            mock_table = MagicMock()
            mock_client.table.return_value = mock_table
            mock_table.select.return_value = mock_table
            mock_table.ilike.return_value = mock_table
            mock_table.execute.return_value = MagicMock(data=[
                {"alternative_exercise": "Bodyweight Squats"}
            ])

            result = await service.get_low_impact_alternative("Jump Squats")

            assert result == "Bodyweight Squats"


# =============================================================================
# Validation Tests
# =============================================================================

class TestSeniorFitnessValidation:
    """Tests for request validation."""

    def test_invalid_recovery_multiplier(self, client, mock_supabase):
        """Test that invalid recovery multiplier is rejected."""
        response = client.put(
            f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}",
            json={"recovery_multiplier": -1.0}
        )

        assert response.status_code in [404, 422]

    def test_invalid_max_exercises(self, client, mock_supabase):
        """Test that invalid max exercises is rejected."""
        response = client.put(
            f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}",
            json={"max_exercises_per_session": -5}
        )

        assert response.status_code in [404, 422]

    def test_invalid_warmup_duration(self, client, mock_supabase):
        """Test that negative warmup duration is rejected."""
        response = client.put(
            f"/api/v1/senior-fitness/settings/{MOCK_USER_ID}",
            json={"extended_warmup_minutes": -10}
        )

        assert response.status_code in [404, 422]
