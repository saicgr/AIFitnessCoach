#!/usr/bin/env python3
"""
Insert the 38 NEW canonical exercises into exercise_library_manual with FULL columns
(instructions, secondary_muscles, body_part, movement metadata, timing) + upload their
branded PNGs to S3 and set image_s3_path. Then refresh the MV.

Merges:
  new50_candidates.json  (name, slug, equipment, target_muscle, category, type, style,
                          is_dynamic_stretch, impact_level)
  scratchpad/specs_A.json, specs_B.json, specs_C.json  (by slug: instructions,
                          secondary_muscles, body_part, difficulty_level,
                          movement_pattern, mechanic_type, force_type)

Usage:
  python insert_new50.py           # dry-run (prints plan, validates merge)
  python insert_new50.py --apply   # upload + insert + refresh MV
"""
import os, sys, json, glob, boto3, psycopg2

BASE = os.path.dirname(os.path.abspath(__file__))
ENV = os.path.join(BASE, "..", "..", "..", "backend", ".env")
GENDIR = os.path.join(BASE, "generated")
SCRATCH = "/private/tmp/claude-501/-Users-saichetangrandhe-AIFitnessCoach/f5849052-d9f1-4c6f-8fb7-f383628dc68b/scratchpad"
PREFIX = "ILLUSTRATIONS ALL/Generated/"
APPLY = "--apply" in sys.argv

env = {}
for line in open(ENV):
    line = line.rstrip("\n")
    if "=" in line and not line.lstrip().startswith("#"):
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")
BUCKET = env["S3_BUCKET_NAME"]
dsn = env["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://").replace("postgres+asyncpg://", "postgresql://")

def timing(typ):
    if typ in ("static-stretch", "yoga", "smr"):
        return {"is_timed": True, "default_hold_seconds": 45 if typ == "smr" else 30,
                "hold_seconds_min": 20, "hold_seconds_max": 60}
    if typ == "raise":
        return {"is_timed": True, "default_duration_seconds": 30}
    if typ == "potentiate":
        return {"is_timed": False, "default_rep_range_min": 5, "default_rep_range_max": 8}
    if typ == "activate":
        return {"is_timed": False, "default_rep_range_min": 10, "default_rep_range_max": 15}
    return {"is_timed": False, "default_rep_range_min": 8, "default_rep_range_max": 12}

def load_specs():
    specs = {}
    for f in ("specs_A.json", "specs_B.json", "specs_C.json"):
        p = os.path.join(SCRATCH, f)
        for o in json.load(open(p)):
            specs[o["slug"]] = o
    return specs

def main():
    cands = json.load(open(os.path.join(BASE, "new50_candidates.json")))
    specs = load_specs()
    conn = psycopg2.connect(dsn); conn.autocommit = True; cur = conn.cursor()

    rows, missing_spec, missing_png, already = [], [], [], []
    for c in cands:
        slug = c["slug"]
        s = specs.get(slug)
        png = os.path.join(GENDIR, slug + ".png")
        if not s: missing_spec.append(slug); continue
        if not os.path.exists(png): missing_png.append(slug); continue
        cur.execute("SELECT 1 FROM exercise_library WHERE lower(btrim(exercise_name))=lower(btrim(%s)) "
                    "UNION SELECT 1 FROM exercise_library_manual WHERE lower(btrim(exercise_name))=lower(btrim(%s))",
                    (c["name"], c["name"]))
        if cur.fetchone(): already.append(c["name"]); continue
        rows.append((c, s, png))

    print(f"candidates={len(cands)} ready={len(rows)} missing_spec={missing_spec} "
          f"missing_png={missing_png} already_exist={already}")
    if not APPLY:
        print("\nDRY RUN — re-run with --apply to upload + insert.")
        for c, s, _ in rows[:3]:
            print("  sample:", c["name"], "|", s["body_part"], "|", s["movement_pattern"], "|", s["instructions"][:70], "...")
        return

    s3 = boto3.client("s3", aws_access_key_id=env["AWS_ACCESS_KEY_ID"],
                      aws_secret_access_key=env["AWS_SECRET_ACCESS_KEY"],
                      region_name=env.get("AWS_DEFAULT_REGION", "us-east-1"))
    n = 0
    for c, s, png in rows:
        key = PREFIX + c["slug"] + ".png"
        s3.upload_file(png, BUCKET, key, ExtraArgs={"ContentType": "image/png"})
        cols = {
            "exercise_name": c["name"], "body_part": s["body_part"], "equipment": c["equipment"],
            "target_muscle": c["target_muscle"], "secondary_muscles": s["secondary_muscles"],
            "instructions": s["instructions"], "difficulty_level": s["difficulty_level"],
            "category": c["category"], "image_s3_path": f"s3://{BUCKET}/{key}",
            "movement_pattern": s["movement_pattern"], "mechanic_type": s["mechanic_type"],
            "force_type": s["force_type"], "is_dynamic_stretch": bool(c["is_dynamic_stretch"]),
            "impact_level": c["impact_level"],
        }
        cols.update(timing(c["type"]))
        keys = list(cols.keys())
        cur.execute(f"INSERT INTO exercise_library_manual ({', '.join(keys)}) "
                    f"VALUES ({', '.join(['%s']*len(keys))})", [cols[k] for k in keys])
        n += 1
        print(f"  + {c['name']:<34} -> {key}")
    print(f"\ninserted {n}. refreshing MV...")
    try:
        cur.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned")
    except Exception:
        cur.execute("REFRESH MATERIALIZED VIEW exercise_library_cleaned")
    print("MV refreshed."); conn.close()

if __name__ == "__main__":
    main()
