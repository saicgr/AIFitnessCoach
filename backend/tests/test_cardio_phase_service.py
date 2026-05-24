"""
Unit tests for `services.cardio_phase_service`.

Run:
    cd backend && .venv/bin/python -m pytest tests/test_cardio_phase_service.py -v --noconftest

Tests stub the Supabase client (no DB) and monkeypatch `predict_for_user` so
the gating / phase-refinement / calibration paths are exercised directly.
"""
from __future__ import annotations

import os
import sys
from datetime import date

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services import cardio_phase_service as svc  # noqa: E402

TODAY = date(2026, 5, 22)


# ---------------------------------------------------------------------------
# Stub Supabase client — minimal surface used by the service.
# ---------------------------------------------------------------------------
class _StubExec:
    def __init__(self, rows):
        self.data = list(rows) if rows is not None else None


class _StubQuery:
    """Captures a `.select(...).eq(...).execute()` (or `.maybe_single()`)
    chain and returns whatever rows the parent table was seeded with."""

    def __init__(self, rows):
        self._rows = rows
        self._single = False

    def select(self, *_a, **_kw):
        return self

    def eq(self, *_a, **_kw):
        return self

    def maybe_single(self):
        self._single = True
        return self

    def execute(self):
        if self._single:
            single = self._rows[0] if self._rows else None
            class _R:
                data = single
            return _R()
        return _StubExec(self._rows)


class StubClient:
    """tables = {table_name: list[dict]} — first row wins for one-row tables."""

    def __init__(self, tables):
        self._tables = tables

    def table(self, name):
        return _StubQuery(self._tables.get(name, []))


def _stub(*, opted_in=True, profile=None):
    """Build a StubClient with a one-row users table and a hormonal_profiles
    table. Pass profile=None for "no profile row"."""
    users = [{"cycle_aware_reminders": opted_in}] if opted_in is not None else []
    profiles = [profile] if profile else []
    return StubClient({"users": users, "hormonal_profiles": profiles})


# ---------------------------------------------------------------------------
# Gates — service must return None and never call the predictor.
# ---------------------------------------------------------------------------
def _explode(*_a, **_kw):  # predictor should NEVER run on a gated path
    raise AssertionError("predict_for_user was called on a gated path")


def test_cycle_disabled_returns_none(monkeypatch):
    monkeypatch.setattr(svc, "predict_for_user", _explode)
    client = _stub(opted_in=False, profile={"menstrual_tracking_enabled": True})
    assert svc.get_phase_recommendation(client, "u1", TODAY) is None


def test_no_profile_returns_none(monkeypatch):
    monkeypatch.setattr(svc, "predict_for_user", _explode)
    client = _stub(opted_in=True, profile=None)
    assert svc.get_phase_recommendation(client, "u1", TODAY) is None


def test_tracking_disabled_returns_none(monkeypatch):
    monkeypatch.setattr(svc, "predict_for_user", _explode)
    client = _stub(opted_in=True, profile={"menstrual_tracking_enabled": False})
    assert svc.get_phase_recommendation(client, "u1", TODAY) is None


def test_pregnancy_returns_none(monkeypatch):
    monkeypatch.setattr(svc, "predict_for_user", _explode)
    client = _stub(
        opted_in=True,
        profile={"menstrual_tracking_enabled": True, "tracking_mode": "pregnancy"},
    )
    assert svc.get_phase_recommendation(client, "u1", TODAY) is None


def test_post_menopause_returns_none(monkeypatch):
    monkeypatch.setattr(svc, "predict_for_user", _explode)
    client = _stub(
        opted_in=True,
        profile={"menstrual_tracking_enabled": True, "menopause_status": "post"},
    )
    assert svc.get_phase_recommendation(client, "u1", TODAY) is None


def test_hormonal_contraceptive_returns_none(monkeypatch):
    monkeypatch.setattr(svc, "predict_for_user", _explode)
    client = _stub(
        opted_in=True,
        profile={
            "menstrual_tracking_enabled": True,
            "hormonal_contraceptive": True,
        },
    )
    assert svc.get_phase_recommendation(client, "u1", TODAY) is None


# ---------------------------------------------------------------------------
# Calibration short-circuit
# ---------------------------------------------------------------------------
def test_calibration_short_circuit(monkeypatch):
    """First cycle: predictions_available=True but cycles_tracked=0 + low conf."""
    def fake_predict(_c, _u, _t):
        return {
            "predictions_available": True,
            "current_phase": "follicular",
            "current_cycle_day": 9,
            "confidence": "low",
            "days_until_next_period": 19,
            "stats": {"cycles_tracked": 0, "avg_cycle_length": None},
        }

    monkeypatch.setattr(svc, "predict_for_user", fake_predict)
    client = _stub(opted_in=True, profile={"menstrual_tracking_enabled": True})
    rec = svc.get_phase_recommendation(client, "u1", TODAY)
    assert rec is not None
    assert rec.phase == "tracking calibration"
    assert rec.recommended_intensity is None
    assert "more logged cycles" in rec.rationale
    assert rec.evidence_citation == svc.EVIDENCE_CITATION


def test_no_predictions_returns_calibration(monkeypatch):
    """Predictor says nothing available (no history) → calibration card too."""
    monkeypatch.setattr(
        svc, "predict_for_user",
        lambda *a, **k: {"predictions_available": False, "stats": {}, "current_phase": None},
    )
    client = _stub(opted_in=True, profile={"menstrual_tracking_enabled": True})
    rec = svc.get_phase_recommendation(client, "u1", TODAY)
    assert rec is not None
    assert rec.phase == "tracking calibration"
    assert rec.recommended_intensity is None


# ---------------------------------------------------------------------------
# Phase → intensity mapping
# ---------------------------------------------------------------------------
def _eligible_client():
    return _stub(opted_in=True, profile={"menstrual_tracking_enabled": True})


def _ok_prediction(phase, *, days_until_next_period=None, cycle_day=10):
    return {
        "predictions_available": True,
        "current_phase": phase,
        "current_cycle_day": cycle_day,
        "confidence": "high",
        "days_until_next_period": days_until_next_period,
        "stats": {"cycles_tracked": 6, "avg_cycle_length": 28.0},
    }


@pytest.mark.parametrize(
    "phase,days_until,expected_phase,expected_intensity",
    [
        ("menstrual",  20, "menstrual",     "low"),
        ("follicular", 17, "follicular",    "high"),
        ("ovulation",  14, "ovulation",     "high"),
        ("luteal",     10, "early_luteal",  "moderate"),  # >5d to next period
        ("luteal",      3, "late_luteal",   "low"),       # ≤5d → recovery
        ("luteal",      5, "late_luteal",   "low"),       # boundary at 5
    ],
)
def test_phase_maps_to_intensity(monkeypatch, phase, days_until, expected_phase, expected_intensity):
    monkeypatch.setattr(
        svc, "predict_for_user",
        lambda *a, **k: _ok_prediction(phase, days_until_next_period=days_until),
    )
    rec = svc.get_phase_recommendation(_eligible_client(), "u1", TODAY)
    assert rec is not None
    assert rec.phase == expected_phase
    assert rec.recommended_intensity == expected_intensity
    assert rec.rationale  # non-empty copy
    assert rec.evidence_citation == svc.EVIDENCE_CITATION


def test_refine_phase_non_luteal_passthrough():
    assert svc.refine_phase({"current_phase": "menstrual"}) == "menstrual"
    assert svc.refine_phase({"current_phase": "ovulation"}) == "ovulation"


def test_refine_phase_luteal_unknown_days_defaults_to_early():
    """If predictor omits days_until_next_period, default to early_luteal so
    we don't over-aggressively recommend recovery."""
    assert svc.refine_phase(
        {"current_phase": "luteal", "days_until_next_period": None}
    ) == "early_luteal"


# ---------------------------------------------------------------------------
# Defensive: predictor returns nonsense → service returns None (no banner).
# ---------------------------------------------------------------------------
def test_unrecognized_phase_returns_none(monkeypatch):
    monkeypatch.setattr(
        svc, "predict_for_user",
        lambda *a, **k: _ok_prediction("perimenopausal_chaos"),
    )
    assert svc.get_phase_recommendation(_eligible_client(), "u1", TODAY) is None


def test_predictor_raises_returns_none(monkeypatch):
    def boom(*a, **k):
        raise RuntimeError("supabase 503")

    monkeypatch.setattr(svc, "predict_for_user", boom)
    assert svc.get_phase_recommendation(_eligible_client(), "u1", TODAY) is None


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))
