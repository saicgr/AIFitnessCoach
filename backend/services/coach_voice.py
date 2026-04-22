"""Central coach-voice helper.

Single source of truth for rendering persona-voiced copy across every surface
(push, email, in-app banners, weekly summary narration, post-workout recap,
quick-adjust confirmation). Ensures the coach the user selected in onboarding
*sounds the same* everywhere — no "Coach" mascot leakage, no "FitWiz team"
voice drift on motivational copy, no hard-coded hype strings.

Design contract:
- Read-only: never writes to DB. Callers fetch once per request via
  `get_coach_voice(user_id)` and thread the `CoachVoice` into subsequent render
  calls.
- Pure render layer: variant pools (>=4 per template) + safe `{placeholder}`
  substitution. No LLM call here — Gemini narration is orchestrated by
  `build_system_prompt()` which reuses `build_personality_prompt()` from the
  LangGraph personality module (single source for persona semantics).
- Channel-aware: `channel='push'` trims to FCM body limits (~120 chars body,
  ~50 chars title); `channel='email'` allows full markdown; `channel='in_app'`
  is freeform. Each variant declares its max channel suitability.
- Style-filtered: variants carry `style_tags` (e.g. {"hype", "intense"}). At
  render time we intersect tags with the voice's style → only matching
  variants stay in the pool, then one is picked deterministically from the
  filtered set (hash(user_id + template_key + date)) so the same user sees
  the same variant for the same event rather than random jitter.

Why a module and not a class: the existing UserStats + push_nudge_cron pipeline
is already well-factored around dataclasses + pure helpers. A module matches
that style and keeps unit-testability simple (no fixtures, just data).

Integrations required by sequencing plan item 3:
- `summaries.py::_generate_ai_summary` — wrap Gemini call with
  `build_system_prompt(voice, agent_role="weekly_recap")`.
- `push_nudge_cron.py` — already persona-aware via notif_svc; new template
  keys should go through `render()`.
- `email_lifecycle.py` — keep transactional in FitWiz voice; route every
  motivational send through `render(..., channel="email")`.
- Mobile pre-set banner + post-workout — fetch voice via existing
  user_ai_settings fetch, pass into a new `/render-copy` endpoint (or inline
  the variant pools to the client; see plan item 2).
"""
from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass, field
from datetime import date
from typing import Any, Iterable, Optional

from core.logger import get_logger
from core.supabase_client import get_supabase
from models.chat import AISettings
from services.langgraph_agents.personality import (
    build_personality_prompt,
    sanitize_coach_name,
)

logger = get_logger(__name__)


# ── Constants ──────────────────────────────────────────────────────────────

DEFAULT_COACH_NAME = "Your Coach"
DEFAULT_FIRST_NAME = "there"

# FCM physical limits. Title/body over these will be silently truncated by the
# platform; we cap ourselves so variant selection matches what users actually
# see (and so we don't pick a variant that ends mid-word).
PUSH_TITLE_MAX_CHARS = 50
PUSH_BODY_MAX_CHARS = 178  # ~2 lines on iOS lock screen

# Fallback when a template key has no variants matching the voice's style tags.
# Only hit in practice if a template was registered with overly-narrow tags.
GENERIC_FALLBACK_TAGS = frozenset({"neutral"})


# ── Data model ─────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class CoachVoice:
    """Immutable read-view of a user's persona config.

    Populated once per request via `get_coach_voice(user_id)`; threaded through
    render calls. Kept frozen so accidental mutation (e.g. "let's lowercase the
    name just for this send") can't leak across renders.
    """
    user_id: str
    first_name: str                       # "Alex", or "there" as last resort
    coach_name: str                       # "Coach Mike", or "Your Coach"
    style: str                            # matches AISettings.coaching_style
    tone: str                             # matches AISettings.communication_tone
    encouragement: float                  # 0.0 – 1.0
    response_length: str                  # "concise" | "balanced" | "detailed"
    use_emojis: bool
    include_tips: bool

    # Derived style tags — used for variant filtering. Populated by
    # `_derive_style_tags` at construction time so render() doesn't recompute.
    style_tags: frozenset[str] = field(default_factory=frozenset)

    def to_ai_settings(self) -> AISettings:
        """Build an AISettings instance for `build_personality_prompt()`.

        Why re-synthesize instead of caching the original row: `CoachVoice` is
        the canonical shape across the app. The AISettings intermediate lives
        only inside prompt assembly and can be thrown away after.
        """
        return AISettings(
            coach_name=self.coach_name if self.coach_name != DEFAULT_COACH_NAME else None,
            coaching_style=self.style,
            communication_tone=self.tone,
            encouragement_level=self.encouragement,
            response_length=self.response_length,
            use_emojis=self.use_emojis,
            include_tips=self.include_tips,
        )


# ── Style tag derivation ───────────────────────────────────────────────────

# Map of (style | tone) → tag set. Tags are deliberately coarse so variant
# pools can be authored with unions in mind (e.g. tag a variant "hype" and it
# plays for hype-beast, drill-sergeant, and college-coach). Each style MUST
# include "neutral" so the generic fallback pool is always reachable.
_STYLE_TAGS: dict[str, frozenset[str]] = {
    "motivational":    frozenset({"warm", "supportive", "neutral"}),
    "professional":    frozenset({"reserved", "factual", "neutral"}),
    "friendly":        frozenset({"warm", "casual", "neutral"}),
    "tough-love":      frozenset({"direct", "intense", "neutral"}),
    "drill-sergeant":  frozenset({"intense", "hype", "loud", "neutral"}),
    "zen-master":      frozenset({"calm", "reserved", "neutral"}),
    "hype-beast":      frozenset({"hype", "loud", "warm", "neutral"}),
    "scientist":       frozenset({"factual", "reserved", "neutral"}),
    "comedian":        frozenset({"warm", "playful", "neutral"}),
    "old-school":      frozenset({"direct", "casual", "neutral"}),
    "college-coach":   frozenset({"intense", "direct", "loud", "neutral"}),
}

_TONE_TAGS: dict[str, frozenset[str]] = {
    "casual":       frozenset({"casual"}),
    "encouraging":  frozenset({"warm", "supportive"}),
    "formal":       frozenset({"reserved", "factual"}),
    "gen-z":        frozenset({"casual", "playful"}),
    "sarcastic":    frozenset({"playful", "direct"}),
    "roast-mode":   frozenset({"intense", "playful"}),
    "pirate":       frozenset({"playful"}),
    "british":      frozenset({"reserved", "playful"}),
    "surfer":       frozenset({"casual", "warm"}),
    "anime":        frozenset({"hype", "intense"}),
}


def _derive_style_tags(style: str, tone: str) -> frozenset[str]:
    """Union the style + tone tag sets. Unknown values fall back to neutral."""
    style_set = _STYLE_TAGS.get(style, frozenset({"neutral"}))
    tone_set = _TONE_TAGS.get(tone, frozenset())
    return style_set | tone_set


# ── Name resolution (mirrors email_helpers.first_name) ─────────────────────

def _first_name_from_user_row(user: dict) -> str:
    """Extract first name from a `users` table row.

    Mirrors `email_helpers.first_name()` logic exactly so push/email/in-app
    stay aligned. If that helper ever changes, update both.

    Fallback chain: users.name → display_name → email prefix → "there".
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
        clean = "".join(c for c in prefix if c.isalpha())
        if clean:
            return clean.capitalize()

    return DEFAULT_FIRST_NAME


# ── Fetcher ────────────────────────────────────────────────────────────────

async def get_coach_voice(user_id: str, supabase=None) -> CoachVoice:
    """Fetch a user's `CoachVoice` for the current request.

    Safe to call on any user_id — missing rows fall back to defaults rather
    than raising, because voice-rendering must never block the primary action
    (sending a push, rendering a summary). If the user has no ai_settings row
    yet, we use the onboarding defaults (motivational / encouraging).

    Args:
        user_id: uuid string of the user
        supabase: optional supabase client. If omitted, fetches via
                  `get_supabase()`. Accept as param so callers in a request
                  context can share the connection.
    """
    sb = (supabase or get_supabase()).client

    # Two cheap point-reads. Could gather concurrently, but these are indexed
    # lookups on PKs — latency is dominated by the round-trip, not the query.
    # Keeping sequential for readability; switch to asyncio.gather if profiling
    # flags it.
    try:
        ai_res = sb.table("user_ai_settings").select(
            "coach_name, coaching_style, communication_tone, encouragement_level, "
            "response_length, use_emojis, include_tips"
        ).eq("user_id", user_id).limit(1).execute()
        ai_row = (ai_res.data or [{}])[0] if ai_res.data else {}
    except Exception as e:
        logger.warning(f"[CoachVoice] ai_settings fetch failed for {user_id}: {e}")
        ai_row = {}

    try:
        # Column selection kept minimal and compatible with the current users
        # schema — display_name isn't present on every deployment; first_name
        # resolution falls back to email prefix if name is also missing.
        user_res = sb.table("users").select("name, email").eq(
            "id", user_id
        ).limit(1).execute()
        user_row = (user_res.data or [{}])[0] if user_res.data else {}
    except Exception as e:
        logger.warning(f"[CoachVoice] users fetch failed for {user_id}: {e}")
        user_row = {}

    raw_coach_name = ai_row.get("coach_name")
    coach_name = (
        sanitize_coach_name(raw_coach_name, default=DEFAULT_COACH_NAME)
        if raw_coach_name else DEFAULT_COACH_NAME
    )
    style = ai_row.get("coaching_style") or "motivational"
    tone = ai_row.get("communication_tone") or "encouraging"

    return CoachVoice(
        user_id=user_id,
        first_name=_first_name_from_user_row(user_row),
        coach_name=coach_name,
        style=style,
        tone=tone,
        encouragement=float(ai_row.get("encouragement_level", 0.7)),
        response_length=ai_row.get("response_length") or "balanced",
        use_emojis=bool(ai_row.get("use_emojis", True)),
        include_tips=bool(ai_row.get("include_tips", True)),
        style_tags=_derive_style_tags(style, tone),
    )


def voice_from_ai_settings(
    user_id: str, ai_settings: dict, user_row: Optional[dict] = None
) -> CoachVoice:
    """Synchronous constructor when caller already has the rows in memory.

    Why exists: `push_nudge_cron.py` already preloads ai_settings + users
    rows for batch processing and passing them here saves N extra DB hits.
    Same defaults as `get_coach_voice`.
    """
    user_row = user_row or {}
    raw_coach_name = ai_settings.get("coach_name")
    coach_name = (
        sanitize_coach_name(raw_coach_name, default=DEFAULT_COACH_NAME)
        if raw_coach_name else DEFAULT_COACH_NAME
    )
    style = ai_settings.get("coaching_style") or "motivational"
    tone = ai_settings.get("communication_tone") or "encouraging"

    return CoachVoice(
        user_id=user_id,
        first_name=_first_name_from_user_row(user_row),
        coach_name=coach_name,
        style=style,
        tone=tone,
        encouragement=float(ai_settings.get("encouragement_level", 0.7)),
        response_length=ai_settings.get("response_length") or "balanced",
        use_emojis=bool(ai_settings.get("use_emojis", True)),
        include_tips=bool(ai_settings.get("include_tips", True)),
        style_tags=_derive_style_tags(style, tone),
    )


# ── Template registry ──────────────────────────────────────────────────────

@dataclass(frozen=True)
class Template:
    """A single variant. `tags` intersect with CoachVoice.style_tags at render time."""
    text: str
    tags: frozenset[str] = frozenset({"neutral"})
    channels: frozenset[str] = frozenset({"push", "email", "in_app"})
    # If True, variant references {first_name} or {coach_name} — used by
    # internal validation so templates without names still feel personal.
    requires_name: bool = False


# Registry shape: {template_key: {"title": [Template...], "body": [Template...]}}
# For non-push templates, use only "body". Keys correspond to the surfaces
# enumerated in the plan file — add new keys here as new surfaces are built.
#
# Authoring rules (enforced by `_validate_registry` at import time):
# 1. Each (key, part) MUST have >=4 variants.
# 2. Each key MUST include at least one variant tagged {"neutral"} as the
#    guaranteed fallback when a user's voice matches no other variant.
# 3. Push titles MUST fit PUSH_TITLE_MAX_CHARS; push bodies MUST fit
#    PUSH_BODY_MAX_CHARS. Accounts for {first_name} ≈ 10 chars of slack.
_TEMPLATES: dict[str, dict[str, list[Template]]] = {
    # ── Sunday Wrapped push (Item 1) ────────────────────────────────────
    "weekly_summary_push": {
        "title": [
            Template("Your week, {first_name} 📊",
                     tags=frozenset({"neutral", "warm"}),
                     channels=frozenset({"push"}),
                     requires_name=True),
            Template("Week in review",
                     tags=frozenset({"neutral", "reserved", "factual"}),
                     channels=frozenset({"push"})),
            Template("{first_name}, let's look at your week",
                     tags=frozenset({"warm", "supportive"}),
                     channels=frozenset({"push"}),
                     requires_name=True),
            Template("WEEK RECAP — LET'S GO",
                     tags=frozenset({"hype", "loud", "intense"}),
                     channels=frozenset({"push"})),
            Template("Sunday check-in 🧘",
                     tags=frozenset({"calm", "reserved"}),
                     channels=frozenset({"push"})),
            Template("Yo {first_name} the wrap is here 💀",
                     tags=frozenset({"playful", "casual"}),
                     channels=frozenset({"push"}),
                     requires_name=True),
        ],
        "body": [
            Template("{workouts} workouts, {prs} PRs. Tap to see what's next.",
                     tags=frozenset({"neutral", "factual", "reserved"})),
            Template("{first_name} — {workouts} sessions, {prs} PRs, {volume_lbs} lbs moved. Here's how next week looks.",
                     tags=frozenset({"warm", "supportive"}),
                     requires_name=True),
            Template("YOU MOVED {volume_lbs} LBS. {prs} PRs. STEP UP NEXT WEEK.",
                     tags=frozenset({"hype", "loud", "intense"})),
            Template("Breathe. {workouts} sessions behind you, {prs} new bests. Let's plan gently.",
                     tags=frozenset({"calm", "reserved"})),
            Template("Solid week: {workouts} workouts, {prs} PRs. Next week's plan is ready — one tap.",
                     tags=frozenset({"direct", "neutral"})),
            Template("{workouts} workouts this week, {prs} PRs, no cap 💪 peek next week's plan inside",
                     tags=frozenset({"casual", "playful"})),
        ],
    },

    # ── Quick-adjust confirmation toast (Item 4) ────────────────────────
    "quick_adjust_summary": {
        "body": [
            Template("Adjusted to {sets_remaining} sets across {exercises_remaining} exercises (~{minutes} min). Undo?",
                     tags=frozenset({"neutral", "factual", "reserved"})),
            Template("Got it — trimmed to {sets_remaining} sets, {exercises_remaining} exercises. ~{minutes} min left.",
                     tags=frozenset({"warm", "supportive", "direct"})),
            Template("ADJUSTED. {exercises_remaining} LIFTS, {sets_remaining} SETS. MOVE.",
                     tags=frozenset({"hype", "loud", "intense"})),
            Template("Lighter load: {sets_remaining} sets across {exercises_remaining} exercises. Breathe into it.",
                     tags=frozenset({"calm", "reserved"})),
            Template("Okay bestie — {sets_remaining} sets, {exercises_remaining} exercises, ~{minutes} min. Lock in.",
                     tags=frozenset({"casual", "playful"})),
        ],
    },

    # ── Weekly summary AI system-prompt addendum (Item 1 Gemini call) ───
    # Not user-facing copy — this gets prepended to the Gemini prompt in
    # _generate_ai_summary so the generated narrative sounds voiced. Only
    # one variant because the personality prompt from build_personality_prompt
    # already owns voice semantics.
    "weekly_summary_system_addendum": {
        "body": [
            Template(
                "You are generating {first_name}'s weekly fitness recap as {coach_name}. "
                "Stay in your configured coaching style. Be specific with their numbers — "
                "don't write generic fitness copy. Celebrate wins, acknowledge misses without guilt, "
                "and preview the next week in one sentence.",
                tags=frozenset({"neutral"}),
                channels=frozenset({"in_app"}),
                requires_name=True,
            ),
        ],
    },
}


def _validate_registry() -> None:
    """Validate the template registry at import time.

    Catches authoring mistakes early (missing neutral fallback, oversized push
    variants, too-few variants per pool) rather than failing mid-render. Logs
    but doesn't raise — in prod we'd rather degrade than crash on startup.
    """
    for key, parts in _TEMPLATES.items():
        for part, variants in parts.items():
            if len(variants) < 4 and key != "weekly_summary_system_addendum":
                logger.warning(
                    f"[CoachVoice] Template '{key}.{part}' has only {len(variants)} "
                    f"variants; registry requires >=4 for variety."
                )
            if not any("neutral" in v.tags for v in variants):
                logger.warning(
                    f"[CoachVoice] Template '{key}.{part}' has no 'neutral' "
                    f"fallback variant — some voices may hit the generic fallback."
                )
            for v in variants:
                if "push" in v.channels and part == "title" and len(v.text) > PUSH_TITLE_MAX_CHARS:
                    logger.warning(
                        f"[CoachVoice] Push title variant exceeds {PUSH_TITLE_MAX_CHARS} chars: {v.text!r}"
                    )
                if "push" in v.channels and part == "body" and len(v.text) > PUSH_BODY_MAX_CHARS:
                    logger.warning(
                        f"[CoachVoice] Push body variant exceeds {PUSH_BODY_MAX_CHARS} chars: {v.text!r}"
                    )


_validate_registry()


# ── Rendering ──────────────────────────────────────────────────────────────

_PLACEHOLDER_RE = re.compile(r"\{([a-zA-Z_][a-zA-Z0-9_]*)\}")


def _substitute(template: str, data: dict[str, Any], voice: CoachVoice) -> str:
    """Replace {placeholders} with data values. Missing keys → empty string.

    We deliberately don't use str.format() because a missing key there raises
    KeyError — we'd rather render a slightly-empty message than crash the
    notification pipeline. Keys {first_name} and {coach_name} are always
    populated from the voice.
    """
    full_data = {
        "first_name": voice.first_name,
        "coach_name": voice.coach_name,
        **{k: str(v) if v is not None else "" for k, v in data.items()},
    }

    def _replace(match: re.Match) -> str:
        key = match.group(1)
        if key not in full_data:
            logger.debug(f"[CoachVoice] Missing placeholder {{{key}}} for template; rendering as empty.")
            return ""
        return full_data[key]

    return _PLACEHOLDER_RE.sub(_replace, template)


def _pick_variant(
    variants: list[Template],
    voice: CoachVoice,
    channel: str,
    selection_salt: str,
) -> Template:
    """Pick a variant matching the voice's style tags + channel.

    Selection is deterministic given (user_id, selection_salt) — same event for
    same user always picks the same variant (no flip-flopping on retries). But
    different events yield different variants so the user doesn't see the same
    line twice in a row.

    Fallback chain:
      1. Variants whose tags intersect voice.style_tags AND support channel
      2. Neutral variants supporting the channel
      3. Any variant supporting the channel (last resort)
    """
    channel_ok = [v for v in variants if channel in v.channels]
    if not channel_ok:
        # Bad call — no variants for this channel at all. Fall back to any.
        channel_ok = list(variants)

    matching = [v for v in channel_ok if v.tags & voice.style_tags]
    if not matching:
        matching = [v for v in channel_ok if v.tags & GENERIC_FALLBACK_TAGS]
    if not matching:
        matching = channel_ok

    # Deterministic pick: hash(user_id + salt) % len(matching).
    digest = hashlib.sha1(f"{voice.user_id}|{selection_salt}".encode()).digest()
    idx = int.from_bytes(digest[:4], "big") % len(matching)
    return matching[idx]


def render(
    template_key: str,
    voice: CoachVoice,
    data: Optional[dict[str, Any]] = None,
    *,
    part: str = "body",
    channel: str = "push",
    selection_salt: Optional[str] = None,
) -> str:
    """Render a persona-voiced string for a given template key.

    Args:
        template_key: registry key (e.g. "weekly_summary_push")
        voice: loaded via `get_coach_voice(user_id)` or `voice_from_ai_settings`
        data: placeholder values; {first_name}/{coach_name} are auto-populated
        part: "title" | "body" for keys with multiple parts, else "body"
        channel: "push" | "email" | "in_app" — filters variants + length
        selection_salt: stabilizes variant choice across retries. Recommended:
                        `f"{template_key}:{YYYY-MM-DD}"` so variety is per-day,
                        not per-call.

    Returns:
        Rendered string. On missing template, returns empty string + logs
        error (never raises — render failures must never block the primary
        action).
    """
    if template_key not in _TEMPLATES:
        logger.error(f"[CoachVoice] Unknown template_key: {template_key}")
        return ""

    parts = _TEMPLATES[template_key]
    if part not in parts:
        logger.error(f"[CoachVoice] Template '{template_key}' has no part '{part}'")
        return ""

    salt = selection_salt or f"{template_key}:{date.today().isoformat()}"
    variant = _pick_variant(parts[part], voice, channel, salt)
    rendered = _substitute(variant.text, data or {}, voice)

    # Strip emojis if the voice opts out. Conservative range — covers the
    # emoji blocks, pictographs, and symbols we actually use.
    if not voice.use_emojis:
        rendered = re.sub(
            r"[\U0001F300-\U0001FAFF\U00002600-\U000027BF\U0001F000-\U0001F02F]",
            "",
            rendered,
        ).strip()

    # Channel-specific safety trim — a mid-render substitution could push a
    # well-authored variant over limits if user data is unusually long.
    if channel == "push":
        limit = PUSH_TITLE_MAX_CHARS if part == "title" else PUSH_BODY_MAX_CHARS
        if len(rendered) > limit:
            rendered = rendered[: limit - 1].rstrip() + "…"

    return rendered


# ── System-prompt assembly for LLM narration (summaries, post-workout) ─────

def build_system_prompt(voice: CoachVoice, agent_role: str = "fitness coach") -> str:
    """Build a Gemini/LLM system prompt that narrates in the user's voice.

    Thin wrapper over `build_personality_prompt()` — the canonical persona
    semantics live there. Use this whenever a *new* (non-LangGraph) Gemini
    call needs to sound like the user's coach. Existing LangGraph agents
    already use build_personality_prompt directly.

    Example (summaries.py):
        voice = await get_coach_voice(user_id)
        system_prompt = build_system_prompt(voice, agent_role="weekly recap narrator")
        content = await gemini_service.chat(user_message=prompt, system_prompt=system_prompt)
    """
    return build_personality_prompt(
        ai_settings=voice.to_ai_settings(),
        agent_name=voice.coach_name if voice.coach_name != DEFAULT_COACH_NAME else "Coach",
        agent_specialty=agent_role,
    )


# ── Sign-off (email footer, in-app toast footer) ───────────────────────────

def signature(voice: CoachVoice, channel: str = "email") -> str:
    """Return the appropriate sign-off for a channel.

    - Transactional emails should NOT call this (they sign as FitWiz).
    - Motivational emails: "— {coach_name}"
    - Push: signature is usually omitted (too long); callers shouldn't append.
    - In-app: subtle attribution line.
    """
    if channel == "push":
        return ""  # Push body is too tight for a signature
    if channel == "in_app":
        return f"— {voice.coach_name}"
    return f"— {voice.coach_name}"


# ── Convenience: iterate template keys (for audits / tests) ────────────────

def known_template_keys() -> Iterable[str]:
    """Return all registered template keys. Used by the audit script in task 2."""
    return _TEMPLATES.keys()
