"""Re-export so the `buff_dudes` slug used by format_detector resolves to
our PDF-backed adapter. The actual implementation lives in
`buff_dudes_pdf.py` — the _pdf suffix makes the file's content obvious at
a glance in the directory listing, but the detector needs to import this
shorter name."""
from .buff_dudes_pdf import parse  # noqa: F401
