"""Phase-2 food-scan latency benchmark — REAL images.

Hits the locally-running backend on port 9876 with the QA reviewer JWT and
times every image in scripts/benchmarks/images/ end-to-end (HTTP request →
SSE `event: done` or `event: error`). For each image we report wall time,
final SSE event, and any cache_source / error_code surfaced in the payload.

Usage:
    cd backend
    SKIP_INFLAMMATION_PREWARM=1 .venv/bin/python -m uvicorn main:app \
        --host 127.0.0.1 --port 9876 --log-level warning &
    .venv/bin/python scripts/benchmarks/run_phase2_image_bench.py

Each food image is run TWICE so the second run reflects warm hot-cache /
user_contributed lookups. Non-food images are run once and expected to
return NO_FOOD_DETECTED in ~3-4s (Stage-1 fails fast, no Stage-2 fires).
"""
import json
import os
import sys
import time
from pathlib import Path

import requests
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]  # backend/
load_dotenv(ROOT / ".env")

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]
USER_ID = "d54e6652-fdf1-4ca0-82d1-23d7c02df294"
QA_EMAIL = "reviewer@fitwiz.us"
QA_PASSWORD = "FitWiz2026!"
BASE = os.environ.get("BENCH_BASE", "http://127.0.0.1:9876")

IMG_DIR = Path(__file__).resolve().parent / "images"


def mint_jwt() -> str:
    r = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": SUPABASE_KEY, "Content-Type": "application/json"},
        json={"email": QA_EMAIL, "password": QA_PASSWORD},
        timeout=10,
    )
    r.raise_for_status()
    return r.json()["access_token"]


def time_image_scan(token: str, name: str, img_bytes: bytes) -> dict:
    """Run /analyze-image-stream once. Returns latency + outcome dict."""
    headers = {"Authorization": f"Bearer {token}"}
    t0 = time.perf_counter()
    last_event = None
    final_payload = None
    error_code = None
    cache_source = None
    n_dishes = 0

    try:
        with requests.post(
            f"{BASE}/api/v1/nutrition/analyze-image-stream",
            headers=headers,
            files={"image": (name, img_bytes, "image/jpeg")},
            data={"user_id": USER_ID, "meal_type": "lunch"},
            stream=True,
            timeout=120,
        ) as resp:
            for line in resp.iter_lines(decode_unicode=True):
                if not line:
                    continue
                if line.startswith("event:"):
                    last_event = line.split(":", 1)[1].strip()
                elif line.startswith("data:"):
                    try:
                        d = json.loads(line[5:].strip())
                    except Exception:
                        continue
                    if last_event in ("done", "error"):
                        final_payload = d
                        error_code = d.get("error_code")
                        cs = d.get("cache_source") or (
                            (d.get("data") or {}).get("cache_source") if isinstance(d.get("data"), dict) else None
                        )
                        if cs:
                            cache_source = cs
                        items = d.get("food_items") or (d.get("data") or {}).get("food_items") or []
                        if isinstance(items, list):
                            n_dishes = len(items)
                if last_event in ("done", "error"):
                    break
    except Exception as e:
        return {
            "elapsed_ms": (time.perf_counter() - t0) * 1000,
            "final_event": "exception",
            "error": str(e),
        }

    return {
        "elapsed_ms": (time.perf_counter() - t0) * 1000,
        "final_event": last_event,
        "error_code": error_code,
        "cache_source": cache_source,
        "n_dishes": n_dishes,
    }


def main() -> int:
    print("[1/3] minting QA reviewer JWT...")
    token = mint_jwt()
    print(f"      ok (token len={len(token)})\n")

    print(f"[2/3] discovering images in {IMG_DIR}")
    images = sorted(IMG_DIR.glob("*.jpg"))
    if not images:
        print("      no images found — aborting")
        return 1
    for p in images:
        print(f"      • {p.name} ({p.stat().st_size} bytes)")
    print()

    print("[3/3] running scans (each food image twice; non-food once)\n")
    header = f"{'image':<32} {'pass':>5} {'elapsed':>10}  {'event':<8} {'dishes':>6}  notes"
    print(header)
    print("-" * len(header))

    rows = []
    for img_path in images:
        is_non_food = img_path.name.startswith("non_food_")
        n_passes = 1 if is_non_food else 2
        img_bytes = img_path.read_bytes()
        for pass_idx in range(1, n_passes + 1):
            r = time_image_scan(token, img_path.name, img_bytes)
            label = "warm" if pass_idx == 2 else "cold"
            ms = f"{r['elapsed_ms']:.0f}ms"
            ev = r.get("final_event", "?") or "?"
            dishes = r.get("n_dishes", 0)
            notes_parts = []
            if r.get("error_code"):
                notes_parts.append(f"err={r['error_code']}")
            if r.get("cache_source"):
                notes_parts.append(f"cache={r['cache_source']}")
            if r.get("error"):
                notes_parts.append(f"exc={r['error'][:50]}")
            notes = " ".join(notes_parts)
            print(f"{img_path.name:<32} {label:>5} {ms:>10}  {ev:<8} {dishes:>6}  {notes}")
            rows.append({"image": img_path.name, "pass": label, **r})

    # Summary stats
    food_cold = [r for r in rows if not r["image"].startswith("non_food_") and r["pass"] == "cold"]
    food_warm = [r for r in rows if not r["image"].startswith("non_food_") and r["pass"] == "warm"]
    nonfood = [r for r in rows if r["image"].startswith("non_food_")]
    if food_cold:
        avg_cold = sum(r["elapsed_ms"] for r in food_cold) / len(food_cold)
        print(f"\nfood cold avg: {avg_cold:.0f}ms ({len(food_cold)} images)")
    if food_warm:
        avg_warm = sum(r["elapsed_ms"] for r in food_warm) / len(food_warm)
        print(f"food warm avg: {avg_warm:.0f}ms ({len(food_warm)} images)")
    if nonfood:
        avg_nonfood = sum(r["elapsed_ms"] for r in nonfood) / len(nonfood)
        print(f"non-food avg:  {avg_nonfood:.0f}ms ({len(nonfood)} images, expect NO_FOOD_DETECTED)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
