"""One-time backfill of inflammation_score + health_score on existing food_logs.

Many historical rows have a NULL inflammation_score and/or health_score:
legacy rows logged before the feature, verified-data cache hits that predated
the inflammation rollout, and the barcode / saved-food / quick-log / manual /
OCR paths that funnel through /log-direct without scoring. The Daily and
food-history UIs then render no inflammation pill (and no Health pill) for
those meals.

This script re-runs the SAME enrichment the live app uses
(services.food_score_enrichment.enrich_food_log_scores) over every NULL-score
row. That function:
  * prefers the free cache stack (198k-row override DB) — ~95% of rows resolve
    with NO Gemini call;
  * only calls Gemini on the cache-miss tail;
  * writes a deterministic health_score when the model omits one, so a row is
    never left without a health score (and therefore never re-selected forever);
  * marks score_status='unavailable' on rows Gemini genuinely cannot score.

Idempotent + resumable: it only ever fills NULL columns (never macros), so
Ctrl-C and re-run is safe and picks up where it left off. Rows already marked
score_status='unavailable' are skipped (when that column exists).

Run:
    cd /Users/saichetangrandhe/AIFitnessCoach
    backend/.venv/bin/python -m backend.scripts.backfill_food_log_scores --dry-run
    backend/.venv/bin/python -m backend.scripts.backfill_food_log_scores --limit 200
    backend/.venv/bin/python -m backend.scripts.backfill_food_log_scores

Flags:
    --dry-run        Count candidate rows only; make no changes.
    --limit N        Process at most N rows (default: all).
    --concurrency N  Concurrent enrichment tasks (default: 8).

Env (loaded from backend/.env):
    SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY (via core.db.get_supabase_db)
    GEMINI_API_KEY (only for the cache-miss tail)
"""
from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path

from dotenv import load_dotenv

# Bootstrap sys.path so `from core.db import ...` works as a module or file.
ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")
sys.path.insert(0, str(BACKEND))

from core.db import get_supabase_db  # noqa: E402
from core.logger import get_logger  # noqa: E402
from services.food_score_enrichment import enrich_food_log_scores  # noqa: E402

logger = get_logger(__name__)

# Supabase PostgREST caps a single response at 1000 rows.
PAGE = 1000

# Rows missing EITHER headline score. PostgREST `or` filter syntax.
_MISSING_FILTER = "inflammation_score.is.null,health_score.is.null"


def _score_status_exists(db) -> bool:
    """True when the food_logs.score_status column exists. Older deploys may
    not have it yet (the enrichment code defends against this too), in which
    case we cannot filter out permanently-unavailable rows — they'll be
    retried, which is harmless (the enrich fn re-marks them)."""
    try:
        db.client.table("food_logs").select("score_status").limit(1).execute()
        return True
    except Exception:
        return False


def _base_query(db, has_status: bool):
    q = (
        db.client.table("food_logs")
        .select("id,user_id")
        .or_(_MISSING_FILTER)
    )
    if has_status:
        # Skip rows Gemini already declared unscoreable so we don't loop.
        q = q.neq("score_status", "unavailable")
    # Oldest-first so the user's history fills in chronologically.
    return q.order("created_at", desc=False)


async def _count(db, has_status: bool) -> int:
    # PostgREST exact count via a head/count call.
    q = db.client.table("food_logs").select("id", count="exact").or_(_MISSING_FILTER)
    if has_status:
        q = q.neq("score_status", "unavailable")
    res = q.limit(1).execute()
    return res.count or 0


async def _fetch_candidates(db, has_status: bool, limit: int | None) -> list[dict]:
    rows: list[dict] = []
    offset = 0
    while True:
        page_size = PAGE
        if limit is not None:
            remaining = limit - len(rows)
            if remaining <= 0:
                break
            page_size = min(PAGE, remaining)
        res = (
            _base_query(db, has_status)
            .range(offset, offset + page_size - 1)
            .execute()
        )
        batch = res.data or []
        rows.extend(batch)
        if len(batch) < page_size:
            break
        offset += page_size
    return rows


async def main() -> None:
    parser = argparse.ArgumentParser(description="Backfill food_log inflammation + health scores")
    parser.add_argument("--dry-run", action="store_true", help="Count candidates only; no writes")
    parser.add_argument("--limit", type=int, default=None, help="Max rows to process")
    parser.add_argument("--concurrency", type=int, default=8, help="Concurrent enrichment tasks")
    args = parser.parse_args()

    db = get_supabase_db()
    has_status = _score_status_exists(db)
    if not has_status:
        logger.warning(
            "[backfill] food_logs.score_status column not found — cannot skip "
            "previously-unavailable rows (they'll be retried, which is safe)."
        )

    total = await _count(db, has_status)
    print(f"Candidate rows (inflammation_score OR health_score NULL): {total}")
    print(
        "Note: ~95% resolve from the free override-DB cache; only the "
        "cache-miss tail calls Gemini (~$0.0003/row Flash-Lite)."
    )
    if args.dry_run:
        print("Dry run — no changes made.")
        return
    if total == 0:
        print("Nothing to backfill.")
        return

    candidates = await _fetch_candidates(db, has_status, args.limit)
    print(f"Processing {len(candidates)} rows with concurrency={args.concurrency}...")

    sem = asyncio.Semaphore(args.concurrency)
    enriched = 0
    skipped = 0
    failed = 0
    done = 0
    lock = asyncio.Lock()

    async def _run(rowid: str, user_id: str) -> None:
        nonlocal enriched, skipped, failed, done
        async with sem:
            try:
                ok = await enrich_food_log_scores(rowid, user_id)
            except Exception as e:  # noqa: BLE001
                ok = False
                logger.warning(f"[backfill] {rowid} raised: {e}")
            async with lock:
                done += 1
                if ok:
                    enriched += 1
                else:
                    # Either already-scored on re-check, too sparse, or Gemini
                    # marked it unavailable — all non-fatal no-ops.
                    skipped += 1
                if done % 100 == 0 or done == len(candidates):
                    print(
                        f"  {done}/{len(candidates)} — enriched={enriched} "
                        f"skipped/no-op={skipped}",
                        flush=True,
                    )

    await asyncio.gather(
        *[
            _run(r["id"], r["user_id"])
            for r in candidates
            if r.get("id") and r.get("user_id")
        ]
    )

    print(
        f"\nDone. enriched={enriched} skipped/no-op={skipped} of {len(candidates)} processed."
    )
    remaining = await _count(db, has_status)
    print(f"Remaining NULL-score rows: {remaining} (re-run to continue).")


if __name__ == "__main__":
    asyncio.run(main())
