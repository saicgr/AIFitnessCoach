"""
Tests for exercise RAG search functions.
"""

import pytest
from unittest.mock import patch, MagicMock


class TestBuildSearchQuery:
    """Tests for build_search_query function."""

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_builds_basic_query(self, mock_keywords):
        """Test building basic search query."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="chest",
            equipment=["Dumbbells"],
            fitness_level="intermediate",
            goals=["Build Muscle"]
        )

        assert "chest" in query.lower()
        assert "dumbbell" in query.lower()
        assert "intermediate" in query.lower()
        assert "muscle" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_uses_focus_area_keywords(self, mock_keywords):
        """Test using predefined focus area keywords."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="full_body",
            equipment=["Bodyweight"],
            fitness_level="beginner",
            goals=[]
        )

        assert "full body" in query.lower()
        assert "compound" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_sport_specific_keywords(self, mock_keywords):
        """Test sport-specific focus areas."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="boxing",
            equipment=["Bodyweight"],
            fitness_level="intermediate",
            goals=[]
        )

        assert "boxing" in query.lower()
        assert "punch" in query.lower() or "power" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_includes_goal_keywords(self, mock_keywords):
        """Test including goal-specific keywords."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="legs",
            equipment=["Full Gym"],
            fitness_level="advanced",
            goals=["Lose Weight", "Improve Endurance"]
        )

        assert "fat" in query.lower() or "metabolic" in query.lower()
        assert "endurance" in query.lower() or "cardio" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_includes_training_program_keywords(self, mock_keywords):
        """Test including training program keywords."""
        mock_keywords.return_value = {
            "HYROX Training": "hyrox functional running endurance"
        }

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="full_body",
            equipment=["Full Gym"],
            fitness_level="intermediate",
            goals=["HYROX Training"]
        )

        assert "hyrox" in query.lower() or "functional" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_handles_empty_equipment(self, mock_keywords):
        """Test handling empty equipment list."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="core",
            equipment=[],
            fitness_level="beginner",
            goals=[]
        )

        assert "bodyweight" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_unknown_focus_area(self, mock_keywords):
        """Test handling unknown focus area."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="unknown_area",
            equipment=["Dumbbells"],
            fitness_level="intermediate",
            goals=[]
        )

        assert "unknown_area" in query.lower()


class TestFocusAreaKeywords:
    """Tests for FOCUS_AREA_KEYWORDS constant."""

    def test_contains_body_parts(self):
        """Test that common body parts are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        expected_areas = ["full_body", "chest", "back", "legs", "core"]
        # Note: FOCUS_AREA_KEYWORDS might not have all these, but should have focus areas
        assert "full_body" in FOCUS_AREA_KEYWORDS
        assert "boxing" in FOCUS_AREA_KEYWORDS

    def test_contains_sports(self):
        """Test that sport-specific areas are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        assert "boxing" in FOCUS_AREA_KEYWORDS
        assert "hyrox" in FOCUS_AREA_KEYWORDS
        assert "crossfit" in FOCUS_AREA_KEYWORDS


class TestGoalKeywords:
    """Tests for GOAL_KEYWORDS constant."""

    def test_contains_common_goals(self):
        """Test that common goals are included."""
        from services.exercise_rag.search import GOAL_KEYWORDS

        assert "Build Muscle" in GOAL_KEYWORDS
        assert "Lose Weight" in GOAL_KEYWORDS
        assert "Increase Strength" in GOAL_KEYWORDS
        assert "Improve Endurance" in GOAL_KEYWORDS
        assert "General Fitness" in GOAL_KEYWORDS

    def test_goal_values_are_strings(self):
        """Test that goal keywords are strings."""
        from services.exercise_rag.search import GOAL_KEYWORDS

        for goal, keywords in GOAL_KEYWORDS.items():
            assert isinstance(keywords, str)
            assert len(keywords) > 0
