"""ChromaDB-independent workout exercise fallbacks (Fix 4 — bulletproof quick workout).

`generate_quick_workout` must NEVER fail for a reasonable request. When the RAG
(ChromaDB) selection times out, errors, or returns too few exercises, it falls
through these layers:

- `sql_bodyweight_exercises` — direct query of the `exercise_library_cleaned` MV
  (no ChromaDB, no LLM). Real PT-reviewed instructions live on the row; the client
  also routes instructions by exercise name. 528 bodyweight-beginner rows exist, so
  this fills almost every request.
- `static_bodyweight_exercises` — a hardcoded, INJURY-AWARE curated bodyweight set
  with canonical names (the client instruction engine routes by name, per CLAUDE.md
  — never filler). Zero external dependency: the absolute last resort that always
  returns a valid, executable workout even if ChromaDB AND embeddings are down.

Returned dicts match the shape `generate_quick_workout`'s assembly reads via `.get`:
name / reps / duration_seconds / muscle_group / body_part / equipment / notes /
gif_url / video_url / image_url / library_id.
"""
from __future__ import annotations

import random
from typing import Any, Dict, List, Optional, Set

from core.logger import get_logger

logger = get_logger(__name__)

# focus_area (from workout_tools.focus_area_map) → MV `body_part` values.
_FOCUS_TO_BODY_PARTS: Dict[str, List[str]] = {
    "full_body": ["full body", "chest", "back", "upper legs", "shoulders", "waist"],
    "full_body_power": ["cardio", "full body", "upper legs"],
    "chest": ["chest", "shoulders", "upper arms"],
    "back": ["back", "upper arms"],
    "shoulders": ["shoulders", "upper arms"],
    "arms": ["upper arms", "lower arms"],
    "legs": ["upper legs", "lower legs"],
    "core": ["waist"],
    "cardio": ["cardio", "full body"],
    "hiit": ["cardio", "full body", "upper legs"],
    "boxing": ["cardio", "full body", "upper arms"],
    "hyrox": ["cardio", "full body", "upper legs"],
    "crossfit": ["full body", "upper legs", "back"],
    "martial_arts": ["cardio", "full body", "upper legs"],
    "mobility": ["full body", "waist"],
    "flexibility": ["full body", "waist"],
    "strength": ["upper legs", "chest", "back"],
    "endurance": ["cardio", "full body"],
}

_ALLOWED_LEVELS: Dict[str, List[str]] = {
    "beginner": ["beginner"],
    "intermediate": ["beginner", "intermediate"],
    "advanced": ["beginner", "intermediate", "advanced"],
}

_MV = "exercise_library_cleaned"
_SELECT_COLS = (
    "id, name, body_part, equipment, target_muscle, secondary_muscles, "
    "instructions, difficulty_level, gif_url, video_url, image_url, avoid_if"
)


def _row_to_exercise(r: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "name": (r.get("name") or "").strip(),
        "reps": None,  # assembly applies adaptive default
        "duration_seconds": None,
        "muscle_group": r.get("target_muscle") or r.get("body_part") or "",
        "body_part": r.get("body_part") or "",
        "equipment": r.get("equipment") or "Bodyweight",
        "notes": "",
        "instructions": r.get("instructions") or "",
        "gif_url": r.get("gif_url") or "",
        "video_url": r.get("video_url") or "",
        "image_url": r.get("image_url") or "",
        "library_id": r.get("id") or "",
    }


def _injury_blocks(text: str, injury_parts: List[str]) -> bool:
    """True if any injured body-part keyword appears in `text` (best-effort)."""
    if not injury_parts:
        return False
    t = (text or "").lower()
    return any(p.lower().strip() in t for p in injury_parts if p)


def _norm_equip(e: str) -> str:
    return (e or "").lower().replace("_", " ").strip()


_BODYWEIGHT_EQUIP = {"bodyweight", "body weight", "none", ""}


def sql_exercises(
    db: Any,
    *,
    focus_area: str,
    fitness_level: str,
    count: int,
    equipment: Optional[List[str]] = None,
    injury_parts: Optional[List[str]] = None,
    avoid_names: Optional[Set[str]] = None,
) -> List[Dict[str, Any]]:
    """L1 (fast path) / L2 (fallback) — direct selection from the MV (no
    ChromaDB, no LLM). EQUIPMENT-AWARE: prefers exercises the user can actually
    do with their gear (incl. exotic like "hay bale", "sandbag", "tire") and
    always allows bodyweight. Best-effort injury exclusion. Never raises.

    This is the FAST primary path for the chat quick-workout: one indexed query
    + in-memory filter (~hundreds of ms) instead of a slow ChromaDB round-trip.
    """
    injury_parts = injury_parts or []
    avoid_lower = {a.lower() for a in (avoid_names or set())}
    gear_terms = [
        _norm_equip(e) for e in (equipment or [])
        if _norm_equip(e) and _norm_equip(e) not in _BODYWEIGHT_EQUIP
    ]
    parts = _FOCUS_TO_BODY_PARTS.get(focus_area, _FOCUS_TO_BODY_PARTS["full_body"])
    levels = _ALLOWED_LEVELS.get((fitness_level or "beginner").lower(), ["beginner", "intermediate"])
    rng = random.Random((hash(focus_area) ^ (count * 2654435761)) & 0xFFFFFFFF)

    out: List[Dict[str, Any]] = []
    seen: Set[str] = set()

    def _consume(rows: List[Dict[str, Any]]):
        rng.shuffle(rows)
        for r in rows:
            if len(out) >= count:
                return
            name = (r.get("name") or "").strip()
            if not name or name.lower() in seen or name.lower() in avoid_lower:
                continue
            dl = (r.get("difficulty_level") or "").lower()
            if dl and dl not in levels:
                continue
            hay = " ".join([
                str(r.get("body_part") or ""),
                str(r.get("target_muscle") or ""),
                str(r.get("avoid_if") or ""),
            ])
            if _injury_blocks(hay, injury_parts):
                continue
            out.append(_row_to_exercise(r))
            seen.add(name.lower())

    # Pass 1 — when the user named real gear (incl. exotic like "hay bale"),
    # query it DIRECTLY via an OR of ilike filters so rare equipment (a handful
    # of rows) actually surfaces. Honors the focus's body parts first; if that's
    # too narrow for the gear, retry gear without the body-part restriction so
    # the user's request ("work out with a hay bale") is genuinely respected.
    if gear_terms:
        or_filter = ",".join(f"equipment.ilike.*{g}*" for g in gear_terms)
        for restrict_parts in (True, False):
            if len(out) >= count:
                break
            try:
                gq = db.client.table(_MV).select(_SELECT_COLS).or_(or_filter)
                if restrict_parts:
                    gq = gq.in_("body_part", parts)
                _consume((gq.limit(120).execute()).data or [])
            except Exception as e:
                logger.warning(f"[WorkoutFallback] gear query failed: {e}")

    # Pass 2 — bodyweight top-up (always available) to reach `count`.
    if len(out) < count:
        try:
            bq = (
                db.client.table(_MV).select(_SELECT_COLS)
                .in_("body_part", parts)
                .ilike("equipment", "%bodyweight%")
                .limit(160)
                .execute()
            )
            _consume(bq.data or [])
        except Exception as e:
            logger.warning(f"[WorkoutFallback] bodyweight query failed: {e}")

    return out[:count]


# Back-compat alias (older callers).
def sql_bodyweight_exercises(db, **kwargs):
    return sql_exercises(db, **kwargs)


# ── L3 — static curated bodyweight set (zero external dependency) ─────────────
# Canonical names (the client's name-routed instruction engine supplies correct,
# technique-specific instructions — never filler, per CLAUDE.md). Each entry:
#   (name, muscle_group, mode, value, unsafe_for)
# mode "reps" → value reps; mode "time" → value seconds. unsafe_for = injury
# keywords that make the move inappropriate (matched as substrings against the
# resolved hard-avoid body parts).
_R, _T = "reps", "time"

_UNIVERSAL_SAFE = [
    ("Dead Bug", "waist", _T, 40, set()),
    ("Bird-Dog", "back", _T, 40, set()),
    ("Glute Bridge", "upper legs", _R, 15, {"lower back"}),
    ("Standing Calf Raise", "lower legs", _R, 20, {"ankle"}),
    ("Marching in Place", "cardio", _T, 45, set()),
    ("Cat-Cow", "waist", _T, 40, set()),
]

_STATIC: Dict[str, List[tuple]] = {
    "full_body": [
        ("Bodyweight Squat", "upper legs", _R, 15, {"knee", "hip", "ankle"}),
        ("Push-Up", "chest", _R, 12, {"wrist", "shoulder", "elbow"}),
        ("Plank", "waist", _T, 40, {"wrist", "shoulder", "lower back"}),
        ("Reverse Lunge", "upper legs", _R, 12, {"knee", "hip", "ankle"}),
        ("Glute Bridge", "upper legs", _R, 15, {"lower back"}),
        ("Mountain Climber", "cardio", _T, 40, {"wrist", "shoulder", "knee"}),
        ("Superman", "back", _R, 15, {"lower back"}),
        ("Jumping Jack", "cardio", _T, 45, {"knee", "ankle", "hip"}),
    ],
    "chest": [
        ("Push-Up", "chest", _R, 12, {"wrist", "shoulder", "elbow"}),
        ("Incline Push-Up", "chest", _R, 14, {"wrist", "shoulder"}),
        ("Pike Push-Up", "shoulders", _R, 10, {"wrist", "shoulder"}),
        ("Tricep Dips (Chair)", "upper arms", _R, 12, {"shoulder", "elbow", "wrist"}),
        ("Plank Shoulder Tap", "waist", _T, 40, {"wrist", "shoulder"}),
        ("Wall Push-Up", "chest", _R, 15, set()),
    ],
    "back": [
        ("Superman", "back", _R, 15, {"lower back"}),
        ("Bird-Dog", "back", _T, 40, set()),
        ("Reverse Snow Angel", "back", _R, 15, {"shoulder"}),
        ("Prone Y-T-W Raise", "back", _R, 10, {"shoulder"}),
        ("Doorway Row", "back", _R, 12, {"elbow"}),
        ("Glute Bridge", "upper legs", _R, 15, {"lower back"}),
    ],
    "shoulders": [
        ("Pike Push-Up", "shoulders", _R, 10, {"wrist", "shoulder"}),
        ("Reverse Snow Angel", "shoulders", _R, 15, {"shoulder"}),
        ("Plank Shoulder Tap", "waist", _T, 40, {"wrist", "shoulder"}),
        ("Wall Push-Up", "chest", _R, 15, set()),
        ("Prone Y-T-W Raise", "shoulders", _R, 10, {"shoulder"}),
    ],
    "arms": [
        ("Tricep Dips (Chair)", "upper arms", _R, 12, {"shoulder", "elbow", "wrist"}),
        ("Diamond Push-Up", "upper arms", _R, 10, {"wrist", "elbow", "shoulder"}),
        ("Push-Up", "chest", _R, 12, {"wrist", "shoulder", "elbow"}),
        ("Plank Shoulder Tap", "waist", _T, 40, {"wrist", "shoulder"}),
    ],
    "legs": [
        ("Bodyweight Squat", "upper legs", _R, 15, {"knee", "hip", "ankle"}),
        ("Reverse Lunge", "upper legs", _R, 12, {"knee", "hip", "ankle"}),
        ("Glute Bridge", "upper legs", _R, 15, {"lower back"}),
        ("Wall Sit", "upper legs", _T, 40, {"knee"}),
        ("Standing Calf Raise", "lower legs", _R, 20, {"ankle"}),
        ("Clamshell", "upper legs", _R, 15, set()),
        ("Standing Hip Abduction", "upper legs", _R, 15, set()),
    ],
    "core": [
        ("Plank", "waist", _T, 40, {"wrist", "shoulder", "lower back"}),
        ("Dead Bug", "waist", _T, 40, set()),
        ("Bicycle Crunch", "waist", _R, 20, {"neck", "lower back"}),
        ("Mountain Climber", "cardio", _T, 40, {"wrist", "shoulder", "knee"}),
        ("Hollow Hold", "waist", _T, 30, {"lower back"}),
        ("Bird-Dog", "back", _T, 40, set()),
    ],
    "cardio": [
        ("Jumping Jack", "cardio", _T, 45, {"knee", "ankle", "hip"}),
        ("Mountain Climber", "cardio", _T, 40, {"wrist", "shoulder", "knee"}),
        ("High Knees", "cardio", _T, 40, {"knee", "ankle", "hip"}),
        ("Squat to Stand", "upper legs", _R, 15, {"knee", "hip"}),
        ("Marching in Place", "cardio", _T, 45, set()),
        ("Standing Knee Raise", "waist", _T, 40, set()),
    ],
    "mobility": [
        ("Cat-Cow", "waist", _T, 40, set()),
        ("World's Greatest Stretch", "full body", _T, 45, set()),
        ("Hip Circles", "upper legs", _T, 30, set()),
        ("Shoulder Rolls", "shoulders", _T, 30, set()),
        ("Standing Hamstring Stretch", "upper legs", _T, 40, set()),
        ("Child's Pose", "back", _T, 45, set()),
    ],
}
# Aliases → reuse the closest curated list.
_STATIC["full_body_power"] = _STATIC["cardio"]
_STATIC["hiit"] = _STATIC["cardio"]
_STATIC["boxing"] = _STATIC["cardio"]
_STATIC["hyrox"] = _STATIC["cardio"]
_STATIC["crossfit"] = _STATIC["full_body"]
_STATIC["martial_arts"] = _STATIC["cardio"]
_STATIC["flexibility"] = _STATIC["mobility"]
_STATIC["strength"] = _STATIC["full_body"]
_STATIC["endurance"] = _STATIC["cardio"]
_STATIC["upper"] = _STATIC["chest"]
_STATIC["lower"] = _STATIC["legs"]


def _static_tuple_to_exercise(t: tuple) -> Dict[str, Any]:
    name, muscle, mode, value, _unsafe = t
    return {
        "name": name,
        "reps": value if mode == _R else None,
        "duration_seconds": value if mode == _T else None,
        "muscle_group": muscle,
        "body_part": muscle,
        "equipment": "Bodyweight",
        "notes": "",
        "instructions": "",  # client routes instructions by canonical name
        "gif_url": "",
        "video_url": "",
        "image_url": "",
        "library_id": "",
    }


def static_bodyweight_exercises(
    *,
    focus_area: str,
    count: int,
    injury_parts: Optional[List[str]] = None,
    avoid_names: Optional[Set[str]] = None,
) -> List[Dict[str, Any]]:
    """L3 — ALWAYS returns ≥min(count, available) injury-safe bodyweight moves.

    Filters the focus's curated set by injury, then tops up from the universal-
    safe pool so a focus⇄injury collision (e.g. leg day + knee injury) still
    yields a real workout (glute bridge, dead bug, bird-dog, calf raise, …).
    """
    injury_parts = [p.lower().strip() for p in (injury_parts or []) if p]
    avoid_lower = {a.lower() for a in (avoid_names or set())}
    pool = _STATIC.get(focus_area) or _STATIC["full_body"]

    def _safe(t: tuple) -> bool:
        _name, _m, _mode, _v, unsafe = t
        if _name.lower() in avoid_lower:
            return False
        for inj in injury_parts:
            if any(u in inj or inj in u for u in unsafe):
                return False
        return True

    chosen: List[tuple] = [t for t in pool if _safe(t)]
    seen = {t[0].lower() for t in chosen}
    # Top up from the universal-safe pool if injury filtering thinned it out.
    for t in _UNIVERSAL_SAFE:
        if len(chosen) >= count:
            break
        if t[0].lower() in seen or not _safe(t):
            continue
        chosen.append(t)
        seen.add(t[0].lower())
    # Absolute floor: if everything got filtered (extreme injury stack), the
    # universal-safe pool minus injuries still leaves Dead Bug / Bird-Dog /
    # Cat-Cow for nearly any injury — but guarantee at least one move.
    if not chosen:
        chosen = [_UNIVERSAL_SAFE[0], _UNIVERSAL_SAFE[1], _UNIVERSAL_SAFE[5]]
    return [_static_tuple_to_exercise(t) for t in chosen[:count]]


def merge_unique(*lists: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Concatenate exercise lists, de-duping by lowercased name, order-preserving."""
    out: List[Dict[str, Any]] = []
    seen: Set[str] = set()
    for lst in lists:
        for ex in lst or []:
            key = (ex.get("name") or "").strip().lower()
            if not key or key in seen:
                continue
            out.append(ex)
            seen.add(key)
    return out
