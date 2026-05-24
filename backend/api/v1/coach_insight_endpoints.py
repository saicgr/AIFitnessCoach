"""
Coach Insight Endpoints (SLICE_COACH)
=====================================
Surfaces short, deterministic "Coach's take" insights for cardio detail
screens. Currently exposes:

    GET /coach/cardio-insight/{cardio_log_id}

The wired frontend (later wave) shows the result as an italic 1-2 sentence
line beneath the synced workout detail header. This file is the
authoritative source: builds the cardio context, invokes the coach agent's
response node with `source="cardio_auto_insight"`, validates ownership,
caches per (cardio_log_id, updated_at), and dedupes concurrent mounts via
an asyncio.Lock keyed by cardio_log_id.

Hard rules:
- The user MUST own the cardio_log row. Cross-user fetch returns 403 — never
  the cached insight from the real owner.
- The endpoint NEVER fabricates the insight. If the coach reply is empty
  (the prompt explicitly allows this when nothing is notable), the endpoint
  returns HTTP 204.
- Cache is per-process and is invalidated whenever cardio_logs.updated_at
  changes for the given row. Per-row asyncio.Lock dedupes concurrent
  generation so simultaneous mounts only invoke Gemini once.
"""
from __future__ import annotations

import asyncio
import logging
from typing import Any, Dict, Optional, Tuple

from fastapi import APIRouter, Depends, HTTPException, Path, Response

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from services.user_context.cardio_activity import get_cardio_context_for_ai

logger = logging.getLogger("coach_cardio_insight")

router = APIRouter()


# ---------------------------------------------------------------------------
# Per-process cache + per-row asyncio.Lock registry.
# Cache value = (updated_at_iso_string, insight_text_or_empty).
# ---------------------------------------------------------------------------
_INSIGHT_CACHE: Dict[str, Tuple[str, str]] = {}
_INFLIGHT_LOCKS: Dict[str, asyncio.Lock] = {}
_LOCK_REGISTRY_LOCK = asyncio.Lock()


def _reset_cache_for_tests() -> None:
    """Test-only helper — never called from production code paths."""
    _INSIGHT_CACHE.clear()
    _INFLIGHT_LOCKS.clear()


async def _get_lock(cardio_log_id: str) -> asyncio.Lock:
    """Return a per-row asyncio.Lock, creating it on first use.

    The registry insert itself is guarded by a global lock so two concurrent
    requests for the same id always get the SAME Lock object — otherwise the
    second request could create its own Lock and skip the dedupe.
    """
    lock = _INFLIGHT_LOCKS.get(cardio_log_id)
    if lock is not None:
        return lock
    async with _LOCK_REGISTRY_LOCK:
        lock = _INFLIGHT_LOCKS.get(cardio_log_id)
        if lock is None:
            lock = asyncio.Lock()
            _INFLIGHT_LOCKS[cardio_log_id] = lock
        return lock


async def _invoke_coach_for_insight(
    *, user_id: str, cardio_log_id: str
) -> str:
    """Build the cardio context, invoke the coach response node directly,
    return the trimmed reply. Empty string means "nothing notable to say".

    Imports are local so test mocks can override `coach_response_node` /
    `get_cardio_context_for_ai` cleanly at the module level.
    """
    from services.langgraph_agents.coach_agent.nodes import coach_response_node

    # health_context is intentionally NOT pre-fetched here — auto-insight is
    # cardio-focused and the health block would bias the reply away from the
    # session at hand. The user-facing AskCoach button path (chat) still
    # pre-fetches health_context as it does today.
    cardio_context = await get_cardio_context_for_ai(
        user_id=user_id, focus_cardio_log_id=cardio_log_id,
    )

    state: Dict[str, Any] = {
        "user_id": user_id,
        "user_message": (
            "Give me a one or two sentence cardio insight about THIS session "
            "compared to my recent history. If nothing is notable, reply with "
            "an empty string."
        ),
        "conversation_history": [],
        "rag_documents": [],
        "rag_context_formatted": "",
        "ai_response": "",
        "final_response": "",
        "rag_context_used": False,
        "similar_questions": [],
        "health_context": None,
        "cardio_context": cardio_context,
        "source": "cardio_auto_insight",
    }

    try:
        result = await coach_response_node(state)
    except Exception as e:
        logger.warning(f"[cardio_insight] coach_response_node failed: {e}")
        return ""

    reply = (result or {}).get("final_response") or ""
    return reply.strip()


@router.get("/cardio-insight/{cardio_log_id}")
async def get_cardio_insight(
    cardio_log_id: str = Path(..., description="cardio_logs.id (UUID)"),
    current_user: dict = Depends(get_current_user),
):
    """Return a short "Coach's take" for the given cardio_log row.

    Returns:
        200 { "insight": str, "cached": bool } on success.
        204 (no body) when there is nothing notable to say.
        403 when the row does not belong to the caller.
        404 when the row does not exist.
    """
    try:
        user_id = str(current_user["id"])
        sb = get_supabase_db()

        # --- Ownership + freshness probe (single query) ----------------------
        try:
            resp = (
                sb.client.table("cardio_logs")
                .select("id, user_id, updated_at")
                .eq("id", cardio_log_id)
                .limit(1)
                .execute()
            )
        except Exception as e:
            raise safe_internal_error(e, "cardio_insight_ownership")

        if not resp.data:
            raise HTTPException(status_code=404, detail="cardio_log not found")

        row = resp.data[0]
        if str(row.get("user_id")) != user_id:
            raise HTTPException(status_code=403, detail="not your cardio log")

        # Some legacy rows may lack updated_at — fall back to the id so the
        # cache key is still stable per row.
        updated_at = str(row.get("updated_at") or row.get("id"))

        # --- Cache hit? ------------------------------------------------------
        cached = _INSIGHT_CACHE.get(cardio_log_id)
        if cached and cached[0] == updated_at:
            insight = cached[1]
            if not insight:
                return Response(status_code=204)
            return {"insight": insight, "cached": True}

        # --- Inflight dedupe — only one generation per row at a time --------
        lock = await _get_lock(cardio_log_id)
        async with lock:
            # Re-check cache inside the lock — a sibling request that won the
            # race wrote the value while we were waiting.
            cached = _INSIGHT_CACHE.get(cardio_log_id)
            if cached and cached[0] == updated_at:
                insight = cached[1]
                if not insight:
                    return Response(status_code=204)
                return {"insight": insight, "cached": True}

            insight = await _invoke_coach_for_insight(
                user_id=user_id, cardio_log_id=cardio_log_id,
            )
            _INSIGHT_CACHE[cardio_log_id] = (updated_at, insight)

        if not insight:
            return Response(status_code=204)
        return {"insight": insight, "cached": False}
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "coach_cardio_insight")
