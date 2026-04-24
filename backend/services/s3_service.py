"""
Generic S3 helper — upload / download raw bytes for media_analysis_jobs.

This is the thin wrapper that WorkoutHistoryImporter (and future byte-oriented
importers) expect. Keyed off the same AWS settings used by VisionService and
CustomExerciseMediaService, but exposes bytes in/bytes out without feature-specific
path conventions.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)


class S3Service:
    """Minimal byte-oriented S3 wrapper."""

    def __init__(self) -> None:
        settings = get_settings()
        self.bucket = settings.s3_bucket_name
        self.region = settings.aws_default_region or "us-east-1"

        if self._configured():
            self._client = boto3.client(
                "s3",
                region_name=self.region,
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
                config=Config(signature_version="s3v4"),
            )
        else:
            self._client = None

    def _configured(self) -> bool:
        settings = get_settings()
        return bool(
            settings.s3_bucket_name
            and settings.aws_access_key_id
            and settings.aws_secret_access_key
        )

    def is_configured(self) -> bool:
        return self._client is not None and bool(self.bucket)

    # ---------- Upload ----------

    def upload_bytes(
        self,
        data: bytes,
        *,
        key_prefix: str,
        filename: str,
        content_type: Optional[str] = None,
    ) -> str:
        """Upload raw bytes to S3 under `{key_prefix}/{timestamp}-{uuid}-{safe_filename}`.

        Returns the full S3 key. Raises RuntimeError if S3 isn't configured.
        """
        if not self.is_configured():
            raise RuntimeError("S3 is not configured (missing AWS credentials or bucket)")

        safe_name = _sanitize_filename(filename)
        timestamp = datetime.utcnow().strftime("%Y%m%dT%H%M%S")
        key = f"{key_prefix.rstrip('/')}/{timestamp}-{uuid.uuid4().hex[:8]}-{safe_name}"

        try:
            put_kwargs = {"Bucket": self.bucket, "Key": key, "Body": data}
            if content_type:
                put_kwargs["ContentType"] = content_type
            self._client.put_object(**put_kwargs)
            logger.info(f"📤 [S3] Uploaded {len(data)} bytes to {key}")
            return key
        except ClientError as e:
            logger.error(f"❌ [S3] upload_bytes failed for {key}: {e}", exc_info=True)
            raise

    # ---------- Download ----------

    def download_bytes(self, key: str) -> bytes:
        """Fetch an object from S3 and return its bytes. Raises on failure."""
        if not self.is_configured():
            raise RuntimeError("S3 is not configured (missing AWS credentials or bucket)")
        try:
            resp = self._client.get_object(Bucket=self.bucket, Key=key)
            body = resp["Body"].read()
            logger.info(f"📥 [S3] Downloaded {len(body)} bytes from {key}")
            return body
        except ClientError as e:
            logger.error(f"❌ [S3] download_bytes failed for {key}: {e}", exc_info=True)
            raise

    # Aliases used by other services.
    def get_object_bytes(self, key: str) -> bytes:
        return self.download_bytes(key)


def _sanitize_filename(name: str) -> str:
    """Make a safe filename for object keys — strip path traversal + weird chars."""
    base = (name or "upload.bin").rsplit("/", 1)[-1].rsplit("\\", 1)[-1]
    cleaned = "".join(
        ch if (ch.isalnum() or ch in "._-") else "_" for ch in base
    ).strip("._")
    return cleaned or "upload.bin"


_s3_singleton: Optional[S3Service] = None


def get_s3_service() -> S3Service:
    """Return the module-level S3Service singleton."""
    global _s3_singleton
    if _s3_singleton is None:
        _s3_singleton = S3Service()
    return _s3_singleton
