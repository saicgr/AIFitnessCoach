"""
Image Storage Service - AWS S3 Integration for food images.

Stores food images captured during meal logging with organized paths:
- images/camera/{user_id}/{date_timestamp}/{meal_type}_{uuid}.jpg
- images/barcode/{user_id}/{date_timestamp}/{meal_type}_{uuid}.jpg
"""

import uuid
import boto3
from datetime import datetime
from typing import Optional
from botocore.config import Config
from botocore.exceptions import ClientError
from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)


class ImageStorageService:
    """Service for storing food images in AWS S3."""

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

    async def upload_food_image(
        self,
        user_id: str,
        image_bytes: bytes,
        meal_type: str,
        source: str = "camera",
    ) -> Optional[str]:
        """
        Upload food image to S3 and return the storage key.

        Args:
            user_id: User's ID
            image_bytes: Raw image bytes (JPEG)
            meal_type: Type of meal (breakfast, lunch, dinner, snack)
            source: Source of image ("camera" or "barcode")

        Returns:
            S3 key if successful, None if not configured or failed

        Storage structure:
            images/{source}/{user_id}/{date_timestamp}/{meal_type}_{uuid}.jpg

        Examples:
            - images/camera/abc123/2026-01-11_143052/breakfast_a1b2c3d4.jpg
            - images/barcode/abc123/2026-01-11_120530/snack_e5f6g7h8.jpg
        """
        if not self._is_configured():
            logger.warning("S3 not configured, skipping image upload")
            return None

        now = datetime.utcnow()
        date_timestamp = now.strftime("%Y-%m-%d_%H%M%S")
        unique_id = uuid.uuid4().hex[:8]

        key = f"images/{source}/{user_id}/{date_timestamp}/{meal_type}_{unique_id}.jpg"

        try:
            self._client.put_object(
                Bucket=self.bucket_name,
                Key=key,
                Body=image_bytes,
                ContentType="image/jpeg",
            )
            logger.info(f"Uploaded food image: {key}")
            return key
        except ClientError as e:
            logger.error(f"Failed to upload image to S3: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error uploading to S3: {e}")
            return None

    def get_signed_url(self, storage_key: str, expires_in: int = 3600) -> Optional[str]:
        """
        Generate a presigned URL for viewing an image.

        Args:
            storage_key: S3 key returned from upload_food_image
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
        except ClientError as e:
            logger.error(f"Failed to generate presigned URL: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error generating presigned URL: {e}")
            return None

    async def delete_image(self, storage_key: str) -> bool:
        """
        Delete an image from S3.

        Args:
            storage_key: S3 key to delete

        Returns:
            True if deleted, False otherwise
        """
        if not self._is_configured() or not storage_key:
            return False

        try:
            self._client.delete_object(
                Bucket=self.bucket_name,
                Key=storage_key
            )
            logger.info(f"Deleted image: {storage_key}")
            return True
        except ClientError as e:
            logger.error(f"Failed to delete image from S3: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error deleting from S3: {e}")
            return False


# Singleton instance
_image_storage_service: Optional[ImageStorageService] = None


def get_image_storage_service() -> ImageStorageService:
    """Get singleton ImageStorageService instance."""
    global _image_storage_service
    if _image_storage_service is None:
        _image_storage_service = ImageStorageService()
    return _image_storage_service
