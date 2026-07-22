"""Bulk grouping + commit for the nutrition importer.

Pure-DB synchronous functions (supabase-py .execute() is blocking); the async job
runner calls these via ``asyncio.to_thread`` and then invalidates caches. Imports
are HISTORY ONLY — they populate food_logs/weight_logs + trends, but deliberately
skip every per-log side effect (streak, XP, scoring, achievements). Do NOT wire
scoring into this path.
"""
from __future__ import annotations

import logging
from collections import OrderedDict
from datetime import date as date_cls

from core.db import get_supabase_db
from .normalize import local_noon_iso
from .parsers import NormalizedWeightRow
from .transform import group_food_logs, make_key as _key  # noqa: F401

logger = logging.getLogger(__name__)
_CHUNK = 400


def summarize(user_id: str, source: str, food_rows, weight_rows, unmapped, unreadable) -> dict:
    """Build the dry-run preview payload (no writes)."""
    logs = group_food_logs(user_id, source, food_rows)
    dates = sorted({l["_date"] for l in logs})
    overlap = _existing_log_dates(user_id, dates) if dates else set()
    sample = [
        {"date": l["_date"], "meal": l["meal_type"],
         "calories": l["total_calories"], "items": len(l["food_items"])}
        for l in logs[:8]
    ]
    return {
        "count": len(logs),
        "days": len(dates),
        "date_range": [dates[0], dates[-1]] if dates else None,
        "sample_rows": sample,
        "unmapped_columns": unmapped,
        "overlap_days": len(overlap),
        "weight_rows": len({w.date for w in weight_rows}),
        "unreadable_rows": unreadable,
    }


def _existing_log_dates(user_id: str, dates: list[str]) -> set[str]:
    """Distinct local dates (by logged_at::date) that already have non-deleted
    food logs, within the imported date span."""
    if not dates:
        return set()
    db = get_supabase_db()
    lo, hi = dates[0], dates[-1]
    try:
        res = (
            db.client.table("food_logs")
            .select("logged_at")
            .eq("user_id", user_id)
            .is_("deleted_at", "null")
            .gte("logged_at", f"{lo}T00:00:00")
            .lte("logged_at", f"{hi}T23:59:59")
            .execute()
        )
        return {str(r["logged_at"])[:10] for r in (res.data or [])}
    except Exception as e:  # noqa: BLE001
        logger.warning("overlap scan failed: %s", e)
        return set()


def _existing_idem_keys(user_id: str, keys: list[str]) -> set[str]:
    db = get_supabase_db()
    found: set[str] = set()
    for i in range(0, len(keys), 150):
        chunk = keys[i:i + 150]
        try:
            res = (
                db.client.table("food_logs")
                # Tombstone read (explicit opt-out of the soft-delete guard):
                # this pre-filter exists to keep a re-import from colliding in
                # the food_logs idempotency_key unique index, and that index has
                # NO deleted_at predicate. If the guard hid soft-deleted rows,
                # their keys would be invisible here yet still collide on insert,
                # turning a re-import of a previously-deleted meal into a unique
                # violation instead of the intended de-dupe no-op.
                .include_soft_deleted()
                .select("idempotency_key")
                .eq("user_id", user_id)
                .in_("idempotency_key", chunk)
                .execute()
            )
            found |= {r["idempotency_key"] for r in (res.data or []) if r.get("idempotency_key")}
        except Exception as e:  # noqa: BLE001
            logger.warning("idem prefilter failed: %s", e)
    return found


def commit_food(user_id: str, source: str, food_rows, overlap_strategy: str) -> dict:
    """Apply overlap strategy + idempotency, then bulk insert. Returns counts +
    the set of affected dates (for cache invalidation)."""
    db = get_supabase_db()
    logs = group_food_logs(user_id, source, food_rows)
    if not logs:
        return {"imported": 0, "skipped": 0, "replaced": 0, "failed": 0, "dates": []}

    all_dates = sorted({l["_date"] for l in logs})
    existing = _existing_log_dates(user_id, all_dates)
    skipped = replaced = 0

    if overlap_strategy == "skip":
        before = len(logs)
        logs = [l for l in logs if l["_date"] not in existing]
        skipped = before - len(logs)
    elif overlap_strategy == "replace":
        overlap_dates = sorted({l["_date"] for l in logs} & existing)
        replaced = _soft_delete_dates(user_id, overlap_dates)
    # merge: insert alongside (no-op here)

    # Idempotency pre-filter (also makes re-import a no-op).
    keys = [l["idempotency_key"] for l in logs]
    dupes = _existing_idem_keys(user_id, keys)
    logs = [l for l in logs if l["idempotency_key"] not in dupes]

    affected = sorted({l["_date"] for l in logs})
    imported = failed = 0
    for i in range(0, len(logs), _CHUNK):
        chunk = [{k: v for k, v in l.items() if k != "_date"} for l in logs[i:i + _CHUNK]]
        try:
            db.client.table("food_logs").insert(chunk).execute()
            imported += len(chunk)
        except Exception as e:  # noqa: BLE001
            logger.error("food bulk insert chunk failed: %s", e)
            failed += len(chunk)

    return {"imported": imported, "skipped": skipped, "replaced": replaced,
            "failed": failed, "dates": affected}


def _soft_delete_dates(user_id: str, dates: list[str]) -> int:
    if not dates:
        return 0
    db = get_supabase_db()
    n = 0
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()
    for d in dates:
        try:
            res = (
                db.client.table("food_logs")
                .update({"deleted_at": now})
                .eq("user_id", user_id)
                .is_("deleted_at", "null")
                .gte("logged_at", f"{d}T00:00:00")
                .lte("logged_at", f"{d}T23:59:59")
                .execute()
            )
            n += len(res.data or [])
        except Exception as e:  # noqa: BLE001
            logger.warning("soft-delete failed for %s: %s", d, e)
    return n


def commit_weight(user_id: str, source: str, weight_rows: list[NormalizedWeightRow]) -> int:
    """One weight entry per date (last wins), idempotent. Returns inserted count."""
    if not weight_rows:
        return 0
    db = get_supabase_db()
    by_date: "OrderedDict[date_cls, float]" = OrderedDict()
    for w in weight_rows:
        by_date[w.date] = w.weight_kg
    rows = []
    for d, kg in by_date.items():
        rows.append({
            "user_id": user_id,
            "weight_kg": round(kg, 2),
            "logged_at": local_noon_iso(d),
            "source": "import",
            "idempotency_key": _key(user_id, source, d.isoformat(), "wt"),
        })
    keys = [r["idempotency_key"] for r in rows]
    dupes: set[str] = set()
    for i in range(0, len(keys), 150):
        try:
            res = (
                db.client.table("weight_logs").select("idempotency_key")
                .eq("user_id", user_id).in_("idempotency_key", keys[i:i + 150]).execute()
            )
            dupes |= {r["idempotency_key"] for r in (res.data or []) if r.get("idempotency_key")}
        except Exception as e:  # noqa: BLE001
            logger.warning("weight idem prefilter failed: %s", e)
    rows = [r for r in rows if r["idempotency_key"] not in dupes]
    inserted = 0
    for i in range(0, len(rows), _CHUNK):
        try:
            db.client.table("weight_logs").insert(rows[i:i + _CHUNK]).execute()
            inserted += len(rows[i:i + _CHUNK])
        except Exception as e:  # noqa: BLE001
            logger.error("weight bulk insert failed: %s", e)
    return inserted
