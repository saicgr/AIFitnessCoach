"""
Workout History — FILE IMPORT endpoints.

Exposes the user-facing layer on top of `WorkoutHistoryImporter` (strength
history + cardio + creator program templates parsed from 30+ upload formats).

Endpoints:
  • POST  /workout-history/import/file     — multipart upload, async (job)
  • POST  /workout-history/import/preview  — multipart upload, sync dry-run
  • POST  /workout-history/remap           — batch raw→canonical rename + audit
  • POST  /workout-history/remap/{id}/undo — revert a remap batch
  • GET   /workout-history/unresolved/{user_id} — groups of unmatched names
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID

from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
)
from pydantic import BaseModel, Field

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/workout-history", tags=["Workout History Import"])


# =============================================================================
# Constants
# =============================================================================

# Reject files > 25 MB outright — every adapter loads bytes into memory and the
# biggest legitimate export we've seen is a 6 MB five-year Garmin dump.
MAX_UPLOAD_SIZE_BYTES = 25 * 1024 * 1024

# Preview runs synchronously — adapter parsing for a 5 MB file is typically
# <5 s but AI fallback on a PDF can push to 20 s. Give it a hard ceiling so a
# runaway parse can't hold the request worker forever.
PREVIEW_TIMEOUT_SECONDS = 30

ALLOWED_CONTENT_PATTERNS = (
    "text/csv",
    "application/csv",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.ms-excel.sheet.macroEnabled.12",
    "application/json",
    "application/octet-stream",  # generic — trust extension
    "application/zip",
    "application/pdf",
    "application/x-parquet",
    "application/xml",
    "text/xml",
    "text/plain",
)


# =============================================================================
# Pydantic models
# =============================================================================

class RemapRequest(BaseModel):
    """Batch rename every `raw_name` row for a user to a canonical exercise."""
    user_id: str
    raw_name: str = Field(..., min_length=1, max_length=500)
    exercise_id: Optional[str] = None
    canonical_name: str = Field(..., min_length=1, max_length=500)
    source_app: Optional[str] = None


class RemapResponse(BaseModel):
    rows_affected: int
    audit_id: str


class UndoResponse(BaseModel):
    rows_reverted: int
    audit_id: str


class UnresolvedSuggestion(BaseModel):
    canonical_name: str
    exercise_id: Optional[str]
    confidence: float
    source: str  # alias | library | rag


class UnresolvedGroup(BaseModel):
    raw_name: str
    row_count: int
    session_count: int
    first_seen: Optional[datetime]
    last_seen: Optional[datetime]
    source_apps: List[str]
    suggestions: List[UnresolvedSuggestion]


# =============================================================================
# POST /import/preview — synchronous dry-run
# =============================================================================

@router.post("/import/preview")
async def preview_import(
    file: UploadFile = File(...),
    unit_hint: str = Form("lb"),
    timezone_hint: str = Form("UTC"),
    source_app_hint: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """Parse an uploaded file synchronously WITHOUT writing to the DB.

    Returns the adapter's dry-run summary (source_app, row counts, sample rows,
    unresolved exercises, warnings) so the user can eyeball the detection
    before committing to the full import.
    """
    user_id = str(current_user["id"])
    logger.info(
        f"🔍 [WorkoutHistoryFile] Preview requested by user={user_id} "
        f"filename={file.filename} unit={unit_hint} tz={timezone_hint} hint={source_app_hint}"
    )

    data, content_type = await _read_and_validate(file)

    # Upload to S3 — adapters read from S3 to mirror the production flow exactly
    # (and because the AI fallback currently re-uploads PDFs to Gemini from S3).
    s3_key = _upload_to_s3(
        data,
        user_id=user_id,
        filename=file.filename or "upload.bin",
        content_type=content_type,
    )

    # Build a synthetic media_analysis_jobs-shaped dict — we DON'T persist this
    # job because dry-run shouldn't pollute the user's job history.
    synthetic_job: Dict[str, Any] = {
        "id": "preview-" + user_id,  # placeholder; never written to DB
        "user_id": user_id,
        "s3_keys": [s3_key],
        "params": {
            "user_id": user_id,
            "unit_hint": unit_hint,
            "timezone_hint": timezone_hint,
            "source_app_hint": source_app_hint,
            "filename": file.filename,
            "dry_run": True,
        },
    }

    try:
        from services.workout_import.service import WorkoutHistoryImporter

        importer = WorkoutHistoryImporter()
        summary = await asyncio.wait_for(
            importer.run(synthetic_job),
            timeout=PREVIEW_TIMEOUT_SECONDS,
        )
        logger.info(
            f"✅ [WorkoutHistoryFile] Preview complete: app={summary.get('source_app')} "
            f"strength={summary.get('strength_row_count')} cardio={summary.get('cardio_row_count')}"
        )
        # Surface the uploaded s3_key so the caller (and summary sheet in dev
        # tools) can see where the preview blob lives. The full `/import/file`
        # path re-uploads from fresh bytes so we don't share keys between the
        # two endpoints — leaves room for a future "confirm preview" that
        # reuses the same key.
        summary["_preview_s3_key"] = s3_key
        return summary
    except asyncio.TimeoutError:
        logger.warning(f"⏱ [WorkoutHistoryFile] Preview exceeded {PREVIEW_TIMEOUT_SECONDS}s")
        raise HTTPException(
            status_code=504,
            detail=(
                "Preview timed out. Your file may be very large or the AI fallback parser "
                "is still processing. Try the regular import (async) instead."
            ),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ [WorkoutHistoryFile] Preview failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_history_file")


# =============================================================================
# POST /import/file — async full import via media job
# =============================================================================

@router.post("/import/file")
async def import_file(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    unit_hint: str = Form("lb"),
    timezone_hint: str = Form("UTC"),
    source_app_hint: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """Upload a workout history export and enqueue a background job.

    Returns `{job_id, status}` — Flutter polls `GET /api/v1/media-jobs/{job_id}`
    for progress.
    """
    user_id = str(current_user["id"])
    logger.info(
        f"📥 [WorkoutHistoryFile] Import requested by user={user_id} "
        f"filename={file.filename} unit={unit_hint} hint={source_app_hint}"
    )

    data, content_type = await _read_and_validate(file)

    # #96 — duplicate-file pre-check. If this exact file has already been
    # imported for this user, short-circuit with the cached summary rather
    # than re-running the pipeline (which would dedup at the row level but
    # waste S3 upload + Gemini calls).
    file_sha = _file_sha256(data)
    existing_job = _find_prior_import_job(user_id=user_id, file_sha256=file_sha)
    if existing_job is not None:
        logger.info(
            f"↩️ [WorkoutHistoryFile] File sha256={file_sha[:12]}… already "
            f"imported (job={existing_job['id']}); returning cached summary"
        )
        return {
            "job_id": existing_job["id"],
            "status": existing_job.get("status", "completed"),
            "duplicate_of": existing_job["id"],
            "cached_summary": existing_job.get("result") or existing_job.get("result_json"),
        }

    s3_key = _upload_to_s3(
        data,
        user_id=user_id,
        filename=file.filename or "upload.bin",
        content_type=content_type,
    )

    try:
        from services.media_job_runner import run_media_job
        from services.media_job_service import get_media_job_service

        job_service = get_media_job_service()
        job_id = job_service.create_job(
            user_id=user_id,
            job_type="workout_history_import",
            s3_keys=[s3_key],
            mime_types=[content_type],
            media_types=["document"],
            params={
                "user_id": user_id,
                "unit_hint": unit_hint,
                "timezone_hint": timezone_hint,
                "source_app_hint": source_app_hint,
                "filename": file.filename,
                "file_sha256": file_sha,
                "dry_run": False,
            },
        )

        # Use BackgroundTasks so FastAPI returns the response promptly; the
        # runner also works via asyncio.create_task for symmetry with other
        # endpoints, but BackgroundTasks is the contract documented in the plan.
        background_tasks.add_task(run_media_job, job_id)

        logger.info(f"✅ [WorkoutHistoryFile] Dispatched workout_history_import job {job_id}")
        return {"job_id": job_id, "status": "pending"}
    except Exception as e:
        logger.error(f"❌ [WorkoutHistoryFile] Failed to create import job: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_history_file")


# =============================================================================
# POST /remap — batch rename + audit + RAG metadata update
# =============================================================================

@router.post("/remap", response_model=RemapResponse)
async def remap_exercise_name(
    request: RemapRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Rewrite every `workout_history_imports` row where `LOWER(exercise_name) =
    LOWER(raw_name)` for this user, setting the canonical name + (optionally)
    the resolved exercise_id.

    Side-effects:
      1. Writes an `history_import_remap_audit` row — includes the UUID list of
         affected rows so the batch can be reverted by /remap/{id}/undo.
      2. Writes an `exercise_alias_contributions` row so curated pairs feed the
         global alias dictionary.
      3. Updates ChromaDB session metadata in a background task (non-blocking).
    """
    verify_user_ownership(current_user, request.user_id)
    logger.info(
        f"🔀 [WorkoutHistoryFile] Remap: user={request.user_id} "
        f"'{request.raw_name}' → '{request.canonical_name}'"
    )

    db = get_supabase_db()

    # 1. Pre-fetch row ids so we can record them in the audit table. Only grab
    #    ids — we rewrite the columns with a single UPDATE afterwards.
    raw_lower = request.raw_name.strip().lower()
    try:
        existing = (
            db.client.table("workout_history_imports")
            .select("id, exercise_name_canonical, exercise_id")
            .eq("user_id", request.user_id)
            .ilike("exercise_name", raw_lower)
            .execute()
        )
    except Exception as e:
        logger.error(f"❌ [WorkoutHistoryFile] Remap lookup failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_history_file")

    rows = existing.data or []
    if not rows:
        # Nothing to remap — still return 200 with rows_affected=0 and skip audit.
        return RemapResponse(rows_affected=0, audit_id="")

    affected_ids = [r["id"] for r in rows]
    old_canonical = rows[0].get("exercise_name_canonical")
    old_exercise_id = rows[0].get("exercise_id")

    # 2. Batch UPDATE — Supabase-py accepts update + filter chain.
    update_payload: Dict[str, Any] = {
        "exercise_name_canonical": request.canonical_name,
    }
    if request.exercise_id:
        update_payload["exercise_id"] = request.exercise_id
    try:
        db.client.table("workout_history_imports") \
            .update(update_payload) \
            .eq("user_id", request.user_id) \
            .ilike("exercise_name", raw_lower) \
            .execute()
    except Exception as e:
        logger.error(f"❌ [WorkoutHistoryFile] Remap UPDATE failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_history_file")

    # 3. Audit row — required for undo.
    audit_payload = {
        "user_id": request.user_id,
        "raw_name": request.raw_name,
        "canonical_name_before": old_canonical,
        "canonical_name_after": request.canonical_name,
        "exercise_id_before": old_exercise_id,
        "exercise_id_after": request.exercise_id,
        "rows_affected": len(affected_ids),
        "affected_row_ids": affected_ids,
    }
    try:
        audit_res = (
            db.client.table("history_import_remap_audit")
            .insert(audit_payload)
            .execute()
        )
        audit_id = audit_res.data[0]["id"] if audit_res.data else ""
    except Exception as e:
        # Audit insert is non-fatal for the rename itself, but critical for
        # undo — warn loudly so on-call sees it.
        logger.error(
            f"⚠️ [WorkoutHistoryFile] Audit insert failed (remap still applied): {e}",
            exc_info=True,
        )
        audit_id = ""

    # 4. Alias contribution — feeds the global dictionary after offline review.
    try:
        db.client.table("exercise_alias_contributions").insert({
            "raw_name_lower": raw_lower,
            "canonical_name": request.canonical_name,
            "exercise_id": request.exercise_id,
            "submitter_user_id": request.user_id,
            "source_app": request.source_app,
            "confidence": 1.0,
            "review_status": "pending",
        }).execute()
    except Exception as e:
        # Non-fatal. The alias pipeline will reconcile when the admin reviews.
        logger.warning(f"⚠️ [WorkoutHistoryFile] Alias contribution insert failed: {e}")

    # 5. Background: update RAG / ChromaDB session metadata so future weight
    #    suggestions pull from the correct canonical bucket. Best-effort.
    if old_canonical and old_canonical != request.canonical_name:
        background_tasks.add_task(
            _update_rag_after_remap,
            user_id=request.user_id,
            old_canonical=old_canonical,
            new_canonical=request.canonical_name,
            new_exercise_id=request.exercise_id,
        )

    logger.info(
        f"✅ [WorkoutHistoryFile] Remap complete: {len(affected_ids)} rows updated, "
        f"audit_id={audit_id}"
    )
    return RemapResponse(rows_affected=len(affected_ids), audit_id=audit_id)


@router.post("/remap/{audit_id}/undo", response_model=UndoResponse)
async def undo_remap(
    audit_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Reverse a prior /remap batch using the audit row's affected_row_ids."""
    user_id = str(current_user["id"])
    logger.info(f"↩️ [WorkoutHistoryFile] Undo remap audit={audit_id} user={user_id}")

    db = get_supabase_db()

    # Load the audit row + verify ownership.
    try:
        audit_res = (
            db.client.table("history_import_remap_audit")
            .select("*")
            .eq("id", audit_id)
            .limit(1)
            .execute()
        )
    except Exception as e:
        raise safe_internal_error(e, "workout_history_file")

    if not audit_res.data:
        raise HTTPException(status_code=404, detail="Audit row not found")
    audit = audit_res.data[0]

    if str(audit["user_id"]) != user_id:
        # Don't leak existence — 404 rather than 403.
        raise HTTPException(status_code=404, detail="Audit row not found")

    if audit.get("reverted"):
        raise HTTPException(status_code=409, detail="Audit already reverted")

    affected_ids = audit.get("affected_row_ids") or []
    if not affected_ids:
        # Nothing to revert — mark reverted anyway so the button stops showing.
        db.client.table("history_import_remap_audit").update({
            "reverted": True,
            "reverted_at": datetime.utcnow().isoformat(),
        }).eq("id", audit_id).execute()
        return UndoResponse(rows_reverted=0, audit_id=audit_id)

    # Restore the previous canonical + exercise_id values on the affected rows.
    try:
        db.client.table("workout_history_imports").update({
            "exercise_name_canonical": audit.get("canonical_name_before"),
            "exercise_id": audit.get("exercise_id_before"),
        }).in_("id", affected_ids).eq("user_id", user_id).execute()
    except Exception as e:
        logger.error(f"❌ [WorkoutHistoryFile] Undo UPDATE failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_history_file")

    # Flag the audit row as reverted.
    try:
        db.client.table("history_import_remap_audit").update({
            "reverted": True,
            "reverted_at": datetime.utcnow().isoformat(),
        }).eq("id", audit_id).execute()
    except Exception as e:
        logger.warning(f"⚠️ [WorkoutHistoryFile] Audit flag-reverted failed: {e}")

    logger.info(f"✅ [WorkoutHistoryFile] Reverted {len(affected_ids)} rows (audit {audit_id})")
    return UndoResponse(rows_reverted=len(affected_ids), audit_id=audit_id)


# =============================================================================
# GET /unresolved/{user_id} — grouped unmatched raw names with suggestions
# =============================================================================

@router.get("/unresolved/{user_id}", response_model=List[UnresolvedGroup])
async def get_unresolved(
    user_id: str,
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
):
    """Return distinct raw exercise names where the resolver gave up (exercise_id
    IS NULL). Each group includes session/row counts and up to 3 suggested
    canonical matches, so the Flutter "Fix these" sheet can pre-populate chips.
    """
    verify_user_ownership(current_user, user_id)
    logger.info(f"🔎 [WorkoutHistoryFile] Unresolved request user={user_id} limit={limit}")

    db = get_supabase_db()

    try:
        # Pull the unresolved rows; we aggregate in Python to avoid requiring
        # a Supabase RPC for a query the app calls infrequently.
        rows_res = (
            db.client.table("workout_history_imports")
            .select("id, exercise_name, performed_at, source_app")
            .eq("user_id", user_id)
            .is_("exercise_id", "null")
            .order("performed_at", desc=True)
            .limit(10_000)   # bounded for safety
            .execute()
        )
    except Exception as e:
        logger.error(f"❌ [WorkoutHistoryFile] Unresolved fetch failed: {e}", exc_info=True)
        raise safe_internal_error(e, "workout_history_file")

    rows = rows_res.data or []
    groups: Dict[str, Dict[str, Any]] = {}
    for row in rows:
        raw = (row.get("exercise_name") or "").strip()
        if not raw:
            continue
        key = raw.lower()
        g = groups.setdefault(key, {
            "raw_name": raw,
            "row_count": 0,
            "session_dates": set(),
            "source_apps": set(),
            "first_seen": None,
            "last_seen": None,
        })
        g["row_count"] += 1
        if row.get("source_app"):
            g["source_apps"].add(row["source_app"])
        performed = row.get("performed_at")
        if performed:
            try:
                ts = datetime.fromisoformat(performed.replace("Z", "+00:00"))
                g["session_dates"].add(ts.date().isoformat())
                if g["first_seen"] is None or ts < g["first_seen"]:
                    g["first_seen"] = ts
                if g["last_seen"] is None or ts > g["last_seen"]:
                    g["last_seen"] = ts
            except Exception:
                pass

    # 2. Resolve top-3 suggestions per group using the exercise resolver.
    suggestions_by_key = _suggest_for_unresolved(list(groups.keys()))

    # 3. Shape response — cap at `limit` groups sorted by row_count DESC.
    ordered = sorted(groups.values(), key=lambda x: x["row_count"], reverse=True)[:limit]
    result: List[UnresolvedGroup] = []
    for g in ordered:
        key = g["raw_name"].lower()
        result.append(UnresolvedGroup(
            raw_name=g["raw_name"],
            row_count=g["row_count"],
            session_count=len(g["session_dates"]),
            first_seen=g["first_seen"],
            last_seen=g["last_seen"],
            source_apps=sorted(g["source_apps"]),
            suggestions=suggestions_by_key.get(key, []),
        ))
    return result


# =============================================================================
# Internal helpers
# =============================================================================

async def _read_and_validate(file: UploadFile) -> tuple[bytes, str]:
    """Read the upload body, enforce the size cap, and return (bytes, content_type)."""
    if not file or not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")

    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")

    if len(data) > MAX_UPLOAD_SIZE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=(
                f"File is too large (max {MAX_UPLOAD_SIZE_BYTES // (1024 * 1024)} MB). "
                "Split the export into smaller files and import them separately."
            ),
        )

    content_type = (file.content_type or "application/octet-stream").lower()
    # We don't hard-fail on unknown content types — users often upload with
    # the wrong MIME. The format detector runs on bytes + filename regardless.
    return data, content_type


def _file_sha256(data: bytes) -> str:
    """Hex digest of the uploaded bytes. Used for the duplicate-file pre-check
    in POST /import/file — same bytes for the same user → return the cached
    summary instead of re-running the pipeline."""
    import hashlib as _hashlib
    return _hashlib.sha256(data).hexdigest()


def _find_prior_import_job(*, user_id: str, file_sha256: str) -> Optional[dict]:
    """Look up a previously-completed media_analysis_jobs row where
    params.file_sha256 matches. Returns the job dict (including cached result)
    or None if no prior import exists.

    Best-effort: any DB failure returns None so the caller falls through to
    the normal upload path (worst case: a redundant re-import, which dedupes
    at the row level via source_row_hash anyway)."""
    try:
        db = get_supabase_db()
        # JSONB path: params->>'file_sha256' = $1  AND  user_id = $2.
        # Supabase Python client doesn't expose the ->> operator directly;
        # we query by user_id + job_type and filter in Python — the hot-path
        # user will have <100 prior jobs so this is fine.
        result = (
            db.client.table("media_analysis_jobs")
            .select("id, status, result, result_json, params, created_at")
            .eq("user_id", user_id)
            .eq("job_type", "workout_history_import")
            .eq("status", "completed")
            .order("created_at", desc=True)
            .limit(100)
            .execute()
        )
        for row in result.data or []:
            params = row.get("params") or {}
            if isinstance(params, str):
                try:
                    import json as _json
                    params = _json.loads(params)
                except Exception:
                    continue
            if params.get("file_sha256") == file_sha256:
                return row
    except Exception as e:
        logger.debug(f"[WorkoutHistoryFile] prior-job lookup skipped: {e}")
    return None


def _upload_to_s3(
    data: bytes,
    *,
    user_id: str,
    filename: str,
    content_type: str,
) -> str:
    """Upload to S3 under `workout-history-imports/{user_id}/…` and return the key."""
    from services.s3_service import get_s3_service

    svc = get_s3_service()
    if not svc.is_configured():
        # Explicit error — don't silently fall back to processing in memory
        # since our adapter pipeline reads from S3 for AI fallback.
        raise HTTPException(
            status_code=503,
            detail="Storage is not configured. Please contact support.",
        )

    try:
        return svc.upload_bytes(
            data,
            key_prefix=f"workout-history-imports/{user_id}",
            filename=filename or "upload.bin",
            content_type=content_type,
        )
    except Exception as e:
        logger.error(f"❌ [WorkoutHistoryFile] S3 upload failed: {e}", exc_info=True)
        raise HTTPException(status_code=502, detail="Failed to store uploaded file.")


def _suggest_for_unresolved(raw_names_lower: List[str]) -> Dict[str, List[UnresolvedSuggestion]]:
    """For each unresolved raw name, compute up to 3 suggested canonical names.

    Uses `ExerciseResolver.resolve()` which cascades alias → library → RAG —
    the same logic the importer runs. We hit it again here so the UI shows
    the best current guess (user may have added aliases since the import ran).
    """
    if not raw_names_lower:
        return {}
    try:
        from services.workout_import.exercise_resolver import ExerciseResolver
    except Exception as e:
        logger.warning(f"[WorkoutHistoryFile] Resolver import failed: {e}")
        return {}

    resolver = ExerciseResolver()
    out: Dict[str, List[UnresolvedSuggestion]] = {}
    for raw in raw_names_lower:
        try:
            result = resolver.resolve(raw)
        except Exception as e:
            logger.debug(f"Resolver failed for '{raw}': {e}")
            out[raw] = []
            continue

        suggestions: List[UnresolvedSuggestion] = []
        # Level 1-3 produce a canonical name; level 4 is the fallback.
        if result.level <= 3:
            suggestions.append(UnresolvedSuggestion(
                canonical_name=result.canonical_name,
                exercise_id=str(result.exercise_id) if result.exercise_id else None,
                confidence=float(result.confidence),
                source={1: "alias", 2: "library", 3: "rag"}.get(result.level, "unknown"),
            ))
        # Future: augment with RAG.query for alternative suggestions. Current
        # ExerciseResolver returns only the top match — leave slot for the
        # Flutter "Search library…" escape hatch when confidence is borderline.
        out[raw] = suggestions
    return out


def _update_rag_after_remap(
    *,
    user_id: str,
    old_canonical: str,
    new_canonical: str,
    new_exercise_id: Optional[str],
) -> None:
    """Background task — rewrite ChromaDB session metadata so strength history
    queries pull the right rows post-remap. Best-effort; we don't block the
    rename on RAG success."""
    try:
        from services.workout_import.rag_indexer import update_session_metadata_for_remap

        update_session_metadata_for_remap(
            user_id=UUID(user_id),
            old_canonical=old_canonical,
            new_canonical=new_canonical,
            new_exercise_id=UUID(new_exercise_id) if new_exercise_id else None,
        )
    except Exception as e:
        logger.warning(f"⚠️ [WorkoutHistoryFile] RAG metadata update failed: {e}")
