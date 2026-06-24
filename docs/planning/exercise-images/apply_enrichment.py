#!/usr/bin/env python3
"""Read a workflow output file (or raw results JSON) and write enriched exercise
metadata to the DB with PARAMETERIZED SQL (safe escaping). Table auto-detected by id.

Usage: python apply_enrichment.py <path-to-output-or-results.json> [--dry]
"""
import sys, json, re, os, psycopg2

ENV = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "backend", ".env")
DRY = "--dry" in sys.argv
path = [a for a in sys.argv[1:] if not a.startswith("--")][0]

env = {}
for line in open(ENV):
    line = line.rstrip("\n")
    if "=" in line and not line.lstrip().startswith("#"):
        k, v = line.split("=", 1); env[k.strip()] = v.strip().strip('"').strip("'")
dsn = env["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://").replace("postgres+asyncpg://", "postgresql://")

raw = open(path).read()

def extract_results(text):
    # Try whole-file JSON first
    try:
        j = json.loads(text)
        if isinstance(j, dict) and "results" in j:
            return j["results"]
        if isinstance(j, list):
            return j
    except Exception:
        pass
    # Find '"results":' and balance-match the array
    i = text.find('"results"')
    if i == -1:
        raise SystemExit("no results array found")
    i = text.find("[", i)
    depth = 0
    for k in range(i, len(text)):
        c = text[k]
        if c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                return json.loads(text[i:k + 1])
    raise SystemExit("unterminated results array")

results = extract_results(raw)
# de-dupe by id (last wins), drop entries without a UUID id
seen = {}
uuid_re = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)
for r in results:
    rid = (r.get("id") or "").strip()
    if uuid_re.match(rid):
        seen[rid] = r
rows = list(seen.values())
print(f"parsed {len(results)} results -> {len(rows)} valid unique-id rows")
if DRY:
    print(json.dumps(rows[0], indent=2)[:800] if rows else "none")
    raise SystemExit(0)

conn = psycopg2.connect(dsn); conn.autocommit = True
cur = conn.cursor()
SQL = """UPDATE {tbl} SET
  instructions = COALESCE(NULLIF(%(instructions)s,''), instructions),
  secondary_muscles = COALESCE(%(secondary_muscles)s, secondary_muscles),
  movement_pattern = COALESCE(%(movement_pattern)s, movement_pattern),
  mechanic_type = COALESCE(%(mechanic_type)s, mechanic_type),
  force_type = COALESCE(%(force_type)s, force_type),
  contraindicated_conditions = COALESCE(%(contraindicated_conditions)s, contraindicated_conditions)
WHERE id = %(id)s::uuid"""

updated_manual = updated_base = 0
for r in rows:
    p = {
        "id": r["id"],
        "instructions": r.get("instructions"),
        "secondary_muscles": r.get("secondary_muscles") or None,
        "movement_pattern": r.get("movement_pattern") or None,
        "mechanic_type": r.get("mechanic_type") or None,
        "force_type": r.get("force_type") or None,
        "contraindicated_conditions": r.get("contraindicated_conditions") or None,
    }
    cur.execute(SQL.format(tbl="exercise_library_manual"), p)
    if cur.rowcount:
        updated_manual += 1
    else:
        cur.execute(SQL.format(tbl="exercise_library"), p)
        updated_base += cur.rowcount
print(f"updated: manual={updated_manual} base={updated_base} total={updated_manual+updated_base}")
conn.close()
