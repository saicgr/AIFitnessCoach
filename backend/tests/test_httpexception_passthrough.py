"""Regression test for Phase 3 fix A.

Asserts that the AI-generation try/except blocks in
`generation_endpoints.py` and `workouts_db_generation.py` re-raise
HTTPException unchanged (preserving 422 / 409) instead of wrapping it as
HTTP 500.

This is a static-source check — running the live endpoint requires a
full app + Supabase. The bug was a missing `except HTTPException: raise`
clause; this test inspects the source to confirm both fix sites are in
place.

Run: cd backend && .venv/bin/python -m pytest tests/test_httpexception_passthrough.py -v
"""
from __future__ import annotations

import ast
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _has_httpexception_passthrough(path: str) -> bool:
    """Return True if file contains an `except HTTPException: raise` immediately
    before a broad `except Exception` that wraps the inner error as
    'Failed to generate workout: ...'."""
    with open(path) as f:
        tree = ast.parse(f.read())
    for node in ast.walk(tree):
        if not isinstance(node, ast.Try):
            continue
        handlers = node.handlers
        for i, h in enumerate(handlers):
            # Look for the broad-except that raises HTTPException(500, "Failed to generate")
            if (
                isinstance(h.type, ast.Name)
                and h.type.id == "Exception"
                and any(
                    isinstance(stmt, ast.Raise)
                    and isinstance(stmt.exc, ast.Call)
                    and isinstance(stmt.exc.func, ast.Name)
                    and stmt.exc.func.id == "HTTPException"
                    for stmt in ast.walk(h)
                )
            ):
                # Check the handler immediately before it
                if i > 0:
                    prev = handlers[i - 1]
                    if (
                        isinstance(prev.type, ast.Name)
                        and prev.type.id == "HTTPException"
                        and len(prev.body) == 1
                        and isinstance(prev.body[0], ast.Raise)
                        and prev.body[0].exc is None
                    ):
                        return True
    return False


def test_generation_endpoints_has_passthrough():
    path = os.path.join(ROOT, "api/v1/workouts/generation_endpoints.py")
    assert _has_httpexception_passthrough(path), (
        "generation_endpoints.py must have `except HTTPException: raise` "
        "before the broad-except that wraps as 500. Without it, the inner "
        "EXERCISE_POOL_TOO_SMALL 422 surfaces as a 500 to clients."
    )


def test_workouts_db_generation_has_passthrough():
    path = os.path.join(ROOT, "api/v1/workouts_db_generation.py")
    assert _has_httpexception_passthrough(path), (
        "workouts_db_generation.py must have `except HTTPException: raise` "
        "before the broad-except that wraps as 500."
    )
