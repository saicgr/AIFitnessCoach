"""
Creator-program adapters.

Every adapter in this package exports

    async def parse(
        *,
        data: bytes,
        filename: str,
        user_id: UUID,
        unit_hint: str,
        tz_hint: str,
        mode_hint: ImportMode,
    ) -> ParseResult

and is routed to from services.workout_import.service._load_adapter when the
format_detector fingerprints the uploaded file against one of the creator
program signatures (see services.workout_import.format_detector).

All heavy shared logic (regex parsers, openpyxl helpers, AMRAP handling,
percentage / RPE extraction, "did the user fill this in?" detection) lives in
services.workout_import.programs._shared so adapter modules stay thin and
readable.
"""
