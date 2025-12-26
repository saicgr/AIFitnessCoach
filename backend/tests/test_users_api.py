"""
Tests for Users API endpoints.

Tests the Google OAuth authentication and user management endpoints.
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
from fastapi import Request
import inspect

from api.v1.users import google_auth, GoogleAuthRequest, row_to_user


class TestGoogleAuthEndpoint:
    """Tests for the Google OAuth authentication endpoint."""

    def test_google_auth_parameter_naming(self):
        """
        Test that google_auth function has correct parameter naming for slowapi.

        The slowapi rate limiter requires the first parameter to be named 'request'
        and be of type starlette.requests.Request.
        """
        sig = inspect.signature(google_auth)
        params = list(sig.parameters.keys())

        # First parameter must be 'request'
        assert params[0] == 'request', f"First param should be 'request', got '{params[0]}'"

        # First parameter must be of type Request
        first_param_type = sig.parameters['request'].annotation
        assert 'Request' in str(first_param_type), f"First param should be Request type, got {first_param_type}"

        # Second parameter should be the body
        assert params[1] == 'body', f"Second param should be 'body', got '{params[1]}'"
        assert sig.parameters['body'].annotation == GoogleAuthRequest

    def test_google_auth_request_model(self):
        """Test GoogleAuthRequest model validation."""
        # Valid request
        request = GoogleAuthRequest(access_token="valid_token_123")
        assert request.access_token == "valid_token_123"

        # Empty token should still be valid (validation happens in endpoint)
        request = GoogleAuthRequest(access_token="")
        assert request.access_token == ""

    def test_google_auth_request_requires_token(self):
        """Test GoogleAuthRequest requires access_token field."""
        with pytest.raises(Exception):
            GoogleAuthRequest()  # Missing required field

    def test_google_auth_endpoint_exists(self, client):
        """Test that the Google auth endpoint is accessible (not 404)."""
        response = client.post(
            "/api/v1/users/auth/google",
            json={"access_token": "test_token"}
        )
        # Should not be 404 (route exists)
        # May be 401 (invalid token) or 500 (service error) but not 404
        assert response.status_code != 404, "Google auth endpoint should exist"

    def test_google_auth_without_token(self, client):
        """Test Google auth fails gracefully without token."""
        response = client.post(
            "/api/v1/users/auth/google",
            json={}
        )
        # Should fail validation (422) due to missing access_token
        assert response.status_code == 422

    @patch('api.v1.users.get_supabase')
    @patch('api.v1.users.get_supabase_db')
    def test_google_auth_with_invalid_token(self, mock_db, mock_supabase, client):
        """Test Google auth returns 401 for invalid token."""
        # Mock Supabase to return None user (invalid token)
        mock_supabase_instance = MagicMock()
        mock_supabase_instance.client.auth.get_user.return_value = MagicMock(user=None)
        mock_supabase.return_value = mock_supabase_instance

        response = client.post(
            "/api/v1/users/auth/google",
            json={"access_token": "invalid_token"}
        )

        assert response.status_code == 401
        assert "Invalid or expired" in response.json()["detail"]

    @patch('api.v1.users.get_supabase')
    @patch('api.v1.users.get_supabase_db')
    def test_google_auth_existing_user(self, mock_db, mock_supabase, client):
        """Test Google auth returns existing user."""
        # Mock Supabase user response
        mock_user = MagicMock()
        mock_user.id = "supabase-user-id-123"
        mock_user.email = "test@example.com"
        mock_user.user_metadata = {"full_name": "Test User"}

        mock_supabase_instance = MagicMock()
        mock_supabase_instance.client.auth.get_user.return_value = MagicMock(user=mock_user)
        mock_supabase.return_value = mock_supabase_instance

        # Mock database - user exists
        existing_user = {
            "id": "user-uuid-123",
            "auth_id": "supabase-user-id-123",
            "email": "test@example.com",
            "name": "Test User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": '["build_muscle"]',
            "equipment": '["dumbbells"]',
            "preferences": '{}',
            "active_injuries": '[]',
            "created_at": "2024-01-01T00:00:00Z",
        }
        mock_db_instance = MagicMock()
        mock_db_instance.get_user_by_auth_id.return_value = existing_user
        mock_db.return_value = mock_db_instance

        response = client.post(
            "/api/v1/users/auth/google",
            json={"access_token": "valid_token"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "user-uuid-123"
        assert data["email"] == "test@example.com"
        assert data["onboarding_completed"] == True

    @patch('api.v1.users.get_supabase')
    @patch('api.v1.users.get_supabase_db')
    def test_google_auth_new_user_creation(self, mock_db, mock_supabase, client):
        """Test Google auth creates new user when not found."""
        # Mock Supabase user response
        mock_user = MagicMock()
        mock_user.id = "new-supabase-user-id"
        mock_user.email = "newuser@example.com"
        mock_user.user_metadata = {"full_name": "New User"}

        mock_supabase_instance = MagicMock()
        mock_supabase_instance.client.auth.get_user.return_value = MagicMock(user=mock_user)
        mock_supabase.return_value = mock_supabase_instance

        # Mock database - user doesn't exist, then gets created
        created_user = {
            "id": "new-user-uuid",
            "auth_id": "new-supabase-user-id",
            "email": "newuser@example.com",
            "name": "New User",
            "onboarding_completed": False,
            "fitness_level": "beginner",
            "goals": "[]",
            "equipment": "[]",
            "preferences": '{"name": "New User", "email": "newuser@example.com"}',
            "active_injuries": [],
            "created_at": "2024-01-01T00:00:00Z",
        }
        mock_db_instance = MagicMock()
        mock_db_instance.get_user_by_auth_id.return_value = None  # User doesn't exist
        mock_db_instance.create_user.return_value = created_user
        mock_db.return_value = mock_db_instance

        response = client.post(
            "/api/v1/users/auth/google",
            json={"access_token": "valid_token"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == "new-user-uuid"
        assert data["email"] == "newuser@example.com"
        assert data["onboarding_completed"] == False
        assert data["fitness_level"] == "beginner"

        # Verify create_user was called with correct data
        mock_db_instance.create_user.assert_called_once()
        call_args = mock_db_instance.create_user.call_args[0][0]
        assert call_args["auth_id"] == "new-supabase-user-id"
        assert call_args["email"] == "newuser@example.com"
        assert call_args["goals"] == "[]"  # Should be string, not list
        assert call_args["equipment"] == "[]"  # Should be string, not list


class TestRowToUser:
    """Tests for the row_to_user helper function."""

    def test_row_to_user_basic(self):
        """Test row_to_user converts database row correctly."""
        row = {
            "id": "test-id",
            "email": "test@example.com",
            "name": "Test User",
            "onboarding_completed": True,
            "fitness_level": "intermediate",
            "goals": ["build_muscle", "lose_weight"],
            "equipment": ["dumbbells", "barbell"],
            "preferences": {"days_per_week": 4},
            "active_injuries": ["shoulder"],
            "created_at": "2024-01-01T00:00:00Z",
        }

        user = row_to_user(row)

        assert user.id == "test-id"
        assert user.email == "test@example.com"
        assert user.name == "Test User"
        assert user.onboarding_completed == True
        assert user.fitness_level == "intermediate"

    def test_row_to_user_json_fields(self):
        """Test row_to_user handles JSONB fields correctly."""
        row = {
            "id": "test-id",
            "email": "test@example.com",
            "onboarding_completed": False,
            "fitness_level": "beginner",
            "goals": ["goal1", "goal2"],  # List from JSONB
            "equipment": [],
            "preferences": {},
            "active_injuries": None,
            "created_at": "2024-01-01T00:00:00Z",
        }

        user = row_to_user(row)

        # JSONB fields should be converted to JSON strings
        assert isinstance(user.goals, str)
        assert isinstance(user.equipment, str)

    def test_row_to_user_null_handling(self):
        """Test row_to_user handles null values correctly."""
        row = {
            "id": "test-id",
            "email": None,
            "name": None,
            "onboarding_completed": False,
            "fitness_level": "beginner",
            "goals": None,
            "equipment": None,
            "preferences": None,
            "active_injuries": None,
            "created_at": "2024-01-01T00:00:00Z",
        }

        user = row_to_user(row)

        assert user.id == "test-id"
        assert user.goals == "[]"  # Default to empty array
        assert user.equipment == "[]"
        assert user.preferences == "{}"


class TestUserEndpoints:
    """Tests for general user management endpoints."""

    def test_get_user_not_found(self, client):
        """Test getting a non-existent user returns 404."""
        response = client.get("/api/v1/users/non-existent-user-id")

        # Should be 404 or 500 (if DB error), but endpoint should exist
        assert response.status_code in [404, 500]

    def test_users_list_endpoint_exists(self, client):
        """Test that users list endpoint exists."""
        response = client.get("/api/v1/users/")

        # Should not be 404
        assert response.status_code != 404
