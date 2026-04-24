"""
Nike Run Club adapter.

Nike Run Club's only export path is a GDPR data dump from
account.nike.com which ships `.gpx` per activity. There is no metadata
file — the activity label is always "Run" — so we simply reuse the
generic GPX pipeline and tag the source_app as 'nike'.
"""
from __future__ import annotations

from uuid import UUID

from ..canonical import ImportMode, ParseResult
from .generic_gpx import parse_gpx_bytes


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: ImportMode,
) -> ParseResult:
    # Nike always emits running activities; force the fallback to 'run' so
    # a GPX missing a <type> tag still lands with the correct activity_type.
    rows = parse_gpx_bytes(
        data=data,
        user_id=user_id,
        source_app="nike",
        activity_fallback="run",
    )
    return ParseResult(
        mode=ImportMode.CARDIO_ONLY,
        source_app="nike",
        cardio_rows=rows,
    )
