"""
Athlean-X Max Size / Max OT PDF.

Columns: `Phase | Week | Day | Exercise | Sets × Reps | Rest`. AX content is
heavily gated — the PDFs we see have text layers sometimes and image tables
other times. _pdf_vision handles both code paths.
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
    # Choose program_name based on the filename.
    lower = filename.lower()
    if "max ot" in lower:
        program_name = "Max OT"
    elif "max size" in lower:
        program_name = "Max Size"
    else:
        program_name = "Athlean-X Program"

    template = await _pdf_vision.extract_program_from_pdf(
        data=data,
        user_id=user_id,
        unit=unit,
        source_app="athlean",
        program_name=program_name,
        program_creator="Jeff Cavaliere / Athlean-X",
        default_rounding_kg=2.27 if unit == WeightUnit.LB else 2.5,
        extraction_hint=("Phased program with explicit Sets × Reps and rest "
                         "intervals. Max OT uses low-rep (4-6) strength work; "
                         "Max Size has hypertrophy rep ranges."),
    )
    if template is None:
        return S.empty_parse_result(
            "athlean", warnings=["PDF extraction returned no program"],
        )
    return ParseResult(
        mode=ImportMode.TEMPLATE,
        source_app="athlean",
        template=template,
    )
