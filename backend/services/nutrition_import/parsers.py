"""Header-driven, tolerant parsers for nutrition exports.

Sources: myfitnesspal (zip of CSVs or single CSV), macrofactor (daily CSV),
cronometer (servings CSV), apple_health (client-assembled JSON rows). All map by
normalized header name and never assume column position. Unmapped columns are
returned, not dropped, so a wrong mapping is visible in the dry-run preview.
"""
from __future__ import annotations

import csv
import io
import zipfile
from dataclasses import dataclass, field
from datetime import date as date_cls
from typing import Optional

from . import normalize as nz

MICRO_FIELDS = {
    "sugar_g", "sodium_mg", "saturated_fat_g", "cholesterol_mg",
    "potassium_mg", "calcium_mg", "iron_mg",
}


@dataclass
class NormalizedFoodRow:
    date: date_cls
    meal: str
    name: str
    calories: Optional[float]
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None
    fiber_g: Optional[float] = None
    micros: dict = field(default_factory=dict)


@dataclass
class NormalizedWeightRow:
    date: date_cls
    weight_kg: float


@dataclass
class ParseResult:
    source: str
    food_rows: list[NormalizedFoodRow] = field(default_factory=list)
    weight_rows: list[NormalizedWeightRow] = field(default_factory=list)
    unmapped_columns: list[str] = field(default_factory=list)
    unreadable_rows: int = 0
    errors: list[str] = field(default_factory=list)


# ── source detection by header signature ─────────────────────────────────────

def detect_source(headers: list[str]) -> str:
    toks = {nz.norm_header(h) for h in headers}
    if {"group", "food name"} & toks and "amount" in toks:
        return "cronometer"
    if "meal" in toks and ("food" in toks or "note" in toks):
        return "myfitnesspal"
    if "energy" in toks or ("calories" in toks and "weight trend" in toks):
        return "macrofactor"
    if "meal" in toks:
        return "myfitnesspal"
    return "macrofactor"  # safest: daily-totals fallback


def _looks_dayfirst(rows: list[list[str]], date_idx: int) -> bool:
    """Heuristic: if any date's first numeric field exceeds 12, it must be a day
    (DD/MM). If any second field exceeds 12, it's MM/DD."""
    dayfirst_votes = us_votes = 0
    for r in rows[:200]:
        if date_idx >= len(r):
            continue
        m = r[date_idx].strip().replace(".", "/").split("/")
        if len(m) >= 2 and m[0].isdigit() and m[1].isdigit():
            a, b = int(m[0]), int(m[1])
            if a > 12 and b <= 12:
                dayfirst_votes += 1
            elif b > 12 and a <= 12:
                us_votes += 1
    return dayfirst_votes > us_votes


# ── core CSV parser ──────────────────────────────────────────────────────────

def _parse_csv_text(text: str, source: str) -> ParseResult:
    res = ParseResult(source=source)
    # Strip a UTF-8 BOM that MFP/Cronometer exports sometimes carry.
    text = text.lstrip("﻿")
    try:
        dialect = csv.Sniffer().sniff(text[:4096], delimiters=",;\t")
    except csv.Error:
        dialect = csv.excel
    reader = list(csv.reader(io.StringIO(text), dialect))
    if not reader:
        return res
    raw_headers = reader[0]
    body = reader[1:]
    mapping, unmapped = nz.map_headers(raw_headers)
    res.unmapped_columns = unmapped

    # Locate key columns + energy header token (for kJ detection).
    field_to_idx: dict[str, int] = {}
    for idx, fld in mapping.items():
        field_to_idx.setdefault(fld, idx)
    energy_token = ""
    if "calories" in field_to_idx:
        energy_token = nz.norm_header(raw_headers[field_to_idx["calories"]]) + " " + \
            (raw_headers[field_to_idx["calories"]].lower())
    # Weight unit: exports label the column "Weight (lbs)" / "Weight (kg)".
    weight_is_lb = False
    if "weight" in field_to_idx:
        wh = raw_headers[field_to_idx["weight"]].lower()
        weight_is_lb = "lb" in wh or "pound" in wh

    date_idx = field_to_idx.get("date")
    dayfirst = _looks_dayfirst(body, date_idx) if date_idx is not None else False

    for r in body:
        if not any(c.strip() for c in r):
            continue
        cell = lambda fld: (r[field_to_idx[fld]] if fld in field_to_idx and field_to_idx[fld] < len(r) else None)
        d = nz.parse_date(cell("date") or "", prefer_dayfirst=dayfirst) if date_idx is not None else None

        # weight row (independent of food validity)
        w = nz.to_float(cell("weight"))
        if w and d:
            w_kg = round(w * 0.453592, 2) if weight_is_lb else w
            if 20 <= w_kg <= 400:  # plausible-kg guard
                res.weight_rows.append(NormalizedWeightRow(date=d, weight_kg=w_kg))

        cals = nz.energy_to_kcal(cell("calories"), energy_token)
        name = (cell("name") or "").strip()
        protein = nz.to_float(cell("protein_g"))
        carbs = nz.to_float(cell("carbs_g"))
        fat = nz.to_float(cell("fat_g"))

        has_food = (cals is not None and cals > 0) or (name and (protein or carbs or fat))
        if not has_food:
            if d is None and w is None:
                res.unreadable_rows += 1
            continue
        if d is None:
            res.unreadable_rows += 1
            continue

        micros = {}
        for mf in MICRO_FIELDS:
            v = nz.to_float(cell(mf))
            if v is not None:
                micros[mf] = v

        res.food_rows.append(NormalizedFoodRow(
            date=d,
            meal=nz.map_meal(cell("meal")),
            name=name or ("Imported daily total" if source == "macrofactor" else "Imported food"),
            calories=cals,
            protein_g=protein,
            carbs_g=carbs,
            fat_g=fat,
            fiber_g=nz.to_float(cell("fiber_g")),
            micros=micros,
        ))
    return res


# ── MyFitnessPal zip (3-CSV export) ──────────────────────────────────────────

def _parse_mfp_zip(data: bytes) -> ParseResult:
    """Pick the richest nutrition CSV from an MFP export zip. Prefer a detailed
    per-food 'Nutrition' file (has a Food column); fall back to the summary."""
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        names = [n for n in zf.namelist() if n.lower().endswith(".csv")]
        # Prefer a file whose header carries a food-name column.
        best = None
        for n in names:
            head = zf.read(n).decode("utf-8-sig", errors="replace")[:2048]
            toks = {nz.norm_header(h) for h in head.splitlines()[0].split(",")} if head else set()
            if "food" in toks or "name" in toks:
                best = n
                break
        target = best or (
            next((n for n in names if "nutrition" in n.lower()), None) or
            (names[0] if names else None)
        )
        if not target:
            res = ParseResult(source="myfitnesspal")
            res.errors.append("No CSV found in MyFitnessPal zip export")
            return res
        text = zf.read(target).decode("utf-8-sig", errors="replace")
        return _parse_csv_text(text, "myfitnesspal")


# ── Apple Health (client-assembled daily JSON rows) ──────────────────────────

def _parse_apple_health(rows: list[dict]) -> ParseResult:
    """rows: [{date:'YYYY-MM-DD', calories, protein_g, carbs_g, fat_g, weight_kg?}].
    Daily aggregates only (no food names). Client filters out our own writes."""
    res = ParseResult(source="apple_health")
    for row in rows or []:
        d = nz.parse_date(str(row.get("date", "")))
        if d is None:
            res.unreadable_rows += 1
            continue
        if row.get("weight_kg"):
            w = nz.to_float(row["weight_kg"])
            if w:
                res.weight_rows.append(NormalizedWeightRow(date=d, weight_kg=w))
        cals = nz.to_float(row.get("calories"))
        if cals and cals > 0:
            res.food_rows.append(NormalizedFoodRow(
                date=d, meal="snack", name="Apple Health daily total",
                calories=cals,
                protein_g=nz.to_float(row.get("protein_g")),
                carbs_g=nz.to_float(row.get("carbs_g")),
                fat_g=nz.to_float(row.get("fat_g")),
            ))
    return res


# ── public entrypoint ────────────────────────────────────────────────────────

def parse_export(
    *,
    data: Optional[bytes] = None,
    filename: str = "",
    source: str = "auto",
    apple_health_rows: Optional[list[dict]] = None,
) -> ParseResult:
    """Parse an uploaded export (or Apple Health rows) into normalized rows."""
    if source == "apple_health" or apple_health_rows is not None:
        return _parse_apple_health(apple_health_rows or [])

    if data is None:
        res = ParseResult(source=source)
        res.errors.append("No file data provided")
        return res

    if filename.lower().endswith(".zip") or data[:2] == b"PK":
        return _parse_mfp_zip(data)

    text = data.decode("utf-8-sig", errors="replace")
    if source == "auto":
        first = text.lstrip("﻿").splitlines()[0] if text.strip() else ""
        source = detect_source(first.split(","))
    return _parse_csv_text(text, source)
