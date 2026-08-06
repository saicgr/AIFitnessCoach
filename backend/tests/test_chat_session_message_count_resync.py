"""Regression gate for UI_E2E 2026-08-05 row 53 (HIGH).

The only saved conversation in the QA account opened to a completely blank
thread: `chat_sessions.message_count` said 1 while `chat_history` held 0
rows for that session — a live-verified drift (independently reproduced
during this fix: session 64127e54 showed message_count=2 against exactly 1
real chat_history row).

Root cause: `touch_session` only ever ADDS 1 to the denormalized counter, and
NOTHING resynced it when a chat_history row was actually removed —
`DELETE /messages/{id}` (single-message delete) and `DELETE /history/{user_id}`
(clear-all) both deleted from `chat_history` directly and never touched
`chat_sessions`, so a session's message_count only ever ratchets up, never
down, no matter how many of its real messages get deleted.

Fixed at the DB facade chokepoint (core/db/facade.py + core/db/sessions_db.py)
so EVERY chat_history delete path resyncs the owning session(s) to the real
row count — not a hand-rolled decrement (which could itself drift), a full
recount against chat_history (the source of truth).
"""
from unittest.mock import MagicMock

import pytest

from core.db.sessions_db import SessionsDB
from core.db.facade import SupabaseDB


class _Resp:
    def __init__(self, data=None, count=None):
        self.data = data or []
        self.count = count


class _FakeChatHistoryQuery:
    """Stands in for chat_history's select().eq().eq()[.order().limit()].execute()."""

    def __init__(self, rows):
        self._rows = rows

    def select(self, *a, **k):
        return self

    def eq(self, *a, **k):
        return self

    def order(self, *a, **k):
        return self

    def limit(self, *a, **k):
        return self

    def execute(self):
        # count="exact" queries return count; row queries return data.
        return _Resp(data=self._rows, count=len(self._rows))


class _FakeSessionUpdateQuery:
    def __init__(self, sink):
        self._sink = sink

    def update(self, data):
        self._sink["update_payload"] = data
        return self

    def eq(self, *a, **k):
        return self

    def execute(self):
        return _Resp(data=[{**self._sink.get("update_payload", {}), "id": "sess-1"}])


class _FakeClient:
    def __init__(self, chat_history_rows, update_sink):
        self._rows = chat_history_rows
        self._sink = update_sink

    def table(self, name):
        if name == "chat_history":
            return _FakeChatHistoryQuery(self._rows)
        if name == "chat_sessions":
            return _FakeSessionUpdateQuery(self._sink)
        raise AssertionError(f"unexpected table {name}")


def _make_sessions_db(chat_history_rows):
    sdb = SessionsDB.__new__(SessionsDB)
    sink = {}
    sdb._supabase_manager = MagicMock(client=_FakeClient(chat_history_rows, sink))
    return sdb, sink


def test_resync_message_count_recomputes_from_real_rows_not_incrementally():
    """The exact live-verified defect: message_count=2, only 1 real row."""
    sdb, sink = _make_sessions_db(
        chat_history_rows=[{"timestamp": "2026-08-06T00:29:31.712006+00:00"}]
    )
    sdb.resync_message_count("sess-1", "user-1")
    assert sink["update_payload"]["message_count"] == 1
    assert sink["update_payload"]["last_message_at"] == "2026-08-06T00:29:31.712006+00:00"


def test_resync_message_count_zeroes_out_a_fully_deleted_session():
    """Row 53's exact symptom: every message deleted -> count must go to 0,
    not stay stranded at whatever it was before the delete."""
    sdb, sink = _make_sessions_db(chat_history_rows=[])
    sdb.resync_message_count("sess-1", "user-1")
    assert sink["update_payload"]["message_count"] == 0
    assert sink["update_payload"]["last_message_at"] is None


def test_delete_chat_message_facade_resyncs_the_owning_session():
    """Facade chokepoint: deleting a message must trigger a resync, not just
    the raw delete."""
    db = SupabaseDB.__new__(SupabaseDB)
    db._user_db = MagicMock()
    db._user_db.delete_chat_message.return_value = True
    db._sessions_db = MagicMock()

    lookup_resp = _Resp(data=[{"session_id": "sess-1"}])
    db._manager = MagicMock()
    db._manager.client.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = lookup_resp

    result = db.delete_chat_message("msg-1", "user-1")

    assert result is True
    db._sessions_db.resync_message_count.assert_called_once_with("sess-1", "user-1")


def test_delete_chat_message_facade_skips_resync_when_delete_failed():
    db = SupabaseDB.__new__(SupabaseDB)
    db._user_db = MagicMock()
    db._user_db.delete_chat_message.return_value = False
    db._sessions_db = MagicMock()

    lookup_resp = _Resp(data=[{"session_id": "sess-1"}])
    db._manager = MagicMock()
    db._manager.client.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value.execute.return_value = lookup_resp

    result = db.delete_chat_message("msg-1", "user-1")

    assert result is False
    db._sessions_db.resync_message_count.assert_not_called()


def test_clear_chat_history_facade_resyncs_every_session_for_the_user():
    db = SupabaseDB.__new__(SupabaseDB)
    db._user_db = MagicMock()
    db._sessions_db = MagicMock()

    db.clear_chat_history("user-1")

    db._user_db.clear_chat_history.assert_called_once_with("user-1")
    db._sessions_db.resync_all_sessions_for_user.assert_called_once_with("user-1")


def test_delete_chat_history_by_user_facade_resyncs_every_session():
    db = SupabaseDB.__new__(SupabaseDB)
    db._user_db = MagicMock()
    db._user_db.delete_chat_history_by_user.return_value = True
    db._sessions_db = MagicMock()

    result = db.delete_chat_history_by_user("user-1")

    assert result is True
    db._sessions_db.resync_all_sessions_for_user.assert_called_once_with("user-1")


# ---------------------------------------------------------------------------
# Live behavioral check against the QA account.
# ---------------------------------------------------------------------------

def _has_live_db_creds() -> bool:
    import os
    return bool(os.environ.get("SUPABASE_URL") and (
        os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_KEY")
    ))


@pytest.mark.skipif(not _has_live_db_creds(), reason="No SUPABASE_URL/KEY in env")
def test_live_resync_matches_real_chat_history_count_for_every_qa_session():
    from core.db.facade import get_supabase_db

    uid = "1aa02a24-0224-4a5a-b1e5-3f24dcd60bdc"
    db = get_supabase_db()
    db.sessions.resync_all_sessions_for_user(uid)

    sessions = db.client.table("chat_sessions").select("id, message_count").eq("user_id", uid).execute().data or []
    assert sessions, "QA account must have at least one chat session"
    for s in sessions:
        real = (
            db.client.table("chat_history")
            .select("id", count="exact")
            .eq("session_id", s["id"])
            .eq("user_id", uid)
            .execute()
        ).count or 0
        assert s["message_count"] == real, f"session {s['id']}: message_count={s['message_count']} real={real}"
