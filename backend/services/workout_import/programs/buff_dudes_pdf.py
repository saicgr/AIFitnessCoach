"""
BUFF Dudes 12-Week Plan PDF (96 pages, sold on buffdudes.us).

Phase → Week → Day → Exercises with fixed `Sets × Reps` and blank weight
lines (user writes them in by hand when they print). PDF is image-heavy —
we route bytes to Gemini Vision.
"""
from __future__ import annotations

from uuid import UUID

from core.logger import get_logger

from ..canonical import ImportMode, ParseResult, WeightUnit
from . import _pdf_vision, _shared as S

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
        source_app="buff_dudes",
        program_name="BUFF Dudes 12-Week Plan",
        program_creator="BUFF Dudes",
        default_rounding_kg=2.27 if unit == WeightUnit.LB else 2.5,
        extraction_hint=("Phase-based: Phase 1 (Weeks 1-4), Phase 2 (5-8), "
                         "Phase 3 (9-12). Each day has 5-7 exercises with "
                         "Sets × Reps pre-printed."),
    )
    if template is None:
        return S.empty_parse_result(
            "buff_dudes", warnings=["PDF extraction returned no program"],
        )
    return ParseResult(
        mode=ImportMode.TEMPLATE,
        source_app="buff_dudes",
        template=template,
    )
