"""
Profile photo upload and delete endpoints (S3-backed).
"""
from core.db import get_supabase_db
import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
import boto3

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.config import get_settings

from api.v1.users.models import ProfilePhotoResponse

router = APIRouter()
logger = get_logger(__name__)


def get_s3_client():
    """Get boto3 S3 client with credentials from settings."""
    settings = get_settings()
    return boto3.client(
        's3',
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_default_region,
    )


async def upload_profile_photo_to_s3(
    file: UploadFile,
    user_id: str,
) -> tuple[str, str]:
    """
    Upload profile photo to S3 and return (photo_url, storage_key).
    """
    # Generate unique key
    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    # SECURITY: Derive extension from content type, not user-controlled filename
    EXT_FROM_CONTENT_TYPE = {'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/heic': 'heic', 'video/mp4': 'mp4', 'video/quicktime': 'mov'}
    ext = EXT_FROM_CONTENT_TYPE.get(file.content_type, 'jpg')
    storage_key = f"profile_photos/{user_id}/{timestamp}_{uuid.uuid4().hex[:8]}.{ext}"

    # Upload to S3
    s3 = get_s3_client()
    contents = await file.read()

    settings = get_settings()
    # SECURITY: No ACL='public-read' — use pre-signed URLs or CloudFront for access.
    s3.put_object(
        Bucket=settings.s3_bucket_name,
        Key=storage_key,
        Body=contents,
        ContentType=file.content_type or 'image/jpeg',
    )

    # Generate URL
    photo_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{storage_key}"

    return photo_url, storage_key


async def delete_profile_photo_from_s3(storage_key: str) -> bool:
    """Delete profile photo from S3."""
    try:
        settings = get_settings()
        s3 = get_s3_client()
        s3.delete_object(
            Bucket=settings.s3_bucket_name,
            Key=storage_key,
        )
        return True
    except Exception as e:
        logger.error(f"Error deleting profile photo from S3: {e}", exc_info=True)
        return False


@router.post("/{id}/photo", response_model=ProfilePhotoResponse)
async def upload_profile_photo(
    id: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Upload a profile photo for a user.

    - Uploads the image to S3
    - Updates the user's photo_url in the database
    - Returns the new photo URL
    """
    logger.info(f"📸 [ProfilePhoto] Upload request for user {id}")

    verify_user_ownership(current_user, id)

    # Validate file type
    if file.content_type not in ['image/jpeg', 'image/png', 'image/gif', 'image/webp']:
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Only JPEG, PNG, GIF, and WebP images are allowed."
        )

    # Check file size (max 5MB)
    contents = await file.read()
    if len(contents) > 5 * 1024 * 1024:
        raise HTTPException(
            status_code=400,
            detail="File too large. Maximum size is 5MB."
        )
    # Reset file position after reading
    await file.seek(0)

    try:
        db = get_supabase_db()

        # Check if user exists
        result = db.client.table("users").select("id, photo_url").eq("id", id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user = result.data[0]
        old_photo_url = user.get("photo_url")

        # Upload new photo to S3
        photo_url, storage_key = await upload_profile_photo_to_s3(file, id)
        logger.info(f"✅ [ProfilePhoto] Uploaded to S3: {storage_key}")

        # Update user's photo_url in database
        db.client.table("users").update({
            "photo_url": photo_url,
        }).eq("id", id).execute()
        logger.info(f"✅ [ProfilePhoto] Updated user record with new photo URL")

        # Delete old photo from S3 if it exists
        if old_photo_url and "profile_photos/" in old_photo_url:
            try:
                old_storage_key = old_photo_url.split(".amazonaws.com/")[1]
                await delete_profile_photo_from_s3(old_storage_key)
                logger.info(f"🗑️ [ProfilePhoto] Deleted old photo: {old_storage_key}")
            except Exception as e:
                logger.warning(f"⚠️ [ProfilePhoto] Could not delete old photo: {e}", exc_info=True)

        return ProfilePhotoResponse(
            photo_url=photo_url,
            message="Profile photo uploaded successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [ProfilePhoto] Upload failed: {e}", exc_info=True)
        raise safe_internal_error(e, "profile_photo_upload")


@router.delete("/{id}/photo")
async def delete_profile_photo(id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Delete a user's profile photo.

    - Removes the photo from S3
    - Sets photo_url to null in the database
    """
    logger.info(f"🗑️ [ProfilePhoto] Delete request for user {id}")
    verify_user_ownership(current_user, id)

    try:
        db = get_supabase_db()

        # Get user and current photo URL
        result = db.client.table("users").select("id, photo_url").eq("id", id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user = result.data[0]
        photo_url = user.get("photo_url")

        if not photo_url:
            return {"message": "No profile photo to delete"}

        # Delete from S3 if it's our photo
        if "profile_photos/" in photo_url:
            try:
                storage_key = photo_url.split(".amazonaws.com/")[1]
                await delete_profile_photo_from_s3(storage_key)
                logger.info(f"✅ [ProfilePhoto] Deleted from S3: {storage_key}")
            except Exception as e:
                logger.warning(f"⚠️ [ProfilePhoto] Could not delete from S3: {e}", exc_info=True)

        # Update user's photo_url to null
        db.client.table("users").update({
            "photo_url": None,
        }).eq("id", id).execute()
        logger.info(f"✅ [ProfilePhoto] Cleared photo URL from user record")

        return {"message": "Profile photo deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [ProfilePhoto] Delete failed: {e}", exc_info=True)
        raise safe_internal_error(e, "profile_photo_delete")
