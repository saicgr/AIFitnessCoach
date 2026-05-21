"""
Unit tests for the Phase C1 health coaching content engine
(services/health_coaching.py).

Covers pattern selection for every message type:
  * daily briefing — good night / poor night / no-sleep / no-data
  * health anomaly — RHR elevated / no baseline / within normal / no-data
  * activity nudge — behind / almost there / goal met / no-data

Plus the deterministic day-seeding and the Gemini-rephrase number-integrity
guard. No network, no DB — pure-function tests over hand-built snapshot dicts.
"""
import asyncio
from datetime import date

import pytest

from services.health_coaching import (
    build_daily_briefing,
    build_health_anomaly,
    build_activity_nudge,
    rephrase_with_gemini,
    _extract_numbers,
)


# -----------------------------------------------------------------------------
# Snapshot fixtures — minimal but shaped exactly like get_health_activity_snapshot.
# -----------------------------------------------------------------------------

def _snapshot(
    *,
    sleep_minutes=None,
    sleep_stale=False,
    recovery_score=None,
    recovery_adjustment=None,
    steps_today=None,
    step_goal=None,
    resting=None,
    baseline=None,
):
    """Build a has_data=True snapshot with only the fields a test needs."""
    last_night = None
    if sleep_minutes is not None:
        last_night = {
            "total_minutes": sleep_minutes,
            "is_stale": sleep_stale,
        }
    recovery = {
        "score": recovery_score,
        "tier": None,
        "volume_multiplier": None,
        "adjustment": recovery_adjustment,
    }
    delta = None
    if resting is not None and baseline is not None:
        delta = round(resting - baseline, 1)
    return {
        "has_data": True,
        "last_night_sleep": last_night,
        "recovery": recovery,
        "steps": {
            "today": steps_today,
            "avg_7d": None,
            "goal": step_goal,
            "goal_pct": None,
        },
        "heart_rate": {
            "resting": resting,
            "resting_baseline": baseline,
            "resting_vs_baseline": delta,
        },
    }


_DAY = date(2026, 5, 21)  # fixed seed day so variant choice is reproducible


# =============================================================================
# Daily briefing
# =============================================================================

class TestDailyBriefing:
    def test_good_night(self):
        snap = _snapshot(sleep_minutes=470, recovery_score=85)
        r = build_daily_briefing(snap, today_workout={"name": "Upper Body"}, day=_DAY)
        assert r["has_message"] is True
        assert r["pattern"] == "good_night"
        assert "85" in r["message"]
        assert "Upper Body" in r["message"]

    def test_poor_night(self):
        snap = _snapshot(
            sleep_minutes=240,  # 4h
            recovery_score=38,
            recovery_adjustment="-10% load, no failure/drop/AMRAP sets",
        )
        r = build_daily_briefing(snap, today_workout={"type": "strength"}, day=_DAY)
        assert r["has_message"] is True
        assert r["pattern"] == "poor_night"
        assert "38" in r["message"]
        # The concrete adjustment must surface in the message.
        assert "load" in r["message"].lower()

    def test_poor_night_low_recovery_overrides_long_sleep(self):
        """A long night but a poor recovery score still picks poor_night."""
        snap = _snapshot(sleep_minutes=460, recovery_score=44,
                         recovery_adjustment="longer rest, trim 1 accessory set")
        r = build_daily_briefing(snap, day=_DAY)
        assert r["pattern"] == "poor_night"

    def test_no_sleep_data_gives_lighter_briefing(self):
        """Edge case F31 — no sleep => activity-only briefing, never skipped."""
        snap = _snapshot(steps_today=3000)  # has_data True, but no sleep
        r = build_daily_briefing(snap, today_workout={"name": "Leg Day"}, day=_DAY)
        assert r["has_message"] is True
        assert r["pattern"] == "no_sleep"
        assert "Leg Day" in r["message"]

    def test_stale_sleep_treated_as_no_sleep(self):
        snap = _snapshot(sleep_minutes=420, sleep_stale=True)
        r = build_daily_briefing(snap, day=_DAY)
        assert r["pattern"] == "no_sleep"

    def test_no_data_returns_clean_empty(self):
        r = build_daily_briefing({"has_data": False, "reason": "no_consent"}, day=_DAY)
        assert r["has_message"] is False
        assert r["reason"] == "no_consent"

    def test_none_snapshot_is_clean_empty(self):
        r = build_daily_briefing(None, day=_DAY)
        assert r["has_message"] is False

    def test_day_seeding_is_stable_within_day_varies_across_days(self):
        snap = _snapshot(sleep_minutes=470, recovery_score=85)
        m1 = build_daily_briefing(snap, day=date(2026, 5, 21))["message"]
        m1b = build_daily_briefing(snap, day=date(2026, 5, 21))["message"]
        # Stable within a day.
        assert m1 == m1b
        # Across enough days the variant rotates (4 templates).
        variants = {
            build_daily_briefing(snap, day=date(2026, 5, 21 + i))["message"]
            for i in range(4)
        }
        assert len(variants) > 1

    def test_briefing_always_carries_brief_message(self):
        """Every pattern returns both a full message and a brief_message."""
        for snap, kwargs in (
            (_snapshot(sleep_minutes=470, recovery_score=85), {}),
            (_snapshot(sleep_minutes=240, recovery_score=38,
                       recovery_adjustment="-10% load"), {}),
            (_snapshot(steps_today=3000), {}),
        ):
            r = build_daily_briefing(snap, day=_DAY, **kwargs)
            assert r["has_message"] is True
            assert isinstance(r["message"], str) and r["message"]
            assert isinstance(r["brief_message"], str) and r["brief_message"]
            assert "domains" in r


# =============================================================================
# Phase E4 — cross-domain daily game plan
# =============================================================================

def _recovery_signal(
    *, tier="compromised", recovery_score=41, volume_multiplier=0.70,
    swap_to_mobility=False, applies=True,
):
    """Build a Phase-B3 get_recovery_workout_signal-shaped dict."""
    if not applies:
        return {"applies": False}
    return {
        "applies": True,
        "tier": tier,
        "recovery_score": recovery_score,
        "volume_multiplier": volume_multiplier,
        "adjustment": {
            "tier": tier,
            "recovery_score": recovery_score,
            "volume_multiplier": volume_multiplier,
            "swap_to_mobility": swap_to_mobility,
            "adjustment_text": "-10% load, no failure/drop/AMRAP sets",
        },
        "prompt_context": "...",
    }


def _nutrition_adjustment(
    *, reason="low_recovery", adjusted=True, protein_delta_g=15, tier="compromised",
):
    """Build a Phase-E1 adjust_targets_for_recovery-shaped dict."""
    return {
        "adjusted": adjusted,
        "reason": reason,
        "tier": tier,
        "targets": {"daily_protein_target_g": 165},
        "calorie_floored": False,
        "craving_heads_up": "...",
        "protein_delta_g": protein_delta_g,
    }


class TestCrossDomainGamePlan:
    def test_low_recovery_plan_names_all_three_domains(self):
        """A low-recovery user's briefing narrates sleep + workout + nutrition."""
        snap = _snapshot(sleep_minutes=300, recovery_score=41,
                         recovery_adjustment="-10% load")
        r = build_daily_briefing(
            snap,
            today_workout={"name": "Push Day", "status": "scheduled"},
            day=_DAY,
            recovery_signal=_recovery_signal(),
            nutrition_adjustment=_nutrition_adjustment(),
        )
        assert r["pattern"] == "poor_night"
        assert sorted(r["domains"]) == ["nutrition", "workout"]
        msg = r["message"]
        # Sleep domain — the recovery score is narrated.
        assert "41" in msg
        # Workout domain — a volume % is narrated (0.70x -> 30%).
        assert "30%" in msg
        # Nutrition domain — the protein delta is narrated.
        assert "15g" in msg
        # One concrete swap is appended.
        assert "coffee" in msg.lower() or "caffeine" in msg.lower()

    def test_brief_message_is_one_line_with_key_numbers(self):
        snap = _snapshot(sleep_minutes=300, recovery_score=41)
        r = build_daily_briefing(
            snap,
            today_workout={"name": "Push Day"},
            day=_DAY,
            recovery_signal=_recovery_signal(),
            nutrition_adjustment=_nutrition_adjustment(protein_delta_g=15),
        )
        brief = r["brief_message"]
        # Brief carries recovery + protein delta and is shorter than the full.
        assert "41" in brief
        assert "15g" in brief
        assert len(brief) < len(r["message"])
        assert "\n" not in brief

    def test_missing_nutrition_data_no_empty_section(self):
        """Edge case G38 — no nutrition data => plan covers only the domains
        with data, no empty section."""
        snap = _snapshot(sleep_minutes=300, recovery_score=41)
        r = build_daily_briefing(
            snap,
            today_workout={"name": "Push Day"},
            day=_DAY,
            recovery_signal=_recovery_signal(),
            nutrition_adjustment=None,
        )
        assert r["domains"] == ["workout"]
        msg = r["message"].lower()
        # No nutrition wording leaks in.
        assert "protein" not in msg
        # Workout section is still present.
        assert "30%" in r["message"]

    def test_missing_workout_data_no_empty_section(self):
        """No scheduled workout / no recovery signal => no workout section."""
        snap = _snapshot(sleep_minutes=300, recovery_score=41)
        r = build_daily_briefing(
            snap,
            today_workout=None,
            day=_DAY,
            recovery_signal=_recovery_signal(applies=False),
            nutrition_adjustment=_nutrition_adjustment(),
        )
        assert r["domains"] == ["nutrition"]
        assert "15g" in r["message"]

    def test_no_upstream_adjustments_falls_back_to_sleep_readout(self):
        """Neither domain has an adjustment => plain poor-night readout, and
        brief == full."""
        snap = _snapshot(sleep_minutes=300, recovery_score=41,
                         recovery_adjustment="-10% load")
        r = build_daily_briefing(
            snap,
            today_workout={"name": "Push Day"},
            day=_DAY,
            recovery_signal=None,
            nutrition_adjustment=None,
        )
        assert r["domains"] == []
        assert r["pattern"] == "poor_night"
        assert r["message"] == r["brief_message"]
        assert "41" in r["message"]

    def test_manually_started_workout_is_not_re_planned(self):
        """Edge case G38 — a workout already started/completed is acknowledged,
        never narrated as a prospective trim."""
        snap = _snapshot(sleep_minutes=300, recovery_score=41)
        for workout in (
            {"name": "Push Day", "status": "in_progress"},
            {"name": "Push Day", "is_completed": True},
        ):
            r = build_daily_briefing(
                snap,
                today_workout=workout,
                day=_DAY,
                recovery_signal=_recovery_signal(),
                nutrition_adjustment=_nutrition_adjustment(),
            )
            # The workout domain is still acknowledged...
            assert "workout" in r["domains"]
            # ...but no prospective "trimmed 30%" claim is made.
            assert "30%" not in r["message"]
            assert "underway" in r["message"].lower()

    def test_mobility_swap_workout_narration(self):
        """A low-tier mobility swap is narrated as a mobility day, not a %."""
        snap = _snapshot(sleep_minutes=240, recovery_score=22)
        r = build_daily_briefing(
            snap,
            today_workout={"name": "Leg Day"},
            day=_DAY,
            recovery_signal=_recovery_signal(
                tier="low", recovery_score=22, volume_multiplier=0.55,
                swap_to_mobility=True,
            ),
            nutrition_adjustment=_nutrition_adjustment(tier="low",
                                                       protein_delta_g=22),
        )
        assert "workout" in r["domains"]
        assert "mobility" in r["message"].lower()

    def test_nutrition_timing_only_when_no_protein_target(self):
        """A low-recovery nutrition adjustment with reason=low_recovery but
        adjusted=False (no protein target) still narrates timing guidance."""
        snap = _snapshot(sleep_minutes=300, recovery_score=41)
        r = build_daily_briefing(
            snap,
            today_workout=None,
            day=_DAY,
            recovery_signal=_recovery_signal(applies=False),
            nutrition_adjustment=_nutrition_adjustment(
                adjusted=False, protein_delta_g=0,
            ),
        )
        assert r["domains"] == ["nutrition"]
        # No fabricated protein number; timing guidance instead.
        assert "+0g" not in r["message"]
        assert (
            "calorie" in r["message"].lower()
            or "protein" in r["message"].lower()
        )

    def test_good_night_has_no_game_plan(self):
        """A good night never produces a cross-domain plan even if signals are
        passed (they would not apply on a good night)."""
        snap = _snapshot(sleep_minutes=470, recovery_score=85)
        r = build_daily_briefing(
            snap,
            today_workout={"name": "Upper Body"},
            day=_DAY,
            recovery_signal=_recovery_signal(applies=False),
            nutrition_adjustment=_nutrition_adjustment(reason="recovery_ok",
                                                       adjusted=False),
        )
        assert r["pattern"] == "good_night"
        assert r["domains"] == []
        assert r["message"] == r["brief_message"]


# =============================================================================
# Health anomaly
# =============================================================================

class TestHealthAnomaly:
    def test_rhr_elevated_fires(self):
        snap = _snapshot(resting=68, baseline=58)  # +10 bpm
        r = build_health_anomaly(snap, day=_DAY)
        assert r["has_message"] is True
        assert r["pattern"] == "rhr_elevated"
        assert "68" in r["message"] and "58" in r["message"]
        # Never diagnoses.
        assert "diagnos" not in r["message"].lower() or "not a diagnosis" in r["message"].lower()

    def test_no_baseline_returns_clean_empty(self):
        """Edge case F30 — no >=14-day baseline => cannot judge elevation."""
        snap = _snapshot(resting=68, baseline=None)
        r = build_health_anomaly(snap, day=_DAY)
        assert r["has_message"] is False
        assert r["reason"] == "no_baseline"

    def test_within_normal_does_not_fire(self):
        snap = _snapshot(resting=60, baseline=58)  # +2 bpm, below threshold
        r = build_health_anomaly(snap, day=_DAY)
        assert r["has_message"] is False
        assert r["reason"] == "within_normal"

    def test_no_data_returns_clean_empty(self):
        r = build_health_anomaly({"has_data": False, "reason": "no_activity_data"})
        assert r["has_message"] is False


# =============================================================================
# Activity nudge
# =============================================================================

class TestActivityNudge:
    def test_behind_on_steps(self):
        snap = _snapshot(steps_today=3000, step_goal=10000)
        r = build_activity_nudge(snap, day=_DAY)
        assert r["has_message"] is True
        assert r["pattern"] == "behind"
        assert r["facts"]["remaining"] == 7000

    def test_almost_there(self):
        snap = _snapshot(steps_today=8500, step_goal=10000)  # 85%
        r = build_activity_nudge(snap, day=_DAY)
        assert r["pattern"] == "almost_there"

    def test_goal_met_congratulates(self):
        snap = _snapshot(steps_today=11000, step_goal=10000)
        r = build_activity_nudge(snap, day=_DAY)
        assert r["pattern"] == "goal_met"
        assert r["facts"]["remaining"] == 0

    def test_goalless_user_gets_default_goal(self):
        snap = _snapshot(steps_today=2000, step_goal=None)
        r = build_activity_nudge(snap, day=_DAY)
        assert r["has_message"] is True
        assert r["facts"]["goal_used_default"] is True

    def test_no_steps_data_returns_clean_empty(self):
        snap = _snapshot(steps_today=None)
        r = build_activity_nudge(snap, day=_DAY)
        assert r["has_message"] is False
        assert r["reason"] == "no_steps_data"

    def test_no_data_returns_clean_empty(self):
        r = build_activity_nudge({"has_data": False, "reason": "no_consent"})
        assert r["has_message"] is False


# =============================================================================
# Gemini rephrase guard
# =============================================================================

class _FakeGemini:
    def __init__(self, reply):
        self._reply = reply

    async def chat(self, user_message=None):
        return self._reply


class _BrokenGemini:
    async def chat(self, user_message=None):
        raise RuntimeError("boom")


class TestRephraseGuard:
    def test_accepts_rephrase_with_identical_numbers(self):
        draft = "You slept 7h30m and recovery is 85/100."
        good = "Nice — 7h30m of sleep, recovery sitting at 85/100."
        out = asyncio.run(rephrase_with_gemini(draft, _FakeGemini(good)))
        assert out == good

    def test_rejects_rephrase_that_changes_a_number(self):
        draft = "You slept 7h30m and recovery is 85/100."
        bad = "Nice — 8h of sleep, recovery sitting at 90/100."
        out = asyncio.run(rephrase_with_gemini(draft, _FakeGemini(bad)))
        assert out == draft  # falls back to the deterministic draft

    def test_rejects_rephrase_that_drops_a_number(self):
        draft = "Steps today: 8,000 of a 10,000 goal."
        bad = "You're making good progress on your step goal today."
        out = asyncio.run(rephrase_with_gemini(draft, _FakeGemini(bad)))
        assert out == draft

    def test_empty_response_falls_back_to_draft(self):
        draft = "Recovery is 60/100 today."
        out = asyncio.run(rephrase_with_gemini(draft, _FakeGemini("")))
        assert out == draft

    def test_gemini_error_falls_back_to_draft(self):
        draft = "Recovery is 60/100 today."
        out = asyncio.run(rephrase_with_gemini(draft, _BrokenGemini()))
        assert out == draft

    def test_none_service_returns_draft(self):
        draft = "Recovery is 60/100 today."
        out = asyncio.run(rephrase_with_gemini(draft, None))
        assert out == draft

    def test_extract_numbers_helper(self):
        assert sorted(_extract_numbers("7h30m and 85/100")) == sorted(
            ["7", "30", "85", "100"]
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
