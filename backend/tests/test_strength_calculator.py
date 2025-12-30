"""
Tests for Strength Calculator Service.

Tests:
- 1RM estimation formulas
- Strength level classification
- Muscle group scoring
- Overall strength calculation
"""
import pytest
from services.strength_calculator_service import (
    StrengthCalculatorService,
    StrengthLevel,
    MuscleGroup,
    OneRepMax,
    StrengthScore,
)


class TestOneRepMaxCalculation:
    """Tests for 1RM estimation."""

    def setup_method(self):
        self.service = StrengthCalculatorService()

    def test_calculate_1rm_brzycki_formula(self):
        """Test Brzycki formula for 1RM."""
        result = self.service.calculate_1rm(100, 5, formula="brzycki")

        assert isinstance(result, OneRepMax)
        assert result.weight_kg == 100
        assert result.reps == 5
        assert result.formula_used == "brzycki"
        # Brzycki: 100 * (36 / (37 - 5)) = 112.5
        assert round(result.estimated_1rm, 1) == 112.5

    def test_calculate_1rm_epley_formula(self):
        """Test Epley formula for 1RM."""
        result = self.service.calculate_1rm(100, 5, formula="epley")

        assert result.formula_used == "epley"
        # Epley: 100 * (1 + 5/30) = 116.67
        assert round(result.estimated_1rm, 2) == 116.67

    def test_calculate_1rm_lombardi_formula(self):
        """Test Lombardi formula for 1RM."""
        result = self.service.calculate_1rm(100, 5, formula="lombardi")

        assert result.formula_used == "lombardi"
        # Lombardi: 100 * 5^0.1 = 117.46
        assert round(result.estimated_1rm, 2) == 117.46

    def test_calculate_1rm_single_rep(self):
        """Test that 1 rep returns the actual weight."""
        result = self.service.calculate_1rm(150, 1)

        assert result.estimated_1rm == 150
        assert result.confidence == 1.0
        assert result.formula_used == "actual"

    def test_calculate_1rm_zero_reps(self):
        """Test handling of zero reps."""
        result = self.service.calculate_1rm(100, 0)

        assert result.estimated_1rm == 100
        assert result.confidence == 0.0

    def test_confidence_decreases_with_higher_reps(self):
        """Test that confidence decreases with higher rep counts."""
        result_5_reps = self.service.calculate_1rm(100, 5)
        result_10_reps = self.service.calculate_1rm(100, 10)
        result_15_reps = self.service.calculate_1rm(100, 15)

        assert result_5_reps.confidence > result_10_reps.confidence
        assert result_10_reps.confidence > result_15_reps.confidence

    def test_calculate_1rm_average(self):
        """Test average of multiple formulas."""
        result = StrengthCalculatorService.calculate_1rm_average(100, 5)

        # Should be average of Brzycki (112.5), Epley (116.67), Lombardi (117.46)
        assert 115 < result < 117


class TestStrengthLevelClassification:
    """Tests for strength level classification."""

    def setup_method(self):
        self.service = StrengthCalculatorService()

    def test_classify_beginner_squat(self):
        """Test beginner classification for squat."""
        # 80kg bodyweight, 50kg squat = 0.625x BW = beginner
        level, ratio, score = self.service.classify_strength_level(
            "squat", 50, 80, gender="male"
        )

        assert level == StrengthLevel.BEGINNER
        assert 0.62 <= ratio <= 0.63  # Allow for rounding
        assert 0 <= score <= 24

    def test_classify_novice_squat(self):
        """Test novice classification for squat."""
        # 80kg bodyweight, 100kg squat = 1.25x BW = novice
        level, ratio, score = self.service.classify_strength_level(
            "squat", 100, 80, gender="male"
        )

        assert level == StrengthLevel.NOVICE
        assert ratio == 1.25
        assert 25 <= score <= 49

    def test_classify_intermediate_squat(self):
        """Test intermediate classification for squat."""
        # 80kg bodyweight, 130kg squat = 1.625x BW = intermediate
        level, ratio, score = self.service.classify_strength_level(
            "squat", 130, 80, gender="male"
        )

        assert level == StrengthLevel.INTERMEDIATE
        assert 1.62 <= ratio <= 1.63  # Allow for rounding
        assert 50 <= score <= 69

    def test_classify_advanced_squat(self):
        """Test advanced classification for squat."""
        # 80kg bodyweight, 180kg squat = 2.25x BW = advanced
        level, ratio, score = self.service.classify_strength_level(
            "squat", 180, 80, gender="male"
        )

        assert level == StrengthLevel.ADVANCED
        assert ratio == 2.25
        assert 70 <= score <= 89

    def test_classify_elite_squat(self):
        """Test elite classification for squat."""
        # 80kg bodyweight, 220kg squat = 2.75x BW = elite
        level, ratio, score = self.service.classify_strength_level(
            "squat", 220, 80, gender="male"
        )

        assert level == StrengthLevel.ELITE
        assert ratio == 2.75
        assert score >= 90

    def test_female_standards_lower(self):
        """Test that female standards are adjusted."""
        # Same lift, female should be higher level
        male_level, _, male_score = self.service.classify_strength_level(
            "squat", 100, 80, gender="male"
        )
        female_level, _, female_score = self.service.classify_strength_level(
            "squat", 100, 80, gender="female"
        )

        # Female should have higher score for same lift
        assert female_score > male_score

    def test_normalize_exercise_name(self):
        """Test exercise name normalization."""
        # Different formats should normalize to same result
        level1, _, _ = self.service.classify_strength_level("Bench Press", 100, 80)
        level2, _, _ = self.service.classify_strength_level("bench_press", 100, 80)
        level3, _, _ = self.service.classify_strength_level("BENCH PRESS", 100, 80)

        # All should give same level (novice for 1.25x BW on bench)
        assert level1 == level2 == level3


class TestMuscleGroupScoring:
    """Tests for muscle group scoring."""

    def setup_method(self):
        self.service = StrengthCalculatorService()

    def test_calculate_muscle_group_score_empty(self):
        """Test scoring with no exercises."""
        result = self.service.calculate_muscle_group_score(
            "chest", [], 80, gender="male"
        )

        assert isinstance(result, StrengthScore)
        assert result.muscle_group == "chest"
        assert result.strength_score == 0
        assert result.strength_level == StrengthLevel.BEGINNER

    def test_calculate_muscle_group_score_single_exercise(self):
        """Test scoring with single exercise."""
        exercises = [
            {"exercise_name": "bench_press", "weight_kg": 100, "reps": 5, "sets": 3}
        ]

        result = self.service.calculate_muscle_group_score(
            "chest", exercises, 80, gender="male"
        )

        assert result.strength_score > 0
        assert result.best_exercise_name == "bench_press"
        assert result.best_estimated_1rm_kg > 100  # 1RM higher than working weight
        assert result.weekly_sets == 3
        assert result.weekly_volume_kg == 100 * 5 * 3

    def test_calculate_muscle_group_score_multiple_exercises(self):
        """Test scoring with multiple exercises."""
        exercises = [
            {"exercise_name": "bench_press", "weight_kg": 100, "reps": 5, "sets": 3},
            {"exercise_name": "incline_bench_press", "weight_kg": 80, "reps": 8, "sets": 3},
        ]

        result = self.service.calculate_muscle_group_score(
            "chest", exercises, 80, gender="male"
        )

        assert result.weekly_sets == 6
        # Best exercise should be the one with highest 1RM
        assert result.best_exercise_name in ["bench_press", "incline_bench_press"]

    def test_calculate_all_muscle_scores(self):
        """Test calculating scores for all muscle groups."""
        workout_data = [
            {"exercise_name": "squat", "weight_kg": 120, "reps": 5, "sets": 4},
            {"exercise_name": "bench_press", "weight_kg": 80, "reps": 8, "sets": 3},
            {"exercise_name": "deadlift", "weight_kg": 140, "reps": 5, "sets": 3},
            {"exercise_name": "bicep_curl", "weight_kg": 20, "reps": 10, "sets": 3},
        ]

        scores = self.service.calculate_all_muscle_scores(workout_data, 80, "male")

        assert isinstance(scores, dict)
        assert len(scores) == len(MuscleGroup)

        # Quads should have score from squat
        assert scores["quads"].strength_score > 0

        # Chest should have score from bench press
        assert scores["chest"].strength_score > 0


class TestOverallStrengthScore:
    """Tests for overall strength score calculation."""

    def setup_method(self):
        self.service = StrengthCalculatorService()

    def test_calculate_overall_strength_score(self):
        """Test overall score calculation."""
        # Create mock score objects
        muscle_scores = {
            "chest": type('obj', (object,), {'strength_score': 50})(),
            "back": type('obj', (object,), {'strength_score': 55})(),
            "quads": type('obj', (object,), {'strength_score': 60})(),
            "shoulders": type('obj', (object,), {'strength_score': 45})(),
            "biceps": type('obj', (object,), {'strength_score': 40})(),
            "triceps": type('obj', (object,), {'strength_score': 42})(),
        }

        overall_score, overall_level = self.service.calculate_overall_strength_score(muscle_scores)

        assert 0 <= overall_score <= 100
        assert isinstance(overall_level, StrengthLevel)

    def test_overall_score_weighted_correctly(self):
        """Test that compound muscle groups are weighted higher."""
        # Create scores where compound muscles are stronger
        compound_strong = {
            "chest": type('obj', (object,), {'strength_score': 80})(),
            "back": type('obj', (object,), {'strength_score': 80})(),
            "quads": type('obj', (object,), {'strength_score': 80})(),
            "biceps": type('obj', (object,), {'strength_score': 20})(),
            "triceps": type('obj', (object,), {'strength_score': 20})(),
        }

        isolation_strong = {
            "chest": type('obj', (object,), {'strength_score': 20})(),
            "back": type('obj', (object,), {'strength_score': 20})(),
            "quads": type('obj', (object,), {'strength_score': 20})(),
            "biceps": type('obj', (object,), {'strength_score': 80})(),
            "triceps": type('obj', (object,), {'strength_score': 80})(),
        }

        compound_overall, _ = self.service.calculate_overall_strength_score(compound_strong)
        isolation_overall, _ = self.service.calculate_overall_strength_score(isolation_strong)

        # Compound-strong should score higher due to weighting
        assert compound_overall > isolation_overall


class TestTrendCalculation:
    """Tests for trend calculation."""

    def test_improving_trend(self):
        """Test detection of improving trend."""
        trend = StrengthCalculatorService.calculate_trend(
            current_score=60,
            previous_scores=[50, 52, 55, 57],
            threshold=3,
        )

        assert trend == "improving"

    def test_declining_trend(self):
        """Test detection of declining trend."""
        trend = StrengthCalculatorService.calculate_trend(
            current_score=45,
            previous_scores=[55, 53, 50, 48],
            threshold=3,
        )

        assert trend == "declining"

    def test_maintaining_trend(self):
        """Test detection of stable trend."""
        trend = StrengthCalculatorService.calculate_trend(
            current_score=50,
            previous_scores=[49, 50, 51, 50],
            threshold=3,
        )

        assert trend == "maintaining"

    def test_empty_history(self):
        """Test with no historical data."""
        trend = StrengthCalculatorService.calculate_trend(
            current_score=50,
            previous_scores=[],
            threshold=3,
        )

        assert trend == "maintaining"


class TestHelperMethods:
    """Tests for helper methods."""

    def test_normalize_exercise_name(self):
        """Test exercise name normalization."""
        assert StrengthCalculatorService._normalize_exercise_name("Bench Press") == "bench_press"
        assert StrengthCalculatorService._normalize_exercise_name("SQUAT") == "squat"
        assert StrengthCalculatorService._normalize_exercise_name("Dumbbell_Curl") == "curl"
        assert StrengthCalculatorService._normalize_exercise_name("barbell-row") == "row"

    def test_get_exercise_muscle_groups(self):
        """Test getting muscle groups for exercises."""
        service = StrengthCalculatorService()

        squat_muscles = service.get_exercise_muscle_groups("squat")
        assert "quads" in squat_muscles
        assert "glutes" in squat_muscles

        bench_muscles = service.get_exercise_muscle_groups("bench_press")
        assert "chest" in bench_muscles
        assert "triceps" in bench_muscles

        unknown_muscles = service.get_exercise_muscle_groups("unknown_exercise")
        assert unknown_muscles == []
