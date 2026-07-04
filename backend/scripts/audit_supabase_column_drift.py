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

What it does: statically extracts every `.table("<name>").select("<cols>")`
in backend/ and validates each bare column identifier against
`schema_columns_snapshot.json` (a checked-in dump of information_schema).

Usage:
    python scripts/audit_supabase_column_drift.py            # report
    python scripts/audit_supabase_column_drift.py --check    # exit 1 on drift
    python scripts/audit_supabase_column_drift.py --refresh  # regen snapshot
                                                             # (needs DATABASE_URL + psycopg2)

Run --check after adding any backend Supabase query or applying a migration
that renames/drops columns. Refresh the snapshot after applying migrations
that ADD columns the code selects.

Conservative by design (no false positives):
  - embedded-resource groups `rel(...)` are stripped (their cols belong to
    the embedded table, not the selected one)
  - `*`, aggregates, `alias:col`, `col::cast`, `col->json` ops are reduced
    to the base column or skipped
  - tables not in the snapshot (dynamic names, non-public schema) are skipped
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

SKIP_DIRS = {".venv", "venv", "node_modules", "__pycache__", "migrations", "scripts"}


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


def _table_of_call(node):
    """Walk a builder chain (ast.Call/Attribute) back to .table("name")."""
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
        else:
            return None
    return None


def _write_violations(src: str, path, schema: dict):
    """AST pass: literal dict keys in .insert({...})/.update({...})/.upsert.

    Only inline literal dicts are checkable statically — dicts built in a
    variable are skipped (no false positives, best-effort coverage).
    """
    import ast
    out = []
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return out
    for node in ast.walk(tree):
        if not (
            isinstance(node, ast.Call)
            and isinstance(node.func, ast.Attribute)
            and node.func.attr in ("insert", "update", "upsert")
            and node.args
        ):
            continue
        table = _table_of_call(node.func.value)
        if not table:
            continue
        real = schema.get(table)
        if real is None:
            continue
        arg = node.args[0]
        dicts = [arg] if isinstance(arg, ast.Dict) else (
            [e for e in arg.elts if isinstance(e, ast.Dict)]
            if isinstance(arg, (ast.List, ast.Tuple)) else []
        )
        real_set = set(real)
        for d in dicts:
            for k in d.keys:
                if (
                    isinstance(k, ast.Constant)
                    and isinstance(k.value, str)
                    and k.value not in real_set
                ):
                    out.append((str(path), node.lineno, table, f"{k.value} [write]"))
    return out


def audit(schema: dict):
    violations = []
    for py in sorted(BACKEND.rglob("*.py")):
        if any(d in py.parts for d in SKIP_DIRS):
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
    cur.execute(
        "SELECT table_name, json_agg(column_name ORDER BY column_name) "
        "FROM information_schema.columns WHERE table_schema='public' "
        "GROUP BY table_name"
    )
    snap = {t: cols for t, cols in cur.fetchall()}
    SNAPSHOT.write_text(json.dumps(snap, indent=1, sort_keys=True))
    print(f"snapshot refreshed: {len(snap)} tables → {SNAPSHOT}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true", help="exit 1 on drift")
    ap.add_argument("--refresh", action="store_true", help="regen snapshot from DATABASE_URL")
    args = ap.parse_args()

    if args.refresh:
        sys.exit(refresh())

    schema = json.loads(SNAPSHOT.read_text())
    violations = audit(schema)
    if violations:
        print(f"❌ {len(violations)} phantom-column select(s):")
        for f, line, table, col in violations:
            print(f"  {f}:{line} — {table}.{col} does not exist")
        sys.exit(1 if args.check else 0)
    print("✅ no phantom columns in .select() strings")


if __name__ == "__main__":
    main()
