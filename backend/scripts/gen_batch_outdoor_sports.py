#!/usr/bin/env python3
"""Generate Outdoor & Sport Specific programs (Cats 76-80) + expansion programs."""
import sys, os
os.chdir('/Users/saichetangrandhe/AIFitnessCoach/backend')
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()

def ex(name, sets, reps, rest, weight, equip, body, muscle, secondary, diff, cue, sub):
    return {"name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest,
            "weight_guidance": weight, "equipment": equip, "body_part": body,
            "primary_muscle": muscle, "secondary_muscles": secondary,
            "difficulty": diff, "form_cue": cue, "substitution": sub}

def wo(name, wtype, mins, exercises):
    return {"workout_name": name, "type": wtype, "duration_minutes": mins, "exercises": exercises}

# ========================================================================
# CATEGORY 76 - HIKING & TRAIL FITNESS (14 programs)
# ========================================================================

def hiking_leg_endurance():
    return wo("Hiking Leg Endurance", "strength", 45, [
        ex("Step-Up", 3, 12, 60, "Bodyweight or light DB", "Bench", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Drive through heel, full extension at top", "Box Step-Up"),
        ex("Walking Lunge", 3, 12, 60, "Bodyweight or DB", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, knee over ankle", "Stationary Lunge"),
        ex("Calf Raise", 3, 20, 45, "Bodyweight or added weight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full range of motion, pause at top", "Seated Calf Raise"),
        ex("Single-Leg Romanian Deadlift", 3, 10, 60, "Light dumbbell", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Hinge at hip, keep back flat", "Romanian Deadlift"),
        ex("Wall Sit", 3, 1, 60, "Hold 45-60 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Back flat on wall, 90 degree knee bend", "Goblet Squat Hold"),
        ex("Ankle Circle", 2, 15, 0, "Each direction each foot", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full circles, controlled movement", "Ankle Alphabet"),
        ex("Side Step Band Walk", 3, 15, 45, "Resistance band", "Resistance Band", "Hips", "Gluteus Medius", ["Hip Abductors", "Quadriceps"], "beginner", "Stay low, tension on band throughout", "Lateral Lunge"),
    ])

def hiking_cardio():
    return wo("Trail Cardio Builder", "cardio", 40, [
        ex("Incline Treadmill Walk", 1, 1, 0, "20 min at 10-15% incline", "Treadmill", "Legs", "Quadriceps", ["Calves", "Glutes", "Hamstrings"], "beginner", "Upright posture, no holding rails", "Stair Climber"),
        ex("Stair Climber", 1, 1, 0, "10 minutes moderate pace", "Stair Machine", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Light grip, drive through heels", "Box Step-Up"),
        ex("Bodyweight Squat", 3, 15, 45, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, chest up", "Goblet Squat"),
        ex("Plank", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line, engaged core", "Forearm Plank"),
        ex("Bird Dog", 3, 10, 30, "Alternate sides", "Bodyweight", "Core", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Extend opposite arm and leg, maintain balance", "Dead Bug"),
    ])

def hiking_balance():
    return wo("Trail Balance & Stability", "balance", 35, [
        ex("Single-Leg Stand", 3, 1, 30, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Calves", ["Core", "Ankle Stabilizers"], "beginner", "Eyes forward, engage core, slight knee bend", "Tandem Stand"),
        ex("BOSU Ball Squat", 3, 10, 45, "Bodyweight", "BOSU Ball", "Legs", "Quadriceps", ["Core", "Ankle Stabilizers"], "intermediate", "Flat side up, controlled descent", "Bodyweight Squat"),
        ex("Lateral Hop", 3, 10, 45, "Side to side", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves", "Core"], "intermediate", "Soft landing, absorb with knees", "Lateral Step"),
        ex("Single-Leg Calf Raise", 3, 12, 30, "Each leg", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full range, hold rail lightly for balance", "Double-Leg Calf Raise"),
        ex("Banded Ankle Dorsiflexion", 3, 15, 30, "Resistance band", "Resistance Band", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Pull toes toward shin against band", "Toe Tap"),
        ex("Single-Leg Deadlift", 3, 8, 45, "Bodyweight or light DB", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Hinge forward, maintain flat back", "Romanian Deadlift"),
    ])

def hiking_pack_strength():
    return wo("Pack Carry Strength", "strength", 50, [
        ex("Farmer's Walk", 3, 1, 60, "Heavy dumbbells, 40 meters", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core", "Legs"], "intermediate", "Shoulders back, tight core, controlled steps", "Suitcase Carry"),
        ex("Goblet Squat", 4, 10, 60, "Moderate weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold weight at chest, elbows inside knees", "Bodyweight Squat"),
        ex("Bent-Over Row", 3, 10, 60, "Moderate weight", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "45 degree hinge, pull to ribcage", "Cable Row"),
        ex("Overhead Press", 3, 10, 60, "Light to moderate", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Press straight up, core braced", "Pike Push-Up"),
        ex("Hip Thrust", 3, 12, 60, "Barbell or bodyweight", "Barbell", "Hips", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Full hip extension, squeeze at top", "Glute Bridge"),
        ex("Dead Bug", 3, 10, 30, "Alternate sides", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Low back pressed to floor, opposite arm/leg extend", "Bird Dog"),
    ])

cat76_programs = [
    ("Day Hike Ready", "Hiking & Trail Fitness", [2, 4, 8], [3, 4], "Build endurance for 5-10 mile hikes with leg strength and cardio", "High",
     lambda w, t: [hiking_leg_endurance(), hiking_cardio(), hiking_leg_endurance()]),
    ("Steep Trail Legs", "Hiking & Trail Fitness", [2, 4, 8], [3, 4], "Conquer elevation gain with uphill and downhill leg power", "High",
     lambda w, t: [hiking_leg_endurance(), hiking_pack_strength(), hiking_leg_endurance()]),
    ("Hiker's Cardio Base", "Hiking & Trail Fitness", [2, 4, 8], [4, 5], "Cardiovascular foundation for trail hiking endurance", "High",
     lambda w, t: [hiking_cardio(), hiking_leg_endurance(), hiking_cardio()]),
    ("Trail Balance Training", "Hiking & Trail Fitness", [1, 2, 4], [4, 5], "Stability and balance for uneven terrain and rocky trails", "Med",
     lambda w, t: [hiking_balance(), hiking_balance(), hiking_balance()]),
    ("Backpacking Prep", "Hiking & Trail Fitness", [4, 8, 12], [4, 5], "Build strength to carry weight over long distances", "Med",
     lambda w, t: [hiking_pack_strength(), hiking_cardio(), hiking_pack_strength()]),
    ("Thru-Hike Training", "Hiking & Trail Fitness", [8, 12, 16], [5, 6], "Long-distance trail preparation for AT, PCT, CDT style hikes", "Med",
     lambda w, t: [hiking_pack_strength(), hiking_cardio(), hiking_leg_endurance(), hiking_pack_strength()]),
    ("Pack Weight Conditioning", "Hiking & Trail Fitness", [2, 4, 8], [3, 4], "Progressive training to build up to heavy pack carrying", "Med",
     lambda w, t: [hiking_pack_strength(), hiking_leg_endurance(), hiking_pack_strength()]),
    ("Mountain Summit Training", "Hiking & Trail Fitness", [4, 8, 12], [4, 5], "High altitude mountain hiking preparation", "Med",
     lambda w, t: [hiking_cardio(), hiking_leg_endurance(), hiking_pack_strength()]),
    ("Hiker's Knee Protection", "Hiking & Trail Fitness", [1, 2, 4], [4, 5], "Prevent knee damage from downhill hiking impact", "Low",
     lambda w, t: [hiking_balance(), hiking_leg_endurance(), hiking_balance()]),
    ("Post-Hike Recovery", "Hiking & Trail Fitness", [1], [1], "Recovery stretching and mobility after long trail days", "Low",
     lambda w, t: [hiking_balance()]),
    ("Trail Runner Transition", "Hiking & Trail Fitness", [2, 4, 8], [3, 4], "Transition from hiking to trail running with proper conditioning", "Low",
     lambda w, t: [hiking_cardio(), hiking_leg_endurance(), hiking_cardio()]),
    ("Weekend Warrior Hiker", "Hiking & Trail Fitness", [2, 4], [3, 4], "Stay trail-ready year round with minimal weekly training", "Low",
     lambda w, t: [hiking_leg_endurance(), hiking_cardio(), hiking_leg_endurance()]),
    ("Altitude Acclimatization", "Hiking & Trail Fitness", [2, 4], [4, 5], "Prepare your body for high elevation hiking", "Low",
     lambda w, t: [hiking_cardio(), hiking_cardio(), hiking_balance()]),
    ("Winter Hiking Prep", "Hiking & Trail Fitness", [2, 4, 8], [3, 4], "Snowshoe and cold weather trail conditioning", "Low",
     lambda w, t: [hiking_leg_endurance(), hiking_pack_strength(), hiking_balance()]),
]

# ========================================================================
# CATEGORY 77 - SKATING FITNESS (12 programs)
# ========================================================================

def skating_balance():
    return wo("Skating Balance", "balance", 35, [
        ex("Single-Leg Squat", 3, 8, 60, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Slow descent, drive through heel", "Assisted Pistol Squat"),
        ex("Lateral Lunge", 3, 10, 45, "Bodyweight or light DB", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Glutes"], "beginner", "Wide step, sit into hip, push back", "Side Step"),
        ex("BOSU Ball Single-Leg Stand", 3, 1, 30, "Hold 20 seconds each leg", "BOSU Ball", "Legs", "Calves", ["Core", "Ankle Stabilizers"], "intermediate", "Slight knee bend, engage core", "Single-Leg Stand"),
        ex("Curtsy Lunge", 3, 10, 45, "Bodyweight", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Hip Adductors"], "beginner", "Step behind and across, knee tracks over toe", "Reverse Lunge"),
        ex("Single-Leg Calf Raise", 3, 15, 30, "Each leg", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full range, controlled", "Double-Leg Calf Raise"),
        ex("Ankle Eversion with Band", 3, 15, 30, "Light resistance band", "Resistance Band", "Legs", "Peroneals", ["Ankle Stabilizers"], "beginner", "Turn foot outward against resistance", "Ankle Circle"),
    ])

def skating_leg_power():
    return wo("Skating Leg Power", "strength", 45, [
        ex("Goblet Squat", 4, 10, 60, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Elbows between knees, full depth", "Bodyweight Squat"),
        ex("Skater Jump", 3, 12, 45, "Side to side", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves", "Core"], "intermediate", "Soft landing, absorb impact", "Lateral Step"),
        ex("Bulgarian Split Squat", 3, 10, 60, "Bodyweight or DB", "Bench", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Rear foot elevated, control descent", "Split Squat"),
        ex("Side Plank Hip Abduction", 3, 10, 45, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Obliques", "Core"], "intermediate", "Lift top leg while holding side plank", "Side-Lying Leg Lift"),
        ex("Box Jump", 3, 8, 60, "Start low, progress height", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Soft landing, step down", "Squat Jump"),
        ex("Copenhagen Adductor Hold", 3, 1, 30, "Hold 20 seconds each side", "Bench", "Hips", "Hip Adductors", ["Core", "Obliques"], "intermediate", "Top foot on bench, hold straight body", "Side-Lying Adduction"),
    ])

def skating_agility():
    return wo("Skating Agility", "conditioning", 40, [
        ex("Lateral Shuffle", 3, 30, 45, "30 seconds per set", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hip Abductors", "Calves"], "beginner", "Low stance, quick feet, don't cross feet", "Side Step"),
        ex("Speed Skater", 3, 15, 45, "Alternating sides", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves", "Core"], "intermediate", "Bound side to side, reach to opposite foot", "Lateral Lunge"),
        ex("Agility Ladder Lateral", 3, 4, 45, "4 lengths", "Agility Ladder", "Legs", "Calves", ["Quadriceps", "Core"], "intermediate", "Quick feet, stay on balls of feet", "Lateral Shuffle"),
        ex("Single-Leg Hop", 3, 10, 45, "Each leg", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Glutes"], "intermediate", "Soft landing, balance before next hop", "Double-Leg Hop"),
        ex("Plank with Hip Dip", 3, 12, 30, "Alternate sides", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis", "Shoulders"], "beginner", "Controlled rotation, tap hip to floor", "Side Plank"),
    ])

cat77_programs = [
    ("Ice Skating Fundamentals", "Skating Fitness", [2, 4, 8], [3, 4], "Balance and glide basics for ice skating beginners", "High",
     lambda w, t: [skating_balance(), skating_leg_power(), skating_balance()]),
    ("Figure Skating Fitness", "Skating Fitness", [4, 8, 12], [4, 5], "Jump, spin, and flexibility training for figure skaters", "High",
     lambda w, t: [skating_leg_power(), skating_balance(), skating_agility()]),
    ("Hockey Skating Power", "Skating Fitness", [4, 8, 12], [4, 5], "Speed, power and agility for ice hockey skating", "High",
     lambda w, t: [skating_leg_power(), skating_agility(), skating_leg_power()]),
    ("Ice Skating Leg Strength", "Skating Fitness", [2, 4, 8], [3, 4], "Build leg power specifically for the skating stride", "Med",
     lambda w, t: [skating_leg_power(), skating_balance(), skating_leg_power()]),
    ("Roller Skating Fitness", "Skating Fitness", [2, 4, 8], [3, 4], "Quad skating conditioning for balance and endurance", "Med",
     lambda w, t: [skating_balance(), skating_agility(), skating_balance()]),
    ("Inline Skating Program", "Skating Fitness", [2, 4, 8], [3, 4], "Rollerblading endurance and technique training", "Med",
     lambda w, t: [skating_agility(), skating_leg_power(), skating_balance()]),
    ("Roller Derby Training", "Skating Fitness", [4, 8, 12], [4, 5], "Contact sport conditioning for roller derby athletes", "Med",
     lambda w, t: [skating_leg_power(), skating_agility(), skating_leg_power()]),
    ("Skating Cardio Blast", "Skating Fitness", [1, 2, 4], [3, 4], "High-intensity skating-inspired cardio workouts", "Med",
     lambda w, t: [skating_agility(), skating_agility(), skating_agility()]),
    ("Skateboard Fitness Prep", "Skating Fitness", [2, 4, 8], [3, 4], "Balance, core, and leg strength for skateboarding", "Med",
     lambda w, t: [skating_balance(), skating_leg_power(), skating_balance()]),
    ("Skatepark Ready", "Skating Fitness", [2, 4, 8], [4, 5], "Conditioning for skatepark tricks and transitions", "Low",
     lambda w, t: [skating_agility(), skating_balance(), skating_leg_power()]),
    ("Skater's Ankle Strength", "Skating Fitness", [1, 2, 4], [4, 5], "Ankle stability and injury prevention for all skaters", "Low",
     lambda w, t: [skating_balance(), skating_balance(), skating_balance()]),
    ("Longboard Cruising Fit", "Skating Fitness", [1, 2, 4], [3, 4], "Endurance and balance for long-distance skating", "Low",
     lambda w, t: [skating_balance(), skating_agility(), skating_balance()]),
]

# ========================================================================
# CATEGORY 78 - GOLF FITNESS (14 programs)
# ========================================================================

def golf_rotation():
    return wo("Golf Rotational Power", "strength", 40, [
        ex("Cable Woodchop", 3, 12, 45, "Moderate weight", "Cable Machine", "Core", "Obliques", ["Rectus Abdominis", "Shoulders"], "intermediate", "Rotate from hip, arms extended, controlled", "Medicine Ball Woodchop"),
        ex("Medicine Ball Rotational Throw", 3, 10, 45, "6-10 lb med ball", "Medicine Ball", "Core", "Obliques", ["Shoulders", "Hip Rotators"], "intermediate", "Rotate hips first, then torso, release at wall", "Cable Woodchop"),
        ex("Pallof Press", 3, 10, 45, "Moderate cable resistance", "Cable Machine", "Core", "Obliques", ["Rectus Abdominis", "Transverse Abdominis"], "intermediate", "Press out and hold, resist rotation", "Banded Pallof Press"),
        ex("Half-Kneeling Cable Rotation", 3, 10, 45, "Light to moderate", "Cable Machine", "Core", "Obliques", ["Hip Flexors", "Shoulders"], "intermediate", "Stable hips, rotate through thoracic spine", "Standing Cable Rotation"),
        ex("Russian Twist", 3, 15, 30, "Medicine ball or weight plate", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Lean back slightly, rotate side to side", "Bicycle Crunch"),
        ex("Hip Rotation Stretch", 2, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Rotators", ["Glutes", "Hip Flexors"], "beginner", "90/90 position, rotate smoothly", "Seated Hip Circle"),
    ])

def golf_mobility():
    return wo("Golf Mobility & Flexibility", "flexibility", 35, [
        ex("Thoracic Spine Rotation", 3, 10, 0, "Each side", "Bodyweight", "Back", "Thoracic Spine", ["Obliques", "Shoulders"], "beginner", "Side-lying, top arm opens, follow with eyes", "Seated Twist"),
        ex("Hip 90/90 Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Hip Rotators", ["Glutes", "Hip Flexors"], "beginner", "Sit tall, both knees at 90 degrees", "Pigeon Stretch"),
        ex("Shoulder Sleeper Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Shoulders", "Rotator Cuff", ["Posterior Deltoid"], "beginner", "Side-lying, gently press forearm down", "Cross-Body Shoulder Stretch"),
        ex("World's Greatest Stretch", 2, 5, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine", "Hamstrings", "Shoulders"], "beginner", "Lunge, rotate, reach - full mobility chain", "Spiderman Stretch"),
        ex("Cat-Cow", 2, 10, 0, "Slow and controlled", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("Standing Lat Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Back", "Latissimus Dorsi", ["Obliques", "Shoulders"], "beginner", "Side bend with overhead arm", "Doorway Lat Stretch"),
        ex("Wrist Flexor Stretch", 2, 1, 0, "Hold 20 seconds each arm", "Bodyweight", "Arms", "Forearms", ["Wrist Flexors"], "beginner", "Extend arm, pull fingers back gently", "Wrist Circle"),
    ])

def golf_endurance():
    return wo("Golf Course Endurance", "conditioning", 40, [
        ex("Incline Walking", 1, 1, 0, "20 min at moderate incline", "Treadmill", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Upright posture, simulate course walking", "Brisk Walking"),
        ex("Bodyweight Squat", 3, 15, 45, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, controlled", "Goblet Squat"),
        ex("Standing Calf Raise", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full extension, slow descent", "Seated Calf Raise"),
        ex("Plank", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Lower Back"], "beginner", "Straight body line, engaged core", "Forearm Plank"),
        ex("Bird Dog", 3, 10, 30, "Alternate sides", "Bodyweight", "Core", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Opposite arm and leg, hold 2 seconds", "Dead Bug"),
    ])

cat78_programs = [
    ("Golf Swing Power", "Golf Fitness", [2, 4, 8], [3, 4], "Increase club head speed with rotational power training", "High",
     lambda w, t: [golf_rotation(), golf_mobility(), golf_rotation()]),
    ("Rotational Core for Golf", "Golf Fitness", [2, 4, 8], [4, 5], "Build core power for a more powerful golf swing", "High",
     lambda w, t: [golf_rotation(), golf_rotation(), golf_mobility()]),
    ("Golf Hip Mobility", "Golf Fitness", [1, 2, 4], [5, 7], "Full hip rotation for better drives and consistent shots", "High",
     lambda w, t: [golf_mobility(), golf_mobility(), golf_mobility()]),
    ("Shoulder Flexibility Golf", "Golf Fitness", [1, 2, 4], [5, 7], "Full backswing shoulder mobility for golf performance", "Med",
     lambda w, t: [golf_mobility(), golf_mobility(), golf_mobility()]),
    ("18-Hole Endurance", "Golf Fitness", [2, 4, 8], [3, 4], "Walk the full 18-hole course with energy to spare", "Med",
     lambda w, t: [golf_endurance(), golf_mobility(), golf_endurance()]),
    ("Golf Walking Fitness", "Golf Fitness", [2, 4], [4, 5], "Build stamina for no-cart rounds on hilly courses", "Med",
     lambda w, t: [golf_endurance(), golf_endurance(), golf_mobility()]),
    ("Senior Golfer Fitness", "Golf Fitness", [2, 4, 8], [3], "Stay on the course longer with age-appropriate conditioning", "Med",
     lambda w, t: [golf_mobility(), golf_endurance(), golf_mobility()]),
    ("Golf Season Prep", "Golf Fitness", [4, 8], [4, 5], "Pre-season conditioning for peak golf performance", "Med",
     lambda w, t: [golf_rotation(), golf_mobility(), golf_endurance()]),
    ("Golfer's Back Health", "Golf Fitness", [1, 2, 4], [5, 7], "Protect your spine from golf-related back pain", "Low",
     lambda w, t: [golf_mobility(), golf_mobility(), golf_mobility()]),
    ("Golf Elbow Prevention", "Golf Fitness", [1, 2, 4], [5, 7], "Keep tendons healthy and prevent golfer's elbow", "Low",
     lambda w, t: [golf_mobility(), golf_mobility(), golf_mobility()]),
    ("Golfer's Wrist Strength", "Golf Fitness", [1, 2], [5, 7], "Grip strength and wrist stability for consistent shots", "Low",
     lambda w, t: [golf_mobility(), golf_mobility()]),
    ("Pre-Round Warmup", "Golf Fitness", [1], [1], "Dynamic warmup routine before teeing off", "Low",
     lambda w, t: [golf_mobility()]),
    ("Post-Round Recovery", "Golf Fitness", [1], [1], "Cool down stretches and mobility after 18 holes", "Low",
     lambda w, t: [golf_mobility()]),
    ("Off-Season Golf Maintenance", "Golf Fitness", [4, 8, 12], [3, 4], "Stay golf-fit year round during the off-season", "Low",
     lambda w, t: [golf_rotation(), golf_mobility(), golf_endurance()]),
]

# ========================================================================
# CATEGORY 79 - SWIMMING & OPEN WATER (14 programs)
# ========================================================================

def swim_dryland_upper():
    return wo("Swim Dryland Upper Body", "strength", 45, [
        ex("Lat Pulldown", 4, 10, 60, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids", "Rear Deltoid"], "intermediate", "Wide grip, pull to upper chest, squeeze lats", "Pull-Up"),
        ex("Straight-Arm Pulldown", 3, 12, 45, "Light to moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Core", "Triceps"], "intermediate", "Arms straight, pull bar to thighs, mimics catch phase", "Dumbbell Pullover"),
        ex("Face Pull", 3, 15, 45, "Light cable", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rotator Cuff", "Rhomboids"], "beginner", "Pull rope to face level, external rotate at end", "Band Pull-Apart"),
        ex("Push-Up", 3, 15, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid", "Core"], "beginner", "Full range, chest to floor", "Knee Push-Up"),
        ex("Internal/External Rotation", 3, 12, 30, "Light band or cable", "Resistance Band", "Shoulders", "Rotator Cuff", ["Infraspinatus", "Subscapularis"], "beginner", "Elbow at 90 degrees, controlled rotation", "Cable External Rotation"),
        ex("Plank", 3, 1, 30, "Hold 45-60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Straight line, no sagging hips", "Forearm Plank"),
    ])

def swim_dryland_core():
    return wo("Swim Core & Kick Power", "strength", 40, [
        ex("Flutter Kick", 3, 30, 30, "30 seconds per set", "Bodyweight", "Core", "Hip Flexors", ["Rectus Abdominis", "Quadriceps"], "beginner", "Low back pressed to floor, small rapid kicks", "Lying Leg Raise"),
        ex("Superman", 3, 12, 30, "Hold 2 seconds at top", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Lift arms and legs simultaneously, controlled", "Bird Dog"),
        ex("Hollow Body Hold", 3, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Low back flat, arms overhead, legs extended", "Tuck Hold"),
        ex("Medicine Ball Slam", 3, 12, 45, "8-12 lb med ball", "Medicine Ball", "Full Body", "Core", ["Shoulders", "Latissimus Dorsi"], "intermediate", "Reach overhead, slam down with force", "Burpee"),
        ex("Leg Raise", 3, 12, 30, "Controlled", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Slow descent, don't arch back", "Knee Raise"),
        ex("Side Plank with Rotation", 3, 8, 30, "Each side", "Bodyweight", "Core", "Obliques", ["Shoulders", "Rectus Abdominis"], "intermediate", "Thread arm under, rotate, reach to sky", "Side Plank"),
    ])

def swim_shoulder_health():
    return wo("Swimmer's Shoulder Health", "flexibility", 30, [
        ex("Band Pull-Apart", 3, 15, 30, "Light resistance band", "Resistance Band", "Shoulders", "Rear Deltoid", ["Rhomboids", "Rotator Cuff"], "beginner", "Arms at shoulder height, squeeze back", "Face Pull"),
        ex("Shoulder External Rotation", 3, 12, 30, "Light band", "Resistance Band", "Shoulders", "Infraspinatus", ["Teres Minor"], "beginner", "Elbow pinned to side, rotate out", "Cable External Rotation"),
        ex("Sleeper Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Shoulders", "Infraspinatus", ["Posterior Capsule"], "beginner", "Side-lying, gently press forearm to floor", "Cross-Body Stretch"),
        ex("Prone Y Raise", 3, 12, 30, "Light dumbbells or bodyweight", "Dumbbells", "Shoulders", "Lower Trapezius", ["Rear Deltoid", "Rhomboids"], "beginner", "Face down, arms form Y, lift with control", "Band Y Raise"),
        ex("Scapular Push-Up", 3, 12, 30, "Bodyweight", "Bodyweight", "Shoulders", "Serratus Anterior", ["Pectoralis Minor"], "beginner", "Plank position, protract/retract scapulae only", "Wall Scapular Push-Up"),
        ex("Doorway Chest Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arm on door frame, lean forward gently", "Floor Chest Stretch"),
    ])

cat79_programs = [
    ("Learn to Swim Adult", "Swimming & Open Water", [4, 8, 12], [3], "Water confidence and dryland conditioning for adult beginner swimmers", "High",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_shoulder_health()]),
    ("Lap Swimming Fitness", "Swimming & Open Water", [2, 4, 8], [3, 4], "Build endurance for pool lap swimming with dryland training", "High",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_dryland_upper()]),
    ("Swim Stroke Improvement", "Swimming & Open Water", [2, 4, 8], [3, 4], "Dryland strength to improve swimming technique and efficiency", "High",
     lambda w, t: [swim_dryland_upper(), swim_shoulder_health(), swim_dryland_core()]),
    ("Pool Sprint Training", "Swimming & Open Water", [2, 4, 8], [3, 4], "Speed-focused dryland power for pool sprints", "Med",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_dryland_upper()]),
    ("Masters Swimming Prep", "Swimming & Open Water", [4, 8, 12], [4, 5], "Competitive pool swimming conditioning for masters athletes", "Med",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_shoulder_health(), swim_dryland_upper()]),
    ("Open Water Swimming", "Swimming & Open Water", [4, 8, 12], [3, 4], "Dryland training for open water lake, ocean, and river swimming", "Med",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_dryland_upper()]),
    ("Ocean Swimming Prep", "Swimming & Open Water", [4, 8, 12], [3, 4], "Build strength for waves, currents, and salt water swimming", "Med",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_dryland_upper()]),
    ("Lake Swimming Program", "Swimming & Open Water", [2, 4, 8], [3, 4], "Freshwater distance swimming dryland conditioning", "Med",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_shoulder_health()]),
    ("Open Water Race Prep", "Swimming & Open Water", [4, 8, 12], [4, 5], "Competition preparation for open water swim races", "Med",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_dryland_upper(), swim_shoulder_health()]),
    ("Swimmer's Dryland Training", "Swimming & Open Water", [2, 4, 8], [3, 4], "Complete out-of-pool conditioning for swimmers", "Low",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_dryland_upper()]),
    ("Swimmer's Shoulder Health", "Swimming & Open Water", [1, 2, 4], [4, 5], "Rotator cuff and shoulder injury prevention for swimmers", "Low",
     lambda w, t: [swim_shoulder_health(), swim_shoulder_health(), swim_shoulder_health()]),
    ("Breath Hold Training", "Swimming & Open Water", [1, 2, 4], [4, 5], "Core and breath control for underwater confidence", "Low",
     lambda w, t: [swim_dryland_core(), swim_dryland_core(), swim_shoulder_health()]),
    ("Triathlon Swim Prep", "Swimming & Open Water", [4, 8, 12], [4, 5], "First leg of triathlon dryland swim conditioning", "Low",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_shoulder_health()]),
    ("Water Polo Conditioning", "Swimming & Open Water", [4, 8, 12], [4, 5], "Treading power and throwing strength for water polo", "Low",
     lambda w, t: [swim_dryland_upper(), swim_dryland_core(), swim_dryland_upper()]),
]

# ========================================================================
# CATEGORY 80 - CYCLING & BIKING (12 programs)
# ========================================================================

def cycling_leg_power():
    return wo("Cycling Leg Power", "strength", 45, [
        ex("Barbell Back Squat", 4, 8, 90, "Moderate to heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Below parallel, drive through heels", "Goblet Squat"),
        ex("Leg Press", 3, 12, 60, "Moderate weight", "Leg Press Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Feet shoulder width, full range", "Goblet Squat"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate barbell", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hinge at hips, bar close to shins", "Dumbbell RDL"),
        ex("Single-Leg Leg Press", 3, 10, 60, "Light to moderate", "Leg Press Machine", "Legs", "Quadriceps", ["Glutes"], "intermediate", "One leg at a time, balance push power", "Bulgarian Split Squat"),
        ex("Calf Raise", 3, 20, 30, "Heavy", "Smith Machine", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full range, 2 second hold at top", "Standing Calf Raise"),
    ])

def cycling_core():
    return wo("Cyclist's Core", "strength", 35, [
        ex("Plank", 3, 1, 30, "Hold 45-60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Straight line head to heels, no hip sag", "Forearm Plank"),
        ex("Dead Bug", 3, 10, 30, "Alternate sides", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Low back pressed to floor, slow controlled", "Bird Dog"),
        ex("Pallof Press", 3, 10, 45, "Cable or band", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis", "Rectus Abdominis"], "intermediate", "Resist rotation, press out and hold", "Banded Pallof Press"),
        ex("Back Extension", 3, 12, 30, "Bodyweight or light plate", "Back Extension Bench", "Back", "Erector Spinae", ["Glutes", "Hamstrings"], "beginner", "Controlled arc, don't hyperextend", "Superman"),
        ex("Side Plank", 3, 1, 30, "Hold 30 seconds each side", "Bodyweight", "Core", "Obliques", ["Gluteus Medius", "Shoulders"], "beginner", "Stack feet, straight line, lift hips", "Modified Side Plank"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Half-kneeling, push hips forward gently", "Standing Quad Stretch"),
    ])

def cycling_endurance():
    return wo("Cycling Endurance Builder", "conditioning", 40, [
        ex("Stationary Bike Intervals", 1, 1, 0, "20 min: 2 min hard / 1 min easy", "Stationary Bike", "Legs", "Quadriceps", ["Calves", "Glutes", "Hamstrings"], "intermediate", "Maintain cadence 80-100 RPM during work", "Jump Rope"),
        ex("Step-Up", 3, 12, 45, "Bodyweight or light DB", "Bench", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "High step, drive through heel", "Box Step-Up"),
        ex("Walking Lunge", 3, 12, 45, "Bodyweight or DB", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, knee tracks over toe", "Stationary Lunge"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight or barbell", "Bodyweight", "Hips", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Full hip extension, squeeze at top", "Hip Thrust"),
        ex("Plank", 3, 1, 30, "Hold 30-45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Engaged core, breathe steadily", "Forearm Plank"),
    ])

def cycling_flexibility():
    return wo("Cyclist's Flexibility", "flexibility", 30, [
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Psoas"], "beginner", "Half-kneeling, push hips forward", "Standing Quad Stretch"),
        ex("Hamstring Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Straight leg on bench, hinge forward", "Seated Forward Fold"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis", "Hip Rotators"], "beginner", "Square hips, fold forward", "Figure-4 Stretch"),
        ex("Quad Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute, keep knees together", "Lying Quad Stretch"),
        ex("Chest Opener", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arms behind back, open chest", "Doorway Stretch"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round, gentle flow", "Seated Cat-Cow"),
        ex("Thoracic Spine Extension", 2, 10, 0, "Over foam roller", "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae"], "beginner", "Hands behind head, extend over roller", "Cat-Cow"),
    ])

cat80_programs = [
    ("Road Cycling Base", "Cycling & Biking", [4, 8, 12], [4, 5], "Build foundational cycling endurance and leg strength", "High",
     lambda w, t: [cycling_leg_power(), cycling_endurance(), cycling_core()]),
    ("Century Ride Prep", "Cycling & Biking", [8, 12, 16], [4, 5], "Train for 100-mile rides with endurance and power", "High",
     lambda w, t: [cycling_endurance(), cycling_leg_power(), cycling_core(), cycling_flexibility()]),
    ("Cycling Climb Training", "Cycling & Biking", [4, 8], [3, 4], "Conquer hills and mountains with leg power training", "High",
     lambda w, t: [cycling_leg_power(), cycling_core(), cycling_leg_power()]),
    ("Cycling Sprint Power", "Cycling & Biking", [2, 4, 8], [3, 4], "Speed, acceleration, and explosive cycling power", "Med",
     lambda w, t: [cycling_leg_power(), cycling_endurance(), cycling_leg_power()]),
    ("Mountain Bike Fitness", "Cycling & Biking", [4, 8, 12], [3, 4], "Technical trail riding strength and core stability", "Med",
     lambda w, t: [cycling_core(), cycling_leg_power(), cycling_endurance()]),
    ("MTB Endurance Builder", "Cycling & Biking", [4, 8, 12], [4, 5], "Long trail ride endurance with off-bike conditioning", "Med",
     lambda w, t: [cycling_endurance(), cycling_leg_power(), cycling_core()]),
    ("Downhill MTB Conditioning", "Cycling & Biking", [2, 4, 8], [3, 4], "Core and control for technical descents", "Med",
     lambda w, t: [cycling_core(), cycling_leg_power(), cycling_core()]),
    ("Indoor Cycling Program", "Cycling & Biking", [2, 4, 8], [4, 5], "Spin bike and indoor trainer workout programs", "Med",
     lambda w, t: [cycling_endurance(), cycling_core(), cycling_endurance()]),
    ("Cyclist's Leg Strength", "Cycling & Biking", [2, 4, 8], [2, 3], "Off-bike leg power building for cycling performance", "Med",
     lambda w, t: [cycling_leg_power(), cycling_leg_power()]),
    ("Cyclist's Core Stability", "Cycling & Biking", [1, 2, 4], [3, 4], "Core and bike handling efficiency training", "Low",
     lambda w, t: [cycling_core(), cycling_core(), cycling_core()]),
    ("Cycling Recovery", "Cycling & Biking", [1], [1], "Post-ride stretching, foam rolling, and mobility", "Low",
     lambda w, t: [cycling_flexibility()]),
    ("Bike Commuter Fitness", "Cycling & Biking", [2, 4], [5, 7], "Daily cycling conditioning for bike commuters", "Low",
     lambda w, t: [cycling_core(), cycling_flexibility(), cycling_endurance()]),
]

# ========================================================================
# WOMEN'S HEALTH EXPANSION (8 programs from checklist expansion)
# ========================================================================

def prenatal_gentle():
    return wo("Prenatal Gentle Movement", "low_impact", 30, [
        ex("Pelvic Tilt", 3, 12, 30, "Bodyweight", "Bodyweight", "Core", "Transverse Abdominis", ["Pelvic Floor", "Lower Back"], "beginner", "Flatten lower back to floor, engage core gently", "Standing Pelvic Tilt"),
        ex("Cat-Cow", 2, 10, 0, "Slow, with breath", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Inhale arch, exhale round, relieve back tension", "Seated Cat-Cow"),
        ex("Kegel", 3, 10, 15, "Hold 5 seconds each", "Bodyweight", "Core", "Pelvic Floor", ["Transverse Abdominis"], "beginner", "Squeeze and lift pelvic floor, breathe normally", "Quick Kegel Flick"),
        ex("Bodyweight Squat", 3, 12, 45, "Bodyweight, wide stance", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Pelvic Floor"], "beginner", "Wide stance, toes out, sit back", "Wall Squat"),
        ex("Side-Lying Leg Lift", 3, 12, 30, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Lie on side, lift top leg, keep hips stacked", "Clamshell"),
        ex("Seated Arm Raise", 2, 10, 30, "Light dumbbells", "Dumbbells", "Shoulders", "Deltoids", ["Trapezius"], "beginner", "Seated on ball or chair, lift to shoulder height", "Standing Arm Raise"),
    ])

def postpartum_recovery():
    return wo("Postpartum Recovery", "low_impact", 25, [
        ex("Diaphragmatic Breathing", 3, 10, 0, "Deep belly breaths", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis", "Pelvic Floor"], "beginner", "Inhale expand belly, exhale gently engage core", "Box Breathing"),
        ex("Kegel", 3, 10, 15, "Hold 5-10 seconds each", "Bodyweight", "Core", "Pelvic Floor", ["Transverse Abdominis"], "beginner", "Lift and squeeze pelvic floor, fully relax between", "Quick Kegel Flick"),
        ex("Glute Bridge", 3, 10, 30, "Bodyweight", "Bodyweight", "Hips", "Gluteus Maximus", ["Pelvic Floor", "Core"], "beginner", "Exhale as you lift, squeeze glutes at top", "Modified Glute Bridge"),
        ex("Heel Slide", 3, 10, 15, "Each leg", "Bodyweight", "Core", "Transverse Abdominis", ["Hip Flexors"], "beginner", "Slide heel along floor, maintain pelvic stability", "Marching"),
        ex("Bird Dog", 3, 8, 30, "Alternate sides", "Bodyweight", "Core", "Erector Spinae", ["Transverse Abdominis", "Glutes"], "beginner", "Opposite arm and leg, keep core engaged", "Dead Bug"),
        ex("Wall Push-Up", 2, 10, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Hands on wall, lower chest toward wall", "Incline Push-Up"),
    ])

def diastasis_rehab():
    return wo("Diastasis Recti Rehab", "rehab", 25, [
        ex("Diaphragmatic Breathing", 3, 10, 0, "Connection breath", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis", "Pelvic Floor"], "beginner", "Inhale expand ribcage, exhale gently draw navel in", "Box Breathing"),
        ex("Heel Tap", 3, 10, 15, "Alternate legs", "Bodyweight", "Core", "Transverse Abdominis", ["Hip Flexors"], "beginner", "Supine, 90-90 position, lower one heel to floor", "Heel Slide"),
        ex("Modified Side Plank", 3, 1, 30, "Hold 15-20 seconds each side", "Bodyweight", "Core", "Obliques", ["Transverse Abdominis"], "beginner", "Knees down, lift hips, breathe", "Side-Lying Hip Lift"),
        ex("Pelvic Floor Engagement", 3, 10, 15, "Coordinate with breath", "Bodyweight", "Core", "Pelvic Floor", ["Transverse Abdominis"], "beginner", "Exhale and gently lift pelvic floor, inhale release", "Kegel"),
        ex("Glute Bridge with Core Activation", 3, 10, 30, "Exhale on lift", "Bodyweight", "Hips", "Gluteus Maximus", ["Transverse Abdominis", "Pelvic Floor"], "beginner", "Exhale engage core then lift, no doming", "Modified Glute Bridge"),
    ])

def csection_recovery():
    return wo("C-Section Recovery", "rehab", 20, [
        ex("Diaphragmatic Breathing", 3, 10, 0, "Gentle reconnection", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Hand on belly, feel gentle rise and fall", "Box Breathing"),
        ex("Ankle Pump", 3, 15, 0, "Both feet", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Point and flex feet, promote circulation", "Toe Wiggle"),
        ex("Heel Slide", 3, 8, 15, "Each leg, very gentle", "Bodyweight", "Core", "Transverse Abdominis", ["Hip Flexors"], "beginner", "Slide heel slowly, maintain neutral spine", "Marching"),
        ex("Pelvic Floor Activation", 3, 8, 15, "Gentle engagement", "Bodyweight", "Core", "Pelvic Floor", ["Transverse Abdominis"], "beginner", "Very gentle squeeze and lift, no straining", "Kegel"),
        ex("Gentle Walking", 1, 1, 0, "5-10 minutes gentle pace", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Core"], "beginner", "Upright posture, short strides, listen to body", "Marching in Place"),
    ])

def perimenopause_power():
    return wo("Perimenopause Power", "strength", 40, [
        ex("Goblet Squat", 3, 10, 60, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Weight at chest, full depth, upright torso", "Bodyweight Squat"),
        ex("Dumbbell Row", 3, 10, 60, "Moderate weight", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Brace on bench, pull to hip, squeeze back", "Cable Row"),
        ex("Dumbbell Overhead Press", 3, 10, 60, "Light to moderate", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Core"], "beginner", "Press overhead, core tight, avoid arching", "Pike Push-Up"),
        ex("Hip Thrust", 3, 12, 60, "Bodyweight or barbell", "Barbell", "Hips", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Back on bench, drive hips up, squeeze", "Glute Bridge"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy dumbbells, 30 meters", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core"], "beginner", "Tall posture, tight core, steady steps", "Suitcase Carry"),
        ex("Standing Calf Raise", 3, 15, 30, "Bodyweight or added weight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full range, strengthen for bone health", "Seated Calf Raise"),
    ])

womens_expansion = [
    ("Trying to Conceive Fitness", "Women's Health", [4, 8], [3, 4], "Fertility-optimized gentle movement to support conception", "Low",
     lambda w, t: [prenatal_gentle(), prenatal_gentle(), prenatal_gentle()]),
    ("First Trimester Safe", "Women's Health", [4, 8, 12], [3, 4], "Early pregnancy appropriate movement for first trimester", "Low",
     lambda w, t: [prenatal_gentle(), prenatal_gentle(), prenatal_gentle()]),
    ("Second Trimester Active", "Women's Health", [4, 8, 12], [4, 5], "Mid-pregnancy energy boost with safe active exercise", "Low",
     lambda w, t: [prenatal_gentle(), prenatal_gentle(), prenatal_gentle()]),
    ("Third Trimester Gentle", "Women's Health", [4, 8, 12], [3, 4], "Late pregnancy comfort movement and birth preparation", "Low",
     lambda w, t: [prenatal_gentle(), prenatal_gentle(), prenatal_gentle()]),
    ("Postpartum Starter", "Women's Health", [2, 4, 8], [3], "Gentle return to movement after birth", "Low",
     lambda w, t: [postpartum_recovery(), postpartum_recovery(), postpartum_recovery()]),
    ("Postpartum to Intermediate", "Women's Health", [4, 8, 12], [4, 5], "Progressive postpartum recovery to rebuild fitness", "Low",
     lambda w, t: [postpartum_recovery(), prenatal_gentle(), postpartum_recovery()]),
    ("Diastasis Recti Rehab", "Women's Health", [4, 8, 12], [5, 6], "Core separation recovery with targeted rehab exercises", "Low",
     lambda w, t: [diastasis_rehab(), diastasis_rehab(), diastasis_rehab()]),
    ("C-Section Recovery", "Women's Health", [4, 8, 12], [3, 4], "Post-surgery safe and gradual return to movement", "Low",
     lambda w, t: [csection_recovery(), csection_recovery(), csection_recovery()]),
    ("Perimenopause Power", "Women's Health", [4, 8, 12], [4, 5], "Strength training to support hormonal transition and bone health", "Low",
     lambda w, t: [perimenopause_power(), perimenopause_power(), perimenopause_power()]),
]

# ========================================================================
# MENSTRUAL CYCLE SYNCED EXPANSION (4 new programs)
# ========================================================================

def ovulation_hiit():
    return wo("Ovulation HIIT Burst", "hiit", 35, [
        ex("Burpee", 3, 10, 30, "Bodyweight, max effort", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "intermediate", "Chest to floor, explode up and jump", "Squat Thrust"),
        ex("Jump Squat", 3, 12, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explode up, soft landing", "Bodyweight Squat"),
        ex("Mountain Climber", 3, 20, 30, "Fast pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "intermediate", "Plank position, rapid knee drives", "High Knees"),
        ex("Kettlebell Swing", 3, 15, 45, "Moderate kettlebell", "Kettlebell", "Hips", "Gluteus Maximus", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Hip hinge, snap hips, squeeze glutes at top", "Dumbbell Swing"),
        ex("Box Jump", 3, 10, 45, "Moderate height box", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Two-foot takeoff, soft landing, step down", "Squat Jump"),
    ])

def cycle_synced_strength():
    return wo("Cycle-Synced Strength", "strength", 40, [
        ex("Goblet Squat", 3, 10, 60, "Moderate weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Full depth, chest up, elbows inside knees", "Bodyweight Squat"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate weight", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full range, controlled", "Push-Up"),
        ex("Dumbbell Row", 3, 10, 60, "Moderate weight", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull to ribcage, squeeze back", "Cable Row"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate weight", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hinge at hips, weights close to shins", "Glute Bridge"),
        ex("Overhead Press", 3, 10, 60, "Light to moderate", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Core"], "beginner", "Press overhead, brace core", "Pike Push-Up"),
    ])

def hormone_gentle():
    return wo("Hormone Harmony Movement", "low_impact", 30, [
        ex("Cat-Cow", 2, 10, 0, "Slow, breath-focused", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round, calming rhythm", "Seated Cat-Cow"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders", "Hips"], "beginner", "Knees wide, reach forward, breathe deeply", "Puppy Pose"),
        ex("Glute Bridge", 3, 12, 30, "Bodyweight", "Bodyweight", "Hips", "Gluteus Maximus", ["Hamstrings", "Pelvic Floor"], "beginner", "Lift hips, squeeze glutes, lower gently", "Modified Glute Bridge"),
        ex("Standing Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Bend knees if needed, let head hang", "Seated Forward Fold"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back", "Glutes"], "beginner", "Knees to one side, gaze opposite", "Seated Twist"),
        ex("Gentle Walking", 1, 1, 0, "10-15 minutes easy pace", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Core"], "beginner", "Relaxed pace, focus on breathing", "Marching in Place"),
    ])

menstrual_expansion = [
    ("Ovulation HIIT Burst", "Menstrual Cycle Synced", [1, 2], [4, 5], "Maximum intensity HIIT during fertile window when energy peaks", "High",
     lambda w, t: [ovulation_hiit(), cycle_synced_strength(), ovulation_hiit()]),
    ("Cycle-Synced Fat Loss", "Menstrual Cycle Synced", [4, 8, 12], [4, 5], "Optimize fat burning by training phase-appropriate throughout your cycle", "Low",
     lambda w, t: [cycle_synced_strength(), ovulation_hiit(), hormone_gentle()]),
    ("Hormone Harmony Training", "Menstrual Cycle Synced", [4, 8, 12], [4, 5], "Balance hormones through cycle-appropriate movement patterns", "Low",
     lambda w, t: [hormone_gentle(), cycle_synced_strength(), hormone_gentle()]),
    ("Irregular Cycle Friendly", "Menstrual Cycle Synced", [4, 8], [3, 4], "Flexible training for unpredictable menstrual cycles", "Low",
     lambda w, t: [cycle_synced_strength(), hormone_gentle(), cycle_synced_strength()]),
]

# ========================================================================
# MEN'S HEALTH EXPANSION (8 new programs)
# ========================================================================

def mens_compound_strength():
    return wo("Men's Compound Strength", "strength", 45, [
        ex("Barbell Back Squat", 4, 8, 120, "Heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Below parallel, chest up, drive through heels", "Goblet Squat"),
        ex("Barbell Deadlift", 4, 6, 120, "Heavy", "Barbell", "Full Body", "Hamstrings", ["Glutes", "Erector Spinae", "Trapezius"], "intermediate", "Hinge at hips, bar close to body, flat back", "Romanian Deadlift"),
        ex("Barbell Bench Press", 4, 8, 90, "Moderate to heavy", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Touch chest, press up, feet flat", "Dumbbell Bench Press"),
        ex("Barbell Row", 3, 8, 60, "Moderate", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps", "Rear Deltoid"], "intermediate", "45 degree hinge, pull to lower chest", "Dumbbell Row"),
        ex("Overhead Press", 3, 8, 60, "Moderate", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict press, no leg drive, core braced", "Dumbbell Press"),
    ])

def mens_vitality():
    return wo("Men's Vitality Circuit", "conditioning", 40, [
        ex("Kettlebell Swing", 3, 15, 45, "Moderate to heavy kettlebell", "Kettlebell", "Hips", "Gluteus Maximus", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Hip hinge, snap hips, squeeze glutes", "Dumbbell Swing"),
        ex("Push-Up", 3, 15, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, chest to floor, tight core", "Knee Push-Up"),
        ex("Goblet Squat", 3, 12, 45, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Full depth, upright torso", "Bodyweight Squat"),
        ex("Farmer's Walk", 3, 1, 45, "Heavy dumbbells, 40 meters", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core"], "beginner", "Shoulders back, brisk controlled pace", "Suitcase Carry"),
        ex("Pull-Up", 3, 8, 60, "Bodyweight or assisted", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Full hang to chin over bar", "Lat Pulldown"),
        ex("Plank", 3, 1, 30, "Hold 45-60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Straight line, no hip sag", "Forearm Plank"),
    ])

def mens_flexibility():
    return wo("Men's Flexibility", "flexibility", 30, [
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Psoas"], "beginner", "Half-kneeling, push hips forward, squeeze glute", "Standing Quad Stretch"),
        ex("Hamstring Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Straight leg, hinge forward from hips", "Seated Forward Fold"),
        ex("Chest Opener Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arms behind, open chest, squeeze shoulder blades", "Doorway Stretch"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Square hips, fold forward for deeper stretch", "Figure-4 Stretch"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("Shoulder Cross-Body Stretch", 2, 1, 0, "Hold 20 seconds each arm", "Bodyweight", "Shoulders", "Posterior Deltoid", ["Rhomboids"], "beginner", "Pull arm across chest, keep shoulder down", "Doorway Stretch"),
    ])

def mens_quick():
    return wo("Quick Dad Workout", "strength", 25, [
        ex("Push-Up", 3, 15, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, fast pace", "Knee Push-Up"),
        ex("Bodyweight Squat", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, controlled pace", "Wall Sit"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight core, straight body", "Forearm Plank"),
        ex("Glute Bridge", 3, 12, 30, "Bodyweight", "Bodyweight", "Hips", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze at top, lower controlled", "Hip Thrust"),
        ex("Superman", 3, 10, 30, "Hold 2 seconds at top", "Bodyweight", "Back", "Erector Spinae", ["Glutes"], "beginner", "Lift arms and legs, controlled", "Bird Dog"),
    ])

mens_expansion = [
    ("Libido Boost Training", "Men's Health", [4, 8, 12], [4, 5], "Circulation, energy, and strength training to boost vitality and intimacy", "Low",
     lambda w, t: [mens_compound_strength(), mens_vitality(), mens_flexibility()]),
    ("Testosterone Maximizer", "Men's Health", [4, 8, 12], [4, 5], "Heavy compound lifts and HIIT to naturally support testosterone levels", "Low",
     lambda w, t: [mens_compound_strength(), mens_vitality(), mens_compound_strength()]),
    ("Male Vitality Program", "Men's Health", [4, 8, 12], [4, 5], "Complete program for energy, stamina, and overall drive", "Low",
     lambda w, t: [mens_vitality(), mens_compound_strength(), mens_flexibility()]),
    ("Performance in Bed", "Men's Health", [2, 4, 8], [3, 4], "Stamina, flexibility, and core endurance for intimate performance", "Low",
     lambda w, t: [mens_flexibility(), mens_vitality(), mens_flexibility()]),
    ("New Dad Survival", "Men's Health", [2, 4, 8], [3], "Quick efficient workouts for sleep-deprived new fathers", "Low",
     lambda w, t: [mens_quick(), mens_quick(), mens_quick()]),
    ("Men Over 60", "Men's Health", [4, 8, 12], [3], "Longevity-focused strength and mobility for men over 60", "Low",
     lambda w, t: [mens_flexibility(), mens_vitality(), mens_flexibility()]),
    ("Midlife Crisis Crusher", "Men's Health", [4, 8, 12], [4, 5], "Reclaim your prime with progressive strength and conditioning", "Low",
     lambda w, t: [mens_compound_strength(), mens_vitality(), mens_compound_strength()]),
    ("Empty Nester Fitness", "Men's Health", [4, 8, 12], [4, 5], "Time to focus on yourself with balanced training", "Low",
     lambda w, t: [mens_vitality(), mens_flexibility(), mens_compound_strength()]),
]

# ========================================================================
# GEN Z VIBES (12 programs)
# ========================================================================

def slay_strength():
    return wo("Slay Mode Strength", "strength", 45, [
        ex("Hip Thrust", 4, 12, 60, "Heavy barbell or dumbbell", "Barbell", "Hips", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Full hip extension, pause and squeeze at top", "Glute Bridge"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate weight", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full range, control the eccentric", "Push-Up"),
        ex("Bulgarian Split Squat", 3, 10, 60, "Dumbbells at sides", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Rear foot elevated, deep stretch at bottom", "Walking Lunge"),
        ex("Lat Pulldown", 3, 10, 60, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Pull to upper chest, squeeze lats", "Assisted Pull-Up"),
        ex("Dumbbell Lateral Raise", 3, 12, 45, "Light dumbbells", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Trapezius"], "beginner", "Slight lean, controlled raise to shoulder height", "Cable Lateral Raise"),
        ex("Hanging Leg Raise", 3, 10, 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Controlled lift, no swinging", "Knee Raise"),
    ])

def gen_z_hiit():
    return wo("No Cap HIIT", "hiit", 35, [
        ex("Burpee", 3, 10, 30, "Max effort", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "intermediate", "Chest to floor, explode up, jump and clap", "Squat Thrust"),
        ex("Jump Squat", 3, 15, 30, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, maximum jump height, soft landing", "Bodyweight Squat"),
        ex("Mountain Climber", 3, 20, 30, "Sprint pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "intermediate", "Fast knee drives in plank position", "High Knees"),
        ex("Kettlebell Swing", 3, 15, 30, "Moderate weight, fast", "Kettlebell", "Hips", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Snap hips, power from glutes", "Dumbbell Swing"),
        ex("Box Jump", 3, 10, 30, "Moderate to high box", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive jump, soft landing, step down", "Squat Jump"),
        ex("Battle Rope Wave", 3, 30, 30, "30 seconds per set", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Arms", "Legs"], "intermediate", "Alternating waves, stay in athletic stance", "Plank Jack"),
    ])

def gen_z_outdoor():
    return wo("Touch Grass Movement", "outdoor", 35, [
        ex("Walking Lunge", 3, 12, 45, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride through park or trail", "Stationary Lunge"),
        ex("Push-Up", 3, 15, 30, "On grass or bench", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range outdoors, connect with nature", "Incline Push-Up"),
        ex("Bear Crawl", 3, 30, 45, "30 seconds per set", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps", "Hip Flexors"], "intermediate", "Low to ground, opposite hand and foot move together", "Plank Walk"),
        ex("Sprint Interval", 3, 30, 60, "30 second sprint", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Core"], "intermediate", "80-90% effort sprint, walk back recovery", "High Knees"),
        ex("Bodyweight Squat", 3, 15, 30, "Bodyweight on grass", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, feel the earth under your feet", "Wall Squat"),
    ])

def gen_z_core():
    return wo("Core Core Aesthetics", "strength", 30, [
        ex("Hanging Leg Raise", 3, 12, 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Controlled lift, no momentum", "Knee Raise"),
        ex("Cable Woodchop", 3, 10, 45, "Moderate cable", "Cable Machine", "Core", "Obliques", ["Rectus Abdominis", "Shoulders"], "intermediate", "Rotate from hips, arms extended", "Medicine Ball Woodchop"),
        ex("Ab Wheel Rollout", 3, 10, 45, "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques", "Shoulders", "Latissimus Dorsi"], "intermediate", "Extend as far as controlled, roll back", "Plank Walkout"),
        ex("Plank", 3, 1, 30, "Hold 60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Straight line, no sagging", "Forearm Plank"),
        ex("Russian Twist", 3, 15, 30, "Medicine ball", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Lean back, rotate side to side with control", "Bicycle Crunch"),
        ex("Dead Bug", 3, 10, 30, "Controlled", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Low back on floor, opposite arm and leg extend", "Bird Dog"),
    ])

gen_z_programs = [
    ("Slay Mode Activated", "Gen Z Vibes", [2, 4, 8], [4, 5], "Main character energy workout - show up and slay every set", "High",
     lambda w, t: [slay_strength(), gen_z_hiit(), slay_strength()]),
    ("Understood the Assignment", "Gen Z Vibes", [2, 4, 8], [4, 5], "You showed up, now show out with structured strength and power", "High",
     lambda w, t: [slay_strength(), slay_strength(), gen_z_hiit()]),
    ("No Cap Cardio", "Gen Z Vibes", [1, 2, 4], [4, 5], "Real ones only - honest high-intensity cardio with no shortcuts", "High",
     lambda w, t: [gen_z_hiit(), gen_z_hiit(), gen_z_hiit()]),
    ("It's Giving Gains", "Gen Z Vibes", [2, 4, 8], [4, 5], "When your workout is giving what it is supposed to give - pure gains", "Med",
     lambda w, t: [slay_strength(), slay_strength(), slay_strength()]),
    ("Touch Grass Training", "Gen Z Vibes", [1, 2, 4], [5, 7], "Get outside, touch nature, and move your body in the real world", "Med",
     lambda w, t: [gen_z_outdoor(), gen_z_outdoor(), gen_z_outdoor()]),
    ("Unhinged Energy Release", "Gen Z Vibes", [1, 2], [3, 4], "Let that feral energy out safely with maximum intensity", "Med",
     lambda w, t: [gen_z_hiit(), gen_z_hiit(), gen_z_hiit()]),
    ("Roman Empire Strength", "Gen Z Vibes", [4, 8, 12], [3, 4], "Think about gains as often as men think about Rome - classic barbell strength", "Med",
     lambda w, t: [slay_strength(), slay_strength(), slay_strength()]),
    ("Delulu is the Solulu", "Gen Z Vibes", [2, 4, 8], [4, 5], "Manifest that dream body with delusional confidence and real work", "Med",
     lambda w, t: [slay_strength(), gen_z_hiit(), slay_strength()]),
    ("This Workout Hits Different", "Gen Z Vibes", [2, 4, 8], [4, 5], "When the workout just clicks - varied and engaging sessions", "Low",
     lambda w, t: [gen_z_hiit(), slay_strength(), gen_z_outdoor()]),
    ("Ate and Left No Crumbs", "Gen Z Vibes", [1, 2, 4], [5, 6], "Finish strong, leave nothing behind - complete every rep", "Low",
     lambda w, t: [gen_z_hiit(), slay_strength(), gen_z_hiit()]),
    ("Living My Best Life", "Gen Z Vibes", [2, 4, 8], [4, 5], "Wellness era unlocked - balanced fitness for your best self", "Low",
     lambda w, t: [slay_strength(), gen_z_outdoor(), gen_z_core()]),
    ("Core Core", "Gen Z Vibes", [1, 2, 4], [5, 6], "Core workout but make it aesthetic - sculpted midsection training", "Low",
     lambda w, t: [gen_z_core(), gen_z_core(), gen_z_core()]),
]

# ========================================================================
# MOOD & EMOTION BASED (12 programs)
# ========================================================================

def mood_calm():
    return wo("Calming Movement", "flexibility", 30, [
        ex("Diaphragmatic Breathing", 3, 10, 0, "Deep belly breaths", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "4 count inhale, 6 count exhale, hand on belly", "Box Breathing"),
        ex("Cat-Cow", 2, 10, 0, "Slow, rhythmic", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Sync with breath, close eyes", "Seated Cat-Cow"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders", "Hips"], "beginner", "Wide knees, reach forward, breathe deep", "Puppy Pose"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back", "Glutes"], "beginner", "Let gravity pull knees, relax fully", "Seated Twist"),
        ex("Gentle Walking", 1, 1, 0, "10 minutes mindful pace", "Bodyweight", "Full Body", "Quadriceps", ["Calves"], "beginner", "Focus on each step, breathe naturally", "Marching in Place"),
        ex("Standing Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Let head hang heavy, shake head yes/no", "Seated Forward Fold"),
    ])

def mood_energize():
    return wo("Energy Boost", "conditioning", 30, [
        ex("Jumping Jack", 3, 20, 30, "Moderate pace", "Bodyweight", "Full Body", "Deltoids", ["Calves", "Core"], "beginner", "Full arm extension overhead, rhythmic", "Step Jack"),
        ex("Bodyweight Squat", 3, 12, 30, "Brisk pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, pump arms for energy", "Wall Squat"),
        ex("Push-Up", 3, 10, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, rhythmic pace", "Knee Push-Up"),
        ex("High Knees", 3, 20, 30, "Moderate pace", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core", "Calves"], "beginner", "Drive knees up, pump arms", "Marching"),
        ex("Plank Shoulder Tap", 3, 10, 30, "Alternate sides", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Plank position, touch opposite shoulder", "Plank"),
    ])

def mood_rage():
    return wo("Rage Channel", "hiit", 40, [
        ex("Battle Rope Wave", 3, 30, 30, "30 seconds max effort", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Arms", "Legs"], "intermediate", "Alternating waves, slam with purpose", "Plank Jack"),
        ex("Medicine Ball Slam", 4, 12, 30, "Heavy med ball, max power", "Medicine Ball", "Full Body", "Core", ["Shoulders", "Latissimus Dorsi"], "intermediate", "Reach high, slam down with everything", "Burpee"),
        ex("Heavy Bag Punching", 3, 60, 30, "60 seconds per round", "Heavy Bag", "Full Body", "Shoulders", ["Core", "Arms", "Chest"], "intermediate", "Proper form, exhale on each punch", "Shadow Boxing"),
        ex("Kettlebell Swing", 4, 15, 30, "Moderate to heavy", "Kettlebell", "Hips", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Aggressive hip snap, power from frustration", "Dumbbell Swing"),
        ex("Burpee", 3, 10, 30, "All out effort", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Channel anger into each rep", "Squat Thrust"),
        ex("Box Jump", 3, 10, 45, "Moderate box", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive, decisive, step down", "Squat Jump"),
    ])

def mood_selfcare():
    return wo("Self-Care Movement", "flexibility", 25, [
        ex("Gentle Neck Roll", 2, 5, 0, "Each direction", "Bodyweight", "Neck", "Trapezius", ["Levator Scapulae"], "beginner", "Slow circles, release neck tension", "Neck Stretch"),
        ex("Shoulder Roll", 2, 10, 0, "Forward and backward", "Bodyweight", "Shoulders", "Trapezius", ["Deltoids"], "beginner", "Big circles, release shoulder tension", "Arm Circle"),
        ex("Cat-Cow", 2, 10, 0, "Very slow, eyes closed", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Sync with breath, feel each vertebra", "Seated Cat-Cow"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 90 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis", "Hip Flexors"], "beginner", "Fold forward, breathe into stretch", "Figure-4 Stretch"),
        ex("Child's Pose", 2, 1, 0, "Hold 90 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Complete surrender, breathe deeply", "Puppy Pose"),
        ex("Savasana", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Complete stillness, body scan meditation", "Seated Meditation"),
    ])

mood_programs = [
    ("Feeling Anxious", "Mood & Emotion Based", [1, 2, 4], [3, 4], "Calm the chaos through grounding movement and breathwork", "High",
     lambda w, t: [mood_calm(), mood_calm(), mood_calm()]),
    ("Feeling Depressed", "Mood & Emotion Based", [1, 2, 4], [3, 5], "Gentle mood-lifting movement to boost endorphins without overwhelm", "High",
     lambda w, t: [mood_energize(), mood_calm(), mood_energize()]),
    ("Feeling Angry", "Mood & Emotion Based", [1, 2], [3, 4], "Channel that rage productively through high-intensity movement", "High",
     lambda w, t: [mood_rage(), mood_rage(), mood_calm()]),
    ("Feeling Stressed", "Mood & Emotion Based", [1, 2, 4], [3, 4], "Burn off cortisol with movement that releases tension", "Med",
     lambda w, t: [mood_energize(), mood_calm(), mood_energize()]),
    ("Feeling Low Energy", "Mood & Emotion Based", [1, 2, 4], [4, 5], "Gentle energy boost without depleting your reserves", "Med",
     lambda w, t: [mood_energize(), mood_calm(), mood_energize()]),
    ("Feeling Restless", "Mood & Emotion Based", [1, 2], [3, 4], "Burn off excess energy with dynamic challenging movement", "Med",
     lambda w, t: [mood_rage(), mood_energize(), mood_rage()]),
    ("Sad Day Movement", "Mood & Emotion Based", [1, 2], [3, 4], "Compassionate self-care workout when you need kindness most", "Med",
     lambda w, t: [mood_selfcare(), mood_calm(), mood_selfcare()]),
    ("Overwhelmed Recovery", "Mood & Emotion Based", [1, 2], [3, 4], "Reset your nervous system when everything feels like too much", "Med",
     lambda w, t: [mood_calm(), mood_selfcare(), mood_calm()]),
    ("Confidence Boost", "Mood & Emotion Based", [1, 2, 4], [4, 5], "Feel powerful in your body with empowering strength movements", "Low",
     lambda w, t: [slay_strength(), mood_energize(), slay_strength()]),
    ("Self-Love Session", "Mood & Emotion Based", [1, 2, 4], [4, 5], "Movement as self-care and celebration of your body", "Low",
     lambda w, t: [mood_selfcare(), mood_energize(), mood_selfcare()]),
    ("Bad Day Burner", "Mood & Emotion Based", [1, 2], [3, 4], "Sweat out the bad vibes with intense cathartic exercise", "Low",
     lambda w, t: [mood_rage(), mood_energize(), mood_rage()]),
    ("Celebration Workout", "Mood & Emotion Based", [1, 2], [3, 4], "Move when you are feeling great and want to keep the energy high", "Low",
     lambda w, t: [mood_energize(), gen_z_hiit(), mood_energize()]),
]

# ========================================================================
# GENERATE ALL PROGRAMS
# ========================================================================

all_program_sets = [
    ("Cat 76 - Hiking & Trail", cat76_programs),
    ("Cat 77 - Skating", cat77_programs),
    ("Cat 78 - Golf", cat78_programs),
    ("Cat 79 - Swimming & Open Water", cat79_programs),
    ("Cat 80 - Cycling & Biking", cat80_programs),
    ("Women's Health Expansion", womens_expansion),
    ("Menstrual Cycle Synced Expansion", menstrual_expansion),
    ("Men's Health Expansion", mens_expansion),
    ("Gen Z Vibes", gen_z_programs),
    ("Mood & Emotion Based", mood_programs),
]

total_generated = 0
total_skipped = 0

for section_name, programs in all_program_sets:
    print(f"\n{'='*60}")
    print(f"  {section_name}")
    print(f"{'='*60}")
    for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in programs:
        if helper.check_program_exists(prog_name):
            print(f"  SKIP (exists): {prog_name}")
            total_skipped += 1
            continue

        weeks_data = {}
        for dur in durs:
            weeks = {}
            for w in range(1, dur + 1):
                p = w / dur if dur > 1 else 0.5
                if p <= 0.33:
                    focus = f"Week {w} - Foundation: build base fitness and learn movements"
                elif p <= 0.66:
                    focus = f"Week {w} - Build: increase intensity and duration"
                else:
                    focus = f"Week {w} - Peak: challenge yourself and test limits"
                weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
            for sess in sessions_list:
                weeks_data[(dur, sess)] = weeks

        mn = helper.get_next_migration_num()
        s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
        if s:
            helper.update_tracker(prog_name, "Done")
            print(f"  OK: {prog_name}")
            total_generated += 1
        else:
            print(f"  FAILED: {prog_name}")

helper.close()
print(f"\n{'='*60}")
print(f"  COMPLETE: Generated {total_generated}, Skipped {total_skipped}")
print(f"{'='*60}")
