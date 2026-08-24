"""Regression gate — E2E register #233 (audit follow-up).

A prior fix to `_resolve_canonical_exercise`
(api/v1/users/exercises.py:24-53) only handled CASING via an exact
case-insensitive `ilike` (no wildcards) against `exercise_library_cleaned`.
A second, independent audit found this overstated: live proof against the
app's own Quick-Add suggestion list
(mobile/flutter/lib/screens/settings/exercise_preferences/widgets/
empty_state_with_suggestions.dart) showed 9 of 12 names still resolved to
0 rows and therefore still persisted `exercise_id: null` — the library only
carries heavily-qualified variants of those names ("Ring Dips", "Pull-Up
Normal Grip", ...), never the plain form the app's own chips display
("Dips", "Pull-Up", ...).

This module fakes the Supabase postgrest chain (real `ilike`/`eq` filter
semantics over an in-memory row list, mirroring
test_exercise_resolution_exact_match_preference.py's approach) across the
three tables the fixed resolver now consults — `exercise_library_cleaned`,
`exercise_aliases`, `exercise_canonical` — so the tests exercise the ACTUAL
resolution order, not a hand-fed return value.
"""
from __future__ import annotations

import re
from typing import Any, Dict, List
from unittest.mock import MagicMock

import pytest

from api.v1.users.exercises import _resolve_canonical_exercise


# ---------------------------------------------------------------------------
# Fake PostgREST chain: select().ilike()/.eq()...limit().execute()
# Each predicate call narrows the in-memory row list; multiple .ilike() calls
# on the same query AND together (mirrors real PostgREST chaining), which is
# exactly what the token-overlap fallback relies on.
# ---------------------------------------------------------------------------

class _FakeExecuteResult:
    def __init__(self, data: List[Dict[str, Any]]):
        self.data = data


class _FakeQuery:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._rows = rows
        self._limit_n = None

    def select(self, *_a, **_kw):
        return self

    def ilike(self, column: str, pattern: str):
        # Translate the ILIKE pattern to a regex ('%' = any run of chars);
        # none of this module's fixtures need '_'/backslash escaping.
        regex_src = "^" + ".*".join(re.escape(part) for part in pattern.split("%")) + "$"
        regex = re.compile(regex_src, re.IGNORECASE)
        self._rows = [r for r in self._rows if regex.match(str(r.get(column) or ""))]
        return self

    def eq(self, column: str, value: Any):
        self._rows = [r for r in self._rows if r.get(column) == value]
        return self

    def limit(self, n: int):
        self._limit_n = n
        return self

    def execute(self):
        rows = self._rows
        if self._limit_n is not None:
            rows = rows[: self._limit_n]
        return _FakeExecuteResult(list(rows))


class _FakeTable:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._rows = rows

    def select(self, *_a, **_kw):
        return _FakeQuery(self._rows)


class _FakeClient:
    def __init__(self, tables: Dict[str, List[Dict[str, Any]]]):
        self._tables = tables

    def table(self, name: str):
        return _FakeTable(self._tables.get(name, []))


def _make_db(tables: Dict[str, List[Dict[str, Any]]]):
    db = MagicMock()
    db.client = _FakeClient(tables)
    return db


# ---------------------------------------------------------------------------
# Fixture data mirroring the shapes actually seen live: exercise_library_cleaned
# never carries a plain "Dips"/"Barbell Back Squat"/etc. row, only qualified
# variants; exercise_aliases maps the plain name to exercise_canonical, a
# DIFFERENT id space than exercise_library_cleaned.
# ---------------------------------------------------------------------------

_LIBRARY_ROWS = [
    {"id": "lib-bench", "name": "Barbell Bench Press"},
    {"id": "lib-dumbbell-bench", "name": "Dumbbell Bench Press"},
    {"id": "lib-ring-dips", "name": "Ring Dips"},
    {"id": "lib-chair-dips", "name": "Chair Triceps Dips"},
]

_ALIAS_ROWS = [
    # Deliberately ALSO carries an alias for a name that has a real exact
    # match in the library, pointing at a DIFFERENT canonical id — proves
    # exact match wins and the alias table is never even consulted for it.
    {"alias_name_normalized": "barbell bench press", "canonical_exercise_id": "canon-wrong"},
    {"alias_name_normalized": "barbell back squat", "canonical_exercise_id": "canon-squat"},
    {"alias_name_normalized": "dips", "canonical_exercise_id": "canon-dips"},
    {"alias_name_normalized": "pull up", "canonical_exercise_id": "canon-pullup"},
]

_CANONICAL_ROWS = [
    {"id": "canon-wrong", "canonical_name": "WRONG - should never be returned", "display_name": None},
    {"id": "canon-squat", "canonical_name": "Barbell squat back POV", "display_name": None},
    {"id": "canon-dips", "canonical_name": "Chest dip with pause bodyweight", "display_name": None},
    {"id": "canon-pullup", "canonical_name": "Pull up normal grip", "display_name": None},
]


def _tables():
    return {
        "exercise_library_cleaned": list(_LIBRARY_ROWS),
        "exercise_aliases": list(_ALIAS_ROWS),
        "exercise_canonical": list(_CANONICAL_ROWS),
    }


class TestExactMatchStillWinsOverAlias:

    def test_exact_library_match_is_never_overridden_by_an_alias(self):
        db = _make_db(_tables())
        resolved_id, resolved_name = _resolve_canonical_exercise(
            db, "Barbell Bench Press", None
        )
        assert resolved_id == "lib-bench"
        assert resolved_name == "Barbell Bench Press"

    def test_caller_supplied_exercise_id_is_trusted_as_is(self):
        db = _make_db(_tables())
        resolved_id, resolved_name = _resolve_canonical_exercise(
            db, "Anything", "already-canonical-id"
        )
        assert resolved_id == "already-canonical-id"
        assert resolved_name == "Anything"


class TestAliasFallbackHandlesNamingVariance:
    """E2E #233: names the cleaned library has no plain-form row for."""

    def test_barbell_back_squat_resolves_via_alias(self):
        db = _make_db(_tables())
        resolved_id, resolved_name = _resolve_canonical_exercise(
            db, "Barbell Back Squat", None
        )
        assert resolved_id == "canon-squat"
        assert resolved_name == "Barbell squat back POV"

    def test_dips_resolves_via_alias_not_an_arbitrary_substring_row(self):
        db = _make_db(_tables())
        resolved_id, resolved_name = _resolve_canonical_exercise(db, "Dips", None)
        # Must NOT silently pick "Ring Dips" / "Chair Triceps Dips" — those
        # are the exact wrong-row hazard this fix exists to avoid.
        assert resolved_id == "canon-dips"
        assert resolved_name == "Chest dip with pause bodyweight"

    def test_pull_up_resolves_via_alias(self):
        db = _make_db(_tables())
        resolved_id, resolved_name = _resolve_canonical_exercise(db, "Pull-Up", None)
        assert resolved_id == "canon-pullup"


class TestTokenFallbackForUnaliasedNames:

    def test_unaliased_but_present_name_resolves_via_token_overlap(self):
        tables = _tables()
        # No alias entry for "dumbbell bench" — must still resolve via the
        # token-overlap fallback against exercise_library_cleaned.
        db = _make_db(tables)
        resolved_id, resolved_name = _resolve_canonical_exercise(
            db, "Dumbbell Bench", None
        )
        assert resolved_id == "lib-dumbbell-bench"
        assert resolved_name == "Dumbbell Bench Press"


class TestGenuinelyMissingNameFallsBackToGivenValue:

    def test_nothing_resolves_returns_name_and_id_as_given(self):
        db = _make_db(_tables())
        resolved_id, resolved_name = _resolve_canonical_exercise(
            db, "Some Totally Unknown Exercise Xyz", None
        )
        assert resolved_id is None
        assert resolved_name == "Some Totally Unknown Exercise Xyz"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
