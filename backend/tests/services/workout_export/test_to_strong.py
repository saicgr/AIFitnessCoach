"""Verify Strong CSV format."""
from __future__ import annotations

import csv
import io

from services.workout_export.to_strong import STRONG_COLUMNS, export_strong_csv


def test_header_matches_strong_columns(sample_strength_rows):
    blob = export_strong_csv(sample_strength_rows, [])
    header = next(csv.reader(io.StringIO(blob.decode("utf-8"))))
    assert header == STRONG_COLUMNS


def test_set_order_is_one_indexed(sample_strength_rows):
    blob = export_strong_csv(sample_strength_rows, [])
    rows = list(csv.DictReader(io.StringIO(blob.decode("utf-8"))))
    # Canonical set_number 1 → Strong Set Order 1 (not 0).
    assert rows[0]["Set Order"] == "1"
    assert rows[1]["Set Order"] == "2"


def test_date_format_is_iso_space_separated(sample_strength_rows):
    blob = export_strong_csv(sample_strength_rows, [])
    text = blob.decode("utf-8")
    assert "2025-03-28 17:29:00" in text


def test_weight_unit_lbs_converts_from_kg(sample_strength_rows):
    blob = export_strong_csv(sample_strength_rows, [], user_unit="lbs")
    rows = list(csv.DictReader(io.StringIO(blob.decode("utf-8"))))
    # 80 kg → ~176.37 lbs.
    assert rows[0]["Weight Unit"] == "lbs"
    assert abs(float(rows[0]["Weight"]) - 176.37) < 0.05


def test_weight_unit_kg_preserves_kg(sample_strength_rows):
    blob = export_strong_csv(sample_strength_rows, [], user_unit="kg")
    rows = list(csv.DictReader(io.StringIO(blob.decode("utf-8"))))
    assert rows[0]["Weight Unit"] == "kg"
    assert float(rows[0]["Weight"]) == 80.0


def test_duration_string_for_cardio(sample_cardio_rows):
    blob = export_strong_csv([], sample_cardio_rows)
    rows = list(csv.DictReader(io.StringIO(blob.decode("utf-8"))))
    # 1800s = 30 minutes → Strong-style minute-only string when hours==0.
    assert rows[0]["Duration"] == "30m"


def test_duration_string_with_hours():
    """Durations over an hour should render as "1h 12m" per Strong convention."""
    from datetime import datetime, timezone
    from uuid import UUID
    from services.workout_import.canonical import CanonicalCardioRow

    user_id = UUID("11111111-1111-1111-1111-111111111111")
    d = datetime(2025, 4, 2, 6, 30, 0, tzinfo=timezone.utc)
    long_cardio = CanonicalCardioRow(
        user_id=user_id,
        performed_at=d,
        activity_type="cycle",
        duration_seconds=4320,     # 1h 12m
        distance_m=40000.0,
        source_app="zealova",
        source_row_hash="abc" * 10,
    )
    blob = export_strong_csv([], [long_cardio])
    rows = list(csv.DictReader(io.StringIO(blob.decode("utf-8"))))
    assert rows[0]["Duration"] == "1h 12m"
