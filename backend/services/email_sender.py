"""The ONE place `resend.Emails.send` is called.

Every outbound email in the backend routes through :func:`send`. Nothing else in
`api/`, `services/` or `scripts/` may import `resend` and call `Emails.send` —
`tests/test_email_sender_cap.py::test_no_direct_resend_calls_outside_the_chokepoint`
is the regression gate for that.

Responsibilities, in order:
  1. Block undeliverable recipients (test-harness users → SES bounce suppression).
     75% of lifetime sends bounced (566/752) because injury/loadtest harnesses
     create users at `@zealova.invalid` / `@zealova-loadtest.dev` and the
     verification + lifecycle mail followed them to SES. SES suspends above ~5%.
  2. Enforce the global per-user lifecycle frequency cap
     (2 / user-local day, 4 / rolling 7 local days).
  3. Send.

Blocking is NORMAL CONTROL FLOW. A blocked send NEVER raises; it returns::

    {"id": None, "success": False, "skipped": True, "reason": R}

with ``R`` ∈ {``undeliverable_domain``, ``frequency_cap``, ``not_configured``}.

``success: False`` on the skip dict is deliberate: every cron job gates
``_log_email_sent(...)`` on ``result.get("success")``, so a blocked send writes NO
`email_send_log` row and therefore does NOT burn the per-type cooldown (which runs
14 days for `week1_*` and 365 days for `one_workout_wonder`). A capped email is
DEFERRED to the next hourly tick, never deleted. Callers must run the result
through :func:`sent_result` — never hand-build ``{"success": True}``.

RACE MODEL — read before editing:
  * :func:`_check_and_reserve` is a plain ``def`` holding ``_LOCK`` and contains
    ZERO awaits. It cannot be preempted by another coroutine (a sync function has
    no yield point) nor by another thread (the lock). Do NOT make it ``async``.
    Do NOT put an ``await`` in it. This is what makes the 26 ``asyncio.gather``ed
    cron jobs race-free against each other.
  * The slot is reserved at SEND time, not at gate time, so a slot can never leak
    to a job that bails after ``_was_recently_sent`` (22 of 26 jobs can).
  * The in-process ledger is seeded from `email_send_log` (cross-run truth) and
    incremented in-process (within-run truth — a row written by job A may not be
    visible to job B's PostgREST read yet). INVARIANT: in-process counts are
    always >= DB counts for the same window, so the cap can transiently
    OVER-suppress (safe — retried next hour) but never OVER-send (unsafe).
"""

from __future__ import annotations

import os
import threading
import time
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Set

# Imported as a module and called as `resend.Emails.send(...)` (attribute lookup at
# call time) so that tests' `patch.object(email_sender.resend.Emails, "send")` and
# scripts/render_transactional_email_preview.py's monkeypatch still intercept.
import resend

from core.logger import get_logger
from core.timezone_utils import _safe_zone

logger = get_logger(__name__)


# ═══════════════════════════════════════════════════════════════════════════════
# 1. Undeliverable recipients
# ═══════════════════════════════════════════════════════════════════════════════

#: Reserved / non-routable TLDs (RFC 2606 + RFC 6761). Mail to these ALWAYS bounces.
UNDELIVERABLE_TLDS: Set[str] = {"invalid", "test", "local", "localhost", "example"}

#: Known synthetic domains minted by our own harnesses / QA tooling.
_STATIC_UNDELIVERABLE_DOMAINS: Set[str] = {
    "zealova-loadtest.dev",       # scripts/loadtest/gen_test_tokens.py
    "cloudtestlabaccounts.com",   # Play Store pre-launch report devices
}


def _suppressed_domains() -> Set[str]:
    """Static blocklist + env ``EMAIL_SUPPRESS_DOMAINS`` (comma-separated).

    Read at CALL time, not import time, so an ops change lands on the next send
    with no redeploy.
    """
    extra = os.getenv("EMAIL_SUPPRESS_DOMAINS", "") or ""
    return _STATIC_UNDELIVERABLE_DOMAINS | {
        d.strip().lower() for d in extra.split(",") if d.strip()
    }


def _domain_of(address: str) -> str:
    """Recipient domain, lowercased. ``""`` when the address is malformed.

    Handles RFC 5322 display-name form (``"QA <qa@zealova.invalid>"``) because
    `from_email` style strings occasionally leak into `to` lists.
    """
    addr = (address or "").strip().lower()
    if addr.endswith(">") and "<" in addr:
        addr = addr[addr.rindex("<") + 1: -1].strip()
    if "@" not in addr:
        return ""
    return addr.rsplit("@", 1)[1].strip()


def is_undeliverable(address: str) -> bool:
    """True when mail to *address* is guaranteed to bounce (or is malformed).

    Malformed addresses count as undeliverable — we never hand garbage to SES.
    """
    domain = _domain_of(address)
    if not domain:
        return True
    if domain in _suppressed_domains():
        return True
    tld = domain.rsplit(".", 1)[-1] if "." in domain else domain
    return tld in UNDELIVERABLE_TLDS      # *.invalid *.test *.local *.example


# ═══════════════════════════════════════════════════════════════════════════════
# 2. Cap policy
# ═══════════════════════════════════════════════════════════════════════════════

MAX_LIFECYCLE_PER_LOCAL_DAY = 2
MAX_LIFECYCLE_PER_ROLLING_7D = 4

#: Kill switch for the frequency cap ONLY. The undeliverable-domain block is never
#: disableable — that one exists to protect the SES sending reputation.
CAP_DISABLED: bool = os.getenv("EMAIL_FREQUENCY_CAP_DISABLED", "").strip().lower() in (
    "1",
    "true",
    "yes",
)

#: EXEMPT = never capped AND never counted. A purchase receipt must not eat the
#: slot the weekly summary needs, and a billing failure must go out even if the
#: user already got 2 nudges today.
EXEMPT_EMAIL_TYPES: frozenset = frozenset(
    {
        # Account / verification
        "verification",
        "email_verification",
        "email_verification_reminder",
        "welcome",
        "password_reset",
        # Revenue
        "purchase_confirmation",
        "billing_issue",
        "trial_expired",
        "trial_ending",
        # Retention-critical (cancel-adjacent; `cancellation_retention` does NOT
        # match the `cancel` prefix rule, so it is listed explicitly — deliberate.)
        "cancellation_retention",
        # Security
        "new_device_signin",
        "security_new_device",
        # Requested / one-off / no-account
        "free_tool_result",
        "live_chat",
        "support",
        "support_reply",
        "workout_reminder",   # user-scheduled transactional reminder
        "roadmap_update",     # scripts/notify_roadmap_voters.py — opt-in, one-off
        "roadmap_ship",
    }
)

#: Prefix rules, applied after the explicit set.
EXEMPT_PREFIXES = ("cancel", "waitlist_", "lifetime_", "dsar_", "security", "live_chat")


def is_exempt(email_type: Optional[str]) -> bool:
    """True when *email_type* is never capped and never counted against the cap."""
    t = (email_type or "").strip().lower()
    if not t:
        return True          # no type supplied → uncappable (per the contract)
    return t in EXEMPT_EMAIL_TYPES or t.startswith(EXEMPT_PREFIXES)


TIER_TRANSACTIONAL, TIER_CORE, TIER_REENGAGEMENT, TIER_GAMIFICATION = 1, 2, 3, 4

#: Priority tiers. The CAP itself is first-come-first-served; PRIORITY is bought by
#: `api/v1/email_cron.py` running the job tiers SEQUENTIALLY. This map is the single
#: source of truth for that ordering and for cap telemetry.
PRIORITY_TIER: Dict[str, int] = {
    # ── T1: transactional / revenue (exempt anyway; listed so a typo can't demote one)
    "verification": TIER_TRANSACTIONAL,
    "email_verification_reminder": TIER_TRANSACTIONAL,
    "purchase_confirmation": TIER_TRANSACTIONAL,
    "billing_issue": TIER_TRANSACTIONAL,
    "trial_ending": TIER_TRANSACTIONAL,
    "trial_expired": TIER_TRANSACTIONAL,
    "cancel_grace": TIER_TRANSACTIONAL,
    "cancel_expired": TIER_TRANSACTIONAL,
    "cancel_offer_7d": TIER_TRANSACTIONAL,
    "cancel_offer_14d": TIER_TRANSACTIONAL,
    "cancel_offer_60d": TIER_TRANSACTIONAL,
    "cancel_sunset": TIER_TRANSACTIONAL,
    "cancellation_retention": TIER_TRANSACTIONAL,
    # ── T2: high-value lifecycle
    "weekly_summary": TIER_CORE,
    "week1_day1": TIER_CORE,
    "week1_day3_completed": TIER_CORE,
    "week1_day3_stalled": TIER_CORE,
    "week1_day5": TIER_CORE,
    "week1_day7": TIER_CORE,
    "day3_activation": TIER_CORE,
    "onboarding_incomplete": TIER_CORE,
    "comeback": TIER_CORE,
    "first_workout_done": TIER_CORE,
    # ── T3: re-engagement
    "one_workout_wonder": TIER_REENGAGEMENT,
    "streak_at_risk": TIER_REENGAGEMENT,
    "idle_nudge": TIER_REENGAGEMENT,
    "premium_idle": TIER_REENGAGEMENT,
    "win_back_30": TIER_REENGAGEMENT,
    "7day_upsell": TIER_REENGAGEMENT,
    "welcome_back_premium": TIER_REENGAGEMENT,
    # ── T4: gamification
    "merch_unlocked": TIER_GAMIFICATION,
    "merch_claim_reminder": TIER_GAMIFICATION,
    "merch_proximity": TIER_GAMIFICATION,
    "level_milestone_celebration": TIER_GAMIFICATION,
    "achievement_unlocked": TIER_GAMIFICATION,
}


def priority_tier(email_type: Optional[str]) -> int:
    """Tier (1-4) for *email_type*. Unregistered types log LOUDLY and default to T3."""
    t = (email_type or "").strip().lower()
    tier = PRIORITY_TIER.get(t)
    if tier is None:
        logger.error(
            "🚨 [email_sender] unregistered email_type %r — treating as T%d. "
            "Add it to PRIORITY_TIER.",
            email_type,
            TIER_REENGAGEMENT,
        )
        return TIER_REENGAGEMENT
    return tier


# ═══════════════════════════════════════════════════════════════════════════════
# 3. In-process ledger
# ═══════════════════════════════════════════════════════════════════════════════

_LEDGER_TTL_SECONDS = 600      # < the 3600s cron period ⇒ every run re-seeds from DB
_TZ_TTL_SECONDS = 900
_LEDGER_MAX_ENTRIES = 5_000


@dataclass
class _UserLedger:
    """Per-user email budget for ONE local day."""

    local_day: str                # "YYYY-MM-DD" in the user's timezone
    day_count: int
    week_count: int
    seeded_monotonic: float


_LEDGER: Dict[str, _UserLedger] = {}
_TZ_CACHE: Dict[str, tuple] = {}        # user_id -> (tz_name, monotonic_at)
_CAP_BLOCKS: Dict[str, int] = {}        # email_type -> blocked count, for /cron telemetry
_LOCK = threading.RLock()               # guards _LEDGER, _TZ_CACHE, _CAP_BLOCKS


def reset_state() -> None:
    """Drop the in-process ledger, tz cache and cap-block counters.

    Called at the top of every cron run (the DB is the cross-run truth) and by tests.
    """
    with _LOCK:
        _LEDGER.clear()
        _TZ_CACHE.clear()
        _CAP_BLOCKS.clear()


def drain_cap_blocks() -> Dict[str, int]:
    """Return ``{email_type: blocked_count}`` and reset the counter.

    Called at the end of the cron run so the HTTP response SURFACES suppression
    instead of hiding it. A dropped email is a product event, not a log line.
    """
    with _LOCK:
        out = dict(_CAP_BLOCKS)
        _CAP_BLOCKS.clear()
        return out


def _parse_ts(raw: Any) -> Optional[datetime]:
    """Parse a Postgres timestamptz string into an aware UTC datetime."""
    if not raw:
        return None
    try:
        dt = datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
    except (ValueError, TypeError):
        return None
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def _row_local_date(row: Dict[str, Any], tz) -> Optional[date]:
    """THE NULL-``sent_local_date`` reconciliation.

    Only `trial_ending` and `7day_upsell` ever pass ``local_date=`` to
    `_log_email_sent`, so the column is NULL on most rows. Prefer it when the
    writing job set it; otherwise derive the local day from the (always populated)
    UTC ``sent_at`` in the user's zone. Never trust the column exclusively.
    """
    sld = row.get("sent_local_date")
    if sld:
        try:
            return date.fromisoformat(str(sld)[:10])
        except ValueError:
            pass
    dt = _parse_ts(row.get("sent_at"))
    return dt.astimezone(tz).date() if dt else None


def _user_tz(supabase, user_id: str):
    """``users.timezone`` as a ZoneInfo, TTL-cached.

    Bad/missing values fall back to UTC via ``_safe_zone`` — the identical fallback
    used by `services.email_helpers.time_band`, so band math and cap math can never
    disagree about which local day it is.
    """
    now = time.monotonic()
    hit = _TZ_CACHE.get(user_id)
    if hit and (now - hit[1]) < _TZ_TTL_SECONDS:
        tz_name = hit[0]
    else:
        tz_name = "UTC"
        res = (
            supabase.client.table("users")
            .select("timezone")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        rows = res.data or []
        if rows and rows[0].get("timezone"):
            tz_name = rows[0]["timezone"]
        _TZ_CACHE[user_id] = (tz_name, now)
    return _safe_zone(tz_name)


def _seed_from_db(supabase, user_id: str, now_utc: datetime, tz) -> _UserLedger:
    """ONE query. Count NON-EXEMPT sends in the user's last 7 local days.

    The UTC prefilter looks back 8 days to cover timezone skew; bucketing into
    local days is then done per-row in the user's zone.
    """
    today = now_utc.astimezone(tz).date()
    cutoff = (now_utc - timedelta(days=8)).isoformat()

    res = (
        supabase.client.table("email_send_log")
        .select("email_type, sent_at, sent_local_date")
        .eq("user_id", user_id)
        .gte("sent_at", cutoff)
        .execute()
    )

    day_count = 0
    week_count = 0
    for row in (res.data or []):
        if is_exempt(row.get("email_type")):
            continue                            # exempt mail neither blocks nor consumes
        local_day = _row_local_date(row, tz)
        if local_day is None:
            continue
        if local_day == today:
            day_count += 1
        if (today - timedelta(days=7)) < local_day <= today:
            week_count += 1

    return _UserLedger(
        local_day=today.isoformat(),
        day_count=day_count,
        week_count=week_count,
        seeded_monotonic=time.monotonic(),
    )


def _sweep_locked() -> None:
    """Evict expired ledger entries once the map grows past its ceiling. Caller holds _LOCK."""
    if len(_LEDGER) <= _LEDGER_MAX_ENTRIES:
        return
    now = time.monotonic()
    for uid in [
        k for k, v in _LEDGER.items()
        if (now - v.seeded_monotonic) >= _LEDGER_TTL_SECONDS
    ]:
        _LEDGER.pop(uid, None)


def _record_cap_block_locked(
    user_id: str,
    email_type: str,
    window: str,
    used: int,
    limit: int,
    local_day: str,
) -> None:
    """Count + log + emit a product event for a capped email. Caller holds ``_LOCK``."""
    _CAP_BLOCKS[email_type] = _CAP_BLOCKS.get(email_type, 0) + 1
    logger.warning(
        "⚠️ [email_sender] frequency_cap: %s (T%d) blocked for user %s — %s %d/%d (local_day=%s)",
        email_type,
        priority_tier(email_type),
        user_id,
        window,
        used,
        limit,
        local_day,
    )
    try:
        from services.posthog_client import capture_lifecycle

        capture_lifecycle(
            user_id=str(user_id),
            event_name="lifecycle_email_capped",
            properties={
                "kind": email_type,
                "channel": "email",
                "tier": priority_tier(email_type),
                "window": window,
                "used": used,
                "limit": limit,
            },
        )
    except Exception:
        pass        # telemetry must NEVER break a send decision


def _check_and_reserve(supabase, user_id: str, email_type: str) -> bool:
    """THE CRITICAL SECTION.

    ``True`` ⇒ a slot is reserved and the caller MUST send (and MUST call
    :func:`_rollback` if the send raises).

    Atomic by construction: a plain ``def`` (no yield point) holding ``_LOCK``. Two
    callers can NEVER both observe ``day_count == 1`` and both decide to send.

    Fails CLOSED on a DB error. Only non-exempt lifecycle mail reaches here (all
    revenue/transactional mail is exempt and returned earlier in :func:`send`), and
    a blocked send writes no `email_send_log` row → its per-type cooldown is
    untouched → it is retried on the next hourly tick. Fail-closed can never drop
    money mail.
    """
    now_utc = datetime.now(timezone.utc)
    with _LOCK:
        try:
            tz = _user_tz(supabase, user_id)
            today = now_utc.astimezone(tz).date().isoformat()
            led = _LEDGER.get(user_id)
            stale = (
                led is None
                or led.local_day != today                                    # local midnight rolled
                or (time.monotonic() - led.seeded_monotonic) >= _LEDGER_TTL_SECONDS
            )
            if stale:
                led = _seed_from_db(supabase, user_id, now_utc, tz)
                _LEDGER[user_id] = led
                _sweep_locked()
        except Exception as e:
            logger.error(
                "❌ [email_sender] cap count failed for user %s / %s: %s — failing CLOSED "
                "(retried next cron tick)",
                user_id,
                email_type,
                e,
                exc_info=True,
            )
            key = f"{email_type}:error"
            _CAP_BLOCKS[key] = _CAP_BLOCKS.get(key, 0) + 1
            return False

        if led.day_count >= MAX_LIFECYCLE_PER_LOCAL_DAY:
            _record_cap_block_locked(
                user_id, email_type, "daily",
                led.day_count, MAX_LIFECYCLE_PER_LOCAL_DAY, led.local_day,
            )
            return False
        if led.week_count >= MAX_LIFECYCLE_PER_ROLLING_7D:
            _record_cap_block_locked(
                user_id, email_type, "rolling_7d",
                led.week_count, MAX_LIFECYCLE_PER_ROLLING_7D, led.local_day,
            )
            return False

        # RESERVE BEFORE the HTTP call — "count after success" would reopen the race
        # the moment anyone moves the send off-thread.
        led.day_count += 1
        led.week_count += 1
        return True


def _rollback(user_id: str) -> None:
    """Release a reservation whose send raised — nothing left the building."""
    with _LOCK:
        led = _LEDGER.get(user_id)
        if led:
            led.day_count = max(0, led.day_count - 1)
            led.week_count = max(0, led.week_count - 1)


# ═══════════════════════════════════════════════════════════════════════════════
# 4. Send plumbing
# ═══════════════════════════════════════════════════════════════════════════════

def _configured() -> bool:
    """True when Resend has an API key.

    `EmailService.__init__` sets ``resend.api_key`` globally, but the chokepoint is
    also reachable from scripts and background tasks that never construct one — so
    we set the key here from the environment when it is unset.
    """
    key = getattr(resend, "api_key", None)
    if key:
        return True
    env_key = os.getenv("RESEND_API_KEY")
    if env_key:
        resend.api_key = env_key
        return True
    return False


def _recipients(params: Dict[str, Any]) -> List[str]:
    """Normalize the Resend ``to`` field (a ``str`` OR a ``list[str]``) to a list."""
    to = params.get("to")
    if isinstance(to, str):
        return [to]
    if to is None:
        return []
    return [str(a) for a in to]


def _skipped(reason: str) -> Dict[str, Any]:
    """The canonical blocked-send return shape.

    ``success: False`` is load-bearing — see the module docstring.
    """
    return {"id": None, "success": False, "skipped": True, "reason": reason}


def _filter_recipients(params: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Drop undeliverable recipients from ``params["to"]``.

    Returns a params dict safe to hand to Resend (a COPY when anything was dropped,
    so the caller's dict is never mutated), or ``None`` when no deliverable
    recipient remains → the send must be blocked.
    """
    recipients = _recipients(params)
    if not recipients:
        return None

    blocked = [a for a in recipients if is_undeliverable(a)]
    if not blocked:
        return params

    kept = [a for a in recipients if not is_undeliverable(a)]
    logger.warning(
        "⚠️ [email_sender] undeliverable recipient(s) dropped: domains=%s (kept=%d)",
        sorted({_domain_of(a) or "<malformed>" for a in blocked}),
        len(kept),
    )
    if not kept:
        return None

    out = dict(params)
    # Preserve the caller's `to` shape: str in → str out, list in → list out.
    out["to"] = kept[0] if isinstance(params.get("to"), str) else kept
    return out


# ═══════════════════════════════════════════════════════════════════════════════
# 5. Public API
# ═══════════════════════════════════════════════════════════════════════════════

def send(
    params: Dict[str, Any],
    *,
    user_id: Optional[str] = None,
    email_type: Optional[str] = None,
) -> Dict[str, Any]:
    """The ONLY call site of ``resend.Emails.send`` in the codebase.

    Args:
        params: The Resend payload, passed through UNTOUCHED apart from having
            undeliverable recipients removed from ``to``. ``tags``, ``reply_to``,
            ``cc``, custom ``from`` etc. all survive.
        user_id: The RECIPIENT's `users.id`. Required for the frequency cap to
            apply. Pass ``None`` when the recipient is not a user (DSAR, waitlist,
            free-tool leads, admin support mail — note `live_chat` has a `user_id`
            in scope that is the REPORTER, not the recipient: pass ``None`` there).
        email_type: The type string written to `email_send_log.email_type`. Drives
            both exemption and cap telemetry.

    Returns:
        Resend's response dict (contains ``"id"``) on a real send — the success-path
        shape is UNCHANGED, so existing ``response.get("id")`` usage keeps working.
        On a blocked send returns
        ``{"id": None, "success": False, "skipped": True, "reason": R}``.

    Raises:
        Only what Resend itself raises on a real send. NEVER raises on a block.
    """
    safe_params = _filter_recipients(params)
    if safe_params is None:
        logger.warning(
            "⚠️ [email_sender] blocked undeliverable_domain — nothing sent (type=%s, user=%s)",
            email_type or "-",
            user_id or "-",
        )
        return _skipped("undeliverable_domain")

    if not _configured():
        logger.warning(
            "⚠️ [email_sender] RESEND_API_KEY unset — %s not sent",
            email_type or "email",
        )
        return _skipped("not_configured")

    capped_type = bool(email_type) and not is_exempt(email_type)

    if capped_type and not user_id:
        # A capped type with no user_id silently escapes the cap. Loud, so an
        # un-instrumented call site shows up in the logs, not in someone's inbox.
        logger.warning(
            "⚠️ [email_sender] %s sent with no user_id — frequency cap NOT applied",
            email_type,
        )

    if CAP_DISABLED or not (capped_type and user_id):
        return resend.Emails.send(safe_params)

    from core.supabase_client import get_supabase   # lazy: keeps this module import-cheap

    supabase = get_supabase()

    if not _check_and_reserve(supabase, str(user_id), str(email_type)):
        return _skipped("frequency_cap")

    try:
        # OUTSIDE the lock: never hold a mutex across network I/O.
        return resend.Emails.send(safe_params)
    except Exception:
        _rollback(str(user_id))
        raise                    # the existing per-mixin try/except owns the error path


def sent_result(response: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    """MANDATORY adapter for every call site that previously did
    ``return {"success": True, "id": response.get("id")}``.

    Without it a blocked send becomes ``{"success": True, "id": None}``, the cron
    writes a phantom `email_send_log` row, and the per-type cooldown is burned for
    mail that never sent (14 days for `week1_*`, 365 days for `one_workout_wonder`).
    The cap would then DELETE mail instead of DEFERRING it — strictly worse than the
    bug we are fixing. This function is load-bearing.
    """
    r = response or {}
    if r.get("skipped"):
        return {
            "success": False,
            "skipped": True,
            "reason": r.get("reason"),
            "id": None,
        }
    return {"success": True, "id": r.get("id")}
