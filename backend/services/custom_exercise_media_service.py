"""
Custom Exercise Media Service - AWS S3 Integration for custom exercise images/videos.

Stores custom exercise media with organized paths:
- custom-exercises/{user_id}/{exercise_id}/image.{ext}
- custom-exercises/{user_id}/{exercise_id}/video.{ext}
- custom-exercises/{user_id}/{exercise_id}/thumbnail.jpg
"""

import uuid
from datetime import datetime
from typing import Optional, Tuple
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)

# Allowed media types
ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'}
ALLOWED_VIDEO_TYPES = {'video/mp4', 'video/quicktime', 'video/webm', 'video/x-m4v'}

# Max file sizes (in bytes)
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10 MB
MAX_VIDEO_SIZE = 100 * 1024 * 1024  # 100 MB


class CustomExerciseMediaService:
    """Service for storing custom exercise media in AWS S3."""

    def __init__(self):
        settings = get_settings()
        self.bucket_name = settings.s3_bucket_name
        self.region = settings.aws_default_region or "us-east-1"

        # Only initialize client if S3 is configured
        if self._is_configured():
            self._client = boto3.client(
                's3',
                region_name=self.region,
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
                config=Config(signature_version='s3v4')
            )
        else:
            self._client = None

    def _is_configured(self) -> bool:
        """Check if S3 is configured."""
        settings = get_settings()
        return bool(
            settings.s3_bucket_name and
            settings.aws_access_key_id and
            settings.aws_secret_access_key
        )

    def _get_extension(self, content_type: str) -> str:
        """Get file extension from content type."""
        ext_map = {
            'image/jpeg': 'jpg',
            'image/png': 'png',
            'image/gif': 'gif',
            'image/webp': 'webp',
            'video/mp4': 'mp4',
            'video/quicktime': 'mov',
            'video/webm': 'webm',
            'video/x-m4v': 'm4v',
        }
        return ext_map.get(content_type, 'bin')

    async def upload_image(
        self,
        user_id: str,
        exercise_id: str,
        image_bytes: bytes,
        content_type: str = "image/jpeg",
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Upload custom exercise image to S3.

        Args:
            user_id: User's ID
            exercise_id: Exercise ID
            image_bytes: Raw image bytes
            content_type: MIME type of the image

        Returns:
            Tuple of (S3 key, error message) - key is None on error
        """
        if not self._is_configured():
            logger.warning("S3 not configured, skipping image upload")
            return None, "S3 storage not configured"

        if content_type not in ALLOWED_IMAGE_TYPES:
            return None, f"Invalid image type. Allowed: {', '.join(ALLOWED_IMAGE_TYPES)}"

        if len(image_bytes) > MAX_IMAGE_SIZE:
            return None, f"Image too large. Maximum size: {MAX_IMAGE_SIZE // (1024*1024)}MB"

        ext = self._get_extension(content_type)
        key = f"custom-exercises/{user_id}/{exercise_id}/image.{ext}"

        try:
            self._client.put_object(
                Bucket=self.bucket_name,
                Key=key,
                Body=image_bytes,
                ContentType=content_type,
            )
            logger.info(f"Uploaded custom exercise image: {key}")
            return key, None
        except ClientError as e:
            logger.error(f"Failed to upload image to S3: {e}")
            return None, str(e)
        except Exception as e:
            logger.error(f"Unexpected error uploading to S3: {e}")
            return None, str(e)

    async def upload_video(
        self,
        user_id: str,
        exercise_id: str,
        video_bytes: bytes,
        content_type: str = "video/mp4",
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Upload custom exercise video to S3.

        Args:
            user_id: User's ID
            exercise_id: Exercise ID
            video_bytes: Raw video bytes
            content_type: MIME type of the video

        Returns:
            Tuple of (S3 key, error message) - key is None on error
        """
        if not self._is_configured():
            logger.warning("S3 not configured, skipping video upload")
            return None, "S3 storage not configured"

        if content_type not in ALLOWED_VIDEO_TYPES:
            return None, f"Invalid video type. Allowed: {', '.join(ALLOWED_VIDEO_TYPES)}"

        if len(video_bytes) > MAX_VIDEO_SIZE:
            return None, f"Video too large. Maximum size: {MAX_VIDEO_SIZE // (1024*1024)}MB"

        ext = self._get_extension(content_type)
        key = f"custom-exercises/{user_id}/{exercise_id}/video.{ext}"

        try:
            self._client.put_object(
                Bucket=self.bucket_name,
                Key=key,
                Body=video_bytes,
                ContentType=content_type,
            )
            logger.info(f"Uploaded custom exercise video: {key}")
            return key, None
        except ClientError as e:
            logger.error(f"Failed to upload video to S3: {e}")
            return None, str(e)
        except Exception as e:
            logger.error(f"Unexpected error uploading to S3: {e}")
            return None, str(e)

    async def upload_thumbnail(
        self,
        user_id: str,
        exercise_id: str,
        thumbnail_bytes: bytes,
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Upload video thumbnail to S3.

        Args:
            user_id: User's ID
            exercise_id: Exercise ID
            thumbnail_bytes: JPEG thumbnail bytes

        Returns:
            Tuple of (S3 key, error message) - key is None on error
        """
        if not self._is_configured():
            return None, "S3 storage not configured"

        key = f"custom-exercises/{user_id}/{exercise_id}/thumbnail.jpg"

        try:
            self._client.put_object(
                Bucket=self.bucket_name,
                Key=key,
                Body=thumbnail_bytes,
                ContentType="image/jpeg",
            )
            logger.info(f"Uploaded custom exercise thumbnail: {key}")
            return key, None
        except Exception as e:
            logger.error(f"Failed to upload thumbnail: {e}")
            return None, str(e)

    def get_signed_url(self, storage_key: str, expires_in: int = 3600) -> Optional[str]:
        """
        Generate a presigned URL for viewing media.

        Args:
            storage_key: S3 key
            expires_in: URL validity in seconds (default 1 hour)

        Returns:
            Presigned URL or None if failed
        """
        if not self._is_configured() or not storage_key:
            return None

        try:
            url = self._client.generate_presigned_url(
                'get_object',
                Params={'Bucket': self.bucket_name, 'Key': storage_key},
                ExpiresIn=expires_in
            )
            return url
        except Exception as e:
            logger.error(f"Failed to generate presigned URL: {e}")
            return None

    def get_public_url(self, storage_key: str) -> Optional[str]:
        """
        Get public URL for S3 object (if bucket is public).

        Args:
            storage_key: S3 key

        Returns:
            Public URL or None
        """
        if not storage_key:
            return None
        return f"https://{self.bucket_name}.s3.{self.region}.amazonaws.com/{storage_key}"

    async def delete_media(self, user_id: str, exercise_id: str) -> bool:
        """
        Delete all media for a custom exercise.

        Args:
            user_id: User's ID
            exercise_id: Exercise ID

        Returns:
            True if deleted, False otherwise
        """
        if not self._is_configured():
            return False

        prefix = f"custom-exercises/{user_id}/{exercise_id}/"

        try:
            # List all objects with the prefix
            response = self._client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=prefix
            )

            if 'Contents' not in response:
                return True  # Nothing to delete

            # Delete all objects
            objects_to_delete = [{'Key': obj['Key']} for obj in response['Contents']]
            self._client.delete_objects(
                Bucket=self.bucket_name,
                Delete={'Objects': objects_to_delete}
            )

            logger.info(f"Deleted {len(objects_to_delete)} media files for exercise {exercise_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to delete exercise media: {e}")
            return False

    def generate_presigned_upload_url(
        self,
        user_id: str,
        exercise_id: str,
        media_type: str,  # "image" or "video"
        content_type: str,
        expires_in: int = 300,  # 5 minutes
    ) -> Tuple[Optional[str], Optional[str], Optional[str]]:
        """
        Generate a presigned URL for direct client upload.

        Args:
            user_id: User's ID
            exercise_id: Exercise ID
            media_type: "image" or "video"
            content_type: MIME type
            expires_in: URL validity in seconds

        Returns:
            Tuple of (presigned_url, s3_key, error) - url and key are None on error
        """
        if not self._is_configured():
            return None, None, "S3 storage not configured"

        if media_type == "image" and content_type not in ALLOWED_IMAGE_TYPES:
            return None, None, f"Invalid image type. Allowed: {', '.join(ALLOWED_IMAGE_TYPES)}"

        if media_type == "video" and content_type not in ALLOWED_VIDEO_TYPES:
            return None, None, f"Invalid video type. Allowed: {', '.join(ALLOWED_VIDEO_TYPES)}"

        ext = self._get_extension(content_type)
        key = f"custom-exercises/{user_id}/{exercise_id}/{media_type}.{ext}"

        try:
            url = self._client.generate_presigned_url(
                'put_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': key,
                    'ContentType': content_type,
                },
                ExpiresIn=expires_in
            )
            return url, key, None
        except Exception as e:
            logger.error(f"Failed to generate presigned upload URL: {e}")
            return None, None, str(e)


# Singleton instance
_custom_exercise_media_service: Optional[CustomExerciseMediaService] = None


def get_custom_exercise_media_service() -> CustomExerciseMediaService:
    """Get singleton CustomExerciseMediaService instance."""
    global _custom_exercise_media_service
    if _custom_exercise_media_service is None:
        _custom_exercise_media_service = CustomExerciseMediaService()
    return _custom_exercise_media_service
