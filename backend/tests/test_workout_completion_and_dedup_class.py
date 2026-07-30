"""Regression gate for the be-workout2 defect class (E2E register #1, #4, #57, #61).

Every assertion here is the CLASS, not the reported instance:

* #1  — no writer may store a workout_logs row as 'completed' with an empty
        set list, and the server (not a fire-and-forget client PATCH) closes a
        session when the user completes the workout.
* #4  — every dedup site that decides "a workout already exists for this day"
        must exclude COMPLETED workouts, and must do so IN THE QUERY (never a
        Python filter applied after `.limit()`).
* #57 — `supersede_workout` must retire the old version BEFORE inserting the
        new one, or the partial unique index rejects the insert.
* #61 — user-initiated extras (chat/studio) must not claim the day's canonical
        is_current slot, and must stay visible to `list_workouts`.
"""

import ast
import inspect
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]


# ---------------------------------------------------------------------------
# #1 — status is always derived from the set list, never defaulted
# ---------------------------------------------------------------------------

def test_sync_bulk_derives_status_from_sets():
    from api.v1.sync import _apply_derived_workout_log_status

    # Empty set list, in every representation the offline queue can produce.
    for empty in ([], "[]", "", None, {}):
        out = _apply_derived_workout_log_status({"sets_json": empty})
        assert out["status"] == "in_progress", empty

    # A client claiming 'completed' with no sets is overruled.
    out = _apply_derived_workout_log_status({"sets_json": [], "status": "completed"})
    assert out["status"] == "in_progress"

    # Real sets -> completed.
    out = _apply_derived_workout_log_status({"sets_json": [{"reps": 5}]})
    assert out["status"] == "completed"

    # A partial update that does not touch the set list gets no invented status.
    out = _apply_derived_workout_log_status({"total_time_seconds": 90})
    assert "status" not in out


def test_sync_bulk_batched_path_uses_the_same_derivation():
    """The batched upsert is the path the offline queue actually drains."""
    import api.v1.sync as sync_mod

    src = inspect.getsource(sync_mod.bulk_sync)
    assert "_apply_derived_workout_log_status" in src, (
        "the batched workout_log bucket must derive status server-side; "
        "otherwise POST /sync/bulk reintroduces register row #1"
    )


def test_complete_endpoint_closes_open_logs_server_side():
    import api.v1.workouts.crud_completion as cc

    src = inspect.getsource(cc.complete_workout)
    assert "finalize_open_logs_for_workout" in src, (
        "POST /workouts/{id}/complete must close the session log server-side — "
        "the Easy finalize PATCH is fire-and-forget and not in the offline queue"
    )


def test_sets_json_is_rebuilt_from_performance_logs_not_fabricated():
    from api.v1.workouts.workout_log_finalize import (
        build_sets_json_from_performance_logs,
    )

    class _Resp:
        def __init__(self, data):
            self.data = data

    class _Q:
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

    class _Client:
        def __init__(self, rows):
            self._rows = rows

        def table(self, name):
            assert name == "performance_logs"
            return _Q(self._rows)

    # No logged sets -> nothing invented.
    assert build_sets_json_from_performance_logs(_Client([]), "log-1") == []

    rows = [{
        "exercise_name": "Barbell Curl",
        "set_number": 1,
        "reps_completed": 10,
        "weight_kg": 32.5,
        "is_completed": True,
        "set_type": "working",
        "rpe": None,
    }]
    out = build_sets_json_from_performance_logs(_Client(rows), "log-1")
    assert len(out) == 1
    assert out[0]["exercise_name"] == "Barbell Curl"
    assert out[0]["reps"] == 10 and out[0]["reps_completed"] == 10
    assert out[0]["weight_kg"] == 32.5
    # An absent optional field stays absent — no fabricated RPE.
    assert "rpe" not in out[0]


# ---------------------------------------------------------------------------
# #4 — every dedup site excludes completed workouts, in the QUERY
# ---------------------------------------------------------------------------

_QUERY_DEDUP_SITES = [
    ("api/v1/workouts/generation_streaming.py", "generate_workout_stream"),
    ("api/v1/workouts/generation_endpoints.py", None),
    ("api/v1/workouts_db_generation.py", None),
]


@pytest.mark.parametrize("relpath", [s[0] for s in _QUERY_DEDUP_SITES])
def test_dedup_queries_filter_completed_in_the_query(relpath):
    src = (BACKEND / relpath).read_text()
    assert "is_completed.is.null,is_completed.eq.false" in src, (
        f"{relpath}: the day-dedup query must exclude completed workouts in the "
        f"QUERY. A Python filter applied after .limit() can see only the "
        f"completed row, generate, and then supersede the user's live workout."
    )


@pytest.mark.parametrize(
    "relpath,func",
    [
        ("api/v1/workouts/generation.py", "generate_next_day_background"),
        ("api/v1/workouts/today.py", "auto_generate_workout"),
    ],
)
def test_list_workouts_dedup_sites_pass_is_completed(relpath, func):
    """`list_workouts` supports is_completed — the BG/pre-cache sites must pass it."""
    tree = ast.parse((BACKEND / relpath).read_text())
    target = None
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == func:
            target = node
            break
    assert target is not None, f"{func} not found in {relpath}"

    # Only the DEDUP reads ("does this day already have a workout?") — the
    # 23505 race-loser refetch deliberately wants the winning row whatever its
    # completion state, and the 14-day pre-cache queue deliberately treats a
    # completed day as covered (see its docstring).
    dedup_targets = {"existing", "existing_suggested"}
    checked = 0
    for node in ast.walk(target):
        if not isinstance(node, ast.Assign):
            continue
        names = {t.id for t in node.targets if isinstance(t, ast.Name)}
        if not (names & dedup_targets):
            continue
        call = node.value
        if not (
            isinstance(call, ast.Call)
            and isinstance(call.func, ast.Attribute)
            and call.func.attr == "list_workouts"
        ):
            continue
        checked += 1
        kwargs = {kw.arg for kw in call.keywords}
        assert "is_completed" in kwargs, (
            f"{relpath}:{func} — the day-dedup db.list_workouts must pass "
            f"is_completed=False, otherwise a finished workout blocks "
            f"generation forever (issue #4)"
        )
    assert checked, f"no dedup list_workouts call found in {func}"


# ---------------------------------------------------------------------------
# #57 — supersede retires before it inserts
# ---------------------------------------------------------------------------

def test_supersede_retires_old_version_before_inserting_new():
    """`workouts_one_current_per_user_day` rejects two current rows on a day."""
    import core.db.workout_db as wdb

    src = inspect.getsource(wdb.WorkoutDB.supersede_workout)
    body = src.split('"""', 2)[-1]  # drop the docstring
    retire_at = body.find('"is_current": False')
    insert_at = body.find("self.create_workout(new_workout_data)")
    assert retire_at != -1 and insert_at != -1
    assert retire_at < insert_at, (
        "supersede_workout must set is_current=False on the OLD row before "
        "inserting the new is_current=True version — otherwise the partial "
        "unique index raises 23505 and single-day regenerate can never commit"
    )
    # And a failed insert must not leave the day with no workout.
    assert '"is_current": True' in body, (
        "a failed insert must restore the old version to current"
    )


# ---------------------------------------------------------------------------
# #61 — chat/studio workouts are extras, not the day's canonical plan
# ---------------------------------------------------------------------------

def test_chat_and_studio_are_user_initiated_extras():
    from core.db.workout_db import (
        USER_INITIATED_WORKOUT_SOURCES,
        _INDEX_EXEMPT_WORKOUT_SOURCES,
    )

    assert "chat" in USER_INITIATED_WORKOUT_SOURCES
    assert "studio" in USER_INITIATED_WORKOUT_SOURCES
    # chat/studio are NOT excluded from workouts_one_current_per_user_day, so
    # they may never be written is_current=TRUE.
    assert "chat" not in _INDEX_EXEMPT_WORKOUT_SOURCES
    assert "studio" not in _INDEX_EXEMPT_WORKOUT_SOURCES


def test_chat_workout_never_claims_the_canonical_slot():
    from core.db.workout_db import WorkoutDB

    captured = {}

    class _Ins:
        def __init__(self, data):
            captured["data"] = data

        def execute(self):
            class R:
                data = [{"id": "new"}]
            return R()

    class _T:
        def insert(self, data):
            return _Ins(data)

    class _C:
        def table(self, name):
            return _T()

    class _StubDB(WorkoutDB):
        def __init__(self):  # no Supabase manager needed
            pass

        @property
        def client(self):
            return _C()

    db = _StubDB()

    db.create_workout({
        "user_id": "u1",
        "name": "Coach session",
        "generation_source": "chat",
        "exercises_json": [],
        "scheduled_date": "2026-08-01T17:00:00+00:00",
    })
    assert captured["data"]["is_current"] is False, (
        "a coach/chat-created workout must be a same-day EXTRA "
        "(is_current=False, valid_to=None), never the day's canonical row"
    )
    assert captured["data"]["valid_to"] is None

    # An explicit caller choice (the SCD2 supersede path) still wins.
    captured.clear()
    db.create_workout({
        "user_id": "u1",
        "generation_source": "chat",
        "is_current": True,
        "exercises_json": [],
    })
    assert captured["data"]["is_current"] is True


def test_extras_stay_visible_to_list_workouts():
    """An is_current=FALSE extra must still be admitted by the read filter."""
    import core.db.workout_db as wdb

    src = inspect.getsource(wdb.WorkoutDB.list_workouts)
    assert "USER_INITIATED_WORKOUT_SOURCES" in src, (
        "the extras branch of the list_workouts or_() filter must be built from "
        "the single enumeration, or an is_current=FALSE chat workout becomes "
        "invisible in /today, /schedule and the workout tab"
    )


def test_streaming_supersede_spares_user_initiated_extras():
    """Generating the day's plan must not demote the user's own same-day extras."""
    src = (BACKEND / "api/v1/workouts/generation_streaming.py").read_text()
    assert "generation_source.not.in." in src, (
        "the /generate-stream supersede UPDATE must exclude "
        "USER_INITIATED_WORKOUT_SOURCES — demoting an is_current extra also "
        "stamps valid_to, which drops it out of list_workouts' extras branch "
        "and makes the user's own workout vanish (issue #4 residual)"
    )
    assert "USER_INITIATED_WORKOUT_SOURCES" in src, (
        "build the exclusion from the single enumeration in core.db.workout_db"
    )
