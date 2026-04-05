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
from core.db import get_supabase_db
from .live_chat_endpoints import router as _endpoints_router


from fastapi import APIRouter, HTTPException, Depends, Header, Request
from typing import Optional, List
from datetime import datetime, timedelta

from core.supabase_db import get_supabase_db
from core.supabase_client import get_supabase
from core.logger import get_logger
from core.exceptions import safe_internal_error
from core.rate_limiter import limiter
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
        supabase = get_supabase().client

        # Get user from token
        user_response = supabase.auth.get_user(token)

        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")

        user_id = user_response.user.id

        # Get user details including role from database
        # SECURITY: Only fetch needed columns — avoid exposing sensitive data
        db = get_supabase_db()

        result = db.client.table("users").select("id, email, name, role, avatar_url, created_at").eq("id", user_id).execute()

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
@limiter.limit("5/minute")
async def admin_login(request: Request, payload: AdminLoginRequest):
    """
    Admin login endpoint.

    Authenticates the admin via Supabase and verifies they have an admin role.
    Returns session tokens and admin profile.
    """
    logger.info(f"Admin login attempt for: {payload.email}")

    try:
        supabase = get_supabase().client

        # Authenticate with Supabase
        auth_response = supabase.auth.sign_in_with_password({
            "email": payload.email,
            "password": payload.password,
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
            logger.warning(f"Non-admin login attempt: {payload.email}, role: {role}")
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
            message=f"Admin logged in: {payload.email}",
            metadata={"role": role},
            status_code=200
        )

        logger.info(f"Admin login successful: {payload.email}, role: {role}")

        return AdminLoginResponse(
            success=True,
            access_token=session.access_token,
            refresh_token=session.refresh_token,
            admin_id=user_id,
            admin_name=user_data.get("name", user_data.get("display_name", "Admin")),
            admin_email=user_data.get("email", payload.email),
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
        # Note: Using users!user_id syntax for PostgREST to infer the FK relationship
        query = db.client.table("support_tickets").select(
            "*, users!user_id(name, email)"
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
        raise safe_internal_error(e, "admin_live_chat")


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
            "*, users!user_id(name, email, avatar_url, subscription_status, created_at)"
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
        raise safe_internal_error(e, "admin_live_chat")


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
        raise safe_internal_error(e, "admin_live_chat")


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
        raise safe_internal_error(e, "admin_live_chat")


# =============================================================================
# Close Live Chat
# =============================================================================


# Include secondary endpoints
router.include_router(_endpoints_router)
