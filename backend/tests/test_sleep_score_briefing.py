"""
Unit tests for FEATURE 1 — the morning SLEEP-SCORE push.

Covers:
  * services.health_coaching.build_sleep_score_briefing
      - tone selection by band (HIGH / POOR-recovering / POOR-all)
      - the 60-79 mid-band defers (has_message False, reason mid_band_defer)
      - clean empty states (no data / no sleep / no score)
      - number integrity: the cited {score} is exactly the resolved score and
        no variant fabricates / alters a number
      - synced-score-first resolution, Python-port fallback when synced is None
      - wake-up count is never fabricated when absent
  * services.sleep_score.compute_sleep_score
      - parity with the Dart computeSleepScore new-user (no-consistency,
        renormalised) path
      - None when there are no asleep minutes

No network, no DB — pure-function tests over hand-built snapshot dicts.
"""
from datetime import date

import pytest

from services.health_coaching import build_sleep_score_briefing, _extract_numbers
from services.sleep_score import compute_sleep_score


# -----------------------------------------------------------------------------
# Snapshot fixtures — shaped exactly like get_health_activity_snapshot.
# -----------------------------------------------------------------------------

def _snapshot(
    *,
    sleep_score=None,
    total_minutes=480,
    is_stale=False,
    recovery_tier=None,
    wake_ups=None,
    efficiency=None,
    deep_minutes=0,
    rem_minutes=0,
    has_data=True,
    sleep_goal=480,
):
    """A has_data=True snapshot carrying only the fields the builder reads."""
    return {
        "has_data": has_data,
        "last_night_sleep": {
            "total_minutes": total_minutes,
            "is_stale": is_stale,
            "sleep_score": sleep_score,
            "wake_ups": wake_ups,
            "efficiency": efficiency,
            "deep_minutes": deep_minutes,
            "rem_minutes": rem_minutes,
        },
        "recovery": {"tier": recovery_tier},
        "goals": {"sleep_duration_goal_minutes": sleep_goal},
    }


_DAY = date(2026, 6, 4)


# -----------------------------------------------------------------------------
# Tone selection
# -----------------------------------------------------------------------------

class TestToneSelection:
    def test_high_score_celebrates(self):
        r = build_sleep_score_briefing(_snapshot(sleep_score=87, total_minutes=460, wake_ups=2), day=_DAY)
        assert r["has_message"] is True
        assert r["type"] == "sleep_score"
        assert r["pattern"] == "high"
        assert "87" in r["message"]

    def test_poor_but_recovering_reassures(self):
        # Poor score, but recovery tier 'moderate' => reassuring tone.
        r = build_sleep_score_briefing(
            _snapshot(sleep_score=42, total_minutes=320, recovery_tier="moderate"), day=_DAY
        )
        assert r["has_message"] is True
        assert r["pattern"] == "poor_recovering"

    @pytest.mark.parametrize("tier", ["good", "optimal"])
    def test_poor_with_good_recovery_still_reassures(self, tier):
        r = build_sleep_score_briefing(
            _snapshot(sleep_score=40, total_minutes=300, recovery_tier=tier), day=_DAY
        )
        assert r["pattern"] == "poor_recovering"

    @pytest.mark.parametrize("tier", ["compromised", "low", None])
    def test_poor_all_encourages(self, tier):
        r = build_sleep_score_briefing(
            _snapshot(sleep_score=33, total_minutes=300, recovery_tier=tier, wake_ups=6), day=_DAY
        )
        assert r["has_message"] is True
        assert r["pattern"] == "poor_all"
        assert "33" in r["message"]

    def test_high_boundary_80_is_high(self):
        r = build_sleep_score_briefing(_snapshot(sleep_score=80, total_minutes=470), day=_DAY)
        assert r["pattern"] == "high"

    def test_poor_boundary_59_is_poor(self):
        r = build_sleep_score_briefing(
            _snapshot(sleep_score=59, total_minutes=340, recovery_tier="low"), day=_DAY
        )
        assert r["pattern"] == "poor_all"


# -----------------------------------------------------------------------------
# Mid-band defer + empty states
# -----------------------------------------------------------------------------

class TestEmptyAndDefer:
    @pytest.mark.parametrize("score", [60, 65, 79])
    def test_mid_band_defers_to_readiness(self, score):
        r = build_sleep_score_briefing(_snapshot(sleep_score=score, total_minutes=420), day=_DAY)
        assert r["has_message"] is False
        assert r["reason"] == "mid_band_defer"

    def test_no_data_snapshot(self):
        r = build_sleep_score_briefing({"has_data": False, "reason": "no_consent"})
        assert r["has_message"] is False
        assert r["reason"] == "no_consent"

    def test_empty_snapshot(self):
        r = build_sleep_score_briefing({})
        assert r["has_message"] is False

    def test_no_sleep_row(self):
        snap = _snapshot(sleep_score=90)
        snap["last_night_sleep"] = None
        r = build_sleep_score_briefing(snap)
        assert r["has_message"] is False
        assert r["reason"] == "no_sleep"

    def test_zero_minutes_is_no_sleep(self):
        r = build_sleep_score_briefing(_snapshot(sleep_score=None, total_minutes=0))
        assert r["has_message"] is False
        assert r["reason"] == "no_sleep"

    def test_stale_sleep_is_no_sleep(self):
        r = build_sleep_score_briefing(_snapshot(sleep_score=88, total_minutes=480, is_stale=True))
        assert r["has_message"] is False
        assert r["reason"] == "no_sleep"


# -----------------------------------------------------------------------------
# Number integrity + score resolution
# -----------------------------------------------------------------------------

class TestNumberIntegrity:
    def test_synced_score_is_cited_verbatim(self):
        r = build_sleep_score_briefing(
            _snapshot(sleep_score=91, total_minutes=470, wake_ups=1), day=_DAY
        )
        assert r["facts"]["sleep_score"] == 91
        assert r["facts"]["score_source"] == "synced"
        # The exact score appears in the copy and the duration numbers are real.
        assert "91" in r["message"]

    def test_fallback_compute_when_synced_is_none(self):
        # No synced score => the Python port computes it from the snapshot.
        snap = _snapshot(
            sleep_score=None,
            total_minutes=300,
            recovery_tier="low",
            efficiency=0.70,
            deep_minutes=30,
            rem_minutes=30,
        )
        r = build_sleep_score_briefing(snap, day=_DAY)
        assert r["has_message"] is True
        assert r["facts"]["score_source"] == "fallback"
        computed = compute_sleep_score(
            asleep_minutes=300, goal_minutes=480, efficiency=0.70, deep_minutes=30, rem_minutes=30
        )
        assert r["facts"]["sleep_score"] == computed
        assert str(computed) in r["message"]

    def test_message_never_fabricates_a_number(self):
        # Every digit run in the message must be a fact we can justify:
        # the score, the wake-up count, the duration h/m, or '100' (out of 100).
        snap = _snapshot(sleep_score=35, total_minutes=305, recovery_tier="low", wake_ups=5)
        r = build_sleep_score_briefing(snap, day=_DAY)
        h, m = divmod(305, 60)
        allowed = {"35", "5", str(h), str(m), f"{m:02d}", "100"}
        for num in _extract_numbers(r["message"]):
            assert num in allowed, f"unexpected number {num} in {r['message']!r}"

    def test_wake_ups_never_fabricated_when_absent(self):
        # wake_ups is None => no variant that cites {wake_ups} may be chosen,
        # so the copy never claims a count that wasn't synced.
        for seed_day in range(date(2026, 6, 1).toordinal(), date(2026, 6, 8).toordinal()):
            r = build_sleep_score_briefing(
                _snapshot(sleep_score=30, total_minutes=290, recovery_tier="low", wake_ups=None),
                day=date.fromordinal(seed_day),
            )
            assert "{wake_ups}" not in r["message"]
            # With no synced count, the message must not assert "N wake-ups".
            assert "wake-ups" not in r["message"] or "few wake-ups" in r["message"]

    def test_same_day_is_stable_across_calls(self):
        a = build_sleep_score_briefing(_snapshot(sleep_score=88, total_minutes=470), day=_DAY)
        b = build_sleep_score_briefing(_snapshot(sleep_score=88, total_minutes=470), day=_DAY)
        assert a["message"] == b["message"]


# -----------------------------------------------------------------------------
# compute_sleep_score — Python-port parity with the Dart original
# -----------------------------------------------------------------------------

def _dart_reference(asleep, goal=480, eff=None, deep=0, rem=0):
    """Independent re-derivation of sleep_score.dart::computeSleepScore for the
    new-user (no consistency) renormalised total — the exact path the backend
    port mirrors."""
    dur_w, rst_w = 50.0, 25.0
    if asleep <= 0:
        return None
    g = goal if goal > 0 else 480
    if asleep >= g:
        ov = asleep - g
        if ov <= 90:
            dp = dur_w
        else:
            dp = dur_w * (1.0 - 0.2 * (min(max(ov - 90, 0), 180) / 180.0))
    else:
        dp = dur_w * (asleep / g)
    dp = min(max(dp, 0.0), dur_w)
    sp = (deep + rem) / asleep if asleep > 0 else 0.0
    stage = min(max(9.0 * (sp / 0.45), 0.0), 9.0)
    if eff is not None:
        en = min(max((eff - 0.5) / 0.45, 0.0), 1.0)
        rp = 16.0 * en + stage
    else:
        rp = min(max(rst_w * (sp / 0.45), 0.0), rst_w)
    rp = min(max(rp, 0.0), rst_w)
    raw, mx = dp + rp, dur_w + rst_w
    return int(min(max(round((raw / mx) * 100), 0), 100))


class TestComputeSleepScoreParity:
    @pytest.mark.parametrize(
        "asleep,goal,eff,deep,rem",
        [
            (480, 480, 0.92, 90, 100),   # on-goal, staged, efficient
            (300, 480, 0.70, 40, 50),    # short night
            (510, 480, None, 0, 0),      # slight overshoot, no eff/stages
            (650, 480, 0.95, 120, 140),  # large overshoot (penalty)
            (60, 480, 0.40, 5, 5),       # very short
            (420, 480, 0.88, 70, 90),    # just under goal
            (700, 480, 0.50, 0, 0),      # big overshoot, floor efficiency
        ],
    )
    def test_parity_with_dart(self, asleep, goal, eff, deep, rem):
        got = compute_sleep_score(
            asleep_minutes=asleep, goal_minutes=goal, efficiency=eff, deep_minutes=deep, rem_minutes=rem
        )
        assert got == _dart_reference(asleep, goal, eff, deep, rem)

    def test_zero_minutes_returns_none(self):
        assert compute_sleep_score(asleep_minutes=0) is None
        assert compute_sleep_score(asleep_minutes=-5) is None

    def test_goal_zero_defaults_to_480(self):
        assert compute_sleep_score(asleep_minutes=480, goal_minutes=0) == compute_sleep_score(
            asleep_minutes=480, goal_minutes=480
        )

    def test_no_efficiency_falls_back_to_stage_bonus(self):
        # With no efficiency, restfulness is the stage bonus scaled to 25.
        with_stages = compute_sleep_score(asleep_minutes=480, deep_minutes=120, rem_minutes=96)
        no_stages = compute_sleep_score(asleep_minutes=480, deep_minutes=0, rem_minutes=0)
        assert with_stages is not None and no_stages is not None
        assert with_stages > no_stages
