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
            payload = {**item.payload, "user_id": user_id}
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

    Stores the exported items in the sync_imports table for later processing.
    """
    user_id = user["id"]
    logger.info(
        f"Sync import received from user {user_id}: "
        f"{len(body.items)} items, exported at {body.exported_at}"
    )

    # Store for manual processing
    supabase = get_supabase()
    try:
        supabase.client.table("sync_imports").insert(
            {
                "user_id": user_id,
                "exported_at": body.exported_at,
                "item_count": len(body.items),
                "items": [item.model_dump() for item in body.items],
            }
        ).execute()
    except Exception as e:
        logger.error(f"Failed to store sync import: {e}", exc_info=True)
        # Don't fail the request -- just log and return success
        # The data was received; storage is best-effort

    return {
        "message": f"Imported {len(body.items)} items for processing",
        "item_count": len(body.items),
    }


# ---------------------------------------------------------------------------
# Internal handlers for each entity type
# ---------------------------------------------------------------------------


async def _process_workout_log(supabase, user_id: str, item: SyncBulkItem):
    """Process a workout_log sync item."""
    payload = item.payload
    payload["user_id"] = user_id

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
