"""
Tests for Live Chat API endpoints.

This module tests:

Live Chat API Tests:
1. test_start_live_chat_success - Start a new live chat session
2. test_start_live_chat_with_escalation - Start with AI escalation context
3. test_get_queue_position - Get queue position
4. test_send_message - Send message in active chat
5. test_send_typing_indicator - Send typing status
6. test_mark_messages_read - Mark messages as read
7. test_end_chat - End chat session
8. test_check_availability - Check if support is available

Admin API Tests:
9. test_admin_login_success - Admin login with valid credentials
10. test_admin_login_wrong_role - Reject non-admin users
11. test_get_active_live_chats - List active chats as admin
12. test_admin_reply - Send reply as admin
13. test_assign_chat - Assign chat to agent
14. test_close_chat - Close/resolve chat
15. test_dashboard_stats - Get dashboard statistics

Webhook Tests:
16. test_webhook_notification_on_new_chat - Webhook called when user starts chat
17. test_webhook_notification_on_new_message - Webhook called on new message

Edge Cases:
18. test_unauthorized_access - Non-admin cannot access admin endpoints
19. test_chat_not_found - Handle missing ticket
20. test_already_ended_chat - Cannot send message to ended chat
"""

import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient


# =============================================================================
# Mock UUIDs and Constants
# =============================================================================

MOCK_USER_ID = "test-user-123"
MOCK_OTHER_USER_ID = "other-user-456"
MOCK_ADMIN_USER_ID = "admin-user-789"
MOCK_AGENT_ID = "agent-user-101"
MOCK_TICKET_ID = "live-chat-ticket-001"
MOCK_MESSAGE_ID = "message-abc-123"
MOCK_ACCESS_TOKEN = "mock-access-token-12345"
MOCK_REFRESH_TOKEN = "mock-refresh-token-67890"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    with patch("api.v1.live_chat.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_supabase_admin():
    """Create a mock Supabase client for admin endpoints."""
    with patch("api.v1.admin.live_chat.get_supabase_db") as mock_db:
        with patch("api.v1.admin.live_chat.get_supabase_client") as mock_client:
            mock_database = MagicMock()
            mock_auth_client = MagicMock()
            mock_db.return_value = mock_database
            mock_client.return_value = mock_auth_client
            yield mock_database, mock_auth_client


@pytest.fixture
def mock_user_context():
    """Mock user context service."""
    with patch("api.v1.live_chat.user_context_service") as mock:
        mock.log_event = AsyncMock(return_value="event-id-123")
        yield mock


@pytest.fixture
def mock_activity_logger():
    """Mock activity logger for live chat."""
    with patch("api.v1.live_chat.log_user_activity", new_callable=AsyncMock) as mock_activity:
        with patch("api.v1.live_chat.log_user_error", new_callable=AsyncMock) as mock_error:
            yield mock_activity, mock_error


@pytest.fixture
def mock_activity_logger_admin():
    """Mock activity logger for admin endpoints."""
    with patch("api.v1.admin.live_chat.log_user_activity", new_callable=AsyncMock) as mock_activity:
        yield mock_activity


@pytest.fixture
def mock_notification_service():
    """Mock notification service for push notifications."""
    with patch("api.v1.admin.live_chat.get_notification_service") as mock:
        mock_service = MagicMock()
        mock_service.send_notification = AsyncMock(return_value=True)
        mock.return_value = mock_service
        yield mock_service


@pytest.fixture
def mock_admin_token_verification():
    """Mock admin token verification to bypass authentication."""
    from models.admin import AdminProfile, AdminRole

    admin_profile = AdminProfile(
        id=MOCK_ADMIN_USER_ID,
        email="admin@example.com",
        name="Test Admin",
        role=AdminRole.ADMIN,
        is_online=True,
        last_seen=datetime.utcnow(),
        created_at=datetime.utcnow(),
        active_chats_count=0,
    )

    with patch("api.v1.admin.live_chat.verify_admin_token", return_value=admin_profile):
        yield admin_profile


@pytest.fixture
def client():
    """Create a test client."""
    from main import app
    return TestClient(app)


# =============================================================================
# Helper Functions
# =============================================================================

def generate_mock_ticket(
    ticket_id: str = MOCK_TICKET_ID,
    user_id: str = MOCK_USER_ID,
    category: str = "technical",
    status: str = "open",
    chat_mode: str = "live_chat",
    assigned_to: str = None,
    escalated_from_ai: bool = False,
    ai_handoff_context: str = None,
):
    """Generate a mock live chat ticket response."""
    return {
        "id": ticket_id,
        "user_id": user_id,
        "subject": f"Live Chat - {category.replace('_', ' ').title()}",
        "category": category,
        "priority": "high",
        "status": status,
        "chat_mode": chat_mode,
        "assigned_to": assigned_to,
        "escalated_from_ai": escalated_from_ai,
        "ai_handoff_context": ai_handoff_context,
        "created_at": "2024-12-30T12:00:00Z",
        "updated_at": "2024-12-30T12:00:00Z",
        "resolved_at": None,
        "closed_at": None,
    }


def generate_mock_message(
    message_id: str = MOCK_MESSAGE_ID,
    ticket_id: str = MOCK_TICKET_ID,
    sender_role: str = "user",
    sender_id: str = MOCK_USER_ID,
    message: str = "This is a test message",
    is_system_message: bool = False,
    read_at: str = None,
):
    """Generate a mock live chat message response."""
    return {
        "id": message_id,
        "ticket_id": ticket_id,
        "sender_role": sender_role,
        "sender_id": sender_id,
        "message": message,
        "is_system_message": is_system_message,
        "created_at": "2024-12-30T12:00:00Z",
        "read_at": read_at,
    }


def generate_mock_queue_entry(
    ticket_id: str = MOCK_TICKET_ID,
    user_id: str = MOCK_USER_ID,
    category: str = "technical",
):
    """Generate a mock queue entry response."""
    return {
        "id": "queue-entry-001",
        "ticket_id": ticket_id,
        "user_id": user_id,
        "category": category,
        "escalated_from_ai": False,
        "user_typing": False,
        "agent_typing": False,
        "created_at": "2024-12-30T12:00:00Z",
    }


def generate_mock_admin_user(
    user_id: str = MOCK_ADMIN_USER_ID,
    role: str = "admin",
    name: str = "Test Admin",
    email: str = "admin@example.com",
):
    """Generate a mock admin user response."""
    return {
        "id": user_id,
        "email": email,
        "name": name,
        "display_name": name,
        "role": role,
        "avatar_url": None,
        "created_at": "2024-01-01T00:00:00Z",
    }


def generate_mock_presence(
    admin_id: str = MOCK_ADMIN_USER_ID,
    is_online: bool = True,
):
    """Generate a mock presence entry."""
    return {
        "admin_id": admin_id,
        "is_online": is_online,
        "last_seen": "2024-12-30T12:00:00Z",
        "status_message": None,
    }


# =============================================================================
# Live Chat API Tests - Start Live Chat
# =============================================================================

class TestStartLiveChat:
    """Tests for POST /live-chat/start"""

    def test_start_live_chat_success(
        self, client, mock_supabase, mock_user_context, mock_activity_logger
    ):
        """Test successfully starting a new live chat session."""
        # Setup mocks
        mock_ticket = generate_mock_ticket()
        mock_message = generate_mock_message()
        mock_queue = generate_mock_queue_entry()

        mock_insert_ticket = MagicMock()
        mock_insert_ticket.data = [mock_ticket]

        mock_insert_message = MagicMock()
        mock_insert_message.data = [mock_message]

        mock_insert_queue = MagicMock()
        mock_insert_queue.data = [mock_queue]

        # Mock queue position queries
        mock_queue_entry_result = MagicMock()
        mock_queue_entry_result.data = [{"created_at": "2024-12-30T12:00:00Z"}]

        mock_queue_count_result = MagicMock()
        mock_queue_count_result.count = 0

        mock_agents_result = MagicMock()
        mock_agents_result.count = 2

        # Chain the mock calls
        mock_supabase.client.table.return_value.insert.return_value.execute.side_effect = [
            mock_insert_ticket,
            mock_insert_message,
            mock_insert_queue,
        ]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_queue_entry_result
        mock_supabase.client.table.return_value.select.return_value.lt.return_value.execute.return_value = mock_queue_count_result
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_agents_result

        # Make request
        response = client.post(
            "/api/v1/live-chat/start",
            json={
                "user_id": MOCK_USER_ID,
                "category": "technical",
                "initial_message": "I need help with my workout plan. The exercises are not loading correctly.",
                "escalated_from_ai": False,
            }
        )

        # Verify
        assert response.status_code == 200
        data = response.json()
        assert data["ticket_id"] == MOCK_TICKET_ID
        assert data["queue_position"] >= 0
        assert data["status"] == "queued"

    def test_start_live_chat_with_escalation(
        self, client, mock_supabase, mock_user_context, mock_activity_logger
    ):
        """Test starting a live chat with AI escalation context."""
        ai_context = "User was asking about nutrition plans but AI couldn't provide specific calorie recommendations."

        mock_ticket = generate_mock_ticket(
            escalated_from_ai=True,
            ai_handoff_context=ai_context,
        )
        mock_message = generate_mock_message()
        mock_queue = generate_mock_queue_entry()

        mock_insert_ticket = MagicMock()
        mock_insert_ticket.data = [mock_ticket]

        mock_insert_message = MagicMock()
        mock_insert_message.data = [mock_message]

        mock_insert_queue = MagicMock()
        mock_insert_queue.data = [mock_queue]

        mock_queue_entry_result = MagicMock()
        mock_queue_entry_result.data = [{"created_at": "2024-12-30T12:00:00Z"}]

        mock_queue_count_result = MagicMock()
        mock_queue_count_result.count = 0

        mock_agents_result = MagicMock()
        mock_agents_result.count = 1

        mock_supabase.client.table.return_value.insert.return_value.execute.side_effect = [
            mock_insert_ticket,
            mock_insert_message,
            mock_insert_queue,
        ]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_queue_entry_result
        mock_supabase.client.table.return_value.select.return_value.lt.return_value.execute.return_value = mock_queue_count_result
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_agents_result

        response = client.post(
            "/api/v1/live-chat/start",
            json={
                "user_id": MOCK_USER_ID,
                "category": "other",
                "initial_message": "The AI couldn't help me, need human support.",
                "escalated_from_ai": True,
                "ai_handoff_context": ai_context,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["ticket_id"] is not None
        assert data["status"] == "queued"


# =============================================================================
# Live Chat API Tests - Queue Position
# =============================================================================

class TestGetQueuePosition:
    """Tests for GET /live-chat/queue-position/{ticket_id}"""

    def test_get_queue_position(self, client, mock_supabase):
        """Test getting queue position for a ticket."""
        mock_ticket = generate_mock_ticket()
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_queue_entry = MagicMock()
        mock_queue_entry.data = [{"created_at": "2024-12-30T12:00:00Z"}]

        mock_position_count = MagicMock()
        mock_position_count.count = 2  # 2 people ahead

        mock_agents_result = MagicMock()
        mock_agents_result.count = 3

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_queue_entry
        mock_supabase.client.table.return_value.select.return_value.lt.return_value.execute.return_value = mock_position_count
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_agents_result

        response = client.get(
            f"/api/v1/live-chat/queue-position/{MOCK_TICKET_ID}?user_id={MOCK_USER_ID}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["ticket_id"] == MOCK_TICKET_ID
        assert "queue_position" in data
        assert "status" in data

    def test_get_queue_position_not_found(self, client, mock_supabase):
        """Test getting queue position for non-existent ticket."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(
            f"/api/v1/live-chat/queue-position/nonexistent-ticket?user_id={MOCK_USER_ID}"
        )

        assert response.status_code == 404


# =============================================================================
# Live Chat API Tests - Send Message
# =============================================================================

class TestSendMessage:
    """Tests for POST /live-chat/{ticket_id}/message"""

    def test_send_message(self, client, mock_supabase, mock_activity_logger):
        """Test sending a message in active chat."""
        mock_ticket = generate_mock_ticket(status="in_progress", assigned_to=MOCK_AGENT_ID)
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_message = generate_mock_message()
        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        # Mock user role check (not an agent)
        mock_user_check = MagicMock()
        mock_user_check.data = [{"role": "user"}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            mock_ticket_result,
            mock_user_check,
        ]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_message_result
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result

        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "Thank you for your help!",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["message"]["message"] == "This is a test message"

    def test_send_message_to_closed_chat(self, client, mock_supabase):
        """Test that sending message to closed chat fails."""
        mock_ticket = generate_mock_ticket(status="closed")
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_ticket_result

        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "Trying to send to closed chat",
            }
        )

        assert response.status_code == 400
        assert "closed" in response.json()["detail"].lower()

    def test_send_message_unauthorized(self, client, mock_supabase):
        """Test that user cannot send message to another user's chat."""
        mock_ticket = generate_mock_ticket(user_id=MOCK_OTHER_USER_ID)
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_user_check = MagicMock()
        mock_user_check.data = [{"role": "user"}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            mock_ticket_result,
            mock_user_check,
        ]

        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "Trying to access other's chat",
            }
        )

        assert response.status_code == 403


# =============================================================================
# Live Chat API Tests - Typing Indicator
# =============================================================================

class TestTypingIndicator:
    """Tests for POST /live-chat/{ticket_id}/typing"""

    def test_send_typing_indicator(self, client, mock_supabase):
        """Test sending typing status update."""
        mock_ticket = generate_mock_ticket()
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_user_check = MagicMock()
        mock_user_check.data = [{"role": "user"}]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            mock_ticket_result,
            mock_user_check,
        ]
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result

        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/typing",
            json={
                "user_id": MOCK_USER_ID,
                "is_typing": True,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["is_typing"] is True

    def test_clear_typing_indicator(self, client, mock_supabase):
        """Test clearing typing indicator."""
        mock_ticket = generate_mock_ticket()
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_user_check = MagicMock()
        mock_user_check.data = [{"role": "user"}]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            mock_ticket_result,
            mock_user_check,
        ]
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result

        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/typing",
            json={
                "user_id": MOCK_USER_ID,
                "is_typing": False,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["is_typing"] is False


# =============================================================================
# Live Chat API Tests - Mark Messages Read
# =============================================================================

class TestMarkMessagesRead:
    """Tests for POST /live-chat/{ticket_id}/read"""

    def test_mark_messages_read(self, client, mock_supabase):
        """Test marking messages as read."""
        mock_ticket = generate_mock_ticket()
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_user_check = MagicMock()
        mock_user_check.data = [{"role": "user"}]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            mock_ticket_result,
            mock_user_check,
        ]
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.eq.return_value.execute.return_value = mock_update_result

        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/read",
            json={
                "user_id": MOCK_USER_ID,
                "message_ids": ["msg-1", "msg-2", "msg-3"],
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["messages_marked_read"] == 3


# =============================================================================
# Live Chat API Tests - End Chat
# =============================================================================

class TestEndChat:
    """Tests for POST /live-chat/{ticket_id}/end"""

    def test_end_chat(self, client, mock_supabase, mock_user_context, mock_activity_logger):
        """Test ending a chat session."""
        mock_ticket = generate_mock_ticket(status="in_progress")
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_user_check = MagicMock()
        mock_user_check.data = [{"role": "user"}]

        mock_insert_result = MagicMock()
        mock_insert_result.data = [{}]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_delete_result = MagicMock()
        mock_delete_result.data = []

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            mock_ticket_result,
            mock_user_check,
        ]
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert_result
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result
        mock_supabase.client.table.return_value.delete.return_value.eq.return_value.execute.return_value = mock_delete_result

        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/end",
            json={
                "user_id": MOCK_USER_ID,
                "resolution_note": "Issue resolved by the support agent.",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["status"] == "ended"

    def test_end_already_ended_chat(self, client, mock_supabase, mock_user_context, mock_activity_logger):
        """Test ending an already ended chat returns success."""
        mock_ticket = generate_mock_ticket(status="resolved")
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_user_check = MagicMock()
        mock_user_check.data = [{"role": "user"}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            mock_ticket_result,
            mock_user_check,
        ]

        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/end",
            json={
                "user_id": MOCK_USER_ID,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["status"] == "ended"


# =============================================================================
# Live Chat API Tests - Check Availability
# =============================================================================

class TestCheckAvailability:
    """Tests for GET /live-chat/availability"""

    def test_check_availability_agents_online(self, client, mock_supabase):
        """Test checking availability when agents are online."""
        mock_agents_result = MagicMock()
        mock_agents_result.count = 3

        mock_queue_result = MagicMock()
        mock_queue_result.count = 2

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_agents_result
        mock_supabase.client.table.return_value.select.return_value.execute.return_value = mock_queue_result

        response = client.get("/api/v1/live-chat/availability")

        assert response.status_code == 200
        data = response.json()
        assert data["is_available"] is True
        assert data["agents_online_count"] > 0

    def test_check_availability_no_agents(self, client, mock_supabase):
        """Test checking availability when no agents are online."""
        mock_agents_result = MagicMock()
        mock_agents_result.count = 0

        mock_queue_result = MagicMock()
        mock_queue_result.count = 0

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_agents_result
        mock_supabase.client.table.return_value.select.return_value.execute.return_value = mock_queue_result

        response = client.get("/api/v1/live-chat/availability")

        assert response.status_code == 200
        data = response.json()
        assert data["is_available"] is False
        assert data["agents_online_count"] == 0
        assert data["operating_hours"] is not None


# =============================================================================
# Admin API Tests - Login
# =============================================================================

class TestAdminLogin:
    """Tests for POST /admin/login"""

    def test_admin_login_success(self, client, mock_supabase_admin, mock_activity_logger_admin):
        """Test successful admin login with valid credentials."""
        mock_db, mock_auth_client = mock_supabase_admin

        # Mock successful authentication
        mock_session = MagicMock()
        mock_session.access_token = MOCK_ACCESS_TOKEN
        mock_session.refresh_token = MOCK_REFRESH_TOKEN

        mock_user = MagicMock()
        mock_user.id = MOCK_ADMIN_USER_ID

        mock_auth_response = MagicMock()
        mock_auth_response.user = mock_user
        mock_auth_response.session = mock_session

        mock_auth_client.auth.sign_in_with_password.return_value = mock_auth_response

        # Mock user data lookup
        mock_user_data = generate_mock_admin_user()
        mock_user_result = MagicMock()
        mock_user_result.data = [mock_user_data]

        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_user_result

        # Mock presence update
        mock_upsert_result = MagicMock()
        mock_upsert_result.data = [{}]
        mock_db.client.table.return_value.upsert.return_value.execute.return_value = mock_upsert_result

        response = client.post(
            "/api/v1/admin/login",
            json={
                "email": "admin@example.com",
                "password": "secure-password-123",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["access_token"] == MOCK_ACCESS_TOKEN
        assert data["admin_id"] == MOCK_ADMIN_USER_ID
        assert data["role"] == "admin"

    def test_admin_login_wrong_role(self, client, mock_supabase_admin):
        """Test that non-admin users cannot login to admin panel."""
        mock_db, mock_auth_client = mock_supabase_admin

        # Mock successful authentication
        mock_session = MagicMock()
        mock_session.access_token = MOCK_ACCESS_TOKEN

        mock_user = MagicMock()
        mock_user.id = MOCK_USER_ID

        mock_auth_response = MagicMock()
        mock_auth_response.user = mock_user
        mock_auth_response.session = mock_session

        mock_auth_client.auth.sign_in_with_password.return_value = mock_auth_response

        # Mock user data lookup - returns regular user role
        mock_user_data = generate_mock_admin_user(user_id=MOCK_USER_ID, role="user")
        mock_user_result = MagicMock()
        mock_user_result.data = [mock_user_data]

        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_user_result

        response = client.post(
            "/api/v1/admin/login",
            json={
                "email": "user@example.com",
                "password": "user-password-123",
            }
        )

        assert response.status_code == 403
        assert "admin" in response.json()["detail"].lower() or "role" in response.json()["detail"].lower()

    def test_admin_login_invalid_credentials(self, client, mock_supabase_admin):
        """Test admin login with invalid credentials."""
        mock_db, mock_auth_client = mock_supabase_admin

        # Mock failed authentication
        mock_auth_client.auth.sign_in_with_password.return_value = None

        response = client.post(
            "/api/v1/admin/login",
            json={
                "email": "admin@example.com",
                "password": "wrong-password",
            }
        )

        assert response.status_code == 401


# =============================================================================
# Admin API Tests - Get Active Live Chats
# =============================================================================

class TestGetActiveLiveChats:
    """Tests for GET /admin/live-chats"""

    def test_get_active_live_chats(
        self, client, mock_supabase_admin, mock_admin_token_verification
    ):
        """Test listing active chats as admin."""
        mock_db, _ = mock_supabase_admin

        # Mock live chat tickets
        mock_tickets = [
            {
                **generate_mock_ticket("ticket-1", status="in_progress", assigned_to=MOCK_AGENT_ID),
                "users": {"name": "Test User 1", "email": "user1@example.com"},
            },
            {
                **generate_mock_ticket("ticket-2", status="open"),
                "users": {"name": "Test User 2", "email": "user2@example.com"},
            },
        ]

        mock_tickets_result = MagicMock()
        mock_tickets_result.data = mock_tickets

        mock_count_result = MagicMock()
        mock_count_result.count = 2

        mock_unread_result = MagicMock()
        mock_unread_result.count = 1

        mock_last_msg_result = MagicMock()
        mock_last_msg_result.data = [{"message": "Last message preview", "created_at": "2024-12-30T12:00:00Z"}]

        mock_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_tickets_result
        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_count_result
        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.execute.return_value = mock_unread_result
        mock_db.client.table.return_value.select.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_last_msg_result

        response = client.get(
            "/api/v1/admin/live-chats",
            headers={"Authorization": f"Bearer {MOCK_ACCESS_TOKEN}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert "chats" in data
        assert "total" in data


# =============================================================================
# Admin API Tests - Reply to Live Chat
# =============================================================================

class TestAdminReply:
    """Tests for POST /admin/live-chats/{ticket_id}/reply"""

    def test_admin_reply(
        self, client, mock_supabase_admin, mock_admin_token_verification, mock_notification_service
    ):
        """Test sending reply as admin."""
        mock_db, _ = mock_supabase_admin

        mock_ticket = generate_mock_ticket(status="in_progress", assigned_to=MOCK_ADMIN_USER_ID)
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_message = generate_mock_message(
            sender_role="agent",
            sender_id=MOCK_ADMIN_USER_ID,
            message="Hello, how can I help you today?",
        )
        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_fcm_result = MagicMock()
        mock_fcm_result.data = [{"fcm_token": "mock-fcm-token"}]

        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_db.client.table.return_value.insert.return_value.execute.return_value = mock_message_result
        mock_db.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result
        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_fcm_result

        response = client.post(
            f"/api/v1/admin/live-chats/{MOCK_TICKET_ID}/reply",
            json={
                "message": "Hello, how can I help you today?",
            },
            headers={"Authorization": f"Bearer {MOCK_ACCESS_TOKEN}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["message"]["sender_role"] == "agent"

    def test_admin_reply_to_closed_chat(
        self, client, mock_supabase_admin, mock_admin_token_verification
    ):
        """Test that admin cannot reply to closed chat."""
        mock_db, _ = mock_supabase_admin

        mock_ticket = generate_mock_ticket(status="resolved")
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result

        response = client.post(
            f"/api/v1/admin/live-chats/{MOCK_TICKET_ID}/reply",
            json={
                "message": "Trying to reply to closed chat",
            },
            headers={"Authorization": f"Bearer {MOCK_ACCESS_TOKEN}"}
        )

        assert response.status_code == 400


# =============================================================================
# Admin API Tests - Assign Chat
# =============================================================================

class TestAssignChat:
    """Tests for POST /admin/live-chats/{ticket_id}/assign"""

    def test_assign_chat(
        self, client, mock_supabase_admin, mock_admin_token_verification, mock_notification_service
    ):
        """Test assigning chat to agent."""
        mock_db, _ = mock_supabase_admin

        mock_ticket = generate_mock_ticket(status="open")
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_agent_data = generate_mock_admin_user(user_id=MOCK_AGENT_ID, name="Support Agent")
        mock_agent_result = MagicMock()
        mock_agent_result.data = [mock_agent_data]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_delete_result = MagicMock()
        mock_delete_result.data = []

        mock_insert_result = MagicMock()
        mock_insert_result.data = [{}]

        mock_fcm_result = MagicMock()
        mock_fcm_result.data = [{"fcm_token": "mock-fcm-token"}]

        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_agent_result
        mock_db.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result
        mock_db.client.table.return_value.delete.return_value.eq.return_value.execute.return_value = mock_delete_result
        mock_db.client.table.return_value.insert.return_value.execute.return_value = mock_insert_result
        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_fcm_result

        response = client.post(
            f"/api/v1/admin/live-chats/{MOCK_TICKET_ID}/assign",
            json={
                "agent_id": MOCK_AGENT_ID,
                "agent_name": "Support Agent",
            },
            headers={"Authorization": f"Bearer {MOCK_ACCESS_TOKEN}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["agent_id"] == MOCK_AGENT_ID


# =============================================================================
# Admin API Tests - Close Chat
# =============================================================================

class TestCloseChat:
    """Tests for POST /admin/live-chats/{ticket_id}/close"""

    def test_close_chat(
        self, client, mock_supabase_admin, mock_admin_token_verification, mock_notification_service
    ):
        """Test closing/resolving a chat."""
        mock_db, _ = mock_supabase_admin

        mock_ticket = generate_mock_ticket(status="in_progress", assigned_to=MOCK_ADMIN_USER_ID)
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_insert_result = MagicMock()
        mock_insert_result.data = [{}]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_delete_result = MagicMock()
        mock_delete_result.data = []

        mock_fcm_result = MagicMock()
        mock_fcm_result.data = [{"fcm_token": "mock-fcm-token"}]

        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_db.client.table.return_value.insert.return_value.execute.return_value = mock_insert_result
        mock_db.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result
        mock_db.client.table.return_value.delete.return_value.eq.return_value.execute.return_value = mock_delete_result
        mock_db.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.limit.return_value.execute.return_value = mock_fcm_result

        response = client.post(
            f"/api/v1/admin/live-chats/{MOCK_TICKET_ID}/close",
            json={
                "resolution_note": "Issue resolved. User was able to complete their workout.",
            },
            headers={"Authorization": f"Bearer {MOCK_ACCESS_TOKEN}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["status"] == "resolved"


# =============================================================================
# Admin API Tests - Dashboard Stats
# =============================================================================

class TestDashboardStats:
    """Tests for GET /admin/dashboard"""

    def test_dashboard_stats(
        self, client, mock_supabase_admin, mock_admin_token_verification
    ):
        """Test getting dashboard statistics."""
        mock_db, _ = mock_supabase_admin

        # Mock various stats queries
        mock_count_result = MagicMock()
        mock_count_result.count = 5

        mock_queue_times_result = MagicMock()
        mock_queue_times_result.data = [
            {"created_at": "2024-12-30T11:50:00Z"},
            {"created_at": "2024-12-30T11:55:00Z"},
        ]

        mock_agents_result = MagicMock()
        mock_agents_result.data = [
            {"admin_id": MOCK_ADMIN_USER_ID, "is_online": True, "last_seen": "2024-12-30T12:00:00Z"}
        ]

        mock_agent_info = MagicMock()
        mock_agent_info.data = [{"name": "Test Admin"}]

        # Set up return values for all the dashboard queries
        mock_db.client.table.return_value.select.return_value.eq.return_value.not_.return_value.is_.return_value.neq.return_value.neq.return_value.execute.return_value = mock_count_result
        mock_db.client.table.return_value.select.return_value.execute.return_value = mock_count_result
        mock_db.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_agents_result
        mock_db.client.table.return_value.select.return_value.neq.return_value.in_.return_value.execute.return_value = mock_count_result
        mock_db.client.table.return_value.select.return_value.gte.return_value.execute.return_value = mock_count_result
        mock_db.client.table.return_value.select.return_value.in_.return_value.execute.return_value = mock_count_result

        response = client.get(
            "/api/v1/admin/dashboard",
            headers={"Authorization": f"Bearer {MOCK_ACCESS_TOKEN}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert "active_live_chats" in data
        assert "queued_live_chats" in data
        assert "agents_online" in data
        assert "resolved_today" in data


# =============================================================================
# Webhook Tests
# =============================================================================

class TestWebhookNotifications:
    """Tests for webhook notifications."""

    def test_webhook_notification_on_new_chat(
        self, client, mock_supabase, mock_user_context, mock_activity_logger
    ):
        """Test that webhook is called when user starts chat."""
        with patch("api.v1.live_chat._send_admin_webhook", new_callable=AsyncMock) as mock_webhook:
            mock_ticket = generate_mock_ticket()
            mock_message = generate_mock_message()
            mock_queue = generate_mock_queue_entry()

            mock_insert_ticket = MagicMock()
            mock_insert_ticket.data = [mock_ticket]

            mock_insert_message = MagicMock()
            mock_insert_message.data = [mock_message]

            mock_insert_queue = MagicMock()
            mock_insert_queue.data = [mock_queue]

            mock_queue_entry_result = MagicMock()
            mock_queue_entry_result.data = [{"created_at": "2024-12-30T12:00:00Z"}]

            mock_queue_count_result = MagicMock()
            mock_queue_count_result.count = 0

            mock_agents_result = MagicMock()
            mock_agents_result.count = 2

            mock_supabase.client.table.return_value.insert.return_value.execute.side_effect = [
                mock_insert_ticket,
                mock_insert_message,
                mock_insert_queue,
            ]

            mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_queue_entry_result
            mock_supabase.client.table.return_value.select.return_value.lt.return_value.execute.return_value = mock_queue_count_result
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_agents_result

            response = client.post(
                "/api/v1/live-chat/start",
                json={
                    "user_id": MOCK_USER_ID,
                    "category": "technical",
                    "initial_message": "I need help with my workout plan.",
                }
            )

            assert response.status_code == 200
            # Verify webhook was called
            mock_webhook.assert_called_once()
            call_args = mock_webhook.call_args
            assert call_args[1]["event_type"] == "live_chat_started"

    def test_webhook_notification_on_new_message(
        self, client, mock_supabase, mock_activity_logger
    ):
        """Test that webhook is called on new user message."""
        with patch("api.v1.live_chat._send_admin_webhook", new_callable=AsyncMock) as mock_webhook:
            mock_ticket = generate_mock_ticket(status="in_progress", assigned_to=MOCK_AGENT_ID)
            mock_ticket_result = MagicMock()
            mock_ticket_result.data = [mock_ticket]

            mock_message = generate_mock_message()
            mock_message_result = MagicMock()
            mock_message_result.data = [mock_message]

            mock_user_check = MagicMock()
            mock_user_check.data = [{"role": "user"}]

            mock_update_result = MagicMock()
            mock_update_result.data = [{}]

            mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
                mock_ticket_result,
                mock_user_check,
            ]
            mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_message_result
            mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result

            response = client.post(
                f"/api/v1/live-chat/{MOCK_TICKET_ID}/message",
                json={
                    "user_id": MOCK_USER_ID,
                    "message": "Thank you for your help!",
                }
            )

            assert response.status_code == 200
            # Verify webhook was called for user message
            mock_webhook.assert_called_once()
            call_args = mock_webhook.call_args
            assert call_args[1]["event_type"] == "live_chat_message"


# =============================================================================
# Edge Cases Tests
# =============================================================================

class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_unauthorized_access(self, client, mock_supabase_admin):
        """Test that non-admin cannot access admin endpoints."""
        mock_db, mock_auth_client = mock_supabase_admin

        # Mock failed token verification
        mock_auth_client.auth.get_user.return_value = None

        response = client.get(
            "/api/v1/admin/live-chats",
            headers={"Authorization": "Bearer invalid-token"}
        )

        assert response.status_code == 401

    def test_chat_not_found(self, client, mock_supabase):
        """Test handling of missing ticket."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.post(
            "/api/v1/live-chat/nonexistent-ticket/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "Hello?",
            }
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_already_ended_chat(self, client, mock_supabase):
        """Test that cannot send message to ended chat."""
        mock_ticket = generate_mock_ticket(status="resolved")
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_ticket_result

        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "Trying to send to ended chat",
            }
        )

        assert response.status_code == 400
        assert "closed" in response.json()["detail"].lower()

    def test_invalid_category(self, client, mock_supabase):
        """Test that invalid category is rejected."""
        response = client.post(
            "/api/v1/live-chat/start",
            json={
                "user_id": MOCK_USER_ID,
                "category": "invalid_category_xyz",
                "initial_message": "This should fail.",
            }
        )

        assert response.status_code == 422  # Validation error

    def test_empty_message(self, client, mock_supabase):
        """Test that empty message is rejected."""
        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "",
            }
        )

        assert response.status_code == 422  # Validation error

    def test_message_too_long(self, client, mock_supabase):
        """Test that message exceeding max length is rejected."""
        response = client.post(
            f"/api/v1/live-chat/{MOCK_TICKET_ID}/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "x" * 5001,  # Max is 5000
            }
        )

        assert response.status_code == 422  # Validation error

    def test_database_error_handling(self, client, mock_supabase, mock_activity_logger):
        """Test graceful handling of database errors."""
        mock_supabase.client.table.return_value.insert.return_value.execute.side_effect = Exception("Database connection failed")

        response = client.post(
            "/api/v1/live-chat/start",
            json={
                "user_id": MOCK_USER_ID,
                "category": "technical",
                "initial_message": "This should trigger a database error.",
            }
        )

        assert response.status_code == 500


# =============================================================================
# Escalation Tests
# =============================================================================

class TestEscalation:
    """Tests for escalating existing tickets to live chat."""

    def test_escalate_ticket_to_live_chat(
        self, client, mock_supabase, mock_user_context, mock_activity_logger
    ):
        """Test escalating an existing ticket to live chat."""
        mock_ticket = generate_mock_ticket(chat_mode="ticket")  # Regular ticket
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_insert_result = MagicMock()
        mock_insert_result.data = [{}]

        mock_queue_entry_result = MagicMock()
        mock_queue_entry_result.data = [{"created_at": "2024-12-30T12:00:00Z"}]

        mock_queue_count_result = MagicMock()
        mock_queue_count_result.count = 0

        mock_agents_result = MagicMock()
        mock_agents_result.count = 1

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_insert_result
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_queue_entry_result
        mock_supabase.client.table.return_value.select.return_value.lt.return_value.execute.return_value = mock_queue_count_result

        response = client.post(
            f"/api/v1/live-chat/escalate/{MOCK_TICKET_ID}",
            json={
                "user_id": MOCK_USER_ID,
                "ai_handoff_context": "User requested human support after AI couldn't answer their question.",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["ticket_id"] == MOCK_TICKET_ID
        assert data["status"] == "queued"

    def test_escalate_already_live_chat(
        self, client, mock_supabase, mock_user_context, mock_activity_logger
    ):
        """Test escalating a ticket that is already in live chat mode."""
        mock_ticket = generate_mock_ticket(chat_mode="live_chat")
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [mock_ticket]

        mock_queue_entry_result = MagicMock()
        mock_queue_entry_result.data = [{"created_at": "2024-12-30T12:00:00Z"}]

        mock_queue_count_result = MagicMock()
        mock_queue_count_result.count = 0

        mock_agents_result = MagicMock()
        mock_agents_result.count = 1

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_queue_entry_result
        mock_supabase.client.table.return_value.select.return_value.lt.return_value.execute.return_value = mock_queue_count_result

        response = client.post(
            f"/api/v1/live-chat/escalate/{MOCK_TICKET_ID}",
            json={
                "user_id": MOCK_USER_ID,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        # Should return current queue position without re-escalating

    def test_escalate_ticket_not_found(self, client, mock_supabase):
        """Test escalating non-existent ticket."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.post(
            "/api/v1/live-chat/escalate/nonexistent-ticket",
            json={
                "user_id": MOCK_USER_ID,
            }
        )

        assert response.status_code == 404


# =============================================================================
# Admin Presence Tests
# =============================================================================

class TestAdminPresence:
    """Tests for admin presence tracking."""

    def test_update_presence_online(
        self, client, mock_supabase_admin, mock_admin_token_verification
    ):
        """Test updating admin presence to online."""
        mock_db, _ = mock_supabase_admin

        mock_upsert_result = MagicMock()
        mock_upsert_result.data = [{}]

        mock_db.client.table.return_value.upsert.return_value.execute.return_value = mock_upsert_result

        response = client.post(
            "/api/v1/admin/presence",
            json={
                "is_online": True,
                "status_message": "Available",
            },
            headers={"Authorization": f"Bearer {MOCK_ACCESS_TOKEN}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["is_online"] is True

    def test_update_presence_offline(
        self, client, mock_supabase_admin, mock_admin_token_verification
    ):
        """Test updating admin presence to offline."""
        mock_db, _ = mock_supabase_admin

        mock_upsert_result = MagicMock()
        mock_upsert_result.data = [{}]

        mock_db.client.table.return_value.upsert.return_value.execute.return_value = mock_upsert_result

        response = client.post(
            "/api/v1/admin/presence",
            json={
                "is_online": False,
            },
            headers={"Authorization": f"Bearer {MOCK_ACCESS_TOKEN}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["is_online"] is False
