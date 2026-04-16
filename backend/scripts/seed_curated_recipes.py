"""Seed curated recipes into user_recipes from data/curated_recipes.yaml.

Idempotent: matches existing curated rows by (slug) and UPDATES in place, otherwise
INSERTs. Ingredients are deleted and re-inserted on every run so the
recipe_ingredients → user_recipes nutrition trigger recomputes per-serving macros
from the latest YAML values.

Usage:
  cd backend && python -m scripts.seed_curated_recipes
"""
from __future__ import annotations

import sys
from pathlib import Path

import yaml

# Ensure `backend/` is importable when run as a script (python -m scripts.seed...)
BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from core.db import get_supabase_db  # noqa: E402


DATA_PATH = BACKEND_DIR / "data" / "curated_recipes.yaml"


def _load_recipes() -> list[dict]:
    with DATA_PATH.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, list) or not data:
        raise RuntimeError(f"{DATA_PATH} must contain a non-empty YAML list of recipes")
    return data


def _find_existing_curated_id(client, slug: str) -> str | None:
    """Return the id of an existing non-deleted curated recipe matching slug, if any."""
    res = (
        client.table("user_recipes")
        .select("id")
        .eq("slug", slug)
        .eq("is_curated", True)
        .is_("deleted_at", "null")
        .limit(1)
        .execute()
    )
    rows = res.data or []
    return rows[0]["id"] if rows else None


def _recipe_payload(r: dict) -> dict:
    """Build the user_recipes row payload from a YAML entry."""
    return {
        "user_id": None,  # curated rows have no owner — allowed by migration 1925
        "name": r["name"],
        "description": r.get("description"),
        "category": r.get("category"),
        "cuisine": r.get("cuisine"),
        "servings": r.get("servings", 1),
        "prep_time_minutes": r.get("prep_time_minutes"),
        "cook_time_minutes": r.get("cook_time_minutes"),
        "instructions": r.get("instructions"),
        "image_url": r.get("image_url"),
        "tags": r.get("tags", []),
        "is_curated": True,
        "is_public": True,  # Discover recipes are inherently public
        "slug": r["slug"],
        "source_type": "curated",
    }


def _ingredient_payload(recipe_id: str, idx: int, ing: dict) -> dict:
    """Build a recipe_ingredients row. Column names match migration 039."""
    return {
        "recipe_id": recipe_id,
        "ingredient_order": idx,
        "food_name": ing["food_name"],
        "amount": ing["amount"],
        "unit": ing["unit"],
        "calories": ing.get("calories", 0),
        "protein_g": ing.get("protein_g", 0),
        "carbs_g": ing.get("carbs_g", 0),
        "fat_g": ing.get("fat_g", 0),
        "fiber_g": ing.get("fiber_g", 0),
        "sugar_g": ing.get("sugar_g"),
    }


def main() -> None:
    recipes = _load_recipes()
    db = get_supabase_db()
    client = db.client

    inserted = 0
    updated = 0

    print(f"Seeding {len(recipes)} curated recipes from {DATA_PATH.name}\n")

    for r in recipes:
        slug = r["slug"]
        payload = _recipe_payload(r)

        existing_id = _find_existing_curated_id(client, slug)

        if existing_id:
            client.table("user_recipes").update(payload).eq("id", existing_id).execute()
            recipe_id = existing_id
            # Delete existing ingredients so the trigger recomputes nutrition cleanly
            client.table("recipe_ingredients").delete().eq("recipe_id", recipe_id).execute()
            updated += 1
            marker = "~"
        else:
            res = client.table("user_recipes").insert(payload).execute()
            if not res.data:
                raise RuntimeError(f"Insert failed for {slug}: no data returned")
            recipe_id = res.data[0]["id"]
            inserted += 1
            marker = "+"

        # Insert ingredients — trigger recalculates recipe nutrition after each insert
        ings = r.get("ingredients", []) or []
        for idx, ing in enumerate(ings):
            client.table("recipe_ingredients").insert(
                _ingredient_payload(recipe_id, idx, ing)
            ).execute()

        print(f"  {marker} {slug:<32} {recipe_id}  ({len(ings)} ingredients)")

    print(f"\n  {inserted} inserted, {updated} updated, {len(recipes) - inserted - updated} skipped")


if __name__ == "__main__":
    main()
