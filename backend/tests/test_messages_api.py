"""
Tests for Direct Messages API endpoints.

Tests:
- Get conversations list
- Get messages in conversation
- Send message
- Mark messages as read
- Get/create conversation with user

HOW THESE TESTS CALL THE API (updated 2026-07) — two wiring bugs in the test
harness, not in the product:

1. AUTH. Every endpoint now depends on `get_current_user` and calls
   `verify_user_ownership(current_user, user_id)` (IDOR guard). Requests without
   a JWT died at the auth layer with 401 before any endpoint code ran, so these
   tests asserted nothing about messaging. They now override the dependency to
   authenticate as TEST_USER_ID (which is also `sample_user_id`, so the ownership
   check passes) — exactly the pattern used by tests/test_goal_social_api.py.

2. MOCK TARGET. `api.v1.social.messages` imports `get_supabase_db` from `core.db`
   (`from core.db import get_supabase_db`), so patching `core.supabase_db.get_supabase_db`
   was a no-op — the endpoints kept using the real client. The fixture now patches
   the name the module actually resolves at call time.

The DB mock also follows the endpoints' CURRENT query shapes: `get_conversations`
is one `get_user_conversations` RPC + a batched participants read, the message
reads filter on `is_("left_at"/"deleted_at", "null")`, and `send_message` runs a
block check. Assertions are unchanged.
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, Mock, patch, MagicMock
from datetime import datetime, timezone
import uuid

from core.auth import get_current_user
from main import app

client = TestClient(app)


# Fixed so the authenticated identity and the `user_id` query param agree — the
# endpoints reject a mismatch with 403 (IDOR guard).
TEST_USER_ID = "11111111-1111-4111-8111-111111111111"


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture(autouse=True)
def override_auth():
    """Authenticate every request in this module as TEST_USER_ID."""
    app.dependency_overrides[get_current_user] = lambda: {
        "id": TEST_USER_ID,
        "email": "test-user@example.com",
    }
    yield
    app.dependency_overrides.pop(get_current_user, None)


class _TableRouter:
    """Routes db.client.table("x") to a per-table MagicMock.

    The endpoints touch several tables in one request; a single shared MagicMock
    makes identical chains (e.g. `.select().eq().execute()` on `conversations`
    and on `users`) collide. Routing by table name keeps each mock honest.
    """

    def __init__(self):
        self._tables = {}

    def __call__(self, name):
        return self._tables.setdefault(name, MagicMock())

    def __getitem__(self, name):
        return self._tables.setdefault(name, MagicMock())


@pytest.fixture
def mock_supabase():
    """Mock the Supabase DB facade the messages endpoints actually use."""
    with patch('api.v1.social.messages.get_supabase_db') as mock:
        db_mock = MagicMock()
        router = _TableRouter()
        db_mock.client.table.side_effect = router
        db_mock.tables = router
        mock.return_value = db_mock
        yield db_mock


@pytest.fixture(autouse=True)
def mock_activity_logging():
    """Silence the fire-and-forget activity/context writes (real Supabase calls)."""
    with patch('api.v1.social.messages.log_user_activity', new=AsyncMock()), \
         patch('api.v1.social.messages.log_user_error', new=AsyncMock()), \
         patch('api.v1.social.messages.user_context_service.log_event', new=AsyncMock()):
        yield


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing (matches the authenticated identity)."""
    return TEST_USER_ID


@pytest.fixture
def sample_recipient_id():
    """Sample recipient ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_conversation_id():
    """Sample conversation ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_conversation_data(sample_conversation_id, sample_user_id, sample_recipient_id):
    """Sample conversation data."""
    return {
        "id": sample_conversation_id,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "last_message_at": datetime.now(timezone.utc).isoformat(),
        "conversation_participants": [
            {
                "user_id": sample_user_id,
                "last_read_at": None,
                "is_muted": False,
                "users": {
                    "name": "Test User",
                    "avatar_url": None,
                    "is_support_user": False,
                }
            },
            {
                "user_id": sample_recipient_id,
                "last_read_at": None,
                "is_muted": False,
                "users": {
                    "name": "Zealova Support",
                    "avatar_url": None,
                    "is_support_user": True,
                }
            }
        ]
    }


@pytest.fixture
def sample_message_data(sample_conversation_id, sample_user_id):
    """Sample message data."""
    return {
        "id": str(uuid.uuid4()),
        "conversation_id": sample_conversation_id,
        "sender_id": sample_user_id,
        "content": "Hello, this is a test message!",
        "is_system_message": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "edited_at": None,
        "deleted_at": None,
    }


# ============================================================
# GET CONVERSATIONS TESTS
# ============================================================

def test_get_conversations_success(mock_supabase, sample_user_id, sample_recipient_id, sample_conversation_data):
    """Test getting conversations list."""
    # Conversations now come from a single RPC (last message + unread count inlined)
    mock_supabase.client.rpc.return_value.execute.return_value.data = [{
        "conversation_id": sample_conversation_data["id"],
        "created_at": sample_conversation_data["created_at"],
        "last_message_at": sample_conversation_data["last_message_at"],
        "unread_count": 0,
        "last_msg_id": None,
    }]

    # Batched participant fetch for the "other user" info
    participants = mock_supabase.tables["conversation_participants"]
    participants.select.return_value.in_.return_value.neq.return_value.is_.return_value.execute.return_value.data = [
        {
            "conversation_id": sample_conversation_data["id"],
            "user_id": sample_recipient_id,
            "last_read_at": None,
            "is_muted": False,
            "users": {"name": "Zealova Support", "avatar_url": None, "is_support_user": True},
        }
    ]

    response = client.get(
        f"/api/v1/social/messages/conversations",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 200
    data = response.json()
    assert "conversations" in data
    assert "total_count" in data
    assert data["total_count"] == 1
    assert data["conversations"][0]["id"] == sample_conversation_data["id"]
    assert data["conversations"][0]["participants"][0]["user_id"] == sample_recipient_id


def test_get_conversations_empty(mock_supabase, sample_user_id):
    """Test getting empty conversations list."""
    mock_supabase.client.rpc.return_value.execute.return_value.data = []

    response = client.get(
        f"/api/v1/social/messages/conversations",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["conversations"] == []
    assert data["total_count"] == 0


# ============================================================
# GET MESSAGES TESTS
# ============================================================

def test_get_messages_success(mock_supabase, sample_user_id, sample_conversation_id, sample_message_data):
    """Test getting messages in a conversation."""
    participants = mock_supabase.tables["conversation_participants"]
    # Participant check (excludes members who left)
    participants.select.return_value.eq.return_value.eq.return_value.is_.return_value.execute.return_value.data = [
        {"id": str(uuid.uuid4())}
    ]
    # Read receipts: other participants in the conversation
    participants.select.return_value.eq.return_value.is_.return_value.neq.return_value.execute.return_value.data = []

    messages_table = mock_supabase.tables["direct_messages"]
    # Count query (excludes soft-deleted)
    messages_table.select.return_value.eq.return_value.is_.return_value.execute.return_value.count = 1
    # Messages page
    messages_table.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value.data = [
        {**sample_message_data, "users": {"name": "Test User", "avatar_url": None, "is_support_user": False}}
    ]

    response = client.get(
        f"/api/v1/social/messages/conversations/{sample_conversation_id}",
        params={"user_id": sample_user_id, "page": 1, "page_size": 50}
    )

    assert response.status_code == 200
    data = response.json()
    assert "messages" in data
    assert "conversation_id" in data
    assert data["conversation_id"] == sample_conversation_id
    assert data["total_count"] == 1
    assert data["messages"][0]["content"] == sample_message_data["content"]
    assert data["messages"][0]["sender_name"] == "Test User"


def test_get_messages_unauthorized(mock_supabase, sample_user_id, sample_conversation_id):
    """Test getting messages when not a participant."""
    participants = mock_supabase.tables["conversation_participants"]
    # Participant check - returns empty (not authorized)
    participants.select.return_value.eq.return_value.eq.return_value.is_.return_value.execute.return_value.data = []

    response = client.get(
        f"/api/v1/social/messages/conversations/{sample_conversation_id}",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 403
    assert "Not authorized" in response.json()["detail"]


# ============================================================
# SEND MESSAGE TESTS
# ============================================================

def test_send_message_success(mock_supabase, sample_user_id, sample_recipient_id, sample_conversation_id):
    """Test sending a message."""
    message_id = str(uuid.uuid4())

    # Neither user has blocked the other
    mock_supabase.tables["user_blocks"].select.return_value.or_.return_value.execute.return_value.data = []

    # Mock get_or_create_conversation RPC
    mock_supabase.client.rpc.return_value.execute.return_value.data = sample_conversation_id

    # Mock message insert
    mock_supabase.tables["direct_messages"].insert.return_value.execute.return_value.data = [{
        "id": message_id,
        "conversation_id": sample_conversation_id,
        "sender_id": sample_user_id,
        "content": "Hello!",
        "is_system_message": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }]

    # Mock sender info query
    mock_supabase.tables["users"].select.return_value.eq.return_value.execute.return_value.data = [{
        "name": "Test User",
        "avatar_url": None,
        "is_support_user": False,
    }]

    response = client.post(
        f"/api/v1/social/messages/send",
        params={"user_id": sample_user_id},
        json={
            "recipient_id": sample_recipient_id,
            "content": "Hello!",
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert "id" in data
    assert "conversation_id" in data
    assert data["content"] == "Hello!"
    assert data["conversation_id"] == sample_conversation_id
    assert data["sender_name"] == "Test User"


def test_send_message_with_conversation_id(mock_supabase, sample_user_id, sample_recipient_id, sample_conversation_id):
    """Test sending a message to existing conversation."""
    message_id = str(uuid.uuid4())

    # Existing 1:1 conversation (not a group)
    mock_supabase.tables["conversations"].select.return_value.eq.return_value.execute.return_value.data = [
        {"id": sample_conversation_id, "is_group": False}
    ]
    # Neither user has blocked the other
    mock_supabase.tables["user_blocks"].select.return_value.or_.return_value.execute.return_value.data = []

    # Mock message insert
    mock_supabase.tables["direct_messages"].insert.return_value.execute.return_value.data = [{
        "id": message_id,
        "conversation_id": sample_conversation_id,
        "sender_id": sample_user_id,
        "content": "Follow-up message",
        "is_system_message": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }]

    # Mock sender info query
    mock_supabase.tables["users"].select.return_value.eq.return_value.execute.return_value.data = [{
        "name": "Test User",
        "avatar_url": None,
        "is_support_user": False,
    }]

    response = client.post(
        f"/api/v1/social/messages/send",
        params={"user_id": sample_user_id},
        json={
            "recipient_id": sample_recipient_id,
            "content": "Follow-up message",
            "conversation_id": sample_conversation_id,
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert data["conversation_id"] == sample_conversation_id
    assert data["content"] == "Follow-up message"
    # An existing conversation must NOT be re-created via the RPC
    mock_supabase.client.rpc.assert_not_called()


# ============================================================
# MARK AS READ TESTS
# ============================================================

def test_mark_as_read_success(mock_supabase, sample_user_id, sample_conversation_id):
    """Test marking messages as read."""
    participants = mock_supabase.tables["conversation_participants"]
    # Mock participant check
    participants.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
        {"id": str(uuid.uuid4())}
    ]

    response = client.post(
        f"/api/v1/social/messages/conversations/{sample_conversation_id}/read",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["conversation_id"] == sample_conversation_id
    # last_read_at was actually written
    participants.update.assert_called_once()
    assert "last_read_at" in participants.update.call_args[0][0]


def test_mark_as_read_unauthorized(mock_supabase, sample_user_id, sample_conversation_id):
    """Test marking as read when not authorized."""
    participants = mock_supabase.tables["conversation_participants"]
    # Mock participant check - returns empty
    participants.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

    response = client.post(
        f"/api/v1/social/messages/conversations/{sample_conversation_id}/read",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 403
    participants.update.assert_not_called()


# ============================================================
# GET CONVERSATION WITH USER TESTS
# ============================================================

def test_get_conversation_with_user_exists(mock_supabase, sample_user_id, sample_recipient_id, sample_conversation_data):
    """Test getting existing conversation with a user."""
    # Mock RPC
    mock_supabase.client.rpc.return_value.execute.return_value.data = sample_conversation_data["id"]

    # Mock conversation query
    mock_supabase.tables["conversations"].select.return_value.eq.return_value.execute.return_value.data = [
        sample_conversation_data
    ]

    # Mock last message query
    mock_supabase.tables["direct_messages"].select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []

    response = client.get(
        f"/api/v1/social/messages/with/{sample_recipient_id}",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 200
    data = response.json()
    assert data is not None
    assert "id" in data
    assert data["id"] == sample_conversation_data["id"]
    # Only the OTHER participant is returned
    assert [p["user_id"] for p in data["participants"]] == [sample_recipient_id]


def test_get_conversation_with_user_creates_new(mock_supabase, sample_user_id, sample_recipient_id):
    """Test creating new conversation when none exists."""
    new_conv_id = str(uuid.uuid4())

    # Mock RPC - creates new
    mock_supabase.client.rpc.return_value.execute.return_value.data = new_conv_id

    # Mock conversation query
    mock_supabase.tables["conversations"].select.return_value.eq.return_value.execute.return_value.data = [{
        "id": new_conv_id,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "last_message_at": datetime.now(timezone.utc).isoformat(),
        "conversation_participants": [
            {
                "user_id": sample_user_id,
                "users": {"name": "User 1", "avatar_url": None, "is_support_user": False}
            },
            {
                "user_id": sample_recipient_id,
                "users": {"name": "User 2", "avatar_url": None, "is_support_user": False}
            }
        ]
    }]

    # Mock last message query
    mock_supabase.tables["direct_messages"].select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []

    response = client.get(
        f"/api/v1/social/messages/with/{sample_recipient_id}",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 200
    assert response.json()["id"] == new_conv_id
