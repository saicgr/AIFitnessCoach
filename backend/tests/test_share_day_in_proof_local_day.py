"""Regression gate for UI_E2E 2026-08-05 row 61 (HIGH).

"Day in Proof" refused to open at 21:56 local ("Log a workout and a meal
today to unlock Day in Proof") on a day the QA account (America/Chicago) had
logged both — a textbook local-day-window defect (CLAUDE.md's documented
class): `date_iso = date or datetime.now(timezone.utc).date().isoformat()`
plus a bare UTC-midnight `_day_bounds` meant any evening local time already
reads as "tomorrow" in UTC, and even an EXPLICIT date was queried against a
UTC-midnight window instead of the user's local day.

Fixed by threading a REQUIRED `timezone_str` through every day-window
function in services/share_data_service.py (`_day_bounds`, `_top_pr_for_day`,
`_meal_grade_for_day`, `_top_workout_for_day`, `day_in_proof`, `on_this_day`)
via the chokepoint `core.timezone_utils.local_day_bounds`, and resolving the
caller's timezone (`resolve_timezone`) + local "today" (`get_user_today`) in
both api/v1/share_ai.py (`/share/day-in-proof`, `/share/insight-line`) and
api/v1/share_growth.py (`/share/on-this-day`) instead of a bare UTC default.
"""
import inspect

import pytest

from core.timezone_utils import local_day_bounds
from services import share_data_service


# ---------------------------------------------------------------------------
# 1. `_day_bounds` no longer hardcodes UTC — it delegates to the chokepoint
#    and produces a DIFFERENT window for a non-UTC timezone.
# ---------------------------------------------------------------------------

def test_day_bounds_delegates_to_local_day_bounds_chokepoint():
    start, end = share_data_service._day_bounds("2026-08-05", "America/Chicago")
    assert (start, end) == local_day_bounds("2026-08-05", "America/Chicago")


def test_day_bounds_differs_from_bare_utc_midnight_for_a_non_utc_user():
    """This is the exact defect: a bare-UTC window and the correct
    America/Chicago window for the SAME calendar date must NOT coincide —
    if they do, the fix has regressed back to UTC-blind."""
    tz_start, tz_end = share_data_service._day_bounds("2026-08-05", "America/Chicago")
    utc_start, utc_end = share_data_service._day_bounds("2026-08-05", "UTC")
    assert tz_start != utc_start
    assert tz_end != utc_end
    # America/Chicago (UTC-5 in August, CDT) local midnight is 05:00 UTC —
    # the window opens 5 hours LATER than a bare-UTC window for the same date.
    assert tz_start == "2026-08-05T05:00:00+00:00"
    assert tz_end == "2026-08-06T05:00:00+00:00"


def test_day_bounds_requires_a_timezone_argument():
    """No default — a caller that forgets to resolve+pass a real tz gets a
    TypeError at call time, not a silent UTC fallback (CLAUDE.md: pass 'UTC'
    only where genuinely global, never as an implicit default)."""
    sig = inspect.signature(share_data_service._day_bounds)
    assert "timezone_str" in sig.parameters
    assert sig.parameters["timezone_str"].default is inspect.Parameter.empty


# ---------------------------------------------------------------------------
# 2. Every day-window function threads timezone_str (no bare UTC default).
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("fn_name", [
    "_top_pr_for_day",
    "_meal_grade_for_day",
    "_top_workout_for_day",
    "day_in_proof",
    "on_this_day",
])
def test_day_window_functions_require_timezone_str(fn_name):
    fn = getattr(share_data_service, fn_name)
    sig = inspect.signature(fn)
    assert "timezone_str" in sig.parameters, f"{fn_name} must accept timezone_str"
    assert sig.parameters["timezone_str"].default is inspect.Parameter.empty, (
        f"{fn_name}'s timezone_str must be required, not defaulted to UTC"
    )


# ---------------------------------------------------------------------------
# 3. The API layer resolves the caller's timezone instead of defaulting to
#    UTC "today" — source-inspection (mirrors this repo's established
#    pattern for chokepoint chekcs, e.g. test_workout_completion_and_dedup).
# ---------------------------------------------------------------------------

def test_day_in_proof_endpoint_resolves_user_timezone():
    import api.v1.share_ai as share_ai

    src = inspect.getsource(share_ai.day_in_proof)
    assert "datetime.now(timezone.utc).date()" not in src, (
        "day-in-proof must not default to UTC 'today' — that reads as "
        "tomorrow for hours every evening for any user west of UTC"
    )
    assert "resolve_timezone" in src and "get_user_today" in src


def test_on_this_day_endpoint_resolves_user_timezone():
    import api.v1.share_growth as share_growth

    src = inspect.getsource(share_growth.on_this_day)
    assert "datetime.now(timezone.utc).date()" not in src
    assert "resolve_timezone" in src and "get_user_today" in src


# ---------------------------------------------------------------------------
# 4. Live behavioral check against the QA account: the exact reported
#    scenario (has_data True for the local day the account actually logged
#    on, regardless of what UTC "today" currently is).
# ---------------------------------------------------------------------------

def _has_live_db_creds() -> bool:
    import os
    return bool(os.environ.get("SUPABASE_URL") and (
        os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_KEY")
    ))


@pytest.mark.skipif(not _has_live_db_creds(), reason="No SUPABASE_URL/KEY in env")
def test_day_in_proof_has_data_true_for_the_qa_accounts_logged_local_day():
    """Verified live: workout c1d5c7e5 (completed 2026-08-05T06:08:59Z) + a
    food log both land in the QA account's 2026-08-05 America/Chicago local
    day. Before the fix, GET .../day-in-proof?date=2026-08-05 queried a
    bare UTC-midnight window that still caught this data by luck for a
    UTC-05 offset within a few specific hours, but the UNDATED default
    (relying on UTC "today") returned has_data=False once UTC had already
    rolled past midnight while the user's evening was still 2026-08-05."""
    from fastapi.testclient import TestClient
    from main import app
    from core.auth import get_current_user

    uid = "1aa02a24-0224-4a5a-b1e5-3f24dcd60bdc"

    async def _current_user():
        return {"id": uid}

    app.dependency_overrides[get_current_user] = _current_user
    try:
        client = TestClient(app)
        r = client.get(f"/api/v1/share/day-in-proof?user_id={uid}&date=2026-08-05")
        assert r.status_code == 200, r.text
        body = r.json()
        assert body["date"] == "2026-08-05"
        assert body["has_data"] is True, body
        assert body["workout"] is not None
        assert body["meal_grade"] is not None
    finally:
        app.dependency_overrides.pop(get_current_user, None)
