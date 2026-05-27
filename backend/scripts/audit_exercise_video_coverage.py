"""Audit video coverage on the RAG-source view (`exercise_library_cleaned`).

Counts rows where ALL of `gif_url`, `video_url`, `image_url` are NULL or
empty — these are the rows that the RAG can still return (the MV dedup
already prioritises rows WITH media, but for exercises where the ONLY
candidate has no media, the zero-media row lands in the MV).

This is the gate behind the URGENT workout-library completeness task
(Promoted 2026-05-27) — pre-Apple-submission we need to know how many
exercises in the RAG corpus would render as a blank card if the AI
selected them. Beginner persona (Tech-guy reviewer, 3.txt T9 L2487-2497;
Ireina, 3.txt T6 L1612-1618) hit exactly this failure mode in Google
Health Coach with "shoulder taps" / "torso twist" — exercises that
existed in their library but had no demo.

Run:
    cd /Users/saichetangrandhe/AIFitnessCoach
    backend/.venv/bin/python -m backend.scripts.audit_exercise_video_coverage

Output:
    backend/scripts/out/exercise_media_gap_<ts>.csv  — per-row report:
        (id, name, body_part, equipment, has_gif, has_video, has_image)
    stdout: summary counts.

Exit code: 0 always (informational). Use `--fail-on-gap N` to exit 1 when
zero-media rows exceed N (CI gate before Apple submission).
"""
from __future__ import annotations

import argparse
import asyncio
import csv
import os
import sys
import time
from pathlib import Path

import asyncpg
from dotenv import load_dotenv

# Load backend/.env DATABASE_URL
SCRIPT_DIR = Path(__file__).resolve().parent
load_dotenv(SCRIPT_DIR.parent / ".env")

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    print("❌ DATABASE_URL not set in backend/.env", file=sys.stderr)
    sys.exit(2)


SQL_COVERAGE_SUMMARY = """
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE NULLIF(gif_url, '') IS NOT NULL)    AS rows_with_gif,
    COUNT(*) FILTER (WHERE NULLIF(video_url, '') IS NOT NULL)  AS rows_with_video,
    COUNT(*) FILTER (WHERE NULLIF(image_url, '') IS NOT NULL)  AS rows_with_image,
    COUNT(*) FILTER (
        WHERE COALESCE(NULLIF(gif_url, ''), NULLIF(video_url, ''), NULLIF(image_url, '')) IS NOT NULL
    ) AS rows_with_any_media,
    COUNT(*) FILTER (
        WHERE NULLIF(gif_url, '') IS NULL
          AND NULLIF(video_url, '') IS NULL
          AND NULLIF(image_url, '') IS NULL
    ) AS rows_with_zero_media,
    COUNT(*) FILTER (
        WHERE COALESCE(NULLIF(instructions, ''), '') = ''
    ) AS rows_with_no_instructions
FROM exercise_library_cleaned;
"""

SQL_ZERO_MEDIA_ROWS = """
SELECT id, name, body_part, equipment,
       (NULLIF(gif_url, '')   IS NOT NULL) AS has_gif,
       (NULLIF(video_url, '') IS NOT NULL) AS has_video,
       (NULLIF(image_url, '') IS NOT NULL) AS has_image,
       LENGTH(COALESCE(instructions, '')) AS instructions_len
FROM exercise_library_cleaned
WHERE NULLIF(gif_url, '')   IS NULL
  AND NULLIF(video_url, '') IS NULL
  AND NULLIF(image_url, '') IS NULL
ORDER BY body_part NULLS LAST, name;
"""


async def main(fail_on_gap: int | None) -> int:
    conn = await asyncpg.connect(DATABASE_URL, timeout=30)
    try:
        summary = await conn.fetchrow(SQL_COVERAGE_SUMMARY)
        zero_media_rows = await conn.fetch(SQL_ZERO_MEDIA_ROWS)
    finally:
        await conn.close()

    total = summary["total_rows"]
    zero_media = summary["rows_with_zero_media"]
    with_any = summary["rows_with_any_media"]

    print(f"\n=== Exercise library media coverage (exercise_library_cleaned) ===")
    print(f"Total rows                  : {total}")
    print(f"Rows with GIF               : {summary['rows_with_gif']}  ({100 * summary['rows_with_gif'] / total:.1f}%)")
    print(f"Rows with video             : {summary['rows_with_video']}  ({100 * summary['rows_with_video'] / total:.1f}%)")
    print(f"Rows with image             : {summary['rows_with_image']}  ({100 * summary['rows_with_image'] / total:.1f}%)")
    print(f"Rows with ANY media         : {with_any}  ({100 * with_any / total:.1f}%)")
    print(f"Rows with ZERO media        : {zero_media}  ({100 * zero_media / total:.1f}%)  ← RAG-visible gap")
    print(f"Rows with empty instructions: {summary['rows_with_no_instructions']}")

    if zero_media_rows:
        out_dir = SCRIPT_DIR / "out"
        out_dir.mkdir(exist_ok=True)
        ts = time.strftime("%Y%m%d_%H%M%S")
        path = out_dir / f"exercise_media_gap_{ts}.csv"
        with path.open("w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow([
                "id", "name", "body_part", "equipment",
                "has_gif", "has_video", "has_image", "instructions_len",
            ])
            for r in zero_media_rows:
                writer.writerow([
                    r["id"], r["name"], r["body_part"], r["equipment"],
                    r["has_gif"], r["has_video"], r["has_image"],
                    r["instructions_len"],
                ])
        print(f"\nCSV: {path.relative_to(SCRIPT_DIR.parent.parent)}")

    if fail_on_gap is not None and zero_media > fail_on_gap:
        print(
            f"\n❌ FAIL: {zero_media} zero-media rows exceed threshold ({fail_on_gap}).",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--fail-on-gap",
        type=int,
        default=None,
        help="Exit 1 when zero-media row count exceeds this threshold (CI gate).",
    )
    args = parser.parse_args()
    sys.exit(asyncio.run(main(args.fail_on_gap)))
