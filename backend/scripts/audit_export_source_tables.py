#!/usr/bin/env python3
"""
Data-export source-table audit — regression gate for register #198.

Every CSV in the GDPR export ZIP is backed by a `db.client.table("<name>")`
call somewhere in `services/data_export.py` — either directly (the dedicated
`_get_filtered_*` / `_get_user_streaks` helpers) or via `_PORTABILITY_TABLES`
(`spec.get("table") or spec["name"]`). A typo'd or renamed table name doesn't
raise: PostgREST 404s (PGRST205), the generic portability fetcher swallows it,
and the export silently ships a header-only CSV that is indistinguishable
from "the user genuinely has zero rows" — exactly the register #198 bug
(`water_intake`, `habit_completions`, `hormonal_logs`, `kegel_logs`,
`user_measurements`, `personal_goals`, `mood_logs` all shipped against table
names that were never real, one at a time, over several audits).

What it does: statically extracts every literal table name this file queries
— `_PORTABILITY_TABLES` entries (resolved `table` override or bare `name`)
plus every literal `db.client.table("...")` call anywhere else in the file —
and validates each against `schema_columns_snapshot.json` (the same checked-in
`information_schema` dump `audit_supabase_column_drift.py` uses). A table
name that isn't a real key in the snapshot is a export CSV that WILL ship
empty for every user, in every environment, regardless of their data.

`nutrition_summaries` is deliberately exempt — it has no backing table and is
computed at export time in `_derive_nutrition_summaries` by aggregating
`food_logs` (itself checked normally).

Usage:
    python scripts/audit_export_source_tables.py            # report
    python scripts/audit_export_source_tables.py --check    # exit 1 on any unresolvable source

Run --check after touching `_PORTABILITY_TABLES` or adding a new export
source table in `services/data_export.py`. Refresh the snapshot the same way
`audit_supabase_column_drift.py --refresh` does (needs DATABASE_URL) after a
migration adds/removes a table this file reads.
"""
import argparse
import ast
import json
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent
DATA_EXPORT_FILE = BACKEND / "services" / "data_export.py"
SNAPSHOT_FILE = Path(__file__).resolve().parent / "schema_columns_snapshot.json"

# Computed at export time from another (checked) source table — not itself a
# table name to validate.
DERIVED_SOURCES = {"nutrition_summaries"}


def _load_snapshot() -> dict:
    if not SNAPSHOT_FILE.exists():
        print(f"Schema snapshot not found: {SNAPSHOT_FILE}", file=sys.stderr)
        sys.exit(2)
    return json.loads(SNAPSHOT_FILE.read_text())


def _portability_table_specs(tree: ast.Module) -> list:
    """Extract (csv_name, resolved_table, lineno) for every entry in
    `_PORTABILITY_TABLES`."""
    specs = []
    for node in ast.walk(tree):
        # `_PORTABILITY_TABLES: List[Dict[str, Any]] = [...]` is an
        # `AnnAssign` (single `.target`), not a plain `Assign` (`.targets`).
        if isinstance(node, ast.AnnAssign):
            target = node.target
            targets_match = isinstance(target, ast.Name) and target.id == "_PORTABILITY_TABLES"
        elif isinstance(node, ast.Assign):
            targets_match = any(
                isinstance(t, ast.Name) and t.id == "_PORTABILITY_TABLES"
                for t in node.targets
            )
        else:
            continue
        if not targets_match:
            continue
        if not isinstance(node.value, ast.List):
            continue
        for elt in node.value.elts:
            if not isinstance(elt, ast.Dict):
                continue
            entry = {}
            for k, v in zip(elt.keys, elt.values):
                if isinstance(k, ast.Constant) and isinstance(v, ast.Constant):
                    entry[k.value] = v.value
            name = entry.get("name")
            if name is None:
                continue
            table = entry.get("table") or name
            specs.append((name, table, elt.lineno))
    return specs


def _literal_table_calls(tree: ast.Module) -> list:
    """Every `db.client.table("literal")` / `<db>.table("literal")` call
    anywhere in the file — covers the dedicated `_get_filtered_*` helpers
    that don't go through `_PORTABILITY_TABLES`."""
    calls = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        func = node.func
        if not (isinstance(func, ast.Attribute) and func.attr == "table"):
            continue
        if not node.args or not isinstance(node.args[0], ast.Constant):
            continue
        if not isinstance(node.args[0].value, str):
            continue
        calls.append((node.args[0].value, node.lineno))
    return calls


def audit() -> tuple[list, list]:
    """Returns (unresolvable, all_checked) — unresolvable is a list of
    (source_label, table, lineno) tuples for tables absent from the snapshot."""
    source = DATA_EXPORT_FILE.read_text()
    tree = ast.parse(source, filename=str(DATA_EXPORT_FILE))
    snapshot = _load_snapshot()

    unresolvable = []
    all_checked = []

    for csv_name, table, lineno in _portability_table_specs(tree):
        if csv_name in DERIVED_SOURCES:
            continue
        all_checked.append((f"{csv_name}.csv", table, lineno))
        if table not in snapshot:
            unresolvable.append((f"{csv_name}.csv", table, lineno))

    seen_tables = {t for _, t, _ in all_checked}
    for table, lineno in _literal_table_calls(tree):
        if table in seen_tables:
            continue
        seen_tables.add(table)
        all_checked.append((f"literal @ line {lineno}", table, lineno))
        if table not in snapshot:
            unresolvable.append((f"literal @ line {lineno}", table, lineno))

    return unresolvable, all_checked


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="exit 1 on any unresolvable source")
    args = parser.parse_args()

    unresolvable, all_checked = audit()

    print(f"Checked {len(all_checked)} export source table(s) against the schema snapshot.")
    if unresolvable:
        print(f"\n❌ {len(unresolvable)} export source(s) reference a table that does not exist:\n")
        for label, table, lineno in unresolvable:
            print(f"  {DATA_EXPORT_FILE.relative_to(BACKEND)}:{lineno}  {label} -> table('{table}') NOT FOUND")
        print(
            "\nThis CSV will ship header-only for EVERY user regardless of their "
            "data (register #198) — fix the table name (or add a `\"table\": "
            "\"<real_name>\"` override in _PORTABILITY_TABLES) before shipping."
        )
        if args.check:
            return 1
    else:
        print("✅ Every export source table resolves to a real table.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
