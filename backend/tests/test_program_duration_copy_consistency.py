"""
Regression gate for row 104 (2026-08 backend prompt sweep): "Gentle Start"'s
featured-carousel chip and Preview stat tile both read "20 MIN" while the
program's own tagline ("Eight minutes counts.") and every week's focus line
("Building consistency through 8-minute movement blocks") say 8. All three
are authored copy that agree with each other and with the real generated
content (every session in every variant carries workouts[].duration_minutes
== 8) — only the structured `programs.session_duration_minutes` field (20)
disagreed. Fix: migrations/2406_fix_gentle_start_session_duration.sql
corrects the field to match the copy + the real per-session data.

Hits the live Supabase project directly (read-only) — no paid LLM calls.
Skipped when Supabase credentials aren't configured in this environment.
"""
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

GENTLE_START_ID = "c78eb6d8-fed0-4a24-93e6-19f424ac60eb"


def _get_db():
    try:
        from core.supabase_client import get_supabase
        return get_supabase()
    except Exception:
        return None


@pytest.mark.skipif(
    not (
        os.environ.get("SUPABASE_URL")
        and (os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_KEY"))
    ),
    reason="Supabase credentials not configured in this environment",
)
def test_gentle_start_stated_duration_matches_actual_session_content():
    db = _get_db()
    if db is None:
        pytest.skip("could not build a Supabase client")

    prog = (
        db.client.table("programs")
        .select("id, session_duration_minutes, variant_base_id")
        .eq("id", GENTLE_START_ID)
        .limit(1)
        .execute()
        .data
    )
    if not prog:
        pytest.skip("Gentle Start program not present in this environment's DB")
    stated = prog[0]["session_duration_minutes"]

    variants = (
        db.client.table("program_variants")
        .select("id")
        .eq("base_program_id", prog[0]["variant_base_id"])
        .limit(1)
        .execute()
        .data
    )
    assert variants, "Gentle Start has no variants to check against"

    week = (
        db.client.table("program_variant_weeks")
        .select("workouts")
        .eq("variant_id", variants[0]["id"])
        .eq("week_number", 1)
        .limit(1)
        .execute()
        .data
    )
    assert week, "Gentle Start variant has no week-1 data to check against"

    durations = [
        s.get("duration_minutes")
        for s in (week[0]["workouts"] or [])
        if isinstance(s, dict) and s.get("duration_minutes")
    ]
    assert durations, "no session carried a duration_minutes to compare against"
    actual = sum(durations) / len(durations)

    assert abs(actual - stated) <= 3, (
        f"programs.session_duration_minutes ({stated}) disagrees with the "
        f"program's real session content ({actual} min avg) — this is exactly "
        f"what drove the '20 MIN' stat tile next to an '8-minute' tagline. "
        f"Apply migrations/2406_fix_gentle_start_session_duration.sql."
    )
