"""
Emit a printable PDF training report using reportlab>=4.2.

Pages:
  1. Cover — athlete name, date range, total workouts, logo blurb.
  2. Week-by-week log — table with (Date, Exercise, Top Set, Volume).
  3. PR highlights — biggest top set per exercise ranked by est. 1RM.
  4. Charts — weekly volume bar, top-set progression for top 3 lifts.

Font strategy:
  - reportlab ships Helvetica / Times / Courier as built-in PDF core fonts
    (no embedding needed — they're standard per PDF 1.7).
  - We ALSO register DejaVu Sans as a fallback and embed it, so unicode
    characters (emoji, °, accented exercise names like "Zercher") render
    cleanly. DejaVu ships with reportlab.
  - When DejaVu isn't available (stripped install), we degrade to Helvetica
    silently — better than a 500 during export.
"""
from __future__ import annotations

import io
import os
from collections import defaultdict
from datetime import date, datetime
from typing import Dict, List, Optional, Tuple

from core import branding
from reportlab.lib import colors
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    HRFlowable,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.graphics.shapes import Drawing
from reportlab.graphics.charts.barcharts import VerticalBarChart
from reportlab.graphics.charts.linecharts import HorizontalLineChart

from services.workout_import.canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
)


_BODY_FONT = "Helvetica"
_BODY_FONT_BOLD = "Helvetica-Bold"


def _register_unicode_font() -> None:
    """Embed DejaVu Sans when available so exercise names with accents /
    unicode render correctly. No-op on failure so core fonts still work.
    """
    global _BODY_FONT, _BODY_FONT_BOLD
    try:
        # reportlab bundles DejaVu under reportlab/fonts/ on most installs.
        import reportlab
        base = os.path.join(os.path.dirname(reportlab.__file__), "fonts")
        regular = os.path.join(base, "DejaVuSans.ttf")
        bold = os.path.join(base, "DejaVuSans-Bold.ttf")
        if os.path.exists(regular):
            pdfmetrics.registerFont(TTFont("DejaVuSans", regular))
            _BODY_FONT = "DejaVuSans"
        if os.path.exists(bold):
            pdfmetrics.registerFont(TTFont("DejaVuSans-Bold", bold))
            _BODY_FONT_BOLD = "DejaVuSans-Bold"
    except Exception:
        # Keep Helvetica; non-fatal.
        pass


def _epley(weight: float, reps: int) -> float:
    """Classic Epley estimate: 1RM ≈ w × (1 + r/30)."""
    if weight <= 0 or reps <= 0:
        return 0.0
    return weight * (1 + reps / 30.0)


def _weekly_volume(strength: List[CanonicalSetRow]) -> List[Tuple[str, float]]:
    by_week: Dict[str, float] = defaultdict(float)
    for r in strength:
        if r.weight_kg is None or r.reps is None:
            continue
        iso = r.performed_at.isocalendar()
        key = f"{iso[0]}-W{iso[1]:02d}"
        by_week[key] += float(r.weight_kg) * int(r.reps)
    return sorted(by_week.items())


def _top_sets_per_exercise(
    strength: List[CanonicalSetRow],
) -> Dict[str, Tuple[float, int, date]]:
    """Return {exercise: (weight_kg, reps, date)} for the top-ranked set.

    Ranked by weight_kg, tie-broken by reps, tie-broken by latest date.
    """
    best: Dict[str, Tuple[float, int, date]] = {}
    for r in strength:
        if r.weight_kg is None or r.reps is None:
            continue
        name = (r.exercise_name_canonical or r.exercise_name_raw or "").strip()
        if not name:
            continue
        candidate = (float(r.weight_kg), int(r.reps), r.performed_at.date())
        cur = best.get(name)
        if cur is None or candidate > cur:
            best[name] = candidate
    return best


def _cover_page(
    athlete_name: str,
    from_date: Optional[date],
    to_date: Optional[date],
    total_workouts: int,
    strength_sets: int,
    cardio_sessions: int,
    styles,
) -> List:
    story: List = []
    title_style = ParagraphStyle(
        "Title", parent=styles["Heading1"], fontName=_BODY_FONT_BOLD,
        fontSize=28, alignment=1, spaceAfter=24, textColor=colors.HexColor("#0ea5a4"),
    )
    subtitle_style = ParagraphStyle(
        "Subtitle", parent=styles["Heading2"], fontName=_BODY_FONT,
        fontSize=14, alignment=1, spaceAfter=12, textColor=colors.HexColor("#475569"),
    )
    body_style = ParagraphStyle(
        "Body", parent=styles["Normal"], fontName=_BODY_FONT, fontSize=11,
        alignment=1, spaceAfter=6,
    )
    story.append(Spacer(1, 2 * inch))
    story.append(Paragraph(f"{branding.APP_NAME} Training Report", title_style))
    story.append(Paragraph(f"Athlete: {athlete_name}", subtitle_style))
    if from_date or to_date:
        dr = f"{from_date or 'beginning'} → {to_date or 'today'}"
        story.append(Paragraph(f"Date range: {dr}", body_style))
    story.append(Spacer(1, 0.5 * inch))
    story.append(HRFlowable(width="50%", color=colors.HexColor("#cbd5e1")))
    story.append(Spacer(1, 0.3 * inch))
    story.append(Paragraph(f"<b>{total_workouts}</b> workouts", body_style))
    story.append(Paragraph(f"<b>{strength_sets}</b> strength sets logged", body_style))
    story.append(Paragraph(f"<b>{cardio_sessions}</b> cardio sessions", body_style))
    story.append(Spacer(1, 1 * inch))
    story.append(Paragraph(
        "Your data is yours — Zealova will never lock you in.",
        ParagraphStyle("Footer", parent=body_style, fontSize=9, textColor=colors.gray),
    ))
    story.append(PageBreak())
    return story


def _log_pages(strength: List[CanonicalSetRow], styles) -> List:
    story: List = []
    h = ParagraphStyle(
        "H2", parent=styles["Heading2"], fontName=_BODY_FONT_BOLD, fontSize=16,
    )
    story.append(Paragraph("Week-by-Week Log", h))
    story.append(Spacer(1, 6))

    # Group strength by (exercise, date) → best set row for condensed log.
    # Storing every set in the PDF bloats the file; one top-set per exercise
    # per day is the readable version that fits on paper.
    by_date_ex: Dict[Tuple[date, str], Tuple[float, int, float]] = {}
    for r in strength:
        if r.weight_kg is None or r.reps is None:
            continue
        name = (r.exercise_name_canonical or r.exercise_name_raw or "").strip()
        if not name:
            continue
        key = (r.performed_at.date(), name)
        vol = float(r.weight_kg) * int(r.reps)
        existing = by_date_ex.get(key)
        if existing is None or (r.weight_kg, r.reps) > (existing[0], existing[1]):
            by_date_ex[key] = (float(r.weight_kg), int(r.reps), existing[2] + vol if existing else vol)
        else:
            # Add volume even if this isn't the top set.
            prev = by_date_ex[key]
            by_date_ex[key] = (prev[0], prev[1], prev[2] + vol)

    header_row = ["Date", "Exercise", "Top Set (kg × reps)", "Volume (kg)"]
    data = [header_row]
    for (d, ex), (w, reps, vol) in sorted(by_date_ex.items()):
        data.append([d.isoformat(), ex, f"{w:.1f} × {reps}", f"{vol:.0f}"])

    if len(data) == 1:
        data.append(["(no strength data in this range)", "", "", ""])

    t = Table(data, repeatRows=1, colWidths=[1.1 * inch, 2.7 * inch, 1.7 * inch, 1.1 * inch])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0ea5a4")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), _BODY_FONT_BOLD),
        ("FONTNAME", (0, 1), (-1, -1), _BODY_FONT),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#cbd5e1")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f8fafc")]),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    story.append(t)
    story.append(PageBreak())
    return story


def _pr_page(strength: List[CanonicalSetRow], styles) -> List:
    story: List = []
    h = ParagraphStyle(
        "H2", parent=styles["Heading2"], fontName=_BODY_FONT_BOLD, fontSize=16,
    )
    story.append(Paragraph("Personal Record Highlights", h))
    story.append(Spacer(1, 6))

    best = _top_sets_per_exercise(strength)
    ranked = sorted(
        best.items(),
        key=lambda kv: _epley(kv[1][0], kv[1][1]),
        reverse=True,
    )
    data = [["Exercise", "Top Set", "Est. 1RM", "Date"]]
    for ex, (w, reps, d) in ranked[:30]:
        data.append([ex, f"{w:.1f} kg × {reps}", f"{_epley(w, reps):.1f} kg", d.isoformat()])

    if len(data) == 1:
        data.append(["(no PR-shaped rows)", "", "", ""])

    t = Table(data, repeatRows=1, colWidths=[2.7 * inch, 1.7 * inch, 1.1 * inch, 1.1 * inch])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#f59e0b")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), _BODY_FONT_BOLD),
        ("FONTNAME", (0, 1), (-1, -1), _BODY_FONT),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#cbd5e1")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#fff7ed")]),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    story.append(t)
    story.append(PageBreak())
    return story


def _charts_page(strength: List[CanonicalSetRow], styles) -> List:
    story: List = []
    h = ParagraphStyle(
        "H2", parent=styles["Heading2"], fontName=_BODY_FONT_BOLD, fontSize=16,
    )
    story.append(Paragraph("Training Volume by Week", h))
    story.append(Spacer(1, 12))

    weekly = _weekly_volume(strength)
    if weekly:
        max_bars = 26         # last 26 weeks fits on the page; older is truncated
        weekly = weekly[-max_bars:]

        drawing = Drawing(6.5 * inch, 2.8 * inch)
        chart = VerticalBarChart()
        chart.x = 40
        chart.y = 30
        chart.width = 6.0 * inch
        chart.height = 2.0 * inch
        chart.data = [[v for _, v in weekly]]
        chart.categoryAxis.categoryNames = [w for w, _ in weekly]
        chart.categoryAxis.labels.angle = 45
        chart.categoryAxis.labels.fontName = _BODY_FONT
        chart.categoryAxis.labels.fontSize = 6
        chart.categoryAxis.labels.dy = -8
        chart.valueAxis.labels.fontName = _BODY_FONT
        chart.valueAxis.labels.fontSize = 7
        chart.valueAxis.valueMin = 0
        chart.bars[0].fillColor = colors.HexColor("#0ea5a4")
        drawing.add(chart)
        story.append(drawing)
    else:
        story.append(Paragraph("(no strength data for chart)", styles["Normal"]))

    story.append(Spacer(1, 24))
    story.append(Paragraph("Top-Set Progression (Top 3 Exercises)", h))
    story.append(Spacer(1, 12))

    # Pick the 3 exercises with the most data points for the progression chart.
    by_ex_series: Dict[str, List[Tuple[date, float]]] = defaultdict(list)
    for r in strength:
        if r.weight_kg is None:
            continue
        name = (r.exercise_name_canonical or r.exercise_name_raw or "").strip()
        if not name:
            continue
        by_ex_series[name].append((r.performed_at.date(), float(r.weight_kg)))

    top3 = sorted(by_ex_series.items(), key=lambda kv: len(kv[1]), reverse=True)[:3]
    if top3 and any(len(s) >= 2 for _, s in top3):
        # Build a date axis from the union of all series dates.
        all_dates = sorted({d for _, s in top3 for d, _ in s})
        label_stride = max(1, len(all_dates) // 10)
        date_labels = [d.isoformat() if i % label_stride == 0 else "" for i, d in enumerate(all_dates)]

        drawing = Drawing(6.5 * inch, 2.8 * inch)
        chart = HorizontalLineChart()
        chart.x = 40
        chart.y = 30
        chart.width = 6.0 * inch
        chart.height = 2.0 * inch
        palette = [colors.HexColor("#0ea5a4"), colors.HexColor("#f59e0b"), colors.HexColor("#8b5cf6")]
        chart.data = []
        for i, (ex, series) in enumerate(top3):
            # Map each exercise's top-set-per-date onto the shared date axis.
            daily_max: Dict[date, float] = defaultdict(float)
            for d, w in series:
                if w > daily_max[d]:
                    daily_max[d] = w
            row = [daily_max.get(d, 0.0) for d in all_dates]
            chart.data.append(row)
            chart.lines[i].strokeColor = palette[i % len(palette)]
            chart.lines[i].strokeWidth = 1.5
        chart.categoryAxis.categoryNames = date_labels
        chart.categoryAxis.labels.angle = 45
        chart.categoryAxis.labels.fontName = _BODY_FONT
        chart.categoryAxis.labels.fontSize = 6
        chart.categoryAxis.labels.dy = -8
        chart.valueAxis.labels.fontName = _BODY_FONT
        chart.valueAxis.labels.fontSize = 7
        drawing.add(chart)
        story.append(drawing)
        story.append(Spacer(1, 6))
        legend = ", ".join(ex for ex, _ in top3)
        story.append(Paragraph(f"Series: {legend}", styles["Normal"]))
    else:
        story.append(Paragraph("(need at least two sessions to plot progression)", styles["Normal"]))
    return story


def export_pdf(
    strength_rows: List[CanonicalSetRow],
    cardio_rows: List[CanonicalCardioRow],
    athlete_name: str = "Athlete",
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
) -> bytes:
    _register_unicode_font()

    buf = io.BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=LETTER,
        leftMargin=0.5 * inch, rightMargin=0.5 * inch,
        topMargin=0.6 * inch, bottomMargin=0.6 * inch,
        title=f"{branding.APP_NAME} Training Report — {athlete_name}",
        author=branding.APP_NAME,
    )
    styles = getSampleStyleSheet()

    total_workouts = len({r.performed_at.date() for r in strength_rows}) + \
                     len({r.performed_at.date() for r in cardio_rows})

    story: List = []
    story.extend(_cover_page(
        athlete_name=athlete_name,
        from_date=from_date,
        to_date=to_date,
        total_workouts=total_workouts,
        strength_sets=len(strength_rows),
        cardio_sessions=len(cardio_rows),
        styles=styles,
    ))
    story.extend(_log_pages(strength_rows, styles))
    story.extend(_pr_page(strength_rows, styles))
    story.extend(_charts_page(strength_rows, styles))

    doc.build(story)
    return buf.getvalue()
