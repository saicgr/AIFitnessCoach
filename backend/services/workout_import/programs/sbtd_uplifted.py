"""
Stronger By The Day / Meg Squats Uplifted PDF.

The SBTD member app has no export; Uplifted is a 122-page PDF with tables
shaped `Sets × Reps @ RPE` per phase/week/day.

We try pypdf text extraction first; if the PDF is image-heavy (many Uplifted
PDFs are), we route bytes to Gemini Vision with a structured schema matching
CanonicalProgramTemplate.
"""
from __future__ import annotations

from typing import List, Optional
from uuid import UUID

from core.logger import get_logger

from ..canonical import (
    ImportMode,
    ParseResult,
    WeightUnit,
)
from . import _shared as S
from . import _pdf_vision

logger = get_logger(__name__)


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: ImportMode,
) -> ParseResult:
    unit = S.normalize_unit_hint(unit_hint)

    template = await _pdf_vision.extract_program_from_pdf(
        data=data,
        user_id=user_id,
        unit=unit,
        source_app="sbtd_uplifted",
        program_name="Uplifted",
        program_creator="Meg Squats",
        default_rounding_kg=2.5 if unit == WeightUnit.KG else 2.27,
        training_max_factor=1.0,
        extraction_hint="RPE-based table. Columns: Set, Reps, RPE. Each week "
                        "decreases RIR (RPE increases). Phase/Week/Day labels.",
    )

    if template is None:
        return S.empty_parse_result(
            "sbtd_uplifted", warnings=["PDF extraction returned no program"],
        )

    return ParseResult(
        mode=ImportMode.TEMPLATE,
        source_app="sbtd_uplifted",
        template=template,
    )
