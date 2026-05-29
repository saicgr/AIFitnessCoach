"""
Chat session database operations (migration 2218 — chat_sessions).

Sessions are the Ask-Coach equivalent of ChatGPT/Gemini conversations: a named,
searchable container for a run of chat_history turns. Backend uses the
service-role key (service-role RLS policy grants full access); user-scoped
methods still pass user_id as a defense-in-depth ownership filter.
"""
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from core.db.base import BaseDB
from core.logger import get_logger

logger = get_logger(__name__)

_COLS = (
    "id, user_id, title, is_archived, message_count, "
    "created_at, updated_at, last_message_at"
)


def _utcnow_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class SessionsDB(BaseDB):
    """CRUD + listing for chat_sessions."""

    def create_session(
        self, user_id: str, title: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        now = _utcnow_iso()
        row = {
            "user_id": user_id,
            "title": title,
            "message_count": 0,
            "created_at": now,
            "updated_at": now,
            "last_message_at": now,
        }
        result = self.client.table("chat_sessions").insert(row).execute()
        return result.data[0] if result.data else None

    def get_session(self, session_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        result = (
            self.client.table("chat_sessions")
            .select(_COLS)
            .eq("id", session_id)
            .eq("user_id", user_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def list_sessions(
        self,
        user_id: str,
        include_archived: bool = False,
        limit: int = 100,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """Sessions newest-activity-first, each enriched with a short preview of
        its most recent turn (2 queries total — no N+1)."""
        q = self.client.table("chat_sessions").select(_COLS).eq("user_id", user_id)
        if not include_archived:
            q = q.eq("is_archived", False)
        q = q.order("last_message_at", desc=True).range(offset, offset + limit - 1)
        sessions = q.execute().data or []
        if not sessions:
            return []
        ids = [s["id"] for s in sessions]
        previews = self._latest_previews(user_id, ids)
        for s in sessions:
            s["preview"] = previews.get(s["id"], "")
        return sessions

    def _latest_previews(self, user_id: str, session_ids: List[str]) -> Dict[str, str]:
        """Map session_id -> latest user_message snippet. One query over the
        relevant turns, newest first; first seen per session wins."""
        if not session_ids:
            return {}
        rows = (
            self.client.table("chat_history")
            .select("session_id, user_message, timestamp")
            .eq("user_id", user_id)
            .in_("session_id", session_ids)
            .order("timestamp", desc=True)
            .limit(max(50, len(session_ids) * 4))
            .execute()
        ).data or []
        out: Dict[str, str] = {}
        for r in rows:
            sid = r.get("session_id")
            if sid and sid not in out:
                msg = (r.get("user_message") or "").strip().replace("\n", " ")
                out[sid] = msg[:120]
        return out

    def update_session(
        self, session_id: str, user_id: str, data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        result = (
            self.client.table("chat_sessions")
            .update(data)
            .eq("id", session_id)
            .eq("user_id", user_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def rename_session(self, session_id: str, user_id: str, title: str):
        return self.update_session(session_id, user_id, {"title": title.strip()[:120]})

    def set_title_if_unset(self, session_id: str, user_id: str, title: str) -> bool:
        """Set a generated title only if the session has none yet (avoids the
        title job clobbering a user rename that raced in)."""
        row = self.get_session(session_id, user_id)
        if not row or row.get("title"):
            return False
        self.update_session(session_id, user_id, {"title": title.strip()[:120]})
        return True

    def touch_session(self, session_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Bump last_message_at + message_count after a turn is saved."""
        row = self.get_session(session_id, user_id)
        if not row:
            return None
        return self.update_session(
            session_id,
            user_id,
            {
                "last_message_at": _utcnow_iso(),
                "message_count": int(row.get("message_count") or 0) + 1,
            },
        )

    def delete_session(self, session_id: str, user_id: str) -> bool:
        """Delete a session; chat_history rows cascade via the FK."""
        result = (
            self.client.table("chat_sessions")
            .delete()
            .eq("id", session_id)
            .eq("user_id", user_id)
            .execute()
        )
        return bool(result.data)

    def search_sessions(
        self, user_id: str, query: str, limit: int = 40
    ) -> List[Dict[str, Any]]:
        """Sessions whose TITLE matches, unioned with sessions that contain a
        matching MESSAGE. Returns session rows (with previews) newest first."""
        like = f"%{query}%"
        by_title = (
            self.client.table("chat_sessions")
            .select(_COLS)
            .eq("user_id", user_id)
            .ilike("title", like)
            .limit(limit)
            .execute()
        ).data or []
        msg_rows = (
            self.client.table("chat_history")
            .select("session_id")
            .eq("user_id", user_id)
            .or_(f"user_message.ilike.{like},ai_response.ilike.{like}")
            .limit(200)
            .execute()
        ).data or []
        msg_session_ids = {r["session_id"] for r in msg_rows if r.get("session_id")}
        found: Dict[str, Dict[str, Any]] = {s["id"]: s for s in by_title}
        missing = [sid for sid in msg_session_ids if sid not in found]
        if missing:
            extra = (
                self.client.table("chat_sessions")
                .select(_COLS)
                .eq("user_id", user_id)
                .in_("id", missing[:limit])
                .execute()
            ).data or []
            for s in extra:
                found[s["id"]] = s
        sessions = sorted(
            found.values(), key=lambda s: s.get("last_message_at") or "", reverse=True
        )[:limit]
        previews = self._latest_previews(user_id, [s["id"] for s in sessions])
        for s in sessions:
            s["preview"] = previews.get(s["id"], "")
        return sessions

    def latest_session(self, user_id: str) -> Optional[Dict[str, Any]]:
        rows = self.list_sessions(user_id, limit=1)
        return rows[0] if rows else None
