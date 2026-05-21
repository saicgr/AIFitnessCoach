"""
Program Library Importer - converts a `programs`-table row into the `days`
JSON shape used by `user_program_templates`.

Two real transform jobs (plan B.2 / B.6 Group 1b):
  1. Rep-string normalization  -> normalize_reps_spec()
  2. Exercise resolution across ALL sources -> ExerciseResolver

The `programs.workouts` blob is already
  [{day, type, workout_name, exercises:[{exercise_name, sets, reps,
    rest_seconds, notes}]}]
so the day-level transform is near 1:1; the work is the rep-string parsing
and the exercise-name resolution.

Used by:
  - api/v1/program_templates.py  (POST /from-program/{id}, GET /library/{id})
  - services/program_template_parser.py  (reuses the SAME normalizer + resolver)
"""
from __future__ import annotations

import re
import logging
from typing import Any, Dict, List, Optional

from core.supabase_client import get_supabase

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Rep-string normalization
# ---------------------------------------------------------------------------
#
# `programs` `reps` is varied free-text. Observed values:
#   "10", "10-12", "10-15 each leg", "30 minutes", "30 seconds",
#   "1-2 minutes", "200", "20 per side", "10-15 minutes climbing",
#   "8-12", "20-30 seconds", "AMRAP"
#
# Output `reps_spec` shapes:
#   {"kind": "fixed",    "min": N, "max": N, "per_side": bool}
#   {"kind": "range",    "min": A, "max": B, "per_side": bool}
#   {"kind": "time",     "min": A, "max": B, "unit": "seconds"|"minutes",
#                        "per_side": bool}
#   {"kind": "amrap",    "per_side": bool}
#   {"kind": "freeform", "raw": "<original>"}   <- never drops anything

_PER_SIDE_RE = re.compile(
    r"\b(each|per)\s+(side|leg|arm)\b|\beach\s+side\b|\bper\s+side\b",
    re.IGNORECASE,
)
_AMRAP_RE = re.compile(r"\b(amrap|to\s+failure|max\s+reps?|max)\b", re.IGNORECASE)
_TIME_UNIT_RE = re.compile(
    r"\b(seconds?|secs?|minutes?|mins?|hours?)\b", re.IGNORECASE
)
_RANGE_RE = re.compile(r"(\d+(?:\.\d+)?)\s*[-–to]+\s*(\d+(?:\.\d+)?)")
_SINGLE_NUM_RE = re.compile(r"(\d+(?:\.\d+)?)")


def _normalize_time_unit(token: str) -> str:
    t = token.lower()
    if t.startswith("min"):
        return "minutes"
    if t.startswith("hour"):
        return "hours"
    return "seconds"


def normalize_reps_spec(raw: Any) -> Dict[str, Any]:
    """Parse a free-text rep value into a structured reps_spec dict.

    Anything that cannot be confidently parsed falls through to
    {"kind": "freeform", "raw": "<original>"} so nothing is ever lost
    (plan B.6 #L7).
    """
    if raw is None:
        # No reps specified at all -> treat as freeform empty so the
        # review UI / defaults layer can handle it.
        return {"kind": "freeform", "raw": ""}

    # Numeric input straight from JSON.
    if isinstance(raw, (int, float)):
        n = int(raw)
        return {"kind": "fixed", "min": n, "max": n, "per_side": False}

    text = str(raw).strip()
    if not text:
        return {"kind": "freeform", "raw": ""}

    lowered = text.lower()
    per_side = bool(_PER_SIDE_RE.search(text))

    # AMRAP / to-failure (#9).
    if _AMRAP_RE.search(lowered) and not _SINGLE_NUM_RE.search(lowered):
        return {"kind": "amrap", "per_side": per_side}

    time_unit_match = _TIME_UNIT_RE.search(lowered)

    # Detect "climbing", "rounds", trailing words that make it unparseable
    # even though it contains numbers e.g. "10-15 minutes climbing".
    # Strategy: extract the leading numeric pattern; if there is meaningful
    # trailing text that is NOT a recognized unit/per-side qualifier, keep
    # freeform so the raw string renders verbatim.
    stripped = _PER_SIDE_RE.sub("", text)
    if time_unit_match:
        stripped = _TIME_UNIT_RE.sub("", stripped, count=1)
    # Remove leading numbers + range separators we will consume.
    residue = _RANGE_RE.sub("", stripped, count=1)
    residue = _SINGLE_NUM_RE.sub("", residue, count=1)
    residue = residue.strip(" -–,.;").strip()

    is_time = time_unit_match is not None

    # Range value.
    range_match = _RANGE_RE.search(text)
    if range_match:
        lo = float(range_match.group(1))
        hi = float(range_match.group(2))
        lo_i = int(lo) if lo.is_integer() else lo
        hi_i = int(hi) if hi.is_integer() else hi
        if is_time:
            if residue:  # e.g. "10-15 minutes climbing"
                return {"kind": "freeform", "raw": text}
            return {
                "kind": "time",
                "min": lo_i,
                "max": hi_i,
                "unit": _normalize_time_unit(time_unit_match.group(1)),
                "per_side": per_side,
            }
        if residue:  # unrecognized trailing words
            return {"kind": "freeform", "raw": text}
        return {"kind": "range", "min": lo_i, "max": hi_i, "per_side": per_side}

    # Single number.
    single_match = _SINGLE_NUM_RE.search(text)
    if single_match:
        val = float(single_match.group(1))
        val_i = int(val) if val.is_integer() else val
        if is_time:
            if residue:
                return {"kind": "freeform", "raw": text}
            return {
                "kind": "time",
                "min": val_i,
                "max": val_i,
                "unit": _normalize_time_unit(time_unit_match.group(1)),
                "per_side": per_side,
            }
        if residue:
            return {"kind": "freeform", "raw": text}
        return {"kind": "fixed", "min": val_i, "max": val_i, "per_side": per_side}

    # Nothing numeric and not AMRAP -> freeform.
    return {"kind": "freeform", "raw": text}


def reps_spec_display(spec: Dict[str, Any]) -> str:
    """Human-readable rendering of a reps_spec (used for `reps` mirror field)."""
    kind = spec.get("kind")
    suffix = " each side" if spec.get("per_side") else ""
    if kind == "fixed":
        return f"{spec.get('min')}{suffix}"
    if kind == "range":
        return f"{spec.get('min')}-{spec.get('max')}{suffix}"
    if kind == "time":
        lo, hi, unit = spec.get("min"), spec.get("max"), spec.get("unit")
        body = f"{lo}" if lo == hi else f"{lo}-{hi}"
        return f"{body} {unit}{suffix}"
    if kind == "amrap":
        return f"AMRAP{suffix}"
    return str(spec.get("raw", ""))


# ---------------------------------------------------------------------------
# Movement classification (rest-default + compound/isolation increment)
# ---------------------------------------------------------------------------
_COMPOUND_KEYWORDS = (
    "squat", "deadlift", "bench", "press", "row", "pull-up", "pullup",
    "chin-up", "chinup", "clean", "snatch", "lunge", "dip", "thruster",
    "good morning", "hip thrust",
)


def is_compound(exercise_name: str) -> bool:
    n = (exercise_name or "").lower()
    return any(k in n for k in _COMPOUND_KEYWORDS)


def default_rest_seconds(exercise_name: str) -> int:
    """Plan B.6 #L13 - default rest by movement classification."""
    return 90 if is_compound(exercise_name) else 60


# ---------------------------------------------------------------------------
# Exercise resolution across exercise_library_cleaned -> custom_exercises -> RAG
# ---------------------------------------------------------------------------
class ExerciseResolver:
    """Resolve an exercise name to an exercise_id across all sources.

    Order (plan B.2): exact -> fuzzy -> RAG semantic.
      1. exercise_library_cleaned MV   (2192 rows, the canonical library)
      2. user's custom_exercises table (their own authored exercises)
      3. ChromaDB RAG  (exercise_library + custom_exercise_library collections)

    Unmatched -> {"exercise_id": None, "unresolved": True} for the review UI.
    """

    def __init__(self, user_id: Optional[str] = None):
        self.user_id = user_id
        self.db = get_supabase()
        self._library_cache: Optional[List[Dict[str, Any]]] = None
        self._custom_cache: Optional[List[Dict[str, Any]]] = None

    # -- source loaders ----------------------------------------------------
    def _load_library(self) -> List[Dict[str, Any]]:
        if self._library_cache is None:
            rows: List[Dict[str, Any]] = []
            page = 0
            while True:
                resp = (
                    self.db.client.table("exercise_library_cleaned")
                    .select("id, name, original_name, target_muscle, body_part")
                    .range(page * 1000, page * 1000 + 999)
                    .execute()
                )
                batch = resp.data or []
                rows.extend(batch)
                if len(batch) < 1000:
                    break
                page += 1
            self._library_cache = rows
            logger.info(
                "ExerciseResolver loaded %d library exercises", len(rows)
            )
        return self._library_cache

    def _load_custom(self) -> List[Dict[str, Any]]:
        if self._custom_cache is None:
            if not self.user_id:
                self._custom_cache = []
                return self._custom_cache
            try:
                resp = (
                    self.db.client.table("custom_exercises")
                    .select("id, name, body_part, target_muscles")
                    .eq("user_id", self.user_id)
                    .execute()
                )
                self._custom_cache = resp.data or []
            except Exception as e:  # noqa: BLE001
                logger.warning("Failed to load custom_exercises: %s", e)
                self._custom_cache = []
        return self._custom_cache

    # -- matching helpers --------------------------------------------------
    @staticmethod
    def _norm(name: str) -> str:
        n = (name or "").lower().strip()
        # collapse separators / pluralization noise
        n = re.sub(r"[\-_/]+", " ", n)
        n = re.sub(r"\s+", " ", n)
        if n.endswith("s") and len(n) > 3:
            n_singular = n[:-1]
        else:
            n_singular = n
        return n_singular

    def _exact(
        self, name: str, rows: List[Dict[str, Any]], name_keys: List[str]
    ) -> Optional[Dict[str, Any]]:
        target = self._norm(name)
        for row in rows:
            for key in name_keys:
                val = row.get(key)
                if val and self._norm(val) == target:
                    return row
        return None

    # Equipment prefixes that should be preferred when a bare exercise name
    # (e.g. "Bench Press") matches several equipment-qualified library rows.
    _PREFERRED_EQUIP_TOKENS = ("barbell", "dumbbell", "bodyweight", "machine")

    def _fuzzy(
        self, name: str, rows: List[Dict[str, Any]], name_keys: List[str]
    ) -> Optional[Dict[str, Any]]:
        """Token-overlap fuzzy match.

        Requires the query tokens to be >=60% covered, then picks the row
        with (in priority order):
          1. highest query coverage
          2. FEWEST extra tokens (closest to the bare query name)
          3. a preferred equipment prefix (Barbell/Dumbbell/... over Band/Cable)
        so "Bench Press" -> "Barbell Bench Press", not "Band Bench Press".
        """
        q_tokens = set(self._norm(name).split())
        if not q_tokens:
            return None
        best: Optional[Dict[str, Any]] = None
        best_key: Optional[tuple] = None
        for row in rows:
            for key in name_keys:
                val = row.get(key)
                if not val:
                    continue
                r_tokens = set(self._norm(val).split())
                if not r_tokens:
                    continue
                overlap = len(q_tokens & r_tokens)
                if overlap == 0:
                    continue
                coverage = overlap / len(q_tokens)
                if coverage < 0.6:
                    continue
                extra = len(r_tokens) - overlap
                preferred = any(
                    t in r_tokens for t in self._PREFERRED_EQUIP_TOKENS
                )
                # Sort key: higher coverage first, then fewer extras, then a
                # preferred equipment prefix.
                rank = (coverage, -extra, 1 if preferred else 0)
                if best_key is None or rank > best_key:
                    best_key = rank
                    best = row
        return best

    def _rag(self, name: str) -> Optional[Dict[str, Any]]:
        """ChromaDB semantic fallback. Returns a synthetic row dict with the
        resolved library/custom id, or None.

        The Chroma Cloud collections in this project have NO server-side
        embedding function - they only accept `query_embeddings`. We embed the
        name first via `GeminiService.get_embedding()` (the sync embedding
        path, matching the rest of this sync importer) then query. Fully
        best-effort: any embed/query failure falls through to unresolved.
        """
        try:
            from services.exercise_rag_service import get_exercise_rag_service
            from services.gemini_service import get_gemini_service

            rag = get_exercise_rag_service()
            collection = getattr(rag, "collection", None)
            if collection is None:
                return None

            # Embed the exercise name BEFORE querying - the collection has no
            # server-side embedding function (query_texts 422s).
            gemini = get_gemini_service()
            embedding = gemini.get_embedding(name)
            if not embedding:
                return None

            res = collection.query(
                query_embeddings=[embedding],
                n_results=1,
                include=["metadatas", "distances"],
            )
            ids = (res.get("ids") or [[]])[0]
            metas = (res.get("metadatas") or [[]])[0]
            distances = (res.get("distances") or [[None]])[0]
            if not ids:
                return None
            # cosine distance: lower is closer; only accept confident hits.
            dist = distances[0] if distances else None
            if dist is not None and dist > 0.45:
                return None
            meta = metas[0] if metas else {}
            return {
                "id": meta.get("library_id") or meta.get("id") or ids[0],
                "name": meta.get("name") or name,
                "source": "rag",
            }
        except Exception as e:  # noqa: BLE001 - RAG is best-effort
            logger.warning("RAG resolution failed for '%s': %s", name, e)
            return None

    # -- public API --------------------------------------------------------
    def resolve(self, exercise_name: str) -> Dict[str, Any]:
        """Resolve one name. Returns:
        {"exercise_id": str|None, "resolved_name": str,
         "source": "library"|"custom"|"rag"|None, "unresolved": bool}
        """
        name = (exercise_name or "").strip()
        if not name:
            return {
                "exercise_id": None,
                "resolved_name": "",
                "source": None,
                "unresolved": True,
            }

        library = self._load_library()
        custom = self._load_custom()

        # 1. exact on library
        hit = self._exact(name, library, ["name", "original_name"])
        if hit:
            return {
                "exercise_id": str(hit["id"]),
                "resolved_name": hit.get("name") or name,
                "source": "library",
                "unresolved": False,
            }
        # 2. exact on custom (X1 - user's own exercise)
        hit = self._exact(name, custom, ["name"])
        if hit:
            return {
                "exercise_id": str(hit["id"]),
                "resolved_name": hit.get("name") or name,
                "source": "custom",
                "unresolved": False,
            }
        # 3. fuzzy on library
        hit = self._fuzzy(name, library, ["name", "original_name"])
        if hit:
            return {
                "exercise_id": str(hit["id"]),
                "resolved_name": hit.get("name") or name,
                "source": "library",
                "unresolved": False,
            }
        # 4. fuzzy on custom
        hit = self._fuzzy(name, custom, ["name"])
        if hit:
            return {
                "exercise_id": str(hit["id"]),
                "resolved_name": hit.get("name") or name,
                "source": "custom",
                "unresolved": False,
            }
        # 5. RAG semantic fallback
        rag_hit = self._rag(name)
        if rag_hit:
            return {
                "exercise_id": str(rag_hit["id"]),
                "resolved_name": rag_hit.get("name") or name,
                "source": "rag",
                "unresolved": False,
            }
        # unresolved (X2 / #L8) - flag for the review UI
        return {
            "exercise_id": None,
            "resolved_name": name,
            "source": None,
            "unresolved": True,
        }


# ---------------------------------------------------------------------------
# Category -> default progression strategy
# ---------------------------------------------------------------------------
# Non-strength categories skip weight progression + deload (plan B.6 #L2).
_NON_PROGRESSING_CATEGORIES = (
    "yoga", "stretch", "stretching", "pain", "mobility", "flexibility",
    "recovery", "rehab",
)


def derive_progression_strategy(category: Optional[str]) -> str:
    cat = (category or "").lower()
    if any(k in cat for k in _NON_PROGRESSING_CATEGORIES):
        return "none"
    return "linear"


def derive_deload_every_n(category: Optional[str]) -> Optional[int]:
    cat = (category or "").lower()
    if any(k in cat for k in _NON_PROGRESSING_CATEGORIES):
        return None
    return 5


# ---------------------------------------------------------------------------
# programs.workouts JSONB  ->  days[] shape
# ---------------------------------------------------------------------------
def _exercise_to_day_exercise(
    raw_ex: Dict[str, Any], resolver: ExerciseResolver
) -> Dict[str, Any]:
    name = (
        raw_ex.get("exercise_name")
        or raw_ex.get("name")
        or ""
    ).strip()
    reps_spec = normalize_reps_spec(raw_ex.get("reps"))
    resolution = resolver.resolve(name)
    rest = raw_ex.get("rest_seconds")
    if rest in (None, ""):
        rest = default_rest_seconds(name)
    set_type = "normal"
    if reps_spec.get("kind") == "amrap":
        set_type = "amrap"
    return {
        "name": resolution["resolved_name"] or name,
        "original_name": name,
        "exercise_id": resolution["exercise_id"],
        "sets": int(raw_ex.get("sets") or 3),
        "reps": reps_spec_display(reps_spec),
        "reps_spec": reps_spec,
        "per_side": reps_spec.get("per_side", False),
        "target_rir": raw_ex.get("target_rir"),
        "target_weight_kg": raw_ex.get("target_weight_kg"),
        "rest_seconds": int(rest),
        "notes": raw_ex.get("notes") or "",
        "set_type": set_type,
        "superset_group": raw_ex.get("superset_group"),
        "unresolved": resolution["unresolved"],
        "resolution_source": resolution["source"],
        "inferred": False,
    }


def _classify_workout_type(raw_type: Optional[str]) -> str:
    t = (raw_type or "").lower()
    if "cardio" in t or "hiit" in t:
        return "cardio"
    if "yoga" in t:
        return "yoga"
    if "stretch" in t or "mobility" in t:
        return "stretching"
    return "strength"


# `workouts.difficulty` is a NOT-NULL column with the allowed values
# easy | medium | hard | hell. `programs.difficulty_level` uses
# Beginner | Intermediate | Advanced | Elite. Map between the two; anything
# missing/unknown defaults to 'medium'.
_DIFFICULTY_MAP = {
    "beginner": "easy",
    "intermediate": "medium",
    "advanced": "hard",
    "elite": "hell",
}
DEFAULT_DIFFICULTY = "medium"
_VALID_DIFFICULTIES = {"easy", "medium", "hard", "hell"}


def map_difficulty(difficulty_level: Optional[str]) -> str:
    """Map a `programs.difficulty_level` value to a `workouts.difficulty`
    value. Already-valid lowercase values pass through; unknown -> 'medium'."""
    if not difficulty_level:
        return DEFAULT_DIFFICULTY
    raw = str(difficulty_level).strip().lower()
    if raw in _VALID_DIFFICULTIES:
        return raw
    return _DIFFICULTY_MAP.get(raw, DEFAULT_DIFFICULTY)


def program_workouts_to_days(
    program_row: Dict[str, Any], resolver: ExerciseResolver
) -> List[Dict[str, Any]]:
    """Transform a `programs` row's `workouts` JSONB into the `days[]` shape.

    Each `programs.workouts[]` entry becomes one day. Days are 0-indexed by
    array position (`day_index`). The `programs.workouts[].day` field is used
    only for the human-readable label fallback.
    """
    blob = program_row.get("workouts")
    workouts_list: List[Dict[str, Any]] = []
    if isinstance(blob, dict):
        workouts_list = blob.get("workouts") or []
    elif isinstance(blob, list):
        workouts_list = blob
    if not workouts_list:
        raise ValueError("Program has no structured workouts to import")

    # All days inherit the parent program's difficulty (mapped to the
    # workouts.difficulty value set). Stored per-day in days[] JSONB so the
    # builder can vary it later without a schema change.
    program_difficulty = map_difficulty(program_row.get("difficulty_level"))

    days: List[Dict[str, Any]] = []
    for idx, w in enumerate(workouts_list):
        raw_exercises = w.get("exercises") or []
        day_exercises = [
            _exercise_to_day_exercise(ex, resolver) for ex in raw_exercises
        ]
        is_rest = len(day_exercises) == 0  # #L16-equivalent / Group 3 #34
        days.append(
            {
                "day_index": idx,
                "day_name": (
                    w.get("workout_name")
                    or w.get("name")
                    or f"Day {w.get('day', idx + 1)}"
                ),
                "is_rest": is_rest,
                "workout_type": _classify_workout_type(w.get("type")),
                "difficulty": program_difficulty,
                "exercises": day_exercises,
            }
        )
    return days


def normalize_program_blob_for_preview(
    program_row: Dict[str, Any], user_id: Optional[str] = None
) -> Dict[str, Any]:
    """Build the full normalized preview payload for one `programs` row.

    Used by GET /library/{id} and as the input for POST /from-program/{id}.
    """
    resolver = ExerciseResolver(user_id=user_id)
    days = program_workouts_to_days(program_row, resolver)
    category = program_row.get("program_category")
    return {
        "name": program_row.get("program_name") or "Imported Program",
        "description": (
            program_row.get("description")
            or program_row.get("short_description")
        ),
        "category": category,
        "week_length": max(7, len(days)),  # #L10
        "days": days,
        "progression_strategy": derive_progression_strategy(category),
        "deload_every_n_weeks": derive_deload_every_n(category),
        "source_program_id": program_row.get("id"),
    }
