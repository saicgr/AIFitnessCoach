"""
Tests for percentage-based 1RM training feature.

Tests the PercentageTrainingService including:
- Working weight calculations
- Intensity descriptions
- RPE to percentage conversion
- Equipment-based rounding
"""
import pytest
from services.percentage_training_service import (
    PercentageTrainingService,
    UserExercise1RM,
    TrainingIntensitySettings,
    WorkingWeightResult,
    LinkedExercise,
)


class TestWorkingWeightCalculation:
    """Tests for calculate_working_weight method."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PercentageTrainingService()

    def test_calculate_70_percent_of_100kg(self):
        """70% of 100kg should be 70kg (barbell rounds to 2.5kg)."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=100.0,
            intensity_percent=70,
            equipment_type='barbell',
        )
        assert result == 70.0

    def test_calculate_75_percent_of_100kg(self):
        """75% of 100kg should be 75kg."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=100.0,
            intensity_percent=75,
            equipment_type='barbell',
        )
        assert result == 75.0

    def test_calculate_85_percent_of_80kg(self):
        """85% of 80kg = 68kg, rounds to 67.5kg for barbell."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=80.0,
            intensity_percent=85,
            equipment_type='barbell',
        )
        assert result == 67.5

    def test_dumbbell_rounding(self):
        """Dumbbells round to 2kg increments."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=50.0,
            intensity_percent=70,
            equipment_type='dumbbell',
        )
        # 50 * 0.70 = 35, rounds to 2kg increment = 36
        assert result == 36.0

    def test_machine_rounding(self):
        """Machines round to 5kg increments."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=100.0,
            intensity_percent=73,
            equipment_type='machine',
        )
        # 100 * 0.73 = 73, rounds to 5kg increment = 75
        assert result == 75.0

    def test_kettlebell_rounding(self):
        """Kettlebells round to 4kg increments."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=40.0,
            intensity_percent=80,
            equipment_type='kettlebell',
        )
        # 40 * 0.80 = 32, rounds to 4kg increment = 32
        assert result == 32.0

    def test_bodyweight_no_rounding(self):
        """Bodyweight exercises don't round."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=70.0,
            intensity_percent=75,
            equipment_type='bodyweight',
        )
        # 70 * 0.75 = 52.5, no rounding
        assert result == 52.5

    def test_intensity_below_50_clamped(self):
        """Intensity below 50% should be clamped to 50%."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=100.0,
            intensity_percent=30,
            equipment_type='barbell',
        )
        # Should use 50% = 50kg
        assert result == 50.0

    def test_intensity_above_100_clamped(self):
        """Intensity above 100% should be clamped to 100%."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=100.0,
            intensity_percent=120,
            equipment_type='barbell',
        )
        # Should use 100% = 100kg
        assert result == 100.0


class TestIntensityDescriptions:
    """Tests for intensity level descriptions."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PercentageTrainingService()

    def test_light_intensity(self):
        """50-60% should be Light/Recovery."""
        description = self.service.get_intensity_description(55)
        assert 'Light' in description or 'Recovery' in description

    def test_moderate_intensity(self):
        """61-70% should be Moderate/Endurance."""
        description = self.service.get_intensity_description(65)
        assert 'Moderate' in description or 'Endurance' in description

    def test_working_intensity(self):
        """71-80% should be Working/Hypertrophy."""
        description = self.service.get_intensity_description(75)
        assert 'Working' in description or 'Hypertrophy' in description

    def test_heavy_intensity(self):
        """81-90% should be Heavy/Strength."""
        description = self.service.get_intensity_description(85)
        assert 'Heavy' in description or 'Strength' in description

    def test_max_intensity(self):
        """91-100% should be Near Max/Peaking."""
        description = self.service.get_intensity_description(95)
        assert 'Max' in description or 'Peaking' in description


class TestRPEConversion:
    """Tests for RPE to percentage conversion."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PercentageTrainingService()

    def test_rpe_10_is_100_percent(self):
        """RPE 10 should be 100% of 1RM."""
        result = self.service.rpe_to_percentage(10.0)
        assert result == 100

    def test_rpe_9_is_96_percent(self):
        """RPE 9 should be 96% of 1RM."""
        result = self.service.rpe_to_percentage(9.0)
        assert result == 96

    def test_rpe_8_is_92_percent(self):
        """RPE 8 should be 92% of 1RM."""
        result = self.service.rpe_to_percentage(8.0)
        assert result == 92

    def test_rpe_7_is_86_percent(self):
        """RPE 7 should be 86% of 1RM."""
        result = self.service.rpe_to_percentage(7.0)
        assert result == 86

    def test_rpe_6_is_80_percent(self):
        """RPE 6 should be 80% of 1RM."""
        result = self.service.rpe_to_percentage(6.0)
        assert result == 80

    def test_rpe_above_10_clamped(self):
        """RPE above 10 should return 100%."""
        result = self.service.rpe_to_percentage(11.0)
        assert result == 100

    def test_rpe_below_5_returns_74(self):
        """RPE below 5 should return 74%."""
        result = self.service.rpe_to_percentage(4.0)
        assert result == 74


class TestDataClasses:
    """Tests for data class functionality."""

    def test_user_exercise_1rm_creation(self):
        """Test creating a UserExercise1RM object."""
        one_rm = UserExercise1RM(
            exercise_name='Bench Press',
            one_rep_max_kg=100.0,
            source='manual',
            confidence=1.0,
        )
        assert one_rm.exercise_name == 'Bench Press'
        assert one_rm.one_rep_max_kg == 100.0
        assert one_rm.source == 'manual'
        assert one_rm.confidence == 1.0

    def test_training_intensity_settings_creation(self):
        """Test creating TrainingIntensitySettings."""
        settings = TrainingIntensitySettings(
            global_intensity_percent=75,
            exercise_overrides={'bench press': 80, 'squat': 70},
        )
        assert settings.global_intensity_percent == 75
        assert settings.exercise_overrides['bench press'] == 80
        assert settings.exercise_overrides['squat'] == 70

    def test_working_weight_result_creation(self):
        """Test creating WorkingWeightResult."""
        result = WorkingWeightResult(
            exercise_name='Squat',
            one_rep_max_kg=140.0,
            intensity_percent=75,
            working_weight_kg=105.0,
            is_from_override=False,
        )
        assert result.exercise_name == 'Squat'
        assert result.one_rep_max_kg == 140.0
        assert result.intensity_percent == 75
        assert result.working_weight_kg == 105.0
        assert result.is_from_override is False


class TestWeightIncrements:
    """Tests for equipment weight increments."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PercentageTrainingService()

    def test_barbell_increment_is_2_5(self):
        """Barbell increment should be 2.5kg."""
        assert self.service.WEIGHT_INCREMENTS['barbell'] == 2.5

    def test_dumbbell_increment_is_2(self):
        """Dumbbell increment should be 2kg."""
        assert self.service.WEIGHT_INCREMENTS['dumbbell'] == 2.0

    def test_machine_increment_is_5(self):
        """Machine increment should be 5kg."""
        assert self.service.WEIGHT_INCREMENTS['machine'] == 5.0

    def test_cable_increment_is_2_5(self):
        """Cable increment should be 2.5kg."""
        assert self.service.WEIGHT_INCREMENTS['cable'] == 2.5

    def test_kettlebell_increment_is_4(self):
        """Kettlebell increment should be 4kg."""
        assert self.service.WEIGHT_INCREMENTS['kettlebell'] == 4.0

    def test_bodyweight_increment_is_0(self):
        """Bodyweight increment should be 0 (no rounding)."""
        assert self.service.WEIGHT_INCREMENTS['bodyweight'] == 0


class TestEdgeCases:
    """Tests for edge cases."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PercentageTrainingService()

    def test_very_small_weight(self):
        """Test with very small weight (5kg 1RM at 70%)."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=5.0,
            intensity_percent=70,
            equipment_type='dumbbell',
        )
        # 5 * 0.70 = 3.5, rounds to 2kg increment = 4
        assert result == 4.0

    def test_very_large_weight(self):
        """Test with very large weight (300kg 1RM at 80%)."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=300.0,
            intensity_percent=80,
            equipment_type='barbell',
        )
        # 300 * 0.80 = 240
        assert result == 240.0

    def test_50_percent_minimum(self):
        """Test 50% intensity (minimum allowed)."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=100.0,
            intensity_percent=50,
            equipment_type='barbell',
        )
        assert result == 50.0

    def test_100_percent_maximum(self):
        """Test 100% intensity (maximum allowed)."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=100.0,
            intensity_percent=100,
            equipment_type='barbell',
        )
        assert result == 100.0

    def test_unknown_equipment_uses_default_increment(self):
        """Unknown equipment should use 2.5kg default increment."""
        result = self.service.calculate_working_weight(
            one_rep_max_kg=100.0,
            intensity_percent=73,
            equipment_type='unknown_equipment',
        )
        # 100 * 0.73 = 73, rounds to 2.5kg increment = 72.5
        assert result == 72.5


class TestEquipmentMultipliers:
    """Tests for equipment multipliers used in linked exercise calculations."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PercentageTrainingService()

    def test_barbell_is_baseline(self):
        """Barbell should be the baseline (1.0)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['barbell'] == 1.0

    def test_dumbbell_multiplier(self):
        """Dumbbell should be 0.85 (85% of barbell)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['dumbbell'] == 0.85

    def test_machine_multiplier(self):
        """Machine should be 0.90 (90% of barbell)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['machine'] == 0.90

    def test_cable_multiplier(self):
        """Cable should be 0.80 (80% of barbell)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['cable'] == 0.80

    def test_kettlebell_multiplier(self):
        """Kettlebell should be 0.75 (75% of barbell)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['kettlebell'] == 0.75

    def test_bodyweight_multiplier(self):
        """Bodyweight should be 0.70 (70% of barbell)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['bodyweight'] == 0.70

    def test_smith_machine_multiplier(self):
        """Smith machine should be 0.95 (95% of barbell)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['smith_machine'] == 0.95

    def test_ez_bar_multiplier(self):
        """EZ bar should be 0.95 (95% of barbell)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['ez_bar'] == 0.95

    def test_trap_bar_multiplier(self):
        """Trap bar should be 1.0 (same as barbell)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['trap_bar'] == 1.0

    def test_resistance_band_multiplier(self):
        """Resistance band should be 0.60 (60% of barbell)."""
        assert self.service.EQUIPMENT_MULTIPLIERS['resistance_band'] == 0.60


class TestLinkedExerciseDataClasses:
    """Tests for LinkedExercise and enhanced WorkingWeightResult data classes."""

    def test_working_weight_result_with_source_fields(self):
        """WorkingWeightResult should have source tracking fields."""
        result = WorkingWeightResult(
            exercise_name='Incline Dumbbell Press',
            one_rep_max_kg=85.0,
            intensity_percent=75,
            working_weight_kg=63.75,
            is_from_override=False,
            source_type='linked',
            source_exercise='Barbell Bench Press',
            equipment_multiplier=0.85,
        )
        assert result.exercise_name == 'Incline Dumbbell Press'
        assert result.source_type == 'linked'
        assert result.source_exercise == 'Barbell Bench Press'
        assert result.equipment_multiplier == 0.85

    def test_working_weight_result_defaults(self):
        """WorkingWeightResult should have sensible defaults for new fields."""
        result = WorkingWeightResult(
            exercise_name='Squat',
            one_rep_max_kg=100.0,
            intensity_percent=75,
            working_weight_kg=75.0,
            is_from_override=False,
        )
        assert result.source_type == 'direct'
        assert result.source_exercise is None
        assert result.equipment_multiplier == 1.0

    def test_linked_exercise_creation(self):
        """Test creating a LinkedExercise object."""
        from services.percentage_training_service import LinkedExercise

        link = LinkedExercise(
            id='test-uuid',
            user_id='user-uuid',
            primary_exercise_name='Barbell Bench Press',
            linked_exercise_name='Incline Dumbbell Press',
            strength_multiplier=0.85,
            relationship_type='variant',
            notes='Incline is harder than flat',
        )
        assert link.primary_exercise_name == 'Barbell Bench Press'
        assert link.linked_exercise_name == 'Incline Dumbbell Press'
        assert link.strength_multiplier == 0.85
        assert link.relationship_type == 'variant'
        assert link.notes == 'Incline is harder than flat'


class TestEquipmentScaling:
    """Tests for equipment-based weight scaling calculations."""

    def setup_method(self):
        """Set up test fixtures."""
        self.service = PercentageTrainingService()

    def test_barbell_to_dumbbell_scaling(self):
        """Barbell 1RM should scale down to dumbbell by 0.85."""
        # If barbell bench is 100kg, dumbbell should be ~85kg
        barbell_1rm = 100.0
        barbell_mult = self.service.EQUIPMENT_MULTIPLIERS['barbell']
        dumbbell_mult = self.service.EQUIPMENT_MULTIPLIERS['dumbbell']

        expected = barbell_1rm * (dumbbell_mult / barbell_mult)
        assert expected == 85.0

    def test_dumbbell_to_barbell_scaling(self):
        """Dumbbell 1RM should scale up to barbell by 1/0.85."""
        # If dumbbell bench is 85kg, barbell should be ~100kg
        dumbbell_1rm = 85.0
        barbell_mult = self.service.EQUIPMENT_MULTIPLIERS['barbell']
        dumbbell_mult = self.service.EQUIPMENT_MULTIPLIERS['dumbbell']

        expected = dumbbell_1rm * (barbell_mult / dumbbell_mult)
        assert expected == 100.0

    def test_barbell_to_cable_scaling(self):
        """Barbell 1RM should scale down to cable by 0.80."""
        barbell_1rm = 100.0
        barbell_mult = self.service.EQUIPMENT_MULTIPLIERS['barbell']
        cable_mult = self.service.EQUIPMENT_MULTIPLIERS['cable']

        expected = barbell_1rm * (cable_mult / barbell_mult)
        assert expected == 80.0

    def test_machine_to_barbell_scaling(self):
        """Machine 1RM should scale up to barbell by 1/0.90."""
        machine_1rm = 90.0
        barbell_mult = self.service.EQUIPMENT_MULTIPLIERS['barbell']
        machine_mult = self.service.EQUIPMENT_MULTIPLIERS['machine']

        expected = machine_1rm * (barbell_mult / machine_mult)
        assert expected == 100.0


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
