#!/usr/bin/env python3
"""Upload the 318 generated exercise images to S3 (parallel) and wire image_s3_path into the DB."""
import os, re, concurrent.futures, boto3, psycopg2
from psycopg2.extras import execute_values

BACKEND_ENV = "/Users/saichetangrandhe/AIFitnessCoach/backend/.env"
GENDIR = "/Users/saichetangrandhe/AIFitnessCoach/docs/planning/exercise-images/generated"
PREFIX = "ILLUSTRATIONS ALL/Generated/"

env = {}
for line in open(BACKEND_ENV):
    line = line.rstrip("\n")
    if "=" in line and not line.lstrip().startswith("#"):
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip('"').strip("'")

BUCKET = env["S3_BUCKET_NAME"]
s3 = boto3.client("s3", aws_access_key_id=env["AWS_ACCESS_KEY_ID"],
                  aws_secret_access_key=env["AWS_SECRET_ACCESS_KEY"],
                  region_name=env.get("AWS_DEFAULT_REGION", "us-east-1"))

def slug(n): return re.sub(r"[^a-z0-9]+", "_", n.lower().strip()).strip("_")

dsn = env["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://").replace("postgres+asyncpg://", "postgresql://")
conn = psycopg2.connect(dsn); conn.autocommit = True
cur = conn.cursor()
cur.execute("SELECT name FROM exercise_library_cleaned WHERE image_url IS NULL OR image_url=''")
names = [r[0] for r in cur.fetchall()]
print(f"{len(names)} exercises with no image in MV")

def upload(name):
    s = slug(name); p = os.path.join(GENDIR, s + ".png")
    if not os.path.exists(p):
        return (name, None, "no_png")
    key = PREFIX + s + ".png"
    s3.upload_file(p, BUCKET, key, ExtraArgs={"ContentType": "image/png"})
    return (name, f"s3://{BUCKET}/{key}", "ok")

results = []
with concurrent.futures.ThreadPoolExecutor(max_workers=16) as ex:
    for r in ex.map(upload, names):
        results.append(r)
ok = [(n, p) for n, p, st in results if st == "ok"]
missing = [n for n, p, st in results if st != "ok"]
print(f"uploaded {len(ok)} | missing PNG {len(missing)}: {missing[:10]}")

# Wire image_s3_path into both source tables (match on normalized exercise_name)
execute_values(cur,
    "UPDATE exercise_library_manual m SET image_s3_path=d.path "
    "FROM (VALUES %s) AS d(name,path) WHERE lower(btrim(m.exercise_name))=lower(btrim(d.name))",
    ok)
print(f"exercise_library_manual rows updated: {cur.rowcount}")
execute_values(cur,
    "UPDATE exercise_library e SET image_s3_path=d.path "
    "FROM (VALUES %s) AS d(name,path) WHERE lower(btrim(e.exercise_name))=lower(btrim(d.name)) "
    "AND (e.image_s3_path IS NULL OR e.image_s3_path='')",
    ok)
print(f"exercise_library (base) rows updated: {cur.rowcount}")

# Refresh the MV
try:
    cur.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY exercise_library_cleaned")
    print("MV refreshed (concurrently)")
except Exception as e:
    print("concurrent refresh failed, trying plain:", str(e)[:80])
    cur.execute("REFRESH MATERIALIZED VIEW exercise_library_cleaned")
    print("MV refreshed (plain)")

# Verify
cur.execute("SELECT COUNT(*) FROM exercise_library_cleaned WHERE image_url IS NULL OR image_url=''")
print(f"remaining no-image in MV after refresh: {cur.fetchone()[0]}")
conn.close()
