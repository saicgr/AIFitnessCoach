"""
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

from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import Optional
from datetime import datetime
import asyncio

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.live_chat import (
    LiveChatStartRequest,
    LiveChatStartResponse,
    LiveChatMessageRequest,
    LiveChatMessageResponse,
    LiveChatTypingRequest,
    LiveChatTypingResponse,
    LiveChatReadRequest,
    LiveChatReadResponse,
    LiveChatEndRequest,
    LiveChatEndResponse,
    LiveChatEscalateRequest,
    LiveChatEscalateResponse,
    QueuePositionResponse,
    AvailabilityResponse,
    LiveChatMessage,
    LiveChatStatus,
    MessageSenderRole,
)
from models.support import TicketStatus, TicketPriority
from services.user_context_service import user_context_service, EventType

router = APIRouter()
logger = get_logger(__name__)

# Average handling time per chat in minutes (for wait time estimation)
AVERAGE_CHAT_DURATION_MINUTES = 10


# =============================================================================
# Helper Functions
# =============================================================================

def _parse_live_chat_message(data: dict) -> LiveChatMessage:
    """Parse database row to LiveChatMessage model."""
    return LiveChatMessage(
        id=str(data["id"]),
        ticket_id=str(data["ticket_id"]),
        sender_role=MessageSenderRole(data["sender_role"]),
        sender_id=data["sender_id"],
        message=data["message"],
        created_at=data.get("created_at") or datetime.utcnow(),
        read_at=data.get("read_at"),
        is_system_message=data.get("is_system_message", False),
    )


async def _get_queue_position(ticket_id: str) -> int:
    """Get current queue position for a ticket."""
    try:
        db = get_supabase_db()

        # Get the ticket's queue entry
        entry_result = db.client.table("live_chat_queue").select("created_at").eq(
            "ticket_id", ticket_id
        ).execute()

        if not entry_result.data:
            return 0

        created_at = entry_result.data[0]["created_at"]

        # Count how many entries are ahead in queue
        count_result = db.client.table("live_chat_queue").select(
            "id", count="exact"
        ).lt("created_at", created_at).execute()

        return (count_result.count or 0) + 1

    except Exception as e:
        logger.warning(f"Failed to get queue position: {e}")
        return 0


async def _get_agents_online_count() -> int:
    """Get count of online agents."""
    try:
        db = get_supabase_db()

        # Check admin_presence table for online agents
        # Agents are considered online if last_seen is within 5 minutes
        result = db.client.table("admin_presence").select(
            "id", count="exact"
        ).eq("is_online", True).execute()

        return result.count or 0

    except Exception as e:
        logger.warning(f"Failed to get agents online count: {e}")
        return 0


async def _estimate_wait_minutes(queue_position: int) -> Optional[int]:
    """Estimate wait time based on queue position and agents online."""
    agents_online = await _get_agents_online_count()

    if agents_online == 0:
        return None  # Cannot estimate if no agents

    # Simple estimation: (queue_position / agents_online) * avg_chat_duration
    estimated_minutes = int((queue_position / agents_online) * AVERAGE_CHAT_DURATION_MINUTES)
    return max(1, estimated_minutes)  # At least 1 minute


async def _send_admin_webhook(
    event_type: str,
    ticket_id: str,
    user_id: str,
    message: str,
    metadata: dict = None
) -> None:
    """
    Send webhook notification to admins.

    This is a placeholder that will be implemented later.
    Currently just logs the event.
    """
    logger.info(f"[Admin Webhook] {event_type}: {message}")
    logger.info(f"  - Ticket: {ticket_id}")
    logger.info(f"  - User: {user_id}")
    if metadata:
        logger.info(f"  - Metadata: {metadata}")

    # TODO: Implement actual webhook call
    # Will be connected to Discord/Slack or custom admin panel


async def _check_if_user_is_agent(user_id: str) -> bool:
    """Check if the user is an admin/agent."""
    try:
        db = get_supabase_db()

        result = db.client.table("users").select("role").eq("id", user_id).execute()

        if result.data and result.data[0].get("role") in ["admin", "support"]:
            return True

        return False

    except Exception as e:
        logger.warning(f"Failed to check user role: {e}")
        return False


# =============================================================================
# Start Live Chat Session
# =============================================================================

@router.post("/start", response_model=LiveChatStartResponse)
async def start_live_chat(request: LiveChatStartRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Start a new live chat session.

    Creates a support ticket with chat_mode='live_chat' and adds the user to the queue.
    Notifies available agents via webhook.

    Returns the ticket ID, queue position, and estimated wait time.
    """
    logger.info(f"Starting live chat for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Create support ticket with live_chat mode
        ticket_record = {
            "user_id": request.user_id,
            "subject": f"Live Chat - {request.category.value.replace('_', ' ').title()}",
            "category": request.category.value,
            "priority": TicketPriority.HIGH.value,  # Live chats are high priority
            "status": TicketStatus.OPEN.value,
            "chat_mode": "live_chat",
            "escalated_from_ai": request.escalated_from_ai,
            "ai_handoff_context": request.ai_handoff_context,
        }

        ticket_result = db.client.table("support_tickets").insert(ticket_record).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=500, detail="Failed to create live chat session")

        ticket_data = ticket_result.data[0]
        ticket_id = str(ticket_data["id"])

        # Add initial message
        message_record = {
            "ticket_id": ticket_id,
            "sender_role": MessageSenderRole.USER.value,
            "sender_id": request.user_id,
            "message": request.initial_message,
            "is_system_message": False,
        }

        message_result = db.client.table("live_chat_messages").insert(message_record).execute()

        if not message_result.data:
            # Rollback ticket creation
            db.client.table("support_tickets").delete().eq("id", ticket_id).execute()
            raise HTTPException(status_code=500, detail="Failed to add initial message")

        # Add to live chat queue
        queue_record = {
            "ticket_id": ticket_id,
            "user_id": request.user_id,
            "category": request.category.value,
            "escalated_from_ai": request.escalated_from_ai,
        }

        queue_result = db.client.table("live_chat_queue").insert(queue_record).execute()

        if not queue_result.data:
            logger.warning(f"Failed to add ticket {ticket_id} to queue, but chat was created")

        # Get queue position and estimate wait time
        queue_position = await _get_queue_position(ticket_id)
        estimated_wait = await _estimate_wait_minutes(queue_position)

        # Send webhook to notify admins
        await _send_admin_webhook(
            event_type="live_chat_started",
            ticket_id=ticket_id,
            user_id=request.user_id,
            message=f"New live chat request: {request.category.value}",
            metadata={
                "category": request.category.value,
                "escalated_from_ai": request.escalated_from_ai,
                "queue_position": queue_position,
                "initial_message_preview": request.initial_message[:100],
            }
        )

        # Log to user context
        await user_context_service.log_event(
            user_id=request.user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "live_chat",
                "action": "started",
                "ticket_id": ticket_id,
                "category": request.category.value,
                "escalated_from_ai": request.escalated_from_ai,
            },
            context={
                "queue_position": queue_position,
            },
        )

        # Log activity
        await log_user_activity(
            user_id=request.user_id,
            action="live_chat_started",
            endpoint="/api/v1/live-chat/start",
            message=f"Started live chat session",
            metadata={
                "ticket_id": ticket_id,
                "category": request.category.value,
                "escalated_from_ai": request.escalated_from_ai,
                "queue_position": queue_position,
            },
            status_code=200
        )

        logger.info(f"Live chat session created: {ticket_id}, queue position: {queue_position}")

        return LiveChatStartResponse(
            ticket_id=ticket_id,
            queue_position=queue_position,
            estimated_wait_minutes=estimated_wait,
            status=LiveChatStatus.QUEUED,
            message=f"You are #{queue_position} in the queue. Estimated wait: {estimated_wait or 'Unknown'} minutes."
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to start live chat: {e}")
        await log_user_error(
            user_id=request.user_id,
            action="live_chat_started",
            error=e,
            endpoint="/api/v1/live-chat/start",
            metadata={"category": request.category.value},
            status_code=500
        )
        raise safe_internal_error(e, "live_chat")


# =============================================================================
# Escalate Existing Ticket to Live Chat
# =============================================================================

@router.post("/escalate/{ticket_id}", response_model=LiveChatEscalateResponse)
async def escalate_to_live_chat(ticket_id: str, request: LiveChatEscalateRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Escalate an existing support ticket to live chat mode.

    Converts the ticket to live_chat mode and adds it to the queue.
    Preserves the AI handoff context for the agent.
    """
    logger.info(f"Escalating ticket {ticket_id} to live chat for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists and belongs to user
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).eq("user_id", request.user_id).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]

        # Check if already in live chat mode
        if ticket_data.get("chat_mode") == "live_chat":
            # Already escalated, just return current queue position
            queue_position = await _get_queue_position(ticket_id)
            estimated_wait = await _estimate_wait_minutes(queue_position)

            return LiveChatEscalateResponse(
                success=True,
                ticket_id=ticket_id,
                queue_position=queue_position,
                estimated_wait_minutes=estimated_wait,
                status=LiveChatStatus.QUEUED,
            )

        # Update ticket to live chat mode
        update_data = {
            "chat_mode": "live_chat",
            "escalated_from_ai": True,
            "ai_handoff_context": request.ai_handoff_context,
            "priority": TicketPriority.HIGH.value,  # Escalated chats are high priority
            "updated_at": datetime.utcnow().isoformat(),
        }

        db.client.table("support_tickets").update(update_data).eq("id", ticket_id).execute()

        # Add to live chat queue
        queue_record = {
            "ticket_id": ticket_id,
            "user_id": request.user_id,
            "category": ticket_data["category"],
            "escalated_from_ai": True,
        }

        db.client.table("live_chat_queue").insert(queue_record).execute()

        # Get queue position
        queue_position = await _get_queue_position(ticket_id)
        estimated_wait = await _estimate_wait_minutes(queue_position)

        # Add system message about escalation
        system_message = {
            "ticket_id": ticket_id,
            "sender_role": MessageSenderRole.AGENT.value,
            "sender_id": "system",
            "message": "This conversation has been escalated to a human support agent. Please wait while we connect you.",
            "is_system_message": True,
        }

        db.client.table("live_chat_messages").insert(system_message).execute()

        # Send webhook to notify admins
        await _send_admin_webhook(
            event_type="live_chat_escalated",
            ticket_id=ticket_id,
            user_id=request.user_id,
            message=f"Ticket escalated from AI: {ticket_data['subject']}",
            metadata={
                "category": ticket_data["category"],
                "queue_position": queue_position,
                "has_ai_context": bool(request.ai_handoff_context),
            }
        )

        # Log to user context
        await user_context_service.log_event(
            user_id=request.user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "live_chat",
                "action": "escalated",
                "ticket_id": ticket_id,
            },
            context={
                "queue_position": queue_position,
            },
        )

        # Log activity
        await log_user_activity(
            user_id=request.user_id,
            action="live_chat_escalated",
            endpoint=f"/api/v1/live-chat/escalate/{ticket_id}",
            message="Escalated ticket to live chat",
            metadata={
                "ticket_id": ticket_id,
                "queue_position": queue_position,
            },
            status_code=200
        )

        logger.info(f"Ticket {ticket_id} escalated to live chat, queue position: {queue_position}")

        return LiveChatEscalateResponse(
            success=True,
            ticket_id=ticket_id,
            queue_position=queue_position,
            estimated_wait_minutes=estimated_wait,
            status=LiveChatStatus.QUEUED,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to escalate ticket to live chat: {e}")
        await log_user_error(
            user_id=request.user_id,
            action="live_chat_escalated",
            error=e,
            endpoint=f"/api/v1/live-chat/escalate/{ticket_id}",
            metadata={"ticket_id": ticket_id},
            status_code=500
        )
        raise safe_internal_error(e, "live_chat")


# =============================================================================
# Get Queue Position
# =============================================================================

@router.get("/queue-position/{ticket_id}", response_model=QueuePositionResponse)
async def get_queue_position(ticket_id: str, user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get current queue position for a live chat session.

    Returns the current position in queue and estimated wait time.
    """
    logger.info(f"Getting queue position for ticket {ticket_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists and belongs to user
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).eq("user_id", user_id).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]

        # Determine status
        status = LiveChatStatus.QUEUED
        if ticket_data.get("status") == "resolved" or ticket_data.get("status") == "closed":
            status = LiveChatStatus.ENDED
        elif ticket_data.get("assigned_to"):
            status = LiveChatStatus.ACTIVE

        queue_position = 0
        estimated_wait = None

        if status == LiveChatStatus.QUEUED:
            queue_position = await _get_queue_position(ticket_id)
            estimated_wait = await _estimate_wait_minutes(queue_position)

        agents_online = await _get_agents_online_count()

        return QueuePositionResponse(
            ticket_id=ticket_id,
            queue_position=queue_position,
            estimated_wait_minutes=estimated_wait,
            status=status,
            agents_online=agents_online,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get queue position: {e}")
        raise safe_internal_error(e, "live_chat")


# =============================================================================
# Send Message
# =============================================================================

@router.post("/{ticket_id}/message", response_model=LiveChatMessageResponse)
async def send_message(ticket_id: str, request: LiveChatMessageRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Send a message in a live chat session.

    Works for both users and agents. The sender role is determined by checking
    if the user is an agent/admin or by the provided sender_role.
    """
    logger.info(f"Sending message to ticket {ticket_id} from user {request.user_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Ticket not found")

        ticket_data = ticket_result.data[0]

        # Check if ticket is closed
        if ticket_data.get("status") in ["closed", "resolved"]:
            raise HTTPException(status_code=400, detail="Cannot send message to a closed chat")

        # Determine sender role
        sender_role = request.sender_role
        if not sender_role:
            is_agent = await _check_if_user_is_agent(request.user_id)
            sender_role = MessageSenderRole.AGENT if is_agent else MessageSenderRole.USER

        # Verify user can send to this ticket
        if sender_role == MessageSenderRole.USER and ticket_data["user_id"] != request.user_id:
            raise HTTPException(status_code=403, detail="Not authorized to send messages to this chat")

        # Create message
        message_record = {
            "ticket_id": ticket_id,
            "sender_role": sender_role.value,
            "sender_id": request.user_id,
            "message": request.message,
            "is_system_message": False,
        }

        message_result = db.client.table("live_chat_messages").insert(message_record).execute()

        if not message_result.data:
            raise HTTPException(status_code=500, detail="Failed to send message")

        message_data = message_result.data[0]

        # Update ticket's updated_at
        db.client.table("support_tickets").update({
            "updated_at": datetime.utcnow().isoformat()
        }).eq("id", ticket_id).execute()

        # Clear typing indicator
        typing_field = "agent_typing" if sender_role == MessageSenderRole.AGENT else "user_typing"
        db.client.table("live_chat_queue").update({
            typing_field: False
        }).eq("ticket_id", ticket_id).execute()

        # Send webhook notification to other party
        if sender_role == MessageSenderRole.USER:
            # Notify agent
            await _send_admin_webhook(
                event_type="live_chat_message",
                ticket_id=ticket_id,
                user_id=request.user_id,
                message="New message from user",
                metadata={"preview": request.message[:100]}
            )

        # Log activity
        await log_user_activity(
            user_id=request.user_id,
            action="live_chat_message",
            endpoint=f"/api/v1/live-chat/{ticket_id}/message",
            message="Sent live chat message",
            metadata={
                "ticket_id": ticket_id,
                "sender_role": sender_role.value,
            },
            status_code=200
        )

        logger.info(f"Message sent to ticket {ticket_id}")

        return LiveChatMessageResponse(
            success=True,
            message=_parse_live_chat_message(message_data),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to send message: {e}")
        await log_user_error(
            user_id=request.user_id,
            action="live_chat_message",
            error=e,
            endpoint=f"/api/v1/live-chat/{ticket_id}/message",
            metadata={"ticket_id": ticket_id},
            status_code=500
        )
        raise safe_internal_error(e, "live_chat")


# =============================================================================
# Typing Indicator
# =============================================================================

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
