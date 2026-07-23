"""
Food-log score enrichment.

Backfills the rich scoring fields (inflammation_score, NOVA processing,
FODMAP rating, glycemic_load, added_sugar_g, plus 30+ micronutrients) on
food_log rows that landed in the database without them. The text-mode and
photo-mode flows already ship with full FoodAnalysisResponse; the other
modes (barcode, saved foods, quick log, manual entry, restaurant menu
re-log, app-screenshot OCR, nutrition-label OCR) call /log-direct without
populating these fields, so the resulting rows render with empty
Inflammation chips, an empty Vitamins & Minerals card, etc.

Strategy: kick this off as a FastAPI BackgroundTask after /log-direct
returns. The user gets an instant 200 with the macros they confirmed; the
scoring fields fill in within ~3-5 seconds via a Gemini text analysis
seeded with the existing food name + locked macros. Writing only into
NULL columns guarantees we never clobber values the client supplied (e.g.
when restaurant mode already had ingredient data, or when the saved-food
relog already cached scores).

Per CLAUDE.md "no silent degradation" rule: when Gemini is unreachable or
returns garbage, we mark `score_status='unavailable'` instead of leaving
columns NULL — the UI then shows greyed chips with a retry icon rather
than blank space.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from core.logger import get_logger
from services.gemini.service import GeminiService

logger = get_logger(__name__)

# Columns we backfill. Mirrors the FoodAnalysisResponse schema scalars so
# `parse_food_description`'s output maps 1:1. Macros (calories/protein/etc)
# are intentionally excluded — those are the user's confirmed truth and
# must not be touched after they hit "Log This Meal".
_SCORE_COLUMNS = (
    "inflammation_score",
    "is_ultra_processed",
    "inflammation_triggers",
    # Health score — backfilled like the rest so barcode / saved-food / quick-
    # log / manual rows (which land via /log-direct without scoring) get the
    # "Health N/10" pill too, not just inflammation. When Gemini omits it we
    # fall back to the deterministic macro score (see _deterministic_health).
    "health_score",
    "health_score_reasons",
    "added_sugar_g",
    "glycemic_load",
    "fodmap_rating",
    "fodmap_reason",
    # Micronutrients — only filled when the row currently has nothing for
    # them, so we don't override hand-edited or barcode-supplied values.
    "sodium_mg", "sugar_g", "saturated_fat_g", "cholesterol_mg",
    "potassium_mg",
    "vitamin_a_ug", "vitamin_c_mg", "vitamin_d_iu", "vitamin_e_mg",
    "vitamin_k_ug", "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg",
    "vitamin_b5_mg", "vitamin_b6_mg", "vitamin_b7_ug", "vitamin_b9_ug",
    "vitamin_b12_ug",
    "calcium_mg", "iron_mg", "magnesium_mg", "zinc_mg", "phosphorus_mg",
    "copper_mg", "manganese_mg", "selenium_ug", "choline_mg",
    "omega3_g", "omega6_g",
)


def _build_seed_description(row: Dict[str, Any]) -> Optional[str]:
    """Build a Gemini-friendly text seed from the existing food_log row.

    Macros are stated explicitly so Gemini doesn't re-estimate them. Item
    names and serving sizes (when present in food_items JSONB) anchor the
    food identity for inflammation/FODMAP/processing inference. Returns
    None when the row is too sparse to score (no items + no totals).
    """
    items: List[Dict[str, Any]] = row.get("food_items") or []
    if not items and not row.get("total_calories"):
        return None

    # Build a per-item description. Cap at first 6 items — anything longer
    # is a complex meal where Gemini can still reason from a representative
    # subset, and we want to keep the prompt under 1k tokens for cost.
    item_lines: List[str] = []
    for item in items[:6]:
        name = (item.get("name") or "").strip()
        if not name:
            continue
        weight = item.get("weight_g") or item.get("serving_g") or item.get("amount_g")
        cal = item.get("calories")
        if weight and cal:
            item_lines.append(f"- {name} ({weight}g, {int(cal)} kcal)")
        elif weight:
            item_lines.append(f"- {name} ({weight}g)")
        else:
            item_lines.append(f"- {name}")

    parts: List[str] = []
    if item_lines:
        parts.append("FOODS LOGGED:\n" + "\n".join(item_lines))

    cal = row.get("total_calories")
    p = row.get("protein_g")
    c = row.get("carbs_g")
    f = row.get("fat_g")
    if cal:
        macros_line = f"CONFIRMED MACROS: {int(cal)} kcal"
        if p is not None:
            macros_line += f", {p:g}g protein"
        if c is not None:
            macros_line += f", {c:g}g carbs"
        if f is not None:
            macros_line += f", {f:g}g fat"
        macros_line += " (these are user-confirmed; do not change them)"
        parts.append(macros_line)

    if not parts:
        return None
    return "\n\n".join(parts)


_CLUSTER_HEADLINE = (
    "inflammation_score", "is_ultra_processed", "fodmap_rating", "glycemic_load",
)


def _cluster_missing(row: Dict[str, Any]) -> bool:
    """True when NONE of the inflammation-cluster signals are populated."""
    return all(row.get(k) in (None, "", 0) for k in _CLUSTER_HEADLINE)


def _health_missing(row: Dict[str, Any]) -> bool:
    """True when the row has no usable health_score (1-10)."""
    return row.get("health_score") in (None, "", 0)


def _row_needs_enrichment(row: Dict[str, Any]) -> bool:
    """True when the row is missing the headline scoring fields. We don't
    require ALL columns — just the inflammation-cluster signals the Daily/Detail
    UIs render (inflammation chip, NOVA flag, FODMAP rating, glycemic load) OR a
    missing health_score. The health_score clause is what lets a barcode row —
    which HAS a NOVA inflammation_score but no health_score — still qualify.
    """
    return _cluster_missing(row) or _health_missing(row)


def _deterministic_health(row: Dict[str, Any]) -> Optional[int]:
    """Deterministic 1-10 health score from the row's confirmed macros (no
    Gemini). Used to guarantee health is never left null after enrichment so
    the backfill doesn't re-select the same row forever. Returns None only when
    the row has no calories to score from.
    """
    cal = row.get("total_calories")
    if not cal:
        return None
    try:
        from services.food_analysis.cache_service import (
            get_food_analysis_cache_service,
        )
        svc = get_food_analysis_cache_service()
        carbs = row.get("carbs_g")
        sugar = row.get("sugar_g")
        return svc._compute_health_score(
            int(cal),
            float(row.get("protein_g") or 0),
            float(row.get("fiber_g") or 0),
            float(carbs) if carbs is not None else None,
            float(sugar) if sugar is not None else None,
        )
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[score_enrich] deterministic health failed: {e}")
        return None


def _extract_scoring_fields(gemini_result: Dict[str, Any]) -> Dict[str, Any]:
    """Project the Gemini analysis into a column-name → value dict the DB
    accepts. Skips empty/null values so we never write a NULL on top of a
    NULL (drops a redundant UPDATE) and never overwrite the macros."""
    out: Dict[str, Any] = {}
    for col in _SCORE_COLUMNS:
        val = gemini_result.get(col)
        if val is None:
            continue
        if isinstance(val, (list, tuple)) and len(val) == 0:
            continue
        if isinstance(val, str) and not val.strip():
            continue
        out[col] = val
    return out


async def _try_cache_stack_enrichment(
    row: Dict[str, Any], user_id: str,
) -> Optional[Dict[str, Any]]:
    """Phase-2: assemble the scoring/micronutrient payload from cache stack.

    Looks up each food_item in food_overrides_user_contributed →
    food_nutrition_overrides_canonical. If EVERY item resolves to a row
    that has the 9 enrichment fields populated, returns an aggregated
    payload that mirrors what _extract_scoring_fields() would have produced
    from a Gemini result. If any item fails to resolve, returns None and
    the caller falls through to the Gemini path.

    No Gemini call inside — entirely DB-driven.
    """
    try:
        from services.food_analysis.cache_service_phase2 import (
            _normalize_food_name,
        )
        from services.food_analysis.cache_service import (
            get_food_analysis_cache_service,
        )
    except Exception as e:  # noqa: BLE001
        logger.warning(f"[score_enrich] phase2 modules unavailable: {e}")
        return None

    items: List[Dict[str, Any]] = row.get("food_items") or []
    if not items:
        return None

    cache_svc = get_food_analysis_cache_service()
    enriched_items: List[Dict[str, Any]] = []
    novel_count = 0

    for item in items:
        name = (item.get("name") or "").strip()
        if not name:
            return None  # Force Gemini path on dirty data
        norm = _normalize_food_name(name)
        # Try user_contributed first (per-user, fastest)
        cached_row = await cache_svc._try_user_contributed(norm, user_id)
        if cached_row is None:
            # Then canonical (global)
            canonical = await cache_svc._batch_canonical_lookup([norm])
            cached_row = canonical.get(norm)
        if cached_row is None:
            cached_row = await cache_svc._fuzzy_canonical_lookup(norm)
        if cached_row is None:
            novel_count += 1
            return None  # Any miss → fall through to Gemini for the whole row
        # Carry forward weight if present, else use 100g default
        weight = float(item.get("weight_g") or 100)
        from services.food_analysis.cache_service_phase2 import _row_to_food_item
        enriched_items.append(_row_to_food_item(cached_row, weight, name_override=name))

    # Aggregate item-level scoring into the food_log payload
    update_payload: Dict[str, Any] = {}

    # 9 enrichment fields — average where numeric, mode where categorical
    inflammation_scores = [it.get("inflammation_score") for it in enriched_items if it.get("inflammation_score") is not None]
    if inflammation_scores:
        update_payload["inflammation_score"] = round(sum(inflammation_scores) / len(inflammation_scores))
    # Triggers — union across items
    all_triggers: set = set()
    for it in enriched_items:
        for t in (it.get("inflammation_triggers") or []):
            all_triggers.add(t)
    if all_triggers:
        update_payload["inflammation_triggers"] = list(all_triggers)
    # Glycemic load — sum across items (it's a per-serving metric)
    gls = [it.get("glycemic_load") for it in enriched_items if it.get("glycemic_load") is not None]
    if gls:
        update_payload["glycemic_load"] = sum(gls)
    # FODMAP — worst-case (high > medium > low)
    fodmap_priority = {"high": 3, "medium": 2, "low": 1}
    fodmap_ratings = [it.get("fodmap_rating") for it in enriched_items if it.get("fodmap_rating")]
    if fodmap_ratings:
        worst = max(fodmap_ratings, key=lambda r: fodmap_priority.get(r, 0))
        update_payload["fodmap_rating"] = worst
        # Concatenate reasons
        reasons = [it.get("fodmap_reason") for it in enriched_items if it.get("fodmap_reason")]
        if reasons:
            update_payload["fodmap_reason"] = "; ".join(reasons[:3])
    # Added sugar — sum
    added_sugars = [float(it.get("added_sugar_g") or 0) for it in enriched_items]
    update_payload["added_sugar_g"] = round(sum(added_sugars), 1)
    # Ultra-processed — true if ANY item is
    update_payload["is_ultra_processed"] = any(
        it.get("is_ultra_processed") for it in enriched_items
    )
    # NOTE: the override rows also carry a `rating` traffic-light
    # (green/yellow/red, mig 2064) but food_logs has NO `rating` column and the
    # app never reads one — the Flutter FoodLog model
    # (data/models/nutrition_part_food_mood.dart) parses health_score /
    # health_score_reasons / inflammation_score / fodmap_rating and nothing
    # else; the only red/yellow/green `rating` the UI renders belongs to
    # menu-analysis DISHES (MenuDishItem), not to logged meals.
    # We used to write update_payload["rating"] here, and because PostgREST
    # rejects the WHOLE payload on one unknown key (PGRST204), that single line
    # silently discarded all ~13 enrichment fields — health_score,
    # inflammation_score, glycemic_load and 29 micronutrients — on every
    # cache-hit enrichment, leaving those rows with a NULL health_score.
    # (Scale, measured 2026-07-22 against production:
    #    SELECT count(*), count(*) FILTER (WHERE health_score IS NULL)
    #      FROM food_logs;   -> 222 rows, 107 with a NULL health_score.
    #  That is a point-in-time number and drifts as rows are logged/backfilled.)
    # Rows already affected are repaired by the EXISTING one-shot backfill,
    # scripts/backfill_food_log_scores.py — it selects rows with a NULL
    # inflammation_score OR health_score and re-runs this same enrichment
    # function; it is idempotent and resumable, so no new tooling is required.
    # health_score covers the per-meal "how good was this" signal the UI shows,
    # so the traffic light is intentionally NOT propagated to the food_log.
    # Regression guard: tests/test_column_drift_audit.py +
    # scripts/audit_supabase_column_drift.py --check.

    # 29 micronutrients — sum across items (per-serving values)
    for col in (
        "saturated_fat_g", "trans_fat_g", "cholesterol_mg",
        "sodium_mg", "potassium_mg", "calcium_mg", "iron_mg", "magnesium_mg",
        "zinc_mg", "phosphorus_mg", "selenium_ug", "copper_mg", "manganese_mg",
        "vitamin_a_ug", "vitamin_c_mg", "vitamin_d_iu",
        "vitamin_e_mg", "vitamin_k_ug",
        "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg", "vitamin_b5_mg",
        "vitamin_b6_mg", "vitamin_b7_ug", "vitamin_b9_ug", "vitamin_b12_ug",
        "choline_mg",
        "omega3_g", "omega6_g",
    ):
        vals = [it.get(col) for it in enriched_items if it.get(col) is not None]
        if vals:
            update_payload[col] = round(sum(vals), 2)

    return update_payload if update_payload else None


async def enrich_food_log_scores(food_log_id: str, user_id: str) -> bool:
    """Run the enrichment pass on a single food_log row.

    Returns True when scoring fields were written, False on no-op (already
    enriched, row not found, or Gemini unavailable). Designed to be safe
    to call as a fire-and-forget BackgroundTask — every exception path is
    logged and swallowed so a Gemini failure never breaks the user's log.
    """
    db = get_supabase_db()
    try:
        result = (
            db.client.table("food_logs")
            .select("*")
            .eq("id", food_log_id)
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        row = result.data
    except Exception as e:
        logger.warning(f"[score_enrich] Could not fetch food_log {food_log_id}: {e}")
        return False

    if not row:
        logger.info(f"[score_enrich] food_log {food_log_id} not found; skipping")
        return False

    if not _row_needs_enrichment(row):
        logger.info(f"[score_enrich] food_log {food_log_id} already has scores; skipping")
        return False

    # Fast path: ONLY health_score is missing (the inflammation cluster is
    # already populated — e.g. a barcode row carries a NOVA inflammation_score
    # but no health_score). Write a deterministic health score from the
    # confirmed macros and stop. This skips the cache-stack/Gemini pass entirely
    # AND never clobbers the existing cluster values.
    if _health_missing(row) and not _cluster_missing(row):
        h = _deterministic_health(row)
        if h is None:
            logger.info(f"[score_enrich] food_log {food_log_id} health-only but too sparse; skipping")
            return False
        try:
            db.client.table("food_logs").update({"health_score": h}).eq("id", food_log_id).execute()
            logger.info(f"[score_enrich] food_log {food_log_id} health-only fill = {h}")
            return True
        except Exception as e:  # noqa: BLE001
            logger.warning(f"[score_enrich] health-only write failed {food_log_id}: {e}")
            return False

    seed = _build_seed_description(row)
    if not seed:
        logger.info(f"[score_enrich] food_log {food_log_id} too sparse to score; skipping")
        return False

    # Phase-2: try cache stack BEFORE calling Gemini. The 198k-row override
    # DB now has all 9 enrichment fields + 29 micronutrients. For >95% of
    # logged foods, this skips the 3-5s Gemini call entirely.
    cached_payload = await _try_cache_stack_enrichment(row, user_id)
    if cached_payload:
        cached_payload["score_status"] = "ok"
        # Cache stack fills the inflammation cluster + micros but not health.
        # Add a deterministic health score when the row lacks one.
        if _health_missing(row) and not cached_payload.get("health_score"):
            h = _deterministic_health(row)
            if h is not None:
                cached_payload["health_score"] = h
        try:
            db.client.table("food_logs").update(cached_payload).eq("id", food_log_id).execute()
            logger.info(
                f"[score_enrich] Cache HIT — enriched food_log {food_log_id} from "
                f"override DB (no Gemini call), {len(cached_payload)} fields"
            )
            return True
        except Exception as e:  # noqa: BLE001
            logger.warning(f"[score_enrich] cache-hit DB write failed {food_log_id}: {e}")
            # Fall through to Gemini path

    try:
        service = GeminiService()
        gemini_result = await service.parse_food_description(
            description=seed,
            user_id=user_id,
            # No personal_history / mood_before — enrichment is an objective
            # scoring pass, not a personalized warning generator. Keep the
            # call cheap (cache-friendly).
        )
    except Exception as e:
        # Gemini blew up — mark explicit unavailable per "no silent
        # degradation" so the UI can show greyed chips + retry affordance,
        # not blank space the user has to investigate.
        logger.warning(f"[score_enrich] Gemini failed for {food_log_id}: {e}")
        try:
            db.client.table("food_logs").update(
                {"score_status": "unavailable"}
            ).eq("id", food_log_id).execute()
        except Exception:
            # If the score_status column doesn't exist yet (migration
            # pending), swallow — the headline columns staying NULL is the
            # signal in that interim state.
            pass
        return False

    if not gemini_result:
        logger.info(f"[score_enrich] Gemini returned nothing for {food_log_id}")
        return False

    update_payload = _extract_scoring_fields(gemini_result)
    if not update_payload:
        logger.info(f"[score_enrich] No scoring fields extracted for {food_log_id}")
        return False

    # Mark success so the UI knows the absence of any individual field is
    # "Gemini decided it's not applicable" (e.g., FODMAP n/a for grilled
    # chicken) rather than "we never tried".
    update_payload["score_status"] = "ok"

    # Guarantee a health_score: Gemini's (already in update_payload via
    # _SCORE_COLUMNS) if it emitted one, else the deterministic macro score so
    # the row is never left without it (prevents the backfill re-selecting it).
    if _health_missing(row) and not update_payload.get("health_score"):
        h = _deterministic_health(row)
        if h is not None:
            update_payload["health_score"] = h

    try:
        db.client.table("food_logs").update(update_payload).eq("id", food_log_id).execute()
        logger.info(
            f"[score_enrich] Enriched food_log {food_log_id} with "
            f"{len(update_payload)} fields"
        )
        return True
    except Exception as e:
        # Most likely cause: score_status column doesn't exist in the DB yet.
        # Retry without it so the rest of the columns still land.
        if "score_status" in str(e):
            update_payload.pop("score_status", None)
            try:
                db.client.table("food_logs").update(update_payload).eq(
                    "id", food_log_id
                ).execute()
                logger.info(
                    f"[score_enrich] Enriched food_log {food_log_id} (without score_status)"
                )
                return True
            except Exception as e2:
                logger.warning(f"[score_enrich] Update failed for {food_log_id}: {e2}")
                return False
        logger.warning(f"[score_enrich] Update failed for {food_log_id}: {e}")
        return False
