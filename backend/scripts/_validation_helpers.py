"""Shared helpers for `validate_workout_generation.py`: sweep matrix,
GenerationResult dataclass, runtime utilities, prompt-capture log handler,
and incremental MD/CSV/summary writers.

Incremental writers (`init_*`, `append_*`) flush a row/section after every
single API call so artifacts on disk grow in real time — useful when the
sweep takes ~5 minutes and the user wants to inspect partial results.
"""
from __future__ import annotations

import csv
import json as _json
import logging
import statistics
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

_log = logging.getLogger("_validation_helpers")

# Domain values (single source of truth — keep aligned with backend defaults)
INTENSITIES = ["easy", "medium", "hard"]
FITNESS_LEVELS = ["beginner", "intermediate", "advanced"]
DURATIONS = [15, 30, 45, 60, 90]
GOALS = ["strength", "hypertrophy", "fat_loss", "endurance",
         "general_fitness", "mobility"]
FOCUSES = ["push", "pull", "legs", "full_body", "core"]

EQUIPMENT_SETS: Dict[str, List[str]] = {
    "full_gym": [
        "barbell", "dumbbells", "cable_machine", "squat_rack", "bench",
        "pull_up_bar", "kettlebell", "leg_press_machine",
        "lat_pulldown", "smith_machine",
    ],
    "home_dumbbells": ["dumbbells", "bench", "resistance_bands"],
    "bodyweight": [],
}
EQUIPMENT_KEYS = list(EQUIPMENT_SETS.keys())

# CSV columns — extended to capture prompt + AI response + per-exercise detail.
CSV_COLS = [
    "idx", "round", "intensity", "fitness_level", "duration_target_min",
    "goal", "equipment_set", "equipment_list", "focus", "injuries",
    "comeback_offset_days",
    "n_input_library_exercises", "input_library_names",
    "n_exercises", "ai_workout_name", "ai_workout_type", "ai_difficulty",
    "ai_notes", "exercise_names_pipe_separated",
    "per_exercise_sets", "per_exercise_reps", "per_exercise_weight_kg",
    "per_exercise_rest_seconds", "per_exercise_muscle_group",
    "est_duration_min", "total_volume_kg",
    "n_safety_violations", "safety_violation_summary", "n_difficulty_scaled",
    "tokens_in", "tokens_out", "generation_path", "error",
    "prompt_char_count", "prompt_text",
]


def _round1() -> List[Dict[str, Any]]:
    """3 × 3 × 5 = 45 rows. Rotate goal/equipment/focus round-robin."""
    out: List[Dict[str, Any]] = []
    i = 0
    for intensity in INTENSITIES:
        for fitness in FITNESS_LEVELS:
            for duration in DURATIONS:
                out.append({
                    "intensity": intensity, "fitness_level": fitness,
                    "duration_minutes": duration,
                    "goal": GOALS[i % len(GOALS)],
                    "equipment_set": EQUIPMENT_KEYS[i % len(EQUIPMENT_KEYS)],
                    "focus": FOCUSES[i % len(FOCUSES)],
                    "injuries": [], "round": 1,
                })
                i += 1
    return out


def _round2() -> List[Dict[str, Any]]:
    """3 × 6 × 3 = 54 rows. Pure equipment-stress sweep."""
    out: List[Dict[str, Any]] = []
    for eq in EQUIPMENT_KEYS:
        for goal in GOALS:
            for focus in ["push", "pull", "legs"]:
                out.append({
                    "intensity": "medium", "fitness_level": "intermediate",
                    "duration_minutes": 45, "goal": goal,
                    "equipment_set": eq, "focus": focus,
                    "injuries": [], "round": 2,
                })
    return out


def _round3_edge() -> List[Dict[str, Any]]:
    """11 hand-crafted edge cases — see plan Round 3."""
    def E(intensity, fl, dur, goal, eq, focus, injuries=(), comeback=None):
        d = {"intensity": intensity, "fitness_level": fl,
             "duration_minutes": dur, "goal": goal,
             "equipment_set": eq, "focus": focus,
             "injuries": list(injuries), "round": 3}
        if comeback:
            d["comeback_offset_days"] = comeback
        return d
    return [
        E("hard", "advanced", 90, "hypertrophy", "full_gym", "full_body"),
        E("easy", "beginner", 15, "strength", "home_dumbbells", "full_body"),
        E("medium", "intermediate", 45, "hypertrophy", "full_gym", "push", ["shoulder"]),
        E("medium", "intermediate", 45, "hypertrophy", "full_gym", "legs", ["knee"]),
        E("medium", "intermediate", 45, "strength", "full_gym", "pull", ["lower_back"]),
        E("easy", "intermediate", 30, "general_fitness", "full_gym", "full_body", comeback=30),
        E("medium", "intermediate", 45, "hypertrophy", "bodyweight", "push"),
        E("easy", "beginner", 30, "mobility", "bodyweight", "full_body"),
        E("hard", "advanced", 90, "endurance", "bodyweight", "full_body"),
        E("easy", "beginner", 30, "endurance", "full_gym", "full_body"),
        E("medium", "intermediate", 60, "strength", "home_dumbbells", "push"),
    ]


def build_sweep_matrix(n: int = 110) -> List[Dict[str, Any]]:
    """Build the deterministic sweep. Cap at `n` rows."""
    out = _round1() + _round2() + _round3_edge()
    return out[:n]


# ---------------------------------------------------------------------------
# Prompt-capture log handler
# ---------------------------------------------------------------------------
class PromptCapture(logging.Handler):
    """Captures the `FULL PROMPT:\\n...` log emitted by the gemini service.

    The gemini path logs the rendered prompt at INFO. We attach this handler
    to the relevant logger, read `latest` after each call, and clear it.
    """

    def __init__(self) -> None:
        super().__init__(level=logging.DEBUG)
        self.latest: Optional[str] = None

    def emit(self, record: logging.LogRecord) -> None:
        try:
            msg = record.getMessage()
        except Exception:
            return
        if "FULL PROMPT:" in msg:
            # Format is "FULL PROMPT:\n<prompt>"
            self.latest = msg.split("FULL PROMPT:", 1)[1].lstrip("\n")

    def consume(self) -> Optional[str]:
        v = self.latest
        self.latest = None
        return v


def install_prompt_capture() -> PromptCapture:
    """Attach a PromptCapture handler to the gemini helpers logger and return it."""
    handler = PromptCapture()
    # Attach to the specific logger that emits the full prompt.
    target = logging.getLogger(
        "services.gemini.workout_generation_helpers_part2"
    )
    # Make sure the logger lets INFO records through to our handler.
    target.setLevel(logging.INFO)
    target.addHandler(handler)
    # Also attach to root in case the logger name differs at runtime.
    logging.getLogger().addHandler(handler)
    return handler


# ---------------------------------------------------------------------------
# Library wrappers / volume math / safety validation
# ---------------------------------------------------------------------------
def select_library_exercises(library_service, focus, equipment, fitness_level, count):
    """Wrap ExerciseLibraryService.get_exercises_for_workout. [] on no match."""
    try:
        return library_service.get_exercises_for_workout(
            focus_area=focus, equipment=equipment, count=count,
            fitness_level=fitness_level,
        )
    except Exception as e:
        _log.warning(f"library lookup failed: {e}")
        return []


def compute_volume_and_duration(exercises: List[Dict[str, Any]]) -> Tuple[float, float]:
    """Approximate (kg-volume, minutes) from sets/reps/weight/rest fields."""
    tv, tm = 0.0, 0.0
    for ex in exercises:
        try:
            sets_i = int(ex.get("sets") or 0)
            reps_raw = ex.get("reps") or 0
            reps_i = int(reps_raw) if str(reps_raw).isdigit() else 10
            weight_f = float(ex.get("weight_kg") or ex.get("weight") or 0)
            rest_f = float(ex.get("rest_seconds") or 60)
        except (TypeError, ValueError):
            continue
        tv += sets_i * reps_i * weight_f
        tm += (sets_i * (reps_i * 3 + rest_f) + 30) / 60.0
    return tv, tm


async def run_safety_validator(
    exercises: List[Dict[str, Any]], user_id: str,
    fitness_level: str, equipment: List[str], injuries: List[str],
) -> Tuple[int, List[str]]:
    """Returns (n_violations, log_lines). Never raises."""
    try:
        from services.workout_safety_validator import (
            UserSafetyContext, validate_and_repair,
        )
    except Exception as e:
        return 0, [f"validator_import_failed: {e}"]
    ctx = UserSafetyContext(
        injuries=injuries or [], difficulty=fitness_level,
        equipment=equipment or [], user_id=user_id,
    )
    try:
        result = await validate_and_repair(exercises, ctx)
        lines = [
            f"violation: {v.exercise_name} — {'; '.join(v.reasons)}"
            for v in result.violations
        ]
        return len(result.violations), lines
    except Exception as e:
        return 0, [f"validator_error: {e}"]


def streaming_subset(matrix: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Pick ~10 streaming workouts: one per (intensity × fitness_level) + 1 edge."""
    seen: set = set()
    picks: List[Dict[str, Any]] = []
    for p in matrix:
        key = (p["intensity"], p["fitness_level"])
        if key not in seen and p.get("round") in (1, 2):
            seen.add(key)
            picks.append(p)
        if len(picks) >= 9:
            break
    for p in matrix:
        if p.get("round") == 3:
            picks.append(p)
            break
    return picks


# ---------------------------------------------------------------------------
# Result dataclass
# ---------------------------------------------------------------------------
@dataclass
class GenerationResult:
    idx: int
    params: Dict[str, Any]
    generation_path: str  # "library" | "streaming"
    exercises: List[Dict[str, Any]] = field(default_factory=list)
    input_library_exercises: List[Dict[str, Any]] = field(default_factory=list)
    ai_workout_name: str = ""
    ai_workout_type: str = ""
    ai_difficulty: str = ""
    ai_notes: str = ""
    prompt_text: str = ""
    n_safety_violations: int = 0
    safety_log_lines: List[str] = field(default_factory=list)
    n_difficulty_scaled: int = 0
    est_duration_min: float = 0.0
    total_volume_kg: float = 0.0
    tokens_in: int = 0
    tokens_out: int = 0
    error: Optional[str] = None


# ---------------------------------------------------------------------------
# Per-exercise detail extractors (for CSV + MD)
# ---------------------------------------------------------------------------
def _ex_sets(ex: Dict[str, Any]) -> str: return str(ex.get("sets", ""))
def _ex_reps(ex: Dict[str, Any]) -> str: return str(ex.get("reps", ""))
def _ex_weight(ex: Dict[str, Any]) -> str:
    return str(ex.get("weight_kg") or ex.get("weight") or "")
def _ex_rest(ex: Dict[str, Any]) -> str: return str(ex.get("rest_seconds", ""))
def _ex_muscle(ex: Dict[str, Any]) -> str:
    m = ex.get("muscle_group") or ex.get("body_part") or ""
    return ",".join(m) if isinstance(m, list) else str(m)
def _ex_name(ex: Dict[str, Any]) -> str:
    return ex.get("name") or ex.get("exercise_name") or ""


def _ex_summary(ex: Dict[str, Any]) -> str:
    """One-line exercise summary for the markdown bullet list."""
    name = _ex_name(ex) or "(unnamed)"
    sets = ex.get("sets", "?")
    reps = ex.get("reps", "?")
    weight = ex.get("weight_kg") or ex.get("weight") or ""
    weight_str = f" @ {weight}kg" if weight not in (None, "", 0) else ""
    rest = ex.get("rest_seconds")
    rest_str = f" rest={rest}s" if rest else ""
    targets = _ex_muscle(ex)
    return f"{name} — {sets}×{reps}{weight_str}{rest_str} — {targets}"


# ---------------------------------------------------------------------------
# Incremental writers
# ---------------------------------------------------------------------------
def init_csv(out_dir: Path) -> Path:
    path = out_dir / "workouts.csv"
    with path.open("w", newline="") as fh:
        csv.writer(fh).writerow(CSV_COLS)
    return path


def append_csv(path: Path, r: GenerationResult) -> None:
    p = r.params
    eq = EQUIPMENT_SETS.get(p.get("equipment_set", ""), [])
    names = "|".join(_ex_name(ex) for ex in r.exercises)
    input_names = "|".join(_ex_name(ex) for ex in r.input_library_exercises)
    sets_col = "|".join(_ex_sets(ex) for ex in r.exercises)
    reps_col = "|".join(_ex_reps(ex) for ex in r.exercises)
    weights_col = "|".join(_ex_weight(ex) for ex in r.exercises)
    rests_col = "|".join(_ex_rest(ex) for ex in r.exercises)
    muscles_col = "|".join(_ex_muscle(ex) for ex in r.exercises)
    safety_summary = " | ".join(r.safety_log_lines[:5])
    row = [
        r.idx, p.get("round"), p.get("intensity"), p.get("fitness_level"),
        p.get("duration_minutes"), p.get("goal"),
        p.get("equipment_set"), ",".join(eq), p.get("focus"),
        ",".join(p.get("injuries") or []),
        p.get("comeback_offset_days") or "",
        len(r.input_library_exercises), input_names,
        len(r.exercises), r.ai_workout_name, r.ai_workout_type, r.ai_difficulty,
        r.ai_notes, names,
        sets_col, reps_col, weights_col, rests_col, muscles_col,
        f"{r.est_duration_min:.1f}", f"{r.total_volume_kg:.1f}",
        r.n_safety_violations, safety_summary, r.n_difficulty_scaled,
        r.tokens_in, r.tokens_out, r.generation_path, r.error or "",
        len(r.prompt_text or ""), r.prompt_text or "",
    ]
    with path.open("a", newline="") as fh:
        csv.writer(fh).writerow(row)


def init_markdown(out_dir: Path) -> Path:
    path = out_dir / "workouts.md"
    path.write_text("# Workout Generation Validation\n\n")
    return path


def append_markdown(path: Path, r: GenerationResult) -> None:
    p = r.params
    eq = EQUIPMENT_SETS.get(p.get("equipment_set", ""), [])
    lines: List[str] = []
    lines.append(
        f"## #{r.idx:03d} — {p.get('intensity')} / {p.get('fitness_level')}"
        f" / {p.get('duration_minutes')}min / {p.get('goal')}"
        f" / {p.get('equipment_set')} / {p.get('focus')} [{r.generation_path}]"
    )
    lines.append("")
    lines.append("### Parameters")
    lines.append(f"- intensity: `{p.get('intensity')}`")
    lines.append(f"- fitness_level: `{p.get('fitness_level')}`")
    lines.append(f"- duration_minutes (target): `{p.get('duration_minutes')}`")
    lines.append(f"- goal: `{p.get('goal')}`")
    lines.append(f"- equipment_set: `{p.get('equipment_set')}` → {eq}")
    lines.append(f"- focus: `{p.get('focus')}`")
    lines.append(f"- injuries: `{p.get('injuries') or []}`")
    if p.get("comeback_offset_days"):
        lines.append(f"- comeback_offset_days: `{p['comeback_offset_days']}`")
    lines.append(f"- round: `{p.get('round')}`")
    lines.append("")

    if r.error:
        lines += [f"### ❌ ERROR\n```\n{r.error}\n```", ""]
    else:
        lines.append("### Library input (pre-filtered exercises sent to Gemini)")
        if r.input_library_exercises:
            for i, ex in enumerate(r.input_library_exercises, 1):
                lines.append(f"  {i}. {_ex_summary(ex)}")
        else:
            lines.append("  (none)")
        lines.append("")

        lines.append("### AI response")
        lines.append(f"- workout_name: **{r.ai_workout_name}**")
        lines.append(f"- type: `{r.ai_workout_type}`  difficulty: `{r.ai_difficulty}`")
        lines.append(f"- notes: {r.ai_notes}")
        lines.append("")

        lines.append("### Final exercises (library + AI metadata)")
        lines.append(
            f"- count: {len(r.exercises)}, est duration: {r.est_duration_min:.1f}m, "
            f"total volume: {r.total_volume_kg:.1f}kg"
        )
        for i, ex in enumerate(r.exercises, 1):
            lines.append(f"  {i}. {_ex_summary(ex)}")
        lines.append("")

        lines.append("### Safety validation")
        lines.append(f"- violations: {r.n_safety_violations}")
        if r.safety_log_lines:
            for ln in r.safety_log_lines:
                lines.append(f"  - {ln}")
        lines.append("")

    if r.prompt_text:
        lines.append("### Prompt sent to Gemini")
        lines.append("```")
        lines.append(r.prompt_text.rstrip())
        lines.append("```")
        lines.append("")

    lines.append(f"- tokens: in={r.tokens_in} out={r.tokens_out}")
    lines.append("")
    lines.append("---")
    lines.append("")

    with path.open("a") as fh:
        fh.write("\n".join(lines))


def append_json(out_dir: Path, r: GenerationResult) -> Path:
    """Per-call JSON dump — full fidelity, easy to diff/review one workout."""
    j_dir = out_dir / "json"
    j_dir.mkdir(exist_ok=True)
    path = j_dir / f"workout_{r.idx:03d}.json"
    payload = {
        "idx": r.idx,
        "generation_path": r.generation_path,
        "params": r.params,
        "ai_workout_name": r.ai_workout_name,
        "ai_workout_type": r.ai_workout_type,
        "ai_difficulty": r.ai_difficulty,
        "ai_notes": r.ai_notes,
        "input_library_exercises": r.input_library_exercises,
        "exercises": r.exercises,
        "n_safety_violations": r.n_safety_violations,
        "safety_log_lines": r.safety_log_lines,
        "n_difficulty_scaled": r.n_difficulty_scaled,
        "est_duration_min": r.est_duration_min,
        "total_volume_kg": r.total_volume_kg,
        "tokens_in": r.tokens_in,
        "tokens_out": r.tokens_out,
        "error": r.error,
        "prompt_text": r.prompt_text,
    }
    path.write_text(_json.dumps(payload, indent=2, default=str))
    return path


def _safe_mean(xs: List[float]) -> float:
    return statistics.fmean(xs) if xs else 0.0


def write_summary(out_dir: Path, results: List[GenerationResult]) -> Path:
    """Aggregate stats — quick eyeball check across the sweep."""
    path = out_dir / "workouts.summary.md"
    total = len(results)
    errored = [r for r in results if r.error]
    ok = [r for r in results if not r.error]
    by_intensity: Dict[str, List[int]] = {}
    by_equipment: Dict[str, List[int]] = {}
    name_counts: Dict[str, int] = {}
    for r in ok:
        by_intensity.setdefault(r.params.get("intensity", "?"), []).append(len(r.exercises))
        by_equipment.setdefault(r.params.get("equipment_set", "?"), []).append(r.n_safety_violations)
        for ex in r.exercises:
            n = _ex_name(ex)
            if n:
                name_counts[n] = name_counts.get(n, 0) + 1
    top = sorted(name_counts.items(), key=lambda kv: -kv[1])[:20]
    total_in = sum(r.tokens_in for r in results)
    total_out = sum(r.tokens_out for r in results)
    pct = f"{len(ok) / total * 100:.1f}%" if total else "0%"
    lines = [
        "# Validation Summary", "",
        f"- Total workouts attempted: {total}",
        f"- Succeeded: {len(ok)} ({pct})",
        f"- Errored: {len(errored)}",
        f"- Total tokens in: {total_in}",
        f"- Total tokens out: {total_out}", "",
        "## Mean exercise count by intensity",
    ]
    lines += [f"- {k}: mean={_safe_mean(v):.2f} (n={len(v)})" for k, v in sorted(by_intensity.items())]
    lines += ["", "## Mean safety violations by equipment_set"]
    lines += [f"- {k}: mean={_safe_mean(v):.2f} (n={len(v)})" for k, v in sorted(by_equipment.items())]
    lines += ["", "## Top 20 most-selected exercises"]
    lines += [f"- {count}× {name}" for name, count in top]
    if errored:
        lines += ["", "## Errors"]
        lines += [f"- #{r.idx:03d} ({r.generation_path}): `{r.error}`" for r in errored]
    path.write_text("\n".join(lines))
    return path
