"""Every `background_tasks.add_task(SYMBOL, ...)` target must be a bound name.

Why this exists
---------------
2026-07-30 production 500: `POST /api/v1/scores/readiness` raised

    NameError: name 'generate_ai_readiness_insight' is not defined

`api/v1/scores.py` scheduled that function as a background task, but only ever
imported `router` from `scores_endpoints` — the symbol was never bound. Nothing
caught it:

  * it is not an ImportError, so the module imports cleanly and the app boots;
  * the route registers fine, so `/openapi.json` and smoke tests pass;
  * it only raises when a user actually submits a readiness check-in — and by
    then the readiness row has ALREADY been written, so the user sees a failure
    for data that was in fact saved.

That is the whole class this test locks down: a background-task callable that
looks fine at import time and 500s at request time.

How it works
------------
Pure AST — no imports, no DB, no env. For every `*.add_task(...)` call in
`backend/api/`, resolve the first positional argument when it is a bare `Name`
and assert it is bound in one of:

  * the enclosing function scopes (params, assignments, for/with/except targets,
    walrus, comprehensions, nested defs)
  * module scope (imports, defs, classes, assignments)
  * names re-exported by a `from X import *` (resolved by parsing X's own AST,
    honouring `__all__` when present)
  * builtins

Attribute targets (`self.foo`, `svc.bar`) and lambdas are skipped — they cannot
be resolved statically and are not the failure mode above.
"""

from __future__ import annotations

import ast
import builtins
from pathlib import Path
from typing import Iterator

API_ROOT = Path(__file__).resolve().parent.parent / "api"
BACKEND_ROOT = Path(__file__).resolve().parent.parent


def _bound_names(node: ast.AST) -> set[str]:
    """Names bound directly in this scope (not descending into nested scopes)."""
    bound: set[str] = set()

    def add_target(t: ast.AST) -> None:
        if isinstance(t, ast.Name):
            bound.add(t.id)
        elif isinstance(t, (ast.Tuple, ast.List)):
            for elt in t.elts:
                add_target(elt)
        elif isinstance(t, ast.Starred):
            add_target(t.value)

    # Function parameters
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda)):
        a = node.args
        for arg in [*a.posonlyargs, *a.args, *a.kwonlyargs]:
            bound.add(arg.arg)
        if a.vararg:
            bound.add(a.vararg.arg)
        if a.kwarg:
            bound.add(a.kwarg.arg)

    body = node.body if isinstance(node.body, list) else [node.body]

    for child in body:
        for sub in ast.walk(child):
            # Do not descend into nested scopes for *their* locals, but the
            # nested def/class name itself IS bound here.
            if isinstance(sub, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                bound.add(sub.name)
            elif isinstance(sub, ast.Import):
                for alias in sub.names:
                    bound.add(alias.asname or alias.name.split(".")[0])
            elif isinstance(sub, ast.ImportFrom):
                for alias in sub.names:
                    if alias.name != "*":
                        bound.add(alias.asname or alias.name)
            elif isinstance(sub, ast.Assign):
                for t in sub.targets:
                    add_target(t)
            elif isinstance(sub, (ast.AnnAssign, ast.AugAssign)):
                add_target(sub.target)
            elif isinstance(sub, ast.NamedExpr):
                add_target(sub.target)
            elif isinstance(sub, (ast.For, ast.AsyncFor)):
                add_target(sub.target)
            elif isinstance(sub, (ast.With, ast.AsyncWith)):
                for item in sub.items:
                    if item.optional_vars is not None:
                        add_target(item.optional_vars)
            elif isinstance(sub, ast.ExceptHandler):
                if sub.name:
                    bound.add(sub.name)
            elif isinstance(sub, ast.comprehension):
                add_target(sub.target)
            elif isinstance(sub, (ast.Global, ast.Nonlocal)):
                bound.update(sub.names)

    return bound


def _resolve_star_import(module_expr: str, level: int, source: Path) -> set[str]:
    """Names a `from <module> import *` would bind, resolved via that module's AST."""
    if level:  # relative import — resolve against the importing file's package
        base = source.parent
        for _ in range(level - 1):
            base = base.parent
        target = base / (module_expr.replace(".", "/") if module_expr else "")
    else:
        target = BACKEND_ROOT / module_expr.replace(".", "/")

    candidates = [target.with_suffix(".py"), target / "__init__.py"]
    path = next((c for c in candidates if c.is_file()), None)
    if path is None:
        # Third-party or unresolvable — be permissive rather than emit a false
        # positive. The regression we care about is first-party.
        return set()

    try:
        tree = ast.parse(path.read_text(encoding="utf-8"))
    except (SyntaxError, UnicodeDecodeError):
        return set()

    # An explicit __all__ wins, exactly as the interpreter does.
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(
            isinstance(t, ast.Name) and t.id == "__all__" for t in node.targets
        ):
            if isinstance(node.value, (ast.List, ast.Tuple)):
                return {
                    e.value
                    for e in node.value.elts
                    if isinstance(e, ast.Constant) and isinstance(e.value, str)
                }

    # No __all__: every module-level name not starting with underscore.
    return {n for n in _bound_names(tree) if not n.startswith("_")}


def _iter_add_task_calls(tree: ast.AST) -> Iterator[tuple[ast.Call, list[ast.AST]]]:
    """Yield (call_node, enclosing_scope_stack) for each `*.add_task(...)`."""

    def walk(node: ast.AST, stack: list[ast.AST]) -> Iterator[tuple[ast.Call, list[ast.AST]]]:
        for child in ast.iter_child_nodes(node):
            if isinstance(child, ast.Call):
                func = child.func
                if isinstance(func, ast.Attribute) and func.attr == "add_task":
                    yield child, list(stack)
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda, ast.ClassDef)):
                yield from walk(child, stack + [child])
            else:
                yield from walk(child, stack)

    yield from walk(tree, [tree])


def test_background_task_targets_are_bound():
    unbound: list[str] = []
    checked = 0

    for path in sorted(API_ROOT.rglob("*.py")):
        try:
            tree = ast.parse(path.read_text(encoding="utf-8"))
        except (SyntaxError, UnicodeDecodeError):
            continue

        module_names = _bound_names(tree)
        for node in tree.body:
            if isinstance(node, ast.ImportFrom) and any(a.name == "*" for a in node.names):
                module_names |= _resolve_star_import(node.module or "", node.level or 0, path)

        for call, stack in _iter_add_task_calls(tree):
            if not call.args:
                continue
            target = call.args[0]
            if not isinstance(target, ast.Name):
                continue  # self.foo / svc.bar / lambda — not statically resolvable
            checked += 1

            visible = set(module_names) | set(dir(builtins))
            for scope in stack[1:]:  # stack[0] is the module, already covered
                visible |= _bound_names(scope)

            if target.id not in visible:
                rel = path.relative_to(BACKEND_ROOT)
                unbound.append(f"{rel}:{target.lineno} -> add_task({target.id}, ...)")

    assert checked > 0, "found no resolvable add_task targets — the AST walk is broken"
    assert not unbound, (
        "background_tasks.add_task() scheduled with unbound name(s). These raise "
        "NameError at REQUEST time, not import time — often after a DB write has "
        "already landed. Import the symbol in the calling module:\n  "
        + "\n  ".join(unbound)
    )
