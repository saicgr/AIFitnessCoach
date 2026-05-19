"""Phase 0 — deterministic structural audit of exercise instructions.

Read-only. NO safety classification by judgment — this only flags STRUCTURAL
defects. Every flag is a CANDIDATE for source-grounded review, never a verdict.

Phase 0 finding (first run): 0 empty, 0 short. The real defect is GENERIC
TEMPLATE text that passes a length check but never teaches the specific
movement. So "deficient" = templated OR generic-filler OR risky-phrase, not
"short".

Scope: exercise_library (2,439) + exercise_library_manual (786) = the rows the
exercise_library_cleaned MV unions and the app serves.
"""
import os
import re
import sys
import hashlib
import datetime
import collections
import psycopg2

ROOT = os.path.join(os.path.dirname(__file__), "..")

with open(os.path.join(ROOT, "backend", ".env")) as f:
    for line in f:
        if line.startswith("DATABASE_URL="):
            raw = line.split("=", 1)[1].strip()
            break
url = raw.replace("postgresql+asyncpg://", "postgresql://")

# --- contamination-guard mode (CI / post-import gate) ------------------------
# `python audit_exercise_instructions.py --check` runs a PRECISE structural
# scan of the served library and exits non-zero if any instruction is empty,
# too short, or templated (3+ exercises share identical text). These are the
# unambiguous signatures of a bad bulk import. Generic/risky-phrase heuristics
# are intentionally NOT gated — they are too noisy for a pass/fail check (they
# false-flag correct cues like "the appropriate angle" / "do not hold breath").
if "--check" in sys.argv:
    import collections as _c
    # Known baseline after migration 2084: 18 exercises remain templated —
    # these are in the deliberately-skipped set (the engine had no reliable
    # template; they await the human/advisor instruction pass). The gate fails
    # if templating exceeds this baseline (a NEW bad import) or if ANY empty /
    # short instruction appears (always an unambiguous defect). Drop the
    # baseline toward 0 as the skipped set is remediated.
    BASELINE_TEMPLATED = 18
    conn = psycopg2.connect(url)
    cur = conn.cursor()
    cur.execute("SELECT id, name, instructions FROM exercise_library_cleaned;")
    rows = cur.fetchall()
    conn.close()
    _norm = lambda t: re.sub(r"\s+", " ", (t or "").strip().lower())
    groups = _c.defaultdict(list)
    for _id, nm, ins in rows:
        groups[hashlib.md5(_norm(ins).encode()).hexdigest()].append(nm)
    hard, templated = [], []
    for _id, nm, ins in rows:
        n = _norm(ins)
        if not n:
            hard.append((nm, "empty instruction"))
        elif len(ins) < 120:
            hard.append((nm, f"too short ({len(ins)} chars)"))
        elif len(groups[hashlib.md5(n.encode()).hexdigest()]) >= 3:
            templated.append(nm)
    fail = bool(hard) or len(templated) > BASELINE_TEMPLATED
    for nm, why in hard:
        print(f"  HARD DEFECT  {nm}  ::  {why}")
    print(f"templated: {len(templated)} (baseline {BASELINE_TEMPLATED})   "
          f"hard defects: {len(hard)}")
    if fail:
        print("FAIL — new contamination detected (a bulk import likely reused a "
              "template or shipped empty instructions). Run "
              "rewrite_exercise_instructions.py before release.")
        sys.exit(1)
    print(f"OK — {len(rows)} served instructions, no new contamination.")
    sys.exit(0)

# --- known-bad / context-risky phrases in INSTRUCTION TEXT (candidates) ------
RISKY_PHRASES = {
    r"\bpush through (the )?pain\b": "train-through-pain",
    r"\bignore (the )?pain\b": "ignore-pain",
    r"\bthrough the pain\b": "train-through-pain",
    r"\bround (your |the )?back\b": "cue to round the back",
    r"\brounded back\b": "rounded-back phrasing",
    r"\bhold your breath\b": "naive breath-hold cue",
    r"\block (your |out your )?knees\b": "knee lockout under load",
    r"\block (your |out your )?elbows\b": "elbow lockout under load",
    r"\bbounce\b": "bounce cue",
    r"\bswing the weight\b": "swing-the-weight cue",
    r"\buse momentum\b": "momentum cue",
    r"\bjerk (the|it|your)\b": "jerk cue",
    r"\bas fast as (you can|possible)\b": "max-speed cue",
    r"\bas heavy as (you can|possible)\b": "max-load, no progression caveat",
    r"\bno rest\b": "no-rest instruction",
}

# Generic filler — phrasing that signals the instruction does NOT teach the
# specific movement (it would read the same for 50 different exercises).
GENERIC_MARKERS = [
    "appropriate grip", "proper posture", "proper position", "proper form",
    "comfortable starting position", "starting position for the",
    "the appropriate", "into position", "in the proper position",
    "with proper back support", "engage your core and perform",
    "perform the movement", "complete the movement", "do the exercise",
]

HEAVY_PATTERNS = {
    "squat", "hinge", "horizontal_push", "vertical_push", "horizontal_pull",
    "vertical_pull", "deadlift", "press", "hip_hinge", "lunge",
}

conn = psycopg2.connect(url)
cur = conn.cursor()
rows = []
# Audit the MATERIALIZED VIEW exercise_library_cleaned — that is the exact set
# the app serves and the active-workout instructions tab renders. movement_pattern
# + beginner flag come from exercise_safety_tags joined on id.
cur.execute("""
    SELECT el.id, el.name, el.equipment, el.instructions,
           el.difficulty_level, st.movement_pattern, el.category,
           st.is_beginner_safe, st.safety_difficulty
    FROM exercise_library_cleaned el
    LEFT JOIN exercise_safety_tags st ON st.exercise_id = el.id;
""")
for r in cur.fetchall():
    rows.append(dict(zip(
        ["id", "name", "equipment", "instructions", "difficulty",
         "movement_pattern", "category", "is_beginner_safe",
         "safety_difficulty"], r)) | {"table": "exercise_library_cleaned"})
conn.close()
total = len(rows)

def norm(t):
    return re.sub(r"\s+", " ", (t or "").strip().lower())

empty, short, thin, substantive = [], [], [], []
dup_index = collections.defaultdict(list)
phrase_hits = collections.defaultdict(list)

for r in rows:
    n = norm(r["instructions"])
    r["len"] = len(r["instructions"]) if r["instructions"] else 0
    r["heavy"] = (r["movement_pattern"] or "").lower() in HEAVY_PATTERNS
    r["beginner"] = (r["is_beginner_safe"] is True
                     or (r["difficulty"] or "").lower() in ("beginner", "novice"))
    r["generic_hits"] = [m for m in GENERIC_MARKERS if m in n]
    r["risky"] = []
    if not n:
        empty.append(r)
    elif r["len"] < 120:
        short.append(r)
    elif r["len"] < 250:
        thin.append(r)
    else:
        substantive.append(r)
    if n:
        dup_index[hashlib.md5(n.encode()).hexdigest()].append(r)
        for pat, why in RISKY_PHRASES.items():
            if re.search(pat, n):
                phrase_hits[why].append(r)
                r["risky"].append(why)

dup_groups = {h: rs for h, rs in dup_index.items() if len(rs) > 1}
for rs in dup_groups.values():
    for r in rs:
        r["dup_size"] = len(rs)
for r in rows:
    r.setdefault("dup_size", 1)
    # templated = shares text with >=2 others, OR heavy generic-filler density
    r["templated"] = r["dup_size"] >= 3
    r["generic"] = len(r["generic_hits"]) >= 2
    r["deficient"] = r["templated"] or r["generic"] or bool(r["risky"])

dup_rows = sum(len(rs) for rs in dup_groups.values())
big_dups = sorted(dup_groups.values(), key=len, reverse=True)
deficient = [r for r in rows if r["deficient"]]
priority = [r for r in deficient if r["beginner"] or r["heavy"]]
heavy_all = [r for r in rows if r["heavy"]]
heavy_bad = [r for r in heavy_all if r["deficient"]]

print(f"Audited {total} exercise instructions\n")
print("STRUCTURAL BUCKETS")
for label, lst in [("empty/NULL", empty), ("short <120c", short),
                    ("thin 120-249c", thin), ("substantive >=250c", substantive)]:
    print(f"  {label:22s} {len(lst):5d}  ({len(lst)/total*100:.1f}%)")
print(f"\nDUPLICATION")
print(f"  distinct texts {len(dup_index)} / {total}")
print(f"  shared by >1   {len(dup_groups)} groups, {dup_rows} rows "
      f"({dup_rows/total*100:.1f}%)")
print(f"\nDEFICIENT (templated >=3  OR  generic-filler  OR  risky-phrase)")
print(f"  templated         {sum(1 for r in rows if r['templated']):5d}")
print(f"  generic-filler    {sum(1 for r in rows if r['generic']):5d}")
print(f"  risky-phrase      {sum(1 for r in rows if r['risky']):5d}")
print(f"  TOTAL deficient   {len(deficient):5d}  ({len(deficient)/total*100:.1f}%)")
print(f"\nHEAVY COMPOUNDS (the 'lifting heavy' red flag)")
print(f"  heavy-compound exercises    {len(heavy_all)}")
print(f"  ...with a deficient instr   {len(heavy_bad)}")
print(f"\nPRIORITY  (deficient AND (beginner OR heavy)) = {len(priority)}")

today = datetime.date.today().isoformat()
outdir = os.path.join(ROOT, "docs", "planning", "exercise-instruction-audit")
os.makedirs(outdir, exist_ok=True)
outpath = os.path.join(outdir, f"phase0-structural-audit-{today}.md")
with open(outpath, "w") as o:
    o.write("# Exercise Instruction Audit — Phase 0 (structural)\n\n")
    o.write(f"Generated {today}, read-only deterministic scan. Flags are "
            f"CANDIDATES for source-grounded review, not verdicts.\n\n")
    o.write(f"**Scope:** {total} instructions "
            f"(`exercise_library` 2439 + `exercise_library_manual` 786).\n\n")
    o.write("## Headline\n\n")
    o.write(f"- Length is NOT the problem: 0 empty, 0 short.\n")
    o.write(f"- The problem is GENERIC / TEMPLATED text: **{len(deficient)} "
            f"of {total} ({len(deficient)/total*100:.0f}%)** instructions are "
            f"templated, generic-filler, or contain a risky phrase.\n")
    o.write(f"- Heavy-compound lifts with a deficient instruction: "
            f"**{len(heavy_bad)} of {len(heavy_all)}**.\n\n")
    o.write("## Buckets\n\n| Bucket | Count | % |\n|---|---|---|\n")
    for label, lst in [("empty", empty), ("short <120c", short),
                        ("thin 120-249c", thin), ("substantive", substantive)]:
        o.write(f"| {label} | {len(lst)} | {len(lst)/total*100:.1f}% |\n")
    o.write(f"\n## Largest template groups\n\n| Count | Example | Text start |\n")
    o.write("|---|---|---|\n")
    for g in big_dups[:30]:
        o.write(f"| {len(g)} | {g[0]['name']} | "
                f"{norm(g[0]['instructions'])[:110].replace('|','/')} |\n")
    o.write(f"\n## Risky-phrase candidates (manual review)\n\n| Count | Concern |\n")
    o.write("|---|---|\n")
    for why, rs in sorted(phrase_hits.items(), key=lambda x: -len(x[1])):
        o.write(f"| {len(rs)} | {why} |\n")
    o.write(f"\n## Priority list — deficient AND (beginner OR heavy compound) "
            f"= {len(priority)}\n\n")
    o.write("| id | name | equipment | pattern | why |\n|---|---|---|---|---|\n")
    for r in sorted(priority, key=lambda r: (not r["heavy"], r["name"])):
        why = []
        if r["templated"]: why.append(f"templated x{r['dup_size']}")
        if r["generic"]: why.append("generic-filler")
        if r["risky"]: why.append("risky:" + ";".join(r["risky"]))
        o.write(f"| {r['id']} | {r['name']} | {r['equipment']} | "
                f"{r['movement_pattern']} | {', '.join(why)} |\n")

print(f"\nReport: {os.path.relpath(outpath, ROOT)}")
