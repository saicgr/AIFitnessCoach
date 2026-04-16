"""
Cook Event Service
==================
Persistence + business logic for recipe_cook_events.

Auto-defaults expires_at from storage kind when not provided
(fridge=+3d, freezer=+30d, counter=+1d).
"""

import logging
import uuid
from datetime import datetime, timedelta
from typing import List, Optional

from core.db import get_supabase_db
from models.cook_event import (
    ActiveCookEvent,
    CookEvent,
    CookEventCreate,
    CookEventUpdate,
    STORAGE_DEFAULT_LIFE_DAYS,
    StorageKind,
)

logger = logging.getLogger(__name__)


class CookEventService:
    def __init__(self):
        self.db = get_supabase_db()

    async def create(self, user_id: str, req: CookEventCreate) -> CookEvent:
        cooked_at = req.cooked_at or datetime.utcnow()
        expires_at = req.expires_at or (
            cooked_at + timedelta(days=STORAGE_DEFAULT_LIFE_DAYS[req.storage])
        )
        portions_remaining = (
            req.portions_remaining if req.portions_remaining is not None else req.portions_made
        )

        ev_id = str(uuid.uuid4())
        now_iso = datetime.utcnow().isoformat()
        row = {
            "id": ev_id,
            "user_id": user_id,
            "recipe_id": req.recipe_id,
            "cooked_at": cooked_at.isoformat(),
            "portions_made": req.portions_made,
            "portions_remaining": portions_remaining,
            "storage": req.storage.value,
            "expires_at": expires_at.isoformat(),
            "notes": req.notes,
            "created_at": now_iso,
            "updated_at": now_iso,
        }
        self.db.client.table("recipe_cook_events").insert(row).execute()
        return CookEvent(**row)

    async def update(self, event_id: str, req: CookEventUpdate) -> Optional[CookEvent]:
        patch = {k: (v.value if hasattr(v, "value") else v)
                 for k, v in req.model_dump(exclude_none=True).items()}
        if not patch:
            return await self.get(event_id)
        # Re-derive expires_at if storage changed and expires_at not explicitly set
        if "storage" in patch and "expires_at" not in patch:
            cur = await self.get(event_id)
            if cur:
                patch["expires_at"] = (
                    cur.cooked_at + timedelta(days=STORAGE_DEFAULT_LIFE_DAYS[StorageKind(patch["storage"])])
                ).isoformat()
        if "expires_at" in patch and isinstance(patch["expires_at"], datetime):
            patch["expires_at"] = patch["expires_at"].isoformat()
        patch["updated_at"] = datetime.utcnow().isoformat()
        self.db.client.table("recipe_cook_events").update(patch).eq("id", event_id).execute()
        return await self.get(event_id)

    async def get(self, event_id: str) -> Optional[CookEvent]:
        res = (
            self.db.client.table("recipe_cook_events").select("*")
            .eq("id", event_id).limit(1).execute()
        )
        return CookEvent(**res.data[0]) if res.data else None

    async def delete(self, event_id: str) -> bool:
        self.db.client.table("recipe_cook_events").delete().eq("id", event_id).execute()
        return True

    async def list_active(self, user_id: str) -> List[ActiveCookEvent]:
        res = (
            self.db.client.table("recipe_cook_events")
            .select("*").eq("user_id", user_id)
            .gt("portions_remaining", 0)
            .order("cooked_at", desc=True).limit(50).execute()
        )
        rows = res.data or []
        recipe_ids = [r["recipe_id"] for r in rows if r.get("recipe_id")]
        recipe_map = {}
        if recipe_ids:
            rec_res = (
                self.db.client.table("user_recipes")
                .select("id,name,image_url").in_("id", recipe_ids).execute()
            )
            recipe_map = {r["id"]: r for r in (rec_res.data or [])}

        now = datetime.utcnow()
        out: List[ActiveCookEvent] = []
        for r in rows:
            try:
                expires = datetime.fromisoformat(r["expires_at"].replace("Z", "+00:00"))
            except Exception:
                expires = now + timedelta(days=3)
            recipe = recipe_map.get(r.get("recipe_id"), {})
            out.append(ActiveCookEvent(
                id=r["id"],
                recipe_id=r.get("recipe_id"),
                recipe_name=recipe.get("name"),
                recipe_image_url=recipe.get("image_url"),
                cooked_at=r["cooked_at"],
                portions_remaining=float(r["portions_remaining"]),
                portions_made=float(r["portions_made"]),
                storage=StorageKind(r["storage"]),
                expires_at=r["expires_at"],
                is_expired=expires.replace(tzinfo=None) < now,
                is_expiring_soon=(expires.replace(tzinfo=None) - now).total_seconds() < 86400,
            ))
        return out


_singleton: Optional[CookEventService] = None


def get_cook_event_service() -> CookEventService:
    global _singleton
    if _singleton is None:
        _singleton = CookEventService()
    return _singleton
