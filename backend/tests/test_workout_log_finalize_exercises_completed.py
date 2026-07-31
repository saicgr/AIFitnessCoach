"""
Regression test for E2E register #139:
``workout_logs.exercises_completed`` is real (migration 1880) but no server
writer ever set it — the client posts its own count to a DIFFERENT table
(``workout_exits``), not ``workout_logs``. This pins that
``finalize_workout_log_row`` (the single server-side session-close
chokepoint) now derives and writes it from the durable set list.
"""
from api.v1.workouts.workout_log_finalize import (
    finalize_workout_log_row,
    _count_completed_exercises,
)


class _Resp:
    def __init__(self, data):
        self.data = data


class _PerfLogsQuery:
    """Stand-in for `.table("performance_logs").select(...).eq(...).order(...).order(...).execute()`."""

    def __init__(self, rows):
        self._rows = rows

    def select(self, *a, **k):
        return self

    def eq(self, *a, **k):
        return self

    def order(self, *a, **k):
        return self

    def execute(self):
        return _Resp(self._rows)


class _UpdateQuery:
    def __init__(self, sink, table_name):
        self._sink = sink
        self._table = table_name

    def update(self, payload):
        self._sink.append((self._table, payload))
        return self

    def eq(self, *a, **k):
        return self

    def execute(self):
        return _Resp(None)


class _FakeClient:
    """Routes `.table("performance_logs")` to a fixed row set and captures
    every `.table("workout_logs").update(...)` payload."""

    def __init__(self, performance_rows):
        self._performance_rows = performance_rows
        self.updates = []

    def table(self, name):
        if name == "performance_logs":
            return _PerfLogsQuery(self._performance_rows)
        if name == "workout_logs":
            return _UpdateQuery(self.updates, name)
        raise AssertionError(f"unexpected table {name}")


def _perf_row(exercise_name, set_number, exercise_id=None, is_completed=True):
    return {
        "exercise_name": exercise_name,
        "exercise_id": exercise_id,
        "set_number": set_number,
        "reps_completed": 10,
        "weight_kg": 25.0,
        "rpe": None,
        "rir": None,
        "set_type": "working",
        "is_completed": is_completed,
        "set_duration_seconds": None,
        "distance_meters": None,
        "logging_mode": "manual",
        "recorded_at": f"2026-07-30T12:0{set_number}:00Z",
    }


# ---------------------------------------------------------------------------
# _count_completed_exercises — the pure derivation
# ---------------------------------------------------------------------------
def test_count_completed_exercises_counts_distinct_exercises():
    sets = [
        {"exercise_name": "Bench Press", "set_number": 1, "is_completed": True},
        {"exercise_name": "Bench Press", "set_number": 2, "is_completed": True},
        {"exercise_name": "Barbell Row", "set_number": 1, "is_completed": True},
    ]
    assert _count_completed_exercises(sets) == 2


def test_count_completed_exercises_excludes_explicitly_incomplete_sets():
    sets = [
        {"exercise_name": "Bench Press", "is_completed": True},
        {"exercise_name": "Skipped Move", "is_completed": False},
    ]
    assert _count_completed_exercises(sets) == 1


def test_count_completed_exercises_prefers_exercise_id():
    # Same exercise_id, different display name variants -> still one exercise.
    sets = [
        {"exercise_id": "ex-1", "exercise_name": "Bench Press", "is_completed": True},
        {"exercise_id": "ex-1", "exercise_name": "Bench Press (Barbell)", "is_completed": True},
    ]
    assert _count_completed_exercises(sets) == 1


def test_count_completed_exercises_empty_or_bad_input():
    assert _count_completed_exercises([]) == 0
    assert _count_completed_exercises(None) == 0
    assert _count_completed_exercises("not json") == 0
    assert _count_completed_exercises("[]") == 0


def test_count_completed_exercises_parses_json_string():
    import json
    sets_str = json.dumps([
        {"exercise_name": "Squat", "is_completed": True},
        {"exercise_name": "Deadlift", "is_completed": True},
    ])
    assert _count_completed_exercises(sets_str) == 2


# ---------------------------------------------------------------------------
# finalize_workout_log_row — the real chokepoint writes exercises_completed
# ---------------------------------------------------------------------------
def test_finalize_writes_exercises_completed_when_rebuilding_from_performance_logs():
    """Watch-sync-style row: sets_json empty, performance_logs has the truth."""
    rows = [
        _perf_row("SkiErg", 1, exercise_id="ex-ski"),
        _perf_row("Wall Ball", 1, exercise_id="ex-wb"),
        _perf_row("Wall Ball", 2, exercise_id="ex-wb"),
    ]
    client = _FakeClient(rows)

    log_row = {"id": "log-1", "sets_json": [], "status": "in_progress"}
    outcome = finalize_workout_log_row(client, log_row)

    assert outcome["sets_backfilled"] == 3
    assert len(client.updates) == 1
    _, payload = client.updates[0]
    assert payload["exercises_completed"] == 2  # SkiErg + Wall Ball


def test_finalize_writes_exercises_completed_from_existing_sets_json():
    """Easy-tier row: sets_json already populated (PATCH landed normally)."""
    client = _FakeClient(performance_rows=[])  # not consulted — sets_json non-empty
    log_row = {
        "id": "log-2",
        "sets_json": [
            {"exercise_name": "Back Squat", "set_number": 1, "is_completed": True},
            {"exercise_name": "Back Squat", "set_number": 2, "is_completed": True},
            {"exercise_name": "Leg Press", "set_number": 1, "is_completed": True},
        ],
        "status": "in_progress",
    }
    outcome = finalize_workout_log_row(client, log_row)

    assert outcome["sets_backfilled"] == 0
    _, payload = client.updates[0]
    assert payload["exercises_completed"] == 2  # Back Squat + Leg Press


def test_finalize_writes_zero_when_no_sets_anywhere():
    client = _FakeClient(performance_rows=[])
    log_row = {"id": "log-3", "sets_json": [], "status": "in_progress"}
    finalize_workout_log_row(client, log_row)

    _, payload = client.updates[0]
    assert payload["exercises_completed"] == 0
