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
    regenerate_future,
    MAX_WEEKS,
)

logger = get_logger(__name__)
router = APIRouter()

# In-memory TTL cache for the program-library browse result. The `programs`
# library is static/curated reference data, so a long TTL is safe — the only
# writes are bulk re-imports, which restart the process. Keyed by the
# (category, difficulty_level, sessions_per_week, search) filter tuple.
# NOTE: cache prefixes carry a "_v2" suffix because the cached dict shape
# changed when the library was unified with branded_programs (added the
# `source` field + branded rows). Bumping the prefix retires any pre-merge
# cached payloads without a manual flush.
_library_browse_cache = ResponseCache(
    prefix="program_library_browse_v2", ttl_seconds=6 * 3600, max_size=256
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
# Branded-program unification (programs ∪ branded_programs at the read API)
# =============================================================================
# The two catalogs are merged at the READ layer ONLY — no data migration. A
# branded card's id is prefixed "branded:<uuid>" so the client + the single-
# program preview/import dispatch can tell the two sources apart; `programs`
# ids stay bare. The card's `source` field ('library' | 'branded') is the
# explicit, prefix-independent discriminator.
_BRANDED_ID_PREFIX = "branded:"

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
        cache_key = _library_browse_cache.make_key(
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

        db = get_supabase()
        # Light card columns ONLY — drop the `workouts` blob from the select.
        # has_workouts + sessions_per_week are now precomputed columns.
        # NOTE: the structured DB-side filters below only apply to the curated
        # `programs` query. Branded rows are fetched whole and filtered in
        # Python by the SAME predicates so the merged set is filtered uniformly.
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
        # duration_weeks range — DB-side (cheap, indexed-ish numeric compare).
        if duration_min is not None:
            query = query.gte("duration_weeks", duration_min)
        if duration_max is not None:
            query = query.lte("duration_weeks", duration_max)
        resp = query.execute()

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
                    source="library",
                )
            )

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
        search_lc = (search or "").strip().lower() or None
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
            if search_lc and search_lc not in (bc.program_name or "").lower():
                continue
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
    "short_description, goals, featured_rank"
)


def _row_to_card(row: Dict[str, Any]) -> LibraryProgramCard:
    """Hydrate a programs row into the lightweight browse card."""
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
    prefix="program_library_featured_v2", ttl_seconds=6 * 3600, max_size=8
)
_library_categories_cache = ResponseCache(
    prefix="program_library_categories_v2", ttl_seconds=6 * 3600, max_size=8
)
_library_recommended_cache = ResponseCache(
    prefix="program_library_recommended_v2", ttl_seconds=6 * 3600, max_size=256
)


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
        cache_key = _library_featured_cache.make_key("featured")
        cached = await _library_featured_cache.get(cache_key)
        if isinstance(cached, dict):
            return cached

        db = get_supabase()
        resp = (
            db.client.table("programs")
            .select(_LIBRARY_CARD_COLS)
            .eq("has_workouts", True)
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
        cache_key = _library_categories_cache.make_key("categories")
        cached = await _library_categories_cache.get(cache_key)
        if isinstance(cached, dict):
            return cached

        db = get_supabase()
        resp = (
            db.client.table("programs")
            .select("program_category")
            .eq("has_workouts", True)
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

        categories = [
            {"category": cat, "count": n}
            for cat, n in sorted(
                counts.items(), key=lambda kv: (-kv[1], kv[0])
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
    """
    try:
        db = get_supabase()

        # --- Branded preview path -----------------------------------------
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
            resolver = ExerciseResolver(user_id=str(current_user["id"]))
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

        # --- Curated `programs` preview path (unchanged) ------------------
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
            "source": "library",
            "preview_available": True,
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

        # --- Curated `programs` import path (unchanged) -------------------
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
