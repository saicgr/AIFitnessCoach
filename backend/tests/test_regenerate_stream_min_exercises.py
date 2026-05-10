"""Phase B — workout floor invariants for /regenerate-stream.

The cascade + post-Gemini pad guarantee that a successful regenerate
always returns ≥ MIN_EXERCISES exercises. These pure-unit tests pin the
helper invariants that protect that floor.

Full end-to-end coverage of /regenerate-stream itself requires a live
DB + Gemini → that's covered by `scripts/audit_csv_quality.py` against
post-fix sweep CSVs, not unit tests.
"""
import pytest

from services.exercise_rag.injury_focus_alternatives import get_curated_alternatives


# Every (injury, focus) combo that returned n_ex < 3 in the 2026-05-08
# baseline sweep must now have ≥4 curated alternatives so the cascade
# tier-2 path can hit the floor without dropping into safety_mode.
_SWEEP_FAILURE_COMBOS = [
    ("shoulder", "push"),
    ("shoulder", "pull"),
    ("shoulder", "full_body"),
    ("knee", "legs"),
    ("knee", "full_body"),
    ("hip", "legs"),
    ("hip", "full_body"),
    ("ankle", "legs"),
    ("ankle", "full_body"),
    ("lower_back", "pull"),
    ("lower_back", "legs"),
    ("lower_back", "full_body"),
    ("elbow", "push"),
    ("elbow", "pull"),
    ("wrist", "push"),
    ("wrist", "pull"),
]


@pytest.mark.parametrize("injury,focus", _SWEEP_FAILURE_COMBOS)
def test_floor_combo_has_min_curated_alternatives(injury, focus):
    """For every failure combo from the sweep, the curated map must
    yield ≥4 alternatives so cascade tier 2 can satisfy MIN_EXERCISES=4."""
    alts = get_curated_alternatives([injury], focus)
    assert len(alts) >= 4, (
        f"({injury}, {focus}) has only {len(alts)} alternatives — "
        f"cascade can't hit floor=4 without falling into safety_mode"
    )


def test_multi_injury_combos_still_have_alternatives():
    """Combos like inj=knee+shoulder + focus=full_body must still
    resolve to a non-empty set (cascade tier 2 dedupes)."""
    multi = [
        (["knee", "shoulder"], "full_body"),
        (["lower_back", "knee"], "full_body"),
        (["wrist", "elbow", "shoulder"], "upper"),
    ]
    for injuries, focus in multi:
        alts = get_curated_alternatives(injuries, focus)
        assert alts, f"empty alternatives for {injuries} + {focus}"


def test_min_floor_constant_is_documented():
    """Sanity check: the constant lives in versioning.py and the cascade
    contract documents 4 as the default. If this changes, the audit
    script in scripts/audit_csv_quality.py must update too."""
    src = open(
        "/Users/saichetangrandhe/AIFitnessCoach/backend/api/v1/workouts/versioning.py"
    ).read()
    assert "MIN_EXERCISES = 4" in src, (
        "MIN_EXERCISES floor changed — update audit_csv_quality.py "
        "and this test together."
    )
