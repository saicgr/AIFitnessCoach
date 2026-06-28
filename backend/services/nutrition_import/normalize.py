"""Normalization helpers for the nutrition importer.

The importer landmines (per plan): vendor exports vary in units (kJ vs kcal,
g vs oz), date/locale formats (MM/DD/YYYY vs DD/MM/YYYY vs ISO, decimal commas),
and column headers. Everything funnels through here so parsers stay declarative.
"""
from __future__ import annotations

import re
from datetime import datetime, time
from typing import Optional

# ── Header normalization ────────────────────────────────────────────────────

def norm_header(raw: str) -> str:
    """Lowercase, strip units/parens/punctuation → canonical token.

    "Carbohydrates (g)" -> "carbohydrates", "Energy (kcal)" -> "energy",
    "Protein (g)" -> "protein".
    """
    s = (raw or "").strip().lower()
    s = re.sub(r"\([^)]*\)", " ", s)        # drop "(g)", "(kcal)", "(mg)"
    s = s.replace("_", " ")
    s = re.sub(r"[^a-z0-9 ]+", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

# Map normalized header -> our canonical field. Aliases cover the three vendors.
HEADER_ALIASES = {
    # date / time
    "date": "date", "day": "date", "time": "time",
    # meal grouping
    "meal": "meal", "group": "meal", "category": "meal",
    # food name
    "food": "name", "food name": "name", "name": "name", "description": "name",
    "note": "note", "notes": "note",
    # energy
    "calories": "calories", "energy": "calories", "kcal": "calories",
    "energy kcal": "calories",
    # macros
    "protein": "protein_g",
    "carbohydrates": "carbs_g", "carbs": "carbs_g", "total carbohydrate": "carbs_g",
    "net carbs": "carbs_g",
    "fat": "fat_g", "total fat": "fat_g", "total lipid": "fat_g",
    "fiber": "fiber_g", "fibre": "fiber_g", "dietary fiber": "fiber_g",
    # common micros (best-effort)
    "sugar": "sugar_g", "sugars": "sugar_g",
    "sodium": "sodium_mg", "saturated fat": "saturated_fat_g",
    "cholesterol": "cholesterol_mg", "potassium": "potassium_mg",
    "calcium": "calcium_mg", "iron": "iron_mg",
    # weight (for include_weight)
    "weight": "weight", "scale weight": "weight", "weight trend": "weight_trend",
    "body weight": "weight",
    "amount": "amount", "quantity": "amount",
}

# Headers we knowingly ignore (so they aren't reported as "unmapped").
IGNORED_HEADERS = {
    "expenditure", "tdee", "target", "primary nutrition targets", "completed",
    "scale weight kg", "weight trend kg",
}


def map_headers(raw_headers: list[str]) -> tuple[dict[int, str], list[str]]:
    """Return (col_index -> canonical_field, unmapped_header_labels)."""
    mapping: dict[int, str] = {}
    unmapped: list[str] = []
    for i, h in enumerate(raw_headers):
        n = norm_header(h)
        field = HEADER_ALIASES.get(n)
        if field:
            mapping[i] = field
        elif n and n not in IGNORED_HEADERS:
            unmapped.append(h.strip())
    return mapping, unmapped


# ── Value normalization ─────────────────────────────────────────────────────

_KJ_PER_KCAL = 4.184


def to_float(raw) -> Optional[float]:
    """Parse a numeric cell tolerant of decimal commas, thousands separators,
    units, and blanks. Returns None when not parseable."""
    if raw is None:
        return None
    if isinstance(raw, (int, float)):
        return float(raw)
    s = str(raw).strip()
    if not s or s.lower() in ("na", "n/a", "-", "—"):
        return None
    s = re.sub(r"[^0-9,.\-]", "", s)          # strip "kcal", "g", spaces
    if not s or s in ("-", ".", ","):
        return None
    # Decimal-comma handling: "1.234,5" (EU) vs "1,234.5" (US) vs "1234,5".
    if "," in s and "." in s:
        if s.rfind(",") > s.rfind("."):       # comma is the decimal sep
            s = s.replace(".", "").replace(",", ".")
        else:                                  # comma is thousands sep
            s = s.replace(",", "")
    elif "," in s:
        # Lone comma: treat as decimal if it looks like "123,45", else thousands.
        if re.match(r"^-?\d{1,3}(,\d{3})+$", s):
            s = s.replace(",", "")
        else:
            s = s.replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return None


def energy_to_kcal(raw, header_token: str) -> Optional[float]:
    """Convert an energy cell to kcal. If the source column is kJ, divide."""
    val = to_float(raw)
    if val is None:
        return None
    if "kj" in header_token or "kilojoule" in header_token:
        return round(val / _KJ_PER_KCAL, 1)
    return val


def grams(raw, unit_hint: str = "") -> Optional[float]:
    """Normalize a mass cell to grams (handles oz)."""
    val = to_float(raw)
    if val is None:
        return None
    if "oz" in unit_hint:
        return round(val * 28.3495, 2)
    return val


# ── Dates ───────────────────────────────────────────────────────────────────

_DATE_FORMATS = (
    "%Y-%m-%d", "%Y/%m/%d", "%m/%d/%Y", "%m/%d/%y",
    "%d/%m/%Y", "%d/%m/%y", "%d.%m.%Y", "%b %d, %Y", "%B %d, %Y",
    "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M:%S",
)


def parse_date(raw: str, prefer_dayfirst: bool = False) -> Optional[datetime.date]:
    """Best-effort date parse. ``prefer_dayfirst`` flips the ambiguous
    MM/DD vs DD/MM order when an export is known to be day-first (EU)."""
    if not raw:
        return None
    s = str(raw).strip()
    s = s.split("T")[0].split(" ")[0] if re.match(r"^\d{4}-\d{2}-\d{2}", s) else s
    fmts = list(_DATE_FORMATS)
    if prefer_dayfirst:
        fmts.sort(key=lambda f: 0 if f.startswith("%d") else 1)
    for fmt in fmts:
        try:
            return datetime.strptime(s, fmt).date()
        except ValueError:
            continue
    return None


def local_noon_iso(d: "datetime.date") -> str:
    """A date-only value lands at LOCAL noon so it stays on the right
    timezone-keyed day after the daily-summary aggregation (which buckets by the
    user's local date). Noon is safe against ±12h tz shifts."""
    return datetime.combine(d, time(12, 0, 0)).isoformat()


# ── Meal type ───────────────────────────────────────────────────────────────

_MEAL_MAP = {
    "breakfast": "breakfast", "brunch": "breakfast", "morning": "breakfast",
    "lunch": "lunch", "noon": "lunch",
    "dinner": "dinner", "supper": "dinner", "evening": "dinner",
    "snack": "snack", "snacks": "snack", "anytime": "snack", "other": "snack",
}


def map_meal(raw: Optional[str]) -> str:
    if not raw:
        return "snack"
    key = str(raw).strip().lower()
    return _MEAL_MAP.get(key, "snack")
