"""Unit tests for the 2026-07 "caring coach" engagement build.

Covers the pure logic added around the push-nudge engine:
  * _mirror_proactive_to_chat — session attach (reuse recent / create stale),
    touch_session bump, session-less fallback on failure;
  * _effective_daily_cap — adaptive open-rate cap math;
  * open_loop_followup message building + due-loop picking;
  * conversational continuity contract: the mirror row carries session_id +
    context_json.proactive so the client's session-scoped history loader
    (and thus conversationHistory) includes the proactive turn.

No network: supabase + memory_db are stubbed in-memory.
"""
import os
import sys
import types
from datetime import datetime, timedelta, timezone

import pytest

sys.path.insert(0, ".")

# Import the modules under test WITHOUT executing api/v1/__init__.py (which
# pulls the entire app — langgraph, chroma, etc.). We pre-register stub
# package objects whose __path__ points at the real directories, so the
# normal import machinery finds the submodules but never runs the package
# initializers. Prod runs the real package; this shortcut is test-only.
_BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for _pkg, _rel in [
    ("api", "api"),
    ("api.v1", "api/v1"),
    ("api.v1.nudge_jobs", "api/v1/nudge_jobs"),
]:
    if _pkg not in sys.modules:
        _m = types.ModuleType(_pkg)
        _m.__path__ = [os.path.join(_BACKEND_ROOT, _rel)]
        sys.modules[_pkg] = _m

from api.v1 import push_nudge_cron as pnc  # noqa: E402
from api.v1.nudge_jobs import open_loop_followup as olf  # noqa: E402


# ---------------------------------------------------------------- stubs

class _StubResult:
    def __init__(self, data=None, count=None):
        self.data = data or []
        self.count = count


class _StubTable:
    """Minimal chainable PostgREST stub recording inserts/updates."""

    def __init__(self, store, name):
        self.store = store
        self.name = name

    def insert(self, row):
        self.store.setdefault(self.name, []).append(dict(row))
        row_out = dict(row)
        row_out.setdefault("id", f"{self.name}-{len(self.store[self.name])}")
        return _StubExec(_StubResult([row_out]))

    def update(self, patch):
        self.store.setdefault(f"{self.name}__updates", []).append(dict(patch))
        return _StubChain(_StubResult([dict(patch)]))

    def select(self, *_a, **_k):
        return _StubChain(_StubResult(self.store.get(self.name, [])))


class _StubChain:
    def __init__(self, result):
        self._result = result

    def __getattr__(self, _name):
        return lambda *a, **k: self

    def execute(self):
        return self._result


class _StubExec:
    def __init__(self, result):
        self._result = result

    def execute(self):
        return self._result


class _StubSupabase:
    def __init__(self, store):
        self.store = store
        self.client = types.SimpleNamespace(table=lambda name: _StubTable(store, name))


class _StubSessions:
    def __init__(self, latest=None):
        self._latest = latest
        self.created = []
        self.touched = []

    def latest_session(self, user_id):
        return self._latest

    def create_session(self, user_id, title=None):
        row = {"id": f"new-session-{len(self.created) + 1}", "title": title}
        self.created.append(row)
        return row

    def touch_session(self, session_id, user_id):
        self.touched.append(session_id)
        return {"id": session_id}


@pytest.fixture
def stub_db(monkeypatch):
    """Patch core.db.get_supabase_db().sessions with a controllable stub."""
    holder = {"sessions": _StubSessions()}

    class _Facade:
        @property
        def sessions(self):
            return holder["sessions"]

    import core.db as core_db
    monkeypatch.setattr(core_db, "get_supabase_db", lambda: _Facade())
    return holder


# ------------------------------------------------- mirror session attach

def _iso(dt):
    return dt.isoformat()


def test_mirror_reuses_recent_session(stub_db):
    stub_db["sessions"] = _StubSessions(
        latest={"id": "recent-1", "last_message_at": _iso(datetime.now(timezone.utc) - timedelta(days=1))}
    )
    store = {}
    supabase = _StubSupabase(store)
    msg_id = pnc._mirror_proactive_to_chat(
        supabase, "user-1", "morning_workout", "hello", {"proactive": True}
    )
    assert msg_id is not None
    row = store["chat_history"][0]
    assert row["session_id"] == "recent-1"
    assert row["context_json"]["proactive"] is True
    assert row["user_message"] == ""  # coach-initiated turn
    assert stub_db["sessions"].touched == ["recent-1"]  # bumps to top of list


def test_mirror_creates_session_when_stale(stub_db):
    stub_db["sessions"] = _StubSessions(
        latest={"id": "old-1", "last_message_at": _iso(datetime.now(timezone.utc) - timedelta(days=30))}
    )
    store = {}
    supabase = _StubSupabase(store)
    pnc._mirror_proactive_to_chat(
        supabase, "user-1", "open_loop_followup", "how's the knee?", {"proactive": True}
    )
    sessions = stub_db["sessions"]
    assert len(sessions.created) == 1
    assert sessions.created[0]["title"] == "Checking in"  # nudge-type title
    assert store["chat_history"][0]["session_id"] == "new-session-1"


def test_mirror_creates_session_when_none_exists(stub_db):
    stub_db["sessions"] = _StubSessions(latest=None)
    store = {}
    supabase = _StubSupabase(store)
    pnc._mirror_proactive_to_chat(
        supabase, "user-1", "evening_recap", "today in review", {"proactive": True}
    )
    assert store["chat_history"][0]["session_id"] == "new-session-1"


def test_mirror_survives_session_failure(stub_db, monkeypatch):
    """A sessions outage must degrade to a session-less insert, never drop."""
    import core.db as core_db

    def _boom():
        raise RuntimeError("sessions down")

    monkeypatch.setattr(core_db, "get_supabase_db", _boom)
    store = {}
    supabase = _StubSupabase(store)
    msg_id = pnc._mirror_proactive_to_chat(
        supabase, "user-1", "morning_workout", "hello", {"proactive": True}
    )
    assert msg_id is not None
    assert "session_id" not in store["chat_history"][0]


# --------------------------------------------------- adaptive daily cap

def test_effective_daily_cap_defaults():
    assert pnc._effective_daily_cap({"notification_preferences": {}}) == 3


def test_effective_daily_cap_backoff_floor():
    user = {"notification_preferences": {"daily_nudge_limit": 1}, "_daily_cap_adjust": -1}
    assert pnc._effective_daily_cap(user) == 1  # floor 1


def test_effective_daily_cap_bonus_ceiling():
    user = {"notification_preferences": {"daily_nudge_limit": 3}, "_daily_cap_adjust": 1}
    assert pnc._effective_daily_cap(user) == 4  # ceiling base+1


def test_adaptive_adjustments_thresholds(monkeypatch):
    rows = (
        [{"user_id": "low", "opened_at": None}] * 20  # 0% open
        + [{"user_id": "high", "opened_at": "x"}] * 12  # 100% open
        + [{"user_id": "few", "opened_at": None}] * 5  # under min sends
    )
    store = {"push_nudge_log": rows}
    supabase = _StubSupabase(store)
    adj = pnc._fetch_adaptive_cap_adjustments(supabase, ["low", "high", "few"])
    assert adj == {"low": -1, "high": 1}


# --------------------------------------------------- open-loop follow-up

def test_loop_message_prefers_resolution_prompt():
    loop = {"resolution_prompt": "How's the knee feeling?", "content": "sore knee"}
    assert olf._loop_message(loop, "Amy") == "How's the knee feeling?"


def test_loop_message_fallback_uses_content_and_name():
    loop = {"resolution_prompt": "", "content": "training for a 10k in August"}
    msg = olf._loop_message(loop, "Amy Smith")
    assert "training for a 10k in August" in msg
    assert msg.startswith("Amy — ")


def test_loop_message_empty_content_gives_empty():
    assert olf._loop_message({"resolution_prompt": "", "content": ""}, None) == ""


def test_pick_due_loop_skips_recently_referenced():
    class _Mem:
        def list_open_loops_due(self, user_id, limit=3):
            return [
                {"id": "a", "last_referenced_at": _iso(datetime.now(timezone.utc) - timedelta(hours=2))},
                {"id": "b", "last_referenced_at": _iso(datetime.now(timezone.utc) - timedelta(days=3))},
            ]

    picked = olf._pick_due_loop(_Mem(), "user-1")
    assert picked["id"] == "b"  # 'a' was surfaced 2h ago → skipped


def test_pick_due_loop_none_when_all_recent():
    class _Mem:
        def list_open_loops_due(self, user_id, limit=3):
            return [{"id": "a", "last_referenced_at": _iso(datetime.now(timezone.utc))}]

    assert olf._pick_due_loop(_Mem(), "user-1") is None
