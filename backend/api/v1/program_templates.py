"""
Program Templates API - the multi-day program-template importer (Phase B).

Mounted at /api/v1/program-templates. Surfaces three authoring paths that all
converge on the same editable `user_program_templates` shape:

  1. Import from the `programs` library  (GET /library, POST /from-program/{id})
     -- the FIRST-EVER API over the `programs` Supabase table (259 structured
        programs; 7 with empty `workouts` are filtered out server-side).
  2. Parse a pasted free-text program     (POST /parse)
  3. Author from scratch                   (POST /)

Then schedule a template forward into concrete `workouts` rows
(POST /{id}/schedule) and regenerate the future when it is edited
(POST /{id}/regenerate-future).

Endpoints:
  GET    /library                 browse the programs-table library
  GET    /library/{program_id}    normalized structured preview of one program
  POST   /from-program/{program_id}  clone a programs row into an editable template
  POST   /parse                   Gemini-parse free text -> days JSON (no save)
  POST   /                        create a template from authored JSON
  GET    /user/{user_id}          list a user's templates
  GET    /{template_id}           get one template
  PATCH  /{template_id}           edit a template
  DELETE /{template_id}           delete a template (keeps scheduled workouts)
  POST   /{template_id}/schedule  expand the template into workouts
  POST   /{template_id}/regenerate-future  rebuild uncompleted future workouts
"""
from __future__ import annotations

import logging
import uuid
from datetime import date, datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Body, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.supabase_client import get_supabase

from services.gemini_service import ResponseCache
from services.program_library_importer import normalize_program_blob_for_preview
from services.program_template_parser import parse_to_template_json
from services.program_template_expander import (
    expand_template,
    regenerate_future,
    MAX_WEEKS,
)

logger = get_logger(__name__)
router = APIRouter()

# In-memory TTL cache for the program-library browse result. The `programs`
# library is static/curated reference data, so a long TTL is safe — the only
# writes are bulk re-imports, which restart the process. Keyed by the
# (category, difficulty_level, sessions_per_week, search) filter tuple.
_library_browse_cache = ResponseCache(
    prefix="program_library_browse", ttl_seconds=6 * 3600, max_size=256
)


# =============================================================================
# Request / response models
# =============================================================================
class LibraryProgramCard(BaseModel):
    """Lightweight card for the library browse grid."""
    id: str
    program_name: str
    program_category: Optional[str] = None
    program_subcategory: Optional[str] = None
    celebrity_name: Optional[str] = None
    difficulty_level: Optional[str] = None
    duration_weeks: Optional[int] = None
    sessions_per_week: Optional[int] = None
    session_duration_minutes: Optional[int] = None
    description: Optional[str] = None
    goals: List[str] = Field(default_factory=list)


class LibraryBrowseResponse(BaseModel):
    total: int
    programs: List[LibraryProgramCard]


class TemplateCreateRequest(BaseModel):
    """Authored / reviewed template payload (also used to save a parsed one)."""
    name: str = Field(..., min_length=1)
    description: Optional[str] = None
    week_length: int = Field(default=7, ge=1)
    days: List[Dict[str, Any]] = Field(...)
    deload_every_n_weeks: Optional[int] = 5
    progression_strategy: str = "linear"
    apply_staples: bool = True
    source: str = "authored"
    source_program_id: Optional[str] = None
    category: Optional[str] = None


class TemplatePatchRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    week_length: Optional[int] = Field(default=None, ge=1)
    days: Optional[List[Dict[str, Any]]] = None
    deload_every_n_weeks: Optional[int] = None
    progression_strategy: Optional[str] = None
    apply_staples: Optional[bool] = None
    category: Optional[str] = None


class ParseRequest(BaseModel):
    description: str = Field(..., min_length=1)


class ScheduleRequest(BaseModel):
    start_date: date
    weeks: int = Field(..., ge=1)
    day_alignment: str = Field(default="start_today")
    # {day_index: "HH:MM"} user-local times; missing days default to noon.
    day_times: Dict[str, str] = Field(default_factory=dict)


# =============================================================================
# Helpers
# =============================================================================
# The 7 programs rows with an empty/missing `workouts` blob (plan B.6 X3) are
# filtered out everywhere. We detect emptiness structurally.
def _has_workouts(program_row: Dict[str, Any]) -> bool:
    blob = program_row.get("workouts")
    if isinstance(blob, dict):
        return bool(blob.get("workouts"))
    if isinstance(blob, list):
        return len(blob) > 0
    return False


def _sessions_per_week(program_row: Dict[str, Any]) -> Optional[int]:
    spw = program_row.get("sessions_per_week")
    if spw:
        return int(spw)
    blob = program_row.get("workouts")
    workouts: List[Any] = []
    if isinstance(blob, dict):
        workouts = blob.get("workouts") or []
    elif isinstance(blob, list):
        workouts = blob
    if workouts:
        return sum(1 for w in workouts if (w.get("exercises") or []))
    return None


def _template_row_to_dict(row: Dict[str, Any]) -> Dict[str, Any]:
    """Normalize a user_program_templates DB row for the API response."""
    return {
        "id": str(row["id"]),
        "user_id": str(row["user_id"]),
        "name": row.get("name"),
        "description": row.get("description"),
        "week_length": row.get("week_length", 7),
        "days": row.get("days") or [],
        "deload_every_n_weeks": row.get("deload_every_n_weeks"),
        "progression_strategy": row.get("progression_strategy", "linear"),
        "apply_staples": row.get("apply_staples", True),
        "source": row.get("source", "authored"),
        "source_program_id": (
            str(row["source_program_id"])
            if row.get("source_program_id")
            else None
        ),
        "category": row.get("category"),
        "created_at": row.get("created_at"),
        "updated_at": row.get("updated_at"),
    }


def _require_owner(row: Dict[str, Any], current_user: dict) -> None:
    if str(row.get("user_id")) != str(current_user["id"]):
        raise HTTPException(status_code=403, detail="Access denied")


def _get_template_or_404(db, template_id: str) -> Dict[str, Any]:
    resp = (
        db.client.table("user_program_templates")
        .select("*")
        .eq("id", template_id)
        .limit(1)
        .execute()
    )
    if not resp.data:
        raise HTTPException(status_code=404, detail="Template not found")
    return resp.data[0]


# =============================================================================
# Library - first-ever API over the `programs` table
# =============================================================================
@router.get("/library", response_model=LibraryBrowseResponse)
async def browse_library(
    category: Optional[str] = Query(default=None),
    difficulty_level: Optional[str] = Query(default=None),
    sessions_per_week: Optional[int] = Query(default=None),
    search: Optional[str] = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    """Browse the 259-program `programs` library as lightweight cards.

    Filters: program_category, difficulty_level, sessions_per_week, free-text
    search on program_name. The 7 rows with an empty `workouts` blob are
    excluded server-side via the precomputed `has_workouts` column (migration
    2220) — we no longer fetch the heavy `workouts` JSONB blob just to derive
    that, which is what made this endpoint slow enough to trip the client's
    receiveTimeout. Empty filtered result -> total=0 (#L14).

    Cached (in-memory, long TTL) keyed by the filter tuple, since the library
    is static curated data.
    """
    try:
        # Serve from cache when present — library is static reference data.
        # RedisCache.get/set take a SINGLE string key — build one via make_key
        # (the old `.get(*cache_key)` unpacked a 4-tuple → TypeError 500).
        cache_key = _library_browse_cache.make_key(
            category or "",
            difficulty_level or "",
            sessions_per_week if sessions_per_week is not None else -1,
            (search or "").strip().lower(),
        )
        cached = await _library_browse_cache.get(cache_key)
        # The cache is JSON-backed (Redis): values MUST be plain dicts. A dict
        # round-trips cleanly and FastAPI re-validates it against the response
        # model. Anything else is a poisoned entry from when a pydantic model
        # was cached directly (json.dumps(..., default=str) stringified the whole
        # object → a str came back and 500'd response validation) — ignore it
        # and fall through to a fresh fetch so the cache self-heals.
        if isinstance(cached, dict):
            return cached

        db = get_supabase()
        # Light card columns ONLY — drop the `workouts` blob from the select.
        # has_workouts + sessions_per_week are now precomputed columns.
        query = db.client.table("programs").select(
            "id, program_name, program_category, program_subcategory, "
            "celebrity_name, difficulty_level, duration_weeks, "
            "sessions_per_week, session_duration_minutes, description, "
            "short_description, goals"
        ).eq("has_workouts", True)  # X3 - exclude the 7 empty programs
        # Celebrity programs are no longer surfaced in the library (product
        # decision 2026-06): drop the whole "Celebrity Workout" category.
        query = query.neq("program_category", "Celebrity Workout")
        if category:
            query = query.eq("program_category", category)
        if difficulty_level:
            query = query.eq("difficulty_level", difficulty_level)
        if sessions_per_week is not None:
            query = query.eq("sessions_per_week", sessions_per_week)
        if search:
            query = query.ilike("program_name", f"%{search}%")
        resp = query.execute()

        cards: List[LibraryProgramCard] = []
        for row in resp.data or []:
            cards.append(
                LibraryProgramCard(
                    id=str(row["id"]),
                    program_name=row.get("program_name") or "Program",
                    program_category=row.get("program_category"),
                    program_subcategory=row.get("program_subcategory"),
                    # No celebrity tags anywhere in the library (incl. the few
                    # Sport Training rows that carry a celebrity_name).
                    celebrity_name=None,
                    difficulty_level=row.get("difficulty_level"),
                    duration_weeks=row.get("duration_weeks"),
                    sessions_per_week=row.get("sessions_per_week"),
                    session_duration_minutes=row.get(
                        "session_duration_minutes"
                    ),
                    description=(
                        row.get("short_description")
                        or row.get("description")
                    ),
                    goals=row.get("goals") or [],
                )
            )
        cards.sort(key=lambda c: (c.program_category or "", c.program_name))
        result = LibraryBrowseResponse(total=len(cards), programs=cards)
        # Cache a JSON-serializable dict, NOT the pydantic model: the Redis cache
        # serializes via json.dumps(..., default=str), which would otherwise
        # stringify the whole model and return a useless str on the next hit.
        await _library_browse_cache.set(cache_key, result.model_dump())
        return result
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to browse program library: %s", e, exc_info=True)
        raise safe_internal_error(e, "program_templates")


@router.get("/library/{program_id}")
async def library_program_detail(
    program_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Full structured preview of one `programs` row - the `workouts` JSONB
    normalized into the `days` shape (rep-strings parsed, exercises resolved).
    """
    try:
        db = get_supabase()
        resp = (
            db.client.table("programs")
            .select("*")
            .eq("id", program_id)
            .limit(1)
            .execute()
        )
        if not resp.data:
            raise HTTPException(status_code=404, detail="Program not found")
        program = resp.data[0]
        if not _has_workouts(program):
            # X4 - a metadata-only / empty program is not importable.
            raise HTTPException(
                status_code=422,
                detail="This program has no structured workouts to preview",
            )
        normalized = normalize_program_blob_for_preview(
            program, user_id=str(current_user["id"])
        )
        return {
            "program_id": str(program["id"]),
            "program_name": program.get("program_name"),
            "celebrity_name": program.get("celebrity_name"),
            "difficulty_level": program.get("difficulty_level"),
            "duration_weeks": program.get("duration_weeks"),
            **normalized,
        }
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to load library program %s: %s", program_id, e,
            exc_info=True,
        )
        raise safe_internal_error(e, "program_templates")


@router.post("/from-program/{program_id}")
async def import_from_program(
    program_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Clone a `programs` row into a NEW editable `user_program_templates` row.

    source='library', source_program_id set. The user's copy is an independent
    snapshot - editing it never affects the source or another user's copy
    (#L11/#L12).
    """
    try:
        db = get_supabase()
        resp = (
            db.client.table("programs")
            .select("*")
            .eq("id", program_id)
            .limit(1)
            .execute()
        )
        if not resp.data:
            raise HTTPException(status_code=404, detail="Program not found")
        program = resp.data[0]
        if not _has_workouts(program):
            # X4 - branded_programs / empty programs are not importable.
            raise HTTPException(
                status_code=422,
                detail="This program has no structured workouts to import",
            )

        user_id = str(current_user["id"])
        normalized = normalize_program_blob_for_preview(
            program, user_id=user_id
        )

        now = datetime.utcnow().isoformat()
        insert_row = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "name": normalized["name"],
            "description": normalized.get("description"),
            "week_length": normalized["week_length"],
            "days": normalized["days"],
            "deload_every_n_weeks": normalized["deload_every_n_weeks"],
            "progression_strategy": normalized["progression_strategy"],
            "apply_staples": True,
            "source": "library",
            "source_program_id": program_id,
            "category": normalized.get("category"),
            "created_at": now,
            "updated_at": now,
        }
        created = (
            db.client.table("user_program_templates")
            .insert(insert_row)
            .execute()
        )
        if not created.data:
            raise HTTPException(
                status_code=500, detail="Failed to create template"
            )
        return _template_row_to_dict(created.data[0])
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to import program %s: %s", program_id, e, exc_info=True
        )
        raise safe_internal_error(e, "program_templates")


# =============================================================================
# Parse - free-text -> days JSON (does NOT save)
# =============================================================================
@router.post("/parse")
async def parse_program(
    request: ParseRequest,
    current_user: dict = Depends(get_current_user),
):
    """Gemini-parse a pasted free-text program into the `days` JSON shape for
    user review. Does NOT persist - the client reviews/edits then POSTs to `/`.

    422 'not_a_program' when the text isn't a program (#12);
    422 'parse_error' when Gemini fails twice (#13/#14).
    """
    try:
        parsed = await parse_to_template_json(
            request.description, user_id=str(current_user["id"])
        )
        return parsed
    except ValueError as ve:
        msg = str(ve)
        if msg.startswith("not_a_program"):
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "not_a_program",
                    "message": msg.split(":", 1)[-1].strip()
                    or "This doesn't look like a workout program",
                },
            )
        if msg.startswith("parse_error"):
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "parse_error",
                    "message": "Could not parse the program. Try the manual "
                    "builder.",
                },
            )
        raise HTTPException(status_code=422, detail={"error": "parse_error",
                                                     "message": msg})
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to parse program: %s", e, exc_info=True)
        raise safe_internal_error(e, "program_templates")


# =============================================================================
# CRUD
# =============================================================================
@router.post("")
@router.post("/")
async def create_template(
    request: TemplateCreateRequest,
    current_user: dict = Depends(get_current_user),
):
    """Create a template from authored / reviewed JSON.

    Rejects an all-rest template (Group 2 #19).
    """
    try:
        days = request.days or []
        has_training_day = any(
            not d.get("is_rest") and (d.get("exercises") or [])
            for d in days
        )
        if not has_training_day:
            raise HTTPException(
                status_code=422,
                detail="A program needs at least one training day",
            )

        # progression_strategy='none' implies no deload weeks.
        deload = request.deload_every_n_weeks
        if request.progression_strategy == "none":
            deload = None

        db = get_supabase()
        now = datetime.utcnow().isoformat()
        insert_row = {
            "id": str(uuid.uuid4()),
            "user_id": str(current_user["id"]),
            "name": request.name,
            "description": request.description,
            "week_length": request.week_length,
            "days": days,
            "deload_every_n_weeks": deload,
            "progression_strategy": request.progression_strategy,
            "apply_staples": request.apply_staples,
            "source": request.source or "authored",
            "source_program_id": request.source_program_id,
            "category": request.category,
            "created_at": now,
            "updated_at": now,
        }
        created = (
            db.client.table("user_program_templates")
            .insert(insert_row)
            .execute()
        )
        if not created.data:
            raise HTTPException(
                status_code=500, detail="Failed to create template"
            )
        return _template_row_to_dict(created.data[0])
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to create template: %s", e, exc_info=True)
        raise safe_internal_error(e, "program_templates")


@router.get("/user/{user_id}")
async def list_user_templates(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """List every template owned by the user (most recent first)."""
    if str(current_user["id"]) != str(user_id):
        raise HTTPException(status_code=403, detail="Access denied")
    try:
        db = get_supabase()
        resp = (
            db.client.table("user_program_templates")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        return {
            "templates": [
                _template_row_to_dict(r) for r in resp.data or []
            ]
        }
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to list templates for %s: %s", user_id, e, exc_info=True
        )
        raise safe_internal_error(e, "program_templates")


@router.get("/{template_id}")
async def get_template(
    template_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Get one template by id."""
    try:
        db = get_supabase()
        row = _get_template_or_404(db, template_id)
        _require_owner(row, current_user)
        return _template_row_to_dict(row)
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to get template %s: %s", template_id, e, exc_info=True
        )
        raise safe_internal_error(e, "program_templates")


@router.patch("/{template_id}")
async def patch_template(
    template_id: str,
    request: TemplatePatchRequest,
    current_user: dict = Depends(get_current_user),
):
    """Edit a template. If `days` is provided it must keep >=1 training day."""
    try:
        db = get_supabase()
        row = _get_template_or_404(db, template_id)
        _require_owner(row, current_user)

        updates: Dict[str, Any] = {}
        for field in (
            "name", "description", "week_length", "days",
            "deload_every_n_weeks", "progression_strategy",
            "apply_staples", "category",
        ):
            val = getattr(request, field)
            if val is not None:
                updates[field] = val

        if "days" in updates:
            has_training_day = any(
                not d.get("is_rest") and (d.get("exercises") or [])
                for d in updates["days"]
            )
            if not has_training_day:
                raise HTTPException(
                    status_code=422,
                    detail="A program needs at least one training day",
                )

        if updates.get("progression_strategy") == "none":
            updates["deload_every_n_weeks"] = None

        if not updates:
            return _template_row_to_dict(row)

        updates["updated_at"] = datetime.utcnow().isoformat()
        updated = (
            db.client.table("user_program_templates")
            .update(updates)
            .eq("id", template_id)
            .execute()
        )
        # #59 - cascade a rename onto an active program assignment.
        if "name" in updates:
            try:
                db.client.table("user_program_assignments").update(
                    {"custom_program_name": updates["name"]}
                ).eq("template_id", template_id).eq(
                    "is_active", True
                ).execute()
            except Exception as rename_err:  # noqa: BLE001
                logger.warning(
                    "Assignment rename cascade failed: %s", rename_err
                )
        return _template_row_to_dict(
            updated.data[0] if updated.data else row
        )
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to patch template %s: %s", template_id, e, exc_info=True
        )
        raise safe_internal_error(e, "program_templates")


@router.delete("/{template_id}")
async def delete_template(
    template_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a template. Already-scheduled workouts are KEPT - the FK
    `ON DELETE SET NULL` simply detaches them from the template (#56).
    """
    try:
        db = get_supabase()
        row = _get_template_or_404(db, template_id)
        _require_owner(row, current_user)
        db.client.table("user_program_templates").delete().eq(
            "id", template_id
        ).execute()
        return {
            "success": True,
            "deleted_template_id": template_id,
            "note": "Already-scheduled workouts were kept; they are no "
            "longer linked to a template.",
        }
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to delete template %s: %s", template_id, e, exc_info=True
        )
        raise safe_internal_error(e, "program_templates")


# =============================================================================
# Schedule + regenerate
# =============================================================================
def _resolve_active_gym_profile(db, user_id: str) -> Optional[str]:
    """Return the user's currently-active gym profile id (#36). Best-effort -
    template workouts still expand without one."""
    for table, active_col in (
        ("gym_profiles", "is_active"),
        ("user_gym_profiles", "is_active"),
    ):
        try:
            resp = (
                db.client.table(table)
                .select("id")
                .eq("user_id", user_id)
                .eq(active_col, True)
                .limit(1)
                .execute()
            )
            if resp.data:
                return str(resp.data[0]["id"])
        except Exception:  # noqa: BLE001
            continue
    return None


@router.post("/{template_id}/schedule")
async def schedule_template(
    template_id: str,
    request: ScheduleRequest,
    current_user: dict = Depends(get_current_user),
):
    """Schedule a template forward: persist a `user_program_schedules` row,
    expand into `workouts`, and mark a `user_program_assignments` row active.

    day_times maps day_index -> "HH:MM" user-local; missing days default to
    noon. day_alignment is 'start_today' (default) or 'calendar_weekday'.
    Idempotent: a re-fired call dedupes on the template slot unique index.
    """
    try:
        if request.weeks > MAX_WEEKS:
            raise HTTPException(
                status_code=422,
                detail=f"weeks is capped at {MAX_WEEKS}",
            )
        if request.day_alignment not in ("start_today", "calendar_weekday"):
            raise HTTPException(
                status_code=422,
                detail="day_alignment must be start_today or "
                "calendar_weekday",
            )

        db = get_supabase()
        template = _get_template_or_404(db, template_id)
        _require_owner(template, current_user)
        user_id = str(current_user["id"])

        gym_profile_id = _resolve_active_gym_profile(db, user_id)

        # Persist the schedule row.
        schedule_id = str(uuid.uuid4())
        db.client.table("user_program_schedules").insert(
            {
                "id": schedule_id,
                "template_id": template_id,
                "user_id": user_id,
                "start_date": request.start_date.isoformat(),
                "weeks": request.weeks,
                "day_alignment": request.day_alignment,
                "day_times": request.day_times,
            }
        ).execute()

        # Expand into workouts (transaction-wrapped + idempotent).
        result = expand_template(
            template=template,
            schedule_id=schedule_id,
            user_id=user_id,
            start_date=request.start_date,
            weeks=request.weeks,
            day_alignment=request.day_alignment,
            day_times=request.day_times,
            gym_profile_id=gym_profile_id,
        )

        # Activate this template's program assignment; supersede any other
        # active assignment (#31/#33).
        try:
            db.client.table("user_program_assignments").update(
                {"is_active": False, "status": "superseded"}
            ).eq("user_id", user_id).eq("is_active", True).execute()
            db.client.table("user_program_assignments").insert(
                {
                    "id": str(uuid.uuid4()),
                    "user_id": user_id,
                    "template_id": template_id,
                    "custom_program_name": template.get("name"),
                    "is_active": True,
                    "status": "active",
                    "started_at": datetime.utcnow().isoformat(),
                    "total_workouts": result["workouts_created"],
                }
            ).execute()
        except Exception as assign_err:  # noqa: BLE001
            # The workouts are already created; an assignment-row hiccup
            # should not 500 the schedule.
            logger.warning(
                "Program assignment activation failed: %s", assign_err
            )

        return {
            "success": True,
            "template_id": template_id,
            "schedule_id": schedule_id,
            "start_date": request.start_date.isoformat(),
            "weeks": request.weeks,
            "day_alignment": request.day_alignment,
            "workouts_created": result["workouts_created"],
            "skipped_existing": result["skipped_existing"],
            "total_attempted": result["total_attempted"],
            "deload_weeks": result["deload_weeks"],
            "gym_profile_id": gym_profile_id,
        }
    except HTTPException:
        raise
    except ValueError as ve:
        # Expander validation errors (row cap, no training days, ...).
        raise HTTPException(status_code=422, detail=str(ve))
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to schedule template %s: %s", template_id, e,
            exc_info=True,
        )
        raise safe_internal_error(e, "program_templates")


@router.post("/{template_id}/regenerate-future")
async def regenerate_future_workouts(
    template_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Rebuild not-yet-started future workouts after a template edit (#54-58).

    Only future, uncompleted, non-detached rows are touched; completed /
    in-progress / chat-detached workouts are left intact.
    """
    try:
        db = get_supabase()
        template = _get_template_or_404(db, template_id)
        _require_owner(template, current_user)
        result = regenerate_future(template, str(current_user["id"]))
        return {
            "success": True,
            "template_id": template_id,
            **result,
        }
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to regenerate future for %s: %s", template_id, e,
            exc_info=True,
        )
        raise safe_internal_error(e, "program_templates")
