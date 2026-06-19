"""Codemod: wrap blocking supabase ``.execute()`` calls in async handlers.

Transforms every ``<query>.execute()`` that sits inside an ``async def`` (and is
NOT already inside a lambda or a nested sync ``def``) into:

    (await run_db(lambda: <query>.execute()))

and ensures ``from core.db_executor import run_db`` is imported.

WHY a codemod: the offload is purely mechanical but spans ~190 call sites with
multi-line query chains; a regex is unsafe and hand-edits are error-prone. AST
gives exact spans. Inline ``await`` (not a deferred lambda) means there is no
loop-variable late-binding hazard — the lambda runs synchronously in the same
iteration. ``(... )`` parens keep precedence correct for ``.data`` chaining and
bare-expression statements.

This does the run_db-per-call CORRECTNESS fix (gets every call off the event
loop, killing the cross-request stall). It deliberately does NOT do the
``gather_db`` concurrency optimization for multi-query endpoints — that's a
follow-up for the few heaviest endpoints, applied by hand.

Usage:  python scripts/offload_codemod.py api/v1/xp.py api/v1/neat.py ...
Idempotent: re-running finds nothing (wrapped calls are inside a lambda).
"""
from __future__ import annotations

import ast
import re
import sys
from pathlib import Path


# Sync helpers that issue their OWN blocking Supabase round-trip. Called bare in
# an async handler they block the event loop exactly like a raw .execute().
# (Attribute-method names like ``get_user`` match ``db.get_user(...)``.)
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


def _violation_nodes(tree: ast.AST) -> list[ast.Call]:
    """Every blocking DB call (``.execute()``, ``db.get_user``, ``resolve_timezone``,
    ``get_week_starts_sunday``) inside an async def, not inside a lambda or a
    nested sync def. Mirrors tests/test_no_blocking_execute_on_hot_paths.py."""
    nodes: list[ast.Call] = []

    class V(ast.NodeVisitor):
        def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef):
            def walk(n, in_lambda: bool, in_sync_def: bool):
                il = in_lambda or isinstance(n, ast.Lambda)
                isd = in_sync_def or isinstance(n, ast.FunctionDef)
                if _is_blocking_call(n) and not il and not isd:
                    nodes.append(n)
                for c in ast.iter_child_nodes(n):
                    walk(c, il, isd)

            for stmt in node.body:
                walk(stmt, False, False)
            self.generic_visit(node)

    V().visit(tree)
    return nodes


def _byte_line_offsets(src: bytes) -> list[int]:
    offs = [0]
    for line in src.splitlines(keepends=True):
        offs.append(offs[-1] + len(line))
    return offs


def _ensure_import(text: str) -> str:
    if re.search(r"^from core\.db_executor import .*run_db", text, re.M):
        return text
    lines = text.splitlines(keepends=True)
    # Prefer inserting right after `from core.db import ...` (all these files
    # have it); else after the first top-level import line.
    anchor = None
    for i, ln in enumerate(lines):
        if ln.startswith("from core.db import"):
            anchor = i
            break
    if anchor is None:
        for i, ln in enumerate(lines):
            if ln.startswith("import ") or ln.startswith("from "):
                anchor = i
                break
    if anchor is None:
        anchor = 0
    lines.insert(anchor + 1, "from core.db_executor import run_db, gather_db\n")
    return "".join(lines)


def codemod_file(path: Path) -> int:
    src_bytes = path.read_bytes()
    tree = ast.parse(src_bytes.decode("utf-8"), filename=str(path))
    nodes = _violation_nodes(tree)
    if not nodes:
        return 0

    line_off = _byte_line_offsets(src_bytes)
    spans = []
    for n in nodes:
        s = line_off[n.lineno - 1] + n.col_offset
        e = line_off[n.end_lineno - 1] + n.end_col_offset
        spans.append((s, e))
    # Replace from the end so earlier offsets stay valid. Spans are disjoint
    # (an .execute() chain never contains another .execute()).
    spans.sort(reverse=True)
    out = src_bytes
    for s, e in spans:
        seg = out[s:e]
        out = out[:s] + b"(await run_db(lambda: " + seg + b"))" + out[e:]

    text = _ensure_import(out.decode("utf-8"))
    path.write_text(text, encoding="utf-8")
    return len(spans)


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: offload_codemod.py <file.py> [<file.py> ...]")
        return 2
    total = 0
    for rel in argv:
        p = Path(rel)
        n = codemod_file(p)
        total += n
        print(f"{rel}: wrapped {n} blocking .execute() call(s)")
    print(f"TOTAL wrapped: {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
