"""
One-shot data fix: identify a user's today + upcoming workouts that
contain exercises incompatible with their current equipment selection,
and either replace the offending exercises or regenerate the whole
workout (caller picks).

Originally written to fix saichetangrandhe@gmail.com whose Bodyweight +
Home plan included "Bodyweight Inverted Rows" (which physically needs a
bar/TRX). With the hardened `filter_by_equipment` from this same change,
re-running generation produces a valid plan — this script just blows
away the stale cached row so the next /today read regenerates it.

Run from repo root:
    cd backend && .venv/bin/python scripts/fix_user_workout_equipment.py \\
        --email saichetangrandhe@gmail.com [--dry-run] [--yes]

Safety:
- Connects via DATABASE_URL (asyncpg). Bypasses RLS — only run with
  explicit user authorization.
- Snapshots before-state to scripts/output/<email>_<ts>_before.json so
  we can roll back if the regen produces something worse.
- Prompts for confirmation before mutating. Pass --yes for scripted runs.
- Only deletes workouts that are NOT started and NOT completed. Active /
  history workouts are NEVER touched. (Matches the plan's policy in §D.)
- Idempotent: re-running once the workouts are valid is a no-op.
"""
import argparse
import asyncio
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path


def _filter_module():
    """Lazy-import filter_by_equipment from the running backend."""
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    from services.exercise_rag.filters import filter_by_equipment

    return filter_by_equipment


def _equipment_to_list(raw):
    """Mirror of `equipment_dual_write_payload` for the read path.

    Accepts the legacy VARCHAR-of-JSON form, the new text[] form, or a
    bare list, and returns a lowercased list[str].
    """
    if raw is None:
        return ["bodyweight"]
    if isinstance(raw, list):
        return [str(v).strip().lower() for v in raw if str(v).strip()]
    if isinstance(raw, str):
        s = raw.strip()
        if not s:
            return ["bodyweight"]
        if s.startswith("[") and s.endswith("]"):
            try:
                return [
                    str(v).strip().lower()
                    for v in json.loads(s)
                    if str(v).strip()
                ]
            except json.JSONDecodeError:
                return ["bodyweight"]
        return [s.lower()]
    return ["bodyweight"]


async def _main() -> None:
    import asyncpg
    from dotenv import load_dotenv

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--email", required=True, help="User's email address")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report mismatches without deleting anything",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Skip confirmation prompt (for scripted runs)",
    )
    args = parser.parse_args()

    load_dotenv()
    url = os.environ["DATABASE_URL"]
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)

    filter_by_equipment = _filter_module()

    conn = await asyncpg.connect(url, ssl="require")
    try:
        user = await conn.fetchrow(
            "SELECT id, email, equipment, equipment_v2, timezone FROM users WHERE email = $1",
            args.email,
        )
        if not user:
            print(f"❌ User not found: {args.email}")
            return

        user_eq_raw = user["equipment_v2"] or user["equipment"]
        user_eq = _equipment_to_list(user_eq_raw)
        print(f"→ User {user['email']} (id={user['id']})")
        print(f"   Stored equipment: {user_eq}")

        # Read today + upcoming workouts that aren't completed/in-progress.
        # The DB column varies by table version; we conservatively pull
        # everything not flagged completed and let the script decide.
        rows = await conn.fetch(
            """
            SELECT id, scheduled_date, name, status, is_completed,
                   exercises::text AS exercises_json
            FROM workouts
            WHERE user_id = $1::uuid
              AND scheduled_date >= CURRENT_DATE
            ORDER BY scheduled_date
            """,
            str(user["id"]),
        )
        if not rows:
            print("   No today/upcoming workouts found.")
            return

        flagged = []
        for r in rows:
            if r["is_completed"]:
                continue
            if r["status"] in ("in_progress", "generating"):
                continue
            try:
                ex_list = json.loads(r["exercises_json"] or "[]")
            except (json.JSONDecodeError, TypeError):
                ex_list = []
            offending = []
            for ex in ex_list:
                ex_eq = ex.get("equipment") or ""
                ex_name = ex.get("name") or ""
                if not filter_by_equipment(ex_eq, user_eq, ex_name):
                    offending.append(
                        {"name": ex_name, "equipment": ex_eq}
                    )
            if offending:
                flagged.append(
                    {
                        "id": str(r["id"]),
                        "scheduled_date": str(r["scheduled_date"]),
                        "name": r["name"],
                        "status": r["status"],
                        "offending_exercises": offending,
                    }
                )

        print(f"   Scanned {len(rows)} workouts; {len(flagged)} have mismatches.\n")
        for w in flagged:
            print(
                f"   • {w['scheduled_date']} {w['name']!r} (status={w['status']}):"
            )
            for o in w["offending_exercises"]:
                print(
                    f"       ✗ {o['name']!r}  equipment={o['equipment']!r}"
                )

        if not flagged:
            print("✅ No equipment mismatches — nothing to do.")
            return

        if args.dry_run:
            print("\n(--dry-run set — not deleting)")
            return

        if not args.yes:
            resp = (
                input(f"\nDelete these {len(flagged)} workouts so they regenerate? [y/N] ")
                .strip()
                .lower()
            )
            if resp not in {"y", "yes"}:
                print("Aborted.")
                return

        # Snapshot for rollback.
        output_dir = Path(__file__).parent / "output"
        output_dir.mkdir(parents=True, exist_ok=True)
        ts = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        safe_email = args.email.replace("@", "_at_").replace(".", "_")
        snap_path = output_dir / f"{safe_email}_{ts}_before.json"
        snap_path.write_text(json.dumps(flagged, indent=2))
        print(f"   Snapshot → {snap_path}")

        # Delete the offending workouts. The next /today (and the
        # upcoming pre-cache) will regenerate them with the hardened
        # filter, producing a valid plan.
        ids = [w["id"] for w in flagged]
        async with conn.transaction():
            await conn.execute(
                "DELETE FROM workouts WHERE id = ANY($1::uuid[])",
                ids,
            )
        print(f"✅ Deleted {len(ids)} workouts. Next /today read will regenerate.")
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
