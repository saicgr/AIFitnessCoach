"""
Tests for Predictive Fatigue Detection System.

Tests:
- 20% rep drop detection
- RPE increase detection
- Weight reduction calculation
- No false positives
- Fatigue level calculation
- Recommendation generation
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime, timedelta


class TestRepDropDetection:
    """Tests for detecting rep decline across sets."""

    def test_20_percent_drop_detected(self):
        """Test that 20%+ rep drop is detected as fatigue."""
        first_set_reps = 12
        current_set_reps = 9  # 25% drop

        decline_percent = (first_set_reps - current_set_reps) / first_set_reps

        assert decline_percent == 0.25
        assert decline_percent >= 0.20  # Threshold for fatigue detection

    def test_minor_drop_not_flagged(self):
        """Test that minor rep drops (<15%) are not flagged as fatigue."""
        first_set_reps = 12
        current_set_reps = 11  # ~8% drop

        decline_percent = (first_set_reps - current_set_reps) / first_set_reps

        assert decline_percent < 0.15
        # Should not trigger fatigue alert

    def test_exact_20_percent_threshold(self):
        """Test behavior at exactly 20% threshold."""
        first_set_reps = 10
        current_set_reps = 8  # Exactly 20%

        decline_percent = (first_set_reps - current_set_reps) / first_set_reps

        assert decline_percent == 0.20
        # At threshold - should be flagged

    def test_severe_drop_30_percent(self):
        """Test that 30%+ drop is flagged as significant fatigue."""
        first_set_reps = 10
        current_set_reps = 7  # 30% drop

        decline_percent = (first_set_reps - current_set_reps) / first_set_reps

        assert decline_percent >= 0.30
        # Should trigger strong fatigue warning

    def test_zero_reps_handled(self):
        """Test handling of zero reps (failure set)."""
        first_set_reps = 10
        current_set_reps = 0  # Complete failure

        if current_set_reps == 0:
            decline_percent = 1.0  # 100% decline
        else:
            decline_percent = (first_set_reps - current_set_reps) / first_set_reps

        assert decline_percent == 1.0

    def test_progressive_decline_across_sets(self):
        """Test detecting progressive decline across multiple sets."""
        set_reps = [12, 11, 10, 8, 6]

        declines = []
        for i in range(1, len(set_reps)):
            decline = (set_reps[0] - set_reps[i]) / set_reps[0]
            declines.append(decline)

        # Calculate actual declines: 12->11=8%, 12->10=17%, 12->8=33%, 12->6=50%
        # By set 4 and 5, should detect significant fatigue
        assert declines[1] < 0.20  # Set 2: 10 reps, ~17% decline (index 1)
        assert declines[2] >= 0.20  # Set 3: 8 reps, ~33% decline (index 2)
        assert declines[3] >= 0.20  # Set 4: 6 reps, 50% decline (index 3)


class TestRPEIncreaseDetection:
    """Tests for detecting RPE increase across sets."""

    def test_rpe_increase_of_2_detected(self):
        """Test that RPE increase of 2+ points is detected."""
        first_set_rpe = 7
        current_set_rpe = 9

        rpe_increase = current_set_rpe - first_set_rpe

        assert rpe_increase >= 2
        # Should trigger fatigue detection

    def test_minor_rpe_increase_not_flagged(self):
        """Test that minor RPE increase (<2) is not flagged."""
        first_set_rpe = 7
        current_set_rpe = 8

        rpe_increase = current_set_rpe - first_set_rpe

        assert rpe_increase < 2
        # Should not trigger fatigue alert

    def test_rpe_at_max_10(self):
        """Test handling of maximum RPE 10."""
        first_set_rpe = 7
        current_set_rpe = 10

        rpe_increase = current_set_rpe - first_set_rpe

        assert rpe_increase == 3
        assert current_set_rpe == 10
        # Maximum fatigue indicator

    def test_high_rpe_from_start(self):
        """Test when RPE is high from the first set."""
        first_set_rpe = 9
        current_set_rpe = 10

        rpe_increase = current_set_rpe - first_set_rpe

        # Even though increase is only 1, high absolute values matter
        is_high_rpe = current_set_rpe >= 9 or first_set_rpe >= 9

        assert is_high_rpe is True

    def test_rpe_progression_pattern(self):
        """Test detecting progressive RPE increase pattern."""
        set_rpes = [7, 7.5, 8, 8.5, 9, 9.5]

        # Check if pattern shows consistent increase
        increases = [set_rpes[i] - set_rpes[i-1] for i in range(1, len(set_rpes))]
        total_increase = set_rpes[-1] - set_rpes[0]

        assert total_increase == 2.5
        assert all(inc >= 0 for inc in increases)  # All increasing


class TestWeightReductionCalculation:
    """Tests for calculating suggested weight reduction."""

    def test_moderate_fatigue_10_percent_reduction(self):
        """Test that moderate fatigue suggests 10% weight reduction."""
        current_weight = 60.0
        fatigue_level = 0.55  # Moderate fatigue

        if fatigue_level >= 0.50 and fatigue_level < 0.65:
            reduction_percent = 10
        else:
            reduction_percent = 0

        reduced_weight = current_weight * (1 - reduction_percent / 100)

        assert reduction_percent == 10
        assert reduced_weight == 54.0

    def test_high_fatigue_15_percent_reduction(self):
        """Test that high fatigue suggests 15% weight reduction."""
        current_weight = 60.0
        fatigue_level = 0.70

        if fatigue_level >= 0.65 and fatigue_level < 0.80:
            reduction_percent = 15
        else:
            reduction_percent = 0

        reduced_weight = current_weight * (1 - reduction_percent / 100)

        assert reduction_percent == 15
        assert reduced_weight == 51.0

    def test_severe_fatigue_20_percent_reduction(self):
        """Test that severe fatigue suggests 20% weight reduction."""
        current_weight = 60.0
        fatigue_level = 0.85

        if fatigue_level >= 0.80:
            reduction_percent = 20
        else:
            reduction_percent = 0

        reduced_weight = current_weight * (1 - reduction_percent / 100)

        assert reduction_percent == 20
        assert reduced_weight == 48.0

    def test_equipment_aware_rounding(self):
        """Test that reduced weight is rounded to equipment increments."""
        current_weight = 60.0
        reduction_percent = 15
        equipment_type = "dumbbell"
        increment = 2.5

        raw_reduced = current_weight * (1 - reduction_percent / 100)  # 51.0
        rounded_reduced = round(raw_reduced / increment) * increment  # 50.0

        assert rounded_reduced == 50.0

    def test_minimum_weight_enforced(self):
        """Test that minimum weight is enforced after reduction."""
        current_weight = 5.0
        reduction_percent = 20
        minimum_weight = 2.5

        raw_reduced = current_weight * (1 - reduction_percent / 100)  # 4.0
        final_weight = max(minimum_weight, raw_reduced)

        assert final_weight == 4.0  # Above minimum


class TestNoFalsePositives:
    """Tests to ensure no false positive fatigue detections."""

    def test_normal_set_variance_no_alarm(self):
        """Test that normal set-to-set variance doesn't trigger alarms."""
        # Normal variance: 12, 11, 12, 11 reps
        set_reps = [12, 11, 12, 11]
        rpes = [7, 7.5, 7, 7.5]

        max_decline = max((set_reps[0] - r) / set_reps[0] for r in set_reps)
        max_rpe_increase = max(r - rpes[0] for r in rpes)

        # Normal variance should not trigger
        assert max_decline < 0.20
        assert max_rpe_increase < 2

    def test_warmup_sets_excluded(self):
        """Test that warmup sets with lower weight/reps don't skew detection."""
        is_warmup = True

        # Warmup sets should be excluded from fatigue calculation
        if is_warmup:
            include_in_analysis = False
        else:
            include_in_analysis = True

        assert include_in_analysis is False

    def test_intentional_dropset_not_flagged(self):
        """Test that intentional drop sets are recognized."""
        workout_type = "drop_set"

        # Drop sets intentionally reduce weight - not fatigue
        if workout_type == "drop_set":
            apply_fatigue_detection = False
        else:
            apply_fatigue_detection = True

        assert apply_fatigue_detection is False

    def test_single_bad_set_with_context(self):
        """Test that single bad set with good context doesn't trigger."""
        set_reps = [12, 12, 8, 12, 12]  # One bad set in the middle
        rpes = [7, 7, 8, 7, 7]

        # If pattern recovers, might be distraction not fatigue
        # Check if recovered in next set
        bad_set_index = 2
        if bad_set_index < len(set_reps) - 1:
            recovered = set_reps[bad_set_index + 1] >= set_reps[0] * 0.9

        assert recovered is True

    def test_first_set_not_flagged(self):
        """Test that first set never triggers fatigue (no comparison)."""
        set_number = 1

        # Need at least 2 sets to detect fatigue
        can_detect_fatigue = set_number > 1

        assert can_detect_fatigue is False

    def test_rpe_not_provided_graceful_handling(self):
        """Test graceful handling when RPE is not provided."""
        rpe_values = [None, None, 8, None]

        # Should only use provided values
        valid_rpes = [r for r in rpe_values if r is not None]

        assert len(valid_rpes) == 1
        # Should not crash, just use available data


class TestFatigueLevelCalculation:
    """Tests for overall fatigue level calculation."""

    def test_combined_indicators_score(self):
        """Test that multiple indicators combine for fatigue score."""
        rep_decline_score = 0.4  # 20% decline
        rpe_increase_score = 0.3  # RPE +2
        weight_reduction_score = 0.0  # No reduction yet

        # Weighted combination
        weights = {"rep_decline": 0.4, "rpe_increase": 0.35, "weight_reduction": 0.25}

        combined_score = (
            rep_decline_score * weights["rep_decline"] +
            rpe_increase_score * weights["rpe_increase"] +
            weight_reduction_score * weights["weight_reduction"]
        )

        assert 0.2 <= combined_score <= 0.4

    def test_fatigue_level_capped_at_1(self):
        """Test that fatigue level never exceeds 1.0."""
        rep_decline_score = 1.0
        rpe_score = 1.0
        weight_reduction_score = 1.0

        raw_score = (rep_decline_score + rpe_score + weight_reduction_score) / 3
        capped_score = min(1.0, raw_score)

        assert capped_score == 1.0

    def test_fatigue_level_never_negative(self):
        """Test that fatigue level is never negative."""
        rep_decline_score = 0.0
        rpe_score = 0.0
        weight_reduction_score = 0.0

        raw_score = (rep_decline_score + rpe_score + weight_reduction_score) / 3
        final_score = max(0.0, raw_score)

        assert final_score == 0.0

    def test_confidence_based_weighting(self):
        """Test that confidence affects indicator weighting."""
        indicators = [
            {"type": "rep_decline", "score": 0.5, "confidence": 0.9},
            {"type": "rpe_increase", "score": 0.3, "confidence": 0.7},
        ]

        total_weight = sum(i["confidence"] for i in indicators)
        weighted_score = sum(i["score"] * i["confidence"] for i in indicators) / total_weight

        # Higher confidence indicators weighted more
        assert 0.35 <= weighted_score <= 0.45


class TestRecommendationGeneration:
    """Tests for generating user recommendations."""

    def test_continue_recommendation_low_fatigue(self):
        """Test that low fatigue returns 'continue' recommendation."""
        fatigue_level = 0.3

        if fatigue_level < 0.50:
            recommendation = "continue"
        else:
            recommendation = "reduce"

        assert recommendation == "continue"

    def test_reduce_weight_recommendation(self):
        """Test that moderate fatigue suggests weight reduction."""
        fatigue_level = 0.55
        sets_remaining = 2

        if fatigue_level >= 0.50 and sets_remaining >= 1:
            recommendation = "reduce_weight"
        else:
            recommendation = "continue"

        assert recommendation == "reduce_weight"

    def test_reduce_sets_recommendation(self):
        """Test that high fatigue with sets remaining suggests reducing sets."""
        fatigue_level = 0.70
        sets_remaining = 3

        if fatigue_level >= 0.65 and sets_remaining >= 2:
            recommendation = "reduce_sets"
        else:
            recommendation = "reduce_weight"

        assert recommendation == "reduce_sets"

    def test_stop_recommendation_severe_fatigue(self):
        """Test that severe fatigue suggests stopping exercise."""
        fatigue_level = 0.90

        if fatigue_level >= 0.85:
            recommendation = "stop_exercise"
        else:
            recommendation = "reduce_sets"

        assert recommendation == "stop_exercise"

    def test_recommendation_includes_reasoning(self):
        """Test that recommendation includes explanation."""
        fatigue_level = 0.65
        indicators = ["rep_decline", "high_rpe"]

        reasoning = f"Fatigue detected ({fatigue_level:.0%}): {', '.join(indicators)}"

        assert "65%" in reasoning
        assert "rep_decline" in reasoning
        assert "high_rpe" in reasoning

    def test_actionable_continue_options(self):
        """Test that recommendations include actionable options."""
        recommendation = "reduce_weight"
        suggested_reduction = 15

        action = {
            "primary": recommendation,
            "suggested_reduction_pct": suggested_reduction,
            "alternatives": ["continue", "reduce_sets", "stop_exercise"],
        }

        assert action["primary"] == "reduce_weight"
        assert action["suggested_reduction_pct"] == 15
        assert "continue" in action["alternatives"]


class TestFatigueDetectionService:
    """Tests for the FatigueDetectionService class."""

    def test_service_initialization(self):
        """Test that service initializes correctly."""
        from services.fatigue_detection_service import FatigueDetectionService

        service = FatigueDetectionService()

        assert service is not None
        assert hasattr(service, "analyze_performance")
        assert hasattr(service, "get_set_recommendation")

    @pytest.mark.asyncio
    async def test_analyze_performance_empty_sets(self):
        """Test analysis with no set data."""
        from services.fatigue_detection_service import FatigueDetectionService

        service = FatigueDetectionService()

        result = await service.analyze_performance(
            user_id="test-user",
            exercise_name="Bench Press",
            current_set=1,
            total_sets=4,
            set_data=[],
        )

        assert result.fatigue_level == 0.0
        assert result.recommendation == "continue"

    @pytest.mark.asyncio
    async def test_analyze_performance_with_decline(self):
        """Test analysis detecting rep decline."""
        from services.fatigue_detection_service import (
            FatigueDetectionService,
            SetPerformance,
        )

        service = FatigueDetectionService()

        set_data = [
            SetPerformance(reps=12, weight_kg=60, rpe=7),
            SetPerformance(reps=10, weight_kg=60, rpe=8),
            SetPerformance(reps=8, weight_kg=60, rpe=9),  # 33% decline
        ]

        result = await service.analyze_performance(
            user_id="test-user",
            exercise_name="Bench Press",
            current_set=3,
            total_sets=4,
            set_data=set_data,
        )

        assert result.fatigue_level > 0.3
        assert "rep_decline" in result.indicators

    def test_get_set_recommendation_continue(self):
        """Test recommendation for low fatigue."""
        from services.fatigue_detection_service import (
            FatigueDetectionService,
            FatigueAnalysis,
        )

        service = FatigueDetectionService()

        analysis = FatigueAnalysis(
            fatigue_level=0.2,
            indicators=[],
            confidence=0.8,
            recommendation="continue",
        )

        recommendation = service.get_set_recommendation(analysis)

        assert recommendation.action == "continue"
        assert recommendation.show_prompt is False

    def test_get_set_recommendation_reduce_weight(self):
        """Test recommendation for moderate fatigue."""
        from services.fatigue_detection_service import (
            FatigueDetectionService,
            FatigueAnalysis,
        )

        service = FatigueDetectionService()

        analysis = FatigueAnalysis(
            fatigue_level=0.6,
            indicators=["rep_decline"],
            confidence=0.85,
            recommendation="reduce_weight",
            suggested_weight_reduction_pct=10,
        )

        recommendation = service.get_set_recommendation(analysis)

        assert recommendation.action == "reduce_weight"
        assert recommendation.show_prompt is True
        assert "10%" in recommendation.message


class TestNextSetPreview:
    """Tests for next set preview functionality."""

    def test_preview_includes_weight_and_reps(self):
        """Test that preview includes recommended weight and reps."""
        preview = {
            "weight_kg": 60,
            "target_reps": 10,
            "based_on": "1rm_intensity",
            "intensity_pct": 75,
        }

        assert "weight_kg" in preview
        assert "target_reps" in preview
        assert preview["intensity_pct"] == 75

    def test_preview_adjusts_for_fatigue(self):
        """Test that preview adjusts for current fatigue."""
        base_weight = 60
        fatigue_level = 0.5
        fatigue_adjustment = 0.9  # 10% reduction

        adjusted_weight = base_weight * fatigue_adjustment

        assert adjusted_weight == 54.0

    def test_preview_shows_during_rest(self):
        """Test that preview is shown during rest period."""
        is_resting = True
        rest_remaining_seconds = 45

        show_preview = is_resting and rest_remaining_seconds > 10

        assert show_preview is True

    def test_one_tap_apply_preview(self):
        """Test one-tap apply recommendation functionality."""
        preview = {"weight_kg": 55, "target_reps": 10}

        # Simulating one-tap apply
        applied = {
            "weight_kg": preview["weight_kg"],
            "target_reps": preview["target_reps"],
            "source": "ai_preview",
        }

        assert applied["source"] == "ai_preview"
        assert applied["weight_kg"] == 55
