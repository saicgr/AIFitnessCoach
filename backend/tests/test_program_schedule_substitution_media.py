"""
Regression test for docs/qa/UI_E2E_2026-08-05.md row 5.

GET /program-templates/library/{program_id}/schedule runs the in-memory
injury-safety preview (`_customize_preview_weeks`) BEFORE building the
exercise-media map. When that preview substitutes a different exercise into
a session slot, the OLD positional media map (`program_exercises_with_media`,
which only ever describes the AUTHORED content) must not be paired with the
NEW exercise's name — that produced a name/media/id mismatch where the
substitute's name rendered next to the previous occupant's photo and
exercise_id (e.g. "180 Jump Turns" shown with Cable Goblet Squat's thumbnail).

This test drives `library_program_schedule` directly (bypassing HTTP) with a
fully-mocked DB and a mocked `_customize_preview_weeks` that performs a
deterministic substitution identical in shape to the real
`enforce_injury_safety` → `_build_replacement` pipeline (new name +
new exercise_id written into the same session-exercise dict).
"""
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


PROGRAM_ID = "prog-1"
VARIANT_ID = "variant-1"
WEEK = 1

AUTHORED_EXERCISE_ID = "authored-ex-id"
SUBSTITUTE_EXERCISE_ID = "substitute-ex-id"


def _workouts_blob():
    """One week, one workout, one exercise slot — authored as 'Cable Goblet
    Squat'. `exercise_id` is intentionally absent on the authored row (this
    mirrors production: most authored rows carry no exercise_id at all)."""
    return [
        {
            "exercises": [
                {"exercise_name": "Cable Goblet Squat", "sets": "3", "reps": "10"},
            ]
        }
    ]


class _FakeTable:
    """Minimal chainable stand-in keyed on (table_name, select_columns)."""

    def __init__(self, responses):
        self._responses = responses  # {(table, select_cols_signature): rows}
        self._table = None
        self._select_cols = None

    def table(self, name):
        self._table = name
        return self

    def select(self, cols):
        self._select_cols = cols
        return self

    def eq(self, *args, **kwargs):
        return self

    def in_(self, *args, **kwargs):
        return self

    def order(self, *args, **kwargs):
        return self

    def limit(self, *args, **kwargs):
        return self

    def execute(self):
        for (table, needle), rows in self._responses.items():
            if table == self._table and needle in (self._select_cols or ""):
                return MagicMock(data=rows)
        return MagicMock(data=[])


def _run_schedule(responses, customize_side_effect):
    from api.v1.program_templates import library_program_schedule

    fake_db = MagicMock()
    fake_db.client = _FakeTable(responses)

    with patch("api.v1.program_templates.get_supabase", return_value=fake_db), \
         patch(
             "api.v1.program_templates._customize_preview_weeks",
             new=AsyncMock(side_effect=customize_side_effect),
         ):
        return asyncio.get_event_loop().run_until_complete(
            library_program_schedule(
                PROGRAM_ID,
                variant_id=VARIANT_ID,
                current_user={"id": "user-1"},
            )
        )


def _substitute_customize(weeks_rows, *, user_id):
    """Stand-in for the real customize pipeline: mutate the ONE exercise dict
    in place, exactly as `_build_replacement` does — new name, new
    exercise_id, same dict object/position."""
    ex = weeks_rows[0]["workouts"][0]["exercises"][0]
    ex["exercise_name"] = "180 Jump Turns"
    ex["name"] = "180 Jump Turns"
    ex["exercise_id"] = SUBSTITUTE_EXERCISE_ID
    return {"status": "customized"}


def _no_op_customize(weeks_rows, *, user_id):
    return {"status": "unchanged"}


def _base_responses():
    return {
        ("program_variant_weeks", "week_number"): [
            {
                "week_number": WEEK,
                "phase": "Peak",
                "focus": "Legs",
                "workouts": _workouts_blob(),
            }
        ],
        # Positional media row still describes the AUTHORED exercise —
        # exactly what program_exercises_with_media contains regardless of
        # any runtime substitution.
        ("program_exercises_with_media", "week_number"): [
            {
                "week_number": WEEK,
                "workout_idx": 1,
                "exercise_idx": 1,
                "exercise_name_normalized": "cable goblet squat",
                "canonical_name": "Cable Goblet Squat",
                "image_s3_path": "s3://bucket/ILLUSTRATIONS ALL/Legs/Cable Goblet Squat.jpg",
                "video_s3_path": "s3://bucket/VERTICAL VIDEOS ALL/Legs/Cable Goblet Squat.mp4",
                "gif_url": None,
            }
        ],
        # canonical_name -> id resolution (only reached for a resolved
        # canon_name; with the fix, a substituted slot never reaches this
        # for its own row, but "Cable Goblet Squat" must still resolve for
        # OTHER unsubstituted callers of this same mock table).
        ("exercise_library_cleaned", "id, name"): [
            {"id": AUTHORED_EXERCISE_ID, "name": "Cable Goblet Squat"},
        ],
        # By-id fallback (image/video/gif) for the SUBSTITUTE's own id.
        ("exercise_library", "image_s3_path"): [
            {
                "id": SUBSTITUTE_EXERCISE_ID,
                "image_s3_path": "s3://bucket/ILLUSTRATIONS ALL/Calisthenics/180 Jump Turns.jpg",
                "video_s3_path": "s3://bucket/VERTICAL VIDEOS ALL/Calisthenics/180 Jump Turns.mp4",
                "gif_url": None,
            }
        ],
        ("exercise_library_cleaned", "image_url"): [],
    }


class TestScheduleSubstitutionMedia:
    def test_substituted_slot_gets_its_own_media_and_id(self):
        """The defect: name says '180 Jump Turns' but id/image stayed on
        Cable Goblet Squat. After the fix, both must belong to the
        substitute."""
        result = _run_schedule(_base_responses(), _substitute_customize)

        ex = result["weeks"][0]["days"][0]["exercises"][0]
        assert ex["name"] == "180 Jump Turns"
        assert ex["exercise_id"] == SUBSTITUTE_EXERCISE_ID, (
            f"exercise_id still points at the authored exercise: {ex['exercise_id']!r} "
            f"(expected the substitute's own id {SUBSTITUTE_EXERCISE_ID!r})"
        )
        assert "Calisthenics" in (ex["image_url"] or "") and "Jump" in (ex["image_url"] or ""), (
            f"image_url still serves the authored exercise's photo: {ex['image_url']!r}"
        )
        assert "Cable" not in (ex["image_url"] or "") and "Goblet" not in (ex["image_url"] or "")
        assert "Jump" in (ex["video_url"] or "")

    def test_unsubstituted_slot_still_uses_positional_media(self):
        """Control case: when nothing was substituted, the positional media
        map must still be used (this guard must not regress the common
        path)."""
        result = _run_schedule(_base_responses(), _no_op_customize)

        ex = result["weeks"][0]["days"][0]["exercises"][0]
        assert ex["name"] == "Cable Goblet Squat"
        assert ex["exercise_id"] == AUTHORED_EXERCISE_ID
        assert "Cable" in (ex["image_url"] or "") and "Goblet" in (ex["image_url"] or "")
