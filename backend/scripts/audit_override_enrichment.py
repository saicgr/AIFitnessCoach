"""Post-hoc quality audit for food_nutrition_overrides enrichment data.

Streams every backfilled row, runs the deterministic validator from
`_enrichment_validator.py`, and reports:
  * per-rule failure counts (errors + warnings)
  * top-N sample failures per rule
  * overall pass rate

Usage:
    cd /Users/saichetangrandhe/AIFitnessCoach
    backend/.venv/bin/python -m backend.scripts.audit_override_enrichment

    # Dry-run by default. Pass --reset-bad to NULL enrichment_backfilled_at
    # on rows with ERROR-severity findings so the backfill picks them up
    # again on the next run.
    backend/.venv/bin/python -m backend.scripts.audit_override_enrichment --reset-bad

    # Re-validate every backfilled row against current validator rules.
    # NULLs the enrichment payload + stamps enrichment_last_violation on rows
    # that fail under the new rules — without calling Gemini. Lets you tighten
    # rules later and clean up old backfilled data cheaply.
    backend/.venv/bin/python -m backend.scripts.audit_override_enrichment --revalidate

    # Limit to most recent N rows for fast feedback during dev:
    AUDIT_LIMIT=500 backend/.venv/bin/python -m backend.scripts.audit_override_enrichment
"""
from __future__ import annotations

import argparse
import asyncio
import logging
import os
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple

import asyncpg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")
sys.path.insert(0, str(BACKEND))

from scripts._enrichment_validator import (  # noqa: E402
    Finding, Severity, validate, has_errors,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("audit_enrichment")

AUDIT_LIMIT = int(os.environ.get("AUDIT_LIMIT", "0"))  # 0 = no limit
SAMPLES_PER_RULE = 10


FETCH_SQL = """
SELECT
  id,
  food_name_normalized,
  display_name,
  fat_per_100g,
  carbs_per_100g,
  sugar_per_100g,
  calories_per_100g,
  inflammation_score,
  inflammation_triggers,
  glycemic_load,
  fodmap_rating,
  fodmap_reason,
  added_sugar_g,
  is_ultra_processed,
  rating,
  rating_reason
FROM food_nutrition_overrides
WHERE enrichment_backfilled_at IS NOT NULL
ORDER BY id
"""


def _row_to_item(r: dict) -> dict:
    """Reverse the backfill script's sentinel translation so the validator
    sees pre-write shape (glycemic_load=-1, fodmap_reason=''). DB stores
    NULLs for both — translate back here."""
    return {
        "row_id": r["id"],
        "inflammation_score": r["inflammation_score"],
        "inflammation_triggers": list(r["inflammation_triggers"] or []),
        "glycemic_load": -1 if r["glycemic_load"] is None else r["glycemic_load"],
        "fodmap_rating": r["fodmap_rating"],
        "fodmap_reason": "" if r["fodmap_reason"] is None else r["fodmap_reason"],
        "added_sugar_g": r["added_sugar_g"],
        "is_ultra_processed": r["is_ultra_processed"],
        "rating": r["rating"],
        "rating_reason": r["rating_reason"],
    }


RESET_BAD_SQL = """
UPDATE food_nutrition_overrides SET
  inflammation_score = NULL,
  inflammation_triggers = NULL,
  glycemic_load = NULL,
  fodmap_rating = NULL,
  fodmap_reason = NULL,
  added_sugar_g = NULL,
  is_ultra_processed = NULL,
  rating = NULL,
  rating_reason = NULL,
  enrichment_backfilled_at = NULL,
  enrichment_last_violation = v.violation,
  -- --reset-bad zeroes attempts so user-driven cleanup gives a fresh shot.
  -- --revalidate keeps attempts intact so cap still applies.
  enrichment_attempts = CASE WHEN $2::bool THEN 0 ELSE enrichment_attempts END
FROM jsonb_to_recordset($1::jsonb) AS v(row_id INTEGER, violation TEXT)
WHERE food_nutrition_overrides.id = v.row_id;
"""


async def main(reset_bad: bool, revalidate: bool, reset_parked: bool = False) -> int:
    db_url = os.environ["DATABASE_URL"].replace(
        "postgresql+asyncpg://", "postgresql://"
    )
    conn = await asyncpg.connect(db_url, statement_cache_size=0)
    try:
        # --reset-parked is a pure SQL operation on rows that have NO data
        # to validate (they hit the 3-attempt cap). Handle it up-front and
        # exit, before the audit-on-backfilled-rows path.
        if reset_parked:
            cnt = await conn.fetchval(
                "SELECT COUNT(*) FROM food_nutrition_overrides "
                "WHERE enrichment_backfilled_at IS NULL "
                "AND enrichment_attempts >= 3"
            )
            if cnt == 0:
                logger.info("[reset-parked] no parked rows — nothing to do")
                return 0
            logger.info(
                "[reset-parked] resetting enrichment_attempts to 0 on %d "
                "parked rows so the next backfill picks them up", cnt,
            )
            await conn.execute("""
                UPDATE food_nutrition_overrides
                SET enrichment_attempts = 0,
                    enrichment_last_violation = NULL
                WHERE enrichment_backfilled_at IS NULL
                  AND enrichment_attempts >= 3
            """)
            logger.info("[reset-parked] done")
            return 0

        n_total = await conn.fetchval(
            "SELECT COUNT(*) FROM food_nutrition_overrides "
            "WHERE enrichment_backfilled_at IS NOT NULL"
        )
        if AUDIT_LIMIT > 0:
            sql = FETCH_SQL + f" LIMIT {AUDIT_LIMIT}"
            logger.info("[audit] limited to most recent %d rows", AUDIT_LIMIT)
        else:
            sql = FETCH_SQL
        logger.info("[audit] streaming %d backfilled rows", n_total)

        rows = await conn.fetch(sql)

        per_rule: Dict[str, int] = defaultdict(int)
        per_rule_severity: Dict[str, Severity] = {}
        samples: Dict[str, List[Tuple[int, str]]] = defaultdict(list)
        rows_with_error: List[int] = []
        rows_with_any: List[int] = []
        rows_clean = 0

        for r in rows:
            source = dict(r)
            item = _row_to_item(source)
            findings = validate(item, source)
            if not findings:
                rows_clean += 1
                continue
            rows_with_any.append(r["id"])
            if has_errors(findings):
                rows_with_error.append(r["id"])
            for f in findings:
                per_rule[f.rule] += 1
                per_rule_severity[f.rule] = f.severity
                if len(samples[f.rule]) < SAMPLES_PER_RULE:
                    samples[f.rule].append((r["id"], f.message))

        n = len(rows)
        logger.info("[audit] === SUMMARY ===")
        logger.info("[audit]   audited rows:           %d", n)
        logger.info("[audit]   clean (no findings):    %d (%.1f%%)",
                    rows_clean, 100*rows_clean/max(n,1))
        logger.info("[audit]   any finding:            %d (%.1f%%)",
                    len(rows_with_any), 100*len(rows_with_any)/max(n,1))
        logger.info("[audit]   ERROR-severity:         %d (%.1f%%)",
                    len(rows_with_error), 100*len(rows_with_error)/max(n,1))

        logger.info("[audit] === PER-RULE COUNTS ===")
        for rule, cnt in sorted(per_rule.items(), key=lambda kv: -kv[1]):
            sev = per_rule_severity[rule].value.upper()
            logger.info("  [%s] %-40s %d", sev, rule, cnt)

        logger.info("[audit] === SAMPLE FAILURES (top %d per rule) ===",
                    SAMPLES_PER_RULE)
        for rule in sorted(samples.keys()):
            logger.info("  --- %s ---", rule)
            for row_id, msg in samples[rule]:
                logger.info("    id=%d  %s", row_id, msg)

        if (reset_bad or revalidate) and rows_with_error:
            mode = "reset-bad (clears attempts counter)" if reset_bad else \
                   "revalidate (keeps attempts counter — respects retry cap)"
            logger.info(
                "[audit] --%s: NULLing %d rows with ERROR findings",
                mode, len(rows_with_error),
            )
            # Build (id, violation) payload from the per-row findings
            # captured earlier. We need the actual violation strings so
            # enrichment_last_violation reflects the current audit reasons.
            id_to_violation: dict = {}
            for r in rows:
                if r["id"] not in rows_with_error:
                    continue
                source = dict(r)
                item = _row_to_item(source)
                findings = validate(item, source)
                err_msgs = [
                    f"{f.rule}: {f.message}"
                    for f in findings if f.severity == Severity.ERROR
                ]
                id_to_violation[r["id"]] = " | ".join(err_msgs)
            import json
            payload = json.dumps([
                {"row_id": rid, "violation": viol}
                for rid, viol in id_to_violation.items()
            ])
            await conn.execute(RESET_BAD_SQL, payload, reset_bad)
            logger.info("[audit] reset complete")
        elif rows_with_error:
            logger.info(
                "[audit] %d rows have ERROR findings — re-run with "
                "--reset-bad (resets attempts) or --revalidate (keeps "
                "attempts, respects cap) to NULL them for retry",
                len(rows_with_error),
            )

        return 0
    finally:
        await conn.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--reset-bad", action="store_true",
        help="NULL enrichment fields + timestamp + reset enrichment_attempts "
             "to 0 on rows with ERROR findings. Use this when validator rules "
             "change in a meaningful way and you want to give all bad rows "
             "a fresh attempt budget.",
    )
    parser.add_argument(
        "--revalidate", action="store_true",
        help="Same NULL-on-failure as --reset-bad, but KEEPS the existing "
             "enrichment_attempts counter intact so the retry cap still "
             "applies. Use this for routine re-checks: rows that already "
             "exhausted their 3 attempts stay parked.",
    )
    parser.add_argument(
        "--reset-parked", action="store_true",
        help="Reset enrichment_attempts to 0 on rows that hit the 3-attempt "
             "cap (parked rows). Useful after loosening validator rules so "
             "the next backfill run can retry those rows. Operates ONLY on "
             "rows where enrichment_backfilled_at IS NULL AND attempts >= 3 "
             "— does not touch successfully enriched rows.",
    )
    args = parser.parse_args()
    if sum([args.reset_bad, args.revalidate, args.reset_parked]) > 1:
        parser.error("--reset-bad, --revalidate, --reset-parked are mutually exclusive")
    sys.exit(asyncio.run(main(
        reset_bad=args.reset_bad,
        revalidate=args.revalidate,
        reset_parked=args.reset_parked,
    )))
