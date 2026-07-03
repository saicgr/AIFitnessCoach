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


@router.get("/metrics/nudges", tags=["Admin"])
async def admin_nudge_metrics(
    request: Request,
    days: int = Query(
        14, ge=1, le=90,
        description="Lookback window in days for the nudge send/open report.",
    ),
) -> dict:
    """Proactive-coach engagement report from push_nudge_log.

    Per day × nudge_type: sent / opened / open rate, plus proactive-message
    reply counts from chat_history. Guarded by X-Cron-Secret like /metrics.

        curl -H "X-Cron-Secret: $CRON_SECRET" \\
             https://<host>/api/v1/admin/metrics/nudges?days=14
    """
    _verify_metrics_secret(request)

    from datetime import date, timedelta

    supabase = get_supabase()
    cutoff = (date.today() - timedelta(days=days)).isoformat()

    # push_nudge_log is small (per-user daily caps); a windowed scan is cheap.
    rows = (
        supabase.client.table("push_nudge_log")
        .select("nudge_type, nudge_date, opened_at, tone")
        .gte("nudge_date", cutoff)
        .limit(50000)
        .execute()
    ).data or []

    by_day: dict = {}
    by_type: dict = {}
    by_tone: dict = {}
    for r in rows:
        day = r.get("nudge_date")
        ntype = r.get("nudge_type") or "unknown"
        opened = 1 if r.get("opened_at") else 0
        day_bucket = by_day.setdefault(day, {})
        cell = day_bucket.setdefault(ntype, {"sent": 0, "opened": 0})
        cell["sent"] += 1
        cell["opened"] += opened
        tcell = by_type.setdefault(ntype, {"sent": 0, "opened": 0})
        tcell["sent"] += 1
        tcell["opened"] += opened
        tone = r.get("tone")
        if tone:
            ncell = by_tone.setdefault(tone, {"sent": 0, "opened": 0})
            ncell["sent"] += 1
            ncell["opened"] += opened

    def _with_rate(d: dict) -> dict:
        return {
            k: {**v, "open_rate": round(v["opened"] / v["sent"], 4) if v["sent"] else 0.0}
            for k, v in sorted(d.items(), key=lambda kv: kv[1]["sent"], reverse=True)
        }

    # Replies to proactive coach messages: user turns that landed after a
    # proactive mirror in the same window (coarse but cron-cheap).
    try:
        proactive = (
            supabase.client.table("chat_history")
            .select("id", count="exact")
            .eq("context_json->>proactive", "true")
            .gte("timestamp", cutoff)
            .execute()
        )
        proactive_count = proactive.count or 0
    except Exception as e:
        logger.warning(f"admin_nudge_metrics: proactive count failed: {e}")
        proactive_count = None

    total_sent = sum(v["sent"] for v in by_type.values())
    total_opened = sum(v["opened"] for v in by_type.values())
    return {
        "window_days": days,
        "total_sent": total_sent,
        "total_opened": total_opened,
        "overall_open_rate": round(total_opened / total_sent, 4) if total_sent else 0.0,
        "proactive_chat_messages": proactive_count,
        "by_type": _with_rate(by_type),
        "by_tone": _with_rate(by_tone),
        "by_day": {d: _with_rate(t) for d, t in sorted(by_day.items(), reverse=True)},
    }
