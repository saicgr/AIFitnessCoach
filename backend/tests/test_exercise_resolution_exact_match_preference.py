"""
Regression test — prod incident: swapping or adding a user-named exercise
silently persisted a DIFFERENT exercise.

`ExerciseLibraryService.search_exercises()` used to run
`.ilike("exercise_name", f"%{query}%").limit(limit).execute()` with NO
ORDER BY and no exact-match preference. With `limit=1` (the shape every
resolution chokepoint calls it with —
`services/exercise_rag/injury_guard.py::_lookup_library_exercise`,
`api/v1/workouts_db.py`, `api/v1/workouts/parse_input.py`) the row returned
was whichever SUBSTRING match Postgres's heap order happened to put first.

Live proof on prod:
  - Requesting "Pull-Up normal grip" persisted "assisted Pull-Up normal grip"
    (equipment: Assisted Chin-Up / Pull-Up Machine).
  - Requesting byte-exact "jumping jack" persisted "Med ball jumping jacks".

A prod SQL sweep found 723 library names are substrings of another; under
heap order, 240 exact names resolve to a different row (33 with different
equipment).

This module fakes the Supabase postgrest chain with a real ILIKE-pattern
matcher (translating percent/underscore/backslash-escaped patterns to regex)
so the tests exercise the ACTUAL resolution/ranking logic — not a hand-fed
mock return value — and would fail again if the exact/prefix/substring
preference regressed.
"""
from __future__ import annotations

import re
from typing import Any, Dict, List
from unittest.mock import patch

import pytest

from services.exercise_library_service import ExerciseLibraryService, escape_ilike
from services.exercise_rag.injury_guard import resolve_user_chosen_exercise


# ---------------------------------------------------------------------------
# Fake PostgREST chain — filters an in-memory row list with REAL ILIKE
# pattern semantics (`%` = any run of chars, `_` = any one char, `\` escapes
# the next char), so escaping bugs and ranking bugs both surface for real.
# ---------------------------------------------------------------------------

def _ilike_pattern_to_regex(pattern: str) -> "re.Pattern[str]":
    out: List[str] = []
    i = 0
    while i < len(pattern):
        ch = pattern[i]
        if ch == "\\" and i + 1 < len(pattern):
            out.append(re.escape(pattern[i + 1]))
            i += 2
            continue
        if ch == "%":
            out.append(".*")
        elif ch == "_":
            out.append(".")
        else:
            out.append(re.escape(ch))
        i += 1
    return re.compile("^" + "".join(out) + "$", re.IGNORECASE | re.DOTALL)


class _FakeExecuteResult:
    def __init__(self, data: List[Dict[str, Any]]):
        self.data = data


class _FakeQuery:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._rows = rows
        self._column = None
        self._pattern = None
        self._order_col = None
        self._limit_n = None

    def select(self, *_a, **_kw):
        return self

    def ilike(self, column: str, pattern: str):
        self._column = column
        self._pattern = pattern
        return self

    def order(self, column: str, **_kw):
        self._order_col = column
        return self

    def limit(self, n: int):
        self._limit_n = n
        return self

    def execute(self):
        regex = _ilike_pattern_to_regex(self._pattern or "")
        matched = [r for r in self._rows if regex.match(str(r.get(self._column) or ""))]
        if self._order_col:
            matched = sorted(matched, key=lambda r: str(r.get(self._order_col) or "").lower())
        if self._limit_n is not None:
            matched = matched[: self._limit_n]
        return _FakeExecuteResult(list(matched))


class _FakeTable:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._rows = rows

    def select(self, *_a, **_kw):
        return _FakeQuery(self._rows)


class _FakeClient:
    def __init__(self, rows: List[Dict[str, Any]]):
        self._rows = rows

    def table(self, _name: str):
        return _FakeTable(self._rows)


_LIBRARY_ROWS: List[Dict[str, Any]] = [
    # Deliberately listed with the SUBSTRING sibling BEFORE the exact match —
    # mirrors the arbitrary-heap-order hazard the prod bug relied on (a
    # first-match/no-ORDER-BY query returns whatever comes first, and there
    # is no guarantee that's the exact one). A fixture that happened to list
    # the exact row first would let the old buggy code pass these tests by
    # accident.
    {"id": 2, "exercise_name": "Med ball jumping jacks", "target_muscle": "calves",
     "body_part": "cardio", "equipment": "medicine ball"},
    {"id": 1, "exercise_name": "jumping jack", "target_muscle": "calves",
     "body_part": "cardio", "equipment": "body weight"},
    {"id": 4, "exercise_name": "assisted Pull-Up normal grip", "target_muscle": "lats",
     "body_part": "back", "equipment": "Assisted Chin-Up / Pull-Up Machine"},
    {"id": 3, "exercise_name": "Pull-Up normal grip", "target_muscle": "lats",
     "body_part": "back", "equipment": "pull-up bar"},
    {"id": 5, "exercise_name": "100 rep something grip challenge", "target_muscle": "forearms",
     "body_part": "lower arms", "equipment": "body weight"},
]


def _make_service(rows: List[Dict[str, Any]]) -> ExerciseLibraryService:
    """Build a real ExerciseLibraryService bound to the fake client, bypassing
    __init__ (which calls get_supabase()) — no Supabase mocking needed."""
    service = ExerciseLibraryService.__new__(ExerciseLibraryService)
    service.client = _FakeClient(rows)
    return service


# ---------------------------------------------------------------------------
# search_exercises: exact > prefix > substring
# ---------------------------------------------------------------------------

class TestExactMatchPreference:

    def test_exact_name_wins_over_longer_substring_sibling_jumping_jack(self):
        service = _make_service(_LIBRARY_ROWS)
        results = service.search_exercises("jumping jack", limit=1)
        assert len(results) == 1
        assert results[0]["name"].lower() == "jumping jack"
        assert results[0]["id"] == 1

    def test_exact_name_wins_over_longer_substring_sibling_pull_up(self):
        service = _make_service(_LIBRARY_ROWS)
        results = service.search_exercises("Pull-Up normal grip", limit=1)
        assert len(results) == 1
        assert results[0]["name"] == "Pull-Up normal grip"
        assert results[0]["id"] == 3
        # the wrong prod behavior handed back the assisted variant instead
        assert results[0]["equipment"] != "Assisted Chin-Up / Pull-Up Machine"

    def test_prefix_match_ranks_above_mid_string_substring(self):
        rows = [
            {"id": 10, "exercise_name": "Banded Pull-Up", "target_muscle": "lats",
             "body_part": "back", "equipment": "band"},
            {"id": 11, "exercise_name": "Pull-Up", "target_muscle": "lats",
             "body_part": "back", "equipment": "pull-up bar"},
            {"id": 12, "exercise_name": "Pull-Up Negative", "target_muscle": "lats",
             "body_part": "back", "equipment": "pull-up bar"},
        ]
        service = _make_service(rows)
        # No exact "Pull" row exists; "Pull-Up" and "Pull-Up Negative" both
        # start with the query ("Pull"), "Banded Pull-Up" only contains it
        # mid-string. Prefix must be ranked ahead of mid-string substring.
        results = service.search_exercises("Pull-Up", limit=1)
        assert results[0]["id"] == 11  # exact match "Pull-Up" itself

        results2 = service.search_exercises("Pull", limit=1)
        assert results2[0]["id"] in (11, 12)  # a prefix match, never id 10

    def test_wildcard_characters_in_query_are_escaped_not_interpreted(self):
        """A literal `%` in a user-typed name must not act as an ILIKE wildcard.

        "100 rep something grip challenge" contains no literal '%' character,
        so it must NOT match a search for "100% grip" once '%' is escaped.
        Before escaping, the unescaped pattern `%100% grip%` reads as the
        wildcard "100" then ANYTHING then " grip" and incorrectly matches it.
        """
        service = _make_service(_LIBRARY_ROWS)
        results = service.search_exercises("100% grip", limit=5)
        assert results == []

    def test_escape_ilike_escapes_percent_underscore_and_backslash(self):
        assert escape_ilike("100% grip") == "100\\% grip"
        assert escape_ilike("under_score") == "under\\_score"
        assert escape_ilike("back\\slash") == "back\\\\slash"


# ---------------------------------------------------------------------------
# Integration through the injury-guard chokepoint: resolve_user_chosen_exercise
# -> _lookup_library_exercise -> search_exercises. Every swap/add surface
# funnels through here, so proving it here proves the fix reaches production.
# ---------------------------------------------------------------------------

class TestInjuryGuardChokepointUsesExactMatch:

    @pytest.mark.asyncio
    async def test_resolve_user_chosen_exercise_returns_exact_match(self):
        fake_service = _make_service(_LIBRARY_ROWS)
        with patch(
            "services.exercise_library_service.get_exercise_library_service",
            return_value=fake_service,
        ):
            resolved = await resolve_user_chosen_exercise("jumping jack", injuries=[])
        assert resolved is not None
        assert resolved["name"].lower() == "jumping jack"
        assert resolved["id"] == 1

    @pytest.mark.asyncio
    async def test_resolve_user_chosen_exercise_does_not_return_assisted_variant(self):
        fake_service = _make_service(_LIBRARY_ROWS)
        with patch(
            "services.exercise_library_service.get_exercise_library_service",
            return_value=fake_service,
        ):
            resolved = await resolve_user_chosen_exercise(
                "Pull-Up normal grip", injuries=[]
            )
        assert resolved is not None
        assert resolved["id"] == 3
        assert resolved["equipment"] != "Assisted Chin-Up / Pull-Up Machine"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
