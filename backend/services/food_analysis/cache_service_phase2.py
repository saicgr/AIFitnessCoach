"""Phase 2 additions to FoodAnalysisCacheService.

This module is a MIXIN that adds the Phase-2 runtime engine to the existing
FoodAnalysisCacheService class without bloating the 2300-line cache_service_helpers
file. Includes:

  * `_normalize_food_name()` — name canonicalization (strips brand symbols,
    lowercases, normalizes whitespace) used at every cache-stack boundary.
  * `_try_user_contributed()` — new layer 0b (between saved_foods and
    canonical) reading from food_overrides_user_contributed.
  * `_upsert_user_contributed()` — auto-write on Gemini fallback, gated by
    users.contribute_food_data flag.
  * `analyze_dishes_from_vision()` — vision-shaped lookup entrypoint.
  * `analyze_menu_from_vision()` — menu-shaped with menu_scan_cache.
  * `_decompose_compound_text()` — Stage-1 text decompose.
  * `_resilient_db_execute()` — wrapper for pooler-resilient DB calls
    (mirrors backfill_override_micronutrients.py:_resilient_execute).
  * 3-tier hot caches via RedisCache.

Mix into FoodAnalysisCacheService by adding to the class bases.
"""
from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import re
from typing import Any, Dict, List, Literal, Optional, Tuple

import asyncpg
from google.genai import types
from sqlalchemy import text

from core.redis_cache import RedisCache
from core.supabase_client import get_supabase
from models.gemini_schemas import (
    Stage1CompoundComponent,
    Stage1CompoundDecompose,
    Stage1Dish,
    Stage1DishIdentification,
    Stage1MenuItem,
    Stage1MenuIdentification,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Hot caches — 3 tiers per HOTCACHE plan section
# ---------------------------------------------------------------------------
# Reuses the existing RedisCache (Redis primary + per-worker in-memory fallback).
# Memory footprint estimates assume ~1.5KB per row (29 nutrient cols + 9
# enrichment + macros + name) for canonical, smaller for user_contributed
# since most users have a short personal-favorites list.

_canonical_cache = RedisCache(
    prefix="food_canonical_v1", ttl_seconds=86400, max_size=2000,
)
_user_contributed_cache = RedisCache(
    prefix="food_user_contrib_v1", ttl_seconds=3600, max_size=10000,
)
_menu_scan_cache_hot = RedisCache(
    prefix="food_menu_scan_v1", ttl_seconds=3600, max_size=500,
)


# ---------------------------------------------------------------------------
# Name normalization — applied at EVERY cache boundary
# ---------------------------------------------------------------------------

# Strip common brand/legal symbols + non-letter prefixes/suffixes.
_BRAND_SYMBOL_RE = re.compile(r"[®™©℠]")
_MULTI_WS_RE = re.compile(r"\s+")
_LEADING_ARTICLE_RE = re.compile(r"^(the|a|an)\s+", re.IGNORECASE)
_NON_FOOD_TOKEN_RE = re.compile(
    r"\b(brand|inc|llc|corp|company|co|ltd|original|classic|signature|gourmet)\b",
    re.IGNORECASE,
)


def _normalize_food_name(raw: str) -> str:
    """Canonical normalization for cache keys + DB lookups.

    Per §B2: strips Big Mac® → big_mac, IHOP® Original Pancakes → ihop_pancakes,
    leading articles, multi-whitespace, lowercases. Single source of truth
    for every Phase-2 cache boundary.
    """
    if not raw:
        return ""
    s = str(raw).strip()  # strip leading/trailing whitespace FIRST so that
                          # _LEADING_ARTICLE_RE matches "The Whopper" not "  The Whopper"
    s = _BRAND_SYMBOL_RE.sub("", s)
    s = _LEADING_ARTICLE_RE.sub("", s)
    s = _NON_FOOD_TOKEN_RE.sub("", s)
    # Normalize whitespace + lowercase + collapse multi-whitespace
    s = s.replace("_", " ")
    s = _MULTI_WS_RE.sub(" ", s).strip().lower()
    # Canonical DB form uses underscores between words (e.g.
    # 'baked_chicken_breast', 'big_mac_american'). Output in that form so
    # exact-match lookups against food_nutrition_overrides_canonical hit
    # cleanly. Fuzzy lookup (trigram '%') tolerates either form anyway.
    return s.replace(" ", "_")


# ---------------------------------------------------------------------------
# Pooler-resilient DB execution (mirrors Phase-1 backfill pattern)
# ---------------------------------------------------------------------------

_TRANSIENT_DB_ERRORS = (
    asyncpg.exceptions.QueryCanceledError,
    asyncpg.exceptions.ConnectionDoesNotExistError,
    asyncpg.exceptions.ConnectionFailureError,
    asyncpg.exceptions.InterfaceError,
    asyncio.TimeoutError,
    OSError,
)
_DB_RETRY_BACKOFF = (1.0, 3.0, 10.0)


async def _resilient_db_execute(op_name: str, fn, max_retries: int = 3):
    """Run an async DB op with retry on transient pooler errors.

    Phase 2 runtime queries are smaller than Phase 1 backfill batches so the
    backoff schedule is tighter (1/3/10s vs 5/15/30s).
    """
    last_err: Exception | None = None
    for attempt in range(max_retries + 1):
        try:
            return await fn()
        except _TRANSIENT_DB_ERRORS as e:
            last_err = e
            if attempt < max_retries:
                delay = _DB_RETRY_BACKOFF[min(attempt, len(_DB_RETRY_BACKOFF) - 1)]
                logger.warning(
                    f"[db:{op_name}] attempt {attempt + 1} failed "
                    f"({type(e).__name__}: {str(e)[:80]}) — retry in {delay:.0f}s"
                )
                await asyncio.sleep(delay)
                continue
            break
    logger.error(f"[db:{op_name}] PERMANENT FAILURE after {max_retries + 1}: {last_err}")
    raise last_err


# ---------------------------------------------------------------------------
# Mixin class — extends FoodAnalysisCacheService
# ---------------------------------------------------------------------------

# All 29 micronutrient columns (must stay in sync with mig 324 + 2073)
_MICRONUTRIENT_COLS = (
    "saturated_fat_g", "trans_fat_g", "cholesterol_mg",
    "sodium_mg", "potassium_mg", "calcium_mg", "iron_mg", "magnesium_mg",
    "zinc_mg", "phosphorus_mg", "selenium_ug", "copper_mg", "manganese_mg",
    "vitamin_a_ug", "vitamin_c_mg", "vitamin_d_iu",
    "vitamin_e_mg", "vitamin_k_ug",
    "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg", "vitamin_b5_mg",
    "vitamin_b6_mg", "vitamin_b7_ug", "vitamin_b9_ug", "vitamin_b12_ug",
    "choline_mg",
    "omega3_g", "omega6_g",
)
# 9 enrichment columns (mig 2064)
_ENRICHMENT_COLS = (
    "inflammation_score", "inflammation_triggers", "glycemic_load",
    "fodmap_rating", "fodmap_reason", "added_sugar_g",
    "is_ultra_processed", "rating", "rating_reason",
)
# 6 macros (per 100g)
_MACRO_COLS = (
    "calories_per_100g", "protein_per_100g", "carbs_per_100g",
    "fat_per_100g", "fiber_per_100g", "sugar_per_100g",
)


def _row_macros_complete(row: Dict[str, Any]) -> bool:
    """A canonical / user_contributed row is 'complete' for runtime use if
    calories>0 AND at least one macro is populated. Rows where ALL macros
    are NULL/0 are the Phase-1 backfill data gap — we treat those as a
    partial hit and fall through to Stage-2 Gemini.

    NOTE: a single macro being 0 is legitimate (chicken wings have ~0g
    carbs, butter has ~0g protein, protein powder has ~0g fat). Only
    reject when ALL three macros are missing/zero.
    """
    cals = row.get("calories_per_100g")
    if cals is None or cals <= 0:
        return False
    populated = 0
    for col in ("protein_per_100g", "carbs_per_100g", "fat_per_100g"):
        v = row.get(col)
        if v is not None and v > 0:
            populated += 1
    return populated >= 1


def _row_to_food_item(
    row: Dict[str, Any],
    weight_g: float,
    name_override: Optional[str] = None,
) -> Dict[str, Any]:
    """Convert a DB row (canonical or user_contributed) into the food_item
    dict shape expected by /log-direct + the streaming response. Scales
    per-100g fields by the supplied weight_g.

    NOTE: callers should gate on `_row_macros_complete(row)` BEFORE invoking
    this — if the row is partial, callers should treat it as a miss and route
    the dish to Stage-2 Gemini instead. We still warn-log here for any
    partial row that slipped through, so the bench can spot drift.
    """
    ratio = weight_g / 100.0
    if not _row_macros_complete(row):
        logger.warning(
            f"[_row_to_food_item] PARTIAL ROW served — "
            f"name={row.get('food_name_normalized')!r} "
            f"calories_per_100g={row.get('calories_per_100g')} "
            f"protein={row.get('protein_per_100g')} "
            f"carbs={row.get('carbs_per_100g')} "
            f"fat={row.get('fat_per_100g')} "
            "(should have routed to Stage-2 — bug in caller)"
        )
    item: Dict[str, Any] = {
        "name": name_override or row.get("display_name") or row.get("food_name_normalized"),
        "weight_g": weight_g,
        "calories": int(round((row.get("calories_per_100g") or 0) * ratio)),
        "protein_g": round((row.get("protein_per_100g") or 0) * ratio, 1),
        "carbs_g": round((row.get("carbs_per_100g") or 0) * ratio, 1),
        "fat_g": round((row.get("fat_per_100g") or 0) * ratio, 1),
        "fiber_g": round((row.get("fiber_per_100g") or 0) * ratio, 1),
        "sugar_g": round((row.get("sugar_per_100g") or 0) * ratio, 1),
    }
    # Scale all 29 micronutrients (skip None values — leave as None, not 0)
    for col in _MICRONUTRIENT_COLS:
        v = row.get(col)
        item[col] = round(v * ratio, 2) if v is not None else None
    # Enrichment fields are per-dish (NOT scaled by portion — same intensity)
    for col in _ENRICHMENT_COLS:
        item[col] = row.get(col)
    return item


class FoodAnalysisCacheServicePhase2:
    """Mixin adding Phase 2 runtime engine to FoodAnalysisCacheService."""

    # ---- Layer 0b: user_contributed lookup -------------------------------

    async def _try_user_contributed(
        self, name_normalized: str, user_id: Optional[str]
    ) -> Optional[Dict[str, Any]]:
        """Layer 0b — per-user cache from past Gemini fallbacks. Returns the
        DB row (already enriched) or None. Bumps log_count + last_logged_at
        atomically on hit.

        Privacy: short-circuits when user_id is None (anonymous / guest).
        """
        if not user_id or not name_normalized:
            return None
        # Hot cache check (per-user keyed)
        cache_key = f"{user_id}:{name_normalized}"
        cached = await _user_contributed_cache.get(cache_key)
        if cached is not None:
            return cached

        async def _fetch():
            supabase = get_supabase()
            async with supabase.get_session() as session:
                # NOTE: do NOT use `:uid::uuid` syntax — SQLAlchemy text()'s
                # `:` named-param syntax collides with PostgreSQL's `::` cast
                # operator under asyncpg + PgBouncer transaction pooling, and
                # the whole UPDATE silently fails with `PostgresSyntaxError:
                # syntax error at or near ":"`. Use portable `CAST(... AS uuid)`.
                result = await session.execute(
                    text("""
                        UPDATE food_overrides_user_contributed
                        SET log_count = log_count + 1,
                            last_logged_at = NOW()
                        WHERE user_id = CAST(:uid AS uuid)
                          AND food_name_normalized = :name
                        RETURNING *
                    """),
                    {"uid": user_id, "name": name_normalized},
                )
                row = result.fetchone()
                # Commit since we mutated (UPDATE)
                await session.commit()
                return dict(row._mapping) if row else None

        try:
            row = await _resilient_db_execute("user_contributed_lookup", _fetch)
        except Exception as e:  # noqa: BLE001
            logger.warning(f"[user_contributed] lookup failed for {user_id}/{name_normalized}: {e}")
            return None

        if row:
            await _user_contributed_cache.set(cache_key, row)
        return row

    # ---- Layer 4 auto-upsert: novel dish writeback -----------------------

    async def _upsert_user_contributed(
        self,
        user_id: Optional[str],
        food_name_normalized: str,
        display_name: str,
        analysis_item: Dict[str, Any],
    ) -> None:
        """Auto-write a Gemini-fallback result to food_overrides_user_contributed.

        Gated by users.contribute_food_data flag (per §2.11). When user is
        opted out, this is a no-op — their data still lands in food_log but
        not in the per-user contributed cache.
        """
        if not user_id or not food_name_normalized:
            return

        # Opt-out check
        async def _check_opt_in():
            supabase = get_supabase()
            async with supabase.get_session() as session:
                result = await session.execute(
                    # `CAST(:uid AS uuid)` — see L226-230 for why we don't use `::`
                    text("SELECT contribute_food_data FROM users WHERE id = CAST(:uid AS uuid) LIMIT 1"),
                    {"uid": user_id},
                )
                row = result.fetchone()
                if row is None:
                    return True
                return row._mapping.get("contribute_food_data", True)

        try:
            opted_in = await _resilient_db_execute("contribute_opt_in_check", _check_opt_in)
        except Exception:
            opted_in = True  # On DB failure, default to opted-in (data lands)
        if not opted_in:
            logger.info(f"[user_contributed] user={user_id} opted out — skipping upsert")
            return

        # Build the column list dynamically to handle missing fields gracefully.
        # For ratio: analysis_item carries per-serving values; we want per-100g.
        # The vision/text path always passes weight_g so we can normalize.
        weight_g = float(analysis_item.get("weight_g") or 0)
        if weight_g <= 0:
            logger.warning(
                f"[user_contributed] skip upsert ({food_name_normalized!r}): "
                "missing weight_g, can't compute per-100g"
            )
            return
        scale = 100.0 / weight_g

        def _per100(field_serving: str) -> Optional[float]:
            v = analysis_item.get(field_serving)
            return round(float(v) * scale, 2) if v is not None else None

        params = {
            "user_id": user_id,
            "food_name_normalized": food_name_normalized,
            "display_name": display_name or food_name_normalized,
            "calories_per_100g": _per100("calories"),
            "protein_per_100g": _per100("protein_g"),
            "carbs_per_100g": _per100("carbs_g"),
            "fat_per_100g": _per100("fat_g"),
            "fiber_per_100g": _per100("fiber_g"),
            "sugar_per_100g": _per100("sugar_g"),
        }
        # Enrichment fields pass through unchanged (not scaled — they're
        # per-dish ratings, not per-100g amounts)
        for col in _ENRICHMENT_COLS:
            params[col] = analysis_item.get(col)
        # Micronutrients in food_log row are typically already per-serving;
        # scale to per-100g
        for col in _MICRONUTRIENT_COLS:
            params[col] = _per100(col) if analysis_item.get(col) is not None else None

        # Build INSERT ... ON CONFLICT ... DO UPDATE dynamically
        cols = list(params.keys())
        placeholders = [f"${i+1}" for i in range(len(cols))]
        update_set = ", ".join(
            f"{c} = COALESCE(EXCLUDED.{c}, food_overrides_user_contributed.{c})"
            for c in cols if c not in ("user_id", "food_name_normalized")
        )
        sql = f"""
            INSERT INTO food_overrides_user_contributed
              ({", ".join(cols)}, source, log_count, first_logged_at, last_logged_at)
            VALUES ({", ".join(placeholders)}, 'gemini_runtime', 1, NOW(), NOW())
            ON CONFLICT (user_id, food_name_normalized) DO UPDATE SET
              {update_set},
              log_count = food_overrides_user_contributed.log_count + 1,
              last_logged_at = NOW()
        """

        async def _upsert():
            # SQLAlchemy named-bindparam version of the dynamic INSERT
            named_params = {f"p{i}": v for i, v in enumerate(params.values())}
            placeholders = [f":p{i}" for i in range(len(params))]
            sql_named = f"""
                INSERT INTO food_overrides_user_contributed
                  ({", ".join(cols)}, source, log_count, first_logged_at, last_logged_at)
                VALUES ({", ".join(placeholders)}, 'gemini_runtime', 1, NOW(), NOW())
                ON CONFLICT (user_id, food_name_normalized) DO UPDATE SET
                  {update_set},
                  log_count = food_overrides_user_contributed.log_count + 1,
                  last_logged_at = NOW()
            """
            supabase = get_supabase()
            async with supabase.get_session() as session:
                await session.execute(text(sql_named), named_params)
                await session.commit()

        try:
            await _resilient_db_execute("user_contributed_upsert", _upsert)
            # Bust hot cache so the next read sees the fresh row
            await _user_contributed_cache.delete(f"{user_id}:{food_name_normalized}")
            logger.info(
                f"[user_contributed] upsert ok user={user_id} dish={food_name_normalized!r}"
            )
        except Exception as e:  # noqa: BLE001
            logger.warning(
                f"[user_contributed] upsert FAILED user={user_id} "
                f"dish={food_name_normalized!r}: {e}"
            )

    # ---- Layer 0c: canonical lookup with hot cache + batch ---------------

    async def _batch_canonical_lookup(
        self, name_normalizeds: List[str],
    ) -> Dict[str, Optional[Dict[str, Any]]]:
        """Hot-cache wrapper around the canonical Postgres lookup. Returns
        a dict mapping each input name to its row (or None if not found)."""
        out: Dict[str, Optional[Dict[str, Any]]] = {}
        miss: List[str] = []
        for n in name_normalizeds:
            cached = await _canonical_cache.get(n)
            if cached is not None:
                out[n] = cached if cached else None
            else:
                miss.append(n)

        if miss:
            async def _query():
                supabase = get_supabase()
                async with supabase.get_session() as session:
                    # SQLAlchemy + asyncpg: use IN with expanding bindparam
                    # instead of `ANY(:names::text[])` which mangles the cast.
                    from sqlalchemy import bindparam
                    stmt = text("""
                        SELECT DISTINCT ON (food_name_normalized) *
                        FROM food_nutrition_overrides_canonical
                        WHERE food_name_normalized IN :names
                    """).bindparams(bindparam("names", expanding=True))
                    result = await session.execute(stmt, {"names": miss})
                    return [dict(r._mapping) for r in result.fetchall()]

            try:
                rows = await _resilient_db_execute("canonical_batch_lookup", _query)
            except Exception as e:  # noqa: BLE001
                logger.warning(f"[canonical_batch] lookup failed: {e}")
                rows = []

            hit_names = set()
            for r in rows:
                name = r["food_name_normalized"]
                # Rows already converted to dict by the query helper
                out[name] = r
                hit_names.add(name)
                await _canonical_cache.set(name, r)
            for n in miss:
                if n not in hit_names:
                    out[n] = None
                    # Cache empty miss for shorter window so a future write
                    # doesn't get blocked. Use empty list as miss sentinel.
                    await _canonical_cache.set(n, [], ttl_override=300)
        return out

    async def _fuzzy_canonical_lookup(
        self, name_normalized: str,
    ) -> Optional[Dict[str, Any]]:
        """Trigram fuzzy match for names that don't exact-match canonical.
        Used for typo tolerance + cuisine-name variation."""
        if not name_normalized:
            return None

        async def _query():
            supabase = get_supabase()
            async with supabase.get_session() as session:
                result = await session.execute(
                    text("""
                        SELECT * FROM food_nutrition_overrides_canonical
                        WHERE food_name_normalized % :name
                        ORDER BY similarity(food_name_normalized, :name) DESC
                        LIMIT 1
                    """),
                    {"name": name_normalized},
                )
                row = result.fetchone()
                return dict(row._mapping) if row else None

        try:
            return await _resilient_db_execute("canonical_fuzzy", _query)
        except Exception as e:  # noqa: BLE001
            logger.warning(f"[canonical_fuzzy] lookup failed for {name_normalized!r}: {e}")
            return None

    # ---- Vision-shaped lookup (Stage 1.5) --------------------------------

    async def analyze_dishes_from_vision(
        self,
        dishes: List[Stage1Dish],
        user_context: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Stage-1.5: given Stage-1 vision identification, look up macros +
        enrichment + micronutrients from the cache stack.

        Returns the same shape as analyze_food_image() so /analyze-image-stream
        can swap in cleanly. Composes the cache-stack lookup chain:
          user_contributed → canonical (exact) → canonical (fuzzy) → USDA → Gemini fallback
        """
        user_id = user_context.get("user_id")
        meal_type = user_context.get("meal_type", "lunch")
        cuisine_tag = user_context.get("cuisine_tag")

        # Normalize all names up front (single source of truth)
        normalized_to_dish: Dict[str, Stage1Dish] = {}
        for d in dishes:
            n = _normalize_food_name(d.name)
            if n:
                normalized_to_dish.setdefault(n, d)

        all_names = list(normalized_to_dish.keys())

        # Run user_contributed (per-name) and canonical (batch) in parallel
        user_results: Dict[str, Optional[Dict[str, Any]]] = {}
        if user_id:
            uc_tasks = {
                n: asyncio.create_task(self._try_user_contributed(n, user_id))
                for n in all_names
            }
            for n, t in uc_tasks.items():
                user_results[n] = await t
        canonical_results = await self._batch_canonical_lookup(all_names)

        food_items: List[Dict[str, Any]] = []
        novel: List[Tuple[str, Stage1Dish]] = []  # (normalized_name, Stage1Dish)
        served_by: Dict[str, str] = {}  # diag: which layer fed each dish
        for name, dish in normalized_to_dish.items():
            row = None
            layer = None
            uc_row = user_results.get(name)
            if uc_row is not None and _row_macros_complete(uc_row):
                row, layer = uc_row, "user_contributed"
            else:
                ca_row = canonical_results.get(name)
                if ca_row is not None and _row_macros_complete(ca_row):
                    row, layer = ca_row, "canonical_exact"
                else:
                    fz_row = await self._fuzzy_canonical_lookup(name)
                    if fz_row is not None and _row_macros_complete(fz_row):
                        row, layer = fz_row, "canonical_fuzzy"

            if row is None:
                # Either no hit, OR a partial-macros row that we refuse to
                # serve. Route to Stage-2 Gemini.
                novel.append((name, dish))
                served_by[name] = "pending_stage2"
                continue
            served_by[name] = layer
            food_items.append(_row_to_food_item(
                row, dish.weight_g_estimate, name_override=dish.name,
            ))

        # Stage-2 fallback for novel dishes — single batched Gemini call
        if novel:
            novel_results = await self._stage2_gemini_for_novel(novel, user_context)
            for (name, dish), result in zip(novel, novel_results):
                if result:
                    food_items.append(result)
                    served_by[name] = "stage2_gemini"
                    # Auto-upsert to user_contributed (gated by opt-out)
                    await self._upsert_user_contributed(
                        user_id, name, dish.name, result,
                    )
                else:
                    served_by[name] = "stage2_failed"

        # Diag: per-dish served_by trace lets the bench attribute hits per layer
        logger.info(
            f"[analyze_dishes_from_vision] served_by={served_by} "
            f"n_food_items={len(food_items)} user_id={user_id}"
        )

        # Aggregate response shape (same as analyze_food_image)
        if not food_items:
            raise RuntimeError("Stage 1.5 produced no food items (all lookups + novel fallback failed)")

        total_cal = sum(int(it.get("calories", 0)) for it in food_items)
        total_p = sum(float(it.get("protein_g", 0)) for it in food_items)
        total_c = sum(float(it.get("carbs_g", 0)) for it in food_items)
        total_f = sum(float(it.get("fat_g", 0)) for it in food_items)
        total_fib = sum(float(it.get("fiber_g", 0)) for it in food_items)
        total_sugar = sum(float(it.get("sugar_g", 0) or 0) for it in food_items)

        return {
            "meal_type": meal_type,
            "food_items": food_items,
            "total_calories": total_cal,
            "total_protein_g": round(total_p, 1),
            "total_carbs_g": round(total_c, 1),
            "total_fat_g": round(total_f, 1),
            "total_fiber_g": round(total_fib, 1),
            "health_score": self._compute_health_score(
                total_cal, total_p, total_fib, total_c, total_sugar
            ),
            "feedback": "",  # populated by enrich_with_tips later if requested
            "_cache_metadata": {
                "novel_count": len(novel),
                "cuisine_tag": cuisine_tag,
                "n_user_contributed_hits": sum(1 for r in user_results.values() if r),
                "n_canonical_hits": sum(1 for r in canonical_results.values() if r),
            },
        }

    async def _stage2_gemini_for_novel(
        self,
        novel: List[Tuple[str, Stage1Dish]],
        user_context: Dict[str, Any],
    ) -> List[Optional[Dict[str, Any]]]:
        """Estimate macros + enrichment + micronutrients for novel dishes via
        Gemini. One `parse_food_description` call per dish, but fired
        CONCURRENTLY (Semaphore-capped) — a 7-component compound meal used to
        take 7×latency sequentially; now it's ~1×latency.
        """
        sem = asyncio.Semaphore(5)  # cap concurrent Gemini calls

        async def _one(name: str, dish: Stage1Dish) -> Optional[Dict[str, Any]]:
            description = f"{dish.name} ({dish.weight_g_estimate:.0f}g)"
            async with sem:
                try:
                    # Hard 15s cap per dish — bounds the tail so one slow
                    # Gemini call can't drag a whole multi-dish scan to 30s+.
                    analysis = await asyncio.wait_for(
                        self.gemini_service.parse_food_description(
                            description=description,
                            user_id=user_context.get("user_id"),
                        ),
                        timeout=15.0,
                    )
                except asyncio.TimeoutError:
                    logger.warning(f"[stage2_gemini] TIMEOUT (>15s) for {dish.name!r}")
                    return None
                except Exception as e:  # noqa: BLE001
                    logger.warning(f"[stage2_gemini] failed for {dish.name!r}: {e}")
                    return None
            items = (analysis or {}).get("food_items") or []
            if not items:
                logger.warning(
                    f"[stage2_gemini] empty food_items for {dish.name!r} — "
                    f"analysis keys={list(analysis.keys()) if analysis else None}"
                )
                return None
            result = items[0]
            # Carry over enrichment if Gemini populated it
            for col in _ENRICHMENT_COLS:
                if col not in result and col in analysis:
                    result[col] = analysis.get(col)
            # Macro-completeness check — only flag if ALL three macros are
            # zero/missing (single-macro=0 is legit: wings have ~0g carbs).
            cal = float(result.get("calories") or 0)
            p = float(result.get("protein_g") or 0)
            c = float(result.get("carbs_g") or 0)
            f = float(result.get("fat_g") or 0)
            if cal > 0 and p <= 0 and c <= 0 and f <= 0:
                logger.warning(
                    f"[stage2_gemini] ALL-ZERO MACROS for {dish.name!r}: "
                    f"cal={cal} p={p} c={c} f={f} — flagging _macro_unknown=True"
                )
                result["_macro_unknown"] = True
            return result

        # gather preserves order → aligns with the zip(novel, results) caller
        return await asyncio.gather(*[_one(n, d) for n, d in novel])

    @staticmethod
    def _compute_health_score(
        calories: int,
        protein_g: float,
        fiber_g: float,
        carbs_g: Optional[float] = None,
        sugar_g: Optional[float] = None,
    ) -> int:
        """Deterministic 1-10 health score from macros (no Gemini).

        Rewards protein and fiber; penalizes high calories, high added/total
        sugar, and low fiber density relative to carbs (a refined-carb signal).
        ``carbs_g`` and ``sugar_g`` are optional — when omitted the refined-carb
        and sugar penalties are skipped (back-compatible with older callers).
        """
        score = 5
        if protein_g >= 20:
            score += 2
        elif protein_g >= 10:
            score += 1
        if fiber_g >= 5:
            score += 2
        elif fiber_g >= 3:
            score += 1
        if calories > 800:
            score -= 2
        elif calories > 600:
            score -= 1

        # Refined-carb penalty — combines a high-sugar signal and a
        # low-fiber-density signal. Added sugar and refined starch overlap
        # heavily, so the two sub-signals are summed then capped at -2 to
        # avoid an unrealistically harsh double penalty (tuned so a
        # pancakes+syrup breakfast lands ~4, a whole-food meal stays 8+).
        refined_penalty = 0

        # High added/total sugar.
        if sugar_g is not None:
            if sugar_g >= 25:
                refined_penalty += 2
            elif sugar_g >= 15:
                refined_penalty += 1

        # Low fiber density relative to carbs. A carb-heavy meal (>= 30g
        # carbs) that delivers almost no fiber is refined starch/sugar.
        if carbs_g is not None and carbs_g >= 30:
            fiber_ratio = fiber_g / carbs_g if carbs_g > 0 else 0.0
            if fiber_ratio < 0.05:
                refined_penalty += 2
            elif fiber_ratio < 0.10:
                refined_penalty += 1

        score -= min(refined_penalty, 2)

        return max(1, min(10, score))

    # ---- Menu-shaped lookup (with menu_scan_cache) -----------------------

    async def analyze_menu_from_vision(
        self,
        identification: Stage1MenuIdentification,
        user_context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Menu-scan: leverage cross-user menu_scan_cache table + restaurant-
        filtered canonical lookup."""
        restaurant = identification.restaurant_name or "unknown"
        dish_names = [_normalize_food_name(it.name) for it in identification.items]
        dish_names = [n for n in dish_names if n]
        if not dish_names:
            raise RuntimeError("Menu Stage 1.5: no valid dish names after normalization")

        # SHA256 of sorted unique dish names = menu fingerprint
        menu_hash = hashlib.sha256(
            ",".join(sorted(set(dish_names))).encode("utf-8")
        ).hexdigest()

        # Cross-user menu_scan_cache hit?
        async def _check_menu_cache():
            supabase = get_supabase()
            async with supabase.get_session() as session:
                result = await session.execute(
                    text("""
                        UPDATE menu_scan_cache
                        SET scan_count = scan_count + 1, last_scanned_at = NOW()
                        WHERE restaurant_name = :rest AND menu_hash = :hash
                          AND expires_at > NOW()
                        RETURNING dishes
                    """),
                    {"rest": restaurant, "hash": menu_hash},
                )
                row = result.fetchone()
                await session.commit()
                return dict(row._mapping) if row else None

        try:
            cached = await _resilient_db_execute("menu_cache_lookup", _check_menu_cache)
        except Exception:
            cached = None
        if cached:
            logger.info(f"[menu_scan_cache] HIT restaurant={restaurant} hash={menu_hash[:8]}")
            # `cached` is the dict from RETURNING dishes; the value is the JSONB blob
            return cached["dishes"] if isinstance(cached, dict) else cached

        # Restaurant-filtered canonical lookup first (chain restaurants get ~100% hit)
        async def _restaurant_lookup():
            supabase = get_supabase()
            async with supabase.get_session() as session:
                from sqlalchemy import bindparam
                stmt = text("""
                    SELECT DISTINCT ON (food_name_normalized) *
                    FROM food_nutrition_overrides_canonical
                    WHERE restaurant_name ILIKE :rest
                      AND food_name_normalized IN :names
                """).bindparams(bindparam("names", expanding=True))
                result = await session.execute(
                    stmt, {"rest": f"%{restaurant}%", "names": dish_names},
                )
                return [dict(r._mapping) for r in result.fetchall()]

        rows_by_name: Dict[str, Optional[Dict[str, Any]]] = {n: None for n in dish_names}
        if restaurant != "unknown":
            try:
                restaurant_rows = await _resilient_db_execute(
                    "menu_restaurant_lookup", _restaurant_lookup,
                )
                for r in restaurant_rows:
                    rows_by_name[r["food_name_normalized"]] = r
            except Exception as e:  # noqa: BLE001
                logger.warning(f"[menu_restaurant_lookup] failed: {e}")

        # Generic fallback for names still missing
        miss_names = [n for n, row in rows_by_name.items() if row is None]
        if miss_names:
            generic_rows = await self._batch_canonical_lookup(miss_names)
            for n, r in generic_rows.items():
                if r:
                    rows_by_name[n] = r

        # Final stragglers — single batched Gemini fallback
        final_miss = [n for n, row in rows_by_name.items() if row is None]
        novel_results: List[Optional[Dict[str, Any]]] = []
        if final_miss:
            novel_pairs = [
                (n, Stage1Dish(name=n, weight_g_estimate=200, serving_description="1 serving", confidence=0.5))
                for n in final_miss
            ]
            novel_results = await self._stage2_gemini_for_novel(novel_pairs, user_context or {})

        # Assemble response shape: list of dish dicts with name + macros + enrichment
        dishes_out: List[Dict[str, Any]] = []
        novel_idx = 0
        for name in dish_names:
            row = rows_by_name.get(name)
            if row:
                dishes_out.append(_row_to_food_item(
                    row, weight_g=row.get("default_serving_g") or 200, name_override=name,
                ))
            elif novel_idx < len(novel_results) and novel_results[novel_idx]:
                dishes_out.append(novel_results[novel_idx])
                novel_idx += 1
            else:
                novel_idx += 1
                continue

        result = {
            "restaurant_name": identification.restaurant_name,
            "items": dishes_out,
            "_cache_metadata": {
                "from_menu_cache": False,
                "n_restaurant_hits": sum(
                    1 for n, r in rows_by_name.items()
                    if r and r.get("restaurant_name")
                ),
                "n_generic_hits": sum(
                    1 for n, r in rows_by_name.items()
                    if r and not r.get("restaurant_name")
                ),
                "n_novel": len(final_miss),
            },
        }

        # Persist to menu_scan_cache for the next user
        async def _write_menu_cache():
            supabase = get_supabase()
            async with supabase.get_session() as session:
                await session.execute(
                    text("""
                        INSERT INTO menu_scan_cache (restaurant_name, menu_hash, dishes)
                        -- CAST(... AS jsonb) instead of `::jsonb` — see L226-230 for why
                        VALUES (:rest, :hash, CAST(:dishes AS jsonb))
                        ON CONFLICT (restaurant_name, menu_hash) DO UPDATE
                        SET dishes = EXCLUDED.dishes, last_scanned_at = NOW(),
                            expires_at = NOW() + INTERVAL '90 days'
                    """),
                    {"rest": restaurant, "hash": menu_hash, "dishes": json.dumps(result)},
                )
                await session.commit()

        try:
            await _resilient_db_execute("menu_cache_write", _write_menu_cache)
            logger.info(
                f"[menu_scan_cache] WRITE restaurant={restaurant} hash={menu_hash[:8]} "
                f"items={len(dishes_out)}"
            )
        except Exception as e:  # noqa: BLE001
            logger.warning(f"[menu_scan_cache] write failed: {e}")

        return result

    # ---- Compound text decompose (Stage 1 for text) ----------------------

    async def _decompose_compound_text(
        self, description: str,
    ) -> List[Stage1CompoundComponent]:
        """Thin Flash Lite call (~500ms) returning canonical dish components
        for compound queries like '2 eggs over easy with toast and bacon'.

        Single-item inputs ('chicken biryani 1 cup') should NOT call this —
        the caller checks for compound markers before invoking.
        """
        from services.gemini.constants import gemini_generate_with_retry

        prompt = f"""Decompose this compound food description into individual dish components.

INPUT: "{description}"

For each component, return:
- name: normalized dish name (e.g. "scrambled eggs", "white toast", "bacon strips", "orange juice")
- quantity_text: quantity hint from the input ("2", "1 slice", "8 oz", etc.) or null

EXAMPLES:
"2 eggs over easy with toast and bacon" → [
  {{"name": "fried eggs", "quantity_text": "2"}},
  {{"name": "white toast", "quantity_text": "1 slice"}},
  {{"name": "bacon strips", "quantity_text": null}}
]

"chicken sandwich and a coke" → [
  {{"name": "chicken sandwich", "quantity_text": "1"}},
  {{"name": "coca-cola", "quantity_text": "1 can"}}
]

Top-level JSON: {{"components": [...]}}

NO macros, NO calories, NO portions in grams — just identification + quantity hint.
"""

        try:
            response = await gemini_generate_with_retry(
                model="gemini-3.1-flash-lite",
                contents=[prompt],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    temperature=0.1,
                    max_output_tokens=400,
                ),
                method_name="decompose_compound_text",
            )
            raw = (response.text or "").strip()
            if raw.startswith("```"):
                raw = raw.strip("`").lstrip("json").strip()
            parsed = json.loads(raw)
            components = []
            for c in parsed.get("components", [])[:15]:
                try:
                    components.append(Stage1CompoundComponent.model_validate(c))
                except Exception as e:  # noqa: BLE001
                    logger.warning(f"[decompose] skip bad component {c}: {e}")
            return components
        except Exception as e:  # noqa: BLE001
            logger.warning(f"[decompose] failed for {description!r}: {e}")
            return []

    # ---- Enrichment-skip helper for text path ----------------------------

    def _row_has_enrichment(self, row: Dict[str, Any]) -> bool:
        """True if this row already has the 9 enrichment fields populated.
        Used by enrich_with_tips to skip the text-path Gemini call when
        the override row already carries everything."""
        return (
            row.get("inflammation_score") is not None
            and row.get("fodmap_rating") is not None
            and row.get("rating") is not None
        )

    @staticmethod
    def _is_compound_query(description: str) -> bool:
        """True if the description looks compound (multiple distinct foods).
        Triggers _decompose_compound_text path."""
        if not description or len(description) < 10:
            return False
        # Common compound markers
        if re.search(r"\b(and|with|plus|\+|alongside)\b", description, re.IGNORECASE):
            return True
        # Comma-separated list (≥2 commas implies ≥3 items)
        if description.count(",") >= 1 and len(description.split()) > 4:
            return True
        return False
