"""Nutrition importer (Part A).

Header-driven, tolerant parsers that bring historical food + weight logs in from
MyFitnessPal, MacroFactor, Cronometer (CSV/zip exports) and Apple Health
(client-assembled daily rows) into the `food_logs` / `weight_logs` tables.

Design (see plan): parsers map by *normalized column name* (not fixed position),
auto-detect source by header signature, surface unmapped columns instead of
silently dropping, and every import runs a dry-run preview before commit. Real
vendor exports are not column-stable, so each parser is validated against a real
golden fixture under ``fixtures/`` before production enablement.
"""

from .parsers import (  # noqa: F401
    NormalizedFoodRow,
    NormalizedWeightRow,
    ParseResult,
    detect_source,
    parse_export,
)
