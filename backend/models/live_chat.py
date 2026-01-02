"""Live Chat Pydantic models.

This module defines models for the live chat support system, enabling users to:
- Start real-time chat sessions with support agents
- Escalate AI chat conversations to human support
- Track queue position and estimated wait times
- Send/receive messages with typing indicators
- Mark messages as read
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

from models.support import TicketCategory, TicketPriority


class LiveChatStatus(str, Enum):
    """Status values for live chat sessions."""
    QUEUED = "queued"
    ACTIVE = "active"
    ENDED = "ended"


class MessageSenderRole(str, Enum):
    """Sender role for live chat messages."""
    USER = "user"
    AGENT = "agent"


# =============================================================================
# Request Models
# =============================================================================

class LiveChatStartRequest(BaseModel):
    """Request to start a new live chat session."""
    user_id: str = Field(..., max_length=100)
    category: TicketCategory
    initial_message: str = Field(..., min_length=1, max_length=5000)
    escalated_from_ai: bool = Field(default=False)
    ai_handoff_context: Optional[str] = Field(default=None, max_length=10000)


class LiveChatMessageRequest(BaseModel):
    """Request to send a message in live chat."""
    user_id: str = Field(..., max_length=100)
    message: str = Field(..., min_length=1, max_length=5000)
    sender_role: Optional[MessageSenderRole] = Field(
        default=None,
        description="Role of the sender. If not provided, determined by user type check."
    )


class LiveChatTypingRequest(BaseModel):
    """Request to update typing indicator."""
    user_id: str = Field(..., max_length=100)
    is_typing: bool = Field(default=True)


class LiveChatReadRequest(BaseModel):
    """Request to mark messages as read."""
    user_id: str = Field(..., max_length=100)
    message_ids: List[str] = Field(..., min_length=1, max_length=100)


class LiveChatEndRequest(BaseModel):
    """Request to end a live chat session."""
    user_id: str = Field(..., max_length=100)
    resolution_note: Optional[str] = Field(default=None, max_length=5000)


class LiveChatEscalateRequest(BaseModel):
    """Request to escalate an existing ticket to live chat."""
    user_id: str = Field(..., max_length=100)
    ai_handoff_context: Optional[str] = Field(default=None, max_length=10000)


# =============================================================================
# Response Models
# =============================================================================

class LiveChatStartResponse(BaseModel):
    """Response after starting a live chat session."""
    ticket_id: str = Field(..., max_length=100)
    queue_position: int = Field(..., ge=0)
    estimated_wait_minutes: Optional[int] = Field(default=None, ge=0)
    status: LiveChatStatus = Field(default=LiveChatStatus.QUEUED)
    message: str = Field(default="You have been added to the queue.")


class QueuePositionResponse(BaseModel):
    """Response with current queue position."""
    ticket_id: str = Field(..., max_length=100)
    queue_position: int = Field(..., ge=0)
    estimated_wait_minutes: Optional[int] = Field(default=None, ge=0)
    status: LiveChatStatus
    agents_online: int = Field(default=0, ge=0)


class AvailabilityResponse(BaseModel):
    """Response with live chat availability status."""
    is_available: bool = Field(default=False)
    agents_online_count: int = Field(default=0, ge=0)
    estimated_wait_minutes: Optional[int] = Field(default=None, ge=0)
    operating_hours: Optional[str] = Field(
        default=None,
        description="Human-readable operating hours if not available."
    )


class LiveChatMessage(BaseModel):
    """A message in a live chat conversation."""
    id: str = Field(..., max_length=100)
    ticket_id: str = Field(..., max_length=100)
    sender_role: MessageSenderRole
    sender_id: str = Field(..., max_length=100)
    message: str = Field(..., max_length=5000)
    created_at: datetime
    read_at: Optional[datetime] = None
    is_system_message: bool = Field(default=False)


class LiveChatMessageResponse(BaseModel):
    """Response after sending a message."""
    success: bool
    message: LiveChatMessage


class LiveChatTypingResponse(BaseModel):
    """Response after updating typing indicator."""
    success: bool
    ticket_id: str = Field(..., max_length=100)
    is_typing: bool


class LiveChatReadResponse(BaseModel):
    """Response after marking messages as read."""
    success: bool
    ticket_id: str = Field(..., max_length=100)
    messages_marked_read: int = Field(default=0, ge=0)


class LiveChatEndResponse(BaseModel):
    """Response after ending a live chat session."""
    success: bool
    ticket_id: str = Field(..., max_length=100)
    ended_at: datetime
    status: LiveChatStatus = Field(default=LiveChatStatus.ENDED)


class LiveChatEscalateResponse(BaseModel):
    """Response after escalating a ticket to live chat."""
    success: bool
    ticket_id: str = Field(..., max_length=100)
    queue_position: int = Field(..., ge=0)
    estimated_wait_minutes: Optional[int] = Field(default=None, ge=0)
    status: LiveChatStatus = Field(default=LiveChatStatus.QUEUED)
