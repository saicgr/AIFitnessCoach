"""
Exercise-name resolver.

Turns a raw exercise name as written in a fitness-app export ("DB Row",
"Bench Press (Barbell)", "BB Deadlift", "flat bench press") into a canonical
name + (where possible) an exercise_id FK into the exercise library.

Four-level cascade — each level is cheap until the last one, so most imports
resolve at level 1 or 2 without touching the RAG service at all:

  1. Hand-curated alias dict  (O(1) lookup, ~60% of inbound names)
  2. Exact lowercase + punct-stripped match on exercise_library.name
  3. ExerciseRAGService semantic search (similarity >= threshold)
  4. Unresolved — returns the canonicalized raw name so aggregation still works
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional
from uuid import UUID

from core.logger import get_logger

logger = get_logger(__name__)


# Top ~250 exercise aliases across Hevy, Strong, Fitbod, Jefit, FitNotes,
# Jeff Nippard sheets, RP templates, Wendler, nSuns, GZCLP, Metallicadpa,
# Starting Strength, and common Google Sheets templates.
#
# Keys are fully normalized (lowercase, punctuation stripped, collapsed
# whitespace). Values are the canonical exercise_library.name slug.
# Keep this file flat — no imports, no fancy tables — so it stays diff-able.
EXERCISE_ALIASES: dict[str, str] = {
    # ── Barbell compound lifts ──
    "bench press": "barbell_bench_press",
    "bench press barbell": "barbell_bench_press",
    "barbell bench press": "barbell_bench_press",
    "bb bench press": "barbell_bench_press",
    "bb bench": "barbell_bench_press",
    "flat bench press": "barbell_bench_press",
    "flat barbell bench press": "barbell_bench_press",
    "bench press flat": "barbell_bench_press",
    "barbell flat bench press": "barbell_bench_press",
    "incline bench press": "barbell_incline_bench_press",
    "incline barbell bench press": "barbell_incline_bench_press",
    "incline bench press barbell": "barbell_incline_bench_press",
    "decline bench press": "barbell_decline_bench_press",
    "decline barbell bench press": "barbell_decline_bench_press",
    "close grip bench press": "barbell_close_grip_bench_press",
    "close grip bench": "barbell_close_grip_bench_press",
    "cgbp": "barbell_close_grip_bench_press",
    "squat": "barbell_back_squat",
    "back squat": "barbell_back_squat",
    "barbell back squat": "barbell_back_squat",
    "bb squat": "barbell_back_squat",
    "low bar squat": "barbell_back_squat",
    "high bar squat": "barbell_back_squat",
    "high bar back squat": "barbell_back_squat",
    "front squat": "barbell_front_squat",
    "barbell front squat": "barbell_front_squat",
    "deadlift": "barbell_deadlift",
    "conventional deadlift": "barbell_deadlift",
    "barbell deadlift": "barbell_deadlift",
    "bb deadlift": "barbell_deadlift",
    "dealift": "barbell_deadlift",  # common typo
    "sumo deadlift": "barbell_sumo_deadlift",
    "romanian deadlift": "barbell_romanian_deadlift",
    "rdl": "barbell_romanian_deadlift",
    "barbell rdl": "barbell_romanian_deadlift",
    "stiff leg deadlift": "barbell_stiff_leg_deadlift",
    "overhead press": "barbell_overhead_press",
    "ohp": "barbell_overhead_press",
    "military press": "barbell_overhead_press",
    "standing overhead press": "barbell_overhead_press",
    "barbell overhead press": "barbell_overhead_press",
    "press": "barbell_overhead_press",
    "push press": "barbell_push_press",
    "barbell push press": "barbell_push_press",
    "barbell row": "barbell_bent_over_row",
    "bent over row": "barbell_bent_over_row",
    "bent over barbell row": "barbell_bent_over_row",
    "bor": "barbell_bent_over_row",
    "bb row": "barbell_bent_over_row",
    "pendlay row": "barbell_pendlay_row",
    "t bar row": "t_bar_row",
    "t-bar row": "t_bar_row",
    "power clean": "barbell_power_clean",
    "power cleans": "barbell_power_clean",
    "clean": "barbell_power_clean",
    "hang clean": "barbell_hang_clean",
    "clean and press": "barbell_clean_and_press",
    "snatch": "barbell_snatch",
    "hip thrust": "barbell_hip_thrust",
    "barbell hip thrust": "barbell_hip_thrust",
    "glute bridge": "barbell_glute_bridge",
    "good morning": "barbell_good_morning",

    # ── Dumbbell variants ──
    "db bench press": "dumbbell_bench_press",
    "dumbbell bench press": "dumbbell_bench_press",
    "dumbell bench press": "dumbbell_bench_press",  # common misspelling
    "db bench": "dumbbell_bench_press",
    "flat dumbbell bench press": "dumbbell_bench_press",
    "incline dumbbell bench press": "dumbbell_incline_bench_press",
    "incline db press": "dumbbell_incline_bench_press",
    "incline db bench": "dumbbell_incline_bench_press",
    "decline dumbbell bench press": "dumbbell_decline_bench_press",
    "db shoulder press": "dumbbell_shoulder_press",
    "dumbbell shoulder press": "dumbbell_shoulder_press",
    "dumbbell overhead press": "dumbbell_shoulder_press",
    "seated dumbbell press": "dumbbell_seated_shoulder_press",
    "db press": "dumbbell_shoulder_press",
    "db fly": "dumbbell_fly",
    "dumbbell fly": "dumbbell_fly",
    "dumbbell flyes": "dumbbell_fly",
    "dumbbell flys": "dumbbell_fly",
    "db row": "dumbbell_row",
    "dumbbell row": "dumbbell_row",
    "single arm dumbbell row": "dumbbell_row",
    "one arm dumbbell row": "dumbbell_row",
    "db curl": "dumbbell_bicep_curl",
    "dumbbell curl": "dumbbell_bicep_curl",
    "dumbbell bicep curl": "dumbbell_bicep_curl",
    "bicep curl": "dumbbell_bicep_curl",
    "hammer curl": "dumbbell_hammer_curl",
    "dumbbell hammer curl": "dumbbell_hammer_curl",
    "incline curl": "dumbbell_incline_curl",
    "incline dumbbell curl": "dumbbell_incline_curl",
    "dumbbell lateral raise": "dumbbell_lateral_raise",
    "lateral raise": "dumbbell_lateral_raise",
    "side raise": "dumbbell_lateral_raise",
    "side lateral raise": "dumbbell_lateral_raise",
    "front raise": "dumbbell_front_raise",
    "rear delt fly": "dumbbell_rear_delt_fly",
    "reverse fly": "dumbbell_rear_delt_fly",
    "dumbbell shrug": "dumbbell_shrug",
    "shrug": "dumbbell_shrug",
    "db lunge": "dumbbell_lunge",
    "dumbbell lunge": "dumbbell_lunge",
    "walking lunge": "dumbbell_walking_lunge",
    "reverse lunge": "dumbbell_reverse_lunge",
    "bulgarian split squat": "dumbbell_bulgarian_split_squat",
    "bss": "dumbbell_bulgarian_split_squat",
    "goblet squat": "dumbbell_goblet_squat",
    "db romanian deadlift": "dumbbell_romanian_deadlift",
    "dumbbell rdl": "dumbbell_romanian_deadlift",
    "db tricep extension": "dumbbell_tricep_extension",
    "dumbbell tricep extension": "dumbbell_tricep_extension",
    "overhead tricep extension": "dumbbell_overhead_tricep_extension",
    "skullcrusher": "dumbbell_skullcrusher",
    "skull crusher": "dumbbell_skullcrusher",
    "lying tricep extension": "dumbbell_skullcrusher",

    # ── Cable / machine ──
    "cable row": "cable_seated_row",
    "seated cable row": "cable_seated_row",
    "low row": "cable_seated_row",
    "lat pulldown": "cable_lat_pulldown",
    "pulldown": "cable_lat_pulldown",
    "wide grip pulldown": "cable_lat_pulldown",
    "close grip pulldown": "cable_close_grip_lat_pulldown",
    "cable tricep pushdown": "cable_tricep_pushdown",
    "tricep pushdown": "cable_tricep_pushdown",
    "rope pushdown": "cable_rope_pushdown",
    "cable curl": "cable_bicep_curl",
    "cable bicep curl": "cable_bicep_curl",
    "cable lateral raise": "cable_lateral_raise",
    "cable crossover": "cable_crossover",
    "cable fly": "cable_crossover",
    "face pull": "cable_face_pull",
    "cable face pull": "cable_face_pull",
    "cable row machine": "cable_seated_row",
    "leg press": "machine_leg_press",
    "hack squat": "machine_hack_squat",
    "leg extension": "machine_leg_extension",
    "leg curl": "machine_leg_curl",
    "lying leg curl": "machine_lying_leg_curl",
    "seated leg curl": "machine_seated_leg_curl",
    "calf raise": "machine_calf_raise",
    "standing calf raise": "machine_standing_calf_raise",
    "seated calf raise": "machine_seated_calf_raise",
    "chest press": "machine_chest_press",
    "chest press machine": "machine_chest_press",
    "pec deck": "machine_pec_deck",
    "pec dec": "machine_pec_deck",
    "smith machine bench press": "smith_machine_bench_press",
    "smith machine squat": "smith_machine_squat",
    "hammer strength row": "machine_row",
    "hammerstrength row": "machine_row",
    "prime incline press": "machine_incline_chest_press",

    # ── Bodyweight ──
    "push up": "bodyweight_push_up",
    "push ups": "bodyweight_push_up",
    "push-up": "bodyweight_push_up",
    "push-ups": "bodyweight_push_up",
    "pushup": "bodyweight_push_up",
    "pushups": "bodyweight_push_up",
    "pull up": "bodyweight_pull_up",
    "pull ups": "bodyweight_pull_up",
    "pull-up": "bodyweight_pull_up",
    "pullup": "bodyweight_pull_up",
    "pullups": "bodyweight_pull_up",
    "chin up": "bodyweight_chin_up",
    "chin-up": "bodyweight_chin_up",
    "chinup": "bodyweight_chin_up",
    "dip": "bodyweight_dip",
    "dips": "bodyweight_dip",
    "tricep dip": "bodyweight_dip",
    "plank": "bodyweight_plank",
    "side plank": "bodyweight_side_plank",
    "sit up": "bodyweight_sit_up",
    "situp": "bodyweight_sit_up",
    "crunch": "bodyweight_crunch",
    "crunches": "bodyweight_crunch",
    "leg raise": "bodyweight_leg_raise",
    "hanging leg raise": "bodyweight_hanging_leg_raise",
    "hanging knee raise": "bodyweight_hanging_knee_raise",
    "mountain climber": "bodyweight_mountain_climber",
    "burpee": "bodyweight_burpee",
    "air squat": "bodyweight_air_squat",
    "pistol squat": "bodyweight_pistol_squat",
    "archer push up": "bodyweight_archer_push_up",
    "archer push-up": "bodyweight_archer_push_up",
    "pike push up": "bodyweight_pike_push_up",
    "handstand push up": "bodyweight_handstand_push_up",
    "hollow body hold": "bodyweight_hollow_body_hold",
    "glute bridge bw": "bodyweight_glute_bridge",
    "bodyweight glute bridge": "bodyweight_glute_bridge",

    # ── Cardio activity labels (Strong / Fitbod sometimes emit these as
    # "exercises" even though they map to cardio_logs downstream) ──
    "running": "cardio_running",
    "run": "cardio_running",
    "treadmill": "cardio_treadmill",
    "walking": "cardio_walking",
    "walk": "cardio_walking",
    "cycling": "cardio_cycling",
    "bike": "cardio_cycling",
    "stationary bike": "cardio_stationary_bike",
    "rowing": "cardio_rowing",
    "row machine": "cardio_rowing",
    "elliptical": "cardio_elliptical",
    "stairmaster": "cardio_stairmaster",
    "stair climber": "cardio_stairmaster",
    "swimming": "cardio_swimming",
    "jump rope": "cardio_jump_rope",

    # ── Foreign-language top entries (rough coverage — resolver level 3
    # catches the long tail via semantic search) ──
    "sentadilla": "barbell_back_squat",             # es
    "peso muerto": "barbell_deadlift",              # es
    "press de banca": "barbell_bench_press",        # es
    "kniebeuge": "barbell_back_squat",              # de
    "kreuzheben": "barbell_deadlift",               # de
    "bankdrücken": "barbell_bench_press",           # de
    "bankdrucken": "barbell_bench_press",
    "squat arrière": "barbell_back_squat",          # fr
    "développé couché": "barbell_bench_press",      # fr
    "soulevé de terre": "barbell_deadlift",         # fr
    "スクワット": "barbell_back_squat",              # ja
    "デッドリフト": "barbell_deadlift",
    "ベンチプレス": "barbell_bench_press",
}


# Characters we strip before normalization — punctuation, parens, em-dashes,
# and the hyperlink marker occasionally left in by Excel paste.
_STRIP_CHARS = re.compile(r"[()\[\]{}.,;:!?\"'`/\\<>|#@$%^&*+=~_\-—–]")


def _normalize(name: str) -> str:
    """Lowercase, strip punctuation, collapse whitespace. Keeps letters
    + digits only."""
    # Preserve leading/trailing meaningful content, strip hyperlinks.
    stripped = str(name).strip()
    if not stripped:
        return ""
    # Strip trailing parenthetical qualifier if it's only equipment:
    # "Bench Press (Barbell)" → "Bench Press"  (then we look up "bench press")
    stripped = re.sub(r"\s*\([^)]*\)\s*$", " ", stripped).strip()
    # Strip emoji / pictograms — broad unicode range.
    stripped = re.sub(r"[\U0001F300-\U0001FAFF\U0001F000-\U0001F1FF]", " ", stripped)
    # Strip punctuation.
    stripped = _STRIP_CHARS.sub(" ", stripped)
    # Collapse whitespace + lowercase.
    return re.sub(r"\s+", " ", stripped.lower()).strip()


@dataclass
class ResolvedExercise:
    """The result of one resolution attempt."""
    exercise_id: Optional[UUID]
    canonical_name: str          # always populated (falls back to normalized raw)
    confidence: float            # 1.0 alias → 0.95 exact → 0.78+ RAG → 0.0 unresolved
    level: int                   # 1 alias | 2 exact | 3 rag | 4 unresolved


class ExerciseResolver:
    """Stateful resolver with caching — one instance per import job is fine."""

    RAG_SIMILARITY_FLOOR = 0.78

    def __init__(self):
        self._cache: dict[str, ResolvedExercise] = {}
        self._rag_service = None   # lazy
        self._library_cache: Optional[dict[str, tuple[UUID, str]]] = None

    def resolve(self, raw_name: str) -> ResolvedExercise:
        """Run the four-level cascade. Caches results for the life of the
        instance so batch imports don't repeat lookups for the same name."""
        key = _normalize(raw_name)
        if not key:
            return ResolvedExercise(None, raw_name or "unknown", 0.0, 4)

        if key in self._cache:
            return self._cache[key]

        # Level 1: alias dict
        if key in EXERCISE_ALIASES:
            canonical = EXERCISE_ALIASES[key]
            result = ResolvedExercise(None, canonical, 1.0, 1)
            # Try to back-fill the exercise_id from the library cache below.
            lib = self._get_library_cache()
            if lib and canonical in lib:
                eid, display_name = lib[canonical]
                result = ResolvedExercise(eid, display_name, 1.0, 1)
            self._cache[key] = result
            return result

        # Level 2: exact normalized match against library
        lib = self._get_library_cache()
        if lib:
            # Library names normalized the same way for direct lookup.
            lib_by_normalized = {_normalize(display): (eid, display) for _, (eid, display) in lib.items()}
            if key in lib_by_normalized:
                eid, display_name = lib_by_normalized[key]
                result = ResolvedExercise(eid, display_name, 0.95, 2)
                self._cache[key] = result
                return result

        # Level 3: RAG semantic search
        rag_hit = self._rag_lookup(raw_name)
        if rag_hit is not None:
            eid, canonical, sim = rag_hit
            if sim >= self.RAG_SIMILARITY_FLOOR:
                result = ResolvedExercise(eid, canonical, float(sim), 3)
                self._cache[key] = result
                return result

        # Level 4: unresolved — canonicalize to normalized form so aggregation
        # still collapses case/punctuation variants.
        result = ResolvedExercise(None, key.replace(" ", "_"), 0.0, 4)
        self._cache[key] = result
        return result

    def _get_library_cache(self) -> Optional[dict[str, tuple[UUID, str]]]:
        """Load {canonical_slug: (exercise_id, display_name)} from the
        exercise_library table once per resolver instance. Returns None on
        failure — caller falls through to the next cascade level."""
        if self._library_cache is not None:
            return self._library_cache
        try:
            from core.db import get_supabase_db

            db = get_supabase_db()
            # PostgREST caps at max_rows (typically 1000); paginate explicitly.
            cache: dict[str, tuple[UUID, str]] = {}
            page_size = 1000
            offset = 0
            while True:
                result = db.client.table("exercise_library") \
                    .select("id, exercise_name") \
                    .range(offset, offset + page_size - 1) \
                    .execute()
                rows = result.data or []
                if not rows:
                    break
                for row in rows:
                    name = row.get("exercise_name")
                    if not name:
                        continue
                    slug = name.lower().strip().replace(" ", "_").replace("-", "_")
                    # Prefer first insert — library has near-duplicates (e.g.
                    # "barbell bench press" + "barbell bench press_female").
                    cache.setdefault(slug, (UUID(row["id"]), name))
                if len(rows) < page_size:
                    break
                offset += page_size
            self._library_cache = cache
            return cache
        except Exception as e:
            logger.warning(f"[ExerciseResolver] Library cache load failed: {e}")
            self._library_cache = {}
            return None

    def _rag_lookup(self, raw_name: str) -> Optional[tuple[Optional[UUID], str, float]]:
        """Query the existing fitness_exercises ChromaDB collection via the
        ExerciseRAGService. Returns (exercise_id_or_none, canonical_name,
        similarity) of the top result, or None on any failure."""
        try:
            if self._rag_service is None:
                from services.exercise_rag_service import ExerciseRAGService  # noqa: WPS433
                self._rag_service = ExerciseRAGService()

            # Use a simple similarity search; depends on the method surface
            # the service exposes. We wrap in try/except to stay resilient
            # against changes in the RAG service API.
            matches = self._rag_service.search_by_name(raw_name, n_results=1) if hasattr(
                self._rag_service, "search_by_name"
            ) else None
            if not matches:
                return None
            top = matches[0]
            eid = top.get("id") or top.get("exercise_id")
            similarity = float(top.get("similarity") or top.get("score") or 0.0)
            canonical = top.get("name") or top.get("canonical_name") or raw_name
            return (UUID(eid) if eid else None, canonical, similarity)
        except Exception as e:
            logger.debug(f"[ExerciseResolver] RAG lookup failed for '{raw_name}': {e}")
            return None


# Module-level convenience singleton (cleared between job runs by callers
# that need fresh library cache).
_default_resolver: Optional[ExerciseResolver] = None


def get_default_resolver() -> ExerciseResolver:
    global _default_resolver
    if _default_resolver is None:
        _default_resolver = ExerciseResolver()
    return _default_resolver


def reset_default_resolver() -> None:
    """Dump the cache — useful when the alias dict or library changes at runtime."""
    global _default_resolver
    _default_resolver = None
