"""
Serve-time resolver: attaches REAL `exercise_library_cleaned.instructions`
text onto exercise dicts that a workout-serving endpoint is about to return.

WHY THIS EXISTS: several generation-time builders (curated-program expansion,
staple injection, AI/RAG workout generation) never copy `instructions` into
the exercises_json they write, even though the exact same exercise's DB row
has good instructions right next to the data they're building. Rather than
fixing every generation-time builder and backfilling already-persisted rows,
this resolves instructions LIVE at serve time — the same shape of fix as
`services.exercise_tracking_metric.attach_tracking_metadata`, which already
tags tracking_type/distance_meters at serve time "so curated, AI-generated,
and custom workouts all benefit." This makes every past, present, and future
workout row correct immediately with no backfill and no staleness risk.

Process-cached (mirrors `_LIBRARY_META_CACHE` in program_template_expander.py):
built once per worker process from exercise_library_cleaned (~2,378 rows) —
cheap in-memory dict lookups after that, no per-request DB round trip.
"""
from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

_PAGE_SIZE = 1000

# name (normalized) -> instructions. None until first successful load attempt.
_NAME_CACHE: Optional[Dict[str, str]] = None

# input name (normalized) -> canonical_name or None. Avoids re-hitting the
# alias RPC for the same chronically-unresolved name across many requests.
_ALIAS_CACHE: Dict[str, Optional[str]] = {}


def _normalize(name: str) -> str:
    return " ".join((name or "").strip().lower().split())


def _ensure_cache_loaded() -> Dict[str, str]:
    """Lazily bulk-load exercise_library_cleaned(name, instructions) once per
    process. Fail-open: any error leaves the cache as an empty dict rather
    than retrying the DB on every subsequent call."""
    global _NAME_CACHE
    if _NAME_CACHE is not None:
        return _NAME_CACHE
    cache: Dict[str, str] = {}
    try:
        from core.db import get_supabase_db
        db = get_supabase_db()
        start = 0
        while True:
            res = (
                db.client.table("exercise_library_cleaned")
                .select("name, instructions")
                .range(start, start + _PAGE_SIZE - 1)
                .execute()
            )
            batch = res.data or []
            for row in batch:
                name = row.get("name")
                instr = row.get("instructions")
                if name and isinstance(instr, str) and instr.strip():
                    cache[_normalize(name)] = instr.strip()
            if len(batch) < _PAGE_SIZE:
                break
            start += _PAGE_SIZE
    except Exception as e:  # noqa: BLE001 — never block serving on this
        logger.warning("exercise_instructions_resolver: cache load failed: %s", e)
        cache = {}
    _NAME_CACHE = cache
    return _NAME_CACHE


def get_instructions_for_name(name: Optional[str]) -> Optional[str]:
    """Real DB instructions for an exercise name, or None if unresolvable.
    Exact normalized-name match first; falls back to the same alias/canonical
    stack the media resolver uses (resolve_exercise_demo_media RPC) for names
    that don't match verbatim (e.g. "SkiErg Interval" vs "Ski Erg Intervals").
    Fail-open: never raises."""
    if not name:
        return None
    cache = _ensure_cache_loaded()
    norm = _normalize(name)
    hit = cache.get(norm)
    if hit:
        return hit

    canonical = _ALIAS_CACHE.get(norm, "__unset__")
    if canonical == "__unset__":
        canonical = None
        try:
            from core.db import get_supabase_db
            db = get_supabase_db()
            rpc = db.client.rpc(
                "resolve_exercise_demo_media", {"p_name": name}
            ).execute()
            rows = rpc.data or []
            if rows:
                canonical = rows[0].get("canonical_name") or None
        except Exception as e:  # noqa: BLE001 — never block serving on this
            logger.debug(
                "exercise_instructions_resolver: alias lookup failed for %s: %s",
                name, e,
            )
        _ALIAS_CACHE[norm] = canonical

    if canonical:
        return cache.get(_normalize(canonical))
    return None


def attach_instructions(exercises: List[Dict[str, Any]], name_key: str = "name") -> None:
    """In-place: set `instructions` on every dict in [exercises] that doesn't
    already carry a non-blank one. No-op for non-dict entries. Never raises —
    safe to call unconditionally at serve time."""
    if not isinstance(exercises, list):
        return
    for ex in exercises:
        if not isinstance(ex, dict):
            continue
        try:
            existing = ex.get("instructions")
            if isinstance(existing, str) and existing.strip():
                continue
            name = (
                ex.get(name_key)
                or ex.get("name")
                or ex.get("exercise_name")
                or ex.get("original_name")
            )
            instr = get_instructions_for_name(name)
            if instr:
                ex["instructions"] = instr
        except Exception as e:  # noqa: BLE001 — one bad exercise never blocks the rest
            logger.debug("exercise_instructions_resolver: attach failed: %s", e)
