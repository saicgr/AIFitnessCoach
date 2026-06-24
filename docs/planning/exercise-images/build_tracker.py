#!/usr/bin/env python3
"""
Source of truth for the MISSING warmup/stretch/yoga/mobility exercises (audited: 0 images
in exercise_library / exercise_library_manual). Emits:
  - missing_warmup_stretch_candidates.json   (consumed by run_pipeline.py --candidates)
  - missing_warmup_stretch_tracker.md        (human-readable progress tracker)

Run:  python build_tracker.py
"""
import json, os, re

BASE = os.path.dirname(os.path.abspath(__file__))

def slug(n): return re.sub(r"[^a-z0-9]+", "_", n.lower().strip()).strip("_")

# category mapping (must be a value the app already uses):
# raise->cardio, activate->strength, mobilize->stretching(dynamic),
# potentiate->plyometric, smr->stretching, static-stretch->stretching, yoga->yoga
# style: which style_prompt variant the generator uses.
# fields: name, type, equipment, target, category, dynamic(bool), impact, style
ROWS = [
 # ---------- RAISE (cardio pulse) ----------
 ("Jog in Place","raise","bodyweight","Calves, Full Body","cardio",True,"medium","dynamic"),
 ("Pogo Hops","raise","bodyweight","Calves","cardio",True,"high","dynamic"),
 ("Lateral Bound","raise","bodyweight","Glutes, Quadriceps","cardio",True,"high","dynamic"),
 ("Line Hops","raise","bodyweight","Calves","cardio",True,"medium","dynamic"),
 ("Grapevine","raise","bodyweight","Adductors, Hips","cardio",True,"medium","dynamic"),
 ("Skater Hops","raise","bodyweight","Glutes, Quadriceps","cardio",True,"high","dynamic"),
 ("Squat Jacks","raise","bodyweight","Quadriceps, Glutes","cardio",True,"high","dynamic"),
 # ---------- ACTIVATE ----------
 ("Monster Walk","activate","resistance band","Gluteus Medius","strength",True,"low","dynamic"),
 ("Standing Lateral Leg Raise","activate","bodyweight","Gluteus Medius","strength",True,"low","dynamic"),
 ("Scapular Push-Up","activate","bodyweight","Serratus Anterior","strength",True,"low","dynamic"),
 ("Glute March","activate","bodyweight","Glutes","strength",True,"low","dynamic"),
 ("Tibialis Raise","activate","bodyweight","Tibialis Anterior","strength",True,"low","dynamic"),
 ("Copenhagen Plank","activate","bodyweight","Adductors","strength",False,"medium","static"),
 ("Banded Squat","activate","resistance band","Quadriceps, Glutes","strength",True,"low","dynamic"),
 ("X-Band Walk","activate","resistance band","Gluteus Medius","strength",True,"low","dynamic"),
 ("Banded Clamshell","activate","resistance band","Gluteus Medius","strength",True,"low","dynamic"),
 ("Terminal Knee Extension","activate","resistance band","Quadriceps (VMO)","strength",True,"low","dynamic"),
 ("Cable Pull-Through","activate","cable machine","Glutes, Hamstrings","strength",True,"low","dynamic"),
 # ---------- MOBILIZE ----------
 ("Shoulder Rolls","mobilize","bodyweight","Shoulders, Upper Trapezius","stretching",True,"low","cars"),
 ("Wrist Circles","mobilize","bodyweight","Forearms, Wrists","stretching",True,"low","cars"),
 ("Knee Circles","mobilize","bodyweight","Knees, Quadriceps","stretching",True,"low","cars"),
 ("Leg Cradle","mobilize","bodyweight","Glutes, Hip Flexors","stretching",True,"low","dynamic"),
 ("Hip Airplane","mobilize","bodyweight","Glutes, Hips","stretching",True,"low","dynamic"),
 ("Gate Opener","mobilize","bodyweight","Hip Abductors","stretching",True,"low","dynamic"),
 ("Gate Closer","mobilize","bodyweight","Hip Adductors","stretching",True,"low","dynamic"),
 ("Toy Soldier Walk","mobilize","bodyweight","Hamstrings","stretching",True,"low","dynamic"),
 ("Straight-Leg Kicks","mobilize","bodyweight","Hamstrings","stretching",True,"low","dynamic"),
 ("Crab Walk","mobilize","bodyweight","Shoulders, Triceps, Glutes","stretching",True,"low","dynamic"),
 ("Duck Walk","mobilize","bodyweight","Quadriceps, Hips","stretching",True,"low","dynamic"),
 ("Beast Crawl","mobilize","bodyweight","Core, Shoulders","stretching",True,"low","dynamic"),
 ("Ankle Rocks","mobilize","bodyweight","Calves, Ankles","stretching",True,"low","dynamic"),
 ("Quadruped Rock-Back","mobilize","bodyweight","Hips, Lower Back","stretching",True,"low","dynamic"),
 ("Segmental Cat-Cow","mobilize","bodyweight","Spine, Core","stretching",True,"low","dynamic"),
 ("Wall Angel","mobilize","bodyweight","Shoulders, Upper Back","stretching",True,"low","dynamic"),
 ("Spiderman Lunge with Reach","mobilize","bodyweight","Hip Flexors, Thoracic Spine","stretching",True,"low","dynamic"),
 ("Sciatic Nerve Floss","mobilize","bodyweight","Hamstrings, Sciatic Nerve","stretching",True,"low","dynamic"),
 ("Cobra to Child Flow","mobilize","bodyweight","Spine, Lats","stretching",True,"low","dynamic"),
 ("Band Shoulder Pass-Through","mobilize","resistance band","Shoulders","stretching",True,"low","dynamic"),
 ("Band Hip Distraction","mobilize","resistance band","Hips","stretching",True,"low","static"),
 ("Band Ankle Mobilization","mobilize","resistance band","Ankles, Calves","stretching",True,"low","dynamic"),
 # ---------- POTENTIATE (plyo) ----------
 ("Broad Jump","potentiate","bodyweight","Quadriceps, Glutes","plyometric",True,"high","dynamic"),
 ("Tuck Jump","potentiate","bodyweight","Quadriceps","plyometric",True,"high","dynamic"),
 ("Depth Jump","potentiate","bodyweight","Quadriceps, Glutes","plyometric",True,"high","dynamic"),
 ("Split Squat Jump","potentiate","bodyweight","Quadriceps, Glutes","plyometric",True,"high","dynamic"),
 ("Single-Leg Hop","potentiate","bodyweight","Calves, Quadriceps","plyometric",True,"high","dynamic"),
 ("Medicine Ball Chest Pass","potentiate","medicine ball","Chest, Triceps","plyometric",True,"medium","dynamic"),
 # ---------- SMR / FOAM ROLL ----------
 ("Foam Roll Calves","smr","foam roller","Calves","stretching",False,"low","smr"),
 ("Foam Roll TFL","smr","foam roller","Tensor Fasciae Latae","stretching",False,"low","smr"),
 ("Foam Roll Shins","smr","foam roller","Tibialis Anterior","stretching",False,"low","smr"),
 ("Foam Roll Forearms","smr","foam roller","Forearms","stretching",False,"low","smr"),
 ("Foam Roll Feet","smr","foam roller","Plantar Fascia, Feet","stretching",False,"low","smr"),
 # ---------- STATIC STRETCH ----------
 ("Upper Trap Stretch","static-stretch","bodyweight","Upper Trapezius","stretching",False,"low","static"),
 ("Levator Scapulae Stretch","static-stretch","bodyweight","Levator Scapulae","stretching",False,"low","static"),
 ("Scalene Stretch","static-stretch","bodyweight","Scalenes","stretching",False,"low","static"),
 ("Suboccipital Stretch","static-stretch","bodyweight","Suboccipitals","stretching",False,"low","static"),
 ("Overhead Shoulder Stretch","static-stretch","bodyweight","Shoulders, Lats","stretching",False,"low","static"),
 ("Pec Minor Stretch","static-stretch","bodyweight","Pectoralis Minor","stretching",False,"low","static"),
 ("Floor Pec Stretch","static-stretch","bodyweight","Pectorals","stretching",False,"low","static"),
 ("Tibialis Stretch","static-stretch","bodyweight","Tibialis Anterior","stretching",False,"low","static"),
 ("Piriformis Stretch","static-stretch","bodyweight","Piriformis, Glutes","stretching",False,"low","static"),
 ("Psoas Stretch","static-stretch","bodyweight","Psoas, Hip Flexors","stretching",False,"low","static"),
 ("Quadratus Lumborum Stretch","static-stretch","bodyweight","Quadratus Lumborum","stretching",False,"low","static"),
 ("Seated Pigeon Stretch","static-stretch","bodyweight","Glutes","stretching",False,"low","static"),
 ("Standing Figure-Four Stretch","static-stretch","bodyweight","Glutes","stretching",False,"low","static"),
 ("Thoracic Extension Stretch","static-stretch","bodyweight","Thoracic Spine","stretching",False,"low","static"),
 ("Hamstring Scoop Stretch","static-stretch","bodyweight","Hamstrings","stretching",False,"low","static"),
 ("Band Hamstring Stretch","static-stretch","resistance band","Hamstrings","stretching",False,"low","static"),
 ("TRX Hamstring Stretch","static-stretch","suspension trainer","Hamstrings","stretching",False,"low","static"),
 ("TRX Shoulder Stretch","static-stretch","suspension trainer","Shoulders","stretching",False,"low","static"),
 # ---------- YOGA ----------
 ("Sphinx Pose","yoga","yoga mat","Lower Back, Abdominals","yoga",False,"low","static"),
 ("Lizard Pose","yoga","yoga mat","Hip Flexors, Hips","yoga",False,"low","static"),
 ("Legs Up the Wall","yoga","yoga mat","Hamstrings","yoga",False,"low","static"),
]

def main():
    items = []
    for i, (name, typ, equip, target, cat, dyn, impact, style) in enumerate(ROWS, 1):
        items.append({
            "n": i, "name": name, "type": typ, "equipment": equip,
            "target_muscle": target, "category": cat,
            "is_dynamic_stretch": dyn, "impact_level": impact,
            "style": style, "slug": slug(name), "filename": slug(name) + ".png",
        })
    with open(os.path.join(BASE, "missing_warmup_stretch_candidates.json"), "w") as f:
        json.dump(items, f, indent=2)

    lines = [
        "# Missing Warmup / Stretch / Yoga / Mobility Exercises — Generation Tracker",
        "",
        f"**Total:** {len(items)} movements audited as ABSENT (0 images in exercise_library / exercise_library_manual).",
        "**Audit basis:** RAMP (Raise/Activate/Mobilize/Potentiate) warm-ups + SMR/static cooldown (NASM) + yoga + equipment-assisted mobility.",
        "**Generator:** `gemini-3.1-flash-image` (3:4)  ·  **Validator:** `gemini-3.5-flash` vision QA.",
        "**Style prompts (by Type):** `style_prompt_dynamic.txt` (raise/activate/potentiate/mobilize) · `style_prompt_static.txt` (static-stretch/yoga) · `style_prompt_smr.txt` (foam roll) · `style_prompt_cars.txt` (rolls/circles).",
        "**Candidate source:** `missing_warmup_stretch_candidates.json` → `python run_pipeline.py --candidates missing_warmup_stretch_candidates.json`",
        "",
        "| # | Name | Type | Equipment | Target Muscle | Filename | Image Generated | Validation | S3 Upload |",
        "|---|------|------|-----------|---------------|----------|-----------------|------------|-----------|",
    ]
    for it in items:
        lines.append(
            f"| {it['n']} | {it['name']} | {it['type']} | {it['equipment']} | "
            f"{it['target_muscle']} | `{it['filename']}` | ⬜ Pending | ⬜ Pending | ⬜ Pending |"
        )
    with open(os.path.join(BASE, "missing_warmup_stretch_tracker.md"), "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {len(items)} rows -> missing_warmup_stretch_candidates.json + missing_warmup_stretch_tracker.md")
    # quick tally by type
    from collections import Counter
    print("by type:", dict(Counter(it["type"] for it in items)))

if __name__ == "__main__":
    main()
