"""Deterministically rewrite poor / generic / risky exercise instructions.

NO LLM. Design:
  * A CORRECT, deterministic classifier (classify_movement) maps each exercise
    name to a specific movement class. We do NOT trust the Dart engine's own
    name-matching (it mis-routes ambiguous names — "hyperextension" -> triceps,
    "ball sit-up" -> L-sit hold, "airbike" -> running).
  * Each class has a CANONICAL EXEMPLAR name that is known to route correctly
    through the app's vetted instruction engine
    (mobile/flutter/lib/screens/workout/shared/exercise_instruction_copy.dart).
    We call the engine with the exemplar, so the CONTENT is always correct for
    the class. The real exercise name is interpolated into the caveat line.
  * Classes with no reliable engine template -> the exercise is SKIPPED
    (original kept). Over-skipping is safe; shipping wrong content is not.
  * Every rewrite is validated deterministically and carries a source_citation.

Usage:
  python backend/scripts/rewrite_exercise_instructions.py --dry-run [--sample N]
  python backend/scripts/rewrite_exercise_instructions.py --emit-sql --out backend/migrations/2084_rewrite_exercise_instructions.sql
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

import psycopg2

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
FLUTTER_DIR = os.path.join(ROOT, "mobile", "flutter")
REWRITE_BATCH = "2084-2026-05-18"

# --- deficiency detection (identical to audit_exercise_instructions.py) -------
RISKY = {
    r"\bpush through (the )?pain\b": "train-through-pain",
    r"\bignore (the )?pain\b": "ignore-pain",
    r"\bthrough the pain\b": "train-through-pain",
    r"\bround (your |the )?back\b": "round-the-back",
    r"\brounded back\b": "rounded-back",
    r"\bhold your breath\b": "breath-hold",
    r"\block (your |out your )?knees\b": "knee-lockout",
    r"\block (your |out your )?elbows\b": "elbow-lockout",
    r"\bbounce\b": "bounce",
    r"\bswing the weight\b": "swing-the-weight",
    r"\buse momentum\b": "momentum",
    r"\bjerk (the|it|your)\b": "jerk",
    r"\bas fast as (you can|possible)\b": "max-speed",
    r"\bas heavy as (you can|possible)\b": "max-load",
    r"\bno rest\b": "no-rest",
}
GENERIC = ["appropriate grip", "proper posture", "proper position", "proper form",
           "comfortable starting position", "starting position for the",
           "the appropriate", "into position", "in the proper position",
           "with proper back support", "engage your core and perform",
           "perform the movement", "complete the movement", "do the exercise"]
VALIDATOR_GENERIC = ["appropriate grip", "proper posture", "proper position",
                     "proper form", "comfortable starting position",
                     "starting position for the", "with proper back support",
                     "engage your core and perform", "perform the movement",
                     "complete the movement", "do the exercise"]
NEGATORS = ("never", "don't", "dont", "do not", "without", "avoid", "not ", "no ")
DART_GENERIC_SETUP = [
    "Set up your equipment and check your form in a mirror if available.",
    "Warm up with lighter weight first.",
    "Position yourself in the starting position.",
    "Focus on controlled movements throughout.",
    "Breathe consistently — exhale on exertion.",
]

# --- movement class -> (canonical exemplar name, exemplar equipment) ----------
# The exemplar is a name KNOWN to route to the right branch of the Dart engine.
EXEMPLARS = {
    "barbell_squat":       ("barbell back squat", "Barbell"),
    "bodyweight_squat":    ("bodyweight squat", "Bodyweight"),
    "goblet_squat":        ("goblet squat", "Dumbbell"),
    "split_squat":         ("bulgarian split squat", "Dumbbell"),
    "pistol_squat":        ("pistol squat", "Bodyweight"),
    "jump_squat":          ("jump squat", "Bodyweight"),
    "lunge":               ("forward lunge", "Dumbbell"),
    "walking_lunge":       ("walking lunge", "Dumbbell"),
    "jump_lunge":          ("jumping lunge", "Bodyweight"),
    "cossack":             ("cossack lunge", "Bodyweight"),
    "deadlift":            ("barbell deadlift", "Barbell"),
    "rdl":                 ("romanian deadlift", "Barbell"),
    "sumo_deadlift":       ("sumo deadlift", "Barbell"),
    "single_leg_deadlift": ("single leg deadlift", "Dumbbell"),
    "trap_bar_deadlift":   ("trap bar deadlift", "Trap Bar"),
    "hip_thrust":          ("barbell hip thrust", "Barbell"),
    "glute_bridge":        ("glute bridge", "Bodyweight"),
    "kettlebell_swing":    ("kettlebell swing", "Kettlebell"),
    "bench_press":         ("barbell bench press", "Barbell"),
    "overhead_press":      ("overhead press", "Barbell"),
    "pushup":              ("push-up", "Bodyweight"),
    "dip":                 ("chest dip", "Bodyweight"),
    "fly":                 ("cable fly", "Cable Machine"),
    "leg_press":           ("leg press", "Leg Press Machine"),
    "calf_raise":          ("standing calf raise", "Bodyweight"),
    "pullup":              ("pull-up", "Bodyweight"),
    "lat_pulldown":        ("lat pulldown", "Cable Machine"),
    "barbell_row":         ("barbell row", "Barbell"),
    "cable_row":           ("seated cable row", "Cable Machine"),
    "inverted_row":        ("inverted row", "Bodyweight"),
    "renegade_row":        ("renegade row", "Dumbbell"),
    "face_pull":           ("face pull", "Cable Machine"),
    "curl":                ("dumbbell curl", "Dumbbell"),
    "hammer_curl":         ("hammer curl", "Dumbbell"),
    "preacher_curl":       ("preacher curl", "Barbell"),
    "concentration_curl":  ("concentration curl", "Dumbbell"),
    "reverse_curl":        ("reverse curl", "Barbell"),
    "triceps_extension":   ("triceps extension", "Dumbbell"),
    "plank":               ("plank", "Bodyweight"),
    "side_plank":          ("side plank", "Bodyweight"),
    "wall_sit":            ("wall sit", "Bodyweight"),
    "crunch":              ("crunch", "Bodyweight"),
    "russian_twist":       ("russian twist", "Bodyweight"),
    "burpee":              ("burpee", "Bodyweight"),
    "mountain_climber":    ("mountain climber", "Bodyweight"),
    "bear_crawl":          ("bear crawl", "Bodyweight"),
    "olympic_clean":       ("power clean", "Barbell"),
    "olympic_snatch":      ("barbell snatch", "Barbell"),
    "olympic_jerk":        ("push jerk", "Barbell"),
    "turkish_getup":       ("turkish get-up", "Kettlebell"),
    "farmer_carry":        ("farmer's carry", "Dumbbell"),
    "jump_rope":           ("jump rope", "Jump Rope"),
    "rowing_erg":          ("rowing machine", "Rowing Machine"),
    "treadmill":           ("treadmill run", "Treadmill"),
    "cardio_bike":         ("stationary bike", "Stationary Bike"),
    "stretch":             ("hamstring stretch", "Bodyweight"),
}

# class -> citation (authoritative technique standard)
_CIT = {
    "squat": "NSCA Essentials of Strength Training & Conditioning 4th ed. (Haff & Triplett 2016) ch.13 — squat technique",
    "lunge": "NSCA ESSC 4th ed. ch.13 — lunge / split-stance technique",
    "hinge": "NSCA ESSC 4th ed. ch.13; McGill, Low Back Disorders 2nd ed. — neutral-spine hip hinge",
    "olympic": "NSCA ESSC 4th ed. ch.15 — Olympic-lift technique",
    "horiz_push": "NSCA ESSC 4th ed. ch.13; NASM EPFT 6th ed. ch.13 — horizontal pressing",
    "vert_push": "NSCA ESSC 4th ed. ch.13; NASM EPFT 6th ed. ch.13 — overhead pressing, neutral rib position",
    "pull": "NSCA ESSC 4th ed. ch.13 — rowing / pulling technique",
    "core": "NASM EPFT 6th ed. ch.9; McGill, Low Back Disorders 2nd ed. — trunk / core training",
    "isolation": "NASM EPFT 6th ed. ch.13 — single-joint resistance technique",
    "stretch": "ACSM's Guidelines for Exercise Testing & Prescription 11th ed. (2021) ch.6 — flexibility training",
    "cardio": "ACSM GETP 11th ed. ch.6-7 — aerobic exercise prescription",
}
CLASS_FAMILY = {
    "barbell_squat": "squat", "bodyweight_squat": "squat", "goblet_squat": "squat",
    "split_squat": "squat", "pistol_squat": "squat", "jump_squat": "squat",
    "leg_press": "squat", "calf_raise": "squat",
    "lunge": "lunge", "walking_lunge": "lunge", "jump_lunge": "lunge", "cossack": "lunge",
    "deadlift": "hinge", "rdl": "hinge", "sumo_deadlift": "hinge",
    "single_leg_deadlift": "hinge", "trap_bar_deadlift": "hinge",
    "hip_thrust": "hinge", "glute_bridge": "hinge", "kettlebell_swing": "hinge",
    "bench_press": "horiz_push", "pushup": "horiz_push", "dip": "horiz_push", "fly": "horiz_push",
    "overhead_press": "vert_push",
    "pullup": "pull", "lat_pulldown": "pull", "barbell_row": "pull",
    "cable_row": "pull", "inverted_row": "pull", "renegade_row": "pull", "face_pull": "pull",
    "curl": "isolation", "hammer_curl": "isolation", "preacher_curl": "isolation",
    "concentration_curl": "isolation", "reverse_curl": "isolation", "triceps_extension": "isolation",
    "plank": "core", "side_plank": "core", "wall_sit": "core", "crunch": "core",
    "russian_twist": "core", "mountain_climber": "core", "bear_crawl": "core", "burpee": "core",
    "olympic_clean": "olympic", "olympic_snatch": "olympic", "olympic_jerk": "olympic",
    "turkish_getup": "olympic", "farmer_carry": "olympic",
    "jump_rope": "cardio", "rowing_erg": "cardio", "treadmill": "cardio", "cardio_bike": "cardio",
    "stretch": "stretch",
}


def classify_movement(name):
    """Deterministic, correct movement classification. Returns a class key in
    EXEMPLARS, or None when no reliable template exists (-> skip)."""
    n = " " + (name or "").lower().strip() + " "
    has = lambda *pats: any(re.search(p, n) for p in pats)

    # Olympic / loaded carries first (before composite "and" check).
    if has(r"\bturkish\b", r"get[- ]?up"):
        return "turkish_getup"
    if has(r"farmer'?s? ?carry", r"farmer'?s? ?walk"):
        return "farmer_carry"
    kb = has(r"kettlebell", r"\bkb\b")
    if has(r"\bsnatch\b") and not kb:
        return "olympic_snatch"
    if has(r"clean and jerk", r"\bpower clean\b", r"\bhang clean\b", r"\bclean\b") and not kb:
        return "olympic_clean"
    if has(r"\bjerk\b") and not kb:
        return "olympic_jerk"

    # Composite / combo — one template cannot describe two movements -> skip.
    if has(r" to ", r" into ", r"\+", r" and (?!jerk)"):
        return None

    # Cardio — bike checked BEFORE run so "airbike sprint" is not "running".
    if has(r"jump ?rope", r"skipping rope"):
        return "jump_rope"
    if has(r"rowing machine", r"\berg\b", r"\brower\b", r"concept ?2"):
        return "rowing_erg"
    if has(r"airbike", r"air bike", r"assault bike", r"echo bike", r"\bbike\b",
           r"cycling", r"spin bike", r"elliptical"):
        return "cardio_bike"
    if has(r"treadmill", r"\brunning\b", r"\bjog", r"\bsprint", r"\brun\b"):
        return "treadmill"

    # Stretch / mobility / yoga.
    if has(r"stretch", r"\bpose\b", r"mobility", r"savasana", r"cat[- ]cow",
           r"sun salutation", r"\bwarrior\b", r"downward dog", r"foam roll"):
        return "stretch"

    # Core — holds, then dynamic.
    if has(r"side plank"):
        return "side_plank"
    if has(r"\bplank\b"):
        return "plank"
    if has(r"wall sit"):
        return "wall_sit"
    if has(r"russian twist"):
        return "russian_twist"
    if has(r"mountain climber"):
        return "mountain_climber"
    if has(r"bear crawl", r"crab walk"):
        return "bear_crawl"
    if has(r"burpee"):
        return "burpee"
    if has(r"crunch", r"sit[- ]?up", r"\bv-?up\b"):
        return "crunch"

    # Squat family.
    if has(r"pistol", r"single[- ]leg squat", r"shrimp squat"):
        return "pistol_squat"
    if has(r"goblet squat"):
        return "goblet_squat"
    if has(r"split squat", r"bulgarian"):
        return "split_squat"
    if has(r"jump squat", r"squat jump"):
        return "jump_squat"
    if has(r"leg press", r"hack squat"):
        return "leg_press"
    if has(r"\bsquat\b", r"\bsquats\b"):
        return "bodyweight_squat" if has(r"bodyweight", r"\bair squat\b") else "barbell_squat"
    if has(r"calf raise"):
        return "calf_raise"

    # Lunge family.
    if has(r"jump(ing)? lunge", r"lunge jump"):
        return "jump_lunge"
    if has(r"cossack"):
        return "cossack"
    if has(r"walking lunge"):
        return "walking_lunge"
    if has(r"\blunge", r"step[- ]?up"):
        return "lunge"

    # Hinge family.
    if has(r"hip thrust"):
        return "hip_thrust"
    if has(r"glute bridge"):
        return "glute_bridge"
    if kb and has(r"swing"):
        return "kettlebell_swing"
    if has(r"romanian", r"\brdl\b", r"stiff[- ]leg"):
        return "rdl"
    if has(r"sumo deadlift"):
        return "sumo_deadlift"
    if has(r"trap[- ]bar", r"hex bar"):
        return "trap_bar_deadlift"
    if has(r"deadlift"):
        return "single_leg_deadlift" if has(r"single", r"one[- ]leg") else "deadlift"

    # Press family.
    if has(r"\bbench press\b", r"larsen press", r"floor press") and not has(r"leg"):
        return "bench_press"
    if has(r"overhead press", r"shoulder press", r"military press", r"arnold press",
           r"push press", r"z[- ]press", r"strict press"):
        return "overhead_press"

    # Push-up / dip.
    if has(r"push[- ]?up"):
        return "pushup"
    if has(r"\bdip\b", r"\bdips\b") and not has(r"bicep"):
        return "dip"

    # Pull family.
    if has(r"pull[- ]?up", r"chin[- ]?up"):
        return "pullup"
    if has(r"lat pulldown", r"\bpulldown\b", r"pull[- ]down"):
        return "lat_pulldown"
    if has(r"face pull", r"pull[- ]apart"):
        return "face_pull"
    if has(r"renegade"):
        return "renegade_row"
    if has(r"\brow\b", r"\brows\b"):
        if has(r"upright"):
            return None  # upright row is a shoulder move; engine has no template
        if has(r"cable", r"seated row", r"machine row"):
            return "cable_row"
        if has(r"inverted", r"\btrx\b", r"australian"):
            return "inverted_row"
        return "barbell_row"

    # Curls / triceps.
    if has(r"hammer curl"):
        return "hammer_curl"
    if has(r"preacher curl"):
        return "preacher_curl"
    if has(r"concentration curl"):
        return "concentration_curl"
    if has(r"reverse curl", r"reverse[- ]grip curl"):
        return "reverse_curl"
    if has(r"\bcurl\b") and not has(r"leg curl", r"wrist curl"):
        return "curl"
    if has(r"triceps? extension", r"skull crusher", r"triceps? kickback",
           r"overhead (triceps?|tricep) extension", r"triceps? pushdown"):
        return "triceps_extension"

    # Chest fly (not rear-delt fly — that is a shoulder move with no template).
    if has(r"\bfly\b", r"\bflye\b", r"crossover", r"pec deck") and not has(r"rear delt", r"reverse fly"):
        return "fly"

    return None  # leg extension, raises, shrugs, ab wheel, etc. -> skip


def fetch_inscope(conn):
    cur = conn.cursor()
    cur.execute("""
        SELECT el.id, el.name, el.equipment, el.instructions, el.target_muscle,
               CASE WHEN b.id IS NOT NULL THEN 'exercise_library'
                    WHEN m.id IS NOT NULL THEN 'exercise_library_manual' END AS src
        FROM exercise_library_cleaned el
        LEFT JOIN exercise_library b ON b.id = el.id
        LEFT JOIN exercise_library_manual m ON m.id = el.id;
    """)
    cols = [d.name for d in cur.description]
    rows = [dict(zip(cols, r)) for r in cur.fetchall()]

    def norm(t):
        return re.sub(r"\s+", " ", (t or "").strip().lower())

    seen = {}
    for r in rows:
        seen.setdefault(hashlib.md5(norm(r["instructions"]).encode()).hexdigest(), []).append(r)
    inscope = []
    for r in rows:
        nrm = norm(r["instructions"])
        if not nrm:
            continue
        dup = len(seen[hashlib.md5(nrm.encode()).hexdigest()]) >= 3
        generic = sum(1 for g in GENERIC if g in nrm) >= 2
        risky = any(re.search(p, nrm) for p in RISKY)
        if dup or generic or risky:
            r["_flags"] = (["templated"] if dup else []) + \
                          (["generic"] if generic else []) + (["risky"] if risky else [])
            inscope.append(r)
    return inscope


def run_dart_exemplars():
    """Run the engine once over the canonical exemplars; return class -> sets."""
    payload = [{"id": cls, "name": nm, "equipment": eq}
               for cls, (nm, eq) in EXEMPLARS.items()]
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fi:
        json.dump(payload, fi)
        in_path = fi.name
    out_path = in_path + ".out"
    res = subprocess.run(["dart", "run", "tool/gen_instructions.dart", in_path, out_path],
                         cwd=FLUTTER_DIR, capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit(f"Dart engine failed:\n{res.stdout}\n{res.stderr}")
    gen = {g["id"]: g for g in json.load(open(out_path))}
    os.unlink(in_path)
    os.unlink(out_path)
    return gen


def assemble(row, sets):
    steps = list(sets["setup"])
    steps.append("Breathing: " + " ".join(sets["breathing"]))
    for tip in sets["tips"][:2]:
        steps.append(tip if tip.lower().startswith("form") else "Form check: " + tip)
    name = (row["name"] or "this exercise").strip()
    muscle = (row["target_muscle"] or "the prime movers").strip()
    steps.append(
        f"The {name} mainly trains your {muscle}. If you are newer to it, start "
        f"light and add load only once the movement feels controlled, and on "
        f"heavier sets end the set when your form or brace breaks down rather "
        f"than grinding out a risky rep.")
    return "\n".join(f"{i}. {s}" for i, s in enumerate(steps, 1))


def validate(text, row, fam, batch_hashes):
    reasons = []
    name = (row["name"] or "").lower()
    muscle = (row["target_muscle"] or "").lower()
    low = text.lower()
    if not text.startswith("1. "):
        reasons.append("does not start with '1. '")
    if len(re.findall(r"(?m)^\d+\. ", text)) < 5:
        reasons.append("fewer than 5 numbered steps")
    if len(text) < 200:
        reasons.append("under 200 chars")
    if name and name not in low:
        reasons.append("missing exercise name")
    if muscle and muscle not in low:
        reasons.append("missing target muscle")
    for g in VALIDATOR_GENERIC:
        if g in low:
            reasons.append(f"generic-filler phrase: '{g}'")
    name_spans = [(m.start(), m.end()) for m in re.finditer(re.escape(name), low)] if name else []
    for pat, label in RISKY.items():
        for mt in re.finditer(pat, low):
            if any(s <= mt.start() and mt.end() <= e for s, e in name_spans):
                continue
            before = low[max(0, mt.start() - 32):mt.start()]
            negated = any(neg in before for neg in NEGATORS)
            whitelisted = (
                (label in ("bounce", "max-speed") and fam == "cardio") or
                (label == "jerk" and fam == "olympic") or
                (label == "round-the-back" and fam == "stretch"))
            if not negated and not whitelisted:
                reasons.append(f"risky phrase '{label}' (un-negated)")
                break
    h = hashlib.md5(re.sub(r"\s+", " ", low).encode()).hexdigest()
    if h in batch_hashes:
        reasons.append("byte-identical to another rewrite in batch")
    return (len(reasons) == 0, reasons, h)


def emit_sql(rewrites, out_path):
    def dq(s):
        return "$instr$" + s + "$instr$"
    lines = [
        "-- 2084_rewrite_exercise_instructions.sql",
        "-- Auto-generated by backend/scripts/rewrite_exercise_instructions.py.",
        "-- Rewrites deficient exercise instructions using the app's own vetted",
        "-- instruction engine, routed by a correct deterministic classifier.",
        "-- Backs up originals first. NO LLM. The MV refresh is NOT here —",
        "-- apply_2084_rewrite.py runs it separately (REFRESH ... CONCURRENTLY",
        "-- cannot run inside a transaction).",
        "",
        "CREATE TABLE IF NOT EXISTS public.exercise_instruction_backup (",
        "    id uuid NOT NULL,",
        "    source_table text NOT NULL,",
        "    old_instructions text,",
        "    new_instructions text,",
        "    movement_class text,",
        "    rewrite_method text NOT NULL DEFAULT 'rule',",
        "    source_citation text,",
        "    rewrite_batch text NOT NULL,",
        "    backed_up_at timestamptz NOT NULL DEFAULT now(),",
        "    PRIMARY KEY (id, rewrite_batch)",
        ");",
        "",
    ]
    for row, cls, fam, text in rewrites:
        src = row["src"]
        cit = (f"[rule | engine=exercise_instruction_copy.dart | class={cls}] "
               f"{_CIT[fam]}")
        uid = str(row["id"])
        lines += [
            "INSERT INTO public.exercise_instruction_backup",
            "  (id, source_table, old_instructions, new_instructions, movement_class,",
            "   source_citation, rewrite_batch)",
            f"SELECT id, '{src}', instructions, {dq(text)}, '{cls}',",
            f"  {dq(cit)}, '{REWRITE_BATCH}'",
            f"FROM public.{src} WHERE id = '{uid}'",
            f"  AND NOT EXISTS (SELECT 1 FROM public.exercise_instruction_backup",
            f"                  WHERE id = '{uid}');",
            f"UPDATE public.{src} SET instructions = {dq(text)} WHERE id = '{uid}';",
            "",
        ]
    with open(out_path, "w") as f:
        f.write("\n".join(lines))
    print(f"\nWrote {len(rewrites)} rewrites -> {out_path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--sample", type=int, default=0)
    ap.add_argument("--emit-sql", action="store_true")
    ap.add_argument("--out", default=os.path.join(ROOT, "backend", "migrations",
                                                  "2084_rewrite_exercise_instructions.sql"))
    args = ap.parse_args()
    if not args.dry_run and not args.emit_sql:
        args.dry_run = True

    for line in open(os.path.join(ROOT, "backend", ".env")):
        if line.startswith("DATABASE_URL="):
            url = line.split("=", 1)[1].strip().replace("postgresql+asyncpg://", "postgresql://")
            break
    conn = psycopg2.connect(url)
    inscope = fetch_inscope(conn)
    conn.close()
    print(f"In-scope deficient exercises: {len(inscope)}")
    if args.sample:
        inscope = inscope[:args.sample]

    dart = run_dart_exemplars()
    rewrites, skipped, failures, batch_hashes = [], [], [], set()
    for row in inscope:
        cls = classify_movement(row["name"])
        if cls is None or cls not in dart:
            skipped.append(row)
            continue
        sets = dart[cls]
        fam = CLASS_FAMILY[cls]
        text = assemble(row, sets)
        ok, reasons, h = validate(text, row, fam, batch_hashes)
        if ok:
            batch_hashes.add(h)
            rewrites.append((row, cls, fam, text))
        else:
            failures.append((row, reasons))

    print(f"\nValidated rewrites: {len(rewrites)}   "
          f"Skipped (no reliable template): {len(skipped)}   "
          f"Validation failures: {len(failures)}")
    for row, reasons in failures:
        print(f"  FAIL  {row['name']}  ::  {'; '.join(reasons)}")

    if args.dry_run:
        for row, cls, fam, text in rewrites[:10]:
            print(f"\n{'='*70}\n{row['name']}  ->  class={cls}")
            print(f"--- NEW ---\n{text}")
        print(f"\n(dry run — showed {min(10, len(rewrites))} of {len(rewrites)}; "
              f"{len(skipped)} skipped)")
        return

    if args.emit_sql:
        if failures:
            sys.exit(f"\nABORT: {len(failures)} validation failures — fix before emitting SQL.")
        emit_sql(rewrites, args.out)


if __name__ == "__main__":
    main()
