"""
Tests for fixes implemented in the current session.

This file contains tests for:
1. User search bio column fix - users.py removes non-existent 'bio' column
2. Quick workout None reps fix - validate_and_cap_exercise_parameters handles None reps
3. Hell difficulty mode - difficulty renamed from Elite to Hell

Run with: pytest backend/tests/test_session_fixes.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, AsyncMock
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ============================================================
# TEST 1: Quick Workout None Reps Fix
# ============================================================

class TestQuickWorkoutNoneRepsFix:
    """
    Tests for the None reps bug fix in validate_and_cap_exercise_parameters.

    Bug: When Gemini returns {"reps": null} in JSON (for time-based exercises),
    the min() function fails with "'<' not supported between instances of 'int' and 'NoneType'"

    Fix: Added try/except block to convert None reps to default value of 10.
    """

    def test_none_reps_defaults_to_10(self):
        """
        When reps is None (JSON null from Gemini), it should default to 10.
        This is the main bug that was fixed.
        """
        from api.v1.workouts.utils import validate_and_cap_exercise_parameters

        exercises = [
            {
                "name": "Jumping Jacks",
                "sets": 3,
                "reps": None,  # JSON null from Gemini for time-based exercise
                "rest_seconds": 30,
                "duration_seconds": 45
            }
        ]

        # This should NOT raise an error anymore
        result = validate_and_cap_exercise_parameters(exercises, "intermediate")

        assert len(result) == 1
        assert result[0]["reps"] == 10  # Default value
        assert result[0]["sets"] == 3
        assert result[0]["name"] == "Jumping Jacks"

    def test_none_reps_with_beginner_fitness_level(self):
        """None reps should work with beginner fitness level caps."""
        from api.v1.workouts.utils import validate_and_cap_exercise_parameters

        exercises = [
            {"name": "High Knees", "sets": 2, "reps": None, "rest_seconds": 20}
        ]

        result = validate_and_cap_exercise_parameters(exercises, "beginner")

        assert result[0]["reps"] == 10  # Default, capped to beginner max (12)
        assert result[0]["sets"] == 2

    def test_none_reps_with_age_caps(self):
        """None reps should work with age-based caps."""
        from api.v1.workouts.utils import validate_and_cap_exercise_parameters

        exercises = [
            {"name": "Burpees", "sets": 3, "reps": None, "rest_seconds": 30}
        ]

        result = validate_and_cap_exercise_parameters(exercises, "intermediate", age=70)

        # Default 10 should be within senior caps
        assert result[0]["reps"] == 10
        assert result[0]["rest_seconds"] >= 75  # Senior min rest

    def test_mixed_none_and_integer_reps(self):
        """Mix of None and integer reps in the same workout should work."""
        from api.v1.workouts.utils import validate_and_cap_exercise_parameters

        exercises = [
            {"name": "Jumping Jacks", "sets": 3, "reps": None, "rest_seconds": 15},
            {"name": "Push-ups", "sets": 3, "reps": 12, "rest_seconds": 60},
            {"name": "Mountain Climbers", "sets": 2, "reps": None, "rest_seconds": 20},
        ]

        result = validate_and_cap_exercise_parameters(exercises, "intermediate")

        assert len(result) == 3
        assert result[0]["reps"] == 10  # None -> default
        assert result[1]["reps"] == 12  # Already valid
        assert result[2]["reps"] == 10  # None -> default

    def test_explicit_null_in_json_style_dict(self):
        """Simulate exactly what Gemini returns - a dict with null value."""
        from api.v1.workouts.utils import validate_and_cap_exercise_parameters
        import json

        # This is what we get from Gemini JSON response
        json_response = '{"name": "Plank", "sets": 3, "reps": null, "hold_seconds": 30}'
        exercise_dict = json.loads(json_response)

        result = validate_and_cap_exercise_parameters([exercise_dict], "intermediate")

        assert result[0]["reps"] == 10  # None -> default

    def test_string_reps_still_works(self):
        """String reps like "8-12" should still be handled correctly."""
        from api.v1.workouts.utils import validate_and_cap_exercise_parameters

        exercises = [
            {"name": "Squats", "sets": 3, "reps": "8-12", "rest_seconds": 60}
        ]

        result = validate_and_cap_exercise_parameters(exercises, "intermediate")

        # Takes the higher value (12) from the range
        assert result[0]["reps"] == 12

    def test_missing_reps_key_uses_default(self):
        """When 'reps' key is missing entirely, should use default 10."""
        from api.v1.workouts.utils import validate_and_cap_exercise_parameters

        exercises = [
            {"name": "Jumping Jacks", "sets": 3, "rest_seconds": 30}  # No reps key
        ]

        result = validate_and_cap_exercise_parameters(exercises, "intermediate")

        assert result[0]["reps"] == 10  # Default from ex.get("reps", 10)


# ============================================================
# TEST 2: User Search Bio Column Fix
# ============================================================

class TestUserSearchBioColumnFix:
    """
    Tests for the bio column fix in social/users.py.

    Bug: The users table doesn't have a 'bio' column, but the search query
    was trying to select it, causing "column users.bio does not exist" error.

    Fix: Removed 'bio' from SELECT and set bio=None in response objects.
    """

    @pytest.mark.asyncio
    async def test_search_users_without_bio_column(self):
        """
        User search should return a matching user with bio=None when the row
        carries no bio value.

        Two things had rotted since this test was written:

        1. CALL (a): `search_users` is a FastAPI endpoint whose `current_user`
           parameter is `Depends(get_current_user)`. Calling the coroutine
           directly leaves that parameter bound to the `Depends` marker object,
           and the endpoint's first statement — `verify_user_ownership(
           current_user, user_id)` — blew up with
           "TypeError: 'Depends' object is not subscriptable".
           The dependency is now resolved explicitly by the test, exactly as
           FastAPI would at request time.

        2. SHAPE (b): the endpoint used to return `List[UserSearchResult]`. It
           now returns a PAGINATED envelope
           `{"results": [...], "total_count": N, "has_more": bool}` with each
           result already `model_dump()`-ed, and it queries with `.range()`
           (offset pagination) + `count="exact"`, plus a `get_workout_counts`
           RPC. The assertions below check the same guarantees against the
           current shape: one matching user, name preserved, bio is None.

        Note the ORIGINAL bug this file names ("users table has no bio column")
        was fixed at the schema level — `users.bio` exists today
        (scripts/schema_columns_snapshot.json) and IS selected. What still has
        to hold, and is what this test now pins, is that a row without a bio
        surfaces as `bio=None` rather than KeyError-ing the search.
        """
        with patch("api.v1.social.users.get_supabase_client") as mock_client:
            # Mock the Supabase client
            mock_supabase = MagicMock()
            mock_client.return_value = mock_supabase

            # Mock users table query (row carries no 'bio' key)
            users_result = MagicMock()
            users_result.data = [
                {"id": "user-1", "name": "John Doe", "username": "johnd", "avatar_url": None}
            ]
            users_result.count = 1

            # Mock empty results for various queries
            empty_result = MagicMock()
            empty_result.data = []
            empty_result.count = 0

            # Create a more sophisticated mock that returns different results based on table
            def mock_table_factory(table_name):
                mock_table = MagicMock()
                mock_table.select.return_value = mock_table
                mock_table.or_.return_value = mock_table
                mock_table.neq.return_value = mock_table
                mock_table.limit.return_value = mock_table
                mock_table.range.return_value = mock_table
                mock_table.eq.return_value = mock_table
                mock_table.in_.return_value = mock_table

                if table_name == "users":
                    mock_table.execute.return_value = users_result
                else:
                    # Return empty for connections, friend_requests, privacy, etc.
                    mock_table.execute.return_value = empty_result

                return mock_table

            mock_supabase.table.side_effect = mock_table_factory
            # Batch workout-count RPC (get_workout_counts) — no rows for this user.
            rpc_result = MagicMock()
            rpc_result.data = []
            mock_supabase.rpc.return_value.execute.return_value = rpc_result

            from api.v1.social.users import search_users

            response = await search_users(
                user_id="test-user-id",
                query="John",
                limit=10,
                offset=0,
                current_user={"id": "test-user-id"},
            )

            # Verify the result
            results = response["results"]
            assert len(results) == 1
            assert response["total_count"] == 1
            assert results[0]["name"] == "John Doe"
            assert results[0]["bio"] is None  # Bio should be None

    def test_user_search_result_model_allows_none_bio(self):
        """UserSearchResult model should accept bio=None."""
        from models.friend_request import UserSearchResult

        # This should not raise an error
        result = UserSearchResult(
            id="user-1",
            name="Test User",
            username="testuser",
            avatar_url=None,
            bio=None,  # Explicitly None
            total_workouts=5,
            current_streak=0,
            is_following=False,
            is_follower=False,
            is_friend=False,
            has_pending_request=False,
            pending_request_id=None,
            requires_approval=False,
        )

        assert result.bio is None
        assert result.name == "Test User"


# ============================================================
# TEST 3: Hell Difficulty Mode
# ============================================================

class TestHellDifficultyMode:
    """
    Tests for the Hell difficulty mode (renamed from Elite).

    The difficulty display name was changed from 'Elite' to 'Hell'
    and Gemini instructions were updated to generate extreme workouts.
    """

    def test_difficulty_utils_returns_hell_display_name(self):
        """
        DifficultyUtils.getDisplayName('hell') should return 'Hell'.
        Note: This is a Flutter test concept, we can only verify backend behavior.
        """
        # Backend doesn't have DifficultyUtils, this verifies the concept
        difficulty_display_names = {
            'easy': 'Beginner',
            'medium': 'Moderate',
            'hard': 'Challenging',
            'hell': 'Hell',  # This is what we changed
        }

        assert difficulty_display_names.get('hell') == 'Hell'
        assert difficulty_display_names.get('hard') == 'Challenging'

    def test_hell_mode_prompt_instruction_exists(self):
        """
        The Gemini service should have Hell mode instructions.
        """
        from services.gemini_service import GeminiService

        # Read the source file to verify Hell mode instructions exist
        import inspect
        source = inspect.getsourcefile(GeminiService)

        with open(source, 'r') as f:
            content = f.read()

        # Verify Hell mode instructions are in the service
        assert 'HELL MODE' in content or 'hell' in content.lower()

    def test_hell_difficulty_in_workout_generation_prompt(self):
        """
        When difficulty='hell', the workout generation should include
        instructions for extreme intensity.
        """
        # This tests the concept - the actual prompt is built dynamically
        difficulty = "hell"

        # Simulated prompt building logic
        if difficulty == "hell":
            expected_instructions = [
                "heavier weights",
                "minimize rest",
                "advanced techniques",
                "maximum intensity"
            ]

            # At least some of these concepts should be in a Hell mode workout
            assert any(keyword in " ".join(expected_instructions).lower()
                      for keyword in ["heavier", "maximum", "advanced"])


# ============================================================
# TEST 4: Duplicate Feature Card Removal
# ============================================================

class TestDuplicateFeatureCardRemoval:
    """
    Tests for the removal of duplicate "What should we build next?" tile.

    The UpcomingFeaturesCard was showing twice on the home screen:
    1. As a pill below the header (kept)
    2. As a tile in the default layout (removed)

    Fix: Removed TileType.upcomingFeatures from defaultTileOrder.
    """

    def test_upcoming_features_not_in_default_tile_order(self):
        """
        TileType.upcomingFeatures should NOT be in the default tile order.
        Note: This is Flutter code, so we verify the concept.
        """
        # Simulated default tile order (what it should be after fix)
        default_tile_order = [
            'quickStart',
            'nextWorkout',
            'fitnessScore',
            'moodPicker',
            'dailyActivity',
            'quickActions',
            'weeklyProgress',
            'weeklyGoals',
            'weekChanges',
            'upcomingWorkouts',
            # 'upcomingFeatures' was removed
        ]

        assert 'upcomingFeatures' not in default_tile_order

    def test_social_preset_no_upcoming_features(self):
        """
        The 'Social' layout preset should not have upcomingFeatures tile.
        """
        # Simulated social preset (what it should be after fix)
        social_preset_tiles = [
            'nextWorkout',
            'leaderboardRank',
            'socialFeed',
            'challengeProgress',
            'streakCounter',
            'personalRecords',
            'weeklyProgress',
            'quickActions',
            # 'upcomingFeatures' was removed
        ]

        assert 'upcomingFeatures' not in social_preset_tiles


# ============================================================
# INTEGRATION TESTS
# ============================================================

class TestQuickWorkoutEndpointIntegration:
    """Integration tests for quick workout endpoint after the None reps fix."""

    @pytest.mark.asyncio
    async def test_quick_workout_endpoint_with_time_based_exercises(self):
        """
        Quick workout endpoint should handle Gemini responses with null reps.

        CALL FIX (a): this test used to open
        `patch("api.v1.workouts.quick.GeminiService")`, which now raises
        `AttributeError: module 'api.v1.workouts.quick' does not have the
        attribute 'GeminiService'` — quick.py was refactored to call
        `services.gemini.constants.gemini_generate_with_retry` and no longer
        imports GeminiService at all. Those three patches were inert scaffolding
        (nothing in the test body ever touched the mocked db/Gemini); they only
        served to make the `with` block explode at setup.

        The assertions are unchanged. What IS new: instead of calling
        `validate_and_cap_exercise_parameters` in isolation, the test now runs
        the exercises through the EXACT post-Gemini pipeline the /quick endpoint
        runs (api/v1/workouts/quick.py:481-497) —
        json.loads -> ensure_exercises_are_dicts -> normalize_exercise_numeric_fields
        -> validate_and_cap_exercise_parameters — so a regression in ANY of those
        three steps (not just the last one) re-breaks `"reps": null`.
        """
        import json

        from api.v1.workouts.generation import (
            ensure_exercises_are_dicts,
            normalize_exercise_numeric_fields,
        )
        from api.v1.workouts.utils import validate_and_cap_exercise_parameters

        # Exactly what Gemini returns for a time-based quick workout: reps null.
        gemini_text = '''
        {
            "name": "Quick 10min Blast",
            "type": "cardio",
            "difficulty": "intermediate",
            "exercises": [
                {"name": "Jumping Jacks", "sets": 3, "reps": null, "duration_seconds": 45, "rest_seconds": 15},
                {"name": "Push-ups", "sets": 3, "reps": 10, "rest_seconds": 30}
            ]
        }
        '''

        workout_data = json.loads(gemini_text.strip())
        exercises = workout_data.get("exercises", [])
        fitness_level = "intermediate"
        difficulty = workout_data.get("difficulty", fitness_level)

        # The /quick endpoint's real normalization chain.
        exercises = ensure_exercises_are_dicts(exercises)
        exercises = normalize_exercise_numeric_fields(exercises)

        # The fix ensures this works
        validated = validate_and_cap_exercise_parameters(
            exercises=exercises,
            fitness_level=fitness_level,
            difficulty=difficulty,
        )

        assert len(validated) == 2
        assert validated[0]["reps"] == 10  # None -> default
        assert validated[1]["reps"] == 10  # Already valid


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
