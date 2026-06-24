#!/usr/bin/env python3
"""Calisthenics SKILL PROGRESSION exercises audited as missing (0 images in DB).
Emits missing_progressions_candidates.json + missing_progressions_tracker.md.
Ladders: handstand, box/plyo, push-up, pull-up, muscle-up, planche, front/back lever,
L-sit, human flag, dragon flag, single-leg. Names are English (no Sanskrit)."""
import json, os, re
BASE = os.path.dirname(os.path.abspath(__file__))
def slug(n): return re.sub(r"[^a-z0-9]+", "_", n.lower().strip()).strip("_")

# (name, ladder, equipment, target, category, dynamic, impact, style, difficulty)
ROWS = [
 # HANDSTAND ladder
 ("Wall Walk","handstand","bodyweight","Shoulders, Core","strength",True,"medium","dynamic","intermediate"),
 ("Chest-to-Wall Handstand Hold","handstand","bodyweight","Shoulders","strength",False,"low","static","intermediate"),
 ("Pike Hold","handstand","bodyweight","Shoulders, Core","strength",False,"low","static","beginner"),
 ("Frogstand","handstand","bodyweight","Forearms, Core","strength",False,"low","static","beginner"),
 ("Wall Handstand Push-Up","handstand","bodyweight","Shoulders, Triceps","strength",True,"medium","dynamic","advanced"),
 # BOX / PLYO ladder
 ("Box Step-Up","box","plyo box","Quadriceps, Glutes","strength",True,"low","dynamic","beginner"),
 ("Seated Box Jump","box","plyo box","Quadriceps, Glutes","plyometric",True,"high","dynamic","intermediate"),
 ("Box Jump Over","box","plyo box","Quadriceps, Glutes","plyometric",True,"high","dynamic","advanced"),
 # PUSH-UP ladder
 ("Wall Push-Up","pushup","bodyweight","Chest","strength",True,"low","dynamic","beginner"),
 ("Pseudo Planche Push-Up","pushup","bodyweight","Shoulders, Chest","strength",True,"medium","dynamic","advanced"),
 ("One-Arm Push-Up","pushup","bodyweight","Chest, Triceps","strength",True,"medium","dynamic","expert"),
 # PULL-UP / MUSCLE-UP ladder
 ("Negative Pull-Up","pullup","pull-up bar","Lats, Biceps","strength",True,"low","dynamic","beginner"),
 ("Jumping Muscle-Up","muscleup","pull-up bar","Lats, Chest, Triceps","strength",True,"medium","dynamic","advanced"),
 ("Bar Muscle-Up","muscleup","pull-up bar","Lats, Chest, Triceps","strength",True,"medium","dynamic","expert"),
 ("Ring Muscle-Up","muscleup","gymnastic rings","Lats, Chest, Triceps","strength",True,"medium","dynamic","expert"),
 # PLANCHE ladder
 ("Planche Lean","planche","bodyweight","Shoulders, Core","strength",False,"low","static","intermediate"),
 ("Tuck Planche","planche","bodyweight","Shoulders, Core","strength",False,"low","static","advanced"),
 ("Advanced Tuck Planche","planche","bodyweight","Shoulders, Core","strength",False,"low","static","advanced"),
 ("Straddle Planche","planche","bodyweight","Shoulders, Core","strength",False,"low","static","expert"),
 # FRONT LEVER ladder
 ("Tuck Front Lever","frontlever","pull-up bar","Lats, Core","strength",False,"low","static","intermediate"),
 ("Advanced Tuck Front Lever","frontlever","pull-up bar","Lats, Core","strength",False,"low","static","advanced"),
 ("Straddle Front Lever","frontlever","pull-up bar","Lats, Core","strength",False,"low","static","expert"),
 # BACK LEVER ladder
 ("Tuck Back Lever","backlever","pull-up bar","Lats, Chest","strength",False,"low","static","intermediate"),
 ("Straddle Back Lever","backlever","pull-up bar","Lats, Chest","strength",False,"low","static","advanced"),
 # L-SIT ladder
 ("Foot-Supported L-Sit","lsit","bodyweight","Core, Hip Flexors","strength",False,"low","static","beginner"),
 ("Tuck L-Sit","lsit","bodyweight","Core, Hip Flexors","strength",False,"low","static","intermediate"),
 ("L-Sit","lsit","bodyweight","Core, Hip Flexors","strength",False,"low","static","advanced"),
 ("V-Sit","lsit","bodyweight","Core, Hip Flexors","strength",False,"low","static","expert"),
 # HUMAN FLAG ladder
 ("Vertical Flag","flag","pull-up bar","Obliques, Lats, Shoulders","strength",False,"low","static","intermediate"),
 ("Tuck Human Flag","flag","pull-up bar","Obliques, Lats, Shoulders","strength",False,"low","static","advanced"),
 ("Straddle Human Flag","flag","pull-up bar","Obliques, Lats, Shoulders","strength",False,"low","static","expert"),
 ("Full Human Flag","flag","pull-up bar","Obliques, Lats, Shoulders","strength",False,"low","static","expert"),
 # DRAGON FLAG ladder
 ("Tuck Dragon Flag","dragonflag","bodyweight","Core","strength",False,"low","static","intermediate"),
 ("Straddle Dragon Flag","dragonflag","bodyweight","Core","strength",False,"low","static","advanced"),
 ("Dragon Flag","dragonflag","bodyweight","Core","strength",False,"low","static","expert"),
 # SINGLE-LEG ladder
 ("Shrimp Squat","singleleg","bodyweight","Quadriceps, Glutes","strength",True,"low","dynamic","advanced"),
]

def main():
    items=[]
    for i,(name,ladder,equip,target,cat,dyn,impact,style,diff) in enumerate(ROWS,1):
        items.append({"n":i,"name":name,"type":"progression","ladder":ladder,"equipment":equip,
            "target_muscle":target,"category":cat,"is_dynamic_stretch":dyn,"impact_level":impact,
            "style":style,"difficulty":diff,"slug":slug(name),"filename":slug(name)+".png"})
    json.dump(items,open(os.path.join(BASE,"missing_progressions_candidates.json"),"w"),indent=2)
    lines=["# Missing Calisthenics Progression Exercises — Generation Tracker","",
      f"**Total:** {len(items)} skill-progression moves audited as absent (0 images). Ladders: handstand, box, push-up, pull-up, muscle-up, planche, front/back lever, L-sit, human flag, dragon flag, single-leg.","",
      "| # | Name | Ladder | Difficulty | Equipment | Target Muscle | Filename | Image Generated | Validation | S3 Upload |",
      "|---|------|--------|-----------|-----------|---------------|----------|-----------------|------------|-----------|"]
    for it in items:
        lines.append(f"| {it['n']} | {it['name']} | {it['ladder']} | {it['difficulty']} | {it['equipment']} | "
                     f"{it['target_muscle']} | `{it['filename']}` | ⬜ Pending | ⬜ Pending | ⬜ Pending |")
    open(os.path.join(BASE,"missing_progressions_tracker.md"),"w").write("\n".join(lines)+"\n")
    from collections import Counter
    print(f"wrote {len(items)} progressions. by ladder:", dict(Counter(it['ladder'] for it in items)))

if __name__=="__main__": main()
