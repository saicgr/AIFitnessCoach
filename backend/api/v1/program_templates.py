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

import asyncio
import copy
import logging
import uuid
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, BackgroundTasks, Body, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.exceptions import safe_internal_error
from core.logger import get_logger
from core.supabase_client import get_supabase

from services.gemini_service import ResponseCache
from services.program_library_importer import (
    normalize_program_blob_for_preview,
    ExerciseResolver,
    _exercise_to_day_exercise,
    _classify_workout_type,
    map_difficulty,
    derive_progression_strategy,
    derive_deload_every_n,
)
from services.program_template_parser import parse_to_template_json
from services.program_template_expander import (
    expand_template,
    expand_variant_weeks,
    plan_template_days,
    plan_variant_schedule,
    regenerate_future,
    resolve_collision,
    MAX_WEEKS,
)

logger = get_logger(__name__)
router = APIRouter()

# Lazy singleton for S3 presigning (same credentials used by custom exercise
# media). Imported lazily to avoid a circular import at module load.
_s3_media_service = None


def _get_s3_media_service():
    global _s3_media_service
    if _s3_media_service is None:
        from services.custom_exercise_media_service import (
            get_custom_exercise_media_service,
        )
        _s3_media_service = get_custom_exercise_media_service()
    return _s3_media_service


def _presign_s3_path(s3_path: Optional[str]) -> Optional[str]:
    """Resolve an S3 path → the best available GET URL.

    Delegates to `resolve_image_url` (api/v1/library/utils) which:
      • rewrites the legacy `ILLUSTRATIONS/` prefix → real `ILLUSTRATIONS ALL/`,
      • returns a permanent public/CDN URL for static prefixes (illustrations),
      • otherwise presigns, correctly STRIPPING the `s3://bucket/` prefix so the
        S3 object Key is right.

    Historically this presigned via `CustomExerciseMediaService.get_signed_url`,
    which used the full `s3://bucket/key` string as the object Key (prefix not
    stripped) → every program-schedule `image_url` 404'd and tiles showed gray
    placeholders. `resolve_image_url` is the shared, correct choke point.
    Returns None when s3_path is absent or resolution fails."""
    if not s3_path:
        return None
    try:
        from api.v1.library.utils import resolve_image_url
        return resolve_image_url(s3_path)
    except Exception as e:  # noqa: BLE001
        logger.debug("presign failed for %s: %s", s3_path, e)
        return None

# In-memory TTL cache for the program-library browse result. The `programs`
# library is static/curated reference data, so a long TTL is safe — the only
# writes are bulk re-imports, which restart the process. Keyed by the
# (category, difficulty_level, sessions_per_week, search) filter tuple.
# NOTE: cache prefixes carry a "_v2" suffix because the cached dict shape
# changed when the library was unified with branded_programs (added the
# `source` field + branded rows). Bumping the prefix retires any pre-merge
# cached payloads without a manual flush.
_library_browse_cache = ResponseCache(
    prefix="program_library_browse_v6", ttl_seconds=6 * 3600, max_size=256
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
    # Editorial fields (migration 2283) — the curated copy shown on the card +
    # detail. Null on branded rows (which carry their own tagline/description).
    editorial_name: Optional[str] = None
    tagline: Optional[str] = None
    who_for: Optional[str] = None
    who_not_for: Optional[str] = None
    equipment_summary: Optional[str] = None
    progression_note: Optional[str] = None
    # Per-program cover art (S3 path or URL). Null → the client draws its
    # category-gradient fallback. Rendered on the featured hero + browse cards.
    image_url: Optional[str] = None
    # 'library' for `programs` rows (bare uuid id), 'branded' for
    # `branded_programs` rows (id prefixed "branded:<uuid>"). Default keeps
    # existing clients/responses unchanged.
    source: str = "library"


class LibraryBrowseResponse(BaseModel):
    total: int
    programs: List[LibraryProgramCard]


class TemplateCreateRequest(BaseModel):
    """Authored / reviewed template payload (also used to save a parsed one)."""
    name: str = Field(..., min_length=1)
    description: Optional[str] = None
    notes: Optional[str] = None
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
    notes: Optional[str] = None
    week_length: Optional[int] = Field(default=None, ge=1)
    days: Optional[List[Dict[str, Any]]] = None
    deload_every_n_weeks: Optional[int] = None
    progression_strategy: Optional[str] = None
    apply_staples: Optional[bool] = None
    category: Optional[str] = None


class ParseRequest(BaseModel):
    description: str = Field(..., min_length=1)
    # Optional duration hint surfaced in the review UI (echoed as suggested_weeks).
    weeks: Optional[int] = Field(default=None, ge=1)


class ScheduleRequest(BaseModel):
    start_date: date
    weeks: int = Field(..., ge=1)
    day_alignment: str = Field(default="start_today")
    # {day_index: "HH:MM"} user-local times; missing days default to noon.
    day_times: Dict[str, str] = Field(default_factory=dict)


class CustomizeOptions(BaseModel):
    """The three optional adaptation toggles applied to a cloned program's days
    BEFORE it is scheduled. All default ON — a user who taps 'Start' without
    touching options gets a level/injury/equipment-fitted plan."""
    adapt_to_level: bool = True
    swap_for_injuries: bool = True
    fit_equipment: bool = True


class AssignProgramRequest(BaseModel):
    """Start a published library program for the user.

    Clones the `programs` row into an editable user_program_template, optionally
    customizes its days, creates a user_program_assignments row (slot +
    assigned_days), then expands concrete dated workouts and clears the /today
    cache.
    """
    program_id: str = Field(..., description="public.programs.id to start")
    assigned_days: List[int] = Field(
        default_factory=list,
        description="Weekdays to train, Mon=0..Sun=6. Empty => start_today "
        "sequential off the template's training days.",
    )
    slot: str = Field(default="primary", description="'primary' | 'addon'")
    start_date: Optional[date] = None
    replace: bool = Field(
        default=True,
        description="primary only: end overlapping active PRIMARY assignments.",
    )
    duration_weeks: Optional[int] = Field(default=None, ge=1)
    customize: Optional[CustomizeOptions] = None
    variant_id: Optional[str] = Field(
        default=None,
        description="Optional program_variants.id to clone. When provided, "
        "the variant's program_variant_weeks rows are used instead of the "
        "curated programs.workouts blob. Fail-open: any lookup error falls "
        "back to the single-plan path.",
    )
    day_resolutions: Dict[str, str] = Field(
        default_factory=dict,
        description="Optional per-day conflict override: {ISO date 'YYYY-MM-DD' "
        "→ 'replace' | 'add'}. 'replace' supersedes the existing workout that "
        "day; 'add' keeps it and stacks the new one as an extra "
        "(program_slot='addon'). Absent/empty → the global slot+replace default "
        "(primary+replace replaces conflicts). Must match the assign-preview "
        "input so creation mirrors the preview exactly.",
    )


class AssignPreviewRequest(BaseModel):
    """Dry-run a program assignment: compute the REAL dated schedule + calendar
    collisions WITHOUT writing anything. Same inputs as [AssignProgramRequest];
    the response shows exactly what `assign` would create so the Start sheet can
    show "what lands when" and "what it overlaps" before the user commits."""
    program_id: str
    assigned_days: List[int] = Field(default_factory=list)
    slot: str = "primary"
    start_date: Optional[date] = None
    replace: bool = True
    duration_weeks: Optional[int] = Field(default=None, ge=1)
    variant_id: Optional[str] = None
    customize: Optional[CustomizeOptions] = None
    day_resolutions: Dict[str, str] = Field(
        default_factory=dict,
        description="Per-day conflict override {ISO date → 'replace' | 'add'}; "
        "same shape + semantics as on AssignProgramRequest so the preview "
        "reflects exactly what assign will create.",
    )


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
        "notes": row.get("notes"),
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
# Branded-program unification (programs ∪ branded_programs at the read API)
# =============================================================================
# The two catalogs are merged at the READ layer ONLY — no data migration. A
# branded card's id is prefixed "branded:<uuid>" so the client + the single-
# program preview/import dispatch can tell the two sources apart; `programs`
# ids stay bare. The card's `source` field ('library' | 'branded') is the
# explicit, prefix-independent discriminator.
_BRANDED_ID_PREFIX = "branded:"

# Product decision 2026-06-25: the library shows ONLY the curated `programs`
# set (is_published=true). The legacy branded_programs catalog has no publish
# flag, so merging it floods every surface with un-curated rows (Desk Break,
# Equipment Specific, Obese Beginner, …). Gate the merge OFF. Branded
# single-program preview/import paths are left intact (harmless — no branded
# card surfaces to reach them). Flip to True to restore the unified merge.
_INCLUDE_BRANDED_IN_LIBRARY = False

# branded_programs.category enum -> friendly Title Case label shown on cards.
# Anything not in this map (the live table has drifted past the original 8-value
# CHECK, e.g. 'gym_packed') falls back to Title-Cased underscores.
_BRANDED_CATEGORY_LABELS: Dict[str, str] = {
    "strength": "Strength",
    "hypertrophy": "Hypertrophy",
    "endurance": "Endurance",
    "athletic": "Athletic",
    "fat_loss": "Fat Loss",
    "general_fitness": "General Fitness",
    "bodyweight": "Bodyweight",
    "powerbuilding": "Powerbuilding",
}

# branded_programs.difficulty_level -> friendly Title Case label.
_BRANDED_DIFFICULTY_LABELS: Dict[str, str] = {
    "beginner": "Beginner",
    "intermediate": "Intermediate",
    "advanced": "Advanced",
    "all_levels": "All Levels",
}


def _titleize(token: Optional[str]) -> Optional[str]:
    """snake_case / lowercase -> 'Title Case' (None passes through)."""
    if not token:
        return None
    return " ".join(w.capitalize() for w in str(token).replace("_", " ").split())


def branded_category_label(category: Optional[str]) -> Optional[str]:
    """Friendly Title Case label for a branded_programs.category value."""
    if not category:
        return None
    key = str(category).strip().lower()
    return _BRANDED_CATEGORY_LABELS.get(key) or _titleize(category)


def branded_difficulty_label(difficulty: Optional[str]) -> Optional[str]:
    """Friendly Title Case label for a branded_programs.difficulty_level."""
    if not difficulty:
        return None
    key = str(difficulty).strip().lower()
    return _BRANDED_DIFFICULTY_LABELS.get(key) or _titleize(difficulty)


def _branded_row_to_card(row: Dict[str, Any]) -> LibraryProgramCard:
    """Map a branded_programs row into the shared LibraryProgramCard shape.

    name->program_name; category enum -> friendly label (program_category);
    split_type -> program_subcategory; difficulty Title Case; description falls
    back to tagline; session_duration_minutes is unknown for branded (null ok).
    The id is prefixed so the client + preview/import dispatch by source.
    """
    return LibraryProgramCard(
        id=f"{_BRANDED_ID_PREFIX}{row['id']}",
        program_name=row.get("name") or "Program",
        program_category=branded_category_label(row.get("category")),
        program_subcategory=_titleize(row.get("split_type")),
        celebrity_name=None,
        difficulty_level=branded_difficulty_label(row.get("difficulty_level")),
        duration_weeks=row.get("duration_weeks"),
        sessions_per_week=row.get("sessions_per_week"),
        session_duration_minutes=None,
        description=(row.get("description") or row.get("tagline")),
        goals=row.get("goals") or [],
        source="branded",
    )


# Light column list for branded cards — mirrors _LIBRARY_CARD_COLS, branded
# schema. is_featured drives the featured ∪.
_BRANDED_CARD_COLS = (
    "id, name, tagline, description, category, difficulty_level, "
    "duration_weeks, sessions_per_week, split_type, goals, is_featured"
)


def _fetch_branded_cards(
    db,
    *,
    featured_only: bool = False,
) -> List[LibraryProgramCard]:
    """Fetch ACTIVE branded_programs as cards. Best-effort: a branded-table
    error must NOT take down the (curated) library — callers degrade to the
    `programs`-only result rather than 500."""
    if not _INCLUDE_BRANDED_IN_LIBRARY:
        return []
    query = (
        db.client.table("branded_programs")
        .select(_BRANDED_CARD_COLS)
        .eq("is_active", True)
    )
    if featured_only:
        query = query.eq("is_featured", True)
    resp = query.execute()
    return [_branded_row_to_card(row) for row in (resp.data or [])]


def _strip_branded_prefix(program_id: str) -> str:
    """'branded:<uuid>' -> '<uuid>'. Assumes caller already checked prefix."""
    return program_id[len(_BRANDED_ID_PREFIX):]


def _branded_week_workouts_to_days(
    week_workouts: List[Dict[str, Any]],
    *,
    difficulty_level: Optional[str],
    resolver: ExerciseResolver,
) -> List[Dict[str, Any]]:
    """Normalize a branded `program_variant_weeks.workouts` array (one week of
    sessions) into the editable `days[]` shape used by user_program_templates.

    The branded week-workout shape is structurally the same as a
    programs.workouts entry: {workout_name, type, exercises:[{name, sets, reps,
    rest_seconds, ...}]}. We reuse the importer's per-exercise normalizer so the
    rep-string parsing + exercise resolution are IDENTICAL to the programs path.
    """
    program_difficulty = map_difficulty(difficulty_level)
    days: List[Dict[str, Any]] = []
    for idx, w in enumerate(week_workouts or []):
        raw_exercises = w.get("exercises") or []
        day_exercises = [
            _exercise_to_day_exercise(ex, resolver) for ex in raw_exercises
        ]
        is_rest = len(day_exercises) == 0
        days.append(
            {
                "day_index": idx,
                "day_name": (
                    w.get("workout_name")
                    or w.get("name")
                    or f"Day {idx + 1}"
                ),
                "is_rest": is_rest,
                "workout_type": _classify_workout_type(w.get("type")),
                "difficulty": program_difficulty,
                "exercises": day_exercises,
            }
        )
    return days


def _fetch_branded_first_week_workouts(
    db, branded_id: str, program_name: str
) -> List[Dict[str, Any]]:
    """Best-effort fetch of one representative week of branded session data.

    Branded structured weeks live in `program_variant_weeks`, reached via a
    `program_variants` row (joined either on base_program_id OR on a name match,
    since the duration service keys variants by variant_name). We take week 1 of
    the base-duration variant as the canonical day rotation. Returns [] if no
    structured weeks exist (caller then signals preview_available=False rather
    than fabricating).
    """
    variant_ids: List[str] = []
    try:
        vresp = (
            db.client.table("program_variants")
            .select("id")
            .eq("base_program_id", branded_id)
            .order("duration_weeks")
            .execute()
        )
        variant_ids = [str(v["id"]) for v in (vresp.data or [])]
    except Exception as e:  # noqa: BLE001
        logger.warning(
            "branded preview: variant lookup by base_program_id failed: %s", e
        )

    # Fallback: the duration service matches variants by variant_name, not
    # base_program_id — try a name match if the FK join found nothing.
    if not variant_ids and program_name:
        try:
            vresp = (
                db.client.table("program_variants")
                .select("id")
                .ilike("variant_name", f"%{program_name}%")
                .order("duration_weeks")
                .execute()
            )
            variant_ids = [str(v["id"]) for v in (vresp.data or [])]
        except Exception as e:  # noqa: BLE001
            logger.warning(
                "branded preview: variant lookup by name failed: %s", e
            )

    for vid in variant_ids:
        try:
            wresp = (
                db.client.table("program_variant_weeks")
                .select("workouts")
                .eq("variant_id", vid)
                .order("week_number")
                .limit(1)
                .execute()
            )
            if wresp.data:
                blob = wresp.data[0].get("workouts")
                if isinstance(blob, list) and blob:
                    return blob
        except Exception as e:  # noqa: BLE001
            logger.warning(
                "branded preview: week fetch for variant %s failed: %s", vid, e
            )
            continue
    return []


# =============================================================================
# Natural program search (broadened multi-field + synonym expansion)
# =============================================================================
# Body-part / goal synonym expansion so "chest" finds push programs, "lose belly
# fat" finds Lean Burn, etc. Each key is the user-typed concept; the values are
# the terms we ALSO match against the program's searchable text. Keyed by the
# trigger substring (so "chest day" still expands via "chest"). The curated set
# is tiny (~18 published) so this all runs in Python per request.
_SEARCH_SYNONYMS: Dict[str, List[str]] = {
    "chest": ["chest", "pec", "bench", "push-up", "push up", "chest press",
              "fly", "dip", "incline", "push"],
    "back": ["back", "lat", "row", "pull", "pull-up", "pull up", "deadlift",
             "pulldown"],
    "leg": ["leg", "quad", "squat", "lunge", "hamstring", "calf", "glute"],
    "legs": ["leg", "quad", "squat", "lunge", "hamstring", "calf", "glute"],
    "glute": ["glute", "hip thrust", "bridge", "hip"],
    "glutes": ["glute", "hip thrust", "bridge", "hip"],
    "shoulder": ["shoulder", "delt", "overhead", "ohp", "press", "lateral raise"],
    "shoulders": ["shoulder", "delt", "overhead", "ohp", "press", "lateral raise"],
    "arm": ["arm", "bicep", "tricep", "curl", "extension"],
    "arms": ["arm", "bicep", "tricep", "curl", "extension"],
    "core": ["core", "ab", "abs", "plank", "crunch", "oblique"],
    "abs": ["core", "ab", "abs", "plank", "crunch", "oblique"],
    "cardio": ["cardio", "run", "running", "endurance", "conditioning",
               "hyrox", "row", "ski", "sprint"],
    "fat loss": ["fat loss", "lean", "cut", "weight loss", "shred", "burn"],
    "lose": ["fat loss", "lean", "cut", "weight loss", "shred", "burn"],
    "belly": ["fat loss", "lean", "cut", "core", "ab", "abs"],
    "muscle": ["muscle", "hypertrophy", "build", "mass", "bodybuilding",
               "aesthetic"],
    "strength": ["strength", "powerlifting", "heavy", "1rm", "power"],
}


def _expand_search_terms(search: str) -> List[str]:
    """Expand a raw search string into a deduped list of lowercased match terms:
    the original phrase + its whitespace tokens + any synonym-map expansions
    triggered by a token or by a phrase substring (e.g. 'fat loss', 'lose')."""
    s = (search or "").strip().lower()
    if not s:
        return []
    terms: List[str] = [s]
    terms.extend(t for t in s.split() if t)
    # Phrase-level synonym triggers (multi-word keys like 'fat loss').
    for key, syns in _SEARCH_SYNONYMS.items():
        if key in s:
            terms.extend(syns)
    # De-dupe, preserve order, drop empties + 1-char noise.
    seen: set = set()
    out: List[str] = []
    for t in terms:
        t = t.strip()
        if len(t) < 2 or t in seen:
            continue
        seen.add(t)
        out.append(t)
    return out


def _workouts_blob_text(workouts: Any) -> str:
    """Flatten a programs.workouts JSONB into a lowercased text blob of exercise
    names (+ workout/day labels) so movements like 'Bench Press' are searchable.
    Best-effort: any unexpected shape returns ''. Bounded — curated programs are
    small."""
    if not workouts:
        return ""
    parts: List[str] = []
    blob = workouts
    if isinstance(blob, dict):
        blob = blob.get("workouts") or []
    if not isinstance(blob, list):
        return ""
    for w in blob:
        if not isinstance(w, dict):
            continue
        for k in ("workout_name", "name", "type", "focus"):
            v = w.get(k)
            if isinstance(v, str):
                parts.append(v)
        for ex in (w.get("exercises") or []):
            if isinstance(ex, dict):
                nm = ex.get("exercise_name") or ex.get("name")
                if isinstance(nm, str):
                    parts.append(nm)
            elif isinstance(ex, str):
                parts.append(ex)
    return " ".join(parts).lower()


def _search_rank(row: Dict[str, Any], terms: List[str]) -> int:
    """Score a program row against the expanded search terms. 0 = no match.
    Weighted by where the hit lands: name/editorial > category/goals/tags >
    description > workouts-text (exercise names)."""
    if not terms:
        return 1  # no search → everything matches (caller shouldn't call this)

    name_blob = " ".join(
        str(row.get(k) or "") for k in ("program_name", "editorial_name")
    ).lower()
    cat_blob = " ".join(
        str(row.get(k) or "")
        for k in ("program_category", "program_subcategory")
    ).lower()
    goals_blob = " ".join(str(g).lower() for g in (row.get("goals") or []))
    tags_blob = " ".join(str(t).lower() for t in (row.get("tags") or []))
    tagline_blob = " ".join(
        str(row.get(k) or "") for k in ("tagline", "who_for")
    ).lower()
    desc_blob = " ".join(
        str(row.get(k) or "")
        for k in ("description", "short_description", "equipment_summary",
                  "progression_note")
    ).lower()
    workouts_blob = _workouts_blob_text(row.get("workouts"))

    score = 0
    for t in terms:
        if t in name_blob:
            score += 100
        if t in cat_blob or t in goals_blob or t in tags_blob:
            score += 40
        if t in tagline_blob:
            score += 25
        if t in desc_blob:
            score += 15
        if t in workouts_blob:
            score += 8
    return score


# =============================================================================
# Library - first-ever API over the `programs` table
# =============================================================================
@router.get("/library", response_model=LibraryBrowseResponse)
async def browse_library(
    category: Optional[str] = Query(default=None),
    difficulty_level: Optional[str] = Query(default=None),
    sessions_per_week: Optional[int] = Query(default=None),
    search: Optional[str] = Query(default=None),
    goals: Optional[str] = Query(
        default=None,
        description="Comma-separated goal tokens; keep programs whose goals[] "
        "overlaps ANY token (case-insensitive contains).",
    ),
    duration_min: Optional[int] = Query(default=None, ge=1),
    duration_max: Optional[int] = Query(default=None, ge=1),
    current_user: dict = Depends(get_current_user),
):
    """Browse the 259-program `programs` library as lightweight cards.

    Filters: program_category, difficulty_level, sessions_per_week, free-text
    search on program_name, goals[] overlap, and a duration_weeks range. The 7
    rows with an empty `workouts` blob are excluded server-side via the
    precomputed `has_workouts` column (migration 2220) — we no longer fetch the
    heavy `workouts` JSONB blob just to derive that, which is what made this
    endpoint slow enough to trip the client's receiveTimeout. Empty filtered
    result -> total=0 (#L14).

    Cached (in-memory, long TTL) keyed by the filter tuple, since the library
    is static curated data.
    """
    try:
        # Serve from cache when present — library is static reference data.
        # RedisCache.get/set take a SINGLE string key — build one via make_key
        # (the old `.get(*cache_key)` unpacked a 4-tuple → TypeError 500).
        db = get_supabase()
        cache_key = _library_browse_cache.make_key(
            await _programs_cache_version(db),
            category or "",
            difficulty_level or "",
            sessions_per_week if sessions_per_week is not None else -1,
            (search or "").strip().lower(),
            (goals or "").strip().lower(),
            duration_min if duration_min is not None else -1,
            duration_max if duration_max is not None else -1,
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

        # Light card columns. When a free-text `search` is present we ALSO pull
        # `tags` + the `workouts` JSONB so the broadened Python matcher can search
        # category/goals/tags/description AND exercise names. The curated
        # published set is tiny (~18) so fetching workouts on the search path is
        # cheap; the no-search browse keeps the light select.
        _card_cols = (
            "id, program_name, program_category, program_subcategory, "
            "celebrity_name, difficulty_level, duration_weeks, "
            "sessions_per_week, session_duration_minutes, description, "
            "short_description, goals, editorial_name, tagline, who_for, "
            "who_not_for, equipment_summary, progression_note, image_url"
        )
        if search:
            _card_cols += ", tags, workouts"
        # NOTE: the structured DB-side filters below only apply to the curated
        # `programs` query. Branded rows are fetched whole and filtered in
        # Python by the SAME predicates so the merged set is filtered uniformly.
        query = db.client.table("programs").select(
            _card_cols
        ).eq("has_workouts", True).eq("is_published", True)  # curated set only
        # Celebrity programs are no longer surfaced in the library (product
        # decision 2026-06): drop the whole "Celebrity Workout" category.
        query = query.neq("program_category", "Celebrity Workout")
        if category:
            query = query.eq("program_category", category)
        if difficulty_level:
            query = query.eq("difficulty_level", difficulty_level)
        if sessions_per_week is not None:
            query = query.eq("sessions_per_week", sessions_per_week)
        # NOTE: `search` is intentionally NOT applied DB-side anymore. The old
        # name-only `ilike(program_name)` missed "chest"/"lose belly fat"/exercise
        # names. We fetch the (small) filtered set and rank in Python below with
        # synonym expansion + multi-field matching. The other DB-side filters
        # (category/difficulty/sessions/duration) still narrow the set first.
        # duration_weeks range — DB-side (cheap, indexed-ish numeric compare).
        if duration_min is not None:
            query = query.gte("duration_weeks", duration_min)
        if duration_max is not None:
            query = query.lte("duration_weeks", duration_max)
        resp = query.execute()

        # Broadened, ranked search over the fetched curated set (synonym-expanded,
        # multi-field). Build {program_id: rank}; rows scoring 0 are dropped. When
        # there's no search, every row passes (rank not consulted).
        search_terms = _expand_search_terms(search) if search else []
        _search_ranks: Dict[str, int] = {}
        if search_terms:
            for row in resp.data or []:
                r = _search_rank(row, search_terms)
                if r > 0:
                    _search_ranks[str(row["id"])] = r

        # goals[] overlap — Python post-filter (case-insensitive substring
        # match of ANY requested token against ANY of the program's goals).
        goal_tokens = [
            g.strip().lower() for g in (goals or "").split(",") if g.strip()
        ]

        def _matches_goals(program_goals: Any) -> bool:
            if not goal_tokens:
                return True
            if not isinstance(program_goals, list):
                return False
            blob = " ".join(str(g).lower() for g in program_goals)
            return any(tok in blob for tok in goal_tokens)

        cards: List[LibraryProgramCard] = []
        for row in resp.data or []:
            if not _matches_goals(row.get("goals")):
                continue
            # When searching, only keep rows that scored a match.
            if search_terms and str(row["id"]) not in _search_ranks:
                continue
            # _row_to_card resolves the cover (image_url) AND strips celebrity —
            # same field shape as /library/featured, so covers render on the
            # browse grid + rails too. (Hand-building the card here previously
            # dropped image_url, leaving browse cards image-less.)
            cards.append(_row_to_card(row))

        # --- Merge in branded_programs, then apply the SAME filters in Python
        # so both taxonomies are filtered identically. The category filter must
        # match EITHER taxonomy: for branded we match against the friendly
        # label (e.g. ?category=Strength matches category='strength'), so a
        # single category value works across both. Best-effort: a branded-table
        # failure degrades to the curated-only result instead of 500ing.
        try:
            branded_cards = _fetch_branded_cards(db)
        except Exception as be:  # noqa: BLE001
            logger.warning("Branded merge skipped (fetch failed): %s", be)
            branded_cards = []

        norm_difficulty = (difficulty_level or "").strip().lower() or None
        for bc in branded_cards:
            # category: match against the friendly label (case-insensitive).
            if category and (bc.program_category or "").lower() != (
                category.strip().lower()
            ):
                continue
            # difficulty_level: branded labels are Title Case ('All Levels');
            # match the raw incoming token case-insensitively against the label.
            if norm_difficulty and (
                bc.difficulty_level or ""
            ).lower() != norm_difficulty:
                continue
            if (
                sessions_per_week is not None
                and bc.sessions_per_week != sessions_per_week
            ):
                continue
            # Broadened branded search: rank the card's own fields against the
            # SAME expanded terms (branded rows have no workouts blob to mine).
            if search_terms:
                bc_row = {
                    "program_name": bc.program_name,
                    "editorial_name": bc.editorial_name,
                    "program_category": bc.program_category,
                    "program_subcategory": bc.program_subcategory,
                    "goals": bc.goals,
                    "tagline": bc.tagline,
                    "who_for": bc.who_for,
                    "description": bc.description,
                }
                br = _search_rank(bc_row, search_terms)
                if br <= 0:
                    continue
                _search_ranks[bc.id] = br
            if duration_min is not None and (
                bc.duration_weeks is None or bc.duration_weeks < duration_min
            ):
                continue
            if duration_max is not None and (
                bc.duration_weeks is None or bc.duration_weeks > duration_max
            ):
                continue
            if not _matches_goals(bc.goals):
                continue
            cards.append(bc)

        if search_terms:
            # Search results: rank desc, then name for stable ties.
            cards.sort(
                key=lambda c: (-_search_ranks.get(c.id, 0), c.program_name)
            )
        else:
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


# Light card column list — shared by /library, /library/featured,
# /library/recommended so they all hydrate the same LibraryProgramCard shape.
_LIBRARY_CARD_COLS = (
    "id, program_name, program_category, program_subcategory, "
    "celebrity_name, difficulty_level, duration_weeks, "
    "sessions_per_week, session_duration_minutes, description, "
    "short_description, goals, featured_rank, "
    "editorial_name, tagline, who_for, who_not_for, "
    "equipment_summary, progression_note, image_url"
)


def _row_to_card(row: Dict[str, Any]) -> LibraryProgramCard:
    """Hydrate a programs row into the lightweight browse card."""
    # Resolve cover art (s3:// → presigned/public URL; pass-through for an
    # already-http URL or null). Same resolver the exercise images use.
    _img = row.get("image_url")
    if _img:
        try:
            from api.v1.library.utils import resolve_image_url
            _img = resolve_image_url(_img)
        except Exception:  # noqa: BLE001 — never block a card on cover resolve
            pass
    return LibraryProgramCard(
        id=str(row["id"]),
        program_name=row.get("program_name") or "Program",
        program_category=row.get("program_category"),
        program_subcategory=row.get("program_subcategory"),
        # No celebrity tags anywhere in the library.
        celebrity_name=None,
        difficulty_level=row.get("difficulty_level"),
        duration_weeks=row.get("duration_weeks"),
        sessions_per_week=row.get("sessions_per_week"),
        session_duration_minutes=row.get("session_duration_minutes"),
        description=(row.get("short_description") or row.get("description")),
        goals=row.get("goals") or [],
        editorial_name=row.get("editorial_name"),
        tagline=row.get("tagline"),
        who_for=row.get("who_for"),
        who_not_for=row.get("who_not_for"),
        equipment_summary=row.get("equipment_summary"),
        progression_note=row.get("progression_note"),
        image_url=_img,
        source="library",
    )


# Maps a user's `primary_goal` to the goal keywords found in a program's
# `goals[]` array. Match is case-insensitive substring (so "Build Muscle"
# matches "build muscle and strength"). strength_hypertrophy spans both.
_GOAL_KEYWORDS: Dict[str, List[str]] = {
    "muscle_hypertrophy": ["build muscle", "hypertrophy", "aesthetic", "muscle"],
    "muscle_strength": ["increase strength", "strength", "powerlifting"],
    "strength_hypertrophy": [
        "build muscle", "hypertrophy", "aesthetic", "muscle",
        "increase strength", "strength", "powerlifting",
    ],
    "weight_loss": ["weight loss", "fat loss", "lean", "lose weight", "cut"],
    "fat_loss": ["fat loss", "weight loss", "lean", "cut"],
    "endurance": ["endurance", "conditioning", "cardio", "stamina"],
    "general_fitness": ["general fitness", "health", "wellness", "fitness"],
    "athletic_performance": [
        "athletic", "performance", "sport", "power", "explosive",
    ],
    "mobility": ["mobility", "flexibility", "stretch"],
}

# Normalized fitness-level vocabulary for the difficulty-match scoring rule.
_FITNESS_LEVELS = ("beginner", "intermediate", "advanced")

# Featured / recommended caches — same long TTL + dict-only rule as browse.
_library_featured_cache = ResponseCache(
    prefix="program_library_featured_v5", ttl_seconds=6 * 3600, max_size=8
)
# Editorial chip order for GET /library/categories. Categories are shown as
# horizontally-scrolling chips; without an explicit order, count-desc + A-Z
# buries low-count marquee categories past the ~4 visible chips. Any category
# NOT listed here falls back to count-desc/alphabetical AFTER these. Prefix
# bumped to _v6 to retire the pre-ordering cached payloads.
_CATEGORY_DISPLAY_ORDER = (
    "Quick Hits",
    "Strength & Muscle",
    "Sports Performance",  # featured early so the (low-count) new category is visible without scrolling past it
    "HYROX & Race Prep",
    "Fat Loss",
    "Aesthetic",
    "Men's Health",
    "Women's Health",
    "Yoga & Mobility",
)
_library_categories_cache = ResponseCache(
    prefix="program_library_categories_v6", ttl_seconds=6 * 3600, max_size=8
)
_library_recommended_cache = ResponseCache(
    prefix="program_library_recommended_v5", ttl_seconds=6 * 3600, max_size=256
)

# Per-program detail cache (GET /library/{id}). The detail payload is STATIC for
# a given program — the heavy cost is ExerciseResolver loading the 2192-row
# library MV + per-exercise RAG (Gemini embed + ChromaDB) resolution, which is
# user-independent (the preview resolves catalog names to the SHARED library, so
# we build it with user_id=None — see _build_library_detail_static). Caching it
# turns a cold 10-20s build into a one-time cost shared across every user. Keyed
# on (program_id, programs-data-version) so any `programs` write busts it (the
# same data-driven token the browse/featured caches use); the 6h TTL bounds
# staleness for branded rows whose writes don't bump the curated token. The one
# dynamic field — joined_count — is overlaid fresh on every response, never
# cached, so social proof stays live.
_library_detail_cache = ResponseCache(
    prefix="program_library_detail_v1", ttl_seconds=6 * 3600, max_size=512
)

# Data-driven cache invalidation. The library content caches key on this token,
# which is `cache_versions.version` for the `programs` table — bumped by a
# statement-level trigger on ANY write to `programs` (API write OR raw
# SQL/migration; migration 2299). So a cover/editorial change flips the token
# and every library cache misses on the next request — no manual prefix bump,
# no redeploy. The token itself is cached briefly so we don't hit the DB on
# every library request; max staleness after a write = this short TTL.
_library_version_cache = ResponseCache(
    prefix="programs_data_version", ttl_seconds=45, max_size=1
)


async def _programs_cache_version(db) -> str:
    """Current `programs` data-version token (see migration 2299). Cached ~45s.
    Fail-open: any error returns "0" so the library still serves (just without
    the dynamic bust) rather than 500ing on a cache-key build."""
    key = _library_version_cache.make_key("programs")
    cached = await _library_version_cache.get(key)
    if cached is not None:
        return str(cached)
    ver = "0"
    try:
        resp = (
            db.client.table("cache_versions")
            .select("version")
            .eq("key", "programs")
            .limit(1)
            .execute()
        )
        if resp.data:
            ver = str(resp.data[0].get("version", 0))
    except Exception as e:  # noqa: BLE001
        logger.warning("programs cache-version lookup failed: %s", e)
    await _library_version_cache.set(key, ver)
    return ver


def _goal_keywords_for(primary_goal: Optional[str]) -> List[str]:
    """Resolve a user's primary_goal to program-goal keywords (lowercase)."""
    if not primary_goal:
        return []
    key = str(primary_goal).strip().lower()
    return _GOAL_KEYWORDS.get(key, [])


def _normalize_level(level: Optional[str]) -> Optional[str]:
    """Normalize an arbitrary fitness_level / difficulty string to one of
    beginner / intermediate / advanced (or None if unrecognized)."""
    if not level:
        return None
    s = str(level).strip().lower()
    for canon in _FITNESS_LEVELS:
        if canon in s:
            return canon
    return None


@router.get("/library/featured", response_model=LibraryBrowseResponse)
async def library_featured(
    current_user: dict = Depends(get_current_user),
):
    """Curated featured programs: WHERE featured_rank IS NOT NULL ORDER BY
    featured_rank ASC. Same lightweight card shape as /library. Excludes
    Celebrity Workout + the empty-workouts rows like everywhere else.

    Cached (in-memory, long TTL) as a plain dict — the library is static.
    """
    try:
        db = get_supabase()
        cache_key = _library_featured_cache.make_key(
            await _programs_cache_version(db), "featured"
        )
        cached = await _library_featured_cache.get(cache_key)
        if isinstance(cached, dict):
            return cached

        resp = (
            db.client.table("programs")
            .select(_LIBRARY_CARD_COLS)
            .eq("has_workouts", True)
            .eq("is_published", True)
            .neq("program_category", "Celebrity Workout")
            .not_.is_("featured_rank", "null")
            .order("featured_rank", desc=False)
            .execute()
        )
        # Curated featured first (ordered by featured_rank), then branded
        # is_featured rows appended AFTER the 6 curated (#3 spec: "rank branded
        # after the 6 curated"). Branded sorted by name for stable ordering.
        cards = [_row_to_card(row) for row in resp.data or []]
        try:
            branded_featured = _fetch_branded_cards(db, featured_only=True)
            branded_featured.sort(key=lambda c: c.program_name)
            cards.extend(branded_featured)
        except Exception as be:  # noqa: BLE001
            logger.warning(
                "Branded featured merge skipped (fetch failed): %s", be
            )
        result = LibraryBrowseResponse(total=len(cards), programs=cards)
        # Cache a JSON-serializable dict, NOT the pydantic model (Redis cache
        # serializes via json.dumps → a cached model returns a useless str).
        await _library_featured_cache.set(cache_key, result.model_dump())
        return result
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to load featured programs: %s", e, exc_info=True)
        raise safe_internal_error(e, "program_templates")


@router.get("/library/categories")
async def library_categories(
    current_user: dict = Depends(get_current_user),
):
    """Distinct program_category values with counts, ordered by count desc.
    Excludes Celebrity Workout + empty-workouts rows.

    Response: {"categories": [{"category": str, "count": int}, ...]}
    Cached (in-memory, long TTL) as a plain dict.
    """
    try:
        db = get_supabase()
        cache_key = _library_categories_cache.make_key(
            await _programs_cache_version(db), "categories"
        )
        cached = await _library_categories_cache.get(cache_key)
        if isinstance(cached, dict):
            return cached

        resp = (
            db.client.table("programs")
            .select("program_category")
            .eq("has_workouts", True)
            .eq("is_published", True)
            .neq("program_category", "Celebrity Workout")
            .execute()
        )
        counts: Dict[str, int] = {}
        for row in resp.data or []:
            cat = row.get("program_category")
            if not cat:
                continue
            counts[cat] = counts.get(cat, 0) + 1

        # Merge branded category counts under the SAME friendly labels so a
        # branded 'strength' folds into the curated 'Strength' bucket where the
        # `programs` taxonomy already uses that label, otherwise it adds a new
        # branded-only category (e.g. 'Powerbuilding'). Best-effort.
        if _INCLUDE_BRANDED_IN_LIBRARY:
            try:
                bresp = (
                    db.client.table("branded_programs")
                    .select("category")
                    .eq("is_active", True)
                    .execute()
                )
                for row in bresp.data or []:
                    label = branded_category_label(row.get("category"))
                    if not label:
                        continue
                    counts[label] = counts.get(label, 0) + 1
            except Exception as be:  # noqa: BLE001
                logger.warning(
                    "Branded category merge skipped (fetch failed): %s", be
                )

        # Order chips by an explicit editorial priority first, then by count
        # desc, then A-Z. Pure count-desc/alphabetical buried marquee but
        # low-count categories (e.g. "Sports Performance", count 2) past the
        # ~4 chips visible in the horizontally-scrolling chip row, making them
        # look absent. An explicit order guarantees curated categories surface;
        # any category NOT in the list falls back to the count/name ordering
        # after the prioritized ones.
        _priority = {cat: i for i, cat in enumerate(_CATEGORY_DISPLAY_ORDER)}
        _fallback_rank = len(_CATEGORY_DISPLAY_ORDER)
        categories = [
            {"category": cat, "count": n}
            for cat, n in sorted(
                counts.items(),
                key=lambda kv: (
                    _priority.get(kv[0], _fallback_rank),
                    -kv[1],
                    kv[0],
                ),
            )
        ]
        result = {"categories": categories}
        # Cache the plain dict directly (already JSON-serializable).
        await _library_categories_cache.set(cache_key, result)
        return result
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to load library categories: %s", e, exc_info=True
        )
        raise safe_internal_error(e, "program_templates")


@router.get("/library/recommended", response_model=LibraryBrowseResponse)
async def library_recommended(
    current_user: dict = Depends(get_current_user),
):
    """Personalized top-10 programs scored against the user's primary_goal +
    fitness_level.

    Scoring per non-celebrity has_workouts program:
      +30 if any user-goal keyword matches the program's goals[]
      +25 if difficulty_level ≈ the user's fitness_level (normalized)
      +10 if featured_rank is not null

    Fail-open: if we can't read a goal AND a level, fall back to the featured
    list (never fabricate). Cached per (goal, level) as a plain dict.
    """
    try:
        user_id = str(current_user["id"])
        primary_goal = current_user.get("primary_goal")
        fitness_level = current_user.get("fitness_level")

        db = get_supabase()
        # get_current_user may not carry profile fields — hydrate from `users`.
        if primary_goal is None or fitness_level is None:
            try:
                ures = (
                    db.client.table("users")
                    .select("primary_goal, fitness_level")
                    .eq("id", user_id)
                    .limit(1)
                    .execute()
                )
                if ures.data:
                    primary_goal = primary_goal or ures.data[0].get(
                        "primary_goal"
                    )
                    fitness_level = fitness_level or ures.data[0].get(
                        "fitness_level"
                    )
            except Exception as ue:  # noqa: BLE001
                logger.warning(
                    "recommended: user profile lookup failed: %s", ue
                )

        goal_keywords = _goal_keywords_for(primary_goal)
        user_level = _normalize_level(fitness_level)

        # Fail-open: no usable personalization signal → featured list.
        if not goal_keywords and not user_level:
            return await library_featured(current_user=current_user)

        cache_key = _library_recommended_cache.make_key(
            await _programs_cache_version(db),
            str(primary_goal or "").lower(),
            user_level or "",
        )
        cached = await _library_recommended_cache.get(cache_key)
        if isinstance(cached, dict):
            return cached

        resp = (
            db.client.table("programs")
            .select(_LIBRARY_CARD_COLS)
            .eq("has_workouts", True)
            .eq("is_published", True)
            .neq("program_category", "Celebrity Workout")
            .execute()
        )

        def _score_goals(program_goals: Any) -> int:
            if goal_keywords and isinstance(program_goals, list):
                blob = " ".join(str(g).lower() for g in program_goals)
                if any(kw in blob for kw in goal_keywords):
                    return 30
            return 0

        def _score(row: Dict[str, Any]) -> int:
            s = _score_goals(row.get("goals"))
            if user_level and _normalize_level(
                row.get("difficulty_level")
            ) == user_level:
                s += 25
            if row.get("featured_rank") is not None:
                s += 10
            return s

        # Score curated programs AND active branded programs together; the top
        # 10 of the MERGED set is returned as cards. Branded difficulty is
        # normalized off the raw enum ('all_levels' -> None, never matches a
        # concrete level — same as the curated path). is_featured mirrors the
        # +10 featured weight. Best-effort branded fetch (degrade to curated).
        scored: List[tuple] = [
            (_score(r), _row_to_card(r)) for r in (resp.data or [])
        ]
        if _INCLUDE_BRANDED_IN_LIBRARY:
            try:
                bresp = (
                    db.client.table("branded_programs")
                    .select(_BRANDED_CARD_COLS)
                    .eq("is_active", True)
                    .execute()
                )
                for brow in bresp.data or []:
                    bs = _score_goals(brow.get("goals"))
                    if user_level and _normalize_level(
                        brow.get("difficulty_level")
                    ) == user_level:
                        bs += 25
                    if brow.get("is_featured"):
                        bs += 10
                    scored.append((bs, _branded_row_to_card(brow)))
            except Exception as be:  # noqa: BLE001
                logger.warning(
                    "Branded recommended merge skipped (fetch failed): %s", be
                )

        scored.sort(key=lambda pair: pair[0], reverse=True)
        top = [card for _, card in scored[:10]]
        result = LibraryBrowseResponse(total=len(top), programs=top)
        await _library_recommended_cache.set(cache_key, result.model_dump())
        return result
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to load recommended programs: %s", e, exc_info=True
        )
        raise safe_internal_error(e, "program_templates")


# --- Detail-page enrichers (joined_count + phases) -------------------------
def _normalize_phases(raw: Any) -> List[Dict[str, Any]]:
    """Normalize the `programs.phases` jsonb (migration 2286) into a clean list
    of {index, title, subtitle, week_start, week_end}. Returns [] when absent /
    malformed — the content agent authors these per published program."""
    if not isinstance(raw, list):
        return []
    out: List[Dict[str, Any]] = []
    for i, p in enumerate(raw):
        if not isinstance(p, dict):
            continue
        out.append({
            "index": p.get("index", i),
            "title": p.get("title"),
            "subtitle": p.get("subtitle"),
            "week_start": p.get("week_start"),
            "week_end": p.get("week_end"),
        })
    return out


def _program_joined_count(db, program_id: str) -> int:
    """COUNT(DISTINCT user_id) of assignments started from this catalog program.
    Real count (may be 0). Fail-open to 0 — social proof must never 500 detail.

    supabase-py has no COUNT(DISTINCT); we fetch the (small) user_id column and
    dedupe in Python. The set is bounded by adoption, well within one page."""
    try:
        resp = (
            db.client.table("user_program_assignments")
            .select("user_id")
            .eq("source_program_id", program_id)
            .execute()
        )
        return len({str(r["user_id"]) for r in (resp.data or []) if r.get("user_id")})
    except Exception as e:  # noqa: BLE001
        logger.warning("joined_count failed for %s (fail-open 0): %s", program_id, e)
        return 0


def _fetch_variant_options(
    db, variant_base_id: Optional[str], default_variant_id: Optional[str]
) -> List[Dict[str, Any]]:
    """Return the sorted list of variant options for the detail page.

    Source: program_variants WHERE base_program_id = variant_base_id, each row
    becoming {variant_id, weeks, sessions_per_week, intensity, is_default}.
    Sorted by weeks ASC, then sessions ASC, then intensity.
    Returns [] when variant_base_id is NULL (single-plan programs).
    """
    if not variant_base_id:
        return []
    try:
        resp = (
            db.client.table("program_variants")
            .select("id, duration_weeks, sessions_per_week, intensity_level")
            .eq("base_program_id", variant_base_id)
            .order("duration_weeks", desc=False)
            .execute()
        )
        all_rows = resp.data or []
        if not all_rows:
            return []
        # Only offer variants that actually have generated week content — some
        # variants came out EMPTY (0 program_variant_weeks rows) from generation
        # gaps. Offering them would dead-end the schedule (falls back to the
        # single plan). Filter to non-empty so the weeks/sessions selectors are
        # honest.
        ids = [str(r["id"]) for r in all_rows]
        wk = (
            db.client.table("program_variant_weeks")
            .select("variant_id")
            .in_("variant_id", ids)
            .execute()
        )
        non_empty = {str(w["variant_id"]) for w in (wk.data or [])}
        rows = [r for r in all_rows if str(r["id"]) in non_empty]
        if not rows:
            return []
        _intensity_rank = {"Easy": 0, "Medium": 1, "Hard": 2}
        rows.sort(
            key=lambda r: (
                r.get("duration_weeks") or 0,
                r.get("sessions_per_week") or 0,
                _intensity_rank.get(r.get("intensity_level") or "Medium", 1),
            )
        )
        # Effective default: the stored default if it's non-empty, else the
        # non-empty variant closest to the stored default's (weeks, sessions) so
        # the headline never points at an empty variant.
        stored = str(default_variant_id or "")
        if stored in {str(r["id"]) for r in rows}:
            eff_default = stored
        else:
            target = next((r for r in all_rows if str(r["id"]) == stored), None)
            tw = (target or {}).get("duration_weeks") or 0
            ts = (target or {}).get("sessions_per_week") or 0
            best = min(
                rows,
                key=lambda r: (
                    abs((r.get("duration_weeks") or 0) - tw),
                    abs((r.get("sessions_per_week") or 0) - ts),
                    _intensity_rank.get(r.get("intensity_level") or "Medium", 1),
                ),
            )
            eff_default = str(best["id"])
        return [
            {
                "variant_id": str(r["id"]),
                "weeks": r.get("duration_weeks"),
                "sessions_per_week": r.get("sessions_per_week"),
                "intensity": r.get("intensity_level"),
                "is_default": str(r["id"]) == eff_default,
            }
            for r in rows
        ]
    except Exception as e:  # noqa: BLE001
        logger.warning(
            "variant_options fetch failed for base %s: %s", variant_base_id, e
        )
        return []


def _build_library_detail_static(db, program_id: str) -> Dict[str, Any]:
    """Build the STATIC (user-independent, cacheable) detail payload for one
    program — everything except the live `joined_count`, which the async route
    overlays fresh.

    Resolves exercises with user_id=None so the payload is identical for every
    user (a curated catalog program's exercises ARE shared-library exercises;
    per-user custom-exercise substitution belongs to the user's OWN saved
    program, not the read-only catalog preview). That user-independence is what
    makes the result safe to cache across users. Heavy: this is the function the
    route runs off the event loop via asyncio.to_thread.

    Raises HTTPException(404/422) exactly as the route contract requires.
    """
    # --- Branded preview path ---------------------------------------------
    if program_id.startswith(_BRANDED_ID_PREFIX):
        branded_id = _strip_branded_prefix(program_id)
        bresp = (
            db.client.table("branded_programs")
            .select("*")
            .eq("id", branded_id)
            .eq("is_active", True)
            .limit(1)
            .execute()
        )
        if not bresp.data:
            raise HTTPException(status_code=404, detail="Program not found")
        branded = bresp.data[0]
        program_name = branded.get("name")
        week_workouts = _fetch_branded_first_week_workouts(
            db, branded_id, program_name or ""
        )
        base = {
            "program_id": program_id,
            "program_name": program_name,
            "celebrity_name": None,
            "difficulty_level": branded_difficulty_label(
                branded.get("difficulty_level")
            ),
            "duration_weeks": branded.get("duration_weeks"),
            "source": "branded",
            "category": branded_category_label(branded.get("category")),
            "description": (
                branded.get("description") or branded.get("tagline")
            ),
        }
        if not week_workouts:
            # No structured weeks -> card-level info + a flag, never fake.
            return {
                **base,
                "preview_available": False,
                "name": program_name,
                "week_length": 7,
                "days": [],
                "progression_strategy": derive_progression_strategy(
                    branded.get("category")
                ),
                "deload_every_n_weeks": derive_deload_every_n(
                    branded.get("category")
                ),
                "source_program_id": branded_id,
            }
        resolver = ExerciseResolver(user_id=None)
        days = _branded_week_workouts_to_days(
            week_workouts,
            difficulty_level=branded.get("difficulty_level"),
            resolver=resolver,
        )
        return {
            **base,
            "preview_available": True,
            "name": program_name or "Imported Program",
            "week_length": max(7, len(days)),
            "days": days,
            "progression_strategy": derive_progression_strategy(
                branded.get("category")
            ),
            "deload_every_n_weeks": derive_deload_every_n(
                branded.get("category")
            ),
            "source_program_id": branded_id,
        }

    # --- Curated `programs` preview path -----------------------------------
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
    normalized = normalize_program_blob_for_preview(program, user_id=None)
    # Variant options (migration 2289): when this program is linked to a
    # branded_programs base, surface the available duration/session choices.
    variant_base_id = program.get("variant_base_id")
    default_variant_id = program.get("default_variant_id")
    variant_options = _fetch_variant_options(db, variant_base_id, default_variant_id)
    # Use the EFFECTIVE default from the (non-empty) options so the FE never
    # initialises the schedule with an empty variant.
    _eff_default = next(
        (o["variant_id"] for o in variant_options if o.get("is_default")), None
    )
    if _eff_default:
        default_variant_id = _eff_default
    # Cover art — same resolver as the browse/featured cards so the detail
    # header KEEPS the cover after this re-fetch replaces the tapped card
    # (a hand-built dict here previously omitted image_url -> cover flickered
    # off once detail loaded).
    from api.v1.library.utils import resolve_image_url as _resolve_img
    return {
        "program_id": str(program["id"]),
        "program_name": program.get("program_name"),
        "celebrity_name": program.get("celebrity_name"),
        "difficulty_level": program.get("difficulty_level"),
        "duration_weeks": program.get("duration_weeks"),
        "sessions_per_week": program.get("sessions_per_week"),
        "session_duration_minutes": program.get("session_duration_minutes"),
        "goals": program.get("goals") or [],
        # Editorial copy (migration 2283) for the detail screen.
        "editorial_name": program.get("editorial_name"),
        "tagline": program.get("tagline"),
        "who_for": program.get("who_for"),
        "who_not_for": program.get("who_not_for"),
        "equipment_summary": program.get("equipment_summary"),
        "progression_note": program.get("progression_note"),
        "image_url": _resolve_img(program.get("image_url")),
        "is_published": program.get("is_published", False),
        # Multi-week phase breakdown (migration 2286 `programs.phases` jsonb).
        # [] when the content agent hasn't authored phases for this program.
        "phases": _normalize_phases(program.get("phases")),
        "source": "library",
        "preview_available": True,
        # Variant chooser (migration 2289): [] + null for single-plan programs.
        "variant_options": variant_options,
        "default_variant_id": (
            str(default_variant_id) if default_variant_id else None
        ),
        **normalized,
    }


@router.get("/library/{program_id}")
async def library_program_detail(
    program_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Full structured preview of one program - the `workouts` JSONB
    normalized into the `days` shape (rep-strings parsed, exercises resolved).

    Source-aware: a 'branded:<uuid>' id previews from branded_programs (week-1
    sessions normalized to the SAME days[] shape). When a branded program has
    no structured weeks, returns card-level info + `preview_available: false`
    so the client shows "Preview not available, you can still start it" rather
    than crashing — we never fabricate workout data.

    Cache-first: the heavy, user-independent build (exercise resolution over the
    2192-row library MV + RAG) is cached by (program_id, programs-data-version)
    and run off the event loop on a cold miss. Only `joined_count` is computed
    live per request, so the 10-20s first build is paid once and shared.
    """
    try:
        db = get_supabase()

        # Cache-first on the static payload, busted by the programs data-version.
        version = await _programs_cache_version(db)
        cache_key = _library_detail_cache.make_key(program_id, version)
        static = await _library_detail_cache.get(cache_key)
        if static is None:
            # Cold miss — build off the event loop so the heavy resolver/RAG
            # work never blocks other in-flight requests.
            static = await asyncio.to_thread(
                _build_library_detail_static, db, program_id
            )
            await _library_detail_cache.set(cache_key, static)

        payload = dict(static)
        # Live social-proof count — never cached, overlaid fresh on every hit.
        # Only curated library programs surface it (branded preview has none).
        if payload.get("source") == "library":
            payload["joined_count"] = await asyncio.to_thread(
                _program_joined_count,
                db,
                str(payload.get("program_id") or program_id),
            )
        return payload
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to load library program %s: %s", program_id, e,
            exc_info=True,
        )
        raise safe_internal_error(e, "program_templates")


@router.get("/library/{program_id}/schedule")
async def library_program_schedule(
    program_id: str,
    variant_id: Optional[str] = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    """Multi-week exercise schedule for a variant of a curated library program.

    When variant_id is supplied → read program_variant_weeks for that variant,
    flatten workouts jsonb into days → exercises, and LEFT JOIN
    program_exercises_with_media (by variant_id + week_number + exercise name)
    to attach image_url, video_url, gif_url, and exercise_id (canonical).

    When variant_id is omitted → use programs.default_variant_id; if that is
    also NULL the program has no variant library and a minimal single-week
    schedule is built from programs.workouts instead (fail-open, no 500).

    Presigning: S3 keys are signed with a 1-hour TTL using the same service
    that handles custom exercise media (CustomExerciseMediaService).
    exercise_id is resolved: program_exercises_with_media does not expose a
    canonical library UUID, so we resolve canonical_name → exercise_library_cleaned.id.
    """
    # NOTE: This route MUST be registered before @router.get("/{template_id}")
    # so FastAPI matches /library/{id}/schedule before the generic catch-all.
    try:
        db = get_supabase()

        # ── 1. Resolve the variant_id to use ──────────────────────────────────
        effective_variant_id = variant_id
        program = None

        if not effective_variant_id:
            # Fetch the curated program to get default_variant_id.
            presp = (
                db.client.table("programs")
                .select("id, program_name, editorial_name, workouts, "
                        "difficulty_level, variant_base_id, default_variant_id")
                .eq("id", program_id)
                .limit(1)
                .execute()
            )
            if not presp.data:
                raise HTTPException(status_code=404, detail="Program not found")
            program = presp.data[0]
            default_vid = program.get("default_variant_id")
            if default_vid:
                effective_variant_id = str(default_vid)

        # ── 2. Variant path: read program_variant_weeks ───────────────────────
        if effective_variant_id:
            weeks_resp = (
                db.client.table("program_variant_weeks")
                .select("week_number, phase, focus, workouts")
                .eq("variant_id", effective_variant_id)
                .order("week_number", desc=False)
                .execute()
            )
            if not weeks_resp.data:
                # Variant exists in DB but has no weeks — fall through to
                # the single-plan path rather than 404ing.
                logger.warning(
                    "schedule: no weeks for variant %s — falling through",
                    effective_variant_id,
                )
                effective_variant_id = None

        if effective_variant_id and weeks_resp.data:
            # ── 2a. Build exercise-name → media map for this variant ──────────
            # Fetch all rows from the view for this variant.
            try:
                media_resp = (
                    db.client.table("program_exercises_with_media")
                    .select(
                        "week_number, workout_idx, exercise_idx, "
                        "exercise_name_normalized, canonical_name, "
                        "image_s3_path, video_s3_path, gif_url"
                    )
                    .eq("variant_id", effective_variant_id)
                    .execute()
                )
                media_rows = media_resp.data or []
            except Exception as me:  # noqa: BLE001
                logger.warning(
                    "schedule: media fetch failed for variant %s: %s",
                    effective_variant_id, me,
                )
                media_rows = []

            # Build a lookup: (week_number, canonical_name_lower) -> media row.
            _media_map: Dict[tuple, Dict[str, Any]] = {}
            for mr in media_rows:
                key = (
                    mr.get("week_number"),
                    (mr.get("canonical_name") or "").lower(),
                )
                if key not in _media_map:
                    _media_map[key] = mr

            # Also build a name-based fallback without week_number.
            _media_name_map: Dict[str, Dict[str, Any]] = {}
            for mr in media_rows:
                cn = (mr.get("canonical_name") or "").lower()
                if cn and cn not in _media_name_map:
                    _media_name_map[cn] = mr

            # PRIMARY map: positional (week_number, workout_idx, exercise_idx).
            # The view's idx columns are 1-based; the JSON flatten loop below is
            # 0-based, so we look up (week, wi+1, ei+1). Positional matching is
            # exact regardless of raw-name vs canonical_name differences — which
            # is what made many thumbnails (Pull-ups, Sled Push, Plank, …) miss
            # when we keyed only on canonical_name.
            _media_pos_map: Dict[tuple, Dict[str, Any]] = {}
            for mr in media_rows:
                pkey = (mr.get("week_number"), mr.get("workout_idx"), mr.get("exercise_idx"))
                if pkey not in _media_pos_map:
                    _media_pos_map[pkey] = mr

            # ── 2b. Resolve canonical_name → exercise_library_cleaned.id ──────
            canonical_names = {
                (mr.get("canonical_name") or "").strip()
                for mr in media_rows
                if mr.get("canonical_name")
            }
            exercise_id_by_name: Dict[str, Optional[str]] = {}
            if canonical_names:
                try:
                    lib_resp = (
                        db.client.table("exercise_library_cleaned")
                        .select("id, name")
                        .in_("name", list(canonical_names))
                        .execute()
                    )
                    for lr in (lib_resp.data or []):
                        exercise_id_by_name[str(lr["name"]).strip()] = str(lr["id"])
                except Exception as le:  # noqa: BLE001
                    logger.warning(
                        "schedule: exercise_id resolution failed: %s", le
                    )

            # ── 2b2. By-id media fallback ─────────────────────────────────────
            # program_exercises_with_media maps media by NAME; some blob names
            # don't resolve (alias gaps, e.g. "Glute Bridge With Abduction
            # Bodyweight"). Blob exercises that carry a verified exercise_id can
            # still resolve media by UUID against the library — batch-fetch those
            # so the flatten loop can fill view misses. Benefits every variant
            # program, not just the timer circuits.
            _json_ex_ids: set = set()
            for _wr in weeks_resp.data:
                for _w in (_wr.get("workouts") or []):
                    if not isinstance(_w, dict):
                        continue
                    for _ex in (_w.get("exercises") or []):
                        if isinstance(_ex, dict) and _ex.get("exercise_id"):
                            _json_ex_ids.add(str(_ex["exercise_id"]))
            _img_by_id: Dict[str, str] = {}
            if _json_ex_ids:
                try:
                    _r = (
                        db.client.table("exercise_library")
                        .select("id, image_s3_path")
                        .in_("id", list(_json_ex_ids))
                        .execute()
                    )
                    for _row in (_r.data or []):
                        if _row.get("image_s3_path"):
                            _img_by_id[str(_row["id"])] = _row["image_s3_path"]
                    _missing = [i for i in _json_ex_ids if i not in _img_by_id]
                    if _missing:
                        _r2 = (
                            db.client.table("exercise_library_cleaned")
                            .select("id, image_url")
                            .in_("id", _missing)
                            .execute()
                        )
                        for _row in (_r2.data or []):
                            if _row.get("image_url"):
                                _img_by_id[str(_row["id"])] = _row["image_url"]
                except Exception as _bid_err:  # noqa: BLE001
                    logger.warning(
                        "schedule: by-id media fallback failed: %s", _bid_err
                    )

            # ── 2c. Flatten weeks → days → exercises ──────────────────────────
            out_weeks: List[Dict[str, Any]] = []
            for wrow in weeks_resp.data:
                week_num = wrow.get("week_number")
                workouts_blob = wrow.get("workouts") or []
                if not isinstance(workouts_blob, list):
                    workouts_blob = []

                days: List[Dict[str, Any]] = []
                for wi, w in enumerate(workouts_blob):
                    if not isinstance(w, dict):
                        continue
                    raw_exercises = w.get("exercises") or []
                    exercises_out: List[Dict[str, Any]] = []
                    for ei, ex in enumerate(
                        raw_exercises if isinstance(raw_exercises, list) else []
                    ):
                        if not isinstance(ex, dict):
                            continue
                        ex_name = (
                            ex.get("exercise_name")
                            or ex.get("name")
                            or ""
                        ).strip()
                        ex_name_lower = ex_name.lower()
                        # PRIMARY: positional match (view idx is 1-based; loop is
                        # 0-based). Falls back to name-based maps only if position
                        # has no row (e.g. view/JSON length drift).
                        media = (
                            _media_pos_map.get((week_num, wi + 1, ei + 1))
                            or _media_map.get((week_num, ex_name_lower))
                            or _media_name_map.get(ex_name_lower)
                            or {}
                        )
                        canon_name = (media.get("canonical_name") or "").strip()
                        json_ex_id = str(ex.get("exercise_id") or "") or None
                        exercise_id = (
                            (exercise_id_by_name.get(canon_name) if canon_name else None)
                            or json_ex_id
                        )

                        # View media first; when the view can't map the name,
                        # fall back to the verified exercise_id in the blob.
                        img_s3 = media.get("image_s3_path") or (
                            _img_by_id.get(json_ex_id) if json_ex_id else None
                        )
                        image_url = _presign_s3_path(img_s3)
                        video_url = _presign_s3_path(media.get("video_s3_path"))
                        gif_url = media.get("gif_url") or None

                        exercises_out.append({
                            "exercise_id": exercise_id,
                            "name": ex_name or canon_name,
                            "sets": str(ex.get("sets") or "") or None,
                            "reps": str(ex.get("reps") or "") or None,
                            "duration": str(ex.get("duration") or "") or None,
                            "image_url": image_url,
                            "video_url": video_url,
                            "gif_url": gif_url,
                            "instructions": None,
                        })

                    try:
                        from services.exercise_instructions_resolver import (
                            attach_instructions,
                        )
                        attach_instructions(exercises_out)
                    except Exception as ie:  # noqa: BLE001
                        logger.warning(
                            "schedule: instructions attach failed: %s", ie
                        )

                    days.append({
                        "day_name": (
                            w.get("workout_name") or w.get("name") or f"Day {wi + 1}"
                        ),
                        "workout_type": w.get("type") or w.get("workout_type"),
                        "exercises": exercises_out,
                    })

                out_weeks.append({
                    "week_number": week_num,
                    "phase": wrow.get("phase"),
                    "focus": wrow.get("focus"),
                    "days": days,
                })

            return {
                "variant_id": effective_variant_id,
                "weeks": out_weeks,
            }

        # ── 3. Single-plan fallback (no variant library) ──────────────────────
        # Fetch the program row if we didn't already.
        if program is None:
            presp = (
                db.client.table("programs")
                .select("id, program_name, editorial_name, workouts, difficulty_level")
                .eq("id", program_id)
                .limit(1)
                .execute()
            )
            if not presp.data:
                raise HTTPException(status_code=404, detail="Program not found")
            program = presp.data[0]

        workouts_blob = program.get("workouts") or {}
        if isinstance(workouts_blob, dict):
            raw_workouts = workouts_blob.get("workouts") or []
        else:
            raw_workouts = workouts_blob if isinstance(workouts_blob, list) else []

        days: List[Dict[str, Any]] = []
        for wi, w in enumerate(raw_workouts):
            if not isinstance(w, dict):
                continue
            raw_exercises = w.get("exercises") or []
            exercises_out: List[Dict[str, Any]] = []
            for ex in (raw_exercises if isinstance(raw_exercises, list) else []):
                if not isinstance(ex, dict):
                    continue
                ex_name = (
                    ex.get("exercise_name") or ex.get("name") or ""
                ).strip()
                exercises_out.append({
                    "exercise_id": None,
                    "name": ex_name,
                    "sets": str(ex.get("sets") or "") or None,
                    "reps": str(ex.get("reps") or "") or None,
                    "duration": str(ex.get("duration") or "") or None,
                    "image_url": None,
                    "video_url": None,
                    "gif_url": None,
                    "instructions": None,
                })

            try:
                from services.exercise_instructions_resolver import (
                    attach_instructions,
                )
                attach_instructions(exercises_out)
            except Exception as ie:  # noqa: BLE001
                logger.warning("schedule: instructions attach failed: %s", ie)

            days.append({
                "day_name": w.get("workout_name") or w.get("name") or f"Day {wi + 1}",
                "workout_type": w.get("type"),
                "exercises": exercises_out,
            })

        # Wrap the single plan as week 1 so the response shape is consistent.
        return {
            "variant_id": None,
            "weeks": [
                {
                    "week_number": 1,
                    "phase": None,
                    "focus": None,
                    "days": days,
                }
            ] if days else [],
        }
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to load schedule for %s: %s", program_id, e, exc_info=True
        )
        raise safe_internal_error(e, "program_templates")


def _enumerate_program_exercise_names(db, program_id: str,
                                      variant_id: Optional[str]) -> List[str]:
    """Flat list of every exercise NAME in a program variant (all weeks), or the
    curated single-plan `programs.workouts` blob when there's no variant. Names
    only — the equipment fit-check needs nothing else. Fail-open: [] on error."""
    effective_variant_id = variant_id
    program = None
    if not effective_variant_id:
        presp = (
            db.client.table("programs")
            .select("id, workouts, default_variant_id")
            .eq("id", program_id)
            .limit(1)
            .execute()
        )
        if not presp.data:
            raise HTTPException(status_code=404, detail="Program not found")
        program = presp.data[0]
        default_vid = program.get("default_variant_id")
        if default_vid:
            effective_variant_id = str(default_vid)

    names: List[str] = []

    def _collect(workouts_blob: Any) -> None:
        if not isinstance(workouts_blob, list):
            return
        for w in workouts_blob:
            if not isinstance(w, dict):
                continue
            for ex in (w.get("exercises") or []):
                if not isinstance(ex, dict):
                    continue
                nm = (ex.get("exercise_name") or ex.get("name") or "").strip()
                if nm:
                    names.append(nm)

    if effective_variant_id:
        weeks_resp = (
            db.client.table("program_variant_weeks")
            .select("workouts")
            .eq("variant_id", effective_variant_id)
            .order("week_number", desc=False)
            .execute()
        )
        if weeks_resp.data:
            for wrow in weeks_resp.data:
                _collect(wrow.get("workouts"))
            return names

    # Single-plan fallback (no variant / empty variant).
    if program is None:
        presp = (
            db.client.table("programs")
            .select("id, workouts")
            .eq("id", program_id)
            .limit(1)
            .execute()
        )
        if not presp.data:
            raise HTTPException(status_code=404, detail="Program not found")
        program = presp.data[0]
    blob = program.get("workouts") or {}
    raw = blob.get("workouts") if isinstance(blob, dict) else blob
    _collect(raw)
    return names


@router.get("/library/{program_id}/equipment-coverage")
async def library_program_equipment_coverage(
    program_id: str,
    variant_id: Optional[str] = Query(default=None),
    gym_profile_id: Optional[str] = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    """Pre-flight equipment fit-check for a curated program against a gym profile.

    Compares every exercise the program prescribes (across all variant weeks)
    with the user's available equipment, using the SAME name-token detection the
    assign-time equipment-fit pass uses — so the warning the client shows never
    disagrees with what assignment actually swaps. Read-only, fail-open.

    `gym_profile_id` defaults to the user's active profile. Returns the coverage
    struct from `compute_equipment_coverage` (status / coverage_pct /
    missing_equipment / swappable_count / ...).

    NOTE: registered under the /library/ prefix so it matches before the generic
    @router.get("/{template_id}") catch-all.
    """
    try:
        db = get_supabase()
        user_id = current_user["id"]
        from services.program_customizer import (
            compute_equipment_coverage,
            resolve_profile_equipment,
        )

        names = _enumerate_program_exercise_names(db, program_id, variant_id)
        prof = resolve_profile_equipment(user_id, gym_profile_id)
        coverage = compute_equipment_coverage(
            names,
            prof.get("equipment") or [],
            environment=prof.get("environment"),
        )
        coverage["gym_profile_id"] = prof.get("gym_profile_id")
        return coverage
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed equipment-coverage for %s: %s", program_id, e, exc_info=True
        )
        raise safe_internal_error(e, "program_templates")


class ImportFromProgramRequest(BaseModel):
    """Optional body for POST /from-program/{program_id}.

    All fields are optional so callers that supply no body (the existing
    behaviour) continue to work unchanged.
    """
    variant_id: Optional[str] = Field(
        default=None,
        description="Optional program_variants.id. When supplied, the variant's "
        "week-1 program_variant_weeks rows replace the curated programs.workouts "
        "blob when building the editable template snapshot. Fail-open.",
    )


@router.post("/from-program/{program_id}")
async def import_from_program(
    program_id: str,
    request: Optional[ImportFromProgramRequest] = None,
    current_user: dict = Depends(get_current_user),
):
    """Clone a program into a NEW editable `user_program_templates` row.

    Source-aware: a 'branded:<uuid>' id imports the branded program's week-1
    sessions into the SAME editable template shape (reusing the branded week ->
    days normalizer). If the branded program has no structured weeks to
    normalize, returns 422 {error:'branded_import_unsupported'} rather than
    fabricating workout data. Curated `programs` import is unchanged.

    source='library' (or 'branded'), source_program_id set. The user's copy is
    an independent snapshot - editing it never affects the source or another
    user's copy (#L11/#L12).
    """
    try:
        db = get_supabase()

        # --- Branded import path ------------------------------------------
        if program_id.startswith(_BRANDED_ID_PREFIX):
            branded_id = _strip_branded_prefix(program_id)
            bresp = (
                db.client.table("branded_programs")
                .select("*")
                .eq("id", branded_id)
                .eq("is_active", True)
                .limit(1)
                .execute()
            )
            if not bresp.data:
                raise HTTPException(
                    status_code=404, detail="Program not found"
                )
            branded = bresp.data[0]
            program_name = branded.get("name")
            user_id = str(current_user["id"])
            week_workouts = _fetch_branded_first_week_workouts(
                db, branded_id, program_name or ""
            )
            if not week_workouts:
                # No clean normalizable structure -> be conservative, do NOT
                # fabricate. The client can still START the branded program via
                # the branded /assign flow.
                raise HTTPException(
                    status_code=422,
                    detail={
                        "error": "branded_import_unsupported",
                        "message": "This program can't be imported as an "
                        "editable template yet. You can still start it.",
                    },
                )
            resolver = ExerciseResolver(user_id=user_id)
            days = _branded_week_workouts_to_days(
                week_workouts,
                difficulty_level=branded.get("difficulty_level"),
                resolver=resolver,
            )
            category = branded.get("category")
            now = datetime.utcnow().isoformat()
            insert_row = {
                "id": str(uuid.uuid4()),
                "user_id": user_id,
                "name": program_name or "Imported Program",
                "description": (
                    branded.get("description") or branded.get("tagline")
                ),
                "week_length": max(7, len(days)),
                "days": days,
                "deload_every_n_weeks": derive_deload_every_n(category),
                "progression_strategy": derive_progression_strategy(category),
                "apply_staples": True,
                # source_program_id is a uuid column -> store the bare uuid; the
                # 'branded' source field records which catalog it came from.
                "source": "branded",
                "source_program_id": branded_id,
                "category": branded_category_label(category),
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

        # --- Curated `programs` import path (unchanged, + optional variant) --
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
        import_days = normalized["days"]

        # Variant override: substitute days from program_variant_weeks week 1.
        import_variant_id = (request.variant_id if request else None)
        if import_variant_id:
            try:
                w1_resp = (
                    db.client.table("program_variant_weeks")
                    .select("workouts")
                    .eq("variant_id", import_variant_id)
                    .eq("week_number", 1)
                    .limit(1)
                    .execute()
                )
                w1_rows = w1_resp.data or []
                if w1_rows:
                    raw_wkts = w1_rows[0].get("workouts") or []
                    if isinstance(raw_wkts, list) and raw_wkts:
                        variant_import_days: List[Dict[str, Any]] = []
                        for wkt in raw_wkts:
                            if not isinstance(wkt, dict):
                                continue
                            exercises = [
                                {
                                    "name": (
                                        ex.get("exercise_name") or ex.get("name") or ""
                                    ),
                                    "sets": ex.get("sets"),
                                    "reps": ex.get("reps"),
                                    "duration": ex.get("duration"),
                                }
                                for ex in (wkt.get("exercises") or [])
                                if isinstance(ex, dict)
                            ]
                            variant_import_days.append({
                                "name": wkt.get("workout_name") or wkt.get("name") or "",
                                "exercises": exercises,
                            })
                        if variant_import_days:
                            import_days = variant_import_days
            except Exception as vie:  # noqa: BLE001 — fail-open
                logger.warning(
                    "import_from_program: variant %s week-1 lookup failed, "
                    "falling back to single plan: %s", import_variant_id, vie
                )

        now = datetime.utcnow().isoformat()
        insert_row = {
            "id": str(uuid.uuid4()),
            "user_id": user_id,
            "name": normalized["name"],
            "description": normalized.get("description"),
            "week_length": normalized["week_length"],
            "days": import_days,
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
        user_id = str(current_user["id"])
        # Resolve fitness level / goal / equipment / injuries so the parse can
        # tailor exercise selection + run the injury-safety pass.
        from services.program_customizer import resolve_user_context
        try:
            uctx = resolve_user_context(user_id)
            # Hydrate primary_goal too (not part of customizer's context).
            try:
                gres = (
                    get_supabase().client.table("users")
                    .select("primary_goal")
                    .eq("id", user_id).limit(1).execute()
                )
                if gres.data:
                    uctx["primary_goal"] = gres.data[0].get("primary_goal")
            except Exception:  # noqa: BLE001
                pass
        except Exception:  # noqa: BLE001
            uctx = None
        parsed = await parse_to_template_json(
            request.description,
            user_id=user_id,
            weeks=request.weeks,
            user_context=uctx,
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
# Import from photo / PDF (Gemini Vision)
# =============================================================================
class ImportPhotoRequest(BaseModel):
    """A photo/screenshot/PDF of a program. Provide EITHER image_base64 (+ mime)
    OR an s3_key. PDFs are accepted (mime_type='application/pdf')."""
    image_base64: Optional[str] = None
    mime_type: str = "image/jpeg"
    s3_key: Optional[str] = None
    weeks: Optional[int] = Field(default=None, ge=1)


@router.post("/import-photo")
async def import_program_from_photo(
    request: ImportPhotoRequest,
    current_user: dict = Depends(get_current_user),
):
    """Vision-parse a photo / screenshot / PDF of a workout program into an
    editable draft template (source='imported'). Does NOT persist — the client
    reviews/edits then POSTs to `/`.

    Returns the same shape as /parse. 422 {error:'not_a_program'} when the image
    isn't a program; 422 {error:'parse_error'} on a vision failure.
    """
    import base64 as _b64
    try:
        user_id = str(current_user["id"])

        # Resolve image bytes from base64 or S3.
        if request.image_base64:
            try:
                image_bytes = _b64.b64decode(request.image_base64)
            except Exception:
                raise HTTPException(
                    status_code=422,
                    detail={"error": "parse_error", "message": "Invalid image data"},
                )
            mime_type = request.mime_type or "image/jpeg"
        elif request.s3_key:
            from services.s3_service import get_s3_service
            try:
                image_bytes = await asyncio.to_thread(
                    get_s3_service().download_bytes, request.s3_key
                )
            except Exception as se:  # noqa: BLE001
                logger.error("import-photo: S3 download failed: %s", se)
                raise HTTPException(
                    status_code=422,
                    detail={"error": "parse_error",
                            "message": "Could not read the uploaded file"},
                )
            # Infer mime from the key extension; default to jpeg, pdf for .pdf.
            key_lc = request.s3_key.lower()
            if key_lc.endswith(".pdf"):
                mime_type = "application/pdf"
            elif key_lc.endswith(".png"):
                mime_type = "image/png"
            else:
                mime_type = request.mime_type or "image/jpeg"
        else:
            raise HTTPException(
                status_code=422,
                detail={"error": "parse_error",
                        "message": "Provide image_base64 or s3_key"},
            )

        # Resolve user context (level / goal / equipment / injuries).
        from services.program_customizer import resolve_user_context
        try:
            uctx = resolve_user_context(user_id)
        except Exception:  # noqa: BLE001
            uctx = None

        from services.program_template_parser import parse_program_from_image
        parsed = await parse_program_from_image(
            image_bytes=image_bytes,
            mime_type=mime_type,
            user_id=user_id,
            weeks=request.weeks,
            user_context=uctx,
        )
        return parsed
    except HTTPException:
        raise
    except ValueError as ve:
        msg = str(ve)
        if msg.startswith("not_a_program"):
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "not_a_program",
                    "message": msg.split(":", 1)[-1].strip()
                    or "This image doesn't look like a workout program",
                },
            )
        raise HTTPException(
            status_code=422,
            detail={"error": "parse_error",
                    "message": "Could not read the program from this image. "
                    "Try a clearer photo or the manual builder."},
        )
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to import program from photo: %s", e, exc_info=True)
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
            "notes": request.notes,
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


# =============================================================================
# Assign / Start a published program  (Program Library integration)
# =============================================================================
def _published_program_or_404(db, program_id: str) -> Dict[str, Any]:
    """Fetch a PUBLISHED, importable `programs` row or raise 404/422.

    Only is_published=true rows are startable from the library (curated set).
    A metadata-only program (empty workouts) is 422 — never fabricated.
    """
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
    if not program.get("is_published"):
        raise HTTPException(
            status_code=404,
            detail="This program is not available to start",
        )
    if not _has_workouts(program):
        raise HTTPException(
            status_code=422,
            detail="This program has no structured workouts to start",
        )
    return program


def _program_display_name(program: Dict[str, Any]) -> str:
    return (
        program.get("editorial_name")
        or program.get("program_name")
        or "Program"
    )


def _assignment_to_dict(
    row: Dict[str, Any],
    *,
    display_name: Optional[str] = None,
    duration_weeks: Optional[int] = None,
) -> Dict[str, Any]:
    """Normalize a user_program_assignments row for the API. display_name +
    duration_weeks are resolved by the caller (template/program lookups)."""
    return {
        "id": str(row["id"]),
        "user_id": str(row["user_id"]),
        "template_id": (
            str(row["template_id"]) if row.get("template_id") else None
        ),
        "source_program_id": (
            str(row["source_program_id"])
            if row.get("source_program_id") else None
        ),
        "branded_program_id": (
            str(row["branded_program_id"])
            if row.get("branded_program_id") else None
        ),
        "custom_program_name": row.get("custom_program_name"),
        "display_name": display_name or row.get("custom_program_name"),
        "assigned_days": row.get("assigned_days") or [],
        "slot": row.get("slot") or "primary",
        "status": row.get("status"),
        "is_active": row.get("is_active", False),
        "current_week": row.get("current_week", 1),
        "duration_weeks": duration_weeks,
        "total_workouts": row.get("total_workouts"),
        "workouts_completed": row.get("workouts_completed", 0),
        "progress_percentage": row.get("progress_percentage", 0),
        "started_at": (
            str(row["started_at"]) if row.get("started_at") else None
        ),
        "completed_at": (
            str(row["completed_at"]) if row.get("completed_at") else None
        ),
    }


async def _clear_today_cache(user_id: str) -> None:
    """Fire the /today cache-clear chokepoint after a schedule change. Imported
    lazily to avoid a heavy import at module load + circulars."""
    try:
        from api.v1.workouts.today import invalidate_today_workout_cache
        await invalidate_today_workout_cache(user_id)
    except Exception as e:  # noqa: BLE001
        logger.warning("today cache invalidation failed: %s", e)


def _purge_superseded_ghost_workouts(
    db, user_id: str, assignment_id: str,
    superseded_assignment_ids: List[str],
) -> None:
    """Delete an abandoned primary's future INCOMPLETE workouts on dates the new
    primary does NOT cover (orphan cleanup on program switch). Keeps the old rows
    on dates the new program scheduled (intentional 'add alongside' days) and
    never touches completed/past history. Fail-soft. Shared by the synchronous
    assign path and the deferred background continuation."""
    if not superseded_assignment_ids:
        return
    try:
        b_dates = set()
        b_rows = (
            db.client.table("workouts")
            .select("scheduled_date")
            .eq("assignment_id", assignment_id)
            .eq("user_id", user_id)
            .execute()
        )
        for r in (b_rows.data or []):
            sd = str(r.get("scheduled_date") or "")[:10]
            if sd:
                b_dates.add(sd)
        old_rows = (
            db.client.table("workouts")
            .select("id, scheduled_date")
            .in_("assignment_id", superseded_assignment_ids)
            .eq("user_id", user_id)
            .eq("is_completed", False)
            .execute()
        )
        ghost_ids = [
            r["id"]
            for r in (old_rows.data or [])
            if str(r.get("scheduled_date") or "")[:10] not in b_dates
        ]
        if ghost_ids:
            db.client.table("workouts").delete().in_(
                "id", [str(x) for x in ghost_ids]
            ).execute()
            logger.info(
                "supersede: purged %d ghost workouts from %d abandoned "
                "primary assignment(s)",
                len(ghost_ids), len(superseded_assignment_ids),
            )
    except Exception as e:  # noqa: BLE001
        logger.warning("supersede ghost purge failed: %s", e)


async def _finish_program_expansion(
    *,
    user_id: str,
    weeks_rows_remaining: List[Dict[str, Any]],
    template: Dict[str, Any],
    schedule_id: str,
    start_date: date,
    assigned_days: List[int],
    gym_profile_id: Optional[str],
    assignment_id: str,
    slot: str,
    replace: bool,
    day_resolutions: Dict[str, str],
    customize: Optional[CustomizeOptions],
    customize_context: Any,
    superseded_assignment_ids: List[str],
    week1_created: int,
) -> None:
    """Background continuation of assign_program_core: AI-tailor + expand the
    program's weeks 2..N, then purge superseded ghosts, correct total_workouts
    and re-clear the /today cache. Fully isolated (its own db handle) and
    best-effort — a failure leaves the user with a usable, already-live week 1
    and is logged loudly (weeks 2..N would then be missing until a re-assign)."""
    try:
        db = get_supabase()
        # Tailor weeks 2..N with the same resolved context as week 1 (best-effort;
        # a tailoring failure just ships the standard plan for those weeks).
        if customize is not None and weeks_rows_remaining:
            from services.program_customizer import customize_template_days
            try:
                flat = [
                    s
                    for w in weeks_rows_remaining
                    for s in (w.get("workouts") or [])
                    if isinstance(s, dict)
                ]
                if flat:
                    await customize_template_days(
                        flat,
                        user_id=user_id,
                        adapt_to_level=customize.adapt_to_level,
                        swap_for_injuries=customize.swap_for_injuries,
                        fit_equipment=customize.fit_equipment,
                        context=customize_context,
                    )
            except Exception as ce:  # noqa: BLE001
                logger.warning(
                    "deferred tailoring failed (standard plan for weeks 2..N): %s",
                    ce,
                )
        result = expand_variant_weeks(
            weeks_rows=weeks_rows_remaining,
            template=template,
            schedule_id=schedule_id,
            user_id=user_id,
            start_date=start_date,
            assigned_days=assigned_days,
            gym_profile_id=gym_profile_id,
            assignment_id=assignment_id,
            program_slot=slot,
            apply_staples=True,
            replace=replace,
            day_resolutions=day_resolutions,
            resolve_collisions=True,
        )
        _purge_superseded_ghost_workouts(
            db, user_id, assignment_id, superseded_assignment_ids
        )
        try:
            db.client.table("user_program_assignments").update(
                {"total_workouts": week1_created + result["workouts_created"]}
            ).eq("id", assignment_id).execute()
        except Exception as e:  # noqa: BLE001
            logger.debug("deferred total_workouts update skipped: %s", e)
        # Re-clear /today so the freshly-created weeks 2..N surface immediately.
        await _clear_today_cache(user_id)
        logger.info(
            "deferred expansion done for assignment %s: +%d workouts (weeks 2..N)",
            assignment_id, result["workouts_created"],
        )
    except Exception as e:  # noqa: BLE001
        logger.error(
            "deferred program expansion FAILED for assignment %s "
            "(week 1 is live; weeks 2..N missing until re-assign): %s",
            assignment_id, e, exc_info=True,
        )


async def assign_program_core(
    db,
    *,
    user_id: str,
    program_id: str,
    assigned_days: List[int],
    slot: str,
    start_date: Optional[date],
    replace: bool,
    duration_weeks: Optional[int],
    customize: Optional[CustomizeOptions],
    variant_id: Optional[str] = None,
    day_resolutions: Optional[Dict[str, str]] = None,
    background_tasks: Optional[BackgroundTasks] = None,
) -> Dict[str, Any]:
    """Shared Start-a-program logic used by the HTTP endpoint AND the coach
    `assign_program` tool. Returns the response dict.

    When [background_tasks] is supplied AND the program is a multi-week VARIANT
    program, only WEEK 1 is expanded (and AI-tailored) synchronously so Start
    returns in ~1s with this week's workouts ready; weeks 2..N (+ their tailoring,
    ghost-purge and final count) finish in a background task a beat later. The
    coach tool passes no background_tasks → the full synchronous path runs
    unchanged. The base-blob path is never deferred (its deload-by-week-index
    scheduling can't be safely split across two expander calls).

    `day_resolutions` ({ISO date → 'replace' | 'add'}) is an optional per-day
    conflict override threaded into the expander so a colliding date is either
    replaced (existing workout removed) or stacked (new tagged 'addon'),
    matching the assign-preview the user confirmed.

    Steps: validate published program -> clone to user_program_template (with
    optional customization of days) -> end overlapping active primaries (replace)
    -> insert assignment -> expand dated workouts tagged with assignment_id +
    slot -> clear /today cache.

    When variant_id is supplied: attempt to build `days` from
    program_variant_weeks (week 1 only for the template snapshot — the full
    multi-week schedule is stored in the assignment's weekly expansion).
    Any variant lookup error falls back silently to the single-plan path.
    """
    slot = (slot or "primary").strip().lower()
    if slot not in ("primary", "addon"):
        raise HTTPException(
            status_code=422, detail="slot must be 'primary' or 'addon'"
        )

    program = _published_program_or_404(db, program_id)
    display_name = _program_display_name(program)

    # Resolve duration: explicit override > program.duration_weeks > 8, capped.
    weeks = duration_weeks or program.get("duration_weeks") or 8
    weeks = max(1, min(int(weeks), MAX_WEEKS))

    start = start_date or date.today()

    # --- 1. Clone the programs row into an editable user template ----------
    normalized = normalize_program_blob_for_preview(program, user_id=user_id)
    days = normalized["days"]

    # --- 1b. Variant override: substitute days from program_variant_weeks ----
    # Only week 1 is used for the template snapshot; the full multi-week
    # expansion is handled by the assignment's dated-workout expander which
    # already knows to call the schedule endpoint per-week.
    if variant_id:
        try:
            w1_resp = (
                db.client.table("program_variant_weeks")
                .select("workouts")
                .eq("variant_id", variant_id)
                .eq("week_number", 1)
                .limit(1)
                .execute()
            )
            w1_rows = w1_resp.data or []
            if w1_rows:
                raw_workouts = w1_rows[0].get("workouts") or []
                if isinstance(raw_workouts, list) and raw_workouts:
                    # Normalize to days shape: [{name, exercises:[...]}]
                    variant_days: List[Dict[str, Any]] = []
                    for w in raw_workouts:
                        if not isinstance(w, dict):
                            continue
                        raw_exercises = w.get("exercises") or []
                        exercises = []
                        for ex in (raw_exercises if isinstance(raw_exercises, list) else []):
                            if isinstance(ex, dict):
                                exercises.append({
                                    "name": (
                                        ex.get("exercise_name")
                                        or ex.get("name")
                                        or ""
                                    ),
                                    "sets": ex.get("sets"),
                                    "reps": ex.get("reps"),
                                    "duration": ex.get("duration"),
                                })
                        variant_days.append({
                            "name": (
                                w.get("workout_name") or w.get("name") or ""
                            ),
                            "exercises": exercises,
                        })
                    if variant_days:
                        days = variant_days
                        logger.debug(
                            "assign_program_core: using variant %s week-1 days "
                            "(%d days)", variant_id, len(days)
                        )
        except Exception as ve:  # noqa: BLE001 — fail-open
            logger.warning(
                "assign_program_core: variant %s week-1 lookup failed, "
                "falling back to single plan: %s", variant_id, ve
            )

    # --- 2. Customize the cloned days (injury / equipment / level) ---------
    # Resolve the schedulable variant ONCE up front — both the AI-tailor pass
    # and the expansion below schedule from its real per-week sessions.
    _eff_vid, _weeks_rows = _resolve_variant_weeks(db, program_id, variant_id)

    # A resolved variant is AUTHORITATIVE for the schedule shape. Its week rows
    # drive the real expansion (expand_variant_weeks below) AND its session count
    # is whatever the variant's weeks contain — so the reported/stored duration
    # must come from the variant, NOT the program-default duration_weeks computed
    # above. Otherwise picking e.g. the HYROX 8wk×5/week variant while the
    # program default is 8wk×4/week would schedule the variant correctly but
    # label the template/assignment/response with the wrong week count and
    # diverge from assign-preview (which derives weeks from plan_variant_schedule
    # → weeks_used). min(len, MAX_WEEKS) matches the planner's [:max_weeks] slice.
    if _weeks_rows:
        weeks = max(1, min(len(_weeks_rows), MAX_WEEKS))

    # Defer weeks 2..N to a background task when we can (variant program, >1
    # week, and a BackgroundTasks to run it on). This controls how much we tailor
    # synchronously — only week 1 when deferring.
    defer_expansion = (
        background_tasks is not None
        and bool(_weeks_rows)
        and len(_weeks_rows) > 1
    )

    customize_summary: Optional[Dict[str, Any]] = None
    _customize_ctx = None  # reused by the deferred weeks-2..N tailoring
    if customize is not None:
        from services.program_customizer import (
            customize_status,
            customize_template_days,
            resolve_user_context,
        )
        try:
            if _weeks_rows:
                # Variant program: tailor the REAL per-week sessions (injuries /
                # equipment / level) with a single resolved context. Sessions are
                # mutated in place inside _weeks_rows, so expand_variant_weeks
                # schedules the tailored set. When deferring, tailor only week 1
                # now (fast); the bg task tailors weeks 2..N with the same ctx.
                _customize_ctx = resolve_user_context(user_id)
                _tailor_rows = _weeks_rows[:1] if defer_expansion else _weeks_rows
                flat_sessions = [
                    s
                    for wrow in _tailor_rows
                    for s in (wrow.get("workouts") or [])
                    if isinstance(s, dict)
                ]
                customize_summary = await customize_template_days(
                    flat_sessions,
                    user_id=user_id,
                    adapt_to_level=customize.adapt_to_level,
                    swap_for_injuries=customize.swap_for_injuries,
                    fit_equipment=customize.fit_equipment,
                    context=_customize_ctx,
                )
            else:
                customize_summary = await customize_template_days(
                    days,
                    user_id=user_id,
                    adapt_to_level=customize.adapt_to_level,
                    swap_for_injuries=customize.swap_for_injuries,
                    fit_equipment=customize.fit_equipment,
                )
            # Stamp whether the tailoring actually changed anything, so the client
            # can confirm it honestly ("swapped 2 …") vs say nothing was needed —
            # instead of silently showing a generic "started" with no signal.
            customize_summary["status"] = customize_status(customize_summary)
        except Exception as ce:  # noqa: BLE001 — never block Start on customize
            logger.warning(
                "assign customize failed (using uncustomized plan): %s", ce
            )
            # Report the failure explicitly (was silently None) so the client can
            # say "couldn't tailor — started with the standard plan" rather than
            # leaving the user believing it applied. No silent degradation.
            customize_summary = {"status": "failed"}

    now = datetime.utcnow().isoformat()
    template_id = str(uuid.uuid4())
    template_row = {
        "id": template_id,
        "user_id": user_id,
        "name": display_name,
        "description": normalized.get("description"),
        "week_length": normalized["week_length"],
        "days": days,
        "deload_every_n_weeks": normalized["deload_every_n_weeks"],
        "progression_strategy": normalized["progression_strategy"],
        "apply_staples": True,
        "source": "library",
        "source_program_id": program_id,
        "category": normalized.get("category"),
        "duration_weeks": weeks,
        "created_at": now,
        "updated_at": now,
    }
    created_tpl = (
        db.client.table("user_program_templates")
        .insert(template_row)
        .execute()
    )
    if not created_tpl.data:
        raise HTTPException(status_code=500, detail="Failed to create template")
    template = created_tpl.data[0]

    # --- 3. End overlapping active PRIMARY assignments --------------------
    # A new PRIMARY program ends any prior active primary whose days overlap,
    # REGARDLESS of the global `replace` flag. The per-day `day_resolutions`
    # map governs per-DATE workout collisions (replace vs stack); the
    # assignment-level "one primary program per overlapping day" invariant is
    # separate. The old `and replace` gate meant the new per-day Start flow
    # (which sends replace=False and resolves conflicts per day) never
    # superseded the prior primary, leaving DUPLICATE active primaries
    # (e.g. a failed-then-retried Start stacked two active assignments).
    # Disjoint-day primaries still coexist (the merged multi-program model).
    superseded_assignment_ids: List[str] = []
    if slot == "primary":
        try:
            existing = (
                db.client.table("user_program_assignments")
                .select("id, assigned_days")
                .eq("user_id", user_id)
                .eq("is_active", True)
                .eq("slot", "primary")
                .execute()
            )
            new_days = set(int(d) for d in (assigned_days or []))
            for ex in existing.data or []:
                ex_days = set(int(d) for d in (ex.get("assigned_days") or []))
                # No assigned_days on either side => treat as a full overlap so
                # a "replace" Start always supersedes the prior primary.
                overlaps = (
                    not new_days or not ex_days or bool(new_days & ex_days)
                )
                if overlaps:
                    db.client.table("user_program_assignments").update(
                        {
                            "is_active": False,
                            "status": "abandoned",
                            "updated_at": now,
                        }
                    ).eq("id", ex["id"]).execute()
                    superseded_assignment_ids.append(str(ex["id"]))
        except Exception as e:  # noqa: BLE001
            logger.warning("primary supersede failed: %s", e)

    # --- 4. Insert the assignment row --------------------------------------
    assignment_id = str(uuid.uuid4())
    assignment_row = {
        "id": assignment_id,
        "user_id": user_id,
        "template_id": template_id,
        "source_program_id": program_id,
        "custom_program_name": display_name,
        "assigned_days": list(assigned_days or []),
        "slot": slot,
        "is_active": True,
        "status": "active",
        "current_week": 1,
        "started_at": now,
    }
    created_asgmt = (
        db.client.table("user_program_assignments")
        .insert(assignment_row)
        .execute()
    )
    if not created_asgmt.data:
        raise HTTPException(
            status_code=500, detail="Failed to create assignment"
        )
    assignment = created_asgmt.data[0]

    # --- 5. Schedule + expand into concrete dated workouts -----------------
    gym_profile_id = _resolve_active_gym_profile(db, user_id)
    schedule_id = str(uuid.uuid4())
    day_alignment = "calendar_weekday" if assigned_days else "start_today"
    try:
        db.client.table("user_program_schedules").insert(
            {
                "id": schedule_id,
                "template_id": template_id,
                "user_id": user_id,
                "start_date": start.isoformat(),
                "weeks": weeks,
                "day_alignment": day_alignment,
                "day_times": {},
            }
        ).execute()
    except Exception as e:  # noqa: BLE001
        logger.warning("schedule row insert failed (continuing): %s", e)

    # Curated multi-week programs store their REAL per-week plan in
    # program_variant_weeks — schedule from that so each calendar week gets its
    # own sessions (and flattened-blob programs like HYROX don't blow the cap).
    # Normal programs with no variant library fall back to the base-blob expand.
    # _weeks_rows was resolved + AI-tailored above.
    if defer_expansion:
        # Synchronously expand WEEK 1 only so this week's workouts are ready
        # immediately; weeks 2..N (+ tailoring, ghost purge, final count) finish
        # in the background. plan_variant_schedule dates weeks by POSITION, and
        # +7d preserves the weekday, so the week-2 row scheduled from start+7
        # lands exactly where week 2 would under a full single-call expansion.
        result = expand_variant_weeks(
            weeks_rows=_weeks_rows[:1],
            template=template,
            schedule_id=schedule_id,
            user_id=user_id,
            start_date=start,
            assigned_days=list(assigned_days or []),
            gym_profile_id=gym_profile_id,
            assignment_id=assignment_id,
            program_slot=slot,
            apply_staples=True,
            replace=replace,
            day_resolutions=day_resolutions or {},
            resolve_collisions=True,
        )
        expected_total = sum(
            len([s for s in (w.get("workouts") or []) if isinstance(s, dict)])
            for w in _weeks_rows
        )
        # Pre-set total_workouts to the full expected count so the assignment
        # reads complete before the bg fill lands (the bg task corrects it).
        try:
            db.client.table("user_program_assignments").update(
                {"total_workouts": expected_total}
            ).eq("id", assignment_id).execute()
        except Exception as e:  # noqa: BLE001
            logger.debug("total_workouts (deferred pre-set) skipped: %s", e)
        background_tasks.add_task(
            _finish_program_expansion,
            user_id=user_id,
            weeks_rows_remaining=_weeks_rows[1:],
            template=template,
            schedule_id=schedule_id,
            start_date=start + timedelta(weeks=1),
            assigned_days=list(assigned_days or []),
            gym_profile_id=gym_profile_id,
            assignment_id=assignment_id,
            slot=slot,
            replace=replace,
            day_resolutions=day_resolutions or {},
            customize=customize,
            customize_context=_customize_ctx,
            superseded_assignment_ids=superseded_assignment_ids,
            week1_created=result["workouts_created"],
        )
        # Report the FULL program count so the client's "N workouts added" toast
        # is honest about what the user is getting.
        result["workouts_created"] = expected_total
    else:
        # Full synchronous expansion: variant all-weeks, or the base-blob path.
        # _weeks_rows was resolved + AI-tailored above.
        if _weeks_rows:
            result = expand_variant_weeks(
                weeks_rows=_weeks_rows,
                template=template,
                schedule_id=schedule_id,
                user_id=user_id,
                start_date=start,
                assigned_days=list(assigned_days or []),
                gym_profile_id=gym_profile_id,
                assignment_id=assignment_id,
                program_slot=slot,
                apply_staples=True,
                replace=replace,
                day_resolutions=day_resolutions or {},
                resolve_collisions=True,
            )
        else:
            result = expand_template(
                template=template,
                schedule_id=schedule_id,
                user_id=user_id,
                start_date=start,
                weeks=weeks,
                day_alignment=day_alignment,
                day_times={},
                gym_profile_id=gym_profile_id,
                assignment_id=assignment_id,
                program_slot=slot,
                assigned_days=list(assigned_days or []),
                replace=replace,
                day_resolutions=day_resolutions or {},
                resolve_collisions=True,
            )

        # Purge ghost workouts from any superseded primary (the old program's
        # future incomplete workouts on dates the new program does NOT cover).
        # The deferred path runs this in the bg task once all weeks exist.
        _purge_superseded_ghost_workouts(
            db, user_id, assignment_id, superseded_assignment_ids
        )

        # Record total_workouts now that we know the count.
        try:
            db.client.table("user_program_assignments").update(
                {"total_workouts": result["workouts_created"]}
            ).eq("id", assignment_id).execute()
        except Exception as e:  # noqa: BLE001
            logger.debug("total_workouts update skipped: %s", e)

    # --- 6. Clear /today cache (chokepoint) --------------------------------
    await _clear_today_cache(user_id)

    # sessions_per_week — from the CHOSEN variant's busiest week when scheduling
    # from program_variant_weeks (authoritative, matches the preview); else the
    # base-blob template's non-rest day count. Surfaced so the client can verify
    # assign == assign-preview after a non-default frequency pick.
    if _weeks_rows:
        # Mirror plan_variant_schedule's per-week session count (dict-only) so
        # this equals the preview's sessions_per_week exactly.
        sessions_per_week = max(
            (
                len([s for s in (w.get("workouts") or []) if isinstance(s, dict)])
                for w in _weeks_rows
            ),
            default=0,
        )
    else:
        sessions_per_week = len(
            [d for d in (days or []) if not d.get("is_rest")]
        )

    response: Dict[str, Any] = {
        "success": True,
        "assignment_id": assignment_id,
        "template_id": template_id,
        "program_id": program_id,
        "program_name": display_name,
        "slot": slot,
        "assigned_days": list(assigned_days or []),
        "duration_weeks": weeks,
        "sessions_per_week": sessions_per_week,
        "workouts_created": result["workouts_created"],
        "skipped_existing": result["skipped_existing"],
        "superseded_existing": result.get("superseded_existing", 0),
        "assignment": _assignment_to_dict(
            assignment, display_name=display_name, duration_weeks=weeks
        ),
    }
    if customize_summary is not None:
        response["customize_summary"] = customize_summary
    return response


@router.post("/assign")
async def assign_program(
    request: AssignProgramRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Start a published library program for the authenticated user.

    Clones -> (optionally) customizes -> creates an assignment -> expands dated
    workouts tagged with the assignment + slot -> clears /today cache. For
    multi-week variant programs only WEEK 1 is expanded synchronously (so this
    returns in ~1s with the current week ready); weeks 2..N finish in a
    background task. Safe to retry: a re-fired expansion dedupes on the
    template-slot unique index, but a retry creates a NEW template/assignment
    (idempotency is per-call, not cross-call — the client should not auto-retry
    a 2xx).
    """
    try:
        db = get_supabase()
        return await assign_program_core(
            db,
            user_id=str(current_user["id"]),
            program_id=request.program_id,
            assigned_days=request.assigned_days,
            slot=request.slot,
            start_date=request.start_date,
            replace=request.replace,
            duration_weeks=request.duration_weeks,
            customize=request.customize,
            variant_id=request.variant_id,
            day_resolutions=request.day_resolutions,
            background_tasks=background_tasks,
        )
    except HTTPException:
        raise
    except ValueError as ve:
        raise HTTPException(status_code=422, detail=str(ve))
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to assign program: %s", e, exc_info=True)
        raise safe_internal_error(e, "program_templates")


# =============================================================================
# Assign PREVIEW (dry-run) + AI review — show what Start would schedule before
# the user commits. The preview reuses the EXACT date planner expand_template
# writes with (plan_template_days) so it can never drift from reality.
# =============================================================================
_WEEKDAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


def _resolve_variant_weeks(
    db, program_id: str, variant_id: Optional[str]
) -> tuple:
    """Resolve the schedulable VARIANT for a curated program → its per-week
    program_variant_weeks (the real source the program-detail schedule reads).
    effective = explicit variant_id, else programs.default_variant_id.
    Returns (effective_variant_id, weeks_rows) or (None, []) when the program
    has no variant library (then callers fall back to the base-blob path)."""
    effective = variant_id
    if not effective:
        try:
            pr = (
                db.client.table("programs")
                .select("default_variant_id")
                .eq("id", program_id)
                .limit(1)
                .execute()
            )
            if pr.data:
                effective = pr.data[0].get("default_variant_id")
        except Exception as e:  # noqa: BLE001
            logger.warning("default_variant_id lookup failed: %s", e)
    if not effective:
        return None, []
    try:
        wks = (
            db.client.table("program_variant_weeks")
            .select("week_number, workouts")
            .eq("variant_id", effective)
            .order("week_number", desc=False)
            .execute()
        )
        rows = wks.data or []
        return (str(effective) if rows else None), rows
    except Exception as e:  # noqa: BLE001
        logger.warning("variant weeks lookup failed for %s: %s", effective, e)
        return None, []


def _resolve_program_days_for_preview(
    db, *, program_id: str, variant_id: Optional[str], user_id: str
) -> Dict[str, Any]:
    """Resolve the in-memory `days` blob + metadata for a program WITHOUT
    cloning a template. Mirrors assign_program_core steps 1-1b (normalize +
    optional variant week-1 override). No DB writes."""
    program = _published_program_or_404(db, program_id)
    display_name = _program_display_name(program)
    normalized = normalize_program_blob_for_preview(program, user_id=user_id)
    days = normalized["days"]

    if variant_id:
        try:
            w1_resp = (
                db.client.table("program_variant_weeks")
                .select("workouts")
                .eq("variant_id", variant_id)
                .eq("week_number", 1)
                .limit(1)
                .execute()
            )
            w1_rows = w1_resp.data or []
            if w1_rows:
                raw_workouts = w1_rows[0].get("workouts") or []
                if isinstance(raw_workouts, list) and raw_workouts:
                    variant_days: List[Dict[str, Any]] = []
                    for idx, w in enumerate(raw_workouts):
                        if not isinstance(w, dict):
                            continue
                        raw_ex = w.get("exercises") or []
                        exercises = [
                            {"name": ex.get("exercise_name") or ex.get("name") or ""}
                            for ex in (raw_ex if isinstance(raw_ex, list) else [])
                            if isinstance(ex, dict)
                        ]
                        variant_days.append({
                            "day_index": idx,
                            "day_name": w.get("workout_name") or w.get("name") or "",
                            "is_rest": len(exercises) == 0,
                            "workout_type": w.get("type") or "strength",
                            "exercises": exercises,
                        })
                    if variant_days:
                        days = variant_days
        except Exception as ve:  # noqa: BLE001 — fail-open, mirror assign
            logger.warning(
                "preview variant %s week-1 lookup failed: %s", variant_id, ve
            )

    return {
        "program": program,
        "display_name": display_name,
        "normalized": normalized,
        "days": days,
    }


def _resolve_training_weekdays(
    db, user_id: str, gym_profile_id: Optional[str]
) -> set:
    """Best-effort set of weekdays (Mon=0..Sun=6) the user already trains on per
    their preferences — used to flag program dates that land on a day the AI
    would otherwise have generated a workout (those future AI workouts are not
    materialized rows yet). Fail-open: empty set on any lookup miss."""
    def _coerce(v) -> set:
        out = set()
        for d in (v or []):
            try:
                di = int(d)
                if 0 <= di <= 6:
                    out.add(di)
            except (TypeError, ValueError):
                continue
        return out

    # Active gym profile takes precedence (it scopes the live schedule).
    if gym_profile_id:
        for table in ("gym_profiles", "user_gym_profiles"):
            try:
                resp = (
                    db.client.table(table).select("*")
                    .eq("id", gym_profile_id).limit(1).execute()
                )
                if resp.data:
                    row = resp.data[0]
                    days = _coerce(row.get("workout_days") or row.get("training_days"))
                    if days:
                        return days
            except Exception:  # noqa: BLE001
                continue
    # Fall back to the user-level preference.
    try:
        resp = (
            db.client.table("users").select("*")
            .eq("id", user_id).limit(1).execute()
        )
        if resp.data:
            return _coerce(
                resp.data[0].get("workout_days")
                or resp.data[0].get("training_days")
            )
    except Exception:  # noqa: BLE001
        pass
    return set()


async def _build_assign_preview(
    db, *, user_id: str, req: "AssignPreviewRequest"
) -> Dict[str, Any]:
    """Compute the dated schedule + collisions a Start would create. No writes."""
    slot = (req.slot or "primary").strip().lower()
    if slot not in ("primary", "addon"):
        raise HTTPException(
            status_code=422, detail="slot must be 'primary' or 'addon'"
        )

    start = req.start_date or date.today()
    assigned_days = list(req.assigned_days or [])

    # Unified per-day plan: {week_number, target_date, weekday, session_name,
    # workout_type, exercises_count, is_deload}. Built from the variant weeks
    # (fast, correct, matches assign) when the program has a variant library;
    # else from the base-blob template path (normal weekly programs).
    pdays: List[Dict[str, Any]] = []
    _eff_vid, _weeks_rows = _resolve_variant_weeks(
        db, req.program_id, req.variant_id
    )
    if _weeks_rows:
        # Fast path — NO normalize/ExerciseResolver.
        prog = _published_program_or_404(db, req.program_id)
        display_name = _program_display_name(prog)
        plan = plan_variant_schedule(
            _weeks_rows, assigned_days=assigned_days, start_date=start
        )
        for p in plan["planned"]:
            sess = p["session"]
            pdays.append({
                "week_number": p["week_number"],
                "target_date": p["target_date"],
                "weekday": p["weekday"],
                "session_name": (
                    sess.get("workout_name") or sess.get("name")
                    or f"Day {p['session_idx'] + 1}"
                ),
                "workout_type": (
                    sess.get("type") or sess.get("workout_type") or "strength"
                ),
                "exercises_count": len(sess.get("exercises") or []),
                "is_deload": False,
            })
        weeks = plan["weeks_used"]
        sessions_per_week = plan["sessions_per_week"]
        # Variant scheduling places session si on the chosen weekday → the
        # training-day picker applies UNLESS the variant trains all 7 days a
        # week (a daily challenge), in which case there are no rest weekdays to
        # pick and the picker must be hidden.
        respects_training_days = (sessions_per_week or 0) < 7
    else:
        resolved = _resolve_program_days_for_preview(
            db, program_id=req.program_id, variant_id=req.variant_id,
            user_id=user_id,
        )
        program = resolved["program"]
        display_name = resolved["display_name"]
        normalized = resolved["normalized"]
        days = resolved["days"]
        weeks = req.duration_weeks or program.get("duration_weeks") or 8
        weeks = max(1, min(int(weeks), MAX_WEEKS))
        day_alignment = "calendar_weekday" if assigned_days else "start_today"
        plan = plan_template_days(
            days,
            week_length=int(normalized.get("week_length") or 7),
            deload_every=normalized.get("deload_every_n_weeks"),
            start_date=start,
            weeks=weeks,
            day_alignment=day_alignment,
            day_times={},
            assigned_days=assigned_days,
        )
        deload_weeks = set(plan["deload_weeks"])
        for p in plan["planned"]:
            day = p["day"]
            pdays.append({
                "week_number": p["week"],
                "target_date": p["target_date"],
                "weekday": p["target_date"].weekday(),
                "session_name": (
                    day.get("day_name") or f"Day {p['day_index'] + 1}"
                ),
                "workout_type": day.get("workout_type") or "strength",
                "exercises_count": len(
                    [e for e in (day.get("exercises") or []) if e]
                ),
                "is_deload": p["week"] in deload_weeks,
            })
        sessions_per_week = len([d for d in days if not d.get("is_rest")])
        # Base-blob path only honours the picked weekdays on a 7-day week.
        # Flattened multi-day blobs (e.g. a 30-day challenge) schedule on
        # consecutive days, so the training-day picker doesn't apply.
        respects_training_days = (
            int(normalized.get("week_length") or 7) == 7
        )

    # Order each calendar week's sessions by date for display.
    pdays.sort(key=lambda d: (d["week_number"], d["target_date"]))

    # --- existing materialized workouts on the planned dates -----------------
    target_dates = sorted({p["target_date"] for p in pdays})
    existing_by_date: Dict[str, List[Dict[str, Any]]] = {}
    if target_dates:
        try:
            lo = target_dates[0].isoformat()
            hi = (target_dates[-1] + timedelta(days=1)).isoformat()
            wresp = (
                db.client.table("workouts")
                .select(
                    "id, name, scheduled_date, program_slot, assignment_id, "
                    "generation_source, generation_method, status"
                )
                .eq("user_id", user_id)
                .gte("scheduled_date", lo)
                .lte("scheduled_date", hi)
                .execute()
            )
            for w in wresp.data or []:
                if (w.get("generation_method") or "") == "health_connect_import":
                    continue
                if (w.get("status") or "") in ("completed", "skipped"):
                    continue
                sd = (w.get("scheduled_date") or "")[:10]
                if sd:
                    existing_by_date.setdefault(sd, []).append(w)
        except Exception as e:  # noqa: BLE001
            logger.warning("preview collision lookup failed: %s", e)

    gym_profile_id = _resolve_active_gym_profile(db, user_id)
    training_weekdays = _resolve_training_weekdays(db, user_id, gym_profile_id)

    # --- build per-week schedule + collisions --------------------------------
    weeks_out: List[Dict[str, Any]] = []
    collisions: List[Dict[str, Any]] = []
    cur_week = None
    week_bucket: Optional[Dict[str, Any]] = None
    replace_count = stack_count = new_count = 0

    for p in pdays:
        wk = p["week_number"]
        td = p["target_date"]
        iso = td.isoformat()
        weekday = p["weekday"]
        session_name = p["session_name"]
        ex_count = p["exercises_count"]
        intensity = "deload" if p["is_deload"] else "normal"

        if wk != cur_week:
            cur_week = wk
            week_bucket = {
                "week_number": wk,
                "is_deload": p["is_deload"],
                "days": [],
            }
            weeks_out.append(week_bucket)

        # classify what's already on this date
        existing = existing_by_date.get(iso) or []
        clash = None
        if existing:
            # prefer a same-slot clash, else the first non-health row
            same_slot = [w for w in existing if (w.get("program_slot") or "") == slot]
            w = (same_slot or existing)[0]
            is_program = bool(
                w.get("assignment_id")
                or (w.get("generation_source") == "template")
            )
            clash = {
                "source": "program" if is_program else "ai",
                "existing_name": w.get("name") or "Workout",
                "existing_slot": w.get("program_slot") or (
                    "primary" if not is_program else "primary"
                ),
            }
        elif weekday in training_weekdays:
            # no row yet, but the AI would have generated here
            clash = {
                "source": "ai_planned",
                "existing_name": "AI workout",
                "existing_slot": "primary",
            }

        # Resolve via the SAME helper the expander materializes with, so the
        # preview can never drift from what assign creates. A per-day override in
        # day_resolutions is honored only on a detected clash (the client sends
        # overrides for conflict cards). resolve_collision returns add | stack |
        # replace; "add" only happens with no clash.
        resolution = resolve_collision(
            date_iso=iso,
            has_existing=(clash is not None),
            slot=slot,
            replace=req.replace,
            day_resolutions=(
                req.day_resolutions if clash is not None else None
            ),
        )
        if resolution == "replace":
            replace_count += 1
        elif resolution == "stack":
            stack_count += 1
        else:  # "add"
            new_count += 1

        day_out = {
            "date": iso,
            "weekday": weekday,
            "weekday_name": _WEEKDAY_NAMES[weekday],
            "session_name": session_name,
            "workout_type": p["workout_type"],
            "exercises_count": ex_count,
            "intensity_mode": intensity,
            "resolution": resolution,
        }
        week_bucket["days"].append(day_out)

        if clash is not None:
            collisions.append({
                "date": iso,
                "weekday": weekday,
                "weekday_name": _WEEKDAY_NAMES[weekday],
                "resolution": resolution,
                **clash,
            })

    # --- which active primaries would `replace` end? -------------------------
    replace_ends: List[Dict[str, Any]] = []
    if slot == "primary" and req.replace:
        try:
            existing_asgmts = (
                db.client.table("user_program_assignments")
                .select("id, custom_program_name, assigned_days")
                .eq("user_id", user_id)
                .eq("is_active", True)
                .eq("slot", "primary")
                .execute()
            )
            new_days = set(int(d) for d in assigned_days)
            for ex in existing_asgmts.data or []:
                ex_days = set(int(d) for d in (ex.get("assigned_days") or []))
                if not new_days or not ex_days or (new_days & ex_days):
                    replace_ends.append({
                        "assignment_id": str(ex["id"]),
                        "name": ex.get("custom_program_name") or "Current program",
                        "weekdays": sorted(ex_days),
                    })
        except Exception as e:  # noqa: BLE001
            logger.warning("preview replace-ends lookup failed: %s", e)

    total = len(pdays)
    summary = _deterministic_preview_summary(
        program_name=display_name,
        weeks=weeks,
        sessions_per_week=sessions_per_week,
        total=total,
        slot=slot,
        replace_count=replace_count,
        stack_count=stack_count,
        new_count=new_count,
        replace_ends=replace_ends,
        assigned_days=assigned_days,
    )

    # AI-tailoring estimate (caveat fix): a DRY-RUN of the same customize passes
    # the commit runs, so the Start sheet can show "what AI will change" live —
    # and surface the honest no-op case (no injuries / gear covers it / level
    # matches). Runs on ONE representative week (the commit tailors all weeks) to
    # bound the injury-RAG cost; injury-free / gear-less users hit the early
    # guards in the passes and pay ~0. NEVER mutates the resolved plan (deep
    # copy) and NEVER persists. Only computed when the client opts in (customize
    # set — i.e. the AI tailor toggle is on).
    customize_summary: Optional[Dict[str, Any]] = None
    if req.customize is not None:
        from services.program_customizer import (
            customize_status,
            customize_template_days,
        )
        try:
            if _weeks_rows:
                first_week = min(
                    _weeks_rows, key=lambda w: w.get("week_number") or 0
                )
                sample = copy.deepcopy([
                    s for s in (first_week.get("workouts") or [])
                    if isinstance(s, dict)
                ])
            else:
                sample = copy.deepcopy(days)
            cs = await customize_template_days(
                sample,
                user_id=user_id,
                adapt_to_level=req.customize.adapt_to_level,
                swap_for_injuries=req.customize.swap_for_injuries,
                fit_equipment=req.customize.fit_equipment,
            )
            cs["status"] = customize_status(cs)
            customize_summary = cs
        except Exception as e:  # noqa: BLE001 — never block the preview
            logger.warning("preview customize dry-run failed: %s", e)
            customize_summary = {"status": "failed"}

    return {
        "program_id": req.program_id,
        "program_name": display_name,
        "duration_weeks": weeks,
        "sessions_per_week": sessions_per_week,
        "total_workouts": total,
        "start_date": start.isoformat(),
        "slot": slot,
        "respects_training_days": respects_training_days,
        "weeks": weeks_out,
        "collisions": collisions,
        "replace_ends": replace_ends,
        "impact": {
            "replace_count": replace_count,
            "stack_count": stack_count,
            "new_count": new_count,
        },
        "summary": summary,
        # Per-week AI-tailoring estimate, or null when the client didn't opt in.
        "customize_summary": customize_summary,
    }


def _deterministic_preview_summary(
    *, program_name: str, weeks: int, sessions_per_week: int, total: int,
    slot: str, replace_count: int, stack_count: int, new_count: int,
    replace_ends: List[Dict[str, Any]], assigned_days: List[int],
) -> str:
    """Instant, always-accurate one-liner about the change (the deterministic
    'coach line' the sheet shows before the LLM review streams in)."""
    days_txt = ""
    if assigned_days:
        days_txt = " on " + "·".join(
            _WEEKDAY_NAMES[d] for d in sorted(set(assigned_days)) if 0 <= d <= 6
        )
    head = (
        f"Schedules {total} {program_name} workouts over {weeks} "
        f"week{'s' if weeks != 1 else ''}{days_txt}."
    )
    bits: List[str] = []
    if slot == "addon":
        bits.append("Stacks on top of your current plan")
    else:
        if replace_ends:
            names = ", ".join(r["name"] for r in replace_ends)
            bits.append(f"Replaces {names}")
        elif replace_count:
            bits.append(f"Replaces {replace_count} existing workout"
                        f"{'s' if replace_count != 1 else ''}")
        if stack_count:
            bits.append(f"runs alongside {stack_count} day"
                        f"{'s' if stack_count != 1 else ''}")
    if new_count:
        bits.append(f"adds {new_count} new training day"
                    f"{'s' if new_count != 1 else ''}")
    if bits:
        return head + " " + "; ".join(bits) + "."
    return head


@router.post("/assign-preview")
async def assign_program_preview(
    request: AssignPreviewRequest,
    current_user: dict = Depends(get_current_user),
):
    """Dry-run a Start: return the real dated schedule + calendar collisions
    WITHOUT writing. Powers the Start sheet's schedule preview + overlap flags +
    the instant deterministic impact line."""
    try:
        db = get_supabase()
        return await _build_assign_preview(
            db, user_id=str(current_user["id"]), req=request
        )
    except HTTPException:
        raise
    except ValueError as ve:
        raise HTTPException(status_code=422, detail=str(ve))
    except Exception as e:  # noqa: BLE001
        logger.error("assign-preview failed: %s", e, exc_info=True)
        raise safe_internal_error(e, "program_templates")


@router.post("/assign-review")
async def assign_program_review(
    request: AssignPreviewRequest,
    current_user: dict = Depends(get_current_user),
):
    """A short AI coach review of what starting this program does to the user's
    week. Recomputes the same dry-run, then asks Gemini for a 1-2 sentence take.
    Fail-soft: returns the deterministic summary if the LLM is unavailable."""
    db = get_supabase()
    try:
        preview = await _build_assign_preview(
            db, user_id=str(current_user["id"]), req=request
        )
    except HTTPException:
        raise
    except ValueError as ve:
        raise HTTPException(status_code=422, detail=str(ve))
    except Exception as e:  # noqa: BLE001
        logger.error("assign-review preview failed: %s", e, exc_info=True)
        raise safe_internal_error(e, "program_templates")

    fallback = preview.get("summary") or ""
    try:
        from google.genai import types
        from services.gemini.constants import gemini_generate_with_retry
        from core.config import get_settings
        settings = get_settings()

        impact = preview["impact"]
        collide_lines = "; ".join(
            f"{c['weekday_name']} {c['date']}: {c['resolution']} "
            f"({c['source']}: {c['existing_name']})"
            for c in preview["collisions"][:8]
        ) or "no overlaps with existing workouts"
        prompt = (
            "You are a concise, encouraging strength coach. In 1-2 short "
            "sentences (max ~40 words, no preamble, no markdown), tell the user "
            "what starting this program does to their training week and whether "
            "it's a sensible fit. Be specific about overlaps.\n\n"
            f"Program: {preview['program_name']}\n"
            f"Duration: {preview['duration_weeks']} weeks, "
            f"{preview['sessions_per_week']} sessions/week\n"
            f"Slot: {preview['slot']}\n"
            f"Total workouts scheduled: {preview['total_workouts']}\n"
            f"Replaces: {impact['replace_count']}, "
            f"stacks alongside: {impact['stack_count']}, "
            f"new training days: {impact['new_count']}\n"
            f"Overlaps: {collide_lines}\n"
        )
        resp = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=0.6, max_output_tokens=120,
            ),
            user_id=str(current_user["id"]),
            timeout=12.0,
            method_name="assign_review",
        )
        review = (getattr(resp, "text", "") or "").strip()
        return {"review": review or fallback, "summary": fallback}
    except Exception as e:  # noqa: BLE001 — never block the sheet on the LLM
        logger.warning("assign-review LLM failed, using deterministic: %s", e)
        return {"review": fallback, "summary": fallback}


# =============================================================================
# Active assignments
# =============================================================================
class AssignmentPatchRequest(BaseModel):
    custom_program_name: Optional[str] = None
    assigned_days: Optional[List[int]] = None
    slot: Optional[str] = None
    status: Optional[str] = None  # 'active' | 'paused'


def _assignment_or_404(db, assignment_id: str) -> Dict[str, Any]:
    resp = (
        db.client.table("user_program_assignments")
        .select("*")
        .eq("id", assignment_id)
        .limit(1)
        .execute()
    )
    if not resp.data:
        raise HTTPException(status_code=404, detail="Assignment not found")
    return resp.data[0]


def _hydrate_assignment_meta(db, row: Dict[str, Any]) -> Dict[str, Any]:
    """Resolve display_name + duration_weeks for an assignment from its template
    (preferred) or source program. Cheap best-effort lookups."""
    display_name = row.get("custom_program_name")
    duration_weeks: Optional[int] = None
    tpl_id = row.get("template_id")
    if tpl_id:
        try:
            tr = (
                db.client.table("user_program_templates")
                .select("name, duration_weeks")
                .eq("id", tpl_id)
                .limit(1)
                .execute()
            )
            if tr.data:
                display_name = display_name or tr.data[0].get("name")
                duration_weeks = tr.data[0].get("duration_weeks")
        except Exception:  # noqa: BLE001
            pass
    if duration_weeks is None and row.get("source_program_id"):
        try:
            pr = (
                db.client.table("programs")
                .select("editorial_name, program_name, duration_weeks")
                .eq("id", row["source_program_id"])
                .limit(1)
                .execute()
            )
            if pr.data:
                display_name = display_name or (
                    pr.data[0].get("editorial_name")
                    or pr.data[0].get("program_name")
                )
                duration_weeks = duration_weeks or pr.data[0].get(
                    "duration_weeks"
                )
        except Exception:  # noqa: BLE001
            pass
    return _assignment_to_dict(
        row, display_name=display_name, duration_weeks=duration_weeks
    )


@router.get("/assignments")
async def list_assignments(
    current_user: dict = Depends(get_current_user),
):
    """Active + recently-completed program assignments for the user.

    Sorted primary-first, then most-recently-started. Each row carries a
    resolved display_name + duration_weeks + source_program_id so the Flutter
    'My Programs' surface renders without extra round-trips.
    """
    try:
        db = get_supabase()
        user_id = str(current_user["id"])
        resp = (
            db.client.table("user_program_assignments")
            .select("*")
            .eq("user_id", user_id)
            .in_("status", ["active", "paused", "completed"])
            .order("started_at", desc=True)
            .execute()
        )
        rows = resp.data or []
        # Only surface PROGRAM-LIBRARY / template / branded assignments — every
        # row here either has a template, a source program, or a branded id.
        hydrated = [_hydrate_assignment_meta(db, r) for r in rows]
        # primary first, then by started_at desc (already desc-ordered above).
        hydrated.sort(key=lambda a: 0 if a.get("slot") == "primary" else 1)
        return {"assignments": hydrated}
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to list assignments: %s", e, exc_info=True)
        raise safe_internal_error(e, "program_templates")


@router.patch("/assignments/{assignment_id}")
async def patch_assignment(
    assignment_id: str,
    request: AssignmentPatchRequest,
    current_user: dict = Depends(get_current_user),
):
    """Rename / move days / change slot / pause-resume an assignment.

    On a day or slot change we reschedule: drop the assignment's future
    incomplete workouts and re-expand from its template against the new days,
    then clear the /today cache.
    """
    try:
        db = get_supabase()
        row = _assignment_or_404(db, assignment_id)
        _require_owner(row, current_user)
        user_id = str(current_user["id"])

        updates: Dict[str, Any] = {}
        if request.custom_program_name is not None:
            updates["custom_program_name"] = request.custom_program_name
        if request.slot is not None:
            s = request.slot.strip().lower()
            if s not in ("primary", "addon"):
                raise HTTPException(
                    status_code=422, detail="slot must be 'primary' or 'addon'"
                )
            updates["slot"] = s
        if request.assigned_days is not None:
            updates["assigned_days"] = [
                int(d) for d in request.assigned_days if 0 <= int(d) <= 6
            ]
        if request.status is not None:
            st = request.status.strip().lower()
            if st not in ("active", "paused"):
                raise HTTPException(
                    status_code=422,
                    detail="status must be 'active' or 'paused'",
                )
            updates["status"] = st
            updates["is_active"] = st == "active"
            if st == "paused":
                updates["paused_at"] = datetime.utcnow().isoformat()

        if not updates:
            return {"success": True, "assignment": _hydrate_assignment_meta(db, row)}

        updates["updated_at"] = datetime.utcnow().isoformat()
        db.client.table("user_program_assignments").update(updates).eq(
            "id", assignment_id
        ).execute()

        # Cascade a rename onto the template too (keeps both surfaces aligned).
        if "custom_program_name" in updates and row.get("template_id"):
            try:
                db.client.table("user_program_templates").update(
                    {"name": updates["custom_program_name"]}
                ).eq("id", row["template_id"]).execute()
            except Exception as e:  # noqa: BLE001
                logger.debug("template rename cascade skipped: %s", e)

        # Pause / resume cascade to the assignment's scheduled workouts.
        # We HIDE rather than delete so resume restores the exact remaining
        # plan (same dates, week alignment, and variant-accurate content) —
        # re-expanding would restart the program from week 1 at today, losing
        # progress. Pause flips future incomplete 'scheduled' rows to
        # status='paused' (excluded by list_workouts); resume flips them back.
        prev_status = (row.get("status") or "").lower()
        paused_now = (
            updates.get("status") == "paused" and prev_status != "paused"
        )
        resumed_now = (
            updates.get("status") == "active" and prev_status == "paused"
        )
        if paused_now:
            try:
                db.client.table("workouts").update(
                    {"status": "paused"}
                ).eq("assignment_id", assignment_id).eq(
                    "user_id", user_id
                ).gte(
                    "scheduled_date", datetime.utcnow().isoformat()
                ).eq("is_completed", False).eq(
                    "status", "scheduled"
                ).execute()
            except Exception as e:  # noqa: BLE001
                logger.warning("pause: hide future rows failed: %s", e)
        elif resumed_now:
            try:
                db.client.table("workouts").update(
                    {"status": "scheduled"}
                ).eq("assignment_id", assignment_id).eq(
                    "user_id", user_id
                ).eq("status", "paused").execute()
            except Exception as e:  # noqa: BLE001
                logger.warning("resume: unhide rows failed: %s", e)

        # Reschedule on a day/slot change: rebuild this assignment's future
        # workouts against the new schedule. (Resume does NOT reschedule — it
        # restores the hidden rows above so progress/week alignment is kept.)
        needs_reschedule = (
            "assigned_days" in updates or "slot" in updates
        ) and row.get("template_id")
        if needs_reschedule:
            await _reschedule_assignment(
                db,
                assignment_id=assignment_id,
                user_id=user_id,
                template_id=str(row["template_id"]),
                assigned_days=updates.get(
                    "assigned_days", row.get("assigned_days") or []
                ),
                slot=updates.get("slot", row.get("slot") or "primary"),
            )

        await _clear_today_cache(user_id)
        fresh = _assignment_or_404(db, assignment_id)
        return {"success": True, "assignment": _hydrate_assignment_meta(db, fresh)}
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to patch assignment %s: %s", assignment_id, e,
            exc_info=True,
        )
        raise safe_internal_error(e, "program_templates")


async def _reschedule_assignment(
    db,
    *,
    assignment_id: str,
    user_id: str,
    template_id: str,
    assigned_days: List[int],
    slot: str,
) -> None:
    """Drop this assignment's FUTURE INCOMPLETE workouts and re-expand the
    template against the new assigned_days/slot. Past + completed rows are kept.
    """
    now_iso = datetime.utcnow().isoformat()
    try:
        # Remove future incomplete rows produced by THIS assignment.
        db.client.table("workouts").delete().eq(
            "assignment_id", assignment_id
        ).eq("user_id", user_id).gte(
            "scheduled_date", now_iso
        ).eq("is_completed", False).execute()
    except Exception as e:  # noqa: BLE001
        logger.warning("reschedule: future-row delete failed: %s", e)

    template = _get_template_or_404(db, template_id)
    weeks = template.get("duration_weeks") or 8
    weeks = max(1, min(int(weeks), MAX_WEEKS))
    gym_profile_id = _resolve_active_gym_profile(db, user_id)
    schedule_id = str(uuid.uuid4())
    day_alignment = "calendar_weekday" if assigned_days else "start_today"
    try:
        db.client.table("user_program_schedules").insert(
            {
                "id": schedule_id,
                "template_id": template_id,
                "user_id": user_id,
                "start_date": date.today().isoformat(),
                "weeks": weeks,
                "day_alignment": day_alignment,
                "day_times": {},
            }
        ).execute()
    except Exception as e:  # noqa: BLE001
        logger.debug("reschedule: schedule row insert skipped: %s", e)
    try:
        expand_template(
            template=template,
            schedule_id=schedule_id,
            user_id=user_id,
            start_date=date.today(),
            weeks=weeks,
            day_alignment=day_alignment,
            day_times={},
            gym_profile_id=gym_profile_id,
            assignment_id=assignment_id,
            program_slot=slot,
            assigned_days=list(assigned_days or []),
        )
    except Exception as e:  # noqa: BLE001
        logger.error("reschedule: re-expand failed: %s", e, exc_info=True)


@router.delete("/assignments/{assignment_id}")
async def delete_assignment(
    assignment_id: str,
    current_user: dict = Depends(get_current_user),
):
    """End an assignment (is_active=false, status='abandoned') and remove ALL
    its INCOMPLETE workouts. Completed rows are kept for history.

    Purge is intentionally NOT date-filtered. A date filter (scheduled_date >=
    utc-now) leaked the user's own TODAY workout: program rows are stored at
    12:00 UTC, so a removal later in the UTC day treated today's session as
    "past" and left it behind — an orphan of an abandoned assignment that
    list_workouts still surfaced (the "I removed the program but Saturday's
    workout is still here" bug). Removing a program clears everything it
    scheduled that the user hasn't actually done."""
    try:
        db = get_supabase()
        row = _assignment_or_404(db, assignment_id)
        _require_owner(row, current_user)
        user_id = str(current_user["id"])

        db.client.table("user_program_assignments").update(
            {
                "is_active": False,
                "status": "abandoned",
                "updated_at": datetime.utcnow().isoformat(),
            }
        ).eq("id", assignment_id).execute()

        removed = 0
        try:
            res = (
                db.client.table("workouts")
                .delete()
                .eq("assignment_id", assignment_id)
                .eq("user_id", user_id)
                .eq("is_completed", False)
                .execute()
            )
            removed = len(res.data or [])
        except Exception as e:  # noqa: BLE001
            logger.warning("assignment delete: workout purge failed: %s", e)

        await _clear_today_cache(user_id)
        return {
            "success": True,
            "assignment_id": assignment_id,
            "future_workouts_removed": removed,
        }
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error(
            "Failed to delete assignment %s: %s", assignment_id, e,
            exc_info=True,
        )
        raise safe_internal_error(e, "program_templates")


# =============================================================================
# Program favorites  (Program Detail page heart — persists)
# =============================================================================
class FavoriteProgramRequest(BaseModel):
    program_id: str = Field(..., description="public.programs.id to favorite")


@router.get("/favorites")
async def list_favorite_programs(
    current_user: dict = Depends(get_current_user),
):
    """The user's favorited library programs as full cards, newest-first.

    Joins favorite_programs -> programs. Includes the editorial card fields +
    `phases` (from the row). Fail-open: any error returns an empty list rather
    than 500ing the favorites surface."""
    try:
        db = get_supabase()
        user_id = str(current_user["id"])
        favs = (
            db.client.table("favorite_programs")
            .select("program_id, created_at")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        rows = favs.data or []
        if not rows:
            return {"programs": []}

        # Preserve favorite order (newest first); fetch the program rows in one
        # query, then re-sort to the favorite order.
        ordered_ids = [str(r["program_id"]) for r in rows if r.get("program_id")]
        progs = (
            db.client.table("programs")
            .select(_LIBRARY_CARD_COLS + ", phases")
            .in_("id", ordered_ids)
            .execute()
        )
        by_id = {str(p["id"]): p for p in (progs.data or [])}

        cards: List[Dict[str, Any]] = []
        for pid in ordered_ids:
            p = by_id.get(pid)
            if not p:
                continue  # program deleted (FK cascade should prevent, but safe)
            card = _row_to_card(p).model_dump()
            card["phases"] = _normalize_phases(p.get("phases"))
            cards.append(card)
        return {"programs": cards}
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to list favorite programs: %s", e, exc_info=True)
        return {"programs": []}


@router.get("/favorites/ids")
async def list_favorite_program_ids(
    current_user: dict = Depends(get_current_user),
):
    """Fast heart-state for the client: just the favorited program_ids. Fail-open
    to an empty list."""
    try:
        db = get_supabase()
        user_id = str(current_user["id"])
        resp = (
            db.client.table("favorite_programs")
            .select("program_id")
            .eq("user_id", user_id)
            .execute()
        )
        ids = [str(r["program_id"]) for r in (resp.data or []) if r.get("program_id")]
        return {"program_ids": ids}
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to list favorite program ids: %s", e, exc_info=True)
        return {"program_ids": []}


@router.post("/favorites")
async def add_favorite_program(
    request: FavoriteProgramRequest,
    current_user: dict = Depends(get_current_user),
):
    """Favorite a program. Idempotent — a re-tap on an already-favorited program
    is a no-op (dedupes on the unique(user_id, program_id) index)."""
    try:
        db = get_supabase()
        user_id = str(current_user["id"])
        # Validate the program exists (clean 404 vs an opaque FK error).
        prog = (
            db.client.table("programs")
            .select("id")
            .eq("id", request.program_id)
            .limit(1)
            .execute()
        )
        if not prog.data:
            raise HTTPException(status_code=404, detail="Program not found")
        try:
            db.client.table("favorite_programs").insert(
                {"user_id": user_id, "program_id": request.program_id}
            ).execute()
        except Exception as ie:  # noqa: BLE001
            # Unique-violation on a re-tap is the idempotent success path.
            if "23505" in str(ie) or "duplicate key" in str(ie).lower():
                logger.debug("favorite already exists (idempotent): %s", ie)
            else:
                raise
        return {"success": True, "favorited": True}
    except HTTPException:
        raise
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to add favorite program: %s", e, exc_info=True)
        raise safe_internal_error(e, "program_templates")


@router.delete("/favorites/{program_id}")
async def remove_favorite_program(
    program_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Unfavorite a program. Idempotent — deleting a non-favorite is success."""
    try:
        db = get_supabase()
        user_id = str(current_user["id"])
        db.client.table("favorite_programs").delete().eq(
            "user_id", user_id
        ).eq("program_id", program_id).execute()
        return {"success": True, "favorited": False}
    except Exception as e:  # noqa: BLE001
        logger.error("Failed to remove favorite program: %s", e, exc_info=True)
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
            "name", "description", "notes", "week_length", "days",
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
