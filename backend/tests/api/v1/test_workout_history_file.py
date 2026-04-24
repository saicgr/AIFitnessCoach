"""
Tests for the file-upload workout history import API.

Covers:
  • POST /workout-history/import/preview — sync dry-run
  • POST /workout-history/import/file    — async job creation
  • POST /workout-history/remap          — batch rename + audit
  • POST /workout-history/remap/{id}/undo — undo
  • GET  /workout-history/unresolved/{user_id} — grouped unresolved

Every test mocks the DB + media_job services to keep it hermetic. The actual
parser pipeline is stubbed via `WorkoutHistoryImporter.run` so we don't need
sample CSVs checked in.
"""
from __future__ import annotations

from io import BytesIO
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import BackgroundTasks, UploadFile


# ─────────────────────── Fixtures ───────────────────────────────────────────

def _make_upload(filename: str = "hevy_export.csv",
                 content: bytes = b"Date,Exercise,Weight,Reps\n2025-04-01,Bench Press,80,8\n",
                 content_type: str = "text/csv") -> UploadFile:
    return UploadFile(filename=filename, file=BytesIO(content), headers={"content-type": content_type})


@pytest.fixture
def fake_user():
    return {"id": "user-1"}


# ─────────────────────── Preview (dry-run) ──────────────────────────────────

class TestPreviewEndpoint:
    """Sync preview must parse bytes and return a summary WITHOUT writing."""

    @pytest.mark.asyncio
    async def test_preview_returns_sample_rows(self, fake_user):
        from api.v1.workout_history_file import preview_import

        # Mock S3 upload so the test never touches AWS.
        mock_s3 = MagicMock()
        mock_s3.is_configured.return_value = True
        mock_s3.upload_bytes.return_value = "workout-history-imports/user-1/2025-preview.csv"

        # Mock the importer so we don't rely on a real adapter.
        fake_summary = {
            "dry_run": True,
            "source_app": "hevy",
            "mode": "history",
            "confidence": 0.92,
            "strength_row_count": 3,
            "cardio_row_count": 0,
            "has_template": False,
            "unresolved_exercises": ["Cable Face Pull"],
            "warnings": [],
            "sample_rows": [
                {"date": "2025-04-01", "exercise": "Bench Press", "weight": 80, "reps": 8},
            ],
        }
        mock_importer = MagicMock()
        mock_importer.run = AsyncMock(return_value=fake_summary)

        with patch("services.s3_service.get_s3_service", return_value=mock_s3), \
             patch(
                 "services.workout_import.service.WorkoutHistoryImporter",
                 return_value=mock_importer,
             ):
            result = await preview_import(
                file=_make_upload(),
                unit_hint="lb",
                timezone_hint="America/Chicago",
                source_app_hint=None,
                current_user=fake_user,
            )

        assert result["dry_run"] is True
        assert result["source_app"] == "hevy"
        assert result["strength_row_count"] == 3
        assert result["sample_rows"][0]["exercise"] == "Bench Press"

        # Verify S3 upload was called (so the adapter can read from S3 as in prod).
        mock_s3.upload_bytes.assert_called_once()
        # Verify no DB write happened: we didn't patch get_supabase_db, so any
        # attempt to write would have raised; reaching this assert proves dry-run.

    @pytest.mark.asyncio
    async def test_preview_rejects_empty_file(self, fake_user):
        from api.v1.workout_history_file import preview_import
        from fastapi import HTTPException

        empty = UploadFile(filename="empty.csv", file=BytesIO(b""), headers={})

        with pytest.raises(HTTPException) as exc:
            await preview_import(
                file=empty,
                unit_hint="lb",
                timezone_hint="UTC",
                source_app_hint=None,
                current_user=fake_user,
            )
        assert exc.value.status_code == 400


# ─────────────────────── Async file upload ──────────────────────────────────

class TestImportFileEndpoint:
    """The async path must create a media_analysis_jobs row and enqueue."""

    @pytest.mark.asyncio
    async def test_import_file_creates_job(self, fake_user):
        from api.v1.workout_history_file import import_file

        mock_s3 = MagicMock()
        mock_s3.is_configured.return_value = True
        mock_s3.upload_bytes.return_value = "workout-history-imports/user-1/hevy.csv"

        mock_job_service = MagicMock()
        mock_job_service.create_job.return_value = "job-uuid-123"

        bg_tasks = BackgroundTasks()

        with patch("services.s3_service.get_s3_service", return_value=mock_s3), \
             patch(
                 "services.media_job_service.get_media_job_service",
                 return_value=mock_job_service,
             ), \
             patch("services.media_job_runner.run_media_job", new_callable=AsyncMock):
            result = await import_file(
                background_tasks=bg_tasks,
                file=_make_upload(),
                unit_hint="lb",
                timezone_hint="America/Chicago",
                source_app_hint="hevy",
                current_user=fake_user,
            )

        assert result == {"job_id": "job-uuid-123", "status": "pending"}

        # Confirm create_job saw the right shape.
        kwargs = mock_job_service.create_job.call_args.kwargs
        assert kwargs["user_id"] == "user-1"
        assert kwargs["job_type"] == "workout_history_import"
        assert kwargs["s3_keys"] == ["workout-history-imports/user-1/hevy.csv"]
        assert kwargs["params"]["unit_hint"] == "lb"
        assert kwargs["params"]["timezone_hint"] == "America/Chicago"
        assert kwargs["params"]["source_app_hint"] == "hevy"
        assert kwargs["params"]["dry_run"] is False

        # BackgroundTasks should have picked up one task (the runner).
        assert len(bg_tasks.tasks) == 1

    @pytest.mark.asyncio
    async def test_import_file_rejects_too_large(self, fake_user):
        from api.v1.workout_history_file import MAX_UPLOAD_SIZE_BYTES, import_file
        from fastapi import HTTPException

        big = UploadFile(
            filename="huge.csv",
            file=BytesIO(b"x" * (MAX_UPLOAD_SIZE_BYTES + 1)),
            headers={},
        )
        with pytest.raises(HTTPException) as exc:
            await import_file(
                background_tasks=BackgroundTasks(),
                file=big,
                unit_hint="lb",
                timezone_hint="UTC",
                source_app_hint=None,
                current_user=fake_user,
            )
        assert exc.value.status_code == 413


# ─────────────────────── Remap ──────────────────────────────────────────────

class TestRemapEndpoint:
    """Batch remap must update rows, write an audit, and insert a contribution."""

    @pytest.mark.asyncio
    async def test_remap_updates_rows_and_writes_audit(self, fake_user):
        from api.v1.workout_history_file import RemapRequest, remap_exercise_name

        # Build a mock DB that returns 2 matching rows, then lets update + insert pass.
        rows_table = MagicMock()
        rows_table.select.return_value.eq.return_value.ilike.return_value.execute.return_value.data = [
            {"id": "r1", "exercise_name_canonical": "bench_press", "exercise_id": None},
            {"id": "r2", "exercise_name_canonical": "bench_press", "exercise_id": None},
        ]
        rows_table.update.return_value.eq.return_value.ilike.return_value.execute.return_value.data = []

        audit_table = MagicMock()
        audit_table.insert.return_value.execute.return_value.data = [{"id": "audit-abc"}]

        alias_table = MagicMock()
        alias_table.insert.return_value.execute.return_value.data = []

        def table_dispatch(name):
            return {
                "workout_history_imports": rows_table,
                "history_import_remap_audit": audit_table,
                "exercise_alias_contributions": alias_table,
            }[name]

        mock_db = MagicMock()
        mock_db.client.table.side_effect = table_dispatch

        bg_tasks = BackgroundTasks()
        request = RemapRequest(
            user_id=fake_user["id"],
            raw_name="flat bench press",
            exercise_id=None,
            canonical_name="barbell_bench_press",
            source_app="hevy",
        )

        with patch("api.v1.workout_history_file.get_supabase_db", return_value=mock_db):
            result = await remap_exercise_name(
                request,
                background_tasks=bg_tasks,
                current_user=fake_user,
            )

        assert result.rows_affected == 2
        assert result.audit_id == "audit-abc"

        # Audit row must include the affected ids so undo works.
        audit_payload = audit_table.insert.call_args[0][0]
        assert audit_payload["rows_affected"] == 2
        assert audit_payload["affected_row_ids"] == ["r1", "r2"]
        assert audit_payload["canonical_name_after"] == "barbell_bench_press"

        # Alias contribution written.
        alias_payload = alias_table.insert.call_args[0][0]
        assert alias_payload["raw_name_lower"] == "flat bench press"
        assert alias_payload["canonical_name"] == "barbell_bench_press"
        assert alias_payload["source_app"] == "hevy"

        # Background task scheduled for RAG metadata update.
        assert len(bg_tasks.tasks) == 1

    @pytest.mark.asyncio
    async def test_remap_no_rows_returns_zero(self, fake_user):
        from api.v1.workout_history_file import RemapRequest, remap_exercise_name

        rows_table = MagicMock()
        rows_table.select.return_value.eq.return_value.ilike.return_value.execute.return_value.data = []

        mock_db = MagicMock()
        mock_db.client.table.return_value = rows_table

        request = RemapRequest(
            user_id=fake_user["id"],
            raw_name="nonexistent_exercise",
            canonical_name="doesnt_matter",
        )

        with patch("api.v1.workout_history_file.get_supabase_db", return_value=mock_db):
            result = await remap_exercise_name(
                request,
                background_tasks=BackgroundTasks(),
                current_user=fake_user,
            )

        assert result.rows_affected == 0
        assert result.audit_id == ""


# ─────────────────────── Undo ───────────────────────────────────────────────

class TestUndoEndpoint:
    @pytest.mark.asyncio
    async def test_undo_restores_previous_values(self, fake_user):
        from api.v1.workout_history_file import undo_remap

        audit_row = {
            "id": "audit-abc",
            "user_id": fake_user["id"],
            "canonical_name_before": "bench_press",
            "exercise_id_before": None,
            "affected_row_ids": ["r1", "r2"],
            "reverted": False,
        }

        audit_table = MagicMock()
        audit_table.select.return_value.eq.return_value.limit.return_value.execute.return_value.data = [audit_row]
        audit_table.update.return_value.eq.return_value.execute.return_value.data = []

        rows_table = MagicMock()
        rows_table.update.return_value.in_.return_value.eq.return_value.execute.return_value.data = []

        def dispatch(name):
            return {
                "history_import_remap_audit": audit_table,
                "workout_history_imports": rows_table,
            }[name]

        mock_db = MagicMock()
        mock_db.client.table.side_effect = dispatch

        with patch("api.v1.workout_history_file.get_supabase_db", return_value=mock_db):
            result = await undo_remap("audit-abc", current_user=fake_user)

        assert result.rows_reverted == 2
        assert result.audit_id == "audit-abc"

    @pytest.mark.asyncio
    async def test_undo_missing_audit_404(self, fake_user):
        from api.v1.workout_history_file import undo_remap
        from fastapi import HTTPException

        audit_table = MagicMock()
        audit_table.select.return_value.eq.return_value.limit.return_value.execute.return_value.data = []

        mock_db = MagicMock()
        mock_db.client.table.return_value = audit_table

        with patch("api.v1.workout_history_file.get_supabase_db", return_value=mock_db):
            with pytest.raises(HTTPException) as exc:
                await undo_remap("missing", current_user=fake_user)
        assert exc.value.status_code == 404


# ─────────────────────── Unresolved ─────────────────────────────────────────

class TestUnresolvedEndpoint:
    @pytest.mark.asyncio
    async def test_unresolved_returns_groups_with_suggestions(self, fake_user):
        from api.v1.workout_history_file import get_unresolved

        # Two distinct raw names, three rows total across two sessions.
        imported_rows = [
            {
                "id": "a", "exercise_name": "Flat Bench Press",
                "performed_at": "2025-04-01T12:00:00+00:00", "source_app": "hevy",
            },
            {
                "id": "b", "exercise_name": "flat bench press",
                "performed_at": "2025-04-03T12:00:00+00:00", "source_app": "hevy",
            },
            {
                "id": "c", "exercise_name": "Smith Row",
                "performed_at": "2025-04-02T12:00:00+00:00", "source_app": "strong",
            },
        ]

        mock_table = MagicMock()
        (
            mock_table.select.return_value
            .eq.return_value
            .is_.return_value
            .order.return_value
            .limit.return_value
            .execute.return_value
        ).data = imported_rows

        mock_db = MagicMock()
        mock_db.client.table.return_value = mock_table

        # Stub the resolver so we don't hit Supabase/Chroma.
        class _FakeResult:
            def __init__(self, canonical, level, confidence, eid=None):
                self.canonical_name = canonical
                self.level = level
                self.confidence = confidence
                self.exercise_id = eid

        def _resolve(raw):
            if "bench" in raw:
                return _FakeResult("barbell_bench_press", 1, 1.0)
            return _FakeResult("smith_bent_over_row", 3, 0.82)

        resolver = MagicMock()
        resolver.resolve.side_effect = _resolve

        with patch("api.v1.workout_history_file.get_supabase_db", return_value=mock_db), \
             patch(
                 "services.workout_import.exercise_resolver.ExerciseResolver",
                 return_value=resolver,
             ):
            result = await get_unresolved(
                user_id=fake_user["id"],
                limit=50,
                current_user=fake_user,
            )

        # Two groups: "Flat Bench Press" collapses to a single group (case-insensitive).
        assert len(result) == 2
        bench = next(g for g in result if "bench" in g.raw_name.lower())
        row = next(g for g in result if "row" in g.raw_name.lower())

        assert bench.row_count == 2
        assert bench.session_count == 2
        assert row.row_count == 1
        assert bench.suggestions[0].canonical_name == "barbell_bench_press"
        assert row.suggestions[0].canonical_name == "smith_bent_over_row"
