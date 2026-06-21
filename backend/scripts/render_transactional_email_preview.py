"""Render the transactional / lifecycle / bespoke emails from the REAL backend
builders (no Resend, no DB, no network) and write the HTML to
docs/planning/redesign-2026-06/email_proofs/backend_rendered/ for visual diffing
against the approved proofs (transactional_emails.html / interactive_emails.html).

Run: backend/.venv312/bin/python scripts/render_transactional_email_preview.py
"""
import asyncio
import dataclasses
import os
import sys

os.environ.setdefault("RESEND_API_KEY", "dummy_preview_key")
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import resend  # noqa: E402

# Capture the HTML each send() would transmit instead of calling Resend.
_CAPTURED = {}
resend.Emails.send = lambda params: (_CAPTURED.update(html=params.get("html", "")) or {"id": "preview"})

from datetime import datetime, date  # noqa: E402
from services.email_service import EmailService  # noqa: E402
from services import email_signature_template as sig  # noqa: E402
from models.email import UserStats, TimeBand, ScheduleState, CoachStyle  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "docs", "planning",
                   "redesign-2026-06", "email_proofs", "backend_rendered")
os.makedirs(OUT, exist_ok=True)
es = EmailService()


def _stats() -> UserStats:
    """Best-effort UserStats for persona/stats-driven emails."""
    defaults = {}
    for f in dataclasses.fields(UserStats):
        if f.default is not dataclasses.MISSING:
            defaults[f.name] = f.default
        elif f.default_factory is not dataclasses.MISSING:  # type: ignore
            defaults[f.name] = f.default_factory()  # type: ignore
        else:
            ann = str(f.type)
            defaults[f.name] = 0 if ("int" in ann or "float" in ann) else (
                "" if "str" in ann else None)
    s = UserStats(**defaults)
    s.coach_name = "Coach Mara"
    s.current_streak_days = 5
    s.workouts_total = 12
    s.schedule_state = ScheduleState.OVERDUE
    s.days_overdue = 2
    s.time_band = TimeBand.MORNING
    s.coach_style = CoachStyle.BALANCED
    s.nutrition_days_logged_this_week = 5
    s.nutrition_avg_calories_week = 1840
    return s


def dump(name: str, coro):
    _CAPTURED.clear()
    try:
        asyncio.run(coro)
        html = _CAPTURED.get("html", "")
        if not html:
            print(f"[skip] {name}: no html captured")
            return None
        path = os.path.join(OUT, f"{name}.html")
        with open(path, "w") as fh:
            fh.write(html)
        # guardrails
        bad = [b for b in ("#06b6d4", "#0f2733", "#1e3a47",
                           "linear-gradient(135deg,#FB923C") if b in html]
        emoji = any(f"&#{c};" in html for c in (127947, 129303, 128200, 128274, 128293))
        flag = " ⚠ LEAK" if (bad or emoji) else ""
        print(f"[ok]   {name:30s} {len(html):6d} bytes{flag}{(' '+str(bad)) if bad else ''}")
        return html
    except Exception as e:  # noqa: BLE001
        print(f"[FAIL] {name}: {type(e).__name__}: {e}")
        return None


print("rendering backend emails →", os.path.relpath(OUT))

dump("verification", es.send_verification_email(
    "t@x.com", "Chetan", "https://zealova.com/verify?token=abc"))
dump("billing_issue", es.send_billing_issue("t@x.com", "Chetan", "premium_annual"))
dump("purchase_confirmation", es.send_purchase_confirmation(
    "t@x.com", "Chetan", "premium_annual", 59.99, "USD"))
dump("welcome", es.send_welcome_email(
    to_email="t@x.com", first_name="Chetan", goal="muscle", days_per_week=3,
    weight_kg=90, goal_weight_kg=84, weight_direction="lose",
    daily_calories=1840, protein_g=155, carbs_g=170, fat_g=61,
    first_workout_name="Full Body A", first_workout_duration=45,
    first_workout_exercises=[
        {"name": "Goblet Squat", "sets": 3, "reps": 10},
        {"name": "Incline DB Press", "sets": 3, "reps": 12},
        {"name": "Lat Pulldown", "sets": 3, "reps": 12},
        {"name": "Romanian Deadlift", "sets": 3, "reps": 10},
    ],
    training_days=["mon", "wed", "fri"]))
dump("workout_reminder", es.send_workout_reminder(
    "t@x.com", "Chetan", _stats(), "Push Day", "strength", date(2026, 6, 22),
    [{"name": "Bench Press", "sets": 4, "reps": 6},
     {"name": "Overhead Press", "sets": 3, "reps": 8}]))
dump("security_new_device", es.send_new_device_signin_email(
    "t@x.com", "Chetan", "iPhone 15", "iOS 18", "Dallas, TX, US",
    "1.2.3.4", datetime(2026, 6, 21, 14, 14)))
from services.email_waitlist import WaitlistEmailService  # noqa: E402
dump("waitlist", WaitlistEmailService().send_waitlist_confirmation("t@x.com", "Chetan"))
dump("free_tool", es.send_free_tool_result(
    "t@x.com", "tdee-calculator",
    {"TDEE": "2,540 cal", "BMR": "1,780 cal", "Goal": "Lose 1 lb/wk"}))
dump("lifetime_waitlist", es.send_lifetime_waitlist_confirmation("t@x.com", 42))
dump("lifetime_checkout", es.send_lifetime_checkout_open("t@x.com", 120))
dump("lifetime_purchase", es.send_lifetime_purchase_confirmation(
    "t@x.com", 88, 14999, "https://zealova.com/receipt/88"))

# Lifecycle look (persona card + stats grid injected through the chokepoint).
from services.email_helpers import build_persona_signature_html, build_stats_grid_html  # noqa: E402
s = _stats()
lifecycle_html = es._build_standard_email(
    logo_url="x", open_url="https://zealova.com/open",
    title="It's been a minute, Chetan", subtitle="One session puts you right back on track.",
    cta_text="Pick up where you left off", features=[],
    footer_text="", persona_signature_html=build_persona_signature_html(s),
    stats_row_html=build_stats_grid_html(s),
    unsubscribe_url="https://zealova.com/unsub", category_name="check-ins",
    header_tag="Check-in",
)
with open(os.path.join(OUT, "lifecycle_overdue.html"), "w") as fh:
    fh.write(lifecycle_html)
print(f"[ok]   {'lifecycle_overdue':30s} {len(lifecycle_html):6d} bytes")

print("\n✅ done — open the files in", os.path.relpath(OUT))
