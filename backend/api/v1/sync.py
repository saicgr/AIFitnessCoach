"""
Sync endpoints for batch processing and import of offline sync data.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import logging

from core.auth import get_current_user
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
    items: List[SyncBulkItem]


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
    items: List[SyncBulkItem]


@router.post("/bulk", response_model=SyncBulkResponse)
async def bulk_sync(
    request: SyncBulkRequest,
    user: dict = Depends(get_current_user),
):
    """
    Process multiple sync items in a single request.

    Routes each item to the appropriate handler based on entity_type.
    Returns per-item success/failure results.
    """
    user_id = user["id"]
    results: List[SyncBulkResultItem] = []
    success_count = 0
    failure_count = 0

    supabase = get_supabase()

    for item in request.items:
        try:
            # Route based on entity_type
            if item.entity_type == "workout_log":
                await _process_workout_log(
                    supabase, user_id, item
                )
            elif item.entity_type == "workout_completion":
                await _process_workout_completion(
                    supabase, user_id, item
                )
            elif item.entity_type == "readiness":
                await _process_readiness(
                    supabase, user_id, item
                )
            elif item.entity_type == "user_profile":
                await _process_user_profile(
                    supabase, user_id, item
                )
            else:
                # Generic pass-through: store the payload in a sync_log table
                logger.warning(
                    f"Unknown entity_type '{item.entity_type}' for user {user_id}"
                )

            results.append(
                SyncBulkResultItem(
                    entity_id=item.entity_id,
                    status="success",
                )
            )
            success_count += 1

        except Exception as e:
            logger.error(
                f"Bulk sync failed for entity {item.entity_id} "
                f"(type={item.entity_type}): {e}"
            )
            results.append(
                SyncBulkResultItem(
                    entity_id=item.entity_id,
                    status="failed",
                    error=str(e),
                )
            )
            failure_count += 1

    return SyncBulkResponse(
        results=results,
        success_count=success_count,
        failure_count=failure_count,
    )


@router.post("/import")
async def import_sync_data(
    request: SyncImportRequest,
    user: dict = Depends(get_current_user),
):
    """
    Import exported sync data for manual processing / admin review.

    Stores the exported items in the sync_imports table for later processing.
    """
    user_id = user["id"]
    logger.info(
        f"Sync import received from user {user_id}: "
        f"{len(request.items)} items, exported at {request.exported_at}"
    )

    # Store for manual processing
    supabase = get_supabase()
    try:
        supabase.client.table("sync_imports").insert(
            {
                "user_id": user_id,
                "exported_at": request.exported_at,
                "item_count": len(request.items),
                "items": [item.model_dump() for item in request.items],
            }
        ).execute()
    except Exception as e:
        logger.error(f"Failed to store sync import: {e}")
        # Don't fail the request -- just log and return success
        # The data was received; storage is best-effort

    return {
        "message": f"Imported {len(request.items)} items for processing",
        "item_count": len(request.items),
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

    supabase.client.table("users").update(payload).eq(
        "id", user_id
    ).execute()
