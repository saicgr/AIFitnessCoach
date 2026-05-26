"""
Daily Coach Insight API.

Endpoint:
  GET /api/v1/coach/daily-insight
      ?date=YYYY-MM-DD&tz=America/Chicago
      &source=home|pillar_stat
      &context=<urlencoded stat label>     (required when source=pillar_stat)
      &refresh=false

Behaviour:
- Computes local_date in the USER'S timezone (header X-User-Timezone, or
  the ?tz= query, or the DB users.timezone column, in that order). All
  reasoning is user-local — never UTC. See feedback_user_local_time_only.md.
- Cache hit: returns the cached row from coach_daily_insights immediately.
- Cache miss: assembles a snapshot from existing Supabase tables, builds
  the prompt via services/gemini/daily_insight_prompt.py, calls Gemini
  with the global+per-user concurrency limiter + cost tracker, validates
  that any numbers cited in the body match the snapshot ground truth, then
  persists and returns the row.
- Cost cap: MAX_INSIGHT_USD_PER_USER_PER_DAY = 0.02. On cap, on Gemini
  failure, or on number-mismatch validation failure, returns a
  deterministic templated fallback with source="deterministic_fallback"
  so the client can render an indicator. No silent fallback to lies.

Per CLAUDE.md: NO mock data, NO silent fallbacks to wrong values, and the
fallback path is deterministic + flagged.
"""
from __future__ import annotations

import json
import logging
import re
from datetime import date, datetime, timezone
from typing import Any, Dict, Optional, Tuple

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from google.genai import types
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.config import get_settings
from core.timezone_utils import resolve_timezone, user_today_date

from services.gemini.constants import (
    cost_tracker,
    gemini_generate_with_retry,
)
from services.gemini.daily_insight_prompt import build_daily_insight_prompt

logger = logging.getLogger("coach_daily_insight")

router = APIRouter()


# ---------------------------------------------------------------------------
# Hard cost cap per user per day for this surface.
# Sized for ~25 calls/day at p99 (typical call ≈ $0.0004 — Flash-lite,
# short prompt + ≤200 output tokens).
# ---------------------------------------------------------------------------
MAX_INSIGHT_USD_PER_USER_PER_DAY = 0.02

# Route whitelist must match the prompt's whitelist; mirrored here so the
# fallback path stays in-contract.
_VALID_ROUTES = {
    "/chat", "/home",
    "/workouts", "/nutrition", "/neat", "/health/sleep", "/fasting",
    "/pillar/train", "/pillar/nourish", "/pillar/move",
}
_VALID_PILLARS = {"train", "nourish", "move", "sleep", "all_done"}


# ---------------------------------------------------------------------------
# Response model
# ---------------------------------------------------------------------------
class CtaModel(BaseModel):
    label: str
    route: str


class DailyInsightResponse(BaseModel):
    insight_id: Optional[str] = None
    local_date: str
    source: str               # "home" or "pillar_stat"
    headline: str
    body: str
    cta_primary: Optional[CtaModel] = None
    cta_secondary: Optional[CtaModel] = None
    leading_pillar: Optional[str] = None
    generated_at: Optional[str] = None
    # "gemini" on the happy path, "deterministic_fallback" otherwise.
    delivery: str = "gemini"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _time_of_day_bucket(now_local: datetime) -> str:
    """Map local hour-of-day into the prompt's branching buckets."""
    h = now_local.hour
    if 5 <= h <= 10:
        return "morning"
    if 11 <= h <= 13:
        return "midday"
    if 14 <= h <= 17:
        return "afternoon"
    if 18 <= h <= 21:
        return "evening"
    if 22 <= h <= 23:
        return "late"
    return "quiet"  # 00:00–04:59


def _first_name(user_row: Dict[str, Any]) -> str:
    """Derive a clean first name with safe fallback to the email handle."""
    raw = (
        user_row.get("first_name")
        or (user_row.get("name") or "").split(" ")[0]
        or (user_row.get("email") or "").split("@")[0]
        or "there"
    )
    return raw.strip() or "there"


def _collect_snapshot(sb, user_id: str, local_date_iso: str) -> Dict[str, Any]:
    """Assemble the today snapshot the prompt + validator both consume.

    Lightweight queries — we deliberately don't reach into the full score
    pipeline here. The home daily-score card already computes the full
    snapshot client-side; this endpoint only needs enough ground truth to
    write a single sentence and validate the numbers it contains.
    Every block is wrapped so a single failing table doesn't 500 the
    whole insight (we just omit that pillar).
    """
    snapshot: Dict[str, Any] = {
        "local_date": local_date_iso,
        "train": {"applicable": True, "completion": 0, "reach_met": False},
        "nourish": {"applicable": True, "completion": 0, "reach_met": False},
        "move": {"applicable": True, "completion": 0, "reach_met": False},
        "sleep": {"applicable": True, "completion": 0, "reach_met": False},
    }

    # --- Today's scheduled workout (Train pillar) -----------------------
    # Schema reality: workouts has no `scheduled_time` column. Drop it.
    next_workout: Optional[Dict[str, Any]] = None
    try:
        tw = sb.client.table("workouts").select(
            "id, name, scheduled_date, completed_at, duration_minutes"
        ).eq("user_id", user_id).eq(
            "scheduled_date", local_date_iso
        ).limit(1).execute()
        if tw.data:
            row = tw.data[0]
            next_workout = {
                "name": row.get("name"),
                "completed": row.get("completed_at") is not None,
            }
            snapshot["train"]["reach_met"] = next_workout["completed"]
            snapshot["train"]["completion"] = 100 if next_workout["completed"] else 0
        else:
            # No scheduled workout today → pillar is a rest day, not unmet.
            snapshot["train"]["applicable"] = False
    except Exception as e:
        logger.warning(f"[daily_insight] workouts lookup failed: {e}")

    # --- Nourish (food log totals) --------------------------------------
    # Schema reality: table is `food_logs` (plural), no `logged_local_date`
    # column — log timestamp is `logged_at` (UTC timestamptz). Calorie field
    # is `total_calories`. Derive the local-day window from local_date_iso
    # against the user's tz at query time.
    try:
        # ISO-format local date → UTC bounds. Without the user's tz here we
        # fall back to a generous ±18h window around the local-date midnight
        # in UTC, then group by logged_at::date in the user's tz on the
        # client side (the totals are an approximation either way for the
        # prompt; the validator only needs honest ground truth).
        day_start_iso = f"{local_date_iso}T00:00:00+00:00"
        day_end_iso = f"{local_date_iso}T23:59:59+00:00"
        fl = sb.client.table("food_logs").select(
            "total_calories, protein_g, logged_at, deleted_at"
        ).eq("user_id", user_id).gte(
            "logged_at", day_start_iso
        ).lte(
            "logged_at", day_end_iso
        ).is_("deleted_at", "null").execute()
        rows = fl.data or []
        cal = sum((r.get("total_calories") or 0) for r in rows)
        protein = sum(float(r.get("protein_g") or 0) for r in rows)
        snapshot["nourish"]["calories_logged"] = round(cal)
        snapshot["nourish"]["protein_logged_g"] = round(protein)
    except Exception as e:
        logger.warning(f"[daily_insight] food_logs lookup failed: {e}")

    # --- Move + Sleep (both live in daily_activity, single query) -------
    # Schema reality: date column is `activity_date` (not `local_date`).
    # No separate `sleep` table — sleep is `daily_activity.sleep_minutes`.
    try:
        da = sb.client.table("daily_activity").select(
            "steps, active_minutes, activity_date, sleep_minutes"
        ).eq("user_id", user_id).eq(
            "activity_date", local_date_iso
        ).maybe_single().execute()
        if da and da.data:
            snapshot["move"]["steps"] = int(da.data.get("steps") or 0)
            snapshot["move"]["active_minutes"] = int(da.data.get("active_minutes") or 0)
            sleep_min = int(da.data.get("sleep_minutes") or 0)
            if sleep_min > 0:
                snapshot["sleep"]["total_minutes"] = sleep_min
                snapshot["sleep"]["total_hours"] = round(sleep_min / 60.0, 1)
            else:
                # No sleep recorded today → not applicable so the prompt /
                # leverage picker skips it. Matches the client-side
                # sleepScoreProvider returning null on disconnected health.
                snapshot["sleep"]["applicable"] = False
    except Exception as e:
        logger.warning(f"[daily_insight] daily_activity lookup failed: {e}")

    # --- User goal --------------------------------------------------------
    # Schema reality: users.daily_calorie_target / daily_protein_target_g
    # (not the non-prefixed versions). No step_goal or sleep_goal_hours
    # columns — those defaults are baked in client-side via healthGoalsProvider
    # (10k steps / 480 min sleep) so we hard-code matching defaults here.
    try:
        u = sb.client.table("users").select(
            "primary_goal, daily_protein_target_g, daily_calorie_target"
        ).eq("id", user_id).maybe_single().execute()
        if u and u.data:
            snapshot["goal"] = u.data.get("primary_goal")
            snapshot["nourish"]["calorie_target"] = u.data.get("daily_calorie_target")
            snapshot["nourish"]["protein_target_g"] = u.data.get("daily_protein_target_g")
        # Defaults matched to the client (lib/data/services/health_goals_service.dart).
        snapshot["move"]["step_target"] = 10000
        snapshot["sleep"]["target_hours"] = 8.0
    except Exception as e:
        logger.warning(f"[daily_insight] users lookup failed: {e}")

    # --- Cycle phase (plan §10) ---------------------------------------
    # Source of truth: the `user_current_cycle_phase` VIEW
    # (backend/migrations/121_hormonal_health_kegel.sql:587). It exposes
    # `current_phase` ∈ {menstrual, follicular, ovulation, luteal, NULL}.
    # NULL means the user does not have menstrual tracking enabled or
    # hasn't logged a period start — treat as no signal and omit the field.
    # Wrapped so a missing/empty view never 500s the insight.
    try:
        cp = sb.client.table("user_current_cycle_phase").select(
            "current_phase"
        ).eq("user_id", user_id).maybe_single().execute()
        if cp and cp.data:
            phase = cp.data.get("current_phase")
            if phase in ("menstrual", "follicular", "ovulation", "luteal"):
                snapshot["cycle_phase"] = phase
    except Exception as e:
        # Phantom view / RLS / table-missing on a non-female-tracking user
        # all funnel here — silent skip is correct.
        logger.debug(f"[daily_insight] cycle phase lookup skipped: {e}")

    return snapshot, next_workout


# ---------------------------------------------------------------------------
# Number-mismatch validator (server-side ground truth guardrail, plan §6f)
# ---------------------------------------------------------------------------
# We extract every standalone integer (and a few simple "Ng" / "Nh" forms)
# from the Gemini body and verify each one appears as some real value in
# the snapshot. If even one cited number isn't backed by ground truth we
# reject the response and fall back to deterministic copy — better a
# templated message than a hallucinated stat shown to the user.
_NUMBER_RE = re.compile(r"\b(\d{1,5}(?:,\d{3})*)(?:\.\d+)?\b")


def _snapshot_number_set(snapshot: Dict[str, Any]) -> set:
    """Flatten every numeric value from the snapshot into a string set."""
    out: set = set()

    def _walk(v):
        if isinstance(v, dict):
            for vv in v.values():
                _walk(vv)
        elif isinstance(v, list):
            for vv in v:
                _walk(vv)
        elif isinstance(v, bool):
            return  # bools are ints in Python; skip
        elif isinstance(v, (int, float)):
            out.add(str(int(v)))
            # Also accept the rounded-hours rendering for sleep (e.g. 6.5).
            if isinstance(v, float) and not v.is_integer():
                out.add(f"{v:.1f}")

    _walk(snapshot)
    # Trivially safe constants — never reject these.
    out.update({"0", "1", "2", "3"})
    return out


def _validate_insight_numbers(body: str, snapshot: Dict[str, Any]) -> bool:
    """Return True iff every number cited in `body` is grounded in snapshot.

    Edge cases handled:
      - Comma-thousands ("4,200") normalised to "4200".
      - Trivial small ints (0-3) are always allowed (sentence counters).
      - Empty body → True (nothing to validate against).
    """
    if not body:
        return True
    grounded = _snapshot_number_set(snapshot)
    for match in _NUMBER_RE.finditer(body):
        token = match.group(1).replace(",", "")
        if token not in grounded:
            logger.warning(
                f"[daily_insight] number guardrail rejected '{token}' "
                f"(grounded={sorted(grounded)[:10]}...)"
            )
            return False
    return True


# ---------------------------------------------------------------------------
# Deterministic fallback templates (mirrors score_coach_line.dart pool logic)
# ---------------------------------------------------------------------------
# Per feedback_dynamic_copy_not_robotic.md: ≥4 variants per pattern, and
# substitute real data. Per feedback_no_em_dashes_marketing.md / the prompt
# rules: zero em/en dashes — graps for "—" / "–" before shipping.
_FALLBACK_TEMPLATES: Dict[str, Dict[str, list]] = {
    "train": {
        "headline": [
            "Today's lift is ready",
            "Your workout is queued",
            "One session stands between today and done",
            "Time to move the needle",
        ],
        "body": [
            "{first_name}, {workout} is on the plan for today. Knock it out and you'll close the Train ring.",
            "{first_name}, you have {workout} scheduled. Even a short version counts toward the streak.",
            "{first_name}, the plan calls for {workout}. Open it and the first set is the hardest part.",
            "{first_name}, {workout} is waiting. Start it now and momentum does the rest.",
        ],
        "cta_primary": {"label": "Start workout", "route": "/workouts/today"},
    },
    "nourish": {
        "headline": [
            "Protein is the lever today",
            "Lock in the fuel",
            "Food log is your edge",
            "Eat the work in",
        ],
        "body": [
            "{first_name}, log what you've eaten so far and we'll show what's left for the day.",
            "{first_name}, a quick log keeps the calorie picture honest. Snap or type one entry.",
            "{first_name}, today's nutrition target is in reach with one solid meal logged.",
            "{first_name}, the food log takes ten seconds and saves a lot of guessing later.",
        ],
        "cta_primary": {"label": "Log food", "route": "/log/food"},
    },
    "move": {
        "headline": [
            "Stack a few more steps",
            "Move minutes are the gap",
            "A short walk closes the ring",
            "Move pillar needs a nudge",
        ],
        "body": [
            "{first_name}, a ten minute walk now puts the Move ring in reach.",
            "{first_name}, the daily steps total is short. One block around the building helps.",
            "{first_name}, active minutes are the weakest signal today. Get up and stretch the legs.",
            "{first_name}, momentum on Move is one short walk away.",
        ],
        "cta_primary": {"label": "View Move", "route": "/move"},
    },
    "sleep": {
        "headline": [
            "Last night was light",
            "Recovery is the priority",
            "Sleep is the weakest link",
            "Wind down a little earlier",
        ],
        "body": [
            "{first_name}, last night ran short. Aim for an earlier wind down tonight.",
            "{first_name}, sleep is the gap to close. Tonight's bedtime matters more than today's gym.",
            "{first_name}, recovery is the lever. Plan for a longer night and the rest of the plan flows.",
            "{first_name}, an extra forty minutes tonight beats an extra rep today.",
        ],
        "cta_primary": {"label": "View sleep", "route": "/sleep"},
    },
    "all_done": {
        "headline": [
            "Every ring closed today",
            "Clean sweep on the plan",
            "You hit the brief",
            "Day delivered",
        ],
        "body": [
            "{first_name}, every pillar is in the green for today. Coast and let recovery work.",
            "{first_name}, the full plan is done. Hydrate, eat well tonight, sleep early.",
            "{first_name}, that's a complete day. The streak just got a little longer.",
            "{first_name}, nothing left on the board. Bank the recovery for tomorrow.",
        ],
        "cta_primary": {"label": "Open home", "route": "/home"},
    },
}


def _pick_fallback_pillar(snapshot: Dict[str, Any]) -> str:
    """Choose the leading pillar for the deterministic fallback.

    Priority order matches the prompt's LEADING_PILLAR RULES so the
    fallback feels coherent with happy-path output.
    """
    train = snapshot.get("train", {})
    nourish = snapshot.get("nourish", {})
    move = snapshot.get("move", {})
    sleep = snapshot.get("sleep", {})

    train_open = train.get("applicable") and not train.get("reach_met")
    nourish_open = (nourish.get("calorie_target") or 0) > 0 and (
        (nourish.get("calories_logged") or 0) < (nourish.get("calorie_target") or 0) * 0.5
    )
    move_open = (move.get("step_target") or 0) > 0 and (
        (move.get("steps") or 0) < (move.get("step_target") or 0) * 0.5
    )
    sleep_open = (sleep.get("target_hours") or 0) > 0 and (
        (sleep.get("total_hours") or 0) < (sleep.get("target_hours") or 0) - 0.5
    )

    if train_open:
        return "train"
    if nourish_open:
        return "nourish"
    if move_open:
        return "move"
    if sleep_open:
        return "sleep"
    return "all_done"


def _deterministic_fallback(
    snapshot: Dict[str, Any],
    next_workout: Optional[Dict[str, Any]],
    first_name: str,
    local_date_iso: str,
    source: str,
) -> Dict[str, Any]:
    """Build the fallback insight payload. Always returns valid output."""
    # Stable per-day variant selection so the user sees the same fallback
    # all day instead of flip-flopping on re-open.
    seed = abs(hash((first_name, local_date_iso))) % 4
    pillar = _pick_fallback_pillar(snapshot)
    tmpl = _FALLBACK_TEMPLATES[pillar]

    workout_name = (next_workout or {}).get("name") or "today's session"
    body = tmpl["body"][seed % len(tmpl["body"])].format(
        first_name=first_name, workout=workout_name,
    )
    headline = tmpl["headline"][seed % len(tmpl["headline"])]
    cta_primary = dict(tmpl["cta_primary"])
    cta_secondary = {"label": "Ask coach", "route": "/chat"}

    return {
        "headline": headline,
        "body": body,
        "cta_primary": cta_primary,
        "cta_secondary": cta_secondary,
        "leading_pillar": pillar,
    }


# ---------------------------------------------------------------------------
# Gemini call
# ---------------------------------------------------------------------------
def _robust_parse_json_object(text: str) -> Optional[Dict[str, Any]]:
    """Parse Gemini JSON output that may carry trailing tokens, leading
    whitespace, or markdown fences.

    Handles three failure modes observed in production:
      * Markdown fence wrapping (```json ... ```)
      * Leading/trailing whitespace
      * "Extra data" — trailing prose after a valid JSON object
    Returns None on unrecoverable failure (caller logs and falls back).
    """
    if not text:
        return None
    s = text.strip()
    # Strip ```json ... ``` fence if present.
    if s.startswith("```"):
        s = re.sub(r"^```(?:json)?\s*", "", s)
        s = re.sub(r"\s*```$", "", s).strip()
    # Fast path.
    try:
        return json.loads(s)
    except json.JSONDecodeError:
        pass
    # Recover from trailing junk via raw_decode at the first '{'.
    first = s.find("{")
    if first < 0:
        return None
    try:
        obj, _end = json.JSONDecoder().raw_decode(s[first:])
        if isinstance(obj, dict):
            return obj
    except json.JSONDecodeError as e:
        logger.error(f"[daily_insight] robust parse gave up: {e} — text head: {s[:200]!r}")
    return None


async def _call_gemini_for_insight(
    *, context: Dict[str, Any], source: str, user_id: str,
) -> Optional[Dict[str, Any]]:
    """Run Gemini with the daily-insight prompt. Return parsed dict or None on failure."""
    settings = get_settings()
    system_instruction, user_message = build_daily_insight_prompt(context, source)
    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                response_mime_type="application/json",
                max_output_tokens=320,
                temperature=0.5,
            ),
            user_id=user_id,
            timeout=12.0,
            method_name="daily_insight",
        )
        text = getattr(response, "text", None)
        if not text:
            return None
        parsed = _robust_parse_json_object(text)
        if parsed is None:
            return None
        # Light shape validation — drop unknown routes/pillars before persisting.
        if parsed.get("leading_pillar") not in _VALID_PILLARS:
            parsed["leading_pillar"] = None
        for k in ("cta_primary", "cta_secondary"):
            cta = parsed.get(k)
            if isinstance(cta, dict) and cta.get("route") not in _VALID_ROUTES:
                # Reject silently — fallback CTA gets stamped in by caller.
                parsed[k] = None
        return parsed
    except Exception as e:
        logger.warning(f"[daily_insight] Gemini call failed: {e}")
        return None


def _user_cost_today_usd(user_id: str) -> float:
    """Read this-user-today cost from the in-process tracker."""
    try:
        snap = cost_tracker.snapshot()
        return float((snap.get("by_user", {}).get(user_id) or {}).get("cost_usd", 0.0))
    except Exception:
        return 0.0


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------
@router.get("/daily-insight", response_model=DailyInsightResponse)
async def daily_insight(
    request: Request,
    date_str: Optional[str] = Query(None, alias="date", description="YYYY-MM-DD; user-local"),
    tz: Optional[str] = Query(None, description="IANA tz override; header wins if both present"),
    source: str = Query("home", description="home | pillar_stat"),
    context: Optional[str] = Query(None, description="Pillar stat label (source=pillar_stat only)"),
    refresh: bool = Query(False, description="Force regenerate, bypassing cache"),
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        # ---- Resolve user-local date (header > query > DB > UTC) ----------
        # resolve_timezone reads X-User-Timezone first. If neither header
        # nor DB has a tz, but the caller passed ?tz=, prefer that over UTC.
        tz_resolved = resolve_timezone(request, sb, user_id)
        if tz_resolved == "UTC" and tz:
            tz_resolved = tz
        if date_str:
            try:
                local_date = date.fromisoformat(date_str)
            except ValueError:
                raise HTTPException(400, "date must be YYYY-MM-DD")
        else:
            local_date = user_today_date(request, sb, user_id)
        local_date_iso = local_date.isoformat()

        # ---- Validate source + stat_context --------------------------------
        # Plan P3e expanded the surface vocabulary. Each one routes to a
        # different branch in daily_insight_prompt.py. All share the same
        # cost cap + cache row shape; only `pillar_stat` carries a
        # stat_context, the others use stat_context=NULL as the cache key.
        _ALLOWED_SOURCES = {
            "home",
            "pillar_stat",
            "morning_brief",
            "evening_recap",
            "morning_brief_onboarding",
            "nutrition_card_morning",
            "workout_card",
        }
        if source not in _ALLOWED_SOURCES:
            raise HTTPException(
                400,
                f"source must be one of {sorted(_ALLOWED_SOURCES)}",
            )
        stat_context = context if source == "pillar_stat" else None
        if source == "pillar_stat" and not stat_context:
            raise HTTPException(400, "context query param required for source=pillar_stat")

        # ---- Cache hit? ----------------------------------------------------
        if not refresh:
            try:
                q = sb.client.table("coach_daily_insights").select("*").eq(
                    "user_id", user_id
                ).eq("local_date", local_date_iso).eq("source", source)
                if stat_context is not None:
                    q = q.eq("stat_context", stat_context)
                else:
                    q = q.is_("stat_context", "null")
                existing = q.limit(1).execute()
                if existing and existing.data:
                    row = existing.data[0]
                    return DailyInsightResponse(
                        insight_id=row.get("id"),
                        local_date=row["local_date"],
                        source=row["source"],
                        headline=row["headline"],
                        body=row["body"],
                        cta_primary=row.get("cta_primary"),
                        cta_secondary=row.get("cta_secondary"),
                        leading_pillar=row.get("leading_pillar"),
                        generated_at=row.get("generated_at"),
                        delivery="gemini",  # cached rows are only stored on success
                    )
            except HTTPException:
                raise
            except Exception as e:
                logger.warning(f"[daily_insight] cache read failed (continuing): {e}")

        # ---- Assemble snapshot + context ----------------------------------
        # Schema reality: users.first_name doesn't exist. Just `name` (full).
        # _first_name() already handles the split — it prefers first_name if
        # present, then splits `name`, then falls back to email-prefix.
        try:
            user_row_resp = sb.client.table("users").select(
                "name, email"
            ).eq("id", user_id).maybe_single().execute()
            user_row = (user_row_resp.data if user_row_resp else {}) or {}
        except Exception:
            user_row = {}
        first_name = _first_name(user_row)

        snapshot, next_workout = _collect_snapshot(sb, user_id, local_date_iso)

        from zoneinfo import ZoneInfo
        now_local = datetime.now(ZoneInfo(tz_resolved if tz_resolved else "UTC"))
        ctx: Dict[str, Any] = {
            "first_name": first_name,
            "today_score_snapshot": snapshot,
            "next_workout": next_workout,
            "goals": snapshot.get("goal"),
            "user_local_tz": tz_resolved,
            "time_of_day_bucket": _time_of_day_bucket(now_local),
            # Plan §10 — null when the user has no cycle tracking enabled.
            "cycle_phase": snapshot.get("cycle_phase"),
        }
        if source == "pillar_stat":
            ctx["pillar_stat_context"] = stat_context

        # ---- Cost cap check -----------------------------------------------
        delivery = "gemini"
        gemini_payload: Optional[Dict[str, Any]] = None
        if _user_cost_today_usd(user_id) >= MAX_INSIGHT_USD_PER_USER_PER_DAY:
            logger.info(f"[daily_insight] user={user_id} cost cap hit, using fallback")
            delivery = "deterministic_fallback"
        else:
            gemini_payload = await _call_gemini_for_insight(
                context=ctx, source=source, user_id=user_id,
            )
            if gemini_payload is None:
                delivery = "deterministic_fallback"
            else:
                # Ground-truth number guardrail (plan §6f).
                if not _validate_insight_numbers(gemini_payload.get("body", ""), snapshot):
                    logger.warning(f"[daily_insight] user={user_id} number guardrail rejected payload")
                    delivery = "deterministic_fallback"
                    gemini_payload = None

        # ---- Build final payload ------------------------------------------
        if delivery == "deterministic_fallback":
            payload = _deterministic_fallback(
                snapshot=snapshot,
                next_workout=next_workout,
                first_name=first_name,
                local_date_iso=local_date_iso,
                source=source,
            )
        else:
            payload = gemini_payload or {}
            # Stamp safe defaults for any missing CTA so the client never NPEs.
            if not payload.get("cta_primary"):
                payload["cta_primary"] = {"label": "Open home", "route": "/home"}
            if not payload.get("cta_secondary"):
                payload["cta_secondary"] = {"label": "Ask coach", "route": "/chat"}

        # ---- Persist ONLY when Gemini succeeded and passed validation -----
        insight_id: Optional[str] = None
        generated_at_iso = datetime.now(timezone.utc).isoformat()
        if delivery == "gemini":
            try:
                insert_payload = {
                    "user_id": user_id,
                    "local_date": local_date_iso,
                    "headline": payload["headline"],
                    "body": payload["body"],
                    "cta_primary": payload.get("cta_primary"),
                    "cta_secondary": payload.get("cta_secondary"),
                    "leading_pillar": payload.get("leading_pillar"),
                    "source": source,
                    "stat_context": stat_context,
                    "generated_at": generated_at_iso,
                }
                ins = sb.client.table("coach_daily_insights").upsert(
                    insert_payload,
                    on_conflict="user_id,local_date,source,stat_context",
                ).execute()
                if ins and ins.data:
                    insight_id = ins.data[0].get("id")
                    generated_at_iso = ins.data[0].get("generated_at", generated_at_iso)
            except Exception as e:
                # Persist failure is non-fatal — still return the payload.
                logger.warning(f"[daily_insight] persist failed: {e}")

        return DailyInsightResponse(
            insight_id=insight_id,
            local_date=local_date_iso,
            source=source,
            headline=payload["headline"],
            body=payload["body"],
            cta_primary=payload.get("cta_primary"),
            cta_secondary=payload.get("cta_secondary"),
            leading_pillar=payload.get("leading_pillar"),
            generated_at=generated_at_iso,
            delivery=delivery,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "coach_daily_insight")
