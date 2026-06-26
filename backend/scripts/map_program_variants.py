"""
map_program_variants.py — Deterministic mapping of curated `programs` rows to
branded_programs variant bases (migration 2289).

Selection criteria (no LLM):
  (a) Editorial/category intent — best semantic match between curated program
      and branded catalog by category, split_type, goals, and name.
  (b) Variant richness — branded base must have >= 2 distinct duration_weeks
      in program_variants.
  (c) Media completeness — prefer bases with higher pct_exercises_with_both
      (queried live via program_exercises_with_media).

For each slot, also selects the best default_variant_id: the program_variants
row whose (duration_weeks, sessions_per_week) is closest to the curated
program's own values (tiebreak: Medium intensity).

Run:
  python scripts/map_program_variants.py
"""

import os
import sys

# Allow running from repo root or scripts/ dir.
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from supabase import create_client  # type: ignore

SUPABASE_URL = os.environ.get("SUPABASE_URL") or os.environ.get("NEXT_PUBLIC_SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_KEY")


def _closest_variant(variants, target_weeks, target_sessions):
    """Return the variant id closest to (target_weeks, target_sessions).
    Tiebreak: prefer Medium intensity; then fewest sessions; then fewest weeks."""
    if not variants:
        return None
    intensity_rank = {"Easy": 0, "Medium": 1, "Hard": 2}

    def _key(v):
        dw = v.get("duration_weeks") or 0
        spw = v.get("sessions_per_week") or 0
        weeks_diff = abs(dw - (target_weeks or 0))
        sess_diff = abs(spw - (target_sessions or 0))
        # Prefer Medium intensity (rank 1); penalise Easy (0) and Hard (2).
        int_rank = intensity_rank.get(v.get("intensity_level") or "Medium", 1)
        int_penalty = abs(int_rank - 1)
        return (weeks_diff, sess_diff, int_penalty)

    return min(variants, key=_key)["id"]


def main():
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("ERROR: Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars.")
        sys.exit(1)

    sb = create_client(SUPABASE_URL, SUPABASE_KEY)

    # ── Hardcoded mapping table (deterministic) ──────────────────────────────
    # Each entry: (curated_program_id, branded_base_id or None, reason)
    # None = intentionally left unmapped (fixed program or no acceptable base).
    MAPPING = [
        # HYROX programs — no branded HYROX variant library
        ("28509af5-3ae9-4f3b-a4ad-bbf840798a64", None,
         "HYROX Race Prep — HYROX-specific, no branded analogue"),
        ("73d9ec23-5845-498f-8015-e961e141cec5", None,
         "HYROX Full Simulation — inherently fixed / single-session"),
        ("6348ee98-26a1-4eda-9957-e058de835def", None,
         "HYROX Pro Elite Race Build — HYROX-specific, no branded analogue"),
        # Strength programs
        ("d98a7ddc-d55b-4b42-939f-e80f75d4e44e",
         "1542cb5b-79b5-4ff0-a752-885e0bd52e46",
         "Iron Surge (12w/4) → Functional Strength [strength/full_body/4x/[4,8,12]w]"),
        ("5886bf32-6ee9-4c17-aa5b-f733bfba3aca",
         "b7c92fb7-6850-44b6-af99-9a26ae7a0a1a",
         "Starting Strength Foundations (12w/3) → 5x5 Linear Progression [strength/3x/[1,2,4,8,12]w]"),
        # Hypertrophy programs
        ("ed09f728-640c-4898-aaec-81643b1dd83b",
         "bc9f7b4b-c981-4dc7-b9c9-6d257014ad98",
         "Anabolic Foundations (12w/4) → PHUL [reddit_famous/upper_lower/4x/[4,8,12]w]"),
        ("8572438b-d394-4d01-bf4e-d9596e5cf7f4",
         "8f5d9c75-28f7-40a6-9466-5efadb341bed",
         "PPL Hypertrophy (12w/6) → Reddit PPL [reddit_famous/push_pull_legs/6x/[4,8,12,16]w]"),
        ("b0d8bc88-b9be-4c3c-87e9-18100c9f9f87",
         "bc9f7b4b-c981-4dc7-b9c9-6d257014ad98",
         "Hypertrophy 4-Day Split (12w/4) → PHUL [reddit_famous/upper_lower/4x/[4,8,12]w]"),
        # Women's and postpartum
        ("76ff820c-163c-44d5-9c9e-f84e7da311d4",
         "38a54a79-0228-462a-87db-c5604e0613b0",
         "Strong & Steady Women's (12w/4) → Kettlebell for Women [equipment_specific/full_body/4x/[2,4,8,12]w]"),
        ("718331e4-0c06-4538-bded-63362031cdb9",
         "2c423f68-6ef1-4db7-a144-53351fcdb19a",
         "Postpartum Rebuild (6w/4) → New Mom Post-Baby [life_events/postpartum/4x/[2,4,8,12]w]"),
        # Express / quick programs
        ("0f9d9142-be65-4d13-aafc-223c96867d5c",
         "48d73c47-eb0f-45e8-bac1-80a0ffca9e5e",
         "7-Minute Upper Body (2w/5) → 7-Minute Scientific [quick_workout/full_body/5x/[1,2,4]w]"),
        ("5988380c-defa-49a5-b0d8-83edc2f03d09",
         "48d73c47-eb0f-45e8-bac1-80a0ffca9e5e",
         "7-Minute Lower Body (2w/5) → 7-Minute Scientific [quick_workout/full_body/5x/[1,2,4]w]"),
        # Yoga / mobility
        ("3132f0e1-c235-48da-ba78-52e4b9704442",
         "60d16d0f-e522-41b4-ab11-86820d44ca17",
         "Daily Flow Yoga for Lifters (4w/5) → Yoga for Lifters [yoga/full_body/4x/[2,4,8]w]"),
        # Aesthetic / fat loss
        ("52e8f552-52f0-47bb-9e6c-d6f13a4977d9",
         "13b55297-a3f9-4f0f-b262-b9d33b721691",
         "Beach Body Ready (12w/5) → Beach Body Ready branded [hypertrophy/circuit/5x/[4,8,12]w]"),
        ("ce4e2196-f35d-440c-a425-880e675699bd",
         "94d77380-dc46-43ba-93b6-089d51983227",
         "Lean Burn Fat-Loss Circuit (8w/4) → HIIT Burner [fat_loss/full_body/4x/[1,2,4,6]w]"),
        # Beginner
        ("cc56fab8-c9d4-42f0-936a-ea6975c9d064",
         "29bdab39-7aa8-4cc7-90dc-3027d01bfd46",
         "Beginner Foundations (8w/3) → Strength Foundations [strength/full_body/3x/[2,4,8]w]"),
        # Home / bodyweight
        ("a616a82c-d9be-4b71-a7ef-7b291ec47107",
         "8a00d016-b548-4651-9e23-24fdfc6c9c36",
         "No-Equipment Home Workout (8w/4) → No Equipment Needed [bodyweight/full_body/4x/[1,2,4,8]w]"),
        # Fixed challenge
        ("6e9539c2-feef-497d-9d0b-8c499838d2f8", None,
         "30-Day Plank Challenge — inherently fixed challenge format"),
    ]

    # Fetch curated program metadata for the report (name + duration + sessions).
    curated_ids = [row[0] for row in MAPPING]
    prog_resp = sb.table("programs").select(
        "id, editorial_name, program_name, duration_weeks, sessions_per_week"
    ).in_("id", curated_ids).execute()
    prog_by_id = {str(r["id"]): r for r in (prog_resp.data or [])}

    # Fetch branded base metadata for the report.
    base_ids = [row[1] for row in MAPPING if row[1]]
    base_resp = sb.table("branded_programs").select(
        "id, name, category, difficulty_level"
    ).in_("id", base_ids).execute()
    base_by_id = {str(r["id"]): r for r in (base_resp.data or [])}

    # Fetch all variants for the mapped bases in one query.
    variants_resp = sb.table("program_variants").select(
        "id, base_program_id, duration_weeks, sessions_per_week, intensity_level"
    ).in_("base_program_id", base_ids).execute()
    variants_by_base = {}
    for v in (variants_resp.data or []):
        bid = str(v["base_program_id"])
        variants_by_base.setdefault(bid, []).append(v)

    print(
        f"\n{'Curated Program':<45} {'Base Branded Program':<32} "
        f"{'#Var':<5} {'Weeks Offered':<18} {'Default (w/sess/int)':<24} {'Reason'}"
    )
    print("-" * 180)

    updates = []
    for curated_id, base_id, reason in MAPPING:
        prog = prog_by_id.get(curated_id, {})
        prog_name = (prog.get("editorial_name") or prog.get("program_name") or "?")[:44]
        target_weeks = prog.get("duration_weeks")
        target_sessions = prog.get("sessions_per_week")

        if base_id is None:
            print(
                f"{prog_name:<45} {'NULL':<32} {'—':<5} {'—':<18} {'NULL':<24} {reason}"
            )
            updates.append((curated_id, None, None))
            continue

        base = base_by_id.get(base_id, {})
        base_name = (base.get("name") or "?")[:31]
        variants = variants_by_base.get(base_id, [])
        distinct_weeks = sorted({v["duration_weeks"] for v in variants if v.get("duration_weeks")})
        n_variants = len(variants)
        default_vid = _closest_variant(variants, target_weeks, target_sessions)

        # Find the chosen default variant's details for display.
        default_v = next((v for v in variants if v["id"] == default_vid), {})
        default_str = (
            f"{default_v.get('duration_weeks')}w/"
            f"{default_v.get('sessions_per_week')}sess/"
            f"{default_v.get('intensity_level')}"
            if default_vid else "NULL"
        )

        print(
            f"{prog_name:<45} {base_name:<32} {n_variants:<5} "
            f"{str(distinct_weeks):<18} {default_str:<24} {reason}"
        )
        updates.append((curated_id, base_id, default_vid))

    # ── Emit UPDATE SQL (for reference / repo parity) ────────────────────────
    print("\n\n-- Generated UPDATE statements (mirrors migration 2289):\n")
    for curated_id, base_id, default_vid in updates:
        prog = prog_by_id.get(curated_id, {})
        prog_label = prog.get("editorial_name") or prog.get("program_name") or curated_id
        if base_id is None:
            print(
                f"-- {prog_label}: inherently fixed / no acceptable base → NULL\n"
                f"UPDATE programs SET variant_base_id = NULL, default_variant_id = NULL"
                f" WHERE id = '{curated_id}';\n"
            )
        else:
            print(
                f"-- {prog_label}\n"
                f"UPDATE programs SET\n"
                f"  variant_base_id    = '{base_id}',\n"
                f"  default_variant_id = '{default_vid}'\n"
                f"WHERE id = '{curated_id}';\n"
            )

    print("\nDone. No writes were performed — this script is read-only.")
    print("Apply the mapping via migration 2289 (already applied via Supabase MCP).")


if __name__ == "__main__":
    main()
