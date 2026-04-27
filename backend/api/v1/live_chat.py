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
from core import branding
from core.db import get_supabase_db
from .live_chat_endpoints import router as _endpoints_router


from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import List, Optional
from datetime import datetime
import asyncio
import httpx

from core.config import get_settings
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
        logger.warning(f"Failed to get queue position: {e}", exc_info=True)
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
        logger.warning(f"Failed to get agents online count: {e}", exc_info=True)
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
    Send webhook notification to admins via Discord and/or email.

    Sends a rich embed to Discord and optionally an email via Resend.
    Gracefully handles failures — never breaks the user flow.
    """
    logger.info(f"[Admin Webhook] {event_type}: {message}")
    logger.info(f"  - Ticket: {ticket_id}")
    logger.info(f"  - User: {user_id}")
    if metadata:
        logger.info(f"  - Metadata: {metadata}")

    settings = get_settings()
    metadata = metadata or {}

    # --- Discord Webhook ---
    if settings.discord_webhook_url:
        try:
            category = metadata.get("category", "General")
            queue_position = metadata.get("queue_position", "N/A")
            escalated = metadata.get("escalated_from_ai", False)
            preview = metadata.get("initial_message_preview", metadata.get("preview", ""))

            # Choose color by event type
            color_map = {
                "live_chat_started": 0x00E5FF,   # cyan
                "live_chat_escalated": 0xFFA726,  # orange
                "live_chat_message": 0x66BB6A,    # green
            }
            color = color_map.get(event_type, 0x9E9E9E)

            # Choose title emoji by event type
            title_map = {
                "live_chat_started": "New Live Chat Request",
                "live_chat_escalated": "Ticket Escalated to Live Chat",
                "live_chat_message": "New Message from User",
            }
            title = title_map.get(event_type, event_type.replace("_", " ").title())

            fields = [
                {"name": "Ticket", "value": f"`#{ticket_id[:8]}`", "inline": True},
                {"name": "Category", "value": category.replace("_", " ").title(), "inline": True},
                {"name": "Queue Position", "value": str(queue_position), "inline": True},
            ]

            if escalated:
                fields.append({"name": "Escalated from AI", "value": "Yes", "inline": True})

            if preview:
                fields.append({"name": "Message Preview", "value": preview[:200], "inline": False})

            embed = {
                "title": f"\U0001f514 {title}",
                "color": color,
                "fields": fields,
                "footer": {"text": f"User: {user_id[:8]}..."},
                "timestamp": datetime.utcnow().isoformat(),
            }

            payload = {"embeds": [embed]}

            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.post(settings.discord_webhook_url, json=payload)
                if resp.status_code in (200, 204):
                    logger.info(f"Discord webhook sent for {event_type} (ticket={ticket_id[:8]})")
                else:
                    logger.warning(f"Discord webhook returned {resp.status_code}: {resp.text[:200]}")

        except Exception as e:
            logger.error(f"Discord webhook failed: {e}", exc_info=True)

    # --- Email Notification (optional fallback) ---
    if settings.admin_notification_email:
        try:
            from services.email_service import EmailService
            email_svc = EmailService()
            if email_svc.is_configured():
                import resend
                category = metadata.get("category", "General")
                queue_position = metadata.get("queue_position", "N/A")

                subject = f"[{branding.APP_NAME}] {event_type.replace('_', ' ').title()} — #{ticket_id[:8]}"
                html_body = f"""
                <h2>{event_type.replace('_', ' ').title()}</h2>
                <p><strong>Ticket:</strong> #{ticket_id[:8]}</p>
                <p><strong>Category:</strong> {category}</p>
                <p><strong>Queue Position:</strong> {queue_position}</p>
                <p><strong>User:</strong> {user_id}</p>
                <p><strong>Message:</strong> {message}</p>
                """

                resend.Emails.send({
                    "from": email_svc.from_email,
                    "to": [settings.admin_notification_email],
                    "subject": subject,
                    "html": html_body,
                })
                logger.info(f"Admin email sent to {settings.admin_notification_email}")
        except Exception as e:
            logger.error(f"Admin email notification failed: {e}", exc_info=True)

    if not settings.discord_webhook_url and not settings.admin_notification_email:
        logger.warning("No admin notification channels configured (set DISCORD_WEBHOOK_URL or ADMIN_NOTIFICATION_EMAIL)")


async def _check_if_user_is_agent(user_id: str) -> bool:
    """Check if the user is an admin/agent."""
    try:
        db = get_supabase_db()

        result = db.client.table("users").select("role").eq("id", user_id).execute()

        if result.data and result.data[0].get("role") in ["admin", "support"]:
            return True

        return False

    except Exception as e:
        logger.warning(f"Failed to check user role: {e}", exc_info=True)
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
            raise safe_internal_error(ValueError("Failed to create live chat session"), "live_chat")

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
            raise safe_internal_error(ValueError("Failed to add initial message"), "live_chat")

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
        logger.error(f"Failed to start live chat: {e}", exc_info=True)
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
        logger.error(f"Failed to escalate ticket to live chat: {e}", exc_info=True)
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
        logger.error(f"Failed to get queue position: {e}", exc_info=True)
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
            raise safe_internal_error(ValueError("Failed to send message"), "live_chat")

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
        logger.error(f"Failed to send message: {e}", exc_info=True)
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


# Include secondary endpoints
router.include_router(_endpoints_router)
