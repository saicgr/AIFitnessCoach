"""Tests for cardio_digest_service.

Run: pytest backend/tests/test_cardio_digest_service.py -v --noconftest
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from typing import List, Dict, Any, Optional

import pytest

from services import cardio_digest_service as svc


# ────────────────────────────────────────────────────────────────────
# Fake Supabase client — chainable .table().select().eq().gte()... etc.
# ────────────────────────────────────────────────────────────────────

class _FakeQuery:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._rows = rows
        self._filters: List[tuple] = []

    def select(self, *_a, **_kw): return self
    def eq(self, k, v):
        self._filters.append(("eq", k, v))
        return self
    def gte(self, k, v):
        self._filters.append(("gte", k, v))
        return self
    def lte(self, k, v):
        self._filters.append(("lte", k, v))
        return self
    def lt(self, k, v):
        self._filters.append(("lt", k, v))
        return self
    def in_(self, k, v):
        self._filters.append(("in", k, v))
        return self
    def limit(self, _n): return self
    def execute(self):
        # Filter by lt/gte/lte on performed_at for history check accuracy.
        rows = self._rows
        for op, k, v in self._filters:
            if op == "gte" and k in ("performed_at", "created_at"):
                rows = [r for r in rows if (r.get(k) or "") >= v]
            elif op == "lte" and k in ("performed_at", "created_at"):
                rows = [r for r in rows if (r.get(k) or "") <= v]
            elif op == "lt" and k in ("performed_at", "created_at"):
                rows = [r for r in rows if (r.get(k) or "") < v]
        return SimpleNamespace(data=list(rows))


class _FakeClient:
    def __init__(self, tables: Dict[str, List[Dict[str, Any]]]):
        self._tables = tables
    def table(self, name: str):
        return _FakeQuery(self._tables.get(name, []))


def _make_db(cardio_logs: List[Dict[str, Any]], cardio_sessions: Optional[List[Dict[str, Any]]] = None):
    return SimpleNamespace(client=_FakeClient({
        "cardio_logs": cardio_logs,
        "cardio_sessions": cardio_sessions or [],
    }))


def _utc_iso(days_ago: float) -> str:
    return (datetime.now(timezone.utc) - timedelta(days=days_ago)).isoformat()


# ────────────────────────────────────────────────────────────────────
# compute_weekly_cardio_summary
# ────────────────────────────────────────────────────────────────────

def test_zero_cardio_returns_none():
    db = _make_db([])
    assert svc.compute_weekly_cardio_summary(db, "u1", "America/Chicago") is None


def test_basic_rollup_with_run_and_walk():
    logs = [
        # 5km run on day -2 (in window, pace 5:00/km)
        {"performed_at": _utc_iso(2), "activity_type": "run",
         "duration_seconds": 1500, "distance_m": 5000.0, "avg_pace_seconds_per_km": 300.0},
        # 3km walk on day -4
        {"performed_at": _utc_iso(4), "activity_type": "walk",
         "duration_seconds": 1800, "distance_m": 3000.0, "avg_pace_seconds_per_km": None},
        # Last week: 4km run on day -10
        {"performed_at": _utc_iso(10), "activity_type": "run",
         "duration_seconds": 1320, "distance_m": 4000.0, "avg_pace_seconds_per_km": 330.0},
        # Old history (35 days ago) — ensures is_first_week=False
        {"performed_at": _utc_iso(35), "activity_type": "run",
         "duration_seconds": 1500, "distance_m": 5000.0, "avg_pace_seconds_per_km": 300.0},
    ]
    db = _make_db(logs)
    s = svc.compute_weekly_cardio_summary(db, "u1", "America/Chicago")
    assert s is not None
    assert s.km_this_week == pytest.approx(8.0)
    assert s.km_last_week == pytest.approx(4.0)
    # delta = (8-4)/4 * 100 = 100%
    assert s.delta_pct == pytest.approx(100.0)
    assert s.longest_run_km == pytest.approx(5.0)
    assert s.fastest_mile_sec is not None
    # 300 sec/km × 1.609344 ≈ 482.8 sec/mile
    assert s.fastest_mile_sec == pytest.approx(300.0 * 1.609344, abs=0.5)
    assert s.session_count == 2
    assert s.is_first_week is False


def test_first_week_no_delta():
    logs = [
        {"performed_at": _utc_iso(1), "activity_type": "run",
         "duration_seconds": 1200, "distance_m": 3000.0, "avg_pace_seconds_per_km": 400.0},
    ]
    # No history older than 14 days → first week.
    db = _make_db(logs)
    s = svc.compute_weekly_cardio_summary(db, "u1", "America/Chicago")
    assert s is not None
    assert s.is_first_week is True
    assert s.delta_pct is None


def test_delta_none_when_last_week_zero_but_not_first_week():
    logs = [
        {"performed_at": _utc_iso(1), "activity_type": "run",
         "duration_seconds": 1200, "distance_m": 3000.0, "avg_pace_seconds_per_km": 400.0},
        # Old history so it's not a first-week user, but no log last week.
        {"performed_at": _utc_iso(40), "activity_type": "run",
         "duration_seconds": 1200, "distance_m": 3000.0, "avg_pace_seconds_per_km": 400.0},
    ]
    db = _make_db(logs)
    s = svc.compute_weekly_cardio_summary(db, "u1", "America/Chicago")
    assert s.is_first_week is False
    assert s.km_last_week == 0.0
    assert s.delta_pct is None


def test_yoga_excluded_from_cardio_rollup():
    logs = [
        {"performed_at": _utc_iso(1), "activity_type": "yoga",
         "duration_seconds": 3600, "distance_m": 0, "avg_pace_seconds_per_km": None},
    ]
    db = _make_db(logs)
    # All rows filtered out → no cardio → None
    assert svc.compute_weekly_cardio_summary(db, "u1", "UTC") is None


# ────────────────────────────────────────────────────────────────────
# format_digest_copy
# ────────────────────────────────────────────────────────────────────

def _summary(**overrides):
    base = dict(
        km_this_week=7.2, km_last_week=6.4, delta_pct=12.5,
        longest_run_km=4.1, longest_run_date=None,
        fastest_mile_sec=482.8, fastest_mile_date=None,
        total_hours=1.1, session_count=3, is_first_week=False,
    )
    base.update(overrides)
    return svc.WeeklyCardioSummary(**base)


def test_first_name_in_subject_and_body():
    s = _summary()
    copy = svc.format_digest_copy(s, user_first_name="Sai", user_email="sai@example.com")
    assert "Sai" in copy["email_subject"]
    assert "Sai" in copy["push_title"]
    assert "Sai" in copy["email_body_html"]


def test_email_prefix_fallback_when_no_first_name():
    s = _summary()
    copy = svc.format_digest_copy(s, user_first_name=None, user_email="johndoe42@x.com")
    assert "Johndoe" in copy["email_subject"]


def test_push_body_under_120_chars():
    s = _summary()
    for i in range(20):
        copy = svc.format_digest_copy(s, "Sai", variant_salt=f"salt-{i}")
        assert len(copy["push_body"]) <= 120, copy["push_body"]


def test_variant_pool_at_least_four_titles_seen():
    """Run 100 invocations across varying salts — confirm >=4 distinct titles."""
    s = _summary()
    titles = set()
    subjects = set()
    for i in range(100):
        copy = svc.format_digest_copy(s, "Sai", variant_salt=f"salt-{i}")
        titles.add(copy["push_title"])
        subjects.add(copy["email_subject"])
    assert len(titles) >= 4, f"only {len(titles)} title variants seen: {titles}"
    assert len(subjects) >= 4, f"only {len(subjects)} subject variants seen: {subjects}"


def test_negative_tone_used_when_delta_negative():
    s = _summary(delta_pct=-15.0)
    # Try many salts — every variant should come from the negative pool.
    for i in range(30):
        copy = svc.format_digest_copy(s, "Sai", variant_salt=f"s-{i}")
        title = copy["push_title"]
        is_neg_pool = any(
            tmpl.format(name="Sai") == title for tmpl in svc._PUSH_TITLE_NEGATIVE
        )
        assert is_neg_pool, f"non-negative title for negative delta: {title}"


def test_baseline_tone_for_first_week():
    s = _summary(is_first_week=True, delta_pct=None, km_last_week=0.0)
    for i in range(30):
        copy = svc.format_digest_copy(s, "Sai", variant_salt=f"s-{i}")
        title = copy["push_title"]
        is_baseline = any(
            tmpl.format(name="Sai") == title for tmpl in svc._PUSH_TITLE_BASELINE
        )
        assert is_baseline, f"non-baseline title for first-week: {title}"


def test_stable_variant_same_salt_same_output():
    s = _summary()
    a = svc.format_digest_copy(s, "Sai", variant_salt="stable-salt")
    b = svc.format_digest_copy(s, "Sai", variant_salt="stable-salt")
    assert a == b


# ────────────────────────────────────────────────────────────────────
# Vacation + quiet hours are enforced by the CRON callers, not the
# service. Verify the service is purely deterministic so the gating
# in email_cron / weekly_wrapped_cron stays the single source of
# truth (mirrors how _was_recently_sent gates all email jobs).
# ────────────────────────────────────────────────────────────────────

def test_service_has_no_side_effects():
    """Service must not touch notification or email infra directly."""
    src = open(svc.__file__).read()
    assert "notification_service" not in src
    assert "email_service" not in src
    assert "resend" not in src.lower()
