"""Harness-side regression test for Phase 3 fix D.

Asserts every block 4 scenario sets force_non_preferred_day=True so the
preferred-day gate (correct 409 response on rest days) doesn't false-fail
the validation harness.

Run: cd backend && .venv/bin/python -m pytest tests/test_scenarios_500_block4_force.py -v
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts._scenarios_500 import build_500  # noqa: E402


def test_block4_all_force_true():
    scenarios = build_500()
    block4 = [s for s in scenarios if s.get("block") == 4]
    assert block4, "Block 4 should not be empty"
    offenders = [
        s for s in block4
        if s["body"].get("force_non_preferred_day") is not True
    ]
    assert not offenders, (
        f"{len(offenders)} block-4 scenarios still have "
        f"force_non_preferred_day != True; first: {offenders[0]['label']}"
    )


def test_no_scenario_explicitly_sets_force_false():
    """Defense in depth: no scenario anywhere should set force=False since
    we have a dedicated gate test elsewhere."""
    scenarios = build_500()
    offenders = [
        s for s in scenarios
        if s["body"].get("force_non_preferred_day") is False
    ]
    assert not offenders, (
        f"{len(offenders)} scenarios set force_non_preferred_day=False; "
        f"first: block={offenders[0].get('block')} label={offenders[0]['label']}"
    )
