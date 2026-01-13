"""
Tests for Direct Messages API endpoints.

Tests:
- Get conversations list
- Get messages in conversation
- Send message
- Mark messages as read
- Get/create conversation with user
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone
import uuid

from main import app

client = TestClient(app)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase():
    """Mock Supabase client for testing."""
    with patch('core.supabase_db.get_supabase_db') as mock:
        db_mock = MagicMock()
        mock.return_value = db_mock
        yield db_mock


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


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
                    "name": "FitWiz Support",
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

def test_get_conversations_success(mock_supabase, sample_user_id, sample_conversation_data):
    """Test getting conversations list."""
    # Mock participant query
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
        {"conversation_id": sample_conversation_data["id"]}
    ]

    # Mock conversations query
    mock_supabase.client.table.return_value.select.return_value.in_.return_value.order.return_value.execute.return_value.data = [
        sample_conversation_data
    ]

    # Mock last message query
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []

    # Mock unread count
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.neq.return_value.execute.return_value.count = 0

    response = client.get(
        f"/api/v1/social/messages/conversations",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 200
    data = response.json()
    assert "conversations" in data
    assert "total_count" in data


def test_get_conversations_empty(mock_supabase, sample_user_id):
    """Test getting empty conversations list."""
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

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
    # Mock participant check
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
        {"id": str(uuid.uuid4())}
    ]

    # Mock count query
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.is_.return_value.execute.return_value.count = 1

    # Mock messages query
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value.data = [
        {**sample_message_data, "users": {"name": "Test User", "avatar_url": None, "is_support_user": False}}
    ]

    # Mock update last_read_at
    mock_supabase.client.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value = None

    response = client.get(
        f"/api/v1/social/messages/conversations/{sample_conversation_id}",
        params={"user_id": sample_user_id, "page": 1, "page_size": 50}
    )

    assert response.status_code == 200
    data = response.json()
    assert "messages" in data
    assert "conversation_id" in data
    assert data["conversation_id"] == sample_conversation_id


def test_get_messages_unauthorized(mock_supabase, sample_user_id, sample_conversation_id):
    """Test getting messages when not a participant."""
    # Mock participant check - returns empty (not authorized)
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

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

    # Mock get_or_create_conversation RPC
    mock_supabase.client.rpc.return_value.execute.return_value.data = sample_conversation_id

    # Mock message insert
    mock_supabase.client.table.return_value.insert.return_value.execute.return_value.data = [{
        "id": message_id,
        "conversation_id": sample_conversation_id,
        "sender_id": sample_user_id,
        "content": "Hello!",
        "is_system_message": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }]

    # Mock conversation update
    mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = None

    # Mock sender info query
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
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


def test_send_message_with_conversation_id(mock_supabase, sample_user_id, sample_recipient_id, sample_conversation_id):
    """Test sending a message to existing conversation."""
    message_id = str(uuid.uuid4())

    # Mock message insert
    mock_supabase.client.table.return_value.insert.return_value.execute.return_value.data = [{
        "id": message_id,
        "conversation_id": sample_conversation_id,
        "sender_id": sample_user_id,
        "content": "Follow-up message",
        "is_system_message": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }]

    # Mock conversation update
    mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = None

    # Mock sender info query
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
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


# ============================================================
# MARK AS READ TESTS
# ============================================================

def test_mark_as_read_success(mock_supabase, sample_user_id, sample_conversation_id):
    """Test marking messages as read."""
    # Mock participant check
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [
        {"id": str(uuid.uuid4())}
    ]

    # Mock update
    mock_supabase.client.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value = None

    response = client.post(
        f"/api/v1/social/messages/conversations/{sample_conversation_id}/read",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["conversation_id"] == sample_conversation_id


def test_mark_as_read_unauthorized(mock_supabase, sample_user_id, sample_conversation_id):
    """Test marking as read when not authorized."""
    # Mock participant check - returns empty
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []

    response = client.post(
        f"/api/v1/social/messages/conversations/{sample_conversation_id}/read",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 403


# ============================================================
# GET CONVERSATION WITH USER TESTS
# ============================================================

def test_get_conversation_with_user_exists(mock_supabase, sample_user_id, sample_recipient_id, sample_conversation_data):
    """Test getting existing conversation with a user."""
    # Mock RPC
    mock_supabase.client.rpc.return_value.execute.return_value.data = sample_conversation_data["id"]

    # Mock conversation query
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
        sample_conversation_data
    ]

    # Mock last message query
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []

    response = client.get(
        f"/api/v1/social/messages/with/{sample_recipient_id}",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 200
    data = response.json()
    assert data is not None
    assert "id" in data


def test_get_conversation_with_user_creates_new(mock_supabase, sample_user_id, sample_recipient_id):
    """Test creating new conversation when none exists."""
    new_conv_id = str(uuid.uuid4())

    # Mock RPC - creates new
    mock_supabase.client.rpc.return_value.execute.return_value.data = new_conv_id

    # Mock conversation query
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [{
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
    mock_supabase.client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value.data = []

    response = client.get(
        f"/api/v1/social/messages/with/{sample_recipient_id}",
        params={"user_id": sample_user_id}
    )

    assert response.status_code == 200
