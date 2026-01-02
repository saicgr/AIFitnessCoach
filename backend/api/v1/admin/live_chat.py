"""
Admin Live Chat API endpoints.

Provides admin-specific functionality for:
- Admin authentication (login with role verification)
- Viewing and managing live chat tickets
- Replying to users as support agents
- Assigning and closing chats
- Dashboard statistics and monitoring
- Agent presence tracking
- Support ticket and report management
"""

from fastapi import APIRouter, HTTPException, Depends, Header
from typing import Optional, List
from datetime import datetime, timedelta

from core.supabase_db import get_supabase_db
from core.supabase_client import get_supabase_client
from core.logger import get_logger
from core.activity_logger import log_user_activity
from models.admin import (
    AdminLoginRequest,
    AdminLoginResponse,
    AdminProfile,
    AdminRole,
    LiveChatTicketSummary,
    LiveChatTicketDetail,
    LiveChatListResponse,
    AdminReplyRequest,
    AdminReplyResponse,
    AssignChatRequest,
    AssignChatResponse,
    CloseChatRequest,
    CloseChatResponse,
    SupportTicketAdminSummary,
    SupportTicketListResponse,
    ChatReportAdminSummary,
    ChatReportListResponse,
    DashboardStats,
    AgentStatus,
    PresenceUpdateRequest,
    PresenceUpdateResponse,
)
from models.live_chat import LiveChatMessage, LiveChatStatus, MessageSenderRole
from models.support import TicketStatus, TicketPriority, TicketCategory
from services.notification_service import NotificationService

router = APIRouter()
logger = get_logger(__name__)

# Notification service for push notifications
_notification_service: Optional[NotificationService] = None


def get_notification_service() -> NotificationService:
    """Get or create notification service singleton."""
    global _notification_service
    if _notification_service is None:
        try:
            _notification_service = NotificationService()
        except Exception as e:
            logger.warning(f"Failed to initialize notification service: {e}")
    return _notification_service


# =============================================================================
# Authentication Helpers
# =============================================================================

async def verify_admin_token(authorization: str = Header(...)) -> AdminProfile:
    """
    Verify the admin's authentication token and return their profile.

    Raises HTTPException 401 if token is invalid or user is not an admin.
    """
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header format")

        token = authorization.replace("Bearer ", "")

        # Use Supabase to verify the token and get user
        supabase = get_supabase_client()

        # Get user from token
        user_response = supabase.auth.get_user(token)

        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")

        user_id = user_response.user.id

        # Get user details including role from database
        db = get_supabase_db()

        result = db.client.table("users").select("*").eq("id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=401, detail="User not found")

        user_data = result.data[0]
        role = user_data.get("role", "user")

        # Verify admin role
        if role not in ["admin", "super_admin", "support"]:
            raise HTTPException(status_code=403, detail="Insufficient permissions. Admin role required.")

        # Get active chats count for this admin
        active_chats_result = db.client.table("support_tickets").select(
            "id", count="exact"
        ).eq("assigned_to", user_id).in_(
            "status", ["open", "in_progress"]
        ).execute()

        active_chats_count = active_chats_result.count or 0

        return AdminProfile(
            id=user_id,
            email=user_data.get("email", ""),
            name=user_data.get("name", user_data.get("display_name", "Admin")),
            role=AdminRole(role) if role in [r.value for r in AdminRole] else AdminRole.SUPPORT,
            is_online=True,
            last_seen=datetime.utcnow(),
            avatar_url=user_data.get("avatar_url"),
            created_at=user_data.get("created_at") or datetime.utcnow(),
            active_chats_count=active_chats_count,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        raise HTTPException(status_code=401, detail="Authentication failed")


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


def _parse_live_chat_summary(data: dict) -> LiveChatTicketSummary:
    """Parse database row to LiveChatTicketSummary model."""
    # Determine chat status from ticket status and queue presence
    chat_status = LiveChatStatus.QUEUED
    if data.get("status") in ["resolved", "closed"]:
        chat_status = LiveChatStatus.ENDED
    elif data.get("assigned_to"):
        chat_status = LiveChatStatus.ACTIVE

    return LiveChatTicketSummary(
        id=str(data["id"]),
        user_id=data["user_id"],
        user_name=data.get("user_name"),
        user_email=data.get("user_email"),
        subject=data.get("subject", "Live Chat"),
        category=TicketCategory(data["category"]) if data.get("category") else TicketCategory.OTHER,
        priority=TicketPriority(data["priority"]) if data.get("priority") else TicketPriority.MEDIUM,
        status=TicketStatus(data["status"]) if data.get("status") else TicketStatus.OPEN,
        chat_status=chat_status,
        created_at=data.get("created_at") or datetime.utcnow(),
        updated_at=data.get("updated_at") or datetime.utcnow(),
        escalated_from_ai=data.get("escalated_from_ai", False),
        agent_id=data.get("assigned_to"),
        agent_name=data.get("agent_name"),
        unread_count=data.get("unread_count", 0),
        last_message_preview=data.get("last_message_preview"),
        last_message_at=data.get("last_message_at"),
        queue_position=data.get("queue_position"),
    )


async def _send_push_notification_to_user(
    user_id: str,
    title: str,
    body: str,
    data: dict = None
) -> bool:
    """Send a push notification to a user."""
    try:
        db = get_supabase_db()

        # Get user's FCM token
        token_result = db.client.table("user_devices").select(
            "fcm_token"
        ).eq("user_id", user_id).eq("notifications_enabled", True).order(
            "updated_at", desc=True
        ).limit(1).execute()

        if not token_result.data:
            logger.info(f"No FCM token found for user {user_id}")
            return False

        fcm_token = token_result.data[0]["fcm_token"]

        notification_service = get_notification_service()
        if not notification_service:
            return False

        success = await notification_service.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type="live_chat",
            data=data or {},
        )

        return success

    except Exception as e:
        logger.error(f"Failed to send push notification: {e}")
        return False


# =============================================================================
# Admin Login
# =============================================================================

@router.post("/login", response_model=AdminLoginResponse)
async def admin_login(request: AdminLoginRequest):
    """
    Admin login endpoint.

    Authenticates the admin via Supabase and verifies they have an admin role.
    Returns session tokens and admin profile.
    """
    logger.info(f"Admin login attempt for: {request.email}")

    try:
        supabase = get_supabase_client()

        # Authenticate with Supabase
        auth_response = supabase.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password,
        })

        if not auth_response or not auth_response.user:
            raise HTTPException(status_code=401, detail="Invalid email or password")

        user_id = auth_response.user.id
        session = auth_response.session

        # Get user details including role
        db = get_supabase_db()

        result = db.client.table("users").select("*").eq("id", user_id).execute()

        if not result.data:
            raise HTTPException(status_code=401, detail="User not found")

        user_data = result.data[0]
        role = user_data.get("role", "user")

        # Verify admin role
        if role not in ["admin", "super_admin", "support"]:
            logger.warning(f"Non-admin login attempt: {request.email}, role: {role}")
            raise HTTPException(
                status_code=403,
                detail="Access denied. Admin, super_admin, or support role required."
            )

        # Update presence to online
        db.client.table("admin_presence").upsert({
            "admin_id": user_id,
            "is_online": True,
            "last_seen": datetime.utcnow().isoformat(),
        }).execute()

        # Log the login
        await log_user_activity(
            user_id=user_id,
            action="admin_login",
            endpoint="/api/v1/admin/login",
            message=f"Admin logged in: {request.email}",
            metadata={"role": role},
            status_code=200
        )

        logger.info(f"Admin login successful: {request.email}, role: {role}")

        return AdminLoginResponse(
            success=True,
            access_token=session.access_token,
            refresh_token=session.refresh_token,
            admin_id=user_id,
            admin_name=user_data.get("name", user_data.get("display_name", "Admin")),
            admin_email=user_data.get("email", request.email),
            role=AdminRole(role) if role in [r.value for r in AdminRole] else AdminRole.SUPPORT,
            expires_at=datetime.utcnow() + timedelta(hours=24),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Admin login failed: {e}")
        raise HTTPException(status_code=401, detail="Authentication failed")


# =============================================================================
# Live Chat List
# =============================================================================

@router.get("/live-chats", response_model=LiveChatListResponse)
async def get_live_chats(
    status: Optional[str] = None,
    category: Optional[str] = None,
    agent_id: Optional[str] = None,
    sort_by: str = "created_at",
    sort_order: str = "desc",
    page: int = 1,
    page_size: int = 20,
    admin: AdminProfile = Depends(verify_admin_token),
):
    """
    Get list of all active live chat tickets.

    Supports filtering by status, category, and assigned agent.
    Includes unread message count and queue position.
    """
    logger.info(f"Admin {admin.id} fetching live chats")

    try:
        db = get_supabase_db()

        # Build query for live chat tickets
        query = db.client.table("support_tickets").select(
            "*, users!support_tickets_user_id_fkey(name, email)"
        ).eq("chat_mode", "live_chat")

        # Apply filters
        if status:
            if status == "queued":
                query = query.is_("assigned_to", "null").neq("status", "resolved").neq("status", "closed")
            elif status == "active":
                query = query.not_.is_("assigned_to", "null").neq("status", "resolved").neq("status", "closed")
            elif status == "ended":
                query = query.in_("status", ["resolved", "closed"])
            else:
                query = query.eq("status", status)

        if category:
            query = query.eq("category", category)

        if agent_id:
            query = query.eq("assigned_to", agent_id)

        # Sorting
        valid_sort_fields = ["created_at", "updated_at", "priority"]
        if sort_by not in valid_sort_fields:
            sort_by = "created_at"

        query = query.order(sort_by, desc=(sort_order == "desc"))

        # Get total count
        count_result = db.client.table("support_tickets").select(
            "id", count="exact"
        ).eq("chat_mode", "live_chat")

        if status and status not in ["queued", "active", "ended"]:
            count_result = count_result.eq("status", status)
        if category:
            count_result = count_result.eq("category", category)
        if agent_id:
            count_result = count_result.eq("assigned_to", agent_id)

        count_result = count_result.execute()
        total = count_result.count or 0

        # Pagination
        offset = (page - 1) * page_size
        query = query.range(offset, offset + page_size - 1)

        result = query.execute()

        chats = []
        for row in result.data or []:
            # Get user info from joined data
            user_info = row.get("users", {}) or {}

            # Get unread count for this ticket
            unread_result = db.client.table("live_chat_messages").select(
                "id", count="exact"
            ).eq("ticket_id", row["id"]).eq(
                "sender_role", "user"
            ).is_("read_at", "null").execute()

            unread_count = unread_result.count or 0

            # Get last message
            last_msg_result = db.client.table("live_chat_messages").select(
                "message, created_at"
            ).eq("ticket_id", row["id"]).order("created_at", desc=True).limit(1).execute()

            last_message_preview = None
            last_message_at = None
            if last_msg_result.data:
                msg = last_msg_result.data[0]["message"]
                last_message_preview = msg[:197] + "..." if len(msg) > 200 else msg
                last_message_at = last_msg_result.data[0]["created_at"]

            # Get queue position if in queue
            queue_position = None
            if not row.get("assigned_to") and row["status"] not in ["resolved", "closed"]:
                queue_result = db.client.table("live_chat_queue").select(
                    "created_at"
                ).eq("ticket_id", row["id"]).execute()

                if queue_result.data:
                    entry_time = queue_result.data[0]["created_at"]
                    position_result = db.client.table("live_chat_queue").select(
                        "id", count="exact"
                    ).lt("created_at", entry_time).execute()
                    queue_position = (position_result.count or 0) + 1

            chat_data = {
                **row,
                "user_name": user_info.get("name"),
                "user_email": user_info.get("email"),
                "unread_count": unread_count,
                "last_message_preview": last_message_preview,
                "last_message_at": last_message_at,
                "queue_position": queue_position,
            }

            chats.append(_parse_live_chat_summary(chat_data))

        return LiveChatListResponse(
            chats=chats,
            total=total,
            page=page,
            page_size=page_size,
            has_more=offset + len(chats) < total,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get live chats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Live Chat Detail
# =============================================================================

@router.get("/live-chats/{ticket_id}", response_model=LiveChatTicketDetail)
async def get_live_chat_detail(
    ticket_id: str,
    admin: AdminProfile = Depends(verify_admin_token),
):
    """
    Get full chat history with messages and user info.

    Includes AI handoff context if the chat was escalated from AI.
    """
    logger.info(f"Admin {admin.id} fetching live chat detail: {ticket_id}")

    try:
        db = get_supabase_db()

        # Get ticket with user info
        ticket_result = db.client.table("support_tickets").select(
            "*, users!support_tickets_user_id_fkey(name, email, avatar_url, subscription_status, created_at)"
        ).eq("id", ticket_id).eq("chat_mode", "live_chat").execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Live chat not found")

        ticket_data = ticket_result.data[0]
        user_info = ticket_data.get("users", {}) or {}

        # Get all messages
        messages_result = db.client.table("live_chat_messages").select("*").eq(
            "ticket_id", ticket_id
        ).order("created_at").execute()

        messages = [_parse_live_chat_message(m) for m in messages_result.data or []]

        # Get typing status from queue
        typing_result = db.client.table("live_chat_queue").select(
            "user_typing, agent_typing"
        ).eq("ticket_id", ticket_id).execute()

        user_typing = False
        agent_typing = False
        if typing_result.data:
            user_typing = typing_result.data[0].get("user_typing", False)
            agent_typing = typing_result.data[0].get("agent_typing", False)

        # Get agent name if assigned
        agent_name = None
        if ticket_data.get("assigned_to"):
            agent_result = db.client.table("users").select("name").eq(
                "id", ticket_data["assigned_to"]
            ).execute()
            if agent_result.data:
                agent_name = agent_result.data[0].get("name")

        # Determine chat status
        chat_status = LiveChatStatus.QUEUED
        if ticket_data.get("status") in ["resolved", "closed"]:
            chat_status = LiveChatStatus.ENDED
        elif ticket_data.get("assigned_to"):
            chat_status = LiveChatStatus.ACTIVE

        return LiveChatTicketDetail(
            id=str(ticket_data["id"]),
            user_id=ticket_data["user_id"],
            user_name=user_info.get("name"),
            user_email=user_info.get("email"),
            user_avatar_url=user_info.get("avatar_url"),
            user_subscription_status=user_info.get("subscription_status"),
            user_member_since=user_info.get("created_at"),
            subject=ticket_data.get("subject", "Live Chat"),
            category=TicketCategory(ticket_data["category"]) if ticket_data.get("category") else TicketCategory.OTHER,
            priority=TicketPriority(ticket_data["priority"]) if ticket_data.get("priority") else TicketPriority.MEDIUM,
            status=TicketStatus(ticket_data["status"]) if ticket_data.get("status") else TicketStatus.OPEN,
            chat_status=chat_status,
            created_at=ticket_data.get("created_at") or datetime.utcnow(),
            updated_at=ticket_data.get("updated_at") or datetime.utcnow(),
            resolved_at=ticket_data.get("resolved_at"),
            escalated_from_ai=ticket_data.get("escalated_from_ai", False),
            ai_handoff_context=ticket_data.get("ai_handoff_context"),
            agent_id=ticket_data.get("assigned_to"),
            agent_name=agent_name,
            messages=messages,
            user_typing=user_typing,
            agent_typing=agent_typing,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get live chat detail: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Reply to Live Chat
# =============================================================================

@router.post("/live-chats/{ticket_id}/reply", response_model=AdminReplyResponse)
async def reply_to_live_chat(
    ticket_id: str,
    request: AdminReplyRequest,
    admin: AdminProfile = Depends(verify_admin_token),
):
    """
    Send a message as a support agent.

    Auto-assigns the chat to this agent if not already assigned.
    Triggers push notification to the user.
    """
    logger.info(f"Admin {admin.id} replying to live chat: {ticket_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists and is a live chat
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).eq("chat_mode", "live_chat").execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Live chat not found")

        ticket_data = ticket_result.data[0]

        # Check if chat is closed
        if ticket_data.get("status") in ["resolved", "closed"]:
            raise HTTPException(status_code=400, detail="Cannot reply to a closed chat")

        # Auto-assign if not already assigned
        if not ticket_data.get("assigned_to"):
            db.client.table("support_tickets").update({
                "assigned_to": admin.id,
                "status": TicketStatus.IN_PROGRESS.value,
                "updated_at": datetime.utcnow().isoformat(),
            }).eq("id", ticket_id).execute()

            # Remove from queue
            db.client.table("live_chat_queue").delete().eq("ticket_id", ticket_id).execute()

            # Add system message about assignment
            system_message = {
                "ticket_id": ticket_id,
                "sender_role": MessageSenderRole.AGENT.value,
                "sender_id": "system",
                "message": f"{admin.name} has joined the chat.",
                "is_system_message": True,
            }
            db.client.table("live_chat_messages").insert(system_message).execute()

        # Create the message
        message_record = {
            "ticket_id": ticket_id,
            "sender_role": MessageSenderRole.AGENT.value,
            "sender_id": admin.id,
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

        # Clear agent typing indicator
        db.client.table("live_chat_queue").update({
            "agent_typing": False
        }).eq("ticket_id", ticket_id).execute()

        # Send push notification to user
        notification_sent = await _send_push_notification_to_user(
            user_id=ticket_data["user_id"],
            title="New message from support",
            body=request.message[:100] + ("..." if len(request.message) > 100 else ""),
            data={
                "ticket_id": ticket_id,
                "type": "live_chat_message",
            }
        )

        logger.info(f"Admin reply sent to ticket {ticket_id}, notification: {notification_sent}")

        return AdminReplyResponse(
            success=True,
            message=_parse_live_chat_message(message_data),
            notification_sent=notification_sent,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to reply to live chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Assign Chat to Agent
# =============================================================================

@router.post("/live-chats/{ticket_id}/assign", response_model=AssignChatResponse)
async def assign_chat(
    ticket_id: str,
    request: AssignChatRequest,
    admin: AdminProfile = Depends(verify_admin_token),
):
    """
    Assign a live chat to a specific agent.

    Removes the chat from the queue and notifies the user.
    """
    logger.info(f"Admin {admin.id} assigning chat {ticket_id} to {request.agent_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).eq("chat_mode", "live_chat").execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Live chat not found")

        ticket_data = ticket_result.data[0]

        # Check if chat is closed
        if ticket_data.get("status") in ["resolved", "closed"]:
            raise HTTPException(status_code=400, detail="Cannot assign a closed chat")

        # Get agent name if not provided
        agent_name = request.agent_name
        if not agent_name:
            agent_result = db.client.table("users").select("name").eq(
                "id", request.agent_id
            ).execute()
            if agent_result.data:
                agent_name = agent_result.data[0].get("name", "Support Agent")

        assigned_at = datetime.utcnow()

        # Update ticket
        db.client.table("support_tickets").update({
            "assigned_to": request.agent_id,
            "status": TicketStatus.IN_PROGRESS.value,
            "updated_at": assigned_at.isoformat(),
        }).eq("id", ticket_id).execute()

        # Remove from queue
        db.client.table("live_chat_queue").delete().eq("ticket_id", ticket_id).execute()

        # Add system message about assignment
        system_message = {
            "ticket_id": ticket_id,
            "sender_role": MessageSenderRole.AGENT.value,
            "sender_id": "system",
            "message": f"{agent_name} has been assigned to this chat.",
            "is_system_message": True,
        }
        db.client.table("live_chat_messages").insert(system_message).execute()

        # Send notification to user
        await _send_push_notification_to_user(
            user_id=ticket_data["user_id"],
            title="Agent connected",
            body=f"{agent_name} is now available to help you.",
            data={
                "ticket_id": ticket_id,
                "type": "agent_assigned",
            }
        )

        logger.info(f"Chat {ticket_id} assigned to agent {request.agent_id}")

        return AssignChatResponse(
            success=True,
            ticket_id=ticket_id,
            agent_id=request.agent_id,
            agent_name=agent_name,
            assigned_at=assigned_at,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to assign chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Close Live Chat
# =============================================================================

@router.post("/live-chats/{ticket_id}/close", response_model=CloseChatResponse)
async def close_chat(
    ticket_id: str,
    request: CloseChatRequest,
    admin: AdminProfile = Depends(verify_admin_token),
):
    """
    Close/resolve the live chat.

    Adds a resolution note and updates the ticket status.
    """
    logger.info(f"Admin {admin.id} closing chat {ticket_id}")

    try:
        db = get_supabase_db()

        # Verify ticket exists
        ticket_result = db.client.table("support_tickets").select("*").eq(
            "id", ticket_id
        ).eq("chat_mode", "live_chat").execute()

        if not ticket_result.data:
            raise HTTPException(status_code=404, detail="Live chat not found")

        ticket_data = ticket_result.data[0]

        # Check if already closed
        if ticket_data.get("status") in ["resolved", "closed"]:
            return CloseChatResponse(
                success=True,
                ticket_id=ticket_id,
                closed_at=datetime.utcnow(),
                status=TicketStatus.RESOLVED,
            )

        closed_at = datetime.utcnow()

        # Add system message about closing
        resolution_text = f"This chat has been resolved by {admin.name}."
        if request.resolution_note:
            resolution_text += f" Note: {request.resolution_note}"

        system_message = {
            "ticket_id": ticket_id,
            "sender_role": MessageSenderRole.AGENT.value,
            "sender_id": "system",
            "message": resolution_text,
            "is_system_message": True,
        }
        db.client.table("live_chat_messages").insert(system_message).execute()

        # Update ticket status
        update_data = {
            "status": TicketStatus.RESOLVED.value,
            "resolved_at": closed_at.isoformat(),
            "updated_at": closed_at.isoformat(),
        }

        db.client.table("support_tickets").update(update_data).eq("id", ticket_id).execute()

        # Remove from queue (if somehow still there)
        db.client.table("live_chat_queue").delete().eq("ticket_id", ticket_id).execute()

        # Notify user
        await _send_push_notification_to_user(
            user_id=ticket_data["user_id"],
            title="Chat resolved",
            body="Your support chat has been resolved. Thank you for contacting us!",
            data={
                "ticket_id": ticket_id,
                "type": "chat_resolved",
            }
        )

        logger.info(f"Chat {ticket_id} closed by admin {admin.id}")

        return CloseChatResponse(
            success=True,
            ticket_id=ticket_id,
            closed_at=closed_at,
            status=TicketStatus.RESOLVED,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to close chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Support Tickets List
# =============================================================================

@router.get("/tickets", response_model=SupportTicketListResponse)
async def get_support_tickets(
    status: Optional[str] = None,
    category: Optional[str] = None,
    priority: Optional[str] = None,
    assigned_to: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    admin: AdminProfile = Depends(verify_admin_token),
):
    """
    Get list of all support tickets (not just live chat).

    Supports filtering by status, category, priority, and assignment.
    """
    logger.info(f"Admin {admin.id} fetching support tickets")

    try:
        db = get_supabase_db()

        # Build query
        query = db.client.table("support_tickets").select(
            "*, users!support_tickets_user_id_fkey(name, email)"
        )

        if status:
            query = query.eq("status", status)

        if category:
            query = query.eq("category", category)

        if priority:
            query = query.eq("priority", priority)

        if assigned_to:
            query = query.eq("assigned_to", assigned_to)

        query = query.order("updated_at", desc=True)

        # Get total count
        count_query = db.client.table("support_tickets").select("id", count="exact")
        if status:
            count_query = count_query.eq("status", status)
        if category:
            count_query = count_query.eq("category", category)
        if priority:
            count_query = count_query.eq("priority", priority)
        if assigned_to:
            count_query = count_query.eq("assigned_to", assigned_to)

        count_result = count_query.execute()
        total = count_result.count or 0

        # Pagination
        offset = (page - 1) * page_size
        query = query.range(offset, offset + page_size - 1)

        result = query.execute()

        tickets = []
        for row in result.data or []:
            user_info = row.get("users", {}) or {}

            # Get assigned agent name
            assigned_to_name = None
            if row.get("assigned_to"):
                agent_result = db.client.table("users").select("name").eq(
                    "id", row["assigned_to"]
                ).execute()
                if agent_result.data:
                    assigned_to_name = agent_result.data[0].get("name")

            tickets.append(SupportTicketAdminSummary(
                id=str(row["id"]),
                user_id=row["user_id"],
                user_name=user_info.get("name"),
                user_email=user_info.get("email"),
                subject=row.get("subject", "Support Ticket"),
                category=TicketCategory(row["category"]) if row.get("category") else TicketCategory.OTHER,
                priority=TicketPriority(row["priority"]) if row.get("priority") else TicketPriority.MEDIUM,
                status=TicketStatus(row["status"]) if row.get("status") else TicketStatus.OPEN,
                created_at=row.get("created_at") or datetime.utcnow(),
                updated_at=row.get("updated_at") or datetime.utcnow(),
                message_count=row.get("message_count", 1),
                assigned_to=row.get("assigned_to"),
                assigned_to_name=assigned_to_name,
                last_message_preview=row.get("last_message_preview"),
                last_message_sender=row.get("last_message_sender"),
            ))

        return SupportTicketListResponse(
            tickets=tickets,
            total=total,
            page=page,
            page_size=page_size,
            has_more=offset + len(tickets) < total,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get support tickets: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Chat Reports List
# =============================================================================

@router.get("/reports", response_model=ChatReportListResponse)
async def get_chat_reports(
    status: Optional[str] = None,
    category: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    admin: AdminProfile = Depends(verify_admin_token),
):
    """
    Get list of all chat message reports.

    Supports filtering by status and category.
    """
    logger.info(f"Admin {admin.id} fetching chat reports")

    try:
        db = get_supabase_db()

        # Build query
        query = db.client.table("chat_message_reports").select(
            "*, users!chat_message_reports_user_id_fkey(name)"
        )

        if status:
            query = query.eq("status", status)

        if category:
            query = query.eq("report_category", category)

        query = query.order("created_at", desc=True)

        # Get total count
        count_query = db.client.table("chat_message_reports").select("id", count="exact")
        if status:
            count_query = count_query.eq("status", status)
        if category:
            count_query = count_query.eq("report_category", category)

        count_result = count_query.execute()
        total = count_result.count or 0

        # Pagination
        offset = (page - 1) * page_size
        query = query.range(offset, offset + page_size - 1)

        result = query.execute()

        reports = []
        for row in result.data or []:
            user_info = row.get("users", {}) or {}

            # Truncate previews
            original_msg = row.get("original_user_message", "")
            ai_response = row.get("reported_ai_response", "")

            reports.append(ChatReportAdminSummary(
                id=str(row["id"]),
                user_id=row["user_id"],
                user_name=user_info.get("name"),
                message_id=row["message_id"],
                report_category=row["report_category"],
                status=row["status"],
                created_at=row.get("created_at") or datetime.utcnow(),
                updated_at=row.get("updated_at") or datetime.utcnow(),
                original_user_message_preview=original_msg[:197] + "..." if len(original_msg) > 200 else original_msg,
                reported_ai_response_preview=ai_response[:197] + "..." if len(ai_response) > 200 else ai_response,
                has_ai_analysis=bool(row.get("ai_analysis")),
                reviewed_by=row.get("reviewed_by"),
            ))

        return ChatReportListResponse(
            reports=reports,
            total=total,
            page=page,
            page_size=page_size,
            has_more=offset + len(reports) < total,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get chat reports: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Dashboard Stats
# =============================================================================

@router.get("/dashboard", response_model=DashboardStats)
async def get_dashboard_stats(
    admin: AdminProfile = Depends(verify_admin_token),
):
    """
    Get admin dashboard statistics.

    Returns overview of active chats, queue size, agent status, etc.
    """
    logger.info(f"Admin {admin.id} fetching dashboard stats")

    try:
        db = get_supabase_db()
        today = datetime.utcnow().date()
        today_start = datetime.combine(today, datetime.min.time())

        # Active live chats (assigned and not closed)
        active_chats_result = db.client.table("support_tickets").select(
            "id", count="exact"
        ).eq("chat_mode", "live_chat").not_.is_(
            "assigned_to", "null"
        ).neq("status", "resolved").neq("status", "closed").execute()

        active_live_chats = active_chats_result.count or 0

        # Queued live chats
        queued_result = db.client.table("live_chat_queue").select(
            "id", count="exact"
        ).execute()

        queued_live_chats = queued_result.count or 0

        # Calculate average wait time for queued chats
        avg_wait_time = None
        if queued_live_chats > 0:
            queue_times_result = db.client.table("live_chat_queue").select(
                "created_at"
            ).execute()

            if queue_times_result.data:
                now = datetime.utcnow()
                wait_times = []
                for entry in queue_times_result.data:
                    created = datetime.fromisoformat(
                        entry["created_at"].replace("Z", "+00:00")
                    ).replace(tzinfo=None)
                    wait_minutes = (now - created).total_seconds() / 60
                    wait_times.append(wait_minutes)

                if wait_times:
                    avg_wait_time = sum(wait_times) / len(wait_times)

        # Open support tickets (not live chat)
        open_tickets_result = db.client.table("support_tickets").select(
            "id", count="exact"
        ).neq("chat_mode", "live_chat").in_(
            "status", ["open", "in_progress", "waiting_response"]
        ).execute()

        open_tickets = open_tickets_result.count or 0

        # Pending tickets (waiting for response)
        pending_result = db.client.table("support_tickets").select(
            "id", count="exact"
        ).eq("status", "waiting_response").execute()

        pending_tickets = pending_result.count or 0

        # Resolved today
        resolved_today_result = db.client.table("support_tickets").select(
            "id", count="exact"
        ).gte("resolved_at", today_start.isoformat()).execute()

        resolved_today = resolved_today_result.count or 0

        # Pending reports
        pending_reports_result = db.client.table("chat_message_reports").select(
            "id", count="exact"
        ).eq("status", "pending").execute()

        pending_reports = pending_reports_result.count or 0

        # Chats started today
        chats_today_result = db.client.table("support_tickets").select(
            "id", count="exact"
        ).eq("chat_mode", "live_chat").gte(
            "created_at", today_start.isoformat()
        ).execute()

        chats_started_today = chats_today_result.count or 0

        # Get online agents
        agents_result = db.client.table("admin_presence").select(
            "admin_id, is_online, last_seen"
        ).eq("is_online", True).execute()

        agents_online = len(agents_result.data) if agents_result.data else 0

        # Get total agents
        total_agents_result = db.client.table("users").select(
            "id", count="exact"
        ).in_("role", ["admin", "super_admin", "support"]).execute()

        total_agents = total_agents_result.count or 0

        # Build online agents list with details
        online_agents = []
        for agent_data in agents_result.data or []:
            agent_id = agent_data["admin_id"]

            # Get agent name
            agent_info_result = db.client.table("users").select("name").eq(
                "id", agent_id
            ).execute()

            agent_name = "Unknown Agent"
            if agent_info_result.data:
                agent_name = agent_info_result.data[0].get("name", "Unknown Agent")

            # Get active chats for this agent
            active_for_agent = db.client.table("support_tickets").select(
                "id", count="exact"
            ).eq("assigned_to", agent_id).in_(
                "status", ["open", "in_progress"]
            ).execute()

            # Get chats resolved today by this agent
            resolved_by_agent = db.client.table("support_tickets").select(
                "id", count="exact"
            ).eq("assigned_to", agent_id).gte(
                "resolved_at", today_start.isoformat()
            ).execute()

            online_agents.append(AgentStatus(
                agent_id=agent_id,
                agent_name=agent_name,
                is_online=True,
                last_seen=agent_data.get("last_seen"),
                active_chats=active_for_agent.count or 0,
                chats_resolved_today=resolved_by_agent.count or 0,
            ))

        return DashboardStats(
            active_live_chats=active_live_chats,
            queued_live_chats=queued_live_chats,
            avg_wait_time_minutes=round(avg_wait_time, 1) if avg_wait_time else None,
            avg_response_time_minutes=None,  # Would need more complex calculation
            open_tickets=open_tickets,
            pending_tickets=pending_tickets,
            resolved_today=resolved_today,
            pending_reports=pending_reports,
            agents_online=agents_online,
            total_agents=total_agents,
            chats_started_today=chats_started_today,
            satisfaction_rate=None,  # Would need feedback data
            online_agents=online_agents,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get dashboard stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Update Presence
# =============================================================================

@router.post("/presence", response_model=PresenceUpdateResponse)
async def update_presence(
    request: PresenceUpdateRequest,
    admin: AdminProfile = Depends(verify_admin_token),
):
    """
    Update admin's online status.

    Used to track which agents are available to take chats.
    """
    logger.info(f"Admin {admin.id} updating presence: online={request.is_online}")

    try:
        db = get_supabase_db()

        now = datetime.utcnow()

        # Upsert presence record
        db.client.table("admin_presence").upsert({
            "admin_id": admin.id,
            "is_online": request.is_online,
            "last_seen": now.isoformat(),
            "status_message": request.status_message,
        }).execute()

        return PresenceUpdateResponse(
            success=True,
            admin_id=admin.id,
            is_online=request.is_online,
            last_seen=now,
        )

    except Exception as e:
        logger.error(f"Failed to update presence: {e}")
        raise HTTPException(status_code=500, detail=str(e))
