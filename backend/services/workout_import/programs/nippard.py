"""
Jeff Nippard paid programs — Fundamentals Hypertrophy, Powerbuilding v3,
Pure Bodybuilding, Upper/Lower, PPL, Essentials.

All share the same XLSX layout:

  * One tab per training split ("Full Body 1: Squat, OHP", "Upper A", "Push A")
  * All weeks are stacked vertically inside each tab — Week 1 block, then
    Week 2 block, etc.
  * Red input cell near the top where the user types literal "kg" or "lbs"
    (NOT a dropdown).
  * Four cells below it for 1RM: Squat / Bench / Deadlift / OHP.
  * Copyright header row ("© Jeff Nippard", URL) sits on row 1 of every tab.
  * Columns (verbatim):
      Exercise | Warm-up Sets | Working Sets | Reps | Load | %1RM | RPE | Rest
      | Notes | Weight Used | Reps Achieved
  * "Weight Used" + "Reps Achieved" are the only user-fill columns — when
    both are populated we emit filled history alongside the template.

Quirks handled here:

  * Merged "WEEK N" banner cells (we resolve via openpyxl merged_cells.ranges).
  * Protected formula cells — openpyxl reads them fine when data_only=True.
  * Rep-range encoding ("8-12", "3-5", "AMRAP").
  * Load-range encoding ("75-80%", "~80%").
  * RPE-range encoding ("7.5", "7-8").
  * Hyperlinked exercise names — we strip hyperlinks, keep the label.
  * Abbreviated names ("BB Row", "DB Row") — passed raw; the ExerciseResolver
    canonicalizes them downstream, so we do NOT try to expand them here.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, List, Optional, Tuple
from uuid import UUID

from core.logger import get_logger

from ..canonical import (
    CanonicalProgramTemplate,
    ImportMode,
    ParseResult,
    PrescribedDay,
    PrescribedExercise,
    PrescribedSet,
    PrescribedWeek,
    SetType,
    WeightUnit,
)
from . import _shared as S

logger = get_logger(__name__)


# Canonical column labels on Nippard sheets (normalized lowercase).
_COL_EXERCISE = ("exercise",)
_COL_WARMUP_SETS = ("warm-up sets", "warmup sets", "warm up sets")
_COL_WORKING_SETS = ("working sets", "sets")
_COL_REPS = ("reps", "rep", "rep range")
_COL_LOAD = ("load",)
_COL_PCT = ("%1rm", "%1 rm", "% 1rm", "% of 1rm")
_COL_RPE = ("rpe",)
_COL_REST = ("rest",)
_COL_NOTES = ("notes", "coaching cues", "cues")
_COL_WEIGHT_USED = ("weight used", "actual weight")
_COL_REPS_ACHIEVED = ("reps achieved", "actual reps", "reps done")


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: ImportMode,
) -> ParseResult:
    try:
        wb = S.load_workbook_from_bytes(data)
    except Exception as e:
        logger.error(f"❌ [nippard] openpyxl open failed: {e}", exc_info=True)
        return S.empty_parse_result("nippard", warnings=[f"could not open workbook: {e}"])

    # 1. Resolve the unit cell and 1RM inputs. Nippard places them near the
    # top of the first training-split tab; we scan the first ~20 rows of every
    # sheet for the labels.
    unit = S.normalize_unit_hint(unit_hint)
    one_rm_inputs: dict[str, float] = {}
    for ws in wb.worksheets:
        scanned = _scan_header_area(ws, unit_hint_default=unit)
        if scanned is None:
            continue
        unit = scanned.unit
        one_rm_inputs.update(scanned.one_rm_inputs)
        break  # first sheet with a populated header wins — every tab repeats it

    # 2. Walk each training-split tab and extract prescribed weeks.
    program_name = _infer_program_name(filename)
    weeks_by_number: dict[int, PrescribedWeek] = {}
    filled_history: List[Tuple[str, Optional[float], Optional[int], Optional[int], Optional[str]]] = []
    warnings: list[str] = []

    for ws in wb.worksheets:
        # Skip instruction / calc / settings sheets — they don't hold exercises.
        title_lower = ws.title.lower()
        if any(k in title_lower for k in ("instruction", "read me", "readme", "settings", "calc", "1rm")):
            continue
        _parse_split_sheet(
            ws=ws,
            unit=unit,
            weeks_by_number=weeks_by_number,
            filled_history=filled_history,
            warnings=warnings,
        )

    if not weeks_by_number:
        return S.empty_parse_result(
            "nippard",
            warnings=warnings + ["no exercise rows found on any tab"],
        )

    weeks = [weeks_by_number[n] for n in sorted(weeks_by_number)]
    days_per_week = max(len(w.days) for w in weeks) if weeks else 0

    template = S.build_template(
        user_id=user_id,
        source_app="nippard",
        program_name=program_name,
        program_creator="Jeff Nippard",
        total_weeks=len(weeks),
        days_per_week=max(days_per_week, 1),
        unit_hint=unit,
        weeks=weeks,
        one_rm_inputs=one_rm_inputs,
        training_max_factor=1.0,
        rounding_multiple_kg=2.5 if unit == WeightUnit.KG else 2.27,  # 5 lb ≈ 2.27 kg
        notes="Imported from Jeff Nippard spreadsheet. %1RM resolves against live 1RM at workout time.",
    )

    strength_rows: list = []
    if filled_history:
        performed_at = datetime.now(tz=timezone.utc)
        strength_rows = S.collect_filled_history_rows(
            user_id=user_id,
            source_app="nippard_history",
            performed_at_fallback=performed_at,
            template=template,
            filled_rows=filled_history,
        )

    mode = (
        ImportMode.PROGRAM_WITH_FILLED_HISTORY if strength_rows else ImportMode.TEMPLATE
    )

    return ParseResult(
        mode=mode,
        source_app="nippard",
        strength_rows=strength_rows,
        template=template,
        warnings=warnings,
        sample_rows_for_preview=_build_preview(template, strength_rows),
    )


# ─────────────────────────── Helpers ───────────────────────────

class _HeaderScan:
    __slots__ = ("unit", "one_rm_inputs")

    def __init__(self, unit: WeightUnit, one_rm_inputs: dict[str, float]):
        self.unit = unit
        self.one_rm_inputs = one_rm_inputs


def _scan_header_area(ws, unit_hint_default: WeightUnit) -> Optional[_HeaderScan]:
    """Look for the unit cell + four 1RM cells (Squat/Bench/DL/OHP) on the
    top ~20 rows. Returns None if nothing matched."""
    found_unit: Optional[WeightUnit] = None
    lifts = {"squat": None, "bench": None, "deadlift": None, "ohp": None}
    label_map = {
        "squat": "squat_kg",
        "back squat": "squat_kg",
        "bench": "bench_kg",
        "bench press": "bench_kg",
        "deadlift": "deadlift_kg",
        "dl": "deadlift_kg",
        "ohp": "ohp_kg",
        "overhead press": "ohp_kg",
        "press": "ohp_kg",
    }

    for row_idx in range(1, 25):
        for col_idx in range(1, 15):
            val = ws.cell(row=row_idx, column=col_idx).value
            if val is None:
                continue
            if isinstance(val, str):
                s = val.strip().lower()
                if s in {"kg", "lbs", "lb", "kilos", "pounds"} and found_unit is None:
                    found_unit = S.normalize_unit_hint(s)
                # Adjacent-cell 1RM: if this cell is a lift label, read the cell
                # immediately to its right.
                for key, slug in label_map.items():
                    if s == key or s.startswith(key + " "):
                        right = ws.cell(row=row_idx, column=col_idx + 1).value
                        w = S.safe_float(right)
                        if w is not None:
                            # Convert to kg using whichever unit we already found
                            u = found_unit or unit_hint_default
                            w_kg = w if u == WeightUnit.KG else w * 0.45359237
                            lifts[key.split()[0] if " " in key else key] = w_kg

    out_1rms = {}
    for k, v in lifts.items():
        if v is not None:
            out_1rms[label_map.get(k, f"{k}_kg")] = v
    if not out_1rms and found_unit is None:
        return None
    return _HeaderScan(unit=found_unit or unit_hint_default, one_rm_inputs=out_1rms)


def _infer_program_name(filename: str) -> str:
    s = filename.lower()
    if "powerbuilding" in s:
        return "Powerbuilding System"
    if "fundamentals" in s:
        return "Fundamentals Hypertrophy"
    if "pure" in s and "bodybuilding" in s:
        return "Pure Bodybuilding"
    if "upper" in s and "lower" in s:
        return "Upper/Lower"
    if "ppl" in s or "push pull legs" in s:
        return "Push/Pull/Legs"
    if "essentials" in s:
        return "Essentials"
    return "Jeff Nippard Program"


def _find_column_indexes(header_row: list) -> dict[str, int]:
    """Map canonical column-name keys → column index (0-based)."""
    idx: dict[str, int] = {}
    for i, cell in enumerate(header_row):
        if cell is None:
            continue
        s = str(cell).strip().lower()
        for key, aliases in {
            "exercise": _COL_EXERCISE,
            "warmup_sets": _COL_WARMUP_SETS,
            "working_sets": _COL_WORKING_SETS,
            "reps": _COL_REPS,
            "load": _COL_LOAD,
            "pct": _COL_PCT,
            "rpe": _COL_RPE,
            "rest": _COL_REST,
            "notes": _COL_NOTES,
            "weight_used": _COL_WEIGHT_USED,
            "reps_achieved": _COL_REPS_ACHIEVED,
        }.items():
            if any(s == a for a in aliases):
                idx[key] = i
                break
    return idx


def _parse_split_sheet(
    *,
    ws,
    unit: WeightUnit,
    weeks_by_number: dict[int, PrescribedWeek],
    filled_history: list,
    warnings: list[str],
) -> None:
    """Walk a single split tab, extracting one PrescribedDay per split + week."""
    rows = list(ws.iter_rows(values_only=False))
    if not rows:
        return

    # Locate the header row — first row containing "Exercise".
    header_idx: Optional[int] = None
    for i, row in enumerate(rows):
        values = [str(c.value).strip().lower() if c.value is not None else "" for c in row]
        if "exercise" in values:
            header_idx = i
            break
    if header_idx is None:
        return

    header_row = [c.value for c in rows[header_idx]]
    col_idx = _find_column_indexes(header_row)
    if "exercise" not in col_idx:
        return

    current_week = 1
    day_exercises: list[PrescribedExercise] = []
    day_label = ws.title

    # Resolve merged "WEEK N" banners using merged ranges on this sheet.
    merged_lookup: dict[int, int] = {}     # row → week number when row is inside a WEEK banner
    for mr in ws.merged_cells.ranges:
        anchor = ws.cell(row=mr.min_row, column=mr.min_col).value
        if isinstance(anchor, str):
            m = S._RE_REP_SINGLE.search(anchor) if False else None  # no-op
            import re
            mw = re.search(r"week\s*(\d+)", anchor, re.IGNORECASE)
            if mw:
                for r in range(mr.min_row, mr.max_row + 1):
                    merged_lookup[r] = int(mw.group(1))

    order_counter = 0

    def flush_day():
        nonlocal day_exercises, order_counter
        if not day_exercises:
            return
        week = weeks_by_number.setdefault(
            current_week,
            PrescribedWeek(week_number=current_week, days=[]),
        )
        day_number = len(week.days) + 1
        week.days.append(
            PrescribedDay(
                day_number=day_number,
                day_label=day_label,
                exercises=day_exercises,
            )
        )
        day_exercises = []
        order_counter = 0

    for row in rows[header_idx + 1 :]:
        row_number = row[0].row if row else 0
        values = [c.value for c in row]

        # WEEK banner row (merged or plain) advances the current_week pointer
        # and flushes the in-progress day to the previous week.
        if row_number in merged_lookup:
            new_week = merged_lookup[row_number]
            if new_week != current_week and day_exercises:
                flush_day()
            current_week = new_week
            continue
        for v in values:
            if isinstance(v, str):
                import re
                mw = re.search(r"^\s*week\s*(\d+)\s*$", v, re.IGNORECASE)
                if mw:
                    new_week = int(mw.group(1))
                    if new_week != current_week and day_exercises:
                        flush_day()
                    current_week = new_week
                    break

        exercise_raw = values[col_idx["exercise"]] if col_idx.get("exercise") is not None else None
        if exercise_raw is None or str(exercise_raw).strip() == "":
            continue
        name = _strip_hyperlink(exercise_raw)
        if not name or name.lower() in {"exercise", "rest", "rest day", "off"}:
            continue

        # Working sets count + rep target + load + pct + RPE.
        sets_count = S.safe_int(values[col_idx["working_sets"]]) if "working_sets" in col_idx else None
        sets_count = sets_count or 1

        reps_cell = values[col_idx["reps"]] if "reps" in col_idx else None
        rep_target, amrap_last = S.parse_rep_target(reps_cell)
        rep_target = rep_target or S.RepTarget(min=8, max=12, amrap_last=False)

        pct_cell = values[col_idx["pct"]] if "pct" in col_idx else None
        percent = S.parse_percent(pct_cell)

        rpe_cell = values[col_idx["rpe"]] if "rpe" in col_idx else None
        rpe, _rir = S.parse_rpe_or_rir(rpe_cell)

        notes = values[col_idx["notes"]] if "notes" in col_idx else None

        load_prescription = (
            S.simple_percent_prescription(percent[0], percent[1],
                                          reference=_reference_for(name))
            if percent is not None
            else (S.rpe_prescription(rpe) if rpe is not None else S.unspecified_prescription())
        )

        warmup_count = S.safe_int(values[col_idx["warmup_sets"]]) if "warmup_sets" in col_idx else 0
        warmup_count = warmup_count or 0

        prescribed_sets: list[PrescribedSet] = []
        for i in range(sets_count):
            is_last = i == sets_count - 1
            prescribed_sets.append(
                PrescribedSet(
                    order=i,
                    set_type=SetType.AMRAP if (amrap_last and is_last) else SetType.WORKING,
                    rep_target=rep_target,
                    load_prescription=load_prescription,
                    rpe_target=(S.RepTarget(min=int(rpe), max=int(rpe)) if rpe else None),
                    notes=str(notes) if notes else None,
                )
            )

        day_exercises.append(
            PrescribedExercise(
                order=order_counter,
                exercise_name_raw=name,
                warmup_set_count=warmup_count,
                sets=prescribed_sets,
            )
        )
        order_counter += 1

        # User-filled history: Weight Used + Reps Achieved both populated.
        w_used = values[col_idx["weight_used"]] if "weight_used" in col_idx else None
        r_done = values[col_idx["reps_achieved"]] if "reps_achieved" in col_idx else None
        w_kg = S.parse_weight_cell(w_used, unit)
        reps_done = S.safe_int(r_done)
        if w_kg is not None and reps_done is not None and reps_done > 0:
            filled_history.append(
                (name, w_kg, reps_done, 1, f"{day_label} — Week {current_week}")
            )

    # End of sheet — flush trailing day.
    flush_day()


def _strip_hyperlink(cell_value: Any) -> str:
    """openpyxl surfaces hyperlinks as the display value on the Cell object,
    but when we've already read `cell.value` we only have a scalar. Defensive:
    strip ` ↗` arrows / parenthesized URLs some sheets include."""
    if cell_value is None:
        return ""
    s = str(cell_value).strip()
    # Drop trailing "(https://youtu.be/...)"-style demo URLs.
    import re
    s = re.sub(r"\s*\(https?://[^)]+\)\s*$", "", s)
    s = re.sub(r"\s*↗\s*$", "", s)
    return s


def _reference_for(exercise_name: str) -> Optional[str]:
    """Map an exercise to the 1RM it's prescribed from. Nippard sheets prescribe
    compound lifts from the named lift's 1RM (squat %1RM → user's squat 1RM);
    accessory work is RPE-based (no percent column populated)."""
    s = exercise_name.lower()
    if "squat" in s and "front" not in s and "split" not in s:
        return "back_squat"
    if "bench" in s and "press" in s and "close-grip" not in s:
        return "bench_press"
    if "deadlift" in s and "romanian" not in s and "stiff" not in s:
        return "deadlift"
    if ("overhead press" in s or "ohp" in s or s == "press"
            or "military press" in s):
        return "overhead_press"
    return None


def _build_preview(template: CanonicalProgramTemplate, strength_rows: list) -> list[dict]:
    """Short preview for the UI upload step — first day of first week."""
    out: list[dict] = []
    if template.weeks and template.weeks[0].days:
        d0 = template.weeks[0].days[0]
        for ex in d0.exercises[:8]:
            out.append({
                "exercise_name": ex.exercise_name_raw,
                "sets": len(ex.sets),
                "reps": f"{ex.sets[0].rep_target.min}-{ex.sets[0].rep_target.max}"
                         if ex.sets else "",
                "load": (
                    f"{int(ex.sets[0].load_prescription.value_min * 100)}-"
                    f"{int(ex.sets[0].load_prescription.value_max * 100)}%"
                    if (ex.sets
                        and ex.sets[0].load_prescription.value_min is not None
                        and ex.sets[0].load_prescription.value_max is not None)
                    else ""
                ),
            })
    for r in strength_rows[:3]:
        out.append({
            "history_preview": True,
            "exercise_name": r.exercise_name_raw,
            "weight_kg": r.weight_kg,
            "reps": r.reps,
        })
    return out
