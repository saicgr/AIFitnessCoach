#!/usr/bin/env python3
"""Fail the build when one FastAPI route is permanently shadowed by another.

WHY THIS GATE EXISTS
--------------------
Starlette matches routes in DECLARATION ORDER and takes the first full match.
A parameterised route declared early swallows every later route that has a
literal segment in the same position:

    @router.get("/food-logs/{user_id}/{log_id}")   # declared first
    @router.get("/food-logs/{log_id}/edits")       # UNREACHABLE

`GET /food-logs/<uuid>/edits` binds user_id=<uuid>, log_id="edits" and runs the
WRONG handler. Two ways that then fails, both seen in production:

  * the handler's ownership check compares the food-log id to the caller's user
    id, never matches, and returns 403 forever (photo-URL refresh + meal edit
    history were dead in the app this way);
  * or the literal segment reaches Postgres as an id and raises 22P02,
    "invalid input syntax for type uuid: \"assignments\"" — a 500.
    (Sentry PYTHON-FASTAPI-64, -5Y, -6S.)

Nothing in FastAPI warns about this; the route simply never runs.

FIX: declare the specific/literal route ABOVE the parameterised one.

Usage:
    python backend/scripts/audit_route_shadowing.py --check   # exit 1 on any finding
    python backend/scripts/audit_route_shadowing.py           # report only
"""
from __future__ import annotations

import argparse
import ast
import re
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent
API_DIR = BACKEND / "api"
HTTP_METHODS = {"get", "post", "put", "patch", "delete", "head", "options"}

# A literal path segment sitting where another route takes a parameter is the
# whole signal, so a placeholder that cannot collide with real literals is fine.
PARAM_PLACEHOLDER = "\x00param\x00"


class Route:
    __slots__ = ("method", "path", "handler", "lineno", "router", "file")

    def __init__(self, method, path, handler, lineno, router, file):
        self.method = method
        self.path = path
        self.handler = handler
        self.lineno = lineno
        self.router = router
        self.file = file

    @property
    def segments(self) -> list[str]:
        return [s for s in self.path.strip("/").split("/") if s != ""]

    def as_regex(self) -> re.Pattern:
        parts = [
            "[^/]+" if (s.startswith("{") and s.endswith("}")) else re.escape(s)
            for s in self.segments
        ]
        return re.compile("^/" + "/".join(parts) + "/?$")

    def concrete(self) -> str:
        """This route's path with its own params filled by a placeholder."""
        return "/" + "/".join(
            PARAM_PLACEHOLDER if (s.startswith("{") and s.endswith("}")) else s
            for s in self.segments
        )

    def has_literal_where(self, other: "Route") -> bool:
        """True if self has a literal segment where `other` has a parameter."""
        if len(self.segments) != len(other.segments):
            return False
        for mine, theirs in zip(self.segments, other.segments):
            mine_param = mine.startswith("{")
            theirs_param = theirs.startswith("{")
            if theirs_param and not mine_param:
                return True
        return False


def collect_routes(path: Path) -> list[Route]:
    try:
        tree = ast.parse(path.read_text(encoding="utf-8"))
    except (SyntaxError, UnicodeDecodeError):
        return []

    routes: list[Route] = []
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        for dec in node.decorator_list:
            if not isinstance(dec, ast.Call):
                continue
            fn = dec.func
            if not (isinstance(fn, ast.Attribute) and fn.attr in HTTP_METHODS):
                continue
            # `@router.get(...)` / `@some_router.get(...)`
            if not isinstance(fn.value, ast.Name):
                continue
            if not dec.args or not isinstance(dec.args[0], ast.Constant):
                continue
            route_path = dec.args[0].value
            if not isinstance(route_path, str):
                continue
            routes.append(
                Route(fn.attr.upper(), route_path, node.name, node.lineno, fn.value.id, path)
            )
    routes.sort(key=lambda r: r.lineno)  # declaration order
    return routes


def find_shadowed(routes: list[Route]) -> list[tuple[Route, Route]]:
    """Return (shadowed, shadowed_by) pairs.

    Only routes on the SAME router object and SAME method can shadow, since a
    different router may be mounted under a different prefix.
    """
    findings = []
    for i, later in enumerate(routes):
        for earlier in routes[:i]:
            if earlier.method != later.method or earlier.router != later.router:
                continue
            # Only a genuine specificity inversion counts: `later` must carry a
            # literal exactly where `earlier` accepts anything.
            if not later.has_literal_where(earlier):
                continue
            if earlier.as_regex().match(later.concrete()):
                findings.append((later, earlier))
                break
    return findings


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="exit 1 if any route is shadowed")
    args = ap.parse_args()

    if not API_DIR.exists():
        print(f"error: {API_DIR} not found", file=sys.stderr)
        return 2

    all_findings = []
    files = 0
    total_routes = 0
    for py in sorted(API_DIR.rglob("*.py")):
        if "__pycache__" in py.parts:
            continue
        routes = collect_routes(py)
        if not routes:
            continue
        files += 1
        total_routes += len(routes)
        for shadowed, by in find_shadowed(routes):
            all_findings.append((shadowed, by))

    print(f"Scanned {total_routes} routes across {files} router files under {API_DIR.relative_to(BACKEND.parent)}/")

    if not all_findings:
        print("\n✅ No shadowed routes.")
        return 0

    print(f"\n❌ {len(all_findings)} unreachable route(s) — a parameterised route declared earlier swallows them:\n")
    for shadowed, by in all_findings:
        rel = shadowed.file.relative_to(BACKEND.parent)
        print(f"  {rel}:{shadowed.lineno}")
        print(f"      {shadowed.method} {shadowed.path}  ->  {shadowed.handler}()  IS UNREACHABLE")
        print(f"      shadowed by {by.method} {by.path} ({by.handler}, line {by.lineno})")
        print(f"      fix: declare {shadowed.handler}() above {by.handler}()")
        print()

    return 1 if args.check else 0


if __name__ == "__main__":
    sys.exit(main())
