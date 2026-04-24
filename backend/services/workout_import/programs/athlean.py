"""Re-export so the `athlean` slug used by format_detector resolves to
our PDF-backed Athlean-X adapter. See `athlean_pdf.py` for the logic."""
from .athlean_pdf import parse  # noqa: F401
