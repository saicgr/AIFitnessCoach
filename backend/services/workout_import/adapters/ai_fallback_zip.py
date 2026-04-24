"""ZIP fallback adapter.

Strava bulk exports, Apple Health, and the occasional gym-management tool
ship a ZIP. Some ZIPs (Apple Health) contain a single meaningful file
(``export.xml``); others (Strava) contain many. This adapter:

  1. Unzips the archive to a flat list of (filename, bytes) pairs.
  2. Runs ``format_detector.detect`` on each member.
  3. Dispatches recognized members back through the package-level adapter
     router (``services.workout_import.adapters``) for parsing.
  4. Concatenates the resulting ``strength_rows`` into a single ParseResult.

It explicitly refuses to recurse into nested ZIPs beyond one level
(edge case #90) to avoid zip-bomb risk.
"""
from __future__ import annotations

import importlib
import io
import logging
import zipfile
from typing import Optional
from uuid import UUID

from ..canonical import (
    CanonicalSetRow,
    ImportMode,
    ParseResult,
)

logger = logging.getLogger(__name__)

SOURCE_APP = "ai_parsed_zip"


async def parse(
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: Optional[ImportMode] = None,
) -> ParseResult:
    warnings: list[str] = []
    all_rows: list[CanonicalSetRow] = []
    source_apps: list[str] = []

    try:
        from ..format_detector import detect
    except ImportError as e:
        return ParseResult(
            mode=ImportMode.AMBIGUOUS,
            source_app=SOURCE_APP,
            warnings=[f"format_detector unavailable: {e}"],
        )

    try:
        zf = zipfile.ZipFile(io.BytesIO(data))
    except zipfile.BadZipFile:
        return ParseResult(
            mode=ImportMode.AMBIGUOUS,
            source_app=SOURCE_APP,
            warnings=["malformed ZIP"],
        )

    for info in zf.infolist():
        if info.is_dir():
            continue
        member_name = info.filename
        if member_name.lower().endswith(".zip"):
            warnings.append(f"skipping nested ZIP: {member_name}")
            continue
        try:
            member_bytes = zf.read(info)
        except Exception as e:
            warnings.append(f"couldn't read {member_name}: {e}")
            continue
        if not member_bytes:
            continue

        detection = detect(member_bytes, filename=member_name)
        if detection.source_app in ("unknown", "ai_fallback_zip"):
            warnings.append(f"skipping unrecognized member: {member_name}")
            continue

        adapter_module_name = (
            f"services.workout_import.adapters.{detection.source_app}"
        )
        try:
            adapter_module = importlib.import_module(adapter_module_name)
        except ImportError:
            # Adapter not yet implemented (e.g., garmin_fit, apple_health_xml
            # sibling tasks) — fall through to ai_fallback if present.
            try:
                adapter_module = importlib.import_module(
                    "services.workout_import.adapters.ai_fallback"
                )
            except ImportError:
                warnings.append(f"no adapter for {detection.source_app}")
                continue

        try:
            result: ParseResult = await adapter_module.parse(
                data=member_bytes,
                filename=member_name,
                user_id=user_id,
                unit_hint=unit_hint,
                tz_hint=tz_hint,
                mode_hint=detection.mode,
            )
        except Exception as e:
            logger.exception("adapter crashed inside ZIP")
            warnings.append(f"{member_name}: {e}")
            continue

        all_rows.extend(result.strength_rows)
        source_apps.append(result.source_app)
        warnings.extend(result.warnings)

    if not all_rows:
        return ParseResult(
            mode=ImportMode.AMBIGUOUS,
            source_app=SOURCE_APP,
            warnings=warnings or ["ZIP contained no recognizable fitness data"],
        )

    primary_source = source_apps[0] if len(set(source_apps)) == 1 else SOURCE_APP
    preview = [r.model_dump(mode="json") for r in all_rows[:20]]
    return ParseResult(
        mode=ImportMode.HISTORY,
        source_app=primary_source,
        strength_rows=all_rows,
        warnings=warnings,
        sample_rows_for_preview=preview,
    )
