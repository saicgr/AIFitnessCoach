"""Phase G — `infer_workout_type_from_prompt` must classify free-text
ai_prompt strings into a workout type, no LLM calls.

Sweep (2026-05-08) idx 68/75/77/258/276/279/305: user explicitly asked for
cardio/mobility/5K/marathon via ai_prompt but output was always strength
because no inference happened. This test pins the keyword classifier.
"""
import pytest

from api.v1.workouts.generation_helpers import infer_workout_type_from_prompt


@pytest.mark.parametrize("prompt,expected", [
    # cardio
    ("more cardio please, i want to sweat", "cardio"),
    ("training for a 5K in 8 weeks", "cardio"),
    ("training for a 10k in 12 weeks", "cardio"),
    ("marathon training, week 8 of 16", "cardio"),
    ("more cardio but no impact", "cardio"),
    ("post-injury return-to-running phase 2", "cardio"),
    ("zone 2 ride for 45 min", "cardio"),
    ("steady state on the bike", "cardio"),
    ("rowing intervals", "cardio"),

    # mobility
    ("easy day, foam rolling and stretching only", "mobility"),
    ("cycle day 1, cramps, mobility focus", "mobility"),
    ("yoga flow today", "mobility"),
    ("recovery and stretching", "mobility"),

    # hiit
    ("quick hiit session", "hiit"),
    ("amrap 20", "hiit"),
    ("tabata style", "hiit"),
    ("crossfit metcon", "hiit"),
    ("EMOM 12", "hiit"),

    # strength / hypertrophy / power
    ("I want a workout that focuses on hypertrophy of the upper body", "strength"),
    ("pure strength but high reps", "strength"),
    ("make it harder", "strength"),
    ("Olympic lifting today — snatch + clean and jerk", "strength"),
    ("explosive plyometrics", "strength"),
    ("bodybuilding chest pump", "strength"),

    # no signal — return None and let caller fall back
    ("just a normal workout", None),
    ("", None),
    (None, None),
    ("some random text without keywords", None),
])
def test_keyword_classifier(prompt, expected):
    assert infer_workout_type_from_prompt(prompt) == expected


def test_first_match_wins_priority_order():
    """When multiple categories match, the first declared category wins.
    `hiit` is declared before `cardio`, so 'hiit cardio circuit' → hiit."""
    assert infer_workout_type_from_prompt("hiit cardio circuit") == "hiit"


def test_case_insensitive():
    assert infer_workout_type_from_prompt("MARATHON TRAINING") == "cardio"
    assert infer_workout_type_from_prompt("Foam Roll Recovery") == "mobility"
