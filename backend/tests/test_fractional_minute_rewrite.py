"""
Regression gate for row 110 (2026-08 backend prompt sweep): Program detail ->
SCHEDULE tab (Pilates Foundations and others) showed interval descriptions in
fractional minutes — "3 rounds: 1 min hard, 0.5 min easy", "2 rounds: 3 min
hard, 1.5 min easy" — nobody reads a rest interval as a decimal minute.

Two fixes, tested separately:
  - scripts/program_build.py `_rewrite_minutes_text` (the GENERATOR that
    produced these at derive-time) — see test_program_build_minutes_rewrite.py.
  - scripts/rewrite_program_copy_plain_language.py `rewrite()` (the CONTENT
    repair pass for already-shipped catalog rows) — covered here. Catalog-wide
    scan found 663 program_variant_weeks rows with a "\\d+\\.\\d+ min" pattern.

No paid calls: pure string-rewrite unit tests.
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "scripts"))

import rewrite_program_copy_plain_language as r  # noqa: E402


def test_the_exact_shipped_defect_strings():
    assert r.rewrite("3 rounds: 1 min hard, 0.5 min easy") == "3 rounds: 1 min hard, 30 sec easy"
    assert r.rewrite("2 rounds: 3 min hard, 1.5 min easy") == "2 rounds: 3 min hard, 90 sec easy"


def test_whole_minutes_are_untouched():
    assert r.rewrite("Rest 2 minutes between sets") == "Rest 2 minutes between sets"


def test_idempotent():
    once = r.rewrite("3 rounds: 1 min hard, 0.5 min easy")
    twice = r.rewrite(once)
    assert once == twice


def test_quarter_minute_rounds_to_nearest_second():
    assert r.rewrite("Hold for 0.25 min") == "Hold for 15 sec"
