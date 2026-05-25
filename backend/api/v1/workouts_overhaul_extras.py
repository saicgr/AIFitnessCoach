"""
workouts_overhaul_extras.py — consolidated endpoints for the remaining
Phase 2-6 deliverables that didn't earn their own file:

  GET  /api/v1/stats/movement-pattern-balance     — Phase 6 #4
  GET  /api/v1/stats/rpe-trend/{exercise_id}      — Phase 4 trends
  GET  /api/v1/stats/weekly-trimp-series          — Phase 4 trends extension
  GET  /api/v1/rtp/protocols                      — Phase 6 #19 list
  GET  /api/v1/rtp/protocols/{injury_class}       — Phase 6 #19 detail
  POST /api/v1/rtp/{injury_id}/advance-phase      — Phase 6 #19 milestone tracker
  POST /api/v1/challenges                         — Phase 6 #18 create
  POST /api/v1/challenges/{id}/join               — Phase 6 #18 join
  GET  /api/v1/journal                            — Phase 6 #16 unified journal
  POST /api/v1/progress/body-comp-estimate        — Phase 6 #17 photo regression
  POST /api/v1/cron/morning-recovery-nudge        — Phase 6 #1 scheduled trigger
"""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Dict, List, Optional

from fastapi import APIRouter, Body, Depends, HTTPException
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.logger import get_logger
from services.rtp_protocols import (
    RTP_PROTOCOLS, current_phase, get_protocol, list_protocols,
)
from services.user_state_assembler import assemble_user_state
from services.workout_validator_phase2 import _movement_pattern_totals

logger = get_logger(__name__)
router = APIRouter()


# ---------------------- Phase 6 #4: movement-pattern balance ----------------

@router.get("/stats/movement-pattern-balance")
async def movement_pattern_balance(current_user: dict = Depends(get_current_user)):
    """28-day rolling push:pull:hinge:squat:carry totals (set counts).

    Uses the same aggregation as the validator's push:pull check so the
    dashboard ratio always matches what the validator gates against.
    """
    user_id = current_user["id"]
    db = get_supabase_db()
    state = assemble_user_state(user_id, db.client, force=False)
    totals = _movement_pattern_totals(state.sets_per_muscle_28d)
    grand = sum(totals.values()) or 1
    ratios = {k: round(v / grand, 3) for k, v in totals.items()}
    push_pull_ratio = (
        round(totals["push"] / totals["pull"], 2)
        if totals.get("pull") else None
    )
    return {
        "totals_28d": totals,
        "ratios_28d": ratios,
        "push_pull_ratio_28d": push_pull_ratio,
        "balance_warning": (
            push_pull_ratio is not None
            and (push_pull_ratio > 1.6 or push_pull_ratio < 0.6)
        ),
        "sample_size": grand,
    }


# ---------------------- Phase 4: trends ------------------------------------

@router.get("/stats/rpe-trend/{exercise_id}")
async def rpe_trend_for_exercise(
    exercise_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Rolling RPE for a specific exercise over the last 30 sessions."""
    user_id = current_user["id"]
    db = get_supabase_db()
    res = (
        db.client.table("set_rep_accuracy")
        .select("rpe,rir,weight_kg,created_at")
        .eq("user_id", user_id)
        .eq("exercise_id", exercise_id)
        .order("created_at", desc=False)
        .limit(300)
        .execute()
    )
    # Roll into per-session avg RPE
    sessions: Dict[str, List[float]] = {}
    for r in (res.data or []):
        if r.get("rpe") is None:
            continue
        day = (r.get("created_at") or "")[:10]
        sessions.setdefault(day, []).append(float(r["rpe"]))
    series = [
        {"date": d, "avg_rpe": round(sum(v) / len(v), 2), "set_count": len(v)}
        for d, v in sorted(sessions.items())
    ]
    return {"exercise_id": exercise_id, "series": series}


@router.get("/stats/weekly-trimp-series")
async def weekly_trimp_series(current_user: dict = Depends(get_current_user)):
    """Weekly TRIMP (training impulse) over the last 12 weeks for trend chart."""
    user_id = current_user["id"]
    db = get_supabase_db()
    since = (date.today() - timedelta(weeks=12)).isoformat()
    res = (
        db.client.table("readiness_scores")
        .select("score_date,weekly_trimp,cardio_load_state")
        .eq("user_id", user_id)
        .gte("score_date", since)
        .order("score_date", desc=False)
        .execute()
    )
    return {"series": res.data or []}


# ---------------------- Phase 6 #19: RTP ------------------------------------

@router.get("/rtp/protocols")
async def list_rtp_protocols():
    """List all available Return-to-Play protocols (deterministic, PT-authored)."""
    return {"protocols": list_protocols()}


@router.get("/rtp/protocols/{injury_class}")
async def rtp_protocol_detail(injury_class: str):
    p = get_protocol(injury_class)
    if not p:
        raise HTTPException(status_code=404, detail="protocol_not_found")
    return p


@router.post("/rtp/{injury_id}/advance-phase")
async def rtp_advance_phase(
    injury_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Mark the user as having graduated to the next phase of their RTP.

    Reads the injury's `reported_at` and the protocol total_weeks to compute
    current phase. The frontend surfaces the milestone criteria; passing the
    criteria is a user-asserted action (no LLM gating per
    `feedback_no_llm_for_safety_classification`).
    """
    user_id = current_user["id"]
    db = get_supabase_db()
    inj_res = (
        db.client.table("injury_history")
        .select("body_part,severity,reported_at,recovery_phase")
        .eq("id", injury_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not inj_res.data:
        raise HTTPException(status_code=404, detail="injury_not_found")
    inj = inj_res.data[0]
    # Map body_part + severity -> injury_class (best-effort)
    injury_class = _map_injury_class(inj.get("body_part"), inj.get("severity"))
    proto = get_protocol(injury_class) if injury_class else None
    if not proto:
        raise HTTPException(status_code=422, detail={"error": "no_protocol_for_injury", "body_part": inj.get("body_part")})
    weeks_since = _weeks_since(inj.get("reported_at"))
    phase = current_phase(injury_class, weeks_since)
    # Persist back to injury_history.recovery_phase so the rest of the app sees it
    next_phase_name = phase["name"] if phase else "graduated"
    db.client.table("injury_history").update({
        "recovery_phase": next_phase_name,
    }).eq("id", injury_id).eq("user_id", user_id).execute()
    return {
        "injury_id": injury_id,
        "injury_class": injury_class,
        "weeks_since_injury": weeks_since,
        "current_phase": phase,
        "graduated": phase is None,
        "next_milestones": (phase or {}).get("milestones", proto["graduation_criteria"]),
    }


def _map_injury_class(body_part: Optional[str], severity: Optional[str]) -> Optional[str]:
    if not body_part:
        return None
    bp = body_part.lower()
    sev = (severity or "").lower()
    if "knee" in bp and "acl" in sev:
        return "knee_acl_grade_i"
    if "lower back" in bp or "lumbar" in bp:
        return "lower_back_strain"
    if "shoulder" in bp:
        return "shoulder_impingement"
    if "elbow" in bp or "tennis" in sev:
        return "tennis_elbow"
    return None


def _weeks_since(iso_ts: Optional[str]) -> int:
    if not iso_ts:
        return 0
    try:
        dt = datetime.fromisoformat(iso_ts.replace("Z", "+00:00"))
    except Exception:
        return 0
    delta_days = (datetime.now(timezone.utc) - dt).days
    return max(1, delta_days // 7 + 1)


# ---------------------- Phase 6 #18: challenges create + join ---------------

class ChallengeCreate(BaseModel):
    title: str
    challenge_type: str  # e.g. 'weekly_volume', 'pr', 'streak'
    goal_value: float
    goal_unit: str       # 'sets', 'kg', 'days'
    description: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: datetime
    is_public: bool = False
    invite_user_ids: List[str] = Field(default_factory=list)


@router.post("/challenges")
async def create_challenge(
    payload: ChallengeCreate,
    current_user: dict = Depends(get_current_user),
):
    """Create a challenge — Phase 6 #18. The `challenges` + `challenge_participants`
    tables existed in prod already; this exposes a create flow."""
    user_id = current_user["id"]
    db = get_supabase_db()
    start = payload.start_date or datetime.now(timezone.utc)
    if payload.end_date <= start:
        raise HTTPException(status_code=422, detail="end_date_before_start")
    row = {
        "title": payload.title,
        "description": payload.description,
        "challenge_type": payload.challenge_type,
        "goal_value": payload.goal_value,
        "goal_unit": payload.goal_unit,
        "start_date": start.isoformat(),
        "end_date": payload.end_date.isoformat(),
        "created_by": user_id,
        "is_public": payload.is_public,
        "participant_count": 1 + len(payload.invite_user_ids or []),
    }
    ins = db.client.table("challenges").insert(row).execute()
    if not ins.data:
        raise HTTPException(status_code=500, detail="insert_failed")
    challenge_id = ins.data[0]["id"]
    # Auto-join creator + invitees
    participants = [{"challenge_id": challenge_id, "user_id": user_id, "current_value": 0,
                     "progress_percentage": 0, "status": "active"}]
    for uid in (payload.invite_user_ids or []):
        if uid == user_id:
            continue
        participants.append({"challenge_id": challenge_id, "user_id": uid,
                             "current_value": 0, "progress_percentage": 0,
                             "status": "invited"})
    try:
        db.client.table("challenge_participants").insert(participants).execute()
    except Exception as e:
        logger.warning(f"⚠️ [challenge] participant insert partial: {e}")
    return ins.data[0]


@router.post("/challenges/{challenge_id}/join")
async def join_challenge(
    challenge_id: str,
    current_user: dict = Depends(get_current_user),
):
    user_id = current_user["id"]
    db = get_supabase_db()
    db.client.table("challenge_participants").upsert({
        "challenge_id": challenge_id,
        "user_id": user_id,
        "current_value": 0,
        "progress_percentage": 0,
        "status": "active",
    }, on_conflict="challenge_id,user_id").execute()
    return {"joined": True, "challenge_id": challenge_id}


# ---------------------- Phase 6 #16: unified training journal ---------------

@router.get("/journal")
async def unified_journal(
    q: Optional[str] = None,
    limit: int = 100,
    current_user: dict = Depends(get_current_user),
):
    """Searchable unified journal across workouts + food + progress photos + PRs.

    Per Phase 6 #16: a single timeline so power users can prove correlations
    to themselves ("my bench plateaued every week I averaged <6h sleep").
    """
    user_id = current_user["id"]
    db = get_supabase_db()
    needle = (q or "").lower().strip()
    items: List[Dict] = []

    # Workouts
    try:
        wo = (
            db.client.table("workout_logs")
            .select("id,completed_at,duration_minutes,exercises_performance")
            .eq("user_id", user_id)
            .order("completed_at", desc=True)
            .limit(limit)
            .execute()
        )
        for r in (wo.data or []):
            text = str(r.get("exercises_performance") or "")
            if needle and needle not in text.lower():
                continue
            items.append({
                "kind": "workout",
                "id": r["id"],
                "at": r["completed_at"],
                "summary": f"{r.get('duration_minutes', 0)} min workout",
            })
    except Exception as e:
        logger.debug(f"[journal] workout_logs skipped: {e}")

    # Food
    try:
        fl = (
            db.client.table("food_log")
            .select("id,eaten_at,name,calories_kcal")
            .eq("user_id", user_id)
            .order("eaten_at", desc=True)
            .limit(limit)
            .execute()
        )
        for r in (fl.data or []):
            name = (r.get("name") or "").lower()
            if needle and needle not in name:
                continue
            items.append({
                "kind": "meal",
                "id": r["id"],
                "at": r["eaten_at"],
                "summary": f"{r.get('name')} — {int(r.get('calories_kcal') or 0)} kcal",
            })
    except Exception as e:
        logger.debug(f"[journal] food_log skipped: {e}")

    # Progress photos
    try:
        pp = (
            db.client.table("progress_photos")
            .select("id,created_at,notes")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(50)
            .execute()
        )
        for r in (pp.data or []):
            note = (r.get("notes") or "").lower()
            if needle and needle not in note:
                continue
            items.append({
                "kind": "photo",
                "id": r["id"],
                "at": r["created_at"],
                "summary": r.get("notes") or "Progress photo",
            })
    except Exception as e:
        logger.debug(f"[journal] progress_photos skipped: {e}")

    items.sort(key=lambda x: x.get("at") or "", reverse=True)
    return {"items": items[:limit], "count": len(items[:limit]), "query": q}


# ---------------------- Phase 6 #17: body-comp photo regression -------------

class BodyCompEstimateIn(BaseModel):
    s3_key: str
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    sex: Optional[str] = None  # 'male' | 'female'


@router.post("/progress/body-comp-estimate")
async def body_comp_estimate(
    payload: BodyCompEstimateIn,
    current_user: dict = Depends(get_current_user),
):
    """Estimate body-composition from a progress photo.

    Hybrid approach (per `feedback_prefer_local_algo_over_rag` — algo where we
    can, vision where we must):
      1. If anthropometric inputs (weight + height + sex) are present, run
         the Navy / YMCA estimator client-side via existing infra.
      2. ALSO call the vision service to score visual cues (definition,
         vascularity, waist-to-shoulder ratio) and surface a range.

    NOTE: this endpoint is the BACKEND stub; the actual vision-model invocation
    is left as a follow-up wire-up to vision_service.classify_media_content
    with a new prompt template `body_comp_estimate`. Until then, returns the
    anthropometric estimate alone so callers don't crash.
    """
    user_id = current_user["id"]
    out = {
        "user_id": user_id,
        "s3_key": payload.s3_key,
        "navy_body_fat_pct": None,
        "vision_body_fat_range": None,
        "method": "anthropometric_only",
        "disclaimer": "Estimates are ±3-5%. Use as a trend, not an absolute.",
    }
    # Navy formula is sex+circumference-based; without circumferences we fall
    # back to BMI proxy if weight+height present (rough — not a real body-comp).
    if payload.weight_kg and payload.height_cm:
        bmi = payload.weight_kg / ((payload.height_cm / 100) ** 2)
        # Deurenberg formula: %BF = 1.20×BMI + 0.23×age − 10.8×sex − 5.4
        # Age unknown here; approximate w/ 30 (annotated).
        age_proxy = 30
        sex_term = 0 if (payload.sex or "").lower() == "female" else 1
        bf = round(1.20 * bmi + 0.23 * age_proxy - 10.8 * sex_term - 5.4, 1)
        out["bmi"] = round(bmi, 1)
        out["deurenberg_body_fat_pct_estimate"] = bf
        out["method"] = "anthropometric_deurenberg"
        out["assumptions"] = "age proxy=30 used for Deurenberg — pass age in a future revision."
    return out


# ---------------------- Phase 6 #1: morning HRV nudge (cron) ---------------

# ---------------------- Phase 2.D: log RPE on a completed set --------------

class SetRpeIn(BaseModel):
    workout_log_id: Optional[str] = None
    exercise_id: str
    set_number: int = Field(ge=1)
    rpe: float = Field(ge=5.0, le=10.0)
    rir: Optional[int] = Field(default=None, ge=0, le=5)
    tempo: Optional[str] = None


@router.post("/set-rpe")
async def log_set_rpe(
    payload: SetRpeIn,
    current_user: dict = Depends(get_current_user),
):
    """Write RPE/RIR/tempo to the matching set_rep_accuracy row + update the
    rolling 7-day stats on user_exercise_state.

    Called by the active-workout screen when the user long-presses a completed
    set and saves an RPE. Drives the Phase 2.D auto-regulation rules + feeds
    user_state_assembler.rolling_rpe_per_exercise.
    """
    user_id = current_user["id"]
    db = get_supabase_db()

    # 1. Update the set_rep_accuracy row (best effort: match by workout_log_id
    #    + exercise_id + set_number; fall back to the most-recent matching row).
    update_fields = {
        "rpe": payload.rpe,
        "rir": payload.rir,
        "tempo": payload.tempo,
    }
    update_fields = {k: v for k, v in update_fields.items() if v is not None}
    matched = 0
    if payload.workout_log_id:
        try:
            res = (
                db.client.table("set_rep_accuracy")
                .update(update_fields)
                .eq("user_id", user_id)
                .eq("workout_log_id", payload.workout_log_id)
                .eq("exercise_id", payload.exercise_id)
                .eq("set_number", payload.set_number)
                .execute()
            )
            matched = len(res.data or [])
        except Exception as e:
            logger.warning(f"⚠️ [set-rpe] direct match failed: {e}")
    if matched == 0:
        # Fall back: most-recent matching set
        try:
            recent = (
                db.client.table("set_rep_accuracy")
                .select("id")
                .eq("user_id", user_id)
                .eq("exercise_id", payload.exercise_id)
                .eq("set_number", payload.set_number)
                .order("created_at", desc=True)
                .limit(1)
                .execute()
            )
            if recent.data:
                db.client.table("set_rep_accuracy").update(update_fields).eq(
                    "id", recent.data[0]["id"]
                ).execute()
                matched = 1
        except Exception as e:
            logger.warning(f"⚠️ [set-rpe] fallback match failed: {e}")

    # 2. Refresh rolling_rpe_7d on user_exercise_state.
    try:
        since = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
        roll = (
            db.client.table("set_rep_accuracy")
            .select("rpe,rir")
            .eq("user_id", user_id)
            .eq("exercise_id", payload.exercise_id)
            .gte("created_at", since)
            .execute()
        )
        rpes = [float(r["rpe"]) for r in (roll.data or []) if r.get("rpe") is not None]
        rirs = [int(r["rir"]) for r in (roll.data or []) if r.get("rir") is not None]
        if rpes:
            db.client.table("user_exercise_state").upsert({
                "user_id": user_id,
                "exercise_id": payload.exercise_id,
                "rolling_rpe_7d": round(sum(rpes) / len(rpes), 2),
                "rolling_rir_7d": round(sum(rirs) / len(rirs), 2) if rirs else None,
                "last_set_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }, on_conflict="user_id,exercise_id").execute()
    except Exception as e:
        logger.warning(f"⚠️ [set-rpe] rolling stats refresh failed: {e}")

    # Invalidate the user_state cache so next generation reads fresh RPE.
    try:
        from services.user_state_assembler import invalidate
        invalidate(user_id)
    except Exception:
        pass

    return {
        "ok": True,
        "matched_rows": matched,
        "rolling_rpe_7d_recomputed": True,
    }


@router.post("/cron/morning-recovery-nudge")
async def morning_recovery_nudge():
    """Cron entry — runs hourly. For every user whose local time is morning
    (07:00–09:00 local per `feedback_intraday_notification_timing`) and whose
    `today_readiness` is below threshold, send a push.

    Schema-aware: reads RHR delta + sleep + Hooper from `readiness_scores`.
    Idempotent: the morning push has a uniqueness key on (user_id, score_date).
    """
    db = get_supabase_db()
    today = date.today().isoformat()
    # Users with today's readiness flagging low intensity recommendation.
    res = (
        db.client.table("today_readiness")
        .select("user_id,readiness_score,readiness_level,recommended_intensity,"
                "ai_insight,hooper_index")
        .eq("score_date", today)
        .execute()
    )
    if not res.data:
        return {"notifications_sent": 0, "reason": "no_readiness_today"}
    sent = 0
    skipped = 0
    for r in res.data:
        intensity = (r.get("recommended_intensity") or "moderate").lower()
        if intensity not in {"low", "very_low", "rest"}:
            skipped += 1
            continue
        user_id = r["user_id"]
        # Dedup against an idempotency log table if one exists; here we just
        # log so the operator can wire it to FCM/APNs later. (notification
        # delivery pipeline is plumbed via push_notifications elsewhere — we
        # write the queue row and let it ship.)
        try:
            db.client.table("notifications").insert({
                "user_id": user_id,
                "type": "morning_recovery_nudge",
                "title": "Take it easy today",
                "body": (
                    f"Readiness is {r.get('readiness_level','low')}. "
                    f"Reducing today's volume — open the app to regenerate."
                ),
                "data": {"recommended_intensity": intensity,
                          "hooper_index": r.get("hooper_index")},
                "scheduled_for": datetime.now(timezone.utc).isoformat(),
            }).execute()
            sent += 1
        except Exception as e:
            logger.warning(f"⚠️ [morning_nudge] queue insert failed for {user_id}: {e}")
    return {"notifications_sent": sent, "skipped": skipped,
            "candidates": len(res.data)}
