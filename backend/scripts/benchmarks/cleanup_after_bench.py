"""Interactive post-bench cleanup of QA reviewer's food_log rows.

Reads the latest run_<UTC>_window.txt to scope DELETE to the bench window
(start ≤ created_at ≤ end). Asks for explicit y/N confirmation before
running the DELETE. Idempotent — safe to run multiple times.

Usage:
    cd backend
    .venv/bin/python scripts/benchmarks/cleanup_after_bench.py
    .venv/bin/python scripts/benchmarks/cleanup_after_bench.py --window run_20260515T180000Z_window.txt
"""
import argparse
import asyncio
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / ".env")
sys.path.insert(0, str(ROOT))

from sqlalchemy import text
from core.supabase_client import get_supabase

RESULTS_DIR = Path(__file__).resolve().parent / "results"


def parse_window(path: Path) -> dict:
    out = {}
    for line in path.read_text().splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip()
    return out


def latest_window() -> Path:
    files = sorted(RESULTS_DIR.glob("run_*_window.txt"))
    if not files:
        sys.exit("no run_*_window.txt files in results/ — run the sweep first")
    return files[-1]


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--window", type=str, default="", help="specific run_*_window.txt (default: latest)")
    parser.add_argument("--yes", action="store_true", help="skip confirmation prompt")
    args = parser.parse_args()

    window_path = RESULTS_DIR / args.window if args.window else latest_window()
    if not window_path.exists():
        sys.exit(f"window file not found: {window_path}")
    w = parse_window(window_path)
    user_id = w["user_id"]
    # asyncpg binds timestamptz columns from datetime objects, not ISO
    # strings — parse them so `created_at >= :t_start` doesn't error.
    from datetime import datetime as _dt
    t_start = _dt.fromisoformat(w["start"])
    t_end = _dt.fromisoformat(w["end"])

    print(f"Bench window: {t_start} → {t_end}")
    print(f"User:         {user_id}")

    supabase = get_supabase()
    async with supabase.get_session() as session:
        # First count
        cnt_row = await session.execute(
            text("""
                SELECT COUNT(*) AS n
                FROM food_logs
                WHERE user_id = CAST(:uid AS uuid)
                  AND created_at >= :t_start
                  AND created_at <= :t_end
            """),
            {"uid": user_id, "t_start": t_start, "t_end": t_end},
        )
        n = cnt_row.fetchone()._mapping["n"]

    print(f"\nWill DELETE {n} food_log rows.")
    if n == 0:
        print("Nothing to clean up.")
        return 0

    if not args.yes:
        ans = input("Type 'DELETE' to confirm: ").strip()
        if ans != "DELETE":
            print("Aborted.")
            return 1

    async with supabase.get_session() as session:
        result = await session.execute(
            text("""
                DELETE FROM food_logs
                WHERE user_id = CAST(:uid AS uuid)
                  AND created_at >= :t_start
                  AND created_at <= :t_end
            """),
            {"uid": user_id, "t_start": t_start, "t_end": t_end},
        )
        await session.commit()
        print(f"Deleted {result.rowcount} rows.")

    # Optional: also clean up user_contributed entries created during the window
    # (so a re-run of the same bench actually re-warms cleanly)
    if not args.yes:
        ans = input("\nAlso clear food_overrides_user_contributed for this user? (y/N): ").strip().lower()
        if ans != "y":
            return 0
    async with supabase.get_session() as session:
        result = await session.execute(
            text("""
                DELETE FROM food_overrides_user_contributed
                WHERE user_id = CAST(:uid AS uuid)
                  AND first_logged_at >= :t_start
                  AND first_logged_at <= :t_end
            """),
            {"uid": user_id, "t_start": t_start, "t_end": t_end},
        )
        await session.commit()
        print(f"Deleted {result.rowcount} user_contributed rows.")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
