"""
GET /api/v1/users/{user_id}/snapped-equipment

Paginated list of the user's snapped-equipment history (Issue #1, Task #6).
Used by the "Snapped" tab in the swap/add sheets so the user can re-rank a
prior canonical equipment against the current workout context without
re-uploading.

Cursor format: ISO-8601 timestamp of the last item (classified_at). Caller
passes ?cursor=<ts> on subsequent pages; rows older than the cursor are
returned.
"""
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter()


class SnapHistoryItem(BaseModel):
    id: str
    s3_key: str
    image_url: Optional[str] = None
    canonical_name: str
    confidence: Optional[float] = None
    vision_label: Optional[str] = None
    last_exercise_id: Optional[str] = None
    created_via: Optional[str] = None
    classified_at: str


class SnapHistoryResponse(BaseModel):
    items: list[SnapHistoryItem]
    next_cursor: Optional[str] = None


def _presign_s3_key(s3_key: str) -> Optional[str]:
    """Return a short-lived presigned URL for the snapped image."""
    try:
        import boto3
        from botocore.config import Config as BotoConfig
        from core.config import get_settings

        settings = get_settings()
        s3 = boto3.client(
            "s3",
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_default_region,
            config=BotoConfig(signature_version="s3v4"),
        )
        return s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.s3_bucket_name, "Key": s3_key},
            ExpiresIn=3600,
        )
    except Exception as e:
        logger.debug(f"[SnappedEquip] presign failed for {s3_key}: {e}")
        return None


@router.get(
    "/{user_id}/snapped-equipment",
    response_model=SnapHistoryResponse,
)
async def list_snapped_equipment(
    user_id: str,
    limit: int = Query(50, ge=1, le=100),
    cursor: Optional[str] = Query(None, description="ISO-8601 timestamp from previous page"),
    current_user: dict = Depends(get_current_user),
):
    if current_user["id"] != user_id:
        raise HTTPException(status_code=403, detail="Cannot read another user's snaps")

    db = get_supabase_db()
    query = (
        db.client.table("snapped_equipment")
        .select(
            "id,s3_key,canonical_name,confidence,vision_label,"
            "last_exercise_id,created_via,classified_at"
        )
        .eq("user_id", user_id)
        # Hide the "rejected" book-keeping rows from the user-facing list.
        .neq("canonical_name", "__not_equipment__")
        .neq("canonical_name", "__unmatched__")
        .order("classified_at", desc=True)
        .limit(limit + 1)  # +1 so we know whether to emit a next_cursor
    )
    if cursor:
        query = query.lt("classified_at", cursor)

    try:
        result = query.execute()
    except Exception as e:
        logger.error(f"❌ [SnappedEquip] DB query failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to load snap history")

    rows = list(result.data or [])
    next_cursor: Optional[str] = None
    if len(rows) > limit:
        next_cursor = rows[limit - 1]["classified_at"]
        rows = rows[:limit]

    items: list[SnapHistoryItem] = []
    for r in rows:
        items.append(
            SnapHistoryItem(
                id=r["id"],
                s3_key=r["s3_key"],
                image_url=_presign_s3_key(r["s3_key"]),
                canonical_name=r["canonical_name"],
                confidence=r.get("confidence"),
                vision_label=r.get("vision_label"),
                last_exercise_id=r.get("last_exercise_id"),
                created_via=r.get("created_via"),
                classified_at=r["classified_at"],
            )
        )

    return SnapHistoryResponse(items=items, next_cursor=next_cursor)
