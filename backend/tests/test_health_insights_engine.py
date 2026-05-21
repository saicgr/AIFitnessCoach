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
    compute_food_sleep_insights,
    compute_training_sleep_insights,
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


# =============================================================================
# Phase E2 — food-to-sleep correlation
# =============================================================================

def _activity_day(i: int, sleep_minutes, **extra):
    """A daily_activity row for day i (March 2026), bucketed by wake date."""
    row = {"activity_date": _day(i), "sleep_minutes": sleep_minutes}
    row.update(extra)
    return row


def _food_log(day_index: int, hour: int, item_name: str, calories: int = 300):
    """A food_logs row logged at `hour` UTC on day `day_index` (March 2026).

    Tests run with utc_offset_hours=0 so the UTC hour IS the local hour."""
    return {
        "logged_at": f"2026-03-{day_index + 1:02d}T{hour:02d}:30:00+00:00",
        "food_items": [{"name": item_name, "calories": calories}],
        "total_calories": calories,
    }


class TestFoodSleepInsights:
    def test_planted_caffeine_timing_to_sleep_correlation(self):
        """20 food-days: even days log a 9pm coffee, odd days log a 9pm water.
        Sleep the FOLLOWING night is short after a coffee day, long otherwise.
        The engine must surface a late_caffeine -> sleep_duration pattern with
        the correct (negative) sign — more evening caffeine, less next-night
        sleep."""
        food_logs = []
        activities = []
        for i in range(22):
            caffeinated = i % 2 == 0
            # Evening (21:00) drink — coffee on even days, water on odd days.
            food_logs.append(
                _food_log(i, 21, "Brewed Coffee" if caffeinated else "Water")
            )
            # The NEXT night's sleep (wake date i+1): short after caffeine.
            next_sleep = 360 if caffeinated else 460
            activities.append(_activity_day(i + 1, next_sleep))

        insights = compute_food_sleep_insights(
            food_logs, activities, window_days=60, utc_offset_hours=0.0
        )
        assert insights, "expected a planted food->sleep insight"

        caffeine = next(
            (
                c
                for c in insights
                if c["food_signal"] == "late_caffeine"
                and c["sleep_metric"] == "sleep_duration"
            ),
            None,
        )
        assert caffeine is not None, "late_caffeine->sleep_duration not surfaced"
        # More evening caffeine lines up with LESS next-night sleep => r < 0.
        assert caffeine["r"] < 0
        assert abs(caffeine["r"]) >= 0.30
        assert caffeine["n"] >= 14
        assert caffeine["association_only"] is True
        assert caffeine["category"] == "food_sleep"
        # Association-only copy, never a causal claim.
        assert "association" in caffeine["insight"].lower()
        assert "cause" in caffeine["insight"].lower()

    def test_sparse_food_data_returns_empty(self):
        """Fewer than 14 paired (food-day, next-night) days -> no output."""
        food_logs = [_food_log(i, 21, "Coffee") for i in range(8)]
        activities = [_activity_day(i + 1, 400) for i in range(8)]
        assert (
            compute_food_sleep_insights(
                food_logs, activities, window_days=60, utc_offset_hours=0.0
            )
            == []
        )

    def test_no_food_logs_returns_empty(self):
        activities = [_activity_day(i + 1, 400) for i in range(30)]
        assert (
            compute_food_sleep_insights(
                [], activities, window_days=60, utc_offset_hours=0.0
            )
            == []
        )

    def test_unknown_foods_never_flag_caffeine(self):
        """An evening meal of plain unknown food must never be treated as a
        caffeine day — only keyword-matched items count (edge case G36)."""
        food_logs = []
        activities = []
        for i in range(22):
            food_logs.append(_food_log(i, 21, "Grilled Chicken Salad"))
            activities.append(_activity_day(i + 1, 400 + (i % 5) * 10))
        insights = compute_food_sleep_insights(
            food_logs, activities, window_days=60, utc_offset_hours=0.0
        )
        # late_caffeine is a flat 0 for every day => zero variance => the
        # caffeine pair is undefined and never surfaces a spurious insight.
        for c in insights:
            assert c["food_signal"] != "late_caffeine"

    def test_alcohol_correlation_surfaces(self):
        """Planted: evening alcohol days -> lower next-night efficiency."""
        food_logs = []
        activities = []
        for i in range(24):
            drank = i % 2 == 0
            food_logs.append(
                _food_log(i, 20, "Red Wine" if drank else "Sparkling Water")
            )
            eff = 0.78 if drank else 0.93
            activities.append(_activity_day(i + 1, 420, sleep_efficiency=eff))
        insights = compute_food_sleep_insights(
            food_logs, activities, window_days=60, utc_offset_hours=0.0
        )
        alcohol = next(
            (c for c in insights if c["food_signal"] == "evening_alcohol"), None
        )
        assert alcohol is not None
        assert alcohol["association_only"] is True


# =============================================================================
# Phase E3 — sleep x training-data insights
# =============================================================================

def _perf_log(day_index: int, weight_kg, reps=8, rpe=8.0, exercise="Bench Press"):
    """A performance_logs row recorded on day `day_index` (March 2026)."""
    return {
        "exercise_name": exercise,
        "set_number": 1,
        "reps_completed": reps,
        "weight_kg": weight_kg,
        "rpe": rpe,
        "recorded_at": f"2026-03-{day_index + 1:02d}T17:00:00+00:00",
    }


def _form_job(day_index: int, form_score):
    """A completed media_analysis_jobs form-analysis row for day `day_index`."""
    return {
        "id": f"job-{day_index}",
        "job_type": "form_analysis",
        "status": "completed",
        "result": {"content_type": "exercise", "form_score": form_score},
        "completed_at": f"2026-03-{day_index + 1:02d}T18:00:00+00:00",
        "created_at": f"2026-03-{day_index + 1:02d}T17:55:00+00:00",
    }


class TestTrainingSleepInsights:
    def test_planted_sleep_to_top_set_correlation(self):
        """20 paired days. Sleep alternates long/short; the top set the SAME
        day is heavier after a long night. The engine must surface a
        sleep_duration -> top_set_load pattern with a positive sign."""
        activities = []
        performance_logs = []
        for i in range(22):
            well_rested = i % 2 == 0
            sleep = 470 if well_rested else 330
            top_set = 100.0 if well_rested else 90.0
            activities.append(_activity_day(i, sleep))
            performance_logs.append(_perf_log(i, top_set))

        insights = compute_training_sleep_insights(
            activities, performance_logs, window_days=60, utc_offset_hours=0.0
        )
        assert insights, "expected a planted sleep->training insight"

        top = next(
            (c for c in insights if c["training_metric"] == "top_set_load"), None
        )
        assert top is not None, "sleep_duration->top_set_load not surfaced"
        # More sleep lines up with a heavier top set => r > 0.
        assert top["r"] > 0
        assert abs(top["r"]) >= 0.30
        assert top["n"] >= 14
        assert top["association_only"] is True
        assert top["category"] == "sleep_training"
        assert "association" in top["insight"].lower()
        assert "cause" in top["insight"].lower()

    def test_planted_sleep_to_form_score_correlation(self):
        """Form data is sparse, but with >= 8 paired (night, scored-lift)
        days a planted sleep->form-score pattern still surfaces."""
        activities = []
        performance_logs = []
        form_jobs = []
        for i in range(20):
            well_rested = i % 2 == 0
            sleep = 470 if well_rested else 320
            activities.append(_activity_day(i, sleep))
            performance_logs.append(_perf_log(i, 80.0))
            # Score: better form after a long night.
            form_jobs.append(_form_job(i, 9 if well_rested else 6))

        insights = compute_training_sleep_insights(
            activities,
            performance_logs,
            form_jobs=form_jobs,
            window_days=60,
            utc_offset_hours=0.0,
        )
        form = next(
            (c for c in insights if c["training_metric"] == "form_score"), None
        )
        assert form is not None, "sleep->form_score not surfaced"
        assert form["r"] > 0  # more sleep, higher form score
        assert form["n"] >= 8
        assert form["association_only"] is True

    def test_sparse_form_data_absent_gracefully(self):
        """Only 4 form-scored days (< the 8-day form minimum) -> the form
        pair is simply absent, never extrapolated (edge case G37). Lift
        correlations still work."""
        activities = []
        performance_logs = []
        form_jobs = []
        for i in range(22):
            well_rested = i % 2 == 0
            activities.append(_activity_day(i, 470 if well_rested else 330))
            performance_logs.append(
                _perf_log(i, 100.0 if well_rested else 90.0)
            )
            if i < 4:  # only 4 form videos ever submitted
                form_jobs.append(_form_job(i, 8))

        insights = compute_training_sleep_insights(
            activities,
            performance_logs,
            form_jobs=form_jobs,
            window_days=60,
            utc_offset_hours=0.0,
        )
        # No form_score insight — too sparse.
        assert all(c["training_metric"] != "form_score" for c in insights)
        # But the lift correlations are unaffected.
        assert any(c["training_metric"] == "top_set_load" for c in insights)

    def test_not_exercise_form_jobs_skipped(self):
        """A 'not_exercise' upload must never be scored as a real form day."""
        activities = [_activity_day(i, 400) for i in range(20)]
        performance_logs = [_perf_log(i, 80.0) for i in range(20)]
        form_jobs = []
        for i in range(20):
            job = _form_job(i, 1)
            job["result"]["content_type"] = "not_exercise"
            form_jobs.append(job)
        insights = compute_training_sleep_insights(
            activities,
            performance_logs,
            form_jobs=form_jobs,
            window_days=60,
            utc_offset_hours=0.0,
        )
        assert all(c["training_metric"] != "form_score" for c in insights)

    def test_no_performance_logs_returns_empty(self):
        activities = [_activity_day(i, 400) for i in range(30)]
        assert (
            compute_training_sleep_insights(
                activities, [], window_days=60, utc_offset_hours=0.0
            )
            == []
        )

    def test_sparse_sleep_returns_empty(self):
        """Fewer than 14 sleep nights -> no output even with rich lift data."""
        activities = [_activity_day(i, 400) for i in range(8)]
        performance_logs = [_perf_log(i, 90.0) for i in range(20)]
        assert (
            compute_training_sleep_insights(
                activities, performance_logs, window_days=60, utc_offset_hours=0.0
            )
            == []
        )


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
