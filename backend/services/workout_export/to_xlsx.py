"""
Emit a multi-sheet .xlsx workbook.

Sheets:
  - Strength   — one row per set, matching CanonicalSetRow fields.
  - Cardio     — one row per session.
  - Templates  — one row per (template, week, day, exercise, set) tuple.
  - Summary    — derived tables: top set / PR per exercise, weekly volume,
                 total workouts, date range.

Uses `pandas.ExcelWriter(engine='openpyxl')` so the formatting survives
the round-trip. Reference file: `backend/services/data_export.py` —
the single-sheet xlsx exporter there is extended here to multi-sheet.
"""
from __future__ import annotations

import io
from collections import defaultdict
from datetime import date, datetime
from typing import Any, Dict, List, Optional
from uuid import UUID

import pandas as pd

from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalProgramTemplate,
    CanonicalSetRow,
)


def _sanitize(v: Any) -> Any:
    if isinstance(v, UUID):
        return str(v)
    if isinstance(v, datetime):
        return v.isoformat()
    if isinstance(v, (dict, list)):
        import json as _json
        return _json.dumps(v, default=str)
    return v


def _df_from_rows(rows: List[Any]) -> pd.DataFrame:
    if not rows:
        return pd.DataFrame()
    dicts = []
    for r in rows:
        d = r.model_dump(mode="json")
        dicts.append({k: _sanitize(v) for k, v in d.items()})
    return pd.DataFrame(dicts)


def _templates_df(templates: List[CanonicalProgramTemplate]) -> pd.DataFrame:
    """Flatten nested templates into a long-format DataFrame."""
    rows: List[Dict[str, Any]] = []
    for t in templates:
        for wk in t.weeks:
            for d in wk.days:
                for ex in d.exercises:
                    for s in ex.sets:
                        rows.append({
                            "program_name": t.program_name,
                            "program_creator": t.program_creator,
                            "week_number": wk.week_number,
                            "week_label": wk.label,
                            "day_number": d.day_number,
                            "day_label": d.day_label,
                            "exercise_name": ex.exercise_name_raw,
                            "superset_id": ex.superset_id,
                            "set_order": s.order,
                            "set_type": s.set_type if isinstance(s.set_type, str) else s.set_type.value,
                            "rep_min": s.rep_target.min,
                            "rep_max": s.rep_target.max,
                            "amrap_last": s.rep_target.amrap_last,
                            "load_kind": s.load_prescription.kind if isinstance(s.load_prescription.kind, str) else s.load_prescription.kind.value,
                            "load_value_min": s.load_prescription.value_min,
                            "load_value_max": s.load_prescription.value_max,
                            "resolved_kg_min": s.load_prescription.resolved_kg_min,
                            "resolved_kg_max": s.load_prescription.resolved_kg_max,
                            "rest_seconds_min": s.rest_seconds_min,
                            "rest_seconds_max": s.rest_seconds_max,
                            "tempo": s.tempo,
                            "notes": s.notes,
                        })
    return pd.DataFrame(rows)


def _summary_df(
    strength_rows: List[CanonicalSetRow],
    cardio_rows: List[CanonicalCardioRow],
) -> pd.DataFrame:
    """Build a one-sheet summary view with the most-asked-for rollups."""
    records: List[Dict[str, Any]] = []

    # ── Top set per exercise (heaviest weight × reps combo) ──────────────
    top_by_ex: Dict[str, Dict[str, Any]] = {}
    for r in strength_rows:
        name = (r.exercise_name_canonical or r.exercise_name_raw or "").strip()
        if not name or r.weight_kg is None or r.reps is None:
            continue
        # Rank by weight_kg primarily, reps as tie-breaker (matches common
        # "top set" definition, not epley-estimated 1RM).
        cur = top_by_ex.get(name)
        candidate = {"weight_kg": r.weight_kg, "reps": r.reps, "date": r.performed_at.date().isoformat()}
        if not cur or (r.weight_kg, r.reps) > (cur["weight_kg"], cur["reps"]):
            top_by_ex[name] = candidate
    for name, top in sorted(top_by_ex.items()):
        records.append({
            "category": "top_set",
            "exercise": name,
            "metric": "weight_kg × reps",
            "value": f"{top['weight_kg']} × {top['reps']}",
            "date": top["date"],
        })

    # ── Weekly volume (kg × reps) ───────────────────────────────────────
    weekly_vol: Dict[str, float] = defaultdict(float)
    for r in strength_rows:
        if r.weight_kg is None or r.reps is None:
            continue
        iso = r.performed_at.isocalendar()
        key = f"{iso[0]}-W{iso[1]:02d}"
        weekly_vol[key] += float(r.weight_kg) * int(r.reps)
    for week_key in sorted(weekly_vol):
        records.append({
            "category": "weekly_volume",
            "exercise": "",
            "metric": "total_kg_x_reps",
            "value": f"{weekly_vol[week_key]:.0f}",
            "date": week_key,
        })

    # ── Cardio totals per activity type ─────────────────────────────────
    cardio_totals: Dict[str, Dict[str, float]] = defaultdict(lambda: {"sessions": 0, "seconds": 0.0, "meters": 0.0})
    for r in cardio_rows:
        bucket = cardio_totals[r.activity_type]
        bucket["sessions"] += 1
        bucket["seconds"] += r.duration_seconds
        bucket["meters"] += (r.distance_m or 0)
    for activity, b in sorted(cardio_totals.items()):
        records.append({
            "category": "cardio_total",
            "exercise": activity,
            "metric": "sessions / hours / km",
            "value": f"{int(b['sessions'])} / {b['seconds']/3600:.1f} / {b['meters']/1000:.1f}",
            "date": "",
        })

    # ── Overall counts ──────────────────────────────────────────────────
    records.append({
        "category": "total",
        "exercise": "",
        "metric": "strength_sets",
        "value": len(strength_rows),
        "date": "",
    })
    records.append({
        "category": "total",
        "exercise": "",
        "metric": "cardio_sessions",
        "value": len(cardio_rows),
        "date": "",
    })
    return pd.DataFrame(records)


def export_xlsx(
    strength_rows: List[CanonicalSetRow],
    cardio_rows: List[CanonicalCardioRow],
    templates: Optional[List[CanonicalProgramTemplate]] = None,
    *,
    include_strength: bool = True,
    include_cardio: bool = True,
    include_templates: bool = False,
) -> bytes:
    output = io.BytesIO()
    with pd.ExcelWriter(output, engine="openpyxl") as writer:
        if include_strength:
            df = _df_from_rows(strength_rows)
            if df.empty:
                df = pd.DataFrame(columns=["performed_at", "exercise_name_canonical", "set_number", "weight_kg", "reps"])
            df.to_excel(writer, sheet_name="Strength", index=False)

        if include_cardio:
            df = _df_from_rows(cardio_rows)
            if df.empty:
                df = pd.DataFrame(columns=["performed_at", "activity_type", "duration_seconds", "distance_m"])
            df.to_excel(writer, sheet_name="Cardio", index=False)

        if include_templates:
            df = _templates_df(templates or [])
            if df.empty:
                df = pd.DataFrame(columns=["program_name", "week_number", "day_number", "exercise_name"])
            df.to_excel(writer, sheet_name="Templates", index=False)

        summary_df = _summary_df(
            strength_rows if include_strength else [],
            cardio_rows if include_cardio else [],
        )
        if summary_df.empty:
            summary_df = pd.DataFrame(columns=["category", "exercise", "metric", "value", "date"])
        summary_df.to_excel(writer, sheet_name="Summary", index=False)

    output.seek(0)
    return output.getvalue()
