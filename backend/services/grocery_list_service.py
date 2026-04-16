"""
Grocery List Service
====================
Build grocery lists from a meal plan or single recipe; manage checkoff state;
classify each item into an aisle (LLM-cached); export to text or CSV.

Unit reconciliation uses existing food_analysis/parser.py weight converters
where possible; incompatible units stay as separate rows with notes.
"""

import csv
import io
import json
import logging
import re
import uuid
from collections import defaultdict
from datetime import datetime
from typing import Dict, List, Optional

from core.db import get_supabase_db
from models.grocery_list import (
    Aisle,
    GroceryList,
    GroceryListCreate,
    GroceryListItem,
    GroceryListItemBase,
    GroceryListItemUpdate,
    GroceryListSummary,
)
from services.food_analysis.parser import _weight_unit_to_grams
from services.gemini_text_helper import gemini_text

logger = logging.getLogger(__name__)


class GroceryListService:
    def __init__(self):
        self.db = get_supabase_db()
        # Process-local aisle cache; LLM call only on cache miss
        self._aisle_cache: Dict[str, Aisle] = {}

    # ------------------------------------------------------------------
    # Build
    # ------------------------------------------------------------------

    async def build(self, user_id: str, req: GroceryListCreate) -> GroceryList:
        # Manual blank list — no source required
        if not req.meal_plan_id and not req.source_recipe_id:
            return await self._create_blank_list(user_id, req)

    async def _create_blank_list(self, user_id: str, req: GroceryListCreate) -> GroceryList:
        """Create an empty grocery list the user can populate manually."""
        list_id = str(uuid.uuid4())
        now_iso = datetime.utcnow().isoformat()
        list_row = {
            "id": list_id,
            "user_id": user_id,
            "name": req.name or "My grocery list",
            "notes": req.notes,
            "created_at": now_iso,
            "updated_at": now_iso,
        }
        self.db.client.table("grocery_lists").insert(list_row).execute()
        return GroceryList(
            id=list_id, user_id=user_id,
            name=list_row["name"], notes=req.notes,
            items=[], created_at=now_iso, updated_at=now_iso,
        )

        if req.meal_plan_id:
            recipe_ids, plan_label = self._recipes_in_plan(req.meal_plan_id)
            list_name = req.name or f"Grocery list for {plan_label}"
        else:
            recipe_ids = [req.source_recipe_id]
            res = (
                self.db.client.table("user_recipes")
                .select("name").eq("id", req.source_recipe_id).limit(1).execute()
            )
            single_name = (res.data or [{}])[0].get("name") or "recipe"
            list_name = req.name or f"Grocery list for {single_name}"

        ingredients = self._fetch_ingredients_for_recipes(recipe_ids)
        aggregated = self._aggregate_ingredients(ingredients)

        staples = await self._user_staples(user_id) if req.suppress_staples else set()

        list_id = str(uuid.uuid4())
        now_iso = datetime.utcnow().isoformat()
        list_row = {
            "id": list_id,
            "user_id": user_id,
            "meal_plan_id": req.meal_plan_id,
            "source_recipe_id": req.source_recipe_id,
            "name": list_name,
            "notes": req.notes,
            "created_at": now_iso,
            "updated_at": now_iso,
        }
        self.db.client.table("grocery_lists").insert(list_row).execute()

        item_rows: List[Dict] = []
        items_out: List[GroceryListItem] = []
        for agg in aggregated:
            aisle = await self._classify_aisle(agg["ingredient_name"])
            is_staple = agg["ingredient_name"].lower() in staples
            row = {
                "id": str(uuid.uuid4()),
                "list_id": list_id,
                "ingredient_name": agg["ingredient_name"],
                "quantity": agg.get("quantity"),
                "unit": agg.get("unit"),
                "aisle": aisle.value if aisle else None,
                "is_checked": False,
                "is_staple_suppressed": is_staple,
                "source_recipe_ids": agg.get("source_recipe_ids", []),
                "notes": agg.get("notes"),
                "created_at": now_iso,
                "updated_at": now_iso,
            }
            item_rows.append(row)
            items_out.append(GroceryListItem(**row))

        if item_rows:
            self.db.client.table("grocery_list_items").insert(item_rows).execute()

        return GroceryList(
            id=list_id, user_id=user_id,
            meal_plan_id=req.meal_plan_id, source_recipe_id=req.source_recipe_id,
            name=list_name, notes=req.notes,
            items=items_out,
            created_at=now_iso, updated_at=now_iso,
        )

    # ------------------------------------------------------------------
    # CRUD on lists + items
    # ------------------------------------------------------------------

    async def get(self, list_id: str) -> Optional[GroceryList]:
        res = self.db.client.table("grocery_lists").select("*").eq("id", list_id).limit(1).execute()
        if not res.data:
            return None
        list_row = res.data[0]
        items_res = (
            self.db.client.table("grocery_list_items")
            .select("*").eq("list_id", list_id).order("aisle").order("ingredient_name")
            .execute()
        )
        items = [GroceryListItem(**r) for r in (items_res.data or [])]
        return GroceryList(items=items, **list_row)

    async def list_for_user(self, user_id: str, limit: int = 50) -> List[GroceryListSummary]:
        res = (
            self.db.client.table("grocery_lists")
            .select("id,name,meal_plan_id,source_recipe_id,created_at")
            .eq("user_id", user_id)
            .order("created_at", desc=True).limit(limit).execute()
        )
        out: List[GroceryListSummary] = []
        for r in res.data or []:
            cnt_res = (
                self.db.client.table("grocery_list_items")
                .select("id,is_checked", count="exact")
                .eq("list_id", r["id"]).execute()
            )
            total = cnt_res.count or 0
            checked = sum(1 for i in (cnt_res.data or []) if i.get("is_checked"))
            out.append(GroceryListSummary(
                id=r["id"], name=r.get("name"),
                item_count=total, checked_count=checked,
                meal_plan_id=r.get("meal_plan_id"),
                source_recipe_id=r.get("source_recipe_id"),
                created_at=r["created_at"],
            ))
        return out

    async def update_item(self, item_id: str, req: GroceryListItemUpdate) -> Optional[GroceryListItem]:
        patch = {k: v for k, v in req.model_dump(exclude_none=True).items()}
        if "aisle" in patch and patch["aisle"]:
            patch["aisle"] = patch["aisle"].value
        patch["updated_at"] = datetime.utcnow().isoformat()
        self.db.client.table("grocery_list_items").update(patch).eq("id", item_id).execute()
        res = (
            self.db.client.table("grocery_list_items")
            .select("*").eq("id", item_id).limit(1).execute()
        )
        return GroceryListItem(**res.data[0]) if res.data else None

    async def add_item(self, list_id: str, item: GroceryListItemBase) -> GroceryListItem:
        item_id = str(uuid.uuid4())
        now_iso = datetime.utcnow().isoformat()
        if not item.aisle:
            item.aisle = await self._classify_aisle(item.ingredient_name)
        row = {
            "id": item_id, "list_id": list_id,
            **item.model_dump(),
            "aisle": item.aisle.value if item.aisle else None,
            "created_at": now_iso, "updated_at": now_iso,
        }
        self.db.client.table("grocery_list_items").insert(row).execute()
        return GroceryListItem(**row)

    async def delete_item(self, item_id: str) -> bool:
        self.db.client.table("grocery_list_items").delete().eq("id", item_id).execute()
        return True

    # ------------------------------------------------------------------
    # Export
    # ------------------------------------------------------------------

    async def export_text(self, list_id: str) -> str:
        gl = await self.get(list_id)
        if not gl:
            return ""
        by_aisle: Dict[str, List[GroceryListItem]] = defaultdict(list)
        for item in gl.items:
            if item.is_staple_suppressed:
                continue
            by_aisle[(item.aisle.value if item.aisle else "other").upper()].append(item)
        out_lines = [f"# {gl.name or 'Grocery list'}"]
        for aisle in sorted(by_aisle.keys()):
            out_lines.append(f"\n## {aisle}")
            for item in by_aisle[aisle]:
                qty = (
                    f"{item.quantity:g} {item.unit or ''}".strip()
                    if item.quantity else ""
                )
                check = "[x]" if item.is_checked else "[ ]"
                out_lines.append(f"{check} {item.ingredient_name}  {qty}".rstrip())
        return "\n".join(out_lines)

    async def export_csv(self, list_id: str) -> str:
        gl = await self.get(list_id)
        if not gl:
            return ""
        buf = io.StringIO()
        w = csv.writer(buf)
        w.writerow(["aisle", "ingredient", "quantity", "unit", "checked", "notes"])
        for item in gl.items:
            if item.is_staple_suppressed:
                continue
            w.writerow([
                item.aisle.value if item.aisle else "other",
                item.ingredient_name,
                f"{item.quantity:g}" if item.quantity else "",
                item.unit or "",
                "yes" if item.is_checked else "no",
                item.notes or "",
            ])
        return buf.getvalue()

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _recipes_in_plan(self, plan_id: str):
        items_res = (
            self.db.client.table("meal_plan_items")
            .select("recipe_id").eq("plan_id", plan_id).execute()
        )
        recipe_ids = [r["recipe_id"] for r in (items_res.data or []) if r.get("recipe_id")]
        plan_res = (
            self.db.client.table("meal_plans")
            .select("name,plan_date").eq("id", plan_id).limit(1).execute()
        )
        plan_row = (plan_res.data or [{}])[0]
        label = plan_row.get("name") or plan_row.get("plan_date") or "plan"
        return recipe_ids, str(label)

    def _fetch_ingredients_for_recipes(self, recipe_ids: List[str]) -> List[Dict]:
        if not recipe_ids:
            return []
        res = (
            self.db.client.table("recipe_ingredients")
            .select("recipe_id,food_name,brand,amount,unit,amount_grams,is_negligible")
            .in_("recipe_id", recipe_ids).execute()
        )
        rows = res.data or []
        return [r for r in rows if not r.get("is_negligible")]

    def _aggregate_ingredients(self, rows: List[Dict]) -> List[Dict]:
        """Group by lower(food_name); merge quantities when units convert; otherwise keep separate.

        Edge case (per plan): "100g chicken" + "4oz chicken" → both → grams → 100 + 113.4 = 213.4g.
        Incompatible ("1 pinch" + "1 tbsp") → kept separate with a note.
        """
        groups: Dict[str, List[Dict]] = defaultdict(list)
        for r in rows:
            key = (r.get("food_name") or "").strip().lower()
            if key:
                groups[key].append(r)

        out: List[Dict] = []
        for name_key, items in groups.items():
            mergeable_g, leftover = [], []
            for it in items:
                grams = it.get("amount_grams")
                if grams is None and it.get("amount") and it.get("unit"):
                    try:
                        grams = _weight_unit_to_grams(float(it["amount"]), str(it["unit"]))
                    except Exception:
                        grams = None
                if grams:
                    mergeable_g.append((grams, it))
                else:
                    leftover.append(it)
            display_name = items[0]["food_name"]
            source_recipe_ids = list({i["recipe_id"] for i in items})
            if mergeable_g:
                total_g = sum(g for g, _ in mergeable_g)
                out.append({
                    "ingredient_name": display_name,
                    "quantity": round(total_g, 1),
                    "unit": "g",
                    "source_recipe_ids": source_recipe_ids,
                })
            for it in leftover:
                out.append({
                    "ingredient_name": display_name,
                    "quantity": float(it.get("amount") or 0),
                    "unit": it.get("unit") or "",
                    "notes": "Could not convert unit — kept separate",
                    "source_recipe_ids": [it["recipe_id"]],
                })
        out.sort(key=lambda x: x["ingredient_name"].lower())
        return out

    async def _user_staples(self, user_id: str) -> set:
        try:
            res = (
                self.db.client.table("user_grocery_staples")
                .select("ingredient_name").eq("user_id", user_id).execute()
            )
            return {(r["ingredient_name"] or "").lower() for r in (res.data or [])}
        except Exception:
            return set()

    async def _classify_aisle(self, ingredient_name: str) -> Optional[Aisle]:
        key = ingredient_name.strip().lower()
        if not key:
            return None
        if key in self._aisle_cache:
            return self._aisle_cache[key]
        # Cheap heuristic first
        guess = self._guess_aisle(key)
        if guess:
            self._aisle_cache[key] = guess
            return guess
        # LLM fallback (single word answer)
        try:
            raw = await gemini_text(
                "Classify this grocery item into ONE aisle from the list:\n"
                "produce, dairy, meat_seafood, pantry, frozen, bakery, beverages, "
                "condiments, spices, snacks, household, other.\n"
                f"Item: {ingredient_name}\n"
                "Reply with only the aisle name.",
                temperature=0.0,
                method_name="grocery_aisle_classify",
            )
            choice = re.sub(r"[^a-z_]", "", (raw or "").strip().lower())
            aisle = Aisle(choice) if choice in {a.value for a in Aisle} else Aisle.OTHER
        except Exception:
            aisle = Aisle.OTHER
        self._aisle_cache[key] = aisle
        return aisle

    def _guess_aisle(self, key: str) -> Optional[Aisle]:
        # Simple heuristics so we don't burn LLM cost on common items
        produce = ("apple", "banana", "tomato", "onion", "garlic", "potato", "lettuce",
                   "spinach", "kale", "carrot", "cucumber", "pepper", "broccoli", "lemon", "lime")
        meat = ("chicken", "beef", "pork", "salmon", "tuna", "shrimp", "lamb", "turkey")
        dairy = ("milk", "yogurt", "cheese", "butter", "cream", "egg")
        pantry = ("rice", "pasta", "flour", "oil", "sugar", "lentil", "bean", "oat")
        spices = ("salt", "pepper", "cumin", "paprika", "turmeric", "chili", "cinnamon")
        bakery = ("bread", "tortilla", "bun", "bagel")
        beverages = ("juice", "soda", "coffee", "tea", "water")
        for kw in produce:
            if kw in key: return Aisle.PRODUCE
        for kw in meat:
            if kw in key: return Aisle.MEAT_SEAFOOD
        for kw in dairy:
            if kw in key: return Aisle.DAIRY
        for kw in spices:
            if kw in key: return Aisle.SPICES
        for kw in pantry:
            if kw in key: return Aisle.PANTRY
        for kw in bakery:
            if kw in key: return Aisle.BAKERY
        for kw in beverages:
            if kw in key: return Aisle.BEVERAGES
        return None


_singleton: Optional[GroceryListService] = None


def get_grocery_service() -> GroceryListService:
    global _singleton
    if _singleton is None:
        _singleton = GroceryListService()
    return _singleton
