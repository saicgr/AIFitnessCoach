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
from services.gemini.nutrition import GeminiNutritionService

logger = get_logger(__name__)

# Columns we backfill. Mirrors the FoodAnalysisResponse schema scalars so
# `parse_food_description`'s output maps 1:1. Macros (calories/protein/etc)
# are intentionally excluded — those are the user's confirmed truth and
# must not be touched after they hit "Log This Meal".
_SCORE_COLUMNS = (
    "inflammation_score",
    "is_ultra_processed",
    "inflammation_triggers",
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


def _row_needs_enrichment(row: Dict[str, Any]) -> bool:
    """True when the row is missing the headline scoring fields. We don't
    require ALL columns — just the four signals the Daily/Detail UIs render
    visibly (inflammation chip, NOVA flag, FODMAP rating, glycemic load).
    """
    headline = ("inflammation_score", "is_ultra_processed", "fodmap_rating", "glycemic_load")
    return all(row.get(k) in (None, "", 0) for k in headline)


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

    seed = _build_seed_description(row)
    if not seed:
        logger.info(f"[score_enrich] food_log {food_log_id} too sparse to score; skipping")
        return False

    try:
        service = GeminiNutritionService()
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
