"""
Canonical data shapes produced by every import adapter.

Every adapter — whether parsing a Hevy CSV, a Jeff Nippard XLSX template, an
Apple Health XML dump, or a Gemini-OCR'd PDF — emits these three shapes so the
rest of the pipeline (exercise resolver, dedup, Supabase writer, RAG indexer)
stays adapter-agnostic.

Hash helpers are deliberately deterministic across Python versions: we round
numeric values before hashing so floating-point drift in the parser doesn't
invalidate a previously-imported row.
"""
from __future__ import annotations

import hashlib
from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


LB_TO_KG = Decimal("0.45359237")
STONE_TO_KG = Decimal("6.35029318")
KM_TO_M = Decimal("1000")
MILE_TO_M = Decimal("1609.344")


class WeightUnit(str, Enum):
    KG = "kg"
    LB = "lb"
    STONE = "stone"


class SetType(str, Enum):
    WORKING = "working"
    WARMUP = "warmup"
    FAILURE = "failure"
    DROPSET = "dropset"
    AMRAP = "amrap"
    CLUSTER = "cluster"
    REST_PAUSE = "rest_pause"
    BACKOFF = "backoff"
    ASSISTANCE = "assistance"


class ImportMode(str, Enum):
    """What the format detector concluded the file contains."""
    HISTORY = "history"                               # filled log (Hevy, Strong, etc.)
    TEMPLATE = "template"                             # blank creator program
    PROGRAM_WITH_FILLED_HISTORY = "program_with_filled_history"  # creator sheet user has been filling in
    CARDIO_ONLY = "cardio_only"                       # Strava / Peloton / Nike
    AMBIGUOUS = "ambiguous"                           # user must disambiguate


class LoadPrescriptionKind(str, Enum):
    PERCENT_1RM = "percent_1rm"
    PERCENT_TM = "percent_tm"              # Wendler: % of Training Max
    ABSOLUTE_KG = "absolute_kg"
    RPE_TARGET = "rpe_target"
    BODYWEIGHT = "bodyweight"
    UNSPECIFIED = "unspecified"


def convert_to_kg(value: Optional[float], unit: Optional[WeightUnit]) -> Optional[float]:
    """Convert any recognized weight to kg. None in → None out."""
    if value is None:
        return None
    if unit is None or unit == WeightUnit.KG:
        return float(value)
    if unit == WeightUnit.LB:
        return float(Decimal(str(value)) * LB_TO_KG)
    if unit == WeightUnit.STONE:
        return float(Decimal(str(value)) * STONE_TO_KG)
    return float(value)


def parse_eu_decimal(raw: str) -> Optional[float]:
    """Handle comma-as-decimal ('22,5') without pulling in a locale library.
    Returns None for blank / non-numeric input.
    """
    if raw is None:
        return None
    s = str(raw).strip().replace(" ", "")
    if not s:
        return None
    # Only treat comma as decimal if it's the LAST separator and no dot follows.
    if "," in s and "." not in s:
        s = s.replace(",", ".")
    # Handle thousand-sep ("1,234.56") — drop commas entirely when a dot also appears.
    elif "," in s and "." in s:
        s = s.replace(",", "")
    try:
        return float(s)
    except ValueError:
        return None


def _round_for_hash(value: Optional[float], ndigits: int = 1) -> str:
    if value is None:
        return ""
    return f"{round(float(value), ndigits):.{ndigits}f}"


class CanonicalSetRow(BaseModel):
    """One logged set — the atomic unit of imported strength history."""
    model_config = ConfigDict(use_enum_values=True)

    user_id: UUID
    performed_at: datetime                   # always TZ-aware, UTC
    workout_name: Optional[str] = None
    exercise_name_raw: str                   # as written in the source file
    exercise_name_canonical: Optional[str] = None  # filled by resolver, may match raw
    exercise_id: Optional[UUID] = None       # filled by resolver when confident
    set_number: Optional[int] = Field(default=None, ge=0, le=99)
    set_type: SetType = SetType.WORKING
    weight_kg: Optional[float] = None        # always converted; None for bodyweight-only
    original_weight_value: Optional[float] = None
    original_weight_unit: Optional[WeightUnit] = None
    reps: Optional[int] = Field(default=None, ge=0, le=999)
    duration_seconds: Optional[int] = Field(default=None, ge=0)
    distance_m: Optional[float] = Field(default=None, ge=0)
    rpe: Optional[float] = Field(default=None, ge=0.0, le=10.0)
    rir: Optional[int] = Field(default=None, ge=0, le=10)
    superset_id: Optional[str] = None
    notes: Optional[str] = None
    source_app: str
    source_row_hash: str

    @field_validator("performed_at")
    @classmethod
    def require_tz_aware(cls, v: datetime) -> datetime:
        if v.tzinfo is None:
            # Adapters must attach a timezone before handing the row off.
            # This fail-fast is intentional — silent "naive → UTC" casts are
            # the single biggest class of import bug.
            raise ValueError("performed_at must be timezone-aware")
        return v

    @staticmethod
    def compute_row_hash(
        *,
        user_id: UUID,
        source_app: str,
        performed_at: datetime,
        exercise_name_canonical: str,
        set_number: Optional[int],
        weight_kg: Optional[float],
        reps: Optional[int],
    ) -> str:
        """Stable dedup hash. Bucketed to the date (not the second) so a
        re-import of the same log with slightly different session timestamps
        still dedupes correctly. Weight rounded to 0.1 kg, which handles the
        lb↔kg floating-point drift without collapsing meaningful differences
        (gym plates are at worst 1.25 kg increments)."""
        components = "|".join([
            str(user_id),
            source_app,
            performed_at.date().isoformat(),
            exercise_name_canonical.strip().lower(),
            str(set_number) if set_number is not None else "",
            _round_for_hash(weight_kg, 1),
            str(reps) if reps is not None else "",
        ])
        return hashlib.sha256(components.encode("utf-8")).hexdigest()

    def to_supabase_row(self, import_job_id: Optional[UUID]) -> Dict[str, Any]:
        """Shape matching workout_history_imports columns post-migration 1964."""
        return {
            "user_id": str(self.user_id),
            "exercise_name": self.exercise_name_raw,
            "weight_kg": self.weight_kg,
            "reps": self.reps,
            "sets": 1,                              # we store one row per set
            "performed_at": self.performed_at.isoformat(),
            "notes": self.notes,
            "source": "import",                     # coarse channel (CHECK constraint)
            "source_app": self.source_app,
            "workout_name": self.workout_name,
            "set_number": self.set_number,
            "set_type": self.set_type.value if isinstance(self.set_type, SetType) else self.set_type,
            "rpe": self.rpe,
            "rir": self.rir,
            "duration_seconds": self.duration_seconds,
            "distance_m": self.distance_m,
            "superset_id": self.superset_id,
            "exercise_id": str(self.exercise_id) if self.exercise_id else None,
            "exercise_name_canonical": self.exercise_name_canonical,
            "source_row_hash": self.source_row_hash,
            "import_job_id": str(import_job_id) if import_job_id else None,
            "original_weight_value": self.original_weight_value,
            "original_weight_unit": (
                self.original_weight_unit.value
                if isinstance(self.original_weight_unit, WeightUnit)
                else self.original_weight_unit
            ),
        }


class CanonicalCardioRow(BaseModel):
    """One cardio session."""
    model_config = ConfigDict(use_enum_values=True)

    user_id: UUID
    performed_at: datetime
    activity_type: str                     # validated against DB CHECK at insert
    duration_seconds: int = Field(..., gt=0)
    distance_m: Optional[float] = Field(default=None, ge=0)
    elevation_gain_m: Optional[float] = Field(default=None, ge=0)
    avg_heart_rate: Optional[int] = Field(default=None, ge=20, le=260)
    max_heart_rate: Optional[int] = Field(default=None, ge=20, le=260)
    avg_pace_seconds_per_km: Optional[float] = None
    avg_speed_mps: Optional[float] = None
    avg_watts: Optional[int] = None
    max_watts: Optional[int] = None
    avg_cadence: Optional[int] = None
    avg_stroke_rate: Optional[int] = None
    training_effect: Optional[float] = None
    vo2max_estimate: Optional[float] = None
    calories: Optional[int] = None
    rpe: Optional[float] = Field(default=None, ge=0, le=10)
    notes: Optional[str] = None
    gps_polyline: Optional[str] = None
    splits_json: Optional[List[Dict[str, Any]]] = None
    source_app: str
    source_external_id: Optional[str] = None
    source_row_hash: str
    sync_account_id: Optional[UUID] = None

    @field_validator("performed_at")
    @classmethod
    def require_tz_aware(cls, v: datetime) -> datetime:
        if v.tzinfo is None:
            raise ValueError("performed_at must be timezone-aware")
        return v

    @staticmethod
    def compute_row_hash(
        *,
        user_id: UUID,
        source_app: str,
        performed_at: datetime,
        activity_type: str,
        duration_seconds: int,
        distance_m: Optional[float],
    ) -> str:
        components = "|".join([
            str(user_id),
            source_app,
            performed_at.replace(microsecond=0).isoformat(),
            activity_type,
            str(duration_seconds),
            _round_for_hash(distance_m, 0),
        ])
        return hashlib.sha256(components.encode("utf-8")).hexdigest()

    def to_supabase_row(self, import_job_id: Optional[UUID]) -> Dict[str, Any]:
        return {
            "user_id": str(self.user_id),
            "performed_at": self.performed_at.isoformat(),
            "activity_type": self.activity_type,
            "duration_seconds": self.duration_seconds,
            "distance_m": self.distance_m,
            "elevation_gain_m": self.elevation_gain_m,
            "avg_heart_rate": self.avg_heart_rate,
            "max_heart_rate": self.max_heart_rate,
            "avg_pace_seconds_per_km": self.avg_pace_seconds_per_km,
            "avg_speed_mps": self.avg_speed_mps,
            "avg_watts": self.avg_watts,
            "max_watts": self.max_watts,
            "avg_cadence": self.avg_cadence,
            "avg_stroke_rate": self.avg_stroke_rate,
            "training_effect": self.training_effect,
            "vo2max_estimate": self.vo2max_estimate,
            "calories": self.calories,
            "rpe": self.rpe,
            "notes": self.notes,
            "gps_polyline": self.gps_polyline,
            "splits_json": self.splits_json,
            "source_app": self.source_app,
            "source_external_id": self.source_external_id,
            "source_row_hash": self.source_row_hash,
            "import_job_id": str(import_job_id) if import_job_id else None,
            "sync_account_id": str(self.sync_account_id) if self.sync_account_id else None,
        }


# ───── Program template shapes ─────

class RepTarget(BaseModel):
    min: int = Field(..., ge=0)
    max: int = Field(..., ge=0)
    amrap_last: bool = False          # e.g. Wendler "5+" / nSuns "x5+"


class LoadPrescription(BaseModel):
    kind: LoadPrescriptionKind
    value_min: Optional[float] = None   # 0.75 for "75%"
    value_max: Optional[float] = None   # 0.80 for "75-80%"
    resolved_kg_min: Optional[float] = None   # computed at import time from snapshotted 1RM
    resolved_kg_max: Optional[float] = None
    reference_1rm_exercise: Optional[str] = None  # e.g. "back_squat" for % prescriptions


class PrescribedSet(BaseModel):
    order: int = Field(..., ge=0)
    set_type: SetType = SetType.WORKING
    rep_target: RepTarget
    load_prescription: LoadPrescription
    rpe_target: Optional[RepTarget] = None          # reuse the min/max shape
    rir_target: Optional[RepTarget] = None
    rest_seconds_min: Optional[int] = None
    rest_seconds_max: Optional[int] = None
    tempo: Optional[str] = None                     # "3-1-1-0"
    notes: Optional[str] = None


class PrescribedExercise(BaseModel):
    order: int = Field(..., ge=0)
    exercise_name_raw: str
    exercise_name_canonical: Optional[str] = None
    exercise_id: Optional[UUID] = None
    superset_id: Optional[str] = None
    warmup_set_count: int = 0
    sets: List[PrescribedSet]


class PrescribedDay(BaseModel):
    day_number: int = Field(..., ge=1)
    day_label: Optional[str] = None          # "Full Body 1: Squat, OHP"
    exercises: List[PrescribedExercise]


class PrescribedWeek(BaseModel):
    week_number: int = Field(..., ge=1)
    label: Optional[str] = None              # "Accumulation", "Deload", etc.
    days: List[PrescribedDay]


class CanonicalProgramTemplate(BaseModel):
    """A creator program imported as a plan (not history)."""
    model_config = ConfigDict(use_enum_values=True)

    user_id: UUID
    source_app: str
    program_name: str
    program_creator: Optional[str] = None
    program_version: Optional[str] = None
    total_weeks: int = Field(..., ge=1)
    days_per_week: int = Field(..., ge=1, le=7)
    unit_hint: WeightUnit
    one_rm_inputs: Dict[str, float] = Field(default_factory=dict)    # {"squat_kg": 140, "bench_kg": 100}
    body_weight_kg: Optional[float] = None
    rounding_multiple_kg: float = 2.5
    training_max_factor: float = 1.0           # Wendler uses 0.9
    weeks: List[PrescribedWeek]
    notes: Optional[str] = None

    def to_supabase_row(
        self,
        import_job_id: Optional[UUID],
        source_file_s3_key: Optional[str] = None,
    ) -> Dict[str, Any]:
        return {
            "user_id": str(self.user_id),
            "source_app": self.source_app,
            "program_name": self.program_name,
            "program_creator": self.program_creator,
            "program_version": self.program_version,
            "total_weeks": self.total_weeks,
            "days_per_week": self.days_per_week,
            "unit_hint": (
                self.unit_hint.value if isinstance(self.unit_hint, WeightUnit) else self.unit_hint
            ),
            "one_rm_inputs": self.one_rm_inputs,
            "body_weight_kg": self.body_weight_kg,
            "rounding_multiple_kg": self.rounding_multiple_kg,
            "training_max_factor": self.training_max_factor,
            "raw_prescription": {"weeks": [w.model_dump() for w in self.weeks]},
            "notes": self.notes,
            "import_job_id": str(import_job_id) if import_job_id else None,
            "source_file_s3_key": source_file_s3_key,
            "active": False,       # user must explicitly activate via settings
            "current_week": 1,
            "current_day": 1,
        }


class ParseResult(BaseModel):
    """What an adapter returns. A single file can produce rows for history,
    cardio, template, or any combination (creator spreadsheets sometimes
    carry all three: template + filled-in history + linked cardio cells).
    """
    mode: ImportMode
    source_app: str
    strength_rows: List[CanonicalSetRow] = Field(default_factory=list)
    cardio_rows: List[CanonicalCardioRow] = Field(default_factory=list)
    template: Optional[CanonicalProgramTemplate] = None
    unresolved_exercise_names: List[str] = Field(default_factory=list)
    warnings: List[str] = Field(default_factory=list)
    sample_rows_for_preview: List[Dict[str, Any]] = Field(default_factory=list)

    @property
    def total_rows(self) -> int:
        return len(self.strength_rows) + len(self.cardio_rows)
