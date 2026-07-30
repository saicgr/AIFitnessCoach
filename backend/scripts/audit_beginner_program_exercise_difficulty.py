#!/usr/bin/env python3
"""Gate: a BEGINNER-badged published program must not prescribe an exercise the
safety index rates advanced/elite (E2E register row 90).

The badge is a promise. "Gentle Start" is sold for true beginners, postpartum
and over-50 users; shipping Archer Push-Up (safety_difficulty='advanced',
shoulder_safe=false, wrist_safe=false) in all 8 weeks of its default variant
breaks that promise before any per-user customization runs — and the preview
Schedule tab renders exactly this raw content.

    cd backend && set -a && source ./.env && set +a && \
      .venv/bin/python scripts/audit_beginner_program_exercise_difficulty.py --check

Exit 1 = at least one beginner-badged published program contains an
advanced/elite exercise. Repair with
scripts/fix_beginner_program_exercise_difficulty.py --apply.

Run after ANY program generation / ingest / variant regeneration.
"""
from __future__ import annotations

import argparse
import os
import sys

import psycopg2

SQL = """
WITH beg AS (
  SELECT p.id AS program_id, p.program_name, v.id AS variant_id,
         (v.id = p.default_variant_id) AS is_default
  FROM programs p
  JOIN program_variants v ON v.base_program_id = p.variant_base_id
  WHERE p.is_published AND lower(p.difficulty_level) = 'beginner'
), ex AS (
  SELECT b.program_name, b.is_default, w.week_number,
         e->>'name' AS raw_name,
         lower(regexp_replace(e->>'name', '[^a-zA-Z0-9]', '', 'g')) AS norm
  FROM beg b
  JOIN program_variant_weeks w ON w.variant_id = b.variant_id,
  LATERAL jsonb_array_elements(w.workouts) s,
  LATERAL jsonb_array_elements(
      COALESCE(s->'exercises', '[]'::jsonb)
      || COALESCE(s->'warmup', '[]'::jsonb)
      || COALESCE(s->'cooldown', '[]'::jsonb)
  ) e
)
SELECT ex.program_name, ex.raw_name, si.name, si.safety_difficulty,
       count(*) AS occurrences,
       count(*) FILTER (WHERE ex.is_default) AS in_default_variant
FROM ex
JOIN exercise_safety_index si ON si.name_normalized = ex.norm
WHERE si.safety_difficulty IN ('advanced', 'elite')
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC
"""


def dsn() -> str:
    d = os.environ.get("DATABASE_URL", "")
    if not d:
        print("DATABASE_URL is not set", file=sys.stderr)
        sys.exit(2)
    d = d.replace("postgresql+asyncpg://", "postgresql://")
    if "sslmode" not in d:
        d += ("&" if "?" in d else "?") + "sslmode=require"
    return d


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.parse_args()

    conn = psycopg2.connect(dsn())
    try:
        with conn.cursor() as cur:
            cur.execute(SQL)
            rows = cur.fetchall()
    finally:
        conn.close()

    if not rows:
        print("OK — no beginner-badged published program prescribes an "
              "advanced/elite exercise.")
        return 0

    programs = sorted({r[0] for r in rows})
    print(f"FAIL — {len(rows)} (program, exercise) pairs across "
          f"{len(programs)} beginner-badged programs:")
    for r in rows:
        print(f"  {r[0]:<44} {r[1]:<38} -> {r[2]} [{r[3]}] "
              f"x{r[4]} ({r[5]} in default variant)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
