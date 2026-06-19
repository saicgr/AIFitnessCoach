"""Deterministic 8-pattern strength-movement classifier + bodyweight-ratio ladders.

FEATURE 4 (composite strength score). When an exercise the user logged is NOT in the
hand-curated ``STRENGTH_STANDARDS`` table (most of the library is AI-named or a long-tail
variant), the relative-strength sub-score (S1) needs SOME ladder to interpolate against.
The pre-existing behaviour was to fall back to the *squat* ladder, which is a 0.75x..2.5x
bodyweight scale — wildly too high for, say, a lateral raise, so every unmapped isolation
move scored ~0. This module replaces that bad fallback with a movement-pattern-aware ladder.

Classification is purely keyword-based (same style as ``equipment_scope.py`` — never an LLM,
per the never-LLM-classify-exercise-safety/level rule). Eight patterns, each with a
beginner..elite bodyweight-ratio ladder sourced from ExRx.net strength standards and
StrengthLevel.com population norms (male baseline; the scorer applies the female 0.65
multiplier exactly as ``classify_strength_level`` already does).

Lookup order the scorer MUST use (see ``strength_calculator_service._resolve_standards``):
    1. exact ``STRENGTH_STANDARDS`` entry  (most accurate, hand-curated)
    2. ``standards_for()`` here            (movement-pattern ladder)
    3. ``isolation_upper`` ladder          (conservative default — NEVER squat)

Mirrors the spirit of ``equipment_scope.py``: a blank/unknown name resolves to the
conservative ``isolation_upper`` ladder, never an over-scaled compound ladder.
"""

from __future__ import annotations

from typing import Dict, Optional

# ---------------------------------------------------------------------------
# Pattern bodyweight-ratio ladders (male baseline; gender multiplier applied
# downstream by classify_strength_level, identical to STRENGTH_STANDARDS rows).
#
# Sources (cited per the evidence-based-standards rule):
#   * Compound presses/pulls/squats/hinges: ExRx.net "Strength Standards" tables
#     (e.g. bench ~0.5x untrained → 2.0x elite; squat 0.75x → 2.5x; DL 1.0x → 3.0x).
#   * Overhead/vertical push: ExRx overhead-press norms (0.35x → 1.25x).
#   * Vertical pull (weighted pull-up / pulldown bodyweight-relative): StrengthLevel
#     pull-up + lat-pulldown norms collapsed to a single added-load + base ladder.
#   * Isolation upper/lower: StrengthLevel curl / lateral-raise / leg-extension /
#     leg-curl population percentiles (untrained..advanced).
# These intentionally mirror the magnitudes already present in STRENGTH_STANDARDS so a
# pattern fallback never produces a discontinuity vs an exact-mapped sibling exercise.
# ---------------------------------------------------------------------------

STRENGTH_PATTERN_STANDARDS: Dict[str, Dict[str, float]] = {
    # Horizontal push — bench press family (ExRx bench standards).
    "horizontal_push": {
        "beginner": 0.50,
        "novice": 0.85,
        "intermediate": 1.15,
        "advanced": 1.50,
        "elite": 2.00,
    },
    # Vertical push — overhead/shoulder press family (ExRx OHP standards).
    "vertical_push": {
        "beginner": 0.35,
        "novice": 0.55,
        "intermediate": 0.75,
        "advanced": 1.00,
        "elite": 1.25,
    },
    # Horizontal pull — barbell/dumbbell/cable row family (ExRx bent-row).
    "horizontal_pull": {
        "beginner": 0.50,
        "novice": 0.75,
        "intermediate": 1.00,
        "advanced": 1.25,
        "elite": 1.50,
    },
    # Vertical pull — pulldown / weighted pull-up family. Ratio expressed against
    # total moved load (added + bodyweight for unloaded pull-ups handled by the
    # bodyweight model in the scorer); StrengthLevel pulldown norms.
    "vertical_pull": {
        "beginner": 0.50,
        "novice": 0.80,
        "intermediate": 1.10,
        "advanced": 1.40,
        "elite": 1.75,
    },
    # Squat — back/front squat family (ExRx squat standards).
    "squat": {
        "beginner": 0.75,
        "novice": 1.25,
        "intermediate": 1.50,
        "advanced": 2.00,
        "elite": 2.50,
    },
    # Hinge — deadlift / RDL / good-morning family (ExRx deadlift, scaled down a
    # touch since RDL/GM ride lower than a competition pull).
    "hinge": {
        "beginner": 0.90,
        "novice": 1.40,
        "intermediate": 1.80,
        "advanced": 2.30,
        "elite": 2.80,
    },
    # Isolation upper — curls, lateral raises, tricep work, rear delts, etc.
    # (StrengthLevel curl / lateral-raise population norms, conservative).
    "isolation_upper": {
        "beginner": 0.10,
        "novice": 0.20,
        "intermediate": 0.35,
        "advanced": 0.50,
        "elite": 0.70,
    },
    # Isolation lower — leg extension / leg curl / calf raise / hip thrust accessory
    # (StrengthLevel leg-extension + leg-curl norms; the higher leg machines pull
    # the upper end up).
    "isolation_lower": {
        "beginner": 0.35,
        "novice": 0.60,
        "intermediate": 0.85,
        "advanced": 1.15,
        "elite": 1.45,
    },
}

# Conservative default per the spec: NEVER squat. An unmapped, unclassifiable move
# defaults to the isolation_upper ladder so a tiny accessory can't tank the score.
DEFAULT_PATTERN = "isolation_upper"


# Keyword tables. Order matters: more specific patterns are checked before generic
# ones (e.g. "overhead press" → vertical_push before a bare "press" could leak into
# horizontal_push). Each tuple is checked against a normalized "name + equipment"
# haystack. Mirrors the most-specific-first ordering used in equipment_scope.py /
# exercise_rag.filters.MOVEMENT_PATTERNS.
_PATTERN_KEYWORDS: tuple[tuple[str, tuple[str, ...]], ...] = (
    # Vertical pull first — "pull up"/"pulldown"/"chin" must not be eaten by row.
    ("vertical_pull", (
        "pull up", "pull-up", "pullup", "chin up", "chin-up", "chinup",
        "pulldown", "pull-down", "pull down", "lat pulldown", "muscle up",
        "muscle-up",
    )),
    # Horizontal pull — rows.
    ("horizontal_pull", (
        "row", "bent over", "bent-over", "pendlay", "t-bar", "seal row",
        "face pull", "rear delt fly", "rear-delt", "inverted row",
    )),
    # Vertical push — overhead/shoulder presses + raises that load the delts
    # vertically (lateral/front raises go to isolation_upper below, so keep them
    # OUT of here).
    ("vertical_push", (
        "overhead press", "shoulder press", "military press", "arnold press",
        "push press", "ohp", "z press", "landmine press",
    )),
    # Horizontal push — bench/chest presses, dips, push-ups, flyes.
    ("horizontal_push", (
        "bench press", "chest press", "incline press", "decline press",
        "push up", "push-up", "pushup", "dip", "floor press", "fly", "flye",
        "pec deck", "chest fly",
    )),
    # Squat family.
    ("squat", (
        "squat", "leg press", "hack squat", "split squat", "lunge", "step up",
        "step-up", "wall sit", "pistol", "sissy squat",
    )),
    # Hinge family.
    ("hinge", (
        "deadlift", "rdl", "romanian", "good morning", "hip hinge",
        "stiff leg", "stiff-leg", "back extension", "hyperextension",
        "kettlebell swing", "kb swing",
    )),
    # Isolation lower — single-joint leg machines + glute accessories + calves.
    ("isolation_lower", (
        "leg extension", "leg curl", "calf raise", "hip thrust", "glute bridge",
        "glute kickback", "hip abduction", "hip adduction", "adductor",
        "abductor", "donkey kick",
    )),
    # Isolation upper — single-joint arm/shoulder/forearm work. Checked LAST so a
    # compound that merely mentions "curl" (none do) can't be miscategorized; raises
    # land here on purpose (single-joint deltoid isolation).
    ("isolation_upper", (
        "curl", "tricep", "triceps", "skull crusher", "skullcrusher",
        "kickback", "lateral raise", "front raise", "side raise", "shrug",
        "wrist", "reverse fly", "cable crossover", "pushdown", "extension",
    )),
)


def get_strength_pattern(name: Optional[str], equipment: Optional[str] = None) -> str:
    """Classify an exercise into one of the eight strength movement patterns.

    Returns ``DEFAULT_PATTERN`` (isolation_upper) when nothing matches — NEVER squat.
    """
    haystack = f"{(name or '').strip().lower()} {(equipment or '').strip().lower()}"
    if not haystack.strip():
        return DEFAULT_PATTERN
    for pattern, keywords in _PATTERN_KEYWORDS:
        for kw in keywords:
            if kw in haystack:
                return pattern
    return DEFAULT_PATTERN


def matched_known_pattern(name: Optional[str], equipment: Optional[str] = None) -> bool:
    """True when the name/equipment matched a real movement-pattern keyword.

    Used by the population-percentile layer to decide whether the exercise has a
    REAL standard to compare against (exact pattern hit) vs only the conservative
    isolation_upper safety-net fallback (in which case we omit the percentile rather
    than fabricate one for a genuinely unknown movement).
    """
    haystack = f"{(name or '').strip().lower()} {(equipment or '').strip().lower()}"
    if not haystack.strip():
        return False
    for _pattern, keywords in _PATTERN_KEYWORDS:
        for kw in keywords:
            if kw in haystack:
                return True
    return False


def standards_for(name: Optional[str], equipment: Optional[str] = None) -> Dict[str, float]:
    """Return the beginner..elite bodyweight-ratio ladder for an exercise's pattern.

    Used as the SECOND lookup tier by the strength scorer (after an exact
    STRENGTH_STANDARDS hit, before the isolation_upper safety net).
    """
    pattern = get_strength_pattern(name, equipment)
    return STRENGTH_PATTERN_STANDARDS.get(pattern, STRENGTH_PATTERN_STANDARDS[DEFAULT_PATTERN])
