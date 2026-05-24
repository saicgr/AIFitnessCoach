"""
Cardio Logs API.

Endpoints for the dedicated `cardio_logs` table (see migration 1965). This
is a sibling to `workout_history_imports` — strength lands there, cardio
lands here. Both feed the AI coach via `get_user_strength_history` +
`get_user_cardio_history`.

Endpoints:
  POST   /cardio-logs              — single insert (manual entry)
  POST   /cardio-logs/bulk         — batch insert (for the import pipeline)
  GET    /cardio-logs/user/{id}    — paginated, filterable history
  GET    /cardio-logs/user/{id}/summary — rollups per activity_type
  DELETE /cardio-logs/user/{id}/entry/{entry_id}

All endpoints require auth and verify user ownership.
"""
from datetime import datetime, date, timedelta, timezone
from typing import List, Optional, Dict, Any

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from pydantic import BaseModel, Field, validator

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/cardio-logs", tags=["Cardio Logs"])


# =============================================================================
# Shared enums / guards — kept in sync with migration 1965 CHECK constraints
# =============================================================================

ALLOWED_ACTIVITY_TYPES = {
    "run", "trail_run", "treadmill", "walk", "hike",
    "cycle", "indoor_cycle", "mountain_bike", "gravel_bike",
    "row", "erg",
    "swim", "open_water_swim",
    "elliptical", "stair", "stepmill",
    "ski_erg", "skate_ski", "nordic_ski", "downhill_ski", "snowboard",
    "yoga", "pilates",
    "hiit", "boxing", "kickboxing",
    "other",
}

ALLOWED_SOURCE_APPS = {
    # Cardio-native apps
    "strava", "peloton", "garmin", "apple_health", "fitbit", "nike",
    "mapmyrun", "runkeeper", "hevy", "fitbod",
    # Manual / generic
    "manual", "ai_parsed", "generic_gpx", "generic_csv",
}


# =============================================================================
# Models
# =============================================================================

class CardioLogEntry(BaseModel):
    """Payload for a single cardio entry. Mirrors cardio_logs columns."""
    performed_at: datetime
    activity_type: str = Field(..., description="One of ALLOWED_ACTIVITY_TYPES")
    duration_seconds: int = Field(..., gt=0, le=24 * 3600 * 2)  # cap at 48h; longer is almost always a bug
    distance_m: Optional[float] = Field(default=None, ge=0)
    elevation_gain_m: Optional[float] = Field(default=None, ge=0)
    avg_heart_rate: Optional[int] = Field(default=None, ge=20, le=260)
    max_heart_rate: Optional[int] = Field(default=None, ge=20, le=260)
    avg_pace_seconds_per_km: Optional[float] = Field(default=None, gt=0)
    avg_speed_mps: Optional[float] = Field(default=None, ge=0)
    avg_watts: Optional[int] = Field(default=None, ge=0)
    max_watts: Optional[int] = Field(default=None, ge=0)
    avg_cadence: Optional[int] = Field(default=None, ge=0)
    avg_stroke_rate: Optional[int] = Field(default=None, ge=0)
    training_effect: Optional[float] = Field(default=None, ge=0, le=10)
    vo2max_estimate: Optional[float] = Field(default=None, gt=0)
    calories: Optional[int] = Field(default=None, ge=0)
    rpe: Optional[float] = Field(default=None, ge=0, le=10)
    notes: Optional[str] = Field(default=None, max_length=2000)
    gps_polyline: Optional[str] = None
    splits_json: Optional[List[Dict[str, Any]]] = None
    source_app: str = Field(default="manual")
    source_external_id: Optional[str] = None
    source_row_hash: Optional[str] = None  # caller computes; else DB will require unique

    @validator("activity_type")
    def validate_activity_type(cls, v: str) -> str:
        if v not in ALLOWED_ACTIVITY_TYPES:
            raise ValueError(
                f"activity_type must be one of {sorted(ALLOWED_ACTIVITY_TYPES)}"
            )
        return v

    @validator("source_app")
    def validate_source_app(cls, v: str) -> str:
        # Keep the whitelist open-ended in practice; warn but allow so an
        # OAuth provider we haven't explicitly listed can still log data.
        if v not in ALLOWED_SOURCE_APPS:
            logger.warning(f"Unknown cardio source_app '{v}' — allowing but flagging")
        return v

    @validator("max_heart_rate")
    def max_hr_ge_avg(cls, v, values):
        avg = values.get("avg_heart_rate")
        if v is not None and avg is not None and v < avg:
            raise ValueError("max_heart_rate must be >= avg_heart_rate")
        return v


class SingleCardioInsertRequest(CardioLogEntry):
    user_id: str


class BulkCardioInsertRequest(BaseModel):
    user_id: str
    entries: List[CardioLogEntry] = Field(..., min_items=1, max_items=500)


class CardioLogResponse(BaseModel):
    id: str
    user_id: str
    performed_at: datetime
    activity_type: str
    duration_seconds: int
    distance_m: Optional[float]
    elevation_gain_m: Optional[float]
    avg_heart_rate: Optional[int]
    max_heart_rate: Optional[int]
    avg_pace_seconds_per_km: Optional[float]
    avg_speed_mps: Optional[float]
    avg_watts: Optional[int]
    max_watts: Optional[int]
    avg_cadence: Optional[int]
    avg_stroke_rate: Optional[int]
    training_effect: Optional[float]
    vo2max_estimate: Optional[float]
    calories: Optional[int]
    rpe: Optional[float]
    notes: Optional[str]
    gps_polyline: Optional[str]
    splits_json: Optional[List[Dict[str, Any]]]
    source_app: str
    source_external_id: Optional[str]
    created_at: datetime


class CardioInsertSummary(BaseModel):
    inserted_count: int
    duplicate_count: int
    failed_count: int
    message: str


class CardioTypeSummary(BaseModel):
    activity_type: str
    total_sessions: int
    total_duration_seconds: int
    total_distance_m: float
    max_distance_m: float
    max_duration_seconds: int
    fastest_pace_seconds_per_km: Optional[float]
    last_performed_at: Optional[datetime]


class CardioSummaryResponse(BaseModel):
    user_id: str
    total_sessions: int
    total_duration_seconds: int
    total_distance_m: float
    weekly_distance_m: float
    weekly_sessions: int
    longest_run_m: Optional[float]
    per_activity: List[CardioTypeSummary]


# =============================================================================
# Helpers
# =============================================================================

def _compute_row_hash_for_manual(entry: CardioLogEntry, user_id: str) -> str:
    """Mirror CanonicalCardioRow.compute_row_hash for manual inserts so the
    unique-index dedup still works — a user who logs the same run twice at
    the same timestamp should collide, not double-count."""
    import hashlib
    parts = [
        user_id,
        entry.source_app,
        entry.performed_at.replace(microsecond=0).isoformat(),
        entry.activity_type,
        str(entry.duration_seconds),
        f"{round(entry.distance_m):.0f}" if entry.distance_m is not None else "",
    ]
    return hashlib.sha256("|".join(parts).encode("utf-8")).hexdigest()


def _entry_to_db_row(entry: CardioLogEntry, user_id: str) -> Dict[str, Any]:
    row: Dict[str, Any] = {
        "user_id": user_id,
        "performed_at": entry.performed_at.isoformat(),
        "activity_type": entry.activity_type,
        "duration_seconds": entry.duration_seconds,
        "distance_m": entry.distance_m,
        "elevation_gain_m": entry.elevation_gain_m,
        "avg_heart_rate": entry.avg_heart_rate,
        "max_heart_rate": entry.max_heart_rate,
        "avg_pace_seconds_per_km": entry.avg_pace_seconds_per_km,
        "avg_speed_mps": entry.avg_speed_mps,
        "avg_watts": entry.avg_watts,
        "max_watts": entry.max_watts,
        "avg_cadence": entry.avg_cadence,
        "avg_stroke_rate": entry.avg_stroke_rate,
        "training_effect": entry.training_effect,
        "vo2max_estimate": entry.vo2max_estimate,
        "calories": entry.calories,
        "rpe": entry.rpe,
        "notes": entry.notes,
        "gps_polyline": entry.gps_polyline,
        "splits_json": entry.splits_json,
        "source_app": entry.source_app,
        "source_external_id": entry.source_external_id,
        "source_row_hash": entry.source_row_hash or _compute_row_hash_for_manual(entry, user_id),
    }
    return row


# =============================================================================
# Post-insert background hook — runs weather lookup + dedup + PR detection +
# auto-tag derivation for each freshly-inserted cardio_log. Single fan-out
# point so the four services don't each need their own webhook into the
# insert endpoint. All steps are best-effort + isolated in try/except so one
# failure never blocks the others or surfaces as a 500 to the user.
# =============================================================================

async def _post_insert_enrich(cardio_log_id: str, user_id: str) -> None:
    """Run weather, dedup, PR, and autotag services on a newly-inserted log.

    Called via `BackgroundTasks.add_task` so the insert request returns
    immediately and the user sees their session logged. Re-running is
    idempotent — services are designed to no-op on second invocation.
    """
    db = get_supabase_db()

    # 1) Weather lookup (Open-Meteo) — populates cardio_logs.weather_json.
    #    Skips for indoor activities or missing GPS.
    try:
        row = (
            db.client.table("cardio_logs")
            .select("id, user_id, performed_at, gps_polyline, indoor_metadata")
            .eq("id", cardio_log_id)
            .single()
            .execute()
        )
        if row.data and not (row.data.get("indoor_metadata") or {}).get("is_indoor"):
            # Try to extract a lat/lon from the start of the polyline. The
            # polyline is an encoded text; for now we skip weather lookup
            # when we don't have decoded coords (the route-upload path
            # writes route_polyline_s3_key with structured points where
            # weather backfill can re-derive lat/lon).
            poly = row.data.get("gps_polyline")
            if poly:
                # Defer: weather backfill happens when the structured route
                # payload lands via /cardio-logs/{id}/route (SLICE_GPS).
                pass
    except Exception as e:
        logger.warning(f"[CardioLogs] post-insert weather skipped: {e}")

    # 2) Dedup — find candidates ±90s / ±5% / same sport, apply primary/hidden.
    try:
        from services.cardio_dedup_service import (
            find_duplicate_candidates,
            resolve_dedup_group,
            apply_dedup_group,
        )
        candidates = find_duplicate_candidates(db, user_id, cardio_log_id)
        if len(candidates) > 1:
            resolved = resolve_dedup_group(db, candidates)
            apply_dedup_group(db, resolved["primary_id"], resolved["hidden_ids"])
            logger.info(
                f"[CardioLogs] dedup grouped {len(candidates)} rows "
                f"primary={resolved['primary_id']}"
            )
    except Exception as e:
        logger.warning(f"[CardioLogs] post-insert dedup skipped: {e}")

    # 3) PR detection — emits cardio PRs into personal_records.
    try:
        from services.cardio_pr_service import CardioPrService
        svc = CardioPrService()
        candidates = svc.detect_cardio_prs(db, cardio_log_id)
        if candidates:
            svc.persist_prs(db, user_id, candidates)
            logger.info(
                f"[CardioLogs] PR persisted {len(candidates)} cardio records "
                f"user={user_id}"
            )
    except Exception as e:
        logger.warning(f"[CardioLogs] post-insert PR skipped: {e}")

    # 4) Auto-tag derivation — hill / negative-split / new-route / dawn/dusk.
    try:
        from services.cardio_autotag_service import update_tags
        update_tags(db, cardio_log_id)
    except Exception as e:
        logger.warning(f"[CardioLogs] post-insert autotag skipped: {e}")


# =============================================================================
# Endpoints
# =============================================================================

@router.post("", response_model=CardioInsertSummary)
async def create_cardio_log(
    request: SingleCardioInsertRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Manually insert a single cardio session. Idempotent via source_row_hash —
    submitting the same (user_id, source_app, performed_at, activity_type,
    duration, distance) twice results in 0 duplicates, not two rows.

    After a successful insert (not a duplicate), schedules a background task
    that runs weather lookup + dedup + PR detection + auto-tags. The user
    sees their session logged immediately; enrichment happens off-request."""
    verify_user_ownership(current_user, request.user_id)
    logger.info(
        f"[CardioLogs] create user={request.user_id} "
        f"type={request.activity_type} duration={request.duration_seconds}s"
    )
    try:
        db = get_supabase_db()
        row = _entry_to_db_row(request, request.user_id)
        result = (
            db.client.table("cardio_logs")
            .upsert(row, on_conflict="user_id,source_row_hash", ignore_duplicates=True)
            .execute()
        )
        inserted = len(result.data or [])
        if inserted and result.data:
            new_id = result.data[0].get("id")
            if new_id:
                background_tasks.add_task(
                    _post_insert_enrich, str(new_id), str(request.user_id)
                )
        return CardioInsertSummary(
            inserted_count=inserted,
            duplicate_count=1 - inserted,
            failed_count=0,
            message=(
                f"Logged {request.activity_type} session"
                if inserted
                else "Duplicate — session already on file"
            ),
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[CardioLogs] create error: {e}", exc_info=True)
        raise safe_internal_error(e, "cardio_logs")


@router.post("/bulk", response_model=CardioInsertSummary)
async def bulk_create_cardio_logs(
    request: BulkCardioInsertRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
):
    """Batch insert up to 500 entries at once. Used by the import pipeline's
    `_bulk_insert_cardio`. Duplicate rows (matching source_row_hash) are
    silently ignored so re-importing the same file is safe.

    Each successfully-inserted row schedules a background enrichment task
    (weather + dedup + PR + autotags). Bulk imports of 100s of rows queue
    many tasks but each is cheap (~50-200ms) and runs after the response."""
    verify_user_ownership(current_user, request.user_id)
    logger.info(f"[CardioLogs] bulk user={request.user_id} count={len(request.entries)}")

    try:
        db = get_supabase_db()
        rows = [_entry_to_db_row(e, request.user_id) for e in request.entries]

        # Chunked upsert — Supabase payload size cap + safer for transient
        # network failures. 250 rows/chunk fits comfortably in a 2MB body.
        CHUNK = 250
        total_inserted = 0
        total_failed = 0
        new_ids: List[str] = []
        for i in range(0, len(rows), CHUNK):
            chunk = rows[i:i + CHUNK]
            try:
                result = (
                    db.client.table("cardio_logs")
                    .upsert(chunk, on_conflict="user_id,source_row_hash", ignore_duplicates=True)
                    .execute()
                )
                total_inserted += len(result.data or [])
                for d in (result.data or []):
                    nid = d.get("id")
                    if nid:
                        new_ids.append(str(nid))
            except Exception as e:
                logger.warning(f"[CardioLogs] bulk chunk failed ({len(chunk)} rows): {e}")
                # Fall back to per-row so one bad row doesn't drop the batch.
                for single in chunk:
                    try:
                        r = (
                            db.client.table("cardio_logs")
                            .upsert(single, on_conflict="user_id,source_row_hash", ignore_duplicates=True)
                            .execute()
                        )
                        total_inserted += len(r.data or [])
                        for d in (r.data or []):
                            nid = d.get("id")
                            if nid:
                                new_ids.append(str(nid))
                    except Exception as inner:
                        logger.error(f"[CardioLogs] per-row failure: {inner}")
                        total_failed += 1

        # Enrichment fan-out — schedule one background task per new row. Cheap
        # individually; for a 500-row import this queues ~500 tasks but each
        # service short-circuits in well under 500ms on typical data.
        for nid in new_ids:
            background_tasks.add_task(
                _post_insert_enrich, nid, str(request.user_id)
            )

        duplicates = len(rows) - total_inserted - total_failed

        return CardioInsertSummary(
            inserted_count=total_inserted,
            duplicate_count=max(duplicates, 0),
            failed_count=total_failed,
            message=f"Inserted {total_inserted} new cardio sessions ({duplicates} duplicates skipped)",
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[CardioLogs] bulk error: {e}", exc_info=True)
        raise safe_internal_error(e, "cardio_logs")


@router.get("/user/{user_id}", response_model=List[CardioLogResponse])
async def get_user_cardio_logs(
    user_id: str,
    activity_type: Optional[str] = Query(default=None),
    from_date: Optional[date] = Query(default=None, alias="from"),
    to_date: Optional[date] = Query(default=None, alias="to"),
    limit: int = Query(default=50, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    """Paginated, filterable cardio history for the history screen.

    Filters:
      - activity_type=run  (single type only; UI displays chips)
      - from=2026-01-01&to=2026-02-01  (inclusive)
    """
    verify_user_ownership(current_user, user_id)
    logger.debug(
        f"[CardioLogs] list user={user_id} type={activity_type} "
        f"from={from_date} to={to_date} limit={limit} offset={offset}"
    )
    try:
        db = get_supabase_db()
        query = db.client.table("cardio_logs").select("*").eq("user_id", user_id)
        if activity_type:
            if activity_type not in ALLOWED_ACTIVITY_TYPES:
                raise HTTPException(status_code=400, detail=f"Invalid activity_type: {activity_type}")
            query = query.eq("activity_type", activity_type)
        if from_date:
            query = query.gte("performed_at", from_date.isoformat())
        if to_date:
            # Inclusive upper bound: end-of-day in UTC.
            end_of_day = datetime.combine(to_date, datetime.max.time(), tzinfo=timezone.utc)
            query = query.lte("performed_at", end_of_day.isoformat())

        end_offset = offset + limit - 1
        result = query.order("performed_at", desc=True).range(offset, end_offset).execute()

        entries: List[CardioLogResponse] = []
        for row in result.data or []:
            entries.append(CardioLogResponse(
                id=row["id"],
                user_id=row["user_id"],
                performed_at=datetime.fromisoformat(str(row["performed_at"]).replace("Z", "+00:00")),
                activity_type=row["activity_type"],
                duration_seconds=row["duration_seconds"],
                distance_m=float(row["distance_m"]) if row.get("distance_m") is not None else None,
                elevation_gain_m=float(row["elevation_gain_m"]) if row.get("elevation_gain_m") is not None else None,
                avg_heart_rate=row.get("avg_heart_rate"),
                max_heart_rate=row.get("max_heart_rate"),
                avg_pace_seconds_per_km=float(row["avg_pace_seconds_per_km"]) if row.get("avg_pace_seconds_per_km") is not None else None,
                avg_speed_mps=float(row["avg_speed_mps"]) if row.get("avg_speed_mps") is not None else None,
                avg_watts=row.get("avg_watts"),
                max_watts=row.get("max_watts"),
                avg_cadence=row.get("avg_cadence"),
                avg_stroke_rate=row.get("avg_stroke_rate"),
                training_effect=float(row["training_effect"]) if row.get("training_effect") is not None else None,
                vo2max_estimate=float(row["vo2max_estimate"]) if row.get("vo2max_estimate") is not None else None,
                calories=row.get("calories"),
                rpe=float(row["rpe"]) if row.get("rpe") is not None else None,
                notes=row.get("notes"),
                gps_polyline=row.get("gps_polyline"),
                splits_json=row.get("splits_json"),
                source_app=row["source_app"],
                source_external_id=row.get("source_external_id"),
                created_at=datetime.fromisoformat(str(row["created_at"]).replace("Z", "+00:00")),
            ))
        return entries

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[CardioLogs] list error: {e}", exc_info=True)
        raise safe_internal_error(e, "cardio_logs")


@router.get("/user/{user_id}/summary", response_model=CardioSummaryResponse)
async def get_user_cardio_summary(
    user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Aggregated cardio stats. Fed to the home-screen tracking strip, the
    AI coach context (`get_user_cardio_history`), and the cardio-history
    screen header cards.

    Computed in-process rather than via a Postgres RPC so the endpoint is
    portable — we don't depend on a yet-unshipped SQL function.
    """
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()

        result = (
            db.client.table("cardio_logs")
            .select(
                "activity_type, duration_seconds, distance_m, "
                "avg_pace_seconds_per_km, performed_at"
            )
            .eq("user_id", user_id)
            .order("performed_at", desc=True)
            .execute()
        )
        rows = result.data or []

        total_sessions = len(rows)
        total_duration = sum(int(r.get("duration_seconds") or 0) for r in rows)
        total_distance = sum(float(r.get("distance_m") or 0) for r in rows)
        week_ago = datetime.now(tz=timezone.utc) - timedelta(days=7)

        weekly_rows = [
            r for r in rows
            if datetime.fromisoformat(str(r["performed_at"]).replace("Z", "+00:00")) >= week_ago
        ]
        weekly_distance = sum(float(r.get("distance_m") or 0) for r in weekly_rows)
        weekly_sessions = len(weekly_rows)

        # Per-activity rollups.
        buckets: Dict[str, Dict[str, Any]] = {}
        for r in rows:
            t = r["activity_type"]
            b = buckets.setdefault(t, {
                "total_sessions": 0,
                "total_duration_seconds": 0,
                "total_distance_m": 0.0,
                "max_distance_m": 0.0,
                "max_duration_seconds": 0,
                "fastest_pace_seconds_per_km": None,
                "last_performed_at": None,
            })
            duration = int(r.get("duration_seconds") or 0)
            distance = float(r.get("distance_m") or 0)
            pace = r.get("avg_pace_seconds_per_km")
            performed_dt = datetime.fromisoformat(str(r["performed_at"]).replace("Z", "+00:00"))

            b["total_sessions"] += 1
            b["total_duration_seconds"] += duration
            b["total_distance_m"] += distance
            if distance > b["max_distance_m"]:
                b["max_distance_m"] = distance
            if duration > b["max_duration_seconds"]:
                b["max_duration_seconds"] = duration
            if pace is not None:
                # Lower pace = faster; only track if sufficiently long to be
                # meaningful (< 500 m runs skew the "PR" data).
                if distance >= 500:
                    p = float(pace)
                    if b["fastest_pace_seconds_per_km"] is None or p < b["fastest_pace_seconds_per_km"]:
                        b["fastest_pace_seconds_per_km"] = p
            if b["last_performed_at"] is None or performed_dt > b["last_performed_at"]:
                b["last_performed_at"] = performed_dt

        per_activity = [
            CardioTypeSummary(
                activity_type=t,
                total_sessions=b["total_sessions"],
                total_duration_seconds=b["total_duration_seconds"],
                total_distance_m=round(b["total_distance_m"], 2),
                max_distance_m=round(b["max_distance_m"], 2),
                max_duration_seconds=b["max_duration_seconds"],
                fastest_pace_seconds_per_km=b["fastest_pace_seconds_per_km"],
                last_performed_at=b["last_performed_at"],
            )
            for t, b in sorted(buckets.items(), key=lambda kv: -kv[1]["total_sessions"])
        ]

        # Longest run specifically — common surface-level PR users ask about.
        longest_run = 0.0
        for b in buckets.get("run", {}).get("max_distance_m", 0.0), buckets.get("trail_run", {}).get("max_distance_m", 0.0), buckets.get("treadmill", {}).get("max_distance_m", 0.0):
            if isinstance(b, (int, float)) and b > longest_run:
                longest_run = float(b)

        return CardioSummaryResponse(
            user_id=user_id,
            total_sessions=total_sessions,
            total_duration_seconds=total_duration,
            total_distance_m=round(total_distance, 2),
            weekly_distance_m=round(weekly_distance, 2),
            weekly_sessions=weekly_sessions,
            longest_run_m=round(longest_run, 2) if longest_run else None,
            per_activity=per_activity,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[CardioLogs] summary error: {e}", exc_info=True)
        raise safe_internal_error(e, "cardio_logs")


@router.delete("/user/{user_id}/entry/{entry_id}")
async def delete_cardio_log(
    user_id: str,
    entry_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Delete a single cardio entry. Not undoable — the UI should confirm."""
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()
        result = (
            db.client.table("cardio_logs")
            .delete()
            .eq("id", entry_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=404, detail="Entry not found")
        return {"message": "Cardio entry deleted", "id": entry_id}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[CardioLogs] delete error: {e}", exc_info=True)
        raise safe_internal_error(e, "cardio_logs")
