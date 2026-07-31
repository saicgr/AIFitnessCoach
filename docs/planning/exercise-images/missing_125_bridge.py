#!/usr/bin/env python3
"""
Task B6 — 125 exercise_canonical rows with no exercise_demos row (no image_s3_path
AND no video_s3_path).

Investigation found the pipeline had ALREADY generated + QA-passed illustrations for
110 of these 125 under the OLD exercise_library table naming (same slug), already
uploaded to S3 at `ILLUSTRATIONS ALL/Generated/<slug>.png` -- they just never got
bridged into exercise_demos for the new canonical id-space (the "91-exercise
library->canonical bridging gap" noted in project memory, here at 110/125).
3 more (front_squats_kettlelbell_over_shoulders, tire_drag_backward,
battle_rope_lunges_with_waves) have a matching slug/S3 file but its last QA verdict
was FAIL (confirmed via md5==ETag match against the jsonl log) -- these need a real
regen. 12 have no prior render at all. So: 15 canonical exercises actually need new
Gemini generation (14 unique image slugs -- two of the 15 are a case-only duplicate
name that collapses to the same slug), the other 110 are a pure DB bridge (zero spend).

Outputs:
  missing_125_candidates.json  -- the 14 unique slugs to run through run_pipeline.py
  missing_125_bridge_plan.json -- full 125-row plan (canonical_id -> slug -> action)
"""
import json, os, re

BASE = os.path.dirname(os.path.abspath(__file__))
SRC = "/tmp/missing_125.json"

def slug(n):
    return re.sub(r"[^a-z0-9]+", "_", n.lower().strip()).strip("_")

GENDIR = os.path.join(BASE, "generated")
existing_local = set(os.listdir(GENDIR))

# Confirmed-failing slugs (last generated render's md5 == S3 ETag == a FAIL verdict
# in the results*/worker_*.jsonl history). overrides.json already carries targeted
# fixes for all three; they were simply never fully resolved (0/6 attempts passed).
NEEDS_REGEN = {
    "front_squats_kettlelbell_over_shoulders.png",
    "tire_drag_backward.png",
    "battle_rope_lunges_with_waves.png",
}

# Hand-filled equipment/target for the 12 canonical rows with NULL DB metadata or
# NULL equipment (the generator/validator both need a concrete equipment string --
# leaving it blank makes exercise_block() default to "bodyweight only", which is
# wrong for a dumbbell/band/cable move and would silently mis-render).
FILL = {
    "brazilian crunches": {
        "equipment": "Bodyweight", "target_muscle": "Abdominals (Rectus Abdominis), Obliques",
    },
    "bulgarian split squat bodyweight": {
        "equipment": "Bodyweight", "target_muscle": "Quadriceps, Glutes",
    },
    "zotman curls dumbbell simultaneous": {
        "equipment": "Dumbbells", "target_muscle": "Biceps, Forearms (Brachioradialis)",
    },
    "decline bench oblique crunches dumbbells": {
        "equipment": "Dumbbells, Decline Bench", "target_muscle": "Obliques",
    },
    "alternating hammer curls seated dumbbells": {
        "equipment": "Dumbbells, Bench", "target_muscle": "Biceps, Forearms (Brachioradialis)",
    },
    "alternating biceps hammer curls resistance band": {
        "equipment": "Resistance Band", "target_muscle": "Biceps, Forearms (Brachioradialis)",
    },
    "bench bulgarian split squats": {
        "equipment": "Bodyweight, Bench", "target_muscle": "Quadriceps, Glutes",
    },
    "dumbbell lying one arm supinated triceps extension": {
        "equipment": "Dumbbells, Bench", "target_muscle": "Triceps",
    },
    "dumbbell single arm shoulder press": {
        "equipment": "Dumbbells", "target_muscle": "Shoulders (Deltoids)",
    },
    "decline bench oblique crunches bodyweight": {
        "equipment": "Bodyweight, Decline Bench", "target_muscle": "Abdominals, Obliques",
    },
    "dumbbell incline palms-back press": {
        "equipment": "Dumbbells, Incline Bench", "target_muscle": "Chest (Upper), Triceps",
    },
}

def main():
    rows = json.load(open(SRC))
    assert len(rows) == 125, f"expected 125, got {len(rows)}"

    plan = []
    to_generate = {}   # slug -> candidate dict (deduped)
    n_bridge = n_regen = n_new = 0

    for r in rows:
        name = r["canonical_name"]
        s = slug(name)
        fn = s + ".png"
        key = name.strip().lower()
        fill = FILL.get(key, {})
        equipment = r.get("equipment") or fill.get("equipment") or "Bodyweight"
        target = r.get("target_muscle") or fill.get("target_muscle") or "Full Body"

        has_local = fn in existing_local
        action = "bridge" if (has_local and fn not in NEEDS_REGEN) else "generate"
        plan.append({
            "canonical_exercise_id": r["id"], "name": name, "slug": s, "filename": fn,
            "action": action, "equipment": equipment, "target_muscle": target,
        })
        if action == "bridge":
            n_bridge += 1
        else:
            if fn in NEEDS_REGEN:
                n_regen += 1
            else:
                n_new += 1
            if s not in to_generate:
                to_generate[s] = {
                    "name": name, "type": "strength", "equipment": equipment,
                    "target_muscle": target, "style": "dynamic",
                    "slug": s, "filename": fn,
                }

    json.dump(plan, open(os.path.join(BASE, "missing_125_bridge_plan.json"), "w"), indent=2)
    cands = list(to_generate.values())
    json.dump(cands, open(os.path.join(BASE, "missing_125_candidates.json"), "w"), indent=2)

    print(f"125 total: bridge(no-spend)={n_bridge}  regen(prev-fail)={n_regen}  new={n_new}")
    print(f"unique slugs to generate: {len(cands)}")
    for c in cands:
        print(" ", c["name"], "->", c["slug"], "|", c["equipment"], "|", c["target_muscle"])

if __name__ == "__main__":
    main()
