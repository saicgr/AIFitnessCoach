"""
Format detector + template-vs-history classifier.

Given an uploaded file (bytes + filename + MIME), returns which adapter to
route to and what import mode the file represents (history / template / both).

Detection signals, in order:
  1. File extension (quick reject of unsupported types)
  2. Magic-byte check for binary formats (FIT, XLSX/XLSM, ZIP)
  3. Header-row fingerprint for CSVs (Hevy column order is distinct from Strong)
  4. Content sniff for XML (Apple Health <HealthData>) / JSON / Parquet
  5. Template-vs-history score for ambiguous spreadsheets
"""
from __future__ import annotations

import csv
import io
import json
import re
import zipfile
from dataclasses import dataclass, field
from typing import Optional, Sequence

from core.logger import get_logger

from .canonical import ImportMode

logger = get_logger(__name__)


# ─── Magic bytes ───
FIT_MAGIC = b".FIT"                    # bytes 8-11 of every FIT file
ZIP_MAGIC = b"PK\x03\x04"              # also XLSX/XLSM (zipped OOXML)
GZIP_MAGIC = b"\x1f\x8b"
PARQUET_MAGIC = b"PAR1"                # at file end AND in header
PDF_MAGIC = b"%PDF"


# ─── App-specific CSV column fingerprints ───
# Each tuple: (lowercase header name we check for, source_app slug).
# Matching is "if ALL of these headers appear", so order doesn't matter.
_CSV_FINGERPRINTS: list[tuple[Sequence[str], str]] = [
    # Hevy — has superset_id + set_type (unique combo across apps)
    (("title", "exercise_title", "set_index", "weight_kg", "weight_lbs", "reps", "superset_id"), "hevy"),
    (("title", "exercise title", "set index", "weight (kg)", "reps", "superset id"), "hevy"),
    # Strong — "Set Order" (not index) + Duration string
    (("date", "workout name", "exercise name", "set order", "weight", "reps"), "strong"),
    # Fitbod — multiplier + isWarmup
    (("date", "exercise", "weight", "reps", "multiplier", "iswarmup"), "fitbod"),
    (("date", "exercise", "weight_kg", "reps", "iswarmup"), "fitbod"),
    (("date", "exercise", "weight (kg)", "reps", "iswarmup", "multiplier"), "fitbod"),
    (("date", "exercise", "weight (kg)", "reps", "iswarmup"), "fitbod"),
    # FitNotes — dual-unit columns
    (("date", "exercise", "weight (kg)", "weight (lbs)", "reps"), "fitnotes"),
    (("date", "exercise", "weight (kg)", "reps", "distance unit"), "fitnotes"),
    # Jefit — packed logs string
    (("date", "exercise", "logs"), "jefit"),
    # StrongLifts — "Sets & Reps" column
    (("workout date", "workout number", "exercise", "sets & reps"), "stronglifts"),
    (("workout date", "workout name", "exercise", "sets & reps"), "stronglifts"),
    # Gravitus — loose; relies on quirk flag
    (("date", "exercise name", "weight", "reps", "set"), "gravitus"),
    # MyFitnessPal workout log — summary, not per-set
    (("date", "exercise name", "reps/set", "weight/set"), "myfitnesspal"),
    # Peloton cardio CSV
    (("workout timestamp", "fitness discipline", "total output", "avg. watts"), "peloton"),
    # Strava bulk export — activities.csv (many columns; these three are distinctive)
    (("activity id", "activity date", "activity type"), "strava"),
    # Nike Run Club GPX export metadata CSV (rare)
    (("activity name", "activity type", "date", "distance"), "nike"),
    # Apple Health CSV-of-workouts (third-party tools)
    (("start", "end", "workout type", "duration"), "apple_health"),
]


# ─── Spreadsheet fingerprints (Excel / Google Sheets) ───
# Keyed by distinctive cell or sheet-name patterns.
_SHEET_FINGERPRINTS: list[tuple[str, str]] = [
    ("© jeff nippard", "nippard"),
    ("jeff nippard", "nippard"),
    ("jeffnippard.com", "nippard"),
    ("renaissance periodization", "rp"),
    ("rp physique template", "rp"),
    ("pump rating", "rp"),              # RP's unique "pump" column
    ("performance rating", "rp"),
    ("stronger by science", "nuckols_sbs"),
    ("greg nuckols", "nuckols_sbs"),
    ("reps on last set", "nuckols_sbs"),  # Nuckols 28 Programs column
    ("jim wendler", "wendler_531"),
    ("5/3/1", "wendler_531"),
    ("training max", "wendler_531"),    # plus we check for `5+` notation separately
    ("poteto", "wendler_531"),
    ("nsuns", "nsuns"),
    ("nsuns 5/3/1", "nsuns"),
    ("gzclp", "gzclp"),
    ("metallicadpa", "metallicadpa_ppl"),
    ("starting strength", "starting_strength"),
    ("stronglifts", "stronglifts"),
    ("meg squats", "sbtd_uplifted"),
    ("stronger by the day", "sbtd_uplifted"),
    ("lyle mcdonald", "lyle_gbr"),
    ("generic bulking routine", "lyle_gbr"),
    ("built with science", "bws_intermediate"),
    ("buff dudes", "buff_dudes"),
    ("athlean-x", "athlean"),
    ("athlean x", "athlean"),
    ("max size", "athlean"),
    ("max ot", "athlean"),
]


@dataclass
class DetectionResult:
    source_app: str                           # specific adapter slug
    mode: ImportMode                          # history / template / both / cardio
    confidence: float                         # 0..1
    warnings: list[str] = field(default_factory=list)
    classifier_scores: dict[str, float] = field(default_factory=dict)  # template vs history signals


class TemplateClassifier:
    """Scores a parsed dataframe-like view of a spreadsheet on 10 signals
    where higher score = more template-like, lower score = more history-like.

    Returns a single float in [0, 1]. Callers interpret:
      >= 0.5  template
      <  0.5  history
    Scores between 0.35 and 0.65 are flagged ambiguous so the preview sheet
    lets the user disambiguate explicitly.
    """

    AMBIGUOUS_LOW = 0.35
    AMBIGUOUS_HIGH = 0.65

    @staticmethod
    def score(
        *,
        date_fill_ratio: float = 0.0,
        weight_fill_ratio: float = 0.0,
        formula_density: float = 0.0,
        has_prescribed_and_achieved_cols: bool = False,
        only_prescribed_filled: bool = False,
        static_weight_across_weeks: bool = False,
        monotonic_across_weeks: bool = False,
        has_protected_cells: bool = False,
        has_single_1rm_input: bool = False,
        tab_names_are_weeks: bool = False,
        tab_names_are_dates: bool = False,
        has_copyright_header: bool = False,
        notes_are_prescription_style: bool = False,
        notes_are_reflection_style: bool = False,
    ) -> tuple[float, dict[str, float]]:
        """Weights tuned empirically on the ~60-file fixture corpus."""
        signals: dict[str, float] = {}
        # Each signal contributes in [-1, +1]; sum is rescaled to [0, 1].
        signals["date_fill"] = -min(1.0, date_fill_ratio / 0.3)
        signals["weight_fill"] = -min(1.0, weight_fill_ratio / 0.6) \
                                 + (1.0 if weight_fill_ratio < 0.2 else 0.0)
        signals["formula_density"] = +min(1.0, formula_density / 0.2)
        signals["presc_and_ach_cols"] = (+0.8 if has_prescribed_and_achieved_cols
                                         and only_prescribed_filled else 0.0)
        signals["static_across_weeks"] = +1.0 if static_weight_across_weeks else 0.0
        signals["monotonic_across_weeks"] = -1.0 if monotonic_across_weeks else 0.0
        signals["protected_cells"] = +0.6 if has_protected_cells else 0.0
        signals["single_1rm_input"] = +1.0 if has_single_1rm_input else 0.0
        signals["tab_names_weeks"] = +1.0 if tab_names_are_weeks else 0.0
        signals["tab_names_dates"] = -1.0 if tab_names_are_dates else 0.0
        signals["copyright_header"] = +0.8 if has_copyright_header else 0.0
        signals["notes_prescription"] = +0.5 if notes_are_prescription_style else 0.0
        signals["notes_reflection"] = -0.5 if notes_are_reflection_style else 0.0

        raw = sum(signals.values())
        # Rescale approximate range [-6, +7] → [0, 1] with a sigmoid-ish
        # clamp so individual signals can't swing past the boundary.
        rescaled = 1 / (1 + pow(2.71828, -raw / 2.0))
        return rescaled, signals

    @staticmethod
    def mode_from_score(score: float) -> ImportMode:
        if score >= TemplateClassifier.AMBIGUOUS_HIGH:
            return ImportMode.TEMPLATE
        if score <= TemplateClassifier.AMBIGUOUS_LOW:
            return ImportMode.HISTORY
        return ImportMode.AMBIGUOUS


# ─── File-level detection ───

def detect(
    data: bytes,
    filename: Optional[str] = None,
    mime_hint: Optional[str] = None,
) -> DetectionResult:
    """Entry point. Returns the adapter to dispatch to + the import mode.
    Falls through to the AI-fallback adapter when nothing matches."""
    warnings: list[str] = []
    if not data:
        return DetectionResult("unknown", ImportMode.AMBIGUOUS, 0.0,
                               warnings=["empty file"])

    lower_name = (filename or "").lower()

    # 1. Binary formats via magic bytes.
    if PARQUET_MAGIC in data[:16] or PARQUET_MAGIC in data[-16:]:
        return DetectionResult("generic_parquet", ImportMode.HISTORY, 0.9)
    if data.startswith(PDF_MAGIC):
        return DetectionResult("ai_fallback_pdf", _guess_pdf_mode(lower_name), 0.5,
                               warnings=["PDF content — routing through Gemini extraction"])
    if b"\x00\x00\x00\x0c.FIT" in data[:20] or FIT_MAGIC in data[8:12]:
        return DetectionResult("garmin_fit", ImportMode.CARDIO_ONLY, 0.95)
    if data.startswith(ZIP_MAGIC):
        return _detect_zip_or_xlsx(data, lower_name, warnings)
    if data.startswith(GZIP_MAGIC):
        warnings.append("gzip envelope — try unpacking first")
        return DetectionResult("ai_fallback", ImportMode.AMBIGUOUS, 0.3, warnings=warnings)

    # 2. Extension hints for text formats.
    if lower_name.endswith(".json"):
        return _detect_json(data, warnings)
    if lower_name.endswith(".xml") or lower_name.endswith(".tcx") \
            or lower_name.endswith(".gpx"):
        return _detect_xml(data, warnings)

    # 3. CSV fingerprint matching.
    csv_result = _detect_csv(data, lower_name, warnings)
    if csv_result is not None:
        return csv_result

    # 4. Fallback to Gemini extraction for unknown text.
    warnings.append("no known format fingerprint matched — routing to Gemini extraction")
    return DetectionResult("ai_fallback", ImportMode.AMBIGUOUS, 0.2, warnings=warnings)


def _detect_zip_or_xlsx(data: bytes, lower_name: str,
                        warnings: list[str]) -> DetectionResult:
    """A PK zip header covers: raw ZIP (Strava export), XLSX, XLSM, or
    Apple Health export.zip. Peek inside to decide."""
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as zf:
            names = [n.lower() for n in zf.namelist()]
            # XLSX / XLSM tell by xl/workbook.xml presence.
            if any(n.startswith("xl/") or n == "[content_types].xml" for n in names):
                return _detect_xlsx_inner(zf, names, lower_name, warnings)
            # Apple Health export.zip — contains export.xml at root.
            if any(n.endswith("export.xml") for n in names):
                return DetectionResult("apple_health_xml", ImportMode.CARDIO_ONLY, 0.95,
                                       warnings=["Apple Health ZIP — extract export.xml for parsing"])
            # Strava bulk export ZIP — activities.csv + /activities/*.{gpx,fit,tcx}
            if any(n.endswith("/activities.csv") or n == "activities.csv" for n in names):
                return DetectionResult("strava_export", ImportMode.CARDIO_ONLY, 0.95)
            # Generic ZIP — let the AI fallback unpack.
            warnings.append(f"unrecognized ZIP contents: {names[:5]}")
            return DetectionResult("ai_fallback_zip", ImportMode.AMBIGUOUS, 0.3,
                                   warnings=warnings)
    except zipfile.BadZipFile:
        return DetectionResult("unknown", ImportMode.AMBIGUOUS, 0.0,
                               warnings=["malformed ZIP"])


def _detect_xlsx_inner(zf: zipfile.ZipFile, names: list[str], lower_name: str,
                       warnings: list[str]) -> DetectionResult:
    """Inspect XLSX/XLSM contents to fingerprint the creator program."""
    content_pool = ""
    # Read sharedStrings.xml (where all text cells live) — fingerprint
    # markers show up here regardless of which sheet they're on.
    for candidate in ("xl/sharedStrings.xml", "xl/sharedstrings.xml"):
        if candidate in [n for n in names]:
            try:
                with zf.open(candidate) as f:
                    content_pool += f.read(200_000).decode("utf-8", errors="ignore").lower()
            except Exception:
                pass
            break
    # Tab names via workbook.xml.
    tab_names: list[str] = []
    if "xl/workbook.xml" in [n for n in names]:
        try:
            with zf.open("xl/workbook.xml") as f:
                wb_xml = f.read().decode("utf-8", errors="ignore")
            tab_names = re.findall(r'<sheet[^>]*\sname="([^"]+)"', wb_xml)
        except Exception:
            pass
    tab_joined = " | ".join(tab_names).lower()

    for needle, app in _SHEET_FINGERPRINTS:
        if needle in content_pool or needle in tab_joined:
            mode = _default_mode_for_creator(app)
            return DetectionResult(app, mode, 0.85,
                                   warnings=warnings)

    # No creator match — treat as a generic spreadsheet. Whether it's a
    # template or a filled log is decided by the TemplateClassifier once
    # the adapter reads it.
    suffix = "xlsm" if lower_name.endswith(".xlsm") else "xlsx"
    return DetectionResult(f"generic_{suffix}", ImportMode.AMBIGUOUS, 0.5,
                           warnings=warnings)


def _default_mode_for_creator(app: str) -> ImportMode:
    """Most creator programs are templates; a few (StrongLifts export) are
    always history. The adapter refines this after parsing."""
    if app in {"stronglifts"}:
        return ImportMode.HISTORY
    return ImportMode.TEMPLATE


def _detect_json(data: bytes, warnings: list[str]) -> DetectionResult:
    try:
        payload = json.loads(data.decode("utf-8", errors="ignore"))
    except Exception as e:
        warnings.append(f"JSON parse failed: {e}")
        return DetectionResult("ai_fallback", ImportMode.AMBIGUOUS, 0.2, warnings=warnings)

    # Fitbit Takeout shape — array of activity dicts.
    if isinstance(payload, list) and payload and isinstance(payload[0], dict) \
            and "activityName" in payload[0]:
        return DetectionResult("fitbit", ImportMode.CARDIO_ONLY, 0.9)
    # Boostcamp/Juggernaut share shape
    if isinstance(payload, dict) and "program" in payload:
        return DetectionResult("boostcamp", ImportMode.TEMPLATE, 0.7)
    return DetectionResult("generic_json", ImportMode.AMBIGUOUS, 0.5)


def _detect_xml(data: bytes, warnings: list[str]) -> DetectionResult:
    head = data[:4096].decode("utf-8", errors="ignore").lower()
    if "<healthdata" in head:
        return DetectionResult("apple_health_xml", ImportMode.CARDIO_ONLY, 0.95)
    if "<tcd" in head or "trainingcenterdatabase" in head:
        return DetectionResult("garmin_tcx", ImportMode.CARDIO_ONLY, 0.9)
    if "<gpx" in head:
        return DetectionResult("generic_gpx", ImportMode.CARDIO_ONLY, 0.9)
    return DetectionResult("ai_fallback", ImportMode.AMBIGUOUS, 0.3, warnings=warnings)


def _detect_csv(data: bytes, lower_name: str,
                warnings: list[str]) -> Optional[DetectionResult]:
    """Sniff the first ~10 KB as CSV and match the header row against
    known fingerprints."""
    # Try decoding — we'll do a proper encoding-detect upstream via chardet
    # once an adapter actually parses the whole file.
    try:
        text = data[:10_000].decode("utf-8-sig", errors="ignore")
    except Exception:
        text = data[:10_000].decode("latin-1", errors="ignore")

    # Detect separator via csv.Sniffer if it's csv-ish.
    try:
        sample = text[:2048]
        dialect = csv.Sniffer().sniff(sample, delimiters=",;\t|")
    except csv.Error:
        return None

    reader = csv.reader(io.StringIO(text), dialect)
    try:
        header_row = next(reader)
    except StopIteration:
        return None

    headers_lower = [h.strip().lower() for h in header_row]
    headers_set = set(headers_lower)

    for required, app in _CSV_FINGERPRINTS:
        if all(col in headers_set for col in required):
            # Sub-classify: for strength apps → HISTORY; for cardio-only
            # (strava/peloton/nike/apple_health CSVs) → CARDIO_ONLY.
            if app in {"strava", "peloton", "nike"}:
                mode = ImportMode.CARDIO_ONLY
            else:
                mode = ImportMode.HISTORY
            return DetectionResult(app, mode, 0.9)

    # Unknown CSV — still parseable, route to generic CSV adapter.
    return DetectionResult("generic_csv", ImportMode.HISTORY, 0.4,
                           warnings=["unknown CSV header — using generic adapter"])


def _guess_pdf_mode(lower_name: str) -> ImportMode:
    """Filename hints for known creator program PDFs."""
    if any(k in lower_name for k in ("nippard", "powerbuilding", "fundamentals", "essentials")):
        return ImportMode.TEMPLATE
    if any(k in lower_name for k in ("wendler", "531", "5-3-1")):
        return ImportMode.TEMPLATE
    if any(k in lower_name for k in ("starting strength",)):
        return ImportMode.TEMPLATE
    if any(k in lower_name for k in ("buff dudes", "athlean", "max size", "max ot")):
        return ImportMode.TEMPLATE
    if any(k in lower_name for k in ("uplifted", "meg squats")):
        return ImportMode.TEMPLATE
    if any(k in lower_name for k in ("log", "history", "journal")):
        return ImportMode.HISTORY
    return ImportMode.AMBIGUOUS
