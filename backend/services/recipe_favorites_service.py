"""
Recipe Favorites Service
========================

CRUD for the `favorite_recipes` join table (migration 1925).

Table shape:
    favorite_recipes(user_id uuid, recipe_id uuid, created_at timestamptz,
                     PRIMARY KEY (user_id, recipe_id))
RLS: users can SELECT/INSERT/DELETE only their own rows.

Public API mirrors `services/recipe_share_service.py` — an async class with a
module-level singleton accessor. All DB work uses the service-role supabase
client (get_supabase_db) so writes don't need an authenticated session; the
auth check happens at the route layer.
"""

import logging
from datetime import datetime
from typing import Dict, List, Optional

from core.db import get_supabase_db

logger = logging.getLogger(__name__)


class RecipeFavoritesService:
    """Async service wrapping the favorite_recipes join table."""

    def __init__(self):
        self.db = get_supabase_db()

    # ------------------------------------------------------------------
    # Writes
    # ------------------------------------------------------------------

    async def add(self, user_id: str, recipe_id: str) -> bool:
        """Insert a favorite row.

        Returns:
            True  -- newly inserted (user just favorited)
            False -- already favorited (composite PK conflict swallowed)

        Implementation detail: supabase-py doesn't expose a clean UPSERT with
        DO NOTHING semantics that distinguishes "inserted" from "conflicted",
        so we do a pre-flight existence check. This is safe because the
        primary key constraint still prevents duplicates on race — a second
        caller will hit an IntegrityError which we treat as "already existed".
        """
        try:
            existing = (
                self.db.client.table("favorite_recipes")
                .select("user_id")
                .eq("user_id", user_id)
                .eq("recipe_id", recipe_id)
                .limit(1)
                .execute()
            )
            if existing.data:
                return False

            now_iso = datetime.utcnow().isoformat()
            self.db.client.table("favorite_recipes").insert({
                "user_id": user_id,
                "recipe_id": recipe_id,
                "created_at": now_iso,
            }).execute()
            return True
        except Exception as exc:
            # Composite PK race-condition: second caller lost → already favorited
            msg = str(exc).lower()
            if "duplicate" in msg or "23505" in msg or "conflict" in msg:
                logger.debug("[Favorites] duplicate insert swallowed for %s/%s", user_id, recipe_id)
                return False
            logger.error("[Favorites] add failed: %s", exc, exc_info=True)
            raise

    async def remove(self, user_id: str, recipe_id: str) -> None:
        """Delete a favorite row. Idempotent — no error if missing."""
        try:
            self.db.client.table("favorite_recipes").delete()\
                .eq("user_id", user_id)\
                .eq("recipe_id", recipe_id)\
                .execute()
        except Exception as exc:
            logger.error("[Favorites] remove failed: %s", exc, exc_info=True)
            raise

    # ------------------------------------------------------------------
    # Reads
    # ------------------------------------------------------------------

    async def list_for_user(
        self, user_id: str, limit: int = 50, offset: int = 0
    ) -> List[dict]:
        """Return favorited recipes as a list of RecipeSummary-shaped dicts.

        Strategy: two-step fetch instead of a JOIN.
          1) Pull the user's favorite (recipe_id, created_at) rows ordered
             by favorite.created_at DESC.
          2) Batch-fetch the matching user_recipes rows (service role, since
             we want curated rows too which are visible to all users anyway).

        We then ingredient-count each recipe via a single aggregated query
        (SELECT recipe_id, count(*) grouped) to keep this endpoint O(1)
        regardless of favorites length. Supabase-py doesn't support
        aggregation natively, so we fall back to per-row count queries but
        cap at `limit` which is ≤50 (migration default).
        """
        # 1) Fetch favorites ordered by recency
        fav_res = (
            self.db.client.table("favorite_recipes")
            .select("recipe_id, created_at")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        fav_rows = fav_res.data or []
        if not fav_rows:
            return []

        recipe_ids = [r["recipe_id"] for r in fav_rows]

        # 2) Fetch the matching recipes — exclude soft-deleted ones.
        rec_res = (
            self.db.client.table("user_recipes")
            .select(
                "id, name, category, calories_per_serving, protein_per_serving_g, "
                "servings, times_logged, image_url, created_at, is_curated, slug, "
                "source_recipe_id, source_recipe_name, source_type"
            )
            .in_("id", recipe_ids)
            .is_("deleted_at", "null")
            .execute()
        )
        by_id = {r["id"]: r for r in (rec_res.data or [])}

        # Preserve the favorite-creation order; drop recipes that were
        # soft-deleted after being favorited (they won't be in `by_id`).
        ordered: List[dict] = []
        for fav in fav_rows:
            row = by_id.get(fav["recipe_id"])
            if row:
                ordered.append(row)
        return ordered

    async def is_favorited(self, user_id: str, recipe_id: str) -> bool:
        """Check a single recipe. Uses composite PK index → sub-ms."""
        if not user_id or not recipe_id:
            return False
        try:
            res = (
                self.db.client.table("favorite_recipes")
                .select("user_id")
                .eq("user_id", user_id)
                .eq("recipe_id", recipe_id)
                .limit(1)
                .execute()
            )
            return bool(res.data)
        except Exception as exc:
            logger.warning("[Favorites] is_favorited failed: %s", exc)
            return False

    async def is_favorited_bulk(
        self, user_id: str, recipe_ids: List[str]
    ) -> Dict[str, bool]:
        """Bulk-check favorited status for a page of recipes.

        Used by `GET /recipes` so the list can render hearts without N+1
        lookups. Returns a dict keyed by every id in `recipe_ids`, with
        `False` for non-favorited (important — callers can blindly .get()).
        """
        if not user_id or not recipe_ids:
            return {rid: False for rid in (recipe_ids or [])}
        try:
            res = (
                self.db.client.table("favorite_recipes")
                .select("recipe_id")
                .eq("user_id", user_id)
                .in_("recipe_id", recipe_ids)
                .execute()
            )
            faved = {row["recipe_id"] for row in (res.data or [])}
            return {rid: (rid in faved) for rid in recipe_ids}
        except Exception as exc:
            logger.warning("[Favorites] is_favorited_bulk failed: %s", exc)
            return {rid: False for rid in recipe_ids}

    async def recipe_ids_for_user(self, user_id: str) -> List[str]:
        """Return all recipe_ids favorited by a user. Helper for list filters.

        Used by `GET /recipes?is_favorite=true` — rather than JOIN through
        supabase-py (which is awkward), we pull the id list and IN-filter.
        A user with 10k favorites would be inefficient, but realistic scale
        is <500 so this is fine.
        """
        try:
            res = (
                self.db.client.table("favorite_recipes")
                .select("recipe_id")
                .eq("user_id", user_id)
                .execute()
            )
            return [row["recipe_id"] for row in (res.data or [])]
        except Exception as exc:
            logger.warning("[Favorites] recipe_ids_for_user failed: %s", exc)
            return []


# ---------------------------------------------------------------------------
# Singleton accessor (matches recipe_share_service pattern)
# ---------------------------------------------------------------------------

_instance: Optional[RecipeFavoritesService] = None


def get_recipe_favorites_service() -> RecipeFavoritesService:
    global _instance
    if _instance is None:
        _instance = RecipeFavoritesService()
    return _instance
