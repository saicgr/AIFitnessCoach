"""
Chat Message Report API endpoints.

Allows users to:
- Report problematic AI chat responses with categorized issues
- View their submitted reports and status
- Get details on specific reports

Reports are analyzed by Gemini AI to understand why a response
might have been problematic, helping improve the AI coach over time.
"""

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field
from enum import Enum

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from services.gemini_service import GeminiService

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Enums
# =============================================================================

class ReportCategory(str, Enum):
    """Categories for chat message reports."""
    WRONG_ADVICE = "wrong_advice"
    INAPPROPRIATE = "inappropriate"
    UNHELPFUL = "unhelpful"
    OUTDATED_INFO = "outdated_info"
    OTHER = "other"


class ReportStatus(str, Enum):
    """Status values for chat message reports."""
    PENDING = "pending"
    REVIEWED = "reviewed"
    RESOLVED = "resolved"
    DISMISSED = "dismissed"


# =============================================================================
# Request/Response Models
# =============================================================================

class ChatMessageReportCreate(BaseModel):
    """Create a new chat message report."""
    user_id: str = Field(..., max_length=100)
    message_id: str = Field(..., max_length=100, description="The ID of the reported AI message")
    report_category: ReportCategory
    report_reason: Optional[str] = Field(None, max_length=1000, description="Optional detailed reason for the report")
    original_user_message: str = Field(..., max_length=5000, description="The user's original message that prompted the AI response")
    reported_ai_response: str = Field(..., max_length=10000, description="The AI response being reported")


class ChatMessageReport(BaseModel):
    """Full chat message report model."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    message_id: str = Field(..., max_length=100)
    report_category: ReportCategory
    report_reason: Optional[str] = Field(None, max_length=1000)
    original_user_message: str = Field(..., max_length=5000)
    reported_ai_response: str = Field(..., max_length=10000)
    ai_analysis: Optional[str] = Field(None, max_length=5000, description="AI analysis of why the response might have been problematic")
    status: ReportStatus
    created_at: datetime
    updated_at: datetime
    reviewed_at: Optional[datetime] = None
    reviewed_by: Optional[str] = Field(None, max_length=100)
    resolution_note: Optional[str] = Field(None, max_length=1000)


class ChatMessageReportResponse(BaseModel):
    """Response after creating a report."""
    success: bool
    report_id: str = Field(..., max_length=100)
    message: str
    status: ReportStatus


class ChatMessageReportSummary(BaseModel):
    """Summary view of a chat message report for list views."""
    id: str = Field(..., max_length=100)
    message_id: str = Field(..., max_length=100)
    report_category: ReportCategory
    status: ReportStatus
    created_at: datetime
    original_user_message_preview: str = Field(..., max_length=100)
    has_ai_analysis: bool = False


# =============================================================================
# Helper Functions
# =============================================================================

def _parse_report(data: dict) -> ChatMessageReport:
    """Parse database row to ChatMessageReport model."""
    return ChatMessageReport(
        id=str(data["id"]),
        user_id=data["user_id"],
        message_id=data["message_id"],
        report_category=ReportCategory(data["report_category"]),
        report_reason=data.get("report_reason"),
        original_user_message=data["original_user_message"],
        reported_ai_response=data["reported_ai_response"],
        ai_analysis=data.get("ai_analysis"),
        status=ReportStatus(data["status"]),
        created_at=data.get("created_at") or datetime.utcnow(),
        updated_at=data.get("updated_at") or datetime.utcnow(),
        reviewed_at=data.get("reviewed_at"),
        reviewed_by=data.get("reviewed_by"),
        resolution_note=data.get("resolution_note"),
    )


def _parse_report_summary(data: dict) -> ChatMessageReportSummary:
    """Parse database row to ChatMessageReportSummary model."""
    original_msg = data.get("original_user_message", "")
    preview = original_msg[:97] + "..." if len(original_msg) > 100 else original_msg

    return ChatMessageReportSummary(
        id=str(data["id"]),
        message_id=data["message_id"],
        report_category=ReportCategory(data["report_category"]),
        status=ReportStatus(data["status"]),
        created_at=data.get("created_at") or datetime.utcnow(),
        original_user_message_preview=preview,
        has_ai_analysis=bool(data.get("ai_analysis")),
    )


# =============================================================================
# Gemini Analysis Integration
# =============================================================================

# Singleton Gemini service (lazy initialization)
_gemini_service: Optional[GeminiService] = None


def get_gemini_service() -> GeminiService:
    """Get or create Gemini service singleton."""
    global _gemini_service
    if _gemini_service is None:
        _gemini_service = GeminiService()
    return _gemini_service


async def analyze_reported_message(
    report_id: str,
    category: ReportCategory,
    original_user_message: str,
    reported_ai_response: str,
    report_reason: Optional[str] = None
) -> None:
    """
    Use Gemini to analyze why the AI response might have been problematic.

    This runs as a background task after the report is created.
    The analysis is stored in the ai_analysis field of the report.
    """
    logger.info(f"Starting Gemini analysis for report {report_id}")

    try:
        gemini = get_gemini_service()

        # Build analysis prompt
        category_descriptions = {
            ReportCategory.WRONG_ADVICE: "providing incorrect or potentially harmful fitness/health advice",
            ReportCategory.INAPPROPRIATE: "being inappropriate, offensive, or unprofessional",
            ReportCategory.UNHELPFUL: "failing to address the user's question or provide useful guidance",
            ReportCategory.OUTDATED_INFO: "providing outdated or superseded fitness/health information",
            ReportCategory.OTHER: "being problematic in some other way",
        }

        category_desc = category_descriptions.get(category, "being problematic")

        # Build the optional reason line
        reason_line = f'USER\'S ADDITIONAL REASON: "{report_reason}"' if report_reason else ''

        analysis_prompt = f"""You are a quality assurance analyst for an AI fitness coach app. A user has reported an AI response as potentially problematic.

REPORT CATEGORY: {category.value} - The user reported this response for {category_desc}.

ORIGINAL USER MESSAGE:
"{original_user_message}"

AI RESPONSE THAT WAS REPORTED:
"{reported_ai_response}"

{reason_line}

Please provide a brief analysis (2-4 sentences) of:
1. Why this response might have been reported under this category
2. What specifically might be problematic about the response
3. A brief suggestion for how the AI coach could have responded better

Keep your analysis professional, objective, and constructive. Focus on actionable insights."""

        analysis = await gemini.chat(
            user_message=analysis_prompt,
            system_prompt="You are a quality assurance analyst reviewing AI fitness coach responses. Be concise, objective, and constructive.",
        )

        # Update the report with the analysis
        db = get_supabase_db()
        db.client.table("chat_message_reports").update({
            "ai_analysis": analysis,
            "updated_at": datetime.utcnow().isoformat(),
        }).eq("id", report_id).execute()

        logger.info(f"Gemini analysis completed for report {report_id}")

    except Exception as e:
        logger.error(f"Failed to analyze reported message {report_id}: {e}")
        # Don't raise - this is a background task, we don't want to affect the user


# =============================================================================
# Submit Report
# =============================================================================

@router.post("/report", response_model=ChatMessageReportResponse)
async def submit_chat_report(
    report: ChatMessageReportCreate,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Submit a report for a problematic AI chat message.

    Creates a report record and triggers async Gemini analysis
    to understand why the response might have been problematic.
    """
    if str(current_user["id"]) != str(report.user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Submitting chat report for user {report.user_id}: category={report.report_category.value}")

    try:
        db = get_supabase_db()

        # Create the report record
        report_record = {
            "user_id": report.user_id,
            "message_id": report.message_id,
            "report_category": report.report_category.value,
            "report_reason": report.report_reason,
            "original_user_message": report.original_user_message,
            "reported_ai_response": report.reported_ai_response,
            "status": ReportStatus.PENDING.value,
        }

        result = db.client.table("chat_message_reports").insert(report_record).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create chat message report")

        report_data = result.data[0]
        report_id = str(report_data["id"])

        # Trigger async Gemini analysis
        background_tasks.add_task(
            analyze_reported_message,
            report_id=report_id,
            category=report.report_category,
            original_user_message=report.original_user_message,
            reported_ai_response=report.reported_ai_response,
            report_reason=report.report_reason,
        )

        # Log user activity
        await log_user_activity(
            user_id=report.user_id,
            action="chat_report_submitted",
            endpoint="/api/v1/chat/report",
            message=f"Submitted chat report: {report.report_category.value}",
            metadata={
                "report_id": report_id,
                "message_id": report.message_id,
                "category": report.report_category.value,
                "has_reason": bool(report.report_reason),
            },
            status_code=200
        )

        logger.info(f"Chat report created: {report_id}")

        return ChatMessageReportResponse(
            success=True,
            report_id=report_id,
            message="Thank you for your feedback. Your report has been submitted and will be analyzed.",
            status=ReportStatus.PENDING,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to submit chat report: {e}")
        await log_user_error(
            user_id=report.user_id,
            action="chat_report_submitted",
            error=e,
            endpoint="/api/v1/chat/report",
            metadata={
                "message_id": report.message_id,
                "category": report.report_category.value,
            },
            status_code=500
        )
        raise safe_internal_error(e, "submit_chat_report")


# =============================================================================
# Get User's Reports
# =============================================================================

@router.get("/reports/{user_id}", response_model=List[ChatMessageReportSummary])
async def get_user_reports(
    user_id: str,
    status: Optional[ReportStatus] = None,
    category: Optional[ReportCategory] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all chat message reports submitted by a user.

    Returns a list of report summaries with optional filtering by status and category.
    Reports are ordered by created_at descending (most recent first).
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting chat reports for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("chat_message_reports").select("*").eq("user_id", user_id)

        if status:
            query = query.eq("status", status.value)

        if category:
            query = query.eq("report_category", category.value)

        query = query.order("created_at", desc=True).range(offset, offset + limit - 1)

        result = query.execute()

        return [_parse_report_summary(r) for r in result.data or []]

    except Exception as e:
        logger.error(f"Failed to get user reports: {e}")
        raise safe_internal_error(e, "get_user_reports")


# =============================================================================
# Get Single Report Details
# =============================================================================

@router.get("/report/{report_id}", response_model=ChatMessageReport)
async def get_report(report_id: str, user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get a single chat message report with full details.

    Returns the full report including the AI analysis if available.
    Only the report owner can access their reports (enforced by query).
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting report {report_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("chat_message_reports").select("*").eq(
            "id", report_id
        ).eq("user_id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Report not found")

        return _parse_report(result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get report: {e}")
        raise safe_internal_error(e, "get_report")


# =============================================================================
# Get Report Categories (for dropdown/UI)
# =============================================================================

@router.get("/categories")
async def get_report_categories(current_user: dict = Depends(get_current_user)):
    """
    Get available report categories and statuses.

    Returns all available categories for creating chat reports.
    """
    return {
        "categories": [
            {
                "value": cat.value,
                "label": cat.value.replace("_", " ").title(),
                "description": _get_category_description(cat),
            }
            for cat in ReportCategory
        ],
        "statuses": [
            {"value": stat.value, "label": stat.value.replace("_", " ").title()}
            for stat in ReportStatus
        ],
    }


def _get_category_description(category: ReportCategory) -> str:
    """Get user-friendly description for a report category."""
    descriptions = {
        ReportCategory.WRONG_ADVICE: "The AI provided incorrect or potentially harmful advice",
        ReportCategory.INAPPROPRIATE: "The response was inappropriate, offensive, or unprofessional",
        ReportCategory.UNHELPFUL: "The response didn't answer my question or provide useful guidance",
        ReportCategory.OUTDATED_INFO: "The information provided is outdated or no longer accurate",
        ReportCategory.OTHER: "Other issue not covered by the above categories",
    }
    return descriptions.get(category, "")


# =============================================================================
# Get User Report Statistics
# =============================================================================

@router.get("/reports/{user_id}/stats")
async def get_user_report_stats(user_id: str, current_user: dict = Depends(get_current_user)):
    """
    Get report statistics for a user.

    Returns counts of reports by status and category.
    """
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    logger.info(f"Getting report stats for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("chat_message_reports").select("*").eq("user_id", user_id).execute()

        reports = result.data or []

        if not reports:
            return {
                "total_reports": 0,
                "status_counts": {s.value: 0 for s in ReportStatus},
                "category_counts": {c.value: 0 for c in ReportCategory},
                "with_ai_analysis": 0,
            }

        # Calculate statistics
        status_counts = {s.value: 0 for s in ReportStatus}
        category_counts = {c.value: 0 for c in ReportCategory}
        with_analysis = 0

        for r in reports:
            status_counts[r["status"]] = status_counts.get(r["status"], 0) + 1
            category_counts[r["report_category"]] = category_counts.get(r["report_category"], 0) + 1
            if r.get("ai_analysis"):
                with_analysis += 1

        return {
            "total_reports": len(reports),
            "status_counts": status_counts,
            "category_counts": category_counts,
            "with_ai_analysis": with_analysis,
        }

    except Exception as e:
        logger.error(f"Failed to get report stats: {e}")
        raise safe_internal_error(e, "get_user_report_stats")
