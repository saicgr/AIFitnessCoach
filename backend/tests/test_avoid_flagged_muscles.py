"""
Unit tests for avoiding exercises that target muscle groups the user flagged on
the onboarding injury body map.

The body-map muscle names flow through the existing `limitations`/`injuries`
list and are converted to avoid-muscles by
`get_muscles_to_avoid_from_injuries` (readiness_utils), which feeds the existing
`avoided_muscles["avoid"]` system consumed by `filter_by_avoided_muscles`
(filters). These tests cover:
- raw body-map muscle names -> avoid tokens that actually match the library's
  free-text target_muscle strings (naming reconciliation: abs->abdominals/core,
  lats->latissimus dorsi, traps->trapezius, underscore->space);
- injury chip ids still avoid their implicated muscles (no regression);
- the workout still fills (fail-soft: avoid removes the targeted exercises but
  the candidate pool keeps everything else);
- empty / sentinel / free-text entries => identical to today (fail-open).

Run:
    cd backend && .venv312/bin/python -m pytest tests/test_avoid_flagged_muscles.py -q
"""
from __future__ import annotations

import pytest

from api.v1.workouts.readiness_utils import (
    get_muscles_to_avoid_from_injuries,
    INJURY_TO_AVOIDED_MUSCLES,
    BODY_MAP_MUSCLE_NORMALIZATION,
)
from services.exercise_rag.filters import filter_by_avoided_muscles


# Library-shaped candidates — target_muscle strings copied from the real
# exercise_library_cleaned (free-text with parenthetical detail).
def _library_candidates():
    return [
        {"name": "Crunch", "target_muscle": "abdominals (rectus abdominis)", "body_part": "waist", "secondary_muscles": []},
        {"name": "Plank", "target_muscle": "core (rectus abdominis, obliques)", "body_part": "waist", "secondary_muscles": []},
        {"name": "Lat Pulldown", "target_muscle": "middle back (latissimus dorsi, teres major)", "body_part": "back", "secondary_muscles": []},
        {"name": "Straight-arm Pulldown", "target_muscle": "lats", "body_part": "back", "secondary_muscles": []},
        {"name": "Barbell Shrug", "target_muscle": "upper back (trapezius)", "body_part": "traps", "secondary_muscles": []},
        {"name": "Bench Press", "target_muscle": "chest (pectoralis major)", "body_part": "chest", "secondary_muscles": []},
        {"name": "Back Squat", "target_muscle": "quadriceps (quadriceps femoris), glutes (gluteus maximus)", "body_part": "thighs", "secondary_muscles": []},
        {"name": "Bicep Curl", "target_muscle": "biceps (biceps brachii)", "body_part": "arms", "secondary_muscles": []},
    ]


def _avoid(limitations):
    """Mirror the generation call site: derive avoid muscles, run the filter."""
    avoided = {"avoid": get_muscles_to_avoid_from_injuries(limitations), "reduce": []}
    # Default floor=0 ⇒ legacy hard-exclude (4th tuple element = pool_collapsed).
    kept, primary, secondary, _collapsed = filter_by_avoided_muscles(_library_candidates(), avoided)
    return {c["name"] for c in kept}, primary, secondary


# --- body-map muscle names exclude the targeted exercises ------------------

def test_abs_excludes_abdominal_and_core_exercises():
    kept, primary, _ = _avoid(["abs"])
    # abs -> abdominals/abs/core: Crunch (abdominals) + Plank (core) removed.
    assert "Crunch" not in kept
    assert "Plank" not in kept
    assert primary == 2
    # Workout still fills with everything else.
    assert {"Lat Pulldown", "Bench Press", "Back Squat", "Bicep Curl"} <= kept


def test_lats_reconciles_to_latissimus_dorsi():
    kept, _, _ = _avoid(["lats"])
    # The naming win: raw "lats" alone misses "middle back (latissimus dorsi)".
    assert "Lat Pulldown" not in kept
    assert "Straight-arm Pulldown" not in kept
    assert "Bench Press" in kept


def test_traps_reconciles_to_trapezius():
    kept, _, _ = _avoid(["traps"])
    assert "Barbell Shrug" not in kept  # "upper back (trapezius)"
    assert "Bench Press" in kept


def test_chest_and_quadriceps_substring_match():
    assert "Bench Press" not in _avoid(["chest"])[0]
    assert "Back Squat" not in _avoid(["quadriceps"])[0]


def test_upper_back_underscore_reconciles_to_space():
    # The body map sends "upper_back"; the library stores "upper back".
    tokens = BODY_MAP_MUSCLE_NORMALIZATION["upper_back"]
    assert "upper back" in tokens
    assert "Barbell Shrug" not in _avoid(["upper_back"])[0]


# --- injury chip ids still avoid their muscles (no regression) -------------

def test_injury_id_knee_still_avoids_quads_and_calves():
    muscles = get_muscles_to_avoid_from_injuries(["knee"])
    # Existing injury map for "knee" includes quads/quadriceps + calves.
    assert "quadriceps" in muscles
    assert "calves" in muscles
    # And it still filters quad-targeting exercises out.
    assert "Back Squat" not in _avoid(["knee"])[0]


def test_injury_id_lower_back_right_sized():
    # lower_back avoidance is now the lumbar region ONLY (the vetted
    # `lower_back_safe` index tag gates the rest). The old broad posterior-chain
    # set (back/glutes/hamstrings) discarded every vetted-safe loaded exercise.
    muscles = set(get_muscles_to_avoid_from_injuries(["lower_back"]))
    assert muscles == set(INJURY_TO_AVOIDED_MUSCLES["lower_back"])
    assert muscles == {"lower_back", "erector_spinae"}
    assert not muscles & {"glutes", "hamstrings", "back", "lats"}


# --- fail-open / fail-soft -------------------------------------------------

def test_empty_and_sentinel_are_noops():
    assert get_muscles_to_avoid_from_injuries([]) == []
    assert get_muscles_to_avoid_from_injuries(["none"]) == []
    assert get_muscles_to_avoid_from_injuries(["other"]) == []
    assert get_muscles_to_avoid_from_injuries([""]) == []
    # Filter with no avoid muscles keeps every candidate.
    kept, primary, secondary = _avoid(["none"])
    assert len(kept) == len(_library_candidates())
    assert primary == 0 and secondary == 0


def test_unknown_free_text_is_ignored_not_raised():
    # Free text that maps to nothing must not raise and must not avoid anything.
    muscles = get_muscles_to_avoid_from_injuries(["my left pinky toe"])
    assert muscles == []


def test_mixed_list_combines_injury_and_muscle_entries():
    muscles = set(get_muscles_to_avoid_from_injuries(["abs", "knee", "none", "zzz"]))
    # abs contributes abdominals/core; knee contributes quads/calves; none/zzz ignored.
    assert {"abdominals", "core"} <= muscles
    assert {"quadriceps", "calves"} <= muscles


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
