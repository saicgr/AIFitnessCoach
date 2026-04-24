"""Smoke tests for PDF-based adapters (BWS, BUFF Dudes, Athlean, SBTD).

The real PDFs route through Gemini Vision. In tests we monkey-patch the
Gemini call with a canned response so we verify ONLY the surrounding wiring:
pypdf page-count guard, JSON → CanonicalProgramTemplate construction,
ParseResult wrapping.
"""
from __future__ import annotations

import pytest

from services.workout_import.canonical import ImportMode
from services.workout_import.programs import (
    athlean_pdf, bws_intermediate, buff_dudes_pdf, sbtd_uplifted,
)

from .conftest import build_minimal_pdf


_FAKE_GEMINI_RESPONSE = {
    "weeks": [
        {
            "week_number": 1,
            "label": None,
            "days": [
                {
                    "day_number": 1,
                    "day_label": "Upper A",
                    "exercises": [
                        {
                            "name": "Bench Press",
                            "sets": 3,
                            "reps_min": 8,
                            "reps_max": 10,
                            "amrap_last": False,
                            "percent_1rm_min": None,
                            "percent_1rm_max": None,
                            "rpe": 8,
                            "notes": None,
                        }
                    ],
                }
            ],
        }
    ]
}


@pytest.fixture(autouse=True)
def _patch_gemini(monkeypatch):
    """Replace the internal Gemini call with a deterministic return."""
    async def _fake(**kwargs):
        return _FAKE_GEMINI_RESPONSE

    from services.workout_import.programs import _pdf_vision
    monkeypatch.setattr(_pdf_vision, "_call_gemini", _fake)


@pytest.mark.asyncio
@pytest.mark.parametrize("adapter, source_app, fname", [
    (sbtd_uplifted, "sbtd_uplifted", "uplifted.pdf"),
    (bws_intermediate, "bws_intermediate", "bws_intermediate.pdf"),
    (buff_dudes_pdf, "buff_dudes", "buff_dudes_12week.pdf"),
    (athlean_pdf, "athlean", "athlean_max_size.pdf"),
])
async def test_pdf_adapter_returns_template(test_user_id, adapter, source_app, fname):
    data = build_minimal_pdf()
    result = await adapter.parse(
        data=data,
        filename=fname,
        user_id=test_user_id,
        unit_hint="lb",
        tz_hint="UTC",
        mode_hint=ImportMode.TEMPLATE,
    )
    assert result.mode == ImportMode.TEMPLATE
    assert result.source_app == source_app
    assert result.template is not None
    day = result.template.weeks[0].days[0]
    assert day.exercises[0].exercise_name_raw == "Bench Press"
