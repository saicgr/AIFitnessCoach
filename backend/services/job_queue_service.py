"""
Database-backed job queue for reliable background workout generation.

This service persists job state to Supabase so jobs survive server restarts.
If the table doesn't exist yet, it falls back to in-memory storage.
"""
from typing import Optional, List, Dict, Any
from datetime import datetime
from core.supabase_db import get_supabase_db
from core.logger import get_logger

logger = get_logger(__name__)

# Fallback in-memory storage when database table doesn't exist
_memory_jobs: Dict[str, Dict[str, Any]] = {}

# Track if we've checked for the table
_table_available: Optional[bool] = None


def _check_table_exists() -> bool:
    """Check if the workout_generation_jobs table exists."""
    global _table_available

    if _table_available is not None:
        return _table_available

    try:
        db = get_supabase_db()
        # Try to query the table
        db.client.table("workout_generation_jobs").select("id").limit(1).execute()
        _table_available = True
        logger.info("✅ workout_generation_jobs table is available")
    except Exception as e:
        if "PGRST205" in str(e) or "Could not find" in str(e):
            _table_available = False
            logger.warning("⚠️ workout_generation_jobs table not found - using in-memory fallback")
            logger.warning("Run migrations/003_workout_generation_jobs.sql to enable persistence")
        else:
            _table_available = False
            logger.error(f"Error checking table: {e}")

    return _table_available


class JobQueueService:
    """Service for managing background workout generation jobs."""

    def __init__(self):
        self.use_db = _check_table_exists()

    def create_job(
        self,
        user_id: str,
        month_start_date: str,
        duration_minutes: int,
        selected_days: List[int],
        weeks: int
    ) -> str:
        """Create a new generation job. Returns job ID."""
        total_expected = weeks * len(selected_days)

        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("workout_generation_jobs").insert({
                    "user_id": user_id,
                    "status": "pending",
                    "month_start_date": month_start_date,
                    "duration_minutes": duration_minutes,
                    "selected_days": selected_days,
                    "weeks": weeks,
                    "total_expected": total_expected,
                    "total_generated": 0
                }).execute()

                job_id = result.data[0]["id"]
                logger.info(f"📝 Created job {job_id} for user {user_id}")
                return job_id
            except Exception as e:
                logger.error(f"Failed to create job in DB: {e}")
                # Fall through to memory storage

        # In-memory fallback
        import uuid
        job_id = str(uuid.uuid4())
        _memory_jobs[job_id] = {
            "id": job_id,
            "user_id": user_id,
            "status": "pending",
            "month_start_date": month_start_date,
            "duration_minutes": duration_minutes,
            "selected_days": selected_days,
            "weeks": weeks,
            "total_expected": total_expected,
            "total_generated": 0,
            "error_message": None,
            "created_at": datetime.now().isoformat()
        }
        return job_id

    def get_job(self, job_id: str) -> Optional[Dict[str, Any]]:
        """Get job by ID."""
        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("workout_generation_jobs").select("*").eq("id", job_id).limit(1).execute()
                return result.data[0] if result.data else None
            except Exception as e:
                logger.error(f"Failed to get job from DB: {e}")

        return _memory_jobs.get(job_id)

    def get_user_pending_job(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get the latest pending or in-progress job for a user."""
        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("workout_generation_jobs")\
                    .select("*")\
                    .eq("user_id", user_id)\
                    .in_("status", ["pending", "in_progress"])\
                    .order("created_at", desc=True)\
                    .limit(1)\
                    .execute()
                return result.data[0] if result.data else None
            except Exception as e:
                logger.error(f"Failed to get pending job from DB: {e}")

        # In-memory fallback
        user_jobs = [j for j in _memory_jobs.values()
                     if j["user_id"] == user_id and j["status"] in ["pending", "in_progress"]]
        return user_jobs[-1] if user_jobs else None

    def get_latest_job_for_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get the most recent job for a user (any status)."""
        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("workout_generation_jobs")\
                    .select("*")\
                    .eq("user_id", user_id)\
                    .order("created_at", desc=True)\
                    .limit(1)\
                    .execute()
                return result.data[0] if result.data else None
            except Exception as e:
                logger.error(f"Failed to get latest job from DB: {e}")

        # In-memory fallback
        user_jobs = [j for j in _memory_jobs.values() if j["user_id"] == user_id]
        return user_jobs[-1] if user_jobs else None

    def update_job_status(
        self,
        job_id: str,
        status: str,
        total_generated: Optional[int] = None,
        error_message: Optional[str] = None
    ):
        """Update job status."""
        update_data = {
            "status": status,
            "updated_at": datetime.now().isoformat()
        }

        if total_generated is not None:
            update_data["total_generated"] = total_generated

        if error_message is not None:
            update_data["error_message"] = error_message

        if status == "in_progress":
            update_data["started_at"] = datetime.now().isoformat()
        elif status in ["completed", "failed"]:
            update_data["completed_at"] = datetime.now().isoformat()

        if self.use_db:
            try:
                db = get_supabase_db()
                db.client.table("workout_generation_jobs")\
                    .update(update_data)\
                    .eq("id", job_id)\
                    .execute()
                logger.info(f"📝 Updated job {job_id} status to {status}")
                return
            except Exception as e:
                logger.error(f"Failed to update job in DB: {e}")

        # In-memory fallback
        if job_id in _memory_jobs:
            _memory_jobs[job_id].update(update_data)

    def get_pending_jobs(self) -> List[Dict[str, Any]]:
        """Get all pending jobs (for recovery on server startup)."""
        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("workout_generation_jobs")\
                    .select("*")\
                    .in_("status", ["pending", "in_progress"])\
                    .order("created_at")\
                    .execute()
                return result.data if result.data else []
            except Exception as e:
                logger.error(f"Failed to get pending jobs from DB: {e}")

        # In-memory fallback
        return [j for j in _memory_jobs.values() if j["status"] in ["pending", "in_progress"]]

    def cancel_stale_jobs(self, older_than_hours: int = 24):
        """Cancel jobs that have been pending/in_progress for too long."""
        if self.use_db:
            try:
                from datetime import timedelta
                cutoff = (datetime.now() - timedelta(hours=older_than_hours)).isoformat()

                db = get_supabase_db()
                result = db.client.table("workout_generation_jobs")\
                    .update({"status": "cancelled", "error_message": "Job timed out", "updated_at": datetime.now().isoformat()})\
                    .in_("status", ["pending", "in_progress"])\
                    .lt("created_at", cutoff)\
                    .execute()

                if result.data:
                    logger.info(f"🧹 Cancelled {len(result.data)} stale jobs")
            except Exception as e:
                logger.error(f"Failed to cancel stale jobs: {e}")

    def get_recent_job(self, user_id: str, within_seconds: int = 60) -> Optional[Dict[str, Any]]:
        """
        Get a recent job for the user within the specified time window.

        This is used to implement generation cooldown - prevents excessive
        retry attempts by checking if generation was recently attempted.

        Args:
            user_id: User ID
            within_seconds: Time window to check (default 60 seconds)

        Returns:
            Recent job dict if found, None otherwise
        """
        from datetime import timedelta

        cutoff = (datetime.now() - timedelta(seconds=within_seconds)).isoformat()

        if self.use_db:
            try:
                db = get_supabase_db()
                result = db.client.table("workout_generation_jobs")\
                    .select("*")\
                    .eq("user_id", user_id)\
                    .gte("created_at", cutoff)\
                    .order("created_at", desc=True)\
                    .limit(1)\
                    .execute()

                if result.data:
                    job = result.data[0]
                    logger.debug(f"Found recent job {job.get('id')} for user {user_id} (status={job.get('status')})")
                    return job
                return None
            except Exception as e:
                logger.error(f"Failed to get recent job from DB: {e}")

        # In-memory fallback
        cutoff_dt = datetime.now() - timedelta(seconds=within_seconds)
        user_jobs = [
            j for j in _memory_jobs.values()
            if j["user_id"] == user_id and
            datetime.fromisoformat(j["created_at"]) >= cutoff_dt
        ]
        return user_jobs[-1] if user_jobs else None


# Singleton instance
_job_queue_service: Optional[JobQueueService] = None


def get_job_queue_service() -> JobQueueService:
    """Get the singleton job queue service instance."""
    global _job_queue_service
    if _job_queue_service is None:
        _job_queue_service = JobQueueService()
    return _job_queue_service
