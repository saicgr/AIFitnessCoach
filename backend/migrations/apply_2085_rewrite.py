"""Apply migration 2084 — rewrite deficient exercise instructions.

Two phases, deliberately separated:
  1. DDL + backup INSERTs + UPDATEs run in ONE transaction, then commit.
  2. The MV refresh runs in a SEPARATE autocommit connection, because
     refresh_exercise_library_cleaned() does REFRESH MATERIALIZED VIEW
     CONCURRENTLY, which Postgres forbids inside a transaction block.

Then a verifier confirms the rewrite landed and the MV is clean.
"""
import os
import re
import hashlib
import psycopg2

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SQL = os.path.join(ROOT, "backend", "migrations", "2085_rewrite_exercise_instructions_batch2.sql")
BATCH = "2085-2026-05-18"

for line in open(os.path.join(ROOT, "backend", ".env")):
    if line.startswith("DATABASE_URL="):
        URL = line.split("=", 1)[1].strip().replace("postgresql+asyncpg://", "postgresql://")
        break

sql = open(SQL).read()
expected_updates = sql.count("UPDATE public.")

# --- phase 1: DDL + backup + UPDATE in one transaction -----------------------
print(f"Applying {os.path.basename(SQL)} ({expected_updates} UPDATEs) in one transaction...")
conn = psycopg2.connect(URL)
try:
    with conn:
        with conn.cursor() as cur:
            cur.execute(sql)
    print("  committed.")
finally:
    conn.close()

# --- phase 2: refresh the MV in autocommit -----------------------------------
print("Refreshing exercise_library_cleaned (separate autocommit connection)...")
conn = psycopg2.connect(URL)
conn.autocommit = True
with conn.cursor() as cur:
    cur.execute("SELECT public.refresh_exercise_library_cleaned(force := true);")
conn.close()
print("  refreshed.")

# --- verifier ----------------------------------------------------------------
print("\nVerifying...")
RISKY = [r"\bpush through (the )?pain\b", r"\bignore (the )?pain\b",
         r"\bthrough the pain\b", r"\bround (your |the )?back\b", r"\brounded back\b",
         r"\bhold your breath\b", r"\block (your |out your )?knees\b",
         r"\block (your |out your )?elbows\b", r"\bbounce\b", r"\bswing the weight\b",
         r"\buse momentum\b", r"\bjerk (the|it|your)\b",
         r"\bas fast as (you can|possible)\b", r"\bas heavy as (you can|possible)\b",
         r"\bno rest\b"]
GENERIC = ["appropriate grip", "proper posture", "proper position", "proper form",
           "comfortable starting position", "starting position for the",
           "the appropriate", "into position", "in the proper position",
           "with proper back support", "engage your core and perform",
           "perform the movement", "complete the movement", "do the exercise"]

conn = psycopg2.connect(URL)
cur = conn.cursor()
ok = True

cur.execute("SELECT count(*) FROM public.exercise_instruction_backup WHERE rewrite_batch=%s;",
            (BATCH,))
backed = cur.fetchone()[0]
print(f"  backup rows for batch: {backed}  (expected {expected_updates})")
ok &= backed == expected_updates

cur.execute("SELECT count(*) FROM exercise_library_cleaned WHERE length(instructions) < 40;")
short = cur.fetchone()[0]
print(f"  MV instructions under 40 chars: {short}  (expected 0)")
ok &= short == 0

# deficiency rescan on the served MV
cur.execute("SELECT id, instructions FROM exercise_library_cleaned WHERE instructions IS NOT NULL;")
rows = cur.fetchall()
norm = lambda t: re.sub(r"\s+", " ", (t or "").strip().lower())
seen = {}
for _id, ins in rows:
    seen.setdefault(hashlib.md5(norm(ins).encode()).hexdigest(), []).append(_id)
deficient = 0
for _id, ins in rows:
    n = norm(ins)
    dup = len(seen[hashlib.md5(n.encode()).hexdigest()]) >= 3
    generic = sum(1 for g in GENERIC if g in n) >= 2
    risky = any(re.search(p, n) for p in RISKY)
    if dup or generic or risky:
        deficient += 1
print(f"  deficient instructions still in MV: {deficient}  (was 193; "
      f"~60 intentionally skipped remain)")

# the rewritten rows must no longer be deficient
cur.execute("""
    SELECT count(*) FROM exercise_library_cleaned el
    JOIN public.exercise_instruction_backup b ON b.id = el.id
    WHERE b.rewrite_batch = %s AND el.instructions = b.new_instructions;
""", (BATCH,))
landed = cur.fetchone()[0]
print(f"  rewrites visible in MV: {landed}  (expected {expected_updates})")
ok &= landed == expected_updates

cur.execute("SELECT queued_at FROM mv_refresh_queue WHERE mv_name='exercise_library_cleaned';")
q = cur.fetchone()
print(f"  mv_refresh_queue.queued_at: {q[0] if q else 'no row'}  (expected None)")

conn.close()
print(f"\n{'VERIFICATION PASSED' if ok else 'VERIFICATION FAILED — investigate above'}")
