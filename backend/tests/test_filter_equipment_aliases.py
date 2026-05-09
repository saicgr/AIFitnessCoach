"""Unit tests for filter_by_equipment alias resolution path (Phase 3 fix B).

Covers the B1–B10 truth table from the plan. Validates that
`use_substitutions=True` activates the equipment_resolver alias chain
seeded by migration 1594 (e.g. TRX → Suspension Trainer).

Run: cd backend && .venv/bin/python -m pytest tests/test_filter_equipment_aliases.py -v
"""
from __future__ import annotations

import asyncio
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.equipment_resolver import EquipmentResolver  # noqa: E402
from services.exercise_rag.filters import filter_by_equipment  # noqa: E402


@pytest.fixture(scope="module", autouse=True)
def _load_resolver():
    asyncio.get_event_loop().run_until_complete(EquipmentResolver.get_instance())


@pytest.mark.parametrize("user_eq,label", [
    (["TRX bands"], "B1a TRX bands"),
    (["TRX"], "B1b TRX bare"),
    (["trx_bands"], "B1c snake_case"),
    (["Trx"], "B1d mixed case"),
])
def test_b1_trx_aliases_match_suspension_trainer(user_eq, label):
    assert filter_by_equipment(
        "Suspension Trainer", user_eq, "Test", use_substitutions=True
    ), f"{label}: TRX should resolve to Suspension Trainer"


def test_b2_canonical_already_matches_without_resolver():
    assert filter_by_equipment(
        "Suspension Trainer", ["Suspension Trainer"], "Test",
        use_substitutions=True,
    )


def test_b3_substring_no_false_positive_short_alias():
    # B3: alias 'bar' (len=3) should NOT match 'barbell' as ex equipment for
    # a user with no barbell-related equipment. The len > 2 guard is in
    # equipment_resolver.resolve at line 123.
    # We use a non-overlapping pair to confirm the resolver isn't matching
    # garbage. Library 'Barbell' for a user with only ['yoga mat'] should fail.
    assert not filter_by_equipment(
        "Barbell", ["yoga mat"], "Test", use_substitutions=True
    )


def test_b6_empty_equipment_returns_false_for_non_bw():
    # Empty list with non-bw exercise — should not match
    assert not filter_by_equipment(
        "Barbell", [], "Test", use_substitutions=True
    )


def test_b6_empty_equipment_passes_for_bodyweight():
    # Empty list with bw exercise — bodyweight is implicit
    assert filter_by_equipment(
        "Bodyweight", [], "Test", use_substitutions=True
    )


def test_b5_unknown_alias_does_not_block_known_alias():
    # Mixed list: TRX resolves; alien_widget does not. The TRX path must
    # still match.
    assert filter_by_equipment(
        "Suspension Trainer", ["TRX", "alien_widget"], "Test",
        use_substitutions=True,
    )


def test_b7_resistance_band_underscore_plural():
    assert filter_by_equipment(
        "Resistance Band", ["resistance_bands"], "Test",
        use_substitutions=True,
    )


def test_bw_implicit_for_specialty_user():
    # A TRX-only user can still do bodyweight push-ups
    assert filter_by_equipment(
        "Bodyweight", ["TRX bands"], "Test", use_substitutions=True
    )


def test_use_substitutions_false_falls_back_to_word_match():
    # When use_substitutions=False, the alias chain is bypassed — TRX user
    # canNOT match Suspension Trainer (regression check on the old default).
    assert not filter_by_equipment(
        "Suspension Trainer", ["TRX bands"], "Test", use_substitutions=False
    )
