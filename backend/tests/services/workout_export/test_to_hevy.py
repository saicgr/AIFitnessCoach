"""Verify the Hevy CSV emitter produces exactly the header order Hevy uses
and renders dates in the "28 Mar 2025, 17:29" format."""
from __future__ import annotations

import csv
import io

from services.workout_export.to_hevy import HEVY_COLUMNS, export_hevy_csv


def test_header_row_matches_hevy_exact_columns(sample_strength_rows):
    blob = export_hevy_csv(sample_strength_rows, cardio_rows=[])
    reader = csv.reader(io.StringIO(blob.decode("utf-8")))
    header = next(reader)
    assert header == HEVY_COLUMNS
    # Hevy requires both kg AND lbs columns to exist — regression guard.
    assert "Weight (kg)" in header and "Weight (lbs)" in header


def test_date_format_is_hevy_style(sample_strength_rows):
    blob = export_hevy_csv(sample_strength_rows, cardio_rows=[])
    text = blob.decode("utf-8")
    assert "28 Mar 2025, 17:29" in text


def test_weight_lbs_and_weight_kg_both_populated(sample_strength_rows):
    blob = export_hevy_csv(sample_strength_rows, cardio_rows=[])
    rows = list(csv.DictReader(io.StringIO(blob.decode("utf-8"))))
    r = rows[0]
    assert r["Weight (kg)"] == "80.00"
    # 80 kg / 0.45359237 ≈ 176.37 lbs — allow tight tolerance.
    assert abs(float(r["Weight (lbs)"]) - 176.37) < 0.05


def test_set_index_is_zero_based(sample_strength_rows):
    blob = export_hevy_csv(sample_strength_rows, cardio_rows=[])
    rows = list(csv.DictReader(io.StringIO(blob.decode("utf-8"))))
    # First set (canonical set_number=1) should be Set Index=0 in Hevy.
    assert rows[0]["Set Index"] == "0"
    assert rows[1]["Set Index"] == "1"


def test_set_type_default_is_normal(sample_strength_rows):
    blob = export_hevy_csv(sample_strength_rows, cardio_rows=[])
    rows = list(csv.DictReader(io.StringIO(blob.decode("utf-8"))))
    assert all(r["Set Type"] == "normal" for r in rows)


def test_empty_input_still_emits_header():
    blob = export_hevy_csv([], [])
    reader = csv.reader(io.StringIO(blob.decode("utf-8")))
    header = next(reader)
    assert header == HEVY_COLUMNS
    # No data rows after the header.
    assert list(reader) == []


def test_cardio_rows_appended_after_strength(sample_strength_rows, sample_cardio_rows):
    blob = export_hevy_csv(sample_strength_rows, sample_cardio_rows)
    rows = list(csv.DictReader(io.StringIO(blob.decode("utf-8"))))
    assert len(rows) == len(sample_strength_rows) + len(sample_cardio_rows)
    # Last row should be the cardio row.
    assert rows[-1]["Exercise Title"] == "Run"
    # Distance is in meters per Hevy's real column header.
    assert float(rows[-1]["Distance (meters)"]) == 5000.0
