"""
Regression gate for row 111 (2026-08 backend prompt sweep): "30-Day Plank
Challenge" session titles are cryptic numeric shorthand — "DAY 5 — 40S +
SIDE", "DAY 7 — 50S + TAPS", "DAY 30 — FINAL 180S TEST".

Root cause: this program has `variant_base_id IS NULL` (never expanded into
program_variants), so it schedules from `programs.workouts` directly — a
base blob `scripts/audit_program_copy_clarity.py` /
`rewrite_program_copy_plain_language.py` never scan (they only walk
`program_variant_weeks`). Fix lives in
migrations/2409_plank_challenge_plain_titles.py — a deterministic (no LLM)
title rewriter, not yet applied to production (dry-run only, per this
task's rule to write-and-report rather than apply).
"""
import importlib.util
import os

_MIGRATION_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "migrations", "2409_plank_challenge_plain_titles.py",
)
_spec = importlib.util.spec_from_file_location("plank_titles_migration", _MIGRATION_PATH)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
rewrite_day_title = _mod.rewrite_day_title


def test_the_exact_shipped_defect_titles():
    assert rewrite_day_title("Day 5 — 40s + Side") == "Day 5 — 40-second hold + side plank"
    assert rewrite_day_title("Day 7 — 50s + Taps") == "Day 7 — 50-second hold + shoulder taps"
    assert rewrite_day_title("Day 26 — 150s + Side") == "Day 26 — 150-second hold + side plank"
    assert rewrite_day_title("Day 30 — Final 180s Test") == "Day 30 — Final 180-second hold test"


def test_plain_hold_days():
    assert rewrite_day_title("Day 3 — 30s") == "Day 3 — 30-second hold"


def test_foundation_days():
    assert rewrite_day_title("Day 1 — Foundation 20s") == "Day 1 — 20-second hold (building the habit)"


def test_rest_days_are_untouched():
    assert rewrite_day_title("Day 4 — Rest") == "Day 4 — Rest"


def test_all_30_real_titles_produce_no_cryptic_shorthand_left():
    real_titles = [
        "Day 1 — Foundation 20s", "Day 2 — Foundation 20s", "Day 3 — 30s", "Day 4 — Rest",
        "Day 5 — 40s + Side", "Day 6 — 45s", "Day 7 — 50s + Taps", "Day 8 — Rest",
        "Day 9 — 60s", "Day 10 — 60s + Side", "Day 11 — 70s", "Day 12 — Rest",
        "Day 13 — 80s + Taps", "Day 14 — 90s", "Day 15 — 90s + Side", "Day 16 — Rest",
        "Day 17 — 100s", "Day 18 — 100s + Taps", "Day 19 — 110s", "Day 20 — Rest",
        "Day 21 — 120s + Side", "Day 22 — 130s", "Day 23 — 140s", "Day 24 — Rest",
        "Day 25 — 150s", "Day 26 — 150s + Side", "Day 27 — 160s", "Day 28 — Rest",
        "Day 29 — 170s", "Day 30 — Final 180s Test",
    ]
    import re
    cryptic = re.compile(r"\d+s\b")
    for title in real_titles:
        new = rewrite_day_title(title)
        assert not cryptic.search(new), f"{title!r} -> {new!r} still has cryptic shorthand"
