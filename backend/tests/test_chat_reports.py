"""
Tests for Chat Message Reporting API endpoints.

This module tests:
1. Submitting chat message reports
2. Report category validation
3. Getting user's own reports
4. Getting single report by ID
5. Gemini analysis integration
6. Activity logging for reports
7. Input validation and error handling

The chat reporting feature allows users to flag AI responses that are:
- inaccurate (factually incorrect fitness/nutrition advice)
- inappropriate (offensive or unprofessional content)
- unhelpful (didn't address the user's question)
- dangerous (potentially harmful fitness advice)
- other (catch-all for other issues)
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
import uuid


# Mock UUIDs for testing
MOCK_USER_ID = "test-user-abc-123"
MOCK_OTHER_USER_ID = "other-user-xyz-456"
MOCK_REPORT_ID = "report-id-789"
MOCK_MESSAGE_ID = "chat-message-id-001"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def mock_supabase():
    """Create a mock Supabase client for database operations."""
    with patch("api.v1.chat_reports.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_supabase_client():
    """Create a mock for direct Supabase client access."""
    with patch("api.v1.chat_reports.get_supabase") as mock:
        mock_client = MagicMock()
        mock.return_value.client = mock_client
        yield mock_client


@pytest.fixture
def mock_gemini_service():
    """Mock Gemini service for AI analysis of reports."""
    with patch("api.v1.chat_reports.gemini_service") as mock:
        # Mock the analyze_report method
        async def mock_analyze(message_content: str, report_category: str, reason: str = None):
            return {
                "severity": "medium",
                "analysis": "The reported message contains potentially inaccurate fitness advice.",
                "suggested_action": "review",
                "confidence": 0.85,
            }
        mock.analyze_chat_report = AsyncMock(side_effect=mock_analyze)
        yield mock


@pytest.fixture
def mock_activity_logger():
    """Mock activity logger for tracking report submissions."""
    with patch("api.v1.chat_reports.log_user_activity", new_callable=AsyncMock) as mock_activity:
        with patch("api.v1.chat_reports.log_user_error", new_callable=AsyncMock) as mock_error:
            yield mock_activity, mock_error


@pytest.fixture
def mock_user_context():
    """Mock user context service for event logging."""
    with patch("api.v1.chat_reports.user_context_service") as mock:
        mock.log_event = AsyncMock(return_value="event-id-123")
        yield mock


@pytest.fixture
def client():
    """Create a test client for the FastAPI application."""
    from main import app
    return TestClient(app)


# =============================================================================
# Helper Functions
# =============================================================================

def generate_mock_report(
    report_id: str = MOCK_REPORT_ID,
    user_id: str = MOCK_USER_ID,
    message_id: str = MOCK_MESSAGE_ID,
    category: str = "inaccurate",
    reason: str = None,
    status: str = "pending",
    ai_analysis: dict = None,
):
    """Generate a mock chat report response."""
    return {
        "id": report_id,
        "user_id": user_id,
        "message_id": message_id,
        "message_content": "This is the AI message that was reported.",
        "user_message": "What exercises help with lower back pain?",
        "category": category,
        "reason": reason,
        "status": status,
        "ai_analysis": ai_analysis,
        "reviewed_at": None,
        "reviewed_by": None,
        "resolution_notes": None,
        "created_at": "2024-12-30T12:00:00Z",
        "updated_at": "2024-12-30T12:00:00Z",
    }


def generate_mock_chat_message(
    message_id: str = MOCK_MESSAGE_ID,
    user_id: str = MOCK_USER_ID,
    user_message: str = "What exercises help with lower back pain?",
    ai_response: str = "Try heavy deadlifts without proper form!",
):
    """Generate a mock chat message from history."""
    return {
        "id": message_id,
        "user_id": user_id,
        "user_message": user_message,
        "ai_response": ai_response,
        "context_json": '{"intent": "question", "agent_type": "coach"}',
        "timestamp": "2024-12-30T11:55:00Z",
    }


# =============================================================================
# Test: Submit Chat Report - Success Cases
# =============================================================================

class TestSubmitChatReportSuccess:
    """Tests for successful POST /chat/reports submissions."""

    def test_submit_chat_report_success(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test successful chat report submission."""
        # Setup mocks
        mock_message = generate_mock_chat_message()
        mock_report = generate_mock_report()

        # Mock fetching the original chat message
        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]

        # Mock inserting the report
        mock_insert_result = MagicMock()
        mock_insert_result.data = [mock_report]

        # Chain mock calls
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        # Make request
        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
                "reason": "The advice about deadlifts is dangerous for someone with back pain.",
            }
        )

        # Verify
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == MOCK_REPORT_ID
        assert data["category"] == "inaccurate"
        assert data["status"] == "pending"
        assert data["message_id"] == MOCK_MESSAGE_ID

    def test_submit_chat_report_all_categories(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test submitting reports with all valid categories."""
        categories = ["inaccurate", "inappropriate", "unhelpful", "dangerous", "other"]

        for category in categories:
            # Setup mocks for each iteration
            mock_message = generate_mock_chat_message()
            mock_report = generate_mock_report(
                report_id=f"report-{category}",
                category=category
            )

            mock_message_result = MagicMock()
            mock_message_result.data = [mock_message]
            mock_insert_result = MagicMock()
            mock_insert_result.data = [mock_report]

            mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
            mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

            response = client.post(
                "/api/v1/chat/reports",
                json={
                    "user_id": MOCK_USER_ID,
                    "message_id": MOCK_MESSAGE_ID,
                    "category": category,
                }
            )

            assert response.status_code == 200, f"Failed for category: {category}"
            assert response.json()["category"] == category

    def test_submit_chat_report_with_reason(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test submitting a report with an optional reason text."""
        mock_message = generate_mock_chat_message()
        reason_text = "The AI suggested exercises that could worsen my condition."
        mock_report = generate_mock_report(reason=reason_text)

        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]
        mock_insert_result = MagicMock()
        mock_insert_result.data = [mock_report]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "dangerous",
                "reason": reason_text,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["reason"] == reason_text

    def test_submit_chat_report_without_reason(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test submitting a report without optional reason (should work)."""
        mock_message = generate_mock_chat_message()
        mock_report = generate_mock_report(reason=None)

        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]
        mock_insert_result = MagicMock()
        mock_insert_result.data = [mock_report]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "unhelpful",
                # No reason field
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["reason"] is None


# =============================================================================
# Test: Get User Reports
# =============================================================================

class TestGetUserReports:
    """Tests for GET /chat/reports/{user_id}"""

    def test_get_user_reports(self, client, mock_supabase, mock_supabase_client):
        """Test fetching a user's own reports."""
        mock_reports = [
            generate_mock_report("report-1", status="pending"),
            generate_mock_report("report-2", status="reviewed"),
            generate_mock_report("report-3", status="resolved"),
        ]

        mock_result = MagicMock()
        mock_result.data = mock_reports
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        assert data[0]["id"] == "report-1"

    def test_get_user_reports_empty(self, client, mock_supabase, mock_supabase_client):
        """Test fetching reports when user has none."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}")

        assert response.status_code == 200
        assert response.json() == []

    def test_get_user_reports_with_pagination(self, client, mock_supabase, mock_supabase_client):
        """Test pagination of user reports."""
        mock_reports = [generate_mock_report(f"report-{i}") for i in range(10, 20)]

        mock_result = MagicMock()
        mock_result.data = mock_reports
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}?limit=10&offset=10")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 10

    def test_get_user_reports_filter_by_status(self, client, mock_supabase, mock_supabase_client):
        """Test filtering reports by status."""
        mock_reports = [generate_mock_report("report-1", status="pending")]

        mock_result = MagicMock()
        mock_result.data = mock_reports
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}?status=pending")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["status"] == "pending"

    def test_get_user_reports_filter_by_category(self, client, mock_supabase, mock_supabase_client):
        """Test filtering reports by category."""
        mock_reports = [generate_mock_report("report-1", category="dangerous")]

        mock_result = MagicMock()
        mock_result.data = mock_reports
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}?category=dangerous")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["category"] == "dangerous"


# =============================================================================
# Test: Get Single Report
# =============================================================================

class TestGetSingleReport:
    """Tests for GET /chat/reports/{user_id}/{report_id}"""

    def test_get_single_report(self, client, mock_supabase, mock_supabase_client):
        """Test fetching a single report by ID."""
        mock_report = generate_mock_report(
            ai_analysis={
                "severity": "high",
                "analysis": "Dangerous fitness advice detected.",
                "suggested_action": "review",
            }
        )

        mock_result = MagicMock()
        mock_result.data = [mock_report]
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}/{MOCK_REPORT_ID}")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == MOCK_REPORT_ID
        assert data["ai_analysis"] is not None
        assert data["ai_analysis"]["severity"] == "high"

    def test_get_single_report_not_found(self, client, mock_supabase, mock_supabase_client):
        """Test getting a non-existent report returns 404."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}/nonexistent-report")

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()


# =============================================================================
# Test: Invalid Input Validation
# =============================================================================

class TestInputValidation:
    """Tests for request validation and error handling."""

    def test_report_invalid_category(self, client, mock_supabase):
        """Test that invalid category is rejected."""
        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "invalid_category",
            }
        )

        assert response.status_code == 422  # Validation error

    def test_report_missing_required_fields(self, client, mock_supabase):
        """Test that missing required fields are rejected."""
        # Missing user_id
        response = client.post(
            "/api/v1/chat/reports",
            json={
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
            }
        )
        assert response.status_code == 422

        # Missing message_id
        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "category": "inaccurate",
            }
        )
        assert response.status_code == 422

        # Missing category
        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
            }
        )
        assert response.status_code == 422

    def test_report_empty_user_id(self, client, mock_supabase):
        """Test that empty user_id is rejected."""
        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": "",
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
            }
        )

        assert response.status_code == 422

    def test_report_empty_message_id(self, client, mock_supabase):
        """Test that empty message_id is rejected."""
        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": "",
                "category": "inaccurate",
            }
        )

        assert response.status_code == 422

    def test_report_reason_too_long(self, client, mock_supabase):
        """Test that reason exceeding max length is rejected."""
        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
                "reason": "x" * 2001,  # Max is 2000
            }
        )

        assert response.status_code == 422


# =============================================================================
# Test: Message Not Found
# =============================================================================

class TestMessageNotFound:
    """Tests for reporting non-existent messages."""

    def test_report_nonexistent_message(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger
    ):
        """Test reporting a message that doesn't exist."""
        # Mock empty result for message lookup
        mock_message_result = MagicMock()
        mock_message_result.data = []
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": "nonexistent-message-id",
                "category": "inaccurate",
            }
        )

        assert response.status_code == 404
        assert "message" in response.json()["detail"].lower()


# =============================================================================
# Test: Gemini Analysis Integration
# =============================================================================

class TestGeminiAnalysis:
    """Tests for Gemini AI analysis of reported messages."""

    @pytest.mark.asyncio
    async def test_gemini_analysis_triggered(
        self, client, mock_supabase, mock_supabase_client, mock_gemini_service, mock_activity_logger
    ):
        """Test that Gemini analysis is triggered for dangerous reports."""
        mock_message = generate_mock_chat_message()
        mock_report = generate_mock_report(
            category="dangerous",
            ai_analysis={
                "severity": "high",
                "analysis": "The reported message contains potentially harmful advice.",
                "suggested_action": "immediate_review",
                "confidence": 0.92,
            }
        )

        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]
        mock_insert_result = MagicMock()
        mock_insert_result.data = [mock_report]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "dangerous",
                "reason": "This advice could cause injury.",
            }
        )

        assert response.status_code == 200
        # Verify Gemini was called
        mock_gemini_service.analyze_chat_report.assert_called_once()

    def test_gemini_analysis_failure_doesnt_fail_report(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger
    ):
        """Test that report submission succeeds even if Gemini analysis fails."""
        with patch("api.v1.chat_reports.gemini_service") as mock_gemini:
            # Make Gemini fail
            mock_gemini.analyze_chat_report = AsyncMock(
                side_effect=Exception("Gemini API error")
            )

            mock_message = generate_mock_chat_message()
            mock_report = generate_mock_report(ai_analysis=None)

            mock_message_result = MagicMock()
            mock_message_result.data = [mock_message]
            mock_insert_result = MagicMock()
            mock_insert_result.data = [mock_report]

            mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
            mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

            response = client.post(
                "/api/v1/chat/reports",
                json={
                    "user_id": MOCK_USER_ID,
                    "message_id": MOCK_MESSAGE_ID,
                    "category": "inaccurate",
                }
            )

            # Report should still succeed
            assert response.status_code == 200
            # AI analysis should be None
            assert response.json()["ai_analysis"] is None


# =============================================================================
# Test: Activity Logging
# =============================================================================

class TestActivityLogging:
    """Tests for activity logging on report actions."""

    def test_activity_logging_on_submit(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test that activity is logged when a report is submitted."""
        mock_activity, mock_error = mock_activity_logger

        mock_message = generate_mock_chat_message()
        mock_report = generate_mock_report()

        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]
        mock_insert_result = MagicMock()
        mock_insert_result.data = [mock_report]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
            }
        )

        assert response.status_code == 200

        # Verify activity was logged
        mock_activity.assert_called_once()
        call_args = mock_activity.call_args
        assert call_args.kwargs["user_id"] == MOCK_USER_ID
        assert call_args.kwargs["action"] == "chat_report"
        assert "category" in call_args.kwargs["metadata"]

    def test_error_logging_on_db_failure(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger
    ):
        """Test that errors are logged when database fails."""
        mock_activity, mock_error = mock_activity_logger

        # Make the message lookup succeed
        mock_message = generate_mock_chat_message()
        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]

        # Make the insert fail
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
        mock_supabase_client.table.return_value.insert.return_value.execute.side_effect = Exception("Database error")

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
            }
        )

        assert response.status_code == 500

        # Verify error was logged
        mock_error.assert_called_once()


# =============================================================================
# Test: RLS Security (User Isolation)
# =============================================================================

class TestRLSSecurity:
    """Tests for Row Level Security - ensuring users can only access their own reports."""

    def test_user_cannot_access_other_user_reports(self, client, mock_supabase, mock_supabase_client):
        """Test that RLS prevents accessing other users' reports."""
        # RLS would filter out other user's reports
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_OTHER_USER_ID}")

        assert response.status_code == 200
        assert response.json() == []

    def test_user_cannot_view_other_user_report(self, client, mock_supabase, mock_supabase_client):
        """Test that user cannot view a specific report belonging to another user."""
        mock_result = MagicMock()
        mock_result.data = []  # RLS prevents finding the report
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}/other-users-report")

        assert response.status_code == 404


# =============================================================================
# Test: Duplicate Report Prevention
# =============================================================================

class TestDuplicateReportPrevention:
    """Tests for preventing duplicate reports on the same message."""

    def test_duplicate_report_same_user(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test that a user cannot report the same message twice."""
        # First check for existing report
        mock_existing_result = MagicMock()
        mock_existing_result.data = [generate_mock_report()]  # Report already exists

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.eq.return_value.execute.return_value = mock_existing_result

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
            }
        )

        assert response.status_code == 409  # Conflict
        assert "already reported" in response.json()["detail"].lower()


# =============================================================================
# Test: Get Report Categories
# =============================================================================

class TestGetCategories:
    """Tests for GET /chat/reports/categories"""

    def test_get_available_categories(self, client):
        """Test getting available report categories."""
        response = client.get("/api/v1/chat/reports/categories")

        assert response.status_code == 200
        data = response.json()

        assert "categories" in data
        assert "statuses" in data

        # Verify all categories are present
        category_values = [c["value"] for c in data["categories"]]
        assert "inaccurate" in category_values
        assert "inappropriate" in category_values
        assert "unhelpful" in category_values
        assert "dangerous" in category_values
        assert "other" in category_values

        # Verify each category has description
        for category in data["categories"]:
            assert "value" in category
            assert "label" in category
            assert "description" in category


# =============================================================================
# Test: Edge Cases
# =============================================================================

class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_very_long_message_content(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test handling of very long message content in reports."""
        # Create a message with long content
        mock_message = generate_mock_chat_message(
            ai_response="x" * 10000  # Very long response
        )
        mock_report = generate_mock_report()

        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]
        mock_insert_result = MagicMock()
        mock_insert_result.data = [mock_report]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
            }
        )

        assert response.status_code == 200

    def test_special_characters_in_reason(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test handling special characters in reason text."""
        mock_message = generate_mock_chat_message()
        reason_with_special_chars = 'Test "reason" with <special> chars & unicode: \u00e9\u00e8'
        mock_report = generate_mock_report(reason=reason_with_special_chars)

        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]
        mock_insert_result = MagicMock()
        mock_insert_result.data = [mock_report]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
        mock_supabase_client.table.return_value.insert.return_value.execute.return_value = mock_insert_result

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "other",
                "reason": reason_with_special_chars,
            }
        )

        assert response.status_code == 200
        assert response.json()["reason"] == reason_with_special_chars

    def test_database_connection_error(
        self, client, mock_supabase_client, mock_activity_logger
    ):
        """Test graceful handling of database connection errors."""
        mock_activity, mock_error = mock_activity_logger

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.side_effect = Exception("Connection timeout")

        response = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
            }
        )

        assert response.status_code == 500

    def test_concurrent_report_submission(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test handling concurrent report submissions (race condition)."""
        # Simulate a race condition where two requests try to create a report
        # for the same message simultaneously
        mock_message = generate_mock_chat_message()
        mock_message_result = MagicMock()
        mock_message_result.data = [mock_message]

        # First call succeeds, second call fails with unique constraint violation
        call_count = 0
        def mock_insert(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                result = MagicMock()
                result.data = [generate_mock_report()]
                return result
            else:
                raise Exception("duplicate key value violates unique constraint")

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_message_result
        mock_supabase_client.table.return_value.insert.return_value.execute.side_effect = mock_insert

        # First request should succeed
        response1 = client.post(
            "/api/v1/chat/reports",
            json={
                "user_id": MOCK_USER_ID,
                "message_id": MOCK_MESSAGE_ID,
                "category": "inaccurate",
            }
        )
        assert response1.status_code == 200


# =============================================================================
# Test: Report Statistics
# =============================================================================

class TestReportStatistics:
    """Tests for report statistics endpoints."""

    def test_get_user_report_stats(self, client, mock_supabase, mock_supabase_client):
        """Test getting report statistics for a user."""
        mock_result = MagicMock()
        mock_result.data = [
            generate_mock_report("r1", status="pending", category="inaccurate"),
            generate_mock_report("r2", status="resolved", category="dangerous"),
            generate_mock_report("r3", status="reviewed", category="unhelpful"),
            generate_mock_report("r4", status="resolved", category="inaccurate"),
        ]
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["total_reports"] == 4
        assert data["pending_reports"] == 1
        assert data["resolved_reports"] == 2
        assert "category_breakdown" in data

    def test_get_user_report_stats_empty(self, client, mock_supabase, mock_supabase_client):
        """Test statistics when user has no reports."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["total_reports"] == 0
        assert data["pending_reports"] == 0


# =============================================================================
# Test: Withdraw Report
# =============================================================================

class TestWithdrawReport:
    """Tests for withdrawing/canceling a report."""

    def test_withdraw_pending_report(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger
    ):
        """Test withdrawing a pending report."""
        mock_report = generate_mock_report(status="pending")

        mock_select_result = MagicMock()
        mock_select_result.data = [mock_report]

        mock_update_result = MagicMock()
        mock_update_result.data = [{"id": MOCK_REPORT_ID, "status": "withdrawn"}]

        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_select_result
        mock_supabase_client.table.return_value.update.return_value.eq.return_value.execute.return_value = mock_update_result

        response = client.delete(
            f"/api/v1/chat/reports/{MOCK_USER_ID}/{MOCK_REPORT_ID}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["status"] == "withdrawn"

    def test_cannot_withdraw_resolved_report(
        self, client, mock_supabase, mock_supabase_client
    ):
        """Test that resolved reports cannot be withdrawn."""
        mock_report = generate_mock_report(status="resolved")

        mock_result = MagicMock()
        mock_result.data = [mock_report]
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.delete(
            f"/api/v1/chat/reports/{MOCK_USER_ID}/{MOCK_REPORT_ID}"
        )

        assert response.status_code == 400
        assert "cannot withdraw" in response.json()["detail"].lower()

    def test_withdraw_nonexistent_report(
        self, client, mock_supabase, mock_supabase_client
    ):
        """Test withdrawing a report that doesn't exist."""
        mock_result = MagicMock()
        mock_result.data = []
        mock_supabase_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = mock_result

        response = client.delete(
            f"/api/v1/chat/reports/{MOCK_USER_ID}/nonexistent-report"
        )

        assert response.status_code == 404
