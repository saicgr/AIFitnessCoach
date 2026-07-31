#!/usr/bin/env python3
"""
Task B6 final step — write exercise_demos rows for all 125 canonical exercises
that had neither an image nor a video demo.

Reads missing_125_bridge_plan.json (built by missing_125_bridge.py):
  - action == "bridge":   image already generated + QA-passed + uploaded to S3
                           under the OLD exercise_library pipeline run (same slug).
                           Zero spend -- just write the DB row.
  - action == "generate": needs the freshly generated PNG from
                           results_missing125/worker_0.jsonl (pass/review verdict).
                           Uploads to S3 if not already there, then writes the row.

Upserts on (canonical_exercise_id, demo_gender) -- the table's real unique
constraint -- demo_gender='neutral' throughout (matches the other 1828 neutral
rows already in the table; this is an androgynous ecorche illustration, one
render covers all genders).

Run:
  python insert_missing_125.py            # dry-run (prints plan)
  python insert_missing_125.py --apply    # upload + upsert
"""
import os, sys, json, glob, boto3, psycopg2

BASE = os.path.dirname(os.path.abspath(__file__))
ENV = os.path.join(BASE, "..", "..", "..", "backend", ".env")
GENDIR = os.path.join(BASE, "generated")
PLAN = os.path.join(BASE, "missing_125_bridge_plan.json")
RESULTS = os.path.join(BASE, "results_missing125")
PREFIX = "ILLUSTRATIONS ALL/Generated/"
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


def load_gen_verdicts():
    v = {}
    for f in glob.glob(os.path.join(RESULTS, "worker_*.jsonl")):
        for ln in open(f):
            try:
                j = json.loads(ln)
                v[j["fn"]] = j  # last record wins (resumable reruns append)
            except Exception:
                pass
    return v


def s3_exists(key):
    try:
        s3.head_object(Bucket=BUCKET, Key=key)
        return True
    except Exception:
        return False


def main():
    plan = json.load(open(PLAN))
    verdicts = load_gen_verdicts()

    ready, not_ready = [], []
    for row in plan:
        fn = row["filename"]
        if row["action"] == "bridge":
            key = PREFIX + fn
            row["_key"] = key
            row["_upload"] = False
            ready.append(row)
        else:
            v = verdicts.get(fn)
            if v and v.get("verdict") in ("pass", "review") and os.path.exists(os.path.join(GENDIR, fn)):
                key = PREFIX + fn
                row["_key"] = key
                row["_upload"] = True
                row["_verdict"] = v["verdict"]
                ready.append(row)
            else:
                row["_verdict"] = v.get("verdict") if v else "not_attempted"
                row["_notes"] = v.get("notes", "") if v else ""
                not_ready.append(row)

    print(f"plan={len(plan)}  ready={len(ready)}  not_ready={len(not_ready)}")
    for r in not_ready:
        print(f"  NOT READY: {r['name']:<45} verdict={r.get('_verdict')}  notes={r.get('_notes','')[:80]}")

    if not APPLY:
        print("\nDRY RUN -- re-run with --apply to upload + upsert.")
        return

    conn = psycopg2.connect(dsn); conn.autocommit = True
    cur = conn.cursor()

    uploaded, upserted = 0, 0
    seen_keys = set()
    for row in ready:
        key = row["_key"]
        if row["_upload"] and key not in seen_keys:
            path = os.path.join(GENDIR, row["filename"])
            if not s3_exists(key):
                s3.upload_file(path, BUCKET, key, ExtraArgs={"ContentType": "image/png"})
                uploaded += 1
                print(f"  uploaded -> {key}")
        seen_keys.add(key)
        s3path = f"s3://{BUCKET}/{key}"
        cur.execute(
            """
            INSERT INTO exercise_demos (canonical_exercise_id, demo_gender, image_s3_path, original_exercise_name)
            VALUES (%s, 'neutral', %s, %s)
            ON CONFLICT (canonical_exercise_id, demo_gender)
            DO UPDATE SET image_s3_path = EXCLUDED.image_s3_path
            WHERE exercise_demos.image_s3_path IS NULL OR exercise_demos.image_s3_path = ''
            """,
            (row["canonical_exercise_id"], s3path, row["name"]),
        )
        upserted += cur.rowcount
        print(f"  + {row['name']:<45} [{row['action']:8}] -> {key}")

    print(f"\nuploaded {uploaded} new S3 objects, upserted {upserted} exercise_demos rows.")
    conn.close()


if __name__ == "__main__":
    main()
