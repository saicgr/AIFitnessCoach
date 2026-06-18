"""
Share AI service — Workstream F cost-disciplined AI for the share/viral layer.

Two AI capabilities, both built to the plan's **cost-discipline principle**:

  F1  ai_restyle(image_bytes, style)
        Gemini **Flash Image** (nano-banana, NOT Pro) turns a user photo into a
        preset style (figurine / anime / comic / trading_card) that PRESERVES
        likeness. Cost gates, all enforced here:
          - kill-switch env flag  SHARE_AI_RESTYLE_ENABLED  (default on)
          - per-user daily cap     SHARE_AI_RESTYLE_DAILY_CAP (default 10)
          - cache key              sha256(photo bytes) + ':' + style
            -> a cache hit re-serves the stored S3 image for FREE (no model
               call, and the daily cap is NOT consumed).
        Output always carries a visible AI watermark/disclosure note in the
        response metadata (the frontend renders the disclosure).

  F2  insight_line(...)
        A one-liner for any share card. DETERMINISTIC-FIRST:
          1. Reuse an existing cached coach insight (coach_daily_insights) when
             one exists for that user+date  -> ZERO new model call.
          2. Else build the line from a deterministic variant pool with real
             data substituted (>=4 variants, feedback_dynamic_copy_not_robotic).
          3. Only when AI is explicitly enabled AND no deterministic line fits
             do we make ONE Gemini **Flash** text call, then cache it.
        Cached per (workout|day)+tone so re-opens of the same share are free.

No mock data: real Gemini, real S3, real DB. The deterministic fallback in F2
is the *design*, not a silent degradation — it is always built from real user
stats.
"""
from __future__ import annotations

import hashlib
import os
import random
from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from core.config import get_settings
from core.db.facade import get_supabase_db
from core.logger import get_logger
from services.s3_service import get_s3_service

logger = get_logger(__name__)
_settings = get_settings()


# --------------------------------------------------------------------------- #
# Kill-switches + caps (env-overridable, default safe).
# --------------------------------------------------------------------------- #
def _env_flag(name: str, default: bool = True) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() not in ("0", "false", "no", "off", "")


def restyle_enabled() -> bool:
    """F1 kill-switch. Disable instantly by setting SHARE_AI_RESTYLE_ENABLED=0."""
    return _env_flag("SHARE_AI_RESTYLE_ENABLED", True)


def insight_ai_enabled() -> bool:
    """F2 kill-switch for the *AI* path only. When off, F2 still works via the
    deterministic variant pool + cached coach insights (it never breaks)."""
    return _env_flag("SHARE_AI_INSIGHT_ENABLED", True)


def restyle_daily_cap() -> int:
    try:
        return max(0, int(os.getenv("SHARE_AI_RESTYLE_DAILY_CAP", "10")))
    except ValueError:
        return 10


# The cheapest image model exposed by google-genai. Override via env if Google
# renames the SKU. This is Flash Image (nano-banana), NOT Pro — per cost rules.
def restyle_image_model() -> str:
    return os.getenv("SHARE_AI_IMAGE_MODEL", "gemini-2.5-flash-image")


# Per-style prompts. Each one explicitly preserves the subject's likeness,
# pose, and framing so the output is recognizably the same person/meal.
_STYLE_PROMPTS: Dict[str, str] = {
    "figurine": (
        "Transform this photo into a collectible vinyl figurine / action-figure "
        "render of the SAME subject. Keep the person's face, body proportions, "
        "pose, outfit colors, and the background scene clearly recognizable. "
        "Glossy toy plastic shading, soft studio light, subtle base stand. "
        "Do not change identity, age, or body type."
    ),
    "anime": (
        "Restyle this photo as a clean modern anime illustration of the SAME "
        "subject. Preserve the exact pose, facial features, hairstyle, outfit, "
        "and background composition so it is recognizably the same person. "
        "Cel shading, crisp lineart, vibrant but natural palette. "
        "Do not alter identity, age, or body type."
    ),
    "comic": (
        "Convert this photo into a bold comic-book panel of the SAME subject. "
        "Keep the pose, face, physique, outfit, and setting recognizable. "
        "Ink outlines, halftone shading, dynamic but realistic proportions. "
        "Do not change identity, age, or body type."
    ),
    "trading_card": (
        "Render this photo as a premium sports trading card featuring the SAME "
        "subject. Preserve the person's face, physique, pose, and outfit. Add a "
        "tasteful holographic border and stat-card framing around them, leaving "
        "the central figure clearly recognizable. "
        "Do not change identity, age, or body type."
    ),
}

VALID_STYLES = tuple(_STYLE_PROMPTS.keys())

# Visible disclosure the frontend must render on any AI-restyled image.
AI_DISCLOSURE = "AI-generated style ✨ · Edited with Zealova AI"


class ShareAIError(Exception):
    """Surfaced to the endpoint as a real error (no silent fallback)."""


class DailyCapReached(ShareAIError):
    pass


class FeatureDisabled(ShareAIError):
    pass


# --------------------------------------------------------------------------- #
# F1 — AI photo-transform (cost-gated, cached).
# --------------------------------------------------------------------------- #
def _restyle_cache_key(image_sha: str, style: str) -> str:
    return f"{image_sha}:{style}"


def _today_utc() -> date:
    return datetime.now(timezone.utc).date()


def _count_today(user_id: str, feature: str = "ai_restyle") -> int:
    db = get_supabase_db()
    row = (
        db.client.table("share_ai_usage")
        .select("count")
        .eq("user_id", user_id)
        .eq("day", _today_utc().isoformat())
        .eq("feature", feature)
        .limit(1)
        .execute()
    )
    if row.data:
        return int(row.data[0].get("count") or 0)
    return 0


def _increment_today(user_id: str, feature: str = "ai_restyle") -> None:
    """Increment the per-user daily counter. Only called on a genuine generation
    (cache misses) — cache hits are free and never counted."""
    db = get_supabase_db()
    today = _today_utc().isoformat()
    current = _count_today(user_id, feature)
    db.client.table("share_ai_usage").upsert(
        {
            "user_id": user_id,
            "day": today,
            "feature": feature,
            "count": current + 1,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        },
        on_conflict="user_id,day,feature",
    ).execute()


def restyle_quota(user_id: str) -> Dict[str, Any]:
    """Read-only quota snapshot for the UI (used today / cap / remaining)."""
    cap = restyle_daily_cap()
    used = _count_today(user_id)
    return {
        "used_today": used,
        "daily_cap": cap,
        "remaining": max(0, cap - used),
        "enabled": restyle_enabled(),
    }


def _lookup_restyle_cache(cache_key: str) -> Optional[Dict[str, Any]]:
    db = get_supabase_db()
    row = (
        db.client.table("share_ai_restyle_cache")
        .select("*")
        .eq("cache_key", cache_key)
        .limit(1)
        .execute()
    )
    return row.data[0] if row.data else None


def _store_restyle_cache(
    *, cache_key: str, user_id: str, style: str, image_sha: str, s3_key: str, model: str
) -> None:
    db = get_supabase_db()
    db.client.table("share_ai_restyle_cache").upsert(
        {
            "cache_key": cache_key,
            "user_id": user_id,
            "style": style,
            "source_sha256": image_sha,
            "s3_key": s3_key,
            "model": model,
        },
        on_conflict="cache_key",
    ).execute()


def _presign(s3_key: str, expires_in: int = 24 * 3600) -> str:
    """Presigned GET URL for an S3 object (mirrors slideshow_service._presign)."""
    s3 = get_s3_service()
    if not s3.is_configured():
        raise ShareAIError("S3 is not configured (missing AWS credentials or bucket)")
    return s3._client.generate_presigned_url(  # noqa: SLF001 — same access as slideshow_service
        "get_object",
        Params={"Bucket": s3.bucket, "Key": s3_key},
        ExpiresIn=expires_in,
    )


def _gemini_generate_image(prompt: str, image_bytes: bytes, mime_type: str) -> bytes:
    """Single Gemini Flash Image generation. Returns PNG/JPEG bytes.

    Uses the shared genai client (Vertex ZDR in prod) with response_modalities
    set to IMAGE so the model returns inline image data. Raises ShareAIError on
    any non-image response (no silent fallback)."""
    from google.genai import types
    from services.gemini.constants import gemini_generate_with_retry_sync

    contents = [
        types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
        prompt,
    ]
    config = types.GenerateContentConfig(
        response_modalities=["IMAGE"],
        # No thinking — image gen does not use a text thinking budget; keeps cost down.
        safety_settings=[
            types.SafetySetting(category="HARM_CATEGORY_HARASSMENT", threshold="BLOCK_ONLY_HIGH"),
            types.SafetySetting(category="HARM_CATEGORY_HATE_SPEECH", threshold="BLOCK_ONLY_HIGH"),
            types.SafetySetting(category="HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold="BLOCK_MEDIUM_AND_ABOVE"),
            types.SafetySetting(category="HARM_CATEGORY_DANGEROUS_CONTENT", threshold="BLOCK_ONLY_HIGH"),
        ],
    )

    response = gemini_generate_with_retry_sync(
        model=restyle_image_model(),
        contents=contents,
        config=config,
        timeout=90,
        method_name="share_ai_restyle",
    )

    # Extract the first inline image part.
    try:
        for cand in response.candidates or []:
            parts = getattr(cand.content, "parts", None) or []
            for part in parts:
                inline = getattr(part, "inline_data", None)
                if inline and getattr(inline, "data", None):
                    return inline.data
    except Exception as e:  # pragma: no cover — defensive
        raise ShareAIError(f"Failed to parse Gemini image response: {e}") from e

    raise ShareAIError(
        "Gemini returned no image (possibly safety-blocked). Try a different photo or style."
    )


def restyle_photo(
    *,
    user_id: str,
    image_bytes: bytes,
    style: str,
    mime_type: str = "image/jpeg",
) -> Dict[str, Any]:
    """F1 entry point. Returns {url, s3_key, style, cached, disclosure, watermark,
    quota}. Enforces kill-switch + daily cap; caches by sha256(bytes)+style.

    Raises FeatureDisabled / DailyCapReached / ShareAIError (no silent fallback).
    """
    if style not in _STYLE_PROMPTS:
        raise ShareAIError(f"Unknown style '{style}'. Valid: {', '.join(VALID_STYLES)}")
    if not restyle_enabled():
        raise FeatureDisabled("AI restyle is currently disabled.")
    if not image_bytes:
        raise ShareAIError("Empty image.")

    image_sha = hashlib.sha256(image_bytes).hexdigest()
    cache_key = _restyle_cache_key(image_sha, style)

    # --- Cache hit: FREE re-serve, cap untouched. ---
    cached = _lookup_restyle_cache(cache_key)
    if cached:
        logger.info(f"✨ [ShareAI] restyle cache HIT key={cache_key[:16]}… (free)")
        return {
            "url": _presign(cached["s3_key"]),
            "s3_key": cached["s3_key"],
            "style": style,
            "cached": True,
            "model": cached.get("model"),
            "disclosure": AI_DISCLOSURE,
            "watermark": True,
            "quota": restyle_quota(user_id),
        }

    # --- Cache miss: enforce daily cap BEFORE spending a generation. ---
    cap = restyle_daily_cap()
    used = _count_today(user_id)
    if used >= cap:
        raise DailyCapReached(
            f"Daily AI restyle limit reached ({used}/{cap}). Resets at midnight UTC."
        )

    model = restyle_image_model()
    logger.info(f"\U0001f3a8 [ShareAI] restyle MISS → generating style={style} model={model}")
    out_bytes = _gemini_generate_image(_STYLE_PROMPTS[style], image_bytes, mime_type)

    s3 = get_s3_service()
    s3_key = s3.upload_bytes(
        out_bytes,
        key_prefix=f"share-ai/{user_id}",
        filename=f"{style}-{image_sha[:12]}.png",
        content_type="image/png",
    )
    _store_restyle_cache(
        cache_key=cache_key, user_id=user_id, style=style,
        image_sha=image_sha, s3_key=s3_key, model=model,
    )
    _increment_today(user_id)  # only real generations consume the cap

    return {
        "url": _presign(s3_key),
        "s3_key": s3_key,
        "style": style,
        "cached": False,
        "model": model,
        "disclosure": AI_DISCLOSURE,
        "watermark": True,
        "quota": restyle_quota(user_id),
    }


# --------------------------------------------------------------------------- #
# F2 — insight line + roast/hype toggle (deterministic-first, cached).
# --------------------------------------------------------------------------- #
VALID_TONES = ("supportive", "savage")


def _insight_cache_get(cache_key: str) -> Optional[Dict[str, Any]]:
    db = get_supabase_db()
    row = (
        db.client.table("share_insight_cache")
        .select("*")
        .eq("cache_key", cache_key)
        .limit(1)
        .execute()
    )
    return row.data[0] if row.data else None


def _insight_cache_put(*, cache_key: str, user_id: str, line: str, tone: str, source: str) -> None:
    db = get_supabase_db()
    db.client.table("share_insight_cache").upsert(
        {
            "cache_key": cache_key,
            "user_id": user_id,
            "line": line,
            "tone": tone,
            "source": source,
        },
        on_conflict="cache_key",
    ).execute()


def _reuse_coach_insight(user_id: str, local_date: str) -> Optional[str]:
    """ZERO-cost reuse: pull an existing coach_daily_insights body for this
    user+date (any source), newest first. Returns None if none cached."""
    db = get_supabase_db()
    try:
        row = (
            db.client.table("coach_daily_insights")
            .select("headline, body, generated_at")
            .eq("user_id", user_id)
            .eq("local_date", local_date)
            .order("generated_at", desc=True)
            .limit(1)
            .execute()
        )
    except Exception as e:  # pragma: no cover — defensive
        logger.warning(f"[ShareAI] coach insight reuse query failed: {e}")
        return None
    if not row.data:
        return None
    r = row.data[0]
    line = (r.get("body") or r.get("headline") or "").strip()
    return line or None


# Deterministic variant pools — >=4 each, real data substituted.
# {value}/{metric}/{name}/{pct} placeholders filled by the caller.
_WORKOUT_POOL_SUPPORTIVE = [
    "{name} done. {metric} in the bank today. \U0001f4aa",
    "Showed up and moved {metric}. That's how streaks are built.",
    "Another session logged: {metric}. Future-you says thanks.",
    "{metric} of honest work today. Consistency is the whole game.",
    "Logged {name}. {metric} closer to the goal.",
]
_WORKOUT_POOL_SAVAGE = [
    "{metric} moved. The couch stayed empty. Respect. \U0001f525",
    "{name}? Demolished. {metric} and not a single excuse.",
    "You came for {metric} and left no reps behind. Brutal.",
    "{metric} today. Your past self is officially intimidated.",
    "No skip. No mercy. {metric} on the board.",
]
_PR_POOL_SUPPORTIVE = [
    "New PR: {value} on {name}. Up {pct}% and the work is working. \U0001f3c6",
    "{name} personal best: {value}. Progress you can see.",
    "{value} on {name}. A brand-new ceiling.",
    "PR alert: {name} at {value}. {pct}% stronger than last time.",
]
_PR_POOL_SAVAGE = [
    "Snapped a PR: {value} on {name}. +{pct}%. The bar feared you. \U0001f525",
    "{name} just got a new boss. {value}. Deal with it.",
    "{value} on {name}. Old you could never.",
    "PR smashed: {name} {value}, up {pct}%. Absolutely unhinged work.",
]
_FOOD_POOL_SUPPORTIVE = [
    "Cleanest plate of the week: {value} health score. \U0001f957",
    "{value}/100 today. Fuelling like you mean it.",
    "Solid day: {metric}. Your body noticed.",
    "{metric} logged. Small wins, stacked.",
]
_FOOD_POOL_SAVAGE = [
    "{value}/100 health score. Your macros didn't stand a chance. \U0001f525",
    "Ate like an athlete today: {metric}. No notes.",
    "{metric}. The kitchen never recovered.",
    "Dialed in: {metric}. Mediocre meals are crying.",
]


def _pick(pool: List[str], seed_key: str) -> str:
    """Deterministic-ish pick (stable per share key so re-opens match)."""
    rnd = random.Random(hashlib.sha256(seed_key.encode()).hexdigest())
    return rnd.choice(pool)


def _deterministic_workout_line(stats: Dict[str, Any], tone: str, seed: str) -> Optional[str]:
    name = (stats.get("name") or "Workout").strip()
    # Prefer a PR if present.
    pr = stats.get("top_pr")
    if pr and pr.get("value"):
        pool = _PR_POOL_SAVAGE if tone == "savage" else _PR_POOL_SUPPORTIVE
        return _pick(pool, seed).format(
            value=pr.get("value"),
            name=pr.get("exercise") or name,
            pct=pr.get("pct") or 0,
        )
    metric = stats.get("metric")  # e.g. "42 min", "8,400 kg volume"
    if not metric:
        return None
    pool = _WORKOUT_POOL_SAVAGE if tone == "savage" else _WORKOUT_POOL_SUPPORTIVE
    return _pick(pool, seed).format(name=name, metric=metric)


def _deterministic_food_line(stats: Dict[str, Any], tone: str, seed: str) -> Optional[str]:
    value = stats.get("health_score")
    metric = stats.get("metric")  # e.g. "168g protein", "1,840 kcal"
    if value is None and not metric:
        return None
    pool = _FOOD_POOL_SAVAGE if tone == "savage" else _FOOD_POOL_SUPPORTIVE
    return _pick(pool, seed).format(value=value if value is not None else "", metric=metric or "")


def insight_line(
    *,
    user_id: str,
    kind: str,                      # 'workout' | 'food'
    tone: str = "supportive",
    cache_key: str,                 # 'workout:<id>' | 'day:<date>' etc. (tone appended internally)
    local_date: Optional[str] = None,
    stats: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """F2 entry. Returns {line, tone, source, cached}.

    Order of preference (cost-ascending):
      1. share_insight_cache hit                          -> free
      2. existing coach_daily_insights body (date)        -> free
      3. deterministic variant pool (real data)           -> free
      4. one Gemini Flash text call (if AI enabled)       -> cached after
    """
    tone = tone if tone in VALID_TONES else "supportive"
    stats = stats or {}
    full_key = f"{cache_key}:{tone}"

    # 1. cached share line
    hit = _insight_cache_get(full_key)
    if hit:
        return {"line": hit["line"], "tone": tone, "source": hit.get("source", "cache"), "cached": True}

    # 2. reuse an existing coach insight (supportive tone only — the coach voice
    #    is supportive; a savage roast still routes to the deterministic pool).
    if tone == "supportive" and local_date:
        coach_line = _reuse_coach_insight(user_id, local_date)
        if coach_line:
            _insight_cache_put(cache_key=full_key, user_id=user_id, line=coach_line,
                               tone=tone, source="coach_insight")
            return {"line": coach_line, "tone": tone, "source": "coach_insight", "cached": False}

    # 3. deterministic variant pool from real stats
    if kind == "food":
        det = _deterministic_food_line(stats, tone, full_key)
    else:
        det = _deterministic_workout_line(stats, tone, full_key)
    if det:
        _insight_cache_put(cache_key=full_key, user_id=user_id, line=det,
                           tone=tone, source="deterministic")
        return {"line": det, "tone": tone, "source": "deterministic", "cached": False}

    # 4. last resort: one cached Flash call (only if enabled + we have *some* data)
    if insight_ai_enabled() and stats:
        line = _ai_flash_line(kind=kind, tone=tone, stats=stats, user_id=user_id)
        if line:
            _insight_cache_put(cache_key=full_key, user_id=user_id, line=line,
                               tone=tone, source="ai_flash")
            return {"line": line, "tone": tone, "source": "ai_flash", "cached": False}

    # No data at all -> honest empty (caller decides whether to show the row).
    return {"line": "", "tone": tone, "source": "none", "cached": False}


def _ai_flash_line(*, kind: str, tone: str, stats: Dict[str, Any], user_id: str) -> Optional[str]:
    """ONE Gemini Flash text call. Synchronous wrapper so the deterministic
    callers stay simple. Returns None on any failure (caller already tried the
    deterministic pool, so None just means 'show no line')."""
    voice = "savage, playful gym-bro roast (never mean about the body)" if tone == "savage" \
        else "warm, supportive coach"
    facts = ", ".join(f"{k}={v}" for k, v in stats.items() if v not in (None, "", []))
    prompt = (
        f"Write ONE short share-card caption (max 12 words, no hashtags, no quotes) "
        f"in a {voice} voice about today's {kind} stats: {facts}. "
        f"Use the real numbers. Output only the caption."
    )
    try:
        from google.genai import types
        from services.gemini.constants import gemini_generate_with_retry_sync

        resp = gemini_generate_with_retry_sync(
            model=_settings.gemini_vision_model,  # Flash Lite — cheapest text path
            contents=[prompt],
            config=types.GenerateContentConfig(
                temperature=0.8,
                max_output_tokens=40,
                thinking_config=types.ThinkingConfig(thinking_budget=0),
            ),
            timeout=20,
            method_name="share_ai_insight_line",
        )
        text = (getattr(resp, "text", "") or "").strip().strip('"')
        return text or None
    except Exception as e:
        logger.warning(f"[ShareAI] Flash insight line failed (using none): {e}")
        return None
