"""
Coach Review Service
====================
AI nutrition-pro reviews for recipes and meal plans.
Persists to coach_reviews; surfaces staleness when subject_version < current.
Allergen flags are honored from nutrition_preferences so users see RED warnings.
"""

import json
import logging
import re
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from models.coach_review import (
    CoachReview,
    CoachReviewKind,
    CoachReviewSubject,
    MicronutrientGap,
    SwapSuggestion,
)
from services.gemini_text_helper import gemini_text

logger = logging.getLogger(__name__)

_REVIEW_PROMPT = """You are a registered dietitian. Score the {subject} on a 0-100 scale.
Output JSON ONLY, exactly this shape:
{{
  "overall_score": 0-100,
  "macro_balance_notes": "short paragraph",
  "micronutrient_gaps": [{{"nutrient":"vitamin_d","deficit_pct":40,"suggestion":"add..."}}],
  "allergen_flags": ["peanut", ...],
  "glycemic_load_score": 0-100,
  "swap_suggestions": [{{"target_label":"","suggested_label":"","rationale":"","deltas":{{"protein_g":18,"calories":-120}}}}],
  "full_feedback": "1-2 paragraphs."
}}

User profile:
{profile}

Subject data:
{subject_data}
"""


def _strip_json(text: str) -> str:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
    return text


class CoachReviewService:
    def __init__(self):
        self.db = get_supabase_db()

    async def review_recipe(
        self, user_id: str, recipe_id: str, kind: CoachReviewKind = CoachReviewKind.AI_REQUESTED
    ) -> CoachReview:
        recipe = self._fetch_recipe(recipe_id)
        if not recipe:
            raise ValueError("recipe not found")
        ingredients = self._fetch_recipe_ingredients(recipe_id)
        profile = await self._fetch_profile(user_id)
        subject_data = json.dumps(
            {"recipe": recipe, "ingredients": ingredients}, default=str
        )
        ai = await self._call_gemini("recipe", subject_data, profile)
        return await self._persist(
            user_id=user_id,
            subject_type=CoachReviewSubject.RECIPE,
            subject_id=recipe_id,
            subject_version=self._current_recipe_version(recipe_id),
            kind=kind,
            ai=ai,
        )

    async def review_meal_plan(
        self, user_id: str, plan_id: str, kind: CoachReviewKind = CoachReviewKind.AI_REQUESTED
    ) -> CoachReview:
        plan = self._fetch_plan_with_items(plan_id)
        if not plan:
            raise ValueError("meal plan not found")
        profile = await self._fetch_profile(user_id)
        subject_data = json.dumps(plan, default=str)
        ai = await self._call_gemini("meal_plan", subject_data, profile)
        return await self._persist(
            user_id=user_id,
            subject_type=CoachReviewSubject.MEAL_PLAN,
            subject_id=plan_id,
            subject_version=None,
            kind=kind,
            ai=ai,
        )

    async def latest(
        self, subject_type: CoachReviewSubject, subject_id: str
    ) -> Optional[CoachReview]:
        res = (
            self.db.client.table("coach_reviews")
            .select("*")
            .eq("subject_type", subject_type.value)
            .eq("subject_id", subject_id)
            .order("reviewed_at", desc=True)
            .limit(1)
            .execute()
        )
        if not res.data:
            return None
        review = self._row_to_review(res.data[0])
        if subject_type == CoachReviewSubject.RECIPE and review.subject_version is not None:
            cur = self._current_recipe_version(subject_id)
            if cur is not None and cur > review.subject_version:
                review.is_stale = True
        return review

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    async def _call_gemini(
        self, subject_kind: str, subject_data: str, profile: Dict
    ) -> Dict:
        prompt = _REVIEW_PROMPT.format(
            subject=subject_kind, profile=json.dumps(profile, default=str), subject_data=subject_data,
        )
        raw = await gemini_text(prompt, temperature=0.2, method_name="coach_review")
        try:
            return json.loads(_strip_json(raw))
        except Exception:
            logger.exception("[CoachReview] failed to parse Gemini JSON")
            raise RuntimeError("AI review failed to return structured JSON")

    async def _persist(
        self,
        user_id: str,
        subject_type: CoachReviewSubject,
        subject_id: str,
        subject_version: Optional[int],
        kind: CoachReviewKind,
        ai: Dict,
    ) -> CoachReview:
        rid = str(uuid.uuid4())
        now_iso = datetime.utcnow().isoformat()
        # Honor user-profile allergens by elevating any matched flags
        profile = await self._fetch_profile(user_id)
        user_allergens = {a.lower() for a in (profile.get("allergens") or [])}
        flagged = list({
            f.lower() for f in (ai.get("allergen_flags") or [])
        } | user_allergens & {(f or "").lower() for f in (ai.get("allergen_flags") or [])})

        row = {
            "id": rid,
            "user_id": user_id,
            "subject_type": subject_type.value,
            "subject_id": subject_id,
            "subject_version": subject_version,
            "review_kind": kind.value,
            "overall_score": ai.get("overall_score"),
            "macro_balance_notes": ai.get("macro_balance_notes"),
            "micronutrient_gaps": ai.get("micronutrient_gaps") or [],
            "allergen_flags": flagged,
            "glycemic_load_score": ai.get("glycemic_load_score"),
            "swap_suggestions": ai.get("swap_suggestions") or [],
            "full_feedback": ai.get("full_feedback"),
            "model_id": "gemini-3-flash",
            "reviewed_at": now_iso,
        }
        self.db.client.table("coach_reviews").insert(row).execute()
        return self._row_to_review(row)

    def _fetch_recipe(self, recipe_id: str) -> Optional[Dict]:
        res = self.db.client.table("user_recipes").select("*").eq("id", recipe_id).limit(1).execute()
        return res.data[0] if res.data else None

    def _fetch_recipe_ingredients(self, recipe_id: str) -> List[Dict]:
        res = (
            self.db.client.table("recipe_ingredients")
            .select("*").eq("recipe_id", recipe_id).order("ingredient_order").execute()
        )
        return res.data or []

    def _fetch_plan_with_items(self, plan_id: str) -> Optional[Dict]:
        plan_res = self.db.client.table("meal_plans").select("*").eq("id", plan_id).limit(1).execute()
        if not plan_res.data:
            return None
        items_res = (
            self.db.client.table("meal_plan_items")
            .select("*").eq("plan_id", plan_id).execute()
        )
        return {**plan_res.data[0], "items": items_res.data or []}

    async def _fetch_profile(self, user_id: str) -> Dict[str, Any]:
        try:
            res = (
                self.db.client.table("nutrition_preferences")
                .select(
                    "target_calories,target_protein_g,target_carbs_g,target_fat_g,"
                    "diet_type,nutrition_goal,allergens,dietary_restrictions"
                )
                .eq("user_id", user_id).limit(1).execute()
            )
            if res.data:
                return res.data[0]
        except Exception:
            logger.warning("[CoachReview] no nutrition_preferences row")
        return {}

    def _current_recipe_version(self, recipe_id: str) -> Optional[int]:
        try:
            res = (
                self.db.client.table("recipe_versions")
                .select("version_number")
                .eq("recipe_id", recipe_id)
                .order("version_number", desc=True).limit(1).execute()
            )
            return (res.data or [{}])[0].get("version_number")
        except Exception:
            return None

    def _row_to_review(self, row: Dict) -> CoachReview:
        return CoachReview(
            id=row["id"], user_id=row["user_id"],
            subject_type=CoachReviewSubject(row["subject_type"]),
            subject_id=row["subject_id"],
            subject_version=row.get("subject_version"),
            review_kind=CoachReviewKind(row["review_kind"]),
            overall_score=row.get("overall_score"),
            macro_balance_notes=row.get("macro_balance_notes"),
            micronutrient_gaps=[
                MicronutrientGap(**g) if isinstance(g, dict) else g
                for g in (row.get("micronutrient_gaps") or [])
            ],
            allergen_flags=row.get("allergen_flags") or [],
            glycemic_load_score=row.get("glycemic_load_score"),
            swap_suggestions=[
                SwapSuggestion(**s) if isinstance(s, dict) else s
                for s in (row.get("swap_suggestions") or [])
            ],
            full_feedback=row.get("full_feedback"),
            model_id=row.get("model_id"),
            reviewed_at=row["reviewed_at"],
            human_pro_id=row.get("human_pro_id"),
        )


_singleton: Optional[CoachReviewService] = None


def get_coach_review_service() -> CoachReviewService:
    global _singleton
    if _singleton is None:
        _singleton = CoachReviewService()
    return _singleton
