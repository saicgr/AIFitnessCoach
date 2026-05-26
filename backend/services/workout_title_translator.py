"""
workout_title_translator.py — lazy translate-on-read for LLM-generated workout
titles (e.g. "Golden Peak Vitality").

Pipeline (per user-facing read):
    1. resolve_display_title(row, locale) checks
       `workouts.display_title_localized[locale]` first.
    2. Cache hit → return it. Cache miss + locale != "en" → return English
       `row["name"]` AND queue a one-shot background translation via
       `translate_and_persist_async()`. The next read of the same workout
       hits the cache.
    3. English-locale reads never translate — they just return `row["name"]`.

The translator is intentionally a NON-blocking call from the request handler:
the user sees the English title on first view (1 frame) and the localized
title on subsequent views. This trades one-off ~1-2s freshness for
zero-latency hot path + zero cost duplication when many readers hit the same
workout simultaneously (an asyncio.Lock per workout_id deduplicates concurrent
translations).

Why not generate in the user's language at workout-creation time? Because the
backlog of existing English-titled workouts (every workout generated before
this feature shipped) would stay English. Lazy translate-on-read covers the
backfill for free.
"""
from __future__ import annotations

import asyncio
from typing import Any, Dict, Optional

from core.locale import LOCALE_NATIVE_NAMES
from core.logger import get_logger

logger = get_logger(__name__)

# Per-workout async locks so concurrent reads on the same row don't all fire
# a Gemini call. First waiter translates; subsequent waiters re-read the row
# and pick up the cached value.
_locks: Dict[str, asyncio.Lock] = {}
# Bounded set of workout_ids we've already queued for this process lifetime
# to avoid stampeding the translator from many simultaneous requests. Cheap
# circuit breaker — not a correctness guard.
_inflight: set[str] = set()


def resolve_display_title(row: Dict[str, Any], locale: Optional[str]) -> str:
    """Return the best display title for [row] in [locale] WITHOUT awaiting.

    Pure read — never queues a translation. Callers that want lazy fill must
    call `maybe_queue_translation()` separately. Splitting read and queue
    keeps this function safe to use inside sync code paths.
    """
    name = (row or {}).get("name") or ""
    if not name:
        return ""
    lc = (locale or "en").lower()
    if lc == "en":
        return name
    cache = (row or {}).get("display_title_localized") or {}
    if isinstance(cache, dict):
        cached = cache.get(lc)
        if isinstance(cached, str) and cached.strip():
            return cached
    return name


def maybe_queue_translation(
    *,
    workout_id: str,
    name: str,
    locale: str,
    existing_cache: Optional[Dict[str, str]],
    db_client,
) -> None:
    """Fire-and-forget: queue a translation for [name] → [locale] if missing.

    Safe to call from request handlers — the work runs on the current event
    loop as a background task. Idempotent per (workout_id, locale) for the
    lifetime of the process.
    """
    if not name or not workout_id:
        return
    lc = (locale or "").lower()
    if lc in ("", "en"):
        return
    if lc not in LOCALE_NATIVE_NAMES:
        return
    if existing_cache and isinstance(existing_cache, dict) and existing_cache.get(lc):
        return
    key = f"{workout_id}:{lc}"
    if key in _inflight:
        return
    _inflight.add(key)
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        # No running loop — caller is sync without a loop; skip silently.
        _inflight.discard(key)
        return
    loop.create_task(
        _translate_and_persist(workout_id, name, lc, db_client, key=key)
    )


async def _translate_and_persist(
    workout_id: str,
    name: str,
    locale: str,
    db_client,
    *,
    key: str,
) -> None:
    """Background worker — translate via Gemini and write to DB."""
    lock = _locks.setdefault(workout_id, asyncio.Lock())
    try:
        async with lock:
            translated = await _translate(name, locale)
            if not translated or translated.strip() == name.strip():
                logger.debug(
                    f"[WorkoutTitleTranslator] no-op for wid={workout_id} "
                    f"locale={locale} (empty/identical translation)"
                )
                return
            await _persist(workout_id, locale, translated, db_client)
    except Exception as e:
        # Best-effort. Never propagate — the user already saw the English
        # title and we'll retry on the next read.
        logger.warning(
            f"[WorkoutTitleTranslator] failed wid={workout_id} locale={locale}: {e}"
        )
    finally:
        _inflight.discard(key)


async def _translate(name: str, locale: str) -> Optional[str]:
    """Translate [name] into [locale] via the shared Gemini chat path.

    Uses a tight, surgical prompt — we want a 1-3 word localized title, not a
    paraphrase. Brand names and acronyms stay in Latin script (matches the
    chat-locale rules).
    """
    from services.gemini_service import gemini_service  # local — avoids cycle

    native = LOCALE_NATIVE_NAMES.get(locale, locale)
    sys_prompt = (
        f"You are a precise localizer. Translate the workout title to {native} "
        f"({locale}). Return ONLY the translated title — no quotes, no notes, "
        "no preamble, no trailing punctuation. Keep brand names (Zealova) and "
        "fitness acronyms (RPE, 1RM, AMRAP, EMOM, PR) in Latin script. Aim "
        "for 1-4 words; preserve the original tone (energetic / serene / etc)."
    )
    try:
        result = await gemini_service.chat(
            user_message=name,
            system_prompt=sys_prompt,
            locale="en",  # we handle the locale directive ourselves above
        )
    except Exception as e:
        logger.debug(f"[WorkoutTitleTranslator] gemini error: {e}")
        return None
    if not result:
        return None
    # Strip likely wrappers / trailing punctuation.
    out = result.strip().strip('"').strip("'").rstrip(".")
    # Refuse pathological outputs (the model echoed the prompt or returned
    # multiple sentences). 80-char cap is generous; a real localized title
    # never exceeds it.
    if len(out) > 80 or "\n" in out:
        return None
    return out


async def _persist(
    workout_id: str, locale: str, translated: str, db_client
) -> None:
    """Merge [locale] → [translated] into `display_title_localized` JSONB.

    Uses Supabase rpc-free path: read current value, merge, write back. The
    column is intentionally append-only at the JSONB level so concurrent
    writers (different locales for the same row) don't trample each other —
    we only ever ADD a key.
    """
    try:
        # Sync supabase client — we're inside an asyncio task so wrap the
        # blocking calls in run_in_executor.
        loop = asyncio.get_running_loop()

        def _read():
            res = (
                db_client.client.table("workouts")
                .select("display_title_localized")
                .eq("id", workout_id)
                .single()
                .execute()
            )
            return (res.data or {}).get("display_title_localized") or {}

        def _write(merged):
            db_client.client.table("workouts").update(
                {"display_title_localized": merged}
            ).eq("id", workout_id).execute()

        current = await loop.run_in_executor(None, _read)
        if not isinstance(current, dict):
            current = {}
        # Last-write-wins per-locale is fine — translation outputs are
        # deterministic enough that two writers producing different strings
        # for the same locale is exceedingly rare.
        current[locale] = translated
        await loop.run_in_executor(None, _write, current)
        logger.info(
            f"[WorkoutTitleTranslator] cached wid={workout_id} locale={locale}: {translated!r}"
        )
    except Exception as e:
        logger.warning(
            f"[WorkoutTitleTranslator] persist failed wid={workout_id} "
            f"locale={locale}: {e}"
        )
