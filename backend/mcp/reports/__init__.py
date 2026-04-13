"""
FitWiz MCP report generation module.

Public API:
    render_report(user_id, report_type, start_date, end_date, format) -> bytes
    report_content_type(format) -> str
    SUPPORTED_REPORT_TYPES
    SUPPORTED_FORMATS
"""
from __future__ import annotations

from .generators import (
    SUPPORTED_FORMATS,
    SUPPORTED_REPORT_TYPES,
    render_report,
    report_content_type,
)

__all__ = [
    "render_report",
    "report_content_type",
    "SUPPORTED_REPORT_TYPES",
    "SUPPORTED_FORMATS",
]
