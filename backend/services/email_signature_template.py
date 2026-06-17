"""Zealova signature email template — the ONE design every email follows.

Table-based + inline-CSS builders mirroring `docs/planning/redesign-2026-06/
weekly_progress_email_v3.html`: orange top rail, header, avatar greeting, rounded
hero card, Google-Health day rings, rounded metric-card grid with pill delta chips,
coach card, pill CTA, official Discord/Instagram/Reddit footer.

Design system (see `feedback_email_design_system`):
- Anton hero numerals/heads, Barlow Condensed uppercase labels, Fraunces italic
  greeting/coach — with Impact/Arial-Narrow/Georgia fallbacks for Outlook.
- Single orange accent (#F0531E): top rail, positive deltas, coach rail, rings,
  one pill CTA. Everything else white/grey on near-black. ZERO emoji — Lucide
  monoline icons only.

Day rings + tile icons are inline SVG (renders in Apple Mail/iOS/modern Gmail;
falls back gracefully in Outlook — accepted per the user's call).
"""
from __future__ import annotations

from typing import List, Optional, Tuple

# ── palette ──
ACCENT = "#F0531E"
ACCENT_BG = "#2a1712"          # faint-orange chip bg (hex, Outlook-safe)
ACCENT_TRACK = "#3a1f12"       # best-day ring track
BG = "#0b0b0c"
CARD = "#141417"
CHIP = "#1c1c22"
LINE = "#1f1f25"
INK = "#f3f3f4"
GREY = "#8a8a90"
FAINT = "#5b5b62"
TRACK = "#232328"

# ── font stacks (web font + Outlook fallback) ──
F_DISP = "'Anton',Impact,'Arial Narrow Bold',sans-serif"
F_LBL = "'Barlow Condensed','Arial Narrow',Arial,sans-serif"
F_SERIF = "'Fraunces',Georgia,'Times New Roman',serif"

FONT_LINK = ("https://fonts.googleapis.com/css2?family=Anton&"
             "family=Barlow+Condensed:wght@600;700&"
             "family=Fraunces:ital,wght@1,400;1,500&display=swap")

# ── Lucide icon inner-SVG (24x24, stroke=currentColor via wrapper) ──
ICON_PATHS = {
    "foot": '<path d="M4 16v-2.38C4 11.5 2.97 10.5 3 8c.03-2.72 1.49-6 4.5-6C9.37 2 10 3.8 10 5.5c0 3.11-2 5.66-2 8.68V16a2 2 0 1 1-4 0Z"/><path d="M20 20v-2.38c0-2.12 1.03-3.12 1-5.62-.03-2.72-1.49-6-4.5-6C14.63 6 14 7.8 14 9.5c0 3.11 2 5.66 2 8.68V20a2 2 0 1 0 4 0Z"/><path d="M16 17h4"/><path d="M4 13h4"/>',
    "pin": '<path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/>',
    "activity": '<path d="M22 12h-4l-3 9L9 3l-3 9H2"/>',
    "timer": '<line x1="10" y1="2" x2="14" y2="2"/><line x1="12" y1="14" x2="15" y2="11"/><circle cx="12" cy="14" r="8"/>',
    "moon": '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>',
    "heart": '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>',
    "scale": '<circle cx="12" cy="5" r="3"/><path d="M6.5 8a2 2 0 0 0-1.905 1.46L2.1 18.5A2 2 0 0 0 4 21h16a2 2 0 0 0 1.925-2.54L19.4 9.5A2 2 0 0 0 17.48 8Z"/>',
    "dumbbell": '<path d="M14.4 14.4 9.6 9.6"/><path d="M18.657 21.485a2 2 0 1 1-2.829-2.828l-1.767 1.768a2 2 0 1 1-2.829-2.829l6.364-6.364a2 2 0 1 1 2.829 2.829l-1.768 1.767a2 2 0 1 1 2.828 2.829z"/><path d="m21.5 21.5-1.4-1.4"/><path d="M3.9 3.9 2.5 2.5"/><path d="M6.404 12.768a2 2 0 1 1-2.829-2.829l1.768-1.767a2 2 0 1 1-2.828-2.829l2.828-2.828a2 2 0 1 1 2.829 2.828l1.767-1.768a2 2 0 1 1 2.829 2.829z"/>',
    "bars": '<path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>',
    "utensils": '<path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/>',
    "leaf": '<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/>',
    "salad": '<path d="M7 21h10"/><path d="M12 21a9 9 0 0 0 9-9H3a9 9 0 0 0 9 9Z"/><path d="M11.38 12a2.4 2.4 0 0 1-.4-4.77 2.4 2.4 0 0 1 3.2-2.77 2.4 2.4 0 0 1 3.47-.63 2.4 2.4 0 0 1 3.37 3.37 2.4 2.4 0 0 1-1.1 3.7 2.51 2.51 0 0 1 .03 1.1"/><path d="m13 12 4-4"/>',
    "flame": '<path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/>',
    "trophy": '<path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/>',
    "medal": '<path d="M7.21 15 2.66 7.14a2 2 0 0 1 .13-2.2L4.4 2.8A2 2 0 0 1 6 2h12a2 2 0 0 1 1.6.8l1.6 2.14a2 2 0 0 1 .14 2.2L16.79 15"/><path d="M11 12 5.12 2.2"/><path d="m13 12 5.88-9.8"/><path d="M8 7h8"/><circle cx="12" cy="17" r="5"/><path d="M12 18v-2h-.5"/>',
}
_STAR = '<path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>'

# Official brand glyphs (single fill path) — Discord, Instagram, Reddit.
_SOCIAL = {
    "discord": '<path d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"/>',
    "instagram": '<path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.015 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.015 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>',
    "reddit": '<path d="M12 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0zm5.01 4.744c.688 0 1.25.561 1.25 1.249a1.25 1.25 0 0 1-2.498.056l-2.597-.547-.8 3.747c1.824.07 3.48.632 4.674 1.488.308-.309.73-.491 1.207-.491.968 0 1.754.786 1.754 1.754 0 .716-.435 1.333-1.01 1.614a3.111 3.111 0 0 1 .042.52c0 2.694-3.13 4.87-7.004 4.87-3.874 0-7.004-2.176-7.004-4.87 0-.183.015-.366.043-.534A1.748 1.748 0 0 1 4.028 12c0-.968.786-1.754 1.754-1.754.463 0 .898.196 1.207.49 1.207-.883 2.878-1.43 4.744-1.487l.885-4.182a.342.342 0 0 1 .14-.197.35.35 0 0 1 .238-.042l2.906.617a1.214 1.214 0 0 1 1.108-.701zM9.25 12C8.561 12 8 12.562 8 13.25c0 .687.561 1.248 1.25 1.248.687 0 1.248-.561 1.248-1.249 0-.688-.561-1.249-1.249-1.249zm5.5 0c-.687 0-1.248.561-1.248 1.25 0 .687.561 1.248 1.249 1.248.688 0 1.249-.561 1.249-1.249 0-.687-.562-1.249-1.25-1.249zm-5.466 3.99a.327.327 0 0 0-.231.094.33.33 0 0 0 0 .463c.842.842 2.484.913 2.961.913.477 0 2.105-.056 2.961-.913a.361.361 0 0 0 .029-.463.33.33 0 0 0-.464 0c-.547.533-1.684.73-2.512.73-.828 0-1.979-.196-2.512-.73a.326.326 0 0 0-.232-.095z"/>',
}

_RING_C = 94.25  # circumference for r=15


def _icon(key: str, size: int, color: str) -> str:
    inner = ICON_PATHS.get(key, ICON_PATHS["activity"])
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" '
            f'stroke="{color}" stroke-width="1.6" stroke-linecap="round" '
            f'stroke-linejoin="round">{inner}</svg>')


def _ring(steps: Optional[int], goal: int, best: bool = False) -> str:
    if steps is None:
        return ('<svg width="40" height="40" viewBox="0 0 40 40">'
                f'<circle cx="20" cy="20" r="15" fill="none" stroke="{TRACK}" '
                'stroke-width="4" stroke-dasharray="2 5"/></svg>')
    frac = max(0.0, min(1.0, steps / goal)) if goal else 0.0
    offset = round(_RING_C * (1 - frac), 1)
    track = ACCENT_TRACK if best else TRACK
    star = (f'<svg x="11" y="11" width="18" height="18" viewBox="0 0 24 24" '
            f'fill="{ACCENT}" stroke="none">{_STAR}</svg>') if best else ""
    return (
        '<svg width="40" height="40" viewBox="0 0 40 40">'
        f'<circle cx="20" cy="20" r="15" fill="none" stroke="{track}" stroke-width="4"/>'
        f'<circle cx="20" cy="20" r="15" fill="none" stroke="{ACCENT}" stroke-width="4" '
        f'stroke-linecap="round" stroke-dasharray="{_RING_C}" stroke-dashoffset="{offset}" '
        f'transform="rotate(-90 20 20)"/>{star}</svg>'
    )


def _lbl(text: str, *, size: int = 12, color: str = GREY, ls: float = 2.0,
         weight: int = 600) -> str:
    return (f'font-family:{F_LBL};text-transform:uppercase;letter-spacing:{ls}px;'
            f'font-size:{size}px;color:{color};font-weight:{weight};')


# ── public builders ──

def section_label(text: str) -> str:
    return (f'<tr><td style="padding:22px 22px 10px;{_lbl(text)}">{text}</td></tr>')


def hero_card(*, icon: str, big: str, caption: str, pills: List[Tuple[str, str]]) -> str:
    """pills: list of (text, dir) where dir ∈ 'up'|'flat'."""
    pill_html = ""
    for text, d in pills:
        if not text:
            continue
        color, bg = (ACCENT, ACCENT_BG) if d == "up" else (GREY, CHIP)
        pill_html += (
            f'<span style="display:inline-block;padding:6px 11px;border-radius:999px;'
            f'{_lbl(text, size=10, ls=1.0, weight=700)}color:{color};background:{bg};'
            f'margin:3px;">{text}</span>'
        )
    return (
        '<tr><td style="padding:14px 22px 0;"><table role="presentation" width="100%" '
        f'cellpadding="0" cellspacing="0" border="0" bgcolor="{CARD}" '
        f'style="background:{CARD};border:1px solid {LINE};border-radius:18px;">'
        '<tr><td align="center" style="padding:26px 18px;">'
        f'<div style="width:48px;height:48px;border-radius:14px;background:{ACCENT_BG};'
        'line-height:48px;margin:0 auto 14px;">'
        f'{_icon(icon, 26, ACCENT)}</div>'
        f'<div style="font-family:{F_DISP};font-size:54px;line-height:1;color:{INK};">{big}</div>'
        f'<div style="{_lbl(caption, size=13, ls=2.5)}margin-top:6px;">{caption}</div>'
        f'<div style="margin-top:14px;">{pill_html}</div>'
        '</td></tr></table></td></tr>'
    )


def day_rings_row(day_steps: List[Tuple[str, Optional[int]]], goal: int,
                  best_label: Optional[str], subline: str) -> str:
    cells = ""
    for label, steps in day_steps:
        is_best = (best_label is not None and label == best_label and steps is not None)
        dcolor = ACCENT if is_best else FAINT
        cells += (
            f'<td align="center" width="14%">{_ring(steps, goal, best=is_best)}'
            f'<div style="{_lbl(label, size=11, ls=0.5)}color:{dcolor};padding-top:7px;">{label}</div></td>'
        )
    return (
        '<tr><td style="padding:20px 16px 4px;"><table role="presentation" width="100%" '
        f'cellpadding="0" cellspacing="0" border="0"><tr>{cells}</tr></table></td></tr>'
        f'<tr><td align="center" style="padding:2px 22px 4px;{_lbl(subline, size=11, ls=1.5)}">{subline}</td></tr>'
    )


def _metric_card(icon: str, value: str, label: str, delta: str, d: str) -> str:
    pill = ""
    if delta:
        color, bg = (ACCENT, ACCENT_BG) if d == "up" else (FAINT, CHIP)
        pill = (f'<div style="display:inline-block;margin-top:11px;padding:5px 9px;'
                f'border-radius:999px;{_lbl(delta, size=10, ls=0.6, weight=700)}'
                f'color:{color};background:{bg};">{delta}</div>')
    return (
        f'<div style="background:{CARD};border:1px solid {LINE};border-radius:15px;'
        'padding:18px 8px;text-align:center;">'
        f'<div style="width:40px;height:40px;border-radius:11px;background:{CHIP};'
        f'line-height:40px;margin:0 auto 11px;">{_icon(icon, 20, GREY)}</div>'
        f'<div style="font-family:{F_DISP};font-size:24px;color:{INK};">{value}</div>'
        f'<div style="{_lbl(label, size=11, ls=1.0)}margin-top:5px;">{label}</div>'
        f'{pill}</div>'
    )


def metric_grid(tiles: List) -> str:
    """tiles: objects with .icon .value .label .delta .dir."""
    if not tiles:
        return ""
    rows_html = ""
    for i in range(0, len(tiles), 3):
        chunk = tiles[i:i + 3]
        cells = ""
        for t in chunk:
            cells += (f'<td width="33.33%" valign="top" style="padding:4px;">'
                      f'{_metric_card(t.icon, t.value, t.label, t.delta, t.dir)}</td>')
        for _ in range(3 - len(chunk)):
            cells += '<td width="33.33%" style="padding:4px;"></td>'
        rows_html += f'<tr>{cells}</tr>'
    return ('<tr><td style="padding:0 18px;"><table role="presentation" width="100%" '
            f'cellpadding="0" cellspacing="0" border="0">{rows_html}</table></td></tr>')


def awards_block(awards: List) -> str:
    """awards: objects with .icon .title .detail."""
    if not awards:
        return ""
    n = len(awards)
    head = f"{n} milestone{'s' if n != 1 else ''} this week"
    rows = ""
    for a in awards:
        rows += (
            f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" '
            f'border="0" bgcolor="{CARD}" style="background:{CARD};border:1px solid {LINE};'
            f'border-left:3px solid {ACCENT};margin-bottom:8px;"><tr>'
            f'<td width="44" align="center" valign="middle" style="padding:13px 0 13px 14px;">'
            f'{_icon(a.icon, 22, ACCENT)}</td>'
            f'<td valign="middle" style="padding:13px 15px 13px 11px;">'
            f'<div style="{_lbl(a.title, size=14, ls=1.5, weight=700)}color:{INK};">{a.title}</div>'
            f'<div style="font-family:{F_LBL};font-size:13px;color:{GREY};margin-top:2px;'
            f'letter-spacing:.3px;">{a.detail}</div></td></tr></table>'
        )
    return (f'<tr><td style="padding:8px 22px 0;{_lbl(head)}">{head}</td></tr>'
            f'<tr><td style="padding:10px 22px 0;">{rows}</td></tr>')


def callout(text_html: str, link_text: str = "", link_url: str = "#") -> str:
    link = (f'<a href="{link_url}" style="{_lbl(link_text, size=12, ls=1.5, weight=700)}'
            f'color:{ACCENT};text-decoration:none;display:inline-block;margin-top:8px;">'
            f'{link_text}</a>') if link_text else ""
    return ('<tr><td style="padding:18px 22px 0;"><div style="border-left:2px solid '
            f'{ACCENT};padding:4px 0 4px 14px;"><div style="font-family:{F_LBL};'
            f'font-size:15px;line-height:1.45;color:{INK};letter-spacing:.3px;">{text_html}</div>'
            f'{link}</div></td></tr>')


def coach_card(name: str, message: str, avatar: str = "") -> str:
    if not message:
        return ""
    av = (avatar or (name[:1] if name else "Z")).upper()
    return (
        '<tr><td style="padding:18px 22px 0;"><table role="presentation" width="100%" '
        f'cellpadding="0" cellspacing="0" border="0" bgcolor="{CARD}" style="background:{CARD};'
        f'border:1px solid {LINE};border-left:3px solid {ACCENT};"><tr>'
        '<td width="50" valign="top" style="padding:15px 0 15px 14px;">'
        f'<table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>'
        f'<td width="34" height="34" align="center" valign="middle" bgcolor="{ACCENT}" '
        f'style="width:34px;height:34px;background:{ACCENT};font-family:{F_DISP};'
        f'font-size:15px;color:{BG};">{av}</td></tr></table></td>'
        f'<td valign="top" style="padding:15px 16px 15px 11px;">'
        f'<div style="{_lbl(name, size=11, ls=1.5)}margin-bottom:4px;">{name}</div>'
        f'<div style="font-family:{F_SERIF};font-style:italic;font-size:15px;line-height:1.45;'
        f'color:{INK};">{message}</div></td></tr></table></td></tr>'
    )


def pill_cta(text: str, url: str) -> str:
    return (
        '<tr><td style="padding:24px 22px 4px;"><table role="presentation" width="100%" '
        'cellpadding="0" cellspacing="0" border="0"><tr>'
        f'<td align="center" bgcolor="{ACCENT}" style="background:{ACCENT};border-radius:999px;">'
        f'<a href="{url}" style="display:block;padding:16px;{_lbl(text, size=15, ls=2.0, weight=700)}'
        f'color:{BG};text-decoration:none;">{text}</a></td></tr></table></td></tr>'
    )


def _footer(unsubscribe_url: Optional[str], category_label: str) -> str:
    socials = ""
    for name in ("discord", "instagram", "reddit"):
        socials += (f'<td style="padding:0 9px;"><a href="#" style="color:{GREY};">'
                    f'<svg width="20" height="20" viewBox="0 0 24 24" fill="{GREY}">'
                    f'{_SOCIAL[name]}</svg></a></td>')
    unsub = unsubscribe_url or "#"
    return (
        f'<tr><td height="1" bgcolor="{LINE}" style="height:1px;line-height:1px;font-size:1px;'
        'padding-top:18px;">&nbsp;</td></tr>'
        '<tr><td align="center" style="padding:18px 22px 24px;">'
        '<table role="presentation" cellpadding="0" cellspacing="0" border="0">'
        f'<tr>{socials}</tr></table>'
        f'<div style="{_lbl("", size=11, ls=0.6, weight=600)}color:{FAINT};line-height:1.7;'
        'padding-top:12px;">You\'re getting this because weekly reports are on.<br>'
        f'<a href="{unsub}" style="color:{FAINT};text-decoration:underline;">Turn off {category_label}</a> '
        f'&middot; <a href="{unsub}" style="color:{FAINT};text-decoration:underline;">Unsubscribe</a> '
        '&middot; Zealova</div></td></tr>'
    )


def signature_email(*, header_tag: str, greeting: str, greeting_sub: str,
                    avatar: str, body_html: str, unsubscribe_url: Optional[str] = None,
                    category_label: str = "weekly reports",
                    preheader: str = "") -> str:
    """Wrap body fragments in the signature chrome → full HTML doc."""
    av = (avatar or (greeting[:1] if greeting else "Z")).upper()
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="color-scheme" content="dark"><meta name="supported-color-schemes" content="dark">
<link href="{FONT_LINK}" rel="stylesheet">
</head>
<body style="margin:0;padding:0;background:#060607;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;">{preheader}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#060607" style="background:#060607;">
<tr><td align="center" style="padding:0 10px 40px;">
<table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" bgcolor="{BG}" style="width:600px;max-width:600px;background:{BG};border:1px solid {LINE};">
  <tr><td height="3" bgcolor="{ACCENT}" style="height:3px;line-height:3px;font-size:3px;">&nbsp;</td></tr>
  <tr><td style="padding:24px 22px 16px;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
    <td align="left" style="{_lbl('Zealova', size=16, ls=3.0, weight=700)}color:{INK};">Zealova</td>
    <td align="right" style="{_lbl(header_tag, size=12, ls=2.0)}color:{FAINT};">{header_tag}</td>
  </tr></table></td></tr>
  <tr><td height="1" bgcolor="{LINE}" style="height:1px;line-height:1px;font-size:1px;">&nbsp;</td></tr>
  <tr><td style="padding:20px 22px 2px;"><table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
    <td width="54" valign="middle"><table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
      <td width="42" height="42" align="center" valign="middle" bgcolor="{ACCENT}" style="width:42px;height:42px;background:{ACCENT};border-radius:50%;font-family:{F_DISP};font-size:19px;color:{BG};">{av}</td>
    </tr></table></td>
    <td valign="middle" style="padding-left:13px;">
      <div style="font-family:{F_SERIF};font-style:italic;font-size:23px;color:{INK};">{greeting}</div>
      <div style="{_lbl(greeting_sub, size=12, ls=1.5)}color:{FAINT};margin-top:2px;">{greeting_sub}</div>
    </td>
  </tr></table></td></tr>
  {body_html}
  {_footer(unsubscribe_url, category_label)}
</table>
</td></tr></table>
</body></html>"""
