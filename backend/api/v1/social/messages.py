"""
Direct Messages API endpoints.

Allows users to:
- Get list of conversations
- Get messages in a conversation
- Send direct messages to other users
- Mark messages as read
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from datetime import datetime

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from services.user_context_service import user_context_service, EventType
from models.social import (
    DirectMessage,
    DirectMessageCreate,
    Conversation,
    ConversationParticipant,
    ConversationsResponse,
    MessagesResponse,
)

router = APIRouter()
logger = get_logger(__name__)


# =============================================================================
# Helper Functions
# =============================================================================

def _parse_message(data: dict, users_data: dict = None) -> DirectMessage:
    """Parse database row to DirectMessage model."""
    sender_info = users_data or {}
    return DirectMessage(
        id=str(data["id"]),
        conversation_id=str(data["conversation_id"]),
        sender_id=str(data["sender_id"]),
        content=data["content"],
        is_system_message=data.get("is_system_message", False),
        created_at=data.get("created_at") or datetime.utcnow(),
        edited_at=data.get("edited_at"),
        sender_name=sender_info.get("name"),
        sender_avatar=sender_info.get("avatar_url"),
        sender_is_support=sender_info.get("is_support_user", False),
    )


def _parse_participant(data: dict) -> ConversationParticipant:
    """Parse participant data."""
    user_data = data.get("users", {}) or {}
    return ConversationParticipant(
        user_id=str(data["user_id"]),
        user_name=user_data.get("name"),
        user_avatar=user_data.get("avatar_url"),
        is_support_user=user_data.get("is_support_user", False),
        last_read_at=data.get("last_read_at"),
        is_muted=data.get("is_muted", False),
    )


# =============================================================================
# Get Conversations
# =============================================================================

@router.get("/conversations", response_model=ConversationsResponse)
async def get_conversations(
    user_id: str = Query(..., description="Current user's ID"),
):
    """
    Get list of conversations for a user.

    Returns conversations sorted by most recent message.
    Includes participant info and last message preview.
    """
    logger.info(f"[Messages] Getting conversations for user {user_id}")

    try:
        db = get_supabase_db()

        # Single RPC: gets conversations with last message + unread count
        convos_result = db.client.rpc("get_user_conversations", {"p_user_id": user_id}).execute()

        if not convos_result.data:
            logger.info(f"[Messages] No conversations found for user {user_id}")
            return ConversationsResponse(conversations=[], total_count=0)

        # Collect conversation IDs to batch-fetch participants (the "other user" info)
        conversation_ids = [str(row["conversation_id"]) for row in convos_result.data]

        participants_result = db.client.table("conversation_participants").select(
            "conversation_id, user_id, last_read_at, is_muted, users(name, avatar_url, is_support_user)"
        ).in_("conversation_id", conversation_ids).neq("user_id", user_id).execute()

        # Index participants by conversation_id
        participants_by_conv = {}
        for p in participants_result.data:
            conv_id = str(p["conversation_id"])
            participants_by_conv.setdefault(conv_id, []).append(_parse_participant(p))

        # Build conversation objects from RPC results
        conversations = []
        for row in convos_result.data:
            conv_id = str(row["conversation_id"])

            # Build last message from RPC data
            last_message = None
            if row.get("last_msg_id"):
                last_message = DirectMessage(
                    id=str(row["last_msg_id"]),
                    conversation_id=conv_id,
                    sender_id=str(row["last_msg_sender_id"]),
                    content=row["last_msg_content"] or "",
                    is_system_message=False,
                    created_at=row.get("last_msg_created_at") or datetime.utcnow(),
                    sender_name=row.get("last_msg_sender_name"),
                    sender_avatar=row.get("last_msg_sender_avatar"),
                )

            conversations.append(Conversation(
                id=conv_id,
                last_message_at=row.get("last_message_at") or row["created_at"],
                created_at=row["created_at"],
                participants=participants_by_conv.get(conv_id, []),
                last_message=last_message,
                unread_count=row.get("unread_count", 0),
            ))

        logger.info(f"[Messages] Found {len(conversations)} conversations for user {user_id}")

        return ConversationsResponse(
            conversations=conversations,
            total_count=len(conversations),
        )

    except Exception as e:
        logger.error(f"[Messages] Failed to get conversations: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Get Messages in Conversation
# =============================================================================

@router.get("/conversations/{conversation_id}", response_model=MessagesResponse)
async def get_messages(
    conversation_id: str,
    user_id: str = Query(..., description="Current user's ID"),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
):
    """
    Get messages in a conversation.

    Returns messages sorted by most recent first.
    Also marks messages as read for the current user.
    """
    logger.info(f"[Messages] Getting messages for conversation {conversation_id}, user {user_id}")

    try:
        db = get_supabase_db()

        # Verify user is participant
        participant_check = db.client.table("conversation_participants").select(
            "id"
        ).eq("conversation_id", conversation_id).eq("user_id", user_id).execute()

        if not participant_check.data:
            raise HTTPException(status_code=403, detail="Not authorized to view this conversation")

        # Get total count
        count_result = db.client.table("direct_messages").select(
            "id", count="exact"
        ).eq("conversation_id", conversation_id).is_("deleted_at", "null").execute()

        total_count = count_result.count or 0

        # Get messages with sender info
        offset = (page - 1) * page_size
        messages_result = db.client.table("direct_messages").select(
            "*, users:sender_id(name, avatar_url, is_support_user)"
        ).eq("conversation_id", conversation_id).is_(
            "deleted_at", "null"
        ).order("created_at", desc=True).range(offset, offset + page_size - 1).execute()

        messages = []
        for msg_data in messages_result.data:
            users_info = msg_data.pop("users", {}) or {}
            messages.append(_parse_message(msg_data, users_info))

        # Mark messages as read
        now = datetime.utcnow().isoformat()
        db.client.table("conversation_participants").update({
            "last_read_at": now
        }).eq("conversation_id", conversation_id).eq("user_id", user_id).execute()

        has_more = (offset + len(messages)) < total_count

        logger.info(f"[Messages] Returning {len(messages)} messages")

        return MessagesResponse(
            messages=messages,
            conversation_id=conversation_id,
            total_count=total_count,
            page=page,
            page_size=page_size,
            has_more=has_more,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Messages] Failed to get messages: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Send Message
# =============================================================================

@router.post("/send", response_model=DirectMessage)
async def send_message(
    request: DirectMessageCreate,
    user_id: str = Query(..., description="Sender's user ID"),
):
    """
    Send a direct message to another user.

    Creates a new conversation if one doesn't exist between the users.
    """
    logger.info(f"[Messages] Sending message from {user_id} to {request.recipient_id}")

    try:
        db = get_supabase_db()

        conversation_id = request.conversation_id

        # If no conversation_id provided, get or create one
        if not conversation_id:
            # Check if conversation exists
            existing_result = db.client.rpc(
                "get_or_create_conversation",
                {"user1_id": user_id, "user2_id": request.recipient_id}
            ).execute()

            if existing_result.data:
                conversation_id = str(existing_result.data)
            else:
                # Fallback: manually create conversation
                conv_result = db.client.table("conversations").insert({}).execute()
                if not conv_result.data:
                    raise HTTPException(status_code=500, detail="Failed to create conversation")

                conversation_id = str(conv_result.data[0]["id"])

                # Add participants
                db.client.table("conversation_participants").insert([
                    {"conversation_id": conversation_id, "user_id": user_id},
                    {"conversation_id": conversation_id, "user_id": request.recipient_id},
                ]).execute()

        # Insert the message
        message_data = {
            "conversation_id": conversation_id,
            "sender_id": user_id,
            "content": request.content,
            "is_system_message": False,
        }

        message_result = db.client.table("direct_messages").insert(message_data).execute()

        if not message_result.data:
            raise HTTPException(status_code=500, detail="Failed to send message")

        msg_row = message_result.data[0]

        # Update conversation last_message_at
        db.client.table("conversations").update({
            "last_message_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
        }).eq("id", conversation_id).execute()

        # Get sender info
        sender_result = db.client.table("users").select(
            "name, avatar_url, is_support_user"
        ).eq("id", user_id).execute()

        sender_info = sender_result.data[0] if sender_result.data else {}

        logger.info(f"[Messages] Message sent successfully in conversation {conversation_id}")

        # Log user activity and context
        await log_user_activity(
            user_id=user_id,
            action="direct_message_sent",
            endpoint="/api/v1/social/messages/send",
            message="Sent a direct message",
            metadata={
                "conversation_id": conversation_id,
                "recipient_id": request.recipient_id,
                "message_length": len(request.content),
            },
            status_code=200
        )

        # Log to user context for AI awareness
        await user_context_service.log_event(
            user_id=user_id,
            event_type=EventType.FEATURE_INTERACTION,
            event_data={
                "feature": "direct_messages",
                "action": "message_sent",
                "conversation_id": conversation_id,
                "recipient_id": request.recipient_id,
            },
            context={
                "message_length": len(request.content),
            },
        )

        return _parse_message(msg_row, sender_info)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Messages] Failed to send message: {e}")
        await log_user_error(
            user_id=user_id,
            action="direct_message_sent",
            error=e,
            endpoint="/api/v1/social/messages/send",
            metadata={"recipient_id": request.recipient_id},
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Mark Messages as Read
# =============================================================================

@router.post("/conversations/{conversation_id}/read")
async def mark_as_read(
    conversation_id: str,
    user_id: str = Query(..., description="Current user's ID"),
):
    """
    Mark all messages in a conversation as read.
    """
    logger.info(f"[Messages] Marking conversation {conversation_id} as read for user {user_id}")

    try:
        db = get_supabase_db()

        # Verify user is participant
        participant_check = db.client.table("conversation_participants").select(
            "id"
        ).eq("conversation_id", conversation_id).eq("user_id", user_id).execute()

        if not participant_check.data:
            raise HTTPException(status_code=403, detail="Not authorized")

        # Update last_read_at
        now = datetime.utcnow().isoformat()
        db.client.table("conversation_participants").update({
            "last_read_at": now
        }).eq("conversation_id", conversation_id).eq("user_id", user_id).execute()

        return {"success": True, "conversation_id": conversation_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Messages] Failed to mark as read: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# =============================================================================
# Get Conversation with User
# =============================================================================

@router.get("/with/{other_user_id}", response_model=Optional[Conversation])
async def get_conversation_with_user(
    other_user_id: str,
    user_id: str = Query(..., description="Current user's ID"),
):
    """
    Get conversation between current user and another user.

    Returns None if no conversation exists.
    """
    logger.info(f"[Messages] Getting conversation between {user_id} and {other_user_id}")

    try:
        db = get_supabase_db()

        # Find conversation where both users are participants
        result = db.client.rpc(
            "get_or_create_conversation",
            {"user1_id": user_id, "user2_id": other_user_id}
        ).execute()

        if not result.data:
            return None

        conversation_id = str(result.data)

        # Get full conversation details
        conv_result = db.client.table("conversations").select(
            "*, conversation_participants(*, users(name, avatar_url, is_support_user))"
        ).eq("id", conversation_id).execute()

        if not conv_result.data:
            return None

        conv_data = conv_result.data[0]

        # Get last message
        last_msg_result = db.client.table("direct_messages").select(
            "*, users:sender_id(name, avatar_url, is_support_user)"
        ).eq("conversation_id", conversation_id).order(
            "created_at", desc=True
        ).limit(1).execute()

        last_message = None
        if last_msg_result.data:
            msg_data = last_msg_result.data[0]
            users_info = msg_data.pop("users", {}) or {}
            last_message = _parse_message(msg_data, users_info)

        # Parse participants
        participants = [
            _parse_participant(p)
            for p in conv_data.get("conversation_participants", [])
            if str(p["user_id"]) != user_id
        ]

        return Conversation(
            id=conversation_id,
            last_message_at=conv_data.get("last_message_at") or conv_data["created_at"],
            created_at=conv_data["created_at"],
            participants=participants,
            last_message=last_message,
            unread_count=0,
        )

    except Exception as e:
        logger.error(f"[Messages] Failed to get conversation: {e}")
        raise HTTPException(status_code=500, detail=str(e))
