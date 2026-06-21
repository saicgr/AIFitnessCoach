"""Injury-safety guard — codified pure-logic gate (injury-2026-06 Phase 1.5).

The full input→output matrix runs live against Render via
``backend/scripts/injury_test_harness.py`` (it needs the real DB + stochastic
Gemini). THESE tests pin the deterministic pieces of the guard so the safety
invariant can't silently regress in CI without a live run:

  - the injury → contraindicated-movement PROMPT constraint (prevention layer)
  - the canonical name-keyword backstop (catches index name-variant misses)
  - the joint → ``*_safe`` column resolver (only the 8 jointed injuries gate)

The drop/replace DB path is exercised end-to-end by the live harness; here we
assert the in-memory decision logic that decides WHAT counts as unsafe.
"""
import pytest

from services.gemini.workout_streaming import build_injury_prompt_constraint
from services.exercise_rag.injury_guard import (
    _name_keyword_banned,
    _build_replacement,
)
from services.exercise_rag.service import _resolve_injury_columns


# ---------------------------------------------------------------------------
# 1. Prompt prevention — every active injury injects a hard movement ban.
# ---------------------------------------------------------------------------

def test_prompt_constraint_bans_per_injury():
    block = build_injury_prompt_constraint(["lower_back"])
    assert "CONTRAINDICATED" in block
    assert "deadlift" in block.lower()
    assert "kettlebell swing" in block.lower()


def test_prompt_constraint_multi_injury_covers_all():
    block = build_injury_prompt_constraint(["knees", "shoulders"]).lower()
    assert "squat" in block          # knee ban
    assert "overhead press" in block  # shoulder ban


def test_prompt_constraint_empty_when_no_injury():
    assert build_injury_prompt_constraint([]) == ""
    assert build_injury_prompt_constraint(None) == ""


def test_prompt_constraint_lower_back_not_doubled():
    # "lower_back" contains "back"; the more-specific lumbar line must appear
    # once and the generic "back" line must NOT be duplicated alongside it.
    block = build_injury_prompt_constraint(["lower_back"])
    assert block.count("Lower Back injury") == 1
    assert "Back injury" not in block.replace("Lower Back injury", "")


def test_prompt_constraint_muscle_chip_still_advises():
    # A muscle-area chip with no movement map still gets a conservative note.
    block = build_injury_prompt_constraint(["biceps"]).lower()
    assert "injur" in block and "biceps" in block


# ---------------------------------------------------------------------------
# 2. Name-keyword backstop — canonical movements drop even on an index miss.
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("name,injuries", [
    ("Good Morning", ["lower_back"]),
    ("Romanian Deadlift", ["lower_back"]),
    ("Kettlebell Swing", ["lower_back"]),
    ("Pistol Squat", ["knees"]),
    ("Jumping Lunge", ["knees"]),
    ("Behind The Neck Press", ["shoulders"]),
    ("Barbell Upright Row", ["shoulders"]),
    ("Box Jump", ["ankles"]),
])
def test_keyword_backstop_drops_canonical(name, injuries):
    assert _name_keyword_banned(name.lower(), injuries) is True


@pytest.mark.parametrize("name,injuries", [
    ("Cable Triceps Pushdown", ["lower_back"]),
    ("Leg Extension", ["lower_back"]),
    ("Seated Chest Press", ["knees"]),
    ("Lateral Raise", ["knees"]),
])
def test_keyword_backstop_keeps_safe(name, injuries):
    assert _name_keyword_banned(name.lower(), injuries) is False


def test_keyword_backstop_lower_back_not_double_counted_via_back():
    # "lower_back" must not also fire the generic "back" set redundantly; the
    # function still returns True (lower_back set covers it) — assert no crash
    # and correct verdict.
    assert _name_keyword_banned("barbell deadlift", ["lower_back"]) is True


# ---------------------------------------------------------------------------
# 3. Joint resolver — only the 8 jointed injuries map to a *_safe column.
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("injury,col", [
    ("knees", "knee_safe"),
    ("lower_back", "lower_back_safe"),
    ("shoulders", "shoulder_safe"),
    ("wrists", "wrist_safe"),
    ("ankles", "ankle_safe"),
    ("hips", "hip_safe"),
    ("neck", "neck_safe"),
    ("elbows", "elbow_safe"),
])
def test_joint_resolves_to_safe_column(injury, col):
    assert col in _resolve_injury_columns([injury])


@pytest.mark.parametrize("chip", ["biceps", "chest", "abs", "calves", "quads", "glutes"])
def test_muscle_chip_has_no_safe_column(chip):
    # Muscle-area chips have no *_safe column — they're handled by avoided_muscles
    # upstream, NOT by the index gate. The resolver must return nothing for them.
    assert _resolve_injury_columns([chip]) == []


def test_multi_injury_unions_columns():
    cols = _resolve_injury_columns(["knees", "lower_back", "shoulders"])
    assert set(cols) == {"knee_safe", "lower_back_safe", "shoulder_safe"}


# ---------------------------------------------------------------------------
# 4. Replacement clone — inherits a valid set/rep structure, swaps identity.
# ---------------------------------------------------------------------------

def test_replacement_clones_structure_swaps_identity():
    template = {"name": "Surviving Press", "sets": 4, "reps": 8,
                "rest_seconds": 90, "set_targets": [{"reps": 8}], "weight": 50}
    cand = {"name": "Machine Chest Press", "equipment": "machine",
            "target_muscle": "chest", "exercise_id": "abc-123",
            "movement_pattern": "horizontal_push"}
    repl = _build_replacement(template, cand)
    assert repl["name"] == "Machine Chest Press"
    assert repl["sets"] == 4 and repl["reps"] == 8 and repl["rest_seconds"] == 90
    assert repl["library_id"] == "abc-123"
    assert repl["muscle_group"] == "chest"


def test_replacement_defaults_when_template_sparse():
    repl = _build_replacement({}, {"name": "Safe Move"})
    assert repl["sets"] == 3 and repl["reps"] == 10 and repl["rest_seconds"] == 60
    assert repl["name"] == "Safe Move"
