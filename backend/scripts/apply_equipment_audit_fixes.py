"""
Apply equipment-tag fixes from a reviewed audit CSV.

Workflow:
  1. Run `audit_exercise_equipment_tags.py` → CSV at output/equipment_audit_*.csv
  2. Hand-review the CSV. Fill in / correct `suggested_equipment` for any
     row where the heuristic was wrong. Delete rows you DON'T want fixed.
  3. Save the reviewed CSV (e.g. as `equipment_audit_REVIEWED.csv`).
  4. Run this script with --csv pointing at the reviewed file.

Run from repo root:
    cd backend && .venv/bin/python scripts/apply_equipment_audit_fixes.py \\
        --csv scripts/output/equipment_audit_REVIEWED.csv

Safety:
- Writes to the underlying `exercise_library` table (NOT the view) using
  the row's name as the key. Ambiguous names (multiple rows with the
  same name) are reported and skipped — fix those manually.
- Snapshots before-state to scripts/output/<csv-stem>_before_<ts>.json
  for rollback.
- Prompts for confirmation before mutating. Pass --yes to skip the prompt
  in CI / scripted runs.
- Idempotent: re-running with the same CSV is a no-op once equipment has
  been updated (rows whose current equipment already matches the
  suggested value are skipped).
"""
import argparse
import asyncio
import csv
import json
import os
import re
from datetime import datetime
from pathlib import Path


async def _main() -> None:
    import asyncpg
    from dotenv import load_dotenv

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--csv", required=True, help="Reviewed audit CSV path (relative to repo root)"
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Skip the confirmation prompt (use in scripted runs only)",
    )
    args = parser.parse_args()

    csv_path = Path(args.csv).resolve()
    if not csv_path.exists():
        raise SystemExit(f"CSV not found: {csv_path}")

    load_dotenv()
    url = os.environ["DATABASE_URL"]
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)

    # Read the CSV. Drop rows with empty suggested_equipment — those are
    # manual-review-only rows the auditor didn't fill in.
    rows = []
    with csv_path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            suggestion = (row.get("suggested_equipment") or "").strip()
            if not suggestion:
                continue
            rows.append(
                {
                    "name": row["name"].strip(),
                    "current_equipment": (row.get("current_equipment") or "").strip(),
                    "suggested_equipment": suggestion,
                }
            )

    if not rows:
        print("No actionable rows in CSV (all suggested_equipment empty). Nothing to do.")
        return

    print(f"→ Loaded {len(rows)} actionable rows from {csv_path.name}")
    print(
        f"   Sample: {rows[0]['name']!r}: "
        f"{rows[0]['current_equipment']!r} → {rows[0]['suggested_equipment']!r}"
    )

    if not args.yes:
        resp = input(f"Apply these {len(rows)} updates? [y/N] ").strip().lower()
        if resp not in {"y", "yes"}:
            print("Aborted.")
            return

    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    snapshot_path = output_dir / f"{csv_path.stem}_before_{ts}.json"

    conn = await asyncpg.connect(url, ssl="require")
    try:
        # Snapshot before-state. Match by exercise_name (the column on the
        # base table — the view exposes it as `name` after INITCAP/clean).
        # We snapshot BOTH the raw rows that match AND record the count so
        # ambiguous matches surface in the snapshot.
        before = []
        ambiguous = []
        skipped_no_change = 0
        applied = 0

        async with conn.transaction():
            for row in rows:
                name = row["name"]
                new_eq = row["suggested_equipment"]

                # The view normalises name via INITCAP+regex. To match a
                # base row, we look it up via case-insensitive comparison
                # of `exercise_name` and the cleaned name.
                base_rows = await conn.fetch(
                    """
                    SELECT id, exercise_name, equipment FROM exercise_library
                    WHERE INITCAP(
                        TRIM(REGEXP_REPLACE(
                          REGEXP_REPLACE(exercise_name, '[_\\s]*(Female|Male|female|male)$', '', 'i'),
                          '_', ' ', 'g'
                        ))
                    ) = $1
                    """,
                    name,
                )
                if not base_rows:
                    print(f"   ⚠️ no match for {name!r} — skipping")
                    continue
                if len(base_rows) > 1:
                    ambiguous.append(
                        {
                            "name": name,
                            "match_count": len(base_rows),
                            "ids": [str(r["id"]) for r in base_rows],
                        }
                    )
                    print(
                        f"   ⚠️ {name!r} matches {len(base_rows)} base rows — "
                        f"skipping (fix manually)"
                    )
                    continue

                base = base_rows[0]
                if (base["equipment"] or "").strip().lower() == new_eq.strip().lower():
                    skipped_no_change += 1
                    continue

                before.append(
                    {
                        "id": str(base["id"]),
                        "exercise_name": base["exercise_name"],
                        "before_equipment": base["equipment"],
                        "after_equipment": new_eq,
                    }
                )
                await conn.execute(
                    "UPDATE exercise_library SET equipment = $1 WHERE id = $2",
                    new_eq,
                    base["id"],
                )
                applied += 1

        snapshot_path.write_text(
            json.dumps(
                {
                    "applied": before,
                    "ambiguous_skipped": ambiguous,
                    "no_change_skipped": skipped_no_change,
                },
                indent=2,
            )
        )

        print(f"\n✅ Applied {applied} updates")
        print(f"   {skipped_no_change} skipped (already at target value)")
        print(f"   {len(ambiguous)} skipped (ambiguous name matches)")
        print(f"   Rollback snapshot: {snapshot_path}")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
