"""Unit tests for the post-Gemini filter helpers introduced 2026-05-09 in
response to render_generate_stream_full_20260509_095849:

- post_filter_excluded_exercises  → catches "Burpee" leak when exclude=['burpee']
- post_filter_equipment_violations → drops kettlebell exercises for empty/no-kb
- coerce_workout_type_from_focus  → focus=cardio/endurance/hiit/mobility → type
- cap_exercise_count_by_density   → 15-min sessions cap at 3 (or 4 for circuit)
"""
from api.v1.workouts.generation_helpers import (
    post_filter_excluded_exercises,
    post_filter_equipment_violations,
    coerce_workout_type_from_focus,
)
from api.v1.workouts.validation_utils import cap_exercise_count_by_density


# --- post_filter_excluded_exercises -----------------------------------------

def test_excludes_canonical_match_drops_capitalized_burpee():
    exes = [{"name": "Burpee"}, {"name": "Push-Up"}]
    out = post_filter_excluded_exercises(exes, ["burpee"], None)
    assert [e["name"] for e in out] == ["Push-Up"]


def test_excludes_substring_alias_collapse():
    exes = [{"name": "Jump Squat (Plyometric)"}]
    out = post_filter_excluded_exercises(exes, ["jump squat"], None)
    assert out == []


def test_excludes_skips_when_list_empty():
    exes = [{"name": "Burpee"}]
    out = post_filter_excluded_exercises(exes, [], None)
    assert out == exes
    out2 = post_filter_excluded_exercises(exes, None, None)
    assert out2 == exes


def test_adjacent_day_list_also_drops():
    exes = [{"name": "Bench Press"}, {"name": "Cable Row"}]
    out = post_filter_excluded_exercises(exes, [], ["bench press"])
    assert [e["name"] for e in out] == ["Cable Row"]


# --- post_filter_equipment_violations ---------------------------------------

def test_equipment_drops_kettlebell_when_user_has_none():
    exes = [
        {"name": "Kettlebell Snatch", "equipment": "kettlebell"},
        {"name": "Push-Up", "equipment": "bodyweight"},
    ]
    out = post_filter_equipment_violations(exes, user_equipment=[], goals=None)
    assert [e["name"] for e in out] == ["Push-Up"]


def test_equipment_infers_from_name_when_field_missing():
    exes = [{"name": "Kettlebell Sumo Deadlift", "equipment": ""}]
    out = post_filter_equipment_violations(
        exes, user_equipment=["dumbbells", "bench"], goals=None,
    )
    assert out == []


def test_equipment_passthrough_when_no_user_equipment_set():
    """user_equipment=None means caller didn't pass it — don't filter."""
    exes = [{"name": "Kettlebell Swing", "equipment": "kettlebell"}]
    out = post_filter_equipment_violations(exes, user_equipment=None, goals=None)
    assert out == exes


def test_equipment_keeps_dumbbell_when_user_has_dumbbells():
    exes = [
        {"name": "Dumbbell Press", "equipment": "dumbbells"},
        {"name": "Kettlebell Snatch", "equipment": "kettlebell"},
    ]
    out = post_filter_equipment_violations(
        exes, user_equipment=["dumbbells", "bench"], goals=None,
    )
    assert [e["name"] for e in out] == ["Dumbbell Press"]


# --- coerce_workout_type_from_focus -----------------------------------------

def test_coerce_cardio_focus_overrides_strength_type():
    assert coerce_workout_type_from_focus("strength", ["cardio"]) == "cardio"


def test_coerce_endurance_focus_maps_to_cardio_type():
    assert coerce_workout_type_from_focus("strength", ["endurance"]) == "cardio"


def test_coerce_hiit_focus_maps_to_cardio_type():
    assert coerce_workout_type_from_focus("hypertrophy", ["hiit"]) == "cardio"


def test_coerce_mobility_focus_overrides_strength_type():
    assert coerce_workout_type_from_focus("strength", ["mobility"]) == "mobility"


def test_coerce_passes_through_when_focus_unknown():
    assert coerce_workout_type_from_focus("strength", ["push"]) == "strength"


def test_coerce_passes_through_when_no_focus():
    assert coerce_workout_type_from_focus("strength", None) == "strength"
    assert coerce_workout_type_from_focus("strength", []) == "strength"


def test_coerce_does_not_downgrade_hybrid_or_circuit():
    """Only strength/hypertrophy/power get coerced — hybrid/circuit are
    legitimate cardio-adjacent labels."""
    assert coerce_workout_type_from_focus("hybrid", ["cardio"]) == "hybrid"
    assert coerce_workout_type_from_focus("circuit", ["cardio"]) == "circuit"


# --- cap_exercise_count_by_density (short-session brackets) -----------------

def _mk_exes(n):
    return [{"name": f"Exercise {i}", "sets": 3, "reps": 10, "rest_seconds": 60}
            for i in range(n)]


def test_density_caps_15min_strength_to_3():
    out = cap_exercise_count_by_density(_mk_exes(6), 15, "strength")
    assert len(out) == 3


def test_density_caps_15min_circuit_to_4():
    out = cap_exercise_count_by_density(_mk_exes(6), 15, "hiit")
    assert len(out) == 4


def test_density_caps_5min_to_2():
    out = cap_exercise_count_by_density(_mk_exes(5), 5, "strength")
    assert len(out) == 2


def test_density_caps_10min_to_3():
    out = cap_exercise_count_by_density(_mk_exes(5), 10, "strength")
    assert len(out) == 3


def test_density_caps_20min_strength_to_4():
    out = cap_exercise_count_by_density(_mk_exes(7), 20, "strength")
    assert len(out) == 4


def test_density_caps_30min_strength_to_5():
    out = cap_exercise_count_by_density(_mk_exes(8), 30, "strength")
    assert len(out) == 5


def test_density_caps_60min_strength_at_ratio():
    # 60 / 7 = ~8 → cap at 8 (not artificially low for longer durations).
    out = cap_exercise_count_by_density(_mk_exes(12), 60, "strength")
    assert len(out) == 8


def test_density_passthrough_when_under_cap():
    out = cap_exercise_count_by_density(_mk_exes(3), 30, "strength")
    assert len(out) == 3
