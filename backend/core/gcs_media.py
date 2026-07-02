"""Transient GCS media transfer for Vertex AI video analysis (ZDR path).

Vertex AI cannot use the Gemini Files API — it reads media from Cloud Storage
via gs:// URIs. This module streams S3 objects straight into a transient GCS
bucket (download and upload are pipelined in ONE pass over the bytes — no temp
file, no sequential download-then-upload) so video analysis runs entirely
inside the zero-data-retention Vertex endpoint instead of shipping user videos
to the Gemini Developer API.

Bucket provisioning is lazy and self-contained: the bucket named
`settings.gcs_media_bucket` (default "{gcp_project_id}-zealova-media") is
created on first use with a 1-day auto-delete lifecycle rule, so even a missed
per-request cleanup can never accumulate user videos.
"""
from __future__ import annotations

import asyncio
import threading
from typing import Optional

from core.config import get_settings
from core.gemini_client import ensure_gcp_credentials
from core.logger import get_logger

logger = get_logger(__name__)

_bucket_lock = threading.Lock()
_bucket_ready: Optional[str] = None  # bucket name once verified/created


def gcs_media_available() -> bool:
    """True when the Vertex/GCS transfer path can be attempted at all."""
    return bool(get_settings().gcp_project_id)


def _bucket_name() -> str:
    settings = get_settings()
    return settings.gcs_media_bucket or f"{settings.gcp_project_id}-zealova-media"


def _get_bucket():
    """Get (or lazily create) the transient media bucket. Thread-safe; the
    existence check + create runs once per process."""
    global _bucket_ready
    from google.cloud import storage
    from google.api_core.exceptions import NotFound

    ensure_gcp_credentials()
    client = storage.Client()
    name = _bucket_name()

    if _bucket_ready == name:
        return client.bucket(name)

    with _bucket_lock:
        if _bucket_ready == name:
            return client.bucket(name)
        try:
            bucket = client.get_bucket(name)
        except NotFound:
            logger.info(f"[GCS] Creating transient media bucket {name}")
            bucket = client.bucket(name)
            # US multi-region: readable by the global Vertex endpoint.
            bucket = client.create_bucket(bucket, location="US")
            # Belt-and-suspenders: objects self-destruct after 1 day even if a
            # per-request delete is missed. Per-request cleanup still runs.
            bucket.add_lifecycle_delete_rule(age=1)
            bucket.patch()
            logger.info(f"[GCS] Created {name} with 1-day auto-delete lifecycle")
        _bucket_ready = name
        return bucket


def _stream_transfer_sync(s3_client, s3_bucket: str, s3_key: str, mime_type: str) -> str:
    """Blocking half of [stream_s3_to_gcs] — pipe the S3 body file-object
    directly into the GCS upload (single pass, no local buffering to disk)."""
    obj = s3_client.get_object(Bucket=s3_bucket, Key=s3_key)
    body = obj["Body"]
    size = obj.get("ContentLength")

    bucket = _get_bucket()
    blob_name = f"form_analysis/{s3_key}"
    blob = bucket.blob(blob_name)
    # retry=None: the S3 body stream is not seekable, so a mid-upload retry
    # could not rewind it. Callers treat any failure as "GCS path unavailable"
    # and fall back to the Files API path, so failing fast here is correct.
    blob.upload_from_file(
        body,
        size=size,
        content_type=mime_type,
        retry=None,
    )
    gs_uri = f"gs://{bucket.name}/{blob_name}"
    logger.info(f"[GCS] Streamed s3://{s3_bucket}/{s3_key} → {gs_uri} ({size} bytes)")
    return gs_uri


async def stream_s3_to_gcs(s3_client, s3_bucket: str, s3_key: str, mime_type: str) -> str:
    """Stream one S3 object into the transient GCS bucket; returns its gs:// URI.

    Runs in a worker thread. For multiple videos, call under `asyncio.gather`
    — each transfer holds its own S3 stream + GCS session, so they parallelize
    cleanly.
    """
    return await asyncio.to_thread(
        _stream_transfer_sync, s3_client, s3_bucket, s3_key, mime_type
    )


async def delete_gcs_object(gs_uri: str) -> None:
    """Best-effort delete of a transferred object (the 1-day lifecycle rule is
    the backstop if this fails)."""
    try:
        if not gs_uri.startswith("gs://"):
            return
        bucket_name, _, blob_name = gs_uri[len("gs://"):].partition("/")

        def _delete():
            from google.cloud import storage

            ensure_gcp_credentials()
            storage.Client().bucket(bucket_name).blob(blob_name).delete()

        await asyncio.to_thread(_delete)
        logger.debug(f"[GCS] Deleted {gs_uri}")
    except Exception as e:
        logger.warning(f"[GCS] Failed to delete {gs_uri} (lifecycle rule will purge it): {e}")
