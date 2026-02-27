"""
Database-backed job queue for background media analysis (form check, food analysis).

This service persists job state to Supabase so jobs survive server restarts.
If the table doesn't exist yet, it falls back to in-memory storage.
"""
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Fallback in-memory storage when database table doesn't exist
_memory_jobs: Dict[str, Dict[str, Any]] = {}

# Track if we've checked for the table
_table_available: Optional[bool] = None


def _check_table_exists() -> bool:
    """Check if the media_analysis_jobs table exists."""
    global _table_available

    if _table_available is not None:
        return _table_available

    try:
        db = get_supabase_db()
        db.client.table("media_analysis_jobs").select("id").limit(1).execute()
        _table_available = True
        logger.info("media_analysis_jobs table is available")
    except Exception as e:
        if "PGRST205" in str(e) or "Could not find" in str(e):
            _table_available = False
            logger.warning("media_analysis_jobs table not found - using in-memory fallback")
            logger.warning("Run migrations/264_media_analysis_jobs.sql to enable persistence")
        else:
            _table_available = False
            logger.error(f"Error checking media_analysis_jobs table: {e}")

    return _table_available


class MediaJobService:
    """Service for managing background media analysis jobs."""

    def __init__(self):
        self.use_db = _check_table_exists()

    def _check_form_analysis_gate(self, user_id: str):
        """Check premium gate for form video analysis (sync wrapper).

        Raises HTTPException(402) if the free-tier limit is exhausted.
        """
        import asyncio
        from core.premium_gate import check_premium_gate

        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                # We're inside an already-running event loop (LangGraph tool context).
                # Use a thread to run the coroutine to avoid "cannot be called from a running event loop".
                import concurrent.futures
                with concurrent.futures.ThreadPoolExecutor() as pool:
                    future = pool.submit(asyncio.run, check_premium_gate(user_id, "form_video_analysis"))
                    future.result(timeout=10)
            else:
                loop.run_until_complete(check_premium_gate(user_id, "form_video_analysis"))
        except RuntimeError:
            asyncio.run(check_premium_gate(user_id, "form_video_analysis"))

    def track_form_analysis_usage(self, user_id: str):
        """Track form video analysis usage after successful completion (sync wrapper)."""
        import asyncio
        from core.premium_gate import track_premium_usage

        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                import concurrent.futures
                with concurrent.futures.ThreadPoolExecutor() as pool:
                    future = pool.submit(asyncio.run, track_premium_usage(user_id, "form_video_analysis"))
                    future.result(timeout=10)
            else:
                loop.run_until_complete(track_premium_usage(user_id, "form_video_analysis"))
        except Exception as e:
            logger.warning(f"Failed to track form_video_analysis usage: {e}")

    def create_job(
        self,
        user_id: str,
        job_type: str,
        s3_keys: List[str],
        mime_types: List[str],
        media_types: List[str],
        params: Optional[Dict[str, Any]] = None,
    ) -> str:
        """Create a new media analysis job. Returns job_id.

        Args:
            user_id: The user who initiated the job.
            job_type: One of 'form_analysis', 'form_comparison', 'food_analysis'.
            s3_keys: List of S3 object keys for uploaded media.
            mime_types: List of MIME types corresponding to s3_keys.
            media_types: List of media types ('image' or 'video') corresponding to s3_keys.
            params: Optional dict with extra parameters (exercise_name, user_context, labels, etc.).

        Returns:
            The newly created job ID.

        Raises:
            HTTPException(402) if the user has exhausted their free-tier form analysis limit.
        """
        # Premium gate check for form video analysis
        if job_type in ("form_analysis", "form_comparison"):
            self._check_form_analysis_gate(user_id)

        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("media_analysis_jobs").insert({
                    "user_id": user_id,
                    "job_type": job_type,
                    "status": "pending",
                    "s3_keys": s3_keys,
                    "mime_types": mime_types,
                    "media_types": media_types,
                    "params": params or {},
                }).execute()

                job_id = result.data[0]["id"]
                logger.info(f"Created media job {job_id} ({job_type}) for user {user_id}")
                return job_id
            except Exception as e:
                logger.error(f"Failed to create media job in DB: {e}")
                # Fall through to memory storage

        # In-memory fallback
        import uuid
        job_id = str(uuid.uuid4())
        _memory_jobs[job_id] = {
            "id": job_id,
            "user_id": user_id,
            "job_type": job_type,
            "status": "pending",
            "s3_keys": s3_keys,
            "mime_types": mime_types,
            "media_types": media_types,
            "params": params or {},
            "result": None,
            "error_message": None,
            "retry_count": 0,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "started_at": None,
            "completed_at": None,
        }
        return job_id

    def get_job(self, job_id: str) -> Optional[Dict[str, Any]]:
        """Get job by ID."""
        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("media_analysis_jobs").select("*").eq("id", job_id).limit(1).execute()
                return result.data[0] if result.data else None
            except Exception as e:
                logger.error(f"Failed to get media job from DB: {e}")

        return _memory_jobs.get(job_id)

    def update_job_status(
        self,
        job_id: str,
        status: str,
        result: Optional[Dict[str, Any]] = None,
        error_message: Optional[str] = None,
        retry_count: Optional[int] = None,
    ):
        """Update job status.

        Args:
            job_id: The job to update.
            status: One of 'pending', 'in_progress', 'completed', 'failed', 'cancelled'.
            result: Optional result dict (set on completion).
            error_message: Optional error message (set on failure).
            retry_count: Optional updated retry count.
        """
        update_data: Dict[str, Any] = {
            "status": status,
            "updated_at": datetime.now().isoformat(),
        }

        if result is not None:
            update_data["result"] = result

        if error_message is not None:
            update_data["error_message"] = error_message

        if retry_count is not None:
            update_data["retry_count"] = retry_count

        if status == "in_progress":
            update_data["started_at"] = datetime.now().isoformat()
        elif status in ("completed", "failed"):
            update_data["completed_at"] = datetime.now().isoformat()

        if self.use_db:
            try:
                db = get_supabase_db()
                db.client.table("media_analysis_jobs")\
                    .update(update_data)\
                    .eq("id", job_id)\
                    .execute()
                logger.info(f"Updated media job {job_id} status to {status}")
                return
            except Exception as e:
                logger.error(f"Failed to update media job in DB: {e}")

        # In-memory fallback
        if job_id in _memory_jobs:
            _memory_jobs[job_id].update(update_data)

    def get_pending_jobs(self) -> List[Dict[str, Any]]:
        """Get all pending/in_progress jobs (for recovery on server startup)."""
        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("media_analysis_jobs")\
                    .select("*")\
                    .in_("status", ["pending", "in_progress"])\
                    .order("created_at")\
                    .execute()
                return result.data if result.data else []
            except Exception as e:
                logger.error(f"Failed to get pending media jobs from DB: {e}")

        # In-memory fallback
        return [j for j in _memory_jobs.values() if j["status"] in ("pending", "in_progress")]

    def cancel_stale_jobs(self, older_than_hours: int = 2):
        """Cancel jobs that have been pending/in_progress for too long."""
        if self.use_db:
            try:
                cutoff = (datetime.now() - timedelta(hours=older_than_hours)).isoformat()

                db = get_supabase_db()
                result = db.client.table("media_analysis_jobs")\
                    .update({
                        "status": "cancelled",
                        "error_message": "Job timed out",
                        "updated_at": datetime.now().isoformat(),
                    })\
                    .in_("status", ["pending", "in_progress"])\
                    .lt("created_at", cutoff)\
                    .execute()

                if result.data:
                    logger.info(f"Cancelled {len(result.data)} stale media jobs")
            except Exception as e:
                logger.error(f"Failed to cancel stale media jobs: {e}")
        else:
            # In-memory fallback
            cutoff_dt = datetime.now() - timedelta(hours=older_than_hours)
            for job in _memory_jobs.values():
                if job["status"] in ("pending", "in_progress"):
                    created = datetime.fromisoformat(job["created_at"])
                    if created < cutoff_dt:
                        job["status"] = "cancelled"
                        job["error_message"] = "Job timed out"
                        job["updated_at"] = datetime.now().isoformat()

    def get_user_active_jobs(self, user_id: str) -> List[Dict[str, Any]]:
        """Get a user's active (pending/in_progress) jobs. For concurrent limit checks."""
        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("media_analysis_jobs")\
                    .select("*")\
                    .eq("user_id", user_id)\
                    .in_("status", ["pending", "in_progress"])\
                    .order("created_at", desc=True)\
                    .execute()
                return result.data if result.data else []
            except Exception as e:
                logger.error(f"Failed to get active media jobs from DB: {e}")

        # In-memory fallback
        return [
            j for j in _memory_jobs.values()
            if j["user_id"] == user_id and j["status"] in ("pending", "in_progress")
        ]


# Singleton instance
_media_job_service: Optional[MediaJobService] = None


def get_media_job_service() -> MediaJobService:
    """Get the singleton media job service instance."""
    global _media_job_service
    if _media_job_service is None:
        _media_job_service = MediaJobService()
    return _media_job_service
