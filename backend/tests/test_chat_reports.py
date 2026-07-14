"""
Tests for Chat Message Reporting API endpoints (`api/v1/chat_reports.py`).

This module tests:
1. Submitting chat message reports          (POST /api/v1/chat/report)
2. Report category validation
3. Getting a user's own reports             (GET  /api/v1/chat/reports/{user_id})
4. Getting a single report by ID            (GET  /api/v1/chat/report/{report_id}?user_id=)
5. Gemini analysis integration              (BackgroundTasks -> analyze_reported_message)
6. Activity logging for reports
7. Input validation and error handling
8. Report statistics                        (GET  /api/v1/chat/reports/{user_id}/stats)
9. Report categories catalog                (GET  /api/v1/chat/categories)

--------------------------------------------------------------------------
WHY THIS FILE WAS REWRITTEN (2026-07-13)
--------------------------------------------------------------------------
Every test in this file previously asserted an API that has never existed.
It was written against an imagined contract:

    POST   /api/v1/chat/reports          {user_id, message_id, category, reason}
    GET    /api/v1/chat/reports/categories
    DELETE /api/v1/chat/reports/{user_id}/{report_id}   ("withdraw")
    categories: inaccurate | inappropriate | unhelpful | dangerous | other

The REAL contract — implemented in `api/v1/chat_reports.py` and matching the
deployed schema in `migrations/126_chat_message_reports.sql`, which is the
source of truth — is:

    POST   /api/v1/chat/report   {user_id, message_id, report_category,
                                  report_reason?, original_user_message,
                                  reported_ai_response}
           -> {success, report_id, message, status}
    GET    /api/v1/chat/reports/{user_id}          -> [ChatMessageReportSummary]
    GET    /api/v1/chat/report/{report_id}?user_id -> ChatMessageReport
    GET    /api/v1/chat/categories
    GET    /api/v1/chat/reports/{user_id}/stats
    report_category: wrong_advice | inappropriate | unhelpful
                     | outdated_info | other        (enforced by a DB CHECK)
    status:          pending | reviewed | resolved | dismissed  (DB CHECK)

Two other structural facts drove the rewrite:
  * The report is SELF-CONTAINED. The client snapshots the reported exchange
    into `original_user_message` / `reported_ai_response` (both NOT NULL on the
    report row). The endpoint therefore never looks the message up in
    chat_history, so there is no "message not found" 404 to assert.
  * Every endpoint is authenticated (`Depends(get_current_user)`) and enforces
    `current_user["id"] == user_id` with a 403. The old tests never
    authenticated at all, so the auth dependency was left unresolved.

Each test below keeps its ORIGINAL INTENT and asserts it against the real
contract; where the original intent describes something the product never
built (duplicate-report 409, withdraw/DELETE), the docstring says so
explicitly and the test now locks in the guarantee the product ACTUALLY makes.
No assertion was weakened or dropped.

The chat reporting feature allows users to flag AI responses that are:
- wrong_advice   (incorrect or potentially harmful fitness/health advice)
- inappropriate  (offensive or unprofessional content)
- unhelpful      (didn't address the user's question)
- outdated_info  (superseded fitness/health information)
- other          (catch-all for other issues)
"""
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient

from api.v1.chat_reports import ReportCategory, ReportStatus
from core.auth import get_current_user


# Mock IDs for testing
MOCK_USER_ID = "test-user-abc-123"
MOCK_OTHER_USER_ID = "other-user-xyz-456"
MOCK_REPORT_ID = "report-id-789"
MOCK_MESSAGE_ID = "chat-message-id-001"

# The real, DB-enforced category set (migrations/126_chat_message_reports.sql)
ALL_CATEGORIES = ["wrong_advice", "inappropriate", "unhelpful", "outdated_info", "other"]

MOCK_USER_MESSAGE = "What exercises help with lower back pain?"
MOCK_AI_RESPONSE = "Try heavy deadlifts without proper form!"


# =============================================================================
# Fixtures
# =============================================================================

@pytest.fixture
def mock_supabase():
    """Mock the Supabase DB handle used by chat_reports.

    Patches `get_supabase_db` — the name chat_reports actually imports (from
    core.db). The previous version of this fixture patched
    `api.v1.chat_reports.get_supabase` which does not exist in the module, so
    every test that used it errored out at fixture setup.
    """
    with patch("api.v1.chat_reports.get_supabase_db") as mock:
        mock_db = MagicMock()
        mock.return_value = mock_db
        yield mock_db


@pytest.fixture
def mock_supabase_client(mock_supabase):
    """The `.client` attribute of the mocked DB handle (the postgrest client)."""
    return mock_supabase.client


@pytest.fixture
def mock_gemini_service():
    """Mock the Gemini service used by the post-report background analysis.

    chat_reports calls `get_gemini_service()` inside `analyze_reported_message`
    and then `await gemini.chat(user_message=..., system_prompt=...)`.
    TestClient runs BackgroundTasks synchronously after the response, so
    without this patch a report submission would make a LIVE Gemini call.
    """
    gemini = MagicMock()
    gemini.chat = AsyncMock(return_value="This response recommends heavy loading without technique cues.")
    with patch("api.v1.chat_reports.get_gemini_service", return_value=gemini):
        yield gemini


@pytest.fixture
def mock_activity_logger():
    """Mock activity logger for tracking report submissions."""
    with patch("api.v1.chat_reports.log_user_activity", new_callable=AsyncMock) as mock_activity:
        with patch("api.v1.chat_reports.log_user_error", new_callable=AsyncMock) as mock_error:
            yield mock_activity, mock_error


@pytest.fixture
def client():
    """Test client authenticated as MOCK_USER_ID.

    Every chat-report endpoint depends on `get_current_user` and 403s unless
    the authenticated id matches the `user_id` in the request, so the
    dependency must be overridden for any of these tests to reach the handler.
    """
    from main import app

    app.dependency_overrides[get_current_user] = lambda: {
        "id": MOCK_USER_ID,
        "email": "test@example.com",
    }
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.pop(get_current_user, None)


# =============================================================================
# Helper Functions
# =============================================================================

def report_payload(
    user_id: str = MOCK_USER_ID,
    message_id: str = MOCK_MESSAGE_ID,
    category: str = "wrong_advice",
    reason: str = None,
    original_user_message: str = MOCK_USER_MESSAGE,
    ai_response: str = MOCK_AI_RESPONSE,
):
    """Build a valid POST /api/v1/chat/report body."""
    return {
        "user_id": user_id,
        "message_id": message_id,
        "report_category": category,
        "report_reason": reason,
        "original_user_message": original_user_message,
        "reported_ai_response": ai_response,
    }


def generate_mock_report(
    report_id: str = MOCK_REPORT_ID,
    user_id: str = MOCK_USER_ID,
    message_id: str = MOCK_MESSAGE_ID,
    category: str = "wrong_advice",
    reason: str = None,
    status: str = "pending",
    ai_analysis: str = None,
    original_user_message: str = MOCK_USER_MESSAGE,
    reported_ai_response: str = MOCK_AI_RESPONSE,
):
    """Generate a mock `chat_message_reports` row (matches migration 126)."""
    return {
        "id": report_id,
        "user_id": user_id,
        "message_id": message_id,
        "report_category": category,
        "report_reason": reason,
        "original_user_message": original_user_message,
        "reported_ai_response": reported_ai_response,
        "ai_analysis": ai_analysis,
        "status": status,
        "resolution_note": None,
        "reviewed_at": None,
        "reviewed_by": None,
        "created_at": "2024-12-30T12:00:00Z",
        "updated_at": "2024-12-30T12:00:00Z",
    }


def stub_insert(mock_client, row):
    """Stub `table(...).insert(...).execute()` to return `row`."""
    result = MagicMock()
    result.data = [row]
    mock_client.table.return_value.insert.return_value.execute.return_value = result
    return result


def inserted_row(mock_client):
    """The dict that was passed to `.insert(...)`."""
    return mock_client.table.return_value.insert.call_args.args[0]


def stub_select_eq_eq(mock_client, rows):
    """Stub `table().select().eq().eq().execute()` (single-report lookup)."""
    result = MagicMock()
    result.data = rows
    mock_client.table.return_value.select.return_value.eq.return_value.eq.return_value.execute.return_value = result
    return result


def stub_list_query(mock_client, rows):
    """Stub `table().select().eq()...order().range().execute()` (report list).

    `.eq()` returns the same mock, so this covers the extra `.eq()` calls added
    by the optional status/category filters as well.
    """
    result = MagicMock()
    result.data = rows
    chain = mock_client.table.return_value.select.return_value.eq.return_value
    chain.eq.return_value = chain
    chain.order.return_value.range.return_value.execute.return_value = result
    return result


def stub_stats_query(mock_client, rows):
    """Stub `table().select().eq().execute()` (stats query)."""
    result = MagicMock()
    result.data = rows
    mock_client.table.return_value.select.return_value.eq.return_value.execute.return_value = result
    return result


# =============================================================================
# Test: Submit Chat Report - Success Cases
# =============================================================================

class TestSubmitChatReportSuccess:
    """Tests for successful POST /api/v1/chat/report submissions."""

    def test_submit_chat_report_success(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test successful chat report submission.

        Path changed from the never-existing POST /chat/reports to the real
        POST /chat/report. The endpoint returns a ChatMessageReportResponse
        ({success, report_id, message, status}), not the stored row.
        """
        stub_insert(mock_supabase_client, generate_mock_report())

        response = client.post(
            "/api/v1/chat/report",
            json=report_payload(
                reason="The advice about deadlifts is dangerous for someone with back pain.",
            ),
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["report_id"] == MOCK_REPORT_ID
        assert data["status"] == "pending"

        # The row persisted must carry the reported exchange verbatim.
        row = inserted_row(mock_supabase_client)
        assert row["user_id"] == MOCK_USER_ID
        assert row["message_id"] == MOCK_MESSAGE_ID
        assert row["report_category"] == "wrong_advice"
        assert row["original_user_message"] == MOCK_USER_MESSAGE
        assert row["reported_ai_response"] == MOCK_AI_RESPONSE
        assert row["status"] == "pending"

    def test_submit_chat_report_all_categories(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test submitting reports with all valid categories.

        Category set corrected to the DB-enforced one (migration 126 CHECK):
        wrong_advice / inappropriate / unhelpful / outdated_info / other.
        The old list (inaccurate, dangerous) would be rejected by Postgres.
        """
        for category in ALL_CATEGORIES:
            stub_insert(
                mock_supabase_client,
                generate_mock_report(report_id=f"report-{category}", category=category),
            )

            response = client.post(
                "/api/v1/chat/report",
                json=report_payload(category=category),
            )

            assert response.status_code == 200, f"Failed for category: {category}"
            assert response.json()["report_id"] == f"report-{category}"
            assert inserted_row(mock_supabase_client)["report_category"] == category

    def test_submit_chat_report_with_reason(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test submitting a report with an optional reason text.

        The response no longer echoes the reason, so the assertion moved to the
        row handed to the DB — a strictly closer check on the same guarantee:
        the user's free-text reason is persisted.
        """
        reason_text = "The AI suggested exercises that could worsen my condition."
        stub_insert(mock_supabase_client, generate_mock_report(reason=reason_text))

        response = client.post(
            "/api/v1/chat/report",
            json=report_payload(category="wrong_advice", reason=reason_text),
        )

        assert response.status_code == 200
        assert inserted_row(mock_supabase_client)["report_reason"] == reason_text

    def test_submit_chat_report_without_reason(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test submitting a report without optional reason (should work)."""
        stub_insert(mock_supabase_client, generate_mock_report(reason=None))

        payload = report_payload(category="unhelpful")
        payload.pop("report_reason")  # field omitted entirely

        response = client.post("/api/v1/chat/report", json=payload)

        assert response.status_code == 200
        assert response.json()["success"] is True
        assert inserted_row(mock_supabase_client)["report_reason"] is None


# =============================================================================
# Test: Get User Reports
# =============================================================================

class TestGetUserReports:
    """Tests for GET /api/v1/chat/reports/{user_id}"""

    def test_get_user_reports(self, client, mock_supabase, mock_supabase_client):
        """Test fetching a user's own reports.

        The endpoint returns ChatMessageReportSummary objects (id, message_id,
        report_category, status, created_at, preview, has_ai_analysis).
        """
        stub_list_query(mock_supabase_client, [
            generate_mock_report("report-1", status="pending"),
            generate_mock_report("report-2", status="reviewed"),
            generate_mock_report("report-3", status="resolved", ai_analysis="Analysis text"),
        ])

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        assert data[0]["id"] == "report-1"
        assert data[0]["status"] == "pending"
        assert data[0]["original_user_message_preview"] == MOCK_USER_MESSAGE
        assert data[0]["has_ai_analysis"] is False
        assert data[2]["has_ai_analysis"] is True

    def test_get_user_reports_empty(self, client, mock_supabase, mock_supabase_client):
        """Test fetching reports when user has none."""
        stub_list_query(mock_supabase_client, [])

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}")

        assert response.status_code == 200
        assert response.json() == []

    def test_get_user_reports_with_pagination(self, client, mock_supabase, mock_supabase_client):
        """Test pagination of user reports."""
        stub_list_query(
            mock_supabase_client,
            [generate_mock_report(f"report-{i}") for i in range(10, 20)],
        )

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}?limit=10&offset=10")

        assert response.status_code == 200
        assert len(response.json()) == 10

        # limit/offset must translate to a half-open postgrest range [10, 19].
        chain = mock_supabase_client.table.return_value.select.return_value.eq.return_value
        chain.order.return_value.range.assert_called_once_with(10, 19)

    def test_get_user_reports_filter_by_status(self, client, mock_supabase, mock_supabase_client):
        """Test filtering reports by status."""
        stub_list_query(mock_supabase_client, [generate_mock_report("report-1", status="pending")])

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}?status=pending")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["status"] == "pending"

        # The filter must be pushed down to the query, not applied in Python.
        chain = mock_supabase_client.table.return_value.select.return_value.eq.return_value
        chain.eq.assert_any_call("status", "pending")

    def test_get_user_reports_filter_by_category(self, client, mock_supabase, mock_supabase_client):
        """Test filtering reports by category."""
        stub_list_query(
            mock_supabase_client,
            [generate_mock_report("report-1", category="wrong_advice")],
        )

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}?category=wrong_advice")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["report_category"] == "wrong_advice"

        chain = mock_supabase_client.table.return_value.select.return_value.eq.return_value
        chain.eq.assert_any_call("report_category", "wrong_advice")


# =============================================================================
# Test: Get Single Report
# =============================================================================

class TestGetSingleReport:
    """Tests for GET /api/v1/chat/report/{report_id}?user_id=..."""

    def test_get_single_report(self, client, mock_supabase, mock_supabase_client):
        """Test fetching a single report by ID.

        `ai_analysis` is a free-text string produced by Gemini (TEXT column in
        migration 126), not the {severity, suggested_action, ...} dict the old
        test imagined.
        """
        analysis = "Dangerous fitness advice detected: heavy loading with no technique cues."
        stub_select_eq_eq(mock_supabase_client, [generate_mock_report(ai_analysis=analysis)])

        response = client.get(
            f"/api/v1/chat/report/{MOCK_REPORT_ID}", params={"user_id": MOCK_USER_ID}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == MOCK_REPORT_ID
        assert data["ai_analysis"] == analysis
        assert data["report_category"] == "wrong_advice"
        assert data["status"] == "pending"

    def test_get_single_report_not_found(self, client, mock_supabase, mock_supabase_client):
        """Test getting a non-existent report returns 404."""
        stub_select_eq_eq(mock_supabase_client, [])

        response = client.get(
            "/api/v1/chat/report/nonexistent-report", params={"user_id": MOCK_USER_ID}
        )

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
            "/api/v1/chat/report",
            json=report_payload(category="invalid_category"),
        )

        assert response.status_code == 422  # Validation error

    def test_report_missing_required_fields(self, client, mock_supabase):
        """Test that missing required fields are rejected.

        Extended to cover every required field of ChatMessageReportCreate —
        including original_user_message / reported_ai_response, which are
        NOT NULL on the table and carry the whole evidentiary payload.
        """
        for missing in (
            "user_id",
            "message_id",
            "report_category",
            "original_user_message",
            "reported_ai_response",
        ):
            payload = report_payload()
            payload.pop(missing)
            response = client.post("/api/v1/chat/report", json=payload)
            assert response.status_code == 422, f"missing {missing} should be rejected"

    def test_report_empty_user_id(self, client, mock_supabase):
        """Test that empty user_id is rejected."""
        response = client.post("/api/v1/chat/report", json=report_payload(user_id=""))

        assert response.status_code == 422

    def test_report_empty_message_id(self, client, mock_supabase):
        """Test that empty message_id is rejected.

        An empty message_id produces an orphan report that can never be traced
        back to the exchange it flags. Production was missing the `min_length=1`
        bound the rest of the codebase applies to required id fields; it was
        added to ChatMessageReportCreate rather than relaxing this test.
        """
        response = client.post("/api/v1/chat/report", json=report_payload(message_id=""))

        assert response.status_code == 422

    def test_report_reason_too_long(self, client, mock_supabase):
        """Test that reason exceeding max length is rejected.

        The real bound is 1000 chars (ChatMessageReportCreate.report_reason),
        not the 2000 the old comment claimed.
        """
        response = client.post(
            "/api/v1/chat/report",
            json=report_payload(reason="x" * 1001),
        )

        assert response.status_code == 422


# =============================================================================
# Test: Reports Are Self-Contained (no chat_history lookup)
# =============================================================================

class TestMessageNotFound:
    """Tests for reporting a message that is not (or no longer) in chat history.

    ORIGINAL INTENT: reporting a message that doesn't exist -> 404.
    That contract was never built and is contradicted by the schema: a report
    row stores `original_user_message` and `reported_ai_response` as NOT NULL
    columns (migration 126), i.e. the client snapshots the exchange into the
    report. The endpoint deliberately never reads chat_history.

    The guarantee that actually protects users is the inverse one, asserted
    below: a report must NOT be lost just because the referenced message row
    can't be found (unsent/streamed/deleted/purged message). If someone later
    adds a chat_history existence check, this test fires and forces the
    conversation about silently dropping user feedback.
    """

    def test_report_nonexistent_message(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """A report for an unknown message_id is still accepted and stored."""
        stub_insert(
            mock_supabase_client,
            generate_mock_report(message_id="nonexistent-message-id"),
        )

        response = client.post(
            "/api/v1/chat/report",
            json=report_payload(message_id="nonexistent-message-id"),
        )

        assert response.status_code == 200
        assert response.json()["success"] is True

        # No chat_history lookup happened; the snapshot came from the client.
        tables = [c.args[0] for c in mock_supabase_client.table.call_args_list]
        assert "chat_history" not in tables
        row = inserted_row(mock_supabase_client)
        assert row["message_id"] == "nonexistent-message-id"
        assert row["reported_ai_response"] == MOCK_AI_RESPONSE


# =============================================================================
# Test: Gemini Analysis Integration
# =============================================================================

class TestGeminiAnalysis:
    """Tests for Gemini AI analysis of reported messages."""

    def test_gemini_analysis_triggered(
        self, client, mock_supabase, mock_supabase_client, mock_gemini_service, mock_activity_logger
    ):
        """Test that Gemini analysis is triggered for a submitted report.

        Analysis runs in a BackgroundTask (`analyze_reported_message`), which
        TestClient executes synchronously after the response. The test is no
        longer `async def`: TestClient cannot be driven from inside a running
        event loop, which is why the original never actually exercised this.
        """
        stub_insert(mock_supabase_client, generate_mock_report(category="wrong_advice"))

        response = client.post(
            "/api/v1/chat/report",
            json=report_payload(category="wrong_advice", reason="This advice could cause injury."),
        )

        assert response.status_code == 200

        # Verify Gemini was called with the reported exchange.
        mock_gemini_service.chat.assert_called_once()
        prompt = mock_gemini_service.chat.call_args.kwargs["user_message"]
        assert MOCK_AI_RESPONSE in prompt
        assert "wrong_advice" in prompt
        assert "This advice could cause injury." in prompt

        # ...and that the analysis was written back onto the report row.
        update_payload = mock_supabase_client.table.return_value.update.call_args.args[0]
        assert update_payload["ai_analysis"] == mock_gemini_service.chat.return_value

    def test_gemini_analysis_failure_doesnt_fail_report(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger
    ):
        """Test that report submission succeeds even if Gemini analysis fails."""
        gemini = MagicMock()
        gemini.chat = AsyncMock(side_effect=Exception("Gemini API error"))

        with patch("api.v1.chat_reports.get_gemini_service", return_value=gemini):
            stub_insert(mock_supabase_client, generate_mock_report(ai_analysis=None))

            response = client.post("/api/v1/chat/report", json=report_payload())

            # Report should still succeed (analysis is best-effort, in background)
            assert response.status_code == 200
            assert response.json()["success"] is True
            assert response.json()["status"] == "pending"

        # No ai_analysis was written, and the failure did not corrupt the row.
        gemini.chat.assert_awaited_once()
        assert mock_supabase_client.table.return_value.update.called is False


# =============================================================================
# Test: Activity Logging
# =============================================================================

class TestActivityLogging:
    """Tests for activity logging on report actions."""

    def test_activity_logging_on_submit(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test that activity is logged when a report is submitted.

        The action string is "chat_report_submitted" (production), not
        "chat_report".
        """
        mock_activity, mock_error = mock_activity_logger
        stub_insert(mock_supabase_client, generate_mock_report())

        response = client.post("/api/v1/chat/report", json=report_payload())

        assert response.status_code == 200

        mock_activity.assert_called_once()
        call_args = mock_activity.call_args
        assert call_args.kwargs["user_id"] == MOCK_USER_ID
        assert call_args.kwargs["action"] == "chat_report_submitted"
        assert call_args.kwargs["metadata"]["category"] == "wrong_advice"
        assert call_args.kwargs["metadata"]["report_id"] == MOCK_REPORT_ID
        assert mock_error.called is False

    def test_error_logging_on_db_failure(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger
    ):
        """Test that errors are logged when database fails."""
        mock_activity, mock_error = mock_activity_logger

        mock_supabase_client.table.return_value.insert.return_value.execute.side_effect = Exception(
            "Database error"
        )

        response = client.post("/api/v1/chat/report", json=report_payload())

        assert response.status_code == 500

        mock_error.assert_called_once()
        assert mock_error.call_args.kwargs["user_id"] == MOCK_USER_ID
        assert mock_error.call_args.kwargs["action"] == "chat_report_submitted"


# =============================================================================
# Test: User Isolation (API-level enforcement of the RLS intent)
# =============================================================================

class TestRLSSecurity:
    """Tests that users can only access their own reports.

    Migration 126's RLS policies scope SELECT/INSERT to `auth.uid() = user_id`.
    The backend uses the service key, so the same isolation is enforced in the
    API layer: each endpoint compares the authenticated user to the requested
    user_id and 403s on mismatch. The old tests asserted an empty 200 body;
    the real behavior is a hard 403 — strictly stronger, so the assertions were
    tightened rather than relaxed.
    """

    def test_user_cannot_access_other_user_reports(self, client, mock_supabase, mock_supabase_client):
        """A user requesting someone else's report list is denied."""
        stub_list_query(mock_supabase_client, [generate_mock_report(user_id=MOCK_OTHER_USER_ID)])

        response = client.get(f"/api/v1/chat/reports/{MOCK_OTHER_USER_ID}")

        assert response.status_code == 403
        assert response.json()["detail"] == "Access denied"
        # The DB must never even be queried for another user's rows.
        assert mock_supabase_client.table.called is False

    def test_user_cannot_view_other_user_report(self, client, mock_supabase, mock_supabase_client):
        """A user cannot view a specific report belonging to another user."""
        # Someone else's user_id in the query string -> hard 403.
        response = client.get(
            f"/api/v1/chat/report/{MOCK_REPORT_ID}", params={"user_id": MOCK_OTHER_USER_ID}
        )
        assert response.status_code == 403

        # Their own user_id but a report id they don't own -> the user_id filter
        # in the query means no row comes back -> 404, never another user's row.
        stub_select_eq_eq(mock_supabase_client, [])
        response = client.get(
            "/api/v1/chat/report/other-users-report", params={"user_id": MOCK_USER_ID}
        )
        assert response.status_code == 404

        select = mock_supabase_client.table.return_value.select.return_value
        select.eq.assert_called_once_with("id", "other-users-report")
        select.eq.return_value.eq.assert_called_once_with("user_id", MOCK_USER_ID)


# =============================================================================
# Test: Repeat Reports On The Same Message
# =============================================================================

class TestDuplicateReportPrevention:
    """Tests for reporting the same message more than once.

    ORIGINAL INTENT: a second report of the same message -> 409 "already
    reported". No such contract exists anywhere in the product: migration 126
    creates six indexes but NO unique constraint on (user_id, message_id), the
    endpoint contains no dedup check, and no client calls one. Reports are an
    append-only feedback log.

    So the guarantee worth protecting is the opposite one, asserted below: a
    user's repeat report is never silently swallowed — e.g. re-reporting the
    same answer under a different category after the first was dismissed must
    still reach the DB. If dedup is ever wanted it needs a product decision, a
    unique index, and a real 409 path; this test will then fail loudly and
    force that work to be done deliberately.  (See OPEN QUESTION in the run
    report.)
    """

    def test_duplicate_report_same_user(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """A user may report the same message twice; both reports are stored."""
        stub_insert(mock_supabase_client, generate_mock_report(report_id="report-first"))
        first = client.post("/api/v1/chat/report", json=report_payload(category="wrong_advice"))

        stub_insert(mock_supabase_client, generate_mock_report(report_id="report-second"))
        second = client.post("/api/v1/chat/report", json=report_payload(category="unhelpful"))

        assert first.status_code == 200
        assert second.status_code == 200
        assert first.json()["report_id"] == "report-first"
        assert second.json()["report_id"] == "report-second"

        # Two distinct rows were persisted for the same message_id.
        inserts = mock_supabase_client.table.return_value.insert.call_args_list
        assert len(inserts) == 2
        assert [i.args[0]["report_category"] for i in inserts] == ["wrong_advice", "unhelpful"]
        assert {i.args[0]["message_id"] for i in inserts} == {MOCK_MESSAGE_ID}


# =============================================================================
# Test: Get Report Categories
# =============================================================================

class TestGetCategories:
    """Tests for GET /api/v1/chat/categories"""

    def test_get_available_categories(self, client):
        """Test getting available report categories.

        Path corrected (/chat/categories, not /chat/reports/categories) and the
        category values corrected to the DB-enforced set. This test is the gate
        that keeps the API enum and the migration-126 CHECK constraint in sync:
        a category the API offers but Postgres rejects would 500 every report
        filed under it.
        """
        response = client.get("/api/v1/chat/categories")

        assert response.status_code == 200
        data = response.json()

        assert "categories" in data
        assert "statuses" in data

        category_values = [c["value"] for c in data["categories"]]
        assert "wrong_advice" in category_values
        assert "inappropriate" in category_values
        assert "unhelpful" in category_values
        assert "outdated_info" in category_values
        assert "other" in category_values
        assert sorted(category_values) == sorted(ALL_CATEGORIES)
        assert sorted(category_values) == sorted(c.value for c in ReportCategory)

        # Verify each category has a label and a user-facing description
        for category in data["categories"]:
            assert "value" in category
            assert "label" in category
            assert category["description"]

        status_values = [s["value"] for s in data["statuses"]]
        assert sorted(status_values) == sorted(s.value for s in ReportStatus)


# =============================================================================
# Test: Edge Cases
# =============================================================================

class TestEdgeCases:
    """Tests for edge cases and error handling."""

    def test_very_long_message_content(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test handling of very long message content in reports.

        A full-length AI response (10,000 chars — the model's max) must be
        reportable; one char over must be rejected rather than silently
        truncated into the report row.
        """
        long_response = "x" * 10000
        stub_insert(mock_supabase_client, generate_mock_report(reported_ai_response=long_response))

        response = client.post(
            "/api/v1/chat/report",
            json=report_payload(ai_response=long_response),
        )

        assert response.status_code == 200
        assert inserted_row(mock_supabase_client)["reported_ai_response"] == long_response

        over_limit = client.post(
            "/api/v1/chat/report",
            json=report_payload(ai_response="x" * 10001),
        )
        assert over_limit.status_code == 422

    def test_special_characters_in_reason(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test handling special characters in reason text."""
        reason_with_special_chars = 'Test "reason" with <special> chars & unicode: éè'
        stub_insert(mock_supabase_client, generate_mock_report(reason=reason_with_special_chars))

        response = client.post(
            "/api/v1/chat/report",
            json=report_payload(category="other", reason=reason_with_special_chars),
        )

        assert response.status_code == 200
        assert inserted_row(mock_supabase_client)["report_reason"] == reason_with_special_chars

    def test_database_connection_error(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger
    ):
        """Test graceful handling of database connection errors."""
        mock_activity, mock_error = mock_activity_logger

        mock_supabase_client.table.return_value.insert.return_value.execute.side_effect = Exception(
            "Connection timeout"
        )

        response = client.post("/api/v1/chat/report", json=report_payload())

        assert response.status_code == 500
        # The DB error text must never be leaked to the client.
        assert "Connection timeout" not in response.text
        mock_error.assert_called_once()

    def test_concurrent_report_submission(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger, mock_gemini_service
    ):
        """Test handling concurrent report submissions (race condition).

        If a unique index is ever added on (user_id, message_id), the loser of
        the race gets a unique-violation from Postgres. It must surface as a
        clean 500 with no DB internals leaked — not a crash, and not a fake 200.
        """
        call_count = 0

        def mock_execute(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                result = MagicMock()
                result.data = [generate_mock_report()]
                return result
            raise Exception("duplicate key value violates unique constraint")

        mock_supabase_client.table.return_value.insert.return_value.execute.side_effect = mock_execute

        response1 = client.post("/api/v1/chat/report", json=report_payload())
        assert response1.status_code == 200

        response2 = client.post("/api/v1/chat/report", json=report_payload())
        assert response2.status_code == 500
        assert "unique constraint" not in response2.text


# =============================================================================
# Test: Report Statistics
# =============================================================================

class TestReportStatistics:
    """Tests for GET /api/v1/chat/reports/{user_id}/stats.

    Response keys are total_reports / status_counts / category_counts /
    with_ai_analysis (production), not the pending_reports / resolved_reports /
    category_breakdown the old test invented. Same guarantee, real key names.
    """

    def test_get_user_report_stats(self, client, mock_supabase, mock_supabase_client):
        """Test getting report statistics for a user."""
        stub_stats_query(mock_supabase_client, [
            generate_mock_report("r1", status="pending", category="wrong_advice"),
            generate_mock_report("r2", status="resolved", category="outdated_info", ai_analysis="a"),
            generate_mock_report("r3", status="reviewed", category="unhelpful"),
            generate_mock_report("r4", status="resolved", category="wrong_advice"),
        ])

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["total_reports"] == 4
        assert data["status_counts"]["pending"] == 1
        assert data["status_counts"]["resolved"] == 2
        assert data["status_counts"]["reviewed"] == 1
        assert data["status_counts"]["dismissed"] == 0
        assert data["category_counts"]["wrong_advice"] == 2
        assert data["category_counts"]["outdated_info"] == 1
        assert data["category_counts"]["unhelpful"] == 1
        assert data["with_ai_analysis"] == 1

    def test_get_user_report_stats_empty(self, client, mock_supabase, mock_supabase_client):
        """Test statistics when user has no reports."""
        stub_stats_query(mock_supabase_client, [])

        response = client.get(f"/api/v1/chat/reports/{MOCK_USER_ID}/stats")

        assert response.status_code == 200
        data = response.json()
        assert data["total_reports"] == 0
        assert data["status_counts"]["pending"] == 0
        assert data["with_ai_analysis"] == 0
        # Every known status/category must still be present as a zero bucket.
        assert sorted(data["status_counts"]) == sorted(s.value for s in ReportStatus)
        assert sorted(data["category_counts"]) == sorted(c.value for c in ReportCategory)


# =============================================================================
# Test: Report Lifecycle Is Admin-Only (no user-facing withdraw)
# =============================================================================

class TestWithdrawReport:
    """Tests for withdrawing/canceling a report.

    ORIGINAL INTENT: DELETE /chat/reports/{user_id}/{report_id} withdraws a
    pending report (200, status="withdrawn") but refuses a resolved one (400).

    That feature does not exist and is contradicted by the schema. Migration
    126 defines the lifecycle as `pending -> reviewed -> resolved/dismissed`
    with a CHECK constraint that has NO 'withdrawn' value, grants users only
    INSERT + SELECT (no UPDATE/DELETE policy), and no DELETE route is
    registered on the chat router. No client calls one either.

    The invariant the product ACTUALLY holds — and that these tests now pin
    down — is: a user can file a report and read it back, but cannot mutate or
    remove it; report state is admin-controlled. That is a live regression
    gate: shipping a user-facing withdraw route that writes status='withdrawn'
    would be rejected by the production CHECK constraint at runtime, so it must
    not be added without a migration. These tests fail the moment someone tries.
    (See OPEN QUESTION in the run report: withdraw may be worth building.)
    """

    def test_withdraw_pending_report(
        self, client, mock_supabase, mock_supabase_client, mock_activity_logger
    ):
        """No user-facing withdraw route exists for a pending report."""
        stub_select_eq_eq(mock_supabase_client, [generate_mock_report(status="pending")])

        response = client.delete(f"/api/v1/chat/report/{MOCK_REPORT_ID}")

        assert response.status_code == 405  # route exists for GET only
        # 'withdrawn' is not a storable status (DB CHECK constraint).
        assert "withdrawn" not in {s.value for s in ReportStatus}
        # Nothing was mutated.
        assert mock_supabase_client.table.return_value.update.called is False
        assert mock_supabase_client.table.return_value.delete.called is False

    def test_cannot_withdraw_resolved_report(
        self, client, mock_supabase, mock_supabase_client
    ):
        """A resolved report is immutable through the user-facing API."""
        stub_select_eq_eq(mock_supabase_client, [generate_mock_report(status="resolved")])

        delete_response = client.delete(f"/api/v1/chat/report/{MOCK_REPORT_ID}")
        assert delete_response.status_code == 405

        # It is still readable, and still resolved.
        get_response = client.get(
            f"/api/v1/chat/report/{MOCK_REPORT_ID}", params={"user_id": MOCK_USER_ID}
        )
        assert get_response.status_code == 200
        assert get_response.json()["status"] == "resolved"
        assert mock_supabase_client.table.return_value.update.called is False

    def test_withdraw_nonexistent_report(
        self, client, mock_supabase, mock_supabase_client
    ):
        """Deleting an unknown report is not an operation the API offers.

        The old path (/chat/reports/{user_id}/{report_id}) is not routed at all,
        and DELETE on the real report path is not allowed — either way, no write
        reaches the reports table.
        """
        old_path = client.delete(f"/api/v1/chat/reports/{MOCK_USER_ID}/nonexistent-report")
        assert old_path.status_code == 404  # no such route

        real_path = client.delete("/api/v1/chat/report/nonexistent-report")
        assert real_path.status_code == 405  # GET-only route

        assert mock_supabase_client.table.return_value.update.called is False
        assert mock_supabase_client.table.return_value.delete.called is False
