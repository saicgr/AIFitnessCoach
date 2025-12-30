"""
Tests for Readiness Service.

Tests:
- Hooper Index calculation
- Readiness score conversion
- Level classification
- Intensity recommendations
- Trend analysis
"""
import pytest
from services.readiness_service import (
    ReadinessService,
    ReadinessCheckIn,
    ReadinessResult,
    ReadinessLevel,
    WorkoutIntensity,
)


class TestHooperIndexCalculation:
    """Tests for Hooper Index calculation."""

    def setup_method(self):
        self.service = ReadinessService()

    def test_hooper_index_best_case(self):
        """Test Hooper Index with best possible values."""
        check_in = ReadinessCheckIn(
            sleep_quality=1,
            fatigue_level=1,
            stress_level=1,
            muscle_soreness=1,
        )

        hooper = self.service.calculate_hooper_index(check_in)

        assert hooper == 4  # 1+1+1+1 = 4 (best)

    def test_hooper_index_worst_case(self):
        """Test Hooper Index with worst possible values."""
        check_in = ReadinessCheckIn(
            sleep_quality=7,
            fatigue_level=7,
            stress_level=7,
            muscle_soreness=7,
        )

        hooper = self.service.calculate_hooper_index(check_in)

        assert hooper == 28  # 7+7+7+7 = 28 (worst)

    def test_hooper_index_average_case(self):
        """Test Hooper Index with average values."""
        check_in = ReadinessCheckIn(
            sleep_quality=4,
            fatigue_level=4,
            stress_level=4,
            muscle_soreness=4,
        )

        hooper = self.service.calculate_hooper_index(check_in)

        assert hooper == 16  # 4+4+4+4 = 16 (middle)


class TestReadinessScoreConversion:
    """Tests for Hooper to readiness score conversion."""

    def setup_method(self):
        self.service = ReadinessService()

    def test_best_hooper_to_score(self):
        """Test best Hooper Index converts to 100."""
        score = self.service.hooper_to_readiness_score(4)
        assert score == 100

    def test_worst_hooper_to_score(self):
        """Test worst Hooper Index converts to 0."""
        score = self.service.hooper_to_readiness_score(28)
        assert score == 0

    def test_middle_hooper_to_score(self):
        """Test middle Hooper Index converts to ~50."""
        score = self.service.hooper_to_readiness_score(16)
        assert score == 50


class TestReadinessLevelClassification:
    """Tests for readiness level classification."""

    def setup_method(self):
        self.service = ReadinessService()

    def test_optimal_level(self):
        """Test optimal level classification (81-100)."""
        assert self.service.classify_readiness_level(100) == ReadinessLevel.OPTIMAL
        assert self.service.classify_readiness_level(90) == ReadinessLevel.OPTIMAL
        assert self.service.classify_readiness_level(81) == ReadinessLevel.OPTIMAL

    def test_good_level(self):
        """Test good level classification (61-80)."""
        assert self.service.classify_readiness_level(80) == ReadinessLevel.GOOD
        assert self.service.classify_readiness_level(70) == ReadinessLevel.GOOD
        assert self.service.classify_readiness_level(61) == ReadinessLevel.GOOD

    def test_moderate_level(self):
        """Test moderate level classification (41-60)."""
        assert self.service.classify_readiness_level(60) == ReadinessLevel.MODERATE
        assert self.service.classify_readiness_level(50) == ReadinessLevel.MODERATE
        assert self.service.classify_readiness_level(41) == ReadinessLevel.MODERATE

    def test_low_level(self):
        """Test low level classification (0-40)."""
        assert self.service.classify_readiness_level(40) == ReadinessLevel.LOW
        assert self.service.classify_readiness_level(20) == ReadinessLevel.LOW
        assert self.service.classify_readiness_level(0) == ReadinessLevel.LOW


class TestIntensityRecommendations:
    """Tests for workout intensity recommendations."""

    def setup_method(self):
        self.service = ReadinessService()

    def test_optimal_readiness_high_intensity(self):
        """Test that optimal readiness recommends high intensity."""
        intensity = self.service.get_recommended_intensity(ReadinessLevel.OPTIMAL)
        assert intensity == WorkoutIntensity.HIGH

    def test_good_readiness_moderate_intensity(self):
        """Test that good readiness recommends moderate intensity."""
        intensity = self.service.get_recommended_intensity(ReadinessLevel.GOOD)
        assert intensity == WorkoutIntensity.MODERATE

    def test_moderate_readiness_light_intensity(self):
        """Test that moderate readiness recommends light intensity."""
        intensity = self.service.get_recommended_intensity(ReadinessLevel.MODERATE)
        assert intensity == WorkoutIntensity.LIGHT

    def test_low_readiness_rest(self):
        """Test that low readiness recommends rest."""
        intensity = self.service.get_recommended_intensity(ReadinessLevel.LOW)
        assert intensity == WorkoutIntensity.REST

    def test_strength_training_moderate_readiness(self):
        """Test that strength training can proceed at moderate readiness."""
        intensity = self.service.get_recommended_intensity(
            ReadinessLevel.MODERATE,
            scheduled_workout_type="strength",
        )
        # Strength training is less affected, so moderate is still OK
        assert intensity == WorkoutIntensity.MODERATE


class TestFullReadinessCalculation:
    """Tests for complete readiness calculation."""

    def setup_method(self):
        self.service = ReadinessService()

    def test_calculate_readiness_optimal(self):
        """Test full calculation for optimal readiness."""
        check_in = ReadinessCheckIn(
            sleep_quality=1,
            fatigue_level=1,
            stress_level=1,
            muscle_soreness=1,
        )

        result = self.service.calculate_readiness(check_in)

        assert isinstance(result, ReadinessResult)
        assert result.hooper_index == 4
        assert result.readiness_score == 100
        assert result.readiness_level == ReadinessLevel.OPTIMAL
        assert result.recommended_intensity == WorkoutIntensity.HIGH

    def test_calculate_readiness_low(self):
        """Test full calculation for low readiness."""
        check_in = ReadinessCheckIn(
            sleep_quality=6,
            fatigue_level=6,
            stress_level=6,
            muscle_soreness=6,
        )

        result = self.service.calculate_readiness(check_in)

        assert result.hooper_index == 24
        assert result.readiness_score < 40
        assert result.readiness_level == ReadinessLevel.LOW
        assert result.recommended_intensity == WorkoutIntensity.REST

    def test_calculate_readiness_includes_recommendations(self):
        """Test that calculation includes recommendations."""
        check_in = ReadinessCheckIn(
            sleep_quality=3,
            fatigue_level=3,
            stress_level=3,
            muscle_soreness=3,
        )

        result = self.service.calculate_readiness(check_in)

        assert result.ai_workout_recommendation is not None
        assert result.component_analysis is not None
        assert "sleep" in result.component_analysis
        assert "fatigue" in result.component_analysis

    def test_calculate_readiness_with_scheduled_workout(self):
        """Test calculation with scheduled workout context."""
        check_in = ReadinessCheckIn(
            sleep_quality=3,
            fatigue_level=4,
            stress_level=3,
            muscle_soreness=3,
        )

        result = self.service.calculate_readiness(
            check_in,
            scheduled_workout_type="strength",
        )

        # Should include workout-specific advice
        assert result.ai_workout_recommendation is not None


class TestComponentAnalysis:
    """Tests for individual component analysis."""

    def setup_method(self):
        self.service = ReadinessService()

    def test_analyze_excellent_sleep(self):
        """Test analysis of excellent sleep."""
        check_in = ReadinessCheckIn(
            sleep_quality=1,
            fatigue_level=4,
            stress_level=4,
            muscle_soreness=4,
        )

        analysis = self.service._analyze_components(check_in)

        assert analysis["sleep"] == "excellent"

    def test_analyze_poor_sleep(self):
        """Test analysis of poor sleep."""
        check_in = ReadinessCheckIn(
            sleep_quality=6,
            fatigue_level=4,
            stress_level=4,
            muscle_soreness=4,
        )

        analysis = self.service._analyze_components(check_in)

        assert "poor" in analysis["sleep"]

    def test_analyze_high_fatigue(self):
        """Test analysis of high fatigue."""
        check_in = ReadinessCheckIn(
            sleep_quality=4,
            fatigue_level=6,
            stress_level=4,
            muscle_soreness=4,
        )

        analysis = self.service._analyze_components(check_in)

        assert "elevated" in analysis["fatigue"]

    def test_identify_limiting_factor(self):
        """Test identification of limiting factor."""
        check_in = ReadinessCheckIn(
            sleep_quality=2,
            fatigue_level=3,
            stress_level=6,  # This is the worst
            muscle_soreness=2,
        )

        factor, severity = self.service._identify_limiting_factor(check_in)

        assert factor == "stress"
        assert severity == 6


class TestTrendAnalysis:
    """Tests for readiness trend analysis."""

    def setup_method(self):
        self.service = ReadinessService()

    def test_improving_trend(self):
        """Test detection of improving readiness trend."""
        result = self.service.calculate_readiness_trend(
            current_score=80,
            historical_scores=[60, 65, 70, 75],
        )

        assert result["trend"] == "improving"
        assert result["trend_score"] > 0

    def test_declining_trend(self):
        """Test detection of declining readiness trend."""
        result = self.service.calculate_readiness_trend(
            current_score=50,
            historical_scores=[80, 75, 70, 60],
        )

        assert result["trend"] == "declining"
        assert result["trend_score"] < 0

    def test_stable_trend(self):
        """Test detection of stable readiness trend."""
        result = self.service.calculate_readiness_trend(
            current_score=65,
            historical_scores=[65, 66, 64, 65],
        )

        assert result["trend"] == "stable"

    def test_days_above_60(self):
        """Test counting of good readiness days."""
        result = self.service.calculate_readiness_trend(
            current_score=70,
            historical_scores=[80, 55, 70, 65, 50, 75],
        )

        # Scores above 60: 80, 70, 65, 75 = 4
        assert result["days_above_60"] == 4

    def test_empty_history(self):
        """Test with no historical data."""
        result = self.service.calculate_readiness_trend(
            current_score=70,
            historical_scores=[],
        )

        assert result["trend"] == "stable"
        assert result["average"] == 70


class TestWorkoutModifications:
    """Tests for workout modification suggestions."""

    def setup_method(self):
        self.service = ReadinessService()

    def test_optimal_modifications(self):
        """Test modifications for optimal readiness."""
        mods = self.service.suggest_workout_modifications(
            ReadinessLevel.OPTIMAL, None
        )

        assert len(mods) > 0
        assert any("PR" in mod or "push" in mod.lower() for mod in mods)

    def test_low_readiness_modifications(self):
        """Test modifications for low readiness."""
        mods = self.service.suggest_workout_modifications(
            ReadinessLevel.LOW, None
        )

        assert len(mods) > 0
        assert any("rest" in mod.lower() for mod in mods)

    def test_moderate_readiness_modifications(self):
        """Test modifications for moderate readiness."""
        mods = self.service.suggest_workout_modifications(
            ReadinessLevel.MODERATE, None
        )

        assert len(mods) > 0
        # Should suggest reducing something
        assert any("reduce" in mod.lower() or "lower" in mod.lower() for mod in mods)
