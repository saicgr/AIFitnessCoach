"""Guard: no blocking supabase ``.execute()`` on hot-path async handlers.

WHY
---
``supabase-py``'s ``.execute()`` is synchronous. Inside an ``async def`` route it
blocks the uvicorn event loop for the whole DB round-trip and serializes every
in-flight request. Measured on deployed prod: a single user's Home-open fan-out
stalled ``/health`` p95 16x and dragged endpoints to 7-10s — including endpoints
that *were* already offloaded, because one blocking neighbour in the same burst
freezes the shared loop.

THE INVARIANT
-------------
Every offload wraps the call in a lambda — ``run_db(lambda: q.execute())``,
``gather_db(lambda: ...)``, or ``loop.run_in_executor(None, lambda: q.execute())``.
So the rule is simple and AST-robust:

    A ``.execute()`` call inside an ``async def`` is a violation IFF it is not
    nested inside a ``lambda``.

This test enumerates the app-open hot-path routers and fails on any violation,
with ``file:line``. It is the durable canary that stops the event-loop-blocking
regression from being silently re-introduced (and re-discovered) every few
sessions. Add new hot-path routers to ``HOT_PATH_FILES`` as they appear in the
Home/Workouts/Nutrition/Coach fan-out.

Runnable standalone: ``python tests/test_no_blocking_execute_on_hot_paths.py``
(prints violations); also collected by pytest as ``test_hot_paths_no_blocking_execute``.
"""
from __future__ import annotations

import ast
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent

# Routers fired (roughly concurrently) on app open. Keep in sync with the
# fan-out burst in scripts/perf_probe.py::fanout_endpoints.
HOT_PATH_FILES = [
    "api/v1/workouts/today.py",
    "api/v1/home/bootstrap.py",
    "api/v1/stats.py",
    "api/v1/xp_endpoints.py",
    "api/v1/xp.py",
    "api/v1/insights.py",
    "api/v1/consistency_endpoints.py",
    "api/v1/consistency.py",
    "api/v1/neat.py",
    "api/v1/neat_compat.py",
    "api/v1/habits_endpoints.py",
    "api/v1/scores.py",
    "api/v1/scores_endpoints.py",
    "api/v1/hydration.py",
]


# Blocking DB calls: raw ``.execute()`` plus sync helpers that do their own
# Supabase round-trip (``db.get_user``, ``resolve_timezone``,
# ``get_week_starts_sunday``). Any of these bare in an async handler blocks the
# event loop. Keep in sync with scripts/offload_codemod.py.
_BLOCKING_ATTR_CALLS = {"execute", "get_user"}
_BLOCKING_NAME_CALLS = {"resolve_timezone", "get_week_starts_sunday"}


def _is_blocking_call(n: ast.AST) -> bool:
    if not isinstance(n, ast.Call):
        return False
    f = n.func
    if isinstance(f, ast.Attribute) and f.attr in _BLOCKING_ATTR_CALLS:
        return True
    if isinstance(f, ast.Name) and f.id in _BLOCKING_NAME_CALLS:
        return True
    return False


def _violations_in_file(path: Path) -> list[tuple[int, str]]:
    """Return (lineno, snippet) for every blocking DB call that sits inside an
    ``async def`` but NOT inside a ``lambda``."""
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    found: list[tuple[int, str]] = []

    class AsyncDefVisitor(ast.NodeVisitor):
        def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef):
            self._scan_async_body(node)
            # also descend into nested defs/classes
            self.generic_visit(node)

        def _scan_async_body(self, async_node: ast.AsyncFunctionDef):
            # Walk every node under the async def, tracking lambda-nesting.
            def walk(n, in_lambda: bool, in_nested_sync_def: bool):
                is_lambda = isinstance(n, ast.Lambda)
                # A nested *sync* def inside the async def runs wherever it's
                # called; if that's via run_db it's fine — don't flag its body.
                is_nested_sync_def = isinstance(n, (ast.FunctionDef,))
                _in_lambda = in_lambda or is_lambda
                _in_nested = in_nested_sync_def or is_nested_sync_def
                if _is_blocking_call(n) and not _in_lambda and not _in_nested:
                    found.append((n.lineno, ast.get_source_segment(
                        path.read_text(encoding="utf-8"), n) or "blocking-db-call"))
                for child in ast.iter_child_nodes(n):
                    walk(child, _in_lambda, _in_nested)

            for stmt in async_node.body:
                walk(stmt, in_lambda=False, in_nested_sync_def=False)

    AsyncDefVisitor().visit(tree)
    return found


def collect_violations() -> dict[str, list[tuple[int, str]]]:
    out: dict[str, list[tuple[int, str]]] = {}
    for rel in HOT_PATH_FILES:
        p = BACKEND / rel
        if not p.exists():
            continue
        v = _violations_in_file(p)
        if v:
            out[rel] = v
    return out


def test_hot_paths_no_blocking_execute():
    violations = collect_violations()
    if violations:
        lines = ["Blocking .execute() inside async handler (wrap in run_db/gather_db):"]
        for rel, items in violations.items():
            for lineno, snippet in items:
                snip = snippet.replace("\n", " ")[:90]
                lines.append(f"  {rel}:{lineno}  {snip}")
        raise AssertionError("\n".join(lines))


if __name__ == "__main__":
    v = collect_violations()
    if not v:
        print("✅ No blocking .execute() in async handlers on hot-path routers.")
    else:
        total = sum(len(x) for x in v.values())
        print(f"❌ {total} blocking .execute() call(s) found:")
        for rel, items in v.items():
            print(f"\n{rel}:")
            for lineno, snippet in items:
                print(f"  L{lineno}: {snippet.splitlines()[0][:100]}")
        raise SystemExit(1)
