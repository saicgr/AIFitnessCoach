"""Regression gate for the NULL-readiness aggregation class (E2E register row 9).

`readiness_scores.readiness_score` is NULLABLE and partial rows are normal —
the mid-workout quick check-in (api/v1/workouts/reshape.py
`_persist_checkin_gauges`) upserts a row carrying only the gauges it collected
and never computes a score. Three separate aggregations summed the raw column:

  * scores_endpoints.py  POST /scores/fitness/calculate  -> TypeError -> HTTP 500
  * scores_endpoints.py  GET  /scores/overview           -> TypeError swallowed
                                                            by `except Exception`
                                                            -> silent data loss
  * workouts/crud_background_tasks.py post-workout recalc -> TypeError swallowed
                                                            by the function's own
                                                            outer `except Exception`
                                                            -> recalculate_user_
                                                            fitness_score() did
                                                            NOTHING for any user
                                                            who ever used the
                                                            check-in. Fixed —
                                                            routed through the
                                                            same chokepoint as
                                                            the other two sites.

Part 1 pins the behaviour of the shared chokepoint
(`api.v1.scores_endpoints.average_readiness_rows`).
Part 2 is a baseline-diff sweep over the whole backend that fails both when a
NEW unfiltered aggregation appears and when a KNOWN_OPEN one is fixed without
updating this list — so the class cannot silently regrow.
"""
import ast
import os

import pytest

from api.v1.scores_endpoints import (
    NEUTRAL_READINESS_BASELINE,
    average_readiness_rows,
    readiness_window_from_response,
)

BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# ---------------------------------------------------------------------------
# Part 1 — the chokepoint's contract
# ---------------------------------------------------------------------------

class TestReadinessChokepoint:
    def test_unscored_rows_are_skipped_not_summed(self):
        """The exact production shape: scored days plus quick check-ins.

        Real rows: 94/58/78/70 from user d54e6652 plus the two unscored rows
        user 9335b664 wrote on 2026-07-28/29.
        """
        rows = [
            {"readiness_score": 94},
            {"readiness_score": 58},
            {"readiness_score": 78},
            {"readiness_score": 70},
            {"readiness_score": None},
            {"readiness_score": None},
        ]
        window = average_readiness_rows(rows)
        assert window.average == 75.0
        assert window.scored_rows == 4
        assert window.unscored_rows == 2
        assert window.has_signal is True

    def test_all_rows_unscored_is_an_explicit_no_signal_state(self):
        """User 9335b664's real 7-day window: two rows, both unscored."""
        window = average_readiness_rows([
            {"readiness_score": None},
            {"readiness_score": None},
        ])
        assert window.average is None
        assert window.has_signal is False
        assert window.scored_rows == 0
        # The count is what distinguishes "checked in but unscored" from
        # "never checked in" — it must not be lost.
        assert window.unscored_rows == 2

    def test_empty_window_is_distinguishable_from_unscored_window(self):
        window = average_readiness_rows([])
        assert window.average is None
        assert window.has_signal is False
        assert window.scored_rows == 0
        assert window.unscored_rows == 0

    def test_a_zero_score_is_real_data_not_missing_data(self):
        """0 is a legitimate readiness score; only None means 'no score'."""
        window = average_readiness_rows([{"readiness_score": 0}, {"readiness_score": 0}])
        assert window.average == 0.0
        assert window.has_signal is True
        assert window.scored_rows == 2

    def test_none_response_object_is_handled(self):
        """maybe_single()/failed queries hand back None, not a response."""
        assert readiness_window_from_response(None).average is None
        assert average_readiness_rows(None).average is None

    def test_neutral_baseline_is_the_scale_midpoint(self):
        assert NEUTRAL_READINESS_BASELINE == 50


# ---------------------------------------------------------------------------
# Part 2 — backend-wide sweep for unfiltered readiness aggregations
# ---------------------------------------------------------------------------

# Files whose aggregation is still unfiltered. This set must SHRINK to empty.
# All three known sites (see module docstring) are now routed through the
# chokepoint, so this is empty — it stays here as the shape the gate expects
# if a new site is ever discovered.
KNOWN_OPEN = set()

# The chokepoint itself is allowed to read the raw column.
CHOKEPOINT_FUNCTIONS = {"average_readiness_rows"}


def _extracts_readiness(node: ast.AST) -> bool:
    """True for `x["readiness_score"]` / `x.get("readiness_score")`."""
    if isinstance(node, ast.Subscript):
        s = node.slice
        return isinstance(s, ast.Constant) and s.value == "readiness_score"
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
        return (
            node.func.attr == "get"
            and bool(node.args)
            and isinstance(node.args[0], ast.Constant)
            and node.args[0].value == "readiness_score"
        )
    return False


def _guards_none(comp: ast.comprehension) -> bool:
    """True when the comprehension filters the extracted value at all."""
    for cond in comp.ifs:
        for sub in ast.walk(cond):
            if _extracts_readiness(sub):
                return True
    return False


def _unfiltered_readiness_comprehensions(tree: ast.AST):
    """Yield line numbers of comprehensions that collect raw readiness_score
    with no filter — the shape that feeds `sum()` a None."""
    chokepoint_lines = set()
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name in CHOKEPOINT_FUNCTIONS:
            chokepoint_lines.update(range(node.lineno, (node.end_lineno or node.lineno) + 1))

    for node in ast.walk(tree):
        if not isinstance(node, (ast.ListComp, ast.GeneratorExp, ast.SetComp)):
            continue
        if node.lineno in chokepoint_lines:
            continue
        if not _extracts_readiness(node.elt):
            continue
        if any(_guards_none(c) for c in node.generators):
            continue
        yield node.lineno


def _iter_backend_python_files():
    skip_dirs = {".venv", ".venv312", "__pycache__", "node_modules", ".git", "tests"}
    for dirpath, dirnames, filenames in os.walk(BACKEND_ROOT):
        dirnames[:] = [d for d in dirnames if d not in skip_dirs]
        for name in filenames:
            if name.endswith(".py"):
                full = os.path.join(dirpath, name)
                yield os.path.relpath(full, BACKEND_ROOT), full


def test_no_unfiltered_readiness_aggregation_outside_the_chokepoint():
    offenders = {}
    for rel, full in _iter_backend_python_files():
        try:
            tree = ast.parse(open(full, encoding="utf-8").read(), filename=full)
        except SyntaxError:
            continue
        lines = sorted(_unfiltered_readiness_comprehensions(tree))
        if lines:
            offenders[rel] = lines

    found = set(offenders)
    new = found - KNOWN_OPEN
    assert not new, (
        "New unfiltered readiness_score aggregation(s) — readiness_score is "
        "NULLABLE, sum() will raise TypeError. Route it through "
        "api.v1.scores_endpoints.average_readiness_rows: "
        + ", ".join(f"{f}:{offenders[f]}" for f in sorted(new))
    )
    fixed = KNOWN_OPEN - found
    assert not fixed, (
        "These files no longer aggregate readiness_score unfiltered — remove "
        "them from KNOWN_OPEN so the gate stays honest: " + ", ".join(sorted(fixed))
    )


def test_scores_endpoints_has_no_unfiltered_readiness_aggregation():
    """The two sites register row 9 was reopened for."""
    path = os.path.join(BACKEND_ROOT, "api/v1/scores_endpoints.py")
    tree = ast.parse(open(path, encoding="utf-8").read(), filename=path)
    assert list(_unfiltered_readiness_comprehensions(tree)) == []


def test_crud_background_tasks_has_no_unfiltered_readiness_aggregation():
    """The third site (E2E row 9, instance 3): the post-workout background
    fitness recalc used to `sum([r["readiness_score"] for r in rows])` raw,
    which raised on the first NULL-scored check-in row and was swallowed by
    `recalculate_user_fitness_score`'s own outer `except Exception` — the
    whole recalc silently did nothing for any user who ever used the
    mid-workout check-in.
    """
    path = os.path.join(BACKEND_ROOT, "api/v1/workouts/crud_background_tasks.py")
    tree = ast.parse(open(path, encoding="utf-8").read(), filename=path)
    assert list(_unfiltered_readiness_comprehensions(tree)) == []


def test_crud_background_tasks_routes_through_the_chokepoint():
    """Pins the fix itself, not just the absence of the old pattern — the
    function must call `readiness_window_from_response` and fall back to
    `NEUTRAL_READINESS_BASELINE`, mirroring the two scores_endpoints.py sites.
    """
    import inspect
    import api.v1.workouts.crud_background_tasks as cbt

    src = inspect.getsource(cbt.recalculate_user_fitness_score)
    assert "readiness_window_from_response" in src
    assert "NEUTRAL_READINESS_BASELINE" in src


def test_overview_readiness_average_is_not_wrapped_in_a_blanket_except():
    """A swallowed TypeError is worse than a 500 — it invents 'no data'."""
    path = os.path.join(BACKEND_ROOT, "api/v1/scores_endpoints.py")
    tree = ast.parse(open(path, encoding="utf-8").read(), filename=path)
    overview = next(
        n for n in ast.walk(tree)
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))
        and n.name == "get_scores_overview"
    )
    for node in ast.walk(overview):
        if not isinstance(node, ast.Try):
            continue
        body_calls = {
            sub.func.id
            for sub in ast.walk(ast.Module(body=node.body, type_ignores=[]))
            if isinstance(sub, ast.Call) and isinstance(sub.func, ast.Name)
        }
        assert "readiness_window_from_response" not in body_calls, (
            "The 7-day readiness average is back inside a try/except at line "
            f"{node.lineno}; 'not enough data' must be an explicit state."
        )
