"""Entry-point robustness: completeness enforcement, request-boundary safety
clamps (Phase D), generation idempotency (E2), and stale-plan invalidation on
injury change (E3).

These are DETERMINISTIC, in-memory unit tests for the entry-point chokepoint
helpers and the uniform completeness invariant. The three generation entry
points — the onboarding INITIAL plan (today.py → /generate), /regenerate-stream,
and /regenerate (non-stream) — now all run the SAME completeness stage
(``ensure_complete_workout``) so no path ships below its duration/type floor.

Run:
    .venv312/bin/python -m pytest tests/test_generation_edge_cases_entry.py -q
"""
import re
from pathlib import Path

import pytest

from api.v1.workouts.utils import (
    # D — request-boundary safety clamps
    clamp_days_per_week,
    reconcile_workout_days,
    clamp_session_minutes,
    normalize_body_measurements,
    clamp_goal_and_rate,
    DAYS_PER_WEEK_MAX,
    MIN_SESSION_MINUTES,
    # E2 — generation idempotency
    generation_request_hash,
    claim_generation_slot,
    release_generation_slot,
    _gen_idempotency_seen,
)

_BACKEND = Path(__file__).resolve().parents[1]
_WORKOUTS = _BACKEND / "api" / "v1" / "workouts"


# ===========================================================================
# A4 — UNIFORM COMPLETENESS ENFORCEMENT across all 3 entry points
# ===========================================================================
#
# The onboarding initial plan flows through today.py::auto_generate_workout →
# generate_workout (/generate in generation_endpoints.py), which already runs
# ensure_complete_workout. /regenerate-stream + /regenerate (versioning.py)
# previously did NOT. These guard tests pin that every entry-point source now
# calls ensure_complete_workout, so a future refactor can't silently drop the
# floor on one path.


def _read(p: Path) -> str:
    return p.read_text()


def test_generate_entry_calls_ensure_complete_workout():
    """The onboarding-first-plan path (today.py → /generate) enforces the floor."""
    src = _read(_WORKOUTS / "generation_endpoints.py")
    assert "ensure_complete_workout(" in src
    assert "completeness_enabled(" in src


def test_regenerate_stream_calls_ensure_complete_workout():
    """/regenerate-stream now runs the SAME completeness stage (was a gap)."""
    src = _read(_WORKOUTS / "versioning.py")
    # Both the stream and non-stream regenerate must reference the stage.
    assert src.count("ensure_complete_workout(") >= 2, (
        "expected ensure_complete_workout in BOTH /regenerate-stream and /regenerate"
    )
    assert "completeness_enabled(" in src


def test_onboarding_first_plan_is_not_legacy_floor_one_path():
    """today.py's auto-gen calls /generate (completeness-enforced), never a
    legacy floor=1 path. Pin the call so onboarding can't regress to it."""
    src = _read(_WORKOUTS / "today.py")
    assert "from .generation_endpoints import generate_workout" in src


@pytest.mark.asyncio
async def test_ensure_complete_workout_enforces_floor_via_rag_backfill():
    """The shared service all 3 entry points call backfills a thin list toward
    target. Mock the rag_service so the test is deterministic + offline."""
    from services.workout_completeness import ensure_complete_workout

    class _FakeRag:
        async def select_exercises_with_fallback(self, **kwargs):
            count = kwargs.get("count", 4)
            pool = [
                {"name": f"Backfill Move {i}", "exercise_id": f"bf{i}",
                 "equipment": "bodyweight", "target_muscles": ["full_body"]}
                for i in range(count + 4)
            ]
            return pool, "tier1"

    thin = [{"name": "Only One", "exercise_id": "x1", "equipment": "bodyweight"}]
    result, degraded = await ensure_complete_workout(
        thin,
        target=5,
        floor=4,
        focus_area="full_body",
        equipment=[],
        fitness_level="intermediate",
        goals=[],
        workout_type="strength",
        rag_service=_FakeRag(),
    )
    # Distinct count must reach at least the floor.
    names = {(e.get("name") or "").strip().lower() for e in result}
    assert len(names) >= 4, f"expected >=4 distinct, got {len(names)}: {names}"


# ===========================================================================
# D1 — schedule clamps
# ===========================================================================


@pytest.mark.parametrize("raw,expected", [
    (0, 1),       # guard 0 days
    (-3, 1),
    (1, 1),
    (3, 3),
    (6, 6),
    (7, 6),       # 7 → 6 (7th day stays rest)
    (12, 6),
    (None, 1),
    ("garbage", 1),
])
def test_clamp_days_per_week(raw, expected):
    assert clamp_days_per_week(raw) == expected


def test_reconcile_workout_days_drops_seventh_hard_day():
    """A 7-day-a-week schedule never yields 7 training days."""
    out = reconcile_workout_days([0, 1, 2, 3, 4, 5, 6], 7)
    assert len(out) <= DAYS_PER_WEEK_MAX
    assert out == [0, 1, 2, 3, 4, 5]


def test_reconcile_workout_days_reconciles_count_mismatch():
    """workout_days longer than days_per_week is trimmed to match."""
    out = reconcile_workout_days([0, 1, 2, 3, 4], 3)
    assert len(out) == 3
    assert out == [0, 1, 2]


def test_reconcile_workout_days_backfills_empty_with_positive_dpw():
    """Empty/malformed weekday list + positive days_per_week → first N weekdays,
    so generation never sees 0 days."""
    out = reconcile_workout_days([], 4)
    assert out == [0, 1, 2, 3]
    # Malformed entries are dropped, not crashed on.
    out2 = reconcile_workout_days(["x", 9, -1, 2, 2], None)
    assert out2 == [2]


def test_reconcile_workout_days_dedups_and_sorts():
    out = reconcile_workout_days([5, 1, 1, 3], None)
    assert out == [1, 3, 5]


@pytest.mark.parametrize("raw,expected", [
    (0, 45),                      # 0 is "unspecified" → sane default, not 0
    (3, MIN_SESSION_MINUTES),     # short but specified → clamp up to the floor
    (None, 45),                   # default when unset
    (45, 45),
    (90, 90),
])
def test_clamp_session_minutes(raw, expected):
    assert clamp_session_minutes(raw) == expected


def test_clamp_session_minutes_never_below_floor():
    for v in (1, 5, 9, MIN_SESSION_MINUTES):
        assert clamp_session_minutes(v) >= MIN_SESSION_MINUTES


# ===========================================================================
# D3 — measurement guards (no divide-by-zero, unit sanity)
# ===========================================================================


def test_normalize_body_measurements_missing_uses_defaults():
    out = normalize_body_measurements(None, None)
    assert out["height_cm"] > 0
    assert out["weight_kg"] > 0
    assert out["weight_normalized"] is False


def test_normalize_body_measurements_zero_height_no_crash():
    out = normalize_body_measurements(0, 0)
    assert out["height_cm"] > 0  # never 0 → BMI/BMR math safe
    assert out["weight_kg"] > 0


def test_normalize_body_measurements_plausible_kg_unchanged():
    """A normal 175cm / 80kg user passes through untouched (fail-open)."""
    out = normalize_body_measurements(175, 80)
    assert out["height_cm"] == 175.0
    assert out["weight_kg"] == 80.0
    assert out["weight_normalized"] is False


def test_normalize_body_measurements_lb_mislabeled_kg_is_converted():
    """A 300 'kg' weight is clearly a lb value → normalized to ~136kg."""
    out = normalize_body_measurements(180, 300)
    assert out["weight_normalized"] is True
    assert 130 <= out["weight_kg"] <= 140


def test_normalize_body_measurements_absurd_weight_clamped():
    out = normalize_body_measurements(180, 9000)
    # 9000/2.2 ≈ 4082 still absurd → clamp to the kg ceiling, no crash.
    assert out["weight_kg"] <= 250.0


# ===========================================================================
# D2 — goal / rate clamps
# ===========================================================================


def test_clamp_goal_and_rate_caps_weekly_rate():
    out = clamp_goal_and_rate(current_weight_kg=90, goal_weight_kg=80,
                              weekly_rate_kg=2.5, height_cm=180)
    assert abs(out["weekly_rate_kg"]) <= 0.9 + 1e-9
    assert out["rate_clamped"] is True


def test_clamp_goal_and_rate_preserves_sign():
    gain = clamp_goal_and_rate(70, 80, 2.0, 180)
    loss = clamp_goal_and_rate(90, 70, -2.0, 180)
    assert gain["weekly_rate_kg"] > 0
    assert loss["weekly_rate_kg"] < 0


def test_clamp_goal_and_rate_raises_unsafe_bmi_goal():
    """A goal implying BMI < 18.5 is raised to the BMI-18.5 weight."""
    # 180cm, BMI 18.5 floor ≈ 59.9kg. Goal of 45kg is unsafe.
    out = clamp_goal_and_rate(80, 45, 0.5, 180)
    assert out["goal_clamped"] is True
    assert out["goal_weight_kg"] >= 59.0


def test_clamp_goal_and_rate_safe_goal_unchanged():
    out = clamp_goal_and_rate(90, 75, 0.5, 180)
    assert out["goal_clamped"] is False
    assert out["rate_clamped"] is False
    assert out["goal_weight_kg"] == 75.0


def test_clamp_goal_and_rate_none_inputs_fail_open():
    out = clamp_goal_and_rate(None, None, None, None)
    assert out["goal_weight_kg"] is None
    assert out["weekly_rate_kg"] is None
    assert out["goal_clamped"] is False


# ===========================================================================
# E2 — generation idempotency (double-tap → one creation)
# ===========================================================================


def test_idempotency_double_tap_claims_once():
    _gen_idempotency_seen.clear()
    h = generation_request_hash("user-1", "regen", "w-1", "2026-06-20")
    first = claim_generation_slot(h)
    second = claim_generation_slot(h)
    assert first is True   # first caller proceeds (creates)
    assert second is False  # duplicate is suppressed → no second creation


def test_idempotency_distinct_requests_both_proceed():
    _gen_idempotency_seen.clear()
    h1 = generation_request_hash("user-1", "regen", "w-1", "2026-06-20")
    h2 = generation_request_hash("user-1", "regen", "w-2", "2026-06-20")
    assert claim_generation_slot(h1) is True
    assert claim_generation_slot(h2) is True  # different workout → not deduped


def test_idempotency_release_allows_retry():
    _gen_idempotency_seen.clear()
    h = generation_request_hash("user-1", "regen", "w-1", "2026-06-20")
    assert claim_generation_slot(h) is True
    assert claim_generation_slot(h) is False
    # On failure, release so the user's retry isn't suppressed.
    release_generation_slot(h)
    assert claim_generation_slot(h) is True


def test_idempotency_ttl_expiry(monkeypatch):
    _gen_idempotency_seen.clear()
    h = generation_request_hash("user-1", "regen", "w-1", "2026-06-20")
    assert claim_generation_slot(h, ttl_seconds=0.0) is True
    # With a 0s TTL the prior entry is immediately expired → next claim proceeds.
    assert claim_generation_slot(h, ttl_seconds=0.0) is True


def test_generation_request_hash_is_stable_and_distinct():
    a = generation_request_hash("u", "regen", "w", "2026-06-20")
    b = generation_request_hash("u", "regen", "w", "2026-06-20")
    c = generation_request_hash("u", "regen", "w", "2026-06-21")
    assert a == b
    assert a != c


# ===========================================================================
# E3 — stale-plan invalidation on injury change
# ===========================================================================


class _FakeResult:
    def __init__(self, data):
        self.data = data


class _FakeQuery:
    """Minimal chainable Supabase query stub recording delete intent."""

    def __init__(self, store, table):
        self._store = store
        self._table = table
        self._op = "select"
        self._filters = {}
        self._in_ids = None

    def select(self, *a, **k):
        self._op = "select"
        return self

    def delete(self, *a, **k):
        self._op = "delete"
        return self

    def eq(self, col, val):
        self._filters[col] = val
        return self

    def gt(self, col, val):
        self._filters[f"gt_{col}"] = val
        return self

    def in_(self, col, ids):
        self._in_ids = list(ids)
        return self

    def _matches(self, row):
        for col, val in self._filters.items():
            if col.startswith("gt_"):
                real = col[3:]
                if not (str(row.get(real, "")) > str(val)):
                    return False
            else:
                if row.get(col) != val:
                    return False
        return True

    def execute(self):
        if self._op == "select":
            return _FakeResult([r for r in self._store["rows"] if self._matches(r)])
        if self._op == "delete":
            ids = set(self._in_ids or [])
            deleted = [r for r in self._store["rows"] if r["id"] in ids]
            self._store["rows"] = [r for r in self._store["rows"] if r["id"] not in ids]
            self._store["deleted"].extend(deleted)
            return _FakeResult(deleted)
        return _FakeResult([])


class _FakeClient:
    def __init__(self, store):
        self._store = store

    def table(self, name):
        return _FakeQuery(self._store, name)


class _FakeDB:
    def __init__(self, store):
        self.client = _FakeClient(store)


def test_invalidate_after_injury_change_deletes_future_incomplete(monkeypatch):
    from api.v1.workouts import utils as u

    today = "2026-06-20"
    store = {
        "rows": [
            {"id": "today-open", "user_id": "user-1", "scheduled_date": today, "status": "scheduled", "is_completed": False},
            {"id": "today-inprog", "user_id": "user-1", "scheduled_date": today, "status": "in_progress", "is_completed": False},
            {"id": "today-done", "user_id": "user-1", "scheduled_date": today, "status": "completed", "is_completed": True},
            {"id": "future-open", "user_id": "user-1", "scheduled_date": "2026-06-22", "status": "scheduled", "is_completed": False},
            {"id": "past-done", "user_id": "user-1", "scheduled_date": "2026-06-10", "status": "completed", "is_completed": True},
        ],
        "deleted": [],
    }
    monkeypatch.setattr(u, "get_supabase_db", lambda: _FakeDB(store))
    monkeypatch.setattr(u, "get_user_today", lambda tz: today)

    res = u.invalidate_workouts_after_injury_change("user-1", timezone_str="UTC")

    deleted_ids = {r["id"] for r in store["deleted"]}
    # not-started today + future-open deleted; in-progress / completed / past kept.
    assert "today-open" in deleted_ids
    assert "future-open" in deleted_ids
    assert "today-inprog" not in deleted_ids
    assert "today-done" not in deleted_ids
    assert "past-done" not in deleted_ids
    assert res["today_deleted"] == 1


def test_update_program_wires_injury_invalidation():
    """program.py::update_program calls the E3 sibling on an injury change."""
    src = _read(_WORKOUTS / "program.py")
    assert "invalidate_workouts_after_injury_change" in src
    assert "_injuries_changed" in src


def test_update_program_clamps_schedule():
    """program.py persists a reconciled (clamped) schedule, not a raw 7-day one."""
    src = _read(_WORKOUTS / "program.py")
    assert "reconcile_workout_days" in src
    assert "clamp_days_per_week" in src
    assert "clamp_session_minutes" in src


def test_generate_entry_clamps_schedule():
    """/generate clamps stored workout_days at the entry point (every gen)."""
    src = _read(_WORKOUTS / "generation_endpoints.py")
    assert "reconcile_workout_days(" in src
