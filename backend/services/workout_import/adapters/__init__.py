"""
Per-app adapters for workout-import. Each adapter exports:

    async def parse(
        *,
        data: bytes,
        filename: str,
        user_id: UUID,
        unit_hint: str,
        tz_hint: str,
        mode_hint: ImportMode,
    ) -> ParseResult

Adapters are imported lazily by services.workout_import.service._load_adapter()
so heavy deps (fitparse, lxml, gpxpy) aren't loaded until a matching file
actually hits the pipeline.
"""
