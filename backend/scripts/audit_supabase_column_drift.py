#!/usr/bin/env python3
"""
Supabase column-drift audit — regression gate for phantom-column selects.

Explicit `.table("X").select("col, col, ...")` strings rot as the schema
evolves; nothing type-checks them against Postgres, and ONE phantom column
poisons the ENTIRE query (PostgREST 42703) — including the valid columns.
This has bitten twice:
  - 2026-05-18: daily_activity.active_minutes / sleep_hours, fasting_records.energy_level
  - 2026-07-04: users.coach_id 500'd the trial-coach cron; 14 more files
    selected users.first_name / display_name / workout_days / health_conditions /
    daily_calories / goal etc. — all silently degrading behind try/except.

  - 2026-07-21: food_score_enrichment wrote a phantom `food_logs.rating`
    key; PGRST204 rejected the WHOLE update, silently dropping all 13
    enrichment fields, so those rows kept a NULL health_score.

What it does: statically extracts, from every .py under backend/,
  1. `.table("<name>").select("<cols>")` column lists,
  2. `.insert(...)/.update(...)/.upsert(...)` payload KEYS (inline literal
     dicts, lists of dicts, and variable-bound payloads whose literal keys
     resolve statically — including one built by a same-file helper), and
  3. first-arg column names of `.eq/.lt/.order/…` filters,
and validates each identifier against `schema_columns_snapshot.json`
(a checked-in dump of information_schema).

Usage:
    python scripts/audit_supabase_column_drift.py            # report everything
    python scripts/audit_supabase_column_drift.py --check    # GATE: exit 1 only
                                                             # on NEW drift
    python scripts/audit_supabase_column_drift.py --strict   # exit 1 on ANY drift
    python scripts/audit_supabase_column_drift.py --update-baseline
    python scripts/audit_supabase_column_drift.py --refresh  # regen snapshot
                                                             # (needs DATABASE_URL + psycopg2)

BASELINE
--------
The write-payload pass (added 2026-07-21) surfaced a large backlog of
pre-existing violations that predate it. A gate that always exits 1 cannot
answer the only question it exists for — "did MY change add a violation?" — so
known-existing violations live in `column_drift_baseline.json` (keyed by
file|table|column, NOT line number, so they survive unrelated edits).

  * `--check` (the CLAUDE.md-documented gate) prints EVERYTHING but exits 1
    only when a violation is absent from the baseline. `--new-only` is an
    explicit alias for those semantics.
  * `--strict` exits 1 on every violation, baselined or not — use it when
    working the backlog down.
  * `--update-baseline` rewrites the baseline from the current tree. Do this
    deliberately (after triaging), never to silence a fresh failure.

Baseline entries that no longer reproduce are reported as stale; they never
fail the gate, they are just a nudge to re-run `--update-baseline`.

Conservative by design — it under-reports rather than false-positives:
  - embedded-resource groups `rel(...)` are stripped (their cols belong to
    the embedded table, not the selected one)
  - `*`, aggregates, `alias:col`, `col::cast`, `col->json` ops are reduced
    to the base column or skipped
  - tables not in the snapshot (dynamic names, non-public schema) are skipped
  - write payloads whose keys can't be resolved statically (loop-variable
    keys, `**spread`, dicts from imported helpers) contribute no keys
  - payload variables are resolved FLOW-SENSITIVELY (last binding wins), so
    rebinding a name to an unrelated dict does not leak the old dict's keys
    into the write; see _ScopeWalker.

Known residual imprecision (both directions are documented, not hidden):
  - `if/else` branches are JOINED by union at the merge point. A key set on
    only one branch IS reported, because that branch really can reach the
    write. This is path-sound, not a false positive.
  - loop bodies are analysed twice, so a key added on iteration N is visible
    to a write on iteration N+1; further loop-carried depth is missed.
  - only same-file, single-level helper returns are resolved.
"""
import argparse
import json
import re
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent
SNAPSHOT = Path(__file__).resolve().parent / "schema_columns_snapshot.json"

# .table("X") ... .select("a, b" \n "c, d") — captures table name + the
# full argument blob of adjacent string literals (Python implicit concat).
SELECT_RE = re.compile(
    r'\.table\(\s*["\']([A-Za-z0-9_]+)["\']\s*\)'       # table name
    # chain up to .select( without crossing into another statement/table call
    r'(?:(?!\.table\(|\.execute\(|\.insert\(|\.update\(|\.upsert\(|\.delete\().)*?'
    r'\.select\(\s*'
    r'((?:"[^"]*"|\'[^\']*\'|\s|\\|\+)+)'               # string-literal blob
    r'\)',
    re.DOTALL,
)

SKIP_DIRS = {"venv", "node_modules", "__pycache__", "migrations", "scripts"}


def _skip(parts) -> bool:
    return any(d in SKIP_DIRS or d.startswith(".venv") for d in parts)


def _strip_embedded(sel: str) -> str:
    """Remove embedded-resource groups like `notification_preferences(...)`."""
    out, depth = [], 0
    for ch in sel:
        if ch == "(":
            depth += 1
            continue
        if ch == ")":
            depth = max(0, depth - 1)
            continue
        if depth == 0:
            out.append(ch)
    # the token immediately before a '(' was the embedded rel name — drop it
    cleaned = "".join(out)
    return cleaned


def _columns_from_select(sel_blob: str):
    parts = re.findall(r'["\']([^"\']*)["\']', sel_blob)
    sel = "".join(parts)
    # remember rel-name prefixes so we can drop them post-strip
    rel_names = set(re.findall(r"([A-Za-z0-9_!]+)\s*\(", sel))
    sel = _strip_embedded(sel)
    for tok in sel.split(","):
        tok = tok.strip()
        if not tok or tok == "*":
            continue
        if tok in rel_names or tok.split("!")[0] in rel_names:
            continue
        tok = tok.split(":")[-1]        # alias:col → col
        tok = tok.split("::")[0]        # col::cast → col
        tok = tok.split("->")[0]        # col->json → col
        tok = tok.strip()
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", tok):
            continue                    # computed/aggregate — skip
        yield tok


def _table_of_call(node, env=None):
    """Walk a builder chain (ast.Call/Attribute) back to .table("name").

    `env` maps variable names to table names (from `q = db.table("x")...`
    assignments) so chains built incrementally through a variable —
    `query = query.order(...)` — still resolve.
    """
    import ast
    cur = node
    for _ in range(40):  # chains are finite; guard against cycles
        if isinstance(cur, ast.Call):
            f = cur.func
            if (
                isinstance(f, ast.Attribute)
                and f.attr == "table"
                and cur.args
                and isinstance(cur.args[0], ast.Constant)
                and isinstance(cur.args[0].value, str)
            ):
                return cur.args[0].value
            cur = f
        elif isinstance(cur, ast.Attribute):
            cur = cur.value
        elif isinstance(cur, ast.Name) and env is not None:
            return env.get(cur.id)
        else:
            return None
    return None


_AMBIGUOUS = object()


def _var_table_env(tree):
    """Map variable names to the table their query chain was built from.

    Module-wide, conservative: a name assigned from chains of two DIFFERENT
    tables anywhere in the file becomes ambiguous and is dropped (no false
    positives from reused builder variable names).
    """
    import ast
    env: dict = {}
    for _ in range(3):  # fixpoint: `q = q.order(...)` needs env from pass 1
        for node in ast.walk(tree):
            if not isinstance(node, ast.Assign) or len(node.targets) != 1:
                continue
            tgt = node.targets[0]
            if not isinstance(tgt, ast.Name):
                continue
            table = _table_of_call(node.value, {
                k: v for k, v in env.items() if v is not _AMBIGUOUS
            })
            if not table:
                continue
            prev = env.get(tgt.id)
            if prev is not None and prev is not _AMBIGUOUS and prev != table:
                env[tgt.id] = _AMBIGUOUS
            elif prev is not _AMBIGUOUS:
                env[tgt.id] = table
    return {k: v for k, v in env.items() if v is not _AMBIGUOUS}


# PostgREST filter/modifier methods whose FIRST arg is a column name.
_FILTER_METHODS = {
    "eq", "neq", "gt", "gte", "lt", "lte", "like", "ilike",
    "is_", "in_", "contains", "contained_by", "order",
}

_IDENT_RE = None  # compiled lazily in _filter_violations


def _filter_violations(src: str, path, schema: dict):
    """AST pass: column args of .eq/.lt/.order/… on chains with a known table.

    Catches drift with NO select string at all — e.g. the retention cron's
    `.table("push_nudge_log").delete().lt("created_at", …)` (42703) and
    plain literal `.table("media_jobs")` where the table itself never
    existed (PGRST205). Dotted/expression args (embedded-resource filters,
    JSON operators) are skipped.
    """
    import ast
    global _IDENT_RE
    if _IDENT_RE is None:
        _IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*$")
    out = []
    seen_unknown_tables = set()
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return out
    env = _var_table_env(tree)
    for node in ast.walk(tree):
        if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)):
            continue
        # Unknown literal table name → the table itself is drift.
        if (
            node.func.attr == "table"
            and node.args
            and isinstance(node.args[0], ast.Constant)
            and isinstance(node.args[0].value, str)
        ):
            tname = node.args[0].value
            if tname not in schema and tname not in seen_unknown_tables:
                seen_unknown_tables.add(tname)
                out.append((str(path), node.lineno, tname, "<table does not exist>"))
            continue
        if node.func.attr not in _FILTER_METHODS or not node.args:
            continue
        arg = node.args[0]
        if not (isinstance(arg, ast.Constant) and isinstance(arg.value, str)):
            continue
        col = arg.value
        if not _IDENT_RE.fullmatch(col):
            continue  # dotted embedded-resource / JSON-operator paths
        table = _table_of_call(node.func.value, env)
        if not table:
            continue
        real = schema.get(table)
        if real is None or col in real:
            continue
        out.append((str(path), node.lineno, table, f"{col} [filter]"))
    return out


# ---------------------------------------------------------------------------
# Write-payload key resolution
#
# `.update({...})` / `.insert({...})` payload KEYS are exactly as fatal as
# select strings — PostgREST rejects the ENTIRE payload on one unknown key
# (PGRST204), so a single phantom key silently drops every other column in the
# same write. 2026-07-21: food_score_enrichment.py built
# `update_payload["rating"]` on a table with no `rating` column; all ~13
# enrichment fields (health_score, inflammation_score, glycemic_load + 29
# micronutrients) were discarded on every cache-hit enrichment, behind a
# WARNING log, leaving those rows with a NULL health_score. (Scale as measured
# 2026-07-22 in production: 107 of 222 food_logs had a NULL health_score — a
# point-in-time count that drifts; see services/food_score_enrichment.py for
# the query.)
#
# Inline literal dicts alone would NOT have caught that: the payload was built
# key-by-key in a local variable inside a helper and returned to the caller
# that issued the write. So we resolve, per scope:
#   * `p = {"a": 1}`                      → literal dict assignment (REBINDS)
#   * `p["b"] = ...`                      → constant-string subscript store
#   * `p.update({"c": 1})` / `p.setdefault("d", …)`
#   * `p = helper(...)` / `await helper(...)` where `helper` returns a dict we
#     resolved the same way (one level of interprocedural depth, same file)
# Anything unresolvable (loop-variable keys, `**spread`, dicts from imported
# helpers, comprehensions) contributes NO keys — we under-report rather than
# false-positive. Literal keys we DO see are real writes even when the dict
# also has dynamic keys, so validating them stays sound.
#
# FLOW SENSITIVITY (fixed 2026-07-22). The first cut of this resolver unioned
# every key ever stored under a variable NAME anywhere in the scope, which
# false-positived on plain rebinding:
#     d = {"some_local_cache_key": 1}; use(d)
#     d = {"user_id": 2}; db.client.table("food_logs").insert(d)
# reported food_logs.some_local_cache_key. _ScopeWalker now executes the scope's
# statements in source order carrying a name→keys state: a whole-name
# assignment REPLACES the entry (last binding wins, and rebinding to something
# unresolvable clears it), while mutations (`p["k"]=`, `p.update`,
# `p.setdefault`) ADD to it. Writes are resolved against the state as of the
# write's own position.
# ---------------------------------------------------------------------------

_WRITE_METHODS = ("insert", "update", "upsert")


def _literal_dict_keys(d) -> set:
    import ast
    return {
        k.value for k in d.keys
        if isinstance(k, ast.Constant) and isinstance(k.value, str)
    }


def _subscript_key(target):
    """Constant string key of `x["k"]`, else None (py3.8 ast.Index tolerated)."""
    import ast
    sl = target.slice
    if sl.__class__.__name__ == "Index":
        sl = getattr(sl, "value", sl)
    if isinstance(sl, ast.Constant) and isinstance(sl.value, str):
        return sl.value
    return None


def _resolve_dict_keys(node, state: dict, func_returns: dict, depth: int = 0) -> set:
    """Best-effort set of literal string keys the expression's dict holds.

    `state` is the flow-sensitive name→keys map as of this expression.
    """
    import ast
    if node is None or depth > 4:
        return set()
    if isinstance(node, ast.Dict):
        return _literal_dict_keys(node)
    if isinstance(node, ast.Name):
        return set(state.get(node.id, ()))
    if isinstance(node, ast.Await):
        return _resolve_dict_keys(node.value, state, func_returns, depth + 1)
    if isinstance(node, ast.IfExp):
        # Either branch can execute — a phantom key in either is a real bug.
        return (
            _resolve_dict_keys(node.body, state, func_returns, depth + 1)
            | _resolve_dict_keys(node.orelse, state, func_returns, depth + 1)
        )
    if isinstance(node, ast.BoolOp):  # `payload or {}`
        keys = set()
        for v in node.values:
            keys |= _resolve_dict_keys(v, state, func_returns, depth + 1)
        return keys
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
        return set(func_returns.get(node.func.id, ()))
    return set()


def _copy_state(state: dict) -> dict:
    return {k: set(v) for k, v in state.items()}


def _merge_states(a: dict, b: dict) -> dict:
    """Dataflow join for an if/else merge point: union per name.

    Path-sound: a key bound on only one branch really can reach a write below
    the merge, so reporting it is a true positive, not a false one.
    """
    out = {}
    for k in set(a) | set(b):
        out[k] = set(a.get(k, ())) | set(b.get(k, ()))
    return out


class _ScopeWalker:
    """Flow-sensitive, single-scope interpreter for dict-payload key sets.

    Walks the statements of ONE scope (module body, function body, or class
    body) in source order, maintaining `state: name -> set(literal keys)`.
    Nested function/class scopes are skipped — they are walked separately.

    Collects:
      * `self.writes`  — (node, table, keys) for every .insert/.update/.upsert
      * `self.returns` — union of key sets returned by this scope
    """

    def __init__(self, env: dict, schema: dict, func_returns: dict):
        self.env = env
        self.schema = schema
        self.func_returns = func_returns
        self.writes = []
        self.returns = set()

    # -- driver ------------------------------------------------------------
    def run(self, body):
        self._block(body, {})

    def _block(self, stmts, state):
        for st in stmts or []:
            self._stmt(st, state)

    # -- statements --------------------------------------------------------
    def _stmt(self, st, state):
        import ast
        if isinstance(st, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            return  # its own scope

        if isinstance(st, ast.If):
            self._exprs(st.test, state)
            s1, s2 = _copy_state(state), _copy_state(state)
            self._block(st.body, s1)
            self._block(st.orelse, s2)
            merged = _merge_states(s1, s2)
            state.clear()
            state.update(merged)
            return

        if isinstance(st, (ast.For, ast.AsyncFor)):
            self._exprs(st.iter, state)
            # Two passes so a key added late in the body is visible to a write
            # earlier in the body on the next iteration. The loop target itself
            # is a dynamic name; assigning it clears any stale entry.
            if isinstance(st.target, ast.Name):
                state.pop(st.target.id, None)
            for _ in range(2):
                self._block(st.body, state)
            self._block(st.orelse, state)
            return

        if isinstance(st, ast.While):
            self._exprs(st.test, state)
            for _ in range(2):
                self._block(st.body, state)
            self._block(st.orelse, state)
            return

        if isinstance(st, ast.Try) or st.__class__.__name__ == "TryStar":
            # An except body really can observe bindings made before the raise,
            # so run them in sequence on the same state rather than branching.
            self._block(st.body, state)
            for h in st.handlers:
                self._block(h.body, state)
            self._block(getattr(st, "orelse", []), state)
            self._block(getattr(st, "finalbody", []), state)
            return

        if isinstance(st, (ast.With, ast.AsyncWith)):
            for item in st.items:
                self._exprs(item.context_expr, state)
            self._block(st.body, state)
            return

        if isinstance(st, ast.Return):
            if st.value is not None:
                self._exprs(st.value, state)
                self.returns |= self._resolve(st.value, state)
            return

        if isinstance(st, (ast.Assign, ast.AnnAssign, ast.AugAssign)):
            value = getattr(st, "value", None)
            if value is not None:
                self._exprs(value, state)     # RHS evaluates BEFORE the bind
            targets = st.targets if isinstance(st, ast.Assign) else [st.target]
            for t in targets:
                self._exprs_target(t, state)
                if isinstance(t, ast.Name):
                    if value is None:
                        continue              # bare annotation `p: Dict`
                    if isinstance(st, ast.AugAssign):
                        state.setdefault(t.id, set()).update(self._resolve(value, state))
                    else:
                        # LAST BINDING WINS — an unresolvable RHS clears the
                        # name rather than leaking the previous dict's keys.
                        state[t.id] = self._resolve(value, state)
                elif isinstance(t, ast.Subscript) and isinstance(t.value, ast.Name):
                    key = _subscript_key(t)
                    if key is not None:
                        state.setdefault(t.value.id, set()).add(key)
            return

        # Everything else (Expr, Raise, Assert, Delete, Match, …): just look
        # for writes / dict mutations inside its expressions.
        for child in ast.iter_child_nodes(st):
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                continue
            if isinstance(child, ast.stmt):
                self._stmt(child, state)
            else:
                self._exprs(child, state)

    def _exprs_target(self, t, state):
        """Subscript targets can hold expressions (`p[f(x)] = …`)."""
        import ast
        if isinstance(t, ast.Subscript):
            self._exprs(t.slice, state)

    # -- expressions -------------------------------------------------------
    def _exprs(self, node, state):
        """Scan one expression tree for DB writes and dict mutations."""
        import ast
        if node is None:
            return
        for n in ast.walk(node):
            if not (isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute) and n.args):
                continue
            meth = n.func.attr
            table = (
                _table_of_call(n.func.value, self.env)
                if meth in _WRITE_METHODS else None
            )
            if table is not None and self.schema.get(table) is not None:
                self.writes.append((n, table, self._resolve_payload(n.args[0], state)))
                continue
            if table is not None:
                continue  # known query builder, unknown table — not a dict
            # Not a DB write → dict mutation on a local payload variable.
            if not isinstance(n.func.value, ast.Name):
                continue
            recv = n.func.value.id
            if recv in self.env:
                continue  # that name is a query builder, not a dict
            if meth == "update" and isinstance(n.args[0], ast.Dict):
                state.setdefault(recv, set()).update(_literal_dict_keys(n.args[0]))
            elif (
                meth == "setdefault"
                and isinstance(n.args[0], ast.Constant)
                and isinstance(n.args[0].value, str)
            ):
                state.setdefault(recv, set()).add(n.args[0].value)

    def _resolve(self, node, state):
        return _resolve_dict_keys(node, state, self.func_returns)

    def _resolve_payload(self, arg, state):
        """Payload may be a dict, a variable, or a list/tuple of dicts."""
        import ast
        if isinstance(arg, (ast.List, ast.Tuple)):
            keys = set()
            for e in arg.elts:
                keys |= self._resolve(e, state)
            return keys
        return self._resolve(arg, state)


def _inline_literal_writes(tree, env: dict, schema: dict):
    """Belt-and-suspenders: inline literal-dict payloads ANYWHERE in the file.

    Uses ast.walk, so it is immune to any scope the statement walker does not
    model (class bodies, match arms, future syntax). Inline literals are
    unambiguous, so this can never false-positive; it exists purely to keep the
    pre-flow-sensitivity coverage of the original ast.walk resolver.
    """
    import ast
    out = []
    for n in ast.walk(tree):
        if not (
            isinstance(n, ast.Call)
            and isinstance(n.func, ast.Attribute)
            and n.func.attr in _WRITE_METHODS
            and n.args
        ):
            continue
        table = _table_of_call(n.func.value, env)
        if not table or schema.get(table) is None:
            continue
        arg = n.args[0]
        keys = set()
        if isinstance(arg, ast.Dict):
            keys = _literal_dict_keys(arg)
        elif isinstance(arg, (ast.List, ast.Tuple)):
            for e in arg.elts:
                if isinstance(e, ast.Dict):
                    keys |= _literal_dict_keys(e)
        if keys:
            out.append((n, table, keys))
    return out


def _write_violations(src: str, path, schema: dict):
    """AST pass: payload keys handed to .insert(…)/.update(…)/.upsert(…).

    Covers inline literal dicts, lists of literal dicts, and variable-bound
    payloads (including ones returned by a same-file helper) whose keys can be
    resolved statically, resolved flow-sensitively per scope. Unresolvable
    payloads yield no keys — skipped, never guessed.
    """
    import ast
    out = []
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return out
    env = _var_table_env(tree)
    # ClassDef bodies are scopes too — a `.insert({...})` at class-body level
    # was invisible to the first cut of this pass.
    scopes = [tree] + [
        n for n in ast.walk(tree)
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef))
    ]

    # Fixpoint: a scope's writes depend on helper return keys, which depend on
    # the helper scopes' own walks.
    func_returns: dict = {}
    walkers: dict = {}
    for _ in range(3):
        walkers = {}
        for s in scopes:
            w = _ScopeWalker(env, schema, func_returns)
            w.run(s.body)
            walkers[id(s)] = w
        next_returns: dict = {}
        ambiguous = set()
        for s in scopes:
            if not isinstance(s, (ast.FunctionDef, ast.AsyncFunctionDef)):
                continue
            ks = walkers[id(s)].returns
            if s.name in next_returns and next_returns[s.name] != ks:
                ambiguous.add(s.name)   # overloaded name in this file — unsafe
            next_returns[s.name] = ks
        for name in ambiguous:
            next_returns.pop(name, None)
        if next_returns == func_returns:
            func_returns = next_returns
            break
        func_returns = next_returns

    found = []
    for s in scopes:
        found.extend(walkers[id(s)].writes)
    found.extend(_inline_literal_writes(tree, env, schema))

    seen = set()
    for node, table, keys in found:
        real_set = set(schema[table])
        for k in sorted(keys - real_set):
            sig = (node.lineno, table, k)
            if sig in seen:
                continue
            seen.add(sig)
            out.append((str(path), node.lineno, table, f"{k} [write]"))
    return out


def audit(schema: dict):
    violations = []
    for py in sorted(BACKEND.rglob("*.py")):
        if _skip(py.parts):
            continue
        try:
            src = py.read_text()
        except Exception:
            continue
        rel = py.relative_to(BACKEND)
        for m in SELECT_RE.finditer(src):
            table, blob = m.group(1), m.group(2)
            real = schema.get(table)
            if real is None:
                continue  # dynamic/unknown table — out of scope
            real_set = set(real)
            line = src[: m.start()].count("\n") + 1
            for col in _columns_from_select(blob):
                if col not in real_set:
                    violations.append((str(rel), line, table, col))
        violations.extend(_write_violations(src, rel, schema))
        violations.extend(_filter_violations(src, rel, schema))
    return violations


def refresh():
    import os
    dsn = os.environ.get("DATABASE_URL", "").replace("+asyncpg", "")
    if not dsn:
        print("DATABASE_URL not set — cannot refresh snapshot", file=sys.stderr)
        return 2
    import psycopg2  # noqa: deferred import — only needed for --refresh
    conn = psycopg2.connect(dsn)
    cur = conn.cursor()
    # Tables + views come from information_schema; MATERIALIZED views do not
    # appear there (exercise_library_cleaned, leaderboard_*) — union pg_class.
    cur.execute(
        "SELECT table_name, json_agg(column_name ORDER BY column_name) "
        "FROM information_schema.columns WHERE table_schema='public' "
        "GROUP BY table_name "
        "UNION ALL "
        "SELECT c.relname, json_agg(a.attname ORDER BY a.attname) "
        "FROM pg_class c "
        "JOIN pg_namespace n ON n.oid = c.relnamespace "
        "JOIN pg_attribute a ON a.attrelid = c.oid "
        "WHERE n.nspname='public' AND c.relkind='m' "
        "AND a.attnum > 0 AND NOT a.attisdropped "
        "GROUP BY c.relname"
    )
    snap = {t: cols for t, cols in cur.fetchall()}
    SNAPSHOT.write_text(json.dumps(snap, indent=1, sort_keys=True))
    print(f"snapshot refreshed: {len(snap)} tables → {SNAPSHOT}")
    return 0


# ---------------------------------------------------------------------------
# Baseline of known-existing violations
#
# Keyed by file|table|column — deliberately NOT line number, so an unrelated
# edit that shifts lines does not resurrect a baselined entry as "new".
# ---------------------------------------------------------------------------

BASELINE = Path(__file__).resolve().parent / "column_drift_baseline.json"

_BASELINE_DOC = (
    "Known-existing phantom-column violations, accepted as a backlog so that "
    "`--check` can answer 'did MY change add one?'. Keyed file|table|column "
    "(no line numbers). Regenerate deliberately with --update-baseline after "
    "triaging; never to silence a fresh failure. --strict ignores this file."
)


def _sig(v) -> str:
    """Stable identity of a violation: file|table|column (no line number)."""
    f, _line, table, col = v
    return f"{f}|{table}|{col}"


def _load_baseline() -> set:
    if not BASELINE.exists():
        return set()
    try:
        data = json.loads(BASELINE.read_text())
    except Exception as e:  # noqa: BLE001
        print(f"⚠️  baseline unreadable ({e}) — treating every violation as new",
              file=sys.stderr)
        return set()
    return set(data.get("entries", []))


def _write_baseline(violations) -> int:
    import datetime
    entries = sorted({_sig(v) for v in violations})
    BASELINE.write_text(json.dumps({
        "description": _BASELINE_DOC,
        "generated": datetime.date.today().isoformat(),
        "count": len(entries),
        "entries": entries,
    }, indent=1) + "\n")
    print(f"baseline written: {len(entries)} known violation(s) → {BASELINE}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true",
                    help="GATE: print everything, exit 1 only on violations "
                         "absent from column_drift_baseline.json")
    ap.add_argument("--new-only", action="store_true",
                    help="explicit alias for --check semantics")
    ap.add_argument("--strict", action="store_true",
                    help="exit 1 on ANY violation, baselined or not")
    ap.add_argument("--update-baseline", action="store_true",
                    help="rewrite column_drift_baseline.json from the current tree")
    ap.add_argument("--refresh", action="store_true",
                    help="regen schema snapshot from DATABASE_URL")
    args = ap.parse_args()

    if args.refresh:
        sys.exit(refresh())

    schema = json.loads(SNAPSHOT.read_text())
    violations = audit(schema)

    if args.update_baseline:
        sys.exit(_write_baseline(violations))

    baseline = _load_baseline()
    new = [v for v in violations if _sig(v) not in baseline]
    known = [v for v in violations if _sig(v) in baseline]
    stale = sorted(baseline - {_sig(v) for v in violations})

    def _dump(label, rows):
        print(f"{label} ({len(rows)}):")
        for f, line, table, col in rows:
            print(f"  {f}:{line} — {table}.{col} does not exist")

    if not violations:
        print("✅ no phantom columns in .select() strings, write payloads, or filters")
    else:
        if new:
            _dump("❌ NEW phantom-column reference(s)", new)
        if known:
            label = ("❌ BASELINED phantom-column reference(s)" if args.strict
                     else "⚠️  BASELINED phantom-column reference(s) — pre-existing, "
                          "not failing this gate")
            _dump(label, known)
        if not new:
            print("✅ no NEW phantom columns introduced")

    if stale:
        print(f"ℹ️  {len(stale)} baseline entr(y/ies) no longer reproduce — "
              f"re-run --update-baseline to prune:")
        for s in stale:
            print(f"  {s}")

    gate_new = args.check or args.new_only
    if args.strict and violations:
        sys.exit(1)
    if gate_new and new:
        sys.exit(1)


if __name__ == "__main__":
    main()
