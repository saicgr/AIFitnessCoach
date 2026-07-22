"""Helper functions extracted from nutrition_db.
Nutrition database operations.

Handles all nutrition-related CRUD operations including:
- Food log management
- Daily and weekly nutrition summaries
- User nutrition targets
- Food analysis caching (for faster AI responses)


"""
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta
import logging
from core.db.base import BaseDB, is_uuid
from core.db.nutrition_db_helpers_part2 import NutritionDBPart2

logger = logging.getLogger(__name__)

# Allowlist enforced by the DB CHECK constraint `food_logs_source_type_check`
# (migration 1960_food_logs_source_input_normalization.sql). Any value outside
# this set makes the INSERT 500. The frozenset is the single source of truth for
# the write-guard in create_food_log — keep it in sync with the migration.
_FOOD_LOG_SOURCE_TYPES = frozenset({
    "text", "image", "barcode", "restaurant",
    "menu", "buffet", "watch", "history", "manual",
    # Internal provenances added in migration 2272 (scheduled meal-log worker +
    # meal-plan service write these directly; preserved, not normalized away).
    "scheduled_log", "meal_plan",
})
# Where to map an out-of-allowlist value. 'history' is the closest bucket for
# re-logs/copies of a prior entry (the most common offender, e.g. 'recent').
_FOOD_LOG_SOURCE_TYPE_FALLBACK = "history"

# food_logs_input_type_check (migration 1960, extended by 2319 with
# 'bill_scan'). Same failure mode as source_type: one out-of-allowlist value
# 500s the whole insert, so it gets the same normalize-at-the-chokepoint
# treatment rather than trusting every call site.
_FOOD_LOG_INPUT_TYPES = frozenset({
    "text", "voice", "camera", "gallery", "barcode",
    "menu_scan", "buffet_scan", "bill_scan", "multi_image_scan",
    "chat", "ai_suggestion", "manual", "image", "copy", "watch",
})
_FOOD_LOG_INPUT_TYPE_FALLBACK = "manual"


class NutritionDB(NutritionDBPart2, BaseDB):
    """
    Database operations for nutrition tracking.

    Handles food logs, nutrition summaries, and user dietary targets.
    """

    # ==================== FOOD LOGS ====================

    def create_food_log(
        self,
        user_id: str,
        meal_type: str,
        food_items: list,
        total_calories: int,
        protein_g: float,
        carbs_g: float,
        fat_g: float,
        fiber_g: float = 0,
        ai_feedback: Optional[str] = None,
        health_score: Optional[int] = None,
        logged_at: Optional[str] = None,
        # Client-generated double-log guard (migration 2245). When supplied,
        # a unique (user_id, idempotency_key) index makes the insert idempotent:
        # a replayed POST returns the already-created row instead of duplicating.
        idempotency_key: Optional[str] = None,
        # Micronutrients
        sodium_mg: Optional[float] = None,
        sugar_g: Optional[float] = None,
        saturated_fat_g: Optional[float] = None,
        cholesterol_mg: Optional[float] = None,
        potassium_mg: Optional[float] = None,
        vitamin_a_ug: Optional[float] = None,
        vitamin_c_mg: Optional[float] = None,
        vitamin_d_iu: Optional[float] = None,
        vitamin_e_mg: Optional[float] = None,
        vitamin_k_ug: Optional[float] = None,
        vitamin_b1_mg: Optional[float] = None,
        vitamin_b2_mg: Optional[float] = None,
        vitamin_b3_mg: Optional[float] = None,
        vitamin_b5_mg: Optional[float] = None,
        vitamin_b6_mg: Optional[float] = None,
        vitamin_b7_ug: Optional[float] = None,
        vitamin_b9_ug: Optional[float] = None,
        vitamin_b12_ug: Optional[float] = None,
        calcium_mg: Optional[float] = None,
        iron_mg: Optional[float] = None,
        magnesium_mg: Optional[float] = None,
        zinc_mg: Optional[float] = None,
        phosphorus_mg: Optional[float] = None,
        copper_mg: Optional[float] = None,
        manganese_mg: Optional[float] = None,
        selenium_ug: Optional[float] = None,
        iodine_ug: Optional[float] = None,
        choline_mg: Optional[float] = None,
        omega3_g: Optional[float] = None,
        omega6_g: Optional[float] = None,
        # Gap 7 — opt-in tracker inputs. caffeine_mg + alcohol_g were previously
        # un-persistable (no column param); added so the caffeine/alcohol daily
        # trackers have a real data source on every log path.
        caffeine_mg: Optional[float] = None,
        alcohol_g: Optional[float] = None,
        # Image storage fields
        image_url: Optional[str] = None,
        image_storage_key: Optional[str] = None,
        source_type: str = "text",
        # Specific input method used to create this log. Populated by every
        # write path so analytics can distinguish voice / camera / gallery /
        # menu_scan / buffet_scan / multi_image_scan / chat / ai_suggestion /
        # barcode / manual / watch. Schema CHECK constraint enforces allowlist.
        input_type: Optional[str] = None,
        user_query: Optional[str] = None,
        # Free-text note attached to the log. Menu scans put the dish's printed
        # menu description here (or whatever the user typed over it) so the row
        # still says what the dish actually was months later.
        notes: Optional[str] = None,
        # Inflammation / ultra-processed tracking
        inflammation_score: Optional[int] = None,
        is_ultra_processed: Optional[bool] = None,
        # Diabetes + FODMAP health-condition scoring (migration 1977)
        glycemic_load: Optional[int] = None,
        fodmap_rating: Optional[str] = None,
        fodmap_reason: Optional[str] = None,
        # Structured inflammation drivers + added-sugar (migration 1978).
        # inflammation_triggers is a short array of tags like
        # ['deep_fried', 'refined_flour']; added_sugar_g is grams per serving.
        inflammation_triggers: Optional[List[str]] = None,
        added_sugar_g: Optional[float] = None,
        # Health score reasons (migration 2061). Tags emitted by Gemini
        # explaining WHY this meal earned its health_score.
        health_score_reasons: Optional[List[str]] = None,
        # Passive mood inference (rules_v1). Null when no rule matched or
        # confidence was below the persistence threshold.
        mood_after_inferred: Optional[str] = None,
        energy_level_inferred: Optional[int] = None,
        inference_confidence: Optional[float] = None,
        inference_source: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a food log entry from AI analysis.

        Args:
            user_id: User's UUID
            meal_type: Type of meal (breakfast, lunch, dinner, snack)
            food_items: List of food items consumed
            total_calories: Total calories in the meal
            protein_g: Grams of protein
            carbs_g: Grams of carbohydrates
            fat_g: Grams of fat
            fiber_g: Grams of fiber
            ai_feedback: AI-generated feedback on the meal
            health_score: Health score (0-100)
            + micronutrients: vitamins, minerals, etc.
            image_url: S3 URL of the food image (for image-based logs)
            image_storage_key: S3 storage key for the image
            source_type: 'text' or 'image' indicating how the food was logged

        Returns:
            Created food log record or None
        """
        # Write-guard: the DB CHECK constraint food_logs_source_type_check only
        # permits the values in _FOOD_LOG_SOURCE_TYPES. A caller passing anything
        # else (e.g. the frontend's "recent" re-log bucket) would 500 the insert.
        # Normalize at this single chokepoint so no caller can ever violate it,
        # and log a warning (fail-open + observability) naming the bad value.
        normalized_source_type = (source_type or "").lower()
        if normalized_source_type not in _FOOD_LOG_SOURCE_TYPES:
            logger.warning(
                "[NutritionDB] Invalid food_logs.source_type=%r "
                "(user_id=%s); normalizing to %r to satisfy "
                "food_logs_source_type_check",
                source_type, user_id, _FOOD_LOG_SOURCE_TYPE_FALLBACK,
            )
            normalized_source_type = _FOOD_LOG_SOURCE_TYPE_FALLBACK

        data = {
            "user_id": user_id,
            "meal_type": meal_type,
            "food_items": food_items,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "ai_feedback": ai_feedback,
            "health_score": health_score,
            "source_type": normalized_source_type,
        }
        if idempotency_key:
            data["idempotency_key"] = idempotency_key
        if input_type:
            # Normalize to lowercase to match CHECK constraint allowlist, and
            # bucket anything outside it rather than letting one bad value 500
            # the insert (same guard source_type has had since 2272).
            normalized_input_type = input_type.lower()
            if normalized_input_type not in _FOOD_LOG_INPUT_TYPES:
                logger.warning(
                    "[NutritionDB] Invalid food_logs.input_type=%r "
                    "(user_id=%s); normalizing to %r to satisfy "
                    "food_logs_input_type_check",
                    input_type, user_id, _FOOD_LOG_INPUT_TYPE_FALLBACK,
                )
                normalized_input_type = _FOOD_LOG_INPUT_TYPE_FALLBACK
            data["input_type"] = normalized_input_type

        # Set explicit logged_at timestamp if provided (timezone-aware)
        if logged_at:
            data["logged_at"] = logged_at

        # Add image fields if provided
        if image_url:
            data["image_url"] = image_url
        if image_storage_key:
            data["image_storage_key"] = image_storage_key
        # Capture originating user input (search query, chat message, caption, etc.)
        if user_query:
            data["user_query"] = user_query
        if notes and notes.strip():
            data["notes"] = notes.strip()

        # Add inflammation / ultra-processed fields if provided
        if inflammation_score is not None:
            data["inflammation_score"] = inflammation_score
        if is_ultra_processed is not None:
            data["is_ultra_processed"] = is_ultra_processed

        # Diabetes + FODMAP (migration 1977). Guarded so older code paths
        # that don't populate these still work.
        if glycemic_load is not None:
            data["glycemic_load"] = glycemic_load
        if fodmap_rating is not None:
            data["fodmap_rating"] = fodmap_rating
        if fodmap_reason is not None:
            data["fodmap_reason"] = fodmap_reason

        # Inflammation triggers + added sugar (migration 1978). Triggers ride
        # alongside inflammation_score so the Score Explain sheet can render
        # "why" chips without a second query; added sugar is surfaced on its
        # own health pill and powers WHO daily-limit comparisons.
        if inflammation_triggers is not None:
            data["inflammation_triggers"] = inflammation_triggers
        if added_sugar_g is not None:
            data["added_sugar_g"] = added_sugar_g
        if health_score_reasons is not None:
            data["health_score_reasons"] = health_score_reasons

        # Passive mood inference columns
        if mood_after_inferred is not None:
            data["mood_after_inferred"] = mood_after_inferred
        if energy_level_inferred is not None:
            data["energy_level_inferred"] = energy_level_inferred
        if inference_confidence is not None:
            data["inference_confidence"] = inference_confidence
        if inference_source is not None:
            data["inference_source"] = inference_source

        # Add micronutrients if provided (only include non-None values)
        micronutrients = {
            "sodium_mg": sodium_mg,
            "sugar_g": sugar_g,
            "saturated_fat_g": saturated_fat_g,
            "cholesterol_mg": cholesterol_mg,
            "potassium_mg": potassium_mg,
            "vitamin_a_ug": vitamin_a_ug,
            "vitamin_c_mg": vitamin_c_mg,
            "vitamin_d_iu": vitamin_d_iu,
            "vitamin_e_mg": vitamin_e_mg,
            "vitamin_k_ug": vitamin_k_ug,
            "vitamin_b1_mg": vitamin_b1_mg,
            "vitamin_b2_mg": vitamin_b2_mg,
            "vitamin_b3_mg": vitamin_b3_mg,
            "vitamin_b5_mg": vitamin_b5_mg,
            "vitamin_b6_mg": vitamin_b6_mg,
            "vitamin_b7_ug": vitamin_b7_ug,
            "vitamin_b9_ug": vitamin_b9_ug,
            "vitamin_b12_ug": vitamin_b12_ug,
            "calcium_mg": calcium_mg,
            "iron_mg": iron_mg,
            "magnesium_mg": magnesium_mg,
            "zinc_mg": zinc_mg,
            "phosphorus_mg": phosphorus_mg,
            "copper_mg": copper_mg,
            "manganese_mg": manganese_mg,
            "selenium_ug": selenium_ug,
            "iodine_ug": iodine_ug,
            "choline_mg": choline_mg,
            "omega3_g": omega3_g,
            "omega6_g": omega6_g,
            "caffeine_mg": caffeine_mg,
            "alcohol_g": alcohol_g,
        }

        # Only add non-None micronutrients to data
        for key, value in micronutrients.items():
            if value is not None:
                data[key] = value

        try:
            result = self.client.table("food_logs").insert(data).execute()
            return result.data[0] if result.data else None
        except Exception as insert_err:
            # Idempotency: a replayed POST (double-tap, offline-queue replay, or
            # a 401-refresh Dio retry) hits the unique (user_id, idempotency_key)
            # index from migration 2245. Treat the duplicate as success and
            # return the row that already exists so the caller's optimistic UI
            # reconciles to one log instead of erroring or duplicating.
            err_text = str(insert_err).lower()
            is_dupe = idempotency_key and (
                "duplicate key" in err_text
                or "unique" in err_text
                or "23505" in err_text
                or "uq_food_logs_user_idempotency_key" in err_text
            )
            if is_dupe:
                existing = (
                    self.client.table("food_logs")
                    .select("*")
                    .eq("user_id", user_id)
                    .eq("idempotency_key", idempotency_key)
                    .is_("deleted_at", "null")
                    .limit(1)
                    .execute()
                )
                if existing.data:
                    return existing.data[0]
            # Not a handled duplicate — re-raise so the real failure surfaces.
            raise

    def get_food_log(self, log_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a food log by ID.

        Args:
            log_id: Food log UUID

        Returns:
            Food log record or None (including when log_id isn't a UUID at all)
        """
        # food_logs.id is uuid — handing Postgres a non-UUID raises 22P02
        # ("invalid input syntax for type uuid") which surfaces as a 500, not a
        # 404. The app's optimistic-write path mints synthetic ids like
        # `optimistic_1784685004510300_2` and can delete a row before its write
        # confirms, so a non-UUID here means "no such row" — return None and let
        # callers 404 normally. Guarding at this chokepoint covers every caller.
        if not is_uuid(log_id):
            logger.info(f"get_food_log: non-UUID id {log_id!r} — treating as not found")
            return None
        result = self.client.table("food_logs").select("*").eq("id", log_id).is_("deleted_at", "null").execute()
        return result.data[0] if result.data else None

    def list_food_logs(
        self,
        user_id: str,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
        meal_type: Optional[str] = None,
        limit: int = 50,
    ) -> List[Dict[str, Any]]:
        """
        List food logs for a user with optional filters.

        Args:
            user_id: User's UUID
            from_date: Filter from date
            to_date: Filter to date
            meal_type: Filter by meal type
            limit: Maximum records to return

        Returns:
            List of food log records
        """
        query = self.client.table("food_logs").select(
            "*"
        ).eq("user_id", user_id).is_("deleted_at", "null")

        if from_date:
            query = query.gte("logged_at", from_date)
        if to_date:
            query = query.lte("logged_at", to_date)
        if meal_type:
            query = query.eq("meal_type", meal_type)

        result = query.order("logged_at", desc=True).limit(limit).execute()
        return result.data or []

    def update_food_log(
        self,
        log_id: str,
        user_id: str,
        total_calories: Optional[int] = None,
        protein_g: Optional[float] = None,
        carbs_g: Optional[float] = None,
        fat_g: Optional[float] = None,
        fiber_g: Optional[float] = None,
        weight_g: Optional[float] = None,
        meal_type: Optional[str] = None,
        logged_at: Optional[str] = None,
        notes: Optional[str] = None,
        food_items: Optional[list] = None,
        tags: Optional[list] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Update fields on an existing food log. All fields are optional
        to support partial updates (e.g. move-only, time-only, notes-only).

        Args:
            log_id: Food log UUID
            user_id: Owner's UUID (for authorization check)
            total_calories: Updated calorie total
            protein_g: Updated protein grams
            carbs_g: Updated carb grams
            fat_g: Updated fat grams
            fiber_g: Updated fiber grams
            weight_g: Accepted for API compatibility. NOT a food_logs column —
                per-item weight lives inside food_items (see note below).
            meal_type: Updated meal type (for move between meals)
            logged_at: Updated timestamp (for time edits)
            notes: Updated notes text
            food_items: Updated food items JSONB

        Returns:
            Updated food log record, or None if not found / not owned
        """
        update_data: Dict[str, Any] = {
            "updated_at": datetime.utcnow().isoformat(),
        }
        if total_calories is not None:
            update_data["total_calories"] = total_calories
        if protein_g is not None:
            update_data["protein_g"] = protein_g
        if carbs_g is not None:
            update_data["carbs_g"] = carbs_g
        if fat_g is not None:
            update_data["fat_g"] = fat_g
        if fiber_g is not None:
            update_data["fiber_g"] = fiber_g
        # NOTE: weight_g is deliberately NOT written to the food_logs row.
        # There is no food_logs.weight_g column — weight lives per ITEM inside
        # the food_items JSONB (see FoodItem.weight_g / food_logs.py's
        # `items[i]["weight_g"]` portion math), and the portion-adjust caller
        # that sends weight_g always sends the recomputed `food_items` array in
        # the same request, so the new weight IS persisted there. Writing the
        # phantom key made PostgREST reject the ENTIRE update (42703), losing
        # the calories/macros/meal_type/notes/tags edits alongside it. The
        # parameter stays in the signature so the route + facade contract is
        # unchanged.
        if meal_type is not None:
            update_data["meal_type"] = meal_type
        if logged_at is not None:
            update_data["logged_at"] = logged_at
        if notes is not None:
            update_data["notes"] = notes
        if food_items is not None:
            update_data["food_items"] = food_items
        # Nutrition overhaul — open-vocab food tags (food_logs.tags, mig 2258).
        # An empty list explicitly clears tags; None leaves them untouched.
        if tags is not None:
            update_data["tags"] = tags

        # Only updated_at means nothing to change
        if len(update_data) <= 1:
            return None

        # Same 22P02 trap as get_food_log: the PUT/PATCH routes hand us the raw
        # path param without going through get_food_log first, so an
        # unconfirmed optimistic row's synthetic id reaches food_logs.id (uuid)
        # directly. Editing, moving, retiming or re-noting a meal whose
        # /log-direct write is still in flight would otherwise 500.
        if not is_uuid(log_id):
            logger.info(f"update_food_log: non-UUID id {log_id!r} — treating as not found")
            return None

        result = (
            self.client.table("food_logs")
            .update(update_data)
            .eq("id", log_id)
            .eq("user_id", user_id)
            .is_("deleted_at", "null")
            .execute()
        )
        return result.data[0] if result.data else None

    def insert_food_log_edits(
        self,
        user_id: str,
        food_log_id: str,
        edits: List[Dict[str, Any]],
        edit_source: str,
    ) -> int:
        """
        Bulk-insert audit rows into food_log_edits.

        Each edit dict must carry: food_item_index, food_item_name, edited_field,
        previous_value, updated_value. Optionally food_item_id.

        Returns number of rows inserted.
        """
        if not edits:
            return 0

        rows: List[Dict[str, Any]] = []
        for e in edits:
            try:
                field = e["edited_field"]
                if field not in ("calories", "protein_g", "carbs_g", "fat_g"):
                    logger.warning(f"Skipping edit with invalid field: {field}")
                    continue
                prev = float(e["previous_value"])
                new = float(e["updated_value"])
                if prev == new:
                    continue
                rows.append({
                    "food_log_id": food_log_id,
                    "user_id": user_id,
                    "food_item_index": int(e["food_item_index"]),
                    "food_item_name": str(e["food_item_name"])[:200],
                    "food_item_id": e.get("food_item_id"),
                    "edited_field": field,
                    "previous_value": prev,
                    "updated_value": new,
                    "edit_source": edit_source,
                })
            except (KeyError, ValueError, TypeError) as err:
                logger.warning(f"Skipping malformed edit row: {err}")
                continue

        if not rows:
            return 0

        try:
            result = self.client.table("food_log_edits").insert(rows).execute()
            return len(result.data) if result.data else 0
        except Exception as e:
            logger.error(f"Failed to insert food_log_edits: {e}", exc_info=True)
            return 0

    def list_food_log_edits(
        self,
        user_id: str,
        food_log_id: str,
    ) -> List[Dict[str, Any]]:
        """Return all edit-history rows for a given food log, newest first."""
        # food_log_edits.food_log_id is uuid — an optimistic row has no edit
        # history by definition, so a synthetic id is an empty list, not a 500.
        if not is_uuid(food_log_id):
            logger.info(f"list_food_log_edits: non-UUID id {food_log_id!r} — no history")
            return []
        result = (
            self.client.table("food_log_edits")
            .select("*")
            .eq("food_log_id", food_log_id)
            .eq("user_id", user_id)
            .order("edited_at", desc=True)
            .execute()
        )
        return result.data or []

    # ==================== USER FOOD OVERRIDES ====================
    # Per-user cal/P/C/F corrections that auto-apply to future logs of the
    # same food. Match key priority: food_item_id when present, else
    # food_name_normalized. See migration 1921_user_food_overrides.sql.

    def upsert_user_food_override(
        self,
        user_id: str,
        food_item: Dict[str, Any],
    ) -> Optional[Dict[str, Any]]:
        """
        UPSERT a per-user override from a food_item dict.

        `food_item` is a row from food_logs.food_items[] — expected keys:
        `name`, `calories`, `protein_g`, `carbs_g`, `fat_g`, optionally
        `id` / `food_item_id`, `weight_g`, `count`, `unit`.

        Match key: (user_id, food_item_id) when food_item_id is present;
        otherwise (user_id, food_name_normalized).

        Bumps `edit_count` and `last_edited_at` on conflict.
        Returns the upserted row, or None on error.
        """
        from core.food_naming import normalize_food_name

        name = (food_item.get("name") or "").strip()
        if not name:
            return None

        food_item_id = food_item.get("id") or food_item.get("food_item_id")
        if food_item_id is not None:
            food_item_id = str(food_item_id)
        normalized = normalize_food_name(name)
        if not normalized:
            return None

        def _num(key: str) -> Optional[float]:
            v = food_item.get(key)
            try:
                return float(v) if v is not None else None
            except (TypeError, ValueError):
                return None

        calories = _num("calories")
        if calories is None:
            return None  # calories is required; can't learn from a partial row

        payload: Dict[str, Any] = {
            "user_id": user_id,
            "food_item_id": food_item_id,
            "food_name_normalized": normalized,
            "display_name": name[:200],
            "calories": int(round(calories)),
            "protein_g": _num("protein_g") or 0,
            "carbs_g": _num("carbs_g") or 0,
            "fat_g": _num("fat_g") or 0,
            "reference_weight_g": _num("weight_g"),
            "reference_count": _num("count"),
            "reference_unit": (food_item.get("unit") or None),
            "last_edited_at": datetime.utcnow().isoformat(),
        }

        # Supabase-py doesn't support partial-unique-index upserts via
        # `on_conflict` (it requires a single column or a composite UNIQUE).
        # Emulate UPSERT: SELECT existing row → UPDATE or INSERT.
        try:
            query = self.client.table("user_food_overrides").select("*").eq("user_id", user_id)
            if food_item_id is not None:
                query = query.eq("food_item_id", food_item_id)
            else:
                query = query.is_("food_item_id", "null").eq("food_name_normalized", normalized)
            existing = query.limit(1).execute()

            if existing.data:
                row = existing.data[0]
                payload["edit_count"] = int(row.get("edit_count") or 1) + 1
                result = (
                    self.client.table("user_food_overrides")
                    .update(payload)
                    .eq("id", row["id"])
                    .execute()
                )
            else:
                payload["edit_count"] = 1
                payload["first_edited_at"] = payload["last_edited_at"]
                result = (
                    self.client.table("user_food_overrides")
                    .insert(payload)
                    .execute()
                )
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"Failed to upsert user_food_override: {e}", exc_info=True)
            return None

    def fetch_user_food_overrides_for_items(
        self,
        user_id: str,
        food_items: List[Dict[str, Any]],
    ) -> Dict[str, Dict[str, Any]]:
        """
        Batch-fetch overrides for a list of food items.

        Returns a dict keyed so callers can look up quickly:
          "id:{food_item_id}" → override
          "name:{normalized}" → override

        An item may match both keys if the same food has overrides under
        both an ID-keyed row (historical) and a name-keyed row. Callers
        should prefer ID lookups first.
        """
        from core.food_naming import normalize_food_name

        if not food_items:
            return {}

        ids = {
            str(it["id"] if "id" in it else it["food_item_id"])
            for it in food_items
            if it.get("id") or it.get("food_item_id")
        }
        names = {
            normalize_food_name(it.get("name") or "")
            for it in food_items
            if it.get("name")
        }
        names.discard("")

        lookup: Dict[str, Dict[str, Any]] = {}
        try:
            if ids:
                id_rows = (
                    self.client.table("user_food_overrides")
                    .select("*")
                    .eq("user_id", user_id)
                    .in_("food_item_id", list(ids))
                    .execute()
                )
                for row in (id_rows.data or []):
                    fid = row.get("food_item_id")
                    if fid:
                        lookup[f"id:{fid}"] = row
            if names:
                name_rows = (
                    self.client.table("user_food_overrides")
                    .select("*")
                    .eq("user_id", user_id)
                    .in_("food_name_normalized", list(names))
                    .execute()
                )
                for row in (name_rows.data or []):
                    norm = row.get("food_name_normalized")
                    if norm:
                        lookup[f"name:{norm}"] = row
        except Exception as e:
            logger.error(f"Failed to fetch user_food_overrides: {e}", exc_info=True)
            return {}
        return lookup

    def delete_food_log(self, log_id: str) -> bool:
        """
        Soft-delete a food log entry (SCD2 pattern).

        Sets deleted_at timestamp instead of removing the row.

        Args:
            log_id: Food log UUID

        Returns:
            True on success, False when log_id can't identify a row at all
        """
        # Safe today only because delete_food_log_endpoint calls get_food_log
        # first; guard here too so the helper can't 22P02 if a future caller
        # skips that precheck.
        if not is_uuid(log_id):
            logger.info(f"delete_food_log: non-UUID id {log_id!r} — nothing to delete")
            return False
        self.client.table("food_logs") \
            .update({"deleted_at": datetime.utcnow().isoformat()}) \
            .eq("id", log_id) \
            .execute()
        return True

    def delete_food_logs_by_user(self, user_id: str) -> bool:
        """
        Delete all food logs for a user.

        Args:
            user_id: User's UUID

        Returns:
            True on success
        """
        self.client.table("food_logs").delete().eq("user_id", user_id).execute()
        return True

    # ==================== NUTRITION SUMMARIES ====================

    def get_daily_nutrition_summary(
        self, user_id: str, date: str, timezone_str: str
    ) -> Dict[str, Any]:
        """
        Get nutrition totals for a specific day.

        Args:
            user_id: User's UUID
            date: Date in YYYY-MM-DD format, in the USER'S local calendar
            timezone_str: IANA timezone (e.g. 'America/Los_Angeles'). REQUIRED —
                          `date` is a local calendar day and `logged_at` is a UTC
                          timestamptz, so the boundaries are meaningless without it.

        `timezone_str` used to be optional, falling back to naive
        f"{date}T00:00:00" bounds that Postgres resolved at the session zone
        (UTC). Every caller that omitted it got the previous evening's logs
        attributed to `date` — the same defect that made the coach card report
        3,630 kcal on a 786 kcal day. Callers must pass the tz they already
        resolved; pass "UTC" explicitly if there is genuinely none.

        Returns:
            Dictionary with nutrition totals and meal breakdown
        """
        from core.timezone_utils import local_date_to_utc_range

        # Closed interval: list_food_logs filters with .lte on to_date.
        start_of_day, end_of_day = local_date_to_utc_range(date, timezone_str)

        logs = self.list_food_logs(
            user_id, from_date=start_of_day, to_date=end_of_day, limit=100
        )

        # Daily inflammation aggregate (0-10). Calorie-weighted so a tiny garnish
        # can't swing the day's score; falls back to a simple mean when every
        # scored log has 0 calories. Only logs that actually carry a score count
        # (None means enrichment is still pending — never treated as 0). Mirrors
        # the per-day logic the daily/weekly report endpoints expose, but lands
        # on the core summary so BOTH the daily view and the weekly trend get it
        # without a second query.
        scored = [l for l in logs if l.get("inflammation_score") is not None]
        daily_inflammation: Optional[float] = None
        inflammation_contributors: List[str] = []
        if scored:
            weight = sum((l.get("total_calories") or 0) for l in scored)
            if weight > 0:
                daily_inflammation = round(
                    sum(l["inflammation_score"] * (l.get("total_calories") or 0)
                        for l in scored) / weight,
                    1,
                )
            else:
                daily_inflammation = round(
                    sum(l["inflammation_score"] for l in scored) / len(scored), 1
                )
            # Top contributors: highest-score distinct foods (drives the
            # "what's driving it" copy on the daily meter).
            seen: set = set()
            for l in sorted(scored, key=lambda x: x["inflammation_score"], reverse=True):
                name = l.get("food_name")
                if name and name not in seen:
                    seen.add(name)
                    inflammation_contributors.append(name)
                if len(inflammation_contributors) >= 3:
                    break

        return {
            "date": date,
            "total_calories": sum(log.get("total_calories") or 0 for log in logs),
            "total_protein_g": sum(float(log.get("protein_g") or 0) for log in logs),
            "total_carbs_g": sum(float(log.get("carbs_g") or 0) for log in logs),
            "total_fat_g": sum(float(log.get("fat_g") or 0) for log in logs),
            "total_fiber_g": sum(float(log.get("fiber_g") or 0) for log in logs),
            "inflammation_score": daily_inflammation,
            "inflammation_contributors": inflammation_contributors,
            "meal_count": len(logs),
            "meals": logs,
        }

    def get_weekly_nutrition_summary(
        self, user_id: str, start_date: str, timezone_str: str
    ) -> List[Dict[str, Any]]:
        """
        Get nutrition totals for a week starting from start_date.

        Args:
            user_id: User's UUID
            start_date: Start date in YYYY-MM-DD format (user's local calendar)
            timezone_str: IANA timezone for day-boundary resolution. REQUIRED —
                          it fans out into 7 daily windows, so a missing tz
                          mis-buckets all seven days, not one.

        Returns:
            List of daily nutrition summaries
        """
        start = datetime.fromisoformat(start_date)
        summaries = []

        for i in range(7):
            day = (start + timedelta(days=i)).strftime("%Y-%m-%d")
            summary = self.get_daily_nutrition_summary(user_id, day, timezone_str=timezone_str)
            summaries.append(summary)

        return summaries

    # ==================== USER NUTRITION TARGETS ====================

    def update_user_nutrition_targets(
        self,
        user_id: str,
        daily_calorie_target: Optional[int] = None,
        daily_protein_target_g: Optional[float] = None,
        daily_carbs_target_g: Optional[float] = None,
        daily_fat_target_g: Optional[float] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Update user's daily nutrition targets.

        Args:
            user_id: User's UUID
            daily_calorie_target: Daily calorie goal
            daily_protein_target_g: Daily protein goal in grams
            daily_carbs_target_g: Daily carbs goal in grams
            daily_fat_target_g: Daily fat goal in grams

        Returns:
            Updated user record or None
        """
        data = {}
        if daily_calorie_target is not None:
            data["daily_calorie_target"] = daily_calorie_target
        if daily_protein_target_g is not None:
            data["daily_protein_target_g"] = daily_protein_target_g
        if daily_carbs_target_g is not None:
            data["daily_carbs_target_g"] = daily_carbs_target_g
        if daily_fat_target_g is not None:
            data["daily_fat_target_g"] = daily_fat_target_g

        if data:
            result = (
                self.client.table("users").update(data).eq("id", user_id).execute()
            )
            # Sync to nutrition_preferences for consistency
            try:
                prefs_sync = {}
                if daily_calorie_target is not None:
                    prefs_sync["target_calories"] = daily_calorie_target
                if daily_protein_target_g is not None:
                    prefs_sync["target_protein_g"] = daily_protein_target_g
                if daily_carbs_target_g is not None:
                    prefs_sync["target_carbs_g"] = daily_carbs_target_g
                if daily_fat_target_g is not None:
                    prefs_sync["target_fat_g"] = daily_fat_target_g
                if prefs_sync:
                    self.client.table("nutrition_preferences").update(prefs_sync).eq("user_id", user_id).execute()
            except Exception as e:
                logger.warning(f"Failed to sync targets to nutrition_preferences: {e}", exc_info=True)
            return result.data[0] if result.data else None
        return None

    def get_user_nutrition_targets(self, user_id: str) -> Dict[str, Any]:
        """
        Get user's daily nutrition targets.

        First tries nutrition_preferences table (where calculate_nutrition_metrics saves),
        then falls back to users table for legacy data.

        Args:
            user_id: User's UUID

        Returns:
            Dictionary with nutrition targets
        """
        # Default empty response
        empty_response = {
            "daily_calorie_target": None,
            "daily_protein_target_g": None,
            "daily_carbs_target_g": None,
            "daily_fat_target_g": None,
        }

        try:
            # First try nutrition_preferences (where calculated metrics are stored)
            result = (
                self.client.table("nutrition_preferences")
                .select("target_calories, target_protein_g, target_carbs_g, target_fat_g")
                .eq("user_id", user_id)
                .maybe_single()
                .execute()
            )
            if result and result.data:
                prefs = result.data
                return {
                    "daily_calorie_target": prefs.get("target_calories"),
                    "daily_protein_target_g": prefs.get("target_protein_g"),
                    "daily_carbs_target_g": prefs.get("target_carbs_g"),
                    "daily_fat_target_g": prefs.get("target_fat_g"),
                }
        except Exception as e:
            logger.warning(f"Error fetching nutrition_preferences for {user_id}: {e}", exc_info=True)

        try:
            # Fallback to users table for legacy data.
            #
            # This fallback is NOT optional. update_user_nutrition_targets()
            # writes users.daily_*_target as the PRIMARY store and only
            # best-effort-syncs nutrition_preferences inside a try/except. A
            # PostgREST .update() against a user with no nutrition_preferences
            # row matches zero rows and raises NOTHING — so the sync silently
            # no-ops and the targets exist ONLY on users. Reading
            # nutrition_preferences alone then returns all-None and the app
            # falls back to its bogus 2000 kcal default.
            #
            # (Removed by accident in d79ea1a7, a bulk "update" commit, which
            # left the docstring above still promising the fallback.)
            result = (
                self.client.table("users")
                .select(
                    "daily_calorie_target, daily_protein_target_g, "
                    "daily_carbs_target_g, daily_fat_target_g"
                )
                .eq("id", user_id)
                .maybe_single()
                .execute()
            )
            if result and result.data:
                return result.data
        except Exception as e:
            logger.warning(f"Error fetching user nutrition targets for {user_id}: {e}", exc_info=True)

        return empty_response

    def enrich_user_with_nutrition_targets(self, user_dict: dict) -> dict:
        """Overlay nutrition_preferences targets onto user dict.

        Ensures user dict always has the latest targets from nutrition_preferences
        (the source of truth), falling back to whatever is already in user_dict.
        """
        if not user_dict or not user_dict.get("id"):
            return user_dict
        try:
            targets = self.get_user_nutrition_targets(user_dict["id"])
            if targets:
                for col, val in targets.items():
                    if val is not None:
                        user_dict[col] = val
        except Exception as e:
            logger.warning(f"Failed to enrich user nutrition targets: {e}", exc_info=True)
        return user_dict

    # ==================== WEIGHT LOGS ====================

    def create_weight_log(
        self,
        user_id: str,
        weight_kg: float,
        logged_at: Optional[datetime] = None,
        source: str = "manual",
        notes: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """
        Create a weight log entry.

        Args:
            user_id: User's UUID
            weight_kg: Weight in kilograms
            logged_at: When the weight was logged (defaults to now)
            source: Source of the weight log (manual, apple_health, etc.)
            notes: Optional notes

        Returns:
            Created weight log record or None
        """
        data = {
            "user_id": user_id,
            "weight_kg": weight_kg,
            "logged_at": (logged_at or datetime.utcnow()).isoformat(),
            "source": source,
            "notes": notes,
        }
        result = self.client.table("weight_logs").insert(data).execute()
        return result.data[0] if result.data else None

    def get_weight_logs(
        self,
        user_id: str,
        limit: int = 30,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get weight logs for a user.

        Args:
            user_id: User's UUID
            limit: Maximum records to return
            from_date: Filter from date
            to_date: Filter to date

        Returns:
            List of weight log records ordered by date (newest first)
        """
        query = self.client.table("weight_logs").select(
            "id, user_id, weight_kg, logged_at, source, notes"
        ).eq("user_id", user_id)

        if from_date:
            query = query.gte("logged_at", from_date)
        if to_date:
            query = query.lte("logged_at", to_date)

        result = query.order("logged_at", desc=True).limit(limit).execute()
        return result.data or []

    def delete_weight_log(self, log_id: str, user_id: str) -> bool:
        """
        Delete a weight log entry.

        Args:
            log_id: Weight log UUID
            user_id: User's UUID (for verification)

        Returns:
            True if deleted
        """
        result = (
            self.client.table("weight_logs")
            .delete()
            .eq("id", log_id)
            .eq("user_id", user_id)
            .execute()
        )
        return len(result.data or []) > 0

    # ==================== NUTRITION PREFERENCES ====================

    def get_nutrition_preferences(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get nutrition preferences for a user.

        Args:
            user_id: User's UUID

        Returns:
            Nutrition preferences record or None
        """
        result = (
            self.client.table("nutrition_preferences")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        return result.data[0] if result.data else None

    def upsert_nutrition_preferences(
        self, user_id: str, preferences: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Create or update nutrition preferences.

        Args:
            user_id: User's UUID
            preferences: Preferences data

        Returns:
            Created/updated preferences record
        """
        data = {"user_id": user_id, **preferences}
        result = (
            self.client.table("nutrition_preferences")
            .upsert(data, on_conflict="user_id")
            .execute()
        )
        return result.data[0] if result.data else None

    # ==================== NUTRITION STREAKS ====================

