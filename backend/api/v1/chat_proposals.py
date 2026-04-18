"""
Chat proposal apply / dismiss endpoints.

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
"""
from __future__ import annotations

import asyncio
import hmac
from datetime import datetime, timezone
from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
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
