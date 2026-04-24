"""
Progress Photo comparison narrative service.

Generates the paragraph that powers the "Progress Summary" card on the
Flutter comparison_view. Replaces the inline logic previously in
backend/api/v1/progress_photos.py::generate_ai_summary with:
- structured output via Pydantic schema (no manual JSON parsing),
- async retry path (gemini_generate_with_retry),
- 24 h Redis cache keyed on the photo pair + duration + weight change.
"""
from __future__ import annotations

import hashlib
import json
import logging
from typing import Optional

import httpx
from google.genai import types

from core.config import get_settings
from core.redis_cache import RedisCache
from models.gemini_schemas import ProgressPhotoComparisonResponse
from services.gemini.constants import gemini_generate_with_retry

logger = logging.getLogger("progress_narrative")

_NARRATIVE_CACHE = RedisCache(
    prefix="progress_narrative", ttl_seconds=86400, max_size=200,
)


async def generate_progress_narrative(
    *,
    before_photo_url: str,
    after_photo_url: str,
    days_between: int,
    weight_change_kg: Optional[float] = None,
    user_id: Optional[str] = None,
    model: Optional[str] = None,
) -> ProgressPhotoComparisonResponse:
    """Compare two progress photos and return a structured narrative.

    `before_photo_url` / `after_photo_url` may be signed S3 URLs (which
    the backend just signed in the calling endpoint). Bytes are fetched
    via httpx and passed as `types.Part.from_bytes`.
    """
    settings = get_settings()
    model = model or settings.gemini_model

    # Cache key ignores the signature part of signed URLs — we only key on
    # the path so re-signs don't miss the cache.
    def _path_only(url: str) -> str:
        return url.split("?", 1)[0]

    cache_key = hashlib.sha256(
        (
            _path_only(before_photo_url)
            + "|" + _path_only(after_photo_url)
            + f"|{days_between}|{weight_change_kg}"
        ).encode()
    ).hexdigest()

    cached = await _NARRATIVE_CACHE.get(cache_key)
    if cached is not None:
        logger.info(f"[progress_narrative] cache hit {cache_key[:12]}")
        return ProgressPhotoComparisonResponse(**cached)

    async with httpx.AsyncClient(timeout=30) as http_client:
        before_resp = await http_client.get(before_photo_url)
        after_resp = await http_client.get(after_photo_url)
        before_resp.raise_for_status()
        after_resp.raise_for_status()

    duration_text = f"{days_between} days"
    if days_between >= 30:
        months = days_between // 30
        duration_text = f"{months} month{'s' if months > 1 else ''}"

    weight_text = ""
    if weight_change_kg is not None:
        sign = "+" if weight_change_kg > 0 else ""
        weight_text = f" Weight changed by {sign}{weight_change_kg:.1f} kg over the interval."

    prompt = f"""You are comparing two fitness progress photos taken {duration_text} apart.{weight_text}

Describe visible changes in 1-3 sentences in `summary_text`, focusing on:
muscle development, body composition (leanness), posture.

Also fill the per-region fields:
- midsection_change: one observation about abs / waist / love handles.
- upper_body_change: chest / shoulders / back / arms observation.
- lower_body_change: quads / glutes / hamstrings / calves observation.
- overall_verdict: one word — improved | maintained | regressed | inconclusive.

If changes are subtle, acknowledge effort and consistency without exaggeration.
Never invent changes you can't see.

Return valid JSON matching the schema."""

    response = await gemini_generate_with_retry(
        model=model,
        contents=[
            types.Part.from_bytes(data=before_resp.content, mime_type="image/jpeg"),
            types.Part.from_bytes(data=after_resp.content, mime_type="image/jpeg"),
            prompt,
        ],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=ProgressPhotoComparisonResponse,
            max_output_tokens=512,
            temperature=0.5,
        ),
        user_id=user_id,
        timeout=25.0,
        method_name="progress_narrative",
    )

    result = response.parsed if hasattr(response, "parsed") and response.parsed else None
    if result is None:
        result = ProgressPhotoComparisonResponse(**json.loads(response.text))

    await _NARRATIVE_CACHE.set(cache_key, result.model_dump())
    return result
