"""
Regression gate for row 198 (2026-08 backend prompt sweep): the EVENING
RECAP card's only CTA was "View sleep details" for an account with no
synced sleep, landing on a screen whose entire content is "Connect Health
to see your sleep" — a dead end. The generator (daily_insight.py /
daily_insight_prompt.py) already computes `sleep["applicable"] = False`
when today has no synced sleep_minutes; it just wasn't consulted before
attaching the CTA.

Two chokepoints fixed:
1. services/gemini/daily_insight_prompt.py ROUTE WHITELIST — now tells
   Gemini to only offer /health/sleep when sleep data actually exists, and
   to route to /metrics (Connect Health) instead.
2. api/v1/coach/daily_insight.py `_pick_fallback_pillar` — the deterministic
   (no-LLM) fallback picked "sleep" as the leading pillar purely from
   target_hours/total_hours, the same gap `move_open` was already patched
   for (E2E #132c) — a disconnected account reads total_hours=0 <
   target_hours=8 unconditionally. Also fixed a route typo ("/sleep" is not
   in the validated route whitelist; the real route is "/health/sleep").

No paid Gemini calls: the prompt assertion reads source text directly, and
`_pick_fallback_pillar` is pure Python.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.gemini import daily_insight_prompt  # noqa: E402
from api.v1.coach import daily_insight as di  # noqa: E402


def test_route_whitelist_gates_sleep_cta_on_data_presence():
    src = daily_insight_prompt._SHARED_RULES
    assert "/metrics" in src
    assert "sleep.applicable" in src, (
        "The prompt's route whitelist doesn't tell Gemini to check whether "
        "sleep data exists before offering /health/sleep as a CTA."
    )


def test_metrics_route_is_in_the_validated_whitelist():
    assert "/metrics" in di._VALID_ROUTES


def _base_snapshot(**overrides):
    snap = {
        "train": {"applicable": False, "reach_met": True},
        "nourish": {"calorie_target": 0, "calories_logged": 0},
        "move": {"applicable": False, "step_target": 0, "steps": 0},
        "sleep": {"applicable": True, "target_hours": 8, "total_hours": 0},
    }
    for k, v in overrides.items():
        snap[k].update(v)
    return snap


def test_fallback_never_picks_sleep_pillar_with_no_sleep_data():
    # DEFECT: an account with zero synced sleep (applicable=False) still has
    # total_hours=0 < target_hours=8, which used to make sleep_open True
    # unconditionally and route the fallback CTA to a dead end.
    snapshot = _base_snapshot(sleep={"applicable": False, "target_hours": 8, "total_hours": 0})
    pillar = di._pick_fallback_pillar(snapshot)
    assert pillar != "sleep", (
        "Fallback picked the 'sleep' leading pillar for an account with no "
        "synced sleep data — this drives a 'View sleep' CTA to an empty "
        "Connect-Health screen."
    )


def test_fallback_still_picks_sleep_pillar_when_data_says_short_sleep():
    # Make sure the fix didn't break the real (connected, short-sleep) case.
    snapshot = _base_snapshot(sleep={"applicable": True, "target_hours": 8, "total_hours": 5})
    pillar = di._pick_fallback_pillar(snapshot)
    assert pillar == "sleep"


def test_sleep_fallback_cta_route_is_the_validated_one():
    route = di._FALLBACK_TEMPLATES["sleep"]["cta_primary"]["route"]
    assert route == "/health/sleep"
    assert route in di._VALID_ROUTES
