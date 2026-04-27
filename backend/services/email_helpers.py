"""Pure helpers for email/notification personalization.

No DB access here — every function is pure (input → output). The `email_cron.py`
orchestrator populates a `UserStats` from DB, then these helpers turn it into
rendered HTML fragments (persona card, stats grid, social footer, mood emoji).

Kept separate from `email_service.py` so email-template files stay focused on
layout while these stay focused on data → pixels.
"""
from __future__ import annotations
from datetime import datetime
from typing import Optional, Tuple
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from core import branding
from models.email import TimeBand, ScheduleState, CoachStyle, UserStats


# ─── Social URLs (re-exported from core.branding for callers that imported
# them from here historically — single source of truth lives in core/branding.py).

DISCORD_URL = branding.DISCORD_URL
INSTAGRAM_URL = branding.INSTAGRAM_URL

# Icon source — simpleicons.org CDN returns cached, branded SVG/PNG per slug.
# White-on-brand variants by appending /ffffff. Why this vs self-hosted:
# these URLs are stable, heavily cached, and don't need repo binary assets.
# When we self-host, swap to `{backend_url}/static/social/{name}.png`.
DISCORD_ICON_URL = "https://cdn.simpleicons.org/discord/ffffff"
INSTAGRAM_ICON_URL = "https://cdn.simpleicons.org/instagram/ffffff"


# ─── Overdue escalation thresholds (driven by coach_style) ──────────────────
# Days the user has been OVERDUE before the mood/copy escalates. Customizable
# via the user's coach_style preference (user_ai_settings.coaching_style):
#   - GENTLE: never escalates past "Nudging" — no guilt ever, regardless of days.
#   - BALANCED (default): gentle nudge → concerned check-in → disappointed.
#     Two full weeks of runway before the firm tone kicks in.
#   - TOUGH_LOVE: aggressive from day 1. Concerned immediately, Disappointed
#     by day 3 — for users who explicitly opted into harder coaching.
#
# Returned tuple: (nudge_max_days, concerned_max_days).
#   days_overdue <= nudge_max_days        → Nudging
#   days_overdue <= concerned_max_days    → Concerned
#   days_overdue >  concerned_max_days    → Disappointed
def _overdue_thresholds(coach_style: CoachStyle) -> Tuple[int, int]:
    if coach_style == CoachStyle.GENTLE:
        # Effectively infinite — Gentle users never see Concerned/Disappointed.
        return (10**9, 10**9)
    if coach_style == CoachStyle.TOUGH_LOVE:
        return (0, 2)  # day 1+ → Concerned; day 3+ → Disappointed
    # BALANCED default: 3-day nudge window, 13-day concerned window, firm at 14+
    return (3, 13)


def overdue_tier(stats: UserStats) -> str:
    """Return the escalation tier for OVERDUE state: 'nudge' | 'concerned' | 'firm'.

    Pure function of `days_overdue` + `coach_style`. Used by both `persona_mood()`
    and the lifecycle email copy branches so mood emoji and subject line stay
    in sync.
    """
    days = stats.days_overdue or 0
    nudge_max, concerned_max = _overdue_thresholds(stats.coach_style)
    if days <= nudge_max:
        return "nudge"
    if days <= concerned_max:
        return "concerned"
    return "firm"


# ─── Name handling ──────────────────────────────────────────────────────────

def first_name(user: dict) -> str:
    """Extract the user's first name for email personalization.

    Fallback chain (first non-empty wins):
      1. First whitespace-token of `users.name`
      2. First whitespace-token of `users.display_name` (if column exists)
      3. Capitalized alpha-only prefix of `users.email` (before @)
      4. Literal "there" (last resort — should rarely render)

    Why: personalization starts with saying someone's name. "Hi Sai" lands;
    "Hi there" is junk-mail. Never use the full name "Sai Chetan Grandhe" in
    email copy — too formal, reads like a cold list.
    """
    name = (user.get("name") or "").strip()
    if name:
        return name.split()[0]

    display = (user.get("display_name") or "").strip()
    if display:
        return display.split()[0]

    email = (user.get("email") or "").strip()
    if email and "@" in email:
        prefix = email.split("@", 1)[0]
        # Strip non-alpha so "john.doe42" → "johndoe" → "Johndoe"
        clean = "".join(c for c in prefix if c.isalpha())
        if clean:
            return clean.capitalize()

    return "there"


# ─── Time bands (user-local time only) ──────────────────────────────────────

def time_band(
    user_tz: str,
    *,
    quiet_start_hour: int = 22,
    quiet_end_hour: int = 6,
    now: Optional[datetime] = None,
) -> TimeBand:
    """Return the current `TimeBand` in the user's local timezone.

    Args:
        user_tz: IANA timezone string (e.g. "America/Chicago"). Invalid/missing
            falls back to UTC so the helper never crashes on bad data.
        quiet_start_hour / quiet_end_hour: the user's quiet window (hours,
            0-23). Supports overnight wraparound (22→06).
        now: override the current moment, only for tests. Defaults to
            `datetime.now(tz)` — note we never use the timezone-unaware
            variant in logic; the user's device timezone is the source of truth.

    Quiet always wins. If the user's quiet window covers the current clock
    hour, `QUIET` is returned even if it would otherwise be morning/evening.
    """
    try:
        tz = ZoneInfo(user_tz)
    except (ZoneInfoNotFoundError, ValueError, TypeError):
        tz = ZoneInfo("UTC")

    local_now = now.astimezone(tz) if now else datetime.now(tz)
    hour = local_now.hour

    # Quiet window — handle both same-day (e.g. 13→15) and overnight (22→06)
    if quiet_start_hour <= quiet_end_hour:
        in_quiet = quiet_start_hour <= hour < quiet_end_hour
    else:
        in_quiet = hour >= quiet_start_hour or hour < quiet_end_hour
    if in_quiet:
        return TimeBand.QUIET

    if 6 <= hour < 11:
        return TimeBand.MORNING
    if 11 <= hour < 14:
        return TimeBand.MIDDAY
    if 14 <= hour < 18:
        return TimeBand.AFTERNOON
    if 18 <= hour < 21:
        return TimeBand.EVENING
    if hour >= 21:
        return TimeBand.LATE
    # 00-06 outside any configured quiet window (rare) — treat as QUIET
    return TimeBand.QUIET


# ─── Persona mood (drives emoji + mood word on the coach card) ──────────────

def persona_mood(stats: UserStats) -> Tuple[str, str]:
    """Return `(emoji, mood_word)` chosen from the user's current stats.

    Used for the persona signature card at the top of motivational emails.
    Order matters — earlier branches win, so the most specific "bad" states
    are checked before the celebratory ones.
    """
    # Overdue with zero activity. The escalation ramp is driven by the user's
    # coach_style preference so users who picked "gentle" never get guilted and
    # users who picked "balanced" get two weeks of runway before the firm tone.
    # See `_overdue_thresholds()` for the day cutoffs.
    if (
        stats.schedule_state == ScheduleState.OVERDUE
        and stats.workouts_total == 0
    ):
        tier = overdue_tier(stats)
        if tier == "nudge":
            return ("👋", "Nudging")
        if tier == "concerned":
            return ("😰", "Concerned")
        return ("😤", "Disappointed")

    # Launches today, still no action late in the day
    if stats.schedule_state == ScheduleState.LAUNCHES_TODAY and stats.time_band in (
        TimeBand.AFTERNOON,
        TimeBand.EVENING,
        TimeBand.LATE,
    ):
        return ("😰", "Concerned")

    # Launches today, morning band — anticipatory, not yet worried
    if stats.schedule_state == ScheduleState.LAUNCHES_TODAY:
        return ("👀", "Watching")

    # Active user with good streak
    if stats.current_streak_days >= 7:
        return ("👑", "Proud")
    if stats.current_streak_days >= 3:
        return ("💪", "Impressed")

    # Lapsing user — had activity but streak broken
    if stats.workouts_total > 0 and stats.current_streak_days == 0:
        return ("🙄", "Unimpressed")

    # Default — neutral watching
    return ("👀", "Watching")


# ─── Social footer HTML ─────────────────────────────────────────────────────

def build_social_footer_html(
    *,
    unsubscribe_url: Optional[str] = None,
    category_name: Optional[str] = None,
) -> str:
    """Render the Discord + Instagram social footer as email-client-safe HTML.

    Rendered as table rows (`<tr>`) so callers drop it directly into their
    `_build_standard_email()` table. Dark-mode colors match the rest of the
    Zealova email template.

    Args:
        unsubscribe_url: if provided along with `category_name`, renders a
            per-category opt-out link below the social buttons. This is the
            one-click unsubscribe that List-Unsubscribe headers also point to.
        category_name: human label for the category ("streak alerts",
            "motivational check-ins", etc).
    """
    category_line = ""
    if unsubscribe_url and category_name:
        category_line = (
            f'<p style="margin:0 0 8px;font-size:12px;color:#71717a;">'
            f'Getting too many of these? '
            f'<a href="{unsubscribe_url}" style="color:#06b6d4;text-decoration:none;">'
            f"Turn off {category_name}"
            f"</a>"
            f"</p>"
        )

    # Buttons render as icon + label horizontally. Using <img> with explicit
    # width/height and mso-style attributes keeps Outlook from stretching them.
    # Fallback: background color stays branded even if the icon fails to load.
    return f"""<tr>
      <td style="padding:32px 40px 0;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
          <tr><td style="border-top:1px solid #1e1e1e;font-size:0;line-height:0;">&nbsp;</td></tr>
        </table>
      </td>
    </tr>
    <tr>
      <td align="center" style="padding:24px 40px 8px;">
        <p style="margin:0 0 14px;font-size:13px;color:#a1a1aa;font-weight:600;">Hang out with us</p>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin:0 auto;">
          <tr>
            <td style="padding:0 8px;">
              <a href="{DISCORD_URL}" style="display:inline-block;background:#5865F2;color:#ffffff;font-size:14px;font-weight:700;text-decoration:none;padding:10px 22px;border-radius:50px;line-height:20px;">
                <img src="{DISCORD_ICON_URL}" alt="" width="16" height="16" style="display:inline-block;vertical-align:middle;margin-right:8px;border:0;" />
                <span style="vertical-align:middle;">Discord</span>
              </a>
            </td>
            <td style="padding:0 8px;">
              <a href="{INSTAGRAM_URL}" style="display:inline-block;background:linear-gradient(135deg,#833AB4,#FD1D1D,#FCB045);color:#ffffff;font-size:14px;font-weight:700;text-decoration:none;padding:10px 22px;border-radius:50px;line-height:20px;">
                <img src="{INSTAGRAM_ICON_URL}" alt="" width="16" height="16" style="display:inline-block;vertical-align:middle;margin-right:8px;border:0;" />
                <span style="vertical-align:middle;">Instagram</span>
              </a>
            </td>
          </tr>
        </table>
      </td>
    </tr>
    <tr>
      <td align="center" style="padding:14px 40px 0;">{category_line}</td>
    </tr>"""


# ─── Persona signature card (motivational emails only) ──────────────────────

def build_persona_signature_html(stats: UserStats) -> str:
    """Render the named-coach signature card that sits above the headline.

    Only used for motivational/lifecycle emails. Transactional emails
    (billing, purchase) skip this — Zealova is the voice there, not the
    persona.
    """
    emoji, mood = persona_mood(stats)
    return f"""<tr>
      <td align="center" style="padding:24px 40px 0;">
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="background:#0f2733;border-radius:12px;">
          <tr>
            <td style="font-size:22px;padding:12px 0 12px 18px;vertical-align:middle;">{emoji}</td>
            <td style="padding:12px 18px 12px 10px;vertical-align:middle;">
              <p style="margin:0;font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:#06b6d4;">{stats.coach_name}</p>
              <p style="margin:0;font-size:13px;color:#a1a1aa;">{mood}</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>"""


# ─── Stats grid / zero-state row ────────────────────────────────────────────

def build_zero_state_row_html(stats: UserStats) -> str:
    """Zero-state stats card for users with no activity yet.

    Structured as a 2×2 grid showing 0 workouts / 0 meals / 0 XP / 0 streak
    so the layout is consistent with the active-user grid. Followed by a
    one-line "noticed" pun.
    """
    def _cell(value: str, label: str, muted: bool = True) -> str:
        color = "#3f3f46" if muted else "#ffffff"
        return (
            f'<td width="50%" style="padding:8px;">'
            f'<div style="background:#0f2733;border-radius:12px;padding:18px 14px;text-align:center;border:1px solid #1e3a47;">'
            f'<p style="margin:0 0 4px;font-size:22px;font-weight:800;color:{color};line-height:1.1;">{value}</p>'
            f'<p style="margin:0;font-size:11px;color:#71717a;letter-spacing:0.5px;text-transform:uppercase;">{label}</p>'
            f"</div>"
            f"</td>"
        )
    return f"""<tr>
      <td style="padding:20px 32px 0;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
          <tr>{_cell("0", "Workouts")}{_cell("0", "Meals logged")}</tr>
          <tr>{_cell("0", "XP earned")}{_cell("0", "Day streak")}</tr>
        </table>
        <p style="margin:16px 0 0;font-size:12px;color:#71717a;text-align:center;letter-spacing:0.3px;">{stats.coach_name} noticed.</p>
      </td>
    </tr>"""


def build_stats_grid_html(stats: UserStats) -> str:
    """2×2 stat grid for active users showing workouts + nutrition + streak + XP.

    Cells are chosen to always have something meaningful to show; "—" fallback
    kept for users who've skipped a dimension entirely so the layout never
    collapses.
    """
    workouts = str(stats.workouts_total) if stats.workouts_total else "—"
    streak = f"{stats.current_streak_days} 🔥" if stats.current_streak_days else "—"
    meals = f"{stats.nutrition_days_logged_this_week}/7 d" if stats.nutrition_days_logged_this_week else "—"
    calories = f"{stats.nutrition_avg_calories_week:,}" if stats.nutrition_avg_calories_week else "—"

    def _cell(value: str, label: str) -> str:
        return (
            f'<td width="50%" style="padding:8px;">'
            f'<div style="background:#0f2733;border-radius:12px;padding:18px 14px;text-align:center;border:1px solid #1e3a47;">'
            f'<p style="margin:0 0 4px;font-size:22px;font-weight:800;color:#ffffff;line-height:1.1;">{value}</p>'
            f'<p style="margin:0;font-size:11px;color:#71717a;letter-spacing:0.5px;text-transform:uppercase;">{label}</p>'
            f"</div>"
            f"</td>"
        )

    return f"""<tr>
      <td style="padding:20px 32px 0;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
          <tr>{_cell(workouts, "Workouts")}{_cell(streak, "Streak")}</tr>
          <tr>{_cell(meals, "Meals this wk")}{_cell(calories, "Avg cal/day")}</tr>
        </table>
      </td>
    </tr>"""


def build_nutrition_grid_html(stats: UserStats) -> str:
    """Dedicated nutrition 2×2 grid for emails where food data is the star.

    Used by the weekly summary and nutrition-specific variants. Pulls calories,
    protein, days logged, and today-logged flag. Renders a placeholder with a
    nudge-to-log line if the user hasn't touched nutrition at all.
    """
    if (
        stats.nutrition_days_logged_this_week == 0
        and not stats.nutrition_avg_calories_week
    ):
        # Not using the feature yet — surface a gentle prompt, not an empty grid.
        return f"""<tr>
      <td style="padding:20px 32px 0;">
        <div style="background:#0f2733;border-radius:12px;padding:18px 16px;border:1px dashed #1e3a47;text-align:center;">
          <p style="margin:0 0 6px;font-size:14px;font-weight:700;color:#ffffff;">Nutrition is blank</p>
          <p style="margin:0;font-size:12px;color:#71717a;line-height:1.5;">
            {stats.coach_name} can only coach what you log. Tap Nutrition in the app to start — photo, barcode, or typing all work.
          </p>
        </div>
      </td>
    </tr>"""

    days = f"{stats.nutrition_days_logged_this_week}/7" if stats.nutrition_days_logged_this_week else "—"
    cal = f"{stats.nutrition_avg_calories_week:,}" if stats.nutrition_avg_calories_week else "—"
    prot = f"{stats.nutrition_avg_protein_g_week}g" if stats.nutrition_avg_protein_g_week else "—"
    today = "Yes" if stats.nutrition_logged_today else "Not yet"

    def _cell(value: str, label: str) -> str:
        return (
            f'<td width="50%" style="padding:8px;">'
            f'<div style="background:#0f2733;border-radius:12px;padding:18px 14px;text-align:center;border:1px solid #1e3a47;">'
            f'<p style="margin:0 0 4px;font-size:22px;font-weight:800;color:#ffffff;line-height:1.1;">{value}</p>'
            f'<p style="margin:0;font-size:11px;color:#71717a;letter-spacing:0.5px;text-transform:uppercase;">{label}</p>'
            f"</div>"
            f"</td>"
        )

    return f"""<tr>
      <td style="padding:6px 32px 0;">
        <p style="margin:0 0 4px;font-size:11px;color:#06b6d4;font-weight:700;letter-spacing:2px;text-transform:uppercase;text-align:center;">Nutrition · Last 7 days</p>
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
          <tr>{_cell(days, "Days logged")}{_cell(cal, "Avg cal/day")}</tr>
          <tr>{_cell(prot, "Avg protein")}{_cell(today, "Logged today")}</tr>
        </table>
      </td>
    </tr>"""
