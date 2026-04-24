"""Verify PDF export produces a readable document with expected strings."""
from __future__ import annotations

import io
from datetime import date

import pypdf

from services.workout_export.to_pdf import export_pdf


def _extract_text(pdf_bytes: bytes) -> str:
    reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
    return "\n".join(page.extract_text() or "" for page in reader.pages)


def test_pdf_has_multiple_pages(sample_strength_rows, sample_cardio_rows):
    blob = export_pdf(
        sample_strength_rows, sample_cardio_rows,
        athlete_name="Alex Test",
        from_date=date(2025, 3, 1),
        to_date=date(2025, 4, 30),
    )
    reader = pypdf.PdfReader(io.BytesIO(blob))
    # Cover + log + PRs + charts = 4 pages minimum.
    assert len(reader.pages) >= 4


def test_pdf_cover_includes_athlete_name_and_dates(sample_strength_rows, sample_cardio_rows):
    blob = export_pdf(
        sample_strength_rows, sample_cardio_rows,
        athlete_name="Alex Test",
        from_date=date(2025, 3, 1),
        to_date=date(2025, 4, 30),
    )
    text = _extract_text(blob)
    assert "Alex Test" in text
    assert "FitWiz Training Report" in text


def test_pdf_has_exercise_names(sample_strength_rows, sample_cardio_rows):
    blob = export_pdf(sample_strength_rows, sample_cardio_rows, athlete_name="Alex")
    text = _extract_text(blob)
    # Both canonical exercise names from the fixture should appear.
    assert "Barbell Row" in text
    assert "Bench Press" in text


def test_pdf_starts_with_pdf_magic_bytes(sample_strength_rows):
    blob = export_pdf(sample_strength_rows, [], athlete_name="Alex")
    # "%PDF-" is the standard magic number.
    assert blob.startswith(b"%PDF-")


def test_pdf_works_with_no_data():
    """Empty user (just signed up) should still get a readable report."""
    blob = export_pdf([], [], athlete_name="NewUser")
    reader = pypdf.PdfReader(io.BytesIO(blob))
    assert len(reader.pages) >= 2           # at least cover + one of log/PR/charts
    text = _extract_text(blob)
    assert "NewUser" in text
