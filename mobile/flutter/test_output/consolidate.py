#!/usr/bin/env python3
"""Merge per-scenario JSON dumps into the CSV and remove the json/ dir.

Adds one column `raw_workout_json` to the CSV containing the full
Workout.toJson() dump for each scenario, then deletes the json/ directory.

Run from mobile/flutter/:
    python3 test_output/consolidate.py
"""
from __future__ import annotations

import csv
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
runs = sorted([p for p in ROOT.iterdir() if p.is_dir() and p.name.startswith("quick_workout_engine_")])

if not runs:
    print("No runs found.")
    sys.exit(0)

for run in runs:
    csv_path = run / "workouts.csv"
    json_dir = run / "json"
    if not csv_path.exists() or not json_dir.exists():
        print(f"·  skip {run.name} (no csv or json dir)")
        continue

    # Read CSV.
    with csv_path.open() as fh:
        reader = csv.reader(fh)
        rows = list(reader)
    header = rows[0]
    body = rows[1:]

    # Index JSON files by idx.
    json_by_idx = {}
    for jf in json_dir.glob("scenario_*.json"):
        try:
            payload = json.loads(jf.read_text())
            idx = payload.get("scenario", {}).get("idx")
            if idx is not None:
                json_by_idx[int(idx)] = payload
        except Exception as e:
            print(f"  ⚠️  could not parse {jf.name}: {e}")

    # Append `raw_workout_json` column.
    new_header = header + ["raw_workout_json"]
    new_body = []
    for row in body:
        try:
            idx = int(row[0])
        except Exception:
            new_body.append(row + [""])
            continue
        payload = json_by_idx.get(idx, {})
        workout = payload.get("workout") or {}
        # Compact one-line JSON so it sits in a single CSV cell.
        new_body.append(row + [json.dumps(workout, separators=(",", ":"))])

    # Write back (overwrite same file).
    with csv_path.open("w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(new_header)
        w.writerows(new_body)

    # Remove json/ dir.
    shutil.rmtree(json_dir)

    print(f"✅ {run.name}: {len(body)} rows consolidated → {csv_path}")
    print(f"   🗑️  removed {json_dir}")
