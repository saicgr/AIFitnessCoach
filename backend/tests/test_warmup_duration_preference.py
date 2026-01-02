"""
Tests for Warmup/Stretch Duration Preference API.

Tests the warmup_duration_minutes and stretch_duration_minutes settings.
These preferences control how long warmup and cooldown stretches should last.
"""
import pytest
from unittest.mock import MagicMock, patch


class TestWarmupDurationPreference:
    """Tests for warmup and stretch duration preferences."""

    @patch('api.v1.workouts.warmup_stretch.get_supabase_db')
    @patch('api.v1.workouts.warmup_stretch.get_warmup_stretch_service')
    def test_default_duration_used_when_no_preference_set(self, mock_service, mock_db, client):
        """Test that default duration (5 min) is used when user has no preference set."""
        workout_id = "test-workout-123"
        user_id = "test-user-123"

        # Mock workout data
        mock_workout = {
            "id": workout_id,
            "user_id": user_id,
            "exercises_json": '[{"name": "Bench Press", "sets": 3, "reps": 10}]',
        }

        # Mock user with no duration preferences
        mock_user = {
            "id": user_id,
            "preferences": '{}',  # No warmup/stretch duration set
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_workout.return_value = mock_workout
        mock_db_instance.get_user.return_value = mock_user
        mock_db.return_value = mock_db_instance

        # Mock warmup service
        mock_service_instance = MagicMock()
        mock_service_instance.create_warmup_for_workout.return_value = {
            "id": "warmup-123",
            "exercises": [{"name": "Jumping Jacks", "duration": 60}],
        }
        mock_service.return_value = mock_service_instance

        # Call API without duration parameter - should use default (5)
        response = client.post(f"/api/v1/workouts/{workout_id}/warmup")

        assert response.status_code == 200

        # Verify the service was called with default duration (5)
        mock_service_instance.create_warmup_for_workout.assert_called_once()
        call_args = mock_service_instance.create_warmup_for_workout.call_args
        assert call_args[0][2] == 5  # Third positional arg is duration_minutes

    @patch('api.v1.workouts.warmup_stretch.get_supabase_db')
    @patch('api.v1.workouts.warmup_stretch.get_warmup_stretch_service')
    def test_user_preference_respected_when_set(self, mock_service, mock_db, client):
        """Test that user's preferred duration is used when set in preferences."""
        workout_id = "test-workout-456"
        user_id = "test-user-456"

        # Mock workout data
        mock_workout = {
            "id": workout_id,
            "user_id": user_id,
            "exercises_json": '[{"name": "Squats", "sets": 4, "reps": 8}]',
        }

        # Mock user with custom duration preferences
        mock_user = {
            "id": user_id,
            "preferences": '{"warmup_duration_minutes": 10, "stretch_duration_minutes": 8}',
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_workout.return_value = mock_workout
        mock_db_instance.get_user.return_value = mock_user
        mock_db.return_value = mock_db_instance

        # Mock warmup service
        mock_service_instance = MagicMock()
        mock_service_instance.create_warmup_for_workout.return_value = {
            "id": "warmup-456",
            "exercises": [{"name": "Arm Circles", "duration": 60}],
        }
        mock_service.return_value = mock_service_instance

        # Call API without duration parameter - should use user preference (10)
        response = client.post(f"/api/v1/workouts/{workout_id}/warmup")

        assert response.status_code == 200

        # Verify the service was called with user's preference (10)
        mock_service_instance.create_warmup_for_workout.assert_called_once()
        call_args = mock_service_instance.create_warmup_for_workout.call_args
        assert call_args[0][2] == 10  # User's preferred warmup duration

    @patch('api.v1.workouts.warmup_stretch.get_supabase_db')
    @patch('api.v1.workouts.warmup_stretch.get_warmup_stretch_service')
    def test_api_parameter_overrides_preference(self, mock_service, mock_db, client):
        """Test that explicitly passed duration overrides user preference."""
        workout_id = "test-workout-789"
        user_id = "test-user-789"

        # Mock workout data
        mock_workout = {
            "id": workout_id,
            "user_id": user_id,
            "exercises_json": '[{"name": "Deadlifts", "sets": 5, "reps": 5}]',
        }

        # Mock user with custom duration preferences
        mock_user = {
            "id": user_id,
            "preferences": '{"warmup_duration_minutes": 10, "stretch_duration_minutes": 8}',
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_workout.return_value = mock_workout
        mock_db_instance.get_user.return_value = mock_user
        mock_db.return_value = mock_db_instance

        # Mock warmup service
        mock_service_instance = MagicMock()
        mock_service_instance.create_warmup_for_workout.return_value = {
            "id": "warmup-789",
            "exercises": [{"name": "Leg Swings", "duration": 60}],
        }
        mock_service.return_value = mock_service_instance

        # Call API WITH explicit duration parameter (3) - should override preference
        response = client.post(
            f"/api/v1/workouts/{workout_id}/warmup",
            params={"duration_minutes": 3}
        )

        assert response.status_code == 200

        # Verify the service was called with explicitly passed duration (3)
        mock_service_instance.create_warmup_for_workout.assert_called_once()
        call_args = mock_service_instance.create_warmup_for_workout.call_args
        assert call_args[0][2] == 3  # Explicitly passed duration overrides preference

    @patch('api.v1.workouts.warmup_stretch.get_supabase_db')
    @patch('api.v1.workouts.warmup_stretch.get_warmup_stretch_service')
    def test_stretch_preference_used(self, mock_service, mock_db, client):
        """Test that stretch duration preference is used correctly."""
        workout_id = "test-workout-stretch"
        user_id = "test-user-stretch"

        # Mock workout data
        mock_workout = {
            "id": workout_id,
            "user_id": user_id,
            "exercises_json": '[{"name": "Rows", "sets": 3, "reps": 12}]',
        }

        # Mock user with custom duration preferences
        mock_user = {
            "id": user_id,
            "preferences": '{"warmup_duration_minutes": 7, "stretch_duration_minutes": 12}',
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_workout.return_value = mock_workout
        mock_db_instance.get_user.return_value = mock_user
        mock_db.return_value = mock_db_instance

        # Mock stretch service
        mock_service_instance = MagicMock()
        mock_service_instance.create_stretches_for_workout.return_value = {
            "id": "stretch-123",
            "exercises": [{"name": "Hamstring Stretch", "duration": 60}],
        }
        mock_service.return_value = mock_service_instance

        # Call stretches API without duration parameter - should use user preference (12)
        response = client.post(f"/api/v1/workouts/{workout_id}/stretches")

        assert response.status_code == 200

        # Verify the service was called with user's stretch preference (12)
        mock_service_instance.create_stretches_for_workout.assert_called_once()
        call_args = mock_service_instance.create_stretches_for_workout.call_args
        assert call_args[0][2] == 12  # User's preferred stretch duration

    @patch('api.v1.workouts.warmup_stretch.get_supabase_db')
    @patch('api.v1.workouts.warmup_stretch.get_warmup_stretch_service')
    def test_combined_endpoint_uses_preferences(self, mock_service, mock_db, client):
        """Test that combined warmup-and-stretches endpoint uses both preferences."""
        workout_id = "test-workout-combined"
        user_id = "test-user-combined"

        # Mock workout data
        mock_workout = {
            "id": workout_id,
            "user_id": user_id,
            "exercises_json": '[{"name": "Pull-ups", "sets": 3, "reps": 8}]',
        }

        # Mock user with custom duration preferences
        mock_user = {
            "id": user_id,
            "preferences": '{"warmup_duration_minutes": 8, "stretch_duration_minutes": 6}',
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_workout.return_value = mock_workout
        mock_db_instance.get_user.return_value = mock_user
        mock_db.return_value = mock_db_instance

        # Mock combined service
        mock_service_instance = MagicMock()
        mock_service_instance.generate_warmup_and_stretches_for_workout.return_value = {
            "warmup": {"exercises": []},
            "stretches": {"exercises": []},
        }
        mock_service.return_value = mock_service_instance

        # Call combined API without duration parameters - should use user preferences
        response = client.post(f"/api/v1/workouts/{workout_id}/warmup-and-stretches")

        assert response.status_code == 200

        # Verify the service was called with user's preferences (8 and 6)
        mock_service_instance.generate_warmup_and_stretches_for_workout.assert_called_once()
        call_args = mock_service_instance.generate_warmup_and_stretches_for_workout.call_args
        assert call_args[0][2] == 8  # warmup_duration
        assert call_args[0][3] == 6  # stretch_duration

    @patch('api.v1.workouts.warmup_stretch.get_supabase_db')
    @patch('api.v1.workouts.warmup_stretch.get_warmup_stretch_service')
    def test_preference_values_clamped_to_valid_range(self, mock_service, mock_db, client):
        """Test that preference values outside 1-15 range are clamped."""
        workout_id = "test-workout-clamped"
        user_id = "test-user-clamped"

        # Mock workout data
        mock_workout = {
            "id": workout_id,
            "user_id": user_id,
            "exercises_json": '[{"name": "Bicep Curls", "sets": 3, "reps": 12}]',
        }

        # Mock user with out-of-range preferences
        mock_user = {
            "id": user_id,
            "preferences": '{"warmup_duration_minutes": 30, "stretch_duration_minutes": 0}',
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_workout.return_value = mock_workout
        mock_db_instance.get_user.return_value = mock_user
        mock_db.return_value = mock_db_instance

        # Mock warmup service
        mock_service_instance = MagicMock()
        mock_service_instance.create_warmup_for_workout.return_value = {
            "id": "warmup-clamped",
            "exercises": [],
        }
        mock_service.return_value = mock_service_instance

        # Call API - values should be clamped to valid range
        response = client.post(f"/api/v1/workouts/{workout_id}/warmup")

        assert response.status_code == 200

        # Verify the service was called with clamped value (15 max)
        mock_service_instance.create_warmup_for_workout.assert_called_once()
        call_args = mock_service_instance.create_warmup_for_workout.call_args
        assert call_args[0][2] == 15  # Clamped to max of 15

    @patch('api.v1.workouts.warmup_stretch.get_supabase_db')
    @patch('api.v1.workouts.warmup_stretch.get_warmup_stretch_service')
    def test_handles_null_preferences(self, mock_service, mock_db, client):
        """Test that null/None preferences are handled gracefully with defaults."""
        workout_id = "test-workout-null"
        user_id = "test-user-null"

        # Mock workout data
        mock_workout = {
            "id": workout_id,
            "user_id": user_id,
            "exercises_json": '[{"name": "Plank", "sets": 3, "duration": 60}]',
        }

        # Mock user with null preferences
        mock_user = {
            "id": user_id,
            "preferences": None,  # NULL preferences
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_workout.return_value = mock_workout
        mock_db_instance.get_user.return_value = mock_user
        mock_db.return_value = mock_db_instance

        # Mock warmup service
        mock_service_instance = MagicMock()
        mock_service_instance.create_warmup_for_workout.return_value = {
            "id": "warmup-null",
            "exercises": [],
        }
        mock_service.return_value = mock_service_instance

        # Call API - should use defaults due to null preferences
        response = client.post(f"/api/v1/workouts/{workout_id}/warmup")

        assert response.status_code == 200

        # Verify the service was called with default duration (5)
        mock_service_instance.create_warmup_for_workout.assert_called_once()
        call_args = mock_service_instance.create_warmup_for_workout.call_args
        assert call_args[0][2] == 5  # Default duration

    @patch('api.v1.users.get_supabase_db')
    @patch('api.v1.users.log_user_activity')
    def test_update_warmup_duration_preference(self, mock_log, mock_db, client):
        """Test updating warmup duration via user preferences update."""
        user_id = "test-user-update-warmup"

        # Mock existing user
        existing_user = {
            "id": user_id,
            "email": "test@example.com",
            "name": "Test User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": '["build_muscle"]',
            "equipment": '["dumbbells"]',
            "preferences": '{"warmup_duration_minutes": 5}',
            "active_injuries": '[]',
            "created_at": "2024-01-01T00:00:00Z",
        }

        # Mock updated user
        updated_user = {
            **existing_user,
            "preferences": '{"warmup_duration_minutes": 10}',
        }

        mock_db_instance = MagicMock()
        mock_db_instance.get_user.return_value = existing_user
        mock_db_instance.update_user.return_value = updated_user
        mock_db.return_value = mock_db_instance

        mock_log.return_value = None

        # Update warmup duration preference
        response = client.put(
            f"/api/v1/users/{user_id}",
            json={
                "preferences": '{"warmup_duration_minutes": 10}'
            }
        )

        assert response.status_code == 200

        # Verify update_user was called
        mock_db_instance.update_user.assert_called_once()
