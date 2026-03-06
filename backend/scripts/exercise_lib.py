#!/usr/bin/env python3
"""
Shared exercise library for workout generation.
Contains exercise helpers, common exercise definitions, and category template generators.
"""


###############################################################################
# HELPERS
###############################################################################

def ex(name, sets, reps, rest, guidance, equip, body, primary, secondary, diff, cue, sub, **kw):
    """Helper to build exercise JSON."""
    e = {
        "name": name,
        "exercise_library_id": None,
        "in_library": False,
        "sets": sets,
        "reps": reps,
        "rest_seconds": rest,
        "weight_guidance": guidance,
        "equipment": equip,
        "body_part": body,
        "primary_muscle": primary,
        "secondary_muscles": secondary,
        "difficulty": diff,
        "form_cue": cue,
        "substitution": sub,
    }
    e.update(kw)
    return e

def workout(name, wtype, duration, exercises):
    """Helper to build workout JSON."""
    return {
        "workout_name": name,
        "type": wtype,
        "duration_minutes": duration,
        "exercises": exercises,
    }

def yoga_pose(name, hold_secs=30, cue="", sub=""):
    return ex(name, 1, 1, 10, f"Hold {hold_secs} seconds", "Bodyweight", "Full Body",
              "Multiple", ["Flexibility", "Balance"], "beginner", cue, sub,
              hold_seconds=hold_secs)

def stretch(name, hold_secs=30, body_part="Full Body", primary="Multiple", cue="", sub=""):
    return ex(name, 1, 1, 10, f"Hold {hold_secs} seconds each side", "Bodyweight",
              body_part, primary, ["Flexibility"], "beginner", cue, sub,
              hold_seconds=hold_secs)

def cardio_ex(name, duration_secs=60, cue="", equip="Bodyweight", diff="beginner"):
    return ex(name, 1, 1, 15, f"{duration_secs} seconds", equip, "Full Body",
              "Cardiovascular", ["Endurance"], diff, cue, "Jumping Jacks",
              duration_seconds=duration_secs)

def face_ex(name, reps=10, cue="", sub=""):
    return ex(name, 3, reps, 15, "No equipment needed", "Bodyweight", "Face",
              "Facial Muscles", ["Jaw", "Neck"], "beginner", cue, sub)


###############################################################################
# COMPOUND BARBELL
###############################################################################

BARBELL_SQUAT = lambda s=5, r=5, rest=180, g="Linear progression +2.5lb/session": ex(
    "Barbell Back Squat", s, r, rest, g, "Barbell", "Legs", "Quadriceps",
    ["Glutes", "Hamstrings", "Core"], "intermediate",
    "Below parallel, brace core, knees track toes", "Goblet Squat")

FRONT_SQUAT = lambda s=3, r=8, rest=120, g="60-70% back squat": ex(
    "Front Squat", s, r, rest, g, "Barbell", "Legs", "Quadriceps",
    ["Core", "Glutes", "Upper Back"], "intermediate",
    "Elbows high, upright torso, full depth", "Goblet Squat")

BARBELL_BENCH = lambda s=5, r=5, rest=180, g="Linear progression +2.5lb/session": ex(
    "Barbell Bench Press", s, r, rest, g, "Barbell", "Chest", "Pectoralis Major",
    ["Triceps", "Anterior Deltoid"], "intermediate",
    "Retract scapula, arch back, touch chest, leg drive", "Dumbbell Bench Press")

INCLINE_BENCH = lambda s=3, r=8, rest=90, g="Moderate weight": ex(
    "Incline Barbell Bench Press", s, r, rest, g, "Barbell", "Chest", "Upper Pectoralis",
    ["Triceps", "Anterior Deltoid"], "intermediate",
    "30-degree incline, full ROM", "Incline Dumbbell Press")

BARBELL_OHP = lambda s=5, r=5, rest=180, g="Linear progression +2.5lb/session": ex(
    "Overhead Press", s, r, rest, g, "Barbell", "Shoulders", "Deltoids",
    ["Triceps", "Core", "Upper Chest"], "intermediate",
    "Strict press, no leg drive, full lockout overhead", "Dumbbell Shoulder Press")

BARBELL_ROW = lambda s=5, r=5, rest=120, g="Linear progression": ex(
    "Barbell Row", s, r, rest, g, "Barbell", "Back", "Latissimus Dorsi",
    ["Rhomboids", "Biceps", "Rear Deltoid"], "intermediate",
    "45-degree torso, pull to lower chest, squeeze shoulder blades", "Dumbbell Row")

DEADLIFT = lambda s=1, r=5, rest=300, g="Linear progression +5lb/session": ex(
    "Barbell Deadlift", s, r, rest, g, "Barbell", "Full Body", "Posterior Chain",
    ["Glutes", "Hamstrings", "Erector Spinae", "Traps"], "intermediate",
    "Hip hinge, flat back, push floor away, lockout hips", "Trap Bar Deadlift")

SUMO_DEADLIFT = lambda s=3, r=5, rest=180, g="Work up to heavy": ex(
    "Sumo Deadlift", s, r, rest, g, "Barbell", "Full Body", "Glutes",
    ["Hamstrings", "Quads", "Adductors"], "intermediate",
    "Wide stance, toes out, chest up, push knees out", "Conventional Deadlift")

RDL = lambda s=3, r=10, rest=90, g="60-70% deadlift 1RM": ex(
    "Romanian Deadlift", s, r, rest, g, "Barbell", "Legs", "Hamstrings",
    ["Glutes", "Erector Spinae"], "intermediate",
    "Hip hinge, slight knee bend, feel hamstring stretch", "Dumbbell RDL")

POWER_CLEAN = lambda s=5, r=3, rest=120, g="Start light, focus technique": ex(
    "Power Clean", s, r, rest, g, "Barbell", "Full Body", "Full Body",
    ["Traps", "Shoulders", "Glutes", "Hamstrings"], "advanced",
    "Triple extension, shrug and pull under, front rack catch", "Hang Power Clean")

CLOSE_GRIP_BENCH = lambda s=3, r=8, rest=90, g="Moderate weight": ex(
    "Close-Grip Bench Press", s, r, rest, g, "Barbell", "Chest", "Triceps",
    ["Pectoralis Major", "Anterior Deltoid"], "intermediate",
    "Hands shoulder-width, elbows tucked", "Dip")

BARBELL_CURL = lambda s=3, r=10, rest=60, g="Moderate weight": ex(
    "Barbell Curl", s, r, rest, g, "Barbell", "Arms", "Biceps",
    ["Brachialis", "Forearms"], "beginner",
    "Strict form, no swinging", "Dumbbell Curl")

SKULL_CRUSHER = lambda s=3, r=10, rest=60, g="EZ-bar": ex(
    "Skull Crusher", s, r, rest, g, "Barbell", "Arms", "Triceps",
    ["Anconeus"], "intermediate",
    "Lower to forehead, extend fully", "Tricep Pushdown")

PENDLAY_ROW = lambda s=5, r=5, rest=120, g="From floor each rep": ex(
    "Pendlay Row", s, r, rest, g, "Barbell", "Back", "Latissimus Dorsi",
    ["Rhomboids", "Biceps", "Erector Spinae"], "intermediate",
    "Torso parallel, pull explosively from floor", "Barbell Row")

HACK_SQUAT = lambda s=3, r=10, rest=90, g="Heavy": ex(
    "Hack Squat", s, r, rest, g, "Machine", "Legs", "Quadriceps",
    ["Glutes"], "intermediate", "Full depth, controlled", "Leg Press")


###############################################################################
# DUMBBELL COMPOUNDS
###############################################################################

DB_BENCH = lambda s=3, r=10, rest=60, g="Moderate weight": ex(
    "Dumbbell Bench Press", s, r, rest, g, "Dumbbell", "Chest", "Pectoralis Major",
    ["Triceps", "Anterior Deltoid"], "beginner",
    "Full ROM, squeeze at top, controlled descent", "Push-Up")

DB_INCLINE_PRESS = lambda s=3, r=10, rest=60, g="Moderate dumbbells": ex(
    "Incline Dumbbell Press", s, r, rest, g, "Dumbbell", "Chest", "Upper Pectoralis",
    ["Triceps", "Anterior Deltoid"], "intermediate",
    "30-degree angle, full ROM", "Incline Barbell Press")

DB_OHP = lambda s=3, r=10, rest=60, g="Moderate dumbbells": ex(
    "Dumbbell Shoulder Press", s, r, rest, g, "Dumbbell", "Shoulders", "Deltoids",
    ["Triceps", "Upper Chest"], "beginner",
    "Full lockout, controlled descent", "Arnold Press")

DB_ROW = lambda s=3, r=10, rest=60, g="Moderate weight": ex(
    "Dumbbell Row", s, r, rest, g, "Dumbbell", "Back", "Latissimus Dorsi",
    ["Rhomboids", "Biceps"], "beginner",
    "Flat back, pull to hip, squeeze at top", "Cable Row")

DB_LATERAL_RAISE = lambda s=3, r=15, rest=30, g="Light, strict form": ex(
    "Dumbbell Lateral Raise", s, r, rest, g, "Dumbbell", "Shoulders", "Lateral Deltoid",
    ["Supraspinatus"], "beginner",
    "No momentum, slight lean, controlled", "Cable Lateral Raise")

DB_CURL = lambda s=3, r=10, rest=45, g="Moderate weight": ex(
    "Dumbbell Curl", s, r, rest, g, "Dumbbell", "Arms", "Biceps",
    ["Brachialis", "Forearms"], "beginner",
    "No swinging, full ROM, squeeze at top", "Barbell Curl")

HAMMER_CURL = lambda s=3, r=10, rest=45, g="Moderate dumbbells": ex(
    "Hammer Curl", s, r, rest, g, "Dumbbell", "Arms", "Brachialis",
    ["Biceps", "Forearms"], "beginner",
    "Neutral grip, controlled tempo", "Reverse Curl")

DB_LUNGE = lambda s=3, r=10, rest=60, g="Per leg": ex(
    "Dumbbell Lunge", s, r, rest, g, "Dumbbell", "Legs", "Quadriceps",
    ["Glutes", "Hamstrings"], "beginner",
    "Knee tracks toe, upright torso, full depth", "Bulgarian Split Squat")

GOBLET_SQUAT = lambda s=3, r=12, rest=60, g="Hold dumbbell at chest": ex(
    "Goblet Squat", s, r, rest, g, "Dumbbell", "Legs", "Quadriceps",
    ["Glutes", "Core"], "beginner",
    "Elbows inside knees, upright torso, below parallel", "Bodyweight Squat")

DB_RDL = lambda s=3, r=12, rest=60, g="Moderate dumbbells": ex(
    "Dumbbell Romanian Deadlift", s, r, rest, g, "Dumbbell", "Legs", "Hamstrings",
    ["Glutes", "Erector Spinae"], "beginner",
    "Hip hinge, dumbbells close to legs, feel stretch", "Single-Leg RDL")

ARNOLD_PRESS = lambda s=3, r=10, rest=60, g="Moderate dumbbells": ex(
    "Arnold Press", s, r, rest, g, "Dumbbell", "Shoulders", "Deltoids",
    ["Triceps", "Upper Chest"], "intermediate",
    "Rotate palms from facing you to forward as you press", "Dumbbell Shoulder Press")

DB_FLY = lambda s=3, r=12, rest=45, g="Light to moderate": ex(
    "Dumbbell Fly", s, r, rest, g, "Dumbbell", "Chest", "Pectoralis Major",
    ["Anterior Deltoid"], "beginner",
    "Slight bend in elbows, feel stretch at bottom", "Cable Fly")

DB_PULLOVER = lambda s=3, r=12, rest=60, g="Moderate dumbbell": ex(
    "Dumbbell Pullover", s, r, rest, g, "Dumbbell", "Chest", "Pectoralis Major",
    ["Latissimus Dorsi", "Serratus"], "intermediate",
    "Lie across bench, lower behind head, feel stretch", "Cable Pullover")

CONCENTRATION_CURL = lambda s=3, r=12, rest=30, g="Light to moderate": ex(
    "Concentration Curl", s, r, rest, g, "Dumbbell", "Arms", "Biceps",
    ["Brachialis"], "beginner",
    "Elbow braced against inner thigh, squeeze at top", "Cable Curl")

DB_SHRUG = lambda s=3, r=15, rest=30, g="Heavy dumbbells": ex(
    "Dumbbell Shrug", s, r, rest, g, "Dumbbell", "Shoulders", "Trapezius",
    ["Rhomboids"], "beginner",
    "Squeeze at top, controlled descent", "Barbell Shrug")

REVERSE_LUNGE = lambda s=3, r=10, rest=60, g="Per leg": ex(
    "Reverse Lunge", s, r, rest, g, "Dumbbell", "Legs", "Quadriceps",
    ["Glutes", "Hamstrings"], "beginner",
    "Step back, knee tracks toe, upright torso", "Walking Lunge")


###############################################################################
# MACHINE / CABLE
###############################################################################

LEG_PRESS = lambda s=3, r=10, rest=90, g="Heavy": ex(
    "Leg Press", s, r, rest, g, "Machine", "Legs", "Quadriceps",
    ["Glutes", "Hamstrings"], "intermediate",
    "Full depth, feet shoulder width, don't lock knees", "Hack Squat")

LEG_EXT = lambda s=3, r=12, rest=45, g="Moderate weight": ex(
    "Leg Extension", s, r, rest, g, "Machine", "Legs", "Quadriceps",
    ["Rectus Femoris"], "beginner",
    "Full extension, squeeze at top, controlled negative", "Sissy Squat")

LEG_CURL = lambda s=3, r=12, rest=45, g="Moderate weight": ex(
    "Leg Curl", s, r, rest, g, "Machine", "Legs", "Hamstrings",
    ["Calves"], "beginner",
    "Full ROM, squeeze at top", "Nordic Curl")

LAT_PULLDOWN = lambda s=3, r=10, rest=60, g="Moderate weight": ex(
    "Lat Pulldown", s, r, rest, g, "Cable Machine", "Back", "Latissimus Dorsi",
    ["Biceps", "Rhomboids"], "beginner",
    "Wide grip, pull to upper chest, squeeze lats", "Pull-Up")

CABLE_ROW = lambda s=3, r=12, rest=60, g="Moderate weight": ex(
    "Seated Cable Row", s, r, rest, g, "Cable Machine", "Back", "Rhomboids",
    ["Latissimus Dorsi", "Biceps", "Rear Deltoid"], "beginner",
    "Chest up, pull to lower chest, squeeze shoulder blades", "Dumbbell Row")

FACE_PULL = lambda s=3, r=15, rest=30, g="Light cable, external rotation": ex(
    "Face Pull", s, r, rest, g, "Cable Machine", "Shoulders", "Rear Deltoid",
    ["Rhomboids", "External Rotators"], "beginner",
    "Pull to face, rotate thumbs back, squeeze", "Band Pull-Apart")

TRICEP_PUSHDOWN = lambda s=3, r=12, rest=45, g="Rope or straight bar": ex(
    "Tricep Pushdown", s, r, rest, g, "Cable Machine", "Arms", "Triceps",
    ["Anconeus"], "beginner",
    "Elbows pinned, full extension, squeeze", "Diamond Push-Up")

TRICEP_OVERHEAD = lambda s=3, r=12, rest=45, g="Cable or dumbbell": ex(
    "Overhead Tricep Extension", s, r, rest, g, "Cable Machine", "Arms", "Triceps Long Head",
    ["Triceps"], "beginner",
    "Full stretch behind head, extend fully", "Skull Crusher")

CABLE_FLY = lambda s=3, r=12, rest=45, g="Light to moderate": ex(
    "Cable Fly", s, r, rest, g, "Cable Machine", "Chest", "Pectoralis Major",
    ["Anterior Deltoid"], "beginner",
    "Slight bend in elbows, squeeze at center", "Dumbbell Fly")

CALF_RAISE = lambda s=4, r=15, rest=30, g="Standing machine or smith": ex(
    "Calf Raise", s, r, rest, g, "Machine", "Legs", "Calves",
    ["Tibialis Anterior"], "beginner",
    "Full stretch at bottom, 2-sec pause at top", "Seated Calf Raise")

HIP_THRUST = lambda s=3, r=12, rest=90, g="Barbell across hips": ex(
    "Barbell Hip Thrust", s, r, rest, g, "Barbell", "Glutes", "Gluteus Maximus",
    ["Hamstrings", "Core"], "intermediate",
    "Shoulders on bench, drive through heels, squeeze glutes at top", "Glute Bridge")

CABLE_KICKBACK = lambda s=3, r=15, rest=30, g="Light cable, per leg": ex(
    "Cable Glute Kickback", s, r, rest, g, "Cable Machine", "Glutes", "Gluteus Maximus",
    ["Hamstrings"], "beginner",
    "Slight lean, drive heel back, squeeze glute at top", "Donkey Kick")

CABLE_PULL_THROUGH = lambda s=3, r=12, rest=45, g="Moderate cable": ex(
    "Cable Pull-Through", s, r, rest, g, "Cable Machine", "Glutes", "Gluteus Maximus",
    ["Hamstrings", "Erector Spinae"], "beginner",
    "Hip hinge, squeeze glutes at top", "Kettlebell Swing")

PEC_DECK = lambda s=3, r=12, rest=45, g="Moderate weight": ex(
    "Pec Deck Fly", s, r, rest, g, "Machine", "Chest", "Pectoralis Major",
    ["Anterior Deltoid"], "beginner",
    "Squeeze at center, controlled negative", "Cable Fly")

CHEST_PRESS_MACHINE = lambda s=3, r=10, rest=60, g="Moderate": ex(
    "Machine Chest Press", s, r, rest, g, "Machine", "Chest", "Pectoralis Major",
    ["Triceps", "Anterior Deltoid"], "beginner",
    "Full ROM, squeeze at extension", "Dumbbell Bench Press")

SHOULDER_PRESS_MACHINE = lambda s=3, r=10, rest=60, g="Moderate": ex(
    "Machine Shoulder Press", s, r, rest, g, "Machine", "Shoulders", "Deltoids",
    ["Triceps"], "beginner",
    "Full lockout, controlled descent", "Dumbbell Shoulder Press")

SEATED_CALF_RAISE = lambda s=4, r=15, rest=30, g="Moderate": ex(
    "Seated Calf Raise", s, r, rest, g, "Machine", "Legs", "Soleus",
    ["Gastrocnemius"], "beginner",
    "Full stretch, squeeze at top", "Standing Calf Raise")

REVERSE_PEC_DECK = lambda s=3, r=15, rest=30, g="Light to moderate": ex(
    "Reverse Pec Deck", s, r, rest, g, "Machine", "Shoulders", "Rear Deltoid",
    ["Rhomboids"], "beginner",
    "Squeeze shoulder blades, controlled", "Face Pull")

CABLE_LATERAL_RAISE = lambda s=3, r=15, rest=30, g="Light cable": ex(
    "Cable Lateral Raise", s, r, rest, g, "Cable Machine", "Shoulders", "Lateral Deltoid",
    ["Supraspinatus"], "beginner",
    "Controlled, slight lean away from cable", "Dumbbell Lateral Raise")

CABLE_CURL = lambda s=3, r=12, rest=45, g="Moderate cable": ex(
    "Cable Curl", s, r, rest, g, "Cable Machine", "Arms", "Biceps",
    ["Brachialis"], "beginner",
    "Constant tension, squeeze at top", "Dumbbell Curl")


###############################################################################
# BODYWEIGHT
###############################################################################

PULLUP = lambda s=3, r=8, rest=90, g="Add weight when hitting 3x8": ex(
    "Pull-Up", s, r, rest, g, "Bodyweight", "Back", "Latissimus Dorsi",
    ["Biceps", "Rhomboids", "Core"], "intermediate",
    "Full dead hang, chin over bar, controlled negative", "Lat Pulldown")

CHINUP = lambda s=3, r=8, rest=90, g="Add weight when hitting 3x8": ex(
    "Chin-Up", s, r, rest, g, "Bodyweight", "Back", "Biceps",
    ["Latissimus Dorsi", "Rhomboids"], "intermediate",
    "Supinated grip, full dead hang, chin over bar", "Lat Pulldown (Close Grip)")

PUSHUP = lambda s=3, r=15, rest=45, g="Bodyweight": ex(
    "Push-Up", s, r, rest, g, "Bodyweight", "Chest", "Pectoralis Major",
    ["Triceps", "Anterior Deltoid", "Core"], "beginner",
    "Full ROM, chest to floor, lock out at top", "Knee Push-Up")

DIP = lambda s=3, r=10, rest=90, g="Add weight when hitting 3x12": ex(
    "Dip", s, r, rest, g, "Bodyweight", "Chest", "Pectoralis Major",
    ["Triceps", "Anterior Deltoid"], "intermediate",
    "Slight forward lean for chest, upright for triceps", "Bench Dip")

PLANK = lambda s=3, r=1, rest=30, g="Hold 30-60 seconds": ex(
    "Plank", s, r, rest, g, "Bodyweight", "Core", "Rectus Abdominis",
    ["Obliques", "Transverse Abdominis"], "beginner",
    "Straight line from head to heels, brace core", "Dead Bug")

HANGING_LEG_RAISE = lambda s=3, r=10, rest=60, g="Controlled, no swinging": ex(
    "Hanging Leg Raise", s, r, rest, g, "Bodyweight", "Core", "Lower Abs",
    ["Hip Flexors", "Obliques"], "intermediate",
    "No swinging, raise legs to parallel or higher", "Lying Leg Raise")

BURPEE = lambda s=1, r=10, rest=30, g="Bodyweight, fast pace": ex(
    "Burpee", s, r, rest, g, "Bodyweight", "Full Body", "Full Body",
    ["Chest", "Legs", "Core", "Shoulders"], "intermediate",
    "Chest to floor, explosive jump, full extension", "Squat Thrust")

MOUNTAIN_CLIMBER = lambda s=1, r=30, rest=20, g="30 seconds": ex(
    "Mountain Climber", s, r, rest, g, "Bodyweight", "Core", "Core",
    ["Hip Flexors", "Shoulders", "Quadriceps"], "beginner",
    "Plank position, drive knees fast, keep hips low", "High Knees")

BODYWEIGHT_SQUAT = lambda s=3, r=15, rest=30, g="Bodyweight": ex(
    "Bodyweight Squat", s, r, rest, g, "Bodyweight", "Legs", "Quadriceps",
    ["Glutes", "Hamstrings"], "beginner",
    "Below parallel, chest up, weight in heels", "Wall Sit")

GLUTE_BRIDGE = lambda s=3, r=15, rest=30, g="Bodyweight or banded": ex(
    "Glute Bridge", s, r, rest, g, "Bodyweight", "Glutes", "Gluteus Maximus",
    ["Hamstrings", "Core"], "beginner",
    "Drive through heels, squeeze glutes 2 sec at top", "Hip Thrust")

BULGARIAN_SPLIT_SQUAT = lambda s=3, r=10, rest=60, g="Per leg, dumbbells optional": ex(
    "Bulgarian Split Squat", s, r, rest, g, "Dumbbell", "Legs", "Quadriceps",
    ["Glutes", "Hamstrings"], "intermediate",
    "Rear foot elevated, knee tracks toe, upright torso", "Lunge")

STEP_UP = lambda s=3, r=10, rest=60, g="Per leg": ex(
    "Step-Up", s, r, rest, g, "Dumbbell", "Legs", "Quadriceps",
    ["Glutes", "Hamstrings"], "beginner",
    "Drive through lead leg, full hip extension at top", "Lunge")

WALL_SIT = lambda s=3, r=1, rest=30, g="Hold 30-60 seconds": ex(
    "Wall Sit", s, r, rest, g, "Bodyweight", "Legs", "Quadriceps",
    ["Glutes"], "beginner",
    "Back flat against wall, knees at 90 degrees", "Bodyweight Squat")

PIKE_PUSHUP = lambda s=3, r=10, rest=60, g="Bodyweight": ex(
    "Pike Push-Up", s, r, rest, g, "Bodyweight", "Shoulders", "Deltoids",
    ["Triceps", "Upper Chest"], "intermediate",
    "Hips high, head toward floor, press up", "Dumbbell Shoulder Press")

DIAMOND_PUSHUP = lambda s=3, r=12, rest=45, g="Bodyweight": ex(
    "Diamond Push-Up", s, r, rest, g, "Bodyweight", "Chest", "Triceps",
    ["Pectoralis Major", "Anterior Deltoid"], "intermediate",
    "Hands together under chest, elbows close", "Tricep Pushdown")

INVERTED_ROW = lambda s=3, r=10, rest=60, g="Bodyweight": ex(
    "Inverted Row", s, r, rest, g, "Bodyweight", "Back", "Rhomboids",
    ["Latissimus Dorsi", "Biceps"], "beginner",
    "Body straight, pull chest to bar, squeeze back", "Dumbbell Row")

BENCH_DIP = lambda s=3, r=12, rest=45, g="Bodyweight": ex(
    "Bench Dip", s, r, rest, g, "Bodyweight", "Arms", "Triceps",
    ["Anterior Deltoid", "Pectoralis Major"], "beginner",
    "Hands on bench behind, lower body, press up", "Tricep Pushdown")

JUMP_SQUAT = lambda s=3, r=10, rest=30, g="Bodyweight, explosive": ex(
    "Jump Squat", s, r, rest, g, "Bodyweight", "Legs", "Quadriceps",
    ["Glutes", "Calves"], "intermediate",
    "Squat deep, explode up, soft landing", "Bodyweight Squat")

JUMPING_LUNGE = lambda s=3, r=10, rest=30, g="Per side": ex(
    "Jumping Lunge", s, r, rest, g, "Bodyweight", "Legs", "Quadriceps",
    ["Glutes", "Hamstrings", "Calves"], "intermediate",
    "Alternate legs mid-air, soft landing", "Walking Lunge")

HIGH_KNEES = lambda s=1, r=30, rest=15, g="30 seconds": ex(
    "High Knees", s, r, rest, g, "Bodyweight", "Full Body", "Hip Flexors",
    ["Core", "Calves", "Quadriceps"], "beginner",
    "Drive knees above hip height, pump arms", "March in Place")

DEAD_BUG = lambda s=3, r=10, rest=30, g="Per side": ex(
    "Dead Bug", s, r, rest, g, "Bodyweight", "Core", "Transverse Abdominis",
    ["Rectus Abdominis", "Hip Flexors"], "beginner",
    "Lower back pressed to floor, extend opposite arm and leg", "Bird Dog")

BIRD_DOG = lambda s=3, r=10, rest=30, g="Per side": ex(
    "Bird Dog", s, r, rest, g, "Bodyweight", "Core", "Erector Spinae",
    ["Glutes", "Shoulders"], "beginner",
    "Extend opposite arm and leg, keep hips level", "Dead Bug")

SUPERMAN = lambda s=3, r=12, rest=30, g="Bodyweight": ex(
    "Superman", s, r, rest, g, "Bodyweight", "Back", "Erector Spinae",
    ["Glutes", "Shoulders"], "beginner",
    "Lie face down, lift arms and legs, squeeze back", "Bird Dog")

CRUNCHES = lambda s=3, r=20, rest=30, g="Bodyweight": ex(
    "Crunches", s, r, rest, g, "Bodyweight", "Core", "Rectus Abdominis",
    ["Obliques"], "beginner",
    "Curl shoulders off floor, exhale on crunch", "Sit-Up")

BICYCLE_CRUNCH = lambda s=3, r=20, rest=30, g="Per side": ex(
    "Bicycle Crunch", s, r, rest, g, "Bodyweight", "Core", "Obliques",
    ["Rectus Abdominis", "Hip Flexors"], "beginner",
    "Opposite elbow to knee, extend other leg", "Russian Twist")

RUSSIAN_TWIST = lambda s=3, r=20, rest=30, g="Per side, optional weight": ex(
    "Russian Twist", s, r, rest, g, "Bodyweight", "Core", "Obliques",
    ["Rectus Abdominis"], "beginner",
    "Lean back slightly, rotate torso side to side", "Bicycle Crunch")

SIDE_PLANK = lambda s=2, r=1, rest=30, g="Hold 30 seconds per side": ex(
    "Side Plank", s, r, rest, g, "Bodyweight", "Core", "Obliques",
    ["Quadratus Lumborum", "Glutes"], "beginner",
    "Stack feet, hips up, straight line", "Modified Side Plank")

DONKEY_KICK = lambda s=3, r=15, rest=30, g="Per leg": ex(
    "Donkey Kick", s, r, rest, g, "Bodyweight", "Glutes", "Gluteus Maximus",
    ["Hamstrings", "Core"], "beginner",
    "On all fours, drive heel toward ceiling, squeeze", "Cable Kickback")

FIRE_HYDRANT = lambda s=3, r=15, rest=30, g="Per leg": ex(
    "Fire Hydrant", s, r, rest, g, "Bodyweight", "Glutes", "Gluteus Medius",
    ["Gluteus Minimus", "Core"], "beginner",
    "On all fours, lift knee to side, keep 90-degree bend", "Banded Lateral Walk")

CLAMSHELL = lambda s=3, r=15, rest=30, g="Per side, band optional": ex(
    "Clamshell", s, r, rest, g, "Bodyweight", "Glutes", "Gluteus Medius",
    ["Hip External Rotators"], "beginner",
    "Side lying, feet together, open knees like clamshell", "Banded Lateral Walk")

SINGLE_LEG_RDL = lambda s=3, r=10, rest=45, g="Per leg, dumbbell optional": ex(
    "Single-Leg Romanian Deadlift", s, r, rest, g, "Dumbbell", "Legs", "Hamstrings",
    ["Glutes", "Balance", "Core"], "intermediate",
    "Hip hinge on one leg, slight knee bend, touch floor", "Romanian Deadlift")

CURTSY_LUNGE = lambda s=3, r=12, rest=45, g="Per leg": ex(
    "Curtsy Lunge", s, r, rest, g, "Bodyweight", "Legs", "Gluteus Medius",
    ["Quadriceps", "Adductors"], "intermediate",
    "Step behind and across, keep torso upright", "Reverse Lunge")

FROG_PUMP = lambda s=3, r=20, rest=30, g="Bodyweight": ex(
    "Frog Pump", s, r, rest, g, "Bodyweight", "Glutes", "Gluteus Maximus",
    ["Adductors"], "beginner",
    "Soles together, knees out, thrust hips up", "Glute Bridge")

SUMO_SQUAT = lambda s=3, r=15, rest=45, g="Wide stance, dumbbell optional": ex(
    "Sumo Squat", s, r, rest, g, "Bodyweight", "Legs", "Adductors",
    ["Glutes", "Quadriceps"], "beginner",
    "Wide stance, toes out, squat deep, chest up", "Goblet Squat")

LATERAL_BAND_WALK = lambda s=3, r=15, rest=30, g="Per direction": ex(
    "Lateral Band Walk", s, r, rest, g, "Resistance Band", "Glutes", "Gluteus Medius",
    ["Gluteus Minimus", "TFL"], "beginner",
    "Band above knees, stay low, push knees out", "Fire Hydrant")

BANDED_SQUAT = lambda s=3, r=15, rest=30, g="Band above knees": ex(
    "Banded Squat", s, r, rest, g, "Resistance Band", "Legs", "Quadriceps",
    ["Glutes", "Adductors"], "beginner",
    "Push knees out against band throughout", "Bodyweight Squat")


###############################################################################
# CARDIO / HIIT EXERCISES
###############################################################################

JUMPING_JACK = lambda s=1, r=30, rest=15, g="30 seconds": ex(
    "Jumping Jacks", s, r, rest, g, "Bodyweight", "Full Body", "Cardiovascular",
    ["Shoulders", "Calves"], "beginner",
    "Full arm extension, land softly", "Step Jacks")

BOX_JUMP = lambda s=3, r=8, rest=60, g="Start with low box": ex(
    "Box Jump", s, r, rest, g, "Bodyweight", "Legs", "Quadriceps",
    ["Glutes", "Calves"], "intermediate",
    "Swing arms, land softly, full hip extension", "Step-Up")

BATTLE_ROPES = lambda s=3, r=1, rest=30, g="30 seconds per set": ex(
    "Battle Ropes", s, r, rest, g, "Battle Ropes", "Full Body", "Shoulders",
    ["Core", "Arms", "Back"], "intermediate",
    "Alternating waves, engage core, athletic stance", "Rope Slams")

KETTLEBELL_SWING = lambda s=3, r=15, rest=45, g="Moderate weight": ex(
    "Kettlebell Swing", s, r, rest, g, "Kettlebell", "Full Body", "Glutes",
    ["Hamstrings", "Core", "Shoulders"], "intermediate",
    "Hip hinge, snap hips, float kettlebell to eye level", "Cable Pull-Through")

JUMP_ROPE = lambda s=1, r=1, rest=30, g="60 seconds": ex(
    "Jump Rope", s, r, rest, g, "Jump Rope", "Full Body", "Calves",
    ["Shoulders", "Core", "Cardiovascular"], "beginner",
    "Light feet, wrists turn rope, stay on balls of feet", "High Knees",
    duration_seconds=60)

ROWING = lambda s=1, r=1, rest=60, g="5 minutes moderate": ex(
    "Rowing Machine", s, r, rest, g, "Rowing Machine", "Full Body", "Back",
    ["Legs", "Arms", "Core", "Cardiovascular"], "beginner",
    "Legs-back-arms sequence, smooth strokes", "Battle Ropes",
    duration_seconds=300)

SLED_PUSH = lambda s=3, r=1, rest=90, g="40 yards, moderate weight": ex(
    "Sled Push", s, r, rest, g, "Sled", "Full Body", "Quadriceps",
    ["Glutes", "Calves", "Core", "Shoulders"], "intermediate",
    "Low body angle, drive with legs, short choppy steps", "Prowler Push")

FARMER_WALK = lambda s=3, r=1, rest=60, g="40 yards, heavy dumbbells": ex(
    "Farmer's Walk", s, r, rest, g, "Dumbbell", "Full Body", "Grip",
    ["Traps", "Core", "Forearms"], "beginner",
    "Tall posture, tight core, quick steps", "Trap Bar Carry",
    duration_seconds=30)


###############################################################################
# YOGA POSES
###############################################################################

DOWNWARD_DOG = lambda: yoga_pose("Downward-Facing Dog", 45, "Hands shoulder-width, push hips up and back, heels toward floor", "Puppy Pose")
WARRIOR_I = lambda: yoga_pose("Warrior I (Virabhadrasana I)", 30, "Front knee over ankle, back leg straight, arms overhead", "High Lunge")
WARRIOR_II = lambda: yoga_pose("Warrior II (Virabhadrasana II)", 30, "Front knee over ankle, arms parallel to floor, gaze over front hand", "Extended Side Angle")
WARRIOR_III = lambda: yoga_pose("Warrior III (Virabhadrasana III)", 30, "Balance on one leg, torso and back leg parallel to floor", "Single-Leg Deadlift")
TREE_POSE = lambda: yoga_pose("Tree Pose (Vrksasana)", 30, "Foot on inner thigh (not knee), hands at heart or overhead", "Kickstand Balance")
CHILDS_POSE = lambda: yoga_pose("Child's Pose (Balasana)", 60, "Knees wide, arms extended, forehead to mat", "Puppy Pose")
CAT_COW = lambda: yoga_pose("Cat-Cow (Marjaryasana-Bitilasana)", 45, "Inhale arch, exhale round, flow with breath", "Seated Spinal Flex")
PIGEON_POSE = lambda: yoga_pose("Pigeon Pose (Eka Pada Rajakapotasana)", 45, "Front shin parallel to mat, hips square, fold forward", "Figure Four Stretch")
COBRA = lambda: yoga_pose("Cobra Pose (Bhujangasana)", 30, "Hands under shoulders, lift chest, keep elbows close", "Sphinx Pose")
TRIANGLE = lambda: yoga_pose("Triangle Pose (Trikonasana)", 30, "Legs wide, front foot forward, reach down and up", "Extended Side Angle")
BRIDGE_POSE = lambda: yoga_pose("Bridge Pose (Setu Bandhasana)", 30, "Feet hip-width, press into feet, lift hips", "Supported Bridge")
SAVASANA = lambda: yoga_pose("Savasana (Corpse Pose)", 120, "Lie flat, arms at sides, palms up, relax completely", "Seated Meditation")
CHAIR_POSE = lambda: yoga_pose("Chair Pose (Utkatasana)", 30, "Knees bent, arms overhead, weight in heels", "Wall Sit")
HALF_MOON = lambda: yoga_pose("Half Moon (Ardha Chandrasana)", 30, "Balance on one leg, hand to floor, top arm up", "Triangle Pose")
EAGLE_POSE = lambda: yoga_pose("Eagle Pose (Garudasana)", 30, "Wrap arms and legs, sit low, focus balance", "Tree Pose")
CAMEL_POSE = lambda: yoga_pose("Camel Pose (Ustrasana)", 30, "Kneel, lean back, hands to heels, open chest", "Bridge Pose")
CROW_POSE = lambda: yoga_pose("Crow Pose (Bakasana)", 20, "Hands on floor, knees on triceps, lean forward, lift feet", "Plank")
BOAT_POSE = lambda: yoga_pose("Boat Pose (Navasana)", 30, "Sit, lift legs and torso, arms parallel to floor", "Modified Boat")
SEATED_FORWARD_FOLD = lambda: yoga_pose("Seated Forward Fold (Paschimottanasana)", 45, "Legs straight, fold from hips, reach for toes", "Standing Forward Fold")
HAPPY_BABY = lambda: yoga_pose("Happy Baby (Ananda Balasana)", 45, "Lie back, grab feet, knees toward armpits", "Supine Figure Four")
GARLAND_POSE = lambda: yoga_pose("Garland Pose (Malasana)", 30, "Deep squat, elbows press knees, palms together", "Sumo Squat")
SPHINX_POSE = lambda: yoga_pose("Sphinx Pose", 30, "Forearms on floor, lift chest gently, relax shoulders", "Cobra Pose")
PUPPY_POSE = lambda: yoga_pose("Puppy Pose (Uttana Shishosana)", 30, "Kneel, walk hands forward, chest toward floor", "Child's Pose")
RECLINED_TWIST = lambda: yoga_pose("Supine Spinal Twist", 45, "Lie back, knees to one side, arms out, look opposite", "Seated Twist")
LEGS_UP_WALL = lambda: yoga_pose("Legs Up the Wall (Viparita Karani)", 120, "Sit near wall, swing legs up, relax completely", "Savasana")
STANDING_FORWARD_FOLD = lambda: yoga_pose("Standing Forward Fold (Uttanasana)", 30, "Hinge at hips, let head hang, bend knees if needed", "Ragdoll Pose")
LOW_LUNGE = lambda: yoga_pose("Low Lunge (Anjaneyasana)", 30, "Front knee over ankle, back knee down, arms up", "High Lunge")
SIDE_ANGLE = lambda: yoga_pose("Extended Side Angle (Utthita Parsvakonasana)", 30, "Front knee bent, forearm on thigh, top arm overhead", "Triangle Pose")
REVOLVED_TRIANGLE = lambda: yoga_pose("Revolved Triangle (Parivrtta Trikonasana)", 30, "Twist torso, opposite hand to front foot, other arm up", "Triangle Pose")
SHOULDER_STAND = lambda: yoga_pose("Shoulder Stand (Sarvangasana)", 60, "Support back with hands, legs vertical, chin to chest", "Legs Up the Wall")
FISH_POSE = lambda: yoga_pose("Fish Pose (Matsyasana)", 30, "Lie back, arch chest, top of head on floor", "Supported Fish")
PLOUGH_POSE = lambda: yoga_pose("Plough Pose (Halasana)", 30, "From shoulder stand, lower feet behind head", "Seated Forward Fold")


###############################################################################
# PILATES EXERCISES
###############################################################################

PILATES_HUNDRED = lambda: ex("The Hundred", 1, 100, 15, "Pump arms 100 times", "Bodyweight", "Core",
    "Rectus Abdominis", ["Obliques", "Hip Flexors"], "intermediate",
    "Legs tabletop or extended, pump arms, breathe 5 in 5 out", "Dead Bug")

PILATES_ROLL_UP = lambda: ex("Roll-Up", 3, 8, 15, "Slow, controlled", "Bodyweight", "Core",
    "Rectus Abdominis", ["Hip Flexors", "Spine"], "intermediate",
    "Articulate spine one vertebra at a time", "Crunch")

PILATES_LEG_CIRCLES = lambda: ex("Single Leg Circles", 2, 10, 15, "Per leg", "Bodyweight", "Core",
    "Hip Flexors", ["Core", "Inner Thigh"], "beginner",
    "Circle leg, keep pelvis stable, both directions", "Dead Bug")

PILATES_ROLLING_BALL = lambda: ex("Rolling Like a Ball", 3, 8, 15, "Balance on sit bones", "Bodyweight", "Core",
    "Rectus Abdominis", ["Spine"], "beginner",
    "Tuck tight, roll to shoulder blades, balance at top", "Crunch")

PILATES_SINGLE_LEG_STRETCH = lambda: ex("Single Leg Stretch", 2, 10, 15, "Per side", "Bodyweight", "Core",
    "Rectus Abdominis", ["Hip Flexors", "Obliques"], "beginner",
    "Alternate legs, pull knee to chest, other leg extends", "Bicycle Crunch")

PILATES_DOUBLE_LEG_STRETCH = lambda: ex("Double Leg Stretch", 2, 8, 15, "Controlled", "Bodyweight", "Core",
    "Rectus Abdominis", ["Hip Flexors"], "intermediate",
    "Extend arms and legs simultaneously, circle arms to hug knees", "Dead Bug")

PILATES_SCISSORS = lambda: ex("Scissors", 2, 10, 15, "Per side", "Bodyweight", "Core",
    "Hip Flexors", ["Hamstrings", "Core"], "beginner",
    "Lie back, alternate legs up and down, shoulders lifted", "Lying Leg Raise")

PILATES_BICYCLE = lambda: ex("Pilates Bicycle", 2, 10, 15, "Per side", "Bodyweight", "Core",
    "Obliques", ["Rectus Abdominis", "Hip Flexors"], "intermediate",
    "Twist opposite elbow to knee, extend other leg", "Bicycle Crunch")

PILATES_SPINE_STRETCH = lambda: ex("Spine Stretch Forward", 3, 5, 15, "Seated, controlled", "Bodyweight", "Core",
    "Erector Spinae", ["Hamstrings"], "beginner",
    "Sit tall, round forward one vertebra at a time, reach past toes", "Seated Forward Fold")

PILATES_SAW = lambda: ex("The Saw", 2, 8, 15, "Per side", "Bodyweight", "Core",
    "Obliques", ["Hamstrings", "Spine"], "beginner",
    "Sit tall, twist and reach toward opposite foot", "Seated Twist")

PILATES_SWAN = lambda: ex("Swan Dive Prep", 3, 6, 15, "Controlled extension", "Bodyweight", "Back",
    "Erector Spinae", ["Glutes", "Shoulders"], "beginner",
    "Lie prone, lift chest using back muscles", "Cobra Pose")

PILATES_SWIMMING = lambda: ex("Swimming", 3, 20, 15, "Alternate arms/legs", "Bodyweight", "Back",
    "Erector Spinae", ["Glutes", "Shoulders"], "beginner",
    "Lie prone, flutter arms and legs, keep core engaged", "Superman")

PILATES_SIDE_KICK = lambda: ex("Side Kick Series", 2, 10, 15, "Per side", "Bodyweight", "Legs",
    "Hip Abductors", ["Glutes", "Core"], "beginner",
    "Lie on side, kick forward and back, keep torso still", "Fire Hydrant")

PILATES_TEASER = lambda: ex("Teaser", 3, 5, 20, "Advanced core", "Bodyweight", "Core",
    "Rectus Abdominis", ["Hip Flexors", "Spine"], "advanced",
    "Roll up to V-sit, arms parallel to legs, balance", "Boat Pose")

PILATES_SEAL = lambda: ex("Seal", 3, 8, 15, "Fun cooldown", "Bodyweight", "Core",
    "Rectus Abdominis", ["Spine"], "beginner",
    "Like rolling ball but clap feet at top and bottom", "Rolling Like a Ball")

PILATES_WALL_SQUAT = lambda: ex("Wall Pilates Squat", 3, 12, 30, "Back against wall", "Bodyweight", "Legs",
    "Quadriceps", ["Glutes", "Core"], "beginner",
    "Slide down wall, knees 90 degrees, press back flat", "Wall Sit")

PILATES_WALL_PUSH = lambda: ex("Wall Push-Up", 3, 15, 30, "Hands on wall", "Bodyweight", "Chest",
    "Pectoralis Major", ["Triceps", "Core"], "beginner",
    "Hands on wall shoulder width, lean in and push back", "Knee Push-Up")

PILATES_WALL_LEG_LIFT = lambda: ex("Wall Leg Lift", 3, 12, 20, "Per side", "Bodyweight", "Legs",
    "Hip Abductors", ["Glutes", "Core"], "beginner",
    "Stand facing wall, lift leg to side/back, control", "Side Leg Raise")


###############################################################################
# REHAB / MOBILITY EXERCISES
###############################################################################

ANKLE_CIRCLES = lambda: ex("Ankle Circles", 2, 10, 10, "Each direction, each ankle", "Bodyweight", "Ankles",
    "Ankle Joint", ["Calves", "Tibialis"], "beginner",
    "Slow circles, full range of motion", "Ankle Alphabet")

WRIST_CIRCLES = lambda: ex("Wrist Circles", 2, 10, 10, "Each direction", "Bodyweight", "Wrists",
    "Wrist Joint", ["Forearms"], "beginner",
    "Slow circles, both directions", "Wrist Flexion/Extension")

WALL_ANGEL = lambda: ex("Wall Angel", 3, 10, 20, "Slow, controlled", "Bodyweight", "Shoulders",
    "Rotator Cuff", ["Scapular Stabilizers", "Thoracic Spine"], "beginner",
    "Back to wall, slide arms up like snow angel, keep contact", "Prone Y Raise")

BAND_PULL_APART = lambda s=3, r=15, rest=20, g="Light band": ex(
    "Band Pull-Apart", s, r, rest, g, "Resistance Band", "Shoulders", "Rear Deltoid",
    ["Rhomboids", "Rotator Cuff"], "beginner",
    "Arms straight, pull band apart, squeeze shoulder blades", "Face Pull")

FOAM_ROLL_QUAD = lambda: ex("Foam Roll Quads", 1, 1, 10, "60 seconds each leg", "Foam Roller", "Legs",
    "Quadriceps", ["IT Band"], "beginner",
    "Roll slowly, pause on tender spots, breathe through it", "Quad Stretch")

FOAM_ROLL_IT_BAND = lambda: ex("Foam Roll IT Band", 1, 1, 10, "60 seconds each side", "Foam Roller", "Legs",
    "IT Band", ["TFL", "Glutes"], "beginner",
    "Side lying, roll from hip to knee", "Lateral Leg Stretch")

FOAM_ROLL_BACK = lambda: ex("Foam Roll Upper Back", 1, 1, 10, "60 seconds", "Foam Roller", "Back",
    "Thoracic Spine", ["Rhomboids", "Traps"], "beginner",
    "Arms crossed, roll mid to upper back", "Cat-Cow")

HIP_90_90 = lambda: ex("90/90 Hip Stretch", 2, 1, 10, "Hold 30 seconds each side", "Bodyweight", "Hips",
    "Hip Rotators", ["Glutes", "Adductors"], "beginner",
    "Front leg 90 degrees, back leg 90 degrees, tall posture", "Pigeon Pose")

WORLD_GREATEST_STRETCH = lambda: ex("World's Greatest Stretch", 2, 5, 15, "Per side", "Bodyweight", "Full Body",
    "Hip Flexors", ["Thoracic Spine", "Hamstrings", "Glutes"], "beginner",
    "Lunge, plant hand, rotate open, reach overhead", "Spiderman Stretch")

BANDED_DISTRACTION = lambda part="Hip": ex(f"Banded {part} Distraction", 2, 1, 10,
    "Hold 30-60 seconds", "Resistance Band", part, f"{part} Joint",
    ["Surrounding Muscles"], "beginner",
    f"Band around {part.lower()}, step away for distraction", "Static Stretch")

CHIN_TUCK = lambda: ex("Chin Tuck", 3, 10, 15, "Hold 5 seconds each", "Bodyweight", "Neck",
    "Deep Neck Flexors", ["Cervical Spine"], "beginner",
    "Pull chin straight back, make double chin, hold", "Neck Retraction")

THORACIC_EXTENSION = lambda: ex("Thoracic Extension over Roller", 2, 8, 15, "Foam roller under upper back",
    "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae"], "beginner",
    "Arms behind head, extend over roller, breathe out", "Cat-Cow")

HIP_FLEXOR_STRETCH = lambda: stretch("Half-Kneeling Hip Flexor Stretch", 30, "Hips", "Hip Flexors",
    "Rear knee down, squeeze glute, lean forward slightly", "Couch Stretch")

PIRIFOMIS_STRETCH = lambda: stretch("Piriformis Stretch", 30, "Hips", "Piriformis",
    "Figure four position, pull bottom knee toward chest", "Pigeon Pose")
