"""
pdf_extractor.py — Gemini PDF understanding.

PDF payloads shared from Files / Drive / Dropbox into Zealova can be:
  * Recipe cookbook page
  * Workout / training program PDF
  * Medical lab report
  * Multi-page nutrition guide
  * Scanned image-only PDF (falls back to image classifier)
  * Password-protected PDF (graceful failure)

This service returns a normalized text body that the intent classifier
runs over. Heavy structured extraction (recipe / workout) is performed
downstream by the existing extractors, fed the text we return here.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Optional

from google.genai import types

from core.config import get_settings
from services.gemini.constants import gemini_generate_with_retry

logger = logging.getLogger(__name__)
settings = get_settings()


@dataclass
class PdfUnderstanding:
    text: str
    page_count: Optional[int] = None
    locked: bool = False
    error: Optional[str] = None


_PDF_PROMPT = """Extract the FULL textual content of this PDF.

If the PDF is password-protected or otherwise unreadable, respond ONLY with
the exact token: LOCKED.

If the PDF is image-only (no machine-readable text layer), still attempt
OCR and emit the visible text.

Preserve list structure (numbered steps, bullet ingredients, sets/reps
tables) using simple markdown. Do not summarize, do not editorialize."""


async def understand_pdf(pdf_bytes: bytes) -> PdfUnderstanding:
    """Run the Gemini PDF understanding call. Returns a PdfUnderstanding
    even on failure (text='', error=...)."""
    if not pdf_bytes:
        return PdfUnderstanding(text="", error="empty pdf")

    try:
        pdf_part = types.Part.from_bytes(data=pdf_bytes, mime_type="application/pdf")
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=[_PDF_PROMPT, pdf_part],
            config=types.GenerateContentConfig(
                temperature=0.1,
                max_output_tokens=8000,
            ),
            method_name="share_pdf_understand",
        )
        raw = (response.text or "").strip()
        if raw.upper() == "LOCKED":
            return PdfUnderstanding(text="", locked=True, error="password-protected or unreadable")
        return PdfUnderstanding(text=raw[:60_000])
    except Exception as e:
        logger.warning(f"[PdfExtractor] failed: {e}", exc_info=True)
        return PdfUnderstanding(text="", error=str(e)[:240])
