"""
Audit `exercise_library_cleaned` for exercises whose equipment tag
contradicts what their NAME implies. Surfaces the data-quality issues
that let "Bodyweight Inverted Rows" (tagged equipment="Body Weight" but
physically requiring a bar/TRX) end up in a Bodyweight-only user's plan.

Run from repo root:
    cd backend && .venv/bin/python scripts/audit_exercise_equipment_tags.py

Outputs a CSV at backend/scripts/output/equipment_audit_<timestamp>.csv
with columns: name, current_equipment, suggested_equipment, reason.

This is a READ-ONLY audit. Use the sibling
`apply_equipment_audit_fixes.py` to mutate rows after a human reviewer
has confirmed the suggestions.

Scoping:
- `exercise_library_cleaned` is a view over `exercise_library` (system
  exercises only). User-created custom exercises live in a separate
  table and are NOT touched by this audit.
"""
import asyncio
import csv
import os
import re
from datetime import datetime
from pathlib import Path


# Heuristic: words in an exercise's name that imply specific physical
# equipment, mapped to the canonical equipment tag we'd expect to see.
# When the name contains one of these words but the row's equipment is
# tagged as bodyweight/none, the audit flags it.
NAME_IMPLIES_EQUIPMENT = {
    # Bar-based — needs something to hang from / push off
    "inverted row": "Pull-up Bar",
    "pull-up": "Pull-up Bar",
    "pullup": "Pull-up Bar",
    "chin-up": "Pull-up Bar",
    "chinup": "Pull-up Bar",
    "muscle up": "Pull-up Bar",
    "muscle-up": "Pull-up Bar",
    # Suspension trainer
    "trx": "Suspension Trainer",
    "suspension": "Suspension Trainer",
    "ring ": "Gymnastic Rings",
    "rings ": "Gymnastic Rings",
    # Iron
    "barbell": "Barbell",
    "ez bar": "EZ Bar",
    "ez-bar": "EZ Bar",
    "trap bar": "Trap Bar",
    # Dumbbells / kettlebell — names that are unambiguous
    "dumbbell": "Dumbbell",
    "kettlebell": "Kettlebell",
    "kb ": "Kettlebell",
    # Machines / cable
    "cable": "Cable Machine",
    "smith": "Smith Machine",
    "leg press": "Leg Press",
    "lat pulldown": "Lat Pulldown",
    # Other
    "resistance band": "Resistance Band",
    "medicine ball": "Medicine Ball",
    "battle rope": "Battle Ropes",
    "dip station": "Dip Station",
}

# Bodyweight-token set (matches services.exercise_rag.filters.BODYWEIGHT_TOKENS).
BODYWEIGHT_TOKENS = {"body weight", "bodyweight", "none"}


def suggest_equipment(name: str, current_equipment: str) -> tuple[str | None, str]:
    """Return (suggested_equipment, reason) when the row looks mis-tagged.

    Returns (None, "") when the row is consistent.
    """
    name_lower = name.lower()
    current_lower = (current_equipment or "").strip().lower()
    is_bodyweight_tagged = current_lower in BODYWEIGHT_TOKENS or current_lower == ""

    # Case 1: name implies specific equipment but tag says bodyweight.
    # This is the "Bodyweight Inverted Rows" bug.
    if is_bodyweight_tagged:
        for keyword, suggested in NAME_IMPLIES_EQUIPMENT.items():
            if keyword in name_lower:
                # Skip false positives where the name mentions equipment
                # only as a descriptor of an alternate position (e.g.
                # "Floor Press" without dumbbell — would be too aggressive).
                # The keywords above are conservative.
                return (
                    suggested,
                    f"Name contains {keyword!r} but tagged as bodyweight",
                )

    # Case 2 (NOT auto-suggested, just flagged): name says "bodyweight"
    # but tag says equipment. Could be legit (e.g. "Bodyweight Squat
    # Variation Tagged As Barbell") — too noisy to auto-suggest. Leave
    # for manual review by emitting a flag-only row with empty suggestion.
    if "bodyweight" in name_lower or "body weight" in name_lower:
        if not is_bodyweight_tagged:
            return (
                "",  # empty suggestion = manual review
                f"Name says bodyweight but tagged as {current_equipment!r}",
            )

    return (None, "")


async def _main() -> None:
    import asyncpg
    from dotenv import load_dotenv

    load_dotenv()
    url = os.environ["DATABASE_URL"]
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)

    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    out_path = output_dir / f"equipment_audit_{ts}.csv"

    print(f"→ Auditing exercise_library_cleaned via {url.split('@', 1)[-1]} …")

    conn = await asyncpg.connect(url, ssl="require")
    try:
        rows = await conn.fetch(
            "SELECT name, equipment, target_muscle, body_part FROM exercise_library_cleaned"
        )
        print(f"   {len(rows)} rows fetched from view")

        flagged = []
        for r in rows:
            name = r["name"] or ""
            equipment = r["equipment"] or ""
            suggested, reason = suggest_equipment(name, equipment)
            if suggested is not None:
                flagged.append(
                    {
                        "name": name,
                        "current_equipment": equipment,
                        "suggested_equipment": suggested,
                        "reason": reason,
                        "target_muscle": r["target_muscle"] or "",
                        "body_part": r["body_part"] or "",
                    }
                )

        # Sort: rows WITH a concrete suggestion first (auto-fixable),
        # then "manual review" rows (empty suggestion), alphabetised by name.
        flagged.sort(
            key=lambda x: (
                0 if x["suggested_equipment"] else 1,
                x["name"].lower(),
            )
        )

        with out_path.open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=[
                    "name",
                    "current_equipment",
                    "suggested_equipment",
                    "reason",
                    "target_muscle",
                    "body_part",
                ],
            )
            writer.writeheader()
            writer.writerows(flagged)

        auto_fixable = sum(1 for r in flagged if r["suggested_equipment"])
        manual = len(flagged) - auto_fixable
        print(f"✅ Wrote {len(flagged)} flagged rows → {out_path}")
        print(f"   {auto_fixable} have concrete suggestions (auto-fixable)")
        print(f"   {manual} need manual review (empty suggestion column)")

        # Spot-check the headline bug.
        bw_inverted = [
            r for r in flagged if "inverted row" in r["name"].lower()
        ]
        if bw_inverted:
            print(
                f"\n   Headline bug confirmed: {len(bw_inverted)} row(s) match "
                f"'inverted row' — sample:"
            )
            for r in bw_inverted[:3]:
                print(
                    f"     • {r['name']!r}: {r['current_equipment']!r} → "
                    f"{r['suggested_equipment']!r}"
                )
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(_main())
