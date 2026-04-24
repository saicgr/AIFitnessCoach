"""
WorkoutHistoryImporter — orchestrator that turns an uploaded file into:
  - rows in workout_history_imports (strength history)
  - rows in cardio_logs (cardio sessions)
  - rows in workout_program_templates (creator programs)
  - docs in ChromaDB (user_exercise_history + user_cardio_history)

Called from the media_job_runner `workout_history_import` branch. The run()
method is idempotent — re-running against the same file produces zero new
rows thanks to source_row_hash unique indexes.
"""
from __future__ import annotations

import asyncio
import io
from typing import Any, Optional
from uuid import UUID

from core.db import get_supabase_db
from core.logger import get_logger

from .canonical import (
    CanonicalCardioRow,
    CanonicalSetRow,
    ImportMode,
    ParseResult,
)
from .exercise_resolver import ExerciseResolver
from .format_detector import detect
from .rag_indexer import index_cardio_sessions, index_strength_sessions

logger = get_logger(__name__)


BULK_INSERT_CHUNK = 500  # Supabase POST body cap comfortable here


class WorkoutHistoryImporter:
    """Stateless per-call; a fresh ExerciseResolver is created per run so the
    library cache reflects the latest exercise_library state."""

    async def run(self, job: dict[str, Any]) -> dict[str, Any]:
        """Execute a workout_history_import media job end-to-end.
        Returns a summary dict stored back into media_analysis_jobs.result.
        """
        params = job.get("params") or {}
        user_id_str = params.get("user_id") or job.get("user_id")
        if not user_id_str:
            raise ValueError("workout_history_import job missing user_id")
        user_id = UUID(user_id_str)

        s3_keys = job.get("s3_keys") or []
        if not s3_keys:
            raise ValueError("workout_history_import job missing s3_keys")
        s3_key = s3_keys[0]

        unit_hint = params.get("unit_hint") or "lb"
        tz_hint = params.get("timezone_hint") or "UTC"
        source_app_hint = params.get("source_app_hint")
        filename = params.get("filename") or s3_key.rsplit("/", 1)[-1]
        dry_run = bool(params.get("dry_run"))

        logger.info(
            f"📦 [WorkoutImport] job={job['id']} user={user_id} file={filename} "
            f"unit={unit_hint} tz={tz_hint} hint={source_app_hint} dry_run={dry_run}"
        )

        # 1. Fetch bytes from S3 (reuses existing helper; see services.s3_service).
        data = await _download_s3_bytes(s3_key)

        # 2. Classify + route.
        detection = detect(data, filename=filename)
        if source_app_hint:
            detection.source_app = source_app_hint
        logger.info(
            f"🔍 [WorkoutImport] detected app={detection.source_app} "
            f"mode={detection.mode} confidence={detection.confidence:.2f}"
        )

        # 3. Dispatch to adapter.
        parse_result = await self._dispatch(
            detection_source_app=detection.source_app,
            detection_mode=detection.mode,
            data=data,
            filename=filename,
            user_id=user_id,
            unit_hint=unit_hint,
            tz_hint=tz_hint,
        )

        # 4. Resolve exercise names for every strength row.
        resolver = ExerciseResolver()
        unresolved: list[str] = []
        for row in parse_result.strength_rows:
            res = resolver.resolve(row.exercise_name_raw)
            row.exercise_name_canonical = res.canonical_name
            row.exercise_id = res.exercise_id
            if res.level == 4:
                unresolved.append(row.exercise_name_raw)
        # Also resolve exercise names inside any program template.
        if parse_result.template:
            for week in parse_result.template.weeks:
                for day in week.days:
                    for exercise in day.exercises:
                        res = resolver.resolve(exercise.exercise_name_raw)
                        exercise.exercise_name_canonical = res.canonical_name
                        exercise.exercise_id = res.exercise_id
                        if res.level == 4:
                            unresolved.append(exercise.exercise_name_raw)

        # 5. Preview mode: return sample rows without writing anything.
        if dry_run:
            return {
                "dry_run": True,
                "source_app": detection.source_app,
                "mode": parse_result.mode.value if hasattr(parse_result.mode, "value") else parse_result.mode,
                "confidence": detection.confidence,
                "strength_row_count": len(parse_result.strength_rows),
                "cardio_row_count": len(parse_result.cardio_rows),
                "has_template": parse_result.template is not None,
                "unresolved_exercises": list(set(unresolved))[:50],
                "warnings": detection.warnings + parse_result.warnings,
                "sample_rows": parse_result.sample_rows_for_preview[:20],
            }

        # 6. Write everything to Supabase.
        job_id = UUID(job["id"])
        db = get_supabase_db()

        inserted_strength = self._bulk_insert_strength(
            db, parse_result.strength_rows, job_id
        )
        inserted_cardio = self._bulk_insert_cardio(
            db, parse_result.cardio_rows, job_id
        )
        inserted_template_id: Optional[str] = None
        if parse_result.template is not None:
            inserted_template_id = self._insert_template(
                db, parse_result.template, job_id
            )

        # 7. Index to RAG (best-effort — don't fail the job if Chroma flakes).
        user_first_name = await self._fetch_first_name(db, user_id)
        rag_strength = rag_cardio = 0
        try:
            rag_strength = index_strength_sessions(
                parse_result.strength_rows, user_first_name=user_first_name
            )
        except Exception as e:
            logger.warning(f"[WorkoutImport] RAG strength index failed: {e}")
        try:
            rag_cardio = index_cardio_sessions(
                parse_result.cardio_rows, user_first_name=user_first_name
            )
        except Exception as e:
            logger.warning(f"[WorkoutImport] RAG cardio index failed: {e}")

        summary = {
            "dry_run": False,
            "source_app": detection.source_app,
            "mode": parse_result.mode.value if hasattr(parse_result.mode, "value") else parse_result.mode,
            "confidence": detection.confidence,
            "inserted_strength_rows": inserted_strength,
            "duplicate_strength_rows": len(parse_result.strength_rows) - inserted_strength,
            "inserted_cardio_rows": inserted_cardio,
            "duplicate_cardio_rows": len(parse_result.cardio_rows) - inserted_cardio,
            "template_id": inserted_template_id,
            "unresolved_exercises": sorted(set(unresolved)),
            "rag_strength_sessions": rag_strength,
            "rag_cardio_sessions": rag_cardio,
            "warnings": detection.warnings + parse_result.warnings,
        }
        logger.info(f"✅ [WorkoutImport] job={job['id']} complete: {summary}")
        return summary

    # ──────────────────────────────── Dispatch ────────────────────────────────

    async def _dispatch(
        self,
        *,
        detection_source_app: str,
        detection_mode: ImportMode,
        data: bytes,
        filename: str,
        user_id: UUID,
        unit_hint: str,
        tz_hint: str,
    ) -> ParseResult:
        """Route to the adapter module matching detection_source_app.
        Adapters are imported lazily so a slow/heavy import doesn't block
        other job types from starting."""
        try:
            adapter = _load_adapter(detection_source_app)
        except Exception as e:
            logger.warning(
                f"[WorkoutImport] no adapter for source_app={detection_source_app}: {e}. "
                "Falling back to AI extraction."
            )
            adapter = _load_adapter("ai_fallback")

        return await _call_adapter(
            adapter,
            data=data,
            filename=filename,
            user_id=user_id,
            unit_hint=unit_hint,
            tz_hint=tz_hint,
            mode_hint=detection_mode,
        )

    # ──────────────────────────────── Writes ────────────────────────────────

    def _bulk_insert_strength(
        self,
        db,
        rows: list[CanonicalSetRow],
        job_id: UUID,
    ) -> int:
        """Insert strength rows in chunks, ignoring (user_id, source_row_hash)
        dedup collisions. Returns the count actually persisted."""
        if not rows:
            return 0
        total_inserted = 0
        payloads = [r.to_supabase_row(job_id) for r in rows]
        for chunk in _chunks(payloads, BULK_INSERT_CHUNK):
            try:
                result = (
                    db.client.table("workout_history_imports")
                    .upsert(
                        chunk,
                        on_conflict="user_id,source_row_hash",
                        ignore_duplicates=True,
                    )
                    .execute()
                )
                total_inserted += len(result.data or [])
            except Exception as e:
                # Per-row fallback if the batch upsert blows up — one bad row
                # shouldn't drop the whole 500.
                logger.warning(
                    f"[WorkoutImport] bulk strength upsert failed ({e!s}); "
                    f"retrying row-by-row for chunk of {len(chunk)}"
                )
                for row in chunk:
                    try:
                        result = (
                            db.client.table("workout_history_imports")
                            .upsert(
                                row,
                                on_conflict="user_id,source_row_hash",
                                ignore_duplicates=True,
                            )
                            .execute()
                        )
                        total_inserted += len(result.data or [])
                    except Exception as inner:
                        logger.error(
                            f"[WorkoutImport] dropping strength row "
                            f"({row.get('exercise_name')}, {row.get('performed_at')}): {inner}"
                        )
        return total_inserted

    def _bulk_insert_cardio(
        self,
        db,
        rows: list[CanonicalCardioRow],
        job_id: UUID,
    ) -> int:
        if not rows:
            return 0
        total_inserted = 0
        payloads = [r.to_supabase_row(job_id) for r in rows]
        for chunk in _chunks(payloads, BULK_INSERT_CHUNK):
            try:
                result = (
                    db.client.table("cardio_logs")
                    .upsert(
                        chunk,
                        on_conflict="user_id,source_row_hash",
                        ignore_duplicates=True,
                    )
                    .execute()
                )
                total_inserted += len(result.data or [])
            except Exception as e:
                logger.warning(
                    f"[WorkoutImport] bulk cardio upsert failed ({e!s}); "
                    f"retrying row-by-row"
                )
                for row in chunk:
                    try:
                        result = (
                            db.client.table("cardio_logs")
                            .upsert(row, on_conflict="user_id,source_row_hash",
                                    ignore_duplicates=True)
                            .execute()
                        )
                        total_inserted += len(result.data or [])
                    except Exception as inner:
                        logger.error(
                            f"[WorkoutImport] dropping cardio row "
                            f"({row.get('activity_type')}, {row.get('performed_at')}): {inner}"
                        )
        return total_inserted

    def _insert_template(self, db, template, job_id: UUID) -> Optional[str]:
        try:
            result = (
                db.client.table("workout_program_templates")
                .insert(template.to_supabase_row(job_id))
                .execute()
            )
            if result.data:
                return result.data[0]["id"]
        except Exception as e:
            logger.error(f"[WorkoutImport] template insert failed: {e}")
        return None

    async def _fetch_first_name(self, db, user_id: UUID) -> str:
        try:
            result = (
                db.client.table("users")
                .select("first_name")
                .eq("id", str(user_id))
                .limit(1)
                .execute()
            )
            if result.data:
                fn = result.data[0].get("first_name")
                if fn:
                    return fn
        except Exception:
            pass
        return "User"


# ──────────────────────────────── Helpers ────────────────────────────────

def _chunks(seq, size):
    for i in range(0, len(seq), size):
        yield seq[i:i + size]


async def _download_s3_bytes(s3_key: str) -> bytes:
    """Fetch a file's bytes from our S3 bucket. Returns bytes, not a stream —
    the adapter pipeline holds the full file in memory for pandas/lxml."""
    from services.s3_service import get_s3_service

    svc = get_s3_service()
    # The existing helper signature varies; adapt both sync + async call shapes.
    if hasattr(svc, "download_bytes"):
        res = svc.download_bytes(s3_key)
        if asyncio.iscoroutine(res):
            return await res
        return res
    if hasattr(svc, "get_object_bytes"):
        return svc.get_object_bytes(s3_key)
    raise RuntimeError("s3_service has no byte-download method")


def _load_adapter(source_app: str):
    """Lazy-import the adapter module for a detected source_app slug.
    Returns a module exporting `async def parse(...)`."""
    import importlib

    # Creator programs live in .programs; everything else in .adapters.
    is_creator = source_app in {
        "nippard", "rp", "nuckols_sbs", "wendler_531",
        "nsuns", "gzclp", "metallicadpa_ppl",
        "starting_strength", "stronglifts",
        "sbtd_uplifted", "lyle_gbr", "bws_intermediate",
        "buff_dudes", "athlean", "generic_xlsx", "generic_xlsm", "generic_sheet",
    }
    pkg = "services.workout_import.programs" if is_creator else "services.workout_import.adapters"
    return importlib.import_module(f"{pkg}.{source_app}")


async def _call_adapter(
    adapter,
    *,
    data: bytes,
    filename: str,
    user_id: UUID,
    unit_hint: str,
    tz_hint: str,
    mode_hint: ImportMode,
) -> ParseResult:
    """Invoke adapter.parse(...) handling sync + async adapters uniformly.
    Every adapter exports this single entrypoint."""
    parse_fn = getattr(adapter, "parse", None)
    if parse_fn is None:
        raise RuntimeError(f"adapter {adapter.__name__} has no parse()")
    result = parse_fn(
        data=data,
        filename=filename,
        user_id=user_id,
        unit_hint=unit_hint,
        tz_hint=tz_hint,
        mode_hint=mode_hint,
    )
    if asyncio.iscoroutine(result):
        result = await result
    return result
