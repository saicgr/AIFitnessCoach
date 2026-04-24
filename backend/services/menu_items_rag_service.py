"""Menu Items RAG service — per-user parsed menu dishes indexed for
cross-menu semantic similarity recall.

Why this collection exists separately from `saved_foods`:
- `saved_foods` holds meals the user explicitly built or saved; entries
  are authored and durable.
- `menu_items` holds every dish Gemini parsed out of any menu the user
  has scanned. Entries are auto-generated, high-volume, and tagged with
  a `liked` flag that flips true when the user logs that dish. The
  recommendation pipeline queries this collection to seed the
  `favoriteMatch` + `historyAffinity` signals with true semantic
  similarity (so "Chicken Tikka" ≈ "Tandoori Chicken" without a
  hand-built lexicon).

Embedding text: "{dish_name} | {cuisine} | {protein_source} | {preparation}"
so semantic nearness prefers cuisine + protein match, not just name tokens.

Best-effort: every public method catches its own exceptions and logs
rather than raising, because menu analysis MUST NOT fail just because
ChromaDB is briefly unavailable.
"""
from __future__ import annotations

import uuid
from typing import Any, Dict, List, Optional

from core.chroma_cloud import ChromaCloudClient
from core.logger import get_logger
from services.gemini_service import GeminiService

logger = get_logger(__name__)


_PROTEIN_KEYWORDS = {
    "chicken", "beef", "pork", "lamb", "turkey", "shrimp", "prawn",
    "fish", "salmon", "tuna", "tilapia", "cod", "crab", "lobster",
    "tofu", "paneer", "chickpea", "chickpeas", "lentil", "lentils",
    "dal", "egg", "eggs", "bean", "beans", "mutton", "duck", "bacon",
}


_PREP_KEYWORDS = {
    "grilled", "fried", "baked", "roasted", "steamed", "boiled",
    "sauteed", "broiled", "braised", "tandoori", "curry", "stew",
    "soup", "salad", "wrap", "burrito", "taco", "pizza", "pasta",
    "sandwich", "burger", "bowl", "stirfry", "stir-fry", "kabab",
    "kebab", "biryani", "tikka",
}


_CUISINE_KEYWORDS = {
    "indian": {"curry", "masala", "tikka", "biryani", "naan", "paneer", "dal", "tandoori", "samosa", "chutney"},
    "italian": {"pasta", "pizza", "risotto", "lasagna", "gnocchi", "parmesan", "marinara"},
    "mexican": {"taco", "burrito", "quesadilla", "enchilada", "salsa", "guacamole", "nachos"},
    "thai": {"pad thai", "tom yum", "green curry", "red curry", "satay"},
    "chinese": {"kung pao", "sweet and sour", "lo mein", "chow mein", "fried rice", "dumpling", "wonton"},
    "japanese": {"sushi", "ramen", "udon", "teriyaki", "tempura", "sashimi", "donburi"},
    "mediterranean": {"hummus", "falafel", "shawarma", "tzatziki", "gyro", "tabbouleh"},
    "american": {"burger", "steak", "wings", "fries", "bbq", "mac and cheese"},
}


def _infer_cuisine(name: str) -> Optional[str]:
    lowered = name.lower()
    for cuisine, markers in _CUISINE_KEYWORDS.items():
        for m in markers:
            if m in lowered:
                return cuisine
    return None


def _infer_protein(name: str) -> Optional[str]:
    lowered = name.lower()
    for p in _PROTEIN_KEYWORDS:
        if p in lowered:
            return p
    return None


def _infer_prep(name: str) -> Optional[str]:
    lowered = name.lower()
    for p in _PREP_KEYWORDS:
        if p in lowered:
            return p
    return None


def _build_embedding_text(name: str) -> str:
    """Compose the embedding content string. Adding the inferred facets
    explicitly (rather than relying solely on name) means Gemini's
    embedding space lines up items by cuisine + protein + prep, not
    just by literal word overlap."""
    cuisine = _infer_cuisine(name) or "unknown"
    protein = _infer_protein(name) or "unknown"
    prep = _infer_prep(name) or "unknown"
    return f"{name} | cuisine:{cuisine} | protein:{protein} | prep:{prep}"


class MenuItemsRAGService:
    """Upsert/query handler for the `menu_items` Chroma collection."""

    def __init__(self, gemini_service: Optional[GeminiService] = None):
        self.gemini = gemini_service or GeminiService()
        self.chroma = ChromaCloudClient()
        self.collection = self.chroma.get_menu_items_collection()
        try:
            count = self.collection.count()
        except Exception as exc:
            logger.warning(f"[menu_items] count failed: {exc}", exc_info=True)
            count = "unknown"
        logger.info(f"MenuItemsRAG initialized with {count} documents")

    # ───────────────── Upsert ─────────────────

    async def upsert_dishes(
        self,
        *,
        menu_analysis_id: str,
        user_id: str,
        restaurant_name: Optional[str],
        food_items: List[Dict[str, Any]],
    ) -> int:
        """Add every dish from a newly-saved menu analysis. Deduplication
        relies on a stable id derived from (user, menu, dish) so the
        same menu being re-saved just overwrites its old entries.

        Returns the number of items upserted.
        """
        if not food_items:
            return 0

        ids: List[str] = []
        embeddings: List[List[float]] = []
        documents: List[str] = []
        metadatas: List[Dict[str, Any]] = []

        for idx, dish in enumerate(food_items):
            name = (dish.get("name") or "").strip()
            if not name:
                continue
            dish_id = f"{user_id}:{menu_analysis_id}:{idx}"
            doc = _build_embedding_text(name)
            try:
                embedding = await self.gemini.get_embedding_async(doc)
            except Exception as exc:
                logger.warning(f"[menu_items] embed failed for {name!r}: {exc}")
                continue

            meta: Dict[str, Any] = {
                "user_id": user_id,
                "menu_analysis_id": menu_analysis_id,
                "restaurant_name": restaurant_name or "",
                "dish_name": name,
                "section": dish.get("section") or "uncategorized",
                "calories": float(dish.get("calories") or 0),
                "protein_g": float(dish.get("protein_g") or 0),
                "carbs_g": float(dish.get("carbs_g") or 0),
                "fat_g": float(dish.get("fat_g") or 0),
                "inflammation_score": int(dish.get("inflammation_score") or 5),
                "rating": dish.get("rating") or "",
                "liked": False,  # flipped true on mark_liked
            }
            allergens = dish.get("detected_allergens") or []
            if isinstance(allergens, list):
                meta["detected_allergens"] = ",".join(str(a) for a in allergens)

            ids.append(dish_id)
            embeddings.append(embedding)
            documents.append(doc)
            metadatas.append(meta)

        if not ids:
            return 0

        try:
            # Upsert semantics: `add` with duplicate ids would raise; use
            # `upsert` if the client exposes it, else delete-then-add.
            if hasattr(self.collection, "upsert"):
                self.collection.upsert(
                    ids=ids,
                    embeddings=embeddings,
                    documents=documents,
                    metadatas=metadatas,
                )
            else:
                try:
                    self.collection.delete(ids=ids)
                except Exception:
                    pass
                self.collection.add(
                    ids=ids,
                    embeddings=embeddings,
                    documents=documents,
                    metadatas=metadatas,
                )
        except Exception as exc:
            logger.warning(f"[menu_items] upsert failed: {exc}", exc_info=True)
            return 0

        logger.info(f"[menu_items] upserted {len(ids)} dishes for user={user_id}")
        return len(ids)

    # ───────────────── Liked marker ─────────────────

    async def mark_liked(
        self,
        *,
        user_id: str,
        dish_name: str,
    ) -> int:
        """Flip `liked=true` on all menu_items matching dish_name for
        this user. Called from the log-selected-items flow so the
        favorite signal in the recommendation pipeline learns from the
        user's actual menu choices, not just saved foods."""
        try:
            # Chroma where filter — approximate name match via $eq.
            # A more fuzzy approach would need a separate lookup step.
            hits = self.collection.get(
                where={"$and": [
                    {"user_id": {"$eq": user_id}},
                    {"dish_name": {"$eq": dish_name}},
                ]},
                include=["metadatas"],
            )
        except Exception as exc:
            logger.warning(f"[menu_items] mark_liked lookup failed: {exc}", exc_info=True)
            return 0

        ids = hits.get("ids") or []
        metas = hits.get("metadatas") or []
        if not ids:
            return 0

        new_metas: List[Dict[str, Any]] = []
        for meta in metas:
            m = dict(meta or {})
            m["liked"] = True
            new_metas.append(m)

        try:
            self.collection.update(ids=ids, metadatas=new_metas)
        except Exception as exc:
            logger.warning(f"[menu_items] mark_liked update failed: {exc}", exc_info=True)
            return 0

        return len(ids)

    # ───────────────── Query ─────────────────

    async def query_similar(
        self,
        *,
        query: str,
        user_id: str,
        k: int = 10,
        liked_only: bool = True,
    ) -> List[Dict[str, Any]]:
        """Return dishes semantically similar to `query` from this
        user's menu_items collection. Caller owns score-thresholding;
        this method returns everything Chroma retrieves."""
        try:
            embedding = await self.gemini.get_embedding_async(_build_embedding_text(query))
        except Exception as exc:
            logger.warning(f"[menu_items] query embed failed: {exc}", exc_info=True)
            return []

        where: Dict[str, Any] = {"user_id": {"$eq": user_id}}
        if liked_only:
            where = {"$and": [where, {"liked": {"$eq": True}}]}

        try:
            results = self.collection.query(
                query_embeddings=[embedding],
                n_results=k,
                where=where,
                include=["metadatas", "distances"],
            )
        except Exception as exc:
            logger.warning(f"[menu_items] query failed: {exc}", exc_info=True)
            return []

        ids = (results.get("ids") or [[]])[0]
        metas = (results.get("metadatas") or [[]])[0]
        dists = (results.get("distances") or [[]])[0]
        out: List[Dict[str, Any]] = []
        for i, meta in enumerate(metas):
            if not meta:
                continue
            # Chroma returns squared cosine distance ∈ [0, 2]; cosine
            # similarity = 1 - distance/2 (approximately). Clamp to [0,1].
            dist = dists[i] if i < len(dists) else 0.0
            cosine = max(0.0, min(1.0, 1.0 - float(dist) / 2.0))
            out.append({
                "dish_name": meta.get("dish_name", ""),
                "restaurant_name": meta.get("restaurant_name") or None,
                "cosine": round(cosine, 4),
                "liked": bool(meta.get("liked", False)),
                "menu_analysis_id": meta.get("menu_analysis_id"),
                "calories": meta.get("calories"),
                "protein_g": meta.get("protein_g"),
            })
        return out


# Module-level singleton so callers can share the same Chroma client.
_singleton: Optional[MenuItemsRAGService] = None


def get_menu_items_rag() -> MenuItemsRAGService:
    global _singleton
    if _singleton is None:
        _singleton = MenuItemsRAGService()
    return _singleton
