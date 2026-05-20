"""Lint gate: catch new timezone bugs before they ship.

Forbidden patterns in `backend/api/`, `backend/services/`, `backend/mcp/`:

  1. Bare midnight-UTC writes: `f"{date}T00:00:00Z"`, `f"{date}T00:00:00+00:00"`
     (write `target_date_to_utc_iso(date, user_tz)` instead)
  2. Bare midnight-UTC concat in query ranges: `.gte("col", f"{x}T00:00:00")`
     (write `local_date_to_utc_range(x, user_tz)` instead)
  3. UTC-naive "today" computations in business logic:
     `date.today()`, `datetime.utcnow()`, `datetime.now(timezone.utc).date()`
     (write `get_user_today(resolve_timezone(request, db, user_id))` instead)

Allow-list comments:
  - Trail any deliberate use with `# tz-allowlist: <reason>` to silence the
    gate for genuine event-timestamp (not calendar-day) uses.

Exit code:
  0 — no findings
  1 — findings detected (prints offending file:line:snippet)
  2 — internal error

Usage:
    backend/.venv/bin/python backend/scripts/audit_timezone_usage.py
    backend/.venv/bin/python backend/scripts/audit_timezone_usage.py --json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Iterable, List, Tuple

BACKEND_ROOT = Path(__file__).resolve().parent.parent
SCAN_ROOTS = [
    BACKEND_ROOT / "api",
    BACKEND_ROOT / "services",
    BACKEND_ROOT / "mcp",
]

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


def is_excluded(p: Path) -> bool:
    s = str(p)
    return any(seg in s for seg in EXCLUDE_PATH_PARTS)


def iter_py_files() -> Iterable[Path]:
    for root in SCAN_ROOTS:
        if not root.is_dir():
            continue
        for p in root.rglob("*.py"):
            if is_excluded(p):
                continue
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


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true", help="emit JSON instead of human")
    args = ap.parse_args()

    all_findings: List[dict] = []
    for p in iter_py_files():
        all_findings.extend(scan_file(p))

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
