"""
Zealova MCP report generator.

Public entrypoints:
    render_report(user_id, report_type, start_date, end_date, format) -> bytes
    report_content_type(format) -> str

Pipeline
--------
1. `data.collect_report_data()` queries Supabase for everything the requested
   report needs (all reads guarded — missing tables produce empty sections,
   never exceptions).
2. A Jinja2 template in `templates/<report_type>.md.j2` is rendered with that
   context dict to produce Markdown.
3. Format dispatch:
     - markdown → bytes of the rendered Markdown (utf-8)
     - html     → Markdown → HTML (python-markdown) wrapped in `_base.html.j2`
     - pdf      → HTML → PDF via WeasyPrint

Dependencies (`markdown`, `jinja2`, `weasyprint`) are imported lazily inside
`render_report()` so the module can be imported in environments where
WeasyPrint's native libs aren't installed (e.g. CI sandboxes). A clear error
is raised only when the caller actually asks for that format.
"""
from __future__ import annotations

import logging
from datetime import date, datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape

from core import branding
from .data import collect_report_data

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Public constants
# ---------------------------------------------------------------------------

SUPPORTED_REPORT_TYPES: List[str] = [
    "weekly_summary",
    "monthly_summary",
    "nutrition_deep_dive",
    "strength_progression",
    "workout_adherence",
]

SUPPORTED_FORMATS: List[str] = ["pdf", "html", "markdown"]

_REPORT_TITLES: Dict[str, str] = {
    "weekly_summary": "Weekly Summary",
    "monthly_summary": "Monthly Summary",
    "nutrition_deep_dive": "Nutrition Deep Dive",
    "strength_progression": "Strength Progression",
    "workout_adherence": "Workout Adherence",
}

_CONTENT_TYPES: Dict[str, str] = {
    "pdf": "application/pdf",
    "html": "text/html; charset=utf-8",
    "markdown": "text/markdown; charset=utf-8",
}


# ---------------------------------------------------------------------------
# Jinja2 environment (module-level, lazy-initialized)
# ---------------------------------------------------------------------------

_TEMPLATES_DIR = Path(__file__).parent / "templates"

# Use a non-strict undefined for Markdown templates so optional sections don't
# blow up when a key is missing — they'll render as blank and the template
# guards each section with {% if %} anyway. We intentionally do NOT autoescape
# Markdown (not HTML), but DO autoescape the HTML wrapper.
_md_env = Environment(
    loader=FileSystemLoader(str(_TEMPLATES_DIR)),
    autoescape=False,
    trim_blocks=False,
    lstrip_blocks=False,
    keep_trailing_newline=True,
)

_html_env = Environment(
    loader=FileSystemLoader(str(_TEMPLATES_DIR)),
    autoescape=select_autoescape(["html", "htm", "xml"]),
    trim_blocks=True,
    lstrip_blocks=True,
)

# Inject brand identity into both Jinja envs so all templates can use
# {{ APP_NAME }} / {{ MARKETING_DOMAIN }} / {{ WEBSITE_URL }} without each
# template caller having to pass it manually. Single source of truth lives
# in core/branding.py so a future rename only touches one constant.
_brand_globals = {
    "APP_NAME": branding.APP_NAME,
    "APP_FULL_TITLE": branding.APP_FULL_TITLE,
    "APP_TAGLINE": branding.APP_TAGLINE,
    "WEBSITE_URL": branding.WEBSITE_URL,
    "MARKETING_DOMAIN": branding.MARKETING_DOMAIN,
    "SUPPORT_EMAIL": branding.SUPPORT_EMAIL,
    "PRIVACY_EMAIL": branding.PRIVACY_EMAIL,
}
_md_env.globals.update(_brand_globals)
_html_env.globals.update(_brand_globals)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _validate_inputs(report_type: str, format: str) -> None:
    if report_type not in SUPPORTED_REPORT_TYPES:
        raise ValueError(
            f"Unsupported report_type '{report_type}'. "
            f"Supported: {', '.join(SUPPORTED_REPORT_TYPES)}"
        )
    if format not in SUPPORTED_FORMATS:
        raise ValueError(
            f"Unsupported format '{format}'. "
            f"Supported: {', '.join(SUPPORTED_FORMATS)}"
        )


def _parse_iso_date(s: str, field_name: str) -> date:
    try:
        return date.fromisoformat(s)
    except (TypeError, ValueError) as e:
        raise ValueError(f"Invalid {field_name} '{s}' — expected YYYY-MM-DD") from e


def _render_markdown(report_type: str, context: Dict[str, Any]) -> str:
    template = _md_env.get_template(f"{report_type}.md.j2")
    return template.render(**context)


def _markdown_to_html(md_text: str, context: Dict[str, Any], report_type: str) -> str:
    """Convert the rendered Markdown to a complete HTML document."""
    try:
        import markdown  # lazy import — only needed for html/pdf output
    except ImportError as e:  # pragma: no cover
        raise RuntimeError(
            "The 'markdown' package is required for HTML/PDF report output. "
            "Install it via `pip install markdown>=3.5`."
        ) from e

    body_html = markdown.markdown(
        md_text,
        extensions=["tables", "fenced_code", "sane_lists", "nl2br"],
        output_format="html5",
    )
    base = _html_env.get_template("_base.html.j2")
    title = f"{branding.APP_NAME} — {_REPORT_TITLES.get(report_type, 'Report')}"
    return base.render(title=title, body=body_html, context=context)


def _html_to_pdf(html_str: str) -> bytes:
    """Render HTML to PDF bytes via WeasyPrint. WeasyPrint is imported lazily."""
    try:
        from weasyprint import HTML  # lazy import — heavy native deps
    except ImportError as e:  # pragma: no cover
        raise RuntimeError(
            "WeasyPrint is not installed or its system dependencies are missing "
            "(cairo, pango, gdk-pixbuf). Install WeasyPrint to generate PDF reports."
        ) from e

    pdf_bytes = HTML(string=html_str).write_pdf()
    if pdf_bytes is None:  # extremely defensive — WeasyPrint returns bytes normally
        raise RuntimeError("WeasyPrint returned no PDF bytes")
    return pdf_bytes


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def report_content_type(format: str) -> str:
    """Return the MIME type for a given report output format."""
    if format not in _CONTENT_TYPES:
        raise ValueError(
            f"Unsupported format '{format}'. "
            f"Supported: {', '.join(SUPPORTED_FORMATS)}"
        )
    return _CONTENT_TYPES[format]


async def render_report(
    *,
    user_id: str,
    report_type: str,
    start_date: str,
    end_date: str,
    format: str,
) -> bytes:
    """
    Render a report for `user_id` over [start_date, end_date] in the given format.

    Args:
        user_id: Zealova user UUID (string).
        report_type: One of SUPPORTED_REPORT_TYPES.
        start_date / end_date: ISO date strings (YYYY-MM-DD), inclusive.
        format: One of SUPPORTED_FORMATS ("pdf", "html", "markdown").

    Returns:
        Raw bytes of the rendered report. Caller is responsible for delivery
        (e.g. uploading to Supabase Storage and returning a signed URL).

    Raises:
        ValueError: on unsupported report_type / format or malformed dates.
        RuntimeError: if a format-specific dependency (markdown / weasyprint)
            is missing or fails at render time.
    """
    _validate_inputs(report_type, format)

    start = _parse_iso_date(start_date, "start_date")
    end = _parse_iso_date(end_date, "end_date")
    if end < start:
        # Swap rather than raising — reports should be resilient to human input.
        # The templates render the range as start→end so we normalize here.
        logger.info("render_report: end_date < start_date, swapping for user %s", user_id)
        start, end = end, start

    logger.info(
        "render_report: user=%s type=%s range=%s..%s format=%s",
        user_id, report_type, start.isoformat(), end.isoformat(), format,
    )

    # 1. Collect data
    context = await collect_report_data(
        user_id=user_id,
        report_type=report_type,
        start=start,
        end=end,
    )

    # Inject the human-readable title so HTML wrapper can use it
    context.setdefault("report_title", _REPORT_TITLES.get(report_type, "Report"))

    # 2. Render Markdown
    md_text = _render_markdown(report_type, context)

    # 3. Dispatch to requested format
    if format == "markdown":
        return md_text.encode("utf-8")

    if format == "html":
        html_str = _markdown_to_html(md_text, context, report_type)
        return html_str.encode("utf-8")

    if format == "pdf":
        html_str = _markdown_to_html(md_text, context, report_type)
        return _html_to_pdf(html_str)

    # Unreachable — _validate_inputs guards this.
    raise ValueError(f"Unsupported format '{format}'")


# ---------------------------------------------------------------------------
# Sanity / smoke test helpers (not part of public MCP surface)
# ---------------------------------------------------------------------------

def _list_templates() -> List[str]:
    """Return sorted list of template filenames for diagnostics."""
    if not _TEMPLATES_DIR.exists():
        return []
    return sorted(p.name for p in _TEMPLATES_DIR.iterdir() if p.is_file())


def _generated_at_iso() -> str:
    return datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
