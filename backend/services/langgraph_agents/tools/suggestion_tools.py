"""
Suggested-action launcher chips for the chat coach.

The frontend renders ``action_data['suggested_actions']`` (a list of
quick-action IDs) as tappable launcher chips inside an assistant message — so
the coach can drop the user straight into a relevant feature ("scan this
menu", "check my form on video", "browse workouts") instead of only describing
it in prose.

This module owns both halves of that:
  1. ``suggest_actions`` — an LLM tool the nutrition + workout agents can call
     when a shortcut would genuinely help.
  2. ``inject_suggested_actions`` — called ONCE at the final response-assembly
     point for EVERY agent. It folds in any LLM-volunteered suggestions AND a
     few deterministic keyword backstops, then merges them into the outgoing
     ``action_data`` (alongside a primary action like ``food_analysis``, or as
     a standalone suggestions payload). Centralizing here means coach/hydration
     (which have no tool-execution loop) still get suggestions.
"""

from typing import Any, Dict, List, Optional

from langchain_core.tools import tool

from core.logger import get_logger

logger = get_logger(__name__)

# Mirror of the frontend `kChatLaunchableActionIds` allowlist in
# mobile/flutter/lib/screens/home/widgets/components/quick_action_launcher.dart.
# SECURITY GATE: the model may ONLY surface these IDs as chips — never
# settings / schedule / account / destructive surfaces. Keep the two in sync.
CHAT_LAUNCHABLE_ACTION_IDS = {
    # Nutrition scans / logging
    "scan_menu",
    "photo_food",
    "scan_food",
    "barcode_food",
    "scan_nutrition_label",
    "scan_app_screenshot",
    "food",
    # Workout entry points (the "workout menu")
    "quick_workout",
    "workout",
    "library",
    "programs",
    "history",
    # Equipment + form
    "identify_equipment",
    "attach_form_video",
    # Progress
    "photo",
    "progress",
}

# Cap so a chatty model can't flood the bubble. Backend order = priority; the
# frontend also caps independently.
MAX_SUGGESTIONS = 4


def _sanitize_ids(ids: Any) -> List[str]:
    """Drop unknown / disallowed / duplicate IDs, preserve order, cap length.

    This is the authoritative server-side filter — a hallucinated or malicious
    ID can never reach the client (the client filters again as defense-in-
    depth).
    """
    out: List[str] = []
    seen = set()
    if isinstance(ids, list):
        for raw in ids:
            cid = str(raw).strip()
            if not cid or cid in seen:
                continue
            if cid not in CHAT_LAUNCHABLE_ACTION_IDS:
                continue
            seen.add(cid)
            out.append(cid)
            if len(out) >= MAX_SUGGESTIONS:
                break
    return out


@tool
def suggest_actions(action_ids: List[str], prompt: str = "") -> Dict[str, Any]:
    """Surface tappable shortcut chips in the chat so the user can jump
    straight into a relevant app feature (scan a restaurant menu, snap a meal,
    check exercise form on video, browse workouts, etc.).

    Call this when a shortcut would genuinely help the user act on your advice:
      - they mention eating out / a restaurant / a menu -> ["scan_menu"]
      - they ask what's in a food but sent no photo -> ["photo_food", "scan_food"]
      - they ask about their form but sent no video -> ["attach_form_video"]
      - they want a workout to do -> ["quick_workout", "workout", "library"]
    Do NOT call it when you just analyzed the exact thing the shortcut opens
    (e.g. don't suggest scan_menu right after analyzing a menu photo).

    Args:
        action_ids: ordered shortcut IDs, most relevant first. Allowed IDs:
            scan_menu, photo_food, scan_food, barcode_food,
            scan_nutrition_label, scan_app_screenshot, food, quick_workout,
            workout, library, programs, history, identify_equipment,
            attach_form_video, photo, progress.
        prompt: short, friendly lead-in line shown above the chips (optional).

    Returns:
        action_data dict carrying the validated suggestions.
    """
    return {
        "action": "suggest_actions",
        "suggested_actions": _sanitize_ids(action_ids),
        "suggested_actions_prompt": (prompt or "").strip(),
    }


# Deterministic keyword backstops — high-precision, unambiguous cases so the
# chips appear even when the LLM doesn't volunteer the tool call.
_EATING_OUT_KEYWORDS = (
    "eat out",
    "eating out",
    "ate out",
    "restaurant",
    "what should i order",
    "what to order",
    "menu at",
    "dining out",
    "go out to eat",
    "going out to eat",
    "grab dinner",
    "grab lunch",
    "order at",
    "at a restaurant",
    "fast food",
    "drive thru",
    "drive-thru",
    "takeout",
    "take out",
    "food court",
)
_WANT_WORKOUT_KEYWORDS = (
    "what workout",
    "which workout",
    "workout should i",
    "give me a workout",
    "what should i train",
    "what to train",
    "workout for today",
    "workout idea",
    "what exercises should",
    "need a workout",
    "suggest a workout",
)
# `action_data['action']` values that mean a food result is already on screen —
# don't re-suggest the scan that produced it.
_FOOD_RESULT_ACTIONS = {
    "food_analysis",
    "food_logged",
    "analyze_menu",
    "analyze_buffet",
    "analyze_multi_food_images",
}


def inject_suggested_actions(
    action_data: Optional[Dict[str, Any]],
    *,
    user_message: str = "",
    selected_agent_value: str = "",
    tool_results: Optional[List[Dict[str, Any]]] = None,
) -> Optional[Dict[str, Any]]:
    """Fold launcher-chip suggestions into ``action_data``.

    Returns the (possibly newly created) ``action_data`` dict, or the original
    value (possibly ``None``) when there is nothing to add. Never clobbers an
    existing primary ``action`` — suggestions ride alongside it.
    """
    primary_action = (action_data or {}).get("action")
    suggestions: List[str] = []
    prompt = ""

    # 1) LLM-volunteered suggestions (suggest_actions tool result).
    for r in (tool_results or []):
        if isinstance(r, dict) and r.get("action") == "suggest_actions":
            suggestions.extend(r.get("suggested_actions") or [])
            if not prompt:
                prompt = (r.get("suggested_actions_prompt") or "").strip()

    # 2) Deterministic keyword backstops.
    ml = (user_message or "").lower()
    if primary_action not in _FOOD_RESULT_ACTIONS and any(
        k in ml for k in _EATING_OUT_KEYWORDS
    ):
        suggestions.append("scan_menu")
    if (
        selected_agent_value == "workout"
        and primary_action != "generate_quick_workout"
        and any(k in ml for k in _WANT_WORKOUT_KEYWORDS)
    ):
        suggestions.extend(["quick_workout", "workout", "library", "history"])

    valid = _sanitize_ids(suggestions)
    if not valid:
        return action_data

    data = dict(action_data) if action_data else {}
    # Standalone case: a previously-None action_data becomes a suggestions
    # payload. setdefault keeps any existing primary action intact.
    data.setdefault("action", "suggest_actions")
    data["suggested_actions"] = valid
    if prompt and not data.get("suggested_actions_prompt"):
        data["suggested_actions_prompt"] = prompt

    logger.info(
        "[SuggestedActions] surfaced %s (agent=%s, primary=%s)",
        valid,
        selected_agent_value or "?",
        primary_action,
    )
    return data
