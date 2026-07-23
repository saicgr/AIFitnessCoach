"""Regression tests for the local-day window chokepoint.

The bug these exist to prevent (2026-07-22, confirmed in production): a coach
card told a user "you have logged 3630 calories so far" on a day they had eaten
786. The window had been built by string-concatenating the user's LOCAL calendar
date with a UTC offset — ``f"{local_date}T00:00:00+00:00"`` /
``f"{local_date}T23:59:59+00:00"`` — and applied to ``food_logs.logged_at``,
a UTC ``timestamptz``. For a UTC-4 user that window actually spans local
20:00 YESTERDAY → 19:59 TODAY, so five of the previous evening's dinner logs
(2,844 kcal) were counted as "today".

``test_production_row_regression`` replays the six real rows and asserts both
halves: the correct window yields 786, and the naive one yields 3630.
"""

from datetime import datetime

import pytest

from core.timezone_utils import (
    local_day_bounds,
    local_range_bounds,
    utc_to_local_date,
)

NY = "America/New_York"


# ── local_day_bounds ────────────────────────────────────────────────────


def test_local_day_bounds_new_york():
    assert local_day_bounds("2026-07-22", NY) == (
        "2026-07-22T04:00:00+00:00",
        "2026-07-23T04:00:00+00:00",
    )


def test_local_day_bounds_positive_offset_zone():
    # Asia/Kolkata is UTC+5:30 — the local day STARTS on the previous UTC date.
    assert local_day_bounds("2026-07-22", "Asia/Kolkata") == (
        "2026-07-21T18:30:00+00:00",
        "2026-07-22T18:30:00+00:00",
    )


def test_local_day_bounds_utc_is_identity():
    assert local_day_bounds("2026-07-22", "UTC") == (
        "2026-07-22T00:00:00+00:00",
        "2026-07-23T00:00:00+00:00",
    )


def _span_hours(bounds):
    start, end = bounds
    return (datetime.fromisoformat(end) - datetime.fromisoformat(start)).total_seconds() / 3600


def test_dst_spring_forward_day_is_23_hours():
    # 2026-03-08 America/New_York: clocks jump 02:00 -> 03:00, so the local day
    # is 23h long. A hardcoded +24h window would over-collect by an hour.
    assert _span_hours(local_day_bounds("2026-03-08", NY)) == 23
    assert local_day_bounds("2026-03-08", NY) == (
        "2026-03-08T05:00:00+00:00",
        "2026-03-09T04:00:00+00:00",
    )


def test_dst_fall_back_day_is_25_hours():
    # 2026-11-01 America/New_York: 02:00 repeats, so the local day is 25h long.
    assert _span_hours(local_day_bounds("2026-11-01", NY)) == 25
    assert local_day_bounds("2026-11-01", NY) == (
        "2026-11-01T04:00:00+00:00",
        "2026-11-02T05:00:00+00:00",
    )


def test_consecutive_days_tile_without_gap_or_overlap():
    # Half-open windows must abut exactly: no row can land in both days, and
    # no row can fall between them.
    _, end_21 = local_day_bounds("2026-07-21", NY)
    start_22, _ = local_day_bounds("2026-07-22", NY)
    assert end_21 == start_22


# ── local_range_bounds ──────────────────────────────────────────────────


def test_local_range_bounds_end_date_is_an_inclusive_calendar_day():
    start, end = local_range_bounds("2026-07-20", "2026-07-22", NY)
    assert start == local_day_bounds("2026-07-20", NY)[0]
    # end is local midnight AFTER 2026-07-22, so everything logged on the 22nd
    # is inside the half-open window.
    assert end == local_day_bounds("2026-07-22", NY)[1] == "2026-07-23T04:00:00+00:00"


def test_local_range_bounds_single_day_matches_local_day_bounds():
    assert local_range_bounds("2026-07-22", "2026-07-22", NY) == local_day_bounds("2026-07-22", NY)


# ── utc_to_local_date ───────────────────────────────────────────────────


def test_utc_to_local_date_buckets_the_exact_row_that_caused_the_bug():
    # 00:56 UTC is 20:56 the PREVIOUS evening in New York. `str(x)[:10]` would
    # have said "2026-07-22" and rolled this dinner onto the wrong day.
    assert utc_to_local_date("2026-07-22T00:56:35+00:00", NY) == "2026-07-21"


def test_utc_to_local_date_handles_z_suffix_and_datetimes():
    assert utc_to_local_date("2026-07-22T00:56:35Z", NY) == "2026-07-21"
    assert utc_to_local_date(datetime.fromisoformat("2026-07-22T16:39:22+00:00"), NY) == "2026-07-22"


def test_utc_to_local_date_positive_offset_rolls_forward():
    # 22:00 UTC is already tomorrow in Kolkata (UTC+5:30).
    assert utc_to_local_date("2026-07-22T22:00:00+00:00", "Asia/Kolkata") == "2026-07-23"


@pytest.mark.parametrize("bad", [None, "", "not-a-timestamp"])
def test_utc_to_local_date_returns_empty_on_unparseable(bad):
    assert utc_to_local_date(bad, NY) == ""


# ── the regression that matters ─────────────────────────────────────────

# The six real production food_logs rows behind the "3630 calories" card.
# Five are the previous evening's dinners (local 2026-07-21 20:56–22:47 NY,
# 2,844 kcal / 8 g protein); one is the actual day's single meal
# (local 2026-07-22 12:39 NY, 786 kcal / 83 g protein).
PRODUCTION_FOOD_LOGS = [
    {"logged_at": "2026-07-22T00:56:35+00:00", "total_calories": 720, "protein_g": 2},
    {"logged_at": "2026-07-22T01:12:03+00:00", "total_calories": 640, "protein_g": 2},
    {"logged_at": "2026-07-22T01:40:18+00:00", "total_calories": 580, "protein_g": 2},
    {"logged_at": "2026-07-22T02:10:47+00:00", "total_calories": 512, "protein_g": 1},
    {"logged_at": "2026-07-22T02:47:09+00:00", "total_calories": 392, "protein_g": 1},
    {"logged_at": "2026-07-22T16:39:22+00:00", "total_calories": 786, "protein_g": 83},
]


def _totals(rows):
    return (
        sum(r["total_calories"] for r in rows),
        sum(r["protein_g"] for r in rows),
    )


def _filter_half_open(rows, start_iso, end_iso):
    """In-memory stand-in for `.gte(start).lt(end)` — no DB, no network."""
    start = datetime.fromisoformat(start_iso)
    end = datetime.fromisoformat(end_iso)
    return [r for r in rows if start <= datetime.fromisoformat(r["logged_at"]) < end]


def _filter_closed(rows, start_iso, end_iso):
    """In-memory stand-in for the old `.gte(start).lte(end)`."""
    start = datetime.fromisoformat(start_iso)
    end = datetime.fromisoformat(end_iso)
    return [r for r in rows if start <= datetime.fromisoformat(r["logged_at"]) <= end]


def test_production_row_regression_local_day_bounds_is_correct():
    start, end = local_day_bounds("2026-07-22", NY)
    kept = _filter_half_open(PRODUCTION_FOOD_LOGS, start, end)
    assert len(kept) == 1
    assert _totals(kept) == (786, 83)


def test_production_row_regression_naive_utc_window_reproduces_3630():
    # This is EXACTLY the code that shipped the bug. Kept as executable
    # documentation: if someone "simplifies" local_day_bounds back to this
    # form, the test above starts reporting 3630 too.
    naive_start = "2026-07-22T00:00:00+00:00"
    naive_end = "2026-07-22T23:59:59+00:00"
    kept = _filter_closed(PRODUCTION_FOOD_LOGS, naive_start, naive_end)
    assert len(kept) == 6
    assert _totals(kept) == (3630, 91)  # 2844 + 786 kcal — the number on the card


def test_production_rows_bucket_to_the_right_local_days():
    buckets = [utc_to_local_date(r["logged_at"], NY) for r in PRODUCTION_FOOD_LOGS]
    assert buckets == ["2026-07-21"] * 5 + ["2026-07-22"]
    # The naive `str(x)[:10]` bucketing everyone used instead:
    naive = [str(r["logged_at"])[:10] for r in PRODUCTION_FOOD_LOGS]
    assert naive == ["2026-07-22"] * 6  # every dinner attributed to the wrong day


def test_previous_local_day_window_keeps_the_five_dinners():
    start, end = local_day_bounds("2026-07-21", NY)
    kept = _filter_half_open(PRODUCTION_FOOD_LOGS, start, end)
    assert len(kept) == 5
    assert _totals(kept) == (2844, 8)


# ── workouts.scheduled_date NOON-anchor invariant ───────────────────────────
# Canonical: scheduled_date is stored at NOON of the day (noon-local via
# target_date_to_utc_iso, or noon-UTC when a writer lacks tz). The invariant a
# NOON anchor must satisfy: it lands inside its own local-day window in EVERY
# realistic timezone, so a day-window read never mis-days the workout — while a
# MIDNIGHT anchor (the old bug) falls into the neighbouring day for offset users.

_ANCHOR_ZONES = ["UTC", NY, "America/Chicago", "America/Los_Angeles",
                 "Asia/Kolkata", "Asia/Tokyo", "Europe/London", "Australia/Sydney"]


def _iso_to_epoch(iso):
    return datetime.fromisoformat(iso).timestamp()


def _in_window(ts_iso, start_iso, end_iso):
    return _iso_to_epoch(start_iso) <= _iso_to_epoch(ts_iso) < _iso_to_epoch(end_iso)


@pytest.mark.parametrize("tz", _ANCHOR_ZONES)
def test_noon_utc_anchor_is_captured_by_every_local_day_window(tz):
    # A noon-UTC row (writer had no tz) must be read on its own calendar day.
    noon_utc = "2026-07-22T12:00:00+00:00"
    start, end = local_day_bounds("2026-07-22", tz)
    assert _in_window(noon_utc, start, end), f"noon-UTC missed in {tz}"


@pytest.mark.parametrize("tz", _ANCHOR_ZONES)
def test_noon_local_anchor_is_captured_by_its_own_local_day_window(tz):
    from core.timezone_utils import target_date_to_utc_iso
    noon_local = target_date_to_utc_iso("2026-07-22", tz)
    start, end = local_day_bounds("2026-07-22", tz)
    assert _in_window(noon_local, start, end), f"noon-local missed in {tz}"


def test_midnight_utc_anchor_is_the_bug_a_west_user_window_misses_it():
    # Documents WHY midnight is wrong (and why the backfill shifted 00:00->12:00):
    # a west-of-UTC user's local day starts AFTER 00:00Z, so a midnight-UTC row
    # falls into the PREVIOUS local day and vanishes from "today".
    midnight_utc = "2026-07-22T00:00:00+00:00"
    start, end = local_day_bounds("2026-07-22", "America/Los_Angeles")
    assert not _in_window(midnight_utc, start, end)
    # ...and re-anchoring it to noon on the same date fixes it:
    noon_utc = "2026-07-22T12:00:00+00:00"
    assert _in_window(noon_utc, start, end)
