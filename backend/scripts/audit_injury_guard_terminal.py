#!/usr/bin/env python3
"""Gate: the injury-safety guard must be TERMINAL on every workout path.

Background (E2E register row 84, CRIT)
--------------------------------------
`services/exercise_rag/injury_guard.enforce_injury_safety` is documented as the
terminal chokepoint applied "to the FINAL exercise list ... right before
persist". It wasn't. Three call sites appended an equipment "finisher" AFTER the
guard had already run:

  api/v1/workouts/generation_streaming.py   (avoid_names=set() — nothing avoided)
  api/v1/workouts/generation_endpoints.py   (avoid_names = injury JOINT names,
                                             matched against exercise NAMES — a
                                             structural no-op)
  services/workout_builder.py               (no guard in the file at all)

The finisher is picked by `_fetch_equipment_finisher`, which sorts the
equipment-matched compound pool alphabetically. For a user who explicitly picks
"Leg Press Machine", row 1 of that pool is **Horizontal Leg Press**, which the
safety index marks `knee_safe = FALSE`. A knee-injured user therefore received a
contraindicated movement bolted onto an otherwise-clean workout.

The invariant this gate enforces
--------------------------------
Anything that APPENDS exercises to a workout must be followed, inside the same
function, by an injury screen — either `filter_injury_unsafe` (screens just the
appended candidates) or a re-run of `enforce_injury_safety`. Ordering discipline
alone is not enough: a future call site that appends without a preceding guard
(workout_builder.py today) would silently pass an "is the guard before me?"
check.

Usage
-----
    cd backend && .venv/bin/python scripts/audit_injury_guard_terminal.py --check

Exit 0 = every appender is screened. Exit 1 = at least one unscreened appender.
"""
from __future__ import annotations

import argparse
import ast
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

BACKEND_ROOT = Path(__file__).resolve().parent.parent

# Functions that ADD exercises to a workout's exercise list. Anything added here
# must be screened afterwards. Extend this set when a new appender is written —
# that is the whole point of the gate.
APPENDERS = {
    "ensure_requested_equipment_represented",
}

# Calls that constitute a valid screen of appended exercises.
SCREENS = {
    "filter_injury_unsafe",
    "enforce_injury_safety",
    "screen_exercise_for_injury",
}

SKIP_DIR_PARTS = {"__pycache__", "node_modules", "tests", ".git", "site-packages"}


def _is_skipped(path: Path) -> bool:
    return any(
        part in SKIP_DIR_PARTS or part.startswith(".venv")
        for part in path.parts
    )


def _call_name(node: ast.Call) -> Optional[str]:
    func = node.func
    if isinstance(func, ast.Name):
        return func.id
    if isinstance(func, ast.Attribute):
        return func.attr
    return None


class _FunctionScan(ast.NodeVisitor):
    """Collect (appender_lines, screen_lines) per enclosing function."""

    def __init__(self) -> None:
        # function qualname -> (lineno, appender_lines, screen_lines)
        self.functions: Dict[str, Tuple[int, List[int], List[int]]] = {}
        self._stack: List[str] = []

    def _visit_func(self, node) -> None:
        self._stack.append(node.name)
        qual = ".".join(self._stack)
        self.functions.setdefault(qual, (node.lineno, [], []))
        self.generic_visit(node)
        self._stack.pop()

    visit_FunctionDef = _visit_func          # noqa: N815
    visit_AsyncFunctionDef = _visit_func     # noqa: N815

    def visit_Call(self, node: ast.Call) -> None:  # noqa: N802
        name = _call_name(node)
        if name and self._stack:
            qual = ".".join(self._stack)
            entry = self.functions.setdefault(qual, (node.lineno, [], []))
            if name in APPENDERS:
                entry[1].append(node.lineno)
            elif name in SCREENS:
                entry[2].append(node.lineno)
        self.generic_visit(node)


def _iter_py_files(root: Path):
    for path in sorted(root.rglob("*.py")):
        if _is_skipped(path):
            continue
        yield path


def audit(root: Path) -> List[str]:
    """Return a list of human-readable violations."""
    violations: List[str] = []
    for path in _iter_py_files(root):
        try:
            tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        except SyntaxError as exc:
            violations.append(f"{path}: could not parse ({exc})")
            continue
        scanner = _FunctionScan()
        scanner.visit(tree)
        for qual, (_def_line, appender_lines, screen_lines) in scanner.functions.items():
            for a_line in appender_lines:
                if not any(s_line > a_line for s_line in screen_lines):
                    rel = path.relative_to(BACKEND_ROOT.parent)
                    violations.append(
                        f"{rel}:{a_line}  {qual}() appends exercises "
                        f"(an APPENDERS call) with no injury screen afterwards. "
                        f"Follow it with filter_injury_unsafe(...) or re-run "
                        f"enforce_injury_safety(...) so the guard stays terminal."
                    )
    return violations


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true",
        help="Exit non-zero when an unscreened appender is found (CI mode).",
    )
    args = parser.parse_args()

    violations = audit(BACKEND_ROOT)
    if violations:
        print(f"❌ {len(violations)} unscreened exercise appender(s) — the injury "
              f"guard is NOT terminal on these paths:\n")
        for v in violations:
            print(f"  - {v}")
        print(
            "\nEvidence this is exploitable: exercise_safety_index_mat marks "
            "'Horizontal Leg Press' knee_safe=FALSE, and it is row 1 of the "
            "alphabetically-sorted 'Leg Press Machine' compound pool that "
            "_fetch_equipment_finisher selects from."
        )
        return 1 if args.check else 0

    print("✅ Every exercise appender is followed by an injury screen — the "
          "guard is terminal on all paths.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
