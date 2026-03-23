"""
Support Ticket API endpoints.

Allows users to:
- Create support tickets with categorized issues
- View their ticket history and status
- Reply to existing tickets
- Close resolved tickets

This addresses the user complaint "Generic reply that didn't address my concern"
by providing a structured ticket system with proper tracking and response handling.
"""

import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from core.auth import get_current_user, verify_user_ownership, verify_resource_ownership
from core.exceptions import safe_internal_error
from core.config import get_settings
from typing import Dict, List, Optional
from datetime import datetime

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.support import (
    SupportTicketCreate,
    SupportTicket,
    SupportTicketWithMessages,
    SupportTicketSummary,
    SupportTicketMessage,
    SupportTicketMessageCreate,
    SupportTicketReplyResponse,
    SupportTicketCloseResponse,
    SupportTicketStatsResponse,
    TicketStatus,
    TicketPriority,
    TicketCategory,
    MessageSender,
)
from services.user_context_service import user_context_service, EventType
from services.trello_service import get_trello_service

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Helper Functions
# =============================================================================

def _parse_ticket(data: dict) -> SupportTicket:
    """Parse database row to SupportTicket model."""
    return SupportTicket(
        id=str(data["id"]),
        user_id=data["user_id"],
        subject=data["subject"],
        category=TicketCategory(data["category"]),
        priority=TicketPriority(data["priority"]),
        status=TicketStatus(data["status"]),
        created_at=data.get("created_at") or datetime.utcnow(),
        updated_at=data.get("updated_at") or datetime.utcnow(),
        resolved_at=data.get("resolved_at"),
        closed_at=data.get("closed_at"),
        assigned_to=data.get("assigned_to"),
        message_count=data.get("message_count", 1),
    )


def _parse_message(data: dict) -> SupportTicketMessage:
    """Parse database row to SupportTicketMessage model."""
    return SupportTicketMessage(
        id=str(data["id"]),
        ticket_id=str(data["ticket_id"]),
        sender=MessageSender(data["sender"]),
        message=data["message"],
        created_at=data.get("created_at") or datetime.utcnow(),
        updated_at=data.get("updated_at"),
        is_internal=data.get("is_internal", False),
    )


def _parse_ticket_summary(data: dict) -> SupportTicketSummary:
    """Parse database row to SupportTicketSummary model."""
    return SupportTicketSummary(
        id=str(data["id"]),
        subject=data["subject"],
        category=TicketCategory(data["category"]),
        priority=TicketPriority(data["priority"]),
        status=TicketStatus(data["status"]),
        created_at=data.get("created_at") or datetime.utcnow(),
        updated_at=data.get("updated_at") or datetime.utcnow(),
        message_count=data.get("message_count", 1),
        last_message_preview=data.get("last_message_preview"),
        last_message_sender=MessageSender(data["last_message_sender"]) if data.get("last_message_sender") else None,
    )


# =============================================================================
# Presigned URL for Ticket Attachments
# =============================================================================

ALLOWED_ATTACHMENT_TYPES = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}
MAX_ATTACHMENT_SIZE = 10 * 1024 * 1024  # 10 MB
PRESIGN_EXPIRY_SECONDS = 600  # 10 minutes


class AttachmentPresignRequest(BaseModel):
    """Request body for generating a presigned S3 upload URL for ticket attachments."""
    filename: str = Field(..., min_length=1, max_length=255)
    content_type: str = Field(..., max_length=50)
    file_size: int = Field(..., gt=0)


class AttachmentPresignResponse(BaseModel):
    """Response with presigned S3 POST URL and fields."""
    presigned_url: str
    presigned_fields: Dict[str, str]
    s3_key: str


@router.post("/attachments/presign", response_model=AttachmentPresignResponse)
async def presign_attachment_upload(
    body: AttachmentPresignRequest,
    current_user: dict = Depends(get_current_user),
):
    """Generate a presigned S3 POST URL for uploading a ticket attachment (image only)."""
    user_id = current_user.get("sub") or current_user.get("user_id")

    if body.content_type not in ALLOWED_ATTACHMENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type. Allowed: {', '.join(ALLOWED_ATTACHMENT_TYPES.keys())}",
        )

    if body.file_size > MAX_ATTACHMENT_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Maximum size: {MAX_ATTACHMENT_SIZE // (1024 * 1024)}MB",
        )

    ext = ALLOWED_ATTACHMENT_TYPES[body.content_type]
    s3_key = f"support_attachments/{user_id}/{uuid.uuid4().hex}.{ext}"

    try:
        settings = get_settings()

        if not settings.s3_bucket_name:
            raise HTTPException(status_code=503, detail="Media upload not configured")

        import boto3
        s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_default_region,
        )

        presigned = s3_client.generate_presigned_post(
            Bucket=settings.s3_bucket_name,
            Key=s3_key,
            Fields={"Content-Type": body.content_type},
            Conditions=[
                {"Content-Type": body.content_type},
                ["content-length-range", 1, MAX_ATTACHMENT_SIZE],
            ],
            ExpiresIn=PRESIGN_EXPIRY_SECONDS,
        )

        return AttachmentPresignResponse(
            presigned_url=presigned["url"],
            presigned_fields=presigned["fields"],
            s3_key=s3_key,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate presigned URL for support attachment: {e}")
        raise safe_internal_error(e, "support_attachment_presign")


# =============================================================================
# Create Support Ticket
# =============================================================================

@router.post("/tickets", response_model=SupportTicketWithMessages)
async def create_support_ticket(ticket: SupportTicketCreate,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a new support ticket.

    Creates a ticket with the specified category and priority,
    and adds the initial message to the conversation thread.
    Also logs the ticket creation to user_context_logs for analytics.
    """
    verify_user_ownership(current_user, ticket.user_id)
    logger.info(f"Creating support ticket for user {ticket.user_id}: {ticket.subject}")

    try:
        db = get_supabase_db()

        # Create the ticket record
        ticket_record = {
            "user_id": ticket.user_id,
            "subject": ticket.subject,
            "category": ticket.category.value,
            "priority": ticket.priority.value,
            "status": TicketStatus.OPEN.value,
        }
        if ticket.attachments:
            ticket_record["attachments"] = ticket.attachments
        if ticket.steps_to_reproduce:
            ticket_record["steps_to_reproduce"] = ticket.steps_to_reproduce
        if ticket.screen_context:
            ticket_record["screen_context"] = ticket.screen_context

        result = db.client.table("support_tickets").insert(ticket_record).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create support ticket")

        ticket_data = result.data[0]
        ticket_id = str(ticket_data["id"])

        # Add the initial message
        message_record = {
            "ticket_id": ticket_id,
            "sender": MessageSender.USER.value,
            "message": ticket.initial_message,
        }

        message_result = db.client.table("support_ticket_messages").insert(message_record).execute()

        if not message_result.data:
            # Rollback ticket creation on message failure
            db.client.table("support_tickets").delete().eq("id", ticket_id).execute()
            raise HTTPException(status_code=500, detail="Failed to add initial message to ticket")

        message_data = message_result.data[0]

        # Log to user_context_logs
        await user_context_service.log_event(
            user_id=ticket.user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "support_ticket",
                "action": "created",
                "ticket_id": ticket_id,
                "category": ticket.category.value,
                "priority": ticket.priority.value,
            },
            context={
                "subject": ticket.subject,
            },
        )

        # Log activity
        await log_user_activity(
            user_id=ticket.user_id,
            action="support_ticket_created",
            endpoint="/api/v1/support/tickets",
            message=f"Created support ticket: {ticket.subject}",
            metadata={
                "ticket_id": ticket_id,
                "category": ticket.category.value,
                "priority": ticket.priority.value,
            },
            status_code=200
        )

        logger.info(f"Support ticket created: {ticket_id}")

        # Create Trello card in background (non-blocking)
        trello = get_trello_service()
        if trello.enabled:
            # Look up user name/username + device info for Trello card context
            user_row = db.client.table("users").select(
                "name, username, email, device_model, device_platform, os_version, screen_width, screen_height"
            ).eq("id", ticket.user_id).execute()
            user_info = user_row.data[0] if user_row.data else {}

            device_info = {
                "device_model": user_info.get("device_model"),
                "device_platform": user_info.get("device_platform"),
                "os_version": user_info.get("os_version"),
                "screen_width": user_info.get("screen_width"),
                "screen_height": user_info.get("screen_height"),
            }
            # Strip None values
            device_info = {k: v for k, v in device_info.items() if v is not None}

            async def _create_trello_card():
                card = await trello.create_card(
                    ticket_id=ticket_id,
                    subject=ticket.subject,
                    category=ticket.category.value,
                    priority=ticket.priority.value,
                    message=ticket.initial_message,
                    user_email=user_info.get("email") or current_user.get("email"),
                    user_name=user_info.get("name"),
                    username=user_info.get("username"),
                    user_id=ticket.user_id,
                    device_info=device_info if device_info else None,
                    attachments=ticket.attachments,
                    steps_to_reproduce=ticket.steps_to_reproduce,
                    screen_context=ticket.screen_context,
                )
                # Store Trello card ID on the ticket for future updates
                if card and card.get("id"):
                    try:
                        db.client.table("support_tickets").update(
                            {"trello_card_id": card["id"]}
                        ).eq("id", ticket_id).execute()
                    except Exception as e:
                        logger.warning(f"Failed to store Trello card ID: {e}")

            background_tasks.add_task(_create_trello_card)

        return SupportTicketWithMessages(
            id=ticket_id,
            user_id=ticket_data["user_id"],
            subject=ticket_data["subject"],
            category=TicketCategory(ticket_data["category"]),
            priority=TicketPriority(ticket_data["priority"]),
            status=TicketStatus(ticket_data["status"]),
            created_at=ticket_data.get("created_at") or datetime.utcnow(),
            updated_at=ticket_data.get("updated_at") or datetime.utcnow(),
            resolved_at=ticket_data.get("resolved_at"),
            closed_at=ticket_data.get("closed_at"),
            assigned_to=ticket_data.get("assigned_to"),
            message_count=1,
            messages=[_parse_message(message_data)],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create support ticket: {e}")
        await log_user_error(
            user_id=ticket.user_id,
            action="support_ticket_created",
            error=e,
            endpoint="/api/v1/support/tickets",
            metadata={"subject": ticket.subject},
            status_code=500
        )
        raise safe_internal_error(e, "support")


# =============================================================================
# Get User's Tickets
# =============================================================================

@router.get("/tickets/{user_id}", response_model=List[SupportTicketSummary])
async def get_user_tickets(
    user_id: str,
    status: Optional[TicketStatus] = None,
    category: Optional[TicketCategory] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: dict = Depends(get_current_user),
):
    """
    Get all support tickets for a user.

    Returns a list of ticket summaries with optional filtering by status and category.
    Tickets are ordered by updated_at descending (most recent first).
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"Getting tickets for user {user_id}")

    try:
        db = get_supabase_db()

        # Use the view for ticket summaries with last message info
        query = db.client.from_("support_tickets_summary").select("*").eq("user_id", user_id)

        if status:
            query = query.eq("status", status.value)

        if category:
            query = query.eq("category", category.value)

        query = query.order("updated_at", desc=True).range(offset, offset + limit - 1)

        result = query.execute()

        return [_parse_ticket_summary(t) for t in result.data or []]

    except Exception as e:
        logger.error(f"Failed to get user tickets: {e}")
        raise safe_internal_error(e, "support")


# =============================================================================
# Get Single Ticket with Messages
# =============================================================================

@router.get("/tickets/{user_id}/{ticket_id}", response_model=SupportTicketWithMessages)
async def get_ticket(user_id: str, ticket_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get a single support ticket with all its messages.

    Returns the full ticket details including the entire conversation thread.
    Only the ticket owner can access their tickets (enforced by RLS).
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"Getting ticket {ticket_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get the ticket
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).eq("user_id", user_id).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]

        # Get all messages for this ticket (excluding internal notes for users)
        messages_result = db.client.table("support_ticket_messages").select("*").eq(
            "ticket_id", ticket_id
        ).eq("is_internal", False).order("created_at").execute()

        messages = [_parse_message(m) for m in messages_result.data or []]

        return SupportTicketWithMessages(
            **_parse_ticket(ticket_data).model_dump(),
            messages=messages,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get ticket: {e}")
        raise safe_internal_error(e, "support")


# =============================================================================
# Add Reply to Ticket
# =============================================================================

@router.post("/tickets/{ticket_id}/reply", response_model=SupportTicketReplyResponse)
async def add_ticket_reply(ticket_id: str, user_id: str, reply: SupportTicketMessageCreate,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """
    Add a reply to an existing support ticket.

    Creates a new message in the ticket's conversation thread.
    Automatically updates the ticket's updated_at timestamp and sets status
    to 'waiting_response' if the user is replying.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"Adding reply to ticket {ticket_id} from user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists and belongs to user
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).eq("user_id", user_id).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]
        current_status = TicketStatus(ticket_data["status"])

        # Check if ticket is closed - can't reply to closed tickets
        if current_status == TicketStatus.CLOSED:
            raise HTTPException(status_code=400, detail="Cannot reply to a closed ticket")

        # Add the message
        message_record = {
            "ticket_id": ticket_id,
            "sender": reply.sender.value,
            "message": reply.message,
        }

        message_result = db.client.table("support_ticket_messages").insert(message_record).execute()

        if not message_result.data:
            raise HTTPException(status_code=500, detail="Failed to add reply")

        message_data = message_result.data[0]

        # Update ticket status if user is replying
        new_status = current_status
        if reply.sender == MessageSender.USER and current_status == TicketStatus.WAITING_RESPONSE:
            new_status = TicketStatus.IN_PROGRESS
        elif reply.sender == MessageSender.SUPPORT and current_status == TicketStatus.OPEN:
            new_status = TicketStatus.IN_PROGRESS

        # Update ticket's updated_at and optionally status
        update_data = {"updated_at": datetime.utcnow().isoformat()}
        if new_status != current_status:
            update_data["status"] = new_status.value

        db.client.table("support_tickets").update(update_data).eq("id", ticket_id).execute()

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="support_ticket_reply",
            endpoint=f"/api/v1/support/tickets/{ticket_id}/reply",
            message="Added reply to support ticket",
            metadata={
                "ticket_id": ticket_id,
                "sender": reply.sender.value,
            },
            status_code=200
        )

        logger.info(f"Reply added to ticket {ticket_id}")

        # Sync reply to Trello card (non-blocking)
        trello_card_id = ticket_data.get("trello_card_id")
        if trello_card_id:
            trello = get_trello_service()
            sender_label = "User" if reply.sender == MessageSender.USER else "Support"
            background_tasks.add_task(
                trello.add_comment, trello_card_id, f"**{sender_label}:** {reply.message}"
            )

        return SupportTicketReplyResponse(
            success=True,
            ticket_id=ticket_id,
            message=_parse_message(message_data),
            new_status=new_status,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add reply to ticket: {e}")
        await log_user_error(
            user_id=user_id,
            action="support_ticket_reply",
            error=e,
            endpoint=f"/api/v1/support/tickets/{ticket_id}/reply",
            metadata={"ticket_id": ticket_id},
            status_code=500
        )
        raise safe_internal_error(e, "support")


# =============================================================================
# Close Ticket
# =============================================================================

@router.patch("/tickets/{ticket_id}/close", response_model=SupportTicketCloseResponse)
async def close_ticket(ticket_id: str, user_id: str,
    background_tasks: BackgroundTasks,
    resolution_note: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Close a support ticket.

    Sets the ticket status to CLOSED and records the closed_at timestamp.
    Optionally adds a final resolution note to the ticket.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"Closing ticket {ticket_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists and belongs to user
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).eq("user_id", user_id).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]
        current_status = TicketStatus(ticket_data["status"])

        # Check if already closed
        if current_status == TicketStatus.CLOSED:
            raise HTTPException(status_code=400, detail="Ticket is already closed")

        closed_at = datetime.utcnow()

        # Add resolution note if provided
        if resolution_note:
            message_record = {
                "ticket_id": ticket_id,
                "sender": MessageSender.USER.value,
                "message": f"[Ticket Closed] {resolution_note}",
            }
            db.client.table("support_ticket_messages").insert(message_record).execute()

        # Update ticket status to closed
        update_data = {
            "status": TicketStatus.CLOSED.value,
            "closed_at": closed_at.isoformat(),
            "updated_at": closed_at.isoformat(),
        }

        # If it wasn't already resolved, set resolved_at too
        if current_status != TicketStatus.RESOLVED:
            update_data["resolved_at"] = closed_at.isoformat()

        db.client.table("support_tickets").update(update_data).eq("id", ticket_id).execute()

        # Log to user_context_logs
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "support_ticket",
                "action": "closed",
                "ticket_id": ticket_id,
                "previous_status": current_status.value,
            },
            context={
                "resolution_note": resolution_note,
            },
        )

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="support_ticket_closed",
            endpoint=f"/api/v1/support/tickets/{ticket_id}/close",
            message="Closed support ticket",
            metadata={
                "ticket_id": ticket_id,
                "previous_status": current_status.value,
            },
            status_code=200
        )

        logger.info(f"Ticket {ticket_id} closed")

        # Archive Trello card (non-blocking)
        trello_card_id = ticket_data.get("trello_card_id")
        if trello_card_id:
            trello = get_trello_service()
            background_tasks.add_task(trello.close_card, trello_card_id)

        return SupportTicketCloseResponse(
            success=True,
            ticket_id=ticket_id,
            closed_at=closed_at,
            final_status=TicketStatus.CLOSED,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to close ticket: {e}")
        await log_user_error(
            user_id=user_id,
            action="support_ticket_closed",
            error=e,
            endpoint=f"/api/v1/support/tickets/{ticket_id}/close",
            metadata={"ticket_id": ticket_id},
            status_code=500
        )
        raise safe_internal_error(e, "support")


# =============================================================================
# Get User Ticket Statistics
# =============================================================================

@router.get("/tickets/{user_id}/stats", response_model=SupportTicketStatsResponse)
async def get_user_ticket_stats(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get support ticket statistics for a user.

    Returns counts of tickets by status and average resolution time.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"Getting ticket stats for user {user_id}")

    try:
        db = get_supabase_db()

        # Get all user tickets
        result = db.client.table("support_tickets").select("*").eq("user_id", user_id).execute()

        tickets = result.data or []

        if not tickets:
            return SupportTicketStatsResponse(
                total_tickets=0,
                open_tickets=0,
                resolved_tickets=0,
                closed_tickets=0,
                avg_resolution_time_hours=None,
            )

        # Calculate statistics
        open_count = sum(1 for t in tickets if t["status"] in ["open", "in_progress", "waiting_response"])
        resolved_count = sum(1 for t in tickets if t["status"] == "resolved")
        closed_count = sum(1 for t in tickets if t["status"] == "closed")

        # Calculate average resolution time for resolved/closed tickets
        resolution_times = []
        for t in tickets:
            if t.get("resolved_at") and t.get("created_at"):
                created = datetime.fromisoformat(t["created_at"].replace("Z", "+00:00"))
                resolved = datetime.fromisoformat(t["resolved_at"].replace("Z", "+00:00"))
                diff = (resolved - created).total_seconds() / 3600  # Convert to hours
                resolution_times.append(diff)

        avg_resolution = sum(resolution_times) / len(resolution_times) if resolution_times else None

        return SupportTicketStatsResponse(
            total_tickets=len(tickets),
            open_tickets=open_count,
            resolved_tickets=resolved_count,
            closed_tickets=closed_count,
            avg_resolution_time_hours=round(avg_resolution, 2) if avg_resolution else None,
        )

    except Exception as e:
        logger.error(f"Failed to get ticket stats: {e}")
        raise safe_internal_error(e, "support")


# =============================================================================
# Get Ticket Categories (for dropdown)
# =============================================================================

@router.get("/categories")
async def get_ticket_categories(
    current_user: dict = Depends(get_current_user),
):
    """
    Get available ticket categories.

    Returns all available categories for creating support tickets.
    """
    return {
        "categories": [
            {"value": cat.value, "label": cat.value.replace("_", " ").title()}
            for cat in TicketCategory
        ],
        "priorities": [
            {"value": pri.value, "label": pri.value.title()}
            for pri in TicketPriority
        ],
        "statuses": [
            {"value": stat.value, "label": stat.value.replace("_", " ").title()}
            for stat in TicketStatus
        ],
    }
