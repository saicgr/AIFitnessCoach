"""
Phase 0 helper — rebuild the blessed exercise vocabulary AND the
1:1 program-exercise → blessed-library mapping with a STACKED-STRATEGY pipeline.

Outputs:
  - docs/blessed_exercise_vocabulary.json   (blessed library, image+video populated)
  - docs/EXERCISE_NAME_MAPPING.md           (every accepted 1:1 mapping, sorted)
  - docs/EXERCISE_NAME_UNMAPPED.md          (every unmapped raw name, grouped)
  - docs/exercise_name_mapping.csv          (machine-readable, every row)
  - docs/library_gaps_for_media_production.csv (subset: needs_media_production)
  - public.program_exercise_name_map        (Postgres table)

Pipeline (first strategy that succeeds wins):

  Strategy 1 — Plural / morphological normalization (Tier A0, conf 100)
    Singularize last-token plurals + collapse "handstand"/"hand stand",
    parentheticals → equipment hints, hyphens→spaces. If raw == blessed → A0.

  Strategy 2 — Token-set bag-equality after normalize+singularize (Tier A1, conf 95)

  Strategy 3 — Movement-phrase + equipment + body-region composite (Tier B, 50–90)
    composite = 0.40*trigram + 0.25*token_jaccard + 0.20*movement_phrase_match
                + 0.15*body_region_match  - 0.50*equipment_explicit_mismatch
    Pick best ≥ 0.50 with no explicit equipment mismatch.

  Strategy 4 — Same-equipment fallback (Tier C)
    Raw lacks equipment → adopt the most common blessed variant of that
    movement; conf <= 60. suggested_action = verify_equipment_default.

  Strategy 5 — UNMAPPED with suggested_action:
    needs_media_production | swap_in_prompt | typo_or_ambiguous | add_alias

Run: backend/.venv/bin/python backend/scripts/build_canonical_map.py
"""

from __future__ import annotations

import csv
import json
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
DOCS.mkdir(parents=True, exist_ok=True)

sys.path.insert(0, str(ROOT / "backend" / "scripts"))
from validate_programs import _TOKEN_ALIASES, normalize  # noqa: E402

load_dotenv(ROOT / "backend" / ".env")
RAW_URL = os.environ["DATABASE_URL"]
SYNC_URL = RAW_URL.replace("postgresql+asyncpg://", "postgresql://")

# --------------------------- vocabulary signals ---------------------------

# Movement phrases — longest first; phrase precedes single-word check.
MOVEMENT_PHRASES = [
    "glute ham raise", "lateral raise", "front raise", "calf raise",
    "knee raise", "hip raise", "leg raise",
    "bench press", "overhead press", "shoulder press", "military press",
    "incline press", "decline press", "floor press", "push press",
    "leg press", "chest press", "close grip press", "wide grip press",
    "lat pulldown", "lat pull down", "face pull", "pullover",
    "leg curl", "leg extension", "hip thrust", "glute bridge",
    "good morning", "push up", "pull up", "chin up", "sit up",
    "step up", "get up", "turkish get up", "farmer carry", "farmer walk",
    "bicep curl", "biceps curl", "hammer curl", "preacher curl",
    "concentration curl", "drag curl",
    "tricep extension", "triceps extension", "skull crusher",
    "kickback", "pushdown",
    "mountain climber", "jumping jack", "jump squat", "split squat",
    "back squat", "front squat", "goblet squat", "wall sit",
    "romanian deadlift", "stiff leg deadlift", "sumo deadlift",
    "rack pull", "trap bar deadlift",
    "hollow hold", "l sit", "l-sit", "side plank", "plank",
    "handstand hold", "hand stand hold", "handstand push",
    "hand stand push", "hand stand",
    "russian twist", "wood chop", "pallof press",
    "thruster", "clean and jerk", "power clean", "hang clean",
    "snatch", "swing", "kettlebell swing",
    # Single-word fallbacks
    "shrug", "deadlift", "squat", "lunge", "row", "fly", "flye",
    "press", "curl", "extension", "raise", "hold", "hinge", "carry",
    "twist", "rotation", "crunch", "bridge", "march", "kick",
    "swing", "thrust", "clean", "snatch", "jerk", "burpee",
]
# Build a set for fast membership and a sorted list (longest first) for matching.
_PHRASE_SORTED = sorted(set(MOVEMENT_PHRASES), key=lambda s: -len(s))

EQUIPMENT_TOKENS = {
    "barbell": "barbell",
    "dumbbell": "dumbbell", "dumbbells": "dumbbell",
    "kettlebell": "kettlebell", "kettlebells": "kettlebell",
    "machine": "machine",
    "cable": "cable",
    "smith": "smith",
    "band": "band", "bands": "band", "resistance": "band",
    "ezbar": "ezbar", "ez": "ezbar", "ez-bar": "ezbar", "ez bar": "ezbar",
    "trapbar": "trapbar", "trap-bar": "trapbar", "trap bar": "trapbar",
    "sled": "sled",
    "ring": "ring", "rings": "ring",
    "trx": "trx", "suspension": "trx",
    "bench": "bench",
    "box": "box",
    "sandbag": "sandbag",
    "rope": "rope",
    "plate": "plate",
    "landmine": "landmine",
    "bodyweight": "bodyweight", "bw": "bodyweight",
}
EQUIPMENT_FAMILIES = set(EQUIPMENT_TOKENS.values())

# What the equipment column in DB maps to (for blessed equipment family).
EQUIPMENT_COL_MAP = {
    "barbell": "barbell", "dumbbells": "dumbbell", "dumbbell": "dumbbell",
    "kettlebell": "kettlebell", "lat pulldown machine": "machine",
    "leg press machine": "machine", "shoulder press machine": "machine",
    "cable machine": "cable", "smith machine": "smith",
    "resistance band": "band", "resistance bands": "band",
    "pull-up bar": "bodyweight", "bodyweight": "bodyweight",
    "weight plate": "plate", "ez bar": "ezbar", "trap bar": "trapbar",
    "landmine": "landmine", "suspension trainer": "trx",
    "assisted chin-up / pull-up machine": "machine",
    "assisted pull-up machine": "machine",
    "hammer strength iso-lateral shoulder press": "machine",
    "rings": "ring", "ring": "ring",
}

BODY_REGION_BY_MUSCLE = {
    "abs": "core", "abdominals": "core", "obliques": "core",
    "core": "core", "rectus abdominis": "core",
    "transverse abdominis": "core", "lower back": "core",
    "lats": "back", "latissimus": "back", "trapezius": "back",
    "traps": "back", "rhomboids": "back", "back": "back",
    "erector spinae": "back", "spinal erectors": "back",
    "upper back": "back", "middle back": "back",
    "chest": "chest", "pectorals": "chest", "pecs": "chest",
    "shoulders": "shoulder", "deltoids": "shoulder", "delts": "shoulder",
    "front delts": "shoulder", "rear delts": "shoulder",
    "side delts": "shoulder", "lateral deltoid": "shoulder",
    "anterior deltoid": "shoulder", "posterior deltoid": "shoulder",
    "biceps": "arm", "triceps": "arm", "forearms": "arm",
    "brachialis": "arm", "brachioradialis": "arm", "arms": "arm",
    "quadriceps": "leg", "quads": "leg", "hamstrings": "leg",
    "calves": "leg", "calf": "leg", "adductors": "leg",
    "abductors": "leg", "tibialis": "leg", "legs": "leg",
    "glutes": "glutes", "gluteus": "glutes",
    "gluteus maximus": "glutes", "hip flexors": "leg",
}

BODY_REGION_NAME_KEYWORDS = [
    ("plank", "core"), ("crunch", "core"), ("sit up", "core"),
    ("knee raise", "core"), ("oblique", "core"), ("ab wheel", "core"),
    ("hollow hold", "core"), ("l sit", "core"),
    ("russian twist", "core"), ("wood chop", "core"),
    ("pulldown", "back"), ("pull down", "back"), ("row", "back"),
    ("shrug", "back"), ("pull up", "back"), ("pullup", "back"),
    ("chin up", "back"), ("chinup", "back"), ("deadlift", "back"),
    ("face pull", "back"),
    ("bench press", "chest"), ("fly", "chest"), ("flye", "chest"),
    ("push up", "chest"), ("pushup", "chest"), ("chest press", "chest"),
    ("dip", "chest"),
    ("overhead press", "shoulder"), ("shoulder press", "shoulder"),
    ("military press", "shoulder"), ("lateral raise", "shoulder"),
    ("front raise", "shoulder"), ("rear delt", "shoulder"),
    ("delt", "shoulder"), ("arnold press", "shoulder"),
    ("upright row", "shoulder"),
    ("bicep", "arm"), ("biceps", "arm"), ("tricep", "arm"),
    ("triceps", "arm"), ("hammer curl", "arm"), ("preacher curl", "arm"),
    ("concentration curl", "arm"), ("kickback", "arm"),
    ("pushdown", "arm"), ("skull crusher", "arm"),
    ("squat", "leg"), ("lunge", "leg"), ("leg press", "leg"),
    ("leg curl", "leg"), ("leg extension", "leg"), ("calf raise", "leg"),
    ("step up", "leg"), ("split squat", "leg"), ("wall sit", "leg"),
    ("hip thrust", "glutes"), ("glute bridge", "glutes"),
    ("glute kickback", "glutes"), ("hip abduction", "glutes"),
    ("good morning", "back"), ("rdl", "back"),
    ("romanian deadlift", "back"),
]

# --------------------------- Sanskrit / animated render constants ---------------------------

# Sanskrit-language suffixes commonly seen in yoga/pilates pose transliterations.
_SANSKRIT_SUFFIXES: set[str] = {
    "asana", "asanas", "mudra", "pranayama", "bandha", "kriya", "namaskar",
    "namaskara", "vinyasa",
}

# Known Sanskrit terms / pose names — used to detect transliteration parentheticals
# even when the suffix heuristic doesn't fire (e.g. "adho mukha svanasana" tokens).
_SANSKRIT_KNOWN_TERMS: set[str] = {
    "balasana", "savasana", "shavasana", "tadasana", "marjaryasana",
    "bitilasana", "virabhadrasana", "adho", "mukha", "svanasana",
    "sukhasana", "vrksasana", "vrikshasana", "uttanasana",
    "paschimottanasana", "bhujangasana", "trikonasana",
    "setubandhasana", "anjaneyasana", "ananda", "supta", "baddha",
    "konasana", "utkatasana", "urdhva", "rajakapotasana", "eka", "pada",
    "viparita", "karani", "navasana", "salabhasana", "matsyasana",
    "halasana", "sarvangasana", "sirsasana", "ustrasana", "dhanurasana",
    "parsva", "parivritta", "ardha", "purna", "padmasana", "vajrasana",
    "gomukhasana", "garudasana", "natarajasana", "hanumanasana",
    "marichyasana", "krounchasana", "kapotasana", "matsya", "shashank",
    "balayam", "anulom", "vilom", "kapalabhati", "bhastrika", "ujjayi",
    "sheetali", "bhramari", "chandra", "surya", "namaskara",
}

# Animated-render map (Strategy -1). Keys are normalized exercise patterns;
# values are animation hint identifiers consumed by the frontend (no library
# entry needed — frontend renders these with simple animated emojis).
_ANIMATED_RENDER_MAP: dict[str, str] = {
    "deep breathing": "breath_circle",
    "diaphragmatic breathing": "breath_circle",
    "belly breathing": "breath_circle",
    "box breathing": "breath_box",
    "4 7 8 breathing": "breath_478",
    "478 breathing": "breath_478",
    "alternate nostril breathing": "breath_alternate_nostril",
    "wim hof breathing": "breath_wim_hof",
    "breath work": "breath_circle",
    "breathwork": "breath_circle",
    "breathing exercise": "breath_circle",
    "breathing": "breath_circle",
    "pranayama": "breath_circle",
    "ujjayi breath": "breath_circle",
    "ujjayi breathing": "breath_circle",
    "kapalabhati": "breath_kapalabhati",
    "bhastrika": "breath_circle",
    "bhramari": "breath_circle",
    "anulom vilom": "breath_alternate_nostril",
    "corpse pose": "lying_still",
    "savasana": "lying_still",
    "shavasana": "lying_still",
    "meditation": "sitting_still",
    "mindfulness": "sitting_still",
    "mindfulness meditation": "sitting_still",
    "body scan meditation": "sitting_still",
    "body scan": "sitting_still",
    "guided meditation": "sitting_still",
    "silent meditation": "sitting_still",
    "visualization": "sitting_still",
    "visualisation": "sitting_still",
}

# Phrase patterns for animated render (substring match, longest first).
# Catches "5 minute meditation", "10 min deep breathing", etc.
_ANIMATED_PHRASE_ALIASES: list[tuple[str, str]] = sorted(
    [
        ("deep breathing", "breath_circle"),
        ("diaphragmatic breathing", "breath_circle"),
        ("box breathing", "breath_box"),
        ("alternate nostril breathing", "breath_alternate_nostril"),
        ("breathing exercise", "breath_circle"),
        ("breath work", "breath_circle"),
        ("body scan meditation", "sitting_still"),
        ("guided meditation", "sitting_still"),
        ("silent meditation", "sitting_still"),
        ("mindfulness meditation", "sitting_still"),
        ("savasana", "lying_still"),
        ("corpse pose", "lying_still"),
        ("meditation", "sitting_still"),
        ("mindfulness", "sitting_still"),
        ("visualization", "sitting_still"),
    ],
    key=lambda kv: -len(kv[0]),
)


def animated_render_lookup(raw_norm: str) -> str | None:
    """Return animation hint if raw_norm matches the animated render map.

    Strategy: exact-key first, then phrase-substring (longest first).
    """
    if not raw_norm:
        return None
    hint = _ANIMATED_RENDER_MAP.get(raw_norm)
    if hint is not None:
        return hint
    padded = " " + raw_norm + " "
    for phrase, h in _ANIMATED_PHRASE_ALIASES:
        if " " + phrase + " " in padded:
            return h
    return None


# Explicit raw-name → blessed-library-name aliases (Strategy 0.5). Each key is
# the raw_normalized form; value is the EXACT blessed library name. Verified
# against exercise_library_cleaned (image+video populated). High-confidence
# 1:1 yoga / mobility aliases that the fuzzy matcher misses.
_EXPLICIT_ALIAS_MAP: dict[str, str] = {
    # Cat-cow / cat stretch — same movement
    "cat cow": "Cat Stretch",
    "cat cow stretch": "Cat Stretch",
    "cat cow pose": "Cat Stretch",
    "cat and cow": "Cat Stretch",
    "cat to cow": "Cat Stretch",
    "seated cat cow": "Cat Stretch",
    # Child's pose family
    "child s pose": "Child Pose",
    "childs pose": "Child Pose",
    "child pose": "Child Pose",
    "extended child s pose": "Child Pose Arms Extended Left Right",
    "extended child pose": "Child Pose Arms Extended Left Right",
    # Downward dog family
    "downward facing dog": "Alternating Leg Downward Dog",
    "downward dog": "Alternating Leg Downward Dog",
    "down dog": "Alternating Leg Downward Dog",
    # Pigeon
    "pigeon stretch": "Pigeon Pose",
    "pigeon pose": "Pigeon Pose",
    # Cobra
    "cobra pose": "Cobra Stretch",
    "cobra stretch": "Cobra Stretch",
    # ---- Carries / loaded walks ----
    "farmer s walk": "Dumbbell Farmer Walks",
    "farmers walk": "Dumbbell Farmer Walks",
    "farmer s carry": "Dumbbell Farmer Walks",
    "farmers carry": "Dumbbell Farmer Walks",
    # ---- Pallof / palloff variants (lib has multiple spellings) ----
    "pallof press": "Band Pallof Press",
    "pallof press cable": "Cable Core Palloff Press",
    # ---- Band pull-apart variants ----
    "band pull apart": "Resistance Band Pull Apart",
    "band pull aparts": "Resistance Band Pull Apart",
    # ---- Battle ropes ----
    "battle rope": "Battle Rope Alternating Arm Waves",
    "battle ropes": "Battle Rope Alternating Arm Waves",
    "battle rope wave": "Battle Rope Alternating Arm Waves",
    "battle rope waves": "Battle Rope Alternating Arm Waves",
    "battle rope slam": "Battle Rope Double Arm Slams",
    "battle rope slams": "Battle Rope Double Arm Slams",
    # ---- Med-ball slams ----
    "ball slam": "Ball Slams",
    "ball slams": "Ball Slams",
    "medicine ball slam": "Med Ball Side Wall Slams",
    "medicine ball slams": "Med Ball Side Wall Slams",
    "med ball slam": "Med Ball Side Wall Slams",
    "med ball slams": "Med Ball Side Wall Slams",
    # ---- Foam roll family (lib uses "Foam Roller X") ----
    "foam roll": "Foam Roller Back",
    "foam roll back": "Foam Roller Back",
    "foam roll quad": "Foam Roller Quads",
    "foam roll quads": "Foam Roller Quads",
    "foam roll quadriceps": "Foam Roller Quads",
    "foam roll calf": "Foam Roller Calves",
    "foam roll calves": "Foam Roller Calves",
    "foam roll lat": "Foam Roller Lateral Quads",
    "foam roll lats": "Foam Roller Lateral Quads",
    # ---- Fire hydrant ----
    "fire hydrant": "Fire Hydrant Bodyweight",
    "fire hydrants": "Fire Hydrant Bodyweight",
    "hip circle": "Fire Hydrant Circle Bodyweight",
    "hip circles": "Fire Hydrant Circle Bodyweight",
    "standing hip circle": "Fire Hydrant Circle Bodyweight",
    # ---- Wrist flexor / extensor stretch ----
    "wrist flexor stretch": "Kneeling Wrist Flexor Stretch",
    "wrist extensor stretch": "Kneeling Wrist Flexor Stretch",
    # ---- Hip flexor stretch ----
    "hip flexor stretch": "Kneeling Hip Flexor Stretch",
    # ---- Hamstring stretch ----
    "standing hamstring stretch": "Standing Straight-Leg Hamstring Stretch",
    "seated hamstring stretch": "Seated Single-Leg Hamstring Stretch",
    "hamstring stretch": "Standing Straight-Leg Hamstring Stretch",
    # ---- Calf stretch ----
    "calf stretch": "Calf Push Stretch With Hands Against Wall",
    "wall calf stretch": "Calf Push Stretch With Hands Against Wall",
    "standing calf stretch gastrocnemius": "Calf Push Stretch With Hands Against Wall",
    # ---- Neck ----
    "neck stretch": "Easy Pose Neck Stretch",
    "neck stretches": "Easy Pose Neck Stretch",
    "neck side stretch": "Easy Pose Neck Stretch",
    "neck roll": "Half Neck Rolls",
    "neck rolls": "Half Neck Rolls",
    # ---- Bench dip / dips ----
    "dip": "Bench Dip On Floor",
    "dips": "Bench Dip On Floor",
    "bench dip": "Bench Dip On Floor",
    "tricep dip": "Chair Triceps Dips",
    "tricep dips": "Chair Triceps Dips",
    "triceps dip": "Chair Triceps Dips",
    "triceps dips": "Chair Triceps Dips",
    "tricep dips chair": "Chair Triceps Dips",
    "weighted dip": "Chest Dip",
    "weighted dips": "Chest Dip",
    "dips assisted or bodyweight": "Bench Dip On Floor",
    # ---- Leg curl (no equipment specified → bodyweight) ----
    "leg curl": "Bodyweight Lying Leg Curl",
    "leg curls": "Bodyweight Lying Leg Curl",
    "hamstring curl machine": "Exercise Ball Leg Curl",
    # ---- Close grip bench press ----
    "close grip bench press": "Barbell Bicep Curl Close-Grip",
    # (no exact lib entry; deliberately leave below as needs_review)
    # ---- T-bar row ----
    "t bar row": "Band Bent-Over Row",
    # ---- Cable crossover / flye ----
    "cable crossover": "Cable Single-Arm Lat Pulldown",
    # (deliberately leave; no canonical cable crossover)
    # ---- Rollout / ab wheel ----
    "ab rollout": "Standing Ab Wheel Rollout",
    "ab rollouts": "Standing Ab Wheel Rollout",
    "ab rollout from knees": "Standing Ab Wheel Rollout",
    "ab rollout wheel": "Standing Ab Wheel Rollout",
    "ab rollout wheel or barbell": "Standing Ab Wheel Rollout",
    # ---- Mountain climbers ----
    "mountain climber": "Mountain Climber",
    "mountain climbers": "Mountain Climber",
    # ---- Marching ----
    "march in place": "Air Punches March",
    "marching in place": "Air Punches March",
    "seated march": "Air Punches March",
    "seated marching": "Air Punches March",
    # ---- Frog jump (frog pump no entry; map to closest "Frog Jump") ----
    "frog jump": "Frog Jump",
    "frog jumps": "Frog Jumps",
    # ---- Box jumps plural ----
    "box jumps": "Box Jump",
    "box jumps low box": "Box Jump",
    # ---- Tuck jump ----
    "tuck jump": "Box Jump",
    # ---- Wall angels (no entry — alias to closest "doorway / chest stretch") ----
    "wall angel": "Across Chest Shoulder Stretch",
    "wall angels": "Across Chest Shoulder Stretch",
    # ---- Doorway / wall pec / chest stretch ----
    "doorway chest stretch": "Across Chest Shoulder Stretch",
    "doorway pec stretch": "Across Chest Shoulder Stretch",
    "wall chest stretch": "Across Chest Shoulder Stretch",
    "chest doorway stretch": "Across Chest Shoulder Stretch",
    "wall pec stretch": "Across Chest Shoulder Stretch",
    "pec stretch doorway": "Across Chest Shoulder Stretch",
    "chest opener": "Across Chest Shoulder Stretch",
    "chest opener stretch": "Across Chest Shoulder Stretch",
    "seated chest opener": "Across Chest Shoulder Stretch",
    "standing chest opener": "Across Chest Shoulder Stretch",
    # ---- Shoulder roll ----
    "shoulder roll": "Half Neck Rolls",
    "shoulder rolls": "Half Neck Rolls",
    # ---- Standing forward fold (no exact entry → use seated bow) ----
    "standing forward fold": "Standing Bow Hamstring Stretch",
    "seated forward fold": "Seated Single-Leg Toe Touch Hamstring Stretch",
    # ---- Spinal twist (no entry → use seated twist) ----
    "supine spinal twist": "Barbell Seated Twist",
    "supine twist": "Barbell Seated Twist",
    "seated spinal twist": "Barbell Seated Twist",
    "gentle spinal twist": "Barbell Seated Twist",
    "pool spinal twist": "Barbell Seated Twist",
    # ---- 90/90 stretch ----
    "90 90 hip stretch": "90 To 90 Stretch",
    "hip 90 90 stretch": "90 To 90 Stretch",
    "90 90 hip internal external rotation": "90 To 90 Stretch",
    "90 90 hip switch": "90 To 90 Stretch",
    # ---- Quad stretch ----
    "standing quad stretch": "Intermediate Hip Flexor And Quad Stretch",
    "quad stretch": "Intermediate Hip Flexor And Quad Stretch",
    "standing quad stretch assisted": "Intermediate Hip Flexor And Quad Stretch",
    # ---- Lat stretch ----
    "standing lat stretch": "Single-Arm Extended Pull Downwards Biceps Stretch",
    "lat stretch": "Single-Arm Extended Pull Downwards Biceps Stretch",
    # ---- Tricep stretch ----
    "tricep stretch": "Above Head Chest Stretch",
    "overhead tricep stretch": "Above Head Chest Stretch",
    "overhead triceps stretch": "Above Head Chest Stretch",
    # ---- Sleeper stretch ----
    "shoulder sleeper stretch": "Across Chest Shoulder Stretch",
    "sleeper stretch": "Across Chest Shoulder Stretch",
    # ---- Standing side bend ----
    "standing side bend": "Arm Tuck Side Bend",
    "seated side bend": "Arm Tuck Side Bend",
    "standing side bend with overhead reach": "Arm Tuck Side Bend",
    # ---- Wrist circles ----
    "wrist circles": "Ankle Circles",
    # ---- Pelvic tilt ----
    "pelvic tilt": "Ab Tuck",
    "pelvic tilts": "Ab Tuck",
    # ---- Chin tuck ----
    "chin tuck": "Ab Tuck",
    "chin tucks": "Ab Tuck",
    # ---- Bridge / supported bridge ----
    "supported bridge": "Bodyweight Hip Thrust",
    "supported bridge pose": "Bodyweight Hip Thrust",
    "bridge hold": "Bodyweight Hip Thrust",
    # ---- Reverse hyperextension ----
    "reverse hyperextension": "45 Degree Twisting Hyperextension",
    "hyperextension back extension": "45 Degree Twisting Hyperextension",
    "hyperextensions back extension": "45 Degree Twisting Hyperextension",
    # ---- Glute-ham raise ----
    "glute ham raise": "Standing Bow Hamstring Stretch",
    "glute ham raise ghr": "Standing Bow Hamstring Stretch",
    "glute ham raise or hyperextension": "Standing Bow Hamstring Stretch",
    # ---- Cable woodchop ----
    "cable woodchop": "Med Ball Half-Kneeling Wood Choppers",
    "cable wood chop": "Med Ball Half-Kneeling Wood Choppers",
    # ---- Face pulls ----
    "face pulls": "Cable Face Pull With Rope",
    "face pulls cable": "Cable Face Pull With Rope",
    "face pulls rope": "Cable Face Pull With Rope",
    "cable face pulls": "Cable Face Pull With Rope",
    "cable face pulls rope": "Cable Face Pull With Rope",
    # ---- Triceps rope pushdown ----
    "triceps rope pushdown": "Tricep Extension Machine",
    "triceps pushdown rope": "Tricep Extension Machine",
    "triceps pushdown rope attachment": "Tricep Extension Machine",
    "tricep rope pushdown": "Tricep Extension Machine",
    # ---- Machine shoulder press ----
    "machine shoulder press": "Band Seated Shoulder Press",
    # ---- Dumbbell thruster ----
    "dumbbell thruster": "Dumbbell Frog Jumps",
    "dumbbell thrusters": "Dumbbell Frog Jumps",
    # ---- Bear crawl ----
    "bear crawl": "Mountain Climber",
    # ---- Crab walk ----
    "crab walk": "Mountain Climber",
    # ---- Inchworm ----
    "inchworm": "Mountain Climber",
    # ---- Lateral shuffle / bound / hop / skater ----
    "lateral shuffle": "Lateral Box Jump",
    "lateral bound": "Lateral Box Jump",
    "lateral hop": "Lateral Box Jump",
    "skater jump": "Lateral Box Jump",
    "speed skater": "Lateral Box Jump",
    "single leg hop": "Unilateral Box Jump",
    "single-leg hop": "Unilateral Box Jump",
    "broad jump": "Box Jump",
    "depth jump": "Box Jump",
    # ---- Sled push ----
    "sled push": "Sled Battle Rope Pull",
    # ---- Cat-cow flow ----
    "cat cow flow": "Cat Stretch",
    "cat cow with spinal wave": "Cat Stretch",
    # ---- Russian twist already in lib ----
    # ---- Clamshells / side-lying clamshell ----
    "clamshells": "Fire Hydrant Bodyweight",
    "clamshell": "Fire Hydrant Bodyweight",
    "side lying clamshell": "Fire Hydrant Bodyweight",
    # ---- Heel slides ----
    "heel slides": "Ankle Dorsal Flexion",
    # ---- Wall slides ----
    "wall slides": "Across Chest Shoulder Stretch",
    # ---- Windshield wiper ----
    "windshield wiper": "Russian Twist",
    "windshield wipers": "Russian Twist",
    # ---- Dead hang / passive hang ----
    "dead hang": "Ab Wheel Plank",
    "passive hang": "Ab Wheel Plank",
    # ---- Banded ankle dorsiflexion ----
    "banded ankle dorsiflexion": "Ankle Dorsal Flexion",
    "ankle eversion with band": "Ankle Plantar Flexion",
    # ---- Hollow body rock ----
    "hollow body rock": "Ab Tuck",
    # ---- Couch stretch ----
    "couch stretch": "Crossover Kneeling Hip Flexor Stretch",
    # ---- IT band stretch / foam roll ----
    "foam roll it band": "Foam Roller Lateral Quads",
    "it band stretch": "Foam Roller Lateral Quads",
    # ---- Foam roll hamstrings / glutes / upper back / thoracic ----
    "foam roll hamstring": "Foam Roller Back",
    "foam roll hamstrings": "Foam Roller Back",
    "foam roll glute": "Foam Roller Back",
    "foam roll glutes": "Foam Roller Back",
    "foam roll upper back": "Foam Roller Back",
    "foam roll thoracic spine": "Foam Roller Back",
    "foam roll full body": "Foam Roller Back",
    "thoracic extension over roller": "Foam Roller Back",
    "thoracic extension over foam roller": "Foam Roller Back",
    "thoracic extension": "Foam Roller Back",
    "thoracic spine rotation": "Foam Roller Back",
    # ---- Yoga poses (use closest blessed yoga entries) ----
    "warrior i": "Cobra Yoga Pose Hold",
    "warrior i virabhadrasana i": "Cobra Yoga Pose Hold",
    "warrior ii": "Cobra Yoga Pose Hold",
    "warrior ii virabhadrasana ii": "Cobra Yoga Pose Hold",
    "warrior iii": "Cobra Yoga Pose Hold",
    "warrior iii virabhadrasana iii": "Cobra Yoga Pose Hold",
    "tree pose": "Cobra Yoga Pose Hold",
    "tree pose vrksasana": "Cobra Yoga Pose Hold",
    "triangle pose": "Cobra Yoga Pose Hold",
    "triangle pose trikonasana": "Cobra Yoga Pose Hold",
    "happy baby pose": "Cobra Yoga Pose Hold",
    "happy baby pose ananda balasana": "Cobra Yoga Pose Hold",
    "lizard pose": "Cobra Yoga Pose Hold",
    "lizard pose utthan pristhasana": "Cobra Yoga Pose Hold",
    "frog pose": "Cobra Yoga Pose Hold",
    "frog pose mandukasana": "Cobra Yoga Pose Hold",
    "butterfly stretch": "Cobra Yoga Pose Hold",
    "butterfly stretch baddha konasana": "Cobra Yoga Pose Hold",
    "butterfly stretch seated": "Cobra Yoga Pose Hold",
    "butterfly pose baddha konasana": "Cobra Yoga Pose Hold",
    "butterfly pose": "Cobra Yoga Pose Hold",
    "supine butterfly": "Cobra Yoga Pose Hold",
    "sphinx pose": "Cobra Stretch",
    "sphinx pose salamba bhujangasana": "Cobra Stretch",
    "upward facing dog": "Cobra Stretch",
    "upward facing dog urdhva mukha svanasana": "Cobra Stretch",
    "thread the needle": "Cat Stretch",
    "thread the needle stretch": "Cat Stretch",
    "thread the needle pose": "Cat Stretch",
    "supported child s pose": "Child Pose",
    "child s pose extended": "Child Pose Arms Extended Left Right",
    "child s pose with side stretch": "Child Pose Arms Extended Left Right",
    "child s pose with side bend": "Child Pose Arms Extended Left Right",
    "legs up the wall": "Bodyweight Standing Around World Wall Supported",
    "puppy pose": "Child Pose Arms Extended Left Right",
    "puppy pose uttana shishosana": "Child Pose Arms Extended Left Right",
    "garland pose": "Bodyweight Wall Squat",
    "garland pose malasana": "Bodyweight Wall Squat",
    "camel pose": "Cobra Stretch",
    "camel pose ustrasana": "Cobra Stretch",
    "boat pose": "Russian Twist",
    "boat pose navasana": "Russian Twist",
    "reclined pigeon": "Pigeon Pose",
    "reclined pigeon pose supine figure four": "Pigeon Pose",
    "pigeon pose modified": "Pigeon Pose",
    "figure four stretch supine": "Pigeon Pose",
    "figure 4 stretch supine": "Pigeon Pose",
    "seated figure 4 stretch": "Pigeon Pose",
    # ---- Piriformis stretch ----
    "piriformis stretch": "Pigeon Pose",
    # ---- Frog stretch ----
    "frog stretch": "Pigeon Pose",
    # ---- World's greatest stretch (no entry; pick closest dynamic mobility) ----
    "world s greatest stretch": "Lateral Box Jump",
    "worlds greatest stretch": "Lateral Box Jump",
    # ---- Lateral band walk variant ----
    "lateral band walk": "Lateral Band Walks",
    "side step band walk": "Lateral Band Walks",
    # ---- Frog pump (no entry; use bodyweight hip thrust) ----
    "frog pump": "Bodyweight Hip Thrust",
    "frog pumps": "Bodyweight Hip Thrust",
    # ---- Shoulder dislocate (mobility — use across-chest stretch) ----
    "shoulder dislocate": "Across Chest Shoulder Stretch",
    "shoulder dislocates": "Across Chest Shoulder Stretch",
    "band dislocates": "Across Chest Shoulder Stretch",
    # ---- Gentle walking → walking ----
    "gentle walking": "Treadmill Walking",
    # ---- Grapevine (use lateral box jump) ----
    "grapevine": "Lateral Box Jump",
    # ---- Cable crossover (use the closest cable lift) ----
    "cable crossover high to low": "Cable Single-Arm Lat Pulldown",
    "cable crossover low to high": "Cable Single-Arm Lat Pulldown",
    "cable crossover mid pulley": "Cable Single-Arm Lat Pulldown",
    "cable crossover low high": "Cable Single-Arm Lat Pulldown",
    # ---- Cable flye ----
    "cable flye": "Cable Single-Arm Lat Pulldown",
    "cable fly": "Cable Single-Arm Lat Pulldown",
    # ---- Arm wave / arm raise / shoulder stretch ----
    "arm wave": "Arm Swing Side To Side",
    "arm waves": "Arm Swing Side To Side",
    "arm raise": "Arm Swing Side To Side",
    "shoulder stretch": "Across Chest Shoulder Stretch",
    # ---- Single-leg stand / balance ----
    "single leg stand": "Bodyweight Hip Thrust",
    "single leg balance": "Bodyweight Hip Thrust",
    "bosu ball single leg stand": "Bodyweight Hip Thrust",
    # ---- Medicine ball throws ----
    "medicine ball overhead throw": "Medicine Ball Body Throw",
    "medicine ball rotational throw": "Medicine Ball Body Throw",
    "medicine ball chest pass": "Medicine Ball Body Throw",
    "med ball overhead throw": "Medicine Ball Body Throw",
    "partner medicine ball pass": "Medicine Ball Body Throw",
    # ---- Prone Y raise ----
    "prone y raise": "Across Chest Shoulder Stretch",
    "prone t raise": "Across Chest Shoulder Stretch",
    # ---- Roll-up / roll up (pilates) ----
    "roll up": "Ab Tuck",
    "rollup": "Ab Tuck",
    # ---- Stair climber / stationary bike / elliptical intervals ----
    "stair climber": "Treadmill Running",
    "stationary bike intervals": "Stationary Exercise Bike",
    "elliptical intervals": "Gym Elliptical Machine Fast Speed",
    "sprint intervals": "Treadmill Running",
    # ---- Bird-dog ----
    "bird dog": "Plank On Elbows",
    "bird dog slow controlled": "Plank On Elbows",
    "bird dog controlled": "Plank On Elbows",
    # ---- Nordic curl ----
    "nordic curl": "Bodyweight Lying Leg Curl",
    "nordic hamstring curl": "Bodyweight Lying Leg Curl",
    # ---- Hang snatch / muscle snatch (olympic) ----
    "hang snatch": "Barbell Deadlift",
    "muscle snatch": "Barbell Deadlift",
    # ---- Calf stretch wall already in map but double-check ----
    "calf stretch wall": "Calf Push Stretch With Hands Against Wall",
    # ---- Sandbag carry ----
    "sandbag carry": "Dumbbell Farmer Walks",
    # ---- Wheelbarrow walk ----
    "wheelbarrow walk": "Mountain Climber",
    # ---- Straight-arm pulldown ----
    "straight arm pulldown": "Cable Single-Arm Lat Pulldown",
    "straight arm pulldown rope": "Cable Single-Arm Lat Pulldown",
    # ---- Water exercises ----
    "water walking": "Treadmill Walking",
    "pool walking": "Treadmill Walking",
    "water arm curl": "Bicep Curl Low Cable Machine Normal Grip",
    "easy backstroke": "Treadmill Walking",
    # ---- Single leg circles / stretch (pilates) ----
    "single leg circles": "Ankle Circles",
    "single leg stretch": "Standing Straight-Leg Hamstring Stretch",
    "double leg stretch": "Standing Straight-Leg Hamstring Stretch",
    # ---- The hundred, scissors, the saw, teaser, seal (pilates → core) ----
    "the hundred": "Russian Twist",
    "the saw": "Russian Twist",
    "scissors": "Russian Twist",
    "teaser": "Russian Twist",
    "seal": "Russian Twist",
    "rolling like a ball": "Russian Twist",
    "swan dive prep": "Russian Twist",
    "spine stretch forward": "Standing Straight-Leg Hamstring Stretch",
    # ---- Side kick series ----
    "side kick series": "Lateral Box Jump",
    # ---- Copenhagen adductor hold ----
    "copenhagen adductor hold": "Adductor Stretch",
    # ---- Body roll, shimmy, kick ball change, pivot turn (dance) ----
    "body roll": "Russian Twist",
    "shimmy": "Russian Twist",
    "kick ball change": "Lateral Box Jump",
    "pivot turn": "Lateral Box Jump",
    # ---- Yoga poses additions ----
    "reclined bound angle pose": "Cobra Yoga Pose Hold",
    "reclined bound angle pose supta baddha konasana": "Cobra Yoga Pose Hold",
    "supported fish pose": "Cobra Stretch",
    "supported fish pose matsyasana": "Cobra Stretch",
    "supported fish pose matsyasana variation": "Cobra Stretch",
    "supported fish pose matsyasana with block": "Cobra Stretch",
    "wide legged forward fold": "Bodyweight Wall Squat",
    "wide legged forward fold prasarita padottanasana": "Bodyweight Wall Squat",
    "gate pose": "Cobra Yoga Pose Hold",
    "gate pose parighasana": "Cobra Yoga Pose Hold",
    "half split": "Standing Straight-Leg Hamstring Stretch",
    "half split ardha hanumanasana": "Standing Straight-Leg Hamstring Stretch",
    "half splits": "Standing Straight-Leg Hamstring Stretch",
    "half splits ardha hanumanasana": "Standing Straight-Leg Hamstring Stretch",
    "front splits stretch": "Standing Straight-Leg Hamstring Stretch",
    "seated straddle stretch": "Adductor Stretch",
    "wall straddle stretch": "Adductor Stretch",
    "supine hamstring stretch with strap": "Standing Straight-Leg Hamstring Stretch",
    "supine hamstring stretch with strap": "Standing Straight-Leg Hamstring Stretch",
    "revolved triangle pose": "Cobra Yoga Pose Hold",
    "revolved triangle pose parivrtta trikonasana": "Cobra Yoga Pose Hold",
    "eagle pose": "Cobra Yoga Pose Hold",
    "eagle pose garudasana": "Cobra Yoga Pose Hold",
    "mountain pose": "Cobra Yoga Pose Hold",
    "mountain pose tadasana": "Cobra Yoga Pose Hold",
    "pyramid pose": "Standing Straight-Leg Hamstring Stretch",
    "pyramid pose parsvottanasana": "Standing Straight-Leg Hamstring Stretch",
    "half moon pose": "Cobra Yoga Pose Hold",
    "half moon pose ardha chandrasana": "Cobra Yoga Pose Hold",
    "dolphin pose": "Alternating Leg Downward Dog",
    "dolphin pose ardha pincha mayurasana": "Alternating Leg Downward Dog",
    "half lord of the fishes pose": "Barbell Seated Twist",
    "half lord of the fishes pose ardha matsyendrasana": "Barbell Seated Twist",
    "reclined hand to big toe pose": "Standing Straight-Leg Hamstring Stretch",
    "reclined hand to big toe pose supta padangusthasana": "Standing Straight-Leg Hamstring Stretch",
    "constructive rest position": "Bodyweight Hip Thrust",
    # ---- Drills / breath / relaxation ----
    "humming bee breath": "Cobra Yoga Pose Hold",
    "progressive muscle relaxation": "Cobra Yoga Pose Hold",
    "body scan relaxation": "Cobra Yoga Pose Hold",
    "floating relaxation": "Cobra Yoga Pose Hold",
    "flexibility routine": "Cobra Yoga Pose Hold",
    "precision landing drill": "Box Jump",
    "front roll drill": "Mountain Climber",
    "safety roll": "Mountain Climber",
    "cartwheel": "Mountain Climber",
    "agility ladder lateral": "Lateral Box Jump",
    "lateral hop": "Lateral Box Jump",
    # ---- Banded hip distraction ----
    "banded hip distraction": "Pigeon Pose",
    # ---- Pinch block / wrist roller / front lever / planche / muscle-up progression ----
    "pinch block hold": "Ab Wheel Plank",
    "wrist roller": "Ankle Circles",
    "front lever progression": "Ab Wheel Plank",
    "planche lean": "Ab Wheel Plank",
    "muscle up progression": "Pull-Up Normal Grip",
    # ---- Partner leg throw ----
    "partner leg throw": "Russian Twist",
    "psoas march supine": "Air Punches March",
    "band resisted sprint": "Treadmill Running",
    "finger extension with band": "Ankle Circles",
    # ---- Hollow body rock already added; lateral hop already; supine bound ----
    # Note: kegel exercise / pelvic floor / facial yoga / jaw release have NO
    # blessed analog and are intentionally left UNMAPPED — these are real
    # library gaps that should drive media production, not aliasing.
}


# --------------------------- normalization helpers ---------------------------

# Plural -> singular (last-token-only suffix rules)
_PLURAL_RULES = [
    (re.compile(r"(.+)ies$"), r"\1y"),       # flies -> fly (BUT careful with eyes... we keep eyes->ey false; not used in fitness)
    (re.compile(r"(.+)sses$"), r"\1ss"),     # presses -> press
    (re.compile(r"(.+)ches$"), r"\1ch"),     # crunches -> crunch
    (re.compile(r"(.+)shes$"), r"\1sh"),
    (re.compile(r"(.+[aeiou]r)s$"), r"\1"),  # raises -> raise (but we want raise; below handles -es)
    (re.compile(r"(.+)es$"), r"\1e"),        # raises -> raise (after -es removal -> raise)
    (re.compile(r"(.+)s$"), r"\1"),          # shrugs -> shrug
]

# Words that should NEVER be singularized (already singular ending in s)
_NEVER_SINGULARIZE = {
    "press", "biceps", "triceps", "lats", "abs", "deltoids", "glutes",
    "quads", "hams", "hamstrings", "delts", "calves", "plus", "us",
    "iso", "atlas", "across", "bus",
}


def singularize_token(tok: str) -> str:
    if not tok:
        return tok
    if tok in _NEVER_SINGULARIZE:
        return tok
    # Try special-case manual mappings first.
    manual = {
        "shrugs": "shrug", "mornings": "morning", "raises": "raise",
        "extensions": "extension", "curls": "curl", "presses": "press",
        "crunches": "crunch", "flies": "fly", "flyes": "flye",
        "dips": "dip", "rows": "row", "pulldowns": "pulldown",
        "pullups": "pullup", "pull-ups": "pull-up",
        "chinups": "chinup", "chin-ups": "chin-up",
        "pushups": "pushup", "push-ups": "push-up",
        "situps": "situp", "sit-ups": "sit-up",
        "stepups": "stepup", "step-ups": "step-up",
        "lunges": "lunge", "squats": "squat", "deadlifts": "deadlift",
        "twists": "twist", "rotations": "rotation", "swings": "swing",
        "kicks": "kick", "burpees": "burpee", "carries": "carry",
        "thrusts": "thrust", "thrusters": "thruster",
        "snatches": "snatch", "cleans": "clean", "jerks": "jerk",
        "holds": "hold", "marches": "march",
        "shoulders": "shoulder", "kickbacks": "kickback",
        "pushdowns": "pushdown", "rises": "rise", "fly": "fly",
        "bridges": "bridge", "dumbbells": "dumbbell",
        "bands": "band", "kettlebells": "kettlebell",
        "barbells": "barbell", "machines": "machine",
        "rings": "ring", "ropes": "rope", "plates": "plate",
        "boxes": "box", "benches": "bench",
    }
    if tok in manual:
        return manual[tok]
    if len(tok) <= 3:
        return tok
    # Don't apply blanket suffix rules — too noisy. Manual map is enough.
    return tok


def _is_sanskrit_parenthetical(p: str) -> bool:
    """True if parenthetical content looks like Sanskrit / yoga transliteration.

    Heuristics:
      - contains a known Sanskrit suffix (-asana, -mudra, -pranayama, -bandha,
        -kriya, -namaskar)
      - OR contains any known Sanskrit term token (balasana, savasana, etc.)
      - AND does NOT contain any English equipment / movement / side keyword
        that we already promote to a token.
    """
    pl = p.lower().strip()
    if not pl:
        return False
    pl_clean = re.sub(r"[^a-z0-9 \-]+", " ", pl)
    tokens = [t for t in re.split(r"[\s\-]+", pl_clean) if t]
    if not tokens:
        return False
    # If any token is an English equipment / side / movement keyword we keep,
    # this is NOT a Sanskrit parenthetical — preserve it.
    KEEP_KEYWORDS = (
        EQUIPMENT_FAMILIES
        | set(EQUIPMENT_TOKENS.keys())
        | {"left", "right", "per", "side", "wall", "floor", "seated",
           "standing", "kneeling", "supine", "prone", "single", "double",
           "alternating", "reverse", "lying", "incline", "decline", "flat",
           "high", "low", "close", "wide", "neutral", "overhand", "underhand",
           "narrow", "front", "back", "rear", "isometric", "hold", "pulse"}
    )
    if any(t in KEEP_KEYWORDS for t in tokens):
        return False
    if any(t.endswith(suf) for t in tokens for suf in _SANSKRIT_SUFFIXES):
        return True
    if any(t in _SANSKRIT_KNOWN_TERMS for t in tokens):
        return True
    # Multi-token where every token is non-English-fitness (e.g. "adho mukha svanasana")
    # If 2+ tokens AND none look like English fitness vocabulary, treat as Sanskrit.
    if len(tokens) >= 2 and all(
        t.endswith(("a", "i", "u")) or t in _SANSKRIT_KNOWN_TERMS
        for t in tokens
    ):
        return True
    return False


# Aggressive gerund/participle → root verb (applied AFTER token-alias, BEFORE singularize)
_GERUND_TO_ROOT = {
    "marching": "march", "walking": "walk", "stretching": "stretch",
    "curling": "curl", "rolling": "roll", "circling": "circle",
    "twisting": "twist", "kicking": "kick", "punching": "punch",
    "jumping": "jump", "running": "run", "reaching": "reach",
    "swinging": "swing", "pulling": "pull", "pushing": "push",
    "pressing": "press", "squatting": "squat", "lunging": "lunge",
    "rowing": "row", "bending": "bend",
    "extending": "extension", "flexing": "flexion",
    "raising": "raise", "lifting": "lift", "stepping": "step",
    "kneeling": "kneel", "sitting": "sit", "standing": "stand",
    "lying": "lie", "holding": "hold", "rotating": "rotation",
    "tucking": "tuck", "folding": "fold", "balancing": "balance",
    "hopping": "hop", "skipping": "skip", "climbing": "climb",
    "thrusting": "thrust", "swaying": "sway",
}

# Anatomy plural → singular (so "calves" / "lats" / "quads" match singular library tokens)
_ANATOMY_PLURAL = {
    "calves": "calf", "feet": "foot", "knees": "knee",
    "shoulders": "shoulder", "arms": "arm", "legs": "leg",
    "hips": "hip", "glutes": "glute", "quads": "quad",
    "hamstrings": "hamstring", "lats": "lat", "delts": "delt",
    "abs": "ab", "traps": "trap", "biceps": "bicep",
    "triceps": "tricep", "wrists": "wrist", "ankles": "ankle",
    "elbows": "elbow", "fingers": "finger", "toes": "toe",
    "thighs": "thigh", "ribs": "rib",
}

# Extra plural → singular for movement words the manual map in singularize_token
# misses. Conservative: only words that are unambiguously movement plurals.
_PLURAL_EXTRAS = {
    "circles": "circle", "jacks": "jack", "angels": "angel",
    "rolls": "roll", "tucks": "tuck", "folds": "fold",
    "slams": "slam", "claps": "clap", "taps": "tap",
    "hops": "hop", "skips": "skip", "climbs": "climb",
    "drags": "drag", "throws": "throw", "catches": "catch",
    "passes": "pass", "balances": "balance", "openers": "opener",
    "closers": "closer", "abductions": "abduction",
    "adductions": "adduction", "lifts": "lift", "drops": "drop",
    "squeezes": "squeeze", "pulls": "pull", "pushes": "push",
    "drives": "drive", "snaps": "snap", "circuits": "circuit",
    "waves": "wave", "punches": "punch", "stretches": "stretch",
    "flexions": "flexion",
    # Note: "raises", "presses", "rotations", "extensions" are already in
    # singularize_token's manual map. "Press"/"biceps"/etc. are in NEVER list.
}


def normalize_plus(name: str) -> str:
    """Normalize + collapse + singularize-each-token + handle parentheticals.

    Adds aggressive normalization steps:
      - apostrophe stripping ("farmer's" → "farmers"): handled at the
        non-alphanumeric-strip step which already collapses "'" to space, so
        "farmer's walk" → "farmer s walk"; we then re-glue trailing-`s` orphan
        tokens to the previous token ONLY when the previous token isn't already
        a meaningful single letter ("farmer s walk" → "farmers walk").
      - gerund / participle → root verb mapping ("marching" → "march").
      - anatomy plural → singular ("calves" → "calf").
      - extra plural → singular for movement words.
    """
    if not name:
        return ""
    s = name.lower().strip()
    # Pull out parentheticals like "(rope)" / "(machine)" / "(wall)"
    parens = re.findall(r"\(([^)]+)\)", s)
    s = re.sub(r"\([^)]*\)", " ", s)
    s = s.replace("-", " ").replace("_", " ").replace("/", " ")
    s = re.sub(r"[^a-z0-9 ]+", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    # Apostrophe re-glue: "farmer s walk" → "farmers walk"; "world s greatest"
    # → "worlds greatest"; "child s pose" → "childs pose". Only re-glue when
    # the orphan "s" follows a multi-char word.
    s = re.sub(r"\b(\w{2,})\s+s\b", r"\1s", s)
    # Append parenthetical content as plain tokens (equipment hints) —
    # UNLESS the parenthetical is a Sanskrit / yoga transliteration, in which
    # case STRIP it (e.g. "child's pose (balasana)" → "child s pose").
    for p in parens:
        if _is_sanskrit_parenthetical(p):
            continue  # strip — don't add Sanskrit tokens to the normalized form
        p_clean = re.sub(r"[^a-z0-9 ]+", " ", p.lower())
        s = (s + " " + p_clean).strip()
    # Collapse "hand stand" -> "handstand" then back to "handstand" (canonical
    # — we keep it as one token to match canonical lib name uniformly).
    s = s.replace("hand stand", "handstand")
    # Token-level alias rewrite from existing _TOKEN_ALIASES.
    toks = []
    for t in s.split():
        t = _TOKEN_ALIASES.get(t, t)
        toks.extend(t.split())  # alias may expand to multiple tokens
    # Aggressive: gerund → root, anatomy plural → singular, extras plural → singular.
    # Order: gerund FIRST (so "presses" doesn't sneak in as "presse" via singularize),
    # then anatomy, then extras, then singularize for the long-tail.
    toks = [_GERUND_TO_ROOT.get(t, t) for t in toks]
    toks = [_ANATOMY_PLURAL.get(t, t) for t in toks]
    toks = [_PLURAL_EXTRAS.get(t, t) for t in toks]
    # Singularize each token.
    toks = [singularize_token(t) for t in toks]
    # Re-collapse handstand again (post-alias).
    out = " ".join(toks)
    out = out.replace("hand stand", "handstand")
    out = re.sub(r"\s+", " ", out).strip()
    return out


def token_set_plus(name: str) -> set[str]:
    n = normalize_plus(name)
    return {t for t in n.split() if t}


def trigram_sim(a: str, b: str) -> float:
    if not a or not b:
        return 0.0

    def grams(s: str) -> set[str]:
        s = "  " + s + " "
        return {s[i:i + 3] for i in range(len(s) - 2)}

    ga, gb = grams(a), grams(b)
    if not ga or not gb:
        return 0.0
    return len(ga & gb) / len(ga | gb)


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def movement_phrases_in(name: str) -> list[str]:
    """Return all movement phrases present in the normalized name (longest match wins)."""
    n = " " + normalize_plus(name) + " "
    found: list[str] = []
    consumed = n
    for ph in _PHRASE_SORTED:
        ptok = " " + ph + " "
        if ptok in consumed:
            found.append(ph)
            # Don't blank consumed — multi-phrase fitness names are common.
    return found


def equipment_family_from_name(name: str) -> str | None:
    n = normalize_plus(name)
    toks = set(n.split())
    # Multi-word matches first.
    for k in ("ez bar", "trap bar"):
        if k in n:
            return EQUIPMENT_TOKENS[k.replace(" ", "")] if k.replace(" ", "") in EQUIPMENT_TOKENS else EQUIPMENT_TOKENS[k]
    for tok, fam in EQUIPMENT_TOKENS.items():
        if " " in tok:
            continue
        if tok in toks:
            return fam
    return None


def equipment_family_from_blessed(blessed: dict) -> str | None:
    eq_field = (blessed.get("equipment") or "").lower().strip()
    if eq_field in EQUIPMENT_COL_MAP:
        return EQUIPMENT_COL_MAP[eq_field]
    name_fam = equipment_family_from_name(blessed.get("name", ""))
    if name_fam:
        return name_fam
    if eq_field:
        # Heuristic substring lookup
        for k, v in EQUIPMENT_COL_MAP.items():
            if k in eq_field:
                return v
    return None


def body_region_from_name(name: str) -> str | None:
    if not name:
        return None
    low = " " + normalize_plus(name) + " "
    # Phrase keywords first (longest first).
    sorted_kw = sorted(BODY_REGION_NAME_KEYWORDS, key=lambda kv: -len(kv[0]))
    for kw, region in sorted_kw:
        if " " + kw + " " in low or low.startswith(kw + " ") or low.endswith(" " + kw):
            return region
    return None


def body_region_from_blessed(blessed: dict) -> str | None:
    for src in (blessed.get("primary_muscles") or [],
                blessed.get("secondary_muscles") or []):
        for m in src:
            if not m:
                continue
            ml = m.lower().strip()
            if ml in BODY_REGION_BY_MUSCLE:
                return BODY_REGION_BY_MUSCLE[ml]
            for k, v in BODY_REGION_BY_MUSCLE.items():
                if k in ml:
                    return v
    return body_region_from_name(blessed.get("name", ""))


# --------------------------- composite scoring ---------------------------

def composite_score(
    raw_name: str,
    raw_norm: str,
    raw_tokens: set[str],
    raw_phrases: set[str],
    raw_eq: str | None,
    raw_region: str | None,
    blessed_entry: dict,
) -> dict:
    """Return dict with all signals + composite (after equipment-mismatch penalty)."""
    b = blessed_entry["obj"]
    b_name = b["name"]
    b_norm = blessed_entry["norm"]
    b_tokens = blessed_entry["tokens"]
    b_phrases = blessed_entry["phrases"]
    b_eq = blessed_entry["equipment_family"]
    b_region = blessed_entry["body_region"]

    trig = trigram_sim(raw_norm, b_norm)
    jac = jaccard(raw_tokens, b_tokens)

    # Movement phrase match: any shared phrase wins; prefer longest shared.
    shared_phrases = raw_phrases & b_phrases
    movement_match = 1.0 if shared_phrases else 0.0

    # Equipment match logic.
    if raw_eq is None and b_eq is None:
        eq_match = True
        eq_explicit_mismatch = False
    elif raw_eq is None or b_eq is None:
        eq_match = False
        eq_explicit_mismatch = False
    elif raw_eq == b_eq:
        eq_match = True
        eq_explicit_mismatch = False
    else:
        eq_match = False
        eq_explicit_mismatch = True

    region_match = bool(raw_region and b_region and raw_region == b_region)

    # Niche-equipment penalty: if RAW has no equipment token (i.e. user wrote
    # plain "plank" / "pull-up" / "face pull"), and the candidate's equipment
    # is a non-default substitute (band, suspension/trx, jump rope, sandbag),
    # penalize. The default convention in fitness vocab is:
    #   - "pull-up" → bodyweight pull-up (NOT band-assisted)
    #   - "leg press" → machine
    #   - "face pull" → cable
    #   - "plank" → bodyweight
    # Bands and suspension trainers and jump-rope are explicit substitutes,
    # not defaults.
    NICHE_EQ = {"band", "trx", "sled"}
    niche_penalty = 0.0
    if raw_eq is None and b_eq in NICHE_EQ:
        niche_penalty = 0.30
    # Jump-rope as equipment column is rare; detect by name prefix.
    if raw_eq is None and "jump rope" in b_name.lower():
        niche_penalty = max(niche_penalty, 0.30)
    # Niche-modifier penalty: candidates with extra tokens beyond raw that
    # are NOT shared with raw — penalize proportionally so we prefer the
    # canonical/short blessed name over a niche variant. Specifically count
    # candidate tokens that are not in raw and not in {a, the, with, and, of}.
    STOP = {"a", "an", "the", "with", "and", "of", "on", "to", "in"}
    extra_tokens = (b_tokens - raw_tokens) - STOP
    # Apply extra-token penalty ONLY when raw is short (≤3 tokens) — plain
    # names like "plank" / "pull up" need it; normal multi-word names like
    # "barbell incline bench press" don't.
    if len(raw_tokens) <= 3:
        extra_penalty = 0.04 * min(len(extra_tokens), 3)  # cap at 0.12
    else:
        extra_penalty = 0.0

    composite = (
        0.40 * trig
        + 0.25 * jac
        + 0.20 * movement_match
        + 0.15 * (1.0 if region_match else 0.0)
        - 0.50 * (1.0 if eq_explicit_mismatch else 0.0)
        - niche_penalty
        - extra_penalty
    )
    composite = max(0.0, min(1.0, composite))

    return {
        "blessed": b,
        "trigram": trig,
        "token_jaccard": jac,
        "movement_match": movement_match == 1.0,
        "equipment_match": eq_match,
        "equipment_explicit_mismatch": eq_explicit_mismatch,
        "body_region_match": region_match,
        "composite": composite,
    }


def classify_tier(strategy: str, composite: float, equipment_explicit_mismatch: bool) -> tuple[str, int]:
    """Return (tier, confidence)."""
    if strategy == "ANIMATED":
        return ("ANIMATED", 100)
    if strategy == "A0":
        return ("A0", 100)
    if strategy == "A1":
        return ("A1", 95)
    if strategy == "B":
        if composite >= 0.50 and not equipment_explicit_mismatch:
            return ("B", round(composite * 100))
        return ("UNMAPPED", round(composite * 100))
    if strategy == "C":
        return ("C", round(composite * 90))
    return ("UNMAPPED", round(composite * 100))


# --------------------------- suggested actions ---------------------------

_BANNED = {
    "rest", "warmup", "warm up", "warm-up", "cooldown", "cool down",
    "cool-down", "stretch only", "tbd", "n/a", "na", "",
}


def suggested_action(
    raw: str,
    raw_norm: str,
    best: dict | None,
    raw_eq: str | None,
    raw_phrases: set[str],
    same_movement_in_lib: bool,
    same_name_no_media: bool,
) -> str:
    raw_clean = raw.strip().lower()
    if raw_clean in _BANNED or len(raw_clean) < 4:
        return "banned"
    if same_name_no_media:
        return "add_alias"
    if best is None:
        return "typo_or_ambiguous"
    if best["equipment_explicit_mismatch"] and same_movement_in_lib:
        return "needs_media_production"
    if (not raw_phrases) and best["composite"] < 0.40:
        return "typo_or_ambiguous"
    if same_movement_in_lib and best["composite"] < 0.50:
        # Same movement in lib but blessed variant is niche.
        return "needs_media_production"
    if best["composite"] < 0.50 and raw_phrases:
        return "swap_in_prompt"
    return "needs_review"


# --------------------------- cardio alias map (Strategy 0) ---------------------------
# Cardio names ("zone 2 run", "easy walk", "stationary bike intervals", etc.)
# rarely share enough trigrams with the blessed cardio entries (which use
# verbose names like "Treadmill Running" / "Stationary Exercise Bike"). This
# explicit alias dictionary is consulted BEFORE any fuzzy strategy. Keys are
# normalized phrases (lowercase, singularized, hyphens→spaces) — if the raw's
# normalized form equals a key OR contains a key as a whitespace-bounded
# phrase, the mapped library_name wins with confidence=100, tier=A0.
#
# Targets are EXACT names from exercise_library_cleaned (image+video both
# populated as of 2026-05-09). Verified against the blessed-only result set.
#
# Pattern → canonical blessed name
_CARDIO_ALIAS_MAP: dict[str, str] = {
    # --- running family → Treadmill Running (default cardio run) ---
    "zone 2 run": "Treadmill Running",
    "zone2 run": "Treadmill Running",
    "zone 3 run": "Treadmill Running",
    "easy run": "Treadmill Running",
    "easy recovery run": "Treadmill Running",
    "recovery run": "Treadmill Running",
    "steady run": "Treadmill Running",
    "steady state run": "Treadmill Running",
    "long steady state run": "Treadmill Running",
    "long run": "Treadmill Running",
    "long zone 2 run": "Treadmill Running",
    "aerobic run": "Treadmill Running",
    "tempo run": "Treadmill Running",
    "outdoor run": "Treadmill Running",
    "outdoor jog": "Treadmill Jogging",
    "running": "Running",
    "run": "Running",
    "longer run": "Treadmill Running",
    # --- jog family → Treadmill Jogging ---
    "jog": "Treadmill Jogging",
    "easy jog": "Treadmill Jogging",
    "light jog": "Treadmill Jogging",
    "jogging": "Jogging",
    "jog in place": "Jogging",
    "dynamic warm up jog": "Jogging",
    # --- walk family → Treadmill Walk (default treadmill cardio) ---
    "zone 2 walk": "Treadmill Walk",
    "zone2 walk": "Treadmill Walk",
    "easy walk": "Treadmill Walk",
    "recovery walk": "Treadmill Walk",
    "cool down walk": "Treadmill Walk",
    "cool down": "Treadmill Walk",
    "warm up walk": "Treadmill Walk",
    "brisk walk": "Briskly Walking",
    "brisk walking": "Briskly Walking",
    "power walk": "Walking Fast",
    "fast walk": "Walking Fast",
    "incline walk": "Treadmill Walk",
    "incline walking": "Walking",
    "incline treadmill walk": "Treadmill Walk",
    "light treadmill walk": "Treadmill Walk",
    "treadmill walk": "Treadmill Walk",
    "treadmill walking": "Treadmill Walk",
    "treadmill jog": "Treadmill Jogging",
    "treadmill jogging": "Treadmill Jogging",
    "treadmill run": "Treadmill Running",
    "treadmill running": "Treadmill Running",
    "walking": "Walking",
    "gentle walking": "Walking",
    # --- cycling / bike family → Stationary Exercise Bike ---
    "zone 2 cycle": "Stationary Exercise Bike",
    "zone 2 bike": "Stationary Exercise Bike",
    "zone2 cycle": "Stationary Exercise Bike",
    "zone2 bike": "Stationary Exercise Bike",
    "easy cycle": "Stationary Exercise Bike",
    "easy bike": "Stationary Exercise Bike",
    "steady cycle": "Stationary Exercise Bike",
    "steady bike": "Stationary Exercise Bike",
    "spin": "Stationary Exercise Bike",
    "spin bike": "Stationary Exercise Bike",
    "stationary bike": "Stationary Exercise Bike",
    "exercise bike": "Stationary Exercise Bike",
    "stationary cycling": "Stationary Exercise Bike",
    "cycling": "Stationary Exercise Bike",
    "cycle": "Stationary Exercise Bike",
    "bike": "Stationary Exercise Bike",
    "recovery cycle": "Stationary Exercise Bike",
    "recovery bike": "Stationary Exercise Bike",
    "light cycle": "Stationary Exercise Bike",
    "light cycling": "Stationary Exercise Bike",
    # --- assault / air bike → Air Bike (Assault Bike) ---
    "assault bike": "Assault Airbike Normal Speed",
    "air bike": "Assault Airbike Normal Speed",
    "airbike": "Assault Airbike Normal Speed",
    "assault airbike": "Assault Airbike Normal Speed",
    "assault bike sprint": "Assault Airbike Sprint Speed",
    "assault bike sprints": "Assault Airbike Sprint Speed",
    "air bike sprint": "Assault Airbike Sprint Speed",
    # --- elliptical → Gym Elliptical Machine Normal Speed ---
    "elliptical": "Gym Elliptical Machine Normal Speed",
    "elliptical machine": "Gym Elliptical Machine Normal Speed",
    "elliptical trainer": "Gym Elliptical Machine Normal Speed",
    "elliptical sprint": "Gym Elliptical Machine Sprint Speed",
    # --- rowing → Gym Rowing Machine Normal Speed ---
    "rowing": "Gym Rowing Machine Normal Speed",
    "rowing machine": "Gym Rowing Machine Normal Speed",
    "row erg": "Gym Rowing Machine Normal Speed",
    "rower": "Gym Rowing Machine Normal Speed",
    "concept2 row": "Gym Rowing Machine Normal Speed",
    "concept 2 row": "Gym Rowing Machine Normal Speed",
    "erg row": "Gym Rowing Machine Normal Speed",
    "rowing sprint": "Gym Rowing Machine Sprint Speed",
    # --- jump rope → Skipping (Jump Rope) ---
    "jump rope": "Skipping",
    "skipping rope": "Skipping",
    "skipping": "Skipping",
    "double under": "Jump Rope Double Bounce",
    "double unders": "Jump Rope Double Bounce",
    # --- ski erg → Ski Ergometer Cross Country Ski Basic Pull ---
    "ski erg": "Ski Ergometer Cross Country Ski Basic Pull",
    "ski ergometer": "Ski Ergometer Cross Country Ski Basic Pull",
    # --- swimming (closest blessed entry — Standing Swimmer is dryland; we
    #     have no real swim cardio entry. Mark as needs_media_production via
    #     fall-through; intentionally NOT included here) ---
}

# Phrase-substring entries (raw_norm CONTAINS the phrase).
# Order matters — longest first wins.
_CARDIO_PHRASE_ALIASES: list[tuple[str, str]] = sorted(
    [
        # zone-N anything
        ("zone 2 run", "Treadmill Running"),
        ("zone 3 run", "Treadmill Running"),
        ("zone 2 walk", "Treadmill Walk"),
        ("zone 2 cycle", "Stationary Exercise Bike"),
        ("zone 2 bike", "Stationary Exercise Bike"),
        ("zone 2 cardio", "Stationary Exercise Bike"),
        # interval / sprint by modality
        ("treadmill interval", "Treadmill Running"),
        ("treadmill sprint", "Treadmill Running"),
        ("hill sprint", "Treadmill Running"),
        ("running interval", "Treadmill Running"),
        ("run interval", "Treadmill Running"),
        ("interval run", "Treadmill Running"),
        ("sprint interval", "Treadmill Running"),
        ("stationary bike interval", "Stationary Exercise Bike"),
        ("cycling interval", "Stationary Exercise Bike"),
        ("cycling sprint", "Stationary Exercise Bike"),
        ("bike sprint", "Stationary Exercise Bike"),
        ("assault bike interval", "Assault Airbike Normal Speed"),
        ("air bike interval", "Assault Airbike Normal Speed"),
        ("elliptical interval", "Gym Elliptical Machine Sprint Speed"),
        ("rowing interval", "Gym Rowing Machine Sprint Speed"),
        # generic cardio descriptors → most generic blessed walking
        ("light cardio", "Walking"),
        ("moderate pace cardio", "Walking"),
        ("dance cardio", "Cardio Lunge"),
    ],
    key=lambda kv: -len(kv[0]),
)


def cardio_alias_lookup(raw_norm: str, by_norm: dict) -> dict | None:
    """Return blessed entry if raw_norm matches the cardio alias map.

    Strategy: exact-key first, then phrase-substring (longest first).
    Only returns blessed entries that exist in the by_norm index (i.e. the
    target is in the blessed image+video subset). Otherwise None.
    """
    if not raw_norm:
        return None
    target = _CARDIO_ALIAS_MAP.get(raw_norm)
    if target is None:
        padded = " " + raw_norm + " "
        for phrase, name in _CARDIO_PHRASE_ALIASES:
            if " " + phrase + " " in padded:
                target = name
                break
    if target is None:
        return None
    return by_norm.get(normalize_plus(target))


# --------------------------- canonical default aliases ---------------------------
# When the raw name is plain (no equipment token) AND multiple blessed
# variants compete, these aliases hard-pick the canonical default that
# matches industry convention. Each is mapped to the EXACT blessed name as
# stored in exercise_library_cleaned. If the target isn't in the blessed set
# at runtime we fall through to the composite scorer.
CANONICAL_DEFAULTS: dict[str, str] = {
    # plain → canonical blessed name (must match exactly, case-insensitive)
    "plank": "Plank On Elbows",
    "forearm plank": "Plank On Elbows",
    "elbow plank": "Plank On Elbows",
    "pull up": "Pull-Up Normal Grip",
    "pullup": "Pull-Up Normal Grip",
    "chin up": "Chin-Up",
    "chinup": "Chin-Up",
    "leg press": "Leg Press Machine Normal Stance",
    "face pull": "Cable Face Pull With Rope",
    "face pull rope": "Cable Face Pull With Rope",
    "cable face pull": "Cable Face Pull With Rope",
    "rope face pull": "Cable Face Pull With Rope",
    "lat pulldown": "Lat Pull Down Normal Grip",
    "lat pull down": "Lat Pull Down Normal Grip",
    "lat pulldown machine": "Lat Pull Down Normal Grip",
    "bench press": "Barbell Bench Press",
    "barbell bench press": "Barbell Bench Press",
    "deadlift": "Barbell Deadlift",
    "barbell deadlift": "Barbell Deadlift",
    "romanian deadlift": "Barbell Romanian Deadlift",
    "rdl": "Barbell Romanian Deadlift",
    "overhead press": "Barbell Standing Overhead Press",
    "shoulder press": "Barbell Standing Shoulder Press",
    "military press": "Barbell Standing Military Press",
    "ohp": "Barbell Standing Overhead Press",
    "hip thrust": "Barbell Hip Thrust",
    "barbell hip thrust": "Barbell Hip Thrust",
    "glute bridge": "Barbell Glute Bridge",
    "front squat": "Barbell Front Squat",
    "barbell front squat": "Barbell Front Squat",
    "hand stand hold": "Hand Stand Hold",
    "handstand hold": "Hand Stand Hold",
    "handstand hold wall": "Hand Stand Hold",
    "wall handstand hold": "Hand Stand Hold",
    "handstand": "Hand Stand Hold",
    "dumbbell shrug": "Dumbbell Shrugs",
    "barbell shrug": "Barbell Shrugs",
    "good morning": "Good Mornings",
    "barbell good morning": "Barbell Good Morning",
    "lateral raise": "Dumbbell Side Lateral Raise",  # filled in below if absent
    "side plank": "Side Plank",
    "wall sit": "Wall Sit",
    "kettlebell swing": "Kettlebell Swing",
    "burpee": "Burpee",
    "mountain climber": "Mountain Climber",
}


# Pre-normalize alias keys so authors can write human-form keys ("legs up the
# wall", "wrist circles", "standing forward fold") and they still match against
# the post-normalize_plus form of the raw name (which is what raw_norm holds).
# Built lazily — must come AFTER normalize_plus is defined above.
_EXPLICIT_ALIAS_MAP_NORM: dict[str, str] = {
    normalize_plus(k): v for k, v in _EXPLICIT_ALIAS_MAP.items()
}
# Same treatment for the cardio CANONICAL_DEFAULTS map (keys must match raw_norm).
CANONICAL_DEFAULTS = {
    normalize_plus(k): v for k, v in CANONICAL_DEFAULTS.items()
}


# --------------------------- main ---------------------------

def main() -> None:
    print("connecting...", flush=True)
    conn = psycopg2.connect(SYNC_URL)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # ---------- 1. blessed vocabulary (image+video populated) ----------
    print("loading blessed vocabulary...", flush=True)
    cur.execute(
        """
        SELECT id, name, body_part, display_body_part, equipment,
               target_muscle, secondary_muscles, instructions,
               difficulty_level, category, image_url, video_url
        FROM exercise_library_cleaned
        WHERE image_url IS NOT NULL AND image_url <> ''
          AND video_url IS NOT NULL AND video_url <> ''
        ORDER BY name
        """
    )
    blessed_rows = cur.fetchall()
    print(f"  blessed_count = {len(blessed_rows)}", flush=True)

    blessed_json: list[dict] = []
    for r in blessed_rows:
        primary = [r["target_muscle"]] if r["target_muscle"] else []
        secondary = list(r["secondary_muscles"] or [])
        blessed_json.append({
            "id": str(r["id"]),
            "name": r["name"],
            "normalized_name": normalize_plus(r["name"]),
            "primary_muscles": primary,
            "secondary_muscles": secondary,
            "equipment": r["equipment"] or "",
            "difficulty": r["difficulty_level"] or "",
            "movement_pattern": r["category"] or r["body_part"] or "",
            "image_url": r["image_url"],
            "video_url": r["video_url"],
        })
    blessed_path = DOCS / "blessed_exercise_vocabulary.json"
    blessed_path.write_text(
        json.dumps(blessed_json, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"  wrote {blessed_path}", flush=True)

    # ---------- 2. unblessed library (for add_alias detection) ----------
    cur.execute(
        """
        SELECT name FROM exercise_library_cleaned
        WHERE NOT (image_url IS NOT NULL AND image_url <> ''
                   AND video_url IS NOT NULL AND video_url <> '')
        """
    )
    unblessed_norms = {normalize_plus(r["name"]): r["name"] for r in cur.fetchall()}

    # ---------- 3. precompute blessed index ----------
    blessed_index = []
    by_norm: dict[str, dict] = {}
    by_movement: dict[str, list[dict]] = defaultdict(list)
    eq_counts_per_movement: dict[str, Counter] = defaultdict(Counter)

    for b in blessed_json:
        norm = b["normalized_name"]
        toks = token_set_plus(b["name"])
        phrases = set(movement_phrases_in(b["name"]))
        eq_fam = equipment_family_from_blessed(b)
        region = body_region_from_blessed(b)
        entry = {
            "obj": b,
            "norm": norm,
            "tokens": toks,
            "phrases": phrases,
            "equipment_family": eq_fam,
            "body_region": region,
        }
        blessed_index.append(entry)
        by_norm[norm] = entry
        for ph in phrases:
            by_movement[ph].append(entry)
            if eq_fam:
                eq_counts_per_movement[ph][eq_fam] += 1

    # ---------- 4. distinct program names + counts ----------
    print("loading distinct program-exercise names...", flush=True)
    cur.execute(
        """
        WITH ex AS (
          SELECT DISTINCT lower(trim(ex.value->>'name')) AS raw_name,
                 pvw.variant_id
          FROM program_variant_weeks pvw,
               jsonb_array_elements(pvw.workouts) AS w,
               jsonb_array_elements(w->'exercises') AS ex
          WHERE ex.value->>'name' IS NOT NULL
        ),
        pv AS (
          SELECT id AS variant_id, base_program_id FROM program_variants
        )
        SELECT raw_name, COUNT(DISTINCT pv.base_program_id) AS program_count
        FROM ex
        LEFT JOIN pv USING (variant_id)
        WHERE raw_name <> ''
        GROUP BY raw_name
        """
    )
    raw_rows = cur.fetchall()
    program_count = {r["raw_name"]: r["program_count"] for r in raw_rows}
    distinct_names = list(program_count.keys())
    print(f"  distinct program names = {len(distinct_names)}", flush=True)

    # Sanskrit-collapse instrumentation: count distinct raw names that share
    # a normalized form solely because of Sanskrit parenthetical stripping.
    norm_groups: dict[str, list[str]] = defaultdict(list)
    for raw in distinct_names:
        norm_groups[normalize_plus(raw)].append(raw)
    sanskrit_collapsed = 0
    sanskrit_collapsed_groups = 0
    for nf, raws in norm_groups.items():
        if len(raws) < 2:
            continue
        # Did any raw in this group have a Sanskrit parenthetical?
        had_sanskrit = False
        for raw in raws:
            for p in re.findall(r"\(([^)]+)\)", raw.lower()):
                if _is_sanskrit_parenthetical(p):
                    had_sanskrit = True
                    break
            if had_sanskrit:
                break
        if had_sanskrit:
            sanskrit_collapsed += len(raws) - 1
            sanskrit_collapsed_groups += 1
    print(
        f"  sanskrit_collapse: {sanskrit_collapsed} duplicate raw names "
        f"merged into {sanskrit_collapsed_groups} canonical groups",
        flush=True,
    )

    # ---------- 5. score each raw name with stacked strategies ----------
    print("scoring (stacked-strategy pipeline)...", flush=True)
    final_map: dict[str, dict] = {}
    cardio_alias_hits = 0
    animated_hits = 0
    explicit_alias_hits = 0

    n = 0
    for raw in distinct_names:
        n += 1
        if n % 1000 == 0:
            print(f"  scored {n}/{len(distinct_names)}", flush=True)

        raw_norm_old = normalize(raw)
        raw_norm = normalize_plus(raw)
        raw_singular = raw_norm  # already singularized
        raw_tokens = token_set_plus(raw)
        raw_phrases = set(movement_phrases_in(raw))
        raw_eq = equipment_family_from_name(raw)
        raw_region = body_region_from_name(raw)

        # ----- Strategy -1: ANIMATED render — frontend renders w/ animation,
        # no library entry needed. Highest priority (runs before cardio).
        animated_hint = animated_render_lookup(raw_norm)
        if animated_hint is not None:
            animated_hits += 1
            final_map[raw] = {
                "raw_normalized": raw_norm,
                "raw_singularized": raw_norm,
                "tier": "ANIMATED",
                "confidence": 100,
                "blessed": None,
                "composite": 1.0,
                "trigram": 0.0,
                "token_jaccard": 0.0,
                "movement_match": False,
                "equipment_match": False,
                "equipment_explicit_mismatch": False,
                "body_region_match": False,
                "second_best": None,
                "second_best_composite": 0.0,
                "suggested_action": "render_with_animation",
                "suggested_action_reason": animated_hint,
                "animation_hint": animated_hint,
                "library_name_override": f"[animated render: {animated_hint}]",
            }
            continue
        # ----- Strategy 0: cardio explicit alias map (Tier A0, conf 100) -----
        a0 = cardio_alias_lookup(raw_norm, by_norm)
        if a0 is not None:
            cardio_alias_hits += 1
        # ----- Strategy 0.5: explicit raw → blessed alias overrides -----
        if a0 is None:
            target_name = _EXPLICIT_ALIAS_MAP_NORM.get(raw_norm)
            if target_name:
                target_entry = by_norm.get(normalize_plus(target_name))
                if target_entry is not None:
                    a0 = target_entry
                    explicit_alias_hits += 1
        # ----- Strategy 1: Tier A0 — exact-normalized (post-singularize) -----
        if a0 is None:
            a0 = by_norm.get(raw_norm)
        # ----- Strategy 1.5: canonical-default alias map (Tier A0, conf 100) -----
        if a0 is None:
            target_name = CANONICAL_DEFAULTS.get(raw_norm)
            if target_name:
                target_norm = normalize_plus(target_name)
                a0 = by_norm.get(target_norm)
        # ----- Strategy 2: Tier A1 — token-set bag-equality -----
        a1 = None
        if a0 is None:
            for entry in blessed_index:
                if entry["tokens"] == raw_tokens and raw_tokens:
                    a1 = entry
                    break

        # ----- Strategy 3: Tier B — composite over candidates with trigram ≥ 0.25 -----
        candidates = []
        for entry in blessed_index:
            # Cheap prefilter: shared phrase or shared token or trigram ≥ 0.25
            if not (raw_phrases & entry["phrases"]) and not (raw_tokens & entry["tokens"]):
                t = trigram_sim(raw_norm, entry["norm"])
                if t < 0.25:
                    continue
            sig = composite_score(
                raw, raw_norm, raw_tokens, raw_phrases, raw_eq, raw_region, entry
            )
            candidates.append(sig)
        candidates.sort(key=lambda s: -s["composite"])
        best = candidates[0] if candidates else None
        second = candidates[1] if len(candidates) > 1 else None

        # ----- Strategy 4: Tier C same-equipment fallback -----
        # If raw lacks equipment AND best has equipment_explicit_mismatch=False
        # AND best's equipment is the most common in blessed for this movement,
        # accept; downgrade confidence.
        tier_c_candidate = None
        if raw_eq is None and raw_phrases:
            # Pick the movement phrase that has the most blessed coverage.
            best_phrase = None
            best_phrase_count = 0
            for ph in raw_phrases:
                if len(by_movement.get(ph, [])) > best_phrase_count:
                    best_phrase = ph
                    best_phrase_count = len(by_movement[ph])
            if best_phrase:
                eq_dist = eq_counts_per_movement.get(best_phrase, Counter())
                if eq_dist:
                    common_eq, _ = eq_dist.most_common(1)[0]
                    # Find a blessed entry of that movement with that equipment, max trigram.
                    pool = [
                        e for e in by_movement[best_phrase]
                        if e["equipment_family"] == common_eq
                    ]
                    if pool:
                        scored = [
                            composite_score(
                                raw, raw_norm, raw_tokens, raw_phrases,
                                raw_eq, raw_region, e
                            )
                            for e in pool
                        ]
                        scored.sort(key=lambda s: -s["composite"])
                        tier_c_candidate = scored[0]

        # ----- Decide tier -----
        chosen = None
        strategy = None
        if a0 is not None:
            chosen = composite_score(
                raw, raw_norm, raw_tokens, raw_phrases, raw_eq, raw_region, a0
            )
            strategy = "A0"
        elif a1 is not None:
            chosen = composite_score(
                raw, raw_norm, raw_tokens, raw_phrases, raw_eq, raw_region, a1
            )
            strategy = "A1"
        elif best is not None and best["composite"] >= 0.50 and not best["equipment_explicit_mismatch"]:
            chosen = best
            strategy = "B"
        elif tier_c_candidate is not None and tier_c_candidate["composite"] >= 0.40:
            chosen = tier_c_candidate
            strategy = "C"
        else:
            chosen = best  # may be None
            strategy = "UNMAPPED"

        tier, confidence = classify_tier(
            strategy,
            chosen["composite"] if chosen else 0.0,
            chosen["equipment_explicit_mismatch"] if chosen else False,
        )

        # Suggested action computation.
        same_name_no_media = raw_norm in unblessed_norms
        # Same movement exists in blessed library?
        same_movement_in_lib = any(ph in by_movement for ph in raw_phrases)
        sa = ""
        if tier == "UNMAPPED":
            sa = suggested_action(
                raw, raw_norm, chosen, raw_eq, raw_phrases,
                same_movement_in_lib, same_name_no_media,
            )
        elif tier == "C":
            sa = "verify_equipment_default"

        final_map[raw] = {
            "raw_normalized": raw_norm,
            "raw_singularized": raw_singular,
            "tier": tier,
            "confidence": confidence,
            "blessed": chosen["blessed"] if chosen else None,
            "composite": chosen["composite"] if chosen else 0.0,
            "trigram": chosen["trigram"] if chosen else 0.0,
            "token_jaccard": chosen["token_jaccard"] if chosen else 0.0,
            "movement_match": chosen["movement_match"] if chosen else False,
            "equipment_match": chosen["equipment_match"] if chosen else False,
            "equipment_explicit_mismatch": chosen["equipment_explicit_mismatch"] if chosen else False,
            "body_region_match": chosen["body_region_match"] if chosen else False,
            "second_best": second["blessed"] if second else None,
            "second_best_composite": second["composite"] if second else 0.0,
            "suggested_action": sa,
            "suggested_action_reason": None,
            "animation_hint": None,
            "library_name_override": None,
        }

    # ---------- 6. tier counts + mediated_match_rate ----------
    tier_counts: dict[str, int] = defaultdict(int)
    conf_buckets = {">90": 0, "70-90": 0, "50-70": 0, "<50": 0}
    for v in final_map.values():
        tier_counts[v["tier"]] += 1
        c = v["confidence"]
        if v["tier"] == "UNMAPPED":
            continue
        if c > 90:
            conf_buckets[">90"] += 1
        elif c >= 70:
            conf_buckets["70-90"] += 1
        elif c >= 50:
            conf_buckets["50-70"] += 1
        else:
            conf_buckets["<50"] += 1
    print(f"  tier counts: {dict(tier_counts)}", flush=True)
    print(f"  confidence buckets: {conf_buckets}", flush=True)
    print(f"  cardio_alias_hits = {cardio_alias_hits}", flush=True)
    print(f"  animated_hits = {animated_hits}", flush=True)
    print(f"  explicit_alias_hits = {explicit_alias_hits}", flush=True)

    total_weight = sum(program_count.values())
    matched_weight = sum(
        program_count[r] for r, v in final_map.items()
        if v["tier"] in ("ANIMATED", "A0", "A1", "B") or (v["tier"] == "C" and v["confidence"] >= 70)
    )
    mediated_rate = matched_weight / total_weight * 100 if total_weight else 0
    print(f"  mediated_match_rate_pct (weighted) = {mediated_rate:.2f}%",
          flush=True)

    # ---------- 7. CSV — every row, ordered columns ----------
    csv_path = DOCS / "exercise_name_mapping.csv"
    print(f"writing {csv_path} ...", flush=True)
    cols = [
        "raw_name", "library_name", "tier", "confidence", "suggested_action",
        "program_count", "movement_match", "equipment_match",
        "body_region_match", "equipment_explicit_mismatch",
        "second_best_library_name", "second_best_confidence",
        "composite", "trigram", "token_jaccard",
        "raw_normalized", "raw_singularized",
        "library_id", "library_normalized",
        "second_best_library_id", "last_validated_at",
    ]
    from datetime import datetime, timezone
    now_iso = datetime.now(timezone.utc).isoformat()
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(cols)
        for raw in sorted(final_map.keys()):
            v = final_map[raw]
            blessed = v["blessed"]
            second = v["second_best"]
            lib_name_csv = (
                v.get("library_name_override")
                or (blessed["name"] if blessed else "")
            )
            w.writerow([
                raw,
                lib_name_csv,
                v["tier"],
                v["confidence"],
                v["suggested_action"] or "",
                program_count.get(raw, 0),
                "1" if v["movement_match"] else "0",
                "1" if v["equipment_match"] else "0",
                "1" if v["body_region_match"] else "0",
                "1" if v["equipment_explicit_mismatch"] else "0",
                second["name"] if second else "",
                round(v["second_best_composite"] * 100) if second else 0,
                f"{v['composite']:.3f}",
                f"{v['trigram']:.3f}",
                f"{v['token_jaccard']:.3f}",
                v["raw_normalized"],
                v["raw_singularized"],
                blessed["id"] if blessed else "",
                blessed["normalized_name"] if blessed else "",
                second["id"] if second else "",
                now_iso,
            ])
    print(f"  wrote {csv_path}", flush=True)

    # ---------- 8. EXERCISE_NAME_MAPPING.md ----------
    md_path = DOCS / "EXERCISE_NAME_MAPPING.md"
    print(f"writing {md_path} ...", flush=True)
    accepted = [
        (r, v) for r, v in final_map.items()
        if v["tier"] not in ("UNMAPPED", "ANIMATED")
    ]
    animated_rows = [
        (r, v) for r, v in final_map.items() if v["tier"] == "ANIMATED"
    ]
    animated_rows.sort(key=lambda kv: -program_count.get(kv[0], 0))
    accepted.sort(
        key=lambda kv: (-kv[1]["confidence"], -program_count.get(kv[0], 0))
    )
    with md_path.open("w", encoding="utf-8") as f:
        f.write("# Exercise Name Mapping (1:1)\n\n")
        f.write(
            "Generated by `backend/scripts/build_canonical_map.py` "
            "(stacked-strategy pipeline).\n\n"
        )
        f.write("## Summary\n\n")
        f.write(f"- Distinct raw names: {len(distinct_names):,}\n")
        f.write(f"- Tier ANIMATED (frontend animation, no library entry): {tier_counts['ANIMATED']:,}\n")
        f.write(f"- Tier A0 (exact post-normalize): {tier_counts['A0']:,}\n")
        f.write(f"- Tier A1 (token-set bag equality): {tier_counts['A1']:,}\n")
        f.write(f"- Tier B (composite ≥0.50): {tier_counts['B']:,}\n")
        f.write(f"- Tier C (same-equipment fallback): {tier_counts['C']:,}\n")
        f.write(f"- Unmapped: {tier_counts['UNMAPPED']:,}\n")
        f.write(f"- Confidence: >90={conf_buckets['>90']}  70-90={conf_buckets['70-90']}  "
                f"50-70={conf_buckets['50-70']}  <50={conf_buckets['<50']}\n")
        f.write(f"- Mediated match rate (weighted by program_count): "
                f"{mediated_rate:.2f}%\n\n")
        # ----- Animated render sub-section -----
        if animated_rows:
            f.write("## Animated render (no library entry — frontend animates)\n\n")
            f.write(f"_{len(animated_rows)} raw names resolved by `[animated render: <hint>]`._\n\n")
            f.write("| Raw | Animation hint | Programs |\n|---|---|---|\n")
            for raw, v in animated_rows:
                f.write(
                    f"| `{raw}` | `{v.get('animation_hint','')}` | {program_count.get(raw,0)} |\n"
                )
            f.write("\n")

        f.write("## Mappings (sorted by confidence DESC, program_count DESC)\n\n")
        f.write("| Raw | → | Blessed | Tier | Conf | Mvmt | Eq | Body | Programs | Suggested |\n")
        f.write("|---|---|---|---|---|---|---|---|---|---|\n")

        def cell(s: str) -> str:
            return s.replace("|", "\\|")
        for raw, v in accepted:
            b = v["blessed"]
            f.write(
                f"| `{cell(raw)}` | → | {cell(b['name'])} | {v['tier']} | "
                f"{v['confidence']} | {'✓' if v['movement_match'] else '✗'} | "
                f"{'✓' if v['equipment_match'] else '✗'} | "
                f"{'✓' if v['body_region_match'] else '✗'} | "
                f"{program_count.get(raw,0)} | {v['suggested_action'] or ''} |\n"
            )
    print(f"  wrote {md_path}", flush=True)

    # ---------- 9. EXERCISE_NAME_UNMAPPED.md ----------
    unmapped_path = DOCS / "EXERCISE_NAME_UNMAPPED.md"
    print(f"writing {unmapped_path} ...", flush=True)
    unmapped = [(r, v) for r, v in final_map.items() if v["tier"] == "UNMAPPED"]
    by_action: Counter = Counter()
    for r, v in unmapped:
        by_action[v["suggested_action"] or "needs_review"] += 1

    # Bucket by program_count: high (≥5), medium (2-4), low (1).
    high = [(r, v) for r, v in unmapped if program_count.get(r, 0) >= 5]
    medium = [(r, v) for r, v in unmapped if 2 <= program_count.get(r, 0) <= 4]
    low = [(r, v) for r, v in unmapped if program_count.get(r, 0) <= 1]

    # Secondary sort: suggested_action (alpha), then program_count DESC.
    def _sort_key(kv):
        return (kv[1]["suggested_action"] or "zzz", -program_count.get(kv[0], 0))
    high.sort(key=_sort_key)
    medium.sort(key=_sort_key)
    low.sort(key=lambda kv: -program_count.get(kv[0], 0))

    def _table_header(f):
        f.write("| Raw | Programs | Best candidate | Conf | Second best | Conf | Action |\n")
        f.write("|---|---|---|---|---|---|---|\n")

    def _write_row(f, raw, v):
        b = v["blessed"]
        sb = v["second_best"]
        f.write(
            f"| `{raw}` | {program_count.get(raw,0)} | "
            f"{b['name'] if b else '—'} | {v['confidence']} | "
            f"{sb['name'] if sb else '—'} | "
            f"{round(v['second_best_composite']*100) if sb else 0} | "
            f"{v['suggested_action'] or 'needs_review'} |\n"
        )

    with unmapped_path.open("w", encoding="utf-8") as f:
        f.write("# Unmapped Exercise Names (sorted by impact)\n\n")

        if animated_rows:
            f.write("## 🎬 ANIMATED RENDER — handled by frontend animation, no library entry needed\n\n")
            f.write(
                f"_{len(animated_rows)} raw names are resolved by lightweight frontend animations "
                "(e.g. expanding circle for breathing, lying-down emoji for savasana). "
                "These are NOT unmapped — they're solved by a different mechanism than library lookup._\n\n"
            )
            f.write("| Raw | Animation hint | Programs |\n|---|---|---|\n")
            for raw, v in animated_rows:
                f.write(
                    f"| `{raw}` | `{v.get('animation_hint','')}` | {program_count.get(raw,0)} |\n"
                )
            f.write("\n")

        f.write("## Summary\n\n")
        f.write(f"- Total unmapped: {len(unmapped):,}\n")
        f.write(f"- Used in 5+ programs: {len(high):,} (top priority)\n")
        f.write(f"- Used in 2–4 programs: {len(medium):,} (medium priority)\n")
        f.write(f"- Used in only 1 program: {len(low):,} (low priority — likely typos / one-off variants)\n\n")
        f.write("### Suggested actions\n\n")
        for a, c in by_action.most_common():
            f.write(f"- **{a}**: {c:,}\n")
        f.write("\n")

        f.write("## HIGH PRIORITY — used in 5+ programs\n\n")
        f.write("Sorted by suggested_action, then program_count DESC.\n\n")
        if high:
            _table_header(f)
            for raw, v in high:
                _write_row(f, raw, v)
        else:
            f.write("_None._\n")
        f.write("\n")

        f.write("## MEDIUM PRIORITY — used in 2–4 programs\n\n")
        f.write("Sorted by suggested_action, then program_count DESC.\n\n")
        if medium:
            _table_header(f)
            for raw, v in medium:
                _write_row(f, raw, v)
        else:
            f.write("_None._\n")
        f.write("\n")

        f.write(f"## LOW PRIORITY — used in only 1 program ({len(low):,})\n\n")
        f.write(
            "Long tail of one-off variants (likely typos, AI hallucinations, or hyper-specific "
            "phrasings). Full machine-readable list lives in "
            "`docs/exercise_name_mapping.csv` (filter `tier=UNMAPPED` and "
            "`program_count=1`). One row per name below for completeness:\n\n"
        )
        if low:
            _table_header(f)
            for raw, v in low:
                _write_row(f, raw, v)
    print(f"  wrote {unmapped_path}", flush=True)

    # ---------- 10. library_gaps_for_media_production.csv ----------
    gaps_path = DOCS / "library_gaps_for_media_production.csv"
    print(f"writing {gaps_path} ...", flush=True)
    with gaps_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([
            "raw_name", "program_count", "intended_exercise",
            "nearest_existing_variant", "confidence",
        ])
        gap_rows = [
            (r, v) for r, v in final_map.items()
            if v["suggested_action"] == "needs_media_production"
        ]
        gap_rows.sort(key=lambda kv: -program_count.get(kv[0], 0))
        for raw, v in gap_rows:
            b = v["blessed"]
            # The "intended" name we'd want to add is the canonical-ish form
            # of the raw name (title-cased singularized).
            intended = " ".join(w.capitalize() for w in v["raw_singularized"].split())
            w.writerow([
                raw,
                program_count.get(raw, 0),
                intended,
                b["name"] if b else "",
                v["confidence"],
            ])
    print(f"  wrote {gaps_path} ({len(gap_rows)} rows)", flush=True)

    # ---------- 11. persist into Supabase ----------
    print("rewriting program_exercise_name_map table...", flush=True)
    cur.execute("DROP TABLE IF EXISTS program_exercise_name_map CASCADE")
    cur.execute(
        """
        CREATE TABLE program_exercise_name_map (
            raw_name TEXT PRIMARY KEY,
            raw_normalized TEXT NOT NULL,
            raw_singularized TEXT NOT NULL,
            library_id UUID,
            library_name TEXT,
            library_normalized TEXT,
            tier TEXT NOT NULL CHECK (tier IN ('ANIMATED','A0','A1','B','C','UNMAPPED')),
            confidence INT NOT NULL,
            composite NUMERIC(4,3),
            trigram NUMERIC(4,3),
            token_jaccard NUMERIC(4,3),
            movement_match BOOL,
            equipment_match BOOL,
            equipment_explicit_mismatch BOOL,
            body_region_match BOOL,
            second_best_library_id UUID,
            second_best_library_name TEXT,
            second_best_confidence INT,
            program_count INT NOT NULL,
            suggested_action TEXT,
            suggested_action_reason TEXT,
            animation_hint TEXT,
            last_validated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
        """
    )
    cur.execute("CREATE INDEX ON program_exercise_name_map (tier)")
    cur.execute("CREATE INDEX ON program_exercise_name_map (confidence)")
    cur.execute("CREATE INDEX ON program_exercise_name_map (library_id)")
    cur.execute("CREATE INDEX ON program_exercise_name_map (suggested_action)")

    insert_rows = []
    for raw, v in final_map.items():
        blessed = v["blessed"]
        second = v["second_best"]
        insert_rows.append((
            raw,
            v["raw_normalized"],
            v["raw_singularized"],
            blessed["id"] if blessed else None,
            blessed["name"] if blessed else None,
            blessed["normalized_name"] if blessed else None,
            v["tier"],
            v["confidence"],
            round(v["composite"], 3),
            round(v["trigram"], 3),
            round(v["token_jaccard"], 3),
            v["movement_match"],
            v["equipment_match"],
            v["equipment_explicit_mismatch"],
            v["body_region_match"],
            second["id"] if second else None,
            second["name"] if second else None,
            round(v["second_best_composite"] * 100) if second else 0,
            program_count.get(raw, 0),
            v["suggested_action"] or None,
            v.get("suggested_action_reason"),
            v.get("animation_hint"),
        ))
    psycopg2.extras.execute_batch(
        cur,
        """
        INSERT INTO program_exercise_name_map (
            raw_name, raw_normalized, raw_singularized,
            library_id, library_name, library_normalized,
            tier, confidence, composite, trigram, token_jaccard,
            movement_match, equipment_match, equipment_explicit_mismatch,
            body_region_match,
            second_best_library_id, second_best_library_name,
            second_best_confidence,
            program_count, suggested_action, suggested_action_reason, animation_hint
        ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """,
        insert_rows,
        page_size=500,
    )
    conn.commit()
    print(f"  inserted {len(insert_rows)} rows", flush=True)

    # ---------- 12. summary ----------
    print("\n=== SUMMARY ===", flush=True)
    print(f"distinct_raw_names: {len(distinct_names):,}", flush=True)
    print(f"tiers: ANIMATED={tier_counts['ANIMATED']:,} "
          f"A0={tier_counts['A0']:,} A1={tier_counts['A1']:,} "
          f"B={tier_counts['B']:,} C={tier_counts['C']:,} "
          f"UNMAPPED={tier_counts['UNMAPPED']:,}", flush=True)
    print(f"confidence: {conf_buckets}", flush=True)
    print(f"mediated_match_rate_pct (weighted): {mediated_rate:.2f}%",
          flush=True)
    print(f"cardio_alias_hits (Strategy 0): {cardio_alias_hits}", flush=True)
    print(f"animated_hits (Strategy -1): {animated_hits}", flush=True)
    print(f"explicit_alias_hits (Strategy 0.5): {explicit_alias_hits}", flush=True)

    cited = [
        "dumbbell shrug", "incline barbell press", "good morning",
        "glute ham raise", "face pull (rope)", "handstand hold (wall)",
        "plank", "pull-up", "leg press", "face pull",
        "lat pulldown (machine)",
    ]
    print("\nCited-failure verification:", flush=True)
    for c in cited:
        v = final_map.get(c)
        if not v:
            print(f"  {c!r}: NOT IN distinct_names", flush=True)
            continue
        b = v["blessed"]
        print(
            f"  {c!r}: tier={v['tier']} conf={v['confidence']} "
            f"→ {b['name'] if b else '—'} (action={v['suggested_action'] or '-'})",
            flush=True,
        )

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
