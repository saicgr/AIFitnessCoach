"""
Single entry point for the export pipeline.

Dispatches to the right format emitter and returns (bytes, content_type,
filename). Callers (the /workout-history/export endpoint, the chat-bot
`export_data` action, and future automations like weekly-digest emails)
should all go through here so filename conventions and content-types stay
consistent.

Format catalog (the `SUPPORTED_FORMATS` map below is also what the
`/workout-history/export/formats` endpoint returns to the UI picker).
"""
from __future__ import annotations

import asyncio
import logging
from datetime import date, datetime
from typing import Optional, Tuple
from uuid import UUID

from . import (
    data_loader,
    to_fitbod,
    to_generic_csv,
    to_gpx,
    to_hevy,
    to_json,
    to_parquet,
    to_pdf,
    to_strong,
    to_tcx,
    to_xlsx,
)

logger = logging.getLogger(__name__)


SUPPORTED_FORMATS = {
    "hevy": {
        "display": "Hevy CSV",
        "description": "Hevy-compatible CSV. Import via Hevy → Settings → Import Data.",
        "extension": "csv",
        "content_type": "text/csv",
        "cardio_only": False,
    },
    "strong": {
        "display": "Strong CSV",
        "description": "Strong-app CSV (also accepted by most community tools).",
        "extension": "csv",
        "content_type": "text/csv",
        "cardio_only": False,
    },
    "fitbod": {
        "display": "Fitbod CSV",
        "description": "Fitbod CSV. Import via Fitbod → Settings → Data.",
        "extension": "csv",
        "content_type": "text/csv",
        "cardio_only": False,
    },
    "csv": {
        "display": "Generic CSV (all columns)",
        "description": "Expanded Zealova-native CSV with every field preserved.",
        "extension": "csv",
        "content_type": "text/csv",
        "cardio_only": False,
    },
    "json": {
        "display": "JSON",
        "description": "Pretty-printed JSON. Easiest re-import path.",
        "extension": "json",
        "content_type": "application/json",
        "cardio_only": False,
    },
    "parquet": {
        "display": "Parquet (ZIP)",
        "description": "Columnar Parquet files — faster for large imports.",
        "extension": "zip",
        "content_type": "application/zip",
        "cardio_only": False,
    },
    "xlsx": {
        "display": "Excel",
        "description": "Multi-sheet workbook (Strength / Cardio / Templates / Summary).",
        "extension": "xlsx",
        "content_type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "cardio_only": False,
    },
    "pdf": {
        "display": "PDF Report",
        "description": "Printable training report with charts and PRs.",
        "extension": "pdf",
        "content_type": "application/pdf",
        "cardio_only": False,
    },
    "tcx": {
        "display": "TCX",
        "description": "Garmin Training Center XML for cardio sessions.",
        "extension": "tcx",
        "content_type": "application/vnd.garmin.tcx+xml",
        "cardio_only": True,
    },
    "gpx": {
        "display": "GPX (cardio only)",
        "description": "GPX route data for runs / rides with recorded GPS.",
        "extension": "gpx",
        "content_type": "application/gpx+xml",
        "cardio_only": True,
    },
}


def _filename(format_key: str, user_id: UUID) -> str:
    ext = SUPPORTED_FORMATS[format_key]["extension"]
    ts = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    short = str(user_id)[:8]
    return f"fitwiz-{format_key}-{short}-{ts}.{ext}"


async def export_user_data(
    *,
    user_id: UUID,
    format: str,
    include_strength: bool = True,
    include_cardio: bool = True,
    include_templates: bool = False,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db=None,
) -> Tuple[bytes, str, str]:
    """Generate an export blob.

    Returns:
        (bytes, content_type, filename)

    Raises:
        ValueError for unsupported format.
        All DB errors bubble up; data_loader logs + degrades on a per-table
        basis so a single missing table doesn't fail the whole export.
    """
    format = (format or "").lower().strip()
    if format not in SUPPORTED_FORMATS:
        raise ValueError(f"Unsupported export format: {format!r}. "
                         f"Pick one of {list(SUPPORTED_FORMATS)}.")

    spec = SUPPORTED_FORMATS[format]

    # Cardio-only formats short-circuit the strength toggle — user can't
    # meaningfully export strength as a TCX file, so we auto-disable.
    if spec["cardio_only"]:
        include_strength = False
        include_cardio = True

    logger.info(
        f"[WorkoutExport] user={user_id} format={format} "
        f"strength={include_strength} cardio={include_cardio} "
        f"templates={include_templates} range={from_date}→{to_date}"
    )

    # Data-loader calls hit Supabase synchronously (the Supabase python
    # client is sync under the hood). Run them in a thread pool so the
    # async endpoint stays responsive for concurrent users. `functools.partial`
    # lets us pass `db=` as a keyword without writing adapter lambdas.
    import functools
    loop = asyncio.get_event_loop()

    strength_fn = functools.partial(data_loader.load_strength, user_id, from_date, to_date, db=db)
    cardio_fn = functools.partial(data_loader.load_cardio, user_id, from_date, to_date, db=db)
    templates_fn = functools.partial(data_loader.load_templates, user_id, db=db)

    strength = (
        await loop.run_in_executor(None, strength_fn) if include_strength else []
    )
    cardio = (
        await loop.run_in_executor(None, cardio_fn)
        if (include_cardio or spec["cardio_only"]) else []
    )
    templates = (
        await loop.run_in_executor(None, templates_fn) if include_templates else []
    )

    # Dispatch. Wrap each emitter call so the content_type + filename stay
    # tied to the format spec rather than re-derived per module.
    if format == "hevy":
        payload = to_hevy.export_hevy_csv(
            strength, cardio,
            include_strength=include_strength,
            include_cardio=include_cardio,
        )
    elif format == "strong":
        # user_unit read async — fall back to "lbs" on failure.
        unit_fn = functools.partial(data_loader.load_user_weight_unit, user_id, db=db)
        user_unit = await loop.run_in_executor(None, unit_fn)
        payload = to_strong.export_strong_csv(
            strength, cardio, user_unit=user_unit,
            include_strength=include_strength,
            include_cardio=include_cardio,
        )
    elif format == "fitbod":
        payload = to_fitbod.export_fitbod_csv(
            strength, cardio,
            include_strength=include_strength,
            include_cardio=include_cardio,
        )
    elif format == "csv":
        payload = to_generic_csv.export_generic_csv(
            strength, cardio,
            include_strength=include_strength,
            include_cardio=include_cardio,
        )
    elif format == "json":
        payload = to_json.export_json(
            strength, cardio, templates,
            include_strength=include_strength,
            include_cardio=include_cardio,
            include_templates=include_templates,
            user_id=user_id,
            from_date=from_date.isoformat() if from_date else None,
            to_date=to_date.isoformat() if to_date else None,
        )
    elif format == "parquet":
        payload = to_parquet.export_parquet(
            strength, cardio,
            include_strength=include_strength,
            include_cardio=include_cardio,
        )
    elif format == "xlsx":
        payload = to_xlsx.export_xlsx(
            strength, cardio, templates,
            include_strength=include_strength,
            include_cardio=include_cardio,
            include_templates=include_templates,
        )
    elif format == "pdf":
        name_fn = functools.partial(data_loader.load_user_first_name, user_id, db=db)
        athlete = await loop.run_in_executor(None, name_fn)
        # PDF is CPU-heavy — offload to thread pool too.
        pdf_fn = functools.partial(
            to_pdf.export_pdf,
            strength, cardio,
            athlete_name=athlete,
            from_date=from_date,
            to_date=to_date,
        )
        payload = await loop.run_in_executor(None, pdf_fn)
    elif format == "tcx":
        payload = to_tcx.export_tcx(cardio)
    elif format == "gpx":
        payload = to_gpx.export_gpx(cardio)
    else:
        # Exhaustive match above; this is defensive.
        raise ValueError(f"No emitter wired for format {format!r}")

    return payload, spec["content_type"], _filename(format, user_id)
