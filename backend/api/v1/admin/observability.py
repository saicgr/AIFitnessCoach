"""
Backend observability snapshot — Phase D4.

Surfaces backend health so the team can SEE it before / during / after the
Phase C load test and in production:
  * per-endpoint latency percentiles (p50/p95/p99) + request count + error rate
  * SQLAlchemy connection-pool pressure (size / checked-out / overflow / util)
  * RedisCache hit/miss counts + hit-rate, per cache prefix

Security
--------
This is internal operational data (route names, traffic volume, DB pressure) —
not a public surface. It is gated by the existing X-Cron-Secret shared secret
(settings.cron_secret), the same mechanism the cron endpoints use. There is no
unauthenticated Prometheus `/metrics` endpoint: we did not add the Prometheus
client dependency, so the only exposure is this guarded JSON snapshot.

The endpoint is cheap and non-blocking: it reads in-memory counters only — no
DB query, no Redis round-trip, no disk.
"""
import hmac
from typing import Optional

from fastapi import APIRouter, HTTPException, Query, Request

from core.config import get_settings
from core.logger import get_logger
from core.metrics import get_request_metrics
from core.redis_cache import all_cache_stats
from core.supabase_client import get_supabase

router = APIRouter()
logger = get_logger(__name__)


def _verify_metrics_secret(request: Request) -> None:
    """Raise 401/503 unless the request carries the correct X-Cron-Secret.

    Reuses the cron shared secret so no new env var is needed. hmac.compare_digest
    keeps the comparison constant-time.
    """
    settings = get_settings()
    secret = settings.cron_secret
    if not secret:
        raise HTTPException(
            status_code=503,
            detail="Metrics endpoint not configured — set CRON_SECRET env var",
        )
    provided = request.headers.get("X-Cron-Secret")
    if not provided or not hmac.compare_digest(provided, secret):
        logger.warning("Admin metrics endpoint called with missing/invalid secret")
        raise HTTPException(status_code=401, detail="Invalid metrics secret")


@router.get("/metrics", tags=["Admin"])
async def admin_metrics(
    request: Request,
    top: int = Query(
        25, ge=1, le=200,
        description="Number of busiest routes to include in the latency table.",
    ),
) -> dict:
    """Human-readable JSON snapshot of backend health.

    Guarded by the X-Cron-Secret header. Example:

        curl -H "X-Cron-Secret: $CRON_SECRET" \\
             https://<host>/api/v1/admin/metrics?top=25

    Returns:
        {
          "requests": { per-route p50/p95/p99 + counts + error rate },
          "db_pool":  { size / checked_out / overflow / utilization },
          "caches":   [ per RedisCache prefix: hits / misses / hit_rate ]
        }
    """
    _verify_metrics_secret(request)

    # ── Per-endpoint request latency percentiles ──
    requests_snapshot = get_request_metrics().snapshot(top_n=top)

    # ── DB connection-pool pressure ──
    try:
        db_pool = get_supabase().pool_stats()
    except Exception as e:
        logger.warning(f"admin_metrics: pool_stats failed: {e}")
        db_pool = {"error": "pool stats unavailable"}

    # ── Cache hit-rate (every live RedisCache instance) ──
    try:
        caches = all_cache_stats()
        cache_lookups = sum(c.get("lookups", 0) for c in caches)
        cache_hits = sum(c.get("hits", 0) for c in caches)
        cache_summary = {
            "total_lookups": cache_lookups,
            "total_hits": cache_hits,
            "overall_hit_rate": (
                round(cache_hits / cache_lookups, 4) if cache_lookups else 0.0
            ),
            "by_prefix": sorted(caches, key=lambda c: c.get("lookups", 0), reverse=True),
        }
    except Exception as e:
        logger.warning(f"admin_metrics: cache stats failed: {e}")
        cache_summary = {"error": "cache stats unavailable"}

    return {
        "requests": requests_snapshot,
        "db_pool": db_pool,
        "caches": cache_summary,
    }
