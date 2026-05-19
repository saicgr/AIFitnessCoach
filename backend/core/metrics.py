"""
In-process backend observability metrics (Phase D4).

Why in-process and not prometheus-client / prometheus-fastapi-instrumentator:
  * No new dependency on the 512MB Render tier (OOM-sensitive).
  * The data we need — per-route latency percentiles, DB pool pressure, cache
    hit-rate — is cheap to keep in a few bounded in-memory structures.
  * The hot path stays allocation-light: one append to a fixed-size deque +
    two integer increments per request. No disk, no network, no blocking.

What this module owns:
  * RouteMetrics — a bounded latency reservoir per route TEMPLATE, computing
    p50/p95/p99 + request count + error count on demand.
  * Module-level counters consumed by the admin metrics snapshot.

Percentiles are computed from a bounded ring buffer (the most-recent N samples
per route). This is a sliding-window estimate, not an all-time exact figure —
which is exactly what you want for "is the backend healthy right now" before /
during / after a load test. The buffer is small enough that a full sort on the
read path (admin endpoint, called rarely) is negligible.
"""
from __future__ import annotations

import threading
import time
from collections import deque
from typing import Dict, List, Optional


# Most-recent latency samples kept per route. 2048 samples is enough for a
# stable p99 estimate while bounding memory to ~16KB/route (8 bytes/float).
_MAX_SAMPLES_PER_ROUTE = 2048

# Hard cap on the number of distinct route labels tracked. Route labels are
# path TEMPLATES (e.g. /api/v1/home/bootstrap), so the cardinality is bounded
# by the number of registered routes — but this guards against an unexpected
# explosion (e.g. a 404-storm against random paths labelled "<unmatched>").
_MAX_ROUTES = 500


class _RouteStat:
    """Latency reservoir + counters for a single route template."""

    __slots__ = ("samples", "count", "errors", "_lock")

    def __init__(self) -> None:
        # deque(maxlen=N) drops the oldest sample on overflow in O(1) — a
        # natural sliding window with no manual trimming.
        self.samples: deque[float] = deque(maxlen=_MAX_SAMPLES_PER_ROUTE)
        self.count: int = 0          # all-time request count for this route
        self.errors: int = 0         # all-time 5xx count for this route
        self._lock = threading.Lock()

    def record(self, duration_ms: float, status_code: int) -> None:
        with self._lock:
            self.samples.append(duration_ms)
            self.count += 1
            if status_code >= 500:
                self.errors += 1

    def snapshot(self) -> dict:
        """Compute percentiles from the current window. Read-path only."""
        with self._lock:
            sample_list = list(self.samples)
            count = self.count
            errors = self.errors
        if not sample_list:
            return {
                "count": count,
                "errors": errors,
                "error_rate": 0.0,
                "p50_ms": 0.0,
                "p95_ms": 0.0,
                "p99_ms": 0.0,
                "max_ms": 0.0,
                "window_samples": 0,
            }
        sample_list.sort()
        return {
            "count": count,
            "errors": errors,
            "error_rate": round(errors / count, 4) if count else 0.0,
            "p50_ms": round(_percentile(sample_list, 0.50), 1),
            "p95_ms": round(_percentile(sample_list, 0.95), 1),
            "p99_ms": round(_percentile(sample_list, 0.99), 1),
            "max_ms": round(sample_list[-1], 1),
            "window_samples": len(sample_list),
        }


def _percentile(sorted_samples: List[float], q: float) -> float:
    """Nearest-rank percentile of an already-sorted list (q in [0, 1])."""
    if not sorted_samples:
        return 0.0
    # Nearest-rank: rank = ceil(q * N), clamped to [1, N], then 0-indexed.
    n = len(sorted_samples)
    idx = max(0, min(n - 1, int(round(q * n + 0.5)) - 1))
    return sorted_samples[idx]


class RequestMetricsRegistry:
    """Thread-safe registry of per-route latency stats.

    A single module-level instance (`request_metrics`) is shared across the
    whole process. Recording is O(1); reading sorts each route's window once.
    """

    def __init__(self) -> None:
        self._routes: Dict[str, _RouteStat] = {}
        self._lock = threading.Lock()
        self._dropped_routes = 0          # routes skipped after _MAX_ROUTES
        self.started_at = time.time()

    def record(self, route_label: str, duration_ms: float, status_code: int) -> None:
        """Record one completed request. Called from the hot path."""
        stat = self._routes.get(route_label)
        if stat is None:
            with self._lock:
                # Re-check inside the lock (another thread may have created it).
                stat = self._routes.get(route_label)
                if stat is None:
                    if len(self._routes) >= _MAX_ROUTES:
                        self._dropped_routes += 1
                        return
                    stat = _RouteStat()
                    self._routes[route_label] = stat
        stat.record(duration_ms, status_code)

    def snapshot(self, top_n: Optional[int] = None) -> dict:
        """Build a JSON-friendly snapshot of all tracked routes.

        Routes are sorted by request count (busiest first) so `top_n` keeps
        the most-trafficked endpoints — the ones that matter for a load test.
        """
        with self._lock:
            items = list(self._routes.items())
            dropped = self._dropped_routes
        per_route = {label: stat.snapshot() for label, stat in items}
        ordered = sorted(
            per_route.items(), key=lambda kv: kv[1]["count"], reverse=True
        )
        if top_n is not None:
            ordered = ordered[:top_n]
        total_requests = sum(s["count"] for s in per_route.values())
        total_errors = sum(s["errors"] for s in per_route.values())
        return {
            "uptime_seconds": round(time.time() - self.started_at, 1),
            "total_requests": total_requests,
            "total_errors": total_errors,
            "overall_error_rate": (
                round(total_errors / total_requests, 4) if total_requests else 0.0
            ),
            "routes_tracked": len(per_route),
            "routes_dropped": dropped,
            "routes": dict(ordered),
        }


# Process-wide singletons. Imported by main.py (middleware) and the admin
# observability endpoint.
request_metrics = RequestMetricsRegistry()


def get_request_metrics() -> RequestMetricsRegistry:
    """Accessor for the process-wide request metrics registry."""
    return request_metrics
