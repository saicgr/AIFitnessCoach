"""
Body Analyzer API.

Endpoints:
- POST /analyze                          Body Analyzer run from 1–4 photos
- POST /extract-measurements             Gemini estimates tape measurements from photos
- GET  /snapshots                        List history
- GET  /latest                           Most-recent snapshot
- GET  /body-age                         Standalone body-age compute (no Gemini)
- POST /retune-proposal                  Generate program-retune deltas
- POST /retune-proposal/{id}/preview     Deterministic next-week diff
- POST /retune-proposal/{id}/apply       Commit deltas to public.users
- POST /retune-proposal/{id}/dismiss     Mark dismissed with reason
- POST /apply-posture-correctives        Add posture-corrective exercises to next program
- POST /trigger-deload-check             Force a deload evaluation

All endpoints require auth + ownership. Deltas are cap-enforced before
persistence via strain_prevention.muscle_volume_caps.
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

from services.gemini.body_analyzer import (
    analyze_body_from_photos,
    compute_body_age,
    check_and_trigger_deload,
    extract_measurements_from_photos,
    generate_program_retune,
    preview_retune_effect,
)

logger = logging.getLogger("body_analyzer_api")

router = APIRouter()


# =============================================================================
# Request / response models
# =============================================================================

class AnalyzeRequest(BaseModel):
    photo_ids: List[str] = Field(..., min_length=1, max_length=4)
    include_measurements: bool = True
    user_context: Optional[str] = None


class SnapshotOut(BaseModel):
    id: str
    user_id: str
    overall_rating: Optional[int] = None
    body_type: Optional[str] = None
    body_fat_percent: Optional[float] = None
    muscle_mass_percent: Optional[float] = None
    symmetry_score: Optional[int] = None
    body_age: Optional[int] = None
    feedback_text: Optional[str] = None
    improvement_tips: List[str] = []
    posture_findings: List[Dict[str, Any]] = []
    front_photo_id: Optional[str] = None
    back_photo_id: Optional[str] = None
    side_left_photo_id: Optional[str] = None
    side_right_photo_id: Optional[str] = None
    created_at: Optional[str] = None


class AnalyzeResponse(BaseModel):
    snapshot: SnapshotOut
    seeded_muscle_focus_points: bool = False


class ExtractMeasurementsRequest(BaseModel):
    photo_ids: List[str] = Field(..., min_length=1, max_length=4)


class ExtractMeasurementsResponse(BaseModel):
    estimates: List[Dict[str, Any]]
    scale_reference_detected: bool
    overall_confidence: float


class BodyAgeResponse(BaseModel):
    body_age: int
    chronological_age: int
    delta: int


class RetuneProposalRequest(BaseModel):
    body_analyzer_snapshot_id: str


class RetuneProposalOut(BaseModel):
    id: str
    body_analyzer_snapshot_id: str
    proposal_json: Dict[str, Any]
    reasoning: str
    confidence: Optional[float] = None
    status: str
    expires_at: Optional[str] = None
    created_at: Optional[str] = None


class PreviewResponse(BaseModel):
    before: Dict[str, Any]
    after: Dict[str, Any]
    field_diffs: List[Dict[str, Any]]
    muscle_focus_diffs: List[Dict[str, Any]]
    reasoning: str
    posture_corrective_tags: List[str]
    priority_muscles: List[str]
    rest_days_per_week_suggested: int
    confidence: float


class ApplyResponse(BaseModel):
    proposal_id: str
    status: str
    applied_at: str
    updated_user: Dict[str, Any]


class DismissRequest(BaseModel):
    reason: Optional[str] = None


class ApplyCorrectivesRequest(BaseModel):
    body_analyzer_snapshot_id: str


class ApplyCorrectivesResponse(BaseModel):
    exercises_added: List[Dict[str, Any]]
    issues_addressed: List[str]


class DeloadCheckResponse(BaseModel):
    needs_deload: bool
    reason: str


# =============================================================================
# Helpers
# =============================================================================

def _resolve_photo(sb, user_id: str, photo_id: Optional[str]) -> Optional[Dict[str, Any]]:
    """Fetch a progress_photo owned by user_id. None if missing or not owned."""
    if not photo_id:
        return None
    result = sb.client.table("progress_photos").select(
        "id, user_id, storage_key, photo_url, view_type"
    ).eq("id", photo_id).eq("user_id", user_id).maybe_single().execute()
    return result.data if result and result.data else None


def _compose_measurements(sb, user_id: str) -> Dict[str, Any]:
    """Pull the latest body_measurements row + user profile vitals."""
    user = sb.client.table("users").select(
        "height_cm, weight_kg, age, gender, date_of_birth, resting_heart_rate"
    ).eq("id", user_id).maybe_single().execute()
    user_row = (user.data if user else {}) or {}

    latest_bm = sb.client.table("body_measurements").select(
        "weight_kg, body_fat_percent, waist_cm, chest_cm, hip_cm, neck_cm, "
        "bicep_left_cm, bicep_right_cm, thigh_left_cm, thigh_right_cm, "
        "shoulder_cm, resting_heart_rate"
    ).eq("user_id", user_id).order(
        "measured_at", desc=True
    ).limit(1).execute()
    bm = (latest_bm.data[0] if latest_bm and latest_bm.data else {}) or {}

    merged: Dict[str, Any] = {}
    merged.update({k: v for k, v in bm.items() if v is not None})
    # Profile fields only if not already in BM
    if user_row.get("height_cm") is not None:
        merged.setdefault("height_cm", user_row["height_cm"])
    if user_row.get("weight_kg") is not None:
        merged.setdefault("weight_kg", user_row["weight_kg"])
    if user_row.get("age") is not None:
        merged.setdefault("age", user_row["age"])
    if user_row.get("gender") is not None:
        merged.setdefault("gender", user_row["gender"])
    if user_row.get("resting_heart_rate") is not None:
        merged.setdefault("resting_heart_rate", user_row["resting_heart_rate"])
    return merged


def _seed_muscle_focus(sb, user_id: str, priority_muscles: List[str]) -> bool:
    """Write auto-seeded muscle_focus_points on first Body Analyzer run.

    Only runs when the user has no existing focus allocation — respects
    prior manual choices.
    """
    user = sb.client.table("users").select(
        "muscle_focus_points"
    ).eq("id", user_id).maybe_single().execute()
    if not user or not user.data:
        return False
    existing = user.data.get("muscle_focus_points") or {}
    if existing and any(int(v) > 0 for v in existing.values() if isinstance(v, (int, float))):
        return False  # user already allocated focus — don't overwrite

    # Distribute 5 points across up to 3 priority muscles.
    picks = [m for m in priority_muscles if m][:3]
    if not picks:
        return False
    allocation: Dict[str, int] = {}
    if len(picks) == 1:
        allocation[picks[0]] = 5
    elif len(picks) == 2:
        allocation[picks[0]] = 3
        allocation[picks[1]] = 2
    else:
        allocation[picks[0]] = 2
        allocation[picks[1]] = 2
        allocation[picks[2]] = 1

    sb.client.table("users").update(
        {"muscle_focus_points": allocation}
    ).eq("id", user_id).execute()
    return True


# =============================================================================
# Endpoints
# =============================================================================

@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(
    request: Request,
    data: AnalyzeRequest,
    current_user: dict = Depends(get_current_user),
):
    """Run Gemini Vision body analysis and persist a snapshot."""
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        # Resolve + validate photo ownership
        photos: List[Dict[str, Any]] = []
        for pid in data.photo_ids:
            row = _resolve_photo(sb, user_id, pid)
            if not row:
                raise HTTPException(status_code=404, detail=f"Photo not found: {pid}")
            photos.append(row)

        # Bucket photos by view_type so we can persist the FK for each.
        by_view: Dict[str, Dict[str, Any]] = {}
        for p in photos:
            view = (p.get("view_type") or "front").lower()
            # Only keep the first photo per view to avoid over-writes.
            by_view.setdefault(view, p)

        s3_keys = [p["storage_key"] for p in photos if p.get("storage_key")]
        if not s3_keys:
            raise HTTPException(status_code=400, detail="Photos have no storage keys")

        measurements = _compose_measurements(sb, user_id) if data.include_measurements else {}

        analysis = await analyze_body_from_photos(
            photo_s3_keys=s3_keys,
            measurements=measurements,
            user_context=data.user_context,
            user_id=user_id,
        )

        # Compute body_age deterministically — don't spend Gemini tokens on it.
        chrono_age = int(measurements.get("age") or 30)
        body_age = compute_body_age(
            chronological_age=chrono_age,
            body_fat_percent=analysis.body_fat_pct,
            muscle_mass_percent=analysis.muscle_mass_pct,
            resting_heart_rate=measurements.get("resting_heart_rate"),
            consistency_score_30d=None,  # fetched lazily if we wire it later
            gender=measurements.get("gender"),
        )

        # Persist snapshot
        row_payload = {
            "user_id": user_id,
            "overall_rating": analysis.overall_rating,
            "body_type": analysis.body_type,
            "body_fat_percent": round(analysis.body_fat_pct, 2),
            "muscle_mass_percent": round(analysis.muscle_mass_pct, 2),
            "symmetry_score": analysis.symmetry_score,
            "body_age": body_age,
            "feedback_text": analysis.feedback_paragraph,
            "improvement_tips": analysis.improvement_tips,
            "posture_findings": [f.model_dump() for f in analysis.posture_findings],
            "front_photo_id": (by_view.get("front") or {}).get("id"),
            "back_photo_id": (by_view.get("back") or {}).get("id"),
            "side_left_photo_id": (by_view.get("side_left") or {}).get("id"),
            "side_right_photo_id": (by_view.get("side_right") or {}).get("id"),
            "ai_model": "gemini-vision",
            "input_measurements": measurements,
        }
        insert = sb.client.table("body_analyzer_snapshots").insert(row_payload).execute()
        if not insert.data:
            raise safe_internal_error(RuntimeError("snapshot insert failed"), "body_analyzer")
        snapshot_row = insert.data[0]

        # Upsert users.body_type so the enum travels with the profile.
        sb.client.table("users").update(
            {"body_type": analysis.body_type}
        ).eq("id", user_id).execute()

        # Auto-seed muscle_focus_points on first run
        seeded = _seed_muscle_focus(sb, user_id, analysis.priority_muscles)

        return AnalyzeResponse(
            snapshot=SnapshotOut(**snapshot_row),
            seeded_muscle_focus_points=seeded,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_analyze")


@router.post("/extract-measurements", response_model=ExtractMeasurementsResponse)
async def extract_measurements(
    request: Request,
    data: ExtractMeasurementsRequest,
    current_user: dict = Depends(get_current_user),
):
    """Estimate tape-measure values from the supplied photos and persist a
    new body_measurements row with measurement_source='photo_estimate' +
    estimate_confidence."""
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        photos: List[Dict[str, Any]] = []
        for pid in data.photo_ids:
            row = _resolve_photo(sb, user_id, pid)
            if not row:
                raise HTTPException(status_code=404, detail=f"Photo not found: {pid}")
            photos.append(row)

        user = sb.client.table("users").select(
            "height_cm"
        ).eq("id", user_id).maybe_single().execute()
        height_cm = (user.data or {}).get("height_cm") if user else None

        s3_keys = [p["storage_key"] for p in photos if p.get("storage_key")]
        result = await extract_measurements_from_photos(
            photo_s3_keys=s3_keys,
            height_cm=height_cm,
            user_id=user_id,
        )

        # Persist estimates as a new body_measurements row.
        bm_row: Dict[str, Any] = {
            "user_id": user_id,
            "measured_at": datetime.now(timezone.utc).isoformat(),
            "measurement_source": "photo_estimate",
            "estimate_confidence": round(result.overall_confidence, 2),
        }
        for est in result.estimates:
            bm_row[est.metric] = round(est.value_cm, 1)

        if any(k for k in bm_row if k.endswith("_cm")):
            sb.client.table("body_measurements").insert(bm_row).execute()

        return ExtractMeasurementsResponse(
            estimates=[e.model_dump() for e in result.estimates],
            scale_reference_detected=result.scale_reference_detected,
            overall_confidence=result.overall_confidence,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_extract_measurements")


@router.get("/snapshots", response_model=List[SnapshotOut])
async def list_snapshots(
    current_user: dict = Depends(get_current_user),
    limit: int = 30,
):
    try:
        sb = get_supabase_db()
        result = sb.client.table("body_analyzer_snapshots").select("*").eq(
            "user_id", current_user["id"]
        ).order("created_at", desc=True).limit(max(1, min(limit, 100))).execute()
        return [SnapshotOut(**row) for row in (result.data or [])]
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_list_snapshots")


@router.get("/latest", response_model=Optional[SnapshotOut])
async def latest_snapshot(current_user: dict = Depends(get_current_user)):
    try:
        sb = get_supabase_db()
        result = sb.client.table("body_analyzer_snapshots").select("*").eq(
            "user_id", current_user["id"]
        ).order("created_at", desc=True).limit(1).execute()
        if not result.data:
            return None
        return SnapshotOut(**result.data[0])
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_latest")


@router.get("/body-age", response_model=BodyAgeResponse)
async def body_age(current_user: dict = Depends(get_current_user)):
    """Recompute body age on demand — useful for home-screen badge."""
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]
        measurements = _compose_measurements(sb, user_id)
        latest = sb.client.table("body_analyzer_snapshots").select(
            "body_fat_percent, muscle_mass_percent"
        ).eq("user_id", user_id).order("created_at", desc=True).limit(1).execute()
        latest_row = (latest.data or [{}])[0]

        chrono = int(measurements.get("age") or 30)
        body_age_val = compute_body_age(
            chronological_age=chrono,
            body_fat_percent=latest_row.get("body_fat_percent") or measurements.get("body_fat_percent"),
            muscle_mass_percent=latest_row.get("muscle_mass_percent"),
            resting_heart_rate=measurements.get("resting_heart_rate"),
            consistency_score_30d=None,
            gender=measurements.get("gender"),
        )
        return BodyAgeResponse(
            body_age=body_age_val,
            chronological_age=chrono,
            delta=body_age_val - chrono,
        )
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_body_age")


@router.post("/retune-proposal", response_model=RetuneProposalOut)
async def create_retune_proposal(
    request: Request,
    data: RetuneProposalRequest,
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        # Load snapshot (must be owned)
        snap = sb.client.table("body_analyzer_snapshots").select("*").eq(
            "id", data.body_analyzer_snapshot_id
        ).eq("user_id", user_id).maybe_single().execute()
        if not snap or not snap.data:
            raise HTTPException(status_code=404, detail="Snapshot not found")
        snapshot = snap.data

        # Current profile columns the generator reads
        user_row = sb.client.table("users").select(
            "muscle_focus_points, training_intensity_percent, primary_goal, "
            "daily_calorie_target, daily_protein_target_g, daily_carbs_target_g, "
            "daily_fat_target_g"
        ).eq("id", user_id).maybe_single().execute()
        user_profile = (user_row.data if user_row else {}) or {}

        # Muscle volume caps — best-effort; empty dict if table missing
        muscle_caps: Dict[str, int] = {}
        try:
            caps = sb.client.table("muscle_volume_caps").select(
                "muscle_group, max_weekly_sets"
            ).eq("user_id", user_id).execute()
            for row in caps.data or []:
                mg = row.get("muscle_group")
                cap = row.get("max_weekly_sets")
                if mg and cap is not None:
                    muscle_caps[mg] = int(cap)
        except Exception as cap_err:
            logger.info(f"[body_analyzer] muscle_volume_caps unavailable: {cap_err}")

        # Recent strength scores (last 4 weeks)
        since = (datetime.now(timezone.utc) - timedelta(days=28)).isoformat()
        ss = sb.client.table("strength_scores").select(
            "muscle_group, strength_score, weekly_sets, weekly_volume_kg, trend"
        ).eq("user_id", user_id).gte("calculated_at", since).execute()
        recent_scores = ss.data or []

        proposal = await generate_program_retune(
            snapshot=snapshot,
            current_user_profile=user_profile,
            muscle_caps=muscle_caps,
            recent_strength_scores=recent_scores,
            user_id=user_id,
        )

        insert_payload = {
            "user_id": user_id,
            "body_analyzer_snapshot_id": data.body_analyzer_snapshot_id,
            "proposal_json": proposal.model_dump(),
            "reasoning": proposal.reasoning,
            "confidence": float(proposal.confidence),
            "status": "pending",
        }
        ins = sb.client.table("program_retune_proposals").insert(insert_payload).execute()
        if not ins.data:
            raise safe_internal_error(RuntimeError("proposal insert failed"), "body_analyzer")
        return RetuneProposalOut(**ins.data[0])
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_create_retune")


@router.post("/retune-proposal/{proposal_id}/preview", response_model=PreviewResponse)
async def preview_retune(
    proposal_id: str,
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]
        prop = sb.client.table("program_retune_proposals").select("*").eq(
            "id", proposal_id
        ).eq("user_id", user_id).maybe_single().execute()
        if not prop or not prop.data:
            raise HTTPException(status_code=404, detail="Proposal not found")

        user_row = sb.client.table("users").select(
            "muscle_focus_points, training_intensity_percent, daily_calorie_target, "
            "daily_protein_target_g, daily_carbs_target_g, daily_fat_target_g"
        ).eq("id", user_id).maybe_single().execute()
        user_profile = (user_row.data if user_row else {}) or {}

        # Rehydrate the stored proposal into the Pydantic schema so preview_retune_effect gets
        # a typed object.
        from models.gemini_schemas import ProgramRetuneProposalResponse
        proposal_obj = ProgramRetuneProposalResponse(**prop.data["proposal_json"])
        diff = preview_retune_effect(
            current_user_profile=user_profile,
            proposal=proposal_obj,
        )
        return PreviewResponse(**diff)
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_preview_retune")


@router.post("/retune-proposal/{proposal_id}/apply", response_model=ApplyResponse)
async def apply_retune(
    proposal_id: str,
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        prop = sb.client.table("program_retune_proposals").select("*").eq(
            "id", proposal_id
        ).eq("user_id", user_id).maybe_single().execute()
        if not prop or not prop.data:
            raise HTTPException(status_code=404, detail="Proposal not found")
        if prop.data["status"] not in ("pending", "auto_applied"):
            raise HTTPException(status_code=409, detail=f"Proposal already {prop.data['status']}")

        proposal_json = prop.data["proposal_json"] or {}

        user_row = sb.client.table("users").select(
            "muscle_focus_points, training_intensity_percent, daily_calorie_target, "
            "daily_protein_target_g, daily_carbs_target_g, daily_fat_target_g"
        ).eq("id", user_id).maybe_single().execute()
        user_profile = (user_row.data if user_row else {}) or {}

        # Build updated values (re-applying bounds as a final safety net).
        def _bounded(base: Optional[int], delta: int, lo: int, hi: int) -> int:
            return max(lo, min(hi, int(base or 0) + int(delta or 0)))

        update: Dict[str, Any] = {}
        mfp = proposal_json.get("muscle_focus_points_proposed") or {}
        if mfp:
            update["muscle_focus_points"] = mfp
        if "training_intensity_percent_delta" in proposal_json:
            update["training_intensity_percent"] = _bounded(
                user_profile.get("training_intensity_percent"),
                proposal_json["training_intensity_percent_delta"],
                30, 150,
            )
        if "daily_calorie_target_delta" in proposal_json:
            update["daily_calorie_target"] = _bounded(
                user_profile.get("daily_calorie_target"),
                proposal_json["daily_calorie_target_delta"],
                800, 6000,
            )
        if "daily_protein_target_g_delta" in proposal_json:
            update["daily_protein_target_g"] = _bounded(
                user_profile.get("daily_protein_target_g"),
                proposal_json["daily_protein_target_g_delta"],
                30, 400,
            )
        if "daily_carbs_target_g_delta" in proposal_json:
            update["daily_carbs_target_g"] = _bounded(
                user_profile.get("daily_carbs_target_g"),
                proposal_json["daily_carbs_target_g_delta"],
                30, 800,
            )
        if "daily_fat_target_g_delta" in proposal_json:
            update["daily_fat_target_g"] = _bounded(
                user_profile.get("daily_fat_target_g"),
                proposal_json["daily_fat_target_g_delta"],
                10, 300,
            )

        applied_at = datetime.now(timezone.utc).isoformat()
        if update:
            sb.client.table("users").update(update).eq("id", user_id).execute()

        sb.client.table("program_retune_proposals").update({
            "status": "applied",
            "applied_at": applied_at,
        }).eq("id", proposal_id).execute()

        return ApplyResponse(
            proposal_id=proposal_id,
            status="applied",
            applied_at=applied_at,
            updated_user=update,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_apply_retune")


@router.post("/retune-proposal/{proposal_id}/dismiss")
async def dismiss_retune(
    proposal_id: str,
    data: DismissRequest,
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]
        prop = sb.client.table("program_retune_proposals").select("id, status").eq(
            "id", proposal_id
        ).eq("user_id", user_id).maybe_single().execute()
        if not prop or not prop.data:
            raise HTTPException(status_code=404, detail="Proposal not found")
        sb.client.table("program_retune_proposals").update({
            "status": "dismissed",
            "dismiss_reason": (data.reason or "")[:500],
        }).eq("id", proposal_id).execute()
        return {"status": "dismissed"}
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_dismiss_retune")


@router.post("/apply-posture-correctives", response_model=ApplyCorrectivesResponse)
async def apply_posture_correctives(
    request: Request,
    data: ApplyCorrectivesRequest,
    current_user: dict = Depends(get_current_user),
):
    """Seed the user's 'muscle_focus_points' and append corrective exercise
    tags to their program preferences. Actual injection into the next
    generated workout happens naturally because the generator reads
    `users.muscle_focus_points` + `users.preferences`."""
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]
        snap = sb.client.table("body_analyzer_snapshots").select(
            "id, posture_findings"
        ).eq("id", data.body_analyzer_snapshot_id).eq(
            "user_id", user_id
        ).maybe_single().execute()
        if not snap or not snap.data:
            raise HTTPException(status_code=404, detail="Snapshot not found")
        findings = snap.data.get("posture_findings") or []
        tags = list({f.get("corrective_exercise_tag") for f in findings if f.get("corrective_exercise_tag")})
        if not tags:
            return ApplyCorrectivesResponse(exercises_added=[], issues_addressed=[])

        # Pull corrective exercises matching any tag
        exercises = sb.client.table("exercise_library").select(
            "id, exercise_name, target_muscle, corrective_for"
        ).overlaps("corrective_for", tags).limit(25).execute()
        exercise_rows = exercises.data or []

        # Stash ids on users.preferences.posture_correctives so the generator
        # can pick them up. Preserves any prior preferences.
        user = sb.client.table("users").select("preferences").eq(
            "id", user_id
        ).maybe_single().execute()
        prefs = (user.data.get("preferences") if user and user.data else {}) or {}
        prefs["posture_correctives"] = {
            "tags": tags,
            "exercise_ids": [e["id"] for e in exercise_rows],
            "seeded_at": datetime.now(timezone.utc).isoformat(),
        }
        sb.client.table("users").update({"preferences": prefs}).eq("id", user_id).execute()

        return ApplyCorrectivesResponse(
            exercises_added=exercise_rows,
            issues_addressed=tags,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_apply_correctives")


@router.post("/trigger-deload-check", response_model=DeloadCheckResponse)
async def trigger_deload_check(current_user: dict = Depends(get_current_user)):
    """On-demand deload evaluation. Background job also calls this."""
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        # latest + 30d-ago snapshots
        latest = sb.client.table("body_analyzer_snapshots").select(
            "overall_rating"
        ).eq("user_id", user_id).order("created_at", desc=True).limit(1).execute()
        thirty_days_ago = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
        old = sb.client.table("body_analyzer_snapshots").select(
            "overall_rating"
        ).eq("user_id", user_id).lte("created_at", thirty_days_ago).order(
            "created_at", desc=True
        ).limit(1).execute()

        # 7-day average readiness
        since_7d = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
        readiness = sb.client.table("readiness_scores").select(
            "readiness_score"
        ).eq("user_id", user_id).gte("created_at", since_7d).execute()
        scores = [r.get("readiness_score") for r in (readiness.data or []) if r.get("readiness_score") is not None]
        avg_ready = sum(scores) / len(scores) if scores else None

        # Open strain alerts
        alerts_count = 0
        try:
            alerts = sb.client.table("volume_increase_alerts").select(
                "id", count="exact"
            ).eq("user_id", user_id).eq("acknowledged", False).execute()
            alerts_count = alerts.count or 0
        except Exception:
            pass

        needs, reason = check_and_trigger_deload(
            latest_snapshot=(latest.data or [{}])[0] if latest.data else None,
            snapshot_30d_ago=(old.data or [{}])[0] if old.data else None,
            avg_readiness_7d=avg_ready,
            open_strain_alerts=alerts_count,
        )
        return DeloadCheckResponse(needs_deload=needs, reason=reason)
    except Exception as e:
        raise safe_internal_error(e, "body_analyzer_deload_check")
