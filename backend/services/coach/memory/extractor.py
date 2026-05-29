"""
Memory candidate extraction.

Given the latest chat exchange and the user's current memories, asks Gemini to
propose a small set of memory OPERATIONS (ADD/UPDATE/RESOLVE/REINFORCE/
CONTRADICT/NOOP). The model never writes directly — it proposes, the resolver
applies. Two cost guards:
  1. a cheap deterministic pre-filter that skips trivial turns with NO LLM call
  2. the per-user-per-day USD cap shared with the daily-insight surface

Returns a list of operation dicts (possibly empty). Never raises into the
caller — extraction failure must not affect the chat reply (it runs in a
BackgroundTask after the reply is already sent).
"""
from __future__ import annotations

import json
import logging
import re
from typing import Any, Dict, List, Optional

from google.genai import types

from core.config import get_settings
from services.gemini.constants import cost_tracker, gemini_generate_with_retry
from services.coach.memory.schemas import (
    MAX_MEMORY_USD_PER_USER_PER_DAY,
    SUGGESTED_CATEGORIES,
)

logger = logging.getLogger("coach_memory.extractor")

# Turns shorter than this (after trimming) almost never carry a durable fact;
# skip the LLM call entirely. Greetings, "ok", "thanks", "yes", etc.
_MIN_MEANINGFUL_CHARS = 12
_TRIVIAL_RE = re.compile(
    r"^(hi|hey|hello|yo|ok|okay|k|thanks|thank you|ty|cool|nice|great|got it|"
    r"yes|no|yep|nope|sure|lol|haha|👍|🙏)\W*$",
    re.IGNORECASE,
)

_SYSTEM = """You maintain a fitness coach's long-term memory about ONE user.
You are given the latest exchange and the user's CURRENT memories. Propose a
SMALL set of memory operations as STRICT JSON.

Extract ONLY durable, coach-relevant facts the USER asserted about themselves:
preferences, goals, constraints, equipment, dietary facts, injuries/pain,
life events affecting training, recurring schedule, motivation.

DO NOT extract:
- pleasantries, acknowledgements, or one-off questions
- anything that is just a number already tracked by the app (body weight,
  calories, steps, heart rate, completed-workout stats) — store the QUALITATIVE
  intent ("wants to lose weight") not the number
- the coach's own advice or statements
- speculation — only what the user actually said

Operations (op):
- ADD: a genuinely new fact not present in current memories
- UPDATE: refine/replace an existing memory (set target_id) — e.g. detail added
- RESOLVE: an existing OPEN-LOOP memory is now closed (set target_id) — e.g.
  user says the pain is gone / better
- REINFORCE: user restated an existing fact (set target_id), no new info
- CONTRADICT: user stated something that conflicts with an existing memory
  (set target_id) — the old one will be superseded
- NOOP: nothing worth remembering (return an empty operations list instead)

Fields per operation:
- op (required)
- target_id: id of the existing memory for UPDATE/RESOLVE/REINFORCE/CONTRADICT
- memory_type: one of semantic | episodic | state | derived
    * semantic = durable identity/preference/goal/constraint/equipment/dietary
    * episodic = a time-bound event/state that will fade
    * state = an OPEN LOOP needing follow-up (pain, "I'll try X") — set
      resolution_prompt to the short question the coach should ask later
      (e.g. "How's the back feeling this morning?")
- category: short tag (e.g. %s)
- content: the fact in concise third-person-neutral form
  (e.g. "Has lower back pain, started this week", "Prefers morning workouts")
- salience: 0..1 importance for surfacing later
- confidence: 0..1 how sure you are the user actually asserted this
- sensitive: true for medical/pain/mental-health facts
- is_injury: true if this is a physical injury/pain/limitation
- source_quote: the exact user words that justify this memory

Return JSON: {"operations": [ ... ]}. If nothing qualifies: {"operations": []}.
Be conservative — prefer fewer, higher-quality memories.""" % (", ".join(SUGGESTED_CATEGORIES))


def is_trivial_turn(user_message: Optional[str]) -> bool:
    """Cheap pre-filter: True when the turn can't plausibly carry a durable
    fact (skip the LLM call)."""
    if not user_message:
        return True
    s = user_message.strip()
    if len(s) < _MIN_MEANINGFUL_CHARS:
        return True
    if _TRIVIAL_RE.match(s):
        return True
    return False


def _user_cost_today_usd(user_id: str) -> float:
    try:
        snap = cost_tracker.snapshot()
        return float((snap.get("by_user", {}).get(user_id) or {}).get("cost_usd", 0.0))
    except Exception:
        return 0.0


def _robust_parse(text: str) -> Optional[Dict[str, Any]]:
    if not text:
        return None
    s = text.strip()
    if s.startswith("```"):
        s = re.sub(r"^```(?:json)?\s*", "", s)
        s = re.sub(r"\s*```$", "", s).strip()
    try:
        return json.loads(s)
    except json.JSONDecodeError:
        pass
    first = s.find("{")
    if first < 0:
        return None
    try:
        obj, _ = json.JSONDecoder().raw_decode(s[first:])
        return obj if isinstance(obj, dict) else None
    except json.JSONDecodeError:
        return None


def _format_existing(memories: List[Dict]) -> str:
    if not memories:
        return "(none yet)"
    out = []
    for m in memories[:40]:
        out.append(
            f"- id={m.get('id')} | type={m.get('memory_type')} | "
            f"status={m.get('status')} | {m.get('content')}"
        )
    return "\n".join(out)


async def extract_operations(
    *,
    user_id: str,
    user_message: str,
    ai_response: str,
    existing_memories: List[Dict],
) -> List[Dict[str, Any]]:
    """Run extraction. Returns a list of op dicts (possibly empty)."""
    if is_trivial_turn(user_message):
        return []
    if _user_cost_today_usd(user_id) >= MAX_MEMORY_USD_PER_USER_PER_DAY:
        logger.info(f"[memory.extractor] cost cap hit for {user_id} — skipping")
        return []

    settings = get_settings()
    user_msg = (
        f"CURRENT MEMORIES:\n{_format_existing(existing_memories)}\n\n"
        f"LATEST EXCHANGE:\nUser: {user_message.strip()[:1500]}\n"
        f"Coach: {(ai_response or '').strip()[:600]}\n\n"
        "Propose memory operations as JSON."
    )
    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=user_msg,
            config=types.GenerateContentConfig(
                system_instruction=_SYSTEM,
                response_mime_type="application/json",
                max_output_tokens=600,
                temperature=0.2,
            ),
            user_id=user_id,
            timeout=12.0,
            method_name="memory_extract",
        )
        text = getattr(response, "text", None)
        parsed = _robust_parse(text) if text else None
        if not parsed:
            return []
        ops = parsed.get("operations")
        return ops if isinstance(ops, list) else []
    except Exception as e:
        logger.warning(f"[memory.extractor] extraction failed: {e}")
        return []
