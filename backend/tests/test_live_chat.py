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


HOW THESE TESTS TALK TO THE APP (updated — the endpoints moved, the guarantees did not)
---------------------------------------------------------------------------------------
Three things about the app changed underneath this file. None of the
guarantees asserted below changed, so every assertion is preserved verbatim;
only the *plumbing* was corrected.

1. ROUTE PREFIX. The user-facing live chat router was remounted from
   `/api/v1/live-chat/...` to `/api/v1/support/live-chat/...` (commit
   00400f9f). Requests to the old prefix 404. Paths updated.

2. MODULE SPLIT. `api.v1.live_chat` and `api.v1.admin.live_chat` were each
   split, with roughly half their endpoints moved into a `*_endpoints.py`
   sub-router (typing / read / end / messages / availability, and admin
   close / tickets / reports / dashboard / presence). Those sub-modules import
   `get_supabase_db` (and friends) into their OWN namespace, so patching only
   the parent module left the moved endpoints talking to the real database.
   Fixtures now patch both halves with the same fake.

3. AUTH IS A FastAPI DEPENDENCY. `Depends(get_current_user)` /
   `Depends(verify_admin_token)` capture the function object at import time, so
   `patch("...verify_admin_token")` cannot intercept them. Tests now use
   `app.dependency_overrides`, which is the supported seam.

The Supabase mocking was also rewritten from long `MagicMock` attribute chains
(`table.return_value.select.return_value.eq.return_value...`) to a small fake
query builder keyed by (table, operation). The chains were ambiguous — several
different queries in one endpoint share the same chain shape (e.g. the
dashboard issues seven distinct `support_tickets.select(count="exact")` calls),
so a single chain stub had to serve them all and silently handed back a
`MagicMock` where an `int` was required. The fake keys results by the table and
operation the production code actually performs, which is unambiguous.
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

# The live chat router is mounted under /support (api/v1/__init__.py).
LIVE_CHAT = "/api/v1/support/live-chat"
ADMIN = "/api/v1/admin"


# =============================================================================
# Fake Supabase query builder
#
# Mirrors the supabase-py surface the endpoints actually use:
#     db.client.table("t").select("...").eq(...).order(...).execute()
# Results are registered per (table, operation), which is how the production
# code is actually structured, so a stub can never be accidentally shared
# between two unrelated queries.
# =============================================================================

class FakeResult:
    """Stand-in for a supabase-py APIResponse."""

    def __init__(self, data=None, count=None):
        self.data = [] if data is None else data
        self.count = count if count is not None else len(self.data)


class FakeQuery:
    """Chainable stand-in for the supabase-py query builder.

    Every filter/order/limit/range call returns self; `execute()` hands back the
    result registered for this (table, operation).
    """

    def __init__(self, db, table: str, op: str):
        self._db = db
        self._table = table
        self._op = op

    @property
    def not_(self):
        # PostgREST negation is an attribute, not a call: .not_.is_(...)
        return self

    def __getattr__(self, name):
        # eq / neq / lt / gte / in_ / is_ / order / limit / range / single / ...
        def _chain(*args, **kwargs):
            return self
        return _chain

    def execute(self):
        return self._db._resolve(self._table, self._op)


class FakeTable:
    def __init__(self, db, name: str):
        self._db = db
        self._name = name

    def select(self, *args, **kwargs):
        return FakeQuery(self._db, self._name, "select")

    def insert(self, *args, **kwargs):
        return FakeQuery(self._db, self._name, "insert")

    def update(self, *args, **kwargs):
        return FakeQuery(self._db, self._name, "update")

    def delete(self, *args, **kwargs):
        return FakeQuery(self._db, self._name, "delete")

    def upsert(self, *args, **kwargs):
        return FakeQuery(self._db, self._name, "upsert")


class FakeSupabaseDB:
    """Stand-in for the object returned by `core.db.get_supabase_db()`."""

    def __init__(self):
        self._results = {}
        self.calls = []

    @property
    def client(self):
        return self

    def table(self, name: str) -> FakeTable:
        return FakeTable(self, name)

    def set(self, table: str, op: str, result):
        """Register the result of `table(table).<op>(...).execute()`.

        `result` may be a FakeResult, an Exception (raised on execute), or a
        list of either — consumed in order, with the last entry repeating.
        """
        self._results[(table, op)] = result

    def _resolve(self, table: str, op: str):
        self.calls.append((table, op))
        value = self._results.get((table, op))

        if value is None:
            return FakeResult(data=[], count=0)

        if isinstance(value, list):
            value = value.pop(0) if len(value) > 1 else value[0]

        if isinstance(value, Exception):
            raise value

        return value


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def mock_supabase():
    """Fake Supabase for the user-facing live chat endpoints.

    Patches BOTH halves of the split module (`live_chat` and
    `live_chat_endpoints`) with the same fake, so typing / read / end /
    availability hit the fake rather than the real database.
    """
    db = FakeSupabaseDB()
    with patch("api.v1.live_chat.get_supabase_db", return_value=db), \
         patch("api.v1.live_chat_endpoints.get_supabase_db", return_value=db):
        yield db


@pytest.fixture
def mock_supabase_admin():
    """Fake Supabase for the admin endpoints (both halves of the split module).

    Production calls `get_supabase().auth_client` for auth (the old
    `get_supabase_client` helper no longer exists), so the auth client is
    exposed through a manager stub.
    """
    db = FakeSupabaseDB()
    mock_auth_client = MagicMock()
    manager = MagicMock()
    manager.auth_client = mock_auth_client

    with patch("api.v1.admin.live_chat.get_supabase_db", return_value=db), \
         patch("api.v1.admin.live_chat_endpoints.get_supabase_db", return_value=db), \
         patch("api.v1.admin.live_chat.get_supabase", return_value=manager), \
         patch("api.v1.admin.live_chat_endpoints.get_supabase", return_value=manager):
        yield db, mock_auth_client


@pytest.fixture
def mock_user_context():
    """Mock user context service (patched in both halves of the split module)."""
    mock = MagicMock()
    mock.log_event = AsyncMock(return_value="event-id-123")
    with patch("api.v1.live_chat.user_context_service", mock), \
         patch("api.v1.live_chat_endpoints.user_context_service", mock):
        yield mock


@pytest.fixture
def mock_activity_logger():
    """Mock activity logger for live chat."""
    with patch("api.v1.live_chat.log_user_activity", new_callable=AsyncMock) as mock_activity:
        with patch("api.v1.live_chat.log_user_error", new_callable=AsyncMock) as mock_error:
            with patch("api.v1.live_chat_endpoints.log_user_activity", new_callable=AsyncMock), \
                 patch("api.v1.live_chat_endpoints.log_user_error", new_callable=AsyncMock):
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
def mock_webhook():
    """Silence the outbound admin webhook (Discord/email) by default.

    `_send_admin_webhook` is fire-and-forget I/O; the tests that assert on it
    patch it themselves.
    """
    with patch("api.v1.live_chat._send_admin_webhook", new_callable=AsyncMock) as mock:
        yield mock


@pytest.fixture
def mock_admin_token_verification():
    """Bypass admin authentication via FastAPI's dependency_overrides.

    `Depends(verify_admin_token)` binds the function object at import time, so
    monkeypatching the module attribute cannot intercept it. Both copies of the
    dependency (the parent module's and the sub-router's) are overridden.
    """
    from main import app
    from models.admin import AdminProfile, AdminRole
    from api.v1.admin.live_chat import verify_admin_token as verify_parent
    from api.v1.admin.live_chat_endpoints import verify_admin_token as verify_sub

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

    async def _override():
        return admin_profile

    app.dependency_overrides[verify_parent] = _override
    app.dependency_overrides[verify_sub] = _override
    try:
        yield admin_profile
    finally:
        app.dependency_overrides.pop(verify_parent, None)
        app.dependency_overrides.pop(verify_sub, None)


@pytest.fixture
def client():
    """Create a test client with the user auth dependency satisfied.

    The live chat endpoints authorize against the `user_id` in the request body
    (which is what these tests exercise); `get_current_user` only gates access
    to the route at all. Overriding it keeps the tests focused on live chat
    behavior instead of JWT plumbing. Admin routes do NOT use this dependency,
    so admin authorization is still genuinely exercised.
    """
    from main import app
    from core.auth import get_current_user

    async def _override_current_user():
        return {"id": MOCK_USER_ID}

    app.dependency_overrides[get_current_user] = _override_current_user
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


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


def _regular_user_role():
    """`_check_if_user_is_agent` reads users.role — a plain user is not an agent."""
    return FakeResult(data=[{"role": "user"}])


# =============================================================================
# Live Chat API Tests - Start Live Chat
# =============================================================================

class TestStartLiveChat:
    """Tests for POST /live-chat/start"""

    def test_start_live_chat_success(
        self, client, mock_supabase, mock_user_context, mock_activity_logger, mock_webhook
    ):
        """Test successfully starting a new live chat session."""
        # Setup mocks
        mock_supabase.set("support_tickets", "insert", FakeResult(data=[generate_mock_ticket()]))
        mock_supabase.set("live_chat_messages", "insert", FakeResult(data=[generate_mock_message()]))
        mock_supabase.set("live_chat_queue", "insert", FakeResult(data=[generate_mock_queue_entry()]))

        # Queue position: first select reads this ticket's queue entry, second
        # counts the entries ahead of it.
        mock_supabase.set("live_chat_queue", "select", [
            FakeResult(data=[{"created_at": "2024-12-30T12:00:00Z"}]),
            FakeResult(count=0),
        ])
        mock_supabase.set("admin_presence", "select", FakeResult(count=2))

        # Make request
        response = client.post(
            f"{LIVE_CHAT}/start",
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
        self, client, mock_supabase, mock_user_context, mock_activity_logger, mock_webhook
    ):
        """Test starting a live chat with AI escalation context."""
        ai_context = "User was asking about nutrition plans but AI couldn't provide specific calorie recommendations."

        mock_supabase.set("support_tickets", "insert", FakeResult(data=[generate_mock_ticket(
            escalated_from_ai=True,
            ai_handoff_context=ai_context,
        )]))
        mock_supabase.set("live_chat_messages", "insert", FakeResult(data=[generate_mock_message()]))
        mock_supabase.set("live_chat_queue", "insert", FakeResult(data=[generate_mock_queue_entry()]))
        mock_supabase.set("live_chat_queue", "select", [
            FakeResult(data=[{"created_at": "2024-12-30T12:00:00Z"}]),
            FakeResult(count=0),
        ])
        mock_supabase.set("admin_presence", "select", FakeResult(count=1))

        response = client.post(
            f"{LIVE_CHAT}/start",
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
        mock_supabase.set("support_tickets", "select", FakeResult(data=[generate_mock_ticket()]))
        mock_supabase.set("live_chat_queue", "select", [
            FakeResult(data=[{"created_at": "2024-12-30T12:00:00Z"}]),
            FakeResult(count=2),  # 2 people ahead
        ])
        mock_supabase.set("admin_presence", "select", FakeResult(count=3))

        response = client.get(
            f"{LIVE_CHAT}/queue-position/{MOCK_TICKET_ID}?user_id={MOCK_USER_ID}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["ticket_id"] == MOCK_TICKET_ID
        assert "queue_position" in data
        assert "status" in data

    def test_get_queue_position_not_found(self, client, mock_supabase):
        """Test getting queue position for non-existent ticket."""
        mock_supabase.set("support_tickets", "select", FakeResult(data=[]))

        response = client.get(
            f"{LIVE_CHAT}/queue-position/nonexistent-ticket?user_id={MOCK_USER_ID}"
        )

        assert response.status_code == 404


# =============================================================================
# Live Chat API Tests - Send Message
# =============================================================================

class TestSendMessage:
    """Tests for POST /live-chat/{ticket_id}/message"""

    def test_send_message(self, client, mock_supabase, mock_activity_logger, mock_webhook):
        """Test sending a message in active chat."""
        mock_supabase.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(status="in_progress", assigned_to=MOCK_AGENT_ID)]
        ))
        mock_supabase.set("users", "select", _regular_user_role())
        mock_supabase.set("live_chat_messages", "insert", FakeResult(data=[generate_mock_message()]))
        mock_supabase.set("support_tickets", "update", FakeResult(data=[{}]))
        mock_supabase.set("live_chat_queue", "update", FakeResult(data=[{}]))

        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/message",
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
        mock_supabase.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(status="closed")]
        ))

        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "Trying to send to closed chat",
            }
        )

        assert response.status_code == 400
        assert "closed" in response.json()["detail"].lower()

    def test_send_message_unauthorized(self, client, mock_supabase):
        """Test that user cannot send message to another user's chat."""
        mock_supabase.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(user_id=MOCK_OTHER_USER_ID)]
        ))
        mock_supabase.set("users", "select", _regular_user_role())

        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/message",
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
        mock_supabase.set("support_tickets", "select", FakeResult(data=[generate_mock_ticket()]))
        mock_supabase.set("users", "select", _regular_user_role())
        mock_supabase.set("live_chat_queue", "update", FakeResult(data=[{}]))

        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/typing",
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
        mock_supabase.set("support_tickets", "select", FakeResult(data=[generate_mock_ticket()]))
        mock_supabase.set("users", "select", _regular_user_role())
        mock_supabase.set("live_chat_queue", "update", FakeResult(data=[{}]))

        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/typing",
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
        mock_supabase.set("support_tickets", "select", FakeResult(data=[generate_mock_ticket()]))
        mock_supabase.set("users", "select", _regular_user_role())
        mock_supabase.set("live_chat_messages", "update", FakeResult(data=[{}]))

        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/read",
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
        mock_supabase.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(status="in_progress")]
        ))
        mock_supabase.set("users", "select", _regular_user_role())
        mock_supabase.set("live_chat_messages", "insert", FakeResult(data=[{}]))
        mock_supabase.set("support_tickets", "update", FakeResult(data=[{}]))
        mock_supabase.set("live_chat_queue", "delete", FakeResult(data=[]))

        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/end",
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
        mock_supabase.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(status="resolved")]
        ))
        mock_supabase.set("users", "select", _regular_user_role())

        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/end",
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
        mock_supabase.set("admin_presence", "select", FakeResult(count=3))
        mock_supabase.set("live_chat_queue", "select", FakeResult(count=2))

        response = client.get(f"{LIVE_CHAT}/availability")

        assert response.status_code == 200
        data = response.json()
        assert data["is_available"] is True
        assert data["agents_online_count"] > 0

    def test_check_availability_no_agents(self, client, mock_supabase):
        """Test checking availability when no agents are online."""
        mock_supabase.set("admin_presence", "select", FakeResult(count=0))
        mock_supabase.set("live_chat_queue", "select", FakeResult(count=0))

        response = client.get(f"{LIVE_CHAT}/availability")

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
        """Test successful admin login with valid credentials.

        `AdminLoginRequest.password` now enforces a complexity policy (min 12
        chars + upper/lower/digit/special — see the `SECURITY:` validator in
        models/admin.py), so the passwords below satisfy it. Anything weaker is
        rejected by request validation with a 422 before authentication is even
        attempted, which is a different guarantee than the one these tests
        protect (valid creds -> 200, wrong role -> 403, bad creds -> 401).
        """
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
        mock_db.set("users", "select", FakeResult(data=[generate_mock_admin_user()]))
        # Mock presence update
        mock_db.set("admin_presence", "upsert", FakeResult(data=[{}]))

        response = client.post(
            f"{ADMIN}/login",
            json={
                "email": "admin@example.com",
                "password": "Secure-Password-123!",
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
        mock_db.set("users", "select", FakeResult(
            data=[generate_mock_admin_user(user_id=MOCK_USER_ID, role="user")]
        ))

        response = client.post(
            f"{ADMIN}/login",
            json={
                "email": "user@example.com",
                "password": "User-Password-123!",
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
            f"{ADMIN}/login",
            json={
                "email": "admin@example.com",
                "password": "Wrong-Password-123!",
            }
        )

        assert response.status_code == 401


# =============================================================================
# Admin API Tests - Token Verification (regression gate)
# =============================================================================

class TestVerifyAdminToken:
    """Direct tests for the `verify_admin_token` dependency itself.

    REGRESSION GATE. The admin endpoints were split across two modules, and each
    got its OWN copy of `verify_admin_token`. The copy in
    `api/v1/admin/live_chat_endpoints.py` drifted from the `AdminProfile` model
    (passed `active_chats=`, which is not a field, and omitted the REQUIRED
    `created_at`), so it raised pydantic ValidationError on every call — which
    its broad `except Exception` converted into 401 "Authentication failed".
    Result: close-chat / tickets / reports / dashboard / presence were
    unreachable for every valid admin, in production.

    The endpoint tests below can't catch this because they override the
    dependency (that is the only way to stub a FastAPI `Depends`), so the
    dependency is exercised here directly — both copies, to prove they cannot
    drift apart again.
    """

    @staticmethod
    def _arrange(mock_db, mock_auth_client, role: str = "admin"):
        user = MagicMock()
        user.id = MOCK_ADMIN_USER_ID
        auth_response = MagicMock()
        auth_response.user = user
        mock_auth_client.auth.get_user.return_value = auth_response

        mock_db.set("users", "select", FakeResult(
            data=[generate_mock_admin_user(role=role)]
        ))
        mock_db.set("support_tickets", "select", FakeResult(count=4))

    @pytest.mark.asyncio
    async def test_verify_admin_token_returns_profile(self, mock_supabase_admin):
        """A valid admin token yields a populated AdminProfile (not a 401)."""
        from api.v1.admin.live_chat import verify_admin_token
        from models.admin import AdminProfile, AdminRole

        mock_db, mock_auth_client = mock_supabase_admin
        self._arrange(mock_db, mock_auth_client)

        profile = await verify_admin_token(authorization=f"Bearer {MOCK_ACCESS_TOKEN}")

        assert isinstance(profile, AdminProfile)
        assert profile.id == MOCK_ADMIN_USER_ID
        assert profile.email == "admin@example.com"
        assert profile.role == AdminRole.ADMIN
        assert profile.active_chats_count == 4

    @pytest.mark.asyncio
    async def test_verify_admin_token_sub_router_returns_profile(self, mock_supabase_admin):
        """The sub-router's dependency must behave identically to the canonical one.

        This is the exact assertion that was failing in production: it used to
        raise HTTPException(401) for a perfectly valid admin token.
        """
        from api.v1.admin.live_chat_endpoints import verify_admin_token
        from models.admin import AdminProfile, AdminRole

        mock_db, mock_auth_client = mock_supabase_admin
        self._arrange(mock_db, mock_auth_client)

        profile = await verify_admin_token(authorization=f"Bearer {MOCK_ACCESS_TOKEN}")

        assert isinstance(profile, AdminProfile)
        assert profile.id == MOCK_ADMIN_USER_ID
        assert profile.role == AdminRole.ADMIN
        assert profile.active_chats_count == 4

    @pytest.mark.asyncio
    async def test_verify_admin_token_rejects_non_admin(self, mock_supabase_admin):
        """A non-admin role is rejected with 403 by both copies."""
        from fastapi import HTTPException
        from api.v1.admin.live_chat import verify_admin_token as verify_parent
        from api.v1.admin.live_chat_endpoints import verify_admin_token as verify_sub

        mock_db, mock_auth_client = mock_supabase_admin

        for verify in (verify_parent, verify_sub):
            self._arrange(mock_db, mock_auth_client, role="user")

            with pytest.raises(HTTPException) as exc_info:
                await verify(authorization=f"Bearer {MOCK_ACCESS_TOKEN}")

            assert exc_info.value.status_code == 403


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

        # The endpoint runs the count query first, then the paginated list query.
        mock_db.set("support_tickets", "select", [
            FakeResult(count=2),
            FakeResult(data=mock_tickets, count=2),
        ])
        # Per ticket: unread count, then last-message preview.
        mock_db.set("live_chat_messages", "select", [
            FakeResult(count=1),
            FakeResult(data=[{"message": "Last message preview", "created_at": "2024-12-30T12:00:00Z"}]),
            FakeResult(count=1),
            FakeResult(data=[{"message": "Last message preview", "created_at": "2024-12-30T12:00:00Z"}]),
        ])
        # ticket-2 is unassigned + open, so it gets a queue-position lookup.
        mock_db.set("live_chat_queue", "select", [
            FakeResult(data=[{"created_at": "2024-12-30T12:00:00Z"}]),
            FakeResult(count=0),
        ])

        response = client.get(
            f"{ADMIN}/live-chats",
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

        mock_db.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(status="in_progress", assigned_to=MOCK_ADMIN_USER_ID)]
        ))
        mock_db.set("live_chat_messages", "insert", FakeResult(data=[generate_mock_message(
            sender_role="agent",
            sender_id=MOCK_ADMIN_USER_ID,
            message="Hello, how can I help you today?",
        )]))
        mock_db.set("support_tickets", "update", FakeResult(data=[{}]))
        mock_db.set("live_chat_queue", "update", FakeResult(data=[{}]))
        # Push notification looks up the recipient's FCM token on `users`.
        mock_db.set("users", "select", FakeResult(data=[{"fcm_token": "mock-fcm-token"}]))

        response = client.post(
            f"{ADMIN}/live-chats/{MOCK_TICKET_ID}/reply",
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

        mock_db.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(status="resolved")]
        ))

        response = client.post(
            f"{ADMIN}/live-chats/{MOCK_TICKET_ID}/reply",
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

        mock_db.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(status="open")]
        ))
        mock_db.set("support_tickets", "update", FakeResult(data=[{}]))
        mock_db.set("live_chat_queue", "delete", FakeResult(data=[]))
        mock_db.set("live_chat_messages", "insert", FakeResult(data=[{}]))
        mock_db.set("users", "select", FakeResult(data=[{
            **generate_mock_admin_user(user_id=MOCK_AGENT_ID, name="Support Agent"),
            "fcm_token": "mock-fcm-token",
        }]))

        response = client.post(
            f"{ADMIN}/live-chats/{MOCK_TICKET_ID}/assign",
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

        mock_db.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(status="in_progress", assigned_to=MOCK_ADMIN_USER_ID)]
        ))
        mock_db.set("live_chat_messages", "insert", FakeResult(data=[{}]))
        mock_db.set("support_tickets", "update", FakeResult(data=[{}]))
        mock_db.set("live_chat_queue", "delete", FakeResult(data=[]))
        mock_db.set("users", "select", FakeResult(data=[{"fcm_token": "mock-fcm-token"}]))

        response = client.post(
            f"{ADMIN}/live-chats/{MOCK_TICKET_ID}/close",
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

        # Every support_tickets read on the dashboard is a count query
        # (active / open / pending / resolved-today / started-today / per-agent).
        mock_db.set("support_tickets", "select", FakeResult(count=5))
        mock_db.set("live_chat_queue", "select", FakeResult(
            data=[
                {"created_at": "2024-12-30T11:50:00Z"},
                {"created_at": "2024-12-30T11:55:00Z"},
            ],
            count=2,
        ))
        mock_db.set("chat_message_reports", "select", FakeResult(count=5))
        mock_db.set("admin_presence", "select", FakeResult(data=[
            {"admin_id": MOCK_ADMIN_USER_ID, "is_online": True, "last_seen": "2024-12-30T12:00:00Z"}
        ]))
        # users: total-agent count query and the per-agent name lookup.
        mock_db.set("users", "select", FakeResult(data=[{"name": "Test Admin"}], count=3))

        response = client.get(
            f"{ADMIN}/dashboard",
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
            mock_supabase.set("support_tickets", "insert", FakeResult(data=[generate_mock_ticket()]))
            mock_supabase.set("live_chat_messages", "insert", FakeResult(data=[generate_mock_message()]))
            mock_supabase.set("live_chat_queue", "insert", FakeResult(data=[generate_mock_queue_entry()]))
            mock_supabase.set("live_chat_queue", "select", [
                FakeResult(data=[{"created_at": "2024-12-30T12:00:00Z"}]),
                FakeResult(count=0),
            ])
            mock_supabase.set("admin_presence", "select", FakeResult(count=2))

            response = client.post(
                f"{LIVE_CHAT}/start",
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
            mock_supabase.set("support_tickets", "select", FakeResult(
                data=[generate_mock_ticket(status="in_progress", assigned_to=MOCK_AGENT_ID)]
            ))
            mock_supabase.set("users", "select", _regular_user_role())
            mock_supabase.set("live_chat_messages", "insert", FakeResult(data=[generate_mock_message()]))
            mock_supabase.set("support_tickets", "update", FakeResult(data=[{}]))
            mock_supabase.set("live_chat_queue", "update", FakeResult(data=[{}]))

            response = client.post(
                f"{LIVE_CHAT}/{MOCK_TICKET_ID}/message",
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
        """Test that non-admin cannot access admin endpoints.

        NOTE: deliberately does NOT use `mock_admin_token_verification` — the
        real `verify_admin_token` dependency runs, so this genuinely exercises
        the rejection path.
        """
        mock_db, mock_auth_client = mock_supabase_admin

        # Mock failed token verification
        mock_auth_client.auth.get_user.return_value = None

        response = client.get(
            f"{ADMIN}/live-chats",
            headers={"Authorization": "Bearer invalid-token"}
        )

        assert response.status_code == 401

    def test_chat_not_found(self, client, mock_supabase):
        """Test handling of missing ticket."""
        mock_supabase.set("support_tickets", "select", FakeResult(data=[]))

        response = client.post(
            f"{LIVE_CHAT}/nonexistent-ticket/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "Hello?",
            }
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_already_ended_chat(self, client, mock_supabase):
        """Test that cannot send message to ended chat."""
        mock_supabase.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(status="resolved")]
        ))

        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/message",
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
            f"{LIVE_CHAT}/start",
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
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "",
            }
        )

        assert response.status_code == 422  # Validation error

    def test_message_too_long(self, client, mock_supabase):
        """Test that message exceeding max length is rejected."""
        response = client.post(
            f"{LIVE_CHAT}/{MOCK_TICKET_ID}/message",
            json={
                "user_id": MOCK_USER_ID,
                "message": "x" * 5001,  # Max is 5000
            }
        )

        assert response.status_code == 422  # Validation error

    def test_database_error_handling(self, client, mock_supabase, mock_activity_logger):
        """Test graceful handling of database errors."""
        mock_supabase.set("support_tickets", "insert", Exception("Database connection failed"))

        response = client.post(
            f"{LIVE_CHAT}/start",
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
        self, client, mock_supabase, mock_user_context, mock_activity_logger, mock_webhook
    ):
        """Test escalating an existing ticket to live chat."""
        mock_supabase.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(chat_mode="ticket")]  # Regular ticket
        ))
        mock_supabase.set("support_tickets", "update", FakeResult(data=[{}]))
        mock_supabase.set("live_chat_queue", "insert", FakeResult(data=[{}]))
        mock_supabase.set("live_chat_messages", "insert", FakeResult(data=[{}]))
        mock_supabase.set("live_chat_queue", "select", [
            FakeResult(data=[{"created_at": "2024-12-30T12:00:00Z"}]),
            FakeResult(count=0),
        ])
        mock_supabase.set("admin_presence", "select", FakeResult(count=1))

        response = client.post(
            f"{LIVE_CHAT}/escalate/{MOCK_TICKET_ID}",
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
        self, client, mock_supabase, mock_user_context, mock_activity_logger, mock_webhook
    ):
        """Test escalating a ticket that is already in live chat mode."""
        mock_supabase.set("support_tickets", "select", FakeResult(
            data=[generate_mock_ticket(chat_mode="live_chat")]
        ))
        mock_supabase.set("live_chat_queue", "select", [
            FakeResult(data=[{"created_at": "2024-12-30T12:00:00Z"}]),
            FakeResult(count=0),
        ])
        mock_supabase.set("admin_presence", "select", FakeResult(count=1))

        response = client.post(
            f"{LIVE_CHAT}/escalate/{MOCK_TICKET_ID}",
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
        mock_supabase.set("support_tickets", "select", FakeResult(data=[]))

        response = client.post(
            f"{LIVE_CHAT}/escalate/nonexistent-ticket",
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

        mock_db.set("admin_presence", "upsert", FakeResult(data=[{}]))

        response = client.post(
            f"{ADMIN}/presence",
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

        mock_db.set("admin_presence", "upsert", FakeResult(data=[{}]))

        response = client.post(
            f"{ADMIN}/presence",
            json={
                "is_online": False,
            },
            headers={"Authorization": f"Bearer {MOCK_ACCESS_TOKEN}"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["is_online"] is False
