"""Open-loop follow-up nudge — the coach remembers what you told it.

"How's the knee holding up?" three days after the user mentioned a sore knee.
Coach memory (migration 2217) already tracks open loops (`status='open'`,
`follow_up_after`, `resolution_prompt`, salience); until now they were only
resurfaced when the user happened to open a briefing. This job turns a DUE
open loop into a proactive push + session-attached chat message — the single
most "a real coach cares about me" signal in the fleet.

Design constraints (fewer, better):
  * At most ONE follow-up per user per day (push_nudge_log dedup), sharing the
    global 3/day cap + rolling weekly cap + quiet hours + vacation/dormancy
    suppression with every other nudge.
  * Copy is the loop's own `resolution_prompt` (authored at extraction time,
    already phrased as the coach's question) — deterministic, no LLM call.
  * After sending, `follow_up_after` is pushed forward and the nag counter
    bumped, so a loop is never asked about two days running; MAX surfaces are
    enforced by `list_open_loops_due`.
  * Resolution needs zero new code: the user's reply lands in the same chat
    session, and the nightly memory-consolidation resolver closes the loop.
"""
from datetime import datetime, timedelta, timezone
from typing import List, Optional

from core.logger import get_logger

logger = get_logger(__name__)

NUDGE_TYPE = "open_loop_followup"

# Only reach out during waking, non-intrusive hours.
_MIN_HOUR = 9
_MAX_HOUR = 20
_DEFAULT_HOUR = 10

# After surfacing a loop, don't surface the SAME loop again for this long.
_REASK_DELAY_DAYS = 3

# If the loop was already referenced (chat injection / briefing) very
# recently, a push would feel like nagging — skip.
_RECENT_REFERENCE_HOURS = 24


def _coach_memory_enabled(supabase, user_id: str) -> bool:
    """Master memory toggle — never push memory content the user turned off."""
    try:
        row = (
            supabase.client.table("users")
            .select("coach_memory_enabled")
            .eq("id", user_id)
            .single()
            .execute()
        ).data or {}
        return bool(row.get("coach_memory_enabled", True))
    except Exception:
        return False  # fail CLOSED — memory content is sensitive


def _pick_due_loop(memory_db, user_id: str) -> Optional[dict]:
    """Highest-salience due open loop that wasn't referenced very recently."""
    try:
        loops = memory_db.list_open_loops_due(user_id, limit=3)
    except Exception as e:
        logger.warning(f"⚠️ [OpenLoop] list_open_loops_due failed for {user_id}: {e}")
        return None
    cutoff = datetime.now(timezone.utc) - timedelta(hours=_RECENT_REFERENCE_HOURS)
    for loop in loops:  # already salience-desc
        ref = loop.get("last_referenced_at")
        if ref:
            try:
                ref_dt = datetime.fromisoformat(str(ref).replace("Z", "+00:00"))
                if ref_dt > cutoff:
                    continue  # coach already brought this up today
            except (ValueError, TypeError):
                pass
        return loop
    return None


def _loop_message(loop: dict, user_name: Optional[str]) -> str:
    """The follow-up question. `resolution_prompt` is authored at extraction
    time as the coach's own question ("How's the knee feeling?") — use it
    verbatim. Fallback: a warm, content-grounded question (never generic
    filler with no reference to what the user actually said)."""
    prompt = (loop.get("resolution_prompt") or "").strip()
    if prompt:
        return prompt
    content = (loop.get("content") or "").strip().rstrip(".")
    if not content:
        return ""
    first = (user_name or "").split(" ")[0].strip()
    lead = f"{first} — " if first else ""
    return f"{lead}you mentioned {content[:120]} a little while ago. How's that going?"


async def job_open_loop_followup(supabase, notif_svc, users: List[dict]) -> int:
    """One caring follow-up per eligible user whose local clock hits their hour."""
    # Lazy import: this module is imported BY push_nudge_cron, so importing the
    # shared gate helpers at call time avoids a circular module import.
    from api.v1 import push_nudge_cron as pnc
    from core.db import get_supabase_db

    memory_db = get_supabase_db().memory
    sent = 0

    for user in users:
        try:
            user_id = str(user["id"])
            prefs = user.get("notification_preferences") or {}

            # Per-type pref (default ON — highest-signal nudge, included even
            # in the "minimal" preset; the mute lives in muted-nudges settings).
            if not prefs.get("open_loop_followup_nudge", True):
                continue

            # Brand-new accounts have no history to follow up on.
            if pnc._user_account_age_days(user) < 3:
                continue

            # Local-hour gate (optimal-send-hour when learned, clamped to
            # waking hours) + quiet hours.
            tz_str = user.get("timezone") or "UTC"
            local_hour = pnc._get_user_local_hour(tz_str)
            target = pnc._get_optimal_hour(user, NUDGE_TYPE, _DEFAULT_HOUR)
            target = min(max(target, _MIN_HOUR), _MAX_HOUR)
            if local_hour != target:
                continue
            if pnc._is_in_quiet_hours(prefs, local_hour):
                continue

            # Rolling weekly cap (dormancy-aware) — same math as _send_nudge.
            band = pnc._dormancy_band(user)
            weekly_cap, window = pnc._weekly_cap_for(user, band)
            if pnc._count_nudges_within(supabase, user_id, window) >= weekly_cap:
                continue

            # Cheap same-day pre-check before touching coach_memory at all.
            local_date = pnc._get_user_local_date(tz_str)
            if pnc._sent_within_days(supabase, user_id, NUDGE_TYPE, 2):
                continue

            loop = _pick_due_loop(memory_db, user_id)
            if not loop:
                continue

            # Master memory toggle — checked only when a due loop exists
            # (rare), so the common path costs zero extra queries.
            if not _coach_memory_enabled(supabase, user_id):
                continue

            message = _loop_message(loop, user.get("name"))
            if not message:
                continue

            coach_name = (user.get("_ai_settings") or {}).get("coach_name") or "Your Coach"
            ok = await pnc._send_health_coaching_nudge(
                supabase,
                notif_svc,
                user,
                NUDGE_TYPE,
                title=coach_name,
                message=message,
                route="/chat",
                facts={
                    "memory_id": str(loop.get("id") or ""),
                    "memory_content": (loop.get("content") or "")[:200],
                },
            )
            if ok:
                sent += 1
                # Never nag: bump the counter and push the loop's next-due
                # date out, so tomorrow's run skips it even if unresolved.
                try:
                    memory_db.bump_follow_up(str(loop["id"]), user_id)
                    next_due = (
                        datetime.now(timezone.utc) + timedelta(days=_REASK_DELAY_DAYS)
                    ).isoformat()
                    memory_db.update_memory(
                        str(loop["id"]), user_id, {"follow_up_after": next_due}
                    )
                except Exception as e:
                    logger.warning(
                        f"⚠️ [OpenLoop] post-send bookkeeping failed for {user_id}: {e}"
                    )
        except Exception as e:
            logger.error(f"❌ [OpenLoop] user loop failed: {e}", exc_info=True)
            continue

    return sent
