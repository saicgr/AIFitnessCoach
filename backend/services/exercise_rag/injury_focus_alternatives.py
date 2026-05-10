"""
Curated injury-aware focus alternatives — Phase A (Plan §A2).

When the fail-closed safety filter (`fetch_safe_candidates`) AND the standard
RAG retrieval both return < N candidates for an `(injury, focus)` combination,
this module supplies the next tier in the cascade: hand-curated lists of
exercise patterns / name fragments that are clinically appropriate for the
named injury under the named focus.

This is **NOT LLM-derived** (per `feedback_no_llm_for_safety_classification.md`).
Each entry is sourced from authoritative physical-therapy and S&C literature:

  - NSCA Essentials of Strength Training & Conditioning, 4th ed. (2016)
  - NASM Essentials of Personal Fitness Training, 7th ed. (2022)
  - ACSM's Guidelines for Exercise Testing and Prescription, 11th ed. (2021)
  - Cook, G. — Movement: Functional Movement Systems (2010)
  - Cressey, E. — published programming for shoulder/back/hip rehab
  - APTA Clinical Practice Guidelines: Knee, Lumbar, Shoulder

Citations are inline at each map entry. When adding a new injury×focus row,
include the source so a future PT reviewer can audit the choice.

The map values are **lists of substrings** matched case-insensitively
against `exercise_library_cleaned.name` AND `movement_pattern`. The cascade
runs the substring match in Postgres ILIKE, then re-applies the active
equipment filter and the fail-closed injury filter for the *remaining*
injuries (i.e. the curated map removes the named injury from the AND clause
because the alternatives are pre-vetted for that joint).
"""
from __future__ import annotations

from typing import Dict, List, Tuple

# 8 supported joints from `services.workout_safety_validator.SUPPORTED_INJURY_JOINTS`.
# Focus aliases handled in `_normalize_focus()`: upper_body→upper, legs→lower,
# leg→lower, hinge→pull (for back work), abs→core, etc.

INJURY_FOCUS_ALTERNATIVES: Dict[Tuple[str, str], List[str]] = {
    # ------------------------------------------------------------------
    # Shoulder
    # ------------------------------------------------------------------
    # Source: APTA Shoulder Pain CPG (2013); Cressey "Optimal Shoulder
    # Performance" — avoid overhead and behind-the-neck loading; prefer
    # neutral-grip and supported variations that limit subacromial impingement.
    # Library-verified substrings (2026-05-09): each substring matches ≥1
    # row in `exercise_library_cleaned`; substrings that returned 0 rows
    # ("landmine press" → just "landmine"; "fist push-up" / "knuckle push-up"
    # — no library coverage; "push-up neutral" — no library coverage) have
    # been replaced or removed.
    ("shoulder", "push"): [
        "floor press",
        "machine chest press",
        "landmine",
        "neutral grip",
        "incline machine",
        "pec deck",
        "svend press",
    ],
    ("shoulder", "pull"): [
        "seated cable row",
        "chest supported",  # matches "Dumbbell Chest Supported Lateral Raises" / Y Raise
        "machine row",
        "face pull",
        "inverted row",
        "suspension trainer",  # neutral-grip suspension rows
    ],
    ("shoulder", "upper"): [
        "floor press", "machine chest press", "machine row", "face pull",
        "neutral grip", "neutral-grip", "chest-supported row",
    ],
    ("shoulder", "core"): [
        "dead bug", "bird dog", "side plank", "pallof press",
        "hollow hold", "anti-rotation", "anti rotation",
    ],
    # ------------------------------------------------------------------
    # Lower back
    # ------------------------------------------------------------------
    # Source: APTA Low Back Pain CPG (2012); McGill — Low Back Disorders.
    # Avoid loaded spinal flexion under load (deadlifts, good mornings,
    # bent-over rows); prefer chest-supported pulling, hip-dominant work
    # with a supported torso, and anti-extension/anti-rotation core.
    ("lower_back", "pull"): [
        "chest supported",
        "lat pulldown",
        "y raise",
        "machine row",
        "incline row",
        "suspension trainer",
    ],
    ("lower_back", "legs"): [
        "leg press",
        "box squat",
        "seated leg curl", "lying leg curl",
        "hip thrust",
        "step-up", "step up",
        "split squat", "bulgarian split",  # supported variations
        "calf raise",
    ],
    ("lower_back", "lower"): [
        "leg press", "seated leg curl", "lying leg curl", "hip thrust",
        "step up", "step-up", "calf raise", "goblet squat to box",
    ],
    ("lower_back", "core"): [
        "dead bug", "bird dog", "side plank", "pallof press",
        "anti-rotation", "anti rotation", "anti-extension",
    ],
    ("lower_back", "upper"): [
        "chest-supported row", "machine chest press", "machine row",
        "lat pulldown", "face pull",
    ],
    # ------------------------------------------------------------------
    # Knee
    # ------------------------------------------------------------------
    # Source: APTA Knee Pain (Patellofemoral) CPG (2019); Cook FMS
    # — avoid deep flexion under load + plyometrics; prefer hip-dominant
    # posterior-chain work, isometrics, and machine-supported quadriceps work.
    ("knee", "legs"): [
        "hip thrust",
        "glute bridge",
        "seated leg curl", "lying leg curl",
        "romanian deadlift", "rdl",  # light only — equipment filter still applies
        "calf raise",
        "clamshell",
        "lateral band walk",  # library uses "Lateral Band Walks", not "monster walk"
        "swimming",
    ],
    ("knee", "lower"): [
        "hip thrust", "glute bridge", "seated leg curl", "lying leg curl",
        "calf raise", "clamshell", "monster walk", "rdl",
    ],
    ("knee", "core"): [
        "dead bug", "bird dog", "side plank", "pallof press",
        "anti-rotation", "anti rotation", "hollow hold",
    ],
    ("knee", "upper"): [
        # Knee-friendly upper-body — anything seated.
        "seated press", "seated row", "machine chest press", "lat pulldown",
        "face pull", "machine row",
    ],
    # ------------------------------------------------------------------
    # Hip
    # ------------------------------------------------------------------
    # Source: APTA Hip Pain CPG (FAI / OA) — avoid wide-stance and deep
    # flexion; prefer narrow-stance and supported variations.
    ("hip", "legs"): [
        "seated leg extension",
        "lying leg curl", "seated leg curl",
        "calf raise",
        "glute bridge",
        "clamshell",
        "leg press",  # narrow stance noted in instructions
    ],
    ("hip", "lower"): [
        "seated leg extension", "lying leg curl", "calf raise",
        "glute bridge", "leg press",
    ],
    ("hip", "core"): [
        "dead bug", "bird dog", "side plank", "pallof press",
        "hollow hold",
    ],
    ("hip", "upper"): [
        "seated press", "seated row", "machine chest press", "lat pulldown",
        "face pull",
    ],
    # ------------------------------------------------------------------
    # Ankle
    # ------------------------------------------------------------------
    # Source: APTA Ankle Sprain CPG (2021) — avoid plyometrics, single-leg
    # balance demands, and deep dorsiflexion under load.
    ("ankle", "legs"): [
        "seated leg extension",
        "leg press",  # heel below toe variation noted in instructions
        "lying leg curl", "seated leg curl",
        "calf raise seated", "seated calf raise",
        "glute bridge",
    ],
    ("ankle", "lower"): [
        "seated leg extension", "leg press", "lying leg curl",
        "seated calf raise", "glute bridge",
    ],
    ("ankle", "core"): [
        "dead bug", "bird dog", "side plank", "pallof press",
        "hollow hold",
    ],
    ("ankle", "upper"): [
        "seated press", "seated row", "machine chest press", "lat pulldown",
    ],
    # ------------------------------------------------------------------
    # Wrist
    # ------------------------------------------------------------------
    # Source: NSCA — wrist pathology requires neutral-wrist loading;
    # avoid extended-wrist push-up positions and barbell front-rack.
    ("wrist", "push"): [
        "machine chest press",
        "pec deck",
        "cable fly",
        "neutral grip",
        "landmine",  # neutral-wrist landmine pressing
        "svend press",  # plate squeeze, neutral wrist
    ],
    ("wrist", "pull"): [
        "machine row",
        "lat pulldown",
        "suspension trainer",  # figure-8 grips = neutral wrist
        "cable row",
    ],
    ("wrist", "upper"): [
        "machine chest press", "machine row", "lat pulldown",
        "neutral grip", "neutral-grip", "pec deck",
    ],
    # ------------------------------------------------------------------
    # Elbow
    # ------------------------------------------------------------------
    # Source: NSCA + Cressey on golfer's/tennis elbow — avoid heavy
    # close-grip pressing and skullcrushers; neutral-grip is friendlier.
    ("elbow", "push"): [
        "machine chest press",
        "neutral grip",
        "pec deck",
        "landmine",
        "svend press",
    ],
    ("elbow", "pull"): [
        "machine row",
        "face pull",
        "band pull apart", "pull apart",  # library: "Resistance Band Pull Apart"
        "lat pulldown",
    ],
    ("elbow", "upper"): [
        "machine chest press", "machine row", "face pull",
        "neutral grip", "neutral-grip", "pec deck",
    ],
    # ------------------------------------------------------------------
    # Neck
    # ------------------------------------------------------------------
    # Source: APTA Neck Pain CPG — avoid loaded carries, shrugs, and
    # front-rack work; prefer chin-tucks and unloaded mobility.
    ("neck", "upper"): [
        "machine chest press", "machine row", "lat pulldown",
        "chin tuck", "neck mobility",
    ],
    ("neck", "core"): [
        "dead bug", "bird dog", "side plank", "pallof press",
        "hollow hold",
    ],
}


# Universal fallbacks per focus when no curated entry exists for the
# specific (injury, focus) pair. These are always-safe defaults.
UNIVERSAL_SAFE_BY_FOCUS: Dict[str, List[str]] = {
    "core": [
        "dead bug", "bird dog", "side plank", "pallof press",
        "hollow hold", "anti-rotation", "anti rotation",
    ],
    "mobility": [
        "cat-cow", "cat cow", "thread the needle", "world's greatest",
        "hip flexor stretch", "thoracic rotation", "ankle circle",
        "neck mobility", "shoulder cars",
    ],
    "recovery": [
        "foam roll", "static stretch", "child's pose", "pigeon pose",
        "supine twist", "diaphragmatic breathing",
    ],
}


# Focus normalization — collapse aliases to canonical keys used in the map.
_FOCUS_ALIASES: Dict[str, str] = {
    "upper_body": "upper",
    "lower_body": "lower",
    "leg": "lower",
    "legs": "legs",  # keep both — map has both legs and lower entries
    "hinge": "pull",
    "abs": "core",
    "abdominals": "core",
    "back": "pull",
    "chest": "push",
    "shoulders": "push",
    "full_body": "full_body",
    "fullbody": "full_body",
}


def normalize_focus(focus: str) -> str:
    """Canonicalize a focus string for map lookup."""
    if not focus:
        return "full_body"
    key = focus.strip().lower().replace(" ", "_")
    return _FOCUS_ALIASES.get(key, key)


def get_curated_alternatives(
    injuries: List[str],
    focus: str,
) -> List[str]:
    """
    Return a deduplicated list of exercise-name/movement-pattern substrings
    that are clinically appropriate for the given injury set + focus.

    Strategy:
      1. For each (injury, focus) pair in the map, accumulate substrings.
      2. If `focus == "full_body"`, expand to push + pull + lower + core
         alternatives for each injury so we get a true full-body set.
      3. If no curated entry matches but `focus in UNIVERSAL_SAFE_BY_FOCUS`,
         use the universal fallback.
      4. Return unique, lowercased substrings preserving insertion order.
    """
    if not injuries:
        return []
    fa = normalize_focus(focus)
    seen: Dict[str, None] = {}

    def _add(items: List[str]) -> None:
        for it in items:
            k = it.strip().lower()
            if k and k not in seen:
                seen[k] = None

    # Direct map lookup per injury for the requested focus
    expand_focuses = [fa]
    if fa in {"full_body", "fullbody"}:
        expand_focuses = ["push", "pull", "lower", "legs", "core"]
    elif fa == "upper":
        expand_focuses = ["push", "pull", "upper"]

    for inj in injuries:
        inj_l = (inj or "").strip().lower()
        if not inj_l:
            continue
        for sub_focus in expand_focuses:
            entries = INJURY_FOCUS_ALTERNATIVES.get((inj_l, sub_focus), [])
            _add(entries)

    # Universal fallback for core/mobility/recovery if nothing matched
    if not seen and fa in UNIVERSAL_SAFE_BY_FOCUS:
        _add(UNIVERSAL_SAFE_BY_FOCUS[fa])

    return list(seen.keys())


def has_curated_coverage(injuries: List[str], focus: str) -> bool:
    """Cheap predicate: does the map contain any entry for this combo?"""
    return bool(get_curated_alternatives(injuries, focus))
