#!/usr/bin/env python3
"""Fuzzy-diff researched candidate exercises against the LIVE exercise library.

Reads candidate JSON files (scratchpad) + the thin-equipment table in
incompatible-equipment-honesty.md, normalizes names aggressively (strip equipment
prefixes / filler, singularize, alias-expand), and classifies each candidate as
HAVE / REVIEW / MISSING by token-set Jaccard + subset against BOTH
exercise_library and exercise_library_manual. Goal: never call something MISSING
that we actually have under different wording/shape -> aggressive matching + a
REVIEW bucket for the borderline band.

Usage: python diff_missing.py
"""
import json, os, re, sys, glob

SCRATCH = "/private/tmp/claude-501/-Users-saichetangrandhe-AIFitnessCoach/f891da3e-d8ad-4308-b2f2-4cfdae47b57f/scratchpad"
DOC = "/Users/saichetangrandhe/AIFitnessCoach/docs/planning/incompatible-equipment-honesty.md"
ENV = "/Users/saichetangrandhe/AIFitnessCoach/backend/.env"
OUT_JSON = os.path.join(SCRATCH, "missing_consolidated.json")

EQUIP_WORDS = {
    "barbell","dumbbell","db","cable","machine","smith","ez","bar","ezbar","kettlebell","kb",
    "bodyweight","weighted","band","resistance","trx","suspension","trainer","grips","with","grip",
    "lever","plate","landmine","medicine","med","ball","yoga","mat","wheel","ab","sled","strongman",
    "equipment","other","treadmill","bench","box","ring","rings","gymnastic","trap","hex","slam",
    "balance","board","bosu","dip","station","stability","sandbag","battle","ropes","foam","roller",
    "agility","ladder","plyo","plyometric","wall","pulldown",
}
STOP = {
    "the","a","an","and","to","of","on","in","for","or","your","from","at","into",
    "exercise","exercises","variation","variations","v2","pose","hold","holds","standing","lying",
    "seated","kneeling","half","one","two","both","per","side","sided","each","position",
}
ALIAS = {
    "rdl": "romanian deadlift", "ohp": "overhead press", "bss": "bulgarian split squat",
    "sldl": "stiff leg deadlift", "tke": "terminal knee extension", "cars": "controlled articular rotation",
    "gm": "good morning", "kot": "", "atg": "", "sl": "single leg", "pushups": "push up",
    "pushup": "push up", "pullup": "pull up", "pullups": "pull up", "chinup": "chin up",
    "situp": "sit up", "situps": "sit up", "stepup": "step up", "stepups": "step up",
    "kickback": "kick back", "pulldown": "pull down", "pullover": "pull over",
    "woodchop": "wood chop", "woodchopper": "wood chop", "crossover": "cross over",
    "stepdown": "step down", "lsit": "l sit", "vsit": "v sit", "vup": "v up",
    "smr": "foam roll",  # self-myofascial release == foam rolling (we store as "Foam Roll X")
}
SUFFIX_DROP = {"s","es"}

def singular(t):
    if len(t) > 4 and t.endswith("ies"):
        return t[:-3] + "y"
    if len(t) > 3 and t.endswith("es") and t[-3] not in "aeiou":
        return t[:-2]
    if len(t) > 3 and t.endswith("s") and not t.endswith("ss"):
        return t[:-1]
    return t

# canonical token collapses (treat as same root)
CANON = {
    "bicep":"bicep","biceps":"bicep","tricep":"tricep","triceps":"tricep","ab":"ab","abs":"ab",
    "glute":"glute","glutes":"glute","quad":"quad","quads":"quad","calve":"calf","calf":"calf",
    "calves":"calf","oblique":"oblique","obliques":"oblique","fly":"fly","flye":"fly","flyes":"fly",
    "flys":"fly","raise":"raise","raises":"raise","curl":"curl","curls":"curl","press":"press",
    "presses":"press","row":"row","rows":"row","squat":"squat","squats":"squat","lunge":"lunge",
    "lunges":"lunge","extension":"extension","extensions":"extension","deadlift":"deadlift",
    "deadlifts":"deadlift","crunch":"crunch","crunches":"crunch","plank":"plank","planks":"plank",
    "dip":"dip","dips":"dip","swing":"swing","swings":"swing","clean":"clean","cleans":"clean",
    "snatch":"snatch","jump":"jump","jumps":"jump","carry":"carry","carries":"carry","walk":"walk",
    "throw":"throw","throws":"throw","slam":"slam","slams":"slam","bridge":"bridge","bridges":"bridge",
    "thrust":"thrust","thrusts":"thrust","pass":"pass","twist":"twist","twists":"twist",
}

def toks(name):
    s = name.lower()
    s = re.sub(r"\(.*?\)", " ", s)            # drop parentheticals (sanskrit etc.)
    s = re.sub(r"[^a-z0-9 ]", " ", s)
    parts = []
    for w in s.split():
        w = ALIAS.get(w, w)
        for x in w.split():
            x = singular(x)
            x = CANON.get(x, x)
            if x and x not in EQUIP_WORDS and x not in STOP and len(x) > 1:
                parts.append(x)
    return set(parts)

def nospace(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())

def jac(a, b):
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)

def load_db_names():
    url = None
    with open(ENV) as f:
        for line in f:
            if line.startswith("DATABASE_URL="):
                url = line.split("=", 1)[1].strip().strip('"').strip("'")
    if not url:
        print("no DATABASE_URL", file=sys.stderr); sys.exit(1)
    url = url.replace("postgresql+asyncpg://", "postgresql://").replace("+asyncpg", "")
    import psycopg2
    cx = psycopg2.connect(url)
    cur = cx.cursor()
    names = set()
    for tbl in ("exercise_library", "exercise_library_manual"):
        cur.execute(f"SELECT DISTINCT exercise_name FROM {tbl} WHERE exercise_name IS NOT NULL")
        for (n,) in cur.fetchall():
            names.add(n)
    cur.close(); cx.close()
    return names

def load_candidates():
    cands = []
    seen = set()
    files = {
        "free-exercise-db": "compact.json", "gym-popular": "popular.json",
        "power/oly/strongman": "power.json", "bodyweight/core/yoga": "bw.json",
        "viral/celebrity": "viral.json", "machines/bars/implements": "machines.json",
        "calisthenics/animal-flow": "calisthenics.json", "rehab/prehab/mobility": "rehab.json",
        "sport/accessibility": "sport.json", "vo2max/hyrox": "vo2max_hyrox.json",
        "planks": "planks.json", "warmups": "warmups.json", "stretches-deep": "stretches.json",
        "gym-variations": "gym_variations.json", "martial-arts": "martial.json",
        "progressions": "progressions.json", "sports-running": "sports_running.json",
        "athletic-progressions": "athletic_progressions.json",
        "goal-ladders": "goal_ladders.json", "movement-variations": "movement_variations.json",
    }
    for src, fn in files.items():
        p = os.path.join(SCRATCH, fn)
        if not os.path.exists(p):
            print(f"MISSING FILE {fn}", file=sys.stderr); continue
        with open(p) as f:
            arr = json.load(f)
        for o in arr:
            nm = (o.get("name") or "").strip()
            if not nm:
                continue
            key = nospace(nm)
            if key in seen:
                continue
            seen.add(key)
            cands.append({"name": nm, "equipment": o.get("equipment"),
                          "muscle": o.get("muscle"), "category": o.get("category"), "src": src})
    # NOTE: the 158 trusted equip-gap variants are NOT diffed here (fuzzy match would wrongly
    # collapse e.g. "Trap Bar RDL" -> "Romanian Deadlift"). They live in the doc's equip-gap rows
    # and are merged in separately by the master-table builder.
    return cands

def main():
    db = load_db_names()
    db_tok = [(n, toks(n), nospace(n)) for n in db]
    cands = load_candidates()
    print(f"DB names: {len(db)} | candidates: {len(cands)}")

    have, review, missing = [], [], []
    for c in cands:
        ct, cns = toks(c["name"]), nospace(c["name"])
        best, best_name = 0.0, ""
        matched = False
        for dn, dt, dns in db_tok:
            # nospace substring (length-guarded)
            if len(cns) >= 7 and (cns in dns or (len(dns) >= 7 and dns in cns)):
                matched = True; best, best_name = 1.0, dn; break
            j = jac(ct, dt)
            # subset: candidate fully contained in a db token-set
            if ct and ct <= dt:
                j = max(j, 0.92)
            if j > best:
                best, best_name = j, dn
        c["score"] = round(best, 2); c["closest"] = best_name
        # surface distinct variations: only call HAVE on a strong/exact match; a shared base
        # word (e.g. "plank") is not enough — a qualifier the DB lacks => it's a missing variation.
        if matched or best >= 0.72:
            have.append(c)
        elif best >= 0.55:
            review.append(c)
        else:
            missing.append(c)

    missing.sort(key=lambda x: (x["category"] or "", x["equipment"] or "", x["name"]))
    review.sort(key=lambda x: -x["score"])
    json.dump({"missing": missing, "review": review, "have_count": len(have)},
              open(OUT_JSON, "w"), indent=2)
    print(f"HAVE={len(have)}  REVIEW={len(review)}  MISSING={len(missing)}")
    from collections import Counter, defaultdict
    print("MISSING by category:", dict(Counter((m['category'] or '?') for m in missing)))

    # markdown — exclude thin-equipment (already in its own table)
    md = [m for m in missing if (m["category"] or "") != "thin-equipment"]
    g = defaultdict(list)
    for m in md:
        g[m["category"] or "?"].append(m)
    out = ["## Movements absent from the library entirely (fuzzy-verified)\n",
           f"_{len(md)} movements with no equivalent in `exercise_library` or "
           f"`exercise_library_manual` under any wording (token-set + alias fuzzy match vs "
           f"{len(db)} names). Separate from the thin-equipment variants above._\n",
           "| # | Name | Equipment | Muscle | Category |", "|--|--|--|--|--|"]
    i = 0
    for cat in sorted(g):
        for m in sorted(g[cat], key=lambda x: x["name"]):
            i += 1
            out.append(f"| {i} | {m['name']} | {m.get('equipment') or ''} | "
                       f"{m.get('muscle') or ''} | {cat} |")
    open(os.path.join(SCRATCH, "missing_consolidated.md"), "w").write("\n".join(out) + "\n")
    print("wrote", OUT_JSON, "+ missing_consolidated.md")

if __name__ == "__main__":
    main()
