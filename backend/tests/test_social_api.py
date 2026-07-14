"""
Tests for Social API endpoints.

Tests:
- Activity creation and retrieval
- Reactions (add/remove)
- User connections
- ChromaDB integration
- Privacy settings
"""

import contextlib
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone
import uuid

from main import app
from core.auth import get_current_user
from models.social import (
    ActivityType, Visibility, ReactionType, ConnectionType
)


client = TestClient(app)


# The social endpoints live in api/v1/social/{feed,reactions,connections}.py; each one
# does `from .utils import get_supabase_client` and `from services.social_rag_service
# import get_social_rag_service`, so those are the names that must be patched. (The old
# fixtures patched `utils.supabase_client.get_supabase_client` — a module that does not
# exist — which is why every test in this file errored at setup with
# "module 'utils' has no attribute 'supabase_client'".)
_SOCIAL_MODULES = (
    "api.v1.social.feed",
    "api.v1.social.reactions",
    "api.v1.social.connections",
)


# ============================================================
# FAKE SUPABASE
# ============================================================

class _FakeResult:
    def __init__(self, data):
        self.data = data


class _FakeQuery:
    """One postgrest query builder call-chain.

    Records the table + operation and returns whatever the test registered for that
    (table, operation) pair. This replaces the old `MagicMock().table.return_value.
    select.return_value.eq.return_value...` chains, which no longer described the
    production call shapes (e.g. add_reaction filters with .eq().eq(), the background
    ChromaDB indexers query `users` and `activity_feed`), so an unconfigured link in the
    chain silently returned a truthy MagicMock and drove the endpoint down the wrong
    branch. The fake is order- and depth-independent: `.eq()/.order()/.limit()/.range()`
    just accumulate filters.
    """

    def __init__(self, table: str, store: "FakeSupabase"):
        self._table = table
        self._store = store
        self._op = None
        self._payload = None
        self.filters = []

    def select(self, *args, **kwargs):
        self._op = "select"
        return self

    def insert(self, payload, *args, **kwargs):
        self._op = "insert"
        self._payload = payload
        self._store.calls.append(("insert", self._table, payload))
        return self

    def update(self, payload, *args, **kwargs):
        self._op = "update"
        self._payload = payload
        self._store.calls.append(("update", self._table, payload))
        return self

    def delete(self, *args, **kwargs):
        self._op = "delete"
        self._store.calls.append(("delete", self._table, None))
        return self

    def upsert(self, payload, *args, **kwargs):
        self._op = "upsert"
        self._payload = payload
        self._store.calls.append(("upsert", self._table, payload))
        return self

    def eq(self, column, value):
        self.filters.append((column, value))
        return self

    # Chainable no-ops used elsewhere in the social routers.
    def neq(self, *a, **k):
        return self

    def order(self, *a, **k):
        return self

    def limit(self, *a, **k):
        return self

    def range(self, *a, **k):
        return self

    def single(self):
        return self

    def execute(self):
        return _FakeResult(self._store.rows.get((self._table, self._op), []))


class FakeSupabase:
    """Stand-in for the postgrest client returned by get_supabase_client()."""

    def __init__(self):
        # (table, operation) -> rows returned by .execute()
        self.rows: dict = {}
        self.calls: list = []

    def set_rows(self, table: str, op: str, rows: list):
        self.rows[(table, op)] = rows

    def table(self, name: str) -> _FakeQuery:
        return _FakeQuery(name, self)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase():
    """Fake Supabase client, injected into every social router module."""
    fake = FakeSupabase()
    with contextlib.ExitStack() as stack:
        for module in _SOCIAL_MODULES:
            stack.enter_context(
                patch(f"{module}.get_supabase_client", return_value=fake)
            )
        yield fake


@pytest.fixture
def mock_social_rag():
    """Mock Social RAG service for testing."""
    rag_mock = MagicMock()
    with contextlib.ExitStack() as stack:
        for module in ("api.v1.social.feed", "api.v1.social.reactions"):
            stack.enter_context(
                patch(f"{module}.get_social_rag_service", return_value=rag_mock)
            )
        yield rag_mock


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing, authenticated for the duration of the test.

    The social endpoints gained `current_user: dict = Depends(get_current_user)` plus a
    `verify_user_ownership(current_user, user_id)` call. Overriding the dependency makes
    the requests below authenticate as the same user they pass in `?user_id=`, so the
    ownership check really runs (and really passes) instead of every request 401-ing.
    """
    user_id = str(uuid.uuid4())
    previous = app.dependency_overrides.get(get_current_user)
    app.dependency_overrides[get_current_user] = lambda: {"id": user_id}
    try:
        yield user_id
    finally:
        # Restore, don't just pop: `app` is a process-wide singleton shared with every
        # other test module.
        if previous is None:
            app.dependency_overrides.pop(get_current_user, None)
        else:
            app.dependency_overrides[get_current_user] = previous


@pytest.fixture
def sample_activity_data():
    """Sample activity data for workout completion."""
    return {
        "workout_name": "Upper Body Strength",
        "duration_minutes": 45,
        "exercises_count": 8,
        "total_volume": 5000,
        "exercises_performance": [
            {"name": "Bench Press", "sets": 4, "reps": 10, "weight_kg": 80},
            {"name": "Pull-ups", "sets": 3, "reps": 12, "weight_kg": 0},
            {"name": "Shoulder Press", "sets": 3, "reps": 10, "weight_kg": 30},
        ]
    }


# ============================================================
# ACTIVITY FEED TESTS
# ============================================================

def test_create_activity_success(mock_supabase, mock_social_rag, sample_user_id, sample_activity_data):
    """Test creating an activity feed item."""
    activity_id = str(uuid.uuid4())

    # Mock Supabase responses
    mock_supabase.set_rows("activity_feed", "insert", [{
        "id": activity_id,
        "user_id": sample_user_id,
        "activity_type": "workout_completed",
        "activity_data": sample_activity_data,
        "visibility": "friends",
        "reaction_count": 0,
        "comment_count": 0,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "workout_log_id": None,
        "achievement_id": None,
        "pr_id": None,
    }])

    # Mock user name lookup (done by the background ChromaDB indexer)
    mock_supabase.set_rows("users", "select", [{"name": "Test User"}])

    # Make request
    response = client.post(
        "/api/v1/social/feed",
        params={"user_id": sample_user_id},
        json={
            "activity_type": "workout_completed",
            "activity_data": sample_activity_data,
            "visibility": "friends",
        }
    )

    # Assertions
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == activity_id
    assert data["user_id"] == sample_user_id
    assert data["activity_type"] == "workout_completed"
    assert data["activity_data"] == sample_activity_data

    # Verify ChromaDB was called
    mock_social_rag.add_activity_to_rag.assert_called_once()


def test_create_activity_chromadb_failure_doesnt_fail_request(
    mock_supabase, mock_social_rag, sample_user_id, sample_activity_data
):
    """Test that ChromaDB failure doesn't fail the activity creation."""
    activity_id = str(uuid.uuid4())

    # Mock Supabase success
    mock_supabase.set_rows("activity_feed", "insert", [{
        "id": activity_id,
        "user_id": sample_user_id,
        "activity_type": "workout_completed",
        "activity_data": sample_activity_data,
        "visibility": "friends",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "reaction_count": 0,
        "comment_count": 0,
        "workout_log_id": None,
        "achievement_id": None,
        "pr_id": None,
    }])

    mock_supabase.set_rows("users", "select", [{"name": "Test User"}])

    # Mock ChromaDB failure
    mock_social_rag.add_activity_to_rag.side_effect = Exception("ChromaDB error")

    # Make request
    response = client.post(
        "/api/v1/social/feed",
        params={"user_id": sample_user_id},
        json={
            "activity_type": "workout_completed",
            "activity_data": sample_activity_data,
            "visibility": "friends",
        }
    )

    # Should still succeed
    assert response.status_code == 200


def test_delete_activity_success(mock_supabase, mock_social_rag, sample_user_id):
    """Test deleting an activity."""
    activity_id = str(uuid.uuid4())

    # Mock ownership check
    mock_supabase.set_rows("activity_feed", "select", [{"user_id": sample_user_id}])

    # Mock delete success
    mock_supabase.set_rows("activity_feed", "delete", [{"id": activity_id}])

    # Make request
    response = client.delete(
        f"/api/v1/social/feed/{activity_id}",
        params={"user_id": sample_user_id}
    )

    # Assertions
    assert response.status_code == 200
    assert response.json()["message"] == "Activity deleted successfully"

    # Verify ChromaDB deletion was called
    mock_social_rag.delete_activity_from_rag.assert_called_once_with(activity_id)


def test_delete_activity_not_owner(mock_supabase, sample_user_id):
    """Test that user cannot delete someone else's activity."""
    activity_id = str(uuid.uuid4())
    other_user_id = str(uuid.uuid4())

    # Mock ownership check - different owner
    mock_supabase.set_rows("activity_feed", "select", [{"user_id": other_user_id}])

    # Make request
    response = client.delete(
        f"/api/v1/social/feed/{activity_id}",
        params={"user_id": sample_user_id}
    )

    # Should fail with 403
    assert response.status_code == 403


# ============================================================
# REACTION TESTS
# ============================================================

def test_add_reaction_success(mock_supabase, mock_social_rag, sample_user_id):
    """Test adding a reaction to an activity."""
    activity_id = str(uuid.uuid4())
    reaction_id = str(uuid.uuid4())

    # Mock no existing reaction
    mock_supabase.set_rows("activity_reactions", "select", [])

    # Mock insert success
    mock_supabase.set_rows("activity_reactions", "insert", [{
        "id": reaction_id,
        "activity_id": activity_id,
        "user_id": sample_user_id,
        "reaction_type": "fire",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }])

    # Mock user and activity owner lookups (background ChromaDB indexer)
    mock_supabase.set_rows("users", "select", [{"name": "Test User"}])
    mock_supabase.set_rows("activity_feed", "select", [{"user_id": sample_user_id}])

    # Make request
    response = client.post(
        "/api/v1/social/reactions",
        params={"user_id": sample_user_id},
        json={
            "activity_id": activity_id,
            "reaction_type": "fire",
        }
    )

    # Assertions
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == reaction_id
    assert data["reaction_type"] == "fire"

    # Verify ChromaDB was called
    mock_social_rag.add_reaction_to_rag.assert_called_once()


def test_update_existing_reaction(mock_supabase, mock_social_rag, sample_user_id):
    """Test updating an existing reaction (changing from fire to strong)."""
    activity_id = str(uuid.uuid4())
    reaction_id = str(uuid.uuid4())

    # Mock existing reaction
    mock_supabase.set_rows("activity_reactions", "select", [{
        "id": reaction_id,
        "activity_id": activity_id,
        "user_id": sample_user_id,
        "reaction_type": "fire",
    }])

    # Mock update success
    mock_supabase.set_rows("activity_reactions", "update", [{
        "id": reaction_id,
        "activity_id": activity_id,
        "user_id": sample_user_id,
        "reaction_type": "strong",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }])
    mock_supabase.set_rows("users", "select", [{"name": "Test User"}])
    mock_supabase.set_rows("activity_feed", "select", [{"user_id": sample_user_id}])

    # Make request
    response = client.post(
        "/api/v1/social/reactions",
        params={"user_id": sample_user_id},
        json={
            "activity_id": activity_id,
            "reaction_type": "strong",
        }
    )

    # Should update, not insert
    assert response.status_code == 200
    data = response.json()
    assert data["reaction_type"] == "strong"


def test_remove_reaction_success(mock_supabase, mock_social_rag, sample_user_id):
    """Test removing a reaction."""
    activity_id = str(uuid.uuid4())
    reaction_id = str(uuid.uuid4())

    # Mock reaction lookup
    mock_supabase.set_rows("activity_reactions", "select", [{"id": reaction_id}])

    # Mock delete success
    mock_supabase.set_rows("activity_reactions", "delete", [{"id": reaction_id}])

    # Make request
    response = client.delete(
        f"/api/v1/social/reactions/{activity_id}",
        params={"user_id": sample_user_id}
    )

    # Assertions
    assert response.status_code == 200
    assert response.json()["message"] == "Reaction removed successfully"

    # Verify ChromaDB deletion
    mock_social_rag.remove_reaction_from_rag.assert_called_once_with(reaction_id)


def test_remove_nonexistent_reaction(mock_supabase, sample_user_id):
    """Test removing a reaction that doesn't exist."""
    activity_id = str(uuid.uuid4())

    # Mock no reaction found
    mock_supabase.set_rows("activity_reactions", "select", [])

    # Make request
    response = client.delete(
        f"/api/v1/social/reactions/{activity_id}",
        params={"user_id": sample_user_id}
    )

    # Should fail with 404
    assert response.status_code == 404


# ============================================================
# USER CONNECTIONS TESTS
# ============================================================

def test_create_connection_success(mock_supabase, sample_user_id):
    """Test following a user."""
    following_id = str(uuid.uuid4())

    # Mock no existing connection
    mock_supabase.set_rows("user_connections", "select", [])

    # Mock insert success
    mock_supabase.set_rows("user_connections", "insert", [{
        "id": str(uuid.uuid4()),
        "follower_id": sample_user_id,
        "following_id": following_id,
        "connection_type": "following",
        "status": "active",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }])

    # Make request
    response = client.post(
        "/api/v1/social/connections",
        params={"user_id": sample_user_id},
        json={
            "following_id": following_id,
            "connection_type": "following",
        }
    )

    # Assertions
    assert response.status_code == 200
    data = response.json()
    assert data["follower_id"] == sample_user_id
    assert data["following_id"] == following_id


def test_cannot_follow_self(mock_supabase, sample_user_id):
    """Test that user cannot follow themselves."""
    # Make request with same user ID
    response = client.post(
        "/api/v1/social/connections",
        params={"user_id": sample_user_id},
        json={
            "following_id": sample_user_id,  # Same as follower
            "connection_type": "following",
        }
    )

    # Should fail with 400
    assert response.status_code == 400
    assert "Cannot follow yourself" in response.json()["detail"]


def test_cannot_follow_twice(mock_supabase, sample_user_id):
    """Test that user cannot follow the same user twice."""
    following_id = str(uuid.uuid4())

    # Mock existing connection
    mock_supabase.set_rows("user_connections", "select", [{
        "id": str(uuid.uuid4()),
        "follower_id": sample_user_id,
        "following_id": following_id,
    }])

    # Make request
    response = client.post(
        "/api/v1/social/connections",
        params={"user_id": sample_user_id},
        json={
            "following_id": following_id,
            "connection_type": "following",
        }
    )

    # Should fail with 400
    assert response.status_code == 400
    assert "Already following" in response.json()["detail"]


# ============================================================
# INTEGRATION TESTS
# ============================================================

def test_activity_with_reactions_flow(mock_supabase, mock_social_rag, sample_user_id, sample_activity_data):
    """Test complete flow: create activity -> add reaction -> remove reaction."""
    activity_id = str(uuid.uuid4())
    reaction_id = str(uuid.uuid4())

    # 1. Create activity
    mock_supabase.set_rows("activity_feed", "insert", [{
        "id": activity_id,
        "user_id": sample_user_id,
        "activity_type": "workout_completed",
        "activity_data": sample_activity_data,
        "visibility": "friends",
        "reaction_count": 0,
        "comment_count": 0,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "workout_log_id": None,
        "achievement_id": None,
        "pr_id": None,
    }])

    mock_supabase.set_rows("users", "select", [{"name": "Test User"}])
    mock_supabase.set_rows("activity_feed", "select", [{"user_id": sample_user_id}])

    create_response = client.post(
        "/api/v1/social/feed",
        params={"user_id": sample_user_id},
        json={
            "activity_type": "workout_completed",
            "activity_data": sample_activity_data,
            "visibility": "friends",
        }
    )

    assert create_response.status_code == 200
    assert mock_social_rag.add_activity_to_rag.called

    # 2. Add reaction
    mock_supabase.set_rows("activity_reactions", "select", [])
    mock_supabase.set_rows("activity_reactions", "insert", [{
        "id": reaction_id,
        "activity_id": activity_id,
        "user_id": sample_user_id,
        "reaction_type": "fire",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }])

    reaction_response = client.post(
        "/api/v1/social/reactions",
        params={"user_id": sample_user_id},
        json={
            "activity_id": activity_id,
            "reaction_type": "fire",
        }
    )

    assert reaction_response.status_code == 200
    assert mock_social_rag.add_reaction_to_rag.called

    # 3. Remove reaction
    mock_supabase.set_rows("activity_reactions", "select", [{"id": reaction_id}])
    mock_supabase.set_rows("activity_reactions", "delete", [{"id": reaction_id}])

    remove_response = client.delete(
        f"/api/v1/social/reactions/{activity_id}",
        params={"user_id": sample_user_id}
    )

    assert remove_response.status_code == 200
    assert mock_social_rag.remove_reaction_from_rag.called


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
