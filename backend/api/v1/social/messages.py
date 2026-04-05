"""
Direct Messages API endpoints.

Allows users to:
- Get list of conversations
- Get messages in a conversation
- Send direct messages to other users
- Mark messages as read
- Create/manage group conversations (F12)
"""
from core.db import get_supabase_db

from fastapi import APIRouter, Depends, HTTPException, Query
from starlette.requests import Request
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from core.rate_limiter import limiter
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
    GroupCreate,
    GroupUpdate,
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
        content=data.get("content"),
        is_system_message=data.get("is_system_message", False),
        created_at=data.get("created_at") or datetime.utcnow(),
        edited_at=data.get("edited_at"),
        sender_name=sender_info.get("name"),
        sender_avatar=sender_info.get("avatar_url"),
        sender_is_support=sender_info.get("is_support_user", False),
        encrypted_content=data.get("encrypted_content"),
        encryption_nonce=data.get("encryption_nonce"),
        encryption_version=data.get("encryption_version", 0),
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


def _check_blocked(db, user_id: str, other_user_id: str) -> bool:
    """Check if either user has blocked the other. Returns True if blocked."""
    try:
        block_check = db.client.table("user_blocks").select("id").or_(
            f"and(blocker_id.eq.{user_id},blocked_id.eq.{other_user_id}),"
            f"and(blocker_id.eq.{other_user_id},blocked_id.eq.{user_id})"
        ).execute()
        return bool(block_check.data)
    except Exception:
        return False


# =============================================================================
# Get Conversations
# =============================================================================

@router.get("/conversations", response_model=ConversationsResponse)
@limiter.limit("30/minute")
async def get_conversations(
    request: Request,
    user_id: str = Query(..., description="Current user's ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get list of conversations for a user.

    Returns conversations sorted by most recent message.
    Includes participant info and last message preview.
    """
    verify_user_ownership(current_user, user_id)
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
            "conversation_id, user_id, last_read_at, is_muted, role, left_at, users(name, avatar_url, is_support_user)"
        ).in_("conversation_id", conversation_ids).neq("user_id", user_id).is_("left_at", "null").execute()

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
                    encryption_version=row.get("last_msg_encryption_version", 0),
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
        raise safe_internal_error(e, "messages")


# =============================================================================
# Get Messages in Conversation
# =============================================================================

@router.get("/conversations/{conversation_id}", response_model=MessagesResponse)
@limiter.limit("30/minute")
async def get_messages(
    request: Request,
    conversation_id: str,
    user_id: str = Query(..., description="Current user's ID"),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """
    Get messages in a conversation.

    Returns messages sorted by most recent first.
    Also marks messages as read for the current user.
    Includes read receipt data for group messages (F13).
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"[Messages] Getting messages for conversation {conversation_id}, user {user_id}")

    try:
        db = get_supabase_db()

        # Verify user is participant (and not left)
        participant_check = db.client.table("conversation_participants").select(
            "id"
        ).eq("conversation_id", conversation_id).eq("user_id", user_id).is_("left_at", "null").execute()

        if not participant_check.data:
            raise HTTPException(status_code=403, detail="Not authorized to view this conversation")

        # Get total count
        count_result = db.client.table("direct_messages").select(
            "id", count="exact"
        ).eq("conversation_id", conversation_id).is_("deleted_at", "null").execute()

        total_count = count_result.count or 0

        # Get messages with sender info (includes display_name and avatar for group msgs)
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

        # Read receipts (F13): get participants' last_read_at and privacy settings
        participants_result = db.client.table("conversation_participants").select(
            "user_id, last_read_at"
        ).eq("conversation_id", conversation_id).is_("left_at", "null").neq("user_id", user_id).execute()

        # Check which participants allow read receipts
        participant_ids = [p["user_id"] for p in (participants_result.data or [])]
        privacy_map = {}
        if participant_ids:
            privacy_result = db.client.table("user_privacy_settings").select(
                "user_id, show_read_receipts"
            ).in_("user_id", participant_ids).execute()
            privacy_map = {p["user_id"]: p.get("show_read_receipts", True) for p in (privacy_result.data or [])}

        # Build read_by info for each message
        read_by_data = {}
        for participant in (participants_result.data or []):
            pid = participant["user_id"]
            # Respect show_read_receipts privacy setting (default True)
            if not privacy_map.get(pid, True):
                continue
            last_read = participant.get("last_read_at")
            if last_read:
                read_by_data[pid] = last_read

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
        raise safe_internal_error(e, "messages")


# =============================================================================
# Send Message
# =============================================================================

@router.post("/send", response_model=DirectMessage)
@limiter.limit("30/minute")
async def send_message(
    request: Request,
    body: DirectMessageCreate,
    user_id: str = Query(..., description="Sender's user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Send a direct message to another user.

    Creates a new conversation if one doesn't exist between the users.
    For group conversations, provide conversation_id (no recipient_id needed).
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"[Messages] Sending message from {user_id} to {body.recipient_id}")

    try:
        db = get_supabase_db()

        conversation_id = body.conversation_id

        # If conversation_id is provided, check if it's a group conversation
        if conversation_id:
            conv_check = db.client.table("conversations").select(
                "id, is_group"
            ).eq("id", conversation_id).execute()

            if conv_check.data and conv_check.data[0].get("is_group"):
                # Group message - verify sender is active participant
                part_check = db.client.table("conversation_participants").select(
                    "id"
                ).eq("conversation_id", conversation_id).eq("user_id", user_id).is_("left_at", "null").execute()
                if not part_check.data:
                    raise HTTPException(status_code=403, detail="Not a member of this group")
            else:
                # DM with existing conversation - check blocks (F9)
                if body.recipient_id and _check_blocked(db, user_id, body.recipient_id):
                    raise HTTPException(status_code=403, detail="Cannot send message to this user")
        else:
            # New DM - check blocks (F9)
            if body.recipient_id and _check_blocked(db, user_id, body.recipient_id):
                raise HTTPException(status_code=403, detail="Cannot send message to this user")

        # If no conversation_id provided, get or create one
        if not conversation_id:
            # Check if conversation exists
            existing_result = db.client.rpc(
                "get_or_create_conversation",
                {"user1_id": user_id, "user2_id": body.recipient_id}
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
                    {"conversation_id": conversation_id, "user_id": body.recipient_id},
                ]).execute()

        # Insert the message
        message_data = {
            "conversation_id": conversation_id,
            "sender_id": user_id,
            "content": body.content if not body.encrypted_content else "[encrypted]",
            "is_system_message": False,
        }

        # Add encryption fields if present
        if body.encrypted_content:
            message_data["encrypted_content"] = body.encrypted_content
            message_data["encryption_nonce"] = body.encryption_nonce
            message_data["encryption_version"] = body.encryption_version

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
                "recipient_id": body.recipient_id,
                "message_length": len(body.encrypted_content or body.content or ""),
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
                "recipient_id": body.recipient_id,
            },
            context={
                "message_length": len(body.encrypted_content or body.content or ""),
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
            metadata={"recipient_id": body.recipient_id},
            status_code=500
        )
        raise safe_internal_error(e, "messages")


# =============================================================================
# Mark Messages as Read
# =============================================================================

@router.post("/conversations/{conversation_id}/read")
@limiter.limit("30/minute")
async def mark_as_read(
    request: Request,
    conversation_id: str,
    user_id: str = Query(..., description="Current user's ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Mark all messages in a conversation as read.
    """
    verify_user_ownership(current_user, user_id)
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
        raise safe_internal_error(e, "messages")


# =============================================================================
# Get Conversation with User
# =============================================================================

@router.get("/with/{other_user_id}", response_model=Optional[Conversation])
async def get_conversation_with_user(
    other_user_id: str,
    user_id: str = Query(..., description="Current user's ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get conversation between current user and another user.

    Returns None if no conversation exists.
    """
    verify_user_ownership(current_user, user_id)
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
        raise safe_internal_error(e, "messages")


# =============================================================================
# Group Conversations (F12)
# =============================================================================

@router.post("/conversations/group")
@limiter.limit("5/minute")
async def create_group_conversation(
    request: Request,
    group: GroupCreate,
    user_id: str = Query(..., description="Creator's user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Create a group conversation.

    The creator is automatically added as an admin member.
    Requires at least 2 other member IDs.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"[Messages] Creating group '{group.name}' by user {user_id}")

    try:
        db = get_supabase_db()

        # Create conversation with is_group=True
        conv_result = db.client.table("conversations").insert({
            "is_group": True,
            "group_name": group.name,
            "created_by": user_id,
        }).execute()

        if not conv_result.data:
            raise HTTPException(status_code=500, detail="Failed to create group conversation")

        conversation_id = str(conv_result.data[0]["id"])

        # Add creator as admin
        participants = [
            {
                "conversation_id": conversation_id,
                "user_id": user_id,
                "role": "admin",
            }
        ]

        # Add other members
        for member_id in group.member_ids:
            if member_id != user_id:
                participants.append({
                    "conversation_id": conversation_id,
                    "user_id": member_id,
                    "role": "member",
                })

        db.client.table("conversation_participants").insert(participants).execute()

        # Send system message
        db.client.table("direct_messages").insert({
            "conversation_id": conversation_id,
            "sender_id": user_id,
            "content": f"Group '{group.name}' created",
            "is_system_message": True,
        }).execute()

        logger.info(f"[Messages] Group created: {conversation_id} with {len(participants)} members")

        return {
            "conversation_id": conversation_id,
            "group_name": group.name,
            "member_count": len(participants),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Messages] Failed to create group: {e}")
        raise safe_internal_error(e, "messages")


@router.put("/conversations/{conversation_id}/members")
async def update_group_members(
    conversation_id: str,
    user_id: str = Query(..., description="Admin user ID"),
    add_member_ids: List[str] = Query(default=[], description="Member IDs to add"),
    remove_member_ids: List[str] = Query(default=[], description="Member IDs to remove"),
    current_user: dict = Depends(get_current_user),
):
    """
    Add or remove members from a group conversation (admin only).
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"[Messages] Updating members for group {conversation_id}")

    try:
        db = get_supabase_db()

        # Verify conversation is a group
        conv_check = db.client.table("conversations").select(
            "id, is_group"
        ).eq("id", conversation_id).execute()

        if not conv_check.data or not conv_check.data[0].get("is_group"):
            raise HTTPException(status_code=400, detail="Not a group conversation")

        # Verify user is admin
        admin_check = db.client.table("conversation_participants").select(
            "role"
        ).eq("conversation_id", conversation_id).eq("user_id", user_id).is_("left_at", "null").execute()

        if not admin_check.data or admin_check.data[0].get("role") != "admin":
            raise HTTPException(status_code=403, detail="Only admins can manage members")

        # Add members
        for member_id in add_member_ids:
            # Check if already a participant (might have left)
            existing = db.client.table("conversation_participants").select(
                "id, left_at"
            ).eq("conversation_id", conversation_id).eq("user_id", member_id).execute()

            if existing.data:
                # Re-join if previously left
                if existing.data[0].get("left_at"):
                    db.client.table("conversation_participants").update({
                        "left_at": None,
                        "role": "member",
                    }).eq("id", existing.data[0]["id"]).execute()
            else:
                db.client.table("conversation_participants").insert({
                    "conversation_id": conversation_id,
                    "user_id": member_id,
                    "role": "member",
                }).execute()

        # Remove members (soft remove by setting left_at)
        for member_id in remove_member_ids:
            if member_id == user_id:
                continue  # Admin can't remove themselves this way
            db.client.table("conversation_participants").update({
                "left_at": datetime.utcnow().isoformat(),
            }).eq("conversation_id", conversation_id).eq("user_id", member_id).execute()

        return {"success": True, "added": len(add_member_ids), "removed": len(remove_member_ids)}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Messages] Failed to update group members: {e}")
        raise safe_internal_error(e, "messages")


@router.put("/conversations/{conversation_id}/settings")
async def update_group_settings(
    conversation_id: str,
    update: GroupUpdate,
    user_id: str = Query(..., description="Admin user ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Update group conversation settings (admin only).
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"[Messages] Updating settings for group {conversation_id}")

    try:
        db = get_supabase_db()

        # Verify conversation is a group
        conv_check = db.client.table("conversations").select(
            "id, is_group"
        ).eq("id", conversation_id).execute()

        if not conv_check.data or not conv_check.data[0].get("is_group"):
            raise HTTPException(status_code=400, detail="Not a group conversation")

        # Verify user is admin
        admin_check = db.client.table("conversation_participants").select(
            "role"
        ).eq("conversation_id", conversation_id).eq("user_id", user_id).is_("left_at", "null").execute()

        if not admin_check.data or admin_check.data[0].get("role") != "admin":
            raise HTTPException(status_code=403, detail="Only admins can update group settings")

        # Build update data
        update_data = {}
        if update.name is not None:
            update_data["group_name"] = update.name
        if update.avatar_url is not None:
            update_data["group_avatar_url"] = update.avatar_url

        if update_data:
            update_data["updated_at"] = datetime.utcnow().isoformat()
            db.client.table("conversations").update(update_data).eq("id", conversation_id).execute()

        return {"success": True, "updated_fields": list(update_data.keys())}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Messages] Failed to update group settings: {e}")
        raise safe_internal_error(e, "messages")


@router.post("/conversations/{conversation_id}/leave")
@limiter.limit("10/minute")
async def leave_group(
    request: Request,
    conversation_id: str,
    user_id: str = Query(..., description="User leaving the group"),
    current_user: dict = Depends(get_current_user),
):
    """
    Leave a group conversation.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"[Messages] User {user_id} leaving group {conversation_id}")

    try:
        db = get_supabase_db()

        # Verify conversation is a group
        conv_check = db.client.table("conversations").select(
            "id, is_group"
        ).eq("id", conversation_id).execute()

        if not conv_check.data or not conv_check.data[0].get("is_group"):
            raise HTTPException(status_code=400, detail="Not a group conversation")

        # Verify user is participant
        part_check = db.client.table("conversation_participants").select(
            "id"
        ).eq("conversation_id", conversation_id).eq("user_id", user_id).is_("left_at", "null").execute()

        if not part_check.data:
            raise HTTPException(status_code=400, detail="Not a member of this group")

        # Set left_at
        db.client.table("conversation_participants").update({
            "left_at": datetime.utcnow().isoformat(),
        }).eq("conversation_id", conversation_id).eq("user_id", user_id).execute()

        # Send system message
        db.client.table("direct_messages").insert({
            "conversation_id": conversation_id,
            "sender_id": user_id,
            "content": "left the group",
            "is_system_message": True,
        }).execute()

        return {"success": True, "message": "Left group successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Messages] Failed to leave group: {e}")
        raise safe_internal_error(e, "messages")
