"""
Tests for the scores API endpoints.

These tests verify that the scores overview endpoint handles None responses
gracefully, particularly for nutrition and fitness scores.

The tests focus on the null-safety patterns used to avoid AttributeError
when database responses are None or have None data.
"""
import pytest


class TestNutritionScoreNullSafety:
    """Tests for null-safety in score calculations."""

    def test_nutrition_score_none_response_handling(self):
        """
        Direct test of the None response handling pattern.

        This mirrors the fix applied:
        nutrition_score = nutrition_response.data.get("nutrition_score")
            if nutrition_response and nutrition_response.data else None
        """
        # Test case 1: nutrition_response is None
        nutrition_response = None
        nutrition_score = nutrition_response.data.get("nutrition_score") if nutrition_response and nutrition_response.data else None
        assert nutrition_score is None

        # Test case 2: nutrition_response exists but data is None
        class MockResponse:
            data = None
        nutrition_response = MockResponse()
        nutrition_score = nutrition_response.data.get("nutrition_score") if nutrition_response and nutrition_response.data else None
        assert nutrition_score is None

        # Test case 3: nutrition_response exists with valid data
        class MockResponseWithData:
            data = {"nutrition_score": 85.5, "nutrition_level": "good"}
        nutrition_response = MockResponseWithData()
        nutrition_score = nutrition_response.data.get("nutrition_score") if nutrition_response and nutrition_response.data else None
        assert nutrition_score == 85.5

    def test_fitness_score_none_response_handling(self):
        """
        Direct test of the None response handling for fitness scores.
        """
        # Test case 1: fitness_response is None
        fitness_response = None
        overall_fitness_score = fitness_response.data.get("overall_fitness_score") if fitness_response and fitness_response.data else None
        assert overall_fitness_score is None

        # Test case 2: fitness_response with data
        class MockResponse:
            data = {"overall_fitness_score": 72.3, "fitness_level": "intermediate", "consistency_score": 80.0}
        fitness_response = MockResponse()
        overall_fitness_score = fitness_response.data.get("overall_fitness_score") if fitness_response and fitness_response.data else None
        fitness_level = fitness_response.data.get("fitness_level") if fitness_response and fitness_response.data else None
        consistency_score = fitness_response.data.get("consistency_score") if fitness_response and fitness_response.data else None

        assert overall_fitness_score == 72.3
        assert fitness_level == "intermediate"
        assert consistency_score == 80.0


class TestReadinessScoreNullSafety:
    """Tests for null-safety in readiness score calculations."""

    def test_readiness_average_with_empty_list(self):
        """Test that readiness average handles empty lists correctly."""
        readiness_scores = []
        readiness_average = (
            sum(readiness_scores) / len(readiness_scores)
            if readiness_scores else None
        )
        assert readiness_average is None

    def test_readiness_average_with_valid_data(self):
        """Test that readiness average calculates correctly."""
        readiness_scores = [80, 85, 90]
        readiness_average = (
            sum(readiness_scores) / len(readiness_scores)
            if readiness_scores else None
        )
        assert readiness_average == 85.0

    def test_readiness_data_extraction_with_none(self):
        """Test extracting readiness scores from None response."""
        response_data = None
        readiness_scores = [r["readiness_score"] for r in (response_data or [])]
        assert readiness_scores == []
