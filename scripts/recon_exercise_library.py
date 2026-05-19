"""Reconnaissance only: inspect the exercise library before any safety audit.

Read-only. Materialized views are NOT in information_schema.tables, so this
also checks pg_matviews. Inspects the base + manual tables and the MV.
"""
import os
import re
import psycopg2

with open(os.path.join(os.path.dirname(__file__), "..", "backend", ".env")) as f:
    for line in f:
        if line.startswith("DATABASE_URL="):
            raw = line.split("=", 1)[1].strip()
            break
url = raw.replace("postgresql+asyncpg://", "postgresql://")

conn = psycopg2.connect(url)
cur = conn.cursor()

print("=== materialized views ===")
cur.execute("SELECT matviewname FROM pg_matviews WHERE schemaname='public' ORDER BY matviewname;")
for (m,) in cur.fetchall():
    print(f"  {m}")

# Inspect the relevant relations regardless of type (table / view / matview).
for rel in ("exercise_library", "exercise_library_manual", "exercise_library_cleaned",
            "exercises", "exercise_safety_tags"):
    print(f"\n=== {rel} ===")
    cur.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema='public' AND table_name=%s
        ORDER BY ordinal_position;
    """, (rel,))
    cols = cur.fetchall()
    if not cols:
        print("  (no columns found)")
        continue
    for cname, ctype in cols:
        print(f"  {cname:34s} {ctype}")
    try:
        cur.execute(f"SELECT COUNT(*) FROM {rel};")
        print(f"  ROWS: {cur.fetchone()[0]}")
    except Exception as e:
        conn.rollback()
        print(f"  (count failed: {e})")

# Deep-dive the MV: instruction columns, completeness, samples.
print("\n\n========== exercise_library_cleaned — instruction audit ==========")
cur.execute("""
    SELECT column_name FROM information_schema.columns
    WHERE table_schema='public' AND table_name='exercise_library_cleaned'
    ORDER BY ordinal_position;
""")
all_cols = [c for (c,) in cur.fetchall()]
instr_cols = [c for c in all_cols if re.search(
    r"instruct|step|cue|description|setup|form|tip|technique", c, re.I)]
print(f"instruction-bearing columns: {instr_cols}")

if instr_cols:
    col = instr_cols[0]
    cur.execute(f"""
        SELECT
          COUNT(*) AS total,
          COUNT(*) FILTER (WHERE {col} IS NULL OR length({col}::text)=0) AS empty,
          COUNT(*) FILTER (WHERE {col} IS NOT NULL AND length({col}::text) BETWEEN 1 AND 59) AS short,
          COUNT(*) FILTER (WHERE length({col}::text) >= 60) AS substantive
        FROM exercise_library_cleaned;
    """)
    total, empty, short, ok = cur.fetchone()
    print(f"  total={total}  empty={empty}  short(<60c)={short}  substantive={ok}")

    print("\n  --- 6 random samples ---")
    sc = ", ".join(["id", "name"] + instr_cols)
    cur.execute(f"SELECT {sc} FROM exercise_library_cleaned "
                f"WHERE {col} IS NOT NULL ORDER BY random() LIMIT 6;")
    for row in cur.fetchall():
        print(f"\n  id={row[0]}  name={row[1]}")
        for cn, val in zip(instr_cols, row[2:]):
            print(f"   [{cn}] {str(val)[:500]}")

conn.close()
