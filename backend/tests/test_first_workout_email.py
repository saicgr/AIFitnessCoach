"""Regression tests for the N2 first-workout-done email (Issues 7 + 8).

Covers two screenshot bugs:
  - Bug 7: Stats grid showed nutrition AVG CAL/DAY (e.g. 542) where it should
    show the WORKOUT kcal for the session that just completed. Plus the
    "0/7" meals cell on day 1 reads as failure — should be em-dash.
  - Bug 8: "Hang out with us" Discord/Instagram pills rendered LEFT-aligned
    in Gmail Android because nested-table `margin:0 auto` is unreliable on
    that renderer. Fixed by adding align="center" to the inner table + cells.

Plus the min-duration gate: sub-3-minute workouts must NOT fire the
celebration email (a 60-second tap-through is not a "first workout").

Run: backend/.venv/bin/pytest backend/tests/test_first_workout_email.py -v
"""
from __future__ import annotations

import asyncio
import os
import re

import pytest


# ─── Stats-grid helper unit tests ───────────────────────────────────────────

def test_first_workout_stats_grid_uses_calories_burned_not_nutrition_avg():
    """Bug 7: with calories_burned=174, the grid renders WORKOUT KCAL = 174 —
    NOT the nutrition AVG CAL/DAY value, and NOT the misleading 542 from the
    screenshot."""
    from services.email_helpers import build_first_workout_stats_grid
    from models.email import UserStats

    stats = UserStats(
        workouts_total=1,
        current_streak_days=1,
        # Realistic day-1 user has logged ONE meal — the legacy grid would
        # render 542 cal/day and surface that in the email. We assert the new
        # helper IGNORES this field.
        nutrition_days_logged_this_week=1,
        nutrition_avg_calories_week=542,
    )
    html = build_first_workout_stats_grid(
        stats,
        workout_calories_burned=174,
        duration_seconds=600,
        user_weight_kg=80.0,
    )
    # Workout kcal must render
    assert ">174<" in html, "Expected workout calories 174 in grid"
    # Label is WORKOUT KCAL (CSS uppercases via text-transform), source is title-case
    assert "Workout kcal" in html
    # The nutrition AVG label/value must NOT appear in this grid
    assert "Avg cal/day" not in html
    assert ">542<" not in html


def test_first_workout_stats_grid_falls_back_to_met_estimate():
    """When calories_burned is None/0, fall back to MET formula:
    kcal = 5.0 × weight_kg × hours. For 600s @ 80kg: 5.0 × 80 × (600/3600) ≈ 67.
    """
    from services.email_helpers import build_first_workout_stats_grid, estimate_workout_kcal_met

    expected = estimate_workout_kcal_met(600, 80.0)
    assert expected > 0, "MET estimate must be positive"
    assert expected == round(5.0 * 80.0 * (600 / 3600))

    from models.email import UserStats
    stats = UserStats(workouts_total=1)
    html = build_first_workout_stats_grid(
        stats,
        workout_calories_burned=None,
        duration_seconds=600,
        user_weight_kg=80.0,
    )
    assert f">{expected}<" in html or f">{expected:,}<" in html


def test_first_workout_stats_grid_renders_dash_for_zero_meals():
    """Day-1 user has logged 0 meals — the cell should read "—" not "0/7"."""
    from services.email_helpers import build_first_workout_stats_grid
    from models.email import UserStats

    stats = UserStats(workouts_total=1, nutrition_days_logged_this_week=0)
    html = build_first_workout_stats_grid(
        stats, workout_calories_burned=174, duration_seconds=600,
    )
    # The cell renders the em-dash, not 0/7
    assert "0/7" not in html
    assert "—" in html


def test_met_estimate_defaults_to_70kg_when_weight_missing():
    """No weight available → 70 kg default. 600s @ 70kg ≈ 58 kcal."""
    from services.email_helpers import estimate_workout_kcal_met
    kcal = estimate_workout_kcal_met(600, None)
    assert kcal == round(5.0 * 70.0 * (600 / 3600))
    assert kcal > 0


def test_met_estimate_zero_for_nonpositive_duration():
    from services.email_helpers import estimate_workout_kcal_met
    assert estimate_workout_kcal_met(0, 80.0) == 0
    assert estimate_workout_kcal_met(-30, 80.0) == 0
    assert estimate_workout_kcal_met(None, 80.0) == 0  # type: ignore[arg-type]


def test_weekly_stats_grid_unchanged_for_existing_callers():
    """Regression: build_stats_grid_html keeps its weekly-recap nutrition
    semantics. We must not have collateral-damaged the weekly summary email."""
    from services.email_helpers import build_stats_grid_html
    from models.email import UserStats

    stats = UserStats(
        workouts_total=3,
        nutrition_days_logged_this_week=5,
        nutrition_avg_calories_week=2100,
    )
    html = build_stats_grid_html(stats)
    assert "Avg cal/day" in html  # weekly grid still shows nutrition avg
    assert "2,100" in html


# ─── Social pills centering (Bug 8) ─────────────────────────────────────────

def test_social_footer_inner_table_is_align_center():
    """Bug 8: inner table wrapping the Discord+Instagram pills must carry the
    legacy align="center" attribute so Gmail Android centers it."""
    from services.email_helpers import build_social_footer_html

    html = build_social_footer_html()
    # The inner pills table must have align="center"
    table_with_align = re.search(
        r'<table[^>]*role="presentation"[^>]*align="center"[^>]*>',
        html,
    )
    assert table_with_align, (
        "Pills inner <table> missing align=\"center\" — Gmail Android will "
        "render the row left-aligned. HTML:\n" + html
    )

    # Both pill <td>s carry align="center" too (defense in depth)
    pill_tds = re.findall(r'<td[^>]*align="center"[^>]*>\s*<a[^>]*href="https://(discord|instagram)', html)
    assert len(pill_tds) >= 2, (
        "Each pill <td> should carry align=\"center\". Matches: " + str(pill_tds)
    )


def test_social_footer_still_contains_both_pills():
    """Sanity: the centering fix didn't drop a pill."""
    from services.email_helpers import build_social_footer_html
    html = build_social_footer_html()
    assert "discord.gg/" in html
    assert "instagram.com/" in html


# ─── Min-duration gate ──────────────────────────────────────────────────────

def test_send_first_workout_done_skips_below_min_duration(monkeypatch):
    """Bug-prevention: sub-180s "workouts" must not trigger the email."""
    import resend
    from services.email_service import EmailService
    from models.email import UserStats

    os.environ.setdefault("RESEND_API_KEY", "dummy")
    sent = []

    def fake_send(params):
        sent.append(params)
        return {"id": "should-not-fire"}

    monkeypatch.setattr(resend.Emails, "send", fake_send)

    svc = EmailService()
    stats = UserStats(workouts_total=1)
    result = asyncio.get_event_loop().run_until_complete(
        svc.send_first_workout_done(
            to_email="t@example.com",
            first_name_value="Sai",
            stats=stats,
            workout_name="Push Day",
            duration_seconds=120,  # 2 minutes — below threshold
        )
    )
    assert result.get("skipped") == "below_min_duration"
    assert sent == [], "Resend.send should NOT have been called for sub-3-min workout"


def test_send_first_workout_done_renders_workout_kcal_label(monkeypatch):
    """End-to-end: the rendered email contains WORKOUT KCAL (not AVG CAL/DAY)
    and the 174 kcal value from the screenshot scenario."""
    import resend
    from services.email_service import EmailService
    from models.email import UserStats

    os.environ.setdefault("RESEND_API_KEY", "dummy")
    captured = {}

    def fake_send(params):
        captured["html"] = params["html"]
        captured["subject"] = params["subject"]
        return {"id": "fake"}

    monkeypatch.setattr(resend.Emails, "send", fake_send)

    svc = EmailService()
    stats = UserStats(
        workouts_total=1, current_streak_days=1,
        nutrition_avg_calories_week=542,  # the bug value — must NOT render
    )
    asyncio.get_event_loop().run_until_complete(
        svc.send_first_workout_done(
            to_email="t@example.com",
            first_name_value="Sai",
            stats=stats,
            workout_name="Push Day",
            duration_seconds=600,
            calories_burned=174,
            user_weight_kg=80.0,
        )
    )
    html = captured["html"]
    assert ">174<" in html, "Workout kcal 174 must render in stats grid"
    # Premailer may transform tag attribute order/case; just check label substring
    assert "Workout kcal" in html, "Label must say WORKOUT KCAL (title-case in source)"
    assert ">542<" not in html, "Nutrition daily-avg 542 must NOT render in this email"
    assert "Sai" in captured["subject"], "First name must appear in subject"
    assert "Sai" in html, "First name must appear in body"


def test_send_first_workout_done_html_has_centered_social_row(monkeypatch):
    """Bug 8 end-to-end: the rendered first-workout email centers its social row.

    The email moved to the signature template, whose footer is a centered row of
    icon links (Discord / Instagram / Reddit) — the old "Hang out with us" text
    pills only exist in `build_social_footer_html`, which this email no longer
    calls. The guarantee worth protecting is unchanged and is what we assert:
    the social row is present, complete, and CENTERED (left-aligned rows are the
    Gmail-Android bug this test was written for).
    """
    from core import branding
    from services import email_sender
    from services.email_service import EmailService
    from models.email import UserStats

    os.environ.setdefault("RESEND_API_KEY", "dummy")
    captured = {}

    def fake_send(params, **kwargs):
        captured["html"] = params["html"]
        return {"id": "fake"}

    # Patch the chokepoint — services/email_sender.send is the only path to Resend.
    monkeypatch.setattr(email_sender, "send", fake_send)

    svc = EmailService()
    stats = UserStats(workouts_total=1)
    asyncio.get_event_loop().run_until_complete(
        svc.send_first_workout_done(
            to_email="t@example.com",
            first_name_value="Sai",
            stats=stats,
            workout_name="Push Day",
            duration_seconds=600,
            calories_burned=174,
        )
    )
    html = captured["html"]

    # Every social destination survives.
    assert "discord.gg/" in html
    assert branding.INSTAGRAM_URL in html

    # The row carrying them is centered.
    social_row = re.search(
        r'<table[^>]*align="center"[^>]*>(?:(?!</table>).)*?discord\.gg/.*?</table>',
        html,
        re.DOTALL,
    )
    assert social_row, (
        'Social icon row is not inside an align="center" table — Gmail Android '
        "will left-align it. HTML:\n" + html[-2500:]
    )
    # Icons render as <img>, not bare text links.
    assert "<img" in social_row.group(0).lower()
