"""
Manual runner for the cardio metric snapshot job.

Examples
--------
    # Compute (no DB writes) for one user — useful for verifying values.
    python backend/scripts/run_cardio_metric_snapshots.py \
        --user-id 11111111-1111-1111-1111-111111111111 --dry-run

    # Commit one user's snapshot for today.
    python backend/scripts/run_cardio_metric_snapshots.py \
        --user-id 11111111-1111-1111-1111-111111111111 --commit

    # Full sweep (intended use by cron) — dry-run first to inspect impact.
    python backend/scripts/run_cardio_metric_snapshots.py --all --dry-run

    # Commit full sweep.
    python backend/scripts/run_cardio_metric_snapshots.py --all --commit
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import date
from pathlib import Path

# Make `backend/` importable when invoked as a plain script.
BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from services import cardio_metric_snapshot_job as job  # noqa: E402
from core.db import get_supabase_db  # noqa: E402


def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Run the cardio metric snapshot job.")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--user-id", help="UUID of a single user to snapshot.")
    g.add_argument("--all", action="store_true",
                   help="Sweep every active user (cron mode).")

    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true",
                      help="Compute + print, do NOT write to DB.")
    mode.add_argument("--commit", action="store_true",
                      help="Persist computed snapshots via UPSERT.")

    p.add_argument("--date", help="ISO snapshot date (default: today).")
    return p.parse_args()


def main() -> int:
    args = _parse_args()
    snapshot_date = date.fromisoformat(args.date) if args.date else None
    dry_run = bool(args.dry_run)

    db = get_supabase_db()

    if args.all:
        summary = job.run_full_sweep(db, snapshot_date=snapshot_date, dry_run=dry_run)
    else:
        summary = job.run_for_user(
            db, args.user_id, snapshot_date=snapshot_date, dry_run=dry_run,
        )

    print(json.dumps(summary, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
