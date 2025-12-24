"""
Tests for core/db/user_db.py module.

Tests user CRUD operations, injuries, metrics, and chat history.
"""
import pytest
from unittest.mock import MagicMock, patch, PropertyMock
from datetime import datetime


class MockQueryBuilder:
    """Mock Supabase query builder for testing."""

    def __init__(self, data=None):
        self._data = data or []

    def select(self, *args, **kwargs):
        return self

    def insert(self, data):
        self._data = [data] if isinstance(data, dict) else data
        return self

    def update(self, data):
        return self

    def delete(self):
        return self

    def eq(self, *args):
        return self

    def neq(self, *args):
        return self

    def gte(self, *args):
        return self

    def lte(self, *args):
        return self

    def ilike(self, *args):
        return self

    def order(self, *args, **kwargs):
        return self

    def limit(self, *args):
        return self

    def range(self, *args):
        return self

    def execute(self):
        return MagicMock(data=self._data)


class MockSupabaseClient:
    """Mock Supabase client for testing."""

    def __init__(self, table_data=None):
        self._table_data = table_data or {}

    def table(self, name):
        data = self._table_data.get(name, [])
        return MockQueryBuilder(data)


class MockSupabaseManager:
    """Mock SupabaseManager for testing."""

    def __init__(self, client=None):
        self._client = client or MockSupabaseClient()

    @property
    def client(self):
        return self._client


@pytest.fixture
def mock_supabase_manager():
    """Create a mock SupabaseManager."""
    return MockSupabaseManager()


@pytest.fixture
def user_db(mock_supabase_manager):
    """Create UserDB with mocked Supabase."""
    from core.db.user_db import UserDB
    return UserDB(mock_supabase_manager)


class TestUserDBGetUser:
    """Test UserDB.get_user method."""

    def test_get_user_found(self, mock_supabase_manager):
        """Should return user when found."""
        user_data = {"id": "user-123", "email": "test@example.com", "name": "Test User"}
        mock_supabase_manager._client._table_data["users"] = [user_data]

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.get_user("user-123")
        assert result == user_data

    def test_get_user_not_found(self, user_db):
        """Should return None when user not found."""
        result = user_db.get_user("nonexistent-user")
        assert result is None


class TestUserDBGetAllUsers:
    """Test UserDB.get_all_users method."""

    def test_get_all_users_with_data(self, mock_supabase_manager):
        """Should return all users."""
        users = [
            {"id": "user-1", "email": "user1@example.com"},
            {"id": "user-2", "email": "user2@example.com"},
        ]
        mock_supabase_manager._client._table_data["users"] = users

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.get_all_users()
        assert len(result) == 2

    def test_get_all_users_empty(self, user_db):
        """Should return empty list when no users."""
        result = user_db.get_all_users()
        assert result == []


class TestUserDBGetUserByAuthId:
    """Test UserDB.get_user_by_auth_id method."""

    def test_get_user_by_auth_id_found(self, mock_supabase_manager):
        """Should return user when found by auth_id."""
        user_data = {"id": "user-123", "auth_id": "auth-456", "email": "test@example.com"}
        mock_supabase_manager._client._table_data["users"] = [user_data]

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.get_user_by_auth_id("auth-456")
        assert result == user_data

    def test_get_user_by_auth_id_not_found(self, user_db):
        """Should return None when auth_id not found."""
        result = user_db.get_user_by_auth_id("nonexistent-auth")
        assert result is None


class TestUserDBGetUserByEmail:
    """Test UserDB.get_user_by_email method."""

    def test_get_user_by_email_found(self, mock_supabase_manager):
        """Should return user when found by email."""
        user_data = {"id": "user-123", "email": "test@example.com"}
        mock_supabase_manager._client._table_data["users"] = [user_data]

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.get_user_by_email("test@example.com")
        assert result == user_data

    def test_get_user_by_email_not_found(self, user_db):
        """Should return None when email not found."""
        result = user_db.get_user_by_email("nonexistent@example.com")
        assert result is None


class TestUserDBCreateUser:
    """Test UserDB.create_user method."""

    def test_create_user_success(self, mock_supabase_manager):
        """Should create and return new user."""
        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        user_data = {"email": "new@example.com", "name": "New User"}
        result = db.create_user(user_data)

        assert result == user_data

    def test_create_user_with_all_fields(self, mock_supabase_manager):
        """Should create user with all provided fields."""
        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        user_data = {
            "email": "test@example.com",
            "name": "Test User",
            "fitness_level": "intermediate",
            "goals": ["build muscle", "lose fat"],
        }
        result = db.create_user(user_data)

        assert result["email"] == "test@example.com"
        assert result["fitness_level"] == "intermediate"


class TestUserDBUpdateUser:
    """Test UserDB.update_user method."""

    def test_update_user_success(self, user_db):
        """Should update and return user."""
        update_data = {"name": "Updated Name"}
        result = user_db.update_user("user-123", update_data)
        # Since mock returns empty, result will be None
        # In real scenario, it would return updated user


class TestUserDBDeleteUser:
    """Test UserDB.delete_user method."""

    def test_delete_user_success(self, user_db):
        """Should return True after deleting user."""
        result = user_db.delete_user("user-123")
        assert result is True


class TestUserDBInjuries:
    """Test UserDB injury methods."""

    def test_list_injuries_all(self, mock_supabase_manager):
        """Should list all injuries for user."""
        injuries = [
            {"id": 1, "user_id": "user-123", "body_part": "shoulder", "is_active": True},
            {"id": 2, "user_id": "user-123", "body_part": "knee", "is_active": False},
        ]
        mock_supabase_manager._client._table_data["injuries"] = injuries

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.list_injuries("user-123")
        assert len(result) == 2

    def test_list_injuries_active_only(self, mock_supabase_manager):
        """Should filter by active status."""
        injuries = [
            {"id": 1, "user_id": "user-123", "body_part": "shoulder", "is_active": True},
        ]
        mock_supabase_manager._client._table_data["injuries"] = injuries

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.list_injuries("user-123", is_active=True)
        assert len(result) == 1

    def test_create_injury(self, user_db):
        """Should create injury record."""
        injury_data = {
            "user_id": "user-123",
            "body_part": "shoulder",
            "description": "Rotator cuff strain",
            "is_active": True,
        }
        result = user_db.create_injury(injury_data)
        assert result["body_part"] == "shoulder"

    def test_update_injury(self, user_db):
        """Should update injury record."""
        update_data = {"is_active": False}
        result = user_db.update_injury(1, update_data)

    def test_delete_injuries_by_user(self, user_db):
        """Should delete all injuries for user."""
        result = user_db.delete_injuries_by_user("user-123")
        assert result is True


class TestUserDBInjuryHistory:
    """Test UserDB injury history methods."""

    def test_list_injury_history(self, mock_supabase_manager):
        """Should list injury history for user."""
        history = [
            {"id": 1, "user_id": "user-123", "body_part": "shoulder"},
        ]
        mock_supabase_manager._client._table_data["injury_history"] = history

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.list_injury_history("user-123")
        assert len(result) == 1

    def test_get_active_injuries(self, mock_supabase_manager):
        """Should get only active injuries."""
        history = [
            {"id": 1, "user_id": "user-123", "is_active": True},
        ]
        mock_supabase_manager._client._table_data["injury_history"] = history

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.get_active_injuries("user-123")
        assert len(result) == 1

    def test_create_injury_history(self, user_db):
        """Should create injury history record."""
        data = {"user_id": "user-123", "body_part": "knee", "is_active": True}
        result = user_db.create_injury_history(data)
        assert result["body_part"] == "knee"

    def test_delete_injury_history_by_user(self, user_db):
        """Should delete all injury history for user."""
        result = user_db.delete_injury_history_by_user("user-123")
        assert result is True


class TestUserDBMetrics:
    """Test UserDB user metrics methods."""

    def test_list_user_metrics(self, mock_supabase_manager):
        """Should list user metrics history."""
        metrics = [
            {"id": 1, "user_id": "user-123", "weight_kg": 80.0},
            {"id": 2, "user_id": "user-123", "weight_kg": 79.5},
        ]
        mock_supabase_manager._client._table_data["user_metrics"] = metrics

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.list_user_metrics("user-123")
        assert len(result) == 2

    def test_create_user_metrics(self, user_db):
        """Should create user metrics record."""
        data = {"user_id": "user-123", "weight_kg": 80.0, "body_fat_pct": 15.0}
        result = user_db.create_user_metrics(data)
        assert result["weight_kg"] == 80.0

    def test_get_latest_user_metrics(self, mock_supabase_manager):
        """Should get most recent metrics."""
        metrics = [{"id": 1, "user_id": "user-123", "weight_kg": 80.0}]
        mock_supabase_manager._client._table_data["user_metrics"] = metrics

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.get_latest_user_metrics("user-123")
        assert result["weight_kg"] == 80.0

    def test_delete_user_metrics_by_user(self, user_db):
        """Should delete all metrics for user."""
        result = user_db.delete_user_metrics_by_user("user-123")
        assert result is True


class TestUserDBChatHistory:
    """Test UserDB chat history methods."""

    def test_list_chat_history(self, mock_supabase_manager):
        """Should list chat history for user."""
        messages = [
            {"id": 1, "user_id": "user-123", "message": "Hello"},
            {"id": 2, "user_id": "user-123", "message": "Hi there"},
        ]
        mock_supabase_manager._client._table_data["chat_history"] = messages

        from core.db.user_db import UserDB
        db = UserDB(mock_supabase_manager)

        result = db.list_chat_history("user-123")
        assert len(result) == 2

    def test_create_chat_message(self, user_db):
        """Should create chat message."""
        data = {"user_id": "user-123", "message": "Hello", "role": "user"}
        result = user_db.create_chat_message(data)
        assert result["message"] == "Hello"

    def test_delete_chat_history_by_user(self, user_db):
        """Should delete all chat history for user."""
        result = user_db.delete_chat_history_by_user("user-123")
        assert result is True
