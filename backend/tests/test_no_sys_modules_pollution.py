"""Guard: a test file may not leave ``sys.modules`` stubbed for another test.

WHY
---
Two test files used to install bare ``ModuleType`` stubs over real packages at
MODULE IMPORT time and never restore them::

    sys.modules["api.v1.nutrition.preferences"] = prefs_stub   # only _active_meal_types
    sys.modules["api.v1.scores"] = _scores                     # only _flatten_logs_for_strength

That is invisible in isolation — the polluter's own tests pass, and the victim's
own tests pass. It only bites in a full run: once the polluter is collected,
every LATER test that patches by string resolves against the stub::

    mock.patch("api.v1.nutrition.preferences.get_supabase_db", ...)
    AttributeError: <module 'api.v1.nutrition.preferences'> does not have the
                    attribute 'get_supabase_db'

That single defect accounted for 20 failures in a full backend run and survived
for a long time precisely because it is order-dependent: it never reproduces
when you run the failing file by itself, which is the first thing anyone tries.

THE INVARIANT
-------------
Stubbing ``sys.modules`` is legitimate — it is how these files test a module in
isolation from its heavy imports. What is NOT legitimate is doing it without
putting the original entries back. So the rule is:

    A test module that ASSIGNS into ``sys.modules`` must also define a
    ``teardown_module`` (or use a fixture/``monkeypatch``) that restores it.

``monkeypatch.setitem(sys.modules, ...)`` and ``mock.patch.dict(sys.modules, ...)``
are already self-restoring and are therefore always fine.

Runnable standalone: ``python tests/test_no_sys_modules_pollution.py``
(prints violations); also collected by pytest.
"""
from __future__ import annotations

import ast
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent

# Self-restoring APIs — assignment through these is inherently safe.
_SAFE_CALLS = frozenset({"setitem", "dict"})


def _is_sys_modules_sub(node: ast.AST) -> bool:
    """True for a ``sys.modules[...]`` subscript."""
    if not isinstance(node, ast.Subscript):
        return False
    value = node.value
    return (
        isinstance(value, ast.Attribute)
        and value.attr == "modules"
        and isinstance(value.value, ast.Name)
        and value.value.id == "sys"
    )


def _guarded_lines(tree: ast.AST) -> set[int]:
    """Lines inside an ``if <name> not in sys.modules:`` guard.

    A guarded insert cannot shadow anything — it only fills a key that is
    absent — so it is not a pollution risk. This is the standard namespace
    package shim (``ModuleType`` with a real ``__path__``).
    """
    safe: set[int] = set()
    for node in ast.walk(tree):
        if not isinstance(node, ast.If):
            continue
        test = node.test
        if (
            isinstance(test, ast.Compare)
            and len(test.ops) == 1
            and isinstance(test.ops[0], ast.NotIn)
            and _is_sys_modules_attr(test.comparators[0])
        ):
            for child in ast.walk(node):
                if hasattr(child, "lineno"):
                    safe.add(child.lineno)
    return safe


def _is_sys_modules_attr(node: ast.AST) -> bool:
    return (
        isinstance(node, ast.Attribute)
        and node.attr == "modules"
        and isinstance(node.value, ast.Name)
        and node.value.id == "sys"
    )


def _assigns_sys_modules(tree: ast.AST) -> list[int]:
    """Line numbers of raw, UNGUARDED ``sys.modules[...] = ...`` assignments."""
    guarded = _guarded_lines(tree)
    hits: list[int] = []
    for node in ast.walk(tree):
        if not isinstance(node, (ast.Assign, ast.AnnAssign)):
            continue
        if node.lineno in guarded:
            continue
        targets = node.targets if isinstance(node, ast.Assign) else [node.target]
        if any(_is_sys_modules_sub(target) for target in targets):
            hits.append(node.lineno)
    return hits


def _has_restore(tree: ast.AST) -> bool:
    """True if the module puts ``sys.modules`` back itself.

    Three accepted shapes, all genuinely restoring:
      * a ``teardown*`` hook,
      * a ``try/finally`` whose ``finally`` writes ``sys.modules`` back
        (better than teardown — it restores immediately, not after the
        module's whole test run),
      * self-restoring APIs: ``monkeypatch.setitem`` / ``mock.patch.dict``.
    """
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.name.startswith("teardown"):
                return True
        if isinstance(node, ast.Try) and node.finalbody:
            for child in ast.walk(ast.Module(body=node.finalbody, type_ignores=[])):
                if _is_sys_modules_sub(child) or (
                    isinstance(child, ast.Call)
                    and isinstance(child.func, ast.Attribute)
                    and child.func.attr == "pop"
                    and _is_sys_modules_attr(child.func.value)
                ):
                    return True
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
            if node.func.attr in _SAFE_CALLS:
                for arg in node.args:
                    if _is_sys_modules_attr(arg):
                        return True
    return False


def find_violations() -> list[tuple[str, int]]:
    violations: list[tuple[str, int]] = []
    for path in sorted(TESTS_DIR.rglob("test_*.py")):
        if path.name == Path(__file__).name:
            continue
        try:
            tree = ast.parse(path.read_text(encoding="utf-8"))
        except SyntaxError:
            continue
        assigns = _assigns_sys_modules(tree)
        if assigns and not _has_restore(tree):
            rel = path.relative_to(TESTS_DIR.parent).as_posix()
            violations.extend((rel, line) for line in assigns)
    return violations


def test_no_test_file_leaves_sys_modules_stubbed():
    violations = find_violations()
    assert not violations, (
        "A test module assigns into sys.modules without restoring it. This "
        "poisons every later mock.patch('<that module>.<attr>') in the same "
        "pytest process and only fails in a FULL run, never in isolation.\n"
        "Add a teardown_module() that puts the original entries back (or pops "
        "keys that did not exist), or use monkeypatch.setitem/mock.patch.dict "
        "which restore themselves:\n"
        + "\n".join(f"  {f}:{line}" for f, line in violations)
    )


if __name__ == "__main__":  # pragma: no cover - manual invocation
    found = find_violations()
    for f, line in found:
        print(f"{f}:{line}  sys.modules assigned without restore")
    print(f"{len(found)} violation(s)")
