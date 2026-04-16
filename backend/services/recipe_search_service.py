"""
Recipe Search Service
=====================
Hybrid lexical + semantic search over recipes.

Lexical:  pg_trgm on user_recipes.name + recipe_ingredients.food_name (migration 510).
          Tags array via GIN; cuisine/category exact match.
Semantic: ChromaDB saved_foods collection extended to include recipes
          (source_type='recipe'); cosine similarity top-K.
"""

import asyncio
import logging
from typing import List, Optional

from core.db import get_supabase_db
from models.recipe import RecipeSummary, RecipesResponse

logger = logging.getLogger(__name__)


class RecipeSearchService:
    def __init__(self):
        self.db = get_supabase_db()

    async def search(
        self,
        user_id: str,
        query: str,
        scope: str = "mine",         # 'mine' | 'community'
        category: Optional[str] = None,
        cuisine: Optional[str] = None,
        has_leftovers: bool = False,
        limit: int = 30,
    ) -> RecipesResponse:
        q = (query or "").strip()
        if len(q) < 2:
            return RecipesResponse(items=[], total_count=0)

        # Run lexical + semantic in parallel
        lex_task = asyncio.create_task(
            self._lexical(user_id, q, scope, category, cuisine, has_leftovers, limit)
        )
        sem_task = asyncio.create_task(
            self._semantic(user_id, q, scope, limit)
        )
        lex_results, sem_results = await asyncio.gather(lex_task, sem_task)

        # Merge by recipe_id, preserve scoring (lexical first; semantic only adds)
        seen = set()
        merged: List[RecipeSummary] = []
        for r in lex_results + sem_results:
            if r.id in seen:
                continue
            seen.add(r.id)
            merged.append(r)
            if len(merged) >= limit:
                break
        return RecipesResponse(items=merged, total_count=len(merged))

    # ------------------------------------------------------------------
    # Lexical via Postgres
    # ------------------------------------------------------------------

    async def _lexical(
        self, user_id: str, q: str, scope: str,
        category: Optional[str], cuisine: Optional[str],
        has_leftovers: bool, limit: int,
    ) -> List[RecipeSummary]:
        try:
            qb = (
                self.db.client.table("user_recipes")
                .select(
                    "id,name,category,calories_per_serving,protein_per_serving_g,"
                    "servings,times_logged,image_url,created_at,user_id,is_public"
                )
                .is_("deleted_at", "null")
            )
            if scope == "mine":
                qb = qb.eq("user_id", user_id)
            else:
                qb = qb.eq("is_public", True)
            if category:
                qb = qb.eq("category", category)
            if cuisine:
                qb = qb.eq("cuisine", cuisine)

            # Use ilike for substring match. pg_trgm fuzzy matching is best done via RPC,
            # but ilike covers most user typing scenarios cheaply.
            qb = qb.ilike("name", f"%{q}%")
            res = qb.order("times_logged", desc=True).limit(limit).execute()
        except Exception:
            logger.exception("[RecipeSearch] lexical (name) failed")
            return []

        rows = res.data or []

        # Fold in ingredient-name matches (recipes whose ingredients contain the query)
        try:
            ing_res = (
                self.db.client.table("recipe_ingredients")
                .select("recipe_id")
                .ilike("food_name", f"%{q}%").limit(200).execute()
            )
            recipe_ids_from_ings = list({r["recipe_id"] for r in (ing_res.data or [])})
            if recipe_ids_from_ings:
                already = {r["id"] for r in rows}
                missing = [rid for rid in recipe_ids_from_ings if rid not in already][:limit]
                if missing:
                    extra_qb = (
                        self.db.client.table("user_recipes")
                        .select(
                            "id,name,category,calories_per_serving,protein_per_serving_g,"
                            "servings,times_logged,image_url,created_at,user_id,is_public"
                        )
                        .in_("id", missing).is_("deleted_at", "null")
                    )
                    if scope == "mine":
                        extra_qb = extra_qb.eq("user_id", user_id)
                    else:
                        extra_qb = extra_qb.eq("is_public", True)
                    extra_res = extra_qb.execute()
                    rows.extend(extra_res.data or [])
        except Exception:
            logger.exception("[RecipeSearch] ingredient match failed")

        if has_leftovers:
            # Filter to recipes that have an active cook_event for this user
            try:
                cook_res = (
                    self.db.client.table("recipe_cook_events")
                    .select("recipe_id").eq("user_id", user_id)
                    .gt("portions_remaining", 0).execute()
                )
                allowed = {r["recipe_id"] for r in (cook_res.data or []) if r.get("recipe_id")}
                rows = [r for r in rows if r["id"] in allowed]
            except Exception:
                logger.warning("[RecipeSearch] leftovers filter failed")

        return [self._row_to_summary(r) for r in rows[:limit]]

    # ------------------------------------------------------------------
    # Semantic via ChromaDB (best-effort; returns [] if collection not extended yet)
    # ------------------------------------------------------------------

    async def _semantic(
        self, user_id: str, q: str, scope: str, limit: int
    ) -> List[RecipeSummary]:
        try:
            from services.saved_foods_rag_service import get_saved_foods_rag

            rag = get_saved_foods_rag()
            results = await rag.semantic_search(
                user_id=user_id if scope == "mine" else None,
                query=q,
                source_type="recipe",
                limit=limit,
            )
            recipe_ids = [r.get("recipe_id") for r in results if r.get("recipe_id")]
            if not recipe_ids:
                return []
            qb = (
                self.db.client.table("user_recipes")
                .select(
                    "id,name,category,calories_per_serving,protein_per_serving_g,"
                    "servings,times_logged,image_url,created_at"
                )
                .in_("id", recipe_ids).is_("deleted_at", "null")
            )
            res = qb.execute()
            return [self._row_to_summary(r) for r in (res.data or [])]
        except Exception:
            return []

    def _row_to_summary(self, row: dict) -> RecipeSummary:
        return RecipeSummary(
            id=row["id"], name=row["name"],
            category=row.get("category"),
            calories_per_serving=row.get("calories_per_serving"),
            protein_per_serving_g=row.get("protein_per_serving_g"),
            servings=int(row.get("servings") or 1),
            ingredient_count=0,
            times_logged=int(row.get("times_logged") or 0),
            image_url=row.get("image_url"),
            created_at=row["created_at"],
        )


_singleton: Optional[RecipeSearchService] = None


def get_recipe_search_service() -> RecipeSearchService:
    global _singleton
    if _singleton is None:
        _singleton = RecipeSearchService()
    return _singleton
