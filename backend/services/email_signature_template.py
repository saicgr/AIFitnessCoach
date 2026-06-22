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

Tile/feature/hero/social icons are HOSTED PNGs served from S3 (`_icon` + `_footer`
emit `<img>`). Gmail — web and app, the majority of recipients — STRIPS inline
`<svg>`, so the previous inline-SVG icons rendered as empty boxes there; PNGs render
everywhere. Regenerate the asset set with `scripts/generate_email_icons.py` after
adding any key to `ICON_PATHS` / `_SOCIAL`. (Day rings remain inline SVG — they are
dynamic progress arcs and appear only in stats/workout emails, never transactional.)
"""
from __future__ import annotations

from typing import List, Optional, Tuple

from core import branding

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
    # ── transactional / security / lifecycle glyphs (Lucide, zero-emoji rule) ──
    "lock": '<rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
    "bell": '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
    "shield": '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
    "shield_check": '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>',
    "mail": '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
    "check_circle": '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="m9 11 3 3L22 4"/>',
    "credit_card": '<rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/>',
    "alert": '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
    "gift": '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13"/><path d="M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7"/><path d="M7.5 8a2.5 2.5 0 0 1 0-5A4.8 8 0 0 1 12 8a4.8 8 0 0 1 4.5-5 2.5 2.5 0 0 1 0 5"/>',
    "calendar": '<rect width="18" height="18" x="3" y="4" rx="2" ry="2"/><line x1="16" x2="16" y1="2" y2="6"/><line x1="8" x2="8" y1="2" y2="6"/><line x1="3" x2="21" y1="10" y2="10"/>',
    "sparkles": '<path d="m12 3-1.9 5.8a2 2 0 0 1-1.3 1.3L3 12l5.8 1.9a2 2 0 0 1 1.3 1.3L12 21l1.9-5.8a2 2 0 0 1 1.3-1.3L21 12l-5.8-1.9a2 2 0 0 1-1.3-1.3Z"/>',
    "clock": '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
    "user": '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
    "smartphone": '<rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><path d="M12 18h.01"/>',
    "message": '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>',
    "trending_up": '<polyline points="22 7 13.5 15.5 8.5 10.5 2 17"/><polyline points="16 7 22 7 22 13"/>',
    "zap": '<path d="M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"/>',
    "x_circle": '<circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/>',
}

# ── Kinetic (CSS-only) interactivity injected into the <head>. JS is stripped by
# every mail client, so interactivity is hover + the checkbox/radio :checked hack +
# scroll-snap. It enhances Apple Mail / iOS Mail / Samsung Mail and DEGRADES
# GRACEFULLY everywhere else: accordions default to OPEN (fallback), and only
# collapse inside the WebKit media query, so Gmail/Outlook never trap content.
# Tabs emit their own per-instance <style> (see `tabs()`); their fallback is all
# panels stacked. See docs/.../email_proofs/AMP_TRACK.md for the AMP path.
KINETIC_CSS = (
    "a.cta{transition:filter .18s ease,transform .18s ease;}"
    "a.cta:hover{filter:brightness(1.10);transform:translateY(-1px);}"
    ".tabin{position:absolute;opacity:0;height:0;width:0;}"
    ".accin{position:absolute;opacity:0;height:0;width:0;}"
    f".acc-head{{display:flex;align-items:center;justify-content:space-between;cursor:pointer;}}"
    f".acc-head .chev{{color:{ACCENT};font-size:14px;transition:transform .3s ease;}}"
    ".acc-panel{max-height:1400px;overflow:hidden;transition:max-height .35s ease;}"
    "@media screen and (-webkit-min-device-pixel-ratio:0){"
    ".acc-panel{max-height:0;}"
    ".accin:checked ~ .acc-panel{max-height:1400px;}}"
    ".accin:checked ~ .acc-head .chev{transform:rotate(90deg);}"
    ".caro{display:flex;gap:12px;overflow-x:auto;scroll-snap-type:x mandatory;"
    "-webkit-overflow-scrolling:touch;}"
    ".caro > div{scroll-snap-align:center;}"
    f".tab-bar label:hover{{color:{INK};}}"
)
_STAR = '<path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>'

# Official brand glyphs (single fill path) — Discord, Instagram, Reddit.
_SOCIAL = {
    "discord": '<path d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"/>',
    "instagram": '<path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.015 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.015 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>',
    "reddit": '<path d="M12 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0zm5.01 4.744c.688 0 1.25.561 1.25 1.249a1.25 1.25 0 0 1-2.498.056l-2.597-.547-.8 3.747c1.824.07 3.48.632 4.674 1.488.308-.309.73-.491 1.207-.491.968 0 1.754.786 1.754 1.754 0 .716-.435 1.333-1.01 1.614a3.111 3.111 0 0 1 .042.52c0 2.694-3.13 4.87-7.004 4.87-3.874 0-7.004-2.176-7.004-4.87 0-.183.015-.366.043-.534A1.748 1.748 0 0 1 4.028 12c0-.968.786-1.754 1.754-1.754.463 0 .898.196 1.207.49 1.207-.883 2.878-1.43 4.744-1.487l.885-4.182a.342.342 0 0 1 .14-.197.35.35 0 0 1 .238-.042l2.906.617a1.214 1.214 0 0 1 1.108-.701zM9.25 12C8.561 12 8 12.562 8 13.25c0 .687.561 1.248 1.25 1.248.687 0 1.248-.561 1.248-1.249 0-.688-.561-1.249-1.249-1.249zm5.5 0c-.687 0-1.248.561-1.248 1.25 0 .687.561 1.248 1.249 1.248.688 0 1.249-.561 1.249-1.249 0-.687-.562-1.249-1.25-1.249zm-5.466 3.99a.327.327 0 0 0-.231.094.33.33 0 0 0 0 .463c.842.842 2.484.913 2.961.913.477 0 2.105-.056 2.961-.913a.361.361 0 0 0 .029-.463.33.33 0 0 0-.464 0c-.547.533-1.684.73-2.512.73-.828 0-1.979-.196-2.512-.73a.326.326 0 0 0-.232-.095z"/>',
}

_RING_C = 94.25  # circumference for r=15


# Color hex → S3 palette folder (see scripts/generate_email_icons.py). Only the
# two palette colors are ever passed to `_icon`; anything else falls back to accent.
_ICON_FOLDER = {ACCENT.lower(): "accent", GREY.lower(): "grey"}


def _icon_base() -> str:
    """Public S3 base for the email icon PNGs (lazy so import never needs settings)."""
    from core.config import get_settings
    return get_settings().email_icon_base_url.rstrip("/")


def _icon(key: str, size: int, color: str) -> str:
    """Hosted-PNG monoline icon. Renders in Gmail (inline SVG does NOT — see module
    docstring). Inline-block + vertical-align:middle so it centers inside the chip
    wrappers (which carry text-align:center + line-height)."""
    if key not in ICON_PATHS:
        key = "activity"
    folder = _ICON_FOLDER.get((color or "").lower(), "accent")
    return (
        f'<img src="{_icon_base()}/{folder}/{key}.png" width="{size}" height="{size}" '
        f'alt="" style="display:inline-block;vertical-align:middle;border:0;outline:none;'
        f'text-decoration:none;-ms-interpolation-mode:bicubic;">'
    )


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
        'line-height:48px;text-align:center;margin:0 auto 14px;">'
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
        f'line-height:40px;text-align:center;margin:0 auto 11px;">{_icon(icon, 20, GREY)}</div>'
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
        f'<a class="cta" href="{url}" style="display:block;padding:16px;{_lbl(text, size=15, ls=2.0, weight=700)}'
        f'color:{BG};text-decoration:none;">{text}</a></td></tr></table></td></tr>'
    )


# ── transactional / interactive builders ──

def hero(*, title: str, sub: str = "", icon: str = "") -> str:
    """Centered Anton hero for transactional emails (no persona/avatar greeting)."""
    icon_html = (
        f'<div style="width:56px;height:56px;border-radius:16px;background:{ACCENT_BG};'
        f'line-height:56px;text-align:center;margin:0 auto 20px;">{_icon(icon, 28, ACCENT)}</div>'
    ) if icon else ""
    sub_html = (
        f'<div style="font-family:{F_SERIF};font-style:italic;font-size:18px;color:{GREY};'
        f'margin-top:14px;line-height:1.5;">{sub}</div>'
    ) if sub else ""
    return (
        f'<tr><td align="center" style="padding:40px 36px 8px;">{icon_html}'
        f'<div style="font-family:{F_DISP};font-size:40px;line-height:1.06;color:{INK};'
        f'letter-spacing:.5px;text-transform:uppercase;">{title}</div>{sub_html}</td></tr>'
    )


def info_row(icon: str, title: str, detail: str) -> str:
    """Signature feature row — orange-accented Lucide icon + bold title + grey detail.
    The zero-emoji replacement for the old emoji feature rows."""
    return (
        f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" '
        f'bgcolor="{CARD}" style="background:{CARD};border:1px solid {LINE};'
        f'border-left:3px solid {ACCENT};margin-bottom:8px;"><tr>'
        f'<td width="46" align="center" valign="middle" style="padding:14px 0 14px 14px;">'
        f'{_icon(icon, 22, ACCENT)}</td>'
        f'<td valign="middle" style="padding:14px 16px 14px 12px;">'
        f'<div style="{_lbl(title, size=14, ls=1.5, weight=700)}color:{INK};">{title}</div>'
        f'<div style="font-family:{F_LBL};font-size:13px;color:{GREY};margin-top:2px;'
        f'letter-spacing:.3px;">{detail}</div></td></tr></table>'
    )


def info_rows(items: List[Tuple[str, str, str]]) -> str:
    """Wrap a list of (icon, title, detail) into a padded <tr> of info_rows."""
    if not items:
        return ""
    inner = "".join(info_row(i, t, d) for i, t, d in items)
    return f'<tr><td style="padding:22px 22px 4px;">{inner}</td></tr>'


def plan_recap(items: List[Tuple[str, str, str]], *, heading: str = "Your plan so far") -> str:
    """Onboarding-answer recap card — (icon_key, label, value) rows in a single
    accent-railed card. Rendered in the verification email so the user sees the
    plan they just built. Returns "" when empty (no card, no heading)."""
    if not items:
        return ""
    rows = ""
    for i, (icon, label, value) in enumerate(items):
        border = "" if i == len(items) - 1 else f"border-bottom:1px solid {LINE};"
        rows += (
            f'<tr><td width="44" align="center" valign="middle" '
            f'style="padding:13px 0 13px 14px;{border}">{_icon(icon, 20, ACCENT)}</td>'
            f'<td valign="middle" style="padding:13px 16px;{border}">'
            f'<span style="{_lbl(label, size=11, ls=1.2)}">{label}</span>'
            f'<span style="float:right;font-family:{F_LBL};font-size:14px;color:{INK};'
            f'font-weight:700;letter-spacing:.3px;">{value}</span></td></tr>'
        )
    return (
        section_label(heading) +
        f'<tr><td style="padding:0 22px;"><table role="presentation" width="100%" '
        f'cellpadding="0" cellspacing="0" border="0" bgcolor="{CARD}" style="background:{CARD};'
        f'border:1px solid {LINE};border-left:3px solid {ACCENT};border-radius:14px;">'
        f'{rows}</table></td></tr>'
    )


def detail_block(rows: List[Tuple[str, str]]) -> str:
    """Key/value strip in a rounded card (e.g. security device/time/location)."""
    if not rows:
        return ""
    cells = ""
    for i, (label, value) in enumerate(rows):
        border = "" if i == len(rows) - 1 else f"border-bottom:1px solid {LINE};"
        cells += (
            f'<tr><td style="padding:14px 18px;{border}">'
            f'<span style="{_lbl(label, size=11, ls=1.5)}">{label}</span>'
            f'<span style="float:right;font-family:{F_LBL};font-size:14px;color:{INK};">{value}</span>'
            f'</td></tr>'
        )
    return (
        f'<tr><td style="padding:24px 22px 0;"><table role="presentation" width="100%" '
        f'cellpadding="0" cellspacing="0" border="0" bgcolor="{CARD}" style="background:{CARD};'
        f'border:1px solid {LINE};border-radius:14px;">{cells}</table></td></tr>'
    )


def accordion(head_text: str, panel_html: str, uid: str) -> str:
    """Tap-to-expand row (checkbox :checked hack). Default OPEN in non-WebKit clients
    (graceful), collapsed-with-expand in Apple/iOS Mail — see KINETIC_CSS."""
    return (
        f'<tr><td style="padding:16px 22px 0;">'
        f'<input class="accin" type="checkbox" id="{uid}">'
        f'<label class="acc-head" for="{uid}" style="{_lbl(head_text, size=13, ls=1.5, weight=700)}'
        f'color:{INK};background:{CARD};border:1px solid {LINE};border-radius:12px;padding:14px 16px;">'
        f'{head_text}<span class="chev">&#9656;</span></label>'
        f'<div class="acc-panel"><div style="padding:12px 4px 2px;">{panel_html}</div></div>'
        f'</td></tr>'
    )


def tabs(items: List[Tuple[str, str]], uid: str = "etab") -> str:
    """Tabbed sections (radio :checked hack). items: [(label, panel_html)]; first is
    default. Emits a per-instance <style> (Apple Mail honors it; Gmail strips it →
    all panels render stacked = graceful fallback)."""
    if not items:
        return ""
    n = len(items)
    radios = bar = panels = ""
    for i, (label, _) in enumerate(items):
        rid = f"{uid}{i}"
        radios += (f'<input class="tabin" type="radio" name="{uid}" id="{rid}"'
                   f'{" checked" if i == 0 else ""}>')
        bar += (f'<label for="{rid}" style="flex:1;text-align:center;cursor:pointer;'
                f'{_lbl(label, size=12, ls=1.5, weight=700)}color:{GREY};background:{CHIP};'
                f'border:1px solid {LINE};border-radius:999px;padding:9px 6px;">{label}</label>')
    for i, (_, panel) in enumerate(items):
        panels += f'<div class="tab-panel {uid}p{i}">{panel}</div>'
    hide, act = [], []
    for i in range(n):
        for j in range(n):
            if i != j:
                hide.append(f'#{uid}{i}:checked~.{uid}b .{uid}p{j}')
        act.append(f'#{uid}{i}:checked~.{uid}b label[for="{uid}{i}"]')
    css = (f'<style>.{uid}b .tab-panel{{display:block}}'
           f'{",".join(hide)}{{display:none}}'
           f'{",".join(act)}{{color:{BG};background:{ACCENT};border-color:{ACCENT}}}</style>')
    return (
        f'<tr><td style="padding:8px 22px 0;">{css}{radios}'
        f'<div class="{uid}b"><div class="tab-bar" style="display:flex;gap:6px;padding:8px 0 6px;">'
        f'{bar}</div>{panels}</div></td></tr>'
    )


def carousel(cards: List[str], swipe_hint: str = "Swipe →") -> str:
    """Horizontal scroll-snap carousel. cards: list of inner-HTML strings."""
    if not cards:
        return ""
    cells = "".join(
        f'<div style="flex:0 0 78%;background:{CARD};border:1px solid {LINE};'
        f'border-radius:16px;padding:18px;box-sizing:border-box;">{c}</div>' for c in cards
    )
    hint = (f'<div style="{_lbl(swipe_hint, size=11, ls=1.0)}color:{FAINT};text-align:center;'
            f'padding-top:6px;">{swipe_hint}</div>') if swipe_hint else ""
    return (f'<tr><td style="padding:8px 22px 4px;"><div class="caro">{cells}</div>{hint}</td></tr>')


def _footer(unsubscribe_url: Optional[str], category_label: str, *,
            kind: str = "preference", note: str = "", show_socials: bool = True) -> str:
    """Signature footer.

    kind="preference"  → opt-out line ("you're getting this because {category} are on"
                          + Turn off / Unsubscribe). For lifecycle/marketing/weekly.
    kind="transactional" → no opt-out; renders `note` (e.g. "you received this because
                          an account was created…"). For verify/billing/purchase.
    kind="security"     → no opt-out; renders `note` (security alerts always sent).
    """
    socials = ""
    if show_socials:
        # Real destinations only; no dead links. Hosted-PNG glyphs (inline SVG is
        # stripped by Gmail — see module docstring).
        base = _icon_base()
        social_urls = [
            ("discord", branding.DISCORD_URL),
            ("instagram", branding.INSTAGRAM_URL),
            ("reddit", branding.REDDIT_URL),
        ]
        for name, url in social_urls:
            socials += (
                f'<td style="padding:0 9px;"><a href="{url}">'
                f'<img src="{base}/social/{name}.png" width="20" height="20" '
                f'alt="{name.title()}" style="display:block;border:0;outline:none;'
                f'text-decoration:none;-ms-interpolation-mode:bicubic;"></a></td>'
            )
        socials = ('<table role="presentation" cellpadding="0" cellspacing="0" border="0" '
                   'align="center"><tr>' + socials + '</tr></table>')
    unsub = unsubscribe_url or "#"
    if kind == "preference":
        line = (
            f"You're getting this because {category_label} are on.<br>"
            f'<a href="{unsub}" style="color:{FAINT};text-decoration:underline;">Turn off {category_label}</a> '
            f'&middot; <a href="{unsub}" style="color:{FAINT};text-decoration:underline;">Unsubscribe</a> '
            '&middot; Zealova'
        )
    elif kind == "security":
        line = (note or "Security alerts are always sent and can't be turned off.") + " &middot; Zealova"
    else:  # transactional
        line = (note or "You received this from Zealova.") + " &middot; Zealova"
    return (
        f'<tr><td height="1" bgcolor="{LINE}" style="height:1px;line-height:1px;font-size:1px;'
        'padding-top:18px;">&nbsp;</td></tr>'
        '<tr><td align="center" style="padding:18px 22px 24px;">'
        f'{socials}'
        f'<div style="{_lbl("", size=11, ls=0.6, weight=600)}color:{FAINT};line-height:1.7;'
        f'padding-top:12px;">{line}</div></td></tr>'
    )


def signature_email(*, header_tag: str, greeting: str = "", greeting_sub: str = "",
                    avatar: str = "", body_html: str, unsubscribe_url: Optional[str] = None,
                    category_label: str = "weekly reports",
                    preheader: str = "",
                    hero_title: str = "", hero_sub: str = "", hero_icon: str = "",
                    footer_kind: str = "preference", footer_note: str = "",
                    footer_socials: bool = True) -> str:
    """Wrap body fragments in the signature chrome → full HTML doc.

    Top zone is one of:
      - avatar greeting (pass `greeting`) — motivational/lifecycle/weekly, OR
      - centered Anton hero (pass `hero_title`) — transactional/security.
    Footer adapts via `footer_kind` ("preference" | "transactional" | "security").
    The <head> carries KINETIC_CSS so hover/accordion/carousel work in-inbox.
    """
    if greeting:
        av = (avatar or greeting[:1] or "Z").upper()
        top_zone = (
            '<tr><td style="padding:20px 22px 2px;"><table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>'
            '<td width="54" valign="middle"><table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>'
            f'<td width="42" height="42" align="center" valign="middle" bgcolor="{ACCENT}" style="width:42px;height:42px;background:{ACCENT};border-radius:50%;font-family:{F_DISP};font-size:19px;color:{BG};">{av}</td>'
            '</tr></table></td>'
            '<td valign="middle" style="padding-left:13px;">'
            f'<div style="font-family:{F_SERIF};font-style:italic;font-size:23px;color:{INK};">{greeting}</div>'
            f'<div style="{_lbl(greeting_sub, size=12, ls=1.5)}color:{FAINT};margin-top:2px;">{greeting_sub}</div>'
            '</td></tr></table></td></tr>'
        )
    else:
        top_zone = hero(title=hero_title, sub=hero_sub, icon=hero_icon)
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="color-scheme" content="dark"><meta name="supported-color-schemes" content="dark">
<link href="{FONT_LINK}" rel="stylesheet">
<style>{KINETIC_CSS}</style>
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
  {top_zone}
  {body_html}
  {_footer(unsubscribe_url, category_label, kind=footer_kind, note=footer_note, show_socials=footer_socials)}
</table>
</td></tr></table>
</body></html>"""
