"""Render the weekly progress email from the real backend code (no Resend, no DB).

Builds representative WeeklyProgress objects for each scenario and writes the
signature-template HTML to docs/planning/redesign-2026-06/ for visual diffing
against weekly_progress_email_v3.html.
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from services.weekly_progress_service import WeeklyProgress, Tile, Award  # noqa: E402
from services import email_signature_template as sig  # noqa: E402
from services.email_marketing import (  # noqa: E402
    _weekly_subject, _weekly_greeting, _compose_weekly_body, _weekly_preheader,
)


class _Stats:
    time_band = type("T", (), {"value": "morning"})()
    coach_name = "Coach Mara"


def _render(progress, name="Chetan"):
    subject = _weekly_subject(progress, name)
    return subject, sig.signature_email(
        header_tag=f"Weekly · {progress.week_label}",
        greeting=_weekly_greeting(progress, name, _Stats()),
        greeting_sub=f"Your stats for {progress.week_label}",
        avatar=name[:1],
        body_html=_compose_weekly_body(progress, "Coach Mara", "#"),
        preheader=_weekly_preheader(progress, name),
    )


# Scenario 1 — full data
full = WeeklyProgress(
    week_label="Jun 6 – 12", has_wearable=True, is_first_week=False, empty_week=False,
    total_steps=15968, avg_steps=2281, best_label="Sat", best_steps=5734,
    steps_delta="↑ 3,888", steps_dir="up",
    day_steps=[("Sun", 1800), ("Mon", 2100), ("Tue", 2400), ("Wed", 1500),
               ("Thu", 900), ("Fri", 1534), ("Sat", 5734)],
    activity_tiles=[
        Tile("pin", "7.3", "Total miles", "↑ 1.8", "up"),
        Tile("activity", "2,729", "Cal burned", "↑ 202", "up"),
        Tile("timer", "370", "Zone min", "↑ 146", "up"),
        Tile("moon", "6h 41m", "Restful sleep", "↑ 11m", "up"),
        Tile("heart", "69", "Resting bpm", "↓ 4", "up"),
        Tile("scale", "98.3", "Weight (kg)", "No change", "flat"),
    ],
    zealova_tiles=[
        Tile("dumbbell", "3", "Workouts", "↑ 1", "up"),
        Tile("bars", "24,310", "Lbs lifted", "↑ 3,120", "up"),
        Tile("utensils", "5 / 7", "Days logged", "↑ 2", "up"),
        Tile("leaf", "42m", "Mindfulness", "↑ 18m", "up"),
        Tile("salad", "1,940", "Cal eaten", "On target", "flat"),
        Tile("flame", "12", "Day streak", "", "flat"),
    ],
)

# Scenario 2 — no wearable
no_wear = WeeklyProgress(
    week_label="Jun 6 – 12", has_wearable=False, is_first_week=False, empty_week=False,
    workouts_this_week=4, workouts_delta="↑ 2", workouts_dir="up",
    workouts_subline="3h 52m training · 31,050 lbs moved",
    zealova_tiles=[
        Tile("bars", "31,050", "Lbs lifted", "↑ 8,400", "up"),
        Tile("timer", "3h 52m", "Time training", "↑ 1h 10m", "up"),
        Tile("utensils", "6 / 7", "Days logged", "↑ 1", "up"),
        Tile("salad", "2,010", "Cal eaten", "240 over target", "flat"),
        Tile("flame", "9", "Day streak", "", "flat"),
    ],
)

# Scenario 5 — awards
awards = WeeklyProgress(
    week_label="Jun 6 – 12", has_wearable=True, is_first_week=False, empty_week=False,
    total_steps=18420, avg_steps=2631, best_label="Sat", best_steps=4980,
    steps_delta="↑ 2,450", steps_dir="up",
    day_steps=[("Sun", 2000), ("Mon", 2400), ("Tue", 2600), ("Wed", 2100),
               ("Thu", 1900), ("Fri", 2440), ("Sat", 4980)],
    awards=[
        Award("medal", "Level 8 reached", "+540 XP this week · top 12% of active members"),
        Award("flame", "14-day streak record", "Longest yet — beat your old best of 11"),
        Award("dumbbell", "New PR · Barbell Bench", "185 lb × 5 — up from 175 lb"),
    ],
    zealova_tiles=[
        Tile("dumbbell", "5", "Workouts", "↑ 2", "up"),
        Tile("bars", "38,900", "Lbs lifted", "↑ 6,100", "up"),
        Tile("trophy", "3", "PRs set", "↑ 3", "up"),
        Tile("flame", "14", "Day streak", "", "flat"),
    ],
)

# Scenario 4 — quiet week
quiet = WeeklyProgress(
    week_label="Jun 6 – 12", has_wearable=False, is_first_week=False, empty_week=True,
    total_steps=652, workouts_this_week=0,
    quiet_line="You logged 652 steps and 0 workouts this week. No guilt — weeks like this happen.",
    zealova_tiles=[
        Tile("utensils", "1 / 7", "Days logged", "↓ 4", "flat"),
        Tile("flame", "Paused", "Streak", "", "flat"),
    ],
)

OUT = os.path.join(os.path.dirname(__file__), "..", "..",
                   "docs", "planning", "redesign-2026-06")
scenarios = {"full": full, "nowearable": no_wear, "awards": awards, "quiet": quiet}
for key, prog in scenarios.items():
    subj, html = _render(prog)
    path = os.path.join(OUT, f"weekly_progress_backend_{key}.html")
    with open(path, "w") as f:
        f.write(html)
    print(f"[{key}] subject: {subj!r}  ->  {os.path.basename(path)}")

print("✅ rendered all scenarios from backend code")
