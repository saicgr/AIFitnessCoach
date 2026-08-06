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
        # Order newest-activity-first. nullslast guards against rows whose
        # last_message_at is NULL (e.g. a freshly created, never-messaged
        # session) so they sort to the end instead of breaking ordering.
        q = q.order("last_message_at", desc=True, nullsfirst=False).range(
            offset, offset + limit - 1
        )
        sessions = q.execute().data or []
        if not sessions:
            return []
        # Preview enrichment is best-effort: if it fails, return the sessions
        # WITHOUT previews rather than 500-ing the whole list (issue 11c).
        try:
            ids = [s["id"] for s in sessions]
            previews = self._latest_previews(user_id, ids)
            for s in sessions:
                s["preview"] = previews.get(s["id"], "")
        except Exception as e:
            logger.error(
                f"[SessionsDB] preview enrichment failed for user {user_id}; "
                f"returning sessions without previews: {e}",
                exc_info=True,
            )
            for s in sessions:
                s.setdefault("preview", "")
        return sessions

    def _latest_previews(self, user_id: str, session_ids: List[str]) -> Dict[str, str]:
        """Map session_id -> latest user_message snippet. One query over the
        relevant turns, newest first; first seen per session wins."""
        if not session_ids:
            return {}
        try:
            rows = (
                self.client.table("chat_history")
                .select("session_id, user_message, timestamp")
                .eq("user_id", user_id)
                .in_("session_id", session_ids)
                .order("timestamp", desc=True)
                .limit(max(50, len(session_ids) * 4))
                .execute()
            ).data or []
        except Exception as e:
            # Never let a preview query break the caller — return empty so the
            # caller falls back to no-preview sessions (issue 11c).
            logger.error(
                f"[SessionsDB] _latest_previews query failed for user {user_id}: {e}",
                exc_info=True,
            )
            return {}
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

    def resync_message_count(self, session_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Recompute message_count + last_message_at from the ACTUAL chat_history
        rows for this session — the source of truth — instead of trusting the
        denormalized counter `touch_session` maintains incrementally.

        WHY THIS EXISTS (UI_E2E 2026-08-05 row 53): `touch_session` only ever
        ADDS 1, so any chat_history DELETE (single-message delete, a whole-
        history clear) that doesn't ALSO call this leaves the session
        permanently overcounted. A session whose message_count says 1+ but
        whose last real row was just deleted then advertises a saved
        conversation in the sessions list that opens completely blank —
        verified live: session 64127e54's message_count read 2 against
        exactly 1 real chat_history row for it. Call this after every
        chat_history delete path (delete_chat_message here in the facade;
        resync_all_sessions_for_user after a whole-history wipe).
        """
        try:
            count_res = (
                self.client.table("chat_history")
                .select("id", count="exact")
                .eq("session_id", session_id)
                .eq("user_id", user_id)
                .execute()
            )
            real_count = count_res.count or 0

            last_res = (
                self.client.table("chat_history")
                .select("timestamp")
                .eq("session_id", session_id)
                .eq("user_id", user_id)
                .order("timestamp", desc=True)
                .limit(1)
                .execute()
            )
            last_message_at = last_res.data[0]["timestamp"] if last_res.data else None

            return self.update_session(
                session_id,
                user_id,
                {"message_count": real_count, "last_message_at": last_message_at},
            )
        except Exception as e:
            logger.warning(
                f"[SessionsDB] resync_message_count failed for session={session_id} "
                f"user={user_id}: {e}",
                exc_info=True,
            )
            return None

    def resync_all_sessions_for_user(self, user_id: str) -> None:
        """Bulk resync — call after a whole-history wipe (clear_chat_history /
        delete_chat_history_by_user) so every one of the user's sessions
        reflects reality (0, since none of its messages exist anymore)
        instead of staying stale at whatever count it held before the wipe.
        Best-effort per-session; one failure never blocks the rest.
        """
        try:
            rows = (
                self.client.table("chat_sessions")
                .select("id")
                .eq("user_id", user_id)
                .execute()
            ).data or []
        except Exception as e:
            logger.warning(f"[SessionsDB] resync_all_sessions_for_user list failed for {user_id}: {e}")
            return
        for row in rows:
            self.resync_message_count(row["id"], user_id)

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
        # `last_message_at` may be NULL; `or ""` keeps the sort total-order-safe.
        sessions = sorted(
            found.values(), key=lambda s: s.get("last_message_at") or "", reverse=True
        )[:limit]
        # Best-effort previews — failures degrade to no-preview, not a 500.
        try:
            previews = self._latest_previews(user_id, [s["id"] for s in sessions])
            for s in sessions:
                s["preview"] = previews.get(s["id"], "")
        except Exception as e:
            logger.error(
                f"[SessionsDB] search preview enrichment failed for user {user_id}: {e}",
                exc_info=True,
            )
            for s in sessions:
                s.setdefault("preview", "")
        return sessions

    def latest_session(self, user_id: str) -> Optional[Dict[str, Any]]:
        rows = self.list_sessions(user_id, limit=1)
        return rows[0] if rows else None
