#!/usr/bin/env python3
"""Gate: never `json.dumps(...)` a value into a JSONB column.

WHY THIS EXISTS
---------------
`api/v1/chat.py:_save_chat_to_db` wrote `{"context_json": json.dumps(ctx)}`
into `chat_history.context_json`, which is JSONB. PostgREST forwards the
already-serialised text, so Postgres stores a jsonb **string** (a double-encoded
scalar) instead of a jsonb object. Two silent failure modes follow:

  1. Readers that test the shape fail. The Flutter client's
     `contextJson is Map` was false, so reopening a saved conversation dropped
     every action card, chart block and agent identity (E2E register row 36).
  2. Every jsonb operator misses. `context_json->>'proactive'`,
     `context_json ? 'action_data'`, `->`, `@>` all return NULL/false on a
     jsonb string, so filters like
     `.eq("context_json->>proactive", "true")` (api/v1/home/bootstrap.py,
     api/v1/admin/observability.py) can never match such a row — usually behind
     a try/except, so nothing is ever logged.

It is a whole CLASS, not one site. A production scan on 2026-07-30 found
scalar-typed values in 20 distinct jsonb columns, e.g.
`workouts.generation_metadata` 197 string rows of 1256,
`warmup_exercise_logs.intervals_json` 13 of 13, `workouts.equipment` 6,
`exercises.tags` 2, `users.preferences` 1.

WHAT IT CHECKS
--------------
Every `.py` under `backend/` (excluding tests, venvs and vendored trees) is
parsed with `ast`. A finding is a dict literal entry whose KEY is a string that
names a JSONB column in the checked-in schema snapshot
(`scripts/schema_jsonb_columns_snapshot.json`, dumped from production
`information_schema`) and whose VALUE is a call to `json.dumps(...)` /
`dumps(...)` (optionally wrapped in an `if/else` expression, which is how the
chat.py defect was written).

BASELINE-DIFF, like scripts/audit_timezone_usage.py: the pre-existing backlog is
grandfathered in `scripts/jsonb_double_encoding_baseline.json` so this gate fails
only on NEW findings and does not block unrelated work. Clear a baseline entry by
passing the dict through instead of dumping it (and repairing the existing rows
with a migration), then `--refresh-baseline`.

USAGE
-----
    python backend/scripts/audit_jsonb_double_encoding.py --check
    python backend/scripts/audit_jsonb_double_encoding.py            # list all
    python backend/scripts/audit_jsonb_double_encoding.py --refresh-baseline
    python backend/scripts/audit_jsonb_double_encoding.py --refresh-schema
        (needs DATABASE_URL + psycopg2; re-dumps the jsonb column snapshot)

Suppress a genuinely intentional site with a trailing comment on the same line:
    "payload": json.dumps(x),  # jsonb-allowlist: column is TEXT in this table
"""
from __future__ import annotations

import argparse
import ast
import json
import os
import sys
import warnings
from pathlib import Path
from typing import Dict, List, Set, Tuple

BACKEND_ROOT = Path(__file__).resolve().parent.parent
SCHEMA_SNAPSHOT = BACKEND_ROOT / "scripts" / "schema_jsonb_columns_snapshot.json"
BASELINE_PATH = BACKEND_ROOT / "scripts" / "jsonb_double_encoding_baseline.json"

# Directories that never write to production tables.
SKIP_DIRS = {
    ".venv",
    ".venv312",
    "venv",
    "node_modules",
    "__pycache__",
    ".git",
    "tests",
    "migrations",
}
ALLOWLIST_MARKER = "# jsonb-allowlist:"


def load_jsonb_columns() -> Tuple[Set[str], Dict[str, List[str]]]:
    """Return (set of jsonb column names, {column: [tables]})."""
    if not SCHEMA_SNAPSHOT.exists():
        raise SystemExit(
            f"missing {SCHEMA_SNAPSHOT} — run with --refresh-schema (needs DATABASE_URL)"
        )
    by_table: Dict[str, List[str]] = json.loads(SCHEMA_SNAPSHOT.read_text())
    by_column: Dict[str, List[str]] = {}
    for table, cols in by_table.items():
        for col in cols:
            by_column.setdefault(col, []).append(table)
    return set(by_column), by_column


def refresh_schema() -> None:
    import psycopg2  # local import: only needed for --refresh-schema

    dsn = os.environ.get("DATABASE_URL")
    if not dsn:
        raise SystemExit("DATABASE_URL is not set")
    dsn = dsn.replace("postgresql+asyncpg://", "postgresql://")
    conn = psycopg2.connect(dsn)
    cur = conn.cursor()
    cur.execute(
        "select table_name, column_name from information_schema.columns "
        "where table_schema='public' and data_type in ('jsonb','json') order by 1,2"
    )
    by_table: Dict[str, List[str]] = {}
    for table, col in cur.fetchall():
        by_table.setdefault(table, []).append(col)
    SCHEMA_SNAPSHOT.write_text(json.dumps(by_table, indent=1, sort_keys=True) + "\n")
    print(f"wrote {SCHEMA_SNAPSHOT} ({len(by_table)} tables)")


def _is_json_dumps(node: ast.AST) -> bool:
    """True when the expression is (or conditionally yields) json.dumps(...)."""
    if isinstance(node, ast.IfExp):
        return _is_json_dumps(node.body) or _is_json_dumps(node.orelse)
    if isinstance(node, ast.BoolOp):
        return any(_is_json_dumps(v) for v in node.values)
    if not isinstance(node, ast.Call):
        return False
    func = node.func
    if isinstance(func, ast.Attribute):
        return func.attr == "dumps"
    if isinstance(func, ast.Name):
        return func.id == "dumps"
    return False


def scan_file(path: Path, jsonb_cols: Set[str]) -> List[Tuple[int, str]]:
    try:
        source = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return []
    if "dumps" not in source:
        return []
    try:
        # Some scanned files carry unescaped regex literals in docstrings; their
        # SyntaxWarnings are noise for this gate.
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", SyntaxWarning)
            tree = ast.parse(source)
    except SyntaxError:
        return []
    lines = source.splitlines()
    findings: List[Tuple[int, str]] = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Dict):
            continue
        for key, value in zip(node.keys, node.values):
            if not isinstance(key, ast.Constant) or not isinstance(key.value, str):
                continue
            if key.value not in jsonb_cols:
                continue
            if not _is_json_dumps(value):
                continue
            lineno = getattr(key, "lineno", getattr(node, "lineno", 0))
            line = lines[lineno - 1] if 0 < lineno <= len(lines) else ""
            if ALLOWLIST_MARKER in line:
                continue
            findings.append((lineno, key.value))
    return findings


def iter_python_files() -> List[Path]:
    out: List[Path] = []
    for root, dirs, files in os.walk(BACKEND_ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".venv")]
        for name in files:
            if name.endswith(".py"):
                out.append(Path(root) / name)
    return sorted(out)


def collect() -> Dict[str, List[int]]:
    jsonb_cols, _ = load_jsonb_columns()
    result: Dict[str, List[int]] = {}
    for path in iter_python_files():
        hits = scan_file(path, jsonb_cols)
        if hits:
            rel = str(path.relative_to(BACKEND_ROOT))
            # Key on file + column, NOT line number, so unrelated edits above a
            # grandfathered site do not resurrect it as a "new" finding.
            for _lineno, column in hits:
                result.setdefault(f"{rel}::{column}", []).append(_lineno)
    return result


def load_baseline() -> Set[str]:
    if not BASELINE_PATH.exists():
        return set()
    data = json.loads(BASELINE_PATH.read_text())
    return set(data.get("grandfathered", []))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="exit 1 on NEW findings")
    parser.add_argument("--refresh-baseline", action="store_true")
    parser.add_argument("--refresh-schema", action="store_true")
    args = parser.parse_args()

    if args.refresh_schema:
        refresh_schema()
        return 0

    findings = collect()
    _, by_column = load_jsonb_columns()

    if args.refresh_baseline:
        BASELINE_PATH.write_text(
            json.dumps(
                {
                    "_comment": (
                        "Grandfathered json.dumps()-into-JSONB sites. Each entry is "
                        "'<path>::<column>'. Do NOT add new entries — pass the dict "
                        "through instead. See audit_jsonb_double_encoding.py."
                    ),
                    "grandfathered": sorted(findings),
                },
                indent=1,
            )
            + "\n"
        )
        print(f"wrote {BASELINE_PATH} ({len(findings)} grandfathered sites)")
        return 0

    baseline = load_baseline()
    new = sorted(set(findings) - baseline)

    if not args.check:
        for key in sorted(findings):
            path, column = key.split("::")
            tables = ", ".join(by_column.get(column, []))
            marker = "NEW " if key in new else "    "
            print(f"{marker}{path}:{findings[key][0]}  {column}  (jsonb in: {tables})")
        print(f"\n{len(findings)} site(s), {len(new)} new vs baseline")
        return 0

    if new:
        print("FAIL — json.dumps() into a JSONB column (stores a double-encoded string):")
        for key in new:
            path, column = key.split("::")
            tables = ", ".join(by_column.get(column, []))
            print(f"  {path}:{findings[key][0]}  '{column}'  is JSONB in: {tables}")
        print(
            "\nPass the Python dict/list straight through — PostgREST serialises it "
            "into a real jsonb object. If the column is TEXT in the table this call "
            f"actually writes, add a trailing '{ALLOWLIST_MARKER} <reason>' comment."
        )
        return 1

    print(f"OK — no new json.dumps()-into-JSONB sites ({len(baseline)} grandfathered)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
