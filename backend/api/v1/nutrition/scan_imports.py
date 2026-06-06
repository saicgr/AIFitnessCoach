"""Direct (non-chat) label-scan & app-screenshot-scan endpoints — Parity A2.

Surfaces the OCR capabilities that previously lived only inside the AI-Coach
chat (`langgraph_agents/tools/nutrition_tools.py` parse_app_screenshot /
parse_nutrition_label) as first-class HTTP endpoints the Flutter food-log
sheet can call directly.

These endpoints are **analyze-only**: they OCR the image, apply the user's
per-food cal/P/C/F overrides, and return a `LogFoodResponse`-shaped payload so
the existing food-log result sheet can review/edit before the user commits the
log via the normal `/nutrition/log-direct` path.

Edge cases handled (plan Part C, table C4):
  - Label serving size ≠ amount eaten → `servings_consumed` query param +
    `scan_meta.servings_per_container` so the client can prompt "how many?".
  - Foreign units (kJ, per-100g) → Gemini converts; surfaced via
    `scan_meta.unit_notes`.
  - Glare / partially cut-off label → `scan_meta.unreadable_fields`.
  - Multi-serving package → `scan_meta.servings_per_container` + a warning
    when the user has not confirmed a portion.
  - Screenshot that is actually a recipe / non-nutrition page →
    `scan_meta.content_kind` ("recipe" | "not_nutrition") so the client can
    route to recipe/text analysis instead of fabricating a log.
  - Screenshot with multiple foods → every food row is returned as its own
    item (Gemini is instructed never to collapse them).
"""
import asyncio
import base64
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.nutrition_bias import apply_calorie_bias, get_user_calorie_bias
from core.rate_limiter import limiter
from services.vision_service import get_vision_service

logger = get_logger(__name__)

router = APIRouter()

# Shared with /log-image — keep in sync.
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic"}
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB


async def _read_and_validate_image(image: UploadFile) -> tuple[str, str]:
    """Validate an uploaded image and return (base64_data, mime_type).

    Raises HTTPException on an unsupported type or oversize file.
    """
    if image.content_type and image.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid image type. Allowed: {', '.join(sorted(ALLOWED_IMAGE_TYPES))}",
        )
    image_bytes = await image.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Empty image upload")
    if len(image_bytes) > MAX_IMAGE_SIZE:
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")
    return (
        base64.b64encode(image_bytes).decode("utf-8"),
        image.content_type or "image/jpeg",
    )


def _build_response(
    analysis: dict,
    *,
    source_type: str,
    scan_meta: dict,
) -> dict:
    """Shape a vision-OCR analysis dict into the `LogFoodResponse` JSON the
    Flutter food-log result sheet (`LogFoodResponse.fromJson`) consumes.

    The endpoint is analyze-only, so `food_log_id` is intentionally null —
    the client logs via `/nutrition/log-direct` after the user reviews.
    """
    food_items = analysis.get("food_items", []) or []
    total_calories = analysis.get("total_calories", 0) or 0
    protein_g = (
        analysis.get("total_protein_g")
        or analysis.get("protein_g")
        or 0.0
    )
    carbs_g = analysis.get("total_carbs_g") or analysis.get("carbs_g") or 0.0
    fat_g = analysis.get("total_fat_g") or analysis.get("fat_g") or 0.0
    fiber_g = analysis.get("total_fiber_g") or analysis.get("fiber_g") or 0.0

    # C4: surface unreadable fields / unit conversions / low confidence as
    # plain warnings the result sheet already renders, in addition to the
    # structured `scan_meta` block the dedicated UI consumes.
    warnings: list[str] = []
    unreadable = analysis.get("unreadable_fields") or []
    if unreadable:
        warnings.append(
            "Some fields were glared or cut off ("
            + ", ".join(str(u) for u in unreadable)
            + ") — double-check those values or re-shoot."
        )
    unit_notes = analysis.get("unit_notes") or []
    if "kj_converted" in unit_notes:
        warnings.append("Energy was in kilojoules — converted to kcal.")
    if "per_100g_normalized" in unit_notes:
        warnings.append("Label was per-100g — normalized to the serving size.")
    spc = analysis.get("servings_per_container")
    if scan_meta.get("kind") == "label" and spc and spc > 1:
        warnings.append(
            f"This package has {spc} servings — confirm how many you actually ate."
        )

    # F5 — surface meal-level micronutrients so the client can forward them to
    # /log-direct (the label OCR already estimates the full RDA-tracked set via
    # the FoodAnalysisResponse schema; previously they were dropped here, so a
    # label scan logged 0/28 micros). Additive — None values are simply absent.
    _MICRO_PASSTHROUGH = [
        'sodium_mg', 'sugar_g', 'added_sugar_g', 'saturated_fat_g', 'cholesterol_mg',
        'potassium_mg', 'vitamin_a_ug', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg',
        'vitamin_k_ug', 'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b6_mg',
        'vitamin_b9_ug', 'vitamin_b12_ug', 'choline_mg', 'calcium_mg', 'iron_mg',
        'magnesium_mg', 'zinc_mg', 'selenium_ug', 'phosphorus_mg', 'copper_mg',
        'manganese_mg', 'iodine_ug', 'omega3_g', 'omega6_g', 'caffeine_mg',
    ]
    micros = {}
    for _k in _MICRO_PASSTHROUGH:
        _v = analysis.get(_k)
        if _v is not None:
            micros[_k] = _v

    return {
        "success": True,
        "food_log_id": None,  # analyze-only — not saved yet
        "food_items": food_items,
        "total_calories": total_calories,
        "protein_g": protein_g,
        "carbs_g": carbs_g,
        "fat_g": fat_g,
        "fiber_g": fiber_g,
        **micros,
        "health_score": analysis.get("health_score"),
        "health_score_reasons": analysis.get("health_score_reasons"),
        "ai_suggestion": analysis.get("feedback") or None,
        "warnings": warnings or None,
        "confidence_level": "low" if analysis.get("low_confidence") else "medium",
        "source_type": source_type,
        # Structured edge-case metadata for the dedicated scan UI.
        "scan_meta": scan_meta,
    }


@router.post("/scan-label")
@limiter.limit("10/minute")
async def scan_nutrition_label(
    request: Request,
    user_id: str = Form(...),
    image: Optional[UploadFile] = File(None),
    images: Optional[List[UploadFile]] = File(None),
    servings_consumed: float = Form(1.0),
    caption: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """Scan a physical nutrition-facts label (analyze-only).

    Reuses `VisionService.analyze_nutrition_label` — the same Gemini-OCR logic
    the chat tool `parse_nutrition_label` calls — so there is no duplicated
    prompt/parse code.

    C4 handling:
      - `servings_consumed` lets the client ask "how many servings?" when the
        label serving size differs from the amount eaten.
      - `scan_meta.servings_per_container` / `unreadable_fields` / `unit_notes`
        let the client confirm portion, flag glare, and note kJ/per-100g.

    Gap 4 — multi-photo stitching: accepts either a single `image` (back-compat)
    or multiple `images` (pieces of the same label, e.g. wrapped around a
    bottle). When the panel is still cut off, `scan_meta.needs_more_photos` is
    true so the client can prompt for another photo and re-scan the full set.
    """
    verify_user_ownership(current_user, user_id)

    if servings_consumed <= 0:
        raise HTTPException(status_code=400, detail="servings_consumed must be > 0")
    # Sanity-clamp absurd portions (C4 multi-serving safety).
    servings_consumed = min(servings_consumed, 50.0)

    # Collect every uploaded photo (single `image` and/or multi `images`).
    uploads = [u for u in ([image] if image else []) + (images or []) if u]
    if not uploads:
        raise HTTPException(status_code=400, detail="No image uploaded")
    if len(uploads) > 5:
        uploads = uploads[:5]  # bound the stitch set
    images_base64: list[str] = []
    mime_type = "image/jpeg"
    for up in uploads:
        b64, mt = await _read_and_validate_image(up)
        images_base64.append(b64)
        mime_type = mt

    try:
        vision_service = get_vision_service()
        analysis = await asyncio.wait_for(
            vision_service.analyze_nutrition_label(
                images_base64=images_base64,
                mime_type=mime_type,
                servings_consumed=servings_consumed,
                user_context=caption,
            ),
            timeout=60,
        )
        if not analysis or not analysis.get("food_items"):
            raise HTTPException(
                status_code=422,
                detail="Could not read the nutrition label. Try a clearer, "
                "well-lit photo of the full panel.",
            )

        # Apply the user's calorie-estimate bias, then their per-food overrides
        # — identical post-processing to /log-image and the chat tool.
        bias = await get_user_calorie_bias(user_id)
        if bias != 0:
            analysis = apply_calorie_bias(analysis, bias)

        db = get_supabase_db()
        from services.food_override_service import apply_user_food_overrides

        food_items, override_totals, num_overridden = await asyncio.to_thread(
            apply_user_food_overrides,
            db, user_id, analysis.get("food_items", []) or [],
        )
        analysis["food_items"] = food_items
        if num_overridden:
            logger.info(
                f"[scan-label] Applied {num_overridden} food override(s) for {user_id}"
            )
            analysis["total_calories"] = override_totals["total_calories"]
            analysis["total_protein_g"] = override_totals["protein_g"]
            analysis["total_carbs_g"] = override_totals["carbs_g"]
            analysis["total_fat_g"] = override_totals["fat_g"]

        # B3 — auto-capture this scanned product into the per-user low-trust lane
        # (food_overrides_user_contributed). With the prompt nudge, product_name
        # carries the packaging size ("Almond Joy King Size"), so the next time
        # THIS user types it the right variant (real net weight) resolves
        # immediately; everyone else only sees it after the cross-user promotion
        # job (scripts/promote_user_contributed.py) corroborates it — a single
        # mis-OCR'd label can never poison the global verified DB. Opt-out and
        # idempotency are enforced inside _upsert_user_contributed.
        try:
            _pname = (analysis.get("product_name") or "").strip()
            _items = analysis.get("food_items") or []
            if _pname and _pname.lower() != "unknown" and _items:
                _norm = " ".join(_pname.lower().split())
                if _norm and len(_norm) >= 4:
                    from services.food_analysis.cache_service_helpers import (
                        get_food_analysis_cache_service,
                    )
                    await get_food_analysis_cache_service()._upsert_user_contributed(
                        user_id=user_id,
                        food_name_normalized=_norm,
                        display_name=_pname,
                        analysis_item=_items[0],
                    )
        except Exception as _cap_err:
            logger.debug(f"[scan-label] variant auto-capture skipped: {_cap_err}")

        scan_meta = {
            "kind": "label",
            "product_name": analysis.get("product_name"),
            "brand": analysis.get("brand"),
            "serving_size": analysis.get("serving_size"),
            "servings_per_container": analysis.get("servings_per_container"),
            "servings_consumed": servings_consumed,
            "per_serving_calories": analysis.get("per_serving_calories"),
            "unreadable_fields": analysis.get("unreadable_fields") or [],
            "unit_notes": analysis.get("unit_notes") or [],
            "low_confidence": bool(analysis.get("low_confidence")),
            # Gap 4 — the core panel is still cut off; the client can add
            # another photo and re-scan the accumulated set.
            "needs_more_photos": not bool(analysis.get("label_complete", True)),
            "photos_used": len(images_base64),
        }
        return _build_response(analysis, source_type="label_scan", scan_meta=scan_meta)

    except HTTPException:
        raise
    except asyncio.TimeoutError:
        logger.warning(f"[scan-label] OCR timed out for user {user_id}")
        raise HTTPException(status_code=504, detail="Label scan timed out — please retry")
    except Exception as e:
        logger.error(f"[scan-label] failed for user {user_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "nutrition")


@router.post("/scan-app-screenshot")
@limiter.limit("10/minute")
async def scan_app_screenshot(
    request: Request,
    user_id: str = Form(...),
    image: UploadFile = File(...),
    caption: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """Scan a screenshot from another nutrition app (analyze-only).

    Reuses `VisionService.analyze_app_screenshot` — the same Gemini-OCR logic
    the chat tool `parse_app_screenshot` calls.

    C4 handling:
      - `scan_meta.content_kind` flags screenshots that are actually a recipe
        or a non-nutrition page so the client routes to recipe/text analysis
        rather than logging garbage.
      - Multiple foods in one screenshot are each returned as their own item.
    """
    verify_user_ownership(current_user, user_id)

    image_base64, mime_type = await _read_and_validate_image(image)

    try:
        vision_service = get_vision_service()
        analysis = await asyncio.wait_for(
            vision_service.analyze_app_screenshot(
                image_base64=image_base64,
                mime_type=mime_type,
                user_context=caption,
            ),
            timeout=60,
        )
        if not analysis:
            raise HTTPException(
                status_code=422,
                detail="Could not read the screenshot. Try a clearer image.",
            )

        content_kind = analysis.get("content_kind", "nutrition_panel")
        # C4: a recipe / non-nutrition screenshot must NOT be logged — tell the
        # client to route it elsewhere. 422 with a structured detail so the
        # Flutter side can branch instead of showing a raw error.
        if content_kind in ("recipe", "not_nutrition"):
            raise HTTPException(
                status_code=422,
                detail={
                    "reason": content_kind,
                    "message": (
                        "This looks like a recipe, not a nutrition panel — "
                        "try the recipe importer instead."
                        if content_kind == "recipe"
                        else "No nutrition data found in this screenshot."
                    ),
                },
            )

        if not analysis.get("food_items"):
            raise HTTPException(
                status_code=422,
                detail="Could not extract any food entries from the screenshot.",
            )

        bias = await get_user_calorie_bias(user_id)
        if bias != 0:
            analysis = apply_calorie_bias(analysis, bias)

        db = get_supabase_db()
        from services.food_override_service import apply_user_food_overrides

        food_items, override_totals, num_overridden = await asyncio.to_thread(
            apply_user_food_overrides,
            db, user_id, analysis.get("food_items", []) or [],
        )
        analysis["food_items"] = food_items
        if num_overridden:
            logger.info(
                f"[scan-app-screenshot] Applied {num_overridden} food override(s) "
                f"for {user_id}"
            )
            analysis["total_calories"] = override_totals["total_calories"]
            analysis["total_protein_g"] = override_totals["protein_g"]
            analysis["total_carbs_g"] = override_totals["carbs_g"]
            analysis["total_fat_g"] = override_totals["fat_g"]

        scan_meta = {
            "kind": "screenshot",
            "content_kind": content_kind,
            "source_app": analysis.get("source_app", "unknown"),
            "unreadable_fields": analysis.get("unreadable_fields") or [],
            "unit_notes": analysis.get("unit_notes") or [],
            "low_confidence": bool(analysis.get("low_confidence")),
        }
        return _build_response(
            analysis, source_type="screenshot_scan", scan_meta=scan_meta
        )

    except HTTPException:
        raise
    except asyncio.TimeoutError:
        logger.warning(f"[scan-app-screenshot] OCR timed out for user {user_id}")
        raise HTTPException(
            status_code=504, detail="Screenshot scan timed out — please retry"
        )
    except Exception as e:
        logger.error(
            f"[scan-app-screenshot] failed for user {user_id}: {e}", exc_info=True
        )
        raise safe_internal_error(e, "nutrition")
