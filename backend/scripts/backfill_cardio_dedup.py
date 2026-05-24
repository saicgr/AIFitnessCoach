"""
Backfill cardio_logs.dedup_group_id / is_hidden_duplicate for existing data.

Migration 2094 added the columns but every existing row is dedup_group_id=NULL.
This script scans the existing table, applies the same matching heuristic the
runtime service uses (±90s, ±5% duration, same activity_type, same user),
chooses a primary per source priority, and writes the group.

Usage:
    cd backend
    .venv/bin/python scripts/backfill_cardio_dedup.py --dry-run
    .venv/bin/python scripts/backfill_cardio_dedup.py --commit

Idempotent: re-running with --commit will skip rows that are already part of
a group (dedup_group_id IS NOT NULL).
"""
from __future__ import annotations

import argparse
import os
import sys
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Tuple

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv  # type: ignore

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

import psycopg2  # type: ignore
from psycopg2.extras import RealDictCursor  # type: ignore

# Reuse the runtime heuristic + priority constants — keeping a single source
# of truth between the runtime path and this backfill.
from services.cardio_dedup_service import (
    DURATION_TOLERANCE_PCT,
    SOURCE_PRIORITY,
    TIME_WINDOW_SECONDS,
)


def _resolve_db_url() -> str:
    """Prefer the direct (non-pooled) URL for bulk batch writes — the pooler
    can drop long-running transactions; direct connections are stable."""
    raw = os.getenv("DATABASE_URL_DIRECT") or os.getenv("DATABASE_URL")
    if not raw:
        raise RuntimeError("DATABASE_URL_DIRECT (or DATABASE_URL) not set")
    return raw.replace("postgresql+asyncpg://", "postgresql://", 1)


def _source_priority(source_app: str | None) -> int:
    if not source_app:
        return 0
    return SOURCE_PRIORITY.get(source_app.lower(), 0)


def _is_match(a: Dict[str, Any], b: Dict[str, Any]) -> bool:
    if a["activity_type"] != b["activity_type"]:
        return False
    if abs((a["performed_at"] - b["performed_at"]).total_seconds()) > TIME_WINDOW_SECONDS:
        return False
    dur_a = int(a["duration_seconds"] or 0)
    dur_b = int(b["duration_seconds"] or 0)
    if dur_a <= 0 or dur_b <= 0:
        return False
    denom = max(dur_a, dur_b)
    if abs(dur_a - dur_b) / denom > DURATION_TOLERANCE_PCT:
        return False
    return True


def _group_rows(rows: List[Dict[str, Any]]) -> List[List[Dict[str, Any]]]:
    """Greedy clustering — for each user/sport bucket, sort by performed_at,
    then walk forward grouping rows whose time delta to the cluster anchor is
    within the window. O(n) per bucket since the window is tiny.
    """
    # Bucket by (user_id, activity_type)
    buckets: Dict[Tuple[str, str], List[Dict[str, Any]]] = defaultdict(list)
    for r in rows:
        buckets[(str(r["user_id"]), r["activity_type"])].append(r)

    groups: List[List[Dict[str, Any]]] = []
    for _key, bucket in buckets.items():
        bucket.sort(key=lambda r: r["performed_at"])
        used = [False] * len(bucket)
        for i, anchor in enumerate(bucket):
            if used[i]:
                continue
            cluster = [anchor]
            used[i] = True
            # Walk forward only — anything earlier than anchor would have been
            # picked up when anchor itself was the candidate of an earlier loop.
            for j in range(i + 1, len(bucket)):
                if used[j]:
                    continue
                # Past the time window? bucket is sorted, so we can break.
                if (bucket[j]["performed_at"] - anchor["performed_at"]).total_seconds() > TIME_WINDOW_SECONDS:
                    break
                if _is_match(anchor, bucket[j]):
                    cluster.append(bucket[j])
                    used[j] = True
            if len(cluster) >= 2:
                groups.append(cluster)
    return groups


def _pick_primary(group: List[Dict[str, Any]]) -> Tuple[Dict[str, Any], List[Dict[str, Any]]]:
    def sort_key(r: Dict[str, Any]) -> Tuple[int, datetime]:
        return (_source_priority(r.get("source_app")), r.get("created_at") or datetime.min)

    sorted_g = sorted(group, key=sort_key, reverse=True)
    return sorted_g[0], sorted_g[1:]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Scan only; no writes.")
    parser.add_argument("--commit", action="store_true", help="Apply dedup groups to the DB.")
    args = parser.parse_args()

    if not (args.dry_run or args.commit):
        parser.error("Pick one of --dry-run or --commit")

    url = _resolve_db_url()
    print(f"[Dedup] Connecting to {url.split('@')[-1].split('/')[0]}...")

    with psycopg2.connect(url, cursor_factory=RealDictCursor) as conn:
        with conn.cursor() as cur:
            # Only scan rows not yet assigned a group — re-runs are safe.
            cur.execute(
                """
                SELECT id, user_id, activity_type, performed_at, duration_seconds,
                       source_app, created_at
                FROM cardio_logs
                WHERE dedup_group_id IS NULL
                ORDER BY user_id, activity_type, performed_at
                """
            )
            rows = cur.fetchall()
            print(f"[Dedup] Scanning {len(rows):,} ungrouped cardio_logs rows...")

            groups = _group_rows(rows)
            print(f"[Dedup] Found {len(groups):,} duplicate groups.")

            if args.dry_run:
                # Print a sample.
                sample = groups[:10]
                print(f"[Dedup] Sample ({len(sample)} of {len(groups)}):")
                for g in sample:
                    primary, losers = _pick_primary(g)
                    print(
                        f"  user={primary['user_id']} sport={primary['activity_type']} "
                        f"primary={primary['id']} ({primary.get('source_app')}) "
                        f"losers={[(str(r['id']), r.get('source_app')) for r in losers]}"
                    )
                print("[Dedup] Dry-run complete. Re-run with --commit to apply.")
                return 0

            # Commit path.
            total_rows_updated = 0
            for g in groups:
                primary, losers = _pick_primary(g)
                primary_id = str(primary["id"])
                loser_ids = [str(r["id"]) for r in losers]

                cur.execute(
                    "UPDATE cardio_logs SET dedup_group_id = %s, is_hidden_duplicate = false "
                    "WHERE id = %s",
                    (primary_id, primary_id),
                )
                total_rows_updated += cur.rowcount

                if loser_ids:
                    cur.execute(
                        "UPDATE cardio_logs SET dedup_group_id = %s, is_hidden_duplicate = true "
                        "WHERE id = ANY(%s)",
                        (primary_id, loser_ids),
                    )
                    total_rows_updated += cur.rowcount

                print(
                    f"[Dedup] user={primary['user_id']} primary={primary_id} "
                    f"sport={primary['activity_type']} hidden={len(loser_ids)}"
                )

            conn.commit()
            print(
                f"[Dedup] COMMIT — {len(groups):,} groups, {total_rows_updated:,} rows updated."
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
