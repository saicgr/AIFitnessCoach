"""
Encryption Key Management endpoints.

Allows users to:
- Upload their X25519 public key
- Fetch another user's active public key
"""
from core.db import get_supabase_db

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from datetime import datetime

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.social import PublicKeyUpload, PublicKeyResponse

router = APIRouter()
logger = get_logger(__name__)


@router.post("/upload", response_model=PublicKeyResponse)
async def upload_public_key(
    request: PublicKeyUpload,
    user_id: str = Query(..., description="Current user's ID"),
    current_user: dict = Depends(get_current_user),
):
    """
    Upload a new X25519 public key.

    Revokes any previous active key and inserts a new one with incremented version.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"[Keys] Uploading public key for user {user_id}")

    try:
        db = get_supabase_db()

        # Get current max version for this user
        existing = db.client.table("user_encryption_keys").select(
            "key_version"
        ).eq("user_id", user_id).is_("revoked_at", "null").order(
            "key_version", desc=True
        ).limit(1).execute()

        new_version = 1
        if existing.data:
            old_version = existing.data[0]["key_version"]
            new_version = old_version + 1

            # Revoke old key
            db.client.table("user_encryption_keys").update({
                "revoked_at": datetime.utcnow().isoformat()
            }).eq("user_id", user_id).is_("revoked_at", "null").execute()

        # Insert new key
        result = db.client.table("user_encryption_keys").insert({
            "user_id": user_id,
            "public_key": request.public_key,
            "algorithm": request.algorithm,
            "key_version": new_version,
        }).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to store public key")

        row = result.data[0]

        logger.info(f"[Keys] Public key uploaded for user {user_id}, version {new_version}")

        return PublicKeyResponse(
            user_id=str(row["user_id"]),
            public_key=row["public_key"],
            algorithm=row["algorithm"],
            key_version=row["key_version"],
            created_at=row["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Keys] Failed to upload public key: {e}")
        raise safe_internal_error(e, "encryption_keys")


@router.get("/{target_user_id}", response_model=PublicKeyResponse)
async def get_public_key(
    target_user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Get a user's active (non-revoked) public encryption key.
    """
    logger.info(f"[Keys] Fetching public key for user {target_user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("user_encryption_keys").select(
            "*"
        ).eq("user_id", target_user_id).is_(
            "revoked_at", "null"
        ).order("key_version", desc=True).limit(1).execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="No active encryption key found for this user")

        row = result.data[0]

        return PublicKeyResponse(
            user_id=str(row["user_id"]),
            public_key=row["public_key"],
            algorithm=row["algorithm"],
            key_version=row["key_version"],
            created_at=row["created_at"],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Keys] Failed to get public key: {e}")
        raise safe_internal_error(e, "encryption_keys")
