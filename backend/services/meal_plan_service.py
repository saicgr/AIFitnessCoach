"""
Meal Plan Service
=================
- create / read / update / delete meal plans + items
- simulate(plan_id) → totals + remainder vs. user targets + AI swap suggestions (no writes)
- apply(plan_id, target_date) → batch-creates food_logs for that date with duplicate detection

Per feedback_no_silent_fallbacks: when something can't be computed (missing target,
unknown recipe), we surface the gap rather than substituting zeros.
"""

import json
import logging
import uuid
from datetime import date, datetime
from typing import Any, Dict, List, Optional, Tuple

from core.db import get_supabase_db
from models.meal_plan import (
    AiSwapSuggestion,
    ApplyResponse,
    MacroRemainder,
    MacroTotals,
    MealPlan,
    MealPlanCreate,
    MealPlanItem,
    MealPlanItemCreate,
    MealPlanUpdate,
    SimulateResponse,
)
from services.gemini_text_helper import gemini_text

logger = logging.getLogger(__name__)


class MealPlanService:
    """Persistence + simulation + apply for daily meal plans."""

    def __init__(self):
        self.db = get_supabase_db()

    # ------------------------------------------------------------------
    # CRUD
    # ------------------------------------------------------------------

    async def create(self, user_id: str, req: MealPlanCreate) -> MealPlan:
        target_snapshot = await self._fetch_user_targets(user_id)

        plan_id = str(uuid.uuid4())
        now_iso = datetime.utcnow().isoformat()
        plan_row = {
            "id": plan_id,
            "user_id": user_id,
            "name": req.name,
            "plan_date": req.plan_date.isoformat() if req.plan_date else None,
            "is_template": req.is_template,
            "target_snapshot": target_snapshot,
            "notes": req.notes,
            "created_at": now_iso,
            "updated_at": now_iso,
        }
        self.db.client.table("meal_plans").insert(plan_row).execute()

        items_out: List[MealPlanItem] = []
        if req.items:
            item_rows = []
            for itm in req.items:
                item_id = str(uuid.uuid4())
                item_rows.append(self._item_create_to_row(item_id, plan_id, itm, now_iso))
                items_out.append(
                    MealPlanItem(
                        id=item_id,
                        plan_id=plan_id,
                        created_at=datetime.fromisoformat(now_iso),
                        **itm.model_dump(),
                    )
                )
            if item_rows:
                self.db.client.table("meal_plan_items").insert(item_rows).execute()

        return MealPlan(
            id=plan_id,
            user_id=user_id,
            name=req.name,
            plan_date=req.plan_date,
            is_template=req.is_template,
            target_snapshot=target_snapshot,
            notes=req.notes,
            items=items_out,
            created_at=datetime.fromisoformat(now_iso),
            updated_at=datetime.fromisoformat(now_iso),
        )

    async def get(self, plan_id: str) -> Optional[MealPlan]:
        plan_res = (
            self.db.client.table("meal_plans").select("*").eq("id", plan_id).limit(1).execute()
        )
        if not plan_res.data:
            return None
        plan_row = plan_res.data[0]
        items_res = (
            self.db.client.table("meal_plan_items")
            .select("*")
            .eq("plan_id", plan_id)
            .order("meal_type")
            .order("slot_order")
            .execute()
        )
        items = [self._row_to_item(r) for r in (items_res.data or [])]
        return self._row_to_plan(plan_row, items)

    async def update(self, plan_id: str, req: MealPlanUpdate) -> Optional[MealPlan]:
        patch = {k: v for k, v in req.model_dump(exclude_none=True).items()}
        if not patch:
            return await self.get(plan_id)
        if "plan_date" in patch and patch["plan_date"]:
            patch["plan_date"] = patch["plan_date"].isoformat()
        patch["updated_at"] = datetime.utcnow().isoformat()
        self.db.client.table("meal_plans").update(patch).eq("id", plan_id).execute()
        return await self.get(plan_id)

    async def delete(self, plan_id: str) -> bool:
        self.db.client.table("meal_plans").delete().eq("id", plan_id).execute()
        return True

    async def add_item(self, plan_id: str, item: MealPlanItemCreate) -> MealPlanItem:
        item_id = str(uuid.uuid4())
        now_iso = datetime.utcnow().isoformat()
        row = self._item_create_to_row(item_id, plan_id, item, now_iso)
        self.db.client.table("meal_plan_items").insert(row).execute()
        return MealPlanItem(
            id=item_id, plan_id=plan_id, created_at=datetime.fromisoformat(now_iso),
            **item.model_dump(),
        )

    async def remove_item(self, item_id: str) -> bool:
        self.db.client.table("meal_plan_items").delete().eq("id", item_id).execute()
        return True

    async def list_for_user(
        self, user_id: str, plan_date: Optional[date] = None, templates_only: bool = False
    ) -> List[MealPlan]:
        # Single round trip via PostgREST embed; previously this was an N+1
        # (one query per plan to fetch items). See plan A1.
        q = (
            self.db.client.table("meal_plans")
            .select("*, meal_plan_items(*)")
            .eq("user_id", user_id)
        )
        if plan_date:
            q = q.eq("plan_date", plan_date.isoformat())
        if templates_only:
            q = q.eq("is_template", True)
        res = q.order("plan_date", desc=True).limit(100).execute()
        plans: List[MealPlan] = []
        for r in res.data or []:
            embedded_items = r.pop("meal_plan_items", None) or []
            # Sort intra-plan items by meal_type then slot_order to match
            # the previous ordering ("meal_type" then "slot_order").
            embedded_items.sort(
                key=lambda i: (i.get("meal_type") or "", i.get("slot_order") or 0)
            )
            items = [self._row_to_item(i) for i in embedded_items]
            plans.append(self._row_to_plan(r, items))
        logger.info("✅ [MealPlan] list_for_user user=%s plans=%d", user_id, len(plans))
        return plans

    # ------------------------------------------------------------------
    # Simulate (what-if) — pure read; computes totals + remainder + swap ideas
    # ------------------------------------------------------------------

    async def simulate(self, plan_id: str, with_swaps: bool = True) -> SimulateResponse:
        """Rule-based projection only — fast path. Gemini swaps are computed
        out-of-band via :meth:`compute_and_persist_swaps` and surfaced to the
        client either through a follow-up GET or Realtime on the
        ``meal_plan_swap_suggestions`` table. See plan A5."""
        plan = await self.get(plan_id)
        if not plan:
            raise ValueError("plan not found")
        if not plan.target_snapshot:
            # Re-pull live targets if snapshot is missing
            plan.target_snapshot = await self._fetch_user_targets(plan.user_id)

        totals = await self._sum_items(plan.items)
        targets = plan.target_snapshot or {}
        remainder = MacroRemainder(
            calories=float(targets.get("calories", 0) or 0) - totals.calories,
            protein_g=float(targets.get("protein_g", 0) or 0) - totals.protein_g,
            carbs_g=float(targets.get("carbs_g", 0) or 0) - totals.carbs_g,
            fat_g=float(targets.get("fat_g", 0) or 0) - totals.fat_g,
        )
        adherence = self._adherence(totals, targets)

        # If a previous background run persisted swaps, hydrate them so the
        # response isn't empty on a follow-up simulate call.
        swaps: List[AiSwapSuggestion] = []
        coach_summary: Optional[str] = None
        if with_swaps:
            try:
                swaps, coach_summary = self._load_persisted_swaps(plan_id)
            except Exception as exc:  # surface but don't fail the projection
                logger.warning("⚠️ [MealPlan] failed to load persisted swaps: %s", exc)

        return SimulateResponse(
            plan_id=plan_id,
            totals=totals,
            target_snapshot=plan.target_snapshot or {},
            remainder=remainder,
            over_budget=remainder.calories < 0,
            adherence_pct=adherence,
            swap_suggestions=swaps,
            coach_summary=coach_summary,
        )

    async def compute_and_persist_swaps(self, plan_id: str) -> None:
        """Background-task entry point. Generates Gemini swap suggestions and
        upserts them into ``meal_plan_swap_suggestions`` so the client can
        poll / Realtime-subscribe. Errors are logged but never raised — this
        runs after the response has been sent."""
        try:
            plan = await self.get(plan_id)
            if not plan or not plan.items:
                logger.info(
                    "🔍 [MealPlan] swap bg task skipped (plan missing or empty): %s",
                    plan_id,
                )
                return
            if not plan.target_snapshot:
                plan.target_snapshot = await self._fetch_user_targets(plan.user_id)
            totals = await self._sum_items(plan.items)
            targets = plan.target_snapshot or {}
            remainder = MacroRemainder(
                calories=float(targets.get("calories", 0) or 0) - totals.calories,
                protein_g=float(targets.get("protein_g", 0) or 0) - totals.protein_g,
                carbs_g=float(targets.get("carbs_g", 0) or 0) - totals.carbs_g,
                fat_g=float(targets.get("fat_g", 0) or 0) - totals.fat_g,
            )
            swaps, coach_summary = await self._gemini_swaps(plan, totals, remainder)
            self._persist_swaps(plan_id, swaps, coach_summary)
            logger.info(
                "✅ [MealPlan] persisted %d swap suggestions for plan %s",
                len(swaps),
                plan_id,
            )
        except Exception as exc:
            logger.exception("❌ [MealPlan] swap background task failed: %s", exc)

    def _persist_swaps(
        self,
        plan_id: str,
        swaps: List[AiSwapSuggestion],
        coach_summary: Optional[str],
    ) -> None:
        payload = {
            "plan_id": plan_id,
            "suggestions": [s.model_dump() for s in swaps],
            "coach_summary": coach_summary,
            "generated_at": datetime.utcnow().isoformat(),
        }
        # Upsert by plan_id (one row per plan). Migration 2036 defines the
        # table with plan_id as primary key.
        self.db.client.table("meal_plan_swap_suggestions").upsert(
            payload, on_conflict="plan_id"
        ).execute()

    def _load_persisted_swaps(
        self, plan_id: str
    ) -> Tuple[List[AiSwapSuggestion], Optional[str]]:
        try:
            res = (
                self.db.client.table("meal_plan_swap_suggestions")
                .select("suggestions,coach_summary")
                .eq("plan_id", plan_id)
                .limit(1)
                .execute()
            )
        except Exception as exc:
            # Table may not exist yet on stale environments — degrade by
            # returning empty. Don't silently swallow the bug; log loudly.
            logger.warning(
                "⚠️ [MealPlan] swap suggestions table read failed (likely migration 2036 not applied): %s",
                exc,
            )
            return [], None
        if not res.data:
            return [], None
        row = res.data[0]
        raw = row.get("suggestions") or []
        out: List[AiSwapSuggestion] = []
        for s in raw:
            try:
                out.append(AiSwapSuggestion(**s))
            except Exception as exc:
                logger.warning("⚠️ [MealPlan] dropped malformed swap row: %s", exc)
        return out, row.get("coach_summary")

    # ------------------------------------------------------------------
    # Apply — write meal_plan_items as food_logs for a given date
    # ------------------------------------------------------------------

    async def apply(self, plan_id: str, target_date: date) -> ApplyResponse:
        plan = await self.get(plan_id)
        if not plan:
            raise ValueError("plan not found")

        existing_recipe_ids = self._existing_logged_recipe_ids(
            plan.user_id, target_date
        )
        food_log_ids: List[str] = []
        duplicates_skipped = 0

        for item in plan.items:
            if item.recipe_id and item.recipe_id in existing_recipe_ids:
                duplicates_skipped += 1
                continue
            log_id = await self._create_food_log_from_item(plan.user_id, target_date, item)
            food_log_ids.append(log_id)

        warning = None
        if duplicates_skipped:
            warning = (
                f"{duplicates_skipped} item(s) were already logged for "
                f"{target_date.isoformat()} and were skipped."
            )

        return ApplyResponse(
            plan_id=plan_id,
            target_date=target_date,
            food_log_ids=food_log_ids,
            duplicates_skipped=duplicates_skipped,
            duplicates_warning=warning,
        )

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    async def _fetch_user_targets(self, user_id: str) -> Dict[str, float]:
        try:
            res = (
                self.db.client.table("nutrition_preferences")
                .select(
                    "target_calories,target_protein_g,target_carbs_g,target_fat_g,target_fiber_g"
                )
                .eq("user_id", user_id)
                .limit(1)
                .execute()
            )
            if res.data:
                row = res.data[0]
                return {
                    "calories": row.get("target_calories") or 0,
                    "protein_g": row.get("target_protein_g") or 0,
                    "carbs_g": row.get("target_carbs_g") or 0,
                    "fat_g": row.get("target_fat_g") or 0,
                    "fiber_g": row.get("target_fiber_g") or 0,
                }
        except Exception:
            logger.exception("[MealPlan] target fetch failed")

        # Fall back to users table fields if nutrition_preferences absent
        try:
            res = (
                self.db.client.table("users")
                .select(
                    "daily_calorie_target,daily_protein_target_g,daily_carbs_target_g,daily_fat_target_g"
                )
                .eq("id", user_id)
                .limit(1)
                .execute()
            )
            if res.data:
                row = res.data[0]
                return {
                    "calories": row.get("daily_calorie_target") or 0,
                    "protein_g": row.get("daily_protein_target_g") or 0,
                    "carbs_g": row.get("daily_carbs_target_g") or 0,
                    "fat_g": row.get("daily_fat_target_g") or 0,
                    "fiber_g": 0,
                }
        except Exception:
            logger.exception("[MealPlan] users targets fallback failed")
        return {"calories": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0, "fiber_g": 0}

    async def _sum_items(self, items: List[MealPlanItem]) -> MacroTotals:
        totals = MacroTotals()
        if not items:
            return totals
        recipe_ids = [i.recipe_id for i in items if i.recipe_id]
        recipe_map: Dict[str, Dict[str, Any]] = {}
        if recipe_ids:
            res = (
                self.db.client.table("user_recipes")
                .select(
                    "id,calories_per_serving,protein_per_serving_g,carbs_per_serving_g,"
                    "fat_per_serving_g,fiber_per_serving_g,sugar_per_serving_g,sodium_per_serving_mg"
                )
                .in_("id", recipe_ids)
                .execute()
            )
            for r in res.data or []:
                recipe_map[r["id"]] = r

        for item in items:
            if item.recipe_id and item.recipe_id in recipe_map:
                r = recipe_map[item.recipe_id]
                mult = item.servings
                totals.calories += float(r.get("calories_per_serving") or 0) * mult
                totals.protein_g += float(r.get("protein_per_serving_g") or 0) * mult
                totals.carbs_g += float(r.get("carbs_per_serving_g") or 0) * mult
                totals.fat_g += float(r.get("fat_per_serving_g") or 0) * mult
                totals.fiber_g += float(r.get("fiber_per_serving_g") or 0) * mult
                totals.sugar_g += float(r.get("sugar_per_serving_g") or 0) * mult
                totals.sodium_mg += float(r.get("sodium_per_serving_mg") or 0) * mult
            elif item.food_items:
                for f in item.food_items:
                    totals.calories += float(f.get("calories") or 0)
                    totals.protein_g += float(f.get("protein") or f.get("protein_g") or 0)
                    totals.carbs_g += float(f.get("carbs") or f.get("carbs_g") or 0)
                    totals.fat_g += float(f.get("fat") or f.get("fat_g") or 0)
                    totals.fiber_g += float(f.get("fiber") or f.get("fiber_g") or 0)
                    totals.sodium_mg += float(f.get("sodium") or f.get("sodium_mg") or 0)
        return totals

    def _adherence(self, totals: MacroTotals, targets: Dict) -> Dict[str, float]:
        out: Dict[str, float] = {}
        for key, t_attr in (
            ("calories", "calories"),
            ("protein_g", "protein_g"),
            ("carbs_g", "carbs_g"),
            ("fat_g", "fat_g"),
            ("fiber_g", "fiber_g"),
        ):
            tgt = float(targets.get(key, 0) or 0)
            cur = getattr(totals, t_attr)
            out[key] = round((cur / tgt * 100) if tgt > 0 else 0, 1)
        return out

    async def _gemini_swaps(
        self, plan: MealPlan, totals: MacroTotals, remainder: MacroRemainder
    ) -> Tuple[List[AiSwapSuggestion], Optional[str]]:
        items_summary = []
        for item in plan.items:
            label = (
                f"recipe:{item.recipe_id}"
                if item.recipe_id
                else f"adhoc:{json.dumps(item.food_items)[:120]}"
            )
            items_summary.append(
                f"- {item.meal_type.value}: {label} x {item.servings} servings"
            )
        prompt = (
            "You are a registered nutritionist reviewing a one-day meal plan.\n"
            "Suggest up to 3 swaps that better hit the user's macro targets.\n"
            "Return JSON ONLY: {\"summary\": \"...\", \"swaps\": [{\"target_label\":\"\","
            "\"suggested_label\":\"\",\"rationale\":\"\",\"deltas\":{\"calories\":-120,\"protein_g\":18}}]}\n"
            f"Targets: {plan.target_snapshot}\n"
            f"Current totals: cal {totals.calories:.0f}, P {totals.protein_g:.0f}, "
            f"C {totals.carbs_g:.0f}, F {totals.fat_g:.0f}, fiber {totals.fiber_g:.0f}\n"
            f"Remainder vs target: cal {remainder.calories:.0f}, P {remainder.protein_g:.0f}, "
            f"C {remainder.carbs_g:.0f}, F {remainder.fat_g:.0f}\n"
            "Plan items:\n" + "\n".join(items_summary)
        )
        raw = await gemini_text(prompt, temperature=0.4, method_name="meal_plan_swaps")
        cleaned = raw.strip()
        if cleaned.startswith("```"):
            import re
            cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
            cleaned = re.sub(r"\s*```$", "", cleaned)
        data = json.loads(cleaned)
        swaps_out: List[AiSwapSuggestion] = []
        for s in (data.get("swaps") or [])[:3]:
            swaps_out.append(
                AiSwapSuggestion(
                    from_label=s.get("target_label", ""),
                    to_label=s.get("suggested_label", ""),
                    rationale=s.get("rationale", ""),
                    deltas=s.get("deltas", {}) or {},
                )
            )
        return swaps_out, data.get("summary")

    def _existing_logged_recipe_ids(self, user_id: str, target_date: date) -> set:
        try:
            res = (
                self.db.client.table("food_logs")
                .select("recipe_id")
                .eq("user_id", user_id)
                .gte("logged_at", f"{target_date.isoformat()}T00:00:00Z")
                .lte("logged_at", f"{target_date.isoformat()}T23:59:59Z")
                .not_.is_("recipe_id", "null")
                .execute()
            )
            return {r["recipe_id"] for r in (res.data or []) if r.get("recipe_id")}
        except Exception:
            return set()

    async def _create_food_log_from_item(
        self, user_id: str, target_date: date, item: MealPlanItem
    ) -> str:
        log_id = str(uuid.uuid4())
        # Compute totals from recipe or use ad-hoc
        if item.recipe_id:
            res = (
                self.db.client.table("user_recipes")
                .select("name,calories_per_serving,protein_per_serving_g,carbs_per_serving_g,"
                        "fat_per_serving_g,fiber_per_serving_g,sugar_per_serving_g,sodium_per_serving_mg")
                .eq("id", item.recipe_id)
                .limit(1)
                .execute()
            )
            r = (res.data or [{}])[0]
            mult = item.servings
            row = {
                "id": log_id,
                "user_id": user_id,
                "meal_type": item.meal_type.value,
                "logged_at": f"{target_date.isoformat()}T12:00:00Z",
                "food_items": [{"name": r.get("name", "Recipe"), "from_plan": True}],
                "total_calories": int(round((r.get("calories_per_serving") or 0) * mult)),
                "protein_g": float(r.get("protein_per_serving_g") or 0) * mult,
                "carbs_g": float(r.get("carbs_per_serving_g") or 0) * mult,
                "fat_g": float(r.get("fat_per_serving_g") or 0) * mult,
                "fiber_g": float(r.get("fiber_per_serving_g") or 0) * mult,
                "sugar_g": float(r.get("sugar_per_serving_g") or 0) * mult,
                "sodium_mg": float(r.get("sodium_per_serving_mg") or 0) * mult,
                "recipe_id": item.recipe_id,
                "servings_consumed": item.servings,
                "source_type": "meal_plan",
            }
        else:
            food_items = item.food_items or []
            cals = sum(float(f.get("calories") or 0) for f in food_items)
            row = {
                "id": log_id,
                "user_id": user_id,
                "meal_type": item.meal_type.value,
                "logged_at": f"{target_date.isoformat()}T12:00:00Z",
                "food_items": food_items,
                "total_calories": int(round(cals)),
                "protein_g": sum(float(f.get("protein") or f.get("protein_g") or 0) for f in food_items),
                "carbs_g": sum(float(f.get("carbs") or f.get("carbs_g") or 0) for f in food_items),
                "fat_g": sum(float(f.get("fat") or f.get("fat_g") or 0) for f in food_items),
                "fiber_g": sum(float(f.get("fiber") or f.get("fiber_g") or 0) for f in food_items),
                "source_type": "meal_plan",
            }
        self.db.client.table("food_logs").insert(row).execute()
        return log_id

    def _item_create_to_row(
        self, item_id: str, plan_id: str, item: MealPlanItemCreate, now_iso: str
    ) -> Dict:
        return {
            "id": item_id,
            "plan_id": plan_id,
            "meal_type": item.meal_type.value,
            "slot_order": item.slot_order,
            "recipe_id": item.recipe_id,
            "food_items": item.food_items,
            "servings": item.servings,
            "created_at": now_iso,
        }

    def _row_to_item(self, row: Dict) -> MealPlanItem:
        return MealPlanItem(
            id=row["id"],
            plan_id=row["plan_id"],
            meal_type=row["meal_type"],
            slot_order=row.get("slot_order") or 0,
            recipe_id=row.get("recipe_id"),
            food_items=row.get("food_items"),
            servings=float(row.get("servings") or 1),
            created_at=row["created_at"],
        )

    def _row_to_plan(self, row: Dict, items: List[MealPlanItem]) -> MealPlan:
        return MealPlan(
            id=row["id"],
            user_id=row["user_id"],
            name=row.get("name"),
            plan_date=row.get("plan_date"),
            is_template=row.get("is_template") or False,
            target_snapshot=row.get("target_snapshot"),
            notes=row.get("notes"),
            items=items,
            created_at=row["created_at"],
            updated_at=row.get("updated_at") or row["created_at"],
        )


_singleton: Optional[MealPlanService] = None


def get_meal_plan_service() -> MealPlanService:
    global _singleton
    if _singleton is None:
        _singleton = MealPlanService()
    return _singleton
