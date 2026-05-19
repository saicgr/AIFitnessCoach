"""Profile the in-scope (deficient) served exercises so the YAML rubric is
grounded in the real data: distinct movement_patterns, equipment, categories,
and counts of cardio / timed / olympic / composite / kegel edge cases.

Read-only.
"""
import os
import re
import hashlib
import collections
import psycopg2

ROOT = os.path.join(os.path.dirname(__file__), "..")
for line in open(os.path.join(ROOT, "backend", ".env")):
    if line.startswith("DATABASE_URL="):
        url = line.split("=", 1)[1].strip().replace("postgresql+asyncpg://", "postgresql://")
        break

RISKY = [r"\bpush through (the )?pain\b", r"\bignore (the )?pain\b",
         r"\bthrough the pain\b", r"\bround (your |the )?back\b", r"\brounded back\b",
         r"\bhold your breath\b", r"\block (your |out your )?knees\b",
         r"\block (your |out your )?elbows\b", r"\bbounce\b", r"\bswing the weight\b",
         r"\buse momentum\b", r"\bjerk (the|it|your)\b", r"\bas fast as (you can|possible)\b",
         r"\bas heavy as (you can|possible)\b", r"\bno rest\b"]
GENERIC = ["appropriate grip", "proper posture", "proper position", "proper form",
           "comfortable starting position", "starting position for the",
           "the appropriate", "into position", "in the proper position",
           "with proper back support", "engage your core and perform",
           "perform the movement", "complete the movement", "do the exercise"]

conn = psycopg2.connect(url)
cur = conn.cursor()
cur.execute("""
    SELECT el.id, el.name, el.equipment, el.instructions, el.category,
           el.difficulty_level,
           COALESCE(b.movement_pattern, m.movement_pattern) AS base_pattern,
           st.movement_pattern AS tag_pattern,
           COALESCE(b.is_timed, m.is_timed) AS is_timed,
           COALESCE(b.is_dynamic_stretch, m.is_dynamic_stretch) AS is_dyn_stretch,
           COALESCE(b.default_hold_seconds, m.default_hold_seconds) AS hold_s,
           COALESCE(b.is_unilateral, m.is_unilateral) AS is_unilateral,
           COALESCE(b.default_tempo, m.default_tempo) AS tempo,
           COALESCE(b.plane_of_motion, m.plane_of_motion) AS plane,
           el.target_muscle, el.secondary_muscles,
           CASE WHEN b.id IS NOT NULL THEN 'exercise_library'
                WHEN m.id IS NOT NULL THEN 'exercise_library_manual' END AS src
    FROM exercise_library_cleaned el
    LEFT JOIN exercise_library b ON b.id = el.id
    LEFT JOIN exercise_library_manual m ON m.id = el.id
    LEFT JOIN exercise_safety_tags st ON st.exercise_id = el.id;
""")
cols = [d.name for d in cur.description]
rows = [dict(zip(cols, r)) for r in cur.fetchall()]
conn.close()

def norm(t):
    return re.sub(r"\s+", " ", (t or "").strip().lower())

dup = collections.defaultdict(list)
for r in rows:
    n = norm(r["instructions"])
    if n:
        dup[hashlib.md5(n.encode()).hexdigest()].append(r["id"])
inscope = []
for r in rows:
    n = norm(r["instructions"])
    if not n:
        continue
    templated = len(dup[hashlib.md5(n.encode()).hexdigest()]) >= 3
    generic = sum(1 for g in GENERIC if g in n) >= 2
    risky = any(re.search(p, n) for p in RISKY)
    if templated or generic or risky:
        r["_why"] = (["templated"] if templated else []) + \
                    (["generic"] if generic else []) + (["risky"] if risky else [])
        inscope.append(r)

print(f"In-scope deficient (served MV): {len(inscope)} of {len(rows)}\n")

def tally(key, label):
    c = collections.Counter(str(r[key]) for r in inscope)
    print(f"--- {label} ({len(c)} distinct) ---")
    for v, n in c.most_common():
        print(f"  {n:4d}  {v}")
    print()

tally("base_pattern", "base movement_pattern")
tally("tag_pattern", "safety_tags movement_pattern")
tally("category", "category")
tally("src", "source table")

print("--- equipment (distinct) ---")
eq = collections.Counter(str(r["equipment"]) for r in inscope)
for v, n in eq.most_common():
    print(f"  {n:4d}  {v}")
print()

# edge-case counts
def name_has(r, *toks):
    nm = (r["name"] or "").lower()
    return any(t in nm for t in toks)

print("--- edge-case counts (in-scope) ---")
print(f"  is_timed=true              {sum(1 for r in inscope if r['is_timed'])}")
print(f"  is_dynamic_stretch=true    {sum(1 for r in inscope if r['is_dyn_stretch'])}")
print(f"  has hold_seconds           {sum(1 for r in inscope if r['hold_s'])}")
print(f"  olympic (snatch/clean/jerk){sum(1 for r in inscope if name_has(r,'snatch','clean','jerk'))}")
print(f"  composite-ish name         {sum(1 for r in inscope if name_has(r,' to ',' + ',' into ','combo'))}")
print(f"  kegel-ish name             {sum(1 for r in inscope if name_has(r,'kegel','pelvic'))}")
print(f"  cardio-ish name            {sum(1 for r in inscope if name_has(r,'treadmill','cycling','bike','rowing','run','sprint','elliptical','jump rope','jump-rope'))}")
print(f"  stretch-ish name           {sum(1 for r in inscope if name_has(r,'stretch','pose','savasana'))}")
print(f"  NULL base_pattern          {sum(1 for r in inscope if r['base_pattern'] is None)}")
print(f"  NULL tag_pattern           {sum(1 for r in inscope if r['tag_pattern'] is None)}")
print(f"  NULL BOTH patterns         {sum(1 for r in inscope if r['base_pattern'] is None and r['tag_pattern'] is None)}")
print(f"  name has underscore        {sum(1 for r in inscope if '_' in (r['name'] or ''))}")
print(f"  name has Female/Male sfx   {sum(1 for r in inscope if re.search(r'[_ ](female|male)$', (r['name'] or ''), re.I))}")
