"""Nutrition importer endpoints (Part A).

Async dry-run preview → commit, mirroring the media-jobs pattern:

  POST /nutrition/import            (multipart file | apple_health_json) -> {job_id}
  GET  /nutrition/import/{job_id}   -> {status, preview|result|error}
  POST /nutrition/import/{job_id}/commit {overlap_strategy, include_weight}

The raw upload is parsed in-memory and never persisted (PII). Import is FREE —
no subscription gate (it is the switcher hook).
"""
import asyncio
import json
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field

from core.auth import get_current_user, verify_user_ownership
from core.logger import get_logger
from services.nutrition_import import jobs

logger = get_logger(__name__)
router = APIRouter()

MAX_IMPORT_SIZE = 25 * 1024 * 1024  # 25MB
VALID_SOURCES = {"auto", "myfitnesspal", "macrofactor", "cronometer", "apple_health"}
VALID_STRATEGIES = {"skip", "merge", "replace"}


class CommitRequest(BaseModel):
    user_id: str
    overlap_strategy: str = Field("skip")
    include_weight: bool = False


@router.post("/import")
async def start_import(
    user_id: str = Form(...),
    source: str = Form("auto"),
    file: Optional[UploadFile] = File(None),
    apple_health_json: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
):
    """Upload an export (or Apple Health rows) and start an async dry-run preview."""
    verify_user_ownership(current_user, user_id)
    if source not in VALID_SOURCES:
        raise HTTPException(400, f"Unknown source '{source}'")

    apple_rows = None
    data = None
    filename = ""
    if source == "apple_health" or apple_health_json:
        try:
            apple_rows = json.loads(apple_health_json or "[]")
            if not isinstance(apple_rows, list):
                raise ValueError("apple_health_json must be a JSON array")
        except (ValueError, json.JSONDecodeError) as e:
            raise HTTPException(400, f"Invalid apple_health_json: {e}")
        source = "apple_health"
    else:
        if file is None:
            raise HTTPException(400, "A file (or apple_health_json) is required")
        data = await file.read()
        if len(data) > MAX_IMPORT_SIZE:
            raise HTTPException(413, "Export file too large (max 25MB)")
        if not data:
            raise HTTPException(400, "Empty file")
        filename = file.filename or ""

    job_id = await asyncio.to_thread(jobs.create_job, user_id, source)
    asyncio.create_task(jobs.run_parse_job(
        job_id, user_id, data=data, filename=filename, source=source,
        apple_health_rows=apple_rows,
    ))
    return {"job_id": job_id, "status": "parsing"}


@router.get("/import/{job_id}")
async def get_import(
    job_id: str,
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Poll an import job: returns preview when ready, result when done."""
    verify_user_ownership(current_user, user_id)
    job = await asyncio.to_thread(jobs.get_job, job_id, user_id)
    if not job:
        raise HTTPException(404, "Import job not found")
    return {
        "job_id": job_id,
        "status": job["status"],
        "source": job.get("source"),
        "preview": job.get("preview"),
        "result": job.get("result"),
        "error": job.get("error"),
    }


@router.post("/import/{job_id}/commit")
async def commit_import(
    job_id: str,
    body: CommitRequest,
    current_user: dict = Depends(get_current_user),
):
    """Commit a previewed import with the chosen overlap strategy."""
    verify_user_ownership(current_user, body.user_id)
    if body.overlap_strategy not in VALID_STRATEGIES:
        raise HTTPException(400, f"Invalid overlap_strategy '{body.overlap_strategy}'")
    job = await asyncio.to_thread(jobs.get_job, job_id, body.user_id)
    if not job:
        raise HTTPException(404, "Import job not found")
    if job["status"] not in ("preview_ready", "error"):
        raise HTTPException(409, f"Job not ready to commit (status={job['status']})")
    if not job.get("parsed_rows"):
        raise HTTPException(409, "Nothing to import (preview empty or already committed)")

    asyncio.create_task(jobs.run_commit_job(
        job_id, body.user_id,
        overlap_strategy=body.overlap_strategy, include_weight=body.include_weight,
    ))
    return {"job_id": job_id, "status": "committing"}
