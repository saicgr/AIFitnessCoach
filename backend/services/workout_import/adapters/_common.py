"""Shared helpers used by every strength adapter.

The intent is that per-app adapter files stay focused on their specific CSV
quirks (column names, packed encodings) and delegate all the universal
edge-case handling — unit conversion, date parsing, rep encoding — to this
module.

Every function here is pure + defensive — no I/O, no exceptions for expected
bad-data cases (return None + caller decides). The adapters themselves decide
whether a malformed row is "skip silently" or "warn + skip".
"""
from __future__ import annotations

import csv
import io
import re
from datetime import datetime, timezone as _tz
from typing import Iterable, List, Optional, Tuple

from ..canonical import (
    WeightUnit,
    convert_to_kg,
    parse_eu_decimal,
)


# ─────── encoding / delimiter sniff ───────

def decode_bytes(data: bytes) -> str:
    """Best-effort text decode. Tries UTF-8-SIG first (strips BOM), then
    chardet for anything weirder (UTF-16 BOMless, Windows-1252, Latin-1).

    Edge cases covered: #68 (UTF-8 BOM / UTF-16 / Windows-1252).
    """
    if not data:
        return ""
    # Quick BOM checks first — unambiguous.
    if data.startswith(b"\xff\xfe") or data.startswith(b"\xfe\xff"):
        try:
            return data.decode("utf-16")
        except Exception:
            pass
    try:
        return data.decode("utf-8-sig")
    except UnicodeDecodeError:
        pass
    try:
        import chardet  # optional dep per requirements.txt
        guess = chardet.detect(data[:50_000])
        enc = (guess.get("encoding") or "latin-1") if guess else "latin-1"
        return data.decode(enc, errors="replace")
    except ImportError:
        return data.decode("latin-1", errors="replace")


def sniff_dialect(sample: str) -> csv.Dialect:
    """Sniff separator (`,` vs `;` vs tab vs pipe) — edge case #69."""
    try:
        return csv.Sniffer().sniff(sample[:4096], delimiters=",;\t|")
    except csv.Error:
        class _Default(csv.excel):
            delimiter = ","
        return _Default()


def iter_csv_rows(data: bytes) -> Iterable[dict]:
    """Decode + dialect-sniff + yield rows as dicts (stripped values).

    Strips leading apostrophes (Excel "keep as text" marker, edge #71),
    trims whitespace (edge #70), normalizes `#REF!`/`#DIV/0!`/`#N/A` to empty
    string (edge #67).
    """
    text = decode_bytes(data)
    if not text.strip():
        return
    dialect = sniff_dialect(text)
    reader = csv.DictReader(io.StringIO(text), dialect=dialect)
    _bad_cells = {"#REF!", "#DIV/0!", "#N/A", "#VALUE!", "#NUM!", "#NAME?", "#NULL!"}
    for row in reader:
        clean = {}
        for k, v in row.items():
            if k is None:
                continue
            key = k.strip() if isinstance(k, str) else k
            if isinstance(v, str):
                s = v.strip()
                if s.startswith("'"):
                    s = s[1:]
                if s in _bad_cells:
                    s = ""
                clean[key] = s
            else:
                clean[key] = v
        yield clean


def is_header_repeat(row: dict, header_fingerprint: Tuple[str, ...]) -> bool:
    """Some exports insert the header row again mid-file (edge case cluster
    around drop_duplicates header rows). If a row contains its own literal
    column names, treat it as a header repeat and skip."""
    if not row:
        return True
    for col in header_fingerprint:
        raw = str(row.get(col, "")).strip()
        # Case-insensitive equality to the column name itself.
        if raw.lower() == col.lower():
            return True
    return False


# ─────── date / time ───────

def parse_datetime(raw: Optional[str], tz_hint: str) -> Optional[datetime]:
    """Parse any of the wildly-inconsistent date formats across export apps
    into a tz-aware datetime. Uses ``dateparser`` when available for locale +
    relative handling; falls back to a small hand-written ladder otherwise.

    Edge cases covered: #33-#42 (text "Day 1" markers → None, US/EU ambiguity,
    Hevy "28 Mar 2025, 17:29", Strong "2025-03-28 17:29:00", Fitbod with tz,
    epoch auto-detect, year-less dates → current year if ≤ today else prior).
    """
    if raw is None:
        return None
    s = str(raw).strip()
    if not s:
        return None
    # Text-only markers like "Day 1" / "Week 2 Day 3" / "D3" are templates.
    if re.match(r"^(day|week|d\d|w\d)\b", s.lower()):
        return None
    # Unix epoch (seconds or milliseconds).
    if re.fullmatch(r"\d{10}", s):
        return datetime.fromtimestamp(int(s), tz=_tz.utc)
    if re.fullmatch(r"\d{13}", s):
        return datetime.fromtimestamp(int(s) / 1000, tz=_tz.utc)

    try:
        import dateparser  # optional dep per requirements.txt
    except ImportError:
        return _parse_datetime_fallback(s, tz_hint)

    settings = {
        "TIMEZONE": tz_hint or "UTC",
        "RETURN_AS_TIMEZONE_AWARE": True,
        "PREFER_DAY_OF_MONTH": "first",
    }
    parsed = dateparser.parse(s, settings=settings)
    if parsed is None:
        return _parse_datetime_fallback(s, tz_hint)

    # Year-less date interpretation (edge case #41).
    if not re.search(r"\d{4}", s):
        today = datetime.now(parsed.tzinfo)
        if parsed.date() > today.date():
            try:
                parsed = parsed.replace(year=parsed.year - 1)
            except ValueError:
                pass  # e.g. Feb 29 rollback
    return parsed


def _parse_datetime_fallback(s: str, tz_hint: str) -> Optional[datetime]:
    """Last-ditch parser when dateparser is unavailable — covers Strong /
    Fitbod / FitNotes formats."""
    fmts = [
        "%Y-%m-%d %H:%M:%S",
        "%Y-%m-%d %H:%M:%S%z",
        "%Y-%m-%d %H:%M:%S %z",           # Fitbod "... +0000"
        "%Y-%m-%dT%H:%M:%S",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%S %z",
        "%Y-%m-%d %H:%M",
        "%Y-%m-%d",
        "%d %b %Y, %H:%M",                 # Hevy "28 Mar 2025, 17:29"
        "%d %b %Y %H:%M",
        "%b %d, %Y",
        "%m/%d/%Y",
        "%m/%d/%Y %H:%M",
        "%d/%m/%Y",
    ]
    try:
        from zoneinfo import ZoneInfo
        tz = ZoneInfo(tz_hint) if tz_hint else _tz.utc
    except Exception:
        tz = _tz.utc
    for fmt in fmts:
        try:
            dt = datetime.strptime(s, fmt)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=tz)
            return dt
        except ValueError:
            continue
    return None


# ─────── weight ───────

_BW_RE = re.compile(r"^\s*bw\s*([+-]\s*\d+(?:[.,]\d+)?)?\s*(kg|lb|lbs)?\s*$",
                    re.IGNORECASE)
_STONE_RE = re.compile(r"^\s*(\d+)\s*st\s*(\d+(?:[.,]\d+)?)?\s*(?:lb|lbs)?\s*$",
                       re.IGNORECASE)


def parse_weight_cell(
    raw: Optional[str],
    *,
    default_unit: WeightUnit,
) -> Tuple[Optional[float], Optional[WeightUnit]]:
    """Return (value, detected_unit). Handles:

    - Plain numerics with EU comma decimal (edge #7)
    - "BW", "BW+25", "BW-20" → bodyweight ± delta (edge #13)
    - "14st 3lb" UK stones (edge #8)
    - Negative values for assistance (edge #12) — kept as-is
    - Trailing "kg"/"lb"/"lbs" unit (edges #1-#5)
    - Empty / "0" → (0.0, default_unit) — bodyweight with weight=0 is real
      data (edge #11), so we never filter on `weight > 0`.
    """
    if raw is None:
        return None, None
    s = str(raw).strip()
    if not s:
        return None, None

    # Bodyweight notation.
    m = _BW_RE.match(s)
    if m:
        delta_raw = (m.group(1) or "").replace(" ", "")
        unit_str = (m.group(2) or "").lower()
        unit = WeightUnit.LB if unit_str in ("lb", "lbs") else WeightUnit.KG if unit_str == "kg" else default_unit
        if not delta_raw:
            return 0.0, unit
        delta = parse_eu_decimal(delta_raw)
        return (delta or 0.0), unit

    # Stones.
    m = _STONE_RE.match(s)
    if m:
        stones = float(m.group(1))
        pounds = float((m.group(2) or "0").replace(",", "."))
        # Convert to kg: stones → kg directly, pounds → kg.
        kg = stones * 6.35029318 + pounds * 0.45359237
        return kg, WeightUnit.KG

    # Extract unit suffix if present.
    lower = s.lower()
    unit: Optional[WeightUnit] = None
    if lower.endswith("kg"):
        unit = WeightUnit.KG
        s = s[:-2].strip()
    elif lower.endswith("lbs"):
        unit = WeightUnit.LB
        s = s[:-3].strip()
    elif lower.endswith("lb"):
        unit = WeightUnit.LB
        s = s[:-2].strip()

    value = parse_eu_decimal(s)
    if value is None:
        return None, None
    return value, (unit or default_unit)


def to_kg(value: Optional[float], unit: Optional[WeightUnit]) -> Optional[float]:
    """Thin wrapper around canonical.convert_to_kg — keeps call sites short."""
    return convert_to_kg(value, unit)


# ─────── reps ───────

# AMRAP markers we recognize anywhere in the rep cell.
_AMRAP_PATTERNS = re.compile(
    r"\b(amrap|max|tf|to\s*failure)\b", re.IGNORECASE,
)


def parse_reps_cell(raw: Optional[str]) -> Tuple[Optional[int], bool, bool]:
    """Return ``(reps, is_amrap, to_failure)``.

    Edge cases:
      #14 rep ranges "8-12" → take the upper bound, both flags False
      #15 AMRAP markers "5+", "x5+", "AMRAP", "MAX", "TF" → is_amrap=True
      #17 rest-pause "12+4+3" → sum (19), flags False
      #20 failure marker "135×8 F" → strip + to_failure=True
      #22 zero reps → None (caller skips)
      #23 spelled-out reps ("eight") → None (caller warns)
    """
    if raw is None:
        return None, False, False
    s = str(raw).strip()
    if not s:
        return None, False, False

    amrap = bool(_AMRAP_PATTERNS.search(s))
    to_failure = False
    # Strip a trailing lone "F" marker (not "F" inside a number like "12F").
    if re.search(r"\bF\b|\bf\b", s) and not re.search(r"\d+f\b", s.lower()):
        to_failure = True
        s = re.sub(r"\bF\b|\bf\b", "", s).strip()

    # "5+" / "x5+" — AMRAP notation, preserve the scalar rep count.
    plus_match = re.match(r"^x?\s*(\d+)\s*\+\s*$", s)
    if plus_match:
        return int(plus_match.group(1)), True, to_failure

    # Rest-pause chain "12+4+3" — sum components (edge #17).
    if "+" in s and not amrap:
        parts = [p.strip() for p in s.split("+") if p.strip()]
        if all(re.fullmatch(r"\d+", p) for p in parts):
            return sum(int(p) for p in parts), False, to_failure

    # Range "8-12" — take upper bound (edge #14).
    range_match = re.match(r"^(\d+)\s*[-–]\s*(\d+)$", s)
    if range_match:
        return int(range_match.group(2)), amrap, to_failure

    # Drop-set chain "100x8 > 80x8" — exploded upstream via split_dropset_chain.
    if ">" in s:
        return None, amrap, to_failure

    # Pure integer (optionally with trailing noise after whitespace).
    m = re.match(r"^(\d+)", s)
    if m:
        return int(m.group(1)), amrap, to_failure

    return None, amrap, to_failure


def split_dropset_chain(raw: str) -> List[Tuple[str, str]]:
    """Explode a drop-set chain "100x8 > 80x8 > 60x8" into individual
    (weight, reps) tuples (edge case #16).

    Returns [] for a non-chain string so the caller can fall through to
    regular parsing.
    """
    if ">" not in raw:
        return []
    parts = [p.strip() for p in re.split(r"[>]+", raw) if p.strip()]
    out: List[Tuple[str, str]] = []
    for part in parts:
        m = re.match(r"^(-?\d+(?:[.,]\d+)?)\s*[x×]\s*(\d+(?:\+)?)\s*$", part, re.IGNORECASE)
        if m:
            out.append((m.group(1), m.group(2)))
        else:
            return []  # non-uniform → bail
    return out


# ─────── RPE / RIR ───────

def parse_rpe(raw: Optional[str]) -> Optional[float]:
    """Parse RPE in any of the forms: 'RPE 8', '@8', '8/10', '8'.
    Returns None for blank / 0 / textual (edge #94)."""
    if raw is None:
        return None
    s = str(raw).strip().lower()
    if not s:
        return None
    s = s.replace("rpe", "").replace("@", "").strip()
    if "/" in s:
        s = s.split("/")[0]
    try:
        val = float(s.replace(",", "."))
    except ValueError:
        return None
    if val <= 0:
        return None
    # Clamp to 10 (edge #93: some users log 11/10).
    return min(val, 10.0)


def parse_rir(raw: Optional[str]) -> Optional[int]:
    if raw is None:
        return None
    s = str(raw).strip()
    if not s:
        return None
    try:
        val = int(float(s.replace(",", ".")))
    except ValueError:
        return None
    # Clamp negative (edge #95) and absurdly high.
    return max(0, min(val, 10))
