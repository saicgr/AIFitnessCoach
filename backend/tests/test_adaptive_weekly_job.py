"""
Unit tests for the adaptive weekly auto-adjust job + apply helpers
(services/adaptive_weekly_job.py).

Pure service-level tests against an in-memory fake Supabase client — no HTTP, no
real DB (the project's `TestClient(app)` is known-broken — httpx/starlette skew,
per MEMORY.md; HTTP-level tests use threaded uvicorn + httpx). Here we drive the
job functions directly because they're pure over `db.client`.

Covers:
  * apply_targets WRITES the new target_calories/macros and returns old→new
  * the weekly job APPLIES when data quality is high (>= threshold)
  * the weekly job does NOT apply (leaves a pending recommendation) when data
    quality is below threshold

Run:
    cd backend && .venv/bin/pytest tests/test_adaptive_weekly_job.py -v
or:
    cd backend && .venv/bin/python tests/test_adaptive_weekly_job.py
"""
import os
import sys
import uuid
from datetime import datetime, timedelta, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import services.adaptive_weekly_job as job  # noqa: E402
from services.adaptive_weekly_job import (  # noqa: E402
    apply_targets,
    compute_recommended_targets,
    run_for_user,
)

# Don't pull the FastAPI/api cache stack into a pure unit test.
job._invalidate_target_caches = lambda _uid: None  # noqa: SLF001


# ---------------------------------------------------------------------------
# Minimal in-memory fake of the supabase-py PostgREST client. Models only the
# surface the job uses: select / eq / is_ / gte / lte / order / limit /
# maybe_single / execute, plus update + insert.
# ---------------------------------------------------------------------------
class _Res:
    def __init__(self, data):
        self.data = data


class _Query:
    def __init__(self, store, table_name):
        self._store = store
        self._table = table_name
        self._filters = []          # (col, val) equality
        self._null_filters = []     # cols required to be None
        self._gte = []              # (col, val)
        self._lte = []              # (col, val)
        self._order = None          # (col, desc)
        self._limit = None
        self._single = False

    # -- read builders --
    def select(self, *_a, **_k):
        return self

    def eq(self, col, val):
        self._filters.append((col, val))
        return self

    def is_(self, col, val):
        if val == "null":
            self._null_filters.append(col)
        return self

    def gte(self, col, val):
        self._gte.append((col, val))
        return self

    def lte(self, col, val):
        self._lte.append((col, val))
        return self

    def order(self, col, desc=False):
        self._order = (col, desc)
        return self

    def limit(self, n):
        self._limit = n
        return self

    def maybe_single(self):
        self._single = True
        return self

    def _matches(self, row):
        if not all(row.get(c) == v for c, v in self._filters):
            return False
        if not all(row.get(c) is None for c in self._null_filters):
            return False
        if not all(str(row.get(c)) >= str(v) for c, v in self._gte):
            return False
        if not all(str(row.get(c)) <= str(v) for c, v in self._lte):
            return False
        return True

    def execute(self):
        rows = [r for r in self._store if self._matches(r)]
        if self._order:
            col, desc = self._order
            rows = sorted(rows, key=lambda r: str(r.get(col)), reverse=desc)
        if self._limit is not None:
            rows = rows[: self._limit]
        if self._single:
            return _Res(dict(rows[0]) if rows else None)
        return _Res([dict(r) for r in rows])

    # -- write builders --
    def update(self, payload):
        self._update_payload = payload
        return self

    def insert(self, payload):
        rows = payload if isinstance(payload, list) else [payload]
        for r in rows:
            self._store.append(dict(r))
        return _InsertResult([dict(r) for r in rows])

    # update is terminal-ish: .update(payload).eq(...).execute()
    def execute_update(self):
        n = 0
        for r in self._store:
            if self._matches(r):
                r.update(self._update_payload)
                n += 1
        return _Res([{"updated": n}])


class _InsertResult:
    def __init__(self, data):
        self.data = data

    def execute(self):
        return _Res(self.data)


class _UpdateChain:
    """Returned by .update(); supports .eq(...).execute()."""

    def __init__(self, store, payload):
        self._store = store
        self._payload = payload
        self._filters = []

    def eq(self, col, val):
        self._filters.append((col, val))
        return self

    def execute(self):
        n = 0
        for r in self._store:
            if all(r.get(c) == v for c, v in self._filters):
                r.update(self._payload)
                n += 1
        return _Res([{"updated": n}])


class _Table:
    def __init__(self, store, name):
        self._store = store
        self._name = name

    def select(self, *a, **k):
        return _Query(self._store, self._name).select(*a, **k)

    def update(self, payload):
        return _UpdateChain(self._store, payload)

    def insert(self, payload):
        rows = payload if isinstance(payload, list) else [payload]
        for r in rows:
            self._store.append(dict(r))
        return _InsertResult([dict(r) for r in rows])


class FakeClient:
    def __init__(self):
        self.tables = {
            "food_logs": [],
            "weight_logs": [],
            "nutrition_preferences": [],
            "weekly_nutrition_recommendations": [],
            "adaptive_nutrition_calculations": [],
        }

    def table(self, name):
        return _Table(self.tables.setdefault(name, []), name)


class FakeDB:
    def __init__(self):
        self.client = FakeClient()


# ---------------------------------------------------------------------------
# Fixtures / builders
# ---------------------------------------------------------------------------
def _seed_logs(db, user_id, *, food_days, weight_count, calories=2200.0):
    """Seed `food_days` daily food logs + `weight_count` weigh-ins in-window."""
    now = datetime.now(timezone.utc)
    for i in range(food_days):
        ts = (now - timedelta(days=i + 1)).isoformat()
        db.client.tables["food_logs"].append({
            "user_id": user_id,
            "logged_at": ts,
            "total_calories": calories,
            "protein_g": 150,
            "carbs_g": 200,
            "fat_g": 70,
            "deleted_at": None,
        })
    # Spread the weigh-ins across the window with flat weight (Δ≈0 → tdee≈intake).
    span = max(food_days - 1, 1)
    for j in range(weight_count):
        offset = 1 + int(j * span / max(weight_count - 1, 1))
        ts = (now - timedelta(days=offset)).isoformat()
        db.client.tables["weight_logs"].append({
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "weight_kg": 80.0,
            "logged_at": ts,
        })


def _seed_prefs(db, user_id, *, goal="maintain", target_calories=1800, auto=True):
    db.client.tables["nutrition_preferences"].append({
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "nutrition_goal": goal,
        "target_calories": target_calories,
        "target_protein_g": 120,
        "target_carbs_g": 180,
        "target_fat_g": 60,
        "auto_adjust_weekly": auto,
    })


# ---------------------------------------------------------------------------
# (a) compute_recommended_targets — goal-based offsets + macro split
# ---------------------------------------------------------------------------
def test_recommended_targets_goal_offsets():
    cut = compute_recommended_targets(2500, {"nutrition_goal": "lose_fat"})
    assert cut["recommended_calories"] == 2000  # 2500 - 500
    assert cut["target_rate_per_week"] == -0.5

    bulk = compute_recommended_targets(2500, {"nutrition_goal": "build_muscle"})
    assert bulk["recommended_calories"] == 2750  # 2500 + 250

    maint = compute_recommended_targets(2500, {"nutrition_goal": "maintain"})
    assert maint["recommended_calories"] == 2500
    # 30P/40C/30F split of 2500 kcal.
    assert maint["recommended_protein_g"] == int((2500 * 0.30) / 4)
    assert maint["recommended_carbs_g"] == int((2500 * 0.40) / 4)
    assert maint["recommended_fat_g"] == int((2500 * 0.30) / 9)


# ---------------------------------------------------------------------------
# (b) apply_targets WRITES the new target and returns old→new
# ---------------------------------------------------------------------------
def test_apply_targets_writes_and_returns_old_new():
    db = FakeDB()
    user = str(uuid.uuid4())
    _seed_prefs(db, user, target_calories=1800)

    rec = compute_recommended_targets(2400, {"nutrition_goal": "maintain"})
    result = apply_targets(db, user, rec, tdee=2400)

    assert result["old"]["target_calories"] == 1800
    assert result["new"]["target_calories"] == 2400
    assert result["calorie_delta"] == 600

    # The DB row was actually mutated.
    row = db.client.tables["nutrition_preferences"][0]
    assert row["target_calories"] == 2400
    assert row["calculated_tdee"] == 2400
    assert row["last_recalculated_at"] is not None


# ---------------------------------------------------------------------------
# (c) Weekly job APPLIES when data quality is high
# ---------------------------------------------------------------------------
def test_weekly_job_applies_when_confident():
    db = FakeDB()
    user = str(uuid.uuid4())
    _seed_prefs(db, user, goal="maintain", target_calories=1800)
    # 12 logged days + 6 weigh-ins → data_quality ≈ 0.87 (>= 0.6 threshold).
    _seed_logs(db, user, food_days=12, weight_count=6, calories=2300.0)

    out = run_for_user(db, user)
    assert out["applied"] is True, out
    assert out["data_quality_score"] >= job.CONFIDENCE_THRESHOLD
    # target_calories moved off the 1800 base toward the ~2300 TDEE.
    assert out["new"]["target_calories"] != 1800
    assert db.client.tables["nutrition_preferences"][0]["target_calories"] == \
        out["new"]["target_calories"]


# ---------------------------------------------------------------------------
# (d) Weekly job does NOT apply below threshold — leaves a pending rec
# ---------------------------------------------------------------------------
def test_weekly_job_respects_threshold_low_confidence():
    db = FakeDB()
    user = str(uuid.uuid4())
    _seed_prefs(db, user, goal="maintain", target_calories=1800)
    # Only 6 logged days + 2 weigh-ins → data_quality ≈ 0.38 (< 0.6).
    _seed_logs(db, user, food_days=6, weight_count=2, calories=2300.0)

    out = run_for_user(db, user)
    assert out["applied"] is False
    assert out["reason"] == "low_confidence"
    assert out["data_quality_score"] < job.CONFIDENCE_THRESHOLD
    # Base target untouched.
    assert db.client.tables["nutrition_preferences"][0]["target_calories"] == 1800
    # A pending recommendation was left for manual review.
    assert out["pending_recommendation_written"] is True
    pend = db.client.tables["weekly_nutrition_recommendations"]
    assert len(pend) == 1
    assert pend[0]["user_accepted"] is False


# ---------------------------------------------------------------------------
# (e) Insufficient data → no apply, no pending (service returns None)
# ---------------------------------------------------------------------------
def test_weekly_job_insufficient_data():
    db = FakeDB()
    user = str(uuid.uuid4())
    _seed_prefs(db, user)
    _seed_logs(db, user, food_days=3, weight_count=1)  # below service minimums

    out = run_for_user(db, user)
    assert out["applied"] is False
    assert out["reason"] == "insufficient_data"


# ---------------------------------------------------------------------------
# Manual runner (matches test_adaptive_tdee.py's convention).
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
