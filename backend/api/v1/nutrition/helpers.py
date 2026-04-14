"""
Shared helpers and constants for nutrition endpoints.

Contains S3 upload helper, regional food keywords, and common imports
used across multiple nutrition sub-modules.
"""
import asyncio
import uuid
from datetime import datetime
from typing import Optional, Tuple

from core.logger import get_logger

logger = get_logger(__name__)


# Regional/complex food keywords - frozenset for O(1) lookup
_REGIONAL_KEYWORDS = frozenset([
    'biryani', 'curry', 'masala', 'tikka', 'tandoori', 'paneer', 'dosa', 'idli',
    'sambar', 'rasam', 'korma', 'vindaloo', 'dal', 'chapati', 'naan',
    'paratha', 'puri', 'samosa', 'pakora', 'chutney', 'raita', 'lassi', 'kulfi',
    'halwa', 'ladoo', 'jalebi', 'kheer', 'upma', 'poha',
    'pho', 'pad thai', 'rendang', 'satay', 'laksa',
    'kimchi', 'bibimbap', 'bulgogi', 'ramen', 'udon', 'sushi', 'tempura',
    'congee', 'szechuan',
    'tacos', 'burrito', 'enchilada', 'tamale', 'mole', 'ceviche',
    'falafel', 'shawarma', 'hummus', 'tabouleh',
    'injera', 'tagine', 'couscous', 'jollof', 'fufu',
    'pierogi', 'borscht', 'goulash', 'schnitzel', 'paella', 'risotto',
    'gnocchi', 'carbonara', 'bolognese', 'tiramisu',
])


def get_s3_client():
    """Get S3 client with configured credentials."""
    import boto3
    from core.config import get_settings
    settings = get_settings()
    return boto3.client(
        's3',
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_default_region,
    )


async def upload_food_image_to_s3(
    file_bytes: bytes,
    user_id: str,
    content_type: str = "image/jpeg",
    source: str = "camera",
    meal_type: str = "meal",
) -> Tuple[str, str]:
    """
    Upload food image to S3 in parallel with Gemini analysis.

    Args:
        file_bytes: Raw image bytes
        user_id: User's UUID
        content_type: MIME type of the image
        source: Source of image ("camera" or "barcode")
        meal_type: Type of meal (breakfast, lunch, dinner, snack)

    Returns:
        Tuple of (image_url, storage_key) — image_url is a 7-day presigned
        GET URL so the client can render it immediately. The read path
        (resign_food_image_url) regenerates short-lived URLs on each fetch
        so the DB-stored URL never leaves the user with a broken image.

    Path format: images/{source}/{user_id}/{date_timestamp}/{meal_type}_{uuid}.{ext}
    Example: images/camera/abc123/2026-01-11_143052/breakfast_a1b2c3d4.jpg
    """
    from core.config import get_settings
    settings = get_settings()

    # Generate unique storage key with organized path
    date_timestamp = datetime.utcnow().strftime('%Y-%m-%d_%H%M%S')
    ext = content_type.split('/')[-1] if content_type else 'jpeg'
    if ext not in ['jpeg', 'jpg', 'png', 'webp', 'gif']:
        ext = 'jpeg'
    unique_id = uuid.uuid4().hex[:8]
    storage_key = f"images/{source}/{user_id}/{date_timestamp}/{meal_type}_{unique_id}.{ext}"

    # Upload to S3 (runs in thread pool to not block event loop).
    # Belt-and-suspenders: try ACL='public-read' first (works if the bucket
    # permits public ACLs), fall back to no-ACL upload if blocked. Either
    # way the read path uses presigned URLs, so the ACL is purely an
    # optimization (avoids the round-trip to sign on each fetch when allowed).
    def _upload():
        s3 = get_s3_client()
        try:
            s3.put_object(
                Bucket=settings.s3_bucket_name,
                Key=storage_key,
                Body=file_bytes,
                ContentType=content_type,
                ACL='public-read',
            )
        except Exception as acl_err:
            # Bucket likely has BlockPublicAcls on (AWS default). That's fine
            # — fall back to a private upload; presigned URLs still work.
            logger.info(
                f"S3 public-read ACL rejected ({acl_err}); falling back to "
                f"private upload — presigned URLs will be used on read."
            )
            s3.put_object(
                Bucket=settings.s3_bucket_name,
                Key=storage_key,
                Body=file_bytes,
                ContentType=content_type,
            )
        # Always generate a presigned GET URL so the response carries a
        # working URL even when the object is private.
        return s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': settings.s3_bucket_name, 'Key': storage_key},
            ExpiresIn=7 * 24 * 3600,  # 7 days; read path re-signs on every fetch
        )

    loop = asyncio.get_event_loop()
    image_url = await loop.run_in_executor(None, _upload)

    logger.info(f"Uploaded food image to S3: {storage_key}")
    return image_url, storage_key


def resign_food_image_url(url: Optional[str], expires_in: int = 24 * 3600) -> Optional[str]:
    """
    Re-sign an S3 image URL so it works regardless of bucket ACLs.

    Accepts:
      - None / empty → returns as-is.
      - Non-S3 URL (CDN, external, http://example.com) → returns as-is.
      - Direct S3 URL (https://{bucket}.s3.{region}.amazonaws.com/{key}) →
        extracts the key and returns a fresh presigned GET URL.
      - Already-presigned S3 URL (with X-Amz-Signature in the query string) →
        strips the signature, re-signs from scratch so the TTL is always
        fresh on every read.

    The 24-hour default TTL is short enough that signatures don't leak via
    long-lived caches, long enough that any reasonable client-side cache
    keeps working between sessions.

    Returns:
        Fresh presigned URL, or original URL on any failure (defensive — we
        never want a re-sign error to break list_food_logs).
    """
    if not url:
        return url
    try:
        from urllib.parse import urlparse
        from core.config import get_settings
        settings = get_settings()

        parsed = urlparse(url)
        bucket = settings.s3_bucket_name
        # Match both virtual-hosted (bucket.s3...) and path-style URLs
        # against our configured bucket only.
        host = parsed.netloc.lower()
        if not host.startswith(f"{bucket}.s3") and host != f"s3.{settings.aws_default_region}.amazonaws.com":
            return url  # foreign URL — leave it alone

        # Extract key from path (strip leading slash; ignore /bucket/ prefix
        # for path-style URLs).
        path = parsed.path.lstrip('/')
        if host == f"s3.{settings.aws_default_region}.amazonaws.com" and path.startswith(f"{bucket}/"):
            key = path[len(bucket) + 1:]
        else:
            key = path
        if not key:
            return url

        s3 = get_s3_client()
        return s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': key},
            ExpiresIn=expires_in,
        )
    except Exception as e:
        logger.warning(f"resign_food_image_url failed for {url[:80]}…: {e}")
        return url
