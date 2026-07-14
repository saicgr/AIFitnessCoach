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
        """Test inferring resistance bands from name.

        RETIRED ASSERTION: this used to expect the plural "Resistance Bands".
        The per-exercise equipment label is singular ("Resistance Band") — the
        plural is the USER-PROFILE label (see `_EQUIPMENT_DISPLAY_MAP`
        `resistance_bands` -> "Resistance Bands" and the onboarding extractor).
        The two forms are reconciled by the alias-aware `filter_by_equipment`
        (see tests/test_filter_equipment_aliases.py::test_b7_resistance_band_underscore_plural,
        which pins "Resistance Band" matching a user's `resistance_bands`), and
        every caller of `infer_equipment_from_name` routes its result through
        that filter rather than comparing strings directly.

        Guarantee protected now: band exercises resolve to the band equipment
        label (not Bodyweight), for both "resistance band ..." and bare "band ...".
        """
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("resistance band pull-apart") == "Resistance Band"
        assert infer_equipment_from_name("band face pull") == "Resistance Band"

    def test_infers_pull_up_bar(self):
        """Test inferring pull-up bar from name.

        RETIRED ASSERTION: expected "Pull-up Bar"; the canonical casing is
        "Pull-Up Bar" (compound-word hyphenates are title-cased on both sides —
        see `_HYPHENATION_FIXES` and `_EQUIPMENT_DISPLAY_MAP` in
        services/exercise_rag/utils.py). Same guarantee, corrected casing.
        """
        from services.exercise_rag.utils import infer_equipment_from_name

        assert infer_equipment_from_name("pull-up bar hang") == "Pull-Up Bar"
        assert infer_equipment_from_name("chin-up bar exercise") == "Pull-Up Bar"

    def test_infers_machine(self):
        """Test inferring machine equipment from name.

        RETIRED ASSERTIONS: this used to expect the generic "Machine" for
        "leg press machine" and "lat pulldown". Those now resolve to their
        SPECIFIC machines ("Leg Press Machine", "Lat Pulldown Machine") — the
        pattern table is deliberately ordered specific-first, with generic
        "machine" as the LAST fallback, so the coach can tell a user which
        machine to walk to. The original intent (a machine name never falls
        through to "Bodyweight", and the generic catch-all still works) is
        preserved and strengthened below.
        """
        from services.exercise_rag.utils import infer_equipment_from_name

        # Specific machines win over the generic fallback.
        assert infer_equipment_from_name("leg press machine") == "Leg Press Machine"
        assert infer_equipment_from_name("lat pulldown") == "Lat Pulldown Machine"

        # Generic catch-all still fires for machines with no specific rule.
        assert infer_equipment_from_name("chest fly machine") == "Machine"
        assert infer_equipment_from_name("seated calf raise machine") == "Machine"

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
