"""
Sync endpoints for batch processing and import of offline sync data.
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from typing import List, Optional
import logging

from core.auth import get_current_user, verify_user_ownership
from core.rate_limiter import limiter
from core.supabase_client import get_supabase

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/sync", tags=["sync"])


class SyncBulkItem(BaseModel):
    operation_type: str
    entity_type: str
    entity_id: str
    http_method: str
    endpoint: str
    payload: dict
    created_at: str


class SyncBulkRequest(BaseModel):
    items: List[SyncBulkItem] = Field(..., max_length=100)


class SyncBulkResultItem(BaseModel):
    entity_id: str
    status: str
    error: Optional[str] = None


class SyncBulkResponse(BaseModel):
    results: List[SyncBulkResultItem]
    success_count: int
    failure_count: int


class SyncImportRequest(BaseModel):
    exported_at: str
    items: List[SyncBulkItem] = Field(..., max_length=100)


@router.post("/bulk", response_model=SyncBulkResponse)
@limiter.limit("10/minute")
async def bulk_sync(
    request: Request,
    body: SyncBulkRequest,
    user: dict = Depends(get_current_user),
):
    """
    Process multiple sync items in a single request.

    Items with simple insert/upsert semantics are batched into a single
    multi-row call per (entity_type, operation_type) bucket. Updates and
    deletes still fall through to per-item handlers because they target
    individual rows by id.
    """
    user_id = user["id"]
    results: List[SyncBulkResultItem] = []
    success_count = 0
    failure_count = 0

    supabase = get_supabase()

    # Bucket batchable upserts (workout_log create/insert + workout_completion +
    # readiness) so we can collapse a 100-item drain into a handful of multi-row
    # calls. Per-row updates and deletes go through the legacy path.
    workout_log_upserts: List[dict] = []
    workout_log_upsert_ids: List[str] = []
    workout_completion_upserts: List[dict] = []
    workout_completion_ids: List[str] = []
    readiness_upserts: List[dict] = []
    readiness_ids: List[str] = []
    fallback_items: List[SyncBulkItem] = []

    for item in body.items:
        if (
            item.entity_type == "workout_log"
            and item.operation_type in ("create", "insert")
        ):
            # Same server-side status derivation as the per-item fallback
            # handler below — this batched path is the one the offline queue
            # actually drains, so it must not be the hole in the wall.
            payload = _apply_derived_workout_log_status(
                {**item.payload, "user_id": user_id}
            )
            workout_log_upserts.append(payload)
            workout_log_upsert_ids.append(item.entity_id)
        elif item.entity_type == "workout_completion":
            payload = {**item.payload, "user_id": user_id}
            workout_completion_upserts.append(payload)
            workout_completion_ids.append(item.entity_id)
        elif item.entity_type == "readiness":
            payload = {**item.payload, "user_id": user_id}
            readiness_upserts.append(payload)
            readiness_ids.append(item.entity_id)
        else:
            fallback_items.append(item)

    def _flush_batch(table: str, rows: List[dict], ids: List[str], on_conflict: str):
        nonlocal success_count, failure_count
        if not rows:
            return
        try:
            supabase.client.table(table).upsert(
                rows, on_conflict=on_conflict
            ).execute()
            for entity_id in ids:
                results.append(SyncBulkResultItem(entity_id=entity_id, status="success"))
                success_count += 1
        except Exception as e:
            logger.error(
                f"Bulk sync batch upsert failed for {table} "
                f"({len(rows)} rows): {e}",
                exc_info=True,
            )
            for entity_id in ids:
                results.append(
                    SyncBulkResultItem(
                        entity_id=entity_id,
                        status="failed",
                        error="Batch upsert failed",
                    )
                )
                failure_count += 1

    _flush_batch("workout_logs", workout_log_upserts, workout_log_upsert_ids, "id")
    _flush_batch(
        "workout_completions",
        workout_completion_upserts,
        workout_completion_ids,
        "id",
    )
    _flush_batch(
        "readiness_scores",
        readiness_upserts,
        readiness_ids,
        "user_id,date",
    )

    for item in fallback_items:
        try:
            if item.entity_type == "workout_log":
                await _process_workout_log(supabase, user_id, item)
            elif item.entity_type == "user_profile":
                await _process_user_profile(supabase, user_id, item)
            else:
                logger.warning(
                    f"Unknown entity_type '{item.entity_type}' for user {user_id}"
                )

            results.append(
                SyncBulkResultItem(entity_id=item.entity_id, status="success")
            )
            success_count += 1
        except Exception as e:
            logger.error(
                f"Bulk sync failed for entity {item.entity_id} "
                f"(type={item.entity_type}): {e}",
                exc_info=True,
            )
            results.append(
                SyncBulkResultItem(
                    entity_id=item.entity_id,
                    status="failed",
                    error="Processing failed",
                )
            )
            failure_count += 1

    # E2E register row 80: the offline-replay path changes the same day-state
    # the coach card narrates, so it must bust the cached insight too.
    #
    # This is the sibling of the bust in workouts/crud_completion.py. A session
    # finished offline reaches the server HERE, not through /complete — and
    # migration 2390's trigger flips `workouts.is_completed` off the replayed
    # `workout_logs` row, so the training state genuinely changes without
    # /complete ever running. Without this, a user who trains offline sees a
    # coach card still telling them to start the workout they already finished.
    #
    # Gated on something actually landing (a bare no-op drain must not spend a
    # write), and fail-soft for the same reason as the /complete sibling: a
    # stale card must never fail a replay the client would then re-queue.
    if success_count and (workout_log_upsert_ids or workout_completion_ids or fallback_items):
        try:
            from api.v1.coach.daily_insight import invalidate_daily_insight_cache
            await invalidate_daily_insight_cache(user_id)
        except Exception as insight_err:
            logger.warning(
                f"[BulkSync] coach-insight cache bust failed for "
                f"user_id={user_id}: {insight_err}"
            )

    return SyncBulkResponse(
        results=results,
        success_count=success_count,
        failure_count=failure_count,
    )


@router.post("/import")
@limiter.limit("10/minute")
async def import_sync_data(
    request: Request,
    body: SyncImportRequest,
    user: dict = Depends(get_current_user),
):
    """
    Import exported sync data for manual processing / admin review.

    Degraded: there is no generic staging table for this admin-review dump
    (the existing import tables — workout_history_imports, nutrition_import_jobs
    — are entity-specific and don't fit a raw {exported_at, items[]} blob). The
    receipt is acknowledged and logged; durable storage awaits a `sync_imports`
    table (user_id, exported_at, item_count, items jsonb) — NEEDS-MIGRATION.
    """
    user_id = user["id"]
    logger.info(
        f"Sync import received from user {user_id}: "
        f"{len(body.items)} items, exported at {body.exported_at} "
        f"(not persisted — no sync_imports store)"
    )

    return {
        "message": f"Imported {len(body.items)} items for processing",
        "item_count": len(body.items),
    }


# ---------------------------------------------------------------------------
# Internal handlers for each entity type
# ---------------------------------------------------------------------------


def _sets_json_is_empty(value) -> bool:
    """True when a synced workout_log payload carries no logged sets."""
    if value is None:
        return True
    if isinstance(value, list):
        return len(value) == 0
    if isinstance(value, str):
        return value.strip() in ("", "[]", "null")
    if isinstance(value, dict):
        return len(value) == 0
    return False


def _apply_derived_workout_log_status(payload: dict) -> dict:
    """Derive `workout_logs.status` server-side — NEVER trust the client's.

    `workout_logs.status` used to DEFAULT to 'completed', and
    `trg_sync_workout_completion` (migration 2256) flips
    `workouts.is_completed = true` off that status. Because this handler
    upserts the offline client's payload VERBATIM, a queued row that simply
    omitted `status` — which is exactly what the Easy tier's first-set row
    looks like: `sets_json = '[]'` — inserted as 'completed' and marked the
    whole workout finished after one set. Migration 2390 flips the column
    default to 'in_progress' and adds an empty-sets guard to the trigger; this
    makes the SYNC WRITER agree with `POST /performance/workout-logs`
    (performance_db.py, `derived_status`) rather than depend on either.

    An empty set list is by definition not a finished session, so it can never
    sync as 'completed' regardless of what the queued payload claims.
    """
    if "sets_json" not in payload:
        # A partial update that does not touch the set list must not have a
        # status invented for it — leave whatever the row already holds.
        return payload
    payload["status"] = (
        "in_progress" if _sets_json_is_empty(payload.get("sets_json")) else "completed"
    )
    return payload


async def _process_workout_log(supabase, user_id: str, item: SyncBulkItem):
    """Process a workout_log sync item."""
    payload = item.payload
    payload["user_id"] = user_id
    _apply_derived_workout_log_status(payload)

    if item.operation_type in ("create", "insert"):
        supabase.client.table("workout_logs").upsert(
            payload, on_conflict="id"
        ).execute()
    elif item.operation_type == "update":
        supabase.client.table("workout_logs").update(payload).eq(
            "id", item.entity_id
        ).eq("user_id", user_id).execute()
    elif item.operation_type == "delete":
        supabase.client.table("workout_logs").delete().eq(
            "id", item.entity_id
        ).eq("user_id", user_id).execute()
    else:
        raise ValueError(f"Unknown operation: {item.operation_type}")


async def _process_workout_completion(
    supabase, user_id: str, item: SyncBulkItem
):
    """Process a workout_completion sync item."""
    payload = item.payload
    payload["user_id"] = user_id

    supabase.client.table("workout_completions").upsert(
        payload, on_conflict="id"
    ).execute()


async def _process_readiness(supabase, user_id: str, item: SyncBulkItem):
    """Process a readiness sync item."""
    payload = item.payload
    payload["user_id"] = user_id

    supabase.client.table("readiness_scores").upsert(
        payload, on_conflict="user_id,date"
    ).execute()


async def _process_user_profile(supabase, user_id: str, item: SyncBulkItem):
    """Process a user_profile sync item."""
    payload = item.payload

    # If this sync touches `equipment`, dual-write to `equipment_v2`
    # (text[]) so the new typed column stays current during the
    # multi-deploy schema migration. Skip when the field isn't present
    # so other profile updates pass through untouched.
    if "equipment" in payload:
        from api.v1.workouts.utils import equipment_dual_write_payload
        payload = {
            **payload,
            **equipment_dual_write_payload(payload["equipment"]),
        }

    supabase.client.table("users").update(payload).eq(
        "id", user_id
    ).execute()

    # The user record is cached for /today (preferences.workout_days,
    # equipment feed schedule resolution) — bust it so a profile sync is
    # visible on the next poll despite the 300s cache TTL.
    try:
        from api.v1.workouts.today import invalidate_today_workout_cache
        await invalidate_today_workout_cache(user_id)
    except Exception as e:
        logger.warning(f"[SYNC] today-cache invalidation failed for {user_id}: {e}")
