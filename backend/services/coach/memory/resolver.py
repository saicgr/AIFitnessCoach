"""
Applies extracted memory operations to the store.

The extractor proposes; the resolver decides and writes. Responsibilities:
  - ADD/UPDATE/RESOLVE/REINFORCE/CONTRADICT → concrete DB mutations
  - trust gating: low-confidence facts land as 'provisional' (not injected)
  - open-loop wiring: state memories get follow_up_after + resolution_prompt
  - injury DUAL-WRITE: an injury fact links to (or creates) a structured
    injury_history row so the workout engine still sees it, while the memory
    row carries the conversational follow-up. Resolving the loop also resolves
    the linked injury_history row.
  - best-effort embedding index for relevance retrieval

Pure side-effects; returns a small summary dict for logging/telemetry.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from services.coach.memory import embeddings
from services.coach.memory.schemas import (
    DEFAULT_FOLLOW_UP_HOURS,
    OP_ADD,
    OP_CONTRADICT,
    OP_REINFORCE,
    OP_RESOLVE,
    OP_UPDATE,
    PROVISIONAL_CONFIDENCE_THRESHOLD,
)

logger = logging.getLogger("coach_memory.resolver")

_INJURY_KEYWORDS = (
    "back", "knee", "shoulder", "wrist", "elbow", "ankle", "hip", "neck",
    "hamstring", "quad", "calf", "groin", "foot", "hand", "chest", "bicep",
    "tricep", "lower back", "rotator", "achilles", "shin",
)


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _guess_body_part(content: str) -> Optional[str]:
    low = (content or "").lower()
    # Longest match wins ("lower back" before "back").
    best = None
    for kw in sorted(_INJURY_KEYWORDS, key=len, reverse=True):
        if kw in low:
            best = kw
            break
    return best


def _find_matching_injury(active_injuries: List[Dict], content: str) -> Optional[Dict]:
    bp = _guess_body_part(content)
    if not bp:
        return None
    for inj in active_injuries:
        hay = f"{inj.get('body_part') or ''} {inj.get('injury_type') or ''} {inj.get('notes') or ''}".lower()
        if bp in hay:
            return inj
    return None


def _link_or_create_injury(db, user_id: str, content: str) -> Optional[str]:
    """Return an injury_history.id to link the memory to: an existing active
    injury matching the body part, or a newly created minimal row. The injury
    agent may already have created one (keyword routing) — we reuse it rather
    than duplicate."""
    try:
        active = db.get_active_injuries(user_id) or []
        match = _find_matching_injury(active, content)
        if match:
            return match.get("id")
        row = db.create_injury_history({
            "user_id": user_id,
            "injury_type": "pain",
            "body_part": _guess_body_part(content) or "unspecified",
            "severity": "mild",
            "is_active": True,
            "reported_at": _utcnow().isoformat(),
            "notes": content[:300],
        })
        return row.get("id") if row else None
    except Exception as e:
        logger.warning(f"[memory.resolver] injury dual-write failed: {e}")
        return None


def _resolve_linked_injury(db, injury_id: str) -> None:
    """Best-effort: mark a linked injury_history row resolved when its loop is
    closed. Direct table update (no facade helper for injury_history updates)."""
    try:
        db.client.table("injury_history").update(
            {"is_active": False, "resolved_at": _utcnow().isoformat()}
        ).eq("id", injury_id).execute()
    except Exception as e:
        logger.warning(f"[memory.resolver] resolve linked injury failed: {e}")


def _build_row(
    op: Dict[str, Any], user_id: str, source_message_id: Optional[str],
    source_session_id: Optional[str], linked_id: Optional[str] = None,
) -> Dict[str, Any]:
    confidence = float(op.get("confidence", 0.7) or 0.7)
    salience = float(op.get("salience", 0.5) or 0.5)
    mem_type = op.get("memory_type") or "semantic"
    provisional = confidence < PROVISIONAL_CONFIDENCE_THRESHOLD

    row: Dict[str, Any] = {
        "user_id": user_id,
        "memory_type": mem_type,
        "category": (op.get("category") or "other")[:60],
        "content": (op.get("content") or "").strip()[:600],
        "salience": max(0.0, min(1.0, salience)),
        "confidence": max(0.0, min(1.0, confidence)),
        "sensitive": bool(op.get("sensitive", False)),
        "source_message_id": source_message_id,
        "source_session_id": source_session_id,
        "source_quote": (op.get("source_quote") or "")[:400] or None,
    }
    if linked_id:
        row["linked_table"] = "injury_history"
        row["linked_id"] = linked_id

    # Status + open-loop wiring.
    if provisional:
        row["status"] = "provisional"
        # A low-confidence "state" can't be a trusted open loop yet.
        if mem_type == "state":
            row["memory_type"] = "episodic"
    elif mem_type == "state":
        row["status"] = "open"
        row["resolution_prompt"] = (op.get("resolution_prompt") or "").strip()[:200] or None
        row["follow_up_after"] = (_utcnow() + timedelta(hours=DEFAULT_FOLLOW_UP_HOURS)).isoformat()
    else:
        row["status"] = "active"
    return row


def apply_operations(
    *,
    user_id: str,
    operations: List[Dict[str, Any]],
    existing_by_id: Dict[str, Dict],
    source_message_id: Optional[str] = None,
    source_session_id: Optional[str] = None,
) -> Dict[str, int]:
    """Apply a list of extractor operations. Returns op counts for telemetry."""
    db = get_supabase_db()
    counts = {"added": 0, "updated": 0, "resolved": 0, "reinforced": 0,
              "superseded": 0, "skipped": 0}

    for op in operations or []:
        kind = (op.get("op") or "").upper()
        target_id = op.get("target_id")
        try:
            if kind == OP_REINFORCE and target_id in existing_by_id:
                db.memory.reinforce_memory(target_id, user_id)
                counts["reinforced"] += 1

            elif kind == OP_RESOLVE and target_id in existing_by_id:
                resolved = db.memory.resolve_memory(target_id, user_id)
                # Cascade to the linked injury row if any.
                tgt = existing_by_id.get(target_id) or {}
                if tgt.get("linked_table") == "injury_history" and tgt.get("linked_id"):
                    _resolve_linked_injury(db, tgt["linked_id"])
                counts["resolved"] += 1 if resolved else 0

            elif kind == OP_UPDATE and target_id in existing_by_id:
                patch = {
                    "content": (op.get("content") or existing_by_id[target_id].get("content") or "")[:600],
                    "salience": max(0.0, min(1.0, float(op.get("salience", existing_by_id[target_id].get("salience", 0.5)) or 0.5))),
                    "last_referenced_at": _utcnow().isoformat(),
                }
                if op.get("category"):
                    patch["category"] = op["category"][:60]
                updated = db.memory.update_memory(target_id, user_id, patch)
                if updated:
                    embeddings.index_memory(updated)
                counts["updated"] += 1 if updated else 0

            elif kind == OP_CONTRADICT:
                # Create the new fact, then supersede the old one (audit trail).
                linked_id = None
                if op.get("is_injury"):
                    linked_id = _link_or_create_injury(db, user_id, op.get("content") or "")
                row = _build_row(op, user_id, source_message_id, source_session_id, linked_id)
                created = db.memory.create_memory(row)
                if created:
                    embeddings.index_memory(created)
                    counts["added"] += 1
                    if target_id in existing_by_id:
                        db.memory.supersede_memory(target_id, user_id, created.get("id"))
                        counts["superseded"] += 1

            elif kind == OP_ADD:
                linked_id = None
                if op.get("is_injury"):
                    linked_id = _link_or_create_injury(db, user_id, op.get("content") or "")
                row = _build_row(op, user_id, source_message_id, source_session_id, linked_id)
                if not row["content"]:
                    counts["skipped"] += 1
                    continue
                created = db.memory.create_memory(row)
                if created:
                    embeddings.index_memory(created)
                    counts["added"] += 1
            else:
                counts["skipped"] += 1
        except Exception as e:
            logger.warning(f"[memory.resolver] op {kind} failed: {e}")
            counts["skipped"] += 1

    return counts
