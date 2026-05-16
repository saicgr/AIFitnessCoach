"""Apply per-user food overrides at log time.

The write side lives in `core/db/nutrition_db_helpers.upsert_user_food_override`
(called after `insert_food_log_edits` succeeds). This module handles the read
side: at the start of any log-writing endpoint, replace the AI's detected
cal/P/C/F values with the user's previously-recorded corrections before the
food_log row is persisted.

Scale rule when the stored reference portion differs from the current log:
  - If both the override and the current item have `weight_g`:
        scaled = override × (current.weight_g / override.reference_weight_g)
  - Else if both have `count`:
        scaled = override × (current.count / override.reference_count)
  - Else: apply 1:1 (the user's number is their absolute default).

Totals (parent `food_log.total_calories` etc.) are recomputed from the
replaced items and returned separately so the caller can use them for
`db.create_food_log(...)` without a second aggregation pass.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from core.food_naming import normalize_food_name
from core.logger import get_logger

logger = get_logger(__name__)


# Fields the override replaces. Everything else on the item (ingredients,
# micros, weight_g, count, etc.) is preserved as-is.
_REPLACED_FIELDS = ("calories", "protein_g", "carbs_g", "fat_g")

# C9 — "one-off correction mis-learned as a pattern". A correction is only
# treated as a LEARNED pattern (auto-applied to future logs + surfaced as
# "Zealova remembered your <food>") once the user has made the SAME correction
# at least this many times. `user_food_overrides.edit_count` starts at 1 on the
# first edit and is bumped on every subsequent correction of the same food, so
# a single one-off edit (edit_count == 1) is recorded but NOT yet applied.
LEARNED_PATTERN_MIN_EDITS = 2


def _safe_float(v: Any) -> Optional[float]:
    try:
        return float(v) if v is not None else None
    except (TypeError, ValueError):
        return None


def _lookup_override(
    item: Dict[str, Any],
    table: Dict[str, Dict[str, Any]],
) -> Optional[Dict[str, Any]]:
    """Prefer food_item_id match, fall back to normalized name."""
    fid = item.get("id") or item.get("food_item_id")
    if fid is not None:
        hit = table.get(f"id:{str(fid)}")
        if hit:
            return hit
    name = item.get("name") or ""
    normalized = normalize_food_name(name)
    if normalized:
        return table.get(f"name:{normalized}")
    return None


def _compute_scale(item: Dict[str, Any], override: Dict[str, Any]) -> float:
    """Scale factor from the override's reference portion to the current item.

    Defaults to 1.0 when there's no reference to scale against — the user's
    absolute numbers are applied regardless of portion. Capped at [0.1, 10]
    to avoid absurd outputs from bad data.
    """
    # Prefer weight_g when both sides have it.
    ref_w = _safe_float(override.get("reference_weight_g"))
    cur_w = _safe_float(item.get("weight_g"))
    if ref_w and ref_w > 0 and cur_w and cur_w > 0:
        return max(0.1, min(10.0, cur_w / ref_w))

    ref_c = _safe_float(override.get("reference_count"))
    cur_c = _safe_float(item.get("count"))
    if ref_c and ref_c > 0 and cur_c and cur_c > 0:
        return max(0.1, min(10.0, cur_c / ref_c))

    return 1.0


def apply_user_food_overrides(
    db,
    user_id: str,
    food_items: List[Dict[str, Any]],
    *,
    skip_indices: Optional[set[int]] = None,
) -> Tuple[List[Dict[str, Any]], Dict[str, float], int]:
    """Return (updated_items, totals, num_overridden).

    `totals` is a dict with `total_calories / protein_g / carbs_g / fat_g`
    summed over the returned items — use it to set the parent food_log's
    aggregate fields.

    `skip_indices` is for the `/log-direct` case where the client is about
    to ship `item_edits` for specific indices: those rows are the user's
    just-now edits and must not be double-applied from a stale override.
    """
    skip = skip_indices or set()
    if not food_items:
        return [], {"total_calories": 0, "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0}, 0

    try:
        table = db.fetch_user_food_overrides_for_items(user_id=user_id, food_items=food_items)
    except Exception as e:
        logger.warning(f"Could not fetch user_food_overrides for {user_id}: {e}")
        table = {}

    updated: List[Dict[str, Any]] = []
    overridden = 0
    totals = {"total_calories": 0.0, "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0}

    for idx, item in enumerate(food_items):
        # Always copy so we never mutate the caller's list.
        new_item = dict(item)

        if idx not in skip and table:
            override = _lookup_override(item, table)
            # C9 — only apply once it's a LEARNED pattern (>= 2 consistent
            # corrections). A first one-off edit is stored (edit_count == 1)
            # but must not silently rewrite future estimates.
            if override is not None:
                _edit_count = int(_safe_float(override.get("edit_count")) or 1)
                if _edit_count < LEARNED_PATTERN_MIN_EDITS:
                    override = None
            if override is not None:
                scale = _compute_scale(item, override)
                new_item["calories"] = int(round(_safe_float(override.get("calories")) or 0) * scale)
                new_item["protein_g"] = (_safe_float(override.get("protein_g")) or 0.0) * scale
                new_item["carbs_g"] = (_safe_float(override.get("carbs_g")) or 0.0) * scale
                new_item["fat_g"] = (_safe_float(override.get("fat_g")) or 0.0) * scale
                new_item["user_override_applied"] = True
                # L4 — "accuracy you can trust". This item's AI estimate was
                # cross-checked against and replaced by a verified override
                # row, so the result sheet surfaces a 'verified' badge and
                # suppresses any low-confidence flag for it.
                new_item["verified_source"] = "override_db"
                # L3 — "it remembers you". Surface a small affirmation in the
                # result sheet that Zealova auto-applied the user's learned
                # numbers for this food.
                _disp = override.get("display_name") or item.get("name") or "this food"
                new_item["remembered_label"] = f"Zealova remembered your {_disp}"
                new_item["override_edit_count"] = _edit_count
                if scale != 1.0:
                    new_item["user_override_scale"] = round(scale, 3)
                overridden += 1

        updated.append(new_item)

        totals["total_calories"] += _safe_float(new_item.get("calories")) or 0
        totals["protein_g"] += _safe_float(new_item.get("protein_g")) or 0
        totals["carbs_g"] += _safe_float(new_item.get("carbs_g")) or 0
        totals["fat_g"] += _safe_float(new_item.get("fat_g")) or 0

    totals["total_calories"] = int(round(totals["total_calories"]))
    return updated, totals, overridden


# ─────────────────────────────────────────────────────────────────────────
# L4 follow-up — global verified cross-check for the IMAGE analysis path.
#
# The per-user override path above only catches foods the *current user* has
# personally corrected. The TEXT analysis path additionally gets a free
# verified badge whenever its cache hit came from the canonical
# `food_nutrition_overrides` / `common_foods` tables (`cache_source` check in
# food_logging_stream.py). The IMAGE path has no such cross-check — an
# AI-vision estimate for a clearly-named, well-known food (e.g. "Big Mac")
# is never badged even though that exact food is a verified row in the
# 198k-row `food_nutrition_overrides` table.
#
# This function closes that gap. For each parsed image item it does a
# NORMALIZED-NAME EXACT-MATCH lookup against the verified DB, reusing the
# SAME lookup the text/cache path uses (`FoodDatabaseLookupService.
# _check_override` — exact `food_name_normalized` equality, no fuzzy/
# substring). On a confident match it tags `verified_source='global_db'` and
# prefers the verified macros (community-curated > vision guess for a
# clearly-named food). On NO match the item is left completely untouched —
# the AI's honest `confidence` and macros are preserved.
# ─────────────────────────────────────────────────────────────────────────

# Plan C10 — a name match is not proof it's the same food. Only items the
# vision model named with at least this much signal are eligible: a 2-char
# fragment (" p", "ad") is far too weak to assert an identity match.
_GLOBAL_CROSSCHECK_MIN_NAME_LEN = 4


def _scale_override_to_item(
    item: Dict[str, Any],
    override: Dict[str, Any],
) -> Optional[Dict[str, float]]:
    """Convert a per-100g override row to absolute macros for this item.

    Scaling priority (mirrors `_override_to_analysis*` in cache_service):
      1. The item's own `weight_g` (the vision model's portion estimate) —
         scale per-100g macros by `weight_g / 100`.
      2. The override's default serving / per-piece weight × count.
      3. Plain 100g as a last resort.

    Returns None when the override has no usable calorie data.
    """
    cal_100 = _safe_float(override.get("calories_per_100g"))
    if cal_100 is None:
        return None

    cur_w = _safe_float(item.get("weight_g"))
    default_count = int(_safe_float(override.get("default_count")) or 1) or 1

    if cur_w and cur_w > 0:
        # Trust the vision model's portion; only the per-gram macros come
        # from the verified DB. No `default_count` here — `weight_g` is
        # already the total weight the model saw on the plate.
        scale = cur_w / 100.0
        count = 1
    else:
        serving_g = (
            _safe_float(override.get("override_serving_g"))
            or _safe_float(override.get("override_weight_per_piece_g"))
            or 100.0
        )
        scale = serving_g / 100.0
        count = default_count

    return {
        "calories": round(cal_100 * scale) * count,
        "protein_g": round((_safe_float(override.get("protein_per_100g")) or 0.0) * scale, 1) * count,
        "carbs_g": round((_safe_float(override.get("carbs_per_100g")) or 0.0) * scale, 1) * count,
        "fat_g": round((_safe_float(override.get("fat_per_100g")) or 0.0) * scale, 1) * count,
        "fiber_g": round((_safe_float(override.get("fiber_per_100g")) or 0.0) * scale, 1) * count,
    }


def apply_global_verified_crosscheck(
    food_items: List[Dict[str, Any]],
) -> Tuple[List[Dict[str, Any]], Dict[str, float], int]:
    """Cross-check AI-estimated image items against the verified food DB.

    Returns `(updated_items, totals, num_verified)`.

    For each item, an exact normalized-name lookup is done against
    `food_nutrition_overrides` via `FoodDatabaseLookupService._check_override`
    — the identical exact-match used by the text/cache path. On a confident
    match the verified macros replace the AI estimate and the item is tagged
    `verified_source='global_db'`. Unmatched items pass through unchanged.

    Conservatism rules (plan C10):
      - EXACT normalized-name equality only. `_check_override` does
        `.eq("food_name_normalized", name.lower().strip())` — no fuzzy,
        trigram or substring matching. Homemade "chicken curry" will NOT
        inherit a packaged "chicken curry" product's macros unless the
        normalized names are byte-equal.
      - Names shorter than 4 chars are skipped — too weak to assert identity.
      - An item already verified (per-user override → `verified_source` set)
        is never downgraded or re-tagged.
      - Any lookup error → that item is left untouched (no silent fallback to
        a degraded value; the AI estimate simply stands).
    """
    if not food_items:
        return [], {"total_calories": 0, "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0}, 0

    # Reuse the text/cache path's exact-match lookup service. Imported lazily
    # to avoid a heavy import at module load and a possible import cycle.
    try:
        from services.food_database_lookup_service import get_food_db_lookup_service

        lookup_service = get_food_db_lookup_service()
    except Exception as e:  # pragma: no cover - defensive
        logger.warning(f"[global-crosscheck] lookup service unavailable: {e}")
        lookup_service = None

    updated: List[Dict[str, Any]] = []
    verified = 0
    totals = {"total_calories": 0.0, "protein_g": 0.0, "carbs_g": 0.0, "fat_g": 0.0}

    for item in food_items:
        new_item = dict(item)

        # Skip items the per-user override path already verified — don't
        # downgrade 'override_db' (a personal correction) to 'global_db'.
        already_verified = bool(new_item.get("verified_source"))

        if lookup_service is not None and not already_verified:
            name = (new_item.get("name") or "").strip()
            normalized = name.lower().strip()
            if len(normalized) >= _GLOBAL_CROSSCHECK_MIN_NAME_LEN:
                try:
                    # Exact normalized-name match against food_nutrition_overrides.
                    override = lookup_service._check_override(name)
                except Exception as e:
                    logger.debug(f"[global-crosscheck] lookup failed for '{name}': {e}")
                    override = None

                if override is not None:
                    scaled = _scale_override_to_item(new_item, override)
                    if scaled is not None and scaled["calories"] > 0:
                        new_item["calories"] = int(round(scaled["calories"]))
                        new_item["protein_g"] = scaled["protein_g"]
                        new_item["carbs_g"] = scaled["carbs_g"]
                        new_item["fat_g"] = scaled["fat_g"]
                        if scaled["fiber_g"]:
                            new_item["fiber_g"] = scaled["fiber_g"]
                        # L4 — verified against the global community DB. The
                        # frontend renders the same verified badge it shows
                        # for 'override_db'.
                        new_item["verified_source"] = "global_db"
                        # The matched canonical name is more reliable than a
                        # vision label; surface it so the badge reads cleanly.
                        new_item["verified_match_name"] = override.get("display_name")
                        verified += 1

        updated.append(new_item)
        totals["total_calories"] += _safe_float(new_item.get("calories")) or 0
        totals["protein_g"] += _safe_float(new_item.get("protein_g")) or 0
        totals["carbs_g"] += _safe_float(new_item.get("carbs_g")) or 0
        totals["fat_g"] += _safe_float(new_item.get("fat_g")) or 0

    totals["total_calories"] = int(round(totals["total_calories"]))
    return updated, totals, verified
