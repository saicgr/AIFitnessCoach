"""Admin Panel Pydantic models.

This module defines models for the admin backend API, enabling admins to:
- Authenticate and manage sessions
- View and respond to live chat tickets
- Manage support tickets and user reports
- Monitor dashboard statistics
- Track agent presence and availability
"""

from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime
from enum import Enum

from models.support import TicketCategory, TicketPriority, TicketStatus
from models.live_chat import LiveChatStatus, MessageSenderRole, LiveChatMessage


class AdminRole(str, Enum):
    """Admin role levels."""
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"
    SUPPORT = "support"


# =============================================================================
# Authentication Models
# =============================================================================

class AdminLoginRequest(BaseModel):
    """Admin login request."""
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)


class AdminLoginResponse(BaseModel):
    """Admin login response."""
    success: bool
    access_token: str = Field(..., max_length=2000)
    refresh_token: Optional[str] = Field(default=None, max_length=2000)
    admin_id: str = Field(..., max_length=100)
    admin_name: str = Field(..., max_length=200)
    admin_email: str = Field(..., max_length=200)
    role: AdminRole
    expires_at: datetime


class AdminProfile(BaseModel):
    """Admin user profile."""
    id: str = Field(..., max_length=100)
    email: str = Field(..., max_length=200)
    name: str = Field(..., max_length=200)
    role: AdminRole
    is_online: bool = False
    last_seen: Optional[datetime] = None
    avatar_url: Optional[str] = Field(default=None, max_length=500)
    created_at: datetime
    active_chats_count: int = Field(default=0, ge=0)


# =============================================================================
# Live Chat Admin Models
# =============================================================================

class LiveChatTicketSummary(BaseModel):
    """Summary view of a live chat ticket for list views."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    user_name: Optional[str] = Field(default=None, max_length=200)
    user_email: Optional[str] = Field(default=None, max_length=200)
    subject: str = Field(..., max_length=200)
    category: TicketCategory
    priority: TicketPriority
    status: TicketStatus
    chat_status: LiveChatStatus
    created_at: datetime
    updated_at: datetime
    escalated_from_ai: bool = False
    agent_id: Optional[str] = Field(default=None, max_length=100)
    agent_name: Optional[str] = Field(default=None, max_length=200)
    unread_count: int = Field(default=0, ge=0)
    last_message_preview: Optional[str] = Field(default=None, max_length=200)
    last_message_at: Optional[datetime] = None
    queue_position: Optional[int] = Field(default=None, ge=0)


class LiveChatTicketDetail(BaseModel):
    """Full live chat ticket with messages and user info."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    user_name: Optional[str] = Field(default=None, max_length=200)
    user_email: Optional[str] = Field(default=None, max_length=200)
    user_avatar_url: Optional[str] = Field(default=None, max_length=500)
    user_subscription_status: Optional[str] = Field(default=None, max_length=50)
    user_member_since: Optional[datetime] = None
    subject: str = Field(..., max_length=200)
    category: TicketCategory
    priority: TicketPriority
    status: TicketStatus
    chat_status: LiveChatStatus
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None
    escalated_from_ai: bool = False
    ai_handoff_context: Optional[str] = Field(default=None, max_length=10000)
    agent_id: Optional[str] = Field(default=None, max_length=100)
    agent_name: Optional[str] = Field(default=None, max_length=200)
    messages: List[LiveChatMessage] = Field(default=[], max_length=1000)
    user_typing: bool = False
    agent_typing: bool = False


class AdminReplyRequest(BaseModel):
    """Request to send a message as an admin/agent."""
    message: str = Field(..., min_length=1, max_length=5000)


class AdminReplyResponse(BaseModel):
    """Response after sending an admin reply."""
    success: bool
    message: LiveChatMessage
    notification_sent: bool = False


class AssignChatRequest(BaseModel):
    """Request to assign a chat to an agent."""
    agent_id: str = Field(..., max_length=100)
    agent_name: Optional[str] = Field(default=None, max_length=200)


class AssignChatResponse(BaseModel):
    """Response after assigning a chat."""
    success: bool
    ticket_id: str = Field(..., max_length=100)
    agent_id: str = Field(..., max_length=100)
    agent_name: Optional[str] = Field(default=None, max_length=200)
    assigned_at: datetime


class CloseChatRequest(BaseModel):
    """Request to close a live chat."""
    resolution_note: Optional[str] = Field(default=None, max_length=5000)
    resolution_category: Optional[str] = Field(default=None, max_length=100)


class CloseChatResponse(BaseModel):
    """Response after closing a chat."""
    success: bool
    ticket_id: str = Field(..., max_length=100)
    closed_at: datetime
    status: TicketStatus = TicketStatus.RESOLVED


# =============================================================================
# Support Ticket Admin Models
# =============================================================================

class SupportTicketAdminSummary(BaseModel):
    """Summary view of a support ticket for admin list views."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    user_name: Optional[str] = Field(default=None, max_length=200)
    user_email: Optional[str] = Field(default=None, max_length=200)
    subject: str = Field(..., max_length=200)
    category: TicketCategory
    priority: TicketPriority
    status: TicketStatus
    created_at: datetime
    updated_at: datetime
    message_count: int = Field(default=1, ge=0)
    assigned_to: Optional[str] = Field(default=None, max_length=100)
    assigned_to_name: Optional[str] = Field(default=None, max_length=200)
    last_message_preview: Optional[str] = Field(default=None, max_length=200)
    last_message_sender: Optional[str] = Field(default=None, max_length=50)


# =============================================================================
# Chat Reports Admin Models
# =============================================================================

class ChatReportAdminSummary(BaseModel):
    """Summary view of a chat report for admin list views."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    user_name: Optional[str] = Field(default=None, max_length=200)
    message_id: str = Field(..., max_length=100)
    report_category: str = Field(..., max_length=100)
    status: str = Field(..., max_length=50)
    created_at: datetime
    updated_at: datetime
    original_user_message_preview: str = Field(..., max_length=200)
    reported_ai_response_preview: str = Field(..., max_length=200)
    has_ai_analysis: bool = False
    reviewed_by: Optional[str] = Field(default=None, max_length=100)


# =============================================================================
# Dashboard Models
# =============================================================================

class AgentStatus(BaseModel):
    """Status of a support agent."""
    agent_id: str = Field(..., max_length=100)
    agent_name: str = Field(..., max_length=200)
    is_online: bool = False
    last_seen: Optional[datetime] = None
    active_chats: int = Field(default=0, ge=0)
    chats_resolved_today: int = Field(default=0, ge=0)


class DashboardStats(BaseModel):
    """Admin dashboard statistics."""
    # Live chat stats
    active_live_chats: int = Field(default=0, ge=0)
    queued_live_chats: int = Field(default=0, ge=0)
    avg_wait_time_minutes: Optional[float] = Field(default=None, ge=0)
    avg_response_time_minutes: Optional[float] = Field(default=None, ge=0)

    # Support ticket stats
    open_tickets: int = Field(default=0, ge=0)
    pending_tickets: int = Field(default=0, ge=0)
    resolved_today: int = Field(default=0, ge=0)

    # Report stats
    pending_reports: int = Field(default=0, ge=0)

    # Agent stats
    agents_online: int = Field(default=0, ge=0)
    total_agents: int = Field(default=0, ge=0)

    # Additional metrics
    chats_started_today: int = Field(default=0, ge=0)
    satisfaction_rate: Optional[float] = Field(default=None, ge=0, le=100)

    # Agent details
    online_agents: List[AgentStatus] = Field(default=[])


# =============================================================================
# Presence Models
# =============================================================================

class PresenceUpdateRequest(BaseModel):
    """Request to update admin presence status."""
    is_online: bool = True
    status_message: Optional[str] = Field(default=None, max_length=200)


class PresenceUpdateResponse(BaseModel):
    """Response after updating presence."""
    success: bool
    admin_id: str = Field(..., max_length=100)
    is_online: bool
    last_seen: datetime


# =============================================================================
# List Response Models
# =============================================================================

class LiveChatListResponse(BaseModel):
    """Paginated list of live chats."""
    chats: List[LiveChatTicketSummary]
    total: int = Field(default=0, ge=0)
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    has_more: bool = False


class SupportTicketListResponse(BaseModel):
    """Paginated list of support tickets."""
    tickets: List[SupportTicketAdminSummary]
    total: int = Field(default=0, ge=0)
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    has_more: bool = False


class ChatReportListResponse(BaseModel):
    """Paginated list of chat reports."""
    reports: List[ChatReportAdminSummary]
    total: int = Field(default=0, ge=0)
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    has_more: bool = False
