#!/usr/bin/env python3
"""
Upload generated branded PNGs for the NEW warmup/stretch/yoga/mobility moves and INSERT them
as first-class rows in exercise_library_manual (with full metadata), then refresh the MV.

Only inserts moves that (a) have a generated PNG that passed/review QA and (b) do NOT already
exist by name in exercise_library / exercise_library_manual.

Run AFTER run_pipeline bulk completes:
  python insert_candidates.py            # dry-run (prints plan)
  python insert_candidates.py --apply    # upload + insert + refresh MV
"""
import os, re, sys, json, glob, boto3, psycopg2
from psycopg2.extras import execute_values

BASE = os.path.dirname(os.path.abspath(__file__))
ENV = os.path.join(BASE, "..", "..", "..", "backend", ".env")
GENDIR = os.path.join(BASE, "generated")
PREFIX = "ILLUSTRATIONS ALL/Generated/"
def _arg(flag, default):
    return sys.argv[sys.argv.index(flag) + 1] if flag in sys.argv else default
CANDS = os.path.join(BASE, _arg("--candidates", "missing_warmup_stretch_candidates.json"))
RESULTS = os.path.join(BASE, _arg("--results", "results_candidates"))
APPLY = "--apply" in sys.argv

env = {}
for line in open(ENV):
    line = line.rstrip("\n")
    if "=" in line and not line.lstrip().startswith("#"):
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")

BUCKET = env["S3_BUCKET_NAME"]
s3 = boto3.client("s3", aws_access_key_id=env["AWS_ACCESS_KEY_ID"],
                  aws_secret_access_key=env["AWS_SECRET_ACCESS_KEY"],
                  region_name=env.get("AWS_DEFAULT_REGION", "us-east-1"))
dsn = env["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://").replace("postgres+asyncpg://", "postgresql://")
conn = psycopg2.connect(dsn); conn.autocommit = True
cur = conn.cursor()

# body_part from target muscle keywords (best-effort; image resolution is by name anyway)
BP = [
    ("calf","lower legs"),("calves","lower legs"),("tibialis","lower legs"),("soleus","lower legs"),("ankle","lower legs"),
    ("hamstring","upper legs"),("quad","upper legs"),("glute","upper legs"),("adductor","upper legs"),("hip","upper legs"),
    ("piriformis","upper legs"),("psoas","upper legs"),("tensor","upper legs"),("knee","upper legs"),
    ("pec","chest"),("chest","chest"),("lat","back"),("trap","back"),("scapula","back"),("rhomboid","back"),
    ("erector","back"),("lumborum","back"),("lower back","back"),("spine","back"),("thoracic","back"),
    ("delt","shoulders"),("shoulder","shoulders"),("rotator","shoulders"),
    ("tricep","upper arms"),("bicep","upper arms"),("forearm","lower arms"),("wrist","lower arms"),
    ("neck","neck"),("scalene","neck"),("levator","neck"),("suboccipital","neck"),("serratus","chest"),
    ("ab","waist"),("core","waist"),("oblique","waist"),("full body","cardio"),
]
def body_part(target):
    t = (target or "").lower()
    for kw, bp in BP:
        if kw in t:
            return bp
    return "cardio"

def timing_cols(typ, dyn):
    """Return dict of timing columns by movement type."""
    if typ in ("static-stretch", "yoga", "smr"):
        return {"is_timed": True, "default_hold_seconds": 45 if typ == "smr" else 30,
                "hold_seconds_min": 20, "hold_seconds_max": 60}
    if typ == "raise":
        return {"is_timed": True, "default_duration_seconds": 30}
    if typ == "potentiate":
        return {"is_timed": False, "default_rep_range_min": 5, "default_rep_range_max": 8}
    if typ == "activate":
        return {"is_timed": False, "default_rep_range_min": 10, "default_rep_range_max": 15}
    # mobilize (dynamic drills)
    return {"is_timed": False, "default_rep_range_min": 8, "default_rep_range_max": 12}

DIFF = {"potentiate": "intermediate"}  # everything else beginner

def generated_ok():
    """slugs whose generated image cleared QA (pass/review)."""
    ok = set()
    for f in glob.glob(os.path.join(RESULTS, "worker_*.jsonl")):
        for ln in open(f):
            try:
                j = json.loads(ln)
                if j.get("verdict") in ("pass", "review") and j.get("generated"):
                    ok.add(j["fn"][:-4] if j["fn"].endswith(".png") else j["fn"])
            except Exception:
                pass
    return ok

def lookup_existing(name):
    """Return (table, has_image) for an exact-name row, else None."""
    for table in ("exercise_library", "exercise_library_manual"):
        cur.execute(f"SELECT (image_s3_path IS NOT NULL AND image_s3_path<>'') FROM {table} "
                    "WHERE lower(btrim(exercise_name))=lower(btrim(%s)) LIMIT 1", (name,))
        row = cur.fetchone()
        if row is not None:
            return (table, bool(row[0]))
    return None

def main():
    cands = json.load(open(CANDS))
    ok = generated_ok()
    to_insert, to_update, skip_noimg, skip_has_img = [], [], [], []
    for c in cands:
        slug = c["slug"]; png = os.path.join(GENDIR, slug + ".png")
        if slug not in ok or not os.path.exists(png):
            skip_noimg.append(c["name"]); continue
        ex = lookup_existing(c["name"])
        if ex is None:
            to_insert.append(c)
        elif not ex[1]:               # row exists but has NO image -> update it
            c["_table"] = ex[0]; to_update.append(c)
        else:
            skip_has_img.append(c["name"])

    print(f"candidates={len(cands)}  generated_ok={len(ok)}  to_insert={len(to_insert)}  "
          f"to_update={len(to_update)}  skip_no_image={len(skip_noimg)}  skip_has_image={len(skip_has_img)}")
    if skip_noimg: print("  no image yet:", skip_noimg)
    if to_update: print("  will UPDATE image on existing rows:", [c["name"] for c in to_update])
    if skip_has_img: print("  already imaged:", skip_has_img)
    if not APPLY:
        print("\nDRY RUN — re-run with --apply to upload + insert.")
        return

    inserted = 0
    for c in to_insert:
        slug = c["slug"]; png = os.path.join(GENDIR, slug + ".png")
        key = PREFIX + slug + ".png"
        s3.upload_file(png, BUCKET, key, ExtraArgs={"ContentType": "image/png"})
        s3path = f"s3://{BUCKET}/{key}"
        cols = {
            "exercise_name": c["name"], "body_part": body_part(c["target_muscle"]),
            "equipment": c["equipment"], "target_muscle": c["target_muscle"],
            "category": c["category"], "image_s3_path": s3path,
            "is_dynamic_stretch": bool(c["is_dynamic_stretch"]),
            "impact_level": c["impact_level"],
            "difficulty_level": c.get("difficulty") or DIFF.get(c["type"], "beginner"),
        }
        cols.update(timing_cols(c["type"], c["is_dynamic_stretch"]))
        keys = list(cols.keys())
        cur.execute(
            f"INSERT INTO exercise_library_manual ({', '.join(keys)}) VALUES ({', '.join(['%s']*len(keys))})",
            [cols[k] for k in keys])
        inserted += 1
        print(f"  + {c['name']:<32} [{c['type']}] -> {key}")

    updated = 0
    for c in to_update:
        slug = c["slug"]; png = os.path.join(GENDIR, slug + ".png")
        key = PREFIX + slug + ".png"
        s3.upload_file(png, BUCKET, key, ExtraArgs={"ContentType": "image/png"})
        s3path = f"s3://{BUCKET}/{key}"
        cur.execute(f"UPDATE {c['_table']} SET image_s3_path=%s "
                    "WHERE lower(btrim(exercise_name))=lower(btrim(%s)) AND (image_s3_path IS NULL OR image_s3_path='')",
                    (s3path, c["name"]))
        updated += cur.rowcount
        print(f"  ~ {c['name']:<32} [{c['type']}] UPDATE {c['_table']} -> {key}")

    print(f"\ninserted {inserted} rows, updated {updated} rows. refreshing MV...")
    try:
        cur.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned")
        print("MV refreshed (concurrently)")
    except Exception as e:
        print("concurrent refresh failed, plain:", str(e)[:80])
        cur.execute("REFRESH MATERIALIZED VIEW exercise_library_cleaned")
        print("MV refreshed (plain)")
    conn.close()

if __name__ == "__main__":
    main()
