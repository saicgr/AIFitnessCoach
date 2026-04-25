"""Micronutrient tracking, RDA, and pinned nutrients endpoints."""
import asyncio
from core.db import get_supabase_db
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from core.timezone_utils import resolve_timezone, local_date_to_utc_range, get_user_today
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger

from models.recipe import (
    NutrientProgress,
    NutrientRDA,
    DailyMicronutrientSummary,
    NutrientContributorsResponse,
    NutrientContributor,
)
from api.v1.nutrition.models import PinnedNutrientsUpdate

router = APIRouter()
logger = get_logger(__name__)

# ============================================
# Micronutrient Endpoints
# ============================================


@router.get("/micronutrients/{user_id}", response_model=DailyMicronutrientSummary)
async def get_daily_micronutrients(
    request: Request,
    user_id: str,
    date: Optional[str] = Query(default=None, description="Date (YYYY-MM-DD), defaults to today"),
    current_user: dict = Depends(get_current_user),
):
    """
    Get daily micronutrient summary with progress towards RDA goals.

    Returns vitamins, minerals, fatty acids, and other nutrients with
    floor/target/ceiling values and current intake.
    """
    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        if date is None:
            date = get_user_today(user_tz)

        logger.info(f"Getting daily micronutrients for user {user_id}, date={date}")

        # Run all 3 DB queries in parallel (sync calls offloaded to thread pool)
        loop = asyncio.get_event_loop()

        def _fetch_rdas():
            return db.client.table("nutrient_rdas")\
                .select("*")\
                .order("display_order")\
                .execute()

        def _fetch_user():
            return db.get_user(user_id)

        def _fetch_logs():
            start_of_day, end_of_day = local_date_to_utc_range(date, user_tz)
            result = db.client.table("food_logs").select("*") \
                .eq("user_id", user_id) \
                .is_("deleted_at", "null") \
                .gte("logged_at", start_of_day) \
                .lte("logged_at", end_of_day) \
                .order("logged_at", desc=True) \
                .limit(50) \
                .execute()
            return result.data or []

        rda_result, user, logs = await asyncio.gather(
            loop.run_in_executor(None, _fetch_rdas),
            loop.run_in_executor(None, _fetch_user),
            loop.run_in_executor(None, _fetch_logs),
        )

        rdas = {r["nutrient_key"]: r for r in (rda_result.data or [])}
        # Default static list if the user never customized: matches the
        # historical hard-coded fallback so the legacy UX is preserved for
        # users who opt out of dynamic pinning.
        DEFAULT_STATIC_PINS = ["vitamin_d", "calcium", "iron", "omega3"]
        static_pinned_keys = (
            (user.get("pinned_nutrients") if user else None) or DEFAULT_STATIC_PINS
        )
        # New `pinned_nutrients_mode` column (added in migration 1982).
        # 'static' = legacy / explicitly opted out. 'dynamic' = compute the
        # pinned set from today's logs. Default 'static' for safety; new
        # accounts get 'dynamic' set by onboarding.
        pinning_mode = (user.get("pinned_nutrients_mode") if user else None) or "static"

        # Aggregate micronutrients from all logs
        totals = {}
        for log in logs:
            for key in rdas.keys():
                col_name = key  # e.g., 'vitamin_d_iu'
                value = log.get(col_name) or 0
                totals[key] = totals.get(key, 0) + float(value)

        # Macro-like keys are surfaced separately on the Daily header — exclude
        # from the pinned card so we don't double-show them.
        MACRO_EXCLUDE = {
            "calories", "protein_g", "carbs_g", "fat_g", "fiber_g",
            "calorie", "kcal",
        }

        # Build progress for each category
        def make_progress(key: str, rda: dict) -> NutrientProgress:
            current = totals.get(key, 0)
            target = rda.get("rda_target") or 1
            floor_val = rda.get("rda_floor")
            ceiling = rda.get("rda_ceiling")
            percentage = round((current / target) * 100, 1) if target > 0 else 0

            if ceiling and current > ceiling:
                status = "over_ceiling"
            elif current >= target:
                status = "optimal"
            elif floor_val and current >= floor_val:
                status = "adequate"
            else:
                status = "low"

            return NutrientProgress(
                nutrient_key=key,
                display_name=rda.get("display_name", key),
                unit=rda.get("unit", ""),
                category=rda.get("category", "other"),
                current_value=round(current, 2),
                target_value=target,
                floor_value=floor_val,
                ceiling_value=ceiling,
                percentage=percentage,
                status=status,
                color_hex=rda.get("color_hex"),
            )

        # Treat several key roots equivalently when matching against the
        # user's saved pinned list (the legacy list stores logical names like
        # 'vitamin_d', the columns are 'vitamin_d_iu' — so we strip the
        # trailing unit suffix to compare).
        def _strip_unit_suffix(k: str) -> str:
            for suf in ("_ug", "_mg", "_iu", "_g"):
                if k.endswith(suf):
                    return k[: -len(suf)]
            return k

        vitamins = []
        minerals = []
        fatty_acids = []
        other = []
        all_progress: list[NutrientProgress] = []

        for key, rda in rdas.items():
            progress = make_progress(key, rda)
            all_progress.append(progress)

            if rda["category"] == "vitamin":
                vitamins.append(progress)
            elif rda["category"] == "mineral":
                minerals.append(progress)
            elif rda["category"] == "fatty_acid":
                fatty_acids.append(progress)
            else:
                other.append(progress)

        # ----- Pinned selection ---------------------------------------------
        pinned: list[NutrientProgress] = []

        def _static_pinned() -> list[NutrientProgress]:
            picked: list[NutrientProgress] = []
            for p in all_progress:
                if (
                    p.nutrient_key in static_pinned_keys
                    or _strip_unit_suffix(p.nutrient_key) in static_pinned_keys
                ):
                    p2 = p.model_copy(update={"pin_reason": "static"})
                    picked.append(p2)
            return picked

        if pinning_mode == "dynamic" and logs:
            # Score each non-macro nutrient with a positive RDA target by
            # `current / target`. Penalty nutrients (sodium, saturated fat,
            # added sugar, cholesterol) — flagged via the new
            # `nutrient_rdas.penalty` column added in migration 1982 — stay
            # in the candidate set even when over_ceiling because that's the
            # most actionable signal ("you're at 140% sodium today").
            candidates = []
            for p in all_progress:
                if p.nutrient_key in MACRO_EXCLUDE:
                    continue
                if p.target_value <= 0:
                    continue
                # Skip nutrients with literally zero contribution from today's
                # logs unless they're penalty items pushing past the ceiling
                # (rare — would imply prior-day spillover, but harmless).
                if p.current_value <= 0 and p.status != "over_ceiling":
                    continue
                rda = rdas.get(p.nutrient_key, {})
                is_penalty = bool(rda.get("penalty"))
                score = p.current_value / p.target_value
                # Boost penalty nutrients that exceeded the ceiling so they
                # win against mere "70% of vitamin C" entries.
                if is_penalty and p.status == "over_ceiling":
                    score = max(score, 1.5)
                pin_reason = (
                    "over_ceiling"
                    if (is_penalty and p.status == "over_ceiling")
                    else "top_contributor"
                )
                candidates.append((score, p.current_value, p, pin_reason))

            # Sort by score desc, tiebreak on absolute amount desc, then
            # category-cap to avoid showing 4 vitamins.
            candidates.sort(key=lambda x: (x[0], x[1]), reverse=True)
            CATEGORY_CAP = 2
            cat_count: dict[str, int] = {}
            for score, _amt, p, pin_reason in candidates:
                cat = p.category or "other"
                if cat_count.get(cat, 0) >= CATEGORY_CAP:
                    continue
                pinned.append(p.model_copy(update={"pin_reason": pin_reason}))
                cat_count[cat] = cat_count.get(cat, 0) + 1
                if len(pinned) >= 4:
                    break

            # Fallback: if we got fewer than 2 dynamic picks, union with
            # static so the card never looks empty. Dedup by nutrient_key.
            if len(pinned) < 2:
                seen = {p.nutrient_key for p in pinned}
                for p in _static_pinned():
                    if p.nutrient_key not in seen:
                        pinned.append(p)
                        if len(pinned) >= 4:
                            break
        else:
            # Static mode OR no logs yet → fall back to user's saved list.
            pinned = _static_pinned()

        return DailyMicronutrientSummary(
            date=date,
            user_id=user_id,
            vitamins=vitamins,
            minerals=minerals,
            fatty_acids=fatty_acids,
            other=other,
            pinned=pinned[:8],  # Hard cap; dynamic mode self-limits to 4.
            pinning_mode=pinning_mode,
        )

    except Exception as e:
        logger.error(f"Failed to get daily micronutrients: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/micronutrients/{user_id}/contributors/{nutrient}", response_model=NutrientContributorsResponse)
async def get_nutrient_contributors(
    request: Request,
    user_id: str,
    nutrient: str,
    date: Optional[str] = Query(default=None, description="Date (YYYY-MM-DD), defaults to today"),
    limit: int = Query(default=10, le=20),
    current_user: dict = Depends(get_current_user),
):
    """
    Get top food contributors for a specific nutrient.

    Shows which foods contributed the most to the day's intake.
    """
    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)

        if date is None:
            date = get_user_today(user_tz)

        logger.info(f"Getting contributors for {nutrient} for user {user_id}, date={date}")

        # Get RDA info
        rda_result = db.client.table("nutrient_rdas")\
            .select("*")\
            .eq("nutrient_key", nutrient)\
            .single()\
            .execute()

        if not rda_result.data:
            raise HTTPException(status_code=404, detail=f"Unknown nutrient: {nutrient}")

        rda = rda_result.data

        # Get all food logs for the day with this nutrient
        start_of_day, end_of_day = local_date_to_utc_range(date, user_tz)
        log_result = db.client.table("food_logs").select("*") \
            .eq("user_id", user_id) \
            .is_("deleted_at", "null") \
            .gte("logged_at", start_of_day) \
            .lte("logged_at", end_of_day) \
            .order("logged_at", desc=True) \
            .limit(50) \
            .execute()
        logs = log_result.data or []

        # Extract contributors
        contributors = []
        total_intake = 0

        for log in logs:
            value = log.get(nutrient) or 0
            if value > 0:
                total_intake += float(value)

                # Get food names from food_items
                food_items = log.get("food_items", [])
                food_name = ", ".join([f.get("name", "Unknown") for f in food_items[:3]])
                if len(food_items) > 3:
                    food_name += f" (+{len(food_items) - 3} more)"

                contributors.append(NutrientContributor(
                    food_log_id=log["id"],
                    food_name=food_name or log.get("meal_type", "Meal"),
                    meal_type=log.get("meal_type", ""),
                    amount=float(value),
                    unit=rda.get("unit", ""),
                    logged_at=datetime.fromisoformat(str(log.get("logged_at", "")).replace("Z", "+00:00")) if log.get("logged_at") else datetime.now(),
                ))

        # Sort by amount descending
        contributors.sort(key=lambda x: x.amount, reverse=True)

        return NutrientContributorsResponse(
            nutrient_key=nutrient,
            display_name=rda.get("display_name", nutrient),
            unit=rda.get("unit", ""),
            total_intake=round(total_intake, 2),
            target=rda.get("rda_target", 0),
            contributors=contributors[:limit],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get nutrient contributors: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.get("/rdas", response_model=List[NutrientRDA])
async def get_all_rdas(current_user: dict = Depends(get_current_user)):
    """
    Get all RDA (Reference Daily Allowance) values for micronutrients.

    Returns floor/target/ceiling values for all tracked nutrients.
    """
    logger.info("Getting all RDAs")

    try:
        db = get_supabase_db()

        result = db.client.table("nutrient_rdas")\
            .select("*")\
            .order("display_order")\
            .execute()

        return [
            NutrientRDA(
                nutrient_name=r["nutrient_name"],
                nutrient_key=r["nutrient_key"],
                unit=r["unit"],
                category=r["category"],
                rda_floor=r.get("rda_floor"),
                rda_target=r.get("rda_target"),
                rda_ceiling=r.get("rda_ceiling"),
                rda_target_male=r.get("rda_target_male"),
                rda_target_female=r.get("rda_target_female"),
                display_name=r["display_name"],
                display_order=r.get("display_order", 0),
                color_hex=r.get("color_hex"),
            )
            for r in (result.data or [])
        ]

    except Exception as e:
        logger.error(f"Failed to get RDAs: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.put("/pinned-nutrients/{user_id}")
async def update_pinned_nutrients(user_id: str, request: PinnedNutrientsUpdate, current_user: dict = Depends(get_current_user)):
    """
    Update user's pinned micronutrients for the dashboard.

    Maximum 8 nutrients can be pinned.
    """
    logger.info(f"Updating pinned nutrients for user {user_id}")

    if len(request.pinned_nutrients) > 8:
        raise HTTPException(status_code=400, detail="Maximum 8 nutrients can be pinned")

    try:
        db = get_supabase_db()

        result = db.client.table("users")\
            .update({"pinned_nutrients": request.pinned_nutrients})\
            .eq("id", user_id)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        return {"status": "updated", "pinned_nutrients": request.pinned_nutrients}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update pinned nutrients: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")
