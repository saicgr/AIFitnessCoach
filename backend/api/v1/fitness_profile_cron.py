"""
Daily snapshotter for fitness_profile_snapshots.

Call pattern (external scheduler — e.g. Render Cron, UptimeRobot, GitHub Actions):
    POST /api/v1/cron/snapshot-fitness-profiles
    X-Cron-Secret: <value of CRON_SECRET env var>

Captures the 6-axis shape for every user who had any workout or food log in
the last 14 days. Upserts on (user_id, snapshot_date) so re-runs for the
same day are idempotent.
"""
import hmac
from typing import Optional

from fastapi import APIRouter, Header, HTTPException, Request

from core.config import get_settings
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.logger import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/cron", tags=["cron"])


def _verify_cron_secret(request: Request, x_cron_secret: Optional[str]):
    """Same pattern as push_nudge_cron._verify_cron_secret."""
    settings = get_settings()
    cron_secret = settings.cron_secret
    if not cron_secret:
        raise HTTPException(
            status_code=503,
            detail="Cron not configured — set CRON_SECRET env var",
        )
    if not x_cron_secret or not hmac.compare_digest(x_cron_secret, cron_secret):
        logger.warning("Fitness snapshot cron called with invalid secret")
        raise HTTPException(status_code=401, detail="Invalid cron secret")

    allowed_ips_str = settings.cron_allowed_ips
    if allowed_ips_str:
        allowed = [ip.strip() for ip in allowed_ips_str.split(",") if ip.strip()]
        forwarded_for = request.headers.get("X-Forwarded-For")
        client_ip = (
            forwarded_for.split(",")[0].strip()
            if forwarded_for
            else (request.client.host if request.client else None)
        )
        if not client_ip or client_ip not in allowed:
            logger.warning(f"Snapshot cron called from disallowed IP: {client_ip}")
            raise HTTPException(status_code=403, detail="IP not allowed")


@router.post("/snapshot-fitness-profiles")
async def snapshot_fitness_profiles(
    request: Request,
    x_cron_secret: Optional[str] = Header(None, alias="X-Cron-Secret"),
):
    """
    Snapshot today's fitness profile for every active user.
    Idempotent — safe to run multiple times per day.
    """
    _verify_cron_secret(request, x_cron_secret)

    try:
        db = get_supabase_db()
        res = db.client.rpc("snapshot_all_active_fitness_profiles", {}).execute()
        count = res.data if isinstance(res.data, int) else (res.data or 0)
        logger.info(f"✅ Fitness profile snapshots: {count} rows")
        return {"snapshot_count": count}
    except Exception as e:
        raise safe_internal_error(e, "cron.snapshot-fitness-profiles")
