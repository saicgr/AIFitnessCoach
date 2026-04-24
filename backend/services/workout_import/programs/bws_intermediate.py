"""
Built With Science Intermediate PDF (Jeremy Ethier).

Image-heavy PDF — the current BWS "Intermediate Program" legacy PDF embeds
exercise demo photos inside the cells, so pypdf text extraction picks up
only partial table text. Route through Gemini Vision for reliable extraction.
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
        source_app="bws_intermediate",
        program_name="BWS Intermediate Program",
        program_creator="Jeremy Ethier / Built With Science",
        default_rounding_kg=2.5 if unit == WeightUnit.KG else 2.27,
        extraction_hint=("Hypertrophy program, Weeks × Exercise rows, cells "
                         "are 'Sets × Reps @ RPE'."),
    )
    if template is None:
        return S.empty_parse_result(
            "bws_intermediate", warnings=["PDF extraction returned no program"],
        )
    return ParseResult(
        mode=ImportMode.TEMPLATE,
        source_app="bws_intermediate",
        template=template,
    )
