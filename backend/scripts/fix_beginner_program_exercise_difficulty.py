#!/usr/bin/env python3
"""Swap advanced/elite exercises out of BEGINNER-badged published programs.

E2E register row 90. "Gentle Start" is badged BEGINNER and sold for true
beginners / postpartum / over-50, yet its default variant prescribes
Archer Push-Up (`exercise_safety_index.safety_difficulty = 'advanced'`,
shoulder_safe = false, wrist_safe = false) in all 8 weeks. Catalog-wide the
same class covers 21 beginner-badged programs.

The replacement is DETERMINISTIC — no LLM, no hand-written per-exercise table:

  1. offender  = an exercise in a beginner-badged published program whose name
                 resolves in exercise_safety_index to safety_difficulty
                 advanced/elite.
  2. candidate = exercise_safety_index rows with safety_difficulty='beginner',
                 the SAME movement_pattern and the SAME equipment (a bodyweight
                 program never gets gym gear), that resolve to a real
                 exercise_library row whose media EXISTS on S3
                 (scripts/audit_exercise_media_urls.object_exists — the
                 documented media gate; non-null is not enough).
                 Bodyweight is the only permitted equipment fallback, and only
                 downward (loaded → bodyweight), never upward.
  3. pick      = rank by (same body_part, name-token overlap, target-muscle
                 overlap, is_beginner_safe, shorter name, name asc) — the
                 nearest same-movement regression, stable across runs.

Every rewritten exercise object is copied to
`program_variant_weeks_exercise_backup` first (logged-data durability), with
the variant/week/session/exercise coordinates needed to restore it.

    .venv/bin/python scripts/fix_beginner_program_exercise_difficulty.py            # dry run
    .venv/bin/python scripts/fix_beginner_program_exercise_difficulty.py --apply

Verify after:  scripts/audit_beginner_program_exercise_difficulty.py --check
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from typing import Any, Dict, List, Optional

import psycopg2
import psycopg2.extras

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from audit_exercise_media_urls import object_exists  # noqa: E402
from backfill_thin_program_sessions import (  # noqa: E402
    _QUALIFIER_TOKENS as _QUALIFIERS,
)

BAD_DIFFICULTY = ("advanced", "elite")
_STOP = {"the", "a", "with", "and", "to", "on", "of", "in", "for"}

# The library is the noisy free-exercise dataset. For a REPLACEMENT we only need
# to exclude entries that are not the same kind of training movement at all —
# stretches, mobility drills, poses and prop novelties. (The stricter junk list
# in backfill_thin_program_sessions also drops "air"/"jump", which would rule
# out "Air Squat" — the correct beginner regression of a pistol squat.)
_JUNK_RE = re.compile(
    r"(stretch|mobilit|warm[- ]?up|\bpose\b|\bflow\b|foam roll|massage|"
    r"\bbottle\b|\bmatka\b|hay bale|\btire\b|sandbag|samtola|white screen)",
    re.I,
)

# A strength movement is never replaced by a mobility drill, a plyometric or a
# rotation drill — those train something else entirely, however well their
# body_part / target_muscle tags happen to line up.
_STRENGTH_PATTERNS = {
    "horizontal_push", "horizontal_pull", "overhead_press", "overhead_pull",
    "vertical_pull", "vertical_push", "squat", "hinge", "lunge", "carry",
    "isometric", "anti_rotation", "hanging",
}


def norm(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]", "", (name or "")).lower()


def tokens(name: str) -> set:
    """Movement words in a name, crudely singularized so 'Squats' matches
    'Squat' and 'Raises' matches 'Raise'."""
    out = set()
    for t in re.split(r"[^a-zA-Z0-9]+", (name or "").lower()):
        if not t or t in _STOP:
            continue
        if len(t) > 3 and t.endswith("s") and not t.endswith("ss"):
            t = t[:-1]
        out.add(t)
    return out


def muscle_tokens(value: Optional[str]) -> set:
    return {
        t for t in re.split(r"[^a-zA-Z]+", (value or "").lower())
        if len(t) > 3
    }


def dsn() -> str:
    d = os.environ.get("DATABASE_URL", "")
    if not d:
        print("DATABASE_URL is not set", file=sys.stderr)
        sys.exit(2)
    d = d.replace("postgresql+asyncpg://", "postgresql://")
    if "sslmode" not in d:
        d += ("&" if "?" in d else "?") + "sslmode=require"
    return d


OFFENDER_SQL = """
WITH beg AS (
  SELECT p.id AS program_id, p.program_name, v.id AS variant_id
  FROM programs p
  JOIN program_variants v ON v.base_program_id = p.variant_base_id
  WHERE p.is_published AND lower(p.difficulty_level) = 'beginner'
)
SELECT DISTINCT
       lower(regexp_replace(e->>'name', '[^a-zA-Z0-9]', '', 'g')) AS norm_name,
       e->>'name'                                                 AS raw_name,
       e->>'equipment'                                            AS raw_equipment
FROM beg b
JOIN program_variant_weeks w ON w.variant_id = b.variant_id,
LATERAL jsonb_array_elements(w.workouts) s,
LATERAL jsonb_array_elements(COALESCE(s->'exercises', '[]'::jsonb)) e
WHERE lower(regexp_replace(e->>'name', '[^a-zA-Z0-9]', '', 'g')) IN (
  SELECT name_normalized FROM exercise_safety_index
  WHERE safety_difficulty IN ('advanced', 'elite')
)
"""

WEEK_SQL = """
WITH beg AS (
  SELECT p.id AS program_id, p.program_name, v.id AS variant_id,
         (v.id = p.default_variant_id) AS is_default
  FROM programs p
  JOIN program_variants v ON v.base_program_id = p.variant_base_id
  WHERE p.is_published AND lower(p.difficulty_level) = 'beginner'
)
SELECT w.id, w.variant_id, w.week_number, w.workouts, b.program_name,
       b.program_id, b.is_default
FROM beg b JOIN program_variant_weeks w ON w.variant_id = b.variant_id
"""


def load_safety(cur) -> Dict[str, dict]:
    cur.execute(
        "SELECT name, name_normalized, movement_pattern, equipment, body_part,"
        " target_muscle, safety_difficulty, is_beginner_safe"
        " FROM exercise_safety_index"
    )
    out = {}
    for r in cur.fetchall():
        out[r["name_normalized"]] = dict(r)
    return out


def load_library_media(cur) -> Dict[str, dict]:
    cur.execute(
        "SELECT exercise_name, image_s3_path, video_s3_path"
        " FROM exercise_library"
    )
    out = {}
    for r in cur.fetchall():
        out[norm(r["exercise_name"])] = dict(r)
    return out


def media_ok(cache: dict, lib: Dict[str, dict], norm_name: str) -> bool:
    """A candidate only counts if its library row's media EXISTS on S3."""
    if norm_name in cache:
        return cache[norm_name]
    row = lib.get(norm_name)
    ok = False
    if row:
        for col in ("image_s3_path", "video_s3_path"):
            path = row.get(col)
            if path and object_exists(path):
                ok = True
                break
    cache[norm_name] = ok
    return ok


def pick_replacement(
    offender: dict, safety: Dict[str, dict], lib: Dict[str, dict],
    media_cache: dict,
) -> Optional[tuple]:
    """Return (candidate, tier_label) or None.

    Tiers, most-faithful first. body_part is a HARD filter in every tier — the
    safety index mis-tags a few movement_patterns ("Barbell Incline Shoulders
    Press (Inside Squat Cage)" is pattern='squat'), and body_part is what stops
    a shoulder press being offered as a squat regression. Equipment never goes
    UP: same equipment, or bodyweight.
    """
    pattern = offender.get("movement_pattern")
    equipment = (offender.get("equipment") or "").strip()
    off_tokens = tokens(offender["name"]) - _QUALIFIERS
    off_muscles = muscle_tokens(offender.get("target_muscle"))
    off_body = (offender.get("body_part") or "").lower()
    if not off_body:
        return None

    equipment_tiers = [equipment] if equipment else []
    if equipment.lower() != "bodyweight":
        equipment_tiers.append("Bodyweight")

    strength_offender = pattern in _STRENGTH_PATTERNS

    def base(c) -> bool:
        if c.get("safety_difficulty") != "beginner":
            return False
        if c["name_normalized"] == offender["name_normalized"]:
            return False
        if _JUNK_RE.search(c["name"] or ""):
            return False
        if strength_offender and c.get("movement_pattern") \
                not in _STRENGTH_PATTERNS:
            return False
        return True

    def rank(c):
        """Nearest same-movement regression, deterministically:
        shared movement words in the NAME first (a push-up is replaced by a
        push-up), then how much of the target musculature is shared (this is
        what separates 'Shoulders (Anterior Deltoids)' from 'Shoulders
        (Posterior Deltoids)'), then same movement_pattern, then the shortest
        — i.e. most canonical — name."""
        return (
            -len(off_tokens & (tokens(c["name"]) - _QUALIFIERS)),
            -len(off_muscles & muscle_tokens(c.get("target_muscle"))),
            0 if c.get("movement_pattern") == pattern else 1,
            0 if c.get("is_beginner_safe") else 1,
            len(c["name"]),
            c["name"],
        )

    for eq in equipment_tiers:
        pools = [
            # 1. same trained body part — the faithful regression.
            (f"same-bodypart/{eq}", [
                c for c in safety.values()
                if base(c)
                and (c.get("equipment") or "").lower() == eq.lower()
                and (c.get("body_part") or "").lower() == off_body
            ]),
            # 2. body_part has no beginner option at all (the index tags
            #    "Diamond Push-Up (On Knees)" as 'upper arms', whose whole
            #    beginner pool is stretches) — fall back to the same equipment
            #    + a real target-muscle overlap.
            (f"same-muscle/{eq}", [
                c for c in safety.values()
                if base(c)
                and (c.get("equipment") or "").lower() == eq.lower()
                and off_muscles & muscle_tokens(c.get("target_muscle"))
            ]),
        ]
        for label, pool in pools:
            for c in sorted(pool, key=rank):
                if media_ok(media_cache, lib, c["name_normalized"]):
                    return c, label
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--limit-media-checks", type=int, default=0,
                    help="0 = check every candidate considered")
    args = ap.parse_args()

    conn = psycopg2.connect(dsn())
    conn.autocommit = False
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    safety = load_safety(cur)
    lib = load_library_media(cur)
    media_cache: dict = {}

    cur.execute(OFFENDER_SQL)
    offender_rows = cur.fetchall()
    offenders = {}
    for r in offender_rows:
        si = safety.get(r["norm_name"])
        if not si or si.get("safety_difficulty") not in BAD_DIFFICULTY:
            continue
        offenders.setdefault(r["norm_name"], si)

    print(f"offending exercise names in beginner-badged programs: "
          f"{len(offenders)}")

    mapping: Dict[str, dict] = {}
    unmapped: List[str] = []
    for nn, si in sorted(offenders.items(), key=lambda kv: kv[1]["name"]):
        picked = pick_replacement(si, safety, lib, media_cache)
        if picked is None:
            unmapped.append(si["name"])
            continue
        rep, tier = picked
        mapping[nn] = rep
        print(f"  {si['name']:<40} [{si['safety_difficulty']}, "
              f"{si['movement_pattern']}, {si['equipment']}, "
              f"{si['body_part']}]"
              f"  ->  {rep['name']}  [{rep['equipment']}, "
              f"{rep['body_part']}]  ({tier})")
    if unmapped:
        print(f"\nNO beginner-safe same-movement replacement with live media "
              f"for: {unmapped}")

    if not mapping:
        print("nothing to do")
        return 1 if unmapped else 0

    # ---- rewrite ---------------------------------------------------------
    cur.execute(WEEK_SQL)
    weeks = cur.fetchall()
    swaps = 0
    touched_weeks = 0
    backup_rows: List[tuple] = []
    updates: List[tuple] = []

    for w in weeks:
        workouts = w["workouts"]
        if not isinstance(workouts, list):
            continue
        changed = False
        for si_idx, session in enumerate(workouts):
            if not isinstance(session, dict):
                continue
            for key in ("exercises", "warmup", "cooldown"):
                block = session.get(key)
                if not isinstance(block, list):
                    continue
                for ex_idx, ex in enumerate(block):
                    if not isinstance(ex, dict):
                        continue
                    nn = norm(ex.get("name") or "")
                    rep = mapping.get(nn)
                    if not rep:
                        continue
                    backup_rows.append((
                        w["id"], w["variant_id"], w["week_number"], si_idx,
                        key, ex_idx, ex.get("name"),
                        json.dumps(ex), rep["name"],
                    ))
                    ex["name"] = rep["name"]
                    if rep.get("equipment"):
                        ex["equipment"] = rep["equipment"]
                    ex["difficulty"] = "beginner"
                    if rep.get("body_part"):
                        ex["body_part"] = rep["body_part"]
                    # A substitution that points BACK at the advanced move (or
                    # at the new name) would reintroduce it on the swap sheet.
                    sub = ex.get("substitution")
                    if sub and norm(sub) in mapping:
                        ex["substitution"] = mapping[norm(sub)]["name"]
                    if sub and norm(sub) == norm(rep["name"]):
                        ex["substitution"] = None
                    changed = True
                    swaps += 1
        if changed:
            touched_weeks += 1
            updates.append((json.dumps(workouts), w["id"]))

    print(f"\nexercise entries to swap: {swaps} across {touched_weeks} "
          f"program_variant_weeks rows")
    if not args.apply:
        print("dry run — pass --apply to write")
        conn.rollback()
        return 0

    cur.execute("""
        CREATE TABLE IF NOT EXISTS program_variant_weeks_exercise_backup (
            id                bigserial PRIMARY KEY,
            week_row_id       uuid NOT NULL,
            variant_id        uuid,
            week_number       integer,
            session_index     integer,
            block             text,
            exercise_index    integer,
            original_name     text,
            original_exercise jsonb NOT NULL,
            replacement_name  text,
            reason            text DEFAULT 'row90_beginner_difficulty_swap',
            backed_up_at      timestamptz NOT NULL DEFAULT now()
        )
    """)
    psycopg2.extras.execute_batch(
        cur,
        "INSERT INTO program_variant_weeks_exercise_backup "
        "(week_row_id, variant_id, week_number, session_index, block, "
        " exercise_index, original_name, original_exercise, replacement_name) "
        "VALUES (%s,%s,%s,%s,%s,%s,%s,%s::jsonb,%s)",
        backup_rows, page_size=500,
    )
    psycopg2.extras.execute_batch(
        cur,
        "UPDATE program_variant_weeks SET workouts = %s::jsonb WHERE id = %s",
        updates, page_size=200,
    )
    conn.commit()
    print(f"backed up {len(backup_rows)} exercise objects; "
          f"updated {len(updates)} week rows")
    return 1 if unmapped else 0


if __name__ == "__main__":
    sys.exit(main())
