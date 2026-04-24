"""Alias for generic_sheet so the dispatcher's `generic_xlsx` slug resolves.

The detector returns `generic_xlsx` when it couldn't fingerprint a known
creator inside an XLSX workbook — we route to the same generic fallback.
"""
from .generic_sheet import parse  # noqa: F401
