"""
Unit tests for _count_completed_workouts_for_milestone
(api/v1/workouts/suggestions.py).

E2E register #147: the "~workout #{n+1}" milestone copy in
services/langgraph_agents/workout_insights/nodes.py was fed a LIFETIME
completed-workout count with no assignment scoping, so Day 1 of a brand-new
program could render as "workout number two" whenever the user had prior
completions on a different program (or a stray historical row). The fix
scopes the count to the workout's `assignment_id` when present.

These tests drive the extracted helper directly against a mocked Supabase
fluent query builder — no network, no DB.
"""
import pytest
from unittest.mock import MagicMock

from api.v1.workouts.suggestions import _count_completed_workouts_for_milestone


class _FakeQuery:
    """Minimal stand-in for the supabase-py fluent query builder.

    Records every `.eq(col, val)` call so tests can assert exactly which
    filters were applied, and returns itself from every chained call except
    `.execute()`.
    """

    def __init__(self, count: int):
        self._count = count
        self.eq_calls = []

    def eq(self, col, val):
        self.eq_calls.append((col, val))
        return self

    def limit(self, n):
        return self

    def execute(self):
        result = MagicMock()
        result.count = self._count
        return result


def _fake_db(count: int) -> MagicMock:
    db = MagicMock()
    query = _FakeQuery(count)
    db.client.table.return_value.select.return_value = query
    db._query = query  # stash for assertions
    return db


def test_scopes_to_assignment_when_present():
    db = _fake_db(count=0)
    total = _count_completed_workouts_for_milestone(db, "user-1", "assignment-abc")

    assert total == 0
    assert ("user_id", "user-1") in db._query.eq_calls
    assert ("is_completed", True) in db._query.eq_calls
    assert ("assignment_id", "assignment-abc") in db._query.eq_calls


def test_falls_back_to_lifetime_count_when_no_assignment():
    db = _fake_db(count=12)
    total = _count_completed_workouts_for_milestone(db, "user-1", None)

    assert total == 12
    assert ("user_id", "user-1") in db._query.eq_calls
    assert ("is_completed", True) in db._query.eq_calls
    # No assignment filter applied — standalone/ad-hoc workout.
    assert not any(col == "assignment_id" for col, _ in db._query.eq_calls)


def test_day_one_of_new_program_is_zero_even_with_prior_lifetime_completions():
    """Regression case from the bug report: a user with lifetime completions
    on a PRIOR program must see 0 (not N) for a fresh assignment's Day 1.

    The fake DB simulates assignment-scoped filtering — count is 0 for the
    new assignment even though a lifetime query would have returned > 0.
    """
    class _ScopedFakeQuery(_FakeQuery):
        def eq(self, col, val):
            self.eq_calls.append((col, val))
            if col == "assignment_id":
                self._count = 0  # new assignment: nothing completed yet
            return self

    db = MagicMock()
    query = _ScopedFakeQuery(count=7)  # 7 lifetime completions on old program
    db.client.table.return_value.select.return_value = query
    db._query = query

    total = _count_completed_workouts_for_milestone(db, "user-1", "new-assignment")
    assert total == 0


def test_fails_open_to_zero_on_db_error():
    db = MagicMock()
    db.client.table.side_effect = Exception("connection reset")

    total = _count_completed_workouts_for_milestone(db, "user-1", "assignment-abc")
    assert total == 0
