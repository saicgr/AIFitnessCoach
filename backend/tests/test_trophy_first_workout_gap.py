"""Regression gate for UI_E2E 2026-08-05 row 56 (HIGH), "Day One" sub-defect.

``achievement_types`` has an id='first_workout' / name='Day One' /
threshold_value=1 / threshold_unit='workouts' row (verified live), but
``check_consistency_achievements``'s hardcoded ``total_trophies`` list started
at 10 workouts (bronze) — so a user's first-ever completed workout could
never earn the one trophy explicitly designed to celebrate it, even once the
check actually runs (the separate, bigger wiring defect fixed in
services/workout_completion_hooks.py + api/v1/performance_db.py).

This does not fix the broader gap (of achievement_types' 464 rows, ~428 have
no code path anywhere in trophy_triggers.py that can ever award them) — that
is a much larger systemic issue flagged separately, not part of this row.
"""
import inspect


def test_consistency_achievements_includes_first_workout_threshold():
    import api.v1.trophy_triggers as tt

    src = inspect.getsource(tt.check_consistency_achievements)
    assert '"first_workout", 1' in src, (
        "achievement_types has id='first_workout' (name='Day One', "
        "threshold_value=1, threshold_unit='workouts') but the hardcoded "
        "total_trophies list in check_consistency_achievements starts at "
        "10 (bronze) — a user's very first completed workout never earns "
        "the trophy built to celebrate exactly that."
    )


def test_first_workout_awards_at_one_completed_log(monkeypatch):
    """Direct behavioral check: 1 workout_logs row -> first_workout awarded."""
    import asyncio
    import api.v1.trophy_triggers as tt

    class _CountResp:
        def __init__(self, count):
            self.data = []
            self.count = count

    class _FakeQuery:
        def __init__(self, count):
            self._count = count

        def select(self, *a, **k):
            return self

        def eq(self, *a, **k):
            return self

        def execute(self):
            return _CountResp(self._count)

    class _FakeTable:
        def __init__(self, count):
            self._count = count

        def __call__(self, name):
            return _FakeQuery(self._count)

    class _FakeDB:
        def __init__(self, count):
            self.client = self

        def table(self, name):
            if name == "workout_logs":
                return _FakeQuery(1)
            # user_streaks and everything else: no rows, no crash.
            return _FakeQuery(0)

    awarded_ids = []

    async def fake_award(db, user_id, achievement_id, current_value, metadata=None):
        awarded_ids.append(achievement_id)
        return {"id": achievement_id}

    async def fake_progress(db, user_id, achievement_id, current_value):
        return None

    monkeypatch.setattr(tt, "get_supabase_db", lambda: _FakeDB(1))
    monkeypatch.setattr(tt, "_award_achievement", fake_award)
    monkeypatch.setattr(tt, "_update_trophy_progress", fake_progress)

    result = asyncio.run(tt.check_consistency_achievements("u1"))
    assert "first_workout" in awarded_ids, awarded_ids
