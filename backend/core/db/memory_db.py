"""
Coach memory database operations (migration 2217 — coach_memory).

System of record for the AI coach's persistent, typed long-term memory.
ChromaDB (collection `coach_memory`) holds a denormalized embedding index for
relevance retrieval only; Postgres here is authoritative.

Memory types : semantic | episodic | state | derived
Statuses     : provisional | active | open | resolved | superseded | dismissed

All reads/writes run with the backend service-role key, so the service-role
RLS policy on coach_memory grants full access. User-scoped methods still pass
user_id explicitly as a defense-in-depth ownership filter.
"""
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from core.db.base import BaseDB
from core.logger import get_logger

logger = get_logger(__name__)

# Columns explicitly listed (never select("*")) so a future column add can't
# silently change the payload shape downstream — but we DO read every current
# column because the services need them.
_COLS = (
    "id, user_id, memory_type, category, content, status, salience, "
    "confidence, sensitive, source_session_id, source_message_id, "
    "source_quote, follow_up_after, resolution_prompt, follow_up_count, "
    "superseded_by, expires_at, last_referenced_at, created_at, updated_at, "
    "linked_table, linked_id"
)

# Statuses that are eligible for prompt injection (the coach should "know" them).
INJECTABLE_STATUSES = ("active", "open")

# An open loop auto-expires after being surfaced this many times unanswered,
# so the coach never nags. Enforced by the consolidator + briefing.
MAX_FOLLOW_UP_SURFACES = 3


def _utcnow_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class MemoryDB(BaseDB):
    """CRUD + lifecycle queries for coach_memory."""

    # ------------------------------------------------------------------ create
    def create_memory(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Insert a memory row. `data` should already be normalized by the
        resolver (memory_type, category, content, status, salience, etc.)."""
        result = self.client.table("coach_memory").insert(data).execute()
        return result.data[0] if result.data else None

    # -------------------------------------------------------------------- reads
    def get_memory(self, memory_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        result = (
            self.client.table("coach_memory")
            .select(_COLS)
            .eq("id", memory_id)
            .eq("user_id", user_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def list_memories(
        self,
        user_id: str,
        statuses: Optional[List[str]] = None,
        memory_types: Optional[List[str]] = None,
        limit: int = 200,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """General list, newest-meaningful-first (salience then recency)."""
        q = self.client.table("coach_memory").select(_COLS).eq("user_id", user_id)
        if statuses:
            q = q.in_("status", statuses)
        if memory_types:
            q = q.in_("memory_type", memory_types)
        q = q.order("salience", desc=True).order("updated_at", desc=True)
        q = q.range(offset, offset + limit - 1)
        return q.execute().data or []

    def list_injectable(self, user_id: str, limit: int = 60) -> List[Dict[str, Any]]:
        """Active + open memories — the candidate pool the retriever ranks
        before injecting into the coach prompt / briefing."""
        return self.list_memories(
            user_id, statuses=list(INJECTABLE_STATUSES), limit=limit
        )

    def list_open_loops_due(
        self, user_id: str, now_iso: Optional[str] = None, limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Open loops whose follow_up_after has passed (or is null) and that
        haven't exhausted their nag budget — what the briefing resurfaces."""
        now_iso = now_iso or _utcnow_iso()
        q = (
            self.client.table("coach_memory")
            .select(_COLS)
            .eq("user_id", user_id)
            .eq("status", "open")
            .lt("follow_up_count", MAX_FOLLOW_UP_SURFACES)
            .order("salience", desc=True)
            .limit(limit)
        )
        rows = q.execute().data or []
        # follow_up_after may be NULL (surface immediately) — filter in Python
        # so a NULL isn't excluded by a `lte` comparison.
        out = []
        for r in rows:
            fa = r.get("follow_up_after")
            if not fa or fa <= now_iso:
                out.append(r)
        return out

    def list_by_linked(
        self, user_id: str, linked_table: str, linked_id: str
    ) -> List[Dict[str, Any]]:
        """Memories mirroring a structured row (e.g. an injury_history row) —
        used by the injector to dedupe and by the resolver to update in place."""
        return (
            self.client.table("coach_memory")
            .select(_COLS)
            .eq("user_id", user_id)
            .eq("linked_table", linked_table)
            .eq("linked_id", linked_id)
            .execute()
        ).data or []

    def search_memories(
        self, user_id: str, query: str, limit: int = 30
    ) -> List[Dict[str, Any]]:
        return (
            self.client.table("coach_memory")
            .select(_COLS)
            .eq("user_id", user_id)
            .neq("status", "dismissed")
            .ilike("content", f"%{query}%")
            .order("salience", desc=True)
            .limit(limit)
            .execute()
        ).data or []

    def list_user_ids_with_active_memory(self, limit: int = 5000) -> List[str]:
        """Distinct user_ids that have injectable memory — drives the nightly
        consolidation cron without scanning every user in the system."""
        rows = (
            self.client.table("coach_memory")
            .select("user_id")
            .in_("status", list(INJECTABLE_STATUSES))
            .limit(limit)
            .execute()
        ).data or []
        seen, out = set(), []
        for r in rows:
            uid = r.get("user_id")
            if uid and uid not in seen:
                seen.add(uid)
                out.append(uid)
        return out

    # ------------------------------------------------------------------ updates
    def update_memory(
        self, memory_id: str, user_id: str, data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        result = (
            self.client.table("coach_memory")
            .update(data)
            .eq("id", memory_id)
            .eq("user_id", user_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def reinforce_memory(
        self, memory_id: str, user_id: str, salience_bump: float = 0.1
    ) -> Optional[Dict[str, Any]]:
        """User restated a known fact — bump salience (capped at 1.0) + recency.
        Confidence is promoted too so a provisional fact can graduate to active."""
        row = self.get_memory(memory_id, user_id)
        if not row:
            return None
        new_sal = min(1.0, float(row.get("salience") or 0.5) + salience_bump)
        new_conf = min(1.0, float(row.get("confidence") or 0.7) + 0.1)
        patch = {
            "salience": new_sal,
            "confidence": new_conf,
            "last_referenced_at": _utcnow_iso(),
        }
        # Promote a provisional fact that's now been reinforced.
        if row.get("status") == "provisional" and new_conf >= 0.6:
            patch["status"] = "active"
        return self.update_memory(memory_id, user_id, patch)

    def supersede_memory(
        self, old_id: str, user_id: str, new_id: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Mark an old fact superseded (a newer contradicting fact replaced it).
        Kept for audit, never injected."""
        patch = {"status": "superseded"}
        if new_id:
            patch["superseded_by"] = new_id
        return self.update_memory(old_id, user_id, patch)

    def resolve_memory(self, memory_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Close an open loop ("back feels better"). Kept for history."""
        return self.update_memory(
            memory_id, user_id, {"status": "resolved", "last_referenced_at": _utcnow_iso()}
        )

    def dismiss_memory(self, memory_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """User deleted the memory — tombstone (status=dismissed) instead of a
        hard delete so the extractor won't immediately re-add the same fact."""
        return self.update_memory(memory_id, user_id, {"status": "dismissed"})

    def bump_follow_up(self, memory_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Record that an open loop was surfaced in a briefing — increments the
        nag counter and pushes follow_up_after out by the resolver/briefing."""
        row = self.get_memory(memory_id, user_id)
        if not row:
            return None
        return self.update_memory(
            memory_id,
            user_id,
            {
                "follow_up_count": int(row.get("follow_up_count") or 0) + 1,
                "last_referenced_at": _utcnow_iso(),
            },
        )

    def touch_referenced(self, memory_ids: List[str]) -> None:
        """Mark memories as referenced in a coach reply (recency signal). Best
        effort — a failure here must never break the chat path."""
        if not memory_ids:
            return
        try:
            (
                self.client.table("coach_memory")
                .update({"last_referenced_at": _utcnow_iso()})
                .in_("id", memory_ids)
                .execute()
            )
        except Exception as e:  # pragma: no cover - telemetry only
            logger.warning(f"[memory] touch_referenced failed: {e}")

    # ------------------------------------------------------------------ deletes
    def hard_delete_memory(self, memory_id: str, user_id: str) -> bool:
        """True hard delete (used by the 'forget everything' purge path)."""
        result = (
            self.client.table("coach_memory")
            .delete()
            .eq("id", memory_id)
            .eq("user_id", user_id)
            .execute()
        )
        return bool(result.data)

    def delete_all_for_user(self, user_id: str) -> bool:
        self.client.table("coach_memory").delete().eq("user_id", user_id).execute()
        return True

    # ------------------------------------------------------------- settings
    def get_memory_enabled(self, user_id: str) -> bool:
        """Master memory toggle from users.coach_memory_enabled (default True)."""
        try:
            row = (
                self.client.table("users")
                .select("coach_memory_enabled")
                .eq("id", user_id)
                .execute()
            ).data
            if row and row[0].get("coach_memory_enabled") is not None:
                return bool(row[0]["coach_memory_enabled"])
        except Exception as e:
            logger.warning(f"[memory] get_memory_enabled failed: {e}")
        return True

    def set_memory_enabled(self, user_id: str, enabled: bool) -> bool:
        self.client.table("users").update(
            {"coach_memory_enabled": enabled}
        ).eq("id", user_id).execute()
        return True
