"""
Issue 2: Equipment-identification tool for the chat AI coach.

Wraps the snap-equipment pipeline (`equipment_snap_core` in
`api/v1/equipment/snap.py`) as a LangGraph tool so the Coach agent can
answer "what's this?" when the user attaches a gym-equipment photo to
chat. The HTTP endpoint and the tool both call the SAME core function —
no behavior drift.

Strict envelope (matches the rest of the tool surface)::

    {
      "success": bool,
      "action_data": {
        "action": "open_swap_or_add",
        "matches": [...],
        "canonical_name": Optional[str],
        "snapped_equipment_id": Optional[str],
        ...
      },
      "summary_text": str,
      "requires_confirmation": False,
    }

Frontend (`chat_repository_part_chat_messages_notifier.dart`) handles
``action == 'open_swap_or_add'`` by rendering EquipmentMatchCard with up
to 3 ranked matches; tapping Swap/Add deeplinks into the appropriate
sheet (active workout) or the quick-workout generator (no active
workout).

Reuse window
------------
If the same s3_key was classified within the last 60 seconds the core
function returns the cached snapped_equipment row instead of re-billing
Vision (edge case 29).

No silent fallback — every error path surfaces a useful summary_text
(feedback_no_silent_fallbacks).
"""
from __future__ import annotations

import asyncio
from typing import Any, Dict, Optional

from langchain_core.tools import tool

from core.logger import get_logger

logger = get_logger(__name__)


def _ok_envelope(action_data: Dict[str, Any], summary: str) -> Dict[str, Any]:
    return {
        "success": True,
        "action_data": action_data,
        "summary_text": summary,
        "requires_confirmation": False,
    }


def _fail_envelope(summary: str, payload: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    return {
        "success": False,
        "action_data": {"action": "open_swap_or_add", **(payload or {})},
        "summary_text": summary,
        "requires_confirmation": False,
    }


@tool
def identify_equipment(s3_key: str, user_id: str) -> Dict[str, Any]:
    """
    Identify a piece of gym equipment in a user-uploaded photo and
    return ranked exercise matches the user can do on it.

    Use this tool when the user attaches a photo of a gym machine /
    rack / cable station / barbell setup to chat and asks "what is
    this?", "what can I do on this?", or simply sends the photo with
    no caption. The tool runs Gemini Vision + EquipmentResolver +
    exercise-library lookup, then returns matches ranked by personal
    last-30-day usage.

    Args:
        s3_key: S3 object key of the already-uploaded photo (the chat
            pipeline uploads media to S3 before invoking tools, so the
            key is always known by the time we tool-call).
        user_id: UUID of the requesting user (used for usage rerank and
            quota enforcement).

    Returns:
        Strict tool envelope. ``action_data.action`` is always
        ``open_swap_or_add``. Frontend renders the matches as a
        chat-card with Swap/Add buttons per match.
    """
    if not s3_key:
        return _fail_envelope("I couldn't find the photo — try resending it.")
    if not user_id:
        return _fail_envelope("Couldn't read your profile — please sign in again.")

    # Lazy import: the snap module pulls in heavy AWS / Gemini deps,
    # and we want tool import-time to stay cheap.
    try:
        from api.v1.equipment.snap import equipment_snap_core
    except Exception as e:  # pragma: no cover — only in degraded envs
        logger.error(f"❌ [identify_equipment] core import failed: {e}", exc_info=True)
        return _fail_envelope(
            "Equipment classifier is offline right now. Try again in a minute."
        )

    try:
        # The @tool decorator runs the function synchronously. We bridge
        # to the async core via `asyncio.run` (or fall back to the
        # already-running loop if one exists, e.g. inside the LangGraph
        # asyncio executor).
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            loop = None

        if loop and loop.is_running():
            future = asyncio.run_coroutine_threadsafe(
                equipment_snap_core(user_id=user_id, s3_key=s3_key, mode="identify"),
                loop,
            )
            response = future.result(timeout=30)
        else:
            response = asyncio.run(
                equipment_snap_core(user_id=user_id, s3_key=s3_key, mode="identify")
            )
    except Exception as e:
        logger.error(f"❌ [identify_equipment] core failed: {e}", exc_info=True)
        return _fail_envelope(
            "Couldn't classify the photo — please try a clearer shot.",
            {"reason": "classifier_error"},
        )

    # `response` is a SnapResponse pydantic model.
    matched = bool(getattr(response, "matched", False))
    canonical = getattr(response, "equipment_canonical_name", None)
    snap_id = getattr(response, "snapped_equipment_id", None)
    matches = list(getattr(response, "matches", []) or [])
    vision_label = getattr(response, "vision_label", None)
    unmatched_reason = getattr(response, "unmatched_reason", None)
    raw_name = getattr(response, "raw_name", None)

    if matched and canonical:
        # Truncate to 3 for the chat card; full list lives on the snapped row.
        top_matches = matches[:3]
        names = [m.get("name", "?") for m in top_matches]
        if names:
            summary = (
                f"Looks like a {canonical.replace('_', ' ')}. "
                f"Top matches: {', '.join(names)}."
            )
        else:
            summary = (
                f"Looks like a {canonical.replace('_', ' ')}, but I don't have any "
                f"exercises in your library for it yet — added it to your gym profile."
            )
        return _ok_envelope(
            {
                "action": "open_swap_or_add",
                "matches": top_matches,
                "canonical_name": canonical,
                "snapped_equipment_id": snap_id,
                "all_matches_count": len(matches),
            },
            summary,
        )

    # Unmatched paths — return success=True with empty matches so the
    # frontend still renders an EquipmentMatchCard with the
    # "Create custom exercise" CTA (edge case 30).
    if unmatched_reason == "not_equipment":
        return _ok_envelope(
            {
                "action": "open_swap_or_add",
                "matches": [],
                "canonical_name": None,
                "snapped_equipment_id": None,
                "vision_label": vision_label,
                "unmatched_reason": "not_equipment",
            },
            "That doesn't look like gym equipment to me — try snapping a "
            "machine, rack, or barbell setup.",
        )

    # low_confidence / no_canonical → "couldn't recognize" with a CTA.
    return _ok_envelope(
        {
            "action": "open_swap_or_add",
            "matches": [],
            "canonical_name": None,
            "snapped_equipment_id": snap_id,
            "raw_name": raw_name,
            "unmatched_reason": unmatched_reason or "unknown",
        },
        "I couldn't recognize this one — but I'll remember it. "
        "Want to add it as a custom exercise?",
    )


# Public registry — appended to ALL_TOOLS via tools/__init__.py
ISSUE_2_EQUIPMENT_TOOLS = [identify_equipment]
