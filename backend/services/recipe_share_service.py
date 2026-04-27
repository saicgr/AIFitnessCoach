"""
Recipe Share Service
====================
Public sharing flow for recipes.
- enable_share(recipe_id) → flips is_public=true, generates a slug, returns ShareLink
- disable_share(recipe_id)
- resolve(slug)             → public-safe payload (no PII)
- clone(slug, target_user)  → copies recipe to target_user with source_type=cloned_from_share

Slug collision: retry up to 5x with new random slug.
"""

import logging
import secrets
import uuid
from datetime import datetime
from typing import Optional

from core import branding
from core.config import get_settings
from core.db import get_supabase_db
from models.recipe_share import CloneRecipeResponse, PublicRecipeView, ShareLink

logger = logging.getLogger(__name__)
_settings = get_settings()


def _generate_slug(length: int = 8) -> str:
    """URL-safe, no ambiguous chars (no 0/O/1/l)."""
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789"
    return "".join(secrets.choice(alphabet) for _ in range(length))


def _link_url(slug: str) -> str:
    base = getattr(_settings, "share_link_base_url", None) or branding.RECIPE_SHARE_BASE
    return f"{base.rstrip('/')}/{slug}"


# ---------------------------------------------------------------------------
# Shared copy helpers
# ---------------------------------------------------------------------------
# These helpers are used by the share-flow `.clone()` AND by the Improvize
# service (services/recipe_improvize_service.py). Keeping a single copy path
# means the trigger `recalculate_recipe_nutrition` sees identical ingredient
# rows regardless of entry point, and any future field additions land in both
# flows automatically.


async def _copy_ingredients_to_recipe(source_recipe_id: str, target_recipe_id: str) -> int:
    """Copy all recipe_ingredients rows from source → target.

    - Re-numbers `ingredient_order` starting at 0 for determinism.
    - Generates new PK ids.
    - Preserves every nutrition/micronutrient column via `dict(ing)` so we
      don't silently drop columns when the schema grows.
    - Resets created_at/updated_at to now.
    Returns the number of ingredients copied.
    """
    db = get_supabase_db()
    now_iso = datetime.utcnow().isoformat()

    ing_res = (
        db.client.table("recipe_ingredients")
        .select("*")
        .eq("recipe_id", source_recipe_id)
        .order("ingredient_order")
        .execute()
    )
    rows = ing_res.data or []
    if not rows:
        return 0

    copies = []
    for idx, ing in enumerate(rows):
        row = dict(ing)
        # Rewrite identity + FK + ordering + timestamps; keep every other column
        row["id"] = str(uuid.uuid4())
        row["recipe_id"] = target_recipe_id
        row["ingredient_order"] = idx
        row["created_at"] = now_iso
        row["updated_at"] = now_iso
        copies.append(row)

    db.client.table("recipe_ingredients").insert(copies).execute()
    return len(copies)


async def _copy_recipe_to_user(
    source: dict,
    target_user_id: str,
    source_type: str,
    extras: Optional[dict] = None,
) -> str:
    """Create a new user_recipes row as a copy of `source` owned by `target_user_id`.

    - `source` is the raw row dict pulled from user_recipes (service-role read).
    - `source_type` is written verbatim — callers pass e.g. "cloned_from_share"
      or "improvized". This is NOT a foreign key; the enum is enforced at the
      DB layer.
    - `extras` lets callers inject/override fields. Typical uses:
        * share flow         → {"source_url": "/r/<slug>"}
        * improvize flow     → {"source_recipe_id", "source_recipe_name",
                                 "source_recipe_user_id", "name"}
      If a key in `extras` duplicates a key in the default copy, `extras` wins.
    - The new copy starts PRIVATE (`is_public=False`) and NON-CURATED
      (`is_curated=False`) — only an admin / seed process should flip those.
    - Per-serving macros are intentionally NOT copied here: the
      `recalculate_recipe_nutrition` trigger re-derives them from the
      ingredients we insert afterwards (so users editing the source don't
      leak stale macros into forks).

    Returns the new recipe id. Also copies ingredients.
    """
    db = get_supabase_db()
    new_id = str(uuid.uuid4())
    now_iso = datetime.utcnow().isoformat()

    copy = {
        "id": new_id,
        "user_id": target_user_id,
        "name": source.get("name"),
        "description": source.get("description"),
        "servings": source.get("servings") or 1,
        "prep_time_minutes": source.get("prep_time_minutes"),
        "cook_time_minutes": source.get("cook_time_minutes"),
        "instructions": source.get("instructions"),
        "image_url": source.get("image_url"),
        "category": source.get("category"),
        "cuisine": source.get("cuisine"),
        "tags": source.get("tags") or [],
        "source_type": source_type,
        "is_public": False,   # forks always start private
        "is_curated": False,  # forks are never curated; only seed script sets TRUE
        "cooking_method": source.get("cooking_method"),
        "cooked_yield_grams": source.get("cooked_yield_grams"),
        "created_at": now_iso,
        "updated_at": now_iso,
    }
    if extras:
        copy.update(extras)

    db.client.table("user_recipes").insert(copy).execute()

    # Copy ingredients; trigger recalcs per-serving macros from these rows.
    await _copy_ingredients_to_recipe(source["id"], new_id)

    return new_id


class RecipeShareService:
    def __init__(self):
        self.db = get_supabase_db()

    async def enable_share(self, user_id: str, recipe_id: str) -> ShareLink:
        # Verify ownership
        owner = self._fetch_recipe_owner(recipe_id)
        if owner != user_id:
            raise PermissionError("not your recipe")

        # Flip is_public on the recipe
        self.db.client.table("user_recipes").update(
            {"is_public": True, "updated_at": datetime.utcnow().isoformat()}
        ).eq("id", recipe_id).execute()

        # Reuse an existing slug if already shared
        existing = (
            self.db.client.table("recipe_share_links")
            .select("*").eq("recipe_id", recipe_id).limit(1).execute()
        )
        if existing.data:
            row = existing.data[0]
            return ShareLink(
                recipe_id=recipe_id, slug=row["slug"], url=_link_url(row["slug"]),
                view_count=row.get("view_count") or 0, save_count=row.get("save_count") or 0,
                created_at=row["created_at"], is_public=True,
            )

        # Create new slug with retry on collision
        for _ in range(5):
            slug = _generate_slug()
            try:
                row = {
                    "id": str(uuid.uuid4()),
                    "recipe_id": recipe_id,
                    "slug": slug,
                    "created_by": user_id,
                    "view_count": 0,
                    "save_count": 0,
                    "created_at": datetime.utcnow().isoformat(),
                }
                self.db.client.table("recipe_share_links").insert(row).execute()
                return ShareLink(
                    recipe_id=recipe_id, slug=slug, url=_link_url(slug),
                    view_count=0, save_count=0,
                    created_at=row["created_at"], is_public=True,
                )
            except Exception as exc:
                logger.warning("[Share] slug collision, retrying: %s", exc)
        raise RuntimeError("Could not generate a unique share slug")

    async def disable_share(self, user_id: str, recipe_id: str) -> bool:
        if self._fetch_recipe_owner(recipe_id) != user_id:
            raise PermissionError("not your recipe")
        self.db.client.table("user_recipes").update(
            {"is_public": False, "updated_at": datetime.utcnow().isoformat()}
        ).eq("id", recipe_id).execute()
        self.db.client.table("recipe_share_links").delete().eq("recipe_id", recipe_id).execute()
        return True

    async def resolve(self, slug: str) -> Optional[PublicRecipeView]:
        # Use the RPC that increments view_count atomically
        try:
            rpc = self.db.client.rpc("resolve_recipe_share", {"p_slug": slug}).execute()
            rows = rpc.data or []
        except Exception:
            rows = []
        if not rows:
            return None
        ref = rows[0]
        if not ref.get("is_public"):
            return None
        recipe_id = ref["recipe_id"]
        rec_res = self.db.client.table("user_recipes").select("*").eq("id", recipe_id).limit(1).execute()
        if not rec_res.data:
            return None
        rec = rec_res.data[0]
        ing_res = (
            self.db.client.table("recipe_ingredients")
            .select(
                "food_name,brand,amount,unit,amount_grams,calories,protein_g,carbs_g,fat_g,"
                "fiber_g,sugar_g,is_optional,is_negligible,notes"
            )
            .eq("recipe_id", recipe_id).order("ingredient_order").execute()
        )
        author_display = self._fetch_author_display_name(rec.get("user_id"))
        return PublicRecipeView(
            slug=slug,
            name=rec.get("name") or "Untitled recipe",
            description=rec.get("description"),
            image_url=rec.get("image_url"),
            servings=int(rec.get("servings") or 1),
            prep_time_minutes=rec.get("prep_time_minutes"),
            cook_time_minutes=rec.get("cook_time_minutes"),
            instructions=rec.get("instructions"),
            category=rec.get("category"),
            cuisine=rec.get("cuisine"),
            tags=rec.get("tags") or [],
            cooking_method=rec.get("cooking_method"),
            cooked_yield_grams=rec.get("cooked_yield_grams"),
            calories_per_serving=rec.get("calories_per_serving"),
            protein_per_serving_g=rec.get("protein_per_serving_g"),
            carbs_per_serving_g=rec.get("carbs_per_serving_g"),
            fat_per_serving_g=rec.get("fat_per_serving_g"),
            fiber_per_serving_g=rec.get("fiber_per_serving_g"),
            micronutrients_per_serving=rec.get("micronutrients_per_serving"),
            ingredients=ing_res.data or [],
            times_logged=int(rec.get("times_logged") or 0),
            view_count=ref.get("view_count") or 0,
            save_count=ref.get("save_count") or 0,
            author_display_name=author_display or "Anonymous chef",
        )

    async def clone(self, slug: str, target_user_id: str) -> CloneRecipeResponse:
        # Pull source recipe by slug (without bumping view_count this time)
        slug_res = (
            self.db.client.table("recipe_share_links")
            .select("recipe_id").eq("slug", slug).limit(1).execute()
        )
        if not slug_res.data:
            raise ValueError("share link not found")
        src_id = slug_res.data[0]["recipe_id"]

        # Detect already-cloned (source_url contains /r/{slug})
        existing = (
            self.db.client.table("user_recipes").select("id")
            .eq("user_id", target_user_id).eq("source_url", f"/r/{slug}").limit(1).execute()
        )
        if existing.data:
            return CloneRecipeResponse(
                new_recipe_id=existing.data[0]["id"],
                already_saved=True,
                message="You already saved this recipe.",
            )

        rec_res = self.db.client.table("user_recipes").select("*").eq("id", src_id).limit(1).execute()
        if not rec_res.data:
            raise ValueError("source recipe missing")
        src = rec_res.data[0]

        # Delegate to the shared copy helper (used by Improvize as well).
        # The share-specific field we inject is `source_url` so the "already
        # saved" lookup above continues to work on re-clone.
        new_id = await _copy_recipe_to_user(
            source=src,
            target_user_id=target_user_id,
            source_type="cloned_from_share",
            extras={"source_url": f"/r/{slug}"},
        )

        # Bump save_count
        try:
            self.db.client.rpc("increment_recipe_share_save", {"p_slug": slug}).execute()
        except Exception:
            pass

        return CloneRecipeResponse(
            new_recipe_id=new_id, already_saved=False,
            message="Recipe saved to your library.",
        )

    # ------------------------------------------------------------------
    # helpers
    # ------------------------------------------------------------------

    def _fetch_recipe_owner(self, recipe_id: str) -> Optional[str]:
        res = self.db.client.table("user_recipes").select("user_id").eq("id", recipe_id).limit(1).execute()
        return (res.data or [{}])[0].get("user_id")

    def _fetch_author_display_name(self, user_id: Optional[str]) -> Optional[str]:
        if not user_id:
            return None
        try:
            res = (
                self.db.client.table("users")
                .select("display_name,first_name,sharing_anonymous")
                .eq("id", user_id).limit(1).execute()
            )
            if not res.data:
                return None
            row = res.data[0]
            if row.get("sharing_anonymous"):
                return "Anonymous chef"
            return row.get("display_name") or row.get("first_name")
        except Exception:
            return None


_singleton: Optional[RecipeShareService] = None


def get_recipe_share_service() -> RecipeShareService:
    global _singleton
    if _singleton is None:
        _singleton = RecipeShareService()
    return _singleton
