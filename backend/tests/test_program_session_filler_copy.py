"""
Regression gate for row 103 (2026-08 backend prompt sweep): the Schedule tab
showed TWO different effort vocabularies inside one session card — Gemini-
authored exercises say "Effort 9 out of 10" (plain language, see
scripts/rewrite_program_copy_plain_language.py), but every accessory
program_session_filler.py backfills onto a thin session carried the RIR
("reps in reserve") shorthand "Moderate — leave 1-2 reps in reserve" — jargon
a normal user can't parse, and a second vocabulary next to the authored one.

Fix: services/program_session_filler.py `_build_session_exercise` no longer
emits RIR notation. No specific effort number is fabricated (the filler has
no computed difficulty for a backfilled accessory) — "moderate, not to
failure" is the honest claim, phrased in plain English.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.program_session_filler import _build_session_exercise  # noqa: E402


def _cand(**overrides):
    base = {
        "name": "Cable Lateral Raise",
        "exercise_id": "ex-1",
        "equipment": "Cable",
        "body_part": "Shoulders",
        "target_muscle": "Deltoids",
        "safety_difficulty": "intermediate",
    }
    base.update(overrides)
    return base


def test_backfilled_weight_guidance_has_no_rir_jargon():
    ex = _build_session_exercise(_cand(), template={"sets": 3, "reps": 12, "rest_seconds": 60}, workout={})
    guidance = ex["weight_guidance"]
    lowered = guidance.lower()
    assert "reps in reserve" not in lowered, (
        f"weight_guidance still uses RIR shorthand a normal user can't parse: {guidance!r}"
    )
    assert "rir" not in lowered, f"weight_guidance still uses bare RIR: {guidance!r}"


def test_backfilled_weight_guidance_matches_authored_plain_vocabulary():
    # Doesn't need to be byte-identical to "Effort N out of 10" (no real
    # number exists for a backfilled accessory), but it must read like the
    # same plain-English family the authored exercises use, not a distinct
    # formal notation.
    ex = _build_session_exercise(_cand(), template={"sets": 3, "reps": 12, "rest_seconds": 60}, workout={})
    guidance = ex["weight_guidance"].lower()
    assert "effort" in guidance or "moderate" in guidance
    assert "in the tank" in guidance or "not to failure" in guidance or "left" in guidance
