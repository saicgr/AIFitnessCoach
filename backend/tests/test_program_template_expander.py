"""Unit tests for services/program_template_expander.py.

Pure-logic coverage for the template -> `workouts` rows expander:
  - _parse_hhmm()             -- 'HH:MM' parse with noon fallback
  - _anchored_scheduled_date()-- date + time -> naive-local ISO datetime
  - _day_to_exercises_json()  -- per-day exercises_json build + deload scaling
  - expand_template()         -- caps, deload-week math, day_alignment

The DB layer (personal_records seeding + the psycopg2 transactional insert) is
mocked so every test is offline. No live DB, no Gemini.
"""
import os
import sys
import uuid
from datetime import date, time
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services import program_template_expander as expander  # noqa: E402
from services.program_template_expander import (  # noqa: E402
    _parse_hhmm,
    _anchored_scheduled_date,
    _day_to_exercises_json,
    expand_template,
    MAX_WEEKS,
    MAX_TOTAL_WORKOUTS,
)


# =============================================================================
# Module constants
# =============================================================================
def test_caps_are_consistent():
    """MAX_TOTAL_WORKOUTS is the 12-week * 7-day product (#41)."""
    assert MAX_WEEKS == 12
    assert MAX_TOTAL_WORKOUTS == 84
    assert MAX_TOTAL_WORKOUTS == MAX_WEEKS * 7


# =============================================================================
# _parse_hhmm — 'HH:MM' parsing, noon default
# =============================================================================
class TestParseHHMM:
    def test_valid_hhmm(self):
        assert _parse_hhmm("06:30") == time(6, 30)

    def test_valid_hour_only(self):
        """A bare hour with no minutes defaults the minute to 0."""
        assert _parse_hhmm("18") == time(18, 0)

    def test_midnight(self):
        assert _parse_hhmm("00:00") == time(0, 0)

    def test_late_evening(self):
        assert _parse_hhmm("23:45") == time(23, 45)

    def test_none_defaults_to_noon(self):
        assert _parse_hhmm(None) == time(12, 0)

    def test_empty_string_defaults_to_noon(self):
        assert _parse_hhmm("") == time(12, 0)

    def test_garbage_defaults_to_noon(self):
        assert _parse_hhmm("not-a-time") == time(12, 0)

    def test_out_of_range_defaults_to_noon(self):
        """time(25, 0) raises inside the parser -> caught -> noon."""
        assert _parse_hhmm("25:99") == time(12, 0)

    def test_non_numeric_parts_default_to_noon(self):
        assert _parse_hhmm("aa:bb") == time(12, 0)


# =============================================================================
# _anchored_scheduled_date — date + time -> naive-local ISO string
# =============================================================================
class TestAnchoredScheduledDate:
    def test_combines_date_and_time(self):
        iso = _anchored_scheduled_date(date(2026, 5, 21), time(6, 30))
        assert iso == "2026-05-21T06:30:00"

    def test_noon_default_anchoring(self):
        iso = _anchored_scheduled_date(date(2026, 1, 1), time(12, 0))
        assert iso == "2026-01-01T12:00:00"

    def test_no_utc_offset_in_output(self):
        """Stored naive (no +00:00) so the wall-clock survives DST/travel."""
        iso = _anchored_scheduled_date(date(2026, 7, 4), time(9, 15))
        assert "+" not in iso
        assert "Z" not in iso


# =============================================================================
# _day_to_exercises_json — per-day exercises_json build
# =============================================================================
class TestDayToExercisesJson:
    def _day(self):
        return {
            "day_index": 0,
            "day_name": "Upper A",
            "exercises": [
                {
                    "name": "Bench Press",
                    "exercise_id": "ex-1",
                    "sets": 4,
                    "reps": "8",
                    "reps_spec": {"kind": "fixed", "min": 8, "max": 8},
                    "rest_seconds": 90,
                    "target_weight_kg": 100.0,
                },
                {
                    "name": "Bicep Curl",
                    "exercise_id": "ex-2",
                    "sets": 3,
                    "reps": "12",
                    "rest_seconds": 60,
                },
            ],
        }

    def test_order_is_one_indexed(self):
        out = _day_to_exercises_json(self._day(), {}, is_deload=False)
        assert out[0]["order"] == 1
        assert out[1]["order"] == 2

    def test_authored_weight_kept_when_not_deload(self):
        out = _day_to_exercises_json(self._day(), {}, is_deload=False)
        assert out[0]["weight_kg"] == 100.0

    def test_deload_scales_weight_to_60_percent(self):
        out = _day_to_exercises_json(self._day(), {}, is_deload=True)
        # 100.0 * 0.6 = 60.0 on a scheduled deload week (#45).
        assert out[0]["weight_kg"] == 60.0

    def test_seed_weight_used_when_no_authored_weight(self):
        seeds = {"bicep curl": 20.0}
        out = _day_to_exercises_json(self._day(), seeds, is_deload=False)
        assert out[1]["weight_kg"] == 20.0

    def test_seed_weight_also_deload_scaled(self):
        seeds = {"bicep curl": 20.0}
        out = _day_to_exercises_json(self._day(), seeds, is_deload=True)
        assert out[1]["weight_kg"] == 12.0  # 20.0 * 0.6

    def test_no_weight_key_when_unknown(self):
        """An exercise with neither authored nor seeded weight omits weight_kg."""
        out = _day_to_exercises_json(self._day(), {}, is_deload=False)
        assert "weight_kg" not in out[1]

    def test_empty_day_yields_empty_list(self):
        out = _day_to_exercises_json({"exercises": []}, {}, is_deload=False)
        assert out == []

    def test_sets_and_reps_carried_through(self):
        out = _day_to_exercises_json(self._day(), {}, is_deload=False)
        assert out[0]["sets"] == 4
        assert out[0]["reps"] == "8"
        assert out[0]["rest_seconds"] == 90


# =============================================================================
# expand_template — caps + deload-week math + day_alignment
# =============================================================================
def _template(days=None, **overrides):
    """A minimal user_program_templates row for expander tests."""
    if days is None:
        days = [
            {
                "day_index": 0,
                "day_name": "Day 1",
                "is_rest": False,
                "workout_type": "strength",
                "difficulty": "medium",
                "exercises": [
                    {"name": "Squat", "sets": 5, "reps": "5",
                     "rest_seconds": 90},
                ],
            },
            {
                "day_index": 1,
                "day_name": "Rest",
                "is_rest": True,
                "exercises": [],
            },
            {
                "day_index": 2,
                "day_name": "Day 2",
                "is_rest": False,
                "workout_type": "strength",
                "difficulty": "medium",
                "exercises": [
                    {"name": "Deadlift", "sets": 3, "reps": "5",
                     "rest_seconds": 90},
                ],
            },
        ]
    base = {
        "id": "tmpl-1",
        "name": "Test Template",
        "week_length": 7,
        "deload_every_n_weeks": 4,
        "apply_staples": False,  # keep staple injection out of these tests
        "days": days,
    }
    base.update(overrides)
    return base


class _FakeCursor:
    """A psycopg2-cursor stand-in. Every INSERT ... RETURNING reports a new
    row (fetchone() truthy) so created==attempted."""

    def __init__(self):
        self.executed = []

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False

    def execute(self, sql, params=None):
        self.executed.append((sql, params))

    def fetchone(self):
        return ("new-row-id",)


class _FakeConn:
    def __init__(self):
        self.autocommit = True
        self.cursor_obj = _FakeCursor()
        self.committed = False
        self.rolled_back = False

    def cursor(self):
        return self.cursor_obj

    def commit(self):
        self.committed = True

    def rollback(self):
        self.rolled_back = True

    def close(self):
        pass


def _run_expand(template, **kwargs):
    """expand_template with DB seeding + psycopg2 connect mocked out.

    Returns (result_dict, fake_conn) so a test can inspect inserted rows.
    """
    fake_conn = _FakeConn()
    defaults = dict(
        schedule_id="sched-1",
        user_id="user-1",
        start_date=date(2026, 6, 1),  # a Monday
        weeks=1,
        day_alignment="start_today",
        day_times={},
    )
    defaults.update(kwargs)
    with patch.object(expander, "_seed_target_weights", return_value={}), \
         patch.object(expander.psycopg2, "connect", return_value=fake_conn), \
         patch.dict(os.environ, {"DATABASE_URL": "postgresql://x/y"}):
        result = expand_template(template=template, **defaults)
    return result, fake_conn


class TestExpandTemplateCaps:
    def test_weeks_zero_raises(self):
        with pytest.raises(ValueError, match="weeks must be >= 1"):
            _run_expand(_template(), weeks=0)

    def test_weeks_over_max_raises(self):
        with pytest.raises(ValueError, match=f"capped at {MAX_WEEKS}"):
            _run_expand(_template(), weeks=MAX_WEEKS + 1)

    def test_total_workout_cap_raises(self):
        """7 training days/week * 13 weeks would exceed the 84 cap.

        Weeks is also capped at 12, so to isolate the *total-workouts* cap we
        use many training days within the 12-week ceiling: 8 training days *
        12 weeks = 96 > 84.
        """
        many_days = [
            {
                "day_index": i,
                "day_name": f"Day {i}",
                "is_rest": False,
                "workout_type": "strength",
                "difficulty": "medium",
                "exercises": [{"name": "Squat", "sets": 3, "reps": "5"}],
            }
            for i in range(8)
        ]
        tmpl = _template(days=many_days, week_length=8)
        with pytest.raises(ValueError, match="cap is 84"):
            _run_expand(tmpl, weeks=12)

    def test_all_rest_template_raises(self):
        all_rest = [
            {"day_index": 0, "day_name": "Rest", "is_rest": True,
             "exercises": []},
        ]
        with pytest.raises(ValueError, match="no training days"):
            _run_expand(_template(days=all_rest))

    def test_weeks_at_max_is_allowed(self):
        """Exactly MAX_WEEKS with few training days stays under the cap."""
        result, _ = _run_expand(_template(), weeks=MAX_WEEKS)
        # 2 training days * 12 weeks = 24 rows, well under 84.
        assert result["total_attempted"] == 24


class TestExpandTemplateDeloadMath:
    def test_deload_weeks_identified(self):
        """deload_every=4 -> weeks 4 and 8 are deload over an 8-week run."""
        result, _ = _run_expand(_template(deload_every_n_weeks=4), weeks=8)
        assert result["deload_weeks"] == [4, 8]

    def test_no_deload_when_strategy_none(self):
        """deload_every_n_weeks=None -> never a deload week."""
        result, _ = _run_expand(
            _template(deload_every_n_weeks=None), weeks=8
        )
        assert result["deload_weeks"] == []

    def test_deload_every_3(self):
        result, _ = _run_expand(_template(deload_every_n_weeks=3), weeks=9)
        assert result["deload_weeks"] == [3, 6, 9]

    def test_first_week_is_not_deload(self):
        """Week 1 is never a deload (1 % N != 0 for any N > 1)."""
        result, _ = _run_expand(_template(deload_every_n_weeks=4), weeks=1)
        assert result["deload_weeks"] == []

    def test_deload_row_marks_intensity_mode(self):
        """The week-4 rows carry intensity_mode='deload' in the INSERT."""
        result, conn = _run_expand(
            _template(deload_every_n_weeks=4), weeks=4
        )
        # Find every inserted intensity_mode value across the executed params.
        modes = []
        for sql, params in conn.cursor_obj.executed:
            if params and "INSERT INTO workouts" in sql:
                # params is the ordered list of column values; the row dict
                # keys order is stable, so locate intensity_mode by re-deriving
                # from the SQL column list.
                col_sql = sql.split("(", 1)[1].split(")", 1)[0]
                cols = [c.strip() for c in col_sql.split(",")]
                idx = cols.index("intensity_mode")
                modes.append(params[idx])
        assert "deload" in modes
        assert "normal" in modes  # weeks 1-3 are normal


class TestExpandTemplateDayAlignment:
    def test_start_today_anchors_first_training_day_on_start_date(self):
        """'start_today': day_index 0 lands exactly on start_date."""
        start = date(2026, 6, 1)
        result, conn = _run_expand(
            _template(), start_date=start, weeks=1,
            day_alignment="start_today",
        )
        dates = _scheduled_dates(conn)
        # Day 0 -> start_date; Day 2 -> start_date + 2 days.
        assert dates[0].startswith("2026-06-01")
        assert dates[1].startswith("2026-06-03")

    def test_calendar_weekday_aligns_to_real_weekdays(self):
        """'calendar_weekday' on a 7-day week shifts each day_index to its
        matching weekday (0=Mon..6=Sun)."""
        # start_date 2026-06-03 is a Wednesday (weekday()==2).
        start = date(2026, 6, 3)
        result, conn = _run_expand(
            _template(), start_date=start, weeks=1,
            day_alignment="calendar_weekday",
        )
        dates = sorted(_scheduled_dates(conn))
        # day_index 0 (Mon): lead=(0-2)%7=5 -> 2026-06-08 (next Monday).
        # day_index 2 (Wed): lead=(2-2)%7=0 -> 2026-06-03 (start day).
        assert any(d.startswith("2026-06-03") for d in dates)
        assert any(d.startswith("2026-06-08") for d in dates)

    def test_day_times_anchor_wall_clock(self):
        """day_times maps day_index -> 'HH:MM'; missing days default to noon."""
        result, conn = _run_expand(
            _template(), start_date=date(2026, 6, 1), weeks=1,
            day_times={"0": "07:00"},  # day 0 at 7am, day 2 unspecified
        )
        dates = _scheduled_dates(conn)
        assert "T07:00:00" in dates[0]   # explicit time honored
        assert "T12:00:00" in dates[1]   # missing -> noon default

    def test_second_week_offsets_by_week_length(self):
        """Week 2 day 0 is week_length(7) days after week 1 day 0."""
        result, conn = _run_expand(
            _template(), start_date=date(2026, 6, 1), weeks=2,
            day_alignment="start_today",
        )
        dates = sorted(_scheduled_dates(conn))
        # Week 1: 06-01, 06-03. Week 2: 06-08, 06-10.
        assert any(d.startswith("2026-06-08") for d in dates)
        assert any(d.startswith("2026-06-10") for d in dates)


def _scheduled_dates(fake_conn):
    """Pull the scheduled_date value out of every workouts INSERT."""
    out = []
    for sql, params in fake_conn.cursor_obj.executed:
        if params and "INSERT INTO workouts" in sql:
            col_sql = sql.split("(", 1)[1].split(")", 1)[0]
            cols = [c.strip() for c in col_sql.split(",")]
            idx = cols.index("scheduled_date")
            out.append(params[idx])
    return out


class TestExpandTemplateResultShape:
    def test_result_keys(self):
        result, _ = _run_expand(_template(), weeks=2)
        assert set(result) == {
            "workouts_created", "skipped_existing", "total_attempted",
            "deload_weeks", "schedule_id",
        }

    def test_rest_days_produce_no_rows(self):
        """The template has 1 rest day; only the 2 training days expand."""
        result, _ = _run_expand(_template(), weeks=1)
        assert result["total_attempted"] == 2  # not 3

    def test_created_count_when_all_new(self):
        """Fake cursor reports every row new -> created==attempted, skipped 0."""
        result, _ = _run_expand(_template(), weeks=3)
        assert result["workouts_created"] == 6   # 2 training days * 3 weeks
        assert result["skipped_existing"] == 0

    def test_transaction_committed(self):
        result, conn = _run_expand(_template(), weeks=1)
        assert conn.committed is True
        assert conn.rolled_back is False

    def test_schedule_id_echoed(self):
        result, _ = _run_expand(_template(), schedule_id="sched-xyz")
        assert result["schedule_id"] == "sched-xyz"
