#!/usr/bin/env python3
"""
maybe_single() null-guard audit — regression gate for a whole class of 500s.

PostgREST's `.maybe_single().execute()` does NOT return an APIResponse with
`data=None` when zero rows match. It returns **None** (the response object
itself). See the vendored builder:

    postgrest/_async/request_builder.py :: AsyncMaybeSingleRequestBuilder.execute
        except APIError as e:
            if e.details and "The result contains 0 rows" in e.details:
                return None            # <-- the footgun

So any consumer that does `result.data` (or `if not result.data:`) WITHOUT
first null-checking the result object raises `AttributeError: 'NoneType' object
has no attribute 'data'` for every account missing the queried row — wrapped as
a 500. The bug is invisible in normal use because the row usually exists; fresh
and test accounts (no nutrition_preferences, no cardio session, no photos, ...)
are exactly where it bites.

  2026-07-15: get_adherence_summary 500'd (`if not prefs_result.data:`) for a
  fresh account with no nutrition_preferences row. A sweep found 53 sibling
  sites across cardio / progress_photos / subscriptions / neat / trophies /
  watch_sync / nutrition endpoints all sharing the identical footgun.

The correct pattern is to guard the RESULT OBJECT, not just `.data`:

    res = db.client.table("t").select("...").eq(...).maybe_single().execute()
    if not res or not res.data:          # <-- res may be None
        ...
    # or, for inline extraction:
    val = (res.data if res else None) or {}

What it does: statically finds every `.maybe_single().execute()` call, tracks
the variable it binds, and verifies the result object is None-checked before
the first `.data` dereference.

Usage:
    python scripts/audit_maybe_single_guards.py            # report
    python scripts/audit_maybe_single_guards.py --check    # exit 1 on any unguarded site

Run --check after adding any backend `.maybe_single()` query.

Conservative by design (a guard is recognised when the result object VAR is
tested for None-ness — `if not VAR:` / `if VAR is None:` / `VAR and VAR.data`
/ `VAR.data if VAR else ...` — but NOT when only `.data` is tested, since
`if not VAR.data:` still dereferences a possibly-None VAR).
"""
import argparse
import re
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent
SKIP_DIRS = {"venv", ".venv", "node_modules", "__pycache__", "migrations", "scripts", "tests"}


def _skip(path: Path) -> bool:
    return any(p in SKIP_DIRS or p.startswith(".venv") for p in path.parts)


def _guarded(var: str, access_blob: str, prewindow: str) -> bool:
    """True when result object `var` is None-checked at/before the `.data` access.

    ``access_blob`` is the access line plus its inline-ternary continuation, so a
    multi-line ``X.data.get(...)\\n  if X and X.data else None`` is recognised.

    Crucially, every ``var`` match is anchored with ``(?!\\.)`` so a check of
    ``var.data`` does NOT count as guarding ``var`` itself — ``if not var.data:``
    and ``x.data if var.data else`` are the exact bugs we flag (they guard the
    attribute, not the possibly-None object).
    """
    v = re.escape(var)
    on_line = (
        re.search(rf"\bif\s+not\s+{v}\b(?!\.)", access_blob)       # if not VAR / if not VAR or
        or re.search(rf"\b{v}\s+and\b", access_blob)               # VAR and VAR.data
        or re.search(rf"\bif\s+{v}\b(?!\.)", access_blob)          # if VAR: / if VAR else
        or re.search(rf"\b{v}\s+is\s+(not\s+)?None\b", access_blob)
    )
    if on_line:
        return True
    # Guard clause earlier in the same block (if not VAR: return/raise/continue).
    pre = (
        re.search(rf"\bif\s+not\s+{v}\b(?!\.)", prewindow)
        or re.search(rf"\bif\s+{v}\s+is\s+None\b", prewindow)
        or re.search(rf"\bif\s+not\s+{v}\s+or\b", prewindow)
        or re.search(rf"\bif\s+{v}\s*:", prewindow)
    )
    return bool(pre)


ASSIGN_RE = re.compile(r"(\w+)\s*=\s*(await\s+)?(db\.|self\.|supabase|_?client|.*\.table\()")


def scan_file(path: Path):
    violations = []
    lines = path.read_text(errors="ignore").split("\n")
    for i, line in enumerate(lines):
        if "maybe_single()" not in line:
            continue
        # Resolve the variable the statement binds (backward to the assignment).
        var = None
        for j in range(i, max(i - 8, -1), -1):
            m = ASSIGN_RE.search(lines[j])
            if m:
                var = m.group(1)
                break
        if not var:
            continue
        # Find the .execute() line that closes the statement.
        end = i
        for k in range(i, min(i + 5, len(lines))):
            if "execute()" in lines[k]:
                end = k
                break
        # First `.data` dereference of the result.
        for k in range(end + 1, min(end + 12, len(lines))):
            if f"{var}.data" in lines[k]:
                prewindow = "\n".join(lines[end + 1:k])
                # Access line + inline-ternary continuation (guard may wrap).
                access_blob = "\n".join(lines[k:k + 3])
                if not _guarded(var, access_blob, prewindow):
                    violations.append((k + 1, var, lines[k].strip()[:100]))
                break
    return violations


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--check", action="store_true", help="exit 1 if any unguarded site is found")
    args = ap.parse_args()

    all_violations = []
    for path in sorted(BACKEND.rglob("*.py")):
        if _skip(path.relative_to(BACKEND)):
            continue
        for (ln, var, snippet) in scan_file(path):
            all_violations.append((path.relative_to(BACKEND), ln, var, snippet))

    if all_violations:
        print(f"❌ {len(all_violations)} unguarded maybe_single().execute() deref(s):\n")
        for rel, ln, var, snippet in all_violations:
            print(f"  {rel}:{ln}  [{var}]  {snippet}")
        print(
            "\nGuard the RESULT OBJECT before .data — maybe_single().execute() "
            "returns None on 0 rows:\n"
            "    if not <var> or not <var>.data:   # guard clause\n"
            "    (<var>.data if <var> else None)   # inline extraction"
        )
        if args.check:
            return 1
    else:
        print("✅ No unguarded maybe_single().execute() derefs found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
