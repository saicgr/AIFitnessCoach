"""
Tests for exercise RAG utility functions.
"""

import pytest


class TestCleanExerciseNameForDisplay:
    """Tests for clean_exercise_name_for_display function."""

    def test_removes_female_suffix(self):
        """Test removing _female suffix."""
        from services.exercise_rag.utils import clean_exercise_name_for_display

        assert clean_exercise_name_for_display("Air Bike_female") == "Air Bike"
        assert clean_exercise_name_for_display("Push-up_Female") == "Push-up"

    def test_removes_male_suffix(self):
        """Test removing _male suffix."""
        from services.exercise_rag.utils import clean_exercise_name_for_display

        assert clean_exercise_name_for_display("Squat_male") == "Squat"
        assert clean_exercise_name_for_display("Deadlift_Male") == "Deadlift"

    def test_removes_version_suffix(self):
        """Test removing (version X) suffix."""
        from services.exercise_rag.utils import clean_exercise_name_for_display

        assert clean_exercise_name_for_display("Push-up (version 2)") == "Push-up"
        assert clean_exercise_name_for_display("Squat (Version 3)") == "Squat"

    def test_handles_empty_string(self):
        """Test handling empty string."""
        from services.exercise_rag.utils import clean_exercise_name_for_display

        assert clean_exercise_name_for_display("") == "Unknown Exercise"
        assert clean_exercise_name_for_display(None) == "Unknown Exercise"

    def test_preserves_normal_names(self):
        """Test preserving normal exercise names."""
        from services.exercise_rag.utils import clean_exercise_name_for_display

        assert clean_exercise_name_for_display("Bench Press") == "Bench Press"
        assert clean_exercise_name_for_display("Romanian Deadlift") == "Romanian Deadlift"


class TestInferEquipmentFromName:
    """Tests for infer_equipment_from_name function."""

    def test_infers_cable_machine(self):
        """Test inferring cable machine from name."""
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("cable machine fly") == "Cable Machine"
        assert infer_equipment_from_name("cable row") == "Cable Machine"

    def test_infers_barbell(self):
        """Test inferring barbell from name."""
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("barbell bench press") == "Barbell"
        assert infer_equipment_from_name("bar bell squat") == "Barbell"

    def test_infers_dumbbells(self):
        """Test inferring dumbbells from name."""
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("dumbbell curl") == "Dumbbells"
        assert infer_equipment_from_name("db bench press") == "Dumbbells"

    def test_infers_kettlebell(self):
        """Test inferring kettlebell from name."""
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("kettlebell swing") == "Kettlebell"
        assert infer_equipment_from_name("kb goblet squat") == "Kettlebell"

    def test_infers_resistance_bands(self):
        """Test inferring resistance bands from name."""
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("resistance band pull-apart") == "Resistance Bands"
        assert infer_equipment_from_name("band face pull") == "Resistance Bands"

    def test_infers_pull_up_bar(self):
        """Test inferring pull-up bar from name."""
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("pull-up bar hang") == "Pull-up Bar"
        assert infer_equipment_from_name("chin-up bar exercise") == "Pull-up Bar"

    def test_infers_machine(self):
        """Test inferring machine from name."""
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("leg press machine") == "Machine"
        assert infer_equipment_from_name("lat pulldown") == "Machine"

    def test_defaults_to_bodyweight(self):
        """Test defaulting to bodyweight for unknown equipment."""
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("push-up") == "Bodyweight"
        assert infer_equipment_from_name("plank") == "Bodyweight"
        assert infer_equipment_from_name("burpee") == "Bodyweight"

    def test_handles_empty_string(self):
        """Test handling empty string."""
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("") == "Bodyweight"
        assert infer_equipment_from_name(None) == "Bodyweight"
