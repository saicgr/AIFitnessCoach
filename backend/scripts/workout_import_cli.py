#!/usr/bin/env python3
"""
Local debugging CLI for the workout-import pipeline.

Usage:
  python -m scripts.workout_import_cli --file <path> [--dry-run] [--classify-only] [--verbose]

Examples:
  python -m scripts.workout_import_cli --file tests/fixtures/workout_imports/hevy_sample.csv --dry-run
  python -m scripts.workout_import_cli --file /path/to/export.csv --classify-only --verbose

Invaluable during user-support: paste a user's export, see exactly where it
lands in the detector + adapter cascade + what the first few normalized rows
look like — all without touching the DB.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
from pathlib import Path
from uuid import uuid4


def _summarize_row(row) -> dict:
    """Render one CanonicalSetRow / CanonicalCardioRow as a printable dict."""
    d = row.model_dump() if hasattr(row, "model_dump") else dict(row)
    # Flatten the enum values so JSON-dump doesn't choke.
    for k, v in list(d.items()):
        if hasattr(v, "value"):
            d[k] = v.value
    return d


async def _run(args):
    from services.workout_import.canonical import ImportMode
    from services.workout_import.format_detector import detect
    from services.workout_import.service import _call_adapter, _load_adapter

    path = Path(args.file)
    if not path.exists():
        print(f"error: file not found: {path}", file=sys.stderr)
        sys.exit(2)

    data = path.read_bytes()
    filename = path.name

    # Stage 1: detect
    detection = detect(data, filename=filename)
    print(f"\n── Detection ──")
    print(f"  source_app:  {detection.source_app}")
    print(f"  mode:        {detection.mode.value if hasattr(detection.mode, 'value') else detection.mode}")
    print(f"  confidence:  {detection.confidence:.2f}")
    if detection.warnings:
        print(f"  warnings:    {detection.warnings}")
    if args.verbose:
        print(f"  file size:   {len(data):,} bytes")

    if args.classify_only:
        return

    # Stage 2: dispatch to adapter
    try:
        adapter = _load_adapter(detection.source_app)
    except ModuleNotFoundError as e:
        print(f"\nerror: no adapter for {detection.source_app!r}: {e}", file=sys.stderr)
        sys.exit(3)

    result = await _call_adapter(
        adapter,
        data=data,
        filename=filename,
        user_id=uuid4(),
        unit_hint=args.unit_hint,
        tz_hint=args.timezone,
        mode_hint=detection.mode,
    )

    print(f"\n── Parse Result ──")
    print(f"  mode:               {result.mode.value if hasattr(result.mode, 'value') else result.mode}")
    print(f"  source_app:         {result.source_app}")
    print(f"  strength_rows:      {len(result.strength_rows)}")
    print(f"  cardio_rows:        {len(result.cardio_rows)}")
    print(f"  has_template:       {result.template is not None}")
    print(f"  unresolved_names:   {len(result.unresolved_exercise_names)}")
    if result.warnings:
        print(f"  warnings:           {result.warnings}")

    if args.verbose and result.strength_rows:
        print(f"\n── First {min(5, len(result.strength_rows))} Strength Rows ──")
        for row in result.strength_rows[:5]:
            print(json.dumps(_summarize_row(row), indent=2, default=str))

    if args.verbose and result.cardio_rows:
        print(f"\n── First {min(5, len(result.cardio_rows))} Cardio Rows ──")
        for row in result.cardio_rows[:5]:
            print(json.dumps(_summarize_row(row), indent=2, default=str))


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--file", required=True, help="Path to the file to classify/parse")
    parser.add_argument("--dry-run", action="store_true", help="(default on — never writes to DB)")
    parser.add_argument("--classify-only", action="store_true",
                        help="Stop after detection; don't dispatch to adapter")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Print first 5 parsed rows as JSON")
    parser.add_argument("--unit-hint", default="lb", choices=["kg", "lb"],
                        help="Weight unit fallback for apps that don't encode units (default: lb)")
    parser.add_argument("--timezone", default="UTC", help="IANA timezone for naive timestamps")
    args = parser.parse_args()
    asyncio.run(_run(args))


if __name__ == "__main__":
    main()
