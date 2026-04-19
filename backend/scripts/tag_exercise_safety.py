"""
Phase 2G — Deterministic Exercise Safety Tagger
===============================================

Populates `public.exercise_safety_tags` (the base table behind the
`exercise_safety_index` view) from the research-backed taxonomy in
`backend/data/exercise_safety_reference.yaml`.

HARD CONSTRAINTS (per user directive):
- NO LLM CALLS. No Gemini, no OpenAI, no anthropic. Pure regex + dict lookup.
- Every row's source_citation is traceable to a line in the yaml.
- Fail-closed default: no pattern + no elite match -> all 8 injury flags FALSE,
  safety_difficulty='unknown', source_citation='UNCLASSIFIED - needs manual audit',
  tagged_by='rule' (this fallback is still a rule).
- Idempotent: uses INSERT ... ON CONFLICT (exercise_id) DO UPDATE.

Embeddings are NOT generated here — the column is left NULL. A later step can
backfill from the RAG pipeline's embedding source. (Audit confirmed there is
no existing `exercise_embeddings` table in this Supabase project.)

Modes
-----
    # Print classified rows to stdout as JSON (no DB writes):
    python -m backend.scripts.tag_exercise_safety --dry-run

    # Same but restrict to a sample of N exercises:
    python -m backend.scripts.tag_exercise_safety --dry-run --sample 50

    # Emit batched UPSERT SQL to stdout or --out <file> (for MCP execution):
    python -m backend.scripts.tag_exercise_safety --mode full --emit-sql --out /tmp/tags.sql

    # Write directly via supabase-py (requires SUPABASE_URL/SUPABASE_SERVICE_KEY):
    python -m backend.scripts.tag_exercise_safety --mode full
    python -m backend.scripts.tag_exercise_safety --mode incremental
    python -m backend.scripts.tag_exercise_safety --mode single --exercise-id <uuid>

Usage inside the MCP-driven workflow (how Phase 2G was executed):
-----------------------------------------------------------------
1.  Run `--dry-run --sample 50` for a spot check.
2.  Run `--mode full --emit-sql --out /tmp/tags.sql` to produce batched SQL.
3.  Execute the batches via Supabase MCP `execute_sql` 500 rows at a time.
4.  Run `audit_exercise_safety_coverage.py`.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import uuid
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

import yaml

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parents[2]
BACKEND_ROOT = REPO_ROOT / "backend"
YAML_PATH = BACKEND_ROOT / "data" / "exercise_safety_reference.yaml"

INJURIES: Tuple[str, ...] = (
    "shoulder",
    "lower_back",
    "knee",
    "elbow",
    "wrist",
    "ankle",
    "hip",
    "neck",
)

INJURY_FLAG_COLS: Tuple[str, ...] = tuple(f"{i}_safe" for i in INJURIES)

# Movement patterns considered "elite" when the skill shares the pattern.
HANGING_PATTERNS = {"hanging", "hanging_inversion"}
OVERHEAD_PATTERNS = {"overhead_press", "overhead_pull", "behind_neck_press", "handstand_load", "inversion"}
PLYO_PATTERNS = {"plyometric", "plyometric_upper_body", "high_impact_axial_load"}
ROTATION_PATTERNS = {"loaded_rotation"}
INVERSION_PATTERNS = {"hanging_inversion", "inversion", "handstand_load"}

# Phase 1A check constraint on `exercise_safety_tags.movement_pattern` restricts
# the column to this 17-value enum. The yaml's extended taxonomy (~30 patterns)
# must be DOWN-PROJECTED to the schema-permitted set when written to the DB.
# The full yaml pattern is still used internally for joint-loading lookups —
# this mapping only affects what we persist.
ALLOWED_MOVEMENT_PATTERNS = {
    "push", "pull", "hinge", "squat", "loaded_rotation", "anti_rotation",
    "carry", "isometric", "mobility", "plyometric", "overhead_press",
    "overhead_pull", "horizontal_push", "horizontal_pull", "vertical_pull",
    "hanging", "inversion",
}

PATTERN_DOWNMAP: Dict[str, str] = {
    # direct passthrough — these are already allowed
    "overhead_press": "overhead_press",
    "overhead_pull": "overhead_pull",
    "horizontal_push": "horizontal_push",
    "horizontal_pull": "horizontal_pull",
    "vertical_pull": "vertical_pull",
    "hinge": "hinge",
    "squat": "squat",
    "loaded_rotation": "loaded_rotation",
    "anti_rotation": "anti_rotation",
    "carry": "carry",
    "isometric": "isometric",
    "mobility": "mobility",
    "plyometric": "plyometric",
    "hanging": "hanging",
    "inversion": "inversion",
    # extended yaml patterns -> collapse onto nearest allowed
    "behind_neck_press": "overhead_press",
    "handstand_load": "inversion",
    "hanging_inversion": "inversion",
    "deep_squat_loaded": "squat",
    "pistol_squat": "squat",
    "lunge": "squat",
    "dips": "horizontal_push",       # triceps dip is functionally horizontal-ish push at the shoulder
    "upright_row": "overhead_press", # elbow-flaring vertical pull to chin — NSCA treats as overhead
    "shrug_heavy": "overhead_press", # loads upper trap + cervical spine similarly
    "horizontal_abduction_loaded": "horizontal_push",
    "loaded_wrist_extension": "horizontal_push",
    "loaded_wrist_flexion": "horizontal_push",
    "loaded_spinal_flexion": "hinge",
    "bench_press_heavy": "horizontal_push",
    "high_velocity_throw": "plyometric",
    "gripping_heavy": "carry",
    "open_chain_knee_extension_heavy": "squat",
    "horizontal_push_bodyweight_plus": "horizontal_push",
    "high_impact_axial_load": "plyometric",
    "plyometric_upper_body": "plyometric",
    "overhead_carry": "carry",   # loaded locomotion, but safety flags derive from yaml_pattern
    "horizontal_pull_hinged": "horizontal_pull",  # bent-over rowing, flags from yaml_pattern
    "olympic_lift": "hinge",      # ground-to-overhead lifts, flags from yaml_pattern
    "overhead_compound": "overhead_press",  # squat/lunge with overhead hold, flags from yaml_pattern
}

# Difficulty ordering; higher tier wins when combined.
DIFF_ORDER = {"unknown": 0, "beginner": 1, "intermediate": 2, "advanced": 3, "elite": 4}
DIFF_FROM_LIBRARY = {
    "beginner": "beginner",
    "intermediate": "intermediate",
    "advanced": "advanced",
    "expert": "advanced",
    # fallthrough handled in code
}

# ---------------------------------------------------------------------------
# Data containers
# ---------------------------------------------------------------------------

@dataclass
class SafetyTagRow:
    exercise_id: str
    shoulder_safe: Optional[bool]
    lower_back_safe: Optional[bool]
    knee_safe: Optional[bool]
    elbow_safe: Optional[bool]
    wrist_safe: Optional[bool]
    ankle_safe: Optional[bool]
    hip_safe: Optional[bool]
    neck_safe: Optional[bool]
    movement_pattern: Optional[str]
    plane_of_motion: Optional[str]
    load_axis: Optional[str]
    is_overhead: bool
    is_loaded_rotation: bool
    is_high_impact: bool
    is_inversion: bool
    is_hanging: bool
    grip_intensity: Optional[str]
    safety_difficulty: str
    is_beginner_safe: bool
    source_citation: str
    tagged_by: str
    notes: Optional[str] = None

    # Stash the name on the dataclass for logging/debug only; not persisted.
    _exercise_name: str = field(default="", repr=False)


# ---------------------------------------------------------------------------
# Reference loading
# ---------------------------------------------------------------------------

def load_reference(path: Path = YAML_PATH) -> Dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"Safety reference yaml not found at {path}")
    with path.open("r", encoding="utf-8") as f:
        ref = yaml.safe_load(f)
    # Sanity — exercise_safety_reference.yaml must have these top-level keys.
    for required in ("injuries", "movement_patterns", "elite_calisthenics_skills", "pattern_detection_rules"):
        if required not in ref:
            raise ValueError(f"YAML missing top-level key: {required}")
    return ref


def _compile_pattern_rules(rules: Dict[str, Dict[str, str]]) -> List[Tuple[str, re.Pattern, Optional[re.Pattern]]]:
    """
    Compile detection rules in a defined order. Order matters: the first rule
    whose include_regex matches (and whose exclude_regex does NOT match) wins.

    NSCA/McGill-derived priority: behind_neck before overhead_press before
    vertical_pull before horizontal_pull, deep_squat before squat, pistol
    before squat, hanging before overhead_pull, etc. Specific-before-general.
    """
    priority_order = [
        # ---- COMPOUND / OLYMPIC LIFTS FIRST ----
        # Olympic lifts (clean/snatch/jerk/thruster) MUST match before any
        # sub-pattern (squat/hinge/overhead_press) would otherwise eat them.
        "olympic_lift",
        # Overhead-position compound moves (OH squat, OH lunge, lunge->OHP,
        # OH sit-up, OH shrug) must tag the overhead shoulder/neck risk before
        # their base-pattern (squat/lunge/hinge) classifies them as leg/core.
        "overhead_compound",

        # ---- ROTATION ----
        # Compound rotation moves (e.g. "Push Up And Rotation") must match
        # loaded_rotation before any horizontal/vertical push/pull pattern.
        "loaded_rotation",
        "anti_rotation",

        # ---- PLYOMETRICS BEFORE SQUAT/PUSH ----
        # "Jump Squat" / "Mountain Climber Jumps" must be plyometric, not
        # squat/horizontal_push.
        "plyometric_upper_body",
        "plyometric",
        "high_impact_axial_load",

        # ---- SPECIFIC VARIANTS BEFORE GENERIC ----
        # Elite calisthenics / inversion variants
        "hanging_inversion",
        "handstand_load",
        "inversion",
        "hanging",

        # Specific push variants (bodyweight+ loads wrist in extension; plyo
        # adds impact; behind-neck is geometry-dangerous). Must run before
        # generic "overhead_press"/"horizontal_push".
        "plyometric_upper_body",
        "horizontal_push_bodyweight_plus",
        "bench_press_heavy",
        "behind_neck_press",
        "dips",
        "upright_row",
        "shrug_heavy",
        "horizontal_abduction_loaded",

        # Hinged pull variant MUST run before generic horizontal_pull so
        # bent-over rows pick up lower_back/hip contraindications.
        "horizontal_pull_hinged",

        # Specific leg variants before generic squat
        "pistol_squat",
        "deep_squat_loaded",
        "lunge",

        # Specific loaded-spine / wrist variants before generic hinge
        "loaded_spinal_flexion",
        "loaded_wrist_extension",
        "loaded_wrist_flexion",

        # Other specific high-risk patterns
        "high_impact_axial_load",
        "high_velocity_throw",
        "open_chain_knee_extension_heavy",
        "gripping_heavy",
        "overhead_carry",

        # ---- GENERIC PATTERNS LAST ----
        "overhead_press",
        "overhead_pull",
        "vertical_pull",
        "horizontal_push",
        "horizontal_pull",
        "hinge",
        "squat",
        "plyometric",
        "carry",
        "isometric",
        "mobility",
    ]
    # de-dup preserving order
    seen: set = set()
    ordered = [p for p in priority_order if not (p in seen or seen.add(p))]

    compiled: List[Tuple[str, re.Pattern, Optional[re.Pattern]]] = []
    for pat in ordered:
        if pat not in rules:
            continue
        entry = rules[pat]
        inc = entry.get("include_regex") or ""
        exc = entry.get("exclude_regex") or ""
        if not inc:
            continue
        inc_re = re.compile(inc)
        exc_re = re.compile(exc) if exc else None
        compiled.append((pat, inc_re, exc_re))
    # Append any remaining rules not in the priority list, for completeness.
    for pat, entry in rules.items():
        if pat in seen:
            continue
        inc = entry.get("include_regex") or ""
        exc = entry.get("exclude_regex") or ""
        if not inc:
            continue
        inc_re = re.compile(inc)
        exc_re = re.compile(exc) if exc else None
        compiled.append((pat, inc_re, exc_re))
    return compiled


def _normalize_name(name: str) -> str:
    if not name:
        return ""
    s = name.strip().lower()
    # unify hyphens and excess whitespace
    s = re.sub(r"[\u2010-\u2015\-_/]+", " ", s)
    s = re.sub(r"\s+", " ", s)
    return s


def _build_elite_index(skills: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Build a matchable elite index. Each entry has:
      name, aliases (normalized), severity, source, token_sets (for loose match).
    """
    index: List[Dict[str, Any]] = []
    for skill in skills:
        name = skill.get("name")
        if not name:
            continue
        aliases = [name] + list(skill.get("aliases") or [])
        norm_aliases = sorted({_normalize_name(a) for a in aliases if a}, key=len, reverse=True)
        token_sets = [set(a.split()) for a in norm_aliases if a]
        index.append({
            "canonical": name,
            "aliases_norm": norm_aliases,
            "token_sets": token_sets,
            "severity": skill.get("severity", "elite"),
            "source": skill.get("source", "elite_calisthenics_skills list"),
        })
    return index


# ---------------------------------------------------------------------------
# Detection
# ---------------------------------------------------------------------------

def detect_movement_pattern(
    name: str,
    compiled_rules: Sequence[Tuple[str, re.Pattern, Optional[re.Pattern]]],
) -> Optional[Tuple[str, str]]:
    """
    Returns (pattern_name, matched_regex_text) or None.
    Iterates compiled rules in priority order; first matching non-excluded wins.
    """
    if not name:
        return None
    for pat, inc_re, exc_re in compiled_rules:
        if inc_re.search(name):
            if exc_re and exc_re.search(name):
                continue
            return pat, inc_re.pattern
    return None


def match_elite_skill(
    name: str,
    elite_index: List[Dict[str, Any]],
) -> Optional[Dict[str, Any]]:
    """
    Returns the matched elite skill entry or None.

    Strategy:
      1. Exact normalized-alias substring match (longest alias first).
      2. Token-set containment: every token of the alias appears as a
         whole word in the exercise name (catches "Front Lever Raise"
         vs alias "front lever raise", and "Weighted Dragon Flag" vs
         alias "dragon flag").
    """
    norm = _normalize_name(name)
    if not norm:
        return None
    tokens = set(norm.split())
    for entry in elite_index:
        # (1) direct substring
        for alias_norm in entry["aliases_norm"]:
            if not alias_norm:
                continue
            # anchor on word boundaries to avoid false positives
            # ("planche" should not match "plan check")
            pattern = r"\b" + re.escape(alias_norm) + r"\b"
            if re.search(pattern, norm):
                return entry
        # (2) token-set containment (all alias tokens present, regardless of order)
        for token_set in entry["token_sets"]:
            if token_set and token_set.issubset(tokens):
                return entry
    return None


def _primary_joints_for_pattern(pattern: Optional[str], movement_patterns: Dict[str, Any]) -> set:
    if not pattern:
        return set()
    entry = movement_patterns.get(pattern)
    if not entry:
        return set()
    return set(entry.get("primary_joints") or []) | set(entry.get("secondary_joints") or [])


def _injury_unsafe_by_pattern(
    injury: str,
    pattern: Optional[str],
    injuries_ref: Dict[str, Any],
) -> Optional[str]:
    """
    Returns citation string if the given movement pattern is forbidden for
    this injury per yaml.injuries[<injury>].forbidden_patterns, else None.
    """
    if not pattern:
        return None
    inj = injuries_ref.get(injury) or {}
    for forbidden in inj.get("forbidden_patterns", []) or []:
        if forbidden.get("pattern") == pattern:
            # include severity in citation for auditing
            sev = forbidden.get("severity", "unknown")
            src = forbidden.get("source", "")
            return f"[{injury} | pattern={pattern} | severity={sev}] {src}"
    return None


def _injury_unsafe_by_name(
    injury: str,
    norm_name: str,
    injuries_ref: Dict[str, Any],
) -> Optional[str]:
    """
    Word-bounded substring match of the normalized forbidden-exercise name
    against the normalized exercise name. Trailing "s"/"es" on the target
    name is tolerated (so "Seated Floor Crunches" matches "Crunch").
    """
    inj = injuries_ref.get(injury) or {}
    for forbidden in inj.get("forbidden_exercises_explicit", []) or []:
        ex_name = _normalize_name(forbidden.get("name", ""))
        if not ex_name:
            continue
        # Leading word boundary; trailing tolerates optional s/es for plurals.
        pattern = r"\b" + re.escape(ex_name) + r"(?:es|s)?\b"
        if re.search(pattern, norm_name):
            src = forbidden.get("source", "")
            return f"[{injury} | exact-name='{forbidden['name']}'] {src}"
    return None


# ---------------------------------------------------------------------------
# Per-exercise classification
# ---------------------------------------------------------------------------

def classify_exercise(
    exercise: Dict[str, Any],
    ref: Dict[str, Any],
    compiled_rules: Sequence[Tuple[str, re.Pattern, Optional[re.Pattern]]],
    elite_index: List[Dict[str, Any]],
) -> SafetyTagRow:
    """
    Deterministic classifier. Fails closed if no pattern and no elite match.
    """
    name = exercise.get("name") or ""
    ex_id = exercise.get("id")
    if not ex_id:
        raise ValueError(f"Exercise missing id: {exercise!r}")

    norm = _normalize_name(name)

    # --- Movement pattern via regex detection rules --------------------------
    # `pattern_internal` = full yaml taxonomy name (used for joint lookups).
    # `movement_pattern` = downmapped to the DB's 17-value enum (persisted).
    pattern_match = detect_movement_pattern(name, compiled_rules)
    pattern_internal = pattern_match[0] if pattern_match else None
    movement_pattern = PATTERN_DOWNMAP.get(pattern_internal) if pattern_internal else None
    if movement_pattern and movement_pattern not in ALLOWED_MOVEMENT_PATTERNS:
        # Defensive — should never trigger since PATTERN_DOWNMAP is hand-audited,
        # but if a new yaml pattern shows up, fail closed (drop to NULL) so we
        # never violate the schema constraint.
        movement_pattern = None

    # --- Elite skill match --------------------------------------------------
    elite = match_elite_skill(name, elite_index)

    # --- Base difficulty from library --------------------------------------
    lib_diff_raw = (exercise.get("difficulty_level") or "").strip().lower()
    lib_diff = DIFF_FROM_LIBRARY.get(lib_diff_raw, "unknown" if not lib_diff_raw else lib_diff_raw)
    if lib_diff not in DIFF_ORDER:
        lib_diff = "unknown"

    # Elite match forces elite difficulty (per yaml severity).
    if elite:
        elite_sev = elite["severity"]  # elite | advanced
        if elite_sev not in DIFF_ORDER:
            elite_sev = "elite"
        if DIFF_ORDER[elite_sev] > DIFF_ORDER[lib_diff]:
            safety_difficulty = elite_sev
        else:
            safety_difficulty = lib_diff
    else:
        safety_difficulty = lib_diff

    # --- Per-injury flags ---------------------------------------------------
    flags: Dict[str, bool] = {col: True for col in INJURY_FLAG_COLS}
    citations: List[str] = []

    # Pattern-driven violations.  Use the FULL yaml pattern (not the downmapped
    # persisted one) so the per-injury forbidden-pattern lookup is precise.
    for inj in INJURIES:
        col = f"{inj}_safe"
        pat_cit = _injury_unsafe_by_pattern(inj, pattern_internal, ref["injuries"])
        if pat_cit:
            flags[col] = False
            citations.append(pat_cit)

    # Explicit forbidden-exercise-name violations (override pattern).
    for inj in INJURIES:
        col = f"{inj}_safe"
        name_cit = _injury_unsafe_by_name(inj, norm, ref["injuries"])
        if name_cit:
            flags[col] = False
            citations.append(name_cit)

    # Elite skills: cascade forbid shoulder/elbow/wrist/lower_back/neck by default.
    # (FIG CoP + JOSPT RC/elbow/neck CPGs consistently contraindicate elite
    # gymnastic-level loads for the injured populations we model.)
    if elite:
        elite_forbid = {
            "shoulder_safe": True,
            "elbow_safe": True,
            "wrist_safe": True,
            "lower_back_safe": True,
            "neck_safe": True,
        }
        # Dragon flag / v-sit / manna / toes-to-bar style implicate lower_back severely;
        # human flag implicates lower_back + hip + knee + ankle (full-body ballistic hold).
        canon = elite["canonical"]
        if canon in ("human flag",):
            elite_forbid.update({"hip_safe": True, "knee_safe": True, "ankle_safe": True})
        if canon in ("one arm handstand", "handstand push-up", "planche", "planche push-up",
                     "iron cross", "maltese", "victorian", "press to handstand",
                     "l-sit to handstand"):
            # all joints above the hip definitely unsafe; plus anti-gravity balance
            elite_forbid.update({"hip_safe": True})
        for col in elite_forbid:
            if flags[col]:
                flags[col] = False
                citations.append(f"[elite-cascade | skill='{canon}'] {elite['source']}")

    # --- avoid_if integration ------------------------------------------------
    # The library's avoid_if column (List[str]) is authoritative when it says
    # an exercise stresses a specific joint. Treat it as a hard override to
    # FALSE regardless of pattern classification.
    avoid_if_raw = exercise.get("avoid_if")
    avoid_list: List[str] = []
    if isinstance(avoid_if_raw, list):
        avoid_list = [str(x).lower() for x in avoid_if_raw if x]
    elif isinstance(avoid_if_raw, str) and avoid_if_raw:
        # Tolerate both JSON-array-as-string and comma-separated.
        avoid_list = [x.strip().lower() for x in re.split(r"[,;]", avoid_if_raw.strip("[]")) if x.strip()]
    avoid_map = {
        "shoulder": "shoulder_safe",
        "lower back": "lower_back_safe",
        "back": "lower_back_safe",   # library often says "back" meaning lumbar
        "knee": "knee_safe",
        "elbow": "elbow_safe",
        "wrist": "wrist_safe",
        "ankle": "ankle_safe",
        "hip": "hip_safe",
        "neck": "neck_safe",
    }
    for tag in avoid_list:
        for key, col in avoid_map.items():
            if key in tag:
                if flags[col]:
                    flags[col] = False
                    citations.append(f"[{col[:-5]} | avoid_if={tag!r}] library-authoritative contraindication flag")

    # --- safe_exercises_explicit override (FINAL — wins over avoid_if) -------
    # Clinical guidelines (JOSPT CPGs, McGill, Sanford FAI) explicitly
    # endorse certain exercises (bodyweight glute bridge, bird dog, clamshell,
    # side lying leg lift, seated leg curl) that would otherwise be blocked
    # by pattern-level hinge/isometric rules OR by library avoid_if metadata.
    # This override runs LAST so clinical research wins over any prior FALSE.
    for inj in INJURIES:
        col = f"{inj}_safe"
        inj_block = ref["injuries"].get(inj, {}) or {}
        safe_list = inj_block.get("safe_exercises_explicit") or []
        for entry in safe_list:
            safe_name = _normalize_name(entry.get("name", ""))
            if not safe_name:
                continue
            pattern_re = r"\b" + re.escape(safe_name) + r"(?:es|s)?\b"
            if re.search(pattern_re, norm):
                if not flags[col]:
                    flags[col] = True
                    src = entry.get("source", "")
                    citations.append(f"[{inj} | SAFE-OVERRIDE exact-name='{entry.get('name')}'] {src}")
                break

    # --- Null-pattern upper-body default override ----------------------------
    # Exercises with no detected movement_pattern AND an upper-body display
    # part (Biceps, Triceps, Forearms, Chest, Shoulders, Back, Rotator Cuff,
    # Neck) that do not contain stance/impact keywords are structurally
    # uninvolved with the lower extremity. Promote knee/hip/ankle to TRUE so
    # a lower-extremity-injured user isn't denied seated bicep curls etc.
    UPPER_BODY_PARTS = {"Biceps", "Triceps", "Forearms", "Chest", "Shoulders", "Back", "Rotator Cuff", "Neck"}
    LOWER_EXTREMITY_FLAGS = ("knee_safe", "hip_safe", "ankle_safe")
    STANCE_KEYWORDS = ("jump", "jumping", "hop", "sprint", "run", "stand", "walk",
                        "lunge", "squat", "step", "plyo", "burpee", "march", "skipp",
                        "skater", "bound", "agility")
    display_part = exercise.get("display_body_part") or ""
    if not pattern_internal and not elite and display_part in UPPER_BODY_PARTS:
        if not any(kw in norm for kw in STANCE_KEYWORDS):
            for col in LOWER_EXTREMITY_FLAGS:
                if not flags[col]:
                    flags[col] = True
                    citations.append(f"[{col[:-5]} | UPPER-BODY-DEFAULT] unclassified upper-body exercise, lower extremity topologically uninvolved")

    # --- Boolean attribute columns (computed off the full yaml pattern) -----
    is_overhead = pattern_internal in OVERHEAD_PATTERNS
    is_loaded_rotation = pattern_internal in ROTATION_PATTERNS
    is_high_impact = pattern_internal in PLYO_PATTERNS
    is_inversion = pattern_internal in INVERSION_PATTERNS
    is_hanging = pattern_internal in HANGING_PATTERNS
    if elite and elite["canonical"] in ("front lever", "back lever", "muscle up",
                                         "one arm pull-up", "skin the cat", "360 pull-up"):
        is_hanging = True
    if elite and elite["canonical"] in ("handstand push-up", "planche", "planche push-up",
                                         "press to handstand", "l-sit to handstand",
                                         "one arm handstand", "iron cross", "maltese", "victorian"):
        is_overhead = True
        is_inversion = True

    # --- Grip intensity (lightweight heuristic) -----------------------------
    grip_intensity: Optional[str] = None
    n = norm
    if any(t in n for t in ("farmer", "deadlift", "dead hang", "heavy grip", "plate pinch", "captains of crush")):
        grip_intensity = "heavy"
    elif is_hanging or "pull up" in n or "chin up" in n or "kettlebell swing" in n:
        grip_intensity = "moderate"
    elif "dumbbell" in n or "barbell" in n or "cable" in n or "row" in n:
        grip_intensity = "light"
    elif pattern_internal in ("isometric", "mobility") or not pattern_internal:
        grip_intensity = "none"

    # --- Plane + load axis (best-effort from pattern) -----------------------
    plane_of_motion: Optional[str] = None
    load_axis: Optional[str] = None
    if pattern_internal in ("loaded_rotation", "anti_rotation", "high_velocity_throw"):
        plane_of_motion = "transverse"
    elif pattern_internal in ("horizontal_abduction_loaded", "lunge"):
        plane_of_motion = "frontal"
    elif pattern_internal:
        plane_of_motion = "sagittal"

    eq = (exercise.get("equipment") or "").lower()
    if "bodyweight" in eq or eq in ("", "none"):
        load_axis = "bodyweight"
    elif pattern_internal in ("carry", "overhead_press", "squat", "deep_squat_loaded",
                               "hinge", "shrug_heavy", "behind_neck_press", "handstand_load"):
        load_axis = "axial"
    else:
        load_axis = "non-axial"

    # --- is_beginner_safe ---------------------------------------------------
    is_beginner_safe = (
        safety_difficulty == "beginner"
        and all(flags[col] for col in INJURY_FLAG_COLS)
    )

    # --- source citation + tagged_by ---------------------------------------
    base_citations: List[str] = []
    if pattern_internal:
        # Record BOTH the full yaml pattern and the downmapped (DB-persisted) one
        # so the manual auditor sees the precise classification.
        base_citations.append(
            f"[pattern-detected | yaml_pattern={pattern_internal} | "
            f"persisted={movement_pattern} | regex={pattern_match[1]!r}]"
        )
    if elite:
        base_citations.append(
            f"[elite-match | skill='{elite['canonical']}' | severity={elite['severity']}] {elite['source']}"
        )
    base_citations.extend(citations)

    has_explicit_name_hit = any(c.startswith("[") and "exact-name=" in c for c in citations)
    has_safe_override_hit = any("SAFE-OVERRIDE" in c for c in citations)
    has_upper_body_default_hit = any("UPPER-BODY-DEFAULT" in c for c in citations)
    has_avoid_if_hit = any("avoid_if=" in c for c in citations)
    if not pattern_internal and not elite:
        if has_explicit_name_hit or has_safe_override_hit or has_upper_body_default_hit or has_avoid_if_hit:
            # We know something concrete about this exercise (explicit-name hits,
            # library avoid_if data, or clinical safe-override guidance).
            # Preserve the flags we computed rather than failing closed.
            source_citation = "UNCLASSIFIED-PATTERN - explicit-name/safe-override/avoid_if hits | " + " | ".join(citations)
            safety_difficulty = "unknown"
            is_beginner_safe = False
        else:
            source_citation = "UNCLASSIFIED - needs manual audit"
            # Fail closed on everything.
            for col in INJURY_FLAG_COLS:
                flags[col] = False
            safety_difficulty = "unknown"
            is_beginner_safe = False
    else:
        source_citation = " | ".join(base_citations) if base_citations else (
            f"[pattern-detected | yaml_pattern={pattern_internal} | persisted={movement_pattern}]"
            if pattern_internal else "[elite-match only]"
        )

    return SafetyTagRow(
        exercise_id=str(ex_id),
        shoulder_safe=flags["shoulder_safe"],
        lower_back_safe=flags["lower_back_safe"],
        knee_safe=flags["knee_safe"],
        elbow_safe=flags["elbow_safe"],
        wrist_safe=flags["wrist_safe"],
        ankle_safe=flags["ankle_safe"],
        hip_safe=flags["hip_safe"],
        neck_safe=flags["neck_safe"],
        movement_pattern=movement_pattern,
        plane_of_motion=plane_of_motion,
        load_axis=load_axis,
        is_overhead=bool(is_overhead),
        is_loaded_rotation=bool(is_loaded_rotation),
        is_high_impact=bool(is_high_impact),
        is_inversion=bool(is_inversion),
        is_hanging=bool(is_hanging),
        grip_intensity=grip_intensity,
        safety_difficulty=safety_difficulty,
        is_beginner_safe=is_beginner_safe,
        source_citation=source_citation,
        tagged_by="rule",
        notes=None,
        _exercise_name=name,
    )


# ---------------------------------------------------------------------------
# Data fetching (optional supabase-py path)
# ---------------------------------------------------------------------------

def _try_import_supabase_client():
    try:
        sys.path.insert(0, str(BACKEND_ROOT))
        from core.supabase_client import get_supabase  # type: ignore
        return get_supabase
    except Exception as e:  # pragma: no cover — environment-specific
        print(f"[WARN] supabase client unavailable in this env: {e}", file=sys.stderr)
        return None


def fetch_exercises_via_supabase(
    get_supabase_fn,
    mode: str,
    exercise_id: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """
    Returns a list of exercise dicts with keys: id, name, target_muscle,
    secondary_muscles, equipment, difficulty_level, instructions.
    """
    sb = get_supabase_fn().client
    query = sb.table("exercise_library_cleaned").select(
        "id,name,target_muscle,secondary_muscles,equipment,difficulty_level,instructions,avoid_if,display_body_part"
    )
    if mode == "single":
        if not exercise_id:
            raise ValueError("--mode single requires --exercise-id")
        query = query.eq("id", exercise_id)
    # Paginated fetch.
    page_size = 1000
    rows: List[Dict[str, Any]] = []
    offset = 0
    while True:
        res = query.range(offset, offset + page_size - 1).execute()
        batch = res.data or []
        rows.extend(batch)
        if len(batch) < page_size:
            break
        offset += page_size
    if mode == "incremental":
        # Filter out already-tagged IDs.
        tagged = sb.table("exercise_safety_tags").select("exercise_id").execute()
        tagged_ids = {r["exercise_id"] for r in (tagged.data or [])}
        rows = [r for r in rows if r["id"] not in tagged_ids]
    return rows


# ---------------------------------------------------------------------------
# Writers
# ---------------------------------------------------------------------------

def _sql_bool(v: Optional[bool]) -> str:
    if v is None:
        return "NULL"
    return "TRUE" if v else "FALSE"


def _sql_str(v: Optional[str]) -> str:
    if v is None:
        return "NULL"
    escaped = v.replace("'", "''")
    return f"'{escaped}'"


def row_to_values_sql(row: SafetyTagRow) -> str:
    return (
        "("
        f"{_sql_str(row.exercise_id)}::uuid,"
        f"{_sql_bool(row.shoulder_safe)},"
        f"{_sql_bool(row.lower_back_safe)},"
        f"{_sql_bool(row.knee_safe)},"
        f"{_sql_bool(row.elbow_safe)},"
        f"{_sql_bool(row.wrist_safe)},"
        f"{_sql_bool(row.ankle_safe)},"
        f"{_sql_bool(row.hip_safe)},"
        f"{_sql_bool(row.neck_safe)},"
        f"{_sql_str(row.movement_pattern)},"
        f"{_sql_str(row.plane_of_motion)},"
        f"{_sql_str(row.load_axis)},"
        f"{_sql_bool(row.is_overhead)},"
        f"{_sql_bool(row.is_loaded_rotation)},"
        f"{_sql_bool(row.is_high_impact)},"
        f"{_sql_bool(row.is_inversion)},"
        f"{_sql_bool(row.is_hanging)},"
        f"{_sql_str(row.grip_intensity)},"
        f"{_sql_str(row.safety_difficulty)},"
        f"{_sql_bool(row.is_beginner_safe)},"
        f"{_sql_str(row.source_citation)},"
        f"{_sql_str(row.tagged_by)},"
        f"{_sql_str(row.notes)}"
        ")"
    )


UPSERT_COLUMNS = (
    "exercise_id,"
    "shoulder_safe,lower_back_safe,knee_safe,elbow_safe,"
    "wrist_safe,ankle_safe,hip_safe,neck_safe,"
    "movement_pattern,plane_of_motion,load_axis,"
    "is_overhead,is_loaded_rotation,is_high_impact,is_inversion,is_hanging,"
    "grip_intensity,safety_difficulty,is_beginner_safe,"
    "source_citation,tagged_by,notes"
)

UPSERT_CONFLICT_SET = ",".join([
    "shoulder_safe=EXCLUDED.shoulder_safe",
    "lower_back_safe=EXCLUDED.lower_back_safe",
    "knee_safe=EXCLUDED.knee_safe",
    "elbow_safe=EXCLUDED.elbow_safe",
    "wrist_safe=EXCLUDED.wrist_safe",
    "ankle_safe=EXCLUDED.ankle_safe",
    "hip_safe=EXCLUDED.hip_safe",
    "neck_safe=EXCLUDED.neck_safe",
    "movement_pattern=EXCLUDED.movement_pattern",
    "plane_of_motion=EXCLUDED.plane_of_motion",
    "load_axis=EXCLUDED.load_axis",
    "is_overhead=EXCLUDED.is_overhead",
    "is_loaded_rotation=EXCLUDED.is_loaded_rotation",
    "is_high_impact=EXCLUDED.is_high_impact",
    "is_inversion=EXCLUDED.is_inversion",
    "is_hanging=EXCLUDED.is_hanging",
    "grip_intensity=EXCLUDED.grip_intensity",
    "safety_difficulty=EXCLUDED.safety_difficulty",
    "is_beginner_safe=EXCLUDED.is_beginner_safe",
    "source_citation=EXCLUDED.source_citation",
    "tagged_by=EXCLUDED.tagged_by",
    "notes=EXCLUDED.notes",
    "tagged_at=now()",
])


def emit_upsert_sql(rows: Sequence[SafetyTagRow], batch_size: int = 500) -> Iterable[str]:
    for i in range(0, len(rows), batch_size):
        batch = rows[i:i + batch_size]
        values = ",\n  ".join(row_to_values_sql(r) for r in batch)
        sql = (
            f"INSERT INTO public.exercise_safety_tags ({UPSERT_COLUMNS})\n"
            f"VALUES\n  {values}\n"
            f"ON CONFLICT (exercise_id) DO UPDATE SET {UPSERT_CONFLICT_SET};"
        )
        yield sql


def write_via_supabase(get_supabase_fn, rows: Sequence[SafetyTagRow], batch_size: int = 500) -> int:
    sb = get_supabase_fn().client
    n = 0
    for i in range(0, len(rows), batch_size):
        batch = rows[i:i + batch_size]
        payload = []
        for r in batch:
            d = asdict(r)
            d.pop("_exercise_name", None)
            payload.append(d)
        res = sb.table("exercise_safety_tags").upsert(payload, on_conflict="exercise_id").execute()
        if getattr(res, "data", None) is not None:
            n += len(res.data)
        else:
            n += len(payload)
    return n


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------

def classify_all(
    exercises: Iterable[Dict[str, Any]],
    ref: Dict[str, Any],
    *,
    log_every: int = 200,
) -> List[SafetyTagRow]:
    compiled = _compile_pattern_rules(ref["pattern_detection_rules"])
    elite = _build_elite_index(ref["elite_calisthenics_skills"])

    out: List[SafetyTagRow] = []
    for i, ex in enumerate(exercises, 1):
        row = classify_exercise(ex, ref, compiled, elite)
        out.append(row)
        if log_every and i % log_every == 0:
            print(f"  ... classified {i} exercises (last: {row._exercise_name!r} -> pat={row.movement_pattern} diff={row.safety_difficulty})",
                  file=sys.stderr)
    return out


def summarize(rows: Sequence[SafetyTagRow]) -> Dict[str, Any]:
    from collections import Counter
    pat_counts = Counter(r.movement_pattern or "__unclassified__" for r in rows)
    diff_counts = Counter(r.safety_difficulty for r in rows)
    unclassified = [r for r in rows if r.source_citation.startswith("UNCLASSIFIED")]
    per_injury_safe = {
        col: sum(1 for r in rows if getattr(r, col) is True)
        for col in INJURY_FLAG_COLS
    }
    elite_match = sum(1 for r in rows if "elite-match" in (r.source_citation or ""))
    return {
        "total": len(rows),
        "by_movement_pattern": dict(pat_counts.most_common()),
        "by_safety_difficulty": dict(diff_counts.most_common()),
        "elite_matched": elite_match,
        "unclassified": len(unclassified),
        "per_injury_safe_count": per_injury_safe,
        "sample_unclassified": [r._exercise_name for r in unclassified[:20]],
        "beginner_safe_total": sum(1 for r in rows if r.is_beginner_safe),
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _parse_args(argv: Optional[List[str]] = None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--mode", choices=["full", "incremental", "single"], default="full")
    ap.add_argument("--exercise-id", default=None, help="UUID (for --mode single)")
    ap.add_argument("--dry-run", action="store_true", help="Do not write; print classified rows + summary")
    ap.add_argument("--emit-sql", action="store_true", help="Emit batched UPSERT SQL to --out / stdout")
    ap.add_argument("--out", default=None, help="Output path for --emit-sql or --emit-json")
    ap.add_argument("--emit-json", action="store_true", help="Emit classified rows as JSON (for MCP)")
    ap.add_argument("--sample", type=int, default=0, help="Limit to first N exercises (for --dry-run)")
    ap.add_argument("--input-json", default=None,
                    help="Read exercises from a local JSON array file instead of Supabase. "
                         "Array of {id,name,target_muscle,secondary_muscles,equipment,difficulty_level}.")
    ap.add_argument("--batch-size", type=int, default=500)
    ap.add_argument("--compact-citations", action="store_true",
                    help="Truncate each row's source_citation to 180 chars. "
                         "Reduces upsert SQL size ~30%%. "
                         "Only affects --emit-sql / --emit-json output.")
    ap.add_argument("--ultra-compact", action="store_true",
                    help="Reduce each citation to `rule:<yaml_pattern>[+name]`. "
                         "Full citation lives in the yaml; persisted value becomes a "
                         "lookup key. Needed to keep total upsert SQL under MCP "
                         "transport limits for a ~2200-row library.")
    return ap.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    args = _parse_args(argv)
    ref = load_reference()

    # --- fetch exercises ----------------------------------------------------
    exercises: List[Dict[str, Any]] = []
    if args.input_json:
        p = Path(args.input_json)
        if not p.exists():
            print(f"input JSON not found: {p}", file=sys.stderr)
            return 2
        with p.open("r", encoding="utf-8") as f:
            exercises = json.load(f)
    else:
        get_sb = _try_import_supabase_client()
        if get_sb is None:
            print("No supabase client available; use --input-json or run within backend env.", file=sys.stderr)
            return 2
        exercises = fetch_exercises_via_supabase(get_sb, args.mode, args.exercise_id)

    if args.sample and args.sample < len(exercises):
        # deterministic sample: take the first N
        exercises = exercises[: args.sample]

    print(f"Loaded {len(exercises)} exercises; classifying...", file=sys.stderr)
    t0 = time.time()
    rows = classify_all(exercises, ref)
    t1 = time.time()
    print(f"Classified {len(rows)} exercises in {t1 - t0:.2f}s", file=sys.stderr)

    if args.compact_citations:
        # Truncate each citation to a cap. The full citation is embedded
        # in-line for Phase 2G's MCP upserts (which have transport-size
        # limits); the yaml itself remains the canonical source, and this
        # truncation is purely for upload-size reduction. For a full
        # audit trail, re-run the tagger without --compact-citations and
        # re-upsert via direct-write.
        CAP = 180
        for r in rows:
            if r.source_citation and len(r.source_citation) > CAP:
                r.source_citation = r.source_citation[: CAP - 3] + "..."
            # clear any notes to keep the column NULL
            r.notes = None

    if args.ultra_compact:
        # Reduce every citation to `rule:<yaml_pattern>` or
        # `rule:UNCLASSIFIED[+exact-name]`. The full citation text lives in
        # the yaml; the persisted field is a lookup key for Phase 4N audit.
        # Reduces the average values-row size from ~1100 chars to ~250.
        for r in rows:
            cit = r.source_citation or ""
            if cit.startswith("UNCLASSIFIED - needs manual audit"):
                r.source_citation = "rule:UNCLASSIFIED"
            elif cit.startswith("UNCLASSIFIED-PATTERN"):
                r.source_citation = "rule:UNCLASSIFIED-name-hits-only"
            else:
                # Pull yaml_pattern=... out of the citation
                m = re.search(r"yaml_pattern=([a-z_]+)", cit)
                if m:
                    tag = f"rule:{m.group(1)}"
                else:
                    m2 = re.search(r"elite-match \| skill='([^']+)'", cit)
                    tag = f"rule:elite:{m2.group(1)}" if m2 else "rule:pattern-detected"
                if "exact-name=" in cit:
                    tag += "+name"
                r.source_citation = tag
            r.notes = None

    summary = summarize(rows)
    print("SUMMARY:", file=sys.stderr)
    print(json.dumps(summary, indent=2), file=sys.stderr)

    # --- output / write -----------------------------------------------------
    if args.emit_json:
        payload = [{k: v for k, v in asdict(r).items() if k != "_exercise_name"} for r in rows]
        target = args.out or "-"
        if target == "-":
            print(json.dumps(payload, indent=2))
        else:
            Path(target).write_text(json.dumps(payload, indent=2))
            print(f"Wrote {len(payload)} rows as JSON to {target}", file=sys.stderr)
        return 0

    if args.emit_sql:
        target = args.out or "-"
        if target == "-":
            for stmt in emit_upsert_sql(rows, args.batch_size):
                print(stmt + "\n")
        else:
            with open(target, "w", encoding="utf-8") as f:
                for stmt in emit_upsert_sql(rows, args.batch_size):
                    f.write(stmt + "\n")
            print(f"Wrote SQL (batch_size={args.batch_size}) to {target}", file=sys.stderr)
        return 0

    if args.dry_run:
        # Print first ~10 rows in detail + full summary above.
        for r in rows[:10]:
            print(json.dumps({k: v for k, v in asdict(r).items() if k != "_exercise_name"}, indent=2))
        return 0

    # Live DB write via supabase-py.
    get_sb = _try_import_supabase_client()
    if get_sb is None:
        print("Cannot write: no supabase client. Use --emit-sql and execute via MCP.", file=sys.stderr)
        return 2
    n = write_via_supabase(get_sb, rows, args.batch_size)
    print(f"Upserted {n} rows to exercise_safety_tags", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
