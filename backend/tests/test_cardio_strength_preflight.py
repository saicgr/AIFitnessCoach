"""Unit tests for the cardio-only + strength-focus preflight gate (Phase 3 fix C).

Covers C1–C12 from the plan. Verifies that
`check_equipment_focus_compatibility` raises 422 only when ALL the
following hold:
- equipment is non-empty
- no bodyweight token in user equipment list
- every equipment item resolves to category=cardio_equipment
- focus_area is a strength-style focus

Run: cd backend && .venv/bin/python -m pytest tests/test_cardio_strength_preflight.py -v
"""
from __future__ import annotations

import asyncio
import os
import sys

import pytest
from fastapi import HTTPException

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.equipment_resolver import EquipmentResolver  # noqa: E402
from api.v1.workouts.generation_helpers import (  # noqa: E402
    check_equipment_focus_compatibility,
)


@pytest.fixture(scope="module", autouse=True)
def _load_resolver():
    asyncio.get_event_loop().run_until_complete(EquipmentResolver.get_instance())


def _expect_422(focus, eq, code="INCOMPATIBLE_EQUIPMENT_FOCUS"):
    with pytest.raises(HTTPException) as exc:
        check_equipment_focus_compatibility(focus, eq)
    assert exc.value.status_code == 422
    assert exc.value.detail.get("code") == code


def _expect_pass(focus, eq):
    # Should NOT raise
    check_equipment_focus_compatibility(focus, eq)


# C1: cardio-only + full_body
def test_c1_cardio_only_full_body_rejects():
    _expect_422("full_body", ["treadmill", "stationary_bike",
                              "rowing_machine", "elliptical"])


# C2: cardio + bodyweight token explicit → pass
def test_c2_cardio_plus_bw_token_passes():
    _expect_pass("full_body", ["treadmill", "bodyweight"])


# C3: cardio + dumbbells (mixed) → pass
def test_c3_cardio_plus_dumbbells_passes():
    _expect_pass("full_body", ["treadmill", "dumbbells"])


# C4: empty list → pass (bw-only path)
def test_c4_empty_equipment_passes():
    _expect_pass("full_body", [])


# C5–C7: cardio-aligned focuses → pass even with cardio-only gear
@pytest.mark.parametrize("focus", ["cardio", "endurance", "hiit",
                                    "mobility", "flexibility"])
def test_c5_c7_cardio_friendly_focuses_pass(focus):
    _expect_pass(focus, ["treadmill"])


# C8: unknown alias → fail open (don't over-reject)
def test_c8_unknown_equipment_fails_open():
    _expect_pass("full_body", ["peloton_alien_brand"])


# C9: E13_TRX equipment → not cardio → pass
def test_c9_trx_equipment_passes():
    _expect_pass("full_body",
                 ["TRX bands", "resistance_bands", "yoga mat"])


# Strength focuses with non-cardio gear all pass
@pytest.mark.parametrize("focus", ["push", "pull", "legs", "upper",
                                    "lower", "chest", "back", "arms",
                                    "shoulders", "core", "glutes"])
def test_strength_focuses_with_dumbbells_pass(focus):
    _expect_pass(focus, ["dumbbells"])


# Cardio-only equipment with each strength focus rejects
@pytest.mark.parametrize("focus", ["push", "pull", "legs", "upper",
                                    "lower", "full_body"])
def test_cardio_only_each_strength_focus_rejects(focus):
    _expect_422(focus, ["treadmill"])


def test_response_includes_focus_and_categories():
    with pytest.raises(HTTPException) as exc:
        check_equipment_focus_compatibility("full_body", ["treadmill"])
    detail = exc.value.detail
    assert detail["focus_area"] == "full_body"
    assert "cardio_equipment" in detail["equipment_categories"]
