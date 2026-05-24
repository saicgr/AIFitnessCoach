"""
Tests for services/cardio_autotag_service.py

Run with:
    cd backend && .venv/bin/python -m pytest tests/test_cardio_autotag_service.py -v
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from unittest.mock import MagicMock

import pytest

from services.cardio_autotag_service import (
    compute_tags,
    update_tags,
    TAG_HILL,
    TAG_NEGATIVE_SPLIT,
    TAG_NEW_ROUTE,
    TAG_DAWN,
    TAG_DUSK,
    TAG_PR,
    HILL_MIN_ELEVATION_M,
    HILL_MAX_DISTANCE_M,
)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------
def _base_row(**overrides):
    row = {
        "id": "row-1",
        "user_id": "user-1",
        "performed_at": "2026-05-23T15:00:00+00:00",  # 15:00 UTC == 10:00 CST
        "activity_type": "run",
        "duration_seconds": 1800,
        "distance_m": 5000.0,
        "elevation_gain_m": 20.0,
        "splits_json": None,
        "gps_polyline": None,
    }
    row.update(overrides)
    return row


# ---------------------------------------------------------------------------
# Hill workout
# ---------------------------------------------------------------------------
def test_hill_workout_at_exact_boundary():
    """100m elevation + 10000m distance EXACTLY → hill."""
    row = _base_row(elevation_gain_m=HILL_MIN_ELEVATION_M, distance_m=HILL_MAX_DISTANCE_M)
    tags = compute_tags(None, row, [])
    assert TAG_HILL in tags


def test_hill_workout_below_elevation_threshold():
    row = _base_row(elevation_gain_m=99.9, distance_m=5000)
    tags = compute_tags(None, row, [])
    assert TAG_HILL not in tags


def test_hill_workout_above_distance_threshold():
    row = _base_row(elevation_gain_m=200, distance_m=10001)
    tags = compute_tags(None, row, [])
    assert TAG_HILL not in tags


def test_hill_workout_missing_elevation():
    row = _base_row(elevation_gain_m=None, distance_m=5000)
    tags = compute_tags(None, row, [])
    assert TAG_HILL not in tags


# ---------------------------------------------------------------------------
# Negative split
# ---------------------------------------------------------------------------
def test_negative_split_at_2_percent_boundary():
    """First half avg pace 300 s/km, second half exactly 2% faster (294)."""
    splits = [
        {"avg_pace_seconds_per_km": 300},
        {"avg_pace_seconds_per_km": 300},
        {"avg_pace_seconds_per_km": 294},
        {"avg_pace_seconds_per_km": 294},
    ]
    row = _base_row(splits_json=splits)
    tags = compute_tags(None, row, [])
    assert TAG_NEGATIVE_SPLIT in tags


def test_negative_split_just_below_threshold():
    splits = [
        {"avg_pace_seconds_per_km": 300},
        {"avg_pace_seconds_per_km": 300},
        {"avg_pace_seconds_per_km": 295},  # ~1.67% faster, below 2%
        {"avg_pace_seconds_per_km": 295},
    ]
    row = _base_row(splits_json=splits)
    tags = compute_tags(None, row, [])
    assert TAG_NEGATIVE_SPLIT not in tags


def test_negative_split_malformed_json_string():
    row = _base_row(splits_json="not-json-at-all")
    tags = compute_tags(None, row, [])
    assert TAG_NEGATIVE_SPLIT not in tags  # tolerant — returns False


def test_negative_split_missing_pace_fields_derives_from_dur_dist():
    splits = [
        {"duration_seconds": 600, "distance_m": 2000},  # 300 s/km
        {"duration_seconds": 600, "distance_m": 2000},
        {"duration_seconds": 580, "distance_m": 2000},  # 290 s/km, 3.3% faster
        {"duration_seconds": 580, "distance_m": 2000},
    ]
    row = _base_row(splits_json=splits)
    tags = compute_tags(None, row, [])
    assert TAG_NEGATIVE_SPLIT in tags


def test_negative_split_accepts_json_string_input():
    splits = [
        {"avg_pace_seconds_per_km": 300},
        {"avg_pace_seconds_per_km": 290},
    ]
    row = _base_row(splits_json=json.dumps(splits))
    tags = compute_tags(None, row, [])
    assert TAG_NEGATIVE_SPLIT in tags


# ---------------------------------------------------------------------------
# New route
# ---------------------------------------------------------------------------
def _polyline_for(coords):
    """Return a JSON-list polyline string (the service handles both encoded
    and JSON-list forms; JSON is easier to reason about in tests)."""
    return json.dumps([[lat, lon] for (lat, lon) in coords])


def test_new_route_with_empty_recent_logs():
    row = _base_row(gps_polyline=_polyline_for([(40.0, -74.0), (40.01, -74.01)]))
    tags = compute_tags(None, row, [])
    assert TAG_NEW_ROUTE in tags


def test_new_route_with_matching_polyline_returns_false():
    poly = _polyline_for([(40.0, -74.0), (40.01, -74.01)])
    row = _base_row(gps_polyline=poly, distance_m=5000)
    prior = _base_row(gps_polyline=poly, distance_m=5000, id="prior-1")
    tags = compute_tags(None, row, [prior])
    assert TAG_NEW_ROUTE not in tags


def test_new_route_endpoints_different_returns_true():
    row = _base_row(
        gps_polyline=_polyline_for([(40.0, -74.0), (40.01, -74.01)]),
        distance_m=5000,
    )
    prior = _base_row(
        gps_polyline=_polyline_for([(41.0, -75.0), (41.01, -75.01)]),
        distance_m=5000,
        id="prior-1",
    )
    tags = compute_tags(None, row, [prior])
    assert TAG_NEW_ROUTE in tags


def test_new_route_no_polyline_returns_false():
    row = _base_row(gps_polyline=None)
    tags = compute_tags(None, row, [])
    assert TAG_NEW_ROUTE not in tags


# ---------------------------------------------------------------------------
# Dawn / dusk in user-local time
# ---------------------------------------------------------------------------
@pytest.mark.parametrize("hour_local", [4, 5, 6, 7])
def test_dawn_run_in_window(hour_local):
    # 05:00 in America/Chicago (CDT, UTC-5 in summer 2026-05) == 10:00 UTC.
    # Build a UTC timestamp that lands on `hour_local` Chicago time.
    utc_hour = (hour_local + 5) % 24
    row = _base_row(performed_at=f"2026-05-23T{utc_hour:02d}:30:00+00:00")
    tags = compute_tags(None, row, [], user_timezone="America/Chicago")
    assert TAG_DAWN in tags
    assert TAG_DUSK not in tags


def test_dawn_run_excludes_8am():
    """8 AM is strictly outside the dawn window."""
    row = _base_row(performed_at="2026-05-23T13:00:00+00:00")  # 8 AM CDT
    tags = compute_tags(None, row, [], user_timezone="America/Chicago")
    assert TAG_DAWN not in tags


@pytest.mark.parametrize("hour_local", [19, 20, 21, 22])
def test_dusk_run_in_window(hour_local):
    utc_hour = (hour_local + 5) % 24
    row = _base_row(performed_at=f"2026-05-23T{utc_hour:02d}:30:00+00:00")
    tags = compute_tags(None, row, [], user_timezone="America/Chicago")
    assert TAG_DUSK in tags
    assert TAG_DAWN not in tags


def test_dusk_run_excludes_23():
    """23:00 is strictly outside the dusk window (exclusive upper bound)."""
    # 23:00 CDT == 04:00 UTC next day; just pick a UTC time that lands at 23 CDT.
    row = _base_row(performed_at="2026-05-24T04:00:00+00:00")
    tags = compute_tags(None, row, [], user_timezone="America/Chicago")
    assert TAG_DUSK not in tags


def test_neither_dawn_nor_dusk_midday():
    # 10:00 CDT
    row = _base_row(performed_at="2026-05-23T15:00:00+00:00")
    tags = compute_tags(None, row, [], user_timezone="America/Chicago")
    assert TAG_DAWN not in tags
    assert TAG_DUSK not in tags


# ---------------------------------------------------------------------------
# PR pass-through
# ---------------------------------------------------------------------------
def test_pr_session_preserved_from_existing_tags():
    """If an integrator (SLICE_CARDIO_PR) already set is_pr_session in the
    row's tags column, compute_tags should preserve it."""
    row = _base_row(tags=[TAG_PR])
    tags = compute_tags(None, row, [])
    assert TAG_PR in tags


# ---------------------------------------------------------------------------
# update_tags idempotency
# ---------------------------------------------------------------------------
def _build_db_mock_for_row(row, recent=None):
    """Stand up a fake Supabase client that returns `row` from cardio_logs and
    captures update calls so the test can inspect what got written."""
    db = MagicMock()
    captured = {"updates": []}

    def table(name):
        tbl_mock = MagicMock()

        def select(_cols):
            sel = MagicMock()

            def eq_id(_col, _val):
                eq_chain = MagicMock()
                def limit(_n):
                    lm = MagicMock()
                    lm.execute.return_value = MagicMock(data=[row] if name == "cardio_logs" else [])
                    return lm
                eq_chain.limit = limit
                # Recent-logs path: select → eq(user_id) → neq(id) → order → limit → execute
                eq_chain.neq = MagicMock(return_value=MagicMock(
                    order=MagicMock(return_value=MagicMock(
                        limit=MagicMock(return_value=MagicMock(
                            execute=MagicMock(return_value=MagicMock(data=recent or []))
                        ))
                    ))
                ))
                return eq_chain
            sel.eq = eq_id
            return sel

        def update(payload):
            up = MagicMock()
            def eq(_col, _val):
                ex = MagicMock()
                def execute():
                    captured["updates"].append(payload)
                    return MagicMock(data=[{"id": _val, **payload}])
                ex.execute = execute
                return ex
            up.eq = eq
            return up

        tbl_mock.select = select
        tbl_mock.update = update
        return tbl_mock

    db.client.table = table
    return db, captured


def test_update_tags_idempotent():
    row = _base_row(
        elevation_gain_m=150,
        distance_m=5000,
        performed_at="2026-05-23T10:30:00+00:00",  # 05:30 CDT — dawn
    )
    db, captured = _build_db_mock_for_row(row, recent=[])

    first = update_tags(db, row["id"])
    second = update_tags(db, row["id"])

    assert first == second
    assert TAG_HILL in first
    # Both runs persisted the SAME tag list — idempotent.
    assert captured["updates"][0] == captured["updates"][1]


def test_update_tags_raises_when_row_missing():
    db = MagicMock()
    # Both probes return empty.
    def table(_name):
        tbl = MagicMock()
        sel = MagicMock()
        eq = MagicMock()
        limit = MagicMock()
        limit.execute.return_value = MagicMock(data=[])
        eq.limit = MagicMock(return_value=limit)
        sel.eq = MagicMock(return_value=eq)
        tbl.select = MagicMock(return_value=sel)
        return tbl
    db.client.table = table
    with pytest.raises(ValueError):
        update_tags(db, "nonexistent-id")
