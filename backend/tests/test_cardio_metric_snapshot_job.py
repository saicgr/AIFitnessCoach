"""
Tests for cardio_metric_snapshot_job — Wave 2 SLICE_TRENDS.

These tests use a hand-rolled fake DB rather than the real Supabase client so
they run without network. The fake mimics the small slice of `db.client.table()
.select(...).eq(...).gte(...).execute()` chain that the job actually uses, plus
`.upsert(...).execute()` for writes.

Coverage:
  - Every metric_key is computed correctly from synthetic cardio data.
  - Idempotency: running twice produces one UPSERT call per row (the unique
    constraint is exercised in production; here we assert the writer always
    re-emits the same row payload).
  - Empty-user skip: a user with no cardio activity produces zero records
    (NO silent-fallback zeros).
  - Single-user vs sweep entrypoints.
"""
from __future__ import annotations

import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

import pytest

# Make `backend/` importable.
BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from services import cardio_metric_snapshot_job as job  # noqa: E402
from services.race_predictor_service import RacePrediction  # noqa: E402
from services.training_load_service import TrainingLoadState  # noqa: E402


# ---------------------------------------------------------------------------
# Fake Supabase client — supports the read/write chain the job uses.
# ---------------------------------------------------------------------------

class _Result:
    def __init__(self, data: List[Dict[str, Any]]):
        self.data = data


class _TableQuery:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._rows = rows
        self._filters: List[Any] = []
        self._upserted: Optional[List[Dict[str, Any]]] = None

    def select(self, *_args, **_kwargs):
        return self

    def eq(self, _col, _val):
        return self

    def gte(self, _col, _val):
        return self

    def order(self, *_args, **_kwargs):
        return self

    def upsert(self, rows, **_kwargs):
        self._upserted = list(rows)
        return self

    def execute(self):
        if self._upserted is not None:
            return _Result(self._upserted)
        return _Result(self._rows)


class FakeClient:
    def __init__(self, tables: Dict[str, List[Dict[str, Any]]]):
        self.tables = tables
        self.upserts: Dict[str, List[List[Dict[str, Any]]]] = {}

    def table(self, name: str) -> _TableQuery:
        rows = self.tables.get(name, [])
        q = _TableQuery(rows)
        # Capture upserts via the result; we wrap execute to record.
        original_execute = q.execute

        def execute():
            res = original_execute()
            if q._upserted is not None:
                self.upserts.setdefault(name, []).append(list(q._upserted))
            return res

        q.execute = execute  # type: ignore[assignment]
        return q


class FakeDB:
    def __init__(self, tables: Dict[str, List[Dict[str, Any]]]):
        self.client = FakeClient(tables)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

USER = "user-abc"
TODAY = date(2026, 5, 24)


def _iso_at(days_ago: int) -> str:
    dt = datetime.combine(TODAY, datetime.min.time(), tzinfo=timezone.utc) - timedelta(days=days_ago)
    return dt.isoformat()


@pytest.fixture
def cardio_db() -> FakeDB:
    """A user with 3 runs in the last 7 days + weather data.

    IMPORTANT — the two source tables store DIFFERENT units, and this fixture
    mirrors the real schema exactly (see scripts/schema_columns_snapshot.json):

      cardio_logs     → distance_m  (meters)     + duration_seconds + performed_at
      cardio_sessions → distance_km (kilometers) + duration_minutes + started_at

    The fixture previously gave the cardio_sessions row `distance_m`/
    `duration_seconds` — columns that do not exist on that table. The loader
    (`_fetch_recent_cardio`) reads the real columns and converts km→m and
    min→s, so the phantom-column row contributed None distance and was silently
    dropped from every rolling-window metric. Same 3km / 900s run, expressed in
    the units the table actually uses.
    """
    return FakeDB({
        "cardio_logs": [
            # 5km in 1500s, 3 days ago, 20°C
            {"user_id": USER, "activity_type": "run", "distance_m": 5000,
             "duration_seconds": 1500, "performed_at": _iso_at(3),
             "weather_json": {"temperature_c": 20.0}},
            # 8km in 2640s, 5 days ago, 18°C
            {"user_id": USER, "activity_type": "running", "distance_m": 8000,
             "duration_seconds": 2640, "performed_at": _iso_at(5),
             "weather_json": {"temperature_c": 18.0}},
        ],
        "cardio_sessions": [
            # 3km (= 3000m) in 15min (= 900s), 1 day ago, 22°C (manual)
            {"user_id": USER, "cardio_type": "run", "distance_km": 3.0,
             "duration_minutes": 15.0, "started_at": _iso_at(1),
             "weather_json": {"temperature_c": 22.0}},
        ],
    })


@pytest.fixture(autouse=True)
def stub_predictors(monkeypatch):
    """Stub race_predictor + training_load services so tests don't hit the DB."""
    def fake_predict(_db, _uid, *, now=None):
        return {
            "five_k": RacePrediction(
                predicted_seconds=1450, distance_m=5000,
                base_run={"distance_m": 5000, "time_seconds": 1500,
                          "performed_at": _iso_at(3), "cardio_log_id": None},
                confidence=0.9, formula="riegel", age_days_of_base=3,
            ),
            "ten_k": RacePrediction(
                predicted_seconds=3015, distance_m=10000,
                base_run={"distance_m": 5000, "time_seconds": 1500,
                          "performed_at": _iso_at(3), "cardio_log_id": None},
                confidence=0.85, formula="riegel", age_days_of_base=3,
            ),
            "half_marathon": RacePrediction(
                predicted_seconds=6600, distance_m=21097,
                base_run={"distance_m": 5000, "time_seconds": 1500,
                          "performed_at": _iso_at(3), "cardio_log_id": None},
                confidence=0.6, formula="cameron", age_days_of_base=3,
            ),
            "marathon": RacePrediction(
                predicted_seconds=13800, distance_m=42195,
                base_run={"distance_m": 5000, "time_seconds": 1500,
                          "performed_at": _iso_at(3), "cardio_log_id": None},
                confidence=0.5, formula="cameron", age_days_of_base=3,
            ),
        }
    monkeypatch.setattr(job.race_predictor_service, "predict_for_user", fake_predict)

    def fake_state(_db, _uid):
        return TrainingLoadState(
            as_of=TODAY, daily_trimp=50.0, acute_load=350.0, chronic_load=300.0,
            acwr=1.17, state="balanced",
            interpretation="balanced load",
            days_of_history=60,
        )
    monkeypatch.setattr(job.training_load_service, "current_state", fake_state)


# ---------------------------------------------------------------------------
# Per-metric correctness
# ---------------------------------------------------------------------------

def test_all_thirteen_metrics_registered():
    assert len(job.REGISTERED_METRIC_KEYS) == 13


def test_compute_for_user_emits_expected_metrics(cardio_db):
    records = job.compute_snapshots_for_user(cardio_db, USER, snapshot_date=TODAY)
    keys = {r.metric_key for r in records}

    # 4 race + 3 training-load + 5 rolling cardio = 12 (refuel skipped — no table)
    expected = {
        "race_predicted_5k_sec", "race_predicted_10k_sec",
        "race_predicted_half_sec", "race_predicted_marathon_sec",
        "training_load_acute", "training_load_chronic", "training_load_acwr",
        "cardio_weekly_distance_m", "cardio_longest_run_m",
        "cardio_fastest_mile_sec", "cardio_pace_avg_sec_per_km",
        "cardio_weather_temp_at_run_c",
    }
    assert expected.issubset(keys)


def test_weekly_distance_sums_logs_and_sessions(cardio_db):
    records = {r.metric_key: r for r in
               job.compute_snapshots_for_user(cardio_db, USER, snapshot_date=TODAY)}
    # 5000 + 8000 + 3000 = 16000m
    assert records["cardio_weekly_distance_m"].value_numeric == pytest.approx(16000.0)


def test_longest_run_picks_max_running_distance(cardio_db):
    records = {r.metric_key: r for r in
               job.compute_snapshots_for_user(cardio_db, USER, snapshot_date=TODAY)}
    assert records["cardio_longest_run_m"].value_numeric == pytest.approx(8000.0)


def test_fastest_mile_uses_best_proportional_pace(cardio_db):
    records = {r.metric_key: r for r in
               job.compute_snapshots_for_user(cardio_db, USER, snapshot_date=TODAY)}
    # Best pace = 5km in 1500s → 1500 * (1609.34/5000) ≈ 482.80s.
    # 8km in 2640s → 2640 * (1609.34/8000) ≈ 531.08s.
    # 3km in 900s → 3000m >= MILE_M ✗ wait: 3000 >= 1609.34 ✓ → 900*(1609.34/3000)≈482.80.
    # So fastest ≈ 482.80.
    assert records["cardio_fastest_mile_sec"].value_numeric == pytest.approx(482.80, abs=0.5)


def test_pace_avg_is_distance_weighted(cardio_db):
    records = {r.metric_key: r for r in
               job.compute_snapshots_for_user(cardio_db, USER, snapshot_date=TODAY)}
    # total_time / total_dist * 1000 = (1500+2640+900) / 16000 * 1000 = 315.0
    assert records["cardio_pace_avg_sec_per_km"].value_numeric == pytest.approx(315.0)


def test_weather_temp_is_mean_across_runs(cardio_db):
    records = {r.metric_key: r for r in
               job.compute_snapshots_for_user(cardio_db, USER, snapshot_date=TODAY)}
    # (20 + 18 + 22) / 3 = 20.0
    assert records["cardio_weather_temp_at_run_c"].value_numeric == pytest.approx(20.0)


def test_training_load_metrics_populated(cardio_db):
    records = {r.metric_key: r for r in
               job.compute_snapshots_for_user(cardio_db, USER, snapshot_date=TODAY)}
    assert records["training_load_acute"].value_numeric == pytest.approx(350.0)
    assert records["training_load_chronic"].value_numeric == pytest.approx(300.0)
    assert records["training_load_acwr"].value_numeric == pytest.approx(1.17)


def test_race_predictions_persist_predicted_seconds(cardio_db):
    records = {r.metric_key: r for r in
               job.compute_snapshots_for_user(cardio_db, USER, snapshot_date=TODAY)}
    assert records["race_predicted_5k_sec"].value_numeric == 1450
    assert records["race_predicted_marathon_sec"].value_numeric == 13800


# ---------------------------------------------------------------------------
# Empty-user / no-data handling
# ---------------------------------------------------------------------------

def test_empty_cardio_only_emits_predictor_metrics(monkeypatch):
    """A user with no cardio rows but a stubbed predictor still gets predictor
    metrics — but never fabricates zeros for the rolling-window metrics."""
    empty_db = FakeDB({"cardio_logs": [], "cardio_sessions": []})
    records = job.compute_snapshots_for_user(empty_db, USER, snapshot_date=TODAY)
    keys = {r.metric_key for r in records}
    # Rolling-window metrics absent (no data → no row, not 0.0).
    for k in ("cardio_weekly_distance_m", "cardio_longest_run_m",
              "cardio_fastest_mile_sec", "cardio_pace_avg_sec_per_km",
              "cardio_weather_temp_at_run_c"):
        assert k not in keys


def test_empty_everything_when_predictors_return_nothing(monkeypatch):
    """Hard skip — predictors AND cardio both empty ⇒ zero records."""
    monkeypatch.setattr(job.race_predictor_service, "predict_for_user",
                        lambda *_a, **_k: {})
    monkeypatch.setattr(job.training_load_service, "current_state",
                        lambda *_a, **_k: TrainingLoadState(
                            as_of=TODAY, daily_trimp=0.0, acute_load=0.0,
                            chronic_load=0.0, acwr=None, state="calibration",
                            interpretation="calibration", days_of_history=0,
                        ))
    empty_db = FakeDB({"cardio_logs": [], "cardio_sessions": []})
    records = job.compute_snapshots_for_user(empty_db, USER, snapshot_date=TODAY)
    assert records == []


# ---------------------------------------------------------------------------
# Idempotency + write path
# ---------------------------------------------------------------------------

def test_upsert_emits_correct_row_shape(cardio_db):
    records = job.compute_snapshots_for_user(cardio_db, USER, snapshot_date=TODAY)
    n = job.upsert_snapshots(cardio_db, records)
    assert n == len(records)
    written = cardio_db.client.upserts["cardio_metric_snapshots"][0]
    sample = written[0]
    assert sample["user_id"] == USER
    assert sample["snapshot_date"] == TODAY.isoformat()
    assert "metric_key" in sample and "value_numeric" in sample
    assert isinstance(sample["meta"], dict)


def test_run_for_user_idempotent(cardio_db):
    first = job.run_for_user(cardio_db, USER, snapshot_date=TODAY)
    second = job.run_for_user(cardio_db, USER, snapshot_date=TODAY)
    assert first["metric_keys"] == second["metric_keys"]
    assert first["wrote"] == second["wrote"]
    # Both writes hit the SAME (user, date, metric) triplets so production's
    # UNIQUE constraint dedups in-place.
    assert len(cardio_db.client.upserts["cardio_metric_snapshots"]) == 2
    a = sorted(cardio_db.client.upserts["cardio_metric_snapshots"][0],
               key=lambda r: r["metric_key"])
    b = sorted(cardio_db.client.upserts["cardio_metric_snapshots"][1],
               key=lambda r: r["metric_key"])
    assert a == b


def test_dry_run_does_not_write(cardio_db):
    summary = job.run_for_user(cardio_db, USER, snapshot_date=TODAY, dry_run=True)
    assert summary["wrote"] == 0
    assert "cardio_metric_snapshots" not in cardio_db.client.upserts
