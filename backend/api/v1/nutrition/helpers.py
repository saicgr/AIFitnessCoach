"""
Shared helpers and constants for nutrition endpoints.

Contains S3 upload helper, regional food keywords, and common imports
used across multiple nutrition sub-modules.
"""
import asyncio
import uuid
from datetime import datetime
from typing import Tuple

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
        Tuple of (image_url, storage_key)

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

    # Upload to S3 (runs in thread pool to not block event loop)
    def _upload():
        s3 = get_s3_client()
        s3.put_object(
            Bucket=settings.s3_bucket_name,
            Key=storage_key,
            Body=file_bytes,
            ContentType=content_type,
        )

    loop = asyncio.get_event_loop()
    await loop.run_in_executor(None, _upload)

    # Generate public URL
    image_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{storage_key}"

    logger.info(f"Uploaded food image to S3: {storage_key}")
    return image_url, storage_key
