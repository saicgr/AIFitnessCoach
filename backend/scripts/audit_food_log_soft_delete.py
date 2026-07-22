#!/usr/bin/env python3
"""
food_logs soft-delete read audit — regression gate for deleted meals leaking
back into every nutrition-derived surface.

A deleted meal is not removed: `DELETE /food-logs/{id}` stamps `deleted_at`
(migration 255) and the row stays. A read that forgets
`.is_("deleted_at", "null")` therefore keeps counting food the user threw away.
A 2026-07 sweep found 36 of 74 `food_logs` reads missing it — deleted meals
were inflating the health/nutrition scores, the logging streak, the weekly
progress email, push nudges, wrapped and XP.

The fix is a chokepoint, not 36 patches: `core/db/soft_delete.py` installs a
guard on the singleton PostgREST client (`SupabaseManager.client`) that appends
`deleted_at is null` to every `.select()` on `food_logs`. This script guards
the ways a read can still slip past it:

  1. THE GUARD ITSELF IS GONE. If nobody installs it in core/supabase_client.py
     (refactor, merge accident), all 74 reads leak again silently. Both the
     registry entry AND the install call are checked by PARSING THE AST, not by
     grepping text — soft_delete.py documents `.table("food_logs")` in its own
     docstring, so a substring test passes even when the live registry entry is
     deleted, and a substring test also passes on a commented-out install call.

  2. A READ OPTS OUT AND THEN FORGETS. Naming `deleted_at` in the projection is
     the guard's documented opt-out (it means "I have thought about soft
     deletes"), so `select("...,deleted_at")` without a `deleted_at` filter is a
     leak the guard will not catch. One site is legitimately in this shape and
     is allowlisted below: the idempotent DELETE, which must see tombstones to
     answer "already soft-deleted?".

  3. A READ ON A CLIENT THE GUARD NEVER TOUCHED. Anything that builds its own
     client with `create_client(...)` (scripts/) bypasses the chokepoint and
     must filter explicitly.

KNOWN GAPS (reported, but cannot be gated by static text scanning):

  * NON-LITERAL PROJECTIONS. The runtime guard tests the RESOLVED value handed
    to `.select(...)`, but this scanner only sees source text. A projection held
    in a variable/constant — `COLS = "id, deleted_at"; .select(COLS)` — would opt
    OUT of the runtime guard (COLS names deleted_at) while a naive text scan sees
    only `COLS` and reports nothing. Every `food_logs` read whose projection is
    NOT a plain string literal is REPORTED (so it is never silently skipped
    again). It is a warning, not a gate failure: the common case — a computed
    column list that does NOT name deleted_at (e.g. home_insights' RDA columns) —
    is correctly filtered by the runtime guard, and failing the gate there would
    red-flag a legitimate read. Verify each reported site does not resolve to a
    projection naming deleted_at; if it might, inline the column list so the
    scanner and the guard agree.

  * `.rpc()` CALLS. A Postgres function reads food_logs SERVER-SIDE, bypassing
    BOTH the runtime guard AND this scanner — the SQL inside the function is the
    only place the `deleted_at is null` filter can live, and no static scan of
    Python can verify it. Known food_logs-reading RPCs are listed and reported as
    a reminder; whether each one filters correctly must be verified in its SQL
    definition.

Usage:
    python scripts/audit_food_log_soft_delete.py            # report
    python scripts/audit_food_log_soft_delete.py --check    # exit 1 on any leak

Run --check after adding any backend `food_logs` read.

Conservative by design: in a file that calls `create_client(...)` at all, every
unfiltered `food_logs` read is flagged — the scan does not trace which client
a given read used, and an explicit filter is always correct.
"""
import argparse
import ast
import re
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent
SKIP_DIRS = {"node_modules", "__pycache__", "migrations", "tests"}

TABLE = "food_logs"
COLUMN = "deleted_at"

# Reads that deliberately want the soft-deleted rows. Keyed by
# (path relative to backend/, a distinctive substring of the chain) so a new
# unfiltered read in the same file is still flagged.
INTENTIONAL_TOMBSTONE_READS = {
    (
        "api/v1/nutrition/food_logs.py",
        'select("id, user_id, deleted_at")',
    ): "idempotent DELETE — must see the tombstone to answer 'already deleted?'",
}

# Postgres functions known to read food_logs server-side. They bypass the
# runtime guard AND this scanner (the filter can only live in the SQL body), so
# they are reported as a standing reminder — NOT gated, because no static scan
# of Python can confirm the SQL filters `deleted_at`. Add a name here when a new
# RPC starts reading food_logs so it stays on the radar.
FOOD_LOG_READING_RPCS = {
    "get_food_patterns",
    "get_symptom_tag_correlations",
    "get_top_foods_by_metric",
    "get_digestion_patterns",
}

CHOKEPOINT = BACKEND / "core" / "supabase_client.py"
GUARD_MODULE = BACKEND / "core" / "db" / "soft_delete.py"


def _skip(path: Path) -> bool:
    return any(p in SKIP_DIRS or p.startswith(".venv") for p in path.parts)


def _nows(s: str) -> str:
    """Collapse ALL whitespace away for tolerant substring matching.

    The allowlist marker and the scanned chain are normalised the SAME way so a
    reformat of an allowlisted read (black wrapping the `.select(` across lines,
    adding a space after `(`) can't turn a legitimate opt-out into a gate
    failure. Applied to both sides — never one only.
    """
    return re.sub(r"\s+", "", s)


def _soft_deleted_tables_from_registry(guard_src: str) -> set:
    """Return the KEYS of the live SOFT_DELETED_TABLES dict, parsed via AST.

    A plain `'"food_logs"' in guard_src` grep can't tell the live registry from
    the module's own docstring — soft_delete.py documents `.table("food_logs")`
    in prose, so the substring test passes even after the registry entry is
    deleted (proven by fault injection). Parsing the actual assignment node is
    the only test that fails when the entry is truly gone. Handles both a plain
    `NAME = {...}` and an annotated `NAME: Dict[...] = {...}` assignment.
    """
    try:
        tree = ast.parse(guard_src)
    except SyntaxError:
        return set()

    def _keys(dict_node: ast.Dict) -> set:
        out = set()
        for k in dict_node.keys:
            if isinstance(k, ast.Constant) and isinstance(k.value, str):
                out.add(k.value)
        return out

    for node in ast.walk(tree):
        if (
            isinstance(node, ast.Assign)
            and any(isinstance(t, ast.Name) and t.id == "SOFT_DELETED_TABLES" for t in node.targets)
            and isinstance(node.value, ast.Dict)
        ):
            return _keys(node.value)
        if (
            isinstance(node, ast.AnnAssign)
            and isinstance(node.target, ast.Name)
            and node.target.id == "SOFT_DELETED_TABLES"
            and isinstance(node.value, ast.Dict)
        ):
            return _keys(node.value)
    return set()


def _calls_install_guard(choke_src: str) -> bool:
    """True iff supabase_client.py contains a LIVE install_soft_delete_guard(...)
    call, detected via AST.

    A bare `"install_soft_delete_guard(" in src` grep passes on a commented-out
    or string-embedded call (proven by fault injection: replacing the call with
    `# install_soft_delete_guard(...)` still passed). AST never sees comments, so
    a disabled call correctly fails this check.
    """
    try:
        tree = ast.parse(choke_src)
    except SyntaxError:
        return False
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            func = node.func
            if isinstance(func, ast.Name) and func.id == "install_soft_delete_guard":
                return True
            if isinstance(func, ast.Attribute) and func.attr == "install_soft_delete_guard":
                return True
    return False


def _chains(src: str):
    """Yield (line_no, chain_text) for every `table("food_logs")` expression.

    The chain runs to the terminating `.execute(` (the builder is lazy, so that
    is where the query is finally sent); a 2500-char window is far longer than
    any chain in this codebase and keeps the scan a single pass.
    """
    for m in re.finditer(r'table\(\s*["\']%s["\']\s*\)' % TABLE, src):
        line_start = src.rfind("\n", 0, m.start()) + 1
        if src[line_start:m.start()].lstrip().startswith("#"):
            continue  # a commented-out example, not a live query
        tail = src[m.end():m.end() + 2500]
        end = tail.find(".execute(")
        chain = tail[:end + 9] if end != -1 else tail[:400]
        yield src[:m.start()].count("\n") + 1, chain


def _is_read(chain: str) -> bool:
    """A read is a chain whose first operation is `.select(`."""
    ops = [(chain.find(op), op) for op in (".select(", ".insert(", ".update(", ".upsert(", ".delete(")]
    ops = [(i, op) for i, op in ops if i != -1]
    return bool(ops) and min(ops)[1] == ".select("


def _projection(chain: str) -> str:
    """The literal text handed to `.select(...)`."""
    m = re.search(r"\.select\(", chain)
    if not m:
        return ""
    depth, out = 0, []
    for ch in chain[m.end() - 1:]:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                break
        out.append(ch)
    return "".join(out)


def _projection_is_literal(projection: str) -> bool:
    """True if the projection is a string literal (or empty → `select()`/`*`).

    The runtime guard opts a read out when the RESOLVED projection names
    `deleted_at`; this scanner only sees source. A projection with no quote at
    all is a variable/constant/splat (`.select(COLS)`, `.select(*cols)`) whose
    value the scanner can't resolve — so it can't tell whether it silently opts
    out of the guard. Only a projection containing a quote (a literal, possibly
    an f-string) is verifiable. Empty projection is `select()` → PostgREST `*`,
    which the guard filters, so that is fine.
    """
    stripped = projection.strip()
    if not stripped:
        return True
    return '"' in projection or "'" in projection


def _filters_soft_delete(chain: str) -> bool:
    return bool(re.search(r'(is_|filter|eq|neq)\(\s*["\']%s["\']' % COLUMN, chain))


def rpc_gap_sites():
    """Report (rel, line, rpc_name) for every call to a known food_logs-reading
    Postgres function. Informational — see FOOD_LOG_READING_RPCS."""
    sites = []
    pattern = re.compile(r'\.rpc\(\s*["\'](%s)["\']' % "|".join(re.escape(n) for n in sorted(FOOD_LOG_READING_RPCS)))
    for path in sorted(BACKEND.rglob("*.py")):
        if _skip(path) or path.resolve() == Path(__file__).resolve():
            continue
        src = path.read_text(errors="ignore")
        for m in pattern.finditer(src):
            line = src[:m.start()].count("\n") + 1
            sites.append((str(path.relative_to(BACKEND)), line, m.group(1)))
    return sites


def audit():
    """Return (violations, warnings).

    violations gate --check (they are unambiguous leaks or a torn-down guard);
    warnings are surfaced every run but never fail the gate (non-literal
    projections the scanner can't resolve — usually guard-protected, see module
    docstring).
    """
    violations = []
    warnings = []

    # 1. The chokepoint must still be wired — both the registry entry and the
    #    install call, checked structurally (AST), never by substring grep.
    if not GUARD_MODULE.exists():
        violations.append((
            "core/db/soft_delete.py", 0,
            "guard module is MISSING — every food_logs read leaks soft-deleted meals",
        ))
    else:
        guard_src = GUARD_MODULE.read_text(errors="ignore")
        if TABLE not in _soft_deleted_tables_from_registry(guard_src):
            violations.append((
                "core/db/soft_delete.py", 0,
                f"{TABLE} is no longer a key of the SOFT_DELETED_TABLES registry — "
                "its reads are unguarded",
            ))
    choke_src = CHOKEPOINT.read_text(errors="ignore") if CHOKEPOINT.exists() else ""
    if not _calls_install_guard(choke_src):
        violations.append((
            "core/supabase_client.py", 0,
            "install_soft_delete_guard() is not called on the main client — "
            "the guard is dead code and every read leaks again",
        ))

    # 2 + 3. Per-read checks.
    # The guard module and this script both quote the chained call in prose;
    # scanning them would flag their own documentation.
    self_referential = {GUARD_MODULE.resolve(), Path(__file__).resolve()}
    for path in sorted(BACKEND.rglob("*.py")):
        if _skip(path) or path.resolve() in self_referential:
            continue
        src = path.read_text(errors="ignore")
        if f'table("{TABLE}")' not in src and f"table('{TABLE}')" not in src:
            continue
        rel = str(path.relative_to(BACKEND))
        own_client = "create_client(" in src
        for line, chain in _chains(src):
            if not _is_read(chain):
                continue
            if _filters_soft_delete(chain):
                continue
            projection = _projection(chain)
            allowed = any(
                rel == a_rel and _nows(a_marker) in _nows(chain)
                for (a_rel, a_marker) in INTENTIONAL_TOMBSTONE_READS
            )
            if allowed:
                continue
            if not _projection_is_literal(projection):
                # The projection is a variable/constant/splat — the scanner
                # can't see whether it names deleted_at (the guard's opt-out).
                # A warning, not a violation: the usual case is a computed
                # column list that does NOT name deleted_at, which the runtime
                # guard filters correctly — gating it would red-flag a
                # legitimate read. Surfaced so it is never silently skipped.
                warnings.append((
                    rel, line,
                    "projection is not a string literal — the scanner cannot "
                    "verify it doesn't name deleted_at (the guard's opt-out); "
                    "verify it resolves without deleted_at, or inline the column "
                    "list",
                ))
                continue
            if COLUMN in projection:
                violations.append((
                    rel, line,
                    f"selects {COLUMN} (opting out of the guard) but never filters it — "
                    "soft-deleted meals reach this read",
                ))
            elif own_client:
                violations.append((
                    rel, line,
                    "reads food_logs on a client built by create_client() — the "
                    f"chokepoint guard never sees it; add .is_(\"{COLUMN}\", \"null\")",
                ))
    return violations, warnings


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true", help="exit 1 when a leak is found")
    args = ap.parse_args()

    violations, warnings = audit()

    # Known gaps (reported every run, never gated — unverifiable from static
    # Python, see module docstring):
    #   * RPC sites that read food_logs server-side (filter lives in the SQL).
    #   * non-literal projections the scanner can't resolve.
    rpc_sites = rpc_gap_sites()
    if rpc_sites:
        print("ℹ️  food_logs is also read server-side by these RPCs — verify each "
              "filters deleted_at in its SQL (guard + scanner can't):")
        for rel, line, name in rpc_sites:
            print(f"  {rel}:{line}  rpc(\"{name}\")")
        print()
    if warnings:
        print("⚠️  computed (non-literal) projections the scanner can't resolve — "
              "guard-protected unless the value names deleted_at; verify each:")
        for rel, line, msg in warnings:
            print(f"  {rel}:{line}\n      {msg}")
        print()

    if not violations:
        print("✅ food_logs soft-delete: chokepoint guard installed, no unguarded reads")
        return 0

    print(f"❌ {len(violations)} soft-delete leak(s):\n")
    for rel, line, msg in violations:
        where = f"{rel}:{line}" if line else rel
        print(f"  {where}\n      {msg}")
    return 1 if args.check else 0


if __name__ == "__main__":
    sys.exit(main())
