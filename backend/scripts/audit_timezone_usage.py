"""Lint gate: catch new timezone bugs before they ship.

Forbidden patterns in `backend/api/`, `backend/services/`, `backend/mcp/`,
`backend/core/`:

  1. Bare midnight-UTC writes: `f"{date}T00:00:00Z"`, `f"{date}T00:00:00+00:00"`
     (write `target_date_to_utc_iso(date, user_tz)` instead)
  2. Bare midnight-UTC concat in query ranges: `.gte("col", f"{x}T00:00:00")`
     (write `local_day_bounds(x, user_tz)` instead)
  3. UTC-naive "today" computations in business logic:
     `date.today()`, `datetime.utcnow()`, `datetime.now(timezone.utc).date()`
     (write `get_user_today(resolve_timezone(request, db, user_id))` instead)

Plus three AST rules the line regexes structurally cannot see:

  4. tz-blind day window — `.gte/.lte/.lt("<timestamptz col>", <f-string with
     T00:00 / T23:59>)`. This is the exact shape that billed a UTC-4 user's
     previous-evening dinners (2,844 kcal) to "today" on the coach card.
  5. UTC-date bucketing — `str(row["logged_at"])[:10]` / `.date()` on a
     timestamptz. The UTC date rolls a 9pm-local row onto the next day.
  6. closed interval — `.lte(` fed an END value from `local_day_bounds` /
     `local_range_bounds`. Those bounds are HALF-OPEN; they need `.lt`.

Real DATE columns (`activity_date`, `local_date`, `score_date`,
`scheduled_date`) are already correct and are allowlisted in the AST rules.

Allow-list comments:
  - Trail any deliberate use with `# tz-allowlist: <reason>` to silence the
    gate for genuine event-timestamp (not calendar-day) uses. Works for the
    regex rules and the AST rules alike (any line the flagged node spans).

Baseline:
  `--check` is the CI mode. It fails ONLY on findings absent from
  `backend/scripts/tz_audit_baseline.json`, so the known backlog is
  grandfathered but cannot GROW. Entries are keyed by file + rule + matched
  source text (NOT line numbers — those churn on every edit).
  Regenerate with `--refresh-baseline` after intentionally fixing (or
  intentionally accepting) findings.

Exit code:
  0 — clean (or, under --check, no findings beyond the baseline)
  1 — findings detected (prints offending file:line:snippet)
  2 — internal error (e.g. --check with no baseline file)

Usage:
    backend/.venv/bin/python backend/scripts/audit_timezone_usage.py
    backend/.venv/bin/python backend/scripts/audit_timezone_usage.py --json
    backend/.venv/bin/python backend/scripts/audit_timezone_usage.py --check
    backend/.venv/bin/python backend/scripts/audit_timezone_usage.py --refresh-baseline
"""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable, List, Optional, Set, Tuple

BACKEND_ROOT = Path(__file__).resolve().parent.parent
SCAN_ROOTS = [
    BACKEND_ROOT / "api",
    BACKEND_ROOT / "services",
    BACKEND_ROOT / "mcp",
    # `core/` holds db helper modules (core/db/nutrition_db_helpers.py) that
    # build day windows themselves — the second root cause of the 2026-07-22
    # coach-card bug lived here and was invisible to this gate.
    BACKEND_ROOT / "core",
]

BASELINE_PATH = BACKEND_ROOT / "scripts" / "tz_audit_baseline.json"

# Skip the helpers themselves + tests + scripts (this audit) + migrations.
EXCLUDE_PATH_PARTS = (
    "/core/timezone_utils.py",
    "/test_",
    "/tests/",
    "/scripts/",
    "/migrations/",
    "/.venv/",
)

ALLOWLIST_RE = re.compile(r"#\s*tz-allowlist\b")

# Pattern → human description. Each pattern is searched line by line.
# These flag ONLY user-calendar-day misuse, not event timestamps. A bare
# `datetime.utcnow()` for `created_at`/`updated_at`/`sent_at` is fine — it
# records when an event happened. Only the `.date()` / `.strftime('%Y-%m-%d')`
# extracts indicate "this is supposed to be a user calendar day".
PATTERNS: List[Tuple[str, "re.Pattern[str]"]] = [
    (
        "midnight-UTC write — use `target_date_to_utc_iso(date, user_tz)`",
        re.compile(r'T00:00:00\+?(?:00:?00)?Z?["\']'),
    ),
    (
        "end-of-day concat — use `local_date_to_utc_range(date, user_tz)`",
        re.compile(r'T23:59:59'),
    ),
    (
        "UTC-naive `date.today()` — use `get_user_today(user_tz)`",
        re.compile(r"\bdate\.today\(\)"),
    ),
    (
        "UTC-naive `datetime.utcnow().date()` / `.strftime('%Y-%m-%d')` — use `get_user_today(user_tz)`",
        re.compile(r"datetime\.utcnow\(\)\.(?:date\(\)|strftime\([\"']%Y-%m-%d)"),
    ),
    (
        "UTC-naive `datetime.now(timezone.utc).date()` — use `get_user_today(user_tz)`",
        re.compile(r"datetime\.now\(timezone\.utc\)\.date\(\)"),
    ),
]

# ── AST rules ───────────────────────────────────────────────────────────
# Columns stored as `timestamptz` (UTC instants). Slicing or day-windowing
# these without the user's zone is the bug class this gate exists for.
TIMESTAMPTZ_COLUMNS = {
    "logged_at",
    "completed_at",
    "created_at",
    "achieved_at",
    "recorded_at",
    "consumed_at",
    "started_at",
}

# Genuine DATE columns — already stored as the user's calendar day, so a
# `f"{date}T00:00:00"` bound or a `[:10]` on them is correct, not a bug.
# `workouts.scheduled_date` is a timestamptz (not a DATE), but is allowlisted
# because its convention is now CLOSED: it is stored at NOON of the day
# (target_date_to_utc_iso — noon-local, or noon-UTC when a writer lacks tz), and
# a noon anchor lands inside its own local-day window in every realistic tz, so
# UTC-day-window reads are correct. Writers MUST use noon (never a bare-date /
# midnight bound); readers MUST use a full-day window, never a bare-date `.eq`
# or `.lte`. See CLAUDE.md "Local-day windows on timestamptz columns".
DATE_COLUMNS = {"activity_date", "local_date", "score_date", "scheduled_date"}

HALF_OPEN_BOUND_FUNCS = {"local_day_bounds", "local_range_bounds"}

RULE_TZ_BLIND_WINDOW = (
    "tz-blind day window — use `local_day_bounds(date, tz)` with .gte/.lt"
)
RULE_UTC_DATE_BUCKET = "UTC-date bucketing — use `utc_to_local_date(value, tz)`"
RULE_CLOSED_INTERVAL = (
    "closed interval on a half-open bound — `local_day_bounds`/`local_range_bounds` "
    "ends need `.lt`, not `.lte`"
)

FILTER_METHODS = {"gte", "lte", "lt"}


def is_excluded(p: Path) -> bool:
    s = str(p)
    return any(seg in s for seg in EXCLUDE_PATH_PARTS)


def iter_py_files() -> Iterable[Path]:
    seen: Set[Path] = set()
    for root in SCAN_ROOTS:
        if not root.is_dir():
            continue
        for p in sorted(root.rglob("*.py")):
            if is_excluded(p) or p in seen:
                continue
            seen.add(p)
            yield p


def scan_file(p: Path) -> List[dict]:
    findings: List[dict] = []
    try:
        text = p.read_text(encoding="utf-8")
    except Exception:
        return findings
    for lineno, line in enumerate(text.splitlines(), start=1):
        if ALLOWLIST_RE.search(line):
            continue
        # Skip pure comment / docstring lines so explanatory comments quoting
        # the forbidden patterns don't trip the gate.
        stripped = line.lstrip()
        if stripped.startswith("#") or stripped.startswith('"""') or stripped.startswith("'''"):
            continue
        for label, pat in PATTERNS:
            if pat.search(line):
                findings.append({
                    "file": str(p.relative_to(BACKEND_ROOT.parent)),
                    "line": lineno,
                    "rule": label,
                    "snippet": line.strip()[:200],
                })
                break  # one finding per line is enough
    return findings


# ── AST helpers ─────────────────────────────────────────────────────────


def _str_const(node: ast.AST) -> Optional[str]:
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return node.value
    return None


def _mentions(node: ast.AST, names: Set[str]) -> bool:
    """True if *node*'s subtree references any of *names* as a string literal,
    a bare identifier, or an attribute — i.e. `r["logged_at"]`, `logged_at`,
    `row.logged_at` all count."""
    for sub in ast.walk(node):
        s = _str_const(sub)
        if s is not None and s in names:
            return True
        if isinstance(sub, ast.Name) and sub.id in names:
            return True
        if isinstance(sub, ast.Attribute) and sub.attr in names:
            return True
    return False


def _has_astimezone(node: ast.AST) -> bool:
    for sub in ast.walk(node):
        if isinstance(sub, ast.Attribute) and sub.attr in ("astimezone", "utc_to_local_date"):
            return True
        if isinstance(sub, ast.Name) and sub.id == "utc_to_local_date":
            return True
    return False


def _literal_parts(node: ast.AST) -> str:
    """Concatenate every string literal in *node*'s subtree — lets us see the
    `T00:00`/`T23:59` inside an f-string or a `+` concat."""
    out = []
    for sub in ast.walk(node):
        s = _str_const(sub)
        if s is not None:
            out.append(s)
    return "".join(out)


def _is_built_timestamp_expr(node: ast.AST) -> bool:
    """f-string, `+` concat, or `"...".format(...)` — a hand-assembled bound."""
    if isinstance(node, (ast.JoinedStr, ast.BinOp)):
        return True
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) and node.func.attr == "format":
        return True
    return False


def _callee_name(call: ast.Call) -> str:
    f = call.func
    if isinstance(f, ast.Name):
        return f.id
    if isinstance(f, ast.Attribute):
        return f.attr
    return ""


def _snippet(text_lines: List[str], node: ast.AST, source: str) -> str:
    seg = None
    try:
        seg = ast.get_source_segment(source, node)
    except Exception:
        seg = None
    if not seg:
        idx = getattr(node, "lineno", 1) - 1
        seg = text_lines[idx] if 0 <= idx < len(text_lines) else ""
    return re.sub(r"\s+", " ", seg).strip()[:200]


def _allowlisted(text_lines: List[str], node: ast.AST) -> bool:
    start = getattr(node, "lineno", 1)
    end = getattr(node, "end_lineno", None) or start
    for i in range(start, end + 1):
        if 0 <= i - 1 < len(text_lines) and ALLOWLIST_RE.search(text_lines[i - 1]):
            return True
    return False


def scan_file_ast(p: Path) -> List[dict]:
    """AST pass for the three structural rules the regexes can't express."""
    findings: List[dict] = []
    try:
        source = p.read_text(encoding="utf-8")
        tree = ast.parse(source)
    except Exception:
        return findings
    lines = source.splitlines()
    rel = str(p.relative_to(BACKEND_ROOT.parent))

    # Names bound to the END element of a half-open bounds tuple, plus names
    # bound to the whole tuple (so `bounds[1]` is recognized too).
    end_names: Set[str] = set()
    tuple_names: Set[str] = set()
    for node in ast.walk(tree):
        if not isinstance(node, ast.Assign) or not isinstance(node.value, ast.Call):
            continue
        if _callee_name(node.value) not in HALF_OPEN_BOUND_FUNCS:
            continue
        for tgt in node.targets:
            if isinstance(tgt, (ast.Tuple, ast.List)) and len(tgt.elts) == 2:
                if isinstance(tgt.elts[1], ast.Name):
                    end_names.add(tgt.elts[1].id)
            elif isinstance(tgt, ast.Name):
                tuple_names.add(tgt.id)

    def _is_half_open_end(arg: ast.AST) -> bool:
        if isinstance(arg, ast.Name) and arg.id in end_names:
            return True
        if isinstance(arg, ast.Subscript):
            idx = arg.slice
            if isinstance(idx, ast.Constant) and idx.value == 1:
                base = arg.value
                if isinstance(base, ast.Name) and base.id in tuple_names:
                    return True
                if isinstance(base, ast.Call) and _callee_name(base) in HALF_OPEN_BOUND_FUNCS:
                    return True
        return False

    def add(node: ast.AST, rule: str) -> None:
        if _allowlisted(lines, node):
            return
        findings.append({
            "file": rel,
            "line": getattr(node, "lineno", 0),
            "rule": rule,
            "snippet": _snippet(lines, node, source),
        })

    for node in ast.walk(tree):
        # (a) tz-blind day window + (c) closed interval on a half-open bound
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
            meth = node.func.attr
            if meth in FILTER_METHODS and len(node.args) >= 2:
                col = _str_const(node.args[0])
                if col in TIMESTAMPTZ_COLUMNS and col not in DATE_COLUMNS:
                    bound = node.args[1]
                    if _is_built_timestamp_expr(bound):
                        lit = _literal_parts(bound)
                        if "T00:00" in lit or "T23:59" in lit:
                            add(node, RULE_TZ_BLIND_WINDOW)
                            continue
            if meth == "lte" and any(_is_half_open_end(a) for a in node.args):
                add(node, RULE_CLOSED_INTERVAL)
                continue

        # (b) UTC-date bucketing: `str(row["logged_at"])[:10]`
        if isinstance(node, ast.Subscript) and isinstance(node.slice, ast.Slice):
            sl = node.slice
            if (
                sl.lower is None
                and sl.step is None
                and isinstance(sl.upper, ast.Constant)
                and sl.upper.value == 10
                and _mentions(node.value, TIMESTAMPTZ_COLUMNS)
                and not _mentions(node.value, DATE_COLUMNS)
                and not _has_astimezone(node.value)
            ):
                add(node, RULE_UTC_DATE_BUCKET)
                continue

        # (b) UTC-date bucketing: `<timestamptz>.date()`
        if (
            isinstance(node, ast.Call)
            and isinstance(node.func, ast.Attribute)
            and node.func.attr == "date"
            and not node.args
            and not node.keywords
            and _mentions(node.func.value, TIMESTAMPTZ_COLUMNS)
            and not _mentions(node.func.value, DATE_COLUMNS)
            and not _has_astimezone(node.func.value)
        ):
            add(node, RULE_UTC_DATE_BUCKET)

    return findings


# ── baseline ────────────────────────────────────────────────────────────
# Keyed by (file, rule, matched source text) — deliberately NOT line numbers,
# which churn on every unrelated edit and would make the baseline worthless.


def _key(f: dict) -> Tuple[str, str, str]:
    return (f["file"], f["rule"], f["snippet"])


def _counts(findings: List[dict]) -> Counter:
    return Counter(_key(f) for f in findings)


def load_baseline() -> Optional[Counter]:
    if not BASELINE_PATH.exists():
        return None
    data = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    c: Counter = Counter()
    for entry in data.get("findings", []):
        c[(entry["file"], entry["rule"], entry["snippet"])] += int(entry.get("count", 1))
    return c


def write_baseline(findings: List[dict]) -> int:
    counts = _counts(findings)
    entries = [
        {"file": k[0], "rule": k[1], "snippet": k[2], "count": n}
        for k, n in sorted(counts.items())
    ]
    payload = {
        "_comment": (
            "Grandfathered timezone-audit findings. `--check` fails only on findings "
            "NOT listed here, so the known backlog cannot grow. Keyed by file + rule + "
            "matched source text (line numbers churn). Regenerate with "
            "`audit_timezone_usage.py --refresh-baseline` — and only ever shrink it."
        ),
        "total": len(findings),
        "findings": entries,
    }
    BASELINE_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return len(findings)


def collect() -> List[dict]:
    all_findings: List[dict] = []
    for p in iter_py_files():
        all_findings.extend(scan_file(p))
        all_findings.extend(scan_file_ast(p))
    all_findings.sort(key=lambda f: (f["file"], f["line"], f["rule"]))
    return all_findings


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true", help="emit JSON instead of human")
    ap.add_argument(
        "--check",
        action="store_true",
        help="CI mode: fail only on findings absent from the baseline",
    )
    ap.add_argument(
        "--refresh-baseline",
        action="store_true",
        help="rewrite scripts/tz_audit_baseline.json from the current tree",
    )
    args = ap.parse_args()

    all_findings = collect()

    if args.refresh_baseline:
        n = write_baseline(all_findings)
        print(f"✍️  timezone audit baseline refreshed: {n} finding(s) -> {BASELINE_PATH}")
        return 0

    if args.check:
        baseline = load_baseline()
        if baseline is None:
            print(
                f"❌ timezone audit: no baseline at {BASELINE_PATH}.\n"
                f"   Run `--refresh-baseline` once to grandfather the current backlog."
            )
            return 2
        current = _counts(all_findings)
        new: List[dict] = []
        remaining = Counter(baseline)
        for f in all_findings:
            k = _key(f)
            if remaining[k] > 0:
                remaining[k] -= 1
            else:
                new.append(f)
        grandfathered = len(all_findings) - len(new)

        if args.json:
            print(json.dumps(new, indent=2))
        elif not new:
            print(
                f"✅ timezone audit --check: clean "
                f"({grandfathered} known finding(s) grandfathered by the baseline)"
            )
        else:
            print(f"❌ timezone audit --check: {len(new)} NEW finding(s)\n")
            for f in new:
                print(f"  {f['file']}:{f['line']}  {f['rule']}")
                print(f"      {f['snippet']}")
            print(
                f"\n{grandfathered} pre-existing finding(s) grandfathered.\n"
                f"To fix: use the appropriate helper from `backend/core/timezone_utils.py`.\n"
                f"To silence one deliberate line, append `# tz-allowlist: <reason>`.\n"
                f"The baseline is for the PRE-EXISTING backlog only — do not add new "
                f"findings to it via --refresh-baseline."
            )
        # Sanity: the baseline should never claim more than the tree has.
        stale = sum(n for k, n in remaining.items() if n > 0 and current[k] < baseline[k])
        if not new and stale:
            print(f"   ({stale} baseline entry/entries no longer present — run --refresh-baseline to shrink)")
        return 0 if not new else 1

    if args.json:
        print(json.dumps(all_findings, indent=2))
    else:
        if not all_findings:
            print("✅ timezone audit: clean")
        else:
            print(f"❌ timezone audit: {len(all_findings)} finding(s)\n")
            for f in all_findings:
                print(f"  {f['file']}:{f['line']}  {f['rule']}")
                print(f"      {f['snippet']}")
            print(
                f"\nTo silence a specific line, append `# tz-allowlist: <reason>`.\n"
                f"To fix: replace with the appropriate helper from "
                f"`backend/core/timezone_utils.py`."
            )

    return 0 if not all_findings else 1


if __name__ == "__main__":
    sys.exit(main())
