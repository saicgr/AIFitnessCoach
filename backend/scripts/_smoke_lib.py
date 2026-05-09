"""Shared helpers for full /generate-stream + /regenerate-stream sweeps.

Pulled out so the two harness files stay readable.
"""
from __future__ import annotations

import asyncio
import csv
import json
import os
import shutil
import time
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import httpx
import requests
from dotenv import load_dotenv
from supabase import Client, create_client

BACKEND = Path(__file__).resolve().parent.parent
load_dotenv(BACKEND / ".env")

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]
RENDER = os.environ.get("RENDER_BASE", "https://aifitnesscoach-zqi3.onrender.com")

USER_ID = "d54e6652-fdf1-4ca0-82d1-23d7c02df294"
ACTIVE_PROFILE = "0890400c-6900-4cd0-b55a-353ea1655206"
QA_EMAIL = "reviewer@fitwiz.us"
QA_PASSWORD = "FitWiz2026!"

sb: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def get_jwt() -> str:
    r = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": SUPABASE_KEY, "Content-Type": "application/json"},
        json={"email": QA_EMAIL, "password": QA_PASSWORD},
        timeout=10,
    )
    r.raise_for_status()
    return r.json()["access_token"]


def next_n_dates(n: int, start_offset: int = 1) -> List[str]:
    """N upcoming dates starting +start_offset days from today."""
    return [(date.today() + timedelta(days=start_offset + i)).isoformat()
            for i in range(n)]


def extract_exercises(workout: Optional[Dict[str, Any]]) -> List[Dict[str, Any]]:
    if not workout:
        return []
    raw = workout.get("exercises_json") or workout.get("exercises") or []
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except Exception:
            return []
    return raw if isinstance(raw, list) else []


def init_outputs(prefix: str, csv_cols: List[str]) -> Path:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out = BACKEND / "scripts" / "output" / f"{prefix}_{ts}"
    (out / "json").mkdir(parents=True, exist_ok=True)
    with (out / "workouts.csv").open("w", newline="") as fh:
        csv.writer(fh).writerow(csv_cols)
    print(f"[harness] output → {out}", flush=True)
    return out


def resume_or_init_outputs(
    prefix: str, csv_cols: List[str], resume_dir: Optional[str],
) -> tuple:
    """Returns (out_dir, completed_idx_set, resumed_entries).

    If `resume_dir` is provided AND exists with a json/ subdir, scan it for
    `scenario_NNN.json` files, return their indices in completed_idx_set,
    and rebuild md_entries from CSV. The harness loop should then skip any
    scenario whose idx is in completed_idx_set.

    If `resume_dir` is "auto", find the most recent dir matching `<prefix>_*`
    under scripts/output/.

    Otherwise initializes a fresh dir via init_outputs().
    """
    output_root = BACKEND / "scripts" / "output"
    if resume_dir and resume_dir.lower() == "auto":
        candidates = sorted(
            (p for p in output_root.iterdir()
             if p.is_dir() and p.name.startswith(f"{prefix}_")),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )
        resume_dir = str(candidates[0]) if candidates else None
        if resume_dir:
            print(f"[harness] resume=auto → {resume_dir}", flush=True)

    if not resume_dir:
        return init_outputs(prefix, csv_cols), set(), []

    out = Path(resume_dir)
    if not out.is_absolute():
        out = output_root / out.name if "/" not in resume_dir else Path(resume_dir)
    json_dir = out / "json"
    csv_path = out / "workouts.csv"
    if not out.is_dir():
        print(f"[harness] resume_dir not found: {out} — starting fresh",
              flush=True)
        return init_outputs(prefix, csv_cols), set(), []

    # Ensure json/ exists (might have been consolidated already — bail out).
    if not json_dir.exists():
        print(f"[harness] {out}/json missing (already consolidated?) — "
              "starting fresh", flush=True)
        return init_outputs(prefix, csv_cols), set(), []

    completed: set = set()
    for jf in json_dir.glob("scenario_*.json"):
        try:
            idx = int(jf.stem.split("_")[-1])
            completed.add(idx)
        except Exception:
            pass

    # Reconstruct md_entries from existing CSV so the live MD reflects state.
    entries = []
    if csv_path.exists():
        with csv_path.open() as fh:
            reader = csv.DictReader(fh)
            for r in reader:
                try:
                    idx = int(r.get("idx", "0"))
                except Exception:
                    continue
                err = r.get("error_message", "")
                n_ex = int(r.get("n_exercises", "0") or 0)
                entries.append({
                    "idx": idx,
                    "label": r.get("label", ""),
                    "name": r.get("workout_name", ""),
                    "n_exercises": n_ex,
                    "latency_ms": int(r.get("latency_ms", "0") or 0),
                    "error": err,
                    "valid": (
                        r.get("http_status") == "200"
                        and n_ex > 0
                        and not err
                    ),
                })
    else:
        # CSV missing but json/ exists — recreate the CSV header.
        with csv_path.open("w", newline="") as fh:
            csv.writer(fh).writerow(csv_cols)

    print(
        f"[harness] resuming → {out} ({len(completed)} scenarios already done)",
        flush=True,
    )
    return out, completed, entries


def write_row(out_dir: Path, row: Dict[str, Any], csv_cols: List[str],
              full_payload: Dict[str, Any]) -> None:
    """Append CSV row (incl. raw_json_payload column inline) — no per-scenario JSON dump.

    Previously this wrote a JSON file per scenario and consolidated at end of run.
    Problem: if the harness was killed mid-flight, JSONs lingered + were never folded.
    Now: payload is written DIRECTLY into the CSV's `raw_json_payload` column on each
    scenario, eliminating the json/ directory entirely. Survives kill -9 cleanly.
    """
    csv_path = out_dir / "workouts.csv"
    cols = list(csv_cols)
    if "raw_json_payload" not in cols:
        cols = cols + ["raw_json_payload"]
        # Append column to header if needed (only if header was already written WITHOUT
        # raw_json_payload).
        try:
            with csv_path.open() as fh:
                first = fh.readline()
            if first and "raw_json_payload" not in first:
                # Re-read all, rewrite with extended header.
                with csv_path.open() as fh:
                    existing = list(csv.reader(fh))
                if existing:
                    existing[0] = existing[0] + ["raw_json_payload"]
                    for r in existing[1:]:
                        # Pad with empty payload — these are pre-fix rows.
                        r.append("")
                    with csv_path.open("w", newline="") as fh:
                        w = csv.writer(fh)
                        w.writerows(existing)
        except FileNotFoundError:
            pass

    payload_str = json.dumps(full_payload, separators=(",", ":"), default=str)
    row_with_payload = dict(row)
    row_with_payload["raw_json_payload"] = payload_str
    with csv_path.open("a", newline="") as fh:
        csv.writer(fh).writerow([row_with_payload.get(c, "") for c in cols])

    # Also remove any stale json/ subdir that older runs left behind.
    json_dir = out_dir / "json"
    if json_dir.exists():
        try:
            shutil.rmtree(json_dir)
        except Exception:
            pass


def consolidate_and_cleanup(out_dir: Path, csv_cols: List[str]) -> None:
    """Compatibility shim. write_row() now writes payloads directly into the CSV's
    raw_json_payload column, so there's nothing to fold. This function only exists to
    clean up `json/` from prior-format runs (pre-2026-05-08) and as a no-op end-of-run hook.
    """
    json_dir = out_dir / "json"
    csv_path = out_dir / "workouts.csv"
    if not csv_path.exists():
        return

    if json_dir.exists():
        # Pre-2026-05-08 format: per-scenario JSONs that need folding into CSV.
        try:
            with csv_path.open() as fh:
                rows = list(csv.reader(fh))
            if not rows:
                shutil.rmtree(json_dir)
                return
            header = rows[0]
            body = rows[1:]
            j_by_idx: Dict[int, Dict[str, Any]] = {}
            for jf in sorted(json_dir.glob("scenario_*.json")):
                try:
                    payload = json.loads(jf.read_text())
                    idx = payload.get("idx") or payload.get("csv_row", {}).get("idx") \
                        or int(jf.stem.split("_")[-1])
                    j_by_idx[int(idx)] = payload
                except Exception as e:
                    print(f"  ⚠️  parse {jf}: {e}", flush=True)
            if "raw_json_payload" not in header:
                header = header + ["raw_json_payload"]
                new_body = []
                for r in body:
                    try:
                        idx = int(r[0])
                    except Exception:
                        new_body.append(r + [""])
                        continue
                    new_body.append(r + [json.dumps(j_by_idx.get(idx, {}),
                                                    separators=(",", ":"), default=str)])
                with csv_path.open("w", newline="") as fh:
                    w = csv.writer(fh)
                    w.writerow(header)
                    w.writerows(new_body)
            shutil.rmtree(json_dir)
            print(f"[harness] folded {len(j_by_idx)} legacy json files → csv; removed {json_dir}",
                  flush=True)
        except Exception as e:
            print(f"[harness] cleanup error: {e}", flush=True)


async def call_sse_with_retry(
    client: httpx.AsyncClient,
    jwt: str,
    url: str,
    body: Dict[str, Any],
    max_retries: int = 2,
    backoff_s: float = 65.0,
) -> Dict[str, Any]:
    """POST SSE, parse events, retry once on Vertex 429 with backoff."""
    for attempt in range(max_retries + 1):
        result = await _call_sse_once(client, jwt, url, body)
        err = result.get("error") or ""
        if "RESOURCE_EXHAUSTED" in err or "429" in err:
            if attempt < max_retries:
                print(f"  [retry] Vertex 429 — sleeping {backoff_s}s then retrying "
                      f"(attempt {attempt + 1}/{max_retries})", flush=True)
                await asyncio.sleep(backoff_s)
                continue
        return result
    return result  # type: ignore


async def _call_sse_once(
    client: httpx.AsyncClient, jwt: str, url: str, body: Dict[str, Any],
) -> Dict[str, Any]:
    t0 = time.time()
    events: List[Dict[str, Any]] = []
    final_workout: Optional[Dict[str, Any]] = None
    preview_id: Optional[str] = None
    err: Optional[str] = None
    status = -1
    try:
        async with client.stream(
            "POST", url, json=body,
            headers={
                "Authorization": f"Bearer {jwt}",
                "Accept": "text/event-stream",
            },
            timeout=90.0,
        ) as resp:
            status = resp.status_code
            if resp.status_code != 200:
                txt = await resp.aread()
                err = f"HTTP {resp.status_code}: {txt[:300]!r}"
                return {
                    "status": status,
                    "latency_ms": int((time.time() - t0) * 1000),
                    "events": [], "final_workout": None,
                    "preview_id": None, "error": err,
                }
            async for line in resp.aiter_lines():
                if not line or not line.startswith("data: "):
                    continue
                raw = line[6:].strip()
                if not raw:
                    continue
                try:
                    ev = json.loads(raw)
                except Exception:
                    events.append({"_raw": raw[:300]})
                    continue
                events.append(ev)
                if isinstance(ev, dict):
                    if "preview_id" in ev:
                        preview_id = ev.get("preview_id")
                    if "error" in ev and "id" not in ev:
                        err = f"sse_error: {str(ev['error'])[:300]}"
                    if "id" in ev and ("exercises_json" in ev or "exercises" in ev):
                        final_workout = ev
                    elif "workout" in ev and isinstance(ev["workout"], dict):
                        final_workout = ev["workout"]
    except Exception as e:
        err = f"{type(e).__name__}: {e}"

    return {
        "status": status,
        "latency_ms": int((time.time() - t0) * 1000),
        "events": events,
        "final_workout": final_workout,
        "preview_id": preview_id,
        "error": err,
    }


_LIVE_MARKER = "<!-- LIVE-RUN-STATUS — auto-updated by harness; do not edit -->"


def update_md_live_status(
    md_path: Path,
    entries: List[Dict[str, Any]],
    run_started_at: str,
) -> None:
    """Rewrite the LIVE-RUN-STATUS section of `md_path` with current entries.

    Each entry: { idx, valid, label, name, n_exercises, latency_ms, error }
    """
    if not md_path.exists():
        return
    raw = md_path.read_text()
    head = raw.split(_LIVE_MARKER, 1)[0].rstrip() + "\n\n"
    body_lines = [
        _LIVE_MARKER,
        "## 🔴 Live Run Status",
        f"_Run started {run_started_at}._ Updated as each scenario completes.\n",
        "| # | Status | Label | Workout name | n_ex | latency_ms | error |",
        "|---|---|---|---|---|---|---|",
    ]
    for e in entries:
        marker = "✅" if e.get("valid") else "❌"
        err = (e.get("error") or "").replace("|", "/")[:80]
        name = (e.get("name") or "").replace("|", "/")[:60]
        body_lines.append(
            f"| {e['idx']} | {marker} | {e.get('label','')[:60]} | "
            f"{name} | {e.get('n_exercises', 0)} | {e.get('latency_ms', 0)} | {err} |"
        )
    md_path.write_text(head + "\n".join(body_lines) + "\n")


def workout_summary(result: Dict[str, Any]) -> Dict[str, Any]:
    """Extract summary fields from a result for CSV row."""
    workout = result.get("final_workout") or {}
    exs = extract_exercises(workout)
    names = [(e.get("name") or e.get("exercise_name") or "") for e in exs]
    sets = [str(e.get("sets") or "") for e in exs]
    reps = [str(e.get("reps") or "") for e in exs]
    weights = [str(e.get("weight_kg") or e.get("weight") or "") for e in exs]
    rests = [str(e.get("rest_seconds") or "") for e in exs]
    muscles: List[str] = []
    for e in exs:
        m = e.get("muscle_group") or e.get("target_muscle") or ""
        if isinstance(m, list):
            m = ",".join(m)
        muscles.append(str(m))
    total_vol = 0.0
    for e in exs:
        try:
            si = int(e.get("sets") or 0)
            ri = int(e.get("reps") or 0) if str(e.get("reps") or "").isdigit() else 10
            wf = float(e.get("weight_kg") or e.get("weight") or 0)
            total_vol += si * ri * wf
        except Exception:
            pass
    return {
        "workout_id": workout.get("id", ""),
        "workout_name": workout.get("name", ""),
        "workout_type": workout.get("type", ""),
        "workout_difficulty": workout.get("difficulty", ""),
        "workout_notes": (workout.get("notes") or workout.get("description") or "")[:500],
        "n_exercises": len(exs),
        "exercise_names_pipe": "|".join(names),
        "per_exercise_sets": "|".join(sets),
        "per_exercise_reps": "|".join(reps),
        "per_exercise_weight_kg": "|".join(weights),
        "per_exercise_rest_seconds": "|".join(rests),
        "per_exercise_muscle_group": "|".join(muscles),
        "duration_minutes": workout.get("duration_minutes", ""),
        "total_volume_kg": f"{total_vol:.1f}",
    }
