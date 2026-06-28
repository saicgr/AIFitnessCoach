"""Async job orchestration for the nutrition importer.

Mirrors the media-jobs pattern: POST creates a job + kicks an async parse task;
the client polls; POST .../commit kicks an async commit task. Blocking supabase
+ CPU parsing run via ``asyncio.to_thread`` so the event loop never stalls.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import date as date_cls, datetime, timezone

from core.db import get_supabase_db
from . import bulk
from .parsers import (
    NormalizedFoodRow,
    NormalizedWeightRow,
    ParseResult,
    parse_export,
)

logger = logging.getLogger(__name__)
_TABLE = "nutrition_import_jobs"


# ── serialization between parse and commit ───────────────────────────────────

def _food_to_json(r: NormalizedFoodRow) -> dict:
    return {"d": r.date.isoformat(), "meal": r.meal, "name": r.name,
            "cal": r.calories, "p": r.protein_g, "c": r.carbs_g,
            "f": r.fat_g, "fib": r.fiber_g, "micros": r.micros}


def _food_from_json(j: dict) -> NormalizedFoodRow:
    return NormalizedFoodRow(
        date=date_cls.fromisoformat(j["d"]), meal=j["meal"], name=j["name"],
        calories=j.get("cal"), protein_g=j.get("p"), carbs_g=j.get("c"),
        fat_g=j.get("f"), fiber_g=j.get("fib"), micros=j.get("micros") or {})


def _weight_to_json(r: NormalizedWeightRow) -> dict:
    return {"d": r.date.isoformat(), "kg": r.weight_kg}


def _weight_from_json(j: dict) -> NormalizedWeightRow:
    return NormalizedWeightRow(date=date_cls.fromisoformat(j["d"]), weight_kg=j["kg"])


# ── job CRUD ─────────────────────────────────────────────────────────────────

def create_job(user_id: str, source: str) -> str:
    db = get_supabase_db()
    res = db.client.table(_TABLE).insert(
        {"user_id": user_id, "source": source, "status": "parsing"}
    ).execute()
    return res.data[0]["id"]


def _update(job_id: str, **fields) -> None:
    fields["updated_at"] = datetime.now(timezone.utc).isoformat()
    get_supabase_db().client.table(_TABLE).update(fields).eq("id", job_id).execute()


def get_job(job_id: str, user_id: str) -> dict | None:
    res = (
        get_supabase_db().client.table(_TABLE).select("*")
        .eq("id", job_id).eq("user_id", user_id).limit(1).execute()
    )
    return (res.data or [None])[0]


# ── runners ──────────────────────────────────────────────────────────────────

async def run_parse_job(job_id: str, user_id: str, *, data=None, filename="",
                        source="auto", apple_health_rows=None) -> None:
    try:
        result: ParseResult = await asyncio.to_thread(
            parse_export, data=data, filename=filename, source=source,
            apple_health_rows=apple_health_rows,
        )
        if result.errors and not result.food_rows and not result.weight_rows:
            await asyncio.to_thread(_update, job_id, status="error",
                                    error="; ".join(result.errors))
            return
        preview = await asyncio.to_thread(
            bulk.summarize, user_id, result.source, result.food_rows,
            result.weight_rows, result.unmapped_columns, result.unreadable_rows,
        )
        await asyncio.to_thread(
            _update, job_id,
            source=result.source, status="preview_ready", preview=preview,
            parsed_rows=[_food_to_json(r) for r in result.food_rows],
            parsed_weight=[_weight_to_json(r) for r in result.weight_rows],
        )
    except Exception as e:  # noqa: BLE001
        logger.error("import parse job %s failed: %s", job_id, e, exc_info=True)
        await asyncio.to_thread(_update, job_id, status="error", error=str(e))


async def run_commit_job(job_id: str, user_id: str, *, overlap_strategy="skip",
                         include_weight=False) -> None:
    try:
        await asyncio.to_thread(_update, job_id, status="committing")
        job = await asyncio.to_thread(get_job, job_id, user_id)
        if not job:
            return
        source = job["source"]
        food_rows = [_food_from_json(j) for j in (job.get("parsed_rows") or [])]
        weight_rows = [_weight_from_json(j) for j in (job.get("parsed_weight") or [])]

        food_res = await asyncio.to_thread(
            bulk.commit_food, user_id, source, food_rows, overlap_strategy)
        weight_imported = 0
        if include_weight:
            weight_imported = await asyncio.to_thread(
                bulk.commit_weight, user_id, source, weight_rows)

        # History-only: invalidate the per-day summary cache so imported days
        # render, but DO NOT touch streak/XP/scoring side effects.
        try:
            from api.v1.nutrition.summaries import invalidate_daily_summary_cache
            for d in food_res.get("dates", []):
                await invalidate_daily_summary_cache(user_id, d)
        except Exception as e:  # noqa: BLE001
            logger.warning("summary cache invalidation skipped: %s", e)

        result = {
            "imported": food_res["imported"], "skipped": food_res["skipped"],
            "replaced": food_res["replaced"], "failed": food_res["failed"],
            "weight_imported": weight_imported,
        }
        await asyncio.to_thread(_update, job_id, status="done", result=result,
                                parsed_rows=None, parsed_weight=None)
    except Exception as e:  # noqa: BLE001
        logger.error("import commit job %s failed: %s", job_id, e, exc_info=True)
        await asyncio.to_thread(_update, job_id, status="error", error=str(e))
