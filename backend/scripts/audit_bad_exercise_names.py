"""Audit `exercise_library_cleaned` for filename-leaked / non-canonical names.

Reads from the cleaned MV (post-`refresh_exercise_library_cleaned()`) and
classifies each row into severity buckets based on the style guide in
`peppy-conjuring-valley.md` Fix 12.

Usage:
    cd backend && .venv/bin/python scripts/audit_bad_exercise_names.py

Outputs a per-row JSON list of issues to stdout and a CSV of flagged rows to
`backend/scripts/output/bad_exercise_names_<timestamp>.csv`.

A second run, after Fix 5 + Fix 12 SQL has been applied, must return zero
flagged rows. The script is idempotent and read-only.
"""
from __future__ import annotations

import csv
import os
import re
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import asyncio
from sqlalchemy import text
from core.supabase_client import get_supabase  # type: ignore  # noqa: E402


_ALL_CAPS_TOKEN = re.compile(r"\b[A-Z]{3,}\b")
_DOUBLE_OR_TRAILING_WS = re.compile(r"\s$|\s{2,}")
_LEGACY_HYPHEN = re.compile(
    r"\b(pull up|push up|chin up|sit up|step up|single arm|one arm|"
    r"single leg|one leg|half kneeling|wide grip|close grip|bent over|get up)\b",
    re.IGNORECASE,
)
_VERSION_OR_POV = re.compile(
    r"\((VERSION|version)\s*\d+\)|\((front|side|back)\s*POV\)",
    re.IGNORECASE,
)
_ANATOMY_POSTER = re.compile(r"major groups|muscle body|padded stool", re.IGNORECASE)


def classify(name: str) -> list[str]:
    issues: list[str] = []
    if not name:
        issues.append("EMPTY_NAME")
        return issues
    if _ANATOMY_POSTER.search(name):
        issues.append("ANATOMY_POSTER")
    if _ALL_CAPS_TOKEN.search(name):
        issues.append("ALL_CAPS_TOKEN")
    if _DOUBLE_OR_TRAILING_WS.search(name):
        issues.append("BAD_WHITESPACE")
    if _LEGACY_HYPHEN.search(name):
        issues.append("UNHYPHENATED_COMPOUND")
    if _VERSION_OR_POV.search(name):
        issues.append("FILENAME_SUFFIX")
    if name.endswith(("_male", "_female", "_Male", "_Female")):
        issues.append("GENDER_SUFFIX")
    return issues


async def main() -> None:
    engine = get_supabase().engine
    sql = text(
        "SELECT id, name, original_name, body_part, target_muscle, image_url "
        "FROM exercise_library_cleaned ORDER BY name"
    )
    async with engine.connect() as conn:
        result = await conn.execute(sql)
        rows = [dict(r._mapping) for r in result.fetchall()]

    flagged = [(r, classify(r["name"])) for r in rows]
    flagged = [(r, iss) for r, iss in flagged if iss]

    print(f"[audit] scanned {len(rows)} rows, flagged {len(flagged)}", flush=True)
    by_issue: dict[str, int] = {}
    for _, iss in flagged:
        for code in iss:
            by_issue[code] = by_issue.get(code, 0) + 1
    for code, n in sorted(by_issue.items(), key=lambda x: -x[1]):
        print(f"  {n:5d}  {code}")

    if not flagged:
        print("[audit] CLEAN — no rows need cleanup.")
        return

    out_dir = Path(__file__).parent / "output"
    out_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = out_dir / f"bad_exercise_names_{ts}.csv"
    with out_path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["id", "name", "original_name", "body_part",
                    "target_muscle", "image_url", "issues"])
        for r, iss in flagged:
            w.writerow([r["id"], r["name"], r["original_name"],
                        r["body_part"], r["target_muscle"],
                        r["image_url"], ",".join(iss)])
    print(f"[audit] wrote {out_path}")


if __name__ == "__main__":
    asyncio.run(main())
