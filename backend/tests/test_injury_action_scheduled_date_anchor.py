"""
E2E register #7 (residual sibling writer) — the injury_action() start_rehab
branch (api/v1/coach/daily_insight.py) wrote workouts.scheduled_date as a
bare `datetime.now(timezone.utc).date().isoformat()`. That is the server's
UTC calendar date with no regard for the user's own timezone; Postgres casts
a bare date to MIDNIGHT UTC, which is 7pm the PREVIOUS local day for a US
user (see api/v1/workouts/scheduled_date_anchor.py's module docstring). Now
routed through anchor_today(tz).

Pure unit test — no DB needed.

Run with: pytest tests/test_injury_action_scheduled_date_anchor.py -v
"""

from datetime import datetime, timezone

from api.v1.workouts.scheduled_date_anchor import anchor_today, scheduled_local_date


def test_old_expression_is_the_wrong_local_day_late_in_the_utc_day():
    """Reproduces the exact failure mode: 03:00 UTC on 2026-07-31 is still
    22:00 (10pm) on 2026-07-30 for a US Central user -- but the OLD
    expression reads the SERVER's UTC calendar date, which has already
    rolled to the 31st."""
    fixed_utc_instant = datetime(2026, 7, 31, 3, 0, tzinfo=timezone.utc)
    user_local_today = "2026-07-30"

    old_value = fixed_utc_instant.date().isoformat()  # the OLD expression's shape

    assert old_value != user_local_today, (
        "the bug: writing the server's UTC calendar date instead of the "
        "user's own local day"
    )
    # The deeper structural defect: a bare 10-char date carries no timezone
    # anchor at all, so Postgres casting it to timestamptz always lands at
    # midnight UTC -- 7pm the previous local day for any US timezone.
    assert len(old_value) == 10 and "T" not in old_value


def test_anchor_today_resolves_to_a_real_anchored_timestamp():
    tz = "America/Chicago"
    value = anchor_today(tz)
    # Must be a real instant (has time + offset), not a bare date.
    assert "T" in value
    # And it must resolve back to a real local calendar day via the
    # project's own read-side companion.
    local_day = scheduled_local_date(value, tz)
    assert local_day is not None and len(local_day) == 10


def test_anchor_today_is_idempotent_across_two_calls_same_local_day():
    tz = "America/Chicago"
    a = anchor_today(tz)
    b = anchor_today(tz)
    # Both calls happen within the same test run (same local day) -- the
    # noon anchor must be stable, not drift with wall-clock seconds.
    assert scheduled_local_date(a, tz) == scheduled_local_date(b, tz)
