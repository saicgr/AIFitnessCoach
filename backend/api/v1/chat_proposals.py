"""
Chat proposal apply / dismiss endpoints + the coach workout card's
deterministic Schedule action.

When the Workout agent stages a change via the `propose_workout_change` tool,
a row lands in `chat_pending_proposals` and the assistant message returns a
`proposal_id` + `proposal_token` in `action_data`. The Flutter client shows
an Apply / Not now card. These endpoints consume the proposal.

Security model:
- get_current_user validates the JWT and yields the backend users.id.
- The proposal row's user_id is matched against current_user["id"].
- A short random proposal_token is required as a shared secret in the body
  so the action_data blob alone (if leaked) can't be replayed by another
  client. Compared constant-time.
- Expired rows return 410; already-consumed rows return 409.

POST /chat/workout-card/schedule exists because the card's Schedule chip used
to re-enter the LLM with the free text "Schedule this workout for tomorrow."
(E2E row 99). The model has no handle on the card's identity, so it AUTHORED A
NEW WORKOUT — different exercises, same title — and scheduled nothing: the user's
chosen workout was silently discarded and `workouts` gained no row. The chip must
carry the workout_id and schedule THAT row deterministically, with no model in
the loop.
"""
import asyncio
import hmac
import re
from datetime import date as date_cls, datetime, timedelta, timezone
from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.timezone_utils import (
    get_user_today,
    resolve_timezone,
    target_date_to_utc_iso,
    utc_to_local_date,
)
from services.langgraph_agents.tools.workout_tools import (
    add_exercise_to_workout,
    remove_exercise_from_workout,
    replace_all_exercises,
    modify_workout_intensity,
    reschedule_workout,
)

router = APIRouter()
logger = get_logger(__name__)


# Map proposal.action → the concrete LangChain tool that executes it.
# replace_exercise and add_exercise both route through add+remove semantics
# via the existing tools (no dedicated single-swap tool).
_ACTION_DISPATCH = {
    "add_exercise": add_exercise_to_workout,
    "remove_exercise": remove_exercise_from_workout,
    "replace_all_exercises": replace_all_exercises,
    "modify_intensity": modify_workout_intensity,
    "reschedule": reschedule_workout,
}


class ProposalActionRequest(BaseModel):
    """Body for apply / dismiss — just the shared secret from action_data."""
    proposal_token: str = Field(..., min_length=4, max_length=128)


def _parse_expires_at(raw: Any) -> Optional[datetime]:
    """Parse the Postgres timestamptz string back into an aware datetime."""
    if raw is None:
        return None
    if isinstance(raw, datetime):
        return raw if raw.tzinfo else raw.replace(tzinfo=timezone.utc)
    if isinstance(raw, str):
        try:
            # Postgres "2026-04-18 01:23:45.678+00" — normalize to ISO8601.
            normalized = raw.replace(" ", "T")
            if normalized.endswith("+00"):
                normalized = normalized[:-3] + "+00:00"
            return datetime.fromisoformat(normalized)
        except ValueError:
            logger.warning(f"Could not parse expires_at: {raw!r}")
            return None
    return None


def _load_and_validate(proposal_id: str, token: str, user_id: str) -> Dict[str, Any]:
    """Fetch the proposal row and enforce ownership / token / status / expiry.

    Raises HTTPException with the right status code for each failure mode so
    the client can map them to distinct UI states (expired card, already-
    applied marker, etc.). Returns the row on success.
    """
    db = get_supabase_db()
    result = (
        db.client.table("chat_pending_proposals")
        .select("*")
        .eq("id", proposal_id)
        .limit(1)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Proposal not found")

    row = result.data[0]

    # Constant-time token compare to avoid leaking length/prefix via timing.
    if not hmac.compare_digest(str(row.get("proposal_token", "")), str(token)):
        logger.warning(
            f"Proposal token mismatch for proposal_id={proposal_id} user={user_id}"
        )
        raise HTTPException(status_code=401, detail="Invalid proposal token")

    if str(row["user_id"]) != str(user_id):
        logger.warning(
            f"IDOR blocked: user {user_id} tried to act on proposal "
            f"{proposal_id} owned by {row['user_id']}"
        )
        raise HTTPException(status_code=403, detail="Access denied")

    if row["status"] != "pending":
        raise HTTPException(
            status_code=409,
            detail=f"Proposal already {row['status']}",
        )

    expires_at = _parse_expires_at(row.get("expires_at"))
    if expires_at is not None and expires_at < datetime.now(timezone.utc):
        # Flip status so subsequent reads don't keep hitting the clock.
        try:
            db.client.table("chat_pending_proposals").update(
                {"status": "expired"}
            ).eq("id", proposal_id).eq("status", "pending").execute()
        except Exception as e:
            logger.warning(f"Failed to flip expired proposal {proposal_id}: {e}")
        raise HTTPException(status_code=410, detail="Proposal expired")

    return row


def _dispatch_tool(row: Dict[str, Any]) -> Dict[str, Any]:
    """Run the mutation tool that matches the staged action."""
    action = row["action"]
    tool_args = row.get("tool_args") or {}
    workout_id = row["workout_id"]

    tool = _ACTION_DISPATCH.get(action)
    if tool is None:
        logger.error(f"No dispatch for proposal action {action!r}")
        raise HTTPException(
            status_code=500,
            detail=f"Proposal action {action!r} is not executable.",
        )

    # Every workout mutation tool takes workout_id + action-specific args.
    # The LLM-provided tool_args are merged with the stored workout_id so
    # the client can't forge a different workout target on apply.
    invoke_args = {**tool_args, "workout_id": workout_id}

    logger.info(
        f"Dispatching proposal {row['id']} → {action} on workout {workout_id}"
    )
    # LangChain @tool wraps functions; .invoke honors the schema and handles
    # both sync and async tool callables consistently.
    return tool.invoke(invoke_args)


def _mark_applied(proposal_id: str) -> None:
    db = get_supabase_db()
    db.client.table("chat_pending_proposals").update(
        {"status": "applied", "applied_at": datetime.now(timezone.utc).isoformat()}
    ).eq("id", proposal_id).eq("status", "pending").execute()


def _mark_dismissed(proposal_id: str) -> None:
    db = get_supabase_db()
    db.client.table("chat_pending_proposals").update(
        {"status": "dismissed"}
    ).eq("id", proposal_id).eq("status", "pending").execute()


@router.post("/proposals/{proposal_id}/apply")
async def apply_proposal(
    proposal_id: str,
    body: ProposalActionRequest,
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """Apply a pending workout-change proposal. See module docstring for
    the status-code contract (404/401/403/409/410)."""
    user_id = str(current_user["id"])
    try:
        row = _load_and_validate(proposal_id, body.proposal_token, user_id)

        # The mutation tools do sync DB + RAG work internally. Run on a
        # worker thread so we don't block the event loop.
        tool_result = await asyncio.to_thread(_dispatch_tool, row)

        if not isinstance(tool_result, dict) or not tool_result.get("success"):
            # Don't mark applied — leave the proposal pending so the user can
            # retry after whatever backend issue gets fixed.
            logger.warning(
                f"Proposal {proposal_id} mutation failed: {tool_result}"
            )
            return {
                "success": False,
                "proposal_id": proposal_id,
                "detail": (
                    tool_result.get("message")
                    if isinstance(tool_result, dict)
                    else "Mutation failed"
                ),
            }

        _mark_applied(proposal_id)
        logger.info(f"Applied proposal {proposal_id} for user {user_id}")

        return {
            "success": True,
            "proposal_id": proposal_id,
            "action": row["action"],
            "applied": tool_result,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "apply_proposal")


@router.post("/proposals/{proposal_id}/dismiss")
async def dismiss_proposal(
    proposal_id: str,
    body: ProposalActionRequest,
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """Mark a pending proposal as dismissed. Idempotent-ish: already-applied
    or already-dismissed rows return 409 so the UI can update its state."""
    user_id = str(current_user["id"])
    try:
        _load_and_validate(proposal_id, body.proposal_token, user_id)
        _mark_dismissed(proposal_id)
        return {"success": True, "proposal_id": proposal_id, "status": "dismissed"}
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "dismiss_proposal")


# ─────────────────────────────────────────────────────────────────────────────
# Coach workout card — deterministic Schedule action (E2E row 99)
# ─────────────────────────────────────────────────────────────────────────────

_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE,
)


class ScheduleWorkoutCardRequest(BaseModel):
    """Body for POST /chat/workout-card/schedule.

    `workout_id` is the identity of the workout ON THE CARD — that is the whole
    point of this endpoint. Exactly one of `target_date` / `days_from_today`
    decides when; `days_from_today` is the default so the client never has to
    compute a date (and therefore can never compute it in the wrong timezone).
    """
    workout_id: str = Field(..., max_length=64)
    target_date: Optional[str] = Field(
        default=None,
        description="Local calendar date YYYY-MM-DD. Omit to use days_from_today.",
    )
    days_from_today: Optional[int] = Field(
        default=None, ge=0, le=365,
        description="Offset from the user's local today. 1 = tomorrow.",
    )


def _resolve_target_local_date(
    body: ScheduleWorkoutCardRequest, tz: str
) -> str:
    """The user-local YYYY-MM-DD this workout should land on."""
    if body.target_date:
        try:
            parsed = date_cls.fromisoformat(body.target_date.strip())
        except ValueError:
            raise HTTPException(
                status_code=422,
                detail="target_date must be a calendar date in YYYY-MM-DD form",
            )
        return parsed.isoformat()

    offset = 1 if body.days_from_today is None else body.days_from_today
    today = date_cls.fromisoformat(get_user_today(tz))
    return (today + timedelta(days=offset)).isoformat()


@router.post("/workout-card/schedule")
async def schedule_workout_from_card(
    request: Request,
    body: ScheduleWorkoutCardRequest,
    current_user: dict = Depends(get_current_user),
) -> Dict[str, Any]:
    """Schedule THE WORKOUT ON THE CARD onto a chosen local day. No LLM.

    Deterministic end-to-end: the workout is looked up by id, ownership is
    enforced, and `workouts.scheduled_date` is written at NOON of the target
    local day (CLAUDE.md convention — a bare date sits at 00:00Z and falls
    outside its own local-day window for every negative-offset user).

    Deliberately does NOT swap with whatever already sits on the target day:
    displacing the user's planned session to make room for a chat-generated one
    is destructive, and `workouts` supports several rows per day.

    Returns the PERSISTED row so the card can render the real state rather than
    an optimistic guess.

    Status contract: 404 unknown workout · 403 not yours · 409 already completed
    · 422 malformed date · 500 write rejected.
    """
    user_id = str(current_user["id"])
    workout_id = body.workout_id.strip()
    if not _UUID_RE.match(workout_id):
        raise HTTPException(status_code=422, detail="workout_id must be a UUID")

    try:
        db = get_supabase_db()
        workout = await asyncio.to_thread(db.get_workout, workout_id)
        if not workout:
            raise HTTPException(status_code=404, detail="Workout not found")
        if str(workout.get("user_id")) != user_id:
            logger.warning(
                f"IDOR blocked: user {user_id} tried to schedule workout "
                f"{workout_id} owned by {workout.get('user_id')}"
            )
            raise HTTPException(status_code=403, detail="Access denied")
        if workout.get("is_completed"):
            raise HTTPException(
                status_code=409,
                detail="That workout is already completed — generate a new one to schedule.",
            )

        tz = resolve_timezone(request, db=db, user_id=user_id)
        target_local_date = _resolve_target_local_date(body, tz)
        previous_local_date = (
            utc_to_local_date(workout.get("scheduled_date"), tz)
            if workout.get("scheduled_date") else None
        )

        updated = await asyncio.to_thread(
            db.update_workout,
            workout_id,
            {
                "scheduled_date": target_date_to_utc_iso(target_local_date, tz),
                "last_modified_method": "coach_card_schedule",
            },
        )
        if not updated:
            # A write that changed nothing must never be reported as scheduled.
            logger.error(
                f"[workout-card/schedule] update wrote no row for {workout_id} "
                f"(user={user_id}, target={target_local_date})"
            )
            raise safe_internal_error(
                Exception("scheduled_date update returned no row"),
                "schedule_workout_from_card",
            )

        exercises = updated.get("exercises_json") or []
        logger.info(
            f"[workout-card/schedule] {workout_id} → {target_local_date} "
            f"({tz}) for user {user_id}"
        )
        return {
            "success": True,
            "workout_id": workout_id,
            "workout_name": updated.get("name"),
            "scheduled_local_date": target_local_date,
            "previous_local_date": previous_local_date,
            "scheduled_date": updated.get("scheduled_date"),
            "timezone": tz,
            "exercise_count": len(exercises) if isinstance(exercises, list) else 0,
            "workout": updated,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "schedule_workout_from_card")
