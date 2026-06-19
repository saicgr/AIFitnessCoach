"""Exercise → muscle-group resolver (Strength-Score breadth, 2026-06).

THE PROBLEM this fixes (Reddit/Gravl complaint): the strength score only reflected a
small set of hand-mapped exercises per muscle. Anyone training mostly on machines,
cables, or accessory movements saw their work under-counted because
``StrengthCalculatorService.get_exercise_muscle_groups`` returned ``[]`` for names that
weren't in the ~30-entry static ``EXERCISE_MUSCLE_GROUPS`` map and weren't carrying
AI-declared muscle metadata (older machine logs have none).

THE FIX: a data-driven tier that reads the app's own ``exercise_library_cleaned`` view
(1000s of exercises with a ``target_muscle`` / ``body_part`` / ``secondary_muscles``
free-text description) and normalizes that messy anatomical text into the 16 canonical
``MuscleGroup`` values. This is a CLOSED vocabulary derived from our own library (not
open user input), so it does not violate the no-hardcoded-enumerations rule — and it is
applied as a *fallback tier* only, so the fast hand-curated map still wins.

The library text looks like:
    "quadriceps (quadriceps femoris), glutes (gluteus maximus, gluteus medius)"
    "hamstrings (biceps femoris, semitendinosus, semimembranosus)"
    "shoulders (posterior deltoids)"
so a naive substring scan would map "biceps femoris" → biceps and "posterior deltoids"
→ shoulders. We avoid that with a PRIORITY-ORDERED, CONSUMING scan: the most specific
anatomical phrases are matched first and removed from the working string before the
generic ones are tested.

Public API:
    NORMALIZE_LIBRARY_MUSCLE  - documented keyword→muscle priority table
    text_to_muscles(text)     - free-text anatomy → ordered, de-duped [MuscleGroup,...]
    build_library_muscle_index(supabase) -> {normalized_name: {"muscles": [...], "equipment": str}}
    resolve_muscles(name, exercise_data, library_index) -> [MuscleGroup,...]
"""
from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

# The 16 canonical scored muscle groups (must match MuscleGroup enum in
# strength_calculator_service.py). Listed here only for validation/clarity.
VALID_MUSCLE_GROUPS = {
    "chest", "back", "shoulders", "rear_delts", "biceps", "triceps", "forearms",
    "quads", "hamstrings", "glutes", "adductors", "calves", "core", "obliques",
    "lower_back", "traps",
}

# PRIORITY-ORDERED keyword → muscle table. Order is LOAD-BEARING: each (keyword,
# muscle) is tested in sequence against a working copy of the text, and every match
# removes the keyword's occurrences from that copy so later (more generic) keywords
# can't re-match the same anatomy. So always put the most specific disambiguating
# phrase BEFORE the generic root it shares characters with, e.g.:
#   * "biceps femoris" (hamstrings) BEFORE "biceps" (biceps)
#   * "posterior deltoid"/"rear delt" (rear_delts) BEFORE "deltoid"/"shoulder"
#   * "triceps" BEFORE "biceps" so "triceps brachii" is consumed (avoids brachii bleed)
#   * "lower back"/"erector spinae" (lower_back) BEFORE generic "back"
#   * "upper/middle back", "lat", "rhomboid", "teres" (back) BEFORE generic "back"
#   * "trapezius"/"trap" (traps) handled before generic back catch-all
# Tokens that don't map to a SCORED group (hip flexors, rotator cuff detail, neck,
# cardio, full body, diaphragm, tibialis) are intentionally absent → dropped, never
# invented into a wrong bucket.
NORMALIZE_LIBRARY_MUSCLE: List[tuple] = [
    # ── Hamstrings (consume before "biceps") ─────────────────────────────────
    ("biceps femoris", "hamstrings"),
    ("semitendinosus", "hamstrings"),
    ("semimembranosus", "hamstrings"),
    ("hamstring", "hamstrings"),
    # ── Quads ────────────────────────────────────────────────────────────────
    ("quadriceps", "quads"),
    ("rectus femoris", "quads"),
    ("vastus", "quads"),
    ("quads", "quads"),
    # ── Adductors / inner thigh ──────────────────────────────────────────────
    ("adductor", "adductors"),
    ("inner thigh", "adductors"),
    # ── Abductors / TFL → glutes (gluteus medius/minimus region) ─────────────
    ("abductor", "glutes"),
    ("tensor fasciae", "glutes"),
    # ── Glutes ───────────────────────────────────────────────────────────────
    ("gluteus", "glutes"),
    ("glute", "glutes"),
    # ── Calves ───────────────────────────────────────────────────────────────
    ("gastrocnemius", "calves"),
    ("soleus", "calves"),
    ("calves", "calves"),
    ("calf", "calves"),
    # ── Lower back (consume before generic "back") ──────────────────────────-
    ("erector spinae", "lower_back"),
    ("lower back", "lower_back"),
    # ── Traps (consume "trapezius"/"upper trap" before generic back) ────────-
    ("trapezius", "traps"),
    ("upper trap", "traps"),
    ("traps", "traps"),
    # ── Back (lats/rhomboids/teres + qualified backs before generic "back") ──
    ("latissimus", "back"),
    ("lats", "back"),
    ("rhomboid", "back"),
    ("teres", "back"),
    ("middle back", "back"),
    ("mid back", "back"),
    ("upper back", "back"),
    ("back", "back"),
    # ── Rear delts (consume before generic deltoid/shoulder) ─────────────────
    ("posterior deltoid", "rear_delts"),
    ("rear deltoid", "rear_delts"),
    ("rear delt", "rear_delts"),
    ("rear shoulder", "rear_delts"),
    # ── Shoulders ────────────────────────────────────────────────────────────
    ("anterior deltoid", "shoulders"),
    ("lateral deltoid", "shoulders"),
    ("front shoulder", "shoulders"),
    ("deltoid", "shoulders"),
    ("delts", "shoulders"),
    ("rotator cuff", "shoulders"),
    ("shoulder", "shoulders"),
    # ── Chest ────────────────────────────────────────────────────────────────
    ("pectoralis", "chest"),
    ("pectoral", "chest"),
    ("clavicular head", "chest"),
    ("upper chest", "chest"),
    ("chest", "chest"),
    # ── Triceps (before biceps so "triceps brachii" is consumed) ─────────────
    ("triceps", "triceps"),
    # ── Biceps (arm) ─────────────────────────────────────────────────────────
    ("biceps brachii", "biceps"),
    ("brachialis", "biceps"),
    ("biceps", "biceps"),
    # ── Forearms (brachioradialis is forearm, not biceps) ────────────────────
    ("brachioradialis", "forearms"),
    ("flexor carpi", "forearms"),
    ("extensor carpi", "forearms"),
    ("flexor digitorum", "forearms"),
    ("extensor digitorum", "forearms"),
    ("wrist", "forearms"),
    ("grip", "forearms"),
    ("forearm", "forearms"),
    # ── Obliques (consume before generic abdominal/core) ─────────────────────
    ("oblique", "obliques"),
    # ── Core / abs ───────────────────────────────────────────────────────────
    ("rectus abdominis", "core"),
    ("transverse abdominis", "core"),
    ("abdominal", "core"),
    ("abdominals", "core"),
    ("abs", "core"),
    ("core", "core"),
]

# Coarse body_part → muscle fallback, used ONLY when target_muscle yields nothing.
# Deliberately maps to a single best-guess primary; ambiguous parts (upper arms,
# full body) are omitted so we never fabricate a wrong attribution.
BODY_PART_FALLBACK: Dict[str, List[str]] = {
    "chest": ["chest"],
    "back": ["back"],
    "shoulders": ["shoulders"],
    "upper legs": ["quads"],
    "lower legs": ["calves"],
    "lower arms": ["forearms"],
    "waist": ["core"],
}


def text_to_muscles(text: Optional[str]) -> List[str]:
    """Normalize a free-text anatomy description → ordered, de-duped muscle groups.

    Uses the priority-ordered CONSUMING scan documented on NORMALIZE_LIBRARY_MUSCLE.
    Returns [] for empty/unmappable text (never raises, never invents a muscle).
    """
    if not text or not isinstance(text, str):
        return []
    # Some library rows store snake_case canonical tokens (rear_delts, upper_back,
    # latissimus_dorsi, upper_chest, lower_back). Normalize underscores → spaces so
    # the keyword scan sees "rear delts" / "upper back" / "latissimus dorsi" etc.
    working = text.lower().replace("_", " ")
    result: List[str] = []
    seen: set = set()

    # Pre-pass: the library writes rear-delt work as "shoulders (posterior deltoids)".
    # That wrapper word "shoulders" would otherwise ALSO add the generic shoulders
    # group, over-crediting front/side delts. When a rear/posterior head is named the
    # movement IS a rear-delt move, so consume the wrapper "shoulder(s)" word here so
    # only rear_delts is credited. (Anterior/lateral heads map to shoulders anyway, so
    # they need no special handling.)
    _REAR_PHRASES = ("posterior deltoid", "rear deltoid", "rear delt", "rear shoulder")
    if any(p in working for p in _REAR_PHRASES):
        result.append("rear_delts")
        seen.add("rear_delts")
        for p in _REAR_PHRASES:
            working = working.replace(p, " ")
        working = working.replace("shoulders", " ").replace("shoulder", " ")

    for keyword, muscle in NORMALIZE_LIBRARY_MUSCLE:
        if keyword in working:
            if muscle not in seen:
                seen.add(muscle)
                result.append(muscle)
            # Consume the keyword everywhere so generic keywords can't re-match it.
            working = working.replace(keyword, " ")
    return result


def _split_secondary(secondary: Any) -> List[str]:
    """secondary_muscles may be a list or a comma/semicolon free-text string."""
    if isinstance(secondary, list):
        return [str(s) for s in secondary if s]
    if isinstance(secondary, str) and secondary.strip():
        return [secondary]
    return []


def build_library_muscle_index(supabase) -> Dict[str, Dict[str, Any]]:
    """One-shot index of the exercise library → {normalized_name: {muscles, equipment}}.

    Reads ``exercise_library_cleaned`` once (the strength recompute calls this a single
    time and threads the result through, so it's one query per recompute, not per
    exercise). ``muscles`` is the ordered union of target_muscle (primary) then
    secondary_muscles, normalized to canonical groups; ``equipment`` is the raw library
    equipment token (used downstream for machine-aware standards + the machine-flag).

    Fail-open: any error returns {} so the recompute silently falls back to the static
    map + AI metadata (current behavior). Never raises into the recompute.
    """
    index: Dict[str, Dict[str, Any]] = {}
    try:
        resp = (
            supabase.table("exercise_library_cleaned")
            .select("name, original_name, target_muscle, body_part, secondary_muscles, equipment")
            .execute()
        )
        rows = resp.data or []
    except Exception as e:  # noqa: BLE001 - view may be absent in some envs
        logger.warning(f"build_library_muscle_index failed (non-fatal, falling back): {e}")
        return {}

    unmapped_samples: set = set()
    for row in rows:
        muscles = text_to_muscles(row.get("target_muscle"))
        for sec in _split_secondary(row.get("secondary_muscles")):
            for m in text_to_muscles(sec):
                if m not in muscles:
                    muscles.append(m)
        if not muscles:
            # Last resort: coarse body_part bucket.
            muscles = BODY_PART_FALLBACK.get(
                str(row.get("body_part") or "").strip().lower(), []
            )
        if not muscles:
            tm = str(row.get("target_muscle") or "").strip().lower()
            if tm and len(unmapped_samples) < 40:
                unmapped_samples.add(tm)
            continue
        equipment = row.get("equipment")
        for name_key in (row.get("name"), row.get("original_name")):
            norm = _norm_name(name_key)
            if norm:
                # First write wins; prefer the richer (more muscles) entry on collision.
                existing = index.get(norm)
                if existing is None or len(muscles) > len(existing["muscles"]):
                    index[norm] = {"muscles": muscles, "equipment": equipment}

    if unmapped_samples:
        logger.info(
            "exercise_muscle_resolver: %d library target_muscle tokens unmapped "
            "(sample: %s)", len(unmapped_samples), sorted(unmapped_samples)[:15]
        )
    logger.info("exercise_muscle_resolver: indexed %d exercise name keys", len(index))
    return index


def _norm_name(name: Optional[str]) -> str:
    """Normalize an exercise name for index lookup (mirror calculator's normalize)."""
    if not name or not isinstance(name, str):
        return ""
    n = name.lower().strip()
    n = n.replace(" ", "_").replace("-", "_")
    n = n.replace("dumbbell_", "").replace("barbell_", "")
    return n


def lookup_library_muscles(
    exercise_name: str, library_index: Optional[Dict[str, Dict[str, Any]]]
) -> List[str]:
    """Library-index muscle lookup for one exercise name (exact then loose match)."""
    if not library_index:
        return []
    norm = _norm_name(exercise_name)
    if not norm:
        return []
    entry = library_index.get(norm)
    if entry:
        return list(entry["muscles"])
    # Loose containment match (handles "incline barbell bench press" vs library name).
    for key, e in library_index.items():
        if key and (key in norm or norm in key):
            return list(e["muscles"])
    return []


def lookup_library_equipment(
    exercise_name: str, library_index: Optional[Dict[str, Dict[str, Any]]]
) -> Optional[str]:
    """Library-index equipment lookup for one exercise name (exact then loose)."""
    if not library_index:
        return None
    norm = _norm_name(exercise_name)
    if not norm:
        return None
    entry = library_index.get(norm)
    if entry:
        return entry.get("equipment")
    for key, e in library_index.items():
        if key and (key in norm or norm in key):
            return e.get("equipment")
    return None


# Equipment tokens that mean "machine/cable assisted" → flagged so a machine PR is
# never used to make a cross-population percentile claim (brands vary too much).
_MACHINE_EQUIPMENT_TOKENS = (
    "machine", "smith", "cable", "lever", "sled", "hammer", "pin", "selectorized",
)


def is_machine_equipment(equipment: Optional[str]) -> bool:
    """True when the equipment token indicates a machine/cable movement."""
    if not equipment or not isinstance(equipment, str):
        return False
    e = equipment.lower()
    return any(tok in e for tok in _MACHINE_EQUIPMENT_TOKENS)
