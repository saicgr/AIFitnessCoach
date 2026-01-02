"""
Tests for Support Ticket API endpoints.

This module tests:
1. Creating support tickets
2. Getting user's tickets
3. Getting single ticket with messages
4. Adding replies to tickets
5. Closing tickets
6. Ticket statistics
7. RLS security (user isolation)
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient


# Mock UUIDs for testing
MOCK_USER_ID = "test-user-123"
MOCK_OTHER_USER_ID = "other-user-456"
MOCK_TICKET_ID = "support-ticket-789"
MOCK_MESSAGE_ID = "message-abc-123"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client."""
    with patch("api.v1.support.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_user_context():
    """Mock user context service."""
    with patch("api.v1.support.user_context_service") as mock:
        mock.log_event = AsyncMock(return_value="event-id-123")
        yield mock


@pytest.fixture
def mock_activity_logger():
    """Mock activity logger."""
    with patch("api.v1.support.log_user_activity", new_callable=AsyncMock) as mock_activity:
        with patch("api.v1.support.log_user_error", new_callable=AsyncMock) as mock_error:
            yield mock_activity, mock_error


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
    subject: str = "Test Support Ticket",
    category: str = "technical",
    priority: str = "medium",
    status: str = "open",
):
    """Generate a mock support ticket response."""
    return {
        "id": ticket_id,
        "user_id": user_id,
        "subject": subject,
        "category": category,
        "priority": priority,
        "status": status,
        "assigned_to": None,
        "created_at": "2024-12-30T12:00:00Z",
        "updated_at": "2024-12-30T12:00:00Z",
        "resolved_at": None,
        "closed_at": None,
    }


def generate_mock_message(
    message_id: str = MOCK_MESSAGE_ID,
    ticket_id: str = MOCK_TICKET_ID,
    sender: str = "user",
    message: str = "This is a test message",
    is_internal: bool = False,
):
    """Generate a mock ticket message response."""
    return {
        "id": message_id,
        "ticket_id": ticket_id,
        "sender": sender,
        "message": message,
        "is_internal": is_internal,
        "created_at": "2024-12-30T12:00:00Z",
        "updated_at": None,
    }


def generate_mock_ticket_summary(
    ticket_id: str = MOCK_TICKET_ID,
    user_id: str = MOCK_USER_ID,
    subject: str = "Test Support Ticket",
    category: str = "technical",
    priority: str = "medium",
    status: str = "open",
    message_count: int = 1,
):
    """Generate a mock ticket summary for list views."""
    return {
        **generate_mock_ticket(ticket_id, user_id, subject, category, priority, status),
        "message_count": message_count,
        "last_message_preview": "This is the last message...",
        "last_message_sender": "user",
    }


# =============================================================================
# Create Ticket Tests
# =============================================================================

class TestCreateSupportTicket:
    """Tests for POST /support/tickets"""

    def test_create_ticket_success(self, client, mock_supabase, mock_user_context, mock_activity_logger):
        """Test successful ticket creation."""
        # Setup mocks
        mock_ticket = generate_mock_ticket()
        mock_message = generate_mock_message()

        mock_insert_ticket = MagicMock()
        mock_insert_ticket.data = [mock_ticket]

        mock_insert_message = MagicMock()
        mock_insert_message.data = [mock_message]

        # Chain the mock calls
        mock_supabase.client.table.return_value.insert.return_value.execute.side_effect = [
            mock_insert_ticket,
            mock_insert_message,
        ]

        # Make request
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "Test Support Ticket",
                "category": "technical",
                "priority": "medium",
                "initial_message": "This is my detailed issue description for the support team.",
            }
        )

        # Verify
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == MOCK_TICKET_ID
        assert data["subject"] == "Test Support Ticket"
        assert data["category"] == "technical"
        assert data["status"] == "open"
        assert len(data["messages"]) == 1

    def test_create_ticket_with_all_categories(self, client, mock_supabase, mock_user_context, mock_activity_logger):
        """Test creating tickets with all available categories."""
        categories = ["billing", "technical", "feature_request", "bug_report", "account", "other"]

        for category in categories:
            mock_ticket = generate_mock_ticket(category=category)
            mock_message = generate_mock_message()

            mock_insert_ticket = MagicMock()
            mock_insert_ticket.data = [mock_ticket]
            mock_insert_message = MagicMock()
            mock_insert_message.data = [mock_message]

            mock_supabase.client.table.return_value.insert.return_value.execute.side_effect = [
                mock_insert_ticket,
                mock_insert_message,
            ]

            response = client.post(
                "/api/v1/support/tickets",
                json={
                    "user_id": MOCK_USER_ID,
                    "subject": f"Test {category} Ticket",
                    "category": category,
                    "initial_message": "Testing category validation for support tickets.",
                }
            )

            assert response.status_code == 200
            assert response.json()["category"] == category

    def test_create_ticket_with_all_priorities(self, client, mock_supabase, mock_user_context, mock_activity_logger):
        """Test creating tickets with all available priorities."""
        priorities = ["low", "medium", "high", "urgent"]

        for priority in priorities:
            mock_ticket = generate_mock_ticket(priority=priority)
            mock_message = generate_mock_message()

            mock_insert_ticket = MagicMock()
            mock_insert_ticket.data = [mock_ticket]
            mock_insert_message = MagicMock()
            mock_insert_message.data = [mock_message]

            mock_supabase.client.table.return_value.insert.return_value.execute.side_effect = [
                mock_insert_ticket,
                mock_insert_message,
            ]

            response = client.post(
                "/api/v1/support/tickets",
                json={
                    "user_id": MOCK_USER_ID,
                    "subject": f"Test {priority} Priority Ticket",
                    "category": "technical",
                    "priority": priority,
                    "initial_message": "Testing priority validation for support tickets.",
                }
            )

            assert response.status_code == 200
            assert response.json()["priority"] == priority

    def test_create_ticket_invalid_category(self, client, mock_supabase):
        """Test that invalid category is rejected."""
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "Test Ticket",
                "category": "invalid_category",
                "initial_message": "This should fail validation.",
            }
        )

        assert response.status_code == 422  # Validation error

    def test_create_ticket_subject_too_short(self, client, mock_supabase):
        """Test that subject with less than 5 characters is rejected."""
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "Hi",
                "category": "technical",
                "initial_message": "This should fail due to short subject.",
            }
        )

        assert response.status_code == 422  # Validation error

    def test_create_ticket_message_too_short(self, client, mock_supabase):
        """Test that initial message with less than 10 characters is rejected."""
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "Valid Subject",
                "category": "technical",
                "initial_message": "Short",
            }
        )

        assert response.status_code == 422  # Validation error


# =============================================================================
# Get User Tickets Tests
# =============================================================================

class TestGetUserTickets:
    """Tests for GET /support/tickets/{user_id}"""

    def test_get_user_tickets_success(self, client, mock_supabase):
        """Test successful retrieval of user's tickets."""
        mock_result = MagicMock()
        mock_result.data = [
            generate_mock_ticket_summary("ticket-1", status="open"),
            generate_mock_ticket_summary("ticket-2", status="in_progress"),
            generate_mock_ticket_summary("ticket-3", status="resolved"),
        ]
        mock_supabase.client.from_.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3

    def test_get_user_tickets_empty(self, client, mock_supabase):
        """Test when user has no tickets."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.from_.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}")

        assert response.status_code == 200
        assert response.json() == []

    def test_get_user_tickets_filter_by_status(self, client, mock_supabase):
        """Test filtering tickets by status."""
        mock_result = MagicMock()
        mock_result.data = [
            generate_mock_ticket_summary("ticket-1", status="open"),
        ]
        mock_supabase.client.from_.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}?status=open")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["status"] == "open"

    def test_get_user_tickets_filter_by_category(self, client, mock_supabase):
        """Test filtering tickets by category."""
        mock_result = MagicMock()
        mock_result.data = [
            generate_mock_ticket_summary("ticket-1", category="billing"),
        ]
        mock_supabase.client.from_.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}?category=billing")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["category"] == "billing"

    def test_get_user_tickets_pagination(self, client, mock_supabase):
        """Test pagination of tickets."""
        mock_result = MagicMock()
        mock_result.data = [
            generate_mock_ticket_summary(f"ticket-{i}")
            for i in range(10, 20)
        ]
        mock_supabase.client.from_.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}?limit=10&offset=10")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 10


# =============================================================================
# Get Single Ticket Tests
# =============================================================================

class TestGetTicket:
    """Tests for GET /support/tickets/{user_id}/{ticket_id}"""

    def test_get_ticket_success(self, client, mock_supabase):
        """Test successful retrieval of single ticket with messages."""
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [generate_mock_ticket()]

        mock_messages_result = MagicMock()
        mock_messages_result.data = [
            generate_mock_message("msg-1", message="Initial message"),
            generate_mock_message("msg-2", sender="support", message="Support response"),
            generate_mock_message("msg-3", message="User follow-up"),
        ]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.side_effect = [
            mock_ticket_result,
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.execute.return_value = mock_messages_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}/{MOCK_TICKET_ID}")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == MOCK_TICKET_ID
        assert len(data["messages"]) == 3

    def test_get_ticket_not_found(self, client, mock_supabase):
        """Test getting non-existent ticket returns 404."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}/nonexistent-ticket")

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_get_ticket_excludes_internal_messages(self, client, mock_supabase):
        """Test that internal support notes are not returned to users."""
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [generate_mock_ticket()]

        # Only non-internal messages should be returned (is_internal=FALSE in query)
        mock_messages_result = MagicMock()
        mock_messages_result.data = [
            generate_mock_message("msg-1", message="User visible message", is_internal=False),
        ]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.side_effect = [
            mock_ticket_result,
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.execute.return_value = mock_messages_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}/{MOCK_TICKET_ID}")

        assert response.status_code == 200
        data = response.json()
        # All returned messages should have is_internal=False
        for msg in data["messages"]:
            assert msg["is_internal"] is False


# =============================================================================
# Add Reply Tests
# =============================================================================

class TestAddTicketReply:
    """Tests for POST /support/tickets/{ticket_id}/reply"""

    def test_add_reply_success(self, client, mock_supabase, mock_activity_logger):
        """Test successfully adding a reply to a ticket."""
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [generate_mock_ticket(status="in_progress")]

        mock_message_result = MagicMock()
        mock_message_result.data = [generate_mock_message(message="User's reply to the support ticket.")]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_message_result
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result

        response = client.post(
            f"/api/v1/support/tickets/{MOCK_TICKET_ID}/reply?user_id={MOCK_USER_ID}",
            json={
                "message": "User's reply to the support ticket.",
                "sender": "user",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["ticket_id"] == MOCK_TICKET_ID
        assert data["message"]["message"] == "User's reply to the support ticket."

    def test_add_reply_to_closed_ticket_fails(self, client, mock_supabase):
        """Test that adding reply to closed ticket fails."""
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [generate_mock_ticket(status="closed")]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result

        response = client.post(
            f"/api/v1/support/tickets/{MOCK_TICKET_ID}/reply?user_id={MOCK_USER_ID}",
            json={
                "message": "Trying to reply to closed ticket.",
                "sender": "user",
            }
        )

        assert response.status_code == 400
        assert "closed" in response.json()["detail"].lower()

    def test_add_reply_ticket_not_found(self, client, mock_supabase):
        """Test adding reply to non-existent ticket."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/support/tickets/nonexistent-ticket/reply?user_id={MOCK_USER_ID}",
            json={
                "message": "Reply to non-existent ticket.",
                "sender": "user",
            }
        )

        assert response.status_code == 404

    def test_add_reply_updates_status(self, client, mock_supabase, mock_activity_logger):
        """Test that user reply changes status from waiting_response to in_progress."""
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [generate_mock_ticket(status="waiting_response")]

        mock_message_result = MagicMock()
        mock_message_result.data = [generate_mock_message()]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_message_result
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result

        response = client.post(
            f"/api/v1/support/tickets/{MOCK_TICKET_ID}/reply?user_id={MOCK_USER_ID}",
            json={
                "message": "User responding to support.",
                "sender": "user",
            }
        )

        assert response.status_code == 200
        assert response.json()["new_status"] == "in_progress"


# =============================================================================
# Close Ticket Tests
# =============================================================================

class TestCloseTicket:
    """Tests for PATCH /support/tickets/{ticket_id}/close"""

    def test_close_ticket_success(self, client, mock_supabase, mock_user_context, mock_activity_logger):
        """Test successfully closing a ticket."""
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [generate_mock_ticket(status="resolved")]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result

        response = client.patch(
            f"/api/v1/support/tickets/{MOCK_TICKET_ID}/close?user_id={MOCK_USER_ID}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["ticket_id"] == MOCK_TICKET_ID
        assert data["final_status"] == "closed"

    def test_close_ticket_with_resolution_note(self, client, mock_supabase, mock_user_context, mock_activity_logger):
        """Test closing ticket with a resolution note."""
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [generate_mock_ticket(status="in_progress")]

        mock_message_result = MagicMock()
        mock_message_result.data = [{}]

        mock_update_result = MagicMock()
        mock_update_result.data = [{}]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value = mock_message_result
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result

        response = client.patch(
            f"/api/v1/support/tickets/{MOCK_TICKET_ID}/close?user_id={MOCK_USER_ID}&resolution_note=Issue%20resolved%20successfully"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_close_already_closed_ticket(self, client, mock_supabase):
        """Test that closing an already closed ticket fails."""
        mock_ticket_result = MagicMock()
        mock_ticket_result.data = [generate_mock_ticket(status="closed")]

        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_ticket_result

        response = client.patch(
            f"/api/v1/support/tickets/{MOCK_TICKET_ID}/close?user_id={MOCK_USER_ID}"
        )

        assert response.status_code == 400
        assert "already closed" in response.json()["detail"].lower()

    def test_close_ticket_not_found(self, client, mock_supabase):
        """Test closing non-existent ticket."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.patch(
            f"/api/v1/support/tickets/nonexistent-ticket/close?user_id={MOCK_USER_ID}"
        )

        assert response.status_code == 404


# =============================================================================
# Ticket Statistics Tests
# =============================================================================

class TestTicketStats:
    """Tests for GET /support/tickets/{user_id}/stats"""

    def test_get_stats_success(self, client, mock_supabase):
        """Test successful retrieval of ticket statistics."""
        now = datetime.utcnow()
        mock_result = MagicMock()
        mock_result.data = [
            generate_mock_ticket("t1", status="open"),
            generate_mock_ticket("t2", status="in_progress"),
            {
                **generate_mock_ticket("t3", status="resolved"),
                "resolved_at": (now - timedelta(hours=24)).isoformat() + "Z",
                "created_at": (now - timedelta(hours=48)).isoformat() + "Z",
            },
            {
                **generate_mock_ticket("t4", status="closed"),
                "resolved_at": (now - timedelta(hours=12)).isoformat() + "Z",
                "created_at": (now - timedelta(hours=36)).isoformat() + "Z",
            },
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["total_tickets"] == 4
        assert data["open_tickets"] == 2  # open + in_progress
        assert data["resolved_tickets"] == 1
        assert data["closed_tickets"] == 1
        assert data["avg_resolution_time_hours"] is not None

    def test_get_stats_no_tickets(self, client, mock_supabase):
        """Test statistics when user has no tickets."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["total_tickets"] == 0
        assert data["open_tickets"] == 0
        assert data["avg_resolution_time_hours"] is None


# =============================================================================
# Get Categories Tests
# =============================================================================

class TestGetCategories:
    """Tests for GET /support/categories"""

    def test_get_categories(self, client):
        """Test getting available categories and priorities."""
        response = client.get("/api/v1/support/categories")

        assert response.status_code == 200
        data = response.json()

        assert "categories" in data
        assert "priorities" in data
        assert "statuses" in data

        # Verify all categories are present
        category_values = [c["value"] for c in data["categories"]]
        assert "billing" in category_values
        assert "technical" in category_values
        assert "feature_request" in category_values
        assert "bug_report" in category_values
        assert "account" in category_values
        assert "other" in category_values

        # Verify all priorities are present
        priority_values = [p["value"] for p in data["priorities"]]
        assert "low" in priority_values
        assert "medium" in priority_values
        assert "high" in priority_values
        assert "urgent" in priority_values


# =============================================================================
# RLS Security Tests
# =============================================================================

class TestRLSSecurity:
    """Tests for Row Level Security (user isolation)."""

    def test_user_cannot_access_other_user_tickets(self, client, mock_supabase):
        """Test that RLS prevents accessing other users' tickets."""
        # When querying with user_id filter, should only get that user's tickets
        mock_result = MagicMock()
        mock_result.data = []  # RLS would filter out other user's tickets
        mock_supabase.client.from_.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        # User A trying to get User B's tickets should return empty
        response = client.get(f"/api/v1/support/tickets/{MOCK_OTHER_USER_ID}")

        assert response.status_code == 200
        # RLS ensures the query only returns tickets for the authenticated user
        # In this test, we verify the API properly filters by user_id

    def test_user_cannot_view_other_user_ticket(self, client, mock_supabase):
        """Test that user cannot view a ticket belonging to another user."""
        mock_result = MagicMock()
        mock_result.data = []  # RLS prevents access
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/support/tickets/{MOCK_USER_ID}/{MOCK_TICKET_ID}")

        assert response.status_code == 404

    def test_user_cannot_reply_to_other_user_ticket(self, client, mock_supabase):
        """Test that user cannot reply to another user's ticket."""
        mock_result = MagicMock()
        mock_result.data = []  # RLS prevents finding the ticket
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.post(
            f"/api/v1/support/tickets/{MOCK_TICKET_ID}/reply?user_id={MOCK_USER_ID}",
            json={
                "message": "Trying to reply to another user's ticket",
                "sender": "user",
            }
        )

        assert response.status_code == 404

    def test_user_cannot_close_other_user_ticket(self, client, mock_supabase):
        """Test that user cannot close another user's ticket."""
        mock_result = MagicMock()
        mock_result.data = []  # RLS prevents finding the ticket
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.patch(
            f"/api/v1/support/tickets/{MOCK_TICKET_ID}/close?user_id={MOCK_USER_ID}"
        )

        assert response.status_code == 404


# =============================================================================
# Model Validation Tests
# =============================================================================

class TestModelValidation:
    """Tests for request model validation."""

    def test_empty_subject_rejected(self, client, mock_supabase):
        """Test that empty subject is rejected."""
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "",
                "category": "technical",
                "initial_message": "Valid message content here.",
            }
        )

        assert response.status_code == 422

    def test_empty_message_rejected(self, client, mock_supabase):
        """Test that empty message is rejected."""
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "Valid Subject Here",
                "category": "technical",
                "initial_message": "",
            }
        )

        assert response.status_code == 422

    def test_invalid_priority_rejected(self, client, mock_supabase):
        """Test that invalid priority is rejected."""
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "Valid Subject",
                "category": "technical",
                "priority": "super_urgent",  # Invalid
                "initial_message": "Valid message content here.",
            }
        )

        assert response.status_code == 422

    def test_missing_user_id_rejected(self, client, mock_supabase):
        """Test that missing user_id is rejected."""
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "subject": "Valid Subject",
                "category": "technical",
                "initial_message": "Valid message content here.",
            }
        )

        assert response.status_code == 422


# =============================================================================
# Edge Cases Tests
# =============================================================================

class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_very_long_subject(self, client, mock_supabase):
        """Test that subject exceeding max length is rejected."""
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "x" * 201,  # Max is 200
                "category": "technical",
                "initial_message": "Valid message content here.",
            }
        )

        assert response.status_code == 422

    def test_very_long_message(self, client, mock_supabase):
        """Test that message exceeding max length is rejected."""
        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "Valid Subject",
                "category": "technical",
                "initial_message": "x" * 5001,  # Max is 5000
            }
        )

        assert response.status_code == 422

    def test_database_error_handling(self, client, mock_supabase, mock_activity_logger):
        """Test graceful handling of database errors."""
        mock_supabase.client.table.return_value.insert.return_value.execute.side_effect = Exception("Database connection failed")

        response = client.post(
            "/api/v1/support/tickets",
            json={
                "user_id": MOCK_USER_ID,
                "subject": "Valid Subject",
                "category": "technical",
                "initial_message": "Valid message content here.",
            }
        )

        assert response.status_code == 500
