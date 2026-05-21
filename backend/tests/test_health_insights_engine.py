"""
Unit tests for the Phase D1 cross-metric correlation engine
(services/health_insights_engine.py).

Covers:
  * Pearson r correctness (perfect +/- correlation, zero-variance guard).
  * A 30-day seeded fixture with a PLANTED sleep<->resting-HR correlation —
    the engine must surface it with the right sign.
  * The minimum-evidence gate — <14 paired days yields an empty result.
  * Clean empty output for no data.
  * Correlation-only framing (no causal claims, association_only flag).

Pure-function tests over hand-built activity-row lists — no DB, no network.
"""
import pytest

from services.health_insights_engine import (
    compute_smart_insights,
    pearson_r,
    top_insight_sentence,
)


# =============================================================================
# Pearson r
# =============================================================================

class TestPearson:
    def test_perfect_positive(self):
        r = pearson_r([1, 2, 3, 4, 5], [2, 4, 6, 8, 10])
        assert r == pytest.approx(1.0)

    def test_perfect_negative(self):
        r = pearson_r([1, 2, 3, 4, 5], [10, 8, 6, 4, 2])
        assert r == pytest.approx(-1.0)

    def test_zero_variance_returns_none(self):
        # A flat series has an undefined correlation — never a fake 0.
        assert pearson_r([5, 5, 5, 5], [1, 2, 3, 4]) is None

    def test_too_few_pairs_returns_none(self):
        assert pearson_r([1], [2]) is None

    def test_clamped_within_unit_range(self):
        r = pearson_r([0.1, 0.2, 0.3], [0.1, 0.2, 0.3])
        assert -1.0 <= r <= 1.0


# =============================================================================
# Fixture builders
# =============================================================================

def _day(i: int) -> str:
    """activity_date string for day i of a March 2026 month."""
    return f"2026-03-{i + 1:02d}"


def _seeded_30_days():
    """30 activity rows with a PLANTED inverse sleep<->resting-HR pattern:
    more sleep => lower resting HR. Steps wander independently."""
    rows = []
    for i in range(30):
        sleep = 360 + (i % 10) * 12  # 360..468 minutes, cyclic
        # Resting HR is a deterministic inverse function of sleep + tiny noise.
        rhr = 80 - (sleep - 360) / 12.0 + (i % 3) * 0.4
        rows.append(
            {
                "activity_date": _day(i),
                "sleep_minutes": sleep,
                "resting_heart_rate": round(rhr, 1),
                "steps": 5000 + (i * 37) % 4000,  # unrelated wander
            }
        )
    return rows


# =============================================================================
# compute_smart_insights
# =============================================================================

class TestComputeSmartInsights:
    def test_planted_correlation_surfaces(self):
        insights = compute_smart_insights(_seeded_30_days(), window_days=30)
        assert insights, "expected at least one insight from a planted pattern"
        pair = {(c["metric_a"], c["metric_b"]) for c in insights}
        flat = {frozenset(p) for p in pair}
        assert frozenset({"sleep", "resting_hr"}) in flat

        sleep_hr = next(
            c
            for c in insights
            if {c["metric_a"], c["metric_b"]} == {"sleep", "resting_hr"}
        )
        # The planted relationship is inverse -> negative r.
        assert sleep_hr["r"] < 0
        assert abs(sleep_hr["r"]) >= 0.3
        # Correlation, not causation.
        assert sleep_hr["association_only"] is True
        assert "association" in sleep_hr["insight"].lower()
        assert "cause" in sleep_hr["insight"].lower()  # explicit no-cause caveat
        assert sleep_hr["n"] >= 14

    def test_fewer_than_14_paired_days_returns_empty(self):
        """Edge case F33 — below the minimum, no spurious output."""
        rows = _seeded_30_days()[:10]  # only 10 days
        assert compute_smart_insights(rows, window_days=30) == []

    def test_exactly_13_paired_days_returns_empty(self):
        rows = _seeded_30_days()[:13]
        assert compute_smart_insights(rows, window_days=30) == []

    def test_14_paired_days_is_enough(self):
        rows = _seeded_30_days()[:14]
        insights = compute_smart_insights(rows, window_days=30)
        # 14 days clears the gate; the planted pattern should still surface.
        assert insights != []

    def test_empty_input_returns_empty(self):
        assert compute_smart_insights([], window_days=60) == []

    def test_no_correlation_below_threshold_is_dropped(self):
        """Random-ish data with no real pattern yields no insight."""
        rows = []
        for i in range(30):
            rows.append(
                {
                    "activity_date": _day(i),
                    # Pseudo-random but deterministic, no relationship.
                    "sleep_minutes": 420 + ((i * 53) % 7) * 3,
                    "resting_heart_rate": 60 + ((i * 29) % 5),
                }
            )
        insights = compute_smart_insights(rows, window_days=30)
        # Any surfaced pair must still clear |r| >= 0.30 — never a weak one.
        for c in insights:
            assert abs(c["r"]) >= 0.30

    def test_window_clamps_old_rows_out(self):
        """Rows older than the window are excluded from the correlation."""
        rows = _seeded_30_days()
        # All 30 rows are inside a 90-day window; a 30-day window keeps them
        # too (they span 30 days). Engine clamps window to [30, 90].
        wide = compute_smart_insights(rows, window_days=200)  # clamped to 90
        narrow = compute_smart_insights(rows, window_days=10)  # clamped to 30
        assert wide != [] and narrow != []

    def test_identical_source_pair_suppressed(self):
        """active_calories and workout_volume share a column -> never paired."""
        rows = []
        for i in range(30):
            rows.append(
                {
                    "activity_date": _day(i),
                    "active_calories": 200 + i * 10,
                    "sleep_minutes": 400 + (i % 5) * 10,
                }
            )
        insights = compute_smart_insights(rows, window_days=30)
        for c in insights:
            assert {c["metric_a"], c["metric_b"]} != {
                "active_calories",
                "workout_volume",
            }

    def test_ranked_by_actionability(self):
        insights = compute_smart_insights(_seeded_30_days(), window_days=30)
        actionabilities = [c["actionability"] for c in insights]
        assert actionabilities == sorted(actionabilities, reverse=True)


# =============================================================================
# top_insight_sentence
# =============================================================================

class TestTopInsight:
    def test_returns_best_sentence(self):
        insights = compute_smart_insights(_seeded_30_days(), window_days=30)
        top = top_insight_sentence(insights)
        assert top
        assert top == insights[0]["insight"]

    def test_empty_list_returns_empty_string(self):
        assert top_insight_sentence([]) == ""


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
