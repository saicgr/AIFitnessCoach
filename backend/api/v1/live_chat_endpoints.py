"""Secondary endpoints for live_chat.  Sub-router included by main module.
Live Chat API endpoints.

Allows users to:
- Start real-time chat sessions with support agents
- Escalate AI chat conversations to human support
- Track queue position and estimated wait times
- Send/receive messages with typing indicators
- Mark messages as read
- End chat sessions

This provides a real-time human support option when AI chat is insufficient.
"""
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
import logging
logger = logging.getLogger(__name__)
from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

router = APIRouter()
@router.post("/{ticket_id}/typing", response_model=LiveChatTypingResponse)
async def update_typing_indicator(ticket_id: str, request: LiveChatTypingRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Update typing indicator for a live chat session.

    Updates either agent_typing or user_typing based on the user's role.
    """
    logger.debug(f"Updating typing indicator for ticket {ticket_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists
        ticket_result = db.client.table("support_tickets").select("id, user_id").eq(
            "id", ticket_id
        ).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]

        # Determine which typing field to update
        is_agent = await _check_if_user_is_agent(request.user_id)
        typing_field = "agent_typing" if is_agent else "user_typing"

        # Verify user can update typing for this ticket
        if not is_agent and ticket_data["user_id"] != request.user_id:
            raise HTTPException(status_code=403, detail="Not authorized for this chat")

        # Update typing indicator
        db.client.table("live_chat_queue").update({
            typing_field: request.is_typing,
            f"{typing_field}_at": datetime.utcnow().isoformat() if request.is_typing else None
        }).eq("ticket_id", ticket_id).execute()

        return LiveChatTypingResponse(
            success=True,
            ticket_id=ticket_id,
            is_typing=request.is_typing,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update typing indicator: {e}")
        raise safe_internal_error(e, "live_chat")


# =============================================================================
# Mark Messages as Read
# =============================================================================

@router.post("/{ticket_id}/read", response_model=LiveChatReadResponse)
async def mark_messages_read(ticket_id: str, request: LiveChatReadRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Mark messages as read in a live chat session.

    Updates the read_at timestamp for the specified messages.
    """
    logger.info(f"Marking messages as read for ticket {ticket_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists and user has access
        ticket_result = db.client.table("support_tickets").select("id, user_id").eq(
            "id", ticket_id
        ).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]
        is_agent = await _check_if_user_is_agent(request.user_id)

        # Verify user can mark messages in this ticket
        if not is_agent and ticket_data["user_id"] != request.user_id:
            raise HTTPException(status_code=403, detail="Not authorized for this chat")

        # Update messages as read
        now = datetime.utcnow().isoformat()

        for message_id in request.message_ids:
            db.client.table("live_chat_messages").update({
                "read_at": now
            }).eq("id", message_id).eq("ticket_id", ticket_id).execute()

        return LiveChatReadResponse(
            success=True,
            ticket_id=ticket_id,
            messages_marked_read=len(request.message_ids),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to mark messages as read: {e}")
        raise safe_internal_error(e, "live_chat")


# =============================================================================
# End Live Chat Session
# =============================================================================

@router.post("/{ticket_id}/end", response_model=LiveChatEndResponse)
async def end_live_chat(ticket_id: str, request: LiveChatEndRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    End a live chat session.

    Updates the ticket status to resolved and removes from queue.
    Adds an optional resolution note.
    """
    logger.info(f"Ending live chat for ticket {ticket_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]
        is_agent = await _check_if_user_is_agent(request.user_id)

        # Verify user can end this chat
        if not is_agent and ticket_data["user_id"] != request.user_id:
            raise HTTPException(status_code=403, detail="Not authorized to end this chat")

        # Check if already ended
        if ticket_data.get("status") in ["closed", "resolved"]:
            return LiveChatEndResponse(
                success=True,
                ticket_id=ticket_id,
                ended_at=datetime.utcnow(),
                status=LiveChatStatus.ENDED,
            )

        ended_at = datetime.utcnow()

        # Add system message about chat ending
        who_ended = "agent" if is_agent else "user"
        system_message = {
            "ticket_id": ticket_id,
            "sender_role": MessageSenderRole.AGENT.value,
            "sender_id": "system",
            "message": f"This chat has been ended by the {who_ended}." + (f" Resolution: {request.resolution_note}" if request.resolution_note else ""),
            "is_system_message": True,
        }

        db.client.table("live_chat_messages").insert(system_message).execute()

        # Update ticket status
        update_data = {
            "status": TicketStatus.RESOLVED.value,
            "resolved_at": ended_at.isoformat(),
            "updated_at": ended_at.isoformat(),
        }

        db.client.table("support_tickets").update(update_data).eq("id", ticket_id).execute()

        # Remove from queue
        db.client.table("live_chat_queue").delete().eq("ticket_id", ticket_id).execute()

        # Log to user context
        await user_context_service.log_event(
            user_id=request.user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "live_chat",
                "action": "ended",
                "ticket_id": ticket_id,
                "ended_by": who_ended,
            },
            context={
                "resolution_note": request.resolution_note,
            },
        )

        # Log activity
        await log_user_activity(
            user_id=request.user_id,
            action="live_chat_ended",
            endpoint=f"/api/v1/live-chat/{ticket_id}/end",
            message="Ended live chat session",
            metadata={
                "ticket_id": ticket_id,
                "ended_by": who_ended,
            },
            status_code=200
        )

        logger.info(f"Live chat {ticket_id} ended by {who_ended}")

        return LiveChatEndResponse(
            success=True,
            ticket_id=ticket_id,
            ended_at=ended_at,
            status=LiveChatStatus.ENDED,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to end live chat: {e}")
        await log_user_error(
            user_id=request.user_id,
            action="live_chat_ended",
            error=e,
            endpoint=f"/api/v1/live-chat/{ticket_id}/end",
            metadata={"ticket_id": ticket_id},
            status_code=500
        )
        raise safe_internal_error(e, "live_chat")


# =============================================================================
# Get Messages
# =============================================================================

@router.get("/{ticket_id}/messages", response_model=List[LiveChatMessage])
async def get_messages(
    ticket_id: str,
    user_id: str,
    limit: int = 50,
    before_id: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Get messages for a live chat session.

    Returns messages ordered by created_at ascending.
    Supports pagination via before_id.
    """
    logger.info(f"Getting messages for ticket {ticket_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists and user has access
        ticket_result = db.client.table("support_tickets").select("id, user_id").eq(
            "id", ticket_id
        ).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]
        is_agent = await _check_if_user_is_agent(user_id)

        if not is_agent and ticket_data["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized for this chat")

        # Build query
        query = db.client.table("live_chat_messages").select("*").eq(
            "ticket_id", ticket_id
        )

        if before_id:
            # Get the created_at of the before_id message for cursor pagination
            before_result = db.client.table("live_chat_messages").select("created_at").eq(
                "id", before_id
            ).execute()
            if before_result.data:
                query = query.lt("created_at", before_result.data[0]["created_at"])

        result = query.order("created_at", desc=False).limit(limit).execute()

        messages = [_parse_live_chat_message(row) for row in (result.data or [])]

        logger.info(f"Retrieved {len(messages)} messages for ticket {ticket_id}")
        return messages

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get messages: {e}")
        raise safe_internal_error(e, "live_chat")


# =============================================================================
# Check Availability
# =============================================================================

@router.get("/availability", response_model=AvailabilityResponse)
async def check_availability(
    current_user: dict = Depends(get_current_user),
):
    """
    Check if live chat support is available.

    Returns whether any agents are online and estimated wait time.
    """
    logger.info("Checking live chat availability")

    try:
        agents_online = await _get_agents_online_count()
        is_available = agents_online > 0

        # Get current queue size to estimate wait
        db = get_supabase_db()
        queue_result = db.client.table("live_chat_queue").select(
            "id", count="exact"
        ).execute()

        queue_size = queue_result.count or 0

        estimated_wait = None
        if is_available and queue_size > 0:
            estimated_wait = int((queue_size / agents_online) * AVERAGE_CHAT_DURATION_MINUTES)
            estimated_wait = max(1, estimated_wait)
        elif is_available:
            estimated_wait = 1  # Immediate if no queue

        operating_hours = None
        if not is_available:
            # Could fetch from config, hardcoded for now
            operating_hours = "9 AM - 6 PM EST, Monday - Friday"

        return AvailabilityResponse(
            is_available=is_available,
            agents_online_count=agents_online,
            estimated_wait_minutes=estimated_wait,
            operating_hours=operating_hours,
        )

    except Exception as e:
        logger.error(f"Failed to check availability: {e}")
        # Return unavailable on error rather than failing
        return AvailabilityResponse(
            is_available=False,
            agents_online_count=0,
            estimated_wait_minutes=None,
            operating_hours="Unable to determine availability. Please try again later.",
        )
