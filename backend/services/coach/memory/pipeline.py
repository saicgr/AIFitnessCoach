"""
Coach memory pipeline — orchestration entry points.

  extract_and_store(...)   write path; runs as a BackgroundTask AFTER the chat
                           reply is sent, so it never adds latency to the reply.
  consolidate_user(...)    nightly reflection (cron): dedupe, decay/archive,
                           open-loop expiry, episodic->semantic promotion, and
                           a conservative derived-insight pass.

Every public function is defensive: a failure here must never surface to the
user or break the chat path.
"""
from __future__ import annotations

import logging
from collections import Counter
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from services.consent_guard import should_save_chat_history
from services.coach.memory import embeddings
from services.coach.memory.extractor import extract_operations, is_trivial_turn
from services.coach.memory.resolver import apply_operations

logger = logging.getLogger("coach_memory.pipeline")


# ---------------------------------------------------------------------------
# Write path
# ---------------------------------------------------------------------------
async def extract_and_store(
    *,
    user_id: str,
    user_message: str,
    ai_response: str,
    source_message_id: Optional[str] = None,
    source_session_id: Optional[str] = None,
) -> Dict[str, Any]:
    """Extract durable facts from one exchange and persist memory operations.
    Returns a summary dict (also logged). Safe to call as a BackgroundTask."""
    summary: Dict[str, Any] = {"ran": False}
    try:
        if is_trivial_turn(user_message):
            return summary

        db = get_supabase_db()

        # Gate: master memory toggle AND chat-history consent.
        if not db.memory.get_memory_enabled(user_id):
            return summary
        if not should_save_chat_history(user_id):
            return summary

        # The extractor needs to see what we already know to dedupe / resolve.
        existing = db.memory.list_injectable(user_id, limit=60)
        existing_by_id = {m.get("id"): m for m in existing if m.get("id")}

        ops = await extract_operations(
            user_id=user_id,
            user_message=user_message,
            ai_response=ai_response,
            existing_memories=existing,
        )
        if not ops:
            return {"ran": True, "operations": 0}

        counts = apply_operations(
            user_id=user_id,
            operations=ops,
            existing_by_id=existing_by_id,
            source_message_id=source_message_id,
            source_session_id=source_session_id,
        )
        summary = {"ran": True, "operations": len(ops), **counts}
        logger.info(f"[memory.pipeline] {user_id}: {summary}")
        return summary
    except Exception as e:  # never propagate into a BackgroundTask
        logger.warning(f"[memory.pipeline] extract_and_store failed for {user_id}: {e}")
        return summary


def mark_loops_surfaced(user_id: str, memory_ids: List[str]) -> None:
    """Called by the briefing after it surfaces open loops: increment the nag
    counter and push follow_up_after out so the same question isn't repeated
    every open. Auto-resolves a loop that has hit its surface budget."""
    db = get_supabase_db()
    for mid in memory_ids or []:
        try:
            row = db.memory.bump_follow_up(mid, user_id)
            if not row:
                continue
            count = int(row.get("follow_up_count") or 0)
            if count >= 3:
                # Exhausted its nag budget — stop surfacing (treat as resolved
                # silently so it leaves the open-loop pool without nagging).
                db.memory.update_memory(mid, user_id, {"status": "resolved"})
            else:
                db.memory.update_memory(
                    mid, user_id,
                    {"follow_up_after": (datetime.now(timezone.utc) + timedelta(hours=20)).isoformat()},
                )
        except Exception as e:
            logger.warning(f"[memory.pipeline] mark_loops_surfaced {mid} failed: {e}")


# ---------------------------------------------------------------------------
# Nightly reflection (cron)
# ---------------------------------------------------------------------------
_WEEKDAYS = ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")


def _parse_ts(val):
    if not val:
        return None
    try:
        s = str(val).replace("Z", "+00:00")
        dt = datetime.fromisoformat(s)
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except Exception:
        return None


def _decay_and_expire(db, user_id: str, mems: List[Dict]) -> int:
    """Archive episodic/derived memories that are old AND low salience, and
    expire open loops past their nag budget. Returns count archived."""
    now = datetime.now(timezone.utc)
    archived = 0
    for m in mems:
        try:
            status = m.get("status")
            mtype = m.get("memory_type")
            if status == "open" and int(m.get("follow_up_count") or 0) >= 3:
                db.memory.update_memory(m["id"], user_id, {"status": "resolved"})
                archived += 1
                continue
            if status in ("active",) and mtype in ("episodic", "derived"):
                ref = _parse_ts(m.get("last_referenced_at")) or _parse_ts(m.get("updated_at")) \
                    or _parse_ts(m.get("created_at"))
                age_days = (now - ref).total_seconds() / 86400.0 if ref else 999
                if age_days > 45 and float(m.get("salience") or 0) < 0.4:
                    db.memory.update_memory(m["id"], user_id, {"status": "superseded"})
                    archived += 1
        except Exception as e:
            logger.warning(f"[memory.pipeline] decay {m.get('id')} failed: {e}")
    return archived


def _promote_episodics(db, user_id: str, mems: List[Dict]) -> int:
    """If the same category shows up in >=3 active episodics, promote a durable
    semantic summary (the pattern has proven itself). Returns count promoted."""
    promoted = 0
    by_cat: Dict[str, List[Dict]] = {}
    for m in mems:
        if m.get("status") == "active" and m.get("memory_type") == "episodic":
            by_cat.setdefault(m.get("category") or "other", []).append(m)
    for cat, rows in by_cat.items():
        if cat in ("other", "observation") or len(rows) < 3:
            continue
        # Avoid double-promoting: skip if a semantic in this category exists.
        has_semantic = any(
            x.get("memory_type") == "semantic" and x.get("category") == cat
            and x.get("status") in ("active", "open")
            for x in mems
        )
        if has_semantic:
            continue
        try:
            created = db.memory.create_memory({
                "user_id": user_id,
                "memory_type": "semantic",
                "category": cat,
                "content": f"Recurring {cat}: {rows[0].get('content')}",
                "status": "active",
                "salience": min(1.0, max(0.5, float(rows[0].get("salience") or 0.5) + 0.2)),
                "confidence": 0.7,
            })
            if created:
                embeddings.index_memory(created)
                promoted += 1
        except Exception as e:
            logger.warning(f"[memory.pipeline] promote {cat} failed: {e}")
    return promoted


def _derived_weekday_skip(db, user_id: str, mems: List[Dict]) -> int:
    """Conservative derived insight: if the user has >=3 weeks of logged
    sessions and one weekday has far fewer than the rest, remember it
    ('Tends to skip workouts on Fridays'). Heavily guarded; silent on failure."""
    try:
        logs = db.list_workout_logs(user_id, limit=120) or []
        days = []
        for lg in logs:
            ts = _parse_ts(lg.get("completed_at"))
            if ts:
                days.append(ts.weekday())  # 0=Mon
        if len(days) < 9:  # need a meaningful sample
            return 0
        counts = Counter(days)
        span_weeks = max(1, (max(_parse_ts(l.get("completed_at")) for l in logs if _parse_ts(l.get("completed_at")))
                             - min(_parse_ts(l.get("completed_at")) for l in logs if _parse_ts(l.get("completed_at")))).days // 7)
        if span_weeks < 3:
            return 0
        avg = sum(counts.values()) / 7.0
        # Find a weekday with <25% of the average (a strong skip signal).
        skip_day = None
        for d in range(7):
            if counts.get(d, 0) <= max(0, avg * 0.25):
                skip_day = d
                break
        if skip_day is None:
            return 0
        content = f"Tends to skip workouts on {_WEEKDAYS[skip_day]}s"
        # Don't duplicate an existing derived row of this shape.
        if any(m.get("memory_type") == "derived" and "skip workouts" in (m.get("content") or "").lower()
               and m.get("status") in ("active", "open") for m in mems):
            return 0
        created = db.memory.create_memory({
            "user_id": user_id,
            "memory_type": "derived",
            "category": "observation",
            "content": content,
            "status": "active",
            "salience": 0.45,
            "confidence": 0.6,
        })
        if created:
            embeddings.index_memory(created)
            return 1
    except Exception as e:
        logger.warning(f"[memory.pipeline] derived weekday-skip failed for {user_id}: {e}")
    return 0


def consolidate_user(user_id: str) -> Dict[str, int]:
    """Run the full nightly reflection for one user. Deterministic (no LLM) so
    it's cheap to run nightly across the active-memory user set."""
    db = get_supabase_db()
    result = {"archived": 0, "promoted": 0, "derived": 0}
    try:
        mems = db.memory.list_memories(
            user_id,
            statuses=["active", "open", "provisional"],
            limit=300,
        )
        result["archived"] = _decay_and_expire(db, user_id, mems)
        result["promoted"] = _promote_episodics(db, user_id, mems)
        result["derived"] = _derived_weekday_skip(db, user_id, mems)
    except Exception as e:
        logger.warning(f"[memory.pipeline] consolidate_user {user_id} failed: {e}")
    return result


def consolidate_all_active(limit_users: int = 5000) -> Dict[str, Any]:
    """Cron entry: reflect over every user with active memory."""
    db = get_supabase_db()
    user_ids = db.memory.list_user_ids_with_active_memory(limit=limit_users)
    totals = {"users": 0, "archived": 0, "promoted": 0, "derived": 0}
    for uid in user_ids:
        r = consolidate_user(uid)
        totals["users"] += 1
        for k in ("archived", "promoted", "derived"):
            totals[k] += r.get(k, 0)
    logger.info(f"[memory.pipeline] nightly consolidation: {totals}")
    return totals
