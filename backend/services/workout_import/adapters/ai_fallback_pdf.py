"""Explicit PDF AI-fallback adapter.

The ``format_detector`` routes PDFs to ``ai_fallback_pdf`` (keeps the
dispatch table readable). Implementation is identical to ``ai_fallback`` —
Gemini accepts the PDF part directly via ``Part.from_bytes`` with
``mime_type="application/pdf"``. We just re-export ``parse`` to keep one
code path.
"""
from __future__ import annotations

from .ai_fallback import parse  # noqa: F401
