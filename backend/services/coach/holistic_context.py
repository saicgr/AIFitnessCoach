"""Holistic user-context assembler for food-capable agents (Gaps 7 + 17).

ONE place that unifies the signals a recommendation should be grounded in, so the
nutrition agent, the coach agent, and the dedicated recommendation/synthesis agent
all reason from the same picture and never drift:

- `resolve_dietary_constraints(user_id)` — the single dietary source of truth.
  A user can be "vegan" in THREE places: `nutrition_preferences.diet_type`,
  `nutrition_preferences.dietary_restrictions[]`, and `coach_memory` (category
  'dietary', said in chat). Historically agents only read `dietary_restrictions`,
  so a diet_type-only vegan could get a meat suggestion. This unions all three
  (+ allergies / custom allergens / dislikes) and emits a HARD rule string.

- `build_holistic_context(user_id, ...)` — assembles the full cross-domain block
  (memory, training-load/ACWR, wearable health/recovery, today's nutrition, and
  dietary constraints) by reusing the existing fetchers. Every block is
  best-effort: a single failure never breaks the turn.

Grounding/safety: this module only AGGREGATES real, already-computed signals — it
never classifies safety with an LLM (`feedback_no_llm_for_safety_classification`)
and never fabricates numbers. Callers render the blocks; medical disclaimer is
shown by the UI.
"""
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# diet_type values that are an actual eating pattern (a real constraint) vs a
# neutral macro preset. A real diet_type joins the restriction set.
_NEUTRAL_DIET_TYPES = {"", "balanced", "custom", "standard", "none"}


def resolve_dietary_constraints(user_id: str, db: Any = None) -> Dict[str, Any]:
    """Union the user's dietary truth across structured prefs + coach memory.

    Returns ``{restrictions, allergies, dislikes, diet_type, notes, hard_rule,
    summary_line, has_any}``. Never raises — returns an empty (permissive) set
    on any failure so a recommendation still works, just without enforcement.
    """
    db = db or get_supabase_db()
    restrictions: List[str] = []
    allergies: List[str] = []
    dislikes: List[str] = []
    notes: List[str] = []
    diet_type = ""

    try:
        prefs = db.get_nutrition_preferences(user_id) or {}
        diet_type = (prefs.get("diet_type") or "").strip().lower()
        restrictions = [str(r) for r in (prefs.get("dietary_restrictions") or []) if r]
        # A real eating-pattern diet_type (vegan/vegetarian/keto/…) is itself a
        # restriction the recommender must honor — fold it in.
        if diet_type and diet_type not in _NEUTRAL_DIET_TYPES and diet_type not in restrictions:
            restrictions.append(diet_type)
        allergies = [str(a) for a in (prefs.get("allergies") or []) if a]
        allergies += [str(a) for a in (prefs.get("custom_allergens") or []) if a]
        dislikes = [str(d) for d in (prefs.get("disliked_foods") or []) if d]
    except Exception as e:
        logger.warning(f"[holistic] dietary prefs read failed for {user_id}: {e}")

    # Chat-derived dietary memory (category 'dietary') supplements the structured
    # prefs — e.g. the user told the coach "I'm vegan" but never set it in settings.
    try:
        mems = db.memory.list_injectable(user_id, limit=60) or []
        for m in mems:
            if (m.get("category") or "").lower() == "dietary":
                txt = (m.get("content") or m.get("text") or "").strip()
                if txt:
                    notes.append(txt)
    except Exception as e:
        logger.debug(f"[holistic] dietary memory read skipped for {user_id}: {e}")

    # De-dupe, preserve order.
    restrictions = list(dict.fromkeys(restrictions))
    allergies = list(dict.fromkeys(allergies))

    has_any = bool(restrictions or allergies or notes)
    rule_parts: List[str] = []
    if restrictions:
        rule_parts.append("dietary restrictions: " + ", ".join(restrictions))
    if allergies:
        rule_parts.append("ALLERGIES (never include, even trace): " + ", ".join(allergies))
    if dislikes:
        rule_parts.append("dislikes (avoid if possible): " + ", ".join(dislikes))
    if notes:
        rule_parts.append("noted in conversation: " + "; ".join(notes[:3]))

    hard_rule = (
        "HARD DIETARY RULE — never recommend or suggest a food that violates these; "
        + " | ".join(rule_parts)
        if has_any
        else ""
    )
    summary_line = (
        ("Diet: " + ", ".join(restrictions) if restrictions else "Diet: no restrictions")
        + (f"; allergies: {', '.join(allergies)}" if allergies else "")
    )

    return {
        "restrictions": restrictions,
        "allergies": allergies,
        "dislikes": dislikes,
        "diet_type": diet_type,
        "notes": notes,
        "has_any": has_any,
        "hard_rule": hard_rule,
        "summary_line": summary_line,
    }


def get_onboarding_signals(user_id: str, db: Any = None) -> Dict[str, Any]:
    """Read the captured-but-unused onboarding signals from preferences JSONB.

    Returns ``{sleep_quality, obstacles, motivations, workout_variety,
    past_blockers}`` with safe defaults (None for the scalar, [] for the lists).
    Never raises — a failure returns the empty/default shape so every caller
    fails open (output byte-identical to today when no signal is present).

    Note: ``workout_variety`` is stored in preferences under the
    ``exercise_consistency`` key (see ``merge_extended_fields_into_preferences``),
    so we read that first and fall back to a raw ``workout_variety`` key.
    """
    empty: Dict[str, Any] = {
        "sleep_quality": None,
        "obstacles": [],
        "motivations": [],
        "workout_variety": None,
        "past_blockers": [],
        "primary_whys": [],
    }
    db = db or get_supabase_db()
    try:
        user = db.get_user(user_id) or {}
    except Exception as e:
        logger.debug(f"[holistic] onboarding signals read failed for {user_id}: {e}")
        return dict(empty)

    prefs = user.get("preferences")
    if isinstance(prefs, str):
        try:
            import json as _json
            prefs = _json.loads(prefs)
        except (ValueError, TypeError):
            prefs = {}
    if not isinstance(prefs, dict):
        prefs = {}

    def _as_list(value: Any) -> List[str]:
        if isinstance(value, list):
            return [str(v) for v in value if v is not None and str(v).strip()]
        if isinstance(value, str) and value.strip():
            return [value.strip()]
        return []

    def _as_str(value: Any) -> Optional[str]:
        if isinstance(value, str) and value.strip():
            return value.strip()
        return None

    return {
        "sleep_quality": _as_str(prefs.get("sleep_quality")),
        "obstacles": _as_list(prefs.get("obstacles")),
        "motivations": _as_list(prefs.get("motivations")),
        "workout_variety": _as_str(
            prefs.get("exercise_consistency") or prefs.get("workout_variety")
        ),
        "past_blockers": _as_list(prefs.get("past_blockers")),
        "primary_whys": _as_list(prefs.get("primary_whys")),
    }


async def build_holistic_context(
    user_id: str,
    timezone_str: str = "UTC",
    current_message: Optional[str] = None,
    include_nutrition: bool = True,
) -> Dict[str, Any]:
    """Assemble the full cross-domain context for a grounded recommendation.

    Reuses the existing fetchers; every block is best-effort. Returns a dict of
    optional blocks the caller renders into a prompt:
      memory_block (str) / memory_ref_ids (list)
      cardio_block (str|None)   — training load / ACWR
      health_block (str|None)   — sleep / recovery / steps / HR (wearable)
      nutrition (dict|None)     — today's macros remaining + recent meals
      dietary (dict)            — resolve_dietary_constraints output
    """
    out: Dict[str, Any] = {
        "memory_block": "",
        "memory_ref_ids": [],
        "cardio_block": None,
        "health_block": None,
        "nutrition": None,
        "dietary": resolve_dietary_constraints(user_id),
    }

    # Memory (sync) — injuries + durable prefs + open loops.
    try:
        from services.coach.memory.injector import build_memory_block
        block, ref_ids = build_memory_block(user_id, current_message, limit=8)
        out["memory_block"] = block or ""
        out["memory_ref_ids"] = ref_ids or []
    except Exception as e:
        logger.warning(f"[holistic] memory block failed for {user_id}: {e}")

    # Training load / ACWR (async).
    try:
        from services.user_context.cardio_activity import get_cardio_context_for_ai
        out["cardio_block"] = await get_cardio_context_for_ai(user_id)
    except Exception as e:
        logger.debug(f"[holistic] cardio context skipped for {user_id}: {e}")

    # Wearable health / recovery / sleep (async).
    try:
        from services.user_context.service import UserContextService
        out["health_block"] = await UserContextService().get_health_context_for_ai(
            user_id, days=7
        )
    except Exception as e:
        logger.debug(f"[holistic] health context skipped for {user_id}: {e}")

    # Today's nutrition (async) — macros remaining + recent meals.
    if include_nutrition:
        try:
            from services.langgraph_agents.tools.nutrition_context_helpers import (
                fetch_daily_nutrition_context,
            )
            out["nutrition"] = await fetch_daily_nutrition_context(user_id, timezone_str)
        except Exception as e:
            logger.debug(f"[holistic] nutrition context skipped for {user_id}: {e}")

    return out
