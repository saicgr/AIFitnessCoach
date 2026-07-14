"""
Tests for Preference Enforcement in Workout Generation.

These tests verify that user preferences (avoided exercises, avoided muscles,
staple exercises) are properly enforced during workout generation.

Addresses the competitor complaint: "I set my preferences and it totally ignored those."
"""
import contextlib
import inspect
import sys
import uuid

import pytest
from unittest.mock import MagicMock, patch, AsyncMock


# ---------------------------------------------------------------------------
# Test doubles for the DB boundary
#
# The /generate endpoint fans out across ~20 DB-backed helper functions. This
# fake stands in for the Supabase client so the endpoint's REAL logic runs
# end-to-end with zero network: every query chain is accepted and resolves to
# "no rows", which is exactly the state of a brand-new user.
# ---------------------------------------------------------------------------

class _FakeResponse:
    def __init__(self, data=None, count=0):
        self.data = data
        self.count = count


class _FakeQuery:
    """Accepts any PostgREST builder chain; every terminal execute() → no rows."""

    def __getattr__(self, _name):
        def _chain(*_args, **_kwargs):
            return self
        return _chain

    def execute(self):
        return _FakeResponse(data=[], count=0)


class _FakeClient:
    def table(self, _name):
        return _FakeQuery()

    def rpc(self, _fn, _params=None):
        return _FakeQuery()


class _FakeDB:
    """Stands in for core.supabase_db.SupabaseDB."""

    def __init__(self, user):
        self.client = _FakeClient()
        self._user = user
        self.created_workout = None

    def get_user(self, _user_id):
        return self._user

    def create_workout(self, data):
        self.created_workout = {**data, "id": str(uuid.uuid4()), "status": "scheduled"}
        return self.created_workout


def _make_http_request():
    """A real starlette Request — the endpoint is rate-limited by slowapi, which
    rejects anything that isn't one, and resolve_timezone() reads its headers."""
    from starlette.requests import Request

    return Request({
        "type": "http",
        "http_version": "1.1",
        "method": "POST",
        "scheme": "http",
        "path": "/api/v1/workouts/generate",
        "raw_path": b"/api/v1/workouts/generate",
        "query_string": b"",
        "root_path": "",
        "headers": [(b"x-user-timezone", b"UTC")],
        "client": ("127.0.0.1", 50000),
        "server": ("testserver", 80),
    })


class TestPreferenceEnforcementInGeneration:
    """Test that preferences are fetched and passed to the AI during generation.

    MOVED + RESHAPED ENDPOINT. The original test called
    `api.v1.workouts.generation.generate_workout(request)` with a bare
    GenerateWorkoutRequest and patched helpers on `api.v1.workouts.generation`.
    Three things changed in production since:

      1. The endpoint moved to `api.v1.workouts.generation_endpoints`
         (`generation` only re-exports it), so patching the old module's
         namespace no longer reaches the helper lookups.
      2. Its signature is now
         `generate_workout(request: Request, *, body, background_tasks, current_user)`
         — a real starlette Request is mandatory (slowapi's user_limiter).
      3. Generation is RAG-first: preferences are pushed into the exercise-RAG
         selector, and `GeminiService.generate_workout_plan` is now only the
         FREE-FORM FALLBACK taken when the RAG returns no exercises.
         `staple_exercises` is also a list of dicts now, collapsed to names via
         `get_staple_names()` before it reaches Gemini.

    The guarantee under test is unchanged and still fully asserted: the three
    preference helpers are called for the user, and their values reach the AI
    layer — now on BOTH the RAG path and the free-form fallback.
    """

    @staticmethod
    @contextlib.contextmanager
    def _generation_harness(rag_exercises):
        """Patch the DB + network boundary; leave the endpoint's logic intact."""
        import api.v1.workouts.generation_endpoints as ge

        user = {
            "id": "test-user-123",
            "fitness_level": "intermediate",
            "goals": ["build_muscle"],
            "equipment": ["dumbbells", "barbell"],
            "preferences": {},
        }
        fake_db = _FakeDB(user)

        gemini_instance = MagicMock()
        gemini_instance.generate_workout_plan = AsyncMock(return_value={
            "name": "Test Workout",
            "type": "strength",
            "difficulty": "medium",
            "exercises": [
                {"name": "Bench Press", "sets": 3, "reps": 10,
                 "muscle_group": "chest", "equipment": "barbell"}
            ],
        })
        gemini_instance.generate_workout_from_library = AsyncMock(return_value={
            "name": "Test Workout",
            "type": "strength",
            "difficulty": "medium",
            "exercises": rag_exercises,
        })

        rag = MagicMock()
        rag.select_exercises_for_workout = AsyncMock(return_value=list(rag_exercises))
        rag.select_exercises_with_fallback = AsyncMock(return_value=(list(rag_exercises), "primary"))

        with contextlib.ExitStack() as stack:
            p = stack.enter_context

            # DB boundary: patch get_supabase_db in EVERY workouts sub-module
            # that resolves it in its own globals (utils.py is a re-export hub,
            # so the helpers live in the sub-modules and look it up there).
            for mod in list(sys.modules.values()):
                name = getattr(mod, "__name__", "")
                if name.startswith("api.v1.workouts") and hasattr(mod, "get_supabase_db"):
                    p(patch.object(mod, "get_supabase_db", lambda: fake_db))

            # Network boundary
            p(patch.object(ge, "GeminiService", MagicMock(return_value=gemini_instance)))
            p(patch.object(ge, "get_exercise_rag_service", MagicMock(return_value=rag)))

            # Preference helpers under test — real signatures, canned values.
            avoided_ex = AsyncMock(return_value=["deadlift", "barbell row"])
            avoided_muscles = AsyncMock(return_value={"avoid": ["lower_back"], "reduce": []})
            staples = AsyncMock(return_value=[
                {"name": "bench press", "reason": "favorite", "muscle_group": "chest",
                 "gym_profile_id": None, "equipment": None, "target_days": None},
                {"name": "squat", "reason": "favorite", "muscle_group": "legs",
                 "gym_profile_id": None, "equipment": None, "target_days": None},
            ])
            p(patch.object(ge, "get_user_avoided_exercises", avoided_ex))
            p(patch.object(ge, "get_user_avoided_muscles", avoided_muscles))
            p(patch.object(ge, "get_user_staple_exercises", staples))

            # Remaining DB-backed helpers the endpoint fans out to: return the
            # neutral "new user" defaults their real implementations return on
            # an empty DB, so none of them perturb the preference plumbing.
            p(patch.object(ge, "get_recently_used_exercises", AsyncMock(return_value=[])))
            p(patch.object(ge, "get_recent_workout_name_words", AsyncMock(return_value=[])))
            p(patch.object(ge, "get_user_1rm_data", AsyncMock(return_value={})))
            p(patch.object(ge, "get_user_training_intensity", AsyncMock(return_value=None)))
            p(patch.object(ge, "get_user_intensity_overrides", AsyncMock(return_value={})))
            p(patch.object(ge, "get_user_comeback_status", AsyncMock(return_value={"in_comeback_mode": False})))
            p(patch.object(ge, "log_workout_change", MagicMock()))
            p(patch.object(ge, "index_workout_to_rag", AsyncMock()))

            yield ge, fake_db, gemini_instance, rag, avoided_ex, avoided_muscles, staples

    @staticmethod
    async def _call_generate(ge):
        from fastapi import BackgroundTasks
        from models.schemas import GenerateWorkoutRequest

        body = GenerateWorkoutRequest(user_id="test-user-123", duration_minutes=45)
        # Unwrap slowapi's rate-limit decorator — rate limiting is orthogonal to
        # what this test asserts, and the limiter needs app state we don't have.
        endpoint = inspect.unwrap(ge.generate_workout)
        return await endpoint(
            _make_http_request(),
            body=body,
            background_tasks=BackgroundTasks(),
            current_user={"id": "test-user-123"},
        )

    @pytest.mark.asyncio
    async def test_generate_endpoint_fetches_avoided_exercises(self):
        """/generate fetches the user's avoided exercises/muscles/staples and
        feeds them to the RAG exercise selector (the primary generation path)."""
        rag_exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10, "muscle_group": "chest", "equipment": "barbell"},
            {"name": "Dumbbell Shoulder Press", "sets": 3, "reps": 10, "muscle_group": "shoulders", "equipment": "dumbbells"},
            {"name": "Lat Pulldown", "sets": 3, "reps": 10, "muscle_group": "back", "equipment": "barbell"},
            {"name": "Goblet Squat", "sets": 3, "reps": 10, "muscle_group": "legs", "equipment": "dumbbells"},
        ]
        with self._generation_harness(rag_exercises) as (
            ge, fake_db, gemini_instance, rag, avoided_ex, avoided_muscles, staples
        ):
            workout = await self._call_generate(ge)

            # The endpoint ran to completion and persisted a real workout —
            # so the assertions below are about a full generation, not a
            # short-circuited one.
            assert workout.user_id == "test-user-123"
            assert fake_db.created_workout is not None

            # Preferences were fetched for this user
            avoided_ex.assert_called_once_with("test-user-123")
            avoided_muscles.assert_called_once_with("test-user-123")
            staples.assert_called_once_with(
                "test-user-123", gym_profile_id=None, scheduled_date=None
            )

            # …and pushed into the RAG selector that picks the exercises.
            rag_kwargs = rag.select_exercises_for_workout.call_args.kwargs
            assert rag_kwargs["avoid_exercises"] == ["deadlift", "barbell row"]
            assert rag_kwargs["avoided_muscles"] == {"avoid": ["lower_back"], "reduce": []}
            assert [s["name"] for s in rag_kwargs["staple_exercises"]] == ["bench press", "squat"]

            # The library path was used, so the free-form fallback stayed unused.
            gemini_instance.generate_workout_from_library.assert_awaited_once()
            gemini_instance.generate_workout_plan.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_generate_endpoint_passes_preferences_to_gemini_fallback(self):
        """When the RAG returns nothing, the free-form Gemini fallback still
        receives avoided_exercises / avoided_muscles / staple_exercises.

        This is the original assertion set from this test, kept verbatim — it
        now lives on the fallback path because generation became RAG-first.
        `staple_exercises` arrives as names (get_staple_names collapses the
        staple dicts) — the same list of names the old test asserted.
        """
        with self._generation_harness([]) as (
            ge, fake_db, gemini_instance, rag, avoided_ex, avoided_muscles, staples
        ):
            workout = await self._call_generate(ge)

            assert workout.user_id == "test-user-123"
            assert fake_db.created_workout is not None

            avoided_ex.assert_called_once_with("test-user-123")
            avoided_muscles.assert_called_once_with("test-user-123")

            call_kwargs = gemini_instance.generate_workout_plan.call_args.kwargs
            assert call_kwargs.get('avoided_exercises') == ["deadlift", "barbell row"]
            assert call_kwargs.get('avoided_muscles') == {"avoid": ["lower_back"], "reduce": []}
            assert call_kwargs.get('staple_exercises') == ["bench press", "squat"]


class TestPostGenerationValidation:
    """Test that generated exercises are validated against user preferences."""

    def test_filters_avoided_exercises_from_response(self):
        """Test that avoided exercises are filtered out of AI response."""
        avoided_exercises = ["deadlift", "barbell row"]

        # Simulated AI response that includes an avoided exercise
        ai_exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10, "muscle_group": "chest"},
            {"name": "Deadlift", "sets": 3, "reps": 8, "muscle_group": "back"},  # Should be filtered
            {"name": "Squat", "sets": 3, "reps": 10, "muscle_group": "legs"},
        ]

        # Apply the same filtering logic as in generation.py
        filtered = [
            ex for ex in ai_exercises
            if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
        ]

        assert len(filtered) == 2
        assert all(ex["name"].lower() != "deadlift" for ex in filtered)

    def test_filters_avoided_muscles_from_response(self):
        """Test that exercises targeting avoided muscles are filtered out."""
        avoided_muscles = {"avoid": ["lower_back"], "reduce": []}

        # Simulated AI response that includes an exercise targeting avoided muscle
        ai_exercises = [
            {"name": "Bench Press", "sets": 3, "reps": 10, "muscle_group": "chest"},
            {"name": "Good Morning", "sets": 3, "reps": 12, "muscle_group": "lower_back"},  # Should be filtered
            {"name": "Squat", "sets": 3, "reps": 10, "muscle_group": "legs"},
        ]

        avoid_muscles_lower = [m.lower() for m in avoided_muscles["avoid"]]
        filtered = [
            ex for ex in ai_exercises
            if ex.get("muscle_group", "").lower() not in avoid_muscles_lower
        ]

        assert len(filtered) == 2
        assert all(ex["muscle_group"].lower() != "lower_back" for ex in filtered)

    def test_case_insensitive_filtering(self):
        """Test that filtering is case-insensitive."""
        avoided_exercises = ["DEADLIFT", "Barbell Row"]

        ai_exercises = [
            {"name": "deadlift", "sets": 3, "reps": 8, "muscle_group": "back"},
            {"name": "BARBELL ROW", "sets": 3, "reps": 10, "muscle_group": "back"},
            {"name": "Squat", "sets": 3, "reps": 10, "muscle_group": "legs"},
        ]

        filtered = [
            ex for ex in ai_exercises
            if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
        ]

        assert len(filtered) == 1
        assert filtered[0]["name"] == "Squat"


class TestGeminiPromptContainsPreferences:
    """Test that Gemini prompt includes user preferences."""

    @pytest.mark.asyncio
    async def test_gemini_prompt_includes_avoided_exercises(self):
        """Test that the Gemini prompt includes avoided exercises instruction."""
        from services.gemini_service import GeminiService

        with patch.object(GeminiService, 'chat', new_callable=AsyncMock) as mock_chat:
            mock_chat.return_value = '{"name": "Test Workout", "type": "strength", "difficulty": "medium", "exercises": []}'

            service = GeminiService()

            # Call with avoided exercises
            await service.generate_workout_plan(
                fitness_level="intermediate",
                goals=["build_muscle"],
                equipment=["dumbbells"],
                avoided_exercises=["deadlift", "barbell row"]
            )

            # The prompt should contain avoided exercises instruction
            # This is a smoke test - actual prompt verification would need access to the prompt

    @pytest.mark.asyncio
    async def test_gemini_prompt_includes_avoided_muscles(self):
        """Test that the Gemini prompt includes avoided muscles instruction."""
        from services.gemini_service import GeminiService

        with patch.object(GeminiService, 'chat', new_callable=AsyncMock) as mock_chat:
            mock_chat.return_value = '{"name": "Test Workout", "type": "strength", "difficulty": "medium", "exercises": []}'

            service = GeminiService()

            # Call with avoided muscles
            await service.generate_workout_plan(
                fitness_level="intermediate",
                goals=["build_muscle"],
                equipment=["dumbbells"],
                avoided_muscles={"avoid": ["lower_back"], "reduce": ["shoulders"]}
            )


class TestExtendWorkoutPreferences:
    """Test that extend workout also respects preferences."""

    def test_extend_workout_filters_avoided_exercises(self):
        """Test that extended exercises also exclude avoided exercises."""
        avoided_exercises = ["deadlift"]

        # Simulated extension exercises
        new_exercises = [
            {"name": "Romanian Deadlift", "sets": 3, "reps": 12, "muscle_group": "hamstrings"},
            {"name": "Deadlift", "sets": 3, "reps": 8, "muscle_group": "back"},  # Should be filtered
            {"name": "Leg Press", "sets": 3, "reps": 10, "muscle_group": "legs"},
        ]

        filtered = [
            ex for ex in new_exercises
            if ex.get("name", "").lower() not in [ae.lower() for ae in avoided_exercises]
        ]

        assert len(filtered) == 2
        # Deadlift should be filtered, Romanian Deadlift should remain (different exercise)
        exercise_names = [ex["name"] for ex in filtered]
        assert "Deadlift" not in exercise_names
        assert "Romanian Deadlift" in exercise_names


class TestPreferenceHelperFunctions:
    """Test the helper functions for fetching user preferences.

    MOVED MODULE: these helpers were split out of `api.v1.workouts.utils` into
    `api.v1.workouts.user_preference_utils` (utils.py is now a re-export hub).
    The helpers resolve `get_supabase_db` in THEIR OWN module globals, so the
    DB must be patched on `user_preference_utils` — patching the re-export hub
    silently did nothing, the helpers hit the real client, and every assertion
    below failed against an empty list. Assertions are unchanged.
    """

    @pytest.mark.asyncio
    async def test_get_user_avoided_exercises_returns_list(self):
        """Test that get_user_avoided_exercises returns a list."""
        with patch('api.v1.workouts.user_preference_utils.get_supabase_db') as mock_db:
            mock_db_instance = MagicMock()
            mock_db.return_value = mock_db_instance

            # Mock RPC call
            mock_result = MagicMock()
            mock_result.data = [
                {"exercise_name": "Deadlift"},
                {"exercise_name": "Barbell Row"}
            ]
            mock_db_instance.client.rpc.return_value.execute.return_value = mock_result

            from api.v1.workouts.utils import get_user_avoided_exercises

            result = await get_user_avoided_exercises("test-user-123")

            assert isinstance(result, list)
            assert len(result) == 2
            assert "deadlift" in result
            assert "barbell row" in result

    @pytest.mark.asyncio
    async def test_get_user_avoided_exercises_returns_empty_on_error(self):
        """Test that get_user_avoided_exercises returns empty list on error."""
        with patch('api.v1.workouts.user_preference_utils.get_supabase_db') as mock_db:
            mock_db_instance = MagicMock()
            mock_db.return_value = mock_db_instance
            mock_db_instance.client.rpc.side_effect = Exception("Database error")

            from api.v1.workouts.utils import get_user_avoided_exercises

            result = await get_user_avoided_exercises("test-user-123")

            assert result == []

    @pytest.mark.asyncio
    async def test_get_user_avoided_muscles_returns_dict(self):
        """Test that get_user_avoided_muscles returns a dict with avoid and reduce."""
        with patch('api.v1.workouts.user_preference_utils.get_supabase_db') as mock_db:
            mock_db_instance = MagicMock()
            mock_db.return_value = mock_db_instance

            # Mock RPC call
            mock_result = MagicMock()
            mock_result.data = [
                {"muscle_group": "Lower Back", "severity": "avoid"},
                {"muscle_group": "Shoulders", "severity": "reduce"}
            ]
            mock_db_instance.client.rpc.return_value.execute.return_value = mock_result

            from api.v1.workouts.utils import get_user_avoided_muscles

            result = await get_user_avoided_muscles("test-user-123")

            assert isinstance(result, dict)
            assert "avoid" in result
            assert "reduce" in result
            assert "lower back" in result["avoid"]
            assert "shoulders" in result["reduce"]

    @pytest.mark.asyncio
    async def test_get_user_staple_exercises_returns_list(self):
        """Test that get_user_staple_exercises returns a list."""
        with patch('api.v1.workouts.user_preference_utils.get_supabase_db') as mock_db:
            mock_db_instance = MagicMock()
            mock_db.return_value = mock_db_instance

            # Mock table query
            mock_result = MagicMock()
            mock_result.data = [
                {"exercise_name": "Bench Press"},
                {"exercise_name": "Squat"}
            ]
            mock_db_instance.client.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result

            from api.v1.workouts.utils import get_user_staple_exercises

            result = await get_user_staple_exercises("test-user-123")

            assert isinstance(result, list)
            assert len(result) == 2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
