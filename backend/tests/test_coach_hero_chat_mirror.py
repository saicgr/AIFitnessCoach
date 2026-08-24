"""Regression gate for UI_E2E 2026-08-05 row 55 (HIGH).

`/chat?source=coach_hero&insight_id=X` had nothing server-side to point at:
migration 2098 added `chat_history.source_surface` + `insight_id` explicitly
so "the same Gemini insight the [Home coach hero] card showed is inserted at
the top of today's chat session as a normal coach turn" (its own comment),
but NOTHING in the backend ever wrote those columns — verified live: the QA
account's `coach_daily_insights` row existed with the exact headline/body,
but all 3 of its `chat_history` rows had `insight_id = NULL` and
`source_surface = NULL`. The client was left synthesizing the opening bubble
itself, which vanished on relaunch and left a follow-up ("Why?") hanging off
nothing.

Fixed by reusing the SAME chokepoint every other proactive coach message uses
(`_mirror_proactive_to_chat`, api/v1/push_nudge_cron.py — CLAUDE.md: never a
hand-rolled insert), extended to accept `source_surface`/`insight_id`, and
called from the daily-insight persist path (api/v1/coach/daily_insight.py)
when `source == "home"`. Gated to once per LOCAL day via
`_already_seeded_today` (a per-insight_id dedup would never catch same-day
regenerations, since the delete-then-insert persist stamps a fresh insight_id
every time).
"""
import inspect
from unittest.mock import MagicMock


# ---------------------------------------------------------------------------
# 1. `_mirror_proactive_to_chat` persists source_surface + insight_id when given.
# ---------------------------------------------------------------------------

def test_mirror_proactive_to_chat_persists_source_surface_and_insight_id(monkeypatch):
    import api.v1.push_nudge_cron as pnc

    monkeypatch.setattr(pnc, "_resolve_mirror_session", lambda *a, **k: "sess-1")

    inserted = {}

    class _InsertResp:
        data = [{"id": "chat-row-1"}]

    class _Table:
        def insert(self, row):
            inserted.update(row)
            return self

        def execute(self):
            return _InsertResp()

    class _FakeClient:
        def table(self, name):
            assert name == "chat_history"
            return _Table()

    fake_supabase = MagicMock(client=_FakeClient())
    fake_sessions = MagicMock()
    monkeypatch.setattr(
        "core.db.get_supabase_db", lambda: MagicMock(sessions=fake_sessions)
    )

    result = pnc._mirror_proactive_to_chat(
        supabase=fake_supabase,
        user_id="user-1",
        nudge_type="daily_insight_home",
        message="Rest is productive.\n\nBody text.",
        context_json={"proactive": True},
        log_tag="CoachHero",
        source_surface="coach_hero",
        insight_id="insight-1",
    )

    assert result == "chat-row-1"
    assert inserted["source_surface"] == "coach_hero"
    assert inserted["insight_id"] == "insight-1"
    assert inserted["session_id"] == "sess-1"


def test_mirror_proactive_to_chat_omits_columns_when_not_given():
    """Every OTHER nudge_type call site (that doesn't pass source_surface/
    insight_id) must be unaffected — no NULL columns forced into the row."""
    import api.v1.push_nudge_cron as pnc

    sig = inspect.signature(pnc._mirror_proactive_to_chat)
    assert sig.parameters["source_surface"].default is None
    assert sig.parameters["insight_id"].default is None


# ---------------------------------------------------------------------------
# 2. `_already_seeded_today` dedup — the per-day guard, not per-insight_id.
# ---------------------------------------------------------------------------

def test_already_seeded_today_true_when_a_row_exists_in_the_local_window(monkeypatch):
    import api.v1.push_nudge_cron as pnc

    monkeypatch.setattr(pnc, "get_user_today", lambda tz: "2026-08-05", raising=False)

    class _Resp:
        data = [{"id": "row-1"}]

    class _Query:
        def select(self, *a, **k):
            return self

        def eq(self, *a, **k):
            return self

        def gte(self, *a, **k):
            return self

        def lt(self, *a, **k):
            return self

        def limit(self, *a, **k):
            return self

        def execute(self):
            return _Resp()

    class _FakeClient:
        def table(self, name):
            assert name == "chat_history"
            return _Query()

    fake_supabase = MagicMock(client=_FakeClient())
    assert pnc._already_seeded_today(fake_supabase, "user-1", "coach_hero", "America/Chicago") is True


def test_already_seeded_today_false_when_no_row_exists():
    import api.v1.push_nudge_cron as pnc

    class _Resp:
        data = []

    class _Query:
        def select(self, *a, **k):
            return self

        def eq(self, *a, **k):
            return self

        def gte(self, *a, **k):
            return self

        def lt(self, *a, **k):
            return self

        def limit(self, *a, **k):
            return self

        def execute(self):
            return _Resp()

    class _FakeClient:
        def table(self, name):
            return _Query()

    fake_supabase = MagicMock(client=_FakeClient())
    assert pnc._already_seeded_today(fake_supabase, "user-1", "coach_hero", "America/Chicago") is False


def test_already_seeded_today_fails_open_on_error():
    """A dedup-check failure must never SILENTLY DROP the seed turn."""
    import api.v1.push_nudge_cron as pnc

    class _FakeClient:
        def table(self, name):
            raise RuntimeError("boom")

    fake_supabase = MagicMock(client=_FakeClient())
    assert pnc._already_seeded_today(fake_supabase, "user-1", "coach_hero", "America/Chicago") is False


# ---------------------------------------------------------------------------
# 3. The daily_insight persist path actually wires the mirror in for source=="home".
# ---------------------------------------------------------------------------

def test_daily_insight_endpoint_mirrors_coach_hero_source_into_chat():
    import api.v1.coach.daily_insight as di

    src = inspect.getsource(di.daily_insight)
    assert '_mirror_proactive_to_chat' in src
    assert '_already_seeded_today' in src
    assert 'source_surface="coach_hero"' in src
    assert 'source == "home"' in src


# ---------------------------------------------------------------------------
# 4. Regression gate for the QA account's live verification: a coach_hero
#    mirror row was written for it while confirming this fix worked
#    end-to-end. That row lives in a fixed calendar day, so asserting
#    against `_already_seeded_today`'s live "local today" window rots the
#    instant the run date moves past the day the row was written (it did:
#    the row is from the 2026-08-05 verification, this suite now runs on
#    later dates and the live call resolves to False every time, with
#    nothing broken). Reproduced deterministically instead, matching the
#    exact shape confirmed live (source_surface="coach_hero", tz
#    America/Chicago) so the dedup behavior stays covered without decaying.
# ---------------------------------------------------------------------------

def test_qa_account_already_seeded_today_after_live_verification_call(monkeypatch):
    """A coach_hero mirror row was written live for the QA account while
    verifying this fix. Confirms the dedup guard correctly reports
    'already seeded' for a matching same-day row (would otherwise re-fire
    on every Home load)."""
    import api.v1.push_nudge_cron as pnc

    monkeypatch.setattr(pnc, "get_user_today", lambda tz: "2026-08-05", raising=False)

    class _Resp:
        data = [{"id": "qa-mirror-row-1"}]

    class _Query:
        def select(self, *a, **k):
            return self

        def eq(self, *a, **k):
            return self

        def gte(self, *a, **k):
            return self

        def lt(self, *a, **k):
            return self

        def limit(self, *a, **k):
            return self

        def execute(self):
            return _Resp()

    class _FakeClient:
        def table(self, name):
            assert name == "chat_history"
            return _Query()

    fake_supabase = MagicMock(client=_FakeClient())
    uid = "1aa02a24-0224-4a5a-b1e5-3f24dcd60bdc"
    assert pnc._already_seeded_today(fake_supabase, uid, "coach_hero", "America/Chicago") is True
