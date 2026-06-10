"""Before/after perf probe for the app-wide performance fix (2026-06).

Measures, against a locally running backend (same Supabase DB as prod):
  1. p50/p95 latency of GET /api/v1/stats/overview/{uid} and /stats/quick/{uid}
  2. Event-loop stall: /health latency WHILE /stats/overview is in flight.
     A healthy (non-blocking) server answers /health in <50ms; a server whose
     event loop is blocked by sequential sync .execute() calls answers only
     after the stats request finishes.
  3. POST /api/v1/nutrition/log-text wall time (3 runs, same description so
     Gemini fires at most once and the cache-hit path — still doing RAG +
     personal-history — dominates). Created logs are deleted afterwards.

Usage:
  .venv/bin/python scripts/perf_probe.py --base http://127.0.0.1:8765 \
      --label baseline --out ../docs/planning/perf-2026-06/baseline.json

Run BEFORE any change (baseline) and after each backend phase with a new
--label/--out. JSON outputs are directly diffable; the stats overview body is
embedded for a same-data regression check.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import os
import statistics
import sys
import time
from pathlib import Path

import httpx
from dotenv import load_dotenv

BACKEND = Path(__file__).resolve().parent.parent
load_dotenv(BACKEND / ".env")

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]
QA_EMAIL = "reviewer@fitwiz.us"
QA_PASSWORD = "FitWiz2026!"
USER_ID = "d54e6652-fdf1-4ca0-82d1-23d7c02df294"

LOG_TEXT_DESCRIPTION = "2 eggs and toast with butter"


def get_jwt() -> str:
    r = httpx.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": SUPABASE_KEY, "Content-Type": "application/json"},
        json={"email": QA_EMAIL, "password": QA_PASSWORD},
        timeout=15,
    )
    r.raise_for_status()
    return r.json()["access_token"]


def pct(values: list[float], p: float) -> float:
    if not values:
        return 0.0
    s = sorted(values)
    k = min(len(s) - 1, max(0, round(p / 100 * (len(s) - 1))))
    return s[k]


def summarize(ms: list[float]) -> dict:
    return {
        "n": len(ms),
        "p50_ms": round(statistics.median(ms), 1) if ms else None,
        "p95_ms": round(pct(ms, 95), 1) if ms else None,
        "min_ms": round(min(ms), 1) if ms else None,
        "max_ms": round(max(ms), 1) if ms else None,
        "raw_ms": [round(m, 1) for m in ms],
    }


async def timed_get(client: httpx.AsyncClient, url: str, **kw) -> tuple[float, httpx.Response]:
    t0 = time.perf_counter()
    resp = await client.get(url, **kw)
    return (time.perf_counter() - t0) * 1000, resp


async def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://127.0.0.1:8765")
    ap.add_argument("--label", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--iters", type=int, default=10)
    ap.add_argument("--skip-logtext", action="store_true")
    args = ap.parse_args()

    jwt = get_jwt()
    headers = {"Authorization": f"Bearer {jwt}"}
    results: dict = {"label": args.label, "base": args.base, "user_id": USER_ID,
                     "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S")}

    async with httpx.AsyncClient(base_url=args.base, headers=headers, timeout=60) as client:
        # Warmup (token cache, connection, any first-hit caches) — excluded.
        await client.get("/health")
        warm = await client.get(f"/api/v1/stats/overview/{USER_ID}")
        warm.raise_for_status()

        # 1) Sequential latency: stats overview + quick.
        for name, path in [
            ("stats_overview", f"/api/v1/stats/overview/{USER_ID}"),
            ("stats_quick", f"/api/v1/stats/quick/{USER_ID}"),
        ]:
            ms: list[float] = []
            body = None
            for _ in range(args.iters):
                t, resp = await timed_get(client, path)
                resp.raise_for_status()
                body = resp.json()
                ms.append(t)
            results[name] = summarize(ms)
            if name == "stats_overview":
                results["stats_overview_body"] = body  # regression diff anchor

        # 2) Event-loop stall: /health while /stats/overview is in flight.
        stall_health_ms: list[float] = []

        async def overview_task():
            await client.get(f"/api/v1/stats/overview/{USER_ID}")

        for _ in range(3):
            task = asyncio.create_task(overview_task())
            await asyncio.sleep(0.05)  # let the stats request reach the server
            for _ in range(3):
                t, resp = await timed_get(client, "/health")
                resp.raise_for_status()
                stall_health_ms.append(t)
                await asyncio.sleep(0.05)
            await task
        results["health_during_stats"] = summarize(stall_health_ms)

        # Control: /health latency with an idle server.
        idle_ms = []
        for _ in range(5):
            t, resp = await timed_get(client, "/health")
            resp.raise_for_status()
            idle_ms.append(t)
        results["health_idle"] = summarize(idle_ms)

        # 3) /log-text wall time (3 runs, cleanup after).
        if not args.skip_logtext:
            lt_ms: list[float] = []
            created: list[str] = []
            for _ in range(3):
                t0 = time.perf_counter()
                resp = await client.post(
                    "/api/v1/nutrition/log-text",
                    json={
                        "user_id": USER_ID,
                        "description": LOG_TEXT_DESCRIPTION,
                        "meal_type": "snack",
                    },
                )
                lt_ms.append((time.perf_counter() - t0) * 1000)
                resp.raise_for_status()
                data = resp.json()
                log_id = (data.get("food_log") or {}).get("id") or data.get("log_id")
                if log_id:
                    created.append(log_id)
                await asyncio.sleep(1)
            results["log_text"] = summarize(lt_ms)
            results["log_text_cleanup"] = []
            for log_id in created:
                d = await client.delete(f"/api/v1/nutrition/food-logs/{log_id}")
                results["log_text_cleanup"].append({"id": log_id, "status": d.status_code})

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(results, indent=2))

    print(f"\n=== perf probe [{args.label}] ===")
    for key in ("stats_overview", "stats_quick", "health_during_stats", "health_idle", "log_text"):
        if key in results:
            s = results[key]
            print(f"{key:22s} p50={s['p50_ms']}ms p95={s['p95_ms']}ms max={s['max_ms']}ms")
    print(f"saved → {out}")


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
