"""
API endpoints for Goal Social Features.

Enables social interaction around weekly goals:
- View friends doing the same goals
- Join friends' goals
- Invite friends to join your goals
- Goal leaderboards

Endpoints:
- GET /goals/{id}/friends - Get friends on same goal (leaderboard)
- POST /goals/{id}/join - Join a friend's goal
- POST /goals/{id}/invite - Invite friend to your goal
- GET /goals/invites - Get pending goal invites
- POST /goals/invites/{id}/respond - Accept/decline invite
- GET /goals/invites/pending-count - Count of pending invites
- DELETE /goals/invites/{id} - Cancel sent invite
"""

from fastapi import APIRouter, HTTPException, Query
from datetime import datetime, date, timedelta, timezone
from typing import Optional, List

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.goal_suggestions import (
    GoalFriendsResponse, GoalLeaderboardEntry, FriendGoalProgress,
    GoalInvite, GoalInviteCreate, GoalInviteWithDetails,
    InviteResponseRequest, GoalInviteResponse,
    SharedGoal, SharedGoalCreate, SharedGoalStatus,
    InviteStatus, GoalVisibility, GoalType,
    PendingInvitesSummary,
)
from models.weekly_personal_goals import WeeklyPersonalGoal

router = APIRouter()
logger = get_logger(__name__)


def get_iso_week_boundaries(for_date: date) -> tuple[date, date]:
    """Get Monday and Sunday of the ISO week containing for_date."""
    week_start = for_date - timedelta(days=for_date.weekday())
    week_end = week_start + timedelta(days=6)
    return week_start, week_end


# ============================================================
# GET FRIENDS ON GOAL
# ============================================================

@router.get("/goals/{goal_id}/friends", response_model=GoalFriendsResponse)
async def get_goal_friends(
    user_id: str,
    goal_id: str,
):
    """
    Get friends who have the same exercise/goal_type combination this week.
    Returns mini-leaderboard sorted by progress.
    """
    logger.info(f"Getting friends on goal: {goal_id} for user: {user_id}")

    try:
        db = get_supabase_db()
        today = date.today()
        week_start, _ = get_iso_week_boundaries(today)

        # Get the user's goal to get exercise/type
        goal_result = db.client.table("weekly_personal_goals").select("*").eq(
            "id", goal_id
        ).eq("user_id", user_id).execute()

        if not goal_result.data:
            raise HTTPException(status_code=404, detail="Goal not found")

        goal = goal_result.data[0]
        exercise_name = goal["exercise_name"]
        goal_type = goal["goal_type"]

        # Get user's friends
        friends_result = db.client.table("user_connections").select(
            "following_id, follower_id"
        ).or_(
            f"follower_id.eq.{user_id},following_id.eq.{user_id}"
        ).eq("status", "active").execute()

        friend_ids = set()
        for conn in friends_result.data:
            if conn["follower_id"] == user_id:
                friend_ids.add(conn["following_id"])
            else:
                friend_ids.add(conn["follower_id"])

        if not friend_ids:
            return GoalFriendsResponse(
                goal_id=goal_id,
                exercise_name=exercise_name,
                goal_type=goal_type,
                week_start=week_start,
                friend_entries=[],
                total_friends_count=0,
                user_rank=1,
                user_progress_percentage=_calc_progress(goal["current_value"], goal["target_value"]),
            )

        # Get friends' goals for same exercise/type this week
        friends_goals = db.client.table("weekly_personal_goals").select(
            "*, users!inner(id, display_name, photo_url)"
        ).in_("user_id", list(friend_ids)).eq(
            "exercise_name", exercise_name
        ).eq("goal_type", goal_type).eq(
            "week_start", week_start.isoformat()
        ).in_("visibility", ["friends", "public"]).execute()

        # Build leaderboard entries
        all_entries = []

        # Add user's entry first
        user_progress = _calc_progress(goal["current_value"], goal["target_value"])
        all_entries.append({
            "user_id": user_id,
            "name": "You",
            "avatar_url": None,
            "current_value": goal["current_value"],
            "target_value": goal["target_value"],
            "progress_percentage": user_progress,
            "is_pr_beaten": goal["is_pr_beaten"],
            "is_current_user": True,
        })

        # Add friends
        for fg in friends_goals.data:
            user_data = fg.get("users", {})
            all_entries.append({
                "user_id": fg["user_id"],
                "name": user_data.get("display_name", "Friend"),
                "avatar_url": user_data.get("photo_url"),
                "current_value": fg["current_value"],
                "target_value": fg["target_value"],
                "progress_percentage": _calc_progress(fg["current_value"], fg["target_value"]),
                "is_pr_beaten": fg["is_pr_beaten"],
                "is_current_user": False,
            })

        # Sort by progress (descending), then by current value
        all_entries.sort(key=lambda x: (x["progress_percentage"], x["current_value"]), reverse=True)

        # Assign ranks
        friend_entries = []
        user_rank = 1
        for i, entry in enumerate(all_entries):
            entry["rank"] = i + 1
            if entry["is_current_user"]:
                user_rank = i + 1
            else:
                friend_entries.append(FriendGoalProgress(**entry))

        return GoalFriendsResponse(
            goal_id=goal_id,
            exercise_name=exercise_name,
            goal_type=goal_type,
            week_start=week_start,
            friend_entries=friend_entries,
            total_friends_count=len(friend_entries),
            user_rank=user_rank,
            user_progress_percentage=user_progress,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get goal friends: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# JOIN A FRIEND'S GOAL
# ============================================================

@router.post("/goals/{goal_id}/join", response_model=WeeklyPersonalGoal)
async def join_goal(
    user_id: str,
    goal_id: str,
):
    """
    Join a friend's goal by creating your own copy with same exercise/type/target.
    Creates shared_goals record to link them.
    """
    logger.info(f"User {user_id} joining goal: {goal_id}")

    try:
        db = get_supabase_db()
        today = date.today()
        week_start, week_end = get_iso_week_boundaries(today)

        # Get the friend's goal
        friend_goal_result = db.client.table("weekly_personal_goals").select("*").eq(
            "id", goal_id
        ).execute()

        if not friend_goal_result.data:
            raise HTTPException(status_code=404, detail="Goal not found")

        friend_goal = friend_goal_result.data[0]

        # Verify it's not the user's own goal
        if friend_goal["user_id"] == user_id:
            raise HTTPException(status_code=400, detail="Cannot join your own goal")

        # Check visibility
        if friend_goal["visibility"] == "private":
            raise HTTPException(status_code=403, detail="This goal is private")

        # Check if user already has same goal this week
        existing = db.client.table("weekly_personal_goals").select("id").eq(
            "user_id", user_id
        ).eq("exercise_name", friend_goal["exercise_name"]).eq(
            "goal_type", friend_goal["goal_type"]
        ).eq("week_start", week_start.isoformat()).execute()

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail=f"You already have a goal for {friend_goal['exercise_name']} this week"
            )

        # Get user's personal best
        pb_result = db.client.table("personal_goal_records").select("record_value").eq(
            "user_id", user_id
        ).eq("exercise_name", friend_goal["exercise_name"]).eq(
            "goal_type", friend_goal["goal_type"]
        ).execute()

        personal_best = pb_result.data[0]["record_value"] if pb_result.data else None

        # Create user's goal
        goal_data = {
            "user_id": user_id,
            "exercise_name": friend_goal["exercise_name"],
            "goal_type": friend_goal["goal_type"],
            "target_value": friend_goal["target_value"],
            "week_start": week_start.isoformat(),
            "week_end": week_end.isoformat(),
            "personal_best": personal_best,
            "status": "active",
            "current_value": 0,
            "is_pr_beaten": False,
            "is_shared": True,
            "visibility": "friends",
        }

        result = db.client.table("weekly_personal_goals").insert(goal_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create goal")

        new_goal = result.data[0]

        # Create shared_goals record
        shared_data = {
            "original_goal_id": goal_id,
            "source_user_id": friend_goal["user_id"],
            "joined_user_id": user_id,
            "joined_goal_id": new_goal["id"],
            "status": "active",
        }

        db.client.table("shared_goals").insert(shared_data).execute()

        # Mark original goal as shared
        db.client.table("weekly_personal_goals").update({
            "is_shared": True
        }).eq("id", goal_id).execute()

        logger.info(f"✅ User {user_id} joined goal {goal_id}")

        return _build_goal_response(new_goal, today)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to join goal: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# INVITE FRIEND TO GOAL
# ============================================================

@router.post("/goals/{goal_id}/invite", response_model=GoalInvite)
async def invite_to_goal(
    user_id: str,
    goal_id: str,
    request: GoalInviteCreate,
):
    """Invite a friend to join your goal."""
    logger.info(f"User {user_id} inviting {request.invitee_id} to goal {goal_id}")

    try:
        db = get_supabase_db()

        # Verify goal belongs to user
        goal_result = db.client.table("weekly_personal_goals").select("*").eq(
            "id", goal_id
        ).eq("user_id", user_id).execute()

        if not goal_result.data:
            raise HTTPException(status_code=404, detail="Goal not found")

        goal = goal_result.data[0]

        # Verify can't invite self
        if request.invitee_id == user_id:
            raise HTTPException(status_code=400, detail="Cannot invite yourself")

        # Verify they are friends
        friends_check = db.client.table("user_connections").select("id").or_(
            f"and(follower_id.eq.{user_id},following_id.eq.{request.invitee_id}),and(follower_id.eq.{request.invitee_id},following_id.eq.{user_id})"
        ).eq("status", "active").execute()

        if not friends_check.data:
            raise HTTPException(status_code=403, detail="Can only invite friends")

        # Check for existing invite
        existing = db.client.table("goal_invites").select("id, status").eq(
            "goal_id", goal_id
        ).eq("invitee_id", request.invitee_id).execute()

        if existing.data:
            existing_invite = existing.data[0]
            if existing_invite["status"] == "pending":
                raise HTTPException(status_code=400, detail="Invite already sent")
            # If declined/expired, allow re-invite by updating
            db.client.table("goal_invites").update({
                "status": "pending",
                "message": request.message,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "responded_at": None,
                "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
            }).eq("id", existing_invite["id"]).execute()

            updated = db.client.table("goal_invites").select("*").eq(
                "id", existing_invite["id"]
            ).execute()

            return GoalInvite(**updated.data[0])

        # Create invite
        invite_data = {
            "goal_id": goal_id,
            "inviter_id": user_id,
            "invitee_id": request.invitee_id,
            "status": "pending",
            "message": request.message,
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        }

        result = db.client.table("goal_invites").insert(invite_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create invite")

        # TODO: Send push notification to invitee

        logger.info(f"✅ Created invite for goal {goal_id} to user {request.invitee_id}")

        return GoalInvite(**result.data[0])

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to invite to goal: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# GET PENDING INVITES
# ============================================================

@router.get("/goals/invites", response_model=List[GoalInviteWithDetails])
async def get_goal_invites(
    user_id: str,
    status: Optional[InviteStatus] = Query(None, description="Filter by status"),
):
    """Get all goal invites for the user (received)."""
    logger.info(f"Getting goal invites for user: {user_id}")

    try:
        db = get_supabase_db()
        now = datetime.now(timezone.utc)

        # Expire old invites first
        db.client.table("goal_invites").update({
            "status": "expired"
        }).eq("status", "pending").lt(
            "expires_at", now.isoformat()
        ).execute()

        # Build query
        query = db.client.table("goal_invites").select(
            "*, weekly_personal_goals!inner(exercise_name, goal_type, target_value, current_value), users!goal_invites_inviter_id_fkey(display_name, photo_url)"
        ).eq("invitee_id", user_id)

        if status:
            query = query.eq("status", status.value)
        else:
            query = query.eq("status", "pending")

        result = query.order("created_at", desc=True).execute()

        invites = []
        for row in result.data:
            goal_data = row.get("weekly_personal_goals", {})
            inviter_data = row.get("users", {})

            invite = GoalInviteWithDetails(
                id=row["id"],
                goal_id=row["goal_id"],
                inviter_id=row["inviter_id"],
                invitee_id=row["invitee_id"],
                status=row["status"],
                message=row.get("message"),
                created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
                responded_at=datetime.fromisoformat(row["responded_at"].replace("Z", "+00:00")) if row.get("responded_at") else None,
                expires_at=datetime.fromisoformat(row["expires_at"].replace("Z", "+00:00")),
                goal_exercise_name=goal_data.get("exercise_name", ""),
                goal_type=goal_data.get("goal_type", "single_max"),
                goal_target_value=goal_data.get("target_value", 0),
                inviter_name=inviter_data.get("display_name", "Friend"),
                inviter_avatar_url=inviter_data.get("photo_url"),
                inviter_current_value=goal_data.get("current_value", 0),
                inviter_progress_percentage=_calc_progress(
                    goal_data.get("current_value", 0),
                    goal_data.get("target_value", 1)
                ),
            )
            invites.append(invite)

        return invites

    except Exception as e:
        logger.error(f"Failed to get goal invites: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# RESPOND TO INVITE
# ============================================================

@router.post("/goals/invites/{invite_id}/respond", response_model=GoalInviteResponse)
async def respond_to_invite(
    user_id: str,
    invite_id: str,
    request: InviteResponseRequest,
):
    """Accept or decline a goal invite."""
    logger.info(f"User {user_id} responding to invite {invite_id}: accept={request.accept}")

    try:
        db = get_supabase_db()
        today = date.today()
        week_start, week_end = get_iso_week_boundaries(today)
        now = datetime.now(timezone.utc)

        # Get invite
        invite_result = db.client.table("goal_invites").select(
            "*, weekly_personal_goals!inner(*)"
        ).eq("id", invite_id).eq("invitee_id", user_id).execute()

        if not invite_result.data:
            raise HTTPException(status_code=404, detail="Invite not found")

        invite = invite_result.data[0]

        if invite["status"] != "pending":
            raise HTTPException(status_code=400, detail=f"Invite is not pending (status: {invite['status']})")

        # Check if expired
        expires_at = datetime.fromisoformat(invite["expires_at"].replace("Z", "+00:00"))
        if expires_at < now:
            db.client.table("goal_invites").update({
                "status": "expired"
            }).eq("id", invite_id).execute()
            raise HTTPException(status_code=400, detail="Invite has expired")

        created_goal_id = None

        if request.accept:
            # Accept - create goal and shared record
            goal_data = invite["weekly_personal_goals"]

            # Check for existing goal
            existing = db.client.table("weekly_personal_goals").select("id").eq(
                "user_id", user_id
            ).eq("exercise_name", goal_data["exercise_name"]).eq(
                "goal_type", goal_data["goal_type"]
            ).eq("week_start", week_start.isoformat()).execute()

            if existing.data:
                raise HTTPException(
                    status_code=400,
                    detail=f"You already have a goal for {goal_data['exercise_name']} this week"
                )

            # Get personal best
            pb_result = db.client.table("personal_goal_records").select("record_value").eq(
                "user_id", user_id
            ).eq("exercise_name", goal_data["exercise_name"]).eq(
                "goal_type", goal_data["goal_type"]
            ).execute()

            personal_best = pb_result.data[0]["record_value"] if pb_result.data else None

            # Create goal
            new_goal_data = {
                "user_id": user_id,
                "exercise_name": goal_data["exercise_name"],
                "goal_type": goal_data["goal_type"],
                "target_value": goal_data["target_value"],
                "week_start": week_start.isoformat(),
                "week_end": week_end.isoformat(),
                "personal_best": personal_best,
                "status": "active",
                "current_value": 0,
                "is_pr_beaten": False,
                "is_shared": True,
                "visibility": "friends",
            }

            new_goal_result = db.client.table("weekly_personal_goals").insert(new_goal_data).execute()

            if not new_goal_result.data:
                raise HTTPException(status_code=500, detail="Failed to create goal")

            new_goal = new_goal_result.data[0]
            created_goal_id = new_goal["id"]

            # Create shared_goals record
            shared_data = {
                "original_goal_id": invite["goal_id"],
                "source_user_id": invite["inviter_id"],
                "joined_user_id": user_id,
                "joined_goal_id": created_goal_id,
                "status": "active",
            }

            db.client.table("shared_goals").insert(shared_data).execute()

            # Mark original goal as shared
            db.client.table("weekly_personal_goals").update({
                "is_shared": True
            }).eq("id", invite["goal_id"]).execute()

            # Update invite status
            db.client.table("goal_invites").update({
                "status": "accepted",
                "responded_at": now.isoformat(),
            }).eq("id", invite_id).execute()

            logger.info(f"✅ User {user_id} accepted invite, created goal {created_goal_id}")

        else:
            # Decline
            db.client.table("goal_invites").update({
                "status": "declined",
                "responded_at": now.isoformat(),
            }).eq("id", invite_id).execute()

            logger.info(f"✅ User {user_id} declined invite {invite_id}")

        # Fetch updated invite
        updated = db.client.table("goal_invites").select("*").eq("id", invite_id).execute()

        return GoalInviteResponse(
            invite=GoalInvite(**updated.data[0]),
            created_goal_id=created_goal_id,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to respond to invite: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# DELETE INVITE (Cancel)
# ============================================================

@router.delete("/goals/invites/{invite_id}")
async def cancel_invite(
    user_id: str,
    invite_id: str,
):
    """Cancel a sent invite."""
    logger.info(f"User {user_id} canceling invite {invite_id}")

    try:
        db = get_supabase_db()

        # Verify invite was sent by user
        invite = db.client.table("goal_invites").select("id").eq(
            "id", invite_id
        ).eq("inviter_id", user_id).eq("status", "pending").execute()

        if not invite.data:
            raise HTTPException(status_code=404, detail="Invite not found or already responded to")

        db.client.table("goal_invites").delete().eq("id", invite_id).execute()

        logger.info(f"✅ Canceled invite {invite_id}")

        return {"status": "deleted", "invite_id": invite_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to cancel invite: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# PENDING INVITES COUNT
# ============================================================

@router.get("/goals/invites/pending-count", response_model=PendingInvitesSummary)
async def get_pending_invites_count(user_id: str):
    """Get count of pending invites for badge display."""
    logger.info(f"Getting pending invites count for user: {user_id}")

    try:
        db = get_supabase_db()
        now = datetime.now(timezone.utc)
        soon_threshold = now + timedelta(hours=24)

        result = db.client.table("goal_invites").select(
            "created_at, expires_at"
        ).eq("invitee_id", user_id).eq("status", "pending").gt(
            "expires_at", now.isoformat()
        ).execute()

        if not result.data:
            return PendingInvitesSummary(
                pending_count=0,
                oldest_invite_at=None,
                expires_soon_count=0,
            )

        oldest = min(row["created_at"] for row in result.data)
        expires_soon = sum(
            1 for row in result.data
            if datetime.fromisoformat(row["expires_at"].replace("Z", "+00:00")) < soon_threshold
        )

        return PendingInvitesSummary(
            pending_count=len(result.data),
            oldest_invite_at=datetime.fromisoformat(oldest.replace("Z", "+00:00")),
            expires_soon_count=expires_soon,
        )

    except Exception as e:
        logger.error(f"Failed to get pending invites count: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def _calc_progress(current: int, target: int) -> float:
    """Calculate progress percentage."""
    if target <= 0:
        return 0.0
    return min(100.0, (current / target) * 100)


def _build_goal_response(row: dict, today: date) -> WeeklyPersonalGoal:
    """Build a WeeklyPersonalGoal response with computed fields."""
    goal = WeeklyPersonalGoal(**row)

    # Calculate progress percentage
    if goal.target_value > 0:
        goal.progress_percentage = min(100.0, (goal.current_value / goal.target_value) * 100)

    # Calculate days remaining
    if isinstance(goal.week_end, str):
        week_end = date.fromisoformat(goal.week_end)
    else:
        week_end = goal.week_end

    goal.days_remaining = max(0, (week_end - today).days + 1)

    return goal
