"""Alias for generic_sheet so the dispatcher's `generic_xlsm` slug resolves.

Macro-enabled workbooks land here when the detector can't fingerprint a
known creator. openpyxl opens them fine with keep_vba=False + data_only=True
and the generic adapter handles both XLSX and XLSM identically.
"""
from .generic_sheet import parse  # noqa: F401
