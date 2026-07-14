"""
Regression tests for the email overhaul.

Covers the invariants that the plan established:
  - No "AI coach" / "AI-generated" / "AI-powered" in email modules.
  - No `datetime.utcnow()` in notification logic (must use user-local TZ).
  - Every lifecycle email template interpolates the user's name.
  - Social footer (Discord + Instagram) present in rendered output.
  - Helpers (first_name, time_band, schedule_state routing) behave correctly.

Run with: pytest backend/tests/test_email_regressions.py -v
"""
from __future__ import annotations

import os
import re
from datetime import datetime, timezone, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import pytest


# Resolve backend/ relative to this test file
BACKEND_ROOT = Path(__file__).resolve().parents[1]
EMAIL_MODULES = [
    BACKEND_ROOT / "services" / "email_service.py",
    BACKEND_ROOT / "services" / "email_lifecycle.py",
    BACKEND_ROOT / "services" / "email_marketing.py",
    BACKEND_ROOT / "services" / "email_helpers.py",
    BACKEND_ROOT / "services" / "email_cancel_ladder.py",
    BACKEND_ROOT / "services" / "email_engagement.py",
    BACKEND_ROOT / "api" / "v1" / "email_cron.py",
]


# ─── Static source-code regressions ─────────────────────────────────────────

def test_no_ai_language_in_email_modules():
    """Every user-facing "AI coach" / "AI-generated" string has been scrubbed."""
    banned = re.compile(r"\bAI coach\b|\bAI-generated\b|\bAI-powered\b|\bAI Coach\b", re.IGNORECASE)
    offenders: list[str] = []
    for path in EMAIL_MODULES:
        text = path.read_text()
        # Strip Python comments so references like "renamed from AI coach tips"
        # in dev-facing docs don't trip us.
        lines = [re.sub(r"#.*$", "", line) for line in text.splitlines()]
        stripped = "\n".join(lines)
        for match in banned.finditer(stripped):
            offenders.append(f"{path.relative_to(BACKEND_ROOT)}: {match.group()!r}")
    assert not offenders, f"AI-language hits found:\n" + "\n".join(offenders)


def test_no_utcnow_in_notification_logic():
    """`datetime.utcnow()` is deprecated and timezone-unaware. Use
    `datetime.now(timezone.utc)` instead."""
    offenders: list[str] = []
    for path in EMAIL_MODULES:
        text = path.read_text()
        for lineno, line in enumerate(text.splitlines(), 1):
            stripped = re.sub(r"#.*$", "", line)
            if "datetime.utcnow" in stripped:
                offenders.append(f"{path.relative_to(BACKEND_ROOT)}:{lineno}: {line.strip()}")
    assert not offenders, f"datetime.utcnow() still in use:\n" + "\n".join(offenders)


def test_every_email_template_uses_name_placeholder():
    """Every rewritten `send_*` that builds HTML must interpolate a name-ish
    variable at least once (first_name_value, display_name, or stats.name).

    This is a static check — we look for functions with `to_email` and
    verify they reference `first_name_value` or `display_name` somewhere.
    """
    offenders: list[str] = []
    for path in (
        BACKEND_ROOT / "services" / "email_lifecycle.py",
        BACKEND_ROOT / "services" / "email_marketing.py",
        BACKEND_ROOT / "services" / "email_cancel_ladder.py",
        BACKEND_ROOT / "services" / "email_engagement.py",
    ):
        text = path.read_text()
        # Split by `async def send_` — each chunk is one method.
        chunks = re.split(r"(?=async def send_)", text)
        for chunk in chunks:
            m = re.search(r"async def (send_\w+)", chunk)
            if not m:
                continue
            name = m.group(1)
            if "to_email" not in chunk:
                continue
            if not (
                "first_name_value" in chunk
                or "display_name" in chunk
                or "stats.coach_name" in chunk
            ):
                offenders.append(f"{path.name}::{name}")
    assert not offenders, f"Email templates missing name interpolation:\n" + "\n".join(offenders)


# ─── Functional tests of helpers ────────────────────────────────────────────

def test_first_name_extracts_first_token():
    from services.email_helpers import first_name
    assert first_name({"name": "Sai Chetan Grandhe"}) == "Sai"
    assert first_name({"name": "Sai"}) == "Sai"


def test_first_name_falls_back_to_email_prefix():
    from services.email_helpers import first_name
    assert first_name({"email": "sai@example.com"}) == "Sai"
    assert first_name({"email": "john.doe42@test.com"}) == "Johndoe"


def test_first_name_last_resort_is_there():
    from services.email_helpers import first_name
    assert first_name({}) == "there"
    assert first_name({"name": "   "}) == "there"


def test_time_band_morning_in_user_local_tz():
    from services.email_helpers import time_band
    from models.email import TimeBand
    # 09:00 in Chicago is always MORNING regardless of server UTC
    now = datetime(2026, 4, 14, 14, 0, tzinfo=timezone.utc)  # 09:00 CDT
    assert time_band("America/Chicago", now=now) == TimeBand.MORNING


def test_time_band_quiet_hours_override_clock():
    from services.email_helpers import time_band
    from models.email import TimeBand
    # 23:00 local is inside default quiet window (22-06) — must return QUIET
    now = datetime(2026, 4, 14, 4, 0, tzinfo=timezone.utc)  # 23:00 CDT prev day
    # Actually 23:00 CDT = 04:00 UTC next day → let's compute explicitly
    # 2026-04-14 04:00 UTC = 2026-04-13 23:00 CDT (CDT is UTC-5)
    result = time_band("America/Chicago", now=now)
    assert result == TimeBand.QUIET


def test_time_band_falls_back_to_utc_on_bad_tz():
    from services.email_helpers import time_band
    from models.email import TimeBand
    now = datetime(2026, 4, 14, 9, 0, tzinfo=timezone.utc)
    # Unknown TZ should not crash — should return a valid band
    result = time_band("Not/A/Zone", now=now)
    assert isinstance(result, TimeBand)


def test_persona_mood_overdue_zero_workouts_is_disappointed():
    """BALANCED coach_style (default): Disappointed only kicks in after ~2 weeks."""
    from services.email_helpers import persona_mood
    from models.email import UserStats, ScheduleState, CoachStyle
    stats = UserStats(
        schedule_state=ScheduleState.OVERDUE,
        workouts_total=0,
        days_overdue=14,
        coach_style=CoachStyle.BALANCED,
    )
    emoji, mood = persona_mood(stats)
    assert mood == "Disappointed"


def test_persona_mood_overdue_day_one_is_soft_nudge():
    """BALANCED + day 1 overdue → Nudging (no guilt for one missed day)."""
    from services.email_helpers import persona_mood
    from models.email import UserStats, ScheduleState, CoachStyle
    stats = UserStats(
        schedule_state=ScheduleState.OVERDUE,
        workouts_total=0,
        days_overdue=1,
        coach_style=CoachStyle.BALANCED,
    )
    emoji, mood = persona_mood(stats)
    assert mood == "Nudging"


def test_persona_mood_overdue_mid_range_is_concerned():
    """BALANCED + 4-13 days overdue → Concerned check-in, not yet Disappointed."""
    from services.email_helpers import persona_mood
    from models.email import UserStats, ScheduleState, CoachStyle
    stats = UserStats(
        schedule_state=ScheduleState.OVERDUE,
        workouts_total=0,
        days_overdue=7,
        coach_style=CoachStyle.BALANCED,
    )
    _emoji, mood = persona_mood(stats)
    assert mood == "Concerned"


def test_persona_mood_gentle_never_escalates():
    """GENTLE coach_style → never Disappointed, even after 30 days overdue."""
    from services.email_helpers import persona_mood
    from models.email import UserStats, ScheduleState, CoachStyle
    stats = UserStats(
        schedule_state=ScheduleState.OVERDUE,
        workouts_total=0,
        days_overdue=30,
        coach_style=CoachStyle.GENTLE,
    )
    _emoji, mood = persona_mood(stats)
    assert mood == "Nudging"


def test_persona_mood_tough_love_escalates_fast():
    """TOUGH_LOVE coach_style → Disappointed by day 3 (opt-in aggressive tone)."""
    from services.email_helpers import persona_mood
    from models.email import UserStats, ScheduleState, CoachStyle
    stats = UserStats(
        schedule_state=ScheduleState.OVERDUE,
        workouts_total=0,
        days_overdue=3,
        coach_style=CoachStyle.TOUGH_LOVE,
    )
    _emoji, mood = persona_mood(stats)
    assert mood == "Disappointed"


def test_persona_mood_launches_today_morning_is_watching():
    from services.email_helpers import persona_mood
    from models.email import UserStats, ScheduleState, TimeBand
    stats = UserStats(
        schedule_state=ScheduleState.LAUNCHES_TODAY,
        time_band=TimeBand.MORNING,
    )
    _emoji, mood = persona_mood(stats)
    assert mood == "Watching"


def test_persona_mood_strong_streak_is_proud():
    from services.email_helpers import persona_mood
    from models.email import UserStats
    stats = UserStats(current_streak_days=14)
    _emoji, mood = persona_mood(stats)
    assert mood == "Proud"


def test_social_footer_has_both_logos_and_links():
    from core import branding
    from services.email_helpers import build_social_footer_html
    html = build_social_footer_html()
    assert "discord.gg/WAYNZpVgsK" in html
    # Assert against branding, not a literal — the handle moved once already
    # (the old literal here was `instagram.com/zealova.com`, which was never a
    # real account) and a hardcoded copy just rots again on the next change.
    assert branding.INSTAGRAM_URL in html
    # Icon <img> tags must reference the simpleicons CDN (or our static fallback)
    assert "discord" in html.lower()
    assert "instagram" in html.lower()
    assert "<img" in html.lower()


def test_nutrition_grid_renders_zero_state_prompt():
    from services.email_helpers import build_nutrition_grid_html
    from models.email import UserStats
    stats = UserStats()  # all zero
    html = build_nutrition_grid_html(stats)
    assert "Nutrition is blank" in html
    assert stats.coach_name in html


def test_nutrition_grid_renders_data_for_active_user():
    from services.email_helpers import build_nutrition_grid_html
    from models.email import UserStats
    stats = UserStats(
        nutrition_days_logged_this_week=5,
        nutrition_avg_calories_week=2100,
        nutrition_avg_protein_g_week=135,
    )
    html = build_nutrition_grid_html(stats)
    assert "5/7" in html
    assert "2,100" in html
    assert "135g" in html


# ─── Schedule-state branching ───────────────────────────────────────────────
# These exercise the Day-3 email's schedule_state logic. We call the send
# method but intercept Resend so no network call happens.

@pytest.fixture
def render_email(monkeypatch):
    """Yield a function that returns (subject, html) for a send_* call."""
    import resend

    def _render(send_fn_call_coro):
        captured: dict = {}

        def fake_send(params):
            captured["subject"] = params["subject"]
            captured["html"] = params["html"]
            return {"id": "fake"}

        monkeypatch.setattr(resend.Emails, "send", fake_send)
        import asyncio
        asyncio.get_event_loop().run_until_complete(send_fn_call_coro)
        return captured

    return _render


def test_day3_launches_today_morning_uses_anticipatory_voice(render_email):
    from services.email_service import EmailService
    from models.email import UserStats, ScheduleState, TimeBand

    os.environ.setdefault("RESEND_API_KEY", "dummy")
    svc = EmailService()
    stats = UserStats(
        schedule_state=ScheduleState.LAUNCHES_TODAY,
        time_band=TimeBand.MORNING,
        next_workout_goal="strength",
    )
    captured = render_email(
        svc.send_day3_activation(
            to_email="t@example.com", first_name_value="Sai", stats=stats
        )
    )
    assert "today's the day" in captured["subject"].lower()
    # Guilt word MUST NOT appear in the anticipatory variant
    assert "worried" not in captured["subject"].lower()


def test_day3_overdue_firm_tier_escalates_but_stays_blameless(render_email):
    """The firm tier fires only after the balanced window expires (14+ days),
    and even then it does NOT guilt the user.

    History: this test used to assert a "worried" subject carrying the persona
    name. That copy was deliberately retired — the old ladder fired
    "Disappointed" language after a SINGLE missed day (see the comment above
    `overdue_tier` in email_lifecycle). The escalation itself is still the
    behavior worth protecting, so we assert the tier changes, not the shaming.
    """
    from services.email_service import EmailService
    from models.email import UserStats, ScheduleState, TimeBand

    os.environ.setdefault("RESEND_API_KEY", "dummy")
    svc = EmailService()

    def _render(days_overdue: int):
        stats = UserStats(
            schedule_state=ScheduleState.OVERDUE,
            time_band=TimeBand.MORNING,
            days_overdue=days_overdue,
            coach_name="Max",  # user picked custom persona
        )
        return render_email(
            svc.send_day3_activation(
                to_email="t@example.com", first_name_value="Sai", stats=stats
            )
        )

    firm = _render(14)
    nudge = _render(1)

    # The ladder actually escalates — day 14 is not the day-1 copy.
    assert firm["subject"] != nudge["subject"]
    assert "your plan's waiting" in nudge["subject"].lower()
    assert "still waiting" in firm["subject"].lower()

    # The user is addressed by name, and the persona still speaks in the body.
    assert "Sai" in firm["subject"]
    assert "Max" in firm["html"]

    # No shaming, at any tier. This is the guarantee the old assertion inverted.
    for word in ("disappointed", "worried", "failed", "excuses"):
        assert word not in firm["subject"].lower()
        assert word not in nudge["subject"].lower()


def test_day3_overdue_day_one_uses_soft_nudge_copy(render_email):
    """Day 1 overdue on default (BALANCED) must not render guilt copy — soft nudge only."""
    from services.email_service import EmailService
    from models.email import UserStats, ScheduleState, TimeBand

    os.environ.setdefault("RESEND_API_KEY", "dummy")
    svc = EmailService()
    stats = UserStats(
        schedule_state=ScheduleState.OVERDUE,
        time_band=TimeBand.MORNING,
        days_overdue=1,
    )
    captured = render_email(
        svc.send_day3_activation(
            to_email="t@example.com", first_name_value="Sai", stats=stats
        )
    )
    subject = captured["subject"].lower()
    html = captured["html"]
    assert "worried" not in subject
    assert "disappointed" not in html.lower()
    assert "1 days ago" not in html  # pluralization guard


def test_day3_subject_always_contains_first_name(render_email):
    from services.email_service import EmailService
    from models.email import UserStats, ScheduleState, TimeBand

    os.environ.setdefault("RESEND_API_KEY", "dummy")
    svc = EmailService()
    for state in (
        ScheduleState.LAUNCHES_TODAY,
        ScheduleState.OVERDUE,
        ScheduleState.LAUNCHES_FUTURE,
        ScheduleState.NO_PLAN,
    ):
        stats = UserStats(schedule_state=state, time_band=TimeBand.MORNING, days_overdue=3, days_until_first_workout=2)
        captured = render_email(
            svc.send_day3_activation(
                to_email="t@example.com", first_name_value="Jordan", stats=stats
            )
        )
        assert "Jordan" in captured["subject"], f"Missing name in subject for state {state}"
        assert "Jordan" in captured["html"], f"Missing name in body for state {state}"


def test_weekly_summary_embeds_nutrition_data(render_email):
    """The Monday recap must show what the user ate, not just what they lifted.

    Nutrition now reaches this email through the `WeeklyProgress` tiles
    (`zealova_tiles`), not the old stats-only summary line — so drive it the way
    the cron actually does. Passing `progress=None` (as this test used to) hits
    the defensive minimal-check-in branch, which by design carries no tiles at
    all, so it could never have proven anything about nutrition.
    """
    from services.email_service import EmailService
    from services.weekly_progress_service import WeeklyProgress, Tile
    from models.email import UserStats

    os.environ.setdefault("RESEND_API_KEY", "dummy")
    svc = EmailService()
    stats = UserStats(
        workouts_this_week=3, workouts_total=12,
        nutrition_days_logged_this_week=5,
        nutrition_avg_calories_week=2100,
        nutrition_avg_protein_g_week=135,
    )
    progress = WeeklyProgress(
        week_label="Jul 6 – Jul 12",
        has_wearable=False,
        is_first_week=False,
        empty_week=False,
        workouts_this_week=3,
        zealova_tiles=[
            Tile("dumbbell", "3", "Workouts", "", "flat"),
            Tile("utensils", "5 / 7", "Days logged", "", "flat"),
            Tile("salad", "2,100", "Cal eaten", "", "flat"),
        ],
    )
    captured = render_email(
        svc.send_weekly_summary(
            to_email="t@example.com", first_name_value="Sai", stats=stats,
            progress=progress, total_duration_minutes=180,
        )
    )
    # Nutrition must be visible in the body.
    assert "5 / 7" in captured["html"]
    assert "Days logged" in captured["html"]
    assert "2,100" in captured["html"]
    assert "Cal eaten" in captured["html"]


def test_every_email_html_contains_social_footer(render_email):
    """Every email built via _build_standard_email has Discord + Instagram."""
    from services.email_service import EmailService
    from models.email import UserStats, ScheduleState, TimeBand

    os.environ.setdefault("RESEND_API_KEY", "dummy")
    svc = EmailService()
    stats = UserStats(schedule_state=ScheduleState.OVERDUE, time_band=TimeBand.MORNING, days_overdue=3)

    captured = render_email(
        svc.send_day3_activation(
            to_email="t@example.com", first_name_value="Sai", stats=stats
        )
    )
    from core import branding
    assert "discord.gg/WAYNZpVgsK" in captured["html"]
    assert branding.INSTAGRAM_URL in captured["html"]
