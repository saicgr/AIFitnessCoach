"""
Dictionary-based algorithm for warmup and stretch selection.
Replaces Gemini API calls with instant, deterministic selection.

Performance: <10ms vs 3-5s with Gemini
"""

import random
from typing import List, Dict, Any, Optional, Set
from core.logger import get_logger
from core.supabase_client import get_supabase

logger = get_logger(__name__)


# ============================================
# EXERCISE TIMING DATA
# ============================================

# Smart timing: duration for static/cardio, reps for dynamic
EXERCISE_TIMING = {
    # WARMUPS - Dynamic movements
    "jumping jack": {"type": "duration", "default": 30, "unit": "seconds"},
    "arm circle": {"type": "reps", "default": 15, "unit": "reps", "notes": "each direction"},
    "circle elbow arm": {"type": "reps", "default": 15, "unit": "reps", "notes": "each direction"},
    "high knees": {"type": "duration", "default": 30, "unit": "seconds"},
    "butt kicks": {"type": "duration", "default": 30, "unit": "seconds"},
    "butt kicks slow": {"type": "duration", "default": 30, "unit": "seconds"},
    "ankle circles": {"type": "reps", "default": 10, "unit": "reps", "notes": "each direction"},
    "dynamic leg swing": {"type": "reps", "default": 15, "unit": "reps", "notes": "each leg"},
    "air punches march": {"type": "duration", "default": 30, "unit": "seconds"},
    "skipping": {"type": "duration", "default": 30, "unit": "seconds"},
    "jogging": {"type": "duration", "default": 60, "unit": "seconds"},
    "star jump": {"type": "reps", "default": 10, "unit": "reps"},
    "jump rope basic jump": {"type": "duration", "default": 60, "unit": "seconds"},

    # CARDIO WARMUPS
    "treadmill walk": {"type": "duration", "default": 300, "unit": "seconds"},
    "treadmill incline walk": {"type": "duration", "default": 600, "unit": "seconds"},
    "stationary bike easy": {"type": "duration", "default": 300, "unit": "seconds"},
    "rowing machine easy": {"type": "duration", "default": 300, "unit": "seconds"},
    "elliptical easy": {"type": "duration", "default": 300, "unit": "seconds"},

    # STRETCHES - All use duration (static holds)
    "standing hamstring calf stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "standing quadriceps stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "lying quadriceps stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "back pec stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "lying glute stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "calf stretch with hands against wall": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "kneeling hip flexor stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "overhead triceps stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each arm"},

    # === TREADMILL VARIATIONS ===
    "treadmill steep incline walk": {"type": "duration", "default": 300, "unit": "seconds"},
    "treadmill backward walk": {"type": "duration", "default": 120, "unit": "seconds"},
    "treadmill side shuffle left": {"type": "duration", "default": 120, "unit": "seconds"},
    "treadmill side shuffle right": {"type": "duration", "default": 120, "unit": "seconds"},
    "treadmill power walk": {"type": "duration", "default": 300, "unit": "seconds"},
    "treadmill high knee walk": {"type": "duration", "default": 120, "unit": "seconds"},
    "treadmill incline jog": {"type": "duration", "default": 300, "unit": "seconds"},
    "treadmill walking lunge": {"type": "duration", "default": 120, "unit": "seconds"},
    "treadmill tempo run": {"type": "duration", "default": 300, "unit": "seconds"},
    "treadmill gradient pyramid": {"type": "duration", "default": 300, "unit": "seconds"},

    # === STEPPER / STAIRMASTER ===
    "stairmaster skip step": {"type": "duration", "default": 300, "unit": "seconds"},
    "stairmaster crossover step": {"type": "duration", "default": 300, "unit": "seconds"},
    "stairmaster lateral step left": {"type": "duration", "default": 120, "unit": "seconds"},
    "stairmaster lateral step right": {"type": "duration", "default": 120, "unit": "seconds"},
    "stairmaster calf raise step": {"type": "duration", "default": 300, "unit": "seconds"},
    "stairmaster double step sprint": {"type": "duration", "default": 300, "unit": "seconds"},
    "stairmaster slow deep step": {"type": "duration", "default": 300, "unit": "seconds"},

    # === STATIONARY BIKE ===
    "stationary bike light spin": {"type": "duration", "default": 300, "unit": "seconds"},
    "stationary bike standing climb": {"type": "duration", "default": 300, "unit": "seconds"},
    "stationary bike single leg drill": {"type": "duration", "default": 120, "unit": "seconds", "notes": "each leg"},
    "stationary bike high cadence spin": {"type": "duration", "default": 300, "unit": "seconds"},
    "recumbent bike easy": {"type": "duration", "default": 300, "unit": "seconds"},
    "stationary bike tabata sprint": {"type": "duration", "default": 240, "unit": "seconds"},

    # === ELLIPTICAL ===
    "elliptical reverse stride": {"type": "duration", "default": 300, "unit": "seconds"},
    "elliptical high incline forward": {"type": "duration", "default": 300, "unit": "seconds"},
    "elliptical no hands": {"type": "duration", "default": 300, "unit": "seconds"},
    "elliptical interval bursts": {"type": "duration", "default": 300, "unit": "seconds"},

    # === ROWING MACHINE ===
    "rowing machine legs only": {"type": "duration", "default": 120, "unit": "seconds"},
    "rowing machine arms only": {"type": "duration", "default": 120, "unit": "seconds"},
    "rowing machine pick drill": {"type": "duration", "default": 120, "unit": "seconds"},

    # === BAR HANGS ===
    "dead hang": {"type": "duration", "default": 30, "unit": "seconds"},
    "active hang": {"type": "duration", "default": 30, "unit": "seconds"},
    "scapular pull-up": {"type": "duration", "default": 30, "unit": "seconds"},
    "mixed grip hang": {"type": "duration", "default": 30, "unit": "seconds"},
    "wide grip hang": {"type": "duration", "default": 30, "unit": "seconds"},
    "chin-up grip hang": {"type": "duration", "default": 30, "unit": "seconds"},
    "towel hang": {"type": "duration", "default": 30, "unit": "seconds"},

    # === JUMP ROPE ===
    "jump rope basic bounce": {"type": "duration", "default": 60, "unit": "seconds"},
    "jump rope alternate foot step": {"type": "duration", "default": 60, "unit": "seconds"},
    "jump rope boxer step": {"type": "duration", "default": 60, "unit": "seconds"},
    "jump rope high knees": {"type": "duration", "default": 60, "unit": "seconds"},
    "jump rope criss-cross": {"type": "duration", "default": 60, "unit": "seconds"},
    "jump rope double under": {"type": "duration", "default": 60, "unit": "seconds"},

    # === DYNAMIC WARMUPS ===
    "a-skip": {"type": "duration", "default": 30, "unit": "seconds"},
    "b-skip": {"type": "duration", "default": 30, "unit": "seconds"},
    "carioca drill": {"type": "duration", "default": 30, "unit": "seconds"},
    "lateral shuffle": {"type": "duration", "default": 30, "unit": "seconds"},
    "bear crawl": {"type": "duration", "default": 30, "unit": "seconds"},
    "world's greatest stretch": {"type": "duration", "default": 45, "unit": "seconds", "notes": "each side"},
    "hip 90/90 switch": {"type": "duration", "default": 30, "unit": "seconds"},
    "inchworm": {"type": "duration", "default": 30, "unit": "seconds"},
    "leg swing forward-backward": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each leg"},
    "leg swing lateral": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each leg"},
    "walking knee hug": {"type": "duration", "default": 30, "unit": "seconds"},
    "walking quad pull": {"type": "duration", "default": 30, "unit": "seconds"},
    "butt kick run": {"type": "duration", "default": 30, "unit": "seconds"},
    "high knee run": {"type": "duration", "default": 30, "unit": "seconds"},
    "frankenstein walk": {"type": "duration", "default": 30, "unit": "seconds"},
    "walking lunge with rotation": {"type": "duration", "default": 30, "unit": "seconds"},
    "lateral lunge": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "reverse lunge with overhead reach": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "spiderman lunge": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "mountain climber": {"type": "duration", "default": 30, "unit": "seconds"},
    "jumping jack": {"type": "duration", "default": 30, "unit": "seconds"},
    "squat to stand": {"type": "duration", "default": 30, "unit": "seconds"},
    "arm circle forward": {"type": "duration", "default": 30, "unit": "seconds"},
    "arm circle backward": {"type": "duration", "default": 30, "unit": "seconds"},
    "torso twist": {"type": "duration", "default": 30, "unit": "seconds"},
    "hip circle": {"type": "duration", "default": 30, "unit": "seconds"},
    "bodyweight good morning": {"type": "duration", "default": 30, "unit": "seconds"},
    "seal jack": {"type": "duration", "default": 30, "unit": "seconds"},

    # === STATIC STRETCHES ===
    "standing hamstring stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "seated hamstring stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "single leg hamstring stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "standing quad stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "prone quad stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "pigeon stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "figure four stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "standing calf stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "soleus stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "chest doorway stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "cross-body shoulder stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each arm"},
    "overhead triceps stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each arm"},
    "neck side bend stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "butterfly stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "seated straddle stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "child's pose": {"type": "duration", "default": 30, "unit": "seconds"},
    "cat-cow stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "supine spinal twist": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "cobra stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "lying glute stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "seated forward fold": {"type": "duration", "default": 30, "unit": "seconds"},
    "standing side bend": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "lat stretch wall": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "wrist flexor stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "wrist extensor stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "ankle dorsiflexion stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "it band stretch standing": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "doorway pec stretch high": {"type": "duration", "default": 30, "unit": "seconds"},
    "supine hamstring stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "seated neck rotation stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "shoulder sleeper stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "hip flexor couch stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "frog stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "scorpion stretch": {"type": "duration", "default": 30, "unit": "seconds"},

    # === FOAM ROLLER ===
    "foam roll it band": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "foam roll quadriceps": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "foam roll hamstrings": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "foam roll calves": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "foam roll glutes": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "foam roll thoracic spine": {"type": "duration", "default": 30, "unit": "seconds"},
    "foam roll lats": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "foam roll adductors": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "foam roll hip flexors": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "foam roll upper back": {"type": "duration", "default": 30, "unit": "seconds"},
    "foam roll peroneals": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "foam roll pecs": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},

    # === MOBILITY DRILLS ===
    "thread the needle": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "thoracic rotation quadruped": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "open book stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "wall slide": {"type": "duration", "default": 30, "unit": "seconds"},
    "ankle cars": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "hip cars": {"type": "duration", "default": 45, "unit": "seconds", "notes": "each side"},
    "shoulder cars": {"type": "duration", "default": 45, "unit": "seconds", "notes": "each side"},
    "prone scorpion": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "bretzel stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "shinbox get-up": {"type": "duration", "default": 30, "unit": "seconds"},
    "deep squat hold": {"type": "duration", "default": 45, "unit": "seconds"},

    # === YOGA-BASED ===
    "sun salutation a": {"type": "duration", "default": 60, "unit": "seconds"},
    "downward facing dog": {"type": "duration", "default": 30, "unit": "seconds"},
    "warrior i": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "warrior ii": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "pigeon pose": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "cobra pose": {"type": "duration", "default": 30, "unit": "seconds"},
    "upward facing dog": {"type": "duration", "default": 30, "unit": "seconds"},
    "low lunge (anjaneyasana)": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "triangle pose (trikonasana)": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "standing forward fold (uttanasana)": {"type": "duration", "default": 30, "unit": "seconds"},
}

# Default timing by exercise type
DEFAULT_TIMING = {
    "warmup_dynamic": {"type": "reps", "default": 15, "unit": "reps"},
    "warmup_cardio": {"type": "duration", "default": 300, "unit": "seconds"},
    "warmup_static": {"type": "duration", "default": 30, "unit": "seconds"},
    "stretch": {"type": "duration", "default": 30, "unit": "seconds"},
}


# ============================================
# WARMUP MAPPINGS BY TRAINING SPLIT
# ============================================

WARMUP_BY_SPLIT = {
    "push": {
        "base": ["Jumping jack", "Arm circle", "Circle elbow arm", "Seal Jack", "Arm Circle Forward", "Arm Circle Backward"],
        "chest_shoulders": ["Air punches march", "Bouncing circle draw"],
    },
    "pull": {
        "base": ["Jumping jack", "Arm circle", "Dynamic Leg Swing", "Bear Crawl", "Inchworm"],
        "back": ["Butt kick with row", "Air Swing Side To Side Swing"],
    },
    "legs": {
        "base": ["Jumping jack", "High knees", "Butt kicks", "Ankle circles", "Dynamic Leg Swing",
                 "A-Skip", "B-Skip", "Carioca Drill", "Lateral Shuffle", "Walking Knee Hug",
                 "Walking Quad Pull", "Lateral Lunge", "Squat to Stand"],
        "quads": ["Bodyweight knee thrust", "Double knee drive"],
        "glutes_hams": ["Butt kicks slow", "Criss cross jump"],
    },
    "upper": {
        "base": ["Jumping jack", "Arm circle", "Circle elbow arm", "Air punches march",
                 "Arm Circle Forward", "Arm Circle Backward", "Seal Jack"],
    },
    "lower": {
        "base": ["Jumping jack", "High knees", "Butt kicks", "Ankle circles", "Dynamic Leg Swing", "Skipping",
                 "A-Skip", "B-Skip", "Carioca Drill", "Lateral Shuffle", "Hip 90/90 Switch",
                 "Walking Lunge with Rotation"],
    },
    "full_body": {
        "base": ["Jumping jack", "High knees", "Butt kicks", "Arm circle", "Ankle circles",
                 "World's Greatest Stretch", "Inchworm", "Bear Crawl", "Torso Twist"],
    },
    # Aliases for common split names
    "chest": {"base": ["Jumping jack", "Arm circle", "Circle elbow arm", "Air punches march"]},
    "back": {"base": ["Jumping jack", "Arm circle", "Dynamic Leg Swing"]},
    "shoulders": {"base": ["Jumping jack", "Arm circle", "Circle elbow arm"]},
    "arms": {"base": ["Jumping jack", "Arm circle", "Circle elbow arm"]},
}

# Cardio warmups for higher intensity workouts
CARDIO_WARMUPS = [
    "Jogging", "Skipping", "Jump Rope basic jump", "Star jump", "180 Jump Turns",
    "Jump Rope Basic Bounce", "Jump Rope Alternate Foot Step", "Jump Rope High Knees",
    "Lateral Shuffle", "High Knee Run", "Butt Kick Run", "Bear Crawl", "Seal Jack",
    "A-Skip", "B-Skip", "Carioca Drill", "Mountain Climber",
]

# Equipment-based warmups (keyed by equipment type)
EQUIPMENT_WARMUPS = {
    "treadmill": [
        "Treadmill Steep Incline Walk", "Treadmill Power Walk", "Treadmill High Knee Walk",
        "Treadmill Backward Walk", "Treadmill Side Shuffle Left", "Treadmill Side Shuffle Right",
        "Treadmill Incline Jog", "Treadmill Walking Lunge", "Treadmill Tempo Run",
        "Treadmill Gradient Pyramid",
    ],
    "stationary_bike": [
        "Stationary Bike Light Spin", "Stationary Bike High Cadence Spin",
        "Stationary Bike Standing Climb", "Stationary Bike Single Leg Drill",
        "Recumbent Bike Easy", "Stationary Bike Tabata Sprint",
    ],
    "stair_climber": [
        "StairMaster Skip Step", "StairMaster Slow Deep Step", "StairMaster Crossover Step",
        "StairMaster Lateral Step Left", "StairMaster Lateral Step Right",
        "StairMaster Calf Raise Step", "StairMaster Double Step Sprint",
    ],
    "elliptical": [
        "Elliptical Reverse Stride", "Elliptical No Hands",
        "Elliptical High Incline Forward", "Elliptical Interval Bursts",
    ],
    "rowing_machine": [
        "Rowing Machine Legs Only", "Rowing Machine Pick Drill", "Rowing Machine Arms Only",
    ],
    "pull_up_bar": [
        "Dead Hang", "Active Hang", "Scapular Pull-Up", "Mixed Grip Hang",
        "Wide Grip Hang", "Chin-Up Grip Hang", "Towel Hang",
    ],
    "jump_rope": [
        "Jump Rope Basic Bounce", "Jump Rope Alternate Foot Step", "Jump Rope Boxer Step",
        "Jump Rope High Knees", "Jump Rope Criss-Cross", "Jump Rope Double Under",
    ],
    "foam_roller": [
        "Foam Roll IT Band", "Foam Roll Quadriceps", "Foam Roll Thoracic Spine",
        "Foam Roll Hamstrings", "Foam Roll Calves", "Foam Roll Glutes",
        "Foam Roll Lats", "Foam Roll Adductors", "Foam Roll Hip Flexors",
        "Foam Roll Upper Back", "Foam Roll Peroneals", "Foam Roll Pecs",
    ],
}


# ============================================
# STRETCH MAPPINGS BY MUSCLE GROUP
# ============================================

STRETCH_BY_MUSCLE = {
    "chest": [
        "Back pec stretch", "Above head chest stretch", "Arms Behind Back Chest Stretch",
        "Bent arm chest stretch", "Corner wall chest stretch", "Side Chest Stretch On Wall",
        "Chest Doorway Stretch", "Doorway Pec Stretch High",
    ],
    "pectorals": [
        "Back pec stretch", "Above head chest stretch", "Arms Behind Back Chest Stretch"
    ],
    "back": [
        "Dynamic Back Stretch", "Exercise ball back stretch", "Kneeling lat floor stretch",
        "Middle back rotation stretch", "Pretzel stretch", "Dead hang stretch"
    ],
    "lats": [
        "Kneeling lat floor stretch", "Dead hang stretch", "Dynamic Back Stretch",
        "Lat Stretch Wall",
    ],
    "shoulders": [
        "Cross Body Shoulder Stretch_Female", "Rear deltoid stretch",
        "back and shoulder stretch", "Extension Of Arms In Vertical Stretch",
        "Cross-Body Shoulder Stretch", "Shoulder Sleeper Stretch",
    ],
    "delts": [
        "Cross Body Shoulder Stretch_Female", "Rear deltoid stretch"
    ],
    "hamstrings": [
        "Standing hamstring calf stretch with Resistance band", "Runner stretch",
        "Lying Single Leg Extended On Wall Hamstrings Stretch", "Standing Straight-Leg Hamstring Stretch",
        "Standing Hamstring Stretch", "Seated Hamstring Stretch", "Supine Hamstring Stretch",
        "Seated Forward Fold",
    ],
    "quadriceps": [
        "Standing quadriceps stretch", "Lying quadriceps stretch",
        "All fours quad stretch", "Lying side quadriceps stretch",
        "Standing Quad Stretch", "Prone Quad Stretch",
    ],
    "quads": [
        "Standing quadriceps stretch", "Lying quadriceps stretch"
    ],
    "glutes": [
        "Lying glute stretch", "Lying Knee Pull Glutes Stretch",
        "Seated Figure Four With Twist Glute Stretch",
        "Pigeon Stretch", "Figure Four Stretch",
    ],
    "calves": [
        "Calf stretch with hands against wall", "Standing gastrocnemius stretch",
        "Seated calf stretch", "Calves stretch on stairs",
        "Standing Calf Stretch", "Soleus Stretch", "Ankle Dorsiflexion Stretch",
    ],
    "hip_flexors": [
        "Kneeling hip flexor stretch", "Lying hip flexor stretch",
        "Exercise ball hip flexor stretch", "Crossover kneeling hip flexor stretch",
        "Kneeling Hip Flexor Stretch", "Hip Flexor Couch Stretch", "Scorpion Stretch",
    ],
    "hips": [
        "Kneeling hip flexor stretch", "Lying hip flexor stretch", "Adductor stretch"
    ],
    "triceps": [
        "Overhead triceps stretch side angle", "Triceps light stretch",
        "Overhand tricep stretching single arm",
        "Overhead Triceps Stretch",
    ],
    "biceps": ["Biceps stretch behind the back"],
    "core": [
        "Abdominal stretch", "Lying (prone) abdominal stretch",
        "Standing lateral stretch", "Knee to chest stretch",
        "Cobra Stretch", "Standing Side Bend", "Supine Spinal Twist",
    ],
    "abs": [
        "Abdominal stretch", "Lying (prone) abdominal stretch"
    ],
    "lower_back": [
        "Knee to chest stretch", "Lying crossover stretch", "Iron cross stretch",
        "Exercise ball lower back prone stretch",
        "Child's Pose", "Cat-Cow Stretch",
    ],
    "adductors": [
        "Adductor stretch", "Adductor stretch side standing", "Butterfly yoga flaps",
        "Butterfly Stretch", "Seated Straddle Stretch", "Frog Stretch",
    ],
    "forearms": [
        "Forearms Stretch On Wall", "Kneeling wrist flexor stretch", "Side wrist pull stretch",
        "Wrist Flexor Stretch", "Wrist Extensor Stretch",
    ],
    "neck": [
        "Half Neck Rolls", "Backward Forward Turn to Side Neck Stretch",
        "Neck Side Bend Stretch", "Seated Neck Rotation Stretch",
    ],
    "full body": [
        "Standing quadriceps stretch", "Lying glute stretch", "Back pec stretch",
        "Calf stretch with hands against wall", "Dynamic Back Stretch",
        "World's Greatest Stretch", "Sun Salutation A",
    ],
}


# ============================================
# INJURY FILTERS
# ============================================

INJURY_AVOID_WARMUPS = {
    "knee": [
        "Jumping jack", "High knees", "Star jump", "Criss cross jump", "180 Jump Turns",
        "Jump Rope basic jump", "Skipping",
        "A-Skip", "B-Skip", "Lateral Shuffle", "Carioca Drill", "Jump Rope Basic Bounce",
        "Jump Rope Double Under", "Mountain Climber", "Walking Lunge with Rotation",
    ],
    "shoulder": [
        "Arm circle", "Circle elbow arm", "Air punches march", "Bouncing circle draw",
        "Seal Jack", "Bear Crawl", "Arm Circle Forward", "Arm Circle Backward",
    ],
    "back": [
        "Butt kick with row", "Kettlebell swing",
        "Bodyweight Good Morning", "Walking Lunge with Rotation",
    ],
    "ankle": [
        "Jumping jack", "High knees", "Skipping", "Jump Rope basic jump", "Star jump",
        "Jump Rope Basic Bounce", "Jump Rope Alternate Foot Step", "A-Skip", "B-Skip",
        "Carioca Drill", "Lateral Shuffle",
    ],
    "hip": [
        "High knees", "Dynamic Leg Swing", "Criss cross jump", "Double knee drive",
        "Hip 90/90 Switch", "Spiderman Lunge", "Lateral Lunge",
    ],
    "wrist": [
        "Air punches march", "Bouncing circle draw",
        "Bear Crawl", "Inchworm",
    ],
    "lower_back": ["Butt kick with row", "Criss cross jump"],
}

INJURY_AVOID_STRETCHES = {
    "knee": [
        "All fours quad stretch", "Kneeling hip flexor stretch", "Kneeling lat floor stretch",
        "Kneeling wrist flexor stretch",
        "Prone Quad Stretch", "Deep Squat Hold", "Shinbox Get-Up", "Frog Stretch",
    ],
    "shoulder": [
        "Above head chest stretch", "Dead hang stretch", "Extension Of Arms In Vertical Stretch",
        "Chest Doorway Stretch", "Doorway Pec Stretch High", "Lat Stretch Wall",
    ],
    "back": [
        "Lying crossover stretch", "Iron cross stretch", "Middle back rotation stretch",
        "Cobra Stretch", "Scorpion Stretch", "Supine Spinal Twist",
    ],
    "hip": [
        "Lying hip flexor stretch", "Kneeling hip flexor stretch", "Adductor stretch",
        "Pigeon Stretch", "Frog Stretch", "Hip Flexor Couch Stretch", "Butterfly Stretch",
    ],
    "lower_back": [
        "Lying crossover stretch", "Iron cross stretch",
        "Cobra Stretch", "Scorpion Stretch", "Seated Forward Fold",
    ],
    "neck": [
        "Half Neck Rolls", "Backward Forward Turn to Side Neck Stretch",
        "Neck Side Bend Stretch", "Seated Neck Rotation Stretch",
    ],
}


# ============================================
# MAIN ALGORITHM CLASS
# ============================================

class WarmupStretchAlgorithm:
    """Algorithm-based warmup/stretch selection without Gemini API calls."""

    def __init__(self):
        self.supabase = get_supabase().client

    def _normalize_split(self, training_split: str) -> str:
        """Normalize training split name to match our mappings."""
        split_lower = training_split.lower().strip()

        # Direct matches
        if split_lower in WARMUP_BY_SPLIT:
            return split_lower

        # Common aliases
        aliases = {
            "push day": "push",
            "pull day": "pull",
            "leg day": "legs",
            "upper body": "upper",
            "lower body": "lower",
            "full body": "full_body",
            "fullbody": "full_body",
            "ppl": "full_body",  # Push-Pull-Legs varies by day
            "phul": "full_body",
            "chest day": "push",
            "back day": "pull",
            "shoulder day": "push",
            "arm day": "arms",
        }

        return aliases.get(split_lower, "full_body")

    def _normalize_muscle(self, muscle: str) -> str:
        """Normalize muscle name to match our mappings."""
        muscle_lower = muscle.lower().strip()

        # Common aliases
        aliases = {
            "pecs": "chest",
            "pectorals": "chest",
            "latissimus dorsi": "lats",
            "deltoids": "shoulders",
            "delts": "shoulders",
            "quads": "quadriceps",
            "hams": "hamstrings",
            "abs": "core",
            "abdominals": "core",
            "glutes": "glutes",
            "gluteus": "glutes",
            "traps": "shoulders",
            "trapezius": "shoulders",
        }

        return aliases.get(muscle_lower, muscle_lower)

    def _filter_by_injuries(
        self,
        exercises: List[str],
        injuries: List[str],
        avoid_map: Dict[str, List[str]]
    ) -> List[str]:
        """Remove exercises that could aggravate injuries."""
        if not injuries:
            return exercises

        # Build set of exercises to avoid
        avoid_exercises: Set[str] = set()
        for injury in injuries:
            injury_lower = injury.lower()
            for key, avoid_list in avoid_map.items():
                if key in injury_lower:
                    avoid_exercises.update(ex.lower() for ex in avoid_list)

        # Filter exercises
        return [ex for ex in exercises if ex.lower() not in avoid_exercises]

    def get_exercise_timing(self, exercise_name: str, exercise_type: str = "warmup") -> Dict[str, Any]:
        """Get smart timing (duration or reps) for an exercise."""
        name_lower = exercise_name.lower()

        # Check specific exercise timing
        if name_lower in EXERCISE_TIMING:
            return EXERCISE_TIMING[name_lower]

        # Default based on exercise type
        if "cardio" in exercise_type.lower() or "treadmill" in name_lower or "bike" in name_lower:
            return DEFAULT_TIMING["warmup_cardio"]
        elif exercise_type.lower() == "stretch":
            return DEFAULT_TIMING["stretch"]
        elif "static" in exercise_type.lower() or "hold" in name_lower:
            return DEFAULT_TIMING["warmup_static"]
        else:
            return DEFAULT_TIMING["warmup_dynamic"]

    async def get_user_preferences(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Fetch user's warmup/stretch preferences from database."""
        try:
            response = self.supabase.table("warmup_stretch_preferences").select("*").eq(
                "user_id", user_id
            ).limit(1).execute()

            if response.data:
                return response.data[0]
            return None
        except Exception as e:
            logger.warning(f"⚠️ Could not fetch warmup preferences for user {user_id}: {e}")
            return None

    async def select_warmups(
        self,
        target_muscles: List[str],
        training_split: str = "full_body",
        equipment: Optional[List[str]] = None,
        injuries: Optional[List[str]] = None,
        intensity: str = "medium",
        user_id: Optional[str] = None,
    ) -> Dict[str, List[Dict[str, Any]]]:
        """
        Select warmup exercises based on workout parameters.

        Returns:
            {
                "pre_workout": [...],      # User's custom pre-workout routine
                "dynamic_warmups": [...],  # Algorithm-selected warmups
            }
        """
        logger.info(f"🔥 Selecting warmups for split={training_split}, muscles={target_muscles}")

        result = {
            "pre_workout": [],
            "dynamic_warmups": [],
        }

        # Get user preferences if available
        user_prefs = None
        if user_id:
            user_prefs = await self.get_user_preferences(user_id)

        # Add pre-workout routine from preferences
        if user_prefs and user_prefs.get("pre_workout_routine"):
            result["pre_workout"] = user_prefs["pre_workout_routine"]
            logger.info(f"📋 Added {len(result['pre_workout'])} pre-workout exercises from preferences")

        # Normalize training split
        split = self._normalize_split(training_split)

        # Get base warmups for this split
        split_warmups = WARMUP_BY_SPLIT.get(split, WARMUP_BY_SPLIT["full_body"])
        selected = list(split_warmups.get("base", []))

        # Add muscle-specific warmups
        for muscle in target_muscles:
            muscle_key = self._normalize_muscle(muscle)
            if muscle_key in split_warmups:
                selected.extend(split_warmups[muscle_key])

        # Add cardio warmup for high intensity
        if intensity.lower() in ["high", "hard", "intense"]:
            selected.extend(random.sample(CARDIO_WARMUPS, min(1, len(CARDIO_WARMUPS))))

        # Add equipment-based warmup if available
        if equipment:
            for equip in equipment:
                equip_options = EQUIPMENT_WARMUPS.get(equip.lower(), [])
                if equip_options:
                    equip_pick = random.choice(equip_options)
                    if equip_pick not in selected:
                        selected.insert(0, equip_pick)
                    break  # Only add one equipment warmup

        # Filter by injuries
        if injuries:
            selected = self._filter_by_injuries(selected, injuries, INJURY_AVOID_WARMUPS)
            logger.info(f"⚠️ Filtered warmups for injuries: {injuries}")

        # Apply user preferred/avoided warmups
        if user_prefs:
            # Add preferred warmups
            preferred = user_prefs.get("preferred_warmups", [])
            if preferred:
                for pref in preferred:
                    if pref not in selected:
                        selected.insert(0, pref)

            # Remove avoided warmups
            avoided = user_prefs.get("avoided_warmups", [])
            if avoided:
                avoided_lower = [a.lower() for a in avoided]
                selected = [ex for ex in selected if ex.lower() not in avoided_lower]

        # Remove duplicates while preserving order
        seen = set()
        unique_selected = []
        for ex in selected:
            if ex.lower() not in seen:
                seen.add(ex.lower())
                unique_selected.append(ex)

        # Limit to 4-5 warmups
        selected = unique_selected[:5]

        # Shuffle for variety
        random.shuffle(selected)

        # Format exercises with timing
        for ex_name in selected[:4]:  # Max 4 dynamic warmups
            timing = self.get_exercise_timing(ex_name, "warmup")
            exercise = {
                "name": ex_name,
                "sets": 1,
                "duration_seconds": timing.get("default", 30) if timing.get("type") == "duration" else None,
                "reps": timing.get("default", 15) if timing.get("type") == "reps" else None,
                "rest_seconds": 10,
                "equipment": "none",
                "notes": timing.get("notes", "Perform with control"),
            }
            result["dynamic_warmups"].append(exercise)

        logger.info(f"✅ Selected {len(result['dynamic_warmups'])} dynamic warmups")
        return result

    async def select_stretches(
        self,
        worked_muscles: List[str],
        training_split: str = "full_body",
        injuries: Optional[List[str]] = None,
        user_id: Optional[str] = None,
    ) -> Dict[str, List[Dict[str, Any]]]:
        """
        Select stretch exercises based on worked muscles.

        Returns:
            {
                "post_exercise": [...],    # User's custom post-exercise routine
                "stretches": [...],        # Algorithm-selected stretches
            }
        """
        logger.info(f"❄️ Selecting stretches for muscles={worked_muscles}")

        result = {
            "post_exercise": [],
            "stretches": [],
        }

        # Get user preferences if available
        user_prefs = None
        if user_id:
            user_prefs = await self.get_user_preferences(user_id)

        # Add post-exercise routine from preferences
        if user_prefs and user_prefs.get("post_exercise_routine"):
            result["post_exercise"] = user_prefs["post_exercise_routine"]
            logger.info(f"📋 Added {len(result['post_exercise'])} post-exercise from preferences")

        # Collect stretches for each worked muscle
        selected = []
        for muscle in worked_muscles:
            muscle_key = self._normalize_muscle(muscle)
            if muscle_key in STRETCH_BY_MUSCLE:
                # Add 1-2 stretches per muscle group
                muscle_stretches = STRETCH_BY_MUSCLE[muscle_key]
                selected.extend(random.sample(muscle_stretches, min(2, len(muscle_stretches))))

        # Add general full-body stretches if not enough
        if len(selected) < 4:
            full_body = STRETCH_BY_MUSCLE.get("full body", [])
            for stretch in full_body:
                if stretch not in selected:
                    selected.append(stretch)
                if len(selected) >= 5:
                    break

        # Filter by injuries
        if injuries:
            selected = self._filter_by_injuries(selected, injuries, INJURY_AVOID_STRETCHES)
            logger.info(f"⚠️ Filtered stretches for injuries: {injuries}")

        # Apply user preferred/avoided stretches
        if user_prefs:
            # Add preferred stretches
            preferred = user_prefs.get("preferred_stretches", [])
            if preferred:
                for pref in preferred:
                    if pref not in selected:
                        selected.insert(0, pref)

            # Remove avoided stretches
            avoided = user_prefs.get("avoided_stretches", [])
            if avoided:
                avoided_lower = [a.lower() for a in avoided]
                selected = [ex for ex in selected if ex.lower() not in avoided_lower]

        # Remove duplicates while preserving order
        seen = set()
        unique_selected = []
        for ex in selected:
            if ex.lower() not in seen:
                seen.add(ex.lower())
                unique_selected.append(ex)

        # Limit to 5 stretches
        selected = unique_selected[:5]

        # Format exercises with timing
        for ex_name in selected:
            timing = self.get_exercise_timing(ex_name, "stretch")
            exercise = {
                "name": ex_name,
                "sets": 1,
                "reps": 1,
                "duration_seconds": timing.get("default", 30),
                "rest_seconds": 0,
                "equipment": "none",
                "notes": timing.get("notes", "Hold and breathe deeply"),
            }
            result["stretches"].append(exercise)

        logger.info(f"✅ Selected {len(result['stretches'])} stretches")
        return result


# ============================================
# SINGLETON INSTANCE
# ============================================

_algorithm_instance: Optional[WarmupStretchAlgorithm] = None


def get_warmup_stretch_algorithm() -> WarmupStretchAlgorithm:
    """Get singleton instance of the algorithm."""
    global _algorithm_instance
    if _algorithm_instance is None:
        _algorithm_instance = WarmupStretchAlgorithm()
    return _algorithm_instance
