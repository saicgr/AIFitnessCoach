"""
Regression tests for E2E register #110: regenerate silently drops the
requested body focus.

Root cause (api/v1/workouts/versioning.py):
  1. `/regenerate` and `/regenerate-stream` never ran the focus-scoped
     candidate pool + deterministic post-filter that `/generate`
     (generation_endpoints.py:1568) runs — their terminal completeness
     stage (A4 / `ensure_complete_workout`) is a pure COUNT floor, so a
     mismatched result (e.g. an all-stretch "legs" session) just got topped
     up with MORE of the wrong exercises.
  2. The fallback that derives `focus_areas` from the existing workout when
     the request omits them read `ex.get("target_muscles")`, a field
     library-sourced exercises never carry (they carry `muscle_group`) — so
     the fallback silently found nothing for the overwhelming majority of
     real workouts.

These tests drive the real (unmocked) `validate_and_filter_focus_mismatches`
so the backfill logic itself is exercised, and only stub out the DB-backed
`build_library_pool` step.
"""
from unittest.mock import patch

from api.v1.workouts.versioning import (
    _apply_regen_focus_validation,
    _derive_focus_areas_from_exercises,
)


# ---------------------------------------------------------------------------
# _derive_focus_areas_from_exercises
# ---------------------------------------------------------------------------
class TestDeriveFocusAreasFromExercises:
    def test_reads_muscle_group_field(self):
        """The bug: library-sourced exercises carry `muscle_group`, not
        `target_muscles` — the old code only checked the latter and always
        came back empty for a real regenerated workout."""
        exercises = [
            {"name": "Back Squat", "muscle_group": "quads"},
            {"name": "Walking Lunge", "muscle_group": "glutes"},
        ]
        result = _derive_focus_areas_from_exercises(exercises)
        assert result  # must NOT be empty — this is the bug being fixed
        assert set(result) <= {"quads", "glutes"}
        assert len(result) <= 2

    def test_prefers_target_muscles_when_present(self):
        exercises = [{"name": "Back Squat", "target_muscles": ["quads", "glutes"]}]
        result = _derive_focus_areas_from_exercises(exercises)
        assert set(result) == {"quads", "glutes"}

    def test_no_muscle_data_yields_empty(self):
        assert _derive_focus_areas_from_exercises([{"name": "Mystery Move"}]) == []
        assert _derive_focus_areas_from_exercises([]) == []
        assert _derive_focus_areas_from_exercises(None) == []

    def test_ignores_non_dict_entries(self):
        exercises = [{"name": "Squat", "muscle_group": "quads"}, "not-a-dict", None]
        result = _derive_focus_areas_from_exercises(exercises)
        assert result == ["quads"]


# ---------------------------------------------------------------------------
# _apply_regen_focus_validation — the actual gate for E2E #110
# ---------------------------------------------------------------------------
ALL_MISMATCHED_STRETCHES = [
    {"name": "Shoulder Stretch", "muscle_group": "shoulders", "reps": "30s"},
    {"name": "Chest Opener Stretch", "muscle_group": "chest", "reps": "30s"},
    {"name": "Upper Back Stretch", "muscle_group": "back", "reps": "30s"},
    {"name": "Triceps Stretch", "muscle_group": "triceps", "reps": "30s"},
    {"name": "Neck Rolls", "muscle_group": "neck", "reps": "10"},
]

LEG_CANDIDATE_POOL = [
    {"name": "Barbell Back Squat", "muscle_group": "quads", "exercise_id": "1"},
    {"name": "Romanian Deadlift", "muscle_group": "hamstrings", "exercise_id": "2"},
    {"name": "Walking Lunge", "muscle_group": "glutes", "exercise_id": "3"},
    {"name": "Leg Press", "muscle_group": "quads", "exercise_id": "4"},
    {"name": "Calf Raise", "muscle_group": "calves", "exercise_id": "5"},
]

_LEG_MUSCLES = {"quads", "hamstrings", "glutes", "calves"}


class TestApplyRegenFocusValidation:
    async def test_legs_regenerate_cannot_return_an_all_stretch_session(self):
        """The reported bug, reproduced directly: a legs regenerate whose
        Gemini output was 5 stretches (none targeting a leg muscle) must not
        ship those stretches — they must be swapped for real leg-focused
        candidates from the pool."""
        with patch(
            "api.v1.workouts.focus_validation_utils.build_library_pool",
            return_value=LEG_CANDIDATE_POOL,
        ):
            result = await _apply_regen_focus_validation(
                exercises=[dict(e) for e in ALL_MISMATCHED_STRETCHES],
                focus_area="legs",
                workout_name="Sleepy Wander Range Session",
                equipment=["bodyweight"],
                fitness_level="intermediate",
                fallback_pool=LEG_CANDIDATE_POOL,
            )

        result_names = {ex["name"] for ex in result}
        stretch_names = {e["name"] for e in ALL_MISMATCHED_STRETCHES}
        assert not (result_names & stretch_names), (
            f"stretch exercises survived the focus filter: {result_names & stretch_names}"
        )
        assert result, "focus validation must not empty out the workout"
        for ex in result:
            assert ex["muscle_group"] in _LEG_MUSCLES, (
                f"'{ex['name']}' ({ex['muscle_group']}) does not target a leg muscle"
            )

    async def test_matching_exercises_pass_through_unchanged(self):
        """A workout that already matches its focus is untouched (no
        spurious replacement when there's nothing to fix)."""
        leg_exercises = [dict(e) for e in LEG_CANDIDATE_POOL[:3]]
        with patch(
            "api.v1.workouts.focus_validation_utils.build_library_pool",
            return_value=LEG_CANDIDATE_POOL,
        ):
            result = await _apply_regen_focus_validation(
                exercises=leg_exercises,
                focus_area="legs",
                workout_name="Leg Day",
                equipment=["barbell"],
                fitness_level="intermediate",
                fallback_pool=LEG_CANDIDATE_POOL,
            )
        assert {ex["name"] for ex in result} == {ex["name"] for ex in leg_exercises}

    async def test_empty_exercises_returns_empty(self):
        result = await _apply_regen_focus_validation(
            exercises=[],
            focus_area="legs",
            workout_name="Empty",
            equipment=[],
            fitness_level="intermediate",
            fallback_pool=[],
        )
        assert result == []

    async def test_no_focus_area_is_a_noop(self):
        exercises = [dict(e) for e in ALL_MISMATCHED_STRETCHES]
        result = await _apply_regen_focus_validation(
            exercises=exercises,
            focus_area="",
            workout_name="No Focus",
            equipment=[],
            fitness_level="intermediate",
            fallback_pool=[],
        )
        assert result == exercises

    async def test_pool_fetch_failure_fails_open(self):
        """If the library pool fetch blows up, fall back to the RAG pool
        already on hand rather than blocking the regenerate."""
        with patch(
            "api.v1.workouts.focus_validation_utils.build_library_pool",
            side_effect=RuntimeError("db down"),
        ):
            result = await _apply_regen_focus_validation(
                exercises=[dict(e) for e in ALL_MISMATCHED_STRETCHES],
                focus_area="legs",
                workout_name="Sleepy Wander Range Session",
                equipment=["bodyweight"],
                fitness_level="intermediate",
                fallback_pool=LEG_CANDIDATE_POOL,
            )
        # Falls back to fallback_pool (RAG candidates) for the backfill —
        # still must not ship the mismatched stretches.
        result_names = {ex["name"] for ex in result}
        stretch_names = {e["name"] for e in ALL_MISMATCHED_STRETCHES}
        assert not (result_names & stretch_names)

    async def test_stage_exception_fails_open_and_keeps_pre_stage_list(self):
        with patch(
            "api.v1.workouts.focus_validation_utils.validate_and_filter_focus_mismatches",
            side_effect=RuntimeError("boom"),
        ):
            exercises = [dict(e) for e in ALL_MISMATCHED_STRETCHES]
            result = await _apply_regen_focus_validation(
                exercises=exercises,
                focus_area="legs",
                workout_name="Sleepy Wander Range Session",
                equipment=["bodyweight"],
                fitness_level="intermediate",
                fallback_pool=LEG_CANDIDATE_POOL,
            )
        assert result == exercises
