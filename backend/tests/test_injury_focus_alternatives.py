"""Phase A — curated injury×focus alternatives map coverage.

Verifies the hand-curated map (`injury_focus_alternatives.py`) returns
clinically appropriate substrings for every realistic combination tested
in the 2026-05-08 sweep, so the cascade tier 2 always has material to
work with before falling back to safety-mode mobility.
"""
import pytest

from services.exercise_rag.injury_focus_alternatives import (
    INJURY_FOCUS_ALTERNATIVES,
    UNIVERSAL_SAFE_BY_FOCUS,
    get_curated_alternatives,
    has_curated_coverage,
    normalize_focus,
)


_EXPECTED_INJURIES = {
    "shoulder", "lower_back", "knee", "elbow", "wrist", "ankle", "hip", "neck",
}


def test_every_supported_injury_has_some_entry():
    covered = {pair[0] for pair in INJURY_FOCUS_ALTERNATIVES.keys()}
    missing = _EXPECTED_INJURIES - covered
    assert not missing, f"missing injury coverage: {missing}"


def test_every_entry_has_at_least_4_alternatives():
    for (inj, foc), alts in INJURY_FOCUS_ALTERNATIVES.items():
        assert len(alts) >= 4, (
            f"({inj}, {foc}) has only {len(alts)} alternatives — "
            f"the cascade needs ≥4 to hit MIN_EXERCISES floor"
        )


@pytest.mark.parametrize("injury,focus", [
    # Cases that returned `n_ex=1` or `no_ex` in the sweep:
    ("shoulder", "push"),
    ("shoulder", "pull"),
    ("knee", "legs"),
    ("knee", "full_body"),
    ("hip", "full_body"),
    ("hip", "legs"),
    ("ankle", "full_body"),
    ("ankle", "legs"),
    ("lower_back", "pull"),
    ("lower_back", "full_body"),
    ("elbow", "push"),
    ("wrist", "push"),
])
def test_sweep_failure_combos_now_return_alternatives(injury, focus):
    alts = get_curated_alternatives([injury], focus)
    assert alts, f"no curated alternatives for ({injury}, {focus})"
    assert len(alts) >= 4


def test_full_body_expands_across_subfocuses():
    """full_body should fan out into push + pull + lower + core picks
    so a knee-injured user requesting full_body still gets variety."""
    alts = get_curated_alternatives(["knee"], "full_body")
    # Should include both upper-body alternatives and knee-friendly lower
    has_lower = any("hip thrust" in a or "glute bridge" in a for a in alts)
    has_core = any("dead bug" in a or "bird dog" in a for a in alts)
    assert has_lower, f"full_body+knee missing lower-body picks: {alts}"
    assert has_core, f"full_body+knee missing core picks: {alts}"


def test_universal_fallback_for_uncovered_focus():
    """If no entry matches, mobility/recovery/core focuses fall back to
    universal-safe defaults."""
    # 'neck' has no `push` entry — but core/mobility focuses fall through.
    alts = get_curated_alternatives(["neck"], "mobility")
    assert alts, "mobility focus must have universal fallback"


def test_focus_aliases_normalized():
    assert normalize_focus("upper_body") == "upper"
    assert normalize_focus("lower_body") == "lower"
    assert normalize_focus("Legs") == "legs"
    assert normalize_focus("hinge") == "pull"
    assert normalize_focus("abs") == "core"


def test_no_injuries_returns_empty():
    assert get_curated_alternatives([], "push") == []
    assert get_curated_alternatives(None, "push") == []


def test_dedup_across_multi_injury():
    """Two injuries that share alternatives shouldn't return duplicates."""
    alts = get_curated_alternatives(["shoulder", "elbow"], "push")
    assert len(alts) == len(set(alts))


def test_has_curated_coverage_predicate():
    assert has_curated_coverage(["shoulder"], "push")
    assert has_curated_coverage(["knee"], "full_body")
    assert not has_curated_coverage([], "push")
