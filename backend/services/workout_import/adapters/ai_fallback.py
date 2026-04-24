"""Gemini-based fallback adapter for PDFs, images, and unknown exports.

When no per-app adapter matches (scanned gym-journal PDFs, photographs of
handwritten logs, weird vendor CSVs we don't have a fingerprint for), we
hand the file to Gemini with a strict structured-output schema that mirrors
``CanonicalSetRow``.

Uses the existing ``gemini_generate_with_retry`` helper from
``services.gemini.constants`` (same one used across the codebase for every
structured Gemini call) — no new SDK dependency.

Edge cases covered here: #72-#81 (PDF specifics), #77 image-of-table,
#23 OCR reps stored as text (Gemini silently normalizes to digits).
"""
from __future__ import annotations

import logging
import mimetypes
from datetime import timezone
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from ..canonical import (
    CanonicalSetRow,
    ImportMode,
    ParseResult,
    SetType,
    WeightUnit,
)
from ._common import parse_datetime, parse_weight_cell, to_kg

logger = logging.getLogger(__name__)

SOURCE_APP = "ai_parsed"


# ── Structured-output schema Gemini returns ──

class _GeminiSetRow(BaseModel):
    performed_at: str = Field(..., description="ISO 8601 date/time. If only the date is visible, use 00:00 local time.")
    workout_name: Optional[str] = None
    exercise_name: str
    set_number: Optional[int] = Field(default=None, ge=0, le=99)
    set_type: str = Field(default="working", description="working|warmup|failure|dropset|amrap")
    weight: Optional[float] = Field(default=None, description="Raw weight value as shown in the source; null for bodyweight.")
    weight_unit: Optional[str] = Field(default=None, description="'kg' or 'lb'; null if not explicitly stated in the source.")
    reps: Optional[int] = Field(default=None, ge=0, le=999)
    rpe: Optional[float] = Field(default=None, ge=0.0, le=10.0)
    notes: Optional[str] = None


class _GeminiExtractResponse(BaseModel):
    source_app_guess: str = Field(..., description="Best guess at the source app or program name, or 'unknown'.")
    warnings: List[str] = Field(default_factory=list)
    rows: List[_GeminiSetRow] = Field(default_factory=list)


_PROMPT = """You are an expert fitness-data extractor. The attached document is a
workout log — possibly a PDF, a screenshot of a spreadsheet, a scanned
handwritten notebook page, or an unfamiliar CSV dump. Extract every
individual logged set you can see.

Rules:
- One JSON object per *set* (not per exercise, not per workout).
- If the document shows "3 sets of 10 @ 135 lb" as a summary row, expand to 3 separate set rows.
- Preserve the weight exactly as shown. Set ``weight_unit`` only when the
  source is unambiguous (explicit "kg" or "lb" nearby, or a header row
  labelled in that unit). Otherwise leave ``weight_unit`` null.
- For bodyweight movements, set ``weight = 0`` and ``weight_unit = null``.
- ``set_type`` must be one of: working, warmup, failure, dropset, amrap.
- For rep ranges like "8-12", use the max; for AMRAP markers like "5+" or
  "AMRAP", use the scalar rep count and set ``set_type = amrap``.
- If a date is only partially visible, use ``null`` in place of the row — do
  not fabricate.
- Write any ambiguities you encountered into ``warnings``.

Return ONLY the JSON object matching the schema."""


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: Optional[ImportMode] = None,
) -> ParseResult:
    default_unit = WeightUnit.LB if (unit_hint or "").lower() == "lb" else WeightUnit.KG
    warnings: list[str] = []

    mime, _ = mimetypes.guess_type(filename)
    if not mime:
        if data.startswith(b"%PDF"):
            mime = "application/pdf"
        elif data[:3] == b"\xff\xd8\xff":
            mime = "image/jpeg"
        elif data[:4] == b"\x89PNG":
            mime = "image/png"
        else:
            mime = "text/plain"

    # Import lazily so the module loads even without Gemini SDK installed in
    # test environments.
    try:
        from google.genai import types  # type: ignore
        from services.gemini.constants import gemini_generate_with_retry
        from core.config import settings
    except ImportError as e:
        warnings.append(f"Gemini SDK unavailable: {e}")
        return ParseResult(
            mode=mode_hint or ImportMode.HISTORY,
            source_app=SOURCE_APP,
            warnings=warnings,
        )

    try:
        file_part = types.Part.from_bytes(data=data, mime_type=mime)
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=[_PROMPT, file_part],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=_GeminiExtractResponse,
                temperature=0.0,
                max_output_tokens=16000,
            ),
            method_name="workout_import_ai_fallback",
            timeout=90,
        )
    except Exception as e:
        logger.exception("AI fallback Gemini call failed")
        warnings.append(f"Gemini extraction failed: {e}")
        return ParseResult(
            mode=mode_hint or ImportMode.HISTORY,
            source_app=SOURCE_APP,
            warnings=warnings,
        )

    parsed: Optional[_GeminiExtractResponse] = getattr(response, "parsed", None)
    if not parsed:
        warnings.append("Gemini returned empty extraction")
        return ParseResult(
            mode=mode_hint or ImportMode.HISTORY,
            source_app=SOURCE_APP,
            warnings=warnings,
        )

    if parsed.warnings:
        warnings.extend(parsed.warnings)

    source_app_slug = f"ai_parsed_{(parsed.source_app_guess or 'unknown').strip().lower().replace(' ', '_')}"
    source_app_slug = source_app_slug[:64]

    rows: list[CanonicalSetRow] = []
    for r in parsed.rows:
        exercise_name = (r.exercise_name or "").strip()
        if not exercise_name:
            continue
        performed_at = parse_datetime(r.performed_at, tz_hint)
        if performed_at is None:
            warnings.append(f"Gemini row had unparseable date: {r.performed_at!r}")
            continue
        performed_at = performed_at.astimezone(timezone.utc)

        unit_hint_row = (r.weight_unit or "").lower()
        if unit_hint_row == "kg":
            explicit_unit = WeightUnit.KG
        elif unit_hint_row in ("lb", "lbs"):
            explicit_unit = WeightUnit.LB
        else:
            explicit_unit = default_unit

        value, unit = parse_weight_cell(
            None if r.weight is None else str(r.weight),
            default_unit=explicit_unit,
        )
        weight_kg = to_kg(value, unit) if value is not None else None

        # Map the LLM's set_type string back to our enum.
        try:
            set_type = SetType(r.set_type)
        except ValueError:
            set_type = SetType.WORKING

        canonical = exercise_name.lower()
        row_hash = CanonicalSetRow.compute_row_hash(
            user_id=user_id,
            source_app=source_app_slug,
            performed_at=performed_at,
            exercise_name_canonical=canonical,
            set_number=r.set_number,
            weight_kg=weight_kg,
            reps=r.reps,
        )
        rows.append(CanonicalSetRow(
            user_id=user_id,
            performed_at=performed_at,
            workout_name=r.workout_name,
            exercise_name_raw=exercise_name,
            exercise_name_canonical=canonical,
            set_number=r.set_number,
            set_type=set_type,
            weight_kg=weight_kg,
            original_weight_value=value,
            original_weight_unit=unit,
            reps=r.reps,
            rpe=r.rpe,
            notes=r.notes,
            source_app=source_app_slug,
            source_row_hash=row_hash,
        ))

    preview = [row.model_dump(mode="json") for row in rows[:20]]
    return ParseResult(
        mode=mode_hint or ImportMode.HISTORY,
        source_app=source_app_slug,
        strength_rows=rows,
        warnings=warnings,
        sample_rows_for_preview=preview,
    )
