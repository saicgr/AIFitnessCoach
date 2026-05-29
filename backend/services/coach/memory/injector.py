"""
Formats recalled memory into the coach prompt block "WHAT I KNOW ABOUT YOU".

Merges two sources into one coherent picture:
  1. coach_memory recall (ranked by the retriever)
  2. structured active injuries (injury_history) — the authoritative injury
     store, which the coach prompt did NOT previously surface at all.

Dedupe rule: a coach_memory row linked to an injury_history row (linked_table=
'injury_history') represents the SAME fact as that injury, so the injury line
is suppressed when its linked memory is already shown — the user sees one fact,
never a doubled "back pain / lower back injury".
"""
from __future__ import annotations

import logging
from typing import Dict, List, Optional, Tuple

from core.db import get_supabase_db
from services.coach.memory.retriever import retrieve_for_chat
from services.coach.memory.schemas import MEMORY_BLOCK_CHAR_BUDGET

logger = logging.getLogger("coach_memory.injector")


def _injury_line(inj: Dict) -> str:
    bp = inj.get("body_part") or inj.get("injury_type") or "injury"
    sev = inj.get("severity")
    note = (inj.get("notes") or "").strip()
    parts = [str(bp)]
    if sev:
        parts.append(f"({sev})")
    line = " ".join(parts)
    if note:
        line += f" — {note[:80]}"
    return line


def build_memory_block(
    user_id: str, current_message: Optional[str] = None, limit: int = 8
) -> Tuple[str, List[str]]:
    """Return (prompt_block, referenced_memory_ids).

    prompt_block is '' when the user has no memory AND no injuries, so the
    caller can omit the section entirely. referenced_memory_ids lets the caller
    bump last_referenced_at after a successful reply (recency signal).
    """
    db = get_supabase_db()

    # Memory must be enabled (master toggle); injuries always surface (safety).
    memory_enabled = True
    try:
        memory_enabled = db.memory.get_memory_enabled(user_id)
    except Exception:
        pass

    mems: List[Dict] = []
    if memory_enabled:
        try:
            mems = retrieve_for_chat(user_id, current_message, limit=limit)
        except Exception as e:
            logger.warning(f"[memory.injector] retrieve failed: {e}")
            mems = []

    try:
        injuries = db.get_active_injuries(user_id) or []
    except Exception:
        injuries = []

    # Which injury rows are already represented by a shown memory?
    linked_injury_ids = {
        m.get("linked_id")
        for m in mems
        if m.get("linked_table") == "injury_history" and m.get("linked_id")
    }

    lines: List[str] = []
    referenced_ids: List[str] = []
    budget = MEMORY_BLOCK_CHAR_BUDGET

    # Open loops first — the coach should proactively close them.
    open_loops = [m for m in mems if m.get("status") == "open"]
    facts = [m for m in mems if m.get("status") != "open"]

    for m in open_loops:
        rp = (m.get("resolution_prompt") or "").strip()
        line = f"- [follow up] {m.get('content')}" + (f" (ask: {rp})" if rp else "")
        if len(line) <= budget:
            lines.append(line)
            referenced_ids.append(m.get("id"))
            budget -= len(line)

    for m in facts:
        tag = m.get("category") or m.get("memory_type") or "note"
        line = f"- [{tag}] {m.get('content')}"
        if len(line) > budget:
            continue
        lines.append(line)
        referenced_ids.append(m.get("id"))
        budget -= len(line)

    for inj in injuries:
        if inj.get("id") in linked_injury_ids:
            continue  # already shown via its linked memory
        line = f"- [injury] {_injury_line(inj)}"
        if len(line) > budget:
            continue
        lines.append(line)
        budget -= len(line)

    if not lines:
        return "", []

    # Recency signal: a memory that keeps getting injected is relevant, so bump
    # its last_referenced_at (best-effort; never blocks the chat path). This is
    # what keeps reinforced/recalled facts from decaying purely on age.
    if referenced_ids:
        try:
            db.memory.touch_referenced(referenced_ids)
        except Exception:
            pass

    block = (
        "WHAT I KNOW ABOUT YOU (durable memory — treat as recall, not as "
        "freshly stated; if the user corrects any item, accept the correction "
        "and move on; never invent details beyond these):\n"
        + "\n".join(lines)
    )
    return block, referenced_ids


def build_memory_block_for_briefing(user_id: str) -> Dict:
    """Compact memory payload for the daily briefing generator: due open loops
    (for the check-in question) and top durable facts (to tailor the plan)."""
    from services.coach.memory.retriever import retrieve_for_briefing

    db = get_supabase_db()
    try:
        if not db.memory.get_memory_enabled(user_id):
            recall = {"open_loops": [], "facts": []}
        else:
            recall = retrieve_for_briefing(user_id, limit=6)
    except Exception as e:
        logger.warning(f"[memory.injector] briefing recall failed: {e}")
        recall = {"open_loops": [], "facts": []}

    open_loops = [
        {
            "id": m.get("id"),
            "content": m.get("content"),
            "resolution_prompt": m.get("resolution_prompt"),
            "category": m.get("category"),
        }
        for m in recall.get("open_loops", [])
    ]
    facts = [
        {"content": m.get("content"), "category": m.get("category")}
        for m in recall.get("facts", [])
    ]
    return {"open_loops": open_loops, "facts": facts}
