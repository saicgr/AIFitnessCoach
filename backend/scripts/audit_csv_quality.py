"""Phase verification — re-audit any historical generate-/regenerate-stream CSV
without re-running paid Gemini sweeps (per `feedback_validation_sweep_cost`).

Two modes:

1. **CSV mode** (default): re-grade an existing sweep output CSV against the
   full 25-section `workout_quality_checklist.md` rubric. Emits
   `workouts_scored.csv`, `audit_full.json`, `audit_full_brief.md`.

2. **Single-payload mode** (``--single-payload payload.json``): score one
   captured curl response against the same rubric. Used in Phase-3 verification
   to confirm a backend fix without re-running the paid sweep.

Usage:
    .venv/bin/python scripts/audit_csv_quality.py \\
        scripts/output/render_generate_stream_full_<TIMESTAMP>/workouts.csv

    .venv/bin/python scripts/audit_csv_quality.py --single-payload curl_b3.json

Section scoring legend per row:
  pass  ✅  meets criterion
  warn  ⚠️   borderline / soft fail
  fail  ❌  hard violation
  skip  ⏭   not applicable (request didn't supply the inputs)
"""
from __future__ import annotations

import argparse
import csv
import json
import math
import re
import sys
from collections import Counter, defaultdict, deque
from pathlib import Path
from typing import Any, Iterable

# Reuse the canonicalizer used by server-side dedup so this scorer agrees
# with the API on what counts as a duplicate exercise.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
try:
    from services.exercise_rag.utils import canonicalize_exercise_name  # type: ignore
except Exception:  # fall back to a tiny local approximation if import fails
    def canonicalize_exercise_name(s: str) -> str:
        return re.sub(r"\s+", " ", (s or "")).strip().lower()


# ---------------------------------------------------------------------------
# Rubric tables (mirrors workout_quality_checklist.md)
# ---------------------------------------------------------------------------

# Section B — per-fitness-level caps (validation_utils.py:57-128)
LEVEL_CAPS = {
    "beginner":     {"max_sets": 3, "max_reps": 12, "min_rest_s": 60},
    "intermediate": {"max_sets": 4, "max_reps": 15, "min_rest_s": 45},
    "advanced":     {"max_sets": 5, "max_reps": 20, "min_rest_s": 30},
    "hell":         {"max_sets": 6, "max_reps": 20, "min_rest_s": 30},
}

# High-rep bonus exercises (+8 reps over level cap, capped at 30)
HIGH_REP_BONUS = (
    "crunch", "sit-up", "sit up", "calf raise", "lateral raise",
    "glute bridge", "burpee",
)

# Section D — goal-driven prescription (quick_workout_constants.dart)
GOAL_PRESCRIPTIONS: dict[str, dict[str, Any]] = {
    "strength":    {"reps_max": 10, "sets_compound": 5, "rest_compound": 180},
    "power":       {"reps_max": 5,  "sets_compound": 5, "rest_compound": 240},
    "hypertrophy": {"reps_min_compound_sets": 3,        "rest_compound": 120},
    "endurance":   {"rest_max": 90, "reps_min": 15},
    "fat_loss":    {"rest_max": 90},
    "mobility":    {"no_weighted_compound": True},
}

# Section F — movement-pattern keyword map (port of movement_patterns.dart)
PATTERN_KEYWORDS: dict[str, tuple[str, ...]] = {
    "squat":            ("squat", "lunge", "split squat", "step-up", "step up", "leg press", "pistol", "wall sit"),
    "hinge":            ("deadlift", "rdl", "good morning", "swing", "hinge", "kettlebell swing", "hip thrust", "glute bridge"),
    "push_horizontal":  ("bench press", "push-up", "push up", "chest press", "dip ", "fly", "chest fly"),
    "pull_horizontal":  ("row", "inverted row"),
    "push_vertical":    ("overhead press", "shoulder press", "military press", "pike push", "handstand push"),
    "pull_vertical":    ("pull-up", "pull up", "chin-up", "chin up", "lat pulldown", "pulldown"),
    "carry":            ("carry", "farmer", "suitcase", "yoke walk"),
    "core":             ("plank", "hollow", "crunch", "sit-up", "sit up", "ab wheel", "leg raise", "dead bug", "bird dog"),
    "cardio":           ("run", "jog", "sprint", "burpee", "jumping jack", "mountain climber", "high knee", "jump rope", "row machine", "bike", "treadmill"),
}

# Section G — what counts as a compound (movement_pattern in {squat,hinge,
# push_horizontal,pull_horizontal,push_vertical,pull_vertical}).
COMPOUND_PATTERNS = {
    "squat", "hinge", "push_horizontal", "pull_horizontal",
    "push_vertical", "pull_vertical",
}

# Section H — injury-blocked pattern keywords (workout_safety_validator.py)
INJURY_BLOCKED: dict[str, tuple[str, ...]] = {
    "shoulder":   ("overhead press", "behind the neck", "weighted dip"),
    "lower_back": ("conventional deadlift", "good morning", "loaded twist"),
    "knee":       ("deep squat", "jump squat", "plyometric", "lunge"),
    "elbow":      ("skullcrusher", "close grip bench"),
    "wrist":      ("flat-palm push-up", "front rack"),
    "ankle":      ("box jump", "single-leg plyometric"),
    "hip":        ("wide stance squat", "deep hinge"),
    "neck":       ("shrug", "weighted front squat", "headstand"),
}

# Section O — equipment subset check. The set of "high-equipment" tokens that
# imply specific gear; if any of these substrings appears in an exercise name
# they should be present in the request's equipment list.
EQUIPMENT_TOKENS: dict[str, tuple[str, ...]] = {
    "barbell":    ("barbell",),
    "dumbbell":   ("dumbbell", "db ", "single-arm db"),
    "kettlebell": ("kettlebell", "kb "),
    "cable":      ("cable",),
    "machine":    ("machine", "smith machine", "leg press", "lat pulldown"),
    "bands":      ("band", "resistance band"),
    "trx":        ("trx", "suspension"),
    "medicine_ball": ("medicine ball", "med ball", "wall ball"),
}

# Section Y — focus_area → expected workout_type
FOCUS_TYPE_MAP: dict[str, set[str]] = {
    "cardio":    {"cardio", "hiit"},
    "endurance": {"cardio", "hiit"},
    "hiit":      {"cardio", "hiit"},
    "mobility":  {"mobility"},
    "stretching":{"mobility"},
    "recovery":  {"mobility", "recovery"},
}


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

def _safe_int(s: str | int | float | None, default: int = 0) -> int:
    try:
        return int(float(s))  # type: ignore[arg-type]
    except Exception:
        return default


def _safe_float(s: Any, default: float = 0.0) -> float:
    try:
        v = float(s)
        if math.isnan(v) or math.isinf(v):
            return default
        return v
    except Exception:
        return default


def _split_pipe(s: str) -> list[str]:
    if not s:
        return []
    return s.split("|")


def parse_request_body(row: dict[str, Any]) -> dict[str, Any]:
    raw = row.get("request_body_json") or "{}"
    try:
        return json.loads(raw)
    except Exception:
        return {}


def parse_exercises(row: dict[str, Any]) -> list[dict[str, Any]]:
    """Reconstitute exercises from the per_exercise_* pipe columns."""
    names = _split_pipe(row.get("exercise_names_pipe") or "")
    if not names:
        return []
    sets_l = _split_pipe(row.get("per_exercise_sets") or "")
    reps_l = _split_pipe(row.get("per_exercise_reps") or "")
    weight_l = _split_pipe(row.get("per_exercise_weight_kg") or "")
    rest_l = _split_pipe(row.get("per_exercise_rest_seconds") or "")
    muscle_l = _split_pipe(row.get("per_exercise_muscle_group") or "")
    out: list[dict[str, Any]] = []
    for i, name in enumerate(names):
        out.append({
            "name": name,
            "sets": _safe_int(sets_l[i] if i < len(sets_l) else None),
            "reps_raw": (reps_l[i] if i < len(reps_l) else ""),
            "reps": _max_reps_in_field(reps_l[i] if i < len(reps_l) else ""),
            "weight_kg": _safe_float(weight_l[i] if i < len(weight_l) else None),
            "rest_seconds": _safe_int(rest_l[i] if i < len(rest_l) else None),
            "muscle_group": (muscle_l[i] if i < len(muscle_l) else "").strip(),
        })
    return out


def _max_reps_in_field(s: str) -> int:
    """Reps may be int '12' or range '8-12'. Returns the larger end."""
    if not s:
        return 0
    m = re.findall(r"\d+", s)
    if not m:
        return 0
    return max(int(x) for x in m)


def detect_pattern(exercise_name: str) -> str | None:
    n = (exercise_name or "").lower()
    for pat, kws in PATTERN_KEYWORDS.items():
        for kw in kws:
            if kw in n:
                return pat
    return None


def detect_equipment_required(exercise_name: str) -> set[str]:
    """Return set of equipment categories the exercise name implies."""
    n = (exercise_name or "").lower()
    out: set[str] = set()
    for cat, toks in EQUIPMENT_TOKENS.items():
        for t in toks:
            if t in n:
                out.add(cat)
                break
    return out


# ---------------------------------------------------------------------------
# Per-row scorers — each returns ("pass"|"warn"|"fail"|"skip", detail_str)
# ---------------------------------------------------------------------------

def score_a_schema(row, body, exes):
    if not exes:
        return ("skip", "no exercises (likely error row)")
    missing = []
    for i, e in enumerate(exes):
        if not e["name"].strip():
            missing.append(f"#{i}.name")
        if e["sets"] < 1:
            missing.append(f"#{i}.sets")
        if e["reps"] < 1:
            missing.append(f"#{i}.reps")
        if e["rest_seconds"] < 30:
            missing.append(f"#{i}.rest<30")
        if not e["muscle_group"]:
            missing.append(f"#{i}.muscle_group")
    dur = _safe_int(row.get("duration_minutes"))
    if not (1 <= dur <= 480):
        missing.append(f"workout.duration={dur}")
    if not row.get("workout_id"):
        missing.append("workout_id")
    if not row.get("workout_name"):
        missing.append("workout_name")
    if not row.get("workout_difficulty"):
        missing.append("difficulty")
    if missing:
        return ("fail", "; ".join(missing[:5]))
    return ("pass", "")


def score_b_param_caps(row, body, exes):
    level = (body.get("fitness_level") or "").lower()
    cap = LEVEL_CAPS.get(level)
    if not cap or not exes:
        return ("skip", f"level={level or 'none'}")
    fails = []
    for i, e in enumerate(exes):
        # high-rep bonus
        rep_cap = cap["max_reps"]
        if any(b in e["name"].lower() for b in HIGH_REP_BONUS):
            rep_cap = min(30, rep_cap + 8)
        if e["sets"] > cap["max_sets"]:
            fails.append(f"#{i} sets={e['sets']}>{cap['max_sets']}")
        if e["reps"] > rep_cap:
            fails.append(f"#{i} reps={e['reps']}>{rep_cap}")
        if 0 < e["rest_seconds"] < cap["min_rest_s"]:
            fails.append(f"#{i} rest={e['rest_seconds']}<{cap['min_rest_s']}")
    if fails:
        return ("fail", "; ".join(fails[:3]))
    return ("pass", "")


def score_c_difficulty(row, body, exes):
    level = (body.get("fitness_level") or "").lower()
    diff = (row.get("workout_difficulty") or "").lower()
    if not level or not diff:
        return ("skip", "")
    if diff not in {"easy", "medium", "hard", "hell"}:
        return ("fail", f"difficulty={diff} not in canon")
    if level == "beginner" and diff not in {"easy", "medium"}:
        return ("fail", f"beginner→{diff}")
    if level == "advanced":
        focus = (body.get("focus_areas") or [None])[0]
        is_mobility = (focus or "").lower() in {"mobility", "stretching", "recovery"}
        if not is_mobility and diff == "easy":
            return ("warn", "advanced w/ easy + non-mobility focus")
    return ("pass", "")


def score_d_goal(row, body, exes):
    goals = body.get("goals") or []
    if not goals or not exes:
        return ("skip", "")
    g = (goals[0] if isinstance(goals, list) else goals).lower().replace(" ", "_")
    pres = GOAL_PRESCRIPTIONS.get(g)
    if not pres:
        return ("skip", f"goal={g}")
    fails = []
    if g == "strength":
        if all(e["reps"] > 10 for e in exes):
            fails.append(f"strength but all reps>10")
    if g == "hypertrophy":
        compound_low = sum(1 for e in exes if e["sets"] < 3 and detect_pattern(e["name"]) in COMPOUND_PATTERNS)
        if exes and all(e["sets"] < 3 for e in exes):
            fails.append("hypertrophy but all sets<3")
    if g == "endurance":
        if all(e["rest_seconds"] > 90 for e in exes if e["rest_seconds"] > 0):
            fails.append("endurance but all rest>90s")
    if g == "mobility":
        for e in exes:
            if e["weight_kg"] > 0 and detect_pattern(e["name"]) in COMPOUND_PATTERNS:
                fails.append(f"mobility w/ weighted compound: {e['name']}")
                break
    if g == "fat_loss":
        # classic 3×10/120s = warn
        if exes and all(e["sets"] == 3 and 8 <= e["reps"] <= 12 and e["rest_seconds"] >= 120 for e in exes):
            return ("warn", "fat_loss w/ classic hypertrophy schema")
    if fails:
        return ("fail", "; ".join(fails[:3]))
    return ("pass", "")


def score_e_density(row, body, exes):
    n = len(exes)
    d = _safe_int(row.get("duration_minutes"))
    if n == 0 or d == 0:
        return ("skip", "")
    if d <= 15 and n > 4:
        return ("fail", f"{d}min/{n}ex (cap=4)")
    ratio = d / n
    if ratio < 4:
        return ("fail", f"{d}min/{n}ex ratio={ratio:.1f}")
    if ratio < 5:
        return ("warn", f"{d}min/{n}ex ratio={ratio:.1f}")
    return ("pass", "")


def score_f_pattern_diversity(row, body, exes):
    if not exes:
        return ("skip", "")
    d = _safe_int(row.get("duration_minutes"))
    pats = {detect_pattern(e["name"]) for e in exes}
    pats.discard(None)
    n = len(pats)
    if d <= 5:
        thresh = 2
    elif d <= 15:
        thresh = 3
    else:
        thresh = 5
    if n < thresh:
        return ("fail", f"patterns={sorted(p for p in pats if p)} n={n}<{thresh}")
    return ("pass", "")


def score_g_compound_first(row, body, exes):
    wt = (row.get("workout_type") or "").lower()
    if wt not in {"strength", "powerlifting", "hypertrophy"}:
        return ("skip", f"type={wt}")
    if len(exes) < 2:
        return ("skip", "n_ex<2")
    first_two = exes[:2]
    if not any(detect_pattern(e["name"]) in COMPOUND_PATTERNS for e in first_two):
        return ("fail", f"first 2 are isolation: {[e['name'] for e in first_two]}")
    return ("pass", "")


def score_h_injury(row, body, exes):
    inj = body.get("injuries") or []
    if not inj:
        return ("skip", "")
    fails = []
    for i in inj:
        i = (i or "").lower()
        for blocked in INJURY_BLOCKED.get(i, ()):
            for e in exes:
                if blocked in e["name"].lower():
                    fails.append(f"injury={i}: {e['name']}")
    if fails:
        return ("fail", "; ".join(fails[:3]))
    return ("pass", "")


def score_i_integrity(row, body, exes):
    if not exes:
        return ("skip", "")
    issues = []
    # 0/NaN/negatives
    for i, e in enumerate(exes):
        if e["sets"] <= 0:
            issues.append(f"#{i} sets=0")
        if e["reps"] <= 0:
            issues.append(f"#{i} reps=0")
        if e["weight_kg"] < 0:
            issues.append(f"#{i} weight<0")
        if e["rest_seconds"] < 0:
            issues.append(f"#{i} rest<0")
    # Dup detection (5 collision modes from checklist I)
    seen_canon: set[str] = set()
    seen_triple: set[tuple[str, str, str]] = set()
    for e in exes:
        canon = canonicalize_exercise_name(e["name"]).lower()
        if canon in seen_canon and canon:
            issues.append(f"dup canon: {e['name']}")
        seen_canon.add(canon)
        # (pattern, muscle, equipment) triple
        pat = detect_pattern(e["name"]) or ""
        eq = ",".join(sorted(detect_equipment_required(e["name"])))
        muscle = (e["muscle_group"] or "").split(",")[0].strip().lower()
        triple = (pat, muscle, eq)
        if all(triple) and triple in seen_triple:
            issues.append(f"dup triple: {triple}")
        seen_triple.add(triple)
    if issues:
        return ("fail", "; ".join(issues[:3]))
    return ("pass", "")


def score_j_physio(row, body, exes):
    # Only meaningful if ai_prompt or birth_date present.
    ap = (body.get("ai_prompt") or "").lower()
    if not ap:
        return ("skip", "no ai_prompt")
    diff = (row.get("workout_difficulty") or "").lower()
    fails = []
    if "75" in ap or "senior" in ap:
        if diff == "hell":
            fails.append("senior+hell")
    if "pregnan" in ap or "trimester" in ap:
        for e in exes:
            if "supine" in e["name"].lower() or "lying" in e["name"].lower():
                fails.append(f"pregnant+supine: {e['name']}")
                break
    if "heart" in ap or "blood pressure" in ap:
        for e in exes:
            if e["weight_kg"] > 0 and detect_pattern(e["name"]) in {"squat", "hinge", "push_vertical"}:
                fails.append(f"BP+heavy compound: {e['name']}")
                break
    if fails:
        return ("fail", "; ".join(fails[:3]))
    return ("pass", "")


def score_k_pattern_balance(row, body, exes):
    if len(exes) < 3:
        return ("skip", "")
    counts: Counter = Counter()
    for e in exes:
        p = detect_pattern(e["name"])
        if p:
            counts[p] += 1
    total = sum(counts.values()) or 1
    top, n = counts.most_common(1)[0] if counts else (None, 0)
    if top and n / total > 0.50:
        return ("warn", f"{top}={n}/{total}")
    return ("pass", "")


def score_l_structure(row, body, exes):
    d = _safe_int(row.get("duration_minutes"))
    if d < 30 or not exes:
        return ("skip", "")
    notes = (row.get("workout_notes") or "").lower()
    has_marker = any(k in notes for k in ("warmup", "warm-up", "warm up", "cooldown", "cool-down", "cool down"))
    if not has_marker:
        return ("warn", "no warmup/cooldown marker in notes")
    return ("pass", "")


def score_o_equipment(row, body, exes):
    eq = body.get("equipment")
    if eq is None:
        return ("skip", "no equipment field")
    eq_set = {(s or "").lower() for s in eq} if isinstance(eq, list) else set()
    bodyweight_only = (eq_set == set() or eq_set == {"bodyweight"})
    fails = []
    for e in exes:
        req = detect_equipment_required(e["name"])
        if bodyweight_only and req:
            fails.append(f"BW-only req={req}: {e['name']}")
            continue
        # Otherwise require subset
        for needed in req:
            if needed in {"machine"} and any("machine" in q for q in eq_set):
                continue
            if needed not in eq_set and not any(needed in q or q in needed for q in eq_set):
                # Only flag if it's a strong category
                if needed in {"barbell", "kettlebell", "cable", "machine", "dumbbell"}:
                    fails.append(f"need={needed} not in {sorted(eq_set)}: {e['name']}")
                    break
    if fails:
        return ("fail", "; ".join(fails[:3]))
    return ("pass", "")


def score_p_user_state(row, body, exes):
    ap = (body.get("ai_prompt") or "").lower()
    if not ap:
        return ("skip", "")
    if any(k in ap for k in ("tired", "sick", "sore", "fatigued", "exhausted")):
        diff = (row.get("workout_difficulty") or "").lower()
        if diff in {"hard", "hell"}:
            return ("fail", f"user tired but diff={diff}")
    return ("pass", "")


def score_r_personalization(row, body, exes, recycled_phrases: set[str]):
    notes = (row.get("workout_notes") or "").strip()
    if not notes:
        return ("warn", "empty notes")
    if notes in recycled_phrases:
        return ("warn", f"recycled phrase: {notes[:60]}")
    return ("pass", "")


def score_s_streaming(row, body, exes):
    sse = _safe_int(row.get("sse_event_count"))
    status = row.get("http_status") or ""
    if status == "200" and sse < 3:
        return ("fail", f"sse={sse} on 200")
    return ("pass", "")


def score_u_locale(row, body, exes):
    fails = []
    for e in exes:
        # Emoji or RTL Arabic
        if any(ord(c) > 0x1F000 for c in e["name"]):
            fails.append(f"emoji in name: {e['name']}")
        if any("֐" <= c <= "ࣿ" for c in e["name"]):
            fails.append(f"RTL in name: {e['name']}")
        if len(e["name"]) > 200:
            fails.append(f"name>200ch: {e['name'][:40]}…")
    if fails:
        return ("warn", "; ".join(fails[:3]))
    return ("pass", "")


def score_w_excludes(row, body, exes):
    excludes = body.get("exclude_exercises") or []
    if not excludes:
        return ("skip", "")
    excl_canon = {canonicalize_exercise_name(s).lower() for s in excludes}
    excl_canon.discard("")
    for e in exes:
        c = canonicalize_exercise_name(e["name"]).lower()
        if c in excl_canon:
            return ("fail", f"excluded leak: {e['name']}")
    return ("pass", "")


def score_x_duration_drift(row, body, exes):
    if not exes:
        return ("skip", "")
    requested = _safe_int(row.get("duration_minutes"))
    if requested == 0:
        return ("skip", "")
    # Estimate: each exercise = sets × (work_seconds + rest_seconds)
    # work_seconds ≈ reps × 3s for strength, 1s/rep for cardio
    est_seconds = 0
    for e in exes:
        reps = e["reps"] or 10
        sets = e["sets"] or 3
        rest = e["rest_seconds"] or 60
        per_set_work = reps * 3
        est_seconds += sets * (per_set_work + rest)
    est_min = est_seconds / 60
    drift = abs(est_min - requested) / max(requested, 1)
    if drift > 0.40:
        return ("fail", f"requested={requested} est={est_min:.0f} drift={drift:.0%}")
    if drift > 0.20:
        return ("warn", f"requested={requested} est={est_min:.0f} drift={drift:.0%}")
    return ("pass", "")


def score_y_type_focus(row, body, exes):
    focus = body.get("focus_areas") or []
    if not focus:
        return ("skip", "")
    f = (focus[0] if isinstance(focus, list) else focus).lower()
    expected = FOCUS_TYPE_MAP.get(f)
    if not expected:
        return ("skip", f"focus={f}")
    wt = (row.get("workout_type") or "").lower()
    if wt not in expected:
        return ("fail", f"focus={f} → expected type∈{sorted(expected)}, got {wt}")
    return ("pass", "")


# Ordered list of per-row sections (cross-row sections are computed separately)
PER_ROW_SECTIONS = [
    ("A_schema",            score_a_schema),
    ("B_param_caps",        score_b_param_caps),
    ("C_difficulty",        score_c_difficulty),
    ("D_goal",              score_d_goal),
    ("E_density",           score_e_density),
    ("F_pattern_diversity", score_f_pattern_diversity),
    ("G_compound_first",    score_g_compound_first),
    ("H_injury",            score_h_injury),
    ("I_integrity",         score_i_integrity),
    ("J_physio",            score_j_physio),
    ("K_pattern_balance",   score_k_pattern_balance),
    ("L_structure",         score_l_structure),
    ("O_equipment",         score_o_equipment),
    ("P_user_state",        score_p_user_state),
    ("S_streaming",         score_s_streaming),
    ("U_locale",            score_u_locale),
    ("W_excludes",          score_w_excludes),
    ("X_duration_drift",    score_x_duration_drift),
    ("Y_type_focus",        score_y_type_focus),
]

CRITICAL_SECTIONS = {
    "A_schema", "B_param_caps", "C_difficulty", "D_goal", "E_density",
    "G_compound_first", "H_injury", "I_integrity", "O_equipment",
    "W_excludes", "Y_type_focus",
}


# ---------------------------------------------------------------------------
# Cross-row rollups (sections M, N, T, Z + the existing 7)
# ---------------------------------------------------------------------------

def cross_row_rollups(rows: list[dict[str, Any]], ok_rows: list[dict[str, Any]]) -> dict:
    out: dict = {}

    # name recycling (M / existing)
    name_freq = Counter(r["workout_name"] for r in ok_rows if r.get("workout_name"))
    top10 = name_freq.most_common(10)
    top10_share = sum(c for _, c in top10) / max(len(ok_rows), 1)
    out["M_name_recycling"] = {
        "unique_names": len(name_freq),
        "unique_share": round(len(name_freq) / max(len(ok_rows), 1), 3),
        "top10_share": round(top10_share, 3),
        "top10_target": 0.25,
        "top10": [(n, c) for n, c in top10],
        "status": "PASS" if top10_share < 0.25 else "WARN" if top10_share < 0.40 else "FAIL",
    }

    # within-block & cross-block exercise overlap (T)
    by_blk: dict = defaultdict(list)
    for r in ok_rows:
        by_blk[r.get("scenario_block") or "?"].append(r)
    overlap = {}
    worst_within = 0.0
    for blk, rs in by_blk.items():
        rs3 = rs[:3]
        if len(rs3) < 2:
            continue
        sets = [set((r.get("exercise_names_pipe") or "").lower().split("|")) for r in rs3]
        common = set.intersection(*sets) - {""}
        union = set.union(*sets) - {""}
        share = len(common) / max(len(union), 1)
        overlap[blk] = round(share, 3)
        worst_within = max(worst_within, share)
    out["T_within_block_overlap"] = {
        "max_share": round(worst_within, 3),
        "target": 0.30,
        "by_block": overlap,
        "status": "PASS" if worst_within < 0.30 else "WARN" if worst_within < 0.50 else "FAIL",
    }

    # N — volume landmarks proxy (per-muscle sets in single session)
    # Flag any single session that delivers >MRV for one muscle (Israetel proxy: chest=22, back=25, shoulder=20, quad=20, ham=20).
    MRV = {"chest": 22, "back": 25, "shoulder": 20, "quadriceps": 20, "hamstrings": 20, "glutes": 20, "biceps": 18, "triceps": 18}
    over_mrv = []
    for r in ok_rows:
        exes = parse_exercises(r)
        muscle_sets: Counter = Counter()
        for e in exes:
            m = (e["muscle_group"] or "").split(",")[0].strip().lower()
            for k in MRV:
                if k in m:
                    muscle_sets[k] += e["sets"]
                    break
        for m, s in muscle_sets.items():
            if s > MRV[m]:
                over_mrv.append({"idx": r["idx"], "muscle": m, "sets": s, "mrv": MRV[m]})
    out["N_volume_landmarks"] = {
        "count": len(over_mrv),
        "samples": over_mrv[:5],
        "target": 0,
        "status": "PASS" if not over_mrv else "WARN",
    }

    # Z — Block 1 stress / latency outliers
    lats = [_safe_int(r.get("latency_ms")) for r in ok_rows if r.get("latency_ms")]
    p95 = sorted(lats)[int(len(lats) * 0.95)] if lats else 0
    blk1_outliers = [
        {"idx": r["idx"], "latency_ms": _safe_int(r.get("latency_ms"))}
        for r in ok_rows
        if r.get("scenario_block") == "1" and _safe_int(r.get("latency_ms")) > p95 * 2
    ]
    out["Z_block1_outliers"] = {
        "count": len(blk1_outliers),
        "p95_ms": p95,
        "samples": blk1_outliers[:5],
        "status": "PASS" if len(blk1_outliers) < 3 else "WARN",
    }

    # legacy 7 (kept for parity with previous reports)
    err_msgs = Counter()
    for r in rows:
        if r.get("error_message"):
            msg = r["error_message"]
            if "INCOMPATIBLE_EQUIPMENT_FOCUS" in msg:
                err_msgs["INCOMPATIBLE_EQUIPMENT_FOCUS_422"] += 1
            elif msg.startswith("HTTP 401"):
                err_msgs["HTTP_401_session_expired"] += 1
            elif msg[:8].startswith(("HTTP 5", "HTTP 4")):
                err_msgs[msg[:9]] += 1
            else:
                err_msgs["other"] += 1
    out["error_buckets"] = dict(err_msgs)

    return out


# ---------------------------------------------------------------------------
# Main scorer
# ---------------------------------------------------------------------------

def score_one_row(row: dict[str, Any], recycled_phrases: set[str]) -> dict[str, Any]:
    body = parse_request_body(row)
    exes = parse_exercises(row)
    scores: dict[str, str] = {}
    details: dict[str, str] = {}
    crit_fails = 0
    any_fail = 0
    any_warn = 0
    for name, fn in PER_ROW_SECTIONS:
        if name == "R_personalization":
            status, detail = score_r_personalization(row, body, exes, recycled_phrases)
        else:
            status, detail = fn(row, body, exes)
        scores[name] = status
        if detail:
            details[name] = detail
        if status == "fail":
            any_fail += 1
            if name in CRITICAL_SECTIONS:
                crit_fails += 1
        elif status == "warn":
            any_warn += 1
    # R is run separately because it needs the rollup
    status, detail = score_r_personalization(row, body, exes, recycled_phrases)
    scores["R_personalization"] = status
    if detail:
        details["R_personalization"] = detail
    if status == "warn":
        any_warn += 1
    return {
        "scores": scores,
        "details": details,
        "score_total_fail": any_fail,
        "score_total_warn": any_warn,
        "score_critical_fails": crit_fails,
    }


def audit_csv(csv_path: Path, write_outputs: bool = True) -> dict:
    rows = list(csv.DictReader(csv_path.open()))
    ok = [r for r in rows if not r.get("error_message")]

    # Build the recycled-phrases set first (notes appearing >5% of rows)
    notes = Counter((r.get("workout_notes") or "").strip() for r in ok)
    recycled_phrases = {k for k, c in notes.items() if k and c / max(len(ok), 1) > 0.05}

    # Per-row scoring
    per_row: list[dict[str, Any]] = []
    section_failures: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for r in rows:
        if r.get("error_message"):
            continue  # Errored rows are graded by error_buckets in cross-row
        scored = score_one_row(r, recycled_phrases)
        per_row.append({"idx": r["idx"], **scored})
        for s, status in scored["scores"].items():
            if status in ("fail", "warn"):
                section_failures[s].append({
                    "idx": r["idx"],
                    "block": r.get("scenario_block"),
                    "label": r.get("label", "")[:60],
                    "status": status,
                    "detail": scored["details"].get(s, ""),
                })

    rollups = cross_row_rollups(rows, ok)

    # Per-section aggregate
    section_counts: dict[str, dict[str, int]] = {}
    for sec_name, _ in PER_ROW_SECTIONS + [("R_personalization", None)]:
        c = Counter()
        for pr in per_row:
            c[pr["scores"].get(sec_name, "skip")] += 1
        section_counts[sec_name] = dict(c)

    report = {
        "csv_path": str(csv_path),
        "total_rows": len(rows),
        "ok_rows": len(ok),
        "err_rows": len(rows) - len(ok),
        "section_counts": section_counts,
        "section_failures_top5": {k: v[:5] for k, v in section_failures.items()},
        "section_failure_totals": {k: len(v) for k, v in section_failures.items()},
        "cross_row": rollups,
    }

    if write_outputs:
        out_dir = csv_path.parent
        # workouts_scored.csv
        scored_path = out_dir / "workouts_scored.csv"
        with scored_path.open("w", newline="") as f:
            base_cols = ["idx", "scenario_block", "label", "http_status", "duration_minutes", "n_exercises", "workout_difficulty"]
            section_cols = [s for s, _ in PER_ROW_SECTIONS] + ["R_personalization"]
            cols = base_cols + section_cols + ["score_total_fail", "score_total_warn", "score_critical_fails"]
            w = csv.writer(f)
            w.writerow(cols)
            pr_by_idx = {pr["idx"]: pr for pr in per_row}
            for r in rows:
                pr = pr_by_idx.get(r["idx"])
                base = [r.get(c, "") for c in base_cols]
                if not pr:
                    w.writerow(base + ["err"] * len(section_cols) + ["", "", ""])
                    continue
                w.writerow(base + [pr["scores"].get(s, "skip") for s in section_cols]
                           + [pr["score_total_fail"], pr["score_total_warn"], pr["score_critical_fails"]])
        # audit_full.json
        (out_dir / "audit_full.json").write_text(json.dumps(report, indent=2, default=str))
        # audit_full_brief.md
        brief_lines = [f"# Audit brief — {csv_path}\n"]
        brief_lines.append(f"- total: {len(rows)}  ok: {len(ok)}  err: {len(rows)-len(ok)}\n")
        brief_lines.append(f"## Error buckets\n")
        for k, v in rollups["error_buckets"].items():
            brief_lines.append(f"- {k}: {v}")
        brief_lines.append("\n## Per-section pass/fail/warn counts\n")
        brief_lines.append("| Section | pass | warn | fail | skip |")
        brief_lines.append("|---|---|---|---|---|")
        for sec, counts in section_counts.items():
            brief_lines.append(f"| {sec} | {counts.get('pass', 0)} | {counts.get('warn', 0)} | {counts.get('fail', 0)} | {counts.get('skip', 0)} |")
        brief_lines.append("\n## Top-5 failing rows per section\n")
        for sec, fails in section_failures.items():
            if not fails:
                continue
            brief_lines.append(f"### {sec} ({len(fails)} flagged)")
            for f in fails[:5]:
                brief_lines.append(f"- idx={f['idx']} blk={f['block']} `{f['label']}` → {f['status']}: {f['detail']}")
            brief_lines.append("")
        (out_dir / "audit_full_brief.md").write_text("\n".join(brief_lines))

    return report


def audit_single_payload(payload_path: Path) -> dict:
    """Score one captured curl response — used in Phase-3 verification."""
    payload = json.loads(payload_path.read_text())
    # Synthesize a CSV-shaped row from the payload
    workout = payload.get("workout") or payload
    exercises = workout.get("exercises") or workout.get("exercises_json") or []
    request_body = payload.get("request_body") or {}
    row = {
        "idx": "single",
        "scenario_block": "single",
        "label": "single-payload",
        "http_status": "200",
        "latency_ms": str(payload.get("latency_ms", 0)),
        "request_body_json": json.dumps(request_body),
        "sse_event_count": str(payload.get("sse_event_count", 99)),
        "workout_id": workout.get("id", "single"),
        "workout_name": workout.get("name", ""),
        "workout_type": workout.get("type", ""),
        "workout_difficulty": workout.get("difficulty", ""),
        "workout_notes": workout.get("notes", ""),
        "n_exercises": str(len(exercises)),
        "exercise_names_pipe": "|".join(e.get("name", "") for e in exercises),
        "per_exercise_sets": "|".join(str(e.get("sets", "")) for e in exercises),
        "per_exercise_reps": "|".join(str(e.get("reps", "")) for e in exercises),
        "per_exercise_weight_kg": "|".join(str(e.get("weight_kg", "") or "") for e in exercises),
        "per_exercise_rest_seconds": "|".join(str(e.get("rest_seconds", "")) for e in exercises),
        "per_exercise_muscle_group": "|".join(e.get("muscle_group", "") or "" for e in exercises),
        "duration_minutes": str(workout.get("duration_minutes", 0)),
        "total_volume_kg": "0",
        "error_message": "",
    }
    scored = score_one_row(row, set())
    return {"row": {k: row[k] for k in ("idx", "workout_name", "workout_type", "workout_difficulty", "n_exercises", "duration_minutes")},
            "scored": scored}


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("csv", type=Path, nargs="?")
    p.add_argument("--single-payload", type=Path,
                   help="Score one captured curl response JSON instead of a CSV")
    p.add_argument("--json", action="store_true", help="emit JSON only")
    args = p.parse_args()

    if args.single_payload:
        rep = audit_single_payload(args.single_payload)
        print(json.dumps(rep, indent=2, default=str))
        scored = rep["scored"]
        return 1 if scored["score_critical_fails"] > 0 else 0

    if not args.csv or not args.csv.exists():
        print("ERROR: provide a CSV path or --single-payload", file=sys.stderr)
        return 2
    rep = audit_csv(args.csv)
    if args.json:
        print(json.dumps(rep, indent=2, default=str))
        return 0
    # Pretty banner.
    print(f"=== Audit: {args.csv} ===\n")
    print(f"Total rows: {rep['total_rows']} (ok={rep['ok_rows']} err={rep['err_rows']})\n")
    print("Section pass/warn/fail/skip:")
    print(f"  {'section':22s} {'pass':>6s} {'warn':>6s} {'fail':>6s} {'skip':>6s}")
    for sec, counts in rep["section_counts"].items():
        print(f"  {sec:22s} {counts.get('pass',0):>6d} {counts.get('warn',0):>6d} {counts.get('fail',0):>6d} {counts.get('skip',0):>6d}")
    print("\nCross-row rollups:")
    for k, v in rep["cross_row"].items():
        if isinstance(v, dict) and "status" in v:
            badge = {"PASS": "✅", "WARN": "⚠️ ", "FAIL": "❌"}.get(v["status"], "  ")
            small = {kk: vv for kk, vv in v.items() if kk != "samples" and not isinstance(vv, list) or kk == "by_block"}
            print(f"  {badge} {k}: {v['status']}  {json.dumps(small, default=str)[:200]}")
        else:
            print(f"     {k}: {v}")
    fails = sum(c.get("fail", 0) for c in rep["section_counts"].values())
    print(f"\nTotal per-row fails across all sections: {fails}")
    return 0 if fails == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
