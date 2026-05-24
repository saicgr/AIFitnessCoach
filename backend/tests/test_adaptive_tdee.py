"""
Unit tests for the adaptive TDEE service — specifically the cycle-aware
7-day pre-period calorie-target hold (Phase E / MacroFactor request 1.3).

Pure service-level tests with an in-memory fake Supabase client (no HTTP,
no real DB). The project's `TestClient(app)` is known-broken (httpx /
starlette skew, per MEMORY.md) so we exercise `compute_tdee_hold`
directly.

Run:
    cd backend && .venv/bin/pytest tests/test_adaptive_tdee.py -v
or:
    cd backend && .venv/bin/python tests/test_adaptive_tdee.py
"""
import os
import sys
import uuid
from datetime import date, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.adaptive_tdee_service import (  # noqa: E402
    HoldResult,
    compute_tdee_hold,
)


# ---------------------------------------------------------------------------
# Minimal in-memory fake of the supabase-py PostgREST client.
# Only models the surface compute_tdee_hold uses:
#   client.table(name).select(...).eq(...).eq(...).limit(N).execute() -> data
#   client.table(name).insert(row).execute()
# ---------------------------------------------------------------------------
class _FakeQuery:
    def __init__(self, store: list[dict]):
        self._store = store
        self._filters: list[tuple[str, object]] = []
        self._limit: int | None = None

    def select(self, *_args, **_kwargs):
        return self

    def eq(self, col, val):
        self._filters.append((col, val))
        return self

    def limit(self, n):
        self._limit = n
        return self

    def execute(self):
        rows = [
            r for r in self._store
            if all(r.get(c) == v for c, v in self._filters)
        ]
        if self._limit is not None:
            rows = rows[: self._limit]

        class _Res:
            def __init__(self, data):
                self.data = data

        return _Res(rows)


class _FakeTable:
    def __init__(self, store: list[dict]):
        self._store = store

    def select(self, *args, **kwargs):
        return _FakeQuery(self._store).select(*args, **kwargs)

    def insert(self, row):
        class _Insert:
            def __init__(self, store, payload):
                self._store = store
                self._payload = payload

            def execute(self):
                # Enforce the (user_id, hold_window_start_date) unique key
                # so the test catches accidental duplicate inserts.
                for existing in self._store:
                    if (
                        existing.get("user_id") == self._payload.get("user_id")
                        and existing.get("hold_window_start_date")
                        == self._payload.get("hold_window_start_date")
                    ):
                        raise RuntimeError("duplicate snapshot key")
                self._store.append(dict(self._payload))

                class _Res:
                    data = [dict(self._payload)]

                return _Res()

        return _Insert(self._store, row)


class FakeClient:
    def __init__(self):
        self.snapshots: list[dict] = []

    def table(self, name):
        if name == "tdee_hold_snapshots":
            return _FakeTable(self.snapshots)
        raise AssertionError(f"unexpected table: {name}")


# ---------------------------------------------------------------------------
# Prediction factory
# ---------------------------------------------------------------------------
def _prediction(
    *,
    today: date,
    days_until_next_period: int,
    last_period_start_offset: int = 28,
    avg_period_length: int = 5,
    current_phase: str = "follicular",
    confidence: str = "high",
    available: bool = True,
):
    """Build a `predict()`-shape dict good enough for compute_tdee_hold."""
    return {
        "predictions_available": available,
        "confidence": confidence,
        "current_phase": current_phase,
        "next_period_date": today + timedelta(days=days_until_next_period),
        "last_period_start": today - timedelta(days=last_period_start_offset),
        "stats": {"avg_period_length": avg_period_length},
    }


USER = str(uuid.uuid4())
TODAY = date(2026, 5, 23)


# ---------------------------------------------------------------------------
# (a) Entering the hold 7 days before predicted period -> pre_period
# ---------------------------------------------------------------------------
def test_enters_hold_seven_days_before_period():
    client = FakeClient()
    pred = _prediction(today=TODAY, days_until_next_period=7,
                       last_period_start_offset=21, current_phase="luteal")
    r = compute_tdee_hold(
        db_client=client, user_id=USER, today=TODAY, prediction=pred,
        menstrual_tracking_enabled=True, cycle_sync_nutrition_enabled=True,
        current_calorie_target=2000, current_cycle_calorie_delta=200,
    )
    assert r.is_held is True
    assert r.hold_reason == "pre_period"
    assert r.frozen_calorie_target == 2000
    assert r.frozen_cycle_calorie_delta == 200
    assert len(client.snapshots) == 1
    assert client.snapshots[0]["hold_reason"] == "pre_period"
    assert client.snapshots[0]["calorie_target_at_entry"] == 2000


# ---------------------------------------------------------------------------
# (b) Remaining in hold during menstruation -> menstrual, returns snapshot
# ---------------------------------------------------------------------------
def test_remains_in_hold_during_menstruation_uses_snapshot():
    client = FakeClient()
    # Day -7 (entry): pre_period
    pred_entry = _prediction(
        today=TODAY, days_until_next_period=7,
        last_period_start_offset=21, current_phase="luteal",
    )
    r1 = compute_tdee_hold(
        db_client=client, user_id=USER, today=TODAY, prediction=pred_entry,
        menstrual_tracking_enabled=True, cycle_sync_nutrition_enabled=True,
        current_calorie_target=2000, current_cycle_calorie_delta=200,
    )
    assert r1.is_held and r1.hold_reason == "pre_period"

    # Day 0 (period starts) — same hold_window_start_date, snapshot reused.
    period_day = TODAY + timedelta(days=7)
    pred_mens = _prediction(
        today=period_day, days_until_next_period=21,
        last_period_start_offset=0, current_phase="menstrual",
    )
    r2 = compute_tdee_hold(
        db_client=client, user_id=USER, today=period_day, prediction=pred_mens,
        menstrual_tracking_enabled=True, cycle_sync_nutrition_enabled=True,
        # Live values changed — snapshot must still win.
        current_calorie_target=1800, current_cycle_calorie_delta=0,
    )
    assert r2.is_held is True
    # Frozen pair survives: 2000 / 200 from entry, NOT 1800/0 live.
    assert r2.frozen_calorie_target == 2000
    assert r2.frozen_cycle_calorie_delta == 200
    # Still exactly one snapshot row (no duplicate insert).
    assert len(client.snapshots) == 1


# ---------------------------------------------------------------------------
# (c) Exiting the hold 4 days post-period -> outside window
# ---------------------------------------------------------------------------
def test_exits_hold_four_days_post_period():
    client = FakeClient()
    # Period started 9 days ago (5-day period ended 4 days ago).
    pred = _prediction(
        today=TODAY, days_until_next_period=19,
        last_period_start_offset=9, avg_period_length=5,
        current_phase="follicular",
    )
    r = compute_tdee_hold(
        db_client=client, user_id=USER, today=TODAY, prediction=pred,
        menstrual_tracking_enabled=True, cycle_sync_nutrition_enabled=True,
        current_calorie_target=2000, current_cycle_calorie_delta=0,
    )
    assert r.is_held is False
    assert r.hold_skipped_reason == "outside_window"
    assert client.snapshots == []


# ---------------------------------------------------------------------------
# (d) Double-bump suppression: luteal × hold returns the snapshot's frozen
#     delta, not a fresh live luteal bump applied on top.
# ---------------------------------------------------------------------------
def test_double_bump_suppression_in_luteal_hold_cell():
    client = FakeClient()
    pred = _prediction(
        today=TODAY, days_until_next_period=5,
        last_period_start_offset=23, current_phase="luteal",
    )
    # Entry: target=2000 already includes a +200 luteal bump (baked in).
    r1 = compute_tdee_hold(
        db_client=client, user_id=USER, today=TODAY, prediction=pred,
        menstrual_tracking_enabled=True, cycle_sync_nutrition_enabled=True,
        current_calorie_target=2000, current_cycle_calorie_delta=200,
    )
    assert r1.is_held and r1.frozen_calorie_target == 2000

    # Next request, caller wrongly passes target=2200 (re-applied bump).
    # Snapshot must still return the entry pair, preventing 2400 doubling.
    r2 = compute_tdee_hold(
        db_client=client, user_id=USER, today=TODAY + timedelta(days=1),
        prediction=pred, menstrual_tracking_enabled=True,
        cycle_sync_nutrition_enabled=True,
        current_calorie_target=2200, current_cycle_calorie_delta=200,
    )
    assert r2.is_held is True
    assert r2.frozen_calorie_target == 2000  # NOT 2200
    assert r2.frozen_cycle_calorie_delta == 200


# ---------------------------------------------------------------------------
# (e) cycle_sync_nutrition_enabled=False -> no hold ('consent_off')
# ---------------------------------------------------------------------------
def test_skips_hold_when_cycle_sync_nutrition_off():
    client = FakeClient()
    pred = _prediction(today=TODAY, days_until_next_period=2,
                       last_period_start_offset=26, current_phase="luteal")
    r = compute_tdee_hold(
        db_client=client, user_id=USER, today=TODAY, prediction=pred,
        menstrual_tracking_enabled=True, cycle_sync_nutrition_enabled=False,
        current_calorie_target=2000, current_cycle_calorie_delta=200,
    )
    assert r.is_held is False
    assert r.hold_skipped_reason == "consent_off"
    assert client.snapshots == []


# ---------------------------------------------------------------------------
# (f) low-confidence prediction -> 'insufficient_prediction_confidence'
# ---------------------------------------------------------------------------
def test_skips_hold_when_prediction_low_confidence():
    client = FakeClient()
    pred = _prediction(today=TODAY, days_until_next_period=3,
                       last_period_start_offset=25, confidence="low",
                       current_phase="luteal")
    r = compute_tdee_hold(
        db_client=client, user_id=USER, today=TODAY, prediction=pred,
        menstrual_tracking_enabled=True, cycle_sync_nutrition_enabled=True,
        current_calorie_target=2000, current_cycle_calorie_delta=200,
    )
    assert r.is_held is False
    assert r.hold_skipped_reason == "insufficient_prediction_confidence"
    assert client.snapshots == []


# ---------------------------------------------------------------------------
# (g) Overlapping windows on a 21-day short cycle: no PK collision
# ---------------------------------------------------------------------------
def test_overlapping_windows_short_cycle_no_key_collision():
    """On a 21-day cycle, the post-period trail of cycle N can overlap
    the pre-period lead of cycle N+1. The unique key is
    (user_id, hold_window_start_date), NOT cycle_start_date, so each
    window must be able to get its own snapshot row.
    """
    client = FakeClient()

    # Cycle N: today is day 6 (1 day past a 5-day period that started day 1).
    # last_period_start = -6 days, period ended 2 days ago → post_period window.
    cycle_n_today = date(2026, 5, 23)
    pred_n = _prediction(
        today=cycle_n_today, days_until_next_period=15,
        last_period_start_offset=6, avg_period_length=5,
        current_phase="follicular",
    )
    r_n = compute_tdee_hold(
        db_client=client, user_id=USER, today=cycle_n_today, prediction=pred_n,
        menstrual_tracking_enabled=True, cycle_sync_nutrition_enabled=True,
        current_calorie_target=2000, current_cycle_calorie_delta=0,
    )
    assert r_n.is_held is True
    assert r_n.hold_reason == "post_period"

    # Cycle N+1: 14 days later (21-day cycle), now 7 days before next period.
    cycle_np1_today = cycle_n_today + timedelta(days=14)
    pred_np1 = _prediction(
        today=cycle_np1_today, days_until_next_period=7,
        last_period_start_offset=20, avg_period_length=5,
        current_phase="luteal",
    )
    r_np1 = compute_tdee_hold(
        db_client=client, user_id=USER, today=cycle_np1_today,
        prediction=pred_np1,
        menstrual_tracking_enabled=True, cycle_sync_nutrition_enabled=True,
        current_calorie_target=2100, current_cycle_calorie_delta=200,
    )
    assert r_np1.is_held is True
    assert r_np1.hold_reason == "pre_period"

    # Two distinct windows → two distinct snapshot rows, no PK collision.
    assert len(client.snapshots) == 2
    starts = {s["hold_window_start_date"] for s in client.snapshots}
    assert len(starts) == 2


# ---------------------------------------------------------------------------
# Extra coverage: menstrual_tracking_enabled=False -> 'tracking_off'
# ---------------------------------------------------------------------------
def test_skips_hold_when_menstrual_tracking_off():
    client = FakeClient()
    pred = _prediction(today=TODAY, days_until_next_period=2,
                       last_period_start_offset=26, current_phase="luteal")
    r = compute_tdee_hold(
        db_client=client, user_id=USER, today=TODAY, prediction=pred,
        menstrual_tracking_enabled=False, cycle_sync_nutrition_enabled=True,
        current_calorie_target=2000, current_cycle_calorie_delta=200,
    )
    assert r.is_held is False
    assert r.hold_skipped_reason == "tracking_off"


# ---------------------------------------------------------------------------
# Manual runner (matches test_cycle_predictor.py's convention).
# ---------------------------------------------------------------------------
def _run_all():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    passed = 0
    for t in tests:
        try:
            t()
            print(f"✅ {t.__name__}")
            passed += 1
        except AssertionError as e:
            print(f"❌ {t.__name__}: {e}")
        except Exception as e:  # noqa: BLE001
            print(f"💥 {t.__name__}: {type(e).__name__}: {e}")
    print(f"\n{passed}/{len(tests)} passed")
    return passed == len(tests)


if __name__ == "__main__":
    sys.exit(0 if _run_all() else 1)
