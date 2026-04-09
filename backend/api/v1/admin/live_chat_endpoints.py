"""Secondary endpoints for live_chat.  Sub-router included by main module.
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
from typing import Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
import logging
logger = logging.getLogger(__name__)
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from fastapi import Header
from models.admin import (
    AdminProfile,
    CloseChatRequest, CloseChatResponse,
    SupportTicketAdminSummary, SupportTicketListResponse,
    ChatReportAdminSummary, ChatReportListResponse,
    DashboardStats, AgentStatus,
    PresenceUpdateRequest, PresenceUpdateResponse,
)
from models.live_chat import LiveChatMessage, LiveChatStatus, MessageSenderRole
from models.admin import AdminRole
from models.support import TicketCategory, TicketPriority, TicketStatus
from core.supabase_client import get_supabase


async def verify_admin_token(authorization: str = Header(...)) -> AdminProfile:
    """Verify admin token - thin re-implementation to avoid circular import."""
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header format")
        token = authorization.replace("Bearer ", "")
        supabase = get_supabase().client
        user_response = supabase.auth.get_user(token)
        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")
        user_id = user_response.user.id
        db = get_supabase_db()
        result = db.client.table("users").select("id, email, name, role, avatar_url, created_at").eq("id", user_id).execute()
        if not result.data:
            raise HTTPException(status_code=401, detail="User not found")
        user_data = result.data[0]
        role = user_data.get("role", "user")
        if role not in ["admin", "super_admin", "support"]:
            raise HTTPException(status_code=403, detail="Insufficient permissions. Admin role required.")
        active_chats_result = db.client.table("support_tickets").select(
            "id", count="exact"
        ).eq("assigned_to", user_id).in_("status", ["open", "in_progress"]).execute()
        active_chats_count = active_chats_result.count or 0
        return AdminProfile(
            id=user_id,
            email=user_data.get("email", ""),
            name=user_data.get("name", user_data.get("display_name", "Admin")),
            role=AdminRole(role) if role in [r.value for r in AdminRole] else AdminRole.SUPPORT,
            is_online=True,
            active_chats=active_chats_count,
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Admin auth error: {e}", exc_info=True)
        raise HTTPException(status_code=401, detail="Authentication failed")

router = APIRouter()
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
        from api.v1.admin.live_chat import _send_push_notification_to_user  # Lazy import to avoid circular import
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
        logger.error(f"Failed to close chat: {e}", exc_info=True)
        raise safe_internal_error(e, "admin_live_chat")


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
            "*, users!user_id(name, email)"
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
        logger.error(f"Failed to get support tickets: {e}", exc_info=True)
        raise safe_internal_error(e, "admin_live_chat")


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
        logger.error(f"Failed to get chat reports: {e}", exc_info=True)
        raise safe_internal_error(e, "admin_live_chat")


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
        logger.error(f"Failed to get dashboard stats: {e}", exc_info=True)
        raise safe_internal_error(e, "admin_live_chat")


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
        logger.error(f"Failed to update presence: {e}", exc_info=True)
        raise safe_internal_error(e, "admin_live_chat")
