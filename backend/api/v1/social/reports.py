"""
Content Reports API endpoints (F9).

This module handles content reporting:
- POST / - Submit a content report
- GET / - Get user's own submitted reports
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger

from .utils import get_supabase_client

logger = get_logger(__name__)

router = APIRouter()


class ReportCreate(BaseModel):
    """Request body for creating a content report."""
    content_type: str = Field(..., pattern="^(post|user|message|comment)$")
    content_id: str = Field(..., max_length=100)
    reported_user_id: Optional[str] = Field(default=None, max_length=100)
    reason: str = Field(..., pattern="^(spam|inappropriate|harassment|other)$")
    description: Optional[str] = Field(default=None, max_length=2000)


@router.post("/")
async def submit_report(
    report: ReportCreate,
    user_id: str = Query(..., description="Current user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Submit a content report.

    Args:
        report: Report details
        user_id: Current user's ID

    Returns:
        Created report record
    """
    try:
        supabase = get_supabase_client()

        report_data = {
            "reporter_id": user_id,
            "content_type": report.content_type,
            "content_id": report.content_id,
            "reason": report.reason,
            "status": "pending",
        }

        if report.reported_user_id:
            report_data["reported_user_id"] = report.reported_user_id
        if report.description:
            report_data["description"] = report.description

        result = supabase.table("content_reports").insert(report_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to submit report")

        logger.info(f"[Reports] Report submitted by {user_id}: {report.content_type}/{report.content_id}")

        return {
            "message": "Report submitted successfully",
            "report_id": result.data[0]["id"],
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Reports] Error submitting report: {e}")
        raise safe_internal_error(e, "reports")


@router.get("/")
async def get_my_reports(
    user_id: str = Query(..., description="Current user ID"),
    limit: int = Query(20, ge=1, le=50),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's own submitted reports.

    Args:
        user_id: Current user's ID
        limit: Maximum reports to return
        offset: Pagination offset

    Returns:
        List of reports submitted by the user
    """
    try:
        supabase = get_supabase_client()

        result = supabase.table("content_reports").select(
            "*"
        ).eq("reporter_id", user_id).order(
            "created_at", desc=True
        ).range(offset, offset + limit - 1).execute()

        return {
            "reports": result.data or [],
            "count": len(result.data or []),
        }

    except Exception as e:
        logger.error(f"[Reports] Error getting reports: {e}")
        raise safe_internal_error(e, "reports")
