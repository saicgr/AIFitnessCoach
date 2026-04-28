"""
Emit pretty-printed JSON matching the canonical schema exactly.

This is the easiest format to re-import: every emitted object matches the
CanonicalSetRow / CanonicalCardioRow / CanonicalProgramTemplate pydantic
models field-for-field, so re-ingestion is:

    data = json.loads(bytes)
    strength = [CanonicalSetRow(**r) for r in data["strength"]]
    cardio   = [CanonicalCardioRow(**r) for r in data["cardio"]]

Design choices:
  - `indent=2` (pretty) because this format's selling point is human
    readability for developers who want to inspect or diff.
  - ISO-8601 with timezone for every datetime.
  - UUIDs rendered as strings — pydantic accepts them on re-parse.
  - `version` field on the envelope so future schema changes can migrate.
"""
from __future__ import annotations

import json
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalProgramTemplate,
    CanonicalSetRow,
)

EXPORT_SCHEMA_VERSION = "1.0"


def _default(o):
    """json.dumps default: UUID → str, datetime → iso."""
    if isinstance(o, UUID):
        return str(o)
    if isinstance(o, datetime):
        return o.isoformat()
    raise TypeError(f"not serializable: {type(o)}")


def export_json(
    strength_rows: List[CanonicalSetRow],
    cardio_rows: List[CanonicalCardioRow],
    templates: Optional[List[CanonicalProgramTemplate]] = None,
    *,
    include_strength: bool = True,
    include_cardio: bool = True,
    include_templates: bool = False,
    user_id: Optional[UUID] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
) -> bytes:
    envelope = {
        "version": EXPORT_SCHEMA_VERSION,
        "source": "zealova",
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "user_id": str(user_id) if user_id else None,
        "filter": {"from": from_date, "to": to_date},
        "strength": (
            [r.model_dump(mode="json") for r in strength_rows] if include_strength else []
        ),
        "cardio": (
            [r.model_dump(mode="json") for r in cardio_rows] if include_cardio else []
        ),
        "templates": (
            [t.model_dump(mode="json") for t in (templates or [])]
            if include_templates
            else []
        ),
        "counts": {
            "strength": len(strength_rows) if include_strength else 0,
            "cardio": len(cardio_rows) if include_cardio else 0,
            "templates": len(templates or []) if include_templates else 0,
        },
    }
    return json.dumps(envelope, indent=2, default=_default, ensure_ascii=False).encode("utf-8")
