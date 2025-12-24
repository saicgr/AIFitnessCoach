"""
Tests for library utility functions.

Tests cover:
- normalize_body_part
- derive_exercise_type
- derive_goals
- derive_suitable_for
- derive_avoids
- row_to_library_exercise
- row_to_library_program
"""
import pytest

from api.v1.library.utils import (
    normalize_body_part,
    derive_exercise_type,
    derive_goals,
    derive_suitable_for,
    derive_avoids,
    row_to_library_exercise,
    row_to_library_program,
)


class TestNormalizeBodyPart:
    """Tests for normalize_body_part function."""

    def test_chest_muscles(self):
        """Test chest muscle normalization."""
        assert normalize_body_part("pectoralis major") == "Chest"
        assert normalize_body_part("chest") == "Chest"

    def test_back_muscles(self):
        """Test back muscle normalization."""
        assert normalize_body_part("latissimus dorsi") == "Back"
        assert normalize_body_part("rhomboids") == "Back"
        assert normalize_body_part("trapezius") == "Back"

    def test_shoulder_muscles(self):
        """Test shoulder muscle normalization."""
        assert normalize_body_part("deltoid") == "Shoulders"
        assert normalize_body_part("shoulder") == "Shoulders"

    def test_arm_muscles(self):
        """Test arm muscle normalization."""
        assert normalize_body_part("biceps brachii") == "Biceps"
        assert normalize_body_part("triceps") == "Triceps"
        assert normalize_body_part("forearm") == "Forearms"

    def test_leg_muscles(self):
        """Test leg muscle normalization."""
        assert normalize_body_part("quadriceps") == "Quadriceps"
        assert normalize_body_part("hamstring") == "Hamstrings"
        assert normalize_body_part("glutes") == "Glutes"
        assert normalize_body_part("gastrocnemius") == "Calves"

    def test_core_muscles(self):
        """Test core muscle normalization."""
        assert normalize_body_part("rectus abdominis") == "Core"
        assert normalize_body_part("obliques") == "Core"
        assert normalize_body_part("core") == "Core"

    def test_other_muscles(self):
        """Test other muscle normalization."""
        assert normalize_body_part("lower back") == "Lower Back"
        assert normalize_body_part("hip adductors") == "Hips"
        assert normalize_body_part("neck") == "Neck"

    def test_empty_or_unknown(self):
        """Test empty or unknown values."""
        assert normalize_body_part("") == "Other"
        assert normalize_body_part(None) == "Other"
        assert normalize_body_part("unknown muscle") == "Other"


class TestDeriveExerciseType:
    """Tests for derive_exercise_type function."""

    def test_yoga_type(self):
        """Test yoga type derivation."""
        assert derive_exercise_type("s3://bucket/Yoga/pose.mp4", "Core") == "Yoga"

    def test_stretching_type(self):
        """Test stretching type derivation."""
        assert derive_exercise_type("s3://bucket/Stretch/hip.mp4", "Hips") == "Stretching"
        assert derive_exercise_type("s3://bucket/Mobility/ankle.mp4", "Calves") == "Stretching"

    def test_cardio_type(self):
        """Test cardio type derivation."""
        assert derive_exercise_type("s3://bucket/HIIT/burpee.mp4", "Core") == "Cardio"
        assert derive_exercise_type("s3://bucket/Cardio/run.mp4", "Quadriceps") == "Cardio"

    def test_strength_type(self):
        """Test strength type derivation."""
        assert derive_exercise_type("s3://bucket/Chest/press.mp4", "Chest") == "Strength"
        assert derive_exercise_type("s3://bucket/Back/row.mp4", "Back") == "Strength"

    def test_no_video_url(self):
        """Test with no video URL defaults appropriately."""
        assert derive_exercise_type("", "Chest") == "Strength"
        assert derive_exercise_type(None, "Core") == "Functional"


class TestDeriveGoals:
    """Tests for derive_goals function."""

    def test_testosterone_boost(self):
        """Test testosterone boost goal derivation."""
        goals = derive_goals("Barbell Squat", "Quadriceps", "quadriceps", "")
        assert "Testosterone Boost" in goals

    def test_fat_burn(self):
        """Test fat burn goal derivation."""
        goals = derive_goals("Burpees", "Core", "core", "s3://bucket/HIIT/burpee.mp4")
        assert "Fat Burn" in goals

    def test_muscle_building(self):
        """Test muscle building goal derivation."""
        goals = derive_goals("Dumbbell Curl", "Biceps", "biceps", "")
        assert "Muscle Building" in goals

    def test_flexibility(self):
        """Test flexibility goal derivation."""
        goals = derive_goals("Pigeon Pose", "Hips", "hip flexors", "s3://bucket/Yoga/pigeon.mp4")
        assert "Flexibility" in goals

    def test_core_strength(self):
        """Test core strength goal derivation."""
        goals = derive_goals("Plank Hold", "Core", "core", "")
        assert "Core Strength" in goals

    def test_default_general_fitness(self):
        """Test default to general fitness when no specific goals match."""
        goals = derive_goals("Random Exercise", "Other", "", "")
        assert "General Fitness" in goals


class TestDeriveSuitableFor:
    """Tests for derive_suitable_for function."""

    def test_beginner_friendly(self):
        """Test beginner friendly derivation."""
        suitable = derive_suitable_for("Wall Push-up", "Chest", "", "")
        assert "Beginner Friendly" in suitable

    def test_senior_friendly(self):
        """Test senior friendly derivation."""
        suitable = derive_suitable_for("Chair Squat", "Quadriceps", "", "")
        assert "Senior Friendly" in suitable

    def test_pregnancy_safe(self):
        """Test pregnancy safe derivation."""
        suitable = derive_suitable_for("Cat Cow Stretch", "Back", "", "")
        assert "Pregnancy Safe" in suitable

    def test_home_workout(self):
        """Test home workout friendly derivation."""
        suitable = derive_suitable_for("Bodyweight Squat", "Quadriceps", "bodyweight", "")
        assert "Home Workout" in suitable

    def test_low_impact(self):
        """Test low impact derivation."""
        suitable = derive_suitable_for("Yoga Pose", "Core", "", "s3://bucket/Yoga/pose.mp4")
        assert "Low Impact" in suitable


class TestDeriveAvoids:
    """Tests for derive_avoids function."""

    def test_knee_stress(self):
        """Test knee stress detection."""
        avoids = derive_avoids("Barbell Squat", "Quadriceps", "barbell")
        assert "Stresses Knees" in avoids

    def test_lower_back_stress(self):
        """Test lower back stress detection."""
        avoids = derive_avoids("Deadlift", "Back", "barbell")
        assert "Stresses Lower Back" in avoids

    def test_shoulder_stress(self):
        """Test shoulder stress detection."""
        avoids = derive_avoids("Overhead Press", "Shoulders", "barbell")
        assert "Stresses Shoulders" in avoids

    def test_wrist_stress(self):
        """Test wrist stress detection."""
        avoids = derive_avoids("Push-up", "Chest", "")
        assert "Stresses Wrists" in avoids

    def test_high_impact(self):
        """Test high impact detection."""
        avoids = derive_avoids("Box Jump", "Quadriceps", "")
        assert "High Impact" in avoids


class TestRowToLibraryExercise:
    """Tests for row_to_library_exercise conversion."""

    def test_from_cleaned_view(self):
        """Test conversion from cleaned view."""
        row = {
            "id": "ex-1",
            "name": "Squat",
            "original_name": "Squat_Male",
            "target_muscle": "quadriceps",
            "body_part": "legs",
            "equipment": "barbell",
            "instructions": "Stand, squat, repeat",
            "difficulty_level": 3,
            "gif_url": "https://example.com/squat.gif",
            "video_url": "s3://bucket/squat.mp4",
            "goals": ["Muscle Building"],
            "suitable_for": ["Gym"],
            "avoid_if": ["Stresses Knees"],
        }

        exercise = row_to_library_exercise(row, from_cleaned_view=True)

        assert exercise.id == "ex-1"
        assert exercise.name == "Squat"
        assert exercise.original_name == "Squat_Male"
        assert exercise.body_part == "Quadriceps"
        assert exercise.equipment == "barbell"

    def test_from_base_table(self):
        """Test conversion from base table."""
        row = {
            "id": "ex-2",
            "exercise_name": "Push_ups_Female",
            "target_muscle": "pectoralis major",
            "equipment": None,
            "video_s3_path": "s3://bucket/pushups.mp4",
        }

        exercise = row_to_library_exercise(row, from_cleaned_view=False)

        assert exercise.id == "ex-2"
        assert exercise.name == "Push_ups"  # Gender suffix removed
        assert exercise.original_name == "Push_ups_Female"
        assert exercise.body_part == "Chest"


class TestRowToLibraryProgram:
    """Tests for row_to_library_program conversion."""

    def test_full_program(self):
        """Test conversion with full program data."""
        row = {
            "id": "prog-1",
            "program_name": "Strength Builder",
            "program_category": "Strength Training",
            "program_subcategory": "Intermediate",
            "difficulty_level": "Intermediate",
            "duration_weeks": 8,
            "sessions_per_week": 4,
            "session_duration_minutes": 60,
            "tags": ["strength", "muscle"],
            "goals": ["Build Muscle", "Increase Strength"],
            "description": "An 8-week strength program",
            "short_description": "Build strength",
        }

        program = row_to_library_program(row)

        assert program.id == "prog-1"
        assert program.name == "Strength Builder"
        assert program.category == "Strength Training"
        assert program.duration_weeks == 8
        assert program.tags == ["strength", "muscle"]

    def test_minimal_program(self):
        """Test conversion with minimal program data."""
        row = {
            "id": "prog-2",
            "program_name": "Quick HIIT",
            "program_category": "Cardio",
        }

        program = row_to_library_program(row)

        assert program.id == "prog-2"
        assert program.name == "Quick HIIT"
        assert program.category == "Cardio"
        assert program.tags == []
        assert program.goals == []
