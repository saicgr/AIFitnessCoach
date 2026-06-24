#!/usr/bin/env python3
"""Missing classic yoga poses (Sanskrit), audited absent from the DB. Emits
missing_yoga_candidates.json + missing_yoga_tracker.md. Name format: 'English (Sanskrit)'."""
import json, os, re
BASE = os.path.dirname(os.path.abspath(__file__))
def slug(n): return re.sub(r"[^a-z0-9]+", "_", n.lower().strip()).strip("_")

# (english, sanskrit, target_muscle, dynamic, impact)  — all yoga / yoga mat / static style
ROWS = [
 ("Mountain Pose","Tadasana","Full Body, Posture", False),
 ("Tree Pose","Vrksasana","Glutes, Core (Balance)", False),
 ("Warrior III","Virabhadrasana III","Glutes, Hamstrings (Balance)", False),
 ("Half Moon Pose","Ardha Chandrasana","Glutes, Obliques (Balance)", False),
 ("Dancer Pose","Natarajasana","Quadriceps, Shoulders (Balance)", False),
 ("Eagle Pose","Garudasana","Shoulders, Upper Back", False),
 ("Reverse Warrior","Viparita Virabhadrasana","Obliques, Quadriceps", False),
 ("Revolved Triangle","Parivrtta Trikonasana","Hamstrings, Spine", False),
 ("Revolved Side Angle","Parivrtta Parsvakonasana","Obliques, Hip Flexors", False),
 ("Wide-Legged Forward Fold","Prasarita Padottanasana","Hamstrings, Adductors", False),
 ("Standing Splits","Urdhva Prasarita Eka Padasana","Hamstrings", False),
 ("Half Splits","Ardha Hanumanasana","Hamstrings", False),
 ("Camel Pose","Ustrasana","Hip Flexors, Abdominals (Backbend)", False),
 ("Locust Pose","Salabhasana","Erector Spinae (Lower Back)", False),
 ("Upward-Facing Dog","Urdhva Mukha Svanasana","Erector Spinae, Chest", False),
 ("Boat Pose","Navasana","Abdominals, Hip Flexors", False),
 ("Garland Pose","Malasana","Adductors, Hips (Deep Squat)", False),
 ("Puppy Pose","Uttana Shishosana","Lats, Shoulders, Spine", False),
 ("Fish Pose","Matsyasana","Chest, Front of Neck", False),
 ("Plow Pose","Halasana","Hamstrings, Upper Back", False),
 ("Shoulderstand","Sarvangasana","Shoulders, Core (Inversion)", False),
 ("Wild Thing","Camatkarasana","Chest, Hip Flexors", False),
 ("Seated Spinal Twist","Ardha Matsyendrasana","Spine, Obliques, Glutes", False),
 ("Head-to-Knee Pose","Janu Sirsasana","Hamstrings, Lower Back", False),
 ("Reclined Bound Angle","Supta Baddha Konasana","Adductors, Hip Flexors", False),
 ("Cobbler's Forward Fold","Baddha Konasana Forward","Adductors, Lower Back", False),
 ("Cat Pose to Cow Pose Flow","Marjaryasana Bitilasana","Spine, Core", True),
 ("Sun Salutation B","Surya Namaskar B","Full Body (Flow)", True),
]

def main():
    items=[]
    for i,(eng,san,target,dyn) in enumerate(ROWS,1):
        name=f"{eng} ({san})"
        items.append({"n":i,"name":name,"type":"yoga","equipment":"yoga mat",
            "target_muscle":target,"category":"yoga","is_dynamic_stretch":dyn,
            "impact_level":"low","style":"dynamic" if dyn else "static",
            "slug":slug(name),"filename":slug(name)+".png"})
    json.dump(items,open(os.path.join(BASE,"missing_yoga_candidates.json"),"w"),indent=2)
    lines=["# Missing Yoga Poses (Sanskrit) — Generation Tracker","",
      f"**Total:** {len(items)} classic poses audited as absent (0 images). Naming: 'English (Sanskrit)'.","",
      "| # | Name | Type | Equipment | Target Muscle | Filename | Image Generated | Validation | S3 Upload |",
      "|---|------|------|-----------|---------------|----------|-----------------|------------|-----------|"]
    for it in items:
        lines.append(f"| {it['n']} | {it['name']} | {it['type']} | {it['equipment']} | "
                     f"{it['target_muscle']} | `{it['filename']}` | ⬜ Pending | ⬜ Pending | ⬜ Pending |")
    open(os.path.join(BASE,"missing_yoga_tracker.md"),"w").write("\n".join(lines)+"\n")
    print(f"wrote {len(items)} yoga poses -> missing_yoga_candidates.json + missing_yoga_tracker.md")

if __name__=="__main__": main()
