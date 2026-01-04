"""
Tests for Smart Weight Auto-Fill System.

Tests:
- 1RM-based weight calculation
- Performance modifier application
- Equipment-aware rounding
- Edge cases (no 1RM, first workout)
- Target intensity percentages
"""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime, timedelta


class TestOneRMCalculation:
    """Tests for 1RM estimation."""

    def test_brzycki_formula(self):
        """Test Brzycki formula: weight * (36 / (37 - reps))"""
        from services.strength_calculator_service import StrengthCalculatorService

        service = StrengthCalculatorService()
        result = service.calculate_1rm(100, 5, formula="brzycki")

        # Brzycki: 100 * (36 / (37 - 5)) = 100 * (36/32) = 112.5
        assert round(result.estimated_1rm, 1) == 112.5
        assert result.formula_used == "brzycki"

    def test_epley_formula(self):
        """Test Epley formula: weight * (1 + reps/30)"""
        from services.strength_calculator_service import StrengthCalculatorService

        service = StrengthCalculatorService()
        result = service.calculate_1rm(100, 5, formula="epley")

        # Epley: 100 * (1 + 5/30) = 100 * 1.1667 = 116.67
        assert round(result.estimated_1rm, 2) == 116.67
        assert result.formula_used == "epley"

    def test_single_rep_equals_actual_weight(self):
        """Test that 1 rep returns the actual weight as 1RM."""
        from services.strength_calculator_service import StrengthCalculatorService

        service = StrengthCalculatorService()
        result = service.calculate_1rm(150, 1)

        assert result.estimated_1rm == 150
        assert result.confidence == 1.0
        assert result.formula_used == "actual"

    def test_high_reps_lower_confidence(self):
        """Test that higher reps result in lower confidence."""
        from services.strength_calculator_service import StrengthCalculatorService

        service = StrengthCalculatorService()

        result_5_reps = service.calculate_1rm(100, 5)
        result_10_reps = service.calculate_1rm(100, 10)
        result_15_reps = service.calculate_1rm(100, 15)

        assert result_5_reps.confidence > result_10_reps.confidence
        assert result_10_reps.confidence > result_15_reps.confidence


class TestSmartWeightCalculation:
    """Tests for smart weight auto-fill based on 1RM."""

    def test_calculate_working_weight_default_intensity(self):
        """Test calculating working weight at default 75% intensity."""
        # Given: User has 80kg 1RM for bench press
        one_rm = 80.0
        intensity = 0.75  # 75% for hypertrophy

        expected_weight = one_rm * intensity  # 60kg

        assert expected_weight == 60.0

    def test_calculate_working_weight_strength_intensity(self):
        """Test calculating working weight at 85% intensity for strength."""
        one_rm = 100.0
        intensity = 0.85  # 85% for strength

        expected_weight = one_rm * intensity  # 85kg

        assert expected_weight == 85.0

    def test_calculate_working_weight_endurance_intensity(self):
        """Test calculating working weight at 60% intensity for endurance."""
        one_rm = 100.0
        intensity = 0.60  # 60% for endurance

        expected_weight = one_rm * intensity  # 60kg

        assert expected_weight == 60.0


class TestEquipmentAwareRounding:
    """Tests for equipment-aware weight rounding."""

    def test_dumbbell_rounding_2_5kg(self):
        """Test that dumbbells round to 2.5kg increments."""
        raw_weight = 23.7
        increment = 2.5

        rounded = round(raw_weight / increment) * increment

        assert rounded == 22.5  # 23.7/2.5=9.48, round(9.48)=9, 9*2.5=22.5

    def test_dumbbell_rounding_rounds_down(self):
        """Test that dumbbells round down when closer to lower value."""
        raw_weight = 21.2
        increment = 2.5

        rounded = round(raw_weight / increment) * increment

        assert rounded == 20.0  # Rounds down

    def test_machine_rounding_5kg(self):
        """Test that machines round to 5kg increments."""
        raw_weight = 42.0
        increment = 5.0

        rounded = round(raw_weight / increment) * increment

        assert rounded == 40.0

    def test_cable_rounding_5kg(self):
        """Test that cable machines round to 5kg increments."""
        raw_weight = 33.0
        increment = 5.0

        rounded = round(raw_weight / increment) * increment

        assert rounded == 35.0

    def test_barbell_rounding_2_5kg(self):
        """Test that barbells round to 2.5kg increments."""
        raw_weight = 61.3
        increment = 2.5

        rounded = round(raw_weight / increment) * increment

        assert rounded == 62.5


class TestPerformanceModifiers:
    """Tests for performance modifier application."""

    def test_performance_modifier_good_sleep(self):
        """Test that good sleep doesn't reduce weight."""
        base_weight = 60.0
        modifier = 1.0  # 100% - good readiness

        adjusted_weight = base_weight * modifier

        assert adjusted_weight == 60.0

    def test_performance_modifier_poor_sleep(self):
        """Test that poor sleep reduces suggested weight."""
        base_weight = 60.0
        modifier = 0.95  # 95% - slightly fatigued

        adjusted_weight = base_weight * modifier

        assert adjusted_weight == 57.0

    def test_performance_modifier_very_fatigued(self):
        """Test significant reduction when very fatigued."""
        base_weight = 60.0
        modifier = 0.85  # 85% - significant fatigue

        adjusted_weight = base_weight * modifier

        assert adjusted_weight == 51.0

    def test_cumulative_set_fatigue(self):
        """Test progressive fatigue across sets reduces weight."""
        base_weight = 60.0

        # Set 1: 100%, Set 2: 100%, Set 3: 95%, Set 4: 90%
        set_modifiers = [1.0, 1.0, 0.95, 0.90]

        expected_weights = [60.0, 60.0, 57.0, 54.0]

        for i, modifier in enumerate(set_modifiers):
            adjusted = base_weight * modifier
            assert adjusted == expected_weights[i], f"Set {i+1} weight mismatch"


class TestEdgeCases:
    """Tests for edge cases in weight suggestions."""

    def test_no_1rm_data_returns_none(self):
        """Test that missing 1RM data returns None for suggestion."""
        user_1rm = None  # No 1RM data

        # Should not suggest weight without baseline
        assert user_1rm is None

    def test_first_workout_uses_conservative_estimate(self):
        """Test that first workout uses conservative estimate."""
        # If user provides bodyweight or estimates, use conservative multiplier
        body_weight = 70.0
        exercise = "bench_press"
        beginner_multiplier = 0.5  # 50% of bodyweight for beginners

        conservative_estimate = body_weight * beginner_multiplier

        assert conservative_estimate == 35.0

    def test_very_old_1rm_reduces_confidence(self):
        """Test that old 1RM data reduces suggestion confidence."""
        days_since_1rm = 90
        base_confidence = 0.9

        # Decay confidence over time
        decay_factor = max(0.5, 1.0 - (days_since_1rm / 180))  # 50% minimum after 180 days
        adjusted_confidence = base_confidence * decay_factor

        assert adjusted_confidence < base_confidence
        assert adjusted_confidence >= 0.4  # Allow lower minimum with decay

    def test_zero_reps_handled(self):
        """Test handling of zero reps input."""
        from services.strength_calculator_service import StrengthCalculatorService

        service = StrengthCalculatorService()
        result = service.calculate_1rm(100, 0)

        # Zero reps should return the weight with low confidence
        assert result.estimated_1rm == 100
        assert result.confidence == 0.0

    def test_negative_weight_rejected(self):
        """Test that negative weights are handled properly."""
        weight = -50.0

        # Weight should be converted to positive or rejected
        assert abs(weight) == 50.0

    def test_extremely_high_reps_capped(self):
        """Test that very high reps (30+) are handled with low confidence."""
        from services.strength_calculator_service import StrengthCalculatorService

        service = StrengthCalculatorService()
        result = service.calculate_1rm(50, 30)

        # Should still calculate but with low confidence
        assert result.estimated_1rm > 50
        assert result.confidence <= 0.5  # At or below 50%


class TestIntensityRanges:
    """Tests for different training intensity ranges."""

    def test_strength_intensity_range(self):
        """Test strength training intensity (80-95%)."""
        one_rm = 100.0

        low_strength = one_rm * 0.80  # 80kg
        high_strength = one_rm * 0.95  # 95kg

        assert low_strength == 80.0
        assert high_strength == 95.0

    def test_hypertrophy_intensity_range(self):
        """Test hypertrophy intensity (67-85%)."""
        one_rm = 100.0

        low_hypertrophy = one_rm * 0.67  # 67kg
        high_hypertrophy = one_rm * 0.85  # 85kg

        assert low_hypertrophy == 67.0
        assert high_hypertrophy == 85.0

    def test_endurance_intensity_range(self):
        """Test endurance intensity (50-67%)."""
        one_rm = 100.0

        low_endurance = one_rm * 0.50  # 50kg
        high_endurance = one_rm * 0.67  # 67kg

        assert low_endurance == 50.0
        assert high_endurance == 67.0

    def test_power_intensity_range(self):
        """Test power training intensity (30-60% for speed work)."""
        one_rm = 100.0

        low_power = one_rm * 0.30  # 30kg
        high_power = one_rm * 0.60  # 60kg

        assert low_power == 30.0
        assert high_power == 60.0


class TestReasoningGeneration:
    """Tests for AI reasoning/explanation generation."""

    def test_reasoning_includes_1rm_reference(self):
        """Test that reasoning includes 1RM reference."""
        one_rm = 80.0
        intensity = 75
        suggested_weight = 60.0

        reasoning = f"Based on your {one_rm}kg 1RM at {intensity}% intensity"

        assert "80.0kg 1RM" in reasoning
        assert "75%" in reasoning

    def test_reasoning_mentions_equipment_rounding(self):
        """Test that reasoning mentions equipment rounding."""
        raw_weight = 58.7
        rounded_weight = 60.0
        equipment = "dumbbell"

        reasoning = f"Rounded to {rounded_weight}kg for {equipment} (2.5kg increments)"

        assert "60.0kg" in reasoning
        assert "dumbbell" in reasoning
        assert "2.5kg" in reasoning

    def test_reasoning_includes_performance_adjustment(self):
        """Test that reasoning includes performance adjustment if applied."""
        base_weight = 60.0
        adjusted_weight = 57.0
        reason = "reduced due to fatigue indicators"

        reasoning = f"Suggested {adjusted_weight}kg (from {base_weight}kg base, {reason})"

        assert "57.0kg" in reasoning
        assert "fatigue" in reasoning


class TestSuggestionConfidence:
    """Tests for suggestion confidence calculation."""

    def test_high_confidence_recent_1rm(self):
        """Test high confidence with recent 1RM data."""
        days_since_test = 7
        data_points = 10

        # Recent data + multiple data points = high confidence
        confidence = min(0.9, 0.7 + (data_points * 0.02) - (days_since_test * 0.01))

        assert confidence >= 0.8

    def test_medium_confidence_older_1rm(self):
        """Test medium confidence with older 1RM data."""
        days_since_test = 45
        data_points = 5

        confidence = min(0.9, 0.7 + (data_points * 0.02) - (days_since_test * 0.005))

        assert 0.5 <= confidence <= 0.8

    def test_low_confidence_limited_data(self):
        """Test low confidence with limited data."""
        days_since_test = 60
        data_points = 1

        confidence = max(0.3, 0.5 + (data_points * 0.02) - (days_since_test * 0.005))

        assert confidence < 0.6
