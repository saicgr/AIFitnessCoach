"""
Tests for MetricsCalculator service.

Tests:
- BMI calculation
- Ideal body weight calculations (Devine, Robinson, Miller)
- BMR calculations (Mifflin-St Jeor, Harris-Benedict)
- TDEE calculation
- Body composition calculations
- Complete metrics calculation

Run with: pytest backend/tests/test_metrics_calculator.py -v
"""

import pytest
from services.metrics_calculator import MetricsCalculator, HealthMetrics


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def calculator():
    return MetricsCalculator()


# ============================================================
# BMI TESTS
# ============================================================

class TestBMICalculation:
    """Test BMI calculation."""

    def test_calculate_bmi_normal_weight(self, calculator):
        """Test BMI for normal weight person."""
        bmi, category = calculator.calculate_bmi(70, 175)
        assert 18.5 <= bmi < 25
        assert category == "normal"

    def test_calculate_bmi_underweight(self, calculator):
        """Test BMI for underweight person."""
        bmi, category = calculator.calculate_bmi(50, 175)
        assert bmi < 18.5
        assert category == "underweight"

    def test_calculate_bmi_overweight(self, calculator):
        """Test BMI for overweight person."""
        bmi, category = calculator.calculate_bmi(85, 175)
        assert 25 <= bmi < 30
        assert category == "overweight"

    def test_calculate_bmi_obese(self, calculator):
        """Test BMI for obese person."""
        bmi, category = calculator.calculate_bmi(100, 160)
        assert bmi >= 30
        assert category == "obese"

    def test_calculate_bmi_invalid_height(self, calculator):
        """Test BMI with invalid height."""
        bmi, category = calculator.calculate_bmi(70, 0)
        assert bmi == 0.0
        assert category == "unknown"

    def test_calculate_bmi_invalid_weight(self, calculator):
        """Test BMI with invalid weight."""
        bmi, category = calculator.calculate_bmi(-10, 175)
        assert bmi == 0.0
        assert category == "unknown"


# ============================================================
# IDEAL BODY WEIGHT TESTS
# ============================================================

class TestIdealBodyWeight:
    """Test ideal body weight calculations."""

    def test_ibw_devine_male(self, calculator):
        """Test Devine formula for male."""
        ibw = calculator.calculate_ibw_devine(175, "male")
        assert ibw > 0
        # For 175cm (about 5'9"), male IBW should be around 70-75kg
        assert 65 <= ibw <= 80

    def test_ibw_devine_female(self, calculator):
        """Test Devine formula for female."""
        ibw = calculator.calculate_ibw_devine(165, "female")
        assert ibw > 0
        # For 165cm, female IBW should be around 55-60kg
        assert 50 <= ibw <= 70

    def test_ibw_robinson_male(self, calculator):
        """Test Robinson formula for male."""
        ibw = calculator.calculate_ibw_robinson(175, "male")
        assert ibw > 0
        assert 60 <= ibw <= 85

    def test_ibw_robinson_female(self, calculator):
        """Test Robinson formula for female."""
        ibw = calculator.calculate_ibw_robinson(165, "female")
        assert ibw > 0
        assert 50 <= ibw <= 70

    def test_ibw_miller_male(self, calculator):
        """Test Miller formula for male."""
        ibw = calculator.calculate_ibw_miller(175, "male")
        assert ibw > 0
        assert 60 <= ibw <= 85

    def test_ibw_miller_female(self, calculator):
        """Test Miller formula for female."""
        ibw = calculator.calculate_ibw_miller(165, "female")
        assert ibw > 0
        assert 50 <= ibw <= 70

    def test_ibw_short_height(self, calculator):
        """Test IBW for very short height (edge case)."""
        # For very short height, result should still be >= 0
        ibw = calculator.calculate_ibw_devine(140, "male")
        assert ibw >= 0


# ============================================================
# BMR TESTS
# ============================================================

class TestBMRCalculation:
    """Test Basal Metabolic Rate calculations."""

    def test_bmr_mifflin_male(self, calculator):
        """Test Mifflin-St Jeor for male."""
        bmr = calculator.calculate_bmr_mifflin(75, 175, 30, "male")
        # For 75kg, 175cm, 30yo male, BMR should be around 1700-1800
        assert 1600 <= bmr <= 1900

    def test_bmr_mifflin_female(self, calculator):
        """Test Mifflin-St Jeor for female."""
        bmr = calculator.calculate_bmr_mifflin(60, 165, 30, "female")
        # For 60kg, 165cm, 30yo female, BMR should be around 1300-1400
        assert 1200 <= bmr <= 1500

    def test_bmr_harris_male(self, calculator):
        """Test Harris-Benedict for male."""
        bmr = calculator.calculate_bmr_harris(75, 175, 30, "male")
        assert 1600 <= bmr <= 1900

    def test_bmr_harris_female(self, calculator):
        """Test Harris-Benedict for female."""
        bmr = calculator.calculate_bmr_harris(60, 165, 30, "female")
        assert 1200 <= bmr <= 1500

    def test_bmr_age_effect(self, calculator):
        """Test that older age results in lower BMR."""
        bmr_young = calculator.calculate_bmr_mifflin(75, 175, 25, "male")
        bmr_old = calculator.calculate_bmr_mifflin(75, 175, 55, "male")
        assert bmr_young > bmr_old


# ============================================================
# TDEE TESTS
# ============================================================

class TestTDEECalculation:
    """Test Total Daily Energy Expenditure calculation."""

    def test_tdee_sedentary(self, calculator):
        """Test TDEE for sedentary activity level."""
        tdee = calculator.calculate_tdee(1700, "sedentary")
        expected = 1700 * 1.2
        assert abs(tdee - expected) < 1

    def test_tdee_lightly_active(self, calculator):
        """Test TDEE for lightly active."""
        tdee = calculator.calculate_tdee(1700, "lightly_active")
        expected = 1700 * 1.375
        assert abs(tdee - expected) < 1

    def test_tdee_moderately_active(self, calculator):
        """Test TDEE for moderately active."""
        tdee = calculator.calculate_tdee(1700, "moderately_active")
        expected = 1700 * 1.55
        assert abs(tdee - expected) < 1

    def test_tdee_very_active(self, calculator):
        """Test TDEE for very active."""
        tdee = calculator.calculate_tdee(1700, "very_active")
        expected = 1700 * 1.725
        assert abs(tdee - expected) < 1

    def test_tdee_extremely_active(self, calculator):
        """Test TDEE for extremely active."""
        tdee = calculator.calculate_tdee(1700, "extremely_active")
        expected = 1700 * 1.9
        assert abs(tdee - expected) < 1

    def test_tdee_unknown_activity(self, calculator):
        """Test TDEE with unknown activity level defaults to lightly_active."""
        tdee = calculator.calculate_tdee(1700, "unknown_level")
        expected = 1700 * 1.375  # Default multiplier
        assert abs(tdee - expected) < 1


# ============================================================
# BODY COMPOSITION TESTS
# ============================================================

class TestBodyComposition:
    """Test body composition calculations."""

    def test_body_fat_navy_male(self, calculator):
        """Test Navy body fat calculation for male."""
        bf = calculator.calculate_body_fat_navy(175, 85, 40, None, "male")
        assert bf is not None
        assert 10 <= bf <= 35

    def test_body_fat_navy_female(self, calculator):
        """Test Navy body fat calculation for female."""
        bf = calculator.calculate_body_fat_navy(165, 75, 35, 100, "female")
        assert bf is not None
        assert 15 <= bf <= 45

    def test_body_fat_navy_invalid_measurements(self, calculator):
        """Test Navy body fat with invalid measurements."""
        # Waist <= neck (invalid)
        bf = calculator.calculate_body_fat_navy(175, 35, 40, None, "male")
        assert bf is None

    def test_body_fat_navy_female_no_hip(self, calculator):
        """Test Navy body fat for female without hip measurement."""
        bf = calculator.calculate_body_fat_navy(165, 75, 35, None, "female")
        assert bf is None

    def test_waist_to_height_ratio(self, calculator):
        """Test waist-to-height ratio."""
        ratio = calculator.calculate_waist_to_height_ratio(80, 175)
        assert ratio == 0.46  # 80/175 = 0.457...

    def test_waist_to_height_ratio_invalid(self, calculator):
        """Test waist-to-height ratio with invalid inputs."""
        assert calculator.calculate_waist_to_height_ratio(None, 175) is None
        assert calculator.calculate_waist_to_height_ratio(80, 0) is None

    def test_waist_to_hip_ratio(self, calculator):
        """Test waist-to-hip ratio."""
        ratio = calculator.calculate_waist_to_hip_ratio(80, 100)
        assert ratio == 0.8

    def test_waist_to_hip_ratio_invalid(self, calculator):
        """Test waist-to-hip ratio with invalid inputs."""
        assert calculator.calculate_waist_to_hip_ratio(None, 100) is None
        assert calculator.calculate_waist_to_hip_ratio(80, 0) is None

    def test_lean_body_mass(self, calculator):
        """Test lean body mass calculation."""
        lbm = calculator.calculate_lean_body_mass(80, 20)
        assert lbm == 64.0  # 80 * (1 - 0.20)

    def test_lean_body_mass_invalid(self, calculator):
        """Test lean body mass with invalid body fat."""
        assert calculator.calculate_lean_body_mass(80, None) is None
        assert calculator.calculate_lean_body_mass(80, -5) is None
        assert calculator.calculate_lean_body_mass(80, 105) is None

    def test_ffmi(self, calculator):
        """Test Fat-Free Mass Index calculation."""
        ffmi = calculator.calculate_ffmi(64, 175)
        # FFMI = 64 / (1.75)^2 = 64 / 3.0625 = 20.9
        assert 20 <= ffmi <= 22

    def test_ffmi_invalid(self, calculator):
        """Test FFMI with invalid inputs."""
        assert calculator.calculate_ffmi(None, 175) is None
        assert calculator.calculate_ffmi(64, 0) is None


# ============================================================
# COMPLETE METRICS TESTS
# ============================================================

class TestCalculateAll:
    """Test complete metrics calculation."""

    def test_calculate_all_basic(self, calculator):
        """Test calculate_all with basic inputs."""
        metrics = calculator.calculate_all(
            weight_kg=75,
            height_cm=175,
            age=30,
            gender="male",
            activity_level="moderately_active"
        )

        assert isinstance(metrics, HealthMetrics)
        assert metrics.bmi > 0
        assert metrics.bmr_mifflin > 0
        assert metrics.tdee > 0
        assert metrics.ideal_body_weight_devine > 0

    def test_calculate_all_with_target_weight(self, calculator):
        """Test calculate_all with target weight."""
        metrics = calculator.calculate_all(
            weight_kg=90,
            height_cm=175,
            age=30,
            gender="male",
            activity_level="moderately_active",
            target_weight_kg=75
        )

        assert metrics.target_bmi is not None
        assert metrics.target_bmi < metrics.bmi

    def test_calculate_all_with_body_measurements(self, calculator):
        """Test calculate_all with body composition measurements."""
        metrics = calculator.calculate_all(
            weight_kg=75,
            height_cm=175,
            age=30,
            gender="male",
            activity_level="moderately_active",
            waist_cm=85,
            hip_cm=100,
            neck_cm=40
        )

        assert metrics.waist_to_height_ratio is not None
        assert metrics.waist_to_hip_ratio is not None
        assert metrics.body_fat_navy is not None
        assert metrics.lean_body_mass is not None
        assert metrics.ffmi is not None

    def test_calculate_all_with_body_fat_provided(self, calculator):
        """Test calculate_all with user-provided body fat."""
        metrics = calculator.calculate_all(
            weight_kg=75,
            height_cm=175,
            age=30,
            gender="male",
            activity_level="moderately_active",
            body_fat_percent=18.0
        )

        assert metrics.body_fat_navy == 18.0
        assert metrics.lean_body_mass is not None

    def test_calculate_all_female(self, calculator):
        """Test calculate_all for female."""
        metrics = calculator.calculate_all(
            weight_kg=60,
            height_cm=165,
            age=28,
            gender="female",
            activity_level="lightly_active"
        )

        assert metrics.bmi > 0
        assert metrics.bmr_mifflin < 1700  # Female BMR typically lower

    def test_calculate_all_normalizes_gender(self, calculator):
        """Test that gender is normalized."""
        metrics_male = calculator.calculate_all(
            weight_kg=75, height_cm=175, age=30,
            gender="MALE", activity_level="sedentary"
        )
        metrics_female = calculator.calculate_all(
            weight_kg=75, height_cm=175, age=30,
            gender="Female", activity_level="sedentary"
        )

        # Both should work without error
        assert metrics_male.bmr_mifflin > 0
        assert metrics_female.bmr_mifflin > 0
        assert metrics_male.bmr_mifflin > metrics_female.bmr_mifflin

    def test_calculate_all_invalid_gender_defaults_to_male(self, calculator):
        """Test that invalid gender defaults to male."""
        metrics = calculator.calculate_all(
            weight_kg=75, height_cm=175, age=30,
            gender="other", activity_level="sedentary"
        )

        # Should use male formula
        expected_male = calculator.calculate_bmr_mifflin(75, 175, 30, "male")
        assert metrics.bmr_mifflin == expected_male


# ============================================================
# INTERPRETATION TESTS
# ============================================================

class TestInterpretations:
    """Test human-readable interpretations."""

    def test_bmi_interpretation_underweight(self, calculator):
        """Test BMI interpretation for underweight."""
        interp = calculator.get_bmi_interpretation(17.5, "underweight")
        assert "17.5" in interp
        assert "below" in interp.lower()

    def test_bmi_interpretation_normal(self, calculator):
        """Test BMI interpretation for normal weight."""
        interp = calculator.get_bmi_interpretation(22.0, "normal")
        assert "22.0" in interp
        assert "healthy" in interp.lower()

    def test_bmi_interpretation_overweight(self, calculator):
        """Test BMI interpretation for overweight."""
        interp = calculator.get_bmi_interpretation(27.0, "overweight")
        assert "27.0" in interp
        assert "above" in interp.lower()

    def test_bmi_interpretation_obese(self, calculator):
        """Test BMI interpretation for obese."""
        interp = calculator.get_bmi_interpretation(32.0, "obese")
        assert "32.0" in interp
        assert "obesity" in interp.lower()

    def test_tdee_interpretation(self, calculator):
        """Test TDEE interpretation."""
        interp = calculator.get_tdee_interpretation(2500, "moderately_active")
        assert "2,500" in interp
        assert "moderate" in interp.lower()


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_very_tall_person(self, calculator):
        """Test calculations for very tall person."""
        metrics = calculator.calculate_all(
            weight_kg=100, height_cm=210, age=25,
            gender="male", activity_level="moderately_active"
        )
        assert metrics.bmi > 0
        assert metrics.bmi < 30  # Should not be obese at this weight/height

    def test_very_short_person(self, calculator):
        """Test calculations for very short person."""
        metrics = calculator.calculate_all(
            weight_kg=45, height_cm=145, age=25,
            gender="female", activity_level="lightly_active"
        )
        assert metrics.bmi > 0
        assert metrics.ideal_body_weight_devine >= 0

    def test_elderly_person(self, calculator):
        """Test calculations for elderly person."""
        metrics = calculator.calculate_all(
            weight_kg=70, height_cm=170, age=75,
            gender="male", activity_level="sedentary"
        )
        assert metrics.bmr_mifflin > 0
        assert metrics.bmr_mifflin < 1600  # Lower BMR due to age


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
