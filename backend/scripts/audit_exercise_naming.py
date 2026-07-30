"""Regression gate for exercise NAMING + MUSCLE-GROUP integrity across the four id-spaces.

Why this exists — E2E register rows #64 and #93.

An exercise's identity is spread over four tables that do not share a primary key:

    exercise_library        -- the user-visible catalogue (also the media source)
    exercise_demos          -- gendered demo media; `original_exercise_name` TRACKS THE
                               S3 OBJECT NAME, so it must NEVER be "corrected"
    exercise_canonical      -- the join key exercise_demos hangs off
    exercise_aliases        -- what resolve_exercise_demo_media() (mig 2290) keys on,
                               and therefore the only thing that keeps a corrected
                               display name pointing at its (uncorrected) S3 object

Three failure modes have shipped to users out of that split:

  MISSPELLING       "Calve Stretch From Wall To Floor" ("calve" is not a word).
  PLACEHOLDER_MUSCLE A bulk import stamped `Full Body (Multiple Muscle Groups)` on rows
                    it could not classify, so a calf stretch was labelled full-body.
  TWIN_DIVERGENCE   A `_female`/`_male` row disagreeing with its own base row about
                    which muscle it trains ("Cable Calve Raise_Female" claimed
                    Quadriceps + Glutes).
  ORPHAN_ALIAS      A display name with no exercise_aliases entry — its media only
                    resolves while the library row's own S3 path holds, with no
                    canonical/demos fallback.

Usage:
    cd backend && set -a && source ./.env && set +a && \
      .venv/bin/python scripts/audit_exercise_naming.py --check

`--check` exits 1 when any NEW finding appears. Known, deliberately-accepted findings
live in scripts/exercise_naming_baseline.json; refresh it with --refresh-baseline once
you have genuinely cleared or accepted the current set.

Read-only. Never writes to exercise_demos or to any *_s3_path.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

import psycopg2

BASELINE_PATH = Path(__file__).with_name("exercise_naming_baseline.json")

# Misspellings that have actually shipped, mapped to the correct spelling. Data, not
# logic — extend it whenever a new one is found rather than special-casing a row.
# "tricep"/"bicep" are deliberately NOT here: they are colloquial in fitness copy and
# ~58 catalogue rows use them intentionally. This list is for spellings that are simply
# wrong in any register.
MISSPELLINGS = {
    "calve": "calf",
    "calfs": "calves",
    "coners": "corners",
    "excercise": "exercise",
    "shoudler": "shoulder",
    "dumbell": "dumbbell",
    "dumbell's": "dumbbell",
    "kettlbell": "kettlebell",
    "barbel": "barbell",
    "streching": "stretching",
    "obliqe": "oblique",
}

# The value the importer writes when it could not classify a movement. Not a legitimate
# muscle group for anything that names a specific muscle in its own title.
PLACEHOLDER_MUSCLE = "Full Body (Multiple Muscle Groups)"

# Muscle words that, appearing in an exercise's own name, contradict PLACEHOLDER_MUSCLE.
NAMED_MUSCLES = (
    "calf", "calves", "quad", "quadricep", "hamstring", "glute", "chest", "pec",
    "lat", "trap", "delt", "shoulder", "bicep", "tricep", "forearm", "abs",
    "abdominal", "oblique", "hip flexor", "adductor", "abductor", "soleus",
    "gastrocnemius",
)

# `_female` / `_male` is glued on with an underscore and Postgres/Python word
# boundaries treat `_` as a word character, so every name predicate strips it first.
_GENDER_SUFFIX = re.compile(r"_(female|male)$", re.IGNORECASE)


def strip_gender(name: str) -> str:
    return _GENDER_SUFFIX.sub("", name or "")


def find_misspellings(name: str) -> list[str]:
    """Return the misspelled tokens present in `name` (gender suffix ignored)."""
    base = strip_gender(name).lower()
    hits = []
    for wrong in MISSPELLINGS:
        if re.search(rf"(?<![a-z]){re.escape(wrong)}(?![a-z])", base):
            hits.append(wrong)
    return hits


def names_a_muscle(name: str) -> str | None:
    base = strip_gender(name).lower()
    for muscle in NAMED_MUSCLES:
        if re.search(rf"(?<![a-z]){re.escape(muscle)}(?![a-z])", base):
            return muscle
    return None


def connect():
    dsn = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://")
    return psycopg2.connect(dsn)


def collect(cur) -> list[dict]:
    findings: list[dict] = []

    # ---- 1. MISSPELLING on the display sides only. --------------------------------
    # exercise_demos.original_exercise_name is deliberately NOT audited: it mirrors the
    # real S3 object key, and "fixing" it is exactly what killed 2,376 media rows in
    # July 2026. Correcting a display name is safe; correcting an S3-tracking name is not.
    cur.execute("SELECT id::text, exercise_name FROM exercise_library")
    for row_id, name in cur.fetchall():
        for wrong in find_misspellings(name):
            findings.append({
                "kind": "MISSPELLING",
                "table": "exercise_library",
                "id": row_id,
                "name": name,
                "detail": f"'{wrong}' should be '{MISSPELLINGS[wrong]}'",
            })

    cur.execute("SELECT exercise_id, locale, name FROM exercise_library_i18n WHERE locale = 'en'")
    for ex_id, locale, name in cur.fetchall():
        for wrong in find_misspellings(name):
            findings.append({
                "kind": "MISSPELLING",
                "table": "exercise_library_i18n",
                "id": f"{ex_id}:{locale}",
                "name": name,
                "detail": f"'{wrong}' should be '{MISSPELLINGS[wrong]}'",
            })

    # ---- 2. PLACEHOLDER_MUSCLE: the name names a muscle, the label says full body. --
    cur.execute(
        "SELECT id::text, exercise_name, target_muscle FROM exercise_library "
        "WHERE target_muscle = %s",
        (PLACEHOLDER_MUSCLE,),
    )
    for row_id, name, target in cur.fetchall():
        muscle = names_a_muscle(name)
        if muscle:
            findings.append({
                "kind": "PLACEHOLDER_MUSCLE",
                "table": "exercise_library",
                "id": row_id,
                "name": name,
                "detail": f"name says '{muscle}' but target_muscle is the import placeholder",
            })

    # ---- 3. TWIN_DIVERGENCE: a gendered twin contradicting its own base row. -------
    cur.execute(
        """
        SELECT s.id::text, s.exercise_name, s.target_muscle, b.target_muscle
        FROM exercise_library s
        JOIN exercise_library b
          ON b.exercise_name = regexp_replace(s.exercise_name, '_(female|male)$', '', 'i')
        WHERE s.exercise_name ~* '_(female|male)$'
          AND s.target_muscle IS DISTINCT FROM b.target_muscle
        """
    )
    for row_id, name, suffixed_target, base_target in cur.fetchall():
        findings.append({
            "kind": "TWIN_DIVERGENCE",
            "table": "exercise_library",
            "id": row_id,
            "name": name,
            "detail": f"twin says '{suffixed_target}', base row says '{base_target}'",
        })

    # ---- 4. ORPHAN_ALIAS: a display name the demo-media fallback cannot resolve. ----
    # Only checked for rows that HAVE a canonical/demos counterpart to fall back to —
    # i.e. where an exercise_demos row exists under some spelling of the same movement.
    cur.execute(
        """
        SELECT e.id::text, e.exercise_name
        FROM exercise_library e
        WHERE NOT EXISTS (
            SELECT 1 FROM exercise_aliases a
            WHERE a.alias_name_normalized = normalize_exercise_name(e.exercise_name)
        )
        AND EXISTS (
            SELECT 1 FROM exercise_canonical c
            JOIN exercise_demos d ON d.canonical_exercise_id = c.id
            WHERE lower(regexp_replace(c.canonical_name, '[^a-zA-Z0-9]+', '', 'g'))
                = lower(regexp_replace(e.exercise_name, '[^a-zA-Z0-9]+', '', 'g'))
        )
        """
    )
    for row_id, name in cur.fetchall():
        findings.append({
            "kind": "ORPHAN_ALIAS",
            "table": "exercise_aliases",
            "id": row_id,
            "name": name,
            "detail": "demo media exists for this movement but no alias maps the name to it",
        })

    return findings


def key(f: dict) -> str:
    return f"{f['kind']}|{f['table']}|{f['id']}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="exit 1 on NEW findings")
    ap.add_argument("--refresh-baseline", action="store_true")
    ap.add_argument("--all", action="store_true", help="print baselined findings too")
    args = ap.parse_args()

    with connect() as conn:
        with conn.cursor() as cur:
            findings = collect(cur)

    baseline = set()
    if BASELINE_PATH.exists():
        baseline = set(json.loads(BASELINE_PATH.read_text()).get("accepted", []))

    if args.refresh_baseline:
        BASELINE_PATH.write_text(
            json.dumps({"accepted": sorted(key(f) for f in findings)}, indent=2) + "\n"
        )
        print(f"baseline refreshed: {len(findings)} accepted findings")
        return 0

    new = [f for f in findings if key(f) not in baseline]
    shown = findings if args.all else new

    by_kind: dict[str, int] = {}
    for f in findings:
        by_kind[f["kind"]] = by_kind.get(f["kind"], 0) + 1
    print(f"total findings: {len(findings)}  {by_kind}")
    print(f"baselined: {len(findings) - len(new)}   NEW: {len(new)}")

    for f in sorted(shown, key=key):
        print(f"  [{f['kind']}] {f['table']} {f['name']!r} — {f['detail']}")

    if args.check and new:
        print(
            "\nFAIL: new exercise-naming findings. Fix the display side "
            "(exercise_library / exercise_library_i18n) and add an exercise_aliases "
            "row for BOTH spellings. Never rename exercise_demos.original_exercise_name "
            "or any *_s3_path — those track the S3 object."
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
