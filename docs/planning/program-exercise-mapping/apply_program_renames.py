#!/usr/bin/env python3
"""
Apply program_full_map.txt to the actual program data: rename every exercise name
inside the 18 published programs (ALL their variant weeks + the 2 base-blob programs)
to the canonical library name, so program exercises match exercise_library /
exercise_library_manual exactly.

- mapped lines  "raw -> Target"   : rename raw -> Target (strip trailing " (verify...)")
- NEW lines     "raw -> NEW"       : rename raw -> NEW_CANON[raw] (the just-inserted canonical)
- SKIP lines    "raw -> SKIP"      : leave unchanged

Matching is by normalize_exercise_name (DB function) so every raw casing/plural variant
in the program JSON maps correctly.

Backs up program_variant_weeks before mutating.

  python apply_program_renames.py            # dry-run (counts + samples)
  python apply_program_renames.py --apply    # backup + rewrite JSONB
"""
import os, sys, json, psycopg2
from psycopg2.extras import Json

BASE = os.path.dirname(os.path.abspath(__file__))
ENV = os.path.join(BASE, "..", "..", "..", "backend", ".env")
MAP = os.path.join(BASE, "..", "..", "..", "program_full_map.txt")
APPLY = "--apply" in sys.argv

NEW_CANON = {
 "Bird Dog Row":"Bird Dog Row","Bird Dog with Elbow to Knee":"Bird Dog Crunch",
 "Bird-Dog Crunch":"Bird Dog Crunch","Bird-Dog Plank":"Bird Dog Plank",
 "Bridge with Reach":"Glute Bridge with Overhead Reach","Doorway Rows":"Doorway Row",
 "Downward Dog to Plank Flow":"Plank to Downward Dog Flow","Downward Dog with Twist":"Downward Dog with Twist",
 "Dumbbell Walking Lunge":"Dumbbell Walking Lunge","EZ Bar Skull Crushers":"EZ Bar Skullcrusher",
 "EZ Bar Skullcrushers":"EZ Bar Skullcrusher","Glute Bridge Hold":"Glute Bridge Hold",
 "Glute Bridge Pulse":"Glute Bridge Pulse","Glute Ham Raise":"Glute Ham Raise",
 "Glute Squeeze Hinge":"Standing Hip Hinge","Goddess Pose":"Goddess Pose",
 "Hanging Toes-to-Bar":"Toes to Bar","High Lunge":"High Lunge","High Lunge Twist":"High Lunge with Twist",
 "High Plank to Down Dog Flow":"Plank to Downward Dog Flow","Kettlebell Romanian Deadlift":"Kettlebell Romanian Deadlift",
 "Kettlebell Walking Lunge":"Kettlebell Walking Lunge","Lateral Plank Walk":"Lateral Plank Walk",
 "Modified Plank":"Kneeling Plank","Modified Side Plank":"Kneeling Side Plank",
 "Plank Rotations":"Plank Rotation","Plank T-Rotations":"Plank Rotation",
 "Plank to Down Dog":"Plank to Downward Dog Flow","Plank to Downward Dog":"Plank to Downward Dog Flow",
 "Plank with Plate":"Weighted Plank","Plank with Weight":"Weighted Plank",
 "Prone Hip Extension":"Prone Hip Extension","Pyramid Pose":"Pyramid Pose","Quadruped Reach":"Quadruped Reach",
 "Reverse Snow Angels":"Reverse Snow Angel","Safety Bar Squat":"Safety Bar Squat","Shuttle Run":"Shuttle Run",
 "Side Plank Rotations":"Side Plank Rotation","Single Leg Balance":"Single-Leg Balance",
 "Single Leg Box Squat":"Single-Leg Box Squat","Staff Pose":"Staff Pose","Standing Hip Hinge":"Standing Hip Hinge",
 "Sumo Squat Pulse":"Sumo Squat Pulse","Sumo Squat Pulses":"Sumo Squat Pulse","Swimming":"Swimming",
 "Toes to Bar":"Toes to Bar","Weighted Chin-Ups":"Weighted Chin-Up","Weighted Pull Up":"Weighted Pull-Up",
 "Weighted Pull Ups":"Weighted Pull-Up","Weighted Walking Lunge":"Weighted Walking Lunge",
}

def strip_verify(t):
    i = t.find(" (verify")
    return t[:i].strip() if i >= 0 else t.strip()

def load_raw_to_target():
    r2t = {}
    for ln in open(MAP):
        ln = ln.rstrip("\n")
        if " -> " not in ln: continue
        raw, tgt = ln.split(" -> ", 1)
        raw = raw.strip(); tgt = tgt.strip()
        if tgt == "SKIP": continue
        if tgt == "NEW":
            c = NEW_CANON.get(raw)
            if c: r2t[raw] = c
        else:
            r2t[raw] = strip_verify(tgt)
    return r2t

env = {}
for line in open(ENV):
    line = line.rstrip("\n")
    if "=" in line and not line.lstrip().startswith("#"):
        k, v = line.split("=", 1); env[k.strip()] = v.strip().strip('"').strip("'")
dsn = env["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://").replace("postgres+asyncpg://", "postgresql://")

def main():
    r2t = load_raw_to_target()
    conn = psycopg2.connect(dsn); conn.autocommit = False; cur = conn.cursor()

    # Build norm -> target using the DB normalizer on the map's raw keys.
    cur.execute("SELECT k, normalize_exercise_name(k) FROM unnest(%s::text[]) k", (list(r2t.keys()),))
    n2t = {}
    for raw, norm in cur.fetchall():
        n2t[norm] = r2t[raw]   # raw keys with same norm should map to same target

    # 18 published programs' variant ids + base-blob program ids
    cur.execute("SELECT id, variant_base_id, default_variant_id FROM programs WHERE is_published AND has_workouts")
    pubs = cur.fetchall()
    vbase = [r[1] for r in pubs if r[1]]
    cur.execute("SELECT pvw.id, pvw.workouts FROM program_variant_weeks pvw "
                "JOIN program_variants pv ON pv.id=pvw.variant_id WHERE pv.base_program_id = ANY(%s::uuid[])", (vbase,))
    vw_rows = cur.fetchall()
    base_ids = [r[0] for r in pubs if r[2] is None]
    cur.execute("SELECT id, workouts FROM programs WHERE id = ANY(%s::uuid[])", (base_ids,))
    base_rows = cur.fetchall()

    # normalizer cache for instance names (one DB call for all distinct names)
    names = set()
    def walk(workouts, key):
        for w in (workouts or []):
            for ex in (w.get("exercises") or []):
                nm = ex.get(key)
                if nm: names.add(nm)
    for _id, wk in vw_rows: walk(wk, "name")
    for _id, wk in base_rows:
        inner = (wk or {}).get("workouts") if isinstance(wk, dict) else None
        walk(inner, "exercise_name")
    cur.execute("SELECT k, normalize_exercise_name(k) FROM unnest(%s::text[]) k", (list(names),))
    name_norm = {k: n for k, n in cur.fetchall()}

    def target_for(nm):
        t = n2t.get(name_norm.get(nm, ""))
        return t if (t and t != nm) else None

    renamed_instances = 0
    distinct_changed = {}
    vw_updates, base_updates = [], []
    for _id, wk in vw_rows:
        changed = False
        for w in (wk or []):
            for ex in (w.get("exercises") or []):
                t = target_for(ex.get("name"))
                if t:
                    distinct_changed[ex["name"]] = t; ex["name"] = t; renamed_instances += 1; changed = True
        if changed: vw_updates.append((_id, wk))
    for _id, wk in base_rows:
        inner = (wk or {}).get("workouts") if isinstance(wk, dict) else None
        changed = False
        for w in (inner or []):
            for ex in (w.get("exercises") or []):
                t = target_for(ex.get("exercise_name"))
                if t:
                    distinct_changed[ex["exercise_name"]] = t; ex["exercise_name"] = t; renamed_instances += 1; changed = True
        if changed: base_updates.append((_id, wk))

    print(f"map entries={len(r2t)} norm_keys={len(n2t)} instance_names={len(names)}")
    print(f"variant_week rows to update={len(vw_updates)}  base-blob rows={len(base_updates)}")
    print(f"instances renamed={renamed_instances}  distinct names changed={len(distinct_changed)}")
    for a, b in list(sorted(distinct_changed.items()))[:25]:
        print(f"   {a!r} -> {b!r}")
    if not APPLY:
        print("\nDRY RUN — re-run with --apply to back up + rewrite.")
        return

    cur.execute("DROP TABLE IF EXISTS program_variant_weeks_bak_prerename")
    cur.execute("CREATE TABLE program_variant_weeks_bak_prerename AS TABLE program_variant_weeks")
    cur.execute("DROP TABLE IF EXISTS programs_workouts_bak_prerename")
    cur.execute("CREATE TABLE programs_workouts_bak_prerename AS SELECT id, workouts FROM programs WHERE id = ANY(%s::uuid[])", (base_ids,))
    for _id, wk in vw_updates:
        cur.execute("UPDATE program_variant_weeks SET workouts=%s WHERE id=%s", (Json(wk), _id))
    for _id, wk in base_updates:
        cur.execute("UPDATE programs SET workouts=%s WHERE id=%s", (Json(wk), _id))
    conn.commit()
    print(f"APPLIED. backed up to *_bak_prerename. updated {len(vw_updates)} variant-week rows, {len(base_updates)} base rows.")
    conn.close()

if __name__ == "__main__":
    main()
