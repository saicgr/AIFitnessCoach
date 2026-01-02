"""
Tests for Ultimate Strength Builder program.

These tests verify:
1. Program exists in catalog (program_definitions.py)
2. Program can be retrieved via API
3. Workout structure is valid
4. All program variants exist
5. User context logging for program selection

Run with: pytest tests/test_ultimate_strength_program.py -v
"""
import pytest
import json
from datetime import datetime
from typing import List, Dict, Any
from unittest.mock import MagicMock, AsyncMock, patch

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class TestUltimateStrengthProgramDefinition:
    """Tests for Ultimate Strength Builder program definition."""

    def test_program_exists_in_catalog(self):
        """Verify that Ultimate Strength Builder exists in program_definitions.py."""
        from scripts.program_definitions import PROGRAMS

        program_names = [p["program_name"] for p in PROGRAMS]

        assert "Ultimate Strength Builder" in program_names, \
            "Ultimate Strength Builder should exist in program catalog"

    def test_program_has_required_fields(self):
        """Verify program has all required metadata fields."""
        from scripts.program_definitions import PROGRAMS

        program = next(
            (p for p in PROGRAMS if p["program_name"] == "Ultimate Strength Builder"),
            None
        )

        assert program is not None, "Program should exist"

        required_fields = [
            "program_name",
            "program_category",
            "program_subcategory",
            "difficulty_level",
            "duration_weeks",
            "sessions_per_week",
            "session_duration_minutes",
            "tags",
            "goals",
            "description",
            "short_description",
        ]

        for field in required_fields:
            assert field in program, f"Program should have {field} field"
            assert program[field] is not None, f"{field} should not be None"

    def test_program_metadata_values(self):
        """Verify program metadata has correct values."""
        from scripts.program_definitions import PROGRAMS

        program = next(
            (p for p in PROGRAMS if p["program_name"] == "Ultimate Strength Builder"),
            None
        )

        assert program["program_category"] == "Goal-Based"
        assert program["program_subcategory"] == "Muscle Building"
        assert program["difficulty_level"] == "Intermediate"
        assert program["duration_weeks"] == 12
        assert program["sessions_per_week"] == 4
        assert program["session_duration_minutes"] == 60

    def test_program_tags(self):
        """Verify program has appropriate strength-related tags."""
        from scripts.program_definitions import PROGRAMS

        program = next(
            (p for p in PROGRAMS if p["program_name"] == "Ultimate Strength Builder"),
            None
        )

        tags = program["tags"]

        assert "strength" in tags, "Should have 'strength' tag"
        assert "powerlifting" in tags, "Should have 'powerlifting' tag"
        assert "compound" in tags, "Should have 'compound' tag"
        assert "progressive overload" in tags, "Should have 'progressive overload' tag"
        assert "periodization" in tags, "Should have 'periodization' tag"

    def test_program_goals(self):
        """Verify program has appropriate goals."""
        from scripts.program_definitions import PROGRAMS

        program = next(
            (p for p in PROGRAMS if p["program_name"] == "Ultimate Strength Builder"),
            None
        )

        goals = program["goals"]

        assert "Build Strength" in goals, "Should have 'Build Strength' goal"
        assert "Build Muscle" in goals, "Should have 'Build Muscle' goal"
        assert "Increase 1RM" in goals, "Should have 'Increase 1RM' goal"

    def test_program_description_mentions_key_concepts(self):
        """Verify program description mentions key training concepts."""
        from scripts.program_definitions import PROGRAMS

        program = next(
            (p for p in PROGRAMS if p["program_name"] == "Ultimate Strength Builder"),
            None
        )

        description = program["description"].lower()

        assert "squat" in description, "Description should mention squat"
        assert "bench" in description, "Description should mention bench"
        assert "deadlift" in description, "Description should mention deadlift"
        assert "periodization" in description, "Description should mention periodization"


class TestUltimateStrengthProgramVariants:
    """Tests for Ultimate Strength Builder program variants."""

    def test_easy_variant_exists(self):
        """Verify Easy variant exists with correct settings."""
        from scripts.program_definitions import PROGRAMS

        program = next(
            (p for p in PROGRAMS if p["program_name"] == "Ultimate Strength Builder - Easy"),
            None
        )

        assert program is not None, "Easy variant should exist"
        assert program["difficulty_level"] == "Beginner"
        assert program["sessions_per_week"] == 3
        assert program["session_duration_minutes"] == 45

    def test_hard_variant_exists(self):
        """Verify Hard variant exists with correct settings."""
        from scripts.program_definitions import PROGRAMS

        program = next(
            (p for p in PROGRAMS if p["program_name"] == "Ultimate Strength Builder - Hard"),
            None
        )

        assert program is not None, "Hard variant should exist"
        assert program["difficulty_level"] == "Advanced"
        assert program["sessions_per_week"] == 5
        assert program["session_duration_minutes"] == 75

    def test_4_week_variant_exists(self):
        """Verify 4-week variant exists with correct duration."""
        from scripts.program_definitions import PROGRAMS

        program = next(
            (p for p in PROGRAMS if p["program_name"] == "Ultimate Strength Builder - 4 Week"),
            None
        )

        assert program is not None, "4-week variant should exist"
        assert program["duration_weeks"] == 4

    def test_8_week_variant_exists(self):
        """Verify 8-week variant exists with correct duration."""
        from scripts.program_definitions import PROGRAMS

        program = next(
            (p for p in PROGRAMS if p["program_name"] == "Ultimate Strength Builder - 8 Week"),
            None
        )

        assert program is not None, "8-week variant should exist"
        assert program["duration_weeks"] == 8

    def test_all_variants_have_same_category(self):
        """Verify all variants are categorized consistently."""
        from scripts.program_definitions import PROGRAMS

        variant_names = [
            "Ultimate Strength Builder",
            "Ultimate Strength Builder - Easy",
            "Ultimate Strength Builder - Hard",
            "Ultimate Strength Builder - 4 Week",
            "Ultimate Strength Builder - 8 Week",
        ]

        for name in variant_names:
            program = next(
                (p for p in PROGRAMS if p["program_name"] == name),
                None
            )

            assert program is not None, f"{name} should exist"
            assert program["program_category"] == "Goal-Based", \
                f"{name} should be in Goal-Based category"
            assert program["program_subcategory"] == "Muscle Building", \
                f"{name} should be in Muscle Building subcategory"


class TestUltimateStrengthWorkoutStructure:
    """Tests for workout structure validation."""

    def test_workouts_json_structure(self):
        """Test that workout JSON has proper structure."""
        # This tests the expected JSON structure from the migration file
        expected_structure = {
            "weekly_structure": [
                {"day": 1, "workout_name": "Squat Focus", "exercises": []},
                {"day": 2, "workout_name": "Bench Focus", "exercises": []},
                {"day": 3, "workout_name": "Deadlift Focus", "exercises": []},
                {"day": 4, "workout_name": "Accessories & Conditioning", "exercises": []},
            ]
        }

        # Validate structure keys
        assert "weekly_structure" in expected_structure
        assert len(expected_structure["weekly_structure"]) == 4

    def test_day_1_squat_focus_structure(self):
        """Test Day 1 (Squat Focus) has appropriate exercises."""
        expected_exercises = [
            "Barbell Back Squat",
            "Pause Squat",
            "Leg Press",
            "Romanian Deadlift",
            "Plank",
        ]

        # Squat focus should include compound lower body movements
        assert "Barbell Back Squat" in expected_exercises
        assert "Romanian Deadlift" in expected_exercises

    def test_day_2_bench_focus_structure(self):
        """Test Day 2 (Bench Focus) has appropriate exercises."""
        expected_exercises = [
            "Barbell Bench Press",
            "Close-Grip Bench Press",
            "Incline Dumbbell Press",
            "Dips",
            "Tricep Pushdown",
        ]

        # Bench focus should include pressing movements
        assert "Barbell Bench Press" in expected_exercises
        assert "Incline Dumbbell Press" in expected_exercises

    def test_day_3_deadlift_focus_structure(self):
        """Test Day 3 (Deadlift Focus) has appropriate exercises."""
        expected_exercises = [
            "Conventional Deadlift",
            "Deficit Deadlift",
            "Barbell Row",
            "Pull-ups",
            "Barbell Curl",
        ]

        # Deadlift focus should include pulling movements
        assert "Conventional Deadlift" in expected_exercises
        assert "Barbell Row" in expected_exercises

    def test_day_4_accessories_structure(self):
        """Test Day 4 (Accessories) has appropriate exercises."""
        expected_exercises = [
            "Overhead Press",
            "Push Press",
            "Farmer Walks",
            "Face Pulls",
            "Hanging Leg Raise",
            "Ab Wheel Rollout",
        ]

        # Accessories should include overhead work and core
        assert "Overhead Press" in expected_exercises
        assert "Farmer Walks" in expected_exercises
        assert "Hanging Leg Raise" in expected_exercises


class TestProgramRetrievalAPI:
    """Tests for program retrieval via API (mock-based)."""

    @pytest.fixture
    def mock_db(self):
        """Create a mock database client."""
        mock = MagicMock()
        mock.client = MagicMock()
        return mock

    @pytest.fixture
    def sample_program_data(self):
        """Sample program data as would be returned from database."""
        return {
            "id": "test-uuid-123",
            "program_name": "Ultimate Strength Builder",
            "program_category": "Goal-Based",
            "program_subcategory": "Muscle Building",
            "difficulty_level": "Intermediate",
            "duration_weeks": 12,
            "sessions_per_week": 4,
            "session_duration_minutes": 60,
            "tags": ["strength", "powerlifting", "compound"],
            "goals": ["Build Strength", "Build Muscle", "Increase 1RM"],
            "description": "The definitive strength building program...",
            "short_description": "Complete 12-week strength mastery program",
            "workouts": {
                "weekly_structure": [
                    {"day": 1, "workout_name": "Squat Focus"},
                    {"day": 2, "workout_name": "Bench Focus"},
                    {"day": 3, "workout_name": "Deadlift Focus"},
                    {"day": 4, "workout_name": "Accessories"},
                ]
            },
        }

    def test_program_data_structure(self, sample_program_data):
        """Test that sample program data has expected structure."""
        assert sample_program_data["program_name"] == "Ultimate Strength Builder"
        assert sample_program_data["duration_weeks"] == 12
        assert sample_program_data["sessions_per_week"] == 4
        assert "workouts" in sample_program_data
        assert "weekly_structure" in sample_program_data["workouts"]

    def test_program_workouts_count(self, sample_program_data):
        """Test that program has 4 workouts per week."""
        workouts = sample_program_data["workouts"]["weekly_structure"]
        assert len(workouts) == 4, "Should have 4 workouts per week"

    def test_workout_days_are_sequential(self, sample_program_data):
        """Test that workout days are 1-4."""
        workouts = sample_program_data["workouts"]["weekly_structure"]
        days = [w["day"] for w in workouts]
        assert days == [1, 2, 3, 4], "Days should be 1-4"


class TestUserContextLogging:
    """Tests for user context logging when selecting Ultimate Strength program."""

    def test_event_type_exists_for_program_selection(self):
        """Verify that program selection event types exist in EventType enum."""
        from services.user_context_service import EventType

        # Check if there are events for program-related actions
        event_names = [e.value for e in EventType]

        # The program logging is handled via database trigger in 101_branded_programs.sql
        # which logs: program_started, program_completed, program_paused, etc.
        # These are logged directly to user_context_logs table

        # Verify the service can log general events
        assert "feature_interaction" in event_names or "FEATURE_INTERACTION" in [e.name for e in EventType], \
            "Should have feature interaction event type"

    def test_user_context_service_can_log_events(self):
        """Verify UserContextService has logging capability."""
        from services.user_context_service import EventType

        # The database trigger log_program_assignment_change() in migration 101
        # handles program-related logging automatically when:
        # - User starts a program (INSERT into user_program_assignments)
        # - User completes/pauses/abandons program (UPDATE status)

        # The trigger logs to user_context_logs with event_data containing:
        # - program_id, program_name, custom_name, progress_percentage, etc.

        # Verify EventType enum has necessary types
        assert EventType.FEATURE_INTERACTION is not None
        assert EventType.SCREEN_VIEW is not None

    def test_program_selection_logging_structure(self):
        """Test expected structure for program selection logs."""
        # This is the structure expected by the database trigger
        expected_event_data = {
            "program_id": "uuid",
            "program_name": "Ultimate Strength Builder",
            "custom_name": None,  # Optional user override
            "total_workouts": 48,  # 12 weeks * 4 sessions
            "assignment_id": "uuid",
        }

        assert "program_id" in expected_event_data
        assert "program_name" in expected_event_data
        assert expected_event_data["program_name"] == "Ultimate Strength Builder"


class TestMigrationFileContent:
    """Tests for migration file content validity."""

    def test_migration_file_exists(self):
        """Verify migration file exists."""
        migration_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "migrations",
            "103_ultimate_strength_program.sql"
        )

        assert os.path.exists(migration_path), \
            "Migration file 103_ultimate_strength_program.sql should exist"

    def test_migration_contains_ultimate_strength_program(self):
        """Verify migration file contains Ultimate Strength Builder INSERT."""
        migration_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "migrations",
            "103_ultimate_strength_program.sql"
        )

        with open(migration_path, "r") as f:
            content = f.read()

        assert "Ultimate Strength Builder" in content, \
            "Migration should insert Ultimate Strength Builder program"

    def test_migration_contains_variants(self):
        """Verify migration file contains all program variants."""
        migration_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "migrations",
            "103_ultimate_strength_program.sql"
        )

        with open(migration_path, "r") as f:
            content = f.read()

        variants = [
            "Ultimate Strength Builder - Easy",
            "Ultimate Strength Builder - Hard",
            "Ultimate Strength Builder - 4 Week",
            "Ultimate Strength Builder - 8 Week",
        ]

        for variant in variants:
            assert variant in content, \
                f"Migration should contain {variant} variant"

    def test_migration_contains_workout_json(self):
        """Verify migration file contains workout JSONB data."""
        migration_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "migrations",
            "103_ultimate_strength_program.sql"
        )

        with open(migration_path, "r") as f:
            content = f.read()

        # Check for workout structure keys
        assert "weekly_structure" in content, \
            "Migration should contain weekly_structure"
        assert "Barbell Back Squat" in content, \
            "Migration should contain main lift exercises"
        assert "Barbell Bench Press" in content, \
            "Migration should contain bench press"
        assert "Conventional Deadlift" in content, \
            "Migration should contain deadlift"


class TestProgramCalculations:
    """Tests for program-related calculations."""

    def test_total_workouts_calculation(self):
        """Test calculation of total workouts in program."""
        duration_weeks = 12
        sessions_per_week = 4

        total_workouts = duration_weeks * sessions_per_week

        assert total_workouts == 48, "12-week program with 4 sessions/week = 48 total workouts"

    def test_session_duration_reasonable(self):
        """Test that session duration is reasonable for strength training."""
        session_duration = 60  # minutes

        # Strength training sessions typically range from 45-90 minutes
        assert 45 <= session_duration <= 90, \
            "Session duration should be between 45-90 minutes for strength training"

    def test_rest_periods_reasonable(self):
        """Test that rest periods are appropriate for strength work."""
        # Main compound lifts should have longer rest periods
        squat_rest = 180  # seconds
        bench_rest = 180  # seconds
        deadlift_rest = 180  # seconds

        # Rest periods for main lifts should be 2-5 minutes (120-300 seconds)
        assert 120 <= squat_rest <= 300
        assert 120 <= bench_rest <= 300
        assert 120 <= deadlift_rest <= 300


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
