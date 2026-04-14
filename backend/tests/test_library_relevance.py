"""Tests for library exercise search relevance ranking.

Covers the canonical-priority tier-1 logic added to sort_by_relevance() in
api/v1/library/utils.py. Every assertion here reflects a user-visible ordering
expectation in Library → Exercises search.
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.v1.library.models import LibraryExercise
from api.v1.library.utils import (
    sort_by_relevance,
    _get_simplified_and_canonicals,
)


def _ex(name: str) -> LibraryExercise:
    """Minimal LibraryExercise fixture — only fields sort_by_relevance reads."""
    return LibraryExercise(
        id="00000000-0000-0000-0000-000000000000",
        name=name,
        original_name=name,
        body_part="Core",
    )


# ── Tier-1 canonical ordering ─────────────────────────────────────────────────

def test_plank_search_surfaces_canonical_first():
    """User types 'plank' → 'Plank On Elbows' and 'High Plank' must lead."""
    exercises = [_ex(n) for n in [
        "Plank Iytw", "Plank Jack", "Plank Lunges", "Plank Pushup",
        "Plank On Elbows", "Plank Knee Tucks", "High Plank",
    ]]
    ordered = [e.name for e in sort_by_relevance(exercises, "plank")]
    assert ordered[0] == "Plank On Elbows"
    assert ordered[1] == "High Plank"


def test_plank_non_canonical_variants_fall_behind_canonical():
    """'Plank Jack' (short name) must not outrank 'Plank On Elbows' anymore."""
    exercises = [_ex("Plank Jack"), _ex("Plank On Elbows")]
    ordered = [e.name for e in sort_by_relevance(exercises, "plank")]
    assert ordered == ["Plank On Elbows", "Plank Jack"]


def test_side_plank_routes_to_its_own_bucket():
    """Side Plank has its own pattern so it won't match a 'plank' search at tier 1."""
    simplified, _ = _get_simplified_and_canonicals("side plank")
    assert simplified == "Side Plank"


def test_bench_press_canonical_order():
    exercises = [_ex(n) for n in [
        "Decline Bench Press (novelty)", "Dumbbell Bench Press", "Barbell Bench Press",
        "Close Grip Barbell Bench Press", "Band Bench Press",
    ]]
    ordered = [e.name for e in sort_by_relevance(exercises, "bench press")]
    assert ordered[0] == "Barbell Bench Press"
    assert ordered[1] == "Dumbbell Bench Press"


def test_curl_canonical_beats_novelty():
    exercises = [_ex(n) for n in [
        "Chair Pose Curl", "Barbell Curl", "Band Close-Grip Biceps Curl", "Dumbbell Curls",
    ]]
    ordered = [e.name for e in sort_by_relevance(exercises, "curl")]
    assert ordered[0] == "Barbell Curl"
    assert ordered[1] == "Dumbbell Curls"


def test_deadlift_canonical_order():
    exercises = [_ex(n) for n in [
        "Kettlebell Sumo Deadlift", "Barbell Deadlift", "Barbell Sumo Deadlift",
        "Trap Bar Deadlift", "Barbell Romanian Deadlift",
    ]]
    ordered = [e.name for e in sort_by_relevance(exercises, "deadlift")]
    assert ordered[0] == "Barbell Deadlift"


# ── Pattern-ordering invariants (specific before generic) ─────────────────────

def test_hammer_curl_simplifies_to_hammer_not_generic_curl():
    simplified, _ = _get_simplified_and_canonicals("dumbbell hammer curl")
    assert simplified == "Hammer Curl"


def test_preacher_curl_simplifies_to_preacher_not_generic_curl():
    simplified, _ = _get_simplified_and_canonicals("barbell preacher curl")
    assert simplified == "Preacher Curl"


def test_leg_curl_simplifies_to_leg_curl_not_generic_curl():
    simplified, _ = _get_simplified_and_canonicals("seated leg curl")
    assert simplified == "Leg Curl"


def test_bulgarian_split_squat_simplifies_to_itself_not_squat():
    simplified, _ = _get_simplified_and_canonicals("dumbbell bulgarian split squat")
    assert simplified == "Bulgarian Split Squat"


def test_goblet_squat_simplifies_to_goblet_not_squat():
    simplified, _ = _get_simplified_and_canonicals("dumbbell goblet squat")
    assert simplified == "Goblet Squat"


def test_front_squat_simplifies_to_front_not_squat():
    simplified, _ = _get_simplified_and_canonicals("barbell front squat")
    assert simplified == "Front Squat"


def test_romanian_deadlift_simplifies_to_romanian_not_deadlift():
    simplified, _ = _get_simplified_and_canonicals("barbell romanian deadlift")
    assert simplified == "Romanian Deadlift"


def test_trap_bar_deadlift_routes_specifically():
    simplified, _ = _get_simplified_and_canonicals("trap bar deadlift")
    assert simplified == "Trap Bar Deadlift"


def test_upright_row_routes_before_generic_row():
    simplified, _ = _get_simplified_and_canonicals("upright row barbell")
    assert simplified == "Upright Row"


def test_lateral_raise_routes_before_generic_raise_patterns():
    simplified, _ = _get_simplified_and_canonicals("dumbbell one arm lateral raise")
    assert simplified == "Lateral Raise"


def test_calf_raise_routes_to_calf_not_leg_raise():
    simplified, _ = _get_simplified_and_canonicals("dumbbell standing calf raise")
    assert simplified == "Calf Raise"


def test_overhead_press_pattern_catches_shoulder_press():
    simplified, _ = _get_simplified_and_canonicals("dumbbell seated shoulder press")
    assert simplified == "Overhead Press"


def test_military_press_pattern_catches_overhead_press():
    simplified, _ = _get_simplified_and_canonicals("barbell standing military press")
    assert simplified == "Overhead Press"


def test_push_press_simplifies_separately_from_bench_press():
    simplified, _ = _get_simplified_and_canonicals("dumbbell push press")
    assert simplified == "Push Press"


# ── Non-regressions & edge cases ──────────────────────────────────────────────

def test_exact_match_still_tier_zero():
    """Typing the exact DB name must land the exercise at position 0
    regardless of canonical list membership."""
    exercises = [_ex("Plank On Elbows"), _ex("High Plank"), _ex("Plank Jack")]
    ordered = [e.name for e in sort_by_relevance(exercises, "Plank On Elbows")]
    assert ordered[0] == "Plank On Elbows"


def test_typo_query_does_not_crash():
    """Typo that matches no tier still produces a sorted list without raising.
    Tier-5 order uses (length ASC, alphabetical) — shorter names first."""
    exercises = [_ex("Plank On Elbows"), _ex("Plank Jack")]
    ordered = [e.name for e in sort_by_relevance(exercises, "xylophone")]
    assert set(ordered) == {"Plank On Elbows", "Plank Jack"}
    # Tier 5 falls back to length ASC, so "Plank Jack" (10 chars) < "Plank On Elbows" (15)
    assert ordered == ["Plank Jack", "Plank On Elbows"]


def test_empty_query_returns_input_unchanged():
    exercises = [_ex("A"), _ex("B"), _ex("C")]
    assert sort_by_relevance(exercises, "") == exercises


def test_non_canonical_tier1_keeps_word_count_tiebreaker():
    """When canonical list doesn't contain the exercise, fall-through tiebreaker
    must still prefer fewer words / shorter names (today's behavior)."""
    # "fly" pattern canonical = (Machine Fly, Pec Deck Fly, Dumbbell Reverse Fly, Cable Rear Delt Fly)
    # Neither of these is in the canonical list, so both fall to the non-canonical bucket.
    exercises = [_ex("Dumbbell Incline Twisted Fly"), _ex("Band High Fly")]
    ordered = [e.name for e in sort_by_relevance(exercises, "fly")]
    # "Band High Fly" has 3 words vs 4 → ranks first
    assert ordered[0] == "Band High Fly"


def test_canonical_in_middle_of_tier_still_sorts_above_non_canonical():
    """Mixed list: one canonical, several non-canonical. Canonical must be #1."""
    exercises = [_ex(n) for n in [
        "Plank Iytw", "Plank Jack", "High Plank", "Plank Lunges", "Plank Knee Tucks",
    ]]
    ordered = [e.name for e in sort_by_relevance(exercises, "plank")]
    assert ordered[0] == "High Plank"


def test_multiple_canonicals_respect_curated_order():
    """Canonical list is [Plank On Elbows, High Plank] — both present must appear in that order."""
    exercises = [_ex("High Plank"), _ex("Plank On Elbows")]
    ordered = [e.name for e in sort_by_relevance(exercises, "plank")]
    assert ordered == ["Plank On Elbows", "High Plank"]


def test_case_insensitive_canonical_match():
    """Canonical list is lowercased internally — exercise names with any casing
    must still be recognized as canonical."""
    exercises = [_ex("PLANK ON ELBOWS"), _ex("Plank Jack")]
    ordered = [e.name for e in sort_by_relevance(exercises, "plank")]
    assert ordered[0] == "PLANK ON ELBOWS"


def test_canonical_not_in_db_falls_through_gracefully():
    """Canonical list entry that doesn't exist as an exercise must not cause errors.
    Any exercise that does exist still ranks per the curated order."""
    # "Reverse Plank" pattern has canonical=(). Any reverse plank exercise falls to
    # the non-canonical bucket and just uses word-count/length tiebreakers.
    exercises = [_ex("Bench Reverse Plank Hold"), _ex("Reverse Plank Leg Raise")]
    # Both are tier-1 matches for "reverse plank"
    ordered = [e.name for e in sort_by_relevance(exercises, "reverse plank")]
    # 3-word name ranks above 4-word name
    assert ordered[0] == "Reverse Plank Leg Raise"


def test_query_not_matching_any_simplified_name_still_ranks_by_substring():
    """Multi-word query like 'dumbbell curl' doesn't equal any simplified base
    ('Curl'), so it falls to tier 2/3/4 — unchanged behavior."""
    exercises = [_ex("Dumbbell Curl"), _ex("Barbell Curl"), _ex("Dumbbell Hammer Curl")]
    ordered = [e.name for e in sort_by_relevance(exercises, "Dumbbell Curl")]
    # Exact match wins tier 0
    assert ordered[0] == "Dumbbell Curl"
