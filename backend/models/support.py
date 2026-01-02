"""Support Ticket Pydantic models.

This module defines models for the support ticket system, enabling users to:
- Create support tickets with different categories and priorities
- View ticket status and history
- Reply to tickets
- Close tickets when resolved
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class TicketCategory(str, Enum):
    """Categories for support tickets."""
    BILLING = "billing"
    TECHNICAL = "technical"
    FEATURE_REQUEST = "feature_request"
    BUG_REPORT = "bug_report"
    ACCOUNT = "account"
    OTHER = "other"


class TicketPriority(str, Enum):
    """Priority levels for support tickets."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


class TicketStatus(str, Enum):
    """Status values for support tickets."""
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    WAITING_RESPONSE = "waiting_response"
    RESOLVED = "resolved"
    CLOSED = "closed"


class MessageSender(str, Enum):
    """Sender types for ticket messages."""
    USER = "user"
    SUPPORT = "support"


# =============================================================================
# Support Ticket Message Models
# =============================================================================

class SupportTicketMessageCreate(BaseModel):
    """Create a new message on a support ticket."""
    message: str = Field(..., min_length=1, max_length=5000)
    sender: MessageSender = Field(default=MessageSender.USER)


class SupportTicketMessage(BaseModel):
    """A message in a support ticket conversation thread."""
    id: str = Field(..., max_length=100)
    ticket_id: str = Field(..., max_length=100)
    sender: MessageSender
    message: str = Field(..., max_length=5000)
    created_at: datetime
    updated_at: Optional[datetime] = None
    is_internal: bool = False  # For support team internal notes


# =============================================================================
# Support Ticket Models
# =============================================================================

class SupportTicketCreate(BaseModel):
    """Create a new support ticket."""
    user_id: str = Field(..., max_length=100)
    subject: str = Field(..., min_length=5, max_length=200)
    category: TicketCategory
    priority: TicketPriority = Field(default=TicketPriority.MEDIUM)
    initial_message: str = Field(..., min_length=10, max_length=5000)


class SupportTicketUpdate(BaseModel):
    """Update a support ticket (for status changes, priority, etc.)."""
    status: Optional[TicketStatus] = None
    priority: Optional[TicketPriority] = None
    assigned_to: Optional[str] = Field(default=None, max_length=100)


class SupportTicket(BaseModel):
    """Support ticket entry."""
    id: str = Field(..., max_length=100)
    user_id: str = Field(..., max_length=100)
    subject: str = Field(..., max_length=200)
    category: TicketCategory
    priority: TicketPriority
    status: TicketStatus
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None
    assigned_to: Optional[str] = Field(default=None, max_length=100)
    message_count: int = Field(default=1, ge=0)


class SupportTicketWithMessages(SupportTicket):
    """Support ticket with full conversation thread."""
    messages: List[SupportTicketMessage] = Field(default=[], max_length=500)


class SupportTicketSummary(BaseModel):
    """Summary view of a support ticket for list views."""
    id: str = Field(..., max_length=100)
    subject: str = Field(..., max_length=200)
    category: TicketCategory
    priority: TicketPriority
    status: TicketStatus
    created_at: datetime
    updated_at: datetime
    message_count: int = Field(default=1, ge=0)
    last_message_preview: Optional[str] = Field(default=None, max_length=100)
    last_message_sender: Optional[MessageSender] = None


# =============================================================================
# Response Models
# =============================================================================

class SupportTicketReplyResponse(BaseModel):
    """Response after adding a reply to a ticket."""
    success: bool
    ticket_id: str = Field(..., max_length=100)
    message: SupportTicketMessage
    new_status: TicketStatus


class SupportTicketCloseResponse(BaseModel):
    """Response after closing a ticket."""
    success: bool
    ticket_id: str = Field(..., max_length=100)
    closed_at: datetime
    final_status: TicketStatus


class SupportTicketStatsResponse(BaseModel):
    """User's support ticket statistics."""
    total_tickets: int = Field(default=0, ge=0)
    open_tickets: int = Field(default=0, ge=0)
    resolved_tickets: int = Field(default=0, ge=0)
    closed_tickets: int = Field(default=0, ge=0)
    avg_resolution_time_hours: Optional[float] = None
