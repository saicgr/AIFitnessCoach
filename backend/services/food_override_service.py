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
            if override is not None:
                scale = _compute_scale(item, override)
                new_item["calories"] = int(round(_safe_float(override.get("calories")) or 0) * scale)
                new_item["protein_g"] = (_safe_float(override.get("protein_g")) or 0.0) * scale
                new_item["carbs_g"] = (_safe_float(override.get("carbs_g")) or 0.0) * scale
                new_item["fat_g"] = (_safe_float(override.get("fat_g")) or 0.0) * scale
                new_item["user_override_applied"] = True
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
