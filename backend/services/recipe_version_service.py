"""
Recipe Version Service
======================
List versions, compute diffs between two versions, revert (creates a new
version representing the revert — never destroys history).

Most version creation happens via the snapshot_recipe_version() trigger
on UPDATE of user_recipes (migration 505). This service handles the human-
facing operations.
"""

import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from models.recipe_version import (
    FieldDiff,
    IngredientDiff,
    RecipeDiff,
    RecipeRevertResponse,
    RecipeVersion,
    RecipeVersionSummary,
    RecipeVersionsResponse,
)

logger = logging.getLogger(__name__)

# Fields shown in field-level diff (everything else is internal/computed)
_DIFFABLE_FIELDS = (
    "name", "description", "servings", "prep_time_minutes", "cook_time_minutes",
    "instructions", "image_url", "category", "cuisine", "tags", "is_public",
    "cooking_method", "cooked_yield_grams",
)


class RecipeVersionService:
    def __init__(self):
        self.db = get_supabase_db()

    async def list_versions(self, recipe_id: str, limit: int = 50) -> RecipeVersionsResponse:
        res = (
            self.db.client.table("recipe_versions")
            .select("id,recipe_id,version_number,change_summary,edited_by,edited_at")
            .eq("recipe_id", recipe_id)
            .order("version_number", desc=True).limit(limit).execute()
        )
        items = [RecipeVersionSummary(**r) for r in (res.data or [])]
        current = items[0].version_number if items else 0
        return RecipeVersionsResponse(items=items, total_count=len(items), current_version=current)

    async def get_version(self, recipe_id: str, version_id: str) -> Optional[RecipeVersion]:
        res = (
            self.db.client.table("recipe_versions")
            .select("*")
            .eq("recipe_id", recipe_id).eq("id", version_id).limit(1).execute()
        )
        return RecipeVersion(**res.data[0]) if res.data else None

    async def diff(self, recipe_id: str, from_version: int, to_version: int) -> RecipeDiff:
        a = await self._snapshot_for(recipe_id, from_version)
        b = await self._snapshot_for(recipe_id, to_version)
        if not a or not b:
            raise ValueError("one or both versions not found")

        field_diffs: List[FieldDiff] = []
        for f in _DIFFABLE_FIELDS:
            if a.get(f) != b.get(f):
                field_diffs.append(FieldDiff(field=f, before=a.get(f), after=b.get(f)))

        ingredient_diffs = self._diff_ingredients(
            a.get("ingredients") or [], b.get("ingredients") or []
        )

        return RecipeDiff(
            from_version=from_version, to_version=to_version,
            field_diffs=field_diffs, ingredient_diffs=ingredient_diffs,
        )

    async def revert(
        self, recipe_id: str, target_version: int, edited_by: Optional[str]
    ) -> RecipeRevertResponse:
        snapshot = await self._snapshot_for(recipe_id, target_version)
        if not snapshot:
            raise ValueError("target version not found")

        # Collect schedule count for the warning text the UI shows BEFORE confirming.
        sched_res = (
            self.db.client.table("scheduled_recipe_logs")
            .select("id", count="exact")
            .eq("recipe_id", recipe_id).eq("enabled", True).execute()
        )
        sched_count = sched_res.count or 0

        # Apply revert by writing back the diffable fields (the snapshot trigger will
        # then capture the previous-current state as a new version).
        patch = {f: snapshot.get(f) for f in _DIFFABLE_FIELDS if f in snapshot}
        patch["updated_at"] = datetime.utcnow().isoformat()
        self.db.client.table("user_recipes").update(patch).eq("id", recipe_id).execute()

        # Restore ingredients: simplest correct approach is delete + reinsert
        old_ingredients = snapshot.get("ingredients") or []
        self.db.client.table("recipe_ingredients").delete().eq("recipe_id", recipe_id).execute()
        if old_ingredients:
            insert_rows: List[Dict[str, Any]] = []
            for idx, ing in enumerate(old_ingredients):
                row = dict(ing)
                row.pop("id", None)
                row.pop("created_at", None)
                row.pop("updated_at", None)
                row["recipe_id"] = recipe_id
                row["ingredient_order"] = idx
                insert_rows.append(row)
            self.db.client.table("recipe_ingredients").insert(insert_rows).execute()

        # Find the new current version that the trigger just created
        cur_res = (
            self.db.client.table("recipe_versions")
            .select("version_number").eq("recipe_id", recipe_id)
            .order("version_number", desc=True).limit(1).execute()
        )
        new_current = (cur_res.data or [{}])[0].get("version_number") or target_version

        return RecipeRevertResponse(
            success=True,
            new_current_version=new_current,
            message=f"Reverted to v{target_version}. A new history entry was created.",
            schedules_using_recipe_count=sched_count,
        )

    async def _snapshot_for(self, recipe_id: str, version_number: int) -> Optional[Dict]:
        res = (
            self.db.client.table("recipe_versions").select("recipe_snapshot")
            .eq("recipe_id", recipe_id).eq("version_number", version_number).limit(1).execute()
        )
        return (res.data or [{}])[0].get("recipe_snapshot")

    def _diff_ingredients(self, before: List[Dict], after: List[Dict]) -> List[IngredientDiff]:
        by_name_a = {(b.get("food_name") or "").lower(): b for b in before}
        by_name_b = {(a.get("food_name") or "").lower(): a for a in after}
        out: List[IngredientDiff] = []
        for name in by_name_b.keys() - by_name_a.keys():
            out.append(IngredientDiff(change="added", food_name=name, after=by_name_b[name]))
        for name in by_name_a.keys() - by_name_b.keys():
            out.append(IngredientDiff(change="removed", food_name=name, before=by_name_a[name]))
        for name in by_name_a.keys() & by_name_b.keys():
            if by_name_a[name] != by_name_b[name]:
                out.append(IngredientDiff(
                    change="modified", food_name=name,
                    before=by_name_a[name], after=by_name_b[name],
                ))
        return out


_singleton: Optional[RecipeVersionService] = None


def get_recipe_version_service() -> RecipeVersionService:
    global _singleton
    if _singleton is None:
        _singleton = RecipeVersionService()
    return _singleton
